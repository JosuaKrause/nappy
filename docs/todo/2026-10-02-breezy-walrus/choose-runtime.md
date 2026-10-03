# Choose the ground runtime after the phone evaluation

Wait for the player to choose among retaining stepped preparation, reverting
its runtime while keeping findings, and keeping the code off by default with a debug
dev flag to turn it on. If chosen, declare and document that flag in the shared
`src/dev/dev_flags.gd` declaration under the cli-tools rules, and make it one of the flags
`?debug=1` opens on the released page, so the phone can compare both positions (the player:
"debug already works on real release builds -- I can do debug=1&day=7 and start at day 7",
[sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md)). A plain dev flag is read only in
a debug build, since `DevFlags.enabled()` is `OS.is_debug_build()`; M193's `?debug=1` bundle is
what reaches a release page, and adding this flag to it widens that bundle beyond "the flags that
choose where a run starts or how it is drawn".
No code change is authorized by the request for a recommendation alone.

The assistant recommends restoring atomic preparation of nearby regions while
preserving loading/unloading, the comparisons, runnable measurement tools and
their pinned historical sources. This reverses only the scheduling experiment,
not the established nearby residency design. Any eventual implementation records
the player's choice, preserves later independent changes and updates its own
tests, design docs and review items in the same PR.

The phone report answers the perceptual stutter question for the tested build.
It does not establish the source of the remaining stutter. Finding more to optimize
is [M159's](../2026-09-19-M159/README.md), and "we will have to look in a different
direction" means "we have to think about other ways -- that is orthogonal to when it
happens" (the player, [sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md)).
The direction is open; do not infer a new bottleneck from the failed perceptual result. The README includes the median and
tail benefits as well as the costs behind the assistant's recommendation.
