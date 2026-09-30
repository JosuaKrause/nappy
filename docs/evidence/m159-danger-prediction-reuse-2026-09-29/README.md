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
| Event field | Definition intensity, inner/outer radius, falloff power, core intensity/radius; shape kind, spine half-length and rectangle half-extents; effective body axis from look/orientation | Values are copied, so replacing or mutating a definition/shape cannot hide behind object identity; shape radius is read by neither the reach guard (`EventDef.field_reach()`) nor sampled field distance, which measures from the spine |
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

To reproduce the demand audit, create a runner checkout at this PR's current head and a separate
disposable baseline checkout. Fetching the ref alone does not install the current probe in the
caller's checkout. `GODOT` names the installed executable; all artifacts stay in fresh scratch:

```sh
source_root=$(git rev-parse --show-toplevel)
scratch_root=$(mktemp -d)
git -C "$source_root" fetch origin refs/pull/439/head
git -C "$source_root" worktree add --detach "$scratch_root/runner" FETCH_HEAD
git -C "$source_root" worktree add --detach "$scratch_root/audit-baseline" \
  7c1fbbd97729aec58cd4b5a6efaa8e329f4abcd6
python3 "$scratch_root/runner/tests/probes/m159_prediction_audit.py" \
  "$scratch_root/audit-baseline"
(cd "$scratch_root/audit-baseline" && GODOT="$GODOT" ./tools/check.sh)
ENTITY_PROFILE_OUTPUT="$scratch_root/demand" \
ENTITY_PROFILE_RENDERED=1 ENTITY_PROFILE_DISABLED=1 \
"$GODOT" --headless --path "$scratch_root/audit-baseline" \
  --script tests/probes/entity_frame_profile.gd
python3 "$scratch_root/runner/tests/probes/entity_frame_profile_analyze.py" \
  "$scratch_root/demand" --profiler-disabled --output "$scratch_root/demand-summary.json"
python3 "$scratch_root/runner/tests/probes/m159_prediction_audit.py" \
  "$scratch_root/audit-baseline" --summarize "$scratch_root/demand" \
  --output "$scratch_root/demand-compact.json"
```

The instrumented scene JSON's `prediction_audit` maps process frame IDs to the four named counts.
Sum only IDs in scene rows with elapsed microseconds in `[5000000, 11000000)`. Instrument mode
refuses a dirty checkout and the repository containing the script, then deliberately dirties the
disposable audit baseline. Summarize mode accepts that instrumented tree. Never use it for timing.

## Controlled native comparison

`measure-native.py` rejects invalid or dirty tracked checkouts, an existing or invalid output path,
and mismatched collectors/analyzer before creating output or launching a check. It hashes both
production sources, then revalidates the clean revisions and every hash after boot and before each
capture. It runs three profiled pairs and three profiler-disabled pairs serially, in before/after,
after/before, before/after order. Full output belongs in a new scratch folder:

```sh
source_root=$(git rev-parse --show-toplevel)
scratch_root=$(mktemp -d)
git -C "$source_root" fetch origin refs/pull/439/head
git -C "$source_root" worktree add --detach "$scratch_root/runner" FETCH_HEAD
git -C "$source_root" worktree add --detach "$scratch_root/before" \
  a53032535c89ef7b583b231454804b23c0241451
git -C "$source_root" worktree add --detach "$scratch_root/after" \
  4e6488e0c60ec342c8ade85b90464d5c6ef1913b
python3 "$scratch_root/runner/docs/evidence/m159-danger-prediction-reuse-2026-09-29/measure-native.py" \
  --baseline "$scratch_root/before" --after "$scratch_root/after" \
  --output "$scratch_root/comparison" --godot "$GODOT"
python3 "$scratch_root/runner/docs/evidence/m159-danger-prediction-reuse-2026-09-29/summarize-native.py" \
  "$scratch_root/comparison"
```

The runner resolves Godot from `--godot`, then `GODOT`, then `godot` on PATH, then an executable
macOS application default. The same resolved binary runs import/boot and capture. Checkout paths
are resolved before launching tools, so relative paths work too.

The runner records exact revisions, source/collector hashes, commands and actual run order, and
stops at the first rejected capture. Native main-loop wall time and observer callback intervals are
separate metrics. Function profiling perturbs the workload, so profiled savings are not unprofiled
savings. The compact comparison retains every trial's acceptance, population, distributions and
relevant function work; full streams and expanded reports stay outside Git.

## Native results

All twelve fresh trials pass on their first launch, with no rejection flags. The committed runner
enforces clean tracked checkouts before and after boot and before every capture; clean status is not
stored as a separate provenance field. `provenance.json` identifies the measured baseline
`a53032535c89ef7b583b231454804b23c0241451` and implementation
`4e6488e0c60ec342c8ade85b90464d5c6ef1913b`. Their exact production-source diff is confined to
`src/events/event_instance.gd` and `src/crowd/crowd_agent.gd`: 52 insertions and 8 deletions add the
two value-keyed caches, extract their sampling helpers and use the warning-free `integral` local.
No other production source differs.

The superseded historical compact timing files remain retrievable at commit
`f0f8f9f084466f85e92b01319c07f964b846a71a`. That run recorded revision IDs but did not enforce
clean tracked sources or hash both production files, so its timing provenance cannot be proved
retroactively and its figures are not used below. The checked-in `comparison.json` and
`provenance.json` are the fresh controlled set.

