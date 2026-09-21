# Lekmod Phase 6 scoping, investigation 1: engine (Lua) dependencies

Research report produced 2026-09-18 for the Lekmod scoping pass (brief: `lekmod-scoping-plan.md`, investigation 1).
Sources: `wftw/` at its current Phase 4 state, `upstream/Community-Patch-DLL/` (CP 5.4.6 source, engine reference),
`upstream/Lekmod/LEKMOD_DLL/` (Lekmod's DLL source), `dll/pmmm-phase4.patch` (our own additions), `docs/HANDOVER.md`
sections 1/3/6/9, `docs/agent-contract.md`, and the sibling reports `lekmod-scope-multiplayer.md` (investigation 3)
and `lekmod-scope-database.md` (investigation 2). Every availability claim below was checked against the two DLL
source trees by grep plus reading the call site — no claim rests on memory. Where a search found nothing, the
search is stated.

## 0. Headline answers

1. **WFTW's engine dependencies are a small, well-defined set: everything is whoward's "DLL Various Mod Components"
   (DVMC) that the Community Patch absorbed wholesale.** The mod's own registration file says so in comments
   (`wftw/Lua/PMMMWishForTheWorldMain.lua:248` onwards: "added by DVMC"), and the mod ships whoward's options file
   that switches the corresponding CP event systems on (`wftw/XML/CIV5Options-MadokaDVMC.xml`, 16 options set to 1).
   Nothing depends on Vox Populi gameplay, CP's diplomacy rework, or CP's combat rework except one pair of methods
   (item 3).
2. **Nine GameEvents are missing on Lekmod, and they collapse into one keystone: custom unit missions.** Seven
   items once the three `CustomMission*` hooks are counted as one feature. The other six events are small,
   independent hook insertions (5–30 lines each). One event the mod uses (`UnitCreated`) exists on Lekmod but with
   a *different argument signature* — the handlers must be re-pointed (a Lua fix, not a DLL one).
3. **The custom-mission port into Lekmod's DLL is surprisingly small: roughly 120–180 lines in one file**
   (`CvUnitMission.cpp`), because everything hard about missions — transport, serialization, database loading — is
   mission-ID-agnostic vanilla machinery that Lekmod already has. No serialization work, no network work, no AI
   weight work. The one-line proof: CP's `CanStartMission` asks Lua before falling off the end of its hardcoded
   mission chain (`CvUnitMission.cpp:1352-1355`); Lekmod's just falls off (`CvUnitMission.cpp:1340`).
4. **Fifteen Lua methods the mod calls are bound in CP and not in Lekmod.** Twelve have trivial Lua workarounds
   (Lekmod even binds better replacements for two of them). The hard ones are `Unit:GetMeleeCombatDamage` /
   `GetMeleeCombatDamageCity` (backing combat code does not exist in Lekmod) and `City:GetSpecialistRate`
   (backing is a CP-only class). `ChangeOverflowResearch` and `AddMessage`-family are binding-only ports or
   one-line shims.
5. **Our own DLL additions (`dll/pmmm-phase4.patch`: Ai Yo, the city cap, the seven `Traits.PMMM*` columns) must be
   re-applied to whatever DLL ships** — estimated 250–400 lines rewritten against Lekmod's vanilla happiness
   pipeline. The patch does *not* contain custom-mission support; that is native CP, and it is the keystone of
   item 2.
6. **Two corrections to `HANDOVER.md` section 9:** `CanHavePromotion` and `PlayerCanFoundReligion` *are* in
   Lekmod's DLL (Lekmod `CvUnit.cpp:22652` and `:8650`, identical signatures to CP's). The handover table's
   "per-unit promotion filter" line overstates the gap. What section 9 got right in spirit: everything else on its
   "No" lines is confirmed missing here.
7. **Inputs for fork-vs-upstream:** the total engine-side port into Lekmod's DLL is modest — one keystone feature
   (~120–180 lines), six small hooks (~80–130 lines combined), a handful of convenience bindings (~50–100 lines),
   plus our own 250–400-line patch — all in a DLL whose license (investigation 3, section C) forbids
   redistribution without the maintainer's prior written permission. Engine work is the same either way; only the
   shipping route differs.

---

## 1. Method

**Mod-side inventory.** A scanner (`build/inv_engine.py`, scratch, gitignored) stripped comments and strings from
every `.lua` under `wftw/Lua` (64 files) and extracted, with file:line:

- every `GameEvents.<Name>` reference — **25 distinct names**;
- every bare `Events.<Name>` reference (word-boundary filtered so `GameEvents.`/`LuaEvents.` do not pollute it) —
  **19 distinct names**;
- every `LuaEvents.<Name>` reference — **28 distinct names**;
- every `receiver:Method(` call — 668 raw `(receiver, method)` pairs, attributed to a class (Unit/Player/City/
  Plot/Team/Game/Map) by inspecting the receiver variable's assignment.

`wftw/UI Replacements/` (5 Lua files, UI context) was reviewed by hand for engine-object calls: it uses only
`Game.HandleAction`, `Game.CanHandleAction`, `Game.SelectionListGameNetMessage` and `LuaEvents` — all available in
Lekmod (section 4.3).

**DLL-side availability.** Two mechanisms deliver events to Lua in Civ V:

- *Vanilla string hooks*: the DLL builds a `CvLuaArgsHandle` and calls `LuaSupport::CallHook / CallTestAll /
  CallTestAny / CallAccumulator(pkScriptSystem, "EventName", ...)`. Both DLLs use this; Lekmod fires ~100 distinct
  names, CP ~93 (CP replaced some vanilla sites with its own macro).
- *CP's event framework*: `GAMEEVENTINVOKE_{HOOK,TESTANY,TESTALL,VALUE,ACCUMULATOR}` macros
  (`CustomMods.h:1215-1218`) over 207 `#define GAMEEVENT_X "Name", "signature"` entries in `CustomMods.h`, many
  gated behind `MOD_EVENTS_*` switches read from the `CustomModOptions` database table
  (`NewCustomModOptions.xml` defaults them to 0; our mod's `wftw/XML/CIV5Options-MadokaDVMC.xml` flips 16 to 1).
  **Lekmod's DLL has none of this machinery**: searched `upstream/Lekmod/LEKMOD_DLL` for `CustomMods`, `GAMEEVENT`
  and `MOD_EVENTS_` — zero hits. Lekmod's DLL is vanilla-lineage (vanilla + AUI-style `#ifdef` fixes + Lekmod's
  own `LEKMOD_*` blocks).

