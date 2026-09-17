-- PMMMNagisaBuilding
-- Author: Vicevirtuoso
-- DateCreated: 6/14/2014 3:05:57 PM
--------------------------------------------------------------


include('PMMMGeneralFunctions.lua');
local iBuilding = GameInfoTypes.BUILDING_PMMM_MAGICAL_DAIRY
local iPrereq = GameInfo.Technologies("Type ='" ..GameInfo.Buildings[iBuilding].PrereqTech.. "'")().ID
--[port] Phase 4: the stacking dummy is gone. The Magical Dairy now replaces the Granary and pays its
--Cattle/Sheep yields through Building_ResourceYieldChanges, which the city screen shows on the tile.

local iCow = GameInfoTypes.RESOURCE_COW
local iSheep = GameInfoTypes.RESOURCE_SHEEP

local iGAPointsPerForeignResource = 5 --constant defined here to change later

function NagisaCitiesBonusTrade(iPlayer)
	local pPlayer = Players[iPlayer]
	if iPlayer < iMaxCivs and pPlayer:IsAlive() then
		if MapModData.gPMMMUniqueBuildings[iPlayer] == iBuilding and Teams[pPlayer:GetTeam()]:IsHasTech(iPrereq) then
			local iTotalGoldenAgePointsBase = 0
			if pPlayer:IsGoldenAge() then
				dprint("Player is in Golden Age. Do not add Golden Age points.")
				return
			end
			for k, v in pairs(pPlayer:GetTradeRoutes()) do
				if v.FromCity:IsHasBuilding(iBuilding) then
					dprint("Adding a trade route FROM " ..v.FromCity:GetName())
					pDestinationCity = v.ToCity
					if pDestinationCity:GetOwner() ~= v.FromCity:GetOwner() then
						dprint("Trade route is not domestic.")
						local iNumPlots = pDestinationCity:GetNumCityPlots()
						for iPlot = 0, iNumPlots - 1 do
							local pPlot = pDestinationCity:GetCityIndexPlot(iPlot)
							if pPlot then
								if pPlot:GetResourceType() == iCow or pPlot:GetResourceType() == iSheep then
									dprint("Found Cow/Sheep.")
									if pDestinationCity:IsWorkingPlot(pPlot) then
										dprint("Tile being worked!")
										iTotalGoldenAgePointsBase = iTotalGoldenAgePointsBase + 1
									end
								end
							end
						end
					end
				end
			end
			for k, v in pairs(pPlayer:GetTradeRoutesToYou()) do
				if v.ToCity:IsHasBuilding(iBuilding) then
					dprint("Adding a trade route TO " ..v.FromCity:GetName())
					pDestinationCity = v.FromCity
					if pDestinationCity:GetOwner() ~= v.ToCity:GetOwner() then
						dprint("Trade route is not domestic.")
						local iNumPlots = pDestinationCity:GetNumCityPlots()
						for iPlot = 0, iNumPlots - 1 do
							local pPlot = pDestinationCity:GetCityIndexPlot(iPlot)
							if pPlot then
								if pPlot:GetResourceType() == iCow or pPlot:GetResourceType() == iSheep then
									dprint("Found Cow/Sheep.")
									if pDestinationCity:IsWorkingPlot(pPlot) then
										dprint("Tile being worked!")
										iTotalGoldenAgePointsBase = iTotalGoldenAgePointsBase + 1
									end
								end
							end
						end
					end
				end
			end
			iTotalGoldenAgePointsBase = iTotalGoldenAgePointsBase * iGAPointsPerForeignResource
			if iTotalGoldenAgePointsBase > 0 then
				dprint("Adding Golden Age points. Total: " ..iTotalGoldenAgePointsBase)
				pPlayer:ChangeGoldenAgeProgressMeter(iTotalGoldenAgePointsBase)
				if iPlayer == Game:GetActivePlayer() then
					Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_NAGISA_GOLDEN_AGE_POINTS", iTotalGoldenAgePointsBase))
				end
			end
		end
	end
end
