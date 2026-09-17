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
