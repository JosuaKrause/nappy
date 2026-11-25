extends RefCounted
## Measurement probe for grassy-beaver's tutorial route (a day one that teaches): over the city
## suites' seeds and seeds 1 to 120, how many cities have a six-street tutorial route that keeps
## every rejection rule of the design (the doorstep's street, then five lesson streets that touch
## no main road, meet no precinct, border no open ground but the tutorial park, border that park
## only on the last street, and border no side of the home block; a second calm area reachable
## from the doorstep's street with the route's ground taken out), how many only a seven-street
## one, and how many none; and which rule prunes most. It measures three readings in turn:
##
## - **literal**: no junction of a lesson street on the main road, and no precinct among the
##   lesson streets or the side streets at their junctions past the first block;
## - **first junction open**: the junction where the route leaves the doorstep's street may stand
##   on the main road, since it is first-block ground she may turn off at anyway;
## - **precinct side streets sealed hard**: that, and a precinct side street allowed, which a soft
##   pair cannot close (a precinct is paved frontage to frontage) and a hard seal would;
## - **as built**: `TutorialRoute.for_city()` itself (`_measure_built()`).
##
## Not a suite: it prints rather than asserts.
## Run by name:
##
##     tools/test.sh probes/grassy_beaver_tutorial_routes.gd   (prints TUTORIAL_ROUTE lines)

## The city suites' seeds: `tests/test_route_tree.gd`, `tests/routes_closures_rig.gd` and
## `tests/test_seals.gd`, each as its own sweep builds them.
static func _seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(4400 + i * 31)
	for i in 12:
		found.append(5150 + i * 13)
	for i in 6:
		found.append(71717 + i * 91)
	for i in range(1, 121):
		found.append(i)
	return found

var _pruned := {}
var _kinds := {}
## The reading measured in this pass (see the header).
var _first_junction_open := false
var _precinct_side_streets_sealed := false

func run(t: TestRunner) -> void:
	var maps: Array[CityMap] = []
	for seed_value in _seeds():
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), 1)
		map.repaint(state)
		maps.append(map)
	_measure("literal", maps)
	_first_junction_open = true
	_measure("first junction open", maps)
	_precinct_side_streets_sealed = true
	_measure("precinct side streets sealed hard", maps)
	_measure_built(maps)
	t.check(true, "a probe asserts nothing")

## **As built**: `TutorialRoute.for_city()` itself, which holds the third reading and, on top of
## it, a side street's mouth half (where its seal stands) opening onto nothing but buildings, and
## its kept ground out of the second calm area's reach.
func _measure_built(maps: Array[CityMap]) -> void:
	var six := 0
	var seven := 0
	var none := 0
	for map in maps:
		var route := TutorialRoute.for_city(map)
		var streets := route.lesson_streets().size() + 1 if route else 0
		match streets:
			6:
				six += 1
			7:
				seven += 1
			_:
				none += 1
		if streets != 6:
			print("TUTORIAL_ROUTE as built | seed %d | %d streets" % [map.city_seed(), streets])
	print("TUTORIAL_ROUTE as built | total %d seeds | six streets %d | seven streets %d | none %d"
			% [maps.size(), six, seven, none])

func _measure(reading: String, maps: Array[CityMap]) -> void:
	_pruned = {}
	_kinds = {}
	var six := 0
	var seven := 0
	var none := 0
	for map in maps:
		var found := _probe(map)
		match int(found["streets"]):
			6:
				six += 1
			7:
				seven += 1
			_:
				none += 1
		if int(found["streets"]) != 6:
			print("TUTORIAL_ROUTE %s | seed %d | %d streets | park kind %s"
					% [reading, map.city_seed(), int(found["streets"]), str(found["kind"])])
	print("TUTORIAL_ROUTE %s | total %d seeds | six streets %d | seven streets %d | none %d"
			% [reading, maps.size(), six, seven, none])
	for rule: String in _pruned:
		print("TUTORIAL_ROUTE %s | pruned by %s: %d" % [reading, rule, int(_pruned[rule])])
	for kind: String in _kinds:
		print("TUTORIAL_ROUTE %s | park kind %s: %d seeds" % [reading, kind, int(_kinds[kind])])

func _prune(rule: String) -> void:
	_pruned[rule] = int(_pruned.get(rule, 0)) + 1

# ------------------------------------------------------------------ one city ---

var _map: CityMap
var _areas: Array[ClosurePlanner.CalmArea] = []
var _area_of := {}
var _home: StreetNetwork.Segment
var _home_keys := {}
var _street_facts := {}
var _box_facts := {}
var _paths: Array[Array] = []

