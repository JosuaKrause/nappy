# grassy-beaver — The lessons on the route: day 1's rows at dawn and the director's hold · 2026-11-26

The second of two pull requests for the item hand-crafted-day-one (a day one that teaches): the
lessons on the tutorial route. The first built the route and its seals (the record
grassy-beaver-silky-wombat); with this one the item is built and its file is gone. The design was
the orchestrator's design document for the entry and its Opus review, neither committed.

## What the player asked, and what was built

On day 1 the obstacles on the way to the park are placed at dawn, authored to teach one lesson after
another, and placement off the route happens normally; the progression is (1) get to the park, (2)
a noise source she can pass wide, (3) one with less room, (4) crossing the road with no cars about,
(5) crossing the road with cars, (6) timing the yeller, then the park (gentle-owl #1253; the yeller
last, minty-dolphin #834).

- **The line** (`TutorialRoute`): the sidewalk she walks along each lesson street, laid by choosing
  among every choice of sides (a few dozen on a route of five or six streets): the park's side on the
  last street; a change of side across lesson (4)'s street at its start, so the sidewalk she arrives
  toward is the one the van shuts; a carriageway crossed again at the far end of lesson (4)'s street
  (lesson (5)) where any line can; and the fewest crossings before lesson (4), then in all.
- **The tree grows along the line** (`RouteTree._grow_the_tutorial()` takes
  `TutorialRoute.line_ground()`, the line's sidewalks and the junction boxes, where it took the
  route's whole streets). So the sidewalk the tree walks, which no body may take
  (`RouteSidewalkRule`), is the line's, and the far sidewalk is where a lesson's row may stand.
  `walked_ground()`, the whole route past the first block as a set, goes: nothing in the game read
  it once the tree grew on the line, and `runs_over()`, which the director asks on each of her
  steps on day 1, reads the route's rects instead of building that set every time.
- **The car-free start asks the route where the crossing is past** (merged from main, where the
  start let the cars in on the whole fourth street, `lesson_streets()` index 2):
  `TutorialRoute.ground_past_the_crossing_with_no_cars()` is the sidewalk the line leaves lesson
  (4)'s zebra on, every lesson street after it and the boxes past the zebra, and
  `CarFreeStart.for_route()` lets the cars in there. So the near sidewalk she arrives on, before the
  delivery van, holds the cars, and on a route of six lesson streets the release follows the
  lesson to its street rather than a fixed index. `crossing_with_cars()`, which nothing in the game
  read, goes; lesson (5)'s crossing is the line's (`_lay_the_line()`).
- **`DawnTutorial`** (`src/events/model/dawn_phases/`, model), after the fixed parts and day 13's
  roadblocks, before the scripted rows: each lesson's row offered its slot tile by tile on its own
  ground for the day (`RowGround.offers_for()`) and judged by the day's rules
  (`RuledLocationGround.offer_on()`), assigned to its location; every other location of the route's
  units past the first block (its lesson streets and their junction boxes, the box where it leaves
  the doorstep's street among them) drawn empty. The route reaches it in the dawn's context
  (`DawnContext.use_the_tutorial_route()`, which `DayPlanner` hands from
  `DayStreets.tutorial_route()`).
- **The director's hold** (`EventDirector.use_tutorial_route()`, handed by `EventsAhead.start_day()`):
  on the route before she has stood in the tutorial park, nothing is handed out but lesson (3)'s dog
  walker, sent the moment she is on its street. On the tutorial day the rig puts both of day one's
  dog walkers first (PLAYTEST-05 6), so the second is the first handout after the park, on her walk
  home; off the route the bag runs at its ordinary pace with what is left of the rig at its head.
- **`market_pair` is off the tutorial route's mouth seals**, beside `delivery_pair`, since the
  market stall is now a lesson's row and a side street sealed with it would blur the lesson (the
  design's own reason for keeping the van off them).

## Where the build differs from the design, and why

- **Lesson (2) is the market stall, not the leaf blower.** The design picked the leaf blower on the
  far sidewalk because his field bills her a little as she drifts toward the carriageway. The day's
  line rule (`RouteLineRule`: her line from a route's junction box along the sidewalk she walks has
  to stay free of cost, inbox #1461 in silky-lemur) refuses him on every slot of every seed measured:
  his line reach is 165px, and her sidewalk lies about 128px across the carriageway. Any row the rule
  lets stand across from the line costs nothing on it, so the design's measured difference between
  the two rows does not survive the rule; the stall (line reach 58px, a loud wall on its own
  sidewalk) is the orchestrator's own sketch (gentle-owl #1253) and stands on every suite seed. The
  design said a row found not to work is a new pick, reported; this is that pick, open to the
  player's correction.
- **The lessons count back from the park's street, and the yeller is on the street before it.** The
  design laid the yeller on street 6 with the park past its far end; the route as built lets its last
  street run along the park, and no field may reach calm ground she has not used
  (`UnusedCalmRule`, which never bends), so nothing can stand there. So the last street carries no
  lesson, the yeller paces the line's sidewalk of the street before it, lesson (4) is the start of the
  street before his and lesson (5) its far end, and a route of six lesson streets leaves its first
  one empty.
- **Placed at a deterministic slot rather than on a stream salt**: nothing is drawn, so a retried
  day 1 replays the same lessons by construction.

## Measured

`tests/probes/grassy_beaver_lessons.gd`, day 1 planned as `DayPlanner` plans it over 144 seeds
(the city suites' 24 and seeds 1 to 120):

| Lesson's row | Stands (24 suite seeds) | Stands (144 seeds) |
|---|---|---|
| market stall (2) | 24 | not yet re-measured over 144 |
| delivery van (4) | 23 | 139 |
| yeller (6) | 18 | 117 |
| leaf blower (the design's (2), before the switch) | — | 0, refused by `RouteLineRule` on every slot |

A line crossing a carriageway at lesson (5)'s junction: 144 of 144 routes. Nothing but the lessons
stood on the route's units past the first block on any seed.

The yeller's misses are the calm rule (his 223px field reaches the park from the street before it,
or another calm area) and, now and then, the line rule; the van's are a slot with no tile of its own
ground (a street tree, a built-over end). A lesson that cannot stand is not placed, and the run log
says so.

## Not done here

- **A walking rig over the seeds** for the dog walkers (lesson (3)'s met on its street, the second
  met before her door): the director's suite holds both sends on a hand-laid route; how often each is
  met in a real walk is not measured.
- **How often a car is at lesson (5)'s zebra** waits for the car-free start, which holds the cars
  until she is past lesson (4)'s zebra.

## Proposed, not asked for

The rows and the streets each lesson takes, the route's other locations drawn empty, and the
director's hold (the player's words name dawn placement only), all open to the player's correction.
