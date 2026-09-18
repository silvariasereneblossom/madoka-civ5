-- PMMMLeaderAbilityDefs
-- [port] Phase 4: the individual Leader Magical Girl abilities. The shared machinery is in
-- PMMMLeaderAbilities.lua; each entry here is only the ability's own behaviour, its cooldown and
-- its AI target rule. Data half: SQL/Phase4/Abilities.sql.
--------------------------------------------------------------

include("PMMMLeaderAbilities.lua")

--Per-civ abilities, one file each
include("PMMMAbilityUltimateMadoka.lua")
include("PMMMAbilityHomura.lua")
include("PMMMAbilityDemonHomura.lua")
include("PMMMAbilitySayaka.lua")
include("PMMMAbilityKyouko.lua")
include("PMMMAbilityKaoruUmika.lua")
include("PMMMAbilityNagisa.lua")
include("PMMMAbilityOrikoKirika.lua")

local iPluviaVulnerable = GameInfoTypes.PROMOTION_PMMM_PLUVIA_VULNERABLE
local iTiroRecoil = GameInfoTypes.PROMOTION_PMMM_TIRO_FINALE_RECOIL

--Is there an enemy of this player anywhere on the plot?
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
-- Madoka Kaname: Pluvia Magica
-- Half-strength hit on the target and every tile around it; everything struck takes 15% more
-- damage for the rest of the turn.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_PLUVIA_MAGICA", {
	Cooldown = 4,
	SoulGemCost = 20,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local pTeam = Teams[pPlayer:GetTeam()]
		local iTeam = pPlayer:GetTeam()
		--The target tile and its six neighbours, each hit once. The last argument to the iterator is
		--'include the centre': without it the primary target was skipped entirely.
		for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, true) do
			if pAreaPlot then
				for i = 0, pAreaPlot:GetNumUnits() - 1 do
					local pTarget = pAreaPlot:GetUnit(i)
					if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
						PMMMVirtualAttack(pUnit, pTarget, 0.5)
						--The vulnerability lasts the rest of this turn only.
						PMMMApplyTimedPromotion(pTarget, iPluviaVulnerable, 1)
					end
				end
			end
		end
		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_PLUVIA_MAGICA"))
		end
	end,

	--Prefer the tile whose neighbourhood holds the most enemies.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		if not PlotHasEnemy(pPlayer, pUnit, pPlot) then return nil end
		local iScore = 0
		for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, true) do
			local iPlotScore = PMMMScoreEnemyPlot(pPlayer, pUnit, pAreaPlot)
			if iPlotScore then iScore = iScore + iPlotScore end
		end
		if iScore == 0 then return nil end
		return iScore
	end,
})

--------------------------------------------------------------
-- Mami Tomoe: Tiro Finale
-- 150% on the target, half that on everything within a tile of it, and she is left exposed.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_TIRO_FINALE_MG", {
	Cooldown = 4,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local pTeam = Teams[pPlayer:GetTeam()]
		local iTeam = pPlayer:GetTeam()

		--Primary target: the first visible enemy on the tile, or the city if there is one.
		PMMMVirtualAttackPlot(pUnit, pPlot, 1.5, true)

		--Splash: one enemy on each surrounding tile, at half the primary's strength.
		for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, false) do
			if pAreaPlot and pAreaPlot ~= pPlot then
				PMMMVirtualAttackPlot(pUnit, pAreaPlot, 0.75, true)
			end
		end

		--Recoil: she is easier to kill until her next turn.
		PMMMApplyTimedPromotion(pUnit, iTiroRecoil, 1)

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_TIRO_FINALE"))
		end
	end,

	--Fire at the weakest enemy stack in range, but only when she is not the one who will die for it.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local iScore = PMMMScoreEnemyPlot(pPlayer, pUnit, pPlot)
		if not iScore then return nil end
		if pUnit:GetDamage() > 50 then return nil end
		return iScore
	end,
})
