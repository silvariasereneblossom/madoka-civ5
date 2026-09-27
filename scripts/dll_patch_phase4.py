#!/usr/bin/env python3
"""Apply the PMMM Phase 4 changes to a Community-Patch-DLL 5.4.6 checkout (idempotent).

Adds Devil Homura's Ai Yo trait columns and Mami's city soft cap to CvPlayer, CvCity and
CvPlayerCulture, and the seven trait columns to CvTraitEntry. Usage: python scripts/dll_patch_phase4.py [repo]
"""
import io
import sys
from pathlib import Path

REPO = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / "upstream" / "Community-Patch-DLL"
SRC = REPO / "CvGameCoreDLL_Expansion2"


def rd(p):
    return io.open(p, encoding="utf-8", errors="surrogateescape", newline="").read()


def wr(p, s):
    io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(s)


TAB = chr(9)


def NL(text):
    """The line ending this file uses."""
    return chr(13) + chr(10) if chr(13) + chr(10) in text else chr(10)


def once(s, old, new, label):
    if new in s:
        return s  # already applied
    n = s.count(old)
    if n != 1:
        raise SystemExit(f"anchor '{label}' matched {n} times")
    return s.replace(old, new, 1)


TRAIT_GETTERS = """// PMMM Phase 4: Devil Homura's Ai Yo and Mami's city cap
bool CvTraitEntry::IsPMMMIgnoreUnhappinessPenalties() const { return m_bPMMMIgnoreUnhappinessPenalties; }
int CvTraitEntry::GetPMMMUnhappinessPerBonusPercent() const { return m_iPMMMUnhappinessPerBonusPercent; }
int CvTraitEntry::GetPMMMUnhappinessBonusMax() const { return m_iPMMMUnhappinessBonusMax; }
bool CvTraitEntry::IsPMMMNoGoldenAges() const { return m_bPMMMNoGoldenAges; }
bool CvTraitEntry::IsPMMMNoIdeologyPressure() const { return m_bPMMMNoIdeologyPressure; }
int CvTraitEntry::GetPMMMCityCapThreshold() const { return m_iPMMMCityCapThreshold; }
int CvTraitEntry::GetPMMMCityCapUnhappinessStep() const { return m_iPMMMCityCapUnhappinessStep; }
"""

TRAIT_CACHE = """\t// PMMM Phase 4 columns (declared by the mod in SQL/Shared/MadokaTableUpdates.sql)
\tm_bPMMMIgnoreUnhappinessPenalties = kResults.GetBool("PMMMIgnoreUnhappinessPenalties");
\tm_iPMMMUnhappinessPerBonusPercent = kResults.GetInt("PMMMUnhappinessPerBonusPercent");
\tm_iPMMMUnhappinessBonusMax = kResults.GetInt("PMMMUnhappinessBonusMax");
\tm_bPMMMNoGoldenAges = kResults.GetBool("PMMMNoGoldenAges");
\tm_bPMMMNoIdeologyPressure = kResults.GetBool("PMMMNoIdeologyPressure");
\tm_iPMMMCityCapThreshold = kResults.GetInt("PMMMCityCapThreshold");
\tm_iPMMMCityCapUnhappinessStep = kResults.GetInt("PMMMCityCapUnhappinessStep");
"""

TRAIT_DECLS = """\t// PMMM (Madoka Magica: Wish for the World) Phase 4 trait columns
\tbool IsPMMMIgnoreUnhappinessPenalties() const;
\tint GetPMMMUnhappinessPerBonusPercent() const;
\tint GetPMMMUnhappinessBonusMax() const;
\tbool IsPMMMNoGoldenAges() const;
\tbool IsPMMMNoIdeologyPressure() const;
\tint GetPMMMCityCapThreshold() const;
\tint GetPMMMCityCapUnhappinessStep() const;
"""

TRAIT_MEMBERS = """\tbool m_bPMMMIgnoreUnhappinessPenalties;
\tint m_iPMMMUnhappinessPerBonusPercent;
\tint m_iPMMMUnhappinessBonusMax;
\tbool m_bPMMMNoGoldenAges;
\tbool m_bPMMMNoIdeologyPressure;
\tint m_iPMMMCityCapThreshold;
\tint m_iPMMMCityCapUnhappinessStep;
"""


def patch_traits():
    p = SRC / "CvTraitClasses.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    if "IsPMMMIgnoreUnhappinessPenalties" not in s:
        s = once(s, "\tbool IsNoConnectionUnhappiness() const;" + nl,
                 "\tbool IsNoConnectionUnhappiness() const;" + nl + TRAIT_DECLS.replace("\n", nl), "trait decls")
        # the member name exists twice (trait entry, then player traits); the entry's is the first
        key = "\tbool m_bNoConnectionUnhappiness;" + nl
        i = s.index(key) + len(key)
        s = s[:i] + TRAIT_MEMBERS.replace("\n", nl) + s[i:]
        wr(p, s)
    p = SRC / "CvTraitClasses.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    getter = "bool CvTraitEntry::IsNoConnectionUnhappiness() const" + nl + "{" + nl + "\treturn m_bNoConnectionUnhappiness;" + nl + "}" + nl
    s = once(s, getter, getter + TRAIT_GETTERS.replace("\n", nl), "trait getters")
    cache = '\tm_bNoConnectionUnhappiness = kResults.GetBool("NoConnectionUnhappiness");' + nl
    s = once(s, cache, cache + TRAIT_CACHE.replace("\n", nl), "trait cache")
    wr(p, s)


