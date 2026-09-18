--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Nagisa
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. Civilization rename (design 8: "Civ renamed Land des Kaeses, people Bebe's Cheese Commonwealth")
--    The Civilizations row keeps its TXT_KEY tags; only the English strings behind them change.
--------------------------------------------------------------------------------------------------------------

UPDATE Language_en_US
SET Text = 'Land des Kaeses'
WHERE Tag = 'TXT_KEY_CIV_NAGISA_DESC';

UPDATE Language_en_US
SET Text = 'Bebe''s Cheese Commonwealth'
WHERE Tag = 'TXT_KEY_CIV_NAGISA_SHORT_DESC';

UPDATE Language_en_US
SET Text = 'Bebe''s'
WHERE Tag = 'TXT_KEY_CIV_NAGISA_ADJECTIVE';


--------------------------------------------------------------------------------------------------------------
-- 2. UA "Cheese!" (design 8): Farms +1 Production, Pastures +1 Food.
--    Replaces the old Pasture +1 Culture row from SQL/Nagisa/NagisaLeaderAndTrait.sql.
--    The Golden Age Cattle/Sheep spread (Trait_PMMM_GoldenAgeResourceSpread) is unchanged.
--------------------------------------------------------------------------------------------------------------

DELETE FROM Trait_ImprovementYieldChanges
WHERE TraitType = 'TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE';

INSERT INTO Trait_ImprovementYieldChanges
			(TraitType,										ImprovementType,		YieldType,				Yield)
VALUES		('TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE',	'IMPROVEMENT_FARM',		'YIELD_PRODUCTION',		1),
			('TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE',	'IMPROVEMENT_PASTURE',	'YIELD_FOOD',			1);


--------------------------------------------------------------------------------------------------------------
-- 3a. Magical Dairy now replaces the Granary instead of the Caravansary (design 8).
--------------------------------------------------------------------------------------------------------------

DELETE FROM Civilization_BuildingClassOverrides
WHERE CivilizationType = 'CIVILIZATION_NAGISA'
AND BuildingType = 'BUILDING_PMMM_MAGICAL_DAIRY';

INSERT INTO Civilization_BuildingClassOverrides
			(CivilizationType,			BuildingClassType,			BuildingType)
VALUES		('CIVILIZATION_NAGISA',		'BUILDINGCLASS_GRANARY',	'BUILDING_PMMM_MAGICAL_DAIRY');


--------------------------------------------------------------------------------------------------------------
-- 3b. Re-base the Buildings row on the vanilla Granary: class, cost, tech, maintenance, free-start era and the
--     Granary's food trade routes. The two Caravansary-only trade-route columns are cleared.
--     Art (ArtDefineTag / IconAtlas / PortraitIndex) is deliberately left alone; it is cosmetic.
--------------------------------------------------------------------------------------------------------------

UPDATE Buildings
SET BuildingClass					= 'BUILDINGCLASS_GRANARY',
	Cost							= (SELECT Cost FROM Buildings WHERE Type = 'BUILDING_GRANARY'),
	GoldMaintenance					= (SELECT GoldMaintenance FROM Buildings WHERE Type = 'BUILDING_GRANARY'),
	PrereqTech						= (SELECT PrereqTech FROM Buildings WHERE Type = 'BUILDING_GRANARY'),
	FreeStartEra					= (SELECT FreeStartEra FROM Buildings WHERE Type = 'BUILDING_GRANARY'),
	AllowsFoodTradeRoutes			= (SELECT AllowsFoodTradeRoutes FROM Buildings WHERE Type = 'BUILDING_GRANARY'),
	TradeRouteLandDistanceModifier	= 0,
	TradeRouteLandGoldBonus			= 0
WHERE Type = 'BUILDING_PMMM_MAGICAL_DAIRY';


--------------------------------------------------------------------------------------------------------------
-- 3c. Flavors: match the vanilla Granary (they had been copied from the Caravansary).
--------------------------------------------------------------------------------------------------------------

