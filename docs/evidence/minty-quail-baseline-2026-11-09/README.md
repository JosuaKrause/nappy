# The numbers from before the refactor and from today's main (minty-quail, the baseline measurements)

Measured, not judged: a difference is listed with its size and nothing says what moved it or whether it matters.

## The two trees, the machine
- **Before:** tag `v0.29.0`, commit `6985ac74fd2853bffc05607c53c21ce50b69429a`, scratch worktree made with `tools/agent-setup.sh --detach v0.29.0 baseline-before`.
- **Today:** `origin/main` at `38ce038231009ae8a4d08284e6bad9dda4b035c2`, `tools/agent-setup.sh --detach origin/main baseline-today`.
- `./tools/check.sh` ran once in each first (both OK). Godot 4.7.2 stable, headless debug build (`tools/test.sh` and `tools/check.sh` pass `--headless`), Apple M2, macOS. Other agents ran Godot on the machine throughout; the load average (1, 5, 15 minute) before each run is recorded below and in `raw/**/*.load` and `raw/timed/loads.txt`. Load was above 50 at the start of one run (noted where it applies), about 3 to 10 for most timed runs.
- Every run: `tools/test.sh <name>` in the scratch tree (it passes `--headless`), or the Godot command shown. No run touches the save (probes and suites do not write it).
- The old tree's tests directory has the probes of its own time; where a probe of the same name exists on both trees, each tree ran its own copy (the copies differ, see "Probes" below). Nothing was edited in place; copies made for this folder are under `probes/` and were copied into the scratch trees (uncommitted there) to run.

