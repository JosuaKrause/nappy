class_name SceneRecipeRuntime
extends Node
## One saved setup feeds scripted scenes, headless assertions and frame-locked recording. Playback
## starts only after construction and scenery preparation; observations use the game's physics ticks.

const DIRECTIONS := {"north": Vector2.UP, "south": Vector2.DOWN,
		"east": Vector2.RIGHT, "west": Vector2.LEFT}
const OWNED_FLAGS := ["--seed", "--day", "--spawn", "--parent", "--meters", "--walk",
		"--flee", "--route", "--force", "--follow", "--zoom", "--zoom-out", "--caption",
		"--title-card", "--start-escape", "--blackout", "--overview", "--day-length",
		"--press", "--tap", "--ending", "--quit-when-still", "--skip"]

var data: Dictionary = {}
var built: Dictionary = {}
var manifest: Dictionary = {}
var named: Dictionary = {}
var scripted := false
var tick := 0
var _player: Stroller
var _city: City
var _steps: Array[Dictionary] = []
var _observations: Array = []
var _duration_ticks := 0
var _active := false
var _capture_tick := -1
var _zoom: ZoomOutCamera
var _last_positions: Dictionary = {}

static func load_recipe(path: String, args: PackedStringArray) -> Dictionary:
	var loaded := SceneRecipe.load_file(path)
	if not loaded.errors.is_empty():
		return loaded
	var recipe: Dictionary = loaded.data
	var errors := validate_runtime(recipe)
	for flag in OWNED_FLAGS:
		if flag in args:
			errors.append("arguments: %s conflicts with recipe-owned setup/playback" % flag)
	var mode := "scripted"
	var index := args.find("--recipe-mode")
	if index >= 0 and (index + 1 >= args.size() or args[index + 1].begins_with("--")):
		errors.append("--recipe-mode requires scripted")
	if index >= 0 and index + 1 < args.size():
		mode = args[index + 1]
	if mode != "scripted":
		errors.append("recipes support scripted launch only in this slice")
	if mode == "free" and ("--walk" in args or "--after" in args or "--screenshot" in args):
		errors.append("free play cannot have scripted input or a capture deadline")
	if not errors.is_empty():
		return {"data": recipe, "errors": errors}
	var result := RecipeCityBuilder.build(recipe)
	result.data = recipe
	return result

