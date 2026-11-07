extends RefCounted
## **Day 13's swap is checked before it is accepted** (`EventScheduler.WalkSiting.in_place_of()`):
## the task's roadblock is built where one of the day's events stands only where the rules a
## roadblock is placed under at dawn take it there. Room all round, no other roadblock within
## `EVENT_SPACING_SAME` and nothing within `EVENT_SPACING_ANY`; clear of the ground round a region
## door (`Tuning.CHECKPOINT_EVENT_GAP`); and the event it replaces is never counted against it.
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
	t.check(_siting([old, near] as Array[EventScheduler.Planned]).in_place_of(def, old, _rng())
			== null, "another roadblock within %.0fpx refuses the swap"
			% EventScheduler.EVENT_SPACING_SAME)
	var far := EventScheduler.Planned.new(def, old.placed_at() + Vector2(
			EventScheduler.EVENT_SPACING_SAME * 4.0, 0))
	t.check(_siting([old, far] as Array[EventScheduler.Planned]).in_place_of(def, old, _rng())
			!= null, "and one well past it does not")

func _test_anything_on_top_of_it_refuses_it(t) -> void:
	var old := _old()
	var beside := EventScheduler.Planned.new(EventCatalogue.by_id("market_stall"),
			old.placed_at() + Vector2(EventScheduler.EVENT_SPACING_ANY * 0.5, 0))
	t.check(_siting([old, beside] as Array[EventScheduler.Planned]).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng()) == null,
			"any other event within %.0fpx refuses the swap" % EventScheduler.EVENT_SPACING_ANY)

func _test_a_region_door_beside_it_refuses_it(t) -> void:
	var old := _old()
	var door := PackedVector2Array([old.placed_at() + Vector2(Tuning.CHECKPOINT_EVENT_GAP * 0.5, 0)])
	t.check(_siting([old] as Array[EventScheduler.Planned], door).in_place_of(
			EventCatalogue.by_id(ROW), old, _rng()) == null,
			"a region door within %.0fpx refuses the swap" % Tuning.CHECKPOINT_EVENT_GAP)
