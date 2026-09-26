## M125 — The test suite is slow again · built 2026-09-13

*(2026-09-13, [PLAYTEST-67](../playtests/PLAYTEST-67.md): "Also the tests are slow again, too. Tests
that only restate numbers in tables etc can be completely removed.")* Seven agent commits on
`feature/m125-test-suite`, two agents, reviewed here. The rule applied is the **verify** skill's:
a check that would only ever go red to say "you changed a number" is deleted, and one that would
say "you broke the thing the number was for" stays.

**Item 1, the restated tables.** Deleted one line at a time, each named in its commit with the
sentence it could have said: `test_acts.gd`'s `act_for_day(3) == 1` and its six marquee
`not available_on(N)` checks (each row's own `first_day` read back, while the general sweep of
every row's `act_tag` against the act is the rule those six were examples of, and stays);
`test_events.gd`'s whole `_test_burning_building_is_a_day_three_one_shot` (six field reads);
and the same shape in `test_checkpoints.gd` and `test_heat.gd`. Nothing deleted was slow; the
pruning is worth doing on its own because a brittle check is a second place every balance edit
has to be made.

**Item 2, the loops sized to what they prove.** The cost was less the seed counts than asking
the same question twice. `test_generator.gd` regenerated the cities its 200-seed guarantee
sweep had already built — nineteen loops at a quarter of a second a city, two thirds of the
suite — and now caches the first 64 pristine cities in `_map(i)`, with every guarantee sweep
asking for exactly as many seeds as before. `test_events.gd` shares one generated map and
memoizes `EventScheduler.build_day` per day across ten call sites that each re-derived the
same fourteen plans at up to a second apiece; the determinism check and the calm-memory
sweeps go round the cache on purpose, since repetition is what they ask about, and the
by-role placement test keeps its own map because it repaints one. `test_crowd.gd`'s simulated
windows are sized to what they read. `test_routes.gd` keeps its twelve maps for the invariant
that is the file's reason to exist and adds a six-map `RULE_SEEDS` for the sweeps that ask
about a rule rather than a layout: determinism 12 → 4, closures landing where a wall belongs 12
→ 6 (a proportion over two hundred closures), the fallen tree's gate 12 → 4. `test_regions.gd`
adds `RULE_SEEDS` 3 of its 6 for its two fourteen-day sweeps, both of which check a
per-placement gate rather than a layout property. `test_full_run` is untouched. Each loop that
survives says in its docstring what count it needs and why.

**Item 3, the budget.** The head of `tests/run_tests.gd` now says that a suite over two minutes
serial is a suite to split or cut, tied to `tools/test.sh`'s own sharding: the longest suite
sets the floor every other shard waits on.

**Measured on CI, per suite, the `test` job of main's run on the M121 merge against the same
job on this branch's pull request:**

| suite | before | after |
|---|---|---|
| `test_events.gd` | 696.9s | 254.1s |
| `test_crowd.gd` | 492.2s | 367.7s |
| `test_routes.gd` | 378.4s | 194.2s |
| `test_generator.gd` | 344.8s | 139.7s |
| `test_regions.gd` | 201.5s | 127.1s |
| whole suite | 1,145,576 checks | 1,093,878 checks |

`test_crowd.gd` moved least because most of its cost is real simulated seconds of
`Crowd.step` rather than assertion volume. **Four suites are still over the two-minute budget
and were outside the entry's own baseline** — `test_resistance.gd`, `test_balance.gd`,
`test_seals.gd` and `test_checkpoints.gd` — and the queue entry now holds them.

**A trap found on the way, now in the godot skill.** `.slice()` on a typed `Array` drops the
element type under GDScript 4.7's static inference, so `for map in _maps.slice(...)` leaves
`map` untyped and a `:=` further down the call chain fails to parse; in a test that aborts
`_ready()` before it can quit and the runner sits printing nothing. Two such loops were already
in `test_routes.gd`. The fix is the loop variable annotated, `for map: CityMap in ...`.
