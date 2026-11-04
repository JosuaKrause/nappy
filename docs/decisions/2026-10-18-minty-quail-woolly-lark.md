# minty-quail — The event manager, pelican and police car suites drive public seams (tests through public seams: W2) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the event manager, pelican and
police car suites, subtask W2 of the scoped plan. No `src/` change and no seam added: the reader of
why the day was lost that the plan named already exists, `EventManager.what_struck_her()`, which
`DayDirector.finish_day()` calls.

**Built.**
- `test_event_manager.gd` (private-read lines 18 to 3, hand-called frames 4 to 0, `GameState`
  lines 18 to 0) builds each test's city on a fresh `RunState` and lets the manager's real ticks
  (`PhysicsTicks`) run retirement, successors and warnings; a `Walker` node moves her along the route
  on its own tick at six times real time. It reaches the rest through `leave_for_a_completed_task()`,
  `WalkSiting.cell_centre()`, `EventStreaming.add()`, `WarningBoard.clear()` and an event's public
  `step()`. It now passes reversed.
- `test_pelican.gd` (20 to 1, `GameState` 31 to 0) runs a quiet day from `start_recipe()` on a run of
  its own, lets the manager's tick end it, and reads the loss through `what_struck_her()` and
  `LossCause.hard_fail_suffix()` into the observer's `day_finished()`. Its check that the visit
  counter listens to all four sightings goes, since `test_visit_counter.gd` holds it.
- `test_police_car.gd` (16 to 0) reads the car's facing through `facing_now()`, finds its body by
  type, turns it at a route's corner, ends a leaving car's route short of her, and raises the mark
  with `Stroller.warn()` on a city in its own run.
- Checks 1608, 54 and 129 to 1636, 53 and 131; ten mutation runs. The event manager suite takes
  about twice as long, since its walks take real ticks.

**Open to overturn:** the `Walker` moves a bare `Stroller` on its own tick rather than through
input, since steering a real stroller round corners would change what the siting tests measure; the
check that the engine's badge is up alone at most a second allows one tick of slack, since only the
warning's tick adds to how long it has shown.

**Not done:** `EventsAhead._warn_down_her_line()` and `_send_down_her_line()`, called by nothing
but the director itself (they want the director to owe the cyclist or the dog, and real frames to
run `place_what_is_owed_ahead()`); `EventInstance._notice_damping()`, which no game class reads.
