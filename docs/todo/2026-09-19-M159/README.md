priority: now

## M159 — A slow frame names the frame that was slow · asked for 2026-09-19

The player says:

> M159 we need to find more things to optimize so yeah it should go to now. but "we will have to look in a different direction" means we have to think about other ways -- that is orthogonal to when it happens.

[sunny-chipmunk, mobile-ground review clarifications](../../playtests/2026-10-03-sunny-chipmunk.md)
records that instruction and the constraint on phone profiling;
[snowy-ibis, mobile ground-stepping feedback](../../playtests/2026-10-02-snowy-ibis.md)
records the phone observation. The next optimization remains to be determined.

> "we did some analysis of performance and lag frames / stutter. have astra look at the recorded
> numbers and the codebase and think about how we could improve performance and reduce stutter"

**On the desktop the player feels the stutter gone with v0.14.0's baked atlases**
([PLAYTEST-112](../../playtests/PLAYTEST-112.md): "I feel like the stuttering is gone (so it was
always what I predicted -- a proper atlas implementation solved it)"). The open items below are
reassessed against that: what remains is confirming it in the recorded numbers, and the phone.

**The deliverable is an optimization, with measurement retained as evidence.**
[PLAYTEST-86](../../playtests/PLAYTEST-86.md) clarifies: "well the point was to actually do some
optimizations. measurement is nice and make sure it's fully recorded but the core is to make
things faster". Instrumentation alone does not complete this item. Reduce a demonstrated cost
without changing gameplay, retain controlled repeated before/after distributions over equal
active-play windows, and verify identical behavior. A measured reduction in a named work metric
must be distinguished from whole-frame improvement and perceived smoothness. The existing noisy
toggle trials establish neither a causal toggle cost nor a shipping pacing choice.

**The conservative contribution rejection** is `CrowdAgent.contribution_at()` skipping velocity
and ellipse work outside a bound that includes the current jolt and the maximum forward stretch.
**The raw traces** come from `--frame-trace`, which supplies bounded raw callback intervals and
atlas CPU spans; its semantics and limits are in
[TELEMETRY.md](../../TELEMETRY.md#raw-frame-traces).

**What the phone records of [velvet-marten](../../playtests/2026-10-11-velvet-marten.md)
point at.** On days 9 and 14 of v0.27.1 the renderer's own work (`render`) is the largest bucket in
nearly every frame, mostly outside the engine's measured canvas render, and day 14's frames sit at
the 33ms line between two refreshes and three, which the player felt as "a lot of stutter" (#703). The
player chose what comes next: [shadows baked into their own page](shadows-are-pictures-on-their-own-atlas-page.md),
[nothing off screen redrawn or animated](nothing-off-screen-is-redrawn-or-animated.md),
[the frame straight to the screen, then fewer pixels](the-frame-goes-straight-to-the-screen-then-fewer-pixels.md),
and the readout's resolution and refresh (the [M159-9 record](../../decisions/2026-09-19-M159-9.md)).
[The cues and the events doing less](the-cues-and-the-events-step-less.md), the filer's proposal, and
[the cheaper tick](make-the-physics-tick-cheaper.md) take the game's own work down beside them.
Day 9's long spike is [bouncy-swan](../2026-10-11-bouncy-swan/README.md)'s.

The [scenery residency record](../../decisions/2026-09-19-M159-4.md) carries loading,
unloading and reconstruction contracts and their acceptance evidence. The remaining scenery
audit preserves stationary pixels while separating partial motion.
