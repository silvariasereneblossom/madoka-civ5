# Kit audit: Nagisa, Kaoru/Umika (Kazumi), Oriko/Kirika (WFTW v27 on CP 5.4.6)

Research report produced 2026-09-16 for the Phase 4 mechanics scope. Numbers come from `build/sim_cp_wftw.db`.
Paths are relative to the repo. Claims about the Shirome gate, the Angelica Bears Entertainment value and the Dairy
dummy's trade-route gold were independently verified against the simulated database.

**Scope note first:** `PMMMPleiadesTrait.lua` and `PMMMShiromeTrait.lua` **are** the trait scripts for two of the three civs under audit; they are named after the civs' in-game `ShortDescription`s. `CIVILIZATION_KAORU_UMIKA` is "The Pleiades Saints" and its leader is Kazumi (`wftw/SQL/KaoruUmika/KaoruUmikaLeaderAndTrait.sql:4-10`: "For compatibility reasons, Kazumi is still KAORU_UMIKA internally"); `CIVILIZATION_ORIKO_KIRIKA` is "Shirome". So `PMMMPleiadesTrait.lua` is Kazumi's Freezer and `PMMMShiromeTrait.lua` is Oriko/Kirika's Future Sight. Both are loaded by `wftw/Lua/Gameplay/PMMMTraitBootstrapper.lua` (lines 74-87) from per-player flags cached in `MapModData.gPMMMTraits` (built in `wftw/Lua/PMMMDataStorage.lua:33-90`), and their per-turn entry points are dispatched from `OnDoTurnRunTraitScripts` (`PMMMTraitBootstrapper.lua:130-135`), with combat/capture hooks at lines 232-240.

The hook-up detail matters: **the Shirome script never loaded.** Its gate was `if MapModData.gPMMMTraits[iPlayer].LeaderMGUniqueMission then` (`PMMMTraitBootstrapper.lua:82`), but `Traits.LeaderMGUniqueMission` is `NULL` for Oriko/Kirika and for every other trait in the built database (`select count(*) from Traits where LeaderMGUniqueMission is not null` = 0). So `OnPlayerDoTurnShiromeTrait` was never dispatched, and two of the three advertised UA effects were dead. **Fixed 2026-09-16: the gate now also tests `LeaderMGIntrigueTurns` and `RevealCivLocations`.** The Pleiades gate (`EnableFreezerSystem == 1`, line 75) is correct and does fire.

---

## 1. Nagisa Momoe: Charlottine Empire

### A. Kit as implemented

**UA "Cheese!" (`TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE`, `wftw/SQL/Nagisa/NagisaLeaderAndTrait.sql:85-97`).** Two effects, and the trait row itself sets *no* other columns.

1. `Trait_ImprovementYieldChanges`: Pasture +1 Culture (lines 90-92). Pure DB, always on, no era scaling, no cap.
2. `Trait_PMMM_GoldenAgeResourceSpread`: `RESOURCE_COW` and `RESOURCE_SHEEP`, `ProbabilityPerTurn = 2` (lines 94-97). Mod-added table read only by Lua. Implementation is `NagisaGoldenAge` (`wftw/Lua/Gameplay/Traits/PMMMNagisaTrait.lua:10-52`), called from `PMMMTraitBootstrapper.lua:117-119` on `PlayerDoTurn`. Per turn, **only while in a Golden Age**, for each city: every plot in the city's 37-plot ring that holds a Cattle/Sheep **and** is within `PlotDistance <= 3` of the city rolls `Game.Rand(100) < 2` (lines 23-31). Each success queues one new resource, dropped on a randomly chosen "empty" plot in the same city (lines 42-46).

**The "no tiles" rule.** "Empty" is stricter than the tooltip: `GetResourceType() < 0 and GetFeatureType() < 0 and GetImprovementType() < 0 and not IsWater() and not IsMountain() and not IsCity()` (line 32). Forest, jungle, marsh, oasis, any improvement, and any existing resource all disqualify a tile. If a city has **zero** qualifying plots the whole queue is dropped (`if #EmptyPlots == 0 then break end`, line 39, the port fix for the old nil-index crash). So a tightly packed or fully improved empire silently stops receiving the trait's main payoff. New cattle are placed with quantity 1 and count as spread sources the following turn, so the effect compounds inside a long Golden Age.

