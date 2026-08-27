class_name CrowdLanes
extends RefCounted
## The lane geometry of the street grid, for anything that travels along it.
##
## The city is a lattice of corridors, each `sidewalk | road | sidewalk` across. A lane is
## one tile-wide strip of one of those bands, running the length of a corridor. This is the
## single place that converts between "corridor 3, offset 4" and a world coordinate, so the
## crowd never has to re-derive the layout arithmetic that `CityMap` already owns.

## Sidewalk offsets across a corridor, outermost first on each side. Four lanes of pavement
## per corridor is what makes a busy street look busy rather than look like a queue.
##
## Walkers have **no side convention**: a pedestrian picks any of the four and either direction.
## That was checked in M29 while the road was being fixed, because playtest 05 asked whether the
## pavements were mirrored the same way the carriageway was. They are not mirrored — they are
## simply unordered, which is a different thing and not a bug. Giving them one would be a design
## change with a measured cost: M19's contact numbers (eleven bumps down a lane centre against
## one on the midline) are what the pavement is balanced on, and they assume a walker may be
## coming the other way in any lane.
const SIDEWALK_OFFSETS: Array[int] = [0, 1, 4, 5]
## The two carriageway lanes, across the corridor: `ROAD_OFFSETS[0]` is the one with the smaller
## cross-axis coordinate. Which way each runs depends on the **axis** — see `road_direction()`.
const ROAD_OFFSETS: Array[int] = [2, 3]

## How much busier the arterial is than an ordinary street. This file is now the only place
## that says which corridor is the main road; before M13 an invisible ambient band said it
## too, and two answers to that question is one too many.
##
## It was 5.5 until M27. When the crowd stopped being spread over the whole city, the share
## this number takes stopped being a share of sixteen corridors and became a share of the three
## or four the player can see — so the *same* weight put half again as much traffic on the
## arterial, and at act I density there was a safe gap in it **0.6% of the time**, with a mean
## wait at the kerb of twenty-two seconds of a hundred and eighty second day.
##
## A road you have to wait for is the hazard playtest 04 asked for. A road that can only be
## crossed at a zebra is *also* fine, and is the M19 design — traffic gives way there, and the
## generator puts one at every junction, so nowhere on a street is more than seven tiles from
## one. What is not fine is a road that cannot be crossed at all and does not say so.
##
## At 5.0 the arterial keeps the noise floor it has to keep (see `tests/test_crowd.gd`, "a busy
## street never lets the meter fall") and jaywalking it is a real gamble rather than an
## impossibility. Measured with a probe, not derived; re-measure if the population moves.
const ARTERIAL_BUSYNESS := 5.0

## Corridors per axis: one on each side of every block, so one more than there are blocks.
static func corridor_count(axis_blocks: int) -> int:
	return axis_blocks + 1

## World coordinate of the centre of the lane at `offset` in corridor `index`.
static func lane_centre(index: int, offset: int) -> float:
	return (index * CityMap.period() + offset + 0.5) * Tuning.TILE_SIZE

## Corridor index a world coordinate falls in, or -1 when it is inside a block.
static func corridor_at(world_coordinate: float) -> int:
	var tile := floori(world_coordinate / Tuning.TILE_SIZE)
	if CityMap.corridor_offset(tile) < 0:
		return -1
	return floori(float(tile) / CityMap.period())

## The sidewalk lane nearest a world coordinate within corridor `index`. Used when a walker
## turns a corner: it keeps to the pavement it is already standing on rather than snapping
## across the road.
static func nearest_sidewalk(index: int, world_coordinate: float) -> int:
	var best := SIDEWALK_OFFSETS[0]
	var best_distance := INF
	for offset in SIDEWALK_OFFSETS:
		var distance := absf(lane_centre(index, offset) - world_coordinate)
		if distance < best_distance:
			best_distance = distance
			best = offset
	return best

