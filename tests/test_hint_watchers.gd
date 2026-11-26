extends RefCounted
## The hints' watchers (`HintWatcher`'s implementations under `src/player/hints/`), each asked what
## the game asks it: a walk begun with the route, then a frame of her position and heading. One
## suite for the family, each case building only the watcher it names over fakes: the map is a
## stand-in answering the tile types laid on it and the holds and closures set on it, the events
## answer the bodies and doors set on them, the view what it is told it sees, and the sources the
## carets they are given. The crossing search is the real `NearestCrossing` over the fake map, a
## plain search the zebra's and the street's watchers share.

## A map whose tiles are the ones laid on it, and a building elsewhere; closures and the streets
## held for a body across them are the tiles set on it.
class _Ground extends CityMap:
	var _ground := {}
	var _closed := {}
	var _barred := {}

	func lay(tile: Vector2i, type: GameEnums.TileType) -> void:
		_ground[tile] = type

	func close(tile: Vector2i) -> void:
		_closed[tile] = true

	func bar(tile: Vector2i) -> void:
		_barred[tile] = true

	## Overrides CityMap.tile_at.
	func tile_at(tile: Vector2i) -> GameEnums.TileType:
		return _ground.get(tile, GameEnums.TileType.BUILDING)

	## Overrides CityMap.is_closed.
	func is_closed(tile: Vector2i) -> bool:
		return _closed.has(tile)

	## Overrides CityMap.is_barred_at.
	func is_barred_at(tile: Vector2i) -> bool:
		return _barred.has(tile)

## A route that runs over the one tile column `x`, passes `junctions` and has its park at `park`.
class _Route extends TutorialRoute:
	var _x := 0
	var _park := Rect2i()

	func _init(x: int, park: Rect2i, junctions: Array[Vector2i] = [], park_block := Vector2i.ZERO) -> void:
		super(null, StreetNetwork.Segment.new(Vector2i(0, 0), true),
				[] as Array[StreetNetwork.Segment], junctions, park_block, Rect2i())
		_x = x
		_park = park

	## Overrides TutorialRoute.runs_over.
	func runs_over(tile: Vector2i) -> bool:
		return tile.x == _x

	## Overrides TutorialRoute.has_in_its_park.
	func has_in_its_park(tile: Vector2i) -> bool:
		return _park.has_point(tile)

## Events whose solid bodies stand at the points set on them, and whose doors in sight are set.
class _Events extends EventManager:
	var _bodies: Array[Vector2] = []
	var _doors: Array[EventInstance] = []

	func stand_a_body(at: Vector2) -> void:
		_bodies.append(at)

	func show_doors(doors: Array[EventInstance]) -> void:
		_doors = doors

	## Overrides EventManager.has_a_body_on.
	func has_a_body_on(stretch: Rect2) -> bool:
		for body in _bodies:
			if stretch.has_point(body):
				return true
		return false

	## Overrides EventManager.doors_in_sight.
	func doors_in_sight() -> Array[EventInstance]:
		return _doors

## A view that sees only the points set on it.
class _View extends VisibleView:
	var _seen: Array[Vector2] = []

	func show(point: Vector2) -> void:
		_seen.append(point)

	## Overrides VisibleView.sees.
	func sees(point: Vector2) -> bool:
		return point in _seen

## A source whose caret is the one set on it.
class _Source extends ExcitementSource:
	var _given := 0

	func _init(body: Node2D, caret: int) -> void:
		super(body)
		_given = caret

	## Overrides ExcitementSource.caret_strength.
	func caret_strength() -> int:
		return _given

## A set of sources that is the sources handed it.
class _Sources extends ExcitementSources:
	var _sources: Array[ExcitementSource] = []

	func _init(sources: Array[ExcitementSource]) -> void:
		_sources = sources

	## Overrides ExcitementSources.every_source.
	func every_source(into: Array) -> void:
		into.append_array(_sources)

func run(t: TestRunner) -> void:
	_test_back_to_the_route_asks_after_a_moment_off_it_and_points_at_it(t)
	_test_back_to_the_route_is_armed_again_once_she_is_on_it(t)
	_test_back_to_the_route_stops_in_the_park_until_the_next_walk(t)
	_test_no_route_no_bubble(t)
	_test_the_zebra_asks_on_the_road_and_points_at_the_crossing(t)
	_test_the_way_to_the_park_points_on_at_each_junction(t)
	_test_walk_wide_asks_for_an_amber_caret_ahead(t)
	_test_turn_back_asks_at_a_seal_or_closure_ahead(t)
	_test_cross_the_street_asks_when_her_sidewalk_is_closed_and_the_far_one_open(t)
	_test_the_chalk_mark_asks_once_a_walk_when_it_comes_into_view(t)
	_test_the_hut_asks_for_a_door_she_has_not_met(t)

