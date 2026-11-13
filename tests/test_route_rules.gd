extends RefCounted
## `RouteJunctionsRule`, `RouteSidewalkRule`, `PacingOpeningRule` and `RouteGroundRule`, the four
## rules that keep the day's routes open. **Why the first three build a city:** each reads the route
## tree's own geometry (which junction boxes the routes cross, which sidewalk a route is walked
## along, the beat a pacing man walks), and a stand-in corridor would be the rule's own arithmetic
## read back to it. The one combined suite is for that shared setup: seed 4242 on day 5, its route
## tree and corridor, built once. **The ground rule reads only which tiles a route runs along and
## what kind of ground each is**, so its cases are one interaction each on a hand-drawn map
## (`StreetMap.full()` with one block painted alley) under a fake corridor that names the route's
## tiles.
##
## - **The junctions:** a burst water main, whose body reaches 96px each way, standing at the middle
##   of a junction box the routes cross closes the crossing and is refused; the same body far from
##   any route is allowed.
## - **The sidewalk:** the same body on the middle of a sidewalk a route is walked along closes the
##   route's line and is refused; on a street no route runs along it is allowed.
## - **The pacing opening:** with a man shouting pacing his beat on a route street, some tile of that
##   street holds a delivery van that would close the opening his beat leaves, and the rule refuses
##   it there; with no man there, the same van at the same tile is allowed.
## - **The route's ground:** a barricade (a body 62px each way) on the alley a route runs down is
##   refused, and the same barricade on the same alley four tiles beside the route stands; an
##   abduction, whose 22px body stops short of the route a tile away and whose 54px lethal inner
##   disc reaches it, standing there is refused; a man shouting, who has no body, stands on the
##   route itself, and so does a region door's post, whose body does not block the way. With the
##   streets counted, the barricade across the sidewalk a route walks is refused and on the far
##   sidewalk stands, and on the street she starts on, which the tree does not carry, it is refused
##   too; with them not counted, the line rules' ground and the home street's hold, it stands on
##   both.

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242
const DAY := 5
const NONE: Array[EventPlan] = []

var _map: CityMap
var _tree: RouteTree
var _corridor: Corridor

func run(t: TestRunner) -> void:
	_map = MapCache.of(SEED)
	var state := CityState.new()
	state.begin_day(_map.block_plans, DAY)
	_map.repaint(state)
	_tree = RouteTree.for_day(_map, DAY)
	_corridor = Corridor.of(_tree)
	_test_a_body_closing_a_route_crossing_is_refused(t)
	_test_a_body_closing_a_route_sidewalk_is_refused(t)
	_test_a_body_closing_a_beats_opening_is_refused(t)
	_test_a_body_on_a_routes_ground_off_the_streets_is_refused(t)
	_test_a_body_on_a_routes_street_is_refused_where_the_streets_count(t)

## `def` built at `tile`, given a counted role so it is asked about.
func _at(id: String, tile: Vector2i) -> EventPlan:
	var plan := GamePlanBuilder.over(_map).build(EventCatalogue.by_id(id), tile,
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

func _test_a_body_closing_a_route_crossing_is_refused(t: TestRunner) -> void:
	var rule := RouteJunctionsRule.new(_map, _corridor)
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

func _test_a_body_closing_a_route_sidewalk_is_refused(t: TestRunner) -> void:
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

func _test_a_body_closing_a_beats_opening_is_refused(t: TestRunner) -> void:
	var rule := PacingOpeningRule.new(_map, _corridor)
	var refused_with := 0
	var allowed_without := 0
	for entry: Array in _corridor.walked_sidewalks(_map):
		var band: Rect2i = entry[1]
		var man := GamePlanBuilder.over(_map).build(EventCatalogue.by_id("homeless_yeller"),
				band.get_center(), RandomNumberGenerator.new())
		if man == null or man.path.size() < 2:
			continue
		man.role = GameEnums.BlockerRole.FRICTION
		var around: Array[EventPlan] = [man]
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

# ------------------------------------------------------------- the route's ground ---

## The block the alley is painted over, and the alley a route runs down it: the block's whole
## interior is alley ground, and the route runs down two of its columns near its west side, from
## the street north of the block to the street south of it.
const ALLEY_BLOCK := Vector2i(2, 2)
const ROUTE_COLUMNS: Array[int] = [35, 36]
## The row of the alley the bodies are stood on, in the block's middle.
const ALLEY_ROW := 38
## The street north of the block: its far (north) sidewalk's outer row, and the south sidewalk band
## the route walks, whose frontage row (against the alley block) the body is stood on.
const FAR_SIDEWALK_ROW := 28
const ROUTE_SIDEWALK_ROWS: Array[int] = [32, 33]
## The home, against the south edge of a block well east of the alley, so its door opens onto the
## street south of that block, a street no route of the cases runs along; and the tile of that
## street's near sidewalk the body is stood on.
const HOME := Rect2i(65, 40, 2, 2)
const ON_THE_HOME_STREET := Vector2i(66, 43)

## A corridor whose routes run along exactly `tiles`, the one question the ground rule asks of it.
class _Route extends Corridor:
	var _tiles := {}

	func _init(tiles: Array[Vector2i]) -> void:
		for tile in tiles:
			_tiles[tile] = true

	## Overrides Corridor.carries_a_route.
	func carries_a_route(tile: Vector2i) -> bool:
		return _tiles.has(tile)

## The streets, with `ALLEY_BLOCK`'s interior painted alley and the home at `HOME`; the route of the
## cases below runs down `ROUTE_COLUMNS` of the alley and along the street north of it on
## `ROUTE_SIDEWALK_ROWS`.
static func _alley_map() -> CityMap:
	var map := StreetMap.full()
	map.home_rect = HOME
	var origin := ALLEY_BLOCK * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH
	for y in range(origin.y, origin.y + Tuning.BLOCK_SIZE):
		for x in range(origin.x, origin.x + Tuning.BLOCK_SIZE):
			map.set_tile(Vector2i(x, y), GameEnums.TileType.ALLEY)
	return map

static func _alley_route() -> _Route:
	var origin := ALLEY_BLOCK * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH
	var tiles: Array[Vector2i] = []
	for y in range(origin.y, origin.y + Tuning.BLOCK_SIZE):
		for x: int in ROUTE_COLUMNS:
			tiles.append(Vector2i(x, y))
	for x in range(origin.x, origin.x + Tuning.BLOCK_SIZE):
		for y: int in ROUTE_SIDEWALK_ROWS:
			tiles.append(Vector2i(x, y))
	return _Route.new(tiles)

## The tiles of the street she starts on, as the day hands them to the rule.
static func _home_street(map: CityMap) -> Rect2i:
	return ClosurePlanner.home_street(map).tile_rect()

## `id`, standing at the middle of `tile`.
static func _standing(map: CityMap, id: String, tile: Vector2i) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id), map.tile_to_world(tile))

