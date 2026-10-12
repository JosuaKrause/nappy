# M159: the influence sweep and the events' step, measured per revision

Evidence for the queue item `make the physics tick cheaper` (M159, jolly-trout, #542: "Also what
about the physics twice per frame? Should we fix that?", then "Sure we can look into making the
tick cheaper"). The crowd's step was made cheaper before
([m159-crowd-tick-2026-10-11](../m159-crowd-tick-2026-10-11/README.md)). This record covers the
other two systems that run once per 30/s physics step: the baby's influence sweep
(`Baby._physics_process()`) and the events' step (`EventManager._physics_process()`). The phone's
frame record put each at about 0.7 ms per extra step
([m159-phone-frame-record-2026-10-04](../m159-phone-frame-record-2026-10-04/README.md), section 5).

The claims: three changes make the sweep 30 to 63% cheaper and the step 10 to 41% cheaper by
median, depending on seed, day and walk; **no event, agent, attribution or meter differs on any
tick**; and the candidates the measurement showed were too small to be worth it were not built.

**Platform and method on every number.** Everything here is a headless workload on one Apple M2
desktop, Godot 4.7.2 (the macOS app's binary, which `tools/test.sh` uses), on a machine other agents
were using (1-minute load average 2.4 to 4.1 at the start of each run, in `runs.tsv`). It is not a
phone, a browser or a whole frame. **What a desktop number cannot say about the phone:** the phone
ran these two systems about twice as slowly as this probe does (0.7 ms against roughly 0.3 to
0.4 ms here), and its slowdown is not the same for every kind of work. GDScript call overhead,
which most of these changes remove, may weigh differently there. The ratios between revisions are
the part that transfers, and only roughly. Whether the phone's two-step frames get shorter needs a
new phone frame record.

## The probe

`tests/probes/m159_tick_sweep_events_cost.gd` (run with
`tools/test.sh probes/m159_tick_sweep_events_cost.gd`).

- **Setup.** Each run starts the seed's city on the day the way `main._start_day()` does: closures
  and region plan, the day's events planned and streamed around the doorstep, the crowd with the
  day's gates. A player rig carries a real `Baby` (a new one for every run).
- **Each tick.** One simulated thirtieth of a second is one physics tick (the crowd's, then the
  events', then the baby's) and one drawn frame (every agent's and every live event's `_process()`).
- **Seeds and days.** Seeds 478156010 (the phone record's) and 4242; days 1, 9 and 14.
- **Two walks.**
  - `street` is the crowd probe's walk: down from the doorstep, then back and forth.
  - `events` walks from event to event. From tick 90 it heads for the nearest live event she has
    not yet reached, and moves on once within half a tile of it. That way fields that reach her,
    warnings, the mark over her head and her attribution are all in the hash.
- **Window.** 150 warmup ticks, then 600 timed. Each case runs 3 repetitions.
- **Two modes.** `whole` times the real `EventManager._physics_process()` and
  `Baby._physics_process()`. `split` times each call of the events' step on its own, and times
  the sweep's three queries before the baby's whole step. The split's `baby` column therefore runs
  with warm caches and is not the whole sweep.
- **Crying ticks are left out.** Some event walks leave the baby crying (the workload table). A
  crying baby's sweep returns at once, so each row records whether she was crying, and the
  influence figures leave those ticks out.

**Parity.** After every tick a running SHA-256 takes in:

- every live event's id, place, age, phase flags and what it has landed on her;
- every agent's place, speed and what it has landed;
- her place, and the mark over her head with its time left;
- the baby's two meters, state, incoming and decay, her own landed share and the decay window.

The probe fails unless `whole` and `split` end on the same chain. The same chain compared across
revisions is the claim that nothing changed. `analyse.py report` refuses to print timings if any
run of a seed, day and walk differs from the others on any revision, repetition or mode.

### What the probe had to fix in itself first

- **A baby carried from run to run made chains disagree.** Four of 24 whole/split pairs diverged
  on the decay window only. `Baby.reset()` does not reset the baby's own clock (`Baby._clock`), and
  the sliding windows pruned against it round differently from a different start. Each run now
  builds its own baby.
- **The first event walk stood still in each event**, which left the baby crying on most of those
  runs. A crying baby's sweep returns at once, so it timed nothing. The walk now moves on, and the
  crying ticks are marked and left out.

## What was changed (one commit each, on `feature/m159-tick-sweep-and-events`)

| label | commit | change |
|---|---|---|
| `base` | `e9945445` | the probe only; the code of `main` |
| `field` | `cc634bf1` | **an event past `EventDef.silent_beyond()` answers zero** before its intensity, velocity or shape is read |
| `loops` | `879b2a1e` | `stream_around()` works out a point plan's distance inline; `_hold_that_would_begin()` tests a door's range before the boom's carriageway; `is_lethal_at()` reads `hard_fail` first |
| `crowd` | `c6a38520` | **the crowd's sweep skips a body past `CrowdAgent.silent_beyond()`** without calling into it (with the tests and the ARCHITECTURE sentence, and the probe's uid) |

**`silent_beyond()`** is a distance from the node past which a field is exactly zero. For an event
it is the body's `shape.reach()` plus the largest radius the field reads (inner, outer, a core's)
plus a pixel, divided by `1 − FIELD_ECCENTRICITY_MAX` (0.5) for a moving field's stretch. For the
crowd it is the largest of both kinds' outer radii and the widest jolt any agent has had, over the
same stretch. `EventDef.field_reach()` already exists, but it is not that bound: it leaves out the
inner radius, a core, a rectangle's corners and a standing row's stretch, so a second figure was
needed. Flocks and a guard leaving his barrier have their fields centred elsewhere, so they skip
the test. Two suites hold both as bounds: `test_events_emission` checks every row at every bearing,
standing and moving, and `test_crowd_contributions` checks every kind, pace and jolt. Dropping the
stretch from the event bound fails 8,176 of its samples.

## Parity: every event, agent and meter identical on every tick

864 runs: 4 revisions × 3 rounds × 2 seeds × 3 days × 2 walks × 3 repetitions × 2 modes. Each seed,
day and walk has one chain on every revision, repetition and mode: **12 chains**. They are the same
12 chains the pilot (below) ended on, and they are listed at the top of `analyse.py report`.

## Timings

The final run is `runs.jsonl.gz`, with its order in `runs.tsv`. It ran three rounds, and each round
started one revision further along the list, so every revision ran once in each slot of a round.
The "x/base" columns are medians of paired ratios: each run's median over the `base` run of the
same round and repetition, with the range across the three rounds in brackets. Absolute figures
are the median of the three runs' medians and the pooled 95th percentile, in µs per tick.

### The influence sweep (`Baby._physics_process()`, crying ticks left out)

| seed | day | walk | base | field | loops | crowd | crowd/base |
|---|---:|---|---:|---:|---:|---:|---:|
| 4242 | 1 | events | 288 (p95 408) | 174 | 211 | 155 (p95 173) | 0.50 [0.40 to 0.56] |
| 4242 | 1 | street | 379 (p95 449) | 199 | 199 | 155 (p95 191) | 0.37 [0.36 to 0.53] |
| 4242 | 9 | events | 167 (p95 256) | 133 | 129 | 110 (p95 136) | 0.65 [0.53 to 0.72] |
| 4242 | 9 | street | 129 (p95 187) | 107 | 108 | 93 (p95 114) | 0.70 [0.57 to 0.72] |
| 4242 | 14 | events | 225 (p95 275) | 158 | 137 | 115 (p95 155) | 0.52 [0.44 to 0.64] |
| 4242 | 14 | street | 198 (p95 232) | 143 | 126 | 106 (p95 134) | 0.56 [0.46 to 0.62] |
| 478156010 | 1 | events | 339 (p95 392) | 188 | 200 | 148 (p95 191) | 0.43 [0.42 to 0.49] |
| 478156010 | 1 | street | 331 (p95 400) | 173 | 217 | 156 (p95 192) | 0.47 [0.45 to 0.54] |
| 478156010 | 9 | events | 139 (p95 176) | 96 | 100 | 82 (p95 102) | 0.58 [0.55 to 0.66] |
| 478156010 | 9 | street | 145 (p95 177) | 73 | 93 | 75 (p95 88) | 0.51 [0.50 to 0.57] |
| 478156010 | 14 | events | 205 (p95 246) | 170 | 164 | 145 (p95 173) | 0.64 [0.62 to 0.90] |
| 478156010 | 14 | street | 203 (p95 246) | 122 | 122 | 96 (p95 111) | 0.45 [0.43 to 0.56] |

### The events' step (`EventManager._physics_process()`)

| seed | day | walk | base | field | loops | crowd | crowd/base |
|---|---:|---|---:|---:|---:|---:|---:|
| 4242 | 1 | events | 341 (p95 477) | 416 | 351 | 334 (p95 375) | 0.90 [0.74 to 1.01] |
| 4242 | 1 | street | 420 (p95 496) | 494 | 364 | 372 (p95 419) | 0.79 [0.75 to 1.09] |
| 4242 | 9 | events | 390 (p95 641) | 481 | 339 | 313 (p95 438) | 0.77 [0.65 to 0.88] |
| 4242 | 9 | street | 443 (p95 615) | 497 | 338 | 330 (p95 368) | 0.71 [0.61 to 0.75] |
| 4242 | 14 | events | 527 (p95 620) | 531 | 344 | 331 (p95 417) | 0.64 [0.53 to 0.76] |
| 4242 | 14 | street | 551 (p95 628) | 576 | 358 | 340 (p95 420) | 0.65 [0.53 to 0.72] |
| 478156010 | 1 | events | 383 (p95 468) | 403 | 325 | 310 (p95 416) | 0.81 [0.78 to 0.90] |
| 478156010 | 1 | street | 367 (p95 437) | 343 | 320 | 295 (p95 338) | 0.80 [0.75 to 0.88] |
| 478156010 | 9 | events | 656 (p95 979) | 600 | 487 | 444 (p95 546) | 0.66 [0.62 to 0.76] |
| 478156010 | 9 | street | 726 (p95 869) | 570 | 489 | 435 (p95 497) | 0.59 [0.57 to 0.67] |
| 478156010 | 14 | events | 650 (p95 844) | 686 | 488 | 463 (p95 574) | 0.65 [0.63 to 0.89] |
| 478156010 | 14 | street | 778 (p95 929) | 760 | 561 | 495 (p95 568) | 0.61 [0.60 to 0.73] |

### By call (split runs; median of the runs' medians, µs per tick, both seeds and walks)

| call | day 1 base | day 1 after | day 9 base | day 9 after | day 14 base | day 14 after |
|---|---:|---:|---:|---:|---:|---:|
| `stream_around()` | 184 | 116 | 213 | 124 | 220 | 130 |
| `_tell_them_where_she_is()` | 33 | 36 | 168 | 78 | 144 | 70 |
| `_check_detentions()` | 19 | 21 | 43 | 22 | 55 | 24 |
| `_check_hard_fails()` | 28 | 19 | 28 | 20 | 30 | 24 |
| `_summon_what_has_been_sighted()` | 37 | 42 | 44 | 46 | 45 | 46 |
| `_watch_the_encounters()` | 28 | 32 | 27 | 28 | 28 | 32 |
| events' sources at her | 242 | 88 | 104 | 50 | 142 | 58 |
| crowd's sources at her | 72 | 36 | 16 | 8 | 30 | 17 |

"After" is `crowd`. The full table, every call and every revision, is printed by
`analyse.py report`.

### How to read it

- **The sweep.** Most of the saving is in the events' half of the sweep: 242 → 88 µs on day 1.
  That is `field`, because most live events are far from her and no longer work their field out.
  The crowd's half halves on every day with `crowd`.
- **The step.**
  - `loops` takes `stream_around()` from about 200 to about 125 µs, and the detention pass on
    walled days from about 50 to about 23 µs.
  - `field` halves `_tell_them_where_she_is()` on walled days, whose barrier question calls
    `contribution_at()` on every barrier structure.
  - Day 1's step improves least (0.79 to 0.90). It has no barriers or doors, and its cost is spread
    across a dozen calls of 10 to 40 µs each.
- **`field` alone does not show in the step's `whole` column.** Its ratios scatter from 0.73 to
  1.07 around 1. The split's `tell` column is where it shows in the step.
- **Noise.**
  - `loops` changes nothing in the sweep, yet its sweep medians differ from `field`'s by −13% to
    +27%. That is about the size of this machine's noise between revisions.
  - The calls no change touches (`retire`, `sighted`, `encounters`, `officers`) read up to 26% lower
    on `base` than on the other three revisions in rounds 2 and 3, when `base` ran late and the
    load had fallen. So the ratios, if anything, understate the changes.
  - The sweep's ratios (0.37 to 0.70) and the step's on walled days (0.59 to 0.77) are outside the
    noise. The step's day 1 ratios (0.79 to 0.90) are not clearly outside it.

## Candidates measured and not built

- **`_summon_what_has_been_sighted()`** (37 to 46 µs) and **`_watch_the_encounters()`** (about
  28 µs) are a property read or two per plan, or per live event, every tick. Making them cheaper
  needs a kept index of the plans that summon or are watched, with its own invalidation, which
  costs more risk than it saves.
- **What is left of `stream_around()`** (about 120 µs) is the loop over 350 to 400 plans itself:
  four property reads each. Cutting it further needs kept positions or a spatial index of plans.
  The events skill records "No spatial hash" for the live instances; it is not reopened here.
- **The rest of `Baby._update_excitement()`** (`accumulate_landed()` on each charging source, and
  the meter's sliding windows) was not split out. The split's `baby` column, 59 to 83 µs after,
  holds it together with the sweep's queries asked again with warm caches, so it does not say how
  much of that is the rest.

## The pilot (`pilot-runs.tsv`)

One round of `base`, `field` and `loops`, in that fixed order, before `crowd` existed. Its 216
runs ended on the same 12 chains. Its timings are not used: `tools/check.sh` ran in another
worktree during the `field` run, and every call read 20 to 40% slower in that run, the untouched
ones included.

## Rerun

```sh
docs/evidence/m159-tick-sweep-events-2026-10-12/run.sh <new-scratch-dir> 3 \
	base=e9945445 field=cc634bf1 loops=879b2a1e crowd=c6a38520
python3 docs/evidence/m159-tick-sweep-events-2026-10-12/analyse.py collect <new-scratch-dir>/out runs.jsonl.gz
python3 docs/evidence/m159-tick-sweep-events-2026-10-12/analyse.py report runs.jsonl.gz
```

The commits are this branch's. After the pull request is squash-merged they stay reachable through
`git fetch origin refs/pull/<PR>/head`. Timings vary between launches; the chains do not.

## Retained

`run.sh` and `analyse.py` (the runner and the analysis), `runs.jsonl.gz` (all 864 runs: every
`whole` run's per-tick rows, and each `split` run's per-call mean, median and 95th percentile),
`runs.tsv` (order, load and file hashes) and `pilot-runs.tsv`. The probe logs and the pilot's runs
stay in scratch: `runs.jsonl.gz` holds everything the tables read, and the pilot adds only its
chains, which are these.
