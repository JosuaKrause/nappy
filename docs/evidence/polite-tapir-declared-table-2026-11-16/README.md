# polite-tapir, the declared table: the seed, the one pass, the acceptance run (2026-11-16)

**The question.** Placement step 3 of polite-tapir (`docs/todo/2026-11-11-polite-tapir/`) replaces
the fitted density tables with one declared table (`src/events/placement_density.gd`): events per
hundred draw locations by view, kind of ground and act, seeded once from main as it stood on
2026-11-09 and scaled once by one probe run. This folder holds the seed, the run the pass used,
the pass, the table it gave and the acceptance run, so a reviewer can read off it that the pass
was made once; and the probes on `origin/main` beside the branch's.

**The trees.**

- The seed tree: main on 2026-11-09, `38ce038231`, the "today" column of
  `docs/evidence/minty-quail-baseline-2026-11-09/`.
- Main today: `origin/main` at `281b673ae` (after #1473, the `UnitFills` seam; #1476, step 2's
  street rules; #1477, the dog walker, the patrol and the convoy sent ahead of her, drawn by no
  unit; #1486, who builds the events), measured in a detached scratch worktree of that commit.
- The branch: `feature-polite-tapir-declared-table`, built on that commit. The seed run
  (`cells_seed.txt`) is at the branch's commit `2768a9c16` (the seed table and the seed weights);
  the acceptance run and every other branch probe at `8150ce6d4` (the table after the pass, with
  the row weights read against the whole seed); the builder's reading's run (`builders_reading_*`)
  at `e4c3bd063` (the same table, the row weights compared among the rows a bag holds). After the
  branch is squash-merged all three are fetched with `git fetch origin refs/pull/1488/head`.

**The cities.** `90210 + 31 i`, `i` in 0 to 17, days 1 to 14, each day planned as
`tests/probes/walk_rows.gd` plans it (the same closures, seals, region wall and streams), so
252 city-days a run. Machine load was not controlled; the counts do not depend on it.

## The files

| File | What it is |
|---|---|
| `density_seed_probe_for_38ce038.gd` | the seed probe, written against the seed tree's API (the design's, unchanged) |
| `seed_main_1109.txt` | its output on `38ce038231` as the design recorded it (`SL`, `SE`, `RD` lines): the seed the cells are read from |
| `seed_rerun_38ce038.txt` | the same probe run again on `38ce038231` for this build, its measured lines alone |
| `seed_unit_rows.txt` | `seed_main_1109.txt` without the `SE` lines of the three rows no unit draws now (`dog_walker`, `police_patrol`, `military_convoy`): the seed a row's share is compared against |
| `seed_table.py` | reads a seed and prints the cells, the per-view rates and the row mix |
| `table_seed.json` | the seed table: the cells of `seed_main_1109.txt` and the design's seed weights |
| `cells_seed.txt` | `tests/probes/placement_cells.gd` on the branch with the seed table (`CL`, `CE` lines) |
| `compare_cells.py`, `compare_seed.txt` | a cells run beside the seed, by view, cell, day and row; that of the seed run |
| `one_pass.py`, `pass.log` | the pass and what it printed, run once: a row's share read against the whole seed, the reading applied |
| `pass_rows_among_the_rows_a_bag_holds_not_applied.log` | the row half of the pass given `seed_unit_rows.txt` as its fifth argument, a row's share compared among the rows a bag holds: the builder's reading, printed and not applied (below) |
| `table_pass_raw.json` | the table `one_pass.py` wrote |
| `table_pass.json` | the table the branch holds: `table_pass_raw.json` less the abduction's two weights |
| `cells_pass.txt`, `compare_pass.txt` | the acceptance run on the branch with that table, and it beside the seed (`--rows`) |
| `cells_beats.txt` | the `CP` lines of the acceptance run, sorted: the pacing rows' beats by ground and length in tiles |
| `main_cells.txt`, `compare_main.txt`, `main_cells_beats.txt` | the same probe on main today (copied into the scratch worktree), it beside the seed, and its `CP` lines |
| `branch_walk_rows_lines.txt`, `main_walk_rows_lines.txt` | `walk_rows.gd`'s `W` lines on the branch and on main |
| `branch_placement_rows_lines.txt`, `main_placement_rows_lines.txt` | `placement_rows.gd`'s `RD`, `RV`, `RK` lines on the branch and on main |
| `branch_m129_totals.txt`, `main_m129_totals.txt` | `m129_zero_cost_line.gd`'s totals on the branch and on main |
| `escape_roadblock_spacing.txt` | `escape_roadblock_spacing.gd` on the branch; main's output is the same but for its time line |
| `row_shares.py` | a row's share of a ground's events, a seed beside a run |
| `design_table_pass_cap95_rejected.json` | the design's rejected trial: a scaled cell capped at 95 instead of 50, which handed a park to the rows rare there once the street musician is refused |
| `builders_reading_catalogue.diff` | the builder's reading's row weights, as a change to the branch's catalogue (`pass_rows_among_the_rows_a_bag_holds_not_applied.log`, the abduction's street weight left unset) |
| `builders_reading_table_pass.json` | the table on the builder's reading, its abduction weight left out |
| `builders_reading_cells.txt`, `builders_reading_compare.txt`, `builders_reading_cells_beats.txt` | `placement_cells.gd` on the builder's reading (`CL`, `CE` lines), it beside the seed (`--rows`), and its `CP` lines |
| `builders_reading_placement_rows_lines.txt`, `builders_reading_walk_rows_lines.txt`, `builders_reading_m129_totals.txt` | `placement_rows.gd`, `walk_rows.gd` and `m129_zero_cost_line.gd` on the builder's reading |
| `two_readings_table.py`, `two_readings_table.txt` | the seed tree, the branch and the builder's reading side by side, row by row and view by view |
| `two_readings_costs.txt` | `test_events_costs.gd`'s day check and ramp check on the branch and on the builder's reading, their counts printed |
| `ramp_cities.txt` | the output of `tests/probes/ramp_cities.gd`, the costs suite's ramp check (day 14 placed over day 1) planned the same way on ten cities, on both readings |

