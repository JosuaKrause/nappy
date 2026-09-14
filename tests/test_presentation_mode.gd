extends RefCounted
## Focused contracts for the default PNG presentation, the explicit SVG override, and
## `readout_requested()` — the release-safe query flag M133, "the readout on the live page", adds
## beside it. All three are parsed the same shape: a bare command-line flag or a `?name=1` query
## parameter, read without `DevFlags.enabled()`'s own gate.
##
## `--skip`/`?skip=` (M124, "the desktop half", turned into a phone-readable flag) is parsed the
## same release-safe way but carries a validated word set rather than a bare `1`, and is honoured
## only while `readout_requested()` itself holds — see the tests below for the parsing, the
## refusal of an unknown word, and that gate.

func run(t) -> void:
	_test_command_line_defaults_to_png(t)
	_test_command_line_svg_override(t)
	_test_query_defaults_to_png(t)
	_test_query_svg_override_is_independent_of_debug_build(t)
	_test_readout_requested_true_for_the_documented_query_shapes(t)
	_test_readout_requested_false_for_everything_else(t)
	_test_readout_requested_does_not_move_enabled(t)
	_test_skip_words_in_any_order(t)
	_test_skip_words_refuses_an_unknown_word(t)
	_test_skip_words_treats_an_empty_value_as_nothing_to_skip(t)
	_test_skip_from_args_and_query_extract_the_raw_value(t)
	_test_skip_is_gated_on_the_readout_being_requested(t)

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

## `--skip`'s own words — see `DevFlags._validate_skip_words()`'s own doc for why an unknown word
## refuses the whole value and an empty one is simply nothing to skip.
func _test_skip_words_in_any_order(t) -> void:
	t.check(DevFlags._validate_skip_words("events,crowd,shadows") == ["events", "crowd", "shadows"],
		"all three words are each recognised, in the order given")
	t.check(DevFlags._validate_skip_words("shadows,events") == ["shadows", "events"],
		"the words may be given in any order")
	t.check(DevFlags._validate_skip_words("crowd") == ["crowd"],
		"a single word is its own one-element set")

func _test_skip_words_refuses_an_unknown_word(t) -> void:
	t.check(DevFlags._validate_skip_words("events,bogus").is_empty(),
		"an unknown word refuses the whole value rather than the words that did parse")
	t.check(DevFlags._validate_skip_words("bogus").is_empty(),
		"a lone unknown word is refused the same way")

func _test_skip_words_treats_an_empty_value_as_nothing_to_skip(t) -> void:
	t.check(DevFlags._validate_skip_words("").is_empty(),
		"an empty value is nothing to skip — parse_layers()'s own precedent for --layers")

func _test_skip_from_args_and_query_extract_the_raw_value(t) -> void:
	t.check(DevFlags._skip_from_args(PackedStringArray(["--skip", "events,crowd"])) == "events,crowd",
		"the value after --skip is extracted whole, before it is split on commas")
	t.check(DevFlags._skip_from_args(PackedStringArray()) == "",
		"no --skip on the command line is an empty raw value")
	t.check(DevFlags._skip_from_query("?skip=shadows") == "shadows",
		"the skip parameter is read out of the query the same shape svg and debug are")
	t.check(DevFlags._skip_from_query("?seed=1&skip=events&day=2") == "events",
		"the skip parameter is found among other URL parameters")
	t.check(DevFlags._skip_from_query("") == "",
		"an absent URL parameter is an empty raw value")

## The gate: `skip_words()` and the three per-word getters read `readout_requested()` before
## parsing anything, and an ordinary test run never asks for the readout (no `--debug` reaches
## this process, and there is no web query to read outside a Web export), so all four answer
## nothing skipped regardless of whatever `--skip` this process's own command line might carry.
func _test_skip_is_gated_on_the_readout_being_requested(t) -> void:
	t.check(DevFlags.skip_words().is_empty(),
		"skip_words() answers nothing skipped while the readout was not requested")
	t.check(not DevFlags.skip_events() and not DevFlags.skip_crowd() and not DevFlags.skip_shadows(),
		"the three per-word getters carry the same gate")
