# minty-quail — The dev capture suites read the tools through what they take and do (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the dev capture suites (the
debug readout and layers, the auto screenshot rig, the still watch, burst capture, the run config).
Four are converted; the item says what the other two still read.

**Built.**
- No public member added. `StillWatch` counts its hold in `_physics_process()` rather than
  `_process()`, so a hold is a whole number of fixed-length ticks a test can count.
- `test_debug_layers.gd` (private-read lines 53 to 0) sets the readout up through
  `RunConfig.parse()`, pushes keys 1 to 7 through the viewport, finds the `DebugLayers` node by name
  and counts redraws over real frames. `test_auto_screenshot.gd` (39 to 0) builds the rig with
  `AutoScreenshot.from_config()` from the walk and flee words, on a clock it hands in, and reads what
  is pressed on `Input`. `test_rig_press.gd` (2 to 0) takes its taps from the real rig on real
  frames. `test_still_watch.gd` (33 to 0) counts ticks around the hold. `test_burst_capture.gd` (31 to
  25) converts its key test; `test_run_config.gd` (15 to 14, `GameState` 2 to 0) plays a run of its own
  in a booted `main` and lets real frames move the crowd, with a control that they do.
- Every check kept or replaced by one that fails under a mutation of what it guards; two guards
  found redundant (the second decimal point, which `is_valid_float()` refuses anyway, and the key
  echo, which `is_action_pressed()` refuses), as they were under the old tests.

**Open to overturn:** the still watch suite running at 600 physics ticks a second for its stretch,
restored after, and reading a window of ticks around the 30-tick hold rather than the exact tick.

**Left:** burst capture wants its recorder taken out of the `Telemetry` autoload and handed its
frame source, clock and directory, part of that autoload's own conversion; the run config's
immutability probe writes `RunConfig`'s private state on purpose; `DebugLayers.body_outline_count()`
is read now only by `test_interior.gd`.
