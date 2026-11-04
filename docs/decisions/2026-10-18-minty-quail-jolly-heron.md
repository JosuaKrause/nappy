# minty-quail — The behaviours, patrol vanish and barrier suites stream plans in and read a barrier's look (tests through public seams: W7b) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the event behaviours, patrol
vanish, barrier and solid suites, subtask W7b of the scoped plan. No `src/` change and no seam added.

**Built.**
- `test_patrol_vanish.gd` (private-read lines 3 to 0, the stand-in through `RunCity.of_the_run` 1
  to 0) puts the manager in the tree before a real stroller and lets its own physics ticks run, one
  a frame through `PhysicsTicks` at four times real time, counting its stretches in ticks; plans come
  in through `EventStreaming.add()`, and the officer a heated patrol lets out is followed by flags set
  while he is alive, since he is freed at the frame's end. The test no longer marks the day as a
  recipe's, so the city's own director runs beside the patrols, as in a real day; it sites nothing
  in these scenes.
- `test_event_behaviours.gd` (1 to 0) streams its plan in through `EventStreaming.add()`.
- `test_barrier_stays.gd` (10 to 0) reads the band through its look's `band_node()`, the barrier's
  body as the `StaticBody2D` under the instance, its rim through the excitement's `rim` and the band's
  through `band_rim_holder()`, and its fading through `is_faded_out()`. Its first check, that the band
  is drawn at its body on every frame, could not fail, since the test had turned off the frame that
  moves the band: it now lets a real frame pass after each step, and fails when the band follows the
  man instead of the body.
- Checks unchanged (21, 69 and 44); eight mutation runs.

**Not done:** `test_events_solid.gd`'s `EventScheduler._route_sidewalks()`, which only the
scheduler's own guard calls; it wants the walked sidewalk bands handed through something another game
class asks, such as `WalkGround`.
