-- PMMMAbilityDemonHomura
-- [port] Phase 4: Devil Homura's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/DemonHomura.sql.
--------------------------------------------------------------
-- Falsified Phenomena, the active half. Design: docs/design/phase4-design-v1.md section 4 and
-- ruling 4 in section 11: an area hit at 150% of her strength on the target tile and the ring around
-- it, no Soul Gem cost, five-turn cooldown.
--
-- The three permanent properties the spec gives her girl -- always in Despair, no Despair penalties,
-- and never a Witch -- are the passive half. They are carried by PROMOTION_PMMM_ALWAYS_DESPAIR in
-- SQL/Phase4/Abilities.sql, read by the girl-state code. Nothing here touches them and
-- PMMMMagicalGirls.lua is deliberately untouched.
--------------------------------------------------------------

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

--------------------------------------------------------------
-- Devil Homura: Falsified Phenomena
-- She rewrites what happened on seven tiles at once. Every enemy unit on the target tile and on the
-- six tiles around it takes a hit at 150% of her strength -- an area attack, so whole stacks are
-- struck, not one unit per tile. No Soul Gem cost.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_FALSIFIED_PHENOMENA", {
	Cooldown = 5,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--The target tile first. PlotAreaSpiralIterator's last argument is "include the centre", and
		--it is false in the ring loop below, so the target would otherwise be skipped.
		PMMMVirtualAttackPlot(pUnit, pPlot, 1.5, false)

		--Then the six tiles around it. bFirstOnly is false throughout: every enemy unit standing in
		--the area is hit, and an enemy city in the area is damaged too.
		for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, false) do
			if pAreaPlot and pAreaPlot ~= pPlot then
				PMMMVirtualAttackPlot(pUnit, pAreaPlot, 1.5, false)
			end
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_FALSIFIED_PHENOMENA"))
		end
	end,

	--Fire at the tile whose neighbourhood holds the most enemies; the area is what the ability is for.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		if not PlotHasEnemy(pPlayer, pUnit, pPlot) then return nil end
		local iScore = PMMMScoreEnemyPlot(pPlayer, pUnit, pPlot) or 0
		for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, false) do
			if pAreaPlot and pAreaPlot ~= pPlot then
				local iPlotScore = PMMMScoreEnemyPlot(pPlayer, pUnit, pAreaPlot)
				if iPlotScore then iScore = iScore + iPlotScore end
			end
		end
		if iScore == 0 then return nil end
		return iScore
	end,
})
