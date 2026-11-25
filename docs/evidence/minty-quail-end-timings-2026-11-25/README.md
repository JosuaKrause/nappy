# The end remeasure's timings (minty-quail, group T)

Measured, listed, sized; nothing here is judged (the record minty-quail-downy-finch judges).

## Trees and machine
Every row is two detached worktrees (`tools/agent-setup.sh --detach <ref> <name>`, each given
`tools/check.sh` once) whose
runs start in one script at the same moment (`Promise.all`), on an Apple M2, Godot 4.7.2,
nothing else running. Each run's
`uptime` and `pgrep -fl Godot` are in `raw/<run>.load`, except for six runs named under Load.

| Role | Ref | Full hash |
|---|---|---|
| head (today's main) | fc29914e6 | fc29914e60afd85bb216bd5e9307b00a3b66218a |
| after-4b | b3693bee7 | b3693bee7149b1ac0694ed6ea611178652d20896 |
| pre-3a | 202f964ec | 202f964ec966c6ad8c169a83630276d94f52c4d8 |
| v0.29.0 | tag | 6985ac74fd2853bffc05607c53c21ce50b69429a |
| tawny-swan merge | 75ef3ad57 | 75ef3ad57da7ec864e282bc2378f0dd9c6ea4aa1 |
| polite-newt merge | cf0f9db72 | cf0f9db72fc833605a12084eed441f21bbfdaeaa |
| calm-egret merge | d22a78e15 | d22a78e1596f8a225e496e8d22a8de13faa1a599 |

Probe copies (uncommitted in the scratch trees, kept in `probes/`): `dawn_planning_time_end.gd`
with
`placement_probe_day_timed.gd` (head's placement_rows.gd and its helper with the timers; headers
say what the timers leave
out), `entity_frame_profile_end.gd` (head's launcher with `--invincible`, debugger port 6128 so
that it runs beside the
after-4b copy on 6127), `entity_frame_profile_v0.29.0_invincible.gd` (port 6127). The after-4b
copies are the baseline
folder's (`docs/evidence/minty-quail-baseline-2026-11-09/probes/`). Nothing under src/, tests/
or tools/ changed.

## Reproduce
`python3 -I summarize_timed.py` prints every table below from `raw/` (`summary_output.txt` is
its output; set
`BASELINE_TIMED` to the baseline folder's `raw/timed` when that folder is not a sibling).
`frame_ticks.py raw/fp` prints the
tick-carrying frames table. Logs over 400 KB are gzipped; the excitement and look probes' logs
keep only their result
lines (XF_COST, LK_COST, check counts); the profiler streams are not kept, the scene files
(every sampled frame) are, gzipped.
Rerun commands write into a new scratch directory (`$SCRATCH`), never into `raw/`, which holds
the recorded results. Commands: `tools/test.sh probes/<probe>.gd > $SCRATCH/<run>.log` in each
tree; the frame profile launcher is
`ENTITY_PROFILE_OUTPUT=$SCRATCH/<prefix> [ENTITY_PROFILE_DISABLED=1] $GODOT --headless --path
<tree> --script tests/probes/<copy>.gd`
then `python3 -I <tree>/tests/probes/entity_frame_profile_analyze.py $SCRATCH/<prefix>
[--profiler-disabled] --output $SCRATCH/<prefix>-summary.json`.

## Load
Every round's one-minute load at its start is in its `.load` file; no Godot process but the
pair's own was running.
Rounds that started at a one-minute load of 4 or more (the load is the previous pair's own,
since nothing else ran), kept and
labelled, not dropped: `t5_m159_tick_sweep_events_cost_*_2` (7.31),
`t5_m159_tick_sweep_events_cost_*_4` (4.21),
`t5_excitement_fingerprint_*_3` (4.07). Every other round started under 4 (highest 3.74). The
plan's section 3 asks for such a round to be rerun, kept and labelled; these three were kept and
labelled and not rerun, since their ratios agree with the clean rounds (tick sweep events 1.056
and 1.066 against 1.067 and 1.052; XF_COST 1.025 against 1.029, 1.014 and 1.029; the baby's
sweep in round 2, 0.974, is just under the clean rounds' 0.982 to 1.000).

Six runs have no load or log file of their own: the head runs beside after-4b of the frame
profile (`raw/fp/{profiled,disabled}_end_{1,2,3}`) wrote to
`raw/frame_{profiled,disabled}_end_{1,2,3}.{load,log}`, the names the v0.29.0 pair's head runs
used next, so those files hold the v0.29.0 pair's load (times 2:50 to 2:52) and log, not the
after-4b pair's (2:48 to 2:49). The six runs' scene and summary files are intact and are what T3
and the tick-frame table use; the pairs were started together, but the six runs' load is not
kept.

## T1. dawn planning (14 cities x 14 days), seconds, rounds 1 to 3
| | build_day | draw_every_unit | whole probe |
|---|---|---|---|
| head | 42.8, 46.2, 47.9 | 329.4, 353.1, 366.4 | 513.6, 549.7, 570.9 |
| after-4b, beside it | 42.9, 46.0, 47.5 | 330.6, 356.2, 369.4 | 499.1, 535.8, 556.3 |

The head copy's whole probe holds work the after-4b copy's does not (each city's day closures,
region wall and seals planned
as DayPlanner does, and a city node per city; see the copy's header). The baseline's fourth
column (not at the same moment):
build_day 44.1, draw_every_unit 334.3, whole probe 505.2.

## T2. crowd tick: mean over the 36 whole-mode cases of each case's median per-tick microseconds
| | rounds 1 to 3 | median (min to max) |
|---|---|---|
| head (tick, agents inside) | 2374, 2398, 2374 | 2374 (2374 to 2398) |
| v0.29.0, beside it (agents column + tick column) | 1353+319, 1369+325, 1355+320 = 1672, 1695, 1675 | 1675 (1672 to 1695) |
| after-4b, the baseline (not at the same moment) | 2481, 2341, 2351 | 2351 (2341 to 2481) |

## T3. frame profile (seed 4242, day 1, `--invincible`), callback interval median ms, rounds 1
to 3
| | head | beside it |
|---|---|---|
| profiled, after-4b pair | 4.21, 4.10, 4.64 | after-4b 4.23, 4.15, 4.96 |
| profiler off, after-4b pair | 7.24, 7.44, 6.81 | after-4b 6.75, 6.76, 7.26 |
| profiled, v0.29.0 pair | 4.59, 4.52, 4.08 | v0.29.0 8.50, 8.41, 8.47 |
| profiler off, v0.29.0 pair | 7.49, 7.15, 6.67 | v0.29.0 8.55, 8.57, 8.57 |

The analyzer accepted all 24 of these runs. Head's unmodified launcher (one profiled, one off,
run alone): both rejected
(reasons in `raw/fp/*_end_unmodified_1-summary.json.gz`: a paused or ended day, northward
movement below 450 px, north
input not held; the profiled one also a physics-count mismatch); callback interval 8.10 and 8.31
ms.

Frames that carry a physics tick (the physics runs at 30 Hz in every tree here, one frame in
four carries a tick; interval to
the previous sampled frame, window 5 to 11 s, `frame_ticks.py`), profiler off, three rounds
each:
| | tick frames, mean ms | other frames, mean ms | longest frame ms | mean of the ten longest ms |
|---|---|---|---|---|
| head, beside v0.29.0 | 16.9, 17.0, 17.2 | 5.5, 5.5, 5.4 | 29.3, 29.0, 32.0 | 21.5, 22.4, 22.3 |
| head, beside after-4b | 16.9, 17.1, 17.4 | 5.5, 5.4, 5.3 | 31.3, 33.6, 33.0 | 21.5, 22.4, 22.8 |
| v0.29.0 | 9.9, 10.0, 9.9 | 7.8, 7.8, 7.8 | 12.5, 11.8, 12.3 | 11.3, 11.4, 11.4 |
| after-4b | 17.4, 17.8, 16.9 | 5.3, 5.2, 5.5 | 31.5, 33.3, 30.3 | 22.9, 22.7, 21.6 |

Profiled: head tick frames 19.5 to 19.6, other frames 4.7; ten longest 24.1 to 24.5 (v0.29.0:
10.0 to 10.2, 7.7, 11.0 to 11.4).

## T4. streaming's tick (split mode's stream column; mean over 36 cases of the per-case median
over the 600-tick window)
| | stream µs/tick, rounds 1 to 3 | planned events (mean) | stream ns per plan | whole mode's events step µs/tick |
|---|---|---|---|---|
| head beside pre-3a | 289.1, 293.2, 289.1 | 292.9 | 988, 1000, 986 | 988, 1001, 987 |
| pre-3a | 208.7, 210.6, 208.3 | 292.9 | 714, 720, 711 | 668, 683, 678 |
| head beside v0.29.0 | 272.2, 269.8, 271.0 | 292.9 | 927, 921, 924 | 932, 928, 927 |
| v0.29.0 | 106.6, 105.9, 105.9 | 371.7 | 286, 285, 285 | 334, 333, 333 |

The probe's own check that its split step changes the state as the whole step does fails on 3 of
36 cases on both head and
pre-3a, every round (seed 4242 day 9 events walk, three repetitions, in the runs beside pre-3a
and v0.29.0; seed 478156010
days 9 and 14 in T5's runs: 6 failures); v0.29.0 has none. The stream column over only the cases
whose split chain equals the
whole chain: head 289.5, 293.8, 291.1 (beside pre-3a), 275.2, 272.4, 273.8 (beside v0.29.0);
pre-3a 209.5, 211.8, 210.2.

## T5. the events' interface's owed readings, rounds 1 to 4 (summary_output.txt has every
figure)
Tawny-swan merge beside calm-egret merge, ratio calm-egret over tawny-swan per round:
- events' whole step, sum of the 36 whole-mode medians (µs): tawny 22200, 26480, 25688, 24601;
  egret 23678, 27953, 27020, 26234; ratios 1.067, 1.056, 1.052, 1.066.
- baby's sweep, sum of 36 split-mode medians (µs): tawny 228, 270, 256, 250; egret 224, 263,
  256, 247; ratios 0.982, 0.974, 1.000, 0.988.
- XF_COST, sum of nine lines (µs): tawny 4264163, 4048809, 4360731, 4026047; egret 4388929,
  4105548, 4471036, 4143330; ratios 1.029, 1.014, 1.025, 1.029.
- fields layer, whole map cold, two seeds (ms): tawny 84.4, 82.1, 75.0, 74.8; egret 88.4, 82.9,
  75.5, 80.7; ratios 1.047, 1.010, 1.007, 1.079.
- crowd tick control (µs): tawny 2747, 2532, 2626, 2497; egret 2888, 2678, 2754, 2631; ratios
  1.051, 1.058, 1.049, 1.053.

Polite-newt merge beside calm-egret merge, LK_COST (µs over 26400 calls): newt 223946, 220664,
222947, 219249; egret 233724,
226803, 223216, 219469; ratios 1.044, 1.028, 1.001, 1.001.

## T6. day 13's roadblock from real chalk marks (head alone, last, load in
`raw/day13_marks_end_1.load`)
480 marks over 20 seeds: found at 576 px 329, at 896 px 83, at 1,024 px 9 (421), swapped 58,
missed 1 (the missed mark is
named in `raw/day13_marks_end_1.log`). Distance, mark to roadblock: found median 422 px (116 to
1,118), swapped median 1,092
(365 to 2,122). RM_TIME on the frame she reads the mark: found median 48.8 ms (max 384.1),
swapped median 96.1 (max 180.8),
the whole-city walk inside a swap median 36.4 (max 48.8). Beside minty-quail-sunny-owl's figures
(swap median 35, max 41, the walk 33; found frame 4; 40 swapped, none missed): the swap frame
96.1 against 35, the found frame 48.8 against 4, swaps 58 against 40, one miss against none, the
walk unchanged. The miss is filed as the `bug` entry bouncy-elk. The probe ran 1,556,718 ms.

## Footprint
230 files, 11.5 MB on disk (the 24 per-tick `m159` logs, gzipped, are about 7 MB of it; every
claim reads only the per-case medians that `summarize_timed.py` computes from them).

## Not measured
Nothing named by the brief is left unmeasured. The phone's frame record and the published build
are not here.
