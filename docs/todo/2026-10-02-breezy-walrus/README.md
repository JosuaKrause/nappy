priority: now

# breezy-walrus — Choose ground preparation after the mobile test · filed 2026-10-02

The player cannot say that spreading ground preparation removed mobile stutter.
They ask whether to retain the code, revert it while preserving findings, or
keep the stepped-loading code off by default, switchable through a debug dev flag.
Their full words and context are in
[snowy-ibis, mobile ground stepping does not visibly remove stutter](../../playtests/2026-10-02-snowy-ibis.md).
They have not selected one of those options.

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
steady costs. This entry does not overturn that runtime before a player choice.

**Proposed, not asked for:** preserve all experimental findings and restore
atomic preparation of each nearby region, retaining existing loading/unloading.
The native comparison shows benefits in both median and tails: ordinary south
at 60Hz moves from 1.190–1.202ms median to 1.067–1.070ms, p95 from
3.519–4.021ms to 2.849–3.073ms, p99 from 4.627–5.274ms to 4.292–4.441ms,
and worst sample from 8.710ms to 7.414ms. The 15Hz tails are mixed. These fixture
results do not establish a whole-game or perceptible phone improvement. The
assistant weighs those gains against the added drawing/allocation costs and pending-job
lifecycle. Keeping a debug flag retains both runtime paths for development and their
testing obligations. That is a maintenance tradeoff, not a player-facing setting.
Retaining stepping or the debug flag remain alternatives for the player to choose.
