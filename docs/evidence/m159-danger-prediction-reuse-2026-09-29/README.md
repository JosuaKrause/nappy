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

To reproduce the demand audit, create a disposable checkout at
`7c1fbbd97729aec58cd4b5a6efaa8e329f4abcd6`, then run from this PR checkout:

```sh
python3 tests/probes/m159_prediction_audit.py /path/to/disposable-baseline
cd /path/to/disposable-baseline
./tools/check.sh
ENTITY_PROFILE_OUTPUT=/private/tmp/new-prediction-demand \
ENTITY_PROFILE_RENDERED=1 ENTITY_PROFILE_DISABLED=1 \
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tests/probes/entity_frame_profile.gd
python3 tests/probes/entity_frame_profile_analyze.py /private/tmp/new-prediction-demand \
  --profiler-disabled --output /private/tmp/new-prediction-demand-summary.json
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
python3 docs/evidence/m159-danger-prediction-reuse-2026-09-29/measure-native.py \
  --baseline /path/to/pristine-stacked-baseline --after /path/to/this-checkout \
  --output /private/tmp/new-prediction-comparison
python3 docs/evidence/m159-danger-prediction-reuse-2026-09-29/summarize-native.py \
  /private/tmp/new-prediction-comparison
```

The runner records exact revisions, collector hashes, commands and actual run order, and stops at
the first rejected capture. Native main-loop wall time and observer callback intervals are separate
metrics. Function profiling perturbs the workload, so profiled savings are not unprofiled savings.
The compact comparison retains every trial's acceptance, population, distributions and relevant
function work; full streams and expanded reports stay outside Git.

## Behavioral verification

`tests/fixtures/prediction_reference.gd` independently preserves the pre-reuse gross calculation.
`tests/test_prediction_reuse.gd` compares float bytes against it across the catalogue, default
queries, movement and same-frame writes, shape/definition mutations, pulse/phase changes, silence,
outranking, retirement and flock changes. Instrumented subclasses count actual sample-loop calls
to show equivalent queries skip work and changed trajectories recompute. Sensitivity, decay and
shared-total changes keep affecting the result immediately while reusing only the integral.
Reference subclasses drive net/caret/redraw/lethal consumers in source/halo/draw order. Existing
danger, halo, manager, crowd, contribution and redraw suites cover their wider gameplay contracts.
