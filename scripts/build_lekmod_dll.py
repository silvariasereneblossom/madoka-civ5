#!/usr/bin/env python3
"""Build the WFTW-ported Lekmod CvGameCore_Expansion2.dll with clang-cl.

Applies dll/lekmod-wftw.patch to upstream/Lekmod/LEKMOD_DLL (idempotently: a tree
that already carries the port is detected and re-patching is skipped), then
compiles every ClCompile item of CvGameCoreDLL_Expansion2.vs2013.vcxproj's
"Mod|Win32" configuration and links with lld-link, mirroring the Community-Patch
clang build (scripts/build_dll.py wrapping upstream build_vp_clang_sdk.py):

  - 64-bit LLVM clang-cl/lld-link (a 32-bit toolchain runs out of memory);
  - -fms-compatibility-version=15.00.30729 (VC9). The game loads this DLL against
    the VC9 CRT that ships with the engine; a DLL built for a modern runtime fails
    to initialise (LoadLibrary error 1114). Lekmod's own build_mod.bat uses the v90
    PlatformToolset, so VC9 is the correct lineage here too;
  - no -flto by default (--lto for a link-time-optimised release; with our LLVM
    the LTO DLL fails to initialise in game);
  - PCH: _precompile.cpp compiled with /Yc, everything else /Yu CvGameCoreDLLPCH.h;
  - parallel compiles, one log per translation unit collected into build.log.

Build outputs go to build/lekmod-clang/ (never into the upstream tree).

Usage:
  python scripts/build_lekmod_dll.py [--config release|debug] [--lto]
                                     [--repo PATH] [--llvm-bin PATH] [--no-apply]
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPO = ROOT / "upstream" / "Lekmod"
# Lekmod ships FireWorksWin32.lib and CvWorldBuilderMapWin32.lib with MSVC /GL
# (LTCG bytecode) members, which lld-link cannot read ("is not a native COFF
# file"). Lekmod does not ship the FirePlace/CvWorldBuilderMap sources, so they
# cannot be rebuilt here; the Community-Patch checkout ships non-LTCG recompiles
# of the same objects (FireWorksWin32.obj / CvWorldBuilderMapWin32.obj, same
# member counts). The FirePlace/CvWorldBuilderMap headers were diffed CP vs
# Lekmod: all differences are parse-level (enum vs typedef, macros, 'typename'),
# and 'FString' is a typedef of 'FStringA', so the prebuilt objects are
# layout-compatible and are linked in place of the bytecode archives.
CP_REPO = ROOT / "upstream" / "Community-Patch-DLL"
NATIVE_OBJ_SUBSTITUTES = {
    "FireWorksWin32.lib": CP_REPO / "FirePlace" / "lib" / "FireWorksWin32.obj",
    "CvWorldBuilderMapWin32.lib": CP_REPO / "CvWorldBuilderMap" / "lib" / "CvWorldBuilderMapWin32.obj",
}
PATCH_FILE = ROOT / "dll" / "lekmod-wftw.patch"
# Follow-up patches applied after the main one, each detected by its own marker so reruns skip it:
# (patch file, file relative to CvGameCoreDLL_Expansion2 holding the marker, marker bytes).
EXTRA_PATCHES = [
    # 2026-09-22: CP's Units.PromotionClass, so Magical Girls level through their own promotion tree.
    (ROOT / "dll" / "lekmod-wftw-promotionclass.patch", "CvUnitClasses.h", b"GetUnitPromotionType"),
    # 2026-09-22: Ai Yo also forbids Declarations of Friendship and City-State alliances.
    (ROOT / "dll" / "lekmod-wftw-aiyo-diplomacy.patch", "CvTraitClasses.h", b"IsPMMMNoFriendship"),
    # 2026-09-22: the Clara Doll tag keeps the Magical Girl promotion tree across upgrades.
    (ROOT / "dll" / "lekmod-wftw-claradoll.patch", "CvGameCoreUtils.h", b"ePromotionClassOverride"),
    # 2026-09-22: PMMMGreatPersonExpended, the (player, unitID, unitType, x, y) hook WFTW needs.
    (ROOT / "dll" / "lekmod-wftw-gpexpended.patch", "CvPlayer.cpp", b"PMMMGreatPersonExpended"),
]
# Legacy conversion helpers (__ftol3/__ltod3) referenced by the prebuilt
# FireWorks objects; see the header comment in the file itself.
CONV_HELPERS = ROOT / "scripts" / "lekmod_conv_helpers.S"
SDK_EXT = ROOT / "tools" / "sdk" / "ext" / "Program Files"
SDK_DIR = SDK_EXT / "Microsoft SDKs" / "Windows" / "v7.0"
VC9_DIR = SDK_EXT / "Microsoft Visual Studio 9.0" / "Vc7"
# 64-bit LLVM (winget). See scripts/build_dll.py for the 32-bit-OOM and
# VC9-runtime notes; the same findings apply to this target.
LLVM_BIN = Path(r"C:\Program Files\LLVM\bin")

CORE_DLL = "CvGameCore_Expansion2"
VCXPROJ = "CvGameCoreDLL_Expansion2.vs2013.vcxproj"
PCH_H = "CvGameCoreDLLPCH.h"
PCH_CPP = "_precompile.cpp"
PATCH_MARKER = b"// WFTW Lekmod port:"  # present in CvUnitMission.cpp once patched

# Mirror of the Community Patch default libs (msvcrt.lib = VC9 CRT import lib).
DEFAULT_LIBS = [
    "winmm.lib", "kernel32.lib", "user32.lib", "gdi32.lib", "winspool.lib",
    "comdlg32.lib", "advapi32.lib", "shell32.lib", "ole32.lib", "oleaut32.lib",
    "uuid.lib", "odbc32.lib", "odbccp32.lib", "msvcrt.lib",
]
CL_SUPPRESS = [
    "invalid-offsetof",
    "tautological-constant-out-of-range-compare",
    "comment",
    "c++11-narrowing",
    # FLuaCommon.h's FLUA_COMPILE_TIME_ERROR builds a negative-size typedef via
    # 'ERROR_##name##[' - a paste MSVC accepts in its never-instantiated dead branches.
    "invalid-token-paste",
]


def clang_major(llvm_bin: Path) -> int:
    out = subprocess.run([str(llvm_bin / "clang-cl.exe"), "--version"],
                         capture_output=True, text=True).stdout
    m = re.search(r"clang version (\d+)", out)
    return int(m.group(1)) if m else 0


def apply_patch(lekmod_root: Path, patch_file: Path) -> None:
    """Idempotently apply the WFTW port patch to LEKMOD_DLL."""
    dll_root = lekmod_root / "LEKMOD_DLL"
    marker_file = dll_root / "CvGameCoreDLL_Expansion2" / "CvUnitMission.cpp"
    if not marker_file.exists():
        sys.exit(f"missing {marker_file}")
    if PATCH_MARKER in marker_file.read_bytes():
        print("patch: already applied (marker found in CvUnitMission.cpp), skipping")
        return
    print(f"patch: applying {patch_file} to {dll_root}")
    with open(patch_file, "rb") as f:
        cp = subprocess.run(["patch", "-p1", "--batch", "--forward", "-d", str(dll_root)],
                            stdin=f, capture_output=True)
    if cp.returncode != 0:
        sys.stdout.write(cp.stdout.decode("utf-8", "replace"))
        sys.stderr.write(cp.stderr.decode("utf-8", "replace"))
        sys.exit("patch failed; the tree may be half-applied - inspect it before rerunning")
    # patch --forward is silent about hunks it considers already applied; verify.
    if PATCH_MARKER not in marker_file.read_bytes():
        sys.exit("patch reported success but the marker is missing; inspect the tree")
    print("patch: applied")


def apply_extra_patches(lekmod_root: Path) -> None:
    """Idempotently apply EXTRA_PATCHES on top of the main port."""
    src = lekmod_root / "LEKMOD_DLL" / "CvGameCoreDLL_Expansion2"
    for patch_file, marker_rel, marker in EXTRA_PATCHES:
        marker_file = src / marker_rel
        if marker in marker_file.read_bytes():
            print(f"patch: {patch_file.name} already applied, skipping")
            continue
        print(f"patch: applying {patch_file.name}")
        with open(patch_file, "rb") as f:
            cp = subprocess.run(["patch", "-p1", "--batch", "--forward", "-d", str(src.parent)],
                                stdin=f, capture_output=True)
        if cp.returncode != 0 or marker not in marker_file.read_bytes():
            sys.stdout.write(cp.stdout.decode("utf-8", "replace"))
            sys.stderr.write(cp.stderr.decode("utf-8", "replace"))
            sys.exit(f"{patch_file.name} failed; inspect the tree before rerunning")


def parse_vcxproj(project_dir: Path) -> tuple[list[str], list[str], list[str], list[str], list[str]]:
    """Read the Mod|Win32 configuration: predefines, include dirs, libs, lib dirs, sources."""
    text = (project_dir / VCXPROJ).read_text(encoding="utf-8-sig")
    m = re.search(
        r"<ItemDefinitionGroup Condition=\"'?\$\(Configuration\)\|\$\(Platform\)'?=='Mod\|Win32'\">(.*?)</ItemDefinitionGroup>",
        text, re.S)
    if not m:
        sys.exit(f"no Mod|Win32 ItemDefinitionGroup in {VCXPROJ}")
    sec = m.group(1)
    predefs = re.search(r"<PreprocessorDefinitions>(.*?)</PreprocessorDefinitions>", sec, re.S)
    incdirs = re.search(r"<AdditionalIncludeDirectories>(.*?)</AdditionalIncludeDirectories>", sec, re.S)
    libs = re.search(r"<AdditionalDependencies>(.*?)</AdditionalDependencies>", sec, re.S)
    libdirs = re.search(r"<AdditionalLibraryDirectories>(.*?)</AdditionalLibraryDirectories>", sec, re.S)
    strip = lambda s: [p for p in re.split(r"[;\n]+", s.strip()) if p and not p.startswith("%(")]
    sources = re.findall(r"<ClCompile Include=\"([^\"]*)\"", text)
    if PCH_CPP not in sources:
        sys.exit(f"{PCH_CPP} missing from {VCXPROJ}")
    return (strip(predefs.group(1)), strip(incdirs.group(1)),
            strip(libs.group(1)), strip(libdirs.group(1)), sources)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default="release", choices=["release", "debug"])
    ap.add_argument("--lto", action="store_true",
                    help="release WITH -flto and /LTCG. Off by default: the LTO DLL built with our "
                         "LLVM fails to initialise in the game (LoadLibrary error 1114)")
    ap.add_argument("--repo", default=str(DEFAULT_REPO), help="Lekmod checkout root")
    ap.add_argument("--llvm-bin", default=os.environ.get("LLVM_BIN", str(LLVM_BIN)),
                    help="folder containing clang-cl.exe and lld-link.exe (env LLVM_BIN)")
    ap.add_argument("--no-apply", action="store_true", help="do not apply the WFTW patch")
    args = ap.parse_args(argv)

    lekmod_root = Path(args.repo).resolve()
    llvm_bin = Path(args.llvm_bin)
    project_dir = lekmod_root / "LEKMOD_DLL" / "CvGameCoreDLL_Expansion2"
    for p, what in [(project_dir / VCXPROJ, "Lekmod vcxproj"),
                    (project_dir / "CvGameCoreDLL.def", "module def file"),
                    (SDK_DIR / "Include", "SDK include"),
                    (SDK_DIR / "Lib", "SDK lib"),
                    (VC9_DIR / "include", "VC9 include"),
                    (VC9_DIR / "lib", "VC9 lib"),
                    (llvm_bin / "clang-cl.exe", "clang-cl"),
                    (llvm_bin / "lld-link.exe", "lld-link")] + \
                   [(sub, f"non-LTCG substitute for {name} (Community-Patch checkout)")
                    for name, sub in NATIVE_OBJ_SUBSTITUTES.items()]:
        if not p.exists():
            print(f"missing {what}: {p}", file=sys.stderr)
            return 2
    if not args.no_apply:
        apply_patch(lekmod_root, PATCH_FILE)
        apply_extra_patches(lekmod_root)

    predefs, incdirs, libs, libdirs, sources = parse_vcxproj(project_dir)
    sources = [s for s in sources if s != PCH_CPP]
    for s in sources:
        if not (project_dir / s).exists():
            sys.exit(f"source listed in {VCXPROJ} is missing: {s}")
    print(f"{len(sources)} translation units + PCH")

    build_dir = ROOT / "build" / "lekmod-clang" / args.config.capitalize()
    out_dir = ROOT / "build" / "lekmod-clang" / "out" / args.config.capitalize()
    for d in (build_dir, out_dir):
        d.mkdir(parents=True, exist_ok=True)
    for s in sources + [PCH_CPP]:
        (build_dir / Path(s).parent).mkdir(parents=True, exist_ok=True)

    major = clang_major(llvm_bin)
    cl_args = ["-m32", "-msse3", "/c", "/MD", "/GS", "/EHsc", "/fp:precise",
               "/Zc:wchar_t", "/Zi", "/FS",
               # target the Visual C++ 2008 runtime; see module docstring
               "-fms-compatibility-version=15.00.30729",
               # MSVC-style late template parsing: the Fireworks container templates
               # (FFastVector/FStaticVector etc.) use unqualified lookups into
               # dependent base classes (Destroy/Copy/m_uiCurrSize) that MSVC
               # resolves at instantiation time; without this flag clang hard-errors.
               "-fdelayed-template-parsing"]
    if args.config == "release":
        cl_args += ["/Ox", "/Ob2", "/Zo"]
        if args.lto:
            cl_args.append("-flto")
    else:
        cl_args += ["/Od", "/Oy-"]
    for predef in predefs:
        cl_args.append(f"/D{predef}")
    for inc in ["."] + incdirs:  # project dir first, as the MSVC build implies it
        inc = inc.replace("$(SolutionDir)", "").replace("$(ProjectDir)", "").strip("\\/")
        cl_args.append(f'/I"{project_dir / inc}"')
    # clang-builtin va_start over VC9's pointer-arithmetic one; must precede the VC9 folder (see the header)
    cl_args.append(f'-external:I"{ROOT / "scripts" / "clang-shim"}"')
    cl_args.append(f'-external:I"{SDK_DIR / "Include"}"')
    cl_args.append(f'-external:I"{VC9_DIR / "include"}"')
    cl_args += [f"-Wno-{s}" for s in CL_SUPPRESS]
    if major and major < 20:
        # LLVM 16-19 reject casting MAX_CIV_PLAYERS to PlayerTypes in a constant
        # expression (CvUnit.cpp: GET_PLAYER(BARBARIAN_PLAYER)) as error-by-default.
        cl_args.append("-Wno-enum-constexpr-conversion")
    cl_arg_str = " ".join(cl_args)

    log_path = out_dir / "build.log"
    log = open(log_path, "wb")
    try:
        pch_path = build_dir / (PCH_H + ".pch")
        if not compile_one(llvm_bin, project_dir / PCH_CPP, build_dir / (PCH_CPP + ".obj"),
                           cl_arg_str, f'/Yc"{PCH_H}" /Fp"{pch_path}"', log,
                           "-- precompiled header --"):
            print("PCH build failed - see " + str(log_path), file=sys.stderr)
            return 1
        print("precompiled header done")

        failures = compile_all(llvm_bin, project_dir, sources, build_dir, cl_arg_str,
                               pch_path, log)
        if failures:
            print(f"{len(failures)} translation unit(s) failed - see {log_path}", file=sys.stderr)
            for f in failures:
                print(f"  failed: {f}", file=sys.stderr)
            return 1
        print(f"{len(sources)} translation units done")

        return link(llvm_bin, project_dir, libs, libdirs, sources, build_dir, out_dir,
                    log, args)
    finally:
        log.close()


def compile_one(llvm_bin: Path, src: Path, obj: Path, cl_arg_str: str, extra: str,
                log, banner: str) -> bool:
    command = f'"{llvm_bin / "clang-cl.exe"}" "{src}" /Fo"{obj}" {extra} {cl_arg_str}'
    cp = subprocess.run(command, capture_output=True)
    log.write(banner.encode() + b"\n")
    log.write(cp.stdout)
    log.write(cp.stderr)
    log.flush()
    return cp.returncode == 0


def compile_all(llvm_bin: Path, project_dir: Path, sources: list[str], build_dir: Path,
                cl_arg_str: str, pch_path: Path, log) -> list[str]:
    """Spawn compiles in parallel (capped), then drain and collect failures."""
    jobs = max(2, (os.cpu_count() or 4))
    running: list[tuple[str, subprocess.Popen, "tempfile._TemporaryFileWrapper"]] = []
    import tempfile
    pending = list(sources)
    failures: list[str] = []

    def spawn(src: str):
        obj = build_dir / (Path(src).with_suffix(".obj").as_posix())
        tmp = tempfile.TemporaryFile()
        command = (f'"{llvm_bin / "clang-cl.exe"}" "{project_dir / src}" /Fo"{obj}" '
                   f'/Yu"{PCH_H}" /Fp"{pch_path}" {cl_arg_str}')
        running.append((src, subprocess.Popen(command, stdout=tmp, stderr=subprocess.STDOUT), tmp))

    print(f"compiling {len(sources)} translation units, {jobs} parallel...")
    start = time.time()
    while pending or running:
        while pending and len(running) < jobs:
            spawn(pending.pop())
        for entry in running[:]:
            src, proc, tmp = entry
            if proc.poll() is None:
                continue
            running.remove(entry)
            tmp.seek(0)
            data = tmp.read()
            tmp.close()
            log.write(f"==== {src} ====\n".encode())
            log.write(data)
            log.flush()
            if proc.returncode != 0:
                failures.append(src)
                tail = data.decode("utf-8", "replace")
                sys.stdout.write(f"FAILED {src}:\n{tail[-2000:]}\n")
    print(f"compiles finished after {time.time() - start:.0f}s")
    return failures


def link(llvm_bin: Path, project_dir: Path, libs: list[str], libdirs: list[str],
         sources: list[str], build_dir: Path, out_dir: Path, log, args) -> int:
    print("linking...")
    link_args = ["/MACHINE:x86", "/DLL", "/DEBUG", "/DYNAMICBASE", "/NXCOMPAT",
                 "/SUBSYSTEM:WINDOWS", "/MANIFEST:EMBED", "/FORCE:MULTIPLE",
                 f'/DEF:"{project_dir / "CvGameCoreDLL.def"}"']
    if args.config == "release":
        link_args += ["/OPT:REF", "/OPT:ICF"]
    if args.lto:
        link_args.append("/LTCG")

    rsp = build_dir / "link.rsp"
    # assemble the legacy conversion helpers (see CONV_HELPERS) into the build dir
    conv_obj = build_dir / "lekmod_conv_helpers.obj"
    cp_asm = subprocess.run([str(llvm_bin / "clang.exe"), "-m32", "-c",
                             str(CONV_HELPERS), "-o", str(conv_obj)], capture_output=True)
    log.write(f"Conv helpers: clang -m32 -c {CONV_HELPERS}\n".encode())
    log.write(cp_asm.stdout); log.write(cp_asm.stderr); log.flush()
    if cp_asm.returncode != 0 or not conv_obj.exists():
        sys.stderr.write(cp_asm.stderr.decode("utf-8", "replace")[-2000:])
        print("conversion helper assembly failed - see " + str(out_dir / "build.log"), file=sys.stderr)
        return 1
    with open(rsp, "w") as f:
        f.write(f'/OUT:"{out_dir / (CORE_DLL + ".dll")}"\n/PDB:"{out_dir / (CORE_DLL + ".pdb")}"\n')
        f.write("\n".join(link_args) + "\n")
        for lib_path in [VC9_DIR / "lib", SDK_DIR / "Lib"] + [
                project_dir / d.replace("$(SolutionDir)", "").strip("\\/") for d in libdirs]:
            f.write(f'/LIBPATH:"{lib_path}"\n')
        for lib in libs:
            # see NATIVE_OBJ_SUBSTITUTES: two of Lekmod's prebuilt archives hold
            # MSVC /GL bytecode that lld-link cannot read; link the Community
            # Patch non-LTCG recompiles instead.
            if lib in NATIVE_OBJ_SUBSTITUTES:
                f.write(f'"{NATIVE_OBJ_SUBSTITUTES[lib]}"\n')
            else:
                f.write(f"{lib}\n")
        for lib in DEFAULT_LIBS:
            f.write(f"{lib}\n")
        f.write(f'"{conv_obj}"\n')
        f.write(f'"{build_dir / (PCH_CPP + ".obj")}"\n')
        for src in sources:
            f.write(f'"{build_dir / (Path(src).with_suffix(".obj").as_posix())}"\n')
    command = f'"{llvm_bin / "lld-link.exe"}" @"{rsp}"'
    start = time.time()
    cp = subprocess.run(command, capture_output=True)
    log.write(f"Linking command: {command}\n".encode())
    log.write(cp.stdout)
    log.write(cp.stderr)
    log.flush()
    if cp.returncode != 0:
        sys.stderr.write(cp.stderr.decode("utf-8", "replace")[-4000:])
        print("linking failed - see " + str(out_dir / "build.log"), file=sys.stderr)
        return 1
    print(f"linked {out_dir / (CORE_DLL + '.dll')} in {time.time() - start:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())