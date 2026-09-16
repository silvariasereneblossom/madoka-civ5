-- PMMMHomuraDecisions
-- Author: Vicevirtuoso
-- DateCreated: 8/22/2014 1:02:29 PM
--------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------
--Decision 1: Devote to Madoka
--If either Madoka is present, gain an exorbitant diplomatic bonus with them at the cost of a diplomatic penalty with everyone else.
--If neither are present, gain the Madoka Memorial which gives +2 Faith from Monuments but increases Unhappiness by 10%
--------------------------------------------------------------------------------------------------------------------------------------------
local tMadokaPlayers = {}
local bAnyMadokaPlayers;

for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
	local pPlayer = Players[i]
	if pPlayer:IsEverAlive() then
		if pPlayer:GetLeaderType() == GameInfoTypes.LEADER_MADOKA or pPlayer:GetLeaderType() == GameInfoTypes.LEADER_ORIGINAL_MADOKA then
			tMadokaPlayers[i] = true
			bAnyMadokaPlayers = true
		end
	end
end

local Decisions_DevoteToMadoka = {}
	Decisions_DevoteToMadoka.Name = "TXT_KEY_DECISIONS_HOMURA_DEVOTE_MADOKA"
	Decisions_DevoteToMadoka.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_DEVOTE_MADOKA_DESC")
	HookDecisionCivilizationIcon(Decisions_DevoteToMadoka, "CIVILIZATION_HOMURA")
	Decisions_DevoteToMadoka.CanFunc = (
	function(pPlayer)
		if (pPlayer:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_HOMURA) then
			return false, false
		end
		if load(pPlayer, "Decisions_DevoteToMadoka") == true then
			Decisions_DevoteToMadoka.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_DEVOTE_MADOKA_ENACTED_DESC")
			return false, false, true
		end
		
		local iCost = math.ceil(250 * iMod)
		Decisions_DevoteToMadoka.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_DEVOTE_MADOKA_DESC", iCost)
		
		if pPlayer:GetGold() < iCost then return true, false end
		
		if (pPlayer:GetNumResourceAvailable(iMagistrate, false) < 1) then return true, false end

		if pPlayer:GetCurrentEra() < GameInfoTypes.ERA_CLASSICAL then return true, false else return true, true end
	
	end
	)
	
	Decisions_DevoteToMadoka.DoFunc = (
	function(pPlayer)
		local iCost = math.ceil(250 * iMod)
		pPlayer:ChangeGold(-iCost)
		pPlayer:ChangeNumResourceTotal(iMagistrate, -1)
		if bAnyMadokaPlayers then
			pPlayer:SetNumFreePolicies(1)
			pPlayer:SetNumFreePolicies(0)
			pPlayer:SetHasPolicy(GameInfoTypes.POLICY_DECISIONS_HOMURA_DEVOTE_MADOKA, true)
		else
			pPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes.BUILDING_DECISIONS_HOMURA_DEVOTE_MADOKA, 1)
		end
		save(pPlayer, "Decisions_DevoteToMadoka", true)
	end
	)

	Decisions_DevoteToMadoka.Monitors = {}
	Decisions_DevoteToMadoka.Monitors[GameEvents.GetScenarioDiploModifier3] =  (
	function(iPlayer1, iPlayer2)
		local pPlayer1 = Players[iPlayer1]
		local pPlayer2 = Players[iPlayer2]
		if (load(pPlayer1, "Decisions_DevoteToMadoka") or load(pPlayer2, "Decisions_DevoteToMadoka")) and bAnyMadokaPlayers then
			if pPlayer1:GetCivilizationType() == GameInfoTypes.CIVILIZATION_HOMURA and tMadokaPlayers[iPlayer2] then
				return -150
			elseif pPlayer2:GetCivilizationType() == GameInfoTypes.CIVILIZATION_HOMURA and tMadokaPlayers[iPlayer1] then
				return -150
			else
				return 20
			end
		else
			return 0
		end
	end
	)

Decisions_AddCivilisationSpecific(GameInfoTypes.CIVILIZATION_HOMURA, "Decisions_DevoteToMadoka", Decisions_DevoteToMadoka)






