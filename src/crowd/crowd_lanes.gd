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
const SIDEWALK_OFFSETS: Array[int] = [0, 1, 4, 5]
## The two carriageway lanes. Traffic on 3 runs the positive way along the axis and traffic
## on 2 runs the negative way, which is the convention the whole crowd drives on.
const ROAD_OFFSETS: Array[int] = [2, 3]

## How much busier the arterial is than an ordinary street. This file is now the only place
## that says which corridor is the main road; before M13 an invisible ambient band said it
## too, and two answers to that question is one too many.
const ARTERIAL_BUSYNESS := 5.5

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
static func road_direction(offset: int) -> float:
	return 1.0 if offset == ROAD_OFFSETS[1] else -1.0

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
	var count := corridor_count(blocks)
	var total := 0.0
	for index in count:
		total += busyness(map_seed, vertical, index)
	var target := rng.randf() * total
	for index in count:
		target -= busyness(map_seed, vertical, index)
		if target <= 0.0:
			return index
	return count - 1

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
