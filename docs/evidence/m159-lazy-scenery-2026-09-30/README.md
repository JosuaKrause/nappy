# M159 — Nearby scenery preparation and eviction

Lazy map-specific preparation has a measurable opportunity. In this bounded native experiment,
preparing ground sources and cells for the initial viewport plus 128px costs 1.53–1.60 ms,
against 79.16–82.20 ms for the full map and border. The detached TileMapLayer's measured Godot
static allocation is about 0.10 MB nearby versus 5.90–5.95 MB full. **This is a counterfactual
preparation experiment, not a shipping implementation or a measured frame-rate improvement.**
It excludes engine frame processing, render quadrants, GPU work, water setup and gameplay.

**The primary coverage baseline is the game's generated daily route network.** The
[generated-route report](ROUTES.md) measures actual Main boots with daily closures/events planned:
one offered option with a retraced return covers 3.9–29.8% of prepared ground in the sampled
envelopes, while the union of every offered route plus home covers 35.9–59.8%. The latter is
not one itinerary. The unrestricted BFS examples below are ancillary and are not this baseline.

The experiment supports making visual ground chunks resident near the camera. It does not
support evicting shared atlas pages or entire Building nodes. It also exposes an eviction
constraint: `TileMapLayer.clear()` retains the measured allocation; freeing the detached layer
returns the static counter exactly to baseline. Chunk ownership needs to permit actual release.

## Conditions and reproducibility

[results.json](results.json) preserves every accepted row, capture revision, exact command,
engine/processor identity, and SHA-256 hashes of all production GDScript, the collector,
project settings and measurement wrapper. Source revision is
`6aa23ba14cd69d77915b2b0875b0b69f240e5c0f`, with clean tracked files before capture and matching
hashes afterwards. [measure.py](measure.py) runs the probe with an external 90-second bound and
requires all expected rows, passing checks, and no engine error or warning. Compact rows are
checked against the original scratch stream before retention. Raw logs remain in scratch.

Godot 4.7.2 official `ed1daf0bf`, Apple M2, macOS, headless debug build. One serial process,
shared pages acquired before timing, no warmup frames and no active-play window. Order is
trial 0/1/2, each seed 4242 then 3265820891; each city build then days 1, 8, 14. Trial 0 also
samples coverage and the subset experiment before day 1. Subset order per seed is full,
nearby, nearby, full. Timed spans use the monotonic microsecond clock. No competing heavy build
runs during this capture. These are repeated spans in one process, not independent launches.

The timed City subclass calls the production methods unchanged and times their outer spans.
Daily state advances scheduled block changes, with no intervening played days, consumed events,
resistance history or meter simulation. `City.start_day()` includes closure/route planning but
does not include Main's subsequent event and crowd start. Pending daily nodes are explicitly
freed after measuring each day's synchronous work; recorded daily node counts include nodes
awaiting that free. This avoids silently accumulating old nodes across the synchronous probe.
Neither this harness nor the detached subset measures complete-frame median/tails/max.

From a checkout containing this evidence, use a fresh revision checkout and scratch directory:

```sh
task_root=$(mktemp -d)
git worktree add --detach "$task_root/source" 6aa23ba14cd69d77915b2b0875b0b69f240e5c0f
cd "$task_root/source"
export GODOT=/path/to/Godot
./tools/check.sh
python3 docs/evidence/m159-lazy-scenery-2026-09-30/measure.py --output "$task_root/results" --godot "$GODOT"
```

`check.sh` prepares the ignored atlas/import cache and boots headless. The wrapper refuses a
dirty tracked checkout and an existing output directory. Every probe run carries `--no-save`;
the final real-boot geometry observation also carries seed 4242. No probe uses invincibility.
The geometric routes do not execute gameplay at all.

Validation: import/boot passes; the accepted probe passes 14 checks, including nonempty subset
parity with every corresponding production cell, complete full-map parity, and actual boot
camera geometry. Doc lint and whitespace checks pass. Local testing is a PARTIAL RUN; CI owns
the full suite. Wrapper help exits without a capture and unknown options are rejected.

Rejected development trials are not measurements: the initial sandboxed import cannot write
Godot logs; an incorrect scene path is corrected before successful validation; one probe frees
a parent before checking its already-freed child; an intermediate memory measurement retains a
temporary `get_used_cells()` array across samples. The final collector avoids the array in its
memory interval and validates every cell with coordinate iteration. Successful development
timings are superseded by the clean accepted capture, not pooled with it.

