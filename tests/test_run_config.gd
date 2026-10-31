extends RefCounted
## `RunConfig`, the run's configuration resolved once at boot: what it reads on which build, that
## a resolved one cannot change, what a recipe puts on top of it, and that `main` hands the world,
## the day, the baby and the escape's clock the plain values out of it. Every config here is parsed
## from the words a test would type (`RunConfig.parse()`), never from this process's own command
## line.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const MAIN_SCRIPT := preload("res://src/main.gd")
const SEED := 4242

func run(t) -> void:
	_test_a_release_build_reads_no_command_line_flag(t)
	_test_a_debug_build_reads_them(t)
	_test_a_release_page_opens_the_bundle_only_with_debug(t)
	_test_a_resolved_config_cannot_change(t)
	_test_a_recipe_stands_in_for_the_run_flags(t)
	_test_the_day_and_the_section_lengths(t)
	_test_every_rig_flag_makes_a_rig(t)
	_test_the_title_is_skipped_by_a_rig_or_a_recipe(t)
	_test_main_hands_the_baby_and_the_city_plain_values(t)
	_test_the_city_hands_each_value_to_its_part(t)
	_test_the_escape_clock_takes_its_length_and_invincible(t)
	_test_touch_and_web_are_the_runs_answers(t)

## The errors raised while it is attached (`OS.add_logger()`).
class RefusedWrites extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String,
			_rationale: String, _editor_notify: bool, _error_type: int,
			_script_backtraces: Array) -> void:
		count += 1

static func _words(words: Array) -> PackedStringArray:
	return PackedStringArray(words)

## A release build answers no command-line flag at all, whatever is typed: a public build cannot be
## told to jump to a day or stop its clock. `--no-telemetry` is the player's own opt-out and is the
## one word read there.
func _test_a_release_build_reads_no_command_line_flag(t) -> void:
	var words := _words(["--day", "5", "--seed", "7", "--invincible", "--layers", "1",
			"--route", "home", "--no-telemetry"])
	var release := RunConfig.parse(words, "", false)
	t.check(release.day_override == 1 and release.seed_override == 0 and not release.invincible
			and release.layers_override.is_empty() and release.route_targets.is_empty()
			and release.active_args.is_empty() and not release.is_rig,
			"a release build reads none of the developer flags")
	t.check(release.no_telemetry, "but does read the player's own --no-telemetry")

func _test_a_debug_build_reads_them(t) -> void:
	var debug := RunConfig.parse(_words(["--day", "99", "--seed", "7", "--invincible",
			"--layers", "1,3", "--ground-mode", "3", "--day-length", "40"]), "", true)
	t.check(debug.day_override == Tuning.RUN_LENGTH_DAYS, "--day is clamped into the run")
	t.check(debug.seed_override == 7 and debug.invincible and debug.layers_override == [1, 3]
			and debug.ground_mode == 3 and is_equal_approx(debug.day_length_override, 40.0),
			"and every other flag given is read")
	t.check(debug.active_args.size() == 11, "the words themselves are kept, all of them")

## The release-safe bundle answers to a release page only once it asked `?debug=1`; using one of its
## parameters is what keeps that page off the save.
func _test_a_release_page_opens_the_bundle_only_with_debug(t) -> void:
	var none := PackedStringArray()
	var unasked := RunConfig.parse(none, "?day=9&invincible=1", false)
	t.check(unasked.day_override == 1 and not unasked.invincible and not unasked.live_debug
			and not unasked.web_debug_flag_used,
			"a release page that did not ask ?debug=1 reads nothing of the bundle")
	var asked := RunConfig.parse(none, "?debug=1&day=9&invincible=1", false)
	t.check(asked.day_override == 9 and asked.invincible and asked.live_debug
			and asked.web_debug_flag_used and asked.readout_requested,
			"one that did reads the bundle and counts as having used it")
	t.check(asked.page_query == "?debug=1&day=9&invincible=1",
			"and keeps the query it read for the readers that parse their own parameter")
	var readout_only := RunConfig.parse(none, "?debug=1", false)
	t.check(readout_only.live_debug and not readout_only.web_debug_flag_used,
			"?debug=1 alone opens the bundle without using any of it")

## A write to a resolved config is refused with a warning and leaves the value as it was, whichever
## field it names, including the ones that hold the gate itself; the arrays are read-only, so no
## reader's edit of one can reach another reader.
func _test_a_resolved_config_cannot_change(t) -> void:
	var config := RunConfig.parse(_words(["--layers", "1", "--route", "home", "--skip", "events",
			"--debug"]), "", true)
	t.check(config.layers_override.is_read_only() and config.route_targets.is_read_only()
			and config.skip_words.is_read_only(),
			"every array a resolved config holds is read-only")
	var refused := RefusedWrites.new()
	OS.add_logger(refused)
	config.invincible = true
	config._open = true
	config._given = PackedStringArray(["--invincible"])
	config._movie = true
	config.debug_build = false
	OS.remove_logger(refused)
	t.check(not config.invincible and config.debug_build
			and not config._movie and not "--invincible" in config._given,
			"a write after the build changes nothing, the fields that hold the gate included")
	config.invincible = true
	t.check(not config.invincible, "and reopening it did not work")
	t.check(refused.count == 5, "each refused write is reported, not swallowed: %d" % refused.count)
	var args := config.active_args
	args.append("--invincible")
	t.check(not "--invincible" in config.active_args,
			"the words are a value: a reader's copy does not change the config's")

