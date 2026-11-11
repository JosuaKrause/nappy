@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## Exercise the actual runtime and argv readers. A tiny child scene isolates exit-status
## assertions without booting Main, constructing another city or quitting the suite's tree.

const AlleyMarks := preload("res://tests/alley_marks.gd")
const EXAMPLE := "res://scene-recipes/power-station-hall.json"
const RecipeErrors := preload("res://tests/recipe_runtime_errors.gd")
const PROBE := """@warning_ignore_start("unsafe_method_access")
extends Node
class World extends Node2D:
	var frames := 0
	func _physics_process(_delta: float) -> void:
		frames += 1
		if Input.is_action_pressed("move_right"):
			position.x += 1
		if frames == 2 and position.x == 1:
			print("ONE_TICK_INPUT_COMPLETED")
## Reads a scene's manifest after the scene's own tick (its priority is the runtime's plus one
## hundred), and says once that a failed observation stopped it before it reported success.
class Watcher extends Node:
	var runtime: SceneRecipeRuntime
	func _ready() -> void:
		process_physics_priority = 200
	func _physics_process(_delta: float) -> void:
		var observed: Array = runtime.manifest.observations
		if observed.is_empty():
			return
		if not runtime.manifest.playback_complete and observed.size() == 1 \
				and not observed[0].passed:
			print("OBSERVATION_STOPPED_BEFORE_SUCCESS")
		set_physics_process(false)
## Where the probe's saves are kept: a scratch file, never the player's, since a policy that broke
## would write here rather than to the player's save.
const _SCRATCH_SAVE := "user://test_scene_recipe_runtime_scratch.json"
## A run of the probe's own, which every runtime below is handed.
var _run := RunState.new()
## A scripted recipe's configuration, which is what the runtime probes below are handed.
func _scripted() -> RunConfig:
	return RunConfig.parse(PackedStringArray(["--recipe", "probe.json", "--recipe-mode", "scripted"]),
			"", true)
func _ready() -> void:
	var config := RunConfig.at_boot()
	var save := GameSave.new(_SCRATCH_SAVE)
	save.configure(config)
	if config.is_rig != config.recipe_scripted:
		save.free()
		get_tree().quit(12)
		return
	# The desktop policy is checked independently of headless's unconditional no-save gate: the same
	# words, parsed for a window, still take no save.
	var windowed := GameSave.new(_SCRATCH_SAVE)
	windowed.configure(RunConfig.parse(OS.get_cmdline_user_args(), "", true, false, {}, false))
	var desktop_saves := windowed.write(_run, false) != GameSave.Result.REFUSED
	windowed.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_SAVE))
	if desktop_saves:
		save.free()
		get_tree().quit(13)
		return
	var saves := save.write(_run, false) != GameSave.Result.REFUSED
	save.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_SAVE))
	if saves:
		get_tree().quit(14)
		return
	if "--probe-camera" in OS.get_cmdline_user_args():
		_probe_the_camera()
		return
	if "--probe-boundary" in OS.get_cmdline_user_args():
		var runtime := SceneRecipeRuntime.new()
		var seconds := 1.0 / Engine.physics_ticks_per_second
		var data := {"name": "one tick input", "playback": {"duration": seconds * 2,
			"walk": str(seconds) + "e1p", "observations": [
			{"tick": 1, "subject": "world", "condition": "near", "at": [1, 0], "distance": 0},
			{"tick": 2, "subject": "world", "condition": "near", "at": [1, 0], "distance": 0}]}}
		runtime.configure({"data": data, "anchors": {}, "manifest": {}}, _scripted(), _run)
		var world := World.new()
		add_child(world)
		add_child(runtime)
		runtime.named.world = world
		runtime.begin()
		return
	if "--probe-observation" not in OS.get_cmdline_user_args():
		print("RECIPE_FLAGS_OK")
		get_tree().quit(0)
		return
	var runtime := SceneRecipeRuntime.new()
	var data := {"name": "failed observation", "playback": {"duration": 1.0 / 60.0,
		"observations": [{"tick": 1, "subject": "missing", "condition": "moving"}]}}
	runtime.configure({"data": data, "anchors": {}, "manifest": {}}, _scripted(), _run)
	add_child(runtime)
	var watcher := Watcher.new()
	watcher.runtime = runtime
	add_child(watcher)
	# Begun as `main` begins it; its own physics tick observes and stops it, and its own quit(1) is
	# the probe's exit status.
	runtime.begin()
## The example recipe installed into a city of the probe's run, begun as `main` begins it with a
## settled start, a fixed camera and a zoom out, and then held for a capture (`prepare_capture()`,
## which `main` hands the screenshot): the settled start leads her by her look-ahead, the fixed
## camera stands over that settled centre by its offset and does not follow her camera, and once the
## capture holds the moment the zoom out stops and the picture stays where it is while idle frames
## pass.
func _probe_the_camera() -> void:
	var loaded := SceneRecipeRuntime.load_recipe("res://scene-recipes/power-station-hall.json",
			PackedStringArray())
	loaded.data.playback = {"duration": 5, "walk": "5p", "settled_camera": true,
		"camera": {"fixed": true, "fixed_offset": [200, 0], "zoom_out": 4, "zoom_delay": 0}}
	var city: City = load("res://scenes/world/city.tscn").instantiate()
	city.run = _run
	add_child(city)
	city.build(loaded.map)
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 1)
	city.start_recipe_day(state, 1, _run.calendar.day_rng())
	var player: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	add_child(player)
	var runtime := SceneRecipeRuntime.new()
	runtime.configure(loaded, _scripted(), _run)
	add_child(runtime)
	var errors := runtime.install(city, player, player.get_node("Baby"),
			DaySpec.for_day(1, Tuning.DAY_LENGTH_SECONDS))
	if not errors.is_empty():
		print(errors)
		get_tree().quit(19)
		return
	var hers: Camera2D = player.get_node("Camera2D")
	hers.make_current()
	runtime.begin()
	var settled := hers.get_screen_center_position()
	var fixed := get_viewport().get_camera_2d()
	hers.position += Vector2(200, 100)
	if hers.offset != Vector2(Stroller.CAMERA_LOOK_AHEAD, 0) or fixed == hers \
			or not settled.is_equal_approx(player.global_position + hers.offset) \
			or not fixed.position.is_equal_approx(settled + Vector2(200, 0)) or fixed.zoom != hers.zoom:
		get_tree().quit(18)
		return
	await get_tree().process_frame
	var zoom: ZoomOutCamera = null
	for child in runtime.get_children():
		if child is ZoomOutCamera:
			zoom = child
	runtime.prepare_capture()
	var shown := get_viewport().get_camera_2d()
	var position_before := shown.position
	var zoom_before := shown.zoom
	for _frame in 3:
		await get_tree().process_frame
	if zoom == null or zoom.is_processing() or not get_tree().paused \
			or get_viewport().get_camera_2d() != shown or shown.position != position_before \
			or shown.zoom != zoom_before:
		get_tree().quit(17)
		return
	print("CAPTURE_CAMERA_FROZEN")
	get_tree().quit(0)
"""

