## M125 — The test suite is slow again · the crowd suite split and four suites sized, 2026-09-13

*(The entry's one remaining item after the first pass; the player's word to start it: "sure go
ahead".)* Five agent commits on `feature/m125-suites-over-budget`, reviewed on the PR.

**The crowd suite is split at its own seals boundary.** `tests/test_crowd.gd` keeps the
population, the contact and strike physics and the street hierarchy; `tests/test_crowd_closures.gd`
takes the hard and soft seals, the pocketed junctions, a region wall's door, the bridges, the
tunnels and the map edges. The cut was made by a script with asserted anchors rather than by
retyping, every test function is called exactly once in its own file, and the check total is
unchanged (179 became 113 and 66). Nothing in the four sized suites was deleted as a
restatement: `test_checkpoints.gd` and `test_seals.gd` share one plan per map and day across
tests that each recomputed it; `test_resistance.gd` and part of `test_checkpoints.gd` sample
fewer seeds for a rule asked per placement, the convention `test_routes.gd` and
`test_regions.gd` already use; `test_balance.gd` walks the arterial for sixty seconds rather
than the whole day, since sleepiness printed every ten seconds plateaus by ten and holds flat,
and sixty is six times that.

| suite | before | after |
|---|---|---|
| `test_crowd.gd` | 227s | 82s, plus `test_crowd_closures.gd` at 61s |
| `test_checkpoints.gd` | 71s | 13s |
| `test_resistance.gd` | 66s | 36s |
| `test_seals.gd` | 107s | 40s |
| `test_balance.gd` | 107s | 39s |

Serial, one process each, on the same machine; the row in `suite_costs.txt` was then
re-recorded under four-way local contention and runs higher than these, so the plan's absolute
numbers are pessimistic until a quiet `--record-costs`.

**One cache reverted.** A first pass that cached every planned map in `test_seals.gd` broke the
fallen-tree check, which reads live per-day map state that a cache hit leaves stale; that test
and its helper stay uncached with the reason on them.

**What is left.** `test_events.gd` at about 160s and `test_routes.gd` at about 141s are the
longest shards now and both had the first pass already, so the next step is a split by subject
for each; the entry holds it. The two small suites M124 and M135 added have no recorded cost
until the next `--record-costs`.
