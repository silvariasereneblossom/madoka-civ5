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
-- [port] Phase 4: own cooldown counters for Homura's two abilities
--------------------------------------------------------------
-- Each ability keeps its own counter here -- the missile on the girl (MagicalGirls[key].MissileFireCooldown),
-- Time Stop on the player (PMMM.TimeStopCooldown[player], which the decision "Draw Mana Into Your Shield"
-- also reads) -- because Time Stop's recovery has rules the framework does not model: a Grief Seed takes a
-- turn off, and it can never come back sooner than 5 turns after use. Both definitions register Cooldown = 0,
-- which the framework now treats as "no framework cooldown" (cooldowns are per ability, and zero stays zero),
-- so the two abilities no longer block each other.
-- Both counters tick in PMMMHomuraDoTurn at the bottom of this file, which is registered on PlayerDoTurn
-- before the framework's own handler (this file is included first), so the AI sees a counter that has
-- already ticked for the turn.
local iMissileFireCooldown = 4

local function GetMissileFireCooldown(iMGKey)
	local tGirl = iMGKey and MagicalGirls[iMGKey]
	return (tGirl and tGirl.MissileFireCooldown) or 0
end

--------------------------------------------------------------
-- Homura Akemi: Concentrated Missile Fire
-- One shell, on one target, at Rocket Artillery's strength for the era, tripled against a city.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_CONCENTRATED_MISSILE_FIRE", {
	--[port] Phase 4: the real 4-turn cooldown is MagicalGirls[key].MissileFireCooldown (see above); 0 here
	--keeps the framework's shared per-girl counter from also locking Time Stop for 4 turns.
	Cooldown = 0,
	--No Soul Gem cost: she empties a shield, not herself.

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		if GetMissileFireCooldown(iMGKey) > 0 then return false end
		return PlotHasEnemy(pPlayer, pUnit, pPlot)
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local fMultiplier = GetMissileMultiplier(iPlayer)
		--[port] Phase 4: the missile's own cooldown, scaled by game speed exactly as the framework scales.
		if iMGKey and MagicalGirls[iMGKey] then
			MagicalGirls[iMGKey].MissileFireCooldown = GetScaledAbilityCooldown(iMissileFireCooldown)
		end

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
		--[port] Phase 4: the missile's own cooldown (the scorer is not handed the girl's key).
		if GetMissileFireCooldown(GetMagicalGirlKey(pPlayer:GetID(), pUnit:GetID())) > 0 then return nil end
		if not PlotHasEnemy(pPlayer, pUnit, pPlot) then return nil end
		local pCity = GetEnemyCityOnPlot(pPlayer, pPlot)
		if pCity then
			return 1000 + pCity:GetDamage()
		end
		return PMMMScoreEnemyPlot(pPlayer, pUnit, pPlot)
	end,
})


--------------------------------------------------------------
-- [port] Phase 4: the rest of Homura's kit -- Time Stop and the Thief of Time.
-- Design: docs/design/phase4-design-v1.md section 3; section 11 ruling 5 (Time Stop is a mission on her
-- leader girl, and the free turn includes Great Person points, tourism and healing); section 12 defaults for
-- the Thief of Time (10% of a random researchable tech) and the Grief Seed reduction (-1 per seed, floor 5).
-- Data half: SQL/Phase4/Homura.sql.
--------------------------------------------------------------

local sHomuraTrait = "TRAIT_STEAL_ENEMY_UNIQUE_ON_CONQUEST"
local iMaxMajorCivs = GameDefines.MAX_MAJOR_CIVS

--Time Stop numbers. Turn counts are Standard-speed values and go through GetScaledAbilityCooldown, as
--every other leader ability's cooldown does.
local iTimeStopCooldown = 20		--turns
local iTimeStopFloor = 5			--Grief Seeds never shorten it below this many turns after the use
local iStoppedTimeAttack = GameInfoTypes.PROMOTION_PMMM_STOPPED_TIME_ATTACK	--ExtraAttacks 1

