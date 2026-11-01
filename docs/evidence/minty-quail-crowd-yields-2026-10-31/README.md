# C2b: the crowd yields to event figures, measured (PR #895, minty-quail shared-components C2b)

> **Kept in the repository:** this README, the tables (`yields.md`, `alone.md`, `events.md`, `cost.md`, the full per-road/per-walk
> splits among them), the analysis scripts, `walks/` (the 48 recorded walks the replay runs read), `raw/` gzipped (the probes' output
> and the two probe diffs), and `pairs/` (stills made on an earlier revision pair, see "Pictures").

Claim: with C2b the crowd gives way to event figures, event figures keep their courses, and nothing the crowd does without a figure changes.
Counts are deterministic; timings come from one machine that other jobs also used. Limits are at the end.

## Provenance
- **Head:** `f9e8253062090eeabb80f02f56824433a57ab2a4` (branch `feature/minty-quail-shared-c2b`), checkout from `tools/agent-setup.sh --detach f9e82530 <name>-head`.
  It includes the review fixes: a figure that goes leaves the list of moves at once (`EventInstance.take_out()`), so there are no ghost moves.
- **Base, the game before C2b:** `21171ee0880aadfcba2c72b8764954745cb5a81c` ("orchestrating: no more side-by-side model runs for now (#907)", `origin/main`),
  checkout from `--detach origin/main <name>-base`; it is an ancestor of head, so the two differ by the PR only.
- **Probes.** Head's `tests/probes/minty_quail_crowd_yields.gd` and `minty_quail_crowd_cadence.gd` run unchanged on head. On base they were copied in, uncommitted:
  - the cadence probe is byte-identical to head's;
  - the yields probe differs by `raw/base-yields-probe.diff` (47 lines): base has no `SeparationPass`, `stood_round` or `keeping_their_course()`, so the copy
    restates head's rule with head's numbers (`NEVER_MOVED`, `UNDER_WAY_TICKS` = 10, `PLACEMENT_STEP` = 32), takes "stood round" from the ids of the 24 rows whose
    `EventDef.stands_as` is `SOMETHING` on head, walks `moves.all()` and keeps the moves that do not yield and have a body; and
  - **ghosts are skipped in the copy**: a move counts only if its event is a live instance (valid, not queued for deletion, not finished, in the tree) or one of the cordon's officers.
  The counters keep the meanings in the yields probe's header. On head the unmodified probe counts every move on the list, which is the live ones only now: `most_figures` is the same on both.
