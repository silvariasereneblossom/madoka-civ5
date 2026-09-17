# Kit audit: Madoka, Ultimate Madoka, Homura, Demon Homura (WFTW v27 on CP 5.4.6)

Research report produced 2026-09-16 for the Phase 4 mechanics scope. Reference build: `build/sim_cp_wftw.db`
(Community Patch 5.4.6 + WFTW). Decisions data is **not** in that DB; it ships under `wftw/DecisionsMod/` and
only loads with the Events & Decisions mod. Paths are relative to the repo.

---

## 1. Madoka Kaname: CIVILIZATION_ORIGINAL_MADOKA ("Mitakihara")

### A. Kit as implemented

**UA "Arrow of Hope" (`TRAIT_FREE_ARCHERY_BONUS_GARRISON_ATTACK`)**: three effects, all DB-driven, zero Lua:

1. **Free Archery.** `Civilization_FreeTechs` row at `wftw/SQL/Madoka/MadokaCivilization.sql:90-94`. She is the only one of these four with a second free tech (all four get `TECH_AGRICULTURE`).
2. **`MGMoodBonus = 100`** (`wftw/SQL/Madoka/MadokaLeaderAndTrait.sql:84-86`). Read into `gPMMMTraits` at `wftw/Lua/PMMMDataStorage.lua:79` and consumed by the `MGMOODMOD_TRAITS` moodlet at `Moods/PMMMCoreMoods.lua:1070`. Flat +100 to every MG she owns, permanently.
3. **`Trait_MoodModChanges` on `MGMOODMOD_FOUGHT_NEAR_LEADER`, Modifier 100** (`MadokaLeaderAndTrait.sql:88-90`). The base moodlet is Value 100 / Turns 10; the trait multiplier is applied as `floor(Value x (1 + v.Value/100))` at `PMMMCoreMoods.lua:41`: **+200 for 10 turns** after any combat near her Leader MG.

What Mood buys (`MG_Moods`): +100 = GOOD (-1 corruption/turn); +300 = ELATED (-3 corruption/turn, -30% Soul Gem ability cost, +50 relationship points, +1 Loyalty/turn). Range -500..+500.

**UU Rosebow Infantry** (replaces Composite Bowman). Identical 7 CS / 11 RCS / range 2 / 2 moves, Construction to Machinery, keeps `PROMOTION_ONLY_DEFENSIVE`. Differences: **Cost 63 vs 75** (-16%), FaithCost 127 vs 150, and `PROMOTION_PMMM_ROSEBOW_INFANTRY`, a trigger promo with two grant paths: `NewPromotionInCity = PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS` (applied by `PMMMRosebowInfantry.lua:40-58`) and a `Promotion_PMMM_GrantNewPromotionOnImprovement` row for `IMPROVEMENT_CITADEL` (applied by lines 10-37). Both bonus promos are `ExtraAttacks = 1` + `CanMoveAfterAttacking = 1`. So: **two ranged attacks per turn while standing in a city or on a Citadel.**

**UB Middle School** (replaces Public School). Byte-for-byte a Public School (Cost 300, maint 3, Scientific Theory, +3 Science, +1 Science per 2 pop, 1 Scientist slot) **plus `GreatPeopleRateModifier = 25`**. No Lua.

**Decisions** (`wftw/DecisionsMod/Lua/PMMMMadokaDecisions.lua`):
- *Establish Mitakiharafest* (lines 14-108). `ceil(500 x iMod)` gold + 2 Magistrates. Requires >= 4 Wheat on Farms and >= 2 Wine on Plantations in city radii (line 56). Grants **3 Golden Age turns + 3 WLTKD turns in the capital, repeating every 25 turns for the rest of the game** (monitor, lines 78-106). Neither number is game-speed scaled.
- *Commission Mi-ta-kun* (lines 119-189). `ceil(1000 x iMod)` gold + 1 Magistrate + Combustion + consumes a Great Artist. **+1 Culture on every owned route tile at the instant of enactment** (`Game.SetPlotExtraYield`, line 175) and +2 Tourism in the capital and connected cities.

