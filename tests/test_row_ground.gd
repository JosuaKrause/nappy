extends RefCounted
## `RowGround`, which tiles a row may stand on and how many times over each is offered, on a
## hand-drawn map (`StreetMap.full()`, the whole lattice of streets round blocks that are all
## building, with one block's interior painted alley). It is handed a stand-in corridor that answers
## what the role asks of the routes (how far off them a tile is, whether a route runs along it,
## whether it is in a gap), weights of the suite's own, each a different number so an answer says
## which one made it, and a wall question of the suite's own, where the game hands the scheduler's
## (`EventScheduler.row_ground()`). The rows are plain data, built here. One interaction each:
##
## - **An answer is kept**: the same question asked again, by the row or by another row that asks
##   the same thing, is given the very answer the first was, and a row that asks for another lane
##   is given another.
## - **A row placed for no role, or on a walk with no routes, is offered every tile once.**
## - **Friction is drawn onto the routes' streets**: a tile of a street a route runs along
##   `on_the_routes` times, whichever sidewalk, and any other tile once.
## - **A wall never stands on a tile a route runs along.** A costly one is offered the rim `rim`
##   times, the far sidewalk of a route's street and a turning one street out alike, a gap `gap`
##   times that, and ground further out once; one that ends the day is offered ground two turnings
##   out `deep` times and the rim once; a wall by its fit alone is offered what friction is.
## - **A row that stands only in alleys is refused an alley the routes run down**, and offered one
##   a turning away.

const StreetMap := preload("res://tests/fixtures/street_map.gd")

const ON_THE_ROUTES := 5
const RIM := 3
const GAP := 2
const DEEP := 7
## A block well inside the map, its interior painted alley.
const ALLEY_BLOCK := Vector2i(3, 3)

## A corridor that answers for the tiles it was told about, and `Corridor.DEEP` off the routes for
## every other.
class _Routes extends Corridor:
	var _away := {}
	var _on_a_route := {}
	var _in_a_gap := {}

	## `tile` is `away` turnings off the routes; a route runs along it where `carries`; it is on a
	## street joining two strands of the routes where `in_a_gap`.
	func put(tile: Vector2i, away: int, carries := false, in_a_gap := false) -> void:
		_away[tile] = away
		if carries:
			_on_a_route[tile] = true
		if in_a_gap:
			_in_a_gap[tile] = true

	## Overrides Corridor.depth.
	func depth(tile: Vector2i) -> int:
		return int(_away.get(tile, Corridor.DEEP))

	## Overrides Corridor.carries_a_route.
	func carries_a_route(tile: Vector2i) -> bool:
		return _on_a_route.has(tile)

	## Overrides Corridor.is_in_a_gap.
	func is_in_a_gap(tile: Vector2i) -> bool:
		return _in_a_gap.has(tile)

var _map: CityMap
## Rows that are walls by their fit alone, as the suite's wall question answers.
var _by_fit: Array[EventDef] = []

func run(t: TestRunner) -> void:
	_map = StreetMap.full()
	var origin := ALLEY_BLOCK * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH
	for y in range(origin.y, origin.y + Tuning.BLOCK_SIZE):
		for x in range(origin.x, origin.x + Tuning.BLOCK_SIZE):
			_map.set_tile(Vector2i(x, y), GameEnums.TileType.ALLEY)
	_test_an_answer_is_kept(t)
	_test_no_role_and_no_routes_offer_every_tile_once(t)
	_test_friction_is_drawn_onto_the_routes_streets(t)
	_test_a_wall_never_stands_on_a_route(t)
	_test_an_alley_row_is_refused_an_alley_the_routes_run_down(t)

## A row that stands on `type`, in the lane `side` of a sidewalk.
func _row(type: GameEnums.TileType, side := EventDef.Pavement.ANY) -> EventDef:
	var def := EventDef.new()
	def.placement.append(type)
	def.pavement_side = side
	return def