DELETE FROM Building_Flavors
WHERE BuildingType = 'BUILDING_PMMM_MAGICAL_DAIRY';

INSERT INTO Building_Flavors
			(BuildingType,						FlavorType,	Flavor)
SELECT		'BUILDING_PMMM_MAGICAL_DAIRY',		FlavorType,	Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_GRANARY';


--------------------------------------------------------------------------------------------------------------
-- 3d. Keep the Granary's own effects: its flat Food and its Wheat/Bananas/Deer Food.
--------------------------------------------------------------------------------------------------------------

DELETE FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_PMMM_MAGICAL_DAIRY';

INSERT INTO Building_YieldChanges
			(BuildingType,						YieldType,	Yield)
SELECT		'BUILDING_PMMM_MAGICAL_DAIRY',		YieldType,	Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_GRANARY';


--------------------------------------------------------------------------------------------------------------
-- 3e. The unique part: every Cattle and Sheep Resource worked by the City gives +1 Food, +1 Gold, +1 Faith and
--     +1 Production. Same mechanism as the Granary's own resource Food, so it shows on the tile.
--------------------------------------------------------------------------------------------------------------

DELETE FROM Building_ResourceYieldChanges
WHERE BuildingType = 'BUILDING_PMMM_MAGICAL_DAIRY';

INSERT INTO Building_ResourceYieldChanges
			(BuildingType,						ResourceType,	YieldType,	Yield)
SELECT		'BUILDING_PMMM_MAGICAL_DAIRY',		ResourceType,	YieldType,	Yield
FROM Building_ResourceYieldChanges WHERE BuildingType = 'BUILDING_GRANARY';

INSERT INTO Building_ResourceYieldChanges
			(BuildingType,						ResourceType,		YieldType,			Yield)
VALUES		('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_COW',		'YIELD_FOOD',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_COW',		'YIELD_GOLD',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_COW',		'YIELD_FAITH',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_COW',		'YIELD_PRODUCTION',	1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_SHEEP',	'YIELD_FOOD',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_SHEEP',	'YIELD_GOLD',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_SHEEP',	'YIELD_FAITH',		1),
			('BUILDING_PMMM_MAGICAL_DAIRY',		'RESOURCE_SHEEP',	'YIELD_PRODUCTION',	1);


--------------------------------------------------------------------------------------------------------------
-- 3f. Retire the Lua-driven stacking dummy. The trade-route and Golden Age bonuses it carried are gone, so the
--     dummy building and its building class are dropped (the driving script is retired separately).
--------------------------------------------------------------------------------------------------------------

DELETE FROM Buildings
WHERE Type = 'BUILDING_PMMM_MAGICAL_DAIRY_DUMMY';

DELETE FROM BuildingClasses
WHERE Type = 'BUILDINGCLASS_PMMM_MAGICAL_DAIRY_DUMMY';


--------------------------------------------------------------------------------------------------------------
-- 4. Bubble Bomber (design 8): half damage on bombing runs (interception), 25% splash damage around the target.
--    The existing +50% vs. Cities and Fortified Units and the within-2-tiles bonus promotion are kept.
--------------------------------------------------------------------------------------------------------------

UPDATE UnitPromotions
SET InterceptionDefenseDamageModifier	= -50,
	SplashDamage						= 25
WHERE Type = 'PROMOTION_PMMM_BUBBLE_BOMBER';


--------------------------------------------------------------------------------------------------------------
-- 5a. Text: the UA.
--------------------------------------------------------------------------------------------------------------

UPDATE Language_en_US
SET Text = '+1 [ICON_PRODUCTION] Production from Farms and +1 [ICON_FOOD] Food from Pastures. During a [ICON_GOLDEN_AGE] Golden Age, [ICON_RES_COW] Cattle and [ICON_RES_SHEEP] Sheep Resources may spread to new tiles (if the tiles are not already improved).'
WHERE Tag = 'TXT_KEY_TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE';


