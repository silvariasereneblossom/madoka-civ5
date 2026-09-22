----------------------------------------------------------------------------------------------------------------------------

-- PMMMGeneralFunctions
-- Author: Vicevirtuoso
-- DateCreated: 6/16/2014 4:11:32 PM
----------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------
--This is known as "GeneralFunctions" since these should ONLY be called from other functions. None of these should ever
--be directly added to a GameEvent hook! (LuaEvents are okay though)
----------------------------------------------------------------------------------------------------------------------------

iMaxCivs = GameDefines.MAX_MAJOR_CIVS

include("VV_PlotIt.lua")

----------------------------------------------------------------------------------------------------------------------------
--[port] Phase 6 Lekmod: CP/Lekmod dual-compatibility layer for engine methods CP binds and Lekmod does not.
--Spec: docs/design/lekmod-scope-engine.md section 4 (Lua-workaround rows only; the binding-only rows are ported
--into Lekmod's DLL separately).
--
--How the capability probes work: engine objects handed to Lua are plain tables whose metatable's __index is the
--class's method table (CvLuaScopedInstance::Push/PushTypeTable -- CP keeps the class tables under the global
--"LuaTypes", Lekmod under globals named "Unit", "Player", ...). Indexing a method a DLL does not bind therefore
--returns nil instead of raising, so `pObject.MethodName ~= nil` is a safe presence test. The probes are done on
--first use, not at file scope: an instance is always in hand there (file scope is NOT safe -- `Unit.X` would
--error under CP, where the class table is not a global), and all instances of a class share one method table,
--so one cached result is valid for every receiver. Under CP every helper below calls the native method and
--behaviour is bit-for-bit what it was; the fallback body only runs under a DLL without the binding.
--
--Sync rule (lekmod-scope-multiplayer.md B0): all of this is gameplay code called from GameEvents handlers; the
--fallbacks touch no randomness (except the damage formula's roll, which uses the synchronised Game.Rand) and
--iterate in fixed order wherever order matters.
----------------------------------------------------------------------------------------------------------------------------

--NOTIFICATION_GENERIC for the AddNotification fallbacks below: the engine-side enum (what vanilla Lua UI
--uses for AddNotification), which every DLL exposes regardless of database state; 0 is the enum's own
--value (Notifications table row 0), so the literal is the belt to the enum's braces.
local iPMMMNotificationGeneric = (NotificationTypes and NotificationTypes.NOTIFICATION_GENERIC) or 0

--[port] Phase 6 Lekmod: combat-strength bindings with a different signature per DLL (2026-09-22).
--  CP:     GetMaxAttackStrength(fromPlot, toPlot, defender)
--          GetMaxDefenseStrength(inPlot, attacker, bFromRangedAttack)
--          GetMaxRangedCombatStrength(otherUnit, city, bAttacking, bForRangedAttack)
--  Lekmod (LEKMOD_COMBAT_PREDICTOR_IMPROVEMENTS, on in its _Defines.h):
--          GetMaxAttackStrength(toPlot, defender, defenderCity, interceptor, bRanged, bBombing, bAirSweep, fromPlot)
--          GetMaxDefenseStrength(toPlot, attacker, attackerCity, interceptor, bRanged, bBombing, bAirSweep)
--          no GetMaxRangedCombatStrength: ranged strength is the attack/defense call with bRanged set.
--CP's argument order on Lekmod hands the DLL a Plot where it reads a Unit, and the game crashes (the enemy-unit
--panel did this on a turn-start refresh). The probe: GetMeleeCombatDamage is CP-only (not in Lekmod or our port).
local bPMMMCPCombatSignatures = nil
local function PMMMUsesCPCombatSignatures(pUnit)
	if bPMMMCPCombatSignatures == nil then
		bPMMMCPCombatSignatures = (pUnit.GetMeleeCombatDamage ~= nil)
	end
	return bPMMMCPCombatSignatures
end

--Melee attack strength of pAttacker from pFromPlot into pToPlot against pDefender (a unit) or pDefenderCity.
function PMMMGetMaxAttackStrength(pAttacker, pFromPlot, pToPlot, pDefender, pDefenderCity)
	if PMMMUsesCPCombatSignatures(pAttacker) then
		return pAttacker:GetMaxAttackStrength(pFromPlot, pToPlot, pDefender)
	end
	return pAttacker:GetMaxAttackStrength(pToPlot, pDefender, pDefenderCity, nil, false, false, false, pFromPlot)
end

--Defense strength of pDefender standing on pInPlot against pAttacker.
function PMMMGetMaxDefenseStrength(pDefender, pInPlot, pAttacker, bFromRangedAttack)
	if PMMMUsesCPCombatSignatures(pDefender) then
		return pDefender:GetMaxDefenseStrength(pInPlot, pAttacker, bFromRangedAttack or false)
	end
	return pDefender:GetMaxDefenseStrength(pInPlot, pAttacker, nil, nil, bFromRangedAttack or false, false, false)
end

--CP's GetMaxRangedCombatStrength(pOther, pCity, bAttacking, bForRangedAttack). On Lekmod: attacking = ranged
--attack strength into the target's plot; defending = ranged-defense strength on the unit's own plot.
function PMMMGetMaxRangedCombatStrength(pUnit, pOther, pCity, bAttacking, bForRangedAttack)
	if PMMMUsesCPCombatSignatures(pUnit) then
		return pUnit:GetMaxRangedCombatStrength(pOther, pCity, bAttacking, bForRangedAttack)
	end
	if bAttacking then
		local pToPlot = (pCity and pCity:Plot()) or (pOther and pOther:GetPlot())
		return pUnit:GetMaxAttackStrength(pToPlot, pOther, pCity, nil, true, false, false, pUnit:GetPlot())
	end
	return pUnit:GetMaxDefenseStrength(pUnit:GetPlot(), pOther, pCity, nil, true, false, false)
end

--Capital-distance combat modifier. CP folds it into GetCombatModifierFromCapitalDistance(plot); Lekmod keeps the
--vanilla CapitalDefenseModifier/CapitalDefenseFalloff pair, combined here as vanilla CvUnit does (base plus
--distance times falloff, counted only while positive).
function PMMMCombatModifierFromCapitalDistance(pUnit, pPlot)
	if pUnit.GetCombatModifierFromCapitalDistance ~= nil then
		return pUnit:GetCombatModifierFromCapitalDistance(pPlot)
	end
	local iModifier = pUnit:CapitalDefenseModifier()
	if iModifier <= 0 or not pPlot then return 0 end
	local pCapital = Players[pUnit:GetOwner()]:GetCapitalCity()
	if not pCapital then return 0 end
	local iDistance = Map.PlotDistance(pCapital:GetX(), pCapital:GetY(), pPlot:GetX(), pPlot:GetY())
	iModifier = iModifier + iDistance * pUnit:CapitalDefenseFalloff()
	return math.max(iModifier, 0)
