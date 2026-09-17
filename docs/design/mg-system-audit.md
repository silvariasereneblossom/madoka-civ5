# Shared Magical Girl system: value, cost and tuning levers

Research report produced 2026-09-16 for the Phase 4 mechanics scope. Source of truth for numbers is
`build/sim_cp_wftw.db` (CP 5.4.6 + WFTW v27, Standard speed) unless a game speed is named. The four
load-bearing claims in section 0 (global system, unread gate column, corruption floor, empty relationship
and personality tables) were independently spot-checked against the code and the simulated database.

## 0. The premise needs correcting first

**The MG system is not an MG-civ perk. It is a global rule change that applies to all 55 civilizations and to city-states.** `MadokaInitMagicalGirl` fires on `GameEvents.GreatPersonExpended` for any `iPlayer < MAX_CIV_PLAYERS` with no civ check (`wftw/Lua/Gameplay/MagicalGirls/PMMMMagicalGirls.lua:367-412`), and `CreateFirstLeaderMagicalGirl` gives a leader MG to every player who founds an original capital, explicitly including city-states, excluding only Ultimate Madoka and Demon Homura (`PMMMMagicalGirls.lua:416-427`). The gate column `Traits.MagicalGirlOnGreatPersonUse` (declared at `wftw/SQL/Shared/MadokaTableUpdates.sql:12`) is **never read by any Lua file in the mod**.

So as a "second unique ability shared by the ten MG civs", its differential worth against Babylon or Poland is approximately **zero**. Babylon also gets a leader MG, also turns its Great Scientist into one, and also has to babysit Soul Gems. What actually differentiates the MG civs is the small set of trait columns that *modify* the shared system, and only six traits in the whole DB set any of them:

| Trait | MG-system effect |
|---|---|
| `TRAIT_STEAL_ENEMY_UNIQUE_ON_CONQUEST` (Homura) | leader respawn -75% (10 to 3 turns), leader promo `PROMOTION_PMMM_HOMURA_TRAIT`, `MaximumMetEraMGStrength=1` (MG strength uses the highest era among met civs) |
| `TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH` (Oriko/Kirika) | `ExtraLeaderMG=1`: two leader MGs from turn 1 |
| `TRAIT_NO_WITCHES` (Ultimate Madoka) | `NoWitches`, `CanSummonWitches` |
| `TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS` (Demon Homura) | `NoMagicalGirls=1` |
| `TRAIT_AMPHIB_WARLORD` (Askia, **vanilla**) | `WitchBarrierXPMultiplier=2` |
| `TRAIT_FREE_ARCHERY_BONUS_GARRISON_ATTACK` (vanilla) | `MGMoodBonus=100` |

Two of the six belong to vanilla leaders. Mami's `MagicalGirlRelationshipModifier` is dead because relationships are unimplemented (below).

## 1. Acquisition, count and cost

**Sources.** (a) One leader MG on founding the original capital, free, may move the turn it spawns, gets `PROMOTION_PMMM_MAGICAL_GIRL_LEADER` (+20% CS) and `PROMOTION_PMMM_IMMUNE_TO_TRUTH` (`PMMMMagicalGirls.lua:210-220, 253-256`). (b) One MG per Great Person expended, inheriting the GP's name, free promotions and home city; cannot move that turn (`PMMMMagicalGirls.lua:317-319`). (c) Pleiades freezer revivals. There is no Kyubey contract, no gold/faith purchase, no per-turn spawn roll: `Units.Cost = -1`, `FaithCost = -1`, `PrereqTech = NULL`.

**Caps.** None. `UnitClasses.MaxPlayerInstances = -1` for `UNITCLASS_PMMM_MAGICAL_GIRL` (only `UNITCLASS_PMMM_ARTIFICIAL_INCUBATOR` is capped, at 3).

**Cost.** Zero production, zero gold (`NoMaintenance = 1`), zero happiness (`Unhappiness = 0`). The only hard cost is `MilitarySupport = 1`: MGs count against unit supply and therefore against the over-supply production penalty. Everything else is attention and risk.

**Typical count (Standard, average empire).** T50: 1 (2 for Oriko/Kirika); the first GP is rarely expended before T60. T100: 2-4. T200: 10-16 *born*, but 3-6 alive; the rest have witched out or defected.

