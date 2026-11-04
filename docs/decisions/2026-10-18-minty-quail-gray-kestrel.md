# minty-quail — The world passability, regions and blocks suites read what the game already asks (tests through public seams: W9b) · 2026-11-03

minty-quail's `tests-public-seams.md`: the world passability, regions and blocks suites, subtask W9b
of the scoped plan. No `src/` change and no seam added; the three suites already built each city on
a run of its own.

**Built.**
- `test_world_passability.gd` (private-read lines 8 to 0) reads the cat crossing through the
  director's `force()`, `start_day()` and `due()`, the call `EventsAhead` makes each tick; the
  scheduler's crossing path through `EventScheduler.place_at()`, which `SceneRecipeRuntime` uses; a
  car's mover through `EventInstance.mover_for()`; and a departure begun with `give_up_the_chase()`
  and read with `facing_now()`. Its navigator check no longer reads the crowd's or the director's
  navigators: a director handed only the map runs on a yard with a body across the cat's run. Each
  real-city test builds its own city.
- `test_regions.gd` (3 to 0) reads the streets an alley opens onto through
  `StreetNetwork.segment_containing()`, and checks that an alley is on the day's lists exactly when
  its two streets' grounds differ, which the old suite never checked; its wall-body reads use
  `plan.wall_bodies` instead of the planner's private wall row.
- `test_blocks.gd` (2 to 1) reads a street's kind through `CityMap.street_kind_at()`.
- Checks 66, 178783 and 24944 to 70, 179083 and 24944; nine mutation runs.

**Open to overturn:** `give_up_the_chase()`, written for pursuers, begins the departure of rows that
are not; on those it differs from finishing them only by setting `gave_up`. The ordinary-street
count in `test_blocks.gd` has no mutation run, since mutating `street_kind_at()` stalled the run;
its evidence is that it matched the private reader on 2112 segments. `test_regions.gd` reversed runs
fewer checks, since a few depend on what an earlier test repaints.

**Not done:** `test_blocks.gd`'s bed count reads `CityDecals._street_tree_pits`, since the beds live
only in the decal layer's draw; it wants a reader of what a `SceneryLayer` holds that a game class
calls. `EventScheduler._cross_street_path` serves no catalogue row today, since the director sites
the cat: it wants a row, or removing.
