extends RefCounted
## `CarFreeStart` on its own: handed rectangles for the route and the ground past the crossing
## lesson, and two callables that record what it asks of the crowd, so no city or crowd is built.
## The route's geometry (`for_route()`) is held on a route laid by hand, which needs no map.

var _held := 0
var _let_in := 0

func _hold() -> void:
	_held += 1

func _release() -> void:
	_let_in += 1

func _start(route: Array[Rect2], past: Array[Rect2]) -> CarFreeStart:
	_held = 0
	_let_in = 0
	return CarFreeStart.new(route, past, 400.0, _hold, _release)

func run(t: TestRunner) -> void:
	var route: Array[Rect2] = [Rect2(0, 0, 1000, 100)]
	var past: Array[Rect2] = [Rect2(1000, 0, 500, 100)]

	var start := _start(route, past)
	start.watch_her(Vector2(10, 50))
	t.check(_held == 1 and _let_in == 0, "the first tick of play holds the cars, once")
	start.watch_her(Vector2(500, 50))
	start.watch_her(Vector2(600, 450))
	t.check(_held == 1 and _let_in == 0,
			"on the route, or less than a block off it, the cars stay held")

	start.watch_her(Vector2(1200, 50))
	t.check(_let_in == 1, "past the crossing lesson the cars are let in")
	start.watch_her(Vector2(10, 50))
	start.watch_her(Vector2(2000, 2000))
	t.check(_held == 1 and _let_in == 1,
			"they are let in once, for good: back on the route holds nothing again")

	start = _start(route, past)
	start.watch_her(Vector2(300, 100 + 399))
	t.check(_let_in == 0, "just under a block from the route is still held")
	start.watch_her(Vector2(300, 100 + 400))
	t.check(_let_in == 1, "a block from the route lets the cars in")

	start = _start(route, past)
	start.watch_her(Vector2(-300, -300))
	t.check(_let_in == 1, "a block off the route's end counts the same: it is a distance")

	start = _start(route, past)
	start.hold_now()
	t.check(_held == 1, "a start with no title in front of it holds at once")
	start.watch_her(Vector2(10, 50))
	t.check(_held == 1, "and holds only once")

	_test_the_route_it_is_made_for(t)

func _test_the_route_it_is_made_for(t: TestRunner) -> void:
	var home := StreetNetwork.Segment.new(Vector2i(0, 0), true)
	var streets: Array[StreetNetwork.Segment] = []
	for i in 5:
		streets.append(StreetNetwork.Segment.new(Vector2i(i + 1, 0), true))
	var junctions: Array[Vector2i] = []
	var route := TutorialRoute.new(null, home, streets, junctions, Vector2i.ZERO, Rect2i())
	var start := CarFreeStart.for_route(route, _hold, _release)
	_held = 0
	_let_in = 0
	var second := streets[1].tile_rect()
	var fourth := streets[2].tile_rect()
	start.watch_her(Vector2(second.get_center()) * Tuning.TILE_SIZE)
	t.check(_held == 1 and _let_in == 0, "standing on the second lesson street is not past the crossing")
	start.watch_her(Vector2(fourth.get_center()) * Tuning.TILE_SIZE)
	t.check(_let_in == 1, "standing on the fourth street lets the cars in")
