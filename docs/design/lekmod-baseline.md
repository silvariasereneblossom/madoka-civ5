# Lekmod v35.3 civ power baseline

Research report produced 2026-09-16 for the Phase 4 mechanics scope. Method: Lekmod ships its whole database as
two megafiles, `upstream/Lekmod/LEKMOD/Override/CIV5Units.xml` (9.77 MB, 429 table definitions + all gameplay rows)
and `CIV5Units_Mongol.xml` (6.52 MB, `Language_*`); every other file in `Override/` is zero bytes, a deliberate
blanking of the vanilla XML. Both were parsed into SQLite and diffed against `build/seed_vanilla_bnw.db`. Version
`LEKMOD/VERSION` = `v35.3000`. The repo's `docs/` holds only `installation.md`; the only prose rationale is comments
in `LEKMOD/Art/No Quitters Mod (v 11)/civs/*.xml` and that mod's changelog.

## 1. Design principles, as evidenced

**Kill RNG.** Source comment in `NQMod/civs/GermanyChanges.xml:5`: *"Bump up the chance to 100% because RNG sucks."* (barbarian conversion 67% to 100%). Same instinct in v35 Defines: `RELIGION_BASE_CHANCE_PROPHET_SPAWN` 5 to **100** (prophets are deterministic), `NUKE_UNIT_DAMAGE_BASE` 30 to 40 with both random components 40 to 30, and Spain's first-finder gold 500 to a flat **100** per Natural Wonder regardless of who finds it first.

**Replace percentage multipliers and one-shot bursts with flat per-turn yields.** Observatory +50% Science to **+4 Science flat** (now costs 1 gold); Hubble's 2 free Great Scientists to **+10 Science**; Louvre loses its free Great Artist; Leaning Tower loses its free Great Person and drops 25% to 20%; Angkor Wat's -25% plot-culture cost to **+5 Culture +5 Science**; Statue of Liberty's +1 Production per specialist to **+6 Happiness**; Statue of Zeus to **+3C/+3G/+3P**. Korea's UA is the template: the unpredictable "tech boost per science building in the capital" is deleted and replaced with +1 Science in the capital and +2 Science on three Great Person improvements.

**Everything must be live early.** Babylon's free Great Scientist moves from Writing to **Philosophy** (and 50% to 25% rate) because Writing was too early; conversely Garden moves Theology to **Drama**, Constable Banking to **Chivalry**, Lumbermill Construction to **Bronze Working**, Brazilwood Camp Machinery to **Bronze Working**, Mosque of Djenne Theology to **Philosophy**, Feitoria Navigation to **Compass**, Neuschwanstein Railroad to **Rifling** (1060 to 750 hammers). Worker cost 70 to **48**, Workboat 50 to **30**, Shrine 40 to 30, Temple/Courthouse 100 to **75**.

**MP-friendliness over simulation fidelity.** `PEACE_TREATY_LENGTH` 10 to **1** and every `GameSpeeds.PeaceDealDuration` to **1**; `HandicapInfos.ProductionFreeUnits` 5-10 to **99999** on all nine handicaps (the unit-supply production penalty is gone); Classical starts get `NoBarbUnits`/`NoGoodies` and 2 defensive units; a fifth speed `GAMESPEED_ONLINE` (50% growth/train/construct/culture, 67% research). The lobby drafter (`LEKMOD/Lua/Utilities/Lekmod_drafter.lua:4-5`) defaults to **2 bans / 3 picks per player**, which is the competitive frame the mod is balanced for.

**No snowbally late abilities.** Poland's free-policy-per-era becomes a flat **-10% policy cost**; Ideology first-adopter free policies 2 to **1** on all three branches; `SWITCH_POLICY_BRANCHES_TENETS_LOST` 2 to 1; `Eras.FaithCostMultiplier` flattened to **100** for Renaissance through Future (was 150/200/300/400/500). The Atomic Bomb is deleted outright.

## 2. What Lekmod changed, per vanilla civ

All 43 vanilla civs are present; **CIVILIZATION_VENICE is `Playable=false`**, replaced by a new `CIVILIZATION_VENEZ`. 72 new civs bring the roster to 115.

**Full UA replacements (4).** *Germany*: Furor Teutonicus to **Precision German Engineering**, +1 Production and +1 Science each on Workshop, Windmill, Factory, Hydro Plant, +33% Great Engineer rate. *Ottomans*: Barbary Corsairs to **Millets**, +1 Happiness per World Religion present in each city, plus Faith on every unit promotion (Lua: `ceil(ExperienceNeeded/3)`). *Assyria*: Treasures of Nineveh to **Siege Warfare**, siege units +1 Movement and a free Great Writer at Philosophy. *Ethiopia*: same `CombatBonusVsLargerCiv=20` column but re-read by the DLL as **flat +20 Combat Strength**, not +20%.

