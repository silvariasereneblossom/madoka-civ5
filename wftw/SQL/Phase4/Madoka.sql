--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for Madoka
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- Section 1: "Middle School replaces the National College: +40% Science (not 50), +2 Faith, +20% Faith,
--             free Magical Girl on completion."
--
-- Only the data half lives here. The free Magical Girl on completion is a Lua hook on
-- GameEvents.CityConstructed and is being implemented separately -- nothing in this file touches it.
--
-- Collision note: BUILDING_PMMM_MITAKIHARA_MS (Mitakihara Middle School, a World Wonder in
-- BUILDINGCLASS_PMMM_MITAKIHARA_MS at TECH_SCIENTIFIC_THEORY) used to arrive at the same tech and in the
-- same "school" slot as this unique building. Moving the Middle School onto the National College
-- (BUILDINGCLASS_NATIONAL_COLLEGE, TECH_PHILOSOPHY) removes that collision: the two no longer share a
-- building class, a tech or a build slot, and Mitakihara can build both.
--
-- Every table and column below was verified against build/sim_cp_wftw.db (CP 5.4.6 schema) before writing.
-- The game ships SQLite 3.7.17: no WITH, no window functions, and booleans are written as 1/0.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. Move the override from the Public School to the National College.
--    The DELETE runs unconditionally so the file is idempotent and so Mitakihara goes back to building the
--    ordinary Public School.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Civilization_BuildingClassOverrides
WHERE CivilizationType = 'CIVILIZATION_ORIGINAL_MADOKA'
  AND BuildingClassType IN ('BUILDINGCLASS_PUBLIC_SCHOOL', 'BUILDINGCLASS_NATIONAL_COLLEGE');

INSERT INTO Civilization_BuildingClassOverrides
			(CivilizationType,				BuildingClassType,					BuildingType)
VALUES		('CIVILIZATION_ORIGINAL_MADOKA','BUILDINGCLASS_NATIONAL_COLLEGE',	'BUILDING_PMMM_MIDDLE_SCHOOL');


