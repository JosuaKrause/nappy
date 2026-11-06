extends RefCounted
## Focused contracts for `readout_requested()` — the release-safe query flag M133, "the readout on
## the live page", adds — and for the two flags parsed beside it. Each is read the same shape: a
## bare command-line flag or a `?name=1` query parameter, without the debug build's own gate.
##
## **The presentation mode is not one of them any more.** A build is whichever mode the atlases
## were baked in (`AtlasTable.baked().bake_mode()`), so there is nothing at runtime left to select: the
## release is always the default PNG bake and `tools/bake-atlases.sh --svg` is the custom local
## one.
##
## `--skip`/`?skip=` (M124, "the desktop half", turned into a phone-readable flag) is parsed the
## same release-safe way but carries a validated word set rather than a bare `1`, and is honoured
## only while `readout_requested()` itself holds — see the tests below for the parsing, the
## refusal of an unknown word, and that gate.
##
## `?seed=` (M138, "a seed on the live page under `?debug=1`") is honoured under the same gate,
## but only for a positive integer.
##
## `live_debug_requested()` (docs/DECISIONS.md, M193, "the live page's ?debug=1 reaches the debug
## flags") opens a second, smaller bundle on top of the two above — `?day=`, `?invincible=1` and
## the rest named at its own doc. It is the build being a debug one `or` the readout being
## requested, a truth table this suite drives.
##
## **Every flag is read the way the game reads it**: `RunConfig.parse()` takes the command line, the
## page's query and the build type as arguments and answers the configuration the game runs on, so
## this suite types the words a player would and reads the field the game reads, and reaches none
## of `DevFlags`' private parsers.

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
	_test_live_debug_requested_is_debug_or_readout(t)
	_test_day_from_query_clamps_the_same_way_as_the_command_line(t)
	_test_day_from_query_is_not_given_when_absent(t)
	_test_web_debug_flag_used_names_the_bundles_own_parameters(t)
	_test_web_debug_flag_used_ignores_debug_alone_and_the_older_bundle(t)
	_test_layers_from_query_is_unchanged_by_m193(t)
	_test_controls_reads_the_url_is_the_live_debug_gate_and_web(t)
	_test_controls_word_from_query_is_unchanged_by_m193(t)
	_test_escape_from_query(t)
	_test_meters_from_query(t)
	_test_day_length_from_query(t)
	_test_ending_from_query(t)
	_test_blackout_from_query(t)
	_test_ground_mode_reads_the_command_line_and_the_open_page(t)
	_test_ground_mode_is_ignored_on_a_release_page_without_debug(t)
	_test_ground_mode_refuses_anything_but_its_three_numbers(t)
	_test_the_physics_tick_is_pinned_to_thirty_with_interpolation_on(t)

## The configuration a release page whose address bar says `query` runs on.
func _page(query: String) -> RunConfig:
	return RunConfig.parse(PackedStringArray(), query, false)

## The configuration a debug build started with `args` and opened on `query` runs on.
func _debug_build(args: Array, query := "") -> RunConfig:
	return RunConfig.parse(PackedStringArray(args), query, true)

## The presentation is decided before the game runs and cannot be moved from inside it. Stated as
## two facts a reader can check rather than as the absence of a flag: the bake names the mode it
## wrote, and the dev-flag table — the one manifest `tools/lib_dev_flags.sh` validates against —
## carries no way to ask for the other one.
func _test_the_bake_alone_decides_the_presentation(t) -> void:
	var mode := AtlasTable.baked().bake_mode()
	t.check(mode == "png" or mode == "svg",
		"the region table names the bake the tree carries (got '%s')" % mode)
	var table := FileAccess.get_file_as_string("res://src/dev/dev_flags.gd")
	t.check(table.contains("DEV_FLAG_TABLE"), "the dev-flag table is where this reads it from")
	t.check(not table.contains("--svg"),
		"no dev flag asks for a presentation the bake did not write")

