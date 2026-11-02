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

**Where it stands:** the suites still to convert are the ones the first command above counts above zero; the largest are the `tests/test_resistance_*.gd` suites (with the helper they share, `tests/resistance_rig.gd`, which the `tests/test_*.gd` of the commands does not match and is counted by naming it) and `test_save_wiring.gd`. `test_save_wiring.gd` holds the 16 save checks that build a script-only `main` and reach its members. Nothing is missing from `main` for them: the `test_main` slice reached the title, the resume gate and the continue button by booting a real `main` and driving it with real input and real frames, and added only `Main.use_reload()` and `Main.use_quit()`. Converting this file is part of this item's remaining work, done the same way (a booted `main`, its input, `Main.use_reload()` for the day-14 reload, the save symbol found as the booted `main`'s child), and no slice has it yet. `test_finale.gd` and `test_move_poses.gd` boot a real `main` under a debug flag (`--invincible`, `--no-save`) and set `GameSave._uses_save_override`, since the debug policy keeps a flagged run off the save; `test_park_return.gd` and `test_move_poses.gd` still call `GameSave`'s private `_write_now()` to lay down a save to boot from, `test_run_state.gd` its private `_read_now()`, and those two, `test_run_state.gd` and `test_finale.gd` its private `_clear_now()`. `SaveIndicator._home_override`, set only by tests through `SaveIndicator.use_home()`, is process-wide static state left for the hidden-statics work: the symbol's home cannot be handed in while `SaveIndicator.carried()` is static.

**The resistance rewrite removes three carried dependences on test order.** The resistance suites, split by subject, still lean on what an earlier test left behind, and the rewrite through public seams removes each rather than keeping it: `test_resistance_steps.gd` builds the default city before its finished-task tests, which take the one standing; `test_resistance_reach_contacts.gd` builds the seed-1234567 city before the test that reads the city the day-11 mast test last built; `test_resistance_traps.gd` sets six hard-coded alley tiles (`RunFacts.completed_resistance_alley_tiles`) on entry, which a trap test's counts were written against. The player folded the split into this item (tiny-lark #930, #931).
