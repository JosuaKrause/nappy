## M159 — Crowded-scene CPU attribution and separate scenery animation · 2026-09-26

[Sunny lynx](../playtests/2026-09-26-sunny-lynx.md) asks for the work in each frame of a crowded scene,
without requiring desktop stutter reproduction or phone access. The player explicitly resumes
measurements and authorizes a draft PR after pausing the first investigation.

The [measurement record](../evidence/m159-entity-performance-2026-09-26/README.md) preserves the native
Godot profiler stream, population/movement observations, analysis, launch commands, engine
identity and rejected trials. The accepted rendered window is six active seconds after five
seconds of warmup: 200 walkers and 34 cars active, typically 18 walkers and 7 cars in view,
and 552 pixels of northward player travel. Median inclusive callbacks cost 3.114 ms/frame for
crowd updates, 2.688 ms for halo assignment/prediction and 1.619 ms for event updates. Crowd and
event callbacks include substantial predictive-cue work, so these are not pure movement costs.
The largest measured main-loop interval is 23.983 ms, with 45 building redraws taking 9.199 ms.
The source-derived explanation is the vent's 1.4-second timer invalidating the whole building.

There is one valid rendered profile, a profiler-disabled companion and a headless corroboration.
The companion's median callback interval is 1.948 ms lower, exposing material diagnostic
perturbation without establishing a calibrated correction or causal overhead estimate. Rejected
runs include missing input drivers and suppressed draw callbacks. Directed movement, complete
windows, drawn-frame progress, profiler coverage and physics counts are checked by the analyzer.
Probe instrumentation evolves between runs; the report identifies schema/timer differences and
distinguishes the final hardened probe from the exact commands retained in the logs. These are
desktop CPU-side elapsed measurements, not GPU, display-presentation or phone attribution.

The player's follow-up confirms desktop stutter in these runs: "I see the stutter on the desktop,
too, in the runs that you just did." They require animations to be separated from static ground,
with the animated texture absent from that ground, and ask for the frozen south-edge water to
receive the same treatment. This explicitly authorizes the scenery-animation implementation,
including the measured roof-vent redraw problem. It does not establish that every observed hitch
has that cause. Preserve the existing ground-composition decision from Playtest 108: runtime
composition of baked components remains; animation is separated rather than all variants rebaked.

**Proposed, not asked for:** animate the existing water artwork subtly and present an early burst.
No new water-art style is chosen by the player. Preserve the bulkhead, bridge opening, boundaries,
walkability and roof-furniture overlap. Keep future-projection reuse and event shape-classification
optimization as measured candidates, not changes silently included with the scenery work.

The probe passes import/boot, focused frame-trace verification, analyzer integrity gates, doc lint
and whitespace checks. Measurement completes that subtask; M159 remains open for the requested
scenery changes, controlled before/after evidence and the wider phone/optimization work.

The player extends the separation to "the water fountain in the broken pipe texture or the smoke
cloud from the car accident", requiring "only animate the small bits not the entire texture".
They then say "write that down as a plan for now" and "with the whole analysis". The
[separate-animation contract](../evidence/m159-scenery-animation-2026-09-26/CONTRACT.md) records all four cases and the
analysis. No implementation starts and no further measurements run until they resume the work.
This replaces the implementation go-ahead above with a plan-only checkpoint. M100's existing
water/smoke two-frame behavior and periods remain the visual contract; separating the pictures
does not authorize deleting their motion, redrawing a different scene, or changing event costs.

### Implementation resumption and main integration

The player resumes: "main updated again -- read your brief and let's start with the animation
optimization", then "pull the latest from the optimization branch". They explicitly authorize
committing/pushing and incorporating the next main update. These instructions end the plan-only
pause; they do not authorize merging the PR or publishing a release.

The branch is fast-forwarded to `322642ce`, then main `830b9fb8` is merged from base `25ad5497`.
Main's warning lifecycle, visit counters, recording tools and priority-band queue are retained
alongside the independent profiling records, probes and animation contract. The probe's existing
arterial movement flags remain valid; historical measurements are not represented as measurements
of the merged source. Import/boot, doc lint and the frame-trace/dev-rig suites pass.

After the roof implementation checkpoint `d8948e14`, main `3d3f2c96` is merged from base
`830b9fb8`. That main change routes visits and session-free game events through one counter site;
the branch separates roof furniture drawing. They touch separate implementation paths, and
the counter remains a no-op on native debug runs. Both sets of records retain their identities.
The merges are automatic, without conflict resolutions. Import/boot, doc lint and the combined
visit-counter/scenery-animation checks pass. Visual and controlled performance evidence remain
required before any claim that the animation optimization is effective.

