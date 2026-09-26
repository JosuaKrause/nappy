## M125 — test_events and test_routes are split by subject · built 2026-09-25

*([PLAYTEST-67](../playtests/PLAYTEST-67.md): "Also the tests are slow again, too." ·
[PLAYTEST-137](../playtests/PLAYTEST-137.md): "one shard took significantly longer than the rest".)*

**Why.** On CI, `test_events.gd` took about 279s alone and `test_routes.gd` about 159s, so the
first set the floor of the eight-shard plan however the rest were balanced.

**What is built.** `test_events.gd`'s 96 tests are ten suites named for what each proves —
`catalogue`, `emission`, `pursuit`, `scenery`, `fire`, `scheduler`, `costs`, `solid`,
`placement`, `chat` — five of them extending `tests/events_shared_city.gd`, which keeps the
memoised `_map()`, `_rng()` and `_planned()` the old file built once. `test_routes.gd`'s 21 are
four: `lattice`, `closures`, `fallen_trees` (it re-plans a seed's fourteen days uncached) and
`kerb_tint` (the one needing a scene tree). Helpers used by one or two tests are duplicated per
file, as the crowd split did. `suite_costs.txt` carries estimated rows for the new suites and
`test_home_block.gd`, scaled from local times by each old suite's CI-to-local ratio (about 1.5).

**A test that never ran.** `_test_no_body_closes_a_walked_sidewalk` was defined in the old
`test_events.gd` and never called from its `run()`; it runs now, in `test_events_solid.gd`, and its
441 checks are the whole difference between the old total (96,247) and the new (96,688). Every
other suite's count matches the old code running the same tests.

**Measured locally**, contended: events 190.9s became 0.1–75.8s per suite; routes 99.6s became
1.0–84.8s. By the CI ratio, `test_events_scheduler.gd` (about 111–121s) and
`test_routes_closures.gd` (about 134s) sit at the budget, both already split twice; the next
split waits for CI's own numbers.
