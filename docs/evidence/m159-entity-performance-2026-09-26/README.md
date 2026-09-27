# Crowded-scene CPU attribution, September 26, 2026

This historical capture is stored under its M159 queue entry. Raw summary path fields retain
the capture-time `docs/evidence/entity-performance-2026-09-26/` prefix; those files now live
under `docs/evidence/m159-entity-performance-2026-09-26/`. Raw data and manifest hashes are
unchanged by the relocation. The observations below describe the measured checkpoint.

The steady script workload is dominated by crowd updates and predictive danger cues. The
largest measured frames also contain a separate spike: synchronized building redraws for vent
animation. These are native desktop measurements with diagnostic overhead, not phone results
or evidence that the mobile stutter has one established cause. No shipping source is changed.

## Scene and retained windows

Godot 4.7.2 stable official, engine hash `ed1daf0bf001b61586d9930840f2f1394092c079`, Apple M2,
macOS, OpenGL compatibility renderer, 1280×720 viewport. Gameplay source is branch base
`a3382663`. Measurements are captured while uncommitted diagnostic instrumentation evolves;
that gameplay checkpoint does not identify the probe bytes. The committed probe is the hardened
reproduction version, not the byte-identical generator of every archived stream. Each log
preserves its actual launch command and each scene file its observation columns. The accepted
headless trial uses the 13-second backup timer and a 12-column observer. The accepted rendered
profile uses the 20-second backup timer and the 12-column late-process observer; the disabled
companion adds held input and velocity columns. Final receiver metadata also explicitly records
the requested profiling mode and function cap; these are supplied to analysis from the launch
contract for earlier streams that predate those fields. Day 1, seed 4242, arterial
spawn, walking north. Physics is 30 Hz; the diagnostic frame cap is 120 FPS and VSync is disabled.
The debug readout is on, graph and telemetry are off. The raw frame trace and scene observer
are on. No invincibility, population changes or gameplay bypasses are used. Saves are disabled.

Each accepted window excludes five wall-clock seconds of warmup and keeps the following six
seconds of active play. All retained rows are running and unpaused. All three accepted windows
travel 551.997 pixels due north, matching six seconds at the game's 92 px/s walking speed.
Both rendered windows advance the drawn-frame counter exactly once per process-frame interval.
The companion also records held north input in every row. The earlier profiled observer schema
has no input column; its directed displacement, launch flags and per-frame coordinates establish
the walking route independently of crowd shove. Median moving cars per frame is 29.

| Window | Role | Frames | Physics ticks | Median visible walkers / cars / events |
| --- | --- | ---: | ---: | --- |
| `entity-rendered-3` | Native every-frame profile, continuously drawn | 454 | 181 | 18 / 7 / 4 |
| `entity-rendered-unprofiled` | Same route, function profiler disabled | 530 | 181 | 18 / 7 / 4 |
| `entity-headless-valid` | Corroborating native CPU profile, no display | 664 | 180 | 18 / 7 / 4 |

All have 200 active walkers and 34 active cars; median active events is 52, maximum 56.
Visible maxima are 25 walkers, 8 cars and 5 events. “Visible” means the entity origin lies in the
viewport and its node is visible; it is not pixel coverage or occlusion testing. Off-screen
active entities remain part of the CPU workload. Headless visibility is geometric only.

## CPU work per rendered frame

These are the native profiler's **inclusive callback times**, summed across instances of the
same callback within each frame. They include their helper calls and must not be added to the
nested breakdown below or to the engine totals. Physics callbacks use the 181 frames with
exactly one physics tick; the other 273 frames have none. No measured frame has multiple ticks.
Times are milliseconds; p95 uses the nearest-rank definition. Maxima in different rows need not
occur on the same frame. Full per-function self time, inclusive time and call distributions are
in the summary JSON, and all original frame records are retained.