**Leader MG:** yes, named from the leader. No unique promotion, standard 10-turn respawn. **gPMMMTraits flags: `MGMoodBonus` only.**

### B. Text vs code

- **`_CBP` text variants are dead.** `TXT_KEY_TRAIT_FREE_ARCHERY_BONUS_GARRISON_ATTACK_CBP` promises *Trapping*; the SQL unconditionally inserts `TECH_ARCHERY` and nothing selects a `_CBP` key. 13 dead `_CBP` strings across Buildings/Traits/Religions text.
- **The trait's type name is a lie.** No garrison-attack component; that lives on the UU.
- **Mood does nothing for a healthy MG.** `PMMMMagicalGirls.lua:824` clamps total corruption with `math.max(..., 1)`. An undamaged MG's corruption is exactly 1/turn, so a -3 mood modifier is entirely absorbed by the floor. The UA only pays out while a girl is healing. No text says this.
- Mitakiharafest header comment says 3 Wheat / 1 Wine; code and XML say 4/2.
- **Mi-ta-kun gives +2 Culture on shared tiles.** `Game.SetPlotExtraYield` is additive and the loop at lines 168-179 walks every city's full radius with no de-duplication. Text promises +1.
- **The Wheat/Wine scan never checks plot ownership** (lines 42-54) and double-counts overlapping radii.
- Mi-ta-kun's per-turn dummy upkeep lives inside *Mitakiharafest's* monitor (lines 95-103).
- Name collision: the UB is `BUILDING_PMMM_MIDDLE_SCHOOL` and there is also a world wonder `BUILDING_PMMM_MITAKIHARA_MS` at the *same tech* (Scientific Theory, cost 750).

### C. Assessment

**Intuitiveness.** The headline UA number (+100 Mood) is invisible in empire terms and, per the corruption floor, does nothing most turns. "Fought Near Leader doubled" requires the player to understand a moodlet subsystem, keep the Leader MG adjacent to combat, and notice a hidden 10-turn window. The UU is completely legible. Mitakiharafest's 4-Wheat/2-Wine gate is a map lottery.

**Power.** Roughly **Siam tier (B-)**. The real content is a 16%-cheaper Composite Bowman with a double attack in cities (excellent Classical defence, offensive with forward Citadels), a Public School with a free Garden bolted on, and ~12% permanent Golden Age uptime from Mitakiharafest. No growth, no gold, no expansion tempo. The UA contributes essentially nothing to yields.

**Synergy.** Weak internally. The UU wants you fighting near the Leader MG in your own cities, which is where the Fought-Near-Leader moodlet triggers. But the UB (science/GPP, Industrial) and the decisions (Golden Age, Tourism, Combustion) point at a tall builder game. Three different win conditions and no tempo for any of them.

### D. Proposals

1. **light: make the Mood bonus visible in yields.** Add `Trait_YieldFromKills` (Culture 3, Faith 2, era-scaled via `IsEraScaling = 1`) so "hope" produces something the player can see. Pure DB.
2. **light: fix the corruption floor interaction.** Either drop the floor for players whose trait `MGMoodBonus > 0`, or (no Lua) raise `MGMoodBonus` to 200 so she reliably sits at HAPPY/ELATED and the ability-cost tier matters. One SQL literal.
3. **moderate: de-lottery Mitakiharafest.** Replace the 4-Wheat/2-Wine gate with "2 different luxuries connected + a Monument in the capital", fix the de-duplication, scale the 25-turn period by game speed.
4. **moderate: give the UU a reason to leave home.** `Trait_FreePromotionUnitCombats` (UNITCOMBAT_ARCHER) with `ExtraAttacks = 1` while in *friendly territory*, not just on a city/citadel tile. Needs a new promotion row plus one Lua condition.
5. **rework: move the UB to the sacrifice theme.** Middle School gives Faith 2 and `GreatPeopleRateModifier 25`, plus CP `Trait_GreatPersonExpendedYield` (Faith 30, Culture 30, era-scaled) so expending a Prodigy, which *creates a Magical Girl*, visibly pays the empire. Ties UA, UB and the shared MG system into one loop.

### E. Maintainer questions

