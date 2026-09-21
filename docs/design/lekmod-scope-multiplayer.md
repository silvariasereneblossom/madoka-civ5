# Lekmod Phase 6 scoping, investigation 3: multiplayer and packaging

Research report produced 2026-09-18 for the Lekmod scoping pass (brief: `lekmod-scoping-plan.md`, investigation 3).
Sources: `upstream/Lekmod/` (git clone at `v35.3`, commit `70aa6ad`, 2026-09-05), the shipped install parked at
`build/parked-dlc/LEKMOD_v34.15/` (real player-facing data, built 2026-04-19), `wftw/` at its current Phase 4 state,
`docs/HANDOVER.md` sections 1/3/6/9, `docs/agent-contract.md`, `docs/review-2026-09-16.md` section B, and
`PLAN.md` Phase 6. GitHub API facts via `gh api repos/EnormousApplePie/Lekmod`. PLAN.md Phase 6's packaging sketch
(overlay script, `.Civ5Pkg`, `LoadNewContext`, drafter registration) was treated as a hypothesis; it is confirmed in
every point by how Lekmod actually ships, with one significant correction (A4: two packages cannot stack two DLLs).

## 0. Headline answers

1. **Packaging**: Lekmod works in multiplayer by being a fake official DLC package. A `.Civ5Pkg` declares a
   mounted `Art/` and `Lua/` directory tree, an `Override/` folder *replaces the entire game database* with two
   megafiles, a replacement `CvGameCore_Expansion2.dll` at the package root swaps the engine, and a patched
   `InGame.lua` loads every civ's Lua via `LoadNewContext`. Every WFTW content kind has a mapping onto this
   pattern except the `.modinfo` machinery itself (entry points, ordered `UpdateDatabase` list, `Reload*` flags,
   SQL execution), which must be replaced by a build step; and the DLL, which cannot be layered and forces a
   fork-or-upstream decision on its own.
2. **Multiplayer safety**: the mod's dummy-mission sync pattern is genuinely multiplayer-correct (verified, B0),
   and the 2026-09-16 review's fix pass already cleared most desync sources. What remains open: the mood system
   mutating combat-relevant state from client-local `Events.*` handlers (review B1), the appearance-update
   mission with no gameplay-side handler (review B4), and three `pairs()`-into-`Game.Rand` sites found by this
   pass. The TSL save system is per-client by construction and is survivable only under a strict
   "resume MP games from saves" rule plus removal of the divergent writers. Estimated effort to close: ~4-6
   working days (B3), needed regardless of which DLL is chosen.
3. **Fork vs upstream**: Lekmod's license forbids redistribution of anything containing the maintainer's
   contributions without prior written permission, and even with permission demands material alteration and a
   different name. Upstreaming is viable in principle (30 PRs to date, regular external merges, monthly
   releases, 96 commits in 2026 YTD) but the *engine hooks* are the only realistic upstream target; the anime
   content itself would live in our own additive package. Either way the DLL ships to every lobby member, and
   either way the pack is version-pinned: the lobby cannot tell a 34.15 player from a 35.3 player, because the
   package identity file is byte-identical across releases (A6).

---

## A. Packaging

### A1. What ships: the folder and the package file

A Lekmod install is one folder inside the game's `Assets/DLC/`, created by the installer as
`LEKMOD_{version}` (our parked copy is `build/parked-dlc/LEKMOD_v34.15/`). Contents:

```
LEKMOD_v34.15/
  MPModsPack.Civ5Pkg      package descriptor (the game finds .Civ5Pkg anywhere under Assets — lekmod.ps1 comment)
  CvGameCore_Expansion2.dll  replacement game engine (v35 repo copy also ships the .pdb)
  zlib1.dll               the engine DLL's dependency
  Art/                    all textures/models (mounted, see below)
  Fonts/                  ggxml font-icon patches (EmoteIcons_Patch.ggxml, FontIcons_Patch.ggxml)
  Lua/                    all Lua (mounted)
    Civilizations/        one file per custom civ (26 files)
    Utilities/            Lekmod_drafter.lua, Lekmod_version.lua, Lekmod_utilities.lua, ...
    UI/                   vanilla-UI *replacements* (48 files in the installed copy; 10 in the repo)
    tmp/                  {ui, eui, shared}/ source variants of the UI replacements
  Override/               database XML, 529 files (see A2)
  ui_check.bat            picks standard-UI vs EUI variants into Lua/UI (v33+)
  VERSION                 "v35.3000" (repo copy only; the 34.15 install has no VERSION file)
```

`MPModsPack.Civ5Pkg` in full (identical bytes in v34.15 and v35.3000):

```xml
<Civ5Package>
  <GUID>{4249caef-aeb8-45cc-9ccd-ffd722c79097}</GUID>   <!-- the classic MP Mods Pack GUID (Gedemon/MPMPM) -->
  <SteamApp>235580</SteamApp>
  <Version>326</Version>
  <Priority>300</Priority>
  <Key>bf6d34a0074b7ad4b1d1716475f7f7fe</Key>
  <PTags><Tag>Version</Tag></PTags>
  <Name><Value language="en_US">MP ModsPack</Value></Name>
  <Gameplay></Gameplay>
  <UISkin name="Expansion2Primary" set="Expansion2" platform="Common">
    <GameplaySkin>
      <Directory>Art</Directory>
      <Directory>Lua</Directory>
    </GameplaySkin>
  </UISkin>
</Civ5Package>
```

The `GameplaySkin` directories are the mount: everything under `Art/` and `Lua/` enters the game's virtual file
system with package priority 300 (above all official DLC), so a file named `UI/InGame.lua` under `Lua/`
outshadows the vanilla `Assets/UI/InGame.lua`, and art/model files are found by the engine without any manifest.
Civ V multiplayer ignores normal mods entirely (HANDOVER section 9); it does not ignore DLC packages, which is the
entire trick: the pack is indistinguishable from official DLC to the lobby.

### A2. Override = whole-database replacement

