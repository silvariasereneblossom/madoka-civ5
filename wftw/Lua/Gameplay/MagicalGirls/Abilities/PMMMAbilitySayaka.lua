-- PMMMAbilitySayaka
-- [port] Phase 4: Sayaka Miki's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/Sayaka.sql.
--------------------------------------------------------------
-- Baldamente Fortissimo. Design: docs/design/phase4-design-v1.md section 5: every friendly unit
-- within two tiles of her, herself included, heals 25% of its maximum hit points at once and takes
-- half damage while defending for two turns. It deals no damage and costs no Soul Gem; the six-turn
-- cooldown is the whole of the price.
--
-- It has no target. The mission row therefore carries no PMMMMissionRange and no PMMMTargetType, the
-- way MISSION_PMMM_DULL_PAIN does, so clicking the button fires it at once instead of opening target
-- selection, and the framework hands the handler her own plot. The handler centres on her own plot in
-- any case, so the ability behaves the same however it was invoked.
--------------------------------------------------------------

--How far the song carries. Not read from the Missions row: PMMMMissionRange is what turns a mission
--into a targeted one in the UI, so a no-target ability must leave it at 0 and keep its radius here.
local iFortissimoRange = 2

--How much of a unit's maximum hit points the song restores, as a percentage.
local iFortissimoHealPercent = 25

--How long the guard lasts, in the owner's turns. The promotion carries DamageTakenMod -50.
local iFortissimoGuardTurns = 2

local iFortissimoGuard = GameInfoTypes.PROMOTION_PMMM_FORTISSIMO_GUARD

--Every unit of her own team standing within iRange of pCentre, her own tile included.
--Allies on the same team are covered as well, which is what "friendly" means everywhere else in the
--mod; units of a separate civilization we are merely at peace with are not.
local function ForEachFriendlyUnitInRange(pPlayer, pCentre, iRange, fnDo)
	if not pCentre then return end
	local iTeam = pPlayer:GetTeam()
	for pAreaPlot in PlotAreaSpiralIterator(pCentre, iRange, 1, false, false, true) do
		if pAreaPlot then
			for i = 0, pAreaPlot:GetNumUnits() - 1 do
				local pTarget = pAreaPlot:GetUnit(i)
				if pTarget and pTarget:GetTeam() == iTeam then
					fnDo(pTarget)
				end
			end
		end
	end
end

--------------------------------------------------------------
-- Sayaka Miki: Baldamente Fortissimo
-- No damage. Everyone around her is healed and hardened.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_BALDAMENTE_FORTISSIMO", {
	Cooldown = 6,
	--No target: it is centred on her, so the framework must not try to decode a target plot.
	NeedsTarget = false,
	--Playing it is the whole of her turn, the same as every other leader ability.
	EndsTurn = true,
	--No CanUseHere: the guard alone is worth the button even when nobody is hurt, so the only thing
	--that can grey it out is the cooldown.

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--Centred on her, never on the plot she was handed: the ability has no target and the AI path
		--passes whatever plot its scorer liked.
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iFortissimoRange, function(pTarget)
			--Heal 25% of maximum hit points, never past full health.
			local iHeal = math.floor((pTarget:GetMaxHitPoints() * iFortissimoHealPercent) / 100)
			iHeal = math.min(pTarget:GetDamage(), iHeal)
			if iHeal > 0 then
				pTarget:ChangeDamage(-1 * iHeal)
			end
			--Half damage while defending, for the next two turns. The framework takes the promotion
			--away again when it expires.
			PMMMApplyTimedPromotion(pTarget, iFortissimoGuard, iFortissimoGuardTurns)
		end)

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO"))
		end
	end,

	--Sung when it saves something: two or more hurt friends in earshot, or she is under half health
	--herself and the guard is what keeps her alive. The plot the framework offers is her own -- the
	--mission has no range, so the AI's search is a single tile -- and the scorer ignores it for the
	--same reason Execute does.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local iDamaged, iTotalDamage = 0, 0
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iFortissimoRange, function(pTarget)
			local iDamage = pTarget:GetDamage()
			if iDamage > 0 then
				iDamaged = iDamaged + 1
				iTotalDamage = iTotalDamage + iDamage
			end
		end)
		local bSheIsHurt = (pUnit:GetDamage() * 2) >= pUnit:GetMaxHitPoints()
		if iDamaged < 2 and not bSheIsHurt then return nil end
		return 100 + iTotalDamage
	end,
})
