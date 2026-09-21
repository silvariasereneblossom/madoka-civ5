# Lekmod port, Investigation 2: database dependencies

Research report produced 2026-09-18 for the Lekmod scoping pass (`docs/design/lekmod-scoping-plan.md`, Investigation 2).
The question: if Wish for the World's database is loaded onto Lekmod's, what fails loudly, what drifts silently,
and how much of the port is per-file variant work versus one compatibility file.

Method: schema diffs in python `sqlite3` across the simulator databases; a full `civdb.py` simulated load of WFTW
on a Lekmod seed (`build/sim_lekmod35_wftw.db` / `build/sim_lekmod35_wftw.md`); a replay of every `ALTER TABLE` in
the mod against a copy of the Lekmod seed; and a value-by-value comparison of every vanilla row the mod references
with `INSERT ... SELECT`. Nothing in `wftw/` and no pre-existing database was modified; the scratch databases made
for this report are `build/lekmod-scope-altertest-v2.db` (ALTER replay) and `build/lekmod-scope-megafile-reparse.db`
(megafile fidelity check). The game's SQLite is 3.7.17 — no `WITH`, no window functions — and a `.sql` file aborts
at its first failing statement, while XML files continue element by element; everything below respects that.

**Headlines.**

- The mod's own schema work is **free**: all 94 of its `ALTER TABLE` statements apply cleanly on a copy of the
  Lekmod v35 seed (94 ok, 0 failed), and all 82 of its defines are self-created and land fine.
- The simulated load fails **28 of 153 actions**. 14 of those are the pre-existing failures (DecisionsMod files,
  the two optional-mod compatibility files); **14 are Lekmod-specific**. Every Lekmod-specific failure except one
  class is a missing Community Patch table or column, and all but three files are absorbed by one early-loaded
  schema shim. The exception class is Lekmod's **promotion-prereq relocation**, which needs real variants.
- **44 vanilla rows the mod copies or references were rebalanced by Lekmod** (29 single-row, 15 multi-row).
  `INSERT ... SELECT` copies inherit Lekmod's values automatically, so nothing fails — but the resulting stats
  drift from what was play-tested on CP, and the drift is itemised in section 6.
