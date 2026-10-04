# The three ground preparation modes, side by side

The question: what each of the three `--ground-mode` values costs in the matched native comparison
[silky-rabbit](../silky-rabbit-ground-frames-2026-10-02/README.md) ran for atomic and stepped
preparation. The player asked for mode 2 to be measured "like we measure option 1 and 3"
([tawny-stork](../../playtests/2026-10-03-tawny-stork.md), statement 3). Mode 1, the default,
prepares every region needed in a frame whole in that frame; mode 2 prepares at most one whole
region a frame; mode 3 is silky-rabbit's per-region stepping, one renderer quadrant per region per
process frame.

## What was run

`tools/measure-ground-frames.sh` at `51e794447590a6c8f3940bd3dce4cc387ed4e8cc` imports one clean
detached checkout of that revision and launches the same runtime and collector bytes
(`tests/probes/ground_frames_matched.gd`, SHA-256
`4de67aa969ddc47d7492911af6cc73ce6c28fc774eb661e43cf9cd70f1abc31a`) with `--ground-mode 1`, `2`
and `3`. [run-1/runtime.sha256](run-1/runtime.sha256) hashes every tracked file under `src/`,
`scenes/`, `assets/`, `project.godot` and the collector; it is checked before and after every
launch, and both runs have the same manifest. Each run is one warmup per mode, then three trials
each in the rotated order mode 1/2/3, 2/3/1, 3/1/2, which `order.tsv` records with the load
average before each launch. Each launch reports the mode its city actually ran, and the runner
rejects one that differs, one with a forced draw, and one beside which any other Godot process
ran.

Godot 4.7.2 official on an Apple M2 under macOS, OpenGL compatibility, VSync disabled, seed 4242,
a 1280×720 viewport and a 640×360 camera view: silky-rabbit's settings, with its itineraries
and span unchanged. South at modeled 60Hz, south at 15Hz and diagonal at 15Hz each travel 30
modeled seconds at 168px/s, 15 out and 15 back, after 120 settling frames; the shoreline
relocation then settles for 120 frames and samples 240. The span runs from
`SceneTree.process_frame` to `RenderingServer.frame_post_draw`, so the deferred renderer work of
modes 1 and 2 is inside it as much as mode 3's explicit flush. Ranges are the minimum and maximum
of the three per-trial statistics; "worst" is the single worst sample.

Two complete runs are retained, [run-1](run-1/results.json) and [run-2](run-2/results.json),
taken back to back with no other Godot process running and a one-minute load average between 2.0
and 3.7 from other work on the machine.

## Ordinary traversal spans

| Itinerary | Mode | Run | Median ms | p95 ms | p99 ms | Worst ms | Guard catches | Regions per trial |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| South 60Hz | 1, all | 1 | 1.196–1.412 | 3.670–4.858 | 4.916–5.528 | 12.864 | 0 | 102 |
| South 60Hz | 1, all | 2 | 1.253–1.299 | 4.000–4.586 | 5.170–5.406 | 8.055 | 0 | 102 |
| South 60Hz | 2, one | 1 | 1.191–1.477 | 3.495–4.402 | 4.976–5.991 | 9.793 | 0 | 102 |
| South 60Hz | 2, one | 2 | 1.268–1.295 | 4.077–4.351 | 5.173–5.473 | 8.833 | 0 | 102 |
| South 60Hz | 3, stepped | 1 | 1.062–1.117 | 2.764–3.967 | 4.568–4.905 | 8.586 | 0 | 102 |
| South 60Hz | 3, stepped | 2 | 1.102–1.122 | 3.540–4.276 | 4.717–5.142 | 8.058 | 0 | 102 |
| South 15Hz | 1, all | 1 | 1.256–1.555 | 3.910–5.216 | 5.010–5.824 | 7.054 | 0 | 102 |
| South 15Hz | 1, all | 2 | 1.339–1.373 | 4.443–5.053 | 5.449–6.556 | 7.553 | 0 | 102 |
| South 15Hz | 2, one | 1 | 1.273–1.701 | 3.431–4.932 | 4.944–6.261 | 39.578 | 0 | 99 |
| South 15Hz | 2, one | 2 | 1.383–1.396 | 4.430–4.779 | 5.383–5.708 | 6.196 | 0 | 99 |
| South 15Hz | 3, stepped | 1 | 1.107–1.221 | 2.876–4.433 | 4.320–5.575 | 6.145 | 0 | 96 |
| South 15Hz | 3, stepped | 2 | 1.186–1.198 | 3.539–4.438 | 4.592–5.500 | 6.739 | 0 | 96 |
| Diagonal 15Hz | 1, all | 1 | 1.416–1.801 | 4.109–5.506 | 4.630–5.978 | 7.399 | 0 | 130 |
| Diagonal 15Hz | 1, all | 2 | 1.514–1.542 | 4.870–5.283 | 6.020–6.805 | 8.626 | 0 | 130 |
| Diagonal 15Hz | 2, one | 1 | 1.501–4.772 | 4.826–18.904 | 5.736–27.166 | 116.551 | 0 | 128 |
| Diagonal 15Hz | 2, one | 2 | 1.637–1.654 | 4.836–5.027 | 5.724–6.255 | 6.705 | 0 | 128 |
| Diagonal 15Hz | 3, stepped | 1 | 1.312–1.468 | 4.397–4.641 | 5.330–5.612 | 7.690 | 0 | 130 |
| Diagonal 15Hz | 3, stepped | 2 | 1.394–1.598 | 4.866–5.058 | 5.464–5.999 | 12.270 | 0 | 130 |

