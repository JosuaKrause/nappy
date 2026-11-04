# minty-quail — The small suites and the shared helpers use runs of their own (run state handed in: G5) · 2026-11-04

minty-quail's `run-state-handed-in.md`: `tests/test_escape_invisible_wall.gd`,
`test_player_presentation.gd`, `test_move_poses.gd`, `test_scene_recipe_boot.gd`,
`test_held_restart.gd`, `test_orientation.gd`, the comment-only mentions in four resistance and HUD
suites and `tests/resistance_rig.gd`, and the helper `tests/building_events.gd`. Tests only.

**Built.** The suites that boot `main` boot it through `tests/seat.gd`, so each boot plays a run of
its own on a scratch-path save, and their snapshots, restores and resets of the escape section are
gone; the held restart suite hands each pause screen and summary a run held as the screen's child.
`BuildingEvents.events_in()` no longer falls back on the global run: its callers pass theirs. Every
check is kept.

**Not done:** `RunCity.of_the_run()` still hands a city the global run, and suites and probes across
the tree call it, so `rg GameState` does not count them; each moves to `in_run()` or
`with_own_run()`, and the last wave drops the function. The two fingerprint probes pass the global
run to `events_in()` explicitly.