## The commands

Each writes into a fresh scratch directory, `$OUT`, never over the files here.

```sh
OUT=$(mktemp -d)
E=docs/evidence/polite-tapir-declared-table-2026-11-16
# The seed, on a scratch checkout of the seed tree:
tools/agent-setup.sh --detach 38ce038231 seed-tree
cp $E/density_seed_probe_for_38ce038.gd .claude/worktrees/seed-tree/tests/probes/
(cd .claude/worktrees/seed-tree && ./tools/check.sh \
	&& ./tools/test.sh probes/density_seed_probe_for_38ce038.gd > "$OUT/seed.txt")

# A cells run on the branch (at the commit named above), and the other probes:
tools/test.sh probes/placement_cells.gd > "$OUT/cells.txt"
for p in walk_rows placement_rows m129_zero_cost_line placement_fingerprint escape_roadblock_spacing; do
	tools/test.sh probes/$p.gd > "$OUT/$p.txt"
done

# Main's side, on a scratch checkout of main with the cells probe copied in:
tools/agent-setup.sh --detach 281b673ae main-today
cp tests/probes/placement_cells.gd .claude/worktrees/main-today/tests/probes/
(cd .claude/worktrees/main-today && ./tools/check.sh \
	&& ./tools/test.sh probes/placement_cells.gd > "$OUT/main_cells.txt")

# The cells, the pass, and a run beside the seed:
python3 -I $E/seed_table.py $E/seed_main_1109.txt
python3 -I $E/one_pass.py $E/seed_main_1109.txt $E/cells_seed.txt $E/table_seed.json \
	"$OUT/table_pass_raw.json"
python3 -I $E/compare_cells.py $E/seed_main_1109.txt $E/cells_pass.txt --rows
# The builder's reading's row half, printed and not applied:
python3 -I $E/one_pass.py $E/seed_main_1109.txt $E/cells_seed.txt $E/table_seed.json \
	"$OUT/table_builders.json" $E/seed_unit_rows.txt

# The builder's reading, measured: a throwaway copy of the branch with its row weights.
tools/agent-setup.sh --detach 8150ce6d4 builders
(cd .claude/worktrees/builders && git apply "$OLDPWD/$E/builders_reading_catalogue.diff" \
	&& ./tools/check.sh \
	&& for p in placement_cells placement_rows walk_rows m129_zero_cost_line; do
		./tools/test.sh probes/$p.gd > "$OUT/builders_$p.txt"; done)
python3 -I $E/two_readings_table.py $E/seed_main_1109.txt $E/cells_pass.txt \
	$E/builders_reading_cells.txt $E/branch_placement_rows_lines.txt \
	$E/builders_reading_placement_rows_lines.txt
# The costs suite's counts: a print of `real` before its day check and of `early`, `late` before its
# ramp check (the patch is in two_readings_costs.txt), then the suite on the branch and on the copy.
./tools/test.sh events_costs > "$OUT/costs.txt"
(cd .claude/worktrees/builders && ./tools/test.sh events_costs > "$OUT/builders_costs.txt")
# The ramp on ten cities: the probe in tests/probes/, on the branch and on the copy.
./tools/test.sh probes/ramp_cities.gd > "$OUT/ramp.txt"
tools/agent-setup.sh --remove builders   # after `git checkout .` in it
```

