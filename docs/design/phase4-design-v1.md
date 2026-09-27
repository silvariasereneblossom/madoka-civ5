# Phase 4 design v1: the maintainer's kit pass, annotated

Date: 2026-09-17. Source: the maintainer's design message (recorded here nearly verbatim under **Spec**), followed by
implementation notes and concerns from the port side. Supersedes the per-civ proposals in
[mechanics-scope.md](mechanics-scope.md) sections 5 wherever they differ. Decisions already taken: the Magical Girl
system is exclusive to the MG civs; Witch kills by outsiders deny the Grief Seed.

Tags: **[DB]** data rows only, verified against the CP 5.4.6 schema; **[Lua]** existing-script work on synced
GameEvents or custom missions; **[DLL]** needs the bundled custom build; **[check]** API or column not yet verified.

---

## 0. Cross-cutting

### 0.1 Magical Girl strength

**Spec.** Magical Girls automatically match the most advanced frontline unit in strength. Balanced by not being spammable.

**Implementation.** `MAGICAL_GIRL_STRENGTH_PERCENT` 70 to 100 [DB]; make the era table monotonic (Atomic currently
dips 49 to 45 because Mobile SAM is the "best melee") [Lua, `PMMMDataStorage.lua:316-342`].

**Concerns.** At 100% base the existing multipliers stack too high: Mood gives up to +100% combat, Soul Gem state
up to +20%, leader +20%, so a happy leader girl would be 2.4x a line unit. Recommend compressing Mood combat to
+/-30% and Soul Gem state to +10/-20% at the same time, and Witches from 133% to 120% so the signature fight stays
tense. "Cannot be spammed" holds only while girls come from Great People and the leader slot; keep it that way (no
faith purchase, no building that produces more than one).

### 0.2 Unique Magical Girl abilities (UMG)

Every civ now gives its leader girl an active ability. Build one framework, then each ability is a short handler:

- **Trigger:** a custom mission on the leader girl (`Missions` row with the mod's `PMMMMissionRange` /
  `PMMMTargetType`, gated by `LeaderMGUniqueMission`, which the bootstrapper already caches). Custom missions travel
  through the game core, so they are multiplayer-safe; Tiro Finale and Summon Witch already work this way. [Lua]
- **Cooldown:** per girl in the persisted `MagicalGirls[key]` table, decremented in `MagicalGirlUpkeep`; the unit panel
  shows "ready in N". [Lua]
- **Damage:** never as raw "combat strength" numbers. A girl's strength runs from 8 to 100 over a game, so "half her
  strength as damage" is 4 HP in the Ancient era and 50 HP in the Information era. Express every ability as a
  **virtual attack at k x her strength** and let the engine's formula produce the HP number via
  `Unit:GetCombatDamage(iStrength, iOpponentStrength, iCurrentDamage, bIncludeRand, bAttackerIsCity, bDefenderIsCity)`
  (bound in CP's `CvLuaUnit`). k = 0.5 is a glancing hit, 1.5 a strong hit, 4 a kill.
- **Temporary effects:** promotions with the CP columns `DamageTakenMod`, `DefenseMod`, `ExtraAttacks`,
  `CanMoveAfterAttacking`, applied by the handler and cleared on the owner's next `PlayerDoTurn` (the Tiro debuff
  pattern). [DB + Lua]
- **AI:** each ability needs one rule ("if off cooldown and a valid target is in range, fire"), otherwise AI MG civs
  fall behind humans. Budget it per ability.
- **Text:** each mission needs help text and a Civilopedia line.

### 0.3 Leader girls for everyone

Ultimate Madoka and Demon Homura currently get no leader girl (hard-coded). Both now have a UMG, so the hard-code goes
and the Knight decision becomes redundant.

---

## 1. Madoka Kaname (Mitakihara)

**Spec.** Middle School replaces the National College: +40% Science (not 50), +2 Faith, +20% Faith, free Magical Girl
on completion. UMG **Pluvia Magica**: hits all units adjacent to a target enemy for half her strength; hit units take
15% extra damage for the rest of the turn; costs 20% Soul Gem; 4-turn cooldown.

**Implementation.** National College override via `Civilization_BuildingClassOverrides` with `Building_YieldModifiers`
Science 40 and Faith 20, `Building_YieldChanges` Faith 2 [DB]. Free girl on `GameEvents.CityConstructed` (CP event,
verified) through the existing spawn path [Lua]. Pluvia Magica: virtual attack at 0.5 on each adjacent unit, then a
one-turn promotion with `DamageTakenMod 15` [Lua + DB].

