-- PMMMClaraDoll
-- Author: Vicevirtuoso
-- DateCreated: 7/2/2014 2:04:52 PM
--------------------------------------------------------------

--[port] Phase 4: the Clara Doll is now Devil Homura's Swordsman (16 strength, 2 moves) and earns the
--Magical Girl promotion tree from XP (Units.PromotionClass = UNITCOMBAT_MAGICALGIRL, set in
--SQL/Phase4/DemonHomura.sql; its CombatClass stays UNITCOMBAT_MELEE). Its old same-tile aura
--(PROMOTION_PMMM_CLARA_DOLL granting +50% vs. Magical Girls) is removed, so no row is left in
--Promotion_PMMM_GrantAdjacentAllyPromotion.
--
--ClaraDoll() below is the generic driver for that table and is still called by PMMMUUBootstrapper on
--every move and every turn; it now returns at once while the table is empty.


--[port] Phase 4: six promotions in the Magical Girl tree only act on the Magical Girl social systems
--(sparring, socializing, Likes/Dislikes, Loyalty) and do nothing on any other unit. The Clara Doll
--shares the tree, so hide these six from every unit that is not a Magical Girl. CanHavePromotion is
--raised by CvUnit::canAcquirePromotion in both DLL builds (as GameEvents.CanHavePromotion with
--MOD_EVENTS_UNIT_UPGRADES, as the legacy "CanHavePromotion" script call without it), signature
--(iPlayer, iUnit, iPromotion), TESTALL: returning false removes the choice.
local iClaraMagicalGirlType = GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL
local tMagicalGirlOnlyPromotions = {}
for _, sPromotion in ipairs({"PROMOTION_PMMM_CHARISMA_I", "PROMOTION_PMMM_CHARISMA_II", "PROMOTION_PMMM_PATRIOTISM",
		"PROMOTION_PMMM_TRAINER_I", "PROMOTION_PMMM_TRAINER_II", "PROMOTION_PMMM_TEACHER"}) do
	local iPromotion = GameInfoTypes[sPromotion]
	if iPromotion then tMagicalGirlOnlyPromotions[iPromotion] = true end
end

function ClaraDollCanHavePromotion(iPlayer, iUnit, iPromotion)
	if not tMagicalGirlOnlyPromotions[iPromotion] then return true end
	local pPlayer = Players[iPlayer]
	if not pPlayer then return true end
	local pUnit = pPlayer:GetUnitByID(iUnit)
	if pUnit and pUnit:GetUnitType() ~= iClaraMagicalGirlType then
		return false
	end
	return true
end
GameEvents.CanHavePromotion.Add(ClaraDollCanHavePromotion)


--[port] 2026-09-22 ruling: a Clara Doll gains +2 [ICON_STRENGTH] Combat Strength per era, and keeps doing so on
--whatever chassis it upgrades into: the identity promotion PROMOTION_PMMM_CLARA_DOLL survives upgrades and the
--DLLs let a tagged unit pick Magical Girl promotions on any chassis (SQL/Phase4/DemonHomura.sql explains both
--halves). The unit is also never obsolete, so a fresh Swordsman-tier doll can be built in any era.
local iPMMMClaraDollTag = GameInfoTypes.PROMOTION_PMMM_CLARA_DOLL
local iPMMMClaraDollStrengthPerEra = 2
local tPMMMChassisCombat = {}	-- unit type -> its database Combat, looked up once

function SetClaraDollStrength(iPlayer, pUnit)
	if not iPMMMClaraDollTag or not pUnit or not pUnit:IsHasPromotion(iPMMMClaraDollTag) then return end
	local iType = pUnit:GetUnitType()
	if tPMMMChassisCombat[iType] == nil then
		local pInfo = GameInfo.Units[iType]
		tPMMMChassisCombat[iType] = (pInfo and pInfo.Combat) or 0
	end
	local iBase = tPMMMChassisCombat[iType]
	if iBase <= 0 then return end
	local iTarget = iBase + iPMMMClaraDollStrengthPerEra * Players[iPlayer]:GetCurrentEra()
	if pUnit:GetBaseCombatStrength() ~= iTarget then
		pUnit:SetBaseCombatStrength(iTarget)
	end
end


function ClaraDoll(iPlayer, iUnit, bTestAllAllies)
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
	if not pUnit then return end
	SetClaraDollStrength(iPlayer, pUnit)

	--[port] Phase 4: nothing grants an adjacent-ally buff any more; skip the per-unit sweep entirely.
	if not MapModData.gPMMMAdjacentAllyBuffs or next(MapModData.gPMMMAdjacentAllyBuffs) == nil then return end
	dprint("Running ClaraDoll function.")
	-- Supposed to use the much faster CP methods, but they cause crashes, so let's not!
	-- for k, v in pairs(MapModData.gPMMMAdjacentAllyBuffs) do
		-- pUnit:SetHasPromotion(v.NewPromotionType, pUnit:IsWithinDistanceOfUnitPromotion(k, v.Radius, true, false))
	-- end
	if bTestAllAllies then
		for pAllyUnit in pPlayer:Units() do
			for k, v in pairs(MapModData.gPMMMAdjacentAllyBuffs) do
				local bThisUnitStaysBuffed = ClaraDollLoopTest(k, v.Radius, pPlayer, pAllyUnit, pAllyUnit:GetPlot())
				if bThisUnitStaysBuffed then
					pAllyUnit:SetHasPromotion(v.NewPromotionType, true)
					dprint("Unit buffed")
				else
					pAllyUnit:SetHasPromotion(v.NewPromotionType, false)
					dprint("Unit not buffed")
				end
			end
		end
	else
		for k, v in pairs(MapModData.gPMMMAdjacentAllyBuffs) do
			local bThisUnitStaysBuffed = ClaraDollLoopTest(k, v.Radius, pPlayer, pUnit, pUnit:GetPlot())
			if bThisUnitStaysBuffed then
				pUnit:SetHasPromotion(v.NewPromotionType, true)
				dprint("Unit buffed")
			else
				pUnit:SetHasPromotion(v.NewPromotionType, false)
				dprint("Unit not buffed")
			end
		end
	end
end


function ClaraDollLoopTest(iBuffPromo, iRadius, pPlayer, pUnit, pPlot)
	dprint("New test loop")
	if pPlot then
		for c = 0, pPlot:GetNumUnits() - 1 do
			local pPlotUnit = pPlot:GetUnit(c)
			if pPlotUnit and pPlotUnit ~= pUnit then
				if pPlotUnit:GetOwner() == pPlayer:GetID() and pPlotUnit:IsHasPromotion(iBuffPromo) then
					dprint("Found an allied unit with the buff promotion.")
					return true
				end
			end
		end
		if iRadius > 0 then
			for pAreaPlot in PlotAreaSpiralIterator(pPlot, iRadius, 1, true, true, false) do
				dprint("Testing units on plot at " ..pAreaPlot:GetX().. ", " ..pAreaPlot:GetY())
				if pAreaPlot:IsUnit() then
					for c = 0, pAreaPlot:GetNumUnits() - 1 do
						local pPlotUnit = pAreaPlot:GetUnit(c)
						if pPlotUnit then
							if pPlotUnit:GetOwner() == pPlayer:GetID() and pPlotUnit:IsHasPromotion(iBuffPromo) then
								dprint("Found an allied unit with the buff promotion.")
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end