- **Commands** (from each checkout; output in `raw/`; `<out>` is a fresh directory):
  1. `tools/test.sh probes/minty_quail_crowd_yields.gd` (seeds 4242 and 1, the probe's default) -> `raw/yields-*.txt.gz`; 22 runs.
  2. `CADENCE_FRAMES=1 CADENCE_SEEDS=1001,1111,2002,2222,3003,4242,478156010,5005,6006,7007,8008,9009 tools/test.sh probes/minty_quail_crowd_cadence.gd` -> `raw/cadence-alone-*.txt.gz`;
     48 runs = 12 seeds x days 1 and 9 x walks `road` and `walkers`, 60s each.
  3. The same with `CADENCE_EVENTS=1`; base with `CADENCE_RIG_RECORD=<out>/walks` (those 48 files are `walks/`), then head with `CADENCE_RIG_REPLAY=<out>/walks` -> `raw/cadence-events-*.txt.gz`.
  4. `tools/test.sh probes/m159_crowd_tick_cost.gd`, base then head -> `raw/cost-*.txt.gz`.
  5. Turn-rounds: a scratch copy of the cadence probe (`raw/turns-probe.diff`: 16 added lines) run as 3 on both with `CADENCE_RIG_REPLAY=<out>/walks` -> `raw/turns-*.txt.gz`.
- **Order:** the base batch (1 to 4) ran to its end, then the head batch (1 to 4), then the turn-round runs, one process at a time; other jobs may have used the machine.
- Tables: `analyze_yields.py` (needs `raw/yields-base.txt` and `raw/yields-head.txt`, ungzipped) and `analyze_cadence.py <base> <head>`. Paired difference = head minus base over the same (seed, day, walk);
  se = sd of the differences / sqrt(n); t = diff / se. The cost table is the same arithmetic over the 6 pairs (2 seeds x 3 repetitions) per size and walk, `whole` mode.

## What changes for the player
- **Walkers no longer walk into a figure under way or an object or vehicle standing in the street.** With the day's events live, walker/figure overlap entries go from 52.3 to 14.8 a run and overlap seconds from 28.6 to 12.8 (47 of 48 pairs fall).
  Of what remains on the figure days, 39 of 48 entries and 40 of 41 seconds are walkers and the marching column (day 13), which is the one head-on case the design allows to brush past; the other remaining overlaps in the cadence runs are not attributed.
- **Crowd cars stand for a figure in their lane.** Seconds cars stand for a figure: 2.4 to 5.6 a run (38 of 48 pairs up, 2 down); car/figure overlap entries 3.4 to 1.2 (34 down, 1 up) and overlap seconds 2.4 to 1.1.
  The longest single stand for a figure rises from 1.0 to 1.6 s on average (max 6.2 to 7.9 s): a car now waits behind a figure instead of driving into it.
- **Pedestrian bumps fall** 7.5 to 6.3 a run (14 down, 1 up). Cars are somewhat slower on average, 86.5 to 84.6 px/s, as more of them stand.
- **Event figures do not change:** poses identical in 48 of 48 replayed runs and 22 of 22 figure-day runs.
- **The crowd with no figure does not change:** 48 of 48 pairs bit-identical on every metric, and the cost probe's chains over agents (72 runs) identical.

## Figure days (`minty_quail_crowd_yields.gd`), per run, `base > head` where they differ
| seed | run | walker overlap entries | walker overlap seconds | car overlap entries | car seconds standing for figures | longest stand for a figure | longest box stand | box stalls | horns | bumps | strikes | pose hash |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4242 | charging_dog spot 0 | 4 > 0 | 1.07 > 0 | 0 | 0.3 > 0.53 | 0.3 > 0.53 | 2.67 | 0 | 2 | 10 | 0 | same |
| 4242 | charging_dog spot 1 | 1 > 0 | 0.27 > 0 | 0 | 0 | 0 | 1.03 | 0 | 0 | 0 | 0 | same |
| 4242 | charging_dog spot 2 | 2 > 0 | 0.27 > 0 | 0 | 0 | 0 | 1.37 | 0 | 0 | 2 | 0 | same |
| 4242 | policeman_giving_chase spot 0 | 1 > 0 | 0.4 > 0 | 0 | 0.43 | 0.43 | 1.87 | 0 | 1 | 7 > 8 | 0 | same |
| 4242 | policeman_giving_chase spot 1 | 0 | 0 | 0 | 0 | 0 | 2.8 | 0 | 1 | 0 | 0 | same |
| 4242 | policeman_giving_chase spot 2 | 0 | 0 | 0 | 0.43 | 0.43 | 1.63 | 0 | 0 | 1 | 0 | same |
| 4242 | police_patrol spot 0 | 3 > 0 | 2.33 > 0 | 0 | 0 | 0 | 0.03 | 0 | 0 | 8 | 0 | same |
| 4242 | police_patrol spot 1 | 3 > 0 | 2.73 > 0 | 0 | 0 | 0 | 1.83 | 0 | 0 | 2 | 0 | same |
| 4242 | police_patrol spot 2 | 3 > 0 | 2.5 > 0 | 0 | 0 | 0 | 1.4 | 0 | 0 | 4 | 0 | same |
| 4242 | cordon | 0 | 0 | 0 | 0 | 0 | 1.23 | 0 | 0 | 0 | 0 | same |
| 4242 | column | 37 > 11 | 24.93 > 11.37 | 0 | 1.63 | 1.63 | 1.23 | 0 | 0 | 1 > 2 | 0 | same |
| 1 | charging_dog spot 0 | 4 > 0 | 1.07 > 0 | 1 | 0 > 0.1 | 0 > 0.1 | 6.3 | 1 | 0 | 15 | 0 | same |
| 1 | charging_dog spot 1 | 16 > 4 | 5.73 > 0.33 | 1 | 0.57 | 0.57 | 0.03 | 0 | 0 | 4 | 0 | same |
| 1 | charging_dog spot 2 | 1 > 0 | 0.2 > 0 | 0 | 0 | 0 | 0.97 | 0 | 1 | 8 | 0 | same |
| 1 | policeman_giving_chase spot 0 | 1 > 0 | 0.37 > 0 | 0 | 0 | 0 | 10.9 | 1 | 1 | 15 | 0 | same |
| 1 | policeman_giving_chase spot 1 | 10 > 5 | 0.87 > 0.17 | 0 | 0 | 0 | 0.47 | 0 | 0 | 9 | 0 | same |
| 1 | policeman_giving_chase spot 2 | 0 | 0 | 0 | 0 | 0 | 0.53 | 0 | 0 | 9 | 0 | same |
| 1 | police_patrol spot 0 | 3 > 0 | 2.43 > 0 | 0 | 0 | 0 | 1.27 | 0 | 0 | 13 | 0 | same |
| 1 | police_patrol spot 1 | 9 > 0 | 7.9 > 0 | 0 | 0 | 0 | 0.2 | 0 | 0 | 9 | 0 | same |
| 1 | police_patrol spot 2 | 5 > 0 | 3.77 > 0 | 0 | 0 | 0 | 1.5 | 0 | 1 | 8 | 0 | same |
| 1 | cordon | 0 | 0 | 0 | 0 | 0 | 1.23 | 0 | 0 | 0 | 0 | same |
| 1 | column | 54 > 28 | 42 > 28.87 | 6 > 2 | 0 > 2.27 | 0 > 1.63 | 1.23 | 0 | 0 | 6 > 5 | 0 | same |

same hashes 22 of 22
| metric | base total | head total |
|---|---|---|
| walker_overlap_entries | 157 | 48 |
| walker_overlap_seconds | 98.83 | 40.73 |
| car_overlap_entries | 8 | 4 |
| car_seconds_standing_for_figures | 3.37 | 5.97 |
| max longest_stand_for_a_figure | 1.63 | 1.63 |
| max longest_box_stand | 10.9 | 10.9 |
| box_stalls | 2 | 2 |
| horns | 7 | 7 |
| bumps | 131 | 132 |
| strikes | 0 | 0 |
mean_car_speed 87.99511120510688 88.04180062850715
crowd_tick_usec 2934.866388888889 4428.405239898989
most_figures 32.81818181818182 32.81818181818182

Total over the 22 runs: walker overlaps 157 to 48 entries and 98.8 to 40.7 s (the column alone: 91 to 39 entries, 66.9 to 40.2 s); car overlaps 8 to 4; cars standing for a figure 3.4 to 6.0 s; horns 7 to 7; box stalls 2 to 2;
strikes 0 to 0; bumps 131 to 132. Runs that go the other way: seed 4242 `policeman_giving_chase spot 0` and `column` have one more bump each on head; seed 1 `charging_dog spot 0` has cars standing for the dog 0.1 s on head against 0.
`crowd_tick_usec` (2.9 ms base, 4.4 ms head, 32.8 figures at once on average) is wall-clock in the probe on a loaded machine and is not comparable across the two batches; see the cost table.

## Cadence, crowd alone (48 pairs, no event figures)
Every metric identical in all 48 pairs (diff +0, se 0): box collisions, headways, bumps, horns, strikes, car speed (`alone.md`).

## Cadence with the day's events, head replaying base's walk (48 pairs, 24 `road`, 24 `walkers`)
Events' pose hashes (`events_chain`): **identical in 48 of 48**. All 48 pairs (`events.md` has the split by walk):
| metric | base mean | head mean | diff | se | t |
|---|---|---|---|---|---|
| agents | 142.000 | 142.000 | +0.000 | 0.000 | +0.0 |
| box_collisions | 2.042 | 2.125 | +0.083 | 0.430 | +0.2 |
| box_entries_per_minute | 267.146 | 262.604 | -4.542 | 2.724 | -1.7 |
| box_stalls | 0.521 | 0.792 | +0.271 | 0.165 | +1.6 |
| bumps | 7.458 | 6.312 | -1.146 | 0.377 | -3.0 |
| car_overlap_entries | 3.417 | 1.208 | -2.208 | 0.386 | -5.7 |
| car_overlap_per_minute | 3.417 | 1.208 | -2.208 | 0.386 | -5.7 |
| car_overlap_seconds | 2.438 | 1.059 | -1.378 | 0.630 | -2.2 |
| car_seconds_standing | 333.257 | 347.281 | +14.024 | 7.193 | +1.9 |
| car_seconds_standing_for_figures | 2.391 | 5.592 | +3.201 | 0.608 | +5.3 |
| headway_median | 316.599 | 319.236 | +2.636 | 6.919 | +0.4 |
| headway_min | 68.851 | 69.246 | +0.394 | 0.827 | +0.5 |
| headway_p10 | 108.508 | 106.285 | -2.224 | 3.339 | -0.7 |
| horns | 6.271 | 6.146 | -0.125 | 0.205 | -0.6 |
| longest_box_stand | 6.728 | 7.928 | +1.200 | 0.522 | +2.3 |
| longest_stand_for_a_figure | 1.025 | 1.594 | +0.569 | 0.165 | +3.4 |
| mean_car_speed | 86.542 | 84.635 | -1.906 | 0.841 | -2.3 |
| most_figures | 43.979 | 44.000 | +0.021 | 0.021 | +1.0 |
| steps_on_the_tick | 1.000 | 1.000 | +0.000 | 0.000 | +0.0 |
| strikes | 0.396 | 0.438 | +0.042 | 0.051 | +0.8 |
| ticks | 1800.000 | 1800.000 | +0.000 | 0.000 | +0.0 |
| walker_overlap_entries | 52.292 | 14.812 | -37.479 | 5.132 | -7.3 |
| walker_overlap_per_minute | 52.292 | 14.812 | -37.479 | 5.132 | -7.3 |
| walker_overlap_seconds | 28.600 | 12.788 | -15.812 | 2.197 | -7.2 |

Per-run counts over the 48 pairs (up / down / same, totals base to head): strikes 4/2/42 (19 to 21); horns 12/12/24 (301 to 295); box stalls 7/2/39 (25 to 38);
box collisions 13/10/25 (98 to 102); longest box stand 19/9/20 (sum of the 48 longest stands 323 to 381 s); bumps 1/14/33 (358 to 303); car overlap entries 1/34/13 (164 to 58);
car overlap seconds 7/31/10 (117 to 51); seconds standing for figures 38/2/8 (115 to 268); longest stand for a figure 30/2/16; walker overlap entries 1/47/0 (2510 to 711).
A 60 s (the whole window) stand in a junction box is in the same two `road` runs on both revisions (seeds 2222 and 8008, day 1); seed 4242 `road` stands 53 s on both; seed 3003 `road` goes from 26 s to 41 s.

## Turn-rounds behind a parked figure, and what cars in boxes stand for
`box-attribution/` (its own README, analysis and probe diffs) answers both on the same 48 replayed pairs, with the cadence probe instrumented.
- **Turn-rounds.** The scratch counter above (`raw/turns-probe.diff`) counted only `STOPPED_NO_ROOM`, the last-resort reversal on the spot, which an ordinary divert does not set, so its count says nothing about the parked-figure rule. Counting the diverts `blocked_by_a_figure()` triggers instead: 0 in the 48 event runs, since days 1 and 9 never park a figure in a crowd car's lane. In a scene built for it (a car at 130 px/s meeting a vehicle that parks in its lane), the car drives through it on base (33 overlapping frames) and on head brakes, takes the ordinary turn-round arc and heads north by 1.85 s with no overlap.
- **Box stands.** Every tick a car stands in a box is put down to what the first car of its queue waits for. Figures are 58 of head's 1,396 s (0 of base's 1,193), in 45 stands of at most 2.1 s, mostly behind the dog walker and the shouting man while they move; the one patrol-car case is 1.0 s. Every stand of 5 s or more is a queue at a box, a zebra or the checkpoint gate, seed 3003's 41 s included. So figures do not explain the stall rise; head's extra stalls come from timing shifted by short stops for walkers, and no control run separates a real average effect from chaotic divergence.