| Input | Before SHA-256 | After SHA-256 |
| --- | --- | --- |
| `src/events/event_instance.gd` | `bbd30e0f17647f94cd87d30f598a4e7d30b95a01f4db9f280f948c55cb3ad7ec` | `7f62a85868c73b9c6781ec810211a73fcc58be75c0385dd643540d524488c4de` |
| `src/crowd/crowd_agent.gd` | `e7561297c6a588075ddcc88e818cdf9aa3e0df23948b3308d3faa2edc6407fbb` | `40155dd4716538ac5481945d8c3433d70ee79d15151dbf13a73038c5c47fb448` |

The byte-identical collector hashes are `7e63c40f…` for `entity_frame_profile.gd`, `4978dace…`
for its scene and `27edf350…` for its observer; the analyzer is `e58491bf…`. Full hashes remain
in `provenance.json`.

The machine is an Apple M2 on macOS, Godot 4.7.2 stable, Compatibility renderer, 1280×720,
30 Hz physics, vsync disabled and a 120 FPS cap. The collector enables the frame trace and
readout, disables graph/telemetry/save/focus pause, and does not use invincibility. Each run
retains the same five-second warmup and six-second active window described above. Acceptance
requires the complete running/unpaused window, held north and at least 450 px net travel,
moving cars, drawing on at least 95% of frames, no runtime debugger errors, and complete,
uncapped profiler coverage with physics alignment when profiling is enabled.

Every run has 200 walkers, 34 cars, median 52 events and visible medians 18/7/4. Retained paths
cover 548.930–551.997 px, and every retained process frame advances the draw counter. All profiled
windows have complete coverage and matching physics counts. Compiler warnings are 175 before and
173 after; the two removed warnings are the helper locals renamed away from the existing
`landed()` method. Runtime debugger errors are zero. Observer cost p99 is 0.090–0.101 ms.
`comparison.json` preserves each run's complete compact distributions and acceptance data; every
retained field is generated from and checked against its scratch analyzer report.
The retained evidence is six files totaling 106,559 bytes; complete captures, check logs and
expanded analyzer reports remain in the scratch directory named below.

Each timing cell below is **median / p95 / p99 / max**, in milliseconds. Pair 2 launches after
first; pairs 1 and 3 launch before first. These are separate launches, not pooled frames.

| Metric | Pair | Before | After |
| --- | ---: | --- | --- |
| Profiled main-loop wall | 1 | 11.440 / 16.195 / 16.848 / 33.239 | 10.794 / 12.362 / 12.744 / 13.554 |
| Profiled main-loop wall | 2 | 11.489 / 15.954 / 16.507 / 42.882 | 10.868 / 12.527 / 12.942 / 13.227 |
| Profiled main-loop wall | 3 | 11.309 / 15.353 / 16.279 / 16.818 | 9.770 / 14.050 / 14.792 / 15.800 |
| Profiler-disabled callback interval | 1 | 10.627 / 13.172 / 14.424 / 15.544 | 8.785 / 11.798 / 14.189 / 14.876 |
| Profiler-disabled callback interval | 2 | 10.370 / 12.844 / 13.345 / 15.218 | 8.849 / 11.628 / 13.974 / 14.790 |
| Profiler-disabled callback interval | 3 | 10.303 / 12.852 / 13.318 / 14.556 | 8.752 / 11.705 / 13.041 / 14.593 |

Profiled main-loop medians decrease 5.41–13.60%; disabled callback medians decrease
14.67–17.33%. Tails remain variable: disabled pair 2 has a worse after p99 and disabled pair 3 a
slightly worse after maximum, while the profiled after tails are lower in all three pairs. This
establishes a repeatable median reduction on this native route, not uniform tail improvement. No
trial is removed and no capture is retried to improve the result.

Gross requests stay at median 104 event and 268 crowd calls per process frame on both sides.
The baseline audit establishes actual equivalent-input demand independently of this profiler.
Measured real contribution work falls as follows (mean calls per process frame):

| Pair | Event contribution before → after | Crowd contribution before → after | After event / crowd sample loops |
| --- | ---: | ---: | ---: |
| 1 | 792.445 → 323.765 | 2694.067 → 2229.246 | 11.055 / 90.448 |
| 2 | 791.166 → 324.925 | 2663.526 → 2232.219 | 11.100 / 90.548 |
| 3 | 787.979 → 324.351 | 2651.408 → 2225.187 | 11.078 / 90.242 |

Event gross mean inclusive time falls from 1.568–1.591 to 0.743–0.751 ms/frame; crowd gross
falls from 1.329–1.371 to 1.175–1.178 ms/frame. Those inclusive times already include key
gathering/comparison and remaining samples; nested function times must not be added together.
The new helper is absent before, so helper counts alone cannot measure baseline cache hits.

Profiler-enabled callback medians are 11.391–11.568 ms before and 10.588–10.842 ms after,
versus disabled ranges of 10.303–10.627 and 8.752–8.849 ms. Profiling measurably perturbs the
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

`./tools/check.sh` passes on both measured revisions. The platform-authorized focused
`./tools/test.sh prediction_reuse danger halo event_redraw event_manager crowd contribution` run
passes 9,528 checks with zero failures. `tools/test_experiment_preflight.py` covers missing
checkouts, existing outputs, dirty tracked sources, self-instrumentation, relative paths and source
hash propagation; it passes directly and in the complete `./tools/pycheck.sh` gate. The hook suite
passes 603 checks. These game suites are a focused partial run; the full suite belongs to CI.
