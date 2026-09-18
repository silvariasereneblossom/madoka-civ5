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



--------------------------------------------------------------------------------------------------------------
-- Ultimate Madoka: the Law of Cycles return and Summon Witch Form (design section 2, ruling 8)
-- A girl reborn from the Cycle carries PROMOTION_PMMM_CYCLE_RETURNED: 100 XP for every promotion she had applied
-- is given back once (ReturnFromLawOfCycles in PMMMGeneralFunctions.lua), and ExperiencePercent -100 stops all
-- combat XP after that (CvUnit::changeExperienceTimes100 adds XP x ExperiencePercent / 100, so -100 cancels it).
-- She may take or drop her Witch Form at will: PROMOTION_PMMM_WITCH_FORM, +20% Combat Strength.
-- Ruling 15.3 (2026-09-18): the player-facing name is "Summon Herald of the Cycle" (mission) and "Herald of the
-- Cycle" (promotion); the row Types keep their WITCH_FORM names. The old Summon Witch is removed at the end.
-- Handlers: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityUltimateMadoka.lua
--------------------------------------------------------------------------------------------------------------
DELETE FROM UnitPromotions WHERE Type IN ('PROMOTION_PMMM_CYCLE_RETURNED', 'PROMOTION_PMMM_WITCH_FORM');

INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry, ExperiencePercent, CombatPercent)
VALUES		('PROMOTION_PMMM_CYCLE_RETURNED', 'TXT_KEY_PROMOTION_PMMM_CYCLE_RETURNED', 'TXT_KEY_PROMOTION_PMMM_CYCLE_RETURNED_HELP', 'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_CYCLE_RETURNED', -100, 0),
			('PROMOTION_PMMM_WITCH_FORM', 'TXT_KEY_PROMOTION_PMMM_WITCH_FORM', 'TXT_KEY_PROMOTION_PMMM_WITCH_FORM_HELP', 'AS2D_IF_LEVELUP', 1, 57, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_WITCH_FORM', 0, 20);

DELETE FROM Missions WHERE Type = 'MISSION_PMMM_SUMMON_WITCH_FORM';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas)
SELECT		('MISSION_PMMM_SUMMON_WITCH_FORM'), ('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM'), ('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM_HELP'), ('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM_DISABLED'), EntityEventType, Time, 200, 1, 9, ('UNIT_ACTION_ATLAS')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';


--------------------------------------------------------------------------------------------------------------
-- Ultimate Madoka: the Luminous Garden also replaces the Grand Temple (design section 2)
-- A building has one class, so the Grand Temple half is its own building, copied from the Grand Temple (its cost,
-- Holy City and Temple-everywhere requirements and +8 Faith are kept) with:
--   Happiness 8, GreatPeopleRateModifier 25, ReligiousPressureModifier 200 (the Grand Temple's 100 doubles the
--   Holy City's pressure; 200 triples it), PMMMMoodBonus 10 (the Buildings Mood modifier in PMMMCoreMoods.lua gives
--   every one of her girls +10 Mood while she owns it).
-- Its empire-wide 1% Soul Gem recovery is in Lua/Gameplay/Buildings/PMMMUltimateMadokaBuilding.lua.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_YieldChanges				WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_YieldModifiers				WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_YieldChangesPerPop			WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_YieldChangesPerReligion	WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_BuildingClassYieldChanges	WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_Flavors					WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_ClassesNeededInCity		WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Building_PrereqBuildingClasses		WHERE BuildingType = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';
DELETE FROM Buildings							WHERE Type = 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE';

