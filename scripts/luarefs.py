#!/usr/bin/env python3
"""Cross-check a mod's Lua against a simulated game database.

Finds, in every .lua under the mod:
  * GameInfoTypes.X / GameInfoTypes["X"]      -> X must be a Type in some table
  * GameInfo.Table[...] / GameInfo.Table(...)  -> table must exist
  * GameInfo.Table[...].Column                 -> column must exist on that table
  * GameInfo.Table.X (row-by-type shorthand)   -> X must be a Type in that table
  * string literals that look like game types ('BUILDING_...', 'UNIT_...', ...)
    -> must exist as a Type somewhere (a missing one usually means a row
       failed to load, or a typo)

Usage: luarefs.py --db build/sim.db --mod wftw [--ignore-prefix TXT_KEY_ ...]
"""
from __future__ import annotations

import argparse
import re
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

TYPE_PREFIXES = ("BUILDING_", "BUILDINGCLASS_", "UNIT_", "UNITCLASS_", "UNITCOMBAT_", "PROMOTION_",
                 "TRAIT_", "POLICY_", "POLICY_BRANCH_", "MISSION_", "CIVILIZATION_", "LEADER_",
                 "TECH_", "ERA_", "RESOURCE_", "IMPROVEMENT_", "FEATURE_", "TERRAIN_", "BELIEF_",
                 "RELIGION_", "SPECIALIST_", "YIELD_", "DOMAIN_", "MINOR_CIV_", "PROJECT_",
                 "ARTSTYLE_", "GAMESPEED_", "HANDICAP_", "BUILD_", "ROUTE_", "PLAYERCOLOR_",
                 "COLOR_", "DIPLO_MODIFIER_", "NOTIFICATION_", "SOUND_", "AS2D_", "COMMAND_",
                 "ACTIVITY_", "GREAT_WORK_", "GREATWORK_", "FLAVOR_", "DIRECTION_")
SKIP_SUBSTRINGS = ("_ATLAS",)  # atlas names are not Type rows


def load_db(db: Path):
    conn = sqlite3.connect(db)
    tables = {r[0] for r in conn.execute("select name from sqlite_master where type='table'")}
    cols = {t: {r[1] for r in conn.execute(f'pragma table_info("{t}")')} for t in tables}
    types_by_table: dict[str, set[str]] = {}
    all_types: set[str] = set()
    for t in tables:
        if "Type" in cols[t]:
            vals = {r[0] for r in conn.execute(f'select Type from "{t}" where Type is not null')}
            types_by_table[t] = vals
            all_types |= vals
    return tables, cols, types_by_table, all_types


def strip_lua_comments(src: str) -> str:
    """Blank comments without touching string literals ("--" inside a string is common)."""
    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        if ch == "-" and src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:                                             # long comment --[==[ ... ]==]
                close = "]" + m.group(1) + "]"
                j = src.find(close, i + m.end())
                j = n if j < 0 else j + len(close)
            else:                                             # line comment
                j = src.find("\n", i)
                j = n if j < 0 else j
            out.append("".join("\n" if c == "\n" else " " for c in src[i:j]))
            i = j
        elif ch in ("'", '"'):                                # short string with escapes
            j = i + 1
            while j < n and src[j] != ch:
                j += 2 if src[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(src[i:j])
            i = j
        elif ch == "[" and re.match(r"\[=*\[", src[i:]):      # long string [==[ ... ]==]
            m = re.match(r"\[(=*)\[", src[i:])
            close = "]" + m.group(1) + "]"
            j = src.find(close, i + m.end())
            j = n if j < 0 else j + len(close)
            out.append(src[i:j])
            i = j
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--mod", required=True)
    ap.add_argument("--ignore-prefix", action="append", default=None)
    args = ap.parse_args(argv)
    ignore_prefixes = tuple(args.ignore_prefix or ())

    tables, cols, types_by_table, all_types = load_db(Path(args.db))
    problems: dict[str, set[str]] = defaultdict(set)

    for lua in sorted(Path(args.mod).rglob("*.lua")):
        src = strip_lua_comments(lua.read_text(encoding="utf-8-sig", errors="replace"))
        rel = str(lua.relative_to(args.mod))

        for m in re.finditer(r'GameInfoTypes(?:\.([A-Z][A-Z0-9_]+)|\[\s*["\']([A-Z][A-Z0-9_]+)["\']\s*\])', src):
            t = m.group(1) or m.group(2)
            if t not in all_types:
                problems[rel].add(f"GameInfoTypes.{t}: no row with that Type in any table")

        for m in re.finditer(r"GameInfo\.([A-Za-z_][A-Za-z0-9_]*)\s*([\[\(\{\.])", src):
            table, opener = m.group(1), m.group(2)
            if table not in tables:
                problems[rel].add(f"GameInfo.{table}: table does not exist")
                continue
            if opener == ".":
                tail = src[m.end():m.end() + 80]
                mm = re.match(r"([A-Z][A-Z0-9_]+)", tail)
                if mm and mm.group(1) not in types_by_table.get(table, set()):
                    problems[rel].add(f"GameInfo.{table}.{mm.group(1)}: no such Type in {table}")
            elif opener == "[":
                # GameInfo.Table[expr].Column
                depth, i = 1, m.end()
                while i < len(src) and depth:
                    depth += {"[": 1, "]": -1}.get(src[i], 0)
                    i += 1
                mm = re.match(r"\.([A-Za-z_][A-Za-z0-9_]*)", src[i:i + 60])
                if mm and mm.group(1) not in cols[table] and mm.group(1) not in ("ID",):
                    problems[rel].add(f"GameInfo.{table}[..].{mm.group(1)}: column missing on {table}")

        for m in re.finditer(r"""['"]([A-Z][A-Z0-9]*_[A-Z0-9_]+)['"]""", src):
            lit = m.group(1)
            if not lit.startswith(TYPE_PREFIXES) or any(s in lit for s in SKIP_SUBSTRINGS):
                continue
            if ignore_prefixes and lit.startswith(ignore_prefixes):
                continue
            if lit in all_types:
                continue
            problems[rel].add(f"literal '{lit}': no row with that Type in any table")

    total = sum(len(v) for v in problems.values())
    for rel, items in problems.items():
        print(f"== {rel}")
        for it in sorted(items):
            print("   " + it)
    print(f"\n{total} findings in {len(problems)} files "
          f"(db: {len(tables)} tables, {len(all_types)} Type values)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
