-- PMMMDemonHomuraTrait
-- Author: Vicevirtuoso
-- DateCreated: 7/2/2014 12:57:46 PM
--------------------------------------------------------------


function IronCurtainWorkaround(iCapturedPlayer, iCapital, iX, iY, iCapturingPlayer, iPopulation, bConquest)
	local pCapturedPlayer = Players[iCapturedPlayer];
	local pCapturingPlayer = Players[iCapturingPlayer];
	local pCity = Map.GetPlot(iX, iY):GetPlotCity()
	if (pCapturingPlayer:IsAlive()) and bConquest == true then
		for policyInfo in GameInfo.Policies() do
			dprint(policyInfo.Type)
			if policyInfo.FreeBuildingOnConquest ~= nil then
				if pCapturingPlayer:HasPolicy(policyInfo.ID) then
					dprint("Player has policy with free building on conquest (" ..policyInfo.Type.. ")")
					local civType = GameInfo.Civilizations[pCapturingPlayer:GetCivilizationType()].Type
					dprint("civType: " ..civType)
					local buildingclassType = GameInfo.Buildings[GameInfoTypes[policyInfo.FreeBuildingOnConquest]].BuildingClass
					dprint("buildingclassType: " ..buildingclassType)
					for buildingInfo in GameInfo.Civilization_BuildingClassOverrides("CivilizationType ='" ..civType.. "'") do
						if buildingInfo.BuildingClassType == buildingclassType then
							dprint("Test successful")
							local pCity = Map.GetPlot(iX, iY):GetPlotCity();
							pCity:SetNumRealBuilding(GameInfoTypes[buildingInfo.BuildingType], 1)
							pCity:SetNumRealBuilding(GameInfoTypes[policyInfo.FreeBuildingOnConquest], 0)
							return
						end
					end
				end
			end
		end
	end
end

function DemonHomuraUpdate(iPlayer)
	if iPlayer == 63 then return end
	local pPlayer = Players[iPlayer];
	if not pPlayer:IsEverAlive() then
		return
	end
	if pPlayer:IsMinorCiv() then
		return
	end
	local pTraitType = GetTraitType(pPlayer);
	if pTraitType.HappinessToMetEnemies > 0 then
		dprint("Called for HappinessToMetEnemies script")
		for iEnemyPlayer, pEnemyPlayer in pairs(Players) do
			if pEnemyPlayer ~= pPlayer and pEnemyPlayer:IsAlive() then
				if iEnemyPlayer ~= 63 then
					if Teams[pPlayer:GetTeam()]:IsHasMet(pEnemyPlayer:GetTeam()) then
						pEnemyPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_DEMON_HOMURA_DUMMY_ENEMY_HAPPINESS, pTraitType.HappinessToMetEnemies)
						print ("Added " ..pTraitType.HappinessToMetEnemies.. " Happiness to " ..pEnemyPlayer:GetCivilizationShortDescription())
					end
				end
			end
		end
	end
	if pTraitType.UnhappinessPerCivilizationMet > 0 then
		local iNumCivs = 0;
		local iBonusAmount = 0;
		for iEnemyPlayer, pEnemyPlayer in pairs(Players) do
			if pEnemyPlayer ~= pPlayer and pEnemyPlayer:IsAlive() then
				if iEnemyPlayer ~= 63 then
					if not pEnemyPlayer:IsMinorCiv() then
						if Teams[pPlayer:GetTeam()]:IsHasMet(pEnemyPlayer:GetTeam()) then
							iNumCivs = iNumCivs + 1;
							for pTest in GameInfo.Trait_SpecificMetCivUnhappiness() do
								if pTest.TraitType == pTraitType.Type then
									if pTest.EnemyCivilizationType == GameInfo.Civilizations[pEnemyPlayer:GetCivilizationType()].Type then
										iBonusAmount = iBonusAmount + pTest.Unhappiness
										dprint("Additional " ..pTest.Unhappiness.. " unhappiness percent from meeting " ..pEnemyPlayer:GetCivilizationShortDescription())
									end
								end
							end
						end
					end
				end
			end
		end
		local iTotalBuildings = iNumCivs * pTraitType.UnhappinessPerCivilizationMet + iBonusAmount
		pPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_DEMON_HOMURA_DUMMY_UNHAPPINESS, iTotalBuildings)
		print ("Added " ..iTotalBuildings.. " Unhappiness percent to " ..pPlayer:GetCivilizationShortDescription())
	end
	if pTraitType.YieldBonusPerCivilizationMet > 0 then
		local iNumCivs = 0;
		local iBonusAmount = 0;			
		for iEnemyPlayer, pEnemyPlayer in pairs(Players) do
			if pEnemyPlayer ~= pPlayer and pEnemyPlayer:IsAlive() then
				if iEnemyPlayer ~= 63 then
					if not pEnemyPlayer:IsMinorCiv() then
						if Teams[pPlayer:GetTeam()]:IsHasMet(pEnemyPlayer:GetTeam()) then
							iNumCivs = iNumCivs + 1;
							for pTest in GameInfo.Trait_SpecificMetCivYieldBonuses() do
								if pTest.TraitType == pTraitType.Type then
									if pTest.EnemyCivilizationType == GameInfo.Civilizations[pEnemyPlayer:GetCivilizationType()].Type then
										iBonusAmount = iBonusAmount + pTest.YieldBonus
										dprint("Additional " ..pTest.YieldBonus.. " yield percent from meeting " ..pEnemyPlayer:GetCivilizationShortDescription())
									end
								end
							end
						end
					end
				end
			end
		end
		local iTotalBuildings = iNumCivs * pTraitType.YieldBonusPerCivilizationMet + iBonusAmount
		pPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes.BUILDING_PMMM_DEMON_HOMURA_DUMMY_YIELDS, iTotalBuildings)
		print ("Added " ..iTotalBuildings.. " Yield percent to " ..pPlayer:GetCivilizationShortDescription())
	end
end