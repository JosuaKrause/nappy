extends RefCounted
## `RuledLocationGround`'s two settings, the judge as the unit draw and the scripted rows each
## make it: with `roomiest` false it takes the first tile no rule refuses, cramped or not, and with
## it true the first with room all round, else the roomiest; and with `keeps_routes_on_the_run` a
## route is built inside its location's run (`Location.run()`), with it false on no bound. And a
## location's weight is its own ground's alone, a row's weight on a kind of ground left to the bag.
## And a costly wall is weighed where the judge has no corridor (the escape's walk has none, so no
## gap between its strands to weigh). And tiles a caller brings (`offer_on()`, a beat her walk
## lays) are asked in the order handed.
##
## Run with stand-ins for what it is handed: the fit (`_Fit`, whose tiles a check sets and which
## records each build and its bound), the day's rules (`_Rules`, the room of each tile set by
## hand) and, for a location's weight, the map (`_Map`, every street an ordinary one); the
## location is real (`Location`, state), on a street made by hand on the lattice's numbers, and so
## is the walk's ground the weight asks (`RowGround`, its weights and its reading of a wall handed
## to it, plain data).

func run(t: TestRunner) -> void:
	_test_the_first_allowed_tile_or_the_roomiest(t)
	_test_a_route_is_built_inside_its_run(t)
	_test_a_locations_weight_is_its_grounds_alone(t)
	_test_a_costly_wall_is_weighed_with_no_corridor(t)
	_test_tiles_brought_are_asked_in_the_order_handed(t)

const ROOMY := INF
const CRAMPED := 100.0
const CRAMPEDER := 50.0
const NONE: Array[EventPlan] = []

class _Fit extends LocationFit:
	var offered: Array[Vector2i] = []
	## The tiles built on, in the order built, and the bound each was handed.
	var built: Array[Vector2i] = []
	var bounds: Array[Rect2i] = []

	func _init() -> void:
		super(1, null, null, null)

	## Overrides LocationFit.tiles.
	func tiles(_def: EventDef, _location: Location) -> Array[Vector2i]:
		return offered.duplicate()

	## Overrides LocationFit.build.
	func build(def: EventDef, tile: Vector2i, _rng: RandomNumberGenerator,
			within := Rect2i()) -> EventPlan:
		built.append(tile)
		bounds.append(within)
		return EventPlan.new(def, Vector2(tile) * Tuning.TILE_SIZE)

class _Rules extends StreetInvalidation:
	## Tile -> its room, `-INF` for one a rule refuses.
	var rooms := {}

	func _init() -> void:
		super(null, null, [] as Array[Rect2], PackedVector2Array(), null)

	## Overrides StreetInvalidation.room.
	func room(_candidate: EventPlan, _role: GameEnums.BlockerRole, tile: Vector2i,
			_placed: Array[EventPlan], _around: Array[EventPlan]) -> float:
		return float(rooms[tile])

class _Map extends CityMap:
	## Overrides CityMap.street_kind_at.
	func street_kind_at(_vertical: bool, _tile: Vector2i) -> GameEnums.StreetKind:
		return GameEnums.StreetKind.ORDINARY

static func _location() -> Location:
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var tiles := Rect2i(segment.tile_rect().position, Vector2i(3, 2))
	return Location.new(segment, 0, tiles, Vector2(tiles.position) * Tuning.TILE_SIZE,
			PlacementView.View.ON_THE_ROUTE, true, Location.Kind.SIDEWALK)

## A section of the carriageway, the street's whole width, as `StreetLocations` lays one: where a
## row that takes a section stands.
static func _section() -> Location:
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var rect := segment.tile_rect()
	var tiles := Rect2i(rect.position, Vector2i(3, rect.size.y))
	return Location.new(segment, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
			PlacementView.View.ON_THE_ROUTE, true, Location.Kind.SECTION)

static func _judge(fit: _Fit, rules: _Rules, roomiest: bool,
		on_the_run := false) -> RuledLocationGround:
	var standing: Array[EventPlan] = []
	return RuledLocationGround.new(1, 7, null, standing, null, fit, rules, null, roomiest,
			on_the_run)

## The tile `plan` stands on.
static func _tile_of(plan: EventPlan) -> Vector2i:
	return Vector2i(plan.placed_at() / Tuning.TILE_SIZE)

func _test_the_first_allowed_tile_or_the_roomiest(t: TestRunner) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var refused := Vector2i(20, 14)
	var cramped := Vector2i(21, 14)
	var crampeder := Vector2i(22, 14)
	var rules := _Rules.new()
	rules.rooms = {refused: -INF, cramped: CRAMPED, crampeder: CRAMPEDER}
	var fit := _Fit.new()
	fit.offered = [refused, cramped, crampeder] as Array[Vector2i]
	var first := _judge(fit, rules, false).offer(cafe, _location(), NONE)
	var first_allowed := Vector2i(-1, -1)
	for tile in fit.built:
		if tile != refused:
			first_allowed = tile
			break
	t.check(first != null and _tile_of(first) == first_allowed and fit.built.back() == first_allowed,
			"with roomiest off, the first tile tried that no rule refuses is taken, cramped or not, "
			+ "and no tile after it is tried (%s of %s)" % [first_allowed, fit.built])
	fit.built.clear()
	var roomiest := _judge(fit, rules, true).offer(cafe, _location(), NONE)
	t.check(roomiest != null and _tile_of(roomiest) == cramped and fit.built.size() == 3,
			"with it on, every tile is tried and the roomiest a rule leaves valid is taken")
	rules.rooms[crampeder] = ROOMY
	fit.built.clear()
	roomiest = _judge(fit, rules, true).offer(cafe, _location(), NONE)
	t.check(roomiest != null and _tile_of(roomiest) == crampeder,
			"and a tile with room all round is taken over any cramped one")
	rules.rooms = {refused: -INF, cramped: -INF, crampeder: -INF}
	t.check(_judge(fit, rules, false).offer(cafe, _location(), NONE) == null
			and _judge(fit, rules, true).offer(cafe, _location(), NONE) == null,
			"either way, a location every tile of which a rule refuses takes nothing")