func _test_readout_requested_true_for_the_documented_query_shapes(t) -> void:
	t.check(_page("?debug=1").readout_requested,
		"?debug=1 requests the readout without a debug-build gate")
	t.check(_page("?x=1&debug=1").readout_requested,
		"the debug parameter is found among other URL parameters")
	t.check(_debug_build(["--debug"]).readout_requested, "--debug requests it on the command line")

func _test_readout_requested_false_for_everything_else(t) -> void:
	t.check(not _page("?debug=0").readout_requested,
		"debug=0 leaves the readout at its ordinary (debug-build) default")
	t.check(not _page("").readout_requested,
		"an absent URL parameter leaves the readout at its ordinary default")
	t.check(not _page("?debugx=1").readout_requested,
		"only the exact documented parameter name requests the readout")

func _test_readout_requested_does_not_move_enabled(t) -> void:
	var page := RunConfig.parse(PackedStringArray(["--spawn", "park", "--walk", "1e"]),
			"?debug=1", false)
	t.check(page.readout_requested and not page.debug_build and page.active_args.is_empty()
			and page.spawn_target == "",
		"the readout's own release-safe flag reaches nothing the debug build gates — no spawn, "
		+ "meter or scripted-input flag moves with it")

## `--skip`'s own words: an unknown word refuses the whole value and an empty one is simply nothing
## to skip. Read through the configuration's `skip_words`, on the open page that gates them.
func _test_skip_words_in_any_order(t) -> void:
	t.check(_page("?debug=1&skip=events,crowd,shadows,motion").skip_words
			== ["events", "crowd", "shadows", "motion"],
		"all four words are each recognised, in the order given")
	t.check(_page("?debug=1&skip=shadows,events").skip_words == ["shadows", "events"],
		"the words may be given in any order")
	t.check(_page("?debug=1&skip=crowd").skip_words == ["crowd"],
		"a single word is its own one-element set")
	t.check(_page("?debug=1&skip=motion").skip_words == ["motion"],
		"motion, the fourth word, is recognised on its own too")

func _test_skip_words_refuses_an_unknown_word(t) -> void:
	t.check(_page("?debug=1&skip=events,bogus").skip_words.is_empty(),
		"an unknown word refuses the whole value rather than the words that did parse")
	t.check(_page("?debug=1&skip=bogus").skip_words.is_empty(),
		"a lone unknown word is refused the same way")

func _test_skip_words_treats_an_empty_value_as_nothing_to_skip(t) -> void:
	t.check(_page("?debug=1&skip=").skip_words.is_empty(),
		"an empty value is nothing to skip — the layers flag's own precedent")

func _test_skip_from_args_and_query_extract_the_raw_value(t) -> void:
	t.check(_debug_build(["--debug", "--skip", "events,crowd"]).skip_words == ["events", "crowd"],
		"the value after --skip is split on commas")
	t.check(_debug_build(["--debug"]).skip_words.is_empty(),
		"no --skip on the command line is nothing to skip")
	t.check(_page("?debug=1&skip=shadows").skip_words == ["shadows"],
		"the skip parameter is read out of the query")
	t.check(_page("?debug=1&seed=1&skip=events&day=2").skip_words == ["events"],
		"the skip parameter is found among other URL parameters")
	t.check(_page("?debug=1").skip_words.is_empty(), "an absent URL parameter is nothing to skip")

