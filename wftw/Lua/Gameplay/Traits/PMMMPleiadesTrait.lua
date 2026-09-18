-- PMMMPleiadesTrait
-- Author: Vicevirtuoso
-- DateCreated: 8/13/2014 6:56:59 PM
--------------------------------------------------------------
--[port] Phase 4: the Freezer is deterministic. Design: docs/design/phase4-design-v1.md section 9.
--
--   * Capture (kept): when Kazumi's side kills a non-leader enemy Magical Girl in combat and the Freezer has
--     room, the girl's promotions, experience and level are stored.
--   * Capacity (kept): INITIAL_FREEZER_STORAGE (3) + 1 per POP_NEEDED_FOR_NEXT_FREEZER_STORAGE (5) Population
--     in the Capital.
--   * Revival (new): a stored girl revives as Kazumi's Magical Girl, with her stored promotions and level,
--     after max(5, 15 - 2 x Academies Kazumi owns) turns. The Academy count is read every turn, so building or
--     losing an Academy moves every timer at once. Using a Grief Seed on a stored girl takes 3 turns off her
--     timer; the 5-turn floor limits the Academy reduction only, so Grief Seeds may push a timer to 0, and a
--     girl whose timer reaches 0 revives at once.
--   * Retired: the five-band prediction score, the science-diversion slider, the "successes" counter, the
--     "Begin" experiment button and its mission, and the Soul Gem decay in storage (its only remaining effect
--     was a Witch at your own Capital, which the timer makes pointless). No voluntary action spawns a Witch.
--   * Capital capture (kept, made deterministic): if an enemy conquers Kazumi's Capital, every stored girl is
--     released to the conqueror as one of their Magical Girls if they take part in the Magical Girl system,
--     otherwise her Soul Gem shatters. No Witch, no dice.
--
-- Per-girl state lives on MagicalGirls[key] (persisted): FreezerPlayer, FreezerStartTurn, FreezerSeedTurns.
-- All state changes run on synced GameEvents (PlayerDoTurn, CombatEnded, CityCaptureComplete) or on the custom
-- mission MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED, whose GameEvents hook is registered from
-- PMMMAbilityKaoruUmika.lua (that file is always loaded; this one only when a Freezer civ is in the game).
--------------------------------------------------------------

local iMagicalGirlType = GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL
local iFreezerState = GameInfoTypes.MGACTIONSTATE_FREEZER
local iAcademy = GameInfoTypes.IMPROVEMENT_ACADEMY

--[port] Phase 4: the Freezer's numbers. Kept here rather than in GameDefines because the spec fixes them and
--the Defines file is not ours to extend; the trait text in SQL/Phase4/KaoruUmika.sql states the same numbers.
FREEZER_BASE_TURNS = 15
FREEZER_TURNS_PER_ACADEMY = 2
FREEZER_MIN_TURNS = 5
FREEZER_GRIEF_SEED_TURNS = 3

local function HasFreezer(iPlayer)
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	return tTrait ~= nil and (tTrait.EnableFreezerSystem == true or tTrait.EnableFreezerSystem == 1)
end

function GetFreezerStorageMax(iPlayer, ttable)
	if HasFreezer(iPlayer) then
		local iAmount = GameDefines.INITIAL_FREEZER_STORAGE
		local pCapital = Players[iPlayer]:GetCapitalCity()
		if pCapital then
			local iPop = pCapital:GetPopulation()
			local iExtra = math.floor(iPop / GameDefines.POP_NEEDED_FOR_NEXT_FREEZER_STORAGE)
			iAmount = iAmount + iExtra
		end
		if ttable then
			ttable[0] = iAmount
		end
		return iAmount
	end
	if ttable then
		ttable[0] = -1
	end
	return -1
end

LuaEvents.PMMMGetFreezerStorageMax.Add(GetFreezerStorageMax)

function GetFreezerCurrentStorage(iPlayer, ttable)
	if HasFreezer(iPlayer) then
		local iNum = 0;
		for k, v in pairs(MagicalGirls) do
			if v.FreezerPlayer and v.FreezerPlayer == iPlayer then
				iNum = iNum + 1;
			end
		end
		if ttable then
			ttable[0] = iNum
		end
		return iNum
	end
	if ttable then
		ttable[0] = -1
	end
	return -1
end

LuaEvents.PMMMGetFreezerCurrentStorage.Add(GetFreezerCurrentStorage)

