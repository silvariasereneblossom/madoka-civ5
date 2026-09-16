-- Data Storage Lua for PMMM Mod
-- Author: Vicevirtuoso
-- DateCreated: 6/12/2014 12:34:19 PM
--------------------------------------------------------------

--This Lua file defines constants for use throughout the mod.

iMaxCivs = GameDefines.MAX_MAJOR_CIVS
iMaxCivsAndCS = GameDefines.MAX_CIV_PLAYERS


MapModData.PMMMConversionDataInit = MapModData.PMMMConversionDataInit or false;

if not MapModData.PMMMConversionDataInit then
	print("Initializing tables for first load.")
	
	MapModData.gPMMMTraits = {}

	for i = 0, iMaxCivs - 1, 1 do
		local pPlayer = Players[i]
		if pPlayer:IsEverAlive() then
			leaderType = GameInfo.Leaders[pPlayer:GetLeaderType()].Type
			traitType = GameInfo.Leader_Traits("LeaderType ='" .. leaderType .. "'")().TraitType
			trait = GameInfo.Traits[traitType]
			MapModData.gPMMMTraits[i] = {}
			MapModData.gPMMMTraits[i].Type = trait.Type
			MapModData.gPMMMTraits[i].CityStateCombatStrengthModTimes100 = trait.CityStateCombatStrengthModTimes100
			MapModData.gPMMMTraits[i].GreatPersonProgressFromKills = trait.GreatPersonProgressFromKills
			MapModData.gPMMMTraits[i].CombatBonusFromTourismInfluence = trait.CombatBonusFromTourismInfluence
			MapModData.gPMMMTraits[i].MagicalGirlOnGreatPersonUse = trait.MagicalGirlOnGreatPersonUse
			MapModData.gPMMMTraits[i].GrowthBonusFromWorldReligionTimes1000 = trait.GrowthBonusFromWorldReligionTimes1000
			MapModData.gPMMMTraits[i].FaithBonusOnCapitalGrowth = trait.FaithBonusOnCapitalGrowth
			MapModData.gPMMMTraits[i].HappinessToMetEnemies = trait.HappinessToMetEnemies
			MapModData.gPMMMTraits[i].UnhappinessPerCivilizationMet = trait.UnhappinessPerCivilizationMet
			MapModData.gPMMMTraits[i].YieldBonusPerCivilizationMet = trait.YieldBonusPerCivilizationMet
		end
	end

	--Get UBs from this mod.
	MapModData.gPMMMUniqueBuildings = {}
	
	for i = 0, iMaxCivs - 1, 1 do
		local pPlayer = Players[i]
		if pPlayer:IsEverAlive() then
			for row in GameInfo.Civilization_BuildingClassOverrides() do
				if row.CivilizationType == GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type then
					if string.find(row.BuildingType, "_PMMM_") then
						MapModData.gPMMMUniqueBuildings[i] = GameInfo.Buildings("Type ='" ..row.BuildingType.. "'")().ID
					end
				end
			end
		end
	end

	--Which promotions grant a new promotion when on a specific Improvement?
	MapModData.gPMMMOnImprovementPromotions = {}

	for promotion in GameInfo.Promotion_PMMM_GrantNewPromotionOnImprovement() do
		local promotionType = GameInfo.UnitPromotions("Type ='" ..promotion.PromotionType.. "'")().ID
		MapModData.gPMMMOnImprovementPromotions[promotionType] =	{
				["ImprovementType"] = GameInfo.Improvements("Type ='" ..promotion.ImprovementType.. "'")().ID,
				["NewPromotionType"] = GameInfo.UnitPromotions("Type ='" ..promotion.NewPromotionType.. "'")().ID
		}
	end
	
	--Which promotions grant a new promotion when in a City?
	MapModData.gPMMMInCityPromotions = {}

	for promotion in GameInfo.UnitPromotions() do
		if promotion.NewPromotionInCity ~= nil then
			MapModData.gPMMMInCityPromotions[promotion.ID] = GameInfo.UnitPromotions("Type ='" ..promotion.NewPromotionInCity.. "'")().ID
		end
	end
	

	--Which promotions grant a new promotion when an enemy is near?
	MapModData.gPMMMAdjacentEnemyBuffs = {}

	for row in GameInfo.Promotion_PMMM_GrantNewPromotionNearEnemy() do
		local promotionType = GameInfo.UnitPromotions("Type ='" ..row.PromotionType.. "'")().ID
		MapModData.gPMMMAdjacentEnemyBuffs[promotionType] =	{
				["Radius"] = row.Radius,
				["NewPromotionType"] = GameInfo.UnitPromotions("Type ='" ..row.NewPromotionType.. "'")().ID
		}
	end

	--Which promotions allow stealing other UU's promotions on city capture?
	MapModData.gPMMMStealUUPromotions = {}

	for row in GameInfo.UnitPromotions() do
		if row.ObtainUniqueUnitPromotionOnCityCapture == 1 then
			table.insert(MapModData.gPMMMStealUUPromotions, row.ID)
		end
	end


	--Which traits can have resources automatically spread during a Golden Age?
	MapModData.gPMMMGoldenAgeResources = {}

	for k, v in pairs(MapModData.gPMMMTraits) do
		local bIsTrait = false
		for row in GameInfo.Trait_PMMM_GoldenAgeResourceSpread() do
			if row.TraitType == v.Type then
				MapModData.gPMMMGoldenAgeResources[k] = {}
				bIsTrait = true
				break
			end
		end
		if bIsTrait then
			for row in GameInfo.Trait_PMMM_GoldenAgeResourceSpread() do 
				if row.TraitType == v.Type then
					table.insert(MapModData.gPMMMGoldenAgeResources[k], {["ResourceType"] = GameInfo.Resources("Type = '" ..row.ResourceType.. "'")().ID,
					["ProbabilityPerTurn"] = row.ProbabilityPerTurn	})
				end
			end
		end
	end
	
	--v12: Which traits grant promotions to units at HP thresholds?
	MapModData.gPMMMPromotionThresholds = {}

	for k, v in pairs(MapModData.gPMMMTraits) do
		local bIsTrait = false
		for row in GameInfo.Trait_PromotionAtHPThreshold() do
			if row.TraitType == v.Type then
				MapModData.gPMMMPromotionThresholds[k] = {}
				bIsTrait = true
				break
			end
		end
		if bIsTrait then
			for row in GameInfo.Trait_PromotionAtHPThreshold() do 
				if row.TraitType == v.Type then
					table.insert(MapModData.gPMMMPromotionThresholds[k], {["PromotionType"] = GameInfo.UnitPromotions("Type = '" ..row.PromotionType.. "'")().ID,
					["Threshold"] = row.Threshold	})
				end
			end
		end
	end

	--Variable to state whether all of the above values have been cached already. When set to true, this function will not run a second time regardless of whether or not the game is reloaded
	MapModData.PMMMConversionDataInit = true
end