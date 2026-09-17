# Phase 4 scope: Magical Girl civilizations, mechanics and balance

Date: 2026-09-17. Status: proposal for the maintainer's review. Nothing here is implemented except the
"already fixed" items in section 3.

Goal as stated: make the ten Magical Girl (MG) civilizations **more intuitive** and **competitive with the Lekmod
versions of vanilla civs**. Supporting research (five reports, all in this folder):

- [mg-system-audit.md](mg-system-audit.md): the shared MG system, its real value and its knobs
- [audit-madoka-homura.md](audit-madoka-homura.md): Madoka, Ultimate Madoka, Homura, Demon Homura
- [audit-sayaka-kyouko-mami.md](audit-sayaka-kyouko-mami.md): Sayaka, Kyouko, Mami
- [audit-nagisa-kazumi-oriko.md](audit-nagisa-kazumi-oriko.md): Nagisa, Kazumi (Kaoru/Umika), Oriko/Kirika
- [lekmod-baseline.md](lekmod-baseline.md): what "Lekmod-tier" means in numbers

All numbers were taken from the simulated CP 5.4.6 + WFTW v27 database (`build/sim_cp_wftw.db`), not from tooltips.

---

## 1. Five findings that reframe the work

**1. The Magical Girl system is not part of the MG civs' kit. It is a global rule.** Every civilization and every
city-state gets a leader Magical Girl on founding its capital and turns every expended Great Person into one. The
trait column meant to gate this (`MagicalGirlOnGreatPersonUse`) is never read. So when comparing an MG civ with
Babylon, the MG system cancels out: Babylon has girls too. The ten civs compete on their UA, UU and UB alone, plus a
handful of small MG modifiers (only six traits in the whole database set any).

**2. The shared system is worth roughly nothing and costs a lot of attention.** Missions produce no yields at all
(only Mood, XP and Soul Gem). A Magical Girl is always 30% weaker than the era's line unit and 47% weaker than a Witch.
An unmanaged girl dies in about 36 to 40 turns; a managed one needs one deliberate click every three to five turns.
Estimated value: 20 to 30% of a strong vanilla UA for a good player, zero or negative for a casual one, with variance
as large as the mean. Relationships, personalities and the promised per-Great-Person abilities do not exist (empty
tables under 775 lines of text).

**3. Several kits are partly dead or mis-scaled as shipped.** Two thirds of Oriko/Kirika's UA never ran (bootstrap
gate on a column no trait sets; fixed today). Homura's Time Stop does not exist in the build, so her theme and one of
her decisions are dead. Mami's one MG trait column is read by nothing. Kazumi's unique building has 1 Entertainment
where the base has 3. Nagisa's Dairy trade gold is scaled to 0.02. Sayaka's decision left a permanent Hotel plus
Airport in the capital (a regression from my consolidation; fixed today). Every Decision requires the Events and
Decisions mod, which is not installed, so that whole layer is inert in the current test setup.

**4. The power spread is wide, and the strong ones are strong for the wrong reasons.**

| Civ | As shipped | Why |
|---|---|---|
| Ultimate Madoka | A- | Yuri Valhalla (+3 Happiness per Garden, +10% growth), no Witch risk, steals enemy girls |
| Demon Homura | A-/B+ | Uncapped Palace stack, uncapped happiness-from-slaves loop, unbounded Pacify stacking |
| Kyouko | B on paper, A in practice | Uncapped population Mood bonus pins every girl at Ecstatic in a large empire |
| Sayaka | B, A with the (now fixed) permanent tourism dummy | Empire-wide healing is the real content; Harmony is invisible |
| Madoka | B- | A good Composite Bowman and a Public School with a Garden bolted on; UA invisible |
| Oriko/Kirika | B early, D late | Best Classical war package in the mod, nothing after Steel |
| Nagisa | C | Everything conditional on Golden Ages and foreign trade routes |
| Mami | C- | No UA before Gunpowder, a stat-identical Rifleman, a Teahouse worth +3 Production in one city |
| Homura | C- | No yields, no tempo, Time Stop missing, UU at Plastic |
| Kazumi | D | UA only works against other MG civs and usually punishes you; UB is a nerf; cannot build Scouts |

