# minty-quail — The region doors' suites are typed: checkpoints and regions · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The region doors' two suites are typed and lose their opt-out line**: `test_checkpoints` and
  `test_regions`. Loop variables are typed, dictionaries whose keys and values are known are typed
  (a copy goes through `assign()`, since `duplicate()` hands back an untyped dictionary), and the
  two interpolation spies swapped onto her and the camera are named by preloaded constants. One
  dictionary stays untyped on purpose: it mixes segment keys and alley positions. No line under
  `src/` changed and no rig was edited.
- **One read converted**: `test_regions`' determinism check read the map's `region_of_junction`
  array whole; it now asks `RegionPlanner.region_of_junction()` for every junction, as the game's
  planner does.

## Left, each with its reason

The search covered `CheckpointController`, `RegionPlanner`, its `RegionPlan` and the plan's inner
`GateState`.

- **`CheckpointController`**: the suites read no field of it, only methods, a signal and constants.
- **`RegionPlan`'s `walls`, `doors`, `alley_walls`, `alley_doors`, `wall_bodies`, `door_bodies` and
  `gates`, and `GateState`'s `raised` and `position`**: no method answers them, and the game reads
  the same fields (`region_plan().gates` in the day director and the scene recipes).
- **The map's `boundary_wall_at_a`**: no method; the region planner reads it itself.
- **Other modules' fields stay for their passes.** The pull request's description lists them by
  class, inner classes included (the plan record, a street segment, a calm area, a route branch),
  each with the method the game calls where one exists and each method's body checked to return
  that field: among them the row's `obstructs_within()`, `peak()`, `heard_within()`,
  `telegraphs_for()`, `detains_for()`, `ends_the_day()`, `counts_as_one_barrier()` and
  `ground_shape()`; the live event's `row()`, `is_gone()`, `is_on_its_way_out()`, `has_given_up()`
  and `source()`; the plan record's `row()`, `placed_at()`, `walks()` and `instance()`; a ground
  shape's `is_segment()`; the map's `city_seed()`, `plans_by_block()`, `street_network()`,
  `main_road_corridor()`, `precinct_stretches()`, `alley_lots()`, `closed_tile_set()`,
  `home_tile_rect()` and `size_in_tiles()`; and the baby's `excitement_level()`. Among those with
  no method: the plan record's `facing`, `gate_state` and `age`, and her `facing`, which
  `test_checkpoints` writes to turn her.

## Verified

The checkpoint and region suites pass with the check counts they had, `tools/typing_census.py
--check` holds on both files, and the field-read check passes. No check was deleted or moved.
