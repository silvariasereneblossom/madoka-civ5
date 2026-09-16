#!/usr/bin/env python3
"""Offline Civ V mod database simulator.

Seeds a SQLite database from the game's cached gameplay database, then replays
each mod's <UpdateDatabase> actions (SQL and Civ V XML) in modinfo order,
emulating the game's loader closely enough to surface database problems
before the game is launched:

  * .sql files follow sqlite3_exec semantics: statements run in order and the
    file is abandoned at the first error.
  * .xml files follow the Civ V GameData grammar: <Table>/<Column> schema,
    <Row>, <Replace>, <Update><Where/><Set/></Update>, <Delete>. A failing
    element is logged and the loader continues with the next element.
  * Element text is trimmed (the game does this; mods rely on it).
  * <Update>/<Delete> that touch zero rows, and <Delete> without a predicate,
    are reported as warnings: they are the most common silent mod defects.
  * After all mods, PRAGMA foreign_key_check reports dangling references as
    warnings. The game does not enforce them at load either; they fail later.

Fidelity limits: the game uses SQLite 3.7.x while this runs on a modern
SQLite. Constructs newer than 3.7 (UPSERT, CTEs, window functions, DROP
COLUMN) are accepted here but fail in-game. One 3.7 quirk is emulated: a
bare `DEFAULT true|false` in DDL is a *string* default there, so it is
rewritten to a string here and flagged.

Usage:
  civdb.py build --seed core.db --out sim.db [--mod DIR ...] [--report report.md]
  civdb.py diff  --before a.db --after b.db [--tables A,B]
"""
from __future__ import annotations

import argparse
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

LANGUAGES = ["en_US", "de_DE", "es_ES", "fr_FR", "it_IT", "ja_JP", "ko_KR", "pl_PL", "ru_RU", "zh_Hant_HK"]
POST_37_CONSTRUCTS = [
    (re.compile(r"\bON\s+CONFLICT\s*\(.*?\)\s*DO\b", re.I | re.S), "UPSERT (SQLite 3.24+)"),
    (re.compile(r"^\s*WITH\b", re.I), "CTE / WITH (SQLite 3.8.3+)"),
    (re.compile(r"\bOVER\s*\(", re.I), "window function (SQLite 3.25+)"),
    (re.compile(r"\bALTER\s+TABLE\b.*\b(DROP|RENAME)\s+COLUMN\b", re.I | re.S), "ALTER TABLE DROP/RENAME COLUMN (SQLite 3.25+/3.35+)"),
]
BARE_BOOL_DEFAULT = re.compile(r"\bDEFAULT\s+(true|false)\b", re.I)
DbError = (sqlite3.Error, ValueError, TypeError)


@dataclass
class Problem:
    mod: str
    file: str
    kind: str          # "error" | "warning"
    message: str
    detail: str = ""


@dataclass
class Report:
    problems: list[Problem] = field(default_factory=list)
    files_ok: int = 0
    files_failed: int = 0

    def error(self, mod, file, msg, detail=""):
        self.problems.append(Problem(mod, file, "error", msg, detail))

    def warn(self, mod, file, msg, detail=""):
        self.problems.append(Problem(mod, file, "warning", msg, detail))


# ----------------------------------------------------------------------------
# modinfo parsing
# ----------------------------------------------------------------------------

def find_modinfo(mod_dir: Path) -> Path:
    cands = sorted(mod_dir.glob("*.modinfo"))
    if not cands:
        raise SystemExit(f"no .modinfo in {mod_dir}")
    return cands[0]


def modinfo_actions(modinfo: Path) -> tuple[str, list[str]]:
    root = ET.parse(modinfo).getroot()
    name = root.findtext("Properties/Name") or modinfo.stem
    files = [a.text.strip() for a in root.findall("Actions/OnModActivated/UpdateDatabase") if a.text]
    return name, files


def resolve_case_insensitive(base: Path, rel: str) -> Path | None:
    """Windows resolves paths case-insensitively; emulate that on any host."""
    p = base
    for part in re.split(r"[\\/]+", rel):
        if not part:
            continue
        if not p.is_dir():
            return None
        match = next((c for c in p.iterdir() if c.name.lower() == part.lower()), None)
        if match is None:
            return None
        p = match
    return p


