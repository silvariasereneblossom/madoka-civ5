# Handover: Madoka Magica – Wish for the World revival

Status as of **2026-09-18**. This document is the entry point for anyone (human or agent) picking the project up.
It summarises where things stand and points to the detailed records; it does not replace them.

---

## 1. What this project is

A revival of Vicevirtuoso's Civilization V mod **Madoka Magica: Wish for the World** (WFTW, Steam Workshop
273118128, GUID `6938dbeb-84c4-4a08-8bc0-51fca6135175`, v27, abandoned in 2015). The goals set at the start:

1. Run it on the current Community Patch (CP) DLL, as a **bundled custom build** of that DLL.
2. Make it work on the current game build (Civ V 1.0.3.279, unchanged since 2014).
3. Maximise compatibility with other mods.
4. Fix the mechanical bugs.
5. Rework the mechanics of the ten Magical Girl civilizations (**Phase 4, mostly done**).
6. Add girls from Magia Record, Oriko Magica and Tart Magica (**Phase 5, not started**).
7. A separate Lekmod-compatible patch including multiplayer (**Phase 6, scoping next**).

Supporting records, in reading order:

| File | What it holds |
|---|---|
| `PLAN.md` | Original six-phase plan, source research, early decisions |
| `docs/port-notes.md` | Running engineering log: every non-obvious finding, crash and fix, with dates |
| `docs/review-2026-09-16.md` | Six-reviewer code review of the original mod and the fix pass that followed |
| `docs/design/mechanics-scope.md` | Phase 4 scoping: audits synthesised into proposals and questions |
| `docs/design/phase4-design-v1.md` | **The Phase 4 spec**: maintainer rulings (sections 11, 12, 15), build log (section 14) |
| `docs/design/*.md` (others) | Research reports: MG system audit, three civ-group audits, Lekmod power baseline |
| `soundtrack/README.md` | The companion soundtrack pack and the one fix applied to it |

---

## 2. Current status

**Playable.** The game reaches the map and plays with Community Patch 5.4.6 + WFTW + the companion soundtrack,
on **our own build of the CP DLL** (installed in the game's Community Patch mod folder; the original is backed up
next to it). Confirmed in game on 2026-09-18.

**Phase 4 (mechanics rework) is implemented but not yet play-tested in depth.** Everything verifies offline
(all 82 Lua files parse; the simulated database build shows only the 15 long-standing, expected failures), and the
DLL loads in game, but the new abilities and kits have not been exercised in a real game beyond startup.

| Area | State |
|---|---|
| CP integration (data, Lua API, DLL) | Done |
| Stability fix pass (crashes, desync risks, logic bugs from the review) | Done, 190+ fixes, all marked `-- [port]` |
| Music (menu theme stuck, soundtrack stopped after one song) | Fixed |
| Magical Girl system exclusive to the ten MG civs | Done |
| Ten civ kits and ten leader-girl abilities (Phase 4) | Implemented, needs play-testing |
| Bundled DLL (Devil Homura's Ai Yo, Mami's city cap) | Built, deployed, loads |
| Mami "cannot annex/raze/puppet, captures become city-states" | **Tabled** (notes in design doc section 15) |
| Kazumi | Interim kit; maintainer plans a full rework later |
| Devil Homura | Kit built; explicitly provisional pending *Walpurgisnacht Rising* |
| Phase 5 (new girls) | Not started |
| Phase 6 (Lekmod / multiplayer) | Blocker analysis done (section 9); scoping pass is the next task |

---

## 3. Repository layout