func _test_a_body_on_a_routes_ground_off_the_streets_is_refused(t: TestRunner) -> void:
	var map := _alley_map()
	var rule := RouteGroundRule.new(map, _alley_route())
	var on_it := Vector2i(ROUTE_COLUMNS[1], ALLEY_ROW)
	var beside := Vector2i(ROUTE_COLUMNS[1] + 4, ALLEY_ROW)
	var lethal_at := Vector2i(ROUTE_COLUMNS[1] + 1, ALLEY_ROW)
	t.check(map.tile_at(beside) == GameEnums.TileType.ALLEY
			and map.tile_at(lethal_at) == GameEnums.TileType.ALLEY,
			"the tiles beside the route are the same alley")
	t.check(not rule.allows(_standing(map, "barricade", on_it), on_it, NONE, NONE),
			"a body on the alley a route runs down is refused")
	t.check(rule.allows(_standing(map, "barricade", beside), beside, NONE, NONE),
			"the same body on the alley four tiles beside the route stands")
	var abduction := _standing(map, "abduction", lethal_at)
	t.check(abduction.row().obstructs_within() < Tuning.TILE_SIZE
			and abduction.blocking_radius() >= Tuning.TILE_SIZE,
			"the abduction's body stops short of the route a tile away, and its inner disc reaches it")
	t.check(not rule.allows(abduction, lethal_at, NONE, NONE),
			"a lethal row whose inner disc reaches the route's alley is refused")
	var man := _standing(map, "homeless_yeller", on_it)
	t.check(not man.obstructs(), "the man shouting has no body")
	t.check(rule.allows(man, on_it, NONE, NONE), "a row with no body stands on the route itself")
	var door := _standing(map, "checkpoint_post", on_it)
	door.stand_as_a_door()
	t.check(door.blocking_radius() >= Tuning.TILE_SIZE * 0.5 and not door.obstructs(),
			"a region door's post has a body that covers its own tile and does not block the way")
	t.check(rule.allows(door, on_it, NONE, NONE),
			"a region door's body on the route's alley stands: she walks through a door")

func _test_a_body_on_a_routes_street_is_refused_where_the_streets_count(t: TestRunner) -> void:
	var map := _alley_map()
	var route := _alley_route()
	var counting := RouteGroundRule.new(map, route, true, _home_street(map))
	var origin := ALLEY_BLOCK * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH
	var middle := origin.x + Tuning.BLOCK_SIZE / 2
	var across := Vector2i(middle, ROUTE_SIDEWALK_ROWS[1])
	var far := Vector2i(middle, FAR_SIDEWALK_ROW)
	t.check(map.tile_at(across) == GameEnums.TileType.SIDEWALK
			and map.tile_at(far) == GameEnums.TileType.SIDEWALK,
			"both bodies stand on the street's sidewalks")
	t.check(not counting.allows(_standing(map, "barricade", across), across, NONE, NONE),
			"with the streets counted, a body across the sidewalk a route walks is refused")
	t.check(counting.allows(_standing(map, "barricade", far), far, NONE, NONE),
			"and the same body on the far sidewalk stands")
	var line_ground := RouteGroundRule.new(map, route)
	t.check(line_ground.allows(_standing(map, "barricade", across), across, NONE, NONE),
			"with them not counted, the body on the route's sidewalk is left to the line rules")
	var home := ON_THE_HOME_STREET
	t.check(not route.carries_a_route(home)
			and ClosurePlanner.home_street(map).tile_rect().has_point(home),
			"the tile is on the street she starts on, which no route runs along")
	t.check(not counting.allows(_standing(map, "barricade", home), home, NONE, NONE),
			"with the streets counted, a body on the street she starts on is refused")
	t.check(line_ground.allows(_standing(map, "barricade", home), home, NONE, NONE),
			"with them not counted, it is left to the home street's own hold")
