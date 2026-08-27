extends Node
## Central balance table. Every gameplay constant lives here so tuning is one file.
##
## See docs/MECHANICS.md for the reasoning behind these numbers.

## The catalogue validates itself when it is first asked for; traffic has no catalogue to
## hang that on, so the one contract that is not about an event is checked here on boot.
func _ready() -> void:
	validate_traffic()

# ---------------------------------------------------------------- movement ---

const WALK_SPEED := 92.0
const RUN_SPEED := 168.0
const ACCELERATION := 700.0
const FRICTION := 900.0
## Below this speed the player counts as idle (sleepiness drains).
const IDLE_SPEED_THRESHOLD := 12.0

# ------------------------------------------------------------- sleepiness ---

const METER_MAX := 100.0

## The pitch these three make together is the whole loop, and it is the answer to findings
## 2 and 4 from the first playtest: a day used to be winnable by circling the starting block,
## which made the city decoration.
##
## An ordinary street makes real progress and never enough. A whole day of clean street
## walking reaches about three quarters of the meter, so the walk out is worth something and
## the walk out alone can never finish; only calm ground can. `tests/test_meters.gd` holds
## both halves of that, in terms of `day_length()` rather than in numbers, so a change to
## the day cannot quietly make the street sufficient again — which is what kept them honest
## when M18 cut the day from 330s to 180s.
const SLEEPINESS_GAIN_WALKING := 0.42
## Standing still has to be strictly worse than walking, or waiting is a strategy. It also
## has to stay cheaper than a calm zone gives, because stopping is the counterplay to a loud
## event and pricing it above the park's own rate would take that move away.
const SLEEPINESS_DRAIN_IDLE := 1.0
## Playtest 02, finding 1: *"the difference of a park is barely noticeable... I don't want to
## circle in a park for two minutes just to fill up the bar."* At M14's 3.5x a calm stretch
## ran 119s, which is not a reward, it is a wait — and at three and a half times a rate you
## cannot see, it did not even read as faster than the pavement.
##
## At 10x it is 24s from empty, and a second in a park is worth ten on the street. That makes
## a day comfortably winnable *once calm ground is reached*, which is the point: the day is
## meant to be lost on the way there, not in it. See docs/PLAYTEST-02.md, decision 1.
const SLEEPINESS_CALM_ZONE_MULTIPLIER := 10.0
## Sleepiness the baby keeps after being woken up. Half the bar, which is now about twelve
## seconds of park — a fifth of a well-played day, which is what it was before and should
## stay whatever the rates are.
const WAKE_SLEEPINESS_PENALTY := 50.0

## Sleepiness per second on calm ground.
func sleepiness_gain_calm() -> float:
	return SLEEPINESS_GAIN_WALKING * SLEEPINESS_CALM_ZONE_MULTIPLIER

# ------------------------------------------------------------- excitement ---

## While excitement is at or above this, sleepiness is frozen.
const EXCITEMENT_CALM_THRESHOLD := 35.0
## A sleeping baby woken above this goes back to AWAKE.
const EXCITEMENT_WAKE_THRESHOLD := 60.0
## Incoming excitement multiplier while the baby is asleep.
const SLEEPING_SENSITIVITY := 0.55

const EXCITEMENT_DECAY_IDLE := 6.0
const EXCITEMENT_DECAY_WALKING := 3.5
const EXCITEMENT_DECAY_RUNNING := 0.5
## The park has to read on *both* bars, not just the sleepiness one — half of "this is
## working" is the excitement visibly falling away as she walks in under the trees.
const EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER := 2.2

## Excitement per second at full sprint, scaled by how far above walk speed we are.
const EXCITEMENT_FROM_RUNNING := 9.0
## Constant dread while standing in an alley.
const EXCITEMENT_FROM_ALLEY := 3.0

# ---------------------------------------------------------------- telegraph ---

## Fraction of full intensity an event emits while still telegraphing.
const TELEGRAPH_INTENSITY_FRACTION := 0.15
const TELEGRAPH_TIME_DEFAULT := 2.5
## Hard-fail events must give twice the escape margin of an ordinary event.
const TELEGRAPH_HARD_FAIL_MARGIN := 2.0

# ---------------------------------------------------------------------- run ---

