@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **The lifecycle behind `test_scene_recipe_lifecycle_trailers.gd`, `_tasks.gd` and `_scenes.gd`;
## not a suite itself.** Boots the actual Main scene, in this process, on real frames
## (`tests/booted_main.gd`): free input, bounded travel and escape retry must work through the same
## world and signals as interactive play. Each suite runs the recipes whose file name begins with
## its prefix (`PREFIX_TRAILER`, `PREFIX_TASK`) or, for the scenes suite, all the others
## (`PREFIX_OTHER`), so no suite runs two minutes serial; the later-day boot of the power station
## hall belongs to the scenes suite.
##
## **What a recipe is checked for.** Booted scripted, then booted free, it starts from the same
## actors, day and seed (`SceneRecipeRuntime.manifest`, read at `begin()`); booted free it starts
## where the recipe puts her, takes no save and no capture deadline, and real input moves her; a
## bounded scene installs no body outside its ground and lets her out and back, and a stretch keeps
## her on its ground at the void's edge. Then the scene is left the two ways a player leaves one: a
## won day continued from its summary, or a lost escape (`EventBus.hard_fail_triggered`), each
## reloading through the hook `main.use_reload()` hands it, and the boot that follows, taking the
## sitting the one before parked, restores the authored day and actors.
##
## **A scene that does not stand fails as a check, not as the runner's end**: every boot is handed
## `main.use_quit()` a recorder (`_quits`), which `main` also hands the scene to end the game with
## (`SceneRecipeRuntime.configure()`), and a boot that ends its game is a failed check.
##
## **The meters a scene starts at** are checked per boot against `setup.player`'s values, within the
## most they can have moved in the ticks the scene has counted (`_meters_hold()`), not compared across
## the two modes: the scripted boot presses its walk from tick 0, so the two boots' meters differ
## by what that walk did.

const Boot := preload("res://tests/booted_main.gd")

const PREFIX_TRAILER := "trailer-"
const PREFIX_TASK := "task-"
const PREFIX_OTHER := ""

## How long a walk towards a point may take before it is called blocked, how long a scene is walked
## towards the void's edge, and how long real input is held to move her, in seconds of game time.
const WALK_SECONDS := 4.0
const EDGE_SECONDS := 2.5
const MOVE_SECONDS := 0.4
## How many times real time the walks run (`Engine.time_scale`, `PhysicsTicks.pass_ticks()`): at her
## walking pace a tick still moves her a fifth of a tile at most, so no wall is stepped over.
const WALK_SCALE := 2.0

## One entry for every game the boots ended, which `main.use_quit()` is handed to record (it is told
## that the game ended, not with what status).
var _quits: Array[int] = []

## Whether `filename` belongs to the part named by `prefix`.
static func belongs(filename: String, prefix: String) -> bool:
	if prefix == PREFIX_OTHER:
		return not filename.begins_with(PREFIX_TRAILER) and not filename.begins_with(PREFIX_TASK)
	return filename.begins_with(prefix)

func lifecycle(t: TestRunner, prefix: String) -> void:
	await PhysicsTicks.settle(t)
	var tested := 0
	for filename in DirAccess.get_files_at("res://scene-recipes"):
		if not filename.ends_with(".json") or not belongs(filename, prefix):
			continue
		var path := "res://scene-recipes/" + filename
		var scripted := await _scripted_boot(t, path, filename)
		var free := await _free_play(t, path, filename)
		t.check(not scripted.is_empty() and scripted == free.initial,
				"%s free and scripted boots start from identical actors, day and seed" % filename)
		tested += 1
	t.check(tested > 0, "lifecycle discovery exercises saved recipes")
	if prefix != PREFIX_OTHER:
		return
	var stem := "user://scene_recipe_lifecycle_%d" % OS.get_process_id()
	var later_day_path := stem + "_later_power-station-hall.json"
	var later_day: Dictionary = SceneRecipe.load_file("res://scene-recipes/power-station-hall.json").data
	later_day.setup.day = 13
	var later_day_file := FileAccess.open(later_day_path, FileAccess.WRITE)
	later_day_file.store_string(JSON.stringify(later_day))
	later_day_file.close()
	var later := await _free_play(t, later_day_path, "the power station hall on day 13")
	t.check(later.bounded_returned,
			"later-day bounded region bodies stay inside extent and real player exits and returns")
	DirAccess.remove_absolute(later_day_path)

