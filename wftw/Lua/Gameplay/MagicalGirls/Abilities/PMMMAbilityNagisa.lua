-- PMMMAbilityNagisa
-- [port] Phase 4: Nagisa Momoe's Leader Magical Girl abilities.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/Nagisa.sql.
--------------------------------------------------------------
-- [port] Phase 4: Magic Cake Dish. Design: docs/design/phase4-design-v1.md section 15, ruling 7: every
-- friendly unit next to her, her own tile included, heals 25% of its maximum hit points and fights at
-- +10% Combat Strength for 3 turns. No damage, no Soul Gem cost.
--
-- Readings the ruling does not fix (listed in the build report):
--   * "Adjacent" is radius 1 around Nagisa with her own tile included, so she eats the cake too.
--   * "Friendly" is every unit of her own team, as for Baldamente Fortissimo; civilian units are fed as
--     well (the buff does nothing for them, and leaving them out would need a rule the spec does not give).
--   * The cooldown is not in the ruling: 5 turns, scaled by game speed like every other ability.
--
-- It has no target. As with Baldamente Fortissimo, the mission row carries no PMMMMissionRange and no
-- PMMMTargetType, so the button fires at once and the framework hands the handler her own plot.
--------------------------------------------------------------

--How far the cake is passed round. Kept here, not on the Missions row: a range there would turn the
--mission into a targeted one in the UI.
local iCakeRange = 1

--Percent of a unit's maximum hit points restored.
local iCakeHealPercent = 25

--How long the +10% Combat Strength lasts, in the owner's turns. The promotion carries CombatPercent 10.
local iCakeBuffTurns = 3

local iCakePromotion = GameInfoTypes.PROMOTION_PMMM_MAGIC_CAKE

--Every unit of her own team within iRange of pCentre, the centre tile included, in a fixed order
--(spiral order, then the plot's own unit order), so the outcome is the same on every machine.
local function ForEachFriendlyUnitInRange(pPlayer, pCentre, iRange, fnDo)
	if not pCentre then return end
	local iTeam = pPlayer:GetTeam()
	for pAreaPlot in PlotAreaSpiralIterator(pCentre, iRange, 1, false, false, true) do
		if pAreaPlot then
			for i = 0, pAreaPlot:GetNumUnits() - 1 do
				local pTarget = pAreaPlot:GetUnit(i)
				if pTarget and pTarget:GetTeam() == iTeam then
					fnDo(pTarget)
				end
			end
		end
	end
end

--Is a visible enemy unit or enemy city on any tile next to pPlot?
local function IsNextToEnemy(pPlayer, pPlot)
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	for pAreaPlot in PlotAreaSpiralIterator(pPlot, 1, 1, false, false, false) do
		if pAreaPlot and pAreaPlot ~= pPlot then
			for i = 0, pAreaPlot:GetNumUnits() - 1 do
				local pEnemy = pAreaPlot:GetUnit(i)
				if pEnemy and not pEnemy:IsInvisible(iTeam, false) and pTeam:IsAtWar(pEnemy:GetTeam()) then
					return true
				end
			end
			if pAreaPlot:IsCity() then
				local pCity = pAreaPlot:GetPlotCity()
				if pCity and pTeam:IsAtWar(Players[pCity:GetOwner()]:GetTeam()) then return true end
			end
		end
	end
	return false
end

--------------------------------------------------------------
-- Nagisa Momoe: Magic Cake Dish
-- Everyone next to her heals a quarter of their health and fights 10% harder for 3 turns.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_MAGIC_CAKE_DISH", {
	Cooldown = 5,
	--No target: it is centred on her.
	NeedsTarget = false,
	--Serving the cake is the whole of her turn, the same as every other leader ability.
	EndsTurn = true,
	--No CanUseHere: the buff alone is worth the button, so only the cooldown can grey it out.

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--Centred on her, never on the plot she was handed.
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iCakeRange, function(pTarget)
			--Heal 25% of maximum hit points, never past full health.
			local iHeal = math.floor((pTarget:GetMaxHitPoints() * iCakeHealPercent) / 100)
			iHeal = math.min(pTarget:GetDamage(), iHeal)
			if iHeal > 0 then
				pTarget:ChangeDamage(-1 * iHeal)
			end
			--+10% Combat Strength for 3 turns; the framework removes it when it expires.
			PMMMApplyTimedPromotion(pTarget, iCakePromotion, iCakeBuffTurns)
		end)

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_MAGIC_CAKE_DISH"))
		end
	end,

	--Served when it pays: at least two hurt units within reach of the cake, or at least two of our combat
	--units within reach that stand next to an enemy (an adjacent enemy already means we are at war with
	--it). Units counted are the ones the cake reaches, so Nagisa herself counts. The plot the framework
	--offers is her own tile, and the scorer ignores it for the same reason Execute does.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local iDamaged, iTotalDamage, iEngaged = 0, 0, 0
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iCakeRange, function(pTarget)
			local iDamage = pTarget:GetDamage()
			if iDamage > 0 then
				iDamaged = iDamaged + 1
				iTotalDamage = iTotalDamage + iDamage
			end
			if pTarget:IsCombatUnit() and IsNextToEnemy(pPlayer, pTarget:GetPlot()) then
				iEngaged = iEngaged + 1
			end
		end)
		if iDamaged < 2 and iEngaged < 2 then return nil end
		return 100 + iTotalDamage + 50 * iEngaged
	end,
})
