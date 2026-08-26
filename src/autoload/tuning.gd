extends Node
## Central balance table. Every gameplay constant lives here so tuning is one file.
##
## See docs/MECHANICS.md for the reasoning behind these numbers.

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
## These are whole-city populations, and the city is 104 tiles across, so they read far
## smaller on screen than they look here: act I puts roughly one person every 100px of
## pavement, which is a busy street rather than a crowd scene.
const CROWD_PEDESTRIANS_PER_ACT: Array[int] = [420, 320, 90, 150]
const CROWD_CARS_PER_ACT: Array[int] = [110, 84, 22, 44]

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