def patch_player_h():
    p = SRC / "CvPlayer.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\tbool IsEmpireSuperUnhappy() const;" + nl,
             "\tbool IsEmpireSuperUnhappy() const;" + nl +
             "\t// PMMM Phase 4 (Madoka Magica: Wish for the World): Ai Yo and the city soft cap, read from trait columns" + nl +
             "\tbool IsPMMMIgnoreUnhappinessPenalties() const;" + nl +
             "\tint GetPMMMUnhappinessBonusPercent() const;" + nl +
             "\tbool IsPMMMNoGoldenAges() const;" + nl +
             "\tbool IsPMMMNoIdeologyPressure() const;" + nl +
             "\tint GetPMMMCityCapUnhappiness() const;" + nl +
             "\tvoid PMMMRefreshTraitCache() const;" + nl, "h methods")
    s = once(s, "\tint m_iHappinessTotal;" + nl,
             "\tint m_iHappinessTotal;" + nl +
             "\t// PMMM Phase 4: derived from the leader's traits, rebuilt on demand, never serialized" + nl +
             "\tmutable int m_iPMMMTraitCacheLeader;" + nl +
             "\tmutable bool m_bPMMMIgnoreUnhappiness;" + nl +
             "\tmutable int m_iPMMMUnhappinessPerBonusPercent;" + nl +
             "\tmutable int m_iPMMMUnhappinessBonusMax;" + nl +
             "\tmutable bool m_bPMMMNoGoldenAges;" + nl +
             "\tmutable bool m_bPMMMNoIdeologyPressure;" + nl +
             "\tmutable int m_iPMMMCityCapThreshold;" + nl +
             "\tmutable int m_iPMMMCityCapStep;" + nl +
             "\tint m_iPMMMUnhappinessFromCitiesAndPop;" + nl, "h members")
    wr(p, s)


HELPERS = r'''//	--------------------------------------------------------------------------------
// PMMM Phase 4 (Madoka Magica: Wish for the World)
// Trait columns are summed over the leader's traits once per leader and cached. The cache is not
// serialized: it is rebuilt from the database the first time it is read after a load.
void CvPlayer::PMMMRefreshTraitCache() const
{
	const int iLeader = (int)getLeaderType();
	if (m_iPMMMTraitCacheLeader == iLeader)
		return;

	m_iPMMMTraitCacheLeader = iLeader;
	m_bPMMMIgnoreUnhappiness = false;
	m_iPMMMUnhappinessPerBonusPercent = 0;
	m_iPMMMUnhappinessBonusMax = 0;
	m_bPMMMNoGoldenAges = false;
	m_bPMMMNoIdeologyPressure = false;
	m_iPMMMCityCapThreshold = 0;
	m_iPMMMCityCapStep = 0;

	if (iLeader < 0 || !isMajorCiv())
		return;

	const CvLeaderHeadInfo& kLeader = getLeaderInfo();
	for (int iI = 0; iI < GC.getNumTraitInfos(); iI++)
	{
		if (!kLeader.hasTrait(iI))
			continue;
		CvTraitEntry* pTrait = GC.getTraitInfo((TraitTypes)iI);
		if (pTrait == NULL)
			continue;
		if (pTrait->IsPMMMIgnoreUnhappinessPenalties())
			m_bPMMMIgnoreUnhappiness = true;
		if (pTrait->IsPMMMNoGoldenAges())
			m_bPMMMNoGoldenAges = true;
		if (pTrait->IsPMMMNoIdeologyPressure())
			m_bPMMMNoIdeologyPressure = true;
		m_iPMMMUnhappinessPerBonusPercent = max(m_iPMMMUnhappinessPerBonusPercent, pTrait->GetPMMMUnhappinessPerBonusPercent());
		m_iPMMMUnhappinessBonusMax = max(m_iPMMMUnhappinessBonusMax, pTrait->GetPMMMUnhappinessBonusMax());
		if (pTrait->GetPMMMCityCapThreshold() > 0)
		{
			m_iPMMMCityCapThreshold = pTrait->GetPMMMCityCapThreshold();
			m_iPMMMCityCapStep = pTrait->GetPMMMCityCapUnhappinessStep();
		}
	}
}

bool CvPlayer::IsPMMMIgnoreUnhappinessPenalties() const
{
	PMMMRefreshTraitCache();
	return m_bPMMMIgnoreUnhappiness;
}

/// Ai Yo: +1% yields and combat strength per N unhappiness from cities and population, capped
int CvPlayer::GetPMMMUnhappinessBonusPercent() const
{
	PMMMRefreshTraitCache();
	if (m_iPMMMUnhappinessPerBonusPercent <= 0)
		return 0;
	int iBonus = m_iPMMMUnhappinessFromCitiesAndPop / m_iPMMMUnhappinessPerBonusPercent;
	if (m_iPMMMUnhappinessBonusMax > 0)
		iBonus = min(iBonus, m_iPMMMUnhappinessBonusMax);
	return max(iBonus, 0);
}

bool CvPlayer::IsPMMMNoGoldenAges() const
{
	PMMMRefreshTraitCache();
	return m_bPMMMNoGoldenAges;
}

bool CvPlayer::IsPMMMNoIdeologyPressure() const
{
	PMMMRefreshTraitCache();
	return m_bPMMMNoIdeologyPressure;
}

/// Mami's soft cap: every city past the threshold carries Step x (cities over the threshold) unhappiness,
/// so the total is Step x (over)^2. Puppets are not counted, in the manner of Venice.
int CvPlayer::GetPMMMCityCapUnhappiness() const
{
	PMMMRefreshTraitCache();
	if (m_iPMMMCityCapThreshold <= 0 || m_iPMMMCityCapStep <= 0)
		return 0;
	int iCounted = 0;
	int iLoop = 0;
	for (const CvCity* pLoopCity = firstCity(&iLoop); pLoopCity != NULL; pLoopCity = nextCity(&iLoop))
	{
		if (!pLoopCity->IsPuppet())
			iCounted++;
	}
	const int iOver = iCounted - m_iPMMMCityCapThreshold;
	if (iOver <= 0)
		return 0;
	return m_iPMMMCityCapStep * iOver * iOver;
}

'''


