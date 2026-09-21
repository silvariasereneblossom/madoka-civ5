-- PMMMLeaderAbilities
-- [port] Phase 4: shared framework for Leader Magical Girl unique abilities.
-- Design: docs/design/phase4-design-v1.md section 0.2
--------------------------------------------------------------
-- Every Magical Girl civilization gives its Leader Magical Girl one active ability. Each ability is a
-- custom mission, so it travels through the game core and is safe in network games, exactly like
-- Tiro Finale and Summon Witch. This file owns the parts every ability shares:
--
--   * registration:      RegisterLeaderAbility("MISSION_...", { ... })
--   * eligibility:       the CustomMissionPossible hook (leader girl, off cooldown, valid target)
--   * execution:         the CustomMissionStart hook (decode the plot, run the handler, pay the costs)
--   * cooldowns:         per girl in the persisted table, ticked once per player turn
--   * damage:            PMMMVirtualAttack / PMMMVirtualAttackCity
--   * timed effects:     PMMMApplyTimedPromotion, cleared automatically when it expires
--   * AI:                every ability supplies a target chooser; AI players fire it when it is ready
--
-- Damage note: CP 5.4.6 binds Unit:GetCombatDamage but its body is commented out and it always
-- returns 0 (CvLuaUnit.cpp:1176-1190). Use GetMeleeCombatDamage / GetMeleeCombatDamageCity, which
-- are real. Abilities are expressed as a multiplier on the girl's own attack strength so they scale
-- with the era for the whole game.
--------------------------------------------------------------

include("PMMMDefines.lua")

local iMaxCivs = GameDefines.MAX_MAJOR_CIVS
local iMagicalGirlClass = GameInfoTypes.UNITCLASS_PMMM_MAGICAL_GIRL

--Registry: [mission ID] = definition. Definitions are added by the per-civ scripts.
tPMMMLeaderAbilities = tPMMMLeaderAbilities or {}

--Hooks other scripts can join. Each entry is a function; see the call sites for arguments.
--  tPMMMGriefSeedUsedHooks: (iPlayer, iMGKey), called from DoConsumeGriefSeed in PMMMGeneralFunctions.lua
tPMMMGriefSeedUsedHooks = tPMMMGriefSeedUsedHooks or {}

-- Definition fields:
--   Cooldown       (int)      turns before it may be used again, scaled by game speed
--   SoulGemCost    (int)      percent of Soul Gem spent on use (optional)
--   EndsTurn       (bool)     set the girl's movement to 0 after use (default true)
--   NeedsTarget    (bool)     true if the ability is aimed at a plot (default true)
--   CanUseHere     (function) (pPlayer, pUnit, pPlot, iMGKey) -> bool, extra validity test (optional)
--   Execute        (function) (iPlayer, pUnit, pPlot, iMGKey) -> does the work
--   AIScorePlot    (function) (pPlayer, pUnit, pPlot) -> number or nil; AI fires at the best-scoring plot
--   TraitType      (string)   optional: also grant this ability to leader girls of the civ with this trait
function RegisterLeaderAbility(sMission, tDef)
	local pMission = GameInfo.Missions[sMission]
	if not pMission then
		print("PMMMLeaderAbilities: no such mission " .. tostring(sMission) .. ", ability not registered")
		return
	end
	tDef.MissionType = sMission
	tDef.MissionID = pMission.ID
	tDef.Range = pMission.PMMMMissionRange or 1
	if tDef.EndsTurn == nil then tDef.EndsTurn = true end
	if tDef.NeedsTarget == nil then tDef.NeedsTarget = true end
	tPMMMLeaderAbilities[pMission.ID] = tDef
	print("PMMMLeaderAbilities: registered " .. sMission)
end

--------------------------------------------------------------
-- Cooldowns
--------------------------------------------------------------

--Cooldowns are stored per girl and per ability, so a civilization with two leader girls tracks them
--separately and a girl with two abilities (Homura) can use one while the other recovers.
--Stored as MagicalGirls[key].AbilityCooldowns[missionID] = turns remaining.
function GetLeaderAbilityCooldown(iMGKey, iMission)
	if not iMGKey or not MagicalGirls[iMGKey] then return 0 end
	local t = MagicalGirls[iMGKey].AbilityCooldowns
	if not t or not iMission then return 0 end
	return t[iMission] or 0
