## M107 — The run clock · built 2026-09-11

*(2026-09-10: "can you add an in-game timer that counts up during gameplay (and stops when paused
or between days). for now let's keep it hidden and only show it on the win screen"; then "all
endings show the game timer -- with millisecond precision".)* Three agent commits on
`feature/run-clock`, reviewed here. **One number per run, one owner.** `GameState.play_seconds`
is zeroed in `start_run()` and advanced only by `main.gd`'s `_process`, while the day's phase is
walking or returning and the tree is not paused — the summary is already excluded because the day
controller sets the phase to over before it opens, and the pause screen is what the pause check
catches; the title screen and the interior never reach the block. So a retried day's first
attempt counts and a minute on the summary does not. **Shown on every ending and nowhere else**:
`DaySummary.show_ending()` appends one line under the body for bad, neutral and good alike,
formatted `%d:%02d.%03d` by `GameState.format_clock()`, a static formatter placed there so M102's
finale clock reaches the same one. The run's total goes into the existing `ending` telemetry
entry rather than a new kind. **Chosen where the design was silent**: `main` reads the pause
state through `Engine.get_main_loop()` rather than `get_tree()`, because the main suite drives
`main._process()` on an instance never added to the tree, where `get_tree()` logs an error and
answers null — the main loop is the one scene tree either way. The test drives a walking, a
paused, a summary and a title frame with a fixed delta and asserts only the walking frames move
it; one capture of the good ending shows the line rendered under the body.