def patch_player_cpp():
    p = SRC / "CvPlayer.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\t, m_iHappinessTotal()" + nl,
             "\t, m_iHappinessTotal()" + nl +
             "\t, m_iPMMMTraitCacheLeader(-2)" + nl + "\t, m_bPMMMIgnoreUnhappiness(false)" + nl +
             "\t, m_iPMMMUnhappinessPerBonusPercent(0)" + nl + "\t, m_iPMMMUnhappinessBonusMax(0)" + nl +
             "\t, m_bPMMMNoGoldenAges(false)" + nl + "\t, m_bPMMMNoIdeologyPressure(false)" + nl +
             "\t, m_iPMMMCityCapThreshold(0)" + nl + "\t, m_iPMMMCityCapStep(0)" + nl +
             "\t, m_iPMMMUnhappinessFromCitiesAndPop(0)" + nl, "ctor")

    guard = ("\t// PMMM Phase 4: Ai Yo removes every penalty tied to unhappiness" + nl +
             "\tif (IsPMMMIgnoreUnhappinessPenalties())" + nl + "\t\treturn false;" + nl + nl)
    for fn in ("bool CvPlayer::IsEmpireUnhappy() const", "bool CvPlayer::IsEmpireVeryUnhappy() const",
               "bool CvPlayer::IsEmpireSuperUnhappy() const"):
        s = once(s, fn + nl + "{" + nl, fn + nl + "{" + nl + guard, fn)

    s = once(s, "int CvPlayer::GetUnhappinessCombatStrengthPenalty() const" + nl + "{" + nl,
             "int CvPlayer::GetUnhappinessCombatStrengthPenalty() const" + nl + "{" + nl +
             "\t// PMMM Phase 4: Ai Yo turns unhappiness into strength instead (a positive value here is a bonus)" + nl +
             "\tif (IsPMMMIgnoreUnhappinessPenalties())" + nl + "\t\treturn GetPMMMUnhappinessBonusPercent();" + nl + nl,
             "combat")

    s = once(s, "\t\tiUnhappiness += GetUnhappinessFromCityPopulation(pAssumeCityAnnexed, pAssumeCityPuppeted);" + nl,
             "\t\tiUnhappiness += GetUnhappinessFromCityPopulation(pAssumeCityAnnexed, pAssumeCityPuppeted);" + nl +
             "\t\t// PMMM Phase 4: Ai Yo scales on unhappiness from cities and population (count, captured count, population, occupied)" + nl +
             "\t\tint iPMMMCitiesAndPopTimes100 = iUnhappiness;" + nl, "pop")
    s = once(s, "\t\tiUnhappiness += GetUnhappinessFromOccupiedCities(pAssumeCityAnnexed, pAssumeCityPuppeted);" + nl,
             "\t\tint iPMMMOccupiedTimes100 = GetUnhappinessFromOccupiedCities(pAssumeCityAnnexed, pAssumeCityPuppeted);" + nl +
             "\t\tiUnhappiness += iPMMMOccupiedTimes100;" + nl +
             "\t\tiPMMMCitiesAndPopTimes100 += iPMMMOccupiedTimes100;" + nl, "occupied")
    s = once(s, "\t\tiUnhappiness += GetUnhappinessFromUnits();" + nl + nl + "\t\tiUnhappiness /= 100;" + nl,
             "\t\tiUnhappiness += GetUnhappinessFromUnits();" + nl + nl +
             "\t\t// PMMM Phase 4: Mami's soft cap on cities" + nl +
             "\t\tiUnhappiness += GetPMMMCityCapUnhappiness() * 100;" + nl + nl +
             "\t\t// Only the real state is remembered, never an AI what-if about annexing or puppeting a city" + nl +
             "\t\tif (pAssumeCityAnnexed == NULL && pAssumeCityPuppeted == NULL)" + nl +
             "\t\t\tm_iPMMMUnhappinessFromCitiesAndPop = iPMMMCitiesAndPopTimes100 / 100;" + nl + nl +
             "\t\tiUnhappiness /= 100;" + nl, "cap")

    s = once(s, "void CvPlayer::changeGoldenAgeTurns(int iChange, bool bFree)" + nl + "{" + nl,
             "void CvPlayer::changeGoldenAgeTurns(int iChange, bool bFree)" + nl + "{" + nl +
             "\t// PMMM Phase 4: Ai Yo, never a Golden Age from any source" + nl +
             "\tif (iChange > 0 && IsPMMMNoGoldenAges())" + nl + "\t\treturn;" + nl + nl, "ga turns")
    s = once(s, "void CvPlayer::ChangeGoldenAgeProgressMeterTimes100(int iChange)" + nl + "{" + nl,
             "void CvPlayer::ChangeGoldenAgeProgressMeterTimes100(int iChange)" + nl + "{" + nl +
             "\tif (iChange > 0 && IsPMMMNoGoldenAges())" + nl + "\t\treturn;" + nl + nl, "ga meter")

    anchor = "/// Uprisings pop up if the empire is Very Unhappy" + nl
    s = once(s, anchor, HELPERS.replace("\n", nl) + anchor, "helpers")
    wr(p, s)


