# Splitting the frame record's `draw`: what drawing costs, and that nothing drawn changed

Evidence for M159's item "split the frame record's draw column"
([jolly-trout](../../playtests/2026-10-04-jolly-trout.md), #541: "Yes and let's start work on it").
The branch splits `draw` at the renderer's pre-draw callback into `draw` and a new `render`, counts
the game's own `_draw()` calls per kind (`draws_*`), and records the engine's own render CPU time
(`render_cpu_usec`). Two questions follow, and this folder answers them on a desktop:

1. **Does anything drawn change?** The record adds a timestamp and some counters, never a canvas
   item, layer, material or draw call, so the renderer's `draw_calls` and `render_objects` on the
   same seed and route must read the same with the branch as without it.
2. **What does it cost?** With the record off (every player), and on against off.

**What it is not.** One Apple M2 desktop (macOS 26.6.2, Godot 4.7.2-stable, `gl_compatibility`),
windowed 1280x720, VSync off, on seed 67 and the player's route; not a phone and not a browser. The
`render` and `render_cpu_usec` figures are therefore a desktop's. Whether the web build reports
`render_cpu_usec` at all, and what switching the engine's render-time measure on costs under a
page, is **unverified**; the phone's next record says.

## Conclusions

- **Nothing drawn changes.** Record on or off, the base and the branch hand the renderer the same
  work. Over each side's nine measured runs (record off and on), mean draw calls a frame are 248.4
  to 252.1 for the base and 250.0 to 251.8 for the branch, medians 228 to 238 and 233 to 238, p95
  350 to 360 and 349 to 352, render objects 890.7 to 895.8 and 891.4 to 899.5, primitives 2233 to
  2257 on both: the ranges overlap throughout, and the medians of the runs' means (251.2 against
  251.4 draw calls, 895.0 against 894.7 objects) are within a call. The route is driven by the
  wall clock, so the frames drawn differ from run to run.
