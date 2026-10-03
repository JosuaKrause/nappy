# Nearby ground preparation across frames

The implementation advances at most one 4×4-cell renderer quadrant per region per process frame inside each
8×8 region. `TileMapLayer.update_internals()` flushes that step's renderer commands inside
the existing soft 2ms queue timer. A pending layer stays visible in-tree at its actual
off-screen coordinates: Godot's `TileMapLayer::_rendering_update()` explicitly cleans up
hidden layers. Its dirty-quadrant loop also rebuilds every cell in a dirty quadrant, so rows
in a default 16×16 quadrant repeatedly rebuild earlier rows. The pinned engine source is
[Godot's renderer update](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/2d/tile_map_layer.cpp#L225).

Pending allocations pause outside the load boundary and survive until the retention boundary.
They are excluded from resident queries until complete. Live ground edits, route-tint repaints
and resets discard stale partial state. Guard and destination preparation finish synchronously.
Water has one surface per populated quadrant, sharing the city's pausable phase.

## Matched before/after runtime experiment

[matched/results.json](matched/results.json) retains all nine trials: three each of the actual
atomic runtime, the global one-section-per-frame candidate, and the final per-region runtime.
[matched/order.tsv](matched/order.tsv) includes the three preceding warmups and the rotated
trial order: atomic/global/per-region, global/per-region/atomic, per-region/atomic/global.
There are no rejected trials or omitted outliers in this matched experiment. The collector is
`tests/probes/ground_frames_matched.gd` at
`6fbd8bfe3a9f5cfb1465cd6e3811c4fc9a1f4c5b`; its SHA-256 is
`3510730648614f351e5faa599c20adbeb4dc7196c5168e0964fb139e580ec8eb`.

The three clean tracked runtime revisions are atomic
`aae5c189bfe3a7d23530c6f06d17712c7d043807`, global
`59b5e6baee8300a6478e4e481c4de4dc7e996496`, and per-region
`a64abc1cf6f022cbb57e1a5e04edd7602f6f1adf`. The runner copies identical untracked collector
files into each detached checkout, imports it, checks tracked cleanliness and hashes tracked
`src/`, `scenes/`, `assets/` and `project.godot` after setup and before and after every launch.
The retained [atomic](matched/atomic.runtime.sha256), [global](matched/global.runtime.sha256)
and [per-region](matched/per-region.runtime.sha256) manifests differ only in the two ground
preparation/residency scripts. Every trial records its manifest digest and collector revision.

Each launch uses the same Godot 4.7.2 official debug executable on Apple M2/macOS, OpenGL
compatibility, VSync disabled, seed 4242, 1280×720 viewport and 640×360 world camera view.
No other engine or test suite runs during the timed captures. The production City and scenery
objects remain active; the collector supplies the production movement/pending-work update
cadence after moving a noninterpolated Camera2D. It asserts actual camera geometry against
coverage geometry every sampled frame. Ground/water and roof animation receive identical
modeled delta; normal wall-time animation cannot select different roof frames between trials.

Each south-60Hz, south-15Hz and diagonal-15Hz case builds a fresh city, settles for 120 rendered
frames, and traverses 30 modeled seconds at 168px/s: 15 seconds out from the doorstep and 15
back. These are actual Engine process frames with modeled movement increments, rendered
uncapped; they are not native wall-clock 15/60fps limits or playable survival routes. Long
legs enter the outside band. A separate shoreline relocation settles for 120 frames before
240 steady samples. Safety completion stays enabled and all production scenery guard calls
are counted. All 24,300 traversal frames have complete visible ground, and every launch has
zero forced draws. All 27 settled windows have identical cell and pixel hashes.

The common span starts at `SceneTree.process_frame` before modeled animation callbacks and
ends immediately at `RenderingServer.frame_post_draw`. It includes camera movement, scenery
queue work, deferred TileMap preparation, rendering callbacks and submission/waits encountered
there. Thus atomic's deferred renderer work remains inside the same span as the final
runtime's explicit `update_internals()`. It excludes physics before that signal, post-draw
coverage/identity observation, CSV output and image readback. Observer p99 is 41–56µs across
traversal trials, reported separately. Common fixture callback overhead remains in every span.
Queue-only distributions are diagnostic: atomic defers renderer work beyond that timer.

Ranges below are the minimum and maximum of three per-trial statistics, not pooled samples;
the maximum column keeps the single worst sample. Full median/p95/p99/max, sums and frame-budget
counts for traversal, queue and steady windows remain in the JSON.

| Itinerary | Runtime | Median range ms | p99 range ms | Worst ms | Guard catches per trial |
| --- | --- | ---: | ---: | ---: | ---: |
| South 60Hz | Atomic | 1.190–1.202 | 4.627–5.274 | 8.710 | 0 |
| South 60Hz | Global section cap | 1.088–1.091 | 4.310–4.532 | 7.332 | 0 |
| South 60Hz | Per-region | 1.067–1.070 | 4.292–4.441 | 7.414 | 0 |
| South 15Hz | Atomic | 1.263–1.291 | 4.534–5.756 | 6.416 | 0 |
| South 15Hz | Global section cap | 1.287–1.292 | 4.610–5.349 | 5.749 | 16 |
| South 15Hz | Per-region | 1.125–1.141 | 4.445–5.756 | 6.833 | 0 |
| Diagonal 15Hz | Atomic | 1.433–1.444 | 5.173–5.601 | 7.201 | 0 |
| Diagonal 15Hz | Global section cap | 1.406–1.429 | 4.764–5.647 | 6.407 | 31 |
| Diagonal 15Hz | Per-region | 1.329–1.339 | 4.765–5.266 | 7.667 | 0 |

Ordinary south-60Hz median spans are about 11% lower for per-region preparation than atomic;
p95 is 2.849–3.073ms versus 3.519–4.021ms. The 15Hz tails overlap and maxima are mixed, so
these samples do not establish a universal frame-time improvement. No traversal or steady
sample exceeds 16.667ms, 33.333ms or 66.667ms in this controlled native workload. The stricter
global rule gives no consistent advantage over per-region preparation and repeatedly reaches
the safety guard at 15Hz. This supports the per-region choice over the stricter rule for
ordinary preparation throughput; it does not establish perceptible whole-game improvement.

Completed-region counts per trial are 102/102/130 for atomic, 99/96/95 for global and
102/96/130 for per-region over south60/south15/diagonal15. Early completion and retention make
these totals differ even with identical camera paths. `observed_sections` derives progress
from before/after pending steps and newly published owners, including guard-drained steps:
atomic counts whole-region units; stepped runtimes count quadrants. It is not an instrumented
count of every transient internal operation. The global diagonal route discards two partial
jobs per trial. Per-region routes discard none and retain at most 6/6/10 pending owners.

The settled shoreline has 18 regions, 976 populated cells including 336 water cells, and the
same pixels for every runtime. Atomic has 6 water surfaces and 38 draw calls; both stepped
runtimes have 24 water surfaces and 46 draw calls. Clearing ground releases 482,528–482,552
tracked static bytes for atomic versus 776,624–776,720 for stepped preparation, about 61% more.
This is a ground-release Godot allocation delta, not RSS or GPU memory. Steady median spans
are 0.792–0.814ms atomic, 0.818–0.838ms global and 0.818–0.842ms per-region; the extra quadrants
and water objects have a measurable steady cost. These are controlled rendered-city scenery
results, excluding Main, crowds and events, browser/iPhone/Safari, GPU duration and physical
presentation. The bounded-preparation choice carries this overhead; the experiment does not
justify claiming that every platform or active-game frame becomes faster.

## Isolated preparation comparison

The collector is `tests/probes/ground_frames.gd` at clean revision
`a64abc1cf6f022cbb57e1a5e04edd7602f6f1adf`, with source and collector SHA-256 values in
[native.json](native.json). It runs on an Apple M2 with Godot 4.7.2 official debug,
OpenGL compatibility, a 1280×720 viewport and VSync disabled. No competing engine test runs
during the accepted capture. Each strategy gets one unretained warmup, followed by three
retained trials in atomic, rows, quadrants order. Every trial prepares the same eight map
regions (four ordinary, four shoreline), with 408 nonempty cells from seed 4242.

The controlled microfixture uses current map source and atlas lookup for all strategies.
Atomic prepares all 64 candidate cells at once with the default renderer quadrant size;
rows prepares eight candidates per step with that same default; quadrants prepares sixteen
candidates in each independent 4×4 quadrant. All explicitly flush TileMap internals so the
reported preparation includes renderer command creation. Layer construction is outside the
microfixture timer; the production step timer includes it. These are strategy controls in
one revision, not before/after whole-game frame measurements.

| Trial | Strategy | Median / maximum step µs | Maximum renderer flush µs | Total preparation µs | Tracked retained bytes |
| --- | --- | ---: | ---: | ---: | ---: |
| 0 | Atomic | 182 / 260 | 45 | 1,322 | 190,212 |
| 0 | Rows | 35 / 81 | 21 | 2,468 | 408,044 |
| 0 | Quadrants | 45 / 104 | 24 | 1,754 | 332,764 |
| 1 | Atomic | 191 / 279 | 55 | 1,339 | 194,940 |
| 1 | Rows | 33 / 71 | 21 | 2,289 | 408,044 |
| 1 | Quadrants | 42 / 103 | 24 | 1,684 | 332,692 |
| 2 | Atomic | 183 / 251 | 47 | 1,291 | 194,940 |
| 2 | Rows | 32 / 73 | 20 | 2,273 | 408,044 |
| 2 | Quadrants | 46 / 107 | 25 | 1,722 | 332,692 |

Quadrants reduce the maximum bounded preparation span while spending more total work and
retained allocation than atomic preparation. Rows have smaller steps but more repeated renderer
work and more water surfaces. The eight-region fixture holds 4 / 28 / 16 water surfaces for
atomic / rows / quadrants. Retained byte deltas are Godot static allocation, not RSS or GPU
memory, and include both the TileMap and water surface cost. Pending jobs retain a partly
built version of these allocations between the load and retention boundaries; this cost is
bounded spatially by the retention ring, rather than growing with the explored city.

For completed ground and water viewed separately, all nine trials have identical pixel hashes.
Each trial measures twenty steady frames per view; the combined mean draw-call counts are
58 / 70 / 64.5 for atomic / rows / quadrants. Steady callback-span medians are 0.730–0.777ms
across all trials; their tails and full per-trial aggregates remain in the JSON. This small
sample does not establish a steady frame-rate improvement. More quadrants and water materials
are a measured overhead, accepted here to bound ordinary approach preparation.

## Coverage and gameplay

The same collector advances actual process frames over 30 modeled seconds, with 15 seconds
out and 15 back at 168px/s. South, east and diagonal approaches run at modeled 15/30/60Hz:
movement advances by speed/rate while the native renderer runs as fast as it can. The production
movement threshold and pending-work cadence apply. A real camera has a 640×360 world view;
the collector asserts `camera_view()` matches the checked rectangle every frame and disables
interpolation only on that manually moved fixture camera. This is a camera stress itinerary,
not a generated playable route or survival test; its longer legs can reach the outside band.

The same collector on clean candidate `59b5e6baee8300a6478e4e481c4de4dc7e996496` supplies
[global-cap.json](global-cap.json). One quadrant globally per frame causes 16 southward and
31 diagonal guard catches at modeled 15Hz. The synchronous guard preserves coverage, but the
candidate defers too much work until that last boundary. The final scheduler advances distinct
regions together under the unchanged budget, with one step per region per frame. Its fence
survives job cancellation and recreation in the same frame.

| Modeled rate | Direction | Completed regions | Global-cap guard catches | Final guard catches / missing | Final worst step / update µs |
| --- | --- | ---: | ---: | ---: | ---: |
| 15 | South | 96 | 16 | 0 / 0 | 151 / 1,041 |
| 15 | East | 85 | 0 | 0 / 0 | 134 / 1,053 |
| 15 | Diagonal | 130 | 31 | 0 / 0 | 124 / 1,357 |
| 30 | South | 102 | 0 | 0 / 0 | 157 / 1,030 |
| 30 | East | 85 | 0 | 0 / 0 | 122 / 870 |
| 30 | Diagonal | 130 | 0 | 0 / 0 | 150 / 1,286 |
| 60 | South | 102 | 0 | 0 / 0 | 150 / 1,058 |
| 60 | East | 85 | 0 | 0 / 0 | 138 / 939 |
| 60 | Diagonal | 130 | 0 | 0 / 0 | 140 / 1,305 |

Every final completion crosses distinct process frames. Faster completion retains more regions
before a turn, so candidate and final counts need not match. Native frame callback spans and
all per-case distributions remain in the JSON; the final maximum is 5.900ms. These spans include
frame scheduling, are neither GPU duration nor physical presentation latency, and have no
atomic runtime baseline within that rate sweep. The comparison is against the rejected global-cap candidate;
the atomic strategy above is only the isolated preparation control. No forced draw is needed
in either retained rate-sweep launch.

A separate 92px camera look-ahead reversal on clean
`a5495e7e4f996fc15b4c2f7997873004dea3e734` retains [facing.json](facing.json). It completes
85 regions over 1,800 actual process frames at modeled 60Hz, with no missing region or guard
catch-up. Its worst ground step is 133µs and worst update 888µs. The callback span through
drawing has a 33.259ms maximum outlier (1.164ms median, 3.310ms p95); it is retained and not
attributed to ground or removed from the report. There are no forced draws. This capture adds
the offset change that reversing movement direction alone does not exercise.

The real gameplay capture is clean runtime revision
`a5495e7e4f996fc15b4c2f7997873004dea3e734`; its runtime sources match the hashes in `native.json`
(the final collector revision changes only its own camera fixture).
The retained original folder, `rig-192539-seed4242-v0.21.4-8-ga5495e7e-dirty`, contains its run log,
map, timing metadata and all 36 frames. The [three-second clip](walking-reversal.mp4) is encoded
from those timestamps. The rig runs north along an arterial on day 8, then reverses south.
The first, pre-reversal and final frames show continuous ground while crossing a junction.
Invincibility makes this scenery evidence, not a cost or loss test. PNG capture overhead is
visible in the run's frame timings; those intervals support no normal-game performance claim.
The folder's `-dirty` marker includes untracked files: only the evidence folder is untracked
at capture, with no tracked source modifications. Runtime hashes match the native result.

The earlier native launch at `cdb0f71b17ec0daf58e7f555a7ebc799ddba0b6d` is development-only:
its rendered coverage rectangle is wider than the checked model. The next launch at
`d1d615ce` is rejected because the added geometry assertion catches the manually moved
camera's physics interpolation. Neither contributes to the accepted timing table. Headless
development runs check behavior only. The first optional reversal-mode launch at `2f659122`
fails on a typed-array assignment before taking measurements and is excluded. Browser/phone
perception, GPU timing and performance with the complete game's competing work remain outside
these native results. The current tree contains no synchronous
`scenery_residency_acceptance.gd` probe: its archived original must run at the revision
documented in [M159 implementation acceptance](../m159-lazy-scenery-implementation-2026-09-30/README.md).
That synchronous loop cannot advance the process-frame-gated scheduler. Current validation
uses the real-process-frame `ground_frames.gd` and `ground_frames_matched.gd` probes.

## Reproduction

For the matched runtime experiment, use the committed runner; it creates and removes its own
three clean detached runtime checkouts, uses a configurable executable and a fresh caller-relative
scratch directory, and retains full logs and per-frame CSVs outside the repository:

```sh
git fetch origin refs/pull/452/head
task_root=$(mktemp -d)
git worktree add --detach "$task_root/collector" 6fbd8bfe3a9f5cfb1465cd6e3811c4fc9a1f4c5b
cd "$task_root/collector"
./tools/measure-ground-frames.sh --godot "$GODOT" --output ./matched-results
```

The runner rejects unknown/missing arguments before creating files, validates clean source
identity for every launch, stops on errors or coverage failures, and requires cross-strategy
settled cell/pixel equality before accepting the comparison. Its collector has a two-minute
deadline and each native launch has an external 150-second kill. Headless boot/parse, doc lint,
CLI help/error checks and whitespace checks pass for this collector; no runtime source changes
or additional gameplay captures are part of this experiment.

Run from a clone with a configured `GODOT` executable. Fetch the durable PR reference before
checking out either branch-only revision, and use new scratch output paths:

```sh
task_root=$(mktemp -d)
git fetch origin refs/pull/452/head
git worktree add --detach "$task_root/source" a5495e7e4f996fc15b4c2f7997873004dea3e734
cd "$task_root/source"
./tools/check.sh
GROUND_FRAMES_OUTPUT="$task_root/native.json" "$GODOT" --path . --disable-vsync \
  res://tests/probes/ground_frames.tscn -- --no-save --no-telemetry
GROUND_FRAMES_FACING_ONLY=1 GROUND_FRAMES_OUTPUT="$task_root/facing.json" \
  "$GODOT" --path . --disable-vsync res://tests/probes/ground_frames.tscn -- --no-save --no-telemetry
./tools/shot.sh "$task_root/walking.png" 8 --seed 4242 --day 8 --spawn arterial \
  --walk 5N3S --invincible --press snapshot_burst 3
```

For the rejected global-cap rate sweep, use a separate detached worktree at
`59b5e6baee8300a6478e4e481c4de4dc7e996496` and run the normal collector command with a fresh
output path. For the exact accepted rate-sweep collector use
`a64abc1cf6f022cbb57e1a5e04edd7602f6f1adf`; the final collector adds only the optional facing mode.
The probe exits nonzero on a pixel mismatch, camera mismatch, missing visible region or absent
multi-frame completions. `--headless` checks state without rendered timing or pixel claims.
The collector has a two-minute deadline. `tools/clip.sh <printed-burst-folder> <scratch.mp4>`
reconstructs the short clip. Routine test output and full frame-trace streams stay in scratch.
Boot, focused ground/source/route-tint tests, day/finale/orientation tests, doc lint and whitespace
checks pass; local testing is partial and the full suite belongs to CI.