- Applying CP's database on top of Lekmod's is a **non-starter** (34 failing files from CP's own SQL), so the
  port must speak Lekmod's schema directly. Two of the CP trait tables the mod uses exist natively in Lekmod
  and are read by Lekmod's DLL, so a small slice of CP data works as-is.

---

## 1. The seeds and what each one proves

Seven databases underpin this report. Provenance was verified with `sqlite3` before anything was trusted: a real
game-cache dump carries `ApplicationInfo`, `ScannedFiles` and `DownloadableContent` rows and retains the art, audio
and map tables the game's cache always has; a parsed database has exactly the tables one input file defines.

| Database | What it is | Notes |
|---|---|---|
| `build/seed_vanilla_bnw.db` | Real game-cache dump, vanilla BNW 1.0.3.279 | Baseline for all diffs |
| `build/sim_cp_only.db` | `civdb.py` build: CP 5.4.6 alone on the vanilla seed | The "CP value" side of the collision scan |
| `build/sim_cp_wftw.db` | CP 5.4.6 + WFTW (310 files, 15 failures) | The mod's schema truth today |
| `build/seed_lekmod34_core.db` | **Real game-cache dump with Lekmod installed** | Installed release, slightly older than upstream master: 115 civs (no BUGANDA / MALI), no Lekmod trade-connection tables, art/audio/map tables intact, `UnitPromotions_PromotionPrereqOrs` present with 171 rows |
| `build/lekmod35_units.db` | `civdb.py` standalone parse of `Override/CIV5Units.xml` (v35.3000) | 430 tables, 117 civs, 162 prereq-link rows. **An overlay, not a standalone DB**: re-parsing it into an empty database produces 2,887 errors, ~2,865 of them `<ArtDefine_*><Row>: no such table` / `<Audio_*><Row>: no such table` — Lekmod's ~2,900 art and audio rows reference base-game tables the megafile never defines |
| `build/seed_lekmod35.db` | Hybrid: vanilla skeleton + the v35 megafile parse | 460 tables; the seed used for the WFTW load probe |
| `build/sim_lekmod35_wftw.db` / `.md` | WFTW loaded on `seed_lekmod35.db` | The portability probe this report is built on |
| `build/sim_lekmod_cp_wftw.db` / `.md` | CP 5.4.6's database loaded on the Lekmod dump, then WFTW | 279 files ok, **34 failed**, 79 errors — CP's own files collide with Lekmod's schema |

Two fidelity rules follow. First, the **dump is ground truth for the installed release**, and the **parse is
upstream-master gameplay data without art** — every structural finding below was checked against both, and they
agree everywhere except one place, which is itself informative: the v34 dump still contains
`Belief_YieldChangePerForeignCity`, `Belief_YieldChangePerXForeignFollowers`, `Belief_YieldChangeWorldWonder` and
`Policy_BuildingClassTourismModifiers`, but the v35 megafile mentions each only inside XML comments
(`CIV5Units.xml:30745` "combined into Belief_YieldChangePerFollowingCity", `:30805` "Merged into the table
`<WorldWonderYieldChanges>`") and never creates them — Lekmod v35 deleted these four vanilla tables, on top of the
two it deleted earlier. Lekmod's schema is a moving target, and a port must pin a version. Second, the 20
"TABLE-NOT-IN-LEK" hits in the old collision scan are parse artifacts: they are all `ArtDefine_*` rows from
`wftw/SQL/Shared/UnitArtDefines.sql`, tables the real game (and the dump) always has but the parsed megafile
lacks. They are not collisions and are excluded below.

Reproduce the probe with:

```bash
python scripts/civdb.py build --seed build/seed_lekmod35.db --out build/sim_lekmod35_wftw.db --mod wftw --report build/sim_lekmod35_wftw.md
```

## 2. Schema deltas: vanilla vs CP vs the mod, and Lekmod's answer

Diffing `sim_cp_wftw.db` against `seed_vanilla_bnw.db` and attributing every non-vanilla item by searching CP's
`Database Changes/` tree versus the mod's own SQL:

| Layer | Tables | Columns | Defines | Where |
|---|---|---|---|---|
| Community Patch 5.4.6 | +473 | +1,038 (Traits 131, HandicapInfos 168, Policies 143, Buildings 142, UnitPromotions 134, Units 58, ...) | +906 (+20 PostDefines) | CP only |
| WFTW's own additions | +49 | +94 (Traits 46, UnitPromotions 15, Policies 12, Buildings 9, Missions 5, Civilizations 3, Beliefs 3, Specialists 1) | +82 (all self-created) | `wftw/SQL/Shared/MadokaTableUpdates.sql` |
| Lekmod v35 vs vanilla | −6 tables, +128 columns in 16 tables | | +19 defines, several retuned | `Override/CIV5Units.xml` + DLL `_Defines.h` |

The mod's 94 columns all live in `MadokaTableUpdates.sql`, which is why the ALTER replay (section 4) is the
decisive test. The mod reads 95 `GameDefines` — **none is CP-only, none was removed or changed by Lekmod**, so
defines are a non-issue for the port.

Lekmod's own schema, as evidenced from both sources:

- **Promotion prereqs relocated.** `UnitPromotions.PromotionPrereq` and `PromotionPrereqOr1..9` are deleted; OR
  prerequisites live in a link table `UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)`.
  The DLL reads them under `LEKMOD_RELOCATE_PROMOTION_PREREQ_ORS`:
  `upstream/Lekmod/LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvPromotionClasses.cpp:630-655` loads prereqs via
  `SELECT UnitPromotions.ID FROM UnitPromotions_PromotionPrereqOrs INNER JOIN UnitPromotions ON
  UnitPromotions.Type = PrerequisitePromotion WHERE PromotionType = ?`; the vanilla column reads survive only
  behind `#if !defined(...)` at `CvPromotionClasses.cpp:457-477`. The AND prerequisite is dead in Lekmod's build.
- **Deleted vanilla tables**: `Trait_UnimprovedFeatureYieldChanges`, `Trait_YieldChangesStrategicResources`
  (both versions), plus the four belief/policy tables above (v35 only).
- **Deleted vanilla content**: `UNIT_SWEDISH_CAROLEAN` and `IMPROVEMENT_FEITORIA` are gone but their child rows
  (9 and 5 rows across `Unit_AITypes`, `UnitClasses`, `Unit_ClassUpgrades`, `Unit_Flavors`,
  `Unit_FreePromotions`, `UnitGameplay2DScripts`, `Improvements`, ...) were left dangling in Lekmod's own seed.
  `TRAIT_GERMANY` is fully replaced (Furor Teutonicus → Precision German Engineering); `GOLDEN_AGE_CULTURE_MODIFIER`
  is removed (the known CP assert).
- **`TRAITIFY`** (`_Defines.h:1050`): Lekmod independently implements eighteen CP-named trait tables and reads
  them natively — `CvTraitClasses.cpp:1919` (`Trait_YieldFromKills`), `CvTraitClasses.cpp:2421`
  (`Trait_BuildingClassYieldChanges`), consumed in `CvPlayer.cpp:13551/13566`;
  `CvPromotionClasses.cpp:527` (`UnitPromotions_YieldFromKills`). This is a genuine convergence with CP that the
  port gets for free (below).
- **Defines retuned**: prophets deterministic (`RELIGION_BASE_CHANCE_PROPHET_SPAWN` 5 → 100), first-pantheon
  10 → 23, first-prophet 200 → 300, `BARBARIAN_NAVAL_UNIT_START_TURN_SPAWN` 30 → 50, plus yield caps,
  `NEW_SCORE_*` and `INTERNAL_TRADE_*` additions. No unit-supply system: `HandicapInfos.ProductionFreeUnits`
  is 99999 on all handicaps.

## 3. Every CP item the mod actually uses, and Lekmod's answer

**Tables.** Nine CP tables are used (the mod's usage was classified from `build/lek_classify.txt`, re-verified by
grep; `Community` turns out to be self-created by the mod itself, so it is moot):

| Table | Used at | In Lekmod? | Consequence |
|---|---|---|---|
| `Community` | `wftw/SQL/Sweden/GustavusTrait.sql:1` (`CREATE TABLE IF NOT EXISTS COMMUNITY`) | No | Moot — the mod creates it; it is a CP-balance-leaders guard |
| `Trait_BuildingClassYieldChanges` | Phase4 civ SQL | **Yes (native, TRAITIFY)** | Works as pure data |
| `UnitPromotions_YieldFromKills` | Phase4 civ SQL | **Yes (native)**, one extra column (`Max`) | Works as pure data |
| `CustomModOptions` | `XML/CIV5Options-MadokaDVMC.xml` | No | 16 load errors; rows inert without CP's DLL switches (Investigation 1) |
| `DiploModifiers` | `XML/CIV5DiploModifiers-Madoka.xml` | No | 2 load errors; table needs a shim, effect needs the DLL |
| `Improvement_AdjacentResourceYieldChanges` | `SQL/Phase4/OrikoKirika.sql:53-56` | No | Farsight Oracle yields need shim + DLL |
| `Trait_LitYieldChanges` | `SQL/Phase4/KaoruUmika.sql` (stmt 5) | No | Kazumi writing yields need shim + DLL |
| `Trait_YieldFromCSAlly` / `...CSFriend` | `SQL/Phase4/Mami.sql:17-22` (stmt 1) | No | Mami's city-state yields need shim + DLL |

**Columns.** Every CP column the mod writes is absent from Lekmod (verified `van=False, CP=True, lek=False` for
each), and each is the abort point of exactly one failing statement in the probe:

| Column | Used at |
|---|---|
| `HandicapInfos.BarbarianCampGold` / `.AIBarbarianCampGold` | `SQL/Shared/MGDefines.sql:691-698` (camp gold + trigger `SetBarbCampGold0`) |
| `UnitPromotions.DamageTakenMod` | `SQL/Phase4/Abilities.sql:29-30`, `SQL/Phase4/Sayaka.sql:42-43` |
| `UnitPromotions.PromotionPrereqOr1` | `SQL/Shared/MGDefines.sql` (stmt 62), `XML/CIV5UnitPromotions-Madoka.xml` (24-25 rows) |
| `UnitPromotions.SplashDamage` | `SQL/Phase4/Nagisa.sql:141-142` |
| `UnitPromotions.IsVisibleAboveFlag` | `SQL/Phase4/Mami.sql:265-266` |
| `UnitPromotions.CannotBeCaptured` | `SQL/Shared/MGDefines.sql:838` |
| `Units.CanChangePort` / `.CanRepairFleet` | `SQL/Shared/NavalOutpost.sql:1-3` |
| `Units.MaxHitPoints` | `SQL/Phase4/Sayaka.sql:202-203`, `SQL/Phase4/DemonHomura.sql:244` |
| `Units.CargoCombat` | `SQL/Phase4/DemonHomura.sql:155` (the giant full-column copy; `CargoCombat` at `:243`) |
| `Units.PromotionClass` | `XML/CIV5UnitPromotions-Madoka.xml` (`<Units><Update>`), read with a fallback in `Lua/PMMMGeneralFunctions.lua:362-363` |
| `Traits.StartsWithPantheon` | `SQL/Phase4/Kyouko.sql:28-29` |
| `Traits.SpyExtraRankBonus` / `.SpyMoveRateModifier` | `SQL/Phase4/OrikoKirika.sql:24-25` |
| `Traits.GreatWorkWLTKD` | `SQL/Phase4/KaoruUmika.sql:52` |
| `Buildings.NationalPopRequired` | `SQL/Phase4/Madoka.sql:61-62` |
| `Buildings.CapitalOnly` / `.GreatWorkYieldType` | `SQL/Phase4/Sayaka.sql:157-158` |
| `Policies.IsDummy`, `Buildings.IsDummy` / `.ShowInPedia` | `SQL/Phase4/Kyouko.sql:172-183`, `Mami.sql:213-222`, `Sayaka.sql:107-119` |
| `Resources.IsMonopoly` / `.MonopolyHappiness` / `.MonopolyGALength` | `SQL/Phase4/KaoruUmika.sql:98` |
| `Buildings.ConversionModifier` / `.GlobalFollowerPopRequired` / `.IsReformation` | `XML/CBPReligiousWonder.xml` (already a pre-existing CBP-only failure today) |

Two Lua reads degrade gracefully rather than failing: `PromotionClass`
(`Lua/PMMMGeneralFunctions.lua:362-363` falls back to `"UNITCOMBAT_MAGICALGIRL"`) and `CannotHeal`
(`Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityHomura.lua:207-208` iterates `GameInfo.UnitPromotions()` and
nil-compares), so Time Stop's healing suppression quietly stops working on Lekmod until the DLL port lands.

## 4. The ALTER TABLE replay: clean

All 94 of the mod's `ALTER TABLE` statements live in `wftw/SQL/Shared/MadokaTableUpdates.sql`. Replayed against
a fresh copy of `seed_lekmod35.db` (`build/lekmod-scope-altertest-v2.db`): **94 ok, 0 failed** — no column name
collides with anything Lekmod added, and none of Lekmod's 128 added columns is shadowed. In particular the seven
`Traits.PMMM*` columns our DLL patch reads (`dll/pmmm-phase4.patch`: `PMMMMIgnoreUnhappinessPenalties`,
`PMMMUnhappinessPerBonusPercent`, `PMMMUnhappinessBonusMax`, `PMMMNoGoldenAges`, `PMMMNoIdeologyPressure`,
`PMMMCityCapThreshold`, `PMMMCityCapUnhappinessStep`) all exist on Lekmod the moment the mod loads. The schema
side of Ai Yo and Mami's city cap is done; only the DLL side (Investigation 1) remains.

## 5. The simulated load: what fails on Lekmod's schema

`build/sim_lekmod35_wftw.md`: **files ok 125, failed 28, errors 68, warnings 96** (CP baseline: 310 ok, 15 failed,
156 warnings — and the warning sets are identical between the two builds, confirming only hard schema is at
issue). Of the 28:

- **14 reproduce the CP baseline's pre-existing failures**: the 11 `DecisionsMod/SQL/*DecisionData.sql` files
  (`no such table: DecisionsAddin_Support` — that mod is not installed), `PMMMCBP.sql` (CBP/Vox Populi columns,
  stmt 2/21 `IlliteracyHappinessChange`), `PMMMSuperpower.sql` (UNIQUE constraint, pre-existing), and
  `XML/CBPReligiousWonder.xml` (CBP column). The CP baseline's 15th failure was CP's own packaging (a file
  listed in CP's modinfo but missing on disk), which vanishes when CP is not loaded. Nothing to do here.
- **14 are Lekmod-specific** — every one a missing CP table/column, except the promotion-prereq class:

| File | Fails at | Cause |
|---|---|---|
| `SQL/Phase4/Abilities.sql` | stmt 4/28 | `UnitPromotions` has no column `DamageTakenMod` |
| `SQL/Phase4/DemonHomura.sql` | stmt 22/65 | no such column `CargoCombat` (the full-column copy at `:155`) |
| `SQL/Phase4/KaoruUmika.sql` | stmt 5/16 | no such table `Trait_LitYieldChanges` |
| `SQL/Phase4/Kyouko.sql` | stmt 2/31 | no such column `StartsWithPantheon` |
| `SQL/Phase4/Madoka.sql` | stmt 3/19 | no such column `NationalPopRequired` |
| `SQL/Phase4/Mami.sql` | stmt 1/47 | no such table `Trait_YieldFromCSAlly` |
| `SQL/Phase4/Nagisa.sql` | stmt 18/32 | no such column `SplashDamage` |
| `SQL/Phase4/OrikoKirika.sql` | stmt 1/17 | no such column `SpyExtraRankBonus` |
| `SQL/Phase4/Sayaka.sql` | stmt 4/51 | `UnitPromotions` has no column `DamageTakenMod` |
| `SQL/Shared/MGDefines.sql` | stmt 62/115 | `PromotionPrereqOr1` (relocation — see below) |
| `SQL/Shared/NavalOutpost.sql` | stmt 1/8 | no such column `CanRepairFleet` |
| `XML/CIV5DiploModifiers-Madoka.xml` | 2 rows | no such table `DiploModifiers` |
| `XML/CIV5Options-MadokaDVMC.xml` | 16 updates | no such table `CustomModOptions` |
| `XML/CIV5UnitPromotions-Madoka.xml` | 24-25 rows + 1 update | `PromotionPrereqOr1`; one `<Units><Update>` on `PromotionClass` |

`SQL/Phase4/Homura.sql` and `SQL/Phase4/UltimateMadoka.sql` load cleanly — Homura is the one Phase 4 civ whose
data is already pure vanilla-schema.

**The MGDefines abort is the expensive one.** Because SQL aborts at the first failing statement, everything from
statement 63 to 115 is lost when `PROMOTION_PMMM_CHARISMA_II` hits `PromotionPrereqOr1`: the rest of the MG
promotion tree, ~40 `Language_en_US` updates, the barbarian-camp gold write
(`UPDATE HandicapInfos SET BarbarianCampGold = 1, AIBarbarianCampGold = 1, BarbCampGold = 0` plus trigger
`SetBarbCampGold0`, `MGDefines.sql:691-698`), the Witch Barrier `ArtDefine_Landmarks` inserts, and
`UPDATE Improvements SET ArtDefineTag='ART_DEF_IMPROVEMENT_PMMM_WITCH_BARRIER' WHERE
Type='IMPROVEMENT_BARBARIAN_CAMP'`. A late compatibility file *can* re-issue those (they are idempotent
UPDATEs/INSERTs), but the cleaner cut is a variant of the promotion statements themselves (section 8).

**Foreign keys.** The report's FK pass lists 11 findings (CP baseline: 3). Checked against the pristine seed,
most are Lekmod's own pre-existing dangling rows — the `UNIT_SWEDISH_CAROLEAN` children (9 rows) and
`IMPROVEMENT_FEITORIA` children (5 rows) Lekmod never cleaned up, plus a `BUILDING_MC_MALAE_FOOD` and a
trade-connection row. The genuinely mod-caused set is `UnitPromotions_UnitCombats` rows for the MG training
promotions (`PROMOTION_SIEGE_TRAINING_1` etc.): the XML inserts the UnitCombats links but the parent promotion
rows failed on `PromotionPrereqOr1`, and XML keeps going element by element.

**CP-on-Lekmod is not a shortcut.** `build/sim_lekmod_cp_wftw.md` (CP's database applied on the Lekmod dump, then
WFTW) fails 34 files with 79 errors, most inside CP's own SQL — column-count mismatches on GoodyHut fixes,
duplicate columns (`FreeCapitalBuilding`, `GiveDomain`, `WaterAdjacencyMakesValid`), "table already exists" for
tables Lekmod already ships. Even if the DLLs could coexist (they cannot; HANDOVER section 6), the database
layers are mutually exclusive.

## 6. Rows the mod references that Lekmod rebalanced

The mod copies vanilla rows with `INSERT INTO ... SELECT ... FROM <table> WHERE Type = '<row>'`. The scan
(`build/lek_copies.py` → `lek_copies.json`) found **191 such references**; comparing each source row's values in
`sim_cp_only.db` against `lekmod35_units.db`:

| Result | Count | Meaning |
|---|---|---|
| identical | 127 | Copy behaves the same on both |
| DIFF (one row each side) | 29 | The copied row's values differ — listed below |
| MULTI-DIFF (row sets differ) | 15 | Lekmod added/removed sibling rows |
| TABLE-NOT-IN-LEK | 20 | All `ArtDefine_*` — parse artifacts (section 1), not real |
| ROW-NOT-IN-LEK | 0 | Lekmod never deleted anything the mod copies |

Because these are `SELECT`s over the live database, the copies **inherit Lekmod's values automatically** — the
load succeeds and the mod adapts. The hazard is not failure but silent drift from the CP-playtested numbers,
and any statement pinning a literal CP-era value fights the rebalance outright. The 29 single-row diffs:

| Referenced row | CP value → Lekmod value | Referenced at |
|---|---|---|
| `Units.UNIT_WORKER` | Cost 70 → **48** | `SQL/DemonHomura/DemonHomuraUnit.sql:24` |
| `Units.UNIT_GREAT_GENERAL` | Moves 2 → **4** | `SQL/DemonHomura/DemonHomuraUnit.sql:43` (Clara Doll) |
| `Units.UNIT_INFANTRY` | Cost 375→420, FaithCost 750→840, PrereqTech Plastics → Electronics | `SQL/Homura/HomuraUnit.sql:23` |
| `Units.UNIT_SCOUT` | FaithCost 50→75, NoBadGoodies 0→1, ObsoleteTech Scientific Theory → Education | `SQL/KaoruUmika/KaoruUmikaUnit.sql:31` |
| `Units.UNIT_LANCER` | ObsoleteTech Combined Arms → Railroad, GoodyHut upgrade Anti-Tank Gun → Rifle | `SQL/Kyouko/KyoukoUnit.sql:23` |
| `Units.UNIT_TRIREME` | MinAreaSize 10 → **6** | `SQL/Shared/MGDefines.sql:110` (sea witch) |
| `Units.UNIT_WARRIOR` | ObsoleteTech Metal Casting → Iron Working | `SQL/Phase4/Homura.sql:135` (witch melee) |
| `Units.UNIT_WWI_BOMBER` | RangedCombat 50→60, Range 6→7, Cost 325→330 | `SQL/Nagisa/NagisaUnit.sql:23` |
| `Unit_ClassUpgrades.UNIT_LANCER` | upgrade target Anti-Tank Gun → Rifle | `SQL/Kyouko/KyoukoUnit.sql:103` |
| `Buildings.BUILDING_GARDEN` | GreatPeopleRateModifier 25→20, Theology → Drama | `SQL/Phase4/DemonHomura.sql:462` |
| `Buildings.BUILDING_PAGODA` | IsReligious 0→1, FoodKept 0→**10**, Happiness 2→**1** | `SQL/Shared/MGMoods.sql:238` |
| `Buildings.BUILDING_TEMPLE` | Cost 100 → 75 | `ModCompatibility/.../PMMMCBP.sql:10` |
| `Buildings.BUILDING_COURTHOUSE` | NeverCapture 0→1, Cost 100→75 | `SQL/Shared/EntertainmentYield.sql:43` |
| `Buildings.BUILDING_STABLE` | NeverCapture 0→1 | `SQL/Shared/EntertainmentYield.sql:271` |
| `Buildings.BUILDING_CARAVANSARY` | Cost 120→90, TradeRouteLandGoldBonus 200→0 | `SQL/Mami/MamiBuilding.sql:64` |
| `Buildings.BUILDING_HARBOR` | MinAreaSize 10→−1, TradeRouteSeaGoldBonus 100→0 | `SQL/Shared/EntertainmentYield.sql:195` |
| `Buildings.BUILDING_BROADCAST_TOWER` | CultureRateModifier 33→0 | `SQL/Shared/EntertainmentYield.sql:55` |
| `Buildings.BUILDING_SPACESHIP_FACTORY` | SpaceProductionModifier 50→100 | `SQL/Shared/EntertainmentYield.sql:142` |
| `Buildings.BUILDING_CRISTO_REDENTOR` | Cost 1250→1203, PolicyCostModifier −10→−15 | `SQL/Shared/EntertainmentYield.sql:335` |
| `Buildings.BUILDING_FACTORY` | FaithCost 0→360, UnlockedByBelief 0→1 | `SQL/Shared/EntertainmentYield.sql:115` |
| `Buildings.BUILDING_LABORATORY` | FaithCost 200→500 | `SQL/Shared/EntertainmentYield.sql:283` |
| `Buildings.BUILDING_PUBLIC_SCHOOL` | FaithCost 200→300 | `ModCompatibility/.../PMMMCBP.sql:5` |
| `Building_YieldChanges.Opera House` | Yield 1→2 | `SQL/Sayaka/SayakaBuilding.sql:334` |
| `Policies.POLICY_FIVE_YEAR_PLAN` | CultureCost 10→0 | `SQL/Shared/MGMoods.sql:680` |
| `Policies.POLICY_MILITARISM` | CultureCost 10→0, Level 2→1 | `SQL/Shared/MGMoods.sql:690` |
| `Policies.POLICY_VOLUNTEER_ARMY` | CultureCost 10→0, Level 2→1, BaseFreeUnits 6→**3** | `SQL/Shared/MGMoods.sql:670` |
| `Missions.MISSION_SKIP` | DisabledHelp text → none | `SQL/Phase4/Homura.sql:94` |
| `UnitPromotions.PROMOTION_DRILL_1` | HotKey none → KB_X | `SQL/Shared/MGDefines.sql:453` |
| `UnitPromotions.PROMOTION_SHOCK_1` | HotKey none → KB_Z | `ModCompatibility/.../PMMMSuperpower.sql:18` |

The 15 multi-row diffs: `Diplomacy_Responses` GENERIC (v319 → l276 rows, `SQL/Shared/Dialog.sql:108`),
`Unit_Builds.UNIT_WORKER` (v25 → l40), `Units.Special = SPECIALUNIT_PEOPLE` (v11 → l15), `Unit_FreePromotions`
for LANCER, TRIREME and COMPOSITE_BOWMAN, `Unit_AITypes` for LANCER and WORKER, `Units.Class =
UNITCLASS_WORKER`, `BuildFeatures.BUILD_CHATEAU`, `Building_DomainFreeExperiences` ARMORY and MILITARY_ACADEMY,
and Building_Flavors / Building_YieldChanges / Building_ResourceYieldChanges for PAGODA and GRANARY.

Two concrete examples of the drift in action: the **Clara Doll** (`DemonHomuraUnit.sql:43`) copies
`UNIT_GREAT_GENERAL`, so it arrives with 4 Moves on Lekmod instead of 2. The **Yuriji mood building**
(`MGMoods.sql:238`) copies `BUILDING_PAGODA` and then pins `Happiness = 0` — but not `FoodKept`, so on Lekmod it
inherits the Pagoda's 10% food-kept, a hidden buff that did not exist on CP. Every one of these needs a
deliberate keep-or-override ruling in the port, not a silent inherit.

## 7. Rule interactions

**Barbarians / Witches.** Lekmod barely touches barbarians: only `BARBARIAN_NAVAL_UNIT_START_TURN_SPAWN`
30 → 50 (naval barbs arrive later). The Witches-replace-barbarians system is structurally intact. Three data
points need variants: the camp-gold write targets CP columns (`MGDefines.sql:691-698`), so the Lekmod variant
is a single `UPDATE HandicapInfos SET BarbCampGold = 1` on the vanilla column; the sea witch copies
`UNIT_TRIREME`, whose `MinAreaSize` Lekmod dropped 10 → 6, so sea witches can spawn on smaller lakes; and the
melee witch copies `UNIT_WARRIOR`, whose stats are identical in both.

**Germany's familiar conversion is dead.** Lekmod replaced `TRAIT_GERMANY` outright, so
`SQL/Germany/BismarckTrait.sql` (statements 1, 4, 5: `UPDATE Traits SET ConvertNearbyFamiliarRadius = 2,
LandBarbarianConversionPercent = 0 WHERE LandBarbarianConversionPercent > 0`) matches zero rows — no error,
no effect. Its trigger (`OtherModsConvertFamiliarsTrait`) still gets created but fires on nothing. Harmless, but
the "mod civs with Germany's trait convert familiars" rule silently does not exist on Lekmod. Sweden
(`TRAIT_DIPLOMACY_GREAT_PEOPLE`, `GustavusTrait.sql`) and Songhai (`TRAIT_AMPHIB_WARLORD`) survive; Lekmod
buffed Sweden's trait, which the port inherits.

**Great People** all move at 4 on Lekmod, so every GP-based copy (Clara Doll above, and any GPP-based kit) drifts.
**Happiness** stays vanilla-style in Lekmod (no CBP unhappiness columns), so Ai Yo's penalties-removal has a
simpler target — but our DLL implementation sits inside CP's happiness code, which is Investigation 1's problem,
not the database's. **Unit supply** does not exist in Lekmod (`ProductionFreeUnits` 99999), so the CP supply
columns the mod touches are inert, and `POLICY_VOLUNTEER_ARMY`'s `BaseFreeUnits` semantic is different (6 → 3).
**Religion**: Kyouko's `StartsWithPantheon` is a pure DLL feature to port; Lekmod's own religion tuning
(deterministic prophets, first-pantheon 23, first-prophet 300) changes the economy her free pantheon and
Madoka's faith game sit in, and Phase 6 balance should revisit the mod's faith numbers against it.

**Promotion prerequisites** are the one genuine schema divergence with DLL backing: MG promotion trees defined
with `<PromotionPrereqOr1..9>` must instead emit `UnitPromotions_PromotionPrereqOrs` link rows, because
Lekmod's DLL never reads the columns (section 2). Lekmod's DLL also treats the AND prerequisite as dead, so any
AND-gated MG promotion needs redesign (orphan it behind an OR chain) — this affects
`XML/CIV5UnitPromotions-Madoka.xml` (56 mentions, 24-25 failing rows) and the MG tree in `MGDefines.sql`.

## 8. File accounting: Lekmod variants vs one compatibility file

Load-order facts from the modinfo (153 actions): `XML/CIV5Options-MadokaDVMC.xml` is first,
`SQL/Shared/MadokaTableUpdates.sql` is **6th** — ahead of every civ file — and the Phase 4 files load last.
That shape admits a two-file strategy:

1. **An early schema shim** (one new SQL file, loaded right after `MadokaTableUpdates.sql`): ~6
   `CREATE TABLE` statements (`CustomModOptions`, `DiploModifiers`, `Improvement_AdjacentResourceYieldChanges`,
   `Trait_LitYieldChanges`, `Trait_YieldFromCSAlly`, `Trait_YieldFromCSFriend`, — not `Community`, which the mod
   creates itself) plus ~25 `ALTER TABLE ADD COLUMN` for the CP columns in section 3. All 3.7.17-safe plain SQL.
   This alone makes 11 of the 14 failing files load: every Phase 4 civ file except DemonHomura's full-column
   copy, plus `NavalOutpost.sql` and the two XML files. **Caveat: the data written into shim columns is dead
   until the DLL port lands (Investigation 1)** — the shim is staging, and for any feature the fork decides not
   to port, the corresponding statement should be dropped instead.
2. **True content variants** (3 files), which no shim can fix:
   - `SQL/Shared/MGDefines.sql`: promotion statements must write `UnitPromotions_PromotionPrereqOrs` link rows;
     camp gold must target `BarbCampGold`.
   - `XML/CIV5UnitPromotions-Madoka.xml`: same relocation for the promotion trees (`<UnitPromotions_PromotionPrereqOrs><Row>` elements), and the `<Units><Update>` on `PromotionClass` dropped or moved into the shim's world.
   - `SQL/Phase4/Sayaka.sql`: the defensive `DELETE FROM Policy_BuildingClassTourismModifiers` (`:103`) — the
     functional use is already gone (comment at `:87`), but the statement will abort the file on Lekmod v35
     once `DamageTakenMod` is shimmed; drop it.
   - `SQL/Phase4/DemonHomura.sql` loads behind the shim, but its full-column copies
     (`:155` Units from `UNIT_SWORDSMAN`, `:367` Buildings) then copy Lekmod's rebalanced values wholesale —
     keep-or-override rulings needed, per section 6.

A single late compatibility file is **not** sufficient on its own: SQL aborts at the first failing statement,
so `MGDefines.sql` loses statements 63-115 (section 5) and each Phase 4 file loses everything after its abort
point, including statements that a late file cannot distinguish from ones that already ran. A late file works
as a *data patch* for the idempotent lost statements and the rebalance overrides, but the three variants above
must be variants.

**Count**: 3 content variants + 1 early shim + 1 late data patch ≈ 5 new/changed files at the database layer,
plus a balance review of the 44 rebalanced references (section 6) and the DLL decisions (Investigation 1).

## 9. Inputs for the fork-vs-upstream decision

1. **The database port is cheap and mechanical.** 94/94 ALTERs clean, ~25 columns and 7 tables in a shim, 3
   real variants, 5 files total. Nothing in Lekmod's schema obstructs the mod's own data. No part of this layer
   argues for or against forking — it is the same either way.
2. **Every failure that matters is a DLL feature wearing a database costume.** `DamageTakenMod`,
   `SplashDamage`, `CannotHeal`, `StartsWithPantheon`, spy rank columns, `CustomModOptions` switches,
   `DiploModifiers` — the shim can stage the data, but it is inert without a Lekmod DLL that reads it. The cost
   driver is Investigation 1, and the database evidence supports its framing: the shim is only worth building
   for the features the fork commits to porting.
3. **Balance drift is guaranteed and needs a review pass.** 44 copied references land on rebalanced rows, GP
   move at 4, prophets are deterministic, there is no unit supply, and the Temple/Worker/Courthouse economy the
   mod's numbers were tuned against does not exist on Lekmod. Phase 6 needs an explicit keep-or-override ruling
   per row of the section 6 table, ideally in the late data patch file so the rulings are reviewable in one place.
4. **No CP bundling shortcut exists.** CP's own database fails on Lekmod's schema (34 files, section 5), and the
   DLLs are mutually exclusive anyway. The port speaks Lekmod's schema directly. The one free gift is
   `TRAITIFY`: two of the CP trait tables the mod uses already exist in Lekmod and are read by Lekmod's DLL, so
   that slice of CP data works unmodified.
5. **Lekmod is a moving target at the database layer too.** v34 → v35 deleted four more vanilla tables and
   changed the roster by two civs; the promotion-prereq relocation is compile-switch-gated DLL behaviour that a
   different Lekmod build could toggle. The port must pin a Lekmod version (v35.3000 upstream as of this
   report) and re-run the `civdb.py` probe on every Lekmod update — the probe is now a known, reproducible
   check (`build/sim_lekmod35_wftw.md` is the reference output).