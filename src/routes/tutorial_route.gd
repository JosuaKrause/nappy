class_name TutorialRoute
extends RefCounted
## **Day 1's tutorial route**: the doorstep's street (the first block), then the lesson streets one
## after another, then the tutorial park, the way she is taught to walk on the day whose spec walks
## the tutorial (`DaySpec.walks_the_tutorial()`). A pure function of the run's city map, worked out
## once in the composition root (`main._build_the_city()`) and handed to `City`, which hands it on
## in the day's `DayStreets`; nothing derives it a second time, and a city handed none has none.
##
## The design is `docs/CITY.md`, "Day 1's tutorial route". The player asked for day 1 sealed off
## past its first block, both sidewalks of every side street blocked and the street open, so that no
## valid route leaves the tutorial route past the first block (gentle-owl #1253).
##
## **Only a route the seals can close is taken**, checked before it is accepted (**city**), never
## repaired after. `for_city()` tries every route of six streets, then of seven (one lesson street
## left empty), and refuses one whose lesson streets
##
## - **run along the main road or end at one of its junctions**, past the first: the spine is never
##   sealed on a day, so it would be a way off along its sidewalks. The junction where the route
##   leaves the doorstep's street may stand on it, since that junction is first-block ground she may
##   turn off at anyway;
## - **are a precinct**: a soft seal leaves a precinct's paved middle walkable, and a lesson street
##   is never sealed. A precinct **side street** is allowed and sealed hard at its mouth
##   (`SealPlanner`), since a seal need not be a soft one where a soft pair cannot close the street;
## - **border open ground**, other than the tutorial park on the last street or at its far junction:
##   a park, a zone, a square or a courtyard opening onto a lesson street is a way off no seal closes;
## - **border the home block**: the home-street rule keeps every row off its four streets;
##
## and keeps, of the rest, one whose tutorial park is a park or a calm zone where one fits, a square
## or a courtyard otherwise, whose side streets past the first block open onto no open ground
## between the route and their seal (the park aside, at the last street's ends), and from
## whose first block a second calm area stays reachable. A through-alley with a mouth on a lesson
## street or a side street's mouth half refuses nothing: the seals wall that mouth.

## The doorstep's street: the first block, which the route starts in and nothing seals.
var _home: StreetNetwork.Segment
## The lesson streets, in the order she walks them, the first leaving the doorstep's street.
var _streets: Array[StreetNetwork.Segment] = []
## The junctions the route passes, from the one it leaves the doorstep's street at to the far end
## of the last lesson street: one more than `_streets`.
var _junctions: Array[Vector2i] = []
## The tutorial park: the block that anchors it, and its own calm ground.
var _park_block := Vector2i(-1, -1)
var _park_rect := Rect2i()
## The map the route was laid on, for the questions about what opens onto it.
var _map: CityMap

## A route laid by hand or by `for_city()`: the doorstep's street, the lesson streets in order, the
## junctions from the doorstep's street to the far end of the last one, and the park.
func _init(map: CityMap, home: StreetNetwork.Segment, streets: Array[StreetNetwork.Segment],
		junctions: Array[Vector2i], park_block: Vector2i, park_rect: Rect2i) -> void:
	_map = map
	_home = home
	_streets = streets
	_junctions = junctions
	_park_block = park_block
	_park_rect = park_rect

# ---------------------------------------------------------------- questions ---

## The lesson streets, in the order she walks them.
func lesson_streets() -> Array[StreetNetwork.Segment]:
	return _streets

## The block that anchors the tutorial park, as `CityMap.calm_blocks_now()` names it.
func park_block() -> Vector2i:
	return _park_block

## The tutorial park's own calm ground.
func park_rect() -> Rect2i:
	return _park_rect

## Every tile of the route past the doorstep's street, as a set: the junction it leaves that street
## at, the lesson streets, and the junction boxes between and after them. `RouteTree` grows the
## park's branch on this ground alone.
func walked_ground() -> Dictionary:
	var found := _ground_past_the_first_block()
	for tile in _map.rect_tiles(_box(_junctions[0])):
		found[tile] = true
	return found

