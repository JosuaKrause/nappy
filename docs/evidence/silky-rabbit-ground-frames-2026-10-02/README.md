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

## Native comparison

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
whole-game atomic baseline. The comparison is against the rejected global-cap candidate;
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
these native results. The old synchronous `scenery_residency_acceptance.gd` probe requires its
documented historical revision; it cannot advance the current process-frame-gated scheduler.

## Reproduction

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
