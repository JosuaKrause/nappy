extends RefCounted
## Focused contracts for the default PNG presentation, the explicit SVG override, and
## `readout_requested()` — the release-safe query flag M133, "the readout on the live page", adds
## beside it. All three are parsed the same shape: a bare command-line flag or a `?name=1` query
## parameter, read without `DevFlags.enabled()`'s own gate.

func run(t) -> void:
	_test_command_line_defaults_to_png(t)
	_test_command_line_svg_override(t)
	_test_query_defaults_to_png(t)
	_test_query_svg_override_is_independent_of_debug_build(t)
	_test_readout_requested_true_for_the_documented_query_shapes(t)
	_test_readout_requested_false_for_everything_else(t)
	_test_readout_requested_does_not_move_enabled(t)

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

func _test_readout_requested_true_for_the_documented_query_shapes(t) -> void:
	t.check(DevFlags._readout_from_query("?debug=1"),
		"?debug=1 requests the readout without a debug-build gate")
	t.check(DevFlags._readout_from_query("?x=1&debug=1"),
		"the debug parameter is found among other URL parameters")

func _test_readout_requested_false_for_everything_else(t) -> void:
	t.check(not DevFlags._readout_from_query("?debug=0"),
		"debug=0 leaves the readout at its ordinary (debug-build) default")
	t.check(not DevFlags._readout_from_query(""),
		"an absent URL parameter leaves the readout at its ordinary default")
	t.check(not DevFlags._readout_from_query("?debugx=1"),
		"only the exact documented parameter name requests the readout")

func _test_readout_requested_does_not_move_enabled(t) -> void:
	var before := DevFlags.enabled()
	DevFlags._readout_from_query("?debug=1")
	t.check(DevFlags.enabled() == before,
		"the readout's own release-safe flag reaches nothing enabled() gates — no seed, day, "
		+ "spawn, meter, layer or scripted-input flag moves with it")
