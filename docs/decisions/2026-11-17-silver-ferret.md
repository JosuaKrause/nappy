# silver-ferret — The later days are harder off her route than on it, and act IV's route is shorter · 2026-11-25

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
N8 figures stand as they were. `placement_cells.gd` ran once more with one cell of the table set to
the value proposed below, to measure what it places.

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
measure here, and neither raises anything; the board questions below offer the first as the ground
the later days are judged on.

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
- **Her route thins because it is shorter.** It has a third fewer draw locations in act IV than in
  act I (346 a city-day against 543, 0.64 times), nearly the whole of the fall in what lands on it
  (0.66 times); for every hundred draw locations act IV places more than act I, not less (5.32
  against 4.57, `raw/route_cells.txt`). Her route has fewer streets in the later days (about 76
  street units a city on day 1 against 52 on day 14, the `CL` lines) and a little less open
  sidewalk on each (5.9 draw locations a street unit against 5.0). Why the tree is smaller is not
  measured: it grows a branch to each calm area still open that day (`RouteTree.for_day()`), so the
  calm areas the later days shut, their closures and the region wall are the candidates, and none
  is counted here. **A density cell does not address a shorter route**: it puts more in each
  location of the route there is.
- **The walk** is three cities and noisy day by day (day 3 reads 20.7 points a minute, day 6
  93.7); it prices each event at its live rate where it stands when streamed in, ticks nothing (so
  nothing pursues her) and leaves out the moments.

## The judgement

**The two readings disagree: the later days are harder off her route, not on it.** Which reading
judges them is the player's, and the questions below put it to them.

