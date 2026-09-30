# Identical danger-prediction sampling

This experiment tests whether repeated future-contribution samples can be reused without changing
prediction answers, warnings or meter behavior. The stacked baseline includes the separate event
shape classification cache. Native CPU results establish nothing about phone/browser performance,
GPU completion, display presentation or perceived smoothness.

## Reuse boundary and input/write audit

Each source retains one future integral and its effective inputs by value. A matching request
reuses only the twenty future samples. Reach/phase guards, the current contribution, sensitivity,
and netting against the player's decay/shared total run on every request. No query cadence,
horizon, sampling step, population, lethal query, existing caret cache or halo selection changes.
Equivalent inputs can match across adjacent frames; a frame or source clock is not the key.

| Quantity | Inputs and writes | Reuse proof |
| --- | --- | --- |
| Sample positions | Query position, source global position, player velocity, effective source velocity; player physics, event movement/chases, crowd movement/recycling/separation, parent transforms and external writes can change them | All four vectors are copied into the key, never inferred from age or frame |
| Event sample rate | `_caret_intensity_over_horizon()` reads age, pulse, intensity/ramp, noticed/lunged/chatting state, baby awake state, silencing and definition data | The live effective intensity is recomputed before comparison; its exact result is keyed |
| Event field | Definition intensity, inner/outer radius, falloff power, core intensity/radius; shape kind, spine half-length and rectangle half-extents; effective body axis from look/orientation | Values are copied, so replacing or mutating a definition/shape cannot hide behind object identity; shape radius affects the live reach guard, not sampled field distance |
| Event lifecycle | Finish/leave/retire, barrier outranking, waiting, telegraph, parked state; manager streaming and retirement, source updates, silence calls | Finish/leave/outranking are checked first; velocity/intensity helpers read the remaining phases live; removal frees the source-local cache and a new instance starts empty |
| Flocks | Each bird's offset, heading and speed; flock updates and direct mutations | Flocks always sample; no bird geometry cache is introduced |
| Crowd field | Kind and the five jolt fields, modified by process decay, bump, horn and collision startles | All values are copied; current contribution is still queried every time |
| Crowd course | Heading/turn tangent, speed, yielding, turn hold, door hold and pockets; agent updates and external traffic/door state | `velocity()` is read afresh; its effective vector is the same input used by all samples, which do not mutate simulation state |
| Player net | Sensitivity, decay and total projected gross, including halo's gross pass followed by shared-total publication | Sensitivity is applied after the integral; current contribution subtraction and net arithmetic stay live, with their original operation order |
| Horizon/kernel tuning | Horizon, quarter-second step, falloff/eccentricity constants and crowd radii/intensities | These are immutable constants, not runtime cache inputs |

The public gross callers are the halo's all-source pass and each source's `expected_impact_at()`;
the latter is called by its existing caret calculation. Redraw checks and retained drawing ask
that caret. Warning/strike/badge consumers continue using their own unchanged present/lethal
queries. Event-manager physics writes position/awake/outranking, then source processing can move
and change phase; halo processing supplies the player's current kinematics and sums gross before
publishing the total. Crowd physics can move or startle bodies independently of their process
clocks. The key comparison is therefore local to each query rather than tied to those callbacks.

Existing plain event-contribution and caret caches retain their semantics. Reusing future samples
does not skip an ordinary contribution query or change which state those caches observe. Event
future samples carry overrides and never populate the plain contribution cache. Crowd contribution
queries have no cache. Sampling has no simulation/RNG side effects.

Implementation choices open to overturn: cache one integral per source across any number of
identical-input requests; keep a small `Array` of scalar/vector values rather than setters on all
mutators; bypass flocks; cache neither cheap early-zero returns nor net/lethal/caret results. Key
construction and comparison costs are included in the controlled after measurement.

## Baseline demand

`demand.json` records one accepted rendered baseline audit: seed 4242/day 1, arterial spawn,
held north, five seconds warmup and six active seconds. All original samples still execute;
instrumentation counts exact repeated integral inputs and never supplies an answer. Its timings
are deliberately excluded from performance claims. Active/visible populations, motion, draw and
physics checks and instrumented source hashes are retained.

| Source | Gross requests | Eligible sample loops | Identical previous integral | Same-frame subset |
| --- | ---: | ---: | ---: | ---: |
| Events | 54,849 | 18,172 | 12,199 | 9,086 |
| Crowd | 141,933 | 59,642 | 11,114 | 9,327 |