--------------------------------------------------------------------------------------------------------------------------------------------
--Decision 2: Steal Weapons from City-State
--Gain the UU of a Militaristic CS, at the cost of Influence with that City-State.
--------------------------------------------------------------------------------------------------------------------------------------------
local Decisions_HomuraStealWeapons = {}
	Decisions_HomuraStealWeapons.Name = "TXT_KEY_DECISIONS_HOMURA_SAND_SHIELD"
	Decisions_HomuraStealWeapons.Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_SAND_SHIELD_DESC")
	HookDecisionCivilizationIcon(Decisions_HomuraStealWeapons, "CIVILIZATION_HOMURA")
	Decisions_HomuraStealWeapons.CanFunc = (
	function(pPlayer)
		if (pPlayer:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_HOMURA) then
			return false, false
		end
		
		for iCityState, pCityState in pairs(Players) do
			if pCityState:IsAlive() and pCityState:IsMinorCiv() and (Teams[pPlayer:GetTeam()]:IsHasMet(pCityState:GetTeam())) and pCityState:IsMinorCivHasUniqueUnit() == true then
			
				local tTable = {}

				local sKey = "Decisions_HomuraStealWeapons" .. iCityState
				tTable["Name"] = pCityState:GetName()
				tTable["UnitType"] = pCityState:GetMinorCivUniqueUnit()
				tTable["UnitTypeName"] = Locale.ConvertTextKey(GameInfo.Units[tTable["UnitType"]].Description)
				tTable["PrereqTech"] = GameInfo.Technologies[GameInfo.Units[tTable["UnitType"]].PrereqTech].ID or GameInfoTypes.TECH_AGRICULTURE
				tTable["PrereqTechName"] = Locale.ConvertTextKey(GameInfo.Technologies[tTable["PrereqTech"]].Description)

				tTable["Gold"] = math.ceil(GameInfo.Units[tTable["UnitType"]].Cost * 7 * iMod)
				
				tTempDecisions[sKey] = {}
				tTempDecisions[sKey].Name = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_SAND_SHIELD", tTable["Name"])
				tTempDecisions[sKey].Desc = Locale.ConvertTextKey("TXT_KEY_DECISIONS_HOMURA_SAND_SHIELD_DESC", tTable["Name"], tTable["PrereqTechName"], tTable["Gold"], tTable["UnitTypeName"])
				tTempDecisions[sKey].Data1 = pCityState
				tTempDecisions[sKey].Data2 = tTable
				tTempDecisions[sKey].Weight = 0
				tTempDecisions[sKey].Type = "Civilization"
				HookDecisionCivilizationIcon(tTempDecisions[sKey], "CIVILIZATION_HOMURA")
				tTempDecisions[sKey].CanFunc = (
				function(pPlayer, pCityState, tTable)
					local iInf = pCityState:GetMinorCivFriendshipWithMajor(pPlayer:GetID());

					if iInf < GameDefines.FRIENDSHIP_THRESHOLD_NEUTRAL then return true, false end

					local pTeamTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()

					if not pTeamTechs:HasTech(tTable.PrereqTech) then return true, false end

					for pUnit in pPlayer:Units() do
						if pUnit:GetPlot():GetOwner() == pCityState:GetID() then
							return true, true
						end
					end

					return true, false
				end
				)
				
				tTempDecisions[sKey].DoFunc = (
				function(pPlayer, pCityState, tTable)
					local pCapital = pPlayer:GetCapitalCity()
					if pCapital then
						pPlayer:ChangeGold(-tTable["Gold"])
						pCityState:ChangeMinorCivFriendshipWithMajor(pPlayer:GetID(), -40)

						local pNewUnit = pPlayer:InitUnit(tTable["UnitType"], pCapital:GetX(), pCapital:GetY(), UNITAI_ATTACK)
						pNewUnit:SetMoves(0)
					end
				end
				)
			end
		end
	end
	)
	
Decisions_AddCivilisationSpecific(GameInfoTypes.CIVILIZATION_HOMURA, "Decisions_HomuraStealWeapons", Decisions_HomuraStealWeapons)

