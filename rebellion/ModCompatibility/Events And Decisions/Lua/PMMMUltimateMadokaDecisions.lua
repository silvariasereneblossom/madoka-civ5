-- PMMMUltimateMadokaDecisions
-- Author: TheBeast
-- DateCreated: 8/25/2014 2:01:53 PM
--------------------------------------------------------------

local iMagicalGirlClass = GameInfoTypes.UNITCLASS_MAGICALGIRL
local iLuminous = GameInfoTypes.BUILDING_PMMM_LUMINOUS_GARDEN
local iPromotion = GameInfoTypes.PROMOTION_DECISIONS_MADOKA

--------------------------------------------------------------------------------------------------------------------------------------------
--Decision 1: Establish Yuri Valhalla
--+3 Happiness from Luminous Gardens and +10% Growth
--------------------------------------------------------------------------------------------------------------------------------------------
local Decisions_YuriValhalla = {}
	Decisions_YuriValhalla.Name = "TXT_KEY_DECISIONS_MADOKA_YURI_VALHALLA"
	Decisions_YuriValhalla.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_YURI_VALHALLA_DESC")
	HookDecisionCivilizationIcon(Decisions_YuriValhalla, "CIVILIZATION_MADOKA")
	Decisions_YuriValhalla.CanFunc = (
	function(pPlayer)
		if (pPlayer:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_MADOKA) then
			return false, false
		end
		if load(pPlayer, "Decisions_YuriValhalla") == true then
			Decisions_YuriValhalla.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_YURI_VALHALLA_ENACTED_DESC")
			return false, false, true
		end

		local iCost = math.ceil(800 * iMod)
		Decisions_YuriValhalla.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_YURI_VALHALLA_DESC", iCost)
		
		if pPlayer:GetGold() < iCost then return true, false end

		if (pPlayer:GetNumResourceAvailable(iMagistrate, false) < 2) then return true, false end
		
		local iNumMagicalGirls = 0
		for pUnit in pPlayer:Units() do
			if pUnit:GetUnitClassType() == iMagicalGirlClass then
				iNumMagicalGirls = iNumMagicalGirls + 1
				if iNumMagicalGirls >= 4 then
					break
				end
			end
		end

		if iNumMagicalGirls < 4 then
			return true, false
		end

		local iNumLuminousGardens = 0
		for pCity in pPlayer:Cities() do
			if pCity:IsHasBuilding(iLuminous) then
				iNumLuminousGardens = iNumLuminousGardens + 1
				if iNumLuminousGardens >= 2 then
					return true, true
				end
			end
		end

		return true, false
	end
	)
	
	Decisions_YuriValhalla.DoFunc = (
	function(pPlayer)
		local iCost = math.ceil(800 * iMod)
		pPlayer:ChangeGold(-iCost)
		pPlayer:ChangeNumResourceTotal(iMagistrate, -2)
		pPlayer:SetNumFreePolicies(1)
		pPlayer:SetNumFreePolicies(0)
		pPlayer:SetHasPolicy(GameInfoTypes.POLICY_DECISIONS_MADOKA_YURI_VALHALLA, true)
		save(pPlayer, "Decisions_YuriValhalla", true)
	end
	)

Decisions_AddCivilisationSpecific(GameInfoTypes.CIVILIZATION_MADOKA, "Decisions_YuriValhalla", Decisions_YuriValhalla)


--------------------------------------------------------------------------------------------------------------------------------------------
--Decision 2: Appoint {Magical Girl Name} as your Knight
--Grant a level 4+ MG a promotion with Impi ranged strike and +33% Strength. Only one MG with this can be owned at a time
--------------------------------------------------------------------------------------------------------------------------------------------

