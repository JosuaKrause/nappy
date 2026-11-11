@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `RunConfig`, the run's configuration resolved once at boot: what it reads on which build, that
## a resolved one cannot change, what a recipe puts on top of it, and that `main` hands the world,
## the day, the baby and the escape's clock the plain values out of it. Every config here is parsed
## from the words a test would type (`RunConfig.parse()`), never from this process's own command
## line.
##
## **Combined by composition, for this reason:** `RunConfig` is a plain value, and its own rules (what it
## reads on which build, that a resolved one cannot change, what a recipe puts on top) are checked on
## parsed values with nothing built. What the rest holds is that `main` and the city hand each of
## their parts the value it asks for, a guarantee between the configuration and the parts it reaches,
## which only the real composition shows: a boot of `main`, and a built `City` for the one value
## handed through the city's setup. Cities come from the cache (`tests/city_map_cache.gd`).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const UI := preload("res://tests/ui_screens.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_run_config_scratch.json"
const SEED := 4242
## Seconds between two forced rows, short so the first comes within a short walk, and how far the
## walk is sped up (`Engine.time_scale`) and how many game seconds it may take: the wait, one
## retry of a second if the first site is refused (`EventDirector.due()`) and the row's warning
## before it arrives, all under the 11 seconds the day's own first row waits
## (`EventDirector.AHEAD_INTERVAL`).
const FORCED_INTERVAL := 2.0
const FORCED_SCALE := 3.0
const FORCED_WITHIN := 6.0

func run(t) -> void:
	_test_a_release_build_reads_no_command_line_flag(t)
	_test_a_debug_build_reads_them(t)
	_test_a_release_page_opens_the_bundle_only_with_debug(t)
	_test_a_resolved_config_cannot_change(t)
	_test_a_recipe_stands_in_for_the_run_flags(t)
	_test_the_day_and_the_section_lengths(t)
	_test_every_rig_flag_makes_a_rig(t)
	_test_the_title_is_skipped_by_a_rig_or_a_recipe(t)
	await _test_main_hands_the_baby_and_the_city_plain_values(t)
	await _test_the_city_hands_each_value_to_its_part(t)
	await _test_the_forced_row_is_handed_to_the_director(t)
	_test_the_escape_clock_takes_its_length_and_invincible(t)
	await _test_touch_and_web_are_the_runs_answers(t)

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
			and debug.ground_mode == 3 and is_equal_approx(debug.day_length_for(3), 40.0),
			"and every other flag given is read")
	t.check(debug.active_args.size() == 11, "the words themselves are kept, all of them")

