class_name SceneRecipeRuntime
extends AuthoredScene
## One saved setup feeds free play, headless assertions and frame-locked recording. Playback
## starts only after construction and scenery preparation; observations use the game's physics ticks.
## The authored scene `RunFlow` is configured with when the boot was handed `--recipe`.

const DIRECTIONS := {"north": Vector2.UP, "south": Vector2.DOWN,
		"east": Vector2.RIGHT, "west": Vector2.LEFT}
const OWNED_FLAGS := ["--seed", "--day", "--spawn", "--parent", "--meters", "--walk",
		"--flee", "--route", "--force", "--follow", "--zoom", "--zoom-out", "--caption",
		"--title-card", "--start-escape", "--blackout", "--overview", "--day-length",
		"--press", "--tap", "--ending", "--quit-when-still", "--skip", "--smooth-walk"]

var _data: Dictionary = {}
## The walk the scene was installed into (`install()`), handed in by the run flow.
var _walk_spec: DaySpec = null
## What the recipe builder made of the recipe's city section: its map and the anchors' positions.
var _built: Dictionary = {}
## What the scene records of itself, which is how it is read from outside: written to the file
## `--recipe-manifest PATH` names at `begin()`, at a capture, at the end, when the task's mark is read
## or expires, and at every failure.
var _manifest: Dictionary = {}
## The actors an observation can name, by their recipe names (`player`, an event's or an actor's
## `name`, `mark`, `task`, `rider`, `truck_N`).
var _named: Dictionary = {}
## The recipe's entry for each event plan the scene built (the plan to its authored entry), which
## names the plan's event, and whether it is held, charging or relentless, once the walk starts.
var _entry_of_plan: Dictionary = {}
var _scripted := false
## The physics ticks the scene has counted: its clock (`elapsed()`).
var _tick := 0
## The run's configuration with this recipe on top, handed in by `configure()`: where the manifest
## and a draft go, whether to validate and quit, a screenshot's tick and a day's length.
var _config: RunConfig
## The run's catalogue (`EventCatalogue`), the one every row the scene stands is read from: the
## composition root's own, handed in by `configure()`.
var _rows: EventCatalogue
## The run the scene is staged in — its day, its streams, its resistance and its walls — handed in
## by `configure()`.
var _run: RunState
## What the scene ends the game with, handed in by `configure()`, called with the exit status: `main`'s
## own way of ending it (`Main._end_with()`). Empty, the scene quits the tree itself.
var _end_game := Callable()
var _player: Stroller
## The world the scene was installed into (`install()`): its map, today's streets, the city scene's
## dressing, its events, its crowd and its poster walls, her and the baby.
var _world: DayWorld
## The scene's one ground for a row (`EventScheduler.row_ground()`): which tiles a row may stand
## on, made once by `_event_plans()` and handed to every authored row's placement, to the
## escape's actors' and to the scene's walk (`EventManager.start_recipe()`), so none of the
## three scans the map again. It is made inside `install()`'s `witness_only()` bracket, and
## keeps each answer from the first time it is asked: a question the install asks (every authored
## row's) is answered with a bounded scene's exterior and a stretch's void off, and the walk
## keeps that answer; a question first asked while she walks (day 8's burnt-building front) is
## answered with the edges shown, as its side test reads `tile_at()`, `pavement_inward()` and
## `is_street()`.
var _ground: RowGround
## The route tree and the day's locations the recipe's rows are placed against, made once by
## `_event_plans()` and handed to the scene's walk beside the ground, so a siting made as she
## walks grows and lays out none of its own. A scene with no route tree lays its locations out
## under a corridor that answers none, so it hands the walk neither and the walk makes both
## when it needs them.
var _route_tree: RouteTree
var _locations: DayLocations
## Where the army column's lines go, handed in by `use_trace()`; a trace that writes nowhere until then.
var _trace := RunTrace.new()
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
## The recipe as its file has it, which a draft run writes its stretch into; `_data` is the copy it
## plays (`SceneRecipeDraft.base_of()`).
var _written: Dictionary = {}

## The recipe at `path` loaded, validated against the run's catalogue `rows` and built
## (`RecipeCityBuilder.build()`), or its errors.
static func load_recipe(rows: EventCatalogue, path: String,
		args: PackedStringArray) -> Dictionary:
	var loaded := SceneRecipe.load_file(path, "--recipe-draft" in args)
	var load_errors: Array = loaded.errors
	if not load_errors.is_empty():
		return loaded
	var recipe: Dictionary = loaded.data
	var written := recipe
	if "--recipe-draft" in args:
		recipe = SceneRecipeDraft.base_of(recipe)
	var errors := _validate_runtime(rows, recipe)
	for flag: String in OWNED_FLAGS:
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
	var result := RecipeCityBuilder.build(rows, recipe)
	result.data = recipe
	result.written = written
	return result

