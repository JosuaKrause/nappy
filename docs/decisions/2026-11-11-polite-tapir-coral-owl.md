# polite-tapir — One declared table replaces the six fitted ones (placement step 3) · 2026-11-16



**The ask.** Placement step 3 of `placement-by-construction.md`: the density of the city's events is one declared table,
seeded once from what main placed and scaled once by one probe run, and the six fitted tables go. The player approved the
design review's points (inbox #1268 in olive-ferret). The measured table is held to the player's number, one event per
block (PLAYTEST-05 6), which `tests/test_events_costs.gd` checks on day 1.

**Who did what.** A Fable agent wrote the design (`placement-declared-table-design.md`, a brief, not in the repository) and
the pull request is its second half, #1488, after #1473, the seam. The evidence is
`docs/evidence/polite-tapir-declared-table-2026-11-16/` (its README has the commands, the files and every figure below).

## What was built

- **`PlacementDensity`** (`src/events/placement_density.gd`, data): the events a unit's bag holds for every hundred draw
  locations, by view (on the route, route-adjacent, off the route), kind of ground (street, junction box, alley, park or
  square) and act, 48 cells; and the moments an act owes her, 26, 27, 29, 32 for acts I to IV.
- **`UnitFills`** (model): turns the table into a bag fill for each view and ground, once a day, handed to `UnitDraw`. A row's
  marble is weighed by its weight, what its view is to its role, and the draw locations it speaks for. No row speaks for a
  whole street, since no unit draws one after #1477; the design's six for a whole street do not apply.
- **`EventDef.weigh_on()` / `weight_on()`**: a row's weight on a kind of ground, a multiple of its `weight`, kept in an
  exported field so every copy of the row keeps it. A kind of ground the row's `placement` holds weighs one; `validate()`
  refuses a weight on ground the row cannot stand on. `PlacementGround.holds()` says which tile types each kind holds.
- **The 17 row weights**: the design's seed set 14 on rows; the one pass moved four of them and set nine more, fifteen
  rows in all with 23 weights, the abduction's street and junction-box weights unset by the player's answer (below).
- **Deleted**: `VIEW_SHARES`, `VIEW_SHARE_SCALES`, `WALL_VIEW_SCALES`, `FRICTION_VIEW_SCALES`, `GROUND_WEIGHTS` and
  `MOMENTS_PER_DAY`, and with them `EventScheduler.view_weight()`, `view_fills()` and `ground_weight()`.
- **Reads that changed**: `RuledLocationGround.scale()` no longer counts a row's weight on its ground (a location's weight is
  its own ground's alone); `DawnMoments` reads `PlacementDensity.moments_on()`; `UnitFills` asks `EventDef.ends_the_day()`
  rather than reading `hard_fail`; `DaySpec.share_of_walls_drawn()` is the one reader of `wall_row_share` that the
  field-read check allows.
- **Doc sentences made true**: the balance skill and the events skill's `references/fields.md` name the declared table and a
  row's weight on a ground; `CLAUDE.md`'s balance row and the rules hook gain the two new files; `docs/EVENTS.md` says how the
  cells were set and that `chatting_mother` and `homeless_yeller` pace up to eight tiles along a street's sidewalk and one to
  five inside a junction box.

## The measurements

Seed tree: main as it stood on 2026-11-09, `38ce038231`. Main today: `281b673ae`. 18 cities by days 1 to 14, 252 city-days
a run. A "run" is `tests/probes/placement_cells.gd`.

- **The seed tree measured again** gives the same 1,059 lines as the design's seed, in another order; sorted, both hash to
  `f8860c8c152c925d`.
- **The seed run against the seed tree, events per hundred draw locations**: on the route 6.69, run x0.49; route-adjacent
  7.92, x1.21; off the route 7.63, x0.83; the units place 99.2 events a city-day on the seed tree, 81.8 on the run. Every
  view was more than a tenth off, so the one pass scaled each view's cells by its own ratio, at most 50, and moved fourteen
  row weights.
