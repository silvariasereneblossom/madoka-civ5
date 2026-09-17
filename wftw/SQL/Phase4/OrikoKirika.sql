--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for OrikoKirika
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- Section 10: "The intrigue mechanic becomes double spying rate; all units start with Visibility."
-- Every table and column below was verified against build/sim_cp_wftw.db (CP 5.4.6 schema) before writing.
-- The game ships SQLite 3.7.17: no WITH, no window functions, and booleans are written as 1/0.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. Infinitely Finite: replace the leader-Magical-Girl intrigue mechanic with an espionage bonus.
--
--    CP 5.4's espionage has no literal "double spy rate" column. Spy rank is the multiplier on how fast a spy
--    completes any operation, so one extra starting rank is the closest data-side equivalent of doubling the
--    rate; SpyMoveRateModifier = 100 doubles how fast spies travel to their target city. Both columns exist on
--    Traits in the built DB (SpyOffensiveStrengthModifier exists too, but the spec assigns it no value, so it
--    is deliberately left at 0).
--
--    LeaderMGIntrigueTurns = 0 switches off the old "find Intrigue every 5 turns" tick that this replaces.
--    RevealCivLocations and the ExtraLeaderMG* columns are intentionally NOT touched: the spec keeps both.
--------------------------------------------------------------------------------------------------------------
UPDATE Traits
SET		SpyExtraRankBonus		= 1,
		SpyMoveRateModifier		= 100,
		LeaderMGIntrigueTurns	= 0
WHERE Type = 'TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH';


--------------------------------------------------------------------------------------------------------------
-- 2. All units start with Visibility.
--    PROMOTION_SENTRY (VisibilityChange = 1) is the vanilla "+1 sight" promotion and exists in the built DB.
--    DELETE first so re-running the file cannot duplicate the row.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Trait_FreePromotions
WHERE TraitType = 'TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH' AND PromotionType = 'PROMOTION_SENTRY';

INSERT INTO Trait_FreePromotions
			(TraitType,								PromotionType)
VALUES		('TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH',	'PROMOTION_SENTRY');


--------------------------------------------------------------------------------------------------------------
-- 3. Farsight Oracle late-game scaling.
--    Both tables were verified to exist with these exact names in the built DB:
--      Improvement_AdjacentResourceYieldChanges (ImprovementType, ResourceType, YieldType, Yield)
--      Improvement_YieldPerEra                  (ImprovementType, YieldType, Yield)
--    AdjacentResourceYieldChanges is keyed per individual resource, not per resource class, so the Luxury
--    bonus is expanded over every Luxury in the database (Resources.ResourceUsage = 2). Doing it as an
--    INSERT..SELECT means mod-added Luxuries loaded before this file are picked up automatically.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Improvement_AdjacentResourceYieldChanges
WHERE ImprovementType = 'IMPROVEMENT_PMMM_FARSIGHT_ORACLE';

INSERT INTO Improvement_AdjacentResourceYieldChanges
			(ImprovementType,							ResourceType,	YieldType,			Yield)
SELECT		('IMPROVEMENT_PMMM_FARSIGHT_ORACLE'),		Type,			('YIELD_SCIENCE'),	1
FROM Resources WHERE (ResourceUsage = 2);

DELETE FROM Improvement_YieldPerEra
WHERE ImprovementType = 'IMPROVEMENT_PMMM_FARSIGHT_ORACLE';

INSERT INTO Improvement_YieldPerEra
			(ImprovementType,						YieldType,		Yield)
VALUES		('IMPROVEMENT_PMMM_FARSIGHT_ORACLE',	'YIELD_CULTURE',1);


--------------------------------------------------------------------------------------------------------------
-- 4. Text.
--    Trait help now states the real espionage effect and the free Sentry instead of the removed intrigue tick.
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = 'Start with the locations of all Civilizations revealed (but they still must be physically met). All units are built with the Sentry Promotion, granting +1 Sight. [ICON_SPY] Spies start one Rank higher and travel to their target City twice as fast. Receive an extra Leader Magical Girl with a bonus Promotion.'
WHERE Tag = 'TXT_KEY_TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH';


--------------------------------------------------------------------------------------------------------------
--    Farsight Oracle help: the two new scaling yields plus the build restrictions that were never spelled out.
--    Restrictions are facts of the existing Improvements row, verified in the built DB:
--      Improvements.BuildableOnResources = 0  -> cannot be placed on a tile that holds a Resource
--      Improvement_ValidTerrains          -> TERRAIN_GRASS / PLAINS / DESERT / TUNDRA / SNOW only
--      Improvements.AdjacentLuxury = 1, NoTwoAdjacent = 1
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = '+2 [ICON_PEACE] Faith and +1 [ICON_CULTURE] Culture. Additional +1 [ICON_PEACE] Faith and +2 [ICON_CULTURE] Culture after discovering Radio.[NEWLINE][NEWLINE]+1 [ICON_RESEARCH] Science for each adjacent Luxury Resource, and a further +1 [ICON_CULTURE] Culture for each Era that has passed.[NEWLINE][NEWLINE]Friendly units stationed on this tile gain Farsight, a Promotion which allows them to have the equivalent sight of an Air Unit and Indirect Fire.[NEWLINE][NEWLINE]Must be built adjacent to a Luxury Resource, and no two may be adjacent to each other. Cannot be built on a tile that contains a Resource, and may only be built on Grassland, Plains, Desert, Tundra or Snow.'
WHERE Tag = 'TXT_KEY_IMPROVEMENT_PMMM_FARSIGHT_ORACLE_HELP';

UPDATE Language_en_US
SET Text = '+1 [ICON_RESEARCH] Science for each adjacent Luxury Resource, and +1 [ICON_CULTURE] Culture for each Era that has passed.[NEWLINE][NEWLINE]Friendly units stationed on this tile gain Farsight, a Promotion which allows them to have the equivalent sight of an Air Unit and Indirect Fire.[NEWLINE][NEWLINE]Must be built adjacent to a Luxury Resource, and no two may be adjacent to each other. Cannot be built on a tile that contains a Resource, and may only be built on Grassland, Plains, Desert, Tundra or Snow.'
WHERE Tag = 'TXT_KEY_BUILD_PMMM_FARSIGHT_ORACLE_HELP';
