**Scenery separation contract and original crowded-scene analysis.**

**Implementation is authorized.** The player resumes on 2026-09-26: "main updated again -- read
your brief and let's start with the animation optimization". Start with the measured roof-vent
redraw, then carry the same separation through water, pipe spray and crash smoke.
This preserves the implementation contract for M159, a slow frame names the frame that was slow.
The player's complete instructions are in [Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md).
The [full measurement report](../../evidence/entity-performance-2026-09-26/README.md) holds the raw
streams, analysis outputs, commands, engine identity, rejection records and provenance.

## What the player asks for

The player sees desktop stutter in the profiling runs as well as on mobile. Animated scenery
must have its own drawing, with the animated image absent from the static layer. Only the small
moving parts animate; changing a small detail must not redraw an entire ground surface,
building or event picture. The named cases are roof vents, the frozen water south of the map,
the fountain in the broken-pipe scene and the smoke from the car accident.

The retained analysis below supplies the baseline and preservation contract for implementation.
The [implementation report](README.md) and [controlled comparison](native/README.md) describe
the resulting separation and its measured limits. The figures and source explanation below are
the original investigation, retained as provenance rather than measurements of the final code.

## Measured scene and method

Native Godot 4.7.2 on an Apple M2, macOS, OpenGL compatibility rendering, 1280×720 viewport.
Day 1, seed 4242, arterial spawn, walking north. Physics runs at 30 Hz; the diagnostic frame
cap is 120 FPS with VSync disabled. Readout and raw frame tracing are on; graph and telemetry
are off. Normal source queries and loss conditions remain active; invincibility is off and
saves are disabled.

Each retained window excludes five wall-clock seconds of warmup and keeps six active seconds.
The accepted rendered profile has 454 frames and 181 physics ticks; every process interval
advances the drawn-frame counter once. The profiler-disabled companion has 530 frames and
181 ticks. Headless corroboration has 664 frames and 180 ticks and measures no rendered work.
All three travel 551.997 pixels north, matching six seconds at the 92 px/s walking speed.
Typical movement includes 29 cars changing position each frame.

There are 200 active walkers and 34 active cars. The typical viewport contains 18 walkers,
7 cars and 4 events; visible maxima are 25 walkers, 8 cars and 5 events. Active events have a
median count of 52 and maximum of 56. Visibility here means an origin inside the viewport with
a visible node, not an occlusion-tested pixel count. Off-screen active entities still cost CPU.

The receiver uses the native debugger's every-frame function profile. Scene observations join
by engine process-frame ID. The analyzer rejects missing profile frames, function truncation,
paused/ended/incomplete windows, missing directed walking, absent car motion and stalled drawing.
Recorded physics tick deltas agree with Baby physics callback counts. The archived report
documents exactly how the probe evolves during capture; the final hardened probe is not claimed
to be the byte-identical generator of every older stream.

## Steady CPU work

Milliseconds below are **inclusive callback elapsed times**, including each callback's helper
calls, summed across its instances per frame. These rows must not be added to their nested
breakdowns or to engine totals. Different rows' maxima need not occur together. Physics rows
use the 181 frames with one tick; the other 273 frames have no tick. No retained frame has
multiple ticks. Percentiles use nearest rank.

| Work | Median ms | p95 ms | Maximum ms | Typical calls |
| --- | ---: | ---: | ---: | --- |
| Crowd updates: movement, steering, redraw decisions | 3.114 | 3.470 | 3.889 | 234/frame |
| Halo source selection, prediction, assignment | 2.688 | 2.968 | 3.119 | 1/frame |
| Live event behavior and redraw decisions | 1.619 | 1.830 | 1.903 | 52/frame |
| Crowd drawing | 0.455 | 0.699 | 0.831 | 15/frame |
| Screen-edge danger prediction | 0.174 | 0.194 | 0.217 | 1/frame |
| Event drawing | 0.155 | 0.278 | 0.452 | 5/frame |
| Main loop and debug readout | 0.147 | 0.194 | 0.244 | 1/frame |
| Building drawing | 0.000 | 0.000 | 9.199 | 0/frame; maximum 45 |
| Traffic, signals and player contacts | 0.749 | 0.803 | 0.856 | 1/tick |
| Baby meter and source queries | 0.370 | 0.428 | 0.506 | 1/tick |
| Event streaming, placement and contacts | 0.357 | 0.465 | 0.612 | 1/tick |

