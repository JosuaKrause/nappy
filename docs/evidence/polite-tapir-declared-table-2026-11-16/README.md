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
  (`cells_seed.txt`) is at the branch's commit `2768a9c16` (the seed table and the seed weights),
  the acceptance run and every other branch probe at `e4c3bd063` (the table after the pass). After
  the branch is squash-merged both are fetched with `git fetch origin refs/pull/1488/head`.

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
| `one_pass.py`, `pass.log` | the pass and what it printed, run once |
| `pass_rows_against_the_whole_seed_not_applied.log` | the row half of the pass read against the whole seed instead, printed and not applied (below) |
| `table_pass_raw.json` | the table `one_pass.py` wrote |
| `table_pass.json` | the table the branch holds: `table_pass_raw.json` less the abduction's street weight |
| `cells_pass.txt`, `compare_pass.txt` | the acceptance run on the branch with that table, and it beside the seed (`--rows`) |
| `cells_beats.txt` | the `CP` lines of the acceptance run, sorted: the pacing rows' beats by ground and length in tiles |
| `main_cells.txt`, `compare_main.txt`, `main_cells_beats.txt` | the same probe on main today (copied into the scratch worktree), it beside the seed, and its `CP` lines |
| `branch_walk_rows_lines.txt`, `main_walk_rows_lines.txt` | `walk_rows.gd`'s `W` lines on the branch and on main |
| `branch_placement_rows_lines.txt`, `main_placement_rows_lines.txt` | `placement_rows.gd`'s `RD`, `RV`, `RK` lines on the branch and on main |
| `branch_m129_totals.txt`, `main_m129_totals.txt` | `m129_zero_cost_line.gd`'s totals on the branch and on main |
| `escape_roadblock_spacing.txt` | `escape_roadblock_spacing.gd` on the branch; main's output is the same but for its time line |
| `row_shares.py` | a row's share of a ground's events, a seed beside a run |
| `design_table_pass_cap95_rejected.json` | the design's rejected trial: a scaled cell capped at 95 instead of 50, which handed a park to the rows rare there once the street musician is refused |

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
	"$OUT/table_pass_raw.json" $E/seed_unit_rows.txt
python3 -I $E/compare_cells.py $E/seed_main_1109.txt $E/cells_pass.txt --rows
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
   scaled, each by its own ratio, at most 50. **A row's share of a ground's events is compared among
   the rows a bag holds** (`one_pass.py`'s fifth argument, `seed_unit_rows.txt`): read against the
   whole seed, the three rows a bag no longer holds sit in the seed's denominator alone, so every
   row in a junction box, where they were half the events, would read as twice its share without
   placing any more (`pass_rows_against_the_whole_seed_not_applied.log`: it cuts the abduction, the
   charging dog, the chatting mother and the leaf blower in a box for that reason alone). Fourteen
   row weights moved by more than a factor of two. By the player's answer on the board (option D:
   the pass's row weights as designed, the abduction's not set) the abduction's street weight (0.23)
   is left out, so thirteen are set; `table_pass.json` holds them, and nothing else differs from
   `table_pass_raw.json`. **No cell's last act came out under its first**, so no cell is floored
   (the first re-seed floored one, below).
5. **The acceptance run** on that table: `cells_pass.txt`. Nothing is scaled after it.

## What the runs show

Events per hundred draw locations, the seed tree's first, then each run as a multiple of it; main
today is the fitted tables as built:

| | Seed tree | Seed run | After the pass | Main today |
|---|---|---|---|---|
| on the route | 6.69 | x0.49 | x0.85 | x2.34 |
| route-adjacent | 7.92 | x1.21 | x0.98 | x1.12 |
| off the route | 7.63 | x0.83 | x0.93 | x2.36 |
| all | 7.37 | x0.82 | x0.92 | x2.01 |
| events the units place a city-day | 99.2 | 81.8 | 91.2 | 199.6 |

The seed tree's 99.2 holds the three rows the director now sends ahead of her; the branch's 91.2 is
what the units place alone, the director's rows on top of it. `placement_rows.gd`, the whole day
with the moments, a city-day: the seed tree 102.8, main today 201.8, the branch 93.3; day 1 88.5,
181.7 and 90.7.