**5. Lekmod-tier has a recognizable shape.** One sentence, one or two numbers, live no later than Philosophy or
Drama, flat per-turn yields rather than percentages or bursts, no conditional stacking, no RNG. The benchmark curve
for an A-tier kit at Standard speed:

| Turn | Worth |
|---|---|
| 30 | one free unit, or +2 to +4 yield/turn empire-wide, already unlocked |
| 60 | +6 to +10 yield/turn, or a 20 to 30% modifier on one yield, or a 15 to 25% combat edge |
| 100 | +12 to +20 yield/turn (about one extra city's economy) |
| 150 | +25 to +40 yield/turn or two or three stacking effects; nothing new switches on this late |

Six of the ten MG civs deliver nothing measurable before turn 60. That, more than any single number, is the gap.

---

## 2. Design principles for the rework

1. **Every civ gets a flat, visible effect by Philosophy.** Preferably a CP data column (`Trait_*` tables), so it shows
   in the tooltip and the AI can value it.
2. **The MG hook is the second half of the kit, not the whole kit.** Each civ keeps one distinctive interaction with
   the shared system (Homura's respawn, Kazumi's Freezer, Ultimate Madoka's Cycle) and gets ordinary economy on top.
3. **Nothing hidden.** No per-unit counters, no bit-packed dummy buildings, no formulas the panel does not show.
   Where a dummy building is unavoidable, one building with a visible tooltip, not a binary ledger.
4. **No lotteries.** Replace every coin flip (Divination, Freezer bands, Golden Age cattle) with a bought certainty or a
   deterministic trigger. This is the single most consistent Lekmod principle.
5. **Tune the shared system first.** Buffing kits on top of a system that kills the player's units on a timer just
   moves the problem. The constants in section 4 change what every MG is worth, so they set the baseline.
6. **Decide the Decisions.** Either fold the two or three best ones into base kits or keep Events and Decisions as an
   optional layer that is allowed to be uneven. Do not balance around content most players never see.

---

## 3. Tier 0: bugs to fix regardless of design direction

Fixed today (committed with this document): Sayaka Dance Queen dummy never removed; Oriko/Kirika trait script never
loading; two undefined-variable crashes in the Freezer script (Soul Gem zero and capital capture).

Still open, all small and none design-dependent:

| Civ | Bug | Where |
|---|---|---|
| Kyouko | Sakura Church fallback compares a religion ID to a boolean, so a non-founder gets 0% FoodKept forever | `PMMMKyoukoBuilding.lua:24` |
| Kyouko | AI forces every damaged unit to pillage every turn | `PMMMKyoukoTrait.lua:189-192` |
| Kyouko | Develop Rocky: text says East India Company, code checks National Treasury; quotes 400, charges 300 | `PMMMKyoukoDecisions.lua:127-148` |
| Mami | Repeal never removes Japanese (inverted test); Italian branch dereferences an undefined `v`; city-name loop has no break | `PMMMMamiDecisions.lua:287, 212, 35-47` |
| Mami | Tiro Finale: AI fires it at turn start and then cannot move; humans can move two tiles and fire | `PMMMTiroMusketeer.lua:161-226, 11-21` |
| Nagisa | Dairy dummy trade gold is 2 where the column is x100 scaled (Caravansary uses 200) | `NagisaBuilding.sql:64` |
| Kazumi | Angelica Bears copies the Amusement Park without `PMMMEntertainment`, so +1 lands on 0 instead of 3 | `KaoruUmikaBuilding.sql:13-32, 98-100` |
| Kazumi | Publish a Novel shows 350 per work and pays 250 | `PMMMKaoruUmikaDecisions.lua:114, 155` |
| Demon Homura | Her own Clara Doll gives no subjugation: the "does not become MG" return precedes her branch | `PMMMMagicalGirls.lua:373-386` |
| Demon Homura | Punish the Incubators kills units while iterating them; attrition loop can do the same | `PMMMDemonHomuraDecisions.lua:61-66`, `PMMMDemonHomuraTrait.lua:154-174` |
| Demon Homura, Ultimate Madoka | Description assigned to the wrong decision object | `PMMMDemonHomuraDecisions.lua:121`, `PMMMUltimateMadokaDecisions.lua:94` |
| Homura | Clockstopper steals civilian promotions (`Combat >= 0` should be `> 0`) | `PMMMClockstopper.lua:46` |
| Madoka | Mi-ta-kun adds +2 Culture on shared tiles and counts unowned Wheat | `PMMMMadokaDecisions.lua:42-54, 168-179` |
| All | MG strength drops from 49 to 45 entering the Atomic era (Mobile SAM is the era's "best melee") | `PMMMDataStorage.lua:316-342` |
| All | Labyrinth clear removes 1 gold instead of the camp's gold | `PMMMWitches.lua:311-325` |
| All | 13 `_CBP` text variants are unreachable; Herald text says 50% corruption where code gives 100% | text files |

---

## 4. Phase 4a: the shared system

### 4a.1 The one structural decision

The unread `MagicalGirlOnGreatPersonUse` column means the system can be made MG-civ-exclusive with one Lua condition.
Three options:

- **A. Keep it global** (status quo). Every civ has girls; the world has Witches. Most faithful to the mod's premise.
  Cost: vanilla-civ players in a Lekmod lobby inherit the babysitting, and MG civs get no credit for the system.
- **B. Exclusive to MG civs.** Vanilla civs get no girls; Witches still replace barbarians for everyone. The MG
  package becomes a real component of the MG civs' UA and can be counted toward the Lekmod benchmark. Cost: the
  world feels emptier; ten civs must carry all the MG content.
- **C. Hybrid.** Vanilla civs get the leader girl only (one unit, respawning, no Great Person conversion). Keeps the
  flavor, removes most of the babysitting for non-MG players.

Recommendation: **B for multiplayer, C for single player**, switchable by one GameDefine, defaulting to C. This is
the question to answer first, because it decides how much of each civ's power budget the shared package may claim.

### 4a.2 Constants (pure DB, `WFTWGameDefines.xml` and `SQL/Shared/MGMoods.sql`)

| Constant | Now | Proposed | Effect |
|---|---|---|---|
| `MAGICAL_GIRL_STRENGTH_PERCENT` | 70 | 90 | signature unit stops being obsolete on arrival |
| `WITCH_STRENGTH_PERCENT` | 133 | 110 | MG vs Witch becomes a fair fight, not a losing trade |
| `SOUL_GEM_LOSS_PER_HP_REGENERATED` | 1 | 0 (or 0.25) | removes the main hidden drain; healing stops costing seeds |
| `BASE_GRIEF_SEED_RECOVER_AMOUNT` | 40, x BarbPercent | 50, flat | Marathon no longer gets 100 |
| `MGMOODMOD_KNOWS_THE_TRUTH` | -1500 effective | -300 | The Truth becomes a wound, not an execution |
| Homesick / No Socializing / No Vacation caps | 1000 / 500 / 500 | 300 / 200 / 200 | unmanaged girls stop dying on schedule |
| Restlessness | -15/turn, cap 375 | remove | punishes peaceful play for no design reason |
| `MG_Moods.SoulGemCorruptionMod` | -5 to +5 | -2 to +2 | flattens the death spiral |
| `HIDDEN_WITCH_FINDABLE_RADIUS` | 1 | 2 | halves Witch Hunt attempts |
| `HIDDEN_WITCH_SPAWN_CHANCE_PERCENT_PER_CITY` | 25 | 15 | |
| `HIDDEN_WITCH_GROWTH_PROGRESS_REMOVED_PER_TURN` | 10 | 5 | |
| `XP_GAINED_FROM_SPARRING` | 10 | 25 | makes Spar worth three turns off-map |
| `AI_MG_LOYALTY_BONUS_PER_TURN` | 1 x handicap | flat 1 | AI on Immortal currently never loses a girl |
| `MAX_BARBARIANS_FROM_CAMP_NEARBY`, `BARBARIAN_TECH_PERCENT` | 3, 90 | 2, 100 | the mod's hidden difficulty bump |

### 4a.3 Lua changes (small, each self-contained)

- Remove the `math.max(..., 1)` corruption floor (`PMMMMagicalGirls.lua:824`) so good Mood can reach zero decay. This
  is what makes Madoka's and Homura's mood traits do anything for a healthy girl.
- Auto-consume Grief Seeds for humans below a threshold, mirroring the AI branch. Biggest click reduction available.
- Let the player choose the Vacation destination instead of a shuffled deck.
- Make the era strength table monotonic.
- Gate Great-Person conversion on the trait column per 4a.1.
- Surface in the info panel: next turn's corruption breakdown, the witch-out percentage, Home City, Adapted Terrain.

### 4a.4 Give missions a yield

Today the mission suite is pure upkeep. Two cheap additions turn girls into an economy: Witch kills grant yields via
CP's `UnitPromotions_YieldFromKills` (Culture and Faith, era-scaled), and Socialize with a foreign civ grants a small
Tourism pulse. Both are data rows, both visible, both give the player a reason to use the units.

### 4a.5 Dead content

Either implement Relationships and Personalities (the tables and 775 lines of text exist; the code does not) or delete
the promises from the unit help text. Recommendation: delete the text now, put Relationships on the Phase 5 list as
a feature, not a fix.

---

## 5. Phase 4b: per-civ packages

Each package is one identity sentence, then the recommended changes with implementation class (DB = data rows only,
Lua = existing script edit, DLL = needs the custom build). Target after the package is Lekmod A/B tier for all ten.

### Madoka Kaname (Mitakihara), B- now, target A-
*Hope pays out: fighting near her makes everyone stronger, and every Prodigy she spends feeds the empire.*
- DB: `Trait_YieldFromKills` Culture 3 + Faith 2, era-scaled. Visible turn-1 UA.
- DB: `Trait_GreatPersonExpendedYield` Faith 30 + Culture 30, era-scaled, so expending a Prodigy (which creates a girl) is an empire event.
- DB: `MGMoodBonus` 100 to 200 once the corruption floor is gone; keep the doubled Fought-Near-Leader moodlet.
- DB: Middle School adds Faith 2; rename the wonder or move it off Scientific Theory.
- Lua (decision): Mitakiharafest gate becomes "two luxuries connected + Monument", 25-turn period speed-scaled.

### Ultimate Madoka (Madoka's Realm), A- now, target A- (fix the trap, spread the power)
*Despair is not the end: her girls come back, and their return pays.*
- Text: state no leader girl, the level reset, and the summon costs.
- Lua: summon corruption flat x2; on-death loss capped at 25 Soul Gem; Broken Psyche 5 turns and -25%.
- Lua: each Law of Cycles departure grants Faith and Golden Age points (one line in `DoLawOfCyclesTakeaway`).
- DB: fold Yuri Valhalla's Garden happiness into the Luminous Garden at +1 Happiness (visible, no Decisions dependency); keep `CityGrowthMod` in the decision if the layer stays.
- Question: should Lead Away target leader girls?

### Homura Akemi (Neo-Mitakihara), C- now, target A-
*Repeat the month: she is fastest at getting back up, and her army learns from every loop.*
- DB: implement Time Stop with the existing plumbing: `MISSION_PMMM_TIME_STOP` row, `PROMOTION_PMMM_TIME_STOP_<n>` promotions with negative `MovesChange`, trait `TimeStopDuration 1` / `TimeStopCooldown 20`. The matcher, cooldown store, UI and her second Decision all light up. Highest value per line in the whole scope.
- DB: `Trait_MovesChangeUnitClass` Magical Girl +1; `Trait_FreePromotionUnitCombats` melee and gun with `MultipleAttackBonus` or a +10% attack promo (the "I have done this before" edge).
- DB: Thief of Time back to Infantry cost (375) and the steal moved to the trait (`FreeUnitOnConquest` / `Trait_YieldFromConquest` Science, era-scaled) so it is hers and not the unit's; Clockstopper fix regardless.
- DB: Dimensional Armory maintenance 4 to 1, add Production 3.

### Demon Homura (Homura's Realm), A-/B+ now, target A- (cap the exploits, keep the fantasy)
*She takes: every girl she breaks, every Prodigy she consumes, feeds her seat of power.*
- Lua: Clara Doll counts as a subjugation (move the early return).
- DB: Punish the Incubators capped at 12 lifetime; Pacify capped at 5 enactments or with a growing Anarchy cost.
- DB or DLL: split the Palace stack so half goes to Courthouses (`Trait_CityYieldChanges` scaled per subjugation), or replace the 9-bit ledger with a DLL column. The only place in this scope where DLL time is clearly justified.
- Text: Clara Doll +50% (keep 50, fix the text).

### Sayaka Miki (The Oktavians), B now, target A-
*Justice heals: her Great Musicians and her music halls keep the army standing.*
- DB: kill-to-Musician points via `Trait_GreatPersonProgressFromKills`, no Acoustics or Guild gate.
- DB: Stage of Oktavia `HealRateChange` +15 in its city plus `Traits.UnitHealFromGreatPersonBirth` 25 (empire heal on every Great Musician). Delete the per-turn Lua sweep.
- DB: Cutlass Conductor `HPHealedIfDestroyEnemy` 25 instead of Harmony; delete the Harmony dummy.
- Lua: tourism combat bonus only at war, 10/15/20/25/30.

### Kyouko Sakura (Kazamino), B/A now, target A- (cap the mood, publish the numbers)
*Never share your food, until you choose to: her armies eat off the land and her cities keep what they grow.*
- DB: cap `MGMOODMOD_TRAIT_POPULATION` at 150.
- DB: Sakura Church flat `FoodKept` 15; delete the 20-dummy scheme.
- DB (rework, recommended): Stolen Food becomes a free promotion with `HealOnPillage` / `PartialHealOnPillage` plus `Trait_YieldFromKills` Food. Removes the hidden counter, the cooldown and ~900 lines of Lua.
- Lua: remove the AI forced pillage. Optional: Give Food can target a friend's or city-state's city for a Faith or Culture return.

### Mami Tomoe (Nazione di Tiro), C- now, target A-
*The mentor with friends: allies and friendships pay from turn one, and her cities train veterans.*
- DB: `Trait_YieldFromCSAlly` +2 Production +1 Science; `Trait_YieldFromCSFriend` +1 Production. Turn-1 UA.
- DB: Teahouse flat +2 Production and `Experience` 15; friendship scaling via `Trait_YieldChangesPerTradePartner`. Delete the 12-building bit ledger.
- DB: Tiro Musketeer retargeted to Musketman (Gunpowder), Finale strength 40.
- Lua: Finale needs movement left; AI firing moved off turn start.
- Decide: implement `MagicalGirlRelationshipModifier` with Relationships (Phase 5) or delete the column.

### Nagisa Momoe (Charlottine Empire), C now, target B+/A-
*Small and dangerous: cheese pays every turn, Golden Ages are a spike, and the bomber is a finisher.*
- DB: dummy trade gold 2 to 200; `Trait_ResourceYieldChanges` Cow and Sheep +1 Gold; keep Pasture +1 Culture.
- DB: Golden Age package: `Trait_ResourceYieldChangesFromGoldenAge` Cow and Sheep +2 Food, `Trait_GAPToYield` to Culture; spread becomes a flat +1 herd per city on entering a Golden Age (Lua, once per age).
- DB: Dairy engine via `Trait_YieldFromImport` / `Trait_YieldFromExport` (Golden Age points per international route); delete the trade-route scan.
- Consider a Classical UU with a small fear aura, with the Bubble Bomber kept as second UU.

### Kazumi / Kaoru and Umika (Pleiades), D now, target B+
*Writers and athletes: the novel carries the economy; the Freezer is a readable late spike.*
- DB: Angelica Bears `PMMMEntertainment` 4 explicit; Teddy Bear monopoly (`IsMonopoly`, `MonopolyHappiness 2`, `MonopolyGALength 10`).
- DB: `Trait_LitYieldChanges` Great Works of Writing +1 Culture +1 Gold; `Traits.GreatWorkWLTKD` 5. First-half identity from Drama.
- DB: remove the Scout ban; Incubator cap 4 with Sentry.
- Lua: Freezer to three outcomes, no Witch from a voluntary action, score shown in the panel.
- Question: may the Freezer take leader girls?

### Oriko Mikuni and Kirika Kure (Shiromeian Empire), B early and D late now, target A-
*Foresight reduces variance: she sees the map, reads intrigue, and her oracles scale.*
- Done: trait script now loads (reveal and intrigue live).
- DB: Farsight Oracle `Improvement_AdjacentResourceYieldChanges` +1 Science per adjacent luxury; `Improvement_YieldPerEra` +1 Culture per era from Renaissance.
- Lua: Farsight for non-hostile plot owners; Help text states terrain and resource gates.
- Lua (decision): Divination without the Anarchy branch, or replaced by `Traits.GoldToGAP` / `TourismToGAP` continuous conversion.
- Consider moving Sharpen Up Recruits into the UA (sacrifice a unit in a city: XP for N turns plus one Intrigue).

---

## 6. The Decisions layer

Six civs' two Decisions plus Mami's four and Ultimate Madoka's two are the mod's most characterful content and
currently the least reachable. Three options:

1. **Drop the dependency:** port the best one per civ into the base kit as a building, policy or trait effect (Yuri
   Valhalla to the Luminous Garden, Punish the Incubators capped as a Demon Homura mission, Publish a Novel as a
   Great Work event) and delete the rest.
2. **Keep as an optional layer** with the Tier 0 bugs fixed and balance not counted toward the benchmark.
3. **Bundle a minimal decision framework** (the Events and Decisions mod is MIT-style and CP-compatible) so the layer
   always exists.

Recommendation: 1 for the two or three decisions that carry identity, 2 for the rest. Option 3 adds a UI dependency
to the Lekmod multiplayer patch that is not worth carrying.

---

## 7. Order of work and effort

| Step | Content | Class | Rough size |
|---|---|---|---|
| 4a.0 | Tier 0 bug list | Lua/DB/text | one pass, ~20 small edits |
| 4a.1 | The global-vs-exclusive decision, one GameDefine plus one Lua gate | Lua | small |
| 4a.2 | Constants table | DB | small; needs playtest |
| 4a.3 | Floor removal, auto-seed, vacation choice, monotonic strength, panel readouts | Lua/UI | medium |
| 4a.4 | Mission yields | DB | small |
| 4b | Ten civ packages, DB items first, then the Lua items | DB then Lua | medium per civ; Kyouko and Mami reworks are the largest |
| 4c | Demon Homura ledger replacement | DLL | only if the DB split is not enough |
| Test | Simulator run per change, then in-game with the checklist | | continuous |

Every DB change is verifiable offline with `scripts/civdb.py`; only the Lua items need in-game turns.

---

## 8. Questions for the maintainer, in priority order

1. **Global, exclusive, or hybrid** Magical Girl system (4a.1)? This decides everything else.
2. Should the balance target be **CP single player**, **Lekmod multiplayer**, or both with one data set? The benchmark
   numbers above assume Standard speed; Lekmod lobbies run Quick or Online, which favors turn-1 flat effects even more.
3. **Decisions:** fold, keep optional, or bundle (section 6)?
4. **Time Stop:** was it cut on purpose in the WFTW port, or lost? Every consumer survived, so restoring it is cheap.
5. **Ultimate Madoka and Demon Homura have no leader girl.** Deliberate handicap to buy out of, or accident?
6. May **leader girls be captured** (Freezer) or **led away** (Herald)? Excluding them removes the most thematic
   interactions in the mod.
7. Is **Demon Homura** meant to be a one-city civ, or should conquest breadth pay?
8. Is the **1% corruption floor** sacred? Removing it is what makes the mood-based traits real.
9. Kyouko: was excluding Magical Girls from Stolen Food a balance call or an artifact?
10. Nagisa: was the Great Merchant "plant cattle" clause (in the trait's own name, empty tables) cut or lost?
11. Relationships and Personalities: implement in Phase 5, or delete the text now?
12. Is the CBP / Vox Populi build still a target? 13 `_CBP` text variants exist and nothing selects them.