## The procedure, as run

1. **The seed tree measured again.** `seed_rerun_38ce038.txt` holds the same 1,059 measured lines
   as `seed_main_1109.txt`, in another order (the probe prints dictionaries, whose order differs
   from run to run): sorted, both hash to `f8860c8c152c925d` (`shasum -a 256`, first 16 digits).
   The seed tree's measurement did not move.
2. **The seed, every row counted.** Each cell is 100 times the rows the seed tree's draw recorded
   over the open draw locations, summed over the act's days and the 18 cities, at the full share of
   the walls, to two figures; a view and ground with fewer than a hundred events in the sample (the
   route-adjacent junction box, 8) takes its rate over every act, 2.5. The three rows the director
   now sends ahead of her (the dog walker, the police patrol, the military convoy: 25.9 of the seed
   tree's 99.2 events a city-day, half of a junction box's events) are counted, so the cells carry
   their density and a bag hands it to the rows a unit still draws: the city keeps about one event
   per block, the player's number that `tests/test_events_costs.gd` holds on day 1. The cells are
   the design's section 6.4 seed exactly. The moments a day of each act owes are the seed probe's
   `RD` lines averaged over the act: 26, 27, 29, 32. The seed weights are the design's: nothing in a
   junction box for the eight rows the seed tree never placed there, and the rows beside the street
   musician on open ground at their share there against his.
