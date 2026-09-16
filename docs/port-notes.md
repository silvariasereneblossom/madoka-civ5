# Porting Wish for the World to Community Patch 5.4.6 — working notes

Started 2026-09-16. Companion to `../PLAN.md`. Everything here was checked
against the files in `wftw/` (Workshop v27) and the CP 5.4.6 checkout in
`upstream/Community-Patch-DLL`.

## Dependency facts

- WFTW's hard dependency GUID `d1b6328c-ff44-4b0d-aad7-c657f83610cd` (labelled
  "DLL - Various Mod Components" in its modinfo) is the GUID the Community
  Patch still uses. Minimum version 66; CP 5.4.6's modinfo is v151, so the
  dependency resolves as-is.
- WFTW's Workshop build is **v27**, one newer than the last public change note.
- CP-only (no Vox Populi) is still a supported configuration and is what WFTW
  targets. CP's own note: "Community Patch Only isn't compatible with EUI."

## Tooling

- `scripts/civdb.py` replays each mod's `<UpdateDatabase>` actions onto a copy
  of the game's cached database with the game's error semantics (SQL files
  abort at the first failing statement; XML files log and continue). Seed:
  `build/seed_vanilla_bnw.db`, a copy of `cache/Civ5DebugDatabase.db` taken
  with Lekmod removed from the DLC folder (45 civs, 369 tables). The
  `Civ5CoreDatabase.db` is base-game only (20 civs) and is not usable as a seed.
  `build/seed_lekmod34_core.db` is the Lekmod v34.15 world for Phase 6.
  Vanilla text is seeded from the per-package `cache/Localization-*.db`
  files (24,525 en_US tags) behind the game's `Language_en_US` view and
  INSTEAD OF triggers, so duplicate-tag and missing-key behaviour matches.
  Correction (2026-09-16 review): the first version's SQL comment stripper
  broke on `--` inside `/* */` banners and silently dropped statements (23 of
  46 in `PMMMNonMGPromotions.sql`) while reporting the file OK; the error
  counts quoted above were unaffected, but data completeness was not. Fixed;
  the tool now also warns on zero-row updates, bare `DEFAULT true/false`
  (a string default on the game's SQLite 3.7.17) and dangling references.
- `scripts/build_dll.py` builds `CvGameCore_Expansion2.dll` with LLVM 23 and a
  locally extracted Windows SDK 7.0 + VC9 (`tools/sdk/ext`, made with
  `msiexec /a`, nothing installed system-wide). It patches upstream's
  `build_vp_clang_sdk.py` paths, writes `commit_id.inc` itself, and adds
  `/Zc:threadSafeInit- /Zc:sizedDealloc-` plus a `__std_terminate` shim because
  LLVM 23 emits runtime symbols the VC9 CRT lacks.

## Database-level findings (simulator, CP 5.4.6 + WFTW v27)

| Finding | Status |
|---|---|
| `SQL/Shared/MadokaTableUpdates.sql` re-added `UnitPromotions.ShowInUnitPanel`, which CP now ships. Duplicate column → sqlite3_exec aborted the file at statement 39/87, so 48 Magical-Girl columns on Traits/Policies/Buildings/Missions/Civilizations/Beliefs/Specialists were never created and ~15 later files failed on them. Almost certainly the reported "crash when a Magical Girl spawns". | **Fixed** (line removed) |
| `XML/CIV5Options-MadokaDVMC.xml` flips 16 `CustomModOptions`. 14 still exist (all default 0, so flipping is required). `GLOBAL_PROMOTION_CLASSES` and `GLOBAL_SEPARATE_GREAT_ADMIRAL` rows no longer exist; the updates are silent no-ops. Promotion classes are always on in CP (`Units.PromotionClass` exists and WFTW sets it on `UNIT_PMMM_MAGICAL_GIRL`). CP's `CvPlayer` keeps separate `GreatGeneralsCreated`/`GreatAdmiralsCreated` counters and threshold modifiers, so the separate-admiral behaviour is built in. | No-op, verified |
| `DecisionsMod/SQL/*DecisionData.sql` insert into `DecisionsAddin_Support` first; without Events & Decisions the file aborts, by design. | Leave |
| `XML/CBPReligiousWonder.xml` (`MinorityHappinessChange`) and `ModCompatibility/Community Balance Patch/PMMMCBP.sql` (`IlliteracyHappinessChange`) use 2015 CBP columns that no longer exist in CP or VP (VP now has `*FlatReduction` columns). Silent failures in CP-only; need a VP companion mod in Phase 3. | Phase 3 |
| `ModCompatibility/Superpower Modpack/PMMMSuperpower.sql` re-inserts Charisma promotions unconditionally; fails on UNIQUE and aborts when Superpower is absent (harmless). | Cosmetic |
| CP's own modinfo lists `CoreGameOptionTextChanges.xml` which does not exist in the repo (only the `.sql`). Harmless upstream quirk. | Upstream |

All 25 `GameEvents` WFTW hooks exist in CP 5.4.6 with VMC-compatible
signatures (`CustomMission*`, `UnitCreated`, `UnitPrekill`, `GetDiploModifier`,
`TeamSetEra`, `CanDoCommand`, ...).

## Lua API findings

| Call | CP 5.4.6 | Change |
|---|---|---|
| `pPlayer:SetNumAnarchyTurns(n)` | removed | → `SetAnarchyNumTurns(n)` (**done**) |
| `pPlayer:IsPlayerNoSettleRequestEverAsked(p)` | removed with the request flags | approximated with expansion-promise state (**done**); exact semantics would need a DLL Lua hook |
| `pPlayer:IsPlayerStopSpyingRequestEverAsked(p)` | removed | approximated with spy-promise state (**done**) |
| `PreGame:GetGameSpeed()` | engine object, fine | — |
| Everything else (`SetBaseCombatStrength`, `GetMilitaryMight`, `SetName`, `PushMission`, ...) | present | — |

## Lua reference check (`scripts/luarefs.py` against the simulated DB)

- `PMMMKyoukoTrait.lua` used `GameInfoTypes.UNITCLASS_MAGICAL_GIRL` (does not
  exist; the class is `UNITCLASS_PMMM_MAGICAL_GIRL`), so the "not a Magical
  Girl" exclusion in Kyouko's bonus never applied. **Fixed.**
- Benign leftovers: unused locals `BUILDING_PMMM_TEAHOUSE_*_DUMMY`,
  `BUILDING_PMMM_DEMON_HOMURA_DUMMY` (only the `_1.._N` variants exist),
  `UNITCLASS_PMMM_SEA_WITCH` (sea witches share `UNITCLASS_PMMM_WITCH`),
  `PROMOTION_PMMM_TIRO_MUSKETEER_READY` (never used); Time Stop remnants in
  `PMMMGeneralFunctions.lua` and `UnitPanel.lua`; optional external-mod types
  (`CIVILIZATION_BRITAIN_FSN`, `UNIT_RECLUSE_VILLAIN`, JFD CulDiv) and engine
  enums (`NOTIFICATION_*`, `UNITAI_*`, defines) that are not DB rows.
- WFTW formats thousands of XML values as `<Type>\n\tX\n</Type>`; the game's
  loader trims them (the mod's art defines and icons work), so `civdb.py`
  trims too. Do not "clean" the XML for this.

## Custom DLL build (stock CP 5.4.6 source)

| Config | Result | Time | Size |
|---|---|---|---|
| Debug | links, 29 warnings | ~22 s | 28.5 MB (+117 MB pdb) |
| Release (LTO) | links, 29 warnings | ~170 s | 17.03 MB (official 5.4.6: 17.01 MB) |

Outputs: `upstream/Community-Patch-DLL/clang-output/{Debug,Release}/`. Our
fork for WFTW-specific hooks (e.g. an `IsPlayerNoSettleRequestEverAsked`
Lua exposure) can start from this.

## UI overrides

WFTW replaces `UnitPanel.lua/.xml`, `EnemyUnitPanel.lua/.xml`,
`BarbarianCampPopup.lua`, `CivilopediaScreen.lua`, `SetUnitName.lua` with
2015 vanilla-based copies. CP also overrides `UnitPanel.lua` (vanilla+383
changed lines) and `EnemyUnitPanel.lua` (near-rewrite). With both active the
later-loaded mod wins, so WFTW's copies mask CP's. WFTW's deltas are 764 and
536 changed lines respectively; rebasing them onto CP's files is Phase 3 work.
Fine for a first CP-only runtime test.

## Multiplayer hazards spotted in WFTW Lua (for Phase 6 and MP in general)

`Game.GetActivePlayer` ×17, `os.clock` ×4 inside gameplay Lua; `Game.Rand`
is used correctly (×49, no `math.random`). Any gameplay path keyed on the
active player will desync simultaneous-turn games.

## Runtime test setup (done)

- `MODS\(1) Community Patch (v 151)` copied from the repo (ships the 5.4.6 DLL).
- `MODS\Madoka Magica -- Wish for the World [BNW] (v 27)` is a junction to
  `wftw/` in this repo, so edits are live.
- `config.ini`: `LoggingEnabled = 1`, `MessageLog = 1` (backup:
  `config.ini.bak-madoka-20260916`). Game is already windowed.
- Computer-use access to the game was declined, so the first in-game run is
  manual. Custom DLL builds land in
  `upstream/Community-Patch-DLL/clang-output/{Debug,Release}/`; copy the
  `.dll` (and `.pdb` for debugging) over `MODS\(1) Community Patch (v 151)\CvGameCore_Expansion2.dll`
  to test a custom build.

### Manual first run

1. Launch Civ V → Mods → accept → tick **(1) Community Patch** and
   **Madoka Magica -- Wish for the World [BNW]** only (leave the Rebellion and
   BalanceGoldPrime packs off; WFTW blocks Rebellion anyway) → Next.
2. Single Player → Set Up Game → pick Madoka Kaname (or any WFTW civ), small
   map, then start. Each WFTW civ spawns a Leader Magical Girl at turn 1, which
   is the path the old crash reports point at.
3. Play ~10 turns, expend a Great Person if one appears (spawns a second MG).
4. Collect `My Games\Sid Meier's Civilization 5\Logs\Database.log`, `Lua.log`,
   `xml.log`, and any `*.dmp` from the game folder if it crashed. Grep
   `Database.log` for `MadokaTableUpdates` / `duplicate column` to confirm the
   schema fix landed, and `Lua.log` for `PMMM` errors.
