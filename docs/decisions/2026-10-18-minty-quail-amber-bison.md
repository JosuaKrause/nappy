# minty-quail — A run that crosses midnight no longer loses its route lines, and a re-run shuffles anew · 2026-11-06


The flaky half of `tests-isolated.md` (freckled-moose #914): every check whose result changes between
runs made deterministic, and three full shuffled CI runs on one head green. CI's sample of the last
two weeks was mined for failures that passed on a re-run, and each failed shard log read.

## The flakes found, each with its cause and fix

- **`test_route_building.gd`, four checks** (`the run leaves route lines in its run log`, `the
  building is planned as a walk out`, `the building is won`, `and the city's rig takes the walk on`;
  CI run 42132883381, shard 4, passed on re-run). Cause: the suite launches the game as a child
  process and polls the child's run log, finding the folder by `Time.get_date_string_from_system()`
  recomputed on every poll. The child opened its log at 23:59:34 UTC in the folder of 2026-11-05; at
  midnight the suite looked in the folder of 2026-11-06, which did not exist, and read no route
  lines. Fix: the suite names the day it started on once and reads every day folder from that day
  on. Two probes (`tests/probes/escape_winnable.gd`, `m184_route_timing.gd`) build the same path and
  are not suites; they keep it.
- **`test_move_poses.gd`, a position nothing checked** (a lead from the review of #1129: her
  position at the swing tick took five different values on main for seed 1, and three for seed
  4242). Cause: the boot and the title's presses await real frames, and a frame gives the game as
  many physics ticks as the wall clock allows (35 or 36 for seed 4242), so the crowd had stepped a
  wall-time-dependent number of ticks before the walk began; the walk stands her against the nearest
  walker every 30 ticks, so one tick of difference chose another walker and the walks diverged. The
  game's own code reads no wall time here. Fix: the suite holds `Engine.time_scale` at 0 through the
  boot and the title, so ticks that run then carry no game time, and restores it before the walk;
  three runs gave the same position. Other suites that boot `main` and await frames before a
  tick-counted walk have the same shape; none of them was found to check a position the variation
  reaches.
- **CI's shuffle seed.** The seed was the run id, which a re-run shares, so re-running a head
  replayed the same order. It is now the run id followed by the attempt number, and the log prints
  the seed that replays it.

## Not reproduced

The order-dependent `test_touch` failure on main. Eight shuffled serial runs (seeds 1 to 8, two
passes each) of the 18 input, pause and touch suites under eight seconds, `test_touch.gd` among
them, gave no failure. The runner's shared-state check, which since its addition fails a suite that
leaves `Input`, the pause or the engine's settings changed, is what keeps such a leak from reaching
another suite; the cause of that one failure stays unestablished.

## Not flaky

The other failed CI runs of the two weeks (`gates`, `game` and `browser` jobs, and shard failures
whose logs show parse errors or checks of the branch's own change) were deterministic failures of
their branches that a later commit fixed, or non-suite jobs; none passed on a re-run in a shard
beyond the two above, apart from one Chrome export (`browser`, run 41911411887), which is not a
suite.
