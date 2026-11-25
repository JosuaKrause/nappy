# minty-quail's end remeasure: the numbers (group N)

Measured, not judged: a number that moved is listed with its size, and nothing here says what
moved it
or whether it matters. The record `minty-quail-striped-squirrel` (`tools/decisions.sh
minty-quail-striped-squirrel`) lists what moved on purpose and what did not.

## Tree, machine, method
- **Head:** `f98443b5b19ddada1899c13c4d939d84049ea453` (origin/main when the measuring started;
  the
  two pull requests merged since, R0 and R2, change documents only). Worktree
  `.claude/worktrees/mq-r1`, `./tools/check.sh` once first (OK).
- **Before:** the columns of `docs/evidence/minty-quail-baseline-2026-11-09/` (`v0.29.0`,
  `6985ac74fd2853bffc05607c53c21ce50b69429a`; after row 4b, `b3693bee7`). Every probe here is
  deterministic for a tree, so no older tree was run again; head is run once and set beside the
  columns already measured.
- Godot 4.7.2 stable, headless debug build (`tools/test.sh` passes `--headless`), Apple M2.
  One Godot run at a time from this worktree; other agents' Godot runs were on the machine
  (one 1-minute load before each run, with the Godot processes alive, is in `raw/<run>.load`;
  the loads were 2.6 to 5.3). `raw/<run>.time` holds each run's exit code and wall time. Nothing
  here is a timing.
- Each command is `tools/test.sh <suite filter>` or `tools/test.sh probes/<name>.gd` in the
  worktree, its whole output in `raw/<run>.log` (two large ones gzipped).
- Nothing under `src/`, `tests/` or `tools/` changed. One probe copy,
  `probes/row_flags.gd`, was copied into `tests/probes/` of the worktree uncommitted to run and
  removed after (N8).

## N1 Winnability across seeds: the eight suite filters
Checks, 0 failures in every run. The counts differ by the suites' rewrites; the claim is 0
failures.

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

Head against after 4b: `test_finale` 4 fewer checks, `test_acts` 37 fewer (45 to 8),
`test_routes_closures` 2 more; the other five equal.

## N2 A zero-cost line on every route
`probes/m129_zero_cost_line.gd` (`raw/probe_m129_zero_cost_line.log`): 326.2 placed rows a day
over the 24 planned days; primary reading 299 of 299 routes (acts 1 to 4: 89, 89, 75, 46, each
all);
pacing rows over their whole beat 146 of 299 (45 of 89, 33 of 89, 44 of 75, 24 of 46). Equal to
the
after-4b column. The whole output equals `raw/probe_m129_zero_cost_line_after_4b.log` of the
baseline line for line once the runner's own lines (boot, timings) are left out.

## N3 Route costs
- `probes/polite_rabbit_wall_costs.gd`: all 184 routes, 11065 seconds; events through walls / as
  built / 16px 10296.3 / 10189.2 / 10087.4; crowd 17220.5 each; per minute walked events
  55.8 / 55.2 / 54.7, crowd 93.4; share kept events 99.0% / 98.0%. Whole output (every seed and
  day
  row) equal to the after-4b log line for line (runner lines left out). v0.29.0: 21206.0 /
  21077.4
  / 20869.7 and 17504.5.
- `probes/m117_decay.gd`: the whole output has the same lines as the after-4b log
  (`diff` of the two with the runner's own lines left out, rows sorted: no difference; the rows
  of
  its tables print in another order in several places).