## Measured preparation

Ranges cover all six builds or all eighteen sampled day starts. Inclusive nested spans are not
added together. Per-trial values remain in the JSON.

| Native CPU span | Median ms | Range ms |
| --- | ---: | ---: |
| City generation, before scene build | 220.88 | 220.72–231.46 |
| City.build total | 110.40 | 109.55–120.40 |
| Boot ground paint, including composition | 94.51 | 93.87–101.13 |
| Boot shared-sheet composition | 20.79 | 20.65–23.16 |
| Building creation within build | 9.71 | 9.50–10.91 |
| City.start_day total, days 1/8/14 combined | 511.67 | 416.84–536.30 |
| Daily ground paint, including composition | 103.40 | 93.16–107.52 |
| Daily shared-sheet composition | 20.69 | 20.57–20.86 |
| Daily block dressing | 35.37 | 2.04–43.57 |
| Daily closure/route planning | 336.96 | 308.11–352.64 |

The combined day median spans different workloads; it is not a forecast for one day. Day 1
dressing is around 2 ms; later sampled days rebuild condition/day-dependent building decoration
and create more props. The dominant daily span here is closure/route planning, which visual
streaming must retain. Lazy scenery cannot remove all startup work.

`City.build()` paints once; Main then calls `_start_day()`, which calls `City.start_day()` and
paints again before the title/play state is ready. The temporary boot camera and warmup frames
sit between those calls. Thus the first paint is real work with a visible purpose, not safely
deletable wholesale. Both stages should use the same nearby-residency policy; the first day's
correct state still has to be installed before play. Cross-day sheet reuse is not required.

## Ancillary unrestricted-map geometric samples

These retained initial samples are BFS routes over walkable base-map tiles, with a 640×360 camera rectangle
centered at each sampled tile center. They omit daily closures, live bodies, danger, camera
look-ahead/smoothing, roof overhang and time limits. They are **geometric samples, not actual
played routes or evidence of typical human exploration**. Ground means static used cells,
excluding the separate water surface and blank cells under buildings. Buildings mean lot
intersection, not exact pixels. Reversing the same route adds no new rectangles.

| Seed / geometric return route | Distance px | Ground ever covered / prepared | Building lots covered / prepared |
| --- | ---: | ---: | ---: |
| 4242 / nearest calm | 2,496 | 787 / 22,866 (3.4%) | 13 / 158 |
| 4242 / farthest BFS calm | 7,680 | 1,592 / 22,866 (7.0%) | 33 / 158 |
| 3265820891 / nearest calm | 3,392 | 849 / 23,083 (3.7%) | 14 / 150 |
| 3265820891 / farthest BFS calm | 7,936 | 1,856 / 23,083 (8.0%) | 22 / 150 |

At boot only 4–5 building lots intersect the view, while 150–158 buildings and 515–547 nodes
in their subtrees are prepared, including 214–230 roof SceneryLayer nodes. There are also
95–97 prebuilt shadow chunks. Headless preparation does not execute their `_draw()` callbacks,
so these numbers do not count retained rendering-server drawing commands or their bytes.

The real Main boot confirms a 1280×720 viewport, zoom 2, camera center `(2560,2704)` at the
doorstep before the player exists. Its world rectangle is `(2240,2524)` through `(2880,2884)`.
The literal home block is `(2432,2432)` through `(2688,2688)`, only 256×256. Of the visible static
ground cells, 204–206 are outside that block and four inside. Even a whole literal home block
cannot fill this viewport. The practical boundary question is whether “the block around home”
means nearby scenery sufficient to cover this actual view. This report does not silently widen
that request into the entire city or choose missing scenery as acceptable.

Measured roof extensions/furniture rise up to 96px north of their own lot in these seeds.
The source's separate power-station stacks rise 192px from their feet. Whole visual bounds,
including extensions, shadows, trees and stacks, must control eligibility. Building origins
at their south edges and block origins alone are insufficient.

## The bounded ground counterfactual

The probe uses the same composed TileSet, production ground-source selection, coordinate
variation and border-source logic. It creates a detached TileMapLayer, inserts either the full
static ground or cells intersecting the boot viewport plus 128px, validates parity, clears,
and frees it. It omits water and has no engine frame or renderer update between operations.
The 128px margin is an illustrative experiment setting, not a chosen gameplay policy.