**Run 1's last two launches were disturbed.** Its trial 2 of mode 1 (launch 10) and of mode 2
(launch 11) ran 9.1s and 11.9s against 6.6–7.1s for every other launch, and their steady
shoreline medians, which do not prepare anything, rose from 0.79–0.87ms to 0.89–1.22ms with them.
Mode 2's diagonal in launch 11 has 32 samples over 16.667ms and the 116.551ms worst sample; run 2,
the same commands minutes later, has none over 16.667ms in any mode. No other Godot process ran,
so the disturbance came from other work on the machine; the samples are kept and not attributed
to a mode. Run 1's trials 0 and 1, and all of run 2, agree with each other.

Read across both runs: mode 2 costs about what mode 1 does at 60Hz, and at 15Hz it has slightly
higher medians (run 2: 1.383–1.396ms against 1.339–1.373ms south, 1.637–1.654ms against
1.514–1.542ms diagonal) with lower p99 and worst samples than mode 1 there. Mode 3 has the lowest
medians on both south itineraries, as silky-rabbit measured; on the diagonal and in every tail
the three modes' ranges overlap. No mode needed the safety guard in any trial, all 48,600 retained traversal frames
have complete visible ground, and the collector's mode-2 check, that no frame prepares a second
region outside the guard, holds on every one of mode 2's frames. Mode 2 prepares exactly one
region in its busiest frame; modes 1 and 3 complete up to ten. Mode 2 completes fewer regions
over the same route (99 against 102 south at 15Hz, 128 against 130 diagonal) because a region it
has not reached yet is not prepared before the camera turns back.

## Settled shoreline

| Mode | Draw calls | Water surfaces | Tracked bytes released by clearing ground | Steady median ms |
| --- | ---: | ---: | ---: | ---: |
| 1, all | 38 | 6 | 482,528–482,552 | run 1 0.790–1.006, run 2 0.805–0.839 |
| 2, one | 38 | 6 | 482,528–482,552 | run 1 0.789–1.220, run 2 0.796–0.823 |
| 3, stepped | 46 | 24 | 776,624–776,720 | run 1 0.816–0.873, run 2 0.816–0.873 |

The shoreline holds 18 regions; every trial of every mode has the same cells and the same pixels,
which the runner requires before accepting the comparison. Modes 1 and 2 build a region the same
way, so they have the same draw calls, water surfaces and allocation, and those are the numbers
silky-rabbit measured for atomic preparation (38, 6, 482,528–482,552); mode 3's are the ones it
measured for per-region stepping (46, 24, 776,624–776,720). The allocation figure is Godot's
tracked static memory released when the ground is cleared, not RSS or GPU memory.

## Rejected runs

[rejected/contended-run](rejected/contended-run/results.json) is a complete run at
`99ad40950860000c25a0a626e82a326e110be8eb`, the runner before it checked for competing engines.
Another checkout's headless test suite started a minute in and ran through all nine retained
captures with a one-minute load average of 11 to 23, and mode 1's trial 1 forced 4,056 draws
because its window was covered. Its medians are 1.7–3.3ms; it is kept as the reason the runner
now waits for and rejects competing engines and forced draws, and is not part of the comparison.
Its settled-shoreline workload is the same as above.

Seven further attempts at `1be90c8b`, `8e671c8e` and `d0da9f37`, before the runner retook a
contested capture in its own slot, each stopped when another checkout's Godot process ran: twice
before the first capture, twice at the first warmup, and once each at launches 4, 7 and 9. Their
captures are not retained, since none of those runs reached results.

## Limits

These are controlled native City and scenery fixtures, not the whole game: Main, crowds, events,
physics before the process signal, GPU duration, physical presentation and the browser and phone
are outside them. The spans are callback-to-post-draw spans on one Apple M2, not frame pacing on
the phone the modes are meant to be compared on.

## Rerun

From a clone with a Godot executable in `GODOT`, in a fresh scratch directory:

```sh
git fetch origin refs/pull/475/head
task_root=$(mktemp -d)
git worktree add --detach "$task_root/source" 51e794447590a6c8f3940bd3dce4cc387ed4e8cc
cd "$task_root/source"
./tools/measure-ground-frames.sh --godot "$GODOT" --output ./ground-modes
```

The runner keeps full logs and per-frame CSV files in its scratch directory; only the compact
results, the order and the manifest are retained here.