**UB Magical Dairy** (`BUILDINGCLASS_CARAVANSARY` override, `NagisaCivilization.sql:31-33`). The DB row is identical to Caravansary apart from text, icon and flavors: Cost 120, 0 maintenance, Horseback Riding, +50% land TR range, +2 Gold on international land routes. All unique behaviour rides on a stacking dummy, `BUILDING_PMMM_MAGICAL_DAIRY_DUMMY` (`NagisaBuilding.sql:4-6, 58-64`), whose count is set each turn to the number of worked Cattle/Sheep tiles in the city (`wftw/Lua/Gameplay/Buildings/PMMMNagisaBuilding.lua:20-38`). Per stack: `TradeRouteRecipientBonus 2`, `TradeRouteTargetBonus 1`, `TradeRouteLandGoldBonus 2`, `TradeRouteSeaGoldBonus 2`. Separately, `NagisaCitiesBonusTrade` awards **5 Golden Age points per turn** for every Cattle/Sheep worked by the *far* city of any international route that starts or ends at a Dairy city (lines 45-92), suppressed entirely while already in a Golden Age (lines 41-44).

**UU Bubble Bomber** (`UNITCLASS_WWI_BOMBER`, `NagisaCivilization.sql:39-41`). Stats identical to Great War Bomber: 325 cost, 50 ranged, Range 6, 2 moves, Flight to Radar. Adds `PROMOTION_PMMM_BUBBLE_BOMBER` (`CityAttack 50`, `AttackFortifiedMod 50`). A second promotion, `PROMOTION_PMMM_BUBBLE_BOMBER_BONUS` (`RangedAttackModifier 33`), is toggled by `wftw/Lua/Gameplay/UniqueUnits/PMMMBubbleBomber.lua:12-63` whenever any at-war unit is within radius 2.

**Decisions** (`wftw/DecisionsMod/Lua/PMMMNagisaDecisions.lua`). *Enforce Mandatory Extended Recess*: 500 x speed Gold + 1 Magistrate, requires Scientific Theory, once per game; `POLICY_DECISIONS_NAGISA_RECESS`, **+1** Happiness per Public School. *Paint Charlotte's Mouth on the Gate of Castle X*: 100 x speed Culture + 150 x speed Gold, per city, requires a Castle; a free `BUILDING_DECISIONS_NAGISA_CHARLOTTE_GATE` (+2 Defense / +25 HP) and `PROMOTION_DECISIONS_NAGISA` (`NearbyEnemyCombatMod -10`, range 1) on garrisoned land units.

**gPMMMTraits flags: none.** Nagisa is gated on a child table rather than a flag column (`PMMMTraitBootstrapper.lua:48-59` iterates `Trait_PMMM_GoldenAgeResourceSpread`), and on `gPMMMUniqueBuildings[iPlayer] == BUILDING_PMMM_MAGICAL_DAIRY` for the UB script. No civ-specific MG missions or MG rules.

### B. Text vs code

- **`TradeRouteLandGoldBonus`/`SeaGoldBonus = 2` on the dummy is a dead effect.** These columns are x100 scaled: Caravansary uses 200 for "+2 Gold", Harbor 100 for "+1 Gold". At 2 the dummy grants 0.02 Gold per stack. `NagisaBuilding.sql:64` almost certainly wants 200. `TradeRouteRecipientBonus`/`TargetBonus` are *not* scaled, so those two do work.
- **Trait name promises a third effect that does not exist.** `..._MERCHANT_PLANT_CATTLE` and the tables `Trait_PMMM_UnitCreateResource` / `Promotion_PMMM_UnitCreateResource` exist in the schema but are empty and read by nothing. Great Merchants cannot plant cattle.
- **Trait tooltip understates the restrictions.** "if the tiles are not already improved" vs the code's no-feature/no-resource/no-mountain/no-water/no-city filter and the `<= 3` distance gate on source tiles.
- **Dairy strategy text vs help text disagree** on who gets what; the code (`TradeRouteRecipientBonus`) matches the Help.
- The Charlotte Gate code comment says "half defense effect of Walls"; it is 40%. The Recess code comment says "+2 Happiness"; the policy and tooltip both say +1.
- `iMagistrate` is never defined in this repo; it is a global from JFD's Events & Decisions/Rise to Power. Without that mod, Decision 1's `CanFunc` throws.

### C. Assessment

