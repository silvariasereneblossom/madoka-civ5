--=======================================================================================================================
-- Bingle's Civ IV Traits
--=======================================================================================================================
-- Leader_SharedTraits
------------------------------	
CREATE TABLE IF NOT EXISTS 
    Leader_SharedTraits (
    LeaderType          text    REFERENCES Leaders(Type)        default null,
    TraitOne            text    REFERENCES Policies(Type)       default null,
    TraitTwo            text    REFERENCES Policies(Type)       default null);
     
INSERT OR REPLACE INTO Leader_SharedTraits
            (LeaderType,				TraitOne,					TraitTwo)
VALUES      ('LEADER_ORIGINAL_MADOKA',	'POLICY_PHILOSOPHICAL_X',	'POLICY_PROTECTIVE_X'),
			('LEADER_HOMURA',			'POLICY_INDUSTRIOUS_X',		'POLICY_PROTECTIVE_X'),
			('LEADER_MAMI',				'POLICY_CHARISMATIC_X',		'POLICY_DIPLOMATIC_X'),
			('LEADER_SAYAKA',			'POLICY_PHILOSOPHICAL_X',	'POLICY_AGGRESSIVE_X'),
			('LEADER_KYOUKO',			'POLICY_EXPANSIVE_X',		'POLICY_SPIRITUAL_X'),
			('LEADER_NAGISA',			'POLICY_CHARISMATIC_X',		'POLICY_EXPANSIVE_X'),
			('LEADER_MADOKA',			'POLICY_SPIRITUAL_X',		'POLICY_PHILOSOPHICAL_X'),
			('LEADER_DEMON_HOMURA',		'POLICY_IMPERIALISTIC_X',	'POLICY_AGGRESSIVE_X');
------------------------------	
-- Leaders
------------------------------	
UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_ORIGINAL_MADOKA_C4T'
	ELSE 'TXT_KEY_LEADER_ORIGINAL_MADOKA' END) 
WHERE Description = 'TXT_KEY_LEADER_ORIGINAL_MADOKA';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_HOMURA_C4T'
	ELSE 'TXT_KEY_LEADER_HOMURA' END) 
WHERE Description = 'TXT_KEY_LEADER_HOMURA';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_MAMI_C4T'
	ELSE 'TXT_KEY_LEADER_MAMI' END) 
WHERE Description = 'TXT_KEY_LEADER_MAMI';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_SAYAKA_C4T'
	ELSE 'TXT_KEY_LEADER_SAYAKA' END) 
WHERE Description = 'TXT_KEY_LEADER_SAYAKA';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_KYOUKO_C4T'
	ELSE 'TXT_KEY_LEADER_KYOUKO' END) 
WHERE Description = 'TXT_KEY_LEADER_KYOUKO';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_NAGISA_C4T'
	ELSE 'TXT_KEY_LEADER_NAGISA' END) 
WHERE Description = 'TXT_KEY_LEADER_NAGISA';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_MADOKA_C4T'
	ELSE 'TXT_KEY_LEADER_MADOKA' END) 
WHERE Description = 'TXT_KEY_LEADER_MADOKA';

UPDATE Leaders
SET Description = (CASE WHEN EXISTS(SELECT Type FROM Policies WHERE Type = 'POLICY_AGGRESSIVE_X' )
	THEN 'TXT_KEY_LEADER_DEMON_HOMURA_C4T'
	ELSE 'TXT_KEY_LEADER_DEMON_HOMURA' END) 
WHERE Description = 'TXT_KEY_LEADER_DEMON_HOMURA';


--==========================================================================================================================
-- BrutalSamurai's Ethnic Units/Gedemon's R.E.D.
--==========================================================================================================================

--This will, eventually, be a special unit group for all PMMM Civs which makes every unit model female. But that's a long, long way away...

-- Civilizations
------------------------------	
UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_BABYLON' )
	THEN '_BABYLON'
	ELSE '_MED' END) 
WHERE Type = 'CIVILIZATION_MADOKA';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_ASSYRIA' )
	THEN '_ASSYRIA'
	ELSE '_MED' END) 
WHERE Type = 'CIVILIZATION_DEMON_HOMURA';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_JAPAN' )
	THEN '_JAPAN'
	ELSE '_ASIA' END) 
WHERE Type = 'CIVILIZATION_ORIGINAL_MADOKA';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_KOREA' )
	THEN '_KOREA'
	ELSE '_ASIA' END) 
WHERE Type = 'CIVILIZATION_KYOUKO';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_CHINA' )
	THEN '_CHINA'
	ELSE '_ASIA' END) 
WHERE Type = 'CIVILIZATION_HOMURA';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_AUSTRIA' )
	THEN '_AUSTRIA'
	ELSE '_EURO' END) 