const RUN_LENGTH_DAYS := 14
const STARTING_NERVES := 3
## A day is aimed at **about a minute of play, with a grace of three**. Dusk is the grace,
## not the target: a day walked well is over in a minute, and the three minutes are there for
## a day that goes wrong — a bad route, a park that turned out to be spoiled, a baby woken on
## the way home.
##
## It was 330s until M18, which made the outer bound the *typical* length and the meter the
## thing standing between you and it. Cutting it was the other half of finding 1: two minutes
## of standing in a park inside a five and a half minute day is a game about waiting.
const DAY_LENGTH_SECONDS := 180.0
## Curfew (day 6+) shortens the day by this fraction.
const CURFEW_DAY_LENGTH_MULTIPLIER := 0.8

const RESISTANCE_GOAL := 4

# --------------------------------------------------------------------- city ---

const TILE_SIZE := 32
const BLOCK_SIZE := 8
## Sidewalk(2) | road(2) | sidewalk(2). A 1-tile sidewalk left only 2px of clearance for
## the rig, which made walking a street feel like threading a needle.
const STREET_WIDTH := 6
const SIDEWALK_WIDTH := 2
const CITY_BLOCKS := Vector2i(7, 7)

const MIN_CALM_BLOCKS := 3
const MAX_CALM_BLOCKS := 6
## Walking distance in tiles, not straight-line: the calm has to be earned.
const MIN_HOME_TO_PARK_TILES := 30
const PARK_SPOIL_CHANCE := 0.35

## Per-purpose chance a block is split by a through-alley.
const ALLEY_CHANCE := {
	GameEnums.BlockPurpose.RESIDENTIAL: 0.25,
	# Commercial blocks already have a plaza carved out; a second hole through the same
	# lot leaves slivers of building and an alley that opens onto a square.
	GameEnums.BlockPurpose.COMMERCIAL: 0.0,
	GameEnums.BlockPurpose.INDUSTRIAL: 0.5,
	GameEnums.BlockPurpose.CIVIC: 0.0,
	# A courtyard block has a court cut out of it already, and an alley through that court
	# would open the one piece of calm that is supposed to be hidden.
	GameEnums.BlockPurpose.COURTYARD: 0.0,
	GameEnums.BlockPurpose.PARK: 0.0,
	GameEnums.BlockPurpose.FOREST: 0.0,
	GameEnums.BlockPurpose.QUIET_SQUARE: 0.0,
}

# ---------------------------------------------------- block purposes and arcs ---
# Finding 7: more variety in areas, and a city that becomes a different city while you walk
# around in it. Every block is generated with an arc — the ordered purposes it may pass
# through — so the transitions are always coherent and the whole run can be checked at
# generation instead of rescued day by day. See docs/CITY.md, "Block purposes".

## Courtyards are cut into residential blocks rather than taking a block of their own.
const COURTYARD_CHANCE := 0.35
const MAX_COURTYARD_BLOCKS := 3
const COURTYARD_SIZE_TILES := 4

## The hard floor: this many blocks must still be calm on the last day. A day can only be
## won on calm ground, so an arc set that takes all of it makes an unwinnable run rather
## than a hard one. `CityGenerator.validate()` enforces it.
const MIN_CALM_BLOCKS_AT_END := 2

## Chance a calm block that *may* be taken is scheduled to be, and the earliest day it can
## happen. Act III, when the vans start: the parks go at the same time the people do.
const REQUISITION_CHANCE := 0.55
const REQUISITION_FIRST_DAY := 8

## A commercial block goes dark before anything else happens to it.
const BOARDING_CHANCE := 0.5
const BOARDING_FIRST_DAY := 8

## Chance a built block's arc ends in ashes. Event-caused, so it only happens if something
## actually burns there — most of these never fire, which is the point.
const BURN_CHANCE := 0.45
const BURN_FIRST_DAY := 3
const ALLEY_WIDTH_TILES := 2

## Tiles per side of the plaza carved out of a commercial block.
const SQUARE_SIZE_TILES := 4
## The home is a notch in the south edge of a residential block.
const HOME_SIZE_TILES := Vector2i(2, 2)

# ----------------------------------------------------------- road closures ---
# Playtest 01, finding 12: prune the road network per day so the route is a real decision —
# avoidable, but clearly "not that way". See docs/CITY.md, "Road closures".

