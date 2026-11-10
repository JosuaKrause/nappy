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
## - **The reach answers what a flood from home answers**: bodies asked along every street a route
##   runs along in turn, each kept when allowed, get the same answer from the rule as from the same
##   rule working out what a body cuts off by flooding the whole city from home again
##   (`_FloodedReach`), and both refuse some and keep many. It holds the rule's walk of the pieces
##   round a disc. It cannot see the reach kept between asks going stale: a kept body cuts off no
##   route tile, or it would have been refused, so a stale reach holds only tiles that carry no
##   route, and no later answer changes.

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242
const DAY := 5
const NONE: Array[EventScheduler.Planned] = []

## The reach rule working out what a body cuts off by flooding the city from home among the bodies
## and the disc, and taking what home reached before and does not now: what the rule's walk of the
## pieces round the disc has to answer.
class _FloodedReach extends RouteReachRule:
	## Overrides RouteReachRule._cut_off.
	func _cut_off(disc: Dictionary) -> PackedInt32Array:
		var after := _flood(disc)
		var lost := PackedInt32Array()
		for i in _reached.size():
			if _reached[i] == 1 and after[i] == 0 and not disc.has(i):
				lost.append(i)
		return lost

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
	_test_the_reach_answers_what_a_flood_answers(t)

## `def` built at `tile`, given a counted role so it is asked about.
func _at(id: String, tile: Vector2i) -> EventScheduler.Planned:
	var plan := EventScheduler.build_placement(EventCatalogue.by_id(id), _map, tile,
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
		var man := EventScheduler.build_placement(EventCatalogue.by_id("homeless_yeller"), _map,
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

func _test_the_reach_answers_what_a_flood_answers(t) -> void:
	var rule := RouteReachRule.new(_map, _corridor)
	var flooded := _FloodedReach.new(_map, _corridor)
	var kept: Array[EventScheduler.Planned] = []
	var asked := 0
	var differ := 0
	var refused := 0
	var segments := _map.street_segments()
	# Every street a route runs along, where a body is likely to be refused; the flood is the slow
	# half of each ask.
	for segment in segments:
		var tile := segment.tile_rect().get_center()
		if _corridor.depth(tile) != 0:
			continue
		for id in ["burst_water_main", "barricade"]:
			var body := _at(id, tile)
			if body == null:
				continue
			asked += 1
			var allowed := rule.allows(body, tile, NONE, kept)
			if allowed != flooded.allows(body, tile, NONE, kept):
				differ += 1
			if allowed:
				kept.append(body)
			else:
				refused += 1
	t.check(asked > 100 and refused > 0 and kept.size() > 100,
			"bodies asked along the route streets are kept and refused"
			+ " (%d asked, %d refused, %d kept)" % [asked, refused, kept.size()])
	t.check(differ == 0,
			"the rule answers each as a flood of the city from home does (%d differ)" % differ)