INSERT INTO Buildings
			(Type, Description, Civilopedia, Strategy, Help, ThemingBonusHelp, Quote, GoldMaintenance, MutuallyExclusiveGroup, TeamShare, Water, River,
			FreshWater, Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious, BorderObstacle, PlayerBorderObstacle, Capital, GoldenAge,
			MapCentering, NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting, AffectSpiesNow, NullifyInfluenceModifier, Cost,
			FaithCost, LeagueCost, UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod, HurryCostModifier, MinAreaSize, ConquestProb, CitiesPrereq,
			LevelPrereq, CultureRateModifier, GlobalCultureRateModifier, GreatPeopleRateModifier, GlobalGreatPeopleRateModifier, GreatGeneralRateModifier,
			GreatPersonExpendGold, GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience, FoodKept, Airlift, AirModifier, NukeModifier,
			NukeExplosionRand, HealRateChange, Happiness, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity, HappinessPerXPolicies,
			CityCountUnhappinessMod, NoOccupiedUnhappiness, WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier,
			GlobalSpaceProductionModifier, BuildingProductionModifier, WonderProductionModifier, CityConnectionTradeRouteModifier, CapturePlunderModifier,
			PolicyCostModifier, PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier, GlobalPlotBuyCostModifier,
			GlobalPopulationChange, TechShare, FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike, Espionage,
			AllowsFoodTradeRoutes, AllowsProductionTradeRoutes, Defense, ExtraCityHitPoints, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints,
			ExtraMissionarySpreads, ReligiousPressureModifier, EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange,
			TradeRouteRecipientBonus, TradeRouteTargetBonus, NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier,
			XBuiltTriggersIdeologyChoice, TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus,
			CityStateTradeRouteProductionModifier, GreatScientistBeakerModifier, BuildingClass, ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain,
			VictoryPrereq, FreeStartEra, MaxStartEra, ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion,
			TrainedFreePromotion, FreePromotionRemoved, ReplacementBuildingClass, PrereqTech, PolicyBranchType, SpecialistType, SpecialistCount,
			GreatWorkSlotType, FreeGreatWork, GreatWorkCount, SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition,
			PortraitIndex, WonderSplashImage, WonderSplashAnchor, WonderSplashAudio, IconAtlas, ArtInfoCulturalVariation, ArtInfoEraVariation,
			ArtInfoRandomVariation, PMMMMoodBonus)
SELECT		('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), ('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'),
			('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_TEXT'), ('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE_STRATEGY'),
			('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE_HELP'), ThemingBonusHelp, Quote, GoldMaintenance, MutuallyExclusiveGroup, TeamShare, Water,
			River, FreshWater, Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious, BorderObstacle, PlayerBorderObstacle, Capital,
			GoldenAge, MapCentering, NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting, AffectSpiesNow, NullifyInfluenceModifier,
			Cost, FaithCost, LeagueCost, UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod, HurryCostModifier, MinAreaSize, ConquestProb,
			CitiesPrereq, LevelPrereq, CultureRateModifier, GlobalCultureRateModifier, 25, GlobalGreatPeopleRateModifier, GreatGeneralRateModifier,
			GreatPersonExpendGold, GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience, FoodKept, Airlift, AirModifier, NukeModifier,
			NukeExplosionRand, HealRateChange, 8, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity, HappinessPerXPolicies, CityCountUnhappinessMod,
			NoOccupiedUnhappiness, WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier, GlobalSpaceProductionModifier,
			BuildingProductionModifier, WonderProductionModifier, CityConnectionTradeRouteModifier, CapturePlunderModifier, PolicyCostModifier,
			PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier, GlobalPlotBuyCostModifier, GlobalPopulationChange, TechShare,
			FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike, Espionage, AllowsFoodTradeRoutes,
			AllowsProductionTradeRoutes, Defense, ExtraCityHitPoints, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints, ExtraMissionarySpreads, 200,
			EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange, TradeRouteRecipientBonus, TradeRouteTargetBonus,
			NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier, XBuiltTriggersIdeologyChoice,
			TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus,
			CityStateTradeRouteProductionModifier, GreatScientistBeakerModifier, BuildingClass, ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain,
			VictoryPrereq, FreeStartEra, MaxStartEra, ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion,
			TrainedFreePromotion, FreePromotionRemoved, ReplacementBuildingClass, PrereqTech, PolicyBranchType, SpecialistType, SpecialistCount,
			GreatWorkSlotType, FreeGreatWork, GreatWorkCount, SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition, 3,
			WonderSplashImage, WonderSplashAnchor, WonderSplashAudio, ('CIV_COLOR_ATLAS_MADOKA_TEMP'), ArtInfoCulturalVariation, ArtInfoEraVariation,
			ArtInfoRandomVariation, 10
FROM Buildings WHERE Type = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), YieldType, Yield FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_YieldModifiers (BuildingType, YieldType, Yield)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), YieldType, Yield FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_YieldChangesPerPop (BuildingType, YieldType, Yield)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), YieldType, Yield FROM Building_YieldChangesPerPop WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_YieldChangesPerReligion (BuildingType, YieldType, Yield)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), YieldType, Yield FROM Building_YieldChangesPerReligion WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_BuildingClassYieldChanges (BuildingType, BuildingClassType, YieldType, YieldChange)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), BuildingClassType, YieldType, YieldChange FROM Building_BuildingClassYieldChanges WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), FlavorType, Flavor FROM Building_Flavors WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
VALUES ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE', 'FLAVOR_GREAT_PEOPLE', 35);

