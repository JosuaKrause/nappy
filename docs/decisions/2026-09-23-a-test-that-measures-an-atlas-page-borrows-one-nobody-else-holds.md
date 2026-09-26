## A test that measures an atlas page borrows one nobody else holds · 2026-09-23

*(CI shard failures on PR 289, the power station, and PR 297, the rig that walks the route.)*
`tests/test_telemetry.gd`'s check that a baked page writes one load line and one release line
chose the `events` group as "the one group with no consumer yet". That stopped being true when
every `City`'s `EventManager` began acquiring it, so the check passed or failed on which suites
shared its CI shard: any earlier suite that left a `City` standing kept `events` resident.
**Rejected: freeing leakers one at a time** — PR 289 freed `tests/test_protest.gd`'s, and the
next shard layout found another. **Built:** `AtlasLibrary.borrow_group_for_tests()` registers a
page under a name no consumer asks for, read from a real group's baked file, and
`forget_test_group()` removes it; `reset_for_tests()` stays unused there because it would desync
a consumer still in the tree. The leakers were freed as well: `tests/test_resistance.gd` built
seventeen cities and freed one; it now frees each before building the next.
