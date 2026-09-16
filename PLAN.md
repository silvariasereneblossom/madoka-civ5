# Madoka Magica: Wish for the World — revival plan

Research date: 2026-09-16. Everything below was verified against the live Workshop pages, the GitHub repos, and this machine unless marked "assumed".

## 1. What the target actually is

| | Wish for the World (WFTW) | Rebellion civ pack |
|---|---|---|
| Workshop id | 273118128 (the URL you gave) | 207117800 |
| Mod GUID | `6938dbeb-84c4-4a08-8bc0-51fca6135175` | `0ba6de75-d016-4e5e-955b-d8e1e154b839` |
| Last update | 2015-07-07, v26, "no longer supported" | v12 (installed) |
| DLL requirement | **Hard-requires the Community Patch DLL** (2015 era) | None (vanilla Lua API only) |
| Scope | Large gameplay mod: Magical Girl unit class, Soul Gems, Mood/Loyalty, Witches replace barbarians, Incubators, Entertainers, 10 civs | 8 civs, SQL + small Lua traits, E&D / YnAEMP / CBP shims |
| On disk | **Not present anywhere** (no MODS copy, no workshop cache on C:/D:/E:/H:) | `MODS\Madoka Magica Civilization Pack -- Rebellion [BNW] (v 12)` |

Both are by Vicevirtuoso (Steam "Vie S"). The Rebellion pack is the "compatible, stable, fewer features" sibling; WFTW is the ambitious one that died with the 2015 Community Patch.

### WFTW mechanics (from change notes v22–v26 and the CivFanatics thread)
- Magical Girls (MGs) are created by expending Great People ("Prodigies"). No gold upkeep, auto-upgrade per era. Leader MG per civ.
- Soul Gem: minimum 1% corruption/turn, more when injured/regenerating; Grief Seeds restore ~40%. Reaching zero = witch-out.
- Mood scale −500…+500 with 11 bands (−100%…+100% combat strength). Sources: Socializing, Sparring (cooldowns, promotions Charisma/Combat Trainer/Battle Instructor), killing Witches, empire happiness, Likes/Dislikes (policy trees, luxuries, ideology), penalties Homesick, Lack of Socializing, Restlessness, Inadequacy, Incubator "Emotional Abuse".
- Loyalty → defection to other empires; AI gets loyalty bonus per difficulty (`AI_MG_LOYALTY_BONUS_PER_TURN` in `WFTWGameDefines.xml`).
- Witches + Familiars replace barbarians; Familiars become Witches after 25 turns (`FAMILIAR_CONVERSION_TO_WITCH_TURNS`); Witch Labyrinth notifications; Pleiades "Freezer" UI for captured MGs.
- Entertainer specialist + Entertainers' Union buildings; Auto-Socialize unit action.
- Homura's Time Stop was **removed in v26** as an unfixable CTD source. Leaders: Madoka, Homura, Sayaka, Mami, Kyouko, Shirome, Pleiades (Kazumi), plus three more (thread spoilers are images; confirm from the files).
- Persistence via Pazyryk's TableSaverLoader + DarkScythe's TSL Serializer v3.
- CP-only features it used: MGs/Witches/Incubators un-capturable, MGs counted in military might, Honor culture scales with witch strength.
- Later comments (2017–2019): "crashes as soon as it spawns a magical girl" on newer CP; "CP v1‑23 still works"; VMC works ~50–60%.

### Rebellion pack facts (installed copy, inspected)
- Civs: Madoka Kaname (`ORIGINAL_MADOKA`), Ultimate Madoka (`MADOKA`), Homura, Demon Homura, Sayaka, Mami, Kyouko, Nagisa.
- Lua uses only vanilla GameEvents (`PlayerDoTurn`, `UnitSetXY`, `SetPopulation`, `UnitKilledInCombat`, `CityCaptureComplete`, `PlayerCanTrain`, `GetScenarioDiploModifier`). Runs on vanilla, CP and Lekmod DLLs.
- Compat shims: `ModCompatibility/PMMMModCompatibility.sql` (Civ IV Traits, Ethnic Units, YnAEMP start positions), `PMMMCBP.sql` (2015 CBP, GUID `8411a7a8-…`), E&D decisions per civ.
- Known bugs from comments: Demon Homura's Illusion Realm/Courthouse effect broken (missing XML), Sayaka missing for some users, MP desync with Ultimate Madoka on simultaneous turns (Pebble's group fixed it by running the end-turn handler for every player and checking the civ inside), Incubators can't work Information-era improvements with Enlightenment Era, civ-removal mods hide these civs.
- Reference overlay on disk: `Downloads\Archives\Madoka Magica Civpack by ViceVirtuoso - Vox Populi Edition.zip` (Blue Ghost, Dec 2017): VP-aware SQL for six civs, disables Ultimate Madoka and Demon Homura. Good template for CP/VP conditional SQL.