## A recipe is one whole authored setup: its seed, day, escape part and parent stand in for the
## flags' own, on a new config, while the one it came from stays what it was.
func _test_a_recipe_stands_in_for_the_run_flags(t) -> void:
	var base := RunConfig.parse(_words(["--recipe", "scene.json", "--seed", "3", "--day", "2"]),
			"", true)
	var recipe := {"seed": 9, "kind": "escape", "setup": {"day": 7, "parent": "father",
			"progression": {"escape_part": "lobby"}}}
	var overlaid := base.with_recipe(recipe)
	t.check(overlaid.seed_override == 9 and overlaid.day_override == 7 and overlaid.start_escape
			and overlaid.start_escape_at == "lobby" and overlaid.parent_override == "father",
			"the recipe's seed, day, escape part and parent are the run's")
	t.check(overlaid.recipe_path == "scene.json",
			"the rest of the run is parsed from the same words")
	t.check(RunConfig.parse(_words(["--seed", "3"]), "", false, false, recipe).seed_override == 0,
			"a release build keeps no recipe, whatever it is handed")
	t.check(base.seed_override == 3 and base.day_override == 2,
			"and the config it was put on is unchanged")

## A day's length is decided in one place and handed on as a number: `--day-length` for every day
## and every escape section when given, else each one's own.
func _test_the_day_and_the_section_lengths(t) -> void:
	var plain := RunConfig.parse(PackedStringArray(), "", true)
	for day in [1, Tuning.RUN_LENGTH_DAYS]:
		t.check(is_equal_approx(plain.day_length_for(day), Tuning.day_length(day)),
				"day %d runs its own length with no flag" % day)
	t.check(is_equal_approx(plain.escape_section_length(), Tuning.FINALE_LENGTH_SECONDS),
			"and an escape section its own")
	var short := RunConfig.parse(_words(["--day-length", "30"]), "", true)
	t.check(is_equal_approx(short.day_length_for(1), 30.0)
			and is_equal_approx(short.escape_section_length(), 30.0),
			"--day-length compresses a day and an escape section alike")
	t.check(is_equal_approx(short.rig_quit_seconds(), DevFlags.rig_quit_seconds_from(-1.0, 30.0)),
			"and a rig with no --after quits a margin past the day it plays")

## One rig list: every flag on it makes the run a rig, `--tap` included, as do a movie recording
## and a scripted recipe; a plain debug run with other flags is a person's.
func _test_every_rig_flag_makes_a_rig(t) -> void:
	for words: Array in [["--screenshot", "x.png"], ["--walk", "1e"], ["--flee"],
			["--press", "pause", "1"], ["--tap", "1", "1"], ["--route", "home"]]:
		t.check(RunConfig.parse(_words(words), "", true).is_rig, "%s is a rig" % [words])
	t.check(RunConfig.parse(PackedStringArray(), "", true, true).is_rig,
			"a movie recording is a rig")
	t.check(RunConfig.parse(_words(["--recipe", "x.json", "--recipe-mode", "scripted"]), "", true)
			.is_rig, "a scripted recipe is a rig")
	t.check(not RunConfig.parse(_words(["--seed", "1", "--day", "9"]), "", true).is_rig,
			"a run that only chooses where it starts is a person's")
	t.check(not RunConfig.parse(_words(["--walk", "1e"]), "", false).is_rig,
			"and nothing is a rig on a release build")

func _test_the_title_is_skipped_by_a_rig_or_a_recipe(t) -> void:
	t.check(not RunConfig.parse(PackedStringArray(), "", true).skips_the_title(),
			"a plain run opens on the title")
	t.check(RunConfig.parse(_words(["--screenshot", "x.png"]), "", true).skips_the_title(),
			"a screenshot rig photographs the day, not the title")
	t.check(not RunConfig.parse(_words(["--screenshot", "x.png", "--title"]), "", true)
			.skips_the_title(), "unless --title asks for the title itself")
	t.check(RunConfig.parse(_words(["--no-title"]), "", true).skips_the_title(),
			"--no-title skips it")
	t.check(RunConfig.parse(_words(["--frame-record", "--after", "5"]), "", true).skips_the_title(),
			"so does a timed frame record")
	t.check(RunConfig.parse(_words(["--recipe", "x.json", "--title"]), "", true).skips_the_title(),
			"and a recipe, which is one authored day, always does")

