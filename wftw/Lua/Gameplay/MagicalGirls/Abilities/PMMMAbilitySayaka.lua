-- PMMMAbilitySayaka
-- [port] Phase 4: Sayaka Miki's Leader Magical Girl ability.
-- Shared machinery: PMMMLeaderAbilities.lua. Data half: SQL/Phase4/Sayaka.sql.
--------------------------------------------------------------
-- Baldamente Fortissimo. Design: docs/design/phase4-design-v1.md section 5: every friendly unit
-- within two tiles of her, herself included, heals 25% of its maximum hit points at once and takes
-- half damage while defending for two turns. It deals no damage and costs no Soul Gem; the six-turn
-- cooldown is the whole of the price.
--
-- It has no target. The mission row therefore carries no PMMMMissionRange and no PMMMTargetType, the
-- way MISSION_PMMM_DULL_PAIN does, so clicking the button fires it at once instead of opening target
-- selection, and the framework hands the handler her own plot. The handler centres on her own plot in
-- any case, so the ability behaves the same however it was invoked.
--------------------------------------------------------------

--How far the song carries. Not read from the Missions row: PMMMMissionRange is what turns a mission
--into a targeted one in the UI, so a no-target ability must leave it at 0 and keep its radius here.
local iFortissimoRange = 2

--How much of a unit's maximum hit points the song restores, as a percentage.
local iFortissimoHealPercent = 25

--How long the guard lasts, in the owner's turns. The promotion carries DamageTakenMod -50.
local iFortissimoGuardTurns = 2

local iFortissimoGuard = GameInfoTypes.PROMOTION_PMMM_FORTISSIMO_GUARD

--Every unit of her own team standing within iRange of pCentre, her own tile included.
--Allies on the same team are covered as well, which is what "friendly" means everywhere else in the
--mod; units of a separate civilization we are merely at peace with are not.
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

--------------------------------------------------------------
-- Sayaka Miki: Baldamente Fortissimo
-- No damage. Everyone around her is healed and hardened.
--------------------------------------------------------------
RegisterLeaderAbility("MISSION_PMMM_BALDAMENTE_FORTISSIMO", {
	Cooldown = 6,
	--No target: it is centred on her, so the framework must not try to decode a target plot.
	NeedsTarget = false,
	--Playing it is the whole of her turn, the same as every other leader ability.
	EndsTurn = true,
	--No CanUseHere: the guard alone is worth the button even when nobody is hurt, so the only thing
	--that can grey it out is the cooldown.

	Execute = function(iPlayer, pUnit, pPlot, iMGKey)
		local pPlayer = Players[iPlayer]

		--Centred on her, never on the plot she was handed: the ability has no target and the AI path
		--passes whatever plot its scorer liked.
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iFortissimoRange, function(pTarget)
			--Heal 25% of maximum hit points, never past full health.
			local iHeal = math.floor((pTarget:GetMaxHitPoints() * iFortissimoHealPercent) / 100)
			iHeal = math.min(pTarget:GetDamage(), iHeal)
			if iHeal > 0 then
				pTarget:ChangeDamage(-1 * iHeal)
			end
			--Half damage while defending, for the next two turns. The framework takes the promotion
			--away again when it expires.
			PMMMApplyTimedPromotion(pTarget, iFortissimoGuard, iFortissimoGuardTurns)
		end)

		if pPlayer:GetID() == Game:GetActivePlayer() then
			Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_MISSION_PMMM_BALDAMENTE_FORTISSIMO"))
		end
	end,

	--Sung when it saves something: two or more hurt friends in earshot, or she is under half health
	--herself and the guard is what keeps her alive. The plot the framework offers is her own -- the
	--mission has no range, so the AI's search is a single tile -- and the scorer ignores it for the
	--same reason Execute does.
	AIScorePlot = function(pPlayer, pUnit, pPlot)
		local iDamaged, iTotalDamage = 0, 0
		ForEachFriendlyUnitInRange(pPlayer, pUnit:GetPlot(), iFortissimoRange, function(pTarget)
			local iDamage = pTarget:GetDamage()
			if iDamage > 0 then
				iDamaged = iDamaged + 1
				iTotalDamage = iTotalDamage + iDamage
			end
		end)
		local bSheIsHurt = (pUnit:GetDamage() * 2) >= pUnit:GetMaxHitPoints()
		if iDamaged < 2 and not bSheIsHurt then return nil end
		return 100 + iTotalDamage
	end,
})


