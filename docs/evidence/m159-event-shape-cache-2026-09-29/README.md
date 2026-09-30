# Event-shape classification cache measurement

This record measures the event-shape classification cache for M159, a slow frame names the frame
that was slow. The change preserves classification answers and stores the answer when an
`EventDef.look` value is assigned, instead of matching that look every time collision, placement
or drawing asks the question.

The retained active-play comparisons report complete-frame timing and profiler attribution. The
separate probe isolates repeated classification work. Neither measurement is phone timing, a GPU
comparison or evidence about perceived smoothness.

## Production change and correctness

`EventDef.look` has an exported-property setter that derives the plain `has_a_spread` field. The
true set remains roadworks, burnt shell, stall, roadblock, barricade, cafe, fallen tree, car
accident, burst main, scaffolding and collapsed frontage. Protest and firefight remain excluded;
their body-axis branches continue to handle them separately. The public
`EventInstance.has_a_spread()` entry point remains and returns the cached answer.

The four production hot paths read the field directly: instance body-axis selection, manager
body-axis selection, the scheduler's ground-cache key, and its corner filter. The corner filter
therefore keeps spread-drawn events off corners. A getter was not used because it would retain a
GDScript call at each hot read. The derived field is publicly writable as a consequence; the
exported `look` setter is its only production writer, and regression tests protect the invariant.

The input/write audit found that the classification depends only on `look`. All production and
test look assignments construct or deliberately mutate catalogue rows; no phase transition or
runtime event substitution changes a live definition's look. Definitions are copied in catalogue,
scheduler, warning, manager, resistance, finale, heat and probe/test paths, so immutability was not
assumed. Tests cover every enum value and catalogue definition, the default, mutable transitions
in both directions, shallow and deep `Resource.duplicate()` behavior, independent copy mutation,
body and field geometry, spread/corner placement, and event phases. Existing event, redraw,
manager, halo, warning, selection and contribution suites exercise representative consumers.

The danger test fixture now gives its `Camera2D` the physics-process callback used by the real
scene. That fixture-only correction removes the engine interpolation warning; production camera
and interpolation behavior are unchanged.

## Controlled active-play comparison

The runner first requires `./tools/check.sh` to pass in both checkouts, then asserts byte-identical
collector scene, collector scripts and analyzer. It launches one measured process at a time in
three alternating before/after profiled pairs followed by three alternating profiler-disabled
pairs. A second series reverses the order for three more profiler-disabled pairs, running the
cached revision before the baseline each time. Every launch uses seed 4242, day 1, the arterial
spawn, a held northward route, a five-second warmup and a six-second active window. A 60-second
external deadline applies to each launch, and the runner stops at the first rejected capture.

```sh
scratch_output=$(mktemp -d /private/tmp/m159-event-shape-rerun.XXXXXX)

python3 docs/evidence/m159-event-shape-cache-2026-09-29/measure-native.py \
  --baseline /private/tmp/nappy-event-shape-before-41fd54a1 \
  --after /Users/krause/workspace/nappy-codex/.claude/worktrees/event-shape-cache \
  --output "$scratch_output/native"

python3 docs/evidence/m159-event-shape-cache-2026-09-29/summarize-native.py \
  "$scratch_output/native"

python3 docs/evidence/m159-event-shape-cache-2026-09-29/measure-native.py \
  --baseline /private/tmp/nappy-event-shape-before-41fd54a1 \
  --after /Users/krause/workspace/nappy-codex/.claude/worktrees/event-shape-cache \
  --output "$scratch_output/native-reversed" \
  --mode disabled --order after-before

python3 docs/evidence/m159-event-shape-cache-2026-09-29/summarize-native.py \
  "$scratch_output/native-reversed"
```

