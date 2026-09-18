--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for UltimateMadoka
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- Ultimate Madoka: Nothing To Despair, Ever (active half)
-- One shot at four times her strength, never at a city and only half as hard at another Magical Girl, and
-- every girl of hers within two tiles has 5% of her Soul Gem cleared. The immunities the ability is named
-- for are the passive half and ride on PROMOTION_PMMM_NEVER_DESPAIR, set up in Abilities.sql.
-- Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityUltimateMadoka.lua
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_NOTHING_TO_DESPAIR';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_NOTHING_TO_DESPAIR'), ('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR'), ('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR_HELP'), ('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('NON_CITY_ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_NOTHING_TO_DESPAIR'
WHERE Type = 'TRAIT_NO_WITCHES';


--------------------------------------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR', 'Nothing To Despair, Ever'),
	('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR_HELP', 'One enemy unit takes damage equal to an attack at 400% of this Magical Girl''s [ICON_STRENGTH] Combat Strength. Against another Magical Girl the attack is halved, to 200%. Cities can never be targeted.[NEWLINE][NEWLINE]Every friendly Magical Girl within 2 tiles of her, herself included, recovers 5% of her Soul Gem. Range 2. Cooldown 5 turns.'),
	('TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR_DISABLED', 'Nothing To Despair, Ever is recovering, or there is no enemy unit in range. It can never be aimed at a city.');