--------------------------------------------------------------
-- [port] Phase 4: Kyoshikyoku no Seigi (Rhapsody of Justice), Sayaka's UA.
-- Design: docs/design/phase4-design-v1.md section 5. Data half: SQL/Phase4/Sayaka.sql.
--
-- This lives in the ability file on purpose: PMMMTraitBootstrapper.lua loads PMMMSayakaTrait.lua only
-- when the old trait columns are set, and Phase 4 clears them to retire the old UA. This file is always
-- loaded, so the new UA registers its own events here.
--
--   * Once, as soon as she has a capital: create Decretum and put it in the Palace Music Hall's first
--     slot, then grant the hidden policy POLICY_PMMM_SAYAKA_RHAPSODY. [port] Phase 4: since ruling 15.1 the
--     policy carries no modifiers; it is only the "already done" flag, because the engine saves it and no
--     new persisted table is needed.
--   * [port] Phase 4 (ruling 15.1): each of her turns, and when she founds a city, the capital's stack of
--     BUILDING_PMMM_SAYAKA_WONDER_TOURISM (+5% Tourism in all her cities each) is set to the number of World
--     Wonders she built and still owns, and removed from any former capital.
--   * When she founds a city and at the start of each of her turns: keep the Music Hall in her current
--     capital, moving it and its works out of a former capital.
--   * Each of her turns: 10% of her Tourism per turn becomes Musician Prodigy points in the capital, 5%
--     each Artist and Writer points, each capped at 20 points per turn.
--------------------------------------------------------------

--[port] Phase 4: the trait that owns this UA
local sRhapsodyTrait = "TRAIT_TOURISM_HEALING_BONUS"

local iRhapsodyPolicy = GameInfoTypes.POLICY_PMMM_SAYAKA_RHAPSODY
local iMusicHall = GameInfoTypes.BUILDING_PMMM_OKTAVIAN_MUSIC_HALL
local iMusicHallClass = GameInfoTypes.BUILDINGCLASS_PMMM_OKTAVIAN_MUSIC_HALL
local iMusicHallSlots = (iMusicHall and GameInfo.Buildings[iMusicHall].GreatWorkCount) or 0
local iDecretum = GameInfoTypes.GREAT_WORK_PMMM_DECRETUM

--[port] Phase 4: ruling 15.1, +5% Tourism in all her cities per World Wonder (Building_GlobalYieldModifiers
--on a stacking dummy, see SQL/Phase4/Sayaka.sql).
local iWonderTourismDummy = GameInfoTypes.BUILDING_PMMM_SAYAKA_WONDER_TOURISM