## The ground of a walk on the suite's map routed by `routes`, with the suite's weights, a precinct
## weighing nothing more, and its wall question: a row is a wall by cost unless `_by_fit` holds it.
func _ground(routes: Corridor) -> RowGround:
	return RowGround.new(_map, routes, false,
			RowGround.Weights.of(1, ON_THE_ROUTES, RIM, GAP, DEEP),
			func(row: EventDef) -> bool: return not _by_fit.has(row))

## Six sidewalk tiles of the ground's own, and what the stand-in corridor says of each: `[on a
## route, across the street from it, a turning out, in a gap a turning out, two turnings out, far
## off]`.
func _six_tiles(routes: _Routes) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var sidewalks := _ground(null).tiles_for(_row(GameEnums.TileType.SIDEWALK))
	for i in 6:
		tiles.append(sidewalks[i * 40])
	routes.put(tiles[0], 0, true)
	routes.put(tiles[1], 0)
	routes.put(tiles[2], 1)
	routes.put(tiles[3], 1, false, true)
	routes.put(tiles[4], 2)
	return tiles

func _test_an_answer_is_kept(t: TestRunner) -> void:
	var ground := _ground(_Routes.new())
	var one := _row(GameEnums.TileType.SIDEWALK)
	var another := _row(GameEnums.TileType.SIDEWALK)
	var at_the_kerb := _row(GameEnums.TileType.SIDEWALK, EventDef.Pavement.AT_THE_KERB)
	var first := ground.tiles_for(one)
	t.check(not first.is_empty(), "a sidewalk row has ground on the streets (%d tiles)" % first.size())
	t.check(is_same(first, ground.tiles_for(one)), "asked again, a row is given the answer it was given")
	t.check(is_same(first, ground.tiles_for(another)),
			"and a row that asks the same thing is given that answer too")
	t.check(is_same(ground.offers_for(one), ground.offers_for(another)),
			"as it is tile by tile")
	t.check(is_same(ground.offers_for_role(one, GameEnums.BlockerRole.FRICTION),
			ground.offers_for_role(another, GameEnums.BlockerRole.FRICTION)),
			"and for a role")
	var kerb := ground.tiles_for(at_the_kerb)
	t.check(not kerb.is_empty() and kerb.size() < first.size(),
			"a row that asks for the kerb's lane is given the kerb's tiles alone (%d of %d)"
			% [kerb.size(), first.size()])
	t.check(is_same(ground.tiles_for(one, EventDef.Pavement.AT_THE_KERB), kerb),
			"which is what a row asked about that lane is given")

func _test_no_role_and_no_routes_offer_every_tile_once(t: TestRunner) -> void:
	var routes := _Routes.new()
	var tiles := _six_tiles(routes)
	var row := _row(GameEnums.TileType.SIDEWALK)
	var ground := _ground(routes)
	var open := ground.offers_for(row)
	var once := 0
	for tile: Vector2i in open:
		if int(open[tile]) == 1:
			once += 1
	t.check(once == open.size() and open.size() == ground.tiles_for(row).size(),
			"with a precinct weighing nothing more, every tile is offered once (%d)" % open.size())
	t.check(is_same(ground.offers_for_role(row, GameEnums.BlockerRole.NONE), open),
			"a row placed for no role is offered the same")
	var unrouted := _ground(null)
	t.check(is_same(unrouted.offers_for_role(row, GameEnums.BlockerRole.WALL),
			unrouted.offers_for(row)), "and so is any role on a walk with no routes")
	t.check(open.has(tiles[0]), "the tile a route runs along among them")

