-- PMMMHeraldOfMadoka
-- Author: Vicevirtuoso
-- DateCreated: 7/15/2014 11:39:02 AM
--------------------------------------------------------------



local iPromotion = GameInfoTypes.PROMOTION_PMMM_HERALD_OF_MADOKA
local iMissionType = MissionTypes.MISSION_PMMM_LEAD_AWAY

--[port] Phase 4 (design section 2): a girl led away stays in the Cycle 5 turns at Standard speed instead of the Law of
--Cycles' 10, scaled by game speed with the rule the rest of the mod uses (DealDuration / 30, rounded up; Quick 5,
--Epic 8, Marathon 15), and comes back with one free promotion of her new owner's choice.
local iLeadAwayTurnsStandard = 5
local iLeadAwayRange = 1	--MISSION_PMMM_LEAD_AWAY's PMMMMissionRange

local function GetLeadAwayTurns()
	local pSpeed = GameInfo.GameSpeeds[PreGame.GetGameSpeed()]
	if not pSpeed then return iLeadAwayTurnsStandard end
	return math.max(math.ceil(iLeadAwayTurnsStandard * pSpeed.DealDuration / 30), 1)
end

function HeraldCustomMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	if iPlayer < iMaxCivs then
		local pPlayer = Players[iPlayer]
		local pUnit = pPlayer:GetUnitByID(iUnit)
		--lazy and specifying one promotion for now
		if pUnit and pUnit:IsHasPromotion(iPromotion) and iMission == iMissionType then
			if pUnit:GetSpreadsLeft() >= 2 then
				return true
			else
				return bTestVisible
			end
		end
	end
	return false
end


--[port] Phase 4: the target click arrives here as a pushed mission carrying the plot as negated coordinates (the
--InputHandler in PMMMWishForTheWorldMain; the unit panel opens the targeting itself). This used to only toggle
--the highlights again, so Lead Away never fired. It now runs on every machine and does the work.
function HeraldCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iMission == iMissionType then
		local iX, iY = -iData1, -iData2
		if iX >= 0 and iY >= 0 then
			local pPlot = Map.GetPlot(iX, iY)
			local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
			if pPlot and pUnit and pUnit:GetSpreadsLeft() >= 2
			and Map.PlotDistance(pUnit:GetX(), pUnit:GetY(), iX, iY) <= iLeadAwayRange then
				DoLawOfCyclesMission(iPlayer, pUnit, pPlot)
			end
		end
	end
	return 0
end


function HeraldCustomMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	--[port] this is a TESTANY hook that pops the mission queue, so the active-player test
	--made it return a different value on every client
	if iMission == iMissionType then
		return true
	end
	return false
end

--[port] Phase 4: the girl Lead Away may take: an enemy (at war) Magical Girl, never a leader girl, whose Soul Gem is
--Critical. Leader girls are refused by IsLeader, the check this function always had; a missing IsLeader counts as
--a leader so an incomplete record is never taken.
local function GetLeadAwayTarget(iPlayer, pPlot)
	local pTeam = Teams[Players[iPlayer]:GetTeam()]
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pEnemyUnit = pPlot:GetUnit(i)	--[port] was a global
		if pEnemyUnit and pEnemyUnit:GetUnitType() == GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL
		and pTeam:IsAtWar(pEnemyUnit:GetTeam()) then
			local iMGKey = GetMagicalGirlKey(pEnemyUnit:GetOwner(), pEnemyUnit:GetID())
			if iMGKey and MagicalGirls[iMGKey].IsLeader == false
			and MagicalGirls[iMGKey].SoulGemState == GameInfoTypes.PMMM_SGSTATE_CRITICAL then
				return iMGKey
			end
		end
	end
	return nil
end

function DoLawOfCyclesMission(iPlayer, pUnit, pPlot)
	--[port] ran one index past the end and dereferenced the nil it got back
	local iMGKey = GetLeadAwayTarget(iPlayer, pPlot)
	if iMGKey then
		--Time to leave this world! (for 5 turns at Standard speed, and she comes back with a free promotion)
		DoLawOfCyclesTakeaway(iMGKey, iPlayer, GetLeadAwayTurns(), true)
		pUnit:Kill(true)
	end
end

--[port] Phase 4: AI rule. An AI Herald with its two spreads left leads away any valid girl within range; it does not
--go looking for one. Called once per turn from PMMMAbilityUltimateMadoka.lua.
function HeraldAILeadAway(iPlayer)
	local pPlayer = Players[iPlayer]
	if not pPlayer or pPlayer:IsHuman() then return end
	local tHeralds = {}
	for pUnit in pPlayer:Units() do
		if pUnit:IsHasPromotion(iPromotion) and pUnit:GetSpreadsLeft() >= 2 then
			tHeralds[#tHeralds + 1] = pUnit:GetID()
		end
	end
	for _, iUnit in ipairs(tHeralds) do
		local pUnit = pPlayer:GetUnitByID(iUnit)
		if pUnit then
			for pAreaPlot in PlotAreaSpiralIterator(pUnit:GetPlot(), iLeadAwayRange, 1, false, false, false) do
				if pAreaPlot and GetLeadAwayTarget(iPlayer, pAreaPlot) then
					DoLawOfCyclesMission(iPlayer, pUnit, pAreaPlot)
					break
				end
			end
		end
	end
end