Availability therefore required *three* checks per event: (a) the hook name exists in the DLL, (b) the argument
signature matches what the mod's handlers read, and (c) it is not gated off. Check (b) mattered: `UnitCreated`
exists on Lekmod but with different arguments (section 2.4).

**What counts as whose.** Per the brief, `dll/pmmm-phase4.patch` is ours, not CP's. Everything behind a
`MOD_EVENTS_*` option the mod flips in `CIV5Options-MadokaDVMC.xml` is CP-absorbed DVMC. The `DiploModifiers`
database table itself is CP-added (section 2.3), which drags one event port into investigation 2 territory as well.

**Lua method availability.** Bindings were extracted from both DLLs' `CvLua*.cpp` `Method(Name);` registration
blocks. CP binds 3401 method names across the ten core classes vs Lekmod's 2391 (Unit 537 vs 390, Player 1264 vs
853, City 616 vs 390, Plot 278 vs 193, Team 181 vs 143, Game 380 vs 287, Map 38 vs 36, Deal 61 vs 56, TeamTech 21
vs 18). Every method name the mod calls was tested against those tables; the 15 that are CP-only were then
checked for their C++ backing in Lekmod (a binding can be missing while the backing exists, and vice versa).

## 2. Event dependencies

### 2.1 The full GameEvents inventory and availability

All 25 events the mod subscribes, with the DLL that fires them and their Lekmod status. "Signature" compares the
`args->Push` lists at the fire sites in both DLLs.

