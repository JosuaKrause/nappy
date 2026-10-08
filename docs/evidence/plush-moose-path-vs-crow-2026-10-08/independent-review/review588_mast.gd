extends "res://tests/test_resistance.gd"
## Independent review: isolate the exact nonarrowed-mast regression, unchanged.
func run(t) -> void:
	_test_day_eleven_answers_at_any_live_mast(t)
	if _city != null:
		_city.free()