1. Is the CBP/Vox Populi build still a shipping target? Nothing selects the `_CBP` text or swaps Archery for Trapping.
2. Is the 1%/turn corruption floor meant to be absolute, or should trait-driven Mood be allowed to push a full-HP girl to 0 decay?
3. Should the "Middle School" UB and the "Mitakihara Middle School" wonder coexist at the same tech?

---

## 2. Ultimate Madoka: CIVILIZATION_MADOKA ("Madoka's Realm")

### A. Kit as implemented

**UA "Law of Cycles" (`TRAIT_NO_WITCHES`)**: two DB flags (`wftw/SQL/UltimateMadoka/UltimateMadokaLeaderAndTrait.sql:85-87`) driving a lot of Lua:

- **`NoWitches = 1`.** Both witch-out branches in `MagicalGirlUpkeep` call `DoLawOfCyclesTakeaway` instead of `TurnIntoWitch`. `DoLawOfCyclesTakeaway` (`wftw/Lua/PMMMGeneralFunctions.lua:348-407`) kills the unit, sets `MGACTIONSTATE_CYCLING`, wipes `Promotions`. `CheckLOCMagicalGirls` (`PMMMUltimateMadokaTrait.lua:17-28`) returns her after `ceil(DealDuration x 33%)` = **10 turns at Standard**. `ReturnFromLawOfCycles` respawns her **at the capital** with SoulGem 100, **Level 1, XP 0**, HP 100, Loyalty 100.
- **Secondary, undocumented:** no Hidden Witch Barriers ever spawn in her territory (`PMMMWitches.lua:440`), and any HWB in a city she captures is destroyed (`PMMMWitches.lua:669-670`).
- **`CanSummonWitches = 1`.** Adds `MISSION_PMMM_SUMMON_WITCH` and `MISSION_PMMM_DISMISS_WITCH`. `DoSummonWitch` (`PMMMUltimateMadokaTrait.lua:74-84`) spawns a Witch at `floor(bestEraMelee x 1.33)` CS with `PROMOTION_PMMM_WITCH_NO_XP`, zeroing both units' moves. Costs: while a Witch is out, the summoner's corruption is multiplied by `2 + floor(distance/2)` (`PMMMMagicalGirls.lua:812-818`); dismissing sets a 10-turn cooldown; if the Witch is *killed*, `UMadokaOnWitchOrMGDeath` (lines 179-211) deals `min(50, HP-1)` damage to the MG, halves her remaining Soul Gem, and applies `PROMOTION_PMMM_BROKEN_PSYCHE` (**-50% Combat Strength**) for 10 turns.
- **She gets no Leader Magical Girl at all** (hardcoded, `PMMMMagicalGirls.lua:426`). Compensation is a free Archer. Not in her trait text or Civilopedia.

**UU Herald of Madoka** (replaces Missionary). Same 200 Faith, same 2 spreads. `MovesChange = 1` (5 moves), `CanStealCriticalMagicalGirl = 1`, drops the Missionary's sight penalty. Its payload is `MISSION_PMMM_LEAD_AWAY`: with both spreads unused, consume the Herald to send an adjacent enemy **non-leader** MG whose Soul Gem State is `CRITICAL` into the Law of Cycles **under your ownership** (`PMMMHeraldOfMadoka.lua:51-69`). She reappears at *your* capital 10 turns later at full Soul Gem.

**UB Luminous Garden** (replaces Garden). **Mechanically identical to a Garden in the database.** Its only unique effect is Lua: `DoChangeCorruption(-1)` per turn for each MG standing in a city with it (`PMMMUltimateMadokaBuilding.lua:11-27`), which exactly cancels the 1%/turn passive decay.

**Decisions** (`PMMMUltimateMadokaDecisions.lua`):
- *Establish Yuri Valhalla* (lines 13-74). `ceil(800 x iMod)` gold + 2 Magistrates; needs >= 4 MGs and >= 2 Luminous Gardens. Grants `POLICY_DECISIONS_MADOKA_YURI_VALHALLA`: **`CityGrowthMod = 10`** and **+3 Happiness per `BUILDINGCLASS_GARDEN`**.
- *Appoint {MG} as your Knight* (lines 82-164). `ceil(200 x iMod)` **Faith**; an MG at level 4+. Sets `IsLeader = true` and the leader promotion (+20% CS, +50% XP, AlwaysHeal, respawn-on-death).