static func _validate_runtime(rows: EventCatalogue, recipe: Dictionary) -> Array[String]:
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
	for key: String in ["player", "background", "progression"]:
		if not setup.get(key, {}) is Dictionary:
			errors.append("setup.%s must be an object" % key)
	if not errors.is_empty():
		return errors
	var player: Dictionary = setup.get("player", {})
	_keys(player, ["at", "facing", "excitement", "sleep"], "setup.player", errors)
	_position(player.get("at", "doorstep"), "setup.player.at", errors)
	if not DIRECTIONS.has(player.get("facing", "south")):
		errors.append("setup.player.facing must name a cardinal direction")
	for key: String in ["excitement", "sleep"]:
		_number(player.get(key, 0), "setup.player." + key, 0, 100, errors)
	var background: Dictionary = setup.get("background", {})
	_keys(background, ["events", "crowd", "crowd_scope", "uniform_walkers", "walker_multiplier"], "setup.background", errors)
	if background.get("events", false) != false:
		errors.append("setup.background.events: authored scenes require explicit event selections")
	for key: String in ["crowd", "uniform_walkers"]:
		if not background.get(key, false) is bool:
			errors.append("setup.background.%s must be boolean" % key)
	_number(background.get("walker_multiplier", 1), "setup.background.walker_multiplier", 1, 4, errors)
	if (background.has("walker_multiplier") or background.has("uniform_walkers")) and not background.get("crowd", false):
		errors.append("setup.background: walker controls require crowd")
	if not background.get("crowd_scope", "player") in ["player", "city"]:
		errors.append("setup.background.crowd_scope must be player or city")
	if background.get("crowd_scope", "player") == "city" and (
			not background.get("crowd", false) or _object(recipe, "extent").get("scope", "") != "full"):
		errors.append("setup.background.crowd_scope city requires crowd and full extent")
	if _object(recipe, "extent").get("scope", "") in ["bounded", "stretch"] and (
			background.get("crowd", false)):
		errors.append("bounded and stretch scenes require authored actors/events; random background activity needs full extent")
	_validate_route_bag(rows, recipe, errors)
	var progression: Dictionary = setup.get("progression", {})
	_keys(progression, ["blackout", "escape_part"], "setup.progression", errors)
	if not progression.get("blackout", false) is bool:
		errors.append("setup.progression.blackout must be boolean")
	if recipe.get("kind", "city") == "escape":
		if not _list(_object(recipe, "city"), "closures").is_empty():
			errors.append("city.closures is unsupported for escape scenes; select explicit finale events")
		if progression.get("escape_part", "city") != "city":
			errors.append("setup.progression.escape_part: recipes currently support the real city escape")
		if int(setup.get("day", 1)) != Tuning.RUN_LENGTH_DAYS:
			errors.append("setup.day: the escape requires the final day's progression")
	elif progression.has("escape_part"):
		errors.append("setup.progression.escape_part requires kind escape")
	_number(setup.get("signal_time", 0), "setup.signal_time", 0, 86400, errors)
	# No map is built yet, so the keys are checked against a lattice of their own: the same streets
	# every city's map holds (`CityMap.street_network()`).
	var lattice := StreetNetwork.new()
	var structure_streets := {}
	for collection: String in ["seals", "gates", "barriers"]:
		if not setup.get(collection, []) is Array:
			errors.append("setup.%s must be an array" % collection)
			continue
		if recipe.get("kind", "city") == "escape" and not _list(setup, collection).is_empty():
			errors.append("setup.%s is unsupported for escape scenes; select explicit finale events" % collection)
		var seen := {}
		for entry_value: Variant in _list(setup, collection):
			if not entry_value is Dictionary:
				errors.append("setup.%s entries must be objects" % collection)
				continue
			var entry: Dictionary = entry_value
			_keys(entry, ["segment", "candidate"] if collection == "seals" else
					(["segment", "end"] if collection == "barriers" else ["segment"]), collection, errors)
			if not SceneRecipe.tuple(entry.get("segment"), 3, true):
				errors.append("setup.%s requires segment [x,y,axis]" % collection)
				continue
			var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
			if not lattice.by_key(key) or seen.has(key):
				errors.append("setup.%s has an unknown or duplicate street" % collection)
			seen[key] = true
			if structure_streets.has(key):
				errors.append("setup structures select the same street in multiple collections")
			structure_streets[key] = true
			if collection == "seals":
				if not SealPlanner.candidate_named(str(entry.get("candidate", ""))):
					errors.append("setup.seals requires an existing production candidate")
			elif collection == "barriers" and entry.get("end") not in ["a", "b"]:
				errors.append("setup.barriers requires end a or b")
	if not setup.get("roof_fixtures", []) is Array:
		errors.append("setup.roof_fixtures must be an array")
	else:
		var roof_lots := {}
		for roof_value: Variant in _list(setup, "roof_fixtures"):
			if not roof_value is Dictionary:
				errors.append("setup.roof_fixtures entries must be objects")
				continue
			var roof: Dictionary = roof_value
			_keys(roof, ["lot", "fixtures"], "setup.roof_fixtures", errors)
			if not SceneRecipe.tuple(roof.get("lot"), 4, true) or not roof.get("fixtures") is Array:
				errors.append("setup.roof_fixtures requires a tile lot [x,y,w,h] and fixtures array")
				continue
			var lot := SceneRecipe.rect(roof.lot)
			if roof_lots.has(lot):
				errors.append("setup.roof_fixtures duplicates a lot")
			roof_lots[lot] = true
			for fixture_value: Variant in roof.fixtures:
				if not fixture_value is Dictionary:
					errors.append("setup.roof_fixtures.fixtures entries must be objects")
					continue
				var fixture: Dictionary = fixture_value
				_keys(fixture, ["cell", "kind"], "roof fixture", errors)
				if not SceneRecipe.tuple(fixture.get("cell"), 2, true) \
						or not Building.RECIPE_FURNITURE_KINDS.has(str(fixture.get("kind", "")).to_upper()):
					errors.append("roof fixture requires integer cell [column,row] and an existing kind")
	if not setup.get("posters", []) is Array:
		errors.append("setup.posters must be an array")
	else:
		for entry_value: Variant in _list(setup, "posters"):
			if not entry_value is Dictionary:
				errors.append("setup.posters entries must be objects")
				continue
			var entry: Dictionary = entry_value
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
		var column_value: Variant = setup["column"]
		if not column_value is Dictionary:
			errors.append("setup.column must be an object")
		else:
			var column: Dictionary = column_value
			_keys(column, ["at", "direction"], "setup.column", errors)
			_position(column.get("at"), "setup.column.at", errors)
			if not column.get("direction") in ["north", "south"]:
				errors.append("setup.column.direction must be north or south")
			if int(setup.get("day", 1)) != ResistanceHappenings.COLUMN_DAY \
					or recipe.get("kind", "city") != "city" \
					or _object(recipe, "extent").get("scope", "") != "full":
				errors.append("setup.column requires day 13 and a full city scene")
		for i in Tuning.COLUMN_TRUCKS:
			names["truck_%d" % (i + 1)] = true
	var mast_ids := {}
	for collection: String in ["events", "actors"]:
		if not setup.get(collection, []) is Array:
			errors.append("setup.%s must be an array" % collection)
			continue
		for entry_value: Variant in _list(setup, collection):
			var where: String = "setup." + collection
			if not entry_value is Dictionary:
				errors.append(where + " entries must be objects")
				continue
			var entry: Dictionary = entry_value
			_keys(entry, ["name", "row", "at", "path", "age", "route_seed", "mast_id", "heat", "hold", "charging", "relentless"] if collection == "events"
					else ["name", "kind", "at", "direction", "speed"], where, errors)
			var label: Variant = entry.get("name")
			if not label is String or str(label).is_empty() or names.has(label):
				errors.append(where + ".name must be a unique nonempty name")
			else:
				names[label] = true
			_position(entry.get("at"), where + ".at", errors)
			if collection == "events":
				if not entry.get("row") is String or not rows.by_id(str(entry.get("row", ""))):
					errors.append(where + ".row is an unknown catalogue identifier")
				if entry.has("mast_id"):
					# A mast's identity is what the day's task and its arrow answer to, so two
					# authored masts need two ids, and only a loudspeaker is a mast.
					var mast_id: Variant = entry["mast_id"]
					if entry.get("row") != "loudspeaker":
						errors.append(where + ".mast_id belongs to a loudspeaker row")
					elif not mast_id is String or str(mast_id).is_empty() or mast_ids.has(mast_id):
						errors.append(where + ".mast_id must be a unique nonempty string")
					else:
						mast_ids[mast_id] = true
				_number(entry.get("age", 0), where + ".age", 0, 3600, errors)
				_number(entry.get("route_seed", 1), where + ".route_seed", 0, 2147483647, errors, true)
				_number(entry.get("heat", 0), where + ".heat", 0, Tuning.RESISTANCE_GOAL, errors, true)
				if entry.has("hold") and not entry["hold"] is bool:
					errors.append(where + ".hold must be true or false")
				if entry.has("charging") and not entry["charging"] is bool:
					errors.append(where + ".charging must be true or false")
				if entry.has("relentless") and not entry["relentless"] is bool:
					errors.append(where + ".relentless must be true or false")
				if not entry.get("path", []) is Array:
					errors.append(where + ".path must be an array")
				else:
					for point: Variant in _list(entry, "path"):
						_position(point, where + ".path", errors)
			else:
				if not entry.get("kind") in ["walker", "car"]:
					errors.append(where + ".kind must be walker or car")
				if not DIRECTIONS.has(entry.get("direction")):
					errors.append(where + ".direction must be cardinal")
				if entry.has("speed"):
					_number(entry["speed"], where + ".speed", 0, 1000, errors)
	if not errors.is_empty():
		return errors
	if setup.has("column") and not _list(setup, "events").is_empty():
		errors.append("setup.column cannot accompany other pinned events")
	if background.get("crowd", false) and not _list(setup, "actors").is_empty():
		for actor: Dictionary in _list(setup, "actors"):
			if not background.get("uniform_walkers", false) or actor["kind"] != "walker":
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
	if not walk is String or (not str(walk).is_empty() and AutoScreenshot.parse_script(walk).is_empty()):
		errors.append("playback.walk is not a valid timed movement script")
	if not playback.get("smooth", false) is bool:
		errors.append("playback.smooth must be boolean")
	if not playback.get("settled_camera", false) is bool:
		errors.append("playback.settled_camera must be boolean")
	for key: String in ["caption", "title"]:
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
				or not SceneRecipe.tuple(camera["fixed_offset"], 2, false)):
			errors.append("playback.camera.fixed_offset requires fixed true and [x,y] numbers")
		for key: String in camera:
			if key in ["fixed", "fixed_offset"]:
				continue
			_number(camera[key], "playback.camera." + key,
					0 if key in ["zoom_delay", "landscape_margin"] else 0.001,
					4096 if key == "landscape_margin" else 240, errors)
	if not playback.get("observations", []) is Array:
		errors.append("playback.observations must be an array")
	else:
		for check_value: Variant in playback.get("observations", []):
			if not check_value is Dictionary:
				errors.append("playback.observations entries must be objects")
				continue
			var check: Dictionary = check_value
			_keys(check, ["tick", "subject", "condition", "at", "distance", "half", "walkers", "cars"],
					"observation", errors)
			_number(check.get("tick"), "observation.tick", 0,
					float(playback.get("duration", 5)) * Engine.physics_ticks_per_second, errors, true)
			var subject: Variant = check.get("subject")
			if not names.has(subject) and not (subject is String
					and str(subject).begins_with(ROW_SUBJECT)
					and rows.by_id(str(subject).trim_prefix(ROW_SUBJECT))):
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
				for key: String in ["walkers", "cars"]:
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
					% ResistanceSteps.NEIGHBOR_DAY)
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
static func _validate_route_bag(rows: EventCatalogue, recipe: Dictionary,
		errors: Array[String]) -> void:
	var setup: Dictionary = recipe.get("setup", {})
	if not setup.has("route_bag"):
		return
	if not setup.route_bag is Dictionary:
		errors.append("setup.route_bag must be an object")
		return
	var bag: Dictionary = setup.route_bag
	_keys(bag, ["marbles", "pre_bag", "owed", "first_after"], "setup.route_bag", errors)
	var day := int(setup.get("day", 1))
	for field: String in ["marbles", "pre_bag"]:
		if not bag.get(field, []) is Array:
			errors.append("setup.route_bag.%s must be an array of catalogue ids" % field)
			continue
		for id: Variant in bag.get(field, []):
			var def := rows.by_id(str(id)) if id is String else null
			var mode := def.spawn_mode_on(day) if def else EventDef.SpawnMode.MAP
			if not def or not def.available_on(day) or not (def.is_sent_ahead() or mode in [
					EventDef.SpawnMode.AHEAD_OF_PLAYER, EventDef.SpawnMode.TOWARD_PLAYER]):
				errors.append("setup.route_bag.%s: %s is not a row the director sites on day %d"
						% [field, id, day])
	if bag.get("marbles", []) is Array and (bag.get("marbles", []) as Array).is_empty():
		errors.append("setup.route_bag.marbles: the ordinary bag needs a marble")
	if bag.has("owed"):
		_number(bag.owed, "setup.route_bag.owed", 0, 1000, errors, true)
	if bag.has("first_after"):
		_number(bag.first_after, "setup.route_bag.first_after", 0, 600, errors)