INSERT INTO Building_ClassesNeededInCity (BuildingType, BuildingClassType)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), BuildingClassType FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

INSERT INTO Building_PrereqBuildingClasses (BuildingType, BuildingClassType, NumBuildingNeeded)
SELECT ('BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE'), BuildingClassType, NumBuildingNeeded FROM Building_PrereqBuildingClasses WHERE BuildingType = 'BUILDING_GRAND_TEMPLE';

--Both overrides point at this civilization's buildings. The Garden row is re-inserted last on purpose:
--PMMMDataStorage.lua keeps the LAST "_PMMM_" override it reads as the civ's one unique building, and the UB
--bootstrapper loads PMMMUltimateMadokaBuilding.lua only when that is BUILDING_PMMM_LUMINOUS_GARDEN.
DELETE FROM Civilization_BuildingClassOverrides
WHERE CivilizationType = 'CIVILIZATION_MADOKA' AND BuildingClassType IN ('BUILDINGCLASS_GARDEN', 'BUILDINGCLASS_GRAND_TEMPLE');

INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType)
VALUES ('CIVILIZATION_MADOKA', 'BUILDINGCLASS_GRAND_TEMPLE', 'BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE');

INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType)
VALUES ('CIVILIZATION_MADOKA', 'BUILDINGCLASS_GARDEN', 'BUILDING_PMMM_LUMINOUS_GARDEN');


--------------------------------------------------------------------------------------------------------------
-- Ultimate Madoka: city names (design section 2)
-- The capital is the Realm of Cycles (same row, so it stays first). Every named Witch joins the list, Homulilly
-- excepted. The six "ADDON" Witches in Cities-english.xml never reached the list, because
-- UltimateMadokaCivilization.sql selects them before that text file loads; the five that are not Homulilly are
-- added here, with the four canon Witches the mod had no city name for (Charlotte, Oktavia, Candeloro, Ophelia).
-- WitchNames_en_US.xml / Witch_GenericNames hold only the 97 generic, rune-spelled names the mod gives random
-- Witches (Addilyn, Adley, ...); those are not named Witches and are left out.
--------------------------------------------------------------------------------------------------------------
UPDATE Civilization_CityNames SET CityName = 'TXT_KEY_CITY_NAME_UMADOKA_REALM_OF_CYCLES'
WHERE CivilizationType = 'CIVILIZATION_MADOKA' AND CityName = 'TXT_KEY_CITY_NAME_MADOMAGI_MADOKAS_REALM';

DELETE FROM Civilization_CityNames
WHERE CivilizationType = 'CIVILIZATION_MADOKA' AND CityName = 'TXT_KEY_CITY_NAME_MADOKA_ADDON_3';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_CITY_NAME_UMADOKA_REALM_OF_CYCLES', 'Realm of Cycles'),
	('TXT_KEY_CITY_NAME_UMADOKA_CHARLOTTE', 'Charlotte'),
	('TXT_KEY_CITY_NAME_UMADOKA_OKTAVIA', 'Oktavia'),
	('TXT_KEY_CITY_NAME_UMADOKA_CANDELORO', 'Candeloro'),
	('TXT_KEY_CITY_NAME_UMADOKA_OPHELIA', 'Ophelia');

INSERT INTO Civilization_CityNames (CivilizationType, CityName)
SELECT 'CIVILIZATION_MADOKA', Tag FROM Language_en_US
WHERE Tag IN ('TXT_KEY_CITY_NAME_MADOKA_ADDON_1', 'TXT_KEY_CITY_NAME_MADOKA_ADDON_2', 'TXT_KEY_CITY_NAME_MADOKA_ADDON_4',
			'TXT_KEY_CITY_NAME_MADOKA_ADDON_5', 'TXT_KEY_CITY_NAME_MADOKA_ADDON_6',
			'TXT_KEY_CITY_NAME_UMADOKA_CHARLOTTE', 'TXT_KEY_CITY_NAME_UMADOKA_OKTAVIA', 'TXT_KEY_CITY_NAME_UMADOKA_CANDELORO',
			'TXT_KEY_CITY_NAME_UMADOKA_OPHELIA')
AND NOT EXISTS (SELECT 1 FROM Civilization_CityNames c WHERE c.CivilizationType = 'CIVILIZATION_MADOKA' AND c.CityName = Language_en_US.Tag)
ORDER BY Tag;


