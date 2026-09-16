-- Homura Trait
-- Author: Vicevirtuoso
-- DateCreated: 6/14/2014 8:36:03 PM
--------------------------------------------------------------

local iMaxCivs = GameDefines.MAX_MAJOR_CIVS

function UpdateHomuraUnitPromotions(pUnit, iPromotion, iThreshold)
	local iHP = pUnit:GetCurrHitPoints()
	local bSet = false
	if iHP <= iThreshold then
		bSet = true
	end
	pUnit:SetHasPromotion(iPromotion, bSet)
end

function OnHomuraDoTurn(iPlayer)
	if iPlayer < iMaxCivs and MapModData.gPMMMPromotionThresholds[iPlayer] then
		local pPlayer = Players[iPlayer]
		for pUnit in pPlayer:Units() do		
			for k, v in pairs(MapModData.gPMMMPromotionThresholds[iPlayer]) do
				UpdateHomuraUnitPromotions(pUnit, v.PromotionType, v.Threshold)
			end
		end
	end
end

function OnHomuraSetXY(iPlayer, iUnit, iX, iY)
	if iX > 0 and iY > 0 and iPlayer < iMaxCivs and MapModData.gPMMMPromotionThresholds[iPlayer] then
		local pPlayer = Players[iPlayer]
		local pUnit = pPlayer:GetUnitByID(iUnit)		
		for k, v in pairs(MapModData.gPMMMPromotionThresholds[iPlayer]) do
			UpdateHomuraUnitPromotions(pUnit, v.PromotionType, v.Threshold)
		end
	end
end




--Gonna be lazy and just code this one to the Civ itself rather than going through traits
function OnHomuraEnteredGame()
	local iPolicy = GameInfoTypes.POLICY_NEW_HOMURA_TRAIT
	local iCivType = GameInfoTypes.CIVILIZATION_HOMURA
	for iPlayer = 0, iMaxCivs - 1, 1 do
		local pPlayer = Players[iPlayer]
		if pPlayer:GetCivilizationType() == iCivType and not pPlayer:HasPolicy(iPolicy) then
			pPlayer:SetNumFreePolicies(1)
			pPlayer:SetHasPolicy(iPolicy, true)
			pPlayer:SetNumFreePolicies(0)
		end
    end
end