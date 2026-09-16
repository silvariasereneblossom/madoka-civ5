-- PMMMMamiBuilding
-- Author: Vicevirtuoso
-- DateCreated: 6/12/2014 3:24:25 PM
--------------------------------------------------------------


local iBuilding = GameInfoTypes.BUILDING_PMMM_TEAHOUSE
local iPrereq = GameInfo.Technologies("Type ='" ..GameInfo.Buildings[iBuilding].PrereqTech.. "'")().ID
local iMamiDummy = GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY
local iFriendDummy = GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY


--NOTE: This function currently will be broken if multiple Mamis are on the map. Each Mami will get their bonuses, but each of their friends will only get the bonus from the one with the
--highest PlayerID. Looking into a way to fix this without too much overhead (i.e. checking EVERY friendship EVERY turn is too much)
function CheckMamiFriendship(iPlayer)
	local pPlayer = Players[iPlayer]
	if iPlayer < iMaxCivs and pPlayer:IsAlive() then
		if MapModData.gPMMMUniqueBuildings[iPlayer] == iBuilding and Teams[pPlayer:GetTeam()]:IsHasTech(iPrereq) then
			dprint("Called function for FriendshipProductionModifier")
			--First, find out how many Teahouses she has.
			local iNumBuildingsInEmpire = 0;
			for pCity in pPlayer:Cities() do
				if pCity:IsHasBuilding(iBuilding) then
					iNumBuildingsInEmpire = iNumBuildingsInEmpire + 1;
				end
			end
			local iNumDoFs = 0;
			for iLoopID=0, iMaxCivs - 1 do
				local pOtherPlayer = Players[iLoopID]
				if pOtherPlayer:IsAlive() then
					if pPlayer ~= pOtherPlayer then
						if (pPlayer:IsDoF(pOtherPlayer:GetID())) then
							iNumDoFs = iNumDoFs + 1;
								pOtherPlayer:GetCapitalCity():SetNumRealBuilding(iFriendDummy, iNumBuildingsInEmpire)
						else
							pOtherPlayer:GetCapitalCity():SetNumRealBuilding(iFriendDummy, 0)
						end
					end
				end
			end
			pPlayer:GetCapitalCity():SetNumRealBuilding(iMamiDummy, iNumDoFs) --this dummy is only needed in the Capital since it uses Building_BuildingClassYieldChanges
		end
	end
end