**Notes.** A -10% Science national wonder paid back with faith and a free line-strength unit around turn 60 is a fair
trade and gives her an early game. It also resolves the "two Middle Schools at Scientific Theory" collision. Open
point: does the primary target take the hit too, or only its neighbours? Suggest target at 1.0 plus neighbours at 0.5.

---

## 2. Ultimate Madoka (Realm of Cycles)

**Spec.** Capital renamed Realm of Cycles; city list gains every named Witch except Homulilly. Girls return from the
Law of Cycles with 100 XP per applied (non-inherent) promotion, can earn no further XP, and can **Summon Witch Form**
for +20% strength. Led-away enemy girls return after 5 turns (Standard) and get a bonus promotion. Lead Away cannot
target leader girls. Luminous Garden also replaces the Grand Temple: +8 Happiness, +1% Soul Gem recovery for all her
girls, a permanent +10 Mood, +25% Great Person generation, triple Faith pressure from the Holy City. UMG **Nothing To
Despair, Ever**: she can never lose Mood or Soul Gem or become a Witch; single-target attack at 4x strength; girls
within 2 tiles recover 5% Soul Gem; 5-turn cooldown.

**Implementation.** City names [DB text]. Return XP: count `MagicalGirls[key].Promotions` minus free promotions, then
`SetExperience` [Lua]. "No further XP": a permanent promotion with `ExperiencePercent -100` (vanilla column) is
clean and needs no per-turn policing [DB]. Witch Form: toggle mission adding a +20% promotion [Lua + DB]. Grand Temple
override: `Building_YieldModifiers`/`Happiness 8`, `ReligiousPressureModifier 200` (Grand Temple is 100 = double;
200 = triple), `GreatPeopleRateModifier 25` [DB]; the global +1% Soul Gem and +10 Mood are two lines in the mood and
upkeep code keyed on owning the building [Lua]. The leader girl's immunities are flags in upkeep; the attack is a
virtual attack at 4.0 [Lua].

**Notes.** 100 XP per promotion is generous (five promotions cost about 350 XP to earn and return as 500); fine as
the "hope" fantasy, but cap it at 600 so a ten-promotion veteran does not come back at level 12. A 4x attack every five
turns kills anything in the game; 3x still kills contemporaries and leaves siege and unique units a sliver. Suggest 3x
and no city targets. The fragment "Great People." in the spec was cut off; please complete it. Yuri Valhalla's Garden
happiness is superseded by the new building.

---

## 3. Homura Akemi (Neo-Mitakihara)

**Spec.** Time Stop reworked: 20-turn cooldown, reduced by 1 per Grief Seed used; on use every unit gains an extra
attack and every city, build and improvement receives one turn's worth of yields (a free turn). Thief of Time replaces
the Scout: 3 moves, Warrior strength, may enter rival territory; while there, every 3 turns gains progress toward a
random unowned technology. UMG **Concentrated Missile Fire**: one attack mechanically equivalent to Rocket Artillery,
city bonus included. Dimensional Armory replaces the Armory and adds +1 Production.

**Implementation.** Free turn: per city add its per-turn Food, Production, Gold, Science, Culture and Faith; per
worked build call `Plot:ChangeBuildProgress` (bound in CP) for one turn of work rate; give every unit a one-turn
promotion with `ExtraAttacks 1` [Lua + DB]. Cooldown reduction hooks the Grief Seed consumer [Lua]. Thief of Time:
Scout override with `Combat 8`, `Moves 3`, free `RivalTerritory` promotion [DB]; tech progress on `PlayerDoTurn`
counting consecutive turns in foreign territory [Lua]. Missile Fire: virtual attack using Rocket Artillery's 60
ranged strength doubled against cities [Lua]. Armory override [DB].

**Notes.** Two things to decide. (1) **The trigger.** Missions belong to units; a Time Stop button on the leader
girl is thematically right (it is her power) and multiplayer-safe, but dies with her for 3 turns. The alternative is
a zero-cost, repeatable national "Invoke Time Stop" building: `CityConstructed` fires the effect and removes the
building, and the cooldown gates re-adding it. That is unit-independent and the AI will use it on its own. (2)
**Scaling.** A fixed Rocket Artillery hit is a one-shot on anything before the Industrial era; suggest "the strongest
siege unit the player can currently build, 60 at Rocket Artillery" or a virtual attack at 2.0 with the siege city
bonus. Also define "a turn's worth of yields" narrowly: city yields and worker builds, not Great Person points, tourism
or healing, or the free turn becomes hard to reason about. The tech progress amount is unspecified; suggest 10% of the
cheapest available tech per trigger.