**Intuitiveness.** The Dairy is the problem child. Its payoff is a triple conditional the UI cannot show: *worked* Cattle/Sheep x *international* trade routes x whether you are currently in a Golden Age. The GA-point stream is invisible except for a one-line alert, it counts resources in **foreign** cities you do not control, and it shuts off exactly when you are doing well. The trait's spread is pure RNG at 2%/tile/turn, only during Golden Ages, and silently no-ops on built-out cities.

**Power.** Roughly **Denmark/Songhai tier, bottom third**. A 4-6 city game with two pastures per city is +8-12 Culture/turn from the Classical era, about one free Monument per city; the Dairy in a 3-cow capital with two incoming foreign routes is +6 Gold/turn to you and +3 to your partners; the GA engine realistically adds one extra Golden Age across a full game. Against Morocco Nagisa is strictly behind on both axes. The Bubble Bomber is a real upgrade (+50% vs cities plus a near-permanent +33% while defending) but it arrives at Flight and obsoletes at Radar, a ~30-turn window in a civ with no early or mid-game military identity.

**Synergy.** Internally consistent (pastures to culture to Golden Ages to more pastures) but the loop is too slow to close. Against the MG system there is almost nothing: no Soul Gem, Witch or mood interaction.

### D. Proposals

1. **light: fix the dead gold.** `NagisaBuilding.sql:64`: `TradeRouteLandGoldBonus`/`SeaGoldBonus` 2 to 200. Pure DB, one line.
2. **light: make Cheese! visible outside Golden Ages.** Add `Trait_ResourceYieldChanges` rows: `RESOURCE_COW`/`RESOURCE_SHEEP` +1 Gold, keep the Pasture +1 Culture. The civ is *always* paid for settling on herds.
3. **moderate: replace the RNG spread with a deterministic Golden Age package.** Flat "+1 Cattle or Sheep in each city on entering a Golden Age" (Lua, once per GA) plus `Trait_ResourceYieldChangesFromGoldenAge` (Cow/Sheep +2 Food during GAs) and `Trait_GAPToYield` (Golden Age points to Culture). Golden Ages become the civ's *spike*, not its lottery ticket. All three tables exist under CP.
4. **moderate: move the Dairy's Golden Age engine into the DB.** Replace the `GetTradeRoutes()` scan with `Trait_YieldFromImport`/`Trait_YieldFromExport` (2 Golden Age points per international route per era). Same fantasy, zero hidden Lua, AI-legible. Deletes ~55 lines of per-turn Lua.
5. **rework: give Nagisa an early UU.** Move the "small and unexpectedly dangerous" identity to a Classical/Medieval unit (a Charlotte-themed Pikeman or Composite Bowman with a `NearbyEnemyCombatMod`-style aura) and leave the Bomber as a second UU or a promotion line. `Civilization_UnitClassOverrides` + one `UnitPromotions` row; no Lua.

### E. Questions for the maintainer

1. Was `TradeRouteLandGoldBonus = 2` meant to be 200, or was the dummy meant to contribute nothing to your own routes?
2. `_MERCHANT_PLANT_CATTLE` and the two empty `UnitCreateResource` tables: cut on purpose, or lost in a version bump? It would be the cleanest place for a player-driven version of the spread.
3. Should the Golden Age point stream really be suppressed *during* Golden Ages, or was it meant to be banked?

---

## 2. Kaoru Maki & Umika Misaki / Kazumi: Pleiades Empire

### A. Kit as implemented

**UA "The Freezer" (`TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS`, `KaoruUmikaLeaderAndTrait.sql:85-91`).** One non-default column, `EnableFreezerSystem = 1`, plus `Trait_NoTrain UNITCLASS_SCOUT`: **Kazumi can never build a Scout.** Support from `Civilization_FreeUnits` (1 free Artificial Incubator) and `Civilization_FreeBuildingClasses` (a free, capital-only `BUILDING_PMMM_FREEZER`, a display shell; the real storage is a Lua table).

Everything else is `wftw/Lua/Gameplay/Traits/PMMMPleiadesTrait.lua`:

- **Capture.** `PleiadesOnCombatEnded` (lines 271-329) on `CombatEnded`. If a Pleiades player kills a non-leader `UNIT_PMMM_MAGICAL_GIRL` and the Freezer has room, the girl's promotions, XP and level are snapshotted, `Status` set to `MGACTIONSTATE_FREEZER`, `FreezerPlayer` set (lines 306-324).
- **Capacity.** `INITIAL_FREEZER_STORAGE` 3 + `floor(capitalPopulation / 5)` (lines 43-61). A size-20 capital holds 7.
- **Decay.** Every 3 turns each stored girl loses 1 Soul Gem; at 0 she witches out next to your capital (lines 336-358). A Grief Seed can top her up (`PleiadesFreezer.lua:88-109`).
- **The gamble.** `GetPleiadesPrediction` (lines 203-263) scores `era x 5 + academies x 5 + floor(SoulGem/10) + floor(divertedScience / (1% of all beakers ever researched)) + successes x 1`, then buckets: **<= 30 Very Bad**: she witches out beside your capital; **31-50 Bad**: she dies, +1 success; **51-70 Neutral**: she dies, you gain one turn of Science and Culture, +2 successes; **71-90 Good**: she revives as *your* Magical Girl with her promotions, +2 successes; **91+ Very Good**: 8 turns of Science instantly, half a Golden Age, and WLTKD in every city, +2 successes (`DoPleiadesRevival`, lines 86-156).
- **Capital loss.** If your capital falls, each stored girl rolls 25% revive for the *capturer*, 50% die, 25% witch (lines 380-422).

**UU Artificial Incubator** (`KaoruUmikaUnit.sql`). Own `UNITCLASS_PMMM_ARTIFICIAL_INCUBATOR`, `MaxPlayerInstances = 3`. Scout stats: 25 cost, 5 combat, 2 moves, 2 sight, ignores terrain cost, `NoBadGoodies`; **never obsoletes**, no goody-hut upgrade. `PROMOTION_ONLY_DEFENSIVE` and `PROMOTION_PMMM_ARTIFICIAL_INCUBATOR` (`ExtraWithdrawal 80`, `SoulGemPolishPercent 3`). Its `MISSION_PMMM_POLISH` adds 3% Polish to an adjacent friendly MG for all remaining movement, capped at 30%; Polish absorbs `floor(corruption/2)` of incoming Soul Gem damage (`PMMMArtificialIncubator.lua:47-66`).

**UB Angelica Bears** (`BUILDINGCLASS_PMMM_AMUSEMENT_PARK` override). Same shell as the Amusement Park: 360 Production, 3 gpt, Industrialization, requires a Theater, 1 Entertainer slot. Adds +2 Culture, +1 Tourism, and one `RESOURCE_PMMM_TEDDY_BEAR` per city (a unique Luxury, Happiness 4).

**Decisions** (`PMMMKaoruUmikaDecisions.lua`). *Fund Asunaro United F.C.*: 800 x speed Gold + 2 Magistrates, requires 4 Stadiums and Familiar tourism influence with at least half the living civs; Stadiums gain +1 Culture, +1 Gold and +20% city Tourism. *Publish a Novel*: `100 x era + 200` Gold and `50 x era + 150` Culture, requires Printing Press, once per era; a lump of Gold scaling with Great Works of Writing, plus +50 Tourism with all known civs.

**gPMMMTraits flags:** `EnableFreezerSystem = 1` only.

### B. Text vs code

- **The UB is a downgrade, not an upgrade.** Help text: "+4 Entertainment and +1 Tourism". Actual DB: `PMMMEntertainment = 1` against the base Amusement Park's **3**. The `UPDATE ... SET PMMMEntertainment = PMMMEntertainment + 1` at `KaoruUmikaBuilding.sql:98-100` is correct in intent, but the copying `INSERT` (lines 13-32) never includes `PMMMEntertainment`, so +1 landed on 0. Kazumi loses 2 Entertainment per park empire-wide, which feeds MG loyalty and vacation mood. The Help also omits the +2 Culture the building actually has.
- **Publish a Novel advertises 40% more gold than it pays.** `CanFunc` displays `works x 350` (line 114); `DoFunc` pays `works x 250` (line 155).
- **UA text is wrong about the mechanic.** "Based on your Technology level": it is era, Academies, her Soul Gem, diverted beakers and prior successes. It does not mention the decay clock, the capacity formula, that a bad roll spawns a hostile Witch at your capital, or that losing your capital scatters the Freezer.
- **The science slider is close to inert.** `GetAvailableDivertScience` returns only the progress on the *current* tech (`PleiadesFreezer.lua:228-234`), while each prediction point costs 1% of all beakers ever researched (line 223). By the Renaissance that is 2-6 points maximum.
- **Two crash-shaped `nil` globals in the Pleiades script.** `OnPleiadesDoTurn` lines 343-351 use `iMGKey` and `pPlayer` before either exists in scope (`pPlayer` is declared `local` only at line 359), so the Soul-Gem-hits-zero path throws. `OnPleiadesCityCapture` lines 388-392 and 405 have the same problem on two of three branches.
- **`PleiadesOnCombatEnded:277` uses `~= false` where every other site uses `== 1`.** Defanged only because `GetFreezerStorageMax` returns `-1` for non-Pleiades players.
- `SoulGemPolishPercent = 3` on the promotion is never read; the Lua takes the amount from `Missions.PMMMPolishAmount`.

