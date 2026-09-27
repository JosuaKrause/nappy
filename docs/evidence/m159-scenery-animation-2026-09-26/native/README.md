# Native scenery comparison · 2026-09-26

The repeatable result is removal of the synchronized full-building redraw: 180 calls per
six-second baseline window become zero in all three after windows. Peak atlas-region calls
drop from over 5,300 to under 190. Overall median frame time is mixed, so these runs do not
establish a general FPS improvement.

## Revisions and protocol

Before is `24e6c6cd8db03a1070fe25c6807da45a5e67a980`, the clean automatic merge of
`79a323b5` and main `3d3f2c96`; runtime `src`, `art`, `assets` and `export_presets.cfg`
match that main exactly. After is `0fed117cb0b30f1fcd554c7b7256a9a510c14922`.
The baseline's own import/boot completes before measurement. Its initial fresh-cache atlas
bake prints the wrapper's documented missing-class messages; the subsequent import and boot
resolve them. No measurement contains a debugger error.

The collector, scene and observer are byte-identical across both checkouts. `provenance.json`
records their SHA-256 hashes and the one analyzer hash used for both sides. The analyzer adds
p99 output without changing collection or acceptance criteria. `measure-native.py` runs
before/after three times, then one before/after pair with the function profiler disabled.
Each receiver has a 45-second internal deadline and a 60-second external deadline; only one
measured game runs at once. The compressed scene/profiler records, launch logs and individual
summaries retain all eight accepted runs. There are no rejected timing runs.

Godot 4.7.2, native macOS, Apple M2, GL compatibility renderer, 1280×720, 30 Hz physics,
120 FPS cap and disabled vsync. The scene uses seed 4242/day 1, arterial spawn and continuous
north input, five seconds of warmup and six active seconds. Save and telemetry are disabled;
the ordinary debug readout and frame tracing remain enabled on both sides. Measurement runs
do not use invincibility. The population includes 200 walkers and 34 cars throughout, while
event visibility and live counts vary naturally as the rig moves. The retained observer records
population, movement, input, pause/day state and drawn-frame counters on each process frame.

All eight runs pass the shared acceptance rules: full active window, running and unpaused day,
northward displacement, held north input, moving cars, rendered-frame advancement, no debugger
errors and (when enabled) complete uncapped profiler frames with matching physics callback counts.

## Frame distributions

Milliseconds; rows remain separate rather than pooling different runs. Profiled rows use the
engine's main-loop wall duration, which includes CPU process/render submission and waiting, not
GPU execution time.

| Pair | Side | Median | p95 | p99 | Max |
| --- | --- | ---: | ---: | ---: | ---: |
| 1 | Before | 12.260 | 15.970 | 17.882 | 21.228 |
| 1 | After | 13.294 | 16.959 | 17.779 | 22.903 |
| 2 | Before | 12.901 | 16.874 | 20.520 | 23.815 |
| 2 | After | 11.914 | 14.993 | 16.033 | 16.731 |
| 3 | Before | 14.789 | 18.104 | 22.190 | 31.779 |
| 3 | After | 12.964 | 16.818 | 17.087 | 17.506 |

The disabled-profiler companion has no native function durations. Its observer-to-observer
callback interval is a distinct measure, retained separately:

| Side | Median | p95 | p99 | Max |
| --- | ---: | ---: | ---: | ---: |
| Before | 10.963 | 12.620 | 15.177 | 20.911 |
| After | 10.999 | 12.828 | 14.736 | 15.639 |

The disabled median is effectively unchanged; its p95 is slightly higher and p99/max lower.
One companion pair cannot establish a stable tail percentage. Profiled medians are slower in
pair 1 and faster in pairs 2–3. The profiler itself changes callback costs; the observer costs
about 0.075–0.084 ms at the median in profiled runs. These native desktop observations establish
neither phone/browser behavior nor a GPU improvement.

## Work distributions

| Pair | Side | Full-building draws/window | Peak full-building draws/frame | Atlas lookups/window | Peak atlas lookups/frame |
| --- | --- | ---: | ---: | ---: | ---: |
| 1 | Before | 180 | 45 | 64,039 | 5,357 |
| 1 | After | 0 | 0 | 41,327 | 187 |
| 2 | Before | 180 | 45 | 62,779 | 5,362 |
| 2 | After | 0 | 0 | 43,112 | 171 |
| 3 | Before | 180 | 45 | 60,868 | 5,388 |
| 3 | After | 0 | 0 | 40,766 | 177 |

Baseline building drawing peaks at 8.809/9.421/10.066 ms inclusive per frame under the native
profiler. These are rare spikes: even p99 is zero for that callback. After windows contain
470 small-part draw callbacks each, at 0.040/0.026/0.030 ms peak inclusive per frame, with cached
textures. `comparison.json` retains median/p95/p99/max/mean for the work metrics and their costs.

Whole-event draw counts are 2,110/2,064/2,052 before and 1,991/2,019/2,004 after. These include all
event kinds, moving bodies and changing cues; the arterial scene alone cannot attribute their
difference to pipes or smoke. The focused real-runtime fixture supplements it: both event axes
animate with zero static-body/owner redraws, while 72 pipe-part and ten smoke-part draws occur
over its retained burst. Roof static draws and water draw callbacks also stay zero. The water
shader's uniform clock advances without rebuilding its commands. That fixture establishes
separation and pause/resume, not a controlled per-event CPU or GPU speedup.

## Reproduce

Import/boot both checkouts first. From the after checkout, run:

```sh
python3 docs/evidence/m159-scenery-animation-2026-09-26/measure-native.py \
  --baseline /absolute/baseline --after /absolute/after --output /absolute/new-output
python3 docs/evidence/m159-scenery-animation-2026-09-26/summarize-native.py /absolute/new-output
```

The output directory must be new, so existing evidence cannot be overwritten. The runner stops
after any rejected capture and retains its reason instead of continuing a blind launch loop.
