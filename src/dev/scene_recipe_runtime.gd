class_name SceneRecipeRuntime
extends Node
## Minimal scripted launch of a constructed city. The ordinary Main, player and day remain
## live; setup completes before the physics clock starts driving real input actions.

const DIRECTIONS := {"north": Vector2.UP, "south": Vector2.DOWN,
		"east": Vector2.RIGHT, "west": Vector2.LEFT}
const OWNED_FLAGS := ["--seed", "--day", "--spawn", "--parent", "--meters", "--walk",
		"--flee", "--route", "--force", "--follow", "--zoom", "--zoom-out", "--caption",
		"--title-card", "--start-escape", "--blackout", "--overview", "--day-length",
		"--press", "--tap", "--ending", "--quit-when-still", "--skip"]

var data: Dictionary = {}
var built: Dictionary = {}
var manifest: Dictionary = {}
var scripted := true
var tick := 0
var _player: Stroller
var _steps: Array[Dictionary] = []
var _duration_ticks := 0
var _active := false
var _capture_tick := -1

static func load_recipe(path: String, args: PackedStringArray) -> Dictionary:
	var loaded := SceneRecipe.load_file(path)
	if not loaded.errors.is_empty():
		return loaded
	var errors := validate_runtime(loaded.data)
	for flag in OWNED_FLAGS:
		if flag in args:
			errors.append("arguments: %s conflicts with recipe-owned setup/playback" % flag)
	var index := args.find("--recipe-mode")
	if index >= 0 and (index + 1 >= args.size() or args[index + 1] != "scripted"):
		errors.append("--recipe-mode: this builder supports scripted launch only")
	if not errors.is_empty():
		return {"data": loaded.data, "errors": errors}
	var result := RecipeCityBuilder.build(loaded.data)
	result.data = loaded.data
	return result

