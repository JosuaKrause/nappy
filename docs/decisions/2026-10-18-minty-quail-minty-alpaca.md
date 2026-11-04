# minty-quail — The walk siting, seals and scene recipe task and activity suites drive public seams (tests through public seams: W7c) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the scheduler leftovers, subtask
W7c of the scoped plan. Tests only.

**Built.**
- `test_walk_siting_spec.gd` (private-read lines 6 to 0, `GameState` lines 5 to 0) builds a city in
  a run of its own and asks the siting through `WalkSiting.near_her()` and
  `EventManager.queue_a_task_row()`; its day-spec half clears the day's holds on the home block's
  streets through `CityMap.clear_day_holds()`, so the rule alone decides.
- `test_seals.gd` (1 to 0) states the junction rule as the flood fill `test_events_placement.gd`
  uses, asked once per route junction a catalogue row reaches rather than once per row.
- `test_scene_recipe_task.gd` (3 to 0) refuses a mast beside a door through
  `SceneRecipeRuntime.install()`.
- `test_scene_recipe_activity.gd` (7 to 0) loads its recipe as `main` does, reads the booted tree,
  and checks that the baby falling asleep leaves what the director owes ahead unchanged.
- Checks 9, 53905, 96 and 6 to 9, 52901, 96 and 6.

**Open to overturn:** the seals suite's flood fill copies the one in `test_events_placement.gd`, and
could be a helper both share; one check of the walk siting suite still reads `events_ahead.gd` as
text.

**Not done:** `SceneRecipeRuntime._mast_placement()`'s own clause keeping a mast clear of the doors
has no reachable case, since `MastSites.is_eligible()` refuses the same ground first, so it wants
removing; dropping `standing` from the scheduler's reach context is caught by no seals check, a gap
that predates this; the activity probe reads the private enum `Building._Furniture`.