### C. Assessment

**Intuitiveness.** The worst of the three by a distance. The Freezer is a five-outcome hidden-formula lottery whose inputs (Academies built, total lifetime beakers, an invisible "successes" counter) are not things a player tracks, and whose worst outcome punishes you with a Witch at your capital. It only engages against other Magical Girl civs; against vanilla civs or on a map without MG neighbours the UA is a null. The 3-Incubator cap plus the Scout ban means Kazumi explores worse than every civ in the game with a unit that cannot take a camp. Polishing is per-unit, per-turn, costs all movement for 3%, and needs 10 separate actions to reach the 30% cap.

**Power.** **Bottom tier, below Denmark.** For most of a 4-8 city game the effective kit is: a free Scout that cannot fight, no Scouts thereafter, one extra luxury per Amusement Park from Industrialization, and a nerfed Entertainment building. The two Decisions are genuinely strong but late and gated behind another mod. The Freezer's top outcome is game-swinging, but the arithmetic puts 91+ out of reach before the Industrial era: era 7 x 5 = 35 plus 8 Academies x 5 = 40 plus a full Soul Gem 10 = 85. At Classical era with no Academies the score is ~10: **Very Bad**, a hostile Witch. Early captures are a trap.

**Synergy.** The Incubator and the Freezer are the one place this mod's civs really engage the MG system, and the design is coherent: Polish keeps your own girls alive, the Freezer converts dead enemy girls into value. But the halves do not touch each other, the Freezer competes with your own Grief Seed economy, and nothing in the UB or Decisions supports either.

### D. Proposals

1. **light: fix the UB.** Set `PMMMEntertainment = 4` explicitly on `BUILDING_PMMM_ANGELICA_BEARS`, and add the +2 Culture to the Help text.
2. **light: make the Novel honest and the bears a monopoly.** Reconcile Publish a Novel to 300 for both; set `Resources.IsMonopoly = 1` with `MonopolyHappiness 2` / `MonopolyGALength 10` on `RESOURCE_PMMM_TEDDY_BEAR` (CP columns, all zero today).
3. **moderate: flatten the prediction formula to three outcomes and show it.** Drop Very Bad entirely (never spawn a Witch from a *voluntary* action; failure = "she dies, +1 success"), rescale to `era x 8 + academies x 6 + floor(SoulGem/5) + successes x 3`, and print the score and thresholds in the Freezer panel. Lua only.
4. **moderate: give the civ a first-half identity around the manuscript theme.** Add `Trait_LitYieldChanges` (Great Works of Writing +1 Culture +1 Gold) and `Traits.GreatWorkWLTKD = 5`. Both exist in this DB. Umika the novelist carries the economy from Drama onward so the Freezer can stay a situational spike.
5. **rework: retire the Scout ban.** Remove `Trait_NoTrain UNITCLASS_SCOUT`, raise `MaxPlayerInstances` to 4, add `Trait_FreePromotionUnitClass` giving the Incubator `PROMOTION_SENTRY`. Pure DB.

### E. Questions for the maintainer

1. Is a hostile Witch at your own capital the intended punishment for an early Freezer attempt?
2. Was the Scout ban a balance decision or a side effect of the Incubator's own unit class?
3. Should the Freezer be able to capture leader Magical Girls at all? Excluding them removes the most thematic capture in the mod.

---

## 3. Oriko Mikuni & Kirika Kure: Shiromeian Empire

### A. Kit as implemented

**UA "Infinitely Finite" (`TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH`, `OrikoKirikaLeaderAndTrait.sql:84-91`).** Three declared effects, all in mod-added Trait columns:

1. `RevealCivLocations = 1`: reveal a radius-1 ring around every other ever-alive player's starting plot (`PMMMShiromeTrait.lua:47-68`). One-shot, flagged by `PMMM.ShiromeRevealedCivLocations`.
2. `LeaderMGIntrigueTurns = 5`: every 5 turns, if the leader MG is within 2 tiles of foreign cities, pick one at random and call `GetRandomIntrigue(pChosenCity)` (`PMMMShiromeTrait.lua:13-38`).
3. `ExtraLeaderMG = 1`, `ExtraLeaderMGName` ("Kirika Kure"), portrait override, and `ExtraLeaderMGUniquePromotion = PROMOTION_PMMM_MAGICLAW`. Handled in `PMMMMagicalGirls.lua:486-516`, so **it works**: the civ starts with two leader Magical Girls, and Kirika permanently carries +15%/-15% attack/defence and projects the Magiclaw -1 Movement aura.

**Effects 1 and 2 were dead** until the gate fix (scope note). Note the port work at `PMMMShiromeTrait.lua:43-46` moved the reveal from `Events.LoadScreenClose` into the trait's turn path, so before the fix the reveal ran nowhere.

**UU Magiclaw** (`UNITCLASS_SWORDSMAN` override). Identical Swordsman stats (75 Production, 14 Combat, 2 Moves, Iron Working to Steel) with the Iron requirement deleted and `PROMOTION_PMMM_MAGICLAW` (`AttackMod 15`, `DefenseMod -15`). The aura is `Promotion_PMMM_GrantAdjacentEnemyPromotion` (Radius 1, `PROMOTION_PMMM_MAGICLAW_DEBUFF`, `MovesChange -1`), applied by `PMMMMagiclaw.lua:9-74` on `UnitSetXY` and `PlayerDoTurn`.

**UI Farsight Oracle** (`OrikoKirikaImprovement.sql:12-35, 40-47`). Worker-built at Theology (build time 700), `SpecificCivRequired`, `NoTwoAdjacent 1`, `AdjacentLuxury 1`, valid on Grass/Plains/Desert/Tundra/Snow, 20 pillage gold. Yields **+2 Faith +1 Culture**, rising to **+3 Faith +3 Culture** at Radio. `PROMOTION_PMMM_FARSIGHT_ORACLE` (`Recon 1`, `RangeAttackIgnoreLOS 1`) is granted to the owner's land combat units standing on it (`PMMMFarsightOracle.lua:11-27`).

**Decisions** (`PMMMOrikoKirikaDecisions.lua`). *Divine your Country's Future*: `60 x era` Faith, once every 25 x speed turns; 50/99 chance of a full Golden Age, otherwise Anarchy for `ceil(GoldenAgeLength / 3)` turns. *Sharpen up the New Recruits*: costs `BaseCombatStrength x 13` Gold and kills a land military unit created in that city this turn; the city gains +15 land XP for `(10 + ceil(strength/10)) x speed` turns.

**gPMMMTraits flags:** `LeaderMGIntrigueTurns 5`, `RevealCivLocations 1`, `ExtraLeaderMG 1` + the four Extra-leader descriptors.

### B. Text vs code

- **Two thirds of the UA tooltip was unimplemented** (gate bug, now fixed).
- **Farsight is owner-only, not "friendly".** Help says "Friendly units"; code requires `pPlot:GetOwner() == iPlayer` (`PMMMFarsightOracle.lua:18`).
- **The Oracle Help does not mention its build gate** (`BuildableOnResources = 0`, five terrain types inherited from the Chateau).
- `Decisions_DivineCountrysFuture` uses `Game.Rand(99)`, so the split is 50/99, not 50/100. Cosmetic.
- *Sharpen up* shows a stale duration in its enacted description (recomputed from whatever unit is in the city now).
- The `PlayerDoTurn` monitor for that decision runs for every player with no `MAX_MAJOR_CIVS` guard.
- `Improvement_AdjacentResourceYieldChanges` and `Improvement_YieldPerEra` exist in this DB and are unused; the Oracle's only scaling is the single Radio step.

### C. Assessment

**Intuitiveness.** As shipped, the clearest kit of the three, mostly because two thirds of the UA did not run. The Magiclaw's movement aura is well-signposted. The Divination decision is a coin flip between a full Golden Age and 5-8 turns of Anarchy: thematically perfect, mechanically a save-scum magnet and, for an AI, a self-inflicted wound.

