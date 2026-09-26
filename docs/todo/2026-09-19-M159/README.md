## M159 — A slow frame names the frame that was slow · asked for 2026-09-19

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

`CrowdAgent.contribution_at()` skips velocity and ellipse work outside a conservative bound
that includes the current jolt and the maximum forward stretch. The exact-parity checks and
repeated before/after measurement are in [DECISIONS.md](../../DECISIONS.md), M159, cheaper crowd
contribution sweeps; the raw evidence is
[the contribution measurement record](../../evidence/m159-crowd-rejection-2026-09-19/README.md).
This establishes a reduction in query cost, while the remaining long-frame cause and phone
behavior still require the work below. `--frame-trace` supplies bounded raw callback intervals
and atlas CPU spans; its semantics and limits are in [TELEMETRY.md](../../TELEMETRY.md#raw-frame-traces).
