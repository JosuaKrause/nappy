extends RefCounted
## Focused checks for the scheduler's route-to-route spacing arithmetic.

func run(t) -> void:
	_test_stationary_pairs(t)
	_test_one_stationary_side(t)
	_test_one_point_paths_are_stationary(t)
	_test_stationary_fast_paths_match_the_symmetric_oracle_in_both_orders(t)

func _plan(at: Vector2, path := PackedVector2Array()) -> EventScheduler.Planned:
	return EventScheduler.Planned.new(EventCatalogue.by_id("busker"), at, path)

func _symmetric_gap(a: EventScheduler.Planned, b: EventScheduler.Planned) -> float:
	var gap := INF
	for point in a.ends():
		gap = minf(gap, b.distance_from(point))
	for point in b.ends():
		gap = minf(gap, a.distance_from(point))
	return gap

func _test_stationary_pairs(t) -> void:
	var a := _plan(Vector2(2.0, 3.0))
	var b := _plan(Vector2(5.0, 7.0))
	t.close_to(EventScheduler._gap_between(a, b), 5.0,
			"two stationary plans use their point-to-point distance", 0.0001)

func _test_one_stationary_side(t) -> void:
	var point := _plan(Vector2(0.0, 5.0))
	var line := _plan(Vector2.ZERO,
			PackedVector2Array([Vector2(-10.0, 0.0), Vector2(10.0, 0.0)]))
	t.close_to(EventScheduler._gap_between(point, line), 5.0,
			"a point measures to the interior of the other route", 0.0001)
	t.close_to(EventScheduler._gap_between(line, point), 5.0,
			"and reversing the plans gives the same interior distance", 0.0001)

func _test_one_point_paths_are_stationary(t) -> void:
	var one_point := _plan(Vector2(2.0, 3.0), PackedVector2Array([Vector2(100.0, 100.0)]))
	var other := _plan(Vector2(2.0, 7.0))
	t.close_to(EventScheduler._gap_between(one_point, other), 4.0,
			"a one-point path uses the plan position, as ends and distance_from do", 0.0001)

func _test_stationary_fast_paths_match_the_symmetric_oracle_in_both_orders(t) -> void:
	var plans: Array[EventScheduler.Planned] = [
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
			if a.path.size() >= 2 and b.path.size() >= 2:
				continue
			compared += 1
			t.check(EventScheduler._gap_between(a, b) == _symmetric_gap(a, b),
					"stationary ordered pair %d matches the symmetric result" % compared)
	t.check(compared > 0,
			"the stationary oracle covered both orders and the duplicate zero-length segment")