--------------------------------------------------------------------------------------------------------------
-- 2. Rewrite the building row as a National College clone.
--    Copied from BUILDING_NATIONAL_COLLEGE by subquery rather than by literal so the clone keeps tracking CP
--    if CP retunes the National College. Columns pulled across:
--      Cost 125, NumCityCostMod 30, HurryCostModifier -1, PrereqTech TECH_PHILOSOPHY, NationalPopRequired 0,
--      NeverCapture 1, NukeImmune 1, ConquestProb 0, GoldMaintenance 0 (national wonders are free to run),
--      FaithCost 0 / UnlockedByBelief 0 (national wonders cannot be faith-bought),
--      SpecialistType NULL / SpecialistCount 0 (the Public School Scientist slot, which the NC lacks),
--      ArtDefineTag ART_DEF_BUILDING_NATIONAL_COLLEGE (wonder splash art).
--
--    Deliberately NOT cloned:
--      Description / Civilopedia / Strategy / Help  -- Mitakihara keeps its own text.
--      PortraitIndex 3 + IconAtlas CIV_COLOR_ATLAS_ORIGINAL_MADOKA -- keeps the civ's own building icon.
--      GreatPeopleRateModifier 25 -- the Middle School's own signature bonus, not a Public School leftover
--                                    (the Public School has none). It predates this change, is stated in the
--                                    building's help and Civilopedia text, and the Phase 4 spec does not ask
--                                    for its removal, so it is kept. One line to drop if that was intended.
--------------------------------------------------------------------------------------------------------------
UPDATE Buildings
SET		BuildingClass		= 'BUILDINGCLASS_NATIONAL_COLLEGE',
		ArtDefineTag		= (SELECT ArtDefineTag			FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		PrereqTech			= (SELECT PrereqTech			FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		Cost				= (SELECT Cost					FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		NumCityCostMod		= (SELECT NumCityCostMod		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		HurryCostModifier	= (SELECT HurryCostModifier		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		NationalPopRequired	= (SELECT NationalPopRequired	FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		NeverCapture		= (SELECT NeverCapture			FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		NukeImmune			= (SELECT NukeImmune			FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		ConquestProb		= (SELECT ConquestProb			FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		GoldMaintenance		= (SELECT GoldMaintenance		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		FaithCost			= (SELECT FaithCost				FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		UnlockedByBelief	= (SELECT UnlockedByBelief		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		SpecialistType		= (SELECT SpecialistType		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE'),
		SpecialistCount		= (SELECT SpecialistCount		FROM Buildings WHERE Type = 'BUILDING_NATIONAL_COLLEGE')
WHERE Type = 'BUILDING_PMMM_MIDDLE_SCHOOL';


--------------------------------------------------------------------------------------------------------------
-- 3. Drop the Public-School-derived rows the National College does not have.
--    Building_YieldChangesPerPop held YIELD_SCIENCE 50 (= +1 Science per 2 Citizens), a Public School effect.
--    The Scientist specialist slot was removed by the column clone above.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_YieldChangesPerPop WHERE BuildingType = 'BUILDING_PMMM_MIDDLE_SCHOOL';


--------------------------------------------------------------------------------------------------------------
-- 4. Prerequisites: a Library in this City, and a Library in every City.
--    Building_ClassesNeededInCity   -> the local requirement (was BUILDINGCLASS_UNIVERSITY).
--    Building_PrereqBuildingClasses -> NumBuildingNeeded -1, the "one in every city" marker; the Middle
--                                      School had no row at all, so it is copied in from the National College.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_PMMM_MIDDLE_SCHOOL';

INSERT INTO Building_ClassesNeededInCity
			(BuildingType,						BuildingClassType)
SELECT		('BUILDING_PMMM_MIDDLE_SCHOOL'),	BuildingClassType
FROM Building_ClassesNeededInCity WHERE (BuildingType = 'BUILDING_NATIONAL_COLLEGE');

DELETE FROM Building_PrereqBuildingClasses WHERE BuildingType = 'BUILDING_PMMM_MIDDLE_SCHOOL';

INSERT INTO Building_PrereqBuildingClasses
			(BuildingType,						BuildingClassType,	NumBuildingNeeded)
SELECT		('BUILDING_PMMM_MIDDLE_SCHOOL'),	BuildingClassType,	NumBuildingNeeded
FROM Building_PrereqBuildingClasses WHERE (BuildingType = 'BUILDING_NATIONAL_COLLEGE');


--------------------------------------------------------------------------------------------------------------
-- 5. Yields.
--    Flat yields: the National College's own (+3 Science, +1 Culture in CP) plus the spec's +2 Faith.
--    Modifiers:   +40% Science (the National College's 50 minus the 10 the spec trades away) and +20% Faith.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_PMMM_MIDDLE_SCHOOL';

INSERT INTO Building_YieldChanges
			(BuildingType,						YieldType,	Yield)
SELECT		('BUILDING_PMMM_MIDDLE_SCHOOL'),	YieldType,	Yield
FROM Building_YieldChanges WHERE (BuildingType = 'BUILDING_NATIONAL_COLLEGE');

INSERT INTO Building_YieldChanges
			(BuildingType,						YieldType,		Yield)
VALUES		('BUILDING_PMMM_MIDDLE_SCHOOL',		'YIELD_FAITH',	2);

DELETE FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_PMMM_MIDDLE_SCHOOL';

INSERT INTO Building_YieldModifiers
			(BuildingType,						YieldType,			Yield)
VALUES		('BUILDING_PMMM_MIDDLE_SCHOOL',		'YIELD_SCIENCE',	40),
			('BUILDING_PMMM_MIDDLE_SCHOOL',		'YIELD_FAITH',		20);


--------------------------------------------------------------------------------------------------------------
-- 6. Text. States the real numbers and the real prerequisite.
--    The free Magical Girl on completion is not mentioned yet; the Lua side owns that line and can add it
--    when the hook lands.
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US
SET Text = '+40% [ICON_RESEARCH] Science, +2 [ICON_PEACE] Faith and +20% [ICON_PEACE] Faith in this City, and +25% increased [ICON_GREAT_PEOPLE] Prodigy birth rate.[NEWLINE][NEWLINE]Must have built a Library in all Cities. The cost goes up the more cities there are in the empire.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MIDDLE_SCHOOL_HELP';

UPDATE Language_en_US
SET Text = 'The Middle School is the unique National Wonder for Mitakihara, replacing the National College. It raises this City [ICON_RESEARCH] Science output by 40% rather than the National College 50%, and pays the difference back in devotion: +2 [ICON_PEACE] Faith and +20% [ICON_PEACE] Faith. It is also a great place for Magical Girls to gather, providing +25% [ICON_GREAT_PEOPLE] Prodigy birth rate. A Library must be built in every City before it can be constructed. It now arrives with Philosophy rather than Scientific Theory, so it no longer competes with the Mitakihara Middle School World Wonder.'
WHERE Tag = 'TXT_KEY_BUILDING_PMMM_MIDDLE_SCHOOL_STRATEGY';