---

## 4. Devil Homura (Meikyuu no Homura)

Explicitly provisional pending Walpurgisnacht Rising.

**Spec.** Civ renamed Meikyuu no Homura. UA **Ai Yo**: every unhappiness penalty removed (revolts, yield loss, growth
loss and the rest); yields and combat strength +1% per 5 unhappiness up to +25%; base Prodigy rate halved. Unique
leader girl with **Falsified Phenomena**: 150% strength AOE around the target; she is always in Despair, takes no
Despair penalties and can never become a Witch. UU Clara Doll replaces the Swordsman: 16 strength, 2 moves, gains
Magical Girl promotions from XP. UB Half-Moon Garden replaces the Garden: +10% Prodigy rate, +5% to all yields in the
city. Incubator Slave removed.

Ai Yo has five clauses after the rulings: no unhappiness penalties; yields and combat scaling with unhappiness from cities and population; halved Prodigy rate; never a Golden Age and immune to ideology pressure; gold from Witch kills and Labyrinth clears. The tooltip must carry all five.

**Implementation.** Removing unhappiness penalties is DLL-side logic keyed on excess happiness; there is no trait
column for it in CP. Two routes: (a) [DLL] two trait columns, `IgnoreUnhappinessPenalties` and
`YieldPercentPerUnhappiness`, checked where the penalties and the yield modifiers are computed (small, contained);
(b) [Lua] a dummy building that adds Happiness equal to the deficit each turn plus a bit-packed yield-modifier dummy,
which is exactly the hidden construction the audits argued against. Recommend (a); this is what bundling the DLL is
for. Prodigy rate: `GreatPeopleRateModifier -50` [DB]. Clara Doll: Swordsman override with `Combat 16`; the Magical
Girl promotion tree is gated by `UnitPromotions_UnitCombats`, so either give her `UNITCOMBAT_MAGICALGIRL` (simplest,
but anti-MG modifiers then apply to her) or add MELEE rows for the MG promotions and hide them from other melee units
with `GameEvents.UnitCanHavePromotion` (CP event, verified) [DB + Lua]. Half-Moon Garden: `Building_YieldModifiers`
5 on each yield, `GreatPeopleRateModifier 10` [DB]. Falsified Phenomena: virtual attack at 1.5 on target and ring [Lua].

**Notes.** This is the one ability in the pass I would push back on as written. Happiness is the only brake on width
in Civ V; with every penalty gone and a bonus for being unhappy, the optimal line is to settle and conquer without
limit, and the +25% cap bounds the bonus but not the width. The halved Prodigy rate does not offset that. Options that
keep the fantasy: keep the revolt and the very-unhappy combat penalty below -40 excess; or remove the penalties but
make each unhappy point cost 1% Great Person rate on top of the halving; or cap the immunity at the number of cities
(each city absorbs 5 unhappiness). Worth a sentence of intent before it is built.

---

## 5. Sayaka Miki (The Oktavians)

**Spec.** UA renamed **Kyoshikyoku no Seigi** (Rhapsody of Justice): double Tourism from Wonders; the Palace gains 2
Great Work of Music slots with "Decretum" in the first; Cutlass Conductor now replaces the Swordsman and yields Culture
and Faith equal to a quarter of the killed unit's strength; Stage of Oktavia kept; 10% of Tourism becomes Musician
Prodigy points and 5% each Artist and Writer points. UMG **Baldamente Fortissimo**: friendly units within 2 tiles heal
25% and take half damage while defending for 2 turns; 6-turn cooldown.