## Where each recipe is written and loaded, and what loading it answers.
var _errors := RecipeErrors.new()

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_test_schema(t)
	_test_hold_is_for_a_straight_departure(t)
	await _test_a_held_departure_places_its_move(t)
	_test_charging_is_for_a_pursuer_that_waits(t)
	_test_relentless_is_for_a_pursuer(t)
	_test_heat_installs_the_heated_row(t)
	await _test_a_task_gone_after_the_read(t)
	_test_arguments(t)
	await _test_inputs(t)
	_test_real_argv_and_failure(t)

## `hold` reproduces a plain walk away, so it is refused for every row whose departure is anything
## else, with a reason that fits the row.
func _test_hold_is_for_a_straight_departure(t: TestRunner) -> void:
	t.check(SceneRecipeRuntime.hold_refusal(EventCatalogue.by_id("charging_dog")) == "",
			"a dog may be held")
	for row: String in ["fire_truck", "delivery_van", "roadblock"]:
		t.check(SceneRecipeRuntime.hold_refusal(EventCatalogue.by_id(row)) != "",
				"%s is refused" % row)
	var flock := ""
	for def: EventDef in EventCatalogue.all():
		if def.flock_size > 0 and def.pursuit == null:
			flock = SceneRecipeRuntime.hold_refusal(def)
	t.check(flock.contains("does not pursue"), "a flock is refused for not pursuing: %s" % flock)
	var message := SceneRecipeRuntime.hold_refusal_message("post", EventCatalogue.by_id("roadblock"))
	t.check(message.contains("post") and message.contains("roadblock") and not message.contains("%s"),
			"the refusal names the event and the row: %s" % message)

