#!/usr/bin/env python3
"""Offline Civ V mod database simulator.

Seeds a SQLite database from the game's cached core database, then replays each
mod's <UpdateDatabase> actions (SQL and Civ V XML) in modinfo order, emulating
the game's loader closely enough to surface every database error before the
game is ever launched:

  * SQL files run through sqlite3_exec semantics: statements execute in order
    and the file is abandoned at the first error.
  * XML files follow the Civ V GameData grammar: <Table>/<Column> schema,
    <Row>, <Replace>, <Update><Where/><Set/></Update>, <Delete>. A failing
    element aborts the rest of that file, like the game.

Usage:
  civdb.py build --seed core.db --out sim.db [--mod DIR ...] [--report report.md]
  civdb.py diff  --before a.db --after b.db --tables Civilizations,Leaders ...
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import sqlite3
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

LANGUAGES = ["en_US", "DE_DE", "ES_ES", "FR_FR", "IT_IT", "JA_JP", "KO_KR", "PL_PL", "RU_RU", "ZH_Hant_HK"]


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
    tree = ET.parse(modinfo)
    root = tree.getroot()
    name = root.findtext("Properties/Name") or modinfo.stem
    files = []
    for act in root.findall("Actions/OnModActivated/UpdateDatabase"):
        if act.text:
            files.append(act.text.strip())
    return name, files


def resolve_case_insensitive(base: Path, rel: str) -> Path | None:
    """Windows resolves paths case-insensitively; emulate that on any host."""
    p = base
    for part in re.split(r"[\\/]+", rel):
        if not part:
            continue
        if not p.is_dir():
            return None
        match = None
        for child in p.iterdir():
            if child.name.lower() == part.lower():
                match = child
                break
        if match is None:
            return None
        p = match
    return p


# ----------------------------------------------------------------------------
# SQL application
# ----------------------------------------------------------------------------

def strip_sql_comments(sql: str) -> str:
    # Keep it simple: sqlite tolerates -- comments, but complete_statement()
    # can be confused by semicolons inside comments; strip line comments.
    out = []
    for line in sql.splitlines():
        # remove -- comments not inside quotes (good enough for mod SQL)
        i, in_q = 0, None
        cut = None
        while i < len(line):
            ch = line[i]
            if in_q:
                if ch == in_q:
                    in_q = None
            elif ch in ("'", '"'):
                in_q = ch
            elif ch == "-" and line[i:i + 2] == "--":
                cut = i
                break
            i += 1
        out.append(line if cut is None else line[:cut])
    return "\n".join(out)


def split_statements(sql: str) -> list[str]:
    sql = strip_sql_comments(sql)
    # remove /* */ block comments
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.S)
    stmts, buf = [], []
    for line in sql.splitlines(keepends=True):
        buf.append(line)
        if sqlite3.complete_statement("".join(buf)):
            s = "".join(buf).strip()
            if s:
                stmts.append(s)
            buf = []
    tail = "".join(buf).strip()
    if tail:
        stmts.append(tail)
    return stmts


def apply_sql(conn: sqlite3.Connection, text: str, mod: str, file: str, rep: Report) -> bool:
    stmts = split_statements(text)
    for idx, s in enumerate(stmts):
        try:
            conn.execute("SAVEPOINT stmt")
            conn.execute(s)
            conn.execute("RELEASE stmt")
        except sqlite3.Error as e:
            conn.execute("ROLLBACK TO stmt")
            conn.execute("RELEASE stmt")
            excerpt = re.sub(r"\s+", " ", s)[:220]
            rep.error(mod, file, f"SQL error at statement {idx + 1}/{len(stmts)}: {e}",
                      f"{excerpt}  [remaining {len(stmts) - idx - 1} statements skipped]")
            return False
    return True


# ----------------------------------------------------------------------------
# XML application (Civ V GameData grammar)
# ----------------------------------------------------------------------------

def _lit(v: str):
    if v is None:
        return None
    lv = v.strip().lower()
    if lv == "true":
        return 1
    if lv == "false":
        return 0
    return v


def _kv_from_element(el: ET.Element) -> dict:
    """Attributes and/or child elements form column=value pairs."""
    d = {k: _lit(v) for k, v in el.attrib.items()}
    for child in el:
        d[child.tag] = _lit(child.text if child.text is not None else "")
    return d


def _quote_ident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def apply_table_def(conn, el: ET.Element, mod, file, rep) -> None:
    name = el.get("name")
    cols = []
    for c in el.findall("Column"):
        cname = c.get("name")
        ctype = c.get("type", "text").lower()
        parts = [_quote_ident(cname), {"integer": "integer", "int": "integer", "boolean": "boolean",
                                        "text": "text", "real": "real"}.get(ctype, ctype)]
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
        if c.get("reference"):
            parts.append("references " + c.get("reference"))
        cols.append(" ".join(parts))
    exists = conn.execute("select 1 from sqlite_master where type='table' and name=?", (name,)).fetchone()
    if exists:
        rep.warn(mod, file, f"<Table name=\"{name}\"> already exists; game would raise 'table already exists'")
        return
    conn.execute(f"create table {_quote_ident(name)} ({', '.join(cols)})")


def apply_xml(conn: sqlite3.Connection, text: str, mod: str, file: str, rep: Report) -> bool:
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
                apply_table_def(conn, table_el, mod, file, rep)
            except sqlite3.Error as e:
                rep.error(mod, file, f"<Table name=\"{table_el.get('name')}\">: {e}")
                return False
            continue
        for op in table_el:
            try:
                conn.execute("SAVEPOINT op")
                _apply_op(conn, table, op)
                conn.execute("RELEASE op")
            except sqlite3.Error as e:
                conn.execute("ROLLBACK TO op")
                conn.execute("RELEASE op")
                snippet = ET.tostring(op, encoding="unicode")
                snippet = re.sub(r"\s+", " ", snippet)[:220]
                # The game's XML loader logs the failing element and keeps going
                # with the next one (unlike sqlite3_exec on .sql files).
                rep.error(mod, file, f"<{table}><{op.tag}>: {e}", snippet)
                ok = False
    return ok


def _apply_op(conn, table, op: ET.Element):
    t = _quote_ident(table)
    if op.tag in ("Row", "Replace"):
        kv = _kv_from_element(op)
        cols = ", ".join(_quote_ident(k) for k in kv)
        qs = ", ".join("?" for _ in kv)
        verb = "insert or replace" if op.tag == "Replace" else "insert"
        conn.execute(f"{verb} into {t} ({cols}) values ({qs})", list(kv.values()))
    elif op.tag == "Update":
        where_el = op.find("Where")
        set_el = op.find("Set")
        if set_el is None:
            raise sqlite3.OperationalError("<Update> without <Set>")
        sets = _kv_from_element(set_el)
        wheres = _kv_from_element(where_el) if where_el is not None else {}
        sql = f"update {t} set " + ", ".join(f"{_quote_ident(k)}=?" for k in sets)
        params = list(sets.values())
        if wheres:
            sql += " where " + " and ".join(f"{_quote_ident(k)}=?" for k in wheres)
            params += list(wheres.values())
        conn.execute(sql, params)
    elif op.tag == "Delete":
        wheres = _kv_from_element(op)
        sql = f"delete from {t}"
        params = []
        if wheres:
            sql += " where " + " and ".join(f"{_quote_ident(k)}=?" for k in wheres)
            params = list(wheres.values())
        conn.execute(sql, params)
    else:
        raise sqlite3.OperationalError(f"unknown element <{op.tag}> under <{table}>")


# ----------------------------------------------------------------------------
# driver
# ----------------------------------------------------------------------------

def ensure_language_tables(conn):
    for lang in LANGUAGES:
        conn.execute(f'create table if not exists "Language_{lang}" '
                     '(Tag text, Text text, Gender text, Plurality text)')


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
        raw = path.read_bytes()
        text = raw.decode("utf-8-sig", errors="replace")
        ok = apply_sql(conn, text, name, rel, rep) if path.suffix.lower() == ".sql" \
            else apply_xml(conn, text, name, rel, rep)
        if ok:
            rep.files_ok += 1
        else:
            rep.files_failed += 1
        if verbose:
            print(("   ok  " if ok else "   FAIL") + rel)
    conn.commit()


def cmd_build(args):
    out = Path(args.out)
    shutil.copy(args.seed, out)
    conn = sqlite3.connect(out)
    conn.execute("pragma foreign_keys=off")
    ensure_language_tables(conn)
    rep = Report()
    for m in args.mod or []:
        apply_mod(conn, Path(m), rep, args.verbose)
    conn.commit()
    conn.close()
    errs = [p for p in rep.problems if p.kind == "error"]
    warns = [p for p in rep.problems if p.kind == "warning"]
    print(f"\nfiles ok: {rep.files_ok}  failed: {rep.files_failed}  errors: {len(errs)}  warnings: {len(warns)}")
    for p in rep.problems:
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
    tables = args.tables.split(",") if args.tables else [r[0] for r in b.execute(
        "select name from sqlite_master where type='table' order by name")]
    for t in tables:
        try:
            ra = set(a.execute(f'select * from "{t}"').fetchall())
        except sqlite3.Error:
            ra = set()
        rb = set(b.execute(f'select * from "{t}"').fetchall())
        added, removed = rb - ra, ra - rb
        if added or removed:
            print(f"{t}: +{len(added)} -{len(removed)}")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--seed", required=True)
    b.add_argument("--out", required=True)
    b.add_argument("--mod", action="append", help="mod folder containing a .modinfo; repeatable, applied in order")
    b.add_argument("--report")
    b.add_argument("-v", "--verbose", action="store_true")
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