func _probe(map: CityMap) -> Dictionary:
	_map = map
	_areas = ClosurePlanner.calm_areas(map)
	_area_of = {}
	for index in _areas.size():
		for tile in map.rect_tiles(_areas[index].rect):
			if Tile.is_calm(map.tile_at(tile)):
				_area_of[tile] = index
	_home = ClosurePlanner.home_street(map)
	_home_keys = {}
	for side: int in [StreetNetwork.Side.NORTH, StreetNetwork.Side.SOUTH, StreetNetwork.Side.WEST,
			StreetNetwork.Side.EAST]:
		var beside := map.street_network().beside_block(map.home_block_coordinate(), side)
		if beside:
			_home_keys[beside.key()] = true
	_street_facts = {}
	_box_facts = {}
	for length: int in [5, 6]:
		_paths = []
		for first: Vector2i in [_home.a, _home.b]:
			var seen := {_home.a: true, _home.b: true}
			var streets: Array[StreetNetwork.Segment] = []
			var boxes: Array[Vector2i] = [first]
			_extend(first, streets, boxes, seen, length)
		var best_kind := ""
		for tier: String in ["park", "square or courtyard"]:
			for path: Array in _paths:
				var kind := _passes(path, tier)
				if kind != "":
					best_kind = kind
					break
			if best_kind != "":
				break
		if best_kind != "":
			_kinds[best_kind] = int(_kinds.get(best_kind, 0)) + 1
			return {"streets": length + 1, "kind": best_kind, "candidates": _paths.size()}
	return {"streets": 0, "kind": "-", "candidates": 0}

func _extend(at: Vector2i, streets: Array[StreetNetwork.Segment], boxes: Array[Vector2i],
		seen: Dictionary, length: int) -> void:
	if streets.size() == length:
		_paths.append([streets.duplicate(), boxes.duplicate()])
		return
	for segment in _map.street_network().at_junction(at):
		if segment.key() == _home.key() or not _map.has_street(segment.key()):
			continue
		var next := segment.other_end(at)
		if seen.has(next):
			continue
		var rule := _street_rule(segment, streets.size() == length - 1, streets.is_empty())
		if rule == "" and not streets.is_empty():
			rule = _box_rule(at)
		if rule != "":
			_prune(rule)
			continue
		seen[next] = true
		streets.append(segment)
		boxes.append(next)
		_extend(next, streets, boxes, seen, length)
		streets.pop_back()
		boxes.pop_back()
		seen.erase(next)

## The first rule a lesson street breaks on its own, or "".
func _street_rule(segment: StreetNetwork.Segment, last: bool, first_lesson: bool) -> String:
	var key := segment.key()
	if _home_keys.has(key):
		return "a side of the home block"
	var main := _map.main_road_corridor()
	if main >= 0 and _touches_the_main_road(segment, main, first_lesson):
		return "the main road"
	var facts := _street_border(segment)
	if bool(facts["precinct"]):
		return "a precinct"
	if bool(facts["open"]):
		return "open ground"
	var areas: Dictionary = facts["areas"]
	if not last and not areas.is_empty():
		return "calm ground before the last street"
	if last and areas.size() != 1:
		return "the last street borders no single calm area" if areas.is_empty() \
				else "the last street borders a second calm area"
	return ""

## Whether a lesson street runs along the main road or ends at one of its junctions; under the
## "first junction open" reading, the first lesson street's end on the doorstep's street does not
## count.
func _touches_the_main_road(segment: StreetNetwork.Segment, main: int,
		first_lesson: bool) -> bool:
	if not segment.horizontal and segment.a.x == main:
		return true
	var ends: Array[Vector2i] = [segment.a, segment.b]
	for end in ends:
		var on_the_doorstep := end == _home.a or end == _home.b
		if end.x == main and not (_first_junction_open and first_lesson and on_the_doorstep):
			return true
	return false

## The rule a junction box past the first block breaks, or "": a precinct arm, open ground.
func _box_rule(junction: Vector2i) -> String:
	if _box_facts.has(junction):
		return _box_facts[junction]
	var rule := ""
	for arm in _map.street_network().at_junction(junction):
		if _map.has_street(arm.key()) and _is_precinct(arm) and not _precinct_side_streets_sealed:
			rule = "a precinct side street"
	if rule == "":
		var border := _border_of(Rect2i(junction * CityMap.period(),
				Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH)))
		if bool(border["open"]) or not (border["areas"] as Dictionary).is_empty():
			rule = "open ground at a junction"
	_box_facts[junction] = rule
	return rule

func _is_precinct(segment: StreetNetwork.Segment) -> bool:
	var rect := segment.tile_rect()
	var along: int = rect.get_center().x if segment.horizontal else rect.get_center().y
	var index: int = segment.a.y if segment.horizontal else segment.a.x
	return _map.street_kind(not segment.horizontal, index, along) \
			== GameEnums.StreetKind.PEDESTRIAN

func _street_border(segment: StreetNetwork.Segment) -> Dictionary:
	var key := segment.key()
	if _street_facts.has(key):
		return _street_facts[key]
	var facts := _border_of(segment.tile_rect())
	facts["precinct"] = _is_precinct(segment)
	_street_facts[key] = facts
	return facts