## A held event is walked away by the runtime itself (`SceneRecipeRuntime._process()`, which walks
## the events a recipe `hold`s once a drawn frame, `EventInstance.walk_on_by_hand()`): away from
## her at its departure's pace, and moved outside its own step, so its move stands where it now
## does (`MoveProposal.place()`): the crowd's separation pass reads the map's moves (`WorldMap.moves`),
## not the node, and a move left behind would have the crowd step round a dog that is no longer
## there. The dog is a real one, installed by a recipe's `hold` through the runtime's own `install()`
## and `begin()` in a city of its own run's, turned away from her by its own departure
## (`EventInstance.leave_for_a_completed_task()`); the walking is whatever real frames make of it.
func _test_a_held_departure_places_its_move(t: TestRunner) -> void:
	const CITY_SCENE := preload("res://scenes/world/city.tscn")
	const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
	var own_run := RunState.new()
	own_run.start_run(4242)
	own_run.header.day = 3
	var city: City = CITY_SCENE.instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 3)
	city.start_day(state, 3, own_run.calendar.day_rng(3, "closures"))
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	# Where the director would send the dog at her: the lead straight ahead of her, facing south, on
	# ground the dog may stand on; she stands on the first sidewalk tile that gives one.
	var row := EventCatalogue.by_id("charging_dog")
	var lead := Offscreen.lead(Vector2.DOWN, row.chase_speed() + Tuning.WALK_SPEED, row.offscreen_notice)
	var her := Vector2.INF
	for tile in city.map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		var stand := city.map.tile_to_world(tile)
		if city.map.navigator().passable_at(stand + Vector2.DOWN * lead, EventInstance.mover_for(row)) \
				and city.map.navigator().passable_at(stand, EventInstance.mover_for(row)):
			her = stand
			break
	t.check(her != Vector2.INF, "the city has a sidewalk the dog can be sent down at")
	var at := her + Vector2.DOWN * lead
	player.global_position = her
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"setup": {"day": 3, "events": [{"name": "dog", "row": "charging_dog",
			"at": [at.x, at.y], "hold": true}], "player": {"at": [her.x, her.y]}}},
			"manifest": {}, "anchors": {}, "map": city.map}, _recipe_config(false), own_run)
	t.add_child(runtime)
	var errors := runtime.install(city, player, player.get_node("Baby"),
			DaySpec.for_day(3, Tuning.DAY_LENGTH_SECONDS))
	t.check(errors.is_empty(), "the held dog is installed: %s" % [errors])
	runtime.begin()
	var dog: EventInstance = runtime.named.get("dog")
	t.check(dog != null, "the recipe's dog is live")
	if dog != null:
		await t.get_tree().physics_frame
		dog.leave_for_a_completed_task()
		t.check(dog.is_leaving, "the dog is leaving")
		# The runtime takes the dog into its hand on the first drawn frame after it starts leaving;
		# what it has walked since is the runtime's and not the dog's own step before that.
		for _frame in 8:
			if dog.held_by_hand:
				break
			await t.get_tree().process_frame
		t.check(dog.held_by_hand, "the runtime has the dog in its hand")
		var from := dog.position
		for _frame in 8:
			await t.get_tree().process_frame
		var walked := dog.position - from
		t.check(dog.held_by_hand and walked.length() > 0.0 and dog.position.distance_to(
				player.global_position) > from.distance_to(player.global_position),
				"the runtime walks the held dog on, farther from her: %s" % walked)
		var placed := city.map.moves.all().any(func(move: MoveProposal) -> bool:
				return move.from == dog.position and move.to == dog.position)
		t.check(placed, "its move on the map stands where it does, at %s" % dog.position)
		city.events.retire(dog)
	runtime.free()
	player.free()
	city.free()

