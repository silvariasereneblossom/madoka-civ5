## Shared contract for every Phase 4 agent (read carefully)

Repo: `C:\Users\silvariazemaitis\Exploratory\madoka-civ5`, mod under `wftw\`. Windows. Use Bash/Read/Edit/Write/Grep; python is available; Lua syntax check: `"$LOCALAPPDATA/Programs/Lua/bin/luac.exe" -p <file>`.

**Spec.** `docs\design\phase4-design-v1.md`. Your civ's section, plus the rulings tables in sections 11 and 12 (rulings override the section text), plus the build log in section 14. The maintainer's word is final; where the spec is silent, pick the simplest reading, state it in a comment, and list it in your report.

**Other agents are editing other files in this tree at the same time.** Write ONLY the files your prompt lists. Never edit the `.modinfo`, `PMMMWishForTheWorldMain.lua`, `PMMMLeaderAbilities.lua`, `PMMMLeaderAbilityDefs.lua` or `SQL/Phase4/Abilities.sql`. Never run git. Never create new files (the manifest cannot be updated by you); put new Lua in the ability file you were given, which is already loaded into the gameplay context. You may register game events from the top level of that file, e.g. `GameEvents.PlayerDoTurn.Add(MyFunction)`; that runs when the file is included.

**Framework you build on:** read `wftw\Lua\Gameplay\MagicalGirls\PMMMLeaderAbilities.lua` in full. It provides `RegisterLeaderAbility`, per-girl cooldowns, `PMMMVirtualAttack` / `PMMMVirtualAttackCity` / `PMMMVirtualAttackPlot`, `PMMMApplyTimedPromotion`, an AI driver, `GetScaledAbilityCooldown`, the `TraitType` field (bind a second ability to a civ), and `tPMMMGriefSeedUsedHooks` (append a function `(iPlayer, iMGKey)` to react when a Grief Seed is used). Worked examples: `PMMMLeaderAbilityDefs.lua` and the files in `wftw\Lua\Gameplay\MagicalGirls\Abilities\`.

**Civ V / Community Patch facts that bite:**
- `Unit:GetCombatDamage` is a stub in this DLL and always returns 0. Use the framework helpers or `GetMeleeCombatDamage`.
- `PlotAreaSpiralIterator(pPlot, r, sector, anticlock, inwards, centre)`: the last argument decides whether the centre tile is included.
- Gameplay Lua runs on synced `GameEvents`; UI Lua runs per client. Never write game state from `Events.*` or from UI files. Use `Game.Rand` only, never `math.random`. Iterate in a fixed order (`ipairs`, numeric loops) whenever the order affects the outcome.
- `GetMagicalGirlKey(iOwner, iUnitID)` returns `false` on a miss. The Magical Girl class is `GameInfoTypes.UNITCLASS_PMMM_MAGICAL_GIRL`. Persisted mod state lives in `MapModData.PMMM` (alias `PMMM`) and `MagicalGirls`; any new persisted table must be declared in `wftw\Lua\PMMMDefines.lua`, which you may NOT edit, so instead store new per-girl fields on `MagicalGirls[key]` or ask in your report.
- Dummy buildings are allowed only when a real column cannot do the job; prefer CP data columns. Check the CP schema: `upstream\Community-Patch-DLL\(1) Community Patch\Database Changes\`.
- Game SQLite is 3.7.17: no `WITH`, no window functions, no `UPSERT`. A bare `DEFAULT true/false` is a string. A `.sql` file aborts at its first failing statement, so verify every table and column name with python sqlite3 against `build\sim_cp_wftw.db` before writing it. Use DELETE-then-INSERT or INSERT OR REPLACE so files stay idempotent.
- Text: `INSERT OR REPLACE INTO Language_en_US (Tag, Text)` or `UPDATE Language_en_US SET Text=...`. Markup: `[ICON_STRENGTH]`, `[ICON_PRODUCTION]`, `[ICON_GOLD]`, `[ICON_FOOD]`, `[ICON_RESEARCH]`, `[ICON_CULTURE]`, `[ICON_PEACE]` (faith), `[ICON_TOURISM]`, `[ICON_HAPPINESS_1]`, `[ICON_GREAT_PEOPLE]`, `[NEWLINE]`. Every changed mechanic must have player-facing text stating the real numbers. Mark every Lua change with a `--[port] Phase 4:` comment.
- Retiring an old mechanic means removing its effect cleanly: clear the data column or row, and make sure no Lua still references deleted `GameInfoTypes` ids (a nil id passed to `SetNumRealBuilding` or `SetHasPromotion` throws).

**Definition of done (verify before you report):**
1. `luac -p` passes on every Lua file you touched.
2. From the repo root: `python scripts/civdb.py build --seed build/seed_vanilla_bnw.db --out build/sim_<yourname>.db --mod "upstream/Community-Patch-DLL/(1) Community Patch" --mod wftw --report build/sim_<yourname>.md` reports **15 failures**, all pre-existing (11 `DecisionsMod/SQL/*DecisionData.sql`, `CoreGameOptionTextChanges.xml`, `XML/CBPReligiousWonder.xml`, `PMMMCBP.sql`, `PMMMSuperpower.sql`), and none of your files in the error list. Other agents' concurrent edits can briefly break the build; if a failure is not in your files, say so and move on.
3. `python scripts/luarefs.py` reports nothing new in your files (read its usage first).
4. Query the built DB and print evidence for every data change.

**Report:** files touched, verification output, every number or reading you chose that the spec did not fix, anything still pending and why, and any change needed in a file you were not allowed to touch.
