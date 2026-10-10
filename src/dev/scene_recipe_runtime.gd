class_name SceneRecipeRuntime
extends Node
## One saved setup feeds free play, headless assertions and frame-locked recording. Playback
## starts only after construction and scenery preparation; observations use the game's physics ticks.

const DIRECTIONS := {"north": Vector2.UP, "south": Vector2.DOWN,
		"east": Vector2.RIGHT, "west": Vector2.LEFT}
const OWNED_FLAGS := ["--seed", "--day", "--spawn", "--parent", "--meters", "--walk",
		"--flee", "--route", "--force", "--follow", "--zoom", "--zoom-out", "--caption",
		"--title-card", "--start-escape", "--blackout", "--overview", "--day-length",
		"--press", "--tap", "--ending", "--quit-when-still", "--skip", "--smooth-walk"]

var data: Dictionary = {}
var built: Dictionary = {}
var manifest: Dictionary = {}
var named: Dictionary = {}
var scripted := false
var tick := 0
var _player: Stroller
var _city: City
## The recipe's `playback.walk`, pressed tick by tick (`playback.smooth` smooths its turns).
var _plan: WalkPlan
var _observations: Array = []
var _duration_ticks := 0
var _active := false
## A free-play scene under way: nothing is observed or pressed, but the ticks still count and the
## task is still named each tick (`_bind_task_names()`), so a refusal at the read is printed and
## the manifest's task records when she read the mark.
var _hand_played := false
var _capture_tick := -1
var _zoom: ZoomOutCamera
var _fixed_camera: Camera2D
var _last_positions: Dictionary = {}
var _resistance: ResistanceDirector
## A draft run's record of the walk (`--recipe-draft`), or null.
var _draft: SceneRecipeDraft
## The recipe as its file has it, which a draft run writes its stretch into; `data` is the copy it
## plays (`SceneRecipeDraft.base_of()`).
var _written: Dictionary = {}

static func load_recipe(path: String, args: PackedStringArray) -> Dictionary:
	var loaded := SceneRecipe.load_file(path, "--recipe-draft" in args)
	if not loaded.errors.is_empty():
		return loaded
	var recipe: Dictionary = loaded.data
	var written := recipe
	if "--recipe-draft" in args:
		recipe = SceneRecipeDraft.base_of(recipe)
	var errors := validate_runtime(recipe)
	for flag in OWNED_FLAGS:
		if flag in args:
			errors.append("arguments: %s conflicts with recipe-owned setup/playback" % flag)
	var mode := "free"
	var index := args.find("--recipe-mode")
	if index >= 0 and (index + 1 >= args.size() or args[index + 1].begins_with("--")):
		errors.append("--recipe-mode requires free or scripted")
	if index >= 0 and index + 1 < args.size():
		mode = args[index + 1]
	if not mode in ["free", "scripted"]:
		errors.append("--recipe-mode must be free or scripted")
	if mode == "free" and ("--walk" in args or "--after" in args or "--screenshot" in args):
		errors.append("free play cannot have scripted input or a capture deadline")
	if "--recipe-draft" in args and mode != "scripted":
		errors.append("--recipe-draft walks the recipe's own route, so it needs --recipe-mode scripted")
	if not errors.is_empty():
		return {"data": recipe, "errors": errors}
	var result := RecipeCityBuilder.build(recipe)
	result.data = recipe
	result.written = written
	return result

