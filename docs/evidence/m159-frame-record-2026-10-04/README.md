# The frame record's cost and a first look at ground modes 2 and 1, seed 67

Measured for PR #521 (M159, "A slow frame names the frame that was slow") before merge, as the
brief's measurement run asked: native and windowed, one engine at a time, on the player's route.
**Everything here is a desktop: an Apple M2 MacBook Air, not the phone the player stutters on.**

## What was asked, and the answers

1. **Does the record cost anything with it off, against `main`?** It did: in the first batch
   this branch with the record off had a mean frame 0.16ms longer than `main` in all five
   interleaved runs (7.97-8.06ms against 7.78-7.87ms), about 0.6µs for each of the 270 or so
   timed calls a frame. Almost all of those calls are the crowd's agents and the live events,
   each reading the static `FrameRecord.on` and calling its moved body. They now copy the
   switch when they are made and keep their body in `_process()` (commit f2e32475). In the
   second batch, taken after that change, the off path is within the run-to-run noise: medians
   of the per-run means 6.864ms (`main`) and 6.911ms (off), with overlapping ranges.
2. **What does the record cost on?** 0.25ms of mean frame in the first batch and 0.63ms in the
   second (medians of per-run means, on against off). The record's own estimate, its calibrated
   enter/leave pair times its timed calls, is about 0.16ms a frame in every run; the rest is the
   recorder's per-frame bookkeeping and the difference between the two batches.
3. **Mode 2 against mode 1, slow frames with and without a scenery job.** Three recordings each.
   Past the day's load, mode 1 had 49 slow frames and mode 2 had 18. In both, a slow frame on
   this machine is a draw spike of about 19ms that takes the frame just past the 25ms line. On a
   native window `draw` includes the buffer swap's wait, so these are most likely presentation
   stalls rather than CPU drawing: their draw calls are only modestly above an ordinary frame's. Few
   are near a scenery job: 5 of mode 1's 49 and 2 of mode 2's 18 ran one in the same frame, and 2
   more of mode 1's one to five frames after one. That is 14% and 11%, against the 4-6% of all
   frames with a job in the same frame or the five before, so a little above chance on small
   counts, and those frames are draw spikes like the rest (`scenery` 1.7ms on average in them).
   **So on this desktop the slow frames are not the scenery queue's in either mode, and it
   cannot answer the player's hypothesis** ("mode 2 allows more expensive things to take up time
   as it limits itself to a very short time budget"); that needs the phone's recording.

## How it was run

- **Route**: seed 67, day 1, every event (no `--skip`), the walk script
  `2.6e15.5n1w4n1e11n11s1w4s1e15.5s` under `--after 70`. The player's words
  (`docs/playtests/2026-10-03-quiet-yak.md`, "## #510"): "full events on the same seed 67 one
  block to the right walking up all the way squeezing through car accident and going middle
  between stalls and then walking back". The script walks east from the door to the street at tile
  column 87, north up it, one second west round the car accident at tile (87,38) and back, to
  the city's top edge, then the same way down to the door's row. Every capture is checked for
  reaching the top edge (y under 200px) and coming back down (last y over 2300px).
- **`--invincible`**, against the frame-trace doc's advice for controlled trials: without it the
  baby cries at the car accident about 21s in and the day ends, so no run reaches the top.
  Also `--no-title --no-focus-pause --no-save --no-telemetry`.
- **Windowed, 1280x720, always on top** (`--always-on-top`): macOS skips the draw step of a
  covered window, and a rig's window opens behind whatever is in front. A capture with more than
  half a percent of its frames undrawn is rejected.
- **Cost part**: VSync off (`--disable-vsync`), so a frame's length is its work, and
  `--player-view`, the frame a player sees. Every run carries `--frame-trace`, whose two files
  are byte-identical in both checkouts (hashes in `provenance.json`); the record-on runs add
  `--frame-record`. One warmup per condition, then five rounds in rotated order.
- **Modes part**: `--frame-record --ground-mode 2` and `1`, VSync as the project sets it, the
  developer view. **The window was not paced by VSync on this machine**: frames ran at about
  120 a second with no time in `wait`, so these are unpaced frames. A slow frame is still one
  longer than 25ms (one and a half 60Hz budgets). One warmup each, then three alternating rounds.