`Override/` is not "a few patched files" — it is a full replacement of the game's XML database:

- **529 files** in `upstream/Lekmod/LEKMOD/Override/`; **520 of them are zero bytes**. Every zero-byte file
  matches a vanilla `Assets/XML/...` file name and blanks it out during the database build.
- Two files carry the entire replacement database, both headed
  `<!-- generated by MP Modpacks Maker (Gedemon) -->`:
  - `Override/CIV5Units.xml` — **9.77 MB** in v35.3 (11.79 MB in the installed 34.15). Despite the name it holds
    everything: `<Table name="...">` schema blocks (`db_commit_diff.txt` shows the pattern — new table, then
    element rows with a `<Delete/>` idempotency guard), and row data for `Civilizations` (117 rows: 43 vanilla +
    ~74 new), `Leaders` (116), `Traits` (115), `Units` (231), `Buildings` (258), `Technologies` (82), `Policies`
    (122), plus 447 distinct element types and 15,560 `TXT_KEY` references.
  - `Override/CIV5Units_Mongol.xml` — **6.52 MB**, the text database: `<Language_en_US>` etc. for six locales,
    30,386 `TXT_KEY` references, opening with `TXT_KEY_LEKMOD_VERSION` = "LEKMOD v35.3000".
- The other seven non-empty files are small surgical overrides: `Audio2DScriptsExpansion1/2.xml`,
  `AudioDefinesExpansion1.xml` (new sounds), `CityStateDiploPopup.xml` (UI), `MinorCivSounds_Expansion2.xml`,
  `Civ5_Dialog_Adolphus.xml`, and in v35 `Lekmod_MenuLinkIcons.xml`.
- **No SQL is executed** — DLC packages never run `.sql`. The stray `.sql` files inside
  `Art/Champa (Brave New World) (v 43)/SQL/...`, `Art/JFD's The Kingdom of Prussia (v 17)/...` etc. are dead
  vestiges of the third-party mods Lekmod absorbed wholesale; their content was hand-converted into the
  megafiles (header comment: *"manually converted from SQL files... copy-paste just saves a lot of time"*).

Consequences for us: (a) additive packages *can* add new XML files — every XML in every enabled package loads
into the same database — so a WFTW package can append rows without touching Lekmod's megafile; (b) anything that
must *change* an existing Lekmod row (e.g. rebalanced vanilla units WFTW copies, trait columns) needs an
`<Update>`/`<Replace>` against Lekmod's values, version-pinned per release; (c) all 80 of WFTW's `.sql` files
plus 15 XML files must be converted to element-form XML in modinfo order (A7).

### A3. How Lua and UI get picked up

- The `Lua/` mount makes file *name* lookup shadow vanilla. `Lua/UI/InGame.lua` (copied there by `ui_check.bat`
  from `Lua/tmp/ui/InGame.lua.ignore`, or the `tmp/eui` twin for EUI 1.28 or lower) replaces the vanilla
  `InGame.lua`, and it ends with the addin pattern PLAN.md hypothesised — confirmed at
  `Lua/tmp/ui/InGame.lua.ignore:1281-1330`: `ContextPtr:LoadNewContext("Lekmod_global_dummies")`,
  `("Lekmod_utilities")`, then one line per civ (`("Lekmod_tonga")` ... 26 civ files), then the drafter and UI
  helpers. The same trick loads the front-end (`Lua/UI/StagingRoom.lua`, `MPGameOptions.lua`, `MainMenu.lua`,
  `JoiningRoom.lua` patch the multiplayer lobby itself).
- `ui_check.bat` exists because EUI is *also* a DLC-folder mod that replaces some of the same files: the script
  deletes `Lua/UI`, picks the EUI or standard variant of each replacement (probing the installed EUI's actual
  file contents, e.g. `CityBannerManager` function sniffing), and preserves Lekmod-only helpers
  (`CityStatePersonalityHelper.lua`, `LegalScreen.*`). The installer replicates this in Python
  (`LekmodInstaller/ui_manager.py:configure_ui_files`).
- Gameplay-per-civ Lua is ordinary `GameEvents` registration at file load (`Lekmod_aksum.lua:53-58`), plus DLL
  hooks Lekmod added itself (`-- Note: UnitHealed is a Lekmod Event! Not available in the base game`,
  `Lekmod_aksum.lua:57`). That is the same engine-dependency problem WFTW has with the CP DLL, one layer down.

### A4. The DLL swap — and the correction to PLAN.md

