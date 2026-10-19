# The test runner lets frames pass and resets globals between suites

`tests/run_tests.gd` (about lines 39-72) runs every suite inside one synchronous `_ready()` and quits;
control never returns to the main loop until the shard ends. Godot drains its message queue
(deferred calls, `queue_redraw`, `set_deferred`, Control layout) and its delete queue (`queue_free`)
only between frames, so both grow for the whole run. That is the likely cause of the crash the
player reported, "your agent keeps crashing godot]" (minty-lemur #792): one call running eleven
suites died in `test_resistance` about 8 minutes in with "Message queue out of memory" and about 1.38
million "Object was deleted while awaiting a callback." lines, while every suite passes alone.
Separately: suites cannot `await` (one that did would return early), 65 sites fake frames with
`process_frame.emit()` (which resumes a coroutine but runs no `_process` and drains nothing), and
autoload state and the 58 `static var`s in `src/` carry over between suites, patched by hand in 43
places (`_invincible_override`, `_path_override`, `_uses_save_override`, `_home_override`).

**Build:** `_ready` becomes a coroutine that awaits `suite.run(self)` and then
`get_tree().process_frame` and `physics_frame` after each suite; a runner-owned reset between suites
(`GameState.start_run()`, the static override hooks cleared). Confirm the crash first: the same
multi-suite call on `main` before and after.