## `from[key]` as an object, empty where it holds none: a recipe's section as the file has it.
static func _object(from: Dictionary, key: String) -> Dictionary:
	var value: Variant = from.get(key, {})
	return value if value is Dictionary else {}

## `from[key]` as a list, empty where it holds none.
static func _list(from: Dictionary, key: String) -> Array:
	var value: Variant = from.get(key, [])
	return value if value is Array else []

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
	if not value is Array or (value as Array).size() != 2:
		errors.append(where + " must name an anchor or be [world_x, world_y]")
		return
	_number(value[0], where + "[0]", -1000000, 1000000, errors)
	_number(value[1], where + "[1]", -1000000, 1000000, errors)

## The trace the army column's lines go to (`ResistanceHappenings.use_trace()`): the run's own, as
## `main` hands the city's.
func use_trace(trace: RunTrace) -> void:
	_trace = trace

func configure(rows: EventCatalogue, result: Dictionary, config: RunConfig, run: RunState,
		end_game := Callable()) -> void:
	_rows = rows
	_config = config
	_run = run
	_end_game = end_game
	_data = result.data
	_written = result.get("written", result.data)
	_built = result
	if config.recipe_draft_path() != "":
		_draft = SceneRecipeDraft.new(rows)
	var built_manifest: Dictionary = result.manifest
	_manifest = built_manifest.duplicate(true)
	_scripted = config.plays_the_recipe_scripted()
	_manifest["recipe"] = _data.get("name", "")
	_manifest["recipe_sha256"] = JSON.stringify(_data, "", true).sha256_text()
	_manifest["engine"] = Engine.get_version_info().string
	_manifest["physics_ticks_per_second"] = Engine.physics_ticks_per_second
	_manifest["playback_complete"] = false
	_manifest["observations"] = []
	_manifest["setup"] = _setup().duplicate(true)
	_manifest["anchors"] = {}
	for label: String in result.anchors:
		var at: Vector2 = result.anchors[label]
		_manifest.anchors[label] = [at.x, at.y]
	_plan = WalkPlan.make(AutoScreenshot.parse_script(str(_playback().get("walk", ""))),
			Engine.physics_ticks_per_second, bool(_playback().get("smooth", false)))
	_observations = _playback().get("observations", [])
	_duration_ticks = roundi(float(_playback().get("duration", 5)) * Engine.physics_ticks_per_second)
	if config.screenshot_path() != "":
		_capture_tick = ceili(maxf(config.rig_after(), 0.0) * Engine.physics_ticks_per_second
				- 0.00001)
	# begin() supplies the first input; subsequent inputs are queued after the world's tick.
	# Observations and completion therefore see the tick they name, including the final one.
	process_physics_priority = 100
	# The observer must report a gameplay stop rather than hang with the paused world.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _position_of(value: Variant, errors: Array[String]) -> Vector2:
	if value is Array:
		return Vector2(float(value[0]), float(value[1]))
	var anchors: Dictionary = _built["anchors"]
	if anchors.has(value):
		return anchors[value]
	if value == "doorstep":
		return (_built.map as CityMap).doorstep_world_position()
	errors.append("unresolved anchor: %s" % value)
	return Vector2.INF

## The recipe's `setup` section.
func _setup() -> Dictionary:
	return _object(_data, "setup")

## The recipe's `playback` section.
func _playback() -> Dictionary:
	return _object(_data, "playback")

func _start_position() -> Vector2:
	var errors: Array[String] = []
	return _position_of(_object(_setup(), "player").get("at", "doorstep"), errors)

## The map the recipe's city section is built to (`_built.map`).
##
## Overrides AuthoredScene.city_map.
func city_map() -> CityMap:
	return _built.map

## `setup.tutorial_complete`: a mid-game scene starts after the ordinary control lessons.
##
## Overrides AuthoredScene.lessons_learned.
func lessons_learned() -> bool:
	return bool(_setup().get("tutorial_complete", false))

## Overrides AuthoredScene.plays_by_script.
func plays_by_script() -> bool:
	return _scripted

## Installs the fixed day before the world gets a simulation frame. Geometry eligibility reads
## the declared construction context, never the exterior's unbuilt walkable floor. `spec` is the walk
## the run flow started for the scene — the same object its clock and HUD run on — and the scene's
## events run under its settings (`EventManager.start_recipe()`). A setup that does not stand is
## recorded as failed in the manifest (`setup_failed`) as well as returned.
##
## Overrides AuthoredScene.install.
func install(world: DayWorld, spec: DaySpec,
		resistance: ResistanceDirector = null) -> Array[String]:
	var errors := _install(world, spec, resistance)
	if not errors.is_empty():
		_manifest["setup_failed"] = true
		_write_manifest()
	return errors

func _install(world: DayWorld, spec: DaySpec, resistance: ResistanceDirector) -> Array[String]:
	if not world.is_in_a_city():
		return ["a scene recipe is installed into a city's world"]
	_walk_spec = spec
	_world = world
	var player := world.player()
	var baby := world.baby()
	_player = player
	_resistance = resistance
	_named = {"player": player}
	var errors: Array[String] = []
	var setup: Dictionary = _data.get("setup", {})
	var map := world.city_map()
	for roof: Dictionary in setup.get("roof_fixtures", []):
		errors.append_array(world.dressing().furnish_a_roof(SceneRecipe.rect(roof.lot), roof.fixtures))
	var at := _position_of(_object(setup, "player").get("at", "doorstep"), errors)
	if not errors.is_empty():
		return errors
	var edges := map.witness_only()
	if not map.is_open(map.world_to_tile(at)) or not _inside_extent(at):
		errors.append("setup.player.at must be open ground inside the authored extent")
	var background: Dictionary = setup.get("background", {})
	_select_structures(errors)
	# One set of calm areas for the recipe's walk: what its rows are placed against and what the walk
	# sites against after.
	var calm := world.events().calm_as_the_map_stands()
	var plans := _event_plans(at, errors, calm)
	world.events().start_recipe(plans, spec, _run.header().day(), at, calm, _ground,
			_route_tree, _locations if _route_tree else null)
	world.dressing().refresh_street_trees()
	map.restore_edges(edges)
	if not errors.is_empty():
		return errors
	_start_the_route(setup)
	for entry: Dictionary in setup.get("events", []):
		for plan in world.events().plans():
			var planned: Dictionary = _entry_of_plan.get(plan, {})
			if planned.get("name", "") == entry.name:
				if not plan.is_in_the_world():
					errors.append("event %s is not live at its required initial position" % entry.name)
				else:
					# Named and commanded, so asked of the event manager, which hands a plan's live
					# event to the caller that commands it.
					var event := world.events().event_of(plan)
					_named[entry.name] = event
					if bool(planned.get("charging", false)):
						# Set on her from the first frame, as a guard sent after her is: no radius
						# to cross and no warning to stand through.
						event.notice_her_at(at, 0.0)
					if bool(planned.get("relentless", false)):
						_relentless.append(event)
					if bool(planned.get("hold", false)):
						_held.append(event)
						# Never streamed out either, however far she runs from it.
						plan.keep_in_the_world()
	world.crowd().start_day(_run.header().day(),
			_run.calendar().day_rng(_run.header().day(), "crowd"), at,
			bool(background.get("crowd", false)), background.get("crowd_scope", "player") == "city",
			bool(background.get("uniform_walkers", false)), float(background.get("walker_multiplier", 1)))
	if background.get("uniform_walkers", false):
		var area_scale := map.world_size().x * map.world_size().y / pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0) \
				if background.get("crowd_scope", "player") == "city" else 1.0
		var act := Tuning.act_for_day(_run.header().day())
		var expected := roundi(Tuning.crowd_pedestrians(act) * area_scale * float(background.get("walker_multiplier", 1))) \
				+ roundi(Tuning.crowd_cars(act) * area_scale)
		if world.crowd().agent_count() != expected:
			errors.append("setup.background: too few eligible sidewalk positions for the requested uniform population")
			return errors
	if world.streets().region_plan():
		world.crowd().set_gates(world.streets().region_plan().gate_states())
	for entry: Dictionary in setup.get("actors", []):
		var actor_at := _position_of(entry.at, errors)
		if not errors.is_empty():
			break
		if not _inside_extent(actor_at):
			errors.append("actor %s is outside authored bounds" % entry.name)
			continue
		var placed := world.crowd().add_recipe_actor(entry.name,
				CrowdAgent.Kind.CAR if entry.kind == "car" else CrowdAgent.Kind.WALKER,
				actor_at, DIRECTIONS[entry.direction], float(entry.get("speed", -1)),
				hash("actor:%s" % entry.name))
		if not str(placed.error).is_empty():
			errors.append("actor %s: %s" % [entry.name, placed.error])
		else:
			_named[entry.name] = placed.actor
	if map.has_stretch():
		world.crowd().use_stretch()
	world.dressing().start_the_signals(float(setup.get("signal_time", 0)),
			bool(_object(setup, "progression").get("blackout", false)))
	player.reset_at(at, DIRECTIONS[_object(setup, "player").get("facing", "south")])
	baby.reset()
	var initial: Dictionary = setup.get("player", {})
	baby.seed_meters(float(initial.get("sleep", 0)), float(initial.get("excitement", 0)))
	# Asleep where the walk starts her asleep (`DaySpec.starts_with_the_baby_asleep()`, the escape's
	# city), or where the scene fills her sleep.
	if spec.starts_with_the_baby_asleep() or baby.sleepiness_level() >= Tuning.METER_MAX:
		baby.force_sleep()
	if setup.has("column"):
		_install_column(setup.column, errors)
	_install_posters(setup.get("posters", []), errors)
	_manifest["initial_actors"] = _snapshot()
	var installed: Array = []
	_manifest["installed_events"] = installed
	for plan in world.events().plans():
		var placed := plan.placed_at()
		var facing := plan.faces()
		installed.append({"row": plan.row_id(),
				"position": [placed.x, placed.y], "facing": [facing.x, facing.y]})
	return errors