end

function SetLeaderAbilityCooldown(iMGKey, iTurns, iMission)
	if not iMGKey or not MagicalGirls[iMGKey] or not iMission then return end
	MagicalGirls[iMGKey].AbilityCooldowns = MagicalGirls[iMGKey].AbilityCooldowns or {}
	if iTurns > 0 then
		MagicalGirls[iMGKey].AbilityCooldowns[iMission] = iTurns
	else
		MagicalGirls[iMGKey].AbilityCooldowns[iMission] = nil
	end
end

--Game speed scaling, the same rule the rest of the mod uses for turn counts. Zero stays zero, so an
--ability that manages its own recovery (Homura's) can register Cooldown = 0.
function GetScaledAbilityCooldown(iTurns)
	if not iTurns or iTurns <= 0 then return 0 end
	local pSpeed = GameInfo.GameSpeeds[PreGame.GetGameSpeed()]
	if not pSpeed then return iTurns end
	return math.max(math.ceil(iTurns * pSpeed.DealDuration / 30), 1)
end

function IsLeaderAbilityReady(iMGKey, iMission)
	return GetLeaderAbilityCooldown(iMGKey, iMission) <= 0
end

--------------------------------------------------------------
-- Damage helpers
--------------------------------------------------------------

--[port] Phase 6 Lekmod: the melee damage pair. CP binds Unit:GetMeleeCombatDamage / GetMeleeCombatDamageCity
--(CvLuaUnit.cpp:64-65); Lekmod has neither the bindings nor the backing (its combat rework does not exist
--there). Under CP the native methods stay the primary path and behaviour is exactly what it was (note the
--existing trap: CP's Unit:GetCombatDamage is a stub returning 0 -- CvLuaUnit.cpp:1175-1190 -- which is why
--these two are used at all). Under a DLL without the binding, the fallback reimplements the vanilla Civ V
--melee formula in Lua, ported line-for-line from the engine source as shipped in Lekmod (identical to the
--vanilla game's math):
--  CvGame::getCombatDamage (Lekmod CvGame.cpp, "Defender is Unit"/"Defender is City" branches)
--  CvCombatInfo::doStrengthRatio: RATIO = ((((ME / OPP) + 3) / 4) ^ 4) + 1) / 2, inverted when the defender
--    is stronger, capped at 10 before the transform
--  CvCombatInfo::doRandomness + CvUnit::getWoundedRatio: a unit at D damage deals
--    (100 - D * WOUNDED_DAMAGE_MULTIPLIER / 100) percent of base damage (air units: 100 - D); cities are
--    always at full strength
--All constants come from the game's own Defines XML (GlobalDefines), verified in the vanilla BNW database
--(Defines table) and re-asserted by Lekmod's Override/CIV5Units.xml: ATTACK_SAME_STRENGTH_MIN_DAMAGE = 2400
--and ATTACK_SAME_STRENGTH_POSSIBLE_EXTRA_DAMAGE = 1200 (hundredths: 24 base damage + a 0..11 roll at equal
--strength, full health), ATTACKING_CITY_MELEE_DAMAGE_MOD = 100, WOUNDED_DAMAGE_MULTIPLIER = 33,
--MAX_HIT_POINTS = 100. The roll uses Game.Rand (the synchronised RNG, the same stream the engine's
--getJonRandNum draws from), never math.random, so every client rolls the same number in the same handler.
--Skipped, deliberately: CP-only combat systems with no Lekmod equivalent (forced/change damage values, the
--wounded-damage policy modifier, garrison damage absorption) -- on Lekmod those are zero everywhere anyway.
local iPMMMDamageMaxHP = GameDefines.MAX_HIT_POINTS or 100
local iPMMMDamageBase100 = GameDefines.ATTACK_SAME_STRENGTH_MIN_DAMAGE or 2400
local iPMMMDamageRand100 = GameDefines.ATTACK_SAME_STRENGTH_POSSIBLE_EXTRA_DAMAGE or 1200
local iPMMMDamageWoundedMult = GameDefines.WOUNDED_DAMAGE_MULTIPLIER or 33
local iPMMMDamageCityMeleeMod = GameDefines.ATTACKING_CITY_MELEE_DAMAGE_MOD or 100

local bPMMMCPMeleeDamage = nil      -- cached presence probes (nil = not probed yet; see PMMMGeneralFunctions.lua)
local bPMMMCPMeleeDamageCity = nil

local function PMMMDamageWoundedRatio(pUnit)
	if not pUnit then return iPMMMDamageMaxHP end
	local iDamage = pUnit:GetDamage() or 0
	local iRatio
	if pUnit:GetDomainType() == DomainTypes.DOMAIN_AIR then
		iRatio = iPMMMDamageMaxHP - iDamage
	else
		iRatio = iPMMMDamageMaxHP - math.floor(iDamage * iPMMMDamageWoundedMult / 100)
	end
	if iRatio < 1 then iRatio = 1 end
	return iRatio
end

local function PMMMDamageStrengthRatio(iStrength, iOpponentStrength)
	local bInvert = iOpponentStrength > iStrength
	local fRatio
	if iOpponentStrength > 0 then
		fRatio = iStrength / iOpponentStrength
	else
		fRatio = iStrength
	end
	if bInvert then
		if iStrength > 0 then
			fRatio = iOpponentStrength / iStrength
		else
			fRatio = iOpponentStrength
		end
	end
	if fRatio > 10 then fRatio = 10 end
	fRatio = (fRatio + 3) / 4
	fRatio = fRatio ^ 4
	fRatio = (fRatio + 1) / 2
	if bInvert then fRatio = 1 / fRatio end
	return fRatio
end

--Damage pAttacker deals to pDefender. CP: the bound method, exactly as before (bIncludeRand = true, matching
--every existing call site). Lekmod: the vanilla formula above, in hundredths until the final divisions.
function PMMMGetMeleeCombatDamage(pAttacker, iStrength, iDefense, pDefender)
	if bPMMMCPMeleeDamage == nil then
		bPMMMCPMeleeDamage = (pAttacker.GetMeleeCombatDamage ~= nil)
	end
	if bPMMMCPMeleeDamage then
		return pAttacker:GetMeleeCombatDamage(iStrength, iDefense, true, pDefender)
	end
	local iWoundedRatio = PMMMDamageWoundedRatio(pAttacker)
	local iDamage100 = math.floor(iPMMMDamageBase100 * iWoundedRatio / iPMMMDamageMaxHP)
	local iRoll = Game.Rand(iPMMMDamageRand100, "PMMM melee damage roll")
	iRoll = math.floor(iRoll * iWoundedRatio / iPMMMDamageMaxHP)
	iDamage100 = iDamage100 + iRoll
	local iDamage = math.floor(iDamage100 * PMMMDamageStrengthRatio(iStrength, iDefense))
	iDamage = math.floor(iDamage / 100)
	--Vanilla melee always deals at least 1 damage (Lekmod CvGame.cpp: "Damage is at least 1").
	if iDamage <= 0 then iDamage = 1 end
	return iDamage
end

--Damage pAttacker deals to pCity. Same split; the city's defense is its own bound GetStrengthValue (city and
--unit strengths are both in hundredths), and the engine's ATTACKING_CITY_MELEE_DAMAGE_MOD (100 = no change)
--is applied in the fallback for fidelity with real Lekmod melee-vs-city combat.
function PMMMGetMeleeCombatDamageCity(pAttacker, iStrength, pCity)
	if bPMMMCPMeleeDamageCity == nil then
		bPMMMCPMeleeDamageCity = (pAttacker.GetMeleeCombatDamageCity ~= nil)
	end
	if bPMMMCPMeleeDamageCity then
		return pAttacker:GetMeleeCombatDamageCity(iStrength, pCity, true)
	end
	local iWoundedRatio = PMMMDamageWoundedRatio(pAttacker)
	local iDamage100 = math.floor(iPMMMDamageBase100 * iWoundedRatio / iPMMMDamageMaxHP)
	local iRoll = Game.Rand(iPMMMDamageRand100, "PMMM city damage roll")
	iRoll = math.floor(iRoll * iWoundedRatio / iPMMMDamageMaxHP)
	iDamage100 = iDamage100 + iRoll
	local iDamage = math.floor(iDamage100 * PMMMDamageStrengthRatio(iStrength, pCity:GetStrengthValue() or 0))
	iDamage = math.floor(iDamage * iPMMMDamageCityMeleeMod / 100)
	iDamage = math.floor(iDamage / 100)
	if iDamage <= 0 then iDamage = 1 end
	return iDamage
