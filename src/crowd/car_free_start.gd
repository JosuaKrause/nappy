class_name CarFreeStart
extends RefCounted
## Day 1's car-free start: no new car comes into the crowd's box from the moment play begins until
## she is past the crossing taught with no cars (the fourth street of the tutorial route, a street
## before the crossing with cars) or is a full block from the tutorial route, whichever comes first (`docs/MECHANICS.md`, "The car-free start"). Simulation layer, ticked once a tick with her
## position by the crowd it was handed to (`Crowd.use_car_free_start()`).
##
## **The first tick holds the cars**: the crowd is handed her, and so ticks this, only when play
## begins, while the title is up over a crowd already driving, so the title keeps today's density
## and none is near her door when play begins. A morning that starts without a title is held from
## the start (`hold_now()`). **It lets them in once, for good**, so a player who comes back to the
## route finds the cars still driving. It keeps no state a save needs: on a resumed day 1 the same
## two questions, asked of where she stands, give the same answer.
##
## The route is handed as rectangles in world pixels, so a test needs no city.

var _route: Array[Rect2]
var _past_the_crossing_lesson: Array[Rect2]
var _block: float
var _hold_cars: Callable
var _let_cars_in: Callable
var _holding := false
var _over := false

## `route` is the ground of the doorstep's street and the lesson streets; `past_the_crossing` the
## ground past the crossing with no cars (lesson 4's zebra), where the cars are let in; `block` how
## far from `route` she may be before they are. `hold_cars` and `let_cars_in` take nothing.
func _init(route: Array[Rect2], past_the_crossing: Array[Rect2], block: float,
		hold_cars: Callable, let_cars_in: Callable) -> void:
	_route = route
	_past_the_crossing_lesson = past_the_crossing
	_block = block
	_hold_cars = hold_cars
	_let_cars_in = let_cars_in

## The start for day 1's `route`: the cars are let in once she stands on the fourth street's
## ground or beyond (the first lesson street that follows the crossing with no cars, which opens
## the fourth street: `TutorialRoute.lesson_streets()` index 2) or is one street's length
## (`CityMap.period()` tiles, a block and its road) from the route.
static func for_route(route: TutorialRoute, hold_cars: Callable, let_cars_in: Callable) \
		-> CarFreeStart:
	var ground: Array[Rect2] = [_world_rect(route.doorstep_street().run_rect())]
	var past: Array[Rect2] = []
	var streets := route.lesson_streets()
	for i in streets.size():
		ground.append(_world_rect(streets[i].run_rect()))
		if i >= FIRST_STREET_PAST_THE_CROSSING:
			past.append(_world_rect(streets[i].tile_rect()))
	return CarFreeStart.new(ground, past, float(CityMap.period() * Tuning.TILE_SIZE),
			hold_cars, let_cars_in)

## The index among `TutorialRoute.lesson_streets()` of the street lesson (4)'s zebra leads onto: the
## fourth street of the walk, the doorstep's being the first.
const FIRST_STREET_PAST_THE_CROSSING := 2

static func _world_rect(tiles: Rect2i) -> Rect2:
	return Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE)

## Holds the cars now rather than on the first tick: a morning with no title in front of it.
func hold_now() -> void:
	if _holding or _over:
		return
	_holding = true
	_hold_cars.call()

## One tick of play, with where she stands.
func watch_her(at: Vector2) -> void:
	if _over:
		return
	hold_now()
	if _on_any(_past_the_crossing_lesson, at) or _distance_to_the_route(at) >= _block:
		_over = true
		_let_cars_in.call()

func _on_any(rects: Array[Rect2], at: Vector2) -> bool:
	for rect in rects:
		if rect.has_point(at):
			return true
	return false

## Her straight-line distance from the nearest rectangle of the route.
func _distance_to_the_route(at: Vector2) -> float:
	var nearest := INF
	for rect in _route:
		var dx := maxf(maxf(rect.position.x - at.x, at.x - rect.end.x), 0.0)
		var dy := maxf(maxf(rect.position.y - at.y, at.y - rect.end.y), 0.0)
		nearest = minf(nearest, sqrt(dx * dx + dy * dy))
	return nearest