--AI rule numbers (the prompt's rule, written down once).
local iAIWarUnitsNeeded = 3			--at war: this many combat units ...
local iAIWarRange = 3				--... within this many tiles of an enemy

--Thief of Time numbers.
local iThiefOfTime = GameInfoTypes.UNIT_PMMM_CLOCKSTOPPER
local iThiefTurnsPerTrigger = 3		--every 3rd turn begun in a rival major civ's borders
local iThiefTechPercent = 10		--percent of the chosen tech's research cost

--Basic healing rates, from the database (CP 5.4.6: city 25, friendly 20, neutral 10, enemy 10).
local iCityHealRate = GameDefines.CITY_HEAL_RATE or 25
local iFriendlyHealRate = GameDefines.FRIENDLY_HEAL_RATE or 20
local iNeutralHealRate = GameDefines.NEUTRAL_HEAL_RATE or 10
local iEnemyHealRate = GameDefines.ENEMY_HEAL_RATE or 10

--Promotions that forbid healing (CannotHeal). A unit carrying one gets no free-turn healing either.
local tCannotHealPromotions = {}
for row in GameInfo.UnitPromotions() do
	if row.CannotHeal == true or row.CannotHeal == 1 then
		tCannotHealPromotions[#tCannotHealPromotions + 1] = row.ID
	end
end

--Every technology ID in ascending order, so the Thief's candidate list is built in a fixed order on every
--machine before Game.Rand picks from it.
local tAllTechIDs = {}
for row in GameInfo.Technologies() do
	tAllTechIDs[#tAllTechIDs + 1] = row.ID
end
table.sort(tAllTechIDs)

local function IsHomuraPlayer(iPlayer)
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer]
	return tTrait ~= nil and tTrait.Type == sHomuraTrait
end

--------------------------------------------------------------
-- Time Stop cooldown
-- PMMM.TimeStopCooldown[player] is the single source of truth. The UnitPanel tooltip for
-- MISSION_PMMM_TIME_STOP reads it, and the "Draw Mana Into Your Shield" decision (DecisionsMod/Lua/
-- PMMMHomuraDecisions.lua) is enactable while it is above zero and takes 10 turns off it; because nothing
-- else keeps a second copy, the decision's cut simply stands. The framework's per-girl counter is left at
-- its 1-turn minimum (see the note above Concentrated Missile Fire).
--------------------------------------------------------------
local function GetTimeStopCooldown(iPlayer)
	return (PMMM.TimeStopCooldown and PMMM.TimeStopCooldown[iPlayer]) or 0
end

local function SetTimeStopCooldown(iPlayer, iTurns)
	PMMM.TimeStopCooldown = PMMM.TimeStopCooldown or {}
	PMMM.TimeStopCooldown[iPlayer] = math.max(iTurns, 0)
end

--The most recent game turn on which one of this player's girls stopped time, or nil.
--Kept per girl (MagicalGirls[key].TimeStopUsedTurn) because a new persisted per-player table would have
--to be declared in PMMMDefines.lua.
local function GetTimeStopUsedTurn(iPlayer)
	local iLatest
	for _, tGirl in pairs(MagicalGirls) do
		if tGirl.Owner == iPlayer and tGirl.TimeStopUsedTurn then
			if not iLatest or tGirl.TimeStopUsedTurn > iLatest then iLatest = tGirl.TimeStopUsedTurn end
		end
	end
	return iLatest
end

--tPMMMGriefSeedUsedHooks: any of the player's girls using a Grief Seed takes 1 turn off a running Time Stop
--cooldown. Reading of "never below 5": the seeds can never make Time Stop usable sooner than 5 turns
--(scaled) after the turn it was used, so a seed that would cut below that line is capped at it (and a
--cooldown already below the line -- from ticking down, or from the decision -- is left alone). With no
--recorded use (its girl gone) only the plain 1-turn cut applies.
function PMMMHomuraTimeStopGriefSeedUsed(iPlayer, iMGKey)
	if not IsHomuraPlayer(iPlayer) then return end
	local iCooldown = GetTimeStopCooldown(iPlayer)
	if iCooldown <= 0 then return end
	local iNew = iCooldown - 1
	local iUsedTurn = GetTimeStopUsedTurn(iPlayer)
	if iUsedTurn then
		local iFloorLeft = GetScaledAbilityCooldown(iTimeStopFloor) - (Game.GetGameTurn() - iUsedTurn)
		if iNew < iFloorLeft then
			iNew = math.min(iCooldown, iFloorLeft)
		end
	end
	SetTimeStopCooldown(iPlayer, iNew)
end

--------------------------------------------------------------
-- The free turn. Each piece takes the engine's own per-turn value where the Lua API offers one; where it
-- does not, the approximation is commented and always errs low.
--------------------------------------------------------------

--Set by the Time Stop AI scorer just before the framework's AI calls Execute (RunLeaderAbilityAI calls the
--scorer and then Execute at once, at the start of the AI's turn). Execute uses it to know that the workers
--have not yet worked this turn.
local bTimeStopFiredByAI = false

--One extra attack this turn for every unit that can attack. PMMMApplyTimedPromotion with 1 turn expires
--at the start of the player's next turn (PMMMTickTimedPromotions runs from PlayerDoTurn, which CP fires at
--the start of the player's turn), so the attack is good for this turn only. Civilians would gain nothing
--from ExtraAttacks, so they are skipped rather than handed a meaningless icon.
local function TimeStopExtraAttacks(pPlayer)
	if not iStoppedTimeAttack then return end
	for pUnit in pPlayer:Units() do
		if pUnit:IsCombatUnit() or pUnit:GetBaseRangedCombatStrength() > 0 then
			PMMMApplyTimedPromotion(pUnit, iStoppedTimeAttack, 1)
		end
	end
end

local function HasCannotHealPromotion(pUnit)
	for _, iPromotion in ipairs(tCannotHealPromotions) do
		if pUnit:IsHasPromotion(iPromotion) then return true end
	end
	return false
end

--One turn of ordinary healing for every hurt unit.
--APPROXIMATION: CvUnit::healRate has no Lua binding. This rebuilds its core -- the basic rate for the tile
--(city 25, friendly territory 20, enemy territory 10, anywhere else 10) plus the unit's own
--promotion bonus for that kind of territory (GetExtraFriendly/Neutral/EnemyHeal) -- and leaves out the
--rest: medic units on or next to the tile, the city's own heal-rate buildings, religious beliefs, the
--flat-heal promotions, strategic monopolies, the player's base heal modifier and double-heal terrain.
--Every omission is a bonus, so the result never exceeds what the engine would heal. Units that cannot heal
--at all (embarked, a CannotHeal promotion) get nothing; whether the unit moved or fortified is ignored,
--since a stopped-time turn is a rest by definition.
local function TimeStopHealing(pPlayer)
	local iPlayer = pPlayer:GetID()
	local iTeam = pPlayer:GetTeam()
	local pTeam = Teams[iTeam]
	for pUnit in pPlayer:Units() do
		local iDamage = pUnit:GetDamage()
		if iDamage > 0 and not pUnit:IsEmbarked() and not pUnit:IsDelayedDeath() and not HasCannotHealPromotion(pUnit) then
			local pPlot = pUnit:GetPlot()
			if pPlot then
				local iHeal
				local iOwner = pPlot:GetOwner()
				if pPlot:IsCity() then
					iHeal = iCityHealRate
					if pPlot:GetTeam() == iTeam then
						iHeal = iHeal + pUnit:GetExtraFriendlyHeal()
					else
						iHeal = iHeal + pUnit:GetExtraNeutralHeal()
					end
				elseif pPlot:IsFriendlyTerritory(iPlayer) then
					iHeal = iFriendlyHealRate + pUnit:GetExtraFriendlyHeal()
				elseif iOwner >= 0 and pTeam:IsAtWar(Players[iOwner]:GetTeam()) then
					iHeal = iEnemyHealRate + pUnit:GetExtraEnemyHeal()
				else
					iHeal = iNeutralHealRate + pUnit:GetExtraNeutralHeal()
				end
				iHeal = math.min(iHeal, iDamage)
				if iHeal > 0 then
					pUnit:ChangeDamage(-iHeal)
				end
			end
		end
	end
end

--One turn of every city's yields, and one turn of its Great Person points.
--  Food:       the city's surplus (CP's GetYieldRate(FOOD) is already net of consumption) into its food
--              box. A starving city gets nothing rather than a second turn of starvation.
--  Production: the city's per-turn Production into what it is building (ChangeProduction adds to the
--              current order). Nothing while it runs a process (Wealth, Research...): the process's Gold or
--              Science is already inside that city's Gold / Science yield below.
--  Gold, Science, Culture, Faith: each city's per-turn yield, summed and given to the player; Science goes
--              into the current research, or into overflow research if nothing is being researched.
--  APPROXIMATION: only city yields are repeated. Player-level income that does not come from a city
--              (Gold from city-state allies and trade deals, Science from research agreements, Faith and
--              Culture from city-states) is not, nor are upkeep costs charged again; and a city's Culture
--              goes to the player's policy pool only, not a second time into the city's border growth.
--  Great Person points: GetSpecialistRate is the engine's own per-turn figure (hundredths, the unit
--              ChangeSpecialistGreatPersonProgressTimes100 takes), for every specialist type. A Great
--              Person whose threshold this crosses is born at the city's next turn, as usual.
--              [port] Phase 6 Lekmod: GetSpecialistRate is CP-only; the PMMMCityGetSpecialistRate wrapper
--              (PMMMGeneralFunctions.lua) calls it natively under CP and otherwise approximates it as the
--              city's specialist count times the specialist's GreatPeopleRateChange -- base rates only, so
--              per-player GP-rate modifiers are not part of the fallback figure.
local function TimeStopCityYields(pPlayer)
	local iPlayer = pPlayer:GetID()
	local iGold, iScience, iCulture, iFaith = 0, 0, 0, 0
	for pCity in pPlayer:Cities() do
		local iFood = pCity:GetYieldRate(YieldTypes.YIELD_FOOD)
		if iFood > 0 then
			pCity:ChangeFood(iFood)
		end

		if pCity:IsProduction() and not pCity:IsProductionProcess() then
			local iProduction = pCity:GetYieldRate(YieldTypes.YIELD_PRODUCTION)
			if iProduction > 0 then
				pCity:ChangeProduction(iProduction)
			end
		end

		iGold = iGold + math.max(pCity:GetYieldRate(YieldTypes.YIELD_GOLD), 0)
		iScience = iScience + math.max(pCity:GetYieldRate(YieldTypes.YIELD_SCIENCE), 0)
		iCulture = iCulture + math.max(pCity:GetJONSCulturePerTurn(), 0)
		iFaith = iFaith + math.max(pCity:GetFaithPerTurn(), 0)

		for row in GameInfo.Specialists() do
			local iRate = PMMMCityGetSpecialistRate(pCity, row.ID)
			if iRate and iRate > 0 then
				pCity:ChangeSpecialistGreatPersonProgressTimes100(row.ID, iRate)
			end
		end
	end

	if iGold > 0 then pPlayer:ChangeGold(iGold) end
	if iCulture > 0 then pPlayer:ChangeJONSCulture(iCulture) end
	if iFaith > 0 then pPlayer:ChangeFaith(iFaith) end
	if iScience > 0 then
		local iTech = pPlayer:GetCurrentResearch()
		if iTech and iTech >= 0 then
			Teams[pPlayer:GetTeam()]:GetTeamTechs():ChangeResearchProgress(iTech, iScience, iPlayer)
		else
			pPlayer:ChangeOverflowResearch(iScience)
		end
	end
