extends RefCounted
## `HeldStreets` (`src/city/held_streets.gd`): which street segments are held and why, and that the
## crowd's carve-outs (a region door, a street bordering the home block) are answered from the
## reasons rather than from lists of their own. Built by hand, with no city.

const A := Vector3i(1, 2, 0)
const B := Vector3i(3, 4, 1)
const C := Vector3i(5, 6, 0)

func run(t: TestRunner) -> void:
	_test_a_held_segment_is_held_for_the_reasons_it_was_given(t)
	_test_only_a_door_or_a_home_street_is_crossable(t)
	_test_a_copy_and_a_clear_are_independent(t)

func _test_a_held_segment_is_held_for_the_reasons_it_was_given(t: TestRunner) -> void:
	var held := HeldStreets.new()
	held.hold(A, HeldStreets.Why.WALL)
	held.hold(A, HeldStreets.Why.HOME)
	held.hold(B, HeldStreets.Why.SEAL)
	t.check(held.has(A) and held.has(B) and not held.has(C), "a segment is held once given a reason")
	t.check(held.is_for(A, HeldStreets.Why.WALL) and held.is_for(A, HeldStreets.Why.HOME),
			"a segment held twice answers both reasons")
	t.check(not held.is_for(A, HeldStreets.Why.SEAL) and not held.is_for(C, HeldStreets.Why.SEAL),
			"and no reason it was not given")
	t.check(held.size() == 2 and held.keys().size() == 2, "two segments are held")

func _test_only_a_door_or_a_home_street_is_crossable(t: TestRunner) -> void:
	var held := HeldStreets.new()
	held.hold(A, HeldStreets.Why.DOOR)
	held.hold(B, HeldStreets.Why.HOME)
	held.hold(C, HeldStreets.Why.CLOSURE)
	t.check(held.is_crossable(A) and held.is_crossable(B), "a door and a home street are crossable")
	t.check(not held.is_crossable(C), "a closure is not")
	held.hold(C, HeldStreets.Why.HOME)
	t.check(held.is_crossable(C), "a segment that is also a home street is")

func _test_a_copy_and_a_clear_are_independent(t: TestRunner) -> void:
	var held := HeldStreets.new()
	held.hold(A, HeldStreets.Why.SEAL)
	var twin := held.duplicate()
	held.clear()
	t.check(held.size() == 0 and twin.has(A), "clearing the original leaves the copy as it was")
	twin.hold(B, HeldStreets.Why.WALL)
	t.check(not held.has(B), "and holding on the copy leaves the original alone")
