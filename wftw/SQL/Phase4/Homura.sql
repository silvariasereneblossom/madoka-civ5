--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Homura
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- Homura Akemi: Concentrated Missile Fire
-- One shot mechanically equivalent to a Rocket Artillery attack, its bonus against cities included.
-- Range 2, cooldown 4, no Soul Gem cost, no promotion of its own, so this block is the mission row,
-- the trait link and the text.
-- Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityHomura.lua
--
-- What the multiplier means in play. The shot is not a flat 60 damage-strength hit: a flat 60 would kill
-- anything alive before the Industrial era and mean nothing after it. It is a virtual attack at
--
--     Rocket Artillery Ranged Combat Strength (60) / strength of the era's best ordinary land unit
--
-- clamped to between 1.0 and 2.5, and tripled against a city by Rocket Artillery's own PROMOTION_CITY_SIEGE
-- (CityAttack 200, read from the database by the handler, not written down in it). Unclamped that ratio is
-- 5.45 in the Ancient era (60 against the Spearman's 11), 4.29 Classical, 2.86 Medieval, 2.50 Renaissance,
-- 1.76 Industrial, 0.86 Modern, 0.92 Postmodern and 0.60 Future; the clamp holds the first four eras at
-- 2.50 and the last three at 1.00. Because a Magical Girl's own strength is MAGICAL_GIRL_STRENGTH_PERCENT
-- of that same best unit, the two era terms cancel and the shell lands at a near-constant strength for the
-- whole game -- at the current 70% define, 0.7 x 60 = an effective 42 in the unclamped middle eras, and
-- exactly Rocket Artillery's 60 once ruling 1 in section 11 raises the define to 100. That is the point of
-- the ratio: a constant threat, not an ability that grows into a one-shot.
--
-- The rest of Homura's kit in section 3 -- the reworked Time Stop, Thief of Time and the Dimensional Armory --
-- follows further down this file.
--
-- Cooldown note: the framework keeps ONE cooldown per girl, and Homura's girl now owns two abilities. So that
-- Time Stop's 20 turns do not lock the missile (or the missile's 4 lock Time Stop), both abilities keep their
-- own counters in Lua and leave the framework's shared counter at its 1-turn minimum: using one locks the
-- other only until the player's next turn.
--
-- Design: docs/design/phase4-design-v1.md section 3 and the section 12 default for "Homura, Missile Fire
-- scaling".
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_CONCENTRATED_MISSILE_FIRE';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_CONCENTRATED_MISSILE_FIRE'), ('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE'), ('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE_HELP'), ('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_CONCENTRATED_MISSILE_FIRE'
WHERE Type = 'TRAIT_STEAL_ENEMY_UNIQUE_ON_CONQUEST';


--------------------------------------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE', 'Concentrated Missile Fire'),
	('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE_HELP', 'Homura empties a shield full of ordnance onto one tile. The target takes damage equal to a single Rocket Artillery shot: an attack at Rocket Artillery''s 60 Ranged [ICON_STRENGTH] Combat Strength, divided by the [ICON_STRENGTH] Combat Strength of the strongest ordinary land Unit of the current era and applied to her own, held between 100% and 250%.[NEWLINE][NEWLINE]Against an enemy City the shot also gains Rocket Artillery''s +200% City Attack bonus, so it lands three times as hard.[NEWLINE][NEWLINE]Because her own strength tracks the same era, the shell is worth about the same in every era instead of growing with her: it is capped at 250% in the early eras, where a true Rocket Artillery hit would simply kill, and settles at 100% from the Modern era onward. One Unit, or the City, is struck -- never a whole stack.[NEWLINE][NEWLINE]Costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Range 2. Cooldown 4 turns.'),
	('TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE_DISABLED', 'Concentrated Missile Fire is recovering, or there is no enemy in range.');



--------------------------------------------------------------------------------------------------------------
-- Homura Akemi: Time Stop
-- The second Leader Magical Girl ability on Homura's leader girl, bound to her trait by the TraitType field of
-- its Lua definition (the trait's LeaderMGUniqueMission column already names Concentrated Missile Fire).
-- No target, does not end her turn, no Soul Gem cost.
--
-- Cooldown 20 turns at Standard speed (scaled by game speed like every other leader ability). Each Grief Seed
-- any of the player's Magical Girls uses takes 1 turn off a running cooldown, but the seeds never bring it
-- below 5 turns after the use. The live count is PMMM.TimeStopCooldown[player], which the UnitPanel tooltip
-- and the "Draw Mana Into Your Shield" decision already read.
--
-- On use: every unit of the player gains one extra attack for the rest of the turn (the promotion below,
-- removed at the start of the player's next turn), and the player receives one free turn: each city's
-- per-turn Food, Production, Gold, Science, Culture and Faith, one turn of every worker build in progress,
-- one turn of Great Person points in every city, one turn of Tourism on every civilization met, and one
-- turn of ordinary healing for every hurt unit. Handler and its approximations:
-- Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityHomura.lua.
--
-- Design: docs/design/phase4-design-v1.md section 3, rulings table section 11 row 5, section 12 default for
-- "Homura, Time Stop Grief Seed reduction".
--------------------------------------------------------------------------------------------------------------
-- The mission is named MISSION_PMMM_TIME_STOP on purpose: UI Replacements/UnitPanel.lua already has a tooltip
-- branch for that name which shows PMMM.TimeStopCooldown. No PMMMMissionRange / PMMMTargetType, so the button
-- fires at once instead of opening target selection (the Baldamente Fortissimo pattern). Icon: the Skip Turn
-- hourglass.
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_TIME_STOP';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas)
SELECT		('MISSION_PMMM_TIME_STOP'), ('TXT_KEY_MISSION_PMMM_TIME_STOP'), ('TXT_KEY_MISSION_PMMM_TIME_STOP_HELP'), ('TXT_KEY_MISSION_PMMM_TIME_STOP_DISABLED'), EntityEventType, Time, 200, 1, IconIndex, IconAtlas
FROM Missions WHERE Type = 'MISSION_SKIP';

-- The extra attack. Named so that it does NOT match 'PROMOTION_PMMM_TIME_STOP_', the prefix
-- HasAnyTimeStopPromo (PMMMGeneralFunctions.lua) uses for the old "frozen in time" promotions. Blitz's icon.
DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_STOPPED_TIME_ATTACK';

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, ExtraAttacks)
SELECT		('PROMOTION_PMMM_STOPPED_TIME_ATTACK'), ('TXT_KEY_PROMOTION_PMMM_STOPPED_TIME_ATTACK'), ('TXT_KEY_PROMOTION_PMMM_STOPPED_TIME_ATTACK_HELP'), ('AS2D_IF_LEVELUP'), 1, PortraitIndex, IconAtlas, ('PEDIA_ATTRIBUTES'), ('TXT_KEY_PROMOTION_PMMM_STOPPED_TIME_ATTACK'), 1
FROM UnitPromotions WHERE Type = 'PROMOTION_BLITZ';


--------------------------------------------------------------------------------------------------------------
-- Thief of Time (UNIT_PMMM_CLOCKSTOPPER): now replaces the Scout instead of the Infantry.
-- 3 moves, the Warrior's Combat Strength (8), the Scout's cost, prerequisite and obsolescence, and it may enter
-- rival territory (PROMOTION_RIVAL_TERRITORY, the one promotion carrying RivalTerritory = 1 in this database).
-- The conquest-steal promotion PROMOTION_PMMM_CLOCKSTOPPER no longer fits a Scout and is no longer granted
-- (the promotion row itself stays: Clockstopper() in PMMMClockstopper.lua keys on the
-- ObtainUniqueUnitPromotionOnCityCapture column, not on this unit or this promotion).
-- Mechanic (Lua): each of the owner's turns that begins with the Thief inside another major civilization's
-- borders counts once, consecutive or not; every 3rd such turn the owner gains 10% of the research cost of a
-- random technology it can currently research.
--------------------------------------------------------------------------------------------------------------
UPDATE Civilization_UnitClassOverrides SET UnitClassType = 'UNITCLASS_SCOUT'
WHERE CivilizationType = 'CIVILIZATION_HOMURA' AND UnitType = 'UNIT_PMMM_CLOCKSTOPPER';

-- Ruling 15.5 (2026-09-18): the conquest steal is dropped for good; the Thief of Time fills that role.
-- Nothing grants PROMOTION_PMMM_CLOCKSTOPPER any more (no Unit_FreePromotions row, no other table names it, no
-- Lua grants it). Clearing its ObtainUniqueUnitPromotionOnCityCapture flag also empties
-- MapModData.gPMMMStealUUPromotions (PMMMDataStorage.lua), so Clockstopper() in PMMMClockstopper.lua finds no
-- stealing promotion on any capture and returns without effect. The promotion row stays as inert data because
-- SQL/Shared/PMMMNonMGPromotions.sql inserts it and XML/Text/UniqueUnits-english.xml carries its text; its help
-- text below no longer describes a steal.
UPDATE UnitPromotions SET ObtainUniqueUnitPromotionOnCityCapture = 0
WHERE Type = 'PROMOTION_PMMM_CLOCKSTOPPER';

-- Every gameplay column from the Scout (the base file cloned the Infantry), then the two deliberate changes:
-- Moves 3 and the Warrior's Combat. The name, the text and the Homura flag atlas are kept; the portrait and
-- the model become the Scout's, since an Infantry model in the Ancient era would look wrong.
UPDATE Units SET
	Class					= (SELECT Class FROM Units WHERE Type = 'UNIT_SCOUT'),
	Combat					= (SELECT Combat FROM Units WHERE Type = 'UNIT_WARRIOR'),
	RangedCombat			= (SELECT RangedCombat FROM Units WHERE Type = 'UNIT_SCOUT'),
	Range					= (SELECT Range FROM Units WHERE Type = 'UNIT_SCOUT'),
	Cost					= (SELECT Cost FROM Units WHERE Type = 'UNIT_SCOUT'),
	FaithCost				= (SELECT FaithCost FROM Units WHERE Type = 'UNIT_SCOUT'),
	RequiresFaithPurchaseEnabled = (SELECT RequiresFaithPurchaseEnabled FROM Units WHERE Type = 'UNIT_SCOUT'),
	PurchaseOnly			= (SELECT PurchaseOnly FROM Units WHERE Type = 'UNIT_SCOUT'),
	Moves					= 3,
	BaseSightRange			= (SELECT BaseSightRange FROM Units WHERE Type = 'UNIT_SCOUT'),
	Special					= (SELECT Special FROM Units WHERE Type = 'UNIT_SCOUT'),
	Domain					= (SELECT Domain FROM Units WHERE Type = 'UNIT_SCOUT'),
	CombatClass				= (SELECT CombatClass FROM Units WHERE Type = 'UNIT_SCOUT'),
	DefaultUnitAI			= (SELECT DefaultUnitAI FROM Units WHERE Type = 'UNIT_SCOUT'),
	NoBadGoodies			= (SELECT NoBadGoodies FROM Units WHERE Type = 'UNIT_SCOUT'),
	MilitarySupport			= (SELECT MilitarySupport FROM Units WHERE Type = 'UNIT_SCOUT'),
	MilitaryProduction		= (SELECT MilitaryProduction FROM Units WHERE Type = 'UNIT_SCOUT'),
	Pillage					= (SELECT Pillage FROM Units WHERE Type = 'UNIT_SCOUT'),
	PillagePrereqTech		= (SELECT PillagePrereqTech FROM Units WHERE Type = 'UNIT_SCOUT'),
	PrereqResources			= (SELECT PrereqResources FROM Units WHERE Type = 'UNIT_SCOUT'),
	Mechanized				= (SELECT Mechanized FROM Units WHERE Type = 'UNIT_SCOUT'),
	PrereqTech				= (SELECT PrereqTech FROM Units WHERE Type = 'UNIT_SCOUT'),
	ObsoleteTech			= (SELECT ObsoleteTech FROM Units WHERE Type = 'UNIT_SCOUT'),
	GoodyHutUpgradeUnitClass = (SELECT GoodyHutUpgradeUnitClass FROM Units WHERE Type = 'UNIT_SCOUT'),
	HurryCostModifier		= (SELECT HurryCostModifier FROM Units WHERE Type = 'UNIT_SCOUT'),
	AdvancedStartCost		= (SELECT AdvancedStartCost FROM Units WHERE Type = 'UNIT_SCOUT'),
	XPValueAttack			= (SELECT XPValueAttack FROM Units WHERE Type = 'UNIT_SCOUT'),
	XPValueDefense			= (SELECT XPValueDefense FROM Units WHERE Type = 'UNIT_SCOUT'),
	Conscription			= (SELECT Conscription FROM Units WHERE Type = 'UNIT_SCOUT'),
	ExtraMaintenanceCost	= (SELECT ExtraMaintenanceCost FROM Units WHERE Type = 'UNIT_SCOUT'),
	NoMaintenance			= (SELECT NoMaintenance FROM Units WHERE Type = 'UNIT_SCOUT'),
	UnitArtInfo				= (SELECT UnitArtInfo FROM Units WHERE Type = 'UNIT_SCOUT'),
	PortraitIndex			= (SELECT PortraitIndex FROM Units WHERE Type = 'UNIT_SCOUT'),
	IconAtlas				= (SELECT IconAtlas FROM Units WHERE Type = 'UNIT_SCOUT'),
	MoveRate				= (SELECT MoveRate FROM Units WHERE Type = 'UNIT_SCOUT')
WHERE Type = 'UNIT_PMMM_CLOCKSTOPPER';

-- Child rows: replace the Infantry copies with the Scout's.
DELETE FROM Unit_AITypes WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO Unit_AITypes (UnitType, UnitAIType)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', UnitAIType FROM Unit_AITypes WHERE UnitType = 'UNIT_SCOUT';

DELETE FROM Unit_Flavors WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', FlavorType, Flavor FROM Unit_Flavors WHERE UnitType = 'UNIT_SCOUT';

DELETE FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', UnitClassType FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_SCOUT';

DELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO Unit_ResourceQuantityRequirements (UnitType, ResourceType, Cost)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', ResourceType, Cost FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_SCOUT';

DELETE FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO UnitGameplay2DScripts (UnitType, SelectionSound, FirstSelectionSound)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', SelectionSound, FirstSelectionSound FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_SCOUT';

-- Free promotions: the Scout's own, plus the right to enter rival territory. PROMOTION_PMMM_CLOCKSTOPPER (the
-- old conquest steal) goes with the Infantry copies.
DELETE FROM Unit_FreePromotions WHERE UnitType = 'UNIT_PMMM_CLOCKSTOPPER';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', PromotionType FROM Unit_FreePromotions WHERE UnitType = 'UNIT_SCOUT';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT 'UNIT_PMMM_CLOCKSTOPPER', Type FROM UnitPromotions WHERE RivalTerritory = 1 AND Type = 'PROMOTION_RIVAL_TERRITORY';


--------------------------------------------------------------------------------------------------------------
-- Dimensional Armory: now replaces the Armory instead of the Military Academy.
-- An Armory clone -- cost, prerequisite tech, maintenance, prerequisite building and free experience all come
-- from BUILDING_ARMORY -- plus +1 Production.
-- Kept from the old version: Airlift and +4 air unit capacity. Both do nothing until the player has aircraft,
-- so they cost nothing early; late in the game the airlift network is the building's identity (Homura's
-- dimensional storage moving an army) and suits a civilization whose other tools are about tempo.
--------------------------------------------------------------------------------------------------------------
UPDATE Civilization_BuildingClassOverrides SET BuildingClassType = 'BUILDINGCLASS_ARMORY'
WHERE CivilizationType = 'CIVILIZATION_HOMURA' AND BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';