**Implementation.** Wonder tourism: no trait column; a hidden policy with `Policy_BuildingClassTourismModifiers` 100
for every wonder class, granted at game start (the Mami language decisions already use hidden policies) [DB + Lua].
Palace slots: a building holds one slot type and the Palace's is Art, so add a free capital-only building with two Music
slots (`Civilization_FreeBuildingClasses`) [DB]; the pre-filled work via `Game.CreateGreatWork` (bound in CP) plus a
`GreatWorks` row for Decretum [Lua + DB; the audio for a Great Work of Music would come from the soundtrack pack,
check]. Conductor: Swordsman override, `UnitPromotions_YieldFromKills` Culture 25 and Faith 25 (percent of the
victim's strength) [DB]. Tourism conversion: per turn `ChangeSpecialistGreatPersonProgressTimes100` in the capital
[Lua]. Fortissimo: heal via `ChangeDamage(-25)` and a two-turn promotion with `DamageTakenMod -50` [Lua + DB].

**Notes.** Coherent and visible; the tourism-to-Prodigy conversion is the one piece that needs a number check late
(300 tourism = 30 Musician points a turn, more than a Guild), so cap it at, say, 20 per yield per turn.

---

## 6. Kyouko Sakura (Kazamino)

**Spec.** UA renamed **I Live Only For Myself**: +2 Happiness from owned luxuries, -1 from traded luxuries; Shrines +1
Food, Sakura Church +2 Food; unhappiness from population -25%; free pantheon at once without faith but can never found a
religion; Stolen Food becomes a Chain Lancer unique and the Lancer loses the mounted terrain penalties. UMG
**Kugatachi**: 200% strength in a 2-tile line behind the target.

**Implementation.** Luxuries: `ExtraHappinessPerLuxury` exists on Policies, not Traits, so a hidden policy at 2 [DB +
Lua]; the -1 on imported luxuries is a per-turn count of resources available but not owned, applied through a dummy
[Lua]. Shrine food via `Trait_BuildingClassYieldChanges` [DB]; Church row +2 Food [DB]; `PopulationUnhappinessModifier
-25` is a real CP trait column [DB]; `StartsWithPantheon` is a real CP trait column [DB]. "Cannot found a religion":
no column; block Great Prophet founding in Lua (`PlayerCanFoundReligion`-type hook, [check]) or set prophet rate to
zero [check]. Chain Lancer: move the Stolen Food handler to the unit and drop `PROMOTION_NO_DEFENSIVE_BONUSES` [Lua +
DB]. Kugatachi: virtual attack at 2.0 on the target and the next tiles along the same hex direction [Lua].

**Notes.** Turn-1 value at last, and the happiness package suits a wide, greedy Kyouko. Clarify whether "traded" means
imported only or also exported, and how many tiles "a 2-tile line behind the target" is (target plus two, or two
beyond).

---

## 7. Mami Tomoe (Nazione di Tiro)

**Spec.** Keep the yields from city-state allies. Add: each unique traded strategic resource +1 Production in the
capital; traded luxuries +1 Happiness. Teahouse gives +2 Gold and +10% Gold to civilizations you have a Declaration of
Friendship with, or city-states you have pledged to protect. Tiro Musketeer gets **Tiro Siege**: a free attack usable
only on cities, roughly a Cannon. UMG **Tiro Finale**: 150% strength to the target, half to enemies within one tile,
her defence -50% next turn.

**Implementation.** `Trait_YieldFromCSAlly` / `Trait_YieldFromCSFriend` [DB]; imported resources counted per turn
into a capital dummy [Lua]. Teahouse: as written the gold goes to the friends, which is the subsidise-your-rivals
pattern the audit flagged; if the intent is that Mami earns +2 Gold and +10% Gold per such partner, that is
`Building_YieldChanges` plus a per-partner modifier [Lua + DB]. Tiro Siege: a mission that does not spend the attack,
virtual attack with Cannon's 14 strength doubled against cities, city targets only [Lua]. Tiro Finale: existing code
with the new multipliers and `DefenseMod -50` for one turn [Lua + DB].

**Notes.** Please confirm the Teahouse direction. A free Cannon-class city hit every turn from every Musketeer is a
strong Renaissance siege package; consider once per 2 turns or -33% of a Cannon.

**Added 2026-09-17.** Cities past the fourth add extra unhappiness (DLL trait columns for threshold and
penalty). Her yields concentrate in the capital, and the cap is what keeps that concentration honest; raise the
per-ally yields if the cap proves too harsh in play. The Teahouse gold also multiplies per city, so the cap pushes
that bonus toward the capital as well. Watch the two together.

---

## 8. Nagisa Momoe (Land des Kaeses)

**Spec.** Civ renamed Land des Kaeses, people "Bebe's Cheese Commonwealth". Cheese!: Farms +1 Production, Pastures +1
Food. Magical Dairy replaces the Granary: +1 Food, Gold, Faith and Production for every Cattle and Sheep worked by the
city. Bubble Bomber takes half damage on bombing runs and deals 25% damage to enemy units and cities around the target.

**Implementation.** `Trait_ImprovementYieldChanges` [DB]. Dairy: `Building_ResourceYieldChanges` (the Granary's own
mechanism), eight rows, shows on the tile [DB]. Bomber: `InterceptionDefenseDamageModifier -50` and `SplashDamage`
(both real promotion columns) [DB].

**Notes.** Cleanest kit in the pass and entirely data-driven. +1 Production on every Farm is the strongest single line
here (a 6-city empire works 20+ farms by turn 100); if it plays too hot, "Farms adjacent to a Pasture" keeps the
cheese theme and roughly halves it.

---

## 9. Kazumi (Pleiades Saints), open for proposals

**Given.** The Freezer cannot take leader girls. UMG **Rule Break**: 10-turn cooldown, instant promotion for any
Magical Girl.

**Proposal.** UA **Pleiades Saints**: Great Works of Writing +1 Culture +1 Gold and each Great Work created grants 5
turns of We Love the King Day in its city [DB, CP trait columns]; the Freezer stays as the late spike but becomes
deterministic: a stored girl revives as yours after `15 - 2 x Academies` turns (minimum 5) with her promotions, and a
Grief Seed shortens it by 3; no Witch from a voluntary action, no hidden score [Lua]. UU Artificial Incubator kept,
Scout ban removed, cap 4, Polish 5% per use [DB]. UB Angelica Bears fixed to 4 Entertainment, +2 Culture, +1 Tourism,
Teddy Bear luxury as a monopoly [DB]. Rule Break: `Unit:SetPromotionReady(true)` (bound in CP) on a friendly girl
within 2 tiles [Lua].

---

## 10. Oriko Mikuni and Kirika Kure (Shiromeian Empire)

**Spec.** The intrigue mechanic becomes double spying rate; all units start with Visibility.

**Implementation.** Spy rate: CP trait columns `SpyExtraRankBonus`, `SpyMoveRateModifier` and
`SpyOffensiveStrengthModifier` exist; an extra rank is the closest to "double rate" in CP 5.4's espionage (rank
multiplies steal speed) [DB]. Visibility: `Trait_FreePromotions` with `PROMOTION_SENTRY` (+1 sight) [DB]. Keep the
start-location reveal and the extra leader girl.