## `setup.task`, started once her own camera is the one on screen: the boot camera is gone by
## `begin()` and is still current during `install()`, and where the task is placed asks what she
## can see from where she reads the mark, which is later: the mark stands unread and the task is
## placed when she touches it (`_bind_task_names()`). The last night is offered only once the goal
## is met, so a day-14 scene starts with it met. False, with the scene stopped, when the director
## refused it.
func _start_the_task() -> bool:
	if not _setup().has("task"):
		return true
	var task: Dictionary = _data.setup.task
	var errors: Array[String] = []
	if not _resistance:
		errors.append("setup.task: this boot has no resistance director")
	var mark := _position_of(task.mark, errors) if task.has("mark") else Vector2.INF
	var neighbor := _position_of(task.neighbor, errors) if task.has("neighbor") else Vector2.INF
	if errors.is_empty():
		var camera := get_viewport().get_camera_2d()
		if camera:
			camera.force_update_scroll()
		if _run.calendar().is_final_day():
			_run.resistance().set_progress(Tuning.RESISTANCE_GOAL)
		# The day's task is planned over the whole witness, as a played day plans it: the mark's
		# "reachable from home" and the guard's place are questions about the city, and a stretch's
		# void would answer every one of them no.
		var edges := _world.city_map().witness_only()
		errors = _resistance.start_recipe_task(_run.header().day(),
				_run.calendar().day_rng(_run.header().day(), "resistance"),
				_config.day_length_for(_run.header().day()), mark, neighbor)
		_world.city_map().restore_edges(edges)
	if not errors.is_empty():
		_manifest["setup_failed"] = true
		for problem in errors:
			print("[SceneRecipe] " + problem)
		_write_manifest()
		_end_the_game(1)
		return false
	_task_from = mark if mark != Vector2.INF else _player.global_position
	_manifest["task"] = {"mark": [mark.x, mark.y] if mark != Vector2.INF else null}
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
	if not _resistance or not _setup().has("task") or _manifest.get("setup_failed", false):
		return
	var contact: ContactPoint = _resistance.contact()
	if _resistance.read_mark():
		_named["mark"] = _resistance.read_mark()
	elif contact and contact.task_step().is_pickup and not contact.is_finished():
		_named["mark"] = contact
		return
	var task_record: Dictionary = _manifest["task"]
	if (not contact or contact.task_step().is_pickup) and task_record.has("read_tick"):
		if not task_record.has("expired_tick"):
			task_record["expired_tick"] = _tick
			_named.erase("task")
			print("[SceneRecipe] setup.task: the task expired at tick %d" % _tick)
			_write_manifest()
		return
	if not contact or contact.task_step().is_pickup:
		_manifest["setup_failed"] = true
		for problem in _resistance.scene_task_errors():
			print("[SceneRecipe] " + problem)
		print("[SceneRecipe] setup.task: the mark's task has nowhere to go in this scene")
		_write_manifest()
		if _scripted:
			_active = false
			_end_the_game(1)
		return
	if _named.get("task") == contact:
		return
	_named["task"] = contact
	if _resistance.rider():
		_named["rider"] = _resistance.rider()
	var step := _resistance.current_step()
	var target := _resistance.contact_position()
	var arrow := _resistance.red_arrow_target()
	task_record.merge({"step": step.index, "title": step.title,
			"target": [target.x, target.y], "distance": snappedf(_task_from.distance_to(target), 0.01),
			"arrow": [arrow.x, arrow.y] if arrow != Vector2.INF else null, "read_tick": _tick})
	_write_manifest()

## The army column is a production happening, whose close-spaced trucks deliberately do not use
## unrelated catalogue-event spacing. Start its real formation at the authored main-road point.
func _install_column(column: Dictionary, errors: Array[String]) -> void:
	var map := _world.city_map()
	var at := _position_of(column.at, errors)
	if not errors.is_empty():
		return
	var going := -1.0 if column.direction == "north" else 1.0
	var happening := ResistanceHappenings.new()
	happening.use_trace(_trace)
	happening.setup(_rows, map, _run, _world.events(), _world.streets(),
			_world.dressing().fronts(), null, null, null, _world.events().spawn_siting())
	if not happening.column_fits_at(at, going):
		errors.append("setup.column.at must fit the actual main-road lane and whole formation")
		return
	happening.start_day(_run.header().day())
	var trucks := happening.bring_the_column_at(at, going)
	for i in trucks.size():
		_named["truck_%d" % (i + 1)] = trucks[i]

func _install_posters(entries: Array, errors: Array[String]) -> void:
	var fronts := _world.poster_walls().fronts()
	var used := {}
	var recorded: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var at := _position_of(entry.at, errors)
		if not errors.is_empty():
			return
		var tile := _world.city_map().world_to_tile(at)
		if not fronts.has(tile) or not _inside_extent(at) \
				or not _world.city_map().tile_to_world(tile).is_equal_approx(at) or used.has(tile):
			errors.append("poster must name a distinct production wall cell inside the scene")
			continue
		used[tile] = true
		var kind: int = PosterArt.Kind[str(entry.kind).to_upper()]
		_run.posters().paste(tile, kind, false, 1)
		recorded.append({"at": [at.x, at.y], "kind": entry.kind})
	_world.poster_walls().refresh()
	_manifest["authored_posters"] = recorded

func _inside_extent(at: Vector2) -> bool:
	var map: CityMap = _built.map
	if map.has_stretch():
		return map.in_stretch(map.world_to_tile(at))
	var window := map.recipe_window()
	return not window.has_area() or window.has_point(map.world_to_tile(at))

## `setup.route_bag`: the director owes her route the recipe's marbles, drawn from its rigged bag
## by the game's own rules (`EventDirector.start_recipe_route()`). A scene with no route bag keeps
## the director silent, as every scene without one always has.
func _start_the_route(setup: Dictionary) -> void:
	if not setup.has("route_bag"):
		return
	var bag: Dictionary = setup.route_bag
	var marbles: Array = bag.get("marbles", [])
	var pre_bag: Array = bag.get("pre_bag", [])
	var owed := _world.events().start_recipe_route(marbles, pre_bag,
			int(bag.get("owed", marbles.size() + pre_bag.size())), float(bag.get("first_after", -1.0)))
	_manifest["route_bag"] = {"marbles": marbles.size(), "pre_bag": pre_bag, "owed": owed}