## What borders a rect from outside it: the calm areas (by index), whether any other open
## ground does, and the through-alley mouths.
func _border_of(rect: Rect2i) -> Dictionary:
	var areas := {}
	var open := false
	var alleys := 0
	for tile in _map.rect_tiles(rect):
		for offset: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var beside: Vector2i = tile + offset
			if rect.has_point(beside) or not _map.in_bounds(beside):
				continue
			var type := _map.tile_at(beside)
			if not Tile.is_walkable(type) or _map.is_street(beside):
				continue
			if type == GameEnums.TileType.ALLEY and _map.alley_lots().has(_map.alley_at(beside)):
				alleys += 1
			elif _area_of.has(beside):
				areas[_area_of[beside]] = true
			else:
				open = true
	return {"areas": areas, "open": open, "alleys": alleys}

## The kind of park the path ends at when it passes the rules a whole path keeps, or "".
func _passes(path: Array, tier: String) -> String:
	var streets: Array[StreetNetwork.Segment] = []
	streets.assign(path[0])
	var boxes: Array[Vector2i] = []
	boxes.assign(path[1])
	var last := streets[streets.size() - 1]
	var areas: Dictionary = _street_border(last)["areas"]
	var park: int = areas.keys()[0]
	var kind := _kind_of(_areas[park])
	if (kind == "park" or kind == "zone") != (tier == "park"):
		return ""
	# The far junction may border the park (a zone's absorbed street); no earlier box may.
	var far := boxes[boxes.size() - 1]
	if _box_rule(far) != "":
		var border := _border_of(Rect2i(far * CityMap.period(),
				Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH)))
		var at_far: Dictionary = border["areas"]
		if bool(border["open"]) or at_far.size() != 1 or not at_far.has(park):
			_prune("open ground at the far junction")
			return ""
	for arm in _map.street_network().at_junction(far):
		if _map.has_street(arm.key()) and _is_precinct(arm) and not _precinct_side_streets_sealed:
			_prune("a precinct side street")
			return ""
	var doorstep_areas: Dictionary = _street_border(_home)["areas"]
	if doorstep_areas.has(park):
		_prune("the park on the doorstep's street")
		return ""
	if not _second_area_reached(streets, boxes, park):
		_prune("no second calm area from the first block")
		return ""
	return kind

func _kind_of(area: ClosurePlanner.CalmArea) -> String:
	if _map.calm_lot_blocks(area.block) > 1:
		return "zone"
	var counts := {}
	for tile in _map.rect_tiles(area.rect):
		var type := _map.tile_at(tile)
		counts[type] = int(counts.get(type, 0)) + 1
	if int(counts.get(GameEnums.TileType.COURTYARD, 0)) > 0:
		return "courtyard"
	if int(counts.get(GameEnums.TileType.QUIET_SQUARE, 0)) > 0:
		return "square"
	return "park"

## Whether a calm area other than the park is reachable from the doorstep's street and its two
## junction boxes, with the lesson streets, their boxes past the first and the park taken out,
## and the carriageway crossed only in a junction box and the main road walked only across.
func _second_area_reached(streets: Array[StreetNetwork.Segment], boxes: Array[Vector2i],
		park: int) -> bool:
	var size := _map.size_in_tiles()
	var blocked := PackedByteArray()
	blocked.resize(size.x * size.y)
	for segment in streets:
		for tile in _map.rect_tiles(segment.tile_rect()):
			blocked[tile.y * size.x + tile.x] = 1
	for i in range(1, boxes.size()):
		for tile in _map.rect_tiles(Rect2i(boxes[i] * CityMap.period(),
				Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH))):
			blocked[tile.y * size.x + tile.x] = 1
	for tile in _map.rect_tiles(_areas[park].rect):
		blocked[tile.y * size.x + tile.x] = 1
	var queue: Array[Vector2i] = []
	var seen := PackedByteArray()
	seen.resize(size.x * size.y)
	var sources := _map.rect_tiles(_home.tile_rect())
	for junction: Vector2i in [_home.a, _home.b]:
		sources.append_array(_map.rect_tiles(Rect2i(junction * CityMap.period(),
				Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH))))
	for tile in sources:
		if _map.is_walkable(tile) and blocked[tile.y * size.x + tile.x] == 0:
			seen[tile.y * size.x + tile.x] = 1
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
			if not _map.in_bounds(next):
				continue
			var index := next.y * size.x + next.x
			if seen[index] == 1 or blocked[index] == 1 or not _map.is_walkable(next):
				continue
			if CityMap.junction_at(next) == Vector2i(-1, -1):
				if Tile.is_road(_map.tile_at(next)):
					continue
				if main >= 0 and _map.street_kind_at(true, next) == GameEnums.StreetKind.MAIN:
					continue
			seen[index] = 1
			queue.append(next)
	return false
