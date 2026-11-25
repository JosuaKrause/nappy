# silver-ferret: the later days judged on how many events they place and how hard those are

The evidence for the record silver-ferret (`tools/decisions.sh silver-ferret`): per act (I to IV)
and per day 1 to 14, how many events a day places and how hard they are to deal with, read on
today's main. The record holds the judgement; this folder holds the readings, the probe copies
and scripts that make them, and the commands that make them again.

## The claim, and its limits

- **Claim:** the figures below are what today's main places and what those events cost by the
  cost table (`docs/COSTS.md`), over the same 18 cities and the same streams as the end
  remeasure's placement probes, and what walking every route of the day's route tree meets on
  three cities.
- **The measure is the filer's proposal** (the entry's "Proposed, not asked for"): each act's mix
  of rows weighted by the cost table's price of one pass of each row, beside the share of a day's
  events whose rows end the day or hunt her. The price is the pass at the nearest line the table
  gives (0px, or 20px for a row with a solid body), awake and asleep; a pass that nets below zero
  (the decay she has walking anyway is bigger than the row's field) counts as 0 in the "paid"
  figures and keeps its sign in the "net" ones. A row the table dashes (it pursues or waits for
  her, so it has no pass) is unpriced and counted in the share.
- **Limits.** Every day is planned at heat 0 (`PlacementProbeDay.HEAT`), so the share is given
  cold and "with the lethal rung", the ceiling if her heat has reached the rung where the
  roadblock's guard and the night raid hunt her (the end remeasure's N8 reading). The pressing
  rung of a heated row (dearer to stand near, never ending the day) is not counted. The price is
  one pass on quiet sidewalk with no wall between, which is what meeting a row costs, not how
  often she meets it; the route walk is the reading of what she meets. The walk prices each event
  at its live rate where it stands when streamed in and ticks nothing, so nothing pursues and a
  mobile row is met where it starts (the original probe's own limits); the moments the director
  sends ahead of her are not in it.

## Tree, machine, method

- **Tree:** `c60129fadf6e0a904434685f8702509a4a9d1f17` (origin/main when the measuring started),
  worktree `.claude/worktrees/silver-ferret`, `./tools/check.sh` once first (exit 0).
  Nothing under `src/`, `tests/` or `tools/` changed: each probe copy was copied into
  `tests/probes/` of the worktree uncommitted to run and removed after.
- **Since the end remeasure's tree** (`f98443b5b`,
  `docs/evidence/minty-quail-end-numbers-2026-11-24/`)
  no file under `src/events/model/`, `src/events/data/`, `src/city/`, `src/routes/` or
  `src/autoload/` changed, nor `tests/probes/placement_rows.gd`, `placement_probe_day.gd` or
  `ramp_cities.gd`. The 952 `RD`, `RV` and `RK` lines of this run equal that remeasure's
  `raw/placement_rows.log` as a set (`sort` and `diff`: no difference), and `ramp_cities.gd`
  prints the same ten lines.
- Godot 4.7.2 stable (`ed1daf0bf`), headless debug build, Apple M2, one Godot run at a time
  from this worktree; other agents' Godot runs were on the machine (the load before each run is
  in `raw/<run>.load`, a one-minute average of 4.1 to 6.3). `raw/<run>.time` holds each run's
  exit code and wall time.
  Nothing here is a timing.

## The runs

| run | command (in the worktree) | output |
|---|---|---|
| the mix | `tools/test.sh probes/later_days_rows.gd` (the copy `probes/later_days_rows.gd`) | `raw/later_days_rows.log` |
| the ramp | `tools/test.sh probes/ramp_cities.gd` | `raw/ramp_cities.log` |
| the route walk | `tools/test.sh probes/later_days_route_walk.gd` (the copy `probes/later_days_route_walk.gd`) | `raw/later_days_route_walk.log` |
| her route's cells | `tools/test.sh probes/placement_cells.gd` | `raw/placement_cells.log` |
| the one cell set | `tools/test.sh probes/placement_cells.gd`, the tree with `raw/placement_cells_act4_street23.patch` applied | `raw/placement_cells_act4_street23.log` |