## `charging` starts a pursuer that waits for her already set on her, so it is refused for a row with
## no radius to skip and for one that sets off beside her on its own clock.
func _test_charging_is_for_a_pursuer_that_waits(t: TestRunner) -> void:
	t.check(SceneRecipeRuntime.charging_refusal(
			EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)) == "",
			"the hunting roadblock's guard may start charging")
	t.check(SceneRecipeRuntime.charging_refusal(EventCatalogue.by_id("roadblock")) != "",
			"the cold roadblock has no radius to skip")
	t.check(SceneRecipeRuntime.charging_refusal(EventCatalogue.by_id("fire_truck")).contains("wait"),
			"a row that does not wait is refused")
	t.check(_errors.errors_of(t, {"setup": {"day": 7, "events": [{"name": "g",
			"row": "roadblock", "at": [0, 0], "charging": 1}]}}).size() > 0, "charging must be a boolean")

## `relentless` keeps a pursuer from giving up because she ran, so a row that does not pursue is refused.
func _test_relentless_is_for_a_pursuer(t: TestRunner) -> void:
	t.check(SceneRecipeRuntime.relentless_refusal(EventCatalogue.by_id("charging_dog")) == "",
			"a pursuer may be kept coming")
	t.check(SceneRecipeRuntime.relentless_refusal(EventCatalogue.by_id("pigeon_flock")).contains("pursue"),
			"a row that does not pursue is refused")
	t.check(_errors.errors_of(t, {"setup": {"day": 7, "events": [{"name": "g",
			"row": "roadblock", "at": [0, 0], "relentless": 1}]}}).size() > 0, "relentless must be a boolean")

