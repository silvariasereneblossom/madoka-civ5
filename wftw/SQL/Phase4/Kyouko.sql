--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Kyouko
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- UA "I Live Only For Myself" (TRAIT_GROWTH_SPEED_FROM_RELIGION, CIVILIZATION_KYOUKO).
-- Data only. The game's SQLite is 3.7.17: no WITH, no window functions, no bare DEFAULT true/false.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. Unhappiness from population -25%.
--    PopulationUnhappinessModifier is a real CP trait column (percentage, negative = less unhappiness).
--------------------------------------------------------------------------------------------------------------
UPDATE Traits
SET PopulationUnhappinessModifier = -25
WHERE Type = 'TRAIT_GROWTH_SPEED_FROM_RELIGION';


--------------------------------------------------------------------------------------------------------------
-- 2. Free pantheon at once, at no faith cost. StartsWithPantheon is a real CP trait column.
--
--    [Lua PENDING] The other half of the spec -- "can never found a religion" -- has no data column.
--    It needs a Lua block that refuses religion founding for CIVILIZATION_KYOUKO (a PlayerCanFoundReligion
--    style hook, or zeroing her Great Prophet rate). Nothing in this file stops her founding one today,
--    so the trait text below does not claim the restriction yet.
--------------------------------------------------------------------------------------------------------------
UPDATE Traits
SET StartsWithPantheon = 1
WHERE Type = 'TRAIT_GROWTH_SPEED_FROM_RELIGION';


--------------------------------------------------------------------------------------------------------------
-- 3a. Shrines give +1 Food under this trait.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Trait_BuildingClassYieldChanges
WHERE TraitType = 'TRAIT_GROWTH_SPEED_FROM_RELIGION'
  AND BuildingClassType = 'BUILDINGCLASS_SHRINE'
  AND YieldType = 'YIELD_FOOD';

INSERT INTO Trait_BuildingClassYieldChanges (TraitType, BuildingClassType, YieldType, YieldChange)
VALUES ('TRAIT_GROWTH_SPEED_FROM_RELIGION', 'BUILDINGCLASS_SHRINE', 'YIELD_FOOD', 1);


--------------------------------------------------------------------------------------------------------------
-- 3b. The Sakura Church gives +2 Food. Its inherited Temple +2 Faith row is left alone.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_PMMM_SAKURA_CHURCH'
  AND YieldType = 'YIELD_FOOD';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
VALUES ('BUILDING_PMMM_SAKURA_CHURCH', 'YIELD_FOOD', 2);


--------------------------------------------------------------------------------------------------------------
-- 4. Retire the hidden FoodKept dummy: the Church now keeps a flat 15% of Food on growth.
--    The old scheme was a 1%-per-follower ramp to 20%, driven from Lua by stacking up to 20 copies of
--    BUILDING_PMMM_SAKURA_CHURCH_DUMMY (FoodKept 1, NoLimit 1). The driving Lua is retired separately
--    (wftw/Lua/Gameplay/Buildings/PMMMKyoukoBuilding.lua); this file only removes the rows.
--    Children first, then the building, then its building class.
--------------------------------------------------------------------------------------------------------------
UPDATE Buildings
SET FoodKept = 15
WHERE Type = 'BUILDING_PMMM_SAKURA_CHURCH';

DELETE FROM Building_BuildingClassYieldChanges WHERE BuildingType = 'BUILDING_PMMM_SAKURA_CHURCH_DUMMY';
DELETE FROM Building_YieldChanges              WHERE BuildingType = 'BUILDING_PMMM_SAKURA_CHURCH_DUMMY';
DELETE FROM Buildings                          WHERE Type = 'BUILDING_PMMM_SAKURA_CHURCH_DUMMY';
DELETE FROM BuildingClasses                    WHERE Type = 'BUILDINGCLASS_PMMM_SAKURA_CHURCH_DUMMY';