**What is still off after the pass, listed for the end remeasure and fitted to nothing**
(`compare_pass.txt`):

- **On her route the units place 0.85 of the seed tree**: the junction boxes 0.71 and the parks
  and squares 0.51. The rules that keep her route open refuse more of a box's rows the later the
  act: the on-route box's act IV cell holds 46 events in a hundred and the day places 4.5 there
  against the seed tree's 11.8.
- **Parks and squares** hold 0.51 to 0.79 of the seed tree: a unit holds at most one of a row, and
  the street musician is nine tenths of what stands on open ground.
- **Rows off by more than a fifth**, a city-day on the row's days, seed tree then after the pass.
  On a street most of the rows a unit draws are up, since they now carry the three rows' share:
  the abduction 0.94, 4.29 (its weight left unset by the player's answer), the cafe 10.40, 15.54,
  the market stall 4.10, 6.10, the chatting mother 1.57, 2.48, the poster crew 5.61, 7.38, the
  delivery van 5.73, 7.41, the roadblock 5.90, 7.44, the construction 3.56, 4.40; the man shouting
  is down, 5.75, 4.12. In a junction box: the chatting mother 0.43, 1.71, the charging dog 1.22,
  3.91, the leaf blower 0.81, 2.52, the abduction 1.35, 3.41, the pigeon flock 1.85, 2.52. On open
  ground the street musician 7.55, 4.62; the rows rare there are a tenth of an event a city-day
  either way.
- **A day inside an act**: day 1 runs 3% over the seed tree, day 7 a fifth under and day 11 23%
  under.

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
  all`'s longest chain of touching units each ranked below the last, at reach 0: WALK_WU_BRANCH on
  the branch, 28 on main. `WS all`, what her walk sited: WALK_WS_BRANCH on the branch, 128 sitings,
  none on undrawn ground, on main.
- **`m129_zero_cost_line.gd`**: 299 of 299 routes keep a zero-cost line on both (the primary
  reading, and the catalogue's rows alone). Over a pacing row's whole beat: 176 of 299 on the
  branch, 138 on main. Placed rows a day a line has to avoid: 321.7 on the branch, 326.2 on main.
- **`placement_fingerprint.gd`**: the `^FP escape ` and `^FP building ` lines (9,864) are identical
  on both, `8cc1a28243816a83` (`shasum -a 256` of those lines, first 16 digits). The `FP day`
  lines move, as the table moves what a day places.
- **`escape_roadblock_spacing.gd`**: identical on both, but for its time line.
- **`placement_cells.gd` on main** (`compare_main.txt`): 199.6 events the units place a city-day,
  x2.01 the seed tree; the junction boxes x6.6 on the route and x6.2 off it, the fitted tables'
  doubled day.

## The pacing rows' beats

`CP` lines, beats drawn over the 252 city-days by ground and length in whole tiles (a beat is up to
eight tiles, `path_length_tiles`, as far as the unit's ground runs, `Location.run()`):

| Row, ground | Branch | Main today |
|---|---|---|
| chatting mother, street | 626: 450 of eight tiles, 132 of six or seven, 44 of one to three | 753: 545, 143, 65 |
| chatting mother, junction box | 432, one to five tiles | 18,011, one to five tiles |
| man shouting, street | 1,039: 728 of eight tiles, 229 of six or seven, 82 of one to five | 1,797: 1,271, 337, 189 |
| man shouting, junction box | 551, one to five tiles | 37, one to five tiles |
| man shouting, square | 35, one to three tiles | 16, one to three tiles |

## Limits

- The seed tree is main on 2026-11-09, not `v0.29.0` (the design's pick, open to overturn).
- A row's share compared among the rows a bag holds, not against the whole seed, is this build's
  reading of the design's row rule once the seed counts rows no bag holds; open to overturn, with
  the other reading's output beside it.
- Every number is over 18 cities and one stream per city-day; a cell with a hundred events moves
  by about a tenth from one sample to the next, which is why the pass is not repeated.
- A cell is what a unit's bag holds; what she meets on her walk is `walk_rows.gd`'s `WD`, `WV`,
  `WK` and `WM` lines, beside main's here.