## The release-safe bundle answers to a release page only once it asked `?debug=1`; using one of its
## parameters is what keeps that page off the save.
func _test_a_release_page_opens_the_bundle_only_with_debug(t) -> void:
	var none := PackedStringArray()
	var unasked := RunConfig.parse(none, "?day=9&invincible=1", false)
	t.check(unasked.day_override == 1 and not unasked.invincible and not unasked.is_live_debug()
			and not unasked.used_a_web_debug_flag(),
			"a release page that did not ask ?debug=1 reads nothing of the bundle")
	var asked := RunConfig.parse(none, "?debug=1&day=9&invincible=1", false)
	t.check(asked.day_override == 9 and asked.invincible and asked.is_live_debug()
			and asked.used_a_web_debug_flag() and asked.readout_requested,
			"one that did reads the bundle and counts as having used it")
	t.check(asked.page_query_string() == "?debug=1&day=9&invincible=1",
			"and keeps the query it read for the readers that parse their own parameter")
	var readout_only := RunConfig.parse(none, "?debug=1", false)
	t.check(readout_only.is_live_debug() and not readout_only.used_a_web_debug_flag(),
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
	config.debug_build = false
	OS.remove_logger(refused)
	t.check(not config.invincible and config.debug_build,
			"a write after the build changes nothing, the field that holds the gate included")
	t.check(refused.count == 2, "each refused write is reported, not swallowed: %d" % refused.count)
	# The words and the movie flag it was parsed from are what `with_recipe()` (which `main` calls)
	# parses the run from again, so the run it gives is the same run: a refused write to the config
	# is not in it, and what the words and the movie flag said is.
	t.check(not config.with_recipe({}).invincible,
			"the run parsed again from its words does not carry the refused write")
	var movie := RunConfig.parse(_words(["--invincible", "--layers", "1"]), "", true, true)
	var again := movie.with_recipe({})
	t.check(again.recording and again.invincible and again.layers_override == [1]
			and again.active_args == movie.active_args,
			"but does carry the movie flag and every word it was parsed from")
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
	t.check(is_equal_approx(plain.escape_section_length(), RunConfig.FINALE_LENGTH_SECONDS),
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

## A world as loud everywhere as a live row standing on her, for asking whether a baby's meter can
## rise at all: one source of `NOISE` points a second, standing on the world itself.
class LoudWorld extends WorldContext:
	const NOISE := 50.0

	var _noise := ExcitementSource.new(self)

	## Overrides WorldContext.excitement_sources_at.
	func excitement_sources_at(_world_position: Vector2) -> Array:
		return [[_noise, NOISE]]

## Whether `baby`'s excitement rises over a few physics ticks against a `LoudWorld`, her meter
## ticking whether or not the title holds the game paused, and her own world handed back after:
## what `Baby.freeze_excitement()`, which `main` tells her on an invincible run, stops.
func _her_excitement_rises(t, baby: Baby) -> bool:
	var own := baby.world()
	var loud := LoudWorld.new()
	t.add_child(loud)
	var mode := baby.process_mode
	baby.process_mode = Node.PROCESS_MODE_ALWAYS
	baby.set_world(loud)
	var before := baby.excitement_level()
	for _tick in 3:
		await t.get_tree().physics_frame
	var rose := baby.excitement_level() > before
	baby.set_world(own)
	baby.process_mode = mode
	loud.free()
	return rose

## `main` is the one place the configuration is read: the baby and the city it builds are handed
## plain values, and neither reads a flag of its own.
func _test_main_hands_the_baby_and_the_city_plain_values(t) -> void:
	for invincible: bool in [false, true]:
		var words := _words(["--skip", "shadows,motion", "--debug", "--ground-mode", "1",
				"--blackout", "--pelican", "--force", "cyclist", "3"])
		if invincible:
			words.append("--invincible")
		words.append_array(_words(["--no-save", "--no-telemetry"]))
		# The run this boot plays is the test's own, parked in a home the game takes it from.
		var run := RunState.new()
		var home := Boot.home_playing(t, run)
		# The city's flags as it enters the tree: `main` adds it before `build()`, which is where
		# they take effect, so what is read here is what `build()` reads.
		var entered := {}
		var catch := func(node: Node) -> void:
			if node is City:
				var c := node as City
				entered["flags"] = {"ground_mode": c.ground_mode, "skip_shadows": c.skip_shadows,
						"skip_crowd_motion": c.skip_crowd_motion,
						"skip_event_drawing": c.skip_event_drawing,
						"skip_crowd_drawing": c.skip_crowd_drawing,
						"blackout_forced": c.blackout_forced,
						"all_cyclists_pelicans": c.all_cyclists_pelicans,
						"forced_row": c.forced_row, "forced_interval": c.forced_interval,
						"scenery_frame_locked": c.scenery_frame_locked}
		t.get_tree().node_added.connect(catch)
		var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, RunConfig.parse(words, "", true),
				func(main: Node) -> void: main.use_sitting_home(home), false, MapCache.source())
		t.get_tree().node_added.disconnect(catch)
		var baby := Boot.baby(booted.main)
		var rises := false
		if baby:
			rises = await _her_excitement_rises(t, baby)
		t.check(baby != null and rises != invincible,
				"the baby's meter is frozen exactly when the run is invincible (%s)" % invincible)
		var f: Dictionary = entered.get("flags", {})
		t.check(not f.is_empty() and f["ground_mode"] == SceneryGround.Mode.ALL
				and f["skip_shadows"]
				and f["skip_crowd_motion"] and not f["skip_event_drawing"]
				and not f["skip_crowd_drawing"] and f["blackout_forced"] and f["all_cyclists_pelicans"]
				and f["forced_row"] == "cyclist" and is_equal_approx(f["forced_interval"], 3.0)
				and not f["scenery_frame_locked"],
				"the city is handed what the flags chose before it builds")
		booted.free_all()
		home.free()

## What the city is handed reaches the part it belongs to, and the crowd's agents get theirs.
func _test_the_city_hands_each_value_to_its_part(t) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	city.ground_mode = SceneryGround.Mode.STEPPED
	city.scenery_frame_locked = true
	city.skip_shadows = true
	city.skip_event_drawing = true
	city.skip_crowd_drawing = true
	city.skip_crowd_motion = true
	city.blackout_forced = true
	city.all_cyclists_pelicans = true
	t.add_child(city)
	city.build(MapCache.of(SEED))
	# The shadow layer is the scene's own child, found by the name the scene gives it.
	var shadows := city.get_node("BuildingShadows") as BuildingShadows
	t.check(city.scenery_ground.mode == SceneryGround.Mode.STEPPED and city.scenery.frame_locked
			and shadows.skip_draw, "the ground, the scenery and the shadows")
	t.check(city.events.skip_drawing
			and city.events.pelican_rig == EventSpawner.PelicanRig.ALWAYS,
			"the events")
	t.check(city.crowd.skip_motion and city.crowd.skip_agent_drawing, "the crowd")
	# The blackout counts the city as sabotaged: with her far from the station, the lights go out.
	var lot := city.map.tile_rect_to_world(CityMap.blocks_tile_rect(city.map.power_station))
	var she := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	she.add_child(camera)
	t.add_child(she)
	she.set_physics_process(false)
	she.global_position = Vector2(lot.get_center().x, lot.end.y + Blackout.BLACKOUT_DISTANCE + 8.0)
	await PhysicsTicks.pass_ticks(t, 2)
	she.free()
	t.check(not city.signals.powered, "and the blackout, which puts the lights out with no sabotage done")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	city.crowd.start_day(1, rng)
	var agents := city.crowd.agents()
	t.check(not agents.is_empty() and agents[0].skip_draw,
			"and every agent the crowd makes skips its drawing")
	var at: Array[Vector2] = []
	for agent in agents:
		at.append(agent.global_position)
	for i in 30:
		await t.get_tree().physics_frame
	var moved := 0
	for i in agents.size():
		if agents[i].global_position != at[i]:
			moved += 1
	t.check(moved == 0, "and the crowd's physics frames under its skip_motion move none of them (%d moved)" % moved)
	# The control: the same crowd without the flag does move on the same frames, so the frames above
	# really ran the crowd.
	city.crowd.skip_motion = false
	for i in 30:
		await t.get_tree().physics_frame
	moved = 0
	for i in agents.size():
		if agents[i].global_position != at[i]:
			moved += 1
	t.check(moved > 0, "and without the flag the same frames do move them (%d moved)" % moved)
	city.free()

## `--force <row> <seconds>` reaches the director that sites what she meets: a city handed the flag
## sends that row, the first one after the wait the flag names rather than the
## day's own 11 to 26 seconds (`EventDirector.AHEAD_INTERVAL`). Run on the manager's own physics
## ticks with her walking down the street by hand, the way the loose dog's suite does, and read
## off the instances the manager puts in the world: a day's own first row would not come in that
## time, and a flag the director never took up would send no cyclist on day 1.
func _test_the_forced_row_is_handed_to_the_director(t) -> void:
	await PhysicsTicks.settle(t)
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	city.forced_row = "cyclist"
	city.forced_interval = FORCED_INTERVAL
	t.add_child(city)
	city.build(MapCache.of(SEED))
	city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	city.events.use_player(her)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(1), rng, consumed)
	var start := CrowdLanes.arterial_pavement(city.map)
	start.y = city.map.world_size().y * 0.5
	her.global_position = start
	var step := 1.0 / Engine.physics_ticks_per_second * FORCED_SCALE
	var before := city.events.instances().duplicate()
	var seen := {"first": INF}
	var each := func(n: int) -> void:
		her.velocity = Vector2.DOWN * Tuning.WALK_SPEED
		her.global_position += her.velocity * step
		for instance in city.events.instances():
			if instance.def.id == "cyclist" and not before.has(instance) \
					and seen["first"] == INF:
				seen["first"] = n * step
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(FORCED_WITHIN, FORCED_SCALE), each,
			FORCED_SCALE)
	t.check(seen["first"] < INF and seen["first"] >= FORCED_INTERVAL - step,
			"the forced cyclist comes after the wait the flag names, not before (%.1fs)"
					% seen["first"])
	t.check(seen["first"] <= FORCED_WITHIN, "and within the walk, not after the day's own 11s or more")
	her.free()
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
	clock.tick(5.0)
	t.check(is_equal_approx(clock.time_remaining, 25.0), "and stands still when invincible")
	clock.free()

