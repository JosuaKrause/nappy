extends RefCounted
## `WalkSiting`, the siting that lays the rows her walk places (a *beat*): offers a beat the free
## locations on her way, nearest first, and stands it on the first location the judge answers for.
## A branch beat takes the nearest free location of the day's route tree ahead of her; a street beat
## the nearest free location ahead on her street, out of her view; a placed beat is judged without its
## own body and gives its location back only once it has another; a row refused in a look is not judged
## again in it; one ask offers at most `LOCATIONS_A_LOOK` locations; a mast near the mark takes the
## first free location of the tiles it is offered; a fire lit at dusk is laid off her path first.
##
## Run with stand-ins for everything it is handed (`FakeRouteTree` whose cells and carried tiles a
## check sets, `FakeWalkEvents`, `_Locations` whose table of locations a check sets and which
## records each take and give-back, `_Judge` which answers a plan on the first tile it is handed or
## null for a location set to refuse, `_Ground` whose tiles a check sets and which records each
## ask); `Location`, `EventPlan` and `EventDef` are real (state and data) on the bare lattice
## (`CityMap.new()`), a hand-drawn map as `tests/test_ruled_location_ground.gd` builds its own. What
## the judge says of a candidate is `tests/test_ruled_location_ground.gd`'s and `StreetInvalidation`'s,
## and which tile is a row's ground `tests/test_sited_ground.gd`'s.

func run(t: TestRunner) -> void:
	_test_a_branch_beat_takes_the_nearest_free_location_and_one_that_refuses_passes_it_on(t)
	_test_a_taken_or_unavailable_location_is_never_offered_nor_a_tile_the_tree_does_not_carry(t)
	_test_off_the_routes_it_waits_and_says_so_and_standing_still_a_street_beat_waits(t)
	_test_a_street_beat_takes_the_nearest_free_location_ahead_out_of_her_view(t)
	_test_a_placed_beat_keeps_its_location_until_another_takes_it(t)
	_test_a_row_refused_in_a_look_is_not_judged_again_in_it(t)
	_test_one_ask_offers_no_more_than_the_locations_a_look_allows(t)
	_test_among_offered_tiles_the_first_free_location_in_the_order_offered_takes_it(t)
	_test_at_dusk_off_her_path_first_then_merely_away_and_no_location_is_taken(t)
	_test_a_crew_faces_the_wall(t)
	_test_laying_a_mast_asks_the_ground_only_of_tiles_on_her_way(t)
	_test_a_pick_the_ground_round_which_draws_a_unit_is_given_up(t)

const FIRE_DAY := 3
const YELLER_DAY := 6
## Her tile, heading east.
const HER := Vector2i(10, 10)
## The first tile (heading east along a street of two tiles) of each location of the branch.
const ROW_Y := 10

## What a check builds: the stand-ins, and the siting over them.
class _Rig extends RefCounted:
	var map := CityMap.new()
	var tree: FakeRouteTree
	var walk := FakeWalkEvents.new()
	var locations := _Locations.new()
	var judge := _Judge.new()
	var ground := _Ground.new()
	var siting: WalkSiting

## What the siting is handed for the locations: a table a check sets, and a record of each take and
## give-back.
class _Locations extends DayLocations:
	var table: Array[Location] = []
	## Each location taken, with the plan that took it, in order.
	var taken: Array[Array] = []
	## Each location given back, with the plan that gave it back, in order.
	var given_back: Array[Array] = []

	## Overrides DayLocations.holding.
	func holding(tile: Vector2i, _type: int) -> Location:
		for location in table:
			if location.tiles().has_point(tile):
				return location
		return null

	## Overrides DayLocations.take_for_her_walk.
	func take_for_her_walk(location: Location, plan: EventPlan) -> void:
		taken.append([location, plan])
		location.take(plan)

	## Overrides DayLocations.give_back.
	func give_back(location: Location, plan: EventPlan) -> void:
		given_back.append([location, plan])
		location.give_back(plan)

