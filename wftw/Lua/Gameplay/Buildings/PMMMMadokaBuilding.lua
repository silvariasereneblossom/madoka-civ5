-- PMMMMadokaBuilding
-- [port] Phase 4: Mitakihara's Middle School (a National College replacement) gives a free Magical Girl
-- when it is completed. Design: docs/design/phase4-design-v1.md section 1.
--------------------------------------------------------------

include('PMMMGeneralFunctions.lua');

local iMiddleSchool = GameInfoTypes.BUILDING_PMMM_MIDDLE_SCHOOL
local iMagicalGirl = GameInfoTypes.UNIT_PMMM_MAGICAL_GIRL

--GameEvents.CityConstructed(iPlayer, iCity, iBuilding, bGold, bFaithOrCulture)
function MadokaMiddleSchoolConstructed(iPlayer, iCity, iBuilding, bGold, bFaith)
	if iBuilding ~= iMiddleSchool then return end
	if iPlayer >= GameDefines.MAX_MAJOR_CIVS then return end
	if not PlayerHasMagicalGirls(iPlayer) then return end

	local pPlayer = Players[iPlayer]
	local pCity = pPlayer:GetCityByID(iCity)
	if not pCity then return end

	--The spawn table is what OnCreatedMagicalGirl reads on UnitCreated; give her this city as her home
	--so she does not start homesick, then let the normal creation path do the rest.
	tMagicalGirlSpawnTable["HomeCity"] = GetUnitSpecialID(pCity:GetX(), pCity:GetY())
	local pGirl = pPlayer:InitUnit(iMagicalGirl, pCity:GetX(), pCity:GetY(), UNITAI_ATTACK)
	if pGirl then
		pGirl:JumpToNearestValidPlot()
		local sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_MIDDLE_SCHOOL_MG_TITLE")
		local sText = Locale.ConvertTextKey("TXT_KEY_PMMM_NOTIFICATION_MIDDLE_SCHOOL_MG_TEXT", pCity:GetName())
		pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER, sText, sTitle, pCity:GetX(), pCity:GetY())
	end
end
