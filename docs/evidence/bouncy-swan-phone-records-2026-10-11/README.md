# bouncy-swan: the day-9 siting stall, measured before and after, and the placement audit

[bouncy-swan](../../todo/2026-10-11-bouncy-swan/README.md) is the phone's lag spikes, found and
fixed. This folder holds three things:

- the measurement of the day-9 stall the player's phone recorded, before and after this branch's
  fix;
- the scripts that take it;
- the audit of event placement for guaranteed and bounded completion,
  [placement-audit.md](placement-audit.md). The player asked for it in #701 (velvet-marten).

## The phone's records

Both of the player's frame records are kept, unchanged, in
[../velvet-marten-phone-records-2026-10-11/](../velvet-marten-phone-records-2026-10-11/). Their
README gives each file's hash and what it holds. In short:

- **The build**: the released v0.27.1 page, seed 67, ground mode 2.
- **The device**: Chrome 154 on Android, as far as the user agent says.
- **Day 9**: `nappy-frames-seed67-2026-10-11T17-30-58.json`, 10,628 frames over three attempts,
  each starting at the doorstep.
- **Day 14**: `nappy-frames-seed67-2026-10-11T17-40-04.json`. Nothing here uses it.

**Day 9's frames with the most `events` time**, as process frame, seconds into the record, the
frame and its `events` time, and her position:

| Frame | In | Frame time | `events` | Her position |
|---|---|---|---|---|
| 7736 | 205.9s | 775ms | 748ms | (2419, 1903) |
| 2812 | 72.6s | 66ms | 47ms | (1328, 3194) |
| 6323 | 158.9s | 59ms | 39ms | (4486, 1906) |
| 9450 | 254.4s | 51ms | 32ms | (3280, 1304) |
| 1131 | 26.4s | 50ms | 30ms | (4075, 2632) |
| 5800 | 146.0s | 52ms | 29ms | (4084, 2748) |
| 8625 | 232.3s | 50ms | 28ms | (2282, 1100) |
| 5221 | 131.2s | 43ms | 21ms | (2914, 2856) |

The attempts start at frames 0, 1362 and 6867 of the record. Frame 7736 is about 21s into the third
attempt.

**Frame 7736 is the stall this branch fixes.** It is one physics tick inside
`EventManager._site_what_is_on_her_way()`:

- `EventDirector.site_what_is_on_her_way()` asks `WalkSiting.ahead_of()` for each of 12 unplaced
  `poster_crew` copies in one look (the once-a-second siting pass);
- each copy is offered the same single tile;
- `EventScheduler._best_of()` ran the whole placement rule chain on that tile
  `Tuning.EVENT_PLACEMENT_TRIES` (24) times against all 357 of the day's plans before refusing it.

The other spikes were not reproduced one by one.

## The fix, measured

**What changed.**

- `_best_of()` keeps each candidate's verdict for the call, keyed by its tile and the path built on
  it. Every roll, and every draw inside `_build_placement()`, still happens in the same order, so
  the random stream and every placement are unchanged.
- `WalkSiting` works out a look's offer once rather than once per copy, the widening that finds
  nothing included.
- `tests/test_siting_judges_once.gd` fails if either comes back.

**Platform and method.**

