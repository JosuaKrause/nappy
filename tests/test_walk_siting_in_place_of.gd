extends RefCounted
## **Day 13's swap is checked before it is accepted** (`EventScheduler.WalkSiting.in_place_of()`):
## the task's roadblock is built where one of the day's events stands, or beside it, only where the
## rules a roadblock is placed under at dawn take it there. Room all round, no other roadblock within
## `EVENT_SPACING_SAME` and nothing within `EVENT_SPACING_ANY`; clear of the ground round a region
## door (`Tuning.CHECKPOINT_EVENT_GAP`); and the event it replaces is never counted against it.
## Where the event stands on ground a roadblock does not (a sidewalk), the roadblock takes the nearest
## tile of its own ground on the same street within `EventScheduler.SWAP_SPREAD_TILES`; a tile her
## view would show it on is refused.
##
## **Why it generates a city**: a roadblock stands on a street's carriageway, which only a generated
## city lays out with its kerbs and crossings, and its placement (`EventScheduler._build_placement()`)
## reads them. The day's routes are a stand-in with none set (`tests/fake_route_tree.gd`) and the
## walk's events are a stand-in holding the plans each check sets (`tests/fake_walk_events.gd`).

const DAY := 13
const ROW := "roadblock"

var _map: CityMap
var _at: Vector2i

func run(t) -> void:
	_map = CityGenerator.generate(4242)
	_at = _a_tile_it_takes()
	t.check(_at != Vector2i(-1, -1), "the city has road a roadblock may be swapped in on")
	if _at == Vector2i(-1, -1):
		return
	_test_the_event_it_replaces_is_not_in_its_way(t)
	_test_another_roadblock_too_close_refuses_it(t)
	_test_anything_on_top_of_it_refuses_it(t)
	_test_a_region_door_beside_it_refuses_it(t)
	_test_an_event_on_the_sidewalk_gives_way_to_its_streets_carriageway(t)
	_test_a_tile_in_her_view_is_refused(t)

func _siting(plans: Array[EventScheduler.Planned],
		doors := PackedVector2Array()) -> EventScheduler.WalkSiting:
	var walk := FakeWalkEvents.new().set_plans(plans).set_doors(doors)
	return EventScheduler.WalkSiting.new(DAY, _map, FakeRouteTree.new(_map), walk,
			EventScheduler.Verdicts.new())

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("in-place-of:%d" % DAY)
	return rng

func _old() -> EventScheduler.Planned:
	return EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"), _map.tile_to_world(_at))

## The road tile nearest the map's middle where a roadblock is swapped in with nothing else down.
func _a_tile_it_takes() -> Vector2i:
	var def := EventCatalogue.by_id(ROW)
	var middle := _map.size / 2
	var tiles := EventScheduler.open_ground_for(def, _map, {}, -1, true).duplicate()
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - middle).length_squared() < (b - middle).length_squared())
	for tile: Vector2i in tiles:
		var old := EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"),
				_map.tile_to_world(tile))
		if _siting([old] as Array[EventScheduler.Planned]).in_place_of(def, old, _rng()):
			return tile
	return Vector2i(-1, -1)

func _test_the_event_it_replaces_is_not_in_its_way(t) -> void:
	var old := _old()
	var placed := _siting([old] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng())
	t.check(placed != null and placed.row_id() == ROW
			and _map.world_to_tile(placed.placed_at()) == _at,
			"a roadblock takes the place of the event it replaces, which is not counted against it")