end

--One more turn of work on every worker build in progress.
--Plot:ChangeBuildProgress(eBuild, iChange, ePlayer, bNewBuild) (CvLuaPlot.cpp binds CvPlot::
--changeBuildProgress directly). The engine lets a plot's build progress change once per game turn unless
--bNewBuild is true, so this passes true: otherwise the call would be refused on any plot a worker has
--already worked this turn. The price of that flag is that the plot is marked as changed this turn, and a
--worker that has NOT yet worked this turn is then refused its own progress. That is exactly the AI's case
--(its Time Stop fires from PlayerDoTurn, before any unit acts), so an AI's workers are given two turns of
--work here -- the free turn and the ordinary turn this call displaces -- and a human's, who can only press
--the button after the turn's work is done, one.
--The amount is the unit's own work rate (WorkRate(true): its full rate, whatever moves it has left). A work
--rate of 1 or less means instant builds or CP's Civ VI worker option, which do not use build progress, and
--is skipped. Several workers on one build share one call, in unit order.
local function TimeStopWorkerBuilds(pPlayer, bBeforeUnitsActed)
	local iPlayer = pPlayer:GetID()
	local tOrder, tByKey = {}, {}
	for pUnit in pPlayer:Units() do
		local iBuild = pUnit:GetBuildType()
		if iBuild and iBuild >= 0 then
			local iRate = pUnit:WorkRate(true)
			local pPlot = pUnit:GetPlot()
			if iRate and iRate > 1 and pPlot then
				if bBeforeUnitsActed then iRate = iRate * 2 end
				local sKey = pPlot:GetX() .. "," .. pPlot:GetY() .. "," .. iBuild
				local tEntry = tByKey[sKey]
				if not tEntry then
					tEntry = { Plot = pPlot, Build = iBuild, Change = 0 }
					tByKey[sKey] = tEntry
					tOrder[#tOrder + 1] = tEntry
				end
				tEntry.Change = tEntry.Change + iRate
			end
		end
	end
	for _, tEntry in ipairs(tOrder) do
		tEntry.Plot:ChangeBuildProgress(tEntry.Build, tEntry.Change, iPlayer, true)
	end
end

--One turn of Tourism: the engine's own per-turn influence on each civilization (GetInfluencePerTurn, which
--already contains every tourism modifier toward that civilization, so it is added without applying them
--again), for every living major civilization this player has met -- the same set CvPlayerCulture::DoTurn
--walks. Whole points only: the engine's hundredths are rounded down.
local function TimeStopTourism(pPlayer)
	local iPlayer = pPlayer:GetID()
	local iTeam = pPlayer:GetTeam()
	for iOther = 0, iMaxMajorCivs - 1 do
		local pOther = Players[iOther]
		if iOther ~= iPlayer and pOther and pOther:IsAlive() and not pOther:IsMinorCiv()
				and Teams[pOther:GetTeam()]:IsHasMet(iTeam) then
			local iInfluence = pPlayer:GetInfluencePerTurn(iOther)
			if iInfluence and iInfluence > 0 then
				--[port] Phase 6 Lekmod: ChangeInfluenceOnPlayer is CP-only. The wrapper (PMMMGeneralFunctions.lua)
				--calls it natively under CP. On a DLL without it the loop only ever passes MAJOR civilizations, where
				--Lekmod binds no substitute either (the vanilla backing, CvPlayerCulture::ChangeInfluenceOn, is
				--unbound there), so the fallback is a documented no-op: Time Stop's Tourism turn is silently lost
				--for majors. The binding-only port to Lekmod's DLL restores it (see lekmod-scope-engine.md §7.4).
				PMMMPlayerChangeInfluenceOnPlayer(pPlayer, iOther, iInfluence)
			end
		end
	end