func _test_schema(t: TestRunner) -> void:
	var valid := {"setup": {"day": 1, "parent": "mother"},
			"playback": {"duration": 2, "walk": "0.5s0.5E1p", "camera": {"fixed": true},
				"settled_camera": true}}
	t.check(_errors.errors_of(t, valid).is_empty(), "valid optional runtime defaults are accepted")
	var heated := {"setup": {"day": 7, "events": [{"name": "block", "row": "roadblock", "at": [0, 0],
			"heat": EventDef.HEAT_HUNTS_LEVEL}]}}
	t.check(_errors.errors_of(t, heated).is_empty(),
			"an event may name the resistance progress its row is installed at")
	var mixed := {"setup": {"background": {"crowd": true, "uniform_walkers": true},
			"actors": [{"name": "walker", "kind": "walker", "at": [0, 0], "direction": "north"}]}}
	t.check(_errors.errors_of(t, mixed).is_empty(), "uniform background admits explicit walkers")
	mixed.setup.actors[0].kind = "car"
	t.check(not _errors.errors_of(t, mixed).is_empty(), "background still refuses pinned cars")
	mixed.setup.actors[0].kind = "walker"
	mixed.setup.background.uniform_walkers = false
	t.check(not _errors.errors_of(t, mixed).is_empty(), "random background still refuses pinned actors")
	var invalid: Array[Dictionary] = [
		{"setup": {"day": 1.5}},
		{"setup": {"day": 13, "seals": [{"segment": [3, 5, 0], "candidate": "cafe_pair"}],
			"barriers": [{"segment": [3, 5, 0], "end": "b"}]}},
		{"kind": "escape", "setup": {"day": 14, "seals": [{"segment": [5, 4, 0], "candidate": "cafe_pair"}]}},
		{"kind": "escape", "setup": {"day": 14, "gates": [{"segment": [7, 6, 0]}]}},
		{"kind": "escape", "setup": {"day": 14, "barriers": [{"segment": [3, 5, 0], "end": "b"}]}},
		{"kind": "escape", "setup": {"day": 14}, "city": {"closures": [{"segment": [3, 5, 0], "kind": "cordon"}]}},
		{"setup": {"parent": "unknown"}},
		{"setup": {"player": []}},
		{"setup": {"player": {"facing": "northwest"}}},
		{"setup": {"player": {"at": [0]}}},
		{"setup": {"player": {"excitement": INF}}},
		{"setup": {"background": {"crowd": "false"}}},
		{"setup": {"background": {"crowd": true, "crowd_scope": "unknown"}}},
		{"setup": {"background": {"crowd": true, "crowd_scope": "city"}}, "extent": {"scope": "bounded"}},
		{"setup": {"background": {"crowd_scope": "city"}}, "extent": {"scope": "full"}},
		{"setup": {"background": {"events": true}}, "extent": {"scope": "bounded"}},
		{"setup": {"background": {"crowd": true}}, "extent": {"scope": "bounded"}},
		{"setup": {"posters": "not an array"}},
		{"setup": {"posters": [{"at": [0, 0], "kind": "unknown"}]}},
		{"setup": {"day": 1, "posters": [{"at": [0, 0], "kind": "wanted"}]}},
		{"setup": {"progression": {"escape_part": "city"}}},
		{"setup": {"events": "not an array"}},
		{"setup": {"events": [{"name": "event", "row": "unknown", "at": [0, 0]}]}},
		{"setup": {"events": [{"name": "event", "row": "roadblock", "at": [0, 0], "heat": -1}]}},
		{"setup": {"events": [{"name": "event", "row": "roadblock", "at": [0, 0], "heat": 1.5}]}},
		{"setup": {"events": [{"name": "event", "row": "roadblock", "at": [0, 0],
			"heat": Tuning.RESISTANCE_GOAL + 1}]}},
		{"setup": {"actors": [{"name": "actor", "kind": "train", "at": [0, 0], "direction": "east"}]}},
		{"setup": {"actors": [{"name": "player", "kind": "walker", "at": [0, 0], "direction": "east"}]}},
		{"setup": {"actors": [{"name": "actor", "kind": "walker", "at": [0, 0], "direction": "diagonal"}]}},
		{"setup": {"unsupported": true}},
		{"playback": {"walk": "1q"}},
		{"playback": {"duration": "two"}},
		{"playback": {"camera": {"zoom": 0}}},
		{"playback": {"camera": {"fixed": "yes"}}},
		{"playback": {"settled_camera": "false"}},
		{"playback": {"camera": {"fixed_offset": [200, 0]}}},
		{"playback": {"camera": {"fixed": true, "fixed_offset": [200]}}},
		{"playback": {"caption": false}},
		{"playback": {"observations": [{"tick": -1, "subject": "player", "condition": "moving"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "unknown", "condition": "moving"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "player", "condition": "teleporting"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "player", "condition": "near_player",
			"distance": 32, "walkers": 1}]}},
		{"playback": {"unsupported": true}},
	]
	for recipe in invalid:
		t.check(not _errors.errors_of(t, recipe).is_empty(),
				"malformed runtime data is rejected: %s" % [recipe])

