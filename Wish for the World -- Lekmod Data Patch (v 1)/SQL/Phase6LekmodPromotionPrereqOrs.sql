--==============================================================================
-- Phase 6 Lekmod -- promotion-prereq relocation (late data patch)
--==============================================================================
-- PRIVATE Lekmod port of Madoka Magica: Wish for the World (WFTW). Lekmod's
-- license permits personal-use modification. Not for distribution.
--
-- Loads AFTER the WFTW mod (name "Wish for the World -- Lekmod Data Patch"
-- sorts after "Madoka Magica -- Wish for the World [BNW]").
--
-- Lekmod v35 deleted UnitPromotions.PromotionPrereq / PromotionPrereqOr1..9
-- and reads OR prerequisites exclusively from the link table
-- UnitPromotions_PromotionPrereqOrs (upstream/Lekmod/LEKMOD_DLL/
-- CvGameCoreDLL_Expansion2/CvPromotionClasses.cpp:630-655, built under
-- LEKMOD_RELOCATE_PROMOTION_PREREQ_ORS). The early shim restored the columns
-- as inert storage so WFTW's SQL/XML load unmodified; this file converts the
-- staged values into the link rows Lekmod's DLL actually reads.
--
-- Scope: the MG training trees in XML/CIV5UnitPromotions-Madoka.xml (Or1,
-- Or2 in four tier-3 rows), the social tree in SQL/Shared/MGDefines.sql
-- (CHARISMA_II, PATRIOTISM, TRAINER_II, TEACHER), and any promotion whose
-- staged Or-columns are non-null. The AND prerequisite (PromotionPrereq)
-- has NO reader in Lekmod's DLL at all (CvPromotionClasses.cpp:457-477 is
-- compiled out): WFTW writes none, so nothing needs converting -- but
-- AND-gated promotions would need a redesign (or an OR chain) to work.
--
-- Idempotent: DELETE-then-INSERT scoped to exactly the promotions converted.
-- SQLite 3.7.17-safe. The link table has no unique constraint, hence the
-- explicit DELETE (INSERT OR REPLACE would not deduplicate).
--==============================================================================

-- Phase 6 Lekmod: clear our conversions only (Lekmod's own link rows for its
-- own promotions are never touched: they never have staged Or-columns).
DELETE FROM UnitPromotions_PromotionPrereqOrs
WHERE PromotionType IN (SELECT Type FROM UnitPromotions
    WHERE PromotionPrereqOr1 IS NOT NULL OR PromotionPrereqOr2 IS NOT NULL
       OR PromotionPrereqOr3 IS NOT NULL OR PromotionPrereqOr4 IS NOT NULL
       OR PromotionPrereqOr5 IS NOT NULL OR PromotionPrereqOr6 IS NOT NULL
       OR PromotionPrereqOr7 IS NOT NULL OR PromotionPrereqOr8 IS NOT NULL
       OR PromotionPrereqOr9 IS NOT NULL);

-- Phase 6 Lekmod: Or1..Or9 staged columns -> native link rows
INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr1 FROM UnitPromotions WHERE PromotionPrereqOr1 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr2 FROM UnitPromotions WHERE PromotionPrereqOr2 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr3 FROM UnitPromotions WHERE PromotionPrereqOr3 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr4 FROM UnitPromotions WHERE PromotionPrereqOr4 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr5 FROM UnitPromotions WHERE PromotionPrereqOr5 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr6 FROM UnitPromotions WHERE PromotionPrereqOr6 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr7 FROM UnitPromotions WHERE PromotionPrereqOr7 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr8 FROM UnitPromotions WHERE PromotionPrereqOr8 IS NOT NULL;

INSERT INTO UnitPromotions_PromotionPrereqOrs (PromotionType, PrerequisitePromotion)
SELECT Type, PromotionPrereqOr9 FROM UnitPromotions WHERE PromotionPrereqOr9 IS NOT NULL;