# ----------------------------------------------------------------------------
# SQL: quote/comment-aware scanning and splitting
# ----------------------------------------------------------------------------

def scan_sql(sql: str) -> tuple[str, list[int]]:
    """Blank out comments (preserving newlines) and return the cleaned text plus
    the offsets of every top-level ';' (outside strings and comments)."""
    out: list[str] = []
    semis: list[int] = []
    i, n = 0, len(sql)
    while i < n:
        ch = sql[i]
        nxt = sql[i + 1] if i + 1 < n else ""
        if ch == "-" and nxt == "-":                      # line comment
            j = sql.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif ch == "/" and nxt == "*":                    # block comment
            j = sql.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("".join("\n" if c == "\n" else " " for c in sql[i:j]))
            i = j
        elif ch in ("'", '"', "`", "["):                  # literal / quoted identifier
            close = "]" if ch == "[" else ch
            j = i + 1
            while j < n:
                if sql[j] == close:
                    if close != "]" and j + 1 < n and sql[j + 1] == close:   # doubled quote
                        j += 2
                        continue
                    break
                j += 1
            j = min(j + 1, n)
            out.append(sql[i:j])
            i = j
        else:
            if ch == ";":
                semis.append(sum(len(s) for s in out))
            out.append(ch)
            i += 1
    return "".join(out), semis


def split_statements(sql: str) -> list[str]:
    """Split on top-level ';' but keep multi-statement bodies (CREATE TRIGGER
    ... BEGIN ...; ... END;) together via sqlite3.complete_statement."""
    cleaned, semis = scan_sql(sql)
    stmts: list[str] = []
    start = 0
    buf = ""
    for pos in semis + [len(cleaned)]:
        piece = cleaned[start:pos + 1] if pos < len(cleaned) else cleaned[start:]
        start = pos + 1
        buf += piece
        if buf.strip() and sqlite3.complete_statement(buf):
            stmts.append(buf.strip())
            buf = ""
    if buf.strip():
        stmts.append(buf.strip())
    return stmts


def _savepoint(conn, name):
    conn.execute(f"SAVEPOINT {name}")


def _rollback(conn, name):
    try:
        conn.execute(f"ROLLBACK TO {name}")
        conn.execute(f"RELEASE {name}")
    except sqlite3.Error:
        pass  # savepoint lost (e.g. the mod SQL issued COMMIT); nothing to undo


def apply_sql(conn: sqlite3.Connection, text: str, mod: str, file: str, rep: Report) -> bool:
    stmts = split_statements(text)
    for idx, s in enumerate(stmts):
        for rx, what in POST_37_CONSTRUCTS:
            if rx.search(s):
                rep.warn(mod, file, f"statement {idx + 1} uses {what}; the game's SQLite 3.7 rejects it",
                         re.sub(r"\s+", " ", s)[:160])
        if BARE_BOOL_DEFAULT.search(s) and re.match(r"\s*(ALTER|CREATE)\b", s, re.I):
            rep.warn(mod, file, f"statement {idx + 1}: bare DEFAULT true/false is a *string* default on the "
                                "game's SQLite 3.7 (Lua sees 'false' as truthy); use DEFAULT 0/1",
                     re.sub(r"\s+", " ", s)[:160])
            s = BARE_BOOL_DEFAULT.sub(lambda m: f"DEFAULT '{m.group(1).lower()}'", s)
        try:
            _savepoint(conn, "stmt")
            before = conn.total_changes      # counts trigger-made changes too (views like Language_en_US)
            conn.execute(s)
            conn.execute("RELEASE stmt")
        except DbError as e:
            _rollback(conn, "stmt")
            excerpt = re.sub(r"\s+", " ", s)[:220]
            rep.error(mod, file, f"SQL error at statement {idx + 1}/{len(stmts)}: {e}",
                      f"{excerpt}  [remaining {len(stmts) - idx - 1} statements skipped]")
            return False
        if conn.total_changes == before and re.match(r"\s*(UPDATE|DELETE)\b", s, re.I):
            rep.warn(mod, file, f"statement {idx + 1} matched 0 rows", re.sub(r"\s+", " ", s)[:160])
    return True


