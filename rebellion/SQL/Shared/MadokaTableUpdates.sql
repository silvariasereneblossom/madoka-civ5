--**********************************************************************************************
--**********************************************************************************************
-----------------Adjustments to existing Tables (Traits, UnitPromotions)------------------------
--**********************************************************************************************
--**********************************************************************************************



--**********************************************************************************************
--Traits
--**********************************************************************************************
ALTER TABLE Traits ADD COLUMN 'MagicalGirlOnGreatPersonUse' BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE Traits ADD COLUMN 'CityStateCombatStrengthModTimes100' INTEGER DEFAULT 0; --Amount of Strength granted to Gun
ALTER TABLE Traits ADD COLUMN 'GreatPersonProgressFromKills' TEXT DEFAULT NULL; --Sayaka's trait
ALTER TABLE Traits ADD COLUMN 'CombatBonusFromTourismInfluence' BOOLEAN DEFAULT false NOT NULL; --Sayaka's trait. Is a boolean since it uses specific promotions.
ALTER TABLE Traits ADD COLUMN 'GrowthBonusFromWorldReligionTimes1000' INTEGER DEFAULT 0;
ALTER TABLE Traits ADD COLUMN 'FaithBonusOnCapitalGrowth' INTEGER DEFAULT 0;
ALTER TABLE Traits ADD COLUMN 'HappinessToMetEnemies' INTEGER DEFAULT 0;
ALTER TABLE Traits ADD COLUMN 'UnhappinessPerCivilizationMet' INTEGER DEFAULT 0;
ALTER TABLE Traits ADD COLUMN 'YieldBonusPerCivilizationMet' INTEGER DEFAULT 0;

--**********************************************************************************************
--UnitPromotions
--**********************************************************************************************
ALTER TABLE UnitPromotions ADD COLUMN 'ObtainUniqueUnitPromotionOnCityCapture' BOOLEAN DEFAULT false NOT NULL; -- this unit gets a random promotion from the enemy Civ's UU(s) upon city capture
ALTER TABLE UnitPromotions ADD COLUMN 'NewPromotionInCity' TEXT DEFAULT NULL; --Rosebow Infantry