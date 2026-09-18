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


--------------------------------------------------------------------------------------------------------------
-- Kazumi: Pleiades Saints (design section 9; maintainer: the Freezer never takes Leader Magical Girls)
--
-- 1. Writing identity. Great Works of Writing +1 Culture +1 Gold (Trait_LitYieldChanges).
--    Ruling 15.2 (2026-09-18), pending a full rework: Traits.GreatWorkWLTKD (a CP boolean that started We Love
--    the King Day in every city whenever she created a Great Work) is turned off. In its place, creating a Great
--    Work grants a random one of Gold, Faith, Science or Culture: 25 x (era index + 1), scaled by the speed's
--    TrainPercent (Standard 25 in the Ancient era up to 200 in the Information era). Lua:
--    Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityKaoruUmika.lua, on GameEvents.GreatWorkCreated.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Trait_LitYieldChanges WHERE TraitType = 'TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS';
INSERT INTO Trait_LitYieldChanges (TraitType, YieldType, Yield) VALUES
	('TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS', 'YIELD_CULTURE', 1),
	('TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS', 'YIELD_GOLD', 1);

UPDATE Traits SET GreatWorkWLTKD = 0
WHERE Type = 'TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS';

--------------------------------------------------------------------------------------------------------------
-- 2. The Freezer is deterministic now; the rules live in Lua/Gameplay/Traits/PMMMPleiadesTrait.lua.
--    The old prediction Defines (FREEZER_PER_*, FREEZER_TOTAL_SCIENCE_PERCENT, FREEZER_PREVIOUS_SUCCESS_VALUE,
--    FREEZER_TURNS_BETWEEN_SG_DECAY) are no longer read by anything; they stay in WFTWGameDefines.xml, which
--    this file does not own. The capacity Defines (INITIAL_FREEZER_STORAGE 3, POP_NEEDED_FOR_NEXT_FREEZER_STORAGE
--    5) are still used. MISSION_PMMM_PLEIADES_FREEZER (the old "Begin" experiment) is no longer pushed.
--------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
-- 3. Artificial Incubator. The Scout ban goes (the Incubator has its own class, so Scouts are simply trainable
--    again); the cap rises from 3 to 4; it starts with Sentry (+1 sight); Polish is 5% per use. The Lua reads
--    the amount from Missions.PMMMPolishAmount; UnitPromotions.SoulGemPolishPercent is unread but kept equal.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Trait_NoTrain
WHERE TraitType = 'TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS' AND UnitClassType = 'UNITCLASS_SCOUT';

UPDATE UnitClasses SET MaxPlayerInstances = 4
WHERE Type = 'UNITCLASS_PMMM_ARTIFICIAL_INCUBATOR';

DELETE FROM Unit_FreePromotions
WHERE UnitType = 'UNIT_PMMM_ARTIFICIAL_INCUBATOR' AND PromotionType = 'PROMOTION_SENTRY';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType) VALUES
	('UNIT_PMMM_ARTIFICIAL_INCUBATOR', 'PROMOTION_SENTRY');

UPDATE Missions SET PMMMPolishAmount = 5
WHERE Type = 'MISSION_PMMM_POLISH';

UPDATE UnitPromotions SET SoulGemPolishPercent = 5
WHERE Type = 'PROMOTION_PMMM_ARTIFICIAL_INCUBATOR';

