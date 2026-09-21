-- Kyouko Trait
-- Author: Vicevirtuoso
-- DateCreated: 6/14/2014 1:56:55 PM
--------------------------------------------------------------


include('PMMMGeneralFunctions.lua');

local iMissionType1 = GameInfoTypes.MISSION_PMMM_KYOUKO_GIVE_FOOD
local iMissionType2 = GameInfoTypes.MISSION_PMMM_KYOUKO_FOOD_HEAL

--[port] Phase 4: Stolen Food is the Chain Lancer's own ability now, not the trait's. The amounts and the cap still
--live on the trait rows (MaxStolenFood, CaravanPillageStolenFood, Trait_PMMM_StolenFoodFromImprovement).
local iChainLancer = GameInfoTypes.UNIT_PMMM_CHAIN_LANCER

local function IsStolenFoodUnit(pUnit)
	return pUnit ~= nil and pUnit:GetUnitType() == iChainLancer
end

function AddStolenFoodFromImprovement(iPlotX, iPlotY, iOwner, iOldImprovement, iNewImprovement, bPillaged)
	if not bPillaged then return end
	dprint("Improvement pillaged")
	local pPlot = Map.GetPlot(iPlotX, iPlotY)
	dprint("Plot pointer at " ..iPlotX.. ", " ..iPlotY)
	if pPlot:IsUnit() then
		dprint("Plot contains unit(s)")
		for i = 0, pPlot:GetNumUnits() - 1 do
			local bBreak
			dprint("Looping through " ..pPlot:GetNumUnits().. " units.")
			local pUnit = pPlot:GetUnit(i)
			--[port] Phase 4: only a Chain Lancer steals Food (was any Melee, Gunpowder, Mounted or Naval Melee unit).
			if IsStolenFoodUnit(pUnit) then
				dprint("Checking a " ..pUnit:GetName().. ".")
				local iUnitOwner = pUnit:GetOwner()
				for k, v in pairs(PMMM.StolenFoodPlots) do
					if v.X == iPlotX and v.Y == iPlotY then
						if iUnitOwner == Game:GetActivePlayer() then
							Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_ALERT_KYOUKO_PILLAGE_STOLEN_FOOD_TOO_SOON", pUnit:GetName()))
						end
						return
					end
				end
				dprint("Owner ID: " ..iUnitOwner)
				local pUnitOwner = Players[iUnitOwner]
				local iUnit = pUnit:GetID()
				if MapModData.gPMMMTraits[iUnitOwner] and MapModData.gPMMMTraits[iUnitOwner].MaxStolenFood > 0 then
					dprint("Max Stolen Food is greater than 0.")
					for k in pairs(MapModData.gPMMMStolenFoodAmounts[iUnitOwner]) do
						dprint("Check improvement type " ..MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].ImprovementType.. " with food value of "..MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].Amount)
						if iNewImprovement == MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].ImprovementType then
							bBreak = true
							dprint("Improvement matches.")
							local iCurFood;
							local iSpecialID = GetUnitSpecialID(iUnitOwner, iUnit)
							if PMMM.StolenFood[iSpecialID] then
								iCurFood = PMMM.StolenFood[iSpecialID]
							else
								iCurFood = 0
							end
							PMMM.StolenFood[iSpecialID] = math.min((iCurFood + MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].Amount), MapModData.gPMMMTraits[iUnitOwner].MaxStolenFood)
							dprint("Current food for unit: " ..PMMM.StolenFood[iSpecialID])
							PMMM.StolenFoodPlots[#PMMM.StolenFoodPlots + 1] = {
								["X"] = iPlotX,
								["Y"] = iPlotY,
								["Turn"] = Game:GetGameTurn()
							}
							if iUnitOwner == Game:GetActivePlayer() then
								Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_ALERT_KYOUKO_PILLAGE_STOLEN_FOOD", pUnit:GetName(), MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].Amount, Locale.ConvertTextKey(GameInfo.Improvements[MapModData.gPMMMStolenFoodAmounts[iUnitOwner][k].ImprovementType].Description)))
							end
							break
						end
					end
				end
			end
			if bBreak then break end
		end
	end
end


