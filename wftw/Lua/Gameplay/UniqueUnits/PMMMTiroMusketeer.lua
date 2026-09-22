-- Tiro Musketeer
-- Author: Vicevirtuoso
-- DateCreated: 6/19/2014 7:06:29 PM
--------------------------------------------------------------
--[port] Phase 4: Tiro Siege replaces the unit's old Tiro Finale (spec section 7, section 12 default).
-- Data half: SQL/Phase4/Mami.sql block 7.
--
-- Every unit carrying PROMOTION_PMMM_TIRO_MUSKETEER may, once per turn, fire a free shot at an enemy City within
-- 2 tiles. It is a virtual attack at a Cannon's strength against Cities (UNIT_CANNON's RangedCombat raised by the
-- CityAttack of its free promotions: 20 x (100 + 200)% = 60 in CP 5.4.6), scaled by the promotion's
-- TiroFinaleStrength, which now means "percent of that Cannon shot" (100). Damage comes from
-- GetMeleeCombatDamageCity (GetCombatDamage is a stub in this DLL). It spends no movement and does not use the
-- unit's attack, takes no counter-damage, and cannot take a City below 1 HP. The unit needs movement left to act
-- at all (the DLL only starts missions for units that can move), so fire before attacking.
--
-- The 150% area shot (Tiro Finale) now belongs to Mami's Leader Magical Girl alone, as
-- MISSION_PMMM_TIRO_FINALE_MG in PMMMLeaderAbilityDefs.lua. The unit mission row MISSION_PMMM_TIRO_FINALE is
-- repurposed as Tiro Siege (kept, not replaced, so no Missions ID moves) and nothing here can hit units any more.
-- PROMOTION_PMMM_TIRO_MUSKETEER_DEBUFF is repurposed as the "already fired this turn" marker (DefenseMod 0).
--------------------------------------------------------------

local iPromotion = GameInfoTypes.PROMOTION_PMMM_TIRO_MUSKETEER
local iSpentPromotion = GameInfoTypes.PROMOTION_PMMM_TIRO_MUSKETEER_DEBUFF
local iMissionType = GameInfoTypes.MISSION_PMMM_TIRO_FINALE

local pSiegeMission = GameInfo.Missions.MISSION_PMMM_TIRO_FINALE
local iSiegeRange = (pSiegeMission and pSiegeMission.PMMMMissionRange) or 2

--A Cannon's ranged strength against a City, times 100 (the scale GetMeleeCombatDamageCity and city strength use).
local function GetTiroSiegeStrengthTimes100()
	local pCannon = GameInfo.Units.UNIT_CANNON
	if not pCannon then return 0 end
	local iCityAttack = 0
	for row in GameInfo.Unit_FreePromotions("UnitType = 'UNIT_CANNON'") do
		local pPromo = GameInfo.UnitPromotions[row.PromotionType]
		if pPromo and pPromo.CityAttack then
			iCityAttack = iCityAttack + pPromo.CityAttack
		end
	end
	local iPercent = 100
	-- [port] DB.Query, not GameInfo: on Lekmod GameInfo.UnitPromotions does not expose WFTW's own columns (2026-09-21).
	local pTiroPromo
	for row in DB.Query("SELECT TiroFinaleStrength FROM UnitPromotions WHERE Type = 'PROMOTION_PMMM_TIRO_MUSKETEER'") do pTiroPromo = row end
	if pTiroPromo and pTiroPromo.TiroFinaleStrength and pTiroPromo.TiroFinaleStrength > 0 then
		iPercent = pTiroPromo.TiroFinaleStrength
	end
	return math.floor(pCannon.RangedCombat * (100 + iCityAttack) * iPercent / 100)
end
local iSiegeStrengthTimes100 = GetTiroSiegeStrengthTimes100()

--Is pPlot a City this unit may shell right now? Returns the City or nil.
--Distance only, no line of sight: the target is a City, which is always a revealed tile of its own.
local function GetTiroSiegeTarget(pUnit, pPlot)
	if not pUnit or not pPlot or not pPlot:IsCity() then return nil end
	local pCity = pPlot:GetPlotCity()
	if not pCity then return nil end
	local pOwner = Players[pUnit:GetOwner()]
	local iTeam = pOwner:GetTeam()
	if not Teams[iTeam]:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then return nil end
	if not pPlot:IsVisible(iTeam, false) then return nil end
	if Map.PlotDistance(pUnit:GetX(), pUnit:GetY(), pPlot:GetX(), pPlot:GetY()) > iSiegeRange then return nil end
	--Nothing left to knock off: the shot can never take a City below 1 HP.
	if pCity:GetDamage() >= pCity:GetMaxHitPoints() - 1 then return nil end
	return pCity
end

local function CanFireTiroSiege(pUnit)
	return pUnit ~= nil and iPromotion ~= nil and iSpentPromotion ~= nil
		and pUnit:IsHasPromotion(iPromotion) and not pUnit:IsHasPromotion(iSpentPromotion)
end

