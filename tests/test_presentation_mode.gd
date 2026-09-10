extends RefCounted
## Focused contracts for the default PNG presentation and explicit SVG override.

func run(t) -> void:
	_test_command_line_defaults_to_png(t)
	_test_command_line_svg_override(t)
	_test_query_defaults_to_png(t)
	_test_query_svg_override_is_independent_of_debug_build(t)

func _test_command_line_defaults_to_png(t) -> void:
	t.check(not DevFlags._svg_from_args(PackedStringArray()),
		"no command-line modifier leaves PNG graphics selected")
	t.check(not DevFlags._svg_from_args(PackedStringArray(["--svg=1"])),
		"the explicit command-line spelling is a bare --svg flag")

func _test_command_line_svg_override(t) -> void:
	t.check(DevFlags._svg_from_args(PackedStringArray(["--svg"])),
		"--svg selects the authored SVG presentation")

func _test_query_defaults_to_png(t) -> void:
	t.check(not DevFlags._svg_from_query(""),
		"an absent URL parameter leaves PNG graphics selected")
	t.check(not DevFlags._svg_from_query("?svg=0"),
		"svg=0 leaves PNG graphics selected")
	t.check(not DevFlags._svg_from_query("?seed=1&svg=yes"),
		"only the documented URL value selects SVG")

func _test_query_svg_override_is_independent_of_debug_build(t) -> void:
	t.check(DevFlags._svg_from_query("?svg=1"),
		"?svg=1 selects SVG without a debug-build gate")
	t.check(DevFlags._svg_from_query("?seed=1&svg=1&day=2"),
		"the SVG parameter is found among other URL parameters")
