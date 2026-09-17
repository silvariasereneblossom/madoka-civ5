# Kit audit: Sayaka, Kyouko, Mami (WFTW v27 on CP 5.4.6)

Research report produced 2026-09-16 for the Phase 4 mechanics scope. Numbers come from `build/sim_cp_wftw.db`
(CP + mod applied), compared against the vanilla unit/building each UU/UB replaces. Paths are relative to the repo.

---

## 1. Sayaka Miki: The Oktavians

### A. Kit as implemented

**UA `TRAIT_TOURISM_HEALING_BONUS`, "Orchestra for Justice"** (`wftw/SQL/Sayaka/SayakaLeaderAndTrait.sql:84-86`). Only two non-default `Traits` columns: `GreatPersonProgressFromKills='SPECIALIST_MUSICIAN'` and `CombatBonusFromTourismInfluence=1`. **No `Trait_*` child rows at all**: both effects are entirely Lua.

- *Kills to Great Musician points* (`wftw/Lua/Gameplay/Traits/PMMMSayakaTrait.lua:10-74`, hooked at `PMMMTraitBootstrapper.lua:150-156` off `UnitKilledInCombat`). Gated on `TECH_ACOUSTICS` (line 18). Amount = `floor(killedUnit.Combat / 10)` GPP (line 24, stored x100). Under BNW it *requires* a city holding `BUILDING_MUSICIANS_GUILD` (lines 30, 40-50); the capital fallback at 51-61 is only reachable for non-guild specialists, so with no Guild the effect is silently zero. Barbarian kills count (only killer ID 63 is excluded, line 12).
- *Tourism combat bonus* (lines 76-161), refreshed on `UnitSetXY` and `PlayerDoTurn`. On a tile owned by another **major**, the unit gets `PROMOTION_SAYAKA_EXOTIC/FAMILIAR/POPULAR/INFLUENTIAL/DOMINANT` = `CombatPercent` **+5/+10/+15/+20/+25**. Own territory, minor-civ territory and unowned tiles clear all five (lines 105-117). War is *not* checked.

**UU `UNIT_PMMM_CUTLASS_CONDUCTOR`** replaces `UNITCLASS_LONGSWORDSMAN`. Identical to the Longswordsman: 120 production, 21 CS, 2 moves, `TECH_STEEL`. Deltas: **no `RESOURCE_IRON` requirement**; `ObsoleteTech` `TECH_RIFLING` instead of `TECH_GUNPOWDER`; upgrades to `UNITCLASS_RIFLEMAN` instead of Musketman (skips a whole upgrade step); free `PROMOTION_PMMM_CUTLASS_CONDUCTOR` (`HarmonyGainedPerLevel=1`). Harmony (`wftw/Lua/Gameplay/UniqueUnits/PMMMCutlassConductor.lua:15-36`): on each promotion it gains `sum(HarmonyGainedPerLevel) x current level`, i.e. +2 at L2, +3 at L3 (cumulative 2+3+4...). `ExpendHarmony` (47-69) runs per city per turn: a garrisoned unit with >= 1 Harmony spends 1 and the city gets `BUILDING_PMMM_CUTLASS_CONDUCTOR_DUMMY` (`GreatWorksTourismModifier=100`).

**UB `BUILDING_PMMM_STAGE_OF_OKTAVIA`** replaces Opera House. Cost 200, 1 gpt, `TECH_ACOUSTICS`, 1 Music great-work slot, +1 Culture, all unchanged. Adds `EnhancedYieldTech='TECH_COMBINED_ARMS'`, `TechEnhancedTourism=2`, and `Building_TechEnhancedYieldChanges` +2 Culture (the NULL `TechType` is the normal CP pattern; Petra does the same). Lua (`wftw/Lua/Gameplay/Buildings/PMMMSayakaBuilding.lua:13-35`): each turn, count Stages holding a Great Work of Music; **every unit in the empire heals that many HP, anywhere, unfortified**.