---

## 11. Maintainer rulings (2026-09-17, round 2)

| # | Topic | Ruling |
|---|---|---|
| 1 | Girl strength and multipliers | 100% of the frontline unit, existing Mood and Soul Gem multipliers **kept as they are**. Girls are meant to be overpowered individually; mass is the counter. Revisit only after playtesting. |
| 2 | Ability damage | Virtual attacks via `GetCombatDamage`. The strength numbers in the spec were reference points, not HP values. |
| 3 | AI and text | Every UMG ships with an AI rule and tooltip text. Part of the definition of done. |
| 4 | Devil Homura, Ai Yo | **Kept as specified.** Intent: a steamroll-early-or-fall-behind civ. Civ V favours tall play; going wide without the economy still costs heavily, the halved Prodigy rate compounds that, and her power depends on running up unhappiness through settlement and conquest, which opponents can block. Implementation route (a), DLL trait columns. |
| 4b | Devil Homura, counterplay | Reaffirmed: the counter is stopping the snowball before it starts. Late game she faces empires with stronger science and economic tools; her only economic engine is the Half-Moon Garden, and her percentage bonuses multiply a small base. Playtest in a Lekmod-style lobby before tuning. |
| 4c | Devil Homura, Ai Yo measure | **Ruled:** the bonus scales on total unhappiness from cities and population, not the net deficit. |
| 4d | Devil Homura, DLL and AI | **Ruled:** the engine treats her as never unhappy, so AI planning sees it. AI is very aggressive: a civ bordering her should face a high chance of a declaration of war. Leader personality (Boldness, war approach bias, low friendship willingness) plus a DLL-side bias toward declaring on neighbours. |
| 4e | Devil Homura, Golden Ages | **Ruled, hardened:** she can never have a Golden Age from any source, including Great Artists, wonders, policies and surplus happiness. DLL trait column; tooltip states it. |
| 4f | Devil Homura, ideology | **Ruled:** immune to ideology pressure, so no public-opinion unhappiness and no forced revolutions. DLL trait column (CP 5.4 has no data column for this). |
| 5a | Mami, city-state yields | **Ruled:** +1 Production per city-state ally, +1 Science per Friend. Both are multiplied by count and by era index in the DLL (`CvCity.cpp:29229`) and land in the capital only. At Industrial with 3 allies and 6 friends that is +12 Production and +24 Science. |
| 5b | Mami, city soft cap | **Ruled:** every city past the fourth carries +4 unhappiness *for each city over the limit*, so the penalty squares: 5 cities +4, 6 cities +16 (two cities at +8), 7 cities +36 (three at +12). Total is `4 x (cities - 4)^2`. DLL trait columns for the threshold and the per-city step keep both numbers as data. Open: whether puppets count toward the city total. |
| 5 | Time Stop | **Mission on Homura's leader girl.** The free turn **includes** Great Person points, tourism and healing, not only city yields and builds. |
| 6 | Mami, Teahouse | Mami earns +2 Gold and +10% Gold per Declaration of Friendship partner or protected city-state. |
| 7 | Nagisa, Farms | **Kept at +1 Production on every Farm.** She was the weakest civ and her UU arrives very late, so the strong early line is deliberate. |
| 8 | Ultimate Madoka, return XP | **100 XP per applied promotion, uncapped.** Promoting a girl is a real investment and this is its payoff. |
| 9 | Ultimate Madoka, "Great People." | Expending a Great Person grants Golden Age points. |
| 10 | Nothing To Despair, Ever | **4x strength kept**, cannot target cities, **damage halved against Magical Girls**. Five-turn single kill judged acceptable. |