## 2. What an MG does

**Combat.** Base strength is recomputed per era as `floor(era's strongest non-unique MELEE/GUN unit x 70%)` (`wftw/Lua/PMMMDataStorage.lua:308-346`, `MAGICAL_GIRL_STRENGTH_PERCENT = 70`). Computed against the shipped DB:

| Era | best melee | MG | Witch (133%) | Familiar (50%) |
|---|---|---|---|---|
| Ancient | Spearman 11 | **7** | 14 | 5 |
| Classical | Swordsman 14 | **9** | 18 | 7 |
| Medieval | Longswordsman 21 | **14** | 27 | 10 |
| Renaissance | Musketman 24 | **16** | 31 | 12 |
| Industrial | Rifleman 34 | **23** | 45 | 17 |
| Modern | Infantry 70 | **49** | 93 | 35 |
| Postmodern | Mobile SAM 65 | **45** | 86 | 32 |
| Future | XCOM 100 | **70** | 133 | 50 |

An MG is therefore always **30% weaker than a contemporary line unit and 47% weaker than a Witch**. Modifiers close some of that: Soul Gem state gives +20/+5/-5/-15/-30% (`wftw/SQL/Shared/MGStates.sql:51-69`), Mood gives +100 to -100% in eleven steps, the leader promo +20%. A spotless, ecstatic leader MG runs at 7 x (1 + 0.20 + 0.20 + 1.00) = ~17 in the Ancient era; a critical, despairing one is at zero.

**Promotions.** `PromotionClass = UNITCOMBAT_MAGICALGIRL` opens a 44-entry tree: Offense/Defense Training branching into Siege, Skirmish, Sentry and Support lines (3 trainings + 2 specialisations + 1 mastery each), plus Charisma I/II, Patriotism, Teacher, Trainer I/II. XP sources: 5 per Witch killed (scaled by `ExpModifier` policies, `Moods/PMMMCoreMoods.lua:410-418`), 15 for clearing a Witch's Labyrinth (`PMMMWitches.lua:311-323`), 10 per Spar.

**Missions** (`wftw/SQL/Shared/MGMissions.sql`; state durations from `MG_ActionStates`):

| Mission | Off map | Yield | Cooldown | SG cost |
|---|---|---|---|---|
| Witch Hunt | 1 turn | reveals a Hidden Barrier within 1 tile: 1 Witch + 2 Familiars (3 with Raging); -10 diplo per reveal in another major's land, +10 CS influence in a minor's | none | none |
| Socialize | 0 (all movement) | +20 Mood each, cap +300, decays after 15 turns; resets the <= -500 "hasn't socialized" penalty | none | none |
| Vacation | 5 turns | +10 Mood per point of the destination's Entertainment; +/-25 Loyalty (`PMMMReturnMapFunctions.lua:143-163`) | destination is rolled, not chosen | none |
| Spar | 3 turns | +10 XP to both girls | 10 turns, one pair per city | none |
| Write Home | 3 turns | halves the Homesick penalty for 20 turns | Post Office required | none |
| Phone Home | 0 (all movement) | same | Phone Network required | none |
| Dull Pain | 1 movement | ignores the injury Mood penalty for 5 turns, at -20% attack and -1 move | 5 turns | none |
| Grief Seed | 1 movement | +40% Soul Gem (Standard) | needs a seed | n/a |

No mission costs Soul Gem. `Missions.PMMMSoulGemCorruptionBase` and `PMMMPolishAmount` exist but are unused by the base missions.

**Yield value.** The missions produce *no* gold, science, culture or faith. Their entire output is Mood, XP and Soul Gem. Entertainment is likewise not a yield: it is a hidden per-city score from 21 buildings (Marina 4, Island Resort 8, Winter Resort 8, Convention Center 4 +50%, Nightclub +25%, Panathenaic +50%/citizen, wonders 3-4 each) that feeds only three things: Vacation mood, Loyalty (`+1 per 30 of Tourism+Entertainment`), and vacation-destination weighting. A 20-Entertainment empire converts a 5-turn Vacation into +200 Mood and +25 Loyalty. In gold-equivalent terms the whole mission suite is worth **0 per turn**; it is pure upkeep of an asset that itself produces no yield.

