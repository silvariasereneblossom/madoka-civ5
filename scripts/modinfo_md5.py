#!/usr/bin/env python3
"""Refresh the md5 attribute of every <File> entry in a Civ V .modinfo.

ModBuddy writes these when it packages a mod; after editing files by hand
they go stale. The game does not verify them for locally installed mods,
but keeping them right avoids confusion and keeps the modinfo diffable.

Usage: modinfo_md5.py <mod folder> [--check]
  --check   only report mismatches, do not write
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("mod")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args(argv)

    mod = Path(args.mod)
    modinfos = sorted(mod.glob("*.modinfo"))
    if not modinfos:
        print(f"no .modinfo in {mod}", file=sys.stderr)
        return 2
    modinfo = modinfos[0]
    raw = modinfo.read_bytes()
    text = raw.decode("utf-8-sig")
    bom = raw.startswith(b"\xef\xbb\xbf")

    changed, missing = [], []

    def repl(m: re.Match) -> str:
        old_md5, rel = m.group(1), m.group(3)
        path = mod / rel.replace("\\", "/")
        if not path.is_file():
            missing.append(rel)
            return m.group(0)
        new_md5 = hashlib.md5(path.read_bytes()).hexdigest().upper()
        if new_md5 != old_md5.upper():
            changed.append((rel, old_md5, new_md5))
            return f'<File md5="{new_md5}"{m.group(2)}>{rel}</File>'
        return m.group(0)

    new_text = re.sub(r'<File md5="([0-9A-Fa-f]{32})"([^>]*)>([^<]+)</File>', repl, text)

    for rel in missing:
        print(f"MISSING  {rel}")
    for rel, old, new in changed:
        print(f"{'STALE' if args.check else 'UPDATED'}  {rel}  {old[:8]}.. -> {new[:8]}..")
    print(f"{len(changed)} changed, {len(missing)} missing")
    if changed and not args.check:
        modinfo.write_bytes((b"\xef\xbb\xbf" if bom else b"") + new_text.encode("utf-8"))
        print(f"wrote {modinfo.name}")
    return 1 if (missing or (args.check and changed)) else 0


if __name__ == "__main__":
    sys.exit(main())