The first three rows dominate steady script work, but they are not three independent
locomotion costs. Crowd redraw decisions take a median 1.215 ms **within** crowd updates.
Event redraw decisions take 1.506 ms **within** event updates. Both contain danger prediction.
Across callers, crowd future-contribution projections take 1.349 ms inclusive over 268 calls
per frame, and event projections take 2.269 ms over 104 calls. Crowd contribution queries occur
2,589 times per typical frame. The event shape classifier `has_a_spread()` is called 776 times
and takes 0.629 ms median self time. These locate repeated work; they are not extra additive
rows. Headless measurements rank the same three outer callbacks first, at 2.891, 2.609 and
1.573 ms median, but subtracting headless from rendered costs would not isolate rendering.

## Expensive frames and interpretation

The largest measured main-loop wall interval is 23.983 ms. In that same frame, 45 buildings
redraw, taking 9.199 ms inclusive; 5,369 atlas-region lookups take 3.259 ms self time. Another
22.272 ms interval also includes 45 building redraws and 5,331 region lookups. These are the
recorded frame associations, not a claim that every hitch has this cause.

`Building._process()` toggles its vent frame every 1.4 seconds and queues the whole building
for redraw. Its `_draw()` reconstructs every wall, window, roof tile and furniture item.
Vent timers start together at zero. This supplies a source-derived explanation for batched
redraws; a controlled before/after separation is still needed to establish the gain.
The measured spike is **building drawing**, not a measured ground-TileMap rebuild. The player's
broader ground and event-animation instruction applies the same separation rule beyond that
measured case. No individual pipe-fountain or crash-smoke cost is isolated in these runs.

| Timing quantity | Median ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Native main-loop wall interval | 12.568 | 16.140 | 23.983 |
| Native process/render-submit span | 12.065 | 14.555 | 22.152 |
| Sum of emitted script self times | 5.685 | 6.888 | 12.248 |
| Profiled observer-to-observer interval | 13.020 | 15.487 | 23.062 |
| Profiler-disabled observer interval | 11.072 | 13.401 | 19.821 |

The disabled companion's median interval is 1.948 ms lower. This is material diagnostic
perturbation, not a calibrated amount to subtract from functions or a randomized causal estimate.
There is one accepted rendered profile and one disabled companion, with frame-dependent crowd
state and evolving observation fields. Observer self time is about 0.079 ms profiled and
0.076 ms disabled; the later input/velocity fields have a small additional unmeasured cost.
Gameplay callback rows exclude the observer; emitted script self totals include it.

The native process span includes render submission. The engine physics field is the largest
tick in its frame, not the sum of ticks. The main-loop interval excludes final debugger reporting
and pacing sleep. Timers are CPU-side elapsed time and may include scheduling/blocking; no
residual is labeled GPU time. Browser, GPU completion, display presentation, mobile timings and
the causal effect of population changes remain unmeasured. The player's desktop observation is
real feedback, while attribution of every perceived stutter remains unproven.

Rejected trials remain separate: a debugger-protocol failure, two launches without the timed
input driver, a rendered run without an exit-flushed scene record, and a rendered run whose
draw observations stop after roughly one second. Crowd shove is not proof of walking; continuing
process callbacks are not proof of continued rendering. The accepted run uses a no-focus window
kept on top and checks drawn-frame progress. The report retains every available rejected stream.

## Required separation by case

| Case | Static content | Independently animated content | Preservation contract |
| --- | --- | --- | --- |
| Roof vent | Building walls, windows, roof, other furniture and stationary vent housing | Small rotor/moving detail | Existing placement, two phases, 1.4s timer, roof overlap and building states |
| South-edge water | Bulkhead, bridge deck and ordinary ground; no duplicate animated water texture | Water-only surface/ripple drawing | Existing south border and corner ownership, bridge opening, palette, map bounds and collision |
| Broken-pipe fountain | Pipe, crater, asphalt, barriers and stationary surroundings | Fountain, moving spray/droplets and changing water glints | Both street-axis projections, original registration/scale, existing 0.5s phase behavior, no new shadow |
| Car-accident smoke | Cars, onlookers, debris, road details and the existing contact shadow | Small smoke puffs/wisps | Both street-axis projections, existing 1.2s phase behavior, unchanged two-body collision and shadow |

