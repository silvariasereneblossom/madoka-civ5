#!/usr/bin/env python3
"""Install the freshly built WFTW Lekmod DLL into a Lekmod DLC folder.

Takes the DLC folder path as an argument (the folder that contains Lekmod's
CvGameCore_Expansion2.dll inside the game's Assets/DLC tree), backs the original
DLL up once (as CvGameCore_Expansion2.dll.orig-<md5>) and copies the build
output over it. --restore puts the original back. Refuses to run while
Civilization V is open, and refuses to touch the parked v34.15 install at
build/parked-dlc/.

Usage:
  python scripts/deploy_lekmod_dll.py <path-to-lekmod-dlc-folder> [--config release|debug] [--restore]
"""
import argparse
import hashlib
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "lekmod-clang" / "out"
PARKED = ROOT / "build" / "parked-dlc"
DLL = "CvGameCore_Expansion2.dll"


def md5(p: Path) -> str:
    return hashlib.md5(p.read_bytes()).hexdigest().upper()


def game_running() -> bool:
    out = subprocess.run(["tasklist"], capture_output=True, text=True).stdout
    return "CivilizationV" in out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dlc_folder", help="folder containing Lekmod's CvGameCore_Expansion2.dll")
    ap.add_argument("--config", default="release", choices=["release", "debug"])
    ap.add_argument("--restore", action="store_true", help="put the backed-up original DLL back")
    args = ap.parse_args()

    if game_running():
        sys.exit("Civilization V is running. Close it first.")

    target_dir = Path(args.dlc_folder).resolve()
    if PARKED == target_dir or PARKED in target_dir.parents:
        sys.exit(f"refusing to touch the parked v34.15 install at {PARKED}")
    target = target_dir / DLL
    if not target.exists():
        sys.exit(f"no {DLL} in {target_dir}")

    backups = sorted(target_dir.glob(DLL + ".orig-*"))
    if args.restore:
        if not backups:
            sys.exit("no backup to restore")
        shutil.copy2(backups[0], target)
        print(f"restored {backups[0].name}")
        return 0

    source = BUILD / args.config.capitalize() / DLL
    if not source.exists():
        sys.exit(f"build it first: python scripts/build_lekmod_dll.py --config {args.config}")
    if not backups:
        backup = target_dir / f"{DLL}.orig-{md5(target)}"
        shutil.copy2(target, backup)
        print(f"backed up the original as {backup.name}")
    shutil.copy2(source, target)
    print(f"installed {args.config} DLL ({md5(target)}) into {target_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())