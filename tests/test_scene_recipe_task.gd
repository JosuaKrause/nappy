extends RefCounted
## A scene recipe's `setup.task`: what the schema accepts, and what the runtime installs of an
## authored mast (its id, and the ground the day's masts may stand on). What the resistance director
## does with a pinned mark and a pinned neighbor is `tests/test_resistance_recipe_task.gd`'s. The
## scenes' own walks to their targets are `tools/scene-recipes.sh`'s headless assertions.
##
## **Builds a real `City` for the mast install cases only: an authored mast is installed through
## the runtime into the day's city, whose streets, closures and held streets decide where it may
## stand**; the task schema's acceptance is checked without one.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const RecipeErrors := preload("res://tests/recipe_runtime_errors.gd")
## The context city every task scene is built on, so a mark here is a mark there.
const CONTEXT := 1917501
## An alley mouth of that city, the mark most task scenes start at.
const MOUTH := Vector2i(92, 69)
## The seed `_recipe()` gives a scene, which a recipe boot starts its run on.
const RECIPE_SEED := 11

func run(t: TestRunner) -> void:
	_test_the_schema_names_a_mark_on_the_days_that_have_one(t)
	_test_the_task_observations_ask_about_the_task(t)
	_test_an_authored_mast_carries_its_own_id(t)
	_test_an_authored_mast_stands_only_where_the_days_masts_may(t)

func _recipe(day: int, task: Variant, observations := []) -> Dictionary:
	var setup := {"day": day}
	if task != null:
		setup["task"] = task
	return {"version": 1, "name": "task", "seed": RECIPE_SEED, "extent": {"scope": "full"},
		"city": {"context_seed": CONTEXT}, "setup": setup,
		"playback": {"duration": 1, "observations": observations}}

## Where each recipe is written and loaded, and what loading it answers.
var _errors := RecipeErrors.new()

func _refused(t: TestRunner, recipe: Dictionary, words: String) -> bool:
	return _errors.refused(t, recipe, words)

func _test_the_schema_names_a_mark_on_the_days_that_have_one(t: TestRunner) -> void:
	t.check(_refused(t, _recipe(3, {}), "offers no resistance task"),
			"a day before the first mark has no task to start")
	t.check(_refused(t, _recipe(7, {}), "starts at a chalk mark"),
			"a day with a mark needs the mark's place")
	t.check(_errors.errors_of(t, _recipe(7, {"mark": [2960, 2224]})).is_empty(),
			"and accepts it")
	t.check(_refused(t, _recipe(14, {"mark": [2960, 2224]}), "has no chalk mark"),
			"the last night has no mark to place")
	t.check(_errors.errors_of(t, _recipe(14, {})).is_empty(),
			"and starts from its door alone")
	t.check(_refused(t, _recipe(7, {"mark": [2960, 2224], "neighbor": [1936, 4336]}),
			"only day 10's neighbor"), "only day 10's neighbor has a start to pin")
	t.check(_errors.errors_of(t, _recipe(10,
			{"mark": [2128, 4688], "neighbor": [1936, 4336]})).is_empty(), "which day 10 accepts")
	t.check(_refused(t, _recipe(7, {"mark": [2960, 2224], "target": [0, 0]}), "setup.task.target"),
			"an unknown task field is refused")