**Moods.** 25 modifiers, clamped to +/-500, bucketed into 11 levels with `SoulGemCorruptionMod` -5 to +5, `LoyaltyChange` +5 to -5 and `CombatPercent` +100 to -100. The dangerous ones are the accumulators: Homesick -20/turn past 20 turns from home, cap -1000; No Socializing -20/turn past 15, cap -500; No Vacation -20/turn past 25, cap -500; Restlessness -15/turn past 20 without combat, cap -375; Injured -3 per damage point, cap -300; Hostile Terrain -150 (-300 if she is adapted to a *different* hostile terrain); **Knows The Truth -1500, then -750 after 25 turns** (`PMMMCoreMoods.lua:1648-1667`). Positives: Empire Happiness x3, Golden Age +50, Witch kill +100 (cap +500), Socializing +20 (cap +300).

**Relationships and personalities do not exist.** `MGRelationships.sql` is a single commented-out block (`wftw/SQL/Shared/MGRelationships.sql:1-35`) and `MG_RelationshipLevels`, `MG_PersonalityTraits`, `MG_ResponseTypes`, `MG_PersonalityTraitBlocks` and the three personality child tables all have **0 rows** in the shipped DB, despite 635 lines of personality text and 140 lines of relationship text. `Trait_PMMM_MagicalGirlExtraAbility` is also empty, so the promised GP-class ability does not exist.

**Leader MG extras:** +20% CS, immune to The Truth, Loyalty pinned to 100 every turn (`PMMMMagicalGirls.lua:656-658`), exempt from No-Vacation and Inadequacy, cannot vacation, and respawns at the capital after `ceil(10 x DealDuration/30)` turns at **50% Soul Gem** (`PMMMMagicalGirls.lua:567, 888-901`): 10 turns Standard, 3 for Homura, 30 on Marathon.

## 3. The Soul Gem economy

Per turn, in `MagicalGirlUpkeep` (`PMMMMagicalGirls.lua:802-869`):

```
corruption = SOUL_GEM_LOSS_PER_TURN (1)
           + healAmount x SOUL_GEM_LOSS_PER_HP_REGENERATED (1)      -- healAmount = max(floor(damage/10),1)
           x 2 + floor(distance/2)                                   -- only if she has a summoned Witch
corruption = max(corruption + Mood.SoulGemCorruptionMod, 1)          -- floor of 1, always
```

**The floor of 1 is the key constant**: no Mood, promotion or trait can ever push per-turn decay below 1%. A perfectly-managed MG still dies of old age in 100 turns without seeds.

**The healing cost is the real drain.** Every HP regenerated costs 1% of the gem. Going from 1 HP to 100 HP costs ~100% Soul Gem, **2.5 Grief Seeds** at Standard speed. Since an MG fights at 70% strength against Witches at 133%, she takes most of the damage in any Witch fight she initiates.

**Grief Seeds.** One per Witch killed, awarded to `iKillerPlayer` regardless of unit type (`PMMMWitches.lua:282-307`): any Warrior can farm them. Restoration is `min(floor(40 x BarbPercent/100 x ragingMult x noBarbMult), 100)` (`PMMMDataStorage.lua:361-379`): **Quick 26, Standard 40, Epic 60, Marathon 100**, x1.5 if No Barbarians is on. City-states get one free seed every `DealDuration` turns. The AI spends one automatically at <= 50% gem; a human must click.

**Thresholds** (`MG_SoulGemStates`): Spotless 90-100 (+20% CS), Clean 70-89 (+5%), Tarnished 30-69 (-5%), Dirty 10-29 (-15%), Critical 0-9 (-30%, `CanBecomeWitch = 1`).

**Witch roll** (`PMMMMagicalGirls.lua:857-867`): while Critical, each turn `Game.Rand(100) <= 10 + (9 - SoulGem) x 5`. So 10% at SG 9, 30% at 5, 50% at 1. At 0 she converts automatically. Expected survival once Critical, decaying at 1/turn: ~3 turns. Ultimate Madoka's `NoWitches` replaces this with the Law of Cycles: she vanishes for `ceil(30 x 33%) = 10` turns and returns at **100% gem but Level 1 and 0 XP** (`wftw/Lua/PMMMGeneralFunctions.lua:388-409`), which is a full promotion wipe.

