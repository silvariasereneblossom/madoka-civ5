-- PMMMUUBootstrapper
-- Author: Vicevirtuoso
-- DateCreated: 6/17/2014 11:34:05 AM
--------------------------------------------------------------


--Currently, we will load all UUs regardless of whether or not a Civ which uses them is present (or even a Militaristic CS).
--It's rather easy for a mod Civ to get UUs from other Civs using Lua, so we don't want our UUs ending up useless in that case.

local gT = MapModData.gT
local iMaxCivs = GameDefines.MAX_MAJOR_CIVS

--set to true to enable print statements
local bDebug = false

function dprint(...)
  if (bDebug) then
    print(string.format(...))
  end
end

include("PMMMBubbleBomber.lua")
include("PMMMClockstopper.lua")
include("PMMMRosebowInfantry.lua")
include("PMMMTiroMusketeer.lua")

function OnSetXYUUFunctions(iPlayer, iUnit, iX, iY)
	if iPlayer < iMaxCivs then
		GrantNewPromotionOnImprovement(iPlayer, iUnit)
		GrantNewPromotionInCity(iPlayer, iUnit)
		BubbleBomber(iPlayer, iUnit)
		CheckTiroMusketeer(iPlayer, iUnit)
	end
end

function OnDoTurnUUFunctions(iPlayer)
	if iPlayer < iMaxCivs then
		for unit in Players[iPlayer]:Units() do
			local id = unit:GetID()
			GrantNewPromotionOnImprovement(iPlayer, id)
			GrantNewPromotionInCity(iPlayer, id)
			BubbleBomber(iPlayer, id)
			CheckTiroMusketeer(iPlayer, id)
		end
	end
end


function OnCaptureCompleteUUFunctions(iCapturedPlayer, bCapital, iX, iY, iCapturingPlayer, bConquest)
	if bConquest and iCapturingPlayer < iMaxCivs then
		Clockstopper(iCapturedPlayer, bCapital, iX, iY, iCapturingPlayer, bConquest)
	end
end