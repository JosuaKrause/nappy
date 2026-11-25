# minty-quail — The end remeasure's numbers: winnability, route costs, the cost table, placement · 2026-11-24

**The ask.** The entry's remeasure (step 3 of its README) asks for the deterministic numbers once, at the
very end, set beside the design review's baseline readings (inbox #813 in curly-moose): winnability across
seeds, route costs, the cost table, `placement_rows.gd` compared with `tools/compare-placement-rows.py`,
and the test counts the fourth baseline list names. Nothing is judged in the readings; a number that moved
is listed here and playtest decides which deviations are fixed (inbox #1278 in olive-ferret).

**Measured on** `f98443b5b19ddada1899c13c4d939d84049ea453` (head), headless, Godot 4.7.2, one Godot run at a
time. The evidence is `docs/evidence/minty-quail-end-numbers-2026-11-24/` (its README holds the commands,
the loads and every figure; 69 files, 468 KB on disk). The "before" is the baseline folder's columns
(`v0.29.0`, and after row 4b, `b3693bee7`): every probe is deterministic for a tree, so no older tree was
run again.

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

Spread: every probe is deterministic, so each side is one reading, and head equals the after-4b column
line for line in the `RD`, `RV` and `RK` lines of `placement_rows.gd` (952), the whole output of
`polite_rabbit_wall_costs`, `m117_decay` (same lines; rows of its tables print in another order in several
places) and `m129_zero_cost_line`, and the role table (683 lines). The suite counts are in the evidence
README.

## What moved on purpose (named by the record that moved it)

- **Against v0.29.0:** the events' route cost halved and every route has a zero-cost line, from placement
  closed (polite-tapir-velvet-heron) and the one declared table (polite-tapir-coral-owl); the counts of the
  suites changed with their rewrites (the baseline README says so); walls on her route +51% and friction
  -67%, -46% and -45% by view are the same placement redesign. Each is a listing; none is judged.
- **Since after 4b:** the `falloff_power` column left the cost table's geometry table (#1718, the last survey
  for code nothing reaches); `docs/COSTS.md`'s other 280 rows keep every cell, against `v0.29.0` too.

## What moved and no record in this folder names

- `test_acts` 45 to 8 checks (37 fewer), `test_finale` 9463 to 9459 (4 fewer) and `test_routes_closures`
  1850 to 1852 (2 more), all at 0 failures. Entry: no (counts of checks, no number a player feels).
- **The poster tear count** (minty-quail-29): 7 of 2200 tears send nobody (seed 6 day 9; seed 10 days 9 to
  14), where that record measured 39 (1.8%). A gameplay number gets no entry from the remeasure.
- The records' own still-open figures (polite-tapir-coral-owl: her route 0.87 of the seed tree, day 11
  under, the ramp day 14 at 1.14 times day 1): the ramp reads 1.13 from `placement_rows.gd`, and the ten
  cities of `ramp_cities.gd` read 0.95 to 1.51 (the record's nine and 4242 again); days 9 to 11 place 83.4,
  82.4 and 81.4 a city-day against 90.0 on day 1. Listed, not fitted.

## Listed, not fitted, not taken

- **The police patrol's share** (records minty-quail-downy-toad and -jolly-toad said it would be fitted
  here): not fitted. One declared table replaced the fitted ones (polite-tapir-coral-owl) and the player
  left a deviation to playtest (inbox #1278 in olive-ferret).
- **The later days' difficulty** is silver-ferret's to judge; the evidence README's N8 hands its numbers
  (events a city-day and the share whose rows end the day or hunt her, per day and per act: 12.7% in act 1,
  17.6%, 34.2%, 37.7% in act 4).
- **The overlapping-badge still** (minty-quail-15) needs a harness that does not exist: not taken.

## Defects reported

None: no run printed a SCRIPT ERROR or an engine error, every suite and probe exited 0, and every route has a
zero-cost line. One run, `placement_cells.gd`, was cut off by the harness's two-hour script limit and run
again alone; the first, half-written log is kept and labelled.

## Not measured

GoatCounter's counts (a released build is needed), the timings and the pictures belong to the remeasure's
other groups.