**Worked lifespan, Standard speed, a non-leader MG born ~T60.**

*Passive play* (never socialized, never vacationed, never seeded, kept near home): turns 1-14 mood ~0, decay 1/turn, SG 86. From turn 15 No-Socializing stacks at -20/turn, from turn 25 No-Vacation joins, from turn 20 Restlessness. Mood crosses -100 (Grumpy, decay 2) ~turn 20, -200 (Upset, 3) ~turn 24, -400 (Depressed, 5) ~turn 30, and the -500 floor (Despair, 6/turn, -100% CS, -5 Loyalty) ~turn 33. Cumulative loss ~19 + 10 + 18 + 20 = 67 by turn 33, SG ~33; 6/turn brings her Critical (<= 9) around **turn 37** and to 0 around **turn 39**. Loyalty at -5/turn from turn 33 would hit zero at turn 53, so she witches out first. **Expected life ~36-40 turns.**

*Active Witch hunting*: she socialises every ~14 turns (mood floor removed, up to +300), vacations every 25, and the empire kills roughly one Witch per 8-10 turns somewhere. At Happy/Elated mood the corruption term is `max(1 - 2, 1) = 1`. One Grief Seed per 40 turns covers passive decay exactly. The binding constraint becomes combat damage: each Witch she personally melees costs 40-70 HP, so 40-70 SG, 1-2 seeds. **She survives indefinitely if the empire's Witch-kill rate exceeds ~0.025/turn per MG and she is not the one taking the hits.** Put a Warrior on Witch duty and she lives forever; send her in and she nets about -1 seed per fight.

## 4. Witches

Vanilla barbarian spawns are converted on creation (`PMMMWitches.lua:33-107`): a unit spawning in an un-farmed camp becomes a Witch, on water a Sea Familiar, otherwise a 5% chance of an Incubator and otherwise a Familiar. Familiars mature into Witches after `floor(25 x TrainPercent/100)` turns (25 Standard, 75 Marathon, 16 Quick) or instantly if they pillage an improvement (`PMMMWitches.lua:686-706`). MG-born Witches spawn at `floor(eraWitchStrength x 1.2)` (`PMMMMagicalGirls.lua:958`), 160% of the era's best melee.

Killing a Witch gives: 1 Grief Seed, +5 XP (bypassing the barbarian XP cap), +100 Mood to a killing MG (cap +500, 20-turn decay), and 50 gold if you own Mausoleum of Halicarnassus (`Buildings.GoldFromKillingWitches = 50`). Clearing the Labyrinth (renamed barbarian camp, same `IMPROVEMENT_BARBARIAN_CAMP`) gives +15 XP (x2 for Askia) and **-1 gold**, an attempt to cancel the vanilla camp gold that only removes one coin (`PMMMWitches.lua:311-325`).

Hidden Witch Labyrinths begin in the Renaissance (or immediately with No Barbarians) once fewer than `0.1% x plots` visible camps remain. Then, every 10 turns, each city rolls 25% (city-states 5%) for an invisible barrier within its workable radius; the afflicted city loses **10% of its growth threshold in food every turn** and can starve citizens (`PMMMWitches.lua:381-415`). Allowance is `1 + floor(cities/5)`. Digging one out costs an MG a turn per attempt with only a 1-tile find radius and a 2-tile "warm" radius.

**Net:** Witches are a **farm for anyone with a normal army** (free Grief Seeds and XP from units that were going to be barbarians anyway) and a **threat to Magical Girls specifically**, who fight them at a 0.53 strength ratio. Non-MG civs are not disadvantaged, because there are none: every civ has MGs. The genuine asymmetry is that the mod raises `BARBARIAN_TECH_PERCENT` to 90 and `MAX_BARBARIANS_FROM_CAMP_NEARBY` to 3 (`wftw/WFTWGameDefines.xml:7-13`) and makes camp units 33% stronger than the era's best melee: a flat difficulty increase that punishes wide, peaceful, low-military empires and rewards early-aggression UAs.

## 5. Net value

Assumptions: Standard speed, Standard map, single-player, King difficulty, a player who reads notifications but does not optimise, and a baseline of "the same game with the MG system deleted".