func _test_friction_is_drawn_onto_the_routes_streets(t: TestRunner) -> void:
	var routes := _Routes.new()
	var tiles := _six_tiles(routes)
	var offers := _ground(routes).offers_for_role(_row(GameEnums.TileType.SIDEWALK),
			GameEnums.BlockerRole.FRICTION)
	t.check(int(offers[tiles[0]]) == ON_THE_ROUTES and int(offers[tiles[1]]) == ON_THE_ROUTES,
			"friction is offered both sidewalks of a route's street as often as the routes weigh")
	t.check(int(offers[tiles[2]]) == 1 and int(offers[tiles[4]]) == 1 and int(offers[tiles[5]]) == 1,
			"and every tile off the routes once")

func _test_a_wall_never_stands_on_a_route(t: TestRunner) -> void:
	var routes := _Routes.new()
	var tiles := _six_tiles(routes)
	var ground := _ground(routes)
	var costly := _row(GameEnums.TileType.SIDEWALK)
	var lethal := _row(GameEnums.TileType.SIDEWALK)
	lethal.hard_fail = true
	var by_fit := _row(GameEnums.TileType.SIDEWALK)
	_by_fit = [by_fit]
	var wall := GameEnums.BlockerRole.WALL
	var walls: Array[EventDef] = [costly, lethal, by_fit]
	for row in walls:
		t.check(not ground.offers_for_role(row, wall).has(tiles[0]),
				"no wall is offered a tile a route runs along")
	var for_costly := ground.offers_for_role(costly, wall)
	t.check(int(for_costly[tiles[1]]) == RIM and int(for_costly[tiles[2]]) == RIM,
			"a costly wall is offered the rim, across the street from a route and a turning out alike")
	t.check(int(for_costly[tiles[3]]) == RIM * GAP, "a gap as often again as a gap weighs")
	t.check(int(for_costly[tiles[4]]) == 1 and int(for_costly[tiles[5]]) == 1,
			"and ground further out once")
	var for_lethal := ground.offers_for_role(lethal, wall)
	t.check(int(for_lethal[tiles[4]]) == DEEP and int(for_lethal[tiles[5]]) == DEEP,
			"a wall that ends the day is offered ground two turnings out and beyond")
	t.check(int(for_lethal[tiles[1]]) == 1 and int(for_lethal[tiles[2]]) == 1
			and int(for_lethal[tiles[3]]) == 1, "and the rim once, a gap included")
	var for_fit := ground.offers_for_role(by_fit, wall)
	t.check(int(for_fit[tiles[1]]) == ON_THE_ROUTES and int(for_fit[tiles[2]]) == 1
			and int(for_fit[tiles[3]]) == 1 and int(for_fit[tiles[4]]) == 1,
			"a wall by its fit alone is offered what friction is, off the route's own tiles")
	_by_fit = []

func _test_an_alley_row_is_refused_an_alley_the_routes_run_down(t: TestRunner) -> void:
	var routes := _Routes.new()
	var robber := _row(GameEnums.TileType.ALLEY)
	var alley := _ground(null).tiles_for(robber)
	t.check(alley.size() >= 2, "the painted block is alley ground (%d tiles)" % alley.size())
	if alley.size() < 2:
		return
	var required := alley[0]
	var a_turning_away := alley[alley.size() - 1]
	routes.put(required, 0)
	routes.put(a_turning_away, 1)
	var ground := _ground(routes)
	var roles: Array[GameEnums.BlockerRole] = [GameEnums.BlockerRole.FRICTION,
			GameEnums.BlockerRole.WALL, GameEnums.BlockerRole.SET_PIECE]
	for role in roles:
		var offers := ground.offers_for_role(robber, role)
		t.check(not offers.has(required) and offers.has(a_turning_away),
				"a row that stands only in alleys is refused an alley the routes run down (role %d)"
				% role)
	var anywhere := _row(GameEnums.TileType.ALLEY)
	anywhere.placement.append(GameEnums.TileType.SIDEWALK)
	t.check(ground.offers_for_role(anywhere, GameEnums.BlockerRole.FRICTION).has(required),
			"and a row that stands elsewhere too is offered it")
