-- Mami Trait Script
-- Author: Vicevirtuoso
-- DateCreated: 8/21/2013 12:04:47 AM
--------------------------------------------------------------


include('PMMMGeneralFunctions.lua');

--Gunpowder Combat Strength up per CS Ally
function CityStateCombatStrengthUp(iPlayer)
	if MapModData.gPMMMTraits[iPlayer].CityStateCombatStrengthModTimes100 > 0 then
		local pPlayer = Players[iPlayer]
		local iStrengthBonus = 0;
		for iLoopPlayer, pLoopPlayer in pairs(Players) do
			if pLoopPlayer:IsMinorCiv() then
				if pLoopPlayer:GetMinorCivFriendshipLevelWithMajor(iPlayer) >= 2 then
					iStrengthBonus = iStrengthBonus + 1;
				end
			end
		end
		iStrengthBonus = math.floor(iStrengthBonus * MapModData.gPMMMTraits[iPlayer].CityStateCombatStrengthModTimes100 / 100)
		for unit in pPlayer:Units() do
			if unit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_GUN then
				unit:SetBaseCombatStrength(GameInfo.Units[unit:GetUnitType()].Combat + iStrengthBonus)
			end
		end
	end
end


--------------------------------------------------------------
--[port] Phase 4: traded resources (spec section 7). Data half: SQL/Phase4/Mami.sql block 6.
-- Once per turn, count the resource types Mami imports through trade deals with other civilizations, and put
-- two stacking dummies in her capital:
--   BUILDING_PMMM_MAMI_TRADED_STRATEGIC  +1 Production, one copy per different strategic resource imported
--   BUILDING_PMMM_MAMI_TRADED_LUXURY     +1 Happiness,  one copy per different luxury resource imported
-- Reading: "traded" means imported through deals, as ruled for Kyouko in section 12 (city-state resources are
-- not traded); a type counts once however many copies arrive. Keyed on the trait, like the rest of this file.
-- This file is loaded by PMMMTraitBootstrapper.lua when a trait has CityStateCombatStrengthModTimes100 > 0
-- (TRAIT_FRIENDSHIP_PRODUCTION_BONUS has 100).
--------------------------------------------------------------
local sMamiTrait = "TRAIT_FRIENDSHIP_PRODUCTION_BONUS"
local iMamiStrategicDummy = GameInfoTypes.BUILDING_PMMM_MAMI_TRADED_STRATEGIC
local iMamiLuxuryDummy = GameInfoTypes.BUILDING_PMMM_MAMI_TRADED_LUXURY

--Put exactly iCount copies of a stacking dummy in the capital, and none anywhere else (the capital can move).
local function SetMamiCapitalDummy(pPlayer, iBuilding, iCount)
	local pCapital = pPlayer:GetCapitalCity()
	local iCapitalID = pCapital and pCapital:GetID() or -1
	for pCity in pPlayer:Cities() do
		if pCity:GetID() ~= iCapitalID and pCity:GetNumRealBuilding(iBuilding) > 0 then
			pCity:SetNumRealBuilding(iBuilding, 0)
		end
	end
	if pCapital and pCapital:GetNumRealBuilding(iBuilding) ~= iCount then
		pCapital:SetNumRealBuilding(iBuilding, iCount)
	end
end

function MamiTradedResourcesDoTurn(iPlayer)
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	if not tTrait or tTrait.Type ~= sMamiTrait then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end
	if not iMamiStrategicDummy or not iMamiLuxuryDummy then return end

	local iStrategic, iLuxury = 0, 0
	for pResource in GameInfo.Resources() do
		local iResource = pResource.ID
		--GetResourceImport sums deals, city-states and siphoned copies; take the city-state copies back out.
		local iDeal = pPlayer:GetResourceImport(iResource) - pPlayer:GetResourceFromMinors(iResource)
		if iDeal > 0 then
			if pResource.ResourceUsage == 1 then --RESOURCEUSAGE_STRATEGIC
				iStrategic = iStrategic + 1
			elseif pResource.ResourceUsage == 2 then --RESOURCEUSAGE_LUXURY
				iLuxury = iLuxury + 1
			end
		end
	end

	SetMamiCapitalDummy(pPlayer, iMamiStrategicDummy, iStrategic)
	SetMamiCapitalDummy(pPlayer, iMamiLuxuryDummy, iLuxury)
end
GameEvents.PlayerDoTurn.Add(MamiTradedResourcesDoTurn)
