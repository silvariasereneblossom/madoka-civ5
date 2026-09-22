--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Sayaka
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- Sayaka Miki: Baldamente Fortissimo
-- No damage. Every friendly Unit within 2 tiles of her, herself included, heals 25% of its maximum hit
-- points at once and takes half damage while defending for the next 2 turns. Cooldown 6, no Soul Gem cost.
-- Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilitySayaka.lua
--
-- The ability has no target: it is centred on her. The mission row therefore carries neither
-- PMMMMissionRange nor PMMMTargetType, exactly as MISSION_PMMM_DULL_PAIN does, because PMMMTargetType is
-- what makes the UI open target selection instead of firing the mission straight away, and a range of 0
-- keeps the AI's search on her own tile. The two-tile radius lives in the handler.
--
-- The guard is a timed promotion. DamageTakenMod is the CP 5.4.6 column for it (added by the Community
-- Patch in Database Changes/UnitPromotions/PromotionTableChanges.sql) and it is a percentage applied to
-- damage the unit receives: CvUnit.cpp computes iDamage * (100 + DamageTakenMod) / 100 and passes the same
-- value into the melee damage maths, so a positive value means more damage taken -- the mod's own
-- PROMOTION_PMMM_PLUVIA_VULNERABLE uses +15 for that -- and -50 halves incoming damage. It applies whenever
-- the unit is the one being hurt, so besides defending it also halves the recoil she takes from her own
-- attacks; that is a small bonus on top of the spec, not a substitute for it.
--
-- The rest of Sayaka's kit in section 5 -- Kyoshikyoku no Seigi, the Palace Music Hall and Decretum, the
-- Cutlass Conductor and the Stage of Oktavia text -- follows this ability further down the file.
--
-- Design: docs/design/phase4-design-v1.md section 5.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_BALDAMENTE_FORTISSIMO';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas)
SELECT		('MISSION_PMMM_BALDAMENTE_FORTISSIMO'), ('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO'), ('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO_HELP'), ('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO_DISABLED'), EntityEventType, Time, 200, 1, 3, ('UNIT_ACTION_ATLAS')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

--The guard the song leaves behind: cleared by the framework two of the owner's turns later.
DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_FORTISSIMO_GUARD';

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, DamageTakenMod)
VALUES		('PROMOTION_PMMM_FORTISSIMO_GUARD', 'TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD', 'TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD', -50);

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_BALDAMENTE_FORTISSIMO'
WHERE Type = 'TRAIT_TOURISM_HEALING_BONUS';


--------------------------------------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO', 'Baldamente Fortissimo'),
	('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO_HELP', 'Sayaka plays her rhapsody where everyone can hear it. Every friendly Unit within 2 tiles of her, herself included, immediately recovers 25% of its maximum [ICON_STRENGTH] Hit Points and takes 50% less damage while defending for the next 2 turns.[NEWLINE][NEWLINE]Deals no damage, needs no target, and costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Cooldown 6 turns.'),
	('TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO_DISABLED', 'Baldamente Fortissimo is recovering. Sayaka must also have movement left to play it.'),
	('TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD', 'Fortissimo'),
	('TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD_HELP', 'Takes 50% less damage from all sources for 2 turns, after hearing Baldamente Fortissimo.');


--------------------------------------------------------------------------------------------------------------
-- Sayaka Miki: Kyoshikyoku no Seigi (Rhapsody of Justice)
-- Replaces the old UA ("Orchestra for Justice") entirely. Design: docs/design/phase4-design-v1.md section 5.
--
--   1. Wonders: each World Wonder she built and still holds gives +5% Tourism in all her cities, through a
--      stacking dummy building in the capital counted from Lua (ruling 15.1).
--   2. The Palace Music Hall: a capital-only building with 2 Great Work of Music slots; Decretum is
--      created and placed in its first slot from Lua when her capital first exists.
--   3. The Cutlass Conductor replaces the Swordsman and yields Culture and Faith on kills.
--   4. 10% of Tourism becomes Musician Prodigy points, 5% each Artist and Writer points, in the capital,
--      each capped at 20 points per turn (Lua).
-- Lua: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilitySayaka.lua. The ability file is always loaded; the
-- trait bootstrapper only loads PMMMSayakaTrait.lua when the retired trait columns are set.
--------------------------------------------------------------------------------------------------------------