end

--A virtual attack: the girl hits pDefender as if her strength were fMultiplier times her real
--attack strength, without moving, without counterattack, and without spending her attack.
function PMMMVirtualAttack(pAttacker, pDefender, fMultiplier)
	if not pAttacker or not pDefender then return 0 end
	local pFromPlot = pAttacker:GetPlot()
	local pToPlot = pDefender:GetPlot()
	if not pFromPlot or not pToPlot then return 0 end

	local iStrength = math.floor(pAttacker:GetMaxAttackStrength(pFromPlot, pToPlot, pDefender) * fMultiplier)
	local iDefense
	if pDefender:IsEmbarked() then
		iDefense = pDefender:GetEmbarkedUnitDefense()
	else
		iDefense = pDefender:GetMaxDefenseStrength(pToPlot, pAttacker)
	end

	--GetCombatDamage is a stub in CP 5.4.6; GetMeleeCombatDamage is the real one.
	local iDamage = PMMMGetMeleeCombatDamage(pAttacker, iStrength, iDefense, pDefender)
	if not iDamage or iDamage < 0 then iDamage = 0 end
	if iDamage > 100 then iDamage = 100 end
	if iDamage > 0 then
		pDefender:ChangeDamage(iDamage, pAttacker:GetOwner())
	end
	return iDamage