end

--------------------------------------------------------------
-- Time Stop AI rule
--   At war (with anyone but barbarians): fire when at least 3 of its combat units stand within 3 tiles of
--   a visible enemy unit or an enemy city.
--   At peace: fire when the capital is at least half way through a wonder (world, team or national) or a
--   unit.
--------------------------------------------------------------
local function CountCombatUnitsNearEnemies(pPlayer)
	local iCount = 0
	for pUnit in pPlayer:Units() do
		if pUnit:IsCombatUnit() then
			local pCentre = pUnit:GetPlot()
			if pCentre then
				for pAreaPlot in PlotAreaSpiralIterator(pCentre, iAIWarRange, 1, false, false, true) do
					if pAreaPlot and PlotHasEnemy(pPlayer, pUnit, pAreaPlot) then
						iCount = iCount + 1
						break
					end
				end
				if iCount >= iAIWarUnitsNeeded then return iCount end
			end
		end
	end
	return iCount
end

local function IsCapitalHalfWayThroughWonderOrUnit(pPlayer)
	local pCapital = pPlayer:GetCapitalCity()
	if not pCapital or not pCapital:IsProduction() or pCapital:IsProductionProcess() then return false end
	local bCounts = false
	local iUnit = pCapital:GetProductionUnit()
	if iUnit and iUnit >= 0 then
		bCounts = true
	else
		local iBuilding = pCapital:GetProductionBuilding()
		local pBuilding = (iBuilding and iBuilding >= 0) and GameInfo.Buildings[iBuilding] or nil
		local pClass = pBuilding and GameInfo.BuildingClasses[pBuilding.BuildingClass] or nil
		if pClass and (pClass.MaxGlobalInstances > 0 or pClass.MaxTeamInstances > 0 or pClass.MaxPlayerInstances == 1) then
			bCounts = true
		end
	end
	if not bCounts then return false end
	local iNeeded = pCapital:GetProductionNeeded()
	return iNeeded > 0 and (pCapital:GetProduction() * 2) >= iNeeded
