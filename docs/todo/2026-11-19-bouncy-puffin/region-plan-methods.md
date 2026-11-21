# The suites read the region plan and the gate's state through methods, and their fields go private

`RegionPlan` and `GateState` (`src/routes/region_plan.gd` and `src/routes/gate_state.gd`, the routes, model layer)
answer every reader under `src/` through methods (the record bouncy-puffin), but nine of their fields stay public
because the suites, their rigs and the probes read and build plans and gates by hand, each field a `[kept]` line in
`tools/test_only_members.txt`. What is left: those reads go through the methods and the fields go private, each with
its `[kept]` line deleted.

| Field | Read by the suites as | Replaced by |
|---|---|---|
| `RegionPlan.walls` | the wall segments | `wall_segments()` |
| `RegionPlan.doors` | the door segments | `door_segments()` |
| `RegionPlan.alley_walls`, `alley_doors` | the alleys walled or doored | `walled_alleys()`, `door_alleys()` |
| `RegionPlan.wall_bodies`, `door_bodies` | the planned wall and door bodies | `wall_plans()`, `door_plans()` |
| `RegionPlan.gates` | each door's shared state | `gate_states()` |
| `GateState.position` | where the boom stands | `ground_point()` |
| `GateState.raised` | whether the boom is up | `is_boom_up()`, `set_boom_up()` |

A suite that builds a plan or a gate by hand builds it through `RegionPlan`'s `add_*` methods and
`GateState.new(at)`. One write has no method yet: `tests/crowd_rig.gd` sets a gate's position and then its `x` and
`y` apart; the rig builds the gate at its point instead (`GateState.new(at)`), or the pull request says what it adds.

It is built by its own scripted pass or beside minty-quail's row 4a (the tests read through methods, which lists
only the events' own classes), whichever comes first; the search for every old name read without parentheses is
shown in the pull request (inbox #1385 in silver-tapir).
