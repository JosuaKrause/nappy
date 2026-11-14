extends RefCounted
## `RuledLocationGround`'s three settings, the judge as the unit draw and the scripted rows each
## make it: with `roomiest` false it takes the first tile no rule refuses, cramped or not, and with
## it true the first with room all round, else the roomiest; a rule handed in `also` refuses a tile
## the day's rules allow, asked with what the day's rules are asked; and with
## `keeps_routes_on_the_run` a route is built inside its location's run (`Location.run()`), with it
## false on no bound.
##
## Run with stand-ins for what it is handed: the fit (`_Fit`, whose tiles a check sets and which
## records each build and its bound), the day's rules (`_Rules`, the room of each tile set by
## hand) and an extra rule (`_Refusing`); the location is real (`Location`, state), on a street
## made by hand on the lattice's numbers.

func run(t: TestRunner) -> void:
	_test_the_first_allowed_tile_or_the_roomiest(t)
	_test_a_rule_handed_in_also_refuses(t)
	_test_a_route_is_built_inside_its_run(t)

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

class _Refusing extends StreetRule:
	var refused: Array[Vector2i] = []
	## What each ask was handed as what the walk placed, and as that with what stands.
	var asked_placed: Array = []
	var asked_around: Array = []

	## Overrides StreetRule.allows.
	func allows(_candidate: EventPlan, tile: Vector2i, placed: Array[EventPlan],
			around: Array[EventPlan]) -> bool:
		asked_placed.append(placed.duplicate())
		asked_around.append(around.duplicate())
		return not refused.has(tile)

static func _location() -> Location:
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var tiles := Rect2i(segment.tile_rect().position, Vector2i(3, 2))
	return Location.new(segment, 0, tiles, Vector2(tiles.position) * Tuning.TILE_SIZE,
			PlacementView.View.ON_THE_ROUTE, true, Location.Kind.SIDEWALK)

static func _judge(fit: _Fit, rules: _Rules, roomiest: bool, on_the_run := false,
		also: Array[StreetRule] = [], standing: Array[EventPlan] = []) -> RuledLocationGround:
	return RuledLocationGround.new(1, 7, null, standing, null, fit, rules, null, roomiest,
			on_the_run, also)

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

func _test_a_rule_handed_in_also_refuses(t: TestRunner) -> void:
	var cafe := EventCatalogue.by_id("cafe_tables")
	var only := Vector2i(21, 14)
	var rules := _Rules.new()
	rules.rooms = {only: ROOMY}
	var fit := _Fit.new()
	fit.offered = [only] as Array[Vector2i]
	var refusing := _Refusing.new()
	refusing.refused = [only] as Array[Vector2i]
	var also: Array[StreetRule] = [refusing]
	var placed: Array[EventPlan] = [EventPlan.new(cafe, Vector2(5000, 5000))]
	var standing: Array[EventPlan] = [EventPlan.new(EventCatalogue.by_id("roadblock"),
			Vector2(6000, 6000))]
	t.check(_judge(fit, rules, false, false, also, standing).offer(cafe, _location(), placed)
			== null, "a tile the day's rules leave room all round is refused by a rule handed in")
	t.check(refusing.asked_placed == [placed] and refusing.asked_around.size() == 1
			and (refusing.asked_around[0] as Array).size() == 2,
			"asked with what the walk placed, and that with what the day stands")
	refusing.refused.clear()
	t.check(_judge(fit, rules, false, false, also, standing).offer(cafe, _location(), placed)
			!= null, "and allowed where that rule allows it")

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
