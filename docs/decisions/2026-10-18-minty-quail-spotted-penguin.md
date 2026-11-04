# minty-quail — The observers and run config suites boot the real game and press through its screens (tests through public seams: W11a) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the observers and run config
suites, subtask W11a of the scoped plan, on the shape record merry-otter set for the suites that boot
the game. No `src/` change; `tests/booted_main.gd` needed no extension.

**Built.**
- `test_observers.gd` (private-read lines 29 to 0, `GameState` lines 23 to 0) boots the real
  `main.tscn` on a fresh `RunState` handed in through `home_playing`, with a scratch save. `main`'s
  `_on_summary_continued` calls become presses on the summary's Continue through the viewport, with
  the tree paused again in the same signal so no physics tick moves the logged times; the day ends on
  the clock's own `day_finished`, the building is left on the interior's `exit_requested`, and the
  title's two answers are its `start_requested` signal with the title skipped (`--no-title`), since
  the city keeps running behind an open title and moved the neighbour the loss line reports. The
  recorded run-log baseline still matches line for line.
- `test_run_config.gd` (14 to 4) reads the shadow layer off the scene's `BuildingShadows` node, the
  forced row by the cyclist the manager's own ticks send at two seconds against the day's own first
  row at eleven or more, and the screens' touch and quit answers on two real boots (`--touch --web`,
  and none as the control) with a click, a finger, Q and Esc pushed through the viewport and the quit
  through `main.use_quit()`. Its city is on a run of its own.
- Checks 22 and 62 to 22 and 80; ten mutation runs. The run config suite takes about seventeen
  seconds, since it boots `main` twice.

**Open to overturn:** the title's answers are emitted on its own signal with the title skipped, not
clicked.

**Not done:** `test_run_config.gd`'s immutability probe writes and reads `RunConfig._open`, `_given`
and `_movie`, which no game class touches; `test_observers.gd` keeps `RecordingCounter`'s override
of the counter's `_send_event()`, since the counter's gate reads the platform, which a headless run
cannot fake.
