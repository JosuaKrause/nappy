# minty-quail — The door suites take real ticks (A2b D) · 2026-11-24

minty-quail's pass over the event manager's five members only tests read
(`.claude/briefs/designs/minty-quail-manager-members.md`, PR D). The door suites read the manager's
`checkpoints` and stepped the door watch by hand on a city that never ticks.

**Built.**
- `test_route_rig.gd`'s walk-under count passes one real tick per position. `test_resistance_crossing.gd`'s
  walks, clock loops and hut holds run on real ticks at the suite's step; its guard-warning check reads
  `is_its_guard_warning()`.
- `test_checkpoints.gd` stands its door bodies through `start_recipe()`, runs the street-door and
  guard-after-her rigs on real ticks, records where the door puts her down through a recording stroller
  in place of the door's own `lets_her_out` reads, brings the late roadblock and robber in through
  `spawn_extra()`, and holds a new case: a post begins no hold while another row's conversation runs.
- `test_encounters.gd` hands the watch a hold answer of its own instead of the controller's method.

**Noted.**
- The run logs on hand steps and on real ticks match, so no `step_the_doors()` was added. Local timings
  varied too much to judge; `test_resistance_crossing.gd`'s shard time in CI is the measure, against
  twice its recorded 46 s plus 30 s.
- In "the guard who warned is the guard who comes", the far lane stood inside the far hut's 80px reach,
  so on real ticks the hut took her in; the lane moves to 8px across, outside that reach, and the guard is
  read on the tick he is set on her.
- `EventManager._take()` skipping `record_the_body()` fails none of the door suites; the masts' lorry
  case holds it.
