# grassy-beaver — Day 1's tutorial route and its seals · 2026-11-25

The first of two pull requests for the item hand-crafted-day-one (a day one that teaches): the
tutorial route and the seals that close it past its first block. The lessons on the route are the
second, and the item's file now holds only them.

## The reading built

The player asked that day 1's tutorial route be sealed off except for its first block, and then that
a seal need not be a full hard seal so long as no valid route leaves the route past the first block
(gentle-owl #1253). The seed probe (`tests/probes/grassy_beaver_tutorial_routes.gd`) measured three
readings of the design's rejection rules over 144 seeds (the city suites' 24 and seeds 1 to 120),
counting the seeds whose best tutorial route has six streets (the doorstep's and five lesson
streets), only seven (one lesson street left empty), or none:

| Reading (144 seeds) | Six streets | Seven only | None |
|---|---|---|---|
| literal: no lesson-street junction on the main road, no precinct as a lesson or side street | 127 | 11 | 6 |
| the junction where the route leaves the doorstep's street may stand on the main road | 133 | 9 | 2 |
| that, plus a precinct side street allowed and sealed hard | 138 | 6 | 0 |
| as built (`TutorialRoute.for_city()`, the third reading and the stub rule below) | 137 | 7 | 0 |

The third reading is built. The guarantee is "past the first block", so the first junction off the
doorstep's street is first-block ground she may turn off at anyway, and it may stand on the main
road. A precinct side street off the route is paved frontage to frontage, so a soft pair's two
sidewalk bodies would leave its middle walkable; it is sealed with the burst water main, a day-1
hard seal, since a seal need not be a soft one where a soft pair cannot close the street.

## What was built

- **`TutorialRoute`** (`src/routes/tutorial_route.gd`, model): a pure function of the city,
  worked out once in `main._build_the_city()`, handed to `City` and on in
  `DayStreets.tutorial_route()` on the day whose spec walks it (`DaySpec.walks_the_tutorial()`,
  day 1). `for_city()` tries every six-street route, then every seven-street one, checking each
  rule before it accepts a route, and prefers a park or calm zone to a square or courtyard.
- **The tree.** `RouteTree.for_day()` takes the route as a required argument; the tutorial park's
  branch is the route, grown first, and no other branch may use the route's kept ground. The
  fallbacks that grew a second tree in `SitingMaker` and `ClosurePlanner.plan_day()` are gone.
