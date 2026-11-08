# The city's events are placed by construction: locations, and a bag per view

**The ask.** The player laid out how the city's events are placed (inbox #1185, its comments
of 2026-11-08): three views on events, on the route, route-adjacent and off the route, each
with its own bag; a location gets the event its view's bag draws, with no rejection; a route stays
open by construction (across the street from a drawn restaurant the draw is mostly "empty", a "yeller"
at a low chance on later days); a street is three sections of two sidewalk locations each; the roadblock
phase at dawn spaces roadblocks over the route-adjacent locations, and the regular pass never overwrites one; the city's fixed parts have
phases of their own; and day 13's task swaps a whole section's content for a roadblock only when
none is close by. Of building anything on today's placement first: "no duplicate work", "the
refactors come first", "everything else would be meaningless" (inbox #1185).

**Read as:** the design is `docs/EVENTS.md`'s "The three views and the placement order", cited line
by line; its numbered list says where the code differs. Nothing in that section is reopened here.

**Build:** replace the tile-by-tile placement with the design:
- locations per street (three sections along its length, two sidewalk locations in each, a
  street-spanning event taking a whole section), each in one of the three views;
- a bag per view holding every event possible in it, each as many times as its weight, empty
  included; a location's event is what its bag draws, with the events the street's other draws make
  invalid left out (today's placement rules, `_judge()`'s route-opening checks among them, become
  that invalidation);
- the fixed parts' phases at dawn or at the start of the run (the region wall, its doors, the
  closures, the seals, the masts, the ambient rows), a mast's location known from the run's start;
- the roadblock phase after the routes, each roadblock biased toward the route-adjacent location
  farthest from those already placed, its locations taken for the day;
- every other location drawn during the walk;
- day 13's task: a roadblock close by along her paths (576, 896, then 1,024px from where she reads
  the chalk mark), else one off-screen route-adjacent section's content replaced by a roadblock.

It replaces, and deletes: the roll and judgement of `EventScheduler._place_one()`, `_best_of()`,
`_judge()` as a placement step and `_copies_of()`; the dawn roadblock pass
(`_place_beside_the_routes()`); the swap (`Planned.may_be_replaced()`,
`ResistanceDirector._places_to_swap()`, `WalkSiting.in_place_of()`); and whatever only they used.
Day 13's swap misses (33 of 480 real chalk marks in `tests/probes/minty_quail_day13_real_marks.gd`)
go to none. A step is done at test parity (minty-quail's README); what changes on purpose is listed
for the remeasure.