local Decisions_KnightOfMadoka = {}
	Decisions_KnightOfMadoka.Name = "TXT_KEY_DECISIONS_MADOKA_KNIGHT"
	Decisions_KnightOfMadoka.Desc = "TXT_KEY_DECISIONS_MADOKA_KNIGHT_DESC"
	Decisions_KnightOfMadoka.CanFunc = (
	function(pPlayer)
		if pPlayer:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_MADOKA then return false, false end
		
		for pUnit in pPlayer:Units() do

			if pUnit:GetUnitClassType() == iMagicalGirlClass then
			
				local sKey = "Decisions_KnightOfMadoka" ..pPlayer:GetID()..":"..pUnit:GetID()
				local sName = Locale.ConvertTextKey(pUnit:GetNameNoDesc()) or "A Nameless Magical Girl"
				
				tTempDecisions[sKey] = {}
				tTempDecisions[sKey].Name = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_KNIGHT", sName)
				tTempDecisions[sKey].Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_KNIGHT_DESC", sName)
				tTempDecisions[sKey].Data1 = pUnit
				tTempDecisions[sKey].Weight = 0
				tTempDecisions[sKey].Type = "Civilization"
				HookDecisionCivilizationIcon(tTempDecisions[sKey], "CIVILIZATION_MADOKA")
				tTempDecisions[sKey].CanFunc = (
				function(pPlayer, pUnit)
					local sKey = "Decisions_KnightOfMadoka" ..pPlayer:GetID()..":"..pUnit:GetID()
					local sName = Locale.ConvertTextKey(pUnit:GetNameNoDesc()) or "A Nameless Magical Girl"

					if load(pPlayer, sKey) == true and load(pPlayer, "Decisions_KnightOfMadoka") == true then
						tTempDecisions[sKey].Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_KNIGHT_ENACTED_DESC", sName)
						return false, false, true
					end

					if load(pPlayer, "Decisions_KnightOfMadoka") == true then
						return false, false
					end

					if pUnit:GetLevel() < 4 then
						return false, false
					end
					
					local iCost = math.ceil(200 * iMod)

					tTempDecisions[sKey].Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_MADOKA_KNIGHT_DESC", sName, iCost)

					if pPlayer:GetFaith() < iCost then return true, false end
				
					return true, true
				end
				)
				
				tTempDecisions[sKey].DoFunc = (
				function(pPlayer, pUnit)
					local sKey = "Decisions_KnightOfMadoka" ..pPlayer:GetID()..":"..pUnit:GetID()
					local iCost = math.ceil(200 * iMod)
					pPlayer:ChangeFaith(-iCost)
					pUnit:SetHasPromotion(iPromotion, true)
					for eEvent, fFunc in pairs(Decisions_KnightOfMadoka.Monitors) do
						eEvent.Remove(fFunc)
						eEvent.Add(fFunc)
					end
					save("GAME", "Decisions_KnightOfMadoka_Monitors", true)		
					save(pPlayer, "Decisions_KnightOfMadoka", true)
					save(pPlayer, sKey, true)
				end
				)
			end
		end
	end
	)

	Decisions_KnightOfMadoka.Monitors = {}
	Decisions_KnightOfMadoka.Monitors[GameEvents.UnitKilledInCombat] =  (
	function (iKiller, iKilled, iUnit)
		if GameInfo.Units[iUnit].Class == GameInfo.UnitClasses[iMagicalGirlClass].Type then
			local pPlayer = Players[iKilled]
			if load(pPlayer, "Decisions_KnightOfMadoka") == true then
				for pUnit in pPlayer:Units() do
					if pUnit:GetUnitClassType() == iMagicalGirlClass then
						if pUnit:IsHasPromotion(iPromotion) then
							return
						end
					end
				end
				save(pPlayer, "Decisions_KnightOfMadoka", false)
			end
		end
	end
	)

	Decisions_KnightOfMadoka.Monitors[GameEvents.PlayerDoTurn] =  (
	function(iPlayer)
		local pPlayer = Players[iPlayer]
		if load(pPlayer, "Decisions_KnightOfMadoka") == true then
			for pUnit in pPlayer:Units() do
				if pUnit:GetUnitClassType() == iMagicalGirlClass then
					if pUnit:IsHasPromotion(iPromotion) then
						return
					end
				end
			end
			save(pPlayer, "Decisions_KnightOfMadoka", false)
		end
	end
	)

Decisions_AddCivilisationSpecific(GameInfoTypes.CIVILIZATION_MADOKA, "Decisions_KnightOfMadoka", Decisions_KnightOfMadoka)