**Decisions** (`wftw/DecisionsMod/Lua/PMMMSayakaDecisions.lua`, data `../SQL/SayakaDecisionData.sql`):
- *Oktavian Dance Queen* (74-168): `ceil(400 x iMod)` gold + 1 Magistrate, needs Acoustics. Capital gets `ChangeWeLoveTheKingDayCounter(ceil(iGAMod x 6))` and `BUILDING_DECISION_SAYAKA_DUMMY` (`LandmarksTourismPercent=100`, `GreatWorksTourismModifier=100`, i.e. Hotel + Airport stacked).
- *True Ally of Justice* (177-236): `ceil(600 x iMod)` culture + 2 Magistrates, needs Civil Service, blocked if >= 1/3 of civs denounce you. While at war with a civ denounced by >= 1/3 of the world, all MELEE/GUN units get `PROMOTION_DECISIONS_SAYAKA` (= `RivalTerritory` + `ExtraAttacks 1` + `AttackMod 15`). If *you* cross the denounce threshold it self-repeals and gives `ceil(iGAMod x 3)` turns of anarchy (line 44).

**MG system:** no civ-specific missions, no `LeaderMGUniqueMission/Promotion`, no `ExtraLeaderMG`, no `MGMoodBonus`, no `SoulGemCorruptionModifier`. Sayaka has **zero** MG-layer identity. gPMMMTraits flags read: `GreatPersonProgressFromKills`, `CombatBonusFromTourismInfluence` (`PMMMTraitBootstrapper.lua:27-33`).

### B. Text vs code

1. UA text (`wftw/XML/Text/Traits-english.xml:35-39`) omits the Acoustics gate, the hard Musician's-Guild requirement, and the `floor(Combat/10)` rate. No Guild means the UA's first half does literally nothing.
2. Text says "in enemy lands"; the code applies in **any** major civ's territory including DoF partners and allies (`PMMMSayakaTrait.lua:112-118`).
3. **Bug: "once per Era" is once per game.** `DoFunc` saves `Game:GetGameTurn()` (line 129); `CanFunc` compares that saved value to `pPlayer:GetCurrentEra()` (84-92). Past ~turn 8 the comparison never re-opens the decision.
4. **Bug: "for 6 turns" is permanent.** The monitor only enters its city loop when `bDanceQueen or bAllyOfJustice` (line 149); on the turn the timer expires both are false, so the dummy is never written back to 0. This is a port regression; the original (`rebellion/ModCompatibility/Events And Decisions/Lua/PMMMSayakaDecisions.lua:133-141`) removed it once and left it off. **Fixed on 2026-09-16 (sweep also runs once either decision has ever been enacted).**
5. **Undocumented:** Ally of Justice also places the +100%/+100% tourism dummy in the capital *and every capital-connected city*, indefinitely (lines 150-162). Nothing in `SayakaDecisionText.xml` mentions tourism.
6. `IsDenunciationThreshold` compares `iLoopPlayer ~= iPlayer` where `iPlayer` is an undefined global in this file (line 27). Harmless today, fragile.

### C. Assessment

**Intuitiveness.** The worst offender is Harmony: an invisible per-unit counter with no UI, spent 1/turn by a garrison to produce a hidden dummy building. Players cannot see how much Harmony a Conductor has, cannot see the dummy, and the +100% great-works tourism vanishes the turn the unit leaves. The tourism combat promotions *are* visible on the unit panel, which is the one thing done right. The Guild requirement on the UA is a silent no-op trap.

**Power.** Baseline (bugs aside): roughly **vanilla Brazil**, a culture-flavoured warmonger whose kit all lands Medieval or later. Empire-wide +1-4 HP/turn from Stages is genuinely strong sustain for a 4-8 city aggressive game (comparable to a permanent Ottoman/Songhai-style edge), and +25% CS deep in a rival's land is real. But nothing helps before Acoustics, and the Conductor is a stat-identical Longswordsman whose only material gain is skipping Iron. **With bug #4 live** (permanent Hotel+Airport in the capital, plus every connected city via Ally of Justice) she jumps to top-tier for a culture victory; that alone is worth more than the entire designed kit.

**Synergy.** Internally coherent on paper (music GWs to healing; tourism to combat) but the two halves pull apart: the tourism combat bonus wants you deep in enemy land, while Harmony wants Conductors sitting in your own cities. Against the MG system she is neutral-to-negative: the Stage's heal applies to MGs too, which is nice, but she has no soul-gem, mood or Grief-Seed interaction whatsoever, so the mod's headline subsystem is pure overhead for her.

### D. Proposals