end

--------------------------------------------------------------
-- Homura Akemi: Time Stop
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_TIME_STOP", {
	--The girl's trait already names Concentrated Missile Fire; this binds the second ability.
	TraitType = sHomuraTrait,
	--The real 20-turn cooldown is PMMM.TimeStopCooldown[player]; 0 keeps the framework's shared per-girl
	--counter at its 1-turn minimum (see the note above Concentrated Missile Fire).
	Cooldown = 0,
	NeedsTarget = false,
	EndsTurn = false,
	--No Soul Gem cost.

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return GetTimeStopCooldown(pPlayer:GetID()) <= 0
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local bBeforeUnitsActed = bTimeStopFiredByAI
		bTimeStopFiredByAI = false

		TimeStopExtraAttacks(pPlayer)
		TimeStopHealing(pPlayer)
		TimeStopCityYields(pPlayer)
		TimeStopWorkerBuilds(pPlayer, bBeforeUnitsActed)
		TimeStopTourism(pPlayer)

		SetTimeStopCooldown(iPlayer, GetScaledAbilityCooldown(iTimeStopCooldown))
		--"Active" for the rest of this turn; the UnitPanel tooltip reads it. Cleared in PMMMHomuraDoTurn.
		PMMM.TimeStopDuration = PMMM.TimeStopDuration or {}
		PMMM.TimeStopDuration[iPlayer] = 1
		if iMGKey and MagicalGirls[iMGKey] then
			MagicalGirls[iMGKey].TimeStopUsedTurn = Game.GetGameTurn()
		end

		if iPlayer == Game.GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_HOMURA_TIME_STOP_ACTIVATED"))
		end
	end,

	--The framework hands a no-target ability her own plot; the rule looks at the whole empire instead.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		bTimeStopFiredByAI = false
		if GetTimeStopCooldown(pPlayer:GetID()) > 0 then return nil end
		local bFire
		if Teams[pPlayer:GetTeam()]:GetAtWarCount(false) > 0 then
			bFire = CountCombatUnitsNearEnemies(pPlayer) >= iAIWarUnitsNeeded
		else
			bFire = IsCapitalHalfWayThroughWonderOrUnit(pPlayer)
		end
		if not bFire then return nil end
		bTimeStopFiredByAI = true
		return 1
	end,
})

