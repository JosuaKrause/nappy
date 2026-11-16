# polite-tapir, the declared table: the seed, the one pass, the acceptance run (2026-11-16)

**The question.** Placement step 3 of polite-tapir (`docs/todo/2026-11-11-polite-tapir/`) replaces
the fitted density tables with one declared table (`src/events/placement_density.gd`): events per
hundred draw locations by view, kind of ground and act, seeded once from main as it stood on
2026-11-09 and scaled once by one probe run. This folder holds the seed, the run the pass used,
the pass, the table it gave and the acceptance run, so a reviewer can read off it that the pass
was made once.

**The trees.**

- The seed tree: main on 2026-11-09, `38ce038231`, the "today" column of
  `docs/evidence/minty-quail-baseline-2026-11-09/`.
- The branch: `feature-polite-tapir-declared-table`, built on `origin/main` at `281b673ae`
  (after #1473, the `UnitFills` seam; #1476, step 2's street rules; #1477, the dog walker, the
  patrol and the convoy sent ahead of her, drawn by no unit; #1486, who builds the events). The
  seed run (`cells_seed.txt`) is at the branch's commit `5645cdb75` with the seed table, the
  acceptance run (`cells_pass.txt`) at `7c6e0a2f0`; after the branch is squash-merged both are
  fetched with `git fetch origin refs/pull/<the pull request>/head`.

**The cities.** `90210 + 31 i`, `i` in 0 to 17, days 1 to 14, each day planned as
`tests/probes/walk_rows.gd` plans it (the same closures, seals, region wall and streams), so
252 city-days a run. Machine load was not controlled; the counts do not depend on it.

## The files

| File | What it is |
|---|---|
| `density_seed_probe_for_38ce038.gd` | the seed probe, written against the seed tree's API (the design's, unchanged) |
| `seed_main_1109.txt` | its output on `38ce038231` as the design recorded it (`SL`, `SE`, `RD` lines) |
| `seed_rerun_38ce038.txt` | the same probe run again on `38ce038231` for this build, its measured lines alone |
| `seed_unit_rows.txt` | `seed_main_1109.txt` without the `SE` lines of the three rows no unit draws now (`dog_walker`, `police_patrol`, `military_convoy`): the seed the cells are read from |
| `seed_table.py` | reads a seed and prints the cells, the per-view rates and the row mix |
| `table_seed.json` | the seed table: the cells of `seed_unit_rows.txt` and the design's seed weights |
| `cells_seed.txt` | `tests/probes/placement_cells.gd` on the branch with the seed table (`CL`, `CE` lines) |
| `compare_cells.py`, `compare_seed.txt` | that run beside the seed, by view, cell, day and row |
| `one_pass.py`, `pass.log` | the pass (the design's script, unchanged) and what it printed, run once |
| `table_pass_raw.json` | the table `one_pass.py` wrote |
| `table_pass.json` | the table the branch holds: `table_pass_raw.json` less the abduction's street weight, and one cell floored (below) |
| `cells_pass.txt`, `compare_pass.txt` | the acceptance run on the branch with that table, and it beside the seed |
| `cells_beats.txt` | the `CP` lines of `placement_cells.gd` at the branch's head (its `CL`, `CE` lines identical to `cells_pass.txt`, sorted): the pacing rows' beats by ground and length in tiles |
| `branch_walk_rows_lines.txt`, `branch_placement_rows_lines.txt`, `branch_m129_totals.txt` | `walk_rows.gd`'s `W` lines, `placement_rows.gd`'s `RD`, `RV`, `RK` lines and `m129_zero_cost_line.gd`'s totals on the branch at `7c6e0a2f0`; the same probes on `origin/main` are not recorded here yet |
| `row_shares.py` | a row's share of a ground's events, a seed beside a run |
| `design_table_pass_cap95_rejected.json` | the design's rejected trial: a scaled cell capped at 95 instead of 50, which handed a park to the rows rare there once the street musician is refused |

## The commands

Each writes into a fresh scratch directory, `$OUT`, never over the files here.

```sh
OUT=$(mktemp -d)
# The seed, on a scratch checkout of the seed tree:
tools/agent-setup.sh --detach 38ce038231 seed-tree
cp docs/evidence/polite-tapir-declared-table-2026-11-16/density_seed_probe_for_38ce038.gd \
	.claude/worktrees/seed-tree/tests/probes/
(cd .claude/worktrees/seed-tree && ./tools/check.sh \
	&& ./tools/test.sh probes/density_seed_probe_for_38ce038.gd > "$OUT/seed.txt")

# A cells run on the branch (at the commit named above):
tools/test.sh probes/placement_cells.gd > "$OUT/cells.txt"

# The seed without the rows no unit draws now, its cells, the pass, and a run beside the seed:
E=docs/evidence/polite-tapir-declared-table-2026-11-16
grep -vE '^SE .* (dog_walker|police_patrol|military_convoy) ' $E/seed_main_1109.txt > "$OUT/seed_unit_rows.txt"
python3 -I $E/seed_table.py "$OUT/seed_unit_rows.txt"
python3 -I $E/one_pass.py $E/seed_unit_rows.txt $E/cells_seed.txt $E/table_seed.json "$OUT/table_pass_raw.json"
python3 -I $E/compare_cells.py $E/seed_unit_rows.txt $E/cells_pass.txt --rows
```

## The procedure, as run

1. **The seed tree measured again.** `seed_rerun_38ce038.txt` holds the same 1,059 measured lines
   as `seed_main_1109.txt`, in another order (the probe prints dictionaries, whose order differs
   from run to run): sorted, both hash to `f8860c8c152c925d` (`shasum -a 256`, first 16 digits).
   The seed tree's measurement did not move.
2. **The seed read for what a unit draws now.** Since #1477 the dog walker, the police patrol and
   the military convoy are sent ahead of her by the director and drawn by no unit, so no cell
   holds them: their `SE` lines are left out (`seed_unit_rows.txt`). Each cell is then 100 times
   the rows drawn over the open draw locations, summed over the act's days and the 18 cities, at
   the full share of the walls, to two figures; a view and ground with fewer than a hundred events
   in the sample (the route-adjacent junction box, 3) takes its rate over every act. The moments a
   day of each act owes are the seed probe's `RD` lines averaged over the act: 26, 27, 29, 32. The
   seed weights are the design's: nothing in a junction box for the eight rows the seed tree never
   placed there, and the rows beside the street musician on open ground at their share there
   against his.
3. **One probe run** on the seed table: `cells_seed.txt`.
4. **The pass, once**: `one_pass.py` on that run, `pass.log`. Every view was off by more than a
   tenth (on the route x0.52, route-adjacent x1.24, off the route x0.87), so every view's cells were
   scaled, each by its own ratio, at most 50; sixteen row weights moved by more than a factor of
   two. Then, by the player's answer on the board (option D: the pass's row weights as designed,
   the abduction's not set), the abduction's street weight (0.25) is left out; and the one cell
   whose last act came out under its first (on the route, a junction box: 9.6, 9.2, 7.7, 9.5, act
   IV taking its view and ground's all-act ratio for want of a hundred seed events) takes its first
   act's 9.6, so the difficulty ramp the table's own test holds stands. Both are in
   `table_pass.json`; nothing else differs from `table_pass_raw.json`.
5. **The acceptance run** on that table: `cells_pass.txt`. Nothing is scaled after it.

## What the runs show

Events per hundred draw locations, the seed's first, then each run as a multiple of it:

| | Seed (unit rows) | Seed table | After the pass |
|---|---|---|---|
| on the route | 3.79 | x0.52 | x0.85 |
| route-adjacent | 7.22 | x1.24 | x0.97 |
| off the route | 5.80 | x0.87 | x0.92 |
| all | 5.45 | x0.91 | x0.92 |
| events a city-day | 73.3 | 66.8 | 67.7 |

The seed tree's whole day was 99.2 events a city-day; the three rows sent ahead of her now were
25.9 of them, so the units' share of it is 73.3.

**What is still off after the pass, listed for the end remeasure and fitted to nothing**
(`compare_pass.txt`):

- **On her route the units place 0.85 of the seed**: the junction boxes 0.58 and the parks and
  squares 0.51. The rules that keep her route open refuse more of a box's rows than of a street's,
  and the same pass moved the box rows' weights (the chatting mother down, the protest up).
- **Parks and squares** hold 0.51 to 0.79 of the seed: a unit holds at most one of a row, and the
  street musician is nine tenths of what stands on open ground.
- **Rows off by more than a fifth**, a city-day on the row's days, seed then after the pass: the
  abduction on streets 0.94, 3.22 (its weight left unset by the player's answer) and in junction
  boxes 1.35, 2.04; the pigeon flock on streets 2.64, 1.56 and in boxes 1.85, 0.92; the protest in
  boxes 8.96, 5.24; the reversing lorry on streets 2.67, 2.00; the street musician 7.55, 4.62;
  the charging dog in boxes 1.22, 1.71; the leaf blower in boxes 0.81, 1.10.
- **A day inside an act**: day 1 runs 9% over the seed, days 7 and 11 about a fifth under.

## Limits

- The seed tree is main on 2026-11-09, not `v0.29.0` (the design's pick, open to overturn).
- Leaving the three rows sent ahead of her out of the seed is this build's reading, open to
  overturn: the units place the seed tree's other rows, and the day as a whole is thinner than the
  seed tree's by what those three placed.
- Every number is over 18 cities and one stream per city-day; a cell with a hundred events moves
  by about a tenth from one sample to the next, which is why the pass is not repeated.
- A cell is what a unit's bag holds; what she meets on her walk is `tests/probes/walk_rows.gd`'s,
  listed in the pull request beside main's.