## The ground no other branch of the day's tree may use: the lesson streets, every junction box
## past the first, the half of each side street past the first block nearest the route (its
## mouth, where `SealPlanner` stands its seal), and the tutorial park. So no other branch merges
## into the route past its first block, reaches the park another way, or runs over a side street's
## mouth: a calm area that opens onto a side street is reached along the far half, so the seal at
## the mouth never stands on a branch and never leaves the side street open for one.
func kept_ground() -> Dictionary:
	var found := _ground_past_the_first_block()
	for tile in _map.rect_tiles(_park_rect):
		found[tile] = true
	for mouth in side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		for tile in _map.rect_tiles(_mouth_half(segment, bool(mouth[1]))):
			found[tile] = true
	return found

## The half of `segment` nearest its `at_a` end: the ground a seal at that mouth stands on.
static func _mouth_half(segment: StreetNetwork.Segment, at_a: bool) -> Rect2i:
	var rect := segment.tile_rect()
	if segment.horizontal:
		var half := rect.size.x / 2
		return Rect2i(Vector2i(rect.position.x if at_a else rect.end.x - half, rect.position.y),
				Vector2i(half, rect.size.y))
	var tall := rect.size.y / 2
	return Rect2i(Vector2i(rect.position.x, rect.position.y if at_a else rect.end.y - tall),
			Vector2i(rect.size.x, tall))

## The side streets past the first block, each with the end of it that opens onto the route
## (`true` for its `a` end), one entry per mouth: every real street meeting the route at a junction
## past the first that is not a lesson street. A side street with both ends on the route has two.
func side_street_mouths() -> Array[Array]:
	var found: Array[Array] = []
	var on_route := {}
	for segment in _streets:
		on_route[segment.key()] = true
	for i in range(1, _junctions.size()):
		var junction := _junctions[i]
		for arm in _map.street_network().at_junction(junction):
			if on_route.has(arm.key()) or not _map.has_street(arm.key()):
				continue
			found.append([arm, arm.a == junction])
	return found

## The through-alleys with a mouth on a lesson street or on a side street's mouth half past the
## first block (the stub between the route's junction box and the side street's seal), each with
## which mouth (`true` for the one at its rect's start), one entry per such mouth.
func alley_mouths() -> Array[Array]:
	var found: Array[Array] = []
	var lesson := {}
	for segment in _streets:
		for tile in _map.rect_tiles(segment.tile_rect()):
			lesson[tile] = true
	for mouth in side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		for tile in _map.rect_tiles(_mouth_half(segment, bool(mouth[1]))):
			lesson[tile] = true
	for rect in _map.alley_lots():
		if _map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		var vertical := rect.size.x < rect.size.y
		for at_start: bool in [true, false]:
			var mouth := SealPlanner.alley_mouth_rect(rect, vertical, at_start)
			var outside := mouth.position + (
					(Vector2i.UP if at_start else Vector2i(0, mouth.size.y)) if vertical
					else (Vector2i.LEFT if at_start else Vector2i(mouth.size.x, 0)))
			if lesson.has(outside):
				found.append([rect, at_start])
	return found

func _ground_past_the_first_block() -> Dictionary:
	var found := {}
	for segment in _streets:
		for tile in _map.rect_tiles(segment.tile_rect()):
			found[tile] = true
	for i in range(1, _junctions.size()):
		for tile in _map.rect_tiles(_box(_junctions[i])):
			found[tile] = true
	return found

static func _box(junction: Vector2i) -> Rect2i:
	return Rect2i(junction * CityMap.period(), Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH))

# ------------------------------------------------------------------ choosing ---

## The lesson streets a route of six streets has, the doorstep's not counted.
const LESSON_STREETS := 5

## Day 1's tutorial route on `map`, or null where no route keeps every rule. See the class doc.
static func for_city(map: CityMap) -> TutorialRoute:
	var chooser := _Chooser.new(map)
	for length: int in [LESSON_STREETS, LESSON_STREETS + 1]:
		var found := chooser.choose(length)
		if found:
			return found
	return null