- Every capture waits for every other Godot process to end first, and one another engine ran
  beside is kept as rejected and taken again (one, the first warmup of the first batch).
- **Environment**: macOS 26.6.2, Apple M2 (fanless), 16 GiB, Godot 4.7.2-stable (official),
  `gl_compatibility`/`opengl3`, main thread renders, display 60Hz. The machine runs in two
  states between launches, a run's mean frame about 0.5-0.9ms apart, which shows as one slower
  run here and there in every condition.

| batch | checkouts | parts |
|---|---|---|
| `batch1-before/` | `main` 8008980567cd7139cf95c6f314e6eb1c5bd73da5; branch c3041d98d675dce92550facfd4d0b1bb6472b002 (every wrap a static read and a call) | cost, modes |
| `batch2-after/` | `main` 8008980567cd7139cf95c6f314e6eb1c5bd73da5; branch f2e3247545cefe0cb4252669f157b88e80a31f7c (agents and events copy the switch) | cost |

The recordings' build string ends `-dirty` because the evidence scripts were untracked files in
the checkout at the time; the runner hashed every tracked runtime file before each capture
(`runtime_sha256` in `provenance.json`).

## Batch 1: the wraps as reviewed

#### Frame length per run (ms, VSync off, --frame-trace)

| condition | run | frames | mean | p50 | p95 | p99 | worst | >16.7ms | >33.3ms |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| branch-off | r1 | 8036 | 8.041 | 6.695 | 10.904 | 11.333 | 25.0 | 1 | 0 |
| branch-off | r2 | 8018 | 8.060 | 8.088 | 10.506 | 10.862 | 18.5 | 2 | 0 |
| branch-off | r3 | 8095 | 7.983 | 6.648 | 11.020 | 11.465 | 17.4 | 1 | 0 |
| branch-off | r4 | 8110 | 7.973 | 7.965 | 10.537 | 10.883 | 17.0 | 1 | 0 |
| branch-off | r5 | 8098 | 7.979 | 7.972 | 10.495 | 10.956 | 24.7 | 5 | 0 |
| branch-on | r1 | 7963 | 8.116 | 7.093 | 10.753 | 11.142 | 20.1 | 3 | 0 |
| branch-on | r2 | 7844 | 8.238 | 7.194 | 10.802 | 11.232 | 19.1 | 1 | 0 |
| branch-on | r3 | 7857 | 8.230 | 8.216 | 10.528 | 10.887 | 16.7 | 1 | 0 |
| branch-on | r4 | 7854 | 8.233 | 7.304 | 10.755 | 11.234 | 16.8 | 1 | 0 |
| branch-on | r5 | 7816 | 8.272 | 7.511 | 10.791 | 11.188 | 20.5 | 1 | 0 |
| main-off | r1 | 8209 | 7.873 | 6.574 | 10.988 | 11.458 | 23.9 | 3 | 0 |
| main-off | r2 | 8270 | 7.819 | 6.485 | 11.033 | 11.505 | 18.4 | 1 | 0 |
| main-off | r3 | 8280 | 7.806 | 6.532 | 11.037 | 11.518 | 18.6 | 1 | 0 |
| main-off | r4 | 8312 | 7.776 | 6.463 | 10.999 | 11.388 | 16.6 | 0 | 0 |
| main-off | r5 | 8265 | 7.819 | 6.543 | 10.907 | 11.264 | 13.5 | 0 | 0 |

#### Median over runs (ms)

| condition | runs | mean | p50 | p95 | p99 | worst |
|---|---:|---:|---:|---:|---:|---:|
| main-off | 5 | 7.819 | 6.532 | 10.999 | 11.458 | 18.403 |
| branch-off | 5 | 7.983 | 7.965 | 10.537 | 10.956 | 18.480 |
| branch-on | 5 | 8.233 | 7.304 | 10.755 | 11.188 | 19.057 |

#### The record's own estimate of its cost (branch-on runs)

