INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_HOMURA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_HOMURA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_HOMURA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_HOMURA_DEFEATED%', 										1),	
			('LEADER_HOMURA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_HOMURA_FIRSTGREETING%', 								1);



INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_MADOKA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_MADOKA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_MADOKA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_MADOKA_DEFEATED%', 										1),	
			('LEADER_MADOKA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_MADOKA_FIRSTGREETING%', 								1);




INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_ORIGINAL_MADOKA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_ORIGINAL_MADOKA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_ORIGINAL_MADOKA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_ORIGINAL_MADOKA_DEFEATED%', 										1),	
			('LEADER_ORIGINAL_MADOKA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_ORIGINAL_MADOKA_FIRSTGREETING%', 								1);

INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_SAYAKA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_SAYAKA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_SAYAKA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_SAYAKA_DEFEATED%', 										1),	
			('LEADER_SAYAKA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_SAYAKA_FIRSTGREETING%', 								1);

INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_KYOUKO'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_KYOUKO_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_KYOUKO', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_KYOUKO_DEFEATED%', 										1),	
			('LEADER_KYOUKO', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_KYOUKO_FIRSTGREETING%', 								1);

INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_MAMI'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_MAMI_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_MAMI', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_MAMI_DEFEATED%', 										1),	
			('LEADER_MAMI', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_MAMI_FIRSTGREETING%', 								1);

INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_NAGISA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_NAGISA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_NAGISA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_NAGISA_DEFEATED%', 										1),	
			('LEADER_NAGISA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_NAGISA_FIRSTGREETING%', 								1);

INSERT INTO Diplomacy_Responses
			(LeaderType,	ResponseType,	Response,	Bias)
SELECT 		('LEADER_DEMON_HOMURA'),	ResponseType,	REPLACE(Response, '_GENERIC_', '_LEADER_DEMON_HOMURA_'), 1
FROM Diplomacy_Responses WHERE LeaderType = 'GENERIC';

INSERT INTO Diplomacy_Responses 
			(LeaderType, 			ResponseType, 										Response, 																Bias)
VALUES		('LEADER_DEMON_HOMURA', 	'RESPONSE_DEFEATED', 									'TXT_KEY_LEADER_DEMON_HOMURA_DEFEATED%', 										1),	
			('LEADER_DEMON_HOMURA', 	'RESPONSE_FIRST_GREETING', 								'TXT_KEY_LEADER_DEMON_HOMURA_FIRSTGREETING%', 								1);

