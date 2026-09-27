-- PMMMDemonHomuraTrait
-- Author: Vicevirtuoso
-- DateCreated: 7/2/2014 12:57:46 PM
--------------------------------------------------------------

--[port] Phase 4: the old UA "Lovevil" is retired. Its subjugation ledger (the nine
--BUILDING_PMMM_DEMON_HOMURA_DUMMY_* Palace-yield buildings), the Magical Girl attrition in her
--territory, the level-5 immunity promotion, the capital city-view addin, the Golden Age points from
--Witch kills and from global Mood, and the Prodigy-to-subjugation credit are all gone, together with
--their data (SQL/Phase4/DemonHomura.sql deletes the rows and zeroes CapitalBonusPerKilledMagicalGirl
--and MagicalGirlAttrition).
--
--The new UA "Ai Yo" (docs/design/phase4-design-v1.md section 4, rulings 4 to 4f) has five clauses:
--  1. No unhappiness penalties at all (the engine treats her as never unhappy).          [DLL column]
--  2. +1% yields and combat strength per 5 unhappiness from cities and population, max +25%. [DLL column]
--  3. Base Prodigy rate halved: Traits.GreatPeopleRateModifier = -50.                   [data, done]
--  4. Never a Golden Age from any source; immune to ideology pressure.                  [DLL columns]
--  5. Gold from Witch kills (10 + 3 per era) and Labyrinth clears (25 + 10 per era).    [Lua, done]
--     Lives in the Devil Homura branches of GetGriefSeed and CheckDestroyWitchBarrier
--     (Lua/Gameplay/MagicalGirls/PMMMWitches.lua); the amounts are Defines rows.
--
--Clauses 1, 2 and 4 are DLL trait columns the maintainer is adding in parallel. Nothing in Lua
--emulates them; there is deliberately no per-turn happiness or yield dummy here.
--
--PMMMTraitBootstrapper.lua (not editable from this pass) still loads this file for her, calls the
--hooks below and registers SetNumDemonHomuraBuildings / DHCityInfoStack* with LuaEvents, and
--PMMMMagicalGirls.lua still calls OnDemonHomuraKillMG when a girl spawns for her. So every one of
--those names stays defined, as a no-op. Nothing here reads or writes PMMM.Subjugations any more.
--------------------------------------------------------------


--[port] Phase 4: the subjugation dummies are deleted; kept only because the bootstrapper registers
--it with LuaEvents.PMMMSetNumDemonHomuraBuildings. No-op.
function SetNumDemonHomuraBuildings(iPlayer)
end

--[port] Phase 4: no more subjugation credit. PMMMMagicalGirls.lua still calls this when a Magical
--Girl is created for her (it then removes the girl itself). No-op.
function OnDemonHomuraKillMG(iPlayer, iX, iY, iMGKey)
end

--[port] Phase 4: the CombatEnded / UnitPrekill / city-capture / promotion hooks the bootstrapper
--still calls. Their only job was the subjugation ledger and the attrition immunity. No-ops.
function DemonHomuraDirectKill(iAttackingPlayer, iAttackingUnit, attackerDamage, attackerFinalDamage, attackerMaxHP, iDefendingPlayer, iDefendingUnit, defenderDamage, defenderFinalDamage, defenderMaxHP, iInterceptingPlayer, iInterceptingUnit, interceptorDamage, plotX, plotY)
end

function DemonHomuraPrekill(iPlayer, iUnit, iUnitType, iX, iY, bDelay, iKiller)
end

function DemonHomuraOnCityCapture(iCapturedPlayer, bCapital, iX, iY, iCapturingPlayer, bConquest)
end

function OnPromotedToLevel5(iPlayer, iUnit)
end

--[port] Phase 4: per-turn hook. It used to refresh the Palace dummies, add Golden Age points from
--Mood and deal attrition damage to enemy Magical Girls in her territory; all three are retired.
--Ai Yo clauses 1, 2 and 4 (no unhappiness penalties, yield/combat scaling with unhappiness, no
--Golden Age, ideology immunity) are applied by the DLL trait columns, not here. No-op.
--[2026-09-27 ruling] Ai Yo: a Courthouse still lifts the extra Unhappiness an annexed city carries while
--occupied, but pays that amount out as Gold every turn (Traits.PMMMCourthouseUnhappinessToGold = Gold per point).
--It is a choice per city: keep the Unhappiness (it feeds the Ai Yo bonus) or build the Courthouse for Gold.
--"Extra" is what occupation adds over an ordinary city, from the Defines, so it follows either DLL's values.
local tPMMMCourthouseGoldRate = {}	-- player -> Gold per point, read from her trait once
local tPMMMCourthouseLastGold = {}	-- player -> last payout, so the alert only speaks when it changes

local function PMMMCourthouseGoldRate(iPlayer)
	if tPMMMCourthouseGoldRate[iPlayer] == nil then
		local iRate = 0
		local pPlayer = Players[iPlayer]
		local pLeader = pPlayer and GameInfo.Leaders[pPlayer:GetLeaderType()]
		if pLeader then
			for row in GameInfo.Leader_Traits("LeaderType = '" .. pLeader.Type .. "'") do
				local pTrait = GameInfo.Traits[row.TraitType]
				if pTrait and (pTrait.PMMMCourthouseUnhappinessToGold or 0) > iRate then
					iRate = pTrait.PMMMCourthouseUnhappinessToGold
				end
			end
		end
		tPMMMCourthouseGoldRate[iPlayer] = iRate
	end
	return tPMMMCourthouseGoldRate[iPlayer]
end

function DemonHomuraCourthouseGold(iPlayer)
	local iRate = PMMMCourthouseGoldRate(iPlayer)
	if iRate <= 0 then return end
	local pPlayer = Players[iPlayer]
	local fPerCity = math.max(0, (GameDefines.UNHAPPINESS_PER_CAPTURED_CITY or 0) - (GameDefines.UNHAPPINESS_PER_CITY or 0))
	local fPerPop = math.max(0, (GameDefines.UNHAPPINESS_PER_OCCUPIED_POPULATION or 0) - (GameDefines.UNHAPPINESS_PER_POPULATION or 0))
	local fExtra = 0
	for pCity in pPlayer:Cities() do
		if pCity:IsOccupied() and pCity:IsNoOccupiedUnhappiness() and not pCity:IsPuppet() then
			fExtra = fExtra + fPerCity + fPerPop * pCity:GetPopulation()
		end
	end
	local iGold = math.floor(fExtra * iRate)
	if iGold > 0 then
		pPlayer:ChangeGold(iGold)
	end
	if iPlayer == Game.GetActivePlayer() and iGold ~= (tPMMMCourthouseLastGold[iPlayer] or 0) and iGold > 0 then
		Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_AI_YO_COURTHOUSE_GOLD", iGold))
	end
	tPMMMCourthouseLastGold[iPlayer] = iGold
end

function DemonHomuraOnTurnFunctions(iPlayer)
	DemonHomuraCourthouseGold(iPlayer)
end

--[port] Phase 4: the capital city-view addin ("Stolen Magical Energy") is retired. The bootstrapper
--still registers these two with LuaEvents.CityInfoStack*; not inserting the addin key means the
--Dirty handler is never asked to draw anything.
function DHCityInfoStackDataRefresh(tCityInfoAddins, tEventsToHook)
end

function DHCityInfoStackDirty(sKey, pInstance)
end