### Separate animation and controlled result

The player clarifies that animated pixels are removed from the static sprite, moving parts get
their own sprites, and the city block's static drawing never animates. Roof vents, south water,
broken-pipe spray and crash smoke implement that separation. The original artwork, orientation,
registration, shadow, collision, phase timing and foreground overlap are preserved. Runtime
fixtures cover both event orientations, pause/resume and static-owner redraw invariants; the
waterfront burst covers the actual bridge and bulkhead. Requested GIFs are embedded in PR #385
with commit-pinned links. The [report](../evidence/m159-scenery-animation-2026-09-26/README.md)
retains original bursts, rejected fixture attempts, source extraction and comparison evidence.

Roof housing and furniture stay stationary; only the registered 6×6 rotor changes. Water owns a
separate surface and is absent from both static ground cells and the composed ground sheet.
Pipe/smoke SVG spans separate unchanged backgrounds from tightly cropped moving parts, preserving
painter order. Complete event pictures remain available for halo tracing and badges; this adds
375,408 base RGBA8 bytes to the event atlas. Atlas regions clear/rebind over removal/re-entry.
Independent early review found and corrected the retained-region lifetime problem and obsolete
full vent atlas entries, then the unused water source in the static sheet. The water regression
compares a complete independently derived south-band set with explicit bridge exclusions.

**Choices open to visual review:** water uses the existing artwork with a pausable shader ripple,
up to 0.65px horizontally and 0.35px vertically, at angular rates of 0.7 and 0.5 radians/second.
Separate source rasterization/compositing differs by at most one alpha level and three
premultiplied-color levels in RGBA8. A transparent texel around moving SVG crop bounds preserves
edge coverage. No new illustrated artwork is generated.

The [native comparison](../evidence/m159-scenery-animation-2026-09-26/native/README.md) retains
three alternating before/after pairs and one profiler-disabled pair, all accepted over identical
five-second warmups and six-second active windows, with byte-identical collectors and the same
main updates. Full-building draws fall from 180 to zero in every profiled window. Peak atlas
lookups fall from 5,357–5,388 to 171–187 per frame; window totals fall from 60,868–64,039 to
40,766–43,112. Baseline building drawing peaks at 8.809–10.066 ms inclusive; the replacement
small-part callbacks peak at 0.026–0.040 ms. The fixture proves small parts actually advance.

Whole-frame results are mixed. Profiled median pairs are 12.260→13.294, 12.901→11.914 and
14.789→12.964 ms. The separate profiler-disabled callback-interval median is 10.963→10.999 ms;
p95 rises slightly, while p99/max fall. One disabled pair is descriptive, not proof of a stable
tail improvement. The evidence establishes reduced redraw work, not a general FPS, phone,
browser or GPU gain. The arterial run does not isolate per-event spray/smoke speedups; their
fixture establishes drawing ownership instead. Import/boot, affected suites, source parity,
runtime invariants, lint and whitespace checks pass; full-suite CI and final review are separate
gates. No PR merge or release is authorized.

The player accepts a progress checkpoint: "I mean it's good progress for now we can push that"
and asks to include the latest findings. They ask for the next hypotheses to be queued, then
authorize marking the PR ready for review once pushed. Three items are filed under M159:
event-shape classification caching, reuse of identical danger predictions, and reuse/lazy
preparation of static visuals. Current after profiles still spend about 0.605–0.614 ms self time
on `has_a_spread()` over 759–764 calls/frame, with 2,640–2,653 crowd contribution queries/frame.
These support investigation; call counts do not establish identical inputs or hitch causation.
Lazy preparation must measure the actual shared-sheet/draw-command architecture, preserve eager
gameplay state and avoid first-visible-frame loading. No proposed follow-up is implemented here.

The final review checkpoint merged main `27d80a55` into `74c89bae` from base `3d3f2c96`.
Only `HANDOFF.md` conflicted: main carried other sessions' pickup state and an outdated plan-only
description of this PR; the branch carried the completed animation checkpoint. The resolution
kept the current animation state and retained the other open PRs, spent-park plan and counter
readback as separate pickup threads. Main's independent queue/playtest records stayed distinct.
Its GoatCounter edits clarified stored path spelling in help/docstrings, without changing
runtime code; telemetry docs and the review item agree on `/nappy` visits versus `nappy-` metrics.
No gameplay source or measurement collector changed in this merge.

