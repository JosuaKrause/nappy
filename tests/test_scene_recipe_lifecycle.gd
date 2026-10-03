extends RefCounted
## Boots the actual Main scene in isolated processes: free input, bounded travel and escape
## retry must work through the same world and signals as interactive play.

const PROBE := """extends Node
var main: Node
var recipe: SceneRecipeRuntime
var player: Stroller

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	add_child(main)
	recipe = main.get("_recipe")
	player = main.get("_player")
	if not recipe or not player or recipe.manifest.get("setup_failed", false):
		fail("real Main did not finish recipe setup")
		return
	var initial := {"actors": recipe.snapshot(), "day": GameState.day,
		"events": recipe.manifest.get("installed_events", []),
		"seed": GameState.run_seed, "sleep": (main.get("_baby") as Baby).sleepiness,
		"excitement": (main.get("_baby") as Baby).excitement}
	if not player.global_position.is_equal_approx(recipe.start_position()):
		fail("Main moved the player away from the authored start")
		return
	for collection in ["events", "actors"]:
		for entry: Dictionary in recipe.data.get("setup", {}).get(collection, []):
			var actor: Node2D = recipe.named.get(entry.name)
			if not actor:
				fail("Main did not install authored actor " + str(entry.name))
				return
	if GameSave.uses_save() or get_tree().paused or DevFlags.is_rig() != recipe.scripted:
		fail("recipe boot has the wrong save, pause or input mode")
		return
	if get_tree().has_meta("recipe_retry_expected"):
		if initial != get_tree().get_meta("recipe_retry_expected"):
			fail("escape retry did not restore authored player and actors")
			return
		print("RECIPE_RETRY_OK")
		get_tree().quit()
		return
	print("RECIPE_INITIAL " + JSON.stringify(initial, "", true))
	if recipe.scripted:
		get_tree().quit()
		return
	var start := player.global_position
	var direction := Vector2.ZERO
	var map: CityMap = recipe.built.map
	for candidate: Vector2 in [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		if map.is_open(map.world_to_tile(start + candidate * 24.0)):
			direction = candidate
			break
	press(direction)
	for frame in 12:
		await get_tree().physics_frame
	press(Vector2.ZERO)
	if direction == Vector2.ZERO or player.global_position.distance_to(start) < 3.0:
		fail("physical Input actions did not move the real player")
		return
	print("RECIPE_MOVEMENT_OK")
	if DevFlags.recipe_path().ends_with("power-station-hall.json"):
		for plan: EventScheduler.Planned in (main.get("_city") as City).events._plans:
			if not map.recipe_bounds.has_point(map.world_to_tile(plan.position)):
				fail("bounded region installs event bodies outside authored ground")
				return
		var return_at := player.global_position
		var path := exterior_path(map, map.world_to_tile(return_at))
		if path.is_empty():
			fail("bounded hall has no route to its exterior")
			return
		for tile in path:
			if not await walk_to(map.tile_to_world(tile)):
				return
		if map.recipe_bounds.has_point(map.world_to_tile(player.global_position)):
			fail("hall walk never crossed the authored boundary")
			return
		path.reverse()
		for tile in path:
			if not await walk_to(map.tile_to_world(tile)):
				return
		if not await walk_to(return_at):
			return
		print("RECIPE_BOUNDARY_RETURN_OK")
	if recipe.data.get("kind", "city") == "escape":
		# Perturb a real actor as well as walking the player, so a retry that only moves
		# the player cannot pass because a stationary guard happens to remain at its start.
		var changed := false
		for label: String in recipe.named:
			if label != "player":
				(recipe.named[label] as Node2D).global_position += Vector2(64, 0)
				changed = true
		if not changed:
			fail("escape retry probe requires an authored actor")
			return
		var tree := get_tree()
		tree.set_meta("recipe_retry_expected", initial)
		EventBus.hard_fail_triggered.emit("car_strike")
		for frame in 180:
			if not is_inside_tree():
				return
			await tree.process_frame
		fail("escape loss did not reload the authored setup")
		return
	get_tree().quit()

func press(direction: Vector2) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)
	if direction.x != 0:
		Input.action_press("move_right" if direction.x > 0 else "move_left", absf(direction.x))
	if direction.y != 0:
		Input.action_press("move_down" if direction.y > 0 else "move_up", absf(direction.y))

func walk_to(target: Vector2) -> bool:
	for frame in 120:
		var before := player.global_position
		# A stroller facing a wall stops its body six pixels before the tile center.
		# Arrival within a quarter tile still proves the path and boundary crossing.
		if before.distance_to(target) < Tuning.TILE_SIZE * 0.25:
			press(Vector2.ZERO)
			return true
		press(before.direction_to(target))
		await get_tree().physics_frame
		if player.global_position.distance_to(before) > 8.0:
			fail("bounded travel reset or teleported the player")
			return false
	press(Vector2.ZERO)
	fail("physical walk was blocked before %s, stopped at %s" % [target, player.global_position])
	return false

func exterior_path(map: CityMap, start: Vector2i) -> Array[Vector2i]:
	var pending: Array[Vector2i] = [start]
	var previous := {start: start}
	var cursor := 0
	while cursor < pending.size():
		var tile := pending[cursor]
		cursor += 1
		if not map.recipe_bounds.has_point(tile):
			var path: Array[Vector2i] = [tile]
			while tile != start:
				tile = previous[tile]
				path.push_front(tile)
			return path
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + offset
			if not previous.has(next) and map.is_open(next):
				previous[next] = tile
				pending.append(next)
	return []

func fail(message: String) -> void:
	press(Vector2.ZERO)
	print("RECIPE_LIFECYCLE_FAILED " + message)
	get_tree().quit(1)
"""