--------------------------------------------------------------------------------------------------------------
-- 5b. Text: the Magical Dairy. (The _CBP variant is kept in step with the main help tag.)
--------------------------------------------------------------------------------------------------------------

UPDATE Language_en_US
SET Text = 'Each source of [ICON_RES_WHEAT] Wheat [ICON_RES_BANANA] Bananas and [ICON_RES_DEER] Deer worked by this City produce +1 [ICON_FOOD] Food.[NEWLINE][NEWLINE]Each source of [ICON_RES_COW] Cattle and [ICON_RES_SHEEP] Sheep worked by this City produces +1 [ICON_FOOD] Food, +1 [ICON_GOLD] Gold, +1 [ICON_PEACE] Faith and +1 [ICON_PRODUCTION] Production.[NEWLINE][NEWLINE]Allows [ICON_FOOD] Food to be moved from this city along trade routes inside your civilization.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MAGICAL_DAIRY_HELP';

UPDATE Language_en_US
SET Text = 'Each source of [ICON_RES_WHEAT] Wheat [ICON_RES_BANANA] Bananas and [ICON_RES_DEER] Deer worked by this City produce +1 [ICON_FOOD] Food.[NEWLINE][NEWLINE]Each source of [ICON_RES_COW] Cattle and [ICON_RES_SHEEP] Sheep worked by this City produces +1 [ICON_FOOD] Food, +1 [ICON_GOLD] Gold, +1 [ICON_PEACE] Faith and +1 [ICON_PRODUCTION] Production.[NEWLINE][NEWLINE]Allows [ICON_FOOD] Food to be moved from this city along trade routes inside your civilization.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MAGICAL_DAIRY_HELP_CBP';

UPDATE Language_en_US
SET Text = 'The Magical Dairy is the unique building for Bebe''s Cheese Commonwealth, replacing the Granary. On top of everything a Granary does, every [ICON_RES_COW] Cattle and [ICON_RES_SHEEP] Sheep Resource worked by the City produces +1 [ICON_FOOD] Food, +1 [ICON_GOLD] Gold, +1 [ICON_PEACE] Faith and +1 [ICON_PRODUCTION] Production. A single herd is worth four yields at once, and it costs no more than an ordinary Granary.[NEWLINE][NEWLINE]Settle near Cattle and Sheep, pasture them early, and let the cheese pay for everything else.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MAGICAL_DAIRY_STRATEGY';

UPDATE Language_en_US
SET Text = 'Bebe''s appetite is famous, and her Commonwealth was built to feed it. Where other nations store their grain and forget about it, the Magical Dairy turns a city''s herds into cheese, and cheese into everything else: supper, coin, devotion, and the strength to work another day.[NEWLINE][NEWLINE]Every [ICON_RES_COW] Cattle and [ICON_RES_SHEEP] Sheep Resource worked by the City yields +1 [ICON_FOOD] Food, +1 [ICON_GOLD] Gold, +1 [ICON_PEACE] Faith and +1 [ICON_PRODUCTION] Production, on top of the [ICON_FOOD] Food a Granary already provides.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MAGICAL_DAIRY_TEXT';


--------------------------------------------------------------------------------------------------------------
-- 5c. Text: the Bubble Bomber and its promotion.
--------------------------------------------------------------------------------------------------------------

UPDATE Language_en_US
SET Text = 'Unique replacement for the Great War Bomber, which only Nagisa Momoe can train. +50% [ICON_RANGE_STRENGTH] Ranged Strength vs. Cities and Fortified Units, and +33% [ICON_RANGE_STRENGTH] Ranged Strength when a hostile unit is within 2 tiles. Its attacks deal 25% splash damage to enemy Units and Cities around the target, and it takes 50% less damage when intercepted.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_BUBBLE_BOMBER_HELP';

