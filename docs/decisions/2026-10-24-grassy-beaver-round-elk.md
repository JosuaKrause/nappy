# grassy-beaver — The park signs at junctions · 2026-11-26

The item junction-signs (a day one that teaches): a few park signs at junctions, placed where what
they say stays true on every day of the run.

## The player's ask

Signs at junctions only if they can stay true across all days, and used sparingly, since they
become permanent markers that might confuse later on (curly-moose #819). Beside M50 (the city
points somewhere), whose closures act as the city's signposts: a sign adds to them.

## What was built

- **Four pictures**, `art/props/park_sign_{up,down,left,right}.svg` on `street_kit`: a green
  plate with a white reflective rim, a white tree and a white arrow, on a steel post, 28×46,
  feet-anchored. The plate faces the camera in every direction, so the printed arrow carries the
  direction; green against the closed plate's red, in the same plate family. Rendered with the
  game's SVG parser at 1× and 3× beside the closed park plate, the barrier's closed sign and a
  signal head, and seen in a day-1 frame (`docs/evidence/grassy-beaver-junction-signs-2026-11-26/`).
- **`ParkSigns`** (`src/routes/park_signs.gd`, model): the placement, worked out once from the city
  map and the tutorial route. **`ParkSign`** and **`ParkSignDrawer`** (`src/city/`, world): the
  sign as city furniture fixed for the run, drawn by `City._spawn_park_signs()` in `build()`
  beside the signal heads, with no body, field or meter part. `TutorialRoute` answers the three
  questions the signs ask (`doorstep_street()`, `turning_junction()`, `first_lesson_street()`).
- **The design's picks, built and open to the player's overturn.** One sign at the junction where
  the tutorial route leaves the doorstep's street, pointing down the first lesson street; one at the
  doorstep street's other end only on the condition below; no sign in a run whose tutorial park
  does not stay calm (`BlockPlan.stays_calm()`), since a requisitioned park would turn it false.

## Readings where the design left room

- **The second sign points back along the doorstep's street**, and stands only where the tutorial
  park is the nearest calm area from that junction (no other as near) and a shortest way to it runs
  back past the first sign, counted in streets the city has with closures aside. The design's words
  were "only if the tutorial park is the nearest calm area that way too"; a second sign pointing
  down another street toward the park was rejected because it can lead a day-1 player into the
  seals past the first block, which the design's own "either way" note warns against for signs at
  the first junction.
- **Which corner**: the outer corner tile of the junction box's sidewalk, against the block's corner.
  At the first junction, the corner between the arm she arrives along and the arm the sign points
  down; for a sign pointing straight on, the home block's side of the arm ahead; at the other end,
  the home block's side of the doorstep's street. A corner whose tile is not sidewalk gives way to
  the next.
- **None in the escape's stretch**, where the park can lie outside the cut, and none in an authored
  scene's city, which is handed no tutorial route.

## Where the code moved from the design

- The design put the placement under `src/city/`; it is in `src/routes/` beside `TutorialRoute`,
  since the folder's layer is the model the placement belongs to and `src/city/` is the world layer
  (a model file there needs a line of its own in `tools/layer_map.py`).
- `TutorialRoute` (merged with the tutorial route, #1767) had no method answering the signs'
  question, though the design's table of its readers names it; three were added.

## The measurement

`tests/probes/grassy_beaver_park_signs.gd` over the tutorial route probe's 144 seeds (the city suites'
24 and seeds 1 to 120), on 2026-11-26:

| | Cities |
|---|---|
| no tutorial route | 0 |
| no sign: the tutorial park may be requisitioned | 68 (24 of them the swing park, day 12's task park) |
| one sign | 75 |
| two signs | 1 |

Of the 76 first signs, 51 point straight on across the junction and 25 down a turn. **Nearly half the
runs stand no sign**, which is the cost the design's pick 2 named. A sign in those runs too is
ruled out, not offered: the player's condition is a sign at junctions only where it can stay across
all days (curly-moose #819), and a sign beside a park the city may requisition turns false the day it
does. The one open alternative is `TutorialRoute.for_city()` preferring a tutorial park that stays
calm all run, ordered calm park first, then six streets before seven, then park or calm zone before
square or courtyard. Over the same 144 seeds it costs:

- signs would stand in 125 of 144 runs instead of 76 (49 of the 68 runs without one gain a calm
  park; 19 still have none);
- of the 49, 19 need the seven-street route, one lesson street left empty;
- of the 49, 15 get a square or courtyard instead of a park;
- the swing park (day 12's task park) could no longer be the tutorial park;
- it edits `for_city()`, which merged in #1767, and so the route's seal tests and probes.

It is a question for the board, built on the pick as it stands.

## Checks

`tests/test_park_signs.gd` (the placement on a hand-laid route: the first sign, the second sign
and its absence where another park is nearer, none for a park that may be requisitioned, none
without a route) and `tests/test_park_sign.gd` (a sign shows the picture for its way, one picture
per way, through a recording drawer).