The pipe and crash currently select whole-scene A/B pictures from `EventInstance._draw_body()`;
their animation phase also changes `_picture_key()`, invalidating that entire draw list.
M100, water, smoke and steam move, records the requested two-frame animation. Preserve that
behavior while changing ownership of its pixels and redraws. The existing basement steam/grate
split is a useful reference: the grate stays at ground level and only the cloud animates.

Separating artwork means recovering the stationary background underneath every moving phase.
Do not leave one phase baked into the base and draw another over it. A difference mask alone is
insufficient when a puff or spray uncovers pixels. Retain exact offsets after tight cropping;
keep the animated asset genuinely small rather than storing another whole-scene transparent
canvas. Composite each phase over the base to verify alignment, coverage and appearance.

## Implementation contract

1. Audit the named drawing paths and any comparable scenery animation, recording which static
   draw list each phase invalidates. Start with the measured building spike. Keep scene generation,
   event costs, population, simulation cadence and RNG untouched.
2. Split static and animated artwork, with registered transparent moving-part frames where
   appropriate. SVG sources, illustrated fallbacks, atlas membership, resource lifetime and
   texture manifests must agree. Follow the relevant SVG/illustration skills; do not silently
   regenerate an accepted scene in a new style. Show an early burst on the PR for visual feedback.
3. Give small animated pieces their own retained drawing. Frame changes update only those pieces.
   Remove their pixels from the static owner, and prevent animation-only changes from invalidating
   the static ground/building/event draw list. Static state changes still update their owners.
   Preserve overlap explicitly: a vent behind taller furniture or smoke behind a foreground body
   cannot simply be moved to a child that draws above everything. Keep event halo body tracing,
   screen-edge pictures, shadows, scaling and both orientation paths correct.
4. Put south water on a separate surface drawing, absent from the static ground tile layer.
   **Proposed, not asked for:** subtle ripple motion using the existing water artwork. A
   water-only shader or small animated ripple layer is a technical option to inspect, not a
   settled implementation. Avoid per-frame ground composition, large image uploads and atlas
   sampling bleed. Keep the bridge gap and bulkhead stationary. The appearance and exact motion
   remain a visual-review choice; no new timing value is approved by this plan.
5. Reuse the existing ground composition. Playtest 108 explicitly chooses runtime composition
   of baked component pictures for variety and atlas size; separation is not permission to
   rebake every ground variant or to replace the ground system.
6. Verify structural invariants, appearances and measured cost before proposing the optimization
   as effective. Keep all fixes, evidence and corresponding docs on this work item's PR.

The exact node/shader arrangement is an implementation proposal subject to those contracts.
Merely staggering timers, reducing animation frequency or skipping visible updates does not
fulfill the requested separation. Reusing future-source projections and precomputing immutable
event shape classification remain separate measured candidates for steady CPU work; they are
not silently bundled into this scenery change.

## Acceptance and controlled measurement

Focused tests must demonstrate that advancing animation changes its small drawing while static
ground/building/event owners remain unchanged. Check both event orientations, static state changes,
repaint/restart, pause/resume, removal and resource release, plus preserved collisions and bounds.
Check composite phases against the current pictures and record bursts of vents, south water,
pipe fountain and smoke. Still images alone cannot establish animation. Keep save protection;
visual rigs may use invincibility when their subject is appearance, but timing rigs must not.

For performance, run the same **final** collector and observation schema on before and after
code, excluding setup and using identical six-second active windows after five-second warmup.
Use repeated alternating before/after runs, one measured game at a time, with the same route,
crowd/event configuration, renderer, cap, readout and profiling settings. Preserve raw results
and rejected windows. Obtain profiler-disabled comparisons too; do not subtract the existing
1.948 ms difference as a universal correction. Keep cold asset loading separate from warm play.

The primary work metric is whole-building/static-scene redraws and atlas lookup volume on
animation transitions. Verify the new small-part draws actually advance; zero work from missing
animation is failure. Report frame median/p95/p99/max and transition-associated costs, plus
observer overhead, draw-call/resource changes and workload differences. Add focused pipe/smoke
and waterfront scenes because the arterial baseline does not isolate those effects.

Do not claim mobile stutter is solved from native results. Phone/browser confirmation and the
wider M159 optimization/atlas questions remain open. Run import/boot, the focused affected
suites and doc lint for implementation; full-suite verification remains CI's.
Independent semantic and code review is required before any merge, which still needs permission.