## Keep only named production structures. The context plan supplies eligibility and geometry,
## never permission to install unrelated walls or checkpoint actors throughout the scene.
func _select_structures(errors: Array[String]) -> void:
	var region := _world.streets().region_plan()
	if not region:
		return
	var setup: Dictionary = _data.get("setup", {})
	var selected := RegionPlan.new()
	for entry: Dictionary in setup.get("gates", []):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := _world.city_map().street_network().by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.gates: selected street leaves the authored extent")
			continue
		if not _walk_spec.region_wall_stands():
			errors.append("setup.gates: checkpoints are not available on this day")
			continue
		if not region.door_segments().any(func(door: StreetNetwork.Segment) -> bool: return door.key() == key):
			errors.append("setup.gates: the selected street is not an eligible production checkpoint; eligible streets: %s" %
					[region.door_segments().map(func(door: StreetNetwork.Segment) -> Vector3i: return door.key())])
			continue
		RegionPlanner.stand_door(_rows, _world.city_map(), segment, selected)
	for entry: Dictionary in setup.get("barriers", []):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := _world.city_map().street_network().by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.barriers: selected street leaves the authored extent")
			continue
		if not _world.city_map().has_street(key) or _world.streets().route_tree().is_on_the_tree(key) \
				or not _walk_spec.region_wall_stands():
			errors.append("setup.barriers: production barriers require an off-route street on an eligible day")
			continue
		selected.add_wall(segment)
		# The wall's bodies say so, as the day's do (`EventPlan.stand_in_the_wall()`).
		var bodies := SealPlanner.place_hard_on(_rows, _world.city_map(), segment, "roadblock",
				entry.end == "a")
		for body in bodies:
			body.stand_in_the_wall()
		selected.add_wall_plans(bodies)
	# The day's plan is replaced, not edited: a recipe that selects no gate or barrier stands no region
	# wall, and the siting's region is built from the plan it is handed.
	_world.streets().replace_region_plan(selected)

func _segment_inside_extent(segment: StreetNetwork.Segment) -> bool:
	if _world.city_map().has_stretch():
		for tile in _world.city_map().rect_tiles(segment.tile_rect()):
			if not _world.city_map().in_stretch(tile):
				return false
		return true
	var window := _world.city_map().recipe_window()
	return not window.has_area() or window.encloses(segment.tile_rect())

func _authored_seals(errors: Array[String]) -> Array[EventPlan]:
	var plans: Array[EventPlan] = []
	var map := _world.city_map()
	var trees := StreetTrees.footprint_tiles(map)
	var lined := StreetTrees.segment_keys_with_trees(map)
	var emptied: Array[Vector2i] = []
	var route := _world.streets().route_tree()
	for entry: Dictionary in _list(_setup(), "seals"):
		var key := Vector3i(int(entry.segment[0]), int(entry.segment[1]), int(entry.segment[2]))
		var segment := _world.city_map().street_network().by_key(key)
		if not _segment_inside_extent(segment):
			errors.append("setup.seals: selected street leaves the authored extent")
			continue
		if not SealPlanner.may_seal(map, _walk_spec, route, segment):
			errors.append("setup.seals: requires a production off-route, non-home, non-spine street")
			continue
		var candidate := SealPlanner.candidate_named(str(entry.candidate))
		if not candidate:
			continue
		if not SealPlanner.offers(_rows, candidate, _run.header().day(), lined.has(key),
				TutorialRoute.is_a_precinct(map, segment)):
			errors.append("setup.seals: candidate is unavailable on this day or street")
			continue
		var sited := SealPlanner.seal_street(_rows, map, segment, candidate, route, trees,
				emptied)
		plans.append_array(sited.bodies())
		sited.stand_whole(map)
	map.set_seal_tree_pits(emptied)
	return plans

func _event_plans(player_at: Vector2, errors: Array[String], calm: CalmAreas,
		standing: Array[EventPlan] = []) -> Array[EventPlan]:
	var setup: Dictionary = _data.get("setup", {})
	var plans: Array[EventPlan] = []
	var map := _world.city_map()
	# The scene's plan builder over the city's map, made here as the event manager makes the city's.
	var builder := PlanBuilder.new(map, EventInstance.mover_for,
			StreetInvalidation.room_around)
	var tree := _world.streets().route_tree()
	var corridor: Corridor = Corridor.of(tree) if tree else null
	var doors := PackedVector2Array()
	var finale: FinalePlanner.Plan
	if _data.get("kind", "city") == "escape":
		finale = FinalePlanner.route(map)
		# The escape's seals alone, which dress the map as the game's walk does (the tree pits a
		# seal empties, the soft seals cleared); what they place is not the scene's.
		DayPlanner.plan_the_escape_city(_rows, map, finale,
				_run.calendar().day_rng(_run.header().day(), "finale"), _walk_spec, builder, false)
		for chain in finale.chains:
			if not chain.complete:
				errors.append("escape route construction could not complete its ordinary chains")
		# The finale plan validates the real escape routes. Its randomly chosen scenery is
		# not an authored scene's event list.
	elif _world.streets().region_plan():
		for body in _world.streets().region_plan().wall_plans():
			if _inside_extent(body.placed_at()):
				plans.append(body)
		for body in _world.streets().region_plan().door_plans():
			doors.append(body.placed_at())
			if _inside_extent(body.placed_at()):
				plans.append(body)
	if not finale:
		plans.append_array(_authored_seals(errors))
	for segment in map.street_network().around_blocks(Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
		map.hold_segment(segment.key(), HeldStreets.Why.HOME)
	var counts := {}
	# The day's locations, laid out once: an authored row's tile names the one it stands in.
	# A scene with no route tree lays its locations out under a corridor that answers none.
	_route_tree = tree
	_locations = DayLocations.lay_out(map, corridor if corridor else Corridor.of(null))
	# The scene's one ground, made now that the authored seals and the home's holds are on the
	# map.
	_ground = EventScheduler.row_ground(map, corridor,
			_walk_spec.keeps_the_home_streets_clear())
	for entry: Dictionary in setup.get("events", []):
		var at := _position_of(entry.at, errors)
		if not errors.is_empty():
			break
		if not _inside_extent(at):
			errors.append("event %s is outside authored bounds" % entry.name)
			continue
		var def := _rows.by_id(entry.row)
		# A row at a resistance level, the shape a played day's dawn puts it in at that progress
		# (`EventCatalogue.heated()`), for the heated rungs no ordinary authored day reaches.
		if entry.has("heat"):
			def = _rows.heated(def, int(entry.heat))
		var plan: EventPlan
		var why: Array[String] = []
		if def.is_a_mast():
			plan = _mast_placement(def, builder, at, plans)
		elif finale:
			plan = _finale_placement(def, builder, at, player_at, finale, plans,
					int(entry.get("route_seed", 1)))
		elif def.spawn_mode_on(_run.header().day()) != EventDef.SpawnMode.MAP:
			var director := EventDirector.new(_rows, map)
			var heading: Vector2 = DIRECTIONS[_object(setup, "player").get("facing", "south")]
			var route := director.crossing_ahead_of(player_at, heading, def)
			if not def.available_on(_run.header().day()) or not def.pursues() or route.is_empty() \
					or not route[0].is_equal_approx(at) \
					or not DoorClearanceRule.clear_of_the_doors(at, route, doors, def.field_reach()):
				errors.append("event %s fails its ordinary director siting" % entry.name)
				continue
			plan = EventPlan.new(def, at, route)
		else:
			plan = EventScheduler.recipe_placement(def, _run.header().day(), map, builder, at,
					int(entry.get("route_seed", 1)), plans, corridor, _ground, doors, calm,
					standing, _locations, why)
		if not plan:
			errors.append("event %s fails ordinary day/ground/route/spacing placement%s"
					% [entry.name, (": " + "; ".join(why)) if not why.is_empty() else ""])
			continue
		counts[def.id()] = int(counts.get(def.id(), 0)) + 1
		# A day holds no cap on a row its units draw (one of a row in a unit instead,
		# `MarbleDraw`), so a row a unit draws is held to none here either.
		var beside := ResistanceSteps.guarded_row_on(_run.header().day())
		var capped := not def.is_drawn_by_units(_run.header().day(), beside) \
				and def.most_in_a_day() > 0
		if capped and int(counts[def.id()]) > def.most_in_a_day():
			errors.append("event %s exceeds the ordinary per-day cap" % entry.name)
		var requested := PackedVector2Array()
		for point: Variant in entry.get("path", []):
			requested.append(_position_of(point, errors))
		if not requested.is_empty() and requested != plan.walks():
			errors.append("event %s.path is not its production route for route_seed" % entry.name)
		for point in plan.walks():
			if not _inside_extent(point):
				errors.append("event %s route leaves the authored extent" % entry.name)
		# Staged part-way through its telegraph. No row a recipe's placements accept comes again
		# (`EventPlan.repeats()`), so the age is its one instance's.
		var age := float(entry.get("age", 0))
		plan.arrive_aged(age)
		if age > plan.telegraphs_for():
			errors.append("event %s.age cannot skip active simulation; use playback warmup" % entry.name)
		_entry_of_plan[plan] = entry
		if bool(entry.get("hold", false)):
			if hold_refusal(def) != "":
				errors.append(hold_refusal_message(str(entry.name), def))
		if bool(entry.get("charging", false)):
			if charging_refusal(plan.row()) != "":
				errors.append("event %s.charging is refused: row %s %s"
						% [entry.name, plan.row_id(), charging_refusal(plan.row())])
		if bool(entry.get("relentless", false)) and relentless_refusal(plan.row()) != "":
			errors.append("event %s.relentless is refused: row %s %s"
					% [entry.name, plan.row_id(), relentless_refusal(plan.row())])
		if def.is_a_mast():
			# Every mast the game stands has an id, and the director's lists and the blackout
			# find a mast by it: a recipe's own, or the one a mast added for day 11 is named by.
			plan.stand_as_a_mast(str(entry.mast_id) if entry.has("mast_id") \
					else DawnMasts.added_mast_id(plan.placed_at()))
		plans.append(plan)
	return plans

## An authored mast stands where the day's masts may, by the checks `DawnMasts`
## makes of a site and nothing wider: the day is `Tuning.MAST_FIRST_DAY` or later; the tile is a
## sidewalk or square tile `MastSites.is_eligible()` would offer (off the home street,
## its field off a calm interior and off every place a region door could stand, which holds the
## doors this scene stands: each is a street door of the day's plan, at a point
## `MastSites.possible_door_points()` lists, measured at the reach of `EventCatalogue.mast()`,
## which is the authored row's own only while `loudspeaker` is the one mast row and has no heat
## response: a later one needs the door rule back here); it is not closed, not on a held street
## and not on the home block; and no body placed before it is too near
## (`StreetInvalidation.room_around()`). It does not ask what `EventManager.queue_a_mast()`'s
## `WalkSiting` asks beyond those: the calm she has not used. The loudspeaker is a scripted row
## no catalogue roll places, so the ordinary placement refuses it.
func _mast_placement(def: EventDef, builder: PlanBuilder, at: Vector2,
		prior: Array[EventPlan]) -> EventPlan:
	var map := _world.city_map()
	var tile := map.world_to_tile(at)
	if _run.header().day() < Tuning.MAST_FIRST_DAY \
			or not map.tile_to_world(tile).is_equal_approx(at) \
			or not map.tile_at(tile) in [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE] \
			or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile) \
			or not MastSites.is_eligible(_rows, at, map):
		return null
	return builder.place_at(def, tile, RandomNumberGenerator.new(), prior)