1. **light: Make the kill bonus unconditional.** Drop the `TECH_ACOUSTICS` gate (line 18) and route Musician points to the capital when no Guild exists (the branch at 51-61 already does this). Better still, delete the handler and use the CP table `Trait_GreatPersonProgressFromKills` (present in this DB), so the effect is data-driven and shows in the pedia. *Intent:* the UA should work from turn 1, matching its own text.
2. **light: Honour "enemy lands".** Add an `IsAtWar` test before applying the promotions (`PMMMSayakaTrait.lua:118`) and rescale to **10/15/20/25/30**. Cuts one hidden rule, keeps the Influence-to-war-power fantasy.
3. **moderate: Move healing into the tooltip.** Replace the per-turn empire sweep with `Buildings.HealRateChange` on the Stage itself (say +15 in its own city) plus `Traits.UnitHealFromGreatPersonBirth = 25` (both CP columns exist in this DB). Empire-wide healing then becomes "every Great Musician you produce heals your army", which is visible, event-driven, and closer to the self-sacrifice/song theme. DB-only.
4. **moderate: Give the Conductor a combat identity.** Delete Harmony and the dummy; put `HPHealedIfDestroyEnemy = 25` and `GiveHPHealedIfEnemyKilled` on `PROMOTION_PMMM_CUTLASS_CONDUCTOR` (both CP `UnitPromotions` columns exist). "She heals what she kills for" reads instantly and needs no counter.
5. **rework: Split the tourism.** Fix the Dance Queen timer to a real 6 turns, strip the tourism dummy out of Ally of Justice, and instead give the Stage `GlobalGreatWorksTourismModifier` +10 each (CP column present). Tourism then scales with a building you can see rather than with a decision bug.

### E. Questions for the maintainer

1. Was the Musician's-Guild requirement intended as a build prerequisite, or is the capital fallback the intended behaviour and the BNW branch a leftover from the pre-BNW version?
2. Ally of Justice granting empire-wide tourism is in the pre-port source too: deliberate but undocumented, or an old copy-paste you want removed?
3. Should Sayaka have *any* MG-layer hook (she is the canonical witch-transformation character and currently has none)?

---

## 2. Kyouko Sakura: Kazamino

### A. Kit as implemented

**UA `TRAIT_GROWTH_SPEED_FROM_RELIGION`, "Top of the Food Chain"** (`wftw/SQL/Kyouko/KyoukoLeaderAndTrait.sql:84-86`): `MaxStolenFood=100`, `CaravanPillageStolenFood=50`, `PopulationMoodBonus=2`. Child table `Trait_PMMM_StolenFoodFromImprovement`: **FARM, FISHING_BOATS, PLANTATION, TERRACE_FARM = 20 each**.

