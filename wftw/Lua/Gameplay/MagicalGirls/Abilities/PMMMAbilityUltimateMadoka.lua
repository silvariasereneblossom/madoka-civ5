-- PMMMAbilityUltimateMadoka
-- [port] Phase 4: Ultimate Madoka's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/UltimateMadoka.sql.
--------------------------------------------------------------
-- Nothing To Despair, Ever, the active half. Design: docs/design/phase4-design-v1.md section 2 and
-- ruling 10 in section 11: one shot at four times her strength, never aimed at a city, and only half
-- as hard against another Magical Girl. Firing it also clears 5% of the Soul Gem of every girl of
-- hers within two tiles, the Law of Cycles reaching the ones who came with her.
--
-- The immunities the ability is named for (never loses Mood, never clouds, never becomes a Witch)
-- are the passive half and are carried by PROMOTION_PMMM_NEVER_DESPAIR in SQL/Phase4/Abilities.sql,
-- read by the girl-state code. Nothing here touches them.
--------------------------------------------------------------

local iMagicalGirlClass = GameInfoTypes.UNITCLASS_PMMM_MAGICAL_GIRL

local fStrikeMultiplier = 4.0   --ruling 10 keeps the 4x, so a hit is a kill on a contemporary unit
local fGirlMultiplier = 2.0     --halved against a Magical Girl, ruling 10 again
local iSoulGemRecovery = 5      --percent of the Soul Gem each nearby girl gets back
local iRecoveryRange = 2        --tiles around Madoka herself, the centre tile included

--The one unit she shoots at: the first enemy on the tile she can see. Cities are never targets, so a
--tile with a city on it is refused outright rather than letting her shoot past its walls.
local function FirstEnemyOnPlot(pPlayer, pPlot)
	if not pPlot or pPlot:IsCity() then return nil end
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			return pTarget
		end
	end
	return nil
end

--Half strength against another girl, full against everything else.
local function StrikeMultiplierFor(pTarget)
	if pTarget:GetUnitClassType() == iMagicalGirlClass then return fGirlMultiplier end
	return fStrikeMultiplier
end

--------------------------------------------------------------
-- Ultimate Madoka: Nothing To Despair, Ever
-- One target, four times her strength, no cities, half against a girl; every girl of hers within two
-- tiles recovers 5% Soul Gem. No Soul Gem cost: hers can never cloud in the first place.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_NOTHING_TO_DESPAIR", {
	Cooldown = 5,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return FirstEnemyOnPlot(pPlayer, pPlot) ~= nil
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--The shot itself: a single unit, never the city on the tile.
		local pTarget = FirstEnemyOnPlot(pPlayer, pPlot)
		if pTarget then
			PMMMVirtualAttack(pUnit, pTarget, StrikeMultiplierFor(pTarget))
		end

		--Hope spreads from where she stands, not from where she shot.
		for pAreaPlot in PlotAreaSpiralIterator(pUnit:GetPlot(), iRecoveryRange, 1, false, false, true) do
			if pAreaPlot then
				for i = 0, pAreaPlot:GetNumUnits() - 1 do
					local pAlly = pAreaPlot:GetUnit(i)
					if pAlly and pAlly:GetOwner() == iPlayer and pAlly:GetUnitClassType() == iMagicalGirlClass then
						local iOtherMGKey = GetMagicalGirlKey(iPlayer, pAlly:GetID())
						--[port] GetMagicalGirlKey returns false on a miss
						if iOtherMGKey then
							--Negative corruption is recovery: DoChangeCorruption subtracts its argument.
							DoChangeCorruption(-iSoulGemRecovery, iOtherMGKey)
						end
					end
				end
			end
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_NOTHING_TO_DESPAIR"))
		end
	end,

	--The shot kills whatever it touches, so spend it on the biggest thing in range rather than on
	--something a normal attack would finish; a girl is worth half because she only takes half.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local pTarget = FirstEnemyOnPlot(pPlayer, pPlot)
		if not pTarget then return nil end
		local iScore = pTarget:GetBaseCombatStrength() * 100 + pTarget:GetCurrHitPoints()
		if pTarget:GetUnitClassType() == iMagicalGirlClass then iScore = iScore / 2 end
		return iScore
	end,
})
