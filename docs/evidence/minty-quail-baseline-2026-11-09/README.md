# The numbers from before the refactor and from today's main (minty-quail, the baseline measurements)

Measured, not judged: a difference is listed with its size and nothing says what moved it or whether it matters.

## The two trees, the machine
- **Before:** tag `v0.29.0`, commit `6985ac74fd2853bffc05607c53c21ce50b69429a`, scratch worktree made with `tools/agent-setup.sh --detach v0.29.0 baseline-before`.
- **Today:** `origin/main` at `38ce038231009ae8a4d08284e6bad9dda4b035c2`, `tools/agent-setup.sh --detach origin/main baseline-today`.
- **Placement closed:** `4da1e52854825c589efe19bacc8cb77556d41eb8`, the merge of #1548, which closed placement. Its tree is made with `tools/agent-setup.sh --detach 4da1e52854825c589efe19bacc8cb77556d41eb8 baseline-run`, and `./tools/check.sh` ran once in it (OK). A second tree of the same commit, `baseline-run2` (same command, removed after), ran the dawn planning probe and the frame profile of the placement closed column that did not come out in the first (`baseline-run`: dawn parse failure; frame runs rejected); `./tools/check.sh` ran once in it too (OK). Both trees were removed with `tools/agent-setup.sh --remove`. The same Godot 4.7.2 headless debug build on the same machine. The load average before each run is in the `.load` file beside that run's raw output.
- **After row 4b:** `origin/main` at `b3693bee7` (#1634, "The live event is handed its behaviours (minty-quail row 4b)"; row 4b's twelve pull requests have merged). Run in the worktree `.claude/worktrees/baseline-4b` (a sparse checkout of that commit made by `tools/agent-setup.sh`), with the same Godot 4.7.2 headless debug build on the same Apple M2. `./tools/check.sh` ran once first (OK). One driver script ran every measurement once, one at a time, in the order of the rest of this file, noting `uptime` before each (`.load` files). The load stayed between 1.9 and 3.6 (1 minute) before every run; another agent's Godot probe (`amber-dolphin`'s worktree) ran alongside part of it.
- `./tools/check.sh` ran once in each first (both OK). Godot 4.7.2 stable, headless debug build (`tools/test.sh` and `tools/check.sh` pass `--headless`), Apple M2, macOS. Other agents ran Godot on the machine throughout; the load average (1, 5, 15 minute) before each run is recorded below and in `raw/**/*.load` and `raw/timed/loads.txt`. Load was above 50 at the start of one run (noted where it applies), about 3 to 10 for most timed runs.
- Every run: `tools/test.sh <name>` in the scratch tree (it passes `--headless`), or the Godot command shown. No run touches the save (probes and suites do not write it).
- The old tree's tests directory has the probes of its own time; where a probe of the same name exists on both trees, each tree ran its own copy (the copies differ, see "Probes" below). Nothing was edited in place; copies made for this folder are under `probes/` and were copied into the scratch trees (uncommitted there) to run.

## Probes
| Probe | v0.29.0 | today | note | placement closed (4da1e5285) | after 4b (b3693bee7) |
|---|---|---|---|---|---|
| `tests/probes/placement_rows.gd` | absent | present | `probes/placement_rows_v0.29.0.gd` is a cut-down counterpart (see its header): no `DaySpec`, no guarded-row argument, `build_day(day, rng, map, consumed, [], [], tree, 0, doors, [], standing)`; no `Corridor.view_of()`, so the view is that function's rule written out from `Corridor.depth()` and `Corridor.route_junctions()`; `StreetNetwork` is static; same cities (18 from 90210 step 31), same RNG seed strings, same `RD`/`RV`/`RK` lines. Seals do not get `stand_as_a_seal()`, wall bodies not `stand_in_the_wall()` (no such calls there). | the tree's own copy, run | the tree's own copy, run |
| `probes/placement_roles.gd` | not run | run once | prints `ROLE day row role` from `EventScheduler.role_for()` on today's tree; v0.29.0 has no `role_for()`, so the one table feeds the comparison of both trees. | the tree's own copy, run once | the tree's own copy, run once |
| `m129_zero_cost_line`, `m117_decay`, `polite_rabbit_wall_costs`, `m159_crowd_tick_cost`, `entity_frame_profile` (+ observer, analyzer) | own copy | own copy | present in both, run unchanged; they differ between the trees by the API of their time (line diffs: m129 123, m117 59, polite 46, m159 77, observer 6; the analyzer and `entity_frame_profile.gd` are identical). `m159_crowd_tick_cost`'s columns differ: on v0.29.0 `agents` (`CrowdAgent._process()` per agent) and `tick` are timed apart, on today's tree the agents' steps run inside `tick`. | own copy, run unchanged; `entity_frame_profile.gd` (the launcher) as the copy `probes/entity_frame_profile_placement_closed.gd` with `--invincible` added to the game's flags (see "Placement closed (4da1e5285)" below); the observer and the analyzer unchanged | own copy, run unchanged; `entity_frame_profile.gd` (the launcher) run unmodified (the analyzer rejected all six runs) and as the copy `probes/entity_frame_profile_after_4b.gd` with `--invincible`, as in the placement closed column (see "After row 4b (b3693bee7)" below); the observer and the analyzer unchanged |
| `probes/dawn_planning_time_*.gd` | copy of the v0.29.0 counterpart | copy of today's `placement_rows.gd` | 14 cities, a timer around the one `EventScheduler.build_day()` call per city and day; see headers. | `probes/dawn_planning_time_placement_closed.gd`, a copy for this tree (see its header): the copy `dawn_planning_time_today.gd` does not parse at 4da1e5285 (`EventScheduler.build_day()` takes a `DawnContext` and `EventScheduler.Planned` is `EventPlan`), so the tree's own `placement_rows.gd` is the base, with 14 cities, `build_day(dawn)` timed, and `GameDawn.draw_every_unit(dawn)` timed apart (the dawn no longer draws the units; each draws as she comes near it). Ran 3 times | `probes/dawn_planning_time_after_4b.gd`, a copy for this tree made from the tree's own `placement_rows.gd` the way the placement closed copy was (see its header); `dawn_planning_time_placement_closed.gd` was not tried again, since the tree's probe changed its calls. Ran 3 times |
| `escape_winnable.gd` | absent | present | not run on either tree (see "Not measured"). | not run | not run |
| `minty_quail_lane_parity.gd` (minty-quail-16's probe) | absent | present | not run on either tree; `m159_crowd_tick_cost.gd` is used instead, as the brief says. | not run | not run |

Comparison script: `placement-remeasure-script.original.py` is the script from the brief, unchanged (provenance). `compare_placement.py` is it with the sample paths pointed at `raw/`, one sample ("90210+31i", 18 cities, before as the script's "main" and today as its "head"), and its editorial passages (the "changed on purpose" list, "what the probe cannot see", the two notes) removed. `summarize_timed.py` computes the tables of measurements 4 and 5.

## 1. Winnability across seeds and days
The suites that ask whether the days hold together and can be won, each run by name filter (`tools/test.sh <name>`, which matches the suite files `test_x.gd` and its split `test_x_a/_b/_c.gd`). Seeds are the ones the suites use (full run: 4242, 90210, 1234567 on v0.29.0, the same plus the shards of today's split; finale: its rig's own). Counts, run once. Load is the 1-minute average before the run.

| Suite filter | before | today | placement closed (4da1e5285) | after 4b (b3693bee7) |
|---|---|---|---|---|
| `test_full_run*` | 16739 checks, 0 failures (load 28.66) | 16537 checks, 0 failures (load 6.68) | 16236 checks, 0 failures (load 31.19) | 16236 checks, 0 failures (load 2.33) |
| `test_finale*` | 6026 checks, 0 failures (load 11.27) | 9501 checks, 0 failures (load 7.72) | 9464 checks, 0 failures (load 3.69) | 9463 checks, 0 failures (load 3.14) |
| `test_acts*` | 356 checks, 0 failures (load 16.42) | 349 checks, 0 failures (load 5.47) | 349 checks, 0 failures (load 11.61) | 45 checks, 0 failures (load 3.46) |
| `test_regions*` | 178735 checks, 0 failures (load 13.95) | 388618 checks, 0 failures (load 7.80) | 388618 checks, 0 failures (load 9.55) | 388618 checks, 0 failures (load 3.49) |
| `test_seals*` | 53906 checks, 0 failures (load 8.39) | 52814 checks, 0 failures (load 22.16) | 52900 checks, 0 failures (load 17.52) | 52900 checks, 0 failures (load 3.62) |
| `test_routes_lattice*` | 19738 checks, 0 failures (load 5.65) | 19472 checks, 0 failures (load 20.06) | 19472 checks, 0 failures (load 20.81) | 19472 checks, 0 failures (load 3.14) |
| `test_routes_closures*` | 1848 checks, 0 failures (load 5.52) | 1850 checks, 0 failures (load 20.10) | 1850 checks, 0 failures (load 18.31) | 1850 checks, 0 failures (load 2.96) |
| `test_balance*` | 19 checks, 0 failures (load 5.77) | 36 checks, 0 failures (load 8.00) | 36 checks, 0 failures (load 6.26) | 36 checks, 0 failures (load 2.72) |

Check counts differ between the trees because the suites were rewritten and split between them; every run says 0 failures. `m129_zero_cost_line` (does a zero-cost line exist along every route the day plans; 6 seeds, one day per act 1, 5, 9, 13), as printed:

| | before | today | placement closed (4da1e5285) | after 4b (b3693bee7) |
|---|---|---|---|---|
| placed rows a day a line has to avoid | 326.6 | 310.4 | 326.2 | 326.2 |
| routes with a zero-cost line, primary reading, act 1 | 69 of 89 (77.5%) | 77 of 89 (86.5%) | 89 of 89 (100.0%) | 89 of 89 (100.0%) |
| act 2 | 72 of 89 (80.9%) | 80 of 89 (89.9%) | 89 of 89 (100.0%) | 89 of 89 (100.0%) |
| act 3 | 61 of 75 (81.3%) | 70 of 75 (93.3%) | 75 of 75 (100.0%) | 75 of 75 (100.0%) |
| act 4 | 45 of 46 (97.8%) | 46 of 46 (100.0%) | 46 of 46 (100.0%) | 46 of 46 (100.0%) |
| all | 247 of 299 (82.6%) | 273 of 299 (91.3%) | 299 of 299 (100.0%) | 299 of 299 (100.0%) |
| pacing rows over their whole beat, all | 120 of 299 (40.1%) | 154 of 299 (51.5%) | 146 of 299 (48.8%) | 146 of 299 (48.8%) |

The full output, with the shapes of what broke the line, is `raw/probe_m129_zero_cost_line_{before,today}.log`. The escape's own winnability probe (`escape_winnable.gd`) is not run, see below.

## 2. What a route costs to walk
- `tools/cost-table.sh --check`: "docs/COSTS.md is up to date" on both trees (`raw/cost_table_check_*.log`). The two checked-in `COSTS.md` files (`raw/COSTS_before.md`, `raw/COSTS_today.md`) differ only in the prose lines listed in `raw/COSTS_diff.txt` (names of where two constants live and `_role_for` / `role_for`); no table number differs.
- placement closed (4da1e5285): `tools/cost-table.sh --check` printed `docs/COSTS.md is up to date` (`raw/cost_table_check_placement_closed.log`).
- `polite_rabbit_wall_costs` (gross points over the day's routes, 3 seeds x days 1, 5, 9, 13; columns events: through walls / as built / 16px everywhere; crowd likewise), summary rows as printed:

| | before | today | placement closed (4da1e5285) | after 4b (b3693bee7) |
|---|---|---|---|---|
| all, routes / seconds | 184 / 11065 | 184 / 11065 | 184 / 11065 | 184 / 11065 |
| events through walls / as built / 16px | 21206.0 / 21077.4 / 20869.7 | 16821.4 / 16732.5 / 16588.8 | 10296.3 / 10189.2 / 10087.4 | 10296.3 / 10189.2 / 10087.4 |
| crowd (through walls / as built / 16px) | 17504.5 each | 17170.0 each | 17220.5 each | 17220.5 each |
| per minute walked, events | 115.0 / 114.3 / 113.2 | 91.2 / 90.7 / 89.9 | 55.8 / 55.2 / 54.7 | 55.8 / 55.2 / 54.7 |
| per minute walked, crowd | 94.9 | 93.1 | 93.4 | 93.4 |
| share kept, events | 99.4% / 98.4% | 99.5% / 98.6% | 99.0% / 98.0% | 99.0% / 98.0% |

(The per-seed and per-day rows of both trees are in the two raw files, `raw/probe_polite_rabbit_wall_costs_{before,today}.log`; their routes and seconds columns are equal row by row.)
- `m117_decay` (the net meter rate per kind of ground, walked): `raw/probe_m117_decay_{before,today}.log`, whole tables, not reduced here.
- after 4b (b3693bee7): `tools/cost-table.sh --check` printed `docs/COSTS.md is up to date` (`raw/cost_table_check_after_4b.log`). `polite_rabbit_wall_costs` printed the same summary rows as the placement closed column (the column above, `raw/probe_polite_rabbit_wall_costs_after_4b.log`); its per-seed and per-day rows, and the whole output of `m117_decay` (`raw/probe_m117_decay_after_4b.log`) and of `m129_zero_cost_line` (`raw/probe_m129_zero_cost_line_after_4b.log`), equal the placement closed logs line for line once the runner's own lines (boot, timings) are left out.
- placement closed (4da1e5285): the whole output, `raw/probe_m117_decay_placement_closed.log`, not reduced here.

## 3. How many of each event row a city holds a day, by view
`placement_rows` on today's tree, `probes/placement_rows_v0.29.0.gd` on v0.29.0; 18 cities from seed 90210 in steps of 31 (sample "90210+31i"), days 1 to 14, run once each. Logs: `raw/placement_rows_{before,today}.log` (RD / RV / RK lines, summed over the 18 cities), compared by `compare_placement.py` into `raw/placement_comparison.txt` (all 264 lines). The whole day's count per 18 cities, from the `RD` lines (placed, then moments she is owed):

| day | before placed, moments | today placed, moments | placement closed placed, moments | after 4b placed, moments |
|---|---|---|---|---|
| 1 | 1819, 418 | 1593, 414 | 1620, 468 | 1620, 468 |
| 2 | 1864, 469 | 1629, 468 | 1622, 468 | 1622, 468 |
| 3 | 1865, 527 | 1666, 522 | 1542, 469 | 1542, 469 |
| 4 | 2105, 445 | 1711, 450 | 1828, 486 | 1828, 486 |
| 5 | 2317, 462 | 1900, 468 | 1924, 486 | 1924, 486 |
| 6 | 2533, 497 | 2126, 504 | 2007, 486 | 2007, 486 |
| 7 | 2544, 517 | 2048, 522 | 1824, 486 | 1824, 486 |
| 8 | 2682, 507 | 2196, 504 | 2269, 522 | 2269, 522 |
| 9 | 2073, 501 | 1574, 504 | 1501, 522 | 1501, 522 |
| 10 | 2167, 534 | 1662, 540 | 1483, 522 | 1483, 522 |
| 11 | 2221, 560 | 1752, 558 | 1466, 522 | 1466, 522 |
| 12 | 2342, 567 | 1834, 576 | 1782, 576 | 1782, 576 |
| 13 | 2412, 571 | 2218, 576 | 2105, 576 | 2105, 576 |
| 14 | 2495, 579 | 1992, 576 | 1835, 576 | 1835, 576 |

Summary lines of the script, as printed (events per city per day, before to today, z with sigma = sqrt(before + today)):
```
over all 18 cities:
- walls by view, on her route: 8.61 → 6.15 (-29%, z -10.2)
- walls by view, route-adjacent: 27.82 → 19.62 (-29%, z -18.9)
- walls by view, off the route: 18.40 → 13.81 (-25%, z -12.8)
- friction by view, on her route: 19.69 → 17.36 (-12%, z -6.1)
- friction by view, route-adjacent: 6.21 → 7.33 (+18%, z +4.8)
- friction by view, off the route: 37.24 → 31.93 (-14%, z -10.1)
- each row per kind of ground: 48 cells, every cell main or head has, from -68% (homeless_yeller open) to +inf% (alley_mouse junction); within 2σ, from -67% to +inf%
- each row per view: 65 cells, every cell main or head has, from -100% (alley_robbery route-adjacent) to +200% (poster_crew_square route-adjacent); within 2σ, from -100% to +200%
```
Notes on this table: the "z" values are the script's, from one sample (the script's pooled and repeated-sample lists reduce to one list); the role table (walls / friction) is today's for both trees; the old tree's moments column is a count of rows sited in front of her, today's likewise. The v0.29.0 probe's closure, seal and wall rngs use the same seed strings as today's but reach different planners, so the cities' closures are not the same closures.

The placement closed column of the day table is summed from the `RD` lines of `raw/placement_rows_placement_closed.log`, over the same 18 cities as the other two. `compare_placement.py` was not run on it: its samples are named in its own code (`raw/placement_rows_before.log` and `raw/placement_rows_today.log`), so a third sample needs a code change. Its `placement_roles` run is `raw/placement_roles_placement_closed.log`.

After row 4b (b3693bee7) the column is summed from the `RD` lines of `raw/placement_rows_after_4b.log` over the same 18 cities and equals the placement closed column on every day. `tools/compare-placement-rows.py` (now in `tools/`, which reads the same `RD` / `RV` / `RK` lines) was run on the new log with the role table of the first reading (`raw/placement_roles.log`; the tree's own `placement_roles` run, `raw/placement_roles_after_4b.log`, prints the same table):
- placement closed (4da1e5285) to after 4b: `raw/placement_comparison_placement_closed_to_after_4b.txt`: 476 cells compared, none outside 2 sigma, every summary line +0%.
- before (v0.29.0) to after 4b: `raw/placement_comparison_before_to_after_4b.txt` (the tool's output for the first sample, with its (b) list of every cell outside 2 sigma pooled over the 18 cities; its role table is today's for both, as in the first reading). Its summary lines compare the old tree with the one that has placement closed, and are not reduced here.


## 4 and 5. Timed measurements
Trees alternate run by run: before, today, before, today, ... three pairs each, one after another (`$TMPDIR` script, commands below). Load average before each run:

```
dawn before 1 load 4.96 15.31 15.36
dawn today 1 load 5.30 8.01 11.76
dawn before 2 load 3.68 5.14 8.93
dawn today 2 load 4.18 4.42 7.44
dawn before 3 load 55.38 29.93 17.43
dawn today 3 load 6.18 14.83 15.28
crowdtick before 1 load 6.15 7.44 10.92
crowdtick today 1 load 4.51 6.46 9.91
crowdtick before 2 load 2.86 4.97 8.72
crowdtick today 2 load 4.13 4.72 8.01
crowdtick before 3 load 9.51 6.73 7.83
crowdtick today 3 load 7.08 7.45 7.90
frame-profiled before 1 load 10.03 10.18 9.02
frame-profiled today 1 load 9.13 9.96 8.97
frame-profiled before 2 load 8.76 9.82 8.95
frame-profiled today 2 load 9.80 9.97 9.02
frame-profiled before 3 load 8.97 9.77 8.98
frame-profiled today 3 load 8.68 9.65 8.95
frame-disabled before 1 load 8.11 9.44 8.90
frame-disabled today 1 load 7.35 9.18 8.81
frame-disabled before 2 load 7.53 9.09 8.79
frame-disabled today 2 load 8.65 9.20 8.83
frame-disabled before 3 load 7.85 8.99 8.77
frame-disabled today 3 load 8.83 9.11 8.81
```
Dawn run 3 of the old tree started at load 55.4 (1 minute), the highest of the batch; runs 1 and 2 of that tree started below 5.

Commands (each in the tree's own directory):
- dawn: `tools/test.sh probes/dawn_planning_time.gd`, 14 cities x 14 days, printing `DAWN_PLANNING build_day_sec ... whole_probe_sec ...` (raw `raw/timed/dawn_*`).
- crowd tick: `tools/test.sh probes/m159_crowd_tick_cost.gd` (2 seeds x days 1, 9, 14 x 2 walks x 3 repetitions, whole and split modes, 150 warmup then 600 timed ticks per case); one `CROWD_TICK_JSON` line per case and run (raw `raw/timed/crowdtick_*`, every line whole: its `chain` (the hash of the whole window) and `chain_every_150_ticks` fields are kept, in the first reading's files and in the placement closed ones).
- placement closed, dawn: `tools/test.sh probes/dawn_planning_time_placement_closed.gd` in `baseline-run2`, three runs one after another, printing `DAWN_PLANNING build_day_sec ... draw_every_unit_sec ... whole_probe_sec ...` (raw `raw/timed/dawn_placement_closed_run2_*`).
- frame profile: `ENTITY_PROFILE_OUTPUT=<prefix> [ENTITY_PROFILE_DISABLED=1] /Applications/Godot.app/Contents/MacOS/Godot --headless --path <tree> --script tests/probes/entity_frame_profile.gd`, then `python3 -I <tree>/tests/probes/entity_frame_profile_analyze.py <prefix> [--profiler-disabled] --output <prefix>-summary.json` (the analyzer accepted every run). Seed 4242, day 1, arterial spawn, walking north. Summaries are kept gzipped.

`python3 -I summarize_timed.py` prints (kept as `raw/timed_tables.txt`):

```
== 4. dawn planning: seconds inside build_day(), 14 cities x 14 days, per run n=1..3
before build_day [202.553, 177.92, 284.563] median 202.6 (min 177.9, max 284.6) | whole probe [333.633, 293.008, 479.616] median 333.6 (min 293.0, max 479.6)
today build_day [256.185, 403.001, 340.105] median 340.1 (min 256.2, max 403.0) | whole probe [390.513, 598.831, 516.773] median 516.8 (min 390.5, max 598.8)
placement closed build_day [52.917, 51.618, 45.807] median 51.6 (min 45.8, max 52.9) | draw_every_unit [370.179, 345.616, 285.488] median 345.6 (min 285.5, max 370.2) | the two added [423.096, 397.234, 331.295] median 397.2 (min 331.3, max 423.1) | whole probe [604.191, 568.582, 474.322] median 568.6 (min 474.3, max 604.2)
after 4b build_day [44.143, 44.338, 43.721] median 44.1 (min 43.7, max 44.3) | draw_every_unit [332.253, 342.338, 334.332] median 334.3 (min 332.3, max 342.3) | the two added [376.396, 386.676, 378.053] median 378.1 (min 376.4, max 386.7) | whole probe [502.531, 516.41, 505.215] median 505.2 (min 502.5, max 516.4)
== 5a. crowd tick, mean over the 36 cases of the case's median per-tick microseconds, per run
before cases/run 36 | tick column [371, 347, 629] median 370.5 (min 346.8, max 629.3) | agents' own frames column [1675, 1448, 2797] median 1675.4 (min 1448.2, max 2797.1) | agents + tick median 2046.0 (min 1795.0, max 3426.4)
today cases/run 36 | tick column [2086, 3945, 4860] median 3944.7 (min 2085.6, max 4859.8) | agents' own frames column [0, 0, 0] (inside tick) | agents + tick median 3944.7 (min 2085.6, max 4859.8)
placement_closed cases/run 36 | tick column [2467, 2506, 2212] median 2466.6 (min 2211.8, max 2505.7) | agents' own frames column [0, 0, 0] (inside tick) | agents + tick median 2466.6 (min 2211.8, max 2505.7)
after_4b cases/run 36 | tick column [2481, 2341, 2351] median 2350.6 (min 2341.2, max 2481.0) | agents' own frames column [0, 0, 0] (inside tick) | agents + tick median 2350.6 (min 2341.2, max 2481.0)
== 5b. per-system frame profile (entity_frame_profile.gd, seed 4242 day 1, ms), per run
profiled before callback interval median ms [19.209, 15.546, 12.076] median 15.5 (min 12.1, max 19.2) | main-loop wall median ms median 14.9 (min 11.6, max 18.4) | script self sum median ms median 8.9 (min 6.8, max 10.9) | analyzer accepted [True, True, True]
profiled today callback interval median ms [29.13, 28.753, 5.325] median 28.8 (min 5.3, max 29.1) | main-loop wall median ms median 27.6 (min 4.5, max 28.0) | script self sum median ms median 15.9 (min 2.8, max 16.2) | analyzer accepted [True, True, True]
profiled placement closed (--invincible) callback interval median ms [4.647, 5.699, 4.888] median 4.9 (min 4.6, max 5.7) | main-loop wall median ms median 2.3 (min 2.3, max 2.3) | script self sum median ms median 1.3 (min 1.3, max 1.3) | analyzer accepted [True, True, True]
profiled after 4b (launcher unmodified) callback interval median ms [8.308, 8.28, 8.316] median 8.3 (min 8.3, max 8.3) | main-loop wall median ms median 0.5 (min 0.5, max 0.5) | script self sum median ms median 0.3 (min 0.3, max 0.3) | analyzer accepted [False, False, False]
profiled after 4b (--invincible) callback interval median ms [4.333, 3.91, 3.958] median 4.0 (min 3.9, max 4.3) | main-loop wall median ms median 2.5 (min 2.5, max 2.6) | script self sum median ms median 1.4 (min 1.3, max 1.4) | analyzer accepted [True, True, True]
disabled before callback interval median ms [10.668, 8.154, 11.763] median 10.7 (min 8.2, max 11.8)  | analyzer accepted [True, True, True]
disabled today callback interval median ms [6.309, 4.22, 4.683] median 4.7 (min 4.2, max 6.3)  | analyzer accepted [True, True, True]
disabled placement closed (--invincible) callback interval median ms [6.998, 7.53, 7.468] median 7.5 (min 7.0, max 7.5)  | analyzer accepted [True, True, True]
disabled after 4b (launcher unmodified) callback interval median ms [8.333, 8.332, 8.329] median 8.3 (min 8.3, max 8.3)  | analyzer accepted [False, False, False]
disabled after 4b (--invincible) callback interval median ms [6.074, 6.703, 6.306] median 6.3 (min 6.1, max 6.7)  | analyzer accepted [True, True, True]
```
Reading the figures as measurements and nothing more: the crowd tick's three runs on today's tree span 2086 to 4860 microseconds and the old tree's agents + tick span 1795 to 3426, so the two trees' ranges overlap and the difference between their medians is inside the spread; the dawn's build_day ranges overlap likewise (before 177.9 to 284.6 s, today 256.2 to 403.0 s; the two trees' runs 1 and 2 alone do not overlap: 177.9 and 202.6 against 256.2 and 403.0); the profiled frame figures of today's tree run from 4.5 to 28.0 ms per run, which is a spread wider than any difference to the old tree's 11.6 to 18.4 ms; with the profiler disabled, the callback interval's medians do not overlap (before 8.2 to 11.8 ms, median 10.7; today 4.2 to 6.3 ms, median 4.7), so today's frame is the shorter by that measure. The load did not stay constant across the runs, and the old tree's per-agent frames are timed in a separate column; the figures should be taken as they are listed.

### Placement closed (4da1e5285)

The same commands, seeds and repetition counts as the two columns above, one run at a time. The crowd tick ran in the scratch tree `baseline-run`; the dawn planning and the frame profile in `baseline-run2` (a second tree of the same commit; a first attempt at both in `baseline-run` is described under the table). Each run's load average (`uptime`, 1, 5 and 15 minute) is in its `.load` file under `raw/timed/`.

| measurement | runs | load (1 minute) before each run | placement closed (4da1e5285) |
|---|---|---|---|
| dawn planning, seconds inside `build_day()` | 1, 2, 3 | 4.45, 4.06, 3.99 | [52.917, 51.618, 45.807] median 51.6 (min 45.8, max 52.9) |
| dawn planning, seconds inside `GameDawn.draw_every_unit()` (the units' draw, which the dawn no longer does itself) | 1, 2, 3 | as the row above | [370.179, 345.616, 285.488] median 345.6 (min 285.5, max 370.2) |
| dawn planning, the two added, per run | 1, 2, 3 | as the row above | [423.096, 397.234, 331.295] median 397.2 (min 331.3, max 423.1) |
| dawn planning, whole probe (the 14 x 14 days, counting included) | 1, 2, 3 | as the row above | [604.191, 568.582, 474.322] median 568.6 (min 474.3, max 604.2) |
| crowd tick, mean over the 36 whole-mode cases of each case's median tick, microseconds | 1, 2, 3 | 3.10, 5.54, 4.37 | 2466.6, 2505.7, 2211.8; the agents' own frames are inside the tick, as on today's tree |
| frame profile (--invincible), profiled, callback interval median, ms | 1, 2, 3 | 2.37, 2.20, 2.00 | [4.647, 5.699, 4.888] median 4.9 (min 4.6, max 5.7); all three accepted by the analyzer |
| frame profile (--invincible), profiled, main-loop wall median, ms | 1, 2, 3 | as the row above | [2.347, 2.305, 2.301] median 2.3 (min 2.3, max 2.3) |
| frame profile (--invincible), profiled, script self sum median, ms | 1, 2, 3 | as the row above | [1.302, 1.273, 1.281] median 1.3 (min 1.3, max 1.3) |
| frame profile (--invincible), profiler disabled, callback interval median, ms | 1, 2, 3 | 2.00, 1.78, 1.75 | [6.9985, 7.5305, 7.468] median 7.5 (min 7.0, max 7.5); all three accepted by the analyzer |

The crowd figures are read with the same fields as `summarize_timed.py`, section 5a, and `summarize_timed.py` now reads this column's files too (its output is under "4 and 5" above). The dawn and frame figures above are read from the same fields as that script's sections 4 and 5b (`build_day_sec`, `whole_probe_sec`; `callback_interval_ms`, `native_ms.frame_main_loop_wall`, `native_ms.script_self_sum`), the medians by the same median.

**The dawn planning probe.** `probes/dawn_planning_time_today.gd` does not parse at 4da1e5285 (`SCRIPT ERROR: Parse Error: Could not find type "Planned" under base "EventScheduler".`, in all three first-attempt runs, `raw/timed/dawn_placement_closed_{1,2,3}.log`, which exit 1 with `0 checks, 1 failures`). `probes/dawn_planning_time_placement_closed.gd` is a copy for this tree whose header says what changed: it is the tree's own `placement_rows.gd` with 14 cities, the context made with `GameDawn` before the timer starts, a timer around `EventScheduler.build_day(dawn)`, and a second timer around `GameDawn.draw_every_unit(dawn)`. The two columns before this one timed one call, `build_day()`, which drew every unit of the day. At 4da1e5285 the dawn does not draw the units (each draws as she comes near it), so that coverage is the two timers' sum; `build_day_sec` alone is what the game's dawn runs. **This column's `build_day` time leaves out building the calm areas** (`CalmAreas.of(map)`, run inside `GameDawn.context()` before the timer starts), which the timer of the two earlier columns included, so the figures are not like for like on that part. The three runs exit 0 with `1 checks, 0 failures` (`raw/timed/dawn_placement_closed_run2_{1,2,3}.log`). The count lines of these three logs (`RD`, `RV`, `RK`, 14 cities) are the tree's own probe's and are not reduced here.

**The frame profile.** The first attempt in `baseline-run` ran the launcher `tests/probes/entity_frame_profile.gd` unchanged, and the analyzer rejected all six runs (`accepted: false` in each `frame_*_placement_closed_{1,2,3}-summary.json.gz`; callback interval medians profiled 8.032, 7.976, 8.041 and disabled 7.797, 8.008, 7.923 ms, kept as measured and not compared). The reasons it gave: the day reads as paused or ended; the walk north covers 211.1 px of path where about 552 are expected (the accepted `today` runs cover 542.8 to 552.0 px); the north input is not held through the retained window; the profiled runs' callback counts disagree with the scene's tick deltas. The cause, found in the run log of one run of the same game flags without the rig (`raw/timed/frame_rig_placement_closed_walk_north_telemetry.txt`, `tools/telemetry.sh`): the day really ends. The rig holds north for the whole run from the doorstep (seed 4242, day 1, arterial spawn), and at 4da1e5285 the day's placement stands a leaf blower (`near leaf_blower at (113,68), 189px` at 2.2 s) and then a homeless yeller (`near homeless_yeller at (113,59)`) on that line; the log reads `7.5  lost  lost_crying after 7.5s to leaf-blower` with the excitement meter at 100, and `spent a nerve on day 1 (act 1); 4 left — day 1 again`. The analyzer's "paused or ended day" is any row of the observer where the day is not running or the tree is paused, which a lost day is; the rows themselves are not kept in the summaries. The log shows her walking straight north along that line and the baby lost on it. The copy `probes/entity_frame_profile_placement_closed.gd` adds `--invincible` to the game's flags and changes nothing else (its header says why). `--invincible` stands the excitement meter and the day clock still and lets nothing but a win end the day, so the same walk along the same line holds for the whole window (550.6 to 553.7 px of path in the six runs, 543.9 to 546.9 px north, the north input held, the day running, no analyzer rejection). The rows on her line still stand where they do and the excitement meter is frozen while she walks past them; the two earlier columns were measured without the flag, on days that did not end. The six runs: profiled 1, 2, 3, then disabled 1, 2, 3, one at a time (`raw/timed/frame_{profiled,disabled}_placement_closed_invincible_{1,2,3}-summary.json.gz`, with the `.load` files; each rig and analyzer exit status is in the `.load` file's last lines). `summarize_timed.py` reads these runs too (its section 5b).

### After row 4b (b3693bee7)

The same commands, seeds and repetition counts, one run at a time, in `.claude/worktrees/baseline-4b`; each run's load average (`uptime`, 1, 5 and 15 minute) is in its `.load` file under `raw/timed/`, with the run's exit status (the frame runs: rig and analyzer) in its last lines.

| measurement | runs | load (1 minute) before each run | after 4b (b3693bee7) |
|---|---|---|---|
| dawn planning, seconds inside `build_day()` | 1, 2, 3 | 1.94, 2.75, 2.88 | [44.143, 44.338, 43.721] median 44.1 (min 43.7, max 44.3) |
| dawn planning, seconds inside `GameDawn.draw_every_unit()` | 1, 2, 3 | as the row above | [332.253, 342.338, 334.332] median 334.3 (min 332.3, max 342.3) |
| dawn planning, the two added, per run | 1, 2, 3 | as the row above | [376.396, 386.676, 378.053] median 378.1 (min 376.4, max 386.7) |
| dawn planning, whole probe | 1, 2, 3 | as the row above | [502.531, 516.410, 505.215] median 505.2 (min 502.5, max 516.4) |
| crowd tick, mean over the 36 whole-mode cases of each case's median tick, microseconds | 1, 2, 3 | 3.33, 3.30, 2.94 | 2481.0, 2341.2, 2351.1 (median 2350.6; the agents' own frames are inside the tick) |
| frame profile, launcher unmodified, profiled, callback interval median, ms | 1, 2, 3 | 2.88, 2.90, 2.76 | [8.308, 8.280, 8.316]; **all three rejected by the analyzer** |
| frame profile, launcher unmodified, profiler disabled, callback interval median, ms | 1, 2, 3 | 2.73, 2.65, 2.52 | [8.333, 8.332, 8.329]; **all three rejected by the analyzer** |
| frame profile (--invincible), profiled, callback interval median, ms | 1, 2, 3 | 2.48, 2.44, 2.58 | [4.333, 3.910, 3.958] median 4.0 (min 3.9, max 4.3); all three accepted |
| frame profile (--invincible), profiled, main-loop wall median, ms | 1, 2, 3 | as the row above | median 2.5 (min 2.5, max 2.6) |
| frame profile (--invincible), profiled, script self sum median, ms | 1, 2, 3 | as the row above | median 1.4 (min 1.3, max 1.4) |
| frame profile (--invincible), profiler disabled, callback interval median, ms | 1, 2, 3 | 2.56, 2.67, 2.67 | [6.074, 6.703, 6.306] median 6.3 (min 6.1, max 6.7); all three accepted |

The crowd figures are the same fields as `summarize_timed.py` section 5a (the script prints the per-run values rounded to whole microseconds: 2481, 2341, 2351).

**The dawn planning probe.** `probes/dawn_planning_time_placement_closed.gd` was not run again: the tree's own `placement_rows.gd` has changed its calls since 4da1e5285 (a plan is asked for `spawn_mode_on()`, `is_sent_ahead()`, `placed_at()` and `row_id()` directly, the map's block plans come from `plans_by_block()`, a closure from `street_key()`), so `probes/dawn_planning_time_after_4b.gd` was made from the tree's current `placement_rows.gd` with the same change the placement closed copy made (`SEEDS = 14`, the context made with `GameDawn.context()` before the timer starts, a timer around `EventScheduler.build_day(dawn)` and another around `GameDawn.draw_every_unit(dawn)`, the count lines the tree's own). As in the placement closed column the `build_day` timer leaves out building the calm areas, which the first two columns' timer included, so `build_day` alone is not like for like with them; the two timers' sum has the placement closed column's coverage. The three runs exit 0 with `1 checks, 0 failures` (`raw/timed/dawn_after_4b_{1,2,3}.log`).

**The frame profile.** The launcher `tests/probes/entity_frame_profile.gd`, unmodified, ran all six runs (three profiled, three with the profiler disabled) and the analyzer rejected every one of them, with the reasons it gave for the placement closed column's first attempt (profiled: `paused or ended day`, `northward net movement below 450 pixels; expected about 552`, `north input not held throughout retained window`, `profiler physics callback counts disagree with scene tick deltas`; disabled: the first three of those); the summaries are kept (`raw/timed/frame_{profiled,disabled}_after_4b_{1,2,3}-summary.json.gz`, `accepted: false`), and the cause was not looked into again. The six runs with the copy `probes/entity_frame_profile_after_4b.gd` (the launcher with `--invincible` added to the game's flags, as the placement closed column did; its header names what changed) were accepted by the analyzer (`raw/timed/frame_{profiled,disabled}_after_4b_invincible_{1,2,3}-summary.json.gz`), and those are the figures of the table's last rows. The first two columns were measured without the flag, the placement closed column and this one with it.

## Not measured, and why
- `escape_winnable.gd` (the escape's route walked per exit, 24 seeds) exists only on today's tree and walks the real game per seed; it was not run on either tree, to keep a tree-for-tree comparison, and because the walked runs are many hours on a loaded machine.
- `minty_quail_lane_parity.gd`, the probe minty-quail-16 used, does not exist on v0.29.0; the crowd tick is `m159_crowd_tick_cost.gd` on both.
- The release build is not measured (the repo has no way to run the probes on an exported build); every number is a headless debug build.
- Frame time is the headless debug build's; no rendered frame was measured.