--[port] Phase 4: every World Wonder building, in ID order. A World Wonder is a building whose class has
--MaxGlobalInstances = 1 (CP's isWorldWonderClass is MaxGlobalInstances != -1; every such class here is 1).
local tWorldWonderBuildings = {}
for row in GameInfo.Buildings() do
	local pClass = GameInfo.BuildingClasses[row.BuildingClass]
	if pClass and pClass.MaxGlobalInstances == 1 then
		table.insert(tWorldWonderBuildings, row.ID)
	end
end
table.sort(tWorldWonderBuildings)

--Tourism to Prodigy points: percent of Tourism per turn, and the cap per type, in whole points.
--Tourism and the progress call are both in hundredths, so the percentages apply directly.
local tRhapsodyConversion = {
	{ Specialist = GameInfoTypes.SPECIALIST_MUSICIAN, Percent = 10 },
	{ Specialist = GameInfoTypes.SPECIALIST_ARTIST,   Percent = 5 },
	{ Specialist = GameInfoTypes.SPECIALIST_WRITER,   Percent = 5 },
}
local iRhapsodyCapPerTurn = 20

--Per-session cache of which players carry the trait. Read from the database, not from the persisted
--trait cache, so it is right whatever order the scripts were loaded in.
local tIsRhapsodyPlayer = {}
local function IsRhapsodyPlayer(iPlayer)
	if iPlayer < 0 or iPlayer >= GameDefines.MAX_MAJOR_CIVS then return false end
	if tIsRhapsodyPlayer[iPlayer] == nil then
		local pPlayer = Players[iPlayer]
		--A slot that has never been alive is not cached, so a player who enters later is still seen.
		if not pPlayer or not pPlayer:IsEverAlive() then return false end
		local bHas = false
		local pLeader = GameInfo.Leaders[pPlayer:GetLeaderType()]
		if pLeader then
			for row in GameInfo.Leader_Traits{LeaderType = pLeader.Type} do
				if row.TraitType == sRhapsodyTrait then bHas = true end
			end
		end
		tIsRhapsodyPlayer[iPlayer] = bHas
	end
	return tIsRhapsodyPlayer[iPlayer]
end

--The Music Hall always stands in the current capital. If another of her cities still holds it (the
--Palace moved, or she lost the capital and a new one was chosen), its works move into the new Hall's
--free slots and the old Hall is removed. A work that finds no free slot stays where it is, Hall and all.
local function KeepMusicHallInCapital(pPlayer, pCapital)
	if not iMusicHall or not pCapital then return end
	if not pCapital:IsHasBuilding(iMusicHall) then
		pCapital:SetNumRealBuilding(iMusicHall, 1)
	end
	local iCapitalID = pCapital:GetID()
	for pCity in pPlayer:Cities() do
		if pCity:GetID() ~= iCapitalID and pCity:IsHasBuilding(iMusicHall) then
			local bAllMoved = true
			for iSlot = 0, iMusicHallSlots - 1 do
				local iWork = pCity:GetBuildingGreatWork(iMusicHallClass, iSlot)
				if iWork and iWork >= 0 then
					local iFree
					for iNewSlot = 0, iMusicHallSlots - 1 do
						if not iFree and pCapital:GetBuildingGreatWork(iMusicHallClass, iNewSlot) < 0 then
							iFree = iNewSlot
						end
					end
					if iFree then
						pCity:SetBuildingGreatWork(iMusicHallClass, iSlot, -1)
						pCapital:SetBuildingGreatWork(iMusicHallClass, iFree, iWork)
					else
						bAllMoved = false
					end
				end
			end
			if bAllMoved then
				pCity:SetNumRealBuilding(iMusicHall, 0)
			end
		end
	end
end

--[port] Phase 4: ruling 15.1. Reading of "every wonder she has built": a World Wonder standing in one of her
--cities whose original builder is her (City:GetBuildingOriginalOwner). A wonder she lost does not count; one
--she captured from someone else does not count; one she built, lost and took back counts again.
local function CountOwnBuiltWonders(iPlayer, pPlayer)
	local iCount = 0
	for pCity in pPlayer:Cities() do
		if pCity:GetNumWorldWonders() > 0 then
			for _, iBuilding in ipairs(tWorldWonderBuildings) do
				if pCity:GetNumRealBuilding(iBuilding) > 0 and pCity:GetBuildingOriginalOwner(iBuilding) == iPlayer then
					iCount = iCount + 1
				end
			end
		end
	end
	return iCount
end

--[port] Phase 4: ruling 15.1. The capital holds one dummy per wonder; any other city holds none.
local function SyncWonderTourism(iPlayer, pPlayer, pCapital)
	if not iWonderTourismDummy or not pCapital then return end
	local iCapitalID = pCapital:GetID()
	for pCity in pPlayer:Cities() do
		if pCity:GetID() ~= iCapitalID and pCity:GetNumRealBuilding(iWonderTourismDummy) > 0 then
			pCity:SetNumRealBuilding(iWonderTourismDummy, 0)
		end
	end
	local iWonders = CountOwnBuiltWonders(iPlayer, pPlayer)
	if pCapital:GetNumRealBuilding(iWonderTourismDummy) ~= iWonders then
		pCapital:SetNumRealBuilding(iWonderTourismDummy, iWonders)
	end
end

--Once per player: Decretum into the Hall's first slot, then the hidden flag policy.
local function RhapsodyFirstSetup(iPlayer, pPlayer, pCapital)
	if not iRhapsodyPolicy or pPlayer:HasPolicy(iRhapsodyPolicy) then return end
	--[port] Phase 6 Lekmod: Game.CreateGreatWork is CP-only; without it the free Decretum is skipped (tracked
	--degradation) and the rest of the setup still runs.
	if iDecretum and iMusicHall and Game.CreateGreatWork and pCapital:IsHasBuilding(iMusicHall)
	and pCapital:GetBuildingGreatWork(iMusicHallClass, 0) < 0 then
		local sCreator = Locale.ConvertTextKey("TXT_KEY_LEADER_SAYAKA")
		local iWork = Game.CreateGreatWork(iDecretum, iPlayer, pPlayer:GetCurrentEra(), sCreator)
		if iWork and iWork >= 0 then
			pCapital:SetBuildingGreatWork(iMusicHallClass, 0, iWork)
			--[port] Phase 6 Lekmod: City:RefreshTourism is a CP-only recompute trigger; the wrapper
			--(PMMMGeneralFunctions.lua) calls it natively under CP and is a no-op elsewhere, where the next
			--turn's own recompute covers it (one-turn-later tourism display only).
			PMMMCityRefreshTourism(pCapital)
		end
	end
	--bFree: the policy does not count toward the cost of the next one (it is also IsDummy in the data).
	pPlayer:SetHasPolicy(iRhapsodyPolicy, true, true)
end

--10% of Tourism to Musician points, 5% each to Artist and Writer, 20 points per type per turn at most.
local function RhapsodyTourismToProdigies(pPlayer, pCapital)
	local iTourismTimes100 = pPlayer:GetTourism()	--hundredths, as TopPanel.lua reads it
	if not iTourismTimes100 or iTourismTimes100 <= 0 then return end
	for _, tConv in ipairs(tRhapsodyConversion) do
		if tConv.Specialist then
			local iPointsTimes100 = math.floor(iTourismTimes100 * tConv.Percent / 100)
			iPointsTimes100 = math.min(iPointsTimes100, iRhapsodyCapPerTurn * 100)
			if iPointsTimes100 > 0 then
				pCapital:ChangeSpecialistGreatPersonProgressTimes100(tConv.Specialist, iPointsTimes100)
			end
		end
	end
end

function SayakaRhapsodyDoTurn(iPlayer)
	if not IsRhapsodyPlayer(iPlayer) then return end
	local pPlayer = Players[iPlayer]
	if not pPlayer or not pPlayer:IsAlive() then return end
	local pCapital = pPlayer:GetCapitalCity()
	if not pCapital then return end
	KeepMusicHallInCapital(pPlayer, pCapital)
	RhapsodyFirstSetup(iPlayer, pPlayer, pCapital)
	SyncWonderTourism(iPlayer, pPlayer, pCapital)	--[port] Phase 4: ruling 15.1
	RhapsodyTourismToProdigies(pPlayer, pCapital)
end

--Founding her first city puts the Hall and Decretum in place at once rather than on the next turn.
function SayakaRhapsodyCityFounded(iPlayer, iX, iY)
	if not IsRhapsodyPlayer(iPlayer) then return end
	local pPlayer = Players[iPlayer]
	local pCapital = pPlayer and pPlayer:GetCapitalCity()
	if not pCapital then return end
	KeepMusicHallInCapital(pPlayer, pCapital)
	RhapsodyFirstSetup(iPlayer, pPlayer, pCapital)
	SyncWonderTourism(iPlayer, pPlayer, pCapital)	--[port] Phase 4: ruling 15.1
end

--[port] Phase 4: ruling 15.1. A wonder she completes counts at once rather than from her next turn.
local tIsWorldWonderBuilding = {}
for _, iBuilding in ipairs(tWorldWonderBuildings) do tIsWorldWonderBuilding[iBuilding] = true end
function SayakaWonderConstructed(iPlayer, iCity, iBuilding)
	if not tIsWorldWonderBuilding[iBuilding] or not IsRhapsodyPlayer(iPlayer) then return end
	local pPlayer = Players[iPlayer]
	local pCapital = pPlayer and pPlayer:GetCapitalCity()
	if not pCapital then return end
	SyncWonderTourism(iPlayer, pPlayer, pCapital)
end

GameEvents.PlayerDoTurn.Add(SayakaRhapsodyDoTurn)
GameEvents.CityConstructed.Add(SayakaWonderConstructed)	--[port] Phase 4: ruling 15.1
GameEvents.PlayerCityFounded.Add(SayakaRhapsodyCityFounded)