## The escape's exact actors use its own row variants (the walk's spec's
## `DaySpec.walk_bag_rows()`), open streets, tree exclusion, spawn clearance and body
## spacing. No ordinary-day corridor or offscreen director stands in for it.
func _finale_placement(def: EventDef, builder: PlanBuilder, at: Vector2, player_at: Vector2,
		finale: FinalePlanner.Plan, prior: Array[EventPlan],
		route_seed: int) -> EventPlan:
	var rows := _walk_spec.walk_bag_rows(_rows)
	if not rows.has(def.id()):
		return null
	def = rows[def.id()]
	var map := _world.city_map()
	var tile := map.world_to_tile(at)
	if not map.tile_to_world(tile).is_equal_approx(at):
		return null
	var ground_ok := false
	for segment in finale.open_streets:
		if tile in EventScheduler.street_ground(map, _ground, segment, def, player_at):
			ground_ok = true
			break
	if not ground_ok:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	return builder.place_at(def, tile, rng, prior)

## Overrides AuthoredScene.begin.
func begin() -> void:
	if not _start_the_task():
		return
	_manifest["initial_actors"] = _snapshot()
	_record_crowd("initial_crowd")
	print("[SceneRecipe] manifest " + JSON.stringify(_manifest, "", true))
	_write_manifest()
	if _config.validates_the_recipe():
		_end_the_game(0)
		return
	if not _scripted:
		_hand_played = true
		return
	# `install()` positions the player while the boot camera is still current. Camera2D can only
	# reset its smoothed screen centre once the player's camera owns the viewport, which is true
	# here. Settle that state before the excluded moving lead-in begins so a movie never records the
	# camera travelling from its boot position toward an already-moving actor.
	if _playback().get("settled_camera", false):
		_settle_starting_camera()
	var playback: Dictionary = _data.get("playback", {})
	var camera: Dictionary = playback.get("camera", {})
	DevRig.apply_zoom(get_viewport().get_camera_2d(), float(camera.get("zoom", 1)))
	if camera.get("fixed", false):
		var offset: Array = camera.get("fixed_offset", [0, 0])
		_install_fixed_camera(Vector2(float(offset[0]), float(offset[1])))
	if camera.has("zoom_out"):
		var zoom := ZoomOutCamera.new()
		_zoom = zoom
		zoom.use_simulation_clock(elapsed)
		add_child(zoom)
		var map := _world.city_map()
		var bounds := map.tile_rect_to_world(Rect2i(Vector2i.ZERO, map.size_in_tiles())).grow(
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
	_settle_camera_on(starting_camera, _player)

## Puts `camera` on `player` with her facing lead, at once and with no smoothing left to arrive: the
## first view of a scripted scene is the player, not a camera travelling to her.
static func _settle_camera_on(camera: Camera2D, player: Stroller) -> void:
	camera.offset = Vector2(player.facing_direction().x,
			player.facing_direction().y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	camera.force_update_scroll()
	camera.reset_smoothing()
	camera.reset_physics_interpolation()
	camera.force_update_scroll()

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

## Why `hold` is refused for a row, or "" when it may be held. `_process()` reproduces only the plain
## walk straight away from her that a pursuer on foot leaves by, so every row whose departure is
## anything else is refused, each with its own reason.
static func hold_refusal(def: EventDef) -> String:
	if not def.pursues():
		return "does not pursue her, so it has no straight walk away to hold"
	if def.drives():
		return "drives, and a car leaves by its own rules"
	if def.investigates():
		return "lets men out, who walk back to it"
	if def.parks_where_it_arrives():
		return "parks where it arrives"
	if def.leaves_behind() != "":
		return "hands on to another event when it finishes"
	if def.leaves_its_body():
		return "leaves a barrier standing as a guard walks off"
	return ""

## Why `charging` is refused for a row, or "" when it may charge from the first frame. `charging: true`
## has a pursuer that waits for her (`EventDef.waits_for_her()`) start the scene already set on
## her, as the guard a task sends is (`EventInstance.notice_her_at()`), its notice spent: the
## recording shows the charge rather than waiting for her to walk into its radius. A row that
## does not wait has no radius to skip, and one that sets off beside her or runs its own line
## does not charge by that rule.
static func charging_refusal(def: EventDef) -> String:
	if not def.pursues() or def.notice_within() <= 0.0:
		return "does not wait for her, so it has no radius to skip"
	if def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER):
		return "sets off beside her, on its own clock"
	return ""

## Why `relentless` is refused for a row, or "" when it may be kept coming. `relentless: true` keeps a
## pursuer from giving up because she ran (`_keep_the_pursuers_coming()`), so a row that does not
## pursue her has nothing to keep.
static func relentless_refusal(def: EventDef) -> String:
	if not def.pursues():
		return "does not pursue her, so it has no chase to keep going"
	return ""

## The error a refused `hold` reports, naming the event and the row.
static func hold_refusal_message(event_name: String, def: EventDef) -> String:
	return "event %s.hold is refused: row %s %s" % [event_name, def.id(), hold_refusal(def)]

## The pursuers the recipe asked never to give up (`relentless`).
var _relentless: Array[EventInstance] = []

## **A relentless pursuer never gives up because she ran.** A pursuer that has seen her run for
## `Tuning.PURSUIT_SHAKEN_OFF` gives up (`EventPursuit`'s clock of her running), right for a
## played day, and a guard who stops coming half a second into a mother's run in a trailer shot.
## Each physics tick this has it forget that running clock (`EventInstance.forget_her_run()`), so it
## never gets near the limit; nothing else about the chase changes, and the game's rule is untouched.
func _keep_the_pursuers_coming() -> void:
	for instance in _relentless:
		if is_instance_valid(instance) and not instance.is_gone() \
				and not instance.is_on_its_way_out():
			instance.forget_her_run()

## The events the recipe asked to keep (`hold`), so a recording never loses one to the game's own
## despawn: see `_process()`.
var _held: Array[EventInstance] = []

## **A held event is never removed while the scene runs.** A pursuer that gave up the chase walks
## away and is removed once she is more than `Tuning.OUT_OF_SIGHT` from it, which is well inside the
## picture on a wide frame, or after `EventDeparture.LEAVING_GIVES_UP` seconds: right for a played
## day, and a dog vanishing in the middle of a trailer shot. Once a held event is leaving, its own
## process is switched off and this walks it on instead, the same straight departure away from her
## at the row's own departure speed and gait (`EventDeparture.leave()`'s plain branch), with the
## removal left out, and only for a row whose departure is that plain walk (`hold` on any other row
## fails the recipe, `hold_refusal()`), and the scene fails if a held event is sent along a set path
## or otherwise stops leaving in a straight line mid-scene (day 12's park cordon does that).
## Nothing else about the event changes; the game's despawn rules are untouched.
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	for instance in _held:
		if not is_instance_valid(instance) or instance.is_gone() or not instance.is_on_its_way_out():
			continue
		if not instance.walks_straight_away():
			_manifest["playback_error"] = "held event %s no longer leaves in a straight line" \
					% instance.row_id()
			_manifest["stopped_tick"] = _tick
			push_error(_manifest["playback_error"])
			if _active:
				_write_manifest()
				_active = false
				_end_the_game(1)
			return
		# Walked here, once a drawn frame, so its manager does not step it and it is drawn where this
		# puts it rather than interpolated between physics ticks; its look still redraws it.
		instance.hold_by_hand()
		instance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		instance.walk_on_by_hand(delta)

func _physics_process(_delta: float) -> void:
	_keep_the_pursuers_coming()
	if _hand_played and not get_tree().paused:
		_tick += 1
		_bind_task_names()
		return
	if not _active:
		return
	if get_tree().paused:
		_manifest["playback_error"] = "gameplay paused before the authored action completed"
		_manifest["stopped_tick"] = _tick
		_manifest["final_actors"] = _snapshot()
		print("[SceneRecipe] playback stopped: " + JSON.stringify(_manifest))
		_write_manifest()
		_active = false
		_end_the_game(1)
		return
	_tick += 1
	_observe()
	if not _active:
		return
	_watch_the_void()
	_watch_the_crowd()
	if _draft:
		var step := _resistance.current_step() if _resistance else null
		var walking_home: Node2D = _named.get("rider") if step and not step.is_pickup \
				and step.target_kind == ResistanceSteps.TargetKind.NEIGHBOR else null
		_draft.record(_player, _world,
				walking_home if is_instance_valid(walking_home) else null)
	if _capture_tick >= 0 and _tick >= _capture_tick:
		prepare_capture()
		return
	if _tick >= _duration_ticks:
		_active = false
		_release_input()
		_manifest["playback_complete"] = true
		_manifest["final_actors"] = _snapshot()
		_record_crowd("final_crowd")
		_write_manifest()
		if _draft:
			_end_the_game(_write_the_draft())
			return
		_end_the_game(0)
		return
	_apply_input()

func _apply_input() -> void:
	WalkPlan.press(_plan.input_at(_tick))

## Overrides AuthoredScene.elapsed.
func elapsed() -> float:
	return float(_tick) / Engine.physics_ticks_per_second

## Hold the exact simulated moment while the screenshot draws, even with a covered window.
##
## Overrides AuthoredScene.prepare_capture.
func prepare_capture() -> void:
	if _manifest.has("capture_tick"):
		return
	if _zoom:
		_zoom.hold_still()
	var camera := get_viewport().get_camera_2d()
	if camera:
		camera.force_update_scroll()
		_manifest["capture_camera"] = {"position": [camera.global_position.x, camera.global_position.y],
				"zoom": camera.zoom.x}
	_manifest["capture_tick"] = _tick
	_manifest["capture_actors"] = _snapshot()
	_record_crowd("capture_crowd")
	_write_manifest()
	_active = false
	get_tree().paused = true

func _record_crowd(key: String) -> void:
	if _world and _world.crowd():
		_manifest[key] = _world.crowd().recipe_coverage()
		_manifest[key.trim_suffix("_crowd") + "_activity"] = _activity_snapshot()

## Counts only live subjects whose ground positions are in the current picture. A visual review
## still checks occlusion and legibility; whole-field totals alone cannot establish a busy view.
func _activity_snapshot() -> Dictionary:
	var walker_streets := {}
	var visible_events := {}
	var result := {"visible_walkers": 0, "visible_cars": 0, "moving_crowd": 0,
			"walkers_left": 0, "walkers_right": 0,
			"walker_streets": walker_streets,
			"visible_events": visible_events}
	var view := get_viewport().get_visible_rect()
	var transform := get_viewport().get_canvas_transform()
	for agent in _world.crowd().agents():
		if not view.has_point(transform * agent.global_position):
			continue
		var key := "visible_cars" if agent.is_car() else "visible_walkers"
		result[key] += 1
		if not agent.is_car():
			var street := "%s%d" % ["v" if agent.travelling_vertically() else "h",
					agent.lane().corridor_index()]
			if not walker_streets.has(street):
				walker_streets[street] = {"walkers": 0, "moving": 0}
			var counts: Dictionary = walker_streets[street]
			counts["walkers"] = int(counts["walkers"]) + 1
			counts["moving"] = int(counts["moving"]) + int(not agent.velocity().is_zero_approx())
			result["walkers_left" if (transform * agent.global_position).x < view.size.x * 0.5
					else "walkers_right"] += 1
		if not agent.velocity().is_zero_approx():
			result.moving_crowd += 1
	for event in _world.events().instances():
		if view.has_point(transform * event.global_position):
			visible_events[event.row_id()] = int(visible_events.get(event.row_id(), 0)) + 1
	return result

## Whether `event` is chasing her now: a pursuer whose warning has run and that is still in the
## world. What the manifest's `pursuing` records and the `pursuing` observation asks.
static func _is_pursuing(event: EventInstance) -> bool:
	return event.pursues() and event.is_past_its_warning()

func _release_input() -> void:
	TouchControls.set_axis(&"move_left", &"move_right", 0)
	TouchControls.set_axis(&"move_up", &"move_down", 0)
	Input.action_release("run")

func _exit_tree() -> void:
	if _scripted:
		_release_input()

func _snapshot() -> Dictionary:
	var result := {}
	for label: String in _named:
		if not is_instance_valid(_named[label]):
			result[label] = {"retired": true}
			continue
		var actor: Node2D = _named[label]
		var at := actor.global_position
		result[label] = {"position": [snappedf(at.x, 0.0001), snappedf(at.y, 0.0001)]}
		if actor is Stroller:
			var stroller := actor as Stroller
			result[label]["carrying"] = stroller.is_carrying()
			result[label]["speed"] = snappedf(stroller.current_speed(), 0.0001)
			result[label]["gait_frame"] = stroller.mother_gait_frame(
					stroller.current_speed() / Tuning.WALK_SPEED)
		elif actor is ContactPoint:
			result[label]["done"] = (actor as ContactPoint).is_finished()
		elif actor is EventInstance:
			var event := actor as EventInstance
			result[label]["row"] = event.row_id()
			result[label]["telegraphing"] = event.is_telegraphing()
			result[label]["pursuing"] = _is_pursuing(event)
	return result

func _observe() -> void:
	_bind_task_names()
	var observed: Array = _manifest["observations"]
	for check: Dictionary in _observations:
		if check.condition == "appeared" and not _appeared.has(check.subject):
			var watched := _subject_of(str(check.subject))
			if watched and _she_can_see(watched):
				_appeared[check.subject] = _tick
	for check: Dictionary in _observations:
		if int(check.tick) != _tick:
			continue
		var actor := _subject_of(str(check.subject))
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
					passed = actor is Stroller and (actor as Stroller).current_speed() > Tuning.WALK_SPEED
				"carrying":
					passed = actor is Stroller and (actor as Stroller).is_carrying()
				"asleep", "awake":
					# The baby's own state, the one `Baby` sets by the game's sleep rule and the
					# pram's zzz is drawn from -- never a recipe-authored indicator.
					var baby := actor.get_node_or_null("Baby") as Baby if actor is Stroller else null
					passed = baby != null and baby.is_asleep() == (check.condition == "asleep")
				"pursuing":
					passed = actor is EventInstance and _is_pursuing(actor as EventInstance)
				"near_player":
					# What ties one actor to her: a pursuer that closes on her stays this close.
					passed = is_instance_valid(_player) and actor.global_position.distance_to(
							_player.global_position) <= float(check.distance)
				"near", "beyond":
					var errors: Array[String] = []
					var target := _position_of(check.at, errors)
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
					passed = actor is ContactPoint and not (actor as ContactPoint).is_finished() \
							and _resistance != null \
							and _resistance.contact() == actor
				"done":
					passed = actor is ContactPoint and (actor as ContactPoint).is_finished() \
							and (actor as ContactPoint).task_step().index \
							in _run.resistance().completed_steps()
				"arrowed":
					passed = _resistance != null and _resistance.red_arrow_target() != Vector2.INF \
							and _resistance.red_arrow_target().is_equal_approx(actor.global_position)
				"unarrowed":
					passed = _resistance != null and _resistance.red_arrow_target() == Vector2.INF
		var record := check.duplicate(true)
		record["passed"] = passed
		if check.condition == "appeared" and passed:
			record["first_in_the_picture"] = _appeared[check.subject]
		record["state"] = _snapshot().get(check.subject, {})
		if is_instance_valid(_player):
			record["player_at"] = [snappedf(_player.global_position.x, 0.01),
					snappedf(_player.global_position.y, 0.01)]
		if actor and not _named.has(check.subject):
			record["state"] = {"position": [snappedf(actor.global_position.x, 0.0001),
					snappedf(actor.global_position.y, 0.0001)]}
		observed.append(record)
		if not passed and _draft:
			print("[SceneRecipe] draft: unmet on the whole city, walked on: " + JSON.stringify(record))
		elif not passed:
			print("[SceneRecipe] unmet observation: " + JSON.stringify(record))
			_write_manifest()
			_active = false
			_end_the_game(1)
	for label: String in _named:
		if is_instance_valid(_named[label]):
			_last_positions[label] = (_named[label] as Node2D).global_position
	for check: Dictionary in _observations:
		var label := str(check.subject)
		if label.begins_with(ROW_SUBJECT):
			var summoned := _subject_of(label)
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
## scheme's controls cover (the cover `main` handed the city's events, the one every other
## "can she see it" reads). Taking all four corners follows zoom and the quarter-turn used for a
## portrait presentation; using the actor's drawn box keeps this the same overlap question the
## page's encounter counter asks of what she meets.
func _she_can_see(actor: Node2D) -> bool:
	var at := actor.global_position
	var covering := _world.events().visible_view().screen_cover() if _world else null
	var box: Rect2 = (actor as EventInstance).drawn_box() if actor is EventInstance \
			else Rect2(-Vector2.ONE * 16, Vector2.ONE * 32)
	box.position += at
	return VisibleView.visible_share(box, _camera_world_rect(), covering) > 0.0

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
	if not _world or not _world.crowd():
		return counts
	for agent in _world.crowd().agents():
		if not agent.velocity().is_zero_approx() and _in_the_picture(agent.global_position):
			counts["cars" if agent.is_car() else "walkers"] += 1
	return counts

## The node an observation names: a named actor, or for `row:<id>` the first live, unfinished
## instance of that catalogue row in the world. Null when there is none.
func _subject_of(label: String) -> Node2D:
	if not label.begins_with(ROW_SUBJECT):
		return _named[label] if is_instance_valid(_named.get(label)) else null
	if not _world or not _world.events():
		return null
	for instance in _world.events().instances():
		if instance.row_id() == label.trim_prefix(ROW_SUBJECT) and not instance.is_gone():
			return instance
	return null

## Whether any part of a box `half` either side of `centre` is in the picture: its centre or a
## corner, the test `SpawnSiting.Rule.DRAWING_OFF_THE_VIEW` puts a task's target through as it is placed.
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
	if not _world or not _world.city_map().has_stretch():
		return
	for instance in _world.events().instances():
		if _in_the_void.has(instance):
			continue
		var tile := _world.city_map().world_to_tile(instance.global_position)
		if instance.is_waiting() and _world.city_map().is_void(tile):
			_in_the_void[instance] = true
			var found: Array = _manifest.get("in_the_void", [])
			found.append({"tile": [tile.x, tile.y], "row": instance.row_id(), "tick": _tick})
			_manifest["in_the_void"] = found

## Where each of the crowd stood last tick, to catch one that leaves or enters in view.
var _crowd_was := {}
## How far a walker's or a car's picture reaches past its centre, for `_watch_the_crowd()`: a tile,
## a car's half length and its shadow. Less than the room an agent keeps when it leaves
## (`CrowdAgent.ENTRY_PICTURE_ROOM`), since the camera moves on between the frame it left on and the
## tick that asks.
const PICTURE_REACH := float(Tuning.TILE_SIZE)

## **Nothing in a stretch's crowd appears or vanishes where she can see it** *(the player's rule,
## PR #597)*: a walker or car that moves further in one tick than any of them walks or drives — a
## recycle — while it stood, or now stands, in either view (`CrowdAgent.beyond_every_view()`) is
## recorded in the manifest's `seen_to_jump`, which `tests/test_scene_recipe_stretch_crowd.gd` holds
## empty over every stretch scene.
func _watch_the_crowd() -> void:
	if not _world or not _world.city_map().has_stretch() or not _world.crowd():
		return
	for agent in _world.crowd().agents():
		var at := agent.global_position
		if _crowd_was.has(agent):
			var was: Vector2 = _crowd_was[agent]
			if was.distance_to(at) > 2.0 * Tuning.TILE_SIZE \
					and not (agent.beyond_every_view(was, PICTURE_REACH)
					and agent.beyond_every_view(at, PICTURE_REACH)):
				var jumps: Array = _manifest.get("seen_to_jump", [])
				jumps.append({"tick": _tick, "from": [snappedf(was.x, 0.1), snappedf(was.y, 0.1)],
						"to": [snappedf(at.x, 0.1), snappedf(at.y, 0.1)],
						"kind": "car" if agent.is_car() else "walker"})
				_manifest["seen_to_jump"] = jumps
		_crowd_was[agent] = at

## `--recipe-draft FILE`: the stretch the walk just took, written as a recipe (`SceneRecipeDraft`).
## Answers the exit code.
func _write_the_draft() -> int:
	var problems: Array[String] = []
	var pinned: Array[Vector2] = []
	var errors: Array[String] = []
	for field: String in _object(_setup(), "task"):
		pinned.append(_position_of(_data.setup.task[field], errors))
	var drafted := _draft.compose(_written, _run, _world, _start_position(),
			pinned, problems)
	for problem in problems:
		print("[SceneRecipe] draft: " + problem)
	var path := _config.recipe_draft_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("[SceneRecipe] cannot write the draft: " + path)
		return 1
	file.store_string(SceneRecipeDraft.to_json(drafted) + "\n")
	file.close()
	var stretch: Dictionary = drafted["stretch"]
	var drafted_setup: Dictionary = drafted["setup"]
	var tiles := 0
	var runs_by_type: Dictionary = stretch["tiles"]
	for type: String in runs_by_type:
		for run: Array in runs_by_type[type]:
			tiles += int(run[2]) - int(run[1]) + 1
	print("[SceneRecipe] draft written to %s: %d tiles, %d buildings, %d street trees, %d props, %d litter, %d cracks, %d posters, %d walkers and cars"
			% [path, tiles, _list(stretch, "buildings").size(), _list(stretch, "trees").size(),
			_list(stretch, "props").size(), _list(stretch, "litter").size(),
			_list(stretch, "cracks").size(), _list(drafted_setup, "posters").size(),
			_list(drafted_setup, "actors").size()])
	return 0

## An escape section of this recipe was lost and is about to start again. A scripted recipe has
## failed — the manifest says so and the run quits non-zero — and answers `true`; a free one
## answers `false`, for `main` to reload the authored scene rather than retry the section.
##
## Overrides AuthoredScene.lose_the_attempt.
func lose_the_attempt() -> bool:
	if not _scripted:
		return false
	_manifest["playback_error"] = "the authored escape attempt was lost"
	_write_manifest()
	_active = false
	_end_the_game(1)
	return true

## Ends the game with exit status `code`: through what `configure()` was handed, else by quitting the tree.
func _end_the_game(code: int) -> void:
	if _end_game.is_valid():
		_end_game.call(code)
		return
	get_tree().quit(code)

func _write_manifest() -> void:
	var path := _config.recipe_manifest_path()
	if path.is_empty():
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("[SceneRecipe] cannot write manifest: " + path)
		_end_the_game(1)
		return
	file.store_string(JSON.stringify(_manifest, "\t", true) + "\n")
