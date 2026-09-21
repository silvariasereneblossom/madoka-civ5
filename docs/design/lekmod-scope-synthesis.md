# Lekmod Phase 6 scoping: synthesis and recommendation

**Date:** 2026-09-19. This document answers the question the scoping pass was opened with: *what exactly
does it take to run Wish for the World on Lekmod, in multiplayer?* It rests entirely on the three
investigations and cites them; it adds no new evidence.

| Input | File |
|---|---|
| Investigation 1: engine (Lua) dependencies | `docs/design/lekmod-scope-engine.md` |
| Investigation 2: database dependencies | `docs/design/lekmod-scope-database.md` |
| Investigation 3: multiplayer and packaging | `docs/design/lekmod-scope-multiplayer.md` |

---

## 1. The answer, in one paragraph

It is a **port, not a patch** (as `docs/HANDOVER.md` §9 suspected), but a much smaller one than the coarse
blocker table suggested. The engine work is **~500-800 lines of C++ in Lekmod's vanilla-lineage code base** —
week-class, with no serialization or network surface (engine §7.1). The keystone is custom unit missions:
~120-180 lines in one file, without which every Magical Girl action dies at `CanStartMission` (engine §3).
The database port is cheap and mechanical: five files, all 94 `ALTER TABLE`s apply cleanly (database §4).
The two real costs sit outside the port proper: **Lekmod's license forbids redistributing any build
containing the maintainer's contributions without prior written permission** (multiplayer §C1), and the
**standing rebase tax** — data export plus a two-flavour UI rebase on every Lekmod release (multiplayer §C5.3).
Multiplayer safety needs ~4-6 days of fixes **in the CP mod, now, regardless of Phase 6** (multiplayer §B3).

## 2. The consolidated port list

| Workstream | Size | Evidence | Notes |
|---|---|---|---|
| Custom unit missions (the keystone) | ~120-180 lines, 1 file | engine §3.6 | Mission transport, serialization and AI already work on Lekmod unmodified. Gates everything else. |
| Six missing GameEvents | ~80-130 lines combined | engine §2.3 | `CombatEnded` (Grief Seed economy) first; `GetDiploModifier` (~80-150) and `GreatWorkCreated` are droppable flavour. |
| Our `pmmm-phase4.patch` re-applied to Lekmod's DLL | ~250-400 lines, 6 files | engine §5 | Ai Yo, Mami's city cap, the 7 `Traits.PMMM*` columns. Unavoidable on any route. |
| Convenience bindings | ~50-100 lines, mostly skippable | engine §4 | 15 CP-only Lua methods; 12 have Lua workarounds. Prefer a ~20-line Lua damage formula over porting the `GetMeleeCombatDamage` pair. |
| Database shim + variants | 5 files | database §8 | One early shim (~6 tables + ~25 columns), 3 content variants, 1 late data patch. Inert until the DLL hooks read it. |
| Balance rulings on copied rows | review pass, 44 rows | database §6 | Lekmod's rebalances leak into the mod via `INSERT...SELECT` (Clara Doll 4 moves, Yuriji FoodKept, dead Germany rule). Ruling per row, kept in the late patch file. |
| Packaging | the bulk of the non-C++ work | multiplayer §A2, §A7 | SQL never runs as DLC: export pipeline (80 SQL files → scratch DB → element-form XML), `InGame.lua` `LoadNewContext` patch, art copy, installer (80% reusable). Drop the dead Decisions/Events/ModCompatibility layers. |
| UI rebase | per release, ×2 flavours | multiplayer §A7 | WFTW's UnitPanel family collides with Lekmod's own replacements (standard + EUI). |
| MP-safety fixes | ~4-6 days | multiplayer §B3 | P0: mood writes from client-local `Events` (`PMMMCoreMoods.lua:117-140`); three `pairs()`-into-`Game.Rand` sites; one inert mission handler. Land in the CP mod **now**. |

Two features **silently degrade rather than crash** if tracked as DLL items only: `UnitCreated`'s signature
mismatch corrupts MG spawn bookkeeping while looking fine (engine §2.4, Lua-side fix), and Kyouko's
`StartsWithPantheon` is inert data under Lekmod (engine §7.4). Keep both on the port list as Lua/data items.

## 3. Fork versus upstream

The structural fact (multiplayer §A4): **whatever ships the engine hooks *is* the engine** — only one DLL
loads, so a WFTW pack cannot layer anything on top of an installed Lekmod. That collapses the routes to two:

