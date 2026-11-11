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
- **Other modules' fields stay for their passes**, with the game's method named where one exists:
  the map's `main_road` (`main_road_corridor()`), `network` (`street_network()`), `size`
  (`size_in_tiles()`) and `moves` (none); the world's `ExcitementSource.rim` (none);
  `MoveProposal`'s `radius` (`use_body_radius()`) and `stood_round` (none); the events' `is_parked`
  and `age` (`EventInstance.Figure`'s `has_parked()` and `age()`); `EventManager`'s `planner` and
  `world` and a day plan's `placements` and `is_a_day` in `given_planner.gd` (none); and `City`'s
  `crowd`, `map`, `signals` and `atlas`.
- **Suites with a crowd half whose subject is another module's are not taken** and keep their
  opt-out lines: `test_danger` and `test_wall_shield` (which `tests-one-module.md` entry 6 splits
  with the events), `test_drawn_view` and `test_prediction_reuse`. `test_wall_shield`, for
  one, reads a crowd agent's `excitement` where the game asks `mood()`, which its pass converts.
- **Probes on crowd subjects keep their opt-out lines**; they are not suites.

## Verified

The suites and the rig pass, `tools/typing_census.py --check` holds, and no game file changed, so
the identity probes do not apply. No check was deleted or moved.