--------------------------------------------------------------------------------------------------------------
-- 4. Angelica Bears. The copying INSERT in KaoruUmikaBuilding.sql never carried PMMMEntertainment, so the
--    later +1 landed on 0 and the building gave 1 against the Amusement Park's 3. Set it outright. The +2
--    Culture and +1 Tourism are already in Building_YieldChanges. Teddy Bears is marked a monopoly luxury
--    (+2 Happiness and +10% Golden Age length while holding more than GLOBAL_RESOURCE_MONOPOLY_THRESHOLD, 50%,
--    of the world's copies). CAUTION: CP applies monopolies only when CustomModOptions
--    BALANCE_RESOURCE_MONOPOLIES = 1 (CvPlayer::SetHasGlobalMonopoly returns early otherwise), and it is 0 in
--    this mod's CP-only and Lekmod builds. The columns are set so the bonus works wherever that option is on
--    (e.g. under Vox Populi), but the player-facing text does not promise it.
--------------------------------------------------------------------------------------------------------------
UPDATE Buildings SET PMMMEntertainment = 4
WHERE Type = 'BUILDING_PMMM_ANGELICA_BEARS';

UPDATE Resources SET IsMonopoly = 1, MonopolyHappiness = 2, MonopolyGALength = 10
WHERE Type = 'RESOURCE_PMMM_TEDDY_BEAR';

--------------------------------------------------------------------------------------------------------------
-- 5. Text
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS_SHORT', 'Pleiades Saints'),
	('TXT_KEY_TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS', 'Great Works of Writing provide +1 [ICON_CULTURE] Culture and +1 [ICON_GOLD] Gold. When a Great Person creates a Great Work, gain a random one of [ICON_GOLD] Gold, [ICON_PEACE] Faith, [ICON_RESEARCH] Science or [ICON_CULTURE] Culture: 25 in the Ancient Era, +25 for each later era (200 in the Information Era), at Standard speed; scaled by game speed.[NEWLINE][NEWLINE][COLOR_POSITIVE_TEXT]The Freezer:[ENDCOLOR] an enemy Magical Girl you defeat in combat is captured into the Freezer in your [ICON_CAPITAL] Capital if it has room (3 girls, +1 for every 5 [ICON_CITIZEN] Population in your Capital). Leader Magical Girls can never be captured. A captured girl revives beside your Capital as [COLOR_POSITIVE_TEXT]your own Magical Girl[ENDCOLOR], keeping her promotions and level, after 15 turns, minus 2 turns for every Academy you own (minimum 5 turns). Each [ICON_PMMM_GRIEF_SEED] Grief Seed used on a stored girl takes 3 turns off her timer. Her Soul Gem does not decay while she is stored. If an enemy conquers your Capital, every stored girl goes to the conqueror as one of their Magical Girls, or is lost if they have none.[NEWLINE][NEWLINE]Begins the game with an Artificial Incubator.'),

	('TXT_KEY_UNIT_PMMM_ARTIFICIAL_INCUBATOR_HELP', 'Unique unit of the Pleiades Saints, trained in addition to the Scout. Cannot attack, but has an 80% chance to withdraw from melee attacks, and starts with Sentry (+1 sight). May Polish an adjacent Magical Girl''s [ICON_PMMM_SOUL_GEM] Soul Gem by 5%, up to 30%. Only 4 may be owned at a time.'),
	('TXT_KEY_UNIT_PMMM_ARTIFICIAL_INCUBATOR_STRATEGY', 'The Artificial Incubator is the Unique Unit of the Pleiades Saints. It is trained in addition to the Scout, not instead of it. It cannot attack and has a very low [ICON_STRENGTH] Combat Strength, but it withdraws from melee attacks 80% of the time and starts with Sentry for +1 sight, which makes it a good explorer. Its real value is Polishing a Magical Girl''s Soul Gem: each Polish, which uses all of its movement, adds 5% Polish to an adjacent Magical Girl, up to 30%. Whenever she would take Corruption, half of it (rounded down) goes to the Polish instead. Only four may be owned at a time.'),
	('TXT_KEY_MISSION_PMMM_POLISH_HELP', '[COLOR:31:236:224:255]Cost[ENDCOLOR]: All [ICON_MOVES] Movement[NEWLINE][NEWLINE]Order the Artificial Incubator to Polish the [ICON_PMMM_SOUL_GEM] Soul Gem of an adjacent Magical Girl by 5%. When a Magical Girl would take corruption to her Soul Gem, if Polish is present, then half of the corruption, rounded down, is instead dealt to the Polish. (Since it is always rounded down, the 1% Corruption sustained each turn is not affected.) A Magical Girl can have a maximum of 30% Polish at a time.'),

	('TXT_KEY_BUILDING_PMMM_ANGELICA_BEARS_HELP', '+4 [ICON_PMMM_ENTERTAINMENT] Entertainment, +2 [ICON_CULTURE] Culture and +1 [ICON_TOURISM] Tourism.[NEWLINE][NEWLINE]Provides 1 [ICON_RES_PMMM_TEDDY] Teddy Bears, a unique Luxury Resource.'),
	('TXT_KEY_BUILDING_PMMM_ANGELICA_BEARS_STRATEGY', 'This unique Amusement Park replacement may only be built by the Pleiades Saints. Besides +4 Entertainment, +2 Culture and +1 Tourism, it provides a copy of [ICON_RES_PMMM_TEDDY] Teddy Bears, a unique Luxury Resource only the Pleiades can produce. Obtain several copies of this resource to have an edge in trade agreements!'),

	('TXT_KEY_BUILDING_PMMM_FREEZER_STRATEGY', 'Don''t let an enemy capture your Capital while girls are in the Freezer: every one of them would join the conqueror.'),
	('TXT_KEY_PMMM_UI_TOPPANEL_FREEZER_TT', '{1_Num} Magical Girls stored out of a maximum of {2_Num}.[NEWLINE][NEWLINE]Defeat enemy Magical Girls (not Leader Magical Girls) in combat to store them in your Freezer. Each revives as your own Magical Girl after 15 turns, minus 2 per Academy you own (minimum 5); a [ICON_PMMM_GRIEF_SEED] Grief Seed takes 3 turns off.[NEWLINE][COLOR_POSITIVE_TEXT]Click[ENDCOLOR] to open the Freezer.[NEWLINE][NEWLINE]Storage: 3, +1 for every 5 [ICON_CITIZEN] Population in your [ICON_CAPITAL] Capital.[NEWLINE]'),
	('TXT_KEY_PMMM_UI_TOPPANEL_FREEZER_GIRL_TT', '{1_Str}: revives in {2_Num} {2_Num: plural 1?turn; other?turns;}'),

	('TXT_KEY_PMMM_UI_FREEZER_EXPLANATION', 'The Freezer holds the bodies and Soul Gems of the Magical Girls your Civilization has defeated in combat. Each one revives beside your [ICON_CAPITAL] Capital as your own Magical Girl, with her promotions and level, after 15 turns, minus 2 turns for every Academy you own (never fewer than 5). The Academy count is checked every turn, so a new Academy shortens every timer at once. Using a [ICON_PMMM_GRIEF_SEED] Grief Seed on a girl takes 3 more turns off hers, and a girl whose timer reaches 0 revives immediately.'),
	('TXT_KEY_PMMM_UI_FREEZER_LIST_TURNS', '{1_Num} {1_Num: plural 1?turn; other?turns;}'),
	('TXT_KEY_PMMM_UI_FREEZER_LIST_TURNS_TT', '{1_Str} revives as your Magical Girl in {2_Num} {2_Num: plural 1?turn; other?turns;}, at level {3_Num}. Her [ICON_PMMM_SOUL_GEM] Soul Gem is preserved at {4_Num}%.'),
	('TXT_KEY_PMMM_UI_FREEZER_REVIVAL_TURNS', 'Revives in {1_Num} {1_Num: plural 1?turn; other?turns;}'),
	('TXT_KEY_PMMM_UI_FREEZER_NUM_ACADEMIES', 'Academies you own: {1_Num}'),
	('TXT_KEY_PMMM_UI_FREEZER_REVIVAL_DURATION', 'Time in the Freezer: {1_Num} turns (15, minus 2 per Academy, minimum 5), less 3 turns per [ICON_PMMM_GRIEF_SEED] Grief Seed used on her.'),
	('TXT_KEY_PMMM_UI_FREEZER_REVIVAL_DESC', '{1_Str} will join you at level {2_Num} with all the promotions she had when you defeated her. Her [ICON_PMMM_SOUL_GEM] Soul Gem is preserved at {3_Num}% and does not decay in the Freezer.'),
	('TXT_KEY_PMMM_UI_FREEZER_USE_GRIEF_SEED_TT', 'Spend a [ICON_PMMM_GRIEF_SEED] Grief Seed to take 3 turns off this Magical Girl''s time in the Freezer. If that brings her timer to 0, she revives immediately.'),
	('TXT_KEY_PMMM_UI_FREEZER_USE_GRIEF_SEED_NO_UNIT_TT', '[COLOR_WARNING_TEXT]Needs your turn to be active and one of your units with movement left to carry the order. It costs that unit nothing, but replaces its current orders.[ENDCOLOR]'),
	('TXT_KEY_PMMM_UI_FREEZER_SOUL_GEM_TT', '{1_Str}''s [ICON_PMMM_SOUL_GEM] Soul Gem is preserved in the Freezer and does not decay.'),

	('TXT_KEY_PMMM_NOTIFICATION_CAPTURED_MG_TO_FREEZER_TEXT', 'You captured {1_Str}, an enemy Magical Girl, and placed her in the cryogenic storage of your Freezer. She will revive as your own Magical Girl in {2_Num} turns (15, minus 2 per Academy you own, minimum 5). Each Grief Seed you use on her takes 3 turns off.'),
	('TXT_KEY_PMMM_NOTIFICATION_FREEZER_REVIVED_TITLE', 'A Magical Girl Leaves the Freezer'),
	('TXT_KEY_PMMM_NOTIFICATION_FREEZER_REVIVED_TEXT', '{1_Str} has been revived from the Freezer. After some loud complaints about being captured, she has agreed to fight by your side, with every promotion she had before.'),
	('TXT_KEY_PMMM_ALERT_FREEZER_GRIEF_SEED', 'A Grief Seed speeds {1_Str}''s revival by {2_Num} turns. She revives in {3_Num} {3_Num: plural 1?turn; other?turns;}.'),
	('TXT_KEY_PMMM_ALERT_FREEZER_CAPTURE_GOOD', 'You have released {1_Str} from the captured Freezer! She has joined your side in gratitude.'),
	('TXT_KEY_PMMM_ALERT_KAZUMI_GREAT_WORK_BONUS', 'Pleiades Saints: the new Great Work brings +{1_Num} {2_Str} {3_Str}.'),
	('TXT_KEY_PMMM_ALERT_FREEZER_CAPTURE_LOST', 'The Magical Girl {1_Str} was kept in the captured Freezer, but her Soul Gem shattered when the building was breached.');
