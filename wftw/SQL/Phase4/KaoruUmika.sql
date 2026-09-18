--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for KaoruUmika
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- Kazumi: Rule Break
-- A friendly Magical Girl within two tiles may take a promotion at once, whatever her experience says.
-- No damage and no Soul Gem cost; the ten-turn cooldown is the whole of the price. She may aim it at
-- herself, which FRIENDLY_MAGICAL_GIRL targeting already allows.
-- Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityKaoruUmika.lua
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_RULE_BREAK';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_RULE_BREAK'), ('TXT_KEY_MISSION_PMMM_RULE_BREAK'), ('TXT_KEY_MISSION_PMMM_RULE_BREAK_HELP'), ('TXT_KEY_MISSION_PMMM_RULE_BREAK_DISABLED'), EntityEventType, Time, 200, 1, 45, ('UNIT_ACTION_ATLAS'),
			2, ('FRIENDLY_MAGICAL_GIRL')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_RULE_BREAK'
WHERE Type = 'TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS';


--------------------------------------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_RULE_BREAK', 'Rule Break'),
	('TXT_KEY_MISSION_PMMM_RULE_BREAK_HELP', 'Undoes the rule that a Magical Girl must earn her strength. One friendly Magical Girl within 2 tiles, Kazumi herself included, may choose a promotion immediately, no matter how much Experience she has.[NEWLINE][NEWLINE]Deals no damage and costs no Soul Gem. Range 2. Cooldown 10 turns.'),
	('TXT_KEY_MISSION_PMMM_RULE_BREAK_DISABLED', 'Rule Break is recovering, or no friendly Magical Girl in range still needs a promotion.');