## The gate: the skip words are read only while the readout was requested, even on a debug build,
## and the configuration's four booleans carry the same set.
func _test_skip_is_gated_on_the_readout_being_requested(t) -> void:
	var words := PackedStringArray(["--skip", "events,crowd,shadows,motion"])
	var unasked := RunConfig.parse(words, "", true)
	t.check(unasked.skip_words.is_empty() and not unasked.skip_events and not unasked.skip_crowd
			and not unasked.skip_shadows and not unasked.skip_motion,
		"nothing is skipped while the readout was not requested")
	words.append("--debug")
	var asked := RunConfig.parse(words, "", true)
	t.check(asked.skip_events and asked.skip_crowd and asked.skip_shadows and asked.skip_motion,
		"all four are skipped once it was")
	var page := RunConfig.parse(PackedStringArray(), "?debug=1&skip=shadows", false)
	t.check(page.skip_shadows and not page.skip_events,
		"a release page that asked ?debug=1 skips what its own ?skip= names")

## `?seed=`'s positive integer, honoured on a page that asked `?debug=1`.
func _test_seed_from_query_takes_a_valid_seed_under_debug(t) -> void:
	t.check(_page("?debug=1&seed=12345").seed_override == 12345,
		"a valid ?debug=1&seed=12345 yields the seed it names")
	t.check(_page("?seed=12345&debug=1").seed_override == 12345,
		"the seed parameter is found regardless of where it sits among others")

func _test_seed_from_query_ignores_the_seed_without_debug(t) -> void:
	t.check(_page("?seed=12345").seed_override == 0,
		"a release page nobody asked ?debug=1 of never takes a seed, the same as it never skips")
	t.check(_page("").seed_override == 0, "an absent query is not given, the ordinary sentinel")

func _test_seed_from_query_refuses_non_positive_and_malformed_values(t) -> void:
	t.check(_page("?debug=1&seed=0").seed_override == 0, "0 is refused the same as not given")
	t.check(_page("?debug=1&seed=-3").seed_override == 0,
		"a negative seed is refused the same as not given")
	t.check(_page("?debug=1&seed=abc").seed_override == 0,
		"anything that is not an integer is refused the same as not given")
	t.check(_page("?debug=1&seed=").seed_override == 0,
		"an explicit but empty value is refused the same as not given")

## `live_debug_requested()`'s own truth table: a debug build, or a page that asked `?debug=1`.
func _test_live_debug_requested_is_debug_or_readout(t) -> void:
	t.check(_debug_build([]).live_debug,
		"a debug build opens the bundle even without ?debug=1 in the page")
	t.check(_page("?debug=1").live_debug, "a release page carrying ?debug=1 opens the bundle too")
	t.check(_debug_build([], "?debug=1").live_debug, "both together still opens it")
	t.check(not _page("").live_debug, "a release page nobody asked ?debug=1 of opens nothing")

## `?day=`, clamped the same way `--day` itself is rather than refused outright.
func _test_day_from_query_clamps_the_same_way_as_the_command_line(t) -> void:
	t.check(_page("?debug=1&day=9").day_override == 9, "a plain day is read back")
	t.check(_page("?debug=1&day=99").day_override == Tuning.RUN_LENGTH_DAYS,
		"a day past the run's own length clamps into it, the same as --day")
	t.check(_page("?debug=1&day=0").day_override == 1,
		"a day below one clamps up to one, the same as --day")
	t.check(_page("?debug=1&day=abc").day_override == 1,
		"a non-numeric day reads as zero and clamps to one, the same as --day")
	t.check(_page("?seed=1&day=5&debug=1").day_override == 5,
		"the day parameter is found among other URL parameters")
	t.check(_page("?day=5").day_override == 1,
		"a release page nobody asked ?debug=1 of starts on day 1")

func _test_day_from_query_is_not_given_when_absent(t) -> void:
	t.check(_page("").day_override == 1, "an absent query starts on the first day")
	t.check(_page("?debug=1").day_override == 1, "?debug=1 alone opens the bundle but names no day")
	t.check(_debug_build(["--day", "4"], "?debug=1").day_override == 4,
		"an absent ?day= leaves a --day N on the command line alone")
	t.check(_page("?debug=1&day=1").day_override == 1, "?day=1 on an open page is day 1")

