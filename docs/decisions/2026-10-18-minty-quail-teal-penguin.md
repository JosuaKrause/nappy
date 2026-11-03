# minty-quail — The telemetry and GoatCounter suites drive what the game hands in (tests through public seams) · 2026-11-02

minty-quail's `tests-public-seams.md`: the telemetry and GoatCounter suites. The item stays open for
the reads below, `test_observers.gd` and the other suites the item lists.

**Built.**
- `VisitCounter` gains two public members, each something its own `_ready()` hands in: `listen(bus)`
  with `EventBus`, and `send_through(outbox)` with a `GoatCounterOutbox` built on the page's script
  evaluator. Everything a first pass made public for the tests went private again after the first
  review, since a member only a test reads is not a seam (records -44 and -47).
- Three types moved out of the autoloads' statics, each used by the game: `GoatCounterOutbox` (the
  script gate, the queue of events asked for before `count.js` loads, the script line),
  `TelemetryShots` (the day's shot allowance, the spacing, the run-wide picture counter) and
  `TelemetryPage` (whether a page's query is read and asks for the log). An autoload cannot be
  built twice, so a pure static on it was either opened to tests or moved into a type.
- The observer's polls run on real `process_frame`s with the day moved by `DayController.tick()`,
  as `main` moves it; the frame ledger and trace buffer are read through their rows. The caught and
  cut-short charges finish on their own clock rather than through `EventInstance._be_done()`.
- Private-read lines: visit_counter 197 to 1, telemetry 76 to 2 (hand-driven frames 2 to 0),
  frame_record 49 to 25, frame_trace 1 to 0; observers unchanged at 29. Every check kept or replaced
  by one that fails under the same mutation; three checks the redo had stopped proving (the
  off-the-web refusal, the picture counter across a day and a retry, the runner seeing a part's
  fields) were proven again by the reviewer's own mutations.
- The runner's shared-state check (`tests/shared_state.gd`) also compares the script variables of
  each `RefCounted` an autoload holds, one level deep. It found 17 GameState run fields that suites
  change and the runner's own `GameState.start_run()` puts back; each is listed in `EXEMPT` by name
  with that reason. The verify skill's "A suite leaves nothing changed" says so.

**Open to overturn:** the 17 run fields exempted by name rather than restored by each suite, or
by a rule keyed on GameState; a future suite that moves another such field adds it the same way.

**Left, with the route each needs:** the day-adjusted dog row (`EventScheduler._for_day`) wants a
planned placement with a city map; the recording counter's `_send_event()` override wants a gate
handed the platform; `Telemetry._shots` wants a screen handed to `Telemetry`; the observer's
`_watch_the_frame()` wants a source of frame lengths; `test_frame_record.gd` wants seams on `main`
and real crowd, event and excitement frames.