| Callback work | Median | p95 | Max | Calls, median |
| --- | ---: | ---: | ---: | ---: |
| Crowd movement, steering and redraw decisions | 3.114 | 3.470 | 3.889 | 234/frame |
| Halo source selection, prediction and assignment | 2.688 | 2.968 | 3.119 | 1/frame |
| Live event behavior and redraw decisions | 1.619 | 1.830 | 1.903 | 52/frame |
| Crowd drawing | 0.455 | 0.699 | 0.831 | 15/frame |
| Screen-edge danger prediction | 0.174 | 0.194 | 0.217 | 1/frame |
| Event drawing | 0.155 | 0.278 | 0.452 | 5/frame |
| Main loop and debug readout | 0.147 | 0.194 | 0.244 | 1/frame |
| Building drawing | 0.000 | 0.000 | 9.199 | 0/frame; max 45 |
| Traffic queues, signals and player contacts | 0.749 | 0.803 | 0.856 | 1/physics tick |
| Baby meter and source queries | 0.370 | 0.428 | 0.506 | 1/physics tick |
| Event manager streaming, placement and contacts | 0.357 | 0.465 | 0.612 | 1/physics tick |

The main costs above contain substantial cue work. Crowd redraw decisions alone have a median
1.215 ms/frame inside the 3.114 ms crowd update. Event redraw decisions have a median 1.506
ms/frame inside the 1.619 ms event update. Calling the whole callback “movement” would therefore
misattribute prediction work to locomotion.

Across all callers, `CrowdAgent.expected_gross_at()` costs a median 1.349 ms inclusive over 268
calls/frame, and `EventInstance.expected_gross_at()` costs 2.269 ms over 104 calls/frame. These
project future source contributions; both halo assignment and caret decisions call them.
Crowd contributions are queried a median 2,589 times/frame. `EventInstance.has_a_spread()`, which
classifies an event's drawing/field shape with a look-enum match, has 776 calls/frame and 0.629
ms median **self** time. These nested measurements locate repeated work; they are not additional
costs to sum with the outer callbacks.

The headless corroboration ranks the same three callbacks first: crowd updates 2.891 ms,
halo 2.609 ms and live events 1.573 ms median. It is a different rendering workload and cannot
be subtracted from the rendered run to estimate rendering cost.

## Expensive frames and building animation

The most expensive measured main-loop wall interval is frame 778 at 23.983 ms. It contains 45 building
draw callbacks, 9.199 ms inclusive building drawing, and 5,369 `AtlasLibrary.region()` calls
with 3.259 ms self time. Frame 669 is 22.272 ms and also redraws 45 buildings, with 5,331 region
lookups. The per-frame top-self lists in the summary preserve these associations.

Code explains a plausible batching mechanism: `Building._process()` advances a vent timer,
toggles the vent frame every 1.4 seconds, and queues the **whole building** for redraw.
`Building._rebuild()` enables processing only for buildings with vents. Their timers start at
zero, while `_draw()` reconstructs walls, windows and roof furniture as well as the vent.
The measured batch is real; identifying the vent timer as its trigger is a source-derived
explanation, not a separate instrumented causal experiment.

## Engine totals and diagnostic cost

| Quantity | Median ms | p95 ms | Max ms |
| --- | ---: | ---: | ---: |
| Native profiler main-loop wall interval | 12.568 | 16.140 | 23.983 |
| Native process and render-submit span | 12.065 | 14.555 | 22.152 |
| Sum of emitted script self times | 5.685 | 6.888 | 12.248 |
| Profiled late-process callback interval | 13.020 | 15.487 | 23.062 |
| Profiler-disabled callback interval | 11.072 | 13.401 | 19.821 |

The profiler-disabled companion repeats the scene, route, warmup and retained duration, with
the same core observation logic, debugger connection and readout. Its observer adds held input
and velocity fields after the self timer. Its median callback interval is 1.948 ms
lower. This demonstrates material diagnostic perturbation; **it is not a calibrated correction
to subtract from each function**, nor a causal overhead estimate from a randomized repeated
experiment. Cadence changes the frame-dependent traffic state and callback counts. There is
one valid profiled rendered run and one disabled companion, so run-to-run uncertainty remains.
The observer itself measures a median 0.079 ms/frame profiled and 0.076 ms disabled. The final
observer schema adds held input and velocity after this self timer, a small unmeasured addition.

The engine process span includes render submission; its physics field is the **largest tick
in that frame**, not a sum of all ticks. The main-loop wall interval excludes final debugger
reporting and frame pacing sleep. These CPU-side elapsed timers are not hardware CPU samples;
they can include scheduling or blocking time. Script self sums and inclusive callback totals are distinct profiler products;
do not interpret their difference as GPU time. GPU completion, browser work, physical display
presentation, phone performance and the causal effect of population changes are unmeasured.