static func validate_runtime(recipe: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var setup: Dictionary = recipe.get("setup", {})
	var playback: Dictionary = recipe.get("playback", {})
	_keys(setup, ["day", "parent", "player", "background", "progression", "events", "actors",
			"signal_time", "column", "tutorial_complete"], "setup", errors)
	if not setup.get("tutorial_complete", false) is bool:
		errors.append("setup.tutorial_complete must be boolean")
	_number(setup.get("day", 1), "setup.day", 1, 14, errors, true)
	if not setup.get("parent", "mother") in ["mother", "father"]:
		errors.append("setup.parent must be mother or father")
	for key in ["player", "background", "progression"]:
		if not setup.get(key, {}) is Dictionary:
			errors.append("setup.%s must be an object" % key)
	if not errors.is_empty():
		return errors
	var player: Dictionary = setup.get("player", {})
	_keys(player, ["at", "facing", "excitement", "sleep"], "setup.player", errors)
	_position(player.get("at", "doorstep"), "setup.player.at", errors)
	if not DIRECTIONS.has(player.get("facing", "south")):
		errors.append("setup.player.facing must name a cardinal direction")
	for key in ["excitement", "sleep"]:
		_number(player.get(key, 0), "setup.player." + key, 0, 100, errors)
	var background: Dictionary = setup.get("background", {})
	_keys(background, ["events", "crowd", "crowd_scope"], "setup.background", errors)
	for key in ["events", "crowd"]:
		if not background.get(key, false) is bool:
			errors.append("setup.background.%s must be boolean" % key)
	if not background.get("crowd_scope", "player") in ["player", "city"]:
		errors.append("setup.background.crowd_scope must be player or city")
	if background.get("crowd_scope", "player") == "city" and (
			not background.get("crowd", false) or recipe.get("extent", {}).get("scope", "") != "full"):
		errors.append("setup.background.crowd_scope city requires crowd and full extent")
	if recipe.get("extent", {}).get("scope", "") == "bounded" and (
			background.get("events", false) or background.get("crowd", false)):
		errors.append("bounded scenes require authored actors/events; random background activity needs full extent")
	var progression: Dictionary = setup.get("progression", {})
	_keys(progression, ["blackout", "escape_part"], "setup.progression", errors)
	if not progression.get("blackout", false) is bool:
		errors.append("setup.progression.blackout must be boolean")
	if recipe.get("kind", "city") == "escape":
		if progression.get("escape_part", "city") != "city":
			errors.append("setup.progression.escape_part: recipes currently support the real city escape")
		if int(setup.get("day", 1)) != Tuning.RUN_LENGTH_DAYS:
			errors.append("setup.day: the escape requires the final day's progression")
	elif progression.has("escape_part"):
		errors.append("setup.progression.escape_part requires kind escape")
	_number(setup.get("signal_time", 0), "setup.signal_time", 0, 86400, errors)
	var names := {"player": true}
	if setup.has("column"):
		if not setup.column is Dictionary:
			errors.append("setup.column must be an object")
		else:
			_keys(setup.column, ["at", "direction"], "setup.column", errors)
			_position(setup.column.get("at"), "setup.column.at", errors)
			if not setup.column.get("direction") in ["north", "south"]:
				errors.append("setup.column.direction must be north or south")
			if int(setup.get("day", 1)) != ResistanceHappenings.COLUMN_DAY \
					or recipe.get("kind", "city") != "city" \
					or recipe.get("extent", {}).get("scope", "") != "full":
				errors.append("setup.column requires day 13 and a full city scene")
		for i in Tuning.COLUMN_TRUCKS:
			names["truck_%d" % (i + 1)] = true
	for collection in ["events", "actors"]:
		if not setup.get(collection, []) is Array:
			errors.append("setup.%s must be an array" % collection)
			continue
		for entry: Variant in setup.get(collection, []):
			var where: String = "setup." + collection
			if not entry is Dictionary:
				errors.append(where + " entries must be objects")
				continue
			_keys(entry, ["name", "row", "at", "path", "age", "route_seed"] if collection == "events"
					else ["name", "kind", "at", "direction", "speed"], where, errors)
			var label: Variant = entry.get("name")
			if not label is String or str(label).is_empty() or names.has(label):
				errors.append(where + ".name must be a unique nonempty name")
			else:
				names[label] = true
			_position(entry.get("at"), where + ".at", errors)
			if collection == "events":
				if not entry.get("row") is String or not EventCatalogue.by_id(str(entry.get("row", ""))):
					errors.append(where + ".row is an unknown catalogue identifier")
				_number(entry.get("age", 0), where + ".age", 0, 3600, errors)
				_number(entry.get("route_seed", 1), where + ".route_seed", 0, 2147483647, errors, true)
				if not entry.get("path", []) is Array:
					errors.append(where + ".path must be an array")
				else:
					for point: Variant in entry.get("path", []):
						_position(point, where + ".path", errors)
			else:
				if not entry.get("kind") in ["walker", "car"]:
					errors.append(where + ".kind must be walker or car")
				if not DIRECTIONS.has(entry.get("direction")):
					errors.append(where + ".direction must be cardinal")
				if entry.has("speed"):
					_number(entry.speed, where + ".speed", 0, 1000, errors)
	if not errors.is_empty():
		return errors
	if background.get("events", false) and not setup.get("events", []).is_empty():
		errors.append("setup.background.events cannot be combined with pinned events")
	if setup.has("column") and (background.get("events", false) or not setup.get("events", []).is_empty()):
		errors.append("setup.column owns the scene's event activity")
	if background.get("crowd", false) and not setup.get("actors", []).is_empty():
		errors.append("setup.background.crowd cannot be combined with pinned actors")
	_keys(playback, ["walk", "duration", "capture_at", "camera", "caption", "title", "observations"],
			"playback", errors)
	_number(playback.get("duration", 5), "playback.duration", 1.0 / 60.0, 240, errors)
	if not errors.is_empty():
		return errors
	_number(playback.get("capture_at", 0.5), "playback.capture_at", 0,
			float(playback.get("duration", 5)) - 1.0 / 60.0, errors)
	var walk: Variant = playback.get("walk", "")
	if not walk is String or (not str(walk).is_empty() and AutoScreenshot._parse_script(walk).is_empty()):
		errors.append("playback.walk is not a valid timed movement script")
	for key in ["caption", "title"]:
		if not playback.get(key, "") is String:
			errors.append("playback.%s must be text" % key)
	if not playback.get("camera", {}) is Dictionary:
		errors.append("playback.camera must be an object")
	else:
		var camera: Dictionary = playback.get("camera", {})
		_keys(camera, ["zoom", "zoom_out", "zoom_delay"], "playback.camera", errors)
		for key in camera:
			_number(camera[key], "playback.camera." + key,
					0 if key == "zoom_delay" else 0.001, 240, errors)
	if not playback.get("observations", []) is Array:
		errors.append("playback.observations must be an array")
	else:
		for check: Variant in playback.get("observations", []):
			if not check is Dictionary:
				errors.append("playback.observations entries must be objects")
				continue
			_keys(check, ["tick", "subject", "condition", "at", "distance"], "observation", errors)
			_number(check.get("tick"), "observation.tick", 0,
					float(playback.get("duration", 5)) * Engine.physics_ticks_per_second, errors, true)
			if not names.has(check.get("subject")):
				errors.append("observation.subject is not a named actor")
			if not check.get("condition") in ["visible", "moving", "running", "carrying", "pursuing", "near"]:
				errors.append("observation.condition is unsupported")
			if check.get("condition") == "near":
				_position(check.get("at"), "observation.at", errors)
				_number(check.get("distance"), "observation.distance", 0, 10000, errors)
	return errors

static func _keys(object: Dictionary, allowed: Array, where: String, errors: Array[String]) -> void:
	for key: Variant in object:
		if not key in allowed:
			errors.append("%s.%s is unknown" % [where, key])

static func _number(value: Variant, where: String, low: float, high: float,
		errors: Array[String], integer := false) -> void:
	if not (value is int or value is float):
		errors.append(where + " must be numeric")
	elif not is_finite(float(value)) or float(value) < low or float(value) > high \
			or (integer and float(value) != floorf(float(value))):
		errors.append("%s must be %sbetween %s and %s" % [where, "an integer " if integer else "", low, high])

static func _position(value: Variant, where: String, errors: Array[String]) -> void:
	if value is String and not str(value).is_empty():
		return
	if not value is Array or value.size() != 2:
		errors.append(where + " must name an anchor or be [world_x, world_y]")
		return
	_number(value[0], where + "[0]", -1000000, 1000000, errors)
	_number(value[1], where + "[1]", -1000000, 1000000, errors)

func configure(result: Dictionary, scripted_mode: bool) -> void:
	data = result.data
	built = result
	manifest = result.manifest.duplicate(true)
	scripted = scripted_mode
	manifest["recipe"] = data.get("name", "")
	manifest["recipe_sha256"] = JSON.stringify(data, "", true).sha256_text()
	manifest["engine"] = Engine.get_version_info().string
	manifest["physics_ticks_per_second"] = Engine.physics_ticks_per_second
	manifest["playback_complete"] = false
	manifest["observations"] = []
	manifest["setup"] = data.get("setup", {}).duplicate(true)
	manifest["anchors"] = {}
	for label: String in result.anchors:
		var at: Vector2 = result.anchors[label]
		manifest.anchors[label] = [at.x, at.y]
	_steps = AutoScreenshot._parse_script(str(data.get("playback", {}).get("walk", "")))
	_observations = data.get("playback", {}).get("observations", [])
	_duration_ticks = roundi(float(data.get("playback", {}).get("duration", 5)) * Engine.physics_ticks_per_second)
	if "--screenshot" in DevFlags.active_args():
		_capture_tick = ceili(DevFlags._word_after("--after").to_float() * Engine.physics_ticks_per_second - 0.00001)
	# begin() supplies the first input; subsequent inputs are queued after the world's tick.
	# Observations and completion therefore see the tick they name, including the final one.
	process_physics_priority = 100
	# The observer must report a gameplay stop rather than hang with the paused world.
	process_mode = Node.PROCESS_MODE_ALWAYS

func position_of(value: Variant, errors: Array[String]) -> Vector2:
	if value is Array:
		return Vector2(float(value[0]), float(value[1]))
	if built.anchors.has(value):
		return built.anchors[value]
	if value == "doorstep":
		return (built.map as CityMap).doorstep_world_position()
	errors.append("unresolved anchor: %s" % value)
	return Vector2.INF

func start_position() -> Vector2:
	var errors: Array[String] = []
	return position_of(data.get("setup", {}).get("player", {}).get("at", "doorstep"), errors)

## Installs the fixed day before the world gets a simulation frame. Geometry eligibility reads
## the declared construction context, never the exterior's unbuilt walkable floor.
func install(city: City, player: Stroller, baby: Baby) -> Array[String]:
	_city = city
	_player = player
	named = {"player": player}
	var errors: Array[String] = []
	var setup: Dictionary = data.get("setup", {})
	var map := city.map
	var at := position_of(setup.get("player", {}).get("at", "doorstep"), errors)
	if not errors.is_empty():
		return errors
	var exterior := map.recipe_exterior
	map.recipe_exterior = false
	if not map.is_open(map.world_to_tile(at)) or not _inside_extent(at):
		errors.append("setup.player.at must be open ground inside the authored extent")
	var plans := _event_plans(at, errors)
	map.recipe_exterior = exterior
	if not errors.is_empty():
		return errors
	var background: Dictionary = setup.get("background", {})
	if background.get("events", false):
		city.events.start_day(GameState.day, GameState.day_rng(), GameState.consumed_one_shots, at)
	else:
		city.events.start_recipe(plans, GameState.day, at, data.get("kind", "city") == "escape")
	for entry: Dictionary in setup.get("events", []):
		for plan in plans:
			if plan.get_meta("recipe_name", "") == entry.name:
				if not plan.live:
					errors.append("event %s is not live at its required initial position" % entry.name)
				else:
					named[entry.name] = plan.live
	city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"), at,
			bool(background.get("crowd", false)), background.get("crowd_scope", "player") == "city")
	if city.region_plan():
		city.crowd.set_gates(city.region_plan().gates)
	for entry: Dictionary in setup.get("actors", []):
		var actor_at := position_of(entry.at, errors)
		if not errors.is_empty():
			break
		if not _inside_extent(actor_at):
			errors.append("actor %s is outside authored bounds" % entry.name)
			continue
		var placed := city.crowd.add_recipe_actor(entry.name,
				CrowdAgent.Kind.CAR if entry.kind == "car" else CrowdAgent.Kind.WALKER,
				actor_at, DIRECTIONS[entry.direction], float(entry.get("speed", -1)),
				hash("actor:%s" % entry.name))
		if not str(placed.error).is_empty():
			errors.append("actor %s: %s" % [entry.name, placed.error])
		else:
			named[entry.name] = placed.actor
	city.signals.elapsed = float(setup.get("signal_time", 0))
	if setup.get("progression", {}).get("blackout", false):
		city.signals.powered = false
	player.reset_at(at, DIRECTIONS[setup.get("player", {}).get("facing", "south")])
	baby.reset()
	var initial: Dictionary = setup.get("player", {})
	baby.excitement = float(initial.get("excitement", 0))
	baby.sleepiness = float(initial.get("sleep", 0))
	if data.get("kind", "city") == "escape" or baby.sleepiness >= Tuning.METER_MAX:
		baby.force_sleep()
	if setup.has("column"):
		_install_column(setup.column, at, errors)
	manifest["initial_actors"] = snapshot()
	return errors