--------------------------------------------------------------
-- Thief of Time
-- A Thief of Time that ends its owner's turn inside another major civilization's borders counts one turn
-- (checked from PlayerDoTurn, which CP fires at the start of the owner's next turn, before any unit has
-- moved, so the plot is where the unit ended its turn). The count need not be consecutive: leaving the
-- borders pauses it, it does not reset it. On every 3rd counted turn the owner gains 10% of the research
-- cost (its own, city-count-scaled cost) of a random technology it can research right now; the candidates
-- are listed in technology-ID order and Game.Rand picks one. A team-mate's land does not count.
--
-- The counter lives in PMMM.HomuraThiefOfTimeTurns[player][unitID], created here on first use. TableSave
-- saves the whole PMMM table, so it persists; it is NOT declared in PMMMDefines.lua (not ours to edit), and
-- should be, beside the other per-player tables:
--     PMMM.HomuraThiefOfTimeTurns = PMMM.HomuraThiefOfTimeTurns or {}
-- Entries of Thieves that no longer exist are dropped each turn.
--------------------------------------------------------------
local function GrantThiefOfTimeTech(pPlayer)
	local iPlayer = pPlayer:GetID()
	local pTeamTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()
	local tCandidates = {}
	for _, iTech in ipairs(tAllTechIDs) do
		if not pTeamTechs:HasTech(iTech) and pPlayer:CanResearch(iTech) then
			tCandidates[#tCandidates + 1] = iTech
		end
	end
	if #tCandidates == 0 then return end
	local iTech = tCandidates[Game.Rand(#tCandidates, "PMMM Thief of Time tech") + 1]
	local iBeakers = math.floor((pPlayer:GetResearchCost(iTech) * iThiefTechPercent) / 100)
	if iBeakers <= 0 then return end
	pTeamTechs:ChangeResearchProgress(iTech, iBeakers, iPlayer)
	if pPlayer:IsHuman() then
		local pTech = GameInfo.Technologies[iTech]
		--[port] Phase 6 Lekmod: AddMessage is CP-only; the wrapper (PMMMGeneralFunctions.lua) calls it
		--natively under CP and falls back to AddNotification elsewhere.
		PMMMPlayerAddMessage(pPlayer, Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_THIEF_OF_TIME", iBeakers, pTech and pTech.Description or ""))
	end
end

local function DoThiefOfTimeTurn(iPlayer)
	if not iThiefOfTime then return end
	local pPlayer = Players[iPlayer]
	local iTeam = pPlayer:GetTeam()
	local tOld = PMMM.HomuraThiefOfTimeTurns and PMMM.HomuraThiefOfTimeTurns[iPlayer]
	local tNew
	local iTriggers = 0
	for pUnit in pPlayer:Units() do
		if pUnit:GetUnitType() == iThiefOfTime then
			local iUnitID = pUnit:GetID()
			local iCount = (tOld and tOld[iUnitID]) or 0
			local pPlot = pUnit:GetPlot()
			local iOwner = pPlot and pPlot:GetOwner() or -1
			if iOwner >= 0 and iOwner < iMaxMajorCivs and iOwner ~= iPlayer then
				local pOwner = Players[iOwner]
				if pOwner and pOwner:IsAlive() and not pOwner:IsMinorCiv() and pOwner:GetTeam() ~= iTeam then
					iCount = iCount + 1
					if iCount >= iThiefTurnsPerTrigger then
						iCount = 0
						iTriggers = iTriggers + 1
					end
				end
			end
			if iCount > 0 then
				tNew = tNew or {}
				tNew[iUnitID] = iCount
			end
		end
	end
	if tOld or tNew then
		PMMM.HomuraThiefOfTimeTurns = PMMM.HomuraThiefOfTimeTurns or {}
		PMMM.HomuraThiefOfTimeTurns[iPlayer] = tNew
	end
	for _ = 1, iTriggers do
		GrantThiefOfTimeTech(pPlayer)
	end
end

--------------------------------------------------------------
-- Per-turn upkeep: tick both of Homura's cooldowns, end the "time is stopped" flag, count the Thieves.
--------------------------------------------------------------
function PMMMHomuraDoTurn(iPlayer)
	if iPlayer >= iMaxMajorCivs then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end

	if PMMM.TimeStopDuration and PMMM.TimeStopDuration[iPlayer] and PMMM.TimeStopDuration[iPlayer] > 0 then
		PMMM.TimeStopDuration[iPlayer] = 0
	end
	local iCooldown = GetTimeStopCooldown(iPlayer)
	if iCooldown > 0 then
		SetTimeStopCooldown(iPlayer, iCooldown - 1)
		if iCooldown == 1 and pPlayer:IsHuman() then
			--[port] Phase 6 Lekmod: AddMessage is CP-only; wrapper (PMMMGeneralFunctions.lua).
			PMMMPlayerAddMessage(pPlayer, Locale.ConvertTextKey("TXT_KEY_PMMM_ALERT_HOMURA_TIME_STOP_READY"))
		end
	end

	for _, tGirl in pairs(MagicalGirls) do
		if tGirl.Owner == iPlayer and tGirl.MissileFireCooldown and tGirl.MissileFireCooldown > 0 then
			tGirl.MissileFireCooldown = tGirl.MissileFireCooldown - 1
		end
	end

	DoThiefOfTimeTurn(iPlayer)
end

--Registered once even if this file is included again.
if not bPMMMHomuraKitRegistered then
	bPMMMHomuraKitRegistered = true
	GameEvents.PlayerDoTurn.Add(PMMMHomuraDoTurn)
	table.insert(tPMMMGriefSeedUsedHooks, PMMMHomuraTimeStopGriefSeedUsed)
end
