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


--------------------------------------------------------------
-- [port] Phase 4: the rest of Ultimate Madoka's kit (design section 2, rulings 8 and 9).
--
--  * Summon Witch Form: any girl reborn from the Law of Cycles (PROMOTION_PMMM_CYCLE_RETURNED, granted in
--    ReturnFromLawOfCycles) can take on or put away her Witch Form, +20% Combat Strength, as often as she likes.
--    No target, no cost, and it does not end her turn. Not a leader ability, so it has its own mission hooks.
--    [port] Phase 4: ruling 15.3 (2026-09-18) names it "Summon Herald of the Cycle" in the text (promotion "Herald
--    of the Cycle"); the Types keep their WITCH_FORM names. The old Summon Witch, which spawned a Witch unit, is
--    gone (Traits/PMMMUltimateMadokaTrait.lua).
--  * The returned girl's XP lock: the promotion's ExperiencePercent -100 zeroes combat XP; this clamps her back to
--    the XP she returned with against anything else that adds XP (area-effect XP promotions, handicap bonuses, Lua).
--  * Expending a Great Person grants Golden Age points: 50 per era (Ancient 50 ... Information 400), scaled by the
--    game speed's GoldenAgePercent (Quick 40, Epic 62, Marathon 100 in the Ancient Era).
--  * The Herald of Madoka's AI rule, which lives in UniqueUnits/PMMMHeraldOfMadoka.lua.
--------------------------------------------------------------

local iWitchFormMission = GameInfoTypes.MISSION_PMMM_SUMMON_WITCH_FORM
local iWitchFormPromotion = GameInfoTypes.PROMOTION_PMMM_WITCH_FORM
local iCycleReturnedPromotion = GameInfoTypes.PROMOTION_PMMM_CYCLE_RETURNED
local sUltimateMadokaTrait = "TRAIT_NO_WITCHES"
local iGoldenAgePointsPerEra = 50

local function IsReturnedGirl(pUnit)
	return pUnit ~= nil and iCycleReturnedPromotion ~= nil
		and pUnit:GetUnitClassType() == iMagicalGirlClass
		and pUnit:IsHasPromotion(iCycleReturnedPromotion)
end

function UMadokaWitchFormMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn, iPlotX, iPlotY, bTestVisible)
	if not iWitchFormMission or iMission ~= iWitchFormMission then return false end
	local pPlayer = Players[iPlayer]
	if not pPlayer then return false end
	return IsReturnedGirl(pPlayer:GetUnitByID(iUnit))
end

function UMadokaWitchFormMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if not iWitchFormMission or iMission ~= iWitchFormMission then return 0 end
	local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
	if IsReturnedGirl(pUnit) then
		--A toggle: on if she is not in Witch Form, off if she is. Her moves are left alone.
		pUnit:SetHasPromotion(iWitchFormPromotion, not pUnit:IsHasPromotion(iWitchFormPromotion))
	end
	return 0
end

function UMadokaWitchFormMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	return iWitchFormMission ~= nil and iMission == iWitchFormMission
end

GameEvents.CustomMissionPossible.Add(UMadokaWitchFormMissionPossible)
GameEvents.CustomMissionStart.Add(UMadokaWitchFormMissionStart)
GameEvents.CustomMissionCompleted.Add(UMadokaWitchFormMissionCompleted)

--Once per turn: hold every returned girl at the XP she came back with, and let the AI use Witch Form (it has no
--drawback, so an AI girl simply keeps it on) and its Heralds.
function UMadokaCycleDoTurn(iPlayer)
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() or iPlayer >= GameDefines.MAX_MAJOR_CIVS then return end
	local bAI = not pPlayer:IsHuman()
	for pUnit in pPlayer:Units() do
		if IsReturnedGirl(pUnit) then
			local iMGKey = GetMagicalGirlKey(iPlayer, pUnit:GetID())
			local iLocked = iMGKey and MagicalGirls[iMGKey].CycleLockedXP
			if iLocked and pUnit:GetExperience() > iLocked then
				pUnit:SetExperience(iLocked)
			end
			if bAI and iWitchFormPromotion and not pUnit:IsHasPromotion(iWitchFormPromotion) then
				pUnit:SetHasPromotion(iWitchFormPromotion, true)
			end
		end
	end
	if bAI and HeraldAILeadAway then
		HeraldAILeadAway(iPlayer)
	end
end

GameEvents.PlayerDoTurn.Add(UMadokaCycleDoTurn)

--Ruling 9: every Great Person she expends is also a push toward a Golden Age.
function UMadokaGreatPersonExpended(iPlayer, iUnit, iUnitType, iX, iY)
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	if not tTrait or tTrait.Type ~= sUltimateMadokaTrait then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end
	local pSpeed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
	local iSpeedPercent = (pSpeed and pSpeed.GoldenAgePercent) or 100
	local iPoints = math.floor(iGoldenAgePointsPerEra * (pPlayer:GetCurrentEra() + 1) * iSpeedPercent / 100)
	if iPoints > 0 then
		pPlayer:ChangeGoldenAgeProgressMeter(iPoints)
		if iPlayer == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_UMADOKA_GP_GOLDEN_AGE", iPoints))
		end
	end
end

PMMMAddGreatPersonExpendedHandler(UMadokaGreatPersonExpended)
