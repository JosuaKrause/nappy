extends RefCounted
## Focused contracts for the explicit illustrated presentation opt-in.

func run(t) -> void:
	_test_command_line_defaults_to_legacy(t)
	_test_command_line_opt_in(t)
	_test_illustrated_zoom_is_bounded(t)
	_test_query_defaults_to_legacy(t)
	_test_query_opt_in_is_independent_of_debug_build(t)

func _test_command_line_defaults_to_legacy(t) -> void:
	t.check(not DevFlags._illustrated_from_args(PackedStringArray()),
		"no command-line modifier selects legacy graphics")
	t.check(not DevFlags._illustrated_from_args(PackedStringArray(["--illustrated=1"])),
		"the explicit command-line spelling is a bare --illustrated flag")

func _test_command_line_opt_in(t) -> void:
	t.check(DevFlags._illustrated_from_args(PackedStringArray(["--illustrated"])),
		"--illustrated opts into the illustrated presentation")

func _test_illustrated_zoom_is_bounded(t) -> void:
	t.check(is_equal_approx(DevFlags._illustrated_zoom_from_args(PackedStringArray()), 2.0),
		"illustrated zoom defaults to the scene's 2x framing")
	t.check(is_equal_approx(DevFlags._illustrated_zoom_from_args(
			PackedStringArray(["--illustrated-zoom", "1"])), 1.0),
		"--illustrated-zoom 1 removes the 2x world zoom")
	t.check(is_equal_approx(DevFlags._illustrated_zoom_from_args(
			PackedStringArray(["--illustrated-zoom", "99"])), 4.0),
		"illustrated zoom clamps large values")
	t.check(is_equal_approx(DevFlags._illustrated_zoom_from_args(
			PackedStringArray(["--illustrated-zoom", "0"])), 2.0),
		"non-positive illustrated zoom falls back to the finite positive default")
	t.check(is_equal_approx(DevFlags._illustrated_zoom_from_args(
			PackedStringArray(["--illustrated-zoom", "oops"])), 2.0),
		"malformed illustrated zoom falls back to the default")

func _test_query_defaults_to_legacy(t) -> void:
	t.check(not DevFlags._illustrated_from_query(""),
		"an absent URL parameter selects legacy graphics")
	t.check(not DevFlags._illustrated_from_query("?illustrated=0"),
		"illustrated=0 keeps the legacy presentation")
	t.check(not DevFlags._illustrated_from_query("?seed=1&illustrated=yes"),
		"only the documented URL value opts in")

func _test_query_opt_in_is_independent_of_debug_build(t) -> void:
	t.check(DevFlags._illustrated_from_query("?illustrated=1"),
		"?illustrated=1 opts in without a debug-build gate")
	t.check(DevFlags._illustrated_from_query("?seed=1&illustrated=1&day=2"),
		"the illustrated parameter is found among other URL parameters")