func _test_the_task_observations_ask_about_the_task(t: TestRunner) -> void:
	var on_the_task := [{"tick": 1, "subject": "task", "condition": "offered"},
			{"tick": 1, "subject": "mark", "condition": "done"},
			{"tick": 1, "subject": "rider", "condition": "beyond", "at": [0, 0], "distance": 576},
			{"tick": 1, "subject": "task", "condition": "off_screen"}]
	t.check(_errors.errors_of(t, _recipe(7, {"mark": [2960, 2224]}, on_the_task))
			.is_empty(), "the task names its mark, its contact and its rider")
	t.check(_refused(t, _recipe(9, {"mark": [2960, 2224]},
			[{"tick": 1, "subject": "rider", "condition": "visible"}]), "not a named actor"),
			"a task on a bare point has no rider")
	t.check(_refused(t, _recipe(7, null, [{"tick": 1, "subject": "player", "condition": "offered"}]),
			"asks about the task's mark or target"), "offered asks only about the task")
	t.check(_errors.errors_of(t, _recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views", "half": [160, 480]}])).is_empty(),
			"a box clear of her view, in either presentation, is asked with its half extents")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views"}]), "needs [half width, half height]"),
			"and a view check with no box is refused")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "player", "condition": "visible",
			"half": [1, 1]}]), "belongs to clear_of_both_views"), "the half extents belong to it alone")
	t.check(_refused(t, _recipe(3, null, [{"tick": 1, "subject": "row:nothing", "condition": "visible"}]),
			"row:<catalogue id>"), "a row subject names a catalogue row")
	t.check(_errors.errors_of(t, _recipe(3, null,
			[{"tick": 1, "subject": "row:fire_truck", "condition": "visible"}])).is_empty(),
			"such as the engine a fire calls in")

## The context city on `day` as a recipe starts it — the authored closures, no catalogue fill —
## in a run of its own on that day (the recipes' seed, as a recipe boot starts its run), which the
## city is handed: `[city, run]`. A fresh map each time, since a day's bodies and holds are
## recorded on it. `_free_day()` frees the city.
func _day(t: TestRunner, day: int) -> Array:
	var built := RecipeCityBuilder.build({"version": 1, "name": "task", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	var errors: Array[String] = built.errors
	t.check(errors.is_empty(), "the context city builds: %s" % [errors])
	var map: CityMap = built.map
	var own_run := RunState.new()
	own_run.start_run(RECIPE_SEED)
	own_run.header().set_day(day)
	var state := own_run.attempt_spend().block_arcs()
	state.reset()
	state.begin_day(map.plans_by_block(), day)
	var city: City = CITY_SCENE.instantiate()
	city.run = own_run
	t.add_child(city)
	RunCity.build(city, map)
	city.start_recipe_day(state, day, own_run.calendar().day_rng(day, "closures"))
	# A recipe that selects no gate or barrier stands no region wall either, the way
	# `SceneRecipeRuntime._select_structures()` leaves the day's plan.
	if city.streets().region_plan():
		city.streets().replace_region_plan(RegionPlan.new())
	var empty: Array[EventPlan] = []
	RunCity.events(city).start_recipe(empty, DaySpec.for_day(day, Tuning.DAY_LENGTH_SECONDS), day,
			map.tile_to_world(MOUTH))
	return [city, own_run]

func _free_day(made: Array) -> void:
	(made[0] as City).free()

## A scene recipe gives an authored loudspeaker a `mast_id`, the identity day 11's task and its red
## arrow answer to, so a scene can stand two masts and show the arrow move between them
## (`scene-recipes/task-11-two-masts.json`). Only a loudspeaker is a mast, and one id names one mast.
func _test_an_authored_mast_carries_its_own_id(t: TestRunner) -> void:
	var mast := func(name: String, row: String, id: Variant) -> Dictionary:
		var entry := {"name": name, "row": row, "at": [3440, 1936]}
		if id != null:
			entry["mast_id"] = id
		return entry
	var with := func(events: Array) -> Dictionary:
		var recipe := _recipe(11, {"mark": [2960, 2224]})
		recipe.setup["events"] = events
		return recipe
	t.check(_errors.errors_of(t, with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "south")])).is_empty(),
			"two loudspeakers with their own ids are accepted")
	t.check(_refused(t, with.call([mast.call("a", "charging_dog", "north")]),
			"belongs to a loudspeaker row"), "only a loudspeaker is given a mast id")
	t.check(_refused(t, with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "north")]), "unique nonempty string"),
			"two masts cannot share an id")
	t.check(_refused(t, with.call([mast.call("a", "loudspeaker", "")]), "unique nonempty string"),
			"an empty id names nothing")

