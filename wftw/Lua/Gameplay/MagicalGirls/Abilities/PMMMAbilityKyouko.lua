-- PMMMAbilityKyouko
-- [port] Phase 4: Kyouko Sakura's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/Kyouko.sql.
--------------------------------------------------------------

--Range comes from the Missions row so the two halves cannot drift apart.
local pKugatachiMission = GameInfo.Missions["MISSION_PMMM_KUGATACHI"]
local iKugatachiRange = (pKugatachiMission and pKugatachiMission.PMMMMissionRange) or 2

--Is there an enemy of this player anywhere on the plot?
--(PMMMLeaderAbilityDefs.lua has the same helper, but it is file-local there and is declared after
--this file is included, so each ability file that needs it keeps its own copy.)
local function PlotHasEnemy(pPlayer, pUnit, pPlot)
	if not pPlot then return false end
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			return true
		end
	end
	if pPlot:IsCity() then
		local pCity = pPlot:GetPlotCity()
		if pCity and pTeam:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then return true end
	end
	return false
end

--The hex direction from pFrom to pTarget, or nil if pTarget is not on a straight hex line from it.
--Map.PlotDirection walks one tile at a time, so we simply try each of the six directions in turn and
--see which one reaches the target within iRange steps. This is cheap (6 x range steps) and needs no
--hex-coordinate arithmetic of our own.
local function GetHexLineDirection(pFrom, pTarget, iRange)
	if not pFrom or not pTarget then return nil end
	local iTargetX, iTargetY = pTarget:GetX(), pTarget:GetY()
	for eDirection = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
		local pStep = pFrom
		for _ = 1, iRange do
			pStep = Map.PlotDirection(pStep:GetX(), pStep:GetY(), eDirection)
			if not pStep then break end
			if pStep:GetX() == iTargetX and pStep:GetY() == iTargetY then return eDirection end
		end
	end
	return nil
end

--The tiles the thrust passes through: the target, then the two tiles directly beyond it along the
--same direction. On a hex grid not every tile within range 2 sits on a straight line from her -- the
--six "diagonal" tiles of the second ring are reached by turning a corner -- and there is no line to
--continue for those. GetHexLineDirection returns nil there and the thrust hits the target alone.
--Tiles that would fall off the edge of the map are dropped the same way.
local function GetKugatachiLine(pUnit, pPlot)
	local tLine = { pPlot }
	local eDirection = GetHexLineDirection(pUnit:GetPlot(), pPlot, iKugatachiRange)
	if eDirection then
		local pStep = pPlot
		for _ = 1, 2 do
			pStep = Map.PlotDirection(pStep:GetX(), pStep:GetY(), eDirection)
			if not pStep then break end
			tLine[#tLine + 1] = pStep
		end
	end
	return tLine
end

--------------------------------------------------------------
-- Kyouko Sakura: Kugatachi
-- A spear thrust straight through the enemy line: the target tile and the two tiles beyond it along
-- the same hex direction, each struck at 200% of her strength. No Soul Gem cost.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_KUGATACHI", {
	Cooldown = 4,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--One enemy per tile along the line: the spear passes through, it does not fan out. A city
		--standing on one of the tiles is struck as well, as it is for Tiro Finale.
		for _, pLinePlot in ipairs(GetKugatachiLine(pUnit, pPlot)) do
			PMMMVirtualAttackPlot(pUnit, pLinePlot, 2.0, true)
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_KUGATACHI"))
		end
	end,

	--Prefer the aim that puts the most enemies on the line, so she is rewarded for lining them up.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		if not PlotHasEnemy(pPlayer, pUnit, pPlot) then return nil end
		local iScore = 0
		for _, pLinePlot in ipairs(GetKugatachiLine(pUnit, pPlot)) do
			local iPlotScore = PMMMScoreEnemyPlot(pPlayer, pUnit, pLinePlot)
			if iPlotScore then iScore = iScore + iPlotScore end
		end
		if iScore == 0 then return nil end
		return iScore
	end,
})