- `probes/later_days_rows.gd` is `tests/probes/placement_rows.gd` with two kinds of line
  added: `RM day row count` (the moments the dawn owes her, by row) and `FLAGS` for every
  catalogue row (the end remeasure's `row_flags.gd`).
- `probes/later_days_route_walk.gd` is `tests/probes/polite_rabbit_wall_costs.gd` walked on
  every day 1 to 14 rather than days 1, 5, 9 and 13, with one `MET` line a city and day: the
  distinct events whose field reached her as built, and of those the ones whose row ends the day
  or pursues her.
- The readings are made by three scripts in `probes/`, read with `python3 -I`:
  `weigh_days.py docs/COSTS.md raw/later_days_rows.log` (the mix, the price and the share,
  `raw/weigh_days.txt`; the reading without the abduction, `raw/weigh_days_without_abduction.txt`,
  is `weigh_days.py --without abduction docs/COSTS.md raw/later_days_rows.log`, the flag before
  the paths), `route_cells.py raw/placement_cells.log` (her route's draw locations,
  `raw/route_cells.txt`; for the run with the one cell set,
  `route_cells.py --cell 0 0 4 23 raw/placement_cells_act4_street23.log`, which prints that cell
  as the run had it, `raw/route_cells_act4_street23.txt`) and `route_walk.py raw/later_days_route_walk.log`
  (`raw/route_walk.txt`).

- **The one cell set** is the record's board option: her route's street cell in act IV
  (`PlacementDensity.EVENTS_PER_HUNDRED[0][0][3]`) 16 to 23 and nothing else. Since a `const`
  cannot be set from a probe, `src/events/data/placement_density.gd` was edited in the worktree,
  uncommitted, for that one run (`raw/placement_cells_act4_street23.patch`; the edited file's
  SHA-256 `56a29fb656b7477799949a0c2678010074685fc27f4e44dd0c38efc126147d1d`), and restored with
  `git checkout` after it; the tree is otherwise the measured one. Its lines for days 1 to 11 and
  every `CL` line equal `raw/placement_cells.log` as a set.

To run again: check out the tree in a fresh worktree, `./tools/check.sh`, copy each probe copy
into its `tests/probes/`, run the commands above into a new scratch directory, and read them
with the scripts.

## Readings

Events a city-day are the 18 cities' sums divided by 18, the mean of an act's days; "x act I" is
the act's figure over act I's. "Paid" is the price of the priced events' passes, awake, a pass
under the decay as 0; "paid an event" divides it by the priced events, the placed ones less those
the table dashes. The whole of each script's output is in `raw/`.

### The whole city, every placed row (`raw/weigh_days.txt`)

| act (days) | placed | x act I | paid a city-day | x act I | paid an event | x act I | ends the day or pursues (cold) | with the lethal rung | asleep, an event |
|---|---|---|---|---|---|---|---|---|---|
| I (1-3) | 88.6 | 1.00 | 454.9 | 1.00 | 5.84 | 1.00 | 0.6 (0.7%) | 0.6 (0.7%) | 0.21 |
| II (4-7) | 105.3 | 1.19 | 594.3 | 1.31 | 6.61 | 1.13 | 5.8 (5.5%) | 7.0 (6.6%) | 0.43 |
| III (8-11) | 93.3 | 1.05 | 891.9 | 1.96 | 11.39 | 1.95 | 16.7 (17.9%) | 21.9 (23.5%) | 1.57 |
| IV (12-14) | 106.0 | 1.20 | 1242.6 | 2.73 | 13.77 | 2.36 | 18.6 (17.6%) | 28.8 (27.1%) | 1.63 |

### The whole city without the abduction (`raw/weigh_days_without_abduction.txt`)

| act (days) | placed | x act I | paid a city-day | x act I | paid an event | x act I | ends the day or pursues (cold) | with the lethal rung | asleep, an event |
|---|---|---|---|---|---|---|---|---|---|
| I (1-3) | 88.6 | 1.00 | 454.9 | 1.00 | 5.84 | 1.00 | 0.6 (0.7%) | 0.6 (0.7%) | 0.21 |
| II (4-7) | 105.3 | 1.19 | 594.3 | 1.31 | 6.61 | 1.13 | 5.8 (5.5%) | 7.0 (6.6%) | 0.43 |
| III (8-11) | 83.2 | 0.94 | 415.6 | 0.91 | 6.09 | 1.04 | 6.6 (8.0%) | 11.8 (14.2%) | 0.12 |
| IV (12-14) | 94.2 | 1.06 | 688.1 | 1.51 | 8.76 | 1.50 | 6.9 (7.3%) | 17.0 (18.1%) | 0.17 |

The abduction stands 0 times on her route, 49 times route-adjacent and 1309 times off the route
over the 18 cities and fourteen days (`RV` lines). In acts III and IV it is 53% and 45% of the paid
points and 60% and 63% of the rows that end the day (the `TOPACT` lines).

### On her route, view 0 (`raw/weigh_days.txt`)

| act (days) | placed | x act I | paid a city-day | x act I | paid an event | x act I | ends the day or pursues (cold) | with the lethal rung | asleep, an event |
|---|---|---|---|---|---|---|---|---|---|
| I (1-3) | 21.6 | 1.00 | 44.9 | 1.00 | 2.27 | 1.00 | 0.0 (0.0%) | 0.0 (0.0%) | 0.00 |
| II (4-7) | 29.9 | 1.38 | 71.3 | 1.59 | 2.63 | 1.16 | 0.1 (0.4%) | 0.8 (2.8%) | 0.09 |
| III (8-11) | 20.3 | 0.94 | 46.7 | 1.04 | 2.56 | 1.13 | 0.1 (0.3%) | 2.4 (11.8%) | 0.00 |
| IV (12-14) | 14.2 | 0.66 | 35.4 | 0.79 | 2.72 | 1.20 | 0.1 (0.7%) | 1.5 (10.3%) | 0.00 |

### Her route's draw locations (`raw/route_cells.txt`)

| act | draw locations a city-day | events a city-day | per hundred | street: per hundred / cell | junction box: per hundred / cell | park or square: per hundred / cell |
|---|---|---|---|---|---|---|
| I (1-3) | 542.8 | 24.80 | 4.57 | 4.39 / 7.5 | 7.11 / 24.0 | 3.59 / 46.0 |
| II (4-7) | 566.3 | 38.62 | 6.82 | 6.32 / 11.0 | 13.02 / 36.0 | 3.34 / 50.0 |
| III (8-11) | 442.6 | 26.18 | 5.92 | 5.69 / 14.0 | 9.59 / 35.0 | 3.23 / 50.0 |
| IV (12-14) | 345.7 | 18.39 | 5.32 | 5.64 / 16.0 | 4.78 / 46.0 | 4.19 / 50.0 |

With the one cell set (`raw/route_cells_act4_street23.txt`), act IV on her route reads 345.7 draw
locations, 24.26 events a city-day and 7.02 for every hundred; its street 7.81 for every hundred
against the cell of 23, its junction box 4.66 against 46, its park or square unchanged. The other
two views and acts I to III are unchanged. By day, what the units place on her route goes from
20.7, 17.3 and 17.1 a city on days 12 to 14 to 26.7, 23.1 and 23.0, and the whole city from 96.6,
94.9 and 99.9 to 102.6, 100.6 and 105.8.

The units' count here (`placement_cells.gd`, the rows the units drew, one handed to her walk
among them) is a little above the mix's (`placement_rows.gd`, what the dawn placed); the 1174
`CL`, `CE` and `CP` lines equal the end remeasure's `raw/probe_placement_cells.log` as a set.
Her route's alleys hold no cell (0 in every act). The other two views are in the file.