**gPMMMTraits flags: `NoWitches = 1`, `CanSummonWitches = 1`.**

### B. Text vs code

- **Herald text is wrong about the payoff.** Strategy text says the stolen girl returns "with 50% Corruption"; `ReturnFromLawOfCycles` sets `SoulGem = 100`.
- **Trait text omits the level/XP wipe.** "lose all of their Promotions" vs code also setting `Level = 1` and `XP = 0`.
- **Trait text never mentions she has no Leader Magical Girl.**
- Comment/code mismatch on the Witch-death penalty: "Does 25 Damage" vs `min(50, HP-1)`.
- **Wrong-variable bug:** `PMMMUltimateMadokaDecisions.lua:94` assigns to `Decisions_YuriValhalla.Desc` when it means `Decisions_KnightOfMadoka.Desc`.
- **"Must not have any Leader Magical Girls" is not implemented** in the Knight sub-decision; stale entries can allow a second Knight.
- Operator precedence at `PMMMUltimateMadokaTrait.lua:18`: `(A and B) or C`.
- Text typo `[[NEWLINE]` at Buildings-english.xml:179.

### C. Assessment

**Intuitiveness.** The UA's *default* mode is excellent and self-explanatory: the MG system's worst outcome is replaced by a 10-turn timeout. Everything else is opaque. Witch summoning has four hidden costs that appear nowhere in the trait text. The Herald's Lead Away requires tracking an *enemy* MG's Soul Gem State, parking a 5-move civilian adjacent to a hostile military unit, and spending a 200-faith unit: high skill floor, very high payoff, almost no signposting.

**Power.** **Top quartile, around Korea/Babylon tier (A-).** Yuri Valhalla is the strongest single effect of the four civs: +3 Happiness per Garden empire-wide plus `CityGrowthMod = 10` makes a 6-8 city tall empire run 2-3 pop ahead. Add no Witch risk at all, no Hidden Witch Barriers to police, and a UU that permanently steals other civs' named units. Weaknesses are soft: no Leader MG until she pays 200 faith for a Knight, and the UB/decision chain needs fresh water.

**Synergy.** The tightest of the four. UB (Gardens) to Decision 1 (Happiness per Garden) to wide-tall growth to more Prodigies to more MGs. The UB's -1 corruption/turn is the exact counter to the 1%/turn floor. The one anti-synergy is Witch summoning, which spikes corruption at the very moment the UA is trying to make corruption irrelevant.

### D. Proposals

1. **light: write the real text.** No Leader Magical Girl; Law of Cycles returns her at level 1 with full Soul Gem; summoned Witches multiply corruption. Fix the Herald's "50% Corruption" line.
2. **light: fix the two decision bugs.** Line 94 target; wrap line 84 in `Locale.ConvertTextKey`; add an "already has a Leader MG" check.
3. **moderate: make the Witch summon a real choice instead of a trap.** Corruption multiplier flat 2; on-death Soul Gem loss capped at 25 points; `BROKEN_PSYCHE` 5 turns and -25% CS. Four literals plus one promotion row.
4. **moderate: give the Law of Cycles an empire payoff.** Each time one of her girls goes into the Cycle, grant Faith and Golden Age Points (one line in `DoLawOfCyclesTakeaway`). Despair becomes fuel rather than merely not-a-disaster.
5. **rework: fold the missing Leader MG into the UA properly.** `Trait_FreePromotions` on `UNITCLASS_PMMM_MAGICAL_GIRL` granting a weak leader-ish promo to *all* her girls (+10% CS, AlwaysHeal), and reprice the Knight to 400 faith. "The Law of Cycles is everywhere, not one person."

### E. Maintainer questions

1. Is "no Leader Magical Girl" a deliberate handicap she is meant to buy out of with the Knight decision, or an unpatched consequence of the hardcode?
2. Should Lead Away be able to target **Leader** MGs?
3. Is the Luminous Garden supposed to be *only* +1 Soul Gem/turn over a vanilla Garden?

---