## A boot of the recipe at `path` under `mode` ("free" or "scripted"), the reload it asks for handed
## to `reloads` and its sitting parked in `home` as a real reload parks it at the root. Its save is
## at a scratch path, which `Boot.Booted.free_all()` removes.
func _boot(t: TestRunner, path: String, mode: String, home: Node, reloads: Array[int]) -> Boot.Booted:
	var scratch := "user://scene_recipe_lifecycle_%s_%d.json" % [mode, OS.get_process_id()]
	# Parsed for a window and without `--no-save`, so the save is refused by the recipe flags' own
	# policy (`GameSave._uses_save()`) and not by the headless gate: a scratch save written is a failure.
	var config := RunConfig.parse(PackedStringArray(["--no-telemetry", "--recipe", path,
			"--recipe-mode", mode, "--no-focus-pause"]), "", true, false, {}, false)
	return await Boot.boot(t, scratch, config, func(main: Node) -> void:
			main.use_sitting_home(home)
			main.use_reload(func() -> void: reloads.append(1))
			main.use_quit(func() -> void: _quits.append(1)))

## The scripted boot of `path`: its start, read at `begin()`, or an empty dictionary when it did not
## stand. Freed at once, before the walk it plays can reach its end.
func _scripted_boot(t: TestRunner, path: String, label: String) -> Dictionary:
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	_quits.clear()
	var reloads: Array[int] = []
	var booted := await _boot(t, path, "scripted", home, reloads)
	var recipe := scene_of(booted.main)
	var initial := _start_of(t, booted, run, recipe, label)
	t.check(recipe != null and recipe.plays_by_script() and not recipe.manifest.get("setup_failed", false),
			"%s boots real scripted Main" % label)
	booted.free_all()
	home.free()
	return initial

## What a scene started from: its actors and the events installed, as the manifest records them at
## `begin()`, and the run's day and seed. Empty when no scene stands.
func _start_of(t: TestRunner, booted: Boot.Booted, run: RunState, recipe: SceneRecipeRuntime,
		label: String) -> Dictionary:
	if recipe == null or recipe.manifest.get("setup_failed", false):
		return {}
	var start := recipe.manifest.initial_actors.get("player", {}).get("position", [0, 0]) as Array
	t.check(Vector2(start[0], start[1]).is_equal_approx(recipe.start_position()),
			"%s starts her where the recipe puts her" % label)
	var authored_day: Variant = recipe.data.get("setup", {}).get("day")
	t.check(authored_day == null or run.header.day == int(authored_day),
			"%s starts the run on its authored day (day %d)" % [label, run.header.day])
	t.check(_quits.is_empty() and not t.get_tree().paused,
			"%s boots without ending the game, running" % label)
	_meters_hold(t, booted.main, recipe, label)
	for collection in ["events", "actors"]:
		for entry: Dictionary in recipe.data.get("setup", {}).get(collection, []):
			t.check(recipe.named.has(entry.name), "%s installs the authored %s %s"
					% [label, collection, entry.name])
	return {"actors": recipe.manifest.initial_actors, "day": run.header.day,
			"events": recipe.manifest.get("installed_events", []), "seed": run.header.run_seed}

## Her meters are what `setup.player` says, moved by no more than the ticks the scene has counted can
## move them: sleepiness at the fastest it fills (a one-block calm area, `Tuning.sleepiness_gain_calm()`)
## or drains; excitement at the most it falls (`Tuning.EXCITEMENT_DECAY_WALKING` times the calm zone's multiplier, the largest ground
## multiplier, `City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER`), and no more than the meter holds: what raises it (the crowd and every event near her) is not
## bounded by what the scene installs, so a rise is not checked. An escape and a
## full sleep meter start her asleep (`Baby.force_sleep()`).
func _meters_hold(t: TestRunner, main: Node, recipe: SceneRecipeRuntime, label: String) -> void:
	var baby := Boot.baby(main)
	if baby == null:
		return
	var authored: Dictionary = recipe.data.get("setup", {}).get("player", {})
	var asleep: bool = recipe.data.get("kind", "city") == "escape" \
			or float(authored.get("sleep", 0)) >= Tuning.METER_MAX
	var seconds := float(recipe.tick) / Engine.physics_ticks_per_second
	var sleep_rate := maxf(Tuning.sleepiness_gain_calm(1), Baby.SLEEPINESS_DRAIN_IDLE)
	var sleep_from := Tuning.METER_MAX if asleep else float(authored.get("sleep", 0))
	var excite_from := float(authored.get("excitement", 0))
	t.check(absf(baby.sleepiness - sleep_from) <= sleep_rate * seconds + 0.01
			and baby.excitement <= Tuning.METER_MAX
			and baby.excitement >= excite_from - Tuning.EXCITEMENT_DECAY_WALKING * City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER * seconds - 0.01,
			"%s: her meters are %.2f sleep and %.2f excitement after %d ticks, from %.1f and %.1f"
			% [label, baby.sleepiness, baby.excitement, recipe.tick, sleep_from, excite_from])