## The army column is a production happening, whose close-spaced trucks deliberately do not use
## unrelated catalogue-event spacing. Start its real formation at the authored main-road point.
func _install_column(column: Dictionary, player_at: Vector2, errors: Array[String]) -> void:
	var map := _city.map
	var at := position_of(column.at, errors)
	if not errors.is_empty():
		return
	var going := -1.0 if column.direction == "north" else 1.0
	var lane := CrowdLanes.lane_centre(map.main_road, CrowdLanes.road_lane(true, going))
	var top := Tuning.TILE_SIZE * 0.5
	var bottom := map.size.y * Tuning.TILE_SIZE - Tuning.TILE_SIZE * 0.5
	var back := at.y - going * Tuning.COLUMN_SPACING * (Tuning.COLUMN_TRUCKS - 1)
	if not is_equal_approx(at.x, lane) or at.y < top or at.y > bottom or back < top or back > bottom:
		errors.append("setup.column.at must fit the actual main-road lane and whole formation")
		return
	var happening := ResistanceHappenings.new()
	happening.setup(_city, map)
	happening.start_day(GameState.day)
	happening._bring_the_column(EventCatalogue.by_id("military_convoy"), at, player_at,
			lane, going, top, bottom)
	for i in happening.column.size():
		named["truck_%d" % (i + 1)] = happening.column[i]