## `--touch` and `--web` are the run's configuration like every other flag, a debug build's alone,
## and reach the two platform questions through it: `TouchInput.available()` and
## `QuitOption.available()` read nothing off the command line, and `main` hands the answers to the
## five screens it builds: the HUD, the day summary, the touch controls, the pause and the title.
## The screens are read the way a player meets the answers, on two real boots (`_the_screens_answer()`).
func _test_touch_and_web_are_the_runs_answers(t) -> void:
	var words := _words(["--touch", "--web"])
	var debug := RunConfig.parse(words, "", true)
	var release := RunConfig.parse(words, "", false)
	t.check(debug.forces_touch() and debug.previews_the_web(), "a debug build reads --touch and --web")
	t.check(not release.forces_touch() and not release.previews_the_web(), "a release build reads neither")
	t.check(TouchInput.available(debug), "--touch answers the touch question yes")
	t.check(not QuitOption.available(debug), "--web answers the quit question as the web does")
	t.check(TouchInput.available(release) == DisplayServer.is_touchscreen_available()
			and QuitOption.available(release),
			"with neither, the platform answers (this test process: no touch, quitting works)")
	# Each answer below is the opposite of what this headless process's platform gives (no touch,
	# quitting works), so each check fails if `main` stops handing that screen its answer.
	await _the_screens_answer(t, true)
	# The same boot with neither flag, which is what the first one is read against: the same
	# presses, answered the platform's way, so a press that missed its screen cannot pass the first.
	await _the_screens_answer(t, false)