## The free-play boot of `path`, played the ways a player plays a scene and left the ways one is
## left. Returns `{"initial": <its start>, "bounded_returned": <she went out of a bounded scene
## and back>}`.
func _free_play(t: TestRunner, path: String, label: String) -> Dictionary:
	var result := {"initial": {}, "bounded_returned": false}
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	_quits.clear()
	var reloads: Array[int] = []
	var booted := await _boot(t, path, "free", home, reloads)
	var main := booted.main
	var recipe := scene_of(main)
	var player := Boot.player(main)
	var city := Boot.city(main) if Boot.interior(main) == null else null
	var initial := _start_of(t, booted, run, recipe, label)
	t.check(not initial.is_empty() and player != null and not recipe.plays_by_script(),
			"%s boots and completes real free-play lifecycle" % label)
	if initial.is_empty() or player == null:
		booted.free_all()
		home.free()
		return result
	result.initial = initial
	var map: CityMap = recipe.built.map
	# Free play has no capture deadline: the scene keeps counting ticks and nothing ends it (a scripted
	# one that reached its duration would end the game).
	var counted := recipe.tick
	await PhysicsTicks.pass_ticks(t, 3)
	var rig_lock := main.get_node_or_null("RigLock") as RigLock
	t.check(recipe.tick > counted and not recipe.manifest.get("playback_complete", false)
			and (rig_lock == null or not rig_lock.locked_out),
			"%s free play has no capture deadline" % label)
	var start := player.global_position
	var direction := Vector2.ZERO
	for candidate: Vector2 in [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		if map.is_open(map.world_to_tile(start + candidate * 24.0)):
			direction = candidate
			break
	_press(direction)
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(MOVE_SECONDS, WALK_SCALE), Callable(), WALK_SCALE)
	_press(Vector2.ZERO)
	t.check(direction != Vector2.ZERO and player.global_position.distance_to(start) >= 3.0,
			"%s physical Input actions move the real player" % label)
	if map.recipe_bounds.has_area():
		result.bounded_returned = await _go_out_and_back(t, main, map, label)
		t.check(result.bounded_returned, "%s permits physical exit and return without resetting" % label)
	if map.has_stretch():
		await _walk_at_the_void(t, player, map, label)
	if recipe.data.get("kind", "city") == "escape":
		await _lose_the_escape(t, recipe, reloads, label)
	else:
		await _win_the_day(t, main, run, reloads, label)
	t.check(_quits.is_empty() and not FileAccess.file_exists(booted.path),
			"%s: played and left without ending the game or writing a save" % label)
	if reloads.size() == 1:
		var again := await _boot(t, path, "free", home, reloads)
		var again_initial := _start_of(t, again, run, scene_of(again.main), label)
		t.check(again_initial == initial,
				"%s real summary continuation or escape retry restores authored day and actors" % label)
		again.free_all()
	booted.free_all()
	home.free()
	return result

## Free play, left a second time through a won day: the day's win applies the normal progression,
## and the summary's continue reloads.
func _win_the_day(t: TestRunner, main: Node, run: RunState, reloads: Array[int], label: String) -> void:
	var authored_day := run.header.day
	if authored_day == Tuning.RUN_LENGTH_DAYS:
		# The door touched, so the run has earned the good ending: outside a recipe that hands the
		# won day over to the escape, and the reload would boot it with no director.
		run.resistance.sabotage_done = true
	Boot.day(main).day_finished.emit(GameEnums.DayResult.WON)
	# The last night's win ends the run on its ending rather than moving on to a next day.
	var progressed := run.header.ending != GameEnums.Ending.NONE \
			if authored_day == Tuning.RUN_LENGTH_DAYS else run.header.day == authored_day + 1
	t.check(progressed, "%s: winning the recipe day applies normal progression" % label)
	await Boot.press_continue(t, main)
	t.check(reloads.size() == 1, "%s: the summary's continue reloads the authored setup" % label)

## Free play, left through a lost escape: perturbs a real actor as well as the player, so a retry
## that only moved the player could not pass because a stationary guard happens to remain at its
## start, and loses.
func _lose_the_escape(t: TestRunner, recipe: SceneRecipeRuntime, reloads: Array[int], label: String) -> void:
	var changed := false
	for actor_name: String in recipe.named:
		if actor_name != "player":
			(recipe.named[actor_name] as Node2D).global_position += Vector2(64, 0)
			changed = true
	t.check(changed, "%s: an escape retry probe has an authored actor to move" % label)
	EventBus.hard_fail_triggered.emit("car_strike")
	await PhysicsTicks.pass_ticks(t, 3)
	t.check(reloads.size() == 1, "%s: an escape loss reloads the authored setup" % label)

