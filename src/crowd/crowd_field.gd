class_name CrowdField
extends RefCounted
## The patch of city the crowd is actually simulated in: normally a box that travels with the
## player. An explicit recipe overview fixes it to the whole map and scales the population.
##
## In normal play the crowd exists in the few blocks around the player and nowhere
## else. **Consistency off screen does not matter, because nobody can run after a car to check it
## is still there.**
##
## That last clause is the licence for everything here. A city-wide crowd spends its population
## on pavement nobody is looking at, and the density that reaches the player is whatever is left
## over — which is how 110 cars became *"I can just ignore it and cross the street whenever"*.
## The same agents inside a box a twentieth of the area are a street with traffic on it.
##
## What is given up is continuity: the car that just went past behind you is not the car that
## comes back if you turn round. Nothing in the game can observe that, which is why it is the
## cheap half of the trade.
##
## One object rather than a query on `Crowd`, because `CrowdAgent` recycles itself and a test
## steps agents by hand with no `Crowd` ticking. The agents hold this by reference and read a
## centre that something else moves.

## Where the box is centred — the player, once there is one. Moving it re-sizes the box, which
## is the whole of `_grown_for` below.
var centre := Vector2.ZERO:
	set(at):
		_looking_at = at
		if not _stretch_box.has_area():
			centre = map.world_size() * 0.5 if city_view and map else at
			radius = maxf(map.world_size().x, map.world_size().y) * 0.5 \
					if city_view and map else _grown_for(at)
			return
		centre = _stretch_box.get_center()
		radius = maxf(_stretch_box.size.x, _stretch_box.size.y) * 0.5 + Tuning.TILE_SIZE
## Half-extent of the box. Read by everything that places or recycles an agent; never set from
## outside, because it is a function of where the centre is.
var radius := Tuning.CROWD_FIELD_RADIUS
var map: CityMap
## A recipe's city overview simulates every visible street at the ordinary field density.
## The normal moving field remains the default, including after another day is started.
var city_view := false
## Authored scenes may give every pedestrian corridor equal weight; cars keep the street hierarchy.
var uniform_walkers := false
## Where the camera is looking: the point the box is asked to centre on, which a stretch's box
## does not follow. See `looking_at()`.
var _looking_at := Vector2.ZERO
## A task scene's stretch, as a world rectangle round all of it, or empty. **The box is the whole
## stretch and does not move**: the scene's crowd is the street she walks, all of it, for the whole
## scene, so nobody leaves the box and nobody is recycled for being far from her — they are
## recycled where the street stops, at its ends (`stretch_ends`).
var _stretch_box := Rect2()
## Where a stretch's streets run into the void, as the places the crowd enters it:
## `{"vertical", "corridor", "along", "direction"}`, the lane's axis, its corridor, the tile along
## it at the very end, and the way into the stretch. See `stretch_ends_of()`.
var stretch_ends: Array[Dictionary] = []

func _init(city_map: CityMap, at := Vector2.ZERO) -> void:
	map = city_map
	centre = at

func has_stretch() -> bool:
	return _stretch_box.has_area()

## Puts the box over the map's stretch and reads its ends (`CityMap.stretch`): the crowd of a task
## scene walks the stretch and nothing else.
func use_stretch() -> void:
	var box := Rect2i()
	for y in map.size.y:
		for x in map.size.x:
			if map.in_stretch(Vector2i(x, y)):
				box = Rect2i(x, y, 1, 1) if not box.has_area() else box.expand(Vector2i(x, y)) \
						.expand(Vector2i(x + 1, y + 1))
	_stretch_box = map.tile_rect_to_world(box)
	stretch_ends = stretch_ends_of(map)
	centre = _looking_at

## Where the camera is looking: the box's own centre, except on a stretch, whose box stays put while
## the camera follows her. What "out of view" is measured from (`CrowdAgent._out_of_view()`).
func looking_at() -> Vector2:
	return _looking_at if has_stretch() else centre

