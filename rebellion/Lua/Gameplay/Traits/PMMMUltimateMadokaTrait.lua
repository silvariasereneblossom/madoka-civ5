-- Ultimate Madoka Trait Script
-- Author: ViceVirtuoso
-- DateCreated: 6/12/2013 12:10:44 PM
--------------------------------------------------------------

tMadokaGreatPeople = {};

--Multiplayer flag to prevent MP desyncs
bIsMultiplayer = Game:IsNetworkMultiPlayer()


function InitializeMadokaTables()
	for iPlayer, pPlayer in pairs(Players) do
		if iPlayer ~= 63 then
			if pPlayer:IsEverAlive() and not pPlayer:IsMinorCiv() then
				local pTraitType = GetTraitType(pPlayer)
				if pTraitType.MagicalGirlOnGreatPersonUse == 1 then
					tMadokaGreatPeople[iPlayer] = {
						IsAlive = {},
						Name = {},
						XPosition = {},
						YPosition = {},
						Type = {},
					}
				end
			end
		end
	end
end

--Called by other functions to store Madoka's GP IDs, map location, and names
function MadokaGPInfoRefresh(iPlayer, iUnitID)
	local pPlayer = Players[iPlayer];
	local pUnit = pPlayer:GetUnitByID(iUnitID);
	tMadokaGreatPeople[iPlayer].IsAlive[iUnitID] = true;
	tMadokaGreatPeople[iPlayer].XPosition[iUnitID] = pUnit:GetX();
	tMadokaGreatPeople[iPlayer].YPosition[iUnitID] = pUnit:GetY();
	if (pUnit:HasName()) then
		tMadokaGreatPeople[iPlayer].Name[iUnitID] = pUnit:GetNameNoDesc();
	end
	tMadokaGreatPeople[iPlayer].Type[iUnitID] = pUnit:GetUnitClassType();
end

