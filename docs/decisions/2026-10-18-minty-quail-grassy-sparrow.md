# minty-quail — The event placement, acts and scheduler suites read what the scheduler hands out (tests through public seams: W7a) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the event placement, acts and
scheduler suites, subtask W7a of the scoped plan. No `src/` change and no seam added.

**Built.**
- `test_events_placement.gd` (private-read lines 6 to 0) reads each row's role off the
  `Planned.role` that `EventScheduler.recipe_placement()` returns (the recipe runtime's call), and the
  ground a row is offered, the station fronts' guard included, off `open_ground_for()`. The square
  poster crew is checked to be offered squares alone, to land on squares, and to be refused the
  sidewalk tiles of each seed and day. The alley mouse reads `EventInstance.path`, and skips an alley the
  generator made solid but left in `alley_rects`, as `SealPlanner` does (every game reader of
  `alley_rects` checks the tile is still an alley), checking that alleys still open outnumber such
  stale ones ten to one.
- `test_acts.gd` (6 to 1, `GameState` lines 25 to 0) hands each test a fresh `RunState`, reads the
  city through `City.buildings()` and `CityMap.block_at()`, and a park's reach through
  `EventScheduler.blocked_by()` and the grid's `flood()` and `reaches()`, on days 2 to 14 planned
  with barricade scars on rings of three, five and seven tiles round home, so a day that would seal
  home off from every park has to be opened by the scheduler. Its friction check reads the
  poster crew on days 8 and 14, since it is not on offer on day 1, and its solid-row check asks that
  each narrow row places on at least one day.
- `test_events_scheduler.gd` (4 to 3) reads the alley crossing through what the scheduler places.
- Checks 686, 356 and 18737 to 935, 355 and 18728; eleven mutation runs.

**Open to overturn:** `_role_for` stays on the scheduler, since `recipe_placement()` already hands
the role out: of moving it onto `EventDef`, the sidewalk half is clean, but the cost half needs the
scheduler's `WALL_WORTH_OF_COST` moved, passed in, or read upward.

**Not done:** `test_acts.gd`'s `FireLook._flames_across` and `_facade_runs_at`, which want a reader
of what the look paints; `test_events_scheduler.gd`'s `_plan_through_the_fill`, `_thin_the_walls`
and `_stream`, which plan one stream thinned and unthinned, which no game class asks for (a
`DaySpec` carrying the share of walls kept, planned through `build_day()`, would be a design change
of its own).
