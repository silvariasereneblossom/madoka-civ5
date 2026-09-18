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
-- [Lua PENDING, elsewhere] The rest of Sayaka's kit in section 5 -- the doubled Wonder Tourism, the Palace
-- Music slots and Decretum, the Cutlass Conductor and the Tourism-to-Prodigy conversion -- is not in this
-- file, and the text below describes the ability only.
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
	('TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD', 'Rhapsody of Justice'),
	('TXT_KEY_PROMOTION_PMMM_FORTISSIMO_GUARD_HELP', 'Takes 50% less damage from all sources for 2 turns, after hearing Baldamente Fortissimo.');