WHERE Type = 'CIVILIZATION_SAYAKA';

UPDATE Civilizations 
SET ArtStyleSuffix = (CASE WHEN EXISTS(SELECT ArtStyleSuffix FROM Civilizations WHERE ArtStyleSuffix = '_MONGOL' )
	THEN '_MONGOL'
	ELSE '_ASIA' END) 
WHERE Type = 'CIVILIZATION_NAGISA';

--==========================================================================================================================
-- Gedemon's YnAEMP
--==========================================================================================================================
-- Civilizations_YagemStartPosition (Earth Giant)
------------------------------------------------------------	

--This is the only one I care to make new start positions for; the others will just take directly from other Civs
CREATE TABLE IF NOT EXISTS Civilizations_YagemStartPosition(Type, X, Y, AltX, AltY);

INSERT INTO Civilizations_YagemStartPosition
			(Type,										X,		Y,		AltX,	AltY)
VALUES		('CIVILIZATION_MADOKA',						35,		51,		null,	null), --Jerusalem (symbolism!)
			('CIVILIZATION_HOMURA',						91,		56,		null,	null), --southwestern Honshu, where Kyushu should be
			('CIVILIZATION_SAYAKA',						24,		65,		null,	null), --Vienna
			('CIVILIZATION_MAMI',						21,		58,		null,	null), --Rome
			('CIVILIZATION_KYOUKO',						97,		68,		null,	null), --Hokkaido
			('CIVILIZATION_NAGISA',						68,		62,		null,	null), --western end of China, near present-day Kyrgystan. Why? So they can be a steppe tribe of cheese hoarders!
			('CIVILIZATION_ORIGINAL_MADOKA',			98,		63,		null,	null), --northern Honshu
			('CIVILIZATION_DEMON_HOMURA',				33,		56,		null,	null);


------------------------------------------------------------	
-- Civilizations_YahemStartPosition (Earth Huge)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MADOKA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_OTTOMAN');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_HOMURA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_CHINA');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_SAYAKA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_AUSTRIA');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MAMI'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_ROME');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_KYOUKO'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_KOREA');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_NAGISA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_MONGOL');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_JAPAN');

CREATE TABLE IF NOT EXISTS Civilizations_YahemStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_YahemStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	X,	Y
FROM Civilizations_YahemStartPosition WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_CordiformStartPosition (Earth Standard)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MADOKA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_OTTOMAN');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_HOMURA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_CHINA');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_SAYAKA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_AUSTRIA');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MAMI'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_ROME');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_KYOUKO'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_KOREA');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_NAGISA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_MONGOL');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_JAPAN');

CREATE TABLE IF NOT EXISTS Civilizations_CordiformStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_CordiformStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	X,	Y
FROM Civilizations_CordiformStartPosition WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_GreatestEarthStartPosition (Earth Greatest)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MADOKA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_OTTOMAN');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_HOMURA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_CHINA');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_SAYAKA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_AUSTRIA');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MAMI'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_ROME');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_KYOUKO'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_KOREA');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_NAGISA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_MONGOL');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_JAPAN');

CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_GreatestEarthStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	X,	Y
FROM Civilizations_GreatestEarthStartPosition WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_NorthAtlanticStartPosition (North Atlantic)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MADOKA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_OTTOMAN');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_HOMURA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_CHINA');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_SAYAKA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_AUSTRIA');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MAMI'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_ROME');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_KYOUKO'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_KOREA');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_NAGISA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_MONGOL');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_JAPAN');

CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_NorthAtlanticStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	X,	Y
FROM Civilizations_NorthAtlanticStartPosition WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_AmericasStartPosition (Americas)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MADOKA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_OTTOMAN');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_HOMURA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_CHINA');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_SAYAKA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_AUSTRIA');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_MAMI'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_ROME');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_KYOUKO'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_KOREA');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_NAGISA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_MONGOL');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_JAPAN');

CREATE TABLE IF NOT EXISTS Civilizations_AmericasStartPosition(Type, X, Y, AltX, AltY);
INSERT INTO Civilizations_AmericasStartPosition
			(Type,							X,	Y)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	X,	Y
FROM Civilizations_AmericasStartPosition WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_YagemRequestedResource (Earth Giant)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_YagemRequestedResource(Type, Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4);
INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_OTTOMAN');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_CHINA');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_SAYAKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_AUSTRIA');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MAMI'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_ROME');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_KYOUKO'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_KOREA');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_NAGISA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_MONGOL');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_JAPAN');

INSERT INTO Civilizations_YagemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YagemRequestedResource WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_YahemRequestedResource (Earth Huge)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_YahemRequestedResource(Type, Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4);
INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_OTTOMAN');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_CHINA');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_SAYAKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_AUSTRIA');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MAMI'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_ROME');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_KYOUKO'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_KOREA');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_NAGISA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_MONGOL');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_JAPAN');