```
PLAN.md                 original plan
docs/                   everything written down (start with this file)
wftw/                   the mod itself (working copy; junctioned into the game's MODS folder)
  SQL/Phase4/<Civ>.sql  Phase 4 data per civ; load after every base civ file
  SQL/Phase4/Abilities.sql  leader-ability data, DLL-backed trait values, Devil Homura's AI personality
  Lua/Gameplay/MagicalGirls/PMMMLeaderAbilities.lua   leader-ability framework
  Lua/Gameplay/MagicalGirls/Abilities/PMMMAbility<Civ>.lua   one file per civ
rebellion/              the sibling Rebellion civ pack v12, unmodified, for reference
soundtrack/             data files of the companion soundtrack pack (MP3s not tracked)
dll/pmmm-phase4.patch   snapshot of our Community Patch DLL changes
scripts/                tooling (section 5)
upstream/  (ignored)    blobless clones of LoneGazebo/Community-Patch-DLL (5.4.6) and EnormousApplePie/Lekmod
tools/     (ignored)    extracted Windows SDK 7.0 + VC9, debugger, a 32-bit LLVM 18 (unused)
build/     (ignored)    simulator databases, probes, parked Lekmod
```

---

## 4. Environment on the development machine

- Game: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V`, DX11 exe.
- Mods: `Documents\My Games\Sid Meier's Civilization 5\MODS\`
  - `(1) Community Patch (v 151)`: copied from the upstream clone; **its DLL is our build**. Backup:
    `CvGameCore_Expansion2.dll.orig-4556AC94FC156B5EF5A09EF1B66BE666`.
  - `Madoka Magica -- Wish for the World [BNW] (v 27)`: a junction to `wftw/` in this repo.
  - `Madoka Magica Soundtrack (No Stupid Subtitles Edition) (v 6)`: companion pack; must be ticked by hand.
- `config.ini`: logging on (`LoggingEnabled`, `MessageLog`), intro video off. Backup `config.ini.bak-madoka-20260916`.
- **Lekmod is parked** (moved to `build/parked-dlc/`, including the Lekmap map scripts). It cannot coexist with CP.
  Restore with `scripts/lekmod.ps1 -Restore` and untick CP and WFTW before playing Lekmod.
- Toolchain: 64-bit LLVM 23 (winget, `C:\Program Files\LLVM\bin`); Windows SDK 7.0 and the VC9 CRT extracted
  under `tools/sdk/ext` (no system install); Lua 5.4 `luac` for syntax checks; cdb extracted under `tools/sdk/dbg`.
  Visual Studio 2022 Build Tools were installed while chasing the DLL crash and turned out **not** to be needed.

---

## 5. How to work on it

**Verify data changes offline** (the game's SQLite 3.7.17 aborts a `.sql` file at its first error; the simulator
reproduces that):

```bash
python scripts/civdb.py build --seed build/seed_vanilla_bnw.db --out build/sim_cp_wftw.db --mod "upstream/Community-Patch-DLL/(1) Community Patch" --mod wftw --report build/sim_cp_wftw.md
```

Expected: `files ok: 310  failed: 15`. The 15 are pre-existing and harmless (11 Events & Decisions files needing
a mod that is not installed, and four optional-mod compatibility files).

**Other checks and chores:**

- Lua syntax: `"$LOCALAPPDATA/Programs/Lua/bin/luac.exe" -p <file>` on every changed Lua file.
- Type references in Lua against the built DB: `python scripts/luarefs.py --db build/sim_cp_wftw.db --mod wftw`
  (46 known benign findings).
- After editing any mod file: `python scripts/modinfo_md5.py wftw` refreshes the checksums in the `.modinfo`.

**Build and install the DLL:**

```bash
python scripts/build_dll.py --config release
python scripts/deploy_dll.py --config release
```

`build_dll.py` applies `scripts/dll_patch_phase4.py` to the upstream checkout automatically (idempotent), targets
the VC9 runtime, and builds release **without** link-time optimisation (see section 6). `deploy_dll.py` refuses to
run while the game is open, backs up the original once, and fixes the Community Patch `.modinfo` checksum.
`deploy_dll.py --restore` puts the official DLL back.

**Conventions:**

- Mark every change to original mod code with `-- [port]` (Lua) or a comment naming Phase 4.
- New per-civ data goes in `wftw/SQL/Phase4/<Civ>.sql`, new ability code in the civ's `Abilities/` file.
- Multi-file work parallelises well as 4-6 agents on **disjoint** file sets, sharing the contract in
  `docs/agent-contract.md` (the brief every Phase 4 implementation agent was given).