3. **One probe run** on the seed table: `cells_seed.txt`.
4. **The pass, once**: `one_pass.py` on that run, `pass.log`. Every view was off by more than a
   tenth (on the route x0.49, route-adjacent x1.21, off the route x0.83), so every view's cells were
   scaled, each by its own ratio, at most 50. **A row's share of a ground's events is read against
   the whole seed**, every row it counts included: the player's answer on the board
   (`box-rows-after-the-pass`, inbox #1464). The cells count the three rows a bag no longer
   holds, which were half of a junction box's events, and a bag hands their share to the rows it
   still holds, so those rows place more than on the seed tree on either reading; read against the
   whole seed, the pass cuts the charging dog, the chatting mother and the leaf blower in a box,
   and sets no weight on the delivery van, the poster crew, the reversing lorry and the roadblock on
   a street. Compared among the rows a bag holds instead (`one_pass.py`'s fifth argument,
   `seed_unit_rows.txt`: the builder's reading, which the branch was first built on, rejected), it leaves
   those three in a box at 3 to 4 times the seed tree's count and sets the four street rows at 2.2
   to 2.3 (`pass_rows_among_the_rows_a_bag_holds_not_applied.log`, printed and not applied;
   measured below, "The two readings of the row rule"). Thirteen row weights moved by more than a
   factor of two. By the player's answer on the board (option D: the pass's row weights as
   designed, the abduction's not set) the abduction's two weights (a street 0.17, a junction box
   0.28) are left out, so eleven are set; `table_pass.json` holds them, and nothing else differs
   from `table_pass_raw.json`. **No cell's last act came out under its first**, so no cell is
   floored (the first re-seed floored one, below).
5. **The acceptance run** on that table: `cells_pass.txt`. Nothing is scaled after it.

## What the runs show

Events per hundred draw locations, the seed tree's first, then each run as a multiple of it; main
today is the fitted tables as built:

| | Seed tree | Seed run | After the pass | Main today |
|---|---|---|---|---|
| on the route | 6.69 | x0.49 | x0.87 | x2.34 |
| route-adjacent | 7.92 | x1.21 | x1.02 | x1.12 |
| off the route | 7.63 | x0.83 | x0.96 | x2.36 |
| all | 7.37 | x0.82 | x0.95 | x2.01 |
| events the units place a city-day | 99.2 | 81.8 | 94.2 | 199.6 |

The seed tree's 99.2 holds the three rows the director now sends ahead of her; the branch's 94.2 is
what the units place alone, the director's rows on top of it. `placement_rows.gd`, the whole day
with the moments, a city-day: the seed tree 102.8, main today 201.8, the branch 98.4; day 1 88.5,
181.7 and 90.0.

**What is still off after the pass, listed for the end remeasure and fitted to nothing**
(`compare_pass.txt`):

- **On her route the units place 0.87 of the seed tree**: the junction boxes 0.77 and the parks
  and squares 0.50. The rules that keep her route open refuse more of a box's rows the later the
  act: the on-route box's act IV cell holds 46 events in a hundred and the day places 4.8 there
  against the seed tree's 11.8.
- **Parks and squares** hold 0.50 to 0.79 of the seed tree: a unit holds at most one of a row, and
  the street musician is nine tenths of what stands on open ground.
- **Rows off by more than a fifth**, a city-day on the row's days, seed tree then after the pass.
  On a street most of the rows a unit draws are up, since they now carry the three rows' share:
  the abduction 0.94, 5.76 (its weights left unset by the player's answer), the cafe 10.40, 18.74,
  the market stall 4.10, 7.32, the construction 3.56, 5.36, the chatting mother 1.57, 2.27, the
  leaf blower 5.81, 7.57; the four rows the pass set no street weight on are down or near, the
  delivery van 5.73, 4.21, the reversing lorry 2.67, 1.86 (the poster crew 5.61, 4.82 and the
  roadblock 5.90, 4.93 within a fifth). In a junction box: the abduction 1.35, 5.02, the chatting
  mother 0.43, 1.31, the pigeon flock 1.85, 4.12, the man shouting 1.84, 3.43, the leaf blower 0.81,
  1.36, the charging dog 1.22, 1.92. On open ground the street musician 7.55, 4.60; the rows rare
  there are a tenth of an event a city-day either way.
- **A day inside an act**: day 1 runs 2% over the seed tree, days 7 and 10 an eighth under and day
  11 a fifth under.
- **The ramp is flatter.** Day 14 places 1.14 times day 1, where the seed tree's placed 1.28 times,
  and days 9, 10 and 11 place fewer events than day 1 (80.6, 78.1 and 78.4 against 87.6): from day
  9, the first day the region wall stands, a unit draws half its walls, and five cells are lower
  than the act before them. `tests/test_events_costs.gd`'s bar, day 14 a fifth over day 1, passes on
  its city (134 placed against 89). On nine other cities planned the same way (`tests/probes/ramp_cities.gd`,
  `ramp_cities.txt`), three are over the bar and six under it (0.95 to 1.19 times); on the
  builder's reading one of the nine is over it.
- **The mix.** The units place 94.2 events a city-day against the 73.3 the seed tree's units placed
  without the three rows now sent ahead of her, so every other row is nearly a third more common
  on average, the most where the old daily caps held a row down.

## The two readings of the row rule

The pass compares a row's share of a ground's events with the seed's. The seed counts the dog
walker, the patrol and the convoy, half of a junction box's events, and no bag holds them now, so
the rule reads two ways: against the whole seed (the reading applied, `pass.log`), or among the
rows a bag holds (the builder's reading, `pass_rows_among_the_rows_a_bag_holds_not_applied.log`).
The player answered the board's question `box-rows-after-the-pass` for the first (inbox #1464),
and the second is rejected. The builder's reading's row weights are
`builders_reading_catalogue.diff` against the branch's catalogue: the delivery van 2.3 on a street,
the poster crew, the reversing lorry and the roadblock 2.2 there; the charging dog 0.3 on a street
and nothing in a junction box; the chatting mother 0.39 and 0.21; no leaf blower weight in a box;
the protest 4.5 in a box; the abduction left unset. Its acceptance run, made at `e4c3bd063` exactly
as the branch's, is `builders_reading_*`.

Events a city-day on the row's days, seed tree / branch / the builder's reading
(`two_readings_table.txt`):

| Row | Junction box | Street | Her route | The city |
|---|---|---|---|---|
| charging dog | 1.22 / 1.92 / 3.91 | 0.94 / 1.01 / 1.07 | 0.18 / 0.40 / 0.73 | 2.19 / 2.93 / 4.99 |
| chatting mother | 0.43 / 1.31 / 1.71 | 1.57 / 2.27 / 2.48 | 0.96 / 2.50 / 2.96 | 2.00 / 3.58 / 4.20 |
| leaf blower | 0.81 / 1.36 / 2.52 | 5.81 / 7.57 / 6.36 | 0.28 / 0.42 / 0.75 | 6.67 / 9.01 / 8.96 |
| abduction | 1.35 / 5.02 / 3.40 | 0.94 / 5.76 / 4.29 | 0 / 0 / 0 | 2.29 / 10.79 / 7.69 |
| delivery van | | 5.73 / 4.21 / 7.40 | 2.46 / 2.32 / 4.05 | 5.73 / 4.21 / 7.40 |
| poster crew | | 5.61 / 4.82 / 7.38 | 3.16 / 2.86 / 4.39 | 5.61 / 4.82 / 7.38 |
| reversing lorry | | 2.67 / 1.86 / 2.78 | 0 / 0 / 0 | 2.67 / 1.86 / 2.78 |
| roadblock | | 5.90 / 4.93 / 7.44 | 2.89 / 2.27 / 3.35 | 5.90 / 4.93 / 7.44 |
| protest | 8.96 / 8.69 / 9.28 | | 0.02 / 0.09 / 0.09 | 9.67 / 9.48 / 10.07 |

What the units place, events a city-day, seed tree / branch / the builder's reading: on the route
32.0 / 27.7 / 27.4, route-adjacent 27.4 / 28.1 / 26.8, off the route 39.8 / 38.4 / 36.9, the city
99.2 / 94.2 / 91.2. The whole day with the moments (`placement_rows.gd`): 102.8 / 98.4 / 93.3. Day
14 over day 1: x1.28 / x1.14 / x1.11; days 9 to 11 on the branch 80.6, 78.1 and 78.4, on the
builder's reading 76.3, 75.9 and 74.5.

So the reading applied holds the charging dog, the chatting mother and the leaf blower in a junction
box to about half, three quarters and half of what the builder's reading places, still 1.6, 3.0 and
1.7 times the seed tree's count there; the four street rows it leaves unweighed place 0.69 to 0.86
of the seed tree's count on a street where the builder's reading has them at 1.04 to 1.32; and what
it takes from the box rows goes to the rest of the bag, the abduction most (10.8 a city-day over the
city, against 7.7 on the builder's reading and 2.3 on the seed tree), the cafes on her route 6.5
against 4.9, so the units place 94.2 events a city-day against 91.2.

**One event per block holds under both.** `test_events_costs.gd` passes on each
(`two_readings_costs.txt`): on the suite's city, 121 blocks and a bar of 96, the day check counts
115, 138, 174 and 174 events on days 1, 3, 7 and 14 on the branch (the builder's reading 109, 140,
161 and 177), and the ramp check 89 placed on day 1 and 134 on day 14 (the builder's reading 83 and
135).

## The first re-seed, tried and replaced

The first build of this step seeded the cells **without** the three rows sent ahead of her (the
units' share of the seed tree, 73.3 events a city-day), made its one pass on that seed and its
acceptance run (commit `e23a93324` holds its `cells_seed.txt`, `cells_pass.txt` and tables). Its
figures, events per hundred draw locations against that seed: on the route 3.79, x0.52, x0.85;
route-adjacent 7.22, x1.24, x0.97; off the route 5.80, x0.87, x0.92; all 5.45, x0.91, x0.92; 73.3,
66.8 and 67.7 events a city-day. Sixteen row weights moved, and one cell was floored (on the route,
a junction box, act IV 9.5 raised to act I's 9.6).

**Why it was replaced.** `tests/test_events_costs.gd`'s one event per block on day 1, the player's
number (playtest 05, finding 6), failed: the suite's city placed 90 events against the bar's 96,
and 18 cities averaged about 95 on day 1 and 91 on days 3 and 7. The orchestrator decided to seed
from the seed tree with the three rows counted, so that their share of the density goes to the rows
the units still draw. That corrects the seed's input; the corrected seed went through the one pass
once, above.

## Main beside the branch

- **`walk_rows.gd`** (`branch_walk_rows_lines.txt`, `main_walk_rows_lines.txt`): `WC all`, the
  route tiles cut off from home after the dawn and at the end of her walk, is `0 0` on both. `WU
  all`, the units drawn on her walk and the longest chain of touching units each ranked below the
  last, is the same line on both (at reach 0, a chain of 28): the table changes no rank and no
  relation. `WS all`, what her walk sited: 132 places on the branch and 128 on main, none with an
  undrawn unit near it when sited, and the smallest gap to a row a unit drew 72px and 64px (no less
  than `EventScheduler.EVENT_SPACING_ANY`, 64px, on either). What streams in within her radius on
  her walk (`WD`, `WV`): 12,449 rows over the 252 city-days on the branch, 26,295 on main; on her
  route 3,632 and 8,291, route-adjacent 4,655 and 5,753, off it 4,162 and 12,251. The builder's
  reading (`builders_reading_walk_rows_lines.txt`): the same `WC` and `WU` lines, 126 places sited,
  11,835 rows streamed in.
- **`m129_zero_cost_line.gd`**: 299 of 299 routes keep a zero-cost line on both (the primary
  reading, and the catalogue's rows alone). Over a pacing row's whole beat: 146 of 299 on the
  branch, 138 on main (176 on the builder's reading, `builders_reading_m129_totals.txt`). Placed
  rows a day a line has to avoid: 326.3 on the branch, 326.2 on main (321.7 on the builder's
  reading).
- **`placement_fingerprint.gd`**: the `^FP escape ` and `^FP building ` lines (9,864) are identical
  on both, `8cc1a28243816a83` (`shasum -a 256` of those lines, first 16 digits). The `FP day`
  lines move, as the table moves what a day places.
- **`escape_roadblock_spacing.gd`**: identical on both, but for its time line and the boot's run
  line.
- **`placement_cells.gd` on main** (`compare_main.txt`): 199.6 events the units place a city-day,
  x2.01 the seed tree; the junction boxes x6.6 on the route and x6.2 off it, the fitted tables'
  doubled day.

## The pacing rows' beats

`CP` lines, beats drawn over the 252 city-days by ground and length in whole tiles (a beat is up to
eight tiles, `path_length_tiles`, as far as the unit's ground runs, `Location.run()`):

| Row, ground | Branch | Main today |
|---|---|---|
| chatting mother, street | 571: 421 of eight tiles, 122 of six or seven, 28 of one to four | 753: 545, 143, 65 |
| chatting mother, junction box | 331, one to five tiles | 18,011, one to five tiles |
| man shouting, street | 1,424: 995 of eight tiles, 317 of six or seven, 112 of one to five | 1,797: 1,271, 337, 189 |
| man shouting, junction box | 864, one to five tiles | 37, one to five tiles |
| man shouting, square | 35, one to three tiles | 16, one to three tiles |

## Limits

- The seed tree is main on 2026-11-09, not `v0.29.0` (the design's pick, open to overturn).
- A row's share read against the whole seed, not among the rows a bag holds, is the player's
  answer to the board's question `box-rows-after-the-pass` (inbox #1464); the builder's reading
  is measured beside it.
- Every number is over 18 cities and one stream per city-day; a cell with a hundred events moves
  by about a tenth from one sample to the next, which is why the pass is not repeated.
- A cell is what a unit's bag holds; what she meets on her walk is `walk_rows.gd`'s `WD`, `WV`,
  `WK` and `WM` lines, beside main's here.