## 12. Still open, with working defaults

Implementation proceeds on these defaults unless the maintainer overrides them.

| Topic | Working default |
|---|---|
| Madoka, Pluvia Magica | Primary target takes the same 0.5 hit and the 15% vulnerability; neighbours as specified. |
| Homura, Thief of Time | Each trigger grants 10% of the cost of a random unowned, currently researchable tech. |
| Homura, Missile Fire scaling | Virtual attack at Rocket Artillery's ratio to the era's best land unit, siege bonus against cities included. |
| Homura, Time Stop Grief Seed reduction | -1 turn per seed, floor 5 turns. |
| Kyouko, traded luxuries | "Traded" means imported through deals only; exported luxuries are unaffected. |
| Kyouko, Kugatachi | Target plus the two tiles beyond it along the attack direction, 2.0 each. |
| Kyouko, no religion | Enforced in Lua by refusing religion founding for her; revisit if it proves fragile. |
| Mami, Tiro Siege | Once per turn per Musketeer, does not consume the attack, virtual attack at Cannon strength with its city bonus. |
| Ultimate Madoka, Led Away bonus promotion | One free promotion of the player's choice (promotion-ready flag), after XP is restored. |
| Kazumi | Section 9 proposal stands until the maintainer amends it. |
| Devil Homura | Whole kit provisional pending Walpurgisnacht Rising; build the DLL columns so the numbers stay data. |
| Devil Homura, Witch kills | **Ruled:** gold replaces the Golden Age points. A Witch kill pays 10 gold plus 3 per era; clearing a Witch's Labyrinth pays 25 gold plus 10 per era. Ancient era: 10 and 25. Information era: 31 and 95. **Devil Homura only, and part of Ai Yo**, so it belongs in the trait tooltip and Civilopedia rather than the shared Witch rules. Implemented in `GetGriefSeed` and `CheckDestroyWitchBarrier`, which also fixes the Labyrinth clear currently removing 1 gold. |

## 13. Build order

1. UMG framework: mission gating, persisted cooldowns, virtual-attack helper, timed-promotion helper, AI hook, panel readout.
2. Data-only kits: Nagisa, Oriko/Kirika, Madoka's Middle School, Kyouko's economy, Mami's city-state and trade yields.
3. Per-civ UMGs on the framework, one civ at a time, each with its AI rule and text.
4. Lua-heavy mechanics: Time Stop free turn, Thief of Time, Law of Cycles return, Tiro Siege, Sayaka tourism conversion, Kazumi Freezer.
5. DLL: Ai Yo columns in the bundled build.
6. Text and Civilopedia pass for every renamed civ, city list and ability.


---

## 14. Build log (2026-09-17)

**Done and verified in the simulator.**

- Exclusivity: the Magical Girl system belongs to the ten MG civs; Witch kills by outsiders deny the Grief Seed.
- `MAGICAL_GIRL_STRENGTH_PERCENT` is 100, and the era strength curve no longer dips entering the Atomic era.
- Leader-ability framework: registry, cooldowns per girl, timed promotions, virtual-attack helpers, AI driver,
  and a `NON_CITY_ENEMY` target type so highlights match what an ability accepts.
- All eight specified abilities: Pluvia Magica, Nothing To Despair Ever, Concentrated Missile Fire, Falsified
  Phenomena, Baldamente Fortissimo, Kugatachi, Tiro Finale, Rule Break. Each has help text and an AI rule.
- Data kits: Nagisa, Madoka, Oriko/Kirika, Kyouko, Mami.
- Ultimate Madoka and Devil Homura now get Leader Magical Girls, with fixed Mood and Soul Gem states.

