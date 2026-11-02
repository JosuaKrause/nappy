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

**Where it stands:** the suites still to convert are the ones the first command above counts above zero; the largest are `test_resistance.gd` and `test_main.gd`. The save suite's checks that build a script-only `main` are in `tests/test_save_wiring.gd` and wait for `main`'s seams for the title, the resume gate and the reload, which the `test_main` slice gives it. `test_finale.gd`, `test_park_return.gd` and `test_move_poses.gd` boot a real `main` and set `GameSave._uses_save_override`; `test_run_state.gd`, `test_park_return.gd`, `test_finale.gd` and `test_move_poses.gd` still call `GameSave`'s private `_write_now()`, `_read_now()` and `_clear_now()`.

**The slice that rewrites `test_resistance.gd` also splits it by subject.** The file is the floor of the
test suite's run time on CI: every test function stays called once and the check total unchanged, so the
split costs the suite nothing it checks. The player: "yes, fold into the test refactor"
([tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #931), answering whether splitting the resistance
tests, left over from M125 (the test suite is slow again), is part of the refactor; "isn't that part of
the refactor?" ([tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #930). Splitting the file is no separate entry.