## Streets closed per day, by act. Deliberately light. M16 was drafted as though closures
## would be the only thing making a route interesting; playtest 02's findings 2 and 3 put
## route pressure at the scale of a *block* instead — which side of the road to walk down,
## forty times a day — and closures tuned as the sole source of pressure would be far too
## heavy underneath that. Four closed streets out of 112 is a city that has had a bad
## morning, not a city under siege.
const CLOSURES_PER_ACT: Array[int] = [1, 2, 3, 4]

## How much likelier a closure is to land on a street the player would actually have used
## than on one they would not. A closure in the far corner of the map is not a decision, it
## is scenery; this is what aims the mechanic at the route.
const CLOSURE_ROUTE_BIAS := 5.0
## How many blocks longer than the best route a street may be and still count as "on the
## way". At 0 only the single shortest line counts, which aims every closure at the same few
## streets; at 1 it is roughly the set of routes a player would consider.
const CLOSURE_ROUTE_SLACK := 1

## The day-level invariant, and the whole reason the planner is allowed to close anything:
## **at least this many calm areas keep at least two distinct routes to them.** Two routes,
## because one route is a corridor and a corridor is not a decision; two areas, because a
## choice of destination is what makes a choice of route mean anything.
const MIN_CALM_AREAS_WITH_TWO_ROUTES := 2

## How deep the barrier across a closed street's mouth is, in pixels. Thin enough to read as
## a line drawn across the road, thick enough that nothing walks through it in one frame.
const CLOSURE_BARRIER_DEPTH := 24.0

## Streets closed on a given day.
func closures_for_day(day: int) -> int:
	return CLOSURES_PER_ACT[clampi(act_for_day(day) - 1, 0, CLOSURES_PER_ACT.size() - 1)]

# --------------------------------------------------------------- the crowd ---
# Findings 3, 8 and 9 from the first playtest: there was nobody about, and passing the one
# person who was barely moved the meter. The crowd is also the answer to finding 4 — the
# base noise floor a day needs so that standing in one place cannot work. It is emergent
# rather than a city-wide constant, because a number nobody can see means nothing.

## People, then cars, on the streets in each act. The city empties as the acts turn, and
## this is the cruellest number in the game: from act III the streets are *quieter*, because
## there is nobody left going out on them. The city becomes an easier place to put a baby to
## sleep, and that is the horror. Act IV puts a little back, but it is not the same traffic.
##
## This used to be an invisible ambient band on the arterials (`busy_road` / `quiet_road`),
## which meant the player felt the city empty out without ever being able to see it. Now the
## emptiness is the empty pavement.
##
## **Since M27 these are populations of the *field*, not of the city.** The crowd lives in a
## `CROWD_FIELD_RADIUS` box that travels with the player, so the number here is what is on the
## streets *around her* rather than what is scattered over ten thousand tiles. The old numbers
## were whole-city and read a third as dense as they looked: 110 cars over sixteen corridors is
## one every six seconds in your lane, which is playtest 04's *"I can just ignore it and cross
## the street whenever"*. These are measured — see `tests/test_crowd.gd`, "the road has to be
## waited for" — rather than converted from the old ones by area.
const CROWD_PEDESTRIANS_PER_ACT: Array[int] = [200, 150, 42, 70]
const CROWD_CARS_PER_ACT: Array[int] = [46, 35, 9, 18]

## Half-extent of the box the crowd lives in, in px. Everything inside it is simulated;
## anything that leaves it is recycled to the far edge and walks back in.
##
## The floor is the screen: the viewport is 1280x720, so an agent recycled at 800px from the
## camera is always off-screen when it appears, whichever way the player is facing. The ceiling
## is honesty — a box much larger than this is spending frames on pavement nobody can see, which
## is the thing M27 exists to stop.
const CROWD_FIELD_RADIUS := 800.0

## Speed range, min..max. Walkers are slower than the player on purpose: passing someone is
## something *she* does, at a distance she chooses.
const PEDESTRIAN_SPEED := Vector2(46.0, 74.0)
## Ordinary traffic outpaces a walk but never quite matches the fire engine: an emergency
## vehicle has to stay the fastest thing on the road, or its long telegraph stops reading as
## urgency and starts reading as ordinary traffic.
const CAR_SPEED := Vector2(130.0, 185.0)