## A bounded scene installs no body outside its ground; she walks out of it by the nearest way and
## back to where she started. Whether she did.
func _go_out_and_back(t: TestRunner, main: Node, map: CityMap, label: String) -> bool:
	var player := Boot.player(main)
	for plan: EventScheduler.Planned in Boot.city(main).events.plans():
		if not map.recipe_bounds.has_point(map.world_to_tile(plan.position)):
			t.check(false, "%s: bounded region installs event bodies outside authored ground" % label)
			return false
	var return_at := player.global_position
	var path := exterior_path(map, map.world_to_tile(return_at))
	if path.is_empty():
		t.check(false, "%s: bounded scene has a route to its exterior" % label)
		return false
	for tile in path:
		if not await _walk_to(t, player, map.tile_to_world(tile), label):
			return false
	if map.recipe_bounds.has_point(map.world_to_tile(player.global_position)):
		t.check(false, "%s: bounded walk crosses the authored boundary" % label)
		return false
	path.reverse()
	for tile in path:
		if not await _walk_to(t, player, map.tile_to_world(tile), label):
			return false
	return await _walk_to(t, player, return_at, label)

## The void round a stretch is a wall: she walks to the nearest of its cut-off streets by its open
## ground, then walks at the void for `EDGE_SECONDS` and never stands on a tile the scene does not
## have, having come to the edge.
func _walk_at_the_void(t: TestRunner, player: Stroller, map: CityMap, label: String) -> void:
	var path := path_to_the_void(map, map.world_to_tile(player.global_position))
	t.check(not path.is_empty(), "%s: the stretch has a street running into the void" % label)
	if path.is_empty():
		return
	var edge: Vector2i = path.pop_back()
	for tile in path:
		if not await _walk_to(t, player, map.tile_to_world(tile), label):
			return
	var stayed := true
	for _tick in PhysicsTicks.ticks_for(EDGE_SECONDS, WALK_SCALE):
		_press(player.global_position.direction_to(map.tile_to_world(edge)))
		await _tick_of_walking(t)
		if not map.in_stretch(map.world_to_tile(player.global_position)):
			stayed = false
			break
	_press(Vector2.ZERO)
	t.check(stayed and player.global_position.distance_to(map.tile_to_world(edge)) < 2.0 * Tuning.TILE_SIZE,
			"%s keeps her on its stretch at the void's edge, which she has walked to" % label)

## Walks `player` towards `target` on real input until it is within a quarter tile of it. False,
## with the check failed, when the walk is blocked, or a step moves her more than a tick can.
func _walk_to(t: TestRunner, player: Stroller, target: Vector2, label: String) -> bool:
	for _tick in PhysicsTicks.ticks_for(WALK_SECONDS, WALK_SCALE):
		var before := player.global_position
		# A stroller facing a wall stops its body six pixels before the tile center.
		# Arrival within a quarter tile still proves the path and boundary crossing.
		if before.distance_to(target) < Tuning.TILE_SIZE * 0.25:
			_press(Vector2.ZERO)
			return true
		_press(before.direction_to(target))
		await _tick_of_walking(t)
		if player.global_position.distance_to(before) > _run_step() + 2.0:
			_press(Vector2.ZERO)
			t.check(false, "%s: bounded travel reset or teleported the player" % label)
			return false
	_press(Vector2.ZERO)
	t.check(false, "%s: physical walk was blocked before %s, stopped at %s"
			% [label, target, player.global_position])
	return false

## The most a tick of `_tick_of_walking()` can move her: a run step at the scale the walks run at.
func _run_step() -> float:
	return Tuning.RUN_SPEED * WALK_SCALE / Engine.physics_ticks_per_second

func _tick_of_walking(t: TestRunner) -> void:
	await PhysicsTicks.pass_ticks(t, 1, Callable(), WALK_SCALE)

func _press(direction: Vector2) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)
	if direction.x != 0:
		Input.action_press("move_right" if direction.x > 0 else "move_left", absf(direction.x))
	if direction.y != 0:
		Input.action_press("move_down" if direction.y > 0 else "move_up", absf(direction.y))

## The scene recipe a booted `main` plays: the runtime it builds as its own child, or null.
static func scene_of(main: Node) -> SceneRecipeRuntime:
	for child in main.get_children():
		if child is SceneRecipeRuntime:
			return child
	return null

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

## The open tiles from `start` to the cut-off tile (`CityMap.is_cut_off()`) nearest it through the
## stretch's own ground, the cut-off tile last; empty when none is reached.
func path_to_the_void(map: CityMap, start: Vector2i) -> Array[Vector2i]:
	var pending: Array[Vector2i] = [start]
	var previous := {start: start}
	var cursor := 0
	while cursor < pending.size():
		var tile := pending[cursor]
		cursor += 1
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + offset
			if previous.has(next):
				continue
			if map.is_cut_off(next):
				var path: Array[Vector2i] = [tile]
				while tile != start:
					tile = previous[tile]
					path.push_front(tile)
				path.append(next)
				return path
			if map.in_stretch(next) and map.is_open(next):
				previous[next] = tile
				pending.append(next)
	return []
