extends "res://tests/test_resistance.gd"
## Independent review: targeted production-arrow regressions from the existing suite.
func run(t) -> void:
	_test_an_arrow_exists_on_every_task_day(t)
	_test_the_arrow_chooses_by_walking_distance_not_straight_line(t)
	_test_the_arrow_switches_as_another_target_becomes_closer(t)
	_test_the_arrow_moves_at_four_tiles_closer_and_not_at_three(t)
	_test_the_arrow_leaves_a_freed_instance_at_once(t)
	_test_a_single_target_arrow_stays_on_its_contact(t)
	if _city != null:
		_city.free()