end

--The same against a city.
function PMMMVirtualAttackCity(pAttacker, pCity, fMultiplier)
	if not pAttacker or not pCity then return 0 end
	local pFromPlot = pAttacker:GetPlot()
	local pToPlot = pCity:Plot()
	if not pFromPlot or not pToPlot then return 0 end

	local iStrength = math.floor(pAttacker:GetMaxAttackStrength(pFromPlot, pToPlot, nil) * fMultiplier)
	local iDamage = PMMMGetMeleeCombatDamageCity(pAttacker, iStrength, pCity)
	if not iDamage or iDamage < 0 then iDamage = 0 end
	local iRoom = pCity:GetMaxHitPoints() - pCity:GetDamage() - 1
	if iDamage > iRoom then iDamage = math.max(iRoom, 0) end
	if iDamage > 0 then
		pCity:ChangeDamage(iDamage)
	end
	return iDamage
end

--Hit every enemy unit on a plot; returns how many were hit.
function PMMMVirtualAttackPlot(pAttacker, pPlot, fMultiplier, bFirstOnly)
	if not pAttacker or not pPlot then return 0 end
	local pPlayer = Players[pAttacker:GetOwner()]
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	local iHit = 0
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			PMMMVirtualAttack(pAttacker, pTarget, fMultiplier)
			iHit = iHit + 1
			if bFirstOnly then break end
		end
	end
	if pPlot:IsCity() then
		local pCity = pPlot:GetPlotCity()
		if pCity and pTeam:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then
			PMMMVirtualAttackCity(pAttacker, pCity, fMultiplier)
			iHit = iHit + 1
		end
	end
	return iHit
end

--------------------------------------------------------------
-- Timed promotions
--------------------------------------------------------------

--Apply a promotion that removes itself after iTurns of the owner's turns. Used for the short buffs
--and debuffs the abilities hand out. The list is persisted, so it survives a save.
function PMMMApplyTimedPromotion(pUnit, iPromotion, iTurns)
	if not pUnit or not iPromotion then return end
	local iPlayer = pUnit:GetOwner()
	PMMM.TimedPromotions[iPlayer] = PMMM.TimedPromotions[iPlayer] or {}
	pUnit:SetHasPromotion(iPromotion, true)
	local iExpire = Game:GetGameTurn() + math.max(iTurns, 1)
	local iUnitID = pUnit:GetID()
	--[port] re-applying the same promotion must push the expiry out, not add a second entry: the earlier
	--entry would otherwise strip the promotion while the later one still considers it live.
	for _, v in ipairs(PMMM.TimedPromotions[iPlayer]) do
		if v.UnitID == iUnitID and v.Promotion == iPromotion then
			if iExpire > v.Expire then v.Expire = iExpire end
			return
		end
	end
	table.insert(PMMM.TimedPromotions[iPlayer], {
		UnitID = iUnitID,
		Promotion = iPromotion,
		Expire = iExpire,
	})