## 2. Environment (this PC)

- Civ V 1.0.3.279 (exe dated 2014‑11‑19). That **is** the current build; nothing has changed in the game since 2014, so "runs on the current build" really means "runs on the current Community Patch DLL".
- Community Patch: latest **5.4.6** (2026‑08‑31). `(1) Community Patch` GUID `d1b6328c-ff44-4b0d-aad7-c657f83610cd`, modinfo v151, ships `CvGameCore_Expansion2.dll` in the MODS folder. CP-only (without Vox Populi) is still a supported install. 323 `MOD_*` feature switches; most former "DLL Various Mod Components" features live behind `CustomModOptions` rows.
- Lekmod **v34.15** installed as `Assets\DLC\LEKMOD_v34.15` (GitHub main is already v35.3000, pushed 2026‑09‑05). Structure: `MPModsPack.Civ5Pkg` (priority 300), its own `CvGameCore_Expansion2.dll` (vanilla-derived fork with extras such as `SetNumRealBuildingClass`, `HasPolicyBranch`; **not** CP/VMC), 519 zero-byte `Override\*.xml` blanking the base game, one 11.8 MB `Override\CIV5Units.xml` whole-database dump (115 civs), Lua hooked from `Lua\UI\InGame.lua` via `LoadNewContext(...)`, `ui_check.bat` swaps Standard/EUI variants from `Lua\tmp\{ui,eui}`, lobby drafter regex `^CIVILIZATION_(?:MC_|LEKMOD_|D3_)?(.+)$`.
- Toolchain: VS 2022 Community + Build Tools only. CP DLL needs VC++ 2008 SP1 + VC++ 2010 SP1 (v90 toolset) or its clang scripts; Lekmod's `build_mod.bat` also assumes VS 9.0 + MSBuild 12. No 7‑Zip (needed for `.civ5mod`, which is a 7z archive). `gh` is authenticated.

## 3. Hard constraints that shape the design

1. **CP and Lekmod cannot coexist.** Each supplies its own `CvGameCore_Expansion2.dll`; only one gamecore loads. This is why the Lekmod build must be a separate patch.
2. **Civ V multiplayer ignores the MODS folder.** Only DLC packs load in the MP lobby, which is why Lekmod is a DLC-hack pack. The Lekmod patch must therefore be a DLC-pack overlay, and every player needs byte-identical files.
3. **Lekmod's DLL has none of the CP hooks WFTW relies on.** The Magical Girl system (capture rules, military-might, custom events) cannot be ported to Lekmod without forking Lekmod's DLL, which would break MP with everyone else. The Lekmod patch should carry Rebellion-style civs (vanilla Lua API) only.
4. **CP's database schema moved a lot since 2015.** WFTW's table additions and any `ALTER TABLE` will collide with columns CP now ships; CP also changed several GameEvents signatures. Expect the "crash when an MG spawns" to be one of these, not an engine bug.
5. Civ count: WFTW (10) + Rebellion (8) + new girls (~15+) + Lekmod's 115 push past the default; plan for CP's 43-civ build and Lekmod's own limits.

## 4. Phased plan

