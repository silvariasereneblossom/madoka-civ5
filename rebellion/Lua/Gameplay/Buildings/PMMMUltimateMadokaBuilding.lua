-- PMMMUltimateMadokaBuilding
-- Author: Vicevirtuoso
-- DateCreated: 7/10/2014 5:01:26 PM
--------------------------------------------------------------

local iLuminousGarden = GameInfoTypes.BUILDING_PMMM_LUMINOUS_GARDEN
local iMGCombatType = GameInfoTypes.UNITCOMBAT_MAGICALGIRL
local iMaxXP = 30
local iXPGain = 1

function LuminousRecoverSoulGem(iPlayer)
	local pPlayer = Players[iPlayer]
	for pUnit in pPlayer:Units() do
		if pUnit:GetUnitCombatType() == iMGCombatType and pUnit:GetExperience() <= iMaxXP then
			if pUnit:GetPlot():IsCity() then
				local pCity = pUnit:GetPlot():GetPlotCity()
				if pCity then
					if pCity:IsHasBuilding(iLuminousGarden) then
						pUnit:ChangeExperience(iXPGain)
					end
				end
			end
		end
	end
end