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

**Build:** what is left of the design, on the locations of every day (`DayLocations`,
`StreetLocations`, `Location`, each location's view from `Corridor.view_of_ground()`), the bag per
view and its draw (`ViewBag`, `LocationDraw`, asking `LocationGround`), the roadblock phase
(`RoadblockPhase`) and day 13's section swap that are built:
- the events the street's other draws make invalid left out of a location's draw: today's placement
  rules become that invalidation, in place of `JudgedLocationGround`, which still asks `_judge()`
  whether a candidate fits (the roadblock phase's own use of `_judge()` included), and
  `DayRepairs` goes with them; the fitted tables that encode how often `_judge()` refuses
  (`EventScheduler.VIEW_SHARE_SCALES`, `WALL_VIEW_SCALES`, `FRICTION_VIEW_SCALES` and
  `GROUND_WEIGHTS`) are fitted again against main in the same step, with
  `tests/probes/placement_rows.gd`;
- the escape on the same draw, one draw per street and the rest of the street empty once any
  location holds an event (inbox #1185's board answer), `_fill_the_walk_from_the_bag`, `KeptGround`
  and the escape's `Rules` going with it;
- the scene recipes assigning locations;
- the fixed parts' phases at dawn or at the start of the run (the region wall, its doors, the
  closures, the seals, the masts, the ambient rows), a mast's location known from the run's start;
- every other location drawn during the walk. **Read as** (the orchestrator's reading): a rigged marble, such as the day-6 man
  shouting due within the next two events after the mark (olive-koala 2), lands on the next
  location she comes to on her way, so a player who turns at a junction still meets him; today a
  body sited ahead of her is never moved, and she can turn away from it.

It replaces, and deletes: the roll and judgement of `EventScheduler._place_one()`, `_best_of()`,
`_judge()` as a placement step and `_copies_of()`; and whatever only they used.
A step is done at test parity (minty-quail's README); what changes on purpose is listed
for the remeasure.
