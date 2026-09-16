------------------------------------------------------------------------------------------------------------------------------------------------------------
--		DecisionsAddin_Support
------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO DecisionsAddin_Support
			(FileName)
VALUES		('PMMMMadokaDecisions.lua'),
			('PMMMDemonHomuraDecisions.lua'),
			('PMMMHomuraDecisions.lua'),
			('PMMMKyoukoDecisions.lua'),
			('PMMMMamiDecisions.lua'),
			('PMMMNagisaDecisions.lua'),
			('PMMMSayakaDecisions.lua'),
			('PMMMUltimateMadokaDecisions.lua'),
			('PMMMChurchCultDecisions.lua');

------------------------------------------------------------------------------------------------------------------------------------------------------------
--		IconTextureAtlases
------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO IconTextureAtlases 
			(Atlas, 								IconSize, 	Filename, 							IconsPerRow, 	IconsPerColumn)
VALUES		('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	256,		'DecisionsCharlotte256.dds',		1,				1),
			('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	128,		'DecisionsCharlotte128.dds',		1,				1),
			('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	80,			'DecisionsCharlotte80.dds',			1,				1),
			('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	64,			'DecisionsCharlotte64.dds',			1,				1),
			('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	45,			'DecisionsCharlotte45.dds',			1,				1),
			('CIV_COLOR_ATLAS_DECISIONS_NAGISA',	32,			'DecisionsCharlotte32.dds',			1,				1),
			('RESOURCE_ATLAS_DECISIONS_ROCKY',		256,		'DecisionsKyoukoRocky256.dds',		1,				1);

INSERT INTO IconFontTextures
			(IconFontTexture,								IconFontTextureFile)
VALUES		('ICON_FONT_TEXTURE_RESOURCE_DECISIONS_ROCKY',	'DecisionsKyoukoRockyIcon');

INSERT INTO IconFontMapping
			(IconName,				IconFontTexture,								IconMapping)
VALUES		('ICON_RES_PMMM_ROCKY',	'ICON_FONT_TEXTURE_RESOURCE_DECISIONS_ROCKY',	1);

------------------------------------------------------------------------------------------------------------------------------------------------------------
--		Buildings/BuildingClasses
------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO BuildingClasses
			(Type,													DefaultBuilding,								NoLimit)
VALUES		('BUILDINGCLASS_DECISION_ORIGINAL_MADOKA_DUMMY',		'BUILDING_DECISION_ORIGINAL_MADOKA_DUMMY',		0),
			('BUILDINGCLASS_DECISION_DEMON_HOMURA_INCUBATOR',		'BUILDING_DECISION_DEMON_HOMURA_INCUBATOR',		1),
			('BUILDINGCLASS_DECISION_DEMON_HOMURA_PACIFY_SELF',		'BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',	1),
			('BUILDINGCLASS_DECISION_DEMON_HOMURA_PACIFY_OTHERS',	'BUILDING_DECISION_DEMON_HOMURA_PACIFY_OTHERS',	1),
			('BUILDINGCLASS_DECISION_SAYAKA_DUMMY',					'BUILDING_DECISION_SAYAKA_DUMMY',				0),
			('BUILDINGCLASS_DECISIONS_NAGISA_CHARLOTTE_GATE',		'BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE',		0),
			('BUILDINGCLASS_DECISIONS_KYOUKO_DEVELOP_ROCKY',		'BUILDING_DECISIONS_KYOUKO_DEVELOP_ROCKY', 		0),
			('BUILDINGCLASS_DECISIONS_HOMURA_DEVOTE_MADOKA',		'BUILDING_DECISIONS_HOMURA_DEVOTE_MADOKA', 		0),
			('BUILDINGCLASS_DECISIONS_MAMI_DUMMY',					'BUILDING_DECISIONS_MAMI_DUMMY',				0);


INSERT INTO Buildings
			(Type, Description, Civilopedia, Strategy, Help, ThemingBonusHelp, Quote, GoldMaintenance, MutuallyExclusiveGroup, TeamShare, Water, River, 
			FreshWater, Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious, BorderObstacle, PlayerBorderObstacle, Capital, GoldenAge, 
			MapCentering, NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting, AffectSpiesNow, NullifyInfluenceModifier, Cost, FaithCost, 
			LeagueCost, UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod, HurryCostModifier, MinAreaSize, ConquestProb, CitiesPrereq, LevelPrereq, 
			CultureRateModifier, GlobalCultureRateModifier, GreatPeopleRateModifier, GlobalGreatPeopleRateModifier, GreatGeneralRateModifier, GreatPersonExpendGold,
			GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience, FoodKept, Airlift, AirModifier, NukeModifier, NukeExplosionRand, HealRateChange, 
			Happiness, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity, HappinessPerXPolicies, CityCountUnhappinessMod, NoOccupiedUnhappiness, 
			WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier, GlobalSpaceProductionModifier, BuildingProductionModifier, WonderProductionModifier,
			CityConnectionTradeRouteModifier, CapturePlunderModifier, PolicyCostModifier, PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier,
			GlobalPlotBuyCostModifier, GlobalPopulationChange, TechShare, FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike,
			Espionage, AllowsFoodTradeRoutes, AllowsProductionTradeRoutes, Defense, ExtraCityHitPoints, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints,
			ExtraMissionarySpreads, ReligiousPressureModifier, EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange,
			TradeRouteRecipientBonus, TradeRouteTargetBonus, NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier,
			XBuiltTriggersIdeologyChoice, TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus,
			CityStateTradeRouteProductionModifier, GreatScientistBeakerModifier, BuildingClass, ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain, VictoryPrereq,
			FreeStartEra, MaxStartEra, ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion, TrainedFreePromotion,
			FreePromotionRemoved, ReplacementBuildingClass, PrereqTech, PolicyBranchType, SpecialistType, SpecialistCount, GreatWorkSlotType, FreeGreatWork, GreatWorkCount,
			SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition, PortraitIndex, WonderSplashImage, WonderSplashAnchor,
			WonderSplashAudio, IconAtlas, ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation)
SELECT		('BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE'), ('TXT_KEY_BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE'), ('TXT_KEY_BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE_TEXT'), ('TXT_KEY_BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE_STRATEGY'),
			('TXT_KEY_BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE_HELP'), ThemingBonusHelp, Quote, 0, MutuallyExclusiveGroup, TeamShare, Water, River, 
			FreshWater, Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious, BorderObstacle, PlayerBorderObstacle, Capital, GoldenAge, 
			MapCentering, NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting, AffectSpiesNow, NullifyInfluenceModifier, -1, -1, 
			LeagueCost, UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod, HurryCostModifier, MinAreaSize, ConquestProb, CitiesPrereq, LevelPrereq, 
			CultureRateModifier, GlobalCultureRateModifier, GreatPeopleRateModifier, GlobalGreatPeopleRateModifier, GreatGeneralRateModifier, GreatPersonExpendGold,
			GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience, FoodKept, Airlift, AirModifier, NukeModifier, NukeExplosionRand, HealRateChange, 
			Happiness, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity, HappinessPerXPolicies, CityCountUnhappinessMod, NoOccupiedUnhappiness, 
			WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier, GlobalSpaceProductionModifier, BuildingProductionModifier, WonderProductionModifier,
			CityConnectionTradeRouteModifier, CapturePlunderModifier, PolicyCostModifier, PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier,
			GlobalPlotBuyCostModifier, GlobalPopulationChange, TechShare, FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike,
			Espionage, AllowsFoodTradeRoutes, AllowsProductionTradeRoutes, Defense*0.4, ExtraCityHitPoints*0.5, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints,
			ExtraMissionarySpreads, ReligiousPressureModifier, EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange,
			TradeRouteRecipientBonus, TradeRouteTargetBonus, NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier,
			XBuiltTriggersIdeologyChoice, TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus,
			CityStateTradeRouteProductionModifier, GreatScientistBeakerModifier, ('BUILDINGCLASS_DECISIONS_NAGISA_CHARLOTTE_GATE'), ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain, VictoryPrereq,
			FreeStartEra, MaxStartEra, ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion, TrainedFreePromotion,
			FreePromotionRemoved, ReplacementBuildingClass, (null), PolicyBranchType, SpecialistType, SpecialistCount, GreatWorkSlotType, FreeGreatWork, GreatWorkCount,
			SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition, 0, WonderSplashImage, WonderSplashAnchor,
			WonderSplashAudio, ('CIV_COLOR_ATLAS_DECISIONS_NAGISA'), ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation
FROM Buildings WHERE (Type = 'BUILDING_WALLS');

INSERT INTO Buildings
			(Type,										BuildingClass,	
			Cost,	FaithCost,	GreatWorkCount, PrereqTech, NeverCapture,	NukeImmune,
			EnhancedYieldTech, TechEnhancedTourism)
VALUES		('BUILDING_DECISION_ORIGINAL_MADOKA_DUMMY',		'BUILDINGCLASS_DECISION_ORIGINAL_MADOKA_DUMMY',
			-1,		-1,			-1,				'NULL',		1,				1,
			'TECH_COMBUSTION', 2);

INSERT INTO Buildings
			(Type,												BuildingClass,	
			Cost,	FaithCost,	GreatWorkCount, PrereqTech, NeverCapture,	NukeImmune,
			UnmoddedHappiness)
VALUES		('BUILDING_DECISION_DEMON_HOMURA_INCUBATOR',		'BUILDINGCLASS_DECISION_DEMON_HOMURA_INCUBATOR',
			-1,		-1,			-1,				null,		1,				1,
			1),
			('BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',		'BUILDINGCLASS_DECISION_DEMON_HOMURA_PACIFY_SELF',
			-1,		-1,			-1,				null,		1,				1,
			0),
			('BUILDING_DECISION_DEMON_HOMURA_PACIFY_OTHERS',		'BUILDINGCLASS_DECISION_DEMON_HOMURA_PACIFY_OTHERS',
			-1,		-1,			-1,				null,		1,				1,
			1);

INSERT INTO Building_YieldModifiers
			(BuildingType,									YieldType,			Yield)
VALUES		('BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',	'YIELD_CULTURE',	1),
			('BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',	'YIELD_PRODUCTION',	1),
			('BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',	'YIELD_SCIENCE',	1),
			('BUILDING_DECISION_DEMON_HOMURA_PACIFY_SELF',	'YIELD_GOLD',		1);

INSERT INTO Buildings
			(Type,										BuildingClass,	
			Cost,	FaithCost,	GreatWorkCount, PrereqTech, NeverCapture,	NukeImmune,
			LandmarksTourismPercent, GreatWorksTourismModifier)
VALUES		('BUILDING_DECISION_SAYAKA_DUMMY',		'BUILDINGCLASS_DECISION_SAYAKA_DUMMY',
			-1,		-1,			-1,				'NULL',		1,				1,
			100, 100);

INSERT INTO Buildings 	
			(Type, 						 					BuildingClass, 									Description,										Civilopedia,
			Help,													Strategy,			Cost,	PrereqTech, 	ConquestProb,	IconAtlas, 		PortraitIndex)
VALUES		('BUILDING_DECISIONS_KYOUKO_DEVELOP_ROCKY', 	'BUILDINGCLASS_DECISIONS_KYOUKO_DEVELOP_ROCKY',	'TXT_KEY_DECISIONS_BUILDING_KYOUKO_DEVELOP_ROCKY',	'TXT_KEY_DECISIONS_BUILDING_KYOUKO_DEVELOP_ROCKY_CIVILOPEDIA',
			'TXT_KEY_DECISIONS_BUILDING_KYOUKO_DEVELOP_ROCKY_HELP',	null,				-1,  	null,			100,			'BW_ATLAS_1',	0);

INSERT INTO Building_ResourceQuantity
			(BuildingType, 									ResourceType,				Quantity)
VALUES		('BUILDING_DECISIONS_KYOUKO_DEVELOP_ROCKY', 	'RESOURCE_DECISIONS_ROCKY',	3);

INSERT INTO Building_YieldChanges
			(BuildingType,									YieldType,			Yield)
VALUES		('BUILDING_DECISIONS_KYOUKO_DEVELOP_ROCKY', 	'YIELD_FOOD',		2);


INSERT INTO Buildings 	
			(Type, 						 					BuildingClass, 									Description,										Civilopedia,													
			Help,													Strategy,			Cost,	PrereqTech, 	ConquestProb,	IconAtlas, 						PortraitIndex,	UnhappinessModifier)
VALUES		('BUILDING_DECISIONS_HOMURA_DEVOTE_MADOKA', 	'BUILDINGCLASS_DECISIONS_HOMURA_DEVOTE_MADOKA',	'TXT_KEY_DECISIONS_BUILDING_HOMURA_DEVOTE_MADOKA',	'TXT_KEY_DECISIONS_BUILDING_HOMURA_DEVOTE_MADOKA_CIVILOPEDIA',	
			'TXT_KEY_DECISIONS_BUILDING_HOMURA_DEVOTE_MADOKA_HELP',	null,				-1,  	null,			100,			'CIV_COLOR_ATLAS_MADOKA_TEMP',	3,				10);


INSERT INTO Building_BuildingClassYieldChanges
			(BuildingType, 									BuildingClassType,			YieldType, 				YieldChange)
VALUES		('BUILDING_DECISIONS_HOMURA_DEVOTE_MADOKA', 	'BUILDINGCLASS_MONUMENT',	'YIELD_FAITH', 			2);

INSERT INTO Buildings
			(Type,										BuildingClass,	
			Cost,	FaithCost,	GreatWorkCount, PrereqTech, NeverCapture,	NukeImmune)
VALUES		('BUILDING_DECISIONS_MAMI_DUMMY',		'BUILDINGCLASS_DECISIONS_MAMI_DUMMY',
			-1,		-1,			-1,				null,		1,				1);

------------------------------------------------------------------------------------------------------------------------------------------------------------
--		Promotions
------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry,
			RangedSupportFire,		CombatPercent)
SELECT		('PROMOTION_DECISIONS_MADOKA'),		('TXT_KEY_PROMOTION_DECISIONS_MADOKA'),('TXT_KEY_PROMOTION_DECISIONS_MADOKA_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_DECISIONS_MADOKA'),
			1,						33
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry,
			ExtraAttacks,		CombatPercent)
SELECT		('PROMOTION_DECISIONS_SAYAKA'),		('TXT_KEY_PROMOTION_DECISIONS_SAYAKA'),('TXT_KEY_PROMOTION_DECISIONS_SAYAKA_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_DECISIONS_SAYAKA'),
			1,					15
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry,
			NearbyEnemyCombatMod,	NearbyEnemyCombatRange)
SELECT		('PROMOTION_DECISIONS_NAGISA'),		('TXT_KEY_PROMOTION_DECISIONS_NAGISA'),('TXT_KEY_PROMOTION_DECISIONS_NAGISA_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_DECISIONS_NAGISA'),
			-10,					1
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');


------------------------------------------------------------------------------------------------------------------------------------------------------------
--		Dummy Policies
------------------------------------------------------------------------------------------------------------------------------------------------------------


INSERT INTO Policies
			(Type,										Description,								CityGrowthMod)
VALUES		('POLICY_DECISIONS_MADOKA_YURI_VALHALLA',	'TXT_KEY_DECISIONS_MADOKA_YURI_VALHALLA',	10);

INSERT INTO Policy_BuildingClassHappiness
			(PolicyType,								BuildingClassType,		Happiness)
VALUES		('POLICY_DECISIONS_MADOKA_YURI_VALHALLA',	'BUILDINGCLASS_GARDEN',	3);


INSERT INTO Policies
			(Type,								Description)
VALUES		('POLICY_DECISIONS_NAGISA_RECESS',	'TXT_KEY_DECISIONS_NAGISA_RECESS');

INSERT INTO Policy_BuildingClassHappiness
			(PolicyType,						BuildingClassType,				Happiness)
VALUES		('POLICY_DECISIONS_NAGISA_RECESS',	'BUILDINGCLASS_PUBLIC_SCHOOL',	1);


INSERT INTO Policies
			(Type,										Description,								MinorFriendshipMinimum)
VALUES		('POLICY_DECISIONS_HOMURA_DEVOTE_MADOKA',	'TXT_KEY_DECISIONS_HOMURA_DEVOTE_MADOKA',	-5);

INSERT INTO Policies
			(Type,										Description)
VALUES		('POLICY_DECISIONS_MAMI_JAPANESE',			'TXT_KEY_DECISIONS_MAMI_JAPANESE'),
			('POLICY_DECISIONS_MAMI_ITALIAN',			'TXT_KEY_DECISIONS_MAMI_ITALIAN'),
			('POLICY_DECISIONS_MAMI_MAMMIE_DOCTRINE',	'TXT_KEY_DECISIONS_MAMI_MAMMIE_DOCTRINE');

UPDATE Policies
SET GreatWriterRateModifier = 25, GreatArtistRateModifier = 25, GreatMusicianRateModifier = 25
WHERE Type = 'POLICY_DECISIONS_MAMI_ITALIAN';

UPDATE Policies
SET GreatWriterRateModifier = -25, GreatArtistRateModifier = -25, GreatMusicianRateModifier = -25
WHERE Type = 'POLICY_DECISIONS_MAMI_JAPANESE';

UPDATE Policies
SET PolicyCostModifier = 10, MinorFriendshipMinimum = 10
WHERE Type = 'POLICY_DECISIONS_MAMI_MAMMIE_DOCTRINE';

INSERT INTO Policy_YieldModifiers
			(PolicyType,						YieldType,			Yield)
VALUES		('POLICY_DECISIONS_MAMI_JAPANESE',	'YIELD_SCIENCE',	10),
			('POLICY_DECISIONS_MAMI_JAPANESE',	'YIELD_CULTURE',	-20),
			('POLICY_DECISIONS_MAMI_ITALIAN',	'YIELD_SCIENCE',	-10),
			('POLICY_DECISIONS_MAMI_ITALIAN',	'YIELD_CULTURE',	20);

INSERT INTO Policy_BuildingClassTourismModifiers	
			(PolicyType,						BuildingClassType,						TourismModifier)
VALUES		('POLICY_DECISIONS_MAMI_JAPANESE',	'BUILDINGCLASS_DECISIONS_MAMI_DUMMY',	-20),
			('POLICY_DECISIONS_MAMI_ITALIAN',	'BUILDINGCLASS_DECISIONS_MAMI_DUMMY',	20);

INSERT INTO Policy_SpecialistExtraYields
			(PolicyType,						YieldType,			Yield)
VALUES		('POLICY_DECISIONS_MAMI_JAPANESE',	'YIELD_PRODUCTION',	1),
			('POLICY_DECISIONS_MAMI_ITALIAN',	'YIELD_CULTURE',	1);

UPDATE Traits
SET FreeBuilding = 'BUILDING_DECISIONS_MAMI_DUMMY'
WHERE Type = 'TRAIT_FRIENDSHIP_PRODUCTION_BONUS';

------------------------------------------------------------------------------------------------------------------------------------------------------------
--		Resources
------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO Resources 
			(Type,							Description,						Civilopedia, 									ResourceClassType,
			Happiness,  AITradeModifier, 	ResourceUsage,	AIObjective,	'Unique', 	IconString, 				PortraitIndex, 	IconAtlas)
VALUES		('RESOURCE_DECISIONS_ROCKY',	'TXT_KEY_RESOURCE_DECISIONS_ROCKY',	'TXT_KEY_CIV5_RESOURCE_DECISIONS_ROCKY_TEXT',	'RESOURCECLASS_LUXURY',
			4,			10,					2, 				0, 				2, 			'[ICON_RES_PMMM_ROCKY]',	0, 				'RESOURCE_ATLAS_DECISIONS_ROCKY');