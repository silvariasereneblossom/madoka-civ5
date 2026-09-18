#!/usr/bin/env python3
"""Install the bundled Community Patch DLL into the game's (1) Community Patch mod folder.

Backs up the DLL it replaces (once, as CvGameCore_Expansion2.dll.orig-<md5>), copies the freshly built
release DLL over it, and refreshes its md5 in the Community Patch .modinfo so the game accepts it.
Refuses to run while Civilization V is open.

Usage:
  python scripts/deploy_dll.py [--config release|debug] [--restore]
"""
import argparse
import hashlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "upstream" / "Community-Patch-DLL" / "clang-output"
MODS = Path.home() / "Documents" / "My Games" / "Sid Meier's Civilization 5" / "MODS"
CP = MODS / "(1) Community Patch (v 151)"
DLL = "CvGameCore_Expansion2.dll"


def md5(p: Path) -> str:
    return hashlib.md5(p.read_bytes()).hexdigest().upper()


def game_running() -> bool:
    out = subprocess.run(["tasklist"], capture_output=True, text=True).stdout
    return "CivilizationV" in out


def set_modinfo_md5(new_md5: str) -> None:
    modinfo = next(CP.glob("*.modinfo"))
    text = modinfo.read_text(encoding="utf-8")
    pat = re.compile(r'(<File md5=")[0-9A-Fa-f]{32}(" import="1">' + re.escape(DLL) + r'</File>)')
    if len(pat.findall(text)) != 1:
        sys.exit(f"could not find exactly one {DLL} entry in {modinfo}")
    modinfo.write_text(pat.sub(lambda m: m.group(1) + new_md5 + m.group(2), text), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default="release", choices=["release", "debug"])
    ap.add_argument("--restore", action="store_true", help="put the original Community Patch DLL back")
    args = ap.parse_args()

    if game_running():
        sys.exit("Civilization V is running. Close it first.")
    target = CP / DLL
    if not target.exists():
        sys.exit(f"no {DLL} in {CP}")

    backups = sorted(CP.glob(DLL + ".orig-*"))
    if args.restore:
        if not backups:
            sys.exit("no backup to restore")
        shutil.copy2(backups[0], target)
        set_modinfo_md5(md5(target))
        print(f"restored {backups[0].name}")
        return 0

    source = BUILD / args.config.capitalize() / DLL
    if not source.exists():
        sys.exit(f"build it first: python scripts/build_dll.py --config {args.config}")
    if not backups:
        backup = CP / f"{DLL}.orig-{md5(target)}"
        shutil.copy2(target, backup)
        print(f"backed up the original as {backup.name}")
    shutil.copy2(source, target)
    set_modinfo_md5(md5(target))
    print(f"installed {args.config} DLL ({md5(target)}) into {CP.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
