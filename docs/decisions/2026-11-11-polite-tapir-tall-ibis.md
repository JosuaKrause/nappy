# polite-tapir — A sent row's route is worked out as it goes, and a sent car leaves on carriageway · 2026-11-16

**The ask.** The dog walker, the police patrol and the military convoy are put in the world just
ahead of her when she comes near, and the route of each matters only once it exists, and then only
if she follows it, so it can be worked out as it goes (inbox #1460). **Read as** (the
orchestrator's reading, kept from #1477's step): a sent row has no route planned ahead. It has the
leg it was created on, and while she could be watching it at the end of a leg it is given another,
worked out from where it stands; once she could not be watching, it is gone. That a sent car keeps
to carriageway while she can see it, leaving included, is the game's rule for an event car
(`placement-by-construction.md`, step 2), not the player's words.

**Who did what.** A Fable agent designed it (the way-on design, with a prototype that had never
run). Opus built it, through the rounds of a Fable review. With it, step 2 of
`placement-by-construction.md` is built whole.

## What was built

- **`ThroughRoads`** (`src/city/through_roads.gd`, model layer): of the stretches of carriageway
  between two junction boxes, the ones a car can drive into and go on from without turning round.
  A stretch is a car's where every tile of it is carriageway, no precinct's paving, and ground a
  vehicle may stand on now (today's closures and the bodies standing); the through roads are the
  2-core of the graph of boxes and car stretches, so every box a car can reach by them has a second
  way out. Worked out once a walk, after the walk's bodies are recorded, by `EventManager._take()`,
  for a day and for a scene recipe alike.
- **`WayOn`** (`src/events/way_on.gd`, simulation layer): the next leg of a sent row. A row of the
  road (`EventDef.keeps_to_the_carriageway()`) drives to the next junction box and through it:
  straight on where the street beyond is a through road, otherwise round the corner onto the
  crossing street, the turn that leads away from her tried first, as a quarter turn of 16px radius
  driven as three straight pieces. A walker walks straight on, a street and a box at a time.
  `drives_clear()` is the one check that a car may drive a stretch. A further leg keeps to the
  day's rule, `EventDirector.clear_to_go_on()`: out of the clear ground round today's region doors
  and out of every field a placed plan keeps clear, which `use_way_on()` tells the `WayOn` it is
  handed.
- **Who asks it.** `EventsAhead` tells each instance the director sends
  (`EventInstance.go_on_by()`), never keyed on a row, so day 13's column, the escape's trucks and the
  raid's car end their routes where they end. `EventRouteWalk` gives a further leg at the end of the
  route while she is within `Tuning.OUT_OF_SIGHT` (420px) of it.
- **The departure** (`EventDeparture`): a sent row leaves by legs of the same way on
  (`WayOn.leg_to_leave_by()`), held to her sight, so the backstop clock never deletes one she could
  be watching. Only where the way on gives no leg does it fall to the way out every event has: for
  a car, a body put down on its road since its leg was built; for the dog walker, a sidewalk that
  runs out within two tiles (a building line, the map's edge, a park), which is the ordinary case
  and may start in her view.
- **The first leg** (`EventDirector.leg_in_the_lane()`): #1477's 420px bound goes; a leg is sent
  only where `drives_clear()` holds and `next_leg()` from its end is not empty, so nothing is sent
  on a leg it could not go on from.
- **The designer's three findings at `main`, each confirmed by a run and fixed**: the convoy, which
  has no `EventDef.vehicle` and walks as a figure, and the sent dog walker could be deleted in her
  view by the departure's backstop clock (`EventDeparture.LEAVING_GIVES_UP`, 6s), since neither
  departure was held to her sight (now every departure by legs is); the first leg asked only that
  a tile was no precinct's paving, never that it was carriageway (now `drives_clear()` asks both);
  and `EventDef.is_sent_ahead()` is true of every copy of a sent row, day 13's column, the escape's
  trucks and the raid's car among them, so a route that goes on is told per instance by whoever
  sends it, never keyed on the row.
- **The convoy comes only from ahead of her** (`SentAhead.warned_first()`), and the setting that let
  a row come from either end is deleted with the director's coin flip.
- **A scene recipe's bodies are recorded before its way on is made**, so its through roads have
  them (`EventManager.start_recipe()` hands `_take()` its bodies to record).

## What was measured

Against `main` at `281b673ae`, from throwaway probes deleted before commit, unless a line says
otherwise.

**Legs sited**, her standing on every other sidewalk tile beside a carriageway, both ways along its
street, four cities (4242, 90210, 314159, 1234567), day 13's director:

| | main | head |
|---|---|---|
| police patrol | 24,236 of 32,296 (75.0%) | 23,170 (71.7%) |
| military convoy | 26,388 (81.7%), from either end | 23,040 (71.3%), from ahead only |

The patrol's 3.3 points are the legs refused for having no way on from their end; the convoy's
further 7 points are the end behind her no longer tried.

**A day's walk** (the same four cities on days 1, 2, 3, 4, 6, 8, 10, 12 and 14, each a whole day
down the arterial's sidewalk): 9.78 met a day at both; the closest pair of arrivals 11.20s at both;
at most 3 waiting at once at both; dog walkers 119 at main and 121 at the head, patrols 40 and 38,
convoys 3 and 3, every other row the same.

**`tests/probes/olive_badger_route_mix.gd`** (12 seeds by 9 days): 9.7 met a day at both, mismatch
22.4% at main and 22.5% at the head, patrols met 98 and 99, convoys 9 and 9, return patrols landing
80 and 81 of 120, legs meeting at least one 47 of 48 at both. The reviewer re-ran it at the head and
got the same six figures.

**What a pass costs**, net points on the meter (a real `EventInstance` on open ground, the meter
from empty with the walking decay alone; the meter is 100 points, `Tuning.METER_MAX`, and the day
ends crying 9.5 past it, `Baby.EXCITEMENT_OVERFLOW_TO_CRY`). "Main" is live for its first leg only,
"head" while she can see it:

| | main | head |
|---|---|---|
| convoy from ahead, she walks on | 24 to 31 | 24 to 31 |
| convoy from ahead, she stands | 65 to 85 | 65 to 85 |
| patrol, she turns and walks with it | 7 to 29 | -4 to 20 |

And the reviewer's rows for the convoy from ahead, her 48 and 80px to the side, its first leg ending
100 to 640px past her at main:

| She | main | head |
|---|---|---|
| walks on against it | 30 to 32 | 30 to 32 |
| turns to walk its way once it has passed | 52 to 101 | 94 to 102 |
| turns away at its badge and walks ahead of it | 14 to 77 | 226 to 240, charged for 21s |

By that arithmetic the last walk ends the day, from a row that is not `hard_fail`.

**The walking sweep** (`tests/test_sent_rows_keep_to_the_road.gd`, which replaces
`test_sent_cars_off_the_paving.gd`): she walks on, walks with a row once it has passed, or follows
it street by street, from six kinds of place found from the map's own ground and never from
`ThroughRoads`, on two cities with the day's closures laid. Its own tallies at the final head: 59
places (8 plain, 15 before a paved box, 4 before a stub, 4 before a box with one way out, 24 past a
paved box, 4 toward a lethal row's field); 107 rows sent and every one seen, 65 from streets
running north-south and 42 east-west; none sent past a paved box, where `main` sends 13; before a
dead end 22 patrols and 21 convoys watched over three legs and turning a corner in her view while
not leaving, which only a row given a further leg does; 39
cars watched over 15 seconds; 89 rows followed; toward a field 2 patrols and 2 dog walkers seen
leaving for over 6 seconds. The review of the suite before this one found 24 of its 36 places
sending nothing, every row from north-south streets, and no car watched over 9.4 seconds, and it
stayed green with the through roads switched off; this one does not.

Its mutation table, on the final head of the pull request (each line removed in a detached copy, the sweep and the unit suite that names the line run together):

| Line removed | The sweep | The unit suite |
|---|---|---|
| none | passes, 14 checks | — |
| `goes_on(box, out)` in `WayOn._down_the_road()` (made `if false:`) | fails, 38 faults: cars on paving and off the carriageway before a paved box | `test_way_on`: all four "it turns away from her" cases |
| the dropping loop of `ThroughRoads._survey()` | fails, 23 faults: off the carriageway and turned on the spot before a box with one way out | `test_through_roads`: "nor the stub it leaves at the corner", "a lattice that is a single street has no through road" |
| `is_carriageway()` in `WayOn.drives_clear()` | fails, 2 faults: off the carriageway before a paved box | `test_way_on`: "nor a street a park took" |
| `drives_clear()` in `EventDirector.leg_in_the_lane()` | fails, 29 faults: on paving past a paved box, off the carriageway | `test_event_director`: "no police_patrol / military_convoy is sited on a leg a car may not drive" and "each asked of its own leg and a way on from its end" |
| `next_leg()` in `leg_in_the_lane()` | fails, 11 faults: turned on the spot past a paved box | `test_event_director`: "... or go on from (8 of 8)" for both cars, and the same "each asked" check |
| the `_must_clear_sight` line of a departure by legs | fails, 3 faults: the dog walker and the convoy gone in her view toward a lethal row's field | `test_event_departure`: "and 6s after, with her in sight of it all the while, it is still there" |
| the `leg_to_leave_by()` branch of `EventDeparture._walk_the_way()` | fails, 5 faults (turned on the spot, on paving) and "toward a field ... seen leaving for over 6s" | `test_event_departure`: "it asks for legs to leave by (0)" |
| `clear_to_go_on()` answering `true` from its first line | fails, 10 faults: live inside the lorry's field, and nothing seen leaving toward a field | `test_event_director`: "a leg past a lethal row's field is refused", "a leg past a region door is refused" |
| the `use_the_days_rule()` line of `use_way_on()` | fails the same way, 10 faults | `test_event_director`: "the director tells the way on it is handed the day's rule" |
| each of the three `go_on_by()` tellings in `EventsAhead` | fails: the patrol's 59 faults, the convoy's 31, the dog walker's 16 | — |
| `_goes_on()` in `EventRouteWalk.advance()` (made `if false:`) | fails, 2 checks: before a dead end no patrol (22 at the head) and no convoy (21) turns a corner still live. A row given no further leg ends its route at its first leg and leaves, which emits nothing, carries no cue and strikes nobody: the quiet truck, the answer to followed-convoy the player turned down | `test_event_route_walk`: "at the end of its route it asks for a further leg" |
| the turns' order (`turns.reverse()`) | passes: which turn is taken is no fault she can see | `test_way_on`: both "it turns away from her" cases on the other side, and "round the corner away from her with a body on its lane" |
| `turns_onto_her` in `EventCarDriving.check()` | passes: no walk puts her on the street round the corner within the patrol's warning | `test_police_car`: the corner case's "never strikes her" and "stands in the junction box", and the raid's car cases |
| the recipe order (`start_recipe()` recording its bodies after its way on) | not run | `test_event_manager`: "and with a recipe's barricade on the street beyond it, it no longer does" |

**At `main`** (`33be2c7ce`, the suite copied in): it fails "no sent row leaves its ground ...", with 143 faults; the eight it lists are the patrol off the carriageway and turned on the spot at the map's edge, and the dog walker gone in her view 60 and 69px from her. The other checks pass, since `main` sends from the same places. Past a paved box `main` sends 13 cars, which cross the paving; the head sends none.

## Options not taken

- **A way on straight only** (the design's way A). Straight on ends at the map's edge, a paved box
  or a street a park absorbed, and the fourth review of #1477 found 37% of convoys followed from
  behind reaching the map's edge in her view: something must still happen there.
- **Not creating the car where no way exists far enough** (the design's way C, carriageway asked
  for as far as the car stays in her view). For a patrol she walks beside there is no bound at all,
  since she is faster, and for a convoy from behind it refuses most of them. Its smallest form is
  kept: no first leg whose end has no way on.
- **Keeping `SentAhead.from_either_end` as a setting no row uses.** Code nothing reaches is deleted
  (**designing-classes**), and turning the convoy back to either end is a few lines rebuilt.
- **The turn's alternatives.** The crowd's `CarTurn`, an arc planned against the lanes it lands in,
  with its own waits and refusals: a leg is a fixed list of points the route walk drives, and its
  quarter turn takes the 16px radius the lattice gives the crowd's near-side turn, so it adds no
  dial (the design's choice 4). The turn toward her tried first: the turn away from her is tried
  first, so where both go on the car's way leads off from her (the design's choice 3). A turn round
  in the box: the event cars' sixth trap forbids it.
- **`goes_on(from, way)`**, the design's "no leg where the stretch it is on is not a through road".
  It failed nothing, neither `test_way_on` nor the sweep: every leg already drives clear into a box
  it leaves by a through road, whose far box has another way on, so it only refused a car driving
  off a stub into the through roads. Deleted; `test_way_on` asks that such a car goes on.

## Readings and answers

- **"Just ahead of the player"** (inbox #1460): the sent rows are created just ahead of her on the
  street she walks, coming toward her. A reading, open to the player.
- **The convoy comes only from ahead of her**, the orchestrator's reading on the Nappy board, open
  to the player: the player's words do not cover a convoy from behind her, so none is sent.
- **The followed convoy, settled by the player** (the Nappy board's question followed-convoy,
  inbox #1460): a sent convoy stays loud while she can see it, as the dog walker and the patrol do,
  so following it can end the day; stepping away is the lesson, as with the fire engine. The
  reviewer's rows above say what following it costs, and stepping off its street stops the cost.
  Turning it would be one setting: the convoy's
  departure told the way on and its route walk not, so its truck ends its route at its first leg,
  quiet, and still leaves by legs.
