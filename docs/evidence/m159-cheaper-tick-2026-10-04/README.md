# The crowd's physics tick, split by call and made cheaper

Evidence for M159's item "make the physics tick cheaper, starting with the crowd's step"
([jolly-trout](../../playtests/2026-10-04-jolly-trout.md), #542: "Sure we can look into making the
tick cheaper"). The phone's frame record ([its README](../m159-phone-frame-record-2026-10-04/README.md),
section 5) puts one physics step at about 3.8ms, about 1.7ms of it the crowd's step
(`Crowd._physics_process()`), and has 35% of frames running two or more steps. This record says
which call inside the crowd's step costs, what was changed, that no agent moved differently, and
what the step costs before and after on a desktop.

**What it is not.** Every number here is a headless workload on one Apple M2 desktop
(Godot 4.7.2, the editor binary `tools/test.sh` runs), not a phone, not a browser and not a whole
frame. The phone ran the same step at roughly 1.7ms against roughly 0.6–0.9ms here, so the ratio
of before to after is the transferable part, not the microseconds. Whether the phone's two-step
frames get shorter is for a new phone frame record to say.

## The probe

`tests/probes/m159_crowd_tick_cost.gd`, run by `tools/test.sh probes/m159_crowd_tick_cost.gd`. For
each seed (478156010, the phone record's own, and 4242, every other crowd probe's) and each day (1,
the densest crowd and the phone record's own day, 234 agents; 9, the first day with the region
wall, 50 agents with checkpoint huts and gates), it starts the city's day (`City.start_day()`: the
day's closures and region plan), the crowd from a fixed RNG seed and the day's gates, and walks a
player rig down from the doorstep for three seconds and then east and west in two-second legs. One
agent frame (`CrowdAgent._process()` for everybody) and one crowd tick run per simulated thirtieth
of a second; 150 ticks warm it, the next 600 are timed. Three repetitions per seed and day, each in
two modes:

- **`whole`** times the real `Crowd._physics_process()` as one span (column `tick`), and the agent
  frame before it for scale (column `agents`, not part of the tick).
- **`split`** makes the same calls the tick makes, in its order, and times each:
  `signals` (`TrafficSignals.advance()`), `pockets` (`CrowdPockets.refresh()`), `resolve`
  (`_resolve_the_queues()`), `keep_room` (`_keep_room_for_the_turning()`), `index`
  (`_index_the_queues()`), `claims` (`_book_the_turns()`), `give_way` (`give_way_at_junctions()`),
  `gates` (`_stop_for_gates()`), `doors` (`_hold_walkers_at_doors()`), `player`
  (`_meet_the_player()`: make way, bump, strike and horn).

**Parity.** After every tick both modes fold every agent's position and speed (as 32-bit floats, in
the crowd's own order) into a running SHA-256. The probe fails unless the two modes end on the same
digest, which is what keeps the split the tick the game runs. The same digest, compared between
revisions, is the claim that the change moved no agent on any tick: one bit of one agent's position
on one tick changes every digest after it. The probe also prints the digest every 150 ticks, so a
divergence could be placed.

## What the split found

The before revision's split, day 1, mean microseconds a tick (all rounds, both seeds within a few
percent of each other; full table below): the junction negotiation `give_way` about 250, the
checkpoint-door pass `doors` about 210, the player half about 190, the queue resolve about 130,
the turn room and turn bookings about 40 each, everything else under 25. **`give_way` is the most
expensive call**, and per car it is mostly the junction geometry asked several times over:
`distance_to_junction()` was read up to five times for a car approaching a box. **`doors` on a day
with no hut** — every day before the wall — walked every walker through a state machine with
nothing in it. **The player half** asked `_make_way()` and `_bump()` about every walker in the
crowd, nearly all of them far out of reach of both. And six loops walked all 234 agents to act on
the 34 cars or the 200 walkers.

## The change

In `src/crowd/crowd.gd` and `src/crowd/crowd_agent.gd`; each step leaves the decision it feeds
unchanged, which the parity digest checks rather than trusts.

