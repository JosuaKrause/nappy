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
view and its draw (`ViewBag`, `LocationDraw`, asking `LocationGround`), the day's placement rules as
the invalidation (`StreetRule`, one class per rule, composed by `StreetInvalidation`, with a
location's own ground in `LocationFit`), the roadblock phase (`RoadblockPhase`), day 13's section
swap and the escape's one draw a street that are built:
- the scene recipes assigning locations; with them `recipe_placement()` and `place_at()` stop
  rolling a tile;
- the fixed parts' phases at dawn or at the start of the run (the region wall, its doors, the
  closures, the seals, the masts, the ambient rows), a mast's location known from the run's start;
  and the scripted rows and the one-shots, which are placed at dawn for a reason of their own and so
  get dawn phases that assign their locations (the builder's reading, open to correction), so
  `_place_scripted()` and `_place_one_shots()` stop calling `_place_one()`;
- every other location drawn during the walk, the walk's sitings among them (`WalkSiting`: day 3's
  fire, the poster crews, day 6's man shouting, day 7's route van, day 11's added mast, the dusk
  fire). **Read as** (the orchestrator's reading): a rigged marble, such as the day-6 man shouting
  due within the next two events after the mark (olive-koala 2), lands on the next location she
  comes to on her way, so a player who turns at a junction still meets him; today a body sited ahead
  of her is never moved, and she can turn away from it. This step also decides whether a placement
  made during the walk is asked the reach rule (`RouteReachRule`, no body cutting a route tile off
  from home), which today is a dawn rule and a walk's siting is not asked.

Each of the last three takes some of the callers of `EventScheduler._place_one()` and `_best_of()`,
which roll tiles and take the roomiest while asking the day's rules of each (the orchestrator's
choice in step 3b, so their behaviour moves once, with their callers): the scene recipes
`recipe_placement()`; the dawn phases the scripted rows and the one-shots; the walk's draws
`WalkSiting`. **Whichever moves the last caller deletes the roll**: `_place_one()`'s roll,
`_best_of()`, `Verdicts`, `EVENT_PLACEMENT_TRIES`, `_copies_of()`'s weights, and whatever only they
used; `_copies_of()`'s zero for a wall on a route tile stays with `ground_for()`, since it is the
filter that keeps a wall's location ground off the routes and `LocationFit` asks it. The
fitted tables that encode how often the rules refuse (`EventScheduler.VIEW_SHARE_SCALES`,
`WALL_VIEW_SCALES`, `FRICTION_VIEW_SCALES` and `GROUND_WEIGHTS`) are fitted again against main with
`tests/probes/placement_rows.gd` in any step that changes what the draw accepts.
A step is done at test parity (minty-quail's README); what changes on purpose is listed
for the remeasure.
