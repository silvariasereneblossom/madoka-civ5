-- PMMMAbilityOrikoKirika
-- [port] Phase 4: Oriko Mikuni and Kirika Kure's Leader Magical Girl abilities.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/OrikoKirika.sql.
--------------------------------------------------------------
-- [port] Phase 4: design docs/design/phase4-design-v1.md section 15, ruling 8. The Shiromeian Empire has
-- two leader girls, and each owns one ability:
--
--   * Oriko (the civ's first leader girl): Oracle Ray, trait column LeaderMGUniqueMission.
--   * Kirika (the extra leader girl):      Vampire Fang, trait column ExtraLeaderMGUniqueMission.
--
-- PMMMMagicalGirls.lua records the mission each was born with in MagicalGirls[key].ExtraMission, and
-- GetLeaderAbilityForUnit lets a girl with an ExtraMission use that one only. Neither definition sets
-- TraitType, which would open it to both girls.
--
-- Readings the ruling does not fix (listed in the build report):
--   * Oracle Ray: "the area around an enemy unit" is radius 1 around the target tile, the target included.
--     Units standing in a city are never candidates and a city tile cannot be targeted (the ray strikes
--     units, not walls; hitting a garrison directly would bypass the city). A unit killed by one hit
--     leaves the pool; hits left over once every candidate is dead are lost.
--   * Vampire Fang: the cooldown is not in the ruling: 4 turns. Range 1. The debuff lasts 2 of the
--     victim's owner's turns. Kirika heals floor(damage / 2), never past full health. A city tile cannot
--     be targeted.
--------------------------------------------------------------

--How far the ray is scattered around the target tile.
local iOracleRayRadius = 1
--Number of hits and the strength of each, as a multiple of Oriko's attack strength.
local iOracleRayHits = 5
local fOracleRayMultiplier = 0.6

--The bite: strength multiplier, the debuff's length in turns, and the share of damage Kirika drinks.
local fVampireFangMultiplier = 1.5
local iVampireFangDebuffTurns = 2
local iVampireFangDrainPercent = 50

local iVampireFangDebuff = GameInfoTypes.PROMOTION_PMMM_VAMPIRE_FANG_WEAKNESS

--Is this unit still standing after a hit? A lethal ChangeDamage sets IsDead and schedules the unit's
--deletion, so the object is still readable but must not be struck or promoted again.
local function IsAlive(pTarget)
	return pTarget ~= nil and not pTarget:IsDead() and not pTarget:IsDelayedDeath()
end

--Every visible enemy unit on the tile, in the tile's own unit order. A tile holding a city gives none.
local function AddEnemiesOnPlot(pPlayer, pPlot, tList)
	if not pPlot or pPlot:IsCity() then return end
	local pTeam = Teams[pPlayer:GetTeam()]
	local iTeam = pPlayer:GetTeam()
	for i = 0, pPlot:GetNumUnits() - 1 do
		local pTarget = pPlot:GetUnit(i)
		if pTarget and not pTarget:IsInvisible(iTeam, false) and pTeam:IsAtWar(pTarget:GetTeam()) then
			tList[#tList + 1] = pTarget
		end
	end
end

--The first visible enemy unit on the tile, or nil. Never on a city tile.
local function FirstEnemyOnPlot(pPlayer, pPlot)
	local tList = {}
	AddEnemiesOnPlot(pPlayer, pPlot, tList)
	return tList[1]
end

--Oracle Ray's candidates: every enemy unit within iOracleRayRadius of the target tile, the target tile
--first and then the ring in spiral order. The order is fixed, so Game.Rand picks the same unit on every
--machine.
local function GetOracleRayCandidates(pPlayer, pPlot)
	local tList = {}
	for pAreaPlot in PlotAreaSpiralIterator(pPlot, iOracleRayRadius, 1, false, false, true) do
		if pAreaPlot then
			AddEnemiesOnPlot(pPlayer, pAreaPlot, tList)
		end
	end
	return tList
end

--------------------------------------------------------------
-- Oriko Mikuni: Oracle Ray
-- Five hits at 60% of her strength, each on an enemy unit picked at random around the target.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_ORACLE_RAY", {
	Cooldown = 5,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return FirstEnemyOnPlot(pPlayer, pPlot) ~= nil
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local tCandidates = GetOracleRayCandidates(pPlayer, pPlot)

		for _ = 1, iOracleRayHits do
			--Drop anyone an earlier hit killed; the survivors may be hit again.
			local tLive = {}
			for _, pTarget in ipairs(tCandidates) do
				if IsAlive(pTarget) then tLive[#tLive + 1] = pTarget end
			end
			tCandidates = tLive
			if #tCandidates == 0 then break end

			local pTarget = tCandidates[Game.Rand(#tCandidates, "PMMM Oracle Ray target") + 1]
			PMMMVirtualAttack(pUnit, pTarget, fOracleRayMultiplier)
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_ORACLE_RAY"))
		end
	end,

	--Aim where the most enemies (and the most hurt ones) stand, so the five hits are least likely to be
	--wasted on one unit.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		if not FirstEnemyOnPlot(pPlayer, pPlot) then return nil end
		local iScore = 0
		for _, pTarget in ipairs(GetOracleRayCandidates(pPlayer, pPlot)) do
			iScore = iScore + 100 + pTarget:GetDamage()
		end
		return iScore
	end,
})

--------------------------------------------------------------
-- Kirika Kure: Vampire Fang
-- One bite at 150%: the victim fights at -25% for 2 turns and Kirika heals half the damage dealt.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_VAMPIRE_FANG", {
	Cooldown = 4,

	CanUseHere = function(pPlayer, pUnit, pPlot, iMGKey)
		return FirstEnemyOnPlot(pPlayer, pPlot) ~= nil
	end,

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]
		local pTarget = FirstEnemyOnPlot(pPlayer, pPlot)
		if pTarget then
			local iDamage = PMMMVirtualAttack(pUnit, pTarget, fVampireFangMultiplier)

			--The weakness only matters on a survivor.
			if IsAlive(pTarget) then
				PMMMApplyTimedPromotion(pTarget, iVampireFangDebuff, iVampireFangDebuffTurns)
			end

			--Half the damage dealt comes back to her as health, never past full.
			local iHeal = math.floor((iDamage * iVampireFangDrainPercent) / 100)
			iHeal = math.min(pUnit:GetDamage(), iHeal)
			if iHeal > 0 then
				pUnit:ChangeDamage(-1 * iHeal)
			end
		end

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_VAMPIRE_FANG"))
		end
	end,

	--Bite whatever is next to her, preferring the strongest unit (the weakness is worth most there) and,
	--among equals, the most hurt one (the bite is most likely to finish it).
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local pTarget = FirstEnemyOnPlot(pPlayer, pPlot)
		if not pTarget then return nil end
		return pTarget:GetBaseCombatStrength() * 100 + pTarget:GetDamage()
	end,
})
