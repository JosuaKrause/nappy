extends RefCounted
## `RouteJunctionsRule`, `RouteSidewalkRule`, `PacingOpeningRule` and `RouteReachRule`, the four
## rules that keep the day's routes open, each asked of candidates on a generated city's routes. **Why these build a
## city:** each rule reads the route tree's own geometry (which junction boxes the routes cross,
## which sidewalk a route is walked along, the beat a pacing man walks), and a stand-in corridor
## would be the rule's own arithmetic read back to it. The one combined suite is for that shared
## setup: seed 4242 on day 5, its route tree and corridor, built once.
##
## - **The junctions:** a burst water main, whose body reaches 96px each way, standing at the middle
##   of a junction box the routes cross closes the crossing and is refused; the same body far from
##   any route is allowed.
## - **The sidewalk:** the same body on the middle of a sidewalk a route is walked along closes the
##   route's line and is refused; on a street no route runs along it is allowed.
## - **The pacing opening:** with a man shouting pacing his beat on a route street, some tile of that
##   street holds a delivery van that would close the opening his beat leaves, and the rule refuses
##   it there; with no man there, the same van at the same tile is allowed.
## - **The reach:** barricades asked one at a time in rings round home, each kept when allowed,
##   never leave home sealed off from a route tile it reached before, and at least one is refused
##   (a ring is what seals home in).

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242
const DAY := 5
const NONE: Array[EventScheduler.Planned] = []

var _map: CityMap
var _tree: RouteTree
var _corridor: Corridor

func run(t) -> void:
	_map = MapCache.of(SEED)
	var state := CityState.new()
	state.begin_day(_map.block_plans, DAY)
	_map.repaint(state)
	_tree = RouteTree.for_day(_map, DAY)
	_corridor = Corridor.of(_tree)
	_test_a_body_closing_a_route_crossing_is_refused(t)
	_test_a_body_closing_a_route_sidewalk_is_refused(t)
	_test_a_body_closing_a_beats_opening_is_refused(t)
	_test_a_ring_of_bodies_never_seals_home_off(t)

## `def` built at `tile`, given a counted role so it is asked about.
func _at(id: String, tile: Vector2i) -> EventScheduler.Planned:
	var plan := EventScheduler._build_placement(EventCatalogue.by_id(id), _map, tile,
			RandomNumberGenerator.new())
	if plan:
		plan.role = GameEnums.BlockerRole.WALL
	return plan

## A tile on a street no route runs along and two blocks or more from every route tile.
func _far_from_the_routes() -> Vector2i:
	for segment in _map.street_segments():
		var rect := segment.tile_rect()
		var middle := rect.get_center()
		if _corridor.depth(middle) >= 3 and _map.tile_at(middle) == GameEnums.TileType.ROAD:
			return middle
	return Vector2i(-1, -1)

func _test_a_body_closing_a_route_crossing_is_refused(t) -> void:
	var rule := RouteJunctionsRule.new(_map, _corridor, {})
	var junction: Vector2i = _tree.junctions()[0]
	var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	var at_the_box := _at("burst_water_main", box.get_center())
	var far := _at("burst_water_main", _far_from_the_routes())
	t.check(at_the_box != null and far != null, "the body stands at a route junction and far off")
	if at_the_box == null or far == null:
		return
	t.check(not rule.allows(at_the_box, box.get_center(), NONE, NONE),
			"a body across a junction box the routes cross is refused")
	t.check(rule.allows(far, _far_from_the_routes(), NONE, NONE),
			"the same body far from every route is allowed")

func _test_a_body_closing_a_route_sidewalk_is_refused(t) -> void:
	var rule := RouteSidewalkRule.new(_map, _corridor)
	var walked: Array = _corridor.walked_sidewalks(_map)
	t.check(not walked.is_empty(), "the day's routes are walked along sidewalks")
	if walked.is_empty():
		return
	var band: Rect2i = walked[0][1]
	var on_it := _at("burst_water_main", band.get_center())
	var far := _at("burst_water_main", _far_from_the_routes())
	t.check(on_it != null, "the body stands on a route's sidewalk")
	if on_it == null or far == null:
		return
	t.check(not rule.allows(on_it, band.get_center(), NONE, NONE),
			"a body across the sidewalk a route is walked along is refused")
	t.check(rule.allows(far, _far_from_the_routes(), NONE, NONE),
			"the same body on a street no route runs along is allowed")

func _test_a_body_closing_a_beats_opening_is_refused(t) -> void:
	var rule := PacingOpeningRule.new(_map, _corridor)
	var refused_with := 0
	var allowed_without := 0
	for entry: Array in _corridor.walked_sidewalks(_map):
		var band: Rect2i = entry[1]
		var man := EventScheduler._build_placement(EventCatalogue.by_id("homeless_yeller"), _map,
				band.get_center(), RandomNumberGenerator.new())
		if man == null or man.path.size() < 2:
			continue
		man.role = GameEnums.BlockerRole.FRICTION
		var around: Array[EventScheduler.Planned] = [man]
		var segment: StreetNetwork.Segment = entry[0]
		var street := segment.tile_rect()
		for y in range(street.position.y, street.end.y):
			for x in range(street.position.x, street.end.x):
				var tile := Vector2i(x, y)
				var van := _at("delivery_van", tile)
				if van == null or rule.allows(van, tile, around, around):
					continue
				refused_with += 1
				if rule.allows(van, tile, NONE, NONE):
					allowed_without += 1
		if refused_with > 0:
			break
	t.check(refused_with > 0, "with a man pacing a route street, a van closing his beat's opening is refused (%d tiles)"
			% refused_with)
	t.check(allowed_without == refused_with,
			"and every one of those vans is allowed with no man there (%d of %d)"
			% [allowed_without, refused_with])

func _test_a_ring_of_bodies_never_seals_home_off(t) -> void:
	var rule := RouteReachRule.new(_map, _corridor)
	var grid := ReachabilityGrid.build(_map)
	var home := _map.home_tile()
	var routes: Array[Vector2i] = []
	for y in _map.size.y:
		for x in _map.size.x:
			if _corridor.carries_a_route(Vector2i(x, y)):
				routes.append(Vector2i(x, y))
	var reached_bare := grid.flood([home], _map.closed_tiles)
	var kept: Array[EventScheduler.Planned] = []
	var refused: Array[EventScheduler.Planned] = []
	for radius in [3, 5, 7]:
		for step in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
				Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]:
			var barricade := EventScheduler.Planned.new(EventCatalogue.by_id("barricade"),
					_map.tile_to_world(home + step * radius))
			if rule.allows(barricade, home + step * radius, NONE, kept):
				kept.append(barricade)
			else:
				refused.append(barricade)
	var blocked := EventScheduler.blocked_by(_map, kept)
	var reached := grid.flood([home], blocked)
	var lost := 0
	for tile in routes:
		if not blocked.has(tile) and grid.reaches(tile, _map.closed_tiles, reached_bare) \
				and not grid.reaches(tile, blocked, reached):
			lost += 1
	t.check(lost == 0, "the barricades kept leave every route tile home reached still reached (%d lost)"
			% lost)
	t.check(not refused.is_empty(), "a ring of barricades round home has one refused (%d of 24)"
			% refused.size())