--------------------------------------------------------------------------------------------------------------
-- Text for the above, the Herald's Lead Away (5 turns at Standard, free promotion; Lua in
-- UniqueUnits/PMMMHeraldOfMadoka.lua) and the trait (Great Person Golden Age points, ruling 9)
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_TRAIT_NO_WITCHES', 'Magical Girls cannot become Witches. Instead the Law of Cycles leads them away, and after 10 turns (at Standard speed) they return to the [ICON_CAPITAL] Capital with a full [ICON_PMMM_SOUL_GEM] Soul Gem. They lose their Promotions but come back with 100 XP for every Promotion they had earned, and can never earn XP again. A returned Magical Girl may [COLOR_POSITIVE_TEXT]Summon the Herald of the Cycle[ENDCOLOR] at will for +20% [ICON_STRENGTH] Combat Strength.[NEWLINE][NEWLINE]Expending a [ICON_GREAT_PEOPLE] Great Person grants 50 [ICON_GOLDEN_AGE] Golden Age points per Era (50 in the Ancient Era, 400 in the Information Era, at Standard speed).'),

	('TXT_KEY_PROMOTION_PMMM_CYCLE_RETURNED', 'Returned from the Cycle'),
	('TXT_KEY_PROMOTION_PMMM_CYCLE_RETURNED_HELP', 'Reborn through the Law of Cycles with 100 XP for every Promotion she had earned. She can never earn XP again (-100% XP). May Summon the Herald of the Cycle at will for +20% [ICON_STRENGTH] Combat Strength.'),
	('TXT_KEY_PROMOTION_PMMM_WITCH_FORM', 'Herald of the Cycle'),
	('TXT_KEY_PROMOTION_PMMM_WITCH_FORM_HELP', '+20% [ICON_STRENGTH] Combat Strength. She has summoned the Herald of the Cycle, and may dismiss it again at any time.'),

	('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM', 'Summon Herald of the Cycle'),
	('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM_HELP', 'Summon or dismiss this Magical Girl''s Herald of the Cycle. While it is summoned she has +20% [ICON_STRENGTH] Combat Strength.[NEWLINE][NEWLINE]No cost, no target, and it does not use her turn. Only Magical Girls reborn from the Law of Cycles can summon it.'),
	('TXT_KEY_MISSION_PMMM_SUMMON_WITCH_FORM_DISABLED', 'Only a Magical Girl reborn from the Law of Cycles can summon the Herald of the Cycle.'),

	('TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_XP', 'She returns with {1_Num} XP, 100 for each of the {2_Num} Promotions she had earned, and can never earn XP again. She may Summon the Herald of the Cycle at will for +20% [ICON_STRENGTH] Combat Strength.'),
	('TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_FREE_PROMOTION', 'Led away by a Herald of Madoka, she also receives one extra Promotion of your choice.'),
	('TXT_KEY_PMMM_NOTIFICATION_TAKEN_BY_LOC_TEXT', '{1_Str} was nearly overcome by her despair. Fortunately, you were there to take away her suffering and lead her back to your realm. After {2_Num} turns, she will have recovered from her despair and will rise once again to fight for the salvation of the world''s Magical Girls. She will lose her Promotions, but return with 100 XP for each one she had earned.'),
	('TXT_KEY_PMMM_ALERT_UMADOKA_GP_GOLDEN_AGE', '+{1_Num} [ICON_GOLDEN_AGE] Golden Age points from expending a Great Person.'),

	('TXT_KEY_MISSION_PMMM_LEAD_AWAY_HELP', 'Target an adjacent enemy Magical Girl whose [ICON_PMMM_SOUL_GEM] Soul Gem is in a Critical State. The Law of Cycles leads her away, and after 5 turns (at Standard speed) she returns under your control, in your [ICON_CAPITAL] Capital. She loses her Promotions but returns with 100 XP for each one she had earned, plus one extra Promotion of your choice. Leader Magical Girls can never be led away. Consumes the Herald.'),
	('TXT_KEY_UNIT_PMMM_HERALD_OF_MADOKA_HELP', 'Unique replacement for the Missionary, which only Ultimate Madoka can create. +1 [ICON_MOVES] Movement and no sight penalty. May use the "Lead Away" command on an adjacent enemy Magical Girl (never a Leader Magical Girl) whose Soul Gem is in Critical condition: she returns under your control after 5 turns (at Standard speed) with 100 XP per earned Promotion and one extra Promotion of your choice.'),
	('TXT_KEY_UNIT_PMMM_HERALD_OF_MADOKA_STRATEGY', 'The Herald of Madoka is the Unique Unit for Madoka''s Realm, replacing the Missionary. Compared to a regular Missionary, they have an additional point of Movement and do not have a penalty to sight. Additionally, if they have not used their ability to spread religion yet, they may use "Lead Away," a command accessible from the Unit action panel. It can only be used on an adjacent enemy Magical Girl whose Soul Gem is in Critical condition, and never on a Leader Magical Girl. This leads the girl away via the Law of Cycles; after 5 turns (at Standard speed) she returns under your control with a full Soul Gem, 100 XP for every Promotion she had earned and one extra Promotion of your choice. Doing this consumes the Unit.'),
	('TXT_KEY_PROMOTION_PMMM_HERALD_OF_MADOKA_HELP', 'This benevolent Magical Girl has two duties: to spread the word of Madoka, and to help lead away Magical Girls via the Law of Cycles in places she cannot reach. [COLOR_POSITIVE_TEXT]+1 [ICON_MOVES] Movement and no sight penalty[ENDCOLOR]. May use the "[COLOR_POSITIVE_TEXT]Lead Away[ENDCOLOR]" command on an adjacent enemy Magical Girl (never a Leader Magical Girl) whose Soul Gem is Critical: she returns under your control after 5 turns (at Standard speed) with one extra Promotion of your choice.'),

	('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE', 'Luminous Garden (Grand Temple)'),
	('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE_HELP', '+8 [ICON_HAPPINESS_1] Happiness and +25% [ICON_GREAT_PEOPLE] Prodigy birth rate in this City. Triples religious pressure emanating from this City.[NEWLINE][NEWLINE]While you own it, every one of your Magical Girls recovers 1% of her [ICON_PMMM_SOUL_GEM] Soul Gem luster every turn and has +10 Mood.[NEWLINE][NEWLINE]Must be built in a Holy City. Must have built a Temple in all Cities. The cost goes up the more cities there are in the empire.'),
	('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE_STRATEGY', 'Ultimate Madoka''s Grand Temple is a second Luminous Garden. On top of the Grand Temple''s [ICON_PEACE] Faith it gives +8 [ICON_HAPPINESS_1] Happiness and +25% [ICON_GREAT_PEOPLE] Prodigy birth rate, triples the religious pressure of the Holy City instead of doubling it, and lets every one of her Magical Girls recover 1% [ICON_PMMM_SOUL_GEM] Soul Gem every turn with a permanent +10 Mood.'),
	('TXT_KEY_BUILDING_PMMM_LUMINOUS_GARDEN_HELP', '+25% [ICON_GREAT_PEOPLE] Prodigy birth rate in this City.[NEWLINE][NEWLINE]Magical Girls which are stationed in a City containing a Luminous Garden will recover 1% of their [ICON_PMMM_SOUL_GEM] Soul Gem luster every turn.[NEWLINE][NEWLINE]Must be built next to a River or a Lake.[NEWLINE][NEWLINE]Ultimate Madoka''s Grand Temple is also a Luminous Garden: see Luminous Garden (Grand Temple).');