## A real `main` booted on `--touch --web` (`flagged`) or on neither, its title, touch controls, day
## summary and pause screen pressed through the viewport: on a touch device a mouse click is not a
## press (the emulated click of a real touch would arrive twice), and where the platform cannot quit
## `Q` is not a key; on the platform this process has, a click is a press and `Q` quits. The quit is
## the one `main` is handed (`use_quit()`) in place of leaving the test runner. The HUD is read off
## where its meters stand, which is the touch layout's alone.
func _the_screens_answer(t, flagged: bool) -> void:
	var label := "on --touch --web" if flagged else "with neither flag"
	var quits := [0]
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var words := ["--seed", str(SEED)]
	if flagged:
		words.append_array(["--touch", "--web"])
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config(words),
			func(main: Node) -> void:
				main.use_sitting_home(home)
				main.use_quit(func() -> void: quits[0] += 1),
			false, MapCache.source())
	var main := booted.main
	var wanted_quits := 0 if flagged else 1

	# The title: Q, a mouse click on its tap button, then a finger on it.
	var title := Boot.title(main)
	UI.push(title, _key(KEY_Q))
	await UI.frames(t)
	t.check(quits[0] == wanted_quits,
			"%s, Q on the title %s" % [label, "does nothing" if flagged else "quits"])
	UI.push(title, UI.mouse_at(UI.centre(UI.button(title, "Tap")), true))
	await UI.frames(t, 4)
	t.check(title.visible == flagged, "%s, a mouse click on the title's tap button %s" % [label,
			"is not a press" if flagged else "starts the run"])
	if flagged:
		await Boot.press_title(t, main)
		t.check(not title.visible, "%s, and a finger on it starts the run" % label)

	# The HUD's meters: top left on a touch device, where the touch controls leave the corner free.
	var meters := Boot.hud(main).get_node("Root/Meters") as Control
	t.check((meters.anchor_top == 0.0 and meters.offset_top == 40.0) == flagged,
			"%s, the HUD's meters stand %s" % [label,
			"top left, the touch layout" if flagged else "bottom left, the desktop layout"])

	# The touch controls: a mouse click far from her heads her that way, on a desktop alone.
	var click := Vector2(900.0, 500.0)
	UI.push(Boot.touch_controls(main), UI.mouse_at(click, true))
	await UI.frames(t)
	t.check(_a_walking_key_is_held() == not flagged, "%s, a mouse click on the screen %s" % [label,
			"walks nowhere" if flagged else "heads her that way"])
	_let_go_of_the_walking_keys(t, Boot.touch_controls(main), click)
	if flagged:
		UI.push(Boot.touch_controls(main), UI.touch_at(click, true))
		await UI.frames(t)
		t.check(_a_walking_key_is_held(), "%s, and a finger there heads her that way" % label)
		_let_go_of_the_walking_keys(t, Boot.touch_controls(main), click)

	# The day summary, raised by a lost day: a mouse click on its continue, then a finger on it.
	var summary := Boot.summary(main)
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(summary.is_showing(), "%s, a lost day raises the summary" % label)
	await UI.frames(t)
	UI.push(summary, UI.mouse_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t, 4)
	t.check(summary.is_showing() == flagged, "%s, a mouse click on the summary %s" % [label,
			"is not a press" if flagged else "goes on"])
	if flagged:
		await Boot.press_continue(t, main)
		t.check(not summary.is_showing(), "%s, and a finger on it goes on" % label)

	# The pause: Esc opens it, then Q, a mouse click and a finger.
	var pause := Boot.pause(main)
	UI.push(pause, _key(KEY_ESCAPE))
	await UI.frames(t)
	t.check(pause.is_open(), "%s, Esc opens the pause" % label)
	UI.push(pause, _key(KEY_Q))
	await UI.frames(t)
	t.check(quits[0] == wanted_quits * 2,
			"%s, Q on the pause %s" % [label, "does nothing" if flagged else "quits"])
	UI.push(pause, UI.mouse_at(Vector2(100.0, 100.0), true))
	await UI.frames(t, 4)
	t.check(pause.is_open() == flagged, "%s, a mouse click on the pause %s" % [label,
			"is not a press" if flagged else "goes on"])
	if flagged:
		UI.push(pause, UI.touch_at(Vector2(100.0, 100.0), true))
		await UI.frames(t, 4)
		t.check(not pause.is_open(), "%s, and a finger on it goes on" % label)

	booted.free_all()
	home.free()

static func _a_walking_key_is_held() -> bool:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if Input.is_action_pressed(action):
			return true
	return false

## Lifts what a press on the controls left held, the way a player does: the release of the press,
## then the keys themselves, since a heading held by a click stands until something stops it.
func _let_go_of_the_walking_keys(t, controls: TouchControls, at: Vector2) -> void:
	UI.push(controls, UI.touch_at(at, false))
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)

static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