func _inside_extent(at: Vector2) -> bool:
	var map: CityMap = built.map
	return not map.recipe_bounds.has_area() or map.recipe_bounds.has_point(map.world_to_tile(at))

func _event_plans(player_at: Vector2, errors: Array[String]) -> Array[EventScheduler.Planned]:
	var setup: Dictionary = data.get("setup", {})
	var plans: Array[EventScheduler.Planned] = []
	var map := _city.map
	var tree := _city.route_tree()
	var corridor: Corridor = Corridor.of(tree) if tree else null
	var doors := PackedVector2Array()
	var finale: FinalePlanner.Plan
	if data.get("kind", "city") == "escape":
		finale = FinalePlanner.plan(map, GameState.day_rng(GameState.day, "finale"), false)
		for chain in finale.chains:
			if not chain.complete:
				errors.append("escape route construction could not complete its ordinary chains")
		plans.append_array(finale.placements)
	elif _city.region_plan():
		for body in _city.region_plan().wall_bodies:
			if _inside_extent(body.position):
				plans.append(body)
		for body in _city.region_plan().door_bodies:
			doors.append(body.position)
			if _inside_extent(body.position):
				plans.append(body)
	for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
		map.hold_segment(segment.key())
	var counts := {}
	for entry: Dictionary in setup.get("events", []):
		var at := position_of(entry.at, errors)
		if not errors.is_empty():
			break
		if not _inside_extent(at):
			errors.append("event %s is outside authored bounds" % entry.name)
			continue
		var def := EventCatalogue.by_id(entry.row)
		var plan: EventScheduler.Planned
		if finale:
			plan = _finale_placement(def, at, player_at, finale, plans,
					int(entry.get("route_seed", 1)))
		elif def.spawn_mode_on(GameState.day) != EventDef.SpawnMode.MAP:
			var director := EventDirector.new(map)
			var heading: Vector2 = DIRECTIONS[setup.get("player", {}).get("facing", "south")]
			var route := director._crossing_ahead_of(player_at, heading, def)
			if not def.available_on(GameState.day) or not def.pursues or route.is_empty() \
					or not route[0].is_equal_approx(at) \
					or not EventScheduler.clear_of_the_doors(at, route, doors, def.field_reach()):
				errors.append("event %s fails its ordinary director siting" % entry.name)
				continue
			plan = EventScheduler.Planned.new(def, at, route)
		else:
			plan = EventScheduler.recipe_placement(def, GameState.day, map, at,
					int(entry.get("route_seed", 1)), plans, corridor, doors)
		if not plan:
			errors.append("event %s fails ordinary day/ground/route/spacing placement" % entry.name)
			continue
		counts[def.id] = int(counts.get(def.id, 0)) + 1
		if def.max_per_day > 0 and int(counts[def.id]) > def.max_per_day:
			errors.append("event %s exceeds the ordinary per-day cap" % entry.name)
		var requested := PackedVector2Array()
		for point: Variant in entry.get("path", []):
			requested.append(position_of(point, errors))
		if not requested.is_empty() and requested != plan.path:
			errors.append("event %s.path is not its production route for route_seed" % entry.name)
		for point in plan.path:
			if not _inside_extent(point):
				errors.append("event %s route leaves the authored extent" % entry.name)
		plan.age = float(entry.get("age", 0))
		if plan.age > plan.def.telegraph_time:
			errors.append("event %s.age cannot skip active simulation; use playback warmup" % entry.name)
		plan.set_meta("recipe_name", entry.name)
		plans.append(plan)
	return plans

