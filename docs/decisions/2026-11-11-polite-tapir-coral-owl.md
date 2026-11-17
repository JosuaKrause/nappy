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
- **21 weights on fifteen rows**: the design's seed set 14; the one pass moved four of them and set seven more. The
  pass also set the abduction's two weights, which are left unset by the player's answer (below).
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
  view was more than a tenth off, so the one pass scaled each view's cells by its own ratio, at most 50, and moved
  thirteen row weights.
- **The acceptance run, after the pass**: on the route x0.87, route-adjacent x1.02, off the route x0.96, 94.2 events a
  city-day (the director's three rows on top). Main today is x2.34, x1.12, x2.36 and 199.6, twice the seed tree.
- **The whole day, moments included**, a city-day: the seed tree 102.8, main today 201.8, the branch 98.4; on day 1, 88.5,
  181.7 and 90.0.
- **One event per block holds**: `test_events_costs` passes on days 1, 3, 7 and 14.
- **Free line**: `m129_zero_cost_line.gd` 299 of 299 routes keep a zero-cost line on both branch and main; over a pacing row's
  whole beat 176 of 299 on the branch, 138 on main.
- **The escape and building placement fingerprints** (`^FP escape `, `^FP building `, 9,864 lines) are identical on both,
  `8cc1a28243816a83`; `escape_roadblock_spacing.gd` is identical. The `FP day` lines move, as a table moves a day.
- **Her walk**: `WC all` is `0 0` on both; what streams in within her radius is 11,835 rows on the branch and 26,295 on main.
- **Still off, listed for the end remeasure and fitted to nothing**: on her route the units place 0.87 of the seed tree
  (junction boxes 0.77, parks and squares 0.50, since the rules that keep her route open refuse more of a box's rows the
  later the act); day 11 is a fifth under and days 7 and 10 an eighth; the abduction is 0.94 to 5.76 a city-day on a
  street on its days; the four street rows the pass set no weight on place 0.69 to 0.86 of the seed tree's count on a
  street (the delivery van 0.73, the poster crew 0.86, the reversing lorry 0.69, the roadblock 0.84). The
  design's seed-run hash does not match, since #1476 and #1477 moved the tree; the fill itself is the prototype's, 336 of
  336 fills identical.
  - **The mix**: the units place 94.2 events a city-day against the 73.3 the seed tree's units placed without the three
    rows now sent ahead of her, so every other row is nearly a third more common on average, and most of all the rows
    the old daily caps held down: in a junction box the abduction 3.7 times the seed tree's count, the chatting mother
    3.0 times, the pigeon flock 2.2, the man shouting 1.9, the leaf blower 1.7 and the charging dog 1.6.
  - **The ramp is flatter**: day 14 places 1.14 times day 1, where the seed tree's placed 1.28 times, and days 9, 10 and
    11 place fewer events than day 1 (80.6, 78.1 and 78.4 against 87.6), since from day 9 a unit draws half its walls
    and five cells are lower than the act before them (`docs/EVENTS.md`). `test_events_costs`'s bar, day 14 a fifth
    over day 1, passes on its city (134 placed against 89); RAMPCITIES Whether the bar or the table is wrong is a
    question for the orchestrator to put, under the balance skill's rule that a test pushing back asks which of the two
    is wrong.
- **The pacing rows**: 902 chatting mothers drawn, 571 on a street (421 at eight tiles), 331 in a box at one to five;
  2,323 men shouting, 1,424 on a street, 864 in a box, 35 on a square.

## Decided, with its source

- **Option D: the pass sets the row weights, and none on the abduction.** The player's answer on the board's row-weights
  question on 2026-11-15 (inbox #1464), one of the two questions of this step they answered (the other is the reading of
  the row rule, below): they have never seen an abduction in play and do not mind a higher rate, and they picked option
  D, the pass's row weights as designed without the abduction's.
  The design's table had two for it (a street 0.23, a junction box 0.45); this branch's pass set two (a street 0.17, a
  junction box 0.28), and both are left out, so eleven of the pass's thirteen moved weights are set.
- **A row's share is read against the whole seed** (`one_pass.py` without its fifth argument), every row the seed counts
  included. The player's answer on the board's question `box-rows-after-the-pass` on 2026-11-16, "okay" to the
  orchestrator's pick of this reading (inbox #1464). The question as shown set the two readings side by side with their
  figures: the builder's reading, a row's share compared among the rows a bag holds, which the branch was first built
  on ("Rejected"), and this one. The pick's reasons, as the question gave them:
  - the board reply the player picked option D from said that under it the abduction stands higher and "the convoy, the
    protest and the rest come back to main's share", and it named the charging dog and the chatting mother in junction
    boxes among the rows off by more than a factor of two (inbox #1464); the review of #1488 found that the builder's
    reading left those rows three to four times the seed tree's count in a junction box;
  - this reading brings the charging dog, which ends the day, from 5.0 to 2.9 a city-day (the seed tree 2.2), and in a
    junction box from 3.9 to 1.9 (1.2);
  - the whole day comes from 93.3 events a city-day to 98.4 (the seed tree 102.8), and day 14 over day 1 from 1.11 to 1.14
    times (1.28).

  Its costs, which the question named: the abduction rises to 10.8 a city-day on its days (7.7 on the builder's reading,
  2.3 on the seed tree), which the player had accepted higher; and the delivery van, the poster crew, the reversing lorry
  and the roadblock, on which it sets no street weight, place 0.69 to 0.86 of the seed tree's count on a street. It is
  not a refit: it is the one pass's other output, printed by the same run, with option D still holding. One event per
  block holds under it: `test_events_costs` on its city (121 blocks, a bar of 96) counts COSTSAPPLIED.
- **What option D was told, and what is left of it.** The charging dog and the chatting mother come nearer main's share
  on this reading but not back to it: in a junction box the charging dog places 1.6 times the seed tree's count and the
  chatting mother 3.0 times, over the whole city 1.3 and 1.8 times ("The felt change", below).
- **The seed counts every row the seed tree placed.** The cells are the design's section 6.4 seed exactly, including the
  dog walker, the police patrol and the military convoy, 25.9 of the seed tree's 99.2 events a city-day; their share of
  the density goes to the rows a unit still draws. The orchestrator's decision, to keep the player's "one event per block"
  (PLAYTEST-05 6).

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
- **Options A, B and C of the row-weights question**: A set the abduction's weights too, B touched no row, C seeded every
  row's weight from main (some forty fitted numbers on the catalogue); the player picked D (inbox #1464).
- **The builder's reading: a row's share compared among the rows a bag holds** (`one_pass.py`'s fifth argument,
  `seed_unit_rows.txt`; `pass_rows_among_the_rows_a_bag_holds_not_applied.log`), the reading the branch was first built
  on, since it compares like with like once the seed counts rows no bag holds; the player answered
  `box-rows-after-the-pass` for the other (inbox #1464). The cells count the dog walker, the police patrol and the
  military convoy, which were half of a junction box's events, and a bag hands their share to the rows it still holds,
  so on either reading those rows place more than on the seed tree. Its acceptance run, made exactly as the branch's on
  the same 18 cities by 14 days (`builders_reading_*` and `two_readings_table.txt` in the evidence folder), events a
  city-day on the row's days, the seed tree's / the builder's reading / the reading applied:
  - it set the delivery van 2.3 on a street and the poster crew, the reversing lorry and the roadblock 2.2, which
    brought them to 1.04 to 1.32 times the seed tree's count there (0.69 to 0.86 on the reading applied);
  - it left the rows the old caps held down high in a junction box: the charging dog 1.22 / 3.91 / 1.92, the chatting
    mother 0.43 / 1.71 / 1.31, the leaf blower 0.81 / 2.52 / 1.36; over the city the charging dog 2.19 / 4.99 / 2.93
    and the chatting mother 2.00 / 4.20 / 3.58;
  - the units placed 91.2 events a city-day (94.2), the whole day with the moments 93.3 (98.4), the abduction 7.7
    (10.8), cafes on her route 4.9 (6.5), and day 14 1.11 times day 1 (1.14);
  - one event per block held under it too: `test_events_costs` counted COSTSBUILDER.

## Choices open to overturn

- **The design's picks, not answered by the player** (section 14); each with its alternative:
  - the seed is main on 2026-11-09; *alternative*: `v0.29.0`'s density, every cell multiplied once;
  - each cell of a view that is off is scaled by its own ratio; *alternative*: one factor a view, which leaves act I half
    again too dense on her route and act IV a quarter too thin;
  - a scaled cell stops at 50 per hundred; *alternative*: no stop, which makes the rows rare on open ground several times
    as common once the street musician is refused (a stop at 95 is kept as `design_table_pass_cap95_rejected.json`);
  - the table's ground is the unit's four kinds; *alternative*: the location's five kinds, which needs a bag per kind
    inside a street and undoes the one bag;
  - a marble weighs as the draw locations it speaks for; *alternative*: every marble once, with rows' weights raised
    instead;
  - a row that never stands on a ground though its tiles lie there is weighed at nothing there, on the row;
    *alternative*: derive it from the day's ground at dawn;
  - a cell with too few events takes its view and ground's rate over all acts (the route-adjacent junction box, 2.5);
    *alternative*: the off-the-route junction box's cells;
  - the moments are a number an act; *alternative*: a number a day;
  - `PlacementUnit.Kind` moves to data as `PlacementGround.Kind`; *alternative*: a second enum in data with the same
    members;
  - the role-by-view weights stay where they are and are handed in; *alternative*: moved into the table.
- **The gatehouse test's kept line**: the write to `wall_row_share` in `tests/test_events_scheduler.gd`, a kept line of
  `tools/test_only_members.txt` with its reason, since the field-read check refuses a new reader.
- **No cell is floored**: the first re-seed's floor binds nothing on this pass.

## The felt change

Main places about twice the seed tree's events, six times over in the junction boxes: a doubled day. This step brings the
total back to near the seed tree's, one event per block again, and her route a little thinner than it was (0.87 of it,
its junction boxes 0.77). The mix is not the seed tree's:

- the dog walker, the patrol and the convoy no longer stand in the city (the director sends them ahead of her), so every
  other row is nearly a third more common on average; on her route cafes go from 2.2 to 6.5 a city-day, the market stall
  from 0.9 to 2.5;
- the abduction is 10.8 a city-day on its days against 2.3, nearly all off her route (option D);
- **the charging dog, which ends the day**, is 1.92 a city-day in a junction box against 1.22 and 2.93 over the city
  against 2.19, 0.40 on her route against 0.18; **the chatting mother** is 1.31 in a box against 0.43 and 3.58 over the
  city against 2.00, 2.50 on her route against 0.96. These are the two rows option D's reply said would come back to
  main's share: on the reading the player settled (`box-rows-after-the-pass`) they come nearer it;
- the delivery van, the poster crew, the reversing lorry and the roadblock are a little rarer on a street than on the seed
  tree, 0.69 to 0.86 of it;
- late days are not much denser than early ones: day 14 places 1.14 times day 1 where the seed tree placed 1.28, and
  days 9 to 11 fewer than day 1.

## What is left of the item

Steps 4 and 5 of `placement-by-construction.md` stay open: the beats become rigged marbles and the old siting roll goes, and
the escape city's draw is the same unit draw.
