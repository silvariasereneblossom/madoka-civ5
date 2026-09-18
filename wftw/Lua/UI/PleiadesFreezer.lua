-- PleiadesFreezer
-- Author: Vicevirtuoso
-- DateCreated: 8/14/2014 5:57:28 PM
--------------------------------------------------------------
--[port] Phase 4: the Freezer is deterministic (docs/design/phase4-design-v1.md section 9). This panel only
--displays and pushes a mission: it lists the stored girls with the turns left before each revives, and its one
--button pushes MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED (iData1 = the girl's key). All game state changes happen
--in gameplay Lua (Traits/PMMMPleiadesTrait.lua, hook in Abilities/PMMMAbilityKaoruUmika.lua). The prediction
--readout, the science-diversion slider and the "Begin" experiment button are retired, along with the old
--single-player path that called gameplay functions straight from here and the multiplayer path that created a
--Warrior from UI code.
--------------------------------------------------------------

include("IconSupport")
include("InstanceManager")

local g_InstanceManager = InstanceManager:new("MagicalGirlInstance", "MGListRoot", Controls.MGListStack)

ContextPtr:SetHide(true)

include("PMMMDefines.lua");

local iCurrentMG = -1;

local ttable = {}

local iGriefSeedMission = GameInfoTypes.MISSION_PMMM_PLEIADES_FREEZER_GRIEF_SEED

IconHookup(4, 64, "CIV_COLOR_ATLAS_KAORU_UMIKA", Controls.TitleIcon)

Controls.NoMGsLabel:SetHide(true)
Controls.ResultBox:SetHide(true)


function Show()
	ContextPtr:SetHide(false)
end

LuaEvents.PMMMShowFreezerPopup.Add(Show)

function OnCloseButtonClicked()
	ContextPtr:SetHide(true)
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnCloseButtonClicked)

local function ActivePlayerHasFreezer()
	local iActivePlayer = Game.GetActivePlayer()
	local tTrait = MapModData.gPMMMTraits and MapModData.gPMMMTraits[iActivePlayer]
	return tTrait ~= nil and (tTrait.EnableFreezerSystem == true or tTrait.EnableFreezerSystem == 1)
end

--[port] Phase 4: read-only round trips to the gameplay script. Each clears the answer first, so a missing
--gameplay script (no Freezer civ in the game) leaves a default instead of a stale value.
local function GetNumAcademies(iPlayer)
	ttable[0] = nil
	LuaEvents.PMMMGetNumAcademies(iPlayer, ttable)
	return ttable[0] or 0
end

local function GetRevivalTurns(iPlayer, iMGKey)
	ttable[0] = nil
	ttable[1] = nil
	LuaEvents.PMMMGetFreezerRevivalTurns(iPlayer, iMGKey, ttable)
	return ttable[0] or 0, ttable[1] or 0
end

local function GetGriefSeeds(iPlayer)
	return (MapModData.PMMM and MapModData.PMMM.GriefSeeds and MapModData.PMMM.GriefSeeds[iPlayer]) or 0
end

--[port] Phase 4: the unit that carries the Grief Seed mission. A mission needs a unit that can still move this
--turn; the mission itself costs that unit nothing, but pushing it replaces the unit's current orders, so prefer
--the unit already selected, then an idle one, then any that can move.
local function FindMissionUnit(pPlayer)
	local pHead = UI.GetHeadSelectedUnit()
	if pHead and pHead:GetOwner() == pPlayer:GetID() and pHead:CanMove() and not pHead:IsDelayedDeath() then
		return pHead
	end
	local pFallback
	for pUnit in pPlayer:Units() do
		if pUnit:CanMove() and not pUnit:IsDelayedDeath() and not pUnit:IsTrade() then
			if pUnit:GetFortifyTurns() == 0 and not pUnit:IsAutomated() then
				return pUnit
			end
			pFallback = pFallback or pUnit
		end
	end
	return pFallback
end

function OnShowHide(bHide, bInit)
	if (not bHide) then
		if MapModData.gPMMMTraits and ActivePlayerHasFreezer() then
			Controls.MagicalGirlBox:SetHide(false)
			Controls.ExplanationBox:SetHide(false)
			Controls.NoMGsLabel:SetHide(true)
			Init()
			return
		end
	end
	LuaEvents.PMMMRefreshGriefSeedDisplay()
	Controls.MagicalGirlBox:SetHide(true)
	Controls.ExplanationBox:SetHide(true)
	Controls.NoMGsLabel:SetHide(false)
end
ContextPtr:SetShowHideHandler(OnShowHide)