- **`_hold_walkers_at_doors()` returns at once when the day has no hut.** With no hut nothing can
  set a walker's `door_ahead`, and a walker with nothing ahead and nothing held is a no-op in
  `advance_the_door_hold()`; huts are only made in `start_day()`, with a new crowd behind them.
- **The player half skips a walker beyond `CROWD_YIELD_DISTANCE + BUMP_CLEAR_RADIUS + 1px`** (96 +
  19 + 1 = 116px) of her with one squared-distance test, doing the one thing both functions would
  have done for it: releasing `touching`. The sum rather than the larger radius, plus a pixel, so
  nothing the test skips is a walker either function's own `length()` test could have let in.
- **The car-only and walker-only loops walk `_cars` or `_walkers`**, sorted from `_agents` in its
  own order at the top of every `_resolve_the_queues()`. Rebuilt every frame rather than kept
  beside `_agents`, because suites add and remove agents through `_agents` directly and a kept list
  would leave such an agent out of the traffic without a word. The sort is why `resolve` rises: it
  now pays the one pass the other loops no longer each pay.
- **`give_way_at_junctions()` reads each approaching car's `distance_to_junction()` once** and hands
  it to `_first_through()`, `_goes_first()` and `_can_clear_the_box()`; nothing in the function
  moves a car, so the reading is the number they would each have recomputed. Each car's axis is
  read once, and `CrowdAgent.junction_occupied()` tests its two ends without building an array.

## Results

Two revisions, measured alternately by `run.sh` (before, after, before, after, before, after) so
the machine's drift falls on both: the before revision `dcd052a56a4ccf27f207eae30a6aaba47f25b28e`
(the probe and two pure extractions, `_meet_the_player()` and `_book_the_turns()`, so the probe
can time them without copying them) and the after revision
`a7623b36303d1deb6a61f645d364212d6db27b69`. `runs.tsv` has each run's start time, the 1-minute
load average before it and the SHA-256 of `crowd.gd`, `crowd_agent.gd` and the probe; the probe is
the same file on both. **The machine was shared**: other agents' work kept the load average between
about 4 and 5.7 throughout, which is the spread visible between runs below and the long upper
tails on both sides. Every run's probe reported 12 checks and 0 failures.

**Parity holds on every run.** 144 runs (72 per revision), and every one of the same seed, day,
repetition and mode carries the same position chain on both revisions; each seed and day has one
chain across all repetitions, rounds, modes and both revisions:

| seed | day | chain (first 16 hex) |
|---:|---:|---|
| 4242 | 1 | `2d339b04c9a1394f` |
| 4242 | 9 | `0d180a16702b0711` |
| 478156010 | 1 | `e998a116e5e0900e` |
| 478156010 | 9 | `496ce0277041179a` |

**The whole tick**, microseconds a tick, `whole` mode, nine runs of 600 ticks per row
(nearest-rank percentiles):

| seed | day | agents | revision | ticks | mean | p50 | p90 | p95 | p99 | max |
|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 4242 | 1 | 234 | before | 5400 | 881.8 | 871 | 964 | 1021 | 1347 | 3692 |
| 4242 | 1 | 234 | after | 5400 | 503.0 | 444 | 667 | 826 | 1041 | 3083 |
| 478156010 | 1 | 234 | before | 5400 | 945.3 | 862 | 1203 | 1501 | 1887 | 11082 |
| 478156010 | 1 | 234 | after | 5400 | 421.7 | 402 | 464 | 489 | 928 | 6881 |
| 4242 | 9 | 50 | before | 5400 | 433.1 | 422 | 482 | 490 | 519 | 1394 |
| 4242 | 9 | 50 | after | 5400 | 359.7 | 353 | 406 | 415 | 438 | 790 |
| 478156010 | 9 | 50 | before | 5400 | 607.4 | 590 | 784 | 828 | 1060 | 6432 |
| 478156010 | 9 | 50 | after | 5400 | 495.0 | 470 | 577 | 618 | 942 | 1506 |