--Every enemy City this unit could shell from where it stands, in a fixed spiral order.
local function GetTiroSiegeTargets(pUnit)
	local tCities = {}
	for pAreaPlot in PlotAreaSpiralIterator(pUnit:GetPlot(), iSiegeRange, 1, false, false, false) do
		local pCity = GetTiroSiegeTarget(pUnit, pAreaPlot)
		if pCity then tCities[#tCities + 1] = pCity end
	end
	return tCities
end

--The shot itself. Returns the damage dealt (0 if the shot was not allowed).
function DoTiroSiege(iPlayer, pUnit, pPlot)
	if not pUnit or pUnit:GetOwner() ~= iPlayer or not CanFireTiroSiege(pUnit) then return 0 end
	local pCity = GetTiroSiegeTarget(pUnit, pPlot)
	if not pCity then return 0 end

	--[port] Phase 6 Lekmod: through the framework wrapper (PMMMLeaderAbilities.lua) -- CP's bound
	--GetMeleeCombatDamageCity under CP, the vanilla melee-vs-city formula in Lua under a DLL without it.
	local iDamage = PMMMGetMeleeCombatDamageCity(pUnit, iSiegeStrengthTimes100, pCity)
	if not iDamage or iDamage < 0 then iDamage = 0 end
	local iRoom = pCity:GetMaxHitPoints() - pCity:GetDamage() - 1
	if iDamage > iRoom then iDamage = math.max(iRoom, 0) end
	if iDamage > 0 then
		pCity:ChangeDamage(iDamage)
	end

	--Once per turn: the marker is cleared at the start of the owner's next turn (RemoveDefenseDebuff below).
	pUnit:SetHasPromotion(iSpentPromotion, true)

	if iPlayer == Game:GetActivePlayer() then
		Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_ALERT_PMMM_TIRO_SIEGE", pUnit:GetName(), pCity:GetName(), iDamage))
	end
	return iDamage
end

--Kept for MagicalGirlMissionHandler.ExecuteMapClickCustomMission, a deprecated path nothing calls any more.
--It now fires Tiro Siege, with all of Tiro Siege's checks; the old 150% area shot is gone from this unit.
function DoTiroFinale(iPlayer, pUnit, pPlot)
	return DoTiroSiege(iPlayer, pUnit, pPlot)
end

function TiroFinaleCustomMissionPossible(iPlayer, iUnit, iMission, iData1, iData2, _, _, iPlotX, iPlotY, bTestVisible)
	if iMission ~= iMissionType then return false end
	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer and pPlayer:GetUnitByID(iUnit)
	if not pUnit or not pUnit:IsHasPromotion(iPromotion) then return false end
	if bTestVisible then return true end
	if not CanFireTiroSiege(pUnit) then return false end
	if pUnit:GetMoves() <= 0 then return false end
	--The DLL passes the unit's own plot here, not the target, so enable the button when any target is in range;
	--the start handler checks the chosen target.
	return #GetTiroSiegeTargets(pUnit) > 0
end

function TiroFinaleCustomMissionStart(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iMission == iMissionType then
		--[port] iData1/iData2 arrive unary-negated (see the InputHandler in PMMMWishForTheWorldMain);
		--validate them and the plot before use
		local iX, iY = -iData1, -iData2
		if iX >= 0 and iY >= 0 then
			local pPlot = Map.GetPlot(iX, iY)
			local pUnit = Players[iPlayer]:GetUnitByID(iUnit)
			if pPlot and pUnit then
				DoTiroSiege(iPlayer, pUnit, pPlot)
			end
		end
	end
	return 0
end

function TiroFinaleCustomMissionCompleted(iPlayer, iUnit, iMission, iData1, iData2, iFlags, iTurn)
	if iMission == iMissionType then
		return true
	end
	return false
end

--AI rule: fire at the enemy City in range that is closest to falling (most damage already taken), first found
--on ties. The shot is free, so there is no reason to hold it.
local function RunTiroSiegeAI(iPlayer, pUnit)
	local pBest, iBestDamage
	for _, pCity in ipairs(GetTiroSiegeTargets(pUnit)) do
		local iCityDamage = pCity:GetDamage()
		if not iBestDamage or iCityDamage > iBestDamage then
			pBest, iBestDamage = pCity, iCityDamage
		end
	end
	if pBest then
		DoTiroSiege(iPlayer, pUnit, pBest:Plot())
	end
end

--Runs at the start of each player's turn (PMMMUUBootstrapper.OnDoTurnUUFunctions). The name is kept for that
--caller. It clears last turn's "fired" marker, then lets AI Musketeers fire.
--[port] Phase 4: the old AI fired the area shot here and then set the unit's moves to 0, freezing it for the
--whole turn. Tiro Siege never touches movement, so the unit goes on to move and attack normally.
function RemoveDefenseDebuff(iPlayer)
	if iPlayer < iMaxCivsAndCS then
		local pPlayer = Players[iPlayer]
		if not pPlayer or not pPlayer:IsAlive() then return end
		local bAI = not pPlayer:IsHuman()
		for pUnit in pPlayer:Units() do
			if iSpentPromotion and pUnit:IsHasPromotion(iSpentPromotion) then
				pUnit:SetHasPromotion(iSpentPromotion, false)
			end
			if bAI and CanFireTiroSiege(pUnit) then
				RunTiroSiegeAI(iPlayer, pUnit)
			end
		end
	end
end
