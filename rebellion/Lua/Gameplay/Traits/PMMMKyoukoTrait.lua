-- Kyouko Trait
-- Author: Vicevirtuoso
-- DateCreated: 6/14/2014 1:56:55 PM
--------------------------------------------------------------

local iDummy = GameInfoTypes.BUILDING_PMMM_KYOUKO_DUMMY_GROWTH
local iTrackingDummy = GameInfoTypes.BUILDING_PMMM_KYOUKO_TRAIT_DUMMY


function GrowthPerCityFollowing(iCityOwner, iReligion)
	local iGrowthPercent = 0;
	for iPlayer, pPlayer in pairs(Players) do
		if pPlayer:IsEverAlive() and not pPlayer:IsMinorCiv() and iPlayer ~= 63 then
			local pTraitType = GetTraitType(pPlayer)
			if (pTraitType.GrowthBonusFromWorldReligionTimes1000 > 0 and pPlayer:HasCreatedReligion()) then
				if (iReligion == pPlayer:GetReligionCreatedByPlayer()) then
					for _, pPlayer2 in pairs(Players) do
						for pCity in pPlayer2:Cities() do
							if (iReligion == pCity:GetReligiousMajority()) then
								iGrowthPercent = iGrowthPercent + (pTraitType.GrowthBonusFromWorldReligionTimes1000 / 10);
							end
						end
					end
					iGrowthPercent = math.floor(iGrowthPercent)
					pPlayer:GetCapitalCity():SetNumRealBuilding(iDummy, iGrowthPercent)
				end
			end
		end
	end
end

function NewPopulationFaithGrowth(iX, iY, iOld, iNew)
	if iNew > iOld and iNew > 1 then
		local pPlot = Map.GetPlot(iX, iY)
		if pPlot then
			local pCity = pPlot:GetPlotCity()
			if pCity and pCity:IsCapital() then
				local iPlayer = pCity:GetOwner()
				local pPlayer = Players[iPlayer]
				if MapModData.gPMMMTraits[iPlayer] then
					if MapModData.gPMMMTraits[iPlayer].FaithBonusOnCapitalGrowth > 0 then
						local iDummies = pCity:GetNumRealBuilding(iTrackingDummy)
						if iDummies < iNew then
							pCity:SetNumRealBuilding(iTrackingDummy, iNew)
							local iFaith = iNew * MapModData.gPMMMTraits[iPlayer].FaithBonusOnCapitalGrowth
							pPlayer:ChangeFaith(iFaith)
							if iPlayer == Game:GetActivePlayer() then
								Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_KYOUKO_FAITH", iFaith))
							end
						end
					end
				end
			end
		end
	end
end