# Lekmod scoping pass: plan and status

**Status (2026-09-19): complete.** All three investigations ran (a first attempt on 2026-09-18 was stopped
~15 minutes in; this is the re-run) and each wrote its report:

| Investigation | Report |
|---|---|
| 1: engine (Lua) dependencies | `docs/design/lekmod-scope-engine.md` |
| 2: database dependencies | `docs/design/lekmod-scope-database.md` |
| 3: multiplayer and packaging | `docs/design/lekmod-scope-multiplayer.md` |

The consolidated port list and the fork-versus-upstream recommendation are in
`docs/design/lekmod-scope-synthesis.md`. The briefs below are retained for provenance.

The pass answers one question: what exactly does it take to run Wish for the World on Lekmod, in multiplayer?
The output is a port list with effort estimates and a recommendation on forking Lekmod versus upstreaming.

## Investigation 1: engine (Lua) dependencies → `docs/design/lekmod-scope-engine.md`

Inventory every `GameEvents`, `Events`, `LuaEvents` and every method the mod's Lua calls on players, units,
cities, plots, teams, `Game`, `Map` and `PreGame`. For each, check whether the Community Patch 5.4.6 DLL
(`upstream/Community-Patch-DLL`) and the Lekmod DLL (`upstream/Lekmod/LEKMOD_DLL`) provide it, including events
raised only behind a `CustomModOptions` switch. Our own `PMMM*` DLL additions count as ours, not CP's. For each
missing item: the mod features it breaks (file:line), the size of a port into Lekmod's DLL (files, lines,
serialization or network impact), and any Lua-only workaround. Give custom unit missions a full write-up: every
Magical Girl action depends on them. Summary table: feature | CP | Lekmod | features affected | port size | workaround.

## Investigation 2: database dependencies → `docs/design/lekmod-scope-database.md`

Diff the simulated CP + mod schema (`build/sim_cp_wftw.db`) against vanilla BNW (`build/seed_vanilla_bnw.db`) to
find every table, column and define the mod uses that is not vanilla, and attribute each to CP or to the mod.
Parse Lekmod's `Override/CIV5Units.xml` megafile into SQLite and check each element against Lekmod's schema and
whether Lekmod's DLL actually reads it. Also: whether the mod's own `ALTER TABLE` columns apply cleanly on Lekmod;
which vanilla rows the mod copies with `INSERT ... SELECT` that Lekmod has rebalanced; Lekmod rule changes that
interact with the mod (barbarians, Great People, happiness, unit supply, religion); and how many files would need
a Lekmod variant versus one compatibility file loaded last.

## Investigation 3: multiplayer and packaging → `docs/design/lekmod-scope-multiplayer.md`

A. Packaging: how Lekmod's DLC-folder pack works (`.Civ5Pkg`, Override, Lua/UI pickup, DLL swap, lobby matching),
how Lekmod bundles one of its ~72 extra civs end to end, what the mod contains that must be carried over (by file
kind), what has no DLC-folder equivalent (`.modinfo` entry points, load order, audio reload, the soundtrack pack),
and whether `LekmodInstaller` can be reused.
B. Multiplayer safety: TableSaverLoader persistence and late join, state changes from UI code or `Events.*`,
`Game.GetActivePlayer()` in gameplay, `pairs()` order feeding `Game.Rand`, the dummy-mission sync pattern; a
prioritised fix list with effort (this is needed regardless of DLL).
C. Fork versus upstream: Lekmod's license, maintenance and contribution model, and the practical implications of
each route.
