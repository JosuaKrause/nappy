## Test-suite performance — 2026-09-09

Asked for: "make the test suite faster".

**PR #64 review.** The reviewer accepted both optimizations and identified unnecessary scaffolding
and tests that would obstruct a later correctness fix. The route cache's inputs are fixed for the
tree's lifetime: the grid has no post-build mutation and the map's main-road position is assigned
by generation. The growth-only toggle and clear were therefore unnecessary. The no-main-road path
needs no cache because it already returns the grid's neighbor array directly. A shared growth
helper and uncached filtering helper let the differential test vary only memoization, instead of
maintaining a second copy of route growth.

The crossing-route assertion was removed rather than changing placement behavior in this
performance PR. Two mobile paths crossing at their interiors have a true geometric gap of zero;
the endpoint calculation can miss that. Pinning a positive answer would make a correctness fix fail
the test. The comparison against symmetric spacing is limited to pairs with a stationary side,
where the optimized result is exact. This leaves the mobile-crossing defect as a known limitation,
not a design requirement.

The pushing rule was reconciled into one permission covering ready work and unfinished drafts,
with the player's dated words retained. The four-shard comment keeps its load-balancing reason:
with the configured cost estimates, a fifth worker still waits for the largest suite, while three
workers carry more work apiece than that floor. No weight was added for the small spacing suite.

The starting full run took 268.43 seconds on the local Mac with four shards. It executed 648,478
checks; three burst-capture file checks failed because the sandbox denied the Godot user directory.
The event suite was the limiting shard at 264.06 seconds; generation took 172.95 seconds and routes
163.39 seconds. These are measurements of this checkout, not promises about other machines.

A separate headless probe over three seeds and days 1, 7 and 14 measured route construction with
repainting at 217.40 ms/day, grid construction at 40.66 ms/day, and event scheduling with an already
built tree at 400.59 ms/day. Generation's hard-blocker phase, which constructs a reference route
tree, took 246.33 ms on seed 4242.

`RouteTree._ways` filtered the same node's neighbors on every revisit during the loop-erased random
walk. The grid and main-road position cannot change inside one `grow` call, so those filtered lists
can be reused within that call. Their order and duplicate edges must survive: the random walk rolls
an index into the list, so either changing its order or deduplicating it changes seeded routes.
The initial cache was enabled only while `grow` executed, then disabled and cleared. A probe measured
101.25 ms/day after this change. A bounded comparison with the uncached algorithm checks both
ordered branch routes and final RNG state across two seeds and days 1 and 14; the existing
six-seed, four-day route invariants remain in place.

The scheduler profile located 2,966 ms of nine builds in recurring placement, versus 522 ms in the
final walkability check and about 103 ms elsewhere. `_gap_between` measured endpoint distances in
both directions even when one event was just a point. Distance from that point to the other event's
whole route already includes the endpoints, so the second pass cannot improve the answer. Paths
with fewer than two points use `position`, matching `Planned.ends` and `distance_from`; two mobile
routes still use the symmetric calculation. Over 17,391 placed-plan pairs from seed 4242/day 14,
the shortcut returned bit-identical distances for every pair. Twenty repetitions took 227.9 ms
against 456.8 ms for the original calculation. This changes neither candidate order nor RNG draws.
Focused geometry tests cover both argument orders, a point nearest a segment's interior, a
one-point path whose sole point differs from its position, and duplicate zero-length segments.
Two crossing mobile routes retain the endpoint-distance approximation; the function's docstring
now describes that limitation rather than claiming an exact segment-to-segment minimum.

The full verification run encountered two concurrent Godot test processes from the parallel Claude
checkout. Its elapsed time therefore cannot measure the optimization against the starting run, and
the sharding cost table was not retuned from that contended sample. The component comparisons above
are the performance evidence; the full run is the integration check.
It completed 648,547 checks with zero failures in 344.70 seconds. The extra checks include the new
regressions and capture checks that can proceed once the user directory is writable. The boot
check and doc lint also passed. No open gameplay queue item was implemented or reprioritized.

Rejected: removing the repaint on cached route-test plans. The plans are cached, but later
assertions still inspect the map's current day, and a cache hit must restore that day. No seed sweep
was shortened, no simulation was stepped less often, and no mutable map was shared across suites.