static func validate_runtime(recipe: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var setup: Dictionary = recipe.get("setup", {})
	var playback: Dictionary = recipe.get("playback", {})
	_keys(setup, ["day", "parent", "player", "background", "progression", "events", "actors",
			"signal_time", "column", "tutorial_complete", "posters", "roof_fixtures",
			"seals", "gates", "barriers", "task", "route_bag"], "setup", errors)
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
	_keys(background, ["events", "crowd", "crowd_scope", "uniform_walkers", "walker_multiplier"], "setup.background", errors)
	if background.get("events", false) != false:
		errors.append("setup.background.events: authored scenes require explicit event selections")
	for key in ["crowd", "uniform_walkers"]:
		if not background.get(key, false) is bool:
			errors.append("setup.background.%s must be boolean" % key)
	_number(background.get("walker_multiplier", 1), "setup.background.walker_multiplier", 1, 4, errors)
	if (background.has("walker_multiplier") or background.has("uniform_walkers")) and not background.get("crowd", false):
		errors.append("setup.background: walker controls require crowd")
	if not background.get("crowd_scope", "player") in ["player", "city"]:
		errors.append("setup.background.crowd_scope must be player or city")
	if background.get("crowd_scope", "player") == "city" and (
			not background.get("crowd", false) or recipe.get("extent", {}).get("scope", "") != "full"):
		errors.append("setup.background.crowd_scope city requires crowd and full extent")
	if recipe.get("extent", {}).get("scope", "") in ["bounded", "stretch"] and (
			background.get("crowd", false)):
		errors.append("bounded and stretch scenes require authored actors/events; random background activity needs full extent")
	_validate_route_bag(recipe, errors)
	var progression: Dictionary = setup.get("progression", {})
	_keys(progression, ["blackout", "escape_part"], "setup.progression", errors)
	if not progression.get("blackout", false) is bool:
		errors.append("setup.progression.blackout must be boolean")
	if recipe.get("kind", "city") == "escape":
		if not recipe.get("city", {}).get("closures", []).is_empty():
			errors.append("city.closures is unsupported for escape scenes; select explicit finale events")
		if progression.get("escape_part", "city") != "city":
			errors.append("setup.progression.escape_part: recipes currently support the real city escape")
		if int(setup.get("day", 1)) != Tuning.RUN_LENGTH_DAYS:
			errors.append("setup.day: the escape requires the final day's progression")
	elif progression.has("escape_part"):
		errors.append("setup.progression.escape_part requires kind escape")
	_number(setup.get("signal_time", 0), "setup.signal_time", 0, 86400, errors)
	var structure_streets := {}
	for collection in ["seals", "gates", "barriers"]:
		if not setup.get(collection, []) is Array:
			errors.append("setup.%s must be an array" % collection)
			continue
		if recipe.get("kind", "city") == "escape" and not setup.get(collection, []).is_empty():
			errors.append("setup.%s is unsupported for escape scenes; select explicit finale events" % collection)
		var seen := {}
		for entry: Variant in setup.get(collection, []):
			if not entry is Dictionary:
				errors.append("setup.%s entries must be objects" % collection)
				continue
			_keys(entry, ["segment", "candidate"] if collection == "seals" else
					(["segment", "end"] if collection == "barriers" else ["segment"]), collection, errors)
			if not SceneRecipe.tuple(entry.get("segment"), 3, true):
				errors.append("setup.%s requires segment [x,y,axis]" % collection)
				continue
			var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
			if not StreetNetwork.by_key(key) or seen.has(key):
				errors.append("setup.%s has an unknown or duplicate street" % collection)
			seen[key] = true
			if structure_streets.has(key):
				errors.append("setup structures select the same street in multiple collections")
			structure_streets[key] = true
			if collection == "seals":
				var found := false
				for candidate in SealPlanner.candidates():
					found = found or candidate.id == entry.get("candidate", "")
				if not found:
					errors.append("setup.seals requires an existing production candidate")
			elif collection == "barriers" and entry.get("end") not in ["a", "b"]:
				errors.append("setup.barriers requires end a or b")
	if not setup.get("roof_fixtures", []) is Array:
		errors.append("setup.roof_fixtures must be an array")
	else:
		var roof_lots := {}
		for roof: Variant in setup.get("roof_fixtures", []):
			if not roof is Dictionary:
				errors.append("setup.roof_fixtures entries must be objects")
				continue
			_keys(roof, ["lot", "fixtures"], "setup.roof_fixtures", errors)
			if not SceneRecipe.tuple(roof.get("lot"), 4, true) or not roof.get("fixtures") is Array:
				errors.append("setup.roof_fixtures requires a tile lot [x,y,w,h] and fixtures array")
				continue
			var lot := SceneRecipe.rect(roof.lot)
			if roof_lots.has(lot):
				errors.append("setup.roof_fixtures duplicates a lot")
			roof_lots[lot] = true
			for fixture: Variant in roof.fixtures:
				if not fixture is Dictionary:
					errors.append("setup.roof_fixtures.fixtures entries must be objects")
					continue
				_keys(fixture, ["cell", "kind"], "roof fixture", errors)
				if not SceneRecipe.tuple(fixture.get("cell"), 2, true) \
						or not Building.RECIPE_FURNITURE_KINDS.has(str(fixture.get("kind", "")).to_upper()):
					errors.append("roof fixture requires integer cell [column,row] and an existing kind")
	if not setup.get("posters", []) is Array:
		errors.append("setup.posters must be an array")
	else:
		for entry: Variant in setup.get("posters", []):
			if not entry is Dictionary:
				errors.append("setup.posters entries must be objects")
				continue
			_keys(entry, ["at", "kind"], "setup.posters", errors)
			_position(entry.get("at"), "setup.posters.at", errors)
			var key := str(entry.get("kind", "")).to_upper()
			if not PosterArt.Kind.has(key):
				errors.append("setup.posters.kind is unknown")
			elif int(setup.get("day", 1)) < int(PosterWalls.KIND_FIRST_DAY[PosterArt.Kind[key]]):
				errors.append("setup.posters.kind is not available on the authored day")
	var names := {"player": true}
	_validate_task(recipe, names, errors)
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
	var mast_ids := {}
	for collection in ["events", "actors"]:
		if not setup.get(collection, []) is Array:
			errors.append("setup.%s must be an array" % collection)
			continue
		for entry: Variant in setup.get(collection, []):
			var where: String = "setup." + collection
			if not entry is Dictionary:
				errors.append(where + " entries must be objects")
				continue
			_keys(entry, ["name", "row", "at", "path", "age", "route_seed", "mast_id"] if collection == "events"
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
				if entry.has("mast_id"):
					# A mast's identity is what the day's task and its arrow answer to, so two
					# authored masts need two ids, and only a loudspeaker is a mast.
					var mast_id: Variant = entry.mast_id
					if entry.get("row") != "loudspeaker":
						errors.append(where + ".mast_id belongs to a loudspeaker row")
					elif not mast_id is String or str(mast_id).is_empty() or mast_ids.has(mast_id):
						errors.append(where + ".mast_id must be a unique nonempty string")
					else:
						mast_ids[mast_id] = true
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
	if setup.has("column") and not setup.get("events", []).is_empty():
		errors.append("setup.column cannot accompany other pinned events")
	if background.get("crowd", false) and not setup.get("actors", []).is_empty():
		for actor: Dictionary in setup.actors:
			if not background.get("uniform_walkers", false) or actor.kind != "walker":
				errors.append("background crowd accepts only pinned walkers with uniform_walkers enabled")
	_keys(playback, ["walk", "smooth", "duration", "capture_at", "camera", "caption", "title",
			"observations", "settled_camera"],
			"playback", errors)
	_number(playback.get("duration", 5), "playback.duration", 1.0 / 60.0, 240, errors)
	if not errors.is_empty():
		return errors
	_number(playback.get("capture_at", 0.5), "playback.capture_at", 0,
			float(playback.get("duration", 5)) - 1.0 / 60.0, errors)
	var walk: Variant = playback.get("walk", "")
	if not walk is String or (not str(walk).is_empty() and AutoScreenshot._parse_script(walk).is_empty()):
		errors.append("playback.walk is not a valid timed movement script")
	if not playback.get("smooth", false) is bool:
		errors.append("playback.smooth must be boolean")
	if not playback.get("settled_camera", false) is bool:
		errors.append("playback.settled_camera must be boolean")
	for key in ["caption", "title"]:
		if not playback.get(key, "") is String:
			errors.append("playback.%s must be text" % key)
	if not playback.get("camera", {}) is Dictionary:
		errors.append("playback.camera must be an object")
	else:
		var camera: Dictionary = playback.get("camera", {})
		_keys(camera, ["zoom", "zoom_out", "zoom_delay", "landscape_margin", "fixed", "fixed_offset"],
				"playback.camera", errors)
		if not camera.get("fixed", false) is bool:
			errors.append("playback.camera.fixed must be boolean")
		if camera.has("fixed_offset") and (not camera.get("fixed", false) \
				or not SceneRecipe.tuple(camera.fixed_offset, 2, false)):
			errors.append("playback.camera.fixed_offset requires fixed true and [x,y] numbers")
		for key in camera:
			if key in ["fixed", "fixed_offset"]:
				continue
			_number(camera[key], "playback.camera." + key,
					0 if key in ["zoom_delay", "landscape_margin"] else 0.001,
					4096 if key == "landscape_margin" else 240, errors)
	if not playback.get("observations", []) is Array:
		errors.append("playback.observations must be an array")
	else:
		for check: Variant in playback.get("observations", []):
			if not check is Dictionary:
				errors.append("playback.observations entries must be objects")
				continue
			_keys(check, ["tick", "subject", "condition", "at", "distance", "half", "walkers", "cars"],
					"observation", errors)
			_number(check.get("tick"), "observation.tick", 0,
					float(playback.get("duration", 5)) * Engine.physics_ticks_per_second, errors, true)
			var subject: Variant = check.get("subject")
			if not names.has(subject) and not (subject is String
					and str(subject).begins_with(ROW_SUBJECT)
					and EventCatalogue.by_id(str(subject).trim_prefix(ROW_SUBJECT))):
				errors.append("observation.subject is not a named actor or row:<catalogue id>")
			if not check.get("condition") in CONDITIONS:
				errors.append("observation.condition is unsupported")
			if check.get("condition") in ["offered", "done", "arrowed", "unarrowed"] \
					and not subject in ["mark", "task"]:
				errors.append("observation.condition %s asks about the task's mark or target"
						% check.get("condition"))
			if check.get("condition") == "clear_of_both_views":
				if not SceneRecipe.tuple(check.get("half"), 2, false) or float(check.half[0]) <= 0.0 \
						or float(check.half[1]) <= 0.0:
					errors.append("observation.half: clear_of_both_views needs [half width, half height] in px")
			elif check.has("half"):
				errors.append("observation.half belongs to clear_of_both_views")
			if check.get("condition") in ["near", "beyond"]:
				_position(check.get("at"), "observation.at", errors)
				_number(check.get("distance"), "observation.distance", 0, 10000, errors)
			elif check.get("condition") == "near_player":
				_number(check.get("distance"), "observation.distance", 0, 10000, errors)
			if check.get("condition") == "crowd":
				if subject != "player":
					errors.append("observation.condition crowd asks about the picture round the player")
				for key in ["walkers", "cars"]:
					_number(check.get(key, 0), "observation." + key, 0, 1000, errors, true)
			elif check.has("walkers") or check.has("cars"):
				errors.append("observation.walkers and cars belong to crowd")
	return errors

## The observation conditions, in the order `docs/SCENE_RECIPES.md` names them.
const CONDITIONS := ["visible", "moving", "running", "carrying", "asleep", "awake", "pursuing", "near", "beyond",
		"near_player",
		"off_screen", "clear_of_both_views", "offered", "done", "arrowed", "unarrowed", "appeared",
		"crowd"]
## An observation subject naming no actor but the first live instance of a catalogue row: what an
## event summons rather than what the recipe placed, such as the `fire_truck` a seen
## `burning_building` calls in.
const ROW_SUBJECT := "row:"

## `setup.task`: the day's own resistance step, its mark where `mark` puts it and unread until she
## touches it (`ResistanceDirector.start_recipe_task()`). The days with a mark take `mark`; the last
## night has no mark and takes none; `neighbor` pins day 10's neighbor's start and nothing else.
## Names `mark`, `task` (the contact, where the red arrow ends) and, for a task that rides a body —
## the man shouting, the van, the burnt shell, the neighbor, a roadblock — `rider`, for the
## observations.
static func _validate_task(recipe: Dictionary, names: Dictionary, errors: Array[String]) -> void:
	var setup: Dictionary = recipe.get("setup", {})
	if not setup.has("task"):
		return
	if not setup.task is Dictionary:
		errors.append("setup.task must be an object")
		return
	var task: Dictionary = setup.task
	_keys(task, ["mark", "neighbor"], "setup.task", errors)
	if recipe.get("kind", "city") != "city":
		errors.append("setup.task requires a city scene")
	var day := int(setup.get("day", 1))
	var none: Array[int] = []
	var step := ResistanceSteps.for_day(day, none, none, true)
	if not step:
		errors.append("setup.task: day %d offers no resistance task" % day)
		return
	if step.is_pickup:
		if not task.has("mark"):
			errors.append("setup.task.mark: day %d's task starts at a chalk mark" % day)
		else:
			_position(task.mark, "setup.task.mark", errors)
		names["mark"] = true
	elif task.has("mark"):
		errors.append("setup.task.mark: day %d's task has no chalk mark" % day)
	var perform := ResistanceSteps.by_index(step.index + 1) if step.is_pickup else step
	if task.has("neighbor"):
		if not perform or perform.target_kind != ResistanceSteps.TargetKind.NEIGHBOR:
			errors.append("setup.task.neighbor: only day %d's neighbor has a start to pin"
					% ResistanceHappenings.NEIGHBOR_DAY)
		else:
			_position(task.neighbor, "setup.task.neighbor", errors)
	names["task"] = true
	if perform and perform.target_kind in [ResistanceSteps.TargetKind.EVENT,
			ResistanceSteps.TargetKind.SCAR, ResistanceSteps.TargetKind.NEIGHBOR]:
		names["rider"] = true

## `setup.route_bag`: what she meets on her route, drawn by the director from a bag the recipe rigs
## (`EventDirector.start_recipe_route()`). `marbles` fills the ordinary bag, `pre_bag` is drawn from
## first, `owed` is how many events the route is owed (both bags' marbles by default), and
## `first_after` the seconds of walking before the first is due (the ordinary roll by default).
## Every marble names a row the director sites on the scene's day.
static func _validate_route_bag(recipe: Dictionary, errors: Array[String]) -> void:
	var setup: Dictionary = recipe.get("setup", {})
	if not setup.has("route_bag"):
		return
	if not setup.route_bag is Dictionary:
		errors.append("setup.route_bag must be an object")
		return
	var bag: Dictionary = setup.route_bag
	_keys(bag, ["marbles", "pre_bag", "owed", "first_after"], "setup.route_bag", errors)
	var day := int(setup.get("day", 1))
	for field in ["marbles", "pre_bag"]:
		if not bag.get(field, []) is Array:
			errors.append("setup.route_bag.%s must be an array of catalogue ids" % field)
			continue
		for id: Variant in bag.get(field, []):
			var def := EventCatalogue.by_id(str(id)) if id is String else null
			var mode := def.spawn_mode_on(day) if def else EventDef.SpawnMode.MAP
			if not def or not def.available_on(day) or not mode in [
					EventDef.SpawnMode.AHEAD_OF_PLAYER, EventDef.SpawnMode.TOWARD_PLAYER]:
				errors.append("setup.route_bag.%s: %s is not a row the director sites on day %d"
						% [field, id, day])
	if bag.get("marbles", []) is Array and (bag.get("marbles", []) as Array).is_empty():
		errors.append("setup.route_bag.marbles: the ordinary bag needs a marble")
	if bag.has("owed"):
		_number(bag.owed, "setup.route_bag.owed", 0, 1000, errors, true)
	if bag.has("first_after"):
		_number(bag.first_after, "setup.route_bag.first_after", 0, 600, errors)

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
	_written = result.get("written", result.data)
	built = result
	if "--recipe-draft" in DevFlags.active_args():
		_draft = SceneRecipeDraft.new()
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
	_plan = WalkPlan.make(AutoScreenshot._parse_script(str(data.get("playback", {}).get("walk", ""))),
			Engine.physics_ticks_per_second, bool(data.get("playback", {}).get("smooth", false)))
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
func install(city: City, player: Stroller, baby: Baby,
		resistance: ResistanceDirector = null) -> Array[String]:
	_city = city
	_player = player
	_resistance = resistance
	named = {"player": player}
	var errors: Array[String] = []
	var setup: Dictionary = data.get("setup", {})
	var map := city.map
	for roof: Dictionary in setup.get("roof_fixtures", []):
		var found := false
		for building in city.buildings():
			if building.lot == SceneRecipe.rect(roof.lot):
				found = true
				errors.append_array(building.author_roof_furniture(roof.fixtures))
		if not found:
			errors.append("roof_fixtures.lot: no complete production building at the authored footprint")
	var at := position_of(setup.get("player", {}).get("at", "doorstep"), errors)
	if not errors.is_empty():
		return errors
	var edges := map.witness_only()
	if not map.is_open(map.world_to_tile(at)) or not _inside_extent(at):
		errors.append("setup.player.at must be open ground inside the authored extent")
	var background: Dictionary = setup.get("background", {})
	_select_structures(errors)
	var plans := _event_plans(at, errors)
	city.events.start_recipe(plans, GameState.day, at, data.get("kind", "city") == "escape")
	city.refresh_street_trees()
	map.restore_edges(edges)
	if not errors.is_empty():
		return errors
	_start_the_route(setup)
	for entry: Dictionary in setup.get("events", []):
		for plan in city.events._plans:
			if plan.get_meta("recipe_name", "") == entry.name:
				if not plan.live:
					errors.append("event %s is not live at its required initial position" % entry.name)
				else:
					named[entry.name] = plan.live
	city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"), at,
			bool(background.get("crowd", false)), background.get("crowd_scope", "player") == "city",
			bool(background.get("uniform_walkers", false)), float(background.get("walker_multiplier", 1)))
	if background.get("uniform_walkers", false):
		var area_scale := map.world_size().x * map.world_size().y / pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0) \
				if background.get("crowd_scope", "player") == "city" else 1.0
		var act := Tuning.act_for_day(GameState.day)
		var expected := roundi(Tuning.crowd_pedestrians(act) * area_scale * float(background.get("walker_multiplier", 1))) \
				+ roundi(Tuning.crowd_cars(act) * area_scale)
		if city.crowd.agent_count() != expected:
			errors.append("setup.background: too few eligible sidewalk positions for the requested uniform population")
			return errors
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
	if map.has_stretch():
		city.crowd.use_stretch()
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
	_install_posters(setup.get("posters", []), errors)
	manifest["initial_actors"] = snapshot()
	manifest["installed_events"] = []
	for plan in city.events._plans:
		manifest.installed_events.append({"row": plan.def.id,
				"position": [plan.position.x, plan.position.y], "facing": [plan.facing.x, plan.facing.y]})
	return errors