## An authored mast is accepted by the checks `DawnMasts` makes of a site: a
## day with masts, ground a mast site would be offered that is not closed, held or the home block,
## and clear of the day's doors. (107, 60) is where day 11's own mast stands on the context city.
## Each site is installed as a recipe installs it (`install()`), into the day's city in a run of its
## own, and read off what the install says: a refused site is an install error naming the mast.
func _test_an_authored_mast_stands_only_where_the_days_masts_may(t: TestRunner) -> void:
	var at := Vector2(3440, 1936)
	var made := _day(t, 11)
	var city: City = made[0]
	t.check(_mast_installs(t, made, at), "a mast stands on an eligible sidewalk of a day with masts")
	# A site within the reach of a door a street could stand at (`MastSites`, the ground a mast is
	# offered) is refused: found as a tile that only that reach rules out, so the install's refusal
	# is the door's.
	var beside_a_door := _a_site_only_a_door_rules_out(city.map)
	t.check(beside_a_door != Vector2.INF and not _mast_installs(t, made, beside_a_door),
			"but not with its field on the ground a door could stand beside")
	var tile: Vector2i = city.map.world_to_tile(at)
	var street := city.map.street_network().segment_containing(tile)
	var shut: Array[RoadClosure] = city.streets().closures().duplicate()
	shut.append(RoadClosure.new(RoadClosure.Kind.ROADWORKS, street))
	city.map.close_streets(shut)
	t.check(city.map.is_closed(tile), "fixture: the street's closure shuts the tile")
	t.check(not _mast_installs(t, made, at), "nor on a closed tile")
	city.map.close_streets(city.streets().closures())
	city.map.hold_segment(city.map.street_network().segment_containing(tile).key(),
			HeldStreets.Why.SEAL)
	t.check(not _mast_installs(t, made, at), "nor on a held street")
	_free_day(made)
	made = _day(t, Tuning.MAST_FIRST_DAY - 1)
	t.check(not _mast_installs(t, made, at), "nor on a day before the masts")
	_free_day(made)

## A sidewalk or square point of `map` that a mast site is refused only for lying within the reach of
## a point a street door could stand at: ground that is open, unheld, off the home block, and that
## `MastSites.is_eligible()` accepts when no door is handed in, or `Vector2.INF` when there is none.
func _a_site_only_a_door_rules_out(map: CityMap) -> Vector2:
	var reach := Tuning.CHECKPOINT_EVENT_GAP + EventCatalogue.mast().field_reach()
	var nowhere := PackedVector2Array([Vector2(-1.0e7, -1.0e7)])
	for door in MastSites.possible_door_points(map):
		var centre := map.world_to_tile(door)
		var span := ceili(reach / Tuning.TILE_SIZE)
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre + Vector2i(dx, dy)
				if not map.in_bounds(tile) \
						or not map.tile_at(tile) in [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE] \
						or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
					continue
				var at := map.tile_to_world(tile)
				if MastSites.is_eligible(at, map, nowhere) and not MastSites.is_eligible(at, map):
					return at
	return Vector2.INF

## Whether a recipe's loudspeaker at `at` installs on the day `made` (`_day()`) stands, through the
## runtime's own `install()` with her at the alley mouth: false when the install refuses the mast.
func _mast_installs(t: TestRunner, made: Array, at: Vector2) -> bool:
	var city: City = made[0]
	var own_run: RunState = made[1]
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	var her := city.map.tile_to_world(MOUTH)
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"setup": {"day": own_run.header().day(),
			"player": {"at": [her.x, her.y]},
			"events": [{"name": "mast", "row": "loudspeaker", "at": [at.x, at.y], "mast_id": "m"}]}},
			"manifest": {}, "anchors": {}, "map": city.map},
			RunConfig.parse(PackedStringArray(["--recipe", "test.json"]), "", true), own_run)
	var errors := runtime.install(RunCity.world_of(city, player),
			DaySpec.for_day(own_run.header().day(), Tuning.DAY_LENGTH_SECONDS))
	runtime.free()
	player.free()
	return not "\n".join(errors).contains("event mast fails")