func _test_a_route_is_built_inside_its_run(t: TestRunner) -> void:
	var walker := EventCatalogue.by_id("dog_walker")
	var only := Vector2i(21, 14)
	var rules := _Rules.new()
	rules.rooms = {only: ROOMY}
	var fit := _Fit.new()
	fit.offered = [only] as Array[Vector2i]
	var location := _location()
	_judge(fit, rules, false, true).offer(walker, location, NONE)
	t.check(fit.bounds == ([location.run()] as Array[Rect2i]) and location.run().has_area(),
			"on the run, a route is built inside its location's run (%s)" % location.run())
	fit.bounds.clear()
	_judge(fit, rules, true, false).offer(walker, location, NONE)
	t.check(fit.bounds == ([Rect2i()] as Array[Rect2i]), "and off it, on no bound")

## **A location's weight is its own ground's alone** (`scale()`): a row weighed at a half on a
## street (`EventDraft.weighed_on()`) scales at one on an ordinary sidewalk location, since its weight
## on a kind of ground is in the bag's fill already (`UnitFills`) and is not counted again here.
func _test_a_locations_weight_is_its_grounds_alone(t: TestRunner) -> void:
	var draft := EventDraft.new("light")
	draft.recurring()
	draft.plays(EventDef.Role.SCENERY)
	draft.ground([GameEnums.TileType.SIDEWALK] as Array[int])
	draft.weighed_on(PlacementGround.Kind.STREET, 0.5)
	var row := draft.build()
	var ground := RowGround.new(null, null, true, RowGround.Weights.new(),
			func(_def: EventDef) -> bool: return false)
	var standing: Array[EventPlan] = []
	var judge := RuledLocationGround.new(1, 7, _Map.new(), standing, null, _Fit.new(), _Rules.new(),
			ground, false, true)
	t.check(judge.scale(row, _location()) == 1.0,
			"a row weighed at a half on a street scales at one on an ordinary sidewalk (%.2f)"
			% judge.scale(row, _location()))

## **A costly wall is weighed with no corridor**: a walk with no corridor has no gap between strands,
## so a wall by cost that does not end the day (the army truck, on the escape's day) weighs its
## location's own ground alone and the gap's weight is skipped; asked of a null corridor it was a
## call on nothing.
func _test_a_costly_wall_is_weighed_with_no_corridor(t: TestRunner) -> void:
	var truck := EventCatalogue.by_id("military_convoy")
	var day := DaySpec.CITY_DAY
	t.check(EventScheduler.role_for(truck, day) == GameEnums.BlockerRole.WALL and not truck.ends_the_day(),
			"the army truck is a wall that does not end the day on the escape's day")
	var ground := RowGround.new(null, null, true, RowGround.Weights.new(),
			func(_def: EventDef) -> bool: return true)
	var standing: Array[EventPlan] = []
	var judge := RuledLocationGround.new(day, 7, _Map.new(), standing, null, _Fit.new(), _Rules.new(),
			ground, false, false)
	var section := _section()
	t.check(judge.scale(truck, section) == 1.0,
			"at a section of the carriageway, where the truck stands, it weighs the location's own "
			+ "ground alone, the gap's weight skipped (%.2f)" % judge.scale(truck, section))

## **Tiles a caller brings are asked in the order it hands them** (`offer_on()`, for a beat her walk
## lays): the first the rules leave valid answers whatever the rooms of the ones after it, no tile
## after it is tried, none is shuffled, and tiles every rule refuses answer null.
func _test_tiles_brought_are_asked_in_the_order_handed(t: TestRunner) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var refused := Vector2i(20, 14)
	var cramped := Vector2i(21, 14)
	var roomy := Vector2i(22, 14)
	var rules := _Rules.new()
	rules.rooms = {refused: -INF, cramped: CRAMPED, roomy: ROOMY}
	var fit := _Fit.new()
	var handed: Array[Vector2i] = [refused, cramped, roomy]
	var asked := _judge(fit, rules, false).offer_on(cafe, _location(), handed, NONE)
	t.check(asked != null and _tile_of(asked) == cramped and fit.built == ([refused, cramped] as Array[Vector2i]),
			"the first tile no rule refuses answers, in the order handed, and none after it is tried (%s)"
			% [fit.built])
	var backwards: Array[Vector2i] = [roomy, cramped]
	fit.built.clear()
	var other := _judge(fit, rules, false).offer_on(cafe, _location(), backwards, NONE)
	t.check(other != null and _tile_of(other) == roomy and fit.built == ([roomy] as Array[Vector2i]),
			"and a different order answers a different tile")
	rules.rooms = {refused: -INF, cramped: -INF, roomy: -INF}
	t.check(_judge(fit, rules, false).offer_on(cafe, _location(), handed, NONE) == null,
			"tiles every rule refuses answer nothing")
	t.check(_judge(fit, rules, false).offer_on(cafe, _location(), [] as Array[Vector2i], NONE) == null,
			"and no tiles answer nothing")