--Called by other functions to actually spawn the Magical Girl unit
function MadokaInitMagicalGirl(iPlayer, iUnitID)
	local pPlayer = Players[iPlayer];
	local iTeam = pPlayer:GetTeam();
	local pTeam = Teams[iTeam];
	local iUnitClass;
	if (ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY)) then --BNW active, checks for Writers and Musicians
		if (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_PROPHET.ID) then
			iUnitClass = GameInfoTypes.UNIT_PROPHET_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_SCIENTIST.ID) then
			iUnitClass = GameInfoTypes.UNIT_SCIENTIST_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_MERCHANT.ID) then
			iUnitClass = GameInfoTypes.UNIT_MERCHANT_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_ENGINEER.ID) then
			iUnitClass = GameInfoTypes.UNIT_ENGINEER_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_ARTIST.ID or tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_WRITER.ID or tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_MUSICIAN.ID) then
			iUnitClass = GameInfoTypes.UNIT_ARTIST_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.ID or tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_GREAT_ADMIRAL.ID) then
			iUnitClass = GameInfoTypes.UNIT_MILITARISTIC_MAGICAL_GIRL_1;
		else
			dprint("Invalid Unit Type for expended Great Person. Defaulting to generic MG")
			iUnitClass = GameInfoTypes.UNIT_GENERIC_MAGICAL_GIRL_1;
		end
	else --G&K active, no Writers/Musicians
		if (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_PROPHET.ID) then
			iUnitClass = GameInfoTypes.UNIT_PROPHET_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_SCIENTIST.ID) then
			iUnitClass = GameInfoTypes.UNIT_SCIENTIST_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_MERCHANT.ID) then
			iUnitClass = GameInfoTypes.UNIT_MERCHANT_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_ENGINEER.ID) then
			iUnitClass = GameInfoTypes.UNIT_ENGINEER_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_ARTIST.ID) then
			iUnitClass = GameInfoTypes.UNIT_ARTIST_MAGICAL_GIRL_1;
		elseif (tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.ID or tMadokaGreatPeople[iPlayer].Type[iUnitID] == GameInfo.UnitClasses.UNITCLASS_GREAT_ADMIRAL.ID) then
			iUnitClass = GameInfoTypes.UNIT_MILITARISTIC_MAGICAL_GIRL_1;
		else
		dprint("Invalid Unit Type for expended Great Person. Defaulting to generic MG")
		iUnitClass = GameInfoTypes.UNIT_GENERIC_MAGICAL_GIRL_1;
		end	
	end
	local eMagicalGirl = pPlayer:InitUnit(iUnitClass, tMadokaGreatPeople[iPlayer].XPosition[iUnitID], tMadokaGreatPeople[iPlayer].YPosition[iUnitID], UNITAI_ATTACK)
	eMagicalGirl = MagicalGirlUpgrade(pPlayer, eMagicalGirl, iUnitID)
	if (eMagicalGirl:GetPlot():IsWater()) then
		eMagicalGirl:Embark(eMagicalGirl:GetPlot());
	end
	local NameKey;
	if tMadokaGreatPeople[iPlayer].Name[iUnitID] ~= nil then
		--Attempt to use the feminized names from the WFTW mod
		local testNameKey = tMadokaGreatPeople[iPlayer].Name[iUnitID].."_PMMM_FEMALEREPLACE"
		if Locale.ConvertTextKey(testNameKey) ~= testNameKey then
			NameKey = testNameKey
		else
			NameKey = tMadokaGreatPeople[iPlayer].Name[iUnitID]
		end
	end
	if NameKey then
		eMagicalGirl:SetName(NameKey)
	end
	--give a notification to human player that it happened
	if (pPlayer == Players[Game.GetActivePlayer()]) then
		local sTitle = Locale.ConvertTextKey("TXT_KEY_PMMM_MG_CREATED_TITLE");
		local sText = "";
		if (tMadokaGreatPeople[iPlayer].Name[iUnitID] ~= nil) then
			sText = Locale.ConvertTextKey("TXT_KEY_PMMM_MG_CREATED_TEXT", Locale.ConvertTextKey(tMadokaGreatPeople[iPlayer].Name[iUnitID]));
		else
			sText = Locale.ConvertTextKey("TXT_KEY_PMMM_MG_CREATED_NONAME_TEXT");
		end
		pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GREAT_PERSON_ACTIVE_PLAYER, sText, sTitle, tMadokaGreatPeople[iPlayer].XPosition[iUnitID], tMadokaGreatPeople[iPlayer].YPosition[iUnitID], iUnitClass)
	end
	--if Madoka is a bloodthirsty dictator, went Autocracy, and has the Total War policy for +15XP on new units, the MG gets that XP
	local iPolicyXP = 0;
	for pPolicy in GameInfo.Policies() do
		if pPlayer:HasPolicy(pPolicy.ID) and pPolicy.FreeExperience > 0 then
			iPolicyXP = iPolicyXP + pPolicy.FreeExperience
		end
	end
	if iPolicyXP > 0 then
		eMagicalGirl:SetExperience(iPolicyXP)
	end
	--Remove the info of the GP which created the MG
	tMadokaGreatPeople[iPlayer].IsAlive[iUnitID] = nil;
	tMadokaGreatPeople[iPlayer].XPosition[iUnitID] = nil;
	tMadokaGreatPeople[iPlayer].YPosition[iUnitID] = nil;
	tMadokaGreatPeople[iPlayer].Name[iUnitID] = nil;
	tMadokaGreatPeople[iPlayer].Type[iUnitID] = nil;
end


function MagicalGirlUpgrade(pPlayer, pUnit)
	dprint("Begin MG upgrade test")
	local pTeam = Teams[pPlayer:GetTeam()];
	local iUnitType = pUnit:GetUnitType()
	for pOverride in GameInfo.Unit_MagicalGirlUpgrade() do
		dprint("Unit is: " ..GameInfo.Units[iUnitType].Type)
		dprint("Unit to test against: " ..pOverride.UnitType)
		if pOverride.UnitType == GameInfo.Units[iUnitType].Type then
			dprint("Unittype exists in MagicalGirlUpgrade call")
			if pTeam:IsHasTech(GameInfoTypes[GameInfo.Unit_MagicalGirlUpgrade("UnitType ='" ..GameInfo.Units[iUnitType].Type.. "'")().TechRequired]) then
				dprint("Has tech to upgrade")
				iUnitType = GameInfoTypes[GameInfo.Unit_MagicalGirlUpgrade("UnitType ='" ..GameInfo.Units[iUnitType].Type.. "'")().UpgradeUnitType]
			else
				break
			end
		end
	end
	if iUnitType == pUnit:GetUnitType() then return pUnit end
	local pNewUnit = pPlayer:InitUnit(iUnitType, pUnit:GetX(), pUnit:GetY(), UNITAI_ATTACK)
	pNewUnit:Convert(pUnit)
	--embark if on water
	if (pNewUnit:GetPlot():IsWater()) then
		pNewUnit:Embark(pNewUnit:GetPlot());
	end
	return pNewUnit
