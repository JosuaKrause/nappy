extends RefCounted
## The hints' watchers, each asked what the game asks it: a frame of her position and heading, and
## the map and today's streets it reads. The map is a stand-in answering the tile types laid on it;
## the route is hand-laid and answers which tiles it runs over and what is its park.

## A map whose tiles are the ones laid on it, and a building elsewhere.
class _Ground extends CityMap:
	var _ground := {}

	func lay(tile: Vector2i, type: GameEnums.TileType) -> void:
		_ground[tile] = type

	## Overrides CityMap.tile_at.
	func tile_at(tile: Vector2i) -> GameEnums.TileType:
		return _ground.get(tile, GameEnums.TileType.BUILDING)

## A route that runs over the one tile column `x` and has its park at `park`.
class _Column extends TutorialRoute:
	var _x := 0
	var _park := Rect2i()

	func _init(x: int, park: Rect2i) -> void:
		super(null, StreetNetwork.Segment.new(Vector2i(0, 0), true),
				[] as Array[StreetNetwork.Segment], [] as Array[Vector2i], Vector2i.ZERO, Rect2i())
		_x = x
		_park = park

	## Overrides TutorialRoute.runs_over.
	func runs_over(tile: Vector2i) -> bool:
		return tile.x == _x

	## Overrides TutorialRoute.has_in_its_park.
	func has_in_its_park(tile: Vector2i) -> bool:
		return _park.has_point(tile)

## Today's streets answering one route.
class _Streets extends DayStreets:
	var _route: TutorialRoute

	func _init(route: TutorialRoute) -> void:
		_route = route

	## Overrides DayStreets.tutorial_route.
	func tutorial_route() -> TutorialRoute:
		return _route

func run(t: TestRunner) -> void:
	_test_back_to_the_route_asks_after_a_moment_off_it_and_points_at_it(t)
	_test_back_to_the_route_is_armed_again_once_she_is_on_it(t)
	_test_back_to_the_route_stops_in_the_park(t)
	_test_no_route_no_bubble(t)
	_test_the_zebra_asks_on_the_road_and_points_at_the_crossing(t)

func _frame_at(tile: Vector2i, seconds := 0.1) -> HintFrame:
	return HintFrame.new(Vector2(tile * Tuning.TILE_SIZE) + Vector2.ONE * 16.0, Vector2.RIGHT, seconds)

func _test_back_to_the_route_asks_after_a_moment_off_it_and_points_at_it(t: TestRunner) -> void:
	var watcher := BackToRouteWatcher.new(_Streets.new(_Column.new(10, Rect2i())), _Ground.new())
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
	var watcher := BackToRouteWatcher.new(_Streets.new(_Column.new(10, Rect2i())), _Ground.new())
	watcher.asks(_frame_at(Vector2i(14, 4), 1.0))
	watcher.shown()
	watcher.asks(_frame_at(Vector2i(10, 4)))
	t.check(watcher.asks(_frame_at(Vector2i(14, 4), 1.0)), "leaving again asks again")

func _test_back_to_the_route_stops_in_the_park(t: TestRunner) -> void:
	var park := Rect2i(20, 0, 5, 5)
	var watcher := BackToRouteWatcher.new(_Streets.new(_Column.new(10, park)), _Ground.new())
	watcher.asks(_frame_at(Vector2i(21, 2)))
	t.check(not watcher.asks(_frame_at(Vector2i(14, 4), 1.0)),
			"once she has reached the park the walk home is hers")

func _test_no_route_no_bubble(t: TestRunner) -> void:
	var watcher := BackToRouteWatcher.new(_Streets.new(null), _Ground.new())
	t.check(not watcher.asks(_frame_at(Vector2i(14, 4), 5.0)), "a day with no tutorial route asks nothing")

func _test_the_zebra_asks_on_the_road_and_points_at_the_crossing(t: TestRunner) -> void:
	var map := _Ground.new()
	for y in range(0, 6):
		map.lay(Vector2i(5, y), GameEnums.TileType.ROAD)
	map.lay(Vector2i(5, 5), GameEnums.TileType.CROSSING)
	var watcher := UseZebraWatcher.new(map)
	t.check(not watcher.asks(_frame_at(Vector2i(4, 1))), "off the road it does not ask")
	t.check(watcher.asks(_frame_at(Vector2i(5, 2))), "on the carriageway away from a crossing it asks")
	t.check(watcher.direction(_frame_at(Vector2i(5, 2))).is_equal_approx(Vector2.DOWN),
			"pointing at the crossing")
	watcher.shown()
	t.check(not watcher.asks(_frame_at(Vector2i(5, 3))), "once shown it waits until she is off the road")
	watcher.asks(_frame_at(Vector2i(4, 3)))
	t.check(watcher.asks(_frame_at(Vector2i(5, 3))), "and asks again on the next step onto it")
	t.check(not watcher.asks(_frame_at(Vector2i(5, 5))), "on the crossing it never asks")
