# minty-quail — The save, run, telemetry and screen suites lose checks that hold nothing · 2026-11-05

minty-quail's `tests-hold-nothing.md`, the audit's findings in 21 suites no other build owned: the
save, run, telemetry, screen, touch, stroller and resistance-step suites. The player's rule is that
a check whose setup only a test can make, that reads a design decision back, that cannot fail, or
that repeats another, is removed (curly-rabbit #1097); the pause screen's wording checks go and the
checks that a hint is or is not shown stay (curly-rabbit #1100); the visit counter's table of the
chargers' GoatCounter names stays (curly-rabbit #1102). Nothing under `src/` changed.

**Removed.** Whole tests: the escape clock to the hundredth (`test_day_controller`), the `--nerves`
parsing test (`test_run_checkpoints`), `is_double_tap` and the rig-word test (`test_touch`), the
apply test (`test_web_display`), the standing line (`test_summary_model`), the day-under-way load
cost, the refused-save-dark test and the desktop-save-shown test (`test_save`), and the baby's
setter and getter (`test_baby_world`). Single checks: the "seven parts" count (`test_run_state`),
the second-load nerve check and `day == 8 and nerves == 4` (`test_save`), the duplicate "already
answered" check (`test_save_wiring`), the third "a car is still a car" (`test_loss_cause`), five
`>= 0` counter checks (`test_performance`), the pram-mirror duplicate and the north-diagonal
formula (`test_stroller`, which keeps its continuity check), the 16 px dead-zone pin and its
restated line (`test_touch`), the convoy day read back to itself
(`test_resistance_placement_kinds`), the player-presentation tautology, and a `t.check(true, ...)`
in `test_telemetry`. On the pause and title screens, the wording, version and setting checks, two
touch-away duplicates and the run button's tap-scheme literal went; every check that a hint is
empty or shown stays.

**Tightened.** The burst frame cap compares with `BurstRecorder.MAX_FRAMES`; the frame graph's
"class fixed at push" test, which could not fail, became "classes age out with their frames" past
the window; the write-announces test in `test_save` took over the plain-picture check from the
removed desktop-save test; the pause run-button test checks the line is read again on a second
open.

**Kept, each finding weighed and not holding.** `test_touch.gd`'s pause catch `>= 46` pins a bug
that shipped. The round-button margins test is the only home of the pause press half and the
rotated variant. The "touch near her position" test is not a duplicate: the other puts her at
5000,5000. The save's stray-answer test is the only one covering a second answer to a save already
settled. The stroller's live-draw selection test can fail on a wrong lookup. The summary model's
wording checks compose day, nerves and tally from different run states. `test_resistance_steps`'s
"still says where to take it" is half of day 8's contract, and its chalk mark region check is
covered nowhere else. The third floor in the placement test is the player's own (PLAYTEST-131).
`test_visit_counter` is untouched by the player's ruling. The day loop's findings were already gone.

**Open to overturn, the builder's choices.** The pause and title screens' negatives ("no key is
named", no "that way") were read as the player's rule rather than wording and kept; the frame graph
test was tightened rather than deleted; the title hint is checked as shown, not for its text.
