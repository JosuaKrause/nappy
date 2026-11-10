# The city's events are placed by construction: locations, and a bag per view

**The ask.** The player laid out how the city's events are placed (inbox #1185 in gentle-owl, its comments
of 2026-11-08): three views on events, on the route, route-adjacent and off the route, each
with its own bag; a location gets the event its view's bag draws, with no rejection; a route stays
open by construction (across the street from a drawn restaurant the draw is mostly "empty", a "yeller"
at a low chance on later days); a street is three sections of two sidewalk locations each; the roadblock
phase at dawn spaces roadblocks over the route-adjacent locations, and the regular pass never overwrites one; the city's fixed parts have
phases of their own; and day 13's task swaps a whole section's content for a roadblock only when
none is close by. Of building anything on today's placement first: "no duplicate work", "the
refactors come first", "everything else would be meaningless" (inbox #1185 in gentle-owl).

**Read as:** the design is `docs/EVENTS.md`'s "The three views and the placement order", cited line
by line; its numbered list says where the code differs.

**The player's answers to the design review** (inbox #1268 in olive-ferret; each is quoted with what it answered):

- Shown that density is "a chain of correction tables that multiply, each tuned until the new draw
  reproduces the old algorithm's counts", that five of the listed differences from the design would
  still stand when this item closed, and asked whether main's measured mix is the target or the
  starting point, with (b) "Show parity once, then replace the tables with one declared table
  inside the refactor": "(b) also the real test will come from playtests -- so it's not super
  important that the numbers are exactly the same".
- Shown that the dawn draws every location and discards the rows that block nothing while the walk
  draws them again from a second set of bags: "why do we draw at dawn at all? we only put a few
  defined events at dawn and let the rest be drawn during the day", and "get rid of the redundant
  historic double draw".
- Shown that the escape city's draw is "still a second loop with its own marble rules": "yeah
  let's simplify".
- Then, to the orchestrator's reply (which proposed drawing a whole street at once when she first
  comes near it, seeded by the day and the street, so a street holds the same events whatever her
  path): "agree on all design review points. let's do it".

**Read as:**