Across 530 frames the route travels 551.997 px north, with 200 walkers, 34 cars and median
52 events; visible medians are 18 walkers, 7 cars and 4 events. The repeated-input fractions are
67.13% of eligible event loops and 18.63% of crowd loops. Each loop contains twenty samples.
These are actual baseline repetitions, not profiler call counts assumed to have equal inputs.

To reproduce the demand audit, start from a clone with this PR fetched and export `GODOT` as the
installed executable. All generated artifacts go to a new scratch directory:

```sh
runner_root=$(git rev-parse --show-toplevel)
scratch_output=$(mktemp -d)
git fetch origin refs/pull/439/head
git worktree add --detach "$scratch_output/baseline" 7c1fbbd97729aec58cd4b5a6efaa8e329f4abcd6
python3 "$runner_root/tests/probes/m159_prediction_audit.py" "$scratch_output/baseline"
(cd "$scratch_output/baseline" && ./tools/check.sh)
ENTITY_PROFILE_OUTPUT="$scratch_output/demand" \
ENTITY_PROFILE_RENDERED=1 ENTITY_PROFILE_DISABLED=1 \
"$GODOT" --headless --path "$scratch_output/baseline" \
  --script tests/probes/entity_frame_profile.gd
python3 "$runner_root/tests/probes/entity_frame_profile_analyze.py" "$scratch_output/demand" \
  --profiler-disabled --output "$scratch_output/demand-summary.json"
python3 "$runner_root/tests/probes/m159_prediction_audit.py" "$scratch_output/baseline" \
  --summarize "$scratch_output/demand" --output "$scratch_output/demand-compact.json"
```

The instrumented scene JSON's `prediction_audit` maps process frame IDs to the four named counts.
Sum only IDs in scene rows with elapsed microseconds in `[5000000, 11000000)`. Do not time this
instrumented checkout against the production implementation. Restore its three instrumented files
or use a separate pristine baseline for timing.

## Controlled native comparison

`measure-native.py` requires byte-identical collectors/analyzer and passing import/boot in both
checkouts. It runs three profiled pairs and three profiler-disabled pairs, serially. Pair order
is before/after, after/before, before/after in each mode. Both revisions contain classification
caching; only the prediction implementation differs. Full output belongs in a new scratch folder:

```sh
runner_root=$(git rev-parse --show-toplevel)
scratch_root=$(mktemp -d)
git fetch origin refs/pull/439/head
git worktree add --detach "$scratch_root/before" dea05ce0bcceecd34f8213e9b25b49d8a48e8b31
git worktree add --detach "$scratch_root/after" e7306d1d3d79cf743f3a967bd4b37e3e55a70d3c
python3 "$runner_root/docs/evidence/m159-danger-prediction-reuse-2026-09-29/measure-native.py" \
  --baseline "$scratch_root/before" --after "$scratch_root/after" \
  --output "$scratch_root/comparison"
python3 "$runner_root/docs/evidence/m159-danger-prediction-reuse-2026-09-29/summarize-native.py" \
  "$scratch_root/comparison"
```

The runner resolves Godot from `--godot`, then `GODOT`, then `godot` on PATH, then an executable
macOS application default. The same resolved binary runs import/boot and capture. Checkout paths
are resolved before launching tools, so relative paths work too.

The runner records exact revisions, collector hashes, commands and actual run order, and stops at
the first rejected capture. Native main-loop wall time and observer callback intervals are separate
metrics. Function profiling perturbs the workload, so profiled savings are not unprofiled savings.
The compact comparison retains every trial's acceptance, population, distributions and relevant
function work; full streams and expanded reports stay outside Git.

## Native results

All twelve trials pass, without retries. `provenance.json` identifies the measured baseline
`dea05ce0bcceecd34f8213e9b25b49d8a48e8b31` and implementation
`e7306d1d3d79cf743f3a967bd4b37e3e55a70d3c`, and the byte-identical collector/analyzer hashes.
The lower revision's review corrections affect tooling, docs and comments only. The final source
diff after measurement only renames the new event local `landed` to `future_integral`, removing
its shadowed-method warning without changing operations, branches or the cache key.

The machine is an Apple M2 on macOS, Godot 4.7.2 stable, Compatibility renderer, 1280×720,
30 Hz physics, vsync disabled and a 120 FPS cap. The collector enables the frame trace and
readout, disables graph/telemetry/save/focus pause, and does not use invincibility. Each run
retains the same five-second warmup and six-second active window described above. Acceptance
requires the complete running/unpaused window, held north and at least 450 px net travel,
moving cars, drawing on at least 95% of frames, no runtime debugger errors, and complete,
uncapped profiler coverage with physics alignment when profiling is enabled.