- **By the entry's measure, over the whole city**, acts III and IV are harder. They place about as
  many events as act I (1.05 and 1.20 times), those events cost about twice as much to pass (1.95
  and 2.36 times an event), and about one in six ends the day or pursues her, where act I has
  under one in a hundred: harder in kind, the escalation the scheduler's own suite reads the
  player's day-two complaint as asking for (day one may be easy if the difficulty increases,
  PLAYTEST-05 5). **The abduction carries it**: the van whose two men get out and hunt her, a catch
  ending the day. Without that row act III's paid points a city-day are 0.91 times act I's and act
  IV's 1.51 times, and 96% of abductions stand off her route and none on it. Its rate is the one the
  player accepted on the row-weights question, option D, without having seen it in play
  (inbox #1464 in silky-lemur).
- **On her route** the later acts are not much dearer and act IV is thinner. An event there costs
  1.13 and 1.20 times act I's, the count is 0.94 and 0.66 times act I's, and walking every route
  of the day costs 1.11 and 1.13 times act I's points a minute. Cold, the share on her route that
  ends the day or pursues her stays under one in a hundred in every act (0.0%, 0.4%, 0.3%, 0.7%).
  The one rise is with the lethal rung (11.8% and 10.3% in acts III and IV): the roadblock's guard
  and the night raid, once her heat reaches that rung. That is a real change in kind, and it waits
  on her heat. What grows on her way is the count of things heard while walking (1.7 times) and the
  few that end the day or pursue her (none in act I, about one every five and a half minutes walked
  in act III), with the moments, 26 to 32 a day, priced the same a moment.

The game's one verb is where she walks, and a danger that stands on no route of the day reaches
that choice only when she leaves the route tree. So the later days ask her more about where she
must not go than about what a pass costs, and her own route is shorter in act IV than in any act
before it. Whether that reads as too easy is the player's call. The player has said a playtest
decides which deviations need fixing (inbox #1278 in olive-ferret).

## For the board, not raised

The measure stays the filer's proposal (the entry's), and the entry asks that a different measure,
where the remeasure proposes one, go to the player on the board before anything is raised. Nothing
here is raised. Two questions for the orchestrator to put to the player, the bar's after them:

- **Which ground judges the later days: the whole city, or what her route meets?** The whole city
  (the entry's measure as it stands) reads them as harder and closes this with nothing changed.
  Her route (what the units place on it and what walking it meets, priced the same way) reads them
  as not much dearer and act IV as thinner, and opens the next question. The filer would pick her
  route, since it is what the route decision meets.
- **If act IV's route reads thin: change nothing until the release's playtest, or one cell now?**
  - *Change nothing*: no work, and the release plays act IV on her route as measured here.
  - *One cell, by declaration*: her route's street cell in act IV
    (`PlacementDensity.EVENTS_PER_HUNDRED[0][0][3]`), 16 to 23 events for every hundred draw
    locations. **Measured with the cell set** (`placement_cells.gd` on the measured tree with that
    one number changed and nothing else, uncommitted): what the units place on her route in act IV
    goes from 18.4 to 24.3 a city-day, within 2% of act I's 24.8. All of it is on her route's
    streets (15.4 to 21.3). What lands there for every hundred draw locations goes from 5.6 to 7.8,
    the same third of the cell as before (0.35 and 0.34). Her route's junction boxes go from 2.20
    to 2.15. The other two views and acts I to III are unchanged in their counts. The city places
    about 6% more in act IV (97.1 to 103.0 a city-day). The mix's own count on her route (14.2,
    `placement_rows.gd`) was not run again with the cell. Act IV's route stays a third shorter than
    act I's, with more on each stretch of it.
  - *A larger alternative*: hold her route at act II's count (act III's street cell 14 to 23, act
    IV's 16 to 37). It is not measured.

  Either cell is measured again over the same cities once it is set (**balance**: never derive a
  density), and no cell moves the cost table, which prices a row met and not how often one stands.
  Her route's junction-box cell is not proposed: in act IV its boxes place a tenth of what the bag
  holds (4.8 for every hundred against a cell of 46). Why the rest of that bag stays empty is not
  counted here. The filer leans to changing nothing until the playtest, with the one cell measured
  and ready, since the player has said a playtest decides a deviation (inbox #1278 in olive-ferret)
  and that density is not the only way to change difficulty (silky-lemur #1464).

## The bar or the table (the balance skill's rule)

The bar the entry names, day 14 placing a fifth more than day 1, is a check in
`tests/test_events_scheduler.gd` (`_test_a_day_has_enough_in_it_to_meet`, on city 4242), not in
`test_events_costs` as the entry and polite-tapir-coral-owl call it. On today's main it passes on
its city (134 placed on day 14 against 89, 1.51 times) and four of the ten cities of
`ramp_cities.gd` (0.95 to 1.51); over the 18 cities of `placement_rows.gd` day 14 places 1.13
times day 1. **The filer's reading: the bar is the wrong one.** It holds the ramp in the count,
where the later days ramp in price and in kind (off her route most of all), which the player's
words say is a way difficulty rises (silky-lemur #1464), and it passes or fails by which city it is
planned on. Proposed for the board, a code change for a later pull request: a relationship of
difficulty in its place, **stated on her route** (view 0), with the count held only as "the last
day places no fewer than the first". On her route, act IV's paid price of an event is 1.20 times
act I's (day 14 over day 1, 1.12 times), and its share that ends the day or pursues her with the
lethal rung is 10.3% against act I's 0.0%; which of the two the bar holds, and at what ratio, is
the later pull request's to measure. Over the whole city such a bar would pass on the abduction
alone (the paid price of an event in act IV 13.77 with it, 8.76 without, against act I's 5.84,
almost all of it off her route), so it would hold the reading the findings above undercut. The
other reading, that the table is wrong because the count should rise by a fifth, asks for about 6
more events a city-day on day 14 over the 18 cities of the mix (108 against 101.9). The one cell
above adds 5.9 a city on day 14 by the units' count (99.9 to 105.8, `placement_cells.gd`).

## Choices open to overturn

- **The price** is the nearest pass, awake, a pass under the decay counted as nothing; the
  alternatives, the signed pass or the asleep column, are printed beside it (`weigh_days.py`) and
  read the same way: the signed price of an event goes 2.44, 2.50, 7.04, 9.10 by act.
- **Unpriced rows** (those that pursue or wait for her) are counted only in the share.
- **The walk's "met"** is an event whose field reached her as built, at any strength.
- **No pick is made here.** Change nothing, the one cell and its larger alternative go to the
  player; the filer leans to changing nothing until the playtest, with the cell measured.

## Not measured

Heat above 0 beyond the lethal rung's ceiling (the pressing rung, dearer to stand near and never
ending the day), the escape city, contacts, horns and the crowd, and how a day feels, which is a
playtest's. Also not measured: why her route is shorter in the later days, why her route's junction
boxes leave most of their bag empty, the larger alternative's two cells, and the one cell's effect
on the mix's count, the price and the walk.