- **Machine**: an Apple M2, macOS 26.6.2, Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`),
  headless.
- **Revisions**: `bf425cec` (`main`, which is v0.27.1 and one docs commit) against this branch with
  only the `_best_of()` and offer change applied.
- **Rig**: each revision is exported into a scratch directory with two additions, neither
  committed:
  - `Stroller` replays the phone's recorded position track for the third day-9 attempt
    (`replay_patch.py`, driven by `NAPPY_REPLAY`);
  - the director and the manager print one line per look, per sited plan and per physics tick
    (`instrument.py`).
- **Runs**: each is `--seed 67 --day 9 --no-title --no-save`, without `--invincible`. Three before
  runs and three after runs, one at a time, alternating.
- **Window**: the day is lost about 31s into the replay, after 11 looks, so that is the window
  compared.

| Run pair | Stalled look, before | Stalled look, after | Every look, after: median |
|---|---|---|---|
| 1 | 291.7ms | 14.9ms | 0.93ms |
| 2 | 288.6ms | 14.9ms | 0.91ms |
| 3 | 275.0ms | 14.9ms | 0.91ms |

Per-look and per-tick distributions are in [results/day9-analysis.txt](results/day9-analysis.txt).
Each pair's whole events tick, every tick, has a p99 of 1.3–1.5ms and a median of about 0.5ms on
both sides.

In each after run the stalled look makes 12 judgements (one per copy) where the before run made
288. A judgement is one run of the rule chain on one candidate.

**Placements and streams.** In all three pairs the 11 looks are the same on both sides: her
position, and the states of the director's three siting streams after each look. Nothing is sited
in that window. A one-tile offer draws nothing from a stream, since Godot's `randi_range(0, 0)`
leaves it where it was.

**Three further checks hold placements identical where the replay cannot.** The replay is exact
only while the day lasts: past it, under `--invincible`, her position drifts by a tick between two
runs of the same revision.

- **The tests.** `tests/test_siting_judges_once.gd` compares `_best_of()` with the loop that
  judges every try. It covers 27 pools of one to thirty tiles, for a still row, a pacing row and a
  row whose path is rolled. Placement and stream state agree on all 27.
- **A shadow check** (`shadow.py`). In a scratch copy of the branch, every `_best_of()` call also
  runs that loop on a copy of the stream, and every kept offer is worked out again. The three
  attempts were replayed under `--invincible`: 0 disagreements over 490 calls and 606 kept offers,
  the day's dawn plan included ([results/shadow-check.txt](results/shadow-check.txt)).
- **A plan dump** (`dump_plans.gd`, a scratch suite). It plans all 14 days of seeds 4242, 67 and 11
  on both revisions: 6,792 plans, byte-identical
  ([results/plan-dump.txt](results/plan-dump.txt)). The shadow check and the plan dump ran with
  the branch's dawn changes as well, the audit's bounded beat loop, door points and sack piles
  included.

## Day 12, seed 13: the same family, worse

The same rig was run without a replay, through the route rig: `--seed 13 --day 12 --meters 100 0
--route mark,task,home`, the walk snowy-trout used.

- **Without `--invincible`**, one run at a time, until a robber ended the day:
  - before: consecutive looks of 453, 463, 724 and 744ms;
  - after: 52, 63, 168 and 164ms.
- **Under `--invincible`**, so that she walks on: this compares look time only, since the flag does
  not run inside a look.
  - before: two looks of 0.40–0.41s, then six in a row of 0.64–0.70s, then five of 0.98–1.14s;
  - after: 0.04–0.26s.

About 10 crews are owed, each offered 1–6 refused tiles. A judgement costs 3.5–5ms against the
day's 432 plans ([results/day12-seed13-why-after.txt](results/day12-seed13-why-after.txt)).

The day-12 rig is not deterministic between runs: the route rig steers by her position.
[placement-audit.md](placement-audit.md) says what this means for the day-12 softlock.

## What is here

- **`measure.sh <before-rev> <after-rev> <day-9-record.json> [out-dir]`** reruns the day-9
  measurement. It exports both revisions into a fresh scratch directory, bakes and imports them,
  times the third attempt three times per side, alternating, and replays all three attempts under
  `--invincible`. `GODOT` picks the engine and `RUNS` the number of timed pairs. Each revision must
  be fetchable; this branch's is reachable from `refs/pull/<PR>/head`.
- **`replay_patch.py`, `instrument.py`, `extract_track.py`** are the rig's three pieces: the
  replay, the log lines, and a record's attempt as a `seconds x y events_usec` track. They are
  applied to scratch copies only.
- **`analyse_stall.py <before.log> <after.log> ...`** compares the runs pair by pair:
  - the looks and sitings;
  - the stalled look's time;
  - the per-look and per-tick distributions.
- **`shadow.py <checkout>` and `dump_plans.gd`** are the two placement checks above. Copy
  `dump_plans.gd` into a scratch copy's `tests/` as `test_zz_dump_plans.gd`, then run
  `PLAN_DUMP=<file> tools/test.sh zz_dump_plans` there.
- **`results/`** holds:
  - the six day-9 run logs, gzipped, which carry every physics tick's `events` time;
  - their analysis;
  - the day-12 look and ask lines, before and after;
  - the reasons for the after run's refusals;
  - the shadow and plan-dump summaries.

  The scratch logs of the `--invincible` replays and of the parallel day-12 runs are not kept: the
  parallel runs shared the machine eight ways, so their timings are not comparable.
