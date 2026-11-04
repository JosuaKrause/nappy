# minty-quail — The burst recorder and the frame watch become pieces of their own; the frame record suite boots the game (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the telemetry leftovers. The
burst capture and frame record suites read no private member; the item says what `test_telemetry.gd`
and `test_observers.gd` still want.

**Built.**
- `BurstRecorder` (`src/telemetry/burst_recorder.gd`), the animation burst a person asks for with
  B, leaves the `Telemetry` autoload: `Telemetry` builds it and hands it a `TelemetryScreen`
  (`src/telemetry/telemetry_screen.gd`; the game's is the viewport, which a headless run cannot draw
  from), a clock on the tree's timers and its own `note`, and each `start()` the run's `asked/`
  folder. `start()` and `cancel()` are called by `Telemetry`; whether a burst is running is private to
  the recorder.
- `FrameWatch` (`src/telemetry/frame_watch.gd`), the observer's once-a-second `frame` line and the
  `--spikes` probe, leaves `TelemetryObserver`, which builds it, calls `watch()` every frame and
  `restart()` at a day's start; the lines it writes are unchanged.
- `test_frame_record.gd` boots the real game with `--frame-record` on a sitting and a scratch record
  path of its own, reads the crowd through `excitement.clock()` over real ticks pinned one per frame,
  draws events on real frames and reads the flags off `RunConfig.parse()`. No `src/` change for it.
- The first review also found the crowd's "the clock goes back to what was running" check dropped;
  it is back, matching each tick of a node of the test's own that runs after the crowd to the
  stored frame it fell in and requiring that frame's time in physics outside any timed system to
  cover it, so no slow frame fails it (a first version compared wall-clock times and did).
- Private-read lines: burst_capture 25 to 3 (the one swap of `Telemetry._bursts`, read and put back), frame_record 25 to 0 (hand-called frames 7 to 0),
  telemetry 2 to 1; `GameState` lines 7 to 0, and `test_telemetry.gd`'s five cities built on the
  stand-in without naming it each get a run of their own. Forty-five mutation runs.

**Open to overturn** (checks loosened where the brief was silent): "a played frame is kept" means the
count grows, not by exactly one, since when a frame is stored depends on its length; the crowd's
"one timed call for the whole crowd" means no frame makes as many timed calls as there are agents,
its "the clock goes back" half dropped; the readout check finds the record's line by its `slow`
prefix; the desktop save check confirms the file the sitting keeps, not that the game picks a name
under `user://frame-records/`, which would write the player's real folder; the burst's
finish-reason table became two real runs.

**Left:** `Telemetry._shots` in three tests; three tests that write the player's real
`user://telemetry` folder (before this pass too), both wanting the run folder handed to
`begin_run()` and a screen handed to `Telemetry`; the burst suite's one private write, swapping
`Telemetry._bursts` for a recorder of its own so a day's and the run's end are seen cutting a burst
short (the first review found that reach dropped); and the frame recorder's desktop file name, which
wants the records folder handed to the recorder, since naming it under `user://frame-records/` would
write the player's real folder.