function OnKyoukoCustomMission1Possible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	if iPlayer < iMaxCivs then
		if MapModData.gPMMMTraits[iPlayer].MaxStolenFood > 0 then
			local pPlayer = Players[iPlayer]
			local pUnit = pPlayer:GetUnitByID(iUnit)
			--[port] Phase 4: the two Stolen Food missions belong to the Chain Lancer only.
			if not IsStolenFoodUnit(pUnit) then return false end
			local iSpecialID = GetUnitSpecialID(iPlayer, iUnit)
			if PMMM.StolenFood[iSpecialID] then
				if PMMM.StolenFood[iSpecialID] > 0 and iMission == iMissionType1 then
					if pUnit:GetPlot():GetPlotCity() then
						return true
					end
				elseif PMMM.StolenFood[iSpecialID] > 1 and iMission == iMissionType2 then
					if pUnit:GetDamage() > 0 then
						return true
					end
				end
			end
		end
	end
	return false
end

function OnKyoukoCustomMission1Start(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iPlayer < iMaxCivs then
		if MapModData.gPMMMTraits[iPlayer].MaxStolenFood > 0 then
			local pPlayer = Players[iPlayer]
			local pUnit = pPlayer:GetUnitByID(iUnit)
			--[port] Phase 4: the two Stolen Food missions belong to the Chain Lancer only.
			if not IsStolenFoodUnit(pUnit) then return 0 end
			local iSpecialID = GetUnitSpecialID(iPlayer, iUnit)
			if PMMM.StolenFood[iSpecialID] then
				if PMMM.StolenFood[iSpecialID] > 0 and iMission == iMissionType1 then
					if pUnit:GetPlot():GetPlotCity() then
						local pCity = pUnit:GetPlot():GetPlotCity()
						--[port] Phase 6 Lekmod: Unit:AddMessage is CP-only; the wrapper (PMMMGeneralFunctions.lua)
						--calls it natively under CP and falls back to a player AddNotification at the unit's plot.
						PMMMUnitAddMessage(pUnit, Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_GIVE_FOOD", pUnit:GetName(), pCity:GetName(), PMMM.StolenFood[iSpecialID]), iPlayer)
						pCity:ChangeFood(PMMM.StolenFood[iSpecialID])
						PMMM.StolenFood[iSpecialID] = 0
						pUnit:ChangeMoves(-1 * GameDefines.MOVE_DENOMINATOR)
						Events.SerialEventCityInfoDirty.CallImmediate()
					end
				elseif PMMM.StolenFood[iSpecialID] > 1 and iMission == iMissionType2 then
					if pUnit:GetDamage() > 0 then
						local iCurDamage = pUnit:GetDamage()
						local iMaxHeal = math.floor(PMMM.StolenFood[iSpecialID] / 2)
						local iActualHeal = math.min(iCurDamage, iMaxHeal)
						local iRemovedFood = iActualHeal * 2
						PMMMUnitAddMessage(pUnit, Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_FOOD_HEAL", pUnit:GetName(), iActualHeal), iPlayer)
						PMMM.StolenFood[iSpecialID] = math.max(PMMM.StolenFood[iSpecialID] - iRemovedFood, 0)
						pUnit:ChangeDamage(-1 * iActualHeal)
						pUnit:ChangeMoves(-1 * GameDefines.MOVE_DENOMINATOR)
					end
				end
			end
		end
	end
	return 0
end

function OnKyoukoCustomMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iMission == iMissionType1 or iMission == iMissionType2 then
		return true
	end
	return false
end


function AddStolenFoodFromSacking(iPlayer, iUnit)
	if iPlayer < iMaxCivs and MapModData.gPMMMTraits[iPlayer].CaravanPillageStolenFood > 0 then
		dprint("A trade route was pillaged by a Civ which gets Stolen Food from doing so.")
		local pPlayer = Players[iPlayer]
		local pUnit = pPlayer:GetUnitByID(iUnit)
		--[port] Phase 4: only a Chain Lancer steals Food from a plundered Trade Route.
		if not IsStolenFoodUnit(pUnit) then return end
		local iCurFood;
		local iSpecialID = GetUnitSpecialID(iPlayer, iUnit)
		if PMMM.StolenFood[iSpecialID] then
			iCurFood = PMMM.StolenFood[iSpecialID]
		else
			iCurFood = 0
		end
		PMMM.StolenFood[iSpecialID] = math.min((iCurFood + MapModData.gPMMMTraits[iPlayer].CaravanPillageStolenFood), MapModData.gPMMMTraits[iPlayer].MaxStolenFood)
		dprint("Current food for unit: " ..PMMM.StolenFood[iSpecialID])
		--[port] Phase 6 Lekmod: Unit:AddMessage is CP-only; wrapper (PMMMGeneralFunctions.lua). This site
		--passed no player, so the fallback addresses the unit's owner, as the CP path effectively did.
		PMMMUnitAddMessage(pUnit, Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_KYOUKO_CARAVAN_SACK", pUnit:GetName(), MapModData.gPMMMTraits[iPlayer].CaravanPillageStolenFood))
	end
end


function AIStolenFoodCheck(iPlayer)
	local pPlayer = Players[iPlayer]
	for pUnit in pPlayer:Units() do
		--[port] Phase 4: Stolen Food and the forced pillage are Chain Lancer behaviour only; every other unit is left
		--to the normal AI (the old override popped the missions of any damaged Kyouko unit that could pillage).
		if IsStolenFoodUnit(pUnit) then
			local iSpecialID = GetUnitSpecialID(iPlayer, pUnit:GetID())
			local iFood = PMMM.StolenFood[iSpecialID] or 0
			--[port] Phase 4: both uses now need Food in the bag; an empty entry used to cost the unit a move every turn.
			if iFood > 0 then
				--Use it only if the unit is at half health or lower. This will be prioritized over dropping the food in the City.
				if pUnit:GetDamage() >= 50 and iFood > 1 then
					local iCurDamage = pUnit:GetDamage()
					local iMaxHeal = math.floor(iFood / 2)
					local iActualHeal = math.min(iCurDamage, iMaxHeal)
					local iRemovedFood = iActualHeal * 2
					PMMM.StolenFood[iSpecialID] = math.max(iFood - iRemovedFood, 0)
					pUnit:ChangeDamage(-1 * iActualHeal)
					pUnit:ChangeMoves(-1 * GameDefines.MOVE_DENOMINATOR)
				--If unit is above half health and in one of its own cities, dump the food in it
				elseif pUnit:GetPlot():GetPlotCity() and pUnit:GetPlot():GetPlotCity():GetOwner() == iPlayer then
					local pCity = pUnit:GetPlot():GetPlotCity()
					pCity:ChangeFood(iFood)
					PMMM.StolenFood[iSpecialID] = 0
					pUnit:ChangeMoves(-1 * GameDefines.MOVE_DENOMINATOR)
				end
			end

			--v19: Force Kyouko's AI to pillage if it has sustained at least 25 damage
			--[port] Phase 4: Chain Lancers only.
			if pUnit:CanStartMission(GameInfoTypes.MISSION_PILLAGE) and pUnit:GetDamage() >= 25 then
				pUnit:PopMission()
				pUnit:PushMission(GameInfoTypes.MISSION_PILLAGE)
			end
		end
	end
end


--[port] PMMM.StolenFood is keyed by "owner:unit" and unit IDs are recycled; drop the entry
--when the unit dies so a later unit does not inherit its stolen food
function ClearStolenFoodOnDeath(iPlayer, iUnit)
	PMMM.StolenFood[GetUnitSpecialID(iPlayer, iUnit)] = nil
end


--v19: Upkeep on recently pillaged plots
function OnDoTurnStolenFoodPillageUpkeep(iPlayer)
	--[port] was gated on iPlayer == 0, which never fires if player 0 is not in the game;
	--run the sweep once per game turn instead, keyed on a persisted last-swept turn
	local iTurn = Game:GetGameTurn()
	if PMMM.StolenFoodPlotsLastSweptTurn == iTurn then return end
	PMMM.StolenFoodPlotsLastSweptTurn = iTurn
	local tToRemove = {}
	for k, v in pairs(PMMM.StolenFoodPlots) do
		--[port] comparison was inverted: entries were dropped while still on cooldown and kept once it expired
		if v.Turn + GameDefines.STOLEN_FOOD_SAME_TILE_TURNS_BETWEEN <= iTurn then
			tToRemove[k] = true
		end
	end
	for i = #PMMM.StolenFoodPlots, 1, -1 do
		if tToRemove[i] then
			table.remove(PMMM.StolenFoodPlots, i)
		end
	end
end


--------------------------------------------------------------
--[port] Phase 4: "I Live Only For Myself", the Lua halves.
-- Data half: SQL/Phase4/Kyouko.sql blocks 2, 7 and 9. Both parts key on the trait, not the civilization, so the
-- rules follow TRAIT_GROWTH_SPEED_FROM_RELIGION wherever it is attached.
--------------------------------------------------------------
local sKyoukoTrait = "TRAIT_GROWTH_SPEED_FROM_RELIGION"
local iKyoukoLuxuryPolicy = GameInfoTypes.POLICY_PMMM_KYOUKO_LUXURIES
local iKyoukoTradedLuxuryDummy = GameInfoTypes.BUILDING_PMMM_KYOUKO_TRADED_LUXURY
--The policy's bonus is read from its row so the cancellation below cannot drift from the data.
local iKyoukoPolicyBonus = (GameInfo.Policies.POLICY_PMMM_KYOUKO_LUXURIES and GameInfo.Policies.POLICY_PMMM_KYOUKO_LUXURIES.ExtraHappinessPerLuxury) or 0
--The ruling itself: a luxury she only has through a trade deal gives 1 less Happiness than usual.
local iKyoukoTradedLuxuryPenalty = 1

local function IsKyoukoTraitPlayer(iPlayer)
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	return tTrait ~= nil and tTrait.Type == sKyoukoTrait
end

--[port] Phase 4: she can never found a religion. CvUnit::CanFoundReligion asks this event (TestAll) before any
--Great Prophet may found one, for the human UI and the AI alike, so refusing here blocks every founding path.
--Her free pantheon (Traits.StartsWithPantheon) is untouched: pantheons are not founded through this check.
--[port] Phase 6 Lekmod (lekmod-scope-engine.md §7.4): that free pantheon is INERT DATA on Lekmod -- its DLL
--never reads Traits.StartsWithPantheon, so Kyouko starts with no pantheon there. No Lua fix can grant one
--without inventing a replacement mechanic; this is a known, silently-degrading behaviour difference, not a bug
--in this file. Restoring it belongs to the DLL side (if ever), not to the compatibility layer.
function KyoukoCanFoundReligion(iPlayer, iCity)
	if IsKyoukoTraitPlayer(iPlayer) then
		return false
	end
	return true
end
GameEvents.PlayerCanFoundReligion.Add(KyoukoCanFoundReligion)

--Put exactly iCount copies of a stacking dummy in the capital, and none anywhere else (the capital can move).
local function SetKyoukoCapitalDummy(pPlayer, iBuilding, iCount)
	local pCapital = pPlayer:GetCapitalCity()
	local iCapitalID = pCapital and pCapital:GetID() or -1
	for pCity in pPlayer:Cities() do
		if pCity:GetID() ~= iCapitalID and pCity:GetNumRealBuilding(iBuilding) > 0 then
			pCity:SetNumRealBuilding(iBuilding, 0)
		end
	end
	if pCapital and pCapital:GetNumRealBuilding(iBuilding) ~= iCount then
		pCapital:SetNumRealBuilding(iBuilding, iCount)
	end
end

--How many luxuries does she hold only through deals with other civilizations?
--  deal copies = GetResourceImport (deals + city-states + siphoned) minus GetResourceFromMinors.
--  "only through trade" = the luxury currently gives Happiness, and would not without those deal copies.
--Reading (spec section 12): "traded" means imported through deals; exports are unaffected and city-state
--luxuries count as her own. Siphoned copies cannot be separated from Lua and count as deal copies; no civ in
--this mod siphons resources.
local function CountKyoukoDealOnlyLuxuries(pPlayer)
	local iCount = 0
	for pResource in GameInfo.Resources() do
		if pResource.ResourceUsage == 2 then --RESOURCEUSAGE_LUXURY
			local iResource = pResource.ID
			local iDeal = pPlayer:GetResourceImport(iResource) - pPlayer:GetResourceFromMinors(iResource)
			if iDeal > 0 and pPlayer:GetHappinessFromLuxury(iResource) > 0 then
				if pPlayer:GetNumResourceAvailable(iResource, true) - iDeal <= 0 then
					iCount = iCount + 1
				end
			end
		end
	end
	return iCount
end

--[port] Phase 4: once per turn. Grants the hidden +2-per-luxury policy (free, first turn, idempotent) and
--recounts deal-only luxuries into the capital dummy: 3 copies each, -2 to cancel the policy's bonus on that
--luxury (the DLL adds ExtraHappinessPerLuxury to imports too) and -1 for the penalty. Net: owned 4+2 = 6,
--deal-only 4+2-3 = 3.
function KyoukoLuxuryDoTurn(iPlayer)
	if not IsKyoukoTraitPlayer(iPlayer) then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end
	if iKyoukoLuxuryPolicy and not pPlayer:HasPolicy(iKyoukoLuxuryPolicy) then
		pPlayer:SetHasPolicy(iKyoukoLuxuryPolicy, true, true)
	end
	if iKyoukoTradedLuxuryDummy then
		local iCopies = CountKyoukoDealOnlyLuxuries(pPlayer) * (iKyoukoPolicyBonus + iKyoukoTradedLuxuryPenalty)
		SetKyoukoCapitalDummy(pPlayer, iKyoukoTradedLuxuryDummy, iCopies)
	end
end
GameEvents.PlayerDoTurn.Add(KyoukoLuxuryDoTurn)