--[port] Phase 4: Academies the player owns. This used to walk every city's workable plots, which counted an
--Academy twice when two cities shared its tile; the player's own improvement count has no such overlap.
function GetNumAcademies(iPlayer, ttable)
	local pPlayer = Players[iPlayer]
	local iNum = 0
	if pPlayer and iAcademy then
		iNum = pPlayer:GetImprovementCount(iAcademy)
	end
	if ttable then
		ttable[0] = iNum
	end
	return iNum
end

LuaEvents.PMMMGetNumAcademies.Add(GetNumAcademies)

--[port] Phase 4: how long a stored girl stays frozen in total, before any Grief Seeds.
function GetFreezerRevivalDuration(iPlayer)
	local iTurns = FREEZER_BASE_TURNS - FREEZER_TURNS_PER_ACADEMY * GetNumAcademies(iPlayer)
	return math.max(iTurns, FREEZER_MIN_TURNS)
end

--[port] Phase 4: turns left before this girl revives (0 = she revives at the next check).
--Read-only, so the Freezer panel may call it through LuaEvents.PMMMGetFreezerRevivalTurns.
function GetFreezerRevivalTurns(iPlayer, iMGKey, ttable)
	local tGirl = MagicalGirls[iMGKey]
	local iDuration = GetFreezerRevivalDuration(iPlayer)
	local iLeft = iDuration
	if tGirl and tGirl.FreezerPlayer == iPlayer then
		--A girl stored before this version has no start turn yet; OnPleiadesDoTurn stamps one, and until
		--then she simply shows the full duration.
		local iStart = tGirl.FreezerStartTurn or Game.GetGameTurn()
		local iElapsed = Game.GetGameTurn() - iStart
		iLeft = iDuration - iElapsed - (tGirl.FreezerSeedTurns or 0)
	end
	iLeft = math.max(iLeft, 0)
	if ttable then
		ttable[0] = iLeft
		ttable[1] = iDuration
	end
	return iLeft
end

LuaEvents.PMMMGetFreezerRevivalTurns.Add(GetFreezerRevivalTurns)

--[port] Phase 4: bring a stored girl back as iPlayer's Magical Girl beside pPlot, with her stored promotions,
--experience and level (OnCreatedMagicalGirl applies those from her record). Returns the new unit or nil.
local function ReleaseFromFreezer(iPlayer, iMGKey, pPlot)
	local pPlayer = Players[iPlayer]
	local tGirl = MagicalGirls[iMGKey]
	if not pPlayer or not tGirl or not pPlot then return nil end

	tGirl.FreezerPlayer = nil
	tGirl.FreezerStartTurn = nil
	tGirl.FreezerSeedTurns = nil

	--tMagicalGirlSpawnTable is the shared table OnCreatedMagicalGirl reads; it is replaced after every spawn,
	--so it is always named through the global.
	tMagicalGirlSpawnTable["ID"] = iMGKey
	--She died in the fight that captured her, so her last recorded HP may be 0; she comes back healthy.
	tMagicalGirlSpawnTable["RespawnHP"] = GameDefines.MAX_HIT_POINTS
	local pUnit = pPlayer:InitUnit(iMagicalGirlType, pPlot:GetX(), pPlot:GetY(), UnitAITypes.UNITAI_ATTACK)
	if not pUnit then
		tMagicalGirlSpawnTable = {}
		return nil
	end
	pUnit:JumpToNearestValidPlot()
	SetMagicalGirlStrength(iPlayer, pUnit:GetID())
	pUnit:SetMoves(0)

	--A fresh start under a new flag: the mood clocks restart, as they do when a girl defects, and her home is
	--now her new owner's Capital.
	local iTurn = Game.GetGameTurn()
	tGirl.LastVacationTurn = iTurn
	tGirl.LastSocializedTurn = iTurn
	tGirl.HomeCityLastVisited = iTurn
	tGirl.LastCombatTurn = iTurn
	local pCapital = pPlayer:GetCapitalCity()
	if pCapital then
		tGirl.HomeCity = CompileCityID(pCapital)
	end
	return pUnit
end

--[port] Phase 4: revival when the timer runs out. Replaces DoPleiadesRevival and its five outcomes.
function DoFreezerRevival(iPlayer, iMGKey)
	local pPlayer = Players[iPlayer]
	local pCapital = pPlayer and pPlayer:GetCapitalCity()
	if not pCapital then return false end	--no Capital, no Freezer to leave; she waits
	local sName = Locale.ConvertTextKey(MagicalGirls[iMGKey].Name)
	local pUnit = ReleaseFromFreezer(iPlayer, iMGKey, pCapital:Plot())
	if not pUnit then return false end
	local sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_FREEZER_REVIVED_TITLE")
	local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_FREEZER_REVIVED_TEXT", sName)
	pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER, sText, sTitle, pUnit:GetX(), pUnit:GetY(), iMagicalGirlType)
	Events.SerialEventCityInfoDirty()
	Events.SerialEventUnitInfoDirty()
	return true