- **Ancient-Classical (T1-100):** one free, maintenance-free, uncapturable, ungiftable 7 to 9 CS unit at +40% modifiers, which respawns at the capital 10 turns after any death. Call it a free Warrior plus permanent insurance. **~25-35% of Babylon's UA**, well under Poland's.
- **Medieval-Renaissance (T100-160):** 2-4 MGs. Each is a free but sub-par melee unit plus an upkeep obligation. Hidden Barriers start and tax growth. **~20-30% of a top UA, with a fat negative tail**: a single witch-out next to two other MGs can convert three assets into one 160%-strength enemy and two doomed girls.
- **Industrial onward:** MG strength (23 to 49) falls behind line units (34 to 70) while HWB pressure scales with city count. For a wide empire the system is **net negative** unless actively hunted.
- **Whole game, expectation: ~20-30% of a strong vanilla UA for a good player; ~0 to negative for a casual one.** Variance is the dominant term: the standard deviation of the outcome is comparable to the mean.
- **Contribution to MG-civ vs vanilla-civ balance: ~0**, because vanilla civs get the identical package.

Cost in micromanagement: per MG, roughly one deliberate click every 3-5 turns (Socialize ~every 14, Vacation ~every 25, Write/Phone Home ~every 20, Grief Seed on demand, Dull Pain when injured) plus a Soul-Gem-Critical notification per girl per turn while Critical (`PMMMMagicalGirls.lua:1442-1458`). At 5 MGs that is ~1.5 mandatory clicks and ~3 notifications per turn, forever.

## 6. Ten things a new player is not told

1. **The witch-out formula** `10 + (9 - SG) x 5` percent per turn. The only text is "Has a chance to become a Witch each turn." (`wftw/XML/Text/MagicalGirlsAndWitches.xml`, `TXT_KEY_PROMOTION_PMMM_SGSTATE_CRITICAL_HELP`; `wftw/Lua/UI/MagicalGirlInfoPanel.lua`).
2. **Next turn's corruption is never previewed.** The panel shows a Soul Gem percentage but not the per-turn delta or its components (`MagicalGirlInfoPanel.lua`).
3. **Corruption can never fall below 1%/turn** regardless of Mood (`PMMMMagicalGirls.lua:824`), contradicting the implication of the Mood concept text (`Concepts-english.xml`).
4. **"The Truth" is a death sentence and has no concept entry at all.** -1500 Mood pins her at the -500 floor = Despair permanently. It is caught from any witch-out within 2 tiles, including other civs' girls (`Concepts-english.xml`).
5. **Grief Seed potency varies by game speed** (26/40/60/100) and by the No Barbarians option (x1.5). Nothing says so before use (`Concepts-english.xml`, `MagicalGirlsAndWitches.xml`).
6. **Healing 100 HP costs 100% Soul Gem = 2.5 Grief Seeds.** The rate is stated; the total bill of a single Witch fight is not (`Concepts-english.xml`).
7. **Home City is assigned silently** to the nearest city at birth, and if it is razed or lost the Homesick penalty jumps to its -1000 maximum permanently (`PMMMCoreMoods.lua:1286-1289`; `MagicalGirlInfoPanel.lua`).
8. **Adapted Hostile Terrain** is rolled from the home city's ring-1 tiles at birth; standing on a *different* hostile terrain doubles the penalty to -300 (`PMMMMagicalGirls.lua:275-295`, `PMMMCoreMoods.lua:1233-1243`). Nowhere visible (`MagicalGirlInfoPanel.lua`).
9. **The unit help text is false.** It promises "a bonus ability depending on which type of Great Person was expended" and "may form Relationships with other Magical Girls"; `Trait_PMMM_MagicalGirlExtraAbility` and `MG_RelationshipLevels` are both empty (`MagicalGirlsAndWitches.xml`, `MGRelationships.sql`).
10. **Witches are 133% of era-best melee (160% if MG-born) while MGs are 70%.** Nothing warns the player that the signature unit loses to the signature enemy (`Concepts-english.xml`, `MagicalGirlsAndWitches.xml`).

Runners-up: the Loyalty/defection Influence economy is only in a bar tooltip; other players can Socialize with your MGs to build that Influence; and the Vacation destination is rolled, not chosen.

## 7. Tuning levers