## One person, close enough to brush past. Deliberately above the walking decay: a close
## pass has to cost something or the crowd is scenery again. Walking wide of them does not
## — the pavement is two tiles, so how close to pass is a real choice.
const PEDESTRIAN_INTENSITY := 4.2
const PEDESTRIAN_INNER_RADIUS := 22.0
const PEDESTRIAN_OUTER_RADIUS := 88.0

## A car is louder than a person and passes much faster. No single car outruns the idle
## decay — the point is not that one car is dangerous, it is that on a main road there is
## always another one. The floor is the *street*, and it is emergent; the first pass at these
## numbers put the arterial at +15/s, which filled the meter in seven seconds and made the
## main road not expensive but impassable.
const CAR_INTENSITY := 5.4
const CAR_INNER_RADIUS := 38.0
const CAR_OUTER_RADIUS := 170.0

## Chance a walker turns a corner rather than carrying straight on, rolled once per
## junction. High enough that the crowd churns, low enough that streets still have flow.
const PEDESTRIAN_TURN_CHANCE := 0.35

# ------------------------------------------------- bodies on the street (M19) ---
# Playtest 02, findings 2 and 3: *"going to and from a park bears no risk. I don't bump into
# people... I cannot hit cars."* Until M19 the crowd was a field with a picture attached —
# every pavement was identical and none of them could hurt you, which is why the route was
# never a decision. See docs/MECHANICS.md, "The street has physics".

## Centre-to-centre distance at which the player and a pedestrian are touching.
##
## It has to be **under half a lane spacing**, and that is the whole of why it is 14 rather
## than a body's width. Pedestrian lanes are one tile apart, so the only line with no contact
## on it is the midline between two of them; at 18 there was no such line anywhere on a
## two-tile pavement and walking the arterial cost eleven bumps in forty seconds however
## carefully it was done. At 14, holding that line takes the same walk down to two — which
## turns the crowd from a toll into the thing playtest 02 finding 3 asked for.
const BUMP_RADIUS := 14.0
## How much of the separation the player takes; the pedestrian takes the rest. She is pushing
## a pram and they are not, and being shoved by strangers must never take the verb away.
const BUMP_PLAYER_SHARE := 0.3
## Speed of the deflection a contact gives the player. Well under `WALK_SPEED`, so a bump
## knocks her off her line without steering her.
const BUMP_SHOVE_SPEED := 55.0

## A contact is not a write to `Baby.excitement` — it agitates the *person* she walked into,
## and the crowd sums them like it always did. See the invariant in CLAUDE.md.
const BUMP_INTENSITY := 26.0
const BUMP_DURATION := 1.2
const BUMP_INNER_RADIUS := 30.0
const BUMP_OUTER_RADIUS := 90.0

## The car's body, as a box rather than a circle: a car is two tiles long and one wide, and a
## radius that covered its length would kill people standing beside it.
const CAR_STRIKE_HALF_LENGTH := 26.0
const CAR_STRIKE_HALF_WIDTH := 14.0
## Below this a car cannot run anybody over, however close they stand to it. A car halted at a
## zebra is scenery, and walking into one must not end the day.
const CAR_STRIKE_MIN_SPEED := 20.0

## Seconds of travel at which a car sounds its horn at somebody standing in its lane. This is
## the traffic fairness contract, and `validate_traffic()` checks it: the warning has to be
## long enough to walk out of the carriageway before the car arrives, with the same doubled
## margin every other hard fail gets.
const CAR_HORN_TIME := 1.6
## The horn itself, as a jolt on the car that sounded it. A near miss costs something even
## when it is only a near miss.
const CAR_HORN_INTENSITY := 18.0
const CAR_HORN_DURATION := 0.9
const CAR_HORN_INNER_RADIUS := 45.0
const CAR_HORN_OUTER_RADIUS := 190.0
## How long the exclamation mark stays up over the player after the last horn. Long enough to
## survive the gap between two cars in the same lane.
const CAR_WARNING_HOLD := 1.4

## Traffic that queues instead of driving through itself. *(M27, playtest 04: "cars still bump
## into each other".)* A car keeps `CAR_HEADWAY_TIME` seconds of clear road in front of it and
## never closes to less than `CAR_GAP_MIN`, which is a car's own length plus a nose.
##
## The relationship that matters, and the one `tests/test_crowd.gd` states: the headway has to
## be longer than the *braking* time from cruise, or a car physically cannot honour it and the
## queue resolves by interpenetration again. `CAR_BRAKE` is shared with the zebra, so this is
## free to check and cheap to get wrong.
const CAR_HEADWAY_TIME := 0.85
const CAR_GAP_MIN := 66.0

