-- TopPanelGriefSeedDisplay
-- Author: Vicevirtuoso
-- DateCreated: 7/1/2014 12:53:15 AM
--------------------------------------------------------------

--Based off of Gedemon's Revolutions code, which adds functionality to TopPanel.lua without actually modifying it.

function UpdateGriefSeedDisplay()
	-- [port] A23: looked up twice with no nil check
	local pInfoStack = ContextPtr:LookUpControl("/InGame/TopPanel/TopPanelInfoStack")
	if not pInfoStack then
		return
	end
	Controls.GriefSeedString:ChangeParent(pInfoStack)
	pInfoStack:ReprocessAnchoring()
	DoInitGriefSeedTooltips()
	RefreshGriefSeedDisplay()
end

Events.LoadScreenClose.Add(UpdateGriefSeedDisplay)

function DoInitGriefSeedTooltips()
	Controls.GriefSeedString:SetToolTipCallback( GriefSeedTipHandler );
end

local tipControlTable = {}
TTManager:GetTypeControlTable( "TooltipTypeTopPanel", tipControlTable )

function GriefSeedTipHandler(control)
	local iPlayer = Game:GetActivePlayer()
	local iGriefSeeds = MapModData.PMMM.GriefSeeds[iPlayer] or 0
	local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_TT_GRIEF_SEEDS", iGriefSeeds, MapModData.gPMMMGriefSeedRecoverAmount or 0)
	
	if(sText ~= "") then
		tipControlTable.TopPanelMouseover:SetHide(false)
		tipControlTable.TooltipLabel:SetText( sText )
	else
		tipControlTable.TopPanelMouseover:SetHide(true)
	end

	tipControlTable.TopPanelMouseover:DoAutoSize()
end

function RefreshGriefSeedDisplay()
	local iPlayer = Game:GetActivePlayer()
	if MapModData.gPMMMTraits and MapModData.gPMMMTraits[iPlayer] then -- [port] A23: gPMMMTraits may not exist yet
		if MapModData.gPMMMTraits[iPlayer].NoMagicalGirls == true or MapModData.gPMMMTraits[iPlayer].NoMagicalGirls == 1 then
			Controls.GriefSeedString:SetText("");
			return
		end
	end
	local sText = "[ICON_PMMM_GRIEF_SEED] "
	local iGriefSeeds = (MapModData.PMMM and MapModData.PMMM.GriefSeeds and MapModData.PMMM.GriefSeeds[iPlayer]) or 0 -- [port] A23: PMMM table may not exist yet
	if iGriefSeeds > 0 then
		sText = sText .."[COLOR_POSITIVE_TEXT]".. iGriefSeeds.."[ENDCOLOR]"
	else
		sText = sText.."0"
	end
	Controls.GriefSeedString:SetText(sText);
end

LuaEvents.PMMMRefreshGriefSeedDisplay.Add(RefreshGriefSeedDisplay)