## `main` is the one place the configuration is read: the baby and the city it builds are handed
## plain values, and neither reads a flag of its own.
func _test_main_hands_the_baby_and_the_city_plain_values(t) -> void:
	for invincible: bool in [false, true]:
		var words := _words(["--skip", "shadows,motion", "--debug", "--ground-mode", "1",
				"--blackout", "--pelican", "--force", "cyclist", "3"])
		if invincible:
			words.append("--invincible")
		var main: Node2D = MAIN_SCRIPT.new()
		main.configure(RunConfig.parse(words, "", true))
		var player: Stroller = main._make_player()
		t.check((player.get_node("Baby") as Baby).excitement_frozen == invincible,
				"the baby's meter is frozen exactly when the run is invincible (%s)" % invincible)
		player.free()
		var city: City = main._new_city()
		t.check(city.ground_mode == SceneryGround.Mode.ALL and city.skip_shadows
				and city.skip_crowd_motion and not city.skip_event_drawing
				and not city.skip_crowd_drawing and city.blackout_forced and city.all_cyclists_pelicans
				and city.forced_row == "cyclist" and is_equal_approx(city.forced_interval, 3.0)
				and not city.scenery_frame_locked,
				"the city is handed what the flags chose before it builds")
		main.free()

## What the city is handed reaches the part it belongs to, and the crowd's agents get theirs.
func _test_the_city_hands_each_value_to_its_part(t) -> void:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	city.ground_mode = SceneryGround.Mode.STEPPED
	city.scenery_frame_locked = true
	city.skip_shadows = true
	city.skip_event_drawing = true
	city.skip_crowd_drawing = true
	city.skip_crowd_motion = true
	city.blackout_forced = true
	city.all_cyclists_pelicans = true
	city.forced_row = "cyclist"
	city.forced_interval = 2.0
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	t.check(city._ground.mode == SceneryGround.Mode.STEPPED and city.scenery.frame_locked
			and city._building_shadows.skip_draw, "the ground, the scenery and the shadows")
	t.check(city.events.skip_drawing
			and city.events.pelican_rig == EventManager.PelicanRig.ALWAYS
			and city.events._director._force_id == "cyclist"
			and is_equal_approx(city.events._director._force_interval, 2.0),
			"the events")
	t.check(city.crowd.skip_motion and city.crowd.skip_agent_drawing and city.blackout.forced,
			"the crowd and the blackout")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.crowd.start_day(1, rng)
	var agents := city.crowd.agents()
	t.check(not agents.is_empty() and agents[0].skip_draw and agents[0].skip_motion,
			"and every agent the crowd makes")
	city.free()

## The escape's clock is a day's: a section's spec carries the section length it is handed, and the
## day's clock runs it and stands still when it is handed `invincible`.
func _test_the_escape_clock_takes_its_length_and_invincible(t) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.BUILDING, 25.0)
	var clock := DayController.new()
	clock.invincible = true
	clock.spec = spec
	t.add_child(clock)
	clock.set_process(false)
	clock.start(spec.length)
	t.check(is_equal_approx(clock.time_remaining, 25.0), "a section runs the length handed in")
	clock._process(5.0)
	t.check(is_equal_approx(clock.time_remaining, 25.0), "and stands still when invincible")
	clock.free()

## `--touch` and `--web` are the run's configuration like every other flag, a debug build's alone,
## and reach the two platform questions through it: `TouchInput.available()` and
## `QuitOption.available()` read nothing off the command line, and `main` hands the answers to the
## five screens it builds: the HUD, the day summary, the touch controls, the pause and the title.
func _test_touch_and_web_are_the_runs_answers(t) -> void:
	var words := _words(["--touch", "--web"])
	var debug := RunConfig.parse(words, "", true)
	var release := RunConfig.parse(words, "", false)
	t.check(debug.touch_forced and debug.web_preview, "a debug build reads --touch and --web")
	t.check(not release.touch_forced and not release.web_preview, "a release build reads neither")
	t.check(TouchInput.available(debug), "--touch answers the touch question yes")
	t.check(not QuitOption.available(debug), "--web answers the quit question as the web does")
	t.check(TouchInput.available(release) == DisplayServer.is_touchscreen_available()
			and QuitOption.available(release),
			"with neither, the platform answers (this test process: no touch, quitting works)")
	# Each answer below is the opposite of what this headless process's platform gives (no touch,
	# quitting works), so each check fails if `main` stops handing that screen its answer.
	var main: Node2D = MAIN_SCRIPT.new()
	main.configure(debug)
	main._build_the_screens()
	t.check(main._touch_available, "main reads the run's touch answer once")
	t.check(main._hud._touch, "and hands it to the HUD")
	t.check(main._summary._touch, "and to the day summary")
	t.check(main._touch_controls._touch, "and to the touch controls")
	t.check(main._pause._touch and not main._pause._can_quit,
			"and hands the pause screen both answers")
	t.check(main._title._touch and not main._title._can_quit,
			"and the title screen both answers")
	main.free()