## Deceleration when a car gives way at a crossing, and how far ahead it looks for one. The
## relationship that matters is `CAR_ZEBRA_SIGHT > CAR_SPEED.y^2 / (2 * CAR_BRAKE)`: a car
## always has room to stop for a zebra it can see, so giving way is never a screech.
const CAR_BRAKE := 320.0
const CAR_ACCELERATE := 150.0
const CAR_ZEBRA_SIGHT := 200.0
## How close to the crossing the player has to be for the traffic to yield. Roughly "standing
## at the kerb waiting", which is the gesture the crossing is for.
const CAR_ZEBRA_WAIT_RADIUS := 56.0

# ------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"the cat is ineffective since it happens when it spawns — the cat should get
# spawned in in front of the player while they walk"*, and *"don't load everything upfront"*.
# Both are the same change: the world is populated around the player instead of authored across
# a map she mostly never visits. See docs/MECHANICS.md, "The world near you".

## How close the player has to get before a planned event is actually put in the world.
##
## Two floors, and the larger wins. The **screen**: half the viewport diagonal is 735px, so at
## 900 an event always appears off-camera and never pops into an empty pavement. The **fairness
## contract**: the widest field in the catalogue is 380px, so an event that streams in is
## already outside its own outer radius when it becomes visible — which is what makes streaming
## an event legal at all. `tests/test_events.gd` checks the second against the catalogue.
const EVENT_STREAM_RADIUS := 900.0
## And how far past it an event has to get before it is taken away again, so an event on the
## boundary does not flicker in and out as the player paces.
const EVENT_STREAM_HYSTERESIS := 260.0

## How far ahead of the player an `AHEAD` event crosses her line, in px. This is a *reaction
## window* stated as a distance: at `WALK_SPEED` it is the two seconds she gets between seeing
## the cat crouch and reaching the place it bolts through.
const AHEAD_LEAD_DISTANCE := 184.0
## She has to actually be going somewhere for something to happen in front of her. Below this
## there is no "in front".
const AHEAD_MIN_SPEED := 40.0
## Seconds between two `AHEAD` events, so the day's allowance is spread over the walk rather
## than spent in the first ten seconds. The director rolls within this band.
const AHEAD_INTERVAL := Vector2(11.0, 26.0)

# ------------------------------------------------ one event per block (M28) ---
# Playtest 05, finding 6: *"I want one event per block. The dog walker decision should happen
# meaningfully — I want to have to make that decision at least twice on day one."*
#
# The density lives in `EventScheduler.budget_for()` and the catalogue's `max_per_day`, both
# **measured** rather than derived. What lives here is the thing that had to be invented to
# make the density legible: until M28 the per-type caps were the only reason two of the same
# event never landed on one pavement, because placement is a uniform random tile. Raising the
# caps takes that away, so the separation becomes a rule of its own.

## Two events of the same kind never land closer than this. A block is 256px across, so this
## is "not on the same stretch of pavement" — the objection was never to seeing a second dog
## walker, it is to seeing it thirty pixels from the first, which reads as a duplicate rather
## than as a second incident.
const EVENT_SPACING_SAME := 256.0
## And nothing of any kind lands inside this of anything else, which is about two tiles: close
## enough that a café and a shouting man can share a corner, far enough that neither is drawn
## inside the other.
const EVENT_SPACING_ANY := 64.0
## Candidate tiles tried per placement before taking the roomiest one that was offered. A
## fallback rather than a failure: a scripted event has to happen, and on a full map the honest
## answer is the best spot left, not no event.
const EVENT_PLACEMENT_TRIES := 24

## The carriageway, in px — the width the player has to clear when a horn goes.
func carriageway_width() -> float:
	return (STREET_WIDTH - SIDEWALK_WIDTH * 2) * float(TILE_SIZE)