end

local bPMMMCPPlayerAddMessage = nil        -- cached presence probes (nil = not probed yet)
local bPMMMCPPlayerChangeInfluence = nil
local bPMMMCPPlayerExpansionPromise = nil
local bPMMMCPPlayerHasBuildingClass = nil
local bPMMMCPPlayerHasTech = nil
local bPMMMCPPlayerHasWonder = nil
local bPMMMCPPlayerIsAtWarWith = nil
local bPMMMCPPlayerHasBuilding = nil
local bPMMMCPGameAnyoneHasWonder = nil
local bPMMMCPPlayerGetRandomIntrigue = nil
local bPMMMCPCityAddMessage = nil
local bPMMMCPCityHasBuilding = nil
local bPMMMCPCityGetSpecialistRate = nil
local bPMMMCPCityRefreshTourism = nil
local bPMMMCPUnitAddMessage = nil

--Player:AddMessage(text): CP shows a transient message to that player (CvLuaPlayer.cpp lAddMessage ->
--SHOW_PLAYER_MESSAGE). Lekmod binds Player:AddNotification (CvLuaPlayer.cpp lAddNotification) with the full
--CvNotifications::Add signature (type, message, summary, x, y, gameDataIndex, extraData); NOTIFICATION_GENERIC
--(Notifications table row 0, vanilla) with no plot is the closest per-player equivalent, and unlike
--Events.GameplayAlertMessage it reaches the addressed player in multiplayer, not just the local one.
function PMMMPlayerAddMessage(pPlayer, sText)
	if bPMMMCPPlayerAddMessage == nil then
		bPMMMCPPlayerAddMessage = (pPlayer.AddMessage ~= nil)
	end
	if bPMMMCPPlayerAddMessage then
		pPlayer:AddMessage(sText)
	else
		pPlayer:AddNotification(iPMMMNotificationGeneric, sText, sText, -1, -1, pPlayer:GetID(), -1)
	end
end

--City:AddMessage(text, ePlayer): same replacement, carrying the city's plot so the notification points at it.
function PMMMCityAddMessage(pCity, sText, iPlayer)
	if bPMMMCPCityAddMessage == nil then
		bPMMMCPCityAddMessage = (pCity.AddMessage ~= nil)
	end
	if bPMMMCPCityAddMessage then
		pCity:AddMessage(sText, iPlayer)
	else
		local pPlayer = Players[iPlayer or pCity:GetOwner()]
		if pPlayer then
			pPlayer:AddNotification(iPMMMNotificationGeneric, sText, sText, pCity:GetX(), pCity:GetY(), pPlayer:GetID(), -1)
		end
	end
end

--Unit:AddMessage(text, ePlayer): same replacement, carrying the unit's plot.
function PMMMUnitAddMessage(pUnit, sText, iPlayer)
	if bPMMMCPUnitAddMessage == nil then
		bPMMMCPUnitAddMessage = (pUnit.AddMessage ~= nil)
	end
	if bPMMMCPUnitAddMessage then
		pUnit:AddMessage(sText, iPlayer)
	else
		local pPlayer = Players[iPlayer or pUnit:GetOwner()]
		if pPlayer then
			pPlayer:AddNotification(iPMMMNotificationGeneric, sText, sText, pUnit:GetX(), pUnit:GetY(), pPlayer:GetID(), -1)
		end
	end
end

