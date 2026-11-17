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
  ruling, that every row with a body is drawn at dawn so a flood of the whole city from home can
  judge it (stated on the walk draw's pull request, #1262, after
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
the bag per view and the unit's marble draw (`ViewBag`, `MarbleDraw`, `UnitRoom`), the day's placement rules as classes
(`StreetRule`, composed by `StreetInvalidation`, with a location's own ground in `LocationFit`), the
roadblock phase (`RoadblockPhase`), day 13's section swap, the scene recipes' locations, and the
fixed parts' and the scripted rows' dawn phases (`ScriptedPhase`). Every open location is drawn
unit by unit as she comes near it (`UnitDraw`, prepared by `DawnDraw`, drawn by `EventsAhead`): a unit is a street (three sections, six sidewalk
locations), a junction box, an alley, or one park or square (`PlacementUnit`, grouped by
`DayUnits`), with its own stream and a fixed rank from the day's seed, and before a unit draws, every
undrawn unit touching it (sharing a junction box, or bordering the same alley, park or square) with a
lower rank draws first. A unit's bag fill is asked of one object by view and kind of ground
(`UnitFills.of()`), worked out from one declared table (`PlacementDensity`: the events a bag holds
for every hundred draw locations, by view, kind of ground and act, and the moments an act owes her),
the role-by-view weights the day's ground hands it, and each row's own weight, with its weight on a
kind of ground set on its catalogue row where it is rare there or never stands there
(`EventDef.weigh_on()`); empty marbles make up the rest of a bag, so a row the unit's earlier draws
make invalid leaves empty likelier, and no fitted table is left (`docs/EVENTS.md`, "The density,
and why it is a declared table"). The four kinds of ground a unit is (a street, a junction box,
an alley, a park or a square) are data (`PlacementGround.Kind`). Each unit draws from one fresh bag of its most permissive view, a marble drawn before it
is placed (a section, or one location) and the unit's rows laid out together, at most one of a row in the
unit, with no daily cap on a drawn row, and a drawn row's route stays on its street's run (the player
on the board, question long-routes, inbox #1460 in silky-lemur). The dog walker, the police patrol and the military
convoy are drawn by no unit: the director sends each just ahead of her as a marble of her route's bag
(inbox #1460 in silky-lemur). A poster crew is handed to her walk as it is drawn, and a sidewalk
a dawn phase fills closes its section to the draw and the roadblock phase. A place her walk
sites stands on ground whose units have drawn, and no draw reads it. A body put down after dawn (drawn, swapped in or moved by the director) tells the crowd, which
recycles a car standing under it where she cannot see it (`EventStreaming.use_body_listener()`,
`Crowd.recycle_cars_on()`). A day's routes stay open by local rules alone: besides her line through a
route's junctions onto the sidewalks she walks (`RouteLineRule`), its walked sidewalk and a pacing
beat's opening, the route's ground rule (`RouteGroundRule`) keeps every body's disc, every lethal
row's inner disc and every counted row's line reach off a tile a route runs along off the streets
(an alley, a park cut, a square), and keeps the scars and the park spoilers off every route tile and
off the street she starts on, and one sidewalk of every street of her routes stays open past the
bodies drawn on it (`OneSidewalkOpenRule`). The whole-city flood is no rule of the game; `tests/probes/walk_rows.gd` counts the route tiles a
day's bodies cut off from home, expected to be none (record 2026-11-11-polite-tapir).

**Everything that matters is drawn together.** The units draw as she walks, a marble drawn before it
is placed (above). The board questions on how far a unit's draw looks (touching-reach) and on what
the day holds until step 3 (day-density) are answered, and the answers wait in the inbox for the
next filing. The touching-reach answer is "everything that matters must be drawn together" (inbox
#1461 in silky-lemur). On the three route rows the player said "neither of these should be drawn at the beginning.
they all should be drawn when the player is close by to guarantee an encounter", then "just spawn in
the car just ahead of the player? then you guarantee an encounter", "the same for the dog walker and
the convoy", "the route only matters *after* it was spawned", "and then only if the player follows
them around" and "so the route can be ad-hoc" (inbox #1460 in silky-lemur). **Read as** (the orchestrator's
reading): the dog walker, the police patrol and the military convoy are to be put in the world just
ahead of her when she comes near, and each one's route is worked out as it goes, from where it was
put, so like the beats sited from her walk they depend on her path. Each is put just ahead of her on
its first leg, and its route is worked out as it goes, from the end of each leg while she can see
it: a car drives from junction box to junction box by the walk's through roads (`WayOn`,
`ThroughRoads`), so it never comes to a precinct's paving, a closed street, a street a calm zone
absorbed or the map's edge, a walker walks straight on, and each leaves by legs of the same, held to
her sight (`EventInstance.go_on_by()`), so a sent car keeps to carriageway while she can see it (the
game's rule for an event car, not the player's words). **Read as** (the orchestrator's, on the Nappy
board and open to the player's correction): "just spawn in the car just ahead of the player" does
not cover a convoy from behind her, so the convoy comes only from ahead of her. The free-line probe
(`tests/probes/m129_zero_cost_line.gd`) asks whether rows that each leave her a free line together
leave none; the line rule follows her line from a junction box onto the sidewalks she walks, the
home street's included, and the probe shows every route keeping one. The player answered "sure" in
chat to option C of free-line-density and to pick (c) of line-reach-close (inbox #1461 in silky-lemur). **Read
as**: the draw gains a rule that follows her line from a junction box onto the sidewalk she walks,
for every row that lands near her route, and a street that draws after its neighbours keeps one
sidewalk open, given what they drew (with inbox #1465 in spry-plover), which the player's correction on that note
narrows to the streets a rule already keeps walkable, the streets of her routes.

## What is left, in order

The steps are the design review's points, which the player approved: "agree on all design review
points. let's do it", and "I saw the review and approved it" (inbox #1268 in olive-ferret). The mechanism under
each step is the same review's worked-out detail, written after the player had read its points; its
full text names the files each step owns.

4. **The beats become rigged marbles.** The walk's sitings
   (`WalkSiting`: day 3's fire, the poster crews, day 6's man shouting, day 7's route van, day 11's
   added mast, the dusk fire) take a location in the next undrawn unit ahead of her, before it
   draws. **Read as** (the orchestrator's reading): a rigged marble, such as the day-6 man shouting
   due within the next two events after the mark (olive-koala 2), lands on the next location she
   comes to on her way, so a player who turns at a junction still meets him; a row she must meet
   whatever route she takes exists wherever she goes, the guarantee the covering sites gave at dawn
   (M50-the-city-points-somewhere). These stay dependent on her path on purpose. `WalkSiting` leaves the event scheduler for a
   file of its own as this step rewrites it: "yes, and make it so you can inject it which will
   allow for it to be mocked easily" (the player on the board, question walksiting-lift, 2026-11-13;
   inbox #1456 in silky-lemur). **Read as** (the orchestrator's reading): `WalkSiting` is a file of its own, handed to
   `EventsAhead` through a maker and to `EventDirector` as the day's siting, so a test of either can
   pass a mock in its place (the records polite-tapir-coral-egret and polite-tapir-busy-toad). What is
   left is the beat laid in the next undrawn unit ahead of her before it draws, and that unit's draw
   told of it (the design's pull request 4, waiting on the board questions `beats-on-her-street` and
   `beat-changes-its-unit`). The resistance's market (`ResistanceHappenings._market_ahead_of()`) asks the day's route
   tree where she is going and is handed no siting (step 4's first pull request, the record
   polite-tapir-tall-marmot): *proposed, not asked for*, the design's pick, open to the player. `RowGround._times_for_role()` stays with `RowGround.offers_for_role()` while a row's own
   ground still needs it.
5. **The escape city's draw is the same unit draw** with three settings on the day's spec: one bag
   for the whole walk, at most one event a street, and every unit drawn before she sets off, in the
   walk's own order. `EventScheduler._draw_the_walk()` and the spec's switch between draws go, and a
   refused marble stays in the bag. *Open, for the entry lilac-marten (the fuller escape), which
   retunes that density:* the player's order has empty as the rarest outcome ("trucks > explosions >
   vans > barriers > empty", inbox #785 in minty-lemur), while about a third of the streets stand empty today; this
   step keeps today's share and `tests/probes/escape_winnable.gd` shows the before and after.

Steps 4 and 5 touch different files and run in parallel. The dawn draw is a small file of its own
(`src/events/dawn_phases/dawn_draw.gd`).

**How a step is accepted.** Its suites pass, as for every step of the refactor ("for the refactor
test parity is enough", inbox #813 in curly-moose), with the tests that held main's exact counts changed to hold
the rule instead. One probe run checks the step's own guarantee: `tests/probes/walk_rows.gd` draws
every unit over its cities and prints the route tiles cut off from home, which is none or the step
is not done, and the longest chain of units one draw pulled in. The same run prints the events she
meets per walk by view beside the baseline (`baseline-measurements.md`); those are listed for the
end remeasure and no step waits on them or fits to them ("let's do remeasuring at the very end and
not get blocked by it", inbox #813 in curly-moose).
