#!/usr/bin/env python3
"""Build CvGameCore_Expansion2.dll with clang, using a locally extracted
Windows SDK 7.0 + VC9 tree instead of a system install.

This wraps upstream's build_vp_clang_sdk.py (Community-Patch-DLL) and rewrites
its hard-coded 'C:\\Program Files (x86)\\...' paths to the administrative MSI
extraction under tools/sdk/ext. Nothing is installed system-wide.

Usage:
  python scripts/build_dll.py [--config debug|release] [--repo PATH]
"""
from __future__ import annotations

import argparse
import os
import runpy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPO = ROOT / "upstream" / "Community-Patch-DLL"
SDK_EXT = ROOT / "tools" / "sdk" / "ext" / "Program Files"
SDK_DIR = SDK_EXT / "Microsoft SDKs" / "Windows" / "v7.0"
VC9_DIR = SDK_EXT / "Microsoft Visual Studio 9.0" / "Vc7"
LLVM_BIN = Path(r"C:\Program Files\LLVM\bin")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="debug", choices=["debug", "release"])
    ap.add_argument("--repo", default=str(DEFAULT_REPO), help="Community-Patch-DLL checkout (or your fork)")
    args = ap.parse_args(argv)

    repo = Path(args.repo).resolve()
    script = repo / "build_vp_clang_sdk.py"
    for p, what in [(script, "upstream build script"), (SDK_DIR / "Include", "SDK include"),
                    (SDK_DIR / "Lib", "SDK lib"), (VC9_DIR / "include", "VC9 include"),
                    (VC9_DIR / "lib", "VC9 lib"), (LLVM_BIN / "clang-cl.exe", "clang-cl"),
                    (LLVM_BIN / "lld-link.exe", "lld-link")]:
        if not p.exists():
            print(f"missing {what}: {p}", file=sys.stderr)
            return 2

    src = script.read_text(encoding="utf-8")
    sdk = str(SDK_DIR).replace("\\", "\\\\")
    vc = str(VC9_DIR).replace("\\", "\\\\")
    patched = (src
               .replace(r"rf'C:\Program Files (x86)\Microsoft SDKs\Windows\v{SDK_VERSION}\Include'", f"r'{SDK_DIR}\\Include'")
               .replace(r"rf'C:\Program Files (x86)\Microsoft SDKs\Windows\v{SDK_VERSION}\Lib'", f"r'{SDK_DIR}\\Lib'")
               .replace(r"rf'C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\include'", f"r'{VC9_DIR}\\include'")
               .replace(r"sdk_path = rf'C:\Program Files (x86)\Microsoft SDKs\Windows\v{sdk_version}'", f"sdk_path = r'{SDK_DIR}'")
               .replace(r"vs_path = r'C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC'", f"vs_path = r'{VC9_DIR}'"))
    if patched == src:
        print("warning: no path substitutions applied; upstream script layout changed", file=sys.stderr)
    # The upstream script's set_environment also prepends VC9\lib via LIB; keep VC9 lib on the link path too.
    patched = patched.replace("LIB_PATHS = [\n", f"LIB_PATHS = [\n    r'{VC9_DIR}\\lib',\n", 1)

    tmp = repo / "build_vp_clang_local.py"
    tmp.write_text(patched, encoding="utf-8")

    os.environ["PATH"] = str(LLVM_BIN) + os.pathsep + os.environ.get("PATH", "")
    os.chdir(repo)
    sys.argv = [str(tmp), "--config", args.config]
    try:
        runpy.run_path(str(tmp), run_name="__main__")
    except SystemExit as e:
        return int(e.code or 0)
    return 0


if __name__ == "__main__":
    sys.exit(main())