## The escape's exact actors use its own row variants, open streets, tree exclusion, spawn
## clearance and body spacing. No ordinary-day corridor or offscreen director stands in for it.
func _finale_placement(def: EventDef, at: Vector2, player_at: Vector2,
		finale: FinalePlanner.Plan, prior: Array[EventScheduler.Planned],
		route_seed: int) -> EventScheduler.Planned:
	if not def.id in ["military_convoy", "abduction", "roadblock", "finale_explosion"]:
		return null
	if def.id == "roadblock":
		def = EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL)
	elif def.id == "military_convoy":
		def = EventScheduler._without_its_aftermath(def)
	var map := _city.map
	var tile := map.world_to_tile(at)
	if not map.tile_to_world(tile).is_equal_approx(at):
		return null
	var ground_ok := false
	var trees := StreetTrees.footprint_tiles(map)
	for segment in finale.open_streets:
		if tile in EventScheduler._finale_ground(map, segment, def, trees, player_at):
			ground_ok = true
			break
	if not ground_ok:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	var candidate := EventScheduler._build_placement(def, map, tile, rng)
	if not candidate or EventScheduler._room_around(candidate, prior) == -INF:
		return null
	return candidate

func begin() -> void:
	manifest["initial_actors"] = snapshot()
	_record_crowd("initial_crowd")
	print("[SceneRecipe] manifest " + JSON.stringify(manifest, "", true))
	write_manifest()
	if "--recipe-validate" in DevFlags.active_args():
		get_tree().quit(0)
		return
	if not scripted:
		return
	var playback: Dictionary = data.get("playback", {})
	var camera: Dictionary = playback.get("camera", {})
	DevRig.apply_zoom(get_viewport().get_camera_2d(), float(camera.get("zoom", 1)))
	if camera.has("zoom_out"):
		var zoom := ZoomOutCamera.new()
		_zoom = zoom
		zoom.simulation_clock = elapsed
		add_child(zoom)
		zoom.setup(get_viewport().get_camera_2d(), _city.map.tile_rect_to_world(
				Rect2i(Vector2i.ZERO, _city.map.size)), get_viewport().get_visible_rect().size,
				float(camera.zoom_out), float(camera.get("zoom_delay", 0)))
	var title := TrailerText.build(str(playback.get("caption", "")), str(playback.get("title", "")))
	if title:
		add_child(title)
	_active = true
	_observe()
	_apply_input()

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	if get_tree().paused:
		manifest["playback_error"] = "gameplay paused before the authored action completed"
		manifest["stopped_tick"] = tick
		manifest["final_actors"] = snapshot()
		print("[SceneRecipe] playback stopped: " + JSON.stringify(manifest))
		write_manifest()
		_active = false
		get_tree().quit(1)
		return
	tick += 1
	_observe()
	if not _active:
		return
	if _capture_tick >= 0 and tick >= _capture_tick:
		prepare_capture()
		return
	if tick >= _duration_ticks:
		_active = false
		_release_input()
		manifest["playback_complete"] = true
		manifest["completed_tick"] = tick
		manifest["final_actors"] = snapshot()
		_record_crowd("final_crowd")
		write_manifest()
		get_tree().quit(0)
		return
	_apply_input()