## `heat` changes the row a recipe installs, not only what its schema accepts: the same patrol car
## on the same road is the cold patrol with no trigger, and at `EventDef.HEAT_INVESTIGATES_LEVEL` the
## investigating copy that stops for her from `EventDef.HEAT_INVESTIGATE_WITHIN`, the shape a played
## day's dawn gives it (`EventCatalogue.heated()`). Installed through the runtime's own `install()`
## against a real city in a run of its own, and read off the plans the scene's events were started
## on (`EventManager.plans()`), so a field the runtime read and then ignored would fail here.
func _test_heat_installs_the_heated_row(t: TestRunner) -> void:
	const CITY_SCENE := preload("res://scenes/world/city.tscn")
	const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
	var own_run := RunState.new()
	own_run.start_run(4242)
	own_run.header.day = 6
	var city: City = CITY_SCENE.instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, own_run.header.day)
	city.start_day(state, own_run.header.day, own_run.calendar.day_rng(own_run.header.day, "closures"))
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	var baby: Baby = player.get_node("Baby")
	var installed := {}
	for heat: Variant in [null, EventDef.HEAT_INVESTIGATES_LEVEL]:
		var entry := {"name": "car", "row": "police_patrol", "at": [4560, 3984]}
		if heat != null:
			entry["heat"] = heat
		var runtime := SceneRecipeRuntime.new()
		runtime.configure({"data": {"setup": {"day": own_run.header.day, "events": [entry],
				"player": {"at": [4624, 3728]}}}, "manifest": {}, "anchors": {}, "map": city.map},
				_recipe_config(false), own_run)
		var errors := runtime.install(city, player, baby,
				DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
		for plan in city.events.plans():
			if plan.get_meta("recipe_name", "") == "car":
				installed[heat] = plan.def
		t.check(errors.is_empty(), "the patrol car is installed at heat %s: %s" % [heat, errors])
		runtime.free()
	var cold: EventDef = installed.get(null)
	var hot: EventDef = installed.get(EventDef.HEAT_INVESTIGATES_LEVEL)
	t.check(cold != null and not cold.investigates() and is_zero_approx(cold.notice_within()),
			"with no heat the recipe installs the cold patrol, no trigger")
	t.check(hot != null and hot.investigates()
			and is_equal_approx(hot.notice_within(), EventDef.HEAT_INVESTIGATE_WITHIN),
			"at the investigating level it installs the copy that stops for her from %.0fpx"
			% EventDef.HEAT_INVESTIGATE_WITHIN)
	player.free()
	city.free()

## A task gone after she read the mark is one of two things. Placed and then gone, it expired as a
## played day's task can (the thing it rode on finishing, day 10's neighbor home first): the manifest
## records the tick, `task` names nothing from then on, and the setup has not failed. Never placed,
## the director refused it: a failed setup, noticed and recorded in a scene played by hand as well,
## with the director's reasons printed. Each is a free-play scene begun as `main` begins it, in a city
## of a run of its own with a real director, the mark read by her touch (`ContactPoint.complete_now()`),
## and the runtime's own ticks passing; the director is ticked as `main` ticks it.
func _test_a_task_gone_after_the_read(t: TestRunner) -> void:
	var placed := _task_scene(t, 7, {})
	t.check(placed.errors.is_empty(), "the task scene is installed: %s" % [placed.errors])
	var runtime: SceneRecipeRuntime = placed.runtime
	var director: ResistanceDirector = placed.director
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(runtime.named.has("mark") and not runtime.manifest.task.has("read_tick"),
			"before she reads it the mark stands unread and no task is named")
	director.contact().complete_now()
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(runtime.named.has("task") and runtime.manifest.task.get("read_tick") == runtime.tick,
			"the tick after she reads it, the task is named and the read is recorded: %s"
			% [runtime.manifest.task])
	# The thing the task rides on finishes before she gets there.
	var rider := director.rider()
	t.check(rider != null, "the task rides on a live event")
	if rider:
		placed.city.events.retire(rider)
	director.tick(1.0 / Engine.physics_ticks_per_second)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(runtime.manifest.task.get("expired_tick") == runtime.tick and not runtime.named.has("task")
			and not runtime.manifest.get("setup_failed", false),
			"a placed task that is gone expired at the tick it went: %s" % [runtime.manifest.task])
	_free_task_scene(placed)
	# Played by hand, the runtime's own tick is what notices the read, as it does in play. Day 10's
	# neighbor is pinned to a start the day could not draw, which the read refuses.
	var refused := _task_scene(t, 10, {"neighbor": true})
	t.check(refused.errors.is_empty(), "the refused task's scene is installed: %s" % [refused.errors])
	runtime = refused.runtime
	director = refused.director
	director.contact().complete_now()
	var printed := PrintedLines.new()
	OS.add_logger(printed)
	await PhysicsTicks.pass_ticks(t, 1)
	OS.remove_logger(printed)
	t.check(runtime.tick == 1 and runtime.manifest.get("setup_failed", false)
			and not runtime.manifest.task.has("expired_tick"),
			"a task refused at the read fails the setup, noticed by a scene played by hand too")
	var reason := "is not a start the day could draw"
	t.check(Array(printed.lines).any(func(line: String) -> bool: return line.contains(reason)),
			"and the director's reasons are printed: %s" % [printed.lines])
	_free_task_scene(refused)

## Every line printed while it is attached (`OS.add_logger()`), so a test reads what a run prints.
class PrintedLines extends Logger:
	var lines := PackedStringArray()

	func _log_message(message: String, _error: bool) -> void:
		lines.append(message)

## The run configuration a recipe boot hands its runtime: a free-play recipe, or a scripted one.
func _recipe_config(scripted: bool) -> RunConfig:
	return RunConfig.parse(PackedStringArray(["--recipe", "test.json", "--recipe-mode",
			"scripted" if scripted else "free"]), "", true)

## The context city every task scene is built on (`test_scene_recipe_task.gd`'s), the alley mouth
## the day-7 and day-10 scenes start at, and the one the day-10 scene pins its neighbor's start near
## home with: a sidewalk a block from her door, nowhere near the walk the day draws a start from.
const CONTEXT := 1917501
const MOUTH := Vector2i(92, 69)
const MARK := Vector2i(92, 68)
const NEAR_HOME := Vector2i(62, 84)

## A task scene installed and begun as `main` begins one: the context city on `day`, in a run of its
## own with the recipes' seed, a real director handed to the runtime's `install()` as the day director
## hands it, a stroller at the alley mouth, and the free-play runtime begun. `task` is the recipe's
## `setup.task`: a day-7 mark at the alley's mark tile, or (`"neighbor": true`) a day-10 mark with the
## neighbor pinned near home. `errors` are what `install()` returned. `_free_task_scene()` frees it.
func _task_scene(t: TestRunner, day: int, task: Dictionary) -> Dictionary:
	var built := RecipeCityBuilder.build({"version": 1, "name": "task", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	var map: CityMap = built.map
	var own_run := RunState.new()
	own_run.start_run(11)
	own_run.header.day = day
	var state := CityState.new()
	own_run.attempt_spend.city_state = state
	state.begin_day(map.block_plans, day)
	var city: City = load("res://scenes/world/city.tscn").instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(map)
	city.start_recipe_day(state, day, own_run.calendar.day_rng(day, "closures"))
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(map, city.run, city.events, city.streets(), city.fronts(), city, null,
			city.spawn_siting)
	var player: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	t.add_child(player)
	var mark := map.tile_to_world(MARK)
	var pinned := {"mark": [mark.x, mark.y]}
	if task.get("neighbor", false):
		mark = map.tile_to_world(AlleyMarks.mark_tile_of_mouth(map, Vector2i(66, 146)))
		var near := map.tile_to_world(NEAR_HOME)
		pinned = {"mark": [mark.x, mark.y], "neighbor": [near.x, near.y]}
	var start := map.tile_to_world(MOUTH)
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"setup": {"day": day, "task": pinned,
			"player": {"at": [start.x, start.y]}}}, "manifest": {}, "anchors": {}, "map": map},
			_recipe_config(false), own_run)
	t.add_child(runtime)
	var errors := runtime.install(city, player, player.get_node("Baby"),
			DaySpec.for_day(day, Tuning.DAY_LENGTH_SECONDS), director)
	if errors.is_empty():
		runtime.begin()
	return {"errors": errors, "runtime": runtime, "director": director, "city": city,
			"player": player, "run": own_run}