## Probes
| Probe | v0.29.0 | today | note |
|---|---|---|---|
| `tests/probes/placement_rows.gd` | absent | present | `probes/placement_rows_v0.29.0.gd` is a cut-down counterpart (see its header): no `DaySpec`, no guarded-row argument, `build_day(day, rng, map, consumed, [], [], tree, 0, doors, [], standing)`; no `Corridor.view_of()`, so the view is that function's rule written out from `Corridor.depth()` and `Corridor.route_junctions()`; `StreetNetwork` is static; same cities (18 from 90210 step 31), same RNG seed strings, same `RD`/`RV`/`RK` lines. Seals do not get `stand_as_a_seal()`, wall bodies not `stand_in_the_wall()` (no such calls there). |
| `probes/placement_roles.gd` | not run | run once | prints `ROLE day row role` from `EventScheduler.role_for()` on today's tree; v0.29.0 has no `role_for()`, so the one table feeds the comparison of both trees. |
| `m129_zero_cost_line`, `m117_decay`, `polite_rabbit_wall_costs`, `m159_crowd_tick_cost`, `entity_frame_profile` (+ observer, analyzer) | own copy | own copy | present in both, run unchanged; they differ between the trees by the API of their time (line diffs: m129 123, m117 59, polite 46, m159 77, observer 6; the analyzer and `entity_frame_profile.gd` are identical). `m159_crowd_tick_cost`'s columns differ: on v0.29.0 `agents` (`CrowdAgent._process()` per agent) and `tick` are timed apart, on today's tree the agents' steps run inside `tick`. |
| `probes/dawn_planning_time_*.gd` | copy of the v0.29.0 counterpart | copy of today's `placement_rows.gd` | 14 cities, a timer around the one `EventScheduler.build_day()` call per city and day; see headers. |
| `escape_winnable.gd` | absent | present | not run on either tree (see "Not measured"). |
| `minty_quail_lane_parity.gd` (minty-quail-16's probe) | absent | present | not run on either tree; `m159_crowd_tick_cost.gd` is used instead, as the brief says. |

Comparison script: `placement-remeasure-script.original.py` is the script from the brief, unchanged (provenance). `compare_placement.py` is it with the sample paths pointed at `raw/`, one sample ("90210+31i", 18 cities, before as the script's "main" and today as its "head"), and its editorial passages (the "changed on purpose" list, "what the probe cannot see", the two notes) removed. `summarize_timed.py` computes the tables of measurements 4 and 5.

## 1. Winnability across seeds and days
The suites that ask whether the days hold together and can be won, each run by name filter (`tools/test.sh <name>`, which matches the suite files `test_x.gd` and its split `test_x_a/_b/_c.gd`). Seeds are the ones the suites use (full run: 4242, 90210, 1234567 on v0.29.0, the same plus the shards of today's split; finale: its rig's own). Counts, run once. Load is the 1-minute average before the run.

| Suite filter | before | today |
|---|---|---|
| `test_full_run*` | 16739 checks, 0 failures (load 28.66) | 16537 checks, 0 failures (load 6.68) |
| `test_finale*` | 6026 checks, 0 failures (load 11.27) | 9501 checks, 0 failures (load 7.72) |
| `test_acts*` | 356 checks, 0 failures (load 16.42) | 349 checks, 0 failures (load 5.47) |
| `test_regions*` | 178735 checks, 0 failures (load 13.95) | 388618 checks, 0 failures (load 7.80) |
| `test_seals*` | 53906 checks, 0 failures (load 8.39) | 52814 checks, 0 failures (load 22.16) |
| `test_routes_lattice*` | 19738 checks, 0 failures (load 5.65) | 19472 checks, 0 failures (load 20.06) |
| `test_routes_closures*` | 1848 checks, 0 failures (load 5.52) | 1850 checks, 0 failures (load 20.10) |
| `test_balance*` | 19 checks, 0 failures (load 5.77) | 36 checks, 0 failures (load 8.00) |

Check counts differ between the trees because the suites were rewritten and split between them; every run says 0 failures. `m129_zero_cost_line` (does a zero-cost line exist along every route the day plans; 6 seeds, one day per act 1, 5, 9, 13), as printed:

| | before | today |
|---|---|---|
| placed rows a day a line has to avoid | 326.6 | 310.4 |
| routes with a zero-cost line, primary reading, act 1 | 69 of 89 (77.5%) | 77 of 89 (86.5%) |
| act 2 | 72 of 89 (80.9%) | 80 of 89 (89.9%) |
| act 3 | 61 of 75 (81.3%) | 70 of 75 (93.3%) |
| act 4 | 45 of 46 (97.8%) | 46 of 46 (100.0%) |
| all | 247 of 299 (82.6%) | 273 of 299 (91.3%) |
| pacing rows over their whole beat, all | 120 of 299 (40.1%) | 154 of 299 (51.5%) |

The full output, with the shapes of what broke the line, is `raw/probe_m129_zero_cost_line_{before,today}.log`. The escape's own winnability probe (`escape_winnable.gd`) is not run, see below.

## 2. What a route costs to walk
- `tools/cost-table.sh --check`: "docs/COSTS.md is up to date" on both trees (`raw/cost_table_check_*.log`). The two checked-in `COSTS.md` files (`raw/COSTS_before.md`, `raw/COSTS_today.md`) differ only in the prose lines listed in `raw/COSTS_diff.txt` (names of where two constants live and `_role_for` / `role_for`); no table number differs.
- `polite_rabbit_wall_costs` (gross points over the day's routes, 3 seeds x days 1, 5, 9, 13; columns events: through walls / as built / 16px everywhere; crowd likewise), summary rows as printed:

| | before | today |
|---|---|---|
| all, routes / seconds | 184 / 11065 | 184 / 11065 |
| events through walls / as built / 16px | 21206.0 / 21077.4 / 20869.7 | 16821.4 / 16732.5 / 16588.8 |
| crowd (through walls / as built / 16px) | 17504.5 each | 17170.0 each |
| per minute walked, events | 115.0 / 114.3 / 113.2 | 91.2 / 90.7 / 89.9 |
| per minute walked, crowd | 94.9 | 93.1 |
| share kept, events | 99.4% / 98.4% | 99.5% / 98.6% |

(The per-seed and per-day rows of both trees are in the two raw files, `raw/probe_polite_rabbit_wall_costs_{before,today}.log`; their routes and seconds columns are equal row by row.)
- `m117_decay` (the net meter rate per kind of ground, walked): `raw/probe_m117_decay_{before,today}.log`, whole tables, not reduced here.

## 3. How many of each event row a city holds a day, by view
`placement_rows` on today's tree, `probes/placement_rows_v0.29.0.gd` on v0.29.0; 18 cities from seed 90210 in steps of 31 (sample "90210+31i"), days 1 to 14, run once each. Logs: `raw/placement_rows_{before,today}.log` (RD / RV / RK lines, summed over the 18 cities), compared by `compare_placement.py` into `raw/placement_comparison.txt` (all 264 lines). The whole day's count per 18 cities, from the `RD` lines (placed, then moments she is owed):

| day | before placed, moments | today placed, moments |
|---|---|---|
| 1 | 1819, 418 | 1593, 414 |
| 2 | 1864, 469 | 1629, 468 |
| 3 | 1865, 527 | 1666, 522 |
| 4 | 2105, 445 | 1711, 450 |
| 5 | 2317, 462 | 1900, 468 |
| 6 | 2533, 497 | 2126, 504 |
| 7 | 2544, 517 | 2048, 522 |
| 8 | 2682, 507 | 2196, 504 |
| 9 | 2073, 501 | 1574, 504 |
| 10 | 2167, 534 | 1662, 540 |
| 11 | 2221, 560 | 1752, 558 |
| 12 | 2342, 567 | 1834, 576 |
| 13 | 2412, 571 | 2218, 576 |
| 14 | 2495, 579 | 1992, 576 |

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
- crowd tick: `tools/test.sh probes/m159_crowd_tick_cost.gd` (2 seeds x days 1, 9, 14 x 2 walks x 3 repetitions, whole and split modes, 150 warmup then 600 timed ticks per case); one `CROWD_TICK_JSON` line per run (raw `raw/timed/crowdtick_*`, with the hash chains every 150 ticks removed to save space).
- frame profile: `ENTITY_PROFILE_OUTPUT=<prefix> [ENTITY_PROFILE_DISABLED=1] /Applications/Godot.app/Contents/MacOS/Godot --headless --path <tree> --script tests/probes/entity_frame_profile.gd`, then `python3 -I <tree>/tests/probes/entity_frame_profile_analyze.py <prefix> [--profiler-disabled] --output <prefix>-summary.json` (the analyzer accepted every run). Seed 4242, day 1, arterial spawn, walking north. Summaries are kept gzipped.

`python3 -I summarize_timed.py` prints (kept as `raw/timed_tables.txt`):

```
== 4. dawn planning: seconds inside build_day(), 14 cities x 14 days, per run n=1..3
before build_day [202.553, 177.92, 284.563] median 202.6 (min 177.9, max 284.6) | whole probe [333.633, 293.008, 479.616] median 333.6 (min 293.0, max 479.6)
today build_day [256.185, 403.001, 340.105] median 340.1 (min 256.2, max 403.0) | whole probe [390.513, 598.831, 516.773] median 516.8 (min 390.5, max 598.8)
== 5a. crowd tick, mean over the 36 cases of the case's median per-tick microseconds, per run
before cases/run 36 | tick column [371, 347, 629] median 370.5 (min 346.8, max 629.3) | agents' own frames column [1675, 1448, 2797] median 1675.4 (min 1448.2, max 2797.1) | agents + tick median 2046.0 (min 1795.0, max 3426.4)
today cases/run 36 | tick column [2086, 3945, 4860] median 3944.7 (min 2085.6, max 4859.8) | agents' own frames column [0, 0, 0] (inside tick) | agents + tick median 3944.7 (min 2085.6, max 4859.8)
== 5b. per-system frame profile (entity_frame_profile.gd, seed 4242 day 1, ms), per run
profiled before callback interval median ms median 15.5 (min 12.1, max 19.2) | main-loop wall median ms median 14.9 (min 11.6, max 18.4) | script self sum median ms median 8.9 (min 6.8, max 10.9)
profiled today callback interval median ms median 28.8 (min 5.3, max 29.1) | main-loop wall median ms median 27.6 (min 4.5, max 28.0) | script self sum median ms median 15.9 (min 2.8, max 16.2)
disabled before callback interval median ms median 10.7 (min 8.2, max 11.8) 
disabled today callback interval median ms median 4.7 (min 4.2, max 6.3)
```
Reading the figures as measurements and nothing more: the crowd tick's three runs on today's tree span 2086 to 4860 microseconds and the old tree's agents + tick span 1795 to 3426, so the two trees' ranges overlap and the difference between their medians is inside the spread; the dawn's build_day ranges overlap likewise (before 177.9 to 284.6 s, today 256.2 to 403.0 s; the two trees' runs 1 and 2 alone do not overlap: 177.9 and 202.6 against 256.2 and 403.0); the profiled frame figures of today's tree run from 4.5 to 28.0 ms per run, which is a spread wider than any difference to the old tree's 11.6 to 18.4 ms. The load did not stay constant across the runs, and the old tree's per-agent frames are timed in a separate column; the figures should be taken as they are listed.

## Not measured, and why
- `escape_winnable.gd` (the escape's route walked per exit, 24 seeds) exists only on today's tree and walks the real game per seed; it was not run on either tree, to keep a tree-for-tree comparison, and because the walked runs are many hours on a loaded machine.
- `minty_quail_lane_parity.gd`, the probe minty-quail-16 used, does not exist on v0.29.0; the crowd tick is `m159_crowd_tick_cost.gd` on both.
- The release build is not measured (the repo has no way to run the probes on an exported build); every number is a headless debug build.
- Frame time is the headless debug build's; no rendered frame was measured.
