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
| market stall (2) | 24 | 142 |
| delivery van (4) | 23 | 138 |
| yeller (6) | 18 | 117, his beat on lesson (5)'s junction box on all 117 |
| leaf blower (the design's (2), before the switch) | — | 0, refused by `RouteLineRule` on every slot |

A line crossing a carriageway at lesson (5)'s junction: 144 of 144 routes, counted by the probe
before `crossing_with_cars()` went (the line's laying has not changed since; `test_tutorial_route`
holds the crossing on a hand-laid route). Nothing but the lessons stood on the route's units past
the first block on any seed.

`tests/probes/grassy_beaver_dog_walkers.gd` walks day 1 (the walk is `tests/tutorial_walk_rig.gd`'s)
from the doorstep along the day's branch to the tutorial park, into it, and back to the doorstep at
walking speed, and counts a dog walker the director sent as met where she was when it came nearest,
judged against the camera's view. The camera is walked as in play (`FollowCamera`: its lead eased
toward `Stroller.CAMERA_LOOK_AHEAD` along her facing at the rate `Stroller._update_camera()` eases
it, and the followed point smoothed at the speed her scene's camera sets, stepped at the physics
rate), and then held a fixed distance ahead of her along her facing. Over 144 seeds (the city
suites' 24 and seeds 1 to 120):

| Camera | Lesson (3)'s dog walker met on its street | The second met on her walk home, before her door |
|---|---|---|
| as in play | 141 (on seeds 1, 10 and 48 it is met elsewhere on her way out) | 144 |
| 23px ahead | 141 | 144 |
| 31px ahead | 106 | 144 |
| 46px ahead (the whole look-ahead, no lag) | 77 | 144 |

On the 24 suite seeds, with the camera as in play, both came within 5px of her on every seed, which
`tests/test_tutorial_dog_walkers.gd` holds. A camera held a fixed lead ahead turns with her facing
the instant she turns, where the game's eases its lead round over about a second; that is the
likely reason a fixed 31px, near play's lead on a straight walk, meets fewer than play does, read
from the two walks and not traced. Where lesson (3)'s is missed, it comes later on her way or on
her walk home, and a second still comes before her door.

**Why the first build met two on no seed.** The director counted a dog walker sent and spent its
marble when it sited one, and `EventsAhead._send_down_her_line()` then sited it again from another
heading and view and dropped it silently where that found nothing. It is now created on the path the
director sited, against the camera's whole view (`EventDirector._toward_her()` is handed the view).
Lesson (3)'s street is a block long, shorter than the view is wide, so down her line from it is
often past its far end, where a T or a calm zone has no sidewalk: the dog walker now comes down the
line's sidewalk of the street from its far end where down her line has no room, set off as she nears
the corner. The second is sent the same way on that street on her walk home, and the hold lasts on
the walk home until it has come (proposed, open to overturn). The probe itself told no view before:
its camera, never moved by a frame, stood at the world's origin.

**What the creation fix changes on every other day.** A dog walker the director sends on any day is
now created on the path it was sited on, where the old second siting dropped it whenever it found no
room. With the camera centred on her the two give the same days; with it leading her as in play they
do not. The PR's second review walked the city suites' 24 seeds to the first branch's area and back
on main and on the branch, with the camera 46px ahead of her: on day 11 the sent dog walkers met go
from 73 to 80, the loose dog from 22 to 21, the cat from 25 to 24 and the patrol from 1 to 0; on day
5 the loose dog goes from 37 to 38, the patrol from 43 to 45 and the cat from 33 to 31, and the dog
walkers stay at 61. So on a day whose camera leads, the dog walkers the director spent now arrive.

The refusals, counted by rule over the 144 seeds: the yeller's 27 misses are `UnusedCalmRule` on
22 (his 223px field reaches a calm area she has not used from every tile of his slot) and
`RouteLineRule` on the rest; the van's 6 and the stall's 2 are `RouteLineRule`. No cheap
construction raises the yeller's: his slot is the whole line's sidewalk of his street, the park's
street is refused by the calm rule, and an earlier street would put him before lesson (5), out of the
player's order. On those days day 1 teaches fewer lessons. A lesson that cannot stand is not placed, and the run log
says so.

Each lesson's row in the game on seed 4431, lesson (3)'s dog walker meeting her on its street, and
bursts of her walk from lesson (4)'s zebra over lesson (5)'s and past the yeller are in
`docs/evidence/grassy-beaver-lessons-on-the-route-2026-11-26/`. On that seed the yeller's beat
reaches lesson (5)'s zebra, so she meets him on the crossing with cars, and in one of the runs a car
sounds its horn at her there. It is so on every seed he stands on (below).

## The yeller on lesson (5)'s crossing: the choice is the player's

His slot starts at the junction she comes onto his street at, lesson (5)'s crossing with cars, and
his beat runs up to eight tiles from there, so on every one of the 117 seeds he stands on, his beat
reaches that junction's box (the lessons probe's YELLER line: no tile between the nearest end of his
beat and the box, on all 117). She meets the two lessons on one spot, where the player made timing
the yeller a lesson of its own after the crossing with cars (gentle-owl #1253), and the PR's second
review called that a defect.

Keeping him off the junction costs him almost every day. His beat leaves her no line along the
sidewalk, so the day's rules take it only where it reaches a junction box or a side route
(`StreetInvalidation`, a pacing beat that walls a sidewalk); off (5)'s box that is the far junction,
toward the park's street, where his field reaches the park she has not used (`UnusedCalmRule`, which
keeps every field off the calm ground of each area she has not settled in, so that one stays an
area she can settle in). Each option was measured over the same 144 seeds with a throwaway probe,
day 1 planned as `DayPlanner` plans it, every option on the same city:

| Option | Yeller stands | His beat's nearest end from (5)'s box | The tutorial park's calm ground his field reaches | What it costs against the player's words |
|---|---|---|---|---|
| (d) the old slot, from (5)'s junction: **the build** | 117 of 144 | no tile, on all 117 | none | lessons (5) and (6) on one spot, where the player made them two (gentle-owl #1253) |
| his slot past 4 tiles of (5)'s end of the street, the beat held to that stretch and the far box (the construction the third builder tried) | 0 | none stands | none | no yeller on day 1, so lesson (6) is lost |
| (a) his beat 4 tiles long on day 1, his slot past 2 tiles of (5)'s end | 0 | none stands | none | the same, and his beat is no longer the eight tiles the progression describes |
| (a) his beat 6 tiles long on day 1, past 2 tiles | 0 | none stands | none | the same |
| (b) his field allowed into the tutorial park's outer 2 tiles of calm ground but not its middle, his slot past 4 tiles of (5)'s end (3 tiles of edge gives the same counts) | 18 of 144 | 4 to 5 tiles | up to 14 of the park's 64 calm tiles, about a seventh of it on average, its middle on no seed | the unused-calm rule bent for the one park she is sent to: the player asked that nothing be placed onto a calm area she has not used (the words `CalmAreas.unused_ground()` quotes); the park counts as spoiled in the day's plan, and she crosses a noisy edge to settle in its quiet middle; lesson (6) still lost on 126 |
| (c) the route one street longer where he does not fit, a street with no lesson between his and the park's, his slot past 4 tiles | 40 of the 143 seeds that have such a route (1 has none) | 4 to 5 tiles | none | a sixth street that teaches nothing, about five seconds more walking to a park the orchestrator sized at five streets (gentle-owl #1253); a different route, on which the stall stands on 138 and the van on 140 (against 142 and 138); lesson (6) still lost on 103 |

So settling in the tutorial park is untouched by every option but (b), where the field reaches its
edge and never the ground more than two tiles in. The build keeps (d), the old slot, and
`test_dawn_tutorial` holds it; which to give up, the yeller apart from the crossing or the yeller on
most days, is the player's to choose, put to them on the board.

## Not done here

- **How often a car is at lesson (5)'s zebra** as she walks the line is not measured, nor whether
  timing the yeller's pass costs less than walking past him untimed; `docs/EVENTS.md` says the
  latter is unmeasured.

## Proposed, not asked for

The rows and the streets each lesson takes, the route's other locations drawn empty, and the
director's hold (the player's words name dawn placement only), all open to the player's correction.