--------------------------------------------------------------------------------------------------------------
-- 5. Chain Lancer loses the mounted rough-terrain penalty.
--    It inherited PROMOTION_NO_DEFENSIVE_BONUSES from the vanilla Lancer's kit as a free promotion
--    (Unit_FreePromotions). Dropped for the Chain Lancer only; UNIT_LANCER keeps its own row.
--
--    [Lua PENDING] "Stolen Food becomes a Chain Lancer unique": the handler is still trait-wide and fires
--    for all Melee/Mounted/Gunpowder units (wftw/Lua/Gameplay/Traits/PMMMKyoukoTrait.lua). Until that moves
--    to the unit, the trait text below still advertises the trait-wide version.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Unit_FreePromotions
WHERE UnitType = 'UNIT_PMMM_CHAIN_LANCER'
  AND PromotionType = 'PROMOTION_NO_DEFENSIVE_BONUSES';


--------------------------------------------------------------------------------------------------------------
-- 6. Cap the runaway population Mood bonus. The modifier is Value (1) x PopulationMoodBonus (2) x total
--    population and had no MaxValue, so a large empire pinned every girl's Mood at the ceiling.
--    150 caps the contribution at roughly 75 citizens.
--------------------------------------------------------------------------------------------------------------
UPDATE MG_MoodModifiers
SET MaxValue = 150
WHERE Type = 'MGMOODMOD_TRAIT_POPULATION';


--------------------------------------------------------------------------------------------------------------
-- 7. Text.
--
--    [Hidden policy + Lua PENDING, NOT IMPLEMENTED HERE] "+2 Happiness per owned luxury, -1 per imported
--    luxury". ExtraHappinessPerLuxury exists on Policies, not on Traits, so it needs a hidden policy granted
--    to Kyouko (at 2) plus a per-turn Lua count of resources available but not owned, applied through a dummy,
--    for the -1 half. Neither is in this file, so the trait text below deliberately says nothing about
--    luxuries. Redo this text when that lands, together with the "cannot found a religion" line from block 2
--    and the Chain Lancer Stolen Food move from block 5.
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = 'I Live Only For Myself'
WHERE Tag = 'TXT_KEY_TRAIT_GROWTH_SPEED_FROM_RELIGION_SHORT';

UPDATE Language_en_US
SET Text = 'Melee, Mounted, and Gunpowder Units earn Stolen Food from plundering Trade Routes and pillaging Farms or Plantations.[NEWLINE]Founds a Pantheon for free at the start of the game, without spending [ICON_PEACE] Faith.[NEWLINE]Unhappiness from [ICON_CITIZEN] Population reduced by 25%.[NEWLINE]Shrines provide +1 [ICON_FOOD] Food.[NEWLINE]+2 [ICON_PMMM_MOOD] Mood for every [ICON_CITIZEN] Population in your Cities, up to a maximum of +150.'
WHERE Tag = 'TXT_KEY_TRAIT_GROWTH_SPEED_FROM_RELIGION';

UPDATE Language_en_US
SET Text = 'Religious pressure exerted by this City increased by 20%.[NEWLINE][NEWLINE]+2 [ICON_FOOD] Food.[NEWLINE][NEWLINE]15% of the [ICON_FOOD] Food is kept when a new Citizen is born.[NEWLINE][NEWLINE]City must have a Shrine.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_SAKURA_CHURCH_HELP';

UPDATE Language_en_US
SET Text = 'The Sakura Church is the unique building for Kazamino, replacing the Temple. It increases the religious pressure of the city, allowing nearby cities to be converted to your Religion more quickly. It also feeds the city that builds it: +2 [ICON_FOOD] Food every turn, and a permanent Aqueduct-like effect that keeps 15% of the [ICON_FOOD] Food when a new Citizen is born.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_SAKURA_CHURCH_STRATEGY';


