# minty-quail — The test runner lets frames pass and resets globals between suites · 2026-10-19


minty-quail's first item (`test-runner.md`), the first PR of the refactor's order (PR #806). The
item read the player's report of Godot crashing under the agents' test runs (minty-lemur #792) as
the runner's doing: `tests/run_tests.gd` ran every suite inside one synchronous `_ready()`, so the
engine's message queue and delete queue never drained until the shard ended, and every global a
suite set carried into the next.

**The crash did not reproduce.** On `main` before the change, one `tools/test.sh` call with thirteen
suites (resistance, full_run, crowd, routes_closures, seals, events_scheduler, spent_park, generator,
fallen_trees, balance and their substring matches) ran 997 s, 283919 checks, 0 failures, with no
"Message queue out of memory" line and no "Object was deleted while awaiting a callback." line. The
same call after the change: 990 s, 283958 checks, 0 failures, both counts 0. So the change removes
the mechanism the reviewer of PR #781 suspected, but nothing measured shows it was that crash's
cause.

**Built.** The runner awaits each suite's `run(t)` — a plain function or a coroutine, so a suite may
now `await` real frames — lets a physics frame pass before the first suite, and a process frame and
a physics frame after each one. Before each suite, one runner function puts the globals back:
`GameState.start_run` on a fixed seed, and the static test seams the suites set by hand
(`DevFlags._invincible_override` and `args_for_tests`, `GameSave._path_override` and
`_uses_save_override`, `SaveIndicator._home_override`, `FrameRecord.on` and `ledger`,
`ControlsMode._remembered`, `_remembered_mode` and `_remembered_side`,
`TitleScreen._restarted_at_msec`) cleared; `Telemetry`, `VisitCounter` and the `EventBus`
connections are left alone, and its comment says so.

**What the reset exposed.** Suites that stepped a stroller's `_physics_process` by hand and then
moved her themselves (`test_interior`, both end-to-end walks in `test_route_rig`, the stairwell-guard
probe) counted on `move_and_slide()` seeing a zero delta because no physics frame had ever run; once
frames pass she moved twice. They share one helper now, `StrollerSteer.velocity_step` in
`tests/stroller_steer.gd`, which puts her body back after the step. `test_dev_rig`, `test_route_bag`,
`test_route_rig` and `test_day6_yeller_met` passed only on some run seeds; each starts its own run on
the seed it needs, and the runner's fixed seed is for determinism only, its comment saying no suite
may rely on it.

**A suite that quits the tree ended its shard silently.** `RouteRig` quits the tree when its route
finishes, and `test_route_rig` drives a real one. While every suite ran inside one `_ready()` that
quit waited until the runner's own; with frames passing it took effect after `test_route_rig`, and
the shard ended with exit 0 and the rest of its suites unrun — a full run first reported 1021087
checks, and 1295254 once the shard ran to its end. `RouteRig`'s quit is now one overridable method
(the PR's one change in `src/`), which a test stand-in, `RouteRigNoQuit`, turns off. `tools/test.sh`
fails any run whose output holds a `QUIT` line, or has no closing "N checks, M failures" line after
its last suite's timing line, and says whether the shard timed out or the tree was quit; the
runner's `_exit_tree` prints that `QUIT` line, naming the suite that was running when the tree went
away before the runner's own quit. The fixture
`tests/runner_fixtures/quits_the_tree.gd` proves it, run by CI the way `engine_error.gd` proves the
error scan. The runner cannot refuse a quit, since `SceneTree` offers no way to cancel one.

**Left open to overturn.** The runner's reset seed is 2. The overridable `RouteRig._quit()`. The
suites' own hand resets stay (45 assignments of an override seam, 16 of the other statics), and 69
`process_frame.emit()` calls still fake frames; the `tests-public-seams` item takes them out as each
owner is extracted.

**Measured beside it.** On a machine at a load average of about 6, a shard ran 500-600 s, and at the
default 600 s shard timeout all four were killed; the green runs used `TEST_SHARD_TIMEOUT_S=1500`.
That is the margin M125, "the test suite is slow again", is about.
