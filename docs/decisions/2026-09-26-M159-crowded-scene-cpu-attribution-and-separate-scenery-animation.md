## M159 — Crowded-scene CPU attribution and separate scenery animation · 2026-09-26

[Sunny lynx](../playtests/2026-09-26-sunny-lynx.md) asks for the work in each frame of a crowded scene,
without requiring desktop stutter reproduction or phone access. The player explicitly resumes
measurements and authorizes a draft PR after pausing the first investigation.

The [measurement record](../evidence/entity-performance-2026-09-26/README.md) preserves the native
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
[separate-animation plan](../todo/2026-09-19-M159/separate-scenery-animation-from-static-ground.md) records all four cases and the
analysis. No implementation starts and no further measurements run until they resume the work.
This replaces the implementation go-ahead above with a plan-only checkpoint. M100's existing
water/smoke two-frame behavior and periods remain the visual contract; separating the pictures
does not authorize deleting their motion, redrawing a different scene, or changing event costs.
