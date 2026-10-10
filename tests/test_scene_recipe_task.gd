extends RefCounted
## A scene recipe's `setup.task`: what the schema accepts, and what the director does with a pinned
## mark and a pinned neighbor — stands the mark unread, places the task with its own placement when
## it is read, and
## refuses a pin rather than moving it. The scenes' own walks to their targets are
## `tools/scene-recipes.sh`'s headless assertions.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The context city every task scene is built on, so a mark here is a mark there.
const CONTEXT := 1917501
## An alley mouth of that city, the mark most task scenes start at.
const MOUTH := Vector2i(92, 69)

func run(t) -> void:
	_test_the_schema_names_a_mark_on_the_days_that_have_one(t)
	_test_the_task_observations_ask_about_the_task(t)
	_test_the_task_scenes_start_off_an_unread_mark(t)
	_test_the_door_scenes_show_the_robber_a_done_task_sends(t)
	_test_an_authored_mast_carries_its_own_id(t)
	var saved := {"day": GameState.day, "completed": GameState.completed_resistance_steps.duplicate(),
			"failed": GameState.failed_resistance_steps.duplicate(),
			"progress": GameState.resistance_progress, "scars": GameState.scars.duplicate(true),
			"tiles": GameState.completed_resistance_alley_tiles.duplicate(),
			"state": GameState.city_state}
	_test_a_pinned_mark_is_read_and_its_task_placed_near_it(t)
	_test_a_mark_off_an_alley_mouth_is_refused_not_moved(t)
	_test_a_neighbor_start_the_day_could_not_draw_is_refused(t)
	_test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t)
	GameState.day = saved.day
	GameState.completed_resistance_steps = saved.completed
	GameState.failed_resistance_steps = saved.failed
	GameState.resistance_progress = saved.progress
	GameState.scars = saved.scars
	GameState.completed_resistance_alley_tiles = saved.tiles
	GameState.city_state = saved.state

func _recipe(day: int, task: Variant, observations := []) -> Dictionary:
	var setup := {"day": day}
	if task != null:
		setup["task"] = task
	return {"version": 1, "name": "task", "seed": 11, "extent": {"scope": "full"},
		"city": {"context_seed": CONTEXT}, "setup": setup,
		"playback": {"duration": 1, "observations": observations}}

func _refused(recipe: Dictionary, words: String) -> bool:
	return "\n".join(SceneRecipeRuntime.validate_runtime(recipe)).contains(words)

func _test_the_schema_names_a_mark_on_the_days_that_have_one(t) -> void:
	t.check(_refused(_recipe(3, {}), "offers no resistance task"),
			"a day before the first mark has no task to start")
	t.check(_refused(_recipe(7, {}), "starts at a chalk mark"),
			"a day with a mark needs the mark's place")
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(7, {"mark": [2960, 2224]})).is_empty(),
			"and accepts it")
	t.check(_refused(_recipe(14, {"mark": [2960, 2224]}), "has no chalk mark"),
			"the last night has no mark to place")
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(14, {})).is_empty(),
			"and starts from its door alone")
	t.check(_refused(_recipe(7, {"mark": [2960, 2224], "neighbor": [1936, 4336]}),
			"only day 10's neighbor"), "only day 10's neighbor has a start to pin")
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(10,
			{"mark": [2128, 4688], "neighbor": [1936, 4336]})).is_empty(), "which day 10 accepts")
	t.check(_refused(_recipe(7, {"mark": [2960, 2224], "target": [0, 0]}), "setup.task.target"),
			"an unknown task field is refused")

