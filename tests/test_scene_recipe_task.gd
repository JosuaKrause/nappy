extends RefCounted
## A scene recipe's `setup.task`: what the schema accepts, and what the director does with a pinned
## mark and a pinned neighbor — stands the mark unread, places the task with its own placement when
## it is read, and
## refuses a pin rather than moving it. The scenes' own walks to their targets are
## `tools/scene-recipes.sh`'s headless assertions.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
## The context city every task scene is built on, so a mark here is a mark there.
const CONTEXT := 1917501
## An alley mouth of that city, the mark most task scenes start at.
const MOUTH := Vector2i(92, 69)
## The tile one step into that alley from the mouth, where its mark stands.
const MARK := Vector2i(92, 68)
## The seed `_recipe()` gives a scene, which a recipe boot starts its run on.
const RECIPE_SEED := 11

func run(t) -> void:
	t.gives_back_observers()
	_test_the_schema_names_a_mark_on_the_days_that_have_one(t)
	_test_the_task_observations_ask_about_the_task(t)
	_test_the_task_scenes_start_off_an_unread_mark(t)
	_test_the_door_scenes_show_the_robber_a_done_task_sends(t)
	_test_an_authored_mast_carries_its_own_id(t)
	_test_an_authored_mast_stands_only_where_the_days_masts_may(t)
	_test_a_pinned_mark_is_read_and_its_task_placed_near_it(t)
	_test_a_mark_is_touched_only_from_inside_its_alley(t)
	_test_a_mark_one_tile_in_keeps_its_guard_as_far_as_at_the_mouth(t)
	_test_a_mark_off_the_tile_in_from_a_mouth_is_refused_not_moved(t)
	_test_a_neighbor_start_the_day_could_not_draw_is_refused(t)
	_test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t)

