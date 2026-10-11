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
monotonicity test). Days before 9 come out identical.

- **Seals** (`GATEHOUSE_DAY_SEAL_SHARE`): `SealPlanner` rolls once per off-tree street it would seal
  (`_seals_this_street`), the open streets spread evenly as the existing thinning pass spreads them;
  the same share multiplies the alley-mouth seal chance.
- **Road closures** (`GATEHOUSE_DAY_CLOSURE_SHARE`): `ClosurePlanner.closures_wanted(day)` halves the
  quota, a half rounding up, so three become two and four become two; the candidates' order is as
  before.
- **Wall-role rows** (`GATEHOUSE_DAY_WALL_ROW_SHARE`): `EventScheduler._thin_the_walls`, run in
  `build_day` after the fill on a stream of its own, takes back half of the fill's wall placements.
  *The entry proposed halving the wall rows' off-tree weights; measured, that cannot make walls fewer:*
  `_copies_of` decides where a wall stands, not how many a day places (halving every off-tree weight
  left 78.5 walls a day against 78.3), and halving a wall row's weight in the roll cut walls by about
  a quarter while the budget went to friction on the routes. So walls are thinned by count.

**Measured** (`tools/test.sh probes/bouncy_egret_blockers.gd`, six seeds, days 7 to 13, means per
day): on days 9 to 13, sealed streets go from about 143–159 to 67–78, seal bodies from 263–297 to
124–147, closures from 3 (days 9 to 11) and 4 (days 12 and 13) to 2, and walls from 78–89 to 39–46;
friction is unchanged, and days 7 and 8 are identical. The stills are
[bouncy-egret-fewer-blockers-2026-10-11](../evidence/bouncy-egret-fewer-blockers-2026-10-11/), day 10
on seed 4242 before and after.

**What the loosening uncovered.** A soft seal left standing in front of both ends of an alley made
the director call the alley reachable and move a mark there that the red arrow could never lead her
to; `ResistanceDirector._ensure_reachability` treats soft-seal bands as blocked, as the arrow already
did, and `docs/CITY.md`'s guarantees say so. With fewer closures, day 11's rigged mast on seed 4242
is not placed within a 600s walk, so `tests/test_resistance.gd` checks the first of three seeds where
it is; and day 13's guard, set on her from another roadblock 1,778px away with a building between
them, comes straight at her and stops at 479px, so `tests/test_day13_guard.gd` also accepts a guard
who closed in and whose line to her is blocked by a building. That last is a weaker check than
[calm-pelican-14](2026-10-10-calm-pelican-14.md) built: a guard sent from across the city may never
reach her, which is filed as
[velvet-stork](../todo/2026-10-11-velvet-stork/README.md), day 13's guard reaches her from across
the city.

*Open to overturn once the player has played it:* the three shares (0.5 each); thinning the
alley-mouth seals with the streets'; closures rounding half up; walls thinned by count after the fill.