### Walking every route of the day's route tree, three cities (`raw/route_walk.txt`)

| act | minutes walked | points a minute | x act I | events met a minute | x act I | events met a route | end the day or pursue, met a minute | met a route |
|---|---|---|---|---|---|---|---|---|
| I (1-3) | 152.0 | 49.5 | 1.00 | 2.63 | 1.00 | 2.9 | 0.00 | 0.00 |
| II (4-7) | 204.6 | 70.6 | 1.43 | 3.56 | 1.35 | 4.0 | 0.06 | 0.07 |
| III (8-11) | 182.6 | 55.1 | 1.11 | 4.39 | 1.67 | 4.4 | 0.18 | 0.18 |
| IV (12-14) | 138.3 | 55.7 | 1.13 | 4.49 | 1.71 | 4.5 | 0.07 | 0.07 |

The walk's lines for days 1, 5, 9 and 13 equal the end remeasure's
`raw/probe_polite_rabbit_wall_costs.log` line for line.

### The moments the director sends ahead of her (`MOMACT` lines)

| act | moments a day | of them end the day | paid a city-day | paid a moment | rows, a city-day |
|---|---|---|---|---|---|
| I (1-3) | 26.0 | 3.0 | 352.0 | 13.53 | dog walker 10.9, loose dog 6.7, cat dash 5.4, cyclist 2.4, charging dog 0.7 |
| II (4-7) | 27.0 | 3.1 | 298.6 | 11.06 | dog walker 8.2, police patrol 5.9, loose dog 5.3, cat dash 4.4, cyclist 3.1 |
| III (8-11) | 29.0 | 2.7 | 336.5 | 11.60 | dog walker 9.4, loose dog 6.2, police patrol 6.1, cat dash 4.7, cyclist 2.7 |
| IV (12-14) | 32.0 | 3.4 | 380.1 | 11.88 | dog walker 10.0, loose dog 6.6, police patrol 6.3, cat dash 5.1, cyclist 3.4, military convoy 0.7 |

