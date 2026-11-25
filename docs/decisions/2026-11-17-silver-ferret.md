# silver-ferret — The later days are harder on their events' price and danger, not their count, and her route thins · 2026-11-25

**The ask.** "event density is not the only way to tweak difficulty. events themselves are also
more difficult to deal with" (silky-lemur #1464), answering the board's question
`late-days-denser` on whether to raise the later acts' density at once or wait for the
refactor's end remeasure. **Read as** (the entry's): at the end remeasure the later days (acts III
and IV) are judged against the early ones on how many events a day places and how hard those
events are to deal with, both counted, and the later acts' cells of `PlacementDensity` (the
events a unit's bag holds for every hundred draw locations, by view, kind of ground and act) are
raised, by declaration, only if the later days still read as too easy. This item raises nothing:
its reading and any proposed change go to the player on the board.

**Measured on** today's main, `c60129fadf6e0a904434685f8702509a4a9d1f17`, headless, Godot 4.7.2,
one Godot run at a time. The evidence is `docs/evidence/silver-ferret-later-days-2026-11-25/`
(its README holds the commands, the probe copies, the scripts and every figure, per day as well as
per act). The placement probes are the end remeasure's (records minty-quail-striped-squirrel and
minty-quail-bouncy-bison): `placement_rows.gd` over its 18 cities, read again here with the
moments counted by row and every row's flags, `placement_cells.gd` and `ramp_cities.gd`; their
lines equal the remeasure's (no placement code changed between the two trees), so the remeasure's
N8 figures stand as they were.

## The measure, the filer's proposal

The entry proposed it and nothing here changes it: **each act's mix of placed rows, weighted by
the cost table's price of one pass of each row** (`docs/COSTS.md`, the net points one pass at
walking pace costs her, at the nearest line the table gives, 0px or 20px for a row with a solid
body; a pass that nets below the decay she has walking anyway counts as nothing), **beside the
share of a day's events whose rows end the day or pursue her** (cold, and with the lethal rung,
the ceiling once her heat has reached the rung where the roadblock's guard and the night raid hunt
her). Two readings are set beside it because the measure prices a row wherever the city holds it,
and the player meets what is on her way: what the units place **on her route** (the streets of
every route of the day's route tree), and **what walking those routes meets**
(`polite_rabbit_wall_costs.gd` walked on every day, on its three cities). Neither replaces the
measure; neither is used to raise anything.

## Readings (a city-day, the mean of the act's days)

| | act I | act II | act III | act IV |
|---|---|---|---|---|
| events placed | 88.6 | 105.3 (x1.19) | 93.3 (x1.05) | 106.0 (x1.20) |
| priced passes, paid | 455 | 594 (x1.31) | 892 (x1.96) | 1243 (x2.73) |
| paid a priced event | 5.84 | 6.61 (x1.13) | 11.39 (x1.95) | 13.77 (x2.36) |
| end the day or pursue, cold | 0.7% | 5.5% | 17.9% | 17.6% |
| with the lethal rung | 0.7% | 6.6% | 23.5% | 27.1% |
| the same without the abduction: paid | 455 | 594 | 416 (x0.91) | 688 (x1.51) |
| without the abduction: ends the day, cold | 0.7% | 5.5% | 8.0% | 7.3% |
| on her route: events placed | 21.6 | 29.9 (x1.38) | 20.3 (x0.94) | 14.2 (x0.66) |
| on her route: paid a priced event | 2.27 | 2.63 | 2.56 | 2.72 (x1.20) |
| on her route: draw locations | 543 | 566 | 443 | 346 |
| walking her routes: points a minute | 49.5 | 70.6 (x1.43) | 55.1 (x1.11) | 55.7 (x1.13) |
| walking her routes: events met a minute | 2.63 | 3.56 | 4.39 (x1.67) | 4.49 (x1.71) |
| walking: ends the day or pursues, met a minute | 0.00 | 0.06 | 0.18 | 0.07 |
| moments the director sends ahead of her | 26 | 27 | 29 | 32 |
| paid a moment | 13.5 | 11.1 | 11.6 | 11.9 |

- **What carries the price.** In acts III and IV the abduction (10.1 and 11.7 a city-day) is 53%
  and 45% of the paid points and 60% and 63% of the rows that end the day; 96% of abductions
  stand off her route and none on it. The protest carries a fifth of act IV's (9.5 a city-day).
  In acts I and II the leaf blower and the man shouting carry most of it.
- **Asleep**, nearly every pass nets under the decay: a priced event costs 0.21 in act I and 1.57
  and 1.63 in acts III and IV, the abduction, the firefight and the curfew announcement the rows
  that still cost.
- **Her route thins.** It has fewer draw locations in the later acts (346 a city-day in act IV
  against 543 in act I), and of what the bag holds there less lands: her route's junction boxes
  place 4.8 events for every hundred draw locations in act IV against a cell of 46, its streets 5.6
  against 16.
- **The walk** is three cities and noisy day by day (day 3 reads 20.7 points a minute, day 6
  93.7); it prices each event at its live rate where it stands when streamed in, ticks nothing (so
  nothing pursues her) and leaves out the moments.

## The judgement

**With both counted, by the entry's measure, acts III and IV read as hard enough, and no raise of
the later acts' cells is proposed.** They place about as many events as the early acts (1.05 and
1.20 times act I), and those events cost about twice as much to pass (1.95 and 2.36 times an
event) and are about one in six that ends the day or pursues her, where act I has under one in a
hundred. The later days are harder in kind, which is the escalation the scheduler's own suite
reads the player's day-two complaint as asking for: day one may be easy if the difficulty
increases (PLAYTEST-05 5).