## 3. Homura Akemi: CIVILIZATION_HOMURA ("Neo-Mitakihara")

### A. Kit as implemented

**UA "All for Her Sake" (`TRAIT_STEAL_ENEMY_UNIQUE_ON_CONQUEST`)**: three DB columns (`wftw/SQL/Homura/HomuraLeaderAndTrait.sql:81-85`), no trait Lua (`PMMMHomuraTrait.lua` is a 6-line stub):

1. **`MaximumMetEraMGStrength = 1`.** `SetMagicalGirlStrength` (`PMMMGeneralFunctions.lua:487-518`) walks every alive major her team has met and uses the **highest** era instead of her own. MG base CS by era: Ancient 7, Classical 9, Medieval 14, Renaissance 16, Industrial 23, Modern 49, **Atomic 45**, Information 70.
2. **`LeaderMGUniquePromotion = PROMOTION_PMMM_HOMURA_TRAIT`**: `SoulGemCorruptionMod = -3`, applied in the corruption sum and then floored at 1.
3. **`LeaderMGRespawnTimeModifier = -75`**: **3 turns at Standard instead of 10**.

**UU Thief of Time / Clockstopper** (replaces Infantry). **Cost 431 vs 375 (+15%)**, otherwise identical (70 CS, 2 moves, Plastic to Mobile Tactics). Carries `PROMOTION_PMMM_CLOCKSTOPPER` (`ObtainUniqueUnitPromotionOnCityCapture = 1`). `PMMMClockstopper.lua:10-95`: on city capture, collects every `Unit_FreePromotions` row belonging to the loser's UUs of the same domain that the class default unit does not have, and grants one at random. Repeatable, no cap.

**UB Dimensional Armory** (replaces Military Academy). Same 300 cost, Military Science, same +15 XP. Differences: **`GoldMaintenance 4` vs `1`**, `Airlift = 1`, `AirModifier = 4`. The only other building with `Airlift` is the Airport at Radar.

**Decisions** (`PMMMHomuraDecisions.lua`):
- *Devote to Madoka* (lines 26-99). `ceil(250 x iMod)` gold + 1 Magistrate + Classical era. Branches on whether any Madoka player exists, evaluated once at file load. **With a Madoka in the lobby:** `MinorFriendshipMinimum = -5` plus **-150** opinion with Madoka civs and **+20** against everyone else. **Without:** the Madoka Memorial in the capital, **+2 Faith per Monument empire-wide**, **+10% Unhappiness from population**.
- *Draw Mana Into Your Shield* (lines 110-176). Once per era; requires the Time Stop cooldown to be `> 0`. **Can never be enacted (below).**

**Leader MG:** yes, "Homura Akemi", with the -3 corruption promo and the 3-turn respawn. **gPMMMTraits flags: `LeaderMGUniquePromotion`, `LeaderMGRespawnTimeModifier`, `MaximumMetEraMGStrength`.**

### B. Text vs code

- **Time Stop does not exist in this build.** No `MISSION_PMMM_TIME_STOP` row and no `PROMOTION_PMMM_TIME_STOP*` row in the DB. Her trait sets neither `TimeStopDuration` nor `TimeStopCooldown` (both default 0). `tTimeStopPromotions` (`PMMMGeneralFunctions.lua:442-448`) is always empty; `HasAnyTimeStopPromo` always returns false. Full UI support exists and is unreachable (`UI Replacements/UnitPanel.lua:1773-1790`). The only definition anywhere in the repo is `rebellion/SQL/Shared/Promotions.sql:77-82`, which creates `PROMOTION_PMMM_TIME_STOP` without the trailing underscore the Lua matcher needs, and with no mission.
- **Consequently Decision 2 is permanently dead.** `PMMM.TimeStopCooldown[i]` is initialised to 0 and nothing ever raises it.
- **Trait text omits the corruption condition.** Trait text says a flat "3% less Soul Gem Corruption per turn"; the promotion help correctly adds "still subject to the 1% minimum".
- **The trait type name describes the UU, not the trait.** The stealing is driven purely by `ObtainUniqueUnitPromotionOnCityCapture`, so **any civ that acquires a Clockstopper gets the ability, and Homura gets nothing from her trait on conquest.**
- **Clockstopper will steal civilian promotions.** `PMMMClockstopper.lua:46` reads `if not v.Special and v.Combat >= 0`; should be `> 0`. The Help text promises civilian promotions cannot be stolen.
- `pPlot:GetUnit(0)` at line 17 assumes the capturing unit is first on the tile.
- **MG strength goes *down* on entering the Atomic era** (49 to 45), because `UNIT_MOBILE_SAM` (65) is the strongest MELEE/GUN unit gated on an Atomic tech and Infantry (70) is Modern. This hits everyone but gutted Homura specifically.
- Unguarded capital dereference at `PMMMHomuraDecisions.lua:62`.
- Dimensional Armory's strategy text says "the unique building for **Mitakihara**"; it belongs to Neo-Mitakihara.

