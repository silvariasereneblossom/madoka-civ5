--==============================================================================
-- Phase 6 Lekmod -- REBALANCE RULINGS REVIEW (late data patch, comment-only)
--==============================================================================
-- PRIVATE Lekmod port of Madoka Magica: Wish for the World (WFTW). Lekmod's
-- license permits personal-use modification. Not for distribution.
--
-- THIS FILE EXECUTES NOTHING. It is the maintainer's review sheet for the 44
-- rows WFTW references that Lekmod v35 rebalanced (docs/design/
-- lekmod-scope-database.md section 6; raw data in build/lek_copies.txt /
-- build/lek_copies.json). WFTW copies rows with
--     INSERT INTO ... SELECT ... FROM <table> WHERE Type = '<row>'
-- so on Lekmod the copies INHERIT Lekmod's values automatically -- the load
-- succeeds and the mod adapts, but silently drifts from the CP-playtested
-- numbers.
--
-- RULING (default, per the Phase 6 plan): KEEP Lekmod's values. Every
-- potential override below is commented out; to flip a row to the
-- CP-playtested number instead, uncomment its UPDATE. Review before a long
-- Lekmod campaign; also revisit after the DLL port lands (Investigation 1),
-- since some drifts interact with engine features the port will restore.
--
-- Drift highlights worth knowing before you play:
--   * The Clara Doll (DemonHomuraUnit.sql:43) copies UNIT_GREAT_GENERAL and
--     arrives with 4 Moves on Lekmod instead of 2 -- every Great Person does.
--   * The Yuriji mood building (MGMoods.sql:238) copies BUILDING_PAGODA and
--     pins Happiness = 0 but not FoodKept, so on Lekmod it inherits the
--     Pagoda's 10% food kept -- a hidden buff that did not exist on CP.
--   * Sea witches copy UNIT_TRIREME, whose MinAreaSize Lekmod dropped to 6:
--     sea witches can spawn on smaller lakes.
--   * POLICY_VOLUNTEER_ARMY's BaseFreeUnits is 3 on Lekmod (CP: 6) and unit
--     supply does not exist on Lekmod, so supply-related inheritance is inert.
--==============================================================================

--------------------------------------------------------------------------------
-- Phase 6 Lekmod review, part 1 of 2: 29 single-row diffs (CP value -> Lekmod value)
-- Default: KEEP Lekmod's value (the copy inherits it). Uncomment to override
-- back to the CP-playtested value.
--------------------------------------------------------------------------------

-- Units.UNIT_WORKER: Cost 70 -> 48 (referenced by SQL/DemonHomura/DemonHomuraUnit.sql:24)
-- UPDATE Units SET Cost = 70 WHERE Type = 'UNIT_WORKER';

-- Units.UNIT_GREAT_GENERAL: Moves 2 -> 4 (SQL/DemonHomura/DemonHomuraUnit.sql:43, the Clara Doll)
-- UPDATE Units SET Moves = 2 WHERE Type = 'UNIT_GREAT_GENERAL';

-- Units.UNIT_INFANTRY: Cost 375 -> 420, FaithCost 750 -> 840, PrereqTech Plastics -> Electronics
--   (SQL/Homura/HomuraUnit.sql:23)
-- UPDATE Units SET Cost = 375, FaithCost = 750, PrereqTech = 'TECH_PLASTICS' WHERE Type = 'UNIT_INFANTRY';

-- Units.UNIT_SCOUT: FaithCost 50 -> 75, NoBadGoodies 0 -> 1, ObsoleteTech Scientific Theory -> Education
--   (SQL/KaoruUmika/KaoruUmikaUnit.sql:31)
-- UPDATE Units SET FaithCost = 50, NoBadGoodies = 0, ObsoleteTech = 'TECH_SCIENTIFIC_THEORY' WHERE Type = 'UNIT_SCOUT';

-- Units.UNIT_LANCER: ObsoleteTech Combined Arms -> Railroad, GoodyHut upgrade Anti-Tank Gun -> Rifle
--   (SQL/Kyouko/KyoukoUnit.sql:23)
-- UPDATE Units SET ObsoleteTech = 'TECH_COMBINED_ARMS', GoodyHutUpgradeUnitClass = 'UNITCLASS_ANTI_TANK_GUN' WHERE Type = 'UNIT_LANCER';

-- Units.UNIT_TRIREME: MinAreaSize 10 -> 6 (SQL/Shared/MGDefines.sql:110, the sea witch)
-- UPDATE Units SET MinAreaSize = 10 WHERE Type = 'UNIT_TRIREME';

-- Units.UNIT_WARRIOR: ObsoleteTech Metal Casting -> Iron Working (SQL/Phase4/Homura.sql:135, the melee witch)
-- UPDATE Units SET ObsoleteTech = 'TECH_METAL_CASTING' WHERE Type = 'UNIT_WARRIOR';