- *Stolen Food from pillage* (`wftw/Lua/Gameplay/Traits/PMMMKyoukoTrait.lua:20-78`). Fires only on pillage (line 21). The unit must be MELEE/GUN/MOUNTED/**NAVALMELEE** and must **not** be `UNITCLASS_PMMM_MAGICAL_GIRL` (line 32; the port fixed a precedence bug that had made this exclusion dead). Per-unit store capped at 100 (line 60). Each tile is on a `STOLEN_FOOD_SAME_TILE_TURNS_BETWEEN = 30`-turn cooldown (lines 35-42, swept at 205-223).
- *Stolen Food from trade-route plunder*: +50 (lines 145-161).
- *Two unit missions* (`wftw/SQL/Kyouko/KyoukoMissions.sql:1-9`, logic at `PMMMKyoukoTrait.lua:81-135`). `MISSION_PMMM_KYOUKO_GIVE_FOOD`: in any of your cities, dumps the whole store as instant `ChangeFood`, costs 1 movement. `MISSION_PMMM_KYOUKO_FOOD_HEAL`: needs > 1 stored, heals `floor(store/2)` HP capped at current damage at 2 food per HP, costs 1 movement.
- *AI* (164-194): AI dumps or eats automatically, and **forces every damaged Kyouko AI unit at >= 25 damage to `PopMission` + `PushMission(MISSION_PILLAGE)` every turn** (189-192).
- *`PopulationMoodBonus`* (`wftw/Lua/Gameplay/MagicalGirls/Moods/PMMMCoreMoods.lua:1947-1964`): mood += `TotalPopulation x 2 x 1`, **uncapped** (`MG_MoodModifiers.MaxValue` is NULL for `MGMOODMOD_TRAIT_POPULATION`, `wftw/SQL/Shared/MGMoods.sql:150`), folded into a total clamped to +/-500 (`PMMMCoreMoods.lua:62-67`).

**UU `UNIT_PMMM_CHAIN_LANCER`** replaces Lancer. Identical: 185 production, 25 CS, 4 moves, `TECH_METALLURGY`, obsolete at `TECH_COMBINED_ARMS`, FaithCost 370. Deltas: **no `RESOURCE_HORSE`**; `RequiresFaithPurchaseEnabled=0` (faith-buyable without the enabling belief); `PROMOTION_PMMM_CHAIN_LANCER` with `FlankAttackModifier=50`.

**UB `BUILDING_PMMM_SAKURA_CHURCH`** replaces Temple. Identical: 100 cost, 2 gpt, `TECH_PHILOSOPHY`, +2 Faith. Adds `ReligiousPressureModifier=20`. Lua (`wftw/Lua/Gameplay/Buildings/PMMMKyoukoBuilding.lua:13-39`) sets `BUILDING_PMMM_SAKURA_CHURCH_DUMMY` (`FoodKept=1`) to `min(followers, 20)`, i.e. up to **20% food kept on growth**.

**Decisions** (`wftw/DecisionsMod/Lua/PMMMKyoukoDecisions.lua`, data `../SQL/KyoukoDecisionData.sql:17-35`):
- *Empower your Missionaries* (17-104): `ceil(200 x iMod)` faith, requires a founded religion and >= 100 total GPP in the capital; costs 25 progress off **every** specialist track (line 65, `2500` x100). Strips `PROMOTION_UNWELCOME_EVANGELIST` and `PROMOTION_SIGHT_PENALTY` from all Missionaries/Prophets, present and future (monitor at 83-102). Once per game.
- *Develop Rocky* (112-156): 1 Magistrate + gold. Grants `BUILDING_DECISIONS_KYOUKO_DEVELOP_ROCKY`: **+2 Food and 3 copies of `RESOURCE_DECISIONS_ROCKY`**, a unique luxury at Happiness 4.

**MG system:** `PopulationMoodBonus` only. No leader-MG mission/promotion; the two missions above are for *ordinary* military units and MGs are explicitly excluded from earning Stolen Food. gPMMMTraits flags read: `MaxStolenFood`, `CaravanPillageStolenFood`, `PopulationMoodBonus`.

### B. Text vs code

1. UA text (`Traits-english.xml:45-49`) says "Farms or Plantations"; the DB also grants on **Fishing Boats and Terrace Farms**, and the unit filter also includes **naval melee**.
2. Text states none of: 20 per pillage, 50 per trade-route plunder, the 100 cap, the 30-turn per-tile cooldown, or that the two missions exist.
3. **Bug: Sakura Church.** Help text (`Buildings-english.xml:107-111`) says "your Empire's majority Religion"; the code requires the religion **you founded** (`PMMMKyoukoBuilding.lua:21`). The non-founder fallback at line 24 compares an integer religion ID to the boolean returned by `HasReligionInMostCities()` and is therefore **always false**: a Kyouko who adopts someone else's religion gets 0% FoodKept, forever.
4. **Bug: Develop Rocky requirement.** Text says East India Company; the code checks `BUILDING_NATIONAL_TREASURY` (`PMMMKyoukoDecisions.lua:135`).
5. **Bug: Develop Rocky price.** `CanFunc` quotes and gates on `ceil(400 x iMod)` (line 127), `DoFunc` charges `ceil(300 x iMod)` (line 148).
6. **AI bug.** `AIStolenFoodCheck:189-192` overrides the tactical AI every turn for every damaged unit. AI Kyouko armies pillage instead of fighting.
7. The `_CBP` help variants (`Buildings-english.xml:112-116`) only swap in under the Community *Balance* Patch (`wftw/ModCompatibility/Community Balance Patch/PMMMCBP.sql:15`); on plain CP the player sees the base text.

### C. Assessment

**Intuitiveness.** Worst of the three. Stolen Food is a per-unit hidden integer with a hidden 100 cap, a hidden 30-turn per-tile cooldown, and two custom missions whose availability flickers based on that invisible number. `MISSION_PMMM_KYOUKO_FOOD_HEAL` requires `> 1` stored (line 92) but `GIVE_FOOD` requires `> 0`, an inconsistency the player can only discover by poking. The mood bonus is invisible outside the MG panel and its magnitude is never stated anywhere.

**Power.** Two very different answers. Ignoring the mood layer she sits around **vanilla Celts/Iroquois**: a genuinely good early UB (up to 20% FoodKept in every city from Philosophy, roughly half an Aqueduct, empire-wide, 300 turns early), a bad-chassis UU (Lancers are weak in BNW; no-horse + faith-buy + 50% flank does not fix a 25-CS mounted unit at Metallurgy), and a UA that pays ~20 food per pillage under a 30-turn tile cooldown: high micro, low yield.

Counting the mood layer she is **far stronger than that**. `TotalPopulation x 2` uncapped against a +/-500 clamp means a 6-8 city empire at ~75 total pop already gets +150 mood (Good to Happy) and a mature empire at 250 pop pins every Magical Girl at **ECSTATIC**: `SoulGemCorruptionMod -5`, ability cost -70%, relationship +100, loyalty +5. In a mod whose central tension is soul-gem corruption, Kyouko simply opts out of it in the second half of the game. That is Poland-tier, and it is the single biggest balance item in this audit.

**Synergy.** Strong internal loop on paper (pillage, food, grow, more pop, better moods), but the UA is explicitly anti-synergistic with the MG system: line 32 forbids Magical Girls from carrying Stolen Food, so her signature mechanic is unusable by the mod's signature units. The AI pillage-forcing (189) also fights the UB, since her growth engine wants cities and infrastructure, not roaming pillagers.

### D. Proposals

1. **light: Cap the mood bonus.** Set `MG_MoodModifiers.MaxValue = 150` for `MGMOODMOD_TRAIT_POPULATION` (`MGMoods.sql:150`, currently NULL). One value; keeps the flavour ("her people feed her girls"), removes the guaranteed-Ecstatic endgame. *Intent:* Kyouko should be the civ whose girls are hardest to break, not the civ that deletes the subsystem.
2. **light: Publish the numbers and fix the church.** Rewrite `TXT_KEY_TRAIT_GROWTH_SPEED_FROM_RELIGION` to state 20 / 50 / 100 cap / 30-turn cooldown and list all four improvements. For the UB, either fix line 24 to `pCity:GetReligiousMajority() == pPlayer:GetReligionInMostCities()`, or, better, delete `PMMMKyoukoBuilding.lua` and the 20-dummy scheme entirely and set `Buildings.FoodKept = 15` flat on the Sakura Church. One number, in the tooltip, DB-only.
3. **moderate: Make the theme land: "never share your food", turned generous.** Let `MISSION_PMMM_KYOUKO_GIVE_FOOD` also target a DoF partner's or city-state's city, granting them the food and Kyouko a yield (culture or faith scaled to the amount). Requires extending the existing mission Lua; no new subsystem. This is the one place the character arc can actually be played.
4. **moderate: Fix the AI.** Remove the forced pillage at `PMMMKyoukoTrait.lua:189-192` and let `AIStolenFoodCheck` only *use* stored food, never push missions. The AI already dumps and heals correctly at 169-186.
5. **rework: Replace the ledger with promotions.** Give every Kyouko land unit a free promotion carrying `HealOnPillage`, `PartialHealOnPillage` and `AOEDamageOnPillage` (all present in the CP `UnitPromotions` schema), plus `Trait_YieldFromKills` rows for Food. Pillaging then pays out immediately and visibly, the 100-cap/cooldown/missions all disappear, and roughly 900 lines of state-tracking Lua go with them. Recommended direction if you want to reduce hidden complexity anywhere in the mod.

### E. Questions for the maintainer

1. Was excluding Magical Girls from Stolen Food (`PMMMKyoukoTrait.lua:32`) a deliberate balance call, or an artefact of the broken `UNITCLASS_MAGICAL_GIRL` lookup that the port then made real?
2. Is the uncapped population mood bonus intended to reach the +/-500 clamp in a normal large game, or was `MaxValue` meant to be filled in and forgotten?
3. Develop Rocky: which is authoritative, East India Company (text) or National Treasury (code), and is 300 or 400 the intended price?

---

## 3. Mami Tomoe: Nazione di Tiro

### A. Kit as implemented

**UA `TRAIT_FRIENDSHIP_PRODUCTION_BONUS`, "Not Afraid of Anything Anymore"** (`wftw/SQL/Mami/MamiLeaderAndTrait.sql:84-86`, with the in-file comment *"Values increased until more of the trait is implemented"*): `CityStateCombatStrengthModTimes100=100`, `MagicalGirlRelationshipModifier=25`. With the Decisions mod loaded, `MamiDecisionData.sql:50-52` also sets `Traits.FreeBuilding='BUILDING_DECISIONS_MAMI_DUMMY'`. No `Trait_*` child rows.

- *CS combat bonus* (`wftw/Lua/Gameplay/Traits/PMMMMamiTrait.lua:10-27`). Each `PlayerDoTurn`, count minors where `GetMinorCivFriendshipLevelWithMajor >= 2` (Ally), compute `floor(n x 100/100) = n`, then `SetBaseCombatStrength(baseCombat + n)` on every `UNITCOMBAT_GUN` unit. That line runs Musketman, Rifleman, Great War Infantry, Infantry, Mech Infantry, XCOM Squad, so it never expires. Only refreshed on `PlayerDoTurn`, so a newly built unit is unbuffed for one turn.
- *`MagicalGirlRelationshipModifier = 25`* is copied into gPMMMTraits (`wftw/Lua/PMMMDataStorage.lua:52`) and read exactly once, to decide whether to load Mami's trait script (`PMMMTraitBootstrapper.lua:35`). **Nothing in the relationship system consumes it. It is a dead effect.**

**UU `UNIT_PMMM_TIRO_MUSKETEER`** replaces `UNITCLASS_RIFLEMAN` (not Musketman). **Stat-identical to the Rifleman**: 225 production, 34 CS, 2 moves, `TECH_RIFLING`, obsolete at `TECH_REPLACEABLE_PARTS`. Sole delta: `PROMOTION_PMMM_TIRO_MUSKETEER` (`TiroFinaleStrength=50`) unlocking `MISSION_PMMM_TIRO_FINALE` (`wftw/SQL/Mami/MamiMissions.sql:1-5`, `PMMMMissionRange=2`, `PMMMTargetType='ENEMY'`). `PMMMTiroMusketeer.lua:47-137`: hits the first visible at-war unit on the target plot for damage computed at **50%** of `GetMaxAttackStrength`, then one unit on each of the 6 adjacent plots at **25%**; damage per unit capped at 100 (153-154); +5 XP; `SetMoves(0)`; applies `PROMOTION_PMMM_TIRO_MUSKETEER_DEBUFF` (`DefenseMod = -20`) until the owner's next `PlayerDoTurn` (161-176).

**UB `BUILDING_PMMM_TEAHOUSE`** replaces Caravansary. In the database it is **identical in every gameplay column**: 120 cost, 0 maintenance, `TECH_HORSEBACK_RIDING`, +50% land trade route range, +2 gold to other civs. Only flavors and icon differ. Everything else is Lua + 12 dummy buildings (`wftw/Lua/Gameplay/Buildings/PMMMMamiBuilding.lua:51-103`): each turn, count Teahouses `N` and DoFs `D`, then binary-decompose (`toBits`, `PMMMGeneralFunctions.lua:42-51`) into `BUILDING_PMMM_TEAHOUSE_MAMI_DUMMY_1/2/4/8/16/32` worth `D` Production on `BUILDINGCLASS_CARAVANSARY` **in Mami's capital only** (91-99), and `..._FRIEND_DUMMY_*` worth `N` Production on `BUILDINGCLASS_PALACE` in each DoF partner's capital (73-90). Ceiling 63 by construction.

**Decisions: four, not two** (`wftw/DecisionsMod/Lua/PMMMMamiDecisions.lua`, data `../SQL/MamiDecisionData.sql:15-52`):
- *Official Language: Japanese* (59-142): `ceil(200 x iMod)` gold + 1 Magistrate, needs Writing. Grants `POLICY_DECISIONS_MAMI_JAPANESE`: +10% Science, +1 Production per specialist, -20% Culture, -20% tourism (via `Policy_BuildingClassTourismModifiers` on the free dummy), -25% Writer/Artist/Musician rate. Renames the civ and all founded cities.
- *Official Language: Italian* (145-236): the exact mirror (+20% Culture, +20% tourism, +1 Culture per specialist, +25% GWAM rate, -10% Science).
- *Repeal* (239-301): 200 x iMod gold + 1 Magistrate, human-only.
- *The Mammie Doctrine* (304-391): `ceil(600 x iMod)` culture + 2 Magistrates, requires >= 15 excess Happiness, once per game. `PolicyCostModifier=10`, `MinorFriendshipMinimum=10`, and three `GetDiploModifier` hooks returning **-30** (favourable) from male leaders, toward Madoka/Sayaka/Kyouko/Nagisa, and symmetrically to Mami.

**MG system:** nothing functional. No leader-MG mission or promotion, no mood bonus, and her one MG-flavoured column is dead. gPMMMTraits flags read: `CityStateCombatStrengthModTimes100`, `MagicalGirlRelationshipModifier`.

### B. Text vs code

1. **Dead effect.** `MagicalGirlRelationshipModifier=25` does nothing (grep across `wftw/` returns only the SQL, the DataStorage copy, and the bootstrapper test).
2. UA text (`Traits-english.xml:25-29`) describes *only* the city-state combat bonus. The Teahouse friendship network, the actual bulk of the civ, is not part of the UA text at all.
3. Teahouse text (`Buildings-english.xml:57-61`) reads "Provides +1 Production for every Declaration of Friendship you have", implying per-building; the code applies it to the **capital only** (91-99), and only if the capital itself has a Caravansary-class building.
4. **Bug: Repeal never removes Japanese.** `PMMMMamiDecisions.lua:287-291`: `if not pPlayer:HasPolicy(iJapanese) then ... SetHasPolicy(iJapanese, false)`. Inverted test; the branch only runs when the policy is already absent. Italian is removed correctly at 281-285.
5. **Bug: Italian throws.** Line 212 dereferences `v.Name` where `v` is undefined in that scope; the loop errors out for any city carrying a `_DECISIONS_JAPANESE` name. Line 206's `string.sub(sKey, 1, iStart)` is also off by one and leaves a trailing underscore.
6. **Bug: city naming.** `GetMamiJapaneseCityName` (35-47) has no `break`; the first new city consumes every remaining Japanese name and ends up with the last one.
7. **AI bug.** `RemoveDefenseDebuff` (161-226) fires Tiro Finale for the AI from `PlayerDoTurn` (registered at `wftw/Lua/PMMMWishForTheWorldMain.lua:155`), then `SetMoves(0)`. AI Tiro Musketeers burn their entire turn at turn start whenever a target is within 2 tiles and can never advance.
8. **No movement gate.** `TiroFinaleCustomMissionPossible` (11-21) checks only the promotion, and `CvUnitMission.cpp:1350-1353` adds no movement test for custom missions. A human can move both tiles and then fire.
9. `PROMOTION_PMMM_TIRO_MUSKETEER_READY` (line 7) does not exist in the database: dead local.
10. Multi-Mami games are knowingly broken (comment at `PMMMMamiBuilding.lua:49-50`).

### C. Assessment

**Intuitiveness.** The Teahouse is the mod's most opaque construction: twelve invisible dummy buildings, binary bit-packing, a bonus that lives in *other players'* capitals, and a tooltip that describes it wrongly. A player cannot verify any of it without opening the save. Tiro Finale is the opposite: a clear, flashy, well-signposted ability, and the best-designed single thing in these three civs.

**Power.** Clearly the weakest of the three, and below average for BNW generally. Concretely: she has **no UA at all before Gunpowder**, and a 4-ally game gives +4 CS on a 34-strength Rifleman, about +12%, arriving in the Industrial era. The Teahouse network at 6 Teahouses and 3 DoFs is **+3 Production in one city** (less than a single Windmill) plus a diplomatic gift of +6 Production to each friend's capital: she pays for their empires more than her own. The UU is a stat-identical Rifleman with one ability, arriving at Rifling, which is far too late to shape a game. Roughly **vanilla Denmark or Byzantium** tempo-wise, and arguably below: Denmark at least has a Classical-era UA. Against a 4-8 city benchmark she generates perhaps 3-6 yields per turn of unique value across the whole game.

**Synergy.** The pieces don't compose. City-state allies (UA) want gold and quest micromanagement; Teahouses want DoFs; Tiro Finale wants war, and war costs you both allies and DoFs. The Japanese/Italian decisions are a genuinely elegant fork, but they are orthogonal to everything else in the kit. Against the MG system she is the emptiest of the three: her one MG column is dead code, so the mentor/friendship theme, which maps onto the MG relationship system almost perfectly, is entirely unrealised.

### D. Proposals

1. **light: Give her an early game.** Add `Trait_YieldFromCSAlly` and `Trait_YieldFromCSFriend` rows (both CP tables exist in this DB): e.g. +2 Production and +1 Science per Ally, +1 Production per Friend, active from turn 1. DB-only, appears in the city-state tooltip, and makes "mentor with friends" the civ's actual identity rather than a late combat rider.
2. **light: Delete the dummy network.** Put a flat `Building_YieldChanges` +2 Production on the Teahouse and use `Trait_YieldChangesPerTradePartner` (present) for the friendship scaling. That removes 12 buildings, 6 building classes, and `PMMMMamiBuilding.lua` outright, and makes the tooltip true. *Intent:* the same total yield, visible.
3. **moderate: Move the UU forward.** Retarget the Tiro Musketeer to `UNITCLASS_MUSKETMAN` (150 production, 24 CS, `TECH_GUNPOWDER`) and reduce `TiroFinaleStrength` to 40. A Renaissance UU that can shell at range 2 is a real identity; an Industrial one is a footnote. Pure DB change (`Civilization_UnitClassOverrides` + the `Units` row).
4. **moderate: Fix Tiro Finale's plumbing.** Require `pUnit:GetMoves() > 0` in `TiroFinaleCustomMissionPossible` (line 16), and move the AI firing out of `PlayerDoTurn` so AI units aren't frozen at turn start. Both are small, contained Lua edits.
5. **rework: Make "friends" mean mentorship, and revive the dead column.** Two parts. (a) Put `Buildings.Experience = 15` on the Teahouse (vanilla column) so units trained in Teahouse cities start veteran: tea, ribbons, veteran, all in one visible number. (b) Either implement `MagicalGirlRelationshipModifier` in the relationship code (+25% relationship gain between her MGs) or delete the column; right now it is a promise in the data that the game never keeps.

### E. Questions for the maintainer

1. `MamiLeaderAndTrait.sql:86` says the values were "increased until more of the trait is implemented": what was the rest of the intended trait, and is `MagicalGirlRelationshipModifier` the unfinished half?
2. Should the Teahouse production go to Mami or to her friends? The text says both, the code overwhelmingly favours her friends, and as written she is subsidising rivals.
3. The Mammie Doctrine's diplomatic bonus is hard-coded to Madoka/Sayaka/Kyouko/Nagisa (`PMMMMamiDecisions.lua:52`) and omits Homura, later additions and the Pleiades: should that list be data-driven, and is the `-30` meant to apply to *all* MG civs?

---

## Summary

| Civ | Current power tier | Biggest problem | Headline proposal |
|---|---|---|---|
| **Sayaka** | Mid (~Brazil) as designed; **top-tier as shipped** because the Dance Queen tourism dummy was never removed (now fixed) | Harmony is an invisible per-unit counter driving an invisible dummy building; the UA silently does nothing without a Musician's Guild | Move healing onto `HealRateChange` / `UnitHealFromGreatPersonBirth`, and replace Harmony with `HPHealedIfDestroyEnemy` on the Conductor |
| **Kyouko** | Mid (~Celts) on paper; **high (~Poland)** once the uncapped population mood bonus is counted: a large empire pins every MG at Ecstatic | Stolen Food is a hidden per-unit integer with a hidden cap, a hidden 30-turn tile cooldown and two flickering missions; Magical Girls are barred from her own mechanic | Cap `MGMOODMOD_TRAIT_POPULATION` at ~150, flatten the Sakura Church to `FoodKept = 15`, and convert Stolen Food into CP pillage promotions |
| **Mami** | **Low** (~Denmark or below): no UA before Gunpowder, a stat-identical Rifleman at Rifling, and a Teahouse worth ~+3 Production in one city | The whole friendship kit is 12 bit-packed dummy buildings whose tooltip is wrong, and her one MG-themed trait column is dead code | Give her a turn-1 UA via `Trait_YieldFromCSAlly`/`CSFriend`, delete the dummy network for flat yields, and move the Tiro Musketeer back to Musketman |

Ship-blocking bugs regardless of redesign: the permanent Sayaka tourism dummy (`PMMMSayakaDecisions.lua:149`, fixed 2026-09-16), the always-false Sakura Church fallback (`PMMMKyoukoBuilding.lua:24`), the inverted Mami repeal test (`PMMMMamiDecisions.lua:287`), and the AI-freezing Tiro Finale (`PMMMTiroMusketeer.lua:161-226`). Two AI-behaviour bugs sit just behind them: Kyouko's forced pillage (`PMMMKyoukoTrait.lua:189-192`) and the undefined `v` in Mami's Italian decision (`PMMMMamiDecisions.lua:212`).
