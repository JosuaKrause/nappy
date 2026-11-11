# minty-quail — The crowd's suites are typed and read the crowd through methods · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
The first of the crowd's two passes of `typed-everywhere.md`'s "What is untyped in a test goes as
its suite is converted", after the crowd's source cuts (minty-quail-minty-osprey, -jolly-marten)
and the runner typed in every suite (minty-quail-downy-kestrel). The second, the car, walker,
turns, give-way and traffic suites, is still to come.

## What was built

- **`test_crowd_closures_a`, `_b`, `_c`, `test_crowd_contributions`, `test_crowd_field`,
  `test_crowd_streets`, `test_crowd_traffic`, `test_crowd_yields`, `crowd_rig.gd` and
  `crowd_closures_rig.gd` are typed and lose their opt-out line.** `crowd_street_rig.gd`,
  `test_crowd_bodies` and `test_crowd_bodies_on_a_real_day` had none. No line under `src/` changed.
- **The suites ask the crowd through the methods the game calls**: an agent's `mood()`, its lane's
  `kind()`, `strategy()` and `shape()` and the lane's questions for a door, a gate or a pedestrian
  ahead; the lane is told `see_a_pedestrian_at()`, `see_no_pedestrian()` and
  `find_no_junction_to_hold_at()`, a hut `stands_at()`, an arc `travel_on()` and a field
  `centre_on()`, where each was written or read by field. A field answers `half_extent()` and
  `centre_point()`, a car's ground shape `spine_half_length()` and `rounding_radius()`, the traffic
  lights are moved on by `advance()`, and a door hut's line is read through `place_of()` and
  `committed()`. `tools/check_field_reads.py` does not
  read tests, so the reads were found by search.

## Left, each with its reason

- `crowd.sources`: `city.gd` and `run_session.gd` read the field too, and no method answers it.
- `crowd.skip_motion`, written: the configuration seam `city.gd` writes.
- A checkpoint hut's `inside`, compared with a walker or with nothing: no method the game calls says
  who is inside, or whether anyone is. `WalkerDoorHold.waiting()` answers the line's length, but no
  game code calls it, so no test reads through it and it is left for the crowd's own source.
- The traffic lights' `elapsed`, read once to save it and written to set a departure time and to
  restore it: `advance()` only adds and `restart_cycle()` only zeroes, so no method sets a chosen
  time.
- `radius`, written on a hand-built `CarTurn`: no method sets an arc's radius.
- `agent.kind`, written on a hand-built agent: its setter installs the strategy, which is how one
  is built.
- Other modules' fields, which are their own passes: the events' `def.shape`, `piece.shape`,
  `plan.position` and `EventInstance.skip_draw`, `MoveProposal`'s, and the checkpoint gate state's.
- `tests-one-module.md`'s crowd entry stays as written: `test_recipe_crowd`'s
  `Crowd.recipe_coverage` check is in another module's suite, and the events' answers in the crowd's
  suites move with the events.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `d291155ed`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`CarTurn`**: `radius`, written → `tighten_to()` does `radius = tighter`.
- **`City`**: `crowd` → no method; `events` → no method; `map` → no method; `signals` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `boundary_wall_at_a` → no method; `built_over`
  → `streets_built_over()`; `calm_blocks` → `calm_blocks_now()`; `dead_ends` → no method;
  `home_block` → `home_block_coordinate()`; `main_road` → `main_road_corridor()`; `network` →
  `street_network()`; `precinct_spans` → `precinct_stretches()`; `soft_sealed_tiles` → no method;
  `zone_rects` → no method.
- **`Crowd`**: `skip_motion`, written → no method; `sources` → no method.
- **`EventDef`**: `detain_seconds` → `detains_for()`; `obstructs_radius` → `obstructs_within()`;
  `pavement_side` → no method; `shape` → `ground_shape()`; `speed` → no method.
- **`EventInstance`**: `skip_draw`, written → no method.
- **`EventManager`**: `streaming` → no method; `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `position` → `placed_at()`.
- **`EventWorld`**: `map` → no method.
- **`LaneMover`**: `kind`, written through `CrowdAgent` → `setup_at()` does `kind = agent_kind as
  Kind`, `setup()` does `kind = agent_kind`.
- **`MoveProposal`**: `from` → `stands_at()`; `parked` → no method; `parked`, written → no method;
  `radius` → `body_radius()`; `radius`, written → `use_body_radius()` does `radius = reach`;
  `stood_round` → `stood_round_a_body()`; `stood_round`, written → no method.
- **`RegionPlanner.GateState`**: `position` → no method; `position`, written → no method; `raised` →
  no method.
- **`RegionPlanner.RegionPlan`**: `door_bodies` → no method; `doors` → no method; `gates` → no
  method; `walls` → no method.
- **`SeparationPass.Keeper`**: `move` → no method; `step` → no method; `ticks_still` → no method.
- **`StreetNetwork.Segment`**: `a` → no method; `b` → no method; `horizontal` → no method.
- **`TrafficSignals`**: `elapsed` → no method; `elapsed`, written → `restart_cycle()` does `elapsed
  = 0.0`, `advance()` does `elapsed += delta`.
- **`WalkerDoorHold`**: `inside` → no method.
- **`WorldMap`**: `moves` through `CityMap` → no method; `size` through `CityMap` →
  `size_in_tiles()`; `world`, written through `CityMap` → no method.
- Receiver's class not told: `tests/test_crowd_yields.gd:261` `rig.plan.live`.
- Receiver's class not told: `tests/test_crowd_yields.gd:277` `rig.plan.live`.
- Receiver's class not told: `tests/test_crowd_yields.gd:282` `rig.plan.live`.
- Receiver's class not told: `tests/test_crowd_yields.gd:304` `rig.plan.live`.

## Verified

The crowd's suites pass, `tools/typing_census.py --check` holds, and no game file changed, so the
identity probes do not apply. No check was deleted or moved.