## What judges a location: answers a plan on the first tile handed, or null for a location (or a
## row) set to refuse, and records each ask.
class _Judge extends LocationGround:
	var refuses: Array[Location] = []
	var refuses_rows: Array[String] = []
	var refuses_everything := false
	## Each ask, as `[row id, location, tiles, among]`.
	var asks: Array[Array] = []

	## Overrides LocationGround.offer_on.
	func offer_on(def: EventDef, location: Location, tiles: Array[Vector2i],
			among: Array[EventPlan]) -> EventPlan:
		asks.append([def.id, location, tiles.duplicate(), among])
		if refuses_everything or location in refuses or def.id in refuses_rows:
			return null
		return EventPlan.new(def, Vector2(tiles[0]) * float(Tuning.TILE_SIZE))

## The tiles a row stands on, as a check sets them, and every tile asked of it.
class _Ground extends SitedGround:
	var set_of_tiles := {}
	var asked: Array[Vector2i] = []

	func _init() -> void:
		super(null, null, {})

	## Overrides SitedGround.takes.
	func takes(_def: EventDef, tile: Vector2i) -> bool:
		asked.append(tile)
		return set_of_tiles.has(tile)

	## Overrides SitedGround.tiles_of.
	func tiles_of(_def: EventDef) -> Dictionary:
		return set_of_tiles

	## Overrides SitedGround.is_a_wall_by_cost.
	func is_a_wall_by_cost(_def: EventDef) -> bool:
		return false

	## Overrides SitedGround.prepare.
	func prepare(_def: EventDef) -> void:
		pass

## A plan that records the way it was turned to.
class _SpyPlan extends EventPlan:
	var faced := Vector2.ZERO

	## Overrides EventPlan.face.
	func face(direction: Vector2) -> void:
		faced = direction
		super(direction)

# ------------------------------------------------------------------- helpers ---

## A location of `width` by two tiles at (`x`, `y`).
static func _location(x: int, y: int, available := true, width := 4) -> Location:
	var tiles := Rect2i(Vector2i(x, y), Vector2i(width, 2))
	return Location.new(null, 0, tiles, Vector2(tiles.get_center()) * float(Tuning.TILE_SIZE),
			PlacementView.View.ON_THE_ROUTE, available, Location.Kind.SIDEWALK)

## The siting over stand-ins for `day`, her way ahead the cells over `first_cell` to `last_cell` along
## the row `ROW_Y` (a cell is two tiles square), every tile of them carried by the tree and the
## row's ground.
static func _rig(day: int, first_cell: int, last_cell: int) -> _Rig:
	var rig := _Rig.new()
	rig.tree = FakeRouteTree.new(rig.map)
	var cells := {}
	var carried: Array[Vector2i] = []
	for cell in range(first_cell, last_cell + 1):
		cells[Vector2i(cell, ROW_Y / 2)] = float((cell * 2 - HER.x) * Tuning.TILE_SIZE)
		for dy in 2:
			for dx in 2:
				var tile := Vector2i(cell * 2 + dx, ROW_Y + dy)
				carried.append(tile)
				rig.ground.set_of_tiles[tile] = 1
	rig.tree.set_cells_ahead(cells).set_carried_tiles(carried)
	rig.siting = WalkSiting.new(day, rig.map, rig.tree, rig.walk, rig.locations, rig.judge,
			rig.ground)
	return rig

static func _her() -> Vector2:
	return Vector2(HER) * float(Tuning.TILE_SIZE) + Vector2.ONE * (Tuning.TILE_SIZE * 0.5)

static func _unplaced(id: String) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id), Vector2.INF)

## The locations a judge was asked about, in order.
static func _asked(judge: _Judge) -> Array[Location]:
	var found: Array[Location] = []
	for ask in judge.asks:
		found.append(ask[1])
	return found

# --------------------------------------------------------------------- tests ---

