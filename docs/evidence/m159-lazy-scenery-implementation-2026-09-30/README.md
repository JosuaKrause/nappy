# M159 — Nearby scenery implementation acceptance

This evidence checks the shipping implementation against the retained
[PR #444 preparation baseline](../m159-lazy-scenery-2026-09-30/README.md) and its
[generated-route workload](../m159-lazy-scenery-2026-09-30/ROUTES.md). It does not repeat that
investigation or establish a before/after frame-rate improvement.

## Policy and bounded loading checks

Ground owns freeable eight-by-eight-cell TileMapLayer children, each covering 256px. Buildings
retain gameplay identity, collision and entrance facts while releasing windows, roof furniture,
roof layers and retained draw commands. Decals and shadows prepare per chunk; props, markers,
home-door pictures and signal drawing join residency. Signals and other gameplay simulation
remain complete. Shared atlas pages and composed ground sheets remain resident.

The viewport loads 256px ahead, retains existing work out to 512px and synchronously protects
a 96px guard. At the maximum 168px/s run speed, the load margin gives 1.52s; the guard covers
the 92px facing reversal plus a physics step. Ordinary preparation has about 0.95s between
the load and guard boundaries. Retention adds another 1.52s before reversal requires reloading.
Production maintenance runs after 16px movement, while pending work drains each frame. A
2ms soft budget includes scans, sorting and pending preparation, finishing its current atomic
job. Relocations, changed viewport dimensions and emergency visible coverage are synchronous;
the limit is not a promise that every callback, boot or deferred draw completes within 2ms.

Three serial headless samples at tracked-clean revision
`7af2180646c6d3cb7514f75e8cf1d2192d161155` use the longest generated daily option, then retrace
it, on two seeds from #444. The probe selects open, branch-colored tile positions after real
Main closure/event planning, interpolates its camera envelope at 168/60 pixels per step, and
checks every visible ground cell and intersecting building. It is a camera workload, not a
tile-perfect player path or survival simulation. The collector directly calls every update;
it bypasses the production 16px maintenance cadence and excludes deferred drawing.

| Sample | Steps | Median / p95 / p99 / max update ms | Worst ground batch ms | Peak chunks | Missing / emergency catch-ups |
| --- | ---: | --- | ---: | ---: | --- |
| 4242, day 8, first | 6,118 | 0.392 / 0.414 / 0.503 / 2.207 | 0.329 | 42 | 0 / 0 |
| 4242, day 8, repeat | 6,118 | 0.392 / 0.413 / 0.485 / 2.256 | 0.331 | 42 | 0 / 0 |
| 3265820891, day 12 | 6,256 | 0.510 / 0.542 / 0.683 / 2.245 | 0.332 | 42 | 0 / 0 |

Home prepares 30 ground chunks, 1,432–1,460 static cells and 14 of 150–158 buildings. Complete
out-and-back camera itineraries cover 17,024–17,408px. Eviction invalidates every held final
ground node (35–41 nodes), releasing 675,592–772,064 tracked Godot static bytes. This counter
does not measure process RSS, driver/GPU allocations or all renderer-deferred resources.
The largest measured ground batch occupies about one sixth of the soft budget. These measured
updates include residency bookkeeping and shadow/decal preparation, not only TileMap filling.

The [compact results](results.json) retain every accepted row, exact commands, engine identity,
capture revision and a digest of the tracked runtime sources plus collector. JSON rows are
decoded from the scratch streams and checked for four passing assertions and no engine
warnings/errors. Development trials are excluded. No competing engine/build process runs during
these accepted samples. Apple M2, macOS, Godot 4.7.2 official debug build; native timings are
not browser, phone or GPU results.

## Rendered acceptance

Two real gameplay runs retain their complete original telemetry folders, including maps,
ordered logs, burst metadata and all 36 frames. The short
[arterial reversal](walking-reversal.mp4) and [shore reversal](shore-reversal.mp4) clips use
the burst timestamps. Sampled frames at the start, reversal and return show populated ground,
buildings, shadows, street furniture and continuous water; this is bounded visual evidence,
not exhaustive proof of every state or camera orientation. The controller reaches obstacles
on both outbound legs; invincibility preserves the observation window without testing costs.

The frame trace samples RenderingServer.frame_post_draw after five seconds of active warmup.
The retained aggregates use the following five seconds, before the burst begins at second 11,
so PNG capture overhead is excluded. The limit is the first sample plus 5,000,000 microseconds;
the final sample falls just short. Percentiles use nearest rank over positive intervals.

| Run | Samples | Actual travel in window | Median / p95 / p99 / max ms |
| --- | ---: | ---: | --- |
| Arterial, seed 4242 day 8 | 893 | 187.7px | 5.115 / 7.753 / 8.518 / 8.990 |
| Shore, seed 3265820891 day 12 | 703 | 2.1px | 6.354 / 10.847 / 13.087 / 15.191 |

The shore timing window is effectively stationary against an event, so it is not walking-frame
evidence. Its later reversal burst moves along the boundary and is visual evidence; capture
overhead makes that interval unsuitable for ordinary frame timing. The arterial timing window
includes movement and complete deferred rendering work, but this observer is a CPU callback,
not a physical presentation timestamp or GPU duration. Both runs have telemetry and the debug
readout enabled, VSync disabled, a 1280x720 viewport and the OpenGL compatibility renderer.
There is no pre-change control for these distributions and no claim of a causal improvement.
Full frame streams and console logs remain in scratch; their compact aggregates are sufficient
for the reported observation and fresh commands reproduce the experiment.

## Reproduction and checks

Fetch the PR reference before checking out the branch-only capture revision:

```sh
task_root=$(mktemp -d)
git fetch origin refs/pull/445/head
git worktree add --detach "$task_root/source" 7af2180646c6d3cb7514f75e8cf1d2192d161155
cd "$task_root/source"
./tools/check.sh
./tools/test.sh probes/scenery_residency_acceptance.gd --seed 4242 --day 8 --no-save
./tools/test.sh probes/scenery_residency_acceptance.gd --seed 4242 --day 8 --no-save
./tools/test.sh probes/scenery_residency_acceptance.gd --seed 3265820891 --day 12 --no-save
./tools/shot.sh "$task_root/walking.png" 16 --seed 4242 --day 8 --spawn arterial --walk 12N4S --invincible --frame-trace --press snapshot_burst 11
./tools/shot.sh "$task_root/shore.png" 16 --seed 3265820891 --day 12 --spawn corner:se --walk 12W4E --invincible --frame-trace --press snapshot_burst 11
```

The captures need a display server. Commands use fresh output paths and never overwrite these
recorded results. `tools/clip.sh <printed-burst-directory> <scratch-output.mp4>` reconstructs a
clip. The old #444 probes require their documented pinned revision because the live ground
owner is now a chunk container.

`check.sh`, doc lint and whitespace checks pass. The focused scenery, camera, main, shadow,
roof and ground suites pass 57,265 checks; the additional independent streamed/full shadow
seam parity and residency run passes 3,415. Blackout, posters, home, fallen-tree routes, blocks
and resistance pass 106,946 checks. That last run exposes a pre-existing resistance fixture
camera callback warning; its callback is corrected explicitly before the accepted captures.
The tests check identity/collision, RNG independence, current unloaded state, hysteresis,
day reset, actual Main destination preparation, water clock ownership and exact shadow tiles.
State assertions do not prove every final rendered pixel. Local verification is partial;
full-suite CI, independent review and browser/phone observation are separate checks. The separate
partly-visible animation queue item remains outside this implementation.

The route-curbstone suite visits every neighborhood and compares its actual resident source
and atlas coordinates against the complete independently derived route set. A reverse sweep
checks reconstruction after eviction; a complete finale sweep checks that no route tint remains.
That suite plus residency passes 9,248 checks after correcting the fixture's whole-map-resident
assumption. This test-only correction does not change the captured runtime source.
