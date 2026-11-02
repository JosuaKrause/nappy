# Tests drive public seams and real frames

Tests reach private members and drive frames by hand. Count a suite's lines that read a private member,
including one named in a string, with
`rg -c '^[^#]*(\.\_[a-z][a-zA-Z0-9_]*|\.(call|callv|set|get|call_deferred)\("_)' tests/test_*.gd`, and its
lines that call a frame function or emit the frame signal by hand with
`rg -c '^[^#]*(\._(physics_)?process\(|\._(unhandled_)?input\(|process_frame\.emit)' tests/test_*.gd`;
both skip comment lines and neither sees access through a variable holding the name. Many suites instantiate `main`;
`test_home_block.gd` (near 249) copies `City._height_for`'s random stream; `test_camera_start.gd` depends
on `main._ready()` holding exactly two awaits. `SceneRecipeRuntime`
rebuilds placement from other classes' private functions (`SealPlanner._eligible`, `_place`,
`_seal_along_tile`, `_mark_soft_sealed`; `EventScheduler._build_placement`, `_room_around`,
`_street_ground`; `RegionPlanner._add_door_bodies`; `instance._advance_gait`), so authored scenes drift from the game. `SceneRecipeRuntime.walk_spec` is a
public field only tests read, and two checks compare it with the value just assigned; no test
reaches the crowd's or `ResistanceDirector`'s fallback to the map's navigator, or `main` handing
`SceneRecipeRuntime.install()` the spec its clock runs on.

**Build:** as each owner is extracted (the items above), it gets public seams and injected
dependencies, and the tests that reached into it move to the seams, with fakes injected instead of
statics patched; since the test runner lets frames pass, scene-level tests step real frames. Planners
get public "place this at this site" entry points that the scheduler and recipes both call. It is
one pass after the last refactor item, "once the refactor is done let's rewrite the tests with
dependency injection and through public APIs", and a step may convert the tests it touches early,
"you can also do it as a bit with each step as long as the final result is the same" (inbox #813 in curly-moose).

**Where it stands:** the suites still to convert are the ones the first command above counts above zero. The resistance suites share `tests/resistance_rig.gd` (which the `tests/test_*.gd` of the commands does not match and is counted by naming it) and drive `ResistanceDirector`'s public seams (`contact()`, `read_mark()`, `rider()`, `use_steps()`, `guard_spot()`, `draw_reachable()`, `touch_reach()`, `pursuer_walker()`, `door_position()`, `door_axis()`, `trap()`) and `CheckpointController.guard_is_after_her()`; the rig, `test_resistance_steps.gd`, `test_resistance_traps.gd`, `test_resistance_reach_contacts.gd` and `test_resistance_crossing.gd` are converted, each test building its own city in a run of its own, with no test leaning on what an earlier one left behind. Still to do there: the other seven resistance suites, `test_resistance_reach_marks.gd` among them though the first command counts it zero (it writes `GameState` in `_with_clean_run()`), after which the rig's `_build_city()` and `_with_clean_run()` go (`arrow` needs seams for the arrow's insides, `placement_kinds` and `replacement` for the happenings' and `City`'s, `alley_siting` for the guard-placement draws); `tests/test_checkpoints.gd` still reads and writes `CheckpointController._guard_after_her` (the reads `guard_after_her()` answers, the writes in `_guard_after_her_rig()` nothing yet), and the probe `tests/probes/trap_arrival_fingerprint.gd` reads and clears `director._trap` (the read `trap()` answers); the rig's last private read, `_edge_of_her_circle()` reading `director._reach_blocked`, which moves with `reach_narrow` and `reach_relocated`; a public step on `Baby` for `traps`' `_walk_the_trap()`; and a public form of `EventScheduler._room_around()`, which `reach_contacts` and `SceneRecipeRuntime` call. `test_save_wiring.gd` boots a real `main` and reads no private member; a test hands in the home the game parks its `Sitting` in across a reload, and reads it back out of that home. The save tests reach `GameSave` through `write()`, `try_resume()` and `clear()`.
