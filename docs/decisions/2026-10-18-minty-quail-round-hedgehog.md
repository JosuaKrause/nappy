# minty-quail — The spent park and park cordon suites read the park's public geometry (tests through public seams: W9a) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the spent park and park cordon
suites, subtask W9a of the scoped plan. No `src/` change and no seam added. `test_barrier_stays.gd`
is untouched: its ten reads are all in `src/events/` (`RoadblockLook._band`,
`EventInstance._obstruction` and `_rim`).

**Built.**
- `test_spent_park.gd` (private-read lines 10 to 4, `GameState` lines 6 to 0) reads the fence through
  `CityMap.closed_tiles`, its end points through the run's public `from_along`, `to_along` and
  `outward` and `mouth_centres()`, and walks a rectangle's edge itself instead of `_edge_tile`.
- `test_park_cordon.gd` (6 to 5) builds a fresh `RunState` and city for each test, where one city
  served all thirteen, and tests a body on the stretch against its public ends `a` and `b`.
- `test_park_cordon_seeds.gd` (5 to 3) uses the map it already holds and the same stretch test.
- Checks unchanged; five mutation runs, and an open-end check that read `rail_ends()` on both sides,
  so could not fail, was rewritten from the public fields before the PR.

**Open to overturn:** the stretch test is a local distance test against `a` and `b`, a copy of what
`ParkCordon._body_on` does.

**Not done, with the seam each wants:**
- `ResistanceDirector._happenings` (two reads): no game class asks for it, since `main` ticks the
  director. Of the three ways weighed (an accessor only tests read, which the Build line rules out;
  ticking the cordon suites through `director.tick()` with a real `Stroller` and reading the cordon
  off what the game registers; handing the cordon's owner in), the builder would pick the second,
  as a task of its own, since it rewrites more than twenty-five tick sites.
- `_reach_blocked` (two): its public `reach_obstruction()` is read by no game class; it wants the
  obstruction handed to `ParkCordon`.
- `ParkCordon._exit`, `_leaving` and `_still_to_come_out()`: no game reader, and the last shows
  nothing a test can observe in these scenarios (a mutation of it fails nothing, with or without a
  behavioural stand-in), so its direct read stays rather than a check that cannot fail.
- `City._closure_nodes` and `_spawn_closure()`: they want a reader of the day's closure pictures or a
  closure handed in through `recipe_closures`.
