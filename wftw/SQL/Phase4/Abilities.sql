--------------------------------------------------------------------------------------------------------------
-- Phase 4: Leader Magical Girl unique abilities (data half)
--
-- Each ability is a custom mission plus, where it needs one, a short-lived promotion. The trait column
-- LeaderMGUniqueMission names the mission that civilization's Leader Magical Girl owns; the framework in
-- Lua/Gameplay/MagicalGirls/PMMMLeaderAbilities.lua reads it, and the handlers live in
-- Lua/Gameplay/MagicalGirls/PMMMLeaderAbilityDefs.lua.
--
-- Loads after every civilization file. Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- Madoka Kaname: Pluvia Magica
-- A rain of arrows on a target and everything around it, and the survivors take more damage this turn.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_PLUVIA_MAGICA';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_PLUVIA_MAGICA'), ('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA'), ('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA_HELP'), ('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

--The vulnerability the rain leaves behind: cleared by the framework on the owner's next turn.
DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_PLUVIA_VULNERABLE';

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, DamageTakenMod)
VALUES		('PROMOTION_PMMM_PLUVIA_VULNERABLE', 'TXT_KEY_PROMOTION_PMMM_PLUVIA_VULNERABLE', 'TXT_KEY_PROMOTION_PMMM_PLUVIA_VULNERABLE_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_PLUVIA_VULNERABLE', 15);

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_PLUVIA_MAGICA'
WHERE Type = 'TRAIT_FREE_ARCHERY_BONUS_GARRISON_ATTACK';


--------------------------------------------------------------------------------------------------------------
-- Mami Tomoe: Tiro Finale
-- Her signature shot. The unit-borne version becomes a city-only siege attack later; this is the girl's.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_TIRO_FINALE_MG';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_TIRO_FINALE_MG'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE_MG_HELP'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

--Firing it leaves her exposed until her next turn.
DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_TIRO_FINALE_RECOIL';

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, DefenseMod)
VALUES		('PROMOTION_PMMM_TIRO_FINALE_RECOIL', 'TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL', 'TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL', -50);

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_TIRO_FINALE_MG'
WHERE Type = 'TRAIT_FRIENDSHIP_PRODUCTION_BONUS';


--------------------------------------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA', 'Pluvia Magica'),
	('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA_HELP', 'A rain of arrows falls on the target tile and every tile around it. Each enemy struck takes damage equal to an attack at half this Magical Girl''s [ICON_STRENGTH] Combat Strength, and takes 15% more damage from all sources for the rest of the turn.[NEWLINE][NEWLINE]Costs 20% of her Soul Gem. Range 2. Cooldown 4 turns.'),
	('TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA_DISABLED', 'Pluvia Magica is recovering, her Soul Gem is too clouded, or there is no enemy in range.'),
	('TXT_KEY_PROMOTION_PMMM_PLUVIA_VULNERABLE', 'Pierced by Hope'),
	('TXT_KEY_PROMOTION_PMMM_PLUVIA_VULNERABLE_HELP', 'Takes 15% more damage from all sources until the end of the turn.'),
	('TXT_KEY_MISSION_PMMM_TIRO_FINALE_MG_HELP', 'Fires her finishing shot. The target takes damage equal to an attack at 150% of her [ICON_STRENGTH] Combat Strength, and every enemy within one tile of it takes half as much.[NEWLINE][NEWLINE]She fights at -50% [ICON_STRENGTH] Defense until her next turn. Range 2. Cooldown 4 turns.'),
	('TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL', 'Tiro Finale Recoil'),
	('TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL_HELP', '-50% [ICON_STRENGTH] Defense until the start of her next turn, after firing Tiro Finale.');