func _apply_input() -> void:
	var remaining := float(tick) / Engine.physics_ticks_per_second
	var direction := Vector2.ZERO
	var running := false
	for step in _steps:
		if remaining < float(step.seconds):
			direction = step.direction
			running = step.run
			break
		remaining -= float(step.seconds)
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if running:
		Input.action_press("run")
	else:
		Input.action_release("run")

func elapsed() -> float:
	return float(tick) / Engine.physics_ticks_per_second

## Hold the exact simulated moment while the screenshot draws, even with a covered window.
func prepare_capture() -> void:
	if manifest.has("capture_tick"):
		return
	if _zoom:
		_zoom._process(0)
		_zoom.set_process(false)
	var camera := get_viewport().get_camera_2d()
	if camera:
		camera.force_update_scroll()
		manifest["capture_camera"] = {"position": [camera.global_position.x, camera.global_position.y],
				"zoom": camera.zoom.x}
	manifest["capture_tick"] = tick
	manifest["capture_actors"] = snapshot()
	_record_crowd("capture_crowd")
	write_manifest()
	_active = false
	get_tree().paused = true

func _record_crowd(key: String) -> void:
	if _city and _city.crowd:
		manifest[key] = _city.crowd.recipe_coverage()

func _release_input() -> void:
	TouchControls._set_axis(&"move_left", &"move_right", 0)
	TouchControls._set_axis(&"move_up", &"move_down", 0)
	Input.action_release("run")