## Which way traffic runs in a carriageway lane: +1 along the axis, -1 against it.
##
## **The city drives on the right, and that is a rule about the side of the road relative to
## travel, not about the offset.** It flips with the axis, and until M29 it did not: the whole
## crowd used `offset == 3 means positive`, which is right-hand traffic on the east-west streets
## and left-hand traffic on the north-south ones. Playtest 05, finding 2 — *"the cars are not
## consistently driving on the right side"* — and it is invisible to every other test in the
## suite, because separation, headway, capacity and noise are all true either way, and invisible
## in a still, because a stopped frame does not say which way a car is pointing. It shows up the
## moment a human watches a junction.
##
## Screen coordinates have Y pointing down, so along a **vertical** corridor +1 is south and the
## driver's right is west — the *smaller* cross coordinate. Along a **horizontal** one +1 is east
## and their right is south — the larger. Hence the flip.
static func road_direction(vertical: bool, offset: int) -> float:
	var positive_lane := ROAD_OFFSETS[0] if vertical else ROAD_OFFSETS[1]
	return 1.0 if offset == positive_lane else -1.0

## The inverse: which lane a car travelling `direction` along this axis belongs in. Written as
## the pair of one function so the two can never drift — a car that turns a corner picks its
## lane from its new direction, and a car that spawns picks its direction from its lane.
static func road_lane(vertical: bool, direction: float) -> int:
	var positive_lane := ROAD_OFFSETS[0] if vertical else ROAD_OFFSETS[1]
	return positive_lane if direction > 0.0 else (ROAD_OFFSETS[0] + ROAD_OFFSETS[1] - positive_lane)

## The corridor the arterial runs down, for one axis.
static func arterial_index(axis_blocks: int) -> int:
	return axis_blocks / 2

## How busy a corridor is, relative to an ordinary street. Seeded from the city rather than
## the day, because it is a property of the city: the same street is busy every morning, and
## learning which ones are quiet is most of what a fixed city is *for*.
static func busyness(map_seed: int, vertical: bool, index: int) -> float:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	if index == arterial_index(blocks):
		return ARTERIAL_BUSYNESS
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("busy:%d:%s:%d" % [map_seed, "v" if vertical else "h", index])
	return rng.randf_range(0.5, 1.7)

## A corridor chosen in proportion to how busy it is. This is what makes a route decision
## out of a grid: a uniform crowd would make every street equally loud, and then there would
## be nothing to choose between them.
static func pick_corridor(rng: RandomNumberGenerator, map_seed: int, vertical: bool) -> int:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	return pick_corridor_in_range(rng, map_seed, vertical, Vector2i(0, corridor_count(blocks) - 1))

## The same, restricted to an inclusive range of corridor indices — the streets that are
## actually inside the crowd's field.
##
## The weighting survives the restriction, and that is the point of doing it this way rather
## than picking uniformly among the few streets in view: the arterial is still the busy one
## when it is one of three corridors on screen, so a player who has learned which street is
## loud is still right about it.
static func pick_corridor_in_range(rng: RandomNumberGenerator, map_seed: int, vertical: bool,
		range_inclusive: Vector2i) -> int:
	var lo := range_inclusive.x
	var hi := maxi(lo, range_inclusive.y)
	var total := 0.0
	for index in range(lo, hi + 1):
		total += busyness(map_seed, vertical, index)
	var target := rng.randf() * total
	for index in range(lo, hi + 1):
		target -= busyness(map_seed, vertical, index)
		if target <= 0.0:
			return index
	return hi

## A point on the pavement beside the north-south arterial, half way down the map. The one
## place the crowd's noise floor is highest, which makes it the place worth measuring.
static func arterial_pavement(map: CityMap) -> Vector2:
	var corridor := arterial_index(Tuning.CITY_BLOCKS.x)
	var x := corridor * CityMap.period() + Tuning.SIDEWALK_WIDTH - 1
	return map.tile_to_world(Vector2i(x, map.size.y / 2))

## The same, for whichever north-south corridor this city made the quietest.
static func quietest_pavement(map: CityMap) -> Vector2:
	var count := corridor_count(Tuning.CITY_BLOCKS.x)
	var quietest := 0
	for index in count:
		if busyness(map.seed_used, true, index) < busyness(map.seed_used, true, quietest):
			quietest = index
	var x := quietest * CityMap.period() + Tuning.SIDEWALK_WIDTH - 1
	return map.tile_to_world(Vector2i(x, map.size.y / 2))
