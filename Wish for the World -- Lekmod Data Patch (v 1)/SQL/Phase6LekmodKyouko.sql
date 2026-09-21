--==============================================================================
-- Phase 6 Lekmod -- Kyouko trait-yield conversion (late data patch)
--==============================================================================
-- PRIVATE Lekmod port of Madoka Magica: Wish for the World (WFTW). Lekmod's
-- license permits personal-use modification. Not for distribution.
--
-- Lekmod v35 implements Trait_BuildingClassYieldChanges natively, naming the
-- value column 'Yield' where Community Patch uses 'YieldChange'. WFTW's
-- SQL/Phase4/Kyouko.sql inserts only YieldChange. Two coordinated fixes make
-- that file load unmodified AND work on Lekmod:
--   * The EARLY shim rebuilds the table with the identical schema plus
--     DEFAULT 0 on the native 'Yield', so Kyouko.sql's insert no longer
--     aborts on the NOT NULL constraint and the whole file runs; the row
--     lands with the live Yield = 0 (inert) and YieldChange = 1 (staged).
--   * THIS file then copies the staged CP-style value into Lekmod's live
--     column, so the Shrine +1 [ICON_FOOD] Food that Kyouko's trait promises
--     actually takes effect on Lekmod -- Lekmod's DLL reads 'Yield'.
--
-- Scoped to rows written through the staged column only: Lekmod's own rows
-- never have YieldChange set (the shim added that column after load), and
-- the WHERE on Yield = 0 keeps this idempotent -- the converted row no
-- longer matches on a re-run. Plain UPDATE, SQLite 3.7.17-safe.
--==============================================================================

-- Phase 6 Lekmod: staged YieldChange -> live Yield, for rows the shim's
-- DEFAULT 0 rebuild left inert (Kyouko's shrine: BUILDINGCLASS_SHRINE +1 Food)
UPDATE Trait_BuildingClassYieldChanges
SET Yield = YieldChange
WHERE YieldChange IS NOT NULL
  AND YieldChange <> 0
  AND Yield = 0;

--------------------------------------------------------------------------------
-- Intended end state (Kyouko's trait, TRAIT_GROWTH_SPEED_FROM_RELIGION):
--   TraitType          = TRAIT_GROWTH_SPEED_FROM_RELIGION
--   BuildingClassType   = BUILDINGCLASS_SHRINE
--   YieldType          = YIELD_FOOD
--   Yield              = 1   (Lekmod-live: read by Lekmod's DLL)
--   YieldChange        = 1   (CP-staged: parity for the future DLL port)
--------------------------------------------------------------------------------