- Commits are authored by the maintainer only; do not add co-author lines.

---

## 6. Findings that will bite you

**Game and Steam**

- Civ V exiting ~10 s after start with code `0x8000DEAD` is Steam's CEG copy protection, not a mod. Fix:
  `steam://validate/8930`. Launching the exe directly needs `SteamAppId=8930` in the environment.
- Lekmod and Community Patch cannot be loaded together (both replace the DLL, and Lekmod overrides the whole
  database). With Lekmod active, CP asserts on `GOLDEN_AGE_CULTURE_MODIFIER` then crashes; Lekmap's Pangaea
  Fractal regenerates forever without Lekmod. Park Lekmod for CP testing.

**Building the DLL**

- clang-cl must be told `-fms-compatibility-version=15.00.30729`. Upstream CI gets that from the VC9 compiler on
  its PATH; without it clang targets a modern runtime and the DLL fails to initialise (`LoadLibrary` error 1114 in
  `Logs/Gamecore.log`).
- The release DLL **with link-time optimisation fails to initialise** in the game; without `-flto` it works. The
  underlying cause is unknown (a 64-bit LLVM matching upstream CI's version is the next thing to try).
- The 32-bit LLVM 18 package runs out of memory linking. Use a 64-bit LLVM.
- The DLL fetches its allocators and string pools from the game exe at load, so it cannot be probed in a
  stand-in process; debug in game or read `Gamecore.log`.
- Our DLL reads seven `Traits.PMMM*` columns declared by WFTW's SQL, so it expects WFTW to be loaded.

**Community Patch Lua and data**

- `Unit:GetCombatDamage` is bound but stubbed to return 0 in CP 5.4.6. Use `GetMeleeCombatDamage` /
  `GetMeleeCombatDamageCity` (the ability framework's `PMMMVirtualAttack*` helpers do).
- `PlotAreaSpiralIterator(plot, r, sector, anticlock, inwards, centre)`: the last argument includes the centre tile.
- Trait yields from city-state allies and friends are multiplied by count **and** era index, in the capital only.
- `GreatWorkWLTKD` is an on/off flag (every city, ~6 turns), not a turn count; resource monopolies only apply
  with Vox Populi's monopoly option on.
- `CityCaptureComplete` fires before `acquireCity` has finished with the city; transferring the city inside it is a
  use-after-free crash.
- Game SQLite is 3.7.17: no `WITH`, no window functions; a bare `DEFAULT true/false` is a string.

**Mod architecture**

- Magical Girl state lives in `MapModData.PMMM` and is saved through TableSaverLoader, which is client-local.
  Fine in single player; a multiplayer hazard (section 9).
- The Magical Girl system is exclusive to civs whose trait sets `HasMagicalGirls` (define
  `MAGICAL_GIRLS_EXCLUSIVE_TO_MG_CIVS`, 1 by default). Witches still replace barbarians for everyone; a Witch kill by
  a civ outside the system yields no Grief Seed.

---

## 7. Phase 4 in one page

Full rulings are in `docs/design/phase4-design-v1.md`. The shape of each civ now:

| Civ | Kit highlights | Leader-girl ability |
|---|---|---|
| Madoka | Middle School replaces the National College (+40% Science, Faith, free girl) | Pluvia Magica |
| Ultimate Madoka | Law of Cycles return with promotion-scaled XP, Summon Herald of the Cycle, Luminous Garden also replaces the Grand Temple, Realm of Cycles | Nothing To Despair, Ever |
| Homura | Time Stop (a free turn), Thief of Time Scout that earns tech in foreign land, Dimensional Armory | Concentrated Missile Fire |
| Devil Homura | **Ai Yo** (DLL): no unhappiness penalties, +1% yields and strength per 5 unhappiness up to 25%, no Golden Ages, no ideology pressure, Witch gold; Clara Doll Swordsman; Half-Moon Garden; warmonger AI | Falsified Phenomena |
| Sayaka | Wonders give +5% Tourism empire-wide each, Music Hall with Decretum, Swordsman Cutlass Conductor, Tourism to Prodigy points | Baldamente Fortissimo |
| Kyouko | Luxury happiness rules, free pantheon but no religion, food buildings, Stolen Food on the Chain Lancer | Kugatachi |
| Mami | City-state yields, Teahouse gold per friend, Tiro Siege, **city soft cap** (DLL, squaring unhappiness past four cities) | Tiro Finale |
| Nagisa | Farms +Production, Pastures +Food, Magical Dairy as a Granary, Bubble Bomber splash | Magic Cake Dish |
| Kazumi | Deterministic Freezer, writing yields, random yield on Great Works (interim) | Rule Break |
| Oriko / Kirika | Extra spy rank, Sentry on all units, scaling Farsight Oracle | Oracle Ray / Vampire Fang |

Magical Girls now match the era's frontline unit at 100% strength. Every ability has an AI rule and tooltip text.

---

## 8. Known issues and open items

- **Needs a real play-test**: every leader ability (button appears, cooldown ticks, damage lands), Time Stop's free
  turn, the Freezer timers, Ai Yo's tooltip line and combat bonus, Mami's cap.
- **Tabled**: Mami's capture-to-city-state rule. Notes on the crash hazard and a safe transfer point are in design
  doc section 15.
- **Approximations**: Time Stop's free turn under-counts some healing, deal income and border growth; Kyouko's
  luxury rule treats city-state luxuries as her own.
- **Old saves**: Oriko and Kirika can each use both abilities in games started before per-girl binding.
- **Deferred from the review**: rebasing WFTW's `UnitPanel.lua` / `EnemyUnitPanel.lua` onto CP's versions; a Vox
  Populi companion; performance refactors; the multiplayer items B1, B4, B5.
- **Events & Decisions**: every civ's decisions need that mod, which is not installed; the layer is inert today.
- **Text pass**: most text was written per change; a final consistency pass over renamed civs, the Civilopedia
  and trait tooltips (for example Oriko's) is still owed.
- **Cleanup**: `tools/llvm18` (unused) and VS 2022 Build Tools (not needed) can be removed.

---

## 9. Next: Lekmod integration (Phase 6)

Not a patch: a port. Civ V loads exactly one game DLL, Lekmod ships its own, and WFTW now depends on engine
features that DLL does not have. From a check of Lekmod's DLL source (`upstream/Lekmod/LEKMOD_DLL`):

| Needed by WFTW | In Lekmod's DLL |
|---|---|
| Custom unit missions (every Magical Girl action and every ability) | No |
| Great Work creation event, per-unit promotion filter | No |
| `GetMeleeCombatDamage`, `DamageTakenMod`, city-state ally/friend yields | No |
| `StartsWithPantheon`, spy rank columns | No |
| Ai Yo and the city cap (our additions) | No |
| Turn, capture, kill, construction events; `SetPromotionReady`; `ChangeBuildProgress` | Yes |

What a Lekmod version takes:

1. A Lekmod DLL with those features ported in (open source), shipped to every player in the lobby: a fork, or
   features upstreamed to Lekmod.
2. The database layer rebuilt against Lekmod's own full-database override; `civdb.py` can be seeded from it.
3. Packaging as a DLC-folder pack, because multiplayer ignores normal mods.
4. Multiplayer safety: synced state instead of client-local saves, deterministic iteration for random choices,
   no state changes from UI code.

**The immediate next task** is a scoping pass (started and paused on 2026-09-18 with no output yet; the three
briefs are in `docs/design/lekmod-scoping-plan.md`): inventory every Community Patch dependency in WFTW (GameEvents,
Lua methods, tables, columns, defines) against Lekmod's DLL and schema, and produce a port list with effort
estimates, plus a recommendation on forking versus upstreaming.