function OnMagicalGirlClicked(iMGKey)
	local iPlayer = Game.GetActivePlayer()
	local pPlayer = Players[iPlayer]
	local tGirl = MapModData.PMMM and MapModData.PMMM.MagicalGirls and MapModData.PMMM.MagicalGirls[iMGKey]
	if not tGirl or tGirl.FreezerPlayer ~= iPlayer then
		Controls.ResultBox:SetHide(true)
		return
	end
	iCurrentMG = iMGKey
	local sNameCaps = string.upper(Locale.ConvertTextKey(tGirl.Name))
	Controls.SelectedMGNameLabel:SetText(sNameCaps)

	local iAcademies = GetNumAcademies(iPlayer)
	local iLeft, iDuration = GetRevivalTurns(iPlayer, iMGKey)
	Controls.RevivalTurnsLabel:LocalizeAndSetText("TXT_KEY_PMMM_UI_FREEZER_REVIVAL_TURNS", iLeft)
	Controls.NumAcademiesLabel:LocalizeAndSetText("TXT_KEY_PMMM_UI_FREEZER_NUM_ACADEMIES", iAcademies)
	Controls.RevivalDurationLabel:LocalizeAndSetText("TXT_KEY_PMMM_UI_FREEZER_REVIVAL_DURATION", iDuration)
	Controls.RevivalDescLabel:LocalizeAndSetText("TXT_KEY_PMMM_UI_FREEZER_REVIVAL_DESC", Locale.ConvertTextKey(tGirl.Name), tGirl.Level or 1, tGirl.SoulGem or 0)

	--Grief Seed Button
	local sTip = Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_USE_GRIEF_SEED_TT")
	if GetGriefSeeds(iPlayer) <= 0 then
		Controls.GriefSeedButton:SetDisabled(true)
		sTip = sTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_USE_GRIEF_SEED_NO_SEEDS_TT")
	elseif not pPlayer:IsTurnActive() or not FindMissionUnit(pPlayer) then
		Controls.GriefSeedButton:SetDisabled(true)
		sTip = sTip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_USE_GRIEF_SEED_NO_UNIT_TT")
	else
		Controls.GriefSeedButton:SetDisabled(false)
		Controls.GriefSeedButton:SetVoid1(iMGKey)
	end
	Controls.GriefSeedButton:SetToolTipString(sTip)

	Controls.ResultBox:SetHide(false)
end

--[port] Phase 4: push the Freezer Grief Seed mission on one of our own units. The gameplay hook spends the
--seed and moves the timer; this panel refreshes when gameplay fires PMMMRefreshFreezerPopup.
function OnGriefSeedButtonClicked(iMGKey)
	local pPlayer = Players[Game.GetActivePlayer()]
	if not pPlayer or not iGriefSeedMission then return end
	local pUnit = FindMissionUnit(pPlayer)
	if not pUnit then return end
	local pPrevious = UI.GetHeadSelectedUnit()
	UI.SelectUnit(pUnit)
	Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION, iGriefSeedMission, iMGKey, 0, 0, false, false)
	if pPrevious and pPrevious ~= pUnit then
		UI.SelectUnit(pPrevious)
	end
	Controls.GriefSeedButton:SetDisabled(true)
end

Controls.GriefSeedButton:RegisterCallback(Mouse.eLClick, OnGriefSeedButtonClicked)

