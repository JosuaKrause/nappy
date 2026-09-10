extends RefCounted
## Focused contracts for the explicit illustrated presentation opt-in.

func run(t) -> void:
	_test_command_line_defaults_to_legacy(t)
	_test_command_line_opt_in(t)
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