func _frame_at(tile: Vector2i, seconds := 0.1, heading := Vector2.RIGHT) -> HintFrame:
	return HintFrame.new(Vector2(tile * Tuning.TILE_SIZE) + Vector2.ONE * 16.0, heading, seconds)

func _back_to(route: TutorialRoute) -> BackToRouteWatcher:
	var watcher := BackToRouteWatcher.new(_Ground.new())
	watcher.begin_walk(route)
	return watcher

func _test_back_to_the_route_asks_after_a_moment_off_it_and_points_at_it(t: TestRunner) -> void:
	var watcher := _back_to(_Route.new(10, Rect2i()))
	t.check(not watcher.asks(_frame_at(Vector2i(10, 4))), "on the route it does not ask")
	t.check(not watcher.asks(_frame_at(Vector2i(13, 4), 0.2)), "a step off the route is no leaving")
	t.check(watcher.asks(_frame_at(Vector2i(13, 4), 1.0)), "off it for a moment, it asks")
	t.check(watcher.direction(_frame_at(Vector2i(13, 4))).is_equal_approx(Vector2.LEFT),
			"pointing at the nearest tile of the route")
	t.check(watcher.every_time(), "it is the hint that shows every time")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i(13, 4), 1.0)), "once shown it waits to be re-armed")
	t.check(watcher.still_applies(_frame_at(Vector2i(13, 4))), "its bubble holds while she is off")
	t.check(not watcher.still_applies(_frame_at(Vector2i(10, 4))), "and goes once she is on")

func _test_back_to_the_route_is_armed_again_once_she_is_on_it(t: TestRunner) -> void:
	var watcher := _back_to(_Route.new(10, Rect2i()))
	watcher.asks(_frame_at(Vector2i(14, 4), 1.0))
	watcher.shown()
	watcher.asks(_frame_at(Vector2i(10, 4)))
	t.check(watcher.asks(_frame_at(Vector2i(14, 4), 1.0)), "leaving again asks again")

func _test_back_to_the_route_stops_in_the_park_until_the_next_walk(t: TestRunner) -> void:
	var route := _Route.new(10, Rect2i(20, 0, 5, 5))
	var watcher := _back_to(route)
	watcher.asks(_frame_at(Vector2i(21, 2)))
	t.check(not watcher.asks(_frame_at(Vector2i(14, 4), 1.0)),
			"once she has reached the park the walk home is hers")
	watcher.begin_walk(route)
	t.check(watcher.asks(_frame_at(Vector2i(14, 4), 1.0)),
			"and a retried day 1 asks again from its start")

func _test_no_route_no_bubble(t: TestRunner) -> void:
	var watcher := _back_to(null)
	t.check(not watcher.asks(_frame_at(Vector2i(14, 4), 5.0)), "a walk with no tutorial route asks nothing")
	t.check(not watcher.still_applies(_frame_at(Vector2i(14, 4))), "and holds no bubble")
	var park := WayToParkWatcher.new(_Ground.new())
	park.begin_walk(null)
	t.check(not park.asks(_frame_at(Vector2i(14, 4))) and park.direction(_frame_at(Vector2i(1, 1))) == Vector2.ZERO,
			"nor does the way to the park")

func _test_the_zebra_asks_on_the_road_and_points_at_the_crossing(t: TestRunner) -> void:
	var map := _Ground.new()
	for y in range(0, 6):
		map.lay(Vector2i(5, y), GameEnums.TileType.ROAD)
	map.lay(Vector2i(5, 5), GameEnums.TileType.CROSSING)
	var watcher := UseZebraWatcher.new(map, NearestCrossing.new(map))
	t.check(not watcher.asks(_frame_at(Vector2i(4, 1))), "off the road it does not ask")
	t.check(watcher.asks(_frame_at(Vector2i(5, 2))), "on the carriageway away from a crossing it asks")
	t.check(watcher.direction(_frame_at(Vector2i(5, 2))).is_equal_approx(Vector2.DOWN),
			"pointing at the crossing")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i(5, 3))), "once shown it waits until she is off the road")
	watcher.asks(_frame_at(Vector2i(4, 3)))
	t.check(watcher.asks(_frame_at(Vector2i(5, 3))), "and asks again on the next step onto it")
	t.check(not watcher.asks(_frame_at(Vector2i(5, 5))), "on the crossing it never asks")