| run | timer_pair_usec | timer calls a frame | pairs x calls, us a frame |
|---|---:|---:|---:|
| r1 | 0.585 | 273.5 | 159.9 |
| r2 | 0.579 | 273.6 | 158.3 |
| r3 | 0.574 | 273.6 | 156.9 |
| r4 | 0.609 | 273.6 | 166.6 |
| r5 | 0.569 | 273.6 | 155.7 |

## Batch 2: agents and events copy the switch

#### Frame length per run (ms, VSync off, --frame-trace)

| condition | run | frames | mean | p50 | p95 | p99 | worst | >16.7ms | >33.3ms |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| branch-off | r1 | 9353 | 6.911 | 6.032 | 10.498 | 11.014 | 13.3 | 0 | 0 |
| branch-off | r2 | 9356 | 6.911 | 6.290 | 9.498 | 10.077 | 18.3 | 2 | 0 |
| branch-off | r3 | 9303 | 6.947 | 6.306 | 9.507 | 10.065 | 20.6 | 4 | 0 |
| branch-off | r4 | 8273 | 7.813 | 7.733 | 10.555 | 10.940 | 20.3 | 1 | 0 |
| branch-off | r5 | 9687 | 6.670 | 6.072 | 9.686 | 10.291 | 13.5 | 0 | 0 |
| branch-on | r1 | 8578 | 7.536 | 7.447 | 9.932 | 10.365 | 19.9 | 3 | 0 |
| branch-on | r2 | 8496 | 7.606 | 6.714 | 10.465 | 10.951 | 23.8 | 2 | 0 |
| branch-on | r3 | 8665 | 7.459 | 7.335 | 9.849 | 10.284 | 31.4 | 3 | 0 |
| branch-on | r4 | 8429 | 7.667 | 7.606 | 10.099 | 10.622 | 19.1 | 3 | 0 |
| branch-on | r5 | 8732 | 7.405 | 7.253 | 9.791 | 10.222 | 16.5 | 0 | 0 |
| main-off | r1 | 9414 | 6.864 | 6.258 | 9.455 | 10.020 | 17.0 | 1 | 0 |
| main-off | r2 | 9532 | 6.779 | 6.173 | 9.326 | 9.884 | 13.4 | 0 | 0 |
| main-off | r3 | 9428 | 6.857 | 6.254 | 9.407 | 10.102 | 17.6 | 2 | 0 |
| main-off | r4 | 9415 | 6.869 | 6.265 | 9.441 | 10.028 | 15.2 | 0 | 0 |
| main-off | r5 | 8741 | 7.393 | 7.073 | 10.333 | 10.807 | 22.6 | 1 | 0 |

#### Median over runs (ms)

| condition | runs | mean | p50 | p95 | p99 | worst |
|---|---:|---:|---:|---:|---:|---:|
| main-off | 5 | 6.864 | 6.258 | 9.441 | 10.028 | 16.955 |
| branch-off | 5 | 6.911 | 6.290 | 9.686 | 10.291 | 18.312 |
| branch-on | 5 | 7.536 | 7.335 | 9.932 | 10.365 | 19.948 |

#### The record's own estimate of its cost (branch-on runs)

| run | timer_pair_usec | timer calls a frame | pairs x calls, us a frame |
|---|---:|---:|---:|
| r1 | 0.569 | 273.3 | 155.4 |
| r2 | 0.570 | 273.4 | 155.8 |
| r3 | 0.603 | 273.4 | 164.7 |
| r4 | 0.571 | 273.5 | 156.2 |
| r5 | 0.561 | 273.4 | 153.4 |

## Why that shape: `wrap_cost.gd`

A headless microbenchmark of the wrap's possible shapes, a million calls each, seven rotated
rounds, the body a single addition, on the same machine:

| shape | record off, ns over the body inline | record on, ns over the body inline |
|---|---:|---:|
| static read + call (as reviewed) | +150.6 | +712.9 |
| member read + call | +82.1 | +642.5 |
| static read, body inline | +91.3 | +880.1 |
| member read, body inline (built) | +25.0 | +738.3 |

## Batch 1: ground modes 2 and 1

All six recordings are kept as `batch1-before/2*-modes-*.record.json.gz`. A recording's first
kept frame is the day's load (100-125ms, mostly `process_rest`), which every count in the
summary includes; the last table leaves the first two seconds of play out.

