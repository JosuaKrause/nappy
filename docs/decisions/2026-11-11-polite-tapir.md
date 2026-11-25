# polite-tapir — The route's ground rule replaces the flood · 2026-11-11

**The ask.** A route stays open by the street's own rules, never by a flood: "there is no reason to
check whether a route is open during game play because it cannot be closed to begin with"
(inbox #1173 in gray-dolphin), and the design review's first step, which the player approved
(inbox #1268 in olive-ferret), replaces the whole-city flood with one more local rule
(`placement-by-construction.md`, step 1).

## What was built

- **`RouteGroundRule`** (`src/events/street_rules/route_ground_rule.gd`): a candidate that blocks the
  way (a body she cannot pass, or a row that ends the day, counted by its inner disc) is refused when
  its disc covers a tile a route runs along that is off the streets (an alley, a park cut, a square).
  It reads only the candidate's disc and the route's tiles and keeps nothing between asks; with no
  corridor it asks nothing. The off-the-street reading is the rule's public question, which
  `StreetInvalidation` also asks.
- **`StreetInvalidation` composes it with the three line rules** and loses its reach parameter, so
  every judge asks it: the dawn's phases and draw, the walk's sitings and the authored scenes.
- **The scars and the park spoilers ask it with the streets counted**: no body of one covers any
  route tile, nor the street she starts on, which `EventScheduler` works out once and hands the
  rule. A refused scar is not stood that day; a refused spoiler stands on the open tile of its own
  cell of the park nearest the cell's centre that the rule allows, so a used park the day could not
  shut keeps its spoilers (PLAYTEST-140 8: "a used park is shut by the events placed in it, as
  before"). A hand-drawn park in `tests/test_events_scheduler.gd` holds it, and fails with the
  spoiler dropped.
- **`RouteReachRule` is deleted.** `tests/probes/walk_rows.gd` counts, per day and summed, the route
  tiles home reached among the day's closures that the day's bodies cut off, after the dawn and at the
  end of her walk, and names the bodies behind any; the count is none on every day.

## Choices open to overturn

- **The scars and the spoilers are kept off a route's street tiles too** (the planner's, departing
  from the item's "ask the new rule"): they are asked no line rule, so the flood was the only thing
  that kept a street-wide scar such as a barricade from closing a route's street.
- **They are also kept off the street she starts on** (the builder's): the route tree does not carry
  the street her front door opens onto, and the whole-suite run showed barricade scars on its sidewalk
  sealing the home in where the flood had refused them. Drawn rows and sitings were already kept off
  that street.
- **Every judge asks the rule**, the walk's sitings, the escape's draw and the scene recipes included
  (the planner's). The escape's draw is handed no corridor and so is asked nothing. The refusal goes
  by the disc, not by the tile a row stands on, so a row standing on a sidewalk beside a route's park
  cut, square or alley mouth is refused as well as one standing on that ground. Measured with the
  rule alone over every tile the placement offers each row (`EventScheduler.open_ground_for()`, a
  wall's route cells left out), on cities 90210, 90365 and 90551 on days 6 and 13, in the pull
  request's review: from a street, the construction site (80 of 42,453 tiles), the abduction (46 of
  33,367, its 54px lethal inner disc reaching the ground beside its sidewalk) and the reversing lorry
  (10 of 9,662); off one, the street musician (451 of 2,181), the poster crew on a square (40 of
  736), the protest (39 of 6,192) and the firefight (20 of 5,416). The leaf blower, the market stall
  and the alley robbery were refused nowhere there. The walk's own sitings (the fires, the poster
  crews, day 7's van, day 11's mast) stand on streets; a route-bag place or a scene's row of these
  rows is what they lose.
- **A refused scar is not stood that day** (the planner's), as one that cut a route off was not. A
  refused spoiler is stood beside the route instead (above), the player's words deciding it.

## For the end remeasure

No body stands on a route's ground off the streets, at dawn or on her walk, which is stricter than the
flood, the rows above losing the tiles named; the scars refused on any route tile and the street she
starts on, and the spoilers moved off them within their cells, which no probe plans and the suites
witness; and the probe's `WD`, `WV` and `WK` lines, listed in pull request
#1380's description, unread.

## Verified

The whole suite ran locally before the first push; its only failures were the home-street gap above,
fixed in the rule and held by a hand-drawn map case, and the run log matched its recording. After the
fix the brief's suites and every suite that names the changed functions pass, with
`./tools/check.sh`, the layer, field-read and test-only-member checks and the lint pass.