Day 1's median tick is 49% lower on seed 4242 and 53% lower on the phone's seed; day 9's 16% and
20%. On day 1 every after run's own median is below every before run's: 413–668 against 776–943
microseconds on seed 4242, 378–458 against 762–1232 on the phone's seed (each run's median is in
`analyse.py report`'s output). On day 9 the two overlap at their edges: 338–392 against 389–480,
and 419–563 against 482–780.

**By call**, mean microseconds a tick, `split` mode:

| seed | day | revision | resolve | keep_room | index | claims | give_way | gates | doors | player | tick |
|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4242 | 1 | before | 126.0 | 48.9 | 20.7 | 41.4 | 251.4 | 14.2 | 208.4 | 188.8 | 902.1 |
| 4242 | 1 | after | 163.0 | 18.6 | 20.1 | 13.0 | 186.6 | 2.6 | 0.4 | 64.3 | 470.9 |
| 478156010 | 1 | before | 130.5 | 39.5 | 21.5 | 35.2 | 247.1 | 14.5 | 219.7 | 197.6 | 907.9 |
| 478156010 | 1 | after | 165.0 | 8.8 | 19.8 | 6.1 | 178.9 | 2.8 | 0.4 | 66.7 | 450.8 |
| 4242 | 9 | before | 24.2 | 9.6 | 6.5 | 8.2 | 56.1 | 63.6 | 215.5 | 41.7 | 427.1 |
| 4242 | 9 | after | 32.8 | 4.1 | 6.5 | 3.0 | 45.7 | 40.5 | 214.1 | 18.4 | 366.7 |
| 478156010 | 9 | before | 24.4 | 7.9 | 7.7 | 7.0 | 54.4 | 104.7 | 327.5 | 43.8 | 579.4 |
| 478156010 | 9 | after | 34.0 | 2.0 | 7.5 | 1.5 | 47.1 | 67.0 | 326.7 | 18.2 | 506.1 |

`signals` and `pockets` are under 2 microseconds on every row and left out; `tick` is the sum of
every column but the agent frame. The agent frame itself (`CrowdAgent._process()` for every
agent, per frame rather than per tick) was 3,374–3,551 microseconds on day 1 on both revisions and
is untouched by this change.

## What is left

- **The checkpoint-door pass on a walled day** is the largest part of day 9's tick (214–327
  microseconds): each walker scans every hut (26 on the phone's seed) for one on its own line.
  The next reduction would bucket the huts by the line they stand on, once a day.
- **The queue resolve's lane keys**: `CrowdAgent.lane_key()` formats a string per car per tick,
  about a fifth of `resolve` on this machine; integer keys would change `TrafficIndex`'s key type
  across the crowd and several suites.
- **The rest of the step** (the baby's influence sweep, the events' step, the engine's own
  physics, about 2.1ms of the phone's 3.8ms) was not measured here.

## Retained, and how to rerun

- `run.sh` makes two detached worktrees of the two revisions in a new scratch directory, imports
  each, and runs the probe alternately, three rounds by default (`GODOT` names the engine). A
  rerun needs both revisions in the clone: when the pull request's branch is gone, fetch
  `refs/pull/<number>/head` first.
- `analyse.py collect <out-dir> runs.jsonl.gz` gathers a rerun's logs; `analyse.py report
  runs.jsonl.gz` refuses to print timings unless the parity holds, then prints every table above
  (`python3 docs/evidence/m159-cheaper-tick-2026-10-04/analyse.py report
  docs/evidence/m159-cheaper-tick-2026-10-04/runs.jsonl.gz`). Standard library only.
- `runs.jsonl.gz`: every probe run's output, with its revision and round. The `whole` runs keep
  every tick's two numbers; the `split` runs keep each column's mean, median and 95th percentile
  rather than eleven numbers a tick, since only their means are claimed.
- `runs.tsv`: run order, start times, load averages and source hashes.

The full probe logs, the import logs and the two worktrees stayed in scratch space.
