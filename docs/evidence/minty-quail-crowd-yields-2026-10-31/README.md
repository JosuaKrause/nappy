# C2b: the crowd yields to event figures, measured (PR #895, minty-quail shared-components C2b)

> **Kept in the repository:** this README, the tables (`*.md`), the analysis scripts, `pairs/` (each before still stacked over its after still, which is where `before/` and `after/` went), `walks/` (the recorded walks the replay runs read) and `raw/` gzipped. The scene recipes and the separate before and after stills stayed in the session's scratch; the commands below remake them.


Claim: with C2b, walkers step aside from or are pushed clear of event figures and crowd cars stand for
them, while the event figures keep their courses and nothing the crowd does *without* a figure changes.
Measured by agent `c2b-sonnet` (Sonnet 5.5), on one machine, other agents running Godot at the same time.
Limits are at the end.

## Provenance
- **Head:** `108ad8507a8d914c3d44e71c6d2c0679e9e55818` (branch `feature/minty-quail-shared-c2b`, merge of main
  into C2b). Checkout `c2b-sonnet-head` from `tools/agent-setup.sh --detach 108ad850 c2b-sonnet-head`.
- **Base, the game before C2b:** `70ef44c66a8f06dcf86b8a2aad90bc23faec1caf` (`origin/main`, "File inbox #883, #884,
  #894, #896 ... (#898)"), checkout `c2b-sonnet-base` from `--detach origin/main`. Head's
  `tests/probes/minty_quail_crowd_yields.gd` and `minty_quail_crowd_cadence.gd` were copied over it,
  uncommitted (the cadence probe already existed on main in an older form and was overwritten).
  Both checkouts were removed afterwards.
- Commands (each from the checkout named; `tools/test.sh` output copied to `raw/`):
  1. `tools/test.sh probes/minty_quail_crowd_yields.gd` on both (seeds 4242 and 1, the probe's defaults) -> `raw/yields-base.txt`, `raw/yields-head.txt`.
  2. Crowd alone: `CADENCE_FRAMES=1 CADENCE_SEEDS=1001,1111,2002,2222,3003,4242,478156010,5005,6006,7007,8008,9009 tools/test.sh probes/minty_quail_crowd_cadence.gd` on both -> `raw/cadence-alone-*.txt`.
     48 runs each = 12 seeds x days 1 and 9 x walks `road` and `walkers`.
  3. With the day's events, same seeds and frames: base with `CADENCE_EVENTS=1 CADENCE_RIG_RECORD=<out>/walks` (48 walks recorded to `walks/`), head with `CADENCE_EVENTS=1 CADENCE_RIG_REPLAY=<out>/walks` -> `raw/cadence-events-*.txt`.
  4. `tools/test.sh probes/m159_crowd_tick_cost.gd` on both, base first, then head -> `raw/cost-*.txt`.
  5. Pictures: from the head checkout `tools/scene-recipes.sh --screenshots --output <out>/after --recipe <each of the 8 recipes>` -> `after/`; manifests, logs and the `-start` stills moved to `raw/scene-after/`. Recipes: `/tmp/c2b-runs/pics/recipes/`. Before stills: `/tmp/c2b-runs/pics/before/` (made on the base by the orchestrator), copied to `before/`. `pairs/` stack before over after, for review only.
- Tables come from `analyze_yields.py` and `analyze_cadence.py` in this folder. Paired differences are head minus base
  over the same (seed, day, walk); se = sd of the differences / sqrt(n); t = diff/se.
- One mishap: the first base crowd-alone run was killed and re-run; `raw/cadence-alone-base.txt` is the complete clean re-run (48 lines).

## What changes for the player
Walkers no longer walk through a charging dog, a chasing officer or the marching column: on the replayed day runs a
walker/figure overlap entry falls from 59 to 10 per run (about -83%) and walker-overlap seconds from 23.8 to 1.4.
Crowd cars stand for figures: seconds standing for a figure in the lane rise from 3.7 to 6.5 per run, car/figure overlap entries
fall 6.5 -> 4.5. Pedestrian bumps fall (7.6 -> 6.2 per run), which fits walkers stepping aside rather than into each other.
Cars move a little slower on average (86.8 -> 85.4 px/s) because more of them are standing.
Horns, strikes and junction stalls do not move measurably. The event figures themselves do not move at all.

## Figure days (`minty_quail_crowd_yields.gd`), per run, `base > head` where they differ
| seed | run | walker overlap entries | walker overlap seconds | car overlap entries | car seconds standing for figures | longest stand for a figure | longest box stand | box stalls | horns | bumps | strikes | pose hash |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4242 | charging_dog spot 0 | 8 > 0 | 1.6 > 0 | 0 | 0.3 > 0.53 | 0.3 > 0.53 | 2.67 | 0 | 2 | 10 | 0 | same |
| 4242 | charging_dog spot 1 | 1 > 0 | 0.27 > 0 | 0 | 0 | 0 | 1.03 | 0 | 0 | 0 | 0 | same |
| 4242 | charging_dog spot 2 | 2 > 0 | 0.27 > 0 | 0 | 0 | 0 | 1.37 | 0 | 0 | 2 | 0 | same |
| 4242 | policeman_giving_chase spot 0 | 1 > 0 | 0.4 > 0 | 0 | 0.43 | 0.43 | 1.87 | 0 | 1 | 7 | 0 | same |
| 4242 | policeman_giving_chase spot 1 | 0 | 0 | 0 | 0 | 0 | 2.8 | 0 | 1 | 0 | 0 | same |
| 4242 | policeman_giving_chase spot 2 | 0 | 0 | 0 | 0.43 | 0.43 | 1.63 | 0 | 0 | 1 | 0 | same |
| 4242 | police_patrol spot 0 | 0 | 0 | 0 | 0 | 0 | 0.03 | 0 | 0 | 8 | 0 | same |
| 4242 | police_patrol spot 1 | 0 | 0 | 0 | 0 | 0 | 1.83 | 0 | 0 | 2 | 0 | same |
| 4242 | police_patrol spot 2 | 0 | 0 | 0 | 0 | 0 | 1.4 | 0 | 0 | 4 | 0 | same |
| 4242 | cordon | 0 | 0 | 0 | 0 | 0 | 1.23 | 0 | 0 | 0 | 0 | same |
| 4242 | column | 29 > 8 | 14.5 > 2.03 | 0 | 1.63 | 1.63 | 1.23 | 0 | 0 | 1 | 0 | same |
| 1 | charging_dog spot 0 | 12 > 1 | 2.37 > 0.13 | 1 | 0 > 0.1 | 0 > 0.1 | 6.3 | 1 | 0 | 15 > 17 | 0 | same |
| 1 | charging_dog spot 1 | 19 > 4 | 7 > 0.33 | 1 | 0.57 | 0.57 | 0.03 | 0 | 0 | 4 | 0 | same |
| 1 | charging_dog spot 2 | 1 > 0 | 0.2 > 0 | 0 | 0 | 0 | 0.97 | 0 | 1 | 8 | 0 | same |
| 1 | policeman_giving_chase spot 0 | 2 > 0 | 0.77 > 0 | 0 | 0 | 0 | 10.9 | 1 | 1 | 15 | 0 | same |
| 1 | policeman_giving_chase spot 1 | 10 > 5 | 0.87 > 0.17 | 0 | 0 | 0 | 0.47 | 0 | 0 | 9 | 0 | same |
| 1 | policeman_giving_chase spot 2 | 0 | 0 | 0 | 0 | 0 | 0.53 | 0 | 0 | 9 | 0 | same |
| 1 | police_patrol spot 0 | 0 | 0 | 0 | 0 | 0 | 1.27 | 0 | 0 | 13 | 0 | same |
| 1 | police_patrol spot 1 | 0 | 0 | 0 | 0 | 0 | 0.2 | 0 | 0 | 9 | 0 | same |
| 1 | police_patrol spot 2 | 0 | 0 | 0 | 0 | 0 | 1.5 | 0 | 1 | 8 | 0 | same |
| 1 | cordon | 0 | 0 | 0 | 0 | 0 | 1.23 | 0 | 0 | 0 | 0 | same |
| 1 | column | 31 > 0 | 13.37 > 0 | 6 > 2 | 0 > 3.07 | 0 > 1.63 | 1.23 | 0 | 0 | 6 > 5 | 0 | same |

same hashes 22 of 22
| metric | base total | head total |
|---|---|---|
| walker_overlap_entries | 116 | 18 |
| walker_overlap_seconds | 41.6 | 2.67 |
| car_overlap_entries | 8 | 4 |
| car_seconds_standing_for_figures | 3.37 | 6.77 |
| max longest_stand_for_a_figure | 1.63 | 1.63 |
| max longest_box_stand | 10.9 | 10.9 |
| box_stalls | 2 | 2 |
| horns | 7 | 7 |
| bumps | 131 | 132 |
| strikes | 0 | 0 |
mean_car_speed 87.99511120510688 88.02406199370452
crowd_tick_usec 13101.459330808071 15373.543863636365
most_figures 4.045454545454546 4.045454545454546

Totals over the 22 runs: walker overlap entries 116 -> 18, walker overlap seconds 41.6 -> 2.67, car overlap entries 8 -> 4,
cars standing for a figure 3.37s -> 6.77s, longest stand for a figure 1.63s on both, longest stand in a junction box 10.9s on both,
junction stalls 2 -> 2, horns 7 -> 7, bumps 131 -> 132, strikes 0 -> 0, mean car speed 88.00 -> 88.02 px/s. The events' pose
hashes are identical in 22 of 22 runs. Probe's `crowd_tick_usec` (13.1 ms vs 15.4 ms mean) is measured under load and not
comparable across the two runs; use the cost probe below.
Runs that go the other way: seed 1 `charging_dog spot 0` has cars standing for the dog for 0.1s on head against 0 on base and bumps 15 -> 17;
seed 1 `column` has cars standing 3.07s on head against 0 and still 2 car/figure overlap entries on head (6 on base).

## Cadence, crowd alone (48 pairs, no event figures)
All 48 pairs are bit-identical on every metric (diff +0, se 0): box collisions, headways, bumps, horns, strikes, car speed.
## all 48 pairs
| metric | base mean | head mean | diff | se | t |
|---|---|---|---|---|---|
| box_collisions | 2.000 | 2.000 | +0.000 | 0.000 | +0.0 |
| box_entries_per_minute | 310.583 | 310.583 | +0.000 | 0.000 | +0.0 |
| bumps | 6.979 | 6.979 | +0.000 | 0.000 | +0.0 |
| headway_median | 356.228 | 356.228 | +0.000 | 0.000 | +0.0 |
| headway_min | 80.751 | 80.751 | +0.000 | 0.000 | +0.0 |
| headway_p10 | 137.881 | 137.881 | +0.000 | 0.000 | +0.0 |
| horns | 4.917 | 4.917 | +0.000 | 0.000 | +0.0 |
| mean_car_speed | 101.953 | 101.953 | +0.000 | 0.000 | +0.0 |
| strikes | 0.417 | 0.417 | +0.000 | 0.000 | +0.0 |


## Cadence with the day's events, head replaying base's walk (48 pairs, 24 `road`, 24 `walkers`)
Events' pose hashes (`events_chain`): **identical in 48 of 48** runs.
## all 48 pairs
| metric | base mean | head mean | diff | se | t |
|---|---|---|---|---|---|
| box_collisions | 1.917 | 2.354 | +0.438 | 0.338 | +1.3 |
| box_entries_per_minute | 267.979 | 262.396 | -5.583 | 2.297 | -2.4 |
| box_stalls | 0.583 | 0.708 | +0.125 | 0.148 | +0.8 |
| bumps | 7.562 | 6.229 | -1.333 | 0.383 | -3.5 |
| car_overlap_entries | 6.542 | 4.542 | -2.000 | 0.417 | -4.8 |
| car_overlap_per_minute | 6.542 | 4.542 | -2.000 | 0.417 | -4.8 |
| car_overlap_seconds | 4.670 | 4.275 | -0.395 | 0.557 | -0.7 |
| car_seconds_standing | 332.634 | 343.077 | +10.443 | 5.671 | +1.8 |
| car_seconds_standing_for_figures | 3.655 | 6.527 | +2.872 | 0.687 | +4.2 |
| headway_median | 317.586 | 314.643 | -2.943 | 6.632 | -0.4 |
| headway_min | 68.473 | 69.921 | +1.449 | 1.044 | +1.4 |
| headway_p10 | 109.168 | 106.676 | -2.492 | 2.065 | -1.2 |
| horns | 6.062 | 6.125 | +0.062 | 0.198 | +0.3 |
| longest_box_stand | 6.914 | 6.958 | +0.044 | 0.291 | +0.2 |
| longest_stand_for_a_figure | 1.708 | 1.867 | +0.160 | 0.191 | +0.8 |
| mean_car_speed | 86.768 | 85.394 | -1.374 | 0.499 | -2.8 |
| strikes | 0.375 | 0.375 | +0.000 | 0.042 | +0.0 |
| walker_overlap_entries | 59.167 | 10.042 | -49.125 | 6.807 | -7.2 |
| walker_overlap_per_minute | 59.167 | 10.042 | -49.125 | 6.807 | -7.2 |
| walker_overlap_seconds | 23.835 | 1.382 | -22.453 | 2.858 | -7.9 |


By walk:
## road 24 pairs
| metric | base mean | head mean | diff | se | t |
|---|---|---|---|---|---|
| box_collisions | 2.167 | 2.333 | +0.167 | 0.622 | +0.3 |
| box_entries_per_minute | 259.333 | 251.333 | -8.000 | 3.484 | -2.3 |
| box_stalls | 0.750 | 1.125 | +0.375 | 0.261 | +1.4 |
| bumps | 0.000 | 0.000 | +0.000 | 0.000 | +0.0 |
| car_overlap_entries | 6.083 | 4.167 | -1.917 | 0.558 | -3.4 |
| car_overlap_per_minute | 6.083 | 4.167 | -1.917 | 0.558 | -3.4 |
| car_overlap_seconds | 4.776 | 4.011 | -0.765 | 0.507 | -1.5 |
| car_seconds_standing | 393.282 | 411.472 | +18.190 | 9.004 | +2.0 |
| car_seconds_standing_for_figures | 3.935 | 7.556 | +3.621 | 1.193 | +3.0 |
| headway_median | 332.118 | 329.808 | -2.310 | 9.728 | -0.2 |
| headway_min | 71.242 | 71.199 | -0.043 | 1.257 | -0.0 |
| headway_p10 | 114.525 | 109.951 | -4.574 | 3.221 | -1.4 |
| horns | 8.000 | 7.917 | -0.083 | 0.318 | -0.3 |
| longest_box_stand | 9.510 | 10.139 | +0.629 | 0.290 | +2.2 |
| longest_stand_for_a_figure | 1.564 | 1.892 | +0.328 | 0.220 | +1.5 |
| mean_car_speed | 82.256 | 80.415 | -1.841 | 0.770 | -2.4 |
| strikes | 0.417 | 0.417 | +0.000 | 0.000 | +0.0 |
| walker_overlap_entries | 53.292 | 9.958 | -43.333 | 9.185 | -4.7 |
| walker_overlap_per_minute | 53.292 | 9.958 | -43.333 | 9.185 | -4.7 |
| walker_overlap_seconds | 22.233 | 1.503 | -20.731 | 4.015 | -5.2 |


## walkers 24 pairs
| metric | base mean | head mean | diff | se | t |
|---|---|---|---|---|---|
| box_collisions | 1.667 | 2.375 | +0.708 | 0.272 | +2.6 |
| box_entries_per_minute | 276.625 | 273.458 | -3.167 | 2.987 | -1.1 |
| box_stalls | 0.417 | 0.292 | -0.125 | 0.125 | -1.0 |
| bumps | 15.125 | 12.458 | -2.667 | 0.667 | -4.0 |
| car_overlap_entries | 7.000 | 4.917 | -2.083 | 0.631 | -3.3 |
| car_overlap_per_minute | 7.000 | 4.917 | -2.083 | 0.631 | -3.3 |
| car_overlap_seconds | 4.564 | 4.539 | -0.025 | 1.000 | -0.0 |
| car_seconds_standing | 271.986 | 274.682 | +2.696 | 6.718 | +0.4 |
| car_seconds_standing_for_figures | 3.375 | 5.499 | +2.124 | 0.674 | +3.2 |
| headway_median | 303.053 | 299.478 | -3.575 | 9.223 | -0.4 |
| headway_min | 65.703 | 68.644 | +2.941 | 1.637 | +1.8 |
| headway_p10 | 103.811 | 103.400 | -0.411 | 2.582 | -0.2 |
| horns | 4.125 | 4.333 | +0.208 | 0.241 | +0.9 |
| longest_box_stand | 4.318 | 3.778 | -0.540 | 0.483 | -1.1 |
| longest_stand_for_a_figure | 1.851 | 1.843 | -0.008 | 0.312 | -0.0 |
| mean_car_speed | 91.280 | 90.372 | -0.908 | 0.636 | -1.4 |
| strikes | 0.333 | 0.333 | +0.000 | 0.085 | +0.0 |
| walker_overlap_entries | 65.042 | 10.125 | -54.917 | 10.103 | -5.4 |
| walker_overlap_per_minute | 65.042 | 10.125 | -54.917 | 10.103 | -5.4 |
| walker_overlap_seconds | 25.436 | 1.261 | -24.175 | 4.124 | -5.9 |

Per-run sign counts over the 48 pairs (up / down / same): strikes 2/2/44 (total 18 -> 18); horns 15/11/22 (291 -> 294);
box stalls 5/4/39 (28 -> 34); box collisions 14/5/29 (92 -> 113); bumps 3/17/28 (363 -> 299);
car overlap entries 4/32/12 (314 -> 218); standing for figures 36/6/6; walker overlap entries 48 of 48 pairs fall.
Longest junction-box stand is 60.0s (the whole window) in the same two `road` runs (2222 and 8008, day 1) on both revisions, and 53s in a third (4242): a pre-existing stall the change neither causes nor cures.

## Cost (`m159_crowd_tick_cost.gd`, whole-tick mean, microseconds per tick, indicative only)
Base ran first, then head, with other Godot jobs running; the probe's own chains of crowd state are identical on both revisions.
| agents | walk | reps | base mean us/tick | head mean us/tick | change |
|---|---|---|---|---|---|
| 234 | street | 6 | 3253 | 3463 | +6% |
| 234 | walkers | 6 | 3294 | 3600 | +9% |
| 50 | street | 6 | 900 | 1113 | +24% |
| 50 | walkers | 6 | 900 | 1144 | +27% |
| 86 | street | 6 | 1532 | 1837 | +20% |
| 86 | walkers | 6 | 1524 | 1858 | +22% |

Head costs roughly 0.2 to 0.3 ms more per tick (+6 to +9% at 234 agents, +20 to +27% at 50 and 86), the same added amount at every size,
in all 36 pairs of repetitions. Only the absolute figure moves with load; a constant added cost per tick is consistent
with the new per-tick gathering and per-body asking.

## Pictures
Eight pairs, `before/` (base) against `after/` (head), 1280x720, same recipe and moment; `pairs/` stack them (before on top).
- `dog-2.3`: dog far from the walkers; the two frames are the same scene. It shows nothing of the yielding.
- `dog-2.5`: dog mid-block; walkers near it are in about the same places in both. Shows little; no overlap in either.
- `dog-2.8`: dog at the right of the crossing; no walker is on the dog in either, the crowd differs slightly. Does not clearly show yielding.
- `dog-3.3`: dog beside the right-hand walkers; a walker stands close below it in both and the crowd differs elsewhere. Does not clearly show yielding.
- `dog-3.8`: the clearest dog pair: before, a walker stands over the dog at the right edge; after, the walker is off to the side and the dog runs through a gap. Shows yielding.
- `car-2.7`: dog crossing the lane, car approaching; the car is somewhat farther back in the after frame. Shows a slightly earlier stand.
- `car-2.85`: before, the car sits against the dog's rear (overlapping it); after, the car stands a clear car-length back. Shows the car yielding.
- `car-3.0`: before, the dog is drawn over the car's bonnet beside the stroller; after, the car stands well back and the dog is clear. Shows the car yielding.
The dog stills are single frames of a crowded street where the head's crowd also differs elsewhere (crowd state diverges once walkers yield), so
they illustrate rather than prove; the counts above carry the claim.

## Conclusion
- **For the player:** walkers get out of the way of an oncoming event figure (overlap entries 59 -> 10 per day run) and cars stop short of one
  (stand seconds nearly double), with the figures' own paths untouched.
- **Real, not noise** (paired t well past 3 with the same sign in most pairs): walker overlap entries and seconds (t about -7 to -8), car/figure
  overlap entries (t -4.8; 32 of 48 pairs fall), seconds cars stand for a figure (t +4.2; 36 of 48 rise), bumps (t -3.5; 17 down against 3 up).
- **Probably a consequence, borderline:** mean car speed (t -2.8) and box entries per minute (t -2.4): more cars standing, within what the number of metrics
  tested (about 20 per table) would produce by chance at |t| about 2.5, so say "consistent with" not "shown".
- **Noise, flat:** horns (+0.06 +/- 0.20 per run), strikes (0.375 both, 44 of 48 pairs identical, 2 up and 2 down), headways (|t| at most 1.2 on the
  p10, 1.4 on the minimum), box stalls (+0.125 +/- 0.148), longest stand in a box (+0.04 +/- 0.29), longest stand for a figure (+0.16 +/- 0.19), car overlap seconds (-0.4 +/- 0.6).
- **Unresolved and worth a reviewer's look:** junction-box collisions rise 1.92 -> 2.35 per run (92 -> 113 total; 14 pairs up, 5 down;
  +0.44 +/- 0.34, t 1.3, driven by the `walkers` walk, t 2.6, 24 pairs). Not significant at 48 pairs, but the sign test (14 against 5) is borderline, so this is not shown to be flat.
  Cars still overlap figures about 4.5 times per run on head and the overlap seconds did not fall (4.7 -> 4.3, se 0.56): cars yield *earlier* but are still reached by
  fast figures, so overlap entries fall without the time spent overlapping falling much.
- **What should not change, did not:** the events' poses match in 48 of 48 replayed runs and 22 of 22 figure-day runs; crowd-alone runs are bit-identical in all 48;
  horns, strikes and stalls are flat within noise; the longest box stand (60.0s on two `road` runs) is the same on both revisions.

## Limits
- One machine, concurrent with another agent's Godot runs: timings are indicative; counts are deterministic and unaffected.
- 12 seeds, 2 days, 2 walks, 1800 ticks (60s) each; the figure days use seeds 4242 and 1 only (22 runs; per-run, not tested statistically).
- Under replay the walk is base's; head's crowd diverges anyway, so run-level crowd differences are chaotic and only the means over 48 pairs mean anything; per-run values of one metric are not comparable.
- About 20 metrics tested per table with no multiplicity correction; only |t| of 3 or more is called real.
- The picture pairs are single frames; the crowd around the figure differs between before and after, and dog-2.3, 2.5, 2.8 and 3.3 show no clear difference.
- Base's `m159` timing ran before head's, so drift under load is not separated from the head effect; the added cost is the same at every agent count in every repetition, which argues against drift alone.