--Player:ChangeInfluenceOnPlayer(other, amount, false, false): CP's tourism-influence changer
--(CvPlayerCulture::ChangeInfluenceOn). Lekmod binds only Player:ChangeMinorCivFriendshipWithMajor, whose
--receiver is the MINOR (CvLuaPlayer.cpp lChangeMinorCivFriendshipWithMajor -> ChangeFriendshipWithMajor), so
--for a city-state the call inverts to Players[iMinor]:ChangeMinorCivFriendshipWithMajor(iMajor, iAmount); note
--this skips CP's influence modifiers and game-speed scaling (both false in the one call site anyway).
--For a MAJOR civ there is no bound equivalent at all: the vanilla backing exists in Lekmod
--(CvPlayerCulture::ChangeInfluenceOn, CvCultureClasses.cpp) but is unbound, so the call is a documented no-op
--until that binding-only port lands. The single call site (Homura's Time Stop tourism) only passes majors.
function PMMMPlayerChangeInfluenceOnPlayer(pPlayer, iOther, iInfluence)
	if bPMMMCPPlayerChangeInfluence == nil then
		bPMMMCPPlayerChangeInfluence = (pPlayer.ChangeInfluenceOnPlayer ~= nil)
	end
	if bPMMMCPPlayerChangeInfluence then
		pPlayer:ChangeInfluenceOnPlayer(iOther, iInfluence, false, false)
	elseif iOther and iOther >= 0 and Players[iOther] and Players[iOther]:IsMinorCiv() and iInfluence and iInfluence > 0 then
		Players[iOther]:ChangeMinorCivFriendshipWithMajor(pPlayer:GetID(), iInfluence)
	end
end

--Player:GetNumTurnsExpansionPromise(other): CP promise-rework counter, no Lekmod equivalent. Drop the term
--under Lekmod (the adjacent IsPlayerBrokenExpansionPromise / IsPlayerIgnoredExpansionPromise checks ARE
--bound there, so the mood demand still fires off those).
function PMMMPlayerGetNumTurnsExpansionPromise(pPlayer, iOther)
	if bPMMMCPPlayerExpansionPromise == nil then
		bPMMMCPPlayerExpansionPromise = (pPlayer.GetNumTurnsExpansionPromise ~= nil)
	end
	if bPMMMCPPlayerExpansionPromise then
		return pPlayer:GetNumTurnsExpansionPromise(iOther)
	end
	return 0
end

--Player:HasBuildingClass(class): CP semantics are "any city has the civilization's building of that class"
--(CvPlayer::HasBuildingClass -> CvCity::HasBuildingClass). Fallback: any city has ANY building of the class
--(one building per class per city, so this is the same set), via GetNumBuilding > 0, which is exactly the
--count CP's city-level check reads. The class->buildings map is built once, lazily; the iteration order does
--not matter (presence test only).
local tPMMMBuildingsByClass = nil
function PMMMPlayerHasBuildingClass(pPlayer, iClass)
	if bPMMMCPPlayerHasBuildingClass == nil then
		bPMMMCPPlayerHasBuildingClass = (pPlayer.HasBuildingClass ~= nil)
	end
	if bPMMMCPPlayerHasBuildingClass then
		return pPlayer:HasBuildingClass(iClass)
	end
	if not iClass or iClass < 0 then return false end
	if tPMMMBuildingsByClass == nil then
		tPMMMBuildingsByClass = {}
		for row in GameInfo.Buildings() do
			local iClassID = GameInfoTypes[row.BuildingClass]
			if iClassID then
				local tList = tPMMMBuildingsByClass[iClassID]
				if not tList then
					tList = {}
					tPMMMBuildingsByClass[iClassID] = tList
				end
				tList[#tList + 1] = row.ID
			end
		end
	end
	local tList = tPMMMBuildingsByClass[iClass]
	if tList then
		for pCity in pPlayer:Cities() do
			for i = 1, #tList do
				if pCity:GetNumBuilding(tList[i]) > 0 then
					return true
				end
			end
		end
	end
	return false
end

--Player:HasTech(tech): CP is a one-liner over the team's techs; Lekmod binds the same pieces
--(Team:GetTeamTechs, TeamTech:HasTech), and the mod already uses this form elsewhere.
function PMMMPlayerHasTech(pPlayer, iTech)
	if bPMMMCPPlayerHasTech == nil then
		bPMMMCPPlayerHasTech = (pPlayer.HasTech ~= nil)
	end
	if bPMMMCPPlayerHasTech then
		return pPlayer:HasTech(iTech)
	end
	return Teams[pPlayer:GetTeam()]:GetTeamTechs():HasTech(iTech)
end

--Player:HasWonder(building): CP semantics are "any city HasWonder == HasBuilding == GetNumBuilding > 0"
--(CvPlayer::HasWonder, CvCity::HasBuilding). Wonders are one-per-city, so the count comparison is exact.
function PMMMPlayerHasWonder(pPlayer, iWonder)
	if bPMMMCPPlayerHasWonder == nil then
		bPMMMCPPlayerHasWonder = (pPlayer.HasWonder ~= nil)
	end
	if bPMMMCPPlayerHasWonder then
		return pPlayer:HasWonder(iWonder)
	end
	if not iWonder or iWonder < 0 then return false end
	for pCity in pPlayer:Cities() do
		if pCity:GetNumBuilding(iWonder) > 0 then
			return true
		end
	end
	return false
end

--Player:HasBuilding(building): NOT in the spec's §4 table -- a call site the name-by-name inventory
--missed (PMMMCoreLikesDislikes.lua, wonder Likes/Dislikes). CP binds it (CvLuaPlayer.cpp LUAAPIIMPL
--Player HasBuilding -> CvPlayer::HasBuilding) and Lekmod does not bind it (no "HasBuilding" in its
--CvLuaPlayer.cpp at all). CP semantics: any city HasBuilding(i) == any city GetNumBuilding(i) > 0 --
--the same loop HasWonder makes, so the fallback is exact, not approximate.
function PMMMPlayerHasBuilding(pPlayer, iBuilding)
	if bPMMMCPPlayerHasBuilding == nil then
		bPMMMCPPlayerHasBuilding = (pPlayer.HasBuilding ~= nil)
	end
	if bPMMMCPPlayerHasBuilding then
		return pPlayer:HasBuilding(iBuilding)
	end
	if not iBuilding or iBuilding < 0 then return false end
	for pCity in pPlayer:Cities() do
		if pCity:GetNumBuilding(iBuilding) > 0 then
			return true
		end
	end
	return false
end

--Player:GetRandomIntrigue(city): NOT in the spec's §4 table -- a call site the name-by-name inventory
--missed (PMMMShiromeTrait.lua, Shirome's Leader-MG free intrigue). CP-only binding (CvLuaPlayer.cpp
--lGetRandomIntrigue -> CvPlayerEspionage::GetRandomIntrigue), and the backing is deep inside CP's
--espionage/AIOperation rework: it reads CP's spy-assignment and AI sneak-attack-operation state, none
--of which Lekmod's vanilla espionage has or exposes to Lua. No Lua fallback can exist; under a DLL
--without the binding the call is a documented no-op (Shirome's free intrigue silently does nothing,
--like Kyouko's StartsWithPantheon, lekmod-scope-engine.md §7.4). Returns true if intrigue was granted
--so the caller can decide whether to spend its once-per-N-turns bookkeeping on it.
function PMMMPlayerGetRandomIntrigue(pPlayer, pCity)
	if bPMMMCPPlayerGetRandomIntrigue == nil then
		bPMMMCPPlayerGetRandomIntrigue = (pPlayer.GetRandomIntrigue ~= nil)
	end
	if bPMMMCPPlayerGetRandomIntrigue then
		pPlayer:GetRandomIntrigue(pCity)
		return true
	end
	return false
end

--Game:AnyoneHasWonder(building): NOT in the spec's §4 table -- a call site the
--name-by-name inventory missed (PMMMCoreLikesDislikes.lua, wonder Likes/Dislikes). CP binds it
--(CvLuaGame.cpp lAnyoneHasWonder -> CvGame::AnyoneHasWonder); Lekmod has neither binding nor backing.
--CP semantics: any LIVING player HasWonder(i) -- the loop below over civs, city-states and barbarians
--(iMaxCivsAndCS is the barbarian slot, GameDefines.MAX_CIV_PLAYERS) covers every player that can own
--a city; the spectator cannot, so the fallback matches CP exactly.
function PMMMGameAnyoneHasWonder(iWonder)
	if bPMMMCPGameAnyoneHasWonder == nil then
		bPMMMCPGameAnyoneHasWonder = (Game.AnyoneHasWonder ~= nil)
	end
	if bPMMMCPGameAnyoneHasWonder then
		return Game:AnyoneHasWonder(iWonder)
	end
	for iOther = 0, iMaxCivsAndCS do
		local pOther = Players[iOther]
		if pOther and pOther:IsAlive() and PMMMPlayerHasWonder(pOther, iWonder) then
			return true
		end
	end
	return false
end

--Player:IsAtWarWith(player): CP is a one-liner over the teams; the mod already uses the Teams form at
--MagicalGirlMissionHandler.lua's ENEMY targeting.
function PMMMPlayerIsAtWarWith(pPlayer, iOther)
	if bPMMMCPPlayerIsAtWarWith == nil then
		bPMMMCPPlayerIsAtWarWith = (pPlayer.IsAtWarWith ~= nil)
	end
	if bPMMMCPPlayerIsAtWarWith then
		return pPlayer:IsAtWarWith(iOther)
	end
	if not iOther or iOther < 0 then return false end
	local pOther = Players[iOther]
	if not pOther then return false end
	return Teams[pPlayer:GetTeam()]:IsAtWar(pOther:GetTeam())
end

--City:HasBuilding(building): CP reads the total building count (CvCity::HasBuilding ->
--GetCityBuildings()->GetNumBuilding), which includes free buildings. City:IsHasBuilding reads the same
--counter and is bound in BOTH DLLs, so the fallback is exact, not approximate (GetNumRealBuilding would
--have differed on free buildings).
function PMMMCityHasBuilding(pCity, iBuilding)
	if bPMMMCPCityHasBuilding == nil then
		bPMMMCPCityHasBuilding = (pCity.HasBuilding ~= nil)
	end
	if bPMMMCPCityHasBuilding then
		return pCity:HasBuilding(iBuilding)
	end
	return pCity:IsHasBuilding(iBuilding)
end

--City:GetSpecialistRate(specialist): CP's per-turn Great Person progress in hundredths from a CP-only class
--(CvCityCitizens::GetSpecialistRate: specialists + buildings + religion, times the city's rate modifier).
--Fallback approximation per the spec: specialist count x the Specialists-table base rate (GreatPeopleRateChange,
--vanilla value 3 for GP specialists, 0 for citizens), x 100 for the hundredths
--ChangeSpecialistGreatPersonProgressTimes100 takes. Under-counts by design (no building, religion or modifier
--terms), so Time Stop grants slightly fewer Great Person points under Lekmod than under CP.
function PMMMCityGetSpecialistRate(pCity, iSpecialist)
	if bPMMMCPCityGetSpecialistRate == nil then
		bPMMMCPCityGetSpecialistRate = (pCity.GetSpecialistRate ~= nil)
	end
	if bPMMMCPCityGetSpecialistRate then
		return pCity:GetSpecialistRate(iSpecialist)
	end
	local tSpecialist = GameInfo.Specialists[iSpecialist]
	if not tSpecialist then return 0 end
	return (pCity:GetSpecialistCount(iSpecialist) or 0) * (tSpecialist.GreatPeopleRateChange or 0) * 100
end

--City:RefreshTourism(): CP-only recompute trigger. Tourism is recomputed on every turn anyway, so under
--Lekmod the call is dropped and the next turn's recompute covers it (one-turn-later display only).
function PMMMCityRefreshTourism(pCity)
	if bPMMMCPCityRefreshTourism == nil then
		bPMMMCPCityRefreshTourism = (pCity.RefreshTourism ~= nil)
	end
	if bPMMMCPCityRefreshTourism then
		pCity:RefreshTourism()
	end
end



-- from http://lua-users.org/wiki/SplitJoin
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


--Credit to UltimatePotato from Civfanatics for this trick!
function toBits(num)
    -- returns a table of bits, least significant first.
	t={} -- will contain the bits
    while num>0 do
        local rest=math.fmod(num,2)
        t[#t+1]=rest
        num=(num-rest)/2
    end
    return t
end

--This function returns a value of the format "xx:yyyyyyy", where "xx" is the PlayerID of a unit owner and "yyyyyyy" is the UnitID of the unit.
--Needed for table keys. Using a pUnit as a table key causes cross-table updates to fail!
function GetUnitSpecialID(iPlayer, iUnit)
	return iPlayer..":"..iUnit
end

function ReturnUnitFromSpecialID(ID)
	local temptable = split(ID, ":");	
	local iPlayer = tonumber(temptable[1]);
	local iUnit = tonumber(temptable[2]);
	local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
	if pUnit then
		return pUnit
	else
		return nil
	end
end

function ReturnPlotFromSpecialID(ID)
	local temptable = split(ID, ":");	
	local iX = tonumber(temptable[1]);
	local iY = tonumber(temptable[2]);
	local pPlot = Map.GetPlot(iX, iY)
	if pPlot then
		return pPlot
	else
		return nil
	end
end

function ReturnPlayerAndUnitIDsFromSpecialID(ID)
	local temptable = split(ID, ":");	
	local iPlayer = tonumber(temptable[1]);
	local iUnit = tonumber(temptable[2]);
	return iPlayer, iUnit
end


--Taken from Events & Decisions
function CompileCityID(pCity)
	local iOriginalOwner = pCity:GetOriginalOwner()
	local iTurnFounded = pCity:GetGameTurnFounded ()	--Used to Compile Unique City ID
	local iCityID = ("X" .. pCity:GetX() .. "Y" .. pCity:GetY() .. "P" .. iOriginalOwner .. "T" .. iTurnFounded)
	return iCityID
end

function Vice_DecompileCityID(sKey)
    local iBreak = string.find(sKey, "Y")
	local iBreak2 = string.find(sKey, "P")
    iX = tonumber(string.sub(sKey, 2, iBreak - 1))
    iY = tonumber(string.sub(sKey, iBreak + 1, iBreak2 - 1))
    local pPlot = Map.GetPlot(iX, iY)
	local pCity = pPlot:GetPlotCity()
    return pCity
end

--v21: Find the nearest friendly City

function FindNearestFriendlyCity(pPlayer, pPlot)
	if pPlot:IsCity() and pPlot:GetOwner() == pPlayer:GetID() then
		return pPlot:GetPlotCity()
	else
		local iNearestDistance = 10000
		local pNearestCity;
		local iX = pPlot:GetX()
		local iY = pPlot:GetY()
		for pCity in pPlayer:Cities() do
			local iThisDistance = Map.PlotDistance(iX, iY, pCity:GetX(), pCity:GetY())
			if iThisDistance < iNearestDistance then
				iNearestDistance = iThisDistance
				pNearestCity = pCity
			end
		end
		return pNearestCity
	end
end


--Given a Unit ID and Owner ID, get the Key in the MagicalGirls table which corresponds.
function GetMagicalGirlKey(iOwner, iUnit)
	for k, v in pairs(MagicalGirls) do
		if v.UnitID == iUnit and v.Owner == iOwner then
			return k
		end
	end
	return false
end

--Set the Soul Gem State for a MG, corresponding to its given Soul Gem value. Also provide it with the proper Promotion.
function SetSoulGemState(iMGKey)
	for k, v in pairs(MapModData.gPMMMSoulGemStates) do
		if v.MinPercent <= MagicalGirls[iMGKey].SoulGem and v.MaxPercent >= MagicalGirls[iMGKey].SoulGem then
			MagicalGirls[iMGKey].SoulGemState = k
			local pPlayer, pUnit = RetrieveMGPointers(iMGKey)
			if pUnit then	-- [port] off-map MGs (Freezer, hunt, vacation, sparring) have no unit
				pUnit:SetHasPromotion(v.Promotion, true)
				for k2, v2 in pairs(MapModData.gPMMMSoulGemStates) do
					if k2 ~= k then
						pUnit:SetHasPromotion(v2.Promotion, false)
					end
				end
			end
			return
		end
	end
	print("Error: Soul Gem State for current Soul Gem percentage not found!")
end

--Add Corruption to a MG's gem, taking into account Polishing.
function DoChangeCorruption(iCorruption, iMGKey)
	--Do we have Polish?
	local bIsPolish
	if MagicalGirls[iMGKey].Polish then
		if MagicalGirls[iMGKey].Polish > 0 then
			bIsPolish = true
		end
	end
	if bIsPolish and iCorruption > 0 then
		local iSoulGemCorruption = 0
		local iPolishCorruption = 0
		--In the case of an odd number, the amount hit to the Soul Gem is 1 higher than the amount hit to the Polish.
		--This means the default 1% corruption per turn is not affected!
		if (iCorruption % 2) > 0 then
			iSoulGemCorruption = math.floor(iCorruption / 2) + 1
			iPolishCorruption = math.floor(iCorruption / 2)
		else
			iSoulGemCorruption = iCorruption / 2
			iPolishCorruption = iCorruption / 2
		end
		--If the corruption to the Polish is higher than the total Polish, then the remainder is dealt to the Soul Gem proper
		if iPolishCorruption > MagicalGirls[iMGKey].Polish then
			iPolishCorruption = iPolishCorruption - MagicalGirls[iMGKey].Polish
			iSoulGemCorruption = iSoulGemCorruption + iPolishCorruption
			MagicalGirls[iMGKey].Polish = 0
		else
			MagicalGirls[iMGKey].Polish = MagicalGirls[iMGKey].Polish - iPolishCorruption
		end
		MagicalGirls[iMGKey].SoulGem = MagicalGirls[iMGKey].SoulGem - iSoulGemCorruption
		local pPlayer, pMagicalGirl = RetrieveMGPointers(iMGKey)
		if pMagicalGirl and pPlayer:GetID() == Game:GetActivePlayer() then	-- [port] no unit for off-map MGs
			Events.AddPopupTextEvent(HexToWorld(ToHexFromGrid(Vector2(pMagicalGirl:GetX(), pMagicalGirl:GetY()))), Locale.ConvertTextKey("TXT_KEY_PMMM_TILEPOPUP_SOUL_GEM_MINUS", iSoulGemCorruption), 1)
		end
	else
		MagicalGirls[iMGKey].SoulGem = MagicalGirls[iMGKey].SoulGem - iCorruption
		--Clamp
		if MagicalGirls[iMGKey].SoulGem < 0 then
			MagicalGirls[iMGKey].SoulGem = 0
		elseif MagicalGirls[iMGKey].SoulGem > GameDefines.MAXIMUM_SOUL_GEM_AMOUNT then
			MagicalGirls[iMGKey].SoulGem = GameDefines.MAXIMUM_SOUL_GEM_AMOUNT
		end
		SetSoulGemState(iMGKey)
		local pPlayer, pMagicalGirl = RetrieveMGPointers(iMGKey)
		if pMagicalGirl and pPlayer:GetID() == Game:GetActivePlayer() then	-- [port] no unit for off-map MGs
			local sString;
			if iCorruption > 0 then
				sString = Locale.ConvertTextKey("TXT_KEY_PMMM_TILEPOPUP_SOUL_GEM_MINUS", iCorruption)
			else
				sString = Locale.ConvertTextKey("TXT_KEY_PMMM_TILEPOPUP_SOUL_GEM_PLUS", -iCorruption)
			end
			Events.AddPopupTextEvent(HexToWorld(ToHexFromGrid(Vector2(pMagicalGirl:GetX(), pMagicalGirl:GetY()))), sString, 1)
		end
	end
end

--Get a pPlayer and a pUnit from a key in the MG table.
--This returns two values, so always call it as "pPlayer, pUnit = RetrieveMGPointers(iMGKey)"
--Using "(RetrieveMGPointers(iMGKey))" will return just a pPlayer
function RetrieveMGPointers(iMGKey)
	local pPlayer = Players[MagicalGirls[iMGKey].Owner]
	local pUnit = pPlayer:GetUnitByID(MagicalGirls[iMGKey].UnitID)
	if pUnit then
		return pPlayer, pUnit
	else
		return pPlayer
	end
end


--Get the best possible spot to plop a new Hostile unit. Copied from Recluse's Lua.
--pSpawningUnit is the unit the new Hostile is replacing; it is excluded from the "is this plot occupied" test. It may be nil.
function FindBestEnemySpawnPlot(pOriginalPlot, pSpawningUnit)	-- [port] pUnit used to be read as an undeclared global here
	local pSpawnPlot;
	--We'll keep a table of how acceptable a plot is to spawn on if it doesn't have perfect conditions (no cities or units).
	--Values used:
	--2: Contains only military units, pretty acceptable since it will just displace the units.
	--1: Contains civilian units, only acceptable as a last resort since it will kill the civilian unit.
	--0: Contains a city. NEVER spawn it in a city!
	local tPlotValidity = {}
	-- [port] tPlotValidity is keyed by plot userdata, so pairs() order differs per client; keep a parallel ordered list for the Game.Rand pick
	local tPlotOrder = {}
	local function SetPlotValidity(pPlot, iValidity)
		if tPlotValidity[pPlot] == nil then
			tPlotOrder[#tPlotOrder + 1] = pPlot
		end
		tPlotValidity[pPlot] = iValidity
	end
	--Let's see if the plot it's already on is okay first.
	if not pOriginalPlot:IsCity() then
		local bThisPlotValid = true;
		--Iterate over units in this plot, if there are any units other than the GP itself then this shouldn't be considered valid for this first check
		for i = 0, pOriginalPlot:GetNumUnits() - 1 do
			local pPlotUnit = pOriginalPlot:GetUnit(i)
			if pPlotUnit ~= pSpawningUnit then
				bThisPlotValid = false
				if not pPlotUnit:IsCombatUnit() then
					SetPlotValidity(pOriginalPlot, 1)
				end
			end
		end
		if bThisPlotValid == true then
			pSpawnPlot = pOriginalPlot
		elseif tPlotValidity[pOriginalPlot] == nil then
			SetPlotValidity(pOriginalPlot, 2)
		end
	else
		SetPlotValidity(pOriginalPlot, 0)
	end

	--If that didn't work, then let's try each adjacent plot.
	if not pSpawnPlot then
		local direction_types = {
			DirectionTypes.DIRECTION_NORTHEAST,
			DirectionTypes.DIRECTION_EAST,
			DirectionTypes.DIRECTION_SOUTHEAST,
			DirectionTypes.DIRECTION_SOUTHWEST,
			DirectionTypes.DIRECTION_WEST,
			DirectionTypes.DIRECTION_NORTHWEST
		}
		for a, direction in ipairs(direction_types) do
			local pNextPlot = Map.PlotDirection(pOriginalPlot:GetX(), pOriginalPlot:GetY(), direction)
			if pNextPlot ~= nil then
				if not pNextPlot:IsCity() then
					if pNextPlot:IsUnit() then
						for i = 0, pNextPlot:GetNumUnits() - 1 do
							local pPlotUnit = pNextPlot:GetUnit(i)
							if not pPlotUnit:IsCombatUnit() then
								SetPlotValidity(pNextPlot, 1)
							end
						end
						if tPlotValidity[pNextPlot] == nil then
							SetPlotValidity(pNextPlot, 2)
						end
					else
						pSpawnPlot = pNextPlot
						break
					end
				else
					SetPlotValidity(pNextPlot, 0)
				end
			end
		end
	end

	--If THAT didn't work, then we'll refer to the table we've created.
	if not pSpawnPlot then
		local tBestPlots = {}
		for i = 1, #tPlotOrder do	-- [port] ordered iteration so every client picks the same plot
			local pPlot = tPlotOrder[i]
			if tPlotValidity[pPlot] == 2 then
				table.insert(tBestPlots, pPlot)
			end
		end
		if #tBestPlots < 1 then
			for i = 1, #tPlotOrder do
				local pPlot = tPlotOrder[i]
				if tPlotValidity[pPlot] == 1 then
					table.insert(tBestPlots, pPlot)
				end
			end	
		end
		--Choose one of the best plots at random!
		if #tBestPlots > 0 then
			pSpawnPlot = tBestPlots[Game.Rand(#tBestPlots, "Witch Plot Randomizer") + 1]
		end
	end

	--If even THAT didn't work...that basically means that there is a city in both the GP's tile and in every tile around it!
	--If something that crazy happened, then whatever -- spawn it in the same plot!
	if not pSpawnPlot then
		pSpawnPlot = pOriginalPlot
	end

	return pSpawnPlot
end


function DoConsumeGriefSeed(iMGKey, iPlayer)
	PMMM.GriefSeeds[iPlayer] = math.max(0, PMMM.GriefSeeds[iPlayer] - 1)
	DoChangeCorruption(-MapModData.gPMMMGriefSeedRecoverAmount, iMGKey)
	--[port] Phase 4: listeners (Homura's Time Stop cooldown) react to a seed being used.
	if tPMMMGriefSeedUsedHooks then
		for _, fHook in ipairs(tPMMMGriefSeedUsedHooks) do fHook(iPlayer, iMGKey) end
	end
	local pPlayer, pUnit = RetrieveMGPointers(iMGKey)
	--[port] Phase 6 Lekmod: AddMessage is CP-only; the wrapper (defined above) calls it natively under CP
	--and falls back to AddNotification elsewhere.
	PMMMPlayerAddMessage(pPlayer, Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_USED_GRIEF_SEED", MagicalGirls[iMGKey].Name, MapModData.gPMMMGriefSeedRecoverAmount))
end


--Ultimate Madoka Law of Cycles
--[port] Phase 4: the promotions a girl "applied" herself, counted when the Cycle takes her. Design section 2 and
--ruling 8: she returns with 100 XP for each of them. Applied means earned or chosen: a promotion from the pool her
--unit can pick at a level-up (UnitPromotions_UnitCombats rows for the Magical Girl's PromotionClass that can be
--chosen). Everything she was born with or carries as a state stays out: her unit's and her Great Person's free
--promotions, the leader promotion, Mood and Soul Gem state promotions, and the framework's timed promotions.
local tCyclePromotionPool

local function GetCyclePromotionPool()
	if tCyclePromotionPool then return tCyclePromotionPool end
	tCyclePromotionPool = {}
	local pMGUnit = GameInfo.Units.UNIT_PMMM_MAGICAL_GIRL
	local sClass = (pMGUnit and pMGUnit.PromotionClass) or "UNITCOMBAT_MAGICALGIRL"
	for row in GameInfo.UnitPromotions_UnitCombats() do
		if row.UnitCombatType == sClass then
			local pPromo = GameInfo.UnitPromotions[row.PromotionType]
			if pPromo and not (pPromo.CannotBeChosen == 1 or pPromo.CannotBeChosen == true) then
				tCyclePromotionPool[pPromo.ID] = true
			end
		end
	end
	return tCyclePromotionPool
end

local function CountCycleAppliedPromotions(iMGKey, pUnit)
	if not pUnit then return 0 end
	local tPool = GetCyclePromotionPool()
	local tExclude = {}
	--Free promotions of her own unit type and of the Great Person she came from.
	local sOriginClass = MagicalGirls[iMGKey].Class
	local pOriginClass = sOriginClass and GameInfo.UnitClasses[sOriginClass]
	for row in GameInfo.Unit_FreePromotions() do
		local pFreeUnit = GameInfo.Units[row.UnitType]
		if pFreeUnit and (pFreeUnit.ID == pUnit:GetUnitType() or (pOriginClass and pFreeUnit.Class == pOriginClass.Type)) then
			local pPromo = GameInfo.UnitPromotions[row.PromotionType]
			if pPromo then tExclude[pPromo.ID] = true end
		end
	end
	--Timed promotions the ability framework is holding on her.
	local tTimed = PMMM.TimedPromotions and PMMM.TimedPromotions[pUnit:GetOwner()]
	if tTimed then
		for _, v in ipairs(tTimed) do
			if v.UnitID == pUnit:GetID() then tExclude[v.Promotion] = true end
		end
	end
	local iCount = 0
	for iPromo in pairs(tPool) do
		if not tExclude[iPromo] and pUnit:IsHasPromotion(iPromo) then
			iCount = iCount + 1
		end
	end
	return iCount
end

--[port] Phase 4: iTurns is how long she stays in the Cycle (default MapModData.gPMMMLawOfCyclesTurns, 10 at Standard);
--the Herald of Madoka's Lead Away passes its own shorter stay. bLedAway marks a girl who is owed a free promotion.
function DoLawOfCyclesTakeaway(iMGKey, iNewPlayer, iTurns, bLedAway)
	local pPlayer, pUnit = RetrieveMGPointers(iMGKey)
	local iX = pUnit:GetX()
	local iY = pUnit:GetY()
	local iMG = GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL
	--[port] Phase 4: count what she earned before the list is wiped; ReturnFromLawOfCycles pays it back as XP.
	MagicalGirls[iMGKey].CycleAppliedPromotions = CountCycleAppliedPromotions(iMGKey, pUnit)
	MagicalGirls[iMGKey].CycleTurns = iTurns or MapModData.gPMMMLawOfCyclesTurns
	if bLedAway then
		MagicalGirls[iMGKey].CycleLedAway = true
	else
		MagicalGirls[iMGKey].CycleLedAway = nil
	end
	local iCycleTurns = MagicalGirls[iMGKey].CycleTurns
	MagicalGirls[iMGKey].Status = GameInfoTypes.MGACTIONSTATE_CYCLING
	MagicalGirls[iMGKey].CycleStartTurn = Game:GetGameTurn()
	if MagicalGirls[iMGKey].SummonedWitch then
		local _, iUnit = ReturnPlayerAndUnitIDsFromSpecialID(MagicalGirls[iMGKey].SummonedWitch)
		local pWitchUnit = Players[_]:GetUnitByID(iUnit)
		if pWitchUnit then pWitchUnit:Kill(true) end	--[port] Phase 4: the Witch may already be gone
		MagicalGirls[iMGKey].SummonedWitch = nil
	end
	MagicalGirls[iMGKey].SummonedWitchCooldown = nil
	MagicalGirls[iMGKey].Promotions = {}
	local sText;
	local sTitle;
	local iNotiType;
	if iNewPlayer then
		local iOldPlayer = MagicalGirls[iMGKey].Owner
		MagicalGirls[iMGKey].Owner = iNewPlayer
		sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_TOOK_ENEMY_MG_LOC_TEXT", MagicalGirls[iMGKey].Name, iCycleTurns)
		sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_TOOK_ENEMY_MG_LOC_TITLE")
		iNotiType = NotificationTypes.NOTIFICATION_GENERIC

		local sTheirText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_MG_LED_AWAY_BY_ENEMY_LOC_TEXT", MagicalGirls[iMGKey].Name)
		local sTheirTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_MG_LED_AWAY_BY_ENEMY_LOC_TITLE")
		pPlayer:AddNotification(NotificationTypes.NOTIFICATION_UNIT_DIED, sTheirText, sTheirTitle, iX, iY, iMG)
		Players[iNewPlayer]:AddNotification(iNotiType, sText, sTitle, iX, iY, iMG)
	else
		sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_TAKEN_BY_LOC_TEXT", MagicalGirls[iMGKey].Name, iCycleTurns)
		sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_TAKEN_BY_LOC_TITLE")
		iNotiType = NotificationTypes.NOTIFICATION_UNIT_DIED
		pPlayer:AddNotification(iNotiType, sText, sTitle, iX, iY, iMG)
	end
	pUnit:Kill()

end


--[port] Phase 4: the XP the engine asks for at a given level, the same sum CvUnit::experienceNeeded makes
--(EXPERIENCE_PER_LEVEL x (1+2+..+L), the player's level modifier rounded up, then the game speed's ExperiencePercent).
local function CycleExperienceNeeded(pPlayer, iLevel)
	local iNeeded = GameDefines.EXPERIENCE_PER_LEVEL * iLevel * (iLevel + 1) / 2
	local iModifier = pPlayer:GetLevelExperienceModifier()
	if iModifier ~= 0 then
		iNeeded = math.ceil(iNeeded * (100 + iModifier) / 100)
	end
	local pSpeed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
	local iSpeedPercent = (pSpeed and pSpeed.ExperiencePercent) or 100
	return math.floor(iNeeded * iSpeedPercent / 100)
end

--[port] Phase 4: returns true when she came back, false when there is nowhere to put her yet (no capital); she then
--stays in the Cycle and CheckLOCMagicalGirls tries again next turn.
function ReturnFromLawOfCycles(iMGKey)
	local pPlayer = (RetrieveMGPointers(iMGKey))
	local pCapital = pPlayer:GetCapitalCity()
	if not pCapital then return false end
	local iX = pCapital:GetX()
	local iY = pCapital:GetY()
	local iMG = GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL
	--[port] Phase 4: the respawn in OnCreatedMagicalGirl copies Level, XP, HP and Promotions from the table while
	--InitUnit is still running, so the fresh values have to be in place before it, not after.
	MagicalGirls[iMGKey].SoulGem = 100
	MagicalGirls[iMGKey].Level = 1
	MagicalGirls[iMGKey].XP = 0
	MagicalGirls[iMGKey].HP = GameDefines.MAX_HIT_POINTS
	MagicalGirls[iMGKey].Promotions = {}
	MagicalGirls[iMGKey].Loyalty = 100
	tMagicalGirlSpawnTable["ID"] = iMGKey
	local eMagicalGirl = pPlayer:InitUnit(iMG, iX, iY, UNITAI_ATTACK)
	eMagicalGirl:SetName(MagicalGirls[iMGKey].Name)
	SetMagicalGirlStrength(pPlayer:GetID(), eMagicalGirl:GetID())
	MagicalGirls[iMGKey].UnitID = eMagicalGirl:GetID()
	MagicalGirls[iMGKey].Status = GameInfoTypes.MGACTIONSTATE_ACTIVE

	--[port] Phase 4 (design section 2, ruling 8): 100 XP for every promotion she had applied, uncapped. The figure is
	--the Standard-speed one, scaled by the game speed's ExperiencePercent as the engine scales non-combat XP.
	local pSpeed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
	local iSpeedPercent = (pSpeed and pSpeed.ExperiencePercent) or 100
	local iApplied = MagicalGirls[iMGKey].CycleAppliedPromotions or 0
	local iXP = math.floor(100 * iApplied * iSpeedPercent / 100)
	local iBaseXP = iXP
	local bFreePromotion = MagicalGirls[iMGKey].CycleLedAway
	if bFreePromotion then
		--Lead Away's bonus promotion, of the player's choice, on top of what the XP buys. The bare promotion-ready
		--flag cannot carry it: she is reborn inside PlayerDoTurn, CvPlayer::doTurnUnits runs straight after it, and
		--CvUnit::doTurn -> testPromotionReady clears any flag her XP does not cover (CvPlayer.cpp:10571-10580,
		--CvUnit.cpp:3160). So her XP is raised to exactly the threshold of one level beyond what it already buys.
		local iLevel = 1
		while CycleExperienceNeeded(pPlayer, iLevel) <= iXP do
			iLevel = iLevel + 1
		end
		iXP = CycleExperienceNeeded(pPlayer, iLevel)
	end
	eMagicalGirl:SetExperience(iXP)
	MagicalGirls[iMGKey].XP = iXP
	MagicalGirls[iMGKey].CycleLockedXP = iXP
	--She earns nothing more: ExperiencePercent -100 on this promotion zeroes combat XP (CvUnit.cpp:22002-22012), and
	--the ability file clamps her XP back to CycleLockedXP each turn against any other source.
	eMagicalGirl:SetHasPromotion(GameInfoTypes.PROMOTION_PMMM_CYCLE_RETURNED, true)
	if iXP > 0 and iXP >= eMagicalGirl:ExperienceNeeded() then
		eMagicalGirl:SetPromotionReady(true)
	end
	MagicalGirls[iMGKey].CycleAppliedPromotions = nil
	MagicalGirls[iMGKey].CycleLedAway = nil
	MagicalGirls[iMGKey].CycleTurns = nil

	SetSoulGemState(iMGKey)
	local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_TEXT", MagicalGirls[iMGKey].Name)
	sText = sText .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_XP", iBaseXP, iApplied)
	if bFreePromotion then
		sText = sText .. " " .. Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_FREE_PROMOTION")
	end
	local sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_LAW_OF_CYCLES_REBORN_TITLE")
	pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER, sText, sTitle, iX, iY, iMG)
	return true
end



--Use Grief Seed button clicked (enabled as a LuaEvent)
--As of v21, it is still in the LuaEvents, but it will be called from a CustomMissionStart for multiplayer compatibility.
function UseGriefSeed(iUnit, iPlayer, bKey)
	--bKey means that iUnit is a MGKey rather than a Unit ID, used for the Freezer button since those units aren't on the map
	local pPlayer = Players[iPlayer]
	local pUnit;
	local iMGKey
	if not bKey then
		pUnit = pPlayer:GetUnitByID(iUnit)
		iMGKey = GetMagicalGirlKey(iPlayer, iUnit)
	else
		iMGKey = iUnit
	end
	local ttable = {}
	if iMGKey and PMMM.GriefSeeds[iPlayer] and PMMM.GriefSeeds[iPlayer] > 0 then
		DoConsumeGriefSeed(iMGKey, iPlayer)
		SetSoulGemState(iMGKey)
		LuaEvents.PMMMRefreshGriefSeedDisplay()
		if pUnit then
			pUnit:ChangeMoves(-1 * GameDefines.MOVE_DENOMINATOR)
		end
	else
		return
	end
end


--Check if unit has time stop promos.
--This was in Homura's trait script, but since EnemyUnitPanel and such use it, it needs to always be available.
tTimeStopPromotions = {}

for promotion in GameInfo.UnitPromotions() do
	if string.find(promotion.Type, 'PROMOTION_PMMM_TIME_STOP_') then
		tTimeStopPromotions[-promotion.MovesChange] = promotion.ID
	end
end

function HasAnyTimeStopPromo(pUnit)
	for k, v in pairs(tTimeStopPromotions) do
		if pUnit:IsHasPromotion(v) then
			return true
		end
	end
	return false
end


function DeckShuffle(tTable, sString)
	local tDeck = {}
	for k, v in pairs(tTable) do
		if v > -1 then
			for i = 0, v, 1 do
				tDeck[#tDeck + 1] = k
			end
		end
	end
	
	if not sString then sString = "PMMM Generic Deck Shuffle" end
	
	return tDeck[Game.Rand(#tDeck, sString) + 1]
end


function GetLeaderMagicalGirl(iPlayer)
	for k, v in pairs(MapModData.PMMM.MagicalGirls) do
		if v.Owner == iPlayer and v.IsLeader == true and v.Status == GameInfoTypes.MGACTIONSTATE_ACTIVE then
			local pPlayer = Players[iPlayer]
			local pUnit = pPlayer:GetUnitByID(v.UnitID)
			if pUnit then return pUnit end
		end
	end
	return false
end


function SetMagicalGirlStrength(iPlayer, iUnit)
	local iEra;
	local pPlayer = Players[iPlayer]
	local pUnit;
	if iUnit then
		pUnit = pPlayer:GetUnitByID(iUnit)
	end
	if MapModData.gPMMMTraits[iPlayer] and (MapModData.gPMMMTraits[iPlayer].MaximumMetEraMGStrength == 1 or MapModData.gPMMMTraits[iPlayer].MaximumMetEraMGStrength == true) then
		local iHighestEra = pPlayer:GetCurrentEra();
		local pTeam = Teams[pPlayer:GetTeam()]
		for i = 0, GameDefines.MAX_MAJOR_CIVS -1, 1 do
			local pLoop = Players[i]
			if pLoop:IsAlive() and pTeam:IsHasMet(pLoop:GetTeam()) then
				local iTheirEra = pLoop:GetCurrentEra()
				if iTheirEra and iTheirEra > iHighestEra then
					iHighestEra = iTheirEra
				end
			end
		end
		iEra = iHighestEra
	else
		iEra = pPlayer:GetCurrentEra()
	end

	--Set the strength (but check for pUnit to exist; this function should work without passing a unit ID so we can just get a number.)
	if pUnit then
		pUnit:SetBaseCombatStrength(MapModData.gPMMMMagicalGirlEraStrengths[iEra])
	end

	--Also return the value.
	return MapModData.gPMMMMagicalGirlEraStrengths[iEra]
end