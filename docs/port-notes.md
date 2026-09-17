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

## 2026-09-16 evening: "game crashes on start" (not the mod)

Symptom: every launch (DX9 and DX11, via Steam or direct, with or without
Lekmod, before and after any mod/config change) exited 6-13 s after
`SetActiveDLCandMods`, i.e. when the main menu should appear. No minidump, no
Windows Error Reporting event. Last successful session was 2026-04-27.

Diagnosis: process exit code `0x8000DEAD` = `ExitProcess` from a stub in the
executable (`CivilizationV_DX11.exe` VA `0x495f10`) reached only indirectly,
preceded by a helper that talks to the Steam client over the DRM IPC channel
(`STEAM_DRM_IPC` file mapping, `STEAM_DIPC_CONSUME` / `SREAM_DIPC_PRODUCE`
events): the Steamworks CEG wrapper's fatal path. Under cdb the process
enumerated DxDiag, the driver store and network adapters right before
exiting (CEG hardware fingerprinting), and CEG defeats debugger breakpoints,
so no stack was recoverable.

Fix: `steam://validate/8930`. Steam reported *Files Corrupt*, re-downloaded
and committed both executables (18:40), and the next launch reached the
main menu. Restarting the Steam client alone did not help. Exploit
Protection mitigations were at defaults; the game's owner account matched
the logged-in account, so it was a stale per-machine CEG binding (new GPU
driver / Parsec virtual adapters since April), not a licence problem.

Side effects of the investigation, all reversible: `config.ini` gained
`SkipIntroVideo = 1` (left in place; remove the two lines under
`LoggingEnabled` to restore); the Steam client was restarted once at 18:36
(a running OOTP 27 session re-attached fine); Debugging Tools for Windows
were extracted to `tools/sdk/dbg` (not installed); `build/dbg/` holds the
cdb logs.

## In-game music stuck on the menu theme (2026-09-16)

Symptom: after loading a WFTW civ the main-menu theme keeps looping; civ peace/war music never starts.

How the engine picks civ music: `Civilizations.SoundtrackTag` names a family of 2D audio scripts
`SONG_<TAG>_PEACE_n` / `SONG_<TAG>_WAR_n` (vanilla: `SONG_JAPAN_PEACE_1` ... in `Assets/Sounds/XML`,
BNW civs in `DLC/Expansion2/Sounds/XML/<Civ>Audio2DScripts.xml`). Vanilla civs leave the column NULL and the
engine derives the tag from the civ type. If the family does not exist, the music system never leaves the menu track.

Cause in WFTW: every civ is inserted with `INSERT ... SELECT ... SoundtrackTag ... FROM Civilizations WHERE Type =
'CIVILIZATION_JAPAN'` (or ROME / GERMANY / ASSYRIA), which copies that NULL, so the engine looked for
`SONG_ORIGINAL_MADOKA_PEACE_1` and friends. Those scripts only exist when the companion mod
"Madoka Magica Soundtrack (No Stupid Subtitles Edition) (v 6)" (GUID d58f9739-b51a-401d-b2ff-c0c480840fce) is
enabled: it sets `SoundtrackTag = 'MADOKA'` for all ten civs (UPDATE plus an AFTER INSERT trigger, so load order
does not matter) and defines `SONG_MADOKA_PEACE_1..99` / `SONG_MADOKA_WAR_1..93` plus per-leader diplomacy music.
`Civ5ModsDatabase.db` showed the pack with Enabled = 0 during the test run, so nothing supplied the scripts.

Fix (committed): each `SQL/<Civ>/<Civ>Civilization.sql` now writes the base civ's tag literally
(`'JAPAN'`, `'ROME'` for Mami, `'GERMANY'` for Sayaka, `'ASSYRIA'` for Ultimate Madoka and Demon Homura), so WFTW has
working music on its own; the soundtrack pack still overrides it with `'MADOKA'`. Verified with the simulator
(`build/sim_cp_wftw.db` = base tags, `build/sim_cp_wftw_ost.db` with the pack as a third `--mod` = all `MADOKA`,
same 300 ok / 15 expected failures). The pack's SQL/XML load cleanly on CP + WFTW; its 141 MP3s are `import="1"`
and `LoadType Streamed`.

To hear the Madoka soundtrack: tick the soundtrack mod in the Mods menu together with (1) Community Patch and WFTW
(it only *References* WFTW, so it is not enabled automatically).

### Follow-up: soundtrack plays one song, then silence (2026-09-16, later)

With the pack enabled the first Madoka track played and nothing followed. All 192 `SONG_MADOKA_*` rows in
`MadokaSoundtrack.xml` lacked `IsMusic` (default 0); vanilla civ songs carry `bIsMusic=True` and the pack's own
`AS2D_LEADER_MUSIC_*` rows carry `IsMusic=1`. Only music-flagged scripts are managed by the music player, so the
opening song (which the engine triggers directly) played and the rotation never started. Fixed in the installed pack
and mirrored under `soundtrack/` (see its README). Pack data is otherwise consistent: 157 sound rows all resolve to
files on disk, no dangling script rows, PEACE 1..99 and WAR 1..93 without gaps (zero-padded numbers would also break
rotation, per CivFanatics), all MP3s `import="1"`, `LoadType Streamed`.

Open question: whether the engine mixes `Era_Soundtracks` tracks (vanilla ambient/era music) into a civ's rotation.
The CP DLL never reads `Era_Soundtracks` (the exe does), so if non-Madoka tracks show up for Madoka civs the only
levers are (a) the pack's `SisPuellaMagicaOmnis` option (all civs use MADOKA) or (b) a client-side Lua/DB.Query
rewrite of `Era_Soundtracks` when the local player's civ is MADOKA-tagged. Wait for the user's report first.

### EnemyUnitPanel under CP: capital-defense methods

`UI Replacements/EnemyUnitPanel.lua` called `Unit:CapitalDefenseModifier()` / `CapitalDefenseFalloff()`, which CP's
`CvLuaUnit` no longer binds (it exposes `GetCombatModifierFromCapitalDistance(plot)` instead). Every hover over an
enemy unit raised a Lua error and truncated the combat preview. The three blocks now use the CP call, matching CP's
own `Core Files/Overrides/EnemyUnitPanel.lua`. A scan of every unit method WFTW's Lua calls against CP's 538 bound
methods found no other gaps. The full Phase 3 rebase onto CP's panel is still pending.

### Despair test result

A Leader Magical Girl at 0% Soul Gem fires the "became a Witch" notification but no Witch unit appears: this is the
mod's v19 rule in `TurnIntoWitch` (leaders are killed and respawn after `LEADER_MG_RESPAWN_TURNS`, scaled by game
speed and `LeaderMGRespawnTimeModifier`). Only non-leader girls spawn a barbarian Witch. Not a bug; a Phase 4 design
question if the user wants leaders to witch out for real.
