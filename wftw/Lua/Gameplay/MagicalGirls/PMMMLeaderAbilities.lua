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

--Cooldowns are stored per girl so a civilization with two leader girls tracks them separately.
function GetLeaderAbilityCooldown(iMGKey)
	if not iMGKey or not MagicalGirls[iMGKey] then return 0 end
	return MagicalGirls[iMGKey].AbilityCooldown or 0
end

function SetLeaderAbilityCooldown(iMGKey, iTurns)
	if not iMGKey or not MagicalGirls[iMGKey] then return end
	MagicalGirls[iMGKey].AbilityCooldown = math.max(iTurns, 0)
end

--Game speed scaling, the same rule the rest of the mod uses for turn counts.
function GetScaledAbilityCooldown(iTurns)
	local pSpeed = GameInfo.GameSpeeds[PreGame.GetGameSpeed()]
	if not pSpeed then return iTurns end
	return math.max(math.ceil(iTurns * pSpeed.DealDuration / 30), 1)
end

function IsLeaderAbilityReady(iMGKey)
	return GetLeaderAbilityCooldown(iMGKey) <= 0
end

--------------------------------------------------------------
-- Damage helpers
--------------------------------------------------------------

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
	local iDamage = pAttacker:GetMeleeCombatDamage(iStrength, iDefense, true, pDefender)
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
	local iDamage = pAttacker:GetMeleeCombatDamageCity(iStrength, pCity, true)
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
	return tDef, iMGKey
end

function LeaderAbilityCustomMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	if iPlayer >= iMaxCivs then return false end
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
	local tDef, iMGKey = GetLeaderAbilityForUnit(iPlayer, pUnit, iMission)
	if not tDef then return false end
	if not IsLeaderAbilityReady(iMGKey) then return false end
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
	if not tDef2 or not IsLeaderAbilityReady(iMGKey) then return 0 end

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

	SetLeaderAbilityCooldown(iMGKey, GetScaledAbilityCooldown(tDef.Cooldown or 1))
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
		if v.Owner == iPlayer and v.AbilityCooldown and v.AbilityCooldown > 0 then
			v.AbilityCooldown = v.AbilityCooldown - 1
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
				if tCheck and IsLeaderAbilityReady(iMGKey) and tDef.AIScorePlot then
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
						SetLeaderAbilityCooldown(iMGKey, GetScaledAbilityCooldown(tDef.Cooldown or 1))
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
