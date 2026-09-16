-- Rebellion Civpack Main Script
-- Author: Vicevirtuoso
-- DateCreated: 6/17/2014 11:33:29 AM
--------------------------------------------------------------

include("PlotIterators.lua")
include("PMMMDataStorage.lua")
include("PMMMUUBootstrapper.lua")
include("PMMMUBBootstrapper.lua")
include("PMMMTraitBootstrapper.lua")


--set to true to enable print statements
local bDebug = false

function dprint(...)
  if (bDebug) then
    print(string.format(...))
  end
end


--Compatibility with old Rebellion Civpack traits

function GetTraitType(pPlayer)
	local iPlayer = pPlayer:GetID()
	return MapModData.gPMMMTraits[iPlayer]
end

--All GameEvents/Events calls should be run here.

---------PlayerDoTurn------------------------------------------------------------------------------
GameEvents.PlayerDoTurn.Add(RunUBScripts)
GameEvents.PlayerDoTurn.Add(OnDoTurnUUFunctions)
GameEvents.PlayerDoTurn.Add(OnDoTurnRunTraitScripts)


---------UnitSetXY--------------------------------------------------------------------------------
GameEvents.UnitSetXY.Add(OnSetXYUUFunctions)
GameEvents.UnitSetXY.Add(OnSetXYRunTraitScripts)

--------UnitKilledInCombat------------------------------------------------------------------------
GameEvents.UnitKilledInCombat.Add(OnUnitKilledInCombatRunTraitScripts)

--------CityCaptureComplete------------------------------------------------------------------------
GameEvents.CityCaptureComplete.Add(OnCaptureCompleteUUFunctions)
GameEvents.CityCaptureComplete.Add(OnCityCaptureRunTraitScripts)

--------SetPopulation------------------------------------------------------------------------------
GameEvents.SetPopulation.Add(OnSetPopulationRunTraitScripts)

--------LoadScreenClose----------------------------------------------------------------------------
Events.LoadScreenClose.Add(OnLoadScreenCloseRunTraitScripts)