### C. Assessment

**Intuitiveness.** The *least* legible of the four. "MG strength based on the most advanced met era" means her core stat silently changes when a civ she has met finishes a tech, with no notification. The leader-MG bonuses are small, conditional, and buried. The UU's steal is a random pick from an opaque set. One of her two decisions is a permanently greyed-out button.

**Power.** **Bottom tier, around Denmark/Ottomans (C-), and the weakest of these four.** MGs ~1 era ahead in strength when she meets a runaway (maybe +5 CS on 1-3 units), a Leader MG who comes back in 3 turns instead of 10, a Military Academy that costs 3 extra gpt and airlifts, a 15%-overpriced Infantry that arrives at Plastic and grants one random promotion per city capture, one decision that is a coinflip on the lobby composition, and one decision that does not work. No yield, growth or production bonus, no early tempo of any kind.

**Synergy.** Almost none. UA is about Magical Girls; UU and UB are about a late-Industrial standing army with zero MG interaction. The one real interaction is accidental: a Clockstopper that steals `PROMOTION_PMMM_ROSEBOW_INFANTRY` starts receiving the double-attack bonus in cities.

### D. Proposals

1. **light: pull the UU's ability forward and pay for it.** Move the steal to a Musketman-era UU, or at minimum revert the cost to 375. A conquest gimmick that unlocks at Plastic is dead content in most games.
2. **light: fix the civilian steal and the Help text.** `PMMMClockstopper.lua:46` to `v.Combat > 0`.
3. **moderate: give the era-scaling a visible military payoff.** `Trait_MovesChangeUnitClass` (`UNITCLASS_PMMM_MAGICAL_GIRL`, +1) and CP's `MultipleAttackBonus` or `Trait_FreePromotionUnitCombats` so her girls feel like time-manipulators.
4. **moderate: implement Time Stop, or replace the dead decision.** Add the `MISSION_PMMM_TIME_STOP` row, promotions named `PROMOTION_PMMM_TIME_STOP_<n>` with negative `MovesChange`, and set `TimeStopDuration = 1` / `TimeStopCooldown = 20` on the trait: the Lua matcher, the cooldown store, the UI tooltips and Decision 2 all already exist and would light up. Highest value-per-line fix in this whole audit. The Lua-free alternative is `GoldenAgeOnWar = 1` plus `Trait_YieldFromConquest`.
5. **rework: retheme the UB around protecting one city.** Dimensional Armory at 1 gold maintenance, keep the airlift, add Production 3 and 25 XP.

### E. Maintainer questions

1. Was Time Stop cut deliberately for the WFTW port, or lost in the migration from `rebellion/`? Every consumer of it survived.
2. Should the Clockstopper's steal be the *trait* (all her units, on any conquest) rather than a UU promotion that any civ can end up with?
3. Is the Atomic-era MG strength regression (49 to 45) known?

---

## 4. Demon Homura: CIVILIZATION_DEMON_HOMURA ("Homura's Realm")

### A. Kit as implemented

**UA "Lovevil" (`TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS`)**: three DB columns plus the largest trait script in the mod (`PMMMDemonHomuraTrait.lua`, 224 lines):

