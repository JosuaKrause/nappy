# M159: a cheaper crowd step, measured per revision

Evidence for the queue entry `make the physics tick cheaper` (M159, jolly-trout, #542: "Sure we can
look into making the tick cheaper"). It follows
[the first cheaper-tick record](../m159-cheaper-tick-2026-10-04/README.md) and uses the same probe,
extended. The claims: three changes make the crowd's work per 30 Hz step cheaper, **no agent moves
differently on any tick**, and a fourth candidate did not measurably help and was dropped.

**Platform and method on every number.** Everything here is a headless workload on one Apple M2
desktop, Godot 4.7.2 (`tools/test.sh`'s editor binary), on a machine other agents were using
(1-minute load average 2 to 8 in runs 2 and 3, far higher at the start of run 1; see the `.tsv` files). Not a phone, not a
browser, not a whole frame. The ratio between revisions is the transferable part, not the
microseconds. Whether the phone's two-tick frames get shorter is for the next phone frame record.

## The probe

`tests/probes/m159_crowd_tick_cost.gd` (run with `tools/test.sh probes/m159_crowd_tick_cost.gd`),
as in the first record, with two additions. **Days 1, 9 and 14**: day 1 has the densest crowd (234
agents, no huts), day 9 the first walled day (50 agents, 16 or 26 huts, 8 or 13 gates), day 14 the
most walled work (86 agents, 22 or 26 huts, 10 or 13 gates). **Two walks** over each: `street`,
the old fixed walk that never reaches a walker, and `walkers`, which from tick 90 walks at the
nearest walker, so the player half (make way, bump, contact) and the field centre moving through
the crowd are in the hash. Each run reports how many walker-ticks the player was touching a walker
and how many walker-ticks a walker was in a door state other than walking (the workload table in
each report): both are nonzero in every case that can have them, so the hash covers the
checkpoint pass and the bump. Seeds 478156010 (the phone record's) and 4242; 150 warmup ticks, 600
timed.

**Parity.** After every tick a running SHA-256 folds in every agent's position and speed. The probe
fails unless the real tick and the call-by-call copy end on the same chain, and the same chain
compared across revisions is the claim that no agent moved. The probe also records the chain every
150 ticks.

## What was changed (one commit each, on `feature/m159-crowd-tick`)

| label | commit | change |
|---|---|---|
| `base` | `afe2f786` | the probe only (days 14, walkers walk, counters); the code of `main` |
| `ab` | `12b15892` | **A** a walker's redraw computes `velocity()` once, not twice (a third call, `_advance_walker_gait()`, stays), and `velocity()` skips the pocket factor for a walker (always exactly 1.0); **B** `_has_left_the_field()` reads both rooms beyond the map once and builds the field's along bounds inline |
| `huts` | `bacb7b4d` | **C** huts and gates bucketed by the column and row they stand on (128px) once a tick; a walker or car looks only at the buckets its line covers, the exact tests unchanged |
| `keys` | `7101db02` | integer lane keys in place of formatted strings (`CrowdAgent.make_lane_key()`, `TrafficIndex`) |
| `e` | `e-has-stretch-member.patch` on `keys` | **dropped**: `CrowdField.has_stretch()` as a stored member read directly by the agent frame |

`e` is a diff, not a commit on the branch: apply the patch on `keys` (`git apply`) to rebuild it.
Its measurement ran from a local commit of that patch on top of `keys`.

## Parity: every agent identical on every tick

Three retained runs, 1080 + 720 + 1152 probe runs over five, two and four revisions. In each, every
run of the same seed, day, walk, repetition and mode carries the same chain on every revision, and
each seed, day and walk has one chain: **12 chains** (2 seeds x 3 days x 2 walks), the same 12 in
all three runs, and the day 1 and day 9 `street` chains equal the first record's. `analyse.py
report` refuses to print timings if any differ. The chains are listed at the top of each report.

## Timings

Three runs of `run.sh`, rotating through the revisions round by round. **The machine's load swung
widely during the first run** (load average 165 at its start, and its round 2 ran about twice as
slow as rounds 1 and 3 for every revision), which makes its pooled tables unusable as a before and
after: it is retained for its parity and as the contradictory trial. The reading below comes from
the second and third runs, on a quieter machine, with each run's median compared with the baseline
run of the same round and repetition (`paired`), and the lowest run median (`best`).

**Run order matters and was not rotated.** Within a round the revisions always ran in the same order
(the baseline first). In the third run, day 1's agent frame (which `huts` and `keys` do not touch
beyond `keys`'s lane key) reads 0.86 to 0.94 for every revision after the first, so about 5 to 10%
of a later label's ratio is the position in the round, not the change. Read the differences between
labels with that in mind; the day 9 and day 14 door passes changed by 40 to 60%, far more.

### A and B: the agents' own frame (run 2: `base` vs `ab`, five rounds x 3 repetitions)

Median of the paired ratios of the agents' own frame (`CrowdAgent._process()` for every agent), `ab`
over `base`, in every one of the 12 seed, day and walk cases: **0.83 to 0.86**. Best run medians,
microseconds a frame, `street` walk: seed 4242 day 1 2589 to 2118, day 9 509 to 442, day 14 896 to
876; seed 478156010 day 1 2670 to 2023, day 9 612 to 448, day 14 1072 to 788. About 16% of the
agents' frame. The crowd tick proper does not contain this frame, and its whole-tick medians moved
by 1 to 7% between the two (the tick is untouched by A and B; that is the noise floor of this
comparison).

### C: the checkpoint passes (run 3: `ab` vs `huts`, 4 rounds x 3 repetitions)

Microseconds a tick, `split` mode means, `street` walk (the `walkers` walk agrees):

| seed | day | doors, `ab` | doors, `huts` | gates, `ab` | gates, `huts` | tick (split sum), `ab` | `huts` |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4242 | 9 | 167.7 | 116.7 | 31.8 | 22.9 | 287 | 227 |
| 4242 | 14 | 379.8 | 182.1 | 94.7 | 35.8 | 629 | 372 |
| 478156010 | 9 | 274.7 | 137.0 | 56.1 | 28.1 | 424 | 251 |
| 478156010 | 14 | 383.7 | 192.1 | 78.2 | 31.7 | 624 | 373 |

Whole-tick median, `huts` against `ab`: day 9 -21% and -38%, day 14 -41% and -35%; day 1 (no hut,
no change by construction) -3 to -4%, which is the run-order bias above.

### Integer lane keys (run 3: `huts` vs `keys`)

The queue resolve fell from 121.5 to 100.2 (seed 4242, day 1) and from 122.5 to 98.6 (seed
478156010, day 1) microseconds a tick, the whole tick on day 1 from 350 to 315 and from 334 to 294
(`split` sums), on days 9 and 14 the resolve by 16 to 24%. Whole-tick median, `keys` against
`huts`: day 1 -13% and -12%, day 9 -3% and -10%, day 14 -2% and -11%.

### The whole step, `ab` to `keys` (run 3, whole-tick median, microseconds)

| seed | day | `ab` | `keys` | change |
|---:|---:|---:|---:|---:|
| 4242 | 1 | 366 | 304 | -17% |
| 4242 | 9 | 279 | 213 | -24% |
| 4242 | 14 | 606 | 351 | -42% |
| 478156010 | 1 | 337 | 287 | -15% |
| 478156010 | 9 | 399 | 222 | -44% |
| 478156010 | 14 | 579 | 337 | -42% |

With the agents' frame (A and B, 16% of about 2 to 2.5 ms on day 1, and the same share elsewhere)
on top, which the tick does not contain but a frame does.

### Dropped: `has_stretch()` as a stored member (`e`)

`keys` against `e` in run 3, whole-tick medians in microseconds (`keys`, `e`): seed 4242 day 1 304
and 304, day 9 213 and 211, day 14 351 and 342; seed 478156010 day 1 287 and 305, day 9 222 and
238, day 14 337 and 336. Differences of both signs, inside the run-order noise. The agents' frame,
paired against `ab`, on day 1 and the `street` walk: 0.86 (`keys`) and 0.88 (`e`) on seed 4242,
0.88 and 0.94 on seed 478156010. One removed method call per agent is not visible. **Not built, for the same reason, and unmeasured:**
reusing the step's `world_to_tile()` result (one call per car), caching the junction in
`_consider_turning()` (it already returns at its first test for nearly every walker on nearly
every tick), and integer junction keys in `give_way_at_junctions()` (its keys are `Vector2i`, which
hash as two integers with no formatting, and the function is cars only).

## Assumptions the changes rely on, checked

- **B: `field.map` is `_map`.** `Crowd` makes the one `CrowdField` and hands it to every agent
  together with its map. A suite that sets an agent up with a field built on a different map would
  see `limit` from the agent's map where `along_bounds()` used the field's. None does.
- **C: a walker's heading is on an axis.** A walker never has a turn path, so `heading()` is
  `(0, +-1)` or `(+-1, 0)`; then the across distance is exactly one coordinate difference, and the
  bucket range (tolerance plus a pixel) is a superset of what passes the exact test. A heading on
  neither axis (a car mid-turn) takes every hut or gate, as before.
- **C: ties.** The hut scan took the first hut in the day's order on a tie in distance; the buckets
  are visited lowest first, so the tie is broken by index. The gate scan, now car-major, keeps each
  gate's car order, and the per-gate decisions still run in gate order, so the last gate to claim a
  car still wins its `gate_hold`.

## Retained, and how to rerun

Footprint: 10 files, about 3.3 MB (the three `.jsonl.gz` files are 1.3, 0.8 and 1.2 MB: each
`whole` run keeps its per-tick numbers so the distributions can be recomputed).

- `run.sh <scratch-dir> <rounds> <label=sha>...` makes a sparse detached worktree per revision in a
  new scratch directory, imports each, copies the last revision's probe over all of them, and runs
  the probe rotating through the labels round by round. `GODOT` names the engine. A rerun needs the
  revisions in the clone; the branch's commits are on `origin/feature/m159-crowd-tick`, and after
  the pull request is squash-merged and the branch deleted, `git fetch origin
  refs/pull/<number>/head` makes them reachable.
- The three runs were: run 1, rounds 3, `base ab huts keys e`; run 2, rounds 5, `base ab`; run 3,
  rounds 4, `ab huts keys e`, all with the full commit IDs of the table above (`e` being the patch
  on `keys`).
- `analyse.py collect <out-dir> <file.jsonl.gz>` gathers a run's logs; `analyse.py report <file>`
  checks parity and prints every table, including the paired and best-of reading. Standard library
  only.
- `runs.jsonl.gz` and `runs.tsv` are run 1, `ab-runs.jsonl.gz` and `ab-runs.tsv` run 2,
  `cde-runs.jsonl.gz` and `cde-runs.tsv` run 3. The `.tsv` files carry each run's start time, the
  1-minute load before it and the SHA-256 of the three files compared. A `split` run keeps its
  column means, medians and 95th percentiles rather than every tick.
- Not retained: the probe logs, the import logs and the worktrees (scratch space).