def patch_city_cpp():
    p = SRC / "CvCity.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    old = ("\tint iModifier = iTempMod;" + nl + "\tif (toolTipSink)" + nl +
           "\t\tGC.getGame().BuildProdModHelpText(toolTipSink, \"TXT_KEY_YIELD_MOD_BUILDINGS\", iTempMod);" + nl)
    s = once(s, old, old + nl +
             "\t// PMMM Phase 4: Ai Yo, yields grow with unhappiness from cities and population" + nl +
             "\tconst int iPMMMAiYo = kOwner.GetPMMMUnhappinessBonusPercent();" + nl +
             "\tif (iPMMMAiYo != 0)" + nl + "\t{" + nl + "\t\tiModifier += iPMMMAiYo;" + nl +
             "\t\tif (toolTipSink)" + nl +
             "\t\t\tGC.getGame().BuildProdModHelpText(toolTipSink, \"TXT_KEY_PMMM_YIELD_MOD_AI_YO\", iPMMMAiYo);" + nl +
             "\t}" + nl, "yield")
    wr(p, s)


def patch_culture_cpp():
    p = SRC / "CvCultureClasses.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    old = "int CvPlayerCulture::GetPublicOpinionUnhappiness() const" + nl + "{" + nl + "\treturn m_iOpinionUnhappiness;"
    s = once(s, old,
             "int CvPlayerCulture::GetPublicOpinionUnhappiness() const" + nl + "{" + nl +
             "\t// PMMM Phase 4: Ai Yo, immune to ideology pressure" + nl +
             "\tif (m_pPlayer && m_pPlayer->IsPMMMNoIdeologyPressure())" + nl + "\t\treturn 0;" + nl + nl +
             "\treturn m_iOpinionUnhappiness;", "opinion")
    wr(p, s)


def patch_clara_doll_tag(src=None):
    """2026-09-22 ruling: a Clara Doll keeps the Magical Girl promotion tree (and its era scaling) through every
    upgrade. The tag is PROMOTION_PMMM_CLARA_DOLL, which upgrades carry over; the DLL half is an optional
    "treat this unit's promotion tree as X" argument on the promotion-validity helpers, passed by
    CvUnit::isPromotionValid when the unit carries the tag. Shared by both DLLs: Lekmod calls this with its own
    source directory and ships the result as dll/lekmod-wftw-claradoll.patch."""
    src = SRC if src is None else Path(src)

    p = src / "CvGameCoreUtils.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    if "ePromotionClassOverride" not in s:
        s = s.replace("bool IsPromotionValidForUnitCombatType(PromotionTypes ePromotion, UnitTypes eUnit);",
                      "bool IsPromotionValidForUnitCombatType(PromotionTypes ePromotion, UnitTypes eUnit, UnitCombatTypes ePromotionClassOverride = NO_UNITCOMBAT);")
        s = s.replace("bool isPromotionValid(PromotionTypes ePromotion, UnitTypes eUnit, bool bLeader, bool bTestingPrereq=false);",
                      "bool isPromotionValid(PromotionTypes ePromotion, UnitTypes eUnit, bool bLeader, bool bTestingPrereq=false, UnitCombatTypes ePromotionClassOverride = NO_UNITCOMBAT);")
        wr(p, s)

    p = src / "CvGameCoreUtils.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    if "ePromotionClassOverride" not in s:
        s = once(s, "bool IsPromotionValidForUnitCombatType(PromotionTypes ePromotion, UnitTypes eUnit)" + nl,
                 "bool IsPromotionValidForUnitCombatType(PromotionTypes ePromotion, UnitTypes eUnit, UnitCombatTypes ePromotionClassOverride)" + nl, "utils combat sig")
        # the promotion tree this check uses: the unit's own, or the caller's override (PMMM Clara Doll tag)
        for old in ("promotionInfo->GetUnitCombatClass(unitInfo->GetUnitPromotionType())",
                    "promotionInfo->GetUnitCombatClass(unitInfo->GetUnitCombatType())"):
            if old in s:
                s = s.replace(old, "promotionInfo->GetUnitCombatClass(ePromotionClassOverride != NO_UNITCOMBAT ? (int)ePromotionClassOverride : " + old[old.index("(") + 1:-1] + ")", 1)
                break
        s = once(s, "bool isPromotionValid(PromotionTypes ePromotion, UnitTypes eUnit, bool bLeader, bool bTestingPrereq)" + nl,
                 "bool isPromotionValid(PromotionTypes ePromotion, UnitTypes eUnit, bool bLeader, bool bTestingPrereq, UnitCombatTypes ePromotionClassOverride)" + nl, "utils valid sig")
        # pass the override down: the combat-class test and every prerequisite recursion
        s = s.replace("::IsPromotionValidForUnitCombatType(ePromotion, eUnit)", "::IsPromotionValidForUnitCombatType(ePromotion, eUnit, ePromotionClassOverride)")
        s = s.replace(", eUnit, bLeader, true)", ", eUnit, bLeader, true, ePromotionClassOverride)")
        wr(p, s)

    p = src / "CvUnit.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    if "PMMM Clara Doll tag" not in s:
        override = ("\t// PMMM Clara Doll tag: a unit carrying it levels through the Magical Girl tree on any chassis" + nl +
                    "\t// it upgrades into (promotions survive upgrades, so the tag rides along)." + nl +
                    "\tstatic PromotionTypes ePMMMClaraDoll = (PromotionTypes)GC.getInfoTypeForString(\"PROMOTION_PMMM_CLARA_DOLL\", true);" + nl +
                    "\tstatic UnitCombatTypes ePMMMMagicalGirl = (UnitCombatTypes)GC.getInfoTypeForString(\"UNITCOMBAT_MAGICALGIRL\", true);" + nl +
                    "\tUnitCombatTypes ePMMMOverride = NO_UNITCOMBAT;" + nl +
                    "\tif (ePMMMClaraDoll != NO_PROMOTION && ePMMMMagicalGirl != NO_UNITCOMBAT && isHasPromotion(ePMMMClaraDoll))" + nl +
                    "\t\tePMMMOverride = ePMMMMagicalGirl;" + nl + nl)
        for old, new in (("\tif(!::isPromotionValid(ePromotion, getUnitType(), true))" + nl,
                          override + "\tif(!::isPromotionValid(ePromotion, getUnitType(), true, false, ePMMMOverride))" + nl),
                         ("\tif(!::isPromotionValid(ePromotion, getUnitType(), true/*bLeader*/))" + nl,
                          override + "\tif(!::isPromotionValid(ePromotion, getUnitType(), true/*bLeader*/, false, ePMMMOverride))" + nl)):
            if old in s:
                s = once(s, old, new, "unit promotion override")
                break
        wr(p, s)


def patch_ai_yo_culture(src=None):
    """2026-09-27 ruling: happiness a policy or ideology tenet would give Ai Yo becomes twice as much Culture
    instead. Trait column PMMMPolicyHappinessToCulture. The happiness itself is suppressed (it is inert for her
    anyway: her bonus reads gross unhappiness from cities and population, not the net figure), and the Culture is
    added next to the engine's own excess-happiness-to-Culture component.

    CP applies policy happiness per city (CvCity) while Lekmod applies it on the player (CvPlayer), so the
    suppression differs; everything else is identical. As with the other steps, insertions sit at the boundaries
    of blocks earlier steps inserted, never inside them."""
    src = SRC if src is None else Path(src)

    p = src / "CvTraitClasses.h"; s = rd(p); nl = NL(s)
    s = once(s, TAB + "bool IsPMMMCannotAllyCityStates() const;" + nl,
             TAB + "bool IsPMMMCannotAllyCityStates() const;" + nl + TAB + "bool IsPMMMPolicyHappinessToCulture() const;" + nl, "trait h decls 3")
    s = once(s, TAB + "bool m_bPMMMCannotAllyCityStates;" + nl,
             TAB + "bool m_bPMMMCannotAllyCityStates;" + nl + TAB + "bool m_bPMMMPolicyHappinessToCulture;" + nl, "trait h members 3")
    wr(p, s)

    p = src / "CvTraitClasses.cpp"; s = rd(p); nl = NL(s)
    s = once(s, "bool CvTraitEntry::IsPMMMCannotAllyCityStates() const { return m_bPMMMCannotAllyCityStates; }" + nl,
             "bool CvTraitEntry::IsPMMMCannotAllyCityStates() const { return m_bPMMMCannotAllyCityStates; }" + nl +
             "bool CvTraitEntry::IsPMMMPolicyHappinessToCulture() const { return m_bPMMMPolicyHappinessToCulture; }" + nl, "trait getters 3")
    s = once(s, TAB + 'm_bPMMMCannotAllyCityStates = kResults.GetBool("PMMMCannotAllyCityStates");' + nl,
                TAB + 'm_bPMMMCannotAllyCityStates = kResults.GetBool("PMMMCannotAllyCityStates");' + nl +
                TAB + 'm_bPMMMPolicyHappinessToCulture = kResults.GetBool("PMMMPolicyHappinessToCulture");' + nl, "trait cache 3")
    ctor = TAB + "m_bPMMMCannotAllyCityStates(false)," + nl
    if ctor in s:   # Lekmod initialises trait members in the constructor
        s = once(s, ctor, ctor + TAB + "m_bPMMMPolicyHappinessToCulture(false)," + nl, "trait ctor 3")
    wr(p, s)

    p = src / "CvPlayer.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    # CP keeps the 2026-09-22 flags in their own diplomacy cache; the Lekmod port put them in the main one, so
    # the anchors differ per tree. The code inserted is the same: this flag always gets its own small cache.
    decl_anchor = ("\tvoid PMMMRefreshDiplomacyTraitCache() const;" + nl
                   if "PMMMRefreshDiplomacyTraitCache" in s else "\tbool IsPMMMCannotAllyCityStates() const;" + nl)
    s = once(s, decl_anchor,
             decl_anchor +
             "\tbool IsPMMMPolicyHappinessToCulture() const;" + nl +
             "\tint GetPMMMPolicyHappiness() const;" + nl +
             "\tint GetPMMMCultureFromPolicyHappinessTimes100() const;" + nl +
             "\tvoid PMMMRefreshCultureTraitCache() const;" + nl, "player h decls 3")
    s = once(s, "\tmutable bool m_bPMMMCannotAllyCityStates;" + nl,
             "\tmutable bool m_bPMMMCannotAllyCityStates;" + nl +
             "\tmutable int m_iPMMMCultureCacheLeader;" + nl +
             "\tmutable bool m_bPMMMPolicyHappinessToCulture;" + nl, "player h members 3")
    wr(p, s)

    p = src / "CvPlayer.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\t, m_bPMMMCannotAllyCityStates(false)" + nl,
             "\t, m_bPMMMCannotAllyCityStates(false)" + nl + "\t, m_iPMMMCultureCacheLeader(-2)" + nl +
             "\t, m_bPMMMPolicyHappinessToCulture(false)" + nl, "player ctor 3")
    # This flag gets its own cache rather than joining the diplomacy one: adding a line inside that block would
    # break the contiguity its own step checks for, and it would insert a second copy of itself.
    # Anchored on the START of the 2026-09-22 diplomacy block: inserting after that block's
    # last line would sit between it and the HELPERS block, with the same result.
    dip = ("//" + TAB + "--------------------------------------------------------------------------------" + nl +
           "// PMMM Ai Yo, 2026-09-22 ruling: no Declarations of Friendship, never a City-State's ally." + nl)
    if dip not in s:    # the Lekmod port writes those accessors without the banner comment
        dip = "/// Ai Yo: no Declarations of Friendship, either way" + nl
    s = once(s, dip,
             "/// Ai Yo: the happiness her policies and ideology tenets would grant" + nl +
             "int CvPlayer::GetPMMMPolicyHappiness() const" + nl + "{" + nl +
             TAB + "int iHappiness = GetPlayerPolicies()->GetNumericModifier(POLICYMOD_EXTRA_HAPPINESS);" + nl +
             TAB + "iHappiness += getNumCities() * GetPlayerPolicies()->GetNumericModifier(POLICYMOD_EXTRA_HAPPINESS_PER_CITY);" + nl +
             TAB + "return max(iHappiness, 0);" + nl + "}" + nl + nl +
             "/// Ai Yo: twice that happiness, as Culture per turn" + nl +
             "int CvPlayer::GetPMMMCultureFromPolicyHappinessTimes100() const" + nl + "{" + nl +
             TAB + "if (!IsPMMMPolicyHappinessToCulture())" + nl + TAB + TAB + "return 0;" + nl + nl +
             TAB + "return GetPMMMPolicyHappiness() * 2 * 100;" + nl + "}" + nl + nl +
             "/// Ai Yo's Culture conversion flag, cached per leader and never serialized" + nl +
             "void CvPlayer::PMMMRefreshCultureTraitCache() const" + nl + "{" + nl +
             TAB + "const int iLeader = (int)getLeaderType();" + nl +
             TAB + "if (m_iPMMMCultureCacheLeader == iLeader)" + nl + TAB + TAB + "return;" + nl + nl +
             TAB + "m_iPMMMCultureCacheLeader = iLeader;" + nl +
             TAB + "m_bPMMMPolicyHappinessToCulture = false;" + nl +
             TAB + "if (iLeader < 0 || !isMajorCiv())" + nl + TAB + TAB + "return;" + nl + nl +
             TAB + "const CvLeaderHeadInfo& kLeader = getLeaderInfo();" + nl +
             TAB + "for (int iI = 0; iI < GC.getNumTraitInfos(); iI++)" + nl + TAB + "{" + nl +
             TAB + TAB + "if (!kLeader.hasTrait(iI))" + nl + TAB + TAB + TAB + "continue;" + nl +
             TAB + TAB + "CvTraitEntry* pTrait = GC.getTraitInfo((TraitTypes)iI);" + nl +
             TAB + TAB + "if (pTrait != NULL && pTrait->IsPMMMPolicyHappinessToCulture())" + nl +
             TAB + TAB + TAB + "m_bPMMMPolicyHappinessToCulture = true;" + nl +
             TAB + "}" + nl + "}" + nl + nl +
             "bool CvPlayer::IsPMMMPolicyHappinessToCulture() const" + nl + "{" + nl +
             TAB + "PMMMRefreshCultureTraitCache();" + nl + TAB + "return m_bPMMMPolicyHappinessToCulture;" + nl + "}" + nl + nl +
             dip, "player culture accessors")
    # add the Culture, next to the engine's own excess-happiness component
    cp_line = "\tiTmp = GetJONSCulturePerTurnFromExcessHappinessTimes100();" + nl
    lek_line = "\tiCulturePerTurn += GetJONSCulturePerTurnFromExcessHappinessTimes100();" + nl
    if cp_line in s:
        s = once(s, cp_line, "\t// PMMM Ai Yo: the happiness her policies would have given, as Culture" + nl +
                 "\tiTmp = GetPMMMCultureFromPolicyHappinessTimes100();" + nl +
                 "\tiCulturePerTurn += iTmp;" + nl +
                 "\tGC.getGame().BuildYieldTimes100HelpText(toolTipSink, \"TXT_KEY_TP_CULTURE_FROM_HAPPINESS\", iTmp, \"\");" + nl + nl +
                 cp_line, "cp culture add")
    else:
        s = once(s, lek_line, lek_line + nl +
                 "\t// PMMM Ai Yo: the happiness her policies would have given, as Culture" + nl +
                 "\tiCulturePerTurn += GetPMMMCultureFromPolicyHappinessTimes100();" + nl, "lekmod culture add")
        # Lekmod keeps policy happiness on the player: suppress it there
        s = once(s, "int CvPlayer::GetHappinessFromPolicies() const" + nl + "{" + nl,
                 "int CvPlayer::GetHappinessFromPolicies() const" + nl + "{" + nl +
                 "\t// PMMM Ai Yo: converted to Culture instead (GetPMMMCultureFromPolicyHappinessTimes100)" + nl +
                 "\tif (IsPMMMPolicyHappinessToCulture())" + nl + "\t\treturn 0;" + nl + nl, "lekmod happiness off")
    wr(p, s)

    # CP keeps policy happiness on the city: suppress it there
    p = src / "CvCity.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    old = "\t\tiTotalHappiness += kPlayer.GetPlayerPolicies()->GetNumericModifier(POLICYMOD_EXTRA_HAPPINESS);" + nl
    if old in s:
        s = once(s, old, "\t\t// PMMM Ai Yo: her policy happiness becomes Culture instead" + nl +
                 "\t\tif (!kPlayer.IsPMMMPolicyHappinessToCulture())" + nl + "\t" + old, "cp city happiness capital")
        old2 = ("\tiTotalHappiness += kPlayer.GetPlayerPolicies()->GetNumericModifier(POLICYMOD_EXTRA_HAPPINESS_PER_CITY) + kPlayer.GetExtraHappinessPerCity();" + nl)
        s = once(s, old2, "\tif (kPlayer.IsPMMMPolicyHappinessToCulture())" + nl +
                 "\t\tiTotalHappiness += kPlayer.GetExtraHappinessPerCity();" + nl + "\telse" + nl + "\t" + old2, "cp city happiness per city")
        wr(p, s)