## `setup.task`, started once her own camera is the one on screen: the boot camera is gone by
## `begin()` and is still current during `install()`, and where the task is placed asks what she
## can see from where she reads the mark, which is later: the mark stands unread and the task is
## placed when she touches it (`_bind_task_names()`). The last night is offered only once the goal
## is met, so a day-14 scene starts with it met. False, with the scene stopped, when the director
## refused it.
func _start_the_task() -> bool:
	if not data.get("setup", {}).has("task"):
		return true
	var task: Dictionary = data.setup.task
	var errors: Array[String] = []
	if not _resistance:
		errors.append("setup.task: this boot has no resistance director")
	var mark := position_of(task.mark, errors) if task.has("mark") else Vector2.INF
	var neighbor := position_of(task.neighbor, errors) if task.has("neighbor") else Vector2.INF
	if errors.is_empty():
		var camera := get_viewport().get_camera_2d()
		if camera:
			camera.force_update_scroll()
		if GameState.is_final_day():
			GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		# The day's task is planned over the whole witness, as a played day plans it: the mark's
		# "reachable from home" and the guard's place are questions about the city, and a stretch's
		# void would answer every one of them no.
		var edges := _city.map.witness_only()
		errors = _resistance.start_recipe_task(GameState.day,
				GameState.day_rng(GameState.day, "resistance"), DevRig.day_length(GameState.day),
				mark, neighbor)
		_city.map.restore_edges(edges)
	if not errors.is_empty():
		manifest["setup_failed"] = true
		for problem in errors:
			print("[SceneRecipe] " + problem)
		write_manifest()
		get_tree().quit(1)
		return false
	_task_from = mark if mark != Vector2.INF else _player.global_position
	manifest["task"] = {"mark": [mark.x, mark.y] if mark != Vector2.INF else null}
	_bind_task_names()
	return true

