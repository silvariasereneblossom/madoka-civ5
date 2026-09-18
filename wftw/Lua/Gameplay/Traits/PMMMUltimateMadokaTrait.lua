-- PMMMUltimateMadokaTrait
-- Author: Vicevirtuoso
-- DateCreated: 7/2/2014 12:58:04 PM
--------------------------------------------------------------



--[port] Phase 4: ruling 15.3 (2026-09-18) removed the old Summon Witch (MISSION_PMMM_SUMMON_WITCH /
--MISSION_PMMM_DISMISS_WITCH, which spawned a Witch unit beside the girl). SQL/Phase4/UltimateMadoka.sql sets
--Traits.CanSummonWitches = 0. PMMMTraitBootstrapper.lua still calls the four hooks below by name, so they stay
--defined, but none of them offers, starts or runs a summon any more. The Law of Cycles return
--(CheckLOCMagicalGirls) is unchanged. Her Witch Form ("Summon Herald of the Cycle") lives in
--Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilityUltimateMadoka.lua and is not affected.

local iBrokenPsyche = GameInfoTypes.PROMOTION_PMMM_BROKEN_PSYCHE

function CheckLOCMagicalGirls(iPlayer)
	--[port] Phase 4: `a and b or c` read the trait of a player past iMaxCivs; parenthesised, and nil-safe.
	local tTrait = iPlayer < iMaxCivs and MapModData.gPMMMTraits[iPlayer]
	if tTrait and (tTrait.NoWitches == true or tTrait.NoWitches == 1) then
		--[port] Phase 4: collect first, in key order, then return them: the return spawns units, and the order decides
		--their IDs, so it must be the same on every machine.
		local tDue = {}
		local iCurTurn = Game:GetGameTurn()
		for k, v in pairs(MagicalGirls) do
			if v.Owner == iPlayer and v.Status == GameInfoTypes.MGACTIONSTATE_CYCLING then
				--[port] Phase 4: each girl carries her own stay (Lead Away is 5 turns at Standard, the Cycle itself 10).
				if (iCurTurn - v.CycleStartTurn) >= (v.CycleTurns or MapModData.gPMMMLawOfCyclesTurns) then
					tDue[#tDue + 1] = k
				end
			end
		end
		table.sort(tDue, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ipairs(tDue) do
			ReturnFromLawOfCycles(k)
		end
	end
end




--[port] Phase 4: ruling 15.3. Summon Witch is never possible, so the button is never offered.
function SummonWitchCustomMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	return false
end


--[port] Phase 4: ruling 15.3. Nothing to start: no Witch is ever spawned or dismissed.
function SummonWitchCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	return 0
end


--[port] Phase 4: ruling 15.3. The missions can no longer be pushed, so there is nothing to complete.
function SummonWitchCustomMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	return false
end


--[port] Phase 4: ruling 15.3. The AI no longer summons Witches. All that is left is to let a Broken Psyche
--cooldown carried over from a save made before the ruling run out, so the promotion does not stick forever.
function WitchCooldownUpkeep(iPlayer)
	if iPlayer >= iMaxCivs then return end
	local pPlayer = Players[iPlayer]
	for pUnit in pPlayer:Units() do
		if pUnit:GetUnitClassType() == GameInfoTypes.UNITCLASS_PMMM_MAGICAL_GIRL then
			local iMGKey = GetMagicalGirlKey(iPlayer, pUnit:GetID())
			--[port] GetMagicalGirlKey returns false on a miss
			if iMGKey and MagicalGirls[iMGKey] and MagicalGirls[iMGKey].SummonedWitchCooldown then
				MagicalGirls[iMGKey].SummonedWitchCooldown = MagicalGirls[iMGKey].SummonedWitchCooldown - 1
				if MagicalGirls[iMGKey].SummonedWitchCooldown <= 0 then
					MagicalGirls[iMGKey].SummonedWitchCooldown = nil
					if iBrokenPsyche then pUnit:SetHasPromotion(iBrokenPsyche, false) end
				end
			end
		end
	end
end


--[port] Phase 4: ruling 15.3. No summoned Witch exists to tie to a girl's death, so nothing to do.
function UMadokaOnWitchOrMGDeath(iPlayer, iUnit, iUnitType, iX, iY, bDelay, iByPlayer)
end
