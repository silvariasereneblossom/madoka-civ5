-- PMMMUltimateMadokaBuilding
-- Author: Vicevirtuoso
-- DateCreated: 7/10/2014 5:01:26 PM
--------------------------------------------------------------




local iLuminousGarden = GameInfoTypes.BUILDING_PMMM_LUMINOUS_GARDEN
--[port] Phase 4 (design section 2): the Luminous Garden also replaces the Grand Temple. One building cannot fill two
--classes, so that half is its own building. Its +10 Mood for every girl is data (Buildings.PMMMMoodBonus, read by the
--Buildings Mood modifier); its empire-wide Soul Gem recovery is here.
local iLuminousGardenGrandTemple = GameInfoTypes.BUILDING_PMMM_LUMINOUS_GARDEN_GRAND_TEMPLE
local iGrandTempleRecovery = 1	--percent of the Soul Gem every one of her girls recovers each turn while she owns it

function LuminousRecoverSoulGem(iPlayer)
	local pPlayer = Players[iPlayer]
	--[port] Phase 4: owning the Grand Temple half heals every girl on the map, wherever she stands. It stacks with the
	--Garden's own 1% for a girl stationed in a Luminous Garden city.
	local bEmpireWide = iLuminousGardenGrandTemple and pPlayer:CountNumBuildings(iLuminousGardenGrandTemple) > 0
	for pUnit in pPlayer:Units() do
		if pUnit:GetUnitType() == GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL then
			local iRecovery = 0
			if pUnit:GetPlot():IsCity() then
				local pCity = pUnit:GetPlot():GetPlotCity()
				if pCity:HasBuilding(iLuminousGarden) then
					iRecovery = iRecovery + 1
				end
			end
			if bEmpireWide then
				iRecovery = iRecovery + iGrandTempleRecovery
			end
			if iRecovery > 0 then
				local iMGKey = GetMagicalGirlKey(iPlayer, pUnit:GetID())
				--[port] GetMagicalGirlKey returns false on a miss
				if iMGKey then
					DoChangeCorruption(-iRecovery, iMGKey)
				end
			end
		end
	end
end
