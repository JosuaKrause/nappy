extends "res://tests/events_shared_city.gd"
## Focused checks for the scheduler's route-to-route spacing arithmetic, and that no two events of a
## planned day are drawn inside each other (the planned day is the shared city's, from
## `events_shared_city.gd`).

func run(t: TestRunner) -> void:
	_test_stationary_pairs(t)
	_test_one_stationary_side(t)
	_test_one_point_paths_are_stationary(t)
	_test_stationary_fast_paths_match_the_symmetric_oracle_in_both_orders(t)
	_test_no_two_events_are_drawn_inside_each_other(t)

func _plan(at: Vector2, path := PackedVector2Array()) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id("busker"), at, path)

func _symmetric_gap(a: EventPlan, b: EventPlan) -> float:
	var gap := INF
	for point in a.ends():
		gap = minf(gap, b.distance_from(point))
	for point in b.ends():
		gap = minf(gap, a.distance_from(point))
	return gap

func _test_stationary_pairs(t: TestRunner) -> void:
	var a := _plan(Vector2(2.0, 3.0))
	var b := _plan(Vector2(5.0, 7.0))
	t.close_to(a.gap_to(b), 5.0,
			"two stationary plans use their point-to-point distance", 0.0001)

func _test_one_stationary_side(t: TestRunner) -> void:
	var point := _plan(Vector2(0.0, 5.0))
	var line := _plan(Vector2.ZERO,
			PackedVector2Array([Vector2(-10.0, 0.0), Vector2(10.0, 0.0)]))
	t.close_to(point.gap_to(line), 5.0,
			"a point measures to the interior of the other route", 0.0001)
	t.close_to(line.gap_to(point), 5.0,
			"and reversing the plans gives the same interior distance", 0.0001)

func _test_one_point_paths_are_stationary(t: TestRunner) -> void:
	var one_point := _plan(Vector2(2.0, 3.0), PackedVector2Array([Vector2(100.0, 100.0)]))
	var other := _plan(Vector2(2.0, 7.0))
	t.close_to(one_point.gap_to(other), 4.0,
			"a one-point path uses the plan position, as ends and distance_from do", 0.0001)

func _test_stationary_fast_paths_match_the_symmetric_oracle_in_both_orders(t: TestRunner) -> void:
	var plans: Array[EventPlan] = [
		_plan(Vector2(2.0, 3.0)),
		_plan(Vector2(0.0, 5.0)),
		_plan(Vector2(2.0, 3.0), PackedVector2Array([Vector2(100.0, 100.0)])),
		_plan(Vector2.ZERO,
				PackedVector2Array([Vector2(-10.0, 0.0), Vector2(10.0, 0.0)])),
		_plan(Vector2.ZERO,
				PackedVector2Array([Vector2(0.0, -10.0), Vector2(0.0, 10.0)])),
		_plan(Vector2(50.0, 50.0),
				PackedVector2Array([Vector2(20.0, 20.0), Vector2(20.0, 20.0)])),
	]
	var compared := 0
	for a in plans:
		for b in plans:
			if a.walks().size() >= 2 and b.walks().size() >= 2:
				continue
			compared += 1
			t.check(a.gap_to(b) == _symmetric_gap(a, b),
					"stationary ordered pair %d matches the symmetric result" % compared)
	t.check(compared > 0,
			"the stationary oracle covered both orders and the duplicate zero-length segment")

## **No two events are drawn inside each other**: every two placed events of a day stand at
## least `EventScheduler.EVENT_SPACING_ANY` apart, the one spacing no placement bends. Two of a
## kind may stand closer than `EVENT_SPACING_SAME` where two touching units each drew one; that a
## unit draws one of a row is `tests/test_events_scheduler.gd`'s.
func _test_no_two_events_are_drawn_inside_each_other(t: TestRunner) -> void:
	var pairs := 0
	for day: int in [1, 8, 14]:
		var planned := _planned(day)
		for i in planned.size():
			for j in range(i + 1, planned.size()):
				var a: EventPlan = planned[i]
				var b: EventPlan = planned[j]
				if not a.is_placed() or not b.is_placed():
					continue
				if a.is_ambient():
					continue
				if b.is_ambient():
					continue
				var gap := a.placed_at().distance_to(b.placed_at())
				pairs += 1
				t.check(gap >= EventScheduler.EVENT_SPACING_ANY - 0.5,
						"day %d: '%s' and '%s' are not drawn inside each other (%.0fpx)"
						% [day, a.row_id(), b.row_id(), gap])
	t.check(pairs > 0, "there were placed pairs to measure (%d)" % pairs)
