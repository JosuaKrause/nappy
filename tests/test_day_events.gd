extends RefCounted
## `DayEvents`, the day's planned rows read through one object: which calm areas each row spoils
## and whether one is a pursuit, kept in step with every row added. The one place that
## logic is checked, on plans built by hand with known answers; every other check that needs these
## facts asks the object a day returns.
##
## The calm areas are a stand-in (`FakeCalmAreas`) holding two areas of a real city, copied from
## what `CalmAreas.of()` answers for seed 4242: no city is built. The rows are the catalogue's own.

## A court of 4x4 tiles, and a park of 10x10, as `CalmAreas.of()` answers them for seed 4242.
const COURT := Vector2i(1, 4)
const COURT_GROUND := Rect2(704, 2016, 128, 128)
const PARK := Vector2i(1, 6)
const PARK_GROUND := Rect2(928, 3040, 320, 320)

func run(t: TestRunner) -> void:
	_test_a_row_spoils_the_ground_its_field_reaches(t)
	_test_a_playground_a_scar_and_a_row_not_yet_placed_spoil_nothing(t)
	_test_a_pursuit_is_counted_while_it_is_planned(t)
	_test_the_standing_bodies_are_not_the_plans_rows(t)

func _calm() -> FakeCalmAreas:
	return FakeCalmAreas.new() \
			.set_area(COURT, COURT_GROUND) \
			.set_area(PARK, PARK_GROUND)

func _row(id: String, at: Vector2) -> EventPlan:
	return EventPlan.new(EventCatalogue.by_id(id), at)

## Just above the court's top edge by `gap` pixels, on its middle.
func _above_the_court(gap: float) -> Vector2:
	return Vector2(COURT_GROUND.get_center().x, COURT_GROUND.position.y - gap)

func _test_a_row_spoils_the_ground_its_field_reaches(t: TestRunner) -> void:
	var events := DayEvents.over(_calm())
	var reach := EventCatalogue.by_id("dog_walker").field_reach()
	var near := _row("dog_walker", _above_the_court(reach - 10.0))
	var far := _row("dog_walker", _above_the_court(reach + 10.0))
	events.add(near)
	events.add(far)
	t.check(events.is_spoiled(COURT) and events.spoilers_of(COURT) == ([near] as Array[EventPlan]),
			"a row whose field reaches the court spoils it, and one just past its reach does not")
	t.check(not events.is_spoiled(PARK), "and the park it reaches neither of them")
	var inside := _row("busker", PARK_GROUND.get_center())
	events.add(inside)
	t.check(events.spoilers_of(PARK) == ([inside] as Array[EventPlan]),
			"a row standing on the park spoils the park")
	t.check(events.placements() == ([near, far, inside] as Array[EventPlan])
			and events.size() == 3, "and every row is in the plan, in the order placed")

func _test_a_playground_a_scar_and_a_row_not_yet_placed_spoil_nothing(t: TestRunner) -> void:
	var events := DayEvents.over(_calm())
	var playground := _row("playground", COURT_GROUND.get_center())
	var scar := _row("burnt_shell", COURT_GROUND.get_center())
	scar.permanent = true
	var unplaced := _row("dog_walker", Vector2.INF)
	events.add_all([playground, scar, unplaced] as Array[EventPlan])
	t.check(not events.is_spoiled(COURT),
			"a playground, a scar the run left and a row not yet placed leave the court clean")
	var today := _row("burnt_shell", COURT_GROUND.get_center())
	events.add(today)
	t.check(events.spoilers_of(COURT) == ([today] as Array[EventPlan]),
			"while the same row placed today, not the run's, spoils it")

func _test_a_pursuit_is_counted_while_it_is_planned(t: TestRunner) -> void:
	var events := DayEvents.over(_calm())
	events.add(_row("dog_walker", Vector2(100, 100)))
	t.check(not events.has_a_pursuit(), "a day of dog walkers has no pursuit")
	var dog := _row("charging_dog", Vector2.INF)
	events.add(dog)
	t.check(events.has_a_pursuit(), "a charging dog owed to her walk is one")

func _test_the_standing_bodies_are_not_the_plans_rows(t: TestRunner) -> void:
	var seal := _row("barricade", PARK_GROUND.get_center())
	var standing: Array[EventPlan] = [seal]
	var events := DayEvents.over(_calm(), standing)
	t.check(events.standing() == standing, "a seal handed in stands for the plan")
	t.check(events.placements().is_empty() and not events.is_spoiled(PARK),
			"but it is not one of the day's rows, and it spoils no park")
	events.placements().append(_row("dog_walker", Vector2(1, 1)))
	t.check(events.size() == 0, "and what a question answers is a copy the plan does not share")
