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
SELECT		('MISSION_PMMM_TIRO_FINALE_MG'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE_MG_HELP'), ('TXT_KEY_MISSION_PMMM_TIRO_FINALE_MG_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
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
	('TXT_KEY_MISSION_PMMM_TIRO_FINALE_MG_DISABLED', 'Tiro Finale is recovering, or there is no enemy within 2 tiles.'),
	('TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL', 'Tiro Finale Recoil'),
	('TXT_KEY_PROMOTION_PMMM_TIRO_FINALE_RECOIL_HELP', '-50% [ICON_STRENGTH] Defense until the start of her next turn, after firing Tiro Finale.');

--------------------------------------------------------------------------------------------------------------
-- Two Leader Magical Girls whose state never changes.
-- Ultimate Madoka's can never lose Mood or Soul Gem and can never become a Witch.
-- Devil Homura's is always in Despair, takes none of its penalties, and can never become a Witch.
-- The Lua that reads these lives in PMMMMagicalGirls.lua (corruption) and Moods/PMMMCoreMoods.lua (mood).
--------------------------------------------------------------------------------------------------------------
DELETE FROM UnitPromotions WHERE Type IN ('PROMOTION_PMMM_NEVER_DESPAIR', 'PROMOTION_PMMM_ALWAYS_DESPAIR');

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry)
VALUES	('PROMOTION_PMMM_NEVER_DESPAIR', 'TXT_KEY_PROMOTION_PMMM_NEVER_DESPAIR', 'TXT_KEY_PROMOTION_PMMM_NEVER_DESPAIR_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_NEVER_DESPAIR'),
		('PROMOTION_PMMM_ALWAYS_DESPAIR', 'TXT_KEY_PROMOTION_PMMM_ALWAYS_DESPAIR', 'TXT_KEY_PROMOTION_PMMM_ALWAYS_DESPAIR_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_ALWAYS_DESPAIR');

UPDATE Traits SET LeaderMGUniquePromotion = 'PROMOTION_PMMM_NEVER_DESPAIR'  WHERE Type = 'TRAIT_NO_WITCHES';
UPDATE Traits SET LeaderMGUniquePromotion = 'PROMOTION_PMMM_ALWAYS_DESPAIR' WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_PROMOTION_PMMM_NEVER_DESPAIR', 'Law of Cycles Incarnate'),
	('TXT_KEY_PROMOTION_PMMM_NEVER_DESPAIR_HELP', 'Her Mood is always Ecstatic, her Soul Gem never clouds, and she can never become a Witch.'),
	('TXT_KEY_PROMOTION_PMMM_ALWAYS_DESPAIR', 'Meikyuu no Homura'),
	('TXT_KEY_PROMOTION_PMMM_ALWAYS_DESPAIR_HELP', 'She is always in Despair, but suffers none of its penalties, her Soul Gem never clouds, and she can never become a Witch.');

--------------------------------------------------------------------------------------------------------------
-- DLL-backed trait values (columns declared in SQL/Shared/MadokaTableUpdates.sql, read by the bundled DLL)
--------------------------------------------------------------------------------------------------------------
-- Devil Homura, Ai Yo: +1% per 5 unhappiness from cities and population, up to +25%.
UPDATE Traits SET PMMMIgnoreUnhappinessPenalties = 1, PMMMUnhappinessPerBonusPercent = 5, PMMMUnhappinessBonusMax = 25,
	PMMMNoGoldenAges = 1, PMMMNoIdeologyPressure = 1
WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

-- Mami: every city past the fourth adds 4 unhappiness per city over (5 cities +4, 6 +16, 7 +36).
UPDATE Traits SET PMMMCityCapThreshold = 4, PMMMCityCapUnhappinessStep = 4
WHERE Type = 'TRAIT_FRIENDSHIP_PRODUCTION_BONUS';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_PMMM_YIELD_MOD_AI_YO', '[NEWLINE][ICON_BULLET]Ai Yo: {1_Num}%');

--------------------------------------------------------------------------------------------------------------
-- Devil Homura's AI: a civ that borders her should expect a declaration of war.
--------------------------------------------------------------------------------------------------------------
UPDATE Leaders SET Boldness = 10, WarmongerHate = 2, DenounceWillingness = 8, DoFWillingness = 2, Forgiveness = 1
WHERE Type = 'LEADER_DEMON_HOMURA';

UPDATE Leader_MajorCivApproachBiases SET Bias = 10 WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND MajorCivApproachType = 'MAJOR_CIV_APPROACH_WAR';
UPDATE Leader_MajorCivApproachBiases SET Bias = 8  WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND MajorCivApproachType = 'MAJOR_CIV_APPROACH_HOSTILE';
UPDATE Leader_MajorCivApproachBiases SET Bias = 6  WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND MajorCivApproachType = 'MAJOR_CIV_APPROACH_DECEPTIVE';
UPDATE Leader_MajorCivApproachBiases SET Bias = 1  WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND MajorCivApproachType = 'MAJOR_CIV_APPROACH_FRIENDLY';

UPDATE Leader_Flavors SET Flavor = 10 WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND FlavorType = 'FLAVOR_OFFENSE';
UPDATE Leader_Flavors SET Flavor = 10 WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND FlavorType = 'FLAVOR_EXPANSION';
UPDATE Leader_Flavors SET Flavor = 8  WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND FlavorType = 'FLAVOR_MILITARY_TRAINING';
UPDATE Leader_Flavors SET Flavor = 1  WHERE LeaderType = 'LEADER_DEMON_HOMURA' AND FlavorType = 'FLAVOR_HAPPINESS';