**What the measure does not show, and the player should know before reading it as settled:**

- about half of the later acts' price, and three fifths of their rows that end the day, is one
  row, the abduction, placed almost wholly off her route, at the rate the player accepted on the
  row-weights question, option D, without having seen it in play (inbox #1464 in silky-lemur);
  without it act III costs what act I does (0.91 times) and act IV half again;
- what she walks is not dearer: on her route the later acts place fewer events (act IV two thirds
  of act I's), priced the same each, and walking every route of the day costs about a tenth more a
  minute in acts III and IV than in act I; what grows on her way is the count of things heard
  (1.7 times) and the few that end the day or pursue her (none in act I, about one every five
  and a half minutes walked in act III), with the moments, 26 to 32 a day, priced the same a
  moment.

So the later days ask her more about where she must not go than about what a pass costs, and her
own route is thinner in act IV than in any act before it. Whether that reads as too easy is a
playtest's question, and the player has said playtest decides a deviation (inbox #1278 in
olive-ferret).

## Proposed for the board, not raised

**If the player reads act IV's walk as too thin**, the change the measurement points to is one
cell, by declaration: **her route's street cell in act IV, 16 to 23 events for every hundred draw
locations** (`PlacementDensity.EVENTS_PER_HUNDRED[0][0][3]`), which, if what lands there scales
with the cell, brings her route back to act I's count (18.4 events a city-day in act IV to about
24.8, by `placement_cells.gd`; the city about 6% more in act IV). Her route's junction-box cell
is not the lever: in act IV it places a tenth of what its bag holds, the rules that keep her route
open refusing the rest. A larger alternative holds her route at act II's count instead (act III's
street cell 14 to 23, act IV's 16 to 37). Either is measured again after it is set, over the same
cities (**balance**: never derive a density); no cell moves the cost table, which prices a row
met and not how often one stands. The plainer
alternative, which this record picks, is to change nothing and let the playtest the release
carries say whether the later days are easy.

## The bar or the table (the balance skill's rule)

The bar the entry names, day 14 placing a fifth more than day 1, is a check in
`tests/test_events_scheduler.gd` (`_test_a_day_has_enough_in_it_to_meet`, on city 4242), not in
`test_events_costs` as the entry and polite-tapir-coral-owl call it. On today's main it passes on
its city (134 placed on day 14 against 89, 1.51 times) and four of the ten cities of
`ramp_cities.gd` (0.95 to 1.51); over the 18 cities of `placement_rows.gd` day 14 places 1.13
times day 1. **The filer's reading: the bar is the wrong one.** It holds the ramp in the count,
where the later days ramp in price and in kind, which the player's words say is a way difficulty
rises (silky-lemur #1464), and it passes or fails by which city it is planned on. Proposed for the
board, a code change for a later pull request: a relationship of difficulty in its place (act IV's
share of events that end the day or pursue her over act I's, or the paid price of an event), with
the count held only as "the last day places no fewer than the first". The other reading, that the
table is wrong because the count should rise by a fifth, asks for about 6 more events a city-day
on day 14 over the 18 cities (108 against 101.9), about what the one cell proposed above would
add.

## Choices open to overturn

- **The price** is the nearest pass, awake, a pass under the decay counted as nothing; the
  alternatives, the signed pass or the asleep column, are printed beside it (`weigh_days.py`) and
  read the same way: the signed price of an event goes 2.44, 2.50, 7.04, 9.10 by act.
- **Unpriced rows** (those that pursue or wait for her) are counted only in the share.
- **The walk's "met"** is an event whose field reached her as built, at any strength.
- **Picked: change nothing**, against the one cell above and its larger alternative.

## Not measured

Heat above 0 beyond the lethal rung's ceiling (the pressing rung, dearer to stand near and never
ending the day), the escape city, contacts, horns and the crowd, and how a day feels, which is a
playtest's.
