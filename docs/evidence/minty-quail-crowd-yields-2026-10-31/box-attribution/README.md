# C2b delta review, findings 1 and 2: what cars stand for in boxes, and one turn-round behind a parked figure

Head `0d753acf`, base `21171ee0`. All runs headless, one process at a time, checkouts made with `tools/agent-setup.sh --detach` and removed after. No committed code.

## 1. Junction stalls and box stands

### Commands
- Head checkout `m3-head` with `raw/attr-probe.diff` applied to `tests/probes/minty_quail_crowd_yields.gd` (adds the attribution to `Meeting`, which the cadence probe uses). Base checkout `m3-base`: head's cadence probe copied in, head's yields probe + the evidence's `raw/base-yields-probe.diff` (ghost-skipping base copy) + `raw/attr-probe.diff`.
- Both: `CADENCE_FRAMES=1 CADENCE_SEEDS=1001,1111,2002,2222,3003,4242,478156010,5005,6006,7007,8008,9009 CADENCE_EVENTS=1 CADENCE_RIG_REPLAY=<evidence>/walks tools/test.sh probes/minty_quail_crowd_cadence.gd` -> `raw/attr-{base,head}.txt.gz` (48 runs each, base replaying its own recorded walks, head the same).
- `python3 analyze_attr.py raw/attr-base.txt raw/attr-head.txt > analysis.md` (full tables, including every stall).
- Replay reproduces the evidence: box_stalls 25 (base) and 38 (head); the attribution's own count of stands of 150 ticks or more matches (25 and 38); seed 3003 `road` longest stand 26.3 s base, 40.9 s head.

