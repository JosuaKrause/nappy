# minty-quail — The checkpoint and save-wiring suites boot the real game, and the finale boots its escapes (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the checkpoint, finale and
save-wiring suites. The first and last are converted; the item lists what the finale still reads.

**Built.**
- No new public member and no seam; one stale docstring in `src/ui/title_screen.gd`.
- `test_save_wiring.gd` waits for its boot with `Boot.until_booted()`, uses `tests/booted_main.gd`'s
  finders and presses, plays a fresh `RunState` per test, and reads what is on disk into a run of
  its own: its old reads into `GameState` were overwriting the run `main` played.
- `test_run_checkpoints.gd` boots the real `main` for every check about it, answers the title
  through the viewport with its platform handed in (`use_platform()`), wins days through the day's
  end signal and the summary's Continue, loses hard runs through `EventBus.hard_fail_triggered`, and
  photographs a changed run through `RunStateRegistry.photograph()` rather than writing dawn fields.
- `test_finale.gd` boots every escape through one helper on a run of the test's own; the pause
  test's touch check became behaviour (a heading held, let go while paused, given back only by the
  same controls).
- `tests/booted_main.gd` gains `home_playing(t, run)`, and freeing a boot gives the observers back
  what they held before it, since `VisitCounter` otherwise kept a run the test had freed.
- Private-read lines: run_checkpoints 105 to 0, finale 175 to 34; hand-driven frames 19 to 0 and 18
  to 4; `GameState` lines 50, 176 and 67 to 0. Every check kept; the finale gains three (each
  booted escape freed through a check that its keys are still bound). Twenty-four mutation runs;
  one found the route rig's building test true by luck (the building walker's press landed on the
  city brief), fixed so it fails.

**Found:** a real `Esc` over an open pause reaches the pause screen first and closes it, so
`main`'s refusal to open a second pause there is not reachable by a key; the check reads "Esc over
the open pause closes it, and no second pause opens". The route rig's building test said nothing
presses the building's brief, which `BuildingWalker` does; it says the walker pressed it.

**Open to overturn** (the builder's choices where the brief was silent): the observer give-back
after each boot; the held-restart test letting its boot build its own sitting, which the runner
hands the stand-in, since parking that sitting is what it checks; tests emitting the signals the
game fires (`day_finished`, the pause and summary restart and quit signals, `hard_fail_triggered`);
`DayController.tick(0.0)` called to put her through the city exit in two tests, since over real
frames her body is moved off the exit tile before the clock looks.
