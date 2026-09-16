-- Tiro Musketeer
-- Author: Vicevirtuoso
-- DateCreated: 6/19/2014 7:06:29 PM
--------------------------------------------------------------

local iPromotion = GameInfoTypes.PROMOTION_PMMM_TIRO_MUSKETEER_BONUS
local iMusketeer = GameInfoTypes.UNIT_PMMM_TIRO_MUSKETEER

function CheckTiroMusketeer(iPlayer, iUnit)
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
		if pUnit:GetUnitType() == iMusketeer then
		local pPlot = pUnit:GetPlot()
		if pPlot then
			local iOwner = pPlot:GetOwner()
			if iOwner >= GameDefines.MAX_MAJOR_CIVS and iOwner < GameDefines.MAX_CIV_PLAYERS then
				local pOwner = Players[iOwner]
				if pOwner:GetMinorCivFriendshipLevelWithMajor(iPlayer) >= 2 then
					pUnit:SetHasPromotion(iPromotion, true)
				else
					pUnit:SetHasPromotion(iPromotion, false)
				end
			else
				pUnit:SetHasPromotion(iPromotion, false)
			end
		end
	end
end