## Cost (`m159_crowd_tick_cost.gd`, whole-tick mean, microseconds per tick, 6 pairs each)
| agents | walk | pairs | base us/tick | head us/tick | diff | se | pairs up |
|---|---|---|---|---|---|---|---|
| 234 | walkers | 6 | 3809 | 4343 | +535 (+14%) | 236 | 5 of 6 |
| 234 | street | 6 | 3559 | 4096 | +537 (+15%) | 175 | 5 of 6 |
| 86 | walkers | 6 | 1934 | 1914 | -20 (-1%) | 58 | 3 of 6 |
| 86 | street | 6 | 1665 | 1816 | +152 (+9%) | 77 | 4 of 6 |
| 50 | walkers | 6 | 1056 | 1200 | +144 (+14%) | 61 | 4 of 6 |
| 50 | street | 6 | 1093 | 1193 | +99 (+9%) | 144 | 4 of 6 |

The probe starts no events, so no figure is on the map: it measures the added per-tick cost with nothing to give way to (gathering the figures, asking per body), not the cost with the 30 to 50 figures a day has (`most_figures` above).
At 234 agents head costs about 0.54 ms (+14 to +15%) more in both walks, 5 of 6 pairs up each (t about 3.1 and 2.3); at 50 and 86 agents the differences (-1% to +14%) are within their standard errors, so noise, with an added cost
that is consistent with the same fixed amount (0.1 to 0.5 ms). Run-to-run spread within one revision is as large as 30%.

