# minty-quail — The event manager's five parts go private (A2b Z) · 2026-11-24

The last of the pull requests of the design that makes the event manager's five parts internal
(`.claude/briefs/designs/minty-quail-manager-members.md`). Six pull requests did the pass: M moved the
manager's own suites and added the hand-in `use_sitings()` and the two kept forwards `route_row()` and
`way_on()`; D moved the door suites to real ticks and added `step_the_doors()`; P moved `--pelican`
into the event surroundings and gave the rigs parts of their own; S moved the other suites to
`start_recipe()`, `stream_around()` and the tick; W measured the director walks and added
`step_what_is_ahead()`; Z renames.

## What was built

- `EventManager`'s `ahead`, `checkpoints`, `spawner`, `streaming` and `warnings` are `_ahead`,
  `_checkpoints`, `_spawner`, `_streaming` and `_warnings`; their five `[own file only]` lines are
  gone from `tools/test_only_members.txt`.
- The eight parked probes (`calm_pelican_day7_van_met`, `plush_moose_arrow_cost`,
  `minty_quail_crowd_yields`, `director_placement_fingerprint`, `m159_tick_sweep_events_cost`,
  `minty_quail_pursuit_timing`, `poster_pursuer_starts`, `trap_arrival_fingerprint`) and
  `tests/basement_walk_rig.gd`'s two reads of the streaming read the underscore names. A probe's
  private read stands, so the lines it prints are the same.
- Two long lines other reviews left are rewrapped (`test_pursuer_on_foot.gd`'s docstring,
  `test_event_moves.gd`'s retirement check).

## Measured

Each probe was run by name on main and on the head; the lines each prints are the same apart from
the times they print (the cost probes' microseconds and milliseconds). `m159_tick_sweep_events_cost`
and `minty_quail_crowd_yields` report 3 failures on both: the first is the split mode's known
mismatch with the real tick (lilac-pelican's `tick-sweep-split.md`), the second a change of
`EventBus.hard_fail_triggered`'s listeners that the probe leaves behind.

## Set aside

`use_director()` (a hand-in only so a test keeps a handle on the real director), walking five cities
for `route_row()`, and real ticks in the probes (every fingerprint they print would change).

## Not held

`EventManager._take()` skipping `EventSpawner.record_the_body()` fails no suite; the gap is filed in
`tests-own-class-members.md`.