### Phase 0 — Acquire and baseline (blocked on you)
- Get WFTW's files: subscribe on Steam and open the in-game Mods menu once (Civ V downloads workshop items into `MODS` as `.civ5mod`), or tell me to fetch it (SteamCMD anonymous or the Mega link on the Workshop page; I will not download without your go-ahead).
- Install 7‑Zip to unpack `.civ5mod` (`winget install 7zip.7zip`), with your OK.
- Create the git repo in `Exploratory\madoka-civ5\` with `wftw\` (upstream v26 as the first commit, untouched), `rebellion\` (v12 as-is), `docs\`.
- Snapshot upstream behaviour: load WFTW under CP 5.4.6 (CP-only), collect `Database.log`, `Lua.log`, `xml.log`, and a minidump of the MG-spawn crash. This gives the bug list for Phase 2.

### Phase 1 — Community Patch integration
Two readings of "integrate the CP DLL"; recommend the first:
- **A. Depend on `(1) Community Patch`** (reference GUID `d1b6328c-…`, minversion 151). No compiling. Turn on the `CustomModOptions` switches WFTW needs via SQL (events for unit capture/creation/prekill, etc.). This is how the original shipped and how every CP-based mod works today.
- **B. Ship a custom DLL build** only if a required hook is missing. Cost: VC++ 2008/2010 install, a fork of the CP repo, and a rebuild for every CP release. Keep as a fallback; prototype any new hook as a CP pull request first, since CP still merges community hooks.
Deliverable: WFTW loads on CP 5.4.6 with zero Database.log errors and no CTD through 100 AI-only turns.

### Phase 2 — Port and fix
- Schema: reconcile `MadokaNewTables`-style additions with CP tables; move to `CREATE TABLE IF NOT EXISTS` + column-existence checks (pattern already in `PMMMCBP.sql`).
- Lua: replace removed/renamed API, re-check every `GameEvents` signature against CP's current `CvLuaGameEvents`, replace `Events`-context reads used for gameplay with gamecore data, and verify TSL serialization under CP's save format.
- Known bugs to reproduce and fix: MG-spawn CTD; Time Stop (either stay removed or re-implement with CP's `UnitCanMove`/plot-freeze events); Demon Homura Illusion Realm (Rebellion); Enlightenment Era improvement whitelist for Incubators; Ultimate Madoka simultaneous-turn desync.

### Phase 3 — Compatibility hardening
- Priority list: CP-only, full Vox Populi, EUI 1.28/1.29+, Events & Decisions, YnAEMP, Enlightenment Era, civ-removal mods, 43-civ DLL.
- Method: no wholesale UI file replacement (that is what breaks EUI/VP); use addin contexts and CP's exposed Lua UI hooks; keep every third-party shim in conditional SQL like the existing `ModCompatibility\` folder; maintain a compatibility test matrix in `docs\`.

### Phase 4 — Mechanic changes for the MG civs
Your design call. Suggested process: write `docs\mechanics.md` describing current MG/Soul Gem/Mood/Witch numbers (all live in `WFTWGameDefines.xml`) and the changes you want, then implement per subsystem with AI-only autoplay tests. I would separate "tuning" (defines only) from "new behaviour" (Lua/DLL).

### Phase 5 — New civilizations
- Roster candidates: Magia Record (Iroha Tamaki, Yachiyo Nanami, Tsuruno Yui, Felicia Mitsuki, Sana Futaba, Momoko Togame, Rena Minami, Kaede Akino, Mifuyu Azusa, Touka Satomi, Nemu Hiiragi, Alina Gray, Kuroe, Ui Tamaki); Oriko Magica (Oriko Mikuni, Kirika Kure, Yuma Chitose); Tart Magica (Tart/Jeanne, Riz Hawkwood, Melissa de Vignolles, Corbeau, Minou, Lapin, Isabeau, Elisa Celjska).
- Build a civ template (SQL + trait Lua + E&D decisions + YnAEMP positions + text) from the Rebellion bootstrapper pattern so each girl is a folder. Art is the real cost: leaderscene, DoM, icon atlases, unit models; budget it per civ and decide which get AI-playable leaderscenes.

### Phase 6 — Lekmod multiplayer patch (separate deliverable)
- Content: Rebellion-style civs (plus Phase 5 civs written to the vanilla Lua API); no MG system.
- Form: a build script that overlays onto an installed `LEKMOD_vXX` folder: adds new GameData/TextData XML (generated from the SQL by applying it to a scratch DB and exporting), art folders, `Lua\Civilizations\Madoka_*.lua`, patches `InGame.lua` and both `Lua\tmp\ui` and `Lua\tmp\eui` variants with `LoadNewContext` lines, registers civs with the drafter. Output is a zip everyone installs; version-pinned to the Lekmod release your group plays (installed 34.15 vs GitHub 35.x, decide).
- MP safety rules: gameplay logic only in `GameEvents` handlers, never `Game.GetActivePlayer()` for gameplay, `Game.Rand` not `math.random`, no per-client state; test on simultaneous turns with two clients.

## 5. Decisions I need from you
1. How to obtain WFTW (subscribe yourself, or authorize a download by me).
2. "Integrate the CP DLL": dependency (recommended) or bundled custom build.
3. Lekmod target version and whether the Lekmod patch is Rebellion-civs-only (recommended).
4. Permission to install 7‑Zip now and the VC++ 2008/2010 toolchain if Phase 1B or a Lekmod DLL change becomes necessary.

## 6. Sources
- Workshop: WFTW https://steamcommunity.com/sharedfiles/filedetails/?id=273118128 · change notes https://steamcommunity.com/sharedfiles/filedetails/changelog/273118128 · Rebellion https://steamcommunity.com/sharedfiles/filedetails/?id=207117800
- CivFanatics WFTW thread https://forums.civfanatics.com/threads/wip-madoka-magica-wish-for-the-world.543931/
- Community Patch repo/releases https://github.com/LoneGazebo/Community-Patch-DLL · DEVELOPMENT.md (toolchain)
- Lekmod repo https://github.com/EnormousApplePie/Lekmod · docs/installation.md
- MPMPM DLC-hack thread https://forums.civfanatics.com/threads/mpmpm-multiplayer-mod-dlc-hack-updated.533238/