## Where the task's distance is measured from: the mark, or on the last night where she starts.
var _task_from := Vector2.INF

## Names what the director offers now. A mark stands unread as `mark` until she touches it; the
## task it unlocks is placed at that touch, so `task` and `rider` are named from the tick after,
## and the manifest records where the target was put and which way the arrow points. Called every
## tick, in free play as well as in a scripted one, so an observation finds the task however late
## she reads the mark.
##
## **A task gone after the read is one of two things, told apart by whether it was ever placed.**
## Never placed, the director refused it: the reasons are printed, and a scripted scene stops as a
## failed setup while free play goes on with no task. Placed and then gone, it expired the way a
## played day's task does (`ResistanceDirector._expire()`: day 10's neighbor home before she
## reaches them, a rider finishing, a deadline): the manifest's `task.expired_tick` records when,
## `task` names nothing from then on, and an observation that still asks about it fails on that.
func _bind_task_names() -> void:
	if not _resistance or not data.get("setup", {}).has("task") or manifest.get("setup_failed", false):
		return
	var contact: ContactPoint = _resistance._contact
	if _resistance._read_mark:
		named["mark"] = _resistance._read_mark
	elif contact and contact.step.is_pickup and not contact.is_done:
		named["mark"] = contact
		return
	if (not contact or contact.step.is_pickup) and manifest.task.has("read_tick"):
		if not manifest.task.has("expired_tick"):
			manifest.task["expired_tick"] = tick
			named.erase("task")
			print("[SceneRecipe] setup.task: the task expired at tick %d" % tick)
			write_manifest()
		return
	if not contact or contact.step.is_pickup:
		manifest["setup_failed"] = true
		for problem in _resistance.scene_task_errors():
			print("[SceneRecipe] " + problem)
		print("[SceneRecipe] setup.task: the mark's task has nowhere to go in this scene")
		write_manifest()
		if scripted:
			_active = false
			get_tree().quit(1)
		return
	if named.get("task") == contact:
		return
	named["task"] = contact
	if _resistance._rider:
		named["rider"] = _resistance._rider
	var step := _resistance.current_step()
	var target := _resistance.contact_position()
	var arrow := _resistance.red_arrow_target()
	manifest.task.merge({"step": step.index, "title": step.title,
			"target": [target.x, target.y], "distance": snappedf(_task_from.distance_to(target), 0.01),
			"arrow": [arrow.x, arrow.y] if arrow != Vector2.INF else null, "read_tick": tick})

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

