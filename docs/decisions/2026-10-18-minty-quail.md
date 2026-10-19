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
now `await` real frames — and lets a process frame and a physics frame pass after each suite. Before
each suite, one runner function puts the globals back: `GameState.start_run` on a fixed seed, and
the static test seams (`DevFlags._invincible_override`, `GameSave._path_override`,
`GameSave._uses_save_override`, `SaveIndicator._home_override`) cleared. Nothing in `src/` changed.

**What the reset exposed.** `test_interior` and the stairwell-guard probe stepped a rig's
`_physics_process` by hand and moved her themselves, which counted on `move_and_slide()` seeing a
zero delta because no physics frame had ever run; once frames pass she moved twice, and both now put
her body back after the step. `test_dev_rig` and `test_route_bag` passed only on some run seeds (they
fail on seed 1) and `test_day6_yeller_met` failed on a random one; each now starts its own run on the
seed it needs. The runner's fixed seed is for determinism only, and its comment says no suite may
rely on it. The three pass with it at 1, 2 and 7.

**Left open to overturn.** The runner's reset seed is 2. The suites' own hand resets of the static
seams stay (49 assignments), and 69 `process_frame.emit()` calls still fake frames; the
`tests-public-seams` item takes both out as each owner is extracted.

**Measured beside it.** The unfiltered `./tools/test.sh` passed (1021087 checks) only with
`TEST_SHARD_TIMEOUT_S=1500`: at the default 600 s all four shards were killed on a machine at a load
average of about 6, where a shard ran 500-600 s. That is the margin M125, "the test suite is slow
again", is about.