--Retire the old UA. With both columns cleared, PMMMTraitBootstrapper.lua no longer loads
--PMMMSayakaTrait.lua, so the kill-to-Musician-points handler and the tourism-influence combat promotions
--(PROMOTION_SAYAKA_EXOTIC ... _DOMINANT) stop running. Nothing else grants those five promotions, so their
--rows stay as inert data.
UPDATE Traits
SET GreatPersonProgressFromKills = NULL, CombatBonusFromTourismInfluence = 0
WHERE Type = 'TRAIT_TOURISM_HEALING_BONUS';


--------------------------------------------------------------------------------------------------------------
-- 1. Wonders: +5% Tourism in every city per World Wonder she built (ruling 15.1, 2026-09-18)
-- Replaces the old per-wonder +100% city modifier (Policy_BuildingClassTourismModifiers), whose rows are gone.
--
-- No Building, Policy or Trait column gives a player-wide Tourism percentage, but Building_GlobalYieldModifiers
-- accepts YIELD_TOURISM: CvPlayer::processBuilding adds GetGlobalYieldModifier * iChange to the player's
-- yield rate modifier, and CvCity::getBaseYieldRateModifier adds the player's modifier to every city's yield,
-- Tourism included (the same path the old policy's modifier took, one level up). iChange is the change in
-- the real building count, so a stacked dummy adds 5% per copy.
--
-- The dummy stands in her capital; Lua (PMMMAbilitySayaka.lua) sets its count every turn to the number of
-- World Wonders (classes with MaxGlobalInstances = 1) standing in her cities whose original owner is her,
-- i.e. wonders she built and still holds, and moves it if the capital moves. NeverCapture: a captured
-- capital loses it, and the next turn puts it in her new capital.
--
-- POLICY_PMMM_SAYAKA_RHAPSODY stays as an empty hidden policy (no modifiers): the Lua uses it, saved by the
-- engine, as the "Decretum already created" flag.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Policy_BuildingClassTourismModifiers WHERE PolicyType = 'POLICY_PMMM_SAYAKA_RHAPSODY';
DELETE FROM Policies WHERE Type = 'POLICY_PMMM_SAYAKA_RHAPSODY';

INSERT INTO Policies
			(Type,								Description,							Help,										IsDummy,	PortraitIndex,	IconAtlas,		IconAtlasAchieved)
VALUES		('POLICY_PMMM_SAYAKA_RHAPSODY',		'TXT_KEY_POLICY_PMMM_SAYAKA_RHAPSODY',	'TXT_KEY_POLICY_PMMM_SAYAKA_RHAPSODY_HELP',	1,			6,				'POLICY_ATLAS',	'POLICY_A_ATLAS');

DELETE FROM Building_GlobalYieldModifiers WHERE BuildingType = 'BUILDING_PMMM_SAYAKA_WONDER_TOURISM';
DELETE FROM Buildings       WHERE Type = 'BUILDING_PMMM_SAYAKA_WONDER_TOURISM';
DELETE FROM BuildingClasses WHERE Type = 'BUILDINGCLASS_PMMM_SAYAKA_WONDER_TOURISM';

INSERT INTO BuildingClasses (Type, Description, DefaultBuilding, NoLimit)
VALUES ('BUILDINGCLASS_PMMM_SAYAKA_WONDER_TOURISM', 'TXT_KEY_BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 'BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 1);

INSERT INTO Buildings
			(Type, BuildingClass, Description, Help, Cost, FaithCost, GreatWorkCount, PrereqTech,
			NeverCapture, NukeImmune, ConquestProb, IsDummy, ShowInPedia,
			IconAtlas, PortraitIndex)
VALUES		('BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 'BUILDINGCLASS_PMMM_SAYAKA_WONDER_TOURISM',
			'TXT_KEY_BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 'TXT_KEY_BUILDING_PMMM_SAYAKA_WONDER_TOURISM_HELP', -1, -1, -1, NULL,
			1, 1, 0, 1, 0,
			'BW_ATLAS_1', 19);

INSERT INTO Building_GlobalYieldModifiers (BuildingType, YieldType, Yield)
VALUES ('BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 'YIELD_TOURISM', 5);


--------------------------------------------------------------------------------------------------------------
-- 2. The Palace Music Hall and Decretum
-- A building holds one slot type and the Palace's is Art/Artifact, so the two Music slots live on a separate
-- capital-only building. Neither data route follows the capital (checked in CvCity.cpp):
--   * Civilization_FreeBuildingClasses is granted once, as a real building, in the first city only.
--   * Traits.FreeCapitalBuilding with no CapitalFreeBuildingPrereqTech is granted in the first city, but
--     CvCity::AddFreeCapitalBuildings only moves it to a new capital when that prereq tech is set.
-- So Lua owns it: when she founds a city and at the start of every turn it puts the Hall in her current
-- capital and moves it, with the works in its slots, out of any former capital. Cost -1: never buildable.
--
-- Decretum: a Great Work of Music, created once with Game.CreateGreatWork and placed with
-- City:SetBuildingGreatWork(Hall class, slot 0, index), the same two calls CP makes for Buildings.FreeGreatWork.
-- FreeGreatWork is not used because it would create a fresh Decretum every time the Hall is re-granted.
-- Great Works of Music reach units only through Unit_UniqueNames, and no name carries this one, so no Great
-- Musician can ever create a second copy.
-- Audio: AS2D_GREAT_MUSICIAN_PAGANINI_CAPRICE24, the base game's solo violin piece (Paganini's Caprice
-- No. 24). The violin is the instrument of Sayaka's story, and Paganini is already one of her city names.
-- The Madoka soundtrack is a separate optional mod, so a base-game script is the only sound sure to exist.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Buildings WHERE Type = 'BUILDING_PMMM_OKTAVIAN_MUSIC_HALL';
DELETE FROM BuildingClasses WHERE Type = 'BUILDINGCLASS_PMMM_OKTAVIAN_MUSIC_HALL';

INSERT INTO BuildingClasses
			(Type,										DefaultBuilding,						Description,								NoLimit)
VALUES		('BUILDINGCLASS_PMMM_OKTAVIAN_MUSIC_HALL',	'BUILDING_PMMM_OKTAVIAN_MUSIC_HALL',	'TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL',	1);

INSERT INTO Buildings
			(Type,									BuildingClass,								Description,									Help,												Civilopedia,
			Cost,	FaithCost,	PrereqTech,	CapitalOnly,	NeverCapture,	NukeImmune,	ConquestProb,	GreatWorkSlotType,			GreatWorkCount,	GreatWorkYieldType,	PortraitIndex,	IconAtlas)
VALUES		('BUILDING_PMMM_OKTAVIAN_MUSIC_HALL',	'BUILDINGCLASS_PMMM_OKTAVIAN_MUSIC_HALL',	'TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL',	'TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL_HELP',	'TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL_HELP',
			-1,		0,			NULL,		1,				1,				1,			0,				'GREAT_WORK_SLOT_MUSIC',	2,				'YIELD_CULTURE',	19,				'BW_ATLAS_1');

DELETE FROM GreatWorks WHERE Type = 'GREAT_WORK_PMMM_DECRETUM';

INSERT INTO GreatWorks
			(Type,							Description,						GreatWorkClassType,	Image,							Audio,										ArchaeologyOnly)
VALUES		('GREAT_WORK_PMMM_DECRETUM',	'TXT_KEY_GREAT_WORK_PMMM_DECRETUM',	'GREAT_WORK_MUSIC',	'GreatMusician_Background.dds',	'AS2D_GREAT_MUSICIAN_PAGANINI_CAPRICE24',	0);


--------------------------------------------------------------------------------------------------------------
-- 3. Cutlass Conductor: now the Swordsman's replacement
-- The unit row is rebuilt as a Swordsman clone: class, strength, cost, faith cost, moves, sight, tech,
-- obsolescence (Steel), upgrade (Longswordsman), goody-hut upgrade, art and sounds. It keeps its unique
-- promotion and keeps not needing Iron (the base file removed the requirement and the spec does not bring
-- it back). Its own flag atlas (CIV_ALPHA_ATLAS_SAYAKA, offset 0) is kept.
--
-- The kill yield uses CP's UnitPromotions_YieldFromKills. Checked in CvPlayer::doInstantYield,
-- INSTANT_YIELD_TYPE_KILL: the killing unit's getYieldFromKills (summed from its promotions) is added to
-- iKillYield, then iKillYield = iKillYield * iCombatStrength / 100, where iCombatStrength is the killed
-- unit's max(base melee strength, base ranged strength). So 25 = a quarter of the victim's strength, rounded
-- down. Faith is skipped when religion is disabled for the game. Being a promotion, it stays with the unit
-- after it upgrades.
--------------------------------------------------------------------------------------------------------------
UPDATE Units SET
	Class						= (SELECT Class						FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Combat						= (SELECT Combat					FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RangedCombat				= (SELECT RangedCombat				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Cost						= (SELECT Cost						FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FaithCost					= (SELECT FaithCost					FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RequiresFaithPurchaseEnabled = (SELECT RequiresFaithPurchaseEnabled FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Moves						= (SELECT Moves						FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseSightRange				= (SELECT BaseSightRange			FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CombatClass					= (SELECT CombatClass				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	DefaultUnitAI				= (SELECT DefaultUnitAI				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PrereqTech					= (SELECT PrereqTech				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ObsoleteTech				= (SELECT ObsoleteTech				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GoodyHutUpgradeUnitClass	= (SELECT GoodyHutUpgradeUnitClass	FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	HurryCostModifier			= (SELECT HurryCostModifier			FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	AdvancedStartCost			= (SELECT AdvancedStartCost			FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Conscription				= (SELECT Conscription				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	XPValueAttack				= (SELECT XPValueAttack				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	XPValueDefense				= (SELECT XPValueDefense			FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CombatLimit					= (SELECT CombatLimit				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MaxHitPoints				= (SELECT MaxHitPoints				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	UnitArtInfo					= (SELECT UnitArtInfo				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MoveRate					= (SELECT MoveRate					FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PortraitIndex				= (SELECT PortraitIndex				FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	IconAtlas					= (SELECT IconAtlas					FROM Units WHERE Type = 'UNIT_SWORDSMAN')
WHERE Type = 'UNIT_PMMM_CUTLASS_CONDUCTOR';

DELETE FROM Civilization_UnitClassOverrides
WHERE CivilizationType = 'CIVILIZATION_SAYAKA' AND UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';

INSERT INTO Civilization_UnitClassOverrides
			(CivilizationType,		UnitClassType,			UnitType)
VALUES		('CIVILIZATION_SAYAKA',	'UNITCLASS_SWORDSMAN',	'UNIT_PMMM_CUTLASS_CONDUCTOR');

--Child tables: every row copied from the Longswordsman or Musketman is replaced by the Swordsman's.
DELETE FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', UnitClassType FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_AITypes WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_AITypes (UnitType, UnitAIType)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', UnitAIType FROM Unit_AITypes WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_Flavors WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', FlavorType, Flavor FROM Unit_Flavors WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO UnitGameplay2DScripts (UnitType, SelectionSound, FirstSelectionSound)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', SelectionSound, FirstSelectionSound FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_Buildings WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_Buildings (UnitType, BuildingType)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', BuildingType FROM Unit_Buildings WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_BuildingClassRequireds WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_BuildingClassRequireds (UnitType, BuildingClassType)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', BuildingClassType FROM Unit_BuildingClassRequireds WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_ProductionModifierBuildings WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_ProductionModifierBuildings (UnitType, BuildingType, ProductionModifier)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', BuildingType, ProductionModifier FROM Unit_ProductionModifierBuildings WHERE UnitType = 'UNIT_SWORDSMAN';

DELETE FROM Unit_YieldFromKills WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_YieldFromKills (UnitType, YieldType, Yield)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', YieldType, Yield FROM Unit_YieldFromKills WHERE UnitType = 'UNIT_SWORDSMAN';

--Still no Iron: nothing is copied into Unit_ResourceQuantityRequirements.
DELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';

DELETE FROM Unit_FreePromotions WHERE UnitType = 'UNIT_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT 'UNIT_PMMM_CUTLASS_CONDUCTOR', PromotionType FROM Unit_FreePromotions WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
VALUES ('UNIT_PMMM_CUTLASS_CONDUCTOR', 'PROMOTION_PMMM_CUTLASS_CONDUCTOR');

--Its promotion: Harmony retired (the column itself is gone), kill yields added.

DELETE FROM UnitPromotions_YieldFromKills WHERE PromotionType = 'PROMOTION_PMMM_CUTLASS_CONDUCTOR';
INSERT INTO UnitPromotions_YieldFromKills
			(PromotionType,							YieldType,			Yield)
VALUES		('PROMOTION_PMMM_CUTLASS_CONDUCTOR',	'YIELD_CULTURE',	25),
			('PROMOTION_PMMM_CUTLASS_CONDUCTOR',	'YIELD_FAITH',		25);

--Harmony's dummy building goes with it. The Conductor has no script any more.
DELETE FROM Buildings WHERE Type = 'BUILDING_PMMM_CUTLASS_CONDUCTOR_DUMMY';
DELETE FROM BuildingClasses WHERE Type = 'BUILDINGCLASS_PMMM_CUTLASS_CONDUCTOR_DUMMY';


--------------------------------------------------------------------------------------------------------------
-- Text: Kyoshikyoku no Seigi, the Music Hall, Decretum, the Cutlass Conductor and the Stage of Oktavia
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_TRAIT_TOURISM_HEALING_BONUS_SHORT', 'Kyoshikyoku no Seigi (Rhapsody of Justice)'),
	('TXT_KEY_TRAIT_TOURISM_HEALING_BONUS', 'Each World Wonder you built and still own gives +5% [ICON_TOURISM] Tourism in all your Cities. The Palace gains 2 Great Work of Music slots, and the first holds [COLOR_POSITIVE_TEXT]Decretum[ENDCOLOR] from the start.[NEWLINE][NEWLINE]Every turn the [ICON_CAPITAL] Capital earns [ICON_GREAT_PEOPLE] Musician Prodigy points equal to 10% of your [ICON_TOURISM] Tourism per turn, and Artist and Writer Prodigy points equal to 5% each. Each type is capped at 20 points per turn.'),
	('TXT_KEY_POLICY_PMMM_SAYAKA_RHAPSODY', 'Kyoshikyoku no Seigi'),
	('TXT_KEY_POLICY_PMMM_SAYAKA_RHAPSODY_HELP', 'Decretum has been composed.'),
	('TXT_KEY_BUILDING_PMMM_SAYAKA_WONDER_TOURISM', 'Rhapsody of Wonders'),
	('TXT_KEY_BUILDING_PMMM_SAYAKA_WONDER_TOURISM_HELP', '+5% [ICON_TOURISM] Tourism in all your Cities. Your [ICON_CAPITAL] Capital holds one for each World Wonder you built and still own.'),
	('TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL', 'Palace Music Hall'),
	('TXT_KEY_BUILDING_PMMM_OKTAVIAN_MUSIC_HALL_HELP', 'Part of Sayaka''s Palace: 2 slots for Great Works of Music. The first starts with [COLOR_POSITIVE_TEXT]Decretum[ENDCOLOR]. Always stands in the [ICON_CAPITAL] Capital: if the Palace moves, the Hall and the works in it follow at the start of your next turn. Cannot be built or captured.'),
	('TXT_KEY_GREAT_WORK_PMMM_DECRETUM', 'Decretum'),
	('TXT_KEY_UNIT_PMMM_CUTLASS_CONDUCTOR_HELP', 'Unique replacement for the Swordsman, which only Sayaka Miki can train. Does not require [ICON_RES_IRON] Iron. When it kills a unit, you gain [ICON_CULTURE] Culture and [ICON_PEACE] Faith, each equal to 25% of the killed unit''s [ICON_STRENGTH] Combat Strength.'),
	('TXT_KEY_UNIT_PMMM_CUTLASS_CONDUCTOR_STRATEGY', 'The Cutlass Conductor is the Unique Unit for the Oktavians, replacing the Swordsman. It has the Swordsman''s cost, strength and movement, but does not require [ICON_RES_IRON] Iron. Every unit it kills gives [ICON_CULTURE] Culture and [ICON_PEACE] Faith, each equal to a quarter of that unit''s [ICON_STRENGTH] Combat Strength, so stronger victims pay more. It upgrades to the Longswordsman and keeps this ability after upgrading.'),
	('TXT_KEY_UNIT_PMMM_CUTLASS_CONDUCTOR_TEXT', 'A platoon of Magical Girls who have trained diligently in mimicking Sayaka Miki''s Magic, so much so that even their outfits are identical to hers.[NEWLINE][NEWLINE]Because they can generate their own weapons from their magic, they do not require Iron. Every victory they win is played like a movement of a symphony, and the Oktavians answer each one with art and devotion.'),
	('TXT_KEY_PROMOTION_PMMM_CUTLASS_CONDUCTOR_HELP', 'When this unit kills a unit, gain [ICON_CULTURE] Culture and [ICON_PEACE] Faith, each equal to 25% of the killed unit''s [ICON_STRENGTH] Combat Strength.'),
	('TXT_KEY_BUILDING_PMMM_STAGE_OF_OKTAVIA_HELP', '+1 [ICON_CULTURE] Culture and 1 slot for a Great Work of Music. For every Stage of Oktavia in your empire holding a Great Work of Music, all your Units heal 1 extra HP at the start of your turn, wherever they are. +2 [ICON_CULTURE] Culture and +2 [ICON_TOURISM] Tourism after researching Combined Arms.[NEWLINE][NEWLINE]City must have an Amphitheater.'),
	('TXT_KEY_BUILDING_PMMM_STAGE_OF_OKTAVIA_HELP_CBP', '+1 [ICON_CULTURE] Culture and 1 slot for a Great Work of Music. For every Stage of Oktavia in your empire holding a Great Work of Music, all your Units heal 1 extra HP at the start of your turn, wherever they are. +2 [ICON_CULTURE] Culture and +2 [ICON_TOURISM] Tourism after researching Combined Arms.[NEWLINE][NEWLINE]City must have an Amphitheater.'),
	('TXT_KEY_BUILDING_PMMM_STAGE_OF_OKTAVIA_STRATEGY', 'The Stage of Oktavia is the unique building for The Oktavians, replacing the Opera House. It gives +1 [ICON_CULTURE] Culture and holds one Great Work of Music. For every Stage of Oktavia in your empire that holds a Great Work of Music, all your units heal 1 extra HP at the start of your turn, in any territory and whether or not they are fortified. After Combined Arms it also gives +2 [ICON_CULTURE] Culture and +2 [ICON_TOURISM] Tourism.');
