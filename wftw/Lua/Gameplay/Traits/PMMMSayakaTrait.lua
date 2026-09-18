-- Sayaka Trait Script
-- Author: Vicevirtuoso
-- DateCreated: 8/20/2013 12:04:47 AM
--------------------------------------------------------------

--[port] Phase 4: retired. Sayaka's old UA ("Orchestra for Justice") is replaced by Kyoshikyoku no Seigi
--(Rhapsody of Justice), design section 5. Its two effects are gone:
--  * Musician Prodigy points for kills (Traits.GreatPersonProgressFromKills), and
--  * the combat promotions for Tourism influence over the landowner (Traits.CombatBonusFromTourismInfluence,
--    PROMOTION_SAYAKA_EXOTIC ... _DOMINANT).
--SQL/Phase4/Sayaka.sql clears both columns, so PMMMTraitBootstrapper.lua, which includes this file only when
--one of them is set, no longer loads it. The new UA lives in
--Lua/Gameplay/MagicalGirls/Abilities/PMMMAbilitySayaka.lua, which is always loaded.
--
--The three entry points the bootstrapper calls are kept as empty functions so that nothing can call a nil
--global if this file is ever included again, and so that they no longer touch any promotion id.

include('PMMMGeneralFunctions.lua');

--[port] Phase 4: retired, kills no longer give Great Person points.
function GreatPersonProgressFromKills(iKiller, iKilled, iKilledUnit)
end

--[port] Phase 4: retired, no Tourism influence combat promotions.
function OnMoveTourismPromotionUpdate(iPlayer, iUnitID)
end

--[port] Phase 4: retired, no Tourism influence combat promotions.
function OnTurnTourismPromotionUpdate(iPlayer)
end