## N4 The cost table
`tools/cost-table.sh --check` prints `docs/COSTS.md is up to date` (`raw/cost_table_check.log`).
`docs/COSTS.md` against `v0.29.0`: all 280 table rows have the same cells; the differences are
prose lines (where `SLEEPING_SENSITIVITY` and `WALL_WORTH_OF_COST` live, the names of the role,
speed and pursuit accessors). Against after 4b (`b3693bee7`): the same 280 rows with the same
cells
except that the `falloff_power` column of the geometry table is gone (#1718).

## N5 placement_rows.gd with tools/compare-placement-rows.py
`probes/placement_rows.gd` (18 cities from 90210 in steps of 31, days 1 to 14,
`raw/placement_rows.log`,
705.5 s) and `probes/placement_roles.gd` (`raw/placement_roles.log`).
- The role table equals the baseline's `placement_roles.log` as a set of lines (683 lines each).
- **After 4b to head:** the 952 `RD`, `RV` and `RK` lines equal the after-4b log's line for
  line. `raw/placement_comparison_after_4b_to_head.txt`: 476 cells compared, none outside 2
  sigma,
  every summary line +0%.
- **v0.29.0 to head:** `raw/placement_comparison_v0.29.0_to_head.txt`: 523 cells compared, 320
  outside
  2 sigma pooled over the 18 cities, none outside on two samples with the same sign (one sample
  here). Summary lines, events per city per day:
  - walls by view, on her route 8.61 to 13.00 (+51%), route-adjacent 27.82 to 23.89 (-14%), off
    the
    route 18.40 to 21.58 (+17%);
  - friction by view, on her route 19.69 to 6.57 (-67%), route-adjacent 6.21 to 3.35 (-46%), off
    the route 37.24 to 20.54 (-45%).
- The day's placed count and moments owed, summed over the 18 cities (`RD`), equal the after-4b
  column on every day: day 1 1620, 468; day 4 1828, 486; day 8 2269, 522; day 11 1466, 522;
  day 13 2105, 576; day 14 1835, 576 (all fourteen days are in the log).

## N6 What the placement records left for the remeasure
Each probe's whole output is in `raw/`; no older tree runs these probes.
- `probes/placement_view_mix.gd` (`raw/probe_placement_view_mix.log`, 731 s): `PV_DAY` events a
  city-day, day 1 88.9, day 7 105.3, day 9 83.1, day 11 82.0, day 13 115.4, day 14 103.2; owed
  moments 26.0 on day 1, 32.0 on day 12 to 14.
- `probes/walk_rows.gd` (`raw/probe_walk_rows.log.gz`, 2237 s): `WD` (units streamed in within
  her radius over the 18 seeds) 857, 869, 911, 1186, 1019, 953, 956, 1223, 687, 717, 643, 677,
  1030, 726 for days 1 to 14, 12454 in all; the `WV`, `WK` and `WM` lines are in the log.
- `probes/downy_llama_route_roadblocks.gd` (`raw/probe_downy_llama_route_roadblocks.log`, 776
  s),
  `RB heat day on adjacent off junction` summed over 18 cities: day 13 heat 0 `0 360 0 0`, heat
  4
  `0 361 0 0` (every one route-adjacent); on her route days 7 to 14 at heat 0: 52, 52, 43, 26,
  47, 46, 0
  (day 13), 28; at heat 4: 14, 21, 9, 6, 2, 7, 0, 6.
- `probes/placement_cells.gd` (`raw/probe_placement_cells.log`, 687 s; a first run was cut off
  by
  the harness's two-hour script limit with the file half written and is kept as
  `raw/probe_placement_cells_interrupted.log`).
- `probes/ramp_cities.gd` (`raw/probe_ramp_cities.log`, 40 s), `RAMP` day 14 over day 1 on ten
  cities: 4242 1.51 (89 to 134), 77 1.34, 1301 1.17, 90210 1.05, 90241 0.99, 90272 1.19, 90303
  1.20,
  90334 1.32, 2024 0.95, 31337 1.14. From `placement_rows.gd`'s `RD` sum: day 14 over day 1
  1835 over 1620, 1.13; days 9, 10 and 11 83.4, 82.4 and 81.4 placed a city-day against 90.0 on
  day 1.
- Events a city-day by view from `RV` (on her route / route-adjacent / off the route): day 1
  21.8 / 36.4 / 31.7, day 7 29.0 / 30.3 / 42.1, day 11 16.1 / 17.9 / 47.5, day 14 12.9 / 17.9 /
  71.1; the mean over the fourteen days 22.0 / 28.7 / 47.7.

## N7 The fourth baseline list's test counts
`test_acts` 349 to 45 to 8 and `test_finale` 9464 to 9463 to 9459: in N1.

## N8 The later days' events: how many, and how many end the day or hunt her
Input for silver-ferret's item; nothing is compared. `probes/row_flags.gd` prints for every
catalogue
row (the cold row, heat 0) `ends_the_day()`, `pursues()`, `waits_for_her()` and
`hunts_for_her()` (`raw/probe_row_flags.log`). A row counts as "ends or hunts" when any of the
four holds. Counts are `RV` rows of `placement_rows.gd` over the 18 cities, divided by 18 (the
"placed" column equals `RD` / 18). Acts are `Tuning.ACT_START_DAYS` = 1, 4, 8, 12.

| day | placed a city (RV sum) | ends the day | hunts (pursues or waits) | ends or hunts | share |
|---|---|---|---|---|---|
| 1 | 90.0 | 0.0 | 12.8 | 12.8 | 14.3% |
| 2 | 90.1 | 0.0 | 9.9 | 9.9 | 11.0% |
| 3 | 85.7 | 1.8 | 9.3 | 11.1 | 12.9% |
| 4 | 101.6 | 6.2 | 15.4 | 17.3 | 17.0% |
| 5 | 106.9 | 5.9 | 15.0 | 17.4 | 16.3% |
| 6 | 111.5 | 5.8 | 15.3 | 17.2 | 15.4% |
| 7 | 101.3 | 5.3 | 20.6 | 22.3 | 22.0% |
| 8 | 126.1 | 24.6 | 38.2 | 40.3 | 32.0% |
| 9 | 83.4 | 12.4 | 26.6 | 28.0 | 33.6% |
| 10 | 82.4 | 14.2 | 27.8 | 29.5 | 35.8% |
| 11 | 81.4 | 15.5 | 28.6 | 29.9 | 36.7% |
| 12 | 99.0 | 16.3 | 30.4 | 32.2 | 32.5% |
| 13 | 116.9 | 19.6 | 48.4 | 51.3 | 43.9% |
| 14 | 101.9 | 19.9 | 33.9 | 36.3 | 35.6% |

| act (days) | placed a city a day | ends or hunts a city a day | share |
|---|---|---|---|
| 1 (1-3) | 88.6 | 11.3 | 12.7% |
| 2 (4-7) | 105.3 | 18.5 | 17.6% |
| 3 (8-11) | 93.3 | 31.9 | 34.2% |
| 4 (12-14) | 106.0 | 40.0 | 37.7% |

Not counted here: the moments the director owes her (26.0 to 32.0 a day) and rows that gain a
hunting rung only at a higher heat.

## Not measured, listed
- **The poster tear count** (record minty-quail-29): `probes/poster_pursuer_starts.gd` (an
  existing
  probe, 40 seeds, days 4 to 14, five tears a day, `raw/probe_poster_pursuer_starts.log.gz`, 923
  s):
  2200 tears, **7 send nobody**, all on region-wall days: seed 6 day 9, and seed 10 on days 9,
  10, 11,
  12, 13 and 14 (the record's count then was 39 of 2200, 1.8%).
- **The police patrol's share** (records minty-quail-downy-toad and -jolly-toad said it would be
  fitted here): listed, not fitted. Its role is friction on every day of the role table; no fit
  was
  made. See the record.
- **The overlapping-badge still** (minty-quail-15): no harness exists; not taken.
- GoatCounter's counts, the timings and the pictures are other groups'.
