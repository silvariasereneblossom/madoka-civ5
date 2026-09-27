--------------------------------------------------------------------------------------------------------------
-- Phase 4 kit changes for DemonHomura
-- Loaded after every civilization file, so it may UPDATE rows the base files inserted.
-- Design: docs/design/phase4-design-v1.md
--------------------------------------------------------------------------------------------------------------
-- UA "Ai Yo" (TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS, CIVILIZATION_DEMON_HOMURA).
-- Data only. The game's SQLite is 3.7.17: no WITH, no window functions, no bare DEFAULT true/false.
--------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------
-- 1. UMG "Falsified Phenomena": the Leader Magical Girl ability (data half).
--    An area hit -- every enemy unit on the target tile and on the six tiles around it takes an attack at
--    150% of her Combat Strength. Range 2, cooldown 5, no Soul Gem cost.
--    Handler: Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityDemonHomura.lua. It needs no promotion of its
--    own, so this block is the mission row, the trait link and the text.
--
--    The rest of the spec's Leader Magical Girl clauses -- she is always in Despair, takes no Despair
--    penalties, and can never become a Witch -- are states of the girl rather than of the ability. They ride
--    on PROMOTION_PMMM_ALWAYS_DESPAIR, set up in Abilities.sql and read by the girl-state code, so the help
--    text below describes the attack only.
--
--    Design: docs/design/phase4-design-v1.md section 4 and ruling 4 in section 11.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Missions WHERE Type = 'MISSION_PMMM_FALSIFIED_PHENOMENA';

INSERT INTO Missions
			(Type, Description, Help, DisabledHelp, EntityEventType, Time, OrderPriority, Visible, IconIndex, IconAtlas,
			PMMMMissionRange, PMMMTargetType)