UPDATE Language_en_US
SET Text = 'The Bubble Bomber is the Unique Unit for Bebe''s Cheese Commonwealth, replacing the Great War Bomber. The bubbles they drop are highly destructive, and as such, it deals an additional 50% damage against Cities and Fortified Units. The bubbles also burst outward: every enemy Unit and City around the target takes 25% splash damage, so one run is worth far more against a stacked front or a defended City. The same bubbles cushion the girls on the way home, so the Bomber takes 50% less damage when it is intercepted. The Cheese Commonwealth is a relatively peaceful group of girls, but they are fierce when defending their dairies -- if there is an enemy Unit within 2 tiles of the City in which the Bubble Bomber is located, it will gain an additional 33% [ICON_RANGE_STRENGTH] Ranged Strength!'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_BUBBLE_BOMBER_STRATEGY';

UPDATE Language_en_US
SET Text = 'Trumpet Bubbles are shockingly powerful weapons. As such, this unit gains [COLOR_POSITIVE_TEXT]+50% [ICON_RANGE_STRENGTH] Ranged Strength[ENDCOLOR] vs. [COLOR_POSITIVE_TEXT]Cities and Fortified Units[ENDCOLOR], and its attacks deal [COLOR_POSITIVE_TEXT]25% splash damage[ENDCOLOR] to enemy Units and Cities around the target. The bubbles cushion the girls on the way home, so the unit takes [COLOR_POSITIVE_TEXT]50% less damage[ENDCOLOR] when it is intercepted. The girls are much more willing to fight invaders than to go on conquering sprees, so they also gain [COLOR_POSITIVE_TEXT]+33% [ICON_RANGE_STRENGTH] Ranged Strength[ENDCOLOR] when an enemy Unit is within 2 tiles.'
WHERE Tag = 'TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER_HELP';


--------------------------------------------------------------------------------------------------------------
-- 6. Nagisa Momoe: Magic Cake Dish (design section 15, ruling 7)
--    No damage. Every friendly Unit on her tile or next to it heals 25% of its maximum hit points and fights at
--    +10% Combat Strength for 3 turns. Cooldown 5 turns (the ruling gives none; chosen here), no Soul Gem cost.
--    Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityNagisa.lua
--
--    No target: like MISSION_PMMM_BALDAMENTE_FORTISSIMO the row carries neither PMMMMissionRange nor
--    PMMMTargetType, so the button fires at once; the radius of 1 lives in the handler.
--    The buff is a timed promotion with CombatPercent 10, removed by the framework after 3 of her turns.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_MAGIC_CAKE_DISH';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas)
SELECT		('MISSION_PMMM_MAGIC_CAKE_DISH'), ('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH'), ('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH_HELP'), ('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH_DISABLED'), EntityEventType, Time, 200, 1, 16, ('UNIT_ACTION_ATLAS')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_MAGIC_CAKE';

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, CombatPercent)
VALUES		('PROMOTION_PMMM_MAGIC_CAKE', 'TXT_KEY_PROMOTION_PMMM_MAGIC_CAKE', 'TXT_KEY_PROMOTION_PMMM_MAGIC_CAKE_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_MAGIC_CAKE', 10);

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_MAGIC_CAKE_DISH'
WHERE Type = 'TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH', 'Magic Cake Dish'),
	('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH_HELP', 'Nagisa shares out a magic cake. Every friendly Unit on her tile or an adjacent tile, herself included, immediately recovers 25% of its maximum Hit Points and gains +10% [ICON_STRENGTH] Combat Strength for 3 turns.[NEWLINE][NEWLINE]Deals no damage, needs no target, and costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Cooldown 5 turns.'),
	('TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH_DISABLED', 'Magic Cake Dish is recovering. Nagisa must also have movement left to serve it.'),
	('TXT_KEY_PROMOTION_PMMM_MAGIC_CAKE', 'Magic Cake'),
	('TXT_KEY_PROMOTION_PMMM_MAGIC_CAKE_HELP', '+10% [ICON_STRENGTH] Combat Strength for 3 turns, after sharing Nagisa''s Magic Cake Dish.');