#### Slow frames per recording (VSync as a player plays, --frame-record)

| mode | run | frames | p50 ms | p99 ms | worst ms | slow | slow, scenery job | slow, no job | largest cost in slow frames, job | largest cost, no job |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| mode1 | r1 | 7902 | 8.51 | 23.82 | 107.3 | 17 | 0 | 17 | - | draw 15, crowd 1, process_rest 1 |
| mode1 | r2 | 7942 | 8.60 | 23.80 | 100.9 | 37 | 2 | 35 | draw 2 | draw 33, outside_callbacks 1, process_rest 1 |
| mode1 | r3 | 7953 | 8.73 | 23.83 | 100.3 | 13 | 3 | 10 | draw 3 | draw 8, crowd 1, process_rest 1 |
| mode2 | r1 | 7771 | 8.72 | 23.85 | 114.9 | 10 | 0 | 10 | - | draw 7, crowd 1, outside_callbacks 1, process_rest 1 |
| mode2 | r2 | 7884 | 8.45 | 23.87 | 113.7 | 3 | 0 | 3 | - | crowd 1, draw 1, process_rest 1 |
| mode2 | r3 | 7880 | 8.55 | 23.76 | 125.1 | 13 | 2 | 11 | draw 2 | draw 9, crowd 1, process_rest 1 |

#### Mean ms per slow frame, by bucket (pooled over a mode's recordings)

| mode | slow frames | split | scenery | crowd | influence | events | cues | draw | physics_rest | process_rest |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| mode1 | 67 | all | 0.24 | 3.96 | 0.03 | 1.21 | 1.40 | 19.02 | 0.16 | 3.09 |
| mode1 | 5 | scenery job | 1.73 | 3.05 | 0.02 | 1.21 | 1.31 | 19.05 | 0.11 | 0.29 |
| mode1 | 62 | no job | 0.12 | 4.04 | 0.03 | 1.21 | 1.41 | 19.02 | 0.17 | 3.32 |
| mode2 | 26 | all | 0.25 | 5.34 | 0.04 | 1.24 | 1.42 | 18.79 | 0.26 | 7.77 |
| mode2 | 2 | scenery job | 1.70 | 3.01 | 0.02 | 1.22 | 1.26 | 18.98 | 0.12 | 0.30 |
| mode2 | 24 | no job | 0.13 | 5.53 | 0.04 | 1.24 | 1.43 | 18.78 | 0.27 | 8.40 |

#### Slow frames after the day's load, against recent scenery jobs

| mode | run | slow after 2s | job in the same frame | job 1-5 frames before | frames with a job | frames |
|---|---|---:|---:|---:|---:|---:|
| mode1 | r1 | 15 | 0 | 0 | 55 | 7902 |
| mode1 | r2 | 23 | 2 | 2 | 54 | 7942 |
| mode1 | r3 | 11 | 3 | 0 | 54 | 7953 |
| mode2 | r1 | 7 | 0 | 0 | 75 | 7771 |
| mode2 | r2 | 1 | 0 | 0 | 86 | 7884 |
| mode2 | r3 | 10 | 2 | 0 | 83 | 7880 |

## Rerun

The scripts come from a runner checkout at this folder's commit (fc96d06161e8be3308cabf6a194a29f9f1b8ee08,
on the PR's ref); the measured checkouts are separate, since the runner refuses a dirty one.

```sh
source_root=$(git rev-parse --show-toplevel)
scratch=$(mktemp -d)
evidence=docs/evidence/m159-frame-record-2026-10-04
git -C "$source_root" fetch origin main refs/pull/521/head
git -C "$source_root" worktree add --detach "$scratch/runner" fc96d06161e8be3308cabf6a194a29f9f1b8ee08
git -C "$source_root" worktree add --detach "$scratch/branch" f2e3247545cefe0cb4252669f157b88e80a31f7c
git -C "$source_root" worktree add --detach "$scratch/main" 8008980567cd7139cf95c6f314e6eb1c5bd73da5
python3 "$scratch/runner/$evidence/measure.py" \
  --branch "$scratch/branch" --main "$scratch/main" --output "$scratch/run" --godot "$GODOT"
python3 "$scratch/runner/$evidence/summarize.py" "$scratch/run/results.json"
"$GODOT" --headless --path "$scratch/branch" --script "$scratch/runner/$evidence/wrap_cost.gd"
```