func _free_task_scene(made: Dictionary) -> void:
	for node: Node in [made.runtime, made.player, made.director, made.city]:
		node.free()

func _test_arguments(t: TestRunner) -> void:
	for args: PackedStringArray in [
		PackedStringArray(["--recipe-mode", "unknown"]),
		PackedStringArray(["--seed", "3"]),
		PackedStringArray(["--day", "3"]),
		PackedStringArray(["--walk", "1s"]),
		PackedStringArray(["--press", "pause", "0.1"]),
		PackedStringArray(["--tap", "1", "1"]),
		PackedStringArray(["--recipe-mode"]),
		PackedStringArray(["--screenshot", "out.png"]),
		PackedStringArray(["--recipe-mode", "free", "--after", "1"]),
	]:
		var loaded := SceneRecipeRuntime.load_recipe(EXAMPLE, args)
		t.check(not loaded.errors.is_empty(), "conflicting or unknown recipe arguments fail: %s" % [args])
	var output: Array = []
	var status := OS.execute("bash", PackedStringArray([
		ProjectSettings.globalize_path("res://tools/run.sh"), "--recipe", EXAMPLE,
		"--unknown-recipe-flag"]), output, true)
	t.check(status != 0 and str(output).contains("--unknown-recipe-flag"),
			"run.sh rejects an unknown flag before launching a game")