func _test_the_way_to_the_park_points_on_at_each_junction(t: TestRunner) -> void:
	var period := CityMap.period()
	var junctions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1)]
	var park_block := Vector2i(1, 1)
	var route := _Route.new(-1, CityMap.block_rect(park_block), junctions, park_block)
	var map := _Ground.new()
	var watcher := WayToParkWatcher.new(map)
	watcher.begin_walk(route)
	var start := Vector2i(2, 2)
	var first := Vector2i(period + 2, 2)
	var second := Vector2i(period + 2, period + 2)
	t.check(watcher.asks(_frame_at(start)), "it asks as play starts")
	var to_first := map.tile_rect_to_world(Rect2i(junctions[0] * period, Vector2i.ONE * Tuning.STREET_WIDTH)).get_center()
	t.check(watcher.direction(_frame_at(start)).is_equal_approx(
			(to_first - _frame_at(start).position()).normalized()), "pointing at the first junction")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(start + Vector2i.RIGHT)), "once shown it waits for a junction")
	t.check(watcher.asks(_frame_at(first + Vector2i(3, 3))),
			"anywhere in the junction's box she has come to it, its outer corner too")
	t.check(watcher.direction(_frame_at(first)).y > 0.9, "and it points on to the next one, south")
	watcher.shown()
	t.check(watcher.asks(_frame_at(second)), "the last junction points on to the park")
	watcher.shown()
	var in_the_park := CityMap.block_rect(park_block).get_center()
	t.check(not watcher.asks(_frame_at(in_the_park)), "in the park it stops")
	t.check(not watcher.asks(_frame_at(start)), "and stays stopped for the rest of the walk")
	watcher.begin_walk(route)
	t.check(watcher.asks(_frame_at(start)), "a retried day 1 starts it again")

func _test_walk_wide_asks_for_an_amber_caret_ahead(t: TestRunner) -> void:
	var ahead := Node2D.new()
	ahead.position = Vector2(100.0, 0.0)
	var behind := Node2D.new()
	behind.position = Vector2(-100.0, 0.0)
	t.add_child(ahead)
	t.add_child(behind)
	var amber := _Source.new(ahead, WalkWideWatcher.AMBER)
	var sets: Array[ExcitementSources] = [_Sources.new([amber] as Array[ExcitementSource])]
	var watcher := WalkWideWatcher.new(sets)
	var facing_east := HintFrame.new(Vector2.ZERO, Vector2.RIGHT, 0.1)
	t.check(watcher.asks(facing_east), "an amber caret ahead of her asks")
	watcher.shown()
	t.check(not watcher.asks(facing_east), "once shown it waits for the way ahead to clear")
	t.check(not watcher.asks(HintFrame.new(Vector2.ZERO, Vector2.LEFT, 0.1)), "behind her it asks nothing")
	t.check(watcher.asks(facing_east), "and once it has cleared, asks again")
	var red := WalkWideWatcher.new([_Sources.new([_Source.new(ahead, 2)] as Array[ExcitementSource])]
			as Array[ExcitementSources])
	t.check(not red.asks(facing_east), "the doubled red caret is not a noise to walk wide of")
	var far_behind := WalkWideWatcher.new([_Sources.new([_Source.new(behind, WalkWideWatcher.AMBER)]
			as Array[ExcitementSource])] as Array[ExcitementSources])
	t.check(not far_behind.asks(facing_east), "an amber caret behind her asks nothing")
	ahead.free()
	behind.free()

func _street_row(map: _Ground, y: int, from: int, to: int) -> void:
	for x in range(from, to + 1):
		map.lay(Vector2i(x, y), GameEnums.TileType.SIDEWALK)

func _test_turn_back_asks_at_a_seal_or_closure_ahead(t: TestRunner) -> void:
	var map := _Ground.new()
	_street_row(map, 3, 0, 20)
	map.close(Vector2i(6, 3))
	var watcher := TurnBackWatcher.new(map)
	t.check(not watcher.asks(_frame_at(Vector2i(0, 3))), "a closure further than she looks asks nothing")
	t.check(watcher.asks(_frame_at(Vector2i(3, 3))), "a closure a few tiles along her heading asks")
	t.check(not watcher.asks(_frame_at(Vector2i(3, 3), 0.1, Vector2.LEFT)),
			"walking away from it, nothing")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i(3, 3))), "once shown it waits for the way to open")
	var walls := _Ground.new()
	_street_row(walls, 3, 0, 20)
	walls.obstruct_tiles(1, [Vector2i(5, 3)] as Array[Vector2i])
	walls.obstruct_tiles(2, [Vector2i(15, 3)] as Array[Vector2i])
	walls.bar(Vector2i(15, 3))
	var seal := TurnBackWatcher.new(walls)
	t.check(not seal.asks(_frame_at(Vector2i(2, 3))),
			"a body on a street held for no body across it (a café, a door's hut) asks nothing")
	t.check(seal.asks(_frame_at(Vector2i(12, 3))), "a seal's body on a barred street asks")
	t.check(not TurnBackWatcher.new(walls).asks(_frame_at(Vector2i(12, 3), 0.1, Vector2.UP)),
			"nor does a building beside her")

