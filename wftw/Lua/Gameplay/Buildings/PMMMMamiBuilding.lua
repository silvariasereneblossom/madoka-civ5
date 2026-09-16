-- PMMMMamiBuilding
-- Author: Vicevirtuoso
-- DateCreated: 6/12/2014 3:24:25 PM
--------------------------------------------------------------



include ('PMMMGeneralFunctions.lua');

local iBuilding = GameInfoTypes.BUILDING_PMMM_TEAHOUSE
local iPrereq = GameInfo.Technologies("Type ='" ..GameInfo.Buildings[iBuilding].PrereqTech.. "'")().ID
local iMamiDummy = GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY
local iFriendDummy = GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY


--[port] write the friend dummy bit set into one capital; 0 clears it
function SetMamiFriendDummies(pCity, iNumBuildings)
	local tBuildingTable = toBits(iNumBuildings)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_1, tBuildingTable[1] or 0)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_2, tBuildingTable[2] or 0)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_4, tBuildingTable[3] or 0)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_8, tBuildingTable[4] or 0)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_16, tBuildingTable[5] or 0)
	pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIEND_DUMMY_32, tBuildingTable[6] or 0)
end


--[port] once no Teahouse civ is alive any more, no player's turn runs the pass above (the
--gamecore only raises PlayerDoTurn for living players), so the dummies it left in every other
--civ's capital would stay forever. Sweep them once, and re-arm if a Teahouse civ comes back.
function ClearMamiFriendDummiesIfSourceGone()
	for i = 0, iMaxCivs - 1 do
		if MapModData.gPMMMUniqueBuildings[i] == iBuilding and Players[i]:IsAlive() then
			PMMM.MamiFriendDummiesCleared = nil
			return
		end
	end
	if PMMM.MamiFriendDummiesCleared then return end
	PMMM.MamiFriendDummiesCleared = true
	for i = 0, iMaxCivs - 1 do
		local pOtherCapital = Players[i]:GetCapitalCity()
		if pOtherCapital then
			SetMamiFriendDummies(pOtherCapital, 0)
		end
	end
end


--NOTE: This function currently will be broken if multiple Mamis are on the map. Each Mami will get their bonuses, but each of their friends will only get the bonus from the one with the
--highest PlayerID. Looking into a way to fix this without too much overhead (i.e. checking EVERY friendship EVERY turn is too much)
function CheckMamiFriendship(iPlayer)
	local pPlayer = Players[iPlayer]
	if iPlayer < iMaxCivs then
		--[port] the friend dummies live in OTHER civs' capitals, so once no Teahouse civ is left
		--alive nothing ran to take them away again
		ClearMamiFriendDummiesIfSourceGone()
		--[port] the body used to be gated on IsAlive() and the tech test as well, so the dummies
		--were left in place once the source condition went false. Gate only on the (static) civ
		--identity and write 0 through the normal pass when the condition does not hold.
		if MapModData.gPMMMUniqueBuildings[iPlayer] == iBuilding then
			local bHasSource = pPlayer:IsAlive() and Teams[pPlayer:GetTeam()]:IsHasTech(iPrereq)
			dprint("Called function for FriendshipProductionModifier")
			--First, find out how many Teahouses she has.
			local iNumBuildingsInEmpire = 0;
			if bHasSource then
				for pCity in pPlayer:Cities() do
					if pCity:IsHasBuilding(iBuilding) then
						iNumBuildingsInEmpire = iNumBuildingsInEmpire + 1;
					end
				end
			end
			local iNumDoFs = 0;
			for iLoopID=0, iMaxCivs - 1 do
				local pOtherPlayer = Players[iLoopID]
				local iBuildingsToSet = iNumBuildingsInEmpire
				if pOtherPlayer:IsAlive() then
					--[port] Mami's own capital used to receive the friend dummies on top of her own set
					if pPlayer ~= pOtherPlayer then
						if bHasSource and pPlayer:IsDoF(pOtherPlayer:GetID()) then
							iNumDoFs = iNumDoFs + 1;
						else
							iBuildingsToSet = 0
						end
						local pOtherCapital = pOtherPlayer:GetCapitalCity()
						if pOtherCapital then
							SetMamiFriendDummies(pOtherCapital, iBuildingsToSet)
						end
					end
				end
			end
			local pCapital = pPlayer:GetCapitalCity()
			if pCapital then
				local tBuildingTable = toBits(iNumDoFs)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_1, tBuildingTable[1] or 0)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_2, tBuildingTable[2] or 0)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_4, tBuildingTable[3] or 0)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_8, tBuildingTable[4] or 0)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_16, tBuildingTable[5] or 0)
				pCapital:SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_32, tBuildingTable[6] or 0)
			end
		end
	end
end