- **`NoMagicalGirls = 1`.** Expended Prodigies never become MGs; no Leader MG; no Hidden Witch Barriers; the Grief Seed UI is hidden. Compensation: a free Archer.
- **Subjugation ledger.** `PMMM.Subjugations[iPlayer]` is floored and written as a 9-bit set of `BUILDING_PMMM_DEMON_HOMURA_DUMMY_{1..256}` into the **current** capital (`PMMMDemonHomuraTrait.lua:23-49`). Each dummy carries `Building_BuildingClassYieldChanges` to `BUILDINGCLASS_PALACE` of its own magnitude for **Culture, Production, Science, Gold and Tourism**. Net: **N subjugations = +N to each of five Palace yields, capped at 511.**
- **Earning subjugations:** expend a Prodigy (+1); kill any enemy **non-leader** MG (+1, de-duplicated); an enemy MG vacationing to your territory (+0.5, and she permanently loses one promotion).
- **`MagicalGirlAttrition = 5`.** Any MG standing in her territory while at war with her takes **5 damage per turn** unless it has the immunity promotion granted at MG level 5+.
- **Golden Age engine.** Killing a Witch gives 50 GA points instead of a Grief Seed. Every turn she is not in a Golden Age, `floor(0.1 x (Buildings + Beliefs + Policies mood modifiers))` GA points.

**UU 1 Incubator Slave** (replaces Worker). Cost 70, **`WorkRate = 125` vs `100`**.

**UU 2 Clara Doll** (replaces Great General). `PROMOTION_GREAT_GENERAL`, **`PROMOTION_GREAT_ADMIRAL`**, `PROMOTION_DOES_NOT_BECOME_GMG`, and `PROMOTION_PMMM_CLARA_DOLL` granting `PROMOTION_PMMM_CLARA_DOLL_BUFF` to stacked allied units: `UnitPromotions_UnitClasses` vs `UNITCLASS_PMMM_MAGICAL_GIRL`, **Modifier 50**.

**No unique building.**

**Decisions** (`PMMMDemonHomuraDecisions.lua`):
- *Punish the Incubators* (lines 15-104). **Free.** Once per era *and* a `ceil(15 x iMod)`-turn gap; requires >= 1 Incubator Slave. Kills every slave and adds that many copies of a `NoLimit` building to the capital: **+1 permanent empire Happiness per slave killed**.
- *Pacify the World's People* (lines 110-176). **Free** except `(1 + N) x iMod` turns of Anarchy. Own capital gets `(N+1) x 5` copies of a +1% Culture/Production/Science/Gold building; every other major's capital gets `(N+1)` copies of +1 Happiness. Repeatable without limit.

**gPMMMTraits flags: `NoMagicalGirls = 1`, `CapitalBonusPerKilledMagicalGirl = 1`, `MagicalGirlAttrition = 5`.**

### B. Text vs code

- **Her own Great General gives her nothing.** `MadokaInitMagicalGirl` returns at `PMMMMagicalGirls.lua:373-375` for any unit with `PROMOTION_DOES_NOT_BECOME_GMG` **before** the Demon Homura subjugation credit at 378-386. The Clara Doll has exactly that promotion.
- **Clara Doll buff is +50%, text says +33%.**
- **`CapitalBonusPerKilledMagicalGirl = 1` is a dead parameter** (tested as `> 0`, then hardcoded +1).
- Clara Doll `_HELP` duplicates `_STRATEGY` verbatim, including a grammar error.
- **Iterator invalidated while killing.** `PMMMDemonHomuraDecisions.lua:61-66` kills units inside `pPlayer:Units()`; the attrition loop at `PMMMDemonHomuraTrait.lua:154-174` has the same hazard.
- **The training ban is bypassable** (CanFunc clears the era key before evaluating the turn gate).
- **Wrong-variable bug:** `PMMMDemonHomuraDecisions.lua:121` assigns to `Decisions_PunishIncubators.Desc` when it means `Decisions_PacifyTheWorld.Desc`.
- Pacify text says "all Yields" (only four are modified) and presents scaling bonuses as flat.
- Anarchy turns are never `math.ceil`'d.
- Civilopedia bullet 6 is missing its trailing `[NEWLINE]`.

### C. Assessment