func _exit_tree() -> void:
	if scripted:
		_release_input()

func snapshot() -> Dictionary:
	var result := {}
	for label: String in named:
		if not is_instance_valid(named[label]):
			result[label] = {"retired": true}
			continue
		var actor: Node2D = named[label]
		var at := actor.global_position
		result[label] = {"position": [snappedf(at.x, 0.0001), snappedf(at.y, 0.0001)]}
		if actor is Stroller:
			result[label]["carrying"] = actor.carrying
			result[label]["speed"] = snappedf(actor.current_speed(), 0.0001)
			result[label]["gait_frame"] = actor._mother_gait_frame(actor.current_speed() / Tuning.WALK_SPEED)
		elif actor is EventInstance:
			result[label]["row"] = actor.def.id
			result[label]["telegraphing"] = actor.is_telegraphing()
			result[label]["pursuing"] = actor.def.pursues and not actor.is_waiting() \
					and not actor.is_telegraphing() and not actor.is_finished and not actor.is_leaving
	return result

func _observe() -> void:
	for check: Dictionary in _observations:
		if int(check.tick) != tick:
			continue
		var passed := is_instance_valid(named.get(check.subject))
		var actor: Node2D = named[check.subject] if passed else null
		if passed:
			match check.condition:
				"visible":
					var point := get_viewport().get_canvas_transform() * actor.global_position
					passed = get_viewport().get_visible_rect().grow(-20).has_point(point)
				"moving":
					passed = _last_positions.has(check.subject) and actor.global_position.distance_to(
							_last_positions[check.subject]) > 0.01
				"running":
					passed = actor is Stroller and actor.current_speed() > Tuning.WALK_SPEED
				"carrying":
					passed = actor is Stroller and actor.carrying
				"pursuing":
					passed = actor is EventInstance and actor.def.pursues \
							and not actor.is_telegraphing() and not actor.is_waiting() \
							and not actor.is_finished and not actor.is_leaving
				"near":
					var errors: Array[String] = []
					var target := position_of(check.at, errors)
					passed = errors.is_empty() and actor.global_position.distance_to(target) <= float(check.distance)
		var record := check.duplicate(true)
		record["passed"] = passed
		record["state"] = snapshot().get(check.subject, {})
		manifest.observations.append(record)
		if not passed:
			print("[SceneRecipe] unmet observation: " + JSON.stringify(record))
			write_manifest()
			_active = false
			get_tree().quit(1)
	for label: String in named:
		if is_instance_valid(named[label]):
			_last_positions[label] = (named[label] as Node2D).global_position

func write_manifest() -> void:
	var path := DevFlags._word_after("--recipe-manifest")
	if path.is_empty():
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("[SceneRecipe] cannot write manifest: " + path)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t", true) + "\n")