Every run has 200 walkers, 34 cars, median 52 events and visible medians 18/7/4. Retained paths
cover 548.930–552.690 px, and every retained process frame advances the draw counter. All
profiled windows have complete coverage and matching physics counts. Compiler warnings are
175 before and 176 in the measured after revision; comparison of warning payloads attributes
the extra warning to the renamed event local. Runtime debugger errors are zero. Observer
cost p99 is 0.093–0.100 ms. `comparison.json` preserves each run's complete compact distributions
and acceptance data; every retained field is checked against its original analyzer report.

Each timing cell below is **median / p95 / p99 / max**, in milliseconds. Pair 2 launches after
first; pairs 1 and 3 launch before first. These are separate launches, not pooled frames.

| Metric | Pair | Before | After |
| --- | ---: | --- | --- |
| Profiled main-loop wall | 1 | 11.429 / 13.224 / 14.280 / 16.801 | 10.208 / 13.132 / 14.159 / 14.736 |
| Profiled main-loop wall | 2 | 11.488 / 15.479 / 17.022 / 17.982 | 11.164 / 15.284 / 16.838 / 17.667 |
| Profiled main-loop wall | 3 | 11.654 / 15.639 / 16.863 / 17.567 | 9.917 / 14.508 / 15.394 / 16.759 |
| Profiler-disabled callback interval | 1 | 10.505 / 13.797 / 14.606 / 15.632 | 8.939 / 12.844 / 14.541 / 15.429 |
| Profiler-disabled callback interval | 2 | 10.473 / 14.051 / 14.939 / 15.999 | 8.941 / 13.958 / 14.942 / 15.376 |
| Profiler-disabled callback interval | 3 | 10.299 / 14.049 / 14.794 / 15.700 | 9.063 / 13.260 / 15.029 / 44.239 |

Profiled main-loop medians decrease 2.82–14.90%; disabled callback medians decrease
12.00–14.91%. Disabled p99 is slightly worse in pairs 2 and 3, and after pair 3 has a 44.239 ms
maximum. This establishes a repeatable median reduction on this native route, not a uniform
tail reduction. The compact data does not attribute that isolated maximum to a particular
subsystem or outside interruption. No trial is removed to improve the result.

Gross requests stay at median 104 event and 268 crowd calls per process frame on both sides.
The baseline audit establishes actual equivalent-input demand independently of this profiler.
Measured real contribution work falls as follows (mean calls per process frame):

| Pair | Event contribution before → after | Crowd contribution before → after | After event / crowd sample loops |
| --- | ---: | ---: | ---: |
| 1 | 789.241 → 324.884 | 2634.444 → 2234.986 | 11.102 / 90.679 |
| 2 | 789.091 → 328.634 | 2634.675 → 2227.875 | 11.249 / 90.140 |
| 3 | 788.539 → 326.203 | 2682.691 → 2243.671 | 11.148 / 91.018 |

Event gross mean inclusive time falls from 1.588–1.602 to 0.760–0.773 ms/frame; crowd gross
falls from 1.349–1.382 to 1.204–1.211 ms/frame. Those inclusive times already include key
gathering/comparison and remaining samples; nested function times must not be added together.
The new helper is absent before, so helper counts alone cannot measure baseline cache hits.

Profiler-enabled callback medians are 11.428–11.936 ms before and 10.725–11.198 ms after,
versus disabled ranges of 10.299–10.505 and 8.939–9.063 ms. Profiling measurably perturbs the
workload, and launch variation prevents treating these differences as an exact overhead
correction. Native main-loop wall and observer callback interval remain distinct measurements.
No phone, browser, GPU/presentation or perceived-smoothness claim follows from this experiment.

## Behavioral verification

`tests/fixtures/prediction_reference.gd` independently preserves the pre-reuse gross calculation.
`tests/test_prediction_reuse.gd` compares float bytes against it across the catalogue, default
queries, movement and same-frame writes, shape/definition mutations, pulse/phase changes, silence,
outranking, retirement and flock changes. Instrumented subclasses count actual sample-loop calls
to show equivalent queries skip work and changed trajectories recompute. Sensitivity, decay and
shared-total changes keep affecting the result immediately while reusing only the integral.
Reference subclasses drive net/caret/redraw/lethal consumers in source/halo/draw order. Existing
danger, halo, manager, crowd, contribution and redraw suites cover their wider gameplay contracts.

`./tools/check.sh` passes on both measured revisions. `./tools/test.sh prediction_reuse` passes
6,683 checks. `./tools/test.sh danger halo event_redraw event_manager crowd contribution` passes
2,847 checks. These are focused partial runs; the full suite belongs to CI. Documentation lint
and diff checks pass. The final identifier cleanup repeats boot and prediction parity checks.
