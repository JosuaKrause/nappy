# minty-quail — Six members and constants nothing reaches, one more in the tools, and thirteen test helpers, are deleted · 2026-11-19

minty-quail's `dead-code-sweep.md`, the single finds outside `src/events/` and `src/resistance/`
(those two wait for the events' interface rows): code nothing reaches is deleted, and a feature
wanted back is built fresh (inbox #1180 in gray-dolphin). The survey is the world layer's
(`docs/decisions/2026-10-18-minty-quail-sandy-pelican.md`): every member searched for by name across
`src/`, `tests/`, `tools/`, `scenes/`, `scene-recipes/` and `project.godot`, comments stripped, and
each find read again before it went.

**Deleted, and what reached each last** (the last commit that changed the name's use, found with
`git log -S`).
- **`WalkerDoorHold.waiting()`** (`src/crowd/walker_door_hold.gd`): how many walkers queue behind
  whoever is inside a checkpoint hut. The queue's size reaches the game through `committed()`, which
  adds the walker inside; the crowd suites that once read `waiting()` were retyped to read the crowd
  through other methods (#1344), and the last test reading it went with the scene recipes' runtime
  rework (#1543).
- **`DevFlags.RIG_KILL_GRACE_SECONDS` and `RIG_MOVIE_SLOWDOWN`** (`src/dev/dev_flags.gd`): added with
  the rig's window (#353) and the trailer tools (#370), and no script ever read either: the shell
  helper takes `kill_grace` and `movie_slowdown` from the `RIG_QUIT_SECONDS` marker block in the
  same file's doc comment. The two constants' sentences on what each number means now sit above that
  block, where the helper reads them from; the comments in `tools/lib_dev_flags.sh` and
  `tools/test_cli_help.sh` name the block's keys.
- **`PauseScreen._hint`** (`src/ui/pause_screen.gd`): the handle on the pause screen's hint label,
  which nothing has written since the hint's wording left the screen (#728 moved the texts, #869 and
  #925 left no write). The scene's Hint node stays, blank, as before; `DaySummary`'s own `_hint` is
  written (`""`) and stays, its comments now carrying the player's reason themselves rather than
  pointing at the deleted doc.
- **`AtlasLibrary.MEMBERSHIP_PATH`** (`src/visuals/atlas_library.gd`): the atlas membership file's
  path, added with the bake (#245) and read by nothing in `src/`; the bake and
  `tests/test_atlas_library.gd` each declare their own.
- **`GameEnums.District`** (`src/game_enums.gd`): an enum from the game's first commits that no
  code ever named; `docs/ARCHITECTURE.md`'s list of the shared enums loses it.
- **`TABLE_TITLES`** (`tools/cost_table.gd`): the five table titles in a list, added with the cost
  table (#265) and read by nothing; each title is used on its own.
- **Test helpers nothing calls**: `CrowdRig._distance_along`, `FakeCalmAreas.set_besides`,
  `FakeWalkEvents.set_calm` and `set_doors`, `FrontReads.picture_count` and `lit_windows`,
  `ResistanceReads.home_reach`, `ResistanceRig._two_nearby_alleys`, `test_day13_guard`'s
  `robbery_edge_of`, `test_events_fire`'s `_another_branch`, `test_interior`'s
  `_walk_distance_to_nearest`, `test_resistance_traps`'s `_is_really_on_screen` and
  `test_route_rig`'s `_find_tile`. Each lost its last call when a suite moved to public seams
  (#925, #953, #988, #1110, #1127, #1256, #1344) or a placement rule became a class (#1256, #1543
  for the siting roll). The two fakes' fields the setters were the only writers of
  (`_fake_besides`, `_fake_calm`, `_fake_doors`) go with them, and each override answers the value the
  field always held (none, no calm areas, no doors).

**Kept.** `PrintedLines._log_message` in `tests/test_scene_recipe_runtime.gd`, which the item listed:
it overrides `Logger._log_message`, which the engine calls for every line printed while the logger
is attached, so the suite reads what a run prints through it. An override is a use.

**Left.** The events' finds in `dead-code-sweep.md` (`EventDef.effect()`, `PendingWarning.left`,
`EventHold.stop()`) stay for the events' interface rows.

## Parity

No behaviour changes (inbox #813 in curly-moose): the diff under `src/` is deletions and comments,
and a deleted test helper had no caller. `./tools/check.sh`, the suites of every file touched,
`./tools/lint.sh`, `check_layers.py`, `check_field_reads.py --base origin/main`,
`check_test_only_members.py --base origin/main` and `tools/cost-table.sh --check` pass.