func _install_posters(entries: Array, errors: Array[String]) -> void:
	var fronts := _city.poster_walls().fronts()
	var used := {}
	var recorded: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var at := position_of(entry.at, errors)
		if not errors.is_empty():
			return
		var tile := _city.map.world_to_tile(at)
		if not fronts.has(tile) or not _inside_extent(at) \
				or not _city.map.tile_to_world(tile).is_equal_approx(at) or used.has(tile):
			errors.append("poster must name a distinct production wall cell inside the scene")
			continue
		used[tile] = true
		var kind: int = PosterArt.Kind[str(entry.kind).to_upper()]
		GameState.posters.paste(tile, kind, false, 1)
		recorded.append({"at": [at.x, at.y], "kind": entry.kind})
	_city.poster_walls().refresh()
	manifest["authored_posters"] = recorded

func _inside_extent(at: Vector2) -> bool:
	var map: CityMap = built.map
	if map.has_stretch():
		return map.in_stretch(map.world_to_tile(at))
	return not map.recipe_bounds.has_area() or map.recipe_bounds.has_point(map.world_to_tile(at))

## `setup.route_bag`: the director owes her route the recipe's marbles, drawn from its rigged bag
## by the game's own rules (`EventDirector.start_recipe_route()`). A scene with no route bag keeps
## the director silent, as every scene without one always has.
func _start_the_route(setup: Dictionary) -> void:
	if not setup.has("route_bag"):
		return
	var bag: Dictionary = setup.route_bag
	var marbles: Array = bag.get("marbles", [])
	var pre_bag: Array = bag.get("pre_bag", [])
	var owed := _city.events.start_recipe_route(marbles, pre_bag,
			int(bag.get("owed", marbles.size() + pre_bag.size())), float(bag.get("first_after", -1.0)))
	manifest["route_bag"] = {"marbles": marbles.size(), "pre_bag": pre_bag, "owed": owed}

## Keep only named production structures. The context plan supplies eligibility and geometry,
## never permission to install unrelated walls or checkpoint actors throughout the scene.
func _select_structures(errors: Array[String]) -> void:
	var region := _city.region_plan()
	if not region:
		return
	var setup: Dictionary = data.get("setup", {})
	var selected := RegionPlanner.RegionPlan.new()
	for entry: Dictionary in setup.get("gates", []):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := StreetNetwork.by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.gates: selected street leaves the authored extent")
			continue
		if GameState.day < Tuning.REGION_WALL_FIRST_DAY:
			errors.append("setup.gates: checkpoints are not available on this day")
			continue
		if not region.doors.any(func(door): return door.key() == key):
			errors.append("setup.gates: the selected street is not an eligible production checkpoint; eligible streets: %s" %
					[region.doors.map(func(door): return door.key())])
			continue
		selected.doors.append(segment)
		RegionPlanner._add_door_bodies(_city.map, segment, selected)
	for entry: Dictionary in setup.get("barriers", []):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := StreetNetwork.by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.barriers: selected street leaves the authored extent")
			continue
		if not _city.map.has_street(key) or _city.route_tree().is_on_the_tree(key) \
				or GameState.day < Tuning.REGION_WALL_FIRST_DAY:
			errors.append("setup.barriers: production barriers require an off-route street on an eligible day")
			continue
		selected.walls.append(segment)
		selected.wall_bodies.append_array(SealPlanner.place_hard_on(_city.map, segment,
				"roadblock", entry.end == "a"))
	region.doors = selected.doors
	region.door_bodies = selected.door_bodies
	region.gates = selected.gates
	region.walls = selected.walls
	region.wall_bodies = selected.wall_bodies
	region.alley_doors.clear()
	region.alley_walls.clear()

func _segment_inside_extent(segment: StreetNetwork.Segment) -> bool:
	if _city.map.has_stretch():
		for tile in _city.map.rect_tiles(segment.tile_rect()):
			if not _city.map.in_stretch(tile):
				return false
		return true
	return not _city.map.recipe_bounds.has_area() \
			or _city.map.recipe_bounds.encloses(segment.tile_rect())

func _authored_seals(errors: Array[String]) -> Array[EventScheduler.Planned]:
	var plans: Array[EventScheduler.Planned] = []
	var map := _city.map
	var trees := StreetTrees.footprint_tiles(map)
	var lined := StreetTrees.segment_keys_with_trees(map)
	var emptied: Array[Vector2i] = []
	for entry: Dictionary in data.get("setup", {}).get("seals", []):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := StreetNetwork.by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.seals: selected street leaves the authored extent")
			continue
		var home := ClosurePlanner.home_street(map)
		if not map.has_street(key) or _city.route_tree().is_on_the_tree(key) \
				or (home and key == home.key()) or SealPlanner._is_the_main_road(map, segment):
			errors.append("setup.seals: requires a production off-route, non-home, non-spine street")
			continue
		for candidate in SealPlanner.candidates():
			if candidate.id != entry.candidate:
				continue
			if not SealPlanner._eligible(candidate, GameState.day) \
					or (candidate.id == SealPlanner.FALLEN_TREE_SEAL_ID and not lined.has(key)):
				errors.append("setup.seals: candidate is unavailable on this day or street")
				continue
			var along := SealPlanner._seal_along_tile(map, segment, candidate, trees, emptied)
			plans.append_array(SealPlanner._place(map, segment, candidate, along))
			if candidate.strength == SealPlanner.Strength.HARD:
				map.hold_segment(key)
			else:
				for side in [true, false]:
					SealPlanner._mark_soft_sealed(map, SealPlanner._sidewalk_band_tiles(segment, side, along))
	map.set_seal_tree_pits(emptied)
	return plans

func _event_plans(player_at: Vector2, errors: Array[String],
		standing: Array[EventScheduler.Planned] = []) -> Array[EventScheduler.Planned]:
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
		# The finale plan validates the real escape routes. Its randomly chosen scenery is
		# not an authored scene's event list.
	elif _city.region_plan():
		for body in _city.region_plan().wall_bodies:
			if _inside_extent(body.position):
				plans.append(body)
		for body in _city.region_plan().door_bodies:
			doors.append(body.position)
			if _inside_extent(body.position):
				plans.append(body)
	if not finale:
		plans.append_array(_authored_seals(errors))
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
		if def.id == EventScheduler.WalkSiting.MAST_ROW:
			plan = _mast_placement(def, at, plans, doors)
		elif finale:
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
					int(entry.get("route_seed", 1)), plans, corridor, doors, standing)
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
		if def.id == EventScheduler.WalkSiting.MAST_ROW:
			# Every mast the game stands has an id, and the director's lists and the blackout
			# find a mast by it: a recipe's own, or the one a mast added for day 11 is named by.
			plan.mast_id = str(entry.mast_id) if entry.has("mast_id") \
					else EventScheduler.added_mast_id(plan.position)
		plans.append(plan)
	return plans