## **The places a stretch's crowd enters it: every lane end where one of its streets runs into the
## void.** *(azure-beaver: "walkers and cars recycled at the stretch's ends".)* A row of a corridor
## whose next tile along it is cut off (`CityMap.is_cut_off()` — ground in the witness, void in the
## scene) is an end, entered the other way. A street that ends at a building is a wall, not an end,
## and nobody enters there. Nor is a junction's own arm into the void: a walker or a car entered there
## would cross the box and be gone again in a few strides, so an end needs more of the stretch
## behind it than a junction is wide.
static func stretch_ends_of(stretch_map: CityMap) -> Array[Dictionary]:
	var ends: Array[Dictionary] = []
	var seen := {}
	for y in stretch_map.size.y:
		for x in stretch_map.size.x:
			var tile := Vector2i(x, y)
			if not stretch_map.in_stretch(tile):
				continue
			for vertical: bool in [true, false]:
				var cross: int = tile.x if vertical else tile.y
				if CityMap.corridor_offset(cross) < 0:
					continue
				var step := Vector2i.DOWN if vertical else Vector2i.RIGHT
				for outward: int in [-1, 1]:
					if not stretch_map.is_cut_off(tile + step * outward):
						continue
					var run := 0
					while run <= Tuning.STREET_WIDTH and stretch_map.in_stretch(tile - step * outward * (run + 1)):
						run += 1
					if run < Tuning.STREET_WIDTH:
						continue
					var along: int = tile.y if vertical else tile.x
					var corridor := CityMap.junction_index(cross)
					var key := Vector4i(int(vertical), corridor, along, -outward)
					if seen.has(key):
						continue
					seen[key] = true
					ends.append({"vertical": vertical, "corridor": corridor, "along": along,
							"direction": float(-outward)})
	return ends

## Half-extent that keeps the amount of **city** in the box the same wherever she is standing.
##
## The population is a fixed number per act and a box near the boundary is half wall, so a box of
## fixed size spreads the same two hundred people over half the ground: against the west wall it is
## 53% city and still puts 67 walkers on screen — the same count as mid-map, in half the streets —
## and the corridors beside the wall read as 1.6x an ordinary middle one, loud enough that on two
## of five seeds one of them beats the main road.
##
## The fix is a property of the box rather than of the population, which is why it is here and is
## nine lines: everything downstream already reads `radius`, so `contains`, `along_bounds` and
## `corridor_range` all follow, and no agent is ever created, destroyed or made to vanish. Growing
## it is always safe — the floor under `CROWD_FIELD_RADIUS` is that nothing may be seen to appear,
## and that is a floor.
##
## Solved by iteration rather than in closed form. The exact answer is a quadratic whose terms
## depend on which of the four sides are against a wall and which of them clip *while it grows*,
## which is four cases to get wrong; scaling by the square root of the shortfall converges to
## within a pixel in three passes because a bigger box can only add city on the sides that are
## not already against a wall.
func _grown_for(at: Vector2) -> float:
	if not map:
		return Tuning.CROWD_FIELD_RADIUS
	var want := pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0)
	var grown := Tuning.CROWD_FIELD_RADIUS
	for _pass in 3:
		var area := _city_area(at, grown)
		if area <= 0.0 or area >= want:
			break
		grown *= sqrt(want / area)
	return grown

## How much of a box of this size, centred here, is inside the city.
func _city_area(at: Vector2, half: float) -> float:
	var extent := map.world_size()
	var across := minf(extent.x, at.x + half) - maxf(0.0, at.x - half)
	var down := minf(extent.y, at.y + half) - maxf(0.0, at.y - half)
	return maxf(0.0, across) * maxf(0.0, down)

## True while a point is inside the box. `slack` widens it, which is how an agent is allowed a
## little way past the edge before it is recycled — otherwise one that recycles onto the
## boundary can qualify to be recycled again on the next frame.
func contains(at: Vector2, slack := 0.0) -> bool:
	if city_view:
		return Rect2(Vector2.ZERO, map.world_size()).grow(slack).has_point(at)
	return absf(at.x - centre.x) <= radius + slack \
			and absf(at.y - centre.y) <= radius + slack

## The lowest and highest coordinate the box spans along an axis, clamped to the map. Agents
## enter at one of these and leave at the other.
func along_bounds(vertical: bool) -> Vector2:
	var extent := map.world_size()
	var here: float = centre.y if vertical else centre.x
	var limit: float = extent.y if vertical else extent.x
	return Vector2(maxf(0.0, here - radius), minf(limit, here + radius))

## The corridors of one axis that the box overlaps, as an inclusive index range.
##
## Clamped to the city rather than to the box: near the map edge the box hangs over the
## boundary wall, and a corridor index out there does not exist.
##
## This used to claim the clamp is *why* the crowd thins out in the corner of the map instead of
## bunching against the wall, "because there are simply fewer streets to put anybody on". On its
## own it does the opposite: fewer streets and the same two hundred people is more people per
## street, which measures 1.6x an ordinary corridor beside the wall. What makes the sentence
## true is `_grown_for` — the range still clamps, and the box it clamps is now big enough that
## the streets left in it hold the population at the density they hold it at mid-map.
func corridor_range(vertical: bool) -> Vector2i:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	var last := CrowdLanes.corridor_count(blocks) - 1
	# The cross-axis coordinate is what picks a corridor: a vertical corridor is a range of x.
	var here: float = centre.x if vertical else centre.y
	var lo := floori((here - radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	var hi := floori((here + radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	return Vector2i(clampi(lo, 0, last), clampi(hi, 0, last))