func _recipe(day: int, task: Variant, observations := []) -> Dictionary:
	var setup := {"day": day}
	if task != null:
		setup["task"] = task
	return {"version": 1, "name": "task", "seed": RECIPE_SEED, "extent": {"scope": "full"},
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
## and a director, in a run of its own on that day (the recipes' seed, as a recipe boot starts its
## run), which the city and the director are handed. A fresh map each time, since a day's bodies and
## holds are recorded on it. `_free_day()` frees all three.
func _day(t, day: int) -> Array:
	var built := RecipeCityBuilder.build({"version": 1, "name": "task", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	t.check(built.errors.is_empty(), "the context city builds: %s" % [built.errors])
	var map: CityMap = built.map
	var own_run := RunState.new()
	own_run.start_run(RECIPE_SEED)
	own_run.header.day = day
	var state := CityState.new()
	own_run.attempt_spend.city_state = state
	state.begin_day(map.block_plans, day)
	var city: City = CITY_SCENE.instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(map)
	city.start_recipe_day(state, day, own_run.calendar.day_rng(day, "closures"))
	# A recipe that selects no gate or barrier stands no region wall either, the way
	# `SceneRecipeRuntime._select_structures()` leaves the day's plan.
	if city.region_plan():
		city.set_region_plan(RegionPlanner.RegionPlan.new())
	var empty: Array[EventScheduler.Planned] = []
	city.events.start_recipe(empty, DaySpec.for_day(day, Tuning.DAY_LENGTH_SECONDS), day,
			map.tile_to_world(MOUTH))
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, map)
	return [city, director, own_run]

func _free_day(made: Array) -> void:
	for node: Node in made:
		node.free()

func _test_a_pinned_mark_is_read_and_its_task_placed_near_it(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var own_run: RunState = made[2]
	var map := city.map
	var mark := map.tile_to_world(MARK)
	var errors := director.start_recipe_task(7, own_run.calendar.day_rng(7, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "a mark one tile in from an alley mouth is accepted: %s" % [errors])
	# *(Inbox #555, "Unread, walk to it".)* The scene begins with the mark standing unread and no
	# task on offer; a touch reads it and the task is placed then.
	t.check(director.read_mark() == null and director.contact() != null
			and director.contact().step.is_pickup and not director.contact().is_done
			and director.contact().global_position == mark,
			"the mark stands where the recipe put it, unread")
	t.check(director.current_step().is_pickup and director.red_arrow_target() == Vector2.INF
			and director.contact_position() == mark,
			"no task is on offer and no arrow is drawn before she reads it")
	t.check(not own_run.resistance.completed_steps.has(director.current_step().index),
			"nothing is completed at the start")
	director.contact().complete_now()
	var task := director.current_step()
	t.check(director.read_mark() != null and director.read_mark().global_position == mark
			and director.read_mark().is_done, "reading it leaves the mark standing, read")
	t.check(task != null and task.task_event_id == "delivery_van" and not task.is_pickup,
			"and the day's task is on offer")
	var target := director.contact_position()
	t.check(target.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK
			and target.distance_to(mark) < ResistanceDirector.NEAR_THE_MARK + Tuning.TILE_SIZE,
			"placed where a path from the mark first reaches the circle round her (%.0fpx)"
			% target.distance_to(mark))
	t.check(director.red_arrow_target() == target, "with its arrow on the van")
	_free_day(made)

## *(feathery-hare; azure-puffin, inbox #664: "let's move the chalk mark one tile into the alley so
## I actually have to enter the alley to activate it".)* The mark's centre is 48px in from the
## street's edge and a touch reaches 36px: her centre 14px inside the alley (her body wholly past the
## edge) touches it, standing on the pavement at the mouth, body wholly outside, does not, nor does
## the centre on the street's edge.
func _test_a_mark_is_touched_only_from_inside_its_alley(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var own_run: RunState = made[2]
	var map := city.map
	var mark := map.tile_to_world(MARK)
	var errors := director.start_recipe_task(7, own_run.calendar.day_rng(7, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "the mark is accepted: %s" % [errors])
	var outward := Vector2(MOUTH - MARK)
	var street_edge := mark + outward * Tuning.TILE_SIZE * 1.5
	var body := Tuning.PLAYER_BODY_RADIUS
	t.check(director.contact().would_complete_at(street_edge - outward * body),
			"standing in the alley, her body wholly past the street's edge, touches the mark")
	t.check(not director.contact().would_complete_at(street_edge + outward * body),
			"standing on the pavement at the mouth, her body wholly outside it, does not")
	t.check(not director.contact().would_complete_at(street_edge),
			"nor does her centre on the street's edge")
	_free_day(made)

## The guard keeps his distance from the mark (M213's floor and quiet-yak's "Two-thirds wins" weigh
## exactly as before): a mark one tile in has him one tile further in than for a mark on the mouth.
func _test_a_mark_one_tile_in_keeps_its_guard_as_far_as_at_the_mouth(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var map := city.map
	var rng := RandomNumberGenerator.new()
	var at_mouth := map.tile_to_world(MOUTH)
	var at_mark := map.tile_to_world(MARK)
	var from_mouth := director.guard_position(rng, at_mouth, true, Vector2.INF, false)
	var from_mark := director.guard_position(rng, at_mark, true, Vector2.INF, false)
	t.check(from_mouth != Vector2.INF and from_mark != Vector2.INF, "both marks get a guard")
	t.check(is_equal_approx(from_mouth.distance_to(at_mouth), from_mark.distance_to(at_mark)),
			"at the same distance from the mark (%.1fpx, %.1fpx)"
			% [from_mouth.distance_to(at_mouth), from_mark.distance_to(at_mark)])
	t.check(from_mark.distance_to(from_mouth) > Tuning.TILE_SIZE * 0.9,
			"one tile further in")
	_free_day(made)

func _test_a_mark_off_the_tile_in_from_a_mouth_is_refused_not_moved(t) -> void:
	var made := _day(t, 7)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var own_run: RunState = made[2]
	var map := city.map
	var inside := MOUTH + Vector2i.UP * 3
	t.check(map.tile_at(inside) == GameEnums.TileType.ALLEY
			and not ResistanceDirector.is_alley_mouth(map, inside),
			"the probe stands inside the mark's own alley, not at its mouth")
	var errors := director.start_recipe_task(7, own_run.calendar.day_rng(7, "resistance"), 300.0,
			map.tile_to_world(inside))
	t.check("\n".join(errors).contains("is not one tile in from an alley mouth"),
			"a mark in the middle of an alley is refused: %s" % [errors])
	t.check(director.current_step() == null, "and nothing is offered in its place")
	errors = director.start_recipe_task(7, own_run.calendar.day_rng(7, "resistance"), 300.0,
			map.tile_to_world(MOUTH))
	t.check("\n".join(errors).contains("is not one tile in from an alley mouth"),
			"and so is one on the mouth's own tile: %s" % [errors])
	_free_day(made)

func _test_a_neighbor_start_the_day_could_not_draw_is_refused(t) -> void:
	var made := _day(t, 10)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var own_run: RunState = made[2]
	var map := city.map
	var mark := map.tile_to_world(ResistanceDirector.mark_tile_of(map, Vector2i(66, 146)))
	# A sidewalk a block from her door: a few tiles of walk from home, nowhere near the band of
	# about `ResistanceDirector.NEIGHBOR_WALK_HOME_SECONDS` of walk the day draws a start from.
	var near_home := Vector2i(62, 84)
	t.check(map.tile_at(near_home) == GameEnums.TileType.SIDEWALK, "the probe stands on a sidewalk")
	var errors := director.start_recipe_task(10, own_run.calendar.day_rng(10, "resistance"), 300.0, mark,
			map.tile_to_world(near_home))
	t.check(errors.is_empty(), "the mark is accepted; the neighbor is drawn when she reads it")
	director.contact().complete_now()
	errors = director.scene_task_errors()
	t.check("\n".join(errors).contains("is not a start the day could draw"),
			"a neighbor start the day's draw could not make is refused: %s" % [errors])
	t.check(director.current_step() == null or director.current_step().is_pickup
			or director.rider() == null, "and no neighbor is sent home in its place")
	_free_day(made)

## *(Inbox #486: "Now just add a new mast close by".)* A recipe installs no mast it does not name, so
## day 11 meets a city with no live mast at all — which is still no mast near her, and one is put up
## where her path first reaches the circle round her.
func _test_day_eleven_puts_up_a_mast_where_no_mast_stands_at_all(t) -> void:
	var made := _day(t, 11)
	var city: City = made[0]
	var director: ResistanceDirector = made[1]
	var own_run: RunState = made[2]
	var mark := city.map.tile_to_world(MARK)
	var errors := director.start_recipe_task(11, own_run.calendar.day_rng(11, "resistance"), 300.0, mark)
	t.check(errors.is_empty(), "day 11's mark is accepted: %s" % [errors])
	director.contact().complete_now()
	t.check(director.scene_task_errors().is_empty() and director.current_step() != null
			and not director.current_step().is_pickup,
			"and its task finds a mast with none standing: %s" % [director.scene_task_errors()])
	var foot := city.events.mast_foot(director.mast_in_play())
	t.check(director.mast_in_play() != "" and foot != Vector2.INF
			and foot.distance_to(mark) >= ResistanceDirector.NEAR_THE_MARK,
			"a mast put up for it on the circle round her")
	_free_day(made)

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

## An authored mast is accepted by the checks `EventScheduler.place_masts()` makes of a site: a
## day with masts, ground a mast site would be offered that is not closed, held or the home block,
## and clear of the day's doors. (107, 60) is where day 11's own mast stands on the context city.
## Each site is installed as a recipe installs it (`install()`), into the day's city in a run of its
## own, and read off what the install says: a refused site is an install error naming the mast.
func _test_an_authored_mast_stands_only_where_the_days_masts_may(t) -> void:
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
	var street := city.map.network.segment_containing(tile)
	var shut: Array[RoadClosure] = city.closures().duplicate()
	shut.append(RoadClosure.new(RoadClosure.Kind.ROADWORKS, street))
	city.map.close_streets(shut)
	t.check(city.map.is_closed(tile), "fixture: the street's closure shuts the tile")
	t.check(not _mast_installs(t, made, at), "nor on a closed tile")
	city.map.close_streets(city.closures())
	city.map.hold_segment(city.map.network.segment_containing(tile).key())
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
func _mast_installs(t, made: Array, at: Vector2) -> bool:
	var city: City = made[0]
	var own_run: RunState = made[2]
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	var her := city.map.tile_to_world(MOUTH)
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"setup": {"day": own_run.header.day,
			"player": {"at": [her.x, her.y]},
			"events": [{"name": "mast", "row": "loudspeaker", "at": [at.x, at.y], "mast_id": "m"}]}},
			"manifest": {}, "anchors": {}, "map": city.map},
			RunConfig.parse(PackedStringArray(["--recipe", "test.json"]), "", true), own_run)
	var errors := runtime.install(city, player, player.get_node("Baby"),
			DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
	runtime.free()
	player.free()
	return not "\n".join(errors).contains("event mast fails")