func _test_cross_the_street_asks_when_her_sidewalk_is_closed_and_the_far_one_open(t: TestRunner) -> void:
	var period := CityMap.period()
	var map := _Ground.new()
	var x0 := period
	var y0 := period + 6
	for y in range(y0 - 12, y0 + 12):
		for offset in range(Tuning.STREET_WIDTH):
			var type := GameEnums.TileType.ROAD
			if offset < Tuning.SIDEWALK_WIDTH or offset >= Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH:
				type = GameEnums.TileType.SIDEWALK
			map.lay(Vector2i(x0 + offset, y), type)
	map.lay(Vector2i(x0 + 2, y0 - 8), GameEnums.TileType.CROSSING)
	var events := _Events.new(EventSurroundings.new().reading(EventCatalogue.shipped()))
	var crossings := NearestCrossing.new(map)
	var her := Vector2i(x0, y0)
	var south := Vector2.DOWN
	var watcher := CrossStreetWatcher.new(map, events, crossings)
	t.check(not watcher.asks(_frame_at(her, 0.1, south)), "an open sidewalk asks nothing")
	events.stand_a_body(map.tile_rect_to_world(Rect2i(her + Vector2i(1, 2), Vector2i.ONE)).get_center())
	t.check(watcher.asks(_frame_at(her, 0.1, south)), "a body on her sidewalk ahead, the far one open, asks")
	t.check(watcher.direction(_frame_at(her)).y < -0.9, "pointing at the nearest crossing, north")
	t.check(not watcher.asks(_frame_at(her, 0.1, Vector2.UP)), "walking away from the body, nothing")
	t.check(not watcher.asks(_frame_at(her, 0.1, Vector2.RIGHT)), "nor across the street")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(her, 0.1, south)), "once shown it waits for the moment to pass")
	var both := _Events.new(EventSurroundings.new().reading(EventCatalogue.shipped()))
	both.stand_a_body(map.tile_rect_to_world(Rect2i(her + Vector2i(1, 2), Vector2i.ONE)).get_center())
	both.stand_a_body(map.tile_rect_to_world(Rect2i(her + Vector2i(4, 2), Vector2i.ONE)).get_center())
	t.check(not CrossStreetWatcher.new(map, both, crossings).asks(_frame_at(her, 0.1, south)),
			"with the far sidewalk closed too, crossing is no answer")
	events.free()
	both.free()

func _test_the_chalk_mark_asks_once_a_walk_when_it_comes_into_view(t: TestRunner) -> void:
	var view := _View.new()
	var mark := Vector2(300.0, 40.0)
	var on_offer := [Vector2.INF]
	var watcher := ChalkMarkWatcher.new(view, func() -> Vector2: return on_offer[0])
	watcher.begin_walk(null)
	t.check(not watcher.asks(_frame_at(Vector2i.ZERO)), "no mark on offer, nothing")
	on_offer[0] = mark
	t.check(not watcher.asks(_frame_at(Vector2i.ZERO)), "a mark out of her view, nothing")
	view.show(mark)
	t.check(watcher.asks(_frame_at(Vector2i.ZERO)), "the mark coming into her view asks")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i.ZERO)), "only the first time in the walk")
	watcher.begin_walk(null)
	t.check(watcher.asks(_frame_at(Vector2i.ZERO)), "a retried day asks again")

func _test_the_hut_asks_for_a_door_she_has_not_met(t: TestRunner) -> void:
	var events := _Events.new(EventSurroundings.new().reading(EventCatalogue.shipped()))
	var hut := EventInstance.new()
	var other := EventInstance.new()
	var watcher := WalkThroughHutWatcher.new(events)
	watcher.begin_walk(null)
	t.check(not watcher.asks(_frame_at(Vector2i.ZERO)), "no door in sight, nothing")
	events.show_doors([hut] as Array[EventInstance])
	t.check(watcher.asks(_frame_at(Vector2i.ZERO)), "a hut she may walk through, in sight, asks")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i.ZERO)), "the hut she has met asks no more")
	events.show_doors([hut, other] as Array[EventInstance])
	t.check(watcher.asks(_frame_at(Vector2i.ZERO)), "a hut she has not met asks")
	watcher.begin_walk(null)
	events.show_doors([hut] as Array[EventInstance])
	t.check(watcher.asks(_frame_at(Vector2i.ZERO)), "a new walk has met none")
	hut.free()
	other.free()
	events.free()
