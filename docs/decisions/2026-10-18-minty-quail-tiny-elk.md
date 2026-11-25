# minty-quail — The crowd's second pass: the car, walker, turn, give-way and traffic light suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
The second of the crowd's two passes of `typed-everywhere.md`'s "What is untyped in a test goes as
its suite is converted", after the first (minty-quail-minty-panda) took the `test_crowd_*` suites
and their rigs.

## What was built

- **`test_car_views`, `test_walker_views`, `test_turns`, `test_traffic_light` and the rig
  `lane_key_search.gd` are typed and lose their opt-out line**; `test_car_driving`,
  `test_give_way`, `test_traffic_signals`, `given_planner.gd` and
  `recording_traffic_light_drawer.gd` had none. No line under `src/` changed.
- **The suites ask the crowd through the methods the game calls**: the traffic lights are restarted
  and moved on by `restart_cycle()` and `advance()`, which also set the lights to a chosen time in
  `crowd_rig.gd`, where the first pass had left the clock written by field; a traffic light is
  mounted by `mount()`, as the city mounts one; a car's lane is told `see_a_pedestrian_at()`, `see_no_pedestrian()` and
  `be_placed_along()`, and asked `gap_ahead()` and its strategy's `has_nowhere_to_turn()`; an arc
  is moved on by `travel_on()`; an agent's excitement is read by `mood()`.

## Left, each with its reason

The search covered the crowd's own classes: `CrowdAgent`, `LaneMover` and its `Lane`,
`LaneStrategy`, `CarStrategy`, `WalkerStrategy`, `CarTurn`, `AgentLook`, `CarLook`, `WalkerLook`,
`CrowdExcitement`, `Crowd`, `TrafficSignals`, `TrafficLight`, `TrafficLightDrawer`, `GiveWay` and
`CrowdLanes`.

- **`TrafficSignals.powered`, written**: the game writes the field itself (the blackout and the
  scene recipes' runtime), and no method sets it.
- **`CarTurn.radius`, read**: no method answers it.
- **`AgentLook.view`, written**: the look sets it itself, and no method sets a chosen view.
- **`CarLook.travelled`, read and written**: no method answers or sets a chosen distance.
- **Other modules' fields stay for their passes**, listed by class, each with the game's method or
  "no method", under "Fields read and written, by class" below.
- **Suites with a crowd half whose subject is another module's are not taken** and keep their
  opt-out lines: `test_danger` and `test_wall_shield` (which `tests-one-module.md` entry 6 splits
  with the events), `test_drawn_view` and `test_prediction_reuse`. `test_wall_shield`, for
  one, reads a crowd agent's `excitement` where the game asks `mood()`, which its pass converts.
- **Probes on crowd subjects keep their opt-out lines**; they are not suites.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `37333487b`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`AgentLook`**: `view`, written through `CarLook`, `WalkerLook` → `CarLook.sector()` does `view =
  EightDirection.update(view, _agent.velocity(), IDLE_SPEED)`, `CarLook.picture()` does `view =
  EightDirection.update(view, moving, IDLE_SPEED)`, `WalkerLook.sector()` does `view =
  EightDirection.update(view, _heading_now(), IDLE_SPEED)`, `WalkerLook.picture()` does `view =
  EightDirection.update(view, heading_at(moving), IDLE_SPEED)`.
- **`CarLook`**: `travelled` → no method; `travelled`, written → `advance()` does `travelled =
  wrapf(travelled + moving.length() * delta, 0.0, WheelBob.WAVELENGTH)`.
- **`CarTurn`**: `radius` → no method.
- **`City`**: `crowd` → no method; `events` → no method; `map` → no method; `signals` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `boundary_wall_at_a` → no method; `built_over`
  → `streets_built_over()`; `calm_blocks` → `calm_blocks_now()`; `dead_ends` → no method;
  `main_road` → `main_road_corridor()`; `network` → `street_network()`; `precinct_spans` →
  `precinct_stretches()`.
- **`Crowd`**: `skip_motion`, written → no method; `sources` → no method.
- **`DayPlanner.Plan`**: `is_a_day`, written → no method; `placements`, written → no method.
- **`EventDef`**: `detain_seconds` → `detains_for()` (a yes-or-no on the field alone:
  `detains_her()`); `speed` → no method; `telegraph_time` → `telegraphs_for()`.
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out); `is_parked` → no method (`EventInstance.Figure.has_parked()` returns it
  on a view no public method hands out).
- **`EventManager`**: `planner`, written → no method; `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `position` → `placed_at()` (a yes-or-no on the
  field alone: `is_placed()`).
- **`ExcitementSource`**: `rim` through `CrowdExcitement` → no method.
- **`LaneMover`**: `kind`, written through `CrowdAgent` → `setup_at()` does `kind = agent_kind as
  Kind`, `setup()` does `kind = agent_kind`.
- **`MoveProposal`**: `radius`, written → `use_body_radius()` does `radius = reach`; `stood_round`,
  written → no method.
- **`RegionPlanner.GateState`**: `position` → no method; `position`, written → no method.
- **`RegionPlanner.RegionPlan`**: `door_bodies` → no method; `doors` → no method; `gates` → no
  method.
- **`StreetNetwork.Segment`**: `a` → no method; `b` → no method; `horizontal` → no method.
- **`TrafficSignals`**: `elapsed` → no method; `powered`, written through
  `tests/test_traffic_light.gd.GreenSignals` → no method.
- **`WorldMap`**: `moves` through `CityMap` → no method; `size` through `CityMap` →
  `size_in_tiles()`.

## Verified

The suites and the rig pass, `tools/typing_census.py --check` holds, and no game file changed, so
the identity probes do not apply. No check was deleted or moved.
