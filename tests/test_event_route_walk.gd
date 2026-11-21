extends RefCounted
## `EventRouteWalk`, at the end of a route worked out as it goes: a row told a way on
## (`EventInstance.go_on_by()`) is given a further leg there while she could be watching it, and goes
## on, still the event it was; out of her sight it ends its route; a row told none ends its route
## where it ends whatever its row (a copy of a row the director sends, as day 13's column is); and a
## row that paces a beat never asks.
##
## The route walk is a behaviour an event is composed of (`EventBehaviours.compose()`), handed its
## figure, so it is driven through an `EventInstance` out of the tree on open ground, stepped by hand,
## with a fake way on (`FakeWayOn`) and where she is told by hand (`WhereSheIs`).

const STEP := 1.0 / 60.0
const TILE := Tuning.TILE_SIZE

## **A way on that answers a live leg straight on**, three tiles down the way it is asked about, and
## records what it was asked; and no leg to leave by, so a row that leaves falls to the way out every
## event has.
class FakeWayOn extends WayOn:
	var asked: Array[Array] = []

	func _init() -> void:
		super(null, null, null)

	## Overrides WayOn.next_leg.
	func next_leg(_row: EventDef, at: Vector2, heading: Vector2, her: Vector2) -> PackedVector2Array:
		asked.append([at, heading, her])
		return PackedVector2Array([at, at + heading * 3.0 * TILE])

	## Overrides WayOn.leg_to_leave_by.
	func leg_to_leave_by(_row: EventDef, _at: Vector2, _heading: Vector2,
			_her: Vector2) -> PackedVector2Array:
		return PackedVector2Array()

func run(t: TestRunner) -> void:
	_test_told_a_way_on_and_watched_it_goes_on(t)
	_test_out_of_her_sight_it_ends_its_route(t)
	_test_told_none_it_ends_its_route_whatever_its_row(t)
	_test_a_pacing_row_never_asks(t)

## The convoy the director sends, on a two-tile route east, live past its telegraph.
static func _convoy(where: WhereSheIs, way_on: WayOn) -> EventInstance:
	var def := EventCatalogue.by_id("military_convoy").as_sent_ahead()
	var instance := EventInstance.new()
	var path := PackedVector2Array([Vector2.ZERO, Vector2(2.0 * TILE, 0.0)])
	instance.setup(def, path[0], path, Vector2.RIGHT, EventSurroundings.new().hearing(where))
	instance.restore(EventSave.new(maxf(def.telegraph_time, 0.01) + 0.05, 0.0))
	if way_on:
		instance.go_on_by(way_on)
	return instance

## Steps `instance` for `seconds` with her standing at `her`.
static func _step(instance: EventInstance, where: WhereSheIs, her: Vector2, seconds: float) -> void:
	for _i in int(seconds / STEP):
		where.tell(her)
		instance.step(STEP)

## Told a way on, with her beside its route: at the end of its route it asks for a leg from where it
## stands, the way it drives, with her place, and goes on down it still live, well past where its
## route ended.
func _test_told_a_way_on_and_watched_it_goes_on(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var way_on := FakeWayOn.new()
	var instance := _convoy(where, way_on)
	var her := Vector2(TILE, 2.0 * TILE)
	_step(instance, where, her, 1.0)
	t.check(not way_on.asked.is_empty(), "at the end of its route it asks for a further leg")
	if way_on.asked.is_empty():
		instance.free()
		return
	var first: Array = way_on.asked[0]
	t.check((first[0] as Vector2).is_equal_approx(Vector2(2.0 * TILE, 0.0))
			and (first[1] as Vector2).is_equal_approx(Vector2.RIGHT)
			and (first[2] as Vector2).is_equal_approx(her),
			"from where its route ended, the way it drives, with her place: %s" % [first])
	t.check(not instance.is_on_its_way_out() and not instance.is_gone()
			and instance.position.x > 3.0 * TILE,
			"and goes on down it, still the event it was (%.0fpx along)" % instance.position.x)
	instance.free()

## Told a way on, with her further from its route's end than `Tuning.OUT_OF_SIGHT`: it asks nothing
## and ends its route, leaving.
func _test_out_of_her_sight_it_ends_its_route(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var way_on := FakeWayOn.new()
	var instance := _convoy(where, way_on)
	_step(instance, where, Vector2(-Tuning.OUT_OF_SIGHT - 4.0 * TILE, 0.0), 1.0)
	t.check(way_on.asked.is_empty() and (instance.is_on_its_way_out() or instance.is_gone()),
			"out of her sight it asks nothing (%d) and ends its route" % way_on.asked.size())
	instance.free()

## Told none, with her beside its route: it ends its route where it ends. Its row is the copy the
## director sends (`EventDef.is_sent_ahead()`), as every copy of the row is, day 13's column and the
## escape's trucks among them: going on is told to the instance, never read off its row.
func _test_told_none_it_ends_its_route_whatever_its_row(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var instance := _convoy(where, null)
	t.check(instance.row().is_sent_ahead(), "its row is one the director sends")
	_step(instance, where, Vector2(TILE, 2.0 * TILE), 1.0)
	t.check(instance.is_on_its_way_out() or instance.is_gone(),
			"and told no way on, it ends its route where it ends")
	instance.free()

## A row that paces a beat (the raid's car, the patrol pacing) told a way on never asks: its route
## folds back and forth and has no end to go on from.
func _test_a_pacing_row_never_asks(t: TestRunner) -> void:
	var pacing: EventDef = EventCatalogue.by_id("police_patrol").duplicate()
	pacing.shape = EventCatalogue.by_id("police_patrol").shape
	pacing.paces = true
	var where := WhereSheIs.new()
	var way_on := FakeWayOn.new()
	var instance := EventInstance.new()
	var beat := PackedVector2Array([Vector2.ZERO, Vector2(2.0 * TILE, 0.0)])
	instance.setup(pacing, beat[0], beat, Vector2.RIGHT, EventSurroundings.new().hearing(where))
	instance.restore(EventSave.new(maxf(pacing.telegraph_time, 0.01) + 0.05, 0.0))
	instance.go_on_by(way_on)
	_step(instance, where, Vector2(TILE, 4.0 * TILE), 4.0)
	t.check(way_on.asked.is_empty() and not instance.is_on_its_way_out(),
			"a pacing row told a way on never asks (%d) and paces on" % way_on.asked.size())
	instance.free()
