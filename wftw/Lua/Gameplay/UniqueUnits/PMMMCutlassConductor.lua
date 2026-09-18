-- PMMMCutlassConductor
-- Author: Vicevirtuoso
-- DateCreated: 6/13/2014 1:32:50 AM
--------------------------------------------------------------

--[port] Phase 4: the Harmony system is retired. The Cutlass Conductor now replaces the Swordsman and earns
--Culture and Faith on kills through the data column UnitPromotions_YieldFromKills (SQL/Phase4/Sayaka.sql),
--so it needs no script. BUILDING_PMMM_CUTLASS_CONDUCTOR_DUMMY is deleted from the database and nothing here
--names it any more.
--
--PMMMUUBootstrapper.lua calls these three functions for every player, every turn, promotion and death, so
--they stay defined as empty functions.

include('PMMMGeneralFunctions.lua');

--[port] Phase 4: retired, levels no longer grant Harmony.
function AddHarmonyOnLevel(iPlayer, iUnit)
end

--[port] Phase 4: retired. PMMM.Harmony is never written now; drop any entry an older save still carries.
function ClearHarmonyOnDeath(iPlayer, iUnit)
	if PMMM and PMMM.Harmony then
		PMMM.Harmony[GetUnitSpecialID(iPlayer, iUnit)] = nil
	end
end

--[port] Phase 4: retired, garrisoned Conductors no longer place the Harmony dummy building.
function ExpendHarmony(iPlayer)
end
