# minty-quail — The numbers from before the refactor and from today's main are kept side by side · 2026-11-09

minty-quail's `baseline-measurements.md`: the first reading. Shown that the single remeasure at the
end had no stored "before", the player: "sure" (inbox #1268 in olive-ferret).

**Built.** `docs/evidence/minty-quail-baseline-2026-11-09/` holds both columns, its README naming
the two trees (before: `v0.29.0` at `6985ac74f`; today: `main` at `38ce03823`), the machine (an M2,
headless, Godot 4.7.2), every command, the seeds and the machine's load before each run, with the
raw output under `raw/`.

- **Winnability:** no failure on either tree in any of the run suites (`test_full_run`,
  `test_finale`, `test_acts`, `test_regions`, `test_seals`, `test_routes_lattice`,
  `test_routes_closures`, `test_balance`). Routes with a line that costs nothing to walk
  (`m129_zero_cost_line`): 247 of 299 before, 273 of 299 today; placed rows a day to avoid, 326.6
  and 310.4.
- **Route cost:** the cost table is up to date on both trees and the two `docs/COSTS.md` differ in
  prose only. Events met through walls, all rows: 21206.0 before, 16821.4 today; the crowd 17504.5
  and 17170.0; events a minute walked 115.0 and 91.2.
- **Placement rows** (18 cities, days 1 to 14): walls a city a day on her route 8.61 → 6.15,
  route-adjacent 27.82 → 19.62, off the route 18.40 → 13.81; a day's placed total for the 18 cities
  on day 1 1819 → 1593, day 9 2073 → 1574, day 14 2495 → 1992. The old tree's probe draws its
  closures, seals and walls from the same seed strings through different planners, so the cities'
  closures differ and the two columns are not a paired comparison.
- **Dawn planning time** (14 cities × 14 days, three alternating pairs): medians 202.6 s before and
  340.1 s today, the ranges overlapping, one of the old tree's runs started at a load of 55.
- **Crowd tick and frame** (three alternating pairs): per-tick medians 2046 µs before and 3945 µs
  today, the ranges overlapping. With the profiler disabled the frame's callback interval does not
  overlap: a median of 10.7 ms before (8.2 to 11.8) and 4.7 ms today (4.2 to 6.3). The profiled
  frame's spread (today 4.5 to 28.0 ms) is too wide to compare.

**Written for the old tree, each noted in the README:** `placement_rows_v0.29.0.gd` (the old tree
has no `DaySpec`, no `Corridor.view_of()`, and an older `build_day`), one role table from today's
tree used for both (`placement_roles.gd`), and two copied dawn-timing probes. The crowd's tick is
read with `m159_crowd_tick_cost` on both, whose columns differ (the old tree times the agents'
frames apart from the tick). The placement comparison script is in the evidence folder beside the
brief's original.

**Not measured:** the escape's winnability (`escape_winnable.gd` exists only today), a release build
and rendered frames.

**What is left** is in the item: two later readings as further columns, and the comparison script
as a `tools/` entry point.
