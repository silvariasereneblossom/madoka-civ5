-- PMMMShiromeTrait
-- Author: Vice
-- DateCreated: 8/9/2014 9:50:40 PM
--------------------------------------------------------------


function OnPlayerDoTurnShiromeTrait(iPlayer)
	--[port] only ever-alive players have a gPMMMTraits entry
	if not MapModData.gPMMMTraits[iPlayer] then return end
	--[port] the civ-location reveal used to run from the per-client Events.LoadScreenClose
	--and mutated game state there; do it here instead, once per player, on every client
	DoShiromeRevealCivLocations(iPlayer)
	if MapModData.gPMMMTraits[iPlayer].LeaderMGIntrigueTurns > 0 then
		local iLastTurn = PMMM.PlayerLastGotFreeIntrigueTurn[iPlayer] or -100
		if Game:GetGameTurn() - iLastTurn >= MapModData.gPMMMTraits[iPlayer].LeaderMGIntrigueTurns then
			local pLeader = GetLeaderMagicalGirl(iPlayer)
			if pLeader then
				local tCities = {}
				for pAreaPlot in PlotAreaSpiralIterator(pLeader:GetPlot(), 2, false, false, false, true) do
					if pAreaPlot:IsCity() then
						local pCity = pAreaPlot:GetPlotCity()
						if pCity:GetOwner() ~= iPlayer then
							tCities[#tCities + 1] = pCity
						end
					end
				end
				local pChosenCity;
				if #tCities > 1 then
					pChosenCity = tCities[Game.Rand(#tCities, "PMMM Shirome Trait Roll") + 1]
				elseif #tCities == 1 then
					pChosenCity = tCities[1]
				end
				if pChosenCity then
					Players[iPlayer]:GetRandomIntrigue(pChosenCity)
					PMMM.PlayerLastGotFreeIntrigueTurn[iPlayer] = Game:GetGameTurn()
				end
			end
		end
	end
end


--[port] was OnLoadScreenCloseShiromeTrait, run from the per-client Events.LoadScreenClose.
--It now runs from the gamecore PlayerDoTurn path, once per player, guarded by a persisted flag.
--It also used to index gPMMMTraits for every slot up to iMaxCivs, but only ever-alive players
--have an entry there.
function DoShiromeRevealCivLocations(iPlayer)
	PMMM.ShiromeRevealedCivLocations = PMMM.ShiromeRevealedCivLocations or {}
	if PMMM.ShiromeRevealedCivLocations[iPlayer] then return end
	PMMM.ShiromeRevealedCivLocations[iPlayer] = true
	local tTrait = MapModData.gPMMMTraits[iPlayer]
	if not tTrait then return end
	if tTrait.RevealCivLocations and (tTrait.RevealCivLocations == 1 or tTrait.RevealCivLocations == true) then
		local iTeam = Players[iPlayer]:GetTeam()
		for j = 0, iMaxCivs - 1, 1 do
			if iPlayer ~= j then
				local pPlayer = Players[j]
				if pPlayer:IsEverAlive() then
					local pStartPlot = pPlayer:GetStartingPlot()
					if pStartPlot then
						for pAreaPlot in PlotAreaSpiralIterator(pStartPlot, 1, false, false, false, true) do
							pAreaPlot:SetRevealed(iTeam, true)
						end
					end
				end
			end
		end
	end
end