- **Off costs nothing measurable.** Medians of the per-run mean frame, six runs a side, interleaved:
  base 7.901ms, branch 7.957ms. The branch's six runs are 7.88, 7.88, 7.91, 8.01, 8.06 and 10.36ms
  (one slow run), the base's 7.82, 7.84, 7.88, 7.92, 8.03 and 8.12ms. The difference of medians,
  0.056ms, is inside the base's own range (0.30ms), and without the one slow run the branch's mean
  is 7.95ms against the base's 7.94ms. The count argument says the same: `drew_cost.gd` puts one guarded counter, record off, at
  about 130ns, and a frame runs about twenty `_draw()` calls (and 275 in the single busiest
  frame), so 3µs a frame, 0.04% of a mean frame (`docs/TELEMETRY.md`, "Off, it costs every player
  as little as the wrap can").
- **On costs a few tenths of a millisecond.** Median of three runs: branch 8.430ms against base 8.132ms
  (the branch off, 7.957ms, is 0.47ms below its own on). Each side's three runs include one slow one
  (branch 9.79ms, base 13.67ms), so three runs cannot separate the two on-costs from the machine's
  noise; this is a weak figure.
- **What `draw` was holding** (the branch's three record-on runs, mean per frame): `draw` 0.47 to
  0.70ms, `render` 2.85 to 3.26ms, the engine's own `render_cpu_usec` 0.79 to 1.00ms. On this
  desktop nearly all the CPU side of drawing is the renderer's own work, not the engine's side
  before it; about a third of `render` is the engine's measured render CPU time, the rest the submit
  and the buffer swap.
- **`_draw()` calls a frame**, means over the three runs: crowd 10.1 to 12.5 (of 234 agents),
  events 2.1 to 2.4 (of about 37 live), halos 0.6 to 0.7, scenery 0.2, badges 1, player 0.3, other
  3.3; 17.6 to 20.3 together, at most 275 in one frame. So the retained canvas items redraw rarely,
  and a frame's `_draw()` count is small against its 890 render objects.

## What was run

Two sets with the repository's own `docs/evidence/m159-frame-record-2026-10-04/measure.py`,
**unchanged**, `--part cost --cost-rounds 3`: one engine at a time (it waits for every other Godot
process to end before a capture, and a capture another engine ran beside is kept as rejected and
taken again), a warmup per condition then three rotated rounds. It compares `main` with the branch
with the record off and the branch with it on, so the base with the record on needs the roles
swapped:

```sh
# the two checkouts: this branch's, and a detached one of the base (sparse like an agent worktree)
git worktree add --detach ../draw-split-base daa09e97
python3 docs/evidence/m159-frame-record-2026-10-04/measure.py \
    --branch . --main ../draw-split-base --output /tmp/ds-A --part cost --cost-rounds 3
python3 docs/evidence/m159-frame-record-2026-10-04/measure.py \
    --branch ../draw-split-base --main . --output /tmp/ds-B --part cost --cost-rounds 3
python3 docs/evidence/m159-draw-split-2026-10-04/analyse.py --tsv /tmp/runs.tsv /tmp/ds-A /tmp/ds-B
godot --headless --path . --script "$PWD/docs/evidence/m159-draw-split-2026-10-04/drew_cost.gd"
```

(`--output` must not exist; the checkouts must be clean tracked ones, which the script checks and
hashes before every capture. A new run takes a new scratch directory and its numbers will differ
a little: the machine's state moves a run's mean frame by half a millisecond or more.)

| | set A | set B |
|---|---|---|
| `--branch` | the branch, d572b8ef | the base, daa09e97 |
| `--main` | the base, daa09e97 | the branch, d572b8ef |
| gives | base off, branch off, branch on | branch off, base off, base on |
| runs | `set-A/provenance.json` (command, runtime hashes, schedule), `set-A/results.json` (every capture, the rejected ones with the engines that ran beside them) |  `set-B/...` likewise |

- **Revisions.** The branch is d572b8ef, the commit at which the draw split was complete; the
  branch's head now also holds a merge of main, this folder and wording fixes, with **the same 23
  `FrameRecord.drew` counter lines** under `src/` and the same recorder. Re-running at the head
  would be the stronger claim; it was tried and abandoned because other agents' engines ran on the
  machine for the whole hour the runner waits for quiet. The base is daa09e97 (v0.24.0-7), the
  branch's merge base with main.
- **Collector.** Both checkouts' `--frame-trace` files are byte-identical (hashes in each
  `provenance.json`), so one collector timed every run. Record-on runs add `--frame-record`.
- **Route and flags.** Seed 67, `--player-view`, `--invincible`, the walk script
  `2.6e15.5n1w4n1e11n11s1w4s1e15.5s` under `--after 70`, windowed with `--always-on-top`,
  `--disable-vsync`, `--no-save`, `--no-telemetry` (the full command is in each `results.json`).
- **Rejected captures.** Ten of the thirty-four captures ran beside another engine and were taken
  again in the same slot: seven in set A (the branch's on-warmup twice, the base's off round 1
  three times, the branch's on round 2 twice) and three in set B (the branch's off round 1, three
  times); `runs.tsv` lists them with `rejected` True and the engines that ran beside. The runner
  waits for quiet before each capture and samples the process list once a second during it, so an
  engine that started and ended between two samples would not have been seen. The measured runs are the eighteen accepted, non-warmup ones.
- **Order.** The run order is the `label`'s number (`runs.tsv`, `started`): in each set a warmup per
  condition, then rounds r1 to r3 rotating the condition order.
- **Footprint.** Eight files in this folder (about 94KB): `README.md`, `analyse.py`, `drew_cost.gd`,
  `runs.tsv` (every capture, one row each, 8KB) and each set's `provenance.json` and
  `results.json`. The captures' traces and the six record-on records stay in scratch; the numbers
  taken from them are the columns of `runs.tsv`.

## Per-run results

Mean frame ms is the trace's mean interval over the run; the draw call, render object columns are
over every sample of the run's trace. Warmups are listed and left out of the conclusions.

| set | slot | revision | record | trial | frames | mean ms | p50 | p95 | draw calls mean | median | p95 | render objects mean |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 00 | daa09e97 | off | warmup | 8157 | 7.926 | 7.697 | 11.168 | 251.1 | 235 | 352 | 894.6 |
| A | 01 | d572b8ef | off | warmup | 8147 | 7.936 | 7.684 | 11.135 | 252.1 | 236 | 352 | 894.8 |
| A | 02 | d572b8ef | on | warmup | 4717 | 13.700 | 14.193 | 24.165 | 251.2 | 238 | 355 | 889.5 |
| A | 03 | daa09e97 | off | r1 | 8047 | 8.034 | 7.190 | 11.228 | 251.9 | 236 | 351 | 895.6 |
| A | 04 | d572b8ef | off | r1 | 6241 | 10.356 | 9.290 | 16.128 | 251.1 | 238 | 350 | 891.4 |
| A | 05 | d572b8ef | on | r1 | 6595 | 9.792 | 9.036 | 15.953 | 250.0 | 236 | 350 | 892.6 |
| A | 06 | d572b8ef | off | r2 | 8020 | 8.061 | 7.409 | 11.410 | 251.8 | 234 | 351 | 896.4 |
| A | 07 | d572b8ef | on | r2 | 7920 | 8.159 | 7.918 | 11.091 | 250.7 | 236 | 352 | 892.9 |
| A | 08 | daa09e97 | off | r2 | 8204 | 7.879 | 7.659 | 11.120 | 251.2 | 236 | 350 | 894.9 |
| A | 09 | d572b8ef | on | r3 | 7666 | 8.430 | 8.007 | 11.078 | 251.2 | 236 | 350 | 893.7 |
| A | 10 | daa09e97 | off | r3 | 8242 | 7.842 | 7.590 | 11.180 | 250.5 | 236 | 351 | 891.4 |
| A | 11 | d572b8ef | off | r3 | 8206 | 7.879 | 7.646 | 11.173 | 251.4 | 238 | 351 | 895.3 |
| B | 00 | d572b8ef | off | warmup | 8175 | 7.905 | 7.692 | 11.149 | 251.2 | 236 | 351 | 893.4 |
| B | 01 | daa09e97 | off | warmup | 8196 | 7.884 | 7.665 | 11.122 | 251.4 | 234 | 353 | 896.7 |
| B | 02 | daa09e97 | on | warmup | 7660 | 8.436 | 8.110 | 11.002 | 251.9 | 238 | 353 | 895.0 |
| B | 03 | d572b8ef | off | r1 | 8206 | 7.878 | 7.670 | 11.164 | 251.4 | 234 | 349 | 894.0 |
| B | 04 | daa09e97 | off | r1 | 8261 | 7.825 | 7.581 | 11.180 | 251.2 | 238 | 351 | 895.5 |
| B | 05 | daa09e97 | on | r1 | 7967 | 8.114 | 7.850 | 11.169 | 250.5 | 236 | 351 | 892.3 |
| B | 06 | daa09e97 | off | r2 | 7958 | 8.122 | 7.822 | 11.689 | 251.2 | 238 | 351 | 892.4 |
| B | 07 | daa09e97 | on | r2 | 4728 | 13.670 | 14.390 | 23.391 | 248.4 | 228 | 360 | 890.7 |
| B | 08 | d572b8ef | off | r2 | 8069 | 8.005 | 7.747 | 11.157 | 251.0 | 233 | 352 | 893.0 |
| B | 09 | daa09e97 | on | r3 | 7947 | 8.132 | 7.934 | 11.146 | 252.1 | 236 | 352 | 895.8 |
| B | 10 | d572b8ef | off | r3 | 8175 | 7.909 | 7.678 | 11.185 | 251.7 | 238 | 351 | 899.5 |
| B | 11 | daa09e97 | off | r3 | 8160 | 7.922 | 7.730 | 11.128 | 251.0 | 238 | 352 | 895.0 |