`--part cost` or `--part modes` runs one part. Batch 1's branch is
c3041d98d675dce92550facfd4d0b1bb6472b002 in place of the second worktree. The runner needs a
display that stays awake (it was run under `caffeinate -d -i`), takes about 35 minutes for both
parts, and opens an always-on-top window for each capture. Timing varies between launches;
compare conditions within one batch.

## The page path in a browser

Asked by the re-review on PR #521 (its blocking finding: the page path had never run in a browser).
A release export (`tools/export-web.sh`, the custom template the release ships, built locally with
`tools/build-web-template.sh`) of commit 925a75b9c123dccfebd06edd5d37891b74f9e7df, served on a
port of its own and driven by `browser/drive.mjs` in headless Chrome 154 on the same M2, in a fresh
temporary profile that is removed afterwards. Headless Chrome draws through SwiftShader, a
software renderer, so every frame took 45-60ms and every kept frame is slow: **the timings in these
files say nothing about a real browser's speed**, only that the page path works.

What it showed (`browser/result.json`, every check passed, no engine or page error logged):

- `?debug=1&framerecord=1&seed=67`: one `save frames` button at the top of the page, right of the
  day's clock (`browser/button-and-readout.png`), and the readout's `slow` line under the frame
  block, for example `slow 45.6/45.3 ms  draw 33.5  crowd 6.2  events 1.7`.
- A click on the button downloaded `nappy-frames-seed67-<time>.json` through the browser's own
  download. It parses; every row's nine buckets add up to its `frame_usec`; `environment` carries
  the browser's user agent, `timer_resolution_usec` 100 (Chrome's reduced-precision clock step),
  `refresh_assumed` true and the seed 67; rows time a median of 274 calls a frame. The first file
  is kept gzipped beside it.
- After the click, focus was back on the canvas, and the keyboard still steered: 1.5s of the down
  arrow moved her from (2560, 2646) to (2560, 2786) in the next file's newest row.
- A restart through the pause screen (Esc, then R, which calls `_restart_run()`, the function the
  held restart reaches) left exactly one button, shown, and a click on it still downloaded the
  record, kept across the restart.
- `?debug=1&seed=67` alone, and `?framerecord=1&seed=67` without `?debug=1`, showed no button,
  and the recorder's page hook was never defined; without `?debug=1` the seed was ignored too.
- At a phone's size (844x390 CSS pixels, touch emulation) the button sits between the clock and
  the debug readout (`browser/phone.png`).
- No save was written in the profile, so the player's save, which lives in their own browser
  profile, was never in reach; `browser/scratch.json` records the browser closed through the
  protocol with no scratch left behind.

**The first run found a defect, fixed before this one.** At c5f1a175, the button was centred at
the top of the page and covered the day's clock, which is centred at the top of the canvas. Commit
925a75b9 moves its left edge 64 CSS pixels right of the centre. Those runs' screenshots are not
kept; every other check passed in them too.

Not covered: iOS Safari and Chrome on a phone, a touch tap on the button rather than a click, and
any timing on a real GPU. Those are the player's try on the phone.

The folder holds the driver, its result, the console log, the scratch report, the two screenshots
and one downloaded record (7 files, about 690KB, most of it the two screenshots).

```sh
source_root=$(git rev-parse --show-toplevel)
scratch=$(mktemp -d)
git -C "$source_root" fetch origin refs/pull/521/head
git -C "$source_root" worktree add --detach "$scratch/page" 925a75b9c123dccfebd06edd5d37891b74f9e7df
cd "$scratch/page"
tools/build-web-template.sh && tools/export-web.sh
node docs/evidence/m159-frame-record-2026-10-04/browser/drive.mjs --export build/web \
  --output "$scratch/browser" --browser "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```

The driver needs Node 22 and Chrome; the export needs the matching Godot editor (`GODOT=...`).