| GameEvent | Mod subscriptions (first site) | Lekmod? |
|---|---|---|
| `PlayerDoTurn` (21 handlers) | `PMMMAbilityHomura.lua:670` + 20 | Yes, identical (`CvPlayer.cpp:5161`) |
| `UnitSetXY` (9) | `PMMMWishForTheWorldMain.lua:178` + 8 | Yes, identical (`CvUnit.cpp:18095`) |
| `CustomMissionPossible` (14) | `Main.lua:252-265` | **No** |
| `CustomMissionStart` (16) | `Main.lua:267-282` | **No** |
| `CustomMissionCompleted` (14) | `Main.lua:284-297` | **No** |
| `UnitPrekill` (4) | `PMMMUUBootstrapper.lua:67` + 3 | Yes, identical (`CvUnit.cpp:1760`) |
| `UnitKilledInCombat` (4) | `Main.lua:194-197` | Yes (`CvPlayer.cpp:17861`); CP adds a 4th arg the mod does not read |
| `CityCaptureComplete` (4) | `Main.lua:200-203` | Yes, identical 9-arg form (`CvPlayer.cpp:3603`) |
| `UnitCreated` (2) | `Main.lua:233-234` | **Signature mismatch** — see 2.4 |
| `TileImprovementChanged` (2) | `Main.lua:241-242` | **No** |
| `TeamSetEra` (1) | `Main.lua:245` | Yes, identical (`CvTeam.cpp:7863`) |
| `PlayerPlunderedTradeRoute` (1) | `Main.lua:296` | **No** |
| `CanDoCommand` (1) | `Main.lua:299` | **No** |
| `GetDiploModifier` (2) | `Main.lua:302-303` | **No** (and table is CP's — see 2.3) |
| `CombatEnded` (4) | `Main.lua:306-309` | **No** |
| `MakePeace` (1) | `Main.lua:312` | Yes, identical (`CvTeam.cpp:1779`) |
| `CityConstructed` (2) | `PMMMAbilitySayaka.lua:310` + 1 | Yes, identical (`CvCity.cpp:16324`) |
| `PlayerCityFounded` (2) | `PMMMAbilitySayaka.lua:311` + 1 | Yes, identical (`CvPlayer.cpp:8920`) |
| `GreatPersonExpended` (3) | `PMMMAbilityUltimateMadoka.lua:193` + 2 | Yes, identical (`CvPlayer.cpp:18044`) |
| `UnitPromoted` (2) | `Main.lua:231` + 1 | Yes, identical (`CvUnit.cpp:11303`) |
| `PlayerAdoptPolicy` (2) | `PMMMCoreLikesDislikes.lua:221` + 1 | Yes, identical (`CvPlayer.cpp:16897`) |
| `CityCanConstruct` (2) | `Main.lua:224` + 1 | Yes, identical (`CvCity.cpp:3679`) |
| `CanHavePromotion` (1) | `PMMMClaraDoll.lua:40` | Yes, identical (`CvUnit.cpp:22652`) |
| `PlayerCanFoundReligion` (1) | `PMMMKyoukoTrait.lua:265` | Yes, identical (`CvUnit.cpp:8650`) |
| `GreatWorkCreated` (1) | `PMMMAbilityKaoruUmika.lua:165` | **No** |

Fifteen of 25 carry over unchanged. Nine are missing. One more (`UnitCreated`) needs a Lua-side fix for its
arguments.

`Events.*` (19 names: `GameplayAlertMessage`, `SerialEventHexHighlight`, `LoadScreenClose`, …) are fired by the
game executable, not the game-core DLL — searched both DLL trees for each name, zero hits — so they are identical
on Lekmod and out of scope. `LuaEvents.*` (28 names) are mod-defined cross-context signals with no DLL
involvement at all.

### 2.2 The keystone: custom missions

Covered in full in section 3. Port size ~120–180 lines, one file. Everything else in this section is small.

### 2.3 The six non-mission missing events

Each of these is an independent hook insertion into Lekmod's DLL. Sizes are the insertion plus its gate (if we keep
CP's option-gating design) — on a Lekmod fork the gates could be dropped and the hooks made always-on, since the
`CustomModOptions` table does not exist there (that file becomes inert; the option names would have to be handled
by investigation 2's schema work or simply hardcoded).

**CombatEnded** — CP `CvUnitCombat.cpp:3423`, an ungated string hook with a 15-argument signature (attacker
owner/id/damage/final damage/max HP, defender likewise, interceptor likewise, plot X/Y; verified against the mod's
handlers). The mod hangs four core handlers on it (`Main.lua:306-309`): trait scripts, **`OnCombatEndedDidMGKillWitch`
— the Grief Seed economy, the mod's core loop** — fighting-near-leader detection, and QBD damage recovery.
Port: mirror CP's `args->Push` block at the equivalent point of Lekmod's combat resolution (`Lekmod
CvUnitCombat.cpp`, function that resolves melee/ranged combat) — ~25–30 lines. The mod's option file enables
`EVENTS_RED_COMBAT_ENDED`, but the hook itself is ungated in CP, so no gate needed. Workaround: none — without
this hook the mod cannot detect witch kills made in combat; the whole Grief Seed loop dies with it. **Priority
2 after custom missions.**

**TileImprovementChanged** — CP `CvPlot.cpp:9014` and `:9259`, gated `MOD_EVENTS_TILE_IMPROVEMENTS`, 6 args (x, y,
owner, old improvement, new improvement, pillaged). Mod: `Main.lua:241-242` — Kyouko's Stolen Food accrual and
familiar-pillages-improvement detection. Port: the same two sites exist in Lekmod's `CvPlot.cpp`
(`setImprovementType` and its pillage path; Lekmod fires no hook there today — searched, zero hits) — ~12–15 lines.
Workaround: none clean; polling improvements each turn from `PlayerDoTurn` would approximate the non-pillage half
at real CPU cost.

**GetDiploModifier** — CP `CvDiplomacyAI.cpp:49461-49489`, gated `MOD_EVENTS_DIPLO_MODIFIERS`. Complication: the
`DiploModifiers` database table itself is CP's (`(1) Community Patch/Database Changes/Mod Support/
NewDiploModifierTables.xml:6`), and the mod adds two rows to it (`wftw/XML/CIV5DiploModifiers-Madoka.xml`) for the
witch-hunt and witch-bombing penalties (`Main.lua:302-303`). Porting the *event* without the table gets nothing;
the real port is the info class + table load + the opinion-list loop, ~80–150 lines, and the table creation
belongs to investigation 2. Note for Phase 6's multiplayer goal: CP itself skips the AI-scoring side of these
modifiers in networked games (`CvDiplomacyAI.cpp:14310` checks `!isReallyNetworkMultiPlayer()`), so this feature
is SP-flavoured even on CP. Workaround: move the penalties to a Lua-maintained diplo score via other means, or
drop them — they are flavour, not mechanics.

**PlayerPlunderedTradeRoute** — CP `CvTradeClasses.cpp:5200`, 9 args. Mod: `Main.lua:296` (trait scripts on
plunder). Lekmod has the vanilla trade system in `CvUnit::plunderTradeRoute` (Lekmod `CvUnit.cpp:7476` onwards;
Lekmod even has its own plunder-blocked-by-trait check at `:7477-7487`), so the insertion point exists — ~10–15
lines. Workaround: none (no other event reports plundering).

**CanDoCommand** — CP `CvUnit.cpp:4440` (`CallTestAll`, gated `MOD_EVENTS_COMMAND`), 8 args. Mod:
`Main.lua:299` — `PreventDeletePMMMUnits`, which stops players deleting Magical Girl units. Port: the vanilla
`canDoCommand` exists in Lekmod's `CvUnit.cpp` — ~8–10 lines. Workaround: none; the delete command cannot be
intercepted in Lua otherwise.

**GreatWorkCreated** — CP `CvUnit.cpp:9691`, ungated hook, 3 args (owner, unit, great work type). Mod:
`PMMMAbilityKaoruUmika.lua:165` — Kazumi's random-yield-on-Great-Work ability (her interim Phase 4 kit). Port:
Lekmod's great-work creation site in `CvPlayer`/`CvUnit` (searched for the hook name — zero hits) — ~5 lines.
Workaround: poll `Game.GetNumGreatWorks()`-style state from `PlayerDoTurn`, which is exactly the ugly the event
exists to avoid; acceptable only because Kazumi's rework is pending anyway.

### 2.4 The signature trap: `UnitCreated`

Lekmod *does* fire `UnitCreated` — but it is a Lekmod addition (`#ifdef LEKMOD_NEW_LUA_EVENTS`, "MOD.EAP"
comment, Lekmod `CvUnit.cpp:950-966`) with the signature `(iOwner, iUnitID, iX, iY)`. CP fires
`(iOwner, iUnitID, iUnitType, iX, iY)` (`CvUnit.cpp:1253`). The mod's two handlers read the **third** argument as
the unit type:

- `PMMMMagicalGirls.lua:57` — `function OnCreatedMagicalGirl(iPlayer, iUnit, iUnitType)`; `:61` tests
  `iUnitType == iMagicalGirl` — the Magical Girl spawn/respawn bookkeeping;
- `PMMMMagicalGirls.lua:1035` — `GiveGPAName(iPlayer, iUnit, iUnitType, bMagicalGirl)`.

On Lekmod the third argument would be the plot **X coordinate**. The type test would fail almost always — and
succeed by coincidence when X happens to equal the MG unit type ID, a heisenbug. This is not a DLL port at all:
the fix is Lua-side (take the type from `pUnit:GetUnitType()`, which both DLLs bind), and it must be on the port
list because the event "existing" on Lekmod would otherwise look like a green light.

### 2.5 Corrections to HANDOVER section 9

| HANDOVER §9 claim | This investigation's finding |
|---|---|
| "per-unit promotion filter — No" | `CanHavePromotion` **is** in Lekmod (`CvUnit.cpp:22652`, `CallTestAll`, identical args to CP's). The mod itself documents this: `PMMMClaraDoll.lua:18-20`, "raised by CvUnit::canAcquirePromotion in both DLL builds" |
| "Great Work creation event — No" | Confirmed missing (section 2.3), but it is 5 lines, not a feature-sized port |
| "city-state ally/friend yields — No" | Out of engine scope: the *methods* the mood/targeting code needs (`GetInfluencePerTurn` Lekmod `CvLuaPlayer.cpp:264`, `IsPlayerHasOpenBorders` `:585`, `GetMinorCivFriendshipLevelWithMajor` `:594`) are all bound in Lekmod. What is missing is CP's *data columns* for ally/friend trait yields — investigation 2's territory |

## 3. Custom unit missions: full write-up

### 3.1 What a mission is, mechanically

Civ V missions (move, found, sleep, …) are rows in the `Missions` database table. Both DLLs load mission types
**dynamically**: `NUM_MISSION_TYPES = db.Count("Missions")` and a `CvTypes` preload loop reads every row into
`CvTypes::getMISSION_*` handles (verified identical: CP and Lekmod `CvTypes.cpp:237-254`). Nothing in either
engine hardcodes the vanilla mission count, so 34 mod-added mission rows cost the engine nothing.

What the engine *does* hardcode is the mission's **behaviour**: `CvUnitMission::CanStartMission` is a giant
`if (iMission == CvTypes::getMISSION_X()) …` chain, and `StartMission` / `DoStepMission` are similar switches. A
mission ID that matches no case simply never starts and never does anything. That is the whole reason custom
missions need DLL support.

### 3.2 WFTW's mission inventory

**34 distinct mission types** (`grep "'MISSION_PMMM" wftw/SQL | sort -u`), inserted in 14 SQL files:

- shared system missions: `wftw/SQL/Shared/MGMissions.sql` (Witch Hunt, Grief Seed, Purification Through Hope,
  Sparring, Socialize/Auto-Socialize, Dull Pain, Vacation, Write Home/Contact Home, Summon Witch Form,
  Appearance Update, Dismiss Witch, Kyouko's food pair);
- per-civ missions: `KaoruUmika/KaoruUmikaMissions.sql`, `Kyouko/KyoukoMissions.sql`, `Mami/MamiMissions.sql`,
  `UltimateMadoka/UltimateMadokaMissions.sql` and the Phase 4 ability missions in
  `wftw/SQL/Phase4/{Abilities,DemonHomura,Homura,KaoruUmika,Kyouko,Nagisa,OrikoKirika,Sayaka,UltimateMadoka}.sql`
  (Tiro Finale, Pluvia Magica, Time Stop, Concentrated Missile Fire, Rule Break, Oracle Ray / Vampire Fang, …).

The base rows copy vanilla `MISSION_RANGE_ATTACK` / `MISSION_TRADE` columns and add three mod columns
(`PMMMMissionRange`, `PMMMTargetType`, `PMMMMissionExec`) that only the mod's Lua reads — engine-invisible. The
leader-ability framework binds each civ's unique ability to one of these missions through a `Traits` column
(`LeaderMGUniqueMission`, set in `wftw/SQL/Phase4/*.sql`, read only by `PMMMLeaderAbilities.lua` — the DLL never
sees it).

Three of the 34 are "dummy" missions whose entire job is to ride the mission system's network replication to sync
state in multiplayer — investigation 3 verified that pattern is MP-correct (its section B0).

### 3.3 The round trip, and where each leg lives

1. **Button (UI).** `wftw/UI Replacements/UnitPanel.lua:1339-1347`: a mission action whose row has a
   `PMMMTargetType` string enters target mode via `LuaEvents.PMMMSetCustomMissionInfo`; otherwise
   `Game.HandleAction(action)` directly.
2. **Targeting (UI).** `MagicalGirlMissionHandler.lua:28` `SetCustomMissionInfo` → `FindMissionRange`
   (`:51`, LOS/hill logic, using the mod's own `PlotAreaSpiralIterator` from `wftw/Lua/Utils/VV_PlotIt.lua:113`)
   → `FindValidTargets` (`:116`, ten target types:
   enemy, non-city enemy, friendly, friendly MG, sparring, enemy city, enemy critical MG, empty plot, …).
3. **Commit (UI → net).** `PMMMWishForTheWorldMain.lua:112`:
   `Game.SelectionListGameNetMessage(GAMEMESSAGE_PUSH_MISSION, missionID, -iX, -iY, 1, false, false)` —
   coordinates are *negated* so the engine's built-in "walk to plot" reading of a move mission cannot send the
   girl running to the clicked tile; the mod's handlers negate them back
   (`PMMMLeaderAbilities.lua:271`, `-iData1, -iData2`).
4. **Transport (EXE).** The binding `Game.SelectionListGameNetMessage` exists in both DLLs (CP
   `CvLuaGame.cpp:63`, Lekmod `CvLuaGame.cpp:57`), and its implementation just forwards to the engine, which
   broadcasts a net message to every client and lands it in `CvGame::selectionListGameNetMessage` (Lekmod
   `CvGame.cpp:2880`, the `sendPushMission` call at `:2943`; CP equivalent identical in shape). This leg is
   **mission-ID-agnostic** — the EXE neither knows nor cares whether ID 71 is `MISSION_FOUND` or
   `MISSION_PMMM_TIRO_FINALE`. This is why custom missions are automatically multiplayer-safe, and why
   investigation 3 found the dummy-mission pattern correct.
5. **Gate (DLL).** `CvGame::canHandleAction` (Lekmod `CvGame.cpp:3317`) asks the head selected unit
   `CanStartMission(...)` (`:3372`) — this is where the action's button would be greyed out, and where a pushed
   mission is first validated on each client.
6. **Execution (DLL → Lua).** The queued mission is stepped by `CvUnitMission::DoStepMission` / `StartMission`,
   which in CP calls out to Lua at 8 points (below). The mod's handlers do the actual work: cooldowns, Soul Gem
   costs, damage (`PMMMVirtualAttack*`), witch spawning, turn ending
   (`PMMMLeaderAbilities.lua:271-` onwards).
7. **Serialization (DLL).** The mission queue saves generically — `eMissionType, iData1, iData2, iFlags,
   iPushTurn` (Lekmod `CvUnit.cpp:23466-23476`). Any mission ID serializes identically. **No port work.**
8. **AI (Lua).** The mod's AI does not use DLL mission weighting: `MagicalGirlMissionHandler.lua:316`
   `PushAIMissions` pushes missions from Lua via `pUnit:PushMission(...)` (bound in both DLLs — Lekmod
   `CvLuaUnit.cpp:492`). The DLL's own operational AI never needs to *choose* a custom mission. **No port work.**

### 3.4 What CP adds, exactly

CP's `CvUnitMission.cpp` calls Lua around the mission machinery (all gated `MOD_EVENTS_CUSTOM_MISSIONS`,
`CustomMods.h:813`; the mod enables it via `CIV5Options-MadokaDVMC.xml`):

| Hook | CP site | Purpose in the mod |
|---|---|---|
| `CustomMissionPossible` | `CvUnitMission.cpp:1352` | right before the end of `CanStartMission`: lets Lua approve a mission the chain does not know. 14 subscriptions (`Main.lua:252-265`), incl. the hidden-mission auto-approver (`MagicalGirlMissionHandler.lua:384`) |
| `CustomMissionStart` | `:1905` | Lua runs the mission's effect and returns `CUSTOM_MISSION_ACTION` (1, defined `:43-45`). 16 subscriptions (`Main.lua:267-282`) |
| `CustomMissionCompleted` | `:813` and `:2345` | end-of-mission bookkeeping (cooldowns, state). 14 subscriptions (`Main.lua:284-297`) |
| `CustomMissionSetActivity` | `:1462` | sets the unit's activity type while the mission runs (the "hunting" look) |
| `CustomMissionCameraTime` | `:922` | camera pan duration |
| `CustomMissionTargetPlot` | `:1977` | tells the engine where the mission's target plot is |
| `CustomMissionTimerInc` | `:2054` | timer increments for multi-turn missions |

### 3.5 Why nothing works on Lekmod, in one diff

Lekmod's `CanStartMission` (Lekmod `CvUnitMission.cpp:908`) is the same vanilla if/else chain — with Lekmod's own
`LEKMOD_TRAIT_BAN_UNIT_MISSIONS` block at `:923-929` and a vanilla Lua *veto* hook at `:943` (note: veto only —
returning true just falls through to the chain, it cannot approve an unknown mission) — and then:

```
Lekmod  CvUnitMission.cpp:1340:   return false;          // end of CanStartMission
CP      CvUnitMission.cpp:1351-1355:
          if (MOD_EVENTS_CUSTOM_MISSIONS)
            if (GAMEEVENTINVOKE_TESTANY(GAMEEVENT_CustomMissionPossible, ...) == GAMEEVENTRETURN_TRUE)
              return true;
          return false;
```

Every pushed mod mission dies at that `return false`: `canHandleAction` reports the action impossible, the queue
never admits it, and no Lua handler ever runs. The AI-push path (`pUnit:PushMission` from Lua) would enqueue, but
`DoStepMission`'s switch also knows nothing of the mission, so it steps as a no-op. Nothing short of a DLL change
fixes this — there is no Lua-only workaround, because the Lua that would do the working is never called.

### 3.6 The port, sized

Into Lekmod's `CvUnitMission.cpp` (single file, plus ~10 lines in a header for the gate if we keep one):

- the `CustomMissionPossible` test before the final `return false` of `CanStartMission` (~5 lines) — *the
  keystone; nothing else matters until this exists*;
- `CustomMissionStart` in `StartMission` and the return-value handling for `CUSTOM_MISSION_ACTION` /
  `CUSTOM_MISSION_ACTION_AND_DONE` (~30-50 lines: the enum values, the branch that skips vanilla mission
  processing and ends the unit's turn as needed);
- `CustomMissionCompleted` at the two mission-completion points (~10 lines);
- the four optional hooks (SetActivity, CameraTime, TargetPlot, TimerInc) (~40-60 lines; the mod subscribes none
  of them today — searched `wftw/Lua` for each name: only the three main families appear — so a first cut could
  skip all four and the mod would still work; hidden-mission auto-completion rides `CustomMissionCompleted`).

Whether to reuse CP's `GAMEEVENTINVOKE` macros or plain `LuaSupport::CallTestAny` hooks is a style choice; plain
hooks are simpler on a vanilla-lineage DLL (no `CustomMods.cpp` machinery to port) but change the event *names*
from CP's to our own unless we keep the strings identical. Keeping the strings identical
(`CustomMissionPossible` etc. as plain hook names) means **zero Lua changes in the mod** — the recommended route.

**Total: ~120-180 lines in one file.** Serialization: none (3.3 item 7). Network: none (3.3 item 4). AI weights:
none (3.3 item 8). The only cross-file risk is that Lekmod's `DoStepMission` diverges from CP's around the
queue-step sites, which is a matter of reading two switch statements, not new engineering.

## 4. Lua method dependencies (CP-only bindings the mod calls)

All 15, with the mod's call sites, the CP binding, whether the C++ backing exists in Lekmod, and the port or
workaround. "Binding-only port" = add a `Method(X);` + a ~5-line `lX` wrapper to Lekmod's `CvLua<Class>.cpp`.

| Method | Mod call sites | CP binding | Backing in Lekmod? | Fix |
|---|---|---|---|---|
| `Unit:GetMeleeCombatDamage` | `PMMMLeaderAbilities.lua:117` | `CvLuaUnit.cpp:64` | **No** (`CvUnit::getMeleeCombatDamage` is CP's combat rework) | port ~150-300 lines or Lua damage formula (~20 lines, see 4.1) |
| `Unit:GetMeleeCombatDamageCity` | `PMMMLeaderAbilities.lua:134`, `PMMMTiroMusketeer.lua:86` | `CvLuaUnit.cpp:65` | **No** (same) | same |
| `Player:ChangeInfluenceOnPlayer` | `PMMMAbilityHomura.lua:457` | `CvLuaPlayer.cpp:338` | No, but a near-equivalent is already bound | **Lua workaround**: Lekmod binds `Player:ChangeMinorCivFriendshipWithMajor` (Lekmod `CvLuaPlayer.cpp:592`, impl `:6727`) — receiver is the *minor*, so `Players[iCS]:ChangeMinorCivFriendshipWithMajor(iPlayer, iAmt)`; note it skips CP's influence modifiers/game-speed scaling |
| `Player:ChangeOverflowResearch` | `PMMMAbilityHomura.lua:401`, `PMMMAbilityKaoruUmika.lua:139` | `CvLuaPlayer.cpp:647` | **Yes** (`CvPlayer.h:1137` `changeOverflowResearch`) | binding-only port, ~6 lines |
| `Player:AddMessage` | `PMMMAbilityHomura.lua:597,654`, `PMMMWitches.lua:292,295,338`, `PMMMGeneralFunctions.lua:347` | `CvLuaPlayer.cpp:1277` | n/a (CP impl is a one-line `SHOW_PLAYER_MESSAGE` macro) | **Lua workaround**: Lekmod binds `Player:AddNotification` (Lekmod `CvLuaPlayer.cpp:900`) or the EXE-side `Events.GameplayAlertMessage` |
| `Player:GetNumTurnsExpansionPromise` | `PMMMCoreLikesDislikes.lua:710` | `CvLuaPlayer.cpp:1057` | No (CP promise rework; Lekmod has vanilla promises) | **Lua workaround**: drop the term — the adjacent checks `IsPlayerBrokenExpansionPromise` / `IsPlayerIgnoredExpansionPromise` *are* bound in Lekmod (`CvLuaPlayer.cpp:853-862`) |
| `Player:HasBuildingClass` | `PMMMCoreMoods.lua:1397-1398`, `PMMMCityConnectionBuildings.lua:14-15` | `CvLuaPlayer.cpp:1305` | convenience wrapper only | Lua loop: for each city, sum `GetNumRealBuilding` over `GameInfo.Buildings` of that class |
| `Player:HasTech` | `PMMMCoreMoods.lua:1414` | `CvLuaPlayer.cpp:1333` | convenience wrapper only | `Teams[pPlayer:GetTeam()]:GetTeamTechs():HasTech(i)` |
| `Player:HasWonder` | `PMMMEntertainmentSystem.lua:162,190`, `PMMMWitches.lua:307` | `CvLuaPlayer.cpp:1307` | convenience wrapper only | city loop + `GetNumRealBuilding(wonder)` |
| `Player:IsAtWarWith` | `MagicalGirlMissionHandler.lua:203`, `PMMMCoreMoods.lua:560` | `CvLuaPlayer.cpp:1325` | convenience wrapper only | `Teams[pPlayer:GetTeam()]:IsAtWar(Players[i]:GetTeam())` — the mod already uses this form at `MagicalGirlMissionHandler.lua:126` |
| `City:AddMessage` | `PMMMWitches.lua:410,423` (2-arg `(text, iPlayer)` form) | `CvLuaCity.cpp:608` | n/a | same workaround as `Player:AddMessage` |
| `City:GetSpecialistRate` | `PMMMAbilityHomura.lua:386` (Time Stop specialist GP progress) | `CvLuaCity.cpp:233` | **No** (backing is `CvCityCitizens::GetSpecialistRate`, a CP-only class) | Lua approximation from `GetSpecialistCount` × `GameInfo.Specialists` base rate (± city modifiers; Time Stop under-counts slightly), or a ~30-60 line port recomputing the rate |
| `City:HasBuilding` | `PMMMUltimateMadokaBuilding.lua:26` | `CvLuaCity.cpp:611` | convenience wrapper only | `pCity:GetNumRealBuilding(i) > 0` |
| `City:RefreshTourism` | `PMMMAbilitySayaka.lua:253` | `CvLuaCity.cpp:280` | recompute trigger only | accept next-turn recompute (tourism recomputes every turn anyway); drop the call |
| `Unit:AddMessage` | `PMMMKyoukoTrait.lua:117,129,165` | `CvLuaUnit.cpp:622` | n/a | same workaround as `Player:AddMessage` |

Everything else the mod calls on engine objects — including every mission-system binding
(`PushMission`/`PopMission`/`CanStartMission`, Lekmod `CvLuaUnit.cpp:492-495`), `GetInfluencePerTurn`,
`IsPlayerHasOpenBorders`, `GetMinorCivFriendshipLevelWithMajor`, the promise checks, `PreGame`/`GameInfo` access —
is bound in Lekmod (checked name-by-name against the Lekmod binding tables; the inventory JSON
`build/inv_engine.json` holds the full call-site lists).

### 4.1 The one hard pair: `GetMeleeCombatDamage` / `GetMeleeCombatDamageCity`

The leader-ability framework's `PMMMVirtualAttack` / `PMMMVirtualAttackCity` / `PMMMVirtualAttackPlot`
(`PMMMLeaderAbilities.lua:102,127,145`) implement every "deal N damage" ability, and they ask the *engine* for the
damage: `pAttacker:GetMeleeCombatDamage(iStrength, iDefense, true, pDefender)` (`:117`) and
`pAttacker:GetMeleeCombatDamageCity(...)` (`:134`; also `PMMMTiroMusketeer.lua:86`). The backing functions
(`CvUnit::getMeleeCombatDamage` / `getMeleeCombatDamageCity`, CP `CvUnit.h:535-536`) implement CP's combat
formula, which does not exist in Lekmod (searched `Lekmod/LEKMOD_DLL` for both names — zero hits). Note the trap
recorded in HANDOVER §6 and the agent contract: CP's `Unit:GetCombatDamage` is a stub returning 0
(CP `CvLuaUnit.cpp:1175-1190`) — the mod deliberately uses the two real methods.

Two options:

1. **Port** the CP formula (~150-300 lines: the damage calculation with modifiers CP's combat rework feeds it) —
   but then ability damage follows *CP's* combat math while the rest of the game follows Lekmod's, a fidelity
   question more than an engineering one.
2. **Reimplement in Lua** (~20 lines): the Civ V melee damage formula is public knowledge
   (base-damage tables by strength difference, scaled by HP fraction and round modifiers); compute the same
   inputs (`pUnit:GetBaseCombatStrength()`, damage, max HP — all bound in Lekmod) and keep the number under the
   mod's control. This is the recommended route for a Lekmod build: abilities become
   formula-stable across the two DLLs instead of tracking two engines.

## 5. Our own DLL additions (`dll/pmmm-phase4.patch`) on Lekmod

The patch (354 lines, 6 files) is ours, so it must be re-applied to Lekmod's DLL regardless of the fork-vs-upstream
decision. Contents and their port shape:

| Patch item | In CP build | Port to Lekmod |
|---|---|---|
| Ai Yo (Devil Homura): yield/strength bonus per 5 unhappiness | `CvCity.cpp` `getBaseYieldRateModifier` hook | same site exists in Lekmod's `CvCity.cpp`; ~10-20 lines, no serialization (computed, not stored) |
| No unhappiness penalties / no Golden Ages / no ideology pressure | `CvPlayer.cpp/.h` flags + hooks in `GetUnhappinessCombatStrengthPenalty`, `IsEmpire{,Very,Super}Unhappy`, `DoUpdateTotalUnhappiness`, `ChangeGoldenAgeProgressMeterTimes100`, `changeGoldenAgeTurns` | Lekmod has vanilla versions of every one of these functions; ~80-150 lines of guarded clauses. Caution: Lekmod rebalances happiness (investigation 2) — the clauses must be tested against Lekmod's numbers, not CP's |
| City cap (Mami): `GetPMMMCityCapUnhappiness` = step × (cities over threshold)², puppets excluded | `CvPlayer.cpp/.h` | vanilla unhappiness pipeline again; ~30-50 lines |
| `IsPMMMIgnoreUnhappinessPenalties`, `GetPMMMUnhappinessBonusPercent`, `IsPMMMNoGoldenAges`, `IsPMMMNoIdeologyPressure` | `CvPlayer.h` | trivial getters |
| 7 `Traits.PMMM*` column reads (`CacheResults`) | `CvTraitClasses.cpp/.h` | Lekmod has the same `CacheResults`; ~40-60 lines of column reads. The columns arrive via the mod's SQL — investigation 2 confirms they `ALTER TABLE` cleanly |
| Public opinion forced to 0 | `CvCultureClasses.cpp` `GetPublicOpinionUnhappiness` | Lekmod has the vanilla function; ~5 lines |

**Total ~250-400 lines across ~6 files, no serialization impact** (every value is either computed per turn or
read from the database at trait-cache time). The patch does *not* contain custom-mission support — that is
native CP (section 3), so it does not double-count.

One extra engine-read gap outside the patch: Kyouko's `UPDATE Traits SET StartsWithPantheon = 1`
(`wftw/SQL/Phase4/Kyouko.sql:29`) is read by the *engine* (CP `CvTraitClasses.cpp:1163`), not by Lua. Lekmod's
DLL will not read the column, so the free pantheon silently does nothing under Lekmod — port = one column read +
one `CvPlayer` init site (~10 lines), or reimplement the grant in Lua at game start (a workaround with save/load
edges worth avoiding).

## 6. Summary table

| Feature | CP | Lekmod | Mod features affected | Port size into Lekmod DLL | Workaround |
|---|---|---|---|---|---|
| Custom missions (`CustomMissionPossible/Start/Completed`) | native, gated `MOD_EVENTS_CUSTOM_MISSIONS` (`CvUnitMission.cpp:1352, 1905, 813/2345`) | absent — `CanStartMission` ends `return false` (`:1340`) | every MG action, every leader ability, Grief Seed use, witch hunt, sparring, socialization, all 34 mission types | **keystone: ~120-180 lines, 1 file** (start/possible/completed only; ~40-60 more for the 4 optional hooks) | none |
| `CombatEnded` | `CvUnitCombat.cpp:3423`, ungated | absent | Grief Seed from combat kills, trait combat scripts, fight-near-leader, QBD recovery (`Main.lua:306-309`) | ~25-30 lines | none |
| `TileImprovementChanged` | `CvPlot.cpp:9014, 9259` | absent | Kyouko Stolen Food, familiar pillage (`Main.lua:241-242`) | ~12-15 lines | none clean |
| `GetDiploModifier` (+ `DiploModifiers` table) | `CvDiplomacyAI.cpp:49461`; table in `NewDiploModifierTables.xml` | absent | witch-hunt / witch-bombing diplo penalties (`Main.lua:302-303`) | ~80-150 lines + table (investigation 2) | drop the penalties (flavour; CP itself disables AI scoring in networked MP, `CvDiplomacyAI.cpp:14310`) |
| `PlayerPlunderedTradeRoute` | `CvTradeClasses.cpp:5200` | absent (plunder code exists: `CvUnit.cpp:7476+`) | trait plunder scripts (`Main.lua:296`) | ~10-15 lines | none |
| `CanDoCommand` | `CvUnit.cpp:4440` | absent | prevents deleting MG units (`Main.lua:299`) | ~8-10 lines | none |
| `GreatWorkCreated` | `CvUnit.cpp:9691` | absent | Kazumi interim kit (`PMMMAbilityKaoruUmika.lua:165`) | ~5 lines | turn-based polling (ugly); Kazumi rework pending anyway |
| `UnitCreated` signature | `(owner, unit, unitType, x, y)` | `(owner, unit, x, y)` — Lekmod's own addition | MG spawn/respawn + GP naming (`PMMMMagicalGirls.lua:57,61,1035`) | 0 (Lua fix) | read `pUnit:GetUnitType()` instead of arg 3 |
| `Unit:GetMeleeCombatDamage` / `GetMeleeCombatDamageCity` | bound `CvLuaUnit.cpp:64-65` | absent, backing absent | all damage-dealing leader abilities (`PMMMLeaderAbilities.lua:117,134`) | ~150-300 lines (CP formula) **or ~20 lines Lua** | recommended: Lua damage formula |
| `Player:ChangeInfluenceOnPlayer` | `CvLuaPlayer.cpp:338` | absent | Time Stop influence accrual (`PMMMAbilityHomura.lua:457`) | n/a | `Players[iCS]:ChangeMinorCivFriendshipWithMajor(iPlayer, iAmt)` (Lekmod `CvLuaPlayer.cpp:592`) |
| `Player:ChangeOverflowResearch` | `CvLuaPlayer.cpp:647` | backing **exists** (`CvPlayer.h:1137`), binding missing | Time Stop tech progress (`PMMMAbilityHomura.lua:401`), Kaoru/Umika (`:139`) | binding-only, ~6 lines | none needed beyond the binding |
| `Player/City/Unit:AddMessage` (11 sites) | bound | absent | player-facing messages (Time Stop, witches, Kyouko) | ~15 lines or shim | `Player:AddNotification` (Lekmod-bound) / `Events.GameplayAlertMessage` |
| `Player:HasBuildingClass/HasTech/HasWonder/IsAtWarWith`, `City:HasBuilding` | bound | absent (wrappers only) | moods, entertainment system, targeting | ~40 lines of bindings | trivial Lua loops; some already used elsewhere in the mod |
| `Player:GetNumTurnsExpansionPromise` | `CvLuaPlayer.cpp:1057` | absent | city-mood demand check (`PMMMCoreLikesDislikes.lua:710`) | n/a | drop the term; Lekmod binds the promise checks (`CvLuaPlayer.cpp:853-862`) |
| `City:GetSpecialistRate` | `CvLuaCity.cpp:233` | absent, backing is CP-only class | Time Stop GP progress (`PMMMAbilityHomura.lua:386`) | ~30-60 lines | Lua approximation from specialist counts |
| `City:RefreshTourism` | `CvLuaCity.cpp:280` | absent | Sayaka wonder-tourism refresh (`PMMMAbilitySayaka.lua:253`) | ~10 lines | none needed: next-turn recompute |
| Ai Yo + city cap + `Traits.PMMM*` (ours) | `dll/pmmm-phase4.patch` | absent | Devil Homura's and Mami's core kits | **~250-400 lines, ~6 files**, no serialization | none (DLL-only by design) |
| `StartsWithPantheon` column (Kyouko) | engine read, CP `CvTraitClasses.cpp:1163` | column ignored | Kyouko's free pantheon (`wftw/SQL/Phase4/Kyouko.sql:29`) | ~10 lines | Lua grant at game start (save/load edges) |
| 15 vanilla events (`PlayerDoTurn`, `UnitSetXY`, `UnitPrekill`, `UnitKilledInCombat`, `CityCaptureComplete`, `CityConstructed`, `PlayerCityFounded`, `GreatPersonExpended`, `UnitPromoted`, `PlayerAdoptPolicy`, `CityCanConstruct`, `CanHavePromotion`, `TeamSetEra`, `PlayerCanFoundReligion`, `MakePeace`) | — | present, signatures verified identical | most of the trait/mood/witch pipeline | 0 | — |
| All `Events.*` (19) and `LuaEvents.*` (28) | EXE-fired / mod-defined | identical | UI plumbing, cross-context signals | 0 | — |

## 7. Inputs for the fork-vs-upstream decision

What the engine layer contributes to that decision (investigation 3 section C owns the license, maintenance and
community analysis; this section is the technical half):

1. **Total engine-side work to run WFTW on Lekmod's DLL:** the mission keystone (~120-180 lines, one file) + six
   small hooks (~80-130 lines combined, of which `GetDiploModifier` at ~80-150 is the largest and the most
   droppable) + convenience bindings (~50-100 lines, mostly skippable via Lua workarounds) + our own patch
   (~250-400 lines, unavoidable) ≈ **500-800 lines of C++**, all in Lekmod's vanilla-lineage code base, none of it
   touching serialization or network sync. This is a week-class project, not a month-class one, for someone
   already set up to build the DLL (Lekmod ships a VS2013 solution and `build_mod.bat`; our CP build pipeline
   targets VC9 and is documented in HANDOVER §4-5).
2. **Fork and upstream need the same code.** The port is written once either way; the choice only changes who
   merges it, who signs the release, and whether the anime-branded hooks ride the official Lekmod DLL or a
   renamed fork (investigation 3 C: the license forbids redistribution without prior written permission, and
   demands material alteration + a different name even with it). A upstreamable variant would keep the hooks
   generic (plain `LuaSupport` hooks with CP-identical names, no `PMMM` symbols in the DLL) — which is also the
   route recommended in 3.6 for zero Lua changes, so the two goals align.
3. **The gate order is fixed.** Custom missions first (nothing else can even be tested without them), then
   `CombatEnded` (the Grief Seed economy), then the `pmmm-phase4.patch` re-application (two civs' kits), then
   everything else in any order. `GetDiploModifier` and `GreatWorkCreated` are the only candidates to cut
   outright, and both cut features are flavour-side.
4. **Two features silently degrade rather than crash** if their DLL pieces are skipped: `UnitCreated`'s
   signature mismatch (section 2.4) would corrupt MG spawn bookkeeping in a way that *looks* like it works, and
   Kyouko's `StartsWithPantheon` is inert data under Lekmod. The port list should track both as "Lua/data work
   items", not DLL items, or they will be missed precisely because nothing errors.
5. **No CP-only data survives contact with Lekmod's DLL silently** — every `MOD_EVENTS_*` option the mod enables
   in `CIV5Options-MadokaDVMC.xml` is a no-op there (no `CustomModOptions` reader). On a Lekmod build that file
   should be dropped and the hooks made always-on, which removes 16 moving parts and one whole class of
   "is the option on?" debugging. That interacts with investigation 2's schema work (the options *table* also
   will not exist in Lekmod's database).
6. **What we are NOT porting matters for effort honesty:** CP's combat rework, diplomacy rework, city-state
   rework, and the whole `CustomMods` framework stay out. WFTW's engine surface is whoward's DVMC feature set plus
   our patch — small, well-bounded, and independent of the parts of CP that would genuinely be a rewrite.