CI on the preceding source checkpoint exposed two integration assumptions outside the locally
selected suites: southern camera coverage counted only static ground tiles, and event-atlas
ownership expected one page reference while separated moving layers added another. These
failures require reconciliation on this PR before its final independent readiness verdict.

Correction `c753b3d1` removes `EventScenery`'s redundant acquire/release calls: `EventManager`
already holds the events page across its full tree lifetime, covering streamed children and
day clears. The camera coverage failure belongs to `test_main.gd`, not `test_camera_start.gd`;
its zero-unpainted assertion now counts actual water-surface cells alongside static TileMap cells.
Before the correction, `tools/test.sh camera_start atlas_events` reproduces three ownership
failures, and `tools/test.sh main` reproduces both southern-corner coverage failures. Afterwards,
`tools/test.sh camera_start main atlas_events scenery_animation event_redraw atlas_leaf_consumers`
passes 3,093 checks; import/boot and whitespace checks pass. This is a focused run, not full CI.
No artwork, draw geometry, animation clock or gameplay changes. The archived timings remain
measurements of `0fed117c`; the final reference-count correction affects stream-in/out and is
not remeasured, so those results are not presented as fresh measurements of the final head.

The player then explicitly approved every visual change: "I approve every visual change. I said
it to the other agent. Saying it here again so you can record it. other than that I agree with
your assessments" ([Sunny lynx](../playtests/2026-09-26-sunny-lynx.md)). This approves the water
ripple and separated vent, spray and smoke; the appearance review closes. Earlier proposal
wording above records how the design was introduced, not an outstanding request for approval.
Phone/browser performance remains unverified. The player also accepts the review correction
plan and an explicit follow-up audit of the café, street musician and poster crew rather than
silently claiming that all partially animated sprites have been migrated.

### Review corrections and rendered warmup

The twelve-item review of `74c89bae` prompted corrections on the same PR. Water surfaces now
reuse one preloaded shader while retaining independent material uniforms and clocks. Both
ordinary and escape startup draw the halo and a real water atlas region on camera before play.
Transparency is supplied as draw vertex color, preserving the Compatibility renderer's draw
submission; setting node modulation alpha to zero was rejected because it can cull the draw.
Standalone event-catalogue fixtures acquire their own atlas page, while gameplay keeps the event
manager's sole ownership. Static-frame assertions, smoke/spray redraw naming and rotor crop
registration are corrected; the crop is checked against both authored SVG view boxes.

The maintained source generator and crop helper live under `tools/`, with help, argument
rejection before I/O, a non-writing check mode, explicit metadata regeneration and CLI coverage.
Generated headers identify SVG sources as editable and crop metadata as derived. All 28 SVG
geometry bodies remain byte-identical; atlas membership and historical layer/provenance records
are unchanged. The parity probe requires a new output directory rather than overwriting archived
evidence. The graphics docs and SVG/event authoring skills now state the partial-animation
contract, including legitimate foreground/background overlap. The café, street musician and
poster crew remain in the agreed audit; the contract is not a claim that this audit is complete.

Import/boot and the focused event-catalogue, atlas-events, scenery-animation, event-redraw,
camera-start, main and atlas-consumer suites pass 4,142 checks with no failures. The parity probe
passes eight checks; Python tooling, CLI checks, generator parity, lint and whitespace checks
pass. These are focused local checks, not a substitute for the PR's full-suite CI.

The [retained dual-boot capture](../evidence/m159-scenery-animation-2026-09-26/rendered-warmup-2026-09-26/README.md)
uses Godot 4.7.2, Compatibility/OpenGL3 and an Apple M2. Both real boot branches keep the halo
and water warmup nodes live through `frame_post_draw` and complete a visible boot frame. The
existing waterfront burst supplies the approved shoreline appearance. An earlier windowed
attempt produced zero burst frames and establishes nothing. The successful capture is evidence
of rendered warmup, not a measurement of compilation duration, hitch elimination or phone speed;
the earlier controlled timings retain their original source identity.

The original profiling folder is renamed to `m159-entity-performance-2026-09-26` to carry its
queue entry. Live links move with it; raw summary path fields retain the capture-time spelling,
and the report documents that mapping. The handoff restores unrelated guidance from main while
updating this PR's pickup state. The player's explicit visual approval closes the appearance
item. The correction work leaves the queue; final independent review and CI remain PR gates.
