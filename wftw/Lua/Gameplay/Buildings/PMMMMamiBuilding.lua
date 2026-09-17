-- PMMMMamiBuilding
-- Author: Vicevirtuoso
-- DateCreated: 6/12/2014 3:24:25 PM
--------------------------------------------------------------
-- [port] Phase 4 rewrite. The Teahouse used to drive twelve bit-packed dummy buildings that paid
-- Production into other players' capitals; a player could not see any of it and it subsidised her
-- rivals. It now pays Mami: each Teahouse city gets +2 Gold and +10% Gold for every Declaration of
-- Friendship she holds and every city-state she has pledged to protect, through one visible dummy
-- building that stacks. Design: docs/design/phase4-design-v1.md section 7.
--------------------------------------------------------------

include ('PMMMGeneralFunctions.lua');

local iBuilding = GameInfoTypes.BUILDING_PMMM_TEAHOUSE
local iPrereq = GameInfo.Technologies("Type ='" ..GameInfo.Buildings[iBuilding].PrereqTech.. "'")().ID
local iFriendshipDummy = GameInfoTypes.BUILDING_PMMM_TEAHOUSE_FRIENDSHIP_DUMMY

--A cap so a long diplomatic game cannot turn one city into an unbounded multiplier.
local iMaxFriends = GameDefines.MAMI_TEAHOUSE_MAX_FRIENDS or 5

--How many Declarations of Friendship and protected city-states does this player hold?
function GetMamiFriendCount(iPlayer)
	local pPlayer = Players[iPlayer]
	local pTeam = Teams[pPlayer:GetTeam()]
	local iCount = 0
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
		if i ~= iPlayer then
			local pLoop = Players[i]
			if pLoop:IsAlive() and pTeam:IsHasMet(pLoop:GetTeam()) and pPlayer:IsDoF(i) then
				iCount = iCount + 1
			end
		end
	end
	for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
		local pMinor = Players[i]
		if pMinor and pMinor:IsAlive() and pMinor:IsProtectedByMajor(iPlayer) then
			iCount = iCount + 1
		end
	end
	return math.min(iCount, iMaxFriends)
end

--Called once per player turn from PMMMUBBootstrapper.
function CheckMamiFriendship(iPlayer)
	local pPlayer = Players[iPlayer]
	if iPlayer >= iMaxCivs or not pPlayer:IsAlive() then return end
	if MapModData.gPMMMUniqueBuildings[iPlayer] ~= iBuilding then return end
	if not Teams[pPlayer:GetTeam()]:IsHasTech(iPrereq) then return end

	local iFriends = GetMamiFriendCount(iPlayer)
	for pCity in pPlayer:Cities() do
		if pCity:IsHasBuilding(iBuilding) then
			pCity:SetNumRealBuilding(iFriendshipDummy, iFriends)
		elseif pCity:GetNumRealBuilding(iFriendshipDummy) > 0 then
			pCity:SetNumRealBuilding(iFriendshipDummy, 0)
		end
	end
end