func _test_the_task_observations_ask_about_the_task(t) -> void:
	var on_the_task := [{"tick": 1, "subject": "task", "condition": "offered"},
			{"tick": 1, "subject": "mark", "condition": "done"},
			{"tick": 1, "subject": "rider", "condition": "beyond", "at": [0, 0], "distance": 576},
			{"tick": 1, "subject": "task", "condition": "off_screen"}]
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(7, {"mark": [2960, 2224]}, on_the_task))
			.is_empty(), "the task names its mark, its contact and its rider")
	t.check(_refused(_recipe(9, {"mark": [2960, 2224]},
			[{"tick": 1, "subject": "rider", "condition": "visible"}]), "not a named actor"),
			"a task on a bare point has no rider")
	t.check(_refused(_recipe(7, null, [{"tick": 1, "subject": "player", "condition": "offered"}]),
			"asks about the task's mark or target"), "offered asks only about the task")
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views", "half": [160, 480]}])).is_empty(),
			"a box clear of her view, in either presentation, is asked with its half extents")
	t.check(_refused(_recipe(3, null, [{"tick": 1, "subject": "player",
			"condition": "clear_of_both_views"}]), "needs [half width, half height]"),
			"and a view check with no box is refused")
	t.check(_refused(_recipe(3, null, [{"tick": 1, "subject": "player", "condition": "visible",
			"half": [1, 1]}]), "belongs to clear_of_both_views"), "the half extents belong to it alone")
	t.check(_refused(_recipe(3, null, [{"tick": 1, "subject": "row:nothing", "condition": "visible"}]),
			"row:<catalogue id>"), "a row subject names a catalogue row")
	t.check(SceneRecipeRuntime.validate_runtime(_recipe(3, null,
			[{"tick": 1, "subject": "row:fire_truck", "condition": "visible"}])).is_empty(),
			"such as the engine a fire calls in")