## `web_debug_flag_used`: the save's policy (`GameSave._uses_save()`) reads this so a release page's visitor who
## actually typed one of the bundle's parameters never touches the save the page might otherwise
## share with a real player.
func _test_web_debug_flag_used_names_the_bundles_own_parameters(t) -> void:
	for key in ["day", "invincible", "layers", "controls", "escape", "meters", "daylength",
			"ending", "blackout", "groundmode", "framerecord"]:
		t.check(_page("?debug=1&%s=1" % key).web_debug_flag_used,
			"'%s' is one of the bundle's own parameters" % key)

func _test_web_debug_flag_used_ignores_debug_alone_and_the_older_bundle(t) -> void:
	t.check(not _page("").web_debug_flag_used, "an empty query used nothing")
	t.check(not _page("?debug=1").web_debug_flag_used,
		"?debug=1 alone opens the bundle without having used anything in it")
	t.check(not _page("?debug=1&seed=1234&skip=events").web_debug_flag_used,
		"the always-open seed and skip flags are not part of this bundle")
	t.check(not _page("?day=3").web_debug_flag_used,
		"a parameter of the bundle on a page that never opened it is not used")

## `?layers=`: the bundle's gate is `live_debug_requested()`, which the truth table above pins.
func _test_layers_from_query_is_unchanged_by_m193(t) -> void:
	t.check(_page("?debug=1&layers=1,3").layers_override == [1, 3],
		"the layers parameter is read out of the query")
	t.check(_page("?debug=1").layers_override.is_empty(), "an absent parameter is still no layer")
	t.check(_page("?layers=1,3").layers_override.is_empty(),
		"and a page that never opened the bundle reads none")

## `--controls`, then the page's own `?controls=` in the open bundle: the command line wins, and a
## release page answers the query only once it asked `?debug=1`.
func _test_controls_reads_the_url_is_the_live_debug_gate_and_web(t) -> void:
	var none := PackedStringArray()
	t.check(RunConfig.parse(none, "?debug=1&controls=joystick", false).controls_word == "joystick",
		"a release page that asked ?debug=1 reads its own ?controls=")
	t.check(RunConfig.parse(none, "?controls=joystick", false).controls_word == "",
		"a release page that did not reads nothing")
	t.check(RunConfig.parse(PackedStringArray(["--controls", "tap"]), "?controls=joystick", true)
			.controls_word == "tap", "the command line wins over the page")
	t.check(RunConfig.parse(PackedStringArray(["--controls", "tap"]), "", false).controls_word == "",
		"and answers nothing on a release build")

func _test_controls_word_from_query_is_unchanged_by_m193(t) -> void:
	t.check(_page("?debug=1&controls=joystick").controls_word == "joystick",
		"the controls parameter is read out of the query")
	t.check(_page("?debug=1&seed=4&controls=tap").controls_word == "tap",
		"found among other URL parameters")
	t.check(_page("?debug=1").controls_word == "", "an absent parameter is still empty")

## `?escape=1` — the bare boolean M193 opens; `start_escape_at()`'s own optional target word stays
## command-line only (see that function's own doc).
func _test_escape_from_query(t) -> void:
	t.check(_page("?debug=1&escape=1").start_escape, "?escape=1 starts the escape scene")
	t.check(not _page("?debug=1&escape=0").start_escape, "escape=0 starts nothing")
	t.check(not _page("?debug=1").start_escape, "an absent parameter starts nothing")
	t.check(_page("?debug=1&seed=3&escape=1").start_escape, "found among other URL parameters")
	t.check(not _page("?escape=1").start_escape,
		"a page that never opened the bundle starts nothing")