## Proposed targets, not implemented changes

1. Separate the animated vent's draw invalidation from the building's static drawing. Preserve
   vent timing, roof appearance, shadows, sorting and all building states; verify a repeated
   before/after route and pixel comparisons. This targets the measured tail batches.
2. Reuse same-frame future-source projections between halo and caret callers where their inputs
   are identical. Preserve player velocity/sensitivity, jolt state, positions and update ordering;
   compare every output before considering this safe. This targets steady prediction work.
3. Measure precomputed immutable event shape classification or cheaper equivalent matching for
   `has_a_spread()`. Preserve the entire event catalogue's shape classification and state changes.
   Its measured self cost makes it a narrower candidate than lowering entity counts or tick rates.

## Method, provenance and reproduction

`tests/probes/entity_frame_profile.gd` is a bounded headless TCP debugger receiver that launches
the actual main game inside the probe observer scene. The receiver enables native `servers`
profiling with 16,384 function slots and native-call expansion disabled. It retains every
message in memory and writes JSON after the child exits. The observer collects scene facts in
late `_process`, before render submission. It writes on exit even if a timed rig ends early.
Both startup-inclusive raw streams and the exact warmup-filtered analysis are preserved.

The installed engine source defines the protocol and timing interpretation:

- [Remote debugger peer](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/debugger/remote_debugger_peer.cpp)
  frames Variant packets with a byte length.
- [Remote debugger](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/debugger/remote_debugger.cpp)
  addresses commands by message name, thread ID and argument array.
- [Servers profiler](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/servers/debugger/servers_debugger.cpp)
  emits frame number, native times and function signature/calls/self/total/internal fields.
- [Main loop](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/main/main.cpp)
  emits profiler data before incrementing the process-frame counter. Late-process scene rows
  therefore join the profiler on the same frame ID. The accepted rendered profile has zero
  disagreements between recorded physics-frame deltas and Baby physics callback counts.

The script self sum includes diagnostic observer work; gameplay callback rows exclude it.
The analyzer checks packet shape, duplicate IDs/signatures, missing frames, function caps,
script self-sum consistency, directed motion, running/pause state, car movement and drawn-frame
progress. The accepted profile emits at most 495 functions/frame, well below the effective
16,384 cap. Compiler warnings are preserved in debugger messages: 154 pre-existing warnings
from loading game scripts, with no runtime error messages in the accepted windows. The normal
import/boot gate is separate from those debugger-only warnings.

From the measurement checkout, after `./tools/check.sh`:

```sh
ENTITY_PROFILE_OUTPUT=/tmp/crowded ENTITY_PROFILE_RENDERED=1 \
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script tests/probes/entity_frame_profile.gd
uv run python tests/probes/entity_frame_profile_analyze.py /tmp/crowded \
  --output /tmp/crowded-summary.json
```

For the companion add `ENTITY_PROFILE_DISABLED=1` and pass `--profiler-disabled` to the analyzer.
Omit `ENTITY_PROFILE_RENDERED=1` for the headless corroboration. The rendered window stays on top
but takes no focus, because a covered window can stop producing draw callbacks on this host.
One process is timed at a time. A 45-second receiver deadline backs the observer's 11-second
wall-clock window and the existing rig's 20-second simulated timer. Raw files are compressed
losslessly; the analyzer reads `.json.gz` automatically when `.json` is absent.

## Rejected trials and verification

`entity-headless-1` is a protocol-development failure: the initial command lacks its thread ID
and the observer waits on a draw callback unavailable headless. `entity-headless-2` and
`entity-headless-north` lack the timed-trace flags required to instantiate the input rig, so the
player is standing; neither supplies gameplay timing conclusions. `entity-rendered-1` has no
scene JSON because its observer flushes only on successful completion. `entity-rendered-2`
preserves only 1.084 seconds of draw-callback observations despite continued process profiling.
Draw suppression when covered is the working explanation; extending the backup timer alone
does not fix it. All available raw streams and logs for these trials are retained as rejected.
No rejected trial is pooled into the result tables.

Verification consists of the repository import/boot gate, actual headless and rendered probe
execution, analyzer integrity gates, and the focused frame-trace suite. No local full suite is
required and no production source file is patched. The report's conclusions remain bounded by
one valid rendered profile, one disabled companion, and the corroborating headless profile.
