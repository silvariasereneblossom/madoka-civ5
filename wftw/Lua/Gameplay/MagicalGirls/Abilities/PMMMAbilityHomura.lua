-- PMMMAbilityHomura
-- [port] Phase 4: Homura Akemi's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/Homura.sql.
--------------------------------------------------------------
-- Concentrated Missile Fire. Design: docs/design/phase4-design-v1.md section 3 and the section 12
-- default for "Homura, Missile Fire scaling": one shot mechanically equivalent to a Rocket Artillery
-- attack, its bonus against cities included.
--
-- A fixed 60-strength hit would end any unit before the Industrial era and be a pinprick after it, so
-- the shot is expressed the way every other ability is -- a multiplier on her own strength -- and the
-- multiplier is Rocket Artillery's Ranged Combat Strength divided by the strength of the era's best
-- land unit. Because a Magical Girl is herself a fixed percentage of that same unit, the two era terms
-- cancel and the shell lands at the same strength in every era instead of growing with her.
--------------------------------------------------------------

--Rocket Artillery's own numbers, read from the database rather than written down here, so a balance
--pass on the unit carries into the ability. RangedCombat 60 in CP 5.4.6.
local pRocketArtillery = GameInfo.Units["UNIT_ROCKET_ARTILLERY"]
local iRocketStrength = (pRocketArtillery and pRocketArtillery.RangedCombat) or 60

--Its bonus against cities is not a column on the unit: it comes from PROMOTION_CITY_SIEGE, which
--Rocket Artillery carries for free (Unit_FreePromotions). CityAttack 200 there means +200%, so the
--shot is worth three times as much against a city. Summed over its free promotions in case the kit
--ever grows a second source.
local function GetRocketArtilleryCityAttack()
	local iBonus = 0
	for row in GameInfo.Unit_FreePromotions("UnitType = 'UNIT_ROCKET_ARTILLERY'") do
		local pPromotion = GameInfo.UnitPromotions[row.PromotionType]
		if pPromotion and pPromotion.CityAttack and pPromotion.CityAttack ~= 0 then
			iBonus = iBonus + pPromotion.CityAttack
		end
	end
	return iBonus
end

local iCityAttackBonus = GetRocketArtilleryCityAttack()
local fCitySiegeMultiplier = 1 + (iCityAttackBonus / 100)

--The clamp. Without it the multiplier is 5.5 in the Ancient era (60 against a Spearman's 11) and 0.6
--in the Future era, so an ability meant to be a constant threat would be a guaranteed kill at the
--start of the game and a wasted turn at the end of it. 1.0 is the floor because the shot should never
--be weaker than simply swinging at the target; 2.5 is the ceiling because that is roughly what the
--ratio is worth once the Renaissance arrives, the first era in which a 60-strength hit is not absurd.
local fMinMultiplier = 1.0
local fMaxMultiplier = 2.5

--The strength of the era's strongest ordinary land unit, for this player.
--SetMagicalGirlStrength called without a unit returns only the number: the Magical Girl strength for
--the era this player counts as current, which PMMMDataStorage.lua:321-357 computed by scanning for the
--strongest non-unique Melee or Gunpowder unit of the era and taking MAGICAL_GIRL_STRENGTH_PERCENT of
--it. Dividing that percentage back out recovers the unit's own strength without a second scan, and
--keeps the "maximum met era" rule that the same function applies for traits that have it.
local function GetEraBestLandStrength(iPlayer)
	local iGirlStrength = SetMagicalGirlStrength(iPlayer)
	local iPercent = GameDefines.MAGICAL_GIRL_STRENGTH_PERCENT
	if not iGirlStrength or iGirlStrength <= 0 then return nil end
	if not iPercent or iPercent <= 0 then return nil end
	return (iGirlStrength * 100) / iPercent
end

--Rocket Artillery's strength expressed as a multiple of hers, clamped.
local function GetMissileMultiplier(iPlayer)
	local iBest = GetEraBestLandStrength(iPlayer)
	if not iBest or iBest <= 0 then return fMinMultiplier end
	local fMultiplier = iRocketStrength / iBest
	if fMultiplier < fMinMultiplier then return fMinMultiplier end
	if fMultiplier > fMaxMultiplier then return fMaxMultiplier end
	return fMultiplier
end

--Is there an enemy of this player anywhere on the plot?
--(PMMMLeaderAbilityDefs.lua has the same helper, but it is file-local there and is declared after
--this file is included, so each ability file that needs it keeps its own copy.)
local function PlotHasEnemy(pPlayer, pUnit, pPlot)
	if not pPlot then return false end
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			return true
		end
	end
	if pPlot:IsCity() then
		local pCity = pPlot:GetPlotCity()
		if pCity and pTeam:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then return true end
	end
	return false
end

--The enemy city on this plot, or nil. A city we are not at war with is not a target.
local function GetEnemyCityOnPlot(pPlayer, pPlot)
	if not pPlot or not pPlot:IsCity() then return nil end
	local pCity = pPlot:GetPlotCity()
	if not pCity then return nil end
	if not Teams[pPlayer:GetTeam()]:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then return nil end
	return pCity
end

--------------------------------------------------------------
-- Homura Akemi: Concentrated Missile Fire
-- One shell, on one target, at Rocket Artillery's strength for the era, tripled against a city.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_CONCENTRATED_MISSILE_FIRE", {
	Cooldown = 4,
	--No Soul Gem cost: she empties a shield, not herself.

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local fMultiplier = GetMissileMultiplier(iPlayer)

		--One shell lands on one target. A city on the tile is what the shot hits, the way a real
		--ranged attack aimed at a city tile hits the city and not its garrison, and that is where the
		--siege bonus applies; anywhere else the first visible enemy unit on the tile takes it alone.
		local pCity = GetEnemyCityOnPlot(pPlayer, pPlot)
		if pCity then
			PMMMVirtualAttackCity(pUnit, pCity, fMultiplier * fCitySiegeMultiplier)
		else
			PMMMVirtualAttackPlot(pUnit, pPlot, fMultiplier, true)
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_CONCENTRATED_MISSILE_FIRE"))
		end
	end,

	--Cities first: the siege bonus makes the shot worth three times as much against one, and a city is
	--the only target a single shell cannot be wasted on. Otherwise the ordinary "most and weakest
	--enemies" rule, which for a single-target shot comes down to the softest stack in range.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		if not PlotHasEnemy(pPlayer, pUnit, pPlot) then return nil end
		local pCity = GetEnemyCityOnPlot(pPlayer, pPlot)
		if pCity then
			return 1000 + pCity:GetDamage()
		end
		return PMMMScoreEnemyPlot(pPlayer, pUnit, pPlot)
	end,
})