- **The differences listed in `docs/EVENTS.md` are closed inside this item**, not left standing:
  the dawn holds only the defined things (the routes, the region wall and its doors, the closures,
  the seals, the masts, the ambient rows, day 13's roadblock phase, the scripted rows), and every
  other location is drawn as she walks, the rows with a body among them.
- **A route stays open by the street's own rules, never by a flood.** The orchestrator's earlier
  ruling, that every row with a body is drawn at dawn so the reach rule (`RouteReachRule`, a flood
  of the whole city from home) can judge it (stated on the walk draw's pull request, #1262, after
  its first review), is overturned by the player's question above; it
  rested on "no live reachability check" (inbox #1173 in gray-dolphin), which the design satisfies by needing no
  check at all: "there is no reason to check whether a route is open during game play because it
  cannot be closed to begin with" (inbox #1173 in gray-dolphin).
- **A retry is the same day** (PLAYTEST-119 27: "the same day exactly how the player encountered
  it the first time this run. exact same state at the beginning of the day. nothing else").
  *Read as* (the orchestrator's, put to the player as "draw a whole street at once when she first
  comes near it, seeded by the day and the street, so a street holds the same events whatever her
  path" and agreed with the review's points, inbox #1268 in olive-ferret): the events a street's draw gives it do
  not depend on the path she takes to it. The beats sited from her walk are the exception the
  player's own ruling makes: a retried day 3 has its fire "sited from the walk she takes then"
  (PLAYTEST-119 26), and step 4's rigged marbles are of that kind.
- **Exact parity with main is not the bar for this item.** A step lists what moved for the end
  remeasure; a playtest judges it. No table is fitted in a loop.

## What is built

The locations of every day (`DayLocations`, `StreetLocations`, `Location`, each told its view once),
the bag per view and its draw (`ViewBag`, `LocationDraw`), the day's placement rules as classes
(`StreetRule`, composed by `StreetInvalidation`, with a location's own ground in `LocationFit`), the
roadblock phase (`RoadblockPhase`), day 13's section swap, the scene recipes' locations, and the
fixed parts' and the scripted rows' dawn phases (`ScriptedPhase`). Every open location is drawn
at dawn by one loop (`EventScheduler._draw_the_locations()`: `LocationDraw.draw_all()` over
`DayLocations.drawing_order()`); a poster crew is handed to her walk as it is drawn, and a sidewalk
a dawn phase fills closes its section to the draw and the roadblock phase. Nothing is drawn as she
walks.

## What is left, in order

The steps are the design review's points, which the player approved: "agree on all design review
points. let's do it", and "I saw the review and approved it" (inbox #1268 in olive-ferret). The mechanism under
each step is the same review's worked-out detail, written after the player had read its points; its
full text names the files each step owns.

1. **The route's ground rule replaces the flood.** Three of the route rules are already local to a
   street and count bodies as well as fields: a junction box on a route keeps a free crossing
   (`RouteJunctionsRule`), the sidewalk a route walks keeps a line with room for her
   (`RouteSidewalkRule`), and nothing stands in the open end of a pacing beat (`PacingOpeningRule`).
   One more closes the gap: no body's disc and no lethal row's inner disc covers a tile a route runs
   along off the sidewalks (an alley, a park cut, a square). With it a route cannot be closed, and
   `RouteReachRule` leaves the game: the scars and the park spoilers ask the new rule, and the flood
   becomes a probe's check that counts route tiles cut off from home after a whole day is drawn,
   expected to be none. It is stricter than the flood, which let a body stand on a route tile where
   a detour existed.
2. **A street is drawn as one unit, the first time she comes near it.** A unit is a street (three
   sections, six sidewalk locations), a junction box, an alley, or one park or square. Each has its
   own random stream, seeded by the day's seed and the unit, and draws all its locations in one go
   when any of them enters the band ahead of her. Each unit also has a fixed rank from the same
   seed: before a unit draws, every undrawn unit touching it (sharing a junction box, or bordering
   the same alley, park or square) with a lower rank draws first. The day is then exactly what
   drawing every unit at dawn in rank order would give, whatever her path, without paying for
   streets she never comes near. The rows with a body are drawn this way too. The dawn's one draw
   of every open location (`LocationDraw.draw_all()`) and the daily caps for drawn rows go
   (a cap depends on order; "at most one of a row per street" replaces the same-row spacing and the
   roomiest-tile ranking). A body drawn out of her view onto a lane a car stands in has the crowd
   recycle that car. `docs/MECHANICS.md`'s "A retry is the same day" stays true of every drawn row, and the
   test that holds it for the dawn's draw (`test_event_manager`, a day started twice) gains the walk
   for the unit draw: the same city and day drawn along two different walks hold the same drawn
   rows on the same tiles. The test does not cover what is sited from her walk (the moments and step 4's rigged
   marbles), and the doc's sentence says so.
3. **One declared table replaces the fitted ones.** `VIEW_SHARES`, `VIEW_SHARE_SCALES`,
   `WALL_VIEW_SCALES`, `FRICTION_VIEW_SCALES`, `GROUND_WEIGHTS` and `MOMENTS_PER_DAY` go. In their place: the events per hundred locations by view, kind of ground
   and act; the moments per act; and the role-by-view weights that are already declared constants.
   A row's mix stays on its catalogue row, with an optional weight per kind of ground where it is
   rare there. The table is seeded once from main's measured placements (planned as the game plans
   a day), each cell rounded to two figures; if a view's total is off by more than about a tenth on
   one probe run, that view's cells are scaled once. Empty marbles make up the rest of a bag, and a
   row the street's earlier draws make invalid is left out of the draw, so empty gets likelier
   across from a drawn event, as the player's restaurant example has it.
4. **The beats become rigged marbles, and the old siting roll goes.** The walk's sitings
   (`WalkSiting`: day 3's fire, the poster crews, day 6's man shouting, day 7's route van, day 11's
   added mast, the dusk fire) take a location in the next undrawn unit ahead of her, before it
   draws. **Read as** (the orchestrator's reading): a rigged marble, such as the day-6 man shouting
   due within the next two events after the mark (olive-koala 2), lands on the next location she
   comes to on her way, so a player who turns at a junction still meets him; a row she must meet
   whatever route she takes exists wherever she goes, the guarantee the covering sites gave at dawn
   (M50-the-city-points-somewhere). These stay dependent on her path on purpose. With the last
   caller gone, `EventScheduler._best_of()`, `Verdicts`, `EVENT_PLACEMENT_TRIES` and whatever only
   they used are deleted. `_copies_of()` stays with `ground_for()` while a row's own ground still
   needs it.
5. **The escape city's draw is the same unit draw** with three settings on the day's spec: one bag
   for the whole walk, at most one event a street, and every unit drawn before she sets off, in the
   walk's own order. `EventScheduler._draw_the_walk()` and the spec's switch between draws go, and a
   refused marble stays in the bag. *Open, for the entry lilac-marten (the fuller escape), which
   retunes that density:* the player's order has empty as the rarest outcome ("trucks > explosions >
   vans > barriers > empty", inbox #785 in minty-lemur), while about a third of the streets stand empty today; this
   step keeps today's share and `tests/probes/escape_winnable.gd` shows the before and after.

Steps 3, 4 and 5 touch different files and run in parallel once step 2 is in. The event scheduler's
breakup (`scheduler-breakup.md`) is interleaved: its rename lands before step 1, its moves beside
step 1, and its dawn context before step 2, so step 2 edits a small file.

**How a step is accepted.** Its suites pass, as for every step of this entry ("for the refactor
test parity is enough", inbox #813 in curly-moose), with the tests that held main's exact counts changed to hold
the rule instead. One probe run checks the step's own guarantee: `tests/probes/walk_rows.gd` draws
every unit over its cities and prints the route tiles cut off from home, which is none or the step
is not done, and the longest chain of units one draw pulled in. The same run prints the events she
meets per walk by view beside the baseline (`baseline-measurements.md`); those are listed for the
end remeasure and no step waits on them or fits to them ("let's do remeasuring at the very end and
not get blocked by it", inbox #813 in curly-moose).