-- Units.UNIT_WWI_BOMBER: RangedCombat 50 -> 60, Range 6 -> 7, Cost 325 -> 330 (SQL/Nagisa/NagisaUnit.sql:23)
-- UPDATE Units SET RangedCombat = 50, Range = 6, Cost = 325 WHERE Type = 'UNIT_WWI_BOMBER';

-- Unit_ClassUpgrades.UNIT_LANCER: upgrade target Anti-Tank Gun -> Rifle (SQL/Kyouko/KyoukoUnit.sql:103)
-- UPDATE Unit_ClassUpgrades SET UnitClassType = 'UNITCLASS_ANTI_TANK_GUN' WHERE UnitType = 'UNIT_LANCER';

-- Buildings.BUILDING_GARDEN: GreatPeopleRateModifier 25 -> 20, tech Theology -> Drama
--   (SQL/Phase4/DemonHomura.sql:462)
-- UPDATE Buildings SET GreatPeopleRateModifier = 25, PrereqTech = 'TECH_THEOLOGY' WHERE Type = 'BUILDING_GARDEN';

-- Buildings.BUILDING_PAGODA: IsReligious 0 -> 1, FoodKept 0 -> 10, Happiness 2 -> 1
--   (SQL/Shared/MGMoods.sql:238, the Yuriji mood building; pins Happiness = 0 itself)
-- UPDATE Buildings SET IsReligious = 0, FoodKept = 0, Happiness = 2 WHERE Type = 'BUILDING_PAGODA';

-- Buildings.BUILDING_TEMPLE: Cost 100 -> 75 (ModCompatibility/Community Balance Patch/PMMMCBP.sql:10;
--   that file is a pre-existing failure on both engines, so this reference never executes)
-- UPDATE Buildings SET Cost = 100 WHERE Type = 'BUILDING_TEMPLE';

-- Buildings.BUILDING_COURTHOUSE: NeverCapture 0 -> 1, Cost 100 -> 75 (SQL/Shared/EntertainmentYield.sql:43)
-- UPDATE Buildings SET NeverCapture = 0, Cost = 100 WHERE Type = 'BUILDING_COURTHOUSE';

-- Buildings.BUILDING_STABLE: NeverCapture 0 -> 1 (SQL/Shared/EntertainmentYield.sql:271)
-- UPDATE Buildings SET NeverCapture = 0 WHERE Type = 'BUILDING_STABLE';

-- Buildings.BUILDING_CARAVANSARY: Cost 120 -> 90, TradeRouteLandGoldBonus 200 -> 0 (SQL/Mami/MamiBuilding.sql:64)
-- UPDATE Buildings SET Cost = 120, TradeRouteLandGoldBonus = 200 WHERE Type = 'BUILDING_CARAVANSARY';

-- Buildings.BUILDING_HARBOR: MinAreaSize 10 -> -1, TradeRouteSeaGoldBonus 100 -> 0
--   (SQL/Shared/EntertainmentYield.sql:195)
-- UPDATE Buildings SET MinAreaSize = 10, TradeRouteSeaGoldBonus = 100 WHERE Type = 'BUILDING_HARBOR';

-- Buildings.BUILDING_BROADCAST_TOWER: CultureRateModifier 33 -> 0 (SQL/Shared/EntertainmentYield.sql:55)
-- UPDATE Buildings SET CultureRateModifier = 33 WHERE Type = 'BUILDING_BROADCAST_TOWER';

-- Buildings.BUILDING_SPACESHIP_FACTORY: SpaceProductionModifier 50 -> 100 (SQL/Shared/EntertainmentYield.sql:142)
-- UPDATE Buildings SET SpaceProductionModifier = 50 WHERE Type = 'BUILDING_SPACESHIP_FACTORY';

-- Buildings.BUILDING_CRISTO_REDENTOR: Cost 1250 -> 1203, PolicyCostModifier -10 -> -15
--   (SQL/Shared/EntertainmentYield.sql:335)
-- UPDATE Buildings SET Cost = 1250, PolicyCostModifier = -10 WHERE Type = 'BUILDING_CRISTO_REDENTOR';

-- Buildings.BUILDING_FACTORY: FaithCost 0 -> 360, UnlockedByBelief 0 -> 1 (SQL/Shared/EntertainmentYield.sql:115)
-- UPDATE Buildings SET FaithCost = 0, UnlockedByBelief = 0 WHERE Type = 'BUILDING_FACTORY';

-- Buildings.BUILDING_LABORATORY: FaithCost 200 -> 500 (SQL/Shared/EntertainmentYield.sql:283)
-- UPDATE Buildings SET FaithCost = 200 WHERE Type = 'BUILDING_LABORATORY';