Before is `41fd54a1cf5fee1a722dc7fcfb4cb30e95610b1e`. The original series' after revision is
`ea7147fff56eae004bcbe751130e1c35082d3c3b`; the reversed series' after revision is
`7e3b019e229de7c77c1fd2bc1cb000f43ffd9ba5`, which adds only the original series' evidence and
runner options. Production source and the collector/analyzer are byte-identical across those two
after revisions. Each directory's `provenance.json` retains exact commands, collector/analyzer
SHA-256 values, run order and source identities. Each `comparison.json` retains the environment,
acceptance checks, warning/error counts, movement, population, timing and target-function results
projected from the original complete analyzer summaries.

All eighteen captures are accepted with no rejection flags, and the profiled captures have no
missing profiler frames. Each retains 200 walkers, 34 cars, a median 51–52 live events and four
visible events. The route travels
548.930–551.997 px north, a range of one 30 Hz walking step. The environment is Apple M2, macOS,
Godot 4.7.2 stable official `ed1daf0bf`, OpenGL compatibility on Metal, 1280×720, main-thread
rendering, 30 Hz physics, telemetry off, graph off and readout on.

Each raw remote-debug stream also contains 175 script-reload compiler-warning messages on both
revisions, in existing warning categories; there are no runtime debugger errors. Capture
acceptance rejects runtime errors but does not reject compiler-warning messages, so acceptance is
not a claim that these profiler streams are warning-free. This is separate from the focused danger
fixture's engine interpolation warning, which the fixture correction removes.

Complete-frame native main-loop wall time with profiling enabled:

| Pair | Version | Frames | Median ms | p95 ms | p99 ms | Maximum ms |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | Before | 413 | 15.071 | 17.644 | 17.924 | 19.265 |
| 1 | After | 487 | 11.609 | 16.066 | 17.107 | 18.172 |
| 2 | Before | 445 | 12.844 | 16.414 | 17.113 | 17.721 |
| 2 | After | 473 | 11.657 | 17.007 | 18.059 | 23.264 |
| 3 | Before | 435 | 13.029 | 17.200 | 18.751 | 25.063 |
| 3 | After | 506 | 11.483 | 14.528 | 16.219 | 18.346 |

The after median is lower by 1.187–3.462 ms in every profiled pair. The tails are variable: pair 2
has worse after p95, p99 and maximum values, while pairs 1 and 3 improve. Profiling amplifies this
change because it observes every GDScript callback, so these values do not estimate unprofiled
frame savings.

Profiler attribution shows where that amplification occurs:

| Pair | Version | `has_a_spread` median self ms / calls | `_solid_axis` median self ms | `_solid_axis` median inclusive ms |
| ---: | --- | ---: | ---: | ---: |
| 1 | Before | 0.607 / 747 | 0.089 | 0.793 |
| 1 | After | absent | 0.108 | 0.140 |
| 2 | Before | 0.614 / 776 | 0.089 | 0.801 |
| 2 | After | absent | 0.106 | 0.139 |
| 3 | Before | 0.607 / 773 | 0.088 | 0.798 |
| 3 | After | absent | 0.109 | 0.141 |

The `has_a_spread` row disappears because active-play hot paths no longer call the wrapper. Its old
self time includes per-call profiling overhead and is not a literal CPU-saving estimate. The
roughly 0.017–0.021 ms increase in `_solid_axis` self time shows the direct field read moving into
the caller, while its inclusive time no longer includes the classified callback. `_body_axis` is
also attributed to its caller, but it has a median zero calls in the active window; scheduler
placement runs before this profiled window. The isolated probe below measures the classification
operations without function profiling.

With the function profiler disabled, only the observer callback interval is available. The first
three pairs run baseline before cached:

| Pair | Version | Frames | Median ms | p95 ms | p99 ms | Maximum ms |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | Before | 537 | 10.989 | 13.236 | 14.860 | 16.382 |
| 1 | After | 563 | 10.451 | 13.092 | 14.847 | 16.847 |
| 2 | Before | 540 | 10.994 | 12.861 | 14.628 | 17.204 |
| 2 | After | 550 | 10.422 | 14.388 | 16.153 | 29.730 |
| 3 | Before | 533 | 11.017 | 13.513 | 15.769 | 17.430 |
| 3 | After | 567 | 10.209 | 13.350 | 14.306 | 15.668 |