func run(t) -> void:
	var stem := "user://scene_recipe_lifecycle_%d" % OS.get_process_id()
	var script_path := stem + ".gd"
	var scene_path := stem + ".tscn"
	var script := FileAccess.open(script_path, FileAccess.WRITE)
	script.store_string(PROBE)
	script.close()
	var scene := FileAccess.open(scene_path, FileAccess.WRITE)
	scene.store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n[node name=\"Probe\" type=\"Node\"]\nscript = ExtResource(\"1\")\n" % script_path)
	scene.close()
	var recipes := DirAccess.get_files_at("res://scene-recipes")
	var tested := 0
	for filename in recipes:
		if not filename.ends_with(".json"):
			continue
		var path := "res://scene-recipes/" + filename
		var free := _boot(scene_path, path, "free")
		var scripted := _boot(scene_path, path, "scripted")
		t.check(free.status == 0 and not free.initial.is_empty(),
				"%s boots and completes real free-play lifecycle: %s" % [filename, free.output])
		t.check(scripted.status == 0 and not scripted.initial.is_empty(),
				"%s boots real scripted Main: %s" % [filename, scripted.output])
		t.check(not free.initial.is_empty() and free.initial == scripted.initial,
				"%s free and scripted boots start from identical actors, position and meters" % filename)
		t.check(free.output.contains("RECIPE_MOVEMENT_OK"),
				"%s physical Input actions move the real player" % filename)
		if filename == "power-station-hall.json":
			t.check(free.output.contains("RECIPE_BOUNDARY_RETURN_OK"),
					"bounded hall permits physical exit and return without resetting")
		var loaded := SceneRecipe.load_file(path)
		if loaded.data.get("kind", "city") == "escape":
			t.check(free.output.contains("RECIPE_RETRY_OK"),
					"%s actual escape loss reloads authored player and actors" % filename)
		tested += 1
	t.check(tested > 0, "lifecycle discovery exercises saved recipes")
	var later_day_path := stem + "_later_power-station-hall.json"
	var later_day: Dictionary = SceneRecipe.load_file("res://scene-recipes/power-station-hall.json").data
	later_day.setup.day = 13
	var later_day_file := FileAccess.open(later_day_path, FileAccess.WRITE)
	later_day_file.store_string(JSON.stringify(later_day))
	later_day_file.close()
	var later_day_run := _boot(scene_path, later_day_path, "free")
	t.check(later_day_run.status == 0 and later_day_run.output.contains("RECIPE_BOUNDARY_RETURN_OK"),
			"later-day bounded region bodies stay inside extent and real player exits and returns: %s" % later_day_run.output)
	DirAccess.remove_absolute(later_day_path)
	DirAccess.remove_absolute(scene_path)
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(script_path + ".uid")

func _boot(scene: String, recipe: String, mode: String) -> Dictionary:
	var output: Array = []
	var status := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--fixed-fps", "60", "--quit-after", "2400", scene, "--",
		"--recipe", recipe, "--recipe-mode", mode, "--no-telemetry", "--no-focus-pause"
	]), output, true)
	var body := "\n".join(output)
	if body.contains("SCRIPT ERROR") or body.contains("ERROR:"):
		status = 1
	var initial := ""
	for line in body.split("\n"):
		if line.begins_with("RECIPE_INITIAL "):
			initial = line.trim_prefix("RECIPE_INITIAL ")
	return {"status": status, "output": body, "initial": initial}
