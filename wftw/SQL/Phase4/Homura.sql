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
-- [Lua PENDING, elsewhere] The rest of Homura's kit in section 3 -- the reworked Time Stop, Thief of Time
-- and the Dimensional Armory -- is not in this file, and the text below describes the missile shot only.
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