**Bugs found and fixed on the way.** CP's `Unit:GetCombatDamage` is a stub returning 0, so Tiro Finale had been
dealing no damage since the port. Pluvia Magica skipped its own target (the plot iterator's centre flag). A timed
promotion re-applied before it expired was stripped early. The Shirome trait gate keyed on a column every civ now
uses. Kyouko's and Mami's dummy-driven building scripts were retired or rewritten after their dummies were deleted.

**Build status, 2026-09-18.** Every civ's specified kit is implemented and verifies offline (82 Lua files parse, the
simulated database build shows only the 15 long-standing failures). The bundled DLL carries Ai Yo and Mami's city cap and
is installed in the game's Community Patch folder (`scripts/deploy_dll.py --restore` puts the original back). Nothing has
been exercised in a real game yet.

**Open rulings.**
1. Sayaka's wonder Tourism: CP's per-wonder row is +100% of all Tourism in that city and stacks; exact "double each
   wonder's Tourism" needs a Lua tally.
2. Kazumi: `GreatWorkWLTKD` is an on/off flag (every city, about 6 turns), and Teddy Bear monopolies only work under Vox
   Populi's resource-monopoly option.
3. Ultimate Madoka keeps the old Summon Witch alongside Witch Form: keep or remove?
4. Ultimate Madoka and Devil Homura still get the free starting Archer that compensated for having no leader girl.
5. Homura no longer has any conquest steal (the Thief of Time is a Scout now); drop it for good, or give it back to the trait?
6. Mami's city cap ignores puppets (Venice-style) by default.
7. Nagisa and Oriko/Kirika have no leader-girl ability.
8. Tiro Musketeers keep Tiro Siege after upgrading to Riflemen.

**Known approximations.** Time Stop's free turn under-counts healing, city-state and deal income, and border growth;
Kyouko's luxury rule treats city-state luxuries as her own. All are commented where they live.

## 15. Rulings, round 3 (2026-09-18)

| # | Topic | Ruling |
|---|---|---|
| 1 | Sayaka, wonders | Every wonder she has built gives +5% Tourism in **all** her cities. Replaces the per-city +100% policy. |
| 2 | Kazumi, Great Works | Creating a Great Work grants a random bonus of Gold, Faith, Science or Culture, pending a full rework of the civ. |
| 3 | Ultimate Madoka | Keeps Witch Form, renamed **Summon Herald of the Cycle** for her. The old Summon Witch (spawning a Witch unit) is removed. |
| 4 | Ultimate Madoka, Devil Homura | The free starting Archer is removed. |
| 5 | Homura | The conquest steal is dropped for good; the Thief of Time Scout fills that role. |
| 6 | Mami | **Cannot annex, raze or puppet.** A city she captures becomes a new city-state of a random type, keeping the original city's name, at maximum influence with her. |
| 7 | Nagisa | Leader ability **Magic Cake Dish**: adjacent friendly units heal 25% of their HP and gain +10% Combat Strength for 3 turns. |
| 8 | Oriko and Kirika | Oriko: **Oracle Ray**, 5 random hits at 60% strength spread across the enemy units in an area around an enemy unit, 5-turn cooldown. Kirika: **Vampire Fang**, 150% against one enemy unit, -25% Combat Strength on it for 2 turns, and she heals half the damage dealt. |

**Tabled 2026-09-18: ruling 6 (Mami cannot annex, raze or puppet; captures become city-states).** Not implemented. Notes
for when it resumes:
- The city must not change hands inside `GameEvents.CityCaptureComplete`: `CvPlayer::acquireCity` keeps using the
  city after that hook (`CvPlayer.cpp` ~4349-4420), so transferring it there is a use-after-free crash.
- A safe point is after `acquireCity` returns, e.g. the capturing unit's `UnitSetXY` (`CvUnit.cpp` 20739 then 21272).
- CP's capture popup (`PuppetCityPopup.lua`) returns without showing if the active player no longer owns the city.
- `Player:AcquireCity(city, bConquest, bGift)` and `ChangeMinorCivFriendshipWithMajor` are bound; influence cap is
  `FRIENDSHIP_THRESHOLD_MAX` (120). A genuinely new city-state needs a free minor slot and is DLL research.

## 16. Rulings, round 4 (2026-09-22)