end

--Build GP infos for Madoka when the game loads
function OnGameLoad()
	if (UI:IsLoadedGame()) then
		for _, pPlayer in pairs(Player) do
			if pPlayer:IsEverAlive() and not pPlayer:IsMinorCiv() then
				local pTraitType = GetTraitType(pPlayer)
				if pTraitType.MagicalGirlOnGreatPersonUse == 1 then
					for pUnit in pPlayer:Units() do
						if (pUnit:IsGreatPerson()) then
							dprint("Great Person found.")
							local iUnitID = pUnit:GetID()
							MadokaGPInfoRefresh(iPlayer, iUnitID)
						end
					end
				end
			end
		end
	end
end

--Various beginning-of-turn functions
function MadokaTurnBegin(iPlayer)
	local pPlayer = Players[iPlayer];
	if pPlayer:IsEverAlive() and not pPlayer:IsMinorCiv() and iPlayer ~= 63 then
		local pTraitType = GetTraitType(pPlayer)
		if pTraitType.MagicalGirlOnGreatPersonUse == 1 then
			dprint("Beginning of Madoka's turn -- attempting to index Great People")
			for pUnit in pPlayer:Units() do
				--Update all existing GP's infos
				if (pUnit:IsGreatPerson()) and pUnit:GetOriginalOwner() == iPlayer then
					dprint("Great Person found.")
					local iUnitID = pUnit:GetID()
					MadokaGPInfoRefresh(iPlayer, iUnitID)
				end
				--Update strength of any MGs already in friendly territory
				if (pUnit:GetUnitCombatType() == GameInfo.UnitCombatInfos.UNITCOMBAT_MAGICALGIRL.ID) then
					local pPlot = pUnit:GetPlot();
					local pTeam = Teams[pPlayer:GetTeam()];
					if (pPlot:GetOwner() == iPlayer) then
						MagicalGirlUpgrade(pPlayer, pUnit)
					end
				end
			end
			--Give AI players MGs from last turn, since the end-of-turn function doesn't work for them
			--This also gives human players their MGs in Multiplayer games since ActivePlayerTurnEnd causes desyncs
			if (not pPlayer:IsHuman()) or (pPlayer:IsHuman() and bIsMultiplayer) then
				for iUnitID, bIsAlive in pairs(tMadokaGreatPeople[iPlayer].IsAlive) do
					dprint("Checking Great Person UnitID #" ..iUnitID.. "'s alive status")
					if bIsAlive == true then
						dprint(iUnitID.. " was alive last turn")
						local bIsStillAlive = false;
						if pPlayer:GetUnitByID(iUnitID) then
							dprint(iUnitID.. " still owned by Madoka")
							bIsStillAlive = true;
						else
							dprint(iUnitID.. " not owned by Madoka")
							for iLoopPlayer, pLoopPlayer in pairs(Players) do
								for unit in pLoopPlayer:Units() do
									if unit:GetOriginalOwner() == iPlayer then
										dprint("Unit that was owned by Madoka owned by other player")
										if unit:GetUnitClassType() == tMadokaGreatPeople[iPlayer].Type[iUnitID] then
											dprint(iUnitID .. " owned by an enemy player")
											bIsStillAlive = true;
											tMadokaGreatPeople[iPlayer].IsAlive[iUnitID] = nil;
											tMadokaGreatPeople[iPlayer].XPosition[iUnitID] = nil;
											tMadokaGreatPeople[iPlayer].YPosition[iUnitID] = nil;
											tMadokaGreatPeople[iPlayer].Name[iUnitID] = nil;
											tMadokaGreatPeople[iPlayer].Type[iUnitID] = nil;
											break
										end
									end
								end
								if bIsStillAlive == true then break end
							end						
						end
						if bIsStillAlive == false then
							dprint(iUnitID.. " is no longer alive")	
							MadokaInitMagicalGirl(iPlayer, iUnitID)
						end
					end
				end
			end
		end
	end