func _test_meters_from_query(t) -> void:
	t.check(_page("?debug=1&meters=10,90").meters_override == Vector2(10.0, 90.0),
		"both numbers are read back")
	t.check(_page("?debug=1&meters=%d,%d" % [Tuning.METER_MAX + 50, -5]).meters_override
			== Vector2(Tuning.METER_MAX, 0.0),
		"each number clamps into range the same as --meters already does")
	t.check(_page("?debug=1").meters_override == Vector2(-1.0, -1.0), "an absent value is not given")
	t.check(_page("?debug=1&meters=10").meters_override == Vector2(-1.0, -1.0),
		"one number refuses the whole value rather than guessing the other")
	t.check(_page("?debug=1&meters=a,b").meters_override == Vector2(-1.0, -1.0),
		"non-numeric words refuse the whole value")

func _test_day_length_from_query(t) -> void:
	t.check(_page("?debug=1&daylength=45").day_length_for(3) == 45.0,
		"a plain length is the day's length")
	t.check(_page("?debug=1&daylength=0.1").day_length_for(3) == 1.0,
		"a length under one second clamps up to one, the same as --day-length")
	t.check(_page("?debug=1").day_length_for(3) == Tuning.day_length(3),
		"an absent value leaves the day its own length")
	t.check(_page("?debug=1&daylength=abc").day_length_for(3) == Tuning.day_length(3),
		"a non-numeric value refuses the flag rather than a garbage length")
	t.check(_page("?debug=1&daylength=-4").day_length_for(3) == Tuning.day_length(3),
		"a non-positive value refuses the flag")

func _test_ending_from_query(t) -> void:
	t.check(_page("?debug=1&ending=bad").ending_override == "bad", "the raw word is read back")
	t.check(_page("?debug=1").ending_override == "", "an absent value is the empty word")
	t.check(_page("?debug=1&seed=2&ending=good").ending_override == "good",
		"found among other URL parameters")

func _test_blackout_from_query(t) -> void:
	t.check(_page("?debug=1&blackout=1").blackout_requested, "?blackout=1 forces the blackout")
	t.check(not _page("?debug=1&blackout=0").blackout_requested, "blackout=0 forces nothing")
	t.check(not _page("?debug=1").blackout_requested, "an absent parameter forces nothing")

## `--ground-mode`/`?groundmode=`: the command line, the page under the bundle's gate, and the
## default of `2` when neither names one.
func _test_ground_mode_reads_the_command_line_and_the_open_page(t) -> void:
	t.check(_debug_build(["--ground-mode", "2"]).ground_mode == 2, "the command line names the mode")
	t.check(_debug_build(["--seed", "4", "--ground-mode", "3"], "?debug=1&groundmode=2").ground_mode
			== 3, "the command line wins over the page")
	t.check(_debug_build([], "?debug=1&groundmode=3").ground_mode == 3,
		"an open page names the mode among other parameters")
	t.check(_debug_build([], "?debug=1").ground_mode == DevFlags.GROUND_MODE_DEFAULT
		and DevFlags.GROUND_MODE_DEFAULT == SceneryGround.Mode.ONE
		and _page("").ground_mode == 2
		and _debug_build(["--seed", "4"]).ground_mode == 2,
		"naming no mode prepares at most one whole region a frame")

func _test_ground_mode_is_ignored_on_a_release_page_without_debug(t) -> void:
	for query in ["?groundmode=3", "?debug=1&groundmode=3"]:
		var expected := 3 if query.contains("debug=1") else 2
		t.check(_page(query).ground_mode == expected,
			"a release page reads %s as mode %d" % [query, expected])

func _test_ground_mode_refuses_anything_but_its_three_numbers(t) -> void:
	for raw in ["1", "2", "3"]:
		t.check(DevFlags.parse_ground_mode(raw) == int(raw), "mode %s is read back" % raw)
	for raw in ["0", "4", "two", ""]:
		t.check(DevFlags.parse_ground_mode(raw) == 2 \
			and DevFlags.parse_ground_mode(raw) == DevFlags.GROUND_MODE_DEFAULT,
			"'%s' refuses the flag rather than choosing a mode" % raw)

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