## The search `for_city()` runs, with what it has learned about each street and junction kept so
## a street is judged once however many candidates reach it.
class _Chooser extends RefCounted:
	var _map: CityMap
	var _areas: Array[ClosurePlanner.CalmArea] = []
	var _area_of := {}
	var _home: StreetNetwork.Segment
	var _home_keys := {}
	var _streets := {}
	var _boxes := {}
	var _paths: Array[Array] = []
	## The street trees' footprint, which a seal at a side street's mouth steps past.
	var _trees := {}

	func _init(map: CityMap) -> void:
		_map = map
		_trees = StreetTrees.footprint_tiles(map)
		_areas = ClosurePlanner.calm_areas(map)
		for index in _areas.size():
			for tile in map.rect_tiles(_areas[index].rect):
				if Tile.is_calm(map.tile_at(tile)):
					_area_of[tile] = index
		_home = ClosurePlanner.home_street(map)
		for segment in map.street_network().around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			_home_keys[segment.key()] = true

	## The first route of `length` lesson streets that keeps every rule, a park or a zone before a
	## square or a courtyard, in the street network's own order; null where none does.
	func choose(length: int) -> TutorialRoute:
		if not _home:
			return null
		_paths = []
		for first: Vector2i in [_home.a, _home.b]:
			var seen := {_home.a: true, _home.b: true}
			var streets: Array[StreetNetwork.Segment] = []
			var junctions: Array[Vector2i] = [first]
			_extend(first, streets, junctions, seen, length)
		for parks_first: bool in [true, false]:
			for path: Array in _paths:
				var found := _accepted(path, parks_first)
				if found:
					return found
		return null

	func _extend(at: Vector2i, streets: Array[StreetNetwork.Segment], junctions: Array[Vector2i],
			seen: Dictionary, length: int) -> void:
		if streets.size() == length:
			_paths.append([streets.duplicate(), junctions.duplicate()])
			return
		for segment in _map.street_network().at_junction(at):
			if segment.key() == _home.key() or not _map.has_street(segment.key()):
				continue
			var next := segment.other_end(at)
			if seen.has(next) or not _street_keeps(segment, streets.size() == length - 1,
					streets.is_empty()):
				continue
			if not streets.is_empty() and not _box_keeps(at):
				continue
			seen[next] = true
			streets.append(segment)
			junctions.append(next)
			_extend(next, streets, junctions, seen, length)
			streets.pop_back()
			junctions.pop_back()
			seen.erase(next)

	## Whether a lesson street keeps the rules it can be judged by alone; the last one borders
	## exactly one calm area, the park, and no earlier one borders any.
	func _street_keeps(segment: StreetNetwork.Segment, last: bool, first: bool) -> bool:
		if _home_keys.has(segment.key()) or _touches_the_main_road(segment, first):
			return false
		var facts := _street_facts(segment)
		if bool(facts["precinct"]) or bool(facts["open"]):
			return false
		var areas: Dictionary = facts["areas"]
		return areas.size() == 1 if last else areas.is_empty()

	## The main road along the street, or at a junction it ends at; the first lesson street's end
	## on the doorstep's street is first-block ground and does not count.
	func _touches_the_main_road(segment: StreetNetwork.Segment, first: bool) -> bool:
		var main := _map.main_road_corridor()
		if main < 0:
			return false
		if not segment.horizontal and segment.a.x == main:
			return true
		for end: Vector2i in [segment.a, segment.b]:
			var on_the_doorstep := end == _home.a or end == _home.b
			if end.x == main and not (first and on_the_doorstep):
				return true
		return false

	## Whether a junction box between two lesson streets opens onto no open ground.
	func _box_keeps(junction: Vector2i) -> bool:
		if not _boxes.has(junction):
			var border := _border_of(TutorialRoute._box(junction))
			_boxes[junction] = not bool(border["open"]) \
					and (border["areas"] as Dictionary).is_empty()
		return bool(_boxes[junction])

	func _street_facts(segment: StreetNetwork.Segment) -> Dictionary:
		var key := segment.key()
		if not _streets.has(key):
			var facts := _border_of(segment.tile_rect())
			facts["precinct"] = TutorialRoute.is_a_precinct(_map, segment)
			_streets[key] = facts
		return _streets[key]

	## What borders a rect from outside it, street and through-alley tiles aside: the calm areas,
	## by index, and whether any other open ground does.
	func _border_of(rect: Rect2i) -> Dictionary:
		var areas := {}
		var open := false
		for tile in _map.rect_tiles(rect):
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var beside: Vector2i = tile + offset
				if rect.has_point(beside) or not _map.in_bounds(beside):
					continue
				var type := _map.tile_at(beside)
				if not Tile.is_walkable(type) or _map.is_street(beside):
					continue
				if type == GameEnums.TileType.ALLEY \
						and _map.alley_lots().has(_map.alley_at(beside)):
					continue
				if _area_of.has(beside):
					areas[_area_of[beside]] = true
				else:
					open = true
		return {"areas": areas, "open": open}

	## The route a path stands for when it keeps the rules a whole path keeps, or null.
	func _accepted(path: Array, parks_first: bool) -> TutorialRoute:
		var streets: Array[StreetNetwork.Segment] = []
		streets.assign(path[0])
		var junctions: Array[Vector2i] = []
		junctions.assign(path[1])
		var areas: Dictionary = _street_facts(streets[streets.size() - 1])["areas"]
		var park: int = areas.keys()[0]
		if _is_a_park(_areas[park]) != parks_first:
			return null
		var far := _border_of(TutorialRoute._box(junctions[junctions.size() - 1]))
		var at_far: Dictionary = far["areas"]
		if bool(far["open"]) or at_far.size() > 1 or (at_far.size() == 1 and not at_far.has(park)):
			return null
		var at_doorstep: Dictionary = _street_facts(_home)["areas"]
		if at_doorstep.has(park):
			return null
		var route := TutorialRoute.new(_map, _home, streets, junctions, _areas[park].block,
				_areas[park].rect)
		if not _mouths_keep(route, park, junctions.slice(junctions.size() - 2)):
			return null
		if not _second_area_reached(route, park):
			return null
		return route

	## Whether every side street's stub past the first block, between the route's junction box and
	## the row its seal stands on (`SealPlanner.tutorial_mouth_stub()`), opens onto no open ground:
	## the stub is a way off the route if a park, a square or a courtyard opens onto it. A
	## through-alley refuses nothing, since the seals wall its mouth there (`alley_mouths()`). The tutorial park
	## may open onto a side street at either end of the last lesson street (`last`): the park
	## borders that street from its first junction on, so she is at the park there anyway.
	func _mouths_keep(route: TutorialRoute, park: int, last: Array[Vector2i]) -> bool:
		for mouth in route.side_street_mouths():
			var segment: StreetNetwork.Segment = mouth[0]
			var at_a: bool = mouth[1]
			var border := _border_of(SealPlanner.tutorial_mouth_stub(_map, segment, at_a, _trees))
			if bool(border["open"]):
				return false
			var areas: Dictionary = border["areas"]
			var junction := segment.a if at_a else segment.b
			if areas.is_empty() or (last.has(junction) and areas.size() == 1 and areas.has(park)):
				continue
			return false
		return true

	func _is_a_park(area: ClosurePlanner.CalmArea) -> bool:
		if _map.calm_lot_blocks(area.block) > 1:
			return true
		for tile in _map.rect_tiles(area.rect):
			var type := _map.tile_at(tile)
			if type == GameEnums.TileType.COURTYARD or type == GameEnums.TileType.QUIET_SQUARE:
				return false
		return true

	## Whether a calm area other than the park is reachable from the doorstep's street and its two
	## junction boxes with the route's kept ground out, the carriageway crossed only in a junction
	## box and the main road walked only across: the ground the day's other branches grow on.
	func _second_area_reached(route: TutorialRoute, park: int) -> bool:
		var blocked := route.kept_ground()
		var sources := _map.rect_tiles(_home.tile_rect())
		for junction: Vector2i in [_home.a, _home.b]:
			sources.append_array(_map.rect_tiles(TutorialRoute._box(junction)))
		var seen := {}
		var queue: Array[Vector2i] = []
		for tile in sources:
			if _map.is_walkable(tile) and not blocked.has(tile):
				seen[tile] = true
				queue.append(tile)
		var main := _map.main_road_corridor()
		var head := 0
		while head < queue.size():
			var tile := queue[head]
			head += 1
			if _area_of.has(tile) and int(_area_of[tile]) != park:
				return true
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = tile + offset
				if seen.has(next) or blocked.has(next) or not _map.in_bounds(next) \
						or not _map.is_walkable(next):
					continue
				if CityMap.junction_at(next) == Vector2i(-1, -1):
					if Tile.is_road(_map.tile_at(next)):
						continue
					if main >= 0 and _map.street_kind_at(true, next) == GameEnums.StreetKind.MAIN:
						continue
				seen[next] = true
				queue.append(next)
		return false

## Whether `segment` is a precinct, read at its middle: the question a lesson street is refused on
## and a side street sealed hard on (`SealPlanner`).
static func is_a_precinct(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	var rect := segment.tile_rect()
	var along: int = rect.get_center().x if segment.horizontal else rect.get_center().y
	var index: int = segment.a.y if segment.horizontal else segment.a.x
	return map.street_kind(not segment.horizontal, index, along) == GameEnums.StreetKind.PEDESTRIAN