INSERT INTO Civilizations_YahemRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_YahemRequestedResource WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_GreatestEarthRequestedResource (Earth Greatest)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_GreatestEarthRequestedResource(Type, Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4);
INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_OTTOMAN');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_CHINA');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_SAYAKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_AUSTRIA');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MAMI'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_ROME');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_KYOUKO'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_KOREA');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_NAGISA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_MONGOL');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_JAPAN');

INSERT INTO Civilizations_GreatestEarthRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_GreatestEarthRequestedResource WHERE (Type = 'CIVILIZATION_ASSYRIA');

------------------------------------------------------------	
-- Civilizations_AmericasRequestedResource (Americas)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_AmericasRequestedResource(Type, Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4);
INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_OTTOMAN');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_CHINA');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_SAYAKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_AUSTRIA');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MAMI'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_ROME');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_KYOUKO'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_KOREA');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_NAGISA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_MONGOL');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_JAPAN');

INSERT INTO Civilizations_AmericasRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_AmericasRequestedResource WHERE (Type = 'CIVILIZATION_ASSYRIA');
------------------------------------------------------------	
-- Civilizations_NorthAtlanticRequestedResource (North Atlantic)
------------------------------------------------------------	
CREATE TABLE IF NOT EXISTS Civilizations_NorthAtlanticRequestedResource(Type, Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4);
INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_OTTOMAN');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_CHINA');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_SAYAKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_AUSTRIA');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_MAMI'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_ROME');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_KYOUKO'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_KOREA');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_NAGISA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_MONGOL');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_ORIGINAL_MADOKA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_JAPAN');

INSERT INTO Civilizations_NorthAtlanticRequestedResource
			(Type, 						Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4)
SELECT		('CIVILIZATION_DEMON_HOMURA'),	Req1, Yield1, Req2, Yield2, Req3, Yield3, Req4, Yield4
FROM Civilizations_NorthAtlanticRequestedResource WHERE (Type = 'CIVILIZATION_ASSYRIA');

--==========================================================================================================================
-- Hazel's Map Labels
--==========================================================================================================================
-- ML_CivCultures
------------------------------	
CREATE TABLE IF NOT EXISTS ML_CivCultures (ID INTEGER PRIMARY KEY AUTOINCREMENT, CivType TEXT, CultureType TEXT, CultureEra TEXT DEFAULT 'ANY');
INSERT INTO ML_CivCultures
			(CivType,							CultureType,		CultureEra)
VALUES		('CIVILIZATION_ORIGINAL_MADOKA',	'PACIFIC',			'ANY'),
			('CIVILIZATION_HOMURA',				'PACIFIC',			'ANY'),
			('CIVILIZATION_MAMI',				'MEDITERRANEAN',	'ANY'),
			('CIVILIZATION_SAYAKA',				'GERMANIC',			'ANY'),
			('CIVILIZATION_KYOUKO',				'PACIFIC',			'ANY'),
			('CIVILIZATION_NAGISA',				'SLAVIC',			'ANY'),
			('CIVILIZATION_MADOKA',				'ARABIAN',			'ANY'),
			('CIVILIZATION_DEMON_HOMURA',		'ARABIAN',			'ANY');

--==========================================================================================================================
-- JFD's Cultural Diversity
--==========================================================================================================================
-- Civilization_JFD_CultureTypes
------------------------------	
CREATE TABLE IF NOT EXISTS 
Civilization_JFD_CultureTypes (
	CivilizationType 							text 	REFERENCES Civilizations(Type) 		default null,
	CultureType 								text										default null,
	SplashScreenTag								text										default	null,
	SoundtrackTag								text										default	null);

INSERT OR REPLACE INTO Civilization_JFD_CultureTypes
			(CivilizationType,					CultureType,		SplashScreenTag)
VALUES		('CIVILIZATION_MADOKA',				'JFD_Mesopotamic',	'JFD_Madoka'),
			('CIVILIZATION_HOMURA',				'JFD_Oriental',		'JFD_Madoka'),
			('CIVILIZATION_MAMI',				'JFD_Mediterranean','JFD_Madoka'),
			('CIVILIZATION_SAYAKA',				'JFD_Central',		'JFD_Madoka'),
			('CIVILIZATION_KYOUKO',				'JFD_Oriental',		'JFD_Madoka'),
			('CIVILIZATION_NAGISA',				'JFD_Steppe',		'JFD_Madoka'),
			('CIVILIZATION_ORIGINAL_MADOKA',	'JFD_Oriental',		'JFD_Madoka'),
			('CIVILIZATION_DEMON_HOMURA',		'JFD_Totalitarian',	'JFD_Madoka');


--the soundtrack is handled by the soundtrack mod!