SELECT		('MISSION_PMMM_FALSIFIED_PHENOMENA'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_HELP'), ('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_DISABLED'), EntityEventType, Time, 200, 1, 17, ('UNIT_ACTION_ATLAS'),
			2, ('ENEMY')
FROM Missions WHERE Type = 'MISSION_RANGE_ATTACK';

UPDATE Traits SET LeaderMGUniqueMission = 'MISSION_PMMM_FALSIFIED_PHENOMENA'
WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA', 'Falsified Phenomena'),
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_HELP', 'Homura rewrites what happened across seven tiles at once. Every enemy Unit on the target tile and on the six tiles around it takes damage equal to an attack at 150% of her [ICON_STRENGTH] Combat Strength. Whole stacks are struck, not one Unit per tile, and enemy Cities in the area are damaged as well.[NEWLINE][NEWLINE]Costs no [ICON_PMMM_SOUL_GEM] Soul Gem. Range 2. Cooldown 5 turns.'),
	('TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA_DISABLED', 'Falsified Phenomena is recovering, or there is no enemy in range.');



--==============================================================================================================
-- Phase 4 kit, part 2: the rest of the civilization (design section 4; rulings 4, 4b-4f and the Witch-kill
-- gold row in sections 11-12). Everything below this line is data; the Lua halves are in
--   Lua/Gameplay/Traits/PMMMDemonHomuraTrait.lua        (Lovevil retired, hooks kept as no-ops)
--   Lua/Gameplay/MagicalGirls/PMMMWitches.lua            (Witch kill / Labyrinth gold, her branches only)
--   Lua/Gameplay/MagicalGirls/PMMMMagicalGirls.lua       (Prodigy-to-subjugation credit removed)
--   Lua/Gameplay/UniqueUnits/PMMMClaraDoll.lua           (aura driver short-circuit, MG-only promotions hidden)
--==============================================================================================================


--------------------------------------------------------------------------------------------------------------
-- 2. Civilization rename: "Meikyuu no Homura". The Civilizations row keeps its TXT_KEY tags; only the English
--    strings change. Reading chosen (the spec gives one name): Description, ShortDescription and the
--    Civilopedia title all become "Meikyuu no Homura"; the adjective "Homuran" and her leader name
--    ("Demon Homura") are kept.
--------------------------------------------------------------------------------------------------------------
UPDATE Language_en_US SET Text = 'Meikyuu no Homura' WHERE Tag = 'TXT_KEY_CIV_DEMON_HOMURA_DESC';
UPDATE Language_en_US SET Text = 'Meikyuu no Homura' WHERE Tag = 'TXT_KEY_CIV_DEMON_HOMURA_SHORT_DESC';
UPDATE Language_en_US SET Text = 'Meikyuu no Homura' WHERE Tag = 'TXT_KEY_CIV_DEMON_HOMURA_TITLE';
UPDATE Language_en_US SET Text = 'Leader of Meikyuu no Homura' WHERE Tag = 'TXT_KEY_CIVILOPEDIA_LEADERS_DEMON_HOMURA_SUBTITLE';
-- The two Decisions list "Player must be Homura's Realm" as a requirement, and the Hidden Witch notification names
-- her civilization; keep them in step with the name. (The Civilopedia history keeps "Homura's Realm" as lore.)
UPDATE Language_en_US SET Text = REPLACE(Text, 'Homura''s Realm', 'Meikyuu no Homura')
WHERE Tag IN ('TXT_KEY_DECISIONS_DEMON_HOMURA_KILL_INCUBATORS_DESC', 'TXT_KEY_DECISIONS_DEMON_HOMURA_PACIFICATION_DESC',
              'TXT_KEY_PMMM_NOTIFICATION_HIDDEN_WITCHES_STARTING_TEXT');


--------------------------------------------------------------------------------------------------------------
-- 3. Retire "Lovevil".
--    a. Trait columns: CapitalBonusPerKilledMagicalGirl (the subjugation ledger) and MagicalGirlAttrition (5 damage
--       a turn to enemy girls in her land) go to 0. NoMagicalGirls = 1 stays (her Prodigies never become girls;
--       it is also what loads her trait script and routes the Witch-kill gold to her). Zeroing
--       CapitalBonusPerKilledMagicalGirl also switches off the Vacation promotion theft in
--       PMMMReturnMapFunctions.lua, which is gated on it.
--    b. The nine BUILDING_PMMM_DEMON_HOMURA_DUMMY_* Palace-yield dummies, their classes and their 45
--       Building_BuildingClassYieldChanges rows are deleted. No Lua names them any more.
--    c. PROMOTION_IMMUNE_TO_DEMON_HOMURA_TRAIT (the level-5 immunity to the attrition) is deleted; no Lua grants it.
--    The Golden Age points from Witch kills and from Mood, the city-view addin and the Prodigy credit were Lua
--    only and are gone from the scripts.
--------------------------------------------------------------------------------------------------------------
UPDATE Traits
SET CapitalBonusPerKilledMagicalGirl = 0,
    MagicalGirlAttrition             = 0,
    NoMagicalGirls                   = 1
WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

DELETE FROM Building_BuildingClassYieldChanges WHERE BuildingType LIKE 'BUILDING_PMMM_DEMON_HOMURA_DUMMY_%';
DELETE FROM Buildings                          WHERE Type         LIKE 'BUILDING_PMMM_DEMON_HOMURA_DUMMY_%';
DELETE FROM BuildingClasses                    WHERE Type         LIKE 'BUILDINGCLASS_PMMM_DEMON_HOMURA_DUMMY_%';

DELETE FROM UnitPromotions WHERE Type = 'PROMOTION_IMMUNE_TO_DEMON_HOMURA_TRAIT';


--------------------------------------------------------------------------------------------------------------
-- 4. UA "Ai Yo", the data half.
--    Clause 3, base Prodigy rate halved: Traits.GreatPeopleRateModifier -50 (column verified on Traits; CP adds it
--    to the player's Great People rate modifier in CvPlayer.cpp, so it applies to every city).
--    Clause 5, gold from Witches: the amounts are Defines rows read by PMMMWitches.lua.
--        Witch kill      = PMMM_AI_YO_WITCH_KILL_GOLD + PMMM_AI_YO_WITCH_KILL_GOLD_PER_ERA * era = 10 + 3 x era
--        Labyrinth clear = PMMM_AI_YO_LABYRINTH_GOLD  + PMMM_AI_YO_LABYRINTH_GOLD_PER_ERA  * era = 25 + 10 x era
--        era = the player's current era index (Ancient 0): Ancient 10 / 25, Information 31 / 95.
--
--    Clauses 1, 2 and 4 are DLL trait columns (dll/pmmm-phase4.patch), declared in SQL/Shared/MadokaTableUpdates.sql
--    and set in SQL/Phase4/Abilities.sql: PMMMIgnoreUnhappinessPenalties = 1, PMMMUnhappinessPerBonusPercent = 5,
--    PMMMUnhappinessBonusMax = 25, PMMMNoGoldenAges = 1, PMMMNoIdeologyPressure = 1. Her warmonger AI personality
--    is set there too.
--------------------------------------------------------------------------------------------------------------
UPDATE Traits
SET GreatPeopleRateModifier = -50
WHERE Type = 'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS';

DELETE FROM Defines WHERE Name IN ('PMMM_AI_YO_WITCH_KILL_GOLD', 'PMMM_AI_YO_WITCH_KILL_GOLD_PER_ERA',
                                   'PMMM_AI_YO_LABYRINTH_GOLD',  'PMMM_AI_YO_LABYRINTH_GOLD_PER_ERA');
INSERT INTO Defines (Name, Value) VALUES ('PMMM_AI_YO_WITCH_KILL_GOLD',         10);
INSERT INTO Defines (Name, Value) VALUES ('PMMM_AI_YO_WITCH_KILL_GOLD_PER_ERA',  3);
INSERT INTO Defines (Name, Value) VALUES ('PMMM_AI_YO_LABYRINTH_GOLD',          25);
INSERT INTO Defines (Name, Value) VALUES ('PMMM_AI_YO_LABYRINTH_GOLD_PER_ERA',  10);


--------------------------------------------------------------------------------------------------------------
-- 5. UU Clara Doll: now replaces the Swordsman (was the Great General).
--    The row DemonHomuraUnit.sql made from the Great General is rewritten in place from UNIT_SWORDSMAN: every
--    column is copied from the Swordsman except the Clara Doll's own text keys, portrait and flag, then
--    Combat 16 (Swordsman 14), Moves 2. So it has the Swordsman's Cost (75), FaithCost, PrereqTech
--    (TECH_IRON_WORKING), ObsoleteTech, Iron requirement, upgrade (Longswordsman), AI types and art.
--
--    Magical Girl promotions from XP: CP separates the unit's combat class from its promotion class
--    (Units.PromotionClass; CvUnitEntry falls back to CombatClass when it is NULL, and
--    IsPromotionValidForUnitCombatType checks the promotion class). The Magical Girl unit itself is
--    CombatClass UNITCOMBAT_MELEE + PromotionClass UNITCOMBAT_MAGICALGIRL, so the Clara Doll copies exactly that:
--    it fights and is countered as a melee unit (policies, anti-melee bonuses, Lua that tests
--    GetUnitCombatType() == MELEE all see a Swordsman) and levels up through the Magical Girl tree.
--    Nothing in the mod keys on UNITCOMBAT_MAGICALGIRL except UnitPromotions_UnitCombats, so no anti-girl
--    modifier reaches it (the anti-girl bonuses key on UNITCLASS_PMMM_MAGICAL_GIRL, which it is not).
--    This beats both options in the brief: CombatClass = MAGICALGIRL would drop it out of every melee rule,
--    and MELEE rows on 44 promotions would need a Lua veto on every other melee unit in the game.
--    Cost of the choice: it does not get the melee tree (Shock/Drill/Cover), and policy free promotions only
--    reach it where the promotion is also valid for UNITCOMBAT_MAGICALGIRL (same as for the girls).
--    Six social promotions of the tree (Charisma I/II, Patriotism, Trainer I/II, Teacher) only act on the girl
--    social systems; PMMMClaraDoll.lua hides them from non-girls through GameEvents.CanHavePromotion.
--    Promotions already earned are kept when it upgrades to a Longswordsman (CvUnit::convert keeps them).
--
--    Removed (none of them makes sense on a Swordsman): PROMOTION_GREAT_GENERAL, PROMOTION_GREAT_ADMIRAL,
--    PROMOTION_DOES_NOT_BECOME_GMG (Prodigy-only) and the same-tile aura PROMOTION_PMMM_CLARA_DOLL ->
--    PROMOTION_PMMM_CLARA_DOLL_BUFF (+50% vs. Magical Girls); the aura's promotions and rows are deleted.
--    Kept: the fifteen Clara Doll names (Unit_UniqueNames), which CP hands to the first fifteen built.
--------------------------------------------------------------------------------------------------------------
UPDATE Civilization_UnitClassOverrides
SET UnitClassType = 'UNITCLASS_SWORDSMAN'
WHERE CivilizationType = 'CIVILIZATION_DEMON_HOMURA' AND UnitType = 'UNIT_PMMM_CLARA_DOLL';

UPDATE Units SET
	Requirements                      = (SELECT Requirements FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RangedCombat                      = (SELECT RangedCombat FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Cost                              = (SELECT Cost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FaithCost                         = (SELECT FaithCost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RequiresFaithPurchaseEnabled      = (SELECT RequiresFaithPurchaseEnabled FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PurchaseOnly                      = (SELECT PurchaseOnly FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MoveAfterPurchase                 = (SELECT MoveAfterPurchase FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Immobile                          = (SELECT Immobile FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Range                             = (SELECT Range FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseSightRange                    = (SELECT BaseSightRange FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Class                             = (SELECT Class FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Special                           = (SELECT Special FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Capture                           = (SELECT Capture FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CombatClass                       = (SELECT CombatClass FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Domain                            = (SELECT Domain FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CivilianAttackPriority            = (SELECT CivilianAttackPriority FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	DefaultUnitAI                     = (SELECT DefaultUnitAI FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Food                              = (SELECT Food FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NoBadGoodies                      = (SELECT NoBadGoodies FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RivalTerritory                    = (SELECT RivalTerritory FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MilitarySupport                   = (SELECT MilitarySupport FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MilitaryProduction                = (SELECT MilitaryProduction FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Pillage                           = (SELECT Pillage FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PillagePrereqTech                 = (SELECT PillagePrereqTech FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Found                             = (SELECT Found FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FoundAbroad                       = (SELECT FoundAbroad FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CultureBombRadius                 = (SELECT CultureBombRadius FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GoldenAgeTurns                    = (SELECT GoldenAgeTurns FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FreePolicies                      = (SELECT FreePolicies FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	OneShotTourism                    = (SELECT OneShotTourism FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	OneShotTourismPercentOthers       = (SELECT OneShotTourismPercentOthers FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	IgnoreBuildingDefense             = (SELECT IgnoreBuildingDefense FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PrereqResources                   = (SELECT PrereqResources FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Mechanized                        = (SELECT Mechanized FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Suicide                           = (SELECT Suicide FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CaptureWhileEmbarked              = (SELECT CaptureWhileEmbarked FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PrereqTech                        = (SELECT PrereqTech FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ObsoleteTech                      = (SELECT ObsoleteTech FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GoodyHutUpgradeUnitClass          = (SELECT GoodyHutUpgradeUnitClass FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	HurryCostModifier                 = (SELECT HurryCostModifier FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	AdvancedStartCost                 = (SELECT AdvancedStartCost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MinAreaSize                       = (SELECT MinAreaSize FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	AirInterceptRange                 = (SELECT AirInterceptRange FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	AirUnitCap                        = (SELECT AirUnitCap FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NukeDamageLevel                   = (SELECT NukeDamageLevel FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	WorkRate                          = (SELECT WorkRate FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumFreeTechs                      = (SELECT NumFreeTechs FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseBeakersTurnsToCount           = (SELECT BaseBeakersTurnsToCount FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseCultureTurnsToCount           = (SELECT BaseCultureTurnsToCount FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RushBuilding                      = (SELECT RushBuilding FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseHurry                         = (SELECT BaseHurry FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	HurryMultiplier                   = (SELECT HurryMultiplier FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseGold                          = (SELECT BaseGold FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumGoldPerEra                     = (SELECT NumGoldPerEra FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SpreadReligion                    = (SELECT SpreadReligion FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RemoveHeresy                      = (SELECT RemoveHeresy FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ReligionSpreads                   = (SELECT ReligionSpreads FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ReligiousStrength                 = (SELECT ReligiousStrength FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FoundReligion                     = (SELECT FoundReligion FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RequiresEnhancedReligion          = (SELECT RequiresEnhancedReligion FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ProhibitsSpread                   = (SELECT ProhibitsSpread FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CanBuyCityState                   = (SELECT CanBuyCityState FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CombatLimit                       = (SELECT CombatLimit FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RangeAttackOnlyInDomain           = (SELECT RangeAttackOnlyInDomain FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RangeAttackIgnoreLOS              = (SELECT RangeAttackIgnoreLOS FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Trade                             = (SELECT Trade FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumExoticGoods                    = (SELECT NumExoticGoods FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PolicyType                        = (SELECT PolicyType FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RangedCombatLimit                 = (SELECT RangedCombatLimit FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	XPValueAttack                     = (SELECT XPValueAttack FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	XPValueDefense                    = (SELECT XPValueDefense FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SpecialCargo                      = (SELECT SpecialCargo FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	DomainCargo                       = (SELECT DomainCargo FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Conscription                      = (SELECT Conscription FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ExtraMaintenanceCost              = (SELECT ExtraMaintenanceCost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NoMaintenance                     = (SELECT NoMaintenance FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Unhappiness                       = (SELECT Unhappiness FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	UnitArtInfo                       = (SELECT UnitArtInfo FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	UnitArtInfoCulturalVariation      = (SELECT UnitArtInfoCulturalVariation FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	UnitArtInfoEraVariation           = (SELECT UnitArtInfoEraVariation FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ProjectPrereq                     = (SELECT ProjectPrereq FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SpaceshipProject                  = (SELECT SpaceshipProject FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	LeaderPromotion                   = (SELECT LeaderPromotion FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	LeaderExperience                  = (SELECT LeaderExperience FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	DontShowYields                    = (SELECT DontShowYields FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ShowInPedia                       = (SELECT ShowInPedia FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MoveRate                          = (SELECT MoveRate FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CargoCombat                       = (SELECT CargoCombat FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MaxHitPoints                      = (SELECT MaxHitPoints FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FoundMid                          = (SELECT FoundMid FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FoundLate                         = (SELECT FoundLate FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FoundColony                       = (SELECT FoundColony FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CityAttackOnly                    = (SELECT CityAttackOnly FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CulExpOnDisbandUpgrade            = (SELECT CulExpOnDisbandUpgrade FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CostScalerNumRepeats              = (SELECT CostScalerNumRepeats FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	TourismBonusTurns                 = (SELECT TourismBonusTurns FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ResourceType                      = (SELECT ResourceType FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BeliefRequired                    = (SELECT BeliefRequired FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PuppetPurchaseOverride            = (SELECT PuppetPurchaseOverride FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GoodyModifier                     = (SELECT GoodyModifier FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SupplyCapBoost                    = (SELECT SupplyCapBoost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseProductionTurnsToCount        = (SELECT BaseProductionTurnsToCount FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseGoldTurnsToCount              = (SELECT BaseGoldTurnsToCount FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseTurnsForGAPToCount            = (SELECT BaseTurnsForGAPToCount FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseWLTKDTurns                    = (SELECT BaseWLTKDTurns FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumFreeLux                        = (SELECT NumFreeLux FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GPExtra                           = (SELECT GPExtra FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FriendlyLandsPromotion            = (SELECT FriendlyLandsPromotion FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	IsConvertUnit                     = (SELECT IsConvertUnit FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ScaleFromNumGWs                   = (SELECT ScaleFromNumGWs FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ScaleFromNumThemes                = (SELECT ScaleFromNumThemes FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumberOfCultureBombs              = (SELECT NumberOfCultureBombs FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	PurchaseCooldown                  = (SELECT PurchaseCooldown FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	LocalFaithPurchaseCooldown        = (SELECT LocalFaithPurchaseCooldown FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GlobalFaithPurchaseCooldown       = (SELECT GlobalFaithPurchaseCooldown FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	BaseLandAirDefense                = (SELECT BaseLandAirDefense FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	IsMounted                         = (SELECT IsMounted FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NoSupply                          = (SELECT NoSupply FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	FreeUpgrade                       = (SELECT FreeUpgrade FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	UnitEraUpgrade                    = (SELECT UnitEraUpgrade FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SpecialUnitCargoLoad              = (SELECT SpecialUnitCargoLoad FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	WarOnly                           = (SELECT WarOnly FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	WLTKDFromBirth                    = (SELECT WLTKDFromBirth FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	GoldenAgeFromBirth                = (SELECT GoldenAgeFromBirth FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CultureBoost                      = (SELECT CultureBoost FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ExtraAttackHealthOnKill           = (SELECT ExtraAttackHealthOnKill FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	HighSeaRaider                     = (SELECT HighSeaRaider FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumInfPerEra                      = (SELECT NumInfPerEra FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	RestingPointChange                = (SELECT RestingPointChange FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ProductionCostAddedPerEra         = (SELECT ProductionCostAddedPerEra FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CopyYieldsFromExpendTile          = (SELECT CopyYieldsFromExpendTile FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	TileXPOnExpend                    = (SELECT TileXPOnExpend FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	SendCanMoveIntoEvent              = (SELECT SendCanMoveIntoEvent FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CannotEmbark                      = (SELECT CannotEmbark FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MinorCivGift                      = (SELECT MinorCivGift FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NoMinorCivGift                    = (SELECT NoMinorCivGift FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NoMinorCivUU                      = (SELECT NoMinorCivUU FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	MoveAfterUpgrade                  = (SELECT MoveAfterUpgrade FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CanRepairFleet                    = (SELECT CanRepairFleet FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	CanChangePort                     = (SELECT CanChangePort FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	NumberStackingUnits               = (SELECT NumberStackingUnits FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	StackCombat                       = (SELECT StackCombat FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ExtraSpies                        = (SELECT ExtraSpies FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	ExtraLuxuries                     = (SELECT ExtraLuxuries FROM Units WHERE Type = 'UNIT_SWORDSMAN'),
	Combat                            = 16,
	ObsoleteTech                      = NULL,	-- buildable in every era (2026-09-22 ruling)
	Moves                             = 2,
	PromotionClass                    = 'UNITCOMBAT_MAGICALGIRL'
WHERE Type = 'UNIT_PMMM_CLARA_DOLL';

DELETE FROM Unit_AITypes                      WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_NotAITypes                   WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_Flavors                      WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_FreePromotions               WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_ClassUpgrades                WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM UnitGameplay2DScripts             WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_Builds                       WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_Buildings                    WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_BuildingClassRequireds       WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_ProductionModifierBuildings  WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_GreatPersons                 WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_YieldFromKills               WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';
DELETE FROM Unit_TechTypes                    WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL';

INSERT INTO Unit_AITypes (UnitType, UnitAIType)
SELECT 'UNIT_PMMM_CLARA_DOLL', UnitAIType FROM Unit_AITypes WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_NotAITypes (UnitType, UnitAIType)
SELECT 'UNIT_PMMM_CLARA_DOLL', UnitAIType FROM Unit_NotAITypes WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
SELECT 'UNIT_PMMM_CLARA_DOLL', FlavorType, Flavor FROM Unit_Flavors WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT 'UNIT_PMMM_CLARA_DOLL', PromotionType FROM Unit_FreePromotions WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_ClassUpgrades (UnitType, UnitClassType)
SELECT 'UNIT_PMMM_CLARA_DOLL', UnitClassType FROM Unit_ClassUpgrades WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_ResourceQuantityRequirements (UnitType, ResourceType, Cost)
SELECT 'UNIT_PMMM_CLARA_DOLL', ResourceType, Cost FROM Unit_ResourceQuantityRequirements WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO UnitGameplay2DScripts (UnitType, SelectionSound, FirstSelectionSound)
SELECT 'UNIT_PMMM_CLARA_DOLL', SelectionSound, FirstSelectionSound FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_Builds (UnitType, BuildType)
SELECT 'UNIT_PMMM_CLARA_DOLL', BuildType FROM Unit_Builds WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_Buildings (UnitType, BuildingType)
SELECT 'UNIT_PMMM_CLARA_DOLL', BuildingType FROM Unit_Buildings WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_BuildingClassRequireds (UnitType, BuildingClassType)
SELECT 'UNIT_PMMM_CLARA_DOLL', BuildingClassType FROM Unit_BuildingClassRequireds WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_ProductionModifierBuildings (UnitType, BuildingType, ProductionModifier)
SELECT 'UNIT_PMMM_CLARA_DOLL', BuildingType, ProductionModifier FROM Unit_ProductionModifierBuildings WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_GreatPersons (UnitType, GreatPersonType)
SELECT 'UNIT_PMMM_CLARA_DOLL', GreatPersonType FROM Unit_GreatPersons WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_YieldFromKills (UnitType, YieldType, Yield)
SELECT 'UNIT_PMMM_CLARA_DOLL', YieldType, Yield FROM Unit_YieldFromKills WHERE UnitType = 'UNIT_SWORDSMAN';
INSERT INTO Unit_TechTypes (UnitType, TechType)
SELECT 'UNIT_PMMM_CLARA_DOLL', TechType FROM Unit_TechTypes WHERE UnitType = 'UNIT_SWORDSMAN';

-- The retired aura.
DELETE FROM Promotion_PMMM_GrantAdjacentAllyPromotion WHERE PromotionType = 'PROMOTION_PMMM_CLARA_DOLL';
DELETE FROM UnitPromotions_UnitClasses               WHERE PromotionType = 'PROMOTION_PMMM_CLARA_DOLL_BUFF';
DELETE FROM UnitPromotions WHERE Type IN ('PROMOTION_PMMM_CLARA_DOLL', 'PROMOTION_PMMM_CLARA_DOLL_BUFF');

--[2026-09-22 ruling] PROMOTION_PMMM_CLARA_DOLL comes back as the identity tag. It has no effect of its own;
--it marks the unit as a Clara Doll, and because promotions survive upgrades it rides along into the
--Longswordsman and everything after it. Two things read the tag:
--  the DLLs   -- a tagged unit chooses from the Magical Girl promotion tree whatever chassis it is on
--                (dll_patch_phase4.py patch_clara_doll_tag / dll/lekmod-wftw-claradoll.patch);
--  the Lua    -- PMMMClaraDoll.lua gives a tagged unit +2 Combat Strength per era.
--CannotBeChosen keeps it out of the promotion picker; it is granted by Unit_FreePromotions below.
INSERT INTO UnitPromotions
			(Type, Description, Help, Sound, CannotBeChosen, PortraitIndex, IconAtlas, PediaType, PediaEntry)
VALUES		('PROMOTION_PMMM_CLARA_DOLL', 'TXT_KEY_PROMOTION_PMMM_CLARA_DOLL', 'TXT_KEY_PROMOTION_PMMM_CLARA_DOLL_HELP',
			'AS2D_IF_LEVELUP', 1, 58, 'ABILITY_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_PMMM_CLARA_DOLL');

DELETE FROM Unit_FreePromotions WHERE UnitType = 'UNIT_PMMM_CLARA_DOLL' AND PromotionType = 'PROMOTION_PMMM_CLARA_DOLL';
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
VALUES ('UNIT_PMMM_CLARA_DOLL', 'PROMOTION_PMMM_CLARA_DOLL');	-- the identity tag, kept through every upgrade


--------------------------------------------------------------------------------------------------------------
-- 6. UB Half-Moon Garden: replaces the Garden. She had no Garden override, so this is a new building: every column
--    is copied from BUILDING_GARDEN (Cost 120, 1 Gold maintenance, PrereqTech TECH_THEOLOGY in CP, FreshWater = 1,
--    art and icon), then GreatPeopleRateModifier 10 (Garden 25) and +5% to Food, Production, Gold, Science,
--    Culture and Faith in the city through Building_YieldModifiers.
--    Reading chosen: the Garden's own flavour row is copied as is; no other Garden child rows exist in CP.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Civilization_BuildingClassOverrides WHERE BuildingType = 'BUILDING_PMMM_HALF_MOON_GARDEN';
DELETE FROM Building_YieldModifiers             WHERE BuildingType = 'BUILDING_PMMM_HALF_MOON_GARDEN';
DELETE FROM Building_Flavors                    WHERE BuildingType = 'BUILDING_PMMM_HALF_MOON_GARDEN';
DELETE FROM Buildings                           WHERE Type         = 'BUILDING_PMMM_HALF_MOON_GARDEN';

INSERT INTO Buildings
			(
			Type, Description, Civilopedia, Strategy, Help, ThemingBonusHelp, Quote, GoldMaintenance, MutuallyExclusiveGroup, TeamShare, Water, River, FreshWater,
			Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious, BorderObstacle, PlayerBorderObstacle, Capital, GoldenAge, MapCentering,
			NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting, AffectSpiesNow, NullifyInfluenceModifier, Cost, FaithCost, LeagueCost,
			UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod, HurryCostModifier, MinAreaSize, ConquestProb, CitiesPrereq, LevelPrereq,
			CultureRateModifier, GlobalCultureRateModifier, GreatPeopleRateModifier, GlobalGreatPeopleRateModifier, GreatGeneralRateModifier,
			GreatPersonExpendGold, GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience, FoodKept, Airlift, AirModifier, NukeModifier,
			NukeExplosionRand, HealRateChange, Happiness, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity, HappinessPerXPolicies,
			CityCountUnhappinessMod, NoOccupiedUnhappiness, WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier,
			GlobalSpaceProductionModifier, BuildingProductionModifier, WonderProductionModifier, CityConnectionTradeRouteModifier, CapturePlunderModifier,
			PolicyCostModifier, PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier, GlobalPlotBuyCostModifier, GlobalPopulationChange,
			TechShare, FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike, Espionage, AllowsFoodTradeRoutes,
			AllowsProductionTradeRoutes, Defense, ExtraCityHitPoints, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints, ExtraMissionarySpreads,
			ReligiousPressureModifier, EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange, TradeRouteRecipientBonus,
			TradeRouteTargetBonus, NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier, XBuiltTriggersIdeologyChoice,
			TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus, CityStateTradeRouteProductionModifier,
			GreatScientistBeakerModifier, BuildingClass, ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain, VictoryPrereq, FreeStartEra, MaxStartEra,
			ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion, TrainedFreePromotion, FreePromotionRemoved,
			ReplacementBuildingClass, PrereqTech, PolicyBranchType, SpecialistType, SpecialistCount, GreatWorkSlotType, FreeGreatWork, GreatWorkCount,
			SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition, PortraitIndex, WonderSplashImage, WonderSplashAnchor,
			WonderSplashAudio, IconAtlas, ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation, AddsFreshWater, PurchaseOnly, IsNoWater,
			IsNoRiver, IsNoCoast, CapitalOnly, NumPoliciesNeeded, NoUnhappfromXSpecialists, NoUnhappfromXSpecialistsGlobal, FoodBonusPerCityMajorityFollower,
			PlayerBorderGainlessPillage, CityGainlessPillage, AllowsIndustrialWaterRoutes, AllowsAirRoutes, Sealift, BorderGrowthRateIncrease,
			BorderGrowthRateIncreaseGlobal, DiplomatInfluenceBoost, NationalPopRequired, LocalPopRequired, PopulationChange, BorderObstacleCity,
			BorderObstacleWater, DeepWaterTileDamage, AllowsFoodTradeRoutesGlobal, AllowsProductionTradeRoutesGlobal, CityConnectionGoldModifier,
			EmpireSizeModifierReduction, EmpireSizeModifierReductionGlobal, DistressFlatReduction, PovertyFlatReduction, IlliteracyFlatReduction,
			BoredomFlatReduction, ReligiousUnrestFlatReduction, DistressFlatReductionGlobal, PovertyFlatReductionGlobal, IlliteracyFlatReductionGlobal,
			BoredomFlatReductionGlobal, ReligiousUnrestFlatReductionGlobal, BasicNeedsMedianModifier, GoldMedianModifier, ScienceMedianModifier,
			CultureMedianModifier, ReligiousUnrestModifier, BasicNeedsMedianModifierGlobal, GoldMedianModifierGlobal, ScienceMedianModifierGlobal,
			CultureMedianModifierGlobal, ReligiousUnrestModifierGlobal, LocalUnhappinessModifier, GlobalBuildingGoldMaintenanceMod, NationalFollowerPopRequired,
			GlobalFollowerPopRequired, ReformationFollowerReduction, ExtraMissionarySpreadsGlobal, IsReformation, PolicyType, ResourceType,
			PuppetPurchaseOverride, RequiresPuppet, SingleLeagueVotes, AllowsPuppetPurchase, GrantsRandomResourceTerritory, TradeReligionModifier,
			NeedBuildingThisCity, WLTKDTurns, EventTourism, AlwaysHeal, CitySupplyModifier, CitySupplyModifierGlobal, CitySupplyFlat, CitySupplyFlatGlobal,
			CityRangedStrikeRange, CityIndirectFire, RangedStrikeModifier, ExtraMissionaryStrengthGlobal, ResourceDiversityModifier, FinishLandTRTourism,
			FinishSeaTRTourism, VotesPerGPT, RequiresIndustrialCityConnection, CivilizationRequired, PurchaseCooldownReduction, PurchaseCooldownReductionCivilian,
			PurchaseCooldown, CityAirStrikeDefense, BuildAnywhere, FreeArtifacts, SpySecurityModifier, SpySecurityModifierPerXPop, GlobalSpySecurityModifier,
			VassalLevyEra, NumRequiredTier3Tenets, AirModifierGlobal, EventChoiceRequiredActive, CityEventChoiceRequiredActive, IsCorporation,
			GPRateModifierPerXFranchises, TRSpeedBoost, TRVisionBoost, TRTurnModGlobal, TRTurnModLocal, RequiresXFranchises, RequiresXPercentGlobalMonopolies,
			DPToVotes, SecondaryPantheon, IsDummy, AnyWater, BuildingDefenseModifier, DamageReductionFlat, GlobalLandmarksTourismPercent,
			GlobalGreatWorksTourismModifier, NukeInterceptionChance, ShowInPedia, InstantReligiousPressure, BasePressureModifierGlobal, IgnoreDefensivePactLimit,
			FaithToVotes, CapitalsToVotes, DoFToVotes, RAToVotes, GPExpendInfluence, CityAutomatonWorkersChange, GlobalCityAutomatonWorkersChange,
			CityWorkingChange, GlobalCityWorkingChange, GPRateModifierPerMarriage, ExperiencePerGoldenAge, ExperiencePerGoldenAgeCap, GPRateModifierPerLocalTheme,
			GPPOnCitizenBirth, GlobalHappinessPerMajorWar, GlobalMilitaryProductionModPerMajorWar, NoStarvationNonSpecialist, MinimumFood, DefensePerXWonder,
			GarrisonRangedAttackModifier, LocalFranchiseChance, GreatWorkYieldType, GlobalConversionModifier, ConversionModifier, Unhappiness,
			GoldFromKillingWitches, PMMMMoodBonus, PMMMEntertainment, PMMMEntertainmentModifier, PMMMEntertainmentCitizenModifier,
			PMMMEntertainmentSpecialistModifier, PMMMEntertainmentConnectionModifier, PMMMMaxLandAreaSize, PMMMRequiresAdjacentLake
			)
SELECT
			'BUILDING_PMMM_HALF_MOON_GARDEN', 'TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN', 'TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_TEXT',
			'TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_STRATEGY', 'TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_HELP', ThemingBonusHelp, Quote, GoldMaintenance,
			MutuallyExclusiveGroup, TeamShare, Water, River, FreshWater, Mountain, NearbyMountainRequired, Hill, Flat, FoundsReligion, IsReligious,
			BorderObstacle, PlayerBorderObstacle, Capital, GoldenAge, MapCentering, NeverCapture, NukeImmune, AllowsWaterRoutes, ExtraLuxuries, DiplomaticVoting,
			AffectSpiesNow, NullifyInfluenceModifier, Cost, FaithCost, LeagueCost, UnlockedByBelief, UnlockedByLeague, HolyCity, NumCityCostMod,
			HurryCostModifier, MinAreaSize, ConquestProb, CitiesPrereq, LevelPrereq, CultureRateModifier, GlobalCultureRateModifier, 10,
			GlobalGreatPeopleRateModifier, GreatGeneralRateModifier, GreatPersonExpendGold, GoldenAgeModifier, UnitUpgradeCostMod, Experience, GlobalExperience,
			FoodKept, Airlift, AirModifier, NukeModifier, NukeExplosionRand, HealRateChange, Happiness, UnmoddedHappiness, UnhappinessModifier, HappinessPerCity,
			HappinessPerXPolicies, CityCountUnhappinessMod, NoOccupiedUnhappiness, WorkerSpeedModifier, MilitaryProductionModifier, SpaceProductionModifier,
			GlobalSpaceProductionModifier, BuildingProductionModifier, WonderProductionModifier, CityConnectionTradeRouteModifier, CapturePlunderModifier,
			PolicyCostModifier, PlotCultureCostModifier, GlobalPlotCultureCostModifier, PlotBuyCostModifier, GlobalPlotBuyCostModifier, GlobalPopulationChange,
			TechShare, FreeTechs, FreePolicies, FreeGreatPeople, MedianTechPercentChange, Gold, AllowsRangeStrike, Espionage, AllowsFoodTradeRoutes,
			AllowsProductionTradeRoutes, Defense, ExtraCityHitPoints, GlobalDefenseMod, MinorFriendshipChange, VictoryPoints, ExtraMissionarySpreads,
			ReligiousPressureModifier, EspionageModifier, GlobalEspionageModifier, ExtraSpies, SpyRankChange, InstantSpyRankChange, TradeRouteRecipientBonus,
			TradeRouteTargetBonus, NumTradeRouteBonus, LandmarksTourismPercent, InstantMilitaryIncrease, GreatWorksTourismModifier, XBuiltTriggersIdeologyChoice,
			TradeRouteSeaDistanceModifier, TradeRouteSeaGoldBonus, TradeRouteLandDistanceModifier, TradeRouteLandGoldBonus, CityStateTradeRouteProductionModifier,
			GreatScientistBeakerModifier, BuildingClass, ArtDefineTag, NearbyTerrainRequired, ProhibitedCityTerrain, VictoryPrereq, FreeStartEra, MaxStartEra,
			ObsoleteTech, EnhancedYieldTech, TechEnhancedTourism, FreeBuilding, FreeBuildingThisCity, FreePromotion, TrainedFreePromotion, FreePromotionRemoved,
			ReplacementBuildingClass, PrereqTech, PolicyBranchType, SpecialistType, SpecialistCount, GreatWorkSlotType, FreeGreatWork, GreatWorkCount,
			SpecialistExtraCulture, GreatPeopleRateChange, ExtraLeagueVotes, CityWall, DisplayPosition, PortraitIndex, WonderSplashImage, WonderSplashAnchor,
			WonderSplashAudio, IconAtlas, ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation, AddsFreshWater, PurchaseOnly, IsNoWater,
			IsNoRiver, IsNoCoast, CapitalOnly, NumPoliciesNeeded, NoUnhappfromXSpecialists, NoUnhappfromXSpecialistsGlobal, FoodBonusPerCityMajorityFollower,
			PlayerBorderGainlessPillage, CityGainlessPillage, AllowsIndustrialWaterRoutes, AllowsAirRoutes, Sealift, BorderGrowthRateIncrease,
			BorderGrowthRateIncreaseGlobal, DiplomatInfluenceBoost, NationalPopRequired, LocalPopRequired, PopulationChange, BorderObstacleCity,
			BorderObstacleWater, DeepWaterTileDamage, AllowsFoodTradeRoutesGlobal, AllowsProductionTradeRoutesGlobal, CityConnectionGoldModifier,
			EmpireSizeModifierReduction, EmpireSizeModifierReductionGlobal, DistressFlatReduction, PovertyFlatReduction, IlliteracyFlatReduction,
			BoredomFlatReduction, ReligiousUnrestFlatReduction, DistressFlatReductionGlobal, PovertyFlatReductionGlobal, IlliteracyFlatReductionGlobal,
			BoredomFlatReductionGlobal, ReligiousUnrestFlatReductionGlobal, BasicNeedsMedianModifier, GoldMedianModifier, ScienceMedianModifier,
			CultureMedianModifier, ReligiousUnrestModifier, BasicNeedsMedianModifierGlobal, GoldMedianModifierGlobal, ScienceMedianModifierGlobal,
			CultureMedianModifierGlobal, ReligiousUnrestModifierGlobal, LocalUnhappinessModifier, GlobalBuildingGoldMaintenanceMod, NationalFollowerPopRequired,
			GlobalFollowerPopRequired, ReformationFollowerReduction, ExtraMissionarySpreadsGlobal, IsReformation, PolicyType, ResourceType,
			PuppetPurchaseOverride, RequiresPuppet, SingleLeagueVotes, AllowsPuppetPurchase, GrantsRandomResourceTerritory, TradeReligionModifier,
			NeedBuildingThisCity, WLTKDTurns, EventTourism, AlwaysHeal, CitySupplyModifier, CitySupplyModifierGlobal, CitySupplyFlat, CitySupplyFlatGlobal,
			CityRangedStrikeRange, CityIndirectFire, RangedStrikeModifier, ExtraMissionaryStrengthGlobal, ResourceDiversityModifier, FinishLandTRTourism,
			FinishSeaTRTourism, VotesPerGPT, RequiresIndustrialCityConnection, CivilizationRequired, PurchaseCooldownReduction, PurchaseCooldownReductionCivilian,
			PurchaseCooldown, CityAirStrikeDefense, BuildAnywhere, FreeArtifacts, SpySecurityModifier, SpySecurityModifierPerXPop, GlobalSpySecurityModifier,
			VassalLevyEra, NumRequiredTier3Tenets, AirModifierGlobal, EventChoiceRequiredActive, CityEventChoiceRequiredActive, IsCorporation,
			GPRateModifierPerXFranchises, TRSpeedBoost, TRVisionBoost, TRTurnModGlobal, TRTurnModLocal, RequiresXFranchises, RequiresXPercentGlobalMonopolies,
			DPToVotes, SecondaryPantheon, IsDummy, AnyWater, BuildingDefenseModifier, DamageReductionFlat, GlobalLandmarksTourismPercent,
			GlobalGreatWorksTourismModifier, NukeInterceptionChance, ShowInPedia, InstantReligiousPressure, BasePressureModifierGlobal, IgnoreDefensivePactLimit,
			FaithToVotes, CapitalsToVotes, DoFToVotes, RAToVotes, GPExpendInfluence, CityAutomatonWorkersChange, GlobalCityAutomatonWorkersChange,
			CityWorkingChange, GlobalCityWorkingChange, GPRateModifierPerMarriage, ExperiencePerGoldenAge, ExperiencePerGoldenAgeCap, GPRateModifierPerLocalTheme,
			GPPOnCitizenBirth, GlobalHappinessPerMajorWar, GlobalMilitaryProductionModPerMajorWar, NoStarvationNonSpecialist, MinimumFood, DefensePerXWonder,
			GarrisonRangedAttackModifier, LocalFranchiseChance, GreatWorkYieldType, GlobalConversionModifier, ConversionModifier, Unhappiness,
			GoldFromKillingWitches, PMMMMoodBonus, PMMMEntertainment, PMMMEntertainmentModifier, PMMMEntertainmentCitizenModifier,
			PMMMEntertainmentSpecialistModifier, PMMMEntertainmentConnectionModifier, PMMMMaxLandAreaSize, PMMMRequiresAdjacentLake
FROM Buildings WHERE Type = 'BUILDING_GARDEN';

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_PMMM_HALF_MOON_GARDEN', FlavorType, Flavor FROM Building_Flavors WHERE BuildingType = 'BUILDING_GARDEN';

INSERT INTO Building_YieldModifiers
			(BuildingType,						YieldType,				Yield)
VALUES		('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_FOOD',			5),
			('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_PRODUCTION',		5),
			('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_GOLD',			5),
			('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_SCIENCE',		5),
			('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_CULTURE',		5),
			('BUILDING_PMMM_HALF_MOON_GARDEN',	'YIELD_FAITH',			5);

INSERT INTO Civilization_BuildingClassOverrides
			(CivilizationType,				BuildingClassType,		BuildingType)
VALUES		('CIVILIZATION_DEMON_HOMURA',	'BUILDINGCLASS_GARDEN',	'BUILDING_PMMM_HALF_MOON_GARDEN');


--------------------------------------------------------------------------------------------------------------
-- 7. Incubator Slave removed: she builds ordinary Workers. The Worker override is dropped. The unit row itself is
--    kept but hidden from the Civilopedia (ShowInPedia 0) because DecisionsMod/Lua/PMMMDemonHomuraDecisions.lua
--    (outside this pass) still reads GameInfoTypes.UNIT_PMMM_INCUBATOR_SLAVE; nobody can train it any more, so the
--    "Punish the Incubators" decision can never be enacted (see the report).
--------------------------------------------------------------------------------------------------------------
DELETE FROM Civilization_UnitClassOverrides
WHERE CivilizationType = 'CIVILIZATION_DEMON_HOMURA' AND UnitType = 'UNIT_PMMM_INCUBATOR_SLAVE';

UPDATE Units SET ShowInPedia = 0 WHERE Type = 'UNIT_PMMM_INCUBATOR_SLAVE';


--------------------------------------------------------------------------------------------------------------
-- 8. Text. Every number below is the one the data or the Lua uses.
--------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
	('TXT_KEY_TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS_SHORT', 'Ai Yo'),
	('TXT_KEY_TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS',
		--[2026-09-27] Kept short: the long form overflowed the trait window. The Civilopedia entry carries the detail.
		'No [ICON_HAPPINESS_4] Unhappiness penalties. Instead, +1% Yields and [ICON_STRENGTH] Combat Strength per 5 [ICON_HAPPINESS_4] Unhappiness from Cities and Population (max +25%).[NEWLINE]'
		|| 'Policy and Ideology [ICON_HAPPINESS_1] Happiness becomes 2x [ICON_CULTURE] Culture.[NEWLINE]'
		|| '[ICON_GREAT_PEOPLE] Prodigies: -50% rate, never Magical Girls.[NEWLINE]'
		|| 'No [ICON_GOLDEN_AGE] Golden Ages, Ideology pressure, Friendships or City-State allies.[NEWLINE]'
		|| 'Witches: 10 [ICON_GOLD] (+3 per Era). Labyrinths: 25 [ICON_GOLD] (+10 per Era).'),

	('TXT_KEY_CIVILOPEDIA_LEADERS_DEMON_HOMURA_TEXT_1',
		'[ICON_BULLET]Ai Yo: no penalty from [ICON_HAPPINESS_4] Unhappiness ever applies to her. Her cities never revolt, and her yields, growth and [ICON_STRENGTH] Combat Strength never drop however unhappy her people are; the game treats her as never unhappy.[NEWLINE]'
		|| '[ICON_BULLET]Instead, every 5 points of [ICON_HAPPINESS_4] Unhappiness from her Cities and Population (the total, not the shortfall) add +1% to all yields and +1% [ICON_STRENGTH] Combat Strength, up to +25% at 125 Unhappiness.[NEWLINE]'
		|| '[ICON_BULLET]Her [ICON_GREAT_PEOPLE] Prodigy rate is halved (-50%), and Prodigies never become Magical Girls. Her own Leader Magical Girl is her only girl.[NEWLINE]'
		|| '[ICON_BULLET]She can never have a [ICON_GOLDEN_AGE] Golden Age from any source, including Great Artists, Wonders, Policies and surplus Happiness, and she is immune to Ideological pressure: no public-opinion Unhappiness and no forced revolutions.[NEWLINE]'
		|| '[ICON_BULLET]Killing a Witch pays 10 [ICON_GOLD] Gold plus 3 per Era instead of a [ICON_PMMM_GRIEF_SEED] Grief Seed (10 in the Ancient Era, 31 in the Information Era). Clearing a Witch''s Labyrinth pays 25 [ICON_GOLD] Gold plus 10 per Era (25 to 95).[NEWLINE]'
		|| '[ICON_BULLET]No Hidden Witch Barriers spawn in her territory.[NEWLINE]'
		|| '[ICON_BULLET]Unique Unit: the Clara Doll (replaces the Swordsman). Unique Building: the Half-Moon Garden (replaces the Garden).'),

	('TXT_KEY_PMMM_ALERT_KILLED_WITCH_DEMON_HOMURA',
		'You killed the Witch and crushed its [ICON_PMMM_GRIEF_SEED] Grief Seed, absorbing its energy into your Dark Orb and earning {1_Num} [ICON_GOLD] Gold.'),
	('TXT_KEY_PMMM_ALERT_LABYRINTH_GOLD_DEMON_HOMURA',
		'The Witch''s Labyrinth is torn down and its hoard is yours: {1_Num} [ICON_GOLD] Gold.'),

	('TXT_KEY_UNIT_PMMM_CLARA_DOLL_HELP',
		'Unique Swordsman replacement for Meikyuu no Homura. 16 [ICON_STRENGTH] Combat Strength (Swordsman 14) and 2 [ICON_MOVES] Movement, and +2 [ICON_STRENGTH] Combat Strength for every Era that has passed. Never becomes obsolete: it can be built in any Era. Earns Magical Girl promotions from experience instead of the usual melee promotions, and keeps both the Magical Girl tree and the Era bonus when it upgrades.'),
	('TXT_KEY_PROMOTION_PMMM_CLARA_DOLL', 'Clara Doll'),
	('TXT_KEY_PROMOTION_PMMM_CLARA_DOLL_HELP',
		'This unit is one of Homura''s Clara Dolls: +2 [ICON_STRENGTH] Combat Strength for every Era that has passed, and it chooses Magical Girl promotions instead of melee ones. Kept when the unit upgrades.'),
	('TXT_KEY_UNIT_PMMM_CLARA_DOLL_STRATEGY',
		'The Clara Doll is the Unique Unit of Meikyuu no Homura, replacing the Swordsman. It costs the same, needs the same [ICON_RES_IRON] Iron and technology, and hits harder with 16 [ICON_STRENGTH] Combat Strength against the Swordsman''s 14. As it gains experience it chooses from the Magical Girl promotion tree (Offense and Defense Training, then the Siege, Skirmish, Sentry and Support lines) rather than the melee one, and keeps those promotions when it upgrades. It is still a melee unit for every other purpose. An early army of Clara Dolls is how Homura starts the snowball her Unhappiness feeds on.'),

	('TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN', 'Half-Moon Garden'),
	('TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_HELP',
		'+10% [ICON_GREAT_PEOPLE] Great People generation in this City (Garden 25%). +5% [ICON_FOOD] Food, [ICON_PRODUCTION] Production, [ICON_GOLD] Gold, [ICON_RESEARCH] Science, [ICON_CULTURE] Culture and [ICON_PEACE] Faith in this City. City must be next to a River or Lake.'),
	('TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_STRATEGY',
		'The Half-Moon Garden is the Unique Building of Meikyuu no Homura, replacing the Garden. It trades most of the Garden''s Great People bonus for +5% to every yield in the City, and it is her main economic building: with Prodigies born at half speed, the flat percentage is worth more to her than the Garden''s. Build it first in her largest Cities.'),
	('TXT_KEY_BUILDING_PMMM_HALF_MOON_GARDEN_TEXT',
		'Under a moon that is never more than half full, Homura keeps a garden for the one person her world was built around. Everything in it is arranged so that Madoka will be happy there and will never think to ask why, and the flowers bloom whether or not anyone else is allowed to see them.');


--------------------------------------------------------------------------------------------------------------
-- Ruling 15.4 (2026-09-18): no free starting Archer. It made up for her having no Leader Magical Girl, which
-- she has now. The free Settler stays. No text mentioned the Archer.
--------------------------------------------------------------------------------------------------------------
DELETE FROM Civilization_FreeUnits
WHERE CivilizationType = 'CIVILIZATION_DEMON_HOMURA' AND UnitClassType = 'UNITCLASS_ARCHER';