static func validate_runtime(recipe: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var setup: Dictionary = recipe.get("setup", {})
	var playback: Dictionary = recipe.get("playback", {})
	SceneRecipe._keys(setup, ["day", "parent", "player", "background", "tutorial_complete"], "setup", errors)
	_number(setup.get("day", 1), "setup.day", 1, 14, errors, true)
	if not setup.get("parent", "mother") in ["mother", "father"]:
		errors.append("setup.parent must be mother or father")
	if not setup.get("tutorial_complete", false) is bool:
		errors.append("setup.tutorial_complete must be boolean")
	for key in ["player", "background"]:
		if not setup.get(key, {}) is Dictionary:
			errors.append("setup.%s must be an object" % key)
	if not errors.is_empty():
		return errors
	var player: Dictionary = setup.get("player", {})
	SceneRecipe._keys(player, ["at", "facing", "excitement", "sleep"], "setup.player", errors)
	var at: Variant = player.get("at", "doorstep")
	if not (at is String and not at.is_empty()) and not SceneRecipe.tuple(at, 2, false):
		errors.append("setup.player.at must be an anchor name or [world_x,world_y]")
	if not DIRECTIONS.has(player.get("facing", "south")):
		errors.append("setup.player.facing must name a cardinal direction")
	for key in ["excitement", "sleep"]:
		_number(player.get(key, 0), "setup.player." + key, 0, 100, errors)
	var background: Dictionary = setup.get("background", {})
	SceneRecipe._keys(background, ["events", "crowd"], "setup.background", errors)
	for key in background:
		if not background[key] is bool or background[key]:
			errors.append("setup.background.%s: this builder requires false" % key)
	SceneRecipe._keys(playback, ["walk", "duration", "camera"], "playback", errors)
	_number(playback.get("duration", 5), "playback.duration", 1.0 / 30.0, 240, errors)
	var walk: Variant = playback.get("walk", "")
	if not walk is String or (not str(walk).is_empty() and AutoScreenshot._parse_script(walk).is_empty()):
		errors.append("playback.walk must be a valid timed movement script")
	if not playback.get("camera", {}) is Dictionary:
		errors.append("playback.camera must be an object")
	else:
		var camera: Dictionary = playback.get("camera", {})
		SceneRecipe._keys(camera, ["zoom"], "playback.camera", errors)
		_number(camera.get("zoom", 1), "playback.camera.zoom", 0.001, 240, errors)
	return errors

static func _number(value: Variant, where: String, low: float, high: float,
		errors: Array[String], integer := false) -> void:
	if not (value is int or value is float):
		errors.append(where + " must be numeric")
	elif not is_finite(float(value)) or float(value) < low or float(value) > high \
			or (integer and float(value) != floorf(float(value))):
		errors.append(where + " is outside its supported range")

func configure(result: Dictionary, scripted_mode := true) -> void:
	data = result.data
	built = result
	manifest = result.manifest.duplicate(true)
	scripted = scripted_mode
	manifest["recipe"] = data.name
	manifest["recipe_sha256"] = JSON.stringify(data, "", true).sha256_text()
	manifest["engine"] = Engine.get_version_info().string
	manifest["physics_ticks_per_second"] = Engine.physics_ticks_per_second
	manifest["playback_complete"] = false
	manifest["setup"] = data.get("setup", {}).duplicate(true)
	manifest["anchors"] = {}
	for label: String in result.anchors:
		var at: Vector2 = result.anchors[label]
		manifest.anchors[label] = [at.x, at.y]
	_steps = AutoScreenshot._parse_script(str(data.get("playback", {}).get("walk", "")))
	_duration_ticks = roundi(float(data.get("playback", {}).get("duration", 5)) * Engine.physics_ticks_per_second)
	if "--screenshot" in DevFlags.active_args():
		_capture_tick = ceili(DevFlags._word_after("--after").to_float() * Engine.physics_ticks_per_second)
	process_physics_priority = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_position() -> Vector2:
	var at: Variant = data.get("setup", {}).get("player", {}).get("at", "doorstep")
	if at is Array:
		return Vector2(float(at[0]), float(at[1]))
	if built.anchors.has(at):
		return built.anchors[at]
	return (built.map as CityMap).doorstep_world_position() if at == "doorstep" else Vector2.INF

func install(city: City, player: Stroller, baby: Baby) -> Array[String]:
	var errors: Array[String] = []
	var at := start_position()
	var map := city.map
	var bounds := Rect2i(Vector2i.ZERO, map.size) if not map.recipe_exterior else map.recipe_bounds
	if not at.is_finite() or not bounds.has_point(map.world_to_tile(at)) \
			or not map.is_open(map.world_to_tile(at)):
		errors.append("setup.player.at must be open ground inside the authored extent")
		return errors
	city.events.clear()
	city.crowd.clear()
	_player = player
	var initial: Dictionary = data.get("setup", {}).get("player", {})
	player.reset_at(at, DIRECTIONS[initial.get("facing", "south")])
	baby.reset()
	baby.excitement = float(initial.get("excitement", 0))
	baby.sleepiness = float(initial.get("sleep", 0))
	if baby.sleepiness >= Tuning.METER_MAX:
		baby.force_sleep()
	return errors

func snapshot() -> Dictionary:
	var at := _player.global_position
	return {"player": {"position": [at.x, at.y], "speed": _player.current_speed()}}

func begin() -> void:
	manifest["initial_actors"] = snapshot()
	print("[SceneRecipe] manifest " + JSON.stringify(manifest, "", true))
	write_manifest()
	if "--recipe-validate" in DevFlags.active_args():
		get_tree().quit(0)
		return
	DevRig.apply_zoom(get_viewport().get_camera_2d(),
			float(data.get("playback", {}).get("camera", {}).get("zoom", 1)))
	_active = true
	_apply_input()

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	if get_tree().paused:
		manifest["playback_error"] = "gameplay stopped before the script completed"
		write_manifest()
		_active = false
		_release_input()
		get_tree().quit(1)
		return
	tick += 1
	if _capture_tick >= 0 and tick >= _capture_tick:
		prepare_capture()
		return
	if tick >= _duration_ticks:
		_active = false
		_release_input()
		manifest["playback_complete"] = true
		manifest["completed_tick"] = tick
		manifest["final_actors"] = snapshot()
		write_manifest()
		get_tree().quit(0)
		return
	_apply_input()

func _apply_input() -> void:
	var remaining := elapsed()
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

func prepare_capture() -> void:
	manifest["capture_tick"] = tick
	manifest["capture_actors"] = snapshot()
	write_manifest()
	_active = false
	get_tree().paused = true

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

func _release_input() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)

func _exit_tree() -> void:
	_release_input()