The moments that end the day are the cyclists and, on day 3, the charging dog.

### Per day

| day | placed | ends the day or pursues (cold) | with the lethal rung | paid a city-day | paid an event | asleep, an event | her route: placed | her route: paid an event | moments (of them end the day) | walk: points a minute | walk: met a minute | walk: end the day or pursue, met a minute |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 90.0 | 0.0 (0.0%) | 0.0 (0.0%) | 493.5 | 6.40 | 0.25 | 21.8 | 2.52 | 26.0 (0.0) | 72.0 | 3.39 | 0.00 |
| 2 | 90.1 | 0.0 (0.0%) | 0.0 (0.0%) | 459.9 | 5.73 | 0.20 | 23.2 | 2.44 | 26.0 (3.9) | 56.7 | 2.84 | 0.00 |
| 3 | 85.7 | 1.8 (2.1%) | 1.8 (2.1%) | 411.1 | 5.38 | 0.18 | 19.8 | 1.80 | 26.1 (5.2) | 20.7 | 1.70 | 0.00 |
| 4 | 101.6 | 6.2 (6.1%) | 6.2 (6.1%) | 477.7 | 5.54 | 0.17 | 29.7 | 2.14 | 27.0 (3.3) | 81.0 | 3.44 | 0.03 |
| 5 | 106.9 | 5.9 (5.6%) | 5.9 (5.6%) | 541.1 | 5.89 | 0.16 | 30.7 | 2.43 | 27.0 (2.6) | 45.5 | 2.84 | 0.00 |
| 6 | 111.5 | 5.8 (5.2%) | 5.8 (5.2%) | 861.2 | 8.95 | 1.19 | 30.3 | 3.71 | 27.0 (3.1) | 93.7 | 4.13 | 0.13 |
| 7 | 101.3 | 5.3 (5.3%) | 10.1 (9.9%) | 497.4 | 5.82 | 0.15 | 29.0 | 2.24 | 27.0 (3.4) | 63.2 | 3.99 | 0.08 |
| 8 | 126.1 | 24.6 (19.5%) | 30.0 (23.8%) | 1179.2 | 10.98 | 1.61 | 32.6 | 2.19 | 29.0 (2.6) | 61.3 | 3.82 | 0.53 |
| 9 | 83.4 | 12.4 (14.9%) | 18.2 (21.9%) | 691.8 | 9.95 | 1.23 | 17.5 | 2.46 | 29.0 (2.9) | 53.0 | 4.49 | 0.10 |
| 10 | 82.4 | 14.2 (17.3%) | 19.1 (23.1%) | 832.6 | 12.18 | 1.60 | 15.1 | 2.89 | 29.0 (2.6) | 58.4 | 4.36 | 0.06 |
| 11 | 81.4 | 15.5 (19.0%) | 20.3 (25.0%) | 864.0 | 12.72 | 1.83 | 16.1 | 3.16 | 29.0 (2.7) | 48.4 | 4.77 | 0.11 |
| 12 | 99.0 | 16.3 (16.5%) | 21.8 (22.0%) | 1141.6 | 13.51 | 1.52 | 16.6 | 2.41 | 32.0 (3.2) | 57.3 | 4.79 | 0.09 |
| 13 | 116.9 | 19.6 (16.8%) | 39.6 (33.9%) | 1327.2 | 13.20 | 1.60 | 13.2 | 2.98 | 32.0 (4.1) | 52.1 | 4.41 | 0.00 |
| 14 | 101.9 | 19.9 (19.5%) | 24.9 (24.4%) | 1259.0 | 14.70 | 1.78 | 12.9 | 2.83 | 32.0 (3.1) | 56.9 | 4.29 | 0.11 |

### The ramp (`raw/ramp_cities.log`)

`tests/test_events_scheduler.gd`'s ramp check (day 14 a fifth over day 1, on city 4242) planned on
ten cities: 4242 1.51 (89 to 134), 77 1.34, 1301 1.17, 90210 1.05, 90241 0.99, 90272 1.19, 90303
1.20, 90334 1.32, 2024 0.95, 31337 1.14; the check's `late * 5 > early * 6` holds on 4242, 77,
90303 and 90334. Over the 18 cities of the mix, day 14 places 101.9 a city against 90.0 on day 1,
1.13 times.

## Footprint

27 files, about 190 KB: the five runs' whole output with their load and time files (the runs
print little beyond their figures, so nothing is cut), the one-line patch of the cell run, the two
probe copies, the three scripts and their five readings. `check.sh`'s boot output is left out (exit 0).
