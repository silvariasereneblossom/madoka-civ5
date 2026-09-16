CREATE TABLE IF NOT EXISTS COMMUNITY(Type, Value);

-- Madoka's Middle School should reduce Illiteracy
UPDATE Buildings
SET IlliteracyHappinessChange = (SELECT IlliteracyHappinessChange FROM Buildings WHERE Type = 'BUILDING_PUBLIC_SCHOOL')
WHERE Type = 'BUILDING_PMMM_MIDDLE_SCHOOL' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_BUILDINGS' AND Value= 1 );


-- Kyouko's Sakura Church should reduce Religious Strife
UPDATE Buildings
SET MinorityHappinessChange = (SELECT MinorityHappinessChange FROM Buildings WHERE Type = 'BUILDING_TEMPLE')
WHERE Type = 'BUILDING_PMMM_SAKURA_CHURCH' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_BUILDINGS' AND Value= 1 );