end

function PMMMTickTimedPromotions(iPlayer)
	local tList = PMMM.TimedPromotions[iPlayer]
	if not tList then return end
	local pPlayer = Players[iPlayer]
	local iTurn = Game:GetGameTurn()
	local tKeep = {}
	for _, v in ipairs(tList) do
		if iTurn >= v.Expire then
			local pUnit = pPlayer:GetUnitByID(v.UnitID)
			if pUnit then
				pUnit:SetHasPromotion(v.Promotion, false)
			end
		else
			tKeep[#tKeep + 1] = v
		end
	end
	if #tKeep > 0 then
		PMMM.TimedPromotions[iPlayer] = tKeep
	else
		PMMM.TimedPromotions[iPlayer] = nil
	end
end

--------------------------------------------------------------
-- Eligibility and execution
--------------------------------------------------------------

--Which ability may this unit use? Returns the definition and the girl's key.
function GetLeaderAbilityForUnit(iPlayer, pUnit, iMission)
	local tDef = tPMMMLeaderAbilities[iMission]
	if not tDef then return nil end
	if not pUnit or pUnit:GetUnitClassType() ~= iMagicalGirlClass then return nil end
	local iMGKey = GetMagicalGirlKey(iPlayer, pUnit:GetID())
	if not iMGKey then return nil end
	local tGirl = MagicalGirls[iMGKey]
	if not tGirl or not tGirl.IsLeader then return nil end
	--The trait names the mission this civilization's leader girl owns.
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	if not tTrait then return nil end
	local sOwn = tTrait.LeaderMGUniqueMission
	local sExtra = tTrait.ExtraLeaderMGUniqueMission
	--A civ may own more than one ability: the trait column names one, and a definition may also name
	--its trait directly with TraitType (Homura has both Concentrated Missile Fire and Time Stop).
	local bByTrait = tDef.TraitType ~= nil and tDef.TraitType == tTrait.Type
	if tDef.MissionType ~= sOwn and tDef.MissionType ~= sExtra and not bByTrait then return nil end
	--A civ with two leader girls (Oriko and Kirika) names one mission for each. Each leader girl records
	--the mission she was born with in MagicalGirls[key].ExtraMission, so she may use that one only; abilities
	--bound by TraitType (Homura's Time Stop) are open to every leader girl of the civ.
	if not bByTrait and tGirl.ExtraMission and tGirl.ExtraMission ~= tDef.MissionID then return nil end
	return tDef, iMGKey
end

function LeaderAbilityCustomMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	if iPlayer >= iMaxCivs then return false end
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
	local tDef, iMGKey = GetLeaderAbilityForUnit(iPlayer, pUnit, iMission)
	if not tDef then return false end
	if not IsLeaderAbilityReady(iMGKey, iMission) then return false end
	if tDef.SoulGemCost and MagicalGirls[iMGKey].SoulGem and MagicalGirls[iMGKey].SoulGem <= tDef.SoulGemCost then
		return false
	end
	if pUnit:GetMoves() <= 0 then return false end
	if bTestVisible then return true end
	if tDef.CanUseHere then
		local pPlot
		if iPlotX and iPlotY and iPlotX >= 0 and iPlotY >= 0 then
			pPlot = Map.GetPlot(iPlotX, iPlotY)
		end
		return tDef.CanUseHere(pPlayer, pUnit, pPlot, iMGKey) and true or false
	end
	return true
end

function LeaderAbilityCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	local tDef = tPMMMLeaderAbilities[iMission]
	if not tDef then return 0 end
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
	local tDef2, iMGKey = GetLeaderAbilityForUnit(iPlayer, pUnit, iMission)
	if not tDef2 or not IsLeaderAbilityReady(iMGKey, iMission) then return 0 end

	local pPlot
	if tDef.NeedsTarget then
		--The mod's input handler passes the target plot as negated coordinates, as Tiro Finale does.
		local iX, iY = -iData1, -iData2
		if iX < 0 or iY < 0 then return 0 end
		pPlot = Map.GetPlot(iX, iY)
		if not pPlot then return 0 end
	else
		pPlot = pUnit:GetPlot()
	end

	if tDef.CanUseHere and not tDef.CanUseHere(pPlayer, pUnit, pPlot, iMGKey) then return 0 end

	tDef.Execute(iPlayer, pUnit, pPlot, iMGKey)

	SetLeaderAbilityCooldown(iMGKey, GetScaledAbilityCooldown(tDef.Cooldown or 1), iMission)
	if tDef.SoulGemCost and tDef.SoulGemCost > 0 then
		DoChangeCorruption(tDef.SoulGemCost, iMGKey)
	end
	if tDef.EndsTurn then
		pUnit:SetMoves(0)
	end
	return 0
end

function LeaderAbilityCustomMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if tPMMMLeaderAbilities[iMission] then return true end
	return false
end

--------------------------------------------------------------
-- Per-turn upkeep and AI
--------------------------------------------------------------

--Tick cooldowns, expire timed promotions, and let the AI use its abilities.
function PMMMLeaderAbilityDoTurn(iPlayer)
	if iPlayer >= iMaxCivs then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end

	for k, v in pairs(MagicalGirls) do
		if v.Owner == iPlayer and v.AbilityCooldowns then
			for iMission, iTurns in pairs(v.AbilityCooldowns) do
				if iTurns <= 1 then
					v.AbilityCooldowns[iMission] = nil
				else
					v.AbilityCooldowns[iMission] = iTurns - 1
				end
			end
		end
	end

	PMMMTickTimedPromotions(iPlayer)

	if not pPlayer:IsHuman() then
		RunLeaderAbilityAI(iPlayer)
	end
end

--One rule for every ability: if it is ready and the ability's own scorer likes a plot in range, fire.
function RunLeaderAbilityAI(iPlayer)
	local pPlayer = Players[iPlayer]
	for pUnit in pPlayer:Units() do
		if pUnit:GetUnitClassType() == iMagicalGirlClass and pUnit:GetMoves() > 0 then
			for iMission, tDef in pairs(tPMMMLeaderAbilities) do
				local tCheck, iMGKey = GetLeaderAbilityForUnit(iPlayer, pUnit, iMission)
				if tCheck and IsLeaderAbilityReady(iMGKey, iMission) and tDef.AIScorePlot then
					local pBestPlot, iBestScore
					--[port] a self-centred ability is always aimed at her own tile, as on the human path.
					if not tDef.NeedsTarget then
						local pOwnPlot = pUnit:GetPlot()
						if tDef.AIScorePlot(pPlayer, pUnit, pOwnPlot) then pBestPlot = pOwnPlot end
					else
						for pAreaPlot in PlotAreaSpiralIterator(pUnit:GetPlot(), tDef.Range, 1, false, false, true) do
							if pAreaPlot then
								local iScore = tDef.AIScorePlot(pPlayer, pUnit, pAreaPlot)
								if iScore and (not iBestScore or iScore > iBestScore) then
									iBestScore = iScore
									pBestPlot = pAreaPlot
								end
							end
						end
					end
					if pBestPlot then
						tDef.Execute(iPlayer, pUnit, pBestPlot, iMGKey)
						SetLeaderAbilityCooldown(iMGKey, GetScaledAbilityCooldown(tDef.Cooldown or 1), iMission)
						if tDef.SoulGemCost and tDef.SoulGemCost > 0 then
							DoChangeCorruption(tDef.SoulGemCost, iMGKey)
						end
						if tDef.EndsTurn then
							pUnit:SetMoves(0)
						end
						break
					end
				end
			end
		end
	end
end

--------------------------------------------------------------
-- Shared AI scorers the individual abilities can reuse
--------------------------------------------------------------

--Score a plot by the enemy units standing on it: prefer more units, then lower health.
function PMMMScoreEnemyPlot(pPlayer, pUnit, pPlot)
	if not pPlot or not pPlot:IsUnit() then return nil end
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	local iScore, iCount = 0, 0
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			iCount = iCount + 1
			iScore = iScore + 100 + pTarget:GetDamage()
		end
	end
	if iCount == 0 then return nil end
	return iScore
end