| # | Ruling | Implementation |
|---|---|---|
| 1 | Ultimate Madoka's diplomacy music is *Sagitta luminis* (peace and war). | Soundtrack pack `SND_LEADER_MUSIC_MADOKA_*` → `MadokaCiv-Peace41`; original Madoka unchanged. |
| 2 | Ai Yo: Devil Homura cannot be in a Declaration of Friendship (neither proposes nor accepts; AIs never offer). | Trait column `PMMMNoFriendship`; DLL gates in `CvDiplomacyAI` (`IsWantsDoFWithPlayer` on CP, `IsDoFAcceptable`, and `SetDoFAccepted` as a backstop). |
| 3 | Ai Yo: City-States can be her Friends but never her allies. | Trait column `PMMMCannotAllyCityStates`; DLL gate on the Ally-threshold test (CP `IsFriendshipAboveAlliesThreshold`, Lekmod `DoFriendshipChangeEffects`), which also strips an alliance an older save carries. |

| 4 | Clara Dolls gain +2 [ICON_STRENGTH] Combat Strength per era and are buildable in every era; they still upgrade normally, and the upgraded unit keeps the Magical Girl tree, the era scaling and the Clara Doll identity. | `Units.ObsoleteTech = NULL`; identity promotion `PROMOTION_PMMM_CLARA_DOLL` (no effect of its own, `CannotBeChosen`, granted free, survives upgrades); DLL: an optional promotion-class override on the validity helpers, passed by `CvUnit::isPromotionValid` when the unit carries the tag; Lua: `SetClaraDollStrength` in `PMMMClaraDoll.lua` sets the chassis's Combat + 2 x era on every turn and move. |

Ruling 4's rationale: upgrading dolls late was a gold and turn sink just to field units with the Magical Girl
tree. A late-built doll stays a Swordsman chassis on purpose (28 strength by the Modern era): cheap, spammable,
and a promotion carrier rather than a front-line unit.

| 5 | Ai Yo: [ICON_HAPPINESS_1] Happiness that Policies and Ideology tenets would give her becomes twice as much [ICON_CULTURE] Culture instead. | Trait column `PMMMPolicyHappinessToCulture`; DLL adds `GetPMMMPolicyHappiness` (the two policy happiness modifiers) and `GetPMMMCultureFromPolicyHappinessTimes100`, added beside the engine's own excess-happiness-to-Culture component; the happiness itself is suppressed (CP: in `CvCity`, Lekmod: in `CvPlayer::GetHappinessFromPolicies`). |
| 6 | The Ai Yo trait description overflowed the trait window; shortened. | `SQL/Phase4/DemonHomura.sql`, 780 -> 522 characters over 5 lines. The Civilopedia entry keeps the long form. |

| 7 | Ai Yo: a Courthouse still lifts an annexed city's extra occupation Unhappiness, but pays it out as Gold each turn. | Trait column `PMMMCourthouseUnhappinessToGold` (Gold per point, 1); Lua only, `DemonHomuraCourthouseGold` in `PMMMDemonHomuraTrait.lua` on her per-turn hook. Extra per city = (captured-city minus ordinary-city) + population x (occupied minus ordinary per-pop) from the Defines: 2 + 0.34 x pop on CP, so about 3/5/7 Gold at population 5/10/15. Not shown in the Gold-per-turn tooltip; an alert fires when the amount changes. |

Ruling 5 correction (same day): the first build counted only the two flat policy happiness modifiers, which no
policy or tenet in the database uses, so it converted nothing. Policy happiness actually arrives per building
(`Policy_BuildingClassHappiness`: Militarism +2 per Barracks/Armory/Military Academy, Police State +3 per
Courthouse, Fortified Borders, Universal Healthcare and most Order/Freedom tenets), per garrison (Military Caste)
and per population (Aristocracy). `GetPMMMPolicyHappiness` now counts all of these, so the militaristic options
that exist to absorb conquest unhappiness (the maintainer's stated reason for the ruling) pay her in Culture.
Only the flat modifiers are suppressed; the rest still shows as happiness, which does nothing for her. Policy
unhappiness *reductions* (Monarchy -50% capital, Meritocracy -5%, Universal Suffrage) are not converted and
slightly shrink her bonus.

Ruling 5 note: the suppressed happiness was already inert for her, since her yield bonus reads gross unhappiness
from cities and population rather than the net figure. The conversion is what makes Policy happiness worth
anything to her at all, and it softens the culture weakness the rest of the kit creates.

Both DLLs carry rulings 2-5: CP via `scripts/dll_patch_phase4.py` (`patch_ai_yo_diplomacy`), Lekmod via
`dll/lekmod-wftw-aiyo-diplomacy.patch` (an `EXTRA_PATCHES` entry). Patch-script rule learned the hard way: new
steps insert only at the boundaries of blocks earlier steps inserted, never inside them, or those steps stop
recognising themselves and insert a second copy.