## The context city on `day` as a recipe starts it — the authored closures, no catalogue fill —
## and a director. A fresh map each time, since a day's bodies and holds are recorded on it.
func _day(t, day: int) -> Array:
	var built := RecipeCityBuilder.build({"version": 1, "name": "task", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	t.check(built.errors.is_empty(), "the context city builds: %s" % [built.errors])
	var map: CityMap = built.map
	GameState.day = day
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.scars = []
	GameState.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(map.block_plans, day)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	city.start_recipe_day(state, day, GameState.day_rng(day, "closures"))
	# A recipe that selects no gate or barrier stands no region wall either, the way
	# `SceneRecipeRuntime._select_structures()` leaves the day's plan.
	var region := city.region_plan()
	if region:
		region.doors.clear()
		region.door_bodies.clear()
		region.gates.clear()
		region.walls.clear()
		region.wall_bodies.clear()
		region.alley_doors.clear()
		region.alley_walls.clear()
	var empty: Array[EventScheduler.Planned] = []
	city.events.start_recipe(empty, day, map.tile_to_world(MOUTH))
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, map)
	return [city, director]

func _test_a_pinned_mark_is_read_and_its_task_placed_near_it(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var map := city.map
	var mark := map.tile_to_world(MOUTH)
	var errors := director.start_recipe_task(7, GameState.day_rng(7, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "a mark at an alley mouth is accepted: %s" % [errors])
	# *(Inbox #555, "Unread, walk to it".)* The scene begins with the mark standing unread and no
	# task on offer; a touch reads it and the task is placed then.
	t.check(director._read_mark == null and director._contact != null
			and director._contact.step.is_pickup and not director._contact.is_done
			and director._contact.global_position == mark,
			"the mark stands where the recipe put it, unread")
	t.check(director.current_step().is_pickup and director.red_arrow_target() == Vector2.INF
			and director.contact_position() == mark,
			"no task is on offer and no arrow is drawn before she reads it")
	t.check(not GameState.completed_resistance_steps.has(director.current_step().index),
			"nothing is completed at the start")
	director._contact.complete_now()
	var task := director.current_step()
	t.check(director._read_mark != null and director._read_mark.global_position == mark
			and director._read_mark.is_done, "reading it leaves the mark standing, read")
	t.check(task != null and task.task_event_id == "delivery_van" and not task.is_pickup,
			"and the day's task is on offer")
	var target := director.contact_position()
	t.check(target.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK
			and target.distance_to(mark) < ResistanceDirector.NEAR_THE_MARK + Tuning.TILE_SIZE,
			"placed where a path from the mark first reaches the circle round her (%.0fpx)"
			% target.distance_to(mark))
	t.check(director.red_arrow_target() == target, "with its arrow on the van")
	director.free()
	city.free()

func _test_a_mark_off_an_alley_mouth_is_refused_not_moved(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var map := city.map
	var inside := MOUTH + Vector2i.UP * 3
	t.check(map.tile_at(inside) == GameEnums.TileType.ALLEY
			and not ResistanceDirector.is_alley_mouth(map, inside),
			"the probe stands inside the mark's own alley, not at its mouth")
	var errors := director.start_recipe_task(7, GameState.day_rng(7, "resistance"), 300.0,
			map.tile_to_world(inside))
	t.check("\n".join(errors).contains("is not an alley mouth"),
			"a mark in the middle of an alley is refused: %s" % [errors])
	t.check(director.current_step() == null, "and nothing is offered in its place")
	director.free()
	city.free()

func _test_a_neighbor_start_the_day_could_not_draw_is_refused(t) -> void:
	var made := _day(t, 10)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var map := city.map
	var mark := map.tile_to_world(Vector2i(66, 146))
	# A sidewalk a block from her door: a few tiles of walk from home, nowhere near the band of
	# about `Tuning.NEIGHBOR_WALK_HOME_SECONDS` of walk the day draws a start from.
	var near_home := Vector2i(62, 84)
	t.check(map.tile_at(near_home) == GameEnums.TileType.SIDEWALK, "the probe stands on a sidewalk")
	var errors := director.start_recipe_task(10, GameState.day_rng(10, "resistance"), 300.0, mark,
			map.tile_to_world(near_home))
	t.check(errors.is_empty(), "the mark is accepted; the neighbor is drawn when she reads it")
	director._contact.complete_now()
	errors = director.scene_task_errors()
	t.check("\n".join(errors).contains("is not a start the day could draw"),
			"a neighbor start the day's draw could not make is refused: %s" % [errors])
	t.check(director.current_step() == null or director.current_step().is_pickup
			or director._rider == null, "and no neighbor is sent home in its place")
	director.free()
	city.free()

## *(Inbox #486: "Now just add a new mast close by".)* A recipe installs no mast it does not name, so
## day 11 meets a city with no live mast at all — which is still no mast near her, and one is put up
## where her path first reaches the circle round her.
func _test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t) -> void:
	var made := _day(t, 11)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var mark := city.map.tile_to_world(MOUTH)
	var errors := director.start_recipe_task(11, GameState.day_rng(11, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "day 11's mark is accepted: %s" % [errors])
	director._contact.complete_now()
	t.check(director.scene_task_errors().is_empty() and director.current_step() != null
			and not director.current_step().is_pickup,
			"and its task finds a mast with none standing: %s" % [director.scene_task_errors()])
	var foot := city.events.mast_foot(director._mast_id)
	t.check(director._mast_id != "" and foot != Vector2.INF
			and foot.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK,
			"a mast put up for it on the circle round her")
	director.free()
	city.free()

## *(Inbox #555.)* Days 6 to 13's scenes start her off the mark, outside its notice, with the mark
## unread and nothing arrowed at the first tick, then assert the task once she has read it. A scene
## that put her on the mark, or asserted the task at the first tick, would be the old start.
func _test_the_task_scenes_start_off_an_unread_mark(t) -> void:
	var names := ["06-note", "07-package", "08-burnt-shell", "09-crossing", "10-neighbor",
			"11-mast", "12-swing", "13-roadblock"]
	for name: String in names:
		var data: Dictionary = SceneRecipe.load_file("res://scene-recipes/task-%s.json" % name).data
		var anchors: Dictionary = data.anchors
		var mark := Vector2(anchors.mark.tile[0], anchors.mark.tile[1]) * Tuning.TILE_SIZE \
				+ Vector2.ONE * Tuning.TILE_SIZE * 0.5
		var start_name: String = data.setup.player.at
		t.check(start_name != "mark" and anchors.has(start_name), "%s starts off the mark" % name)
		if not anchors.has(start_name):
			continue
		var start := Vector2(anchors[start_name].tile[0], anchors[start_name].tile[1]) \
				* Tuning.TILE_SIZE + Vector2.ONE * Tuning.TILE_SIZE * 0.5
		t.check(start.distance_to(mark) > ResistanceDirector.SEEN_DISTANCE
				and start.distance_to(mark) < ResistanceDirector.NOTICE_RADIUS,
				"%s starts outside the mark's notice but within its reach of the day (%.0fpx)"
				% [name, start.distance_to(mark)])
		var at_first := []
		for check: Dictionary in data.playback.observations:
			if int(check.tick) == 1:
				at_first.append("%s %s" % [check.subject, check.condition])
		t.check("mark offered" in at_first and "mark unarrowed" in at_first,
				"%s asserts the mark unread and no arrow at the first tick" % name)
		t.check(not at_first.any(func(entry: String) -> bool: return entry.begins_with("task ")),
				"%s asserts nothing of the task before she has read the mark" % name)

## *(Inbox #650, "yes include his approach street.")* Day 9's crossing and the station door's corner
## list the street a sent robber starts on in `draft.include`, and ask that he pursues her once the
## task is done. The scenes' own headless play (`tools/scene-recipes.sh`) answers the asking; this
## keeps either from being dropped from the recipe.
func _test_the_door_scenes_show_the_robber_a_done_task_sends(t) -> void:
	for file: String in ["task-09-crossing", "station-door-corner"]:
		var data: Dictionary = SceneRecipe.load_file("res://scene-recipes/%s.json" % file).data
		t.check(not data.get("draft", {}).get("include", []).is_empty(),
				"%s lists the street the robber starts on" % file)
		var pursues := false
		var done_at := 0
		for check: Dictionary in data.playback.observations:
			if check.subject == "task" and check.condition == "done":
				done_at = int(check.tick)
		for check: Dictionary in data.playback.observations:
			if check.subject == "row:robber_giving_chase" and check.condition == "pursuing" \
					and int(check.tick) > done_at:
				pursues = true
		t.check(done_at > 0 and pursues,
				"%s asks that the robber pursues her once the task is done" % file)

## A scene recipe gives an authored loudspeaker a `mast_id`, the identity day 11's task and its red
## arrow answer to, so a scene can stand two masts and show the arrow move between them
## (`scene-recipes/task-11-two-masts.json`). Only a loudspeaker is a mast, and one id names one mast.
func _test_an_authored_mast_carries_its_own_id(t) -> void:
	var mast := func(name: String, row: String, id: Variant) -> Dictionary:
		var entry := {"name": name, "row": row, "at": [3440, 1936]}
		if id != null:
			entry["mast_id"] = id
		return entry
	var with := func(events: Array) -> Dictionary:
		var recipe := _recipe(11, {"mark": [2960, 2224]})
		recipe.setup["events"] = events
		return recipe
	t.check(SceneRecipeRuntime.validate_runtime(with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "south")])).is_empty(),
			"two loudspeakers with their own ids are accepted")
	t.check(_refused(with.call([mast.call("a", "charging_dog", "north")]),
			"belongs to a loudspeaker row"), "only a loudspeaker is given a mast id")
	t.check(_refused(with.call([mast.call("a", "loudspeaker", "north"),
			mast.call("b", "loudspeaker", "north")]), "unique nonempty string"),
			"two masts cannot share an id")
	t.check(_refused(with.call([mast.call("a", "loudspeaker", "")]), "unique nonempty string"),
			"an empty id names nothing")
	var data: Dictionary = SceneRecipe.load_file("res://scene-recipes/task-11-two-masts.json").data
	var ids := []
	for entry: Dictionary in data.setup.events:
		ids.append(entry.get("mast_id", ""))
	t.check(ids.size() == 2 and not "" in ids and ids[0] != ids[1],
			"the two-mast scene stands two masts under two ids")