end

--[port] Phase 4: stored girls of iPlayer in key order, so revivals happen in the same order on every machine.
local function GetStoredGirlKeys(iPlayer)
	local tKeys = {}
	for k, v in pairs(MagicalGirls) do
		if v.FreezerPlayer == iPlayer then
			tKeys[#tKeys + 1] = k
		end
	end
	table.sort(tKeys)
	return tKeys
end

--[port] Phase 4: the Freezer's Grief Seed, run from the custom mission MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED
--(iData1 = the girl's key). Spends one Grief Seed and takes FREEZER_GRIEF_SEED_TURNS off her timer; if that
--empties the timer she revives immediately. Does not touch her Soul Gem.
function DoFreezerGriefSeed(iPlayer, iMGKey)
	if not HasFreezer(iPlayer) then return end
	local tGirl = MagicalGirls[iMGKey]
	if not tGirl or tGirl.FreezerPlayer ~= iPlayer then return end
	if not PMMM.GriefSeeds[iPlayer] or PMMM.GriefSeeds[iPlayer] <= 0 then return end

	PMMM.GriefSeeds[iPlayer] = PMMM.GriefSeeds[iPlayer] - 1
	tGirl.FreezerStartTurn = tGirl.FreezerStartTurn or Game.GetGameTurn()
	tGirl.FreezerSeedTurns = (tGirl.FreezerSeedTurns or 0) + FREEZER_GRIEF_SEED_TURNS

	local sName = Locale.ConvertTextKey(tGirl.Name)
	local iLeft = GetFreezerRevivalTurns(iPlayer, iMGKey)
	if iLeft <= 0 then
		DoFreezerRevival(iPlayer, iMGKey)
	elseif iPlayer == Game.GetActivePlayer() then
		Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_FREEZER_GRIEF_SEED", sName, FREEZER_GRIEF_SEED_TURNS, iLeft))
	end
	LuaEvents.PMMMRefreshGriefSeedDisplay()
	LuaEvents.PMMMRefreshFreezerPopup()
end

--[port] Phase 4: the old experiment mission is retired, and the Grief Seed mission is now handled for single
--and multiplayer alike by the hook in PMMMAbilityKaoruUmika.lua. The bootstrapper still calls these two in
--multiplayer, so they stay as no-ops to keep a seed from being spent twice.
function FreezerCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	return 0
end

function FreezerGriefSeedCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	return 0
end


function PleiadesOnCombatEnded(iAttackingPlayer, iAttackingUnit, attackerDamage, attackerFinalDamage, attackerMaxHP, iDefendingPlayer, iDefendingUnit, defenderDamage, defenderFinalDamage, defenderMaxHP, iInterceptingPlayer, iInterceptingUnit, interceptorDamage, plotX, plotY)
	local pEnemyUnit;
	local pPlayer;
	local pEnemyPlayer;

	--Determines which player's unit died, if any, and bases the rest of the code off of that. In case that two Pleiades players are attacking each other.
	--[port] Phase 4: this test read `~= false`, which let every player through; it now matches the defender test.
	if HasFreezer(iAttackingPlayer) then
		pEnemyPlayer = Players[iDefendingPlayer]
		if pEnemyPlayer then
			pEnemyUnit = pEnemyPlayer:GetUnitByID(iDefendingUnit)
			if pEnemyUnit and pEnemyUnit:GetCurrHitPoints() == 0 then
				pPlayer = Players[iAttackingPlayer]
			else
				pEnemyUnit = nil
				pEnemyPlayer = nil
			end
		end
	end
	if not pEnemyUnit then
		if HasFreezer(iDefendingPlayer) then
			pEnemyPlayer = Players[iAttackingPlayer]
			if pEnemyPlayer then
				pEnemyUnit = pEnemyPlayer:GetUnitByID(iAttackingUnit)
				if pEnemyUnit and pEnemyUnit:GetCurrHitPoints() == 0 then
					pPlayer = Players[iDefendingPlayer]
				else
					pEnemyUnit = nil
					pEnemyPlayer = nil
				end
			end
		end
	end
	if pEnemyUnit then
		--If we've gotten this far, we can ascertain that there's a dead unit detected and the killer was a Pleiades player.
		local iPlayer = pPlayer:GetID()
		if pEnemyUnit:GetUnitType() == iMagicalGirlType then
			local iMaxFreezer = GetFreezerStorageMax(iPlayer)
			local iCurFreezer = GetFreezerCurrentStorage(iPlayer)
			if iCurFreezer < iMaxFreezer then
				local iMGKey = GetMagicalGirlKey(pEnemyPlayer:GetID(), pEnemyUnit:GetID())
				--The Freezer never takes a Leader Magical Girl (maintainer ruling).
				if iMGKey and not MagicalGirls[iMGKey].IsLeader then
					MagicalGirls[iMGKey].Promotions = {}
					for row in GameInfo.UnitPromotions() do
						if pEnemyUnit:IsHasPromotion(row.ID) then
							MagicalGirls[iMGKey].Promotions[#MagicalGirls[iMGKey].Promotions + 1] = row.ID
						end
					end
					MagicalGirls[iMGKey].XP = pEnemyUnit:GetExperience()
					MagicalGirls[iMGKey].Level = pEnemyUnit:GetLevel()
					MagicalGirls[iMGKey].Status = iFreezerState
					MagicalGirls[iMGKey].FreezerPlayer = iPlayer
					--[port] Phase 4: start her revival timer.
					MagicalGirls[iMGKey].FreezerStartTurn = Game.GetGameTurn()
					MagicalGirls[iMGKey].FreezerSeedTurns = 0
					local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_CAPTURED_MG_TO_FREEZER_TEXT", Locale.ConvertTextKey(MagicalGirls[iMGKey].Name), GetFreezerRevivalDuration(iPlayer))
					local sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_CAPTURED_MG_TO_FREEZER_TITLE")
					pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, plotX, plotY)
				end
			end
		end
	end
end


--[port] Phase 4: once per turn, revive every stored girl whose timer has run out. Humans and AI share this path;
--the AI does not spend Grief Seeds on the Freezer. The Soul Gem decay that used to run here is retired.
function OnPleiadesDoTurn(iPlayer)
	if not HasFreezer(iPlayer) then return end
	local bChanged = false
	for _, k in ipairs(GetStoredGirlKeys(iPlayer)) do
		local tGirl = MagicalGirls[k]
		if not tGirl.FreezerStartTurn then
			--Stored before this version: her timer starts now.
			tGirl.FreezerStartTurn = Game.GetGameTurn()
			tGirl.FreezerSeedTurns = 0
		end
		if GetFreezerRevivalTurns(iPlayer, k) <= 0 then
			if DoFreezerRevival(iPlayer, k) then
				bChanged = true
			end
		end
	end
	if bChanged then
		LuaEvents.PMMMRefreshFreezerPopup()
	end
end


--[port] Phase 4: Pleiades Capital conquered. Every stored girl is released to the conqueror if they take part
--in the Magical Girl system; otherwise her Soul Gem shatters. Was a 25/25/50 roll between revive, death and a
--Witch beside the city.
function OnPleiadesCityCapture(iCapturedPlayer, bCapital, iX, iY, iCapturingPlayer, bConquest)
	if iCapturingPlayer < iMaxCivs and iCapturedPlayer < iMaxCivs then
		if HasFreezer(iCapturedPlayer) and bCapital and bConquest then
			local pPlot = Map.GetPlot(iX, iY)
			local bConquerorHasGirls = PlayerHasMagicalGirls(iCapturingPlayer)
			for _, k in ipairs(GetStoredGirlKeys(iCapturedPlayer)) do
				local v = MagicalGirls[k]
				local sName = Locale.ConvertTextKey(v.Name)
				local pUnit
				if bConquerorHasGirls then
					pUnit = ReleaseFromFreezer(iCapturingPlayer, k, pPlot)
				end
				if pUnit then
					if iCapturingPlayer == Game.GetActivePlayer() then
						Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_FREEZER_CAPTURE_GOOD", sName))
					end
				else
					v.Status = GameInfoTypes.MGACTIONSTATE_DEAD
					v.FreezerPlayer = nil
					v.FreezerStartTurn = nil
					v.FreezerSeedTurns = nil
					if iCapturingPlayer == Game.GetActivePlayer() then
						Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_FREEZER_CAPTURE_LOST", sName))
					end
				end
			end
			LuaEvents.PMMMRefreshFreezerPopup()
		end
	end
end
