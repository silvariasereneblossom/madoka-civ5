-- TopPanelFreezerDisplay
-- Author: Vicevirtuoso
-- DateCreated: 7/17/2014 1:47:19 PM
--------------------------------------------------------------

local ttable = {}

ContextPtr:SetHide(true)

local bIsActivePlayerPleiades = false -- [port] A23: default false rather than nil

--Don't use the cached trait table since it has issues when first loading -- find it directly from the DB
-- [port] A23: every step of this chain can be nil in observer/autoplay; also recomputed on active player change (hotseat)
function RecomputeIsActivePlayerPleiades()
	bIsActivePlayerPleiades = false
	local pActivePlayer = Players[Game:GetActivePlayer()]
	local leaderInfo = pActivePlayer and GameInfo.Leaders[pActivePlayer:GetLeaderType()]
	local leaderTraitRow = leaderInfo and GameInfo.Leader_Traits("LeaderType ='" .. leaderInfo.Type .. "'")()
	local trait = leaderTraitRow and GameInfo.Traits[leaderTraitRow.TraitType]

	if trait and trait.EnableFreezerSystem == 1 then
		bIsActivePlayerPleiades = true
	end

	trait = nil --keep pointers to traits in the DB out of memory since it can cause issues
end

RecomputeIsActivePlayerPleiades()


function UpdateFreezerDisplay()
	if bIsActivePlayerPleiades then
		-- [port] A23: looked up twice with no nil check
		local pInfoStack = ContextPtr:LookUpControl("/InGame/TopPanel/TopPanelInfoStack")
		if not pInfoStack then
			return
		end
		Controls.FreezerString:ChangeParent(pInfoStack)
		pInfoStack:ReprocessAnchoring()
		DoInitFreezerTooltips()
		RefreshFreezerDisplay()
	end
end

Events.LoadScreenClose.Add(UpdateFreezerDisplay)

function DoInitFreezerTooltips()
	Controls.FreezerString:SetToolTipCallback( FreezerTipHandler );
end

local tipControlTable = {}
TTManager:GetTypeControlTable( "TooltipTypeTopPanel", tipControlTable )

function FreezerTipHandler(control)
	if bIsActivePlayerPleiades then
		local iPlayer = Game:GetActivePlayer()
		-- [port] A23: the gameplay state may not answer these round trips -- clear and default instead of passing nil on
		ttable[0] = nil
		LuaEvents.PMMMGetFreezerCurrentStorage(iPlayer, ttable)
		local iCurFreezer = ttable[0] or 0
		ttable[0] = nil
		LuaEvents.PMMMGetFreezerStorageMax(iPlayer, ttable)
		local iMaxFreezer = ttable[0] or 0

		local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_UI_TOPPANEL_FREEZER_TT", iCurFreezer, iMaxFreezer)

		tipControlTable.TopPanelMouseover:SetHide(false)
		tipControlTable.TooltipLabel:SetText( sText )
		tipControlTable.TopPanelMouseover:DoAutoSize()
	end
end

function RefreshFreezerDisplay()
	if bIsActivePlayerPleiades then
		local iPlayer = Game:GetActivePlayer()
		-- [port] A23: clear ttable before each round trip and default a missing answer to -1
		ttable[0] = nil
		LuaEvents.PMMMGetFreezerCurrentStorage(iPlayer, ttable)
		local iCurFreezer = ttable[0] or -1
		ttable[0] = nil
		LuaEvents.PMMMGetFreezerStorageMax(iPlayer, ttable)
		local iMaxFreezer = ttable[0] or -1

		local sText;
		if iMaxFreezer > -1 and iCurFreezer > -1 then
			sText = "[ICON_PMMM_SOUL_GEM] "..string.format("%i/%i", iCurFreezer, iMaxFreezer)
		else
			sText = "FREEZER!"
		end
		Controls.FreezerString:SetText(sText);
	end
end

LuaEvents.SRTTRefreshFreezerDisplay.Add(RefreshFreezerDisplay)

Events.SerialEventUnitInfoDirty.Add(RefreshFreezerDisplay)

-- [port] A23: hotseat -- the active player can change to (or away from) Pleiades after load
function OnGameplaySetActivePlayer()
	RecomputeIsActivePlayerPleiades()
	if bIsActivePlayerPleiades then
		UpdateFreezerDisplay()
	else
		Controls.FreezerString:SetText("")
	end
end
Events.GameplaySetActivePlayer.Add(OnGameplaySetActivePlayer)



function OnClicked()
	LuaEvents.PMMMShowFreezerPopup()
end

Controls.FreezerString:RegisterCallback(Mouse.eLClick, OnClicked)