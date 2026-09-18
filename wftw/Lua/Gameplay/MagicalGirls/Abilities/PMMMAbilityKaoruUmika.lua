-- PMMMAbilityKaoruUmika
-- [port] Phase 4: Kazumi's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/KaoruUmika.sql.
--------------------------------------------------------------
-- Rule Break. Design: docs/design/phase4-design-v1.md section 9: a friendly Magical Girl within two
-- tiles may take a promotion at once, whatever her experience says. No damage, no Soul Gem cost, ten
-- turns between uses. Kazumi may aim it at herself; FRIENDLY_MAGICAL_GIRL targeting includes her own
-- tile, so nothing extra is needed for that.
--------------------------------------------------------------

local iMagicalGirlClass = GameInfoTypes.UNITCLASS_PMMM_MAGICAL_GIRL

--The girl on this tile who wants the promotion most: one of ours who is not already promotion-ready,
--and among those the most hurt, since she is the one who needs the new trick soonest. Returns nil
--when the tile holds nobody the ability can help, which is also what makes the button grey out.
local function BestGirlOnPlot(pPlayer, pPlot)
	if not pPlot or not pPlot:IsUnit() then return nil end
	local iPlayer = pPlayer:GetID()
	local pBest, iBestDamage
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pAlly = pPlot:GetUnit(i)
		if pAlly and pAlly:GetOwner() == iPlayer and pAlly:GetUnitClassType() == iMagicalGirlClass
				and not pAlly:IsPromotionReady() then
			local iOtherMGKey = GetMagicalGirlKey(iPlayer, pAlly:GetID())
			--[port] GetMagicalGirlKey returns false on a miss
			if iOtherMGKey then
				local iDamage = pAlly:GetDamage()
				if not iBestDamage or iDamage > iBestDamage then
					iBestDamage = iDamage
					pBest = pAlly
				end
			end
		end
	end
	return pBest
end

--------------------------------------------------------------
-- Kazumi: Rule Break
-- One friendly Magical Girl within two tiles, herself included, may promote immediately.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_RULE_BREAK", {
	Cooldown = 10,
	--Rewriting the rules is the whole of her turn, the same as every other leader ability.
	EndsTurn = true,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return BestGirlOnPlot(pPlayer, pPlot) ~= nil
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local pTarget = BestGirlOnPlot(pPlayer, pPlot)
		if not pTarget then return end

		pTarget:SetPromotionReady(true)

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_RULE_BREAK"))
		end
	end,

	--Same rule as the chooser: a girl who cannot promote already, the most damaged one first.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local pTarget = BestGirlOnPlot(pPlayer, pPlot)
		if not pTarget then return nil end
		return 100 + pTarget:GetDamage()
	end,
})


--------------------------------------------------------------
-- [port] Phase 4: the Freezer's Grief Seed (design section 9).
-- The Freezer panel pushes MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED on one of the player's own units with
-- iData1 = the stored girl's key. The mission is hidden, so HiddenCustomMissionPossible already allows it and
-- HiddenCustomMissionCompleted ends it at once. The work is in DoFreezerGriefSeed (Traits/PMMMPleiadesTrait.lua),
-- which exists only when a Freezer civilization is in the game, hence the check. Registered here because this
-- file is always loaded into the gameplay context, and it runs in single player as well as multiplayer (the
-- bootstrapper's multiplayer-only route is now a no-op).
--------------------------------------------------------------
local iFreezerGriefSeedMission = GameInfoTypes.MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED

function KazumiFreezerGriefSeedMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iFreezerGriefSeedMission and iMission == iFreezerGriefSeedMission and DoFreezerGriefSeed then
		DoFreezerGriefSeed(iPlayer, iData1)
	end
	return 0
end

GameEvents.CustomMissionStart.Add(KazumiFreezerGriefSeedMissionStart)