# ----------------------------------------------------------------------------
# XML application (Civ V GameData grammar)
# ----------------------------------------------------------------------------

_COLUMN_TYPES = {"integer": "integer", "int": "integer", "boolean": "boolean", "text": "text",
                 "string": "text", "variant": "text", "real": "real", "float": "real", "double": "real"}


def _lit(v: str | None):
    if v is None:
        return None
    v = v.strip()          # the game's loader trims element text
    lv = v.lower()
    if lv == "true":
        return 1
    if lv == "false":
        return 0
    return v


def _kv_from_element(el: ET.Element) -> dict:
    """Attributes and/or child elements form column=value pairs."""
    d = {k: _lit(v) for k, v in el.attrib.items()}
    for child in el:
        if len(child):
            raise ValueError(f"unexpected nested element <{child.tag}> inside <{el.tag}>")
        d[child.tag] = _lit(child.text if child.text is not None else "")
    return d


def _quote_ident(name) -> str:
    if not name:
        raise ValueError("missing name attribute")
    return '"' + str(name).replace('"', '""') + '"'


def _table_ddl(el: ET.Element, mod, file, rep) -> str:
    name = el.get("name")
    cols = []
    for c in el.findall("Column"):
        ctype = c.get("type", "text").lower()
        if ctype not in _COLUMN_TYPES:
            rep.warn(mod, file, f"<Table name=\"{name}\"> column {c.get('name')}: unknown type '{ctype}', treated as text")
        parts = [_quote_ident(c.get("name")), _COLUMN_TYPES.get(ctype, "text")]
        if c.get("primarykey", "false").lower() == "true":
            parts.append("primary key")
            if c.get("autoincrement", "false").lower() == "true":
                parts.append("autoincrement")
        if c.get("notnull", "false").lower() == "true":
            parts.append("not null")
        if c.get("unique", "false").lower() == "true":
            parts.append("unique")
        if "default" in c.attrib:
            dv = c.get("default")
            dv = "1" if dv.lower() == "true" else "0" if dv.lower() == "false" else dv
            if re.fullmatch(r"-?\d+(\.\d+)?", dv) or dv.upper() == "NULL":
                parts.append(f"default {dv}")
            else:
                parts.append("default '" + dv.replace("'", "''") + "'")
        ref = c.get("reference")
        if ref:
            m = re.fullmatch(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*", ref)
            parts.append(f"references {_quote_ident(m.group(1))}({_quote_ident(m.group(2))})" if m else f"references {ref}")
        cols.append(" ".join(parts))
    return f"create table {_quote_ident(name)} ({', '.join(cols)})"


def apply_xml(conn: sqlite3.Connection, text: str, mod: str, file: str, rep: Report) -> bool:
    # The game's XML reader tolerates "--" inside comments (illegal in strict XML).
    # Blank comments but keep their newlines so reported line numbers stay right.
    text = re.sub(r"<!--.*?-->", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        rep.error(mod, file, f"XML parse error: {e}")
        return False
    if root.tag != "GameData":
        rep.warn(mod, file, f"root element is <{root.tag}>, not <GameData>; file ignored by game")
        return True
    ok = True
    for table_el in root:
        table = table_el.tag
        if table == "Table":
            try:
                name = table_el.get("name")
                if conn.execute("select 1 from sqlite_master where type='table' and name=?", (name,)).fetchone():
                    raise sqlite3.OperationalError(f"table {name} already exists")
                conn.execute(_table_ddl(table_el, mod, file, rep))
            except DbError as e:
                rep.error(mod, file, f"<Table name=\"{table_el.get('name')}\">: {e}")
                ok = False
            continue
        for op in table_el:
            try:
                _savepoint(conn, "op")
                _apply_op(conn, table, op, mod, file, rep)
                conn.execute("RELEASE op")
            except DbError as e:
                _rollback(conn, "op")
                snippet = re.sub(r"\s+", " ", ET.tostring(op, encoding="unicode"))[:220]
                rep.error(mod, file, f"<{table}><{op.tag}>: {e}", snippet)
                ok = False
    return ok


def _apply_op(conn, table, op: ET.Element, mod, file, rep):
    t = _quote_ident(table)
    snippet = lambda: re.sub(r"\s+", " ", ET.tostring(op, encoding="unicode"))[:160]
    if op.tag in ("Row", "Replace"):
        kv = _kv_from_element(op)
        verb = "insert or replace" if op.tag == "Replace" else "insert"
        if not kv:
            conn.execute(f"{verb} into {t} default values")
            return
        cols = ", ".join(_quote_ident(k) for k in kv)
        qs = ", ".join("?" for _ in kv)
        conn.execute(f"{verb} into {t} ({cols}) values ({qs})", list(kv.values()))
    elif op.tag == "Update":
        where_el = op.find("Where")
        set_el = op.find("Set")
        if set_el is None:
            raise ValueError("<Update> without <Set>")
        sets = _kv_from_element(set_el)
        wheres = _kv_from_element(where_el) if where_el is not None else {}
        sql = f"update {t} set " + ", ".join(f"{_quote_ident(k)}=?" for k in sets)
        params = list(sets.values())
        if wheres:
            sql += " where " + " and ".join(f"{_quote_ident(k)}=?" for k in wheres)
            params += list(wheres.values())
        before = conn.total_changes
        conn.execute(sql, params)
        if conn.total_changes == before:
            rep.warn(mod, file, f"<{table}><Update> matched 0 rows", snippet())
    elif op.tag == "Delete":
        wheres = _kv_from_element(op)
        if not wheres:
            n = conn.execute(f"select count(*) from {t}").fetchone()[0]
            rep.warn(mod, file, f"<{table}><Delete/> has no predicate: deletes all {n} rows", snippet())
            conn.execute(f"delete from {t}")
            return
        sql = f"delete from {t} where " + " and ".join(f"{_quote_ident(k)}=?" for k in wheres)
        before = conn.total_changes
        conn.execute(sql, list(wheres.values()))
        if conn.total_changes == before:
            rep.warn(mod, file, f"<{table}><Delete> matched 0 rows", snippet())
    else:
        raise ValueError(f"unknown element <{op.tag}> under <{table}>")


# ----------------------------------------------------------------------------
# driver
# ----------------------------------------------------------------------------

def seed_text(conn: sqlite3.Connection, text_dbs: list[Path], rep: Report) -> None:
    """Recreate the game's localization layer: a LocalizedText table keyed by
    (Language, Tag), a Language_en_US view with INSTEAD OF triggers (which is
    what mods actually insert into), and one Language_<xx> table per other
    language with a UNIQUE Tag. Vanilla + DLC text comes from the per-package
    Localization-*.db files in the game's cache folder (never the Merged one,
    which also carries text from whatever mods were last activated)."""
    conn.execute('CREATE TABLE LocalizedText("Language" TEXT, "Tag" TEXT, "Text" TEXT, "Gender" TEXT, '
                 '"Plurality" TEXT, PRIMARY KEY(Language, Tag))')
    conn.execute('CREATE INDEX LocalizedText_ByTag ON LocalizedText(Tag)')
    for db in text_dbs:
        conn.execute("ATTACH DATABASE ? AS txt", (str(db),))
        try:
            if conn.execute("select 1 from txt.sqlite_master where name='LocalizedText'").fetchone():
                conn.execute("INSERT OR REPLACE INTO LocalizedText SELECT Language, Tag, Text, Gender, Plurality "
                             "FROM txt.LocalizedText")
        finally:
            conn.commit()
            conn.execute("DETACH DATABASE txt")
    conn.execute("CREATE VIEW Language_en_US AS SELECT Tag, Text, Gender, Plurality FROM LocalizedText "
                 "WHERE Language = 'en_US'")
    conn.execute("CREATE TRIGGER Language_en_US_insert INSTEAD OF INSERT ON Language_en_US BEGIN "
                 "INSERT INTO LocalizedText(Language, Tag, Text, Gender, Plurality) "
                 "VALUES('en_US', NEW.Tag, NEW.Text, NEW.Gender, NEW.Plurality); END")
    conn.execute("CREATE TRIGGER Language_en_US_update INSTEAD OF UPDATE ON Language_en_US BEGIN "
                 "UPDATE LocalizedText SET Text = NEW.Text, Gender = NEW.Gender, Plurality = NEW.Plurality "
                 "WHERE Language = 'en_US' AND Tag = OLD.Tag; END")
    conn.execute("CREATE TRIGGER Language_en_US_delete INSTEAD OF DELETE ON Language_en_US BEGIN "
                 "DELETE FROM LocalizedText WHERE Language = 'en_US' AND Tag = OLD.Tag; END")
    for lang in LANGUAGES:
        if lang == "en_US":
            continue
        t = f"Language_{lang.upper()}"
        conn.execute(f'CREATE TABLE "{t}"("ID" INTEGER PRIMARY KEY AUTOINCREMENT, "Tag" TEXT UNIQUE NOT NULL, '
                     '"Text" TEXT NOT NULL, "Gender" TEXT, "Plurality" TEXT)')
        conn.execute(f'INSERT INTO "{t}"(Tag, Text, Gender, Plurality) SELECT Tag, Text, Gender, Plurality '
                     'FROM LocalizedText WHERE Language = ?', (lang,))
    n = conn.execute("select count(*) from LocalizedText where Language='en_US'").fetchone()[0]
    print(f"== text: {n} en_US tags seeded from {len(text_dbs)} localization db(s)")
    if n == 0:
        rep.warn("(seed)", "text", "no vanilla text loaded; missing-key and duplicate-tag checks are unreliable")


def default_text_dbs() -> list[Path]:
    cache = Path.home() / "Documents" / "My Games" / "Sid Meier's Civilization 5" / "cache"
    order = ["BaseGame", "Upgrade 1", "Mongolia", "Babylon", "Spain and Inca", "Polynesia", "Denmark",
             "Korea", "Ancient Wonders", "Expansion - Gods and Kings", "Expansion - Brave New World",
             "Civilization 5 Complete"]
    found = {p.stem.replace("Localization-", ""): p for p in cache.glob("Localization-*.db") if "Merged" not in p.stem}
    ordered = [found.pop(k) for k in order if k in found]
    return ordered + sorted(found.values())


def read_mod_text(path: Path, mod: str, rel: str, rep: Report) -> str:
    raw = path.read_bytes()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    text = raw.decode("utf-8-sig", errors="replace")
    if "�" in text:
        rep.warn(mod, rel, "file is not valid UTF-8; undecodable bytes were replaced")
    return text


def apply_mod(conn, mod_dir: Path, rep: Report, verbose=False):
    modinfo = find_modinfo(mod_dir)
    name, files = modinfo_actions(modinfo)
    print(f"== {name}: {len(files)} UpdateDatabase actions")
    for rel in files:
        path = resolve_case_insensitive(mod_dir, rel)
        if path is None or not path.is_file():
            rep.error(name, rel, "file listed in modinfo not found on disk")
            rep.files_failed += 1
            continue
        text = read_mod_text(path, name, rel, rep)
        ok = apply_sql(conn, text, name, rel, rep) if path.suffix.lower() == ".sql" \
            else apply_xml(conn, text, name, rel, rep)
        rep.files_ok += ok
        rep.files_failed += (not ok)
        if verbose:
            print(("   ok  " if ok else "   FAIL") + rel)
    conn.commit()


def foreign_key_check(conn, rep: Report):
    """Dangling REFERENCES are not enforced by the game at load; they bite at
    runtime instead, so report them per table (a schema mismatch in one table,
    e.g. a foreign key into the Language_en_US view, must not hide the rest)."""
    tables = [r[0] for r in conn.execute("select name from sqlite_master where type='table' order by name")]
    skipped: list[str] = []
    for t in tables:
        try:
            rows = conn.execute(f'PRAGMA foreign_key_check("{t}")').fetchall()
        except sqlite3.Error:
            # The game's own schema has REFERENCES into non-unique columns and into the
            # Language_en_US view; SQLite cannot check those. Summarise, do not spam.
            skipped.append(t)
            continue
        by_parent: dict[str, list[int]] = {}
        for _table, rowid, parent, _fkid in rows:
            by_parent.setdefault(parent, []).append(rowid)
        for parent, rowids in sorted(by_parent.items()):
            sample = ""
            try:
                cols = [r[1] for r in conn.execute(f'pragma table_info("{t}")')]
                key = next((c for c in cols if c in ("Type", "Tag", "ID")), cols[0])
                vals = [str(r[0]) for r in conn.execute(
                    f'select "{key}" from "{t}" where rowid in ({",".join(map(str, rowids[:5]))})')]
                sample = "e.g. " + ", ".join(vals)
            except sqlite3.Error:
                pass
            rep.warn("(post-check)", "foreign keys",
                     f"{t}: {len(rowids)} row(s) reference missing {parent} rows", sample)
    if skipped:
        print(f"== foreign keys: {len(skipped)} table(s) not checkable (references into views or "
              f"non-unique columns in the game's own schema)")


def cmd_build(args):
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.resolve() == Path(args.seed).resolve():
        raise SystemExit("--out must differ from --seed")
    src = sqlite3.connect(args.seed)
    conn = sqlite3.connect(out)
    with conn:
        conn.execute("pragma writable_schema=0")
    src.backup(conn)
    src.close()
    conn.execute("pragma foreign_keys=off")
    rep = Report()
    text_dbs = [Path(p) for p in args.text_db] if args.text_db else ([] if args.no_text else default_text_dbs())
    seed_text(conn, text_dbs, rep)
    for m in args.mod or []:
        apply_mod(conn, Path(m), rep, args.verbose)
    conn.commit()
    foreign_key_check(conn, rep)
    conn.close()
    errs = [p for p in rep.problems if p.kind == "error"]
    warns = [p for p in rep.problems if p.kind == "warning"]
    print(f"\nfiles ok: {rep.files_ok}  failed: {rep.files_failed}  errors: {len(errs)}  warnings: {len(warns)}")
    for p in rep.problems:
        if p.kind == "error" or args.verbose:
            print(f"[{p.kind.upper()}] {p.mod} :: {p.file}\n    {p.message}" + (f"\n    {p.detail}" if p.detail else ""))
    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            fh.write(f"# civdb report\n\nseed: `{args.seed}`\n\n")
            fh.write(f"files ok: {rep.files_ok}, failed: {rep.files_failed}, errors: {len(errs)}, warnings: {len(warns)}\n\n")
            for p in rep.problems:
                fh.write(f"- **{p.kind}** `{p.mod}` / `{p.file}`: {p.message}\n")
                if p.detail:
                    fh.write(f"  - `{p.detail}`\n")
    return 1 if errs else 0


def cmd_diff(args):
    a = sqlite3.connect(args.before)
    b = sqlite3.connect(args.after)
    try:
        tables = [t.strip() for t in args.tables.split(",")] if args.tables else [r[0] for r in b.execute(
            "select name from sqlite_master where type='table' order by name")]
        for t in tables:
            cols_b = [r[1] for r in b.execute(f'pragma table_info("{t}")')]
            cols_a = {r[1] for r in a.execute(f'pragma table_info("{t}")')}
            common = [c for c in cols_b if c in cols_a]
            if not common:
                print(f"{t}: new table (+{b.execute(f'select count(*) from \"{t}\"').fetchone()[0]} rows)")
                continue
            sel = ", ".join(f'"{c}"' for c in common)
            ra = set(a.execute(f'select {sel} from "{t}"').fetchall())
            rb = set(b.execute(f'select {sel} from "{t}"').fetchall())
            added, removed = rb - ra, ra - rb
            if added or removed:
                print(f"{t}: +{len(added)} -{len(removed)}")
    finally:
        a.close()
        b.close()
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--seed", required=True)
    b.add_argument("--out", required=True)
    b.add_argument("--mod", action="append", help="mod folder containing a .modinfo; repeatable, applied in order")
    b.add_argument("--report")
    b.add_argument("--text-db", action="append",
                   help="Localization-*.db to seed vanilla text from; repeatable (default: the per-package "
                        "files in the game's cache folder, excluding Localization-Merged.db)")
    b.add_argument("--no-text", action="store_true", help="do not seed vanilla text")
    b.add_argument("-v", "--verbose", action="store_true", help="also print warnings and per-file status")
    b.set_defaults(fn=cmd_build)
    d = sub.add_parser("diff")
    d.add_argument("--before", required=True)
    d.add_argument("--after", required=True)
    d.add_argument("--tables")
    d.set_defaults(fn=cmd_diff)
    args = ap.parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