The second three pairs reverse that order and run cached before baseline:

| Pair | Version | Frames | Median ms | p95 ms | p99 ms | Maximum ms |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 4 | After | 561 | 10.436 | 13.289 | 14.499 | 16.619 |
| 4 | Before | 529 | 11.109 | 13.563 | 15.954 | 16.446 |
| 5 | After | 562 | 10.457 | 13.184 | 14.295 | 15.116 |
| 5 | Before | 526 | 11.148 | 14.422 | 15.948 | 16.947 |
| 6 | After | 559 | 10.282 | 13.921 | 14.995 | 17.367 |
| 6 | Before | 531 | 11.044 | 13.936 | 16.087 | 17.854 |

The after median is lower in all six disabled pairs: by 0.538, 0.572 and 0.808 ms when baseline
runs first, then by 0.673, 0.691 and 0.762 ms when cached runs first. Reversing order therefore
does not reverse the median result in this batch. Tail behavior remains variable, especially the
original pair 2's after maximum. These intervals include the observer callback and scheduling
noise; they are a distinct metric from native main-loop markers.

## Isolated unprofiled classification comparison

```sh
./tools/test.sh probes/m159_event_shape_cache.gd
```

Each pair alternates 1,060,000 legacy look matches with 1,060,000 cached field reads over the same
53-definition set. Construction, expected-answer calculation and assertions sit outside the
timer. Exact hit-count parity is checked after every timed pair.

| Pair | Legacy match µs | Cached field µs | Reduction |
| ---: | ---: | ---: | ---: |
| 1 | 1,060,868 | 47,216 | 95.55% |
| 2 | 1,063,927 | 47,755 | 95.51% |
| 3 | 1,061,621 | 47,782 | 95.50% |
| 4 | 1,061,395 | 47,409 | 95.53% |
| 5 | 1,063,207 | 47,373 | 95.54% |

`isolated-probe.log` retains the successful six-check run. An earlier sandboxed invocation is
excluded: both log-file creation and the macOS certificate call failed, so the command returned
nonzero despite passing its assertions. No active-play capture was rejected, and no blind retry
occurred in that controlled series.

This probe deliberately repeats one operation far more densely than an ordinary frame. It
establishes that cached reads reduce isolated classification CPU work; it does not predict a phone
frame or add linearly to the active-play difference.

## Retention and reproduction limits

The committed evidence is the compact measurement record: this README, both rerun scripts, the
successful isolated-probe log, and each series' provenance and comparison JSON. Full compressed
profiler/scene captures, launch/check logs, expanded per-run summaries and the rejected sandbox log
are not retained. The compact rows preserve every reported numeric result and the analyzer fields
needed to check capture acceptance, but exact raw reanalysis of these historical captures is no
longer available.

The collection runner still writes complete compressed captures, launch/check logs and expanded
summaries for a repeat experiment. Use a new scratch output directory as in the commands above;
do not replace the committed comparison directories. Fresh results can vary with the host and run,
even when the source identities, route and windows match.

## Verification and limits

`./tools/check.sh` passes in both checkouts before each measured series. Focused `events`, `event_redraw`,
`event_manager`, `halo` and `danger` suites pass with 72,739 checks and zero failures; the narrowed
`events_catalogue`, danger and probe run passes with 1,292 checks and zero failures.
The successful isolated probe passes six checks with no engine errors. All are expected partial
runs; the unfiltered suite remains for CI. `./tools/lint.sh` and `git diff --check` are the final
documentation/diff gates.

The controlled runs show a repeatable median reduction on this host and workload, with noisy
tails. They do not establish phone performance, GPU behavior, memory/residency impact, or the
absence of perceived stutter. No gameplay, artwork, tuning, query cadence or threat prediction is
changed.
