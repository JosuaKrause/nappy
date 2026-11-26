class_name ParkSigns
extends RefCounted
## **The park signs at junctions**: where the run's few signs stand and which way each points, worked
## out once for the run from the city and day 1's tutorial route (`TutorialRoute`). A sign says
## where a park is, never whether it is open today, so it stays true on every day of the run and is
## never a permanent marker pointing somewhere wrong later; the player asked for signs used
## sparingly for exactly that reason (curly-moose #819). A sign is city furniture beside the
## closures that point somewhere (`docs/CITY.md`, "Diversions — the design"): it adds to them, has no
## body, no field and no part in the meter.
##
## **Which signs** (`docs/CITY.md`, "Park signs at junctions"):
##
## - **one at the junction where the tutorial route leaves the doorstep's street**, pointing down the
##   lesson street the route takes there toward the tutorial park, where a new player stands first;
## - **one at the doorstep street's other end**, pointing back along the doorstep's street, only where
##   the tutorial park is the nearest calm area from that junction and the way to it runs back past
##   the first sign, so the two never disagree and neither points off the tutorial route;
## - **none at all where the tutorial park does not stay calm for the whole run**
##   (`BlockPlan.stays_calm()`): a park its arc requisitions would turn the sign false.
##
## Each stands on the outer corner of the junction box's sidewalk, against the block's corner, out
## of the carriageway and off the kerb she crosses at. A city handed no tutorial route, and the
## escape's stretch, stand none. Model: no node.

## One sign: the junction it stands at, the way it points, and where its post stands.
class Sign extends RefCounted:
	var _junction: Vector2i
	var _points: Vector2i
	var _tile: Vector2i

	func _init(junction: Vector2i, points: Vector2i, tile: Vector2i) -> void:
		_junction = junction
		_points = points
		_tile = tile

	## The junction it stands at.
	func junction() -> Vector2i:
		return _junction

	## The way its arrow points, one step on the lattice (`Vector2i.UP` up the screen).
	func points() -> Vector2i:
		return _points

	## The sidewalk tile its post stands on, a corner of the junction box.
	func tile() -> Vector2i:
		return _tile

var _signs: Array[Sign] = []

## The run's signs on `map` for `route`; none for a null route or a stretch of the city.
static func for_route(map: CityMap, route: TutorialRoute) -> ParkSigns:
	var found := ParkSigns.new()
	if route == null or map.has_stretch() or not map.has_plan_for(route.park_block()) \
			or not map.plan_of(route.park_block()).stays_calm():
		return found
	var turn := route.turning_junction()
	var doorstep := route.doorstep_street()
	var other_end := doorstep.other_end(turn)
	var toward_home := other_end - turn
	var home_side := _home_side(map, doorstep)
	var ahead := route.first_lesson_street().other_end(turn) - turn
	var first := _sign_at(map, turn, ahead, _corners_for(ahead, toward_home, home_side))
	if first == null:
		return found
	found._signs.append(first)
	if _points_back_to(map, route, other_end, turn):
		var back := -toward_home
		var second := _sign_at(map, other_end, back, _corners_for(back, back, home_side))
		if second:
			found._signs.append(second)
	return found

## The signs, the one at the route's first junction first.
func signs() -> Array[Sign]:
	return _signs

# --------------------------------------------------------------- placement ---

## The side of the doorstep's street the home block is on, one step across it.
static func _home_side(map: CityMap, doorstep: StreetNetwork.Segment) -> Vector2i:
	var home := map.home_block_coordinate()
	if doorstep.horizontal:
		return Vector2i.DOWN if home.y == doorstep.a.y else Vector2i.UP
	return Vector2i.RIGHT if home.x == doorstep.a.x else Vector2i.LEFT

## The corners of a junction box a sign pointing `ahead` may stand on, best first, for a player
## arriving from `arrives_from` (the arm she came along, as a step from the junction): the corner
## between that arm and the one the sign points down, where she reads it before she turns; for a
## sign pointing straight on, the home side's corner of the arm ahead. The rest follow, so a corner
## a calm zone took the sidewalk of still leaves one.
static func _corners_for(ahead: Vector2i, arrives_from: Vector2i,
		home_side: Vector2i) -> Array[Vector2i]:
	var straight := ahead.x * arrives_from.x + ahead.y * arrives_from.y != 0
	var across := home_side if straight else arrives_from
	var found: Array[Vector2i] = [ahead + across, ahead - across, -ahead + across, -ahead - across]
	return found

## A sign at `junction` pointing `ahead`, on the first of `corners` whose outer tile is sidewalk,
## or null where none is.
static func _sign_at(map: CityMap, junction: Vector2i, ahead: Vector2i,
		corners: Array[Vector2i]) -> Sign:
	var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	for corner in corners:
		var tile := Vector2i(box.position.x if corner.x < 0 else box.end.x - 1,
				box.position.y if corner.y < 0 else box.end.y - 1)
		if map.in_bounds(tile) and map.tile_at(tile) == GameEnums.TileType.SIDEWALK:
			return Sign.new(junction, ahead, tile)
	return null

# ---------------------------------------------------------- the second sign ---

## Whether a sign at `from`, the doorstep street's far end, pointing back along it toward `turn`
## is true and agrees with the first: the tutorial park is the nearest calm area from `from`, no
## other as near, and a shortest way to it runs through `turn`. Counted in streets over the ones
## the city has, every day's closures aside, since the sign stands all run.
static func _points_back_to(map: CityMap, route: TutorialRoute, from: Vector2i,
		turn: Vector2i) -> bool:
	var from_far := _streets_away(map, from)
	var from_turn := _streets_away(map, turn)
	var park := -1
	var nearest_other := -1
	for area in ClosurePlanner.calm_areas(map):
		var away := _area_away(area, from_far)
		if area.block == route.park_block():
			park = away
			if away >= 0 and _area_away(area, from_turn) + 1 != away:
				return false
		elif away >= 0 and (nearest_other < 0 or away < nearest_other):
			nearest_other = away
	return park >= 0 and (nearest_other < 0 or park < nearest_other)

## How many streets from `from` each junction is over the streets the city has, as
## `junction -> count`; a junction missing is out of reach.
static func _streets_away(map: CityMap, from: Vector2i) -> Dictionary:
	var away := {from: 0}
	var queue: Array[Vector2i] = [from]
	var head := 0
	var network := map.street_network()
	while head < queue.size():
		var at := queue[head]
		head += 1
		for segment in network.at_junction(at):
			if not map.has_street(segment.key()):
				continue
			var next := segment.other_end(at)
			if away.has(next):
				continue
			away[next] = int(away[at]) + 1
			queue.append(next)
	return away

## How many streets away `area` is: the nearest end of a street it opens onto; -1 out of reach.
static func _area_away(area: ClosurePlanner.CalmArea, away: Dictionary) -> int:
	var best := -1
	for segment in area.access:
		for end: Vector2i in [segment.a, segment.b]:
			if away.has(end) and (best < 0 or int(away[end]) < best):
				best = int(away[end])
	return best
