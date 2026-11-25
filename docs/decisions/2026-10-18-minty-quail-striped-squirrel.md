# minty-quail — The end remeasure's numbers: winnability, route costs, the cost table, placement · 2026-11-24

**The ask.** The entry's remeasure (step 3 of its README) asks for the deterministic numbers once, at the very end, set beside the design review's baseline readings (inbox #813 in curly-moose): winnability across seeds, route costs, the cost table, `placement_rows.gd` compared with `tools/compare-placement-rows.py`, and the test counts the fourth baseline list names. Nothing is judged in the readings; a number that moved is listed here and playtest decides which deviations are fixed (inbox #1278 in olive-ferret).

**Measured on** `f98443b5b19ddada1899c13c4d939d84049ea453` (head), headless, Godot 4.7.2, one Godot run at a time. The evidence is `docs/evidence/minty-quail-end-numbers-2026-11-24/` (its README holds the commands, the loads and every figure; 69 files, 468 KB on disk). The "before" is the baseline folder's columns (`v0.29.0`, and after row 4b, `b3693bee7`): every probe is deterministic for a tree, so no older tree was run again.

## Readings (head against the columns)

| | v0.29.0 | after 4b | head |
|---|---|---|---|
| the eight suite filters | 0 failures | 0 failures | 0 failures |
| `m129_zero_cost_line` routes with a zero-cost line | 247 of 299 | 299 of 299 | 299 of 299 |
| pacing rows over their whole beat | 120 of 299 | 146 of 299 | 146 of 299 |
| events' route cost, through walls / as built / 16px | 21206.0 / 21077.4 / 20869.7 | 10296.3 / 10189.2 / 10087.4 | 10296.3 / 10189.2 / 10087.4 |
| crowd's route cost | 17504.5 | 17220.5 | 17220.5 |
| `cost-table.sh --check` | up to date | up to date | up to date |
| placement cells outside 2 sigma, against head | 320 of 523 | 0 of 476 | |

Spread: every probe is deterministic, so each side is one reading, and head equals the after-4b column line for line in the `RD`, `RV` and `RK` lines of `placement_rows.gd` (952), the whole output of `polite_rabbit_wall_costs`, `m117_decay` (same lines; rows of its tables print in another order in several places) and `m129_zero_cost_line`, and the role table (683 lines). The suite counts are in the evidence README.

## What moved on purpose (named by the record that moved it)

- **Against v0.29.0:** the events' route cost halved (21206.0 through walls to 16821.4 in the baseline's mid-refactor column, which names no record, and to 10296.3 in its third column, the reading of placement closed, polite-tapir-velvet-heron) and every route has a zero-cost line from that third column (247 of 299, 273 mid-refactor, 299 of 299), which polite-tapir-coral-owl's declared table keeps (its record measures 299 of 299 on its branch); walls on her route +51% and friction -67%, -46% and -45% by view are the same placement redesign. Each is a listing; none is judged.
- **The suites' check counts, each named by the record or pull request that moved it:** `test_acts` 45 to 8 is #1645 (record minty-quail-gentle-bison: the cases that built a live event, a city or a node, or planned a day, moved to the suites of the modules they test, and two checks that duplicated the stance suite's were dropped); `test_finale` 9463 to 9459 is #1656 (record minty-quail-spry-moose: 6 fewer, the far guard's posts, set-off and pacing moved to `tests/test_event_barrier_post.gd`), with #1705 adding one check and #1692 splitting one into two, so -6 +1 +1 = -4; `test_routes_closures` 1850 to 1852 is #1688 (record minty-quail-coral-elk: `--spawn closure` moved from the dev rig into `routes_closures_rig.gd`). All at 0 failures; none is a check dropped or loosened without a reason.
- **Since after 4b:** the `falloff_power` column left the cost table's geometry table (#1718, the last survey for code nothing reaches); `docs/COSTS.md`'s other 280 rows keep every cell, against `v0.29.0` too.

## What moved and no record names

- **The poster tear count** (minty-quail-29): 7 of 2200 tears send nobody (seed 6 day 9; seed 10 days 9 to 14), where that record measured 39 (1.8%), with the same probe (`poster_pursuer_starts.gd`, added by #886 with that record) on the same 40 seeds, days 4 to 14. No record names why 32 of those tears now find a start: unexplained. A gameplay number gets no entry from the remeasure.
- The records' own still-open figures (polite-tapir-coral-owl): her route reads x0.87 of the seed tree again (`placement_cells.gd` read with `compare_cells.py` from that record's evidence folder: 6.69 to 5.80 events per hundred draw locations; its junction boxes x0.77, open ground x0.50; route-adjacent x1.02, off the route x0.96; 94.2 events a city-day against 99.2), the same figures as that record's acceptance run. Its "day 11 a fifth under" was measured against the seed tree's day 11, and reads the same: 96.5 to 78.6 events a city, x0.81 (days 7 and 10 x0.88, an eighth). The 81.4 against 90.0 of the next figure is another measure, day 11's placed count over head's day 1, about 10% under, and answers another question. The ramp day 14 at 1.14 times day 1 reads 1.13 from `placement_rows.gd`, and the ten cities of `ramp_cities.gd` read 0.95 to 1.51 (the record's nine and 4242 again); days 9 to 11 place 83.4, 82.4 and 81.4 a city-day against 90.0 on day 1. Listed, not fitted.

## Listed, not fitted, not taken

- **The police patrol's share** (records minty-quail-downy-toad and -jolly-toad said it would be fitted here): not fitted. One declared table replaced the fitted ones (polite-tapir-coral-owl) and the player left a deviation to playtest (inbox #1278 in olive-ferret).
- **The later days' difficulty** is silver-ferret's to judge; the evidence README's N8 hands its numbers (events a city-day and the share whose rows end the day or pursue her, per day and per act: 0.7% in act 1, 5.5%, 17.9% and 17.6% in act 4 with no heat; 0.7%, 6.6%, 23.5% and 27.1% if her heat has reached the rung that hunts, which adds the `roadblock`'s guard and the `night_raid`. The rows that only wait for her, pigeon flocks and alley mice, are not counted: they are 9 to 13 of the 81 to 126 placed a city-day).
- **The overlapping-badge still** (minty-quail-15) needs a harness that does not exist: not taken.

## Defects reported

None: no run printed a SCRIPT ERROR or an engine error, every suite and probe exited 0, and every route has a zero-cost line. One run, `placement_cells.gd`, was cut off by the harness's two-hour script limit and run again alone; the first, half-written log is kept and labelled.

## Not measured

GoatCounter's counts (a released build is needed), the timings and the pictures belong to the remeasure's other groups.