## Pictures
`pairs/` stacks before over after stills made on the earlier revision pair (base `70ef44c6`, head `108ad850`); they were not remade here and the counts above carry the claim.

`pairs-fixes/` holds side-by-side stills (base left, head right) made on base `21171ee0` and head `f9e82530`, the revisions measured above, with their recipes and a line per pair in `pairs-fixes/PICTURES.md`. Four moments show the yielding: day 13's column (clearest, at 1.4s), the policeman giving chase, a crowd car held behind the charging dog, and the dog itself (weakly). Two do not: a market stall and café tables fill the footway, so walkers turn back from them on base as well; and no car could be brought behind the parked fire truck, so a turn-round behind a parked figure is not pictured and rests on the tests in `tests/test_crowd_yields.gd`.

## Conclusion
- **For the player:** walkers step round an oncoming figure or a standing object and cars stop for a figure in their lane; the figures' own paths are untouched. Overlaps fall by about 70% for walkers (entries 52 to 15 a run) and 65% for cars (3.4 to 1.2).
- **Real** (|t| at least 3, same sign in most pairs): walker overlap entries and seconds (t -7.3, -7.2), car overlap entries (t -5.7), seconds cars stand for a figure (t +5.3), bumps (t -3.0, 14 down against 1 up),
  longest stand for a figure (t +3.4; a car waits where it used to drive in).
