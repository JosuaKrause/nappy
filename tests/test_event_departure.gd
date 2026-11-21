extends RefCounted
## `EventDeparture` by legs: a row told a way on (`EventInstance.go_on_by()`) leaves by the legs it
## gives (`WayOn.leg_to_leave_by()`), asked again from each leg's end the way it then faces, and is
## held to her sight, so `EventDeparture.LEAVING_GIVES_UP` never ends it beside her; a row told none
## leaves as every row does, and the backstop ends it.
##
## The departure is a behaviour an event is composed of (`EventBehaviours.compose()`), handed its
## figure, so it is driven through an `EventInstance` out of the tree on open ground, stepped by hand,
## with a fake way on (`FakeWayOn`) and where she is told by hand (`WhereSheIs`).

const STEP := 1.0 / 60.0
const TILE := Tuning.TILE_SIZE

## **A way on that gives no live leg** (`next_leg()`), so its row's route ends where it ends, **and a
## leg to leave by that turns**: a tile on the way it is asked about, then four tiles to that way's
## right, so a departure that walks it turns a quarter turn. Records what it was asked.
class FakeWayOn extends WayOn:
	var asked: Array[Array] = []

	func _init() -> void:
		super(null, null, null)

	## Overrides WayOn.next_leg.
	func next_leg(_row: EventDef, _at: Vector2, _heading: Vector2,
			_her: Vector2) -> PackedVector2Array:
		return PackedVector2Array()

	## Overrides WayOn.leg_to_leave_by.
	func leg_to_leave_by(_row: EventDef, at: Vector2, heading: Vector2,
			_her: Vector2) -> PackedVector2Array:
		asked.append([at, heading])
		var turn := heading.orthogonal() * -1.0
		return PackedVector2Array([at, at + heading * TILE, at + heading * TILE + turn * 4.0 * TILE])

func run(t: TestRunner) -> void:
	_test_by_legs_it_is_held_to_her_sight(t)
	_test_it_walks_the_legs_it_is_given(t)
	_test_told_none_the_backstop_ends_it_beside_her(t)

## The convoy the director sends (120px/s, faster than her walk), on a two-tile route east, live past
## its telegraph.
static func _convoy(where: WhereSheIs, way_on: WayOn) -> EventInstance:
	var def := EventCatalogue.by_id("military_convoy").as_sent_ahead()
	var instance := EventInstance.new()
	var path := PackedVector2Array([Vector2.ZERO, Vector2(2.0 * TILE, 0.0)])
	instance.setup(def, path[0], path, Vector2.RIGHT, EventSurroundings.new().hearing(where))
	instance.restore(EventSave.new(maxf(def.telegraph_time, 0.01) + 0.05, 0.0))
	if way_on:
		instance.go_on_by(way_on)
	return instance

## Told a way on, with her standing beside the end of its route: it leaves, and after twice
## `EventDeparture.LEAVING_GIVES_UP` with her still in sight of it, it is still there. Fails with
## the line that holds a departure by legs to her sight removed.
func _test_by_legs_it_is_held_to_her_sight(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var instance := _convoy(where, FakeWayOn.new())
	var left := -1.0
	var clock := 0.0
	var gone_near_her := false
	var her := Vector2(2.0 * TILE, 0.0)
	# She walks along behind it, keeping it within her sight.
	for _i in int((EventDeparture.LEAVING_GIVES_UP * 2.0 + 2.0) / STEP):
		where.tell(her)
		instance.step(STEP)
		clock += STEP
		if instance.is_on_its_way_out() and left < 0.0:
			left = clock
		if instance.is_gone():
			gone_near_her = instance.position.distance_to(her) <= Tuning.OUT_OF_SIGHT
			break
		her = her.move_toward(instance.position, Tuning.WALK_SPEED * 1.5 * STEP)
	t.check(left >= 0.0, "it leaves at the end of its route")
	t.check(not gone_near_her and not instance.is_gone(),
			"and %.0fs after, with her in sight of it all the while, it is still there"
			% (clock - left))
	instance.free()

## Told a way on, it walks the leg it is given, turning a quarter turn onto it, and asks for the next
## from that leg's end the way it then faces.
func _test_it_walks_the_legs_it_is_given(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var way_on := FakeWayOn.new()
	var instance := _convoy(where, way_on)
	var her := Vector2(TILE, -3.0 * TILE)
	for _i in int(3.0 / STEP):
		where.tell(her)
		instance.step(STEP)
	t.check(way_on.asked.size() >= 2, "it asks for legs to leave by (%d)" % way_on.asked.size())
	if way_on.asked.size() < 2:
		instance.free()
		return
	var first: Array = way_on.asked[0]
	var second: Array = way_on.asked[1]
	var first_end := (first[0] as Vector2) + (first[1] as Vector2) * TILE \
			+ (first[1] as Vector2).orthogonal() * -4.0 * TILE
	t.check((first[1] as Vector2).is_equal_approx(Vector2.RIGHT),
			"the first from where its route ended, the way it drove: %s" % [first])
	t.check((second[0] as Vector2).is_equal_approx(first_end)
			and (second[1] as Vector2).is_equal_approx(Vector2.DOWN),
			"the next from the first leg's end, the way it then faces: %s" % [second])
	instance.free()

## Told none, with her beside it as it leaves: the backstop ends it, as it ends every departure not
## held to her sight, and it is gone within `EventDeparture.LEAVING_GIVES_UP` and a second of leaving
## though she could still see it.
func _test_told_none_the_backstop_ends_it_beside_her(t: TestRunner) -> void:
	var where := WhereSheIs.new()
	var instance := _convoy(where, null)
	var her := Vector2(2.0 * TILE, TILE)
	var left := -1.0
	var gone := -1.0
	var clock := 0.0
	for _i in int((EventDeparture.LEAVING_GIVES_UP + 4.0) / STEP):
		where.tell(her)
		instance.step(STEP)
		clock += STEP
		if instance.is_on_its_way_out() and left < 0.0:
			left = clock
		if instance.is_gone():
			gone = clock
			break
		her = her.move_toward(instance.position, Tuning.WALK_SPEED * 1.5 * STEP)
	t.check(left >= 0.0 and gone > 0.0 and gone - left <= EventDeparture.LEAVING_GIVES_UP + 1.0,
			"told no way on, it is gone %.1fs after it leaves, with her following" % (gone - left))
	instance.free()
