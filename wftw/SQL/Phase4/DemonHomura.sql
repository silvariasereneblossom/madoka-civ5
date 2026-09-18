--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for DemonHomura
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- UA "Ai Yo" (TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS, CIVILIZATION_DEMON_HOMURA).
-- Data only. The game's SQLite is 3.7.17: no WITH, no window functions, no bare DEFAULT true/false.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. UMG "Falsified Phenomena": the Leader Magical Girl ability (data half).
--    An area hit -- every enemy unit on the target tile and on the six tiles around it takes an attack at
--    150% of her Combat Strength. Range 2, cooldown 5, no Soul Gem cost.
--    Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityDemonHomura.lua. It needs no promotion of its
--    own, so this block is the mission row, the trait link and the text.
--
--    The rest of the spec's Leader Magical Girl clauses -- she is always in Despair, takes no Despair
--    penalties, and can never become a Witch -- are states of the girl rather than of the ability. They ride
--    on PROMOTION_PMMM_ALWAYS_DESPAIR, set up in Abilities.sql and read by the girl-state code, so the help
--    text below describes the attack only.
--
--    Design: docs/design/phase4-design-v1.md section 4 and ruling 4 in section 11.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_FALSIFIED_PHENOMENA';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_FALSIFIED_PHENOMENA'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_HELP'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_FALSIFIED_PHENOMENA'
WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA', 'Falsified Phenomena'),
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_HELP', 'Homura rewrites what happened across seven tiles at once. Every enemy Unit on the target tile and on the six tiles around it takes damage equal to an attack at 150% of her [ICON_STRENGTH] Combat Strength. Whole stacks are struck, not one Unit per tile, and enemy Cities in the area are damaged as well.[NEWLINE][NEWLINE]Costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Range 2. Cooldown 5 turns.'),
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_DISABLED', 'Falsified Phenomena is recovering, or there is no enemy in range.');