- **The acceptance run, after the pass**: on the route x0.85, route-adjacent x0.98, off the route x0.93, 91.2 events a
  city-day (the director's three rows on top). Main today is x2.34, x1.12, x2.36 and 199.6, twice the seed tree.
- **The whole day, moments included**, a city-day: the seed tree 102.8, main today 201.8, the branch 93.3; on day 1, 88.5,
  181.7 and 90.7.
- **One event per block holds**: `test_events_costs` passes on days 1, 3, 7 and 14.
- **Free line**: `m129_zero_cost_line.gd` 299 of 299 routes keep a zero-cost line on both branch and main; over a pacing row's
  whole beat 176 of 299 on the branch, 138 on main.
- **The escape and building placement fingerprints** (`^FP escape `, `^FP building `, 9,864 lines) are identical on both,
  `8cc1a28243816a83`; `escape_roadblock_spacing.gd` is identical. The `FP day` lines move, as a table moves a day.
- **Her walk**: `WC all` is `0 0` on both; what streams in within her radius is 11,835 rows on the branch and 26,295 on main.
- **Still off, listed for the end remeasure and fitted to nothing**: on her route the units place 0.85 of the seed tree
  (junction boxes 0.71, parks and squares 0.51, since the rules that keep her route open refuse more of a box's rows the
  later the act); days 7 and 11 are a fifth under; most street rows are up, since they carry the three sent-ahead rows'
  share; the abduction is 0.94 to 4.29 a city-day on its days. The design's seed-run hash does not match, since #1476 and
  #1477 moved the tree; the fill itself is the prototype's, 336 of 336 fills identical.
- **The pacing rows**: 1,058 chatting mothers drawn, 626 on a street (450 at eight tiles), 432 in a box at one to five;
  1,625 men shouting, 1,039 on a street, 551 in a box, 35 on a square.

## Decided, with its source

- **Option D: the abduction's two weights are not set.** The pass's row weights stand as designed, except the abduction's
  street weight (0.23) and junction-box weight (0.45): the player's answer on the board on 2026-11-15 (inbox #1464), where they
  answered the design's open picks as the design's, option D being the exception. So thirteen of the pass's fourteen moved weights
  are set.
- **The seed counts every row the seed tree placed.** The cells are the design's section 6.4 seed exactly, including the
  dog walker, the police patrol and the military convoy, 25.9 of the seed tree's 99.2 events a city-day; their share of
  the density goes to the rows a unit still draws. The orchestrator's decision, to keep the player's "one event per block"
  (PLAYTEST-05 6).
- **The design's other picks stand** (section 14): the seed is main on 2026-11-09; each cell is scaled by its own ratio; a
  scaled cell stops at 50 per hundred; the table's ground is the unit's four kinds; a cell with too few events takes its
  view and ground's rate over all acts (the route-adjacent junction box, 2.5); the moments are a number an act;
  `PlacementUnit.Kind` moves to data as `PlacementGround.Kind`; the role-by-view weights stay where they are and are handed
  in.

## Rejected

- **The first re-seed, without the three sent-ahead rows.** It seeded the cells from the units' share alone, 73.3 events a
  city-day, and made its one pass: on the route 3.79, x0.52, x0.85; route-adjacent 7.22, x1.24, x0.97; off the route 5.80,
  x0.87, x0.92; 66.8 then 67.7 events a city-day; sixteen row weights moved and one cell was floored. It broke the bar:
  `test_events_costs`'s one event per block on day 1 placed 90 events on the suite's city against 96, and 18 cities averaged
  about 95 on day 1 and 91 on days 3 and 7. Its runs are commit `e23a93324`.
- **Lowering the bar** (the test's one event per block): it is the player's number (PLAYTEST-05 6), and a measurement does
  not change it.
- **Raising the moments** to make up the difference: the moments are a number an act, measured from the seed tree's own
  days (26, 27, 29, 32). Raising them would hide a seed that dropped the three sent-ahead rows behind a number measured
  without that error, and the cells would still be the wrong ones.
- **The design's other alternatives** (section 14): the seed from `v0.29.0` by multiplying every cell once; one factor for a
  whole view, which leaves act I half again too dense on her route and act IV a quarter too thin; no row touched, or every
  row weight seeded from main (a fitted table of some forty numbers on the catalogue); no stop at 50, which makes the rows
  rare on open ground several times as common once the street musician is refused (a stop at 95 is kept as
  `design_table_pass_cap95_rejected.json`); the location's five kinds of ground, which needs a bag per kind inside a street
  and undoes the one bag; every marble once, with three rows' weights raised instead; deriving a row's refused ground at
  dawn from the day's ground; a number of moments a day; the role-by-view weights moved into the table.
- **Reading a row's share against the whole seed.** The three sent-ahead rows no bag holds would sit in the seed's
  denominator alone, so every junction-box row, where they were half the events, would read as twice its share without
  placing any more, and the pass would cut the abduction, the charging dog, the chatting mother and the leaf blower in a
  box for that reason alone. Its output is `pass_rows_against_the_whole_seed_not_applied.log`, printed and not applied.

## Choices open to overturn

- **A row's share is compared among the rows a bag holds** (`one_pass.py`'s fifth argument), the build's reading of the
  design's row rule once the seed counts rows no bag holds.
- **The gatehouse test's kept line**: the write to `wall_row_share` in `tests/test_events_scheduler.gd`, a kept line of
  `tools/test_only_members.txt` with its reason, since the field-read check refuses a new reader.
- **No cell is floored**: the first re-seed's floor binds nothing on this pass.

## The felt change

Main places about twice the seed tree's events, six times over in the junction boxes: a doubled day. This step brings it back
to about the seed tree's, one event per block again, and her route a little thinner than it was (0.85).

## What is left of the item

Steps 4 and 5 of `placement-by-construction.md` stay open: the beats become rigged marbles and the old siting roll goes, and
the escape city's draw is the same unit draw.