def patch_ai_yo_diplomacy():
    """2026-09-22 ruling: Ai Yo also means no Declarations of Friendship and no City-State alliances.
    Two more trait columns and four gates. Every insertion goes AFTER the last line (or before the first line)
    of a block the Phase 4 steps above inserted, never inside one: those steps detect "already applied" by
    finding their whole block verbatim, and a line spliced into it would make them insert it a second time."""
    p = SRC / "CvTraitClasses.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\tint GetPMMMCityCapUnhappinessStep() const;" + nl,
             "\tint GetPMMMCityCapUnhappinessStep() const;" + nl +
             "\tbool IsPMMMNoFriendship() const;" + nl + "\tbool IsPMMMCannotAllyCityStates() const;" + nl, "trait h decls 2")
    s = once(s, "\tint m_iPMMMCityCapUnhappinessStep;" + nl,
             "\tint m_iPMMMCityCapUnhappinessStep;" + nl +
             "\tbool m_bPMMMNoFriendship;" + nl + "\tbool m_bPMMMCannotAllyCityStates;" + nl, "trait h members 2")
    wr(p, s)

    p = SRC / "CvTraitClasses.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    last = "int CvTraitEntry::GetPMMMCityCapUnhappinessStep() const { return m_iPMMMCityCapUnhappinessStep; }" + nl
    s = once(s, last, last +
             "bool CvTraitEntry::IsPMMMNoFriendship() const { return m_bPMMMNoFriendship; }" + nl +
             "bool CvTraitEntry::IsPMMMCannotAllyCityStates() const { return m_bPMMMCannotAllyCityStates; }" + nl, "trait getters 2")
    last = "\tm_iPMMMCityCapUnhappinessStep = kResults.GetInt(\"PMMMCityCapUnhappinessStep\");" + nl
    s = once(s, last, last +
             "\tm_bPMMMNoFriendship = kResults.GetBool(\"PMMMNoFriendship\");" + nl +
             "\tm_bPMMMCannotAllyCityStates = kResults.GetBool(\"PMMMCannotAllyCityStates\");" + nl, "trait cache 2")
    wr(p, s)

    p = SRC / "CvPlayer.h"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\tvoid PMMMRefreshTraitCache() const;" + nl,
             "\tvoid PMMMRefreshTraitCache() const;" + nl +
             "\tbool IsPMMMNoFriendship() const;" + nl + "\tbool IsPMMMCannotAllyCityStates() const;" + nl +
             "\tvoid PMMMRefreshDiplomacyTraitCache() const;" + nl, "player h decls 2")
    s = once(s, "\tint m_iPMMMUnhappinessFromCitiesAndPop;" + nl,
             "\tint m_iPMMMUnhappinessFromCitiesAndPop;" + nl +
             "\tmutable int m_iPMMMDiplomacyCacheLeader;" + nl +
             "\tmutable bool m_bPMMMNoFriendship;" + nl + "\tmutable bool m_bPMMMCannotAllyCityStates;" + nl, "player h members 2")
    wr(p, s)

    p = SRC / "CvPlayer.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    s = once(s, "\t, m_iPMMMUnhappinessFromCitiesAndPop(0)" + nl,
             "\t, m_iPMMMUnhappinessFromCitiesAndPop(0)" + nl +
             "\t, m_iPMMMDiplomacyCacheLeader(-2)" + nl +
             "\t, m_bPMMMNoFriendship(false)" + nl + "\t, m_bPMMMCannotAllyCityStates(false)" + nl, "player ctor 2")
    first = HELPERS.replace("\n", nl)[:HELPERS.replace("\n", nl).index("void CvPlayer::PMMMRefreshTraitCache() const")]
    block = ("//\t--------------------------------------------------------------------------------" + nl +
             "// PMMM Ai Yo, 2026-09-22 ruling: no Declarations of Friendship, never a City-State's ally." + nl +
             "// Cached per leader like PMMMRefreshTraitCache, and likewise never serialized." + nl +
             "void CvPlayer::PMMMRefreshDiplomacyTraitCache() const" + nl + "{" + nl +
             "\tconst int iLeader = (int)getLeaderType();" + nl +
             "\tif (m_iPMMMDiplomacyCacheLeader == iLeader)" + nl + "\t\treturn;" + nl + nl +
             "\tm_iPMMMDiplomacyCacheLeader = iLeader;" + nl +
             "\tm_bPMMMNoFriendship = false;" + nl + "\tm_bPMMMCannotAllyCityStates = false;" + nl +
             "\tif (iLeader < 0 || !isMajorCiv())" + nl + "\t\treturn;" + nl + nl +
             "\tconst CvLeaderHeadInfo& kLeader = getLeaderInfo();" + nl +
             "\tfor (int iI = 0; iI < GC.getNumTraitInfos(); iI++)" + nl + "\t{" + nl +
             "\t\tif (!kLeader.hasTrait(iI))" + nl + "\t\t\tcontinue;" + nl +
             "\t\tCvTraitEntry* pTrait = GC.getTraitInfo((TraitTypes)iI);" + nl +
             "\t\tif (pTrait == NULL)" + nl + "\t\t\tcontinue;" + nl +
             "\t\tif (pTrait->IsPMMMNoFriendship())" + nl + "\t\t\tm_bPMMMNoFriendship = true;" + nl +
             "\t\tif (pTrait->IsPMMMCannotAllyCityStates())" + nl + "\t\t\tm_bPMMMCannotAllyCityStates = true;" + nl +
             "\t}" + nl + "}" + nl + nl +
             "bool CvPlayer::IsPMMMNoFriendship() const" + nl + "{" + nl +
             "\tPMMMRefreshDiplomacyTraitCache();" + nl + "\treturn m_bPMMMNoFriendship;" + nl + "}" + nl + nl +
             "bool CvPlayer::IsPMMMCannotAllyCityStates() const" + nl + "{" + nl +
             "\tPMMMRefreshDiplomacyTraitCache();" + nl + "\treturn m_bPMMMCannotAllyCityStates;" + nl + "}" + nl + nl)
    s = once(s, first, block + first, "player diplomacy cache")
    wr(p, s)

    p = SRC / "CvDiplomacyAI.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    guard = ("\t// PMMM Ai Yo: no Declarations of Friendship with (or for) a player whose trait forbids them" + nl +
             "\tif (ePlayer >= 0 && ePlayer < MAX_MAJOR_CIVS && (GET_PLAYER(ePlayer).IsPMMMNoFriendship() || GET_PLAYER(GetID()).IsPMMMNoFriendship()))" + nl)
    old = ("bool CvDiplomacyAI::IsWantsDoFWithPlayer(PlayerTypes ePlayer) const" + nl + "{" + nl +
           "\tPRECONDITION(ePlayer >= 0 && ePlayer < MAX_MAJOR_CIVS, \"Player index out of bounds\");" + nl)
    s = once(s, old, old + guard + "\t\treturn false;" + nl, "dof wants")
    old = "bool CvDiplomacyAI::IsDoFAcceptable(PlayerTypes ePlayer)" + nl + "{" + nl
    s = once(s, old, old + guard + "\t\treturn false;" + nl + nl, "dof acceptable")
    old = "void CvDiplomacyAI::SetDoFAccepted(PlayerTypes ePlayer, bool bValue)" + nl + "{" + nl
    s = once(s, old, old + "\t// PMMM Ai Yo: the backstop for any path (deals, events, Lua) that would still make one" + nl +
             "\tif (bValue && ePlayer >= 0 && ePlayer < MAX_MAJOR_CIVS && (GET_PLAYER(ePlayer).IsPMMMNoFriendship() || GET_PLAYER(GetID()).IsPMMMNoFriendship()))" + nl +
             "\t\treturn;" + nl + nl, "dof set")
    wr(p, s)

    p = SRC / "CvMinorCivAI.cpp"; s = rd(p); nl = "\r\n" if "\r\n" in s else "\n"
    old = "bool CvMinorCivAI::IsFriendshipAboveAlliesThreshold(PlayerTypes ePlayer, int iFriendship) const" + nl + "{" + nl
    s = once(s, old, old + "\t// PMMM Ai Yo: this player can be Friends but never an ally" + nl +
             "\tif (ePlayer >= 0 && ePlayer < MAX_MAJOR_CIVS && GET_PLAYER(ePlayer).IsPMMMCannotAllyCityStates())" + nl +
             "\t\treturn false;" + nl + nl, "cs ally")
    wr(p, s)


if __name__ == "__main__":
    patch_traits()
    patch_player_h()
    patch_player_cpp()
    patch_city_cpp()
    patch_culture_cpp()
    patch_ai_yo_diplomacy()
    patch_clara_doll_tag()
    patch_ai_yo_culture()
    print("PMMM Phase 4 DLL changes applied to", SRC)
