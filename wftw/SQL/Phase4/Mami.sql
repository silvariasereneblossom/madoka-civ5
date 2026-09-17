--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Mami
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- UA "Not Afraid of Anything Anymore" (TRAIT_FRIENDSHIP_PRODUCTION_BONUS, CIVILIZATION_MAMI).
-- Data only. The game's SQLite is 3.7.17: no WITH, no window functions, no bare DEFAULT true/false.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. Turn-one value from city-states. Both tables are (TraitType, YieldType, Yield) in CP 5.4.6; there is no
--    era-scaling column because the DLL already scales them: CvCity::UpdateYieldsFromExistingFriendsAndAllies
--    applies Yield x number of allies/friends x max(1, current era) to the CAPITAL only. So +2 Production per
--    ally reads as +2 in the Ancient era and grows one step per era.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Trait_YieldFromCSAlly   WHERE TraitType = 'TRAIT_FRIENDSHIP_PRODUCTION_BONUS';
DELETE FROM Trait_YieldFromCSFriend WHERE TraitType = 'TRAIT_FRIENDSHIP_PRODUCTION_BONUS';

INSERT INTO Trait_YieldFromCSAlly (TraitType, YieldType, Yield)
VALUES ('TRAIT_FRIENDSHIP_PRODUCTION_BONUS', 'YIELD_PRODUCTION', 2);
INSERT INTO Trait_YieldFromCSAlly (TraitType, YieldType, Yield)
VALUES ('TRAIT_FRIENDSHIP_PRODUCTION_BONUS', 'YIELD_SCIENCE', 1);
INSERT INTO Trait_YieldFromCSFriend (TraitType, YieldType, Yield)
VALUES ('TRAIT_FRIENDSHIP_PRODUCTION_BONUS', 'YIELD_PRODUCTION', 1);


--------------------------------------------------------------------------------------------------------------
-- 2a. Teahouse: flat +2 Gold, and units trained here start veteran (Experience 15).
--     Its trade-route lines (TradeRouteLandDistanceModifier 50, TradeRouteLandGoldBonus 200) are untouched.
--
--     [Lua PENDING] Ruling 11.6: "Mami earns +2 Gold and +10% Gold per Declaration of Friendship partner or
--     protected city-state." Only the flat +2 Gold is data. The per-partner +10% Gold modifier has no data
--     column and must be recounted each turn in Lua (count DoF partners + pledged-to-protect city-states,
--     then apply a gold rate modifier to Mami, NOT to the partners -- the old ledger paid the friends).
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_PMMM_TEAHOUSE'
  AND YieldType = 'YIELD_GOLD';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
VALUES ('BUILDING_PMMM_TEAHOUSE', 'YIELD_GOLD', 2);

UPDATE Buildings
SET Experience = 15
WHERE Type = 'BUILDING_PMMM_TEAHOUSE';


