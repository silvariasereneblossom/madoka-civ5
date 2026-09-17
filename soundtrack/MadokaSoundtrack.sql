------------------------OPTIONS------------------------------------------------------------------------------------

CREATE TABLE MadokaSoundtrackOptions(Type, Value);

INSERT INTO MadokaSoundtrackOptions(Type)
VALUES	('SisPuellaMagicaOmnis');

-- Sis Puella Magica Omnis
-- Setting this Value to "1" makes EVERY Civ use the Madoka soundtrack. Yes, even other mod Civs.

UPDATE MadokaSoundtrackOptions
SET Value = 0
WHERE Type = 'SisPuellaMagicaOmnis';


-----------------------END OPTIONS---------------------------------------------------------------------------------


-----------------------SET SOUNDTRACKTAG---------------------------------------------------------------------------

UPDATE Civilizations
SET SoundtrackTag = 'MADOKA'
WHERE EXISTS(SELECT * FROM MadokaSoundtrackOptions WHERE Type = 'SisPuellaMagicaOmnis' AND Value = 1) OR Type IN('CIVILIZATION_MADOKA', 'CIVILIZATION_HOMURA', 'CIVILIZATION_SAYAKA', 'CIVILIZATION_KYOUKO', 'CIVILIZATION_MAMI', 'CIVILIZATION_NAGISA', 'CIVILIZATION_DEMON_HOMURA',
'CIVILIZATION_ORIGINAL_MADOKA', 'CIVILIZATION_KAORU_UMIKA', 'CIVILIZATION_ORIKO_KIRIKA', 'CIVILIZATION_SUZUNE', 'CIVILIZATION_PMMM_JEANNE_DARC');


CREATE TRIGGER SetToMadokaSoundtrackTrigger
AFTER INSERT ON Civilizations
BEGIN
	UPDATE Civilizations
	SET SoundtrackTag = 'MADOKA'
	WHERE EXISTS(SELECT * FROM MadokaSoundtrackOptions WHERE Type = 'SisPuellaMagicaOmnis' AND Value = 1) OR Type IN('CIVILIZATION_MADOKA', 'CIVILIZATION_HOMURA', 'CIVILIZATION_SAYAKA', 'CIVILIZATION_KYOUKO', 'CIVILIZATION_MAMI', 'CIVILIZATION_NAGISA', 'CIVILIZATION_DEMON_HOMURA',
	'CIVILIZATION_ORIGINAL_MADOKA', 'CIVILIZATION_KAORU_UMIKA', 'CIVILIZATION_ORIKO_KIRIKA', 'CIVILIZATION_SUZUNE', 'CIVILIZATION_PMMM_JEANNE_DARC');
END








-----------------------SET SOUNDTRACKTAG---------------------------------------------------------------------------