-- Buildings.BUILDING_PUBLIC_SCHOOL: FaithCost 200 -> 300 (ModCompatibility/Community Balance Patch/PMMMCBP.sql:5;
--   pre-existing failure on both engines, reference never executes)
-- UPDATE Buildings SET FaithCost = 200 WHERE Type = 'BUILDING_PUBLIC_SCHOOL';

-- Building_YieldChanges (Opera House): Yield 1 -> 2 (SQL/Sayaka/SayakaBuilding.sql:334)
-- UPDATE Building_YieldChanges SET Yield = 1 WHERE BuildingType = 'BUILDING_OPERA_HOUSE' AND YieldType = 'YIELD_CULTURE';

-- Policies.POLICY_FIVE_YEAR_PLAN: CultureCost 10 -> 0 (SQL/Shared/MGMoods.sql:680)
-- UPDATE Policies SET CultureCost = 10 WHERE Type = 'POLICY_FIVE_YEAR_PLAN';

-- Policies.POLICY_MILITARISM: CultureCost 10 -> 0, Level 2 -> 1 (SQL/Shared/MGMoods.sql:690)
-- UPDATE Policies SET CultureCost = 10, Level = 2 WHERE Type = 'POLICY_MILITARISM';

-- Policies.POLICY_VOLUNTEER_ARMY: CultureCost 10 -> 0, Level 2 -> 1, BaseFreeUnits 6 -> 3
--   (SQL/Shared/MGMoods.sql:670; on Lekmod there is no unit supply system, ProductionFreeUnits 99999)
-- UPDATE Policies SET CultureCost = 10, Level = 2, BaseFreeUnits = 6 WHERE Type = 'POLICY_VOLUNTEER_ARMY';

-- Missions.MISSION_SKIP: DisabledHelp text -> none (SQL/Phase4/Homura.sql:94)
-- UPDATE Missions SET DisabledHelp = 'TXT_KEY_MISSION_SKIP_DISABLED_HELP' WHERE Type = 'MISSION_SKIP';

-- UnitPromotions.PROMOTION_DRILL_1: HotKey none -> KB_X (SQL/Shared/MGDefines.sql:453)
-- UPDATE UnitPromotions SET HotKey = NULL WHERE Type = 'PROMOTION_DRILL_1';

-- UnitPromotions.PROMOTION_SHOCK_1: HotKey none -> KB_Z (ModCompatibility/Superpower Modpack/
--   PMMMSuperpower.sql:18; pre-existing failure on both engines, reference never executes)
-- UPDATE UnitPromotions SET HotKey = NULL WHERE Type = 'PROMOTION_SHOCK_1';

--------------------------------------------------------------------------------
-- Phase 6 Lekmod review, part 2 of 2: 15 multi-row diffs (the row SETS differ,
-- not just single values). No one-line override exists; if you flip any of
-- these to CP behaviour, write the DELETE/INSERT by hand against
-- build/sim_lek_port_cpcheck.db vs build/seed_lekmod35.db (raw data in
-- build/lek_copies.json). Default: KEEP Lekmod's rows.
--------------------------------------------------------------------------------

-- Diplomacy_Responses GENERIC: 319 rows on vanilla/CP -> 276 on Lekmod (SQL/Shared/Dialog.sql:108).
--   WFTW appends to and updates these sets; both engines resolve, counts differ.

-- Unit_Builds.UNIT_WORKER: 25 rows vanilla/CP -> 40 on Lekmod (worker builds more improvement types).
--   WFTW copies the whole set for its units; on Lekmod Magical Girls can build more things.

-- Units.Special = SPECIALUNIT_PEOPLE: 11 rows -> 15 (more units classified as people).

-- Unit_FreePromotions for UNIT_LANCER, UNIT_TRIREME, UNIT_COMPOSITE_BOWMAN: Lekmod grants
--   different free promotions; WFTW copies these sets for the Witch/Familiar/Incubator units.

-- Unit_AITypes for UNIT_LANCER and UNIT_WORKER; Units.Class = UNITCLASS_WORKER siblings.

-- BuildFeatures.BUILD_CHATEAU: Lekmod changed the terrain/feature validity rows.

-- Building_DomainFreeExperiences for ARMORY and MILITARY_ACADEMY: XP thresholds retuned.

-- Building_Flavors / Building_YieldChanges / Building_ResourceYieldChanges for BUILDING_PAGODA
--   and BUILDING_GRANARY: Lekmod retuned AI weights and yields; copies inherit them.

--------------------------------------------------------------------------------
-- End of Phase 6 Lekmod rebalance rulings. Default ruling: KEEP Lekmod values.
--------------------------------------------------------------------------------