Toward "less babysitting, less RNG, clearer value, MG civs on par with top-tier vanilla".

**Pure DB (`wftw/WFTWGameDefines.xml`, `wftw/SQL/Shared/MGMoods.sql`, `MGStates.sql`):**

| Constant | Now | Direction |
|---|---|---|
| `MAGICAL_GIRL_STRENGTH_PERCENT` | 70 | **to 85-90.** The single highest-leverage number; 70% makes the mod's signature unit structurally obsolete. |
| `WITCH_STRENGTH_PERCENT` | 133 | to 110. Keeps Witches dangerous without making MG-vs-Witch a losing trade. |
| `SOUL_GEM_LOSS_PER_HP_REGENERATED` | 1 | **to 0, or make it a mood-scaled fraction.** This is where the babysitting comes from. |
| `SOUL_GEM_LOSS_PER_TURN` | 1 | keep, but remove the hard floor of 1 in Lua so good Mood can zero it out |
| `BASE_GRIEF_SEED_RECOVER_AMOUNT` | 40 | to 50, and decouple from `BarbPercent` (Marathon currently gets 100%) |
| `MG_MOOD_MINIMUM` / `MAXIMUM` | +/-500 | keep |
| `MGMOODMOD_KNOWS_THE_TRUTH.Value` | 750 (-1500 effective) | **to 200-300.** Currently an instant-kill with no counterplay. |
| `MGMOODMOD_HOMESICK` | 20/turn, cap 1000, start 20 | to cap 300, start 40 |
| `MGMOODMOD_NO_SOCIALIZING` / `NO_VACATION` | 20/turn, cap 500, start 15/25 | to cap 200, start 30/50; these three caps sum to -2000 against a +500 floor, which is why unmanaged girls die on schedule |
| `MGMOODMOD_RESTLESSNESS` | 15/turn, cap 375, start 20 | remove or cap 150 |
| `MG_Moods.SoulGemCorruptionMod` | -5 to +5 | compress to -2 to +2 to reduce the death-spiral slope |
| `HIDDEN_WITCH_SPAWN_CHANCE_PERCENT_PER_CITY` | 25 | to 12-15 |
| `HIDDEN_WITCH_GROWTH_PROGRESS_REMOVED_PER_TURN` | 10 | to 5 |
| `HIDDEN_WITCH_FINDABLE_RADIUS` | 1 | **to 2.** Halves the number of Witch Hunt attempts, the biggest RNG-and-clicks sink. |
| `LEADER_MG_RESPAWN_TURNS` | 10 | keep |
| `MG_SPARRING_COOLDOWN` / `XP_GAINED_FROM_SPARRING` | 10 / 10 | 10 XP for 3 turns off-map is not worth taking; to 25 XP |
| `MG_SoulGemStates` bands | 90/70/30/10 | widen Critical to 0-19 but lower the base witch chance; currently the 0-9 band gives ~3 turns of warning |
| `AI_MG_LOYALTY_BONUS_PER_TURN` | 1 x handicap | AI gets +7/turn on Immortal and never loses a girl to defection; to flat 1 |
| `MAX_BARBARIANS_FROM_CAMP_NEARBY`, `BARBARIAN_TECH_PERCENT` | 3, 90 | revert to 2, 100 if the Witch strength stays at 133 |

**DB, structural:** populate `MG_RelationshipLevels` (uncomment `MGRelationships.sql`) or delete the promises from `MagicalGirlsAndWitches.xml`; same for `MG_PersonalityTraits` and `Trait_PMMM_MagicalGirlExtraAbility`. Give the ten MG civs distinct values in the existing trait columns (`SoulGemCorruptionModifier`, `MGMoodBonus`, `LeaderMGUniquePromotion`, `LeaderMGUniqueMission`, `WitchBarrierXPMultiplier`, `StealGriefSeedOnCityCapture`, `TruthMoodModifier`): these are the only knobs that can actually separate MG civs from Babylon.