## The traffic fairness contract, and the one place it is stated.
##
## A car is not an event, so `validate_event()` never sees it: it has no telegraph, it is not
## in the catalogue, and it is lethal. What stands in for the telegraph is the road itself —
## the carriageway is painted, permanent and learnable, and stepping off the kerb is a choice
## the player makes. On top of that, a car that is actually going to hit somebody sounds its
## horn `CAR_HORN_TIME` out, and that warning must be long enough to walk the whole width of
## the carriageway with the doubled margin a hard fail is owed.
##
## Returns true if the geometry is fair; pushes an error and returns false if it is not.
func validate_traffic() -> bool:
	var required := required_horn_time()
	if CAR_HORN_TIME + 0.001 < required:
		push_error("Unfair traffic: CAR_HORN_TIME %.2fs < required %.2fs (carriageway %.0fpx)"
				% [CAR_HORN_TIME, required, carriageway_width()])
		return false
	return true

## Shortest horn a lethal car may fairly give. Kept separate from `validate_traffic()` so a
## test can check the contract without tripping the error it raises.
func required_horn_time() -> float:
	return carriageway_width() * TELEGRAPH_HARD_FAIL_MARGIN / WALK_SPEED

## Distance a car needs to stop from a given speed. Used by the crossing logic and asserted
## against `CAR_ZEBRA_SIGHT` in `tests/test_crowd.gd`.
func braking_distance(speed: float) -> float:
	return speed * speed / (2.0 * CAR_BRAKE)

## People on the streets in a given act.
func crowd_pedestrians(act: int) -> int:
	return CROWD_PEDESTRIANS_PER_ACT[clampi(act - 1, 0, CROWD_PEDESTRIANS_PER_ACT.size() - 1)]

## Cars on the roads in a given act.
func crowd_cars(act: int) -> int:
	return CROWD_CARS_PER_ACT[clampi(act - 1, 0, CROWD_CARS_PER_ACT.size() - 1)]

# -------------------------------------------------------------------- acts ---

## Day index (1-based, inclusive) at which each act begins.
const ACT_START_DAYS := [1, 4, 8, 12]

## Returns the 1-based act number for a given 1-based day.
func act_for_day(day: int) -> int:
	var act := 1
	for i in ACT_START_DAYS.size():
		if day >= ACT_START_DAYS[i]:
			act = i + 1
	return act

## Length of a given day in seconds, accounting for the curfew announcement.
func day_length(day: int) -> float:
	var length := DAY_LENGTH_SECONDS
	if day >= 6:
		length *= CURFEW_DAY_LENGTH_MULTIPLIER
	return length

# --------------------------------------------------------------- validation ---

## The fairness contract from docs/EVENTS.md: a player who starts walking away the instant
## an event becomes visible must clear its outer radius before it reaches full intensity.
##
## Returns true if the geometry is fair; pushes an error and returns false if it is not.
func validate_event(id: String, telegraph_time: float, inner_radius: float,
		outer_radius: float, hard_fail: bool, speed: float = 0.0) -> bool:
	var required := required_telegraph_time(inner_radius, outer_radius, hard_fail, speed)
	if telegraph_time + 0.001 < required:
		push_error("Unfair event '%s': telegraph_time %.2fs < required %.2fs "
				% [id, telegraph_time, required]
				+ "(inner %.0f, outer %.0f, hard_fail %s)"
				% [inner_radius, outer_radius, hard_fail])
		return false
	return true

## Shortest telegraph an event with this geometry may have and still be fair.
## Kept separate from validate_event() so tests can check the contract without tripping
## the error it raises.
##
## A stationary event only has to be walked out of, so the escape distance is the falloff
## band. An event travelling FASTER than the player sweeps its whole outer radius across
## the street instead — you cannot outwalk it, you can only get off its line — so the
## escape distance is the full radius. An event slower than walking pace (a dog walker)
## can simply be walked away from, so it uses the stationary rule.
func required_telegraph_time(inner_radius: float, outer_radius: float,
		hard_fail: bool, speed: float = 0.0) -> float:
	var margin := TELEGRAPH_HARD_FAIL_MARGIN if hard_fail else 1.0
	var escape := outer_radius if speed > WALK_SPEED else outer_radius - inner_radius
	return escape * margin / WALK_SPEED

## Excitement contribution of a source of `intensity` at distance `d`.
## Quadratic falloff between the inner and outer radius. See docs/MECHANICS.md.
func falloff(d: float, intensity: float, inner_radius: float, outer_radius: float) -> float:
	if d <= inner_radius:
		return intensity
	if d >= outer_radius:
		return 0.0
	var t := (d - inner_radius) / (outer_radius - inner_radius)
	var inv := 1.0 - t
	return intensity * inv * inv