- **Route (i): private fork.** The port lands in a renamed Lekmod DLL we ship to every lobby member.
  License: redistribution of the maintainer's contributions is forbidden "under any circumstances" without
  prior written permission, and demands material alteration + a different name even with it (multiplayer §C1).
  **Written permission from EnormousApplePie is a hard prerequisite, not an afterthought.** Fallback that
  avoids shipping the DLL: an installer-applied xdelta from stock Lekmod to our build, patched locally on each
  user's own download (multiplayer §C6 residual 1) — self-service but still gray, and it costs the same fork
  maintenance, so it softens rather than removes the ask.
- **Route (ii): upstream the hooks, ship an additive pack.** Lekmod is healthy (~monthly releases, external
  PRs merged, readme invites contributions — multiplayer §C2), so generic hooks riding the official DLL are
  license-clean and maintenance-free. The catch: the ~250-400-line `pmmm-phase4` remainder is
  Madoka-specific. Either EAP accepts civ-scoped hooks upstream (Lekmod already carries civ-specific DLL
  behaviour for its own civs, so there is precedent to point at), or that remainder drags us back to
  Route (i) and the permission question.

**Decision (maintainer, 2026-09-19): private first.** The port stays private for personal use for now; if it
is ever distributed publicly, the generic hooks go upstream at that point. Consequences:

1. A private Lekmod DLL fork is fully license-clean — §1 permits personal use and modification while nothing
   is distributed. No EAP conversation, no delta-installer, no zero-touch packaging needed *yet*; §C6 keeps
   that machinery recorded for the day it is.
2. For single-player private use the **DLC packaging workstream largely disappears**: normal mods load in SP,
   so WFTW stays an ordinary ticked mod on top of Lekmod's DLC — mod SQL runs directly against Lekmod's
   database (the shim path; no export, no `Override/` file), mod entry points load via the mod system (no
   `InGame.lua` bootstrap), no installer. Critical path: **DLL hooks → schema shim + variants → rebalance
   rulings → play.** First live test: Lekmod + a ticked normal mod coexist in SP and the mod's SQL executes
   after the DLC database build.
3. B3's multiplayer-safety fixes are only on the critical path if multiplayer happens in the private phase.

**When the port goes public** (the original recommendation, retained for that day): pursue Route (ii) first,
structured so Route (i) is a fallback rather than a restart:

1. Write the hook set **generic** — CP-identical names, no `PMMM` symbols in the DLL — which is also the
   zero-Lua-changes choice (engine §7.2). The code is identical either way; the routes differ only in who
   merges and signs it (engine §7.2).
2. **Ask EAP early** (Lekmod Discord, linked from `readme.md`) with the concrete hook list: (a) would he take
   the generic hooks upstream, and (b) would he take — or permit — the civ-scoped remainder. The answer maps
   us onto a route; do not write a line of the fork before it. Note (multiplayer §C6): a properly structured
   additive pack ships **no files containing his contributions** and can be fully zero-touch — no Lekmod file
   shipped, none modified even locally: export emits references to his rows, never copies; our contexts
   bootstrap from a shadowed *vanilla* InGame sub-context file Lekmod doesn't replace (live-test pending,
   installer-patch fallback); WFTW's UnitPanel family changes re-expressed additively instead of merged with
   his; our own installer. The written-permission gate survives only where his files would ship (route (i),
   bundling, installer code reuse, merged UI files).
3. **Land the B3 multiplayer-safety fixes in the CP mod now** (multiplayer §C5.5): every one is
   single-player-correct, they are cheap, and they make the eventual port diff purely additive.
4. **Pin the Lekmod version deliberately** (installed 34.15 vs upstream 35.3000) and embed our pack's version
   in the staging-room handshake — the lobby cannot catch a mismatch (multiplayer §A6, §C5.2). Note that
   Lekmod's schema itself moved between those versions (database §1, §9.5).
5. **Build the overlay script as part of the port, not after it** — the data export and UI rebase are a
   per-release tax; the script is what makes it payable (multiplayer §C5.3).

Gate order for the engine work is fixed (engine §7.3): custom missions → `CombatEnded` → `pmmm-phase4`
re-application → the rest.

## 4. Effort summary

**Private single-player build (the current plan):** engine week + database days + one live test. The
packaging and multiplayer workstreams park until distribution or MP happens.

**First public MP build (if that day comes):** ≈ engine week (upstream PR) + database days + packaging
weeks (data export, `InGame.lua` bootstrap or equivalent, installer, UI rebase) + B3's 4-6 days — call it
**a few focused weeks of solo work**, then a known rebase tax per Lekmod release. The external dependency
that gates it is EAP's answer on upstreaming, which should be requested before any fork is distributed.