## An authored mast stands where the day's masts may, by the checks `EventScheduler._place_masts()`
## makes of a site and nothing wider: the day is `Tuning.MAST_FIRST_DAY` or later; the tile is a
## sidewalk or square tile `MastSites._is_eligible()` would offer (off the home street, its field
## off a calm interior and off every place a region door could stand); it is not closed, not on a
## held street and not on the home block; the mast's field is clear of the day's own doors
## (`EventScheduler.clear_of_the_doors()`); and no body placed before it is too near
## (`EventScheduler._room_around()`). It does not ask what `EventManager.queue_a_mast()`'s
## `WalkSiting` asks beyond those: the calm she has not used and the route junctions and sidewalks
## the day keeps open. The loudspeaker is a scripted row no catalogue roll places, so the ordinary
## placement refuses it.
func _mast_placement(def: EventDef, at: Vector2, prior: Array[EventScheduler.Planned],
		doors: PackedVector2Array) -> EventScheduler.Planned:
	var map := _city.map
	var tile := map.world_to_tile(at)
	if GameState.day < Tuning.MAST_FIRST_DAY \
			or not map.tile_to_world(tile).is_equal_approx(at) \
			or not map.tile_at(tile) in [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE] \
			or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile) \
			or not MastSites._is_eligible(at, map) \
			or not EventScheduler.clear_of_the_doors(at, PackedVector2Array(), doors,
					def.field_reach()):
		return null
	var candidate := EventScheduler._build_placement(def, map, tile, RandomNumberGenerator.new())
	if not candidate or EventScheduler._room_around(candidate, prior) == -INF:
		return null
	return candidate

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
	if not _start_the_task():
		return
	manifest["initial_actors"] = snapshot()
	_record_crowd("initial_crowd")
	print("[SceneRecipe] manifest " + JSON.stringify(manifest, "", true))
	write_manifest()
	if "--recipe-validate" in DevFlags.active_args():
		get_tree().quit(0)
		return
	if not scripted:
		_hand_played = true
		return
	# `install()` positions the player while the boot camera is still current. Camera2D can only
	# reset its smoothed screen centre once the player's camera owns the viewport, which is true
	# here. Settle that state before the excluded moving lead-in begins so a movie never records the
	# camera travelling from its boot position toward an already-moving actor.
	if data.get("playback", {}).get("settled_camera", false):
		_settle_starting_camera()
	var playback: Dictionary = data.get("playback", {})
	var camera: Dictionary = playback.get("camera", {})
	DevRig.apply_zoom(get_viewport().get_camera_2d(), float(camera.get("zoom", 1)))
	if camera.get("fixed", false):
		var offset: Array = camera.get("fixed_offset", [0, 0])
		_install_fixed_camera(Vector2(float(offset[0]), float(offset[1])))
	if camera.has("zoom_out"):
		var zoom := ZoomOutCamera.new()
		_zoom = zoom
		zoom.simulation_clock = elapsed
		add_child(zoom)
		var bounds := _city.map.tile_rect_to_world(Rect2i(Vector2i.ZERO, _city.map.size)).grow(
				float(camera.get("landscape_margin", 0)))
		zoom.setup(get_viewport().get_camera_2d(), bounds, get_viewport().get_visible_rect().size,
				float(camera.zoom_out), float(camera.get("zoom_delay", 0)))
	var title := TrailerText.build(str(playback.get("caption", "")), str(playback.get("title", "")))
	if title:
		add_child(title)
	_active = true
	_observe()
	_apply_input()

