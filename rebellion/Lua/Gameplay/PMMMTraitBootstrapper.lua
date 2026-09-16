-- PMMM Trait Bootstrapper
-- Author: Vicevirtuoso
-- DateCreated: 6/12/2014 12:35:21 PM
--------------------------------------------------------------

--This file loads trait scripts, but ONLY if a Civ with the trait in question is in the game.
--Why run trait scripts for Civs not in the game?

local gT = MapModData.gT

--set to true to enable print statements
local bDebug = false

function dprint(...)
  if (bDebug) then
    print(string.format(...))
  end
end

bIsHomura = false;
bIsSayaka = false;
bIsMami = false;
bIsKyouko = false;
bIsNagisa = false;
bIsUMadoka = false; 
bIsDHomura = false;

for iPlayer, pTrait in pairs(MapModData.gPMMMTraits) do
	if not bIsHomura then
		for row in GameInfo.Trait_PromotionAtHPThreshold() do
			if row.TraitType == MapModData.gPMMMTraits[iPlayer].Type then
				if row.PromotionType and row.Threshold > 0 then
					print("Loading Homura's trait script.")
					include('PMMMHomuraTrait.lua');
					bIsHomura = true;
				end
			end
		end
	end
	if not bIsSayaka then
		if MapModData.gPMMMTraits[iPlayer].GreatPersonProgressFromKills or MapModData.gPMMMTraits[iPlayer].CombatBonusFromTourismInfluence == 1 then
			print("Loading Sayaka's trait script.")
			include('PMMMSayakaTrait.lua');
			bIsSayaka = true;
		end
	end
	if not bIsMami then
		if MapModData.gPMMMTraits[iPlayer].CityStateCombatStrengthModTimes100 > 0 then
			print("Loading Mami's trait script.")
			include('PMMMMamiTrait.lua');
			bIsMami = true;
		end
	end
	if not bIsKyouko then
		if MapModData.gPMMMTraits[iPlayer].GrowthBonusFromWorldReligionTimes1000 > 0 then
			print("Loading Kyouko's trait script.")
			include('PMMMKyoukoTrait.lua');
			bIsKyouko = true;
		end
	end
	if not bIsNagisa then
		for row in GameInfo.Trait_PMMM_GoldenAgeResourceSpread() do
			if row.TraitType == MapModData.gPMMMTraits[iPlayer].Type then
				if row.ResourceType and row.ProbabilityPerTurn > 0 then
					print("Loading Nagisa's trait script.")
					include('PMMMNagisaTrait.lua');
					bIsNagisa = true;
					break
				end
			end
		end
	end
	if not bIsUMadoka then
		if MapModData.gPMMMTraits[iPlayer].MagicalGirlOnGreatPersonUse == 1 then
			print("Loading Ultimate Madoka's trait script.")
			include('PMMMUltimateMadokaTrait.lua');
			bIsUMadoka = true;
		end
	end
	if not bIsDHomura then
		if MapModData.gPMMMTraits[iPlayer].HappinessToMetEnemies > 0 or MapModData.gPMMMTraits[iPlayer].UnhappinessPerCivilizationMet > 0 or MapModData.gPMMMTraits[iPlayer].YieldBonusPerCivilizationMet > 0 then
			print("Loading Demon Homura's trait script.")
			include('PMMMDemonHomuraTrait.lua');
			bIsDHomura = true;
		end
	end
end


function OnDoTurnRunTraitScripts(iPlayer)
	if iPlayer < iMaxCivs then
		if bIsKyouko then
			GrowthPerCityFollowing(iPlayer)
		end
		if bIsMami then
			CityStateCombatStrengthUp(iPlayer)
		end
		if bIsSayaka then
			OnTurnTourismPromotionUpdate(iPlayer)
		end
		if bIsNagisa then
			NagisaGoldenAge(iPlayer)
		end
		if bIsUMadoka then
			MadokaTurnBegin(iPlayer)
		end
		if bIsDHomura then
			DemonHomuraUpdate(iPlayer)
		end
		if bIsHomura then
			OnHomuraDoTurn(iPlayer)
		end
	end
	if bIsHomura then
		HomuraTimeStopUpkeep(iPlayer)
	end
end

function OnSetXYRunTraitScripts(iPlayer, iUnit, iX, iY)
	if iPlayer < iMaxCivs then
		if bIsSayaka then
			OnMoveTourismPromotionUpdate(iPlayer, iUnit)
		end
		if bIsUMadoka then
			MadokaOnMoveOrSelectGPUpdate(iPlayer, iUnit)
		end
		if bIsHomura then
			OnHomuraSetXY(iPlayer, iUnit, iX, iY)
		end
	end
end

function OnUnitKilledInCombatRunTraitScripts(iKiller, iKilled, iKilledUnit)
	if iKiller < iMaxCivs then
		if bIsSayaka then
			GreatPersonProgressFromKills(iKiller, iKilled, iKilledUnit)
		end
	end
end

function OnCityCaptureCompleteRunTraitScripts(iCapturedPlayer, iCapital, iX, iY, iCapturingPlayer, iPopulation, bConquest)
	if bIsDHomura then
		IronCurtainWorkaround(iCapturedPlayer, iCapital, iX, iY, iCapturingPlayer, iPopulation, bConquest)
	end
end

function OnSetPopulationRunTraitScripts(iX, iY, iOld, iNew)
	if bIsKyouko then
		NewPopulationFaithGrowth(iX, iY, iOld, iNew)
	end
end

function OnLoadScreenCloseRunTraitScripts()
	if bIsHomura then
		OnHomuraEnteredGame(iPlayer, iUnit, iX, iY)
	end
end