## A scripted walk presses the real inputs tick by tick on the game's own physics frames: the
## runtime is begun as `main` begins it (`begin()`), real frames pass, and the inputs are read
## while each leg of `1e1N1p` is under way, by the scene's own clock (`elapsed()`, the clock a
## capture is timed off). Removed from the tree, it lets go of what it held. The frames pass under
## `Engine.time_scale`, which leaves the scene's clock in physics ticks.
func _test_inputs(t: TestRunner) -> void:
	var own_run := RunState.new()
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"playback": {"duration": 3, "walk": "1e1N1p"}},
			"anchors": {}, "manifest": {}}, _recipe_config(true), own_run)
	t.add_child(runtime)
	var scale := Engine.time_scale
	Engine.time_scale = 4.0
	runtime.begin()
	await _until_elapsed(t, runtime, 0.5)
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"walking script presses the real right input without running")
	await _until_elapsed(t, runtime, 1.5)
	t.check(Input.is_action_pressed("move_up") and Input.is_action_pressed("run")
			and not Input.is_action_pressed("move_right"), "turning releases the previous direction and presses real run input")
	await _until_elapsed(t, runtime, 2.5)
	t.check(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO
			and not Input.is_action_pressed("run"), "script pause releases movement and running")
	Engine.time_scale = scale
	runtime.free()
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up")
			and not Input.is_action_pressed("run"), "runtime cleanup releases its held input")

## Lets real physics frames pass until the scene's own clock reads `seconds`.
func _until_elapsed(t: TestRunner, runtime: SceneRecipeRuntime, seconds: float) -> void:
	while runtime.elapsed() < seconds:
		await t.get_tree().physics_frame

func _test_real_argv_and_failure(t: TestRunner) -> void:
	var stem := "user://scene_recipe_runtime_probe_%d" % OS.get_process_id()
	var script_path := stem + ".gd"
	var scene_path := stem + ".tscn"
	var script := FileAccess.open(script_path, FileAccess.WRITE)
	script.store_string(PROBE)
	script.close()
	var scene := FileAccess.open(scene_path, FileAccess.WRITE)
	scene.store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n[node name=\"Probe\" type=\"Node\"]\nscript = ExtResource(\"1\")\n" % script_path)
	scene.close()
	for mode in ["free", "scripted", "failure", "boundary", "camera"]:
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
				"--quit-after", "120", scene_path, "--", "--recipe", EXAMPLE,
				"--recipe-mode", "free" if mode == "free" else "scripted"])
		if mode == "failure":
			args.append("--probe-observation")
		elif mode == "boundary":
			args.append("--probe-boundary")
		elif mode == "camera":
			args.append("--probe-camera")
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), args, output, true)
		var text_output := "\n".join(output)
		t.check(not text_output.contains("SCRIPT ERROR") and not text_output.contains("ERROR:"),
				"%s child completes without engine errors: %s" % [mode, text_output])
		if mode == "failure":
			t.check(status == 1 and text_output.contains("OBSERVATION_STOPPED_BEFORE_SUCCESS"),
					"a failed observation at the final tick stops with failure instead of reporting playback success")
		elif mode == "boundary":
			t.check(status == 0 and text_output.contains("ONE_TICK_INPUT_COMPLETED"),
					"one-tick input moves once, observes after the world, and completes the final tick")
		elif mode == "camera":
			t.check(status == 0 and text_output.contains("CAPTURE_CAMERA_FROZEN"),
					"capture freezes camera at the shared physics tick even when idle time advances: %s"
					% text_output)
		else:
			t.check(status == 0 and text_output.contains("RECIPE_FLAGS_OK"),
					"%s recipe reads real argv, keeps the intended input mode and disables saves" % mode)
	DirAccess.remove_absolute(scene_path)
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(script_path + ".uid")