**Intuitiveness.** The worst-documented and most state-heavy of the four, but with an honest attempt at a fix: she is the only civ whose leader Civilopedia has a "Complete Trait Description" section. The subjugation count is surfaced only by a city-view addin on the capital; the ledger is a 9-bit dummy-building encoding the player can never inspect.

**Power.** **Strongest of these four, roughly Assyria/Songhai tier (A-/B+), and the most exploit-prone.** Three engines compound: (1) the Palace stack: 15-25 subjugations by the Industrial era is realistic against MG civs, i.e. +20-ish each of five yields in one city; (2) Punish the Incubators is a gold-to-permanent-happiness converter with no cap on batch size; (3) Pacify gives unbounded stacking +5% to four yields in the capital for a turn of Anarchy each time. Her weakness is genuine: everything lands in the capital.

**Synergy.** Strong with the shared MG system: every other civ generates Magical Girls from Prodigies, so she always has targets, and the Clara Doll buff is precisely the tool for farming subjugations. Anti-synergies: her own Great General is excluded from her own engine; Prodigy-expenditure income competes with using those Prodigies; Punish the Incubators destroys the workers whose +25% work rate is her only early edge.

### D. Proposals

1. **light: fix the Clara Doll exclusion.** Move the `DOES_NOT_BECOME_GMG` early return below the Demon Homura branch.
2. **light: reconcile the Clara Doll number.** Keep 50 and fix the text.
3. **moderate: cap and re-price the happiness loop.** `MaxPlayerInstances` 10-12 instead of `NoLimit = 1`, and fix the iterator bug.
4. **moderate: spread the Palace stack.** Swap half of the dummy yield to `BUILDINGCLASS_COURTHOUSE`, or convert the ledger to CP's `Trait_CityYieldChanges` with a per-subjugation multiplier. Reward conquest breadth; reduce the lose-the-capital cliff.
5. **rework: replace the dummy-building bit-encoding.** A DLL column `CapitalYieldPerSubjugation` reading a single persisted integer would replace nine building classes, nine buildings and 45 yield rows with one lookup. The one place worth DLL time.

### E. Maintainer questions

1. Is the Clara Doll's exclusion from the subjugation engine intentional flavour, or the bug it looks like?
2. Should Punish the Incubators be batch-unlimited?
3. Is the Palace-only concentration deliberate (a one-city-challenge civ)?

---

## Summary

| Civ | Power tier | Biggest problem | Headline proposal |
|---|---|---|---|
| **Mitakihara** (Madoka) | B- (~Siam) | UA is invisible: +100 Mood is swallowed by the 1%/turn corruption floor for any healthy MG | Give the Mood theme an empire payoff: `Trait_YieldFromKills` Culture/Faith, era-scaled |
| **Madoka's Realm** (Ultimate Madoka) | A- (~Korea/Babylon) | Witch summoning is a hidden four-part trap, and "no Leader Magical Girl" is documented nowhere | Detune the summon and write the real trait text |
| **Neo-Mitakihara** (Homura) | C- (~Denmark) | Time Stop does not exist in the build, so her theme *and* one of her two decisions are dead | Restore Time Stop: mission row, `PROMOTION_PMMM_TIME_STOP_<n>` promos, trait `TimeStopDuration/Cooldown` |
| **Homura's Realm** (Demon Homura) | A-/B+ (~Assyria) | Everything concentrates in one tile via a 9-bit dummy-building ledger; her own UU is excluded from it | Move the subjugation credit above the `DOES_NOT_BECOME_GMG` return, and split yields Palace/Courthouse |
| *Cross-cutting* | | Three copy-paste `X.Desc =` bugs write to the wrong decision object | `PMMMUltimateMadokaDecisions.lua:94`, `PMMMDemonHomuraDecisions.lua:121` |
| *Cross-cutting* | | Two decisions kill units while iterating `pPlayer:Units()` | Apply the existing "collect first, mutate second" fix |
| *Cross-cutting* | | 13 `_CBP` text variants are unreachable | Add a CBP-conditional SQL path or delete the strings |
| *Cross-cutting* | | MG strength drops 49 to 45 entering the Atomic era | Floor the era table monotonically in `PMMMDataStorage.lua:316-342` |