--------------------------------------------------------------------------------------------------------------
-- 2b. Retire the twelve hidden Teahouse dummies (binary ledger 1/2/4/8/16/32, one set granting Production in
--     Mami's own Caravansary class and one set granting Production in the friend's Palace). The driving Lua
--     is retired separately (wftw/Lua/Gameplay/Buildings/PMMMMamiBuilding.lua); this file only removes rows.
--     Yield rows first, then the buildings, then the building classes.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_BuildingClassYieldChanges WHERE BuildingType IN (
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_1',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_4',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_16',  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_32',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_1', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_4', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_16','BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_32');

DELETE FROM Building_YieldChanges WHERE BuildingType IN (
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_1',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_4',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_16',  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_32',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_1', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_4', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_16','BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_32');

DELETE FROM Buildings WHERE Type IN (
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_1',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_4',   'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_16',  'BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_32',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_1', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_2',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_4', 'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_8',
  'BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_16','BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_32');

DELETE FROM BuildingClasses WHERE Type IN (
  'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_1',   'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_2',
  'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_4',   'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_8',
  'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_16',  'BUILDINGCLASS_PMMM_TEAHOUSE_MAMI_DUMMY_32',
  'BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_1', 'BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_2',
  'BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_4', 'BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_8',
  'BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_16','BUILDINGCLASS_PMMM_TEAHOUSE_FRIEND_DUMMY_32');


--------------------------------------------------------------------------------------------------------------
-- 3. The Tiro Musketeer moves from the Rifleman to the Musketman.
--    Numbers copied from the UNIT_MUSKETMAN row: Cost 150, FaithCost 300, Combat 24, Moves 2 (unchanged),
--    PrereqTech TECH_GUNPOWDER, ObsoleteTech TECH_RIFLING, upgrades to UNITCLASS_RIFLEMAN,
--    GoodyHutUpgradeUnitClass UNITCLASS_RIFLEMAN, AdvancedStartCost 25, Conscription 4, DefaultUnitAI ATTACK.
--    Art and portrait follow the Musketman too, since a Rifleman model in the Medieval era looks wrong;
--    the custom Mami unit flag (UnitFlagAtlas CIV_ALPHA_ATLAS_MAMI, offset 0) is kept.
--    Units.Class must match the overridden class or the override does not take.
--    PROMOTION_PMMM_TIRO_MUSKETEER stays as its free promotion (Unit_FreePromotions is untouched).
--------------------------------------------------------------------------------------------------------------
UPDATE Civilization_UnitClassOverrides
SET UnitClassType = 'UNITCLASS_MUSKETMAN'
WHERE CivilizationType = 'CIVILIZATION_MAMI'
  AND UnitType = 'UNIT_PMMM_TIRO_MUSKETEER';

UPDATE Units
SET Class                    = 'UNITCLASS_MUSKETMAN',
    Cost                     = 150,
    FaithCost                = 300,
    Combat                   = 24,
    Moves                    = 2,
    PrereqTech               = 'TECH_GUNPOWDER',
    ObsoleteTech             = 'TECH_RIFLING',
    GoodyHutUpgradeUnitClass = 'UNITCLASS_RIFLEMAN',
    AdvancedStartCost        = 25,
    Conscription             = 4,
    DefaultUnitAI            = 'UNITAI_ATTACK',
    UnitArtInfo              = 'ART_DEF_UNIT_MUSKETMAN',
    IconAtlas                = 'UNIT_ATLAS_1',
    PortraitIndex            = 38
WHERE Type = 'UNIT_PMMM_TIRO_MUSKETEER';

DELETE FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_PMMM_TIRO_MUSKETEER';

INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
VALUES ('UNIT_PMMM_TIRO_MUSKETEER', 'UNITCLASS_RIFLEMAN');


--------------------------------------------------------------------------------------------------------------
-- 4. Tiro Finale to 150% strength (it becomes Mami's leader-girl ability at this value).
--
--    [Lua PENDING] The UMG version also wants half strength against enemies within one tile of the target
--    and DefenseMod -50 on Mami until her next turn; both are Lua constants and are NOT changed here, so the
--    unit help below still quotes the existing 25% splash and -20% defence.
--    [Lua PENDING] "Tiro Siege": a free attack usable only on cities, roughly a Cannon (virtual attack at
--    Cannon strength 14 with its city bonus, does not consume the unit's attack, once per turn per Musketeer,
--    city targets only). No data rows exist for it yet and it is not advertised in any text below.
--------------------------------------------------------------------------------------------------------------
UPDATE UnitPromotions
SET TiroFinaleStrength = 150
WHERE Type = 'PROMOTION_PMMM_TIRO_MUSKETEER';


--------------------------------------------------------------------------------------------------------------
-- 5. Text.
--
--    The trait line deliberately omits "each unique traded strategic resource +1 Production in the capital"
--    and "traded luxuries +1 Happiness" from the spec: both need a per-turn Lua count into a capital dummy
--    and neither is implemented here.
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = 'Gunpowder units receive +1 [ICON_STRENGTH] Combat Strength for every City-State Ally you have.[NEWLINE]Each City-State Ally provides +2 [ICON_PRODUCTION] Production and +1 [ICON_RESEARCH] Science in your [ICON_CAPITAL] Capital, and each City-State Friend provides +1 [ICON_PRODUCTION] Production there. These amounts increase with every Era.'
WHERE Tag = 'TXT_KEY_TRAIT_FRIENDSHIP_PRODUCTION_BONUS';

UPDATE Language_en_US
SET Text = 'Land trade routes originating from this city have a 50% increase in range and produce an additional 2 [ICON_GOLD] Gold when connecting to another civilization.[NEWLINE][NEWLINE]+2 [ICON_GOLD] Gold.[NEWLINE][NEWLINE]New land units trained in this City start with 15 Experience.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_TEAHOUSE_HELP';

UPDATE Language_en_US
SET Text = 'Unique replacement for the Musketman, which only Mami Tomoe can train. May use the Tiro Finale ability, an attack with a 2-tile range which hits with 150% of the Unit''s [ICON_STRENGTH] Combat Strength, and then with 25% of its strength in all adjacent tiles to the target. Using this ability reduces Defense by 20% until your next turn.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_TIRO_MUSKETEER_HELP';

UPDATE Language_en_US
SET Text = 'The Tiro Musketeer is the Unique Unit for Nazione di Tiro, replacing the Musketman. While they function identically to a Musketman in typical combat, they have an ace in the hole: the Tiro Finale attack. This works mostly the same as a regular ranged attack, striking at 150% of the Unit''s [ICON_STRENGTH] Combat Strength, but it also hits enemy targets within 1 tile of the primary target for 1/4 of the damage dealt to the primary target. Using this attack imposes a -20% Defense penalty until the Unit''s next turn.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_TIRO_MUSKETEER_STRATEGY';

UPDATE Language_en_US
SET Text = 'A platoon of Magical Girls who have trained diligently in mimicking Mami Tomoe''s Magic, so much so that even their outfits are identical to hers.[NEWLINE][NEWLINE]Not only have they trained in the use of her beautiful firearms, but they have also adopted her flair for the stylish and dramatic in combat. During a regular skirmish, they fight on par with a trained regiment of musketmen. However, once they feel it is their time to shine, they can unleash Mami''s signature attack: the Tiro Finale, a gargantuan flintlock weapon which lays waste to everything in the area. This, however, leaves them quite vulnerable to a counterattack from any survivors.'
WHERE Tag = 'TXT_KEY_UNIT_PMMM_TIRO_MUSKETEER_TEXT';

--------------------------------------------------------------------------------------------------------------
-- Teahouse friendship bonus: one stacking dummy, driven by PMMMMamiBuilding.lua.
-- Each copy is one Declaration of Friendship or one protected city-state: +2 Gold and +10% Gold in that city.
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO BuildingClasses (Type, Description, DefaultBuilding, NoLimit)
VALUES ('BUILDINGCLASS_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 'TXT_KEY_BUILDING_PMMM_TEAHOUSE', 'BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 1);

INSERT OR REPLACE INTO Buildings (Type, BuildingClass, Description, Help, Cost, FaithCost, GoldMaintenance, PrereqTech, NeverCapture, ArtDefineTag, MinAreaSize, ConquestProb, IconAtlas, PortraitIndex)
VALUES ('BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 'BUILDINGCLASS_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 'TXT_KEY_BUILDING_PMMM_TEAHOUSE', 'TXT_KEY_BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY_HELP', -1, -1, 0, NULL, 1, 'ART_DEF_BUILDING_CARAVANSARY', -1, 0, 'CIV_COLOR_ATLAS_MAMI', 0);

DELETE FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY';
INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
VALUES ('BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 'YIELD_GOLD', 2);

DELETE FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY';
INSERT INTO Building_YieldModifiers (BuildingType, YieldType, Yield)
VALUES ('BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY', 'YIELD_GOLD', 10);

INSERT OR REPLACE INTO Language_en_US (Tag, Text)
VALUES ('TXT_KEY_BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY_HELP', '+2 [ICON_GOLD] Gold and +10% [ICON_GOLD] Gold in this City for each Declaration of Friendship and each City-State you have pledged to protect.');

-- How many friends a Teahouse city may count (keeps a long diplomatic game bounded)
INSERT OR REPLACE INTO Defines (Name, Value) VALUES ('MAMI_TEAHOUSE_MAX_FRIENDS', 5);
