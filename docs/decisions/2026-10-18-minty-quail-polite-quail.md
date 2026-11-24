# minty-quail — The door suites take real ticks (A2b D) · 2026-11-24

minty-quail's pass over the event manager's five members only tests read
(`.claude/briefs/designs/minty-quail-manager-members.md`, PR D). The door suites read the
manager's `checkpoints` and stepped the door watch by hand on a city that never ticks.

**Built.**
- `test_route_rig.gd`'s walk-under count passes one real tick per position.
- `EventManager.step_the_doors(delta)` is the tick's three door steps (`warn_at_the_doors()`,
  `watch_the_door_lines()`, `check_detentions()`, with her in the world), and
  `_tick_the_events()` calls exactly it. `test_resistance_crossing.gd` drives it where it drove
  the door watch by hand, with `step_the_encounters()` before it where a hut's hold runs; its
  guard-warning check reads `is_its_guard_warning()` after a step.
- `test_checkpoints.gd` stands its door bodies through `start_recipe()`, runs the street-door and
  guard-after-her rigs on real ticks, records where the door puts her down through a recording
  stroller in place of the door's own `lets_her_out` reads, and brings the late roadblock and
  robber in through `spawn_extra()`.
- `test_encounters.gd` hands the watch a hold answer of its own instead of the controller's method.

**Measured.** CI's run of the first version of this branch (every walk on real ticks, run
45379611601) printed `test_resistance_crossing.gd` at 94229 ms against 46026 ms in
`tests/suite_costs.txt`: 2.05 times and 48 s more, so both halves of the design's cost condition
held (twice 46.0 s plus 30 s is 92.1 s). The orchestrator decided on the design's fallback,
`step_the_doors()`. Locally the suite takes 114 s on real ticks and 57 to 69 s on the step.
`test_checkpoints.gd` took 133.0 s against 71.2 s recorded (1.87x, under the condition) and stays
on real ticks, as do `test_route_rig.gd` (43.3 s) and `test_encounters.gd` (11.5 s). CI's run
of the step gave `test_resistance_crossing.gd` 75.0 s (1.63 times and 29 s more than recorded,
under the condition), on a loaded shard; hand-stepped runs of it in CI took 40.5 to 68.9 s.

**Noted.**
- The run logs on hand steps and on real ticks match.
- In "the guard who warned is the guard who comes", she stands 8px past the centre line, on the
  carriageway the boom spans, since a hut never takes her in from there
  (`CheckpointController._on_a_booms_carriageway()`), though she is 59.5px from the far hut, inside
  its 80px reach. The far hut warned her and is the nearer of the two (59.5px against 74.7px), so a
  controller that sent the guard from the other hut fails the case. The guard is read on the tick he
  is set on her.
- `EventManager._take()` skipping `record_the_body()` fails no suite: neither D's nor the masts'
  lorry case, which #1703 moved onto `start_recipe()`. Nothing holds that recording; the gap is
  filed.
- A post begins no hold while another row's conversation runs: `test_checkpoints.gd`'s corner of
  two doors holds it through a walk the game can produce, and `test_encounters.gd` points there.
