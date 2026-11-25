# minty-quail's end remeasure: the numbers (group N)

Measured, not judged: a number that moved is listed with its size, and nothing here says what moved it or whether it matters. The record `minty-quail-striped-squirrel` (`tools/decisions.sh minty-quail-striped-squirrel`) lists what moved on purpose and what did not.

## Tree, machine, method
- **Head:** `f98443b5b19ddada1899c13c4d939d84049ea453` (origin/main when the measuring started; the pull requests merged since change documents only: #1731 closes the comments and system map items, #1732 is the end remeasure's escape, run logs and GoatCounter names, #1735 its pictures and #1736 files notes). Worktree `.claude/worktrees/mq-r1`, `./tools/check.sh` once first (OK).
- **Before:** the columns of `docs/evidence/minty-quail-baseline-2026-11-09/` (`v0.29.0`, `6985ac74fd2853bffc05607c53c21ce50b69429a`; after row 4b, `b3693bee7`). Every probe here is deterministic for a tree, so no older tree was run again; head is run once and set beside the columns already measured.
- Godot 4.7.2 stable, headless debug build (`tools/test.sh` passes `--headless`), Apple M2. One Godot run at a time from this worktree; other agents' Godot runs were on the machine (one 1-minute load before each run, with the Godot processes alive, is in `raw/<run>.load`; the loads were 2.6 to 5.3). `raw/<run>.time` holds each run's exit code and wall time. Nothing here is a timing.
- Each command is `tools/test.sh <suite filter>` or `tools/test.sh probes/<name>.gd` in the worktree, its whole output in `raw/<run>.log` (two large ones gzipped).
- Nothing under `src/`, `tests/` or `tools/` changed. One probe copy, `probes/row_flags.gd`, was copied into `tests/probes/` of the worktree uncommitted to run and removed after (N8).

## N1 Winnability across seeds: the eight suite filters
Checks, 0 failures in every run. The counts differ by the suites' rewrites; the claim is 0 failures.

| filter | v0.29.0 | after 4b | head | wall |
|---|---|---|---|---|
| `test_full_run` | 16739 | 16236 | 16236 | 276.8 s |
| `test_finale` | 6026 | 9463 | 9459 | 138.7 s |
| `test_acts` | 356 | 45 | 8 | 5.6 s |
| `test_regions` | 178735 | 388618 | 388618 | 63.0 s |
| `test_seals` | 53906 | 52900 | 52900 | 118.2 s |
| `test_routes_lattice` | 19738 | 19472 | 19472 | 10.0 s |
| `test_routes_closures` | 1848 | 1850 | 1852 | 129.8 s |
| `test_balance` | 19 | 36 | 36 | 89.9 s |

Head against after 4b: `test_finale` 4 fewer checks, `test_acts` 37 fewer (45 to 8), `test_routes_closures` 2 more; the other five equal. Each of the three has a record:
- `test_acts` 45 to 8: #1645, record minty-quail-gentle-bison. The cases that built a live event, a city or a node, or planned a day, moved to the suites of the modules they test, and two checks that duplicated the stance suite's were dropped.
- `test_finale` 9463 to 9459: #1656, record minty-quail-spry-moose, 6 fewer (the far guard's posts, set-off and pacing moved to `tests/test_event_barrier_post.gd`); #1705 added one (the band is streamed out as she walks away) and #1692 one more (one check split in two). That is -6 +1 +1 = -4.
- `test_routes_closures` 1850 to 1852: #1688, record minty-quail-coral-elk (`--spawn closure` moved from the dev rig into `routes_closures_rig.gd`; `test_routes_closures_a.gd` 792 to 794).

## N2 A zero-cost line on every route
`probes/m129_zero_cost_line.gd` (`raw/probe_m129_zero_cost_line.log`): 326.2 placed rows a day over the 24 planned days; primary reading 299 of 299 routes (acts 1 to 4: 89, 89, 75, 46, each all); pacing rows over their whole beat 146 of 299 (45 of 89, 33 of 89, 44 of 75, 24 of 46). Equal to the after-4b column. The whole output equals `raw/probe_m129_zero_cost_line_after_4b.log` of the baseline line for line once the runner's own lines (boot, timings) are left out.

## N3 Route costs
- `probes/polite_rabbit_wall_costs.gd`: all 184 routes, 11065 seconds; events through walls / as built / 16px 10296.3 / 10189.2 / 10087.4; crowd 17220.5 each; per minute walked events 55.8 / 55.2 / 54.7, crowd 93.4; share kept events 99.0% / 98.0%. Whole output (every seed and day row) equal to the after-4b log line for line (runner lines left out). v0.29.0: 21206.0 / 21077.4 / 20869.7 and 17504.5.
- `probes/m117_decay.gd`: the whole output has the same lines as the after-4b log (`diff` of the two with the runner's own lines left out, rows sorted: no difference; the rows of its tables print in another order in several places).

## N4 The cost table
`tools/cost-table.sh --check` prints `docs/COSTS.md is up to date` (`raw/cost_table_check.log`). `docs/COSTS.md` against `v0.29.0`: all 280 table rows have the same cells; the differences are prose lines (where `SLEEPING_SENSITIVITY` and `WALL_WORTH_OF_COST` live, the names of the role, speed and pursuit accessors). Against after 4b (`b3693bee7`): the same 280 rows with the same cells except that the `falloff_power` column of the geometry table is gone (#1718).

## N5 placement_rows.gd with tools/compare-placement-rows.py
`probes/placement_rows.gd` (18 cities from 90210 in steps of 31, days 1 to 14, `raw/placement_rows.log`, 705.5 s) and `probes/placement_roles.gd` (`raw/placement_roles.log`).
- The role table equals the baseline's `placement_roles.log` as a set of lines (683 lines each).
- **After 4b to head:** the 952 `RD`, `RV` and `RK` lines equal the after-4b log's line for line. `raw/placement_comparison_after_4b_to_head.txt`: 476 cells compared, none outside 2 sigma, every summary line +0%.
- **v0.29.0 to head:** `raw/placement_comparison_v0.29.0_to_head.txt`: 523 cells compared, 320 outside 2 sigma pooled over the 18 cities, none outside on two samples with the same sign (one sample here). Summary lines, events per city per day:
  - walls by view, on her route 8.61 to 13.00 (+51%), route-adjacent 27.82 to 23.89 (-14%), off the route 18.40 to 21.58 (+17%);
  - friction by view, on her route 19.69 to 6.57 (-67%), route-adjacent 6.21 to 3.35 (-46%), off the route 37.24 to 20.54 (-45%).
- The day's placed count and moments owed, summed over the 18 cities (`RD`), equal the after-4b column on every day: day 1 1620, 468; day 4 1828, 486; day 8 2269, 522; day 11 1466, 522; day 13 2105, 576; day 14 1835, 576 (all fourteen days are in the log).

## N6 What the placement records left for the remeasure
Each probe's whole output is in `raw/`; no older tree runs these probes.
- `probes/placement_view_mix.gd` (`raw/probe_placement_view_mix.log`, 731 s): `PV_DAY` events a city-day, day 1 88.9, day 7 105.3, day 9 83.1, day 11 82.0, day 13 115.4, day 14 103.2; owed moments 26.0 on day 1, 32.0 on day 12 to 14.
- `probes/walk_rows.gd` (`raw/probe_walk_rows.log.gz`, 2237 s): `WD` (units streamed in within her radius over the 18 seeds) 857, 869, 911, 1186, 1019, 953, 956, 1223, 687, 717, 643, 677, 1030, 726 for days 1 to 14, 12454 in all; the `WV`, `WK` and `WM` lines are in the log.
- `probes/downy_llama_route_roadblocks.gd` (`raw/probe_downy_llama_route_roadblocks.log`, 776 s), `RB heat day on adjacent off junction` summed over 18 cities: day 13 heat 0 `0 360 0 0`, heat 4 `0 361 0 0` (every one route-adjacent); on her route days 7 to 14 at heat 0: 52, 52, 43, 26, 47, 46, 0 (day 13), 28; at heat 4: 14, 21, 9, 6, 2, 7, 0, 6.
- `probes/placement_cells.gd` (`raw/probe_placement_cells.log`, 687 s; a first run was cut off by the harness's two-hour script limit with the file half written and is kept as `raw/probe_placement_cells_interrupted.log`). Read with the declared table's own script, `python3 -I compare_cells.py seed_main_1109.txt raw/probe_placement_cells.log` (the script and the seed tree's `seed_main_1109.txt` are in `docs/evidence/polite-tapir-declared-table-2026-11-16/`), events per hundred draw locations, seed tree to head: on her route 6.69 to 5.80 (x0.87, as in polite-tapir-coral-owl's acceptance run), route-adjacent x1.02, off the route x0.96, 94.2 events a city-day against the seed tree's 99.2; her route's junction boxes x0.77 and open ground x0.50. Per day, events a city, seed tree to head: day 7 111.1 to 97.8 (x0.88), day 10 88.3 to 78.1 (x0.88), day 11 96.5 to 78.6 (x0.81, the record's "a fifth under", same measure and same figure), days 9 to 11 80.6, 78.1 and 78.6 against 87.6 on day 1. The 81.4 against 90.0 of the line below is another measure (the placed count of `placement_rows.gd`, day 11 over day 1, about 10% under) and answers a different question.
- `probes/ramp_cities.gd` (`raw/probe_ramp_cities.log`, 40 s), `RAMP` day 14 over day 1 on ten cities: 4242 1.51 (89 to 134), 77 1.34, 1301 1.17, 90210 1.05, 90241 0.99, 90272 1.19, 90303 1.20, 90334 1.32, 2024 0.95, 31337 1.14. From `placement_rows.gd`'s `RD` sum: day 14 over day 1 1835 over 1620, 1.13; days 9, 10 and 11 83.4, 82.4 and 81.4 placed a city-day against 90.0 on day 1.
- Events a city-day by view from `RV` (on her route / route-adjacent / off the route): day 1 21.8 / 36.4 / 31.7, day 7 29.0 / 30.3 / 42.1, day 11 16.1 / 17.9 / 47.5, day 14 12.9 / 17.9 / 71.1; the mean over the fourteen days 22.0 / 28.7 / 47.7.

## N7 The fourth baseline list's test counts
`test_acts` 349 to 45 to 8 and `test_finale` 9464 to 9463 to 9459: in N1.

## N8 The later days' events: how many, and how many end the day or hunt her
Input for silver-ferret's item; nothing is compared. `probes/row_flags.gd` prints for every catalogue row `ends_the_day()`, `pursues()`, `waits_for_her()` and `hunts_for_her()` (`raw/probe_row_flags.log`). The four mean different things, and only three of them are a row that ends her day or hunts her:
- `ends_the_day()`: walking into its reach ends the day. Every row that `pursues()` (comes after her) also ends the day, so the two make one column, "ends the day or pursues".
- `hunts_for_her()`: whether, at the heat that hunts, the row stops being a place and becomes a hunter (the lethal rung): `roadblock`, `abduction` and `night_raid`. It is true at every heat. Cold, they have not reached that rung (a `roadblock` is only a barrier), so a `roadblock` and a `night_raid` are counted in their own column, "with the lethal rung at heat", which reads as what the days hold if her heat has reached the rung that hunts. `abduction` ends the day cold already.
- `waits_for_her()`: a place that starts its telegraph when she comes close. It is not a hunter and is not counted: it holds `pigeon_flock` and `alley_mouse`, besides `masked_pursuer` and `alley_robbery`, which end the day and are counted by `ends_the_day()`. The last column counts the rows that only wait.

Counts are `RV` rows of `placement_rows.gd` over the 18 cities, divided by 18 (the "placed" column equals `RD` / 18). The heat a player has on a given day depends on what she did, and this log holds no heat, so the two shares are the floor and the ceiling of what the day holds. Acts are `Tuning.ACT_START_DAYS` = 1, 4, 8, 12.

| day | placed a city (RV sum) | ends the day or pursues | with the lethal rung at heat | share, cold | share, with the rung | only waits for her (not counted) |
|---|---|---|---|---|---|---|
| 1 | 90.0 | 0.0 | 0.0 | 0.0% | 0.0% | 12.8 |
| 2 | 90.1 | 0.0 | 0.0 | 0.0% | 0.0% | 9.9 |
| 3 | 85.7 | 1.8 | 1.8 | 2.1% | 2.1% | 9.3 |
| 4 | 101.6 | 6.2 | 6.2 | 6.1% | 6.1% | 11.1 |
| 5 | 106.9 | 5.9 | 5.9 | 5.6% | 5.6% | 11.4 |
| 6 | 111.5 | 5.8 | 5.8 | 5.2% | 5.2% | 11.4 |
| 7 | 101.3 | 5.3 | 10.1 | 5.3% | 9.9% | 12.2 |
| 8 | 126.1 | 24.6 | 30.0 | 19.5% | 23.8% | 10.3 |
| 9 | 83.4 | 12.4 | 18.2 | 14.9% | 21.9% | 9.8 |
| 10 | 82.4 | 14.2 | 19.1 | 17.3% | 23.1% | 10.4 |
| 11 | 81.4 | 15.5 | 20.3 | 19.0% | 25.0% | 9.6 |
| 12 | 99.0 | 16.3 | 21.8 | 16.5% | 22.0% | 10.4 |
| 13 | 116.9 | 19.6 | 39.6 | 16.8% | 33.9% | 11.7 |
| 14 | 101.9 | 19.9 | 24.9 | 19.5% | 24.4% | 11.4 |

| act (days) | placed a city a day | ends the day or pursues a city a day | with the lethal rung at heat | share, cold | share, with the rung |
|---|---|---|---|---|---|
| 1 (1-3) | 88.6 | 0.6 | 0.6 | 0.7% | 0.7% |
| 2 (4-7) | 105.3 | 5.8 | 7.0 | 5.5% | 6.6% |
| 3 (8-11) | 93.3 | 16.7 | 21.9 | 17.9% | 23.5% |
| 4 (12-14) | 106.0 | 18.6 | 28.8 | 17.6% | 27.1% |

Not counted here: the moments the director owes her (26.0 to 32.0 a day), the pressing rung of a row that answers to heat (more of them, more expensive to stand near, never ends the day), and the rows that only wait for her.

## The poster tear count (record minty-quail-29)
`probes/poster_pursuer_starts.gd` (the probe #886 added with that record, on the same 40 seeds, days 4 to 14, five tears a day, `raw/probe_poster_pursuer_starts.log.gz`, 923 s): 2200 tears, **7 send nobody**, all on region-wall days: seed 6 day 9, and seed 10 on days 9, 10, 11, 12, 13 and 14. The record's count was 39 of 2200 (1.8%). No record names what moved it; it is unexplained and listed.

## Listed, not fitted, not taken
- **The police patrol's share** (records minty-quail-downy-toad and -jolly-toad said it would be fitted here): listed, not fitted. Its role is friction on every day of the role table; no fit was made. See the record.
- **The overlapping-badge still** (minty-quail-15): no harness exists; not taken.
- GoatCounter's counts, the timings and the pictures are other groups' (the pictures are #1735).
