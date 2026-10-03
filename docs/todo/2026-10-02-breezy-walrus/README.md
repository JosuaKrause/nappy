priority: now

# breezy-walrus — Three modes of nearby ground preparation, all at once by default · filed 2026-10-02

The player cannot say that spreading ground preparation removed mobile stutter.
They ask whether to retain the code "(it does improve a little bit on paper)",
revert it while preserving findings, or
keep the stepped-loading code off by default, switchable through a debug dev flag.
Their full words and context are in
[snowy-ibis, mobile ground stepping does not visibly remove stutter](../../playtests/2026-10-02-snowy-ibis.md).
The player chose a fourth shape instead: three modes, the first the default, switched on the
phone under `?debug=1` ([tawny-stork](../../playtests/2026-10-03-tawny-stork.md));
`choose-runtime.md` holds the build.

The player says "we will have to look in a different direction" and clarifies:
"M159 we need to find more things to optimize so yeah it should go to now. but
\"we will have to look in a different direction\" means we have to think about other
ways -- that is orthogonal to when it happens."
[sunny-chipmunk, mobile-ground review clarifications](../../playtests/2026-10-03-sunny-chipmunk.md)
records that answer and defines the toggle. M159, a slow frame names the frame that
was slow, holds the search for more optimizations in `now`; which other approach
helps remains open. [PLAYTEST-140, steady phone stutter](../../playtests/PLAYTEST-140.md)
records Chrome on a Pixel 8 Pro and "it's pretty regular nothing stands out" as
earlier context, not identification of the latest test's device.

The merged choice is [silky-rabbit, nearby ground regions prepare across
frames](../../decisions/2026-10-02-silky-rabbit.md): per-region stepping is the
implementation for phone evaluation, with modest native gains and measured
steady costs; it becomes the third mode, and the default goes back to preparing each
needed region whole in one frame.

The comparison behind the choice, kept for whoever builds and measures the modes: on the
native fixture, stepping moved ordinary south at 60Hz from 1.190–1.202ms median to 1.067–1.070ms,
p95 from 3.519–4.021ms to 2.849–3.073ms, p99 from 4.627–5.274ms to 4.292–4.441ms, and the worst
sample from 8.710ms to 7.414ms, with mixed 15Hz tails; on the settled-shoreline fixture it raised
draw calls from 38 to 46, water surfaces from 6 to 24, tracked Godot allocation by about 61% (not
RSS or GPU memory), and steady median spans from 0.792–0.814ms to 0.818–0.842ms. These fixture
results do not establish a whole-game or perceptible phone improvement.
