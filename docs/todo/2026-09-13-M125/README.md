## M125 — The test suite is slow again · asked for 2026-09-13

> "Also the tests are slow again, too. Tests that only restate numbers in tables etc can be
> completely removed."

[PLAYTEST-67](../../playtests/PLAYTEST-67.md). The rule is the **verify** skill's, from 2026-09-03:
*a test that only doubles the work of a change is deleted, not maintained* — one that reads a
design decision back to itself, where "you changed a number" is all it could ever say. What it
keeps: a guard that a sweep was not vacuous, an ordering between two constants, and anything the
skill's incident list names.

**What is true today.** The head of `tests/run_tests.gd` says the budget: a suite over two
minutes on CI is a suite to split or cut, because the longest suite sets the floor every shard
waits on. CI runs eight shards planned from `tests/suite_costs.txt`, which `tools/ci-costs.sh`
refreshes from CI's own timings. `test_events.gd` and `test_routes.gd` are split by subject
(`DECISIONS.md`, M125, test_events and test_routes are split by subject); the new suites' rows
are estimates until `tools/ci-costs.sh` measures them.