--------------------------------------------------------------------------------------------------------------
-- Ruling 15.3 (2026-09-18): the old Summon Witch is removed.
-- MISSION_PMMM_SUMMON_WITCH / MISSION_PMMM_DISMISS_WITCH spawned and dismissed a Witch unit. CanSummonWitches = 0
-- closes every gate in PMMMUltimateMadokaTrait.lua, whose handlers are now inert as well (the missions are never
-- possible, never started, and the AI never summons). The two Missions rows stay: SQL/UltimateMadoka/
-- UltimateMadokaMissions.sql inserts them, XML/Text/UserInterface-english.xml carries their text, and
-- MagicalGirlMissionHandler.lua still names the SUMMON_WITCH exec string. With the gate closed, nothing offers them.
--------------------------------------------------------------------------------------------------------------
UPDATE Traits SET CanSummonWitches = 0
WHERE Type = 'TRAIT_NO_WITCHES';


--------------------------------------------------------------------------------------------------------------
-- Ruling 15.4 (2026-09-18): no free starting Archer. It made up for her having no Leader Magical Girl, which
-- she has now. The free Settler stays. No text mentioned the Archer.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Civilization_FreeUnits
WHERE CivilizationType = 'CIVILIZATION_MADOKA' AND UnitClassType = 'UNITCLASS_ARCHER';
