extends RefCounted
## Focused contracts for `readout_requested()` — the release-safe query flag M133, "the readout on
## the live page", adds — and for the two flags parsed beside it. Each is read the same shape: a
## bare command-line flag or a `?name=1` query parameter, without `DevFlags.enabled()`'s own gate.
##
## **The presentation mode is not one of them any more.** A build is whichever mode the atlases
## were baked in (`AtlasLibrary.bake_mode()`), so there is nothing at runtime left to select: the
## release is always the default PNG bake and `tools/bake-atlases.sh --svg` is the custom local
## one.
##
## `--skip`/`?skip=` (M124, "the desktop half", turned into a phone-readable flag) is parsed the
## same release-safe way but carries a validated word set rather than a bare `1`, and is honoured
## only while `readout_requested()` itself holds — see the tests below for the parsing, the
## refusal of an unknown word, and that gate.
##
## `?seed=` (M138, "a seed on the live page under `?debug=1`") is honoured under the same gate,
## but only for a positive integer — `DevFlags._seed_from_query()` carries its own `?debug=1`
## check inside it, since the release-shaped case that matters is a single query string with or
## without that parameter, not a runtime `readout_requested()` a test has no web query to drive.

func run(t) -> void:
	_test_the_bake_alone_decides_the_presentation(t)
	_test_readout_requested_true_for_the_documented_query_shapes(t)
	_test_readout_requested_false_for_everything_else(t)
	_test_readout_requested_does_not_move_enabled(t)
	_test_skip_words_in_any_order(t)
	_test_skip_words_refuses_an_unknown_word(t)
	_test_skip_words_treats_an_empty_value_as_nothing_to_skip(t)
	_test_skip_from_args_and_query_extract_the_raw_value(t)
	_test_skip_is_gated_on_the_readout_being_requested(t)
	_test_seed_from_query_takes_a_valid_seed_under_debug(t)
	_test_seed_from_query_ignores_the_seed_without_debug(t)
	_test_seed_from_query_refuses_non_positive_and_malformed_values(t)
	_test_the_physics_tick_is_pinned_to_thirty_with_interpolation_on(t)

## The presentation is decided before the game runs and cannot be moved from inside it. Stated as
## two facts a reader can check rather than as the absence of a flag: the bake names the mode it
## wrote, and the dev-flag table — the one manifest `tools/lib_dev_flags.sh` validates against —
## carries no way to ask for the other one.
func _test_the_bake_alone_decides_the_presentation(t) -> void:
	var mode := AtlasLibrary.bake_mode()
	t.check(mode == "png" or mode == "svg",
		"the region table names the bake the tree carries (got '%s')" % mode)
	var table := FileAccess.get_file_as_string("res://src/dev/dev_flags.gd")
	t.check(table.contains("DEV_FLAG_TABLE"), "the dev-flag table is where this reads it from")
	t.check(not table.contains("--svg"),
		"no dev flag asks for a presentation the bake did not write")

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
	t.check(DevFlags._validate_skip_words("events,crowd,shadows,motion")
			== ["events", "crowd", "shadows", "motion"],
		"all four words are each recognised, in the order given")
	t.check(DevFlags._validate_skip_words("shadows,events") == ["shadows", "events"],
		"the words may be given in any order")
	t.check(DevFlags._validate_skip_words("crowd") == ["crowd"],
		"a single word is its own one-element set")
	t.check(DevFlags._validate_skip_words("motion") == ["motion"],
		"motion, the fourth word, is recognised on its own too")

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
	t.check(not DevFlags.skip_events() and not DevFlags.skip_crowd() and not DevFlags.skip_shadows()
			and not DevFlags.skip_motion(),
		"the four per-word getters carry the same gate")

## `?seed=`'s own query parser (M138, "a seed on the live page under `?debug=1`") — see
## `DevFlags._seed_from_query()`'s own doc for why the `?debug=1` gate is checked inside the same
## pure function rather than split out the way `_skip_from_query()`/`_validate_skip_words()` are.
func _test_seed_from_query_takes_a_valid_seed_under_debug(t) -> void:
	t.check(DevFlags._seed_from_query("?debug=1&seed=12345") == 12345,
		"a valid ?debug=1&seed=12345 yields the seed it names")
	t.check(DevFlags._seed_from_query("?seed=12345&debug=1") == 12345,
		"the seed parameter is found regardless of where it sits among others")

func _test_seed_from_query_ignores_the_seed_without_debug(t) -> void:
	t.check(DevFlags._seed_from_query("?seed=12345") == 0,
		"a release page nobody asked ?debug=1 of never takes a seed, the same as it never skips")
	t.check(DevFlags._seed_from_query("") == 0,
		"an absent query is not given, the ordinary sentinel")

func _test_seed_from_query_refuses_non_positive_and_malformed_values(t) -> void:
	t.check(DevFlags._seed_from_query("?debug=1&seed=0") == 0,
		"0 is refused the same as not given")
	t.check(DevFlags._seed_from_query("?debug=1&seed=-3") == 0,
		"a negative seed is refused the same as not given")
	t.check(DevFlags._seed_from_query("?debug=1&seed=abc") == 0,
		"anything that is not an integer is refused the same as not given")
	t.check(DevFlags._seed_from_query("?debug=1&seed=") == 0,
		"an explicit but empty value is refused the same as not given")

## Pins the engine's own physics rate and interpolation setting so a `project.godot` edit cannot
## drift the tick out from under every test that steps the game world by hand with its own `STEP`
## constant and never reads the engine's rate. Read from the running engine rather than the file,
## so this fails if the setting is present but misspelled or overridden and the engine silently
## kept its default of sixty.
func _test_the_physics_tick_is_pinned_to_thirty_with_interpolation_on(t) -> void:
	t.check(Engine.physics_ticks_per_second == 30,
		"the physics tick runs at thirty a second, not the engine's default of sixty")
	t.check(t.get_tree().physics_interpolation,
		"physics interpolation is on, which is what keeps a physics-tick body's motion smooth "
		+ "at the lower rate")