- **The seals.** `SealPlanner.plan_day()` takes the route (`DayPlanner` hands it on). Past the
  first block each side street is sealed at its mouth on the route: a soft pair drawn from the
  day's soft pictures less the delivery van, which blocks her sidewalk for lesson (4), never
  thinned; the burst water main across a precinct. The seal stands the first tile in from the
  junction box that keeps its bodies, and her own beside them, out of the box, stepped past street
  trees. Every through-alley mouth on a lesson street, or on a side street's mouth half, is walled
  with no roll. The market pair seals mouths again, since the market stall is no longer a lesson's
  row (the design's open point 6).
- **The car accident from day 2** (minty-dolphin #834): its seal candidate carries a first day of
  its own, `SealPlanner.Candidate.first_day`, which `_eligible()` reads, since the row is scripted
  for act I and a scripted row's first day is its act's. No edit to the catalogue.
- **A still of the mouth seals** at the second junction of seed 72172's route is
  `docs/evidence/grassy-beaver-day-one-mouth-seals-2026-11-25/`.
- **Docs**: `docs/CITY.md`, "How the corridor is built" and "Sealing the tree", the latter's stale
  "hard one only from act IV" sentence corrected in its own commit; `docs/EVENTS.md`'s
  car-accident row says day 2.

## Found while building the seals, and what was done

- **A side street on the tree.** A calm area that opens onto a side street grows its branch along
  that street, which put the street on the tree (`RouteTree.is_on_the_tree()` answers for a whole
  street), so `SealPlanner.may_seal()` left it unsealed and it was a way off the route: the
  guarantee's flood leaked into most of the city on three of test_seals' six seeds. Now
  `TutorialRoute.kept_ground()` holds the half of each side street nearest the route, so no branch
  takes the ground a mouth seal stands on, and the mouth seal is placed even where a branch runs
  along the far half.
- **Open ground on a stub.** Between the junction box and the mouth seal a stub of one to three
  tiles stays open, and a park, a square or a courtyard opening onto it is a way off. `for_city()`
  refuses such a route; `SealPlanner.tutorial_mouth_stub()` says how deep the stub can be, from the
  widest picture that may seal that mouth and the street trees. The tutorial park may open onto a
  side street at either end of the last lesson street, which borders it from its first junction on.
- **Rejected on the way.** Refusing any open ground or through-alley along a side street's whole
  mouth half left almost no route, since the park's block always touches the side street at the
  start of the last lesson street; walling the alleys instead and measuring only the stub kept the
  count at the third reading's but for one seed moving from six streets to seven.
- **A pavement dead end.** A street the city does not have (`CityMap.has_street()` false) can keep
  a walkable stub of pavement off a junction box; the guarantee's flood allows such pavement and
  still asks everything past it.
- **The route line rule joined the home street's two sidewalks.** With the tutorial route on day 1's
  tree, seed 72172's route crosses junction (5, 6), where the home street meets it, from the north
  street's east sidewalk to the south street's. The homeless yeller (the man pacing a stretch of
  sidewalk, yelling every 5 s) was placed pacing the box's west edge, and his lens, the ground his
  beat never leaves free, took all of the box but its east edge and one tile of that edge, at the
  home street's carriageway: the box's north half was joined only to the home street's north
  sidewalk and its south half only to the south one, and nothing joined the two. test_seals' check
  of the box (a flood inside the box joining every route street) failed. `RouteLineRule` accepted
  him because its flood started from all the free tiles of the first far end at once, and the home
  street's far end lies on both its sidewalks, so one flood seeded on both sides reached every
  other far end through two halves nothing joined. The cause was in the rule, not in the tutorial
  tree, which only put the home street's junction on the route, and not in the check. The rule now
  floods from each free tile of the first far end one piece of free ground at a time and accepts
  only where one piece holds a box tile, every far end and every mouth; the two sidewalks of a far
  end meet only across the carriageway at the next junction, which is no part of the crossing.
  The same holds for a route street while a man paces it, whose far sidewalk joins the ground.
  `tests/test_route_line_rule.gd` holds it on a hand-drawn map: refused with the home street
  named (allowed before the fix), and one tile longer, a beat that leaves the east edge whole
  stands. Rejected: relaxing test_seals' check to let the home street's sidewalks join the box,
  since the walk it would count goes a block round and across the home street's far junction.

## The tests

`tests/test_seals.gd` hands day 1 its tutorial route, as the game does, and holds: each side
street sealed at its mouth with a whole pair (or the burst main across a precinct), never the
delivery van, out of the junction box; every alley mouth on a lesson street walled; the guarantee on
the full walkable tile graph (soft-sealed sidewalks, closures, body discs and every carriageway
between junction boxes closed, the doorstep's street and its boxes taken out: a flood from the
lesson streets reaches only the route's kept ground, dead-end pavement and the park, and a second
calm area is reachable from the first block); and no car accident on day 1 with one on day 2 or 3.
`tests/test_tutorial_route.gd` holds the route's questions on a hand-laid map.
`tests/routes_closures_rig.gd` plans day 1's closures off the tree with the route. The shared rigs
that grow a tree without a dawn (`rig_streets`, `game_dawn`, `event_manager_rig`,
`scene_world`) hand null and say why; the other callers, about forty suites and probes not about
the tutorial, hand null.

## Left open

- **The lessons**: the item's file holds them.
