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
  that field. The whole list, by class, is under "Fields read and written, by class" below.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `e0eab0b0e`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`Baby`**: `excitement` → `excitement_level()`.
- **`City`**: `crowd` → no method; `events` → no method.
- **`CityMap`**: `alley_rects` → `alley_lots()`; `block_plans` → `plans_by_block()`;
  `boundary_wall_at_a` → no method; `closed_tiles` → `closed_tile_set()`; `home_rect` →
  `home_tile_rect()`; `main_road` → `main_road_corridor()`; `network` → `street_network()`;
  `precinct_spans` → `precinct_stretches()`; `seed_used` → `city_seed()`.
- **`ClosurePlanner.CalmArea`**: `access` → no method; `block` → no method; `rect` → no method.
- **`EventDef`**: `barrier_structure` → `counts_as_one_barrier()`; `detain_seconds` →
  `detains_for()` (a yes-or-no on the field alone: `detains_her()`); `guard_sides` → no method;
  `hard_fail` → `ends_the_day()`; `intensity` → `peak()` (a yes-or-no on the field alone:
  `has_a_field()`); `obstructs_radius` → `obstructs_within()` (a yes-or-no on the field alone:
  `has_a_body()`); `outer_radius` → `heard_within()`; `pursuit` → no method; `shape` →
  `ground_shape()`; `telegraph_time` → `telegraphs_for()`.
- **`EventInstance`**: `atlas`, written → no method; `def` → `row()`; `def.detain_distance()` →
  `detain_distance()`; `def.id` → `row_id()`; `drawer`, written → no method; `excitement` →
  `source()`; `gate_state` → no method; `gate_state`, written → no method; `gave_up` →
  `has_given_up()`; `is_finished` → `is_gone()`; `is_leaving` → `is_on_its_way_out()`.
- **`EventManager`**: `checkpoints` → no method; `sources` → no method; `stream_radius`, written →
  no method; `streaming` → no method; `trace`, written → no method; `world` → no method.
- **`EventScheduler.Planned`**: `age`, written → `arrive_aged()` does `age = seconds`; `def` →
  `row()`; `def.id` → `row_id()`; `def.obstructs_radius` → `obstructs_within()`; `facing` → no
  method; `facing`, written → no method; `gate_state` → no method; `gate_state`, written → no
  method; `live` → `instance()` (a yes-or-no on the field alone: `is_in_the_world()`); `path` →
  `walks()` (a yes-or-no on the field alone: `stands_still()`); `position` → `placed_at()` (a
  yes-or-no on the field alone: `is_placed()`).
- **`EventWorld`**: `map` → no method.
- **`GroundShape`**: `half_length` → `spine_half_length()`; `kind` → no method (a yes-or-no on the
  field alone: `is_rect()`, `is_segment()`).
- **`LaneMover`**: `kind` through `CrowdAgent` → `lane().kind()` on its view.
- **`RegionPlanner.GateState`**: `position` → no method; `position`, written → no method; `raised` →
  no method; `raised`, written → no method.
- **`RegionPlanner.RegionPlan`**: `alley_doors` → no method; `alley_walls` → no method;
  `door_bodies` → no method; `doors` → no method; `gates` → no method; `wall_bodies` → no method;
  `walls` → no method.
- **`RoadClosure`**: `segment` → no method.
- **`RouteTree`**: `branches` → no method.
- **`RouteTree.Branch`**: `area` → no method.
- **`StreetNetwork.Segment`**: `a` → no method; `b` → no method; `horizontal` → no method.
- **`Stroller`**: `facing`, written → `reset_at()` does `facing = look.normalized()`.
- **`WorldContext`**: `excitement_sources`, written → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`; `world` → no method (a yes-or-no on
  the field alone: `has_world()`); `world`, written → no method.

## Verified

The checkpoint and region suites pass with the check counts they had, `tools/typing_census.py
--check` holds on both files, and the field-read check passes. No check was deleted or moved.