func _test_another_roadblock_too_close_refuses_it(t) -> void:
	var old := _old()
	var def := EventCatalogue.by_id(ROW)
	var near := EventScheduler.Planned.new(def, old.placed_at() + Vector2(
			EventScheduler.EVENT_SPACING_SAME * 0.75, 0))
	var placed := _siting([old, near] as Array[EventScheduler.Planned]).in_place_of(def, old, _rng())
	t.check(placed == null
			or placed.placed_at().distance_to(near.placed_at()) >= EventScheduler.EVENT_SPACING_SAME,
			"another roadblock within %.0fpx of a tile refuses the swap there"
			% EventScheduler.EVENT_SPACING_SAME)
	var far := EventScheduler.Planned.new(def, old.placed_at() + Vector2(
			EventScheduler.EVENT_SPACING_SAME * 4.0, 0))
	placed = _siting([old, far] as Array[EventScheduler.Planned]).in_place_of(def, old, _rng())
	t.check(placed != null and _map.world_to_tile(placed.placed_at()) == _at,
			"and one well past it does not: it stands where the event stood")

func _test_anything_on_top_of_it_refuses_it(t) -> void:
	var old := _old()
	var beside := EventScheduler.Planned.new(EventCatalogue.by_id("market_stall"),
			old.placed_at() + Vector2(EventScheduler.EVENT_SPACING_ANY * 0.5, 0))
	var placed := _siting([old, beside] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng())
	t.check(placed == null or placed.gap_to(beside) >= EventScheduler.EVENT_SPACING_ANY,
			"any other event within %.0fpx of a tile refuses the swap there"
			% EventScheduler.EVENT_SPACING_ANY)

func _test_a_region_door_beside_it_refuses_it(t) -> void:
	var old := _old()
	var door := PackedVector2Array([old.placed_at() + Vector2(Tuning.CHECKPOINT_EVENT_GAP * 0.5, 0)])
	t.check(_siting([old] as Array[EventScheduler.Planned], door).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng()) == null,
			"a region door within %.0fpx refuses the swap" % Tuning.CHECKPOINT_EVENT_GAP)

## A sidewalk tile on the street `_at` is on, beside the carriageway, which a roadblock does not stand
## on (`EventScheduler.open_ground_for()` does not offer it): `Vector2i(-1, -1)` when none is.
func _a_sidewalk_beside() -> Vector2i:
	var street := _map.network.segment_containing(_at)
	var own := {}
	for tile in EventScheduler.open_ground_for(EventCatalogue.by_id(ROW), _map, {}, -1, true):
		own[tile] = true
	for distance in range(1, EventScheduler.SWAP_SPREAD_TILES + 1):
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var tile := _at + side * distance
			if _map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not own.has(tile) \
					and _map.network.segment_containing(tile) == street:
				return tile
	return Vector2i(-1, -1)

func _test_an_event_on_the_sidewalk_gives_way_to_its_streets_carriageway(t) -> void:
	var sidewalk := _a_sidewalk_beside()
	t.check(sidewalk != Vector2i(-1, -1), "the street has a sidewalk beside the road the roadblock takes")
	if sidewalk == Vector2i(-1, -1):
		return
	var old := EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"),
			_map.tile_to_world(sidewalk))
	var placed := _siting([old] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng())
	var tile := _map.world_to_tile(placed.placed_at()) if placed else Vector2i(-1, -1)
	t.check(placed != null and tile != sidewalk
			and _map.network.segment_containing(tile) == _map.network.segment_containing(sidewalk)
			and maxi(absi(tile.x - sidewalk.x), absi(tile.y - sidewalk.y))
					<= EventScheduler.SWAP_SPREAD_TILES,
			"cafe tables on the sidewalk at %s give way to a roadblock on the same street's road, at %s"
			% [sidewalk, tile])

func _test_a_tile_in_her_view_is_refused(t) -> void:
	var old := _old()
	var nowhere := func(_row: EventDef, _at_point: Vector2) -> bool: return true
	t.check(_siting([old] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng(), nowhere) == null,
			"with every tile in her view, no roadblock is swapped in")
	var at_old := _map.tile_to_world(_at)
	var only_its_own := func(_row: EventDef, at_point: Vector2) -> bool:
		return at_point == at_old
	var placed := _siting([old] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng(), only_its_own)
	t.check(placed == null or _map.world_to_tile(placed.placed_at()) != _at,
			"and with its own tile in her view, it is never put there")