### What the instrumentation does (`raw/attr-probe.diff`)
Every tick, for every crowd car standing (speed under 1 px/s) inside a box, it reads the car's own brake components (the terms `CarStrategy._give_way()` takes the minimum of) and counts one as "binding" when the speed it asks for is under 8 px/s: event figure (`_distance_to_a_figure()`), parked figure (`road_before_a_parked_figure()`), closed tile, zebra, gate hold, box hold (`junction_hold`, which is the junction rule and the signal together: the probe cannot tell a red light from an occupied box), and "car" (`_following_speed()`). A car held by "car" is followed to its leader in the lane (same lane key, the gap matching `gap_ahead`) and the leader's cause is the root cause, recursively. A figure cause is given its row and state (moving, standing, parked) by the nearest figure ahead in the lane. Each stand (consecutive standing ticks in a box, the probe's own definition) records its causes, whether a figure was in view 300 px ahead when the car entered the box, and how long it was in the box before it stood.

### Seconds a car stood in a box, by root cause (48 runs)
| root cause | base s | head s |
|---|---|---|
| waiting at a box (junction rule or signal) at the root of the queue | 721.9 | 889.4 |
| checkpoint gate | 215.8 | 200.0 |
| car ahead, leader not found (queue closing on itself or a landing booked ahead) | 148.9 | 147.3 |
| zebra, someone waiting | 65.3 | 56.3 |
| car ahead that is moving slowly | 39.6 | 44.5 |
| **event figure** | **0** | **57.9** |
| closed tile / other | 1.4 | 0.5 |
| total | 1193 | 1396 |

Head's figure seconds by row (state of the figure while the car stood): dog_walker moving 26.7, homeless_yeller moving 26.5, police_patrol moving 1.6, loose_dog moving 1.1, chatting_mother moving 0.8, cat_dash 0.1, roadblock standing 0.1 (0.9 s found no figure by geometry). On base the cars do not stand for figures, so the figure column is 0 by construction; by geometry alone (a figure within 120 px ahead while the car stood) base has only the checkpoint gate (138.7 s) and unmapped standing objects (76.4 s).

### Answers
- **How much of the rise is figures, and which rows?** None of the stalls. 57.9 s of 1396 s box-standing (4.1%) is stood for a figure, in 45 separate stands, all of them short: the whole-stand length is median 1.3 s, p90 1.8 s, max 2.1 s (figure-rooted seconds: max 1.9 s). The rows are the moving walkers: dog_walker, homeless_yeller (together 53 of the 58 s), then police_patrol 1.6 s, loose_dog 1.1 s. Of the 38 stands of 5 s or more on head, **0** have a figure as root cause (0% of ticks each); 34 are queues at a box, 3 end in a leader the probe could not find, 1 is a zebra. The suspected case (a car already in a box when a figure comes into its lane, for example the patrol car stopping past the box) occurs in 45 stands: of the 33 that have 1 s or more of figure, 28 had no figure in view when the car entered the box; none lasts beyond 2.1 s; the one patrol-car case (seed 7007 day 9) is 1.0 s. No car stood in a box for a *parked* figure in these runs.
- **Is seed 3003's 41 s stand a figure?** No. It is 40.9 s (1226 ticks) running to the end of the run; every one of its ticks has `box_or_signal` as the root: the car stands in the box behind a car queued at the stop line of the next box (the queue ahead is held by the junction rule). Base's 26.3 s stand on the same run has the same root. No figure was ever near it.
- **Distribution of stand lengths** (all stands in a box of 0.5 s or more): base 303, head 347; median 1.2 s on both; p90 4.1 s base, 5.3 s head; 5 s or more: 25 base, 38 head; 30 s or more: 13 base, 15 head. Figure stands (head only): median 1.3 s, p90 1.8 s, max 2.1 s.
- **So what is the rise?** Not a car standing in a box for a figure, but a different gridlock outcome in the same queues. The head-minus-base stalls sit in a few runs: seed 4242 `road` 5 -> 11, seed 1001 `road` 0 -> 4 (+1 on day 9), seed 478156010 `walkers` 0 -> 2, seed 3003 `road` 1 -> 2, seed 9009 `walkers` 0 -> 1, seed 7007 `road` day 9 0 -> 1; down: seed 6006 `walkers` 3 -> 1, seed 2222 `walkers` 1 -> 0. Every stall is the queue-at-a-box root on both revisions, and with no figures the two revisions are bit-identical (48 of 48). The figure's only possible effect is therefore indirect: a car stopped 1 to 2 s for a dog walker or a homeless man shifts the timing of the cars behind it, and which cars meet at a box afterwards differs (chaotic divergence). The evidence's own statement that the mechanism is a car in a box standing for a figure is not borne out; whether the indirect shift raises stalls on average (or only moves them around) cannot be told from 48 pairs (t +1.6 in the evidence). I did not run a control (for example head with the figures' stopping time randomised) to tell the two apart.
- Caveat on the "car_unknown" and "waiting at a box" causes: the probe's box hold is both the occupied-box rule and the signal, and the 8 px/s threshold can leave a car standing while it accelerates away as "other"/"moving".

## 2. One showing of the turn-round behind a parked figure

### Count over the 48 event runs
Probe: `raw/turns-divert-probe.diff` (head checkout `m3-turns`; `LaneMover.step()` counts each tick `blocked_by_a_figure()` triggers `divert()`, separately from a closed tile, and tracks each such car's heading), same 48 runs: `raw/turns-div-head.txt.gz`. Result: **0 diverts triggered by `blocked_by_a_figure()` in 48 runs** (0 figure-only, 0 figure-and-tile; 109,387 car-ticks of closed-tile diverts). The days measured (1 and 9) never park a figure in a crowd car's lane. The event runs therefore show nothing about this rule, in agreement with the earlier turn-round counter, and the count can't be made bigger on these days.

### One scene where it happens
`raw/c2b_turn_behind_parked.gd` (a measuring probe, `tests/test_crowd_yields.gd`'s `_drive_at_a_vehicle` restated, seed 4242): one crowd car drives south at 130 px/s down its lane toward a vehicle (the patrol car's body) that steps into the lane from beside it and parks (`MoveProposal.parked`). On base the field does not exist, so the same vehicle is a move without it and without `stood_round`. Run `tools/test.sh probes/c2b_turn_behind_parked.gd` in each checkout; output `raw/turn-scene-{base,head}.txt.gz`.

| time | base y, speed, heading | head y, speed, heading |
|---|---|---|
| 0.0 s | 242, 130, south | 242, 130, south |
| 0.5 s | 307, 130, south | 304, 107 (braking, arc planned), south |
| 1.0 s | 372, 130, south | 346, 61, south |
| 1.5 s | 437, 130, south (5 px from the figure's centre: through it) | 361, 60, mid-arc |
| 2.0 s | 502, 130, south (through it and past) | 334, 83, **north** |
| 4.5 s | 827, south | 112, east, in the cross street at 130 |

- Base: the car drives through the parked vehicle (33 frames overlapping its body) and on.
- Head: the car brakes to 60 px/s, takes the half-turn arc, is heading north by 1.85 s, 0 overlapping frames, and drives off along the cross street. Instrumentation count in the scene: 1 divert triggered by the parked figure alone, then 1 closed-tile divert (the car at the next block's end). This is the rule working through the ordinary `divert()` path (`_plan_a_turn()`), not the last-resort reversal.

No still: the scene is a hand-built straight street and not a game recipe, and the day-3 fire-truck recipe still does not bring a car behind the truck (see the evidence's `pairs-fixes/PICTURES.md`, item 6); I did not remake it.

## Could not do
- No stills for the turn-round (above). No control run to separate "figures cause the extra stalls by shifting timing" from "chaotic divergence".
- The attribution is of causes at the car's own brake; "box hold" cannot separate a signal from an occupied box.

## Files
`analysis.md` (all tables incl. every stall and per-pair stall deltas), `analyze_attr.py`, `raw/` (all gzipped; probe diffs are `attr-probe.diff`, `turns-divert-probe.diff`, the scene probe `c2b_turn_behind_parked.gd` and its base copy).