| Seed | Full / nearby cells | Full preparation ms, both trials | Nearby preparation ms, both trials | Full / nearby static bytes |
| --- | ---: | --- | --- | ---: |
| 4242 | 22,866 / 404 | 82.204, 79.812 | 1.596, 1.579 | 5,897,668 / 105,828 |
| 3265820891 | 23,083 / 388 | 79.628, 79.156 | 1.541, 1.530 | 5,948,012 / 102,116 |

Clearing takes 0.426–0.506 ms full and 0.007–0.008 ms nearby. Every sample retains its allocation
after clear and returns to baseline after free. Recreating nearby ground is measured twice;
fast reversal through a live eviction boundary is not. Static-memory counters are measured
CPU allocations tracked by Godot, not process RSS, browser heap, GPU allocation or guaranteed
operating-system reclamation. The experiment gives a direction and a mechanism worth building,
not a calibrated production savings estimate.

All cells share one 424×444 composed sheet: 753,024 base RGBA8 bytes by dimension estimate,
unchanged by the subset. Buildings, street kit, ground and decoration baked pages together are
1,801,600 base RGBA8 bytes; pages are held process-wide by Main. These are estimates without
mipmaps, driver padding or upload copies, not measured GPU memory. The six pages acquired by
this harness are not Main's complete nine-page boot set. Evicting cells or roof layers does not
free shared pages. Lazy cell preparation therefore does not make shared composition obsolete;
the roughly 21 ms composition still exists unless separately changed, which this work does not do.

## Existing culling and implementation boundary

Rendering already avoids much off-screen drawing. Ground uses TileMapLayer render quadrants;
Godot describes these as tiles grouped into a CanvasItem, with a default 16×16-cell quadrant
([engine documentation](https://docs.godotengine.org/en/4.6/classes/class_tilemaplayer.html#class-tilemaplayer-property-rendering-quadrant-size)).
BuildingShadows deliberately splits drawing into 16×16 chunks so CanvasItem bounds can cull
them. Buildings and their separate scenery children retain drawing commands until invalidated.
This source audit identifies retained preparation beyond rendering culling; it does not measure
GPU culling efficiency. CityDecals draws its map-wide litter/tree-pit list in one item, making
spatially bounded decal drawing a distinct useful boundary.

A production step can introduce visual ground chunks first while preserving CityMap and every
gameplay system eagerly. Keep shared baked pages and runtime ground composition at allowed
loading moments; nearby-only cells do not authorize a first-visible-frame disk read or shader
compile. Free chunks beyond a wider retention boundary, with a bounded pool if reuse wins
measurement. A single TileMapLayer repeatedly cleared is not demonstrated memory eviction.

Building work requires separating visual rebuild from collision first. `Building._rebuild()`
creates the collision shape alongside windows/front/entrance/roof layers. City, Blackout and
PosterWalls retain the Building objects. Keep those identities, footprints and collisions live;
make only visual descriptions/layers resident. Derive stable appearance from existing seeded
inputs, preserving generation and gameplay RNG call order. Do not resample art on approach.

Preparation needs a time budget and separate entry/retention margins. The source permits
168px/s running and up to 46px camera look-ahead; budget must also cover view changes and the
measured overhang. Chunk batches need measured worst-case creation costs, priority toward
motion, and cancellation/reprioritization on reversal. Instant camera relocation needs a
loading/warmup gate or synchronous destination preparation before revealing the new view;
ordinary velocity-based look-ahead cannot solve a jump. No numeric shipping budget or margin
is chosen by this experiment.

Unloaded visuals need versioned reconstruction for current day/condition, poster contents,
blackout power, sealed home door/window, emptied tree pits, closure markers and daily litter.
`close_ground()` changes tiles plus neighboring edge appearances mid-day, while `present_block()`
changes a block's condition live. Store those facts independently of residency; rebuilding
must consult them, not stale cached pictures. Water remains a separate animated surface and
station stacks retain entity painter order. Static surfaces never regain animated pixels.

Remaining acceptance work for an implementation is repeated complete-frame measurement with
identical actual routes, fast approaches and reversals, overnight changes outside residency,
camera jumps, rendered seam/pop-in checks, and browser/phone memory and timing. None is
established by this native headless investigation, and no production lazy behavior ships here.