end

--Spawns MGs at end of turn for human players. Does not activate for AIs; they get theirs at the beginning of their next turn.
--Doesn't run in MP
function MadokaTurnEnd()
	local iPlayer = Game:GetActivePlayer()
	local pPlayer = Players[iPlayer];
	if pPlayer:IsAlive() and not pPlayer:IsMinorCiv() and iPlayer ~= 63 then
		local pTraitType = GetTraitType(pPlayer)
		if pTraitType.MagicalGirlOnGreatPersonUse == 1 then
			for iUnitID, bIsAlive in pairs(tMadokaGreatPeople[iPlayer].IsAlive) do
				dprint("Checking Great Person UnitID #" ..iUnitID.. "'s alive status")
				if bIsAlive == true then
					dprint(iUnitID.. " was alive last turn")
					local bIsStillAlive = false;
					if pPlayer:GetUnitByID(iUnitID) then
						dprint(iUnitID.. " still owned by Madoka")
						bIsStillAlive = true;
					else
						dprint(iUnitID.. " not owned by Madoka")
						for iLoopPlayer, pLoopPlayer in pairs(Players) do
							for unit in pLoopPlayer:Units() do
								if unit:GetOriginalOwner() == iPlayer then
									dprint("Unit that was owned by Madoka owned by other player")
									if unit:GetUnitClassType() == tMadokaGreatPeople[iPlayer].Type[iUnitID] then
										dprint(iUnitID .. " owned by an enemy player")
										bIsStillAlive = true;
										tMadokaGreatPeople[iPlayer].IsAlive[iUnitID] = nil;
										tMadokaGreatPeople[iPlayer].XPosition[iUnitID] = nil;
										tMadokaGreatPeople[iPlayer].YPosition[iUnitID] = nil;
										tMadokaGreatPeople[iPlayer].Name[iUnitID] = nil;
										tMadokaGreatPeople[iPlayer].Type[iUnitID] = nil;
										break
									end
								end
							end
							if bIsStillAlive == true then break end
						end						
					end
					if bIsStillAlive == false then
						dprint(iUnitID.. " is no longer alive")	
						MadokaInitMagicalGirl(iPlayer, iUnitID)
					end
				end
			end
		end
	end
end

--When a unit is selected or moved, call the info update function if it is Madoka's unit and a GP
function MadokaOnMoveOrSelectGPUpdate(iPlayer, iUnitID)
	if iPlayer ~= 63 then
		local pPlayer = Players[iPlayer];
		if pPlayer:IsEverAlive() and not pPlayer:IsMinorCiv() then
			local pTraitType = GetTraitType(pPlayer)
			if pTraitType.MagicalGirlOnGreatPersonUse == 1 then
				local pUnit = pPlayer:GetUnitByID(iUnitID)
				if pUnit then
					if pUnit:IsGreatPerson() and pUnit:GetOriginalOwner() == iPlayer then
						if (pUnit:GetX() > 0 and pUnit:GetY() > 0) then
							dprint("GP selected or moved by Madoka -- attempting to update information")
							MadokaGPInfoRefresh(iPlayer, iUnitID)
						end
					end
				end
			end
		end
	end
end


if not bIsMultiplayer then
	Events.ActivePlayerTurnEnd.Add(MadokaTurnEnd)
end

Events.UnitSelectionChanged.Add(MadokaOnMoveOrSelectGPUpdate)
Events.SequenceGameInitComplete.Add(InitializeMadokaTables)
Events.SequenceGameInitComplete.Add(OnGameLoad)