**Ten most-buffed** (ranked from the numbers): **Morocco** (+3G/+1C to **+4G/+2C** per trade partner, +1G/+1C per era on land routes, +2G/+1C per era at sea, plus +2G/+1G incoming); **Germany** (above; ~+8P/+8S at four cities with two buildings each); **Arabia** (lost caravan range and religion spread, gained luxury improvements built **2x faster** and **+2 Culture +2 Gold** on each of Brewery, Censer, Gem Cutter, Grocer, Mint, Textile Mill); **Netherlands** (50% luxury retention to **+1 Happiness per unique luxury** and +1 Gold per luxury tile, against a pool of **39 luxuries** vs vanilla's 26); **England** (naval +2 Movement via `Trait_MovesChangeUnitCombats`, plus +100% Production and +1 Happiness each on Constabulary and Police Station, with Constable pulled back to Chivalry); **Siam** (the 50% now includes **Happiness** and allied city-states, gifted units arrive 50% faster with **+15 XP**); **Sweden** (+10% GP only on Declaration of Friendship to **+20% Great Person points in all cities**, gift = 100 Influence **+200 Gold**, new Falu Gruva at Metal Casting); **Portugal** (Caravans/Cargo Ships **-33% Production**, Nau 5 to 6 Moves, new Feitoria harbour at 100 cost with no maintenance, +15 naval XP, +1 Gold on sea resources); **Brazil** (**Golden Age points from every kill**, GA great-person rate 50% to **100%**, Pracinha 70 to 80 CS at Electronics); **Mongolia** (a Horse tile revealed near every city at Chivalry with +1 Food on all horses, armor and mounted-ranged +1 Move, Khan 5 to 7 Moves, Keshik 15 to 17 CS / 16 to 17 RCS).

Honourable mentions: **America** loses the B17 but gains the **Pioneer** (Settler replacement, 5 CS, 2 Moves, ignores terrain cost); **India** Mughal Fort +2 Culture to **+4 Culture and +2 Happiness**; **Iroquois** Longhouse 120 to **75** hammers with Jungle and Hardwood production; **Greece** trades Companion Cavalry for the **Odeon** (Amphitheatre at Writing, +4 Culture +1 Gold, a Writer slot); **Japan** trades the Zero for the **Dojo** (+2 Science, free promotion); **Carthage** drops the Great General prerequisite on mountain-crossing and the elephant costs 100 to **75**.

**Nerfs.** *Babylon*: free Great Scientist Writing to **Philosophy**, rate 50% to **25%**. *Poland*: free policy every era to **-10% policy cost**. *Shoshone*: founded-city claim radius 8 to **4**. *Egypt*: wonder production 20% to **15%**. *Persia*: loses the +10% Golden Age combat modifier. *Korea*: specialists +2 Science to **+1**. *Spain*: 500 to 100 first-finder gold, loses the Conquistador (gains Plaza de Toros). *Huns*: lose the Battering Ram and free Animal Husbandry (gain the Qara stable, +1 Faith per Horse). *England*'s Longbowman 13 to 12 CS; *Ship of the Line* 30/35 to **27/32** and 6 to 5 Moves. *Rome*'s Legion 17 to **16** CS. *Inca*'s Slinger back to base 5 CS. Deleted: Byzantine Dromon, Carthaginian Quinquereme, Danish Ski Infantry, Swedish Hakkapeliitta and Carolean, Polynesian Maori Warrior (moved to the new Maori civ).

## 3. Tiering (judgement, with one hard data point)

The drafter tags 22 of the 42 playable vanilla civs `seasonal`, which `Lekmod_drafter.lua:347-348` excludes from the seasonal pool: Assyria, Austria, Aztec, Brazil, Byzantium, Carthage, Celts, Denmark, England, Ethiopia, France, Germany, Greece, India, Korea, Mongolia, Morocco, Poland, Polynesia, Rome, Siam, Sweden.

- **S**: Morocco (40+ gold/turn from six trade routes by the Renaissance), Germany (compounding flat P/S on buildings every city builds anyway), Siam (Happiness + Culture + Faith + Food from allies at 1.5x), Korea (still the only unconditional science engine).
- **A**: England, Netherlands, Arabia, Sweden, Poland, Brazil, Mongolia, Ethiopia (+20 flat CS is decisive in a 20-34 CS era), India, Rome, Greece, France.
- **B**: Portugal, Denmark, Assyria, Japan, Iroquois, Byzantium, Celts, Austria, Aztec, Persia, Russia, Egypt, Songhai, Maya, Indonesia, Carthage, Spain, Zulu, Ottomans, Inca.
- **C**: Babylon (25% GS rate at Philosophy is thin), Shoshone (4 tiles is a settling convenience), Huns (lost their siege identity), America, China, Venice (the vanilla entry is disabled entirely).

## 4. The benchmark: what an A-tier kit delivers

Quoted at **Standard** speed; Lekmod MP typically runs Quick (67%) or the new Online speed (50% growth/train/construct/culture), so compress by a third to a half.

| Turn | Empire state | A-tier UA should be worth |
|---|---|---|
| 30 | 2-3 cities, capital pop 5-7, ~10 total yield/turn | one free unit (40-70 hammers) **or** +2 to +4 yield/turn empire-wide, **already unlocked** |
| 60 | 4 cities, first UU window, Classical/Medieval | +6 to +10 yield/turn, or a 20-30% modifier on one yield, or a 15-25% combat edge |
| 100 | 4-6 cities, UB in every city | +12 to +20 yield/turn, i.e. roughly one extra city's economy |
| 150 | Renaissance/Industrial | +25 to +40 yield/turn or 2-3 stacking effects; **no new mechanic should switch on here** |

Six exemplar kits, all live Lekmod civs, as templates:

- **Growth**: Boers: Farms +1 Food adjacent to 2 other Farms, +1 Gold at 3, +1 Production at 4, +1 Science and Culture at 5. T30 ~ +2F; T100 ~ +8F/+4G/+3P across four cities.
- **Production**: Zimbabwe: flat **+25% Production** toward buildings and military units in the capital. One number, live turn 1.
- **Warmonger**: Maurya: +20% combat when defending on all non-armour/mounted/air. Or Manchu: Volley promotion (+50% vs fortified and cities) on all mounted/armour/bomber plus zero maintenance.
- **Culture**: Sumeria: **+2 Culture per city at Drama and Poetry**, one tech, every city, permanent. Four cities = +8 Culture/turn by T60.
- **Gold/trade**: Kilwa: +5% Food per international route departing a city, **+4 Gold per internal route**; or Morocco's per-partner scaling.
- **Wide**: Burma: **+1 global Happiness per city**, which is exactly the tax wide play pays. Or Philippines: first 2 expands get +1 Population, civilians +2 Movement at home.

Note the shape: one sentence, one or two numbers, a named trigger tech no later than Philosophy/Drama, and no conditional stacking.

## 5. Global rules that change what a civ needs

- **Happiness**: base luxury happiness is still 4, but the luxury pool is **26 to 39** (More Luxuries), `NUM_BUILDING_RESOURCE_PREREQS` 5 to 6, and six new luxury-processing buildings exist. Happiness abilities are worth *less* per point than in vanilla; luxury-*count* abilities worth more.
- **Policies**: Ideology first-adopter free policies 2 to 1; every tech from Archery onward carries `PolicyDiscountPercent=10`; Rationalism finisher loses its free tech; Fine Arts grants free Aesthetics Schools; Fortified Borders gives **+12 flat Happiness**.
- **Wonders**: cheaper and flatter (section 1). Marble's wonder bonus 15% to **10%**.
- **Units**: Chariot Archers, Camel Archers, Keshiks and Mongol units are `UNITCOMBAT_MOUNTED_RANGED`; Paratroopers/XCOM are `UNITCOMBAT_PARADROPPER`; base embarked movement **2 to 1** with +1 at Compass and +1 at Navigation; embarking moves from Optics to **Sailing** (Optics 85 to 68 beakers); Great People all move at **4**; modern units cost 15-30% more (Tank 375 to 450, Modern Armor 425 to 540, Mech 150 to 240 CS).
- **Religion**: 25 vanilla beliefs deleted, 48 added (92 total); first pantheon needs 23 faith (was 10), first prophet 300 (was 200); prophet spawn deterministic; missionary range 10 to 8 turns.
- **City-states**: allied unit-spawn interval -6, Classical/Renaissance/Industrial faith bonuses raised (2 to 3, 4 to 8, 8 to 12), `MINOR_CIV_SCIENCE_BONUS_MULTIPLIER` removed, personal quests start turn 25.
- **Tech**: Information-era costs up ~5%; `TECH_COST_TOTAL_KNOWN_TEAM_MODIFIER` 30 to 25; many early techs get `DisableTechSteal=1`.

## 6. Portability to a Community-Patch-DLL mod

Checked by grepping `upstream/Community-Patch-DLL/CvGameCoreDLL_Expansion2` for every Lekmod trait column and table.

**Portable as plain rows** (CP reads them): `WonderProductionModifier`, `GreatScientistRateModifier`, `GreatEngineerRateModifier`, `GreatPeopleRateModifier`, `PolicyCostModifier`, `ExtraHappinessPerLuxury`, `LuxuryHappinessRetention`, `CombatBonusVsLargerCiv`, `FreeUnit`/`FreeUnitPrereqTech`, `FreeCapitalBuilding`, `ExtraFoundedCityTerritoryClaimRange`, `GoldenAgeCombatModifier`, `FreeSocialPoliciesPerEra`, `NaturalWonderFirstFinderGold`, `FasterAlongRiver`, `ExtraEmbarkMoves`, `UniqueLuxuryCities`; and the tables `Trait_BuildingClassYieldChanges`, `Trait_CapitalYieldChange`, `Trait_CityYieldChange`, `Trait_YieldFromKills`, `Trait_ResourceYieldChanges`, `Trait_TerrainYieldChanges`, `Trait_FeatureYieldChanges`, `Trait_GoldenAgeYieldModifiers`, plus all vanilla `Trait_FreePromotion*`/`Trait_MovesChangeUnitCombats`. **All Units, Buildings, Improvements, Policies, Technologies, Defines, Eras and GameSpeeds rows are pure data** and port directly.

**Not portable** (zero hits in CP; Lekmod-DLL-only): tables `Trait_AnySpecificSpecialistYieldChanges`, `Trait_BuildingClassHappinessChanges`, `Trait_BuildingClassProductionModifiers`, `Trait_BuildingCostOverride`, `Trait_BuildImprovementBuildTimeOverride`, `Trait_FreeResourceCities` (+`...CityYieldChanges`), `Trait_IncomingTradeConnectionYieldChange`, `Trait_TradeConnectionYieldChange`/`...Modifier`, `Trait_PuppetYieldModifiers`, `Trait_ResourceClassYieldChange`, `Trait_RouteMovementChanges`, `Trait_UnitClassForceCapitalSpawn`, `Trait_BuildCompleteTileClaimRange`, `Trait_BanUnitMissions`, `Trait_EmbarkAllowMissions`, `Trait_GoldenAgeYieldThresholdBonus`, `Trait_GreatWorkYieldChanges`, `Trait_NoBuildImprovement`, `Trait_UnitCombatBuilds`, `Trait_UnitCombatWorkRateChange`, `Trait_City/CapitalEraYieldChange`, `Trait_City/CapitalTechYieldChange`; and columns `HappinessPerReligion`, `CityStateUnitGiftExtraExperience`, `CiviliansEmbarkOneMove`, `GlobalHappinessPerCity`, `YieldSettleUnit`, `SelfReligiousPressureModifier`, `ForeignRelgionPressureModifier`, `ReligionEnhanceReformation`, `FirstProphetCostMod`, `FaithCostModifier`, `MinorBullyModifier`, `MinorFriendshipMinimum`, `HalfMoreSpecialistUnhappiness`, `UnhappinessModifierForPuppetedCities`, `IdeologyPressureUnhappinessModifier`, `SeaTradeRoutesArePlunderImmune`, `NumExtraLeagueVotes`, `GreatGeneralSiegeBonus`, `EmbarkedUnitsFullStrength`, `NaturalWonderFirstFinderFaith`. That covers Arabia, Morocco, Ottomans, Indonesia, Netherlands' gold half, England's happiness half and Germany's building yields.

**Three traps.** (a) `CombatBonusVsLargerCiv=20` means +20% on CP and +20 flat on Lekmod: same row, different game. (b) Lekmod's `Trait_YieldChangesPerTradePartner` has extra `DomainType`/`YieldTimes100`/`EraIncreaseTimes100` columns that vanilla and CP lack; the vanilla two-column form is what CP reads. (c) Lekmod writes booleans as the strings `"true"`/`"false"` (`Walls.CityWall`, `Buildings.NukeImmune`), which on the game's SQLite 3.7.17 is a string, not 1; the same hazard flagged in `docs/port-notes.md`.

**Lua is the escape hatch.** Lekmod's three vanilla-civ scripts all use events CP supports: `GameEvents.UnitPromoted` (Ottoman faith), `GameEvents.TeamTechResearched` (Venice trade route), `GameEvents.UnitCreated` (Polynesia fix). Effects Lekmod does in the DLL, a CP mod can generally do in Lua plus a dummy building, which is the `Global_Dummy_Buildings` / `Civilization_Dummy_Policies` pattern Lekmod itself uses for its newest civs.
