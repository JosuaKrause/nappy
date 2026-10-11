# bouncy-egret — From the gatehouse day on, fewer hard blockers · 2026-10-10

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), point 4, inbox #664:

> when the guard houses are set up the city gets much harder to navigate let's loosen the density
> of the hard blocking events in that case. let's treat every street from that day on as if it was
> on a path (but keep the path calculations still the same for connectedness, distances, routing
> etc)

Asked whether that meant, from day 9, no seals, no road closures and wall events weighted as on a
path everywhere, the player answered: "fewer of all three. gatehouses stay and remain on the actual
paths".

**From `Tuning.REGION_WALL_FIRST_DAY` (day 9) each of the three is halved by a constant of its own**,
the three beside `REGION_WALL_FIRST_DAY` in `src/autoload/tuning.gd`, each 0.5. The route tree,
routing, distances and the region planner's doors are untouched, so the gatehouses stay on the actual
paths; every change only removes blockers, which only adds ground she can reach (the city skill's
monotonicity test). The seal, closure and wall planners plan every day before 9 exactly as
before; the director's reading of soft seals, below, moves some day-6 and day-7 task contacts.

- **Seals** (`GATEHOUSE_DAY_SEAL_SHARE`): `SealPlanner` rolls once per off-tree street it would seal
  (`_seals_this_street`), the open streets spread evenly as the existing thinning pass spreads them;
  the same share multiplies the alley-mouth seal chance.
- **Road closures** (`GATEHOUSE_DAY_CLOSURE_SHARE`): `ClosurePlanner.closures_wanted(day)` halves the
  quota, a half rounding up, so three become two and four become two; the candidates' order is as
  before.
- **Wall-role rows** (`GATEHOUSE_DAY_WALL_ROW_SHARE`): `EventScheduler._thin_the_walls`, run in
  `build_day` after the fill on a stream of its own (`_plan_through_the_fill` is `build_day` up to
  it), takes back half of the fill's wall placements.
  *The entry proposed halving the wall rows' off-tree weights; measured, that cannot make walls fewer:*
  `_copies_of` decides where a wall stands, not how many a day places (halving every off-tree weight
  left 78.5 walls a day against 78.3), and halving a wall row's weight in the roll cut walls by about
  a quarter while the budget went to friction on the routes. So walls are thinned by count.

**Measured** (`tools/test.sh probes/bouncy_egret_blockers.gd`, six seeds, days 7 to 13, means per
day): on days 9 to 13, sealed streets go from about 143–159 to 67–78, seal bodies from 263–297 to
124–147, closures from 3 (days 9 to 11) and 4 (days 12 and 13) to 2, and walls from 78–89 to 39–46;
friction is unchanged, and days 7 and 8 are identical. Held by `tests/test_events_scheduler.gd`
(the thinned day is the fill's own day with only some of its wall placements taken out, in order,
the share kept within 0.15 of the constant, day 8 losing none, and `build_day` standing none of
the walls taken out), `tests/test_routes_closures.gd` (from day 9 a day whose act quota is above
one street closes fewer than that quota, asked of `Tuning.closures_for_day` rather than of
`closures_wanted`) and `tests/test_seals.gd` (the share of off-tree streets sealed from day 9). The
stills are
[bouncy-egret-fewer-blockers-2026-10-11](../evidence/bouncy-egret-fewer-blockers-2026-10-11/), day 10
on seed 4242 before and after; the after still also has a construction band on the lower-left
street that the before still does not, because fewer seals and closures offer the fill other ground
and it rolls other tiles, so the blockers a day keeps are not all where they stood on `main`.

**What the loosening uncovered.** A soft seal left standing in front of both ends of an alley made
the director call the alley reachable and move a mark there that the red arrow could never lead her
to; `ResistanceDirector._ensure_reachability` treats soft-seal bands as blocked, as the arrow already
did, `docs/CITY.md`'s guarantees say so, and `tests/test_resistance.gd`'s own reachability
(`_day_reachability`, what its mark and task sweeps are graded against) reads them the same way.
That reading holds on every day, not only from day 9. Measured by the PR's review over 10 seeds and
days 6 to 13 in the real day order, main against the branch: every mark stands where it stood, but
the task contact moves on 10 of the 30 seed-days from 6 to 8 — day 6 on seeds 4242, 90210, 314159,
777 and 8675309, day 7 on 1234567, 291862120, 314159, 555555 and 8675309, never on day 8; seed
4242's day-6 man shouting moves from tile (95,73) to (92,98) — and on day 11 one more seed in 10
(2295276695) finds no ground for a mast near the mark and falls back to a city mast site, 3 of 10
against 2. *Open to overturn:* the director agreeing with the arrow on every day rather than only
from day 9, which the player did not ask for.

**Day 11's rigged mast is put down on her route by luck, on `main` as on this branch.** Over 30
cities (`tools/test.sh probes/bouncy_egret_day11_mast.gd` with `PROBE_SEEDS` set to the review's ten
seeds, then 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765 and
10946), 600s of walking the day's longest route back and forth puts it down on 10 on `main` (at
aa3fe656) and on 8 on the branch: 5 against 2 on the review's ten, 5 against 6 on the other twenty.
The cause is the same on both. Of the tiles of the mast's ground on the day's route tree that a mast
site may take, every one but one to five per city breaks `_leaves_the_route_junctions_open` or
`_leaves_the_routes_sidewalk_open` with the mast standing alone — its own field, which a line along
the route has to get past, reaches the junction box at the end of whatever street it stands on —
and those few tiles are the same tiles on `main` and on the branch (seeds 4242, 314159, 1234567,
555555 and 8675309: 1, 1, 5, 2 and 1 tiles, most on the city's edge). What differs is whether her
walk comes within reach of one and the siting's roll picks it, and fewer blockers only change which
rolls a walk makes. So `tests/test_resistance.gd` checks the first of three seeds whose walk puts it
down. Making it certain would change what a mast is held to — the city's six masts are already
outside the line rules (`EventScheduler._counts_against_the_line`, "a mast is planted once by
`MastSites`"), and [feathery-marmot](2026-10-03-feathery-marmot.md) puts a queued mast through "the
route junctions and sidewalks the day keeps open" — which is the player's choice and is not made
here.

Day 13's guard, set on her from another roadblock 1,778px away with a building between them, comes
straight at her, slides along the building he meets and stops 479px from her, so
`tests/test_day13_guard.gd` also accepts a guard who ends nearer her than he started, within a tile
and a half of where his own straight line to her meets a building. That is a weaker check than
[calm-pelican-14](2026-10-10-calm-pelican-14.md) built: a guard sent from across the city may never
reach her, which is filed as
[velvet-stork](../todo/2026-10-11-velvet-stork/README.md), day 13's guard reaches her from across
the city.

*Open to overturn once the player has played it:* the three shares (0.5 each); thinning the
alley-mouth seals with the streets'; closures rounding half up; walls thinned by count after the fill.
