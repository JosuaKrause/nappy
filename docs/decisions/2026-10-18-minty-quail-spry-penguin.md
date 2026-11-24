# minty-quail — The other suites put their plans in through start_recipe() and tick the manager (A2b S) · 2026-11-24


PR S of the event manager's five parts (minty-quail, tests-own-class-members, A2b). Eleven suites and
rigs that read `streaming` or `warnings` through the manager now ask the manager's own face.

- A plan put in a day by hand (`streaming.add()`) is a walk planned whole: `start_recipe()` in
  `test_masts.gd` (the lorry), `test_event_moves.gd`, `test_event_behaviours.gd`,
  `test_patrol_vanish.gd` and `test_barrier_stays.gd`, with the walk's focus at the plan.
- A stream-out and stream-in is `stream_around()` a point beyond the stream radius, its hysteresis and
  `Tuning.OUT_OF_SIGHT`, then back (`test_barrier_stays.gd`), so it is held to the rule that nothing
  streams out while she could be watching it.
- The retirement sweep is the manager's tick: one physics tick after `retire()` or `end_now()`
  (`test_event_moves.gd`, `test_drawn_view.gd`, `park_cordon_sweep.gd`, whose chain became coroutines).
- A warning run down (`warnings.run()`) is real ticks with a body of the rig's own standing at her
  (`resistance_rig.gd`'s `_run_the_traps_warning()` and `_let_the_events_tick()`, and the column
  case of `test_resistance_placement_kinds.gd`); the camera-only case moves her `Camera2D`.
- `test_halo.gd` drops `retire()` plus the sweep for `stand_down()`: the case is the halo's net for
  a body queued for deletion between the physics step and its pass, which the tick's own retirement
  cannot make, since the end of the physics step deletes what it queued before the pass. The design's
  "drop the call" would have left the case holding nothing.
- A real tick steps what it makes once, as it steps every event, so the "wholly out of sight the frame
  he exists" checks read the place he was made (`walks()[0]`) and no longer his position after the step.
- Set aside: keeping the sweep synchronous by a public step on the manager (nothing measured asked
  for one), and `stand_down()` in `test_drawn_view.gd` (its manager stays and its edge keeps drawing).
- Measured: the nine suites (`test_masts`, `test_event_moves`, `test_event_behaviours`, `test_halo`,
  `test_drawn_view`, `test_patrol_vanish`, `test_barrier_stays`, `test_resistance_traps`,
  `test_resistance_placement_kinds`) 5876 checks on main and on the head; `test_park_cordon_seeds_a/b/c`
  with `test_resistance_crossing` 1296 on both; three shuffled repeats (seed 7) green.