UPDATE Buildings SET
	BuildingClass			= (SELECT BuildingClass FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	Cost					= (SELECT Cost FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	FaithCost				= (SELECT FaithCost FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	GoldMaintenance			= (SELECT GoldMaintenance FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	PrereqTech				= (SELECT PrereqTech FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	ObsoleteTech			= (SELECT ObsoleteTech FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	HurryCostModifier		= (SELECT HurryCostModifier FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	ConquestProb			= (SELECT ConquestProb FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	Experience				= (SELECT Experience FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	GlobalExperience		= (SELECT GlobalExperience FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	MilitaryProductionModifier = (SELECT MilitaryProductionModifier FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	FreeStartEra			= (SELECT FreeStartEra FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	MaxStartEra				= (SELECT MaxStartEra FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	NeverCapture			= (SELECT NeverCapture FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	ArtDefineTag			= (SELECT ArtDefineTag FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	DisplayPosition			= (SELECT DisplayPosition FROM Buildings WHERE Type = 'BUILDING_ARMORY'),
	Airlift					= 1,
	AirModifier				= 4
WHERE Type = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';

-- Prerequisite building, free experience, production modifiers and AI flavour: the Armory's own rows.
DELETE FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_ClassesNeededInCity (BuildingType, BuildingClassType)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', BuildingClassType FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_ARMORY';

DELETE FROM Building_DomainFreeExperiences WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_DomainFreeExperiences (BuildingType, DomainType, Experience)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', DomainType, Experience FROM Building_DomainFreeExperiences WHERE BuildingType = 'BUILDING_ARMORY';

DELETE FROM Building_UnitCombatFreeExperiences WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_UnitCombatFreeExperiences (BuildingType, UnitCombatType, Experience)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', UnitCombatType, Experience FROM Building_UnitCombatFreeExperiences WHERE BuildingType = 'BUILDING_ARMORY';

DELETE FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_DomainProductionModifiers (BuildingType, DomainType, Modifier)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', DomainType, Modifier FROM Building_DomainProductionModifiers WHERE BuildingType = 'BUILDING_ARMORY';

DELETE FROM Building_Flavors WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', FlavorType, Flavor FROM Building_Flavors WHERE BuildingType = 'BUILDING_ARMORY';
INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor) VALUES
	('BUILDING_PMMM_DIMENSIONAL_ARMORY', 'FLAVOR_PRODUCTION', 5),
	('BUILDING_PMMM_DIMENSIONAL_ARMORY', 'FLAVOR_AIRLIFT', 10);

-- Yields: the Armory's own non-Production yields (none in CP 5.4), then its Production plus 1.
DELETE FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_PMMM_DIMENSIONAL_ARMORY';
INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', YieldType, Yield FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_ARMORY' AND YieldType <> 'YIELD_PRODUCTION';
INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
SELECT 'BUILDING_PMMM_DIMENSIONAL_ARMORY', 'YIELD_PRODUCTION',
	1 + IFNULL((SELECT SUM(Yield) FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_ARMORY' AND YieldType = 'YIELD_PRODUCTION'), 0);


--------------------------------------------------------------------------------------------------------------
-- Text: Time Stop, Thief of Time, Dimensional Armory
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_TIME_STOP', 'Time Stop'),
	('TXT_KEY_MISSION_PMMM_TIME_STOP_HELP', 'Homura stops time, and your civilization lives through a free turn while the world stands still:[NEWLINE][ICON_BULLET]Every Unit you own may attack one extra time this turn.[NEWLINE][ICON_BULLET]Every City gains one more turn of its [ICON_FOOD] Food surplus, [ICON_PRODUCTION] Production (into what it is building), [ICON_GOLD] Gold, [ICON_RESEARCH] Science (into your current research), [ICON_CULTURE] Culture and [ICON_PEACE] Faith, and one more turn of [ICON_GREAT_PEOPLE] Great Person points.[NEWLINE][ICON_BULLET]Every Worker build in progress advances by one more turn of work.[NEWLINE][ICON_BULLET]You gain one more turn of [ICON_TOURISM] Tourism on every civilization you have met.[NEWLINE][ICON_BULLET]Every damaged Unit heals as if it had rested a turn: the basic rate for where it stands (25 in a City, 20 in friendly land, 10 elsewhere) plus its healing promotions.[NEWLINE][NEWLINE]Needs no target, does not end her turn and costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Cooldown 20 turns. Each Grief Seed used by any of your Magical Girls takes 1 turn off the cooldown, but never brings it below 5 turns after the last use.'),
	('TXT_KEY_MISSION_PMMM_TIME_STOP_DISABLED', 'Time Stop is recovering, or Homura has already used an ability this turn.'),
	('TXT_KEY_MISSION_PMMM_TIME_STOP_COOLDOWN', 'Time Stop is recovering for {1_Turns} more turns.'),
	('TXT_KEY_MISSION_PMMM_TIME_STOP_ACTIVE', 'Time is already stopped this turn.'),
	('TXT_KEY_PMMM_ALERT_HOMURA_TIME_STOP_ACTIVATED', 'The world around you slows to a stop! Every Unit may attack one extra time this turn, and your empire lives through a free turn.'),
	('TXT_KEY_PROMOTION_PMMM_STOPPED_TIME_ATTACK', 'Stopped Time'),
	('TXT_KEY_PROMOTION_PMMM_STOPPED_TIME_ATTACK_HELP', 'Time Stop: this Unit may attack one extra time this turn. Removed at the start of your next turn.'),

	('TXT_KEY_UNIT_PMMM_CLOCKSTOPPER_HELP', 'Unique replacement for the Scout, which only Homura Akemi can train. 3 [ICON_MOVES] Moves and 8 [ICON_STRENGTH] Combat Strength (a Warrior''s), and it may enter rival territory without Open Borders. Every 3rd turn you begin with it inside another major civilization''s borders, you gain [ICON_RESEARCH] Science equal to 10% of the cost of a random technology you can currently research.'),
	('TXT_KEY_UNIT_PMMM_CLOCKSTOPPER_STRATEGY', 'The Thief of Time is the Unique Unit for Neo-Mitakihara, replacing the Scout. It costs the same as a Scout but moves 3 tiles and fights as well as a Warrior, and it may walk into foreign lands whether or not their owners have opened their borders. Keep it inside another major civilization''s territory: every third turn of yours that begins with it there (the turns need not be consecutive) gives you 10% of the [ICON_RESEARCH] cost of a random technology you can currently research. Like the Scout, it becomes obsolete with Scientific Theory.'),
	('TXT_KEY_PROMOTION_PMMM_CLOCKSTOPPER_HELP', 'Retired. This promotion no longer has any effect.'),
	('TXT_KEY_UNIT_PMMM_CLOCKSTOPPER_TEXT', 'Girls who have trained diligently in mimicking Homura Akemi''s magic, so much so that even their outfits are identical to hers. Homura''s magic stops time; her imitators use what little of it they have learned to slip across borders unseen and read other nations'' secrets while the clocks stand still.'),

	('TXT_KEY_BUILDING_PMMM_DIMENSIONAL_ARMORY_HELP', '+15 XP for all Units trained in this City. +1 [ICON_PRODUCTION] Production. Enables Units to be airlifted to other Cities which contain a Dimensional Armory or an Airport, and increases the maximum number of aircraft which can be stationed in this City by 4.[NEWLINE][NEWLINE]City must have a Barracks.'),
	('TXT_KEY_BUILDING_PMMM_DIMENSIONAL_ARMORY_HELP_CBP', '+15 XP for all Units trained in this City. +1 [ICON_PRODUCTION] Production. Enables Units to be airlifted to other Cities which contain a Dimensional Armory or an Airport, and increases the maximum number of aircraft which can be stationed in this City by 4.[NEWLINE][NEWLINE]City must have a Barracks.'),
	('TXT_KEY_BUILDING_PMMM_DIMENSIONAL_ARMORY_STRATEGY', 'The Dimensional Armory is the unique building for Neo-Mitakihara, replacing the Armory. It costs and maintains the same as an Armory, gives the same +15 XP to newly trained Units, and adds +1 [ICON_PRODUCTION] Production. Once aircraft arrive it also enables airlifts to other Cities with airlift-capable buildings and holds 4 more aircraft (stacking with an Airport), an early stand-in for the Airport''s military uses.');

-- Alert shown to a human owner when a Thief of Time pays out (Lua: GrantThiefOfTimeTech).
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_PMMM_ALERT_THIEF_OF_TIME', 'A Thief of Time brings back secrets from foreign lands: +{1_Num} [ICON_RESEARCH] Science toward {2_TechName:textkey}.');