--==========================================================================================================================
-- JFD's Exploration Continued Expanded
--==========================================================================================================================

-----------------------------	
-- Civilization_JFD_RevolutionaryCivilizationsToSpawn
------------------------------	
CREATE TABLE IF NOT EXISTS 
Civilization_JFD_RevolutionaryCivilizationsToSpawn (
	CivilizationType 							text 	REFERENCES Civilizations(Type) 		default null,
	RevolutionaryCivilizationType 				text 	REFERENCES Civilizations(Type) 		default null);
	
INSERT INTO Civilization_JFD_RevolutionaryCivilizationsToSpawn
			(CivilizationType,					RevolutionaryCivilizationType)
VALUES		('CIVILIZATION_MADOKA',				'CIVILIZATION_DEMON_HOMURA'),
			('CIVILIZATION_DEMON_HOMURA',		'CIVILIZATION_MADOKA'),

			('CIVILIZATION_ORIGINAL_MADOKA',	'CIVILIZATION_HOMURA'),
			('CIVILIZATION_ORIGINAL_MADOKA',	'CIVILIZATION_MAMI'),
			('CIVILIZATION_ORIGINAL_MADOKA',	'CIVILIZATION_SAYAKA'),
			('CIVILIZATION_ORIGINAL_MADOKA',	'CIVILIZATION_KYOUKO'),
			('CIVILIZATION_ORIGINAL_MADOKA',	'CIVILIZATION_NAGISA'),

			('CIVILIZATION_HOMURA',				'CIVILIZATION_ORIGINAL_MADOKA'),
			('CIVILIZATION_HOMURA',				'CIVILIZATION_MAMI'),
			('CIVILIZATION_HOMURA',				'CIVILIZATION_SAYAKA'),
			('CIVILIZATION_HOMURA',				'CIVILIZATION_KYOUKO'),
			('CIVILIZATION_HOMURA',				'CIVILIZATION_NAGISA'),

			('CIVILIZATION_MAMI',				'CIVILIZATION_ORIGINAL_MADOKA'),
			('CIVILIZATION_MAMI',				'CIVILIZATION_HOMURA'),
			('CIVILIZATION_MAMI',				'CIVILIZATION_SAYAKA'),
			('CIVILIZATION_MAMI',				'CIVILIZATION_KYOUKO'),
			('CIVILIZATION_MAMI',				'CIVILIZATION_NAGISA'),

			('CIVILIZATION_SAYAKA',				'CIVILIZATION_ORIGINAL_MADOKA'),
			('CIVILIZATION_SAYAKA',				'CIVILIZATION_HOMURA'),
			('CIVILIZATION_SAYAKA',				'CIVILIZATION_MAMI'),
			('CIVILIZATION_SAYAKA',				'CIVILIZATION_KYOUKO'),
			('CIVILIZATION_SAYAKA',				'CIVILIZATION_NAGISA'),

			('CIVILIZATION_KYOUKO',				'CIVILIZATION_ORIGINAL_MADOKA'),
			('CIVILIZATION_KYOUKO',				'CIVILIZATION_HOMURA'),
			('CIVILIZATION_KYOUKO',				'CIVILIZATION_MAMI'),
			('CIVILIZATION_KYOUKO',				'CIVILIZATION_SAYAKA'),
			('CIVILIZATION_KYOUKO',				'CIVILIZATION_NAGISA'),

			('CIVILIZATION_NAGISA',				'CIVILIZATION_ORIGINAL_MADOKA'),
			('CIVILIZATION_NAGISA',				'CIVILIZATION_HOMURA'),
			('CIVILIZATION_NAGISA',				'CIVILIZATION_MAMI'),
			('CIVILIZATION_NAGISA',				'CIVILIZATION_SAYAKA'),
			('CIVILIZATION_NAGISA',				'CIVILIZATION_KYOUKO');
			

--==========================================================================================================================	
-- JFD's Piety & Prestige
--==========================================================================================================================			
-- Flavors
------------------------------	
INSERT OR REPLACE INTO Flavors 
			(Type)
VALUES		('FLAVOR_JFD_RELIGIOUS_INTOLERANCE');
------------------------------
-- Leader_Flavors
------------------------------
INSERT INTO Leader_Flavors
			(LeaderType,				FlavorType,							Flavor)
VALUES		('LEADER_MADOKA',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	0),
			('LEADER_HOMURA',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	2),
			('LEADER_MAMI',				'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	0),
			('LEADER_SAYAKA',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	1),
			('LEADER_KYOUKO',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	4),
			('LEADER_NAGISA',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	0),
			('LEADER_MADOKA',			'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	10),
			('LEADER_DEMON_HOMURA',		'FLAVOR_JFD_RELIGIOUS_INTOLERANCE',	12);