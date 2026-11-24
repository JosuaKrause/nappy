# minty-quail — The probes hold the run, the trace and the atlas they hand the city (minty-quail, C6b) · 2026-11-24

C6b of the city scene's pass (`.claude/briefs/designs/minty-quail-city-scene-pass.md`): no file under
`tests/`, `src/` or `tools/` reads `city.run`, `city.trace` or `city.atlas` any more, apart from the one
read left for C7 ("Reads left"). C6a did the suites and the rigs; this is the probes, by hand.

## What was built

- **The run.** Each of the 28 probes that read `city.run` reads the `RunState` it made with
  `RunCity.started_run()` and handed `RunCity.build()`. A helper that took only the city takes the run
  as a parameter after it (`_a_day`, `_walk_one`, `_measure`, `_read_the_mark`, `_restart_the_day`,
  `_start_the_day`); where a helper opened with `var run: RunState = city.run` the line is gone and the
  parameter takes its name. `m180_crews_on_her_way`'s `_pasted_cells()` asks the run's posters and so
  takes the run in place of the city. `m181_resistance_targets` reads its own `own_run`.
  `minty_quail_walk_field_parity` extends `tests/test_day13_guard.gd`, which keeps its run as `_run`
  (C6a), and reads that.
- **The atlas.** The two probes that read `city.atlas` to hand a `ParkCordon` the pages
  (`minty_quail_crowd_yields`, `minty_quail_pursuit_timing`) make an `AtlasLibrary`, hand it to
  `RunCity.build()` as its `library`, and hand the same one to the cordon. No probe reads `city.trace`.
- **Queue.** The `run` and `atlas` lines of `tools/test_only_members.txt` are gone: no test reads either
  field any more, so the check lists neither. The entry's README lists C7 only.

## Reads left

`tests/test_atlas_boot.gd:203`, `node.get("atlas")` over every node of a booted `main`, the city
included, stays for C7, as C6a's record says. `tests/probes/minty_quail_crowd_frames.gd` does not parse on
main (it redeclares `drawn`, filed as silky-moose) and holds no read of the three fields; it is
untouched.

## Measured

The probes are run by name, one at a time, each capped at 90 s. Twelve finish with no error
(`calm_pelican_day7_van_met`, `excitement_fingerprint`, `m179_fire_on_her_way`, `m213_far_end`,
`m219_precinct_pile`, `merry_elk_poster_density`, `minty_quail_pursuit_timing`,
`minty_quail_sidewalk_gap`, `minty_quail_swap_candidates`, `minty_quail_walk_field_parity`,
`placement_fingerprint`, `plush_moose_arrow_cost`). The other sixteen are past setup and printing at the
cap with no `SCRIPT ERROR` and no parse error. The first run of three of them
(`minty_quail_day13_real_marks`, `minty_quail_day13_roadblock`, `minty_quail_walk_field_parity`) failed
to parse, a helper called from a function with no `run` in scope, which the run found and a fix made. On
main and on the branch, `placement_fingerprint` and `excitement_fingerprint` print the same lines apart
from the `XF_COST` timing lines, and `m179_fire_on_her_way` and `m213_far_end` print the same lines
(times aside). Every script under `tests/` was loaded: the only parse error is the one of
`minty_quail_crowd_frames`.