**Power.** If the UA is live: around **Ethiopia/Spain tier**. As shipped before the fix: **Rome tier for the first 60 turns and nothing after.** The Magiclaw is legitimately excellent: an Iron-free Swordsman is the Legion's best property, and a radius-1 -1 Movement aura converts every melee engagement into a kill; paired with Kirika the civ has the strongest Classical/Medieval war package of the three. After Steel it has an Oracle worth 3 Faith/3 Culture on a luxury-adjacent tile (identical total yield to the Chateau but without its +50% defence, and gated behind Theology rather than Chivalry) and two Decisions. A front-loaded aggressive civ with no late game.

**Synergy.** Strong internal synergy on the war half (Kirika's free Magiclaw promotion, the Sharpen Up XP pump, the no-Iron requirement). Anti-synergy: the Oracle's Faith competes with Divination's cost rather than feeding a religion. Against the MG system the civ is well served: the extra leader MG doubles Grief Seed and mission throughput, but also doubles corruption exposure with no Polish equivalent.

### D. Proposals

1. **light: revive the UA.** Done: the gate now tests `LeaderMGIntrigueTurns`/`RevealCivLocations`.
2. **light: make Farsight actually friendly, and say what the Oracle needs.** Accept non-hostile plot owners in `PMMMFarsightOracle.lua:18`; add the terrain/resource restrictions to the Help text.
3. **moderate: give the Oracle a late-game reason to exist.** Add `Improvement_AdjacentResourceYieldChanges` (+1 Science per adjacent Luxury) and `Improvement_YieldPerEra` (+1 Culture per era from Renaissance).
4. **moderate: replace the Divination coin flip with a bought certainty.** Keep the Faith cost, drop the Anarchy branch, and pay out a Golden Age scaled by turns since last use; or, DB-side, use `Traits.TourismToGAP` / `Traits.GoldToGAP` to let Oriko convert a yield into Golden Age points continuously. "Foresight" should *reduce* variance.
5. **rework: put the sacrifice theme in the trait.** Killing your own land unit inside a city grants that city 15 XP for N turns *and* Oriko sees one Intrigue from the nearest foreign civ. `Trait_YieldFromKills`/`Trait_YieldFromLevelUp` for the yield side; the trigger needs Lua on `UnitPrekill`, which the bootstrapper already dispatches.

### E. Questions for the maintainer

1. Was `LeaderMGUniqueMission` ever meant to be set on this trait (an unshipped "Foresee" mission)?
2. Is the Anarchy branch of Divination intended as a genuine 50/50, or was it meant to be weighted by something never wired up?
3. The Oracle drops the Chateau's +50% defence. Balance choice, or should a "watchtower for prophets" keep it and trade away some Faith?

---

## Summary

| Civ | Current power tier | Biggest problem | Headline proposal |
|---|---|---|---|
| **Nagisa** | Low (~Denmark/Songhai) | Every payoff is conditional and invisible; the Dairy dummy's trade gold is x100-mis-scaled to nothing | Fix the scaling (2 to 200) and move the Golden Age engine to `Trait_YieldFromImport`/`Export` |
| **Kazumi (Kaoru/Umika)** | Bottom (below Denmark) | The UA does nothing against non-MG opponents and, before the Industrial era, almost always returns "Very Bad" (a hostile Witch at your capital); the UB is a stealth **nerf** (1 Entertainment vs 3) | Set `PMMMEntertainment = 4`, delete the Very Bad band, add a Great-Works-of-Writing trait so the civ has a first half |
| **Oriko/Kirika** | Mid early (~Rome), very low after Steel | Two of three UA clauses were dead code (gate fixed) | Give the Farsight Oracle era scaling so the civ has a second half |

**Cross-cutting notes.** (a) All six Decisions depend on JFD's Events & Decisions; the two that spend Magistrates additionally depend on `iMagistrate`, a global from Rise to Power. (b) `PMMMPleiadesTrait.lua` has two live nil-global crashes (lines 343-351, 388-405) on the Soul-Gem-zero and capital-capture paths. (c) `Trait_PMMM_TradeRouteBonusPerResource`, `Trait_PMMM_UnitCreateResource`, `Promotion_PMMM_UnitCreateResource` and `Trait_PMMM_MagicalGirlExtraAbility` are declared, empty, and read by nothing.