- **Borderline, probably a consequence, say "consistent with":** mean car speed (t -2.3), car overlap seconds (t -2.2, 31 pairs down against 7), box entries per minute (t -1.7), cars standing in all (t +1.9): more cars stand, and about 22 metrics are tested.
- **Flat (noise):** horns (-0.13 +/- 0.21; 12 up, 12 down), box collisions (+0.08 +/- 0.43; 13 up, 10 down), headways (|t| at most 0.7), strikes (+0.04 +/- 0.05; 4 up, 2 down, 42 identical: 19 to 21 in total, which 48 runs cannot tell from no change).
- **Not shown flat:** junction-box stalls rise 25 to 38 in total (0.52 to 0.79 a run, t +1.6, 7 pairs up, 2 down; the `road` walk +0.54, t 1.8) and the longest box stand rises by 1.2 s a run (t +2.3, 19 up, 9 down; mostly the `road` walk, one run 26 to 41 s).
  Neither reaches t 3, and the sign test on stalls (7 against 2) is p about 0.2, but both point the same way and have a mechanism (a car that entered a box stands in it for a figure that comes into its lane after it entered), so a small real rise cannot be ruled out. Treat as open.
- **What must not change, and did not:** the events' poses (48 of 48, 22 of 22), the crowd alone (48 of 48 bit-identical, 72 of 72 cost chains), horns, strikes (within noise), the 60 s box stands (same two runs on both).
- **Against the first measurement:** the first evidence counted ghost moves; its walker overlap (59 to 10) and car overlap (6.5 to 4.5) were a third to a half too high on both sides. Directions and significance are the same except box collisions, which are flat here (the first said 1.92 to 2.35, unresolved).

## Limits
- One machine with other jobs possibly running: counts are deterministic and unaffected, the cost numbers are indicative, and the probe's `crowd_tick_usec` is not used.
- 12 seeds, 2 days, 2 walks, 60 s each; the figure days use seeds 4242 and 1 (22 runs, per run, not tested).
- Under replay the walk is base's; head's crowd diverges anyway, so single-run values of a metric are chaotic and only the means over 48 pairs mean anything.
- About 22 metrics per table with no multiplicity correction; only |t| of 3 or more is called real. The 48 pairs are 12 seeds x 4 conditions, not independent draws of the city.
- Walker overlaps now count standing objects and vehicles (café tables, vans) as figures, since walkers give way to those; the base probe copy takes that set from head's ids by hand.
- The parked-figure turn-round never occurs in the 48 event runs; one built scene shows it. The cost probe has no figures.
- The pictures are not remade here.