## The nearest free location with ground on her branch takes a branch beat, and a location the judge
## refuses passes it to the next.
func _test_a_branch_beat_takes_the_nearest_free_location_and_one_that_refuses_passes_it_on(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	var l50 := _location(50, ROW_Y)
	var l60 := _location(60, ROW_Y)
	var l70 := _location(70, ROW_Y)
	rig.locations.table = [l70, l50, l60] as Array[Location]
	rig.judge.refuses = [l50] as Array[Location]
	var fire := _unplaced("burning_building")
	rig.walk.set_plans([fire] as Array[EventPlan])
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var laid := rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(laid and fire.is_placed(), "a beat that finds a location is laid")
	t.check(_asked(rig.judge) == ([l50, l60] as Array[Location]),
			"the locations are asked nearest to walk to first, a table's order never read (%d asks)"
			% rig.judge.asks.size())
	t.check(not rig.locations.taken.is_empty() and rig.locations.taken[0][0] == l60 and l60.is_taken()
			and not l50.is_taken() and not l70.is_taken(),
			"the first the judge answers for is taken for the day, the others not")
	t.check(fire.placed_at().is_equal_approx(Vector2(60, ROW_Y) * float(Tuning.TILE_SIZE)),
			"on the first tile of it the walk offered")

## What is never offered: a location taken, one unavailable, a tile the tree does not carry, a tile
## nearer than the stream radius and its hysteresis.
func _test_a_taken_or_unavailable_location_is_never_offered_nor_a_tile_the_tree_does_not_carry(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 16, 50)
	var near := _location(30, ROW_Y)
	var taken := _location(50, ROW_Y)
	var unavailable := _location(60, ROW_Y, false)
	var uncarried := _location(70, ROW_Y)
	var free := _location(80, ROW_Y)
	taken.take(EventPlan.new(EventCatalogue.by_id("cafe_tables"), taken.centre()))
	rig.tree = _tree_without(rig, uncarried.tiles())
	rig.siting = WalkSiting.new(FIRE_DAY, rig.map, rig.tree, rig.walk, rig.locations, rig.judge,
			rig.ground)
	rig.locations.table = [near, taken, unavailable, uncarried, free] as Array[Location]
	var fire := _unplaced("burning_building")
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(_asked(rig.judge) == ([free] as Array[Location]),
			"a taken location, an unavailable one, one with no tile the tree carries and one nearer than "
			+ "the streaming band are never asked about (%d asks)" % rig.judge.asks.size())
	var nearest_offered := INF
	for ask in rig.judge.asks:
		for tile: Vector2i in ask[2]:
			nearest_offered = minf(nearest_offered,
					(Vector2(tile) * float(Tuning.TILE_SIZE)).distance_to(_her()))
	t.check(nearest_offered >= WalkSiting.NOT_YET_REAL - float(Tuning.TILE_SIZE),
			"and no tile is offered nearer than the streaming band (%.0fpx)" % nearest_offered)

## The tree of `rig` carrying every tile its cells hold but those of `rect`.
static func _tree_without(rig: _Rig, rect: Rect2i) -> FakeRouteTree:
	var tree := FakeRouteTree.new(rig.map)
	var carried: Array[Vector2i] = []
	for tile: Vector2i in rig.ground.set_of_tiles:
		if not rect.has_point(tile):
			carried.append(tile)
	var cells := {}
	for cell in range(16, 51):
		cells[Vector2i(cell, ROW_Y / 2)] = float((cell * 2 - HER.x) * Tuning.TILE_SIZE)
	return tree.set_cells_ahead(cells).set_carried_tiles(carried)

## Off the day's routes a branch beat waits and says why; standing still a street beat waits.
func _test_off_the_routes_it_waits_and_says_so_and_standing_still_a_street_beat_waits(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	rig.locations.table = [_location(50, ROW_Y)] as Array[Location]
	rig.tree.set_cells_ahead({})
	var fire := _unplaced("burning_building")
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	t.check(not rig.siting.lay_ahead(fire) and not fire.is_placed(), "off the routes the fire is not laid")
	rig.siting.end_look()
	t.check(rig.siting.waits().has("she is off the day's routes") and rig.judge.asks.is_empty(),
			"and says she is off the routes, asking the judge nothing")
	var yeller := _unplaced("homeless_yeller")
	var street := _rig(YELLER_DAY, 24, 50)
	street.locations.table = [_location(80, ROW_Y)] as Array[Location]
	street.siting.begin_look(_her(), Vector2.ZERO)
	t.check(not street.siting.lay_ahead(yeller), "standing still a street beat is not laid")
	street.siting.end_look()
	t.check(street.siting.waits().has("she is not walking anywhere"), "and says she is not walking")

## A street beat (a row met on her street) takes the nearest free location ahead of her on her
## street whose offered tiles are out of her view and inside the stream radius, and never a tile
## behind her, beyond five tiles of her line of travel or past the stream radius.
func _test_a_street_beat_takes_the_nearest_free_location_ahead_out_of_her_view(t: TestRunner) -> void:
	var rig := _rig(YELLER_DAY, 24, 50)
	var here := Vector2i(60, 40)
	var in_view := _location(62, 40)
	var near := _location(80, 40)
	var further := _location(84, 40)
	var beside := _location(80, 50)
	var behind := _location(40, 40)
	var beyond := _location(92, 40)
	var all := [in_view, near, further, beside, behind, beyond] as Array[Location]
	rig.locations.table = all
	for location in all:
		var rect := location.tiles()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				rig.ground.set_of_tiles[Vector2i(x, y)] = 1
	var her := Vector2(here) * float(Tuning.TILE_SIZE)
	var yeller := _unplaced("homeless_yeller")
	rig.judge.refuses = [near] as Array[Location]
	rig.siting.begin_look(her, Vector2.RIGHT)
	var laid := rig.siting.lay_ahead(yeller)
	rig.siting.end_look()
	t.check(laid and _asked(rig.judge) == ([near, further] as Array[Location]),
			"he is offered the free locations ahead of her on her street, nearest along her heading first, "
			+ "and never one in her view, behind her, off her street or past the stream radius (%d asks)"
			% rig.judge.asks.size())
	t.check(rig.locations.taken.size() == 1 and rig.locations.taken[0][0] == further,
			"and the one the judge answers for is taken")
	var van := _unplaced("delivery_van")
	var van_rig := _rig(7, 24, 50)
	t.check(EventScheduler.role_for(van.row(), 7) == GameEnums.BlockerRole.WALL,
			"the van is a wall on the day it is laid (the guard that the row is one by its fit)")
	van_rig.locations.table = [_location(80, 40)] as Array[Location]
	van_rig.ground.set_of_tiles[Vector2i(80, 40)] = 1
	van_rig.siting.begin_look(her, Vector2.RIGHT)
	var van_laid := van_rig.siting.lay_ahead(van)
	van_rig.siting.end_look()
	t.check(van_laid, "and a wall by its fit alone is laid on her street as well")

## A placed beat is judged among the walk's plans but itself, keeps its location where nothing
## else takes it, and gives it back the moment another does.
func _test_a_placed_beat_keeps_its_location_until_another_takes_it(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	var l50 := _location(50, ROW_Y)
	var l60 := _location(60, ROW_Y)
	rig.locations.table = [l50, l60] as Array[Location]
	var fire := _unplaced("burning_building")
	var other := EventPlan.new(EventCatalogue.by_id("cafe_tables"), Vector2(500, 500))
	rig.walk.set_plans([fire, other] as Array[EventPlan])
	rig.judge.refuses = [l50] as Array[Location]
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(l60.is_taken() and rig.locations.given_back.is_empty(), "the fire stands on the second location")
	rig.judge.asks.clear()
	rig.judge.refuses = [l50, l60] as Array[Location]
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var moved := rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(not moved and l60.is_taken() and rig.locations.given_back.is_empty(),
			"asked again and refused everywhere, it keeps the location it stands on")
	t.check(not rig.judge.asks.is_empty() and not (fire in (rig.judge.asks[0][3] as Array[EventPlan]))
			and other in (rig.judge.asks[0][3] as Array[EventPlan]),
			"and is judged among the walk's plans but itself")
	rig.judge.refuses = [] as Array[Location]
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var again := rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(again and l50.is_taken() and not l60.is_taken()
			and rig.locations.given_back.size() == 1 and rig.locations.given_back[0][0] == l60,
			"given another location it gives the old one back, and no sooner")

## A row refused in a look is not judged again in it; laying a plan, or a new look, asks again.
func _test_a_row_refused_in_a_look_is_not_judged_again_in_it(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	rig.locations.table = [_location(50, ROW_Y), _location(60, ROW_Y)] as Array[Location]
	rig.judge.refuses_rows = ["burning_building"] as Array[String]
	var fire := _unplaced("burning_building")
	var crew := _unplaced("poster_crew")
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	rig.siting.lay_ahead(fire)
	var after_one := rig.judge.asks.size()
	rig.siting.lay_ahead(_unplaced("burning_building"))
	t.check(after_one > 0 and rig.judge.asks.size() == after_one,
			"a row refused is not judged again for the next copy of it in the same look (%d asks)"
			% rig.judge.asks.size())
	var laid_crew := rig.siting.lay_ahead(crew)
	rig.siting.lay_ahead(_unplaced("burning_building"))
	t.check(laid_crew and rig.judge.asks.size() > after_one + 1,
			"and once a plan is laid it is judged again")
	rig.siting.end_look()
	var before := rig.judge.asks.size()
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	rig.siting.lay_ahead(_unplaced("burning_building"))
	rig.siting.end_look()
	t.check(rig.judge.asks.size() > before, "and in the next look")

## One ask offers no more locations than a look allows.
func _test_one_ask_offers_no_more_than_the_locations_a_look_allows(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 100)
	var table: Array[Location] = []
	for i in 14:
		table.append(_location(50 + i * 6, ROW_Y))
	rig.locations.table = table
	rig.judge.refuses_everything = true
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var laid := rig.siting.lay_ahead(_unplaced("burning_building"))
	rig.siting.end_look()
	t.check(not laid and rig.judge.asks.size() > 0 and rig.judge.asks.size() <= WalkSiting.LOCATIONS_A_LOOK,
			"with every location refusing, at most %d are asked about (%d)"
			% [WalkSiting.LOCATIONS_A_LOOK, rig.judge.asks.size()])
	t.check(rig.siting.waits().has("every location offered broke a placement rule"),
			"and it says every location offered broke a placement rule")

## A caller that brings the tiles (the mast near the mark) has them taken by the first free location
## that takes one, in the order offered, a taken one passed over.
func _test_among_offered_tiles_the_first_free_location_in_the_order_offered_takes_it(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	var l50 := _location(50, ROW_Y)
	var l60 := _location(60, ROW_Y)
	var l70 := _location(70, ROW_Y)
	var l80 := _location(80, ROW_Y)
	rig.locations.table = [l50, l60, l70, l80] as Array[Location]
	l70.take(EventPlan.new(EventCatalogue.by_id("cafe_tables"), l70.centre()))
	var offered: Array[Vector2i] = [Vector2i(70, 10), Vector2i(81, 10), Vector2i(61, 10), Vector2i(82, 10)]
	rig.judge.refuses = [l80] as Array[Location]
	var mast := EventPlan.new(EventCatalogue.mast(), Vector2.INF)
	var laid := rig.siting.lay_among(mast, offered)
	t.check(laid and _asked(rig.judge) == ([l80, l60] as Array[Location]) and l60.is_taken(),
			"the first free location in the order offered that the judge answers for takes it, a taken one "
			+ "passed over (%d asks)" % rig.judge.asks.size())
	t.check(rig.judge.asks[0][2] == ([Vector2i(81, 10), Vector2i(82, 10)] as Array[Vector2i]),
			"with the tiles offered of it in the order offered")

## At dusk the fire is laid at least `DUSK_CLEAR_OF_HER` from where she finished, off the routes first,
## else merely away, and no location is taken.
func _test_at_dusk_off_her_path_first_then_merely_away_and_no_location_is_taken(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	var finished := Vector2(20, 10) * float(Tuning.TILE_SIZE)
	var close := _location(24, ROW_Y)
	var on_the_routes := _location(60, ROW_Y)
	var off_the_routes := _location(90, ROW_Y)
	rig.locations.table = [close, on_the_routes, off_the_routes] as Array[Location]
	for location in rig.locations.table:
		var rect := location.tiles()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				rig.ground.set_of_tiles[Vector2i(x, y)] = 1
	rig.tree = _tree_without(rig, off_the_routes.tiles())
	rig.siting = WalkSiting.new(FIRE_DAY, rig.map, rig.tree, rig.walk, rig.locations, rig.judge,
			rig.ground)
	var fire := _unplaced("burning_building")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	t.check(rig.siting.lay_off_her_path(fire, finished, rng) and fire.is_placed(),
			"a fire is laid at dusk")
	t.check(_asked(rig.judge) == ([off_the_routes] as Array[Location]),
			"off the routes first, and never within the distance clear of her (%d asks)" % rig.judge.asks.size())
	rig.judge.asks.clear()
	rig.judge.refuses = [off_the_routes] as Array[Location]
	var second := _unplaced("burning_building")
	rng.seed = 7
	t.check(rig.siting.lay_off_her_path(second, finished, rng),
			"where none off the routes takes it, merely away does")
	t.check(close not in _asked(rig.judge) and on_the_routes in _asked(rig.judge),
			"on a location the routes run along, still never one within the distance clear of her")
	t.check(rig.locations.taken.is_empty(), "and the day being over, no location is taken")

## A crew is turned to face the wall it pastes; the fire is not turned.
func _test_a_crew_faces_the_wall(t: TestRunner) -> void:
	var rig := _rig(4, 24, 50)
	rig.locations.table = [_location(50, ROW_Y)] as Array[Location]
	var crew := _SpyPlan.new(EventCatalogue.by_id("poster_crew"), Vector2.INF)
	var fire := _SpyPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	rig.siting.lay_ahead(crew)
	rig.locations.table = [_location(60, ROW_Y)] as Array[Location]
	rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(crew.is_placed() and crew.faced == Vector2.UP, "a crew faces the wall, its back to the street")
	t.check(fire.is_placed() and fire.faced == Vector2.ZERO, "and the fire is turned nowhere")

## Laying a mast asks the ground only of tiles on the cells of her way: never of the rest of the
## ground the row has.
func _test_laying_a_mast_asks_the_ground_only_of_tiles_on_her_way(t: TestRunner) -> void:
	var rig := _rig(11, 24, 30)
	rig.locations.table = [_location(50, ROW_Y), _location(56, ROW_Y)] as Array[Location]
	for x in range(100, 400):
		rig.ground.set_of_tiles[Vector2i(x, 20)] = 1
	var mast := EventPlan.new(EventCatalogue.mast(), Vector2.INF)
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var laid := rig.siting.lay_ahead(mast)
	rig.siting.end_look()
	var off_her_way := 0
	for tile in rig.ground.asked:
		if tile.y != ROW_Y and tile.y != ROW_Y + 1:
			off_her_way += 1
	t.check(laid and not rig.ground.asked.is_empty() and rig.ground.set_of_tiles.size() > 300
			and off_her_way == 0,
			"the ground is asked of tiles on the cells of her way alone, not of the ground's %d tiles (%d asks, %d off her way)"
			% [rig.ground.set_of_tiles.size(), rig.ground.asked.size(), off_her_way])

## A pick the ground round which draws a unit is given up for this look, with the reason, and stands
## when asked again with nothing left to draw.
func _test_a_pick_the_ground_round_which_draws_a_unit_is_given_up(t: TestRunner) -> void:
	var rig := _rig(FIRE_DAY, 24, 50)
	var l50 := _location(50, ROW_Y)
	rig.locations.table = [l50] as Array[Location]
	var draws: Array[bool] = [true, false]
	var asked_round: Array[Vector2] = []
	rig.siting.use_the_ground_drawer(func(at: Vector2, _reach: float) -> bool:
		asked_round.append(at)
		return draws.pop_front())
	var fire := _unplaced("burning_building")
	rig.siting.begin_look(_her(), Vector2.RIGHT)
	var first := rig.siting.lay_ahead(fire)
	t.check(not first and not fire.is_placed() and not l50.is_taken()
			and rig.siting.waits().has("the ground round its site had not drawn"),
			"a pick that drew a unit is given up, takes no location and says why")
	var second := rig.siting.lay_ahead(fire)
	rig.siting.end_look()
	t.check(second and fire.is_placed() and l50.is_taken() and asked_round.size() == 2,
			"and stands when asked again with nothing left to draw (%d asks of the drawer)" % asked_round.size())