`CvGameCore_Expansion2.dll` sits at the package root (with `zlib1.dll`), exactly as the official Expansion2
package ships its engine. The game loads **one** game DLL: the highest-priority enabled package providing one
wins. This is why Lekmod and Community Patch cannot coexist (HANDOVER section 6), and it corrects the Phase 6
sketch: **you cannot ship WFTW as a second package that layers a DLL on top of an installed Lekmod and expect
both engines' changes to apply.** Only one package's DLL runs. So the engine features WFTW needs (custom unit
missions, the CP hooks, Ai Yo, the city cap — HANDOVER section 9's table) must arrive inside whatever DLL the
lobby actually loads. There are exactly two shapes:

1. a **forked Lekmod package**: Lekmod's DLL source + our hooks, shipped as (part of) a renamed package that
   *replaces* Lekmod for the lobby (route i, C3), or
2. the **official Lekmod DLL** carrying our hooks because they were upstreamed (route ii, C4), with WFTW as a
   data/Lua/art package on top that ships no DLL.

A third hybrid — our package ships a DLL built from Lekmod's source while everyone also installs vanilla
Lekmod — works mechanically (priority decides, ours wins) but still ships a derivative of Lekmod's code, so it
buys nothing over route (i) legally (C1) and doubles the install.

### A5. One civ end to end (Aksum) — the pattern to copy

| Piece | Where (v35.3 tree) | Notes |
|---|---|---|
| Civilization row | `Override/CIV5Units.xml:76688-76705` | `CIVILIZATION_AKSUM`, ID 92, icon atlases, `ArtDefineTag ART_DEF_CIVILIZATION_ZULU` (reused), `SoundtrackTag Arabia` (reused), generic `DoM`/map images |
| Leader row | `Override/CIV5Units.xml:170903-170921` | `LEADER_AKSUM` (Kaleb), full AI flavors; **no leader-scene art define — new Lekmod leaders reuse vanilla scenes, no .gr2 leaderscreen** |
| Leader-civ link | `Override/CIV5Units.xml:68181-68184` | `Civilization_Leaderheads` row |
| Trait | `Override/CIV5Units.xml:207294-207300` | `TRAIT_AKSUM` with `ForeignRelgionPressureModifier -100` and an in-file comment `<!-- Has code in Lua\Civilizations\Lekmod_aksum.lua-->` — the data↔code contract is documented in the megafile itself |
| City names, improvement, units, flavors, dialog responses | `Override/CIV5Units.xml:63359+`, `48625-48645`, `45090`, `156517+`, `103413-103420` | all inline in the same megafile |
| Icon atlas declaration | `Override/CIV5Units.xml:131736` (`IconTextureAtlases` row) | points at the DDS files below |
| Icon DDS files | `Art/Lekmod (v 1)/Art/Civilizations/Aksum/atlas_aksum_{32..256}.dds`, `alpha_atlas_aksum_{16..128}.dds` | one folder per civ, all sizes |
| Building/units 3D | `Art/Lekmod (v 1)/New Civs/Aksum/Graphics/Monolithic Church/*.gr2, *.fxsxml, *.dds` | fxsxml + gr2 + textures |
| Lua | `Lua/Civilizations/Lekmod_aksum.lua` (58 lines) | `GameEvents.ReligionFounded` (UA), `GameEvents.UnitHealed` (UI bonus; DLL-added event), gated on `Lekmod_utilities:is_civilization_active` |
| Text | `Override/CIV5Units_Mongol.xml` (`TXT_KEY_AKSUM_*`, leader dialog) | all languages in the text megafile |
| Drafter entry | `Lua/Utilities/Lekmod_drafter.lua:11` | `Aksum = { tags = { "modded", "seasonal" }, displayName = "Aksum" }` in `CivMeta` |

WFTW differs from this pattern mainly in having *more* art per civ (ten static leaderscenes, `Art/*Scene.xml`
mount files, 29 unit `.gr2`) and *less* per-civ Lua (one shared framework). Both differences are additive; the
pattern carries.

### A6. Lobby matching and version pinning

- **What the lobby checks**: package presence and identity. All players must have the same packages enabled;
   the `.Civ5Pkg` GUID/Version/Key are what the game sees.
- **Identity is constant across releases**: the parked v34.15 `MPModsPack.Civ5Pkg` and the v35.3000 one are
  byte-identical (same GUID `{4249caef-...}`, `Version 326`, `Key bf6d34a0...`). **The lobby cannot tell a
  34.15 player from a 35.3 player.**
- Lekmod knows this and works around it in Lua: the staging-room text is *replaced* so the lobby visibly says
  "LEKMOD v35.3" (`CIV5Units_Mongol.xml`: `<Replace Tag="TXT_KEY_MULTIPLAYER_STAGING_ROOM">` →
  `[COLOR_POSITIVE_TEXT]LEKMOD v35.3[ENDCOLOR]`), and `Lua/Utilities/Lekmod_version.lua:7-21` implements a
  lobby **version handshake over game chat** (`OLD_HANDSHAKE_PREFIX = "#LEKVER#"`, draft notices `#LDRAFT#`,
  plus an `IsUiCheckConfigured` stamp so clients that skipped `ui_check.bat` announce it).
- Implications for us: (a) the WFTW pack must pin to the exact Lekmod release the group plays — currently
  **34.15 (2026-04-19) locally vs v35.3 (2026-09-05) upstream**, i.e. the group is one major version behind an
  actively developed mod; (b) our pack must participate in (or at least not break) that handshake, because a
  WFTW-Lekmod mismatch is exactly the silent failure mode the handshake exists for; (c) whenever Lekmod
  rebalances rows our data references, the pack needs a rebuild against the new megafile — a standing tax
  proportional to Lekmod's release cadence (C2).

### A7. WFTW content mapped by file kind

Inventory of `wftw/` (from the `.modinfo` and directory listings): 79 Lua files, 80 SQL, 15 XML data files
(plus the text files), 320 DDS (`Art/` + `UnitArt/`), 29 `.gr2`, 10 `.fxsxml`, 10 `.ggxml`, 10 leader-scene
XMLs, 1 MP3, a 153-entry ordered `UpdateDatabase` list, 6 entry points, and the companion soundtrack pack
(141 MP3s, 322 MB, `SoundtrackTag` updates, `Audio_2DSounds` rows).

| WFTW kind | Volume | DLC-folder mapping | Verdict |
|---|---|---|---|
| SQL data (`SQL/**`, `WishForTheWorldOptions.sql`) | 80 files, load order fixed by the modinfo's 153-entry `UpdateDatabase` list (Shared → per-civ → Phase4/Abilities last) | **Convert to element-form XML.** Apply the SQL in modinfo order to a scratch DB seeded from the target Lekmod megafile, export rows (and the schema blocks for `Traits.PMMM*` etc.) as one `Override/CIV5WFTW.xml`. PLAN.md's "apply to a scratch DB and export" hypothesis is exactly what MPMPM/Lekmod did (`civdb.py` can seed from the Lekmod folder). | Carries, via build step; **no DLC equivalent for SQL execution or load order** — the order must be baked into the generated file |
| XML data (`XML/`, `WFTWGameDefines.xml`) | 15 files | append/merge into the same generated file; `DELETE`-then-INSERT idempotency in SQL becomes `<Delete/>` guards (Lekmod's own pattern, `db_commit_diff.txt`) | Carries |
| Text (`XML/Text/**`) | ~20 files | into our package's own `Language_en_US` XML (additive; does not need Lekmod's text megafile) | Carries |
| Gameplay Lua | 39 files, all `include`d from `PMMMWishForTheWorldMain.lua` | one folder in our package's `Lua/` + a `LoadNewContext` line in a patched `InGame.lua` (A3 pattern). The main file's `OnModLoaded`/TSL bootstrap works unchanged | Carries |
| UI addins (5 `InGameUIAddin` + 1 `CityViewUIAddin`) | MagicalGirlInfoPanel, PleiadesFreezer, 3 TopPanel displays, CityInfoStack | also `LoadNewContext` (each is an xml+lua pair); CityInfoStack's `CityViewUIAddin` has no DLC entry-point equivalent and must be loaded from the patched `InGame.lua` like the rest | Carries, entry points go away |
| UI Replacements (`UI Replacements/`) | UnitPanel, EnemyUnitPanel (+`_small`), BarbarianCampPopup, CivilopediaScreen, SetUnitName | **conflict**: Lekmod already replaces UnitPanel (two variants: `tmp/ui`, `tmp/eui`). Ours must be rebased onto Lekmod's versions, and shipped as the *same file names* in the higher-priority package, or merged into a combined file per UI flavour. Version-pinned per Lekmod release | Carries with rebase work — the single biggest non-DLL port task after the data layer |
| Art | 320 DDS, 29 gr2, 10 fxsxml, 10 ggxml, 10 scene XMLs, `CivIconAtlases/` | copy into our package's `Art/` (mounted, priority > Lekmod's), atlas rows into our XML | Carries verbatim |
| Audio | `Sound/HomuraTimeStop.mp3`, `XML/CIV5Audio-Madoka.xml`, audio SQL | MP3 into `Art/`, script/define rows into our XML (Lekmod's own `AudioDefinesExpansion1.xml` shows the shape) | Carries |
| Soundtrack pack | 141 MP3s, 322 MB, `SoundtrackTag="MADOKA"` updates, `Audio_2DSounds` | same mechanism, but ship as a *separate optional package* (Lekmod's whole pack is 106.7 MB; the music would quadruple it, and `SoundtrackTag` rows are additive) | Carries, optional second package |
| `DecisionsMod/`, `EventsMod/`, `ModCompatibility/` | 11 SQL + Lua for Events & Decisions, CBP/CBP-Superpower/CulDiv shims | **drop.** DLC multiplayer has no other mods; these layers are dead weight in the pack (they are already inert today, HANDOVER section 8) | Does not carry |
| `.modinfo` entry points, `ReloadAudioSystem`/`ReloadLandmarkSystem`/`ReloadStrategicViewSystem`/`ReloadUnitSystem` flags, md5 manifest | — | no equivalent and none needed: DLC content loads unconditionally with the package; the reload flags exist only to make *mod* loading work | Replaced by the `.Civ5Pkg` + patched context files |
| Our DLL additions (custom missions, Ai Yo, city cap, CP hooks) | `dll/pmmm-phase4.patch` | **cannot be layered** (A4). Fork or upstream | The Phase 6 gate |

### A8. Can `LekmodInstaller` be reused?

Mechanically yes, with modification. What it does: Tk GUI → version list from
`LekmodInstaller/github_setup/versions.json` (GitHub-hosted, Google Drive `file_id` per version) → download →
extract → `ui_manager.configure_ui_files` (Python re-implementation of `ui_check.bat`) → install into
`Assets/DLC/LEKMOD_{version}` → detect/remove old installs. The generic 80% (find the Civ V path
`ui_manager.py:19`, extract, install, version detection, PyInstaller packaging via `LekmodInstaller.spec` and
`build.bat`) is reusable as a skeleton for a WFTW-pack installer. The Lekmod-specific 20% (folder-name sniffing
`_find_lekmod_folder`, Google Drive as the download host, the EUI-probing file checks, Lekmap handling) needs
repointing. Alternatively skip the installer entirely: our pack is one zip dropped next to Lekmod's folder, and
Lekmod's own installer already handles the UI check for the shared files — but our patched `InGame.lua` and
UnitPanel replacements must install into *Lekmod's* package folder (or override it by priority), which argues
for a small installer of our own so the two-step install is one step.

---

## B. Multiplayer safety audit

### B0. The sync model, and the dummy-mission pattern (verified working)

Facts the audit rests on (agent-contract): Civ V runs one Lua VM per client; `GameEvents` fire on every client
in lockstep during turn processing; `Events.*` and `LuaEvents.*` fire client-locally; `Game.Rand` is the
synchronised RNG. `math.random` appears nowhere in the mod (0 hits; 54 `Game.Rand` calls, all with reason
strings — the review counted 49 before Phase 4).

**Does an ability use on one client reach the others?** Yes, by design, and not by a dummy-unit trick: the UI
never applies gameplay effects itself. It pushes a *custom mission* through the engine's network path —
`Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION, missionID, -iX, -iY, ...)` in the
map-click handler (`wftw/Lua/PMMMWishForTheWorldMain.lua:103-118`, net send at :112), in the Magical Girl panel
(`Lua/UI/MagicalGirlInfoPanel.lua:304` and 11 siblings, `MISSION_PMMM_APPEARANCE_UPDATE`), and in the Freezer
panel (`Lua/UI/PleiadesFreezer.lua:153`). The engine replicates the mission; the DLL raises
`GameEvents.CustomMissionStart` on every client, where the gameplay handlers registered in
`PMMMWishForTheWorldMain.lua:262-288` apply the effect. The original author documented the intent:
`MagicalGirlMissionHandler.lua:402` — *"v21: Grief Seeds now handled through a Custom Mission (multiplayer
compatibility)"*. Targeted abilities use the same channel: the local highlight/targeting state
(`tMissionInfo`) is display-only, and the click converts to a mission push. So the framework's sync pattern is
correct **in shape**; determinism then depends on the handlers themselves, which is where the hazards below
live. (Caveat: none of this has been exercised in a real two-client session yet — HANDOVER section 8.)

### B1. TableSaverLoader persistence: how it behaves in MP

- **Where state lives**: `MapModData.PMMM` (alias `PMMM`) and `MagicalGirls`, declared in `PMMMDefines.lua`,
  populated at load (`PMMMWishForTheWorldMain.lua:6-10`, `OnModLoaded` :74-89). Shared with the UI addin
  contexts on the *same client* via the engine-backed `MapModData` (the UI panels read the very same tables,
  `MagicalGirlInfoPanel.lua:71`), and with nobody else.
- **How it saves**: `TableSaverLoader016.lua` serialises the table tree into the save file's SQLite
  (`Civ5SavedGameDatabase.db` — header comment :17-18, `DBChange` :427-433). Triggers: explicit save/quick-save
  interception (`TSLSerializerV3PMMM.lua:189-204`), autosave interception on
  `Events.AIProcessingEndedForPlayer` when `iPlayer == 63` and the turn hits the autosave frequency
  (`TSLSerializerV3PMMM.lua:206-211`), and the load-time save for new games (main :87).
- **What that means in MP**: the tables exist independently in every client's VM. They stay identical only as
  long as every mutation happens inside synced `GameEvents`. Saves are per-client writes into that client's
  save DB; in practice only the host's saves circulate. Civ V has no hot-join: a dropped player returns by
  *loading a save*, which re-reads the same `Civ5SavedGameDatabase` on every client — so a save-load
  resynchronises Lua state, and a client that diverged is silently "healed" (or its divergence frozen into the
  save, if it was the host). **Late join without a save load does not exist in this engine; the real hazard is
  not the join, it is divergence during live play.**
- **Requirement**: (1) remove every non-synced writer (rest of this section); (2) adopt the operating rule that
  MP sessions resume only from saves (already de facto true); (3) optionally add a debug checksum of the PMMM
  tree computed in a `GameEvents` handler and compared via chat, to catch divergence early. Re-architecting
  state into engine-backed storage (the DLL's script data, or full recompute from unit promotions/plot state)
  is the thorough fix and is *not* needed for a first playable MP build — park it.

### B2. Hazard table (all `wftw/Lua/`, current file state)

| # | Hazard | Where | Severity | Status |
|---|---|---|---|---|
| H1 | **Mood state mutated from client-local Events.** `Events.UnitSelectionChanged` / `Events.SerialEventUnitInfoDirty` handlers call `RefreshMGMood(key, pPlayer, pUnit, true)` gated on `Game:GetActivePlayer()` and `UI.GetHeadSelectedUnit()`; `RefreshMGMood` writes `MagicalGirls[key].MoodMods` / `.MoodLevel` **and calls `pUnit:SetHasPromotion(...)`** — combat-relevant state, applied only on the owning client when it selects the unit | `Moods/PMMMCoreMoods.lua:117-140` (mutation inside `RefreshMGMood` at :100-114), registered `PMMMWishForTheWorldMain.lua:318,320` | **High — desync** | Open (review item B1). Already-fixed precedent to copy: the Shirome reveal was moved out of `Events.LoadScreenClose` into a per-player `PlayerDoTurn` (`PMMMTraitBootstrapper.lua:251-255` port comment) |
| H2 | **`pairs()` order feeding `Game.Rand` / outcomes.** (a) `DeckShuffle` builds its deck array via `pairs(tTable)` then indexes it with `Game.Rand` — same roll, different deck order per client ⇒ different pick. 12 call sites (likes/dislikes types and values, vacation destination, defection choice, promotion removal). (b) AI witch-hunt assignment rolls `Game.Rand` *inside* `pairs(MagicalGirls)` and assigns the roll sequence to whichever MG `pairs` visits first — order-swap ⇒ different MGs get different targets ⇒ different unit moves. (c) `RunLeaderAbilityAI` iterates `pairs(tPMMMLeaderAbilities)` and `break`s after the first ability that scores — which ability fires depends on iteration order | (a) `PMMMGeneralFunctions.lua:585-598` + `Moods/PMMMCoreLikesDislikes.lua:147,373,624,1091-1092,1126,1439`, `PMMMLeaveMapFunctions.lua:84,154-172`, `PMMMReturnMapFunctions.lua:191`; (b) `PMMMWitches.lua:653-663`; (c) `PMMMLeaderAbilities.lua:343-377` (break at :374) | **High — desync**, cheap to fix | Open, new in this pass (review B6 fixed the same class for `FindBestEnemySpawnPlot`) |
| H3 | **Appearance mission has no gameplay handler.** UI pushes `MISSION_PMMM_APPEARANCE_UPDATE` (12 sites) but no `CustomMissionStart` handler exists in the gameplay files (grep: zero hits outside `UI/`); the local `LuaEvents.PMMMRefreshAppearance` refresh only exists on the clicking client | `Lua/UI/MagicalGirlInfoPanel.lua:304+` | Medium — currently a benign no-op in network games (B3 fix made edits inert rather than desyncing), but the feature silently does nothing in MP and other clients' panels go stale | Open (review item B4) |
| H4 | **Dangling client-local entry points for gameplay.** `LuaEvents.PMMMUseGriefSeed.Add(UseGriefSeed)` would run the whole grief-seed effect (`DoConsumeGriefSeed`, `SetSoulGemState`, `ChangeMoves`) on one client only if any UI ever fired it — today none does; and the deprecated `ExecuteMapClickCustomMission` calls `DoTiroFinale(Game:GetActivePlayer(), ...)` directly from a map click | `PMMMWishForTheWorldMain.lua:326`; `MagicalGirlMissionHandler.lua:256-269` | Low today (dead code), **landmine** for any future UI work | Open, trivial deletion |
| H5 | **UI-context lazy writes into persisted state.** `MagicalGirls[g_MGKey].LDLoyaltyChange = 0` / `.Influence = {}` are initialised only when a client opens the panel, so the field exists on some clients and not others until a save bakes one client's shape | `Lua/UI/MagicalGirlInfoPanel.lua:192,202` | Low (display-only fields) | Open, trivial move to synced MG creation |
| H6 | **`Game.GetActivePlayer()` in gameplay files**: 37 uses outside `UI/`; audited individually — all surviving uses gate popups/alerts (`Events.GameplayAlertMessage`, `AddPopupTextEvent`) for the local player, which is correct per-client behaviour. The two real gameplay uses are in the dead path (H4) | e.g. `Abilities/PMMMAbilityDemonHomura.lua:63`, `PMMMWitches.lua:266-271` | None (after H4) | Closed by this audit; keep the contract rule |
| H7 | **TSL persistence is per-client** (B1) | `Utils/TableSaverLoader016.lua`, `Utils/TSLSerializerV3PMMM.lua` | Structural | Managed by rule (B1), re-architecture parked |
| — | Already fixed in the review's fix pass, verified present in the code: B3 (`bMulti` nil in UI contexts — now `local bMulti = Game.IsNetworkMultiPlayer()` at `MagicalGirlInfoPanel.lua:28`), B5 (Freezer throwaway unit — now pushes the mission on a real own unit, `PleiadesFreezer.lua:148-153`), B6, B7, B8, B9, B10-partial, B11 (per `review-2026-09-16.md` fix-pass note; spot-checked B3/B5 in the tree) | | | Closed |

Also recorded: `PushAIMissions` (`MagicalGirlMissionHandler.lua:316-373`) iterates `pairs(MagicalGirls)` but
assigns order-independent fixed targets — acceptable; `RefreshMGMood` iterates `pairs(t_MoodMods)` but each
mod's accumulator/value is independent per mod — acceptable; the accumulators only run from the synced
`bAccumulators` callers, not from the Events path (H1's calls pass `bGetText=true, bAccumulators=nil`).

### B3. Prioritised fix list (effort; independent of DLL choice)

| Pri | Fix | Effort | Notes |
|---|---|---|---|
| P0 | **H1**: split `RefreshMGMood` into a pure compute (returns level/mods, writes nothing) used by the Events handlers for display, and a committing path called only from synced events (upkeep `PlayerDoTurn`, `UnitSetXY`/combat hooks — the synced callers already exist at `PMMMMagicalGirls.lua:128,228,643`). Remove `SetHasPromotion` from the Events path | 1-1.5 d | The review's proposed direction (B1). The display path can recompute freely per client since it writes nothing |
| P0 | **H2**: make every `pairs()` that feeds `Game.Rand` or an ordered outcome deterministic: `DeckShuffle` builds its deck over `table.sort`ed keys; witch-hunt assignment iterates a sorted key list of `MagicalGirls`; `RunLeaderAbilityAI` iterates a registration-order array (change `tPMMMLeaderAbilities` to also append to an `ipairs` list) | 1 d | Mechanical, 16 call sites, no behaviour change in single player |
| P1 | **H3**: add a gameplay `CustomMissionStart` handler for `MISSION_PMMM_APPEARANCE_UPDATE` that writes `OverrideIcon` from `iData1/iData2`-encoded values on every client; drop the local `LuaEvents.PMMMRefreshAppearance` write | 0.5 d | Restores a player-facing feature in MP |
| P1 | **H4 + H5**: delete `LuaEvents.PMMMUseGriefSeed` registration and `ExecuteMapClickCustomMission`; move the two lazy field inits into synced MG creation | 0.5 d | Deletes landmines |
| P1 | **H7 policy**: write the "resume MP from saves only" rule into the MP test checklist; add a debug `Game.Rand`-free checksum broadcast (optional, 1-2 d) | 0.5 d | |
| P2 | Two-client hotseat/LAN smoke test of one full ability rotation, one Grief Seed, one Freezer revival, one witch hunt, simultaneous turns | 1-2 d | Everything above is unverified until this happens |
| P3 | Re-architect MG state into engine-backed/synced storage | weeks | Park; only if the checksum tooling shows residual divergence |

Total to a *testable* MP-safe state: **~4-6 working days** of Lua work, all of it needed on any DLL, because
every hazard above is about which code runs where, not about what the DLL provides.

---

## C. Fork versus upstream

### C1. Lekmod's license (verbatim quotes, `upstream/Lekmod/LICENSE`)

> "LEKMOD CONTRIBUTOR & MODIFICATION LICENSE — Copyright (c) 2026 EnormousApplePie. All Rights Reserved."
> "1. PERMITTED USE OF MY CONTRIBUTIONS — You may use, modify, and run the portions of this project that
> constitute my individual work and original contributions for personal, non-commercial purposes only.
> Additionally, you are permitted to integrate, reference, or use my specific contributions in third-party,
> non-commercial open-source projects."
> "2. MANDATORY REDISTRIBUTION & ALTERATION PERMISSION — You may not redistribute, re-upload, or host any
> files, code, or assets containing my individual contributions under any circumstances without prior, explicit
> written permission from me. If written permission is granted, the redistributed work must simultaneously meet
> the following conditions unless explicitly waived in writing: a) the original portions containing my
> contributions must undergo significant, material alterations and functional changes. b) the resulting work
> must be published under a completely different name."

Read together: *using and modifying* Lekmod privately (including in our repo, in an open-source project) is
permitted; *distributing anything containing EAP's contributions* — a rebuilt DLL from `LEKMOD_DLL`, a package
folder containing his megafiles, even a patched `InGame.lua` that is mostly his — needs prior written
permission, and even then must be materially altered and renamed. GitHub classifies the repo as license
"Other / NOASSERTION". WFTW itself carries no license file (Steam Workshop item 273118128; the revival already
operates on the assumption that private use and credit are fine) — the same question will apply to *our* pack
if it ever leaves the group, but it does not constrain a friends-lobby distribution of our own content.

### C2. Project health and contribution model

- **Very active**: 96 commits since 2026-01-01 (through 2026-09-05); releases v34.13→v34.15 within eight days
  (2026-04-11→04-19), then v35.0→v35.3 within three weeks (2026-08-17→09-05). Installed locally: **34.15,
  2026-04-19**; current: **v35.3000, 2026-09-05** — the group is one major version behind.
- **Contribution model is open and used**: readme: "We welcome contributions to LEKMOD! If you have
  improvements... please submit a pull request." 30 PRs to date; external contributors' PRs merged on the
  release branch (e.g. PR #95 "V35", Jacob-Lisner, merged 2026-08-31); 14 authors in `git shortlog` (EAP 279,
  ImmoSS 220, Vironsusi 139 commits). Open PR #97 (MacOS/crossplay) shows even platform support is in flight.
  Repo: created 2021-07-20, 53 stars, 19 forks, 6 open issues.
- **Distribution**: Google Drive zips (106.7 MB for v35.x) listed in
  `LekmodInstaller/github_setup/versions.json`, fetched by the installer; source (including the DLL) is public
  in the repo with `build_mod.bat`.
- **Versioning discipline**: no tags since v30.7 — releases are "version push" commits; the lobby-side
  `#LEKVER#` chat handshake (A6) is the only version agreement mechanism, which is why a WFTW pack must pin to
  the exact release and ideally mimic the handshake for its own version.

### C3. Route (i): private fork with WFTW ported in

What it is: take `LEKMOD/` wholesale, port our DLL hooks into `LEKMOD_DLL`, regenerate the data as additional
XML (or merged megafile), ship the whole thing as one renamed package.

- **Legally**: needs EAP's prior written permission (redistribution of his files), and even with it the work
  must be "significantly, materially altered" and renamed. A "Lekmod + Madoka" zip sent to five friends is
  distribution; the permission requirement applies. This is a hard gate, not a formality — the license says
  "under any circumstances".
- **Engineering**: we own the whole surface: every Lekmod release must be re-applied (DLL rebase + data
  regeneration + `InGame.lua`/UnitPanel patch refresh, since our files *are* his patched files). With ~monthly
  releases and hotfix clusters, that is a standing tax of days per release, or a freezing decision ("we play
  fork-34.15 forever") that cuts the group off from Lekmod's balance fixes — the thing they play Lekmod *for*.
- **Operationally**: simplest for the lobby — one package, one install, no layering; every member must replace
  their Lekmod with our fork (same-folder GUID collision with any vanilla Lekmod install must be handled by the
  installer, as Lekmod's own does, `installer.py:801-823`).

### C4. Route (ii): upstream the engine hooks, ship an additive pack

What it is: PR the *generic* pieces into Lekmod's DLL (custom-unit-mission Lua events, the CP hooks WFTW needs
— the port list from Investigation 1, stripped of anything Madoka-specific), and ship WFTW as its own
higher-priority package containing only our data/Lua/art/UI-rebases plus no DLL.

- **Legally**: the cleanest route. We distribute only our own files; Lekmod continues to distribute Lekmod. No
  permission needed for the pack (our content, our license terms); the upstreamed hooks are contributions *to*
  Lekmod under its own contribution model, which the readme explicitly invites.
- **Engineering**: upstreaming DLL hooks is real work with review latency and no guarantee of acceptance, and
  it only covers the generic layer. Anything Madoka-specific in the DLL (Ai Yo, the city cap) still cannot ship
  in an additive pack (A4) — those features either go dormant in MP or get upstreamed as data-driven options,
  which is a much bigger sell. The additive pack still inherits the per-release rebase tax for every file that
  must match Lekmod's (UnitPanel, InGame.lua, rebalanced-row `<Update>`s), just not the DLL rebase.
- **Politically**: Lekmod is a competitive-MP balance mod; 72 bundled civs show it absorbs third-party civs
  readily, but those arrived as whole-mod adoptions, and anime civs with a global barbarian/witch system are a
  different proposition. Realistic upstream asks, in decreasing order of plausibility: (1) generic DLL hooks
  (missions/events — genuinely useful to any modded-civ pack, and the DLL already has precedent like
  `GameEvents.UnitHealed`); (2) nothing else.

### C5. Recommendation inputs (packaging/maintenance angle; Investigations 1-2 supply the rest)

1. **The DLL decides the route.** A4 is the structural fact: whatever ships the hooks ships the engine. If the
   hook set (Investigation 1's port list) is small and generic, upstreaming is both license-clean and
   maintenance-light, and the WFTW pack is additive. If it is large or Madoka-specific, a fork is unavoidable —
   and then EAP's written permission is a *prerequisite*, not an afterthought; ask early, in the Lekmod Discord
   (`readme.md` links it), with a concrete description.
2. **Version-pinning is mandatory either way.** The lobby cannot catch a mismatch (A6); pin the pack to the
   exact Lekmod release the group plays, decide deliberately whether that is the installed 34.15 or an upgrade
   to current 35.x, and embed the pack's own version in the staging-room text or the `#LEKVER#` handshake
   pattern so a mismatched lobby member is visible.
3. **Budget the rebase, not just the port.** First build: data conversion (A2/A7), UI rebase (UnitPanel family
   ×2 UI flavours), `InGame.lua` patch, art copy, installer — call it the bulk of the packaging work. Every
   Lekmod release after that re-touches the data export and the UI files. A build script (the Phase 6 overlay
   script) is not optional polish; it is what makes the standing tax payable.
4. **Drop the dead layers** (DecisionsMod/EventsMod/ModCompatibility, A7) from the MP pack; they cannot
   function there and halve the data-conversion surface.
5. **The MP-safety fixes (B3) should land in the CP mod now**, regardless of Phase 6: every fix is a
   single-player-correct refactor, they are cheap (~4-6 days), and doing them before the port means the port
   diff is purely additive.

### C6. Does "redistribution" reach a compatibility pack? (refinement, 2026-09-19)

The license's operative clause (§2) restricts *"files, code, or assets **containing my individual
contributions**"* — the test is what is inside the files we ship, not whether our mod interoperates with
Lekmod. §1 additionally permits each user's personal local modification, and explicitly permits
"integrate, reference, or use" of his contributions in third-party non-commercial open-source projects.
Applied to the pack, component by component:

| Component | Ships his content? | Verdict |
|---|---|---|
| WFTW's own data (converted XML), Lua, art, text, soundtrack | No | **Clean.** Users install Lekmod separately from EAP's channels; our files never contain his work. |
| Data export that verbatim-copies his rebalanced rows (the §B/Inv2 collision rows, e.g. unit stats) | Yes, if copied | **Dirty if careless.** The export must emit *our* rows plus `<Update>`/`<Replace>` elements **referencing** his rows — never resolved copies of his values. A design constraint on the A7 export step. |
| Patched `InGame.lua` (his file + our `LoadNewContext` lines) | Yes — modified copy of his file | **Dirty as shipped file — and avoidable entirely.** Better than installer-patching: shadow a *vanilla* InGame sub-context file Lekmod does not replace (e.g. `ResourceIconManager.lua`, `GenericWorldAnchor.lua`, `PlotHelpManager.lua` — present as `<LuaContext>` children of the vanilla `InGame.xml` and absent from both Lekmod `tmp/ui` and `tmp/eui` replacement sets) and call `ContextPtr:LoadNewContext` for our contexts from there. Ships only vanilla-derived content (the same UI-Replacement practice WFTW and every Workshop mod already uses; EAP's license does not reach Firaxis files), and modifies **no Lekmod file, not even locally** — Lekmod's own `InGame.lua` keeps loading and loads his contexts; ours bootstraps alongside. The installer-patch of the user's local `InGame.lua` (§1 covers personal local modification) remains the fallback if the shadow trick fails a live test. |
| Our installer reusing `LekmodInstaller` code (~80%, A8) | Yes | **Dirty.** Write our own installer, or get permission for reuse. |
| Fork DLL (any hook not upstreamed) | Yes — his entire DLL | **Dirty.** Route (ii) upstream is the clean alternative. |
| Any "Lekmod + WFTW bundle" or hosting his megafile/Override anywhere | Yes | **Dirty under all circumstances.** Never do this. |

Consequences: with the installer-patch structure, **the EAP conversation for route (ii) is a courtesy and
collaboration proposal, not a hard prerequisite** — the hard gate survives only where his files would ship
(route (i), a shipped `InGame.lua`, installer reuse, or any bundling). Practical caveats: he could change the
license at any time (pin the license text alongside the pinned Lekmod version); and shipping *our* pack as a
modified derivative of Lekmod's package layout still wants a heads-up as community courtesy. The ask in C5.1
softens accordingly: lead with the upstreamable hook set, state the no-his-files packaging structure, and let
permission questions follow from his answer.

**Two residual touchpoints survive the zero-touch structure** (2026-09-19 refinement):

1. **The fork DLL** (any hook not upstreamed) still ships his entire DLL — route (ii) remains the only fully
   clean engine path. Fallback that avoids *shipping* it (2026-09-19): an installer plus an **xdelta-style
   binary patch** from the stock Lekmod DLL to our build, applied against the copy each user downloads
   themselves. We host only the delta (it encodes overwhelmingly our additions and the patch code); the
   modified DLL exists only on each user's machine, which §1 personal use covers. It is still grayer than
   route (ii): the delta is derived from his binary, §2's "under any circumstances" phrasing leaves room for
   him to object, so this is a *fallback that changes the ask from required to strongly advisable*, not a
   fully clean path. Costs: the full fork build is still maintained, the delta is re-cut per Lekmod release,
   and a patched package's lobby behaviour needs the live test (everyone in the lobby runs the same patch,
   so bytes agree). Runtime DLL injection is the same legal status with none of the stability — not
   considered.
2. **The UnitPanel family collision** (A7): WFTW's `UnitPanel` / `EnemyUnitPanel` (+`_small`) replacements
   collide with Lekmod's own (both UI flavours). A merged file would contain his contributions → permission
   needed for exactly those files. The clean alternative is a small redesign: re-express WFTW's UnitPanel-side
   changes **additively** (our own panel/overlay contexts, the bootstrap trick above) and stop replacing those
   two screens in the MP pack. The other WFTW UI Replacements (`BarbarianCampPopup`, `CivilopediaScreen`,
   `SetUnitName`) do **not** collide with Lekmod's set and ship as normal vanilla-file replacements.
3. The installer must still be **our own code** — reusing `LekmodInstaller`'s Python ships his contributions.

## Open questions / not verified here

- No live two-client MP test has been run; B0's "missions replicate and `CustomMissionStart` fires on all
  clients" is evidenced by the code's design, the v21 comment, and CP's implementation, but not observed.
- The C6 zero-touch bootstrap (shadowing an untouched vanilla InGame sub-context file, e.g.
  `ResourceIconManager.lua`, and calling `LoadNewContext` from it) is evidenced by the context layout in
  vanilla `InGame.xml` and by the absence of those files from both Lekmod replacement variants, but the
  engine behaviour — `LoadNewContext` callable from a sub-context, load-order independence of our contexts,
  EUI not replacing the chosen file — has not been observed in game. Fallback: installer-patch the local
  `InGame.lua`.
- The engine's exact DLC-matching rules in the lobby (GUID vs Version vs Key) are inferred from the
  `.Civ5Pkg` fields and Lekmod's own workaround, not from engine source; the load-order guarantee for
  additive XML across packages (priority) likewise.
- Whether `MapModData` is engine-backed across contexts is inferred from the working UI panels (B1); if it
  were per-context, H5's lazy writes would be harmless — the fix is the same either way.
- Whether EAP would grant redistribution permission, and on what terms — unknown until asked.
- Lekmap (map scripts, `upstream/Lekmod/Lekmap/`, parked at `build/parked-dlc/Maps/`) is out of this brief's
  scope but ships alongside the pack and pins the same way; a WFTW-Lekmod group that plays Lekmap needs its
  version pinned too (`ui_manager.install_lekmap` already handles it in the installer).