--------------------------------------------------------------------------------------------------------------
-- 8. UMG "Kugatachi": the Leader Magical Girl ability (data half).
--    A spear thrust in a line -- the target tile plus the two tiles directly beyond it along the same hex
--    direction, each struck at 200% of her Combat Strength. Range 2, cooldown 4, no Soul Gem cost.
--    Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityKyouko.lua. It needs no promotion of its own,
--    so this block is the mission row, the trait link and the text.
--    Design: docs/design/phase4-design-v1.md section 6 and the section 12 default for Kugatachi.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_KUGATACHI';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_KUGATACHI'), ('TXT_KEY_MISSION_PMMM_KUGATACHI'), ('TXT_KEY_MISSION_PMMM_KUGATACHI_HELP'), ('TXT_KEY_MISSION_PMMM_KUGATACHI_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_KUGATACHI'
WHERE Type = 'TRAIT_GROWTH_SPEED_FROM_RELIGION';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_KUGATACHI', 'Kugatachi'),
	('TXT_KEY_MISSION_PMMM_KUGATACHI_HELP', 'Kyouko drives her spear straight through the enemy line. The target tile and the two tiles directly beyond it, along the same direction, are each struck for damage equal to an attack at 200% of her [ICON_STRENGTH] Combat Strength. An enemy City in the line is damaged as well.[NEWLINE][NEWLINE]The thrust only carries on past the target when the target lies on a straight line of tiles from her. A target reached only by turning a corner, such as the diagonal tiles at Range 2, is struck on its own.[NEWLINE][NEWLINE]Costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Range 2. Cooldown 4 turns.'),
	('TXT_KEY_MISSION_PMMM_KUGATACHI_DISABLED', 'Kugatachi is recovering, or there is no enemy in range.');


--------------------------------------------------------------------------------------------------------------
-- 9. Lua halves of blocks 2, 5 and 7 (landed 2026-09-18). The Lua lives in
--    wftw/Lua/Gameplay/Traits/PMMMKyoukoTrait.lua, loaded by PMMMTraitBootstrapper.lua whenever a player's trait
--    has MaxStolenFood > 0 (TRAIT_GROWTH_SPEED_FROM_RELIGION has 100).
--
--    Block 2, "can never found a religion": GameEvents.PlayerCanFoundReligion returns false for her. The DLL asks
--    it from CvUnit::CanFoundReligion, the only gate both the human and the AI founding paths go through.
--
--    Block 7, luxuries. ExtraHappinessPerLuxury is a Policies column only, so she is given this hidden policy
--    (free, so it costs no culture and does not raise the next policy's cost) on her first turn. The DLL adds it
--    to EVERY luxury that currently gives happiness, imported ones included (CvPlayer::GetHappinessFromResources).
--    The per-turn Lua therefore counts luxuries she has only through trade deals with other civilizations
--    (GetResourceImport minus GetResourceFromMinors > 0, and none left once those deal copies are taken away)
--    and gives the capital 3 copies of the dummy below for each: -2 to cancel the policy's bonus on that luxury
--    and -1 for the ruling itself. Owned luxury: 4 + 2 = 6. Deal-only luxury: 4 + 2 - 3 = 3.
--    Reading: "traded" = imported through deals (section 12); luxuries from city-states count as her own.
--    UnmoddedHappiness is used rather than Happiness or Unhappiness: it is a flat sum into the city's local
--    happiness in CP (CvCity::GetLocalHappiness), accepts negative values, and no policy or trait modifier
--    scales it, so -1 per copy is exactly -1.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Policies WHERE Type = 'POLICY_PMMM_KYOUKO_LUXURIES';

INSERT INTO Policies (Type, Description, Help, ExtraHappinessPerLuxury, IsDummy)
VALUES ('POLICY_PMMM_KYOUKO_LUXURIES', 'TXT_KEY_POLICY_PMMM_KYOUKO_LUXURIES', 'TXT_KEY_POLICY_PMMM_KYOUKO_LUXURIES_HELP', 2, 1);

DELETE FROM Buildings       WHERE Type = 'BUILDING_PMMM_KYOUKO_TRADED_LUXURY';
DELETE FROM BuildingClasses WHERE Type = 'BUILDINGCLASS_PMMM_KYOUKO_TRADED_LUXURY';

INSERT INTO BuildingClasses (Type, Description, DefaultBuilding, NoLimit)
VALUES ('BUILDINGCLASS_PMMM_KYOUKO_TRADED_LUXURY', 'TXT_KEY_BUILDING_PMMM_KYOUKO_TRADED_LUXURY', 'BUILDING_PMMM_KYOUKO_TRADED_LUXURY', 1);

INSERT INTO Buildings
			(Type, BuildingClass, Description, Help, Cost, FaithCost, GreatWorkCount, PrereqTech,
			NeverCapture, NukeImmune, ConquestProb, IsDummy, ShowInPedia, UnmoddedHappiness,
			IconAtlas, PortraitIndex)
VALUES		('BUILDING_PMMM_KYOUKO_TRADED_LUXURY', 'BUILDINGCLASS_PMMM_KYOUKO_TRADED_LUXURY',
			'TXT_KEY_BUILDING_PMMM_KYOUKO_TRADED_LUXURY', 'TXT_KEY_BUILDING_PMMM_KYOUKO_TRADED_LUXURY_HELP', -1, -1, -1, NULL,
			1, 1, 0, 1, 0, -1,
			'CIV_COLOR_ATLAS_KYOUKO', 3);


--------------------------------------------------------------------------------------------------------------
-- 10. Text for blocks 2, 5 and 7 now that their Lua has landed. Numbers are the live data:
--     luxury Happiness 4 (Resources.Happiness), policy +2, deal-only -1 net; Stolen Food 20 per pillaged
--     Farm / Plantation / Fishing Boats / Terrace Farm (Trait_PMMM_StolenFoodFromImprovement), 50 per plundered
--     Trade Route (Traits.CaravanPillageStolenFood), 100 carried at most (Traits.MaxStolenFood), one theft per
--     tile every 30 turns (Defines.STOLEN_FOOD_SAME_TILE_TURNS_BETWEEN).
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = 'Each Luxury resource you have gives +2 [ICON_HAPPINESS_1] Happiness on top of its usual 4. A Luxury you have only through a trade deal with another civilization instead gives 1 less than usual (3). Luxuries from City-States count as your own.[NEWLINE]Founds a Pantheon for free at the start of the game, without spending [ICON_PEACE] Faith, but can never found a Religion.[NEWLINE]Unhappiness from [ICON_CITIZEN] Population reduced by 25%.[NEWLINE]Shrines provide +1 [ICON_FOOD] Food.[NEWLINE]+2 [ICON_PMMM_MOOD] Mood for every [ICON_CITIZEN] Population in your Cities, up to a maximum of +150.'
WHERE Tag = 'TXT_KEY_TRAIT_GROWTH_SPEED_FROM_RELIGION';

UPDATE Language_en_US
SET Text = 'Unique replacement for the Lancer, which only Kyouko Sakura can train. Does not require [ICON_RES_HORSE] Horses. May be bought with [ICON_PEACE] Faith, regardless of beliefs. +50% bonus to Flank Attacks. Unlike other mounted units, keeps its defensive terrain bonuses.[NEWLINE][NEWLINE]Steals [ICON_FOOD] Food: +20 for pillaging a Farm, Terrace Farm, Plantation or Fishing Boats (each tile only once every 30 turns) and +50 for plundering a Trade Route, carrying up to 100. Stolen Food can be delivered to a City you own as [ICON_FOOD] Food, or eaten to heal 1 HP per 2 Food. Each costs 1 [ICON_MOVES] Movement.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_CHAIN_LANCER_HELP';

UPDATE Language_en_US
SET Text = 'The Chain Lancer is the Unique Unit for Kazamino, replacing the Lancer. It does not require [ICON_RES_HORSE] Horses, and may be purchased with [ICON_PEACE] Faith even without any specific beliefs. It additionally gains a 50% bonus to Flank Attacks, and unlike other mounted units it keeps its defensive terrain bonuses. It is the only unit that steals Food: pillaging a Farm, Terrace Farm, Plantation or Fishing Boats nets 20 [ICON_FOOD] Food (each tile once every 30 turns), plundering a Trade Route nets 50, and it can carry up to 100. Bring the haul home to feed a City, or eat it in the field to heal 1 HP for every 2 Food. The combination of these abilities should allow you to easily swarm your opponents with Chain Lancers, allowing for fast, effective attacks...and pillaging.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_CHAIN_LANCER_STRATEGY';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_POLICY_PMMM_KYOUKO_LUXURIES', 'I Live Only For Myself'),
	('TXT_KEY_POLICY_PMMM_KYOUKO_LUXURIES_HELP', '+2 [ICON_HAPPINESS_1] Happiness from each Luxury resource.'),
	('TXT_KEY_BUILDING_PMMM_KYOUKO_TRADED_LUXURY', 'Borrowed Luxuries'),
	('TXT_KEY_BUILDING_PMMM_KYOUKO_TRADED_LUXURY_HELP', '-1 [ICON_HAPPINESS_1] Happiness. Your Capital holds 3 of these for each Luxury you have only through a trade deal: 2 cancel the bonus from I Live Only For Myself on that Luxury, and 1 is the penalty itself.');