func _settle_starting_camera() -> void:
	var starting_camera := get_viewport().get_camera_2d()
	if not starting_camera or not _player:
		return
	starting_camera.offset = Vector2(_player.facing.x,
			_player.facing.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	starting_camera.force_update_scroll()
	starting_camera.reset_smoothing()
	starting_camera.reset_physics_interpolation()
	starting_camera.force_update_scroll()

## Holds a scripted scene on the exact view it begins with. A camera of its own leaves the
## stroller's ordinary follow untouched, so free play and every recipe without `camera.fixed`
## keep the same look-ahead and smoothing behavior.
func _install_fixed_camera(offset := Vector2.ZERO) -> void:
	var starting_camera := get_viewport().get_camera_2d()
	if not starting_camera:
		return
	starting_camera.force_update_scroll()
	var fixed := Camera2D.new()
	fixed.name = "FixedRecipeCamera"
	fixed.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	fixed.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fixed.position = starting_camera.get_screen_center_position() + offset
	fixed.rotation = starting_camera.global_rotation
	fixed.zoom = starting_camera.zoom
	add_child(fixed)
	fixed.make_current()
	fixed.force_update_scroll()
	_fixed_camera = fixed

func _physics_process(_delta: float) -> void:
	if _hand_played and not get_tree().paused:
		tick += 1
		_bind_task_names()
		return
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
	_watch_the_void()
	_watch_the_crowd()
	if _draft:
		var step := _resistance.current_step() if _resistance else null
		var walking_home: Node2D = named.get("rider") if step and not step.is_pickup \
				and step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR else null
		_draft.record(_player, _city, walking_home if is_instance_valid(walking_home) else null)
	if _capture_tick >= 0 and tick >= _capture_tick:
		prepare_capture()
		return
	if tick >= _duration_ticks:
		_active = false
		_release_input()
		manifest["playback_complete"] = true
		manifest["final_actors"] = snapshot()
		_record_crowd("final_crowd")
		write_manifest()
		if _draft:
			get_tree().quit(_write_the_draft())
			return
		get_tree().quit(0)
		return
	_apply_input()

func _apply_input() -> void:
	WalkPlan.press(_plan.input_at(tick))

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
		manifest[key.trim_suffix("_crowd") + "_activity"] = activity_snapshot()

## Counts only live subjects whose ground positions are in the current picture. A visual review
## still checks occlusion and legibility; whole-field totals alone cannot establish a busy view.
func activity_snapshot() -> Dictionary:
	var result := {"visible_walkers": 0, "visible_cars": 0, "moving_crowd": 0,
			"walkers_left": 0, "walkers_right": 0,
			"walker_streets": {},
			"visible_events": {}}
	var view := get_viewport().get_visible_rect()
	var transform := get_viewport().get_canvas_transform()
	for agent in _city.crowd.agents():
		if not view.has_point(transform * agent.global_position):
			continue
		var key := "visible_cars" if agent.kind == CrowdAgent.Kind.CAR else "visible_walkers"
		result[key] += 1
		if agent.kind == CrowdAgent.Kind.WALKER:
			var street := "%s%d" % ["v" if agent.travelling_vertically() else "h", agent.get("_corridor")]
			if not result.walker_streets.has(street):
				result.walker_streets[street] = {"walkers": 0, "moving": 0}
			result.walker_streets[street].walkers += 1
			result.walker_streets[street].moving += int(not agent.velocity().is_zero_approx())
			result["walkers_left" if (transform * agent.global_position).x < view.size.x * 0.5
					else "walkers_right"] += 1
		if not agent.velocity().is_zero_approx():
			result.moving_crowd += 1
	for event in _city.events.instances():
		if view.has_point(transform * event.global_position):
			result.visible_events[event.def.id] = int(result.visible_events.get(event.def.id, 0)) + 1
	return result

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
		elif actor is ContactPoint:
			result[label]["done"] = actor.is_done
		elif actor is EventInstance:
			result[label]["row"] = actor.def.id
			result[label]["telegraphing"] = actor.is_telegraphing()
			result[label]["pursuing"] = actor.def.pursues and not actor.is_waiting() \
					and not actor.is_telegraphing() and not actor.is_finished and not actor.is_leaving
	return result

func _observe() -> void:
	_bind_task_names()
	for check: Dictionary in _observations:
		if check.condition == "appeared" and not _appeared.has(check.subject):
			var watched := subject_of(str(check.subject))
			if watched and _she_can_see(watched):
				_appeared[check.subject] = tick
	for check: Dictionary in _observations:
		if int(check.tick) != tick:
			continue
		var actor := subject_of(str(check.subject))
		var passed := actor != null
		if check.condition == "appeared":
			# Asked of the past, so the subject may be gone by now: a cat that crossed and left.
			passed = _appeared.has(check.subject)
		elif passed:
			match check.condition:
				"visible":
					passed = _in_the_picture(actor.global_position)
				"crowd":
					var moving := _moving_in_the_picture()
					passed = moving.walkers >= int(check.get("walkers", 0)) \
							and moving.cars >= int(check.get("cars", 0))
				"moving":
					passed = _last_positions.has(check.subject) and actor.global_position.distance_to(
							_last_positions[check.subject]) > 0.01
				"running":
					passed = actor is Stroller and actor.current_speed() > Tuning.WALK_SPEED
				"carrying":
					passed = actor is Stroller and actor.carrying
				"asleep", "awake":
					# The baby's own state, the one `Baby` sets by the game's sleep rule and the
					# pram's zzz is drawn from -- never a recipe-authored indicator.
					var baby := actor.get_node_or_null("Baby") as Baby if actor is Stroller else null
					passed = baby != null and (baby.state == GameEnums.BabyState.ASLEEP) \
							== (check.condition == "asleep")
				"pursuing":
					passed = actor is EventInstance and actor.def.pursues \
							and not actor.is_telegraphing() and not actor.is_waiting() \
							and not actor.is_finished and not actor.is_leaving
				"near_player":
					# What ties one actor to her: a pursuer that closes on her stays this close.
					passed = is_instance_valid(_player) and actor.global_position.distance_to(
							_player.global_position) <= float(check.distance)
				"near", "beyond":
					var errors: Array[String] = []
					var target := position_of(check.at, errors)
					var distance := actor.global_position.distance_to(target)
					passed = errors.is_empty() and (distance <= float(check.distance)
							if check.condition == "near" else distance >= float(check.distance))
				"off_screen":
					passed = not _box_on_screen(actor.global_position,
							ResistanceDirector.TASK_HALF_EXTENT)
				"clear_of_both_views":
					passed = not _box_in_either_view(actor.global_position,
							Vector2(float(check.half[0]), float(check.half[1])))
				"offered":
					passed = actor is ContactPoint and not actor.is_done and _resistance != null \
							and _resistance._contact == actor
				"done":
					passed = actor is ContactPoint and actor.is_done \
							and actor.step.index in GameState.completed_resistance_steps
				"arrowed":
					passed = _resistance != null and _resistance.red_arrow_target() != Vector2.INF \
							and _resistance.red_arrow_target().is_equal_approx(actor.global_position)
				"unarrowed":
					passed = _resistance != null and _resistance.red_arrow_target() == Vector2.INF
		var record := check.duplicate(true)
		record["passed"] = passed
		if check.condition == "appeared" and passed:
			record["first_in_the_picture"] = _appeared[check.subject]
		record["state"] = snapshot().get(check.subject, {})
		if is_instance_valid(_player):
			record["player_at"] = [snappedf(_player.global_position.x, 0.01),
					snappedf(_player.global_position.y, 0.01)]
		if actor and not named.has(check.subject):
			record["state"] = {"position": [snappedf(actor.global_position.x, 0.0001),
					snappedf(actor.global_position.y, 0.0001)]}
		manifest.observations.append(record)
		if not passed and _draft:
			print("[SceneRecipe] draft: unmet on the whole city, walked on: " + JSON.stringify(record))
		elif not passed:
			print("[SceneRecipe] unmet observation: " + JSON.stringify(record))
			write_manifest()
			_active = false
			get_tree().quit(1)
	for label: String in named:
		if is_instance_valid(named[label]):
			_last_positions[label] = (named[label] as Node2D).global_position
	for check: Dictionary in _observations:
		var label := str(check.subject)
		if label.begins_with(ROW_SUBJECT):
			var summoned := subject_of(label)
			if summoned:
				_last_positions[label] = summoned.global_position

## The subjects an `appeared` observation asks about that have been in the picture, and the first
## tick each was: a route event the rigged bag hands out comes when the director's pacing and siting
## say, so a scene asks that she saw it by a tick rather than at one. In the picture, not merely in
## the world: a cat sited ahead of her that crouches out of view and never runs is an event she
## never meets, and the scene would be as empty as it looks.
var _appeared := {}

## Whether a world point is in the picture, a margin inside its edges.
func _in_the_picture(at: Vector2) -> bool:
	return get_viewport().get_visible_rect().grow(-20).has_point(
			get_viewport().get_canvas_transform() * at)

## Whether any of the actor's drawing is visible (a tile-sized box for other named actors):
## the actual viewport transformed back through the current camera, less the corners the joystick
## scheme's controls cover. Taking all four corners follows zoom and the quarter-turn used for a
## portrait presentation; using the actor's drawn box keeps this the same overlap question the
## page's encounter counter asks of what she meets.
func _she_can_see(actor: Node2D) -> bool:
	var at := actor.global_position
	var controls := get_tree().get_first_node_in_group(HelpText.CONTROLS_GROUP) as TouchControls
	var joystick := controls != null and controls.controls_mode() == ControlsMode.Mode.JOYSTICK
	var box: Rect2 = actor.drawn_box() if actor is EventInstance else Rect2(-Vector2.ONE * 16, Vector2.ONE * 32)
	box.position += at
	return VisibleView.visible_share(box, _camera_world_rect(), joystick) > 0.0

## The axis-aligned world rectangle the camera currently draws. The game's presentation is either
## unturned or a quarter-turn, so the inverse-transformed viewport corners still bound the exact
## world rectangle; expanding from every corner also avoids assuming which one becomes its top-left.
func _camera_world_rect() -> Rect2:
	var screen := get_viewport().get_visible_rect()
	var to_world := get_viewport().get_canvas_transform().affine_inverse()
	var top_left := to_world * screen.position
	var world := Rect2(top_left, Vector2.ZERO)
	world = world.expand(to_world * Vector2(screen.end.x, screen.position.y))
	world = world.expand(to_world * screen.end)
	world = world.expand(to_world * Vector2(screen.position.x, screen.end.y))
	return world

## How many walkers and cars are moving in the picture now.
func _moving_in_the_picture() -> Dictionary:
	var counts := {"walkers": 0, "cars": 0}
	if not _city or not _city.crowd:
		return counts
	for agent in _city.crowd.agents():
		if not agent.velocity().is_zero_approx() and _in_the_picture(agent.global_position):
			counts["cars" if agent.kind == CrowdAgent.Kind.CAR else "walkers"] += 1
	return counts

## The node an observation names: a named actor, or for `row:<id>` the first live, unfinished
## instance of that catalogue row in the world. Null when there is none.
func subject_of(label: String) -> Node2D:
	if not label.begins_with(ROW_SUBJECT):
		return named[label] if is_instance_valid(named.get(label)) else null
	if not _city or not _city.events:
		return null
	for instance in _city.events.instances():
		if instance.def.id == label.trim_prefix(ROW_SUBJECT) and not instance.is_finished:
			return instance
	return null

## Whether any part of a box `half` either side of `centre` is in the picture: its centre or a
## corner, the test `ResistanceDirector._box_shows()` puts a task's target through as it is placed.
func _box_on_screen(centre: Vector2, half: Vector2) -> bool:
	var view := get_viewport().get_visible_rect()
	var transform := get_viewport().get_canvas_transform()
	for corner: Vector2 in [centre, centre + half, centre - half, centre + Vector2(half.x, -half.y),
			centre + Vector2(-half.x, half.y)]:
		if view.has_point(transform * corner):
			return true
	return false

## Whether any part of a box `half` either side of `centre` is inside the world her camera shows,
## centred on where the camera looks: the 1280x720 design box at the camera's zoom, 640x360 world
## pixels at zoom 2. That is the world in both presentations. A portrait touch screen presents the
## same box turned a quarter (`main._apply_orientation()` turns the camera with
## `ScreenOrientation.apply_to_camera()`), never a narrower and taller piece of the world, and a
## portrait window without touch letterboxes the same box, so one box answers for both, and the
## answer does not depend on the window a check happens to run in.
func _box_in_either_view(centre: Vector2, half: Vector2) -> bool:
	var camera := get_viewport().get_camera_2d()
	var looking := camera.get_screen_center_position() if camera else _player.global_position
	var zoom := camera.zoom.x if camera else 1.0
	var size := ScreenOrientation.DESIGN_SIZE / zoom
	return Rect2(looking - size * 0.5, size).intersects(Rect2(centre - half, half * 2.0))

## Every body the scene put in the world to wait on ground the stretch omits
## (`CityMap.is_void()`) — a guard placed while she walks, standing where the whole city has a
## street and the scene has none — with its tile and row: the manifest's `in_the_void`, which
## `tools/scene-draft.sh` adds to the next draft (`draft.include`) so that nothing waiting for her
## stands in the void. Checked each tick until a body is recorded: a pursuer on its way to her
## from off screen comes down streets the scene does not have and is not one of these.
var _in_the_void := {}

func _watch_the_void() -> void:
	if not _city or not _city.map.has_stretch():
		return
	for instance in _city.events.instances():
		if _in_the_void.has(instance):
			continue
		var tile := _city.map.world_to_tile(instance.global_position)
		if instance.is_waiting() and _city.map.is_void(tile):
			_in_the_void[instance] = true
			var found: Array = manifest.get("in_the_void", [])
			found.append({"tile": [tile.x, tile.y], "row": instance.def.id, "tick": tick})
			manifest["in_the_void"] = found

## Where each of the crowd stood last tick, to catch one that leaves or enters in view.
var _crowd_was := {}
## How far a walker's or a car's picture reaches past its centre, for `_watch_the_crowd()`: a tile,
## a car's half length and its shadow. Less than the room an agent keeps when it leaves
## (`CrowdAgent.ENTRY_PICTURE_ROOM`), since the camera moves on between the frame it left on and the
## tick that asks.
const PICTURE_REACH := float(Tuning.TILE_SIZE)

## **Nothing in a stretch's crowd appears or vanishes where she can see it** *(the player's rule,
## PR #597)*: a walker or car that moves further in one tick than any of them walks or drives — a
## recycle — while it stood, or now stands, in either view (`CrowdAgent._beyond_every_view()`) is
## recorded in the manifest's `seen_to_jump`, which `tests/test_scene_recipe_stretch_crowd.gd` holds
## empty over every stretch scene.
func _watch_the_crowd() -> void:
	if not _city or not _city.map.has_stretch() or not _city.crowd:
		return
	for agent in _city.crowd.agents():
		var at := agent.global_position
		if _crowd_was.has(agent):
			var was: Vector2 = _crowd_was[agent]
			if was.distance_to(at) > 2.0 * Tuning.TILE_SIZE \
					and not (agent._beyond_every_view(was, PICTURE_REACH)
					and agent._beyond_every_view(at, PICTURE_REACH)):
				var jumps: Array = manifest.get("seen_to_jump", [])
				jumps.append({"tick": tick, "from": [snappedf(was.x, 0.1), snappedf(was.y, 0.1)],
						"to": [snappedf(at.x, 0.1), snappedf(at.y, 0.1)],
						"kind": "car" if agent.kind == CrowdAgent.Kind.CAR else "walker"})
				manifest["seen_to_jump"] = jumps
		_crowd_was[agent] = at

## `--recipe-draft FILE`: the stretch the walk just took, written as a recipe (`SceneRecipeDraft`).
## Answers the exit code.
func _write_the_draft() -> int:
	var problems: Array[String] = []
	var pinned: Array[Vector2] = []
	var errors: Array[String] = []
	for field: String in data.get("setup", {}).get("task", {}):
		pinned.append(position_of(data.setup.task[field], errors))
	var drafted := _draft.compose(_written, _city, start_position(), pinned, problems)
	for problem in problems:
		print("[SceneRecipe] draft: " + problem)
	var path := DevFlags._word_after("--recipe-draft")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("[SceneRecipe] cannot write the draft: " + path)
		return 1
	file.store_string(SceneRecipeDraft.to_json(drafted) + "\n")
	file.close()
	var stretch: Dictionary = drafted.stretch
	var tiles := 0
	for type: String in stretch.tiles:
		for run: Array in stretch.tiles[type]:
			tiles += int(run[2]) - int(run[1]) + 1
	print("[SceneRecipe] draft written to %s: %d tiles, %d buildings, %d street trees, %d props, %d litter, %d cracks, %d posters, %d walkers and cars"
			% [path, tiles, stretch.buildings.size(), stretch.trees.size(), stretch.props.size(),
			stretch.litter.size(), stretch.cracks.size(), drafted.setup.posters.size(),
			drafted.setup.actors.size()])
	return 0

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