function Init()
	-- [port] A23: this runs at file load, before the gameplay state has populated MapModData.PMMM
	if not MapModData.PMMM then
		return
	end
	g_InstanceManager:ResetInstances()
	local iPlayer = Game.GetActivePlayer()
	local iKeepSelected = iCurrentMG
	iCurrentMG = -1;

	local bAnyMagicalGirls;
	local bKeepSelected = false

	if MapModData.PMMM.MagicalGirls then
		--[port] Phase 4: list the girls in key order so the list does not reshuffle between refreshes.
		local tKeys = {}
		for k, v in pairs(MapModData.PMMM.MagicalGirls) do
			if v.FreezerPlayer == iPlayer then
				tKeys[#tKeys + 1] = k
			end
		end
		table.sort(tKeys)
		for _, k in ipairs(tKeys) do
			local v = MapModData.PMMM.MagicalGirls[k]
			bAnyMagicalGirls = true
			if k == iKeepSelected then bKeepSelected = true end
			local instance = g_InstanceManager:GetInstance()
			instance.MagicalGirlNameLabel:LocalizeAndSetText(v.Name)
			local iLeft = GetRevivalTurns(iPlayer, k)
			instance.MagicalGirlTurnsLabel:LocalizeAndSetText("TXT_KEY_PMMM_UI_FREEZER_LIST_TURNS", iLeft)
			instance.MagicalGirlTurnsLabel:EnableToolTip(true)
			instance.MagicalGirlTurnsLabel:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_LIST_TURNS_TT", Locale.ConvertTextKey(v.Name), iLeft, v.Level or 1, v.SoulGem or 0))

			instance.SubIconFrame:SetHide(true);
			if (v.OriginalOwner) then
				CivIconHookup(v.OriginalOwner, 32, instance.SubIcon, instance.SubIconBG, instance.SubIconShadow, true, true);
				instance.SubIconFrame:SetHide(false);
			end

			instance.SubIconFrame:EnableToolTip(true)
			instance.SubIcon:EnableToolTip(true)
			instance.SubIconBG:EnableToolTip(true)
			instance.SubIconShadow:EnableToolTip(true)

			-- [port] A23: Players[nil] -- only build the owner tooltip when there is an OriginalOwner
			if (v.OriginalOwner) then
				local sOwnerString = Players[v.OriginalOwner]:GetCivilizationAdjective()

				instance.SubIconFrame:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_ORIGINAL_OWNER_TT", Locale.ConvertTextKey(v.Name), sOwnerString))
				instance.SubIcon:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_ORIGINAL_OWNER_TT", Locale.ConvertTextKey(v.Name), sOwnerString))
				instance.SubIconBG:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_ORIGINAL_OWNER_TT", Locale.ConvertTextKey(v.Name), sOwnerString))
				instance.SubIconShadow:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_PMMM_UI_FREEZER_ORIGINAL_OWNER_TT", Locale.ConvertTextKey(v.Name), sOwnerString))
			end

			instance.MagicalGirlButton:SetVoid1(k)
			instance.MagicalGirlButton:RegisterCallback(Mouse.eLClick, OnMagicalGirlClicked)
		end
		Controls.MGListStack:CalculateSize()
		Controls.MGListStack:ReprocessAnchoring()
		Controls.MGScrollPanel:CalculateInternalSize()
		Controls.MGListLabel:SetHide(true)
	else
		Controls.MGListLabel:SetHide(false)
	end
	if not bAnyMagicalGirls then
		Controls.MGListLabel:SetHide(false)
	end
	--Keep the details of the girl being looked at, so a Grief Seed shows its effect in place.
	if bKeepSelected then
		OnMagicalGirlClicked(iKeepSelected)
	else
		Controls.ResultBox:SetHide(true)
	end
end

Init()

-- [port] A23: Init at load may bail out because MapModData.PMMM is not there yet -- run it again once the game is up
function OnLoadScreenCloseInit()
	Init()
end
Events.LoadScreenClose.Add(OnLoadScreenCloseInit)

--[port] Phase 4: gameplay fires this after a Grief Seed, a revival or a Capital capture; redraw if open.
function OnRefreshFreezerPopup()
	if not ContextPtr:IsHidden() and ActivePlayerHasFreezer() then
		Init()
	end
end
LuaEvents.PMMMRefreshFreezerPopup.Add(OnRefreshFreezerPopup)

--Timers move at every turn change.
function OnActivePlayerTurnStart()
	OnRefreshFreezerPopup()
end
Events.ActivePlayerTurnStart.Add(OnActivePlayerTurnStart)


--Add option to open this in the DiploCorner

function OnDiploCornerPopup()
	Show()
end

function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
  table.insert(additionalEntries, {
    text=Locale.ConvertTextKey("TXT_KEY_PMMM_UI_DIPLOCORNER_FREEZER"),
    call=OnDiploCornerPopup
  })
end

--Don't use the cached trait table since it has issues when first loading -- find it directly from the DB
-- [port] A23: every step of this chain can be nil in observer/autoplay
local pActivePlayer = Players[Game.GetActivePlayer()]
local leaderInfo = pActivePlayer and GameInfo.Leaders[pActivePlayer:GetLeaderType()]
local leaderTraitRow = leaderInfo and GameInfo.Leader_Traits("LeaderType ='" .. leaderInfo.Type .. "'")()
local trait = leaderTraitRow and GameInfo.Traits[leaderTraitRow.TraitType]

if trait and (trait.EnableFreezerSystem == true or trait.EnableFreezerSystem == 1) then
	LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries)
	LuaEvents.RequestRefreshAdditionalInformationDropdownEntries()
end

trait = nil --keep pointers to traits in the DB out of memory since it can cause issues