**Lua:**
- Remove `max(..., 1)` at `PMMMMagicalGirls.lua:824` so positive Mood can genuinely stop decay.
- Auto-consume Grief Seeds for humans below a player-set threshold (mirror the AI branch at `PMMMMagicalGirls.lua:849-854`): the single biggest click reduction.
- Fix the dead computation at `PMMMCoreMoods.lua:1653`, which is immediately overwritten by lines 1656-1660.
- Let the player choose the Vacation destination instead of `DeckShuffle` (`PMMMLeaveMapFunctions.lua:84`).
- Make `MagicalGirlOnGreatPersonUse` actually gate `MadokaInitMagicalGirl`, so the system can be made MG-civ-exclusive if that is the design intent.
- Surface the witch-out percentage, the per-turn corruption breakdown, Home City and Adapted Terrain in `MagicalGirlInfoPanel.lua`.

**Would need DLL work:** a real per-unit resource bar for Soul Gem (currently faked with five mutually-exclusive promotions re-applied every turn); making `SetBaseCombatStrength` era-scaling a data-driven unit property; a `GameEvents.BarbarianCampCleared` hook (the mod polls plots instead, `PMMMWitches.lua:147-160`); making the MG table part of synced game state instead of `Modding.OpenSaveData()`.

CP 5.4.6 already offers data-driven replacements the mod does not use: `UnitPromotions_YieldFromKills` / `YieldFromBarbarianKills` could replace the Halicarnassus Witch-gold Lua and give Witch kills real yields; `UnitPromotions.PromotionDuration` could replace the hand-rolled `DullPainTurns` counter; `UnitPromotions_Plagues`, `NearbyEnemyDamage` and `TileDamageIfNotMoved` could replace Demon Homura's `MagicalGirlAttrition` Lua; `UnitPromotions_BlockedPromotions` could enforce the skill-tree shape declaratively.

## 8. Multiplayer

- **Persistence is client-local.** `TableSave` writes through `Modding.OpenSaveData()` (`wftw/Lua/Utils/TableSaverLoader016.lua:118`) and is triggered from a UI input handler and `Events.AIProcessingEndedForPlayer` (`wftw/Lua/Utils/TSLSerializerV3PMMM.lua:191-211`). The entire MG table lives in `MapModData`, outside synced game state. Each client must re-derive it identically from `GameEvents`; there is no reconciliation.
- **Order-dependent randomness.** `DeckShuffle` builds its deck by `pairs()` order and then indexes it with `Game.Rand` (`wftw/Lua/PMMMGeneralFunctions.lua:460-473`): the RNG is synced but the deck ordering is not guaranteed to be, so vacation destinations, defection targets and Demon Homura's promotion theft can diverge. `DoActionStateTurnUpkeep` also re-creates units while iterating `pairs(MagicalGirls)` (`PMMMMagicalGirls.lua:1221-1238`), and unit IDs are assigned in creation order.
- **Witch bombing is unanswerable griefing.** Walking a despairing MG into a rival's territory and letting her witch out gives every MG of theirs within 2 tiles the permanent -1500 Truth penalty (`PMMMMagicalGirls.lua:965-994`). The only cost is a 50-point AI diplo modifier, which is worthless against a human.
- **Opponents can manipulate your girls.** Socialize targets "any Civ you are not at war with" (`PMMMCoreMoods.lua:184-199`), and each Socialization plus every point of cultural influence builds that civ's Influence over her; at 10 Influence per Loyalty point she eventually defects to them. Vacation can also send her into their empire and cost 25 Loyalty.
- **Simultaneous turns.** MGs are off the map for 1-5 turns during Witch Hunt, Vacation, Spar and Write Home; on return, if the plot is occupied she is teleported by `JumpToNearestValidPlot` (`PMMMMagicalGirls.lua:1228-1235`). Defection and witch-out both change unit ownership mid-turn while opponents are moving.
- **Asymmetric clock pressure.** The AI auto-spends Grief Seeds; humans must click. Under a turn timer, a player with six MGs pays six clicks and reads six notifications while a player with one pays one: a pure skill-irrelevant handicap for the more successful player.
- The mod is clearly aware of the problem (`MISSION_PMMM_APPEARANCE_UPDATE`, `MISSION_PMMM_PLEIADES_FREEZER` and `MISSION_PMMM_GRIEF_SEED` are invisible dummy missions added solely to push state between clients, `wftw/SQL/Shared/MGMissions.sql:88-108`), but that pattern covers icons and seed use, not the mood, loyalty and influence tables.
