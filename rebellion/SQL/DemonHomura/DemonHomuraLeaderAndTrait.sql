--All SQL Leader inserts were based off of SQL code from JFD's Civilizations.

--*******************************************************************
-- Demon Homura
--*******************************************************************

INSERT INTO Leaders 
			(Type, 						Description, 						Civilopedia, 								CivilopediaTag, 								ArtDefineTag,				VictoryCompetitiveness, WonderCompetitiveness, 	MinorCivCompetitiveness, 	Boldness, 	DiploBalance, 	WarmongerHate, 	DenounceWillingness, 	DoFWillingness, Loyalty, 	Neediness, 	Forgiveness, 	Chattiness, Meanness, 	IconAtlas, 							PortraitIndex)
VALUES		('LEADER_DEMON_HOMURA', 	'TXT_KEY_LEADER_DEMON_HOMURA', 	'TXT_KEY_LEADER_DEMON_HOMURA_PEDIA', 	'TXT_KEY_CIVILOPEDIA_LEADERS_DEMON_HOMURA', 	'HomuraRebellionScene.xml',			9,						2, 						2, 							10, 		5, 				7, 				2, 						2, 				1, 			4, 			0, 				1, 			12, 		'CIV_COLOR_ATLAS_DEMON_HOMURA', 	1);


--*******************************************************************
-- Attitudes toward Civilizations
--*******************************************************************
INSERT INTO Leader_MajorCivApproachBiases 
			(LeaderType, 			MajorCivApproachType, 				Bias)
VALUES		('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_WAR', 			10),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_HOSTILE', 		10),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_DECEPTIVE', 	4),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_GUARDED', 		8),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_AFRAID', 		1),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_FRIENDLY', 		2),
			('LEADER_DEMON_HOMURA', 	'MAJOR_CIV_APPROACH_NEUTRAL', 		2);

--*******************************************************************
-- Attitudes toward City-States
--*******************************************************************
INSERT INTO Leader_MinorCivApproachBiases 
			(LeaderType, 			MinorCivApproachType, 				Bias)
VALUES		('LEADER_DEMON_HOMURA', 	'MINOR_CIV_APPROACH_IGNORE', 		7),
			('LEADER_DEMON_HOMURA', 	'MINOR_CIV_APPROACH_FRIENDLY', 		2),
			('LEADER_DEMON_HOMURA', 	'MINOR_CIV_APPROACH_PROTECTIVE', 	2),
			('LEADER_DEMON_HOMURA', 	'MINOR_CIV_APPROACH_CONQUEST', 		8),
			('LEADER_DEMON_HOMURA', 	'MINOR_CIV_APPROACH_BULLY', 		6);

--*******************************************************************
-- Flavors
--*******************************************************************
INSERT INTO Leader_Flavors 
			(LeaderType, 			FlavorType, 						Flavor)
VALUES		('LEADER_DEMON_HOMURA', 	'FLAVOR_OFFENSE', 					10),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_DEFENSE', 					6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_CITY_DEFENSE', 				4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_MILITARY_TRAINING', 		6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_RECON', 					3),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_RANGED', 					7),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_MOBILE', 					6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_NAVAL', 					6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_NAVAL_RECON', 				4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_NAVAL_GROWTH', 				4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_NAVAL_TILE_IMPROVEMENT', 	6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_AIR', 						5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_EXPANSION', 				7),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_GROWTH', 					4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_TILE_IMPROVEMENT', 			6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_INFRASTRUCTURE', 			4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_PRODUCTION', 				6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_GOLD', 						5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_SCIENCE', 					6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_CULTURE', 					2),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_HAPPINESS', 				6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_GREAT_PEOPLE', 				1),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_WONDER', 					1),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_RELIGION', 					1),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_DIPLOMACY', 				1),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_SPACESHIP', 				6),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_WATER_CONNECTION', 			5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_NUKE', 						10),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_USE_NUKE', 					10),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_ESPIONAGE', 				7),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_ANTIAIR',	 				4),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_AIR_CARRIER', 				7),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_I_TRADE_DESTINATION', 		5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_I_TRADE_ORIGIN', 			5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_I_SEA_TRADE_ROUTE', 		5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_I_LAND_TRADE_ROUTE', 		5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_ARCHAEOLOGY', 				5),
			('LEADER_DEMON_HOMURA', 	'FLAVOR_AIRLIFT', 					5);


--*******************************************************************
-- Trait Definition (Lovevil)
--*******************************************************************
INSERT INTO Traits
			(Type,										 Description,										 ShortDescription,																		
			HappinessToMetEnemies,	UnhappinessPerCivilizationMet,	YieldBonusPerCivilizationMet)
VALUES		('TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS', 'TXT_KEY_TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS', 'TXT_KEY_TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS_SHORT',
			5,						10,								5);


--*******************************************************************
-- Trait Assignment
--*******************************************************************

INSERT INTO Leader_Traits 
			(LeaderType, 			TraitType)
VALUES		('LEADER_DEMON_HOMURA', 	'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS');



--*********************************************************************************
--BuildingClasses (dummies)
--*********************************************************************************
INSERT INTO BuildingClasses
			(Type,													DefaultBuilding,	NoLimit)
VALUES		('BUILDINGCLASS_PMMM_DEMON_HOMURA_DUMMY_UNHAPPINESS',	'NO_BUILDING',		1),
			('BUILDINGCLASS_PMMM_DEMON_HOMURA_DUMMY_YIELDS',		'NO_BUILDING',		1),
			('BUILDINGCLASS_PMMM_DEMON_HOMURA_ENEMY_HAPPINESS',		'NO_BUILDING',		1);


--Dummies
INSERT INTO Buildings
			(Type,													BuildingClass,	
			Cost,	FaithCost,	GreatWorkCount, PrereqTech, NeverCapture,	NukeImmune)
VALUES		('BUILDING_PMMM_DEMON_HOMURA_DUMMY_UNHAPPINESS',		'BUILDINGCLASS_PMMM_DEMON_HOMURA_DUMMY_UNHAPPINESS',
			-1,		-1,			-1,				'NULL',		1,				1),
			('BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS',		'BUILDINGCLASS_PMMM_DEMON_HOMURA_DUMMY_YIELDS',
			-1,		-1,			-1,				'NULL',		1,				1),
			('BUILDING_PMMM_DEMON_HOMURA_DUMMY_ENEMY_HAPPINESS',		'BUILDINGCLASS_PMMM_DEMON_HOMURA_ENEMY_HAPPINESS',
			-1,		-1,			-1,				'NULL',		1,				1);

UPDATE Buildings
SET UnhappinessModifier = 1
WHERE Type = 'BUILDING_PMMM_DEMON_HOMURA_DUMMY_UNHAPPINESS';

UPDATE Buildings
SET UnmoddedHappiness = 1
WHERE Type = 'BUILDING_PMMM_DEMON_HOMURA_DUMMY_ENEMY_HAPPINESS';



--*********************************************************************************
--Building_YieldModifiers
--*********************************************************************************
INSERT INTO Building_YieldModifiers
			(BuildingType,								YieldType,			Yield)
VALUES		('BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS',	'YIELD_CULTURE',	1),
			('BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS',	'YIELD_PRODUCTION',	1),
			('BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS',	'YIELD_SCIENCE',	1),
			('BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS',	'YIELD_GOLD',		1);
