extends RefCounted
## What `SceneRecipeRuntime.install()` does with the world it is handed: the structures it
## refuses, the ones it stands as the day's own stand, what it asks of the stand-ins round it,
## and the one spec and the one ground it hands the walk.
##
## **One module, on a world of stand-ins** (`tests/scene_world.gd`): the dressing, the crowd,
## the events, the poster walls, her and the baby record what they are asked and answer what a
## recipe's map gives them. The map and today's streets are real (model data a recipe builds,
## and the day's own planners), and so are the day's static placement functions the runtime goes
## through (`SealPlanner.seal_street()`, `RegionPlanner.stand_door()`, `MastSites`,
## `PlanBuilder`): that the runtime goes through them is what "an authored X stands as the
## day's" means, so they run real here. What the city scene does with the answers, the street
## trees it hides and the buildings it dresses, is the city's suites'
## (`tests/test_recipe_city_drawing.gd`), and what the event manager and the crowd do with the
## plans and actors they are handed is theirs.

const STROLLER_SCENE_AT := Vector2i(16, 16)
## The context city every task scene is built on.
const CONTEXT := 1917501
## An alley mouth of that city, where a mast scene's player starts.
const MOUTH := Vector2i(92, 69)
## The seed a recipe boot starts its run on.
const RECIPE_SEED := 11
## Where day 11's own mast stands on the context city, a sidewalk a mast may be put on.
const MAST_AT := Vector2(3440, 1936)

func run(t: TestRunner) -> void:
	var loaded := SceneRecipe.load_file("res://scene-recipes/trailer-trucks.json")
	var loaded_data: Dictionary = loaded.data
	var data: Dictionary = loaded_data.duplicate(true)
	var setup := {"day": 13, "player": {"at": [16, 16]}}
	data.setup = setup
	var built := RecipeCityBuilder.build(EventCatalogue.shipped(), data)
	built.data = data
	var own_run := _run_on(13)
	var base: CityMap = built.map
	var start_tile := STROLLER_SCENE_AT
	var tile_before := base.tile_at(start_tile)
	var street_before := base.is_street(start_tile)
	_test_a_fallen_tree_empties_its_pit_before_the_trees_are_refreshed(t, built, data, own_run)
	_test_a_bounded_scene_rejects_what_leaves_its_extent(t, data, own_run)
	t.check(base.tile_at(start_tile) == tile_before and base.is_street(start_tile) == street_before,
			"the map after the bounded case is the map before it, at her start tile")
	_test_an_authored_door_stands_as_the_days(t, built, data, own_run)
	_test_an_authored_soft_seal_stands_as_the_days(t, built, data, own_run)
	_test_a_column_scene_hands_the_happenings_the_dressings_fronts(t, built, data, own_run)
	_test_the_scene_runs_under_the_spec_it_is_handed(t, built, data, own_run)
	_test_the_walk_is_handed_the_scenes_ground(t, built, data, own_run)
	_test_the_walk_is_handed_the_scenes_tree_and_locations(t, built, data, own_run)
	_test_an_oversized_uniform_population_is_refused(t)
	_test_an_authored_mast_stands_only_where_the_days_masts_may(t)

## A run of its own on `day`, handed to the runtime as `main` hands it the game's.
func _run_on(day: int) -> RunState:
	var own_run := RunState.new()
	own_run.start_run(RECIPE_SEED)
	own_run.header().set_day(day)
	return own_run

## A world over a copy of `built`'s map on the run's day, and the runtime over that map and `data`.
## `[SceneWorld, SceneRecipeRuntime]`: the suite frees both.
func _stand(built: Dictionary, data: Dictionary, own_run: RunState) -> Array:
	var on: CityMap = (built.map as CityMap).copy()
	var made := SceneWorld.over(on, own_run.header().day())
	var for_this_map: Dictionary = built.duplicate()
	for_this_map.map = on
	for_this_map.data = data
	var runtime := SceneRecipeRuntime.new()
	runtime.configure(EventCatalogue.shipped(), for_this_map,
			RunConfig.parse(PackedStringArray(["--recipe", "test.json"]), "", true), own_run)
	return [made, runtime]

func _day_spec(own_run: RunState) -> DaySpec:
	return DaySpec.for_day(own_run.header().day(), Tuning.DAY_LENGTH_SECONDS)

func _free(stood: Array) -> void:
	(stood[1] as SceneRecipeRuntime).free()
	(stood[0] as SceneWorld).free_all()

## **An authored fallen tree** installs through the day's seal siting and empties exactly one pit
## (`CityMap.is_tree_pit_emptied()`), and the city is asked to refresh its street trees after that
## pit is emptied (the dressing records the pits emptied at each ask). A reinstall with no seal
## clears the pit, and the refresh is asked with none emptied.
func _test_a_fallen_tree_empties_its_pit_before_the_trees_are_refreshed(t: TestRunner,
		built: Dictionary, data: Dictionary, own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var spec := _day_spec(own_run)
	var once: Array[int] = [1]
	var then_none: Array[int] = [1, 0]
	var selected := Vector3i(-1, -1, -1)
	for key: Vector3i in StreetTrees.segment_keys_with_trees(made.map):
		if SealPlanner.may_seal(made.map, spec, made.streets.route_tree(),
				made.map.street_network().by_key(key)):
			selected = key
			break
	t.check(selected.x >= 0, "tree regression has a real eligible off-route street")
	if selected.x >= 0:
		var setup: Dictionary = data.setup
		setup.seals = [{"segment": [selected.x, selected.y, selected.z], "candidate": "fallen_tree_seal"}]
		var errors := runtime.install(made.world, spec)
		t.check(errors.is_empty(),
				"authored fallen tree installs through production siting: %s" % [errors])
		t.check(_emptied_pits(made.map).size() == 1,
				"authored fallen tree empties exactly one source pit")
		t.check(made.dressing.emptied_pits_at_each_refresh() == once,
				"the city is asked to refresh its street trees once the pit is emptied (%s)"
				% [made.dressing.emptied_pits_at_each_refresh()])
		setup.erase("seals")
		errors = runtime.install(made.world, spec)
		t.check(errors.is_empty() and _emptied_pits(made.map).is_empty(),
				"reinstallation clears unselected fallen-tree state")
		t.check(made.dressing.emptied_pits_at_each_refresh() == then_none,
				"and the refresh is asked again with no pit emptied (%s)"
				% [made.dressing.emptied_pits_at_each_refresh()])
	_free(stood)

## The street trees' pits the day has emptied (`CityMap.is_tree_pit_emptied()`, what the city reads
## to hide a tree).
func _emptied_pits(map: CityMap) -> Array[StreetTrees.Planted]:
	var emptied: Array[StreetTrees.Planted] = []
	for pit in StreetTrees.planted(map):
		if map.is_tree_pit_emptied(pit.tile):
			emptied.append(pit)
	return emptied

## **A bounded scene rejects a gate, barrier or seal outside its extent** instead of silently
## dropping the bodies. The scene is a map of its own, built from the recipe with a bounded
## extent through `RecipeCityBuilder`, so the full-scope map the other cases use keeps its
## tiles.
func _test_a_bounded_scene_rejects_what_leaves_its_extent(t: TestRunner, data: Dictionary,
		own_run: RunState) -> void:
	var bounded_data: Dictionary = data.duplicate(true)
	bounded_data.extent = {"scope": "bounded", "bounds": [0, 0, 14, 14]}
	var setup: Dictionary = bounded_data.setup
	bounded_data.anchors = {"start": {"tile": [8, 8]}}
	setup.player = {"at": [8, 8]}
	var bounded := RecipeCityBuilder.build(EventCatalogue.shipped(), bounded_data)
	var build_errors: Array = bounded.errors
	t.check(build_errors.is_empty(), "the bounded recipe builds: %s" % [build_errors])
	if not build_errors.is_empty():
		return
	var stood := _stand(bounded, bounded_data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	for collection: String in ["gates", "barriers", "seals"]:
		var entry := {"segment": [7, 6, 0]} if collection == "gates" else {"segment": [3, 5, 0]}
		if collection == "barriers":
			entry.end = "b"
		elif collection == "seals":
			entry.candidate = "cafe_pair"
		setup[collection] = [entry]
		var errors := runtime.install(made.world, _day_spec(own_run))
		t.check("\n".join(errors).contains("leaves the authored extent"),
				"%s outside a bounded scene rejects instead of silently dropping bodies" % collection)
		setup.erase(collection)
	_free(stood)

## **An authored checkpoint stands as the day's own door does**: the recipe selects one of the day's
## street doors (`RegionPlanner.plan_day()`), and the plan it installs holds that door, its three
## bodies where the day's stand, as the same rows, and its gate — the one entry both stand a door
## through (`RegionPlanner.stand_door()`).
func _test_an_authored_door_stands_as_the_days(t: TestRunner, built: Dictionary, data: Dictionary,
		own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var days := RegionPlanner.plan_day(EventCatalogue.shipped(), made.map, DaySpec.for_day(own_run.header().day()),
			made.streets.route_tree())
	t.check(not days.door_segments().is_empty(), "the day has a street door to author")
	if not days.door_segments().is_empty():
		var setup: Dictionary = data.setup
		var door: StreetNetwork.Segment = days.door_segments()[0]
		var bodies := days.door_plans().slice(0, 3)
		made.streets.replace_region_plan(days)
		var key := door.key()
		setup.gates = [{"segment": [key.x, key.y, key.z]}]
		var errors := runtime.install(made.world, _day_spec(own_run))
		var authored := made.streets.region_plan()
		var authored_doors := authored.door_segments()
		t.check(errors.is_empty() and authored_doors.size() == 1 and authored_doors[0].key() == key
				and authored.gate_states().size() == 1
				and authored.door_plans().size() == bodies.size(),
				"the authored door is the day's street, with its gate and its bodies: %s" % [errors])
		var same := authored.door_plans().size() == bodies.size()
		for i in mini(authored.door_plans().size(), bodies.size()):
			var mine: EventPlan = authored.door_plans()[i]
			var theirs: EventPlan = bodies[i]
			same = same and mine.placed_at() == theirs.placed_at() and mine.row_id() == theirs.row_id() \
					and mine.faces() == theirs.faces()
		t.check(same, "and each body stands where the day's does, as the same row")
		setup.erase("gates")
	_free(stood)

## **An authored soft seal stands as the day's own would**: on an off-walk street the day may
## seal (`SealPlanner.may_seal()`), its two bodies, read off the plans the events were handed,
## stand where the day's pass sites the same picture (`SealPlanner.seal_street()`), and both of
## the street's sidewalks are shut to walkers there.
func _test_an_authored_soft_seal_stands_as_the_days(t: TestRunner, built: Dictionary,
		data: Dictionary, own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var map := made.map
	var spec := _day_spec(own_run)
	var cafe := SealPlanner.candidate_named("cafe_pair")
	var street: StreetNetwork.Segment = null
	for segment in map.street_network().segments():
		if SealPlanner.may_seal(map, spec, made.streets.route_tree(), segment) \
				and map.has_street(segment.key()) \
				and not RegionPlanner.boundary_segments(map).has(segment):
			street = segment
			break
	t.check(cafe != null and street != null, "the day has a street a café pair may seal")
	if cafe != null and street != null:
		var expected := SealPlanner.seal_street(EventCatalogue.shipped(), map, street, cafe, made.streets.route_tree(),
				StreetTrees.footprint_tiles(map), [] as Array[Vector2i])
		var key := street.key()
		var setup: Dictionary = data.setup
		setup.seals = [{"segment": [key.x, key.y, key.z], "candidate": "cafe_pair"}]
		var errors := runtime.install(made.world, spec)
		t.check(errors.is_empty(), "the café pair installs: %s" % [errors])
		# Compared at the grain the placement decides — how far along the street, and which
		# sidewalk — since a body on a sidewalk is centred on its band as it is set up, in a recipe
		# as on a day.
		var centre := map.tile_rect_to_world(street.tile_rect()).get_center()
		var stands: Array[Vector2] = []
		for plan in made.events.plans():
			if plan.row_id() == "cafe_tables":
				stands.append(_along_and_side(street, centre, plan.placed_at()))
		var where: Array[Vector2] = []
		for body in expected.bodies():
			where.append(_along_and_side(street, centre, body.placed_at()))
		stands.sort()
		where.sort()
		t.check(stands == where, "its bodies stand where the day's pass sites the same picture, one on"
				+ " each sidewalk (along, side): %s, %s" % [stands, where])
		var shut := 0
		for tile in map.rect_tiles(street.tile_rect()):
			if not map.passable(tile, Mover.of(Mover.SOFT_SEALS)):
				shut += 1
		t.check(shut == 2 * Tuning.SIDEWALK_WIDTH,
				"and both its sidewalks are shut to walkers there (%d tiles)" % shut)
		setup.erase("seals")
	_free(stood)

## Where `at` stands on `street`: how far along it, and which side of its centre line (-1 or 1).
func _along_and_side(street: StreetNetwork.Segment, centre: Vector2, at: Vector2) -> Vector2:
	if street.horizontal:
		return Vector2(at.x, signf(at.y - centre.y))
	return Vector2(at.y, signf(at.x - centre.x))

## **A scene on day 11 or later hands the happenings the dressing's fronts**, which board the
## neighbor's window as the happenings' day start does for a played day
## (`ResistanceHappenings.start_day()`): day 13's column is the scene that starts the happenings.
func _test_a_column_scene_hands_the_happenings_the_dressings_fronts(t: TestRunner,
		built: Dictionary, data: Dictionary, own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var fronts := FakeCityFronts.new()
	made.dressing.front_with(fronts)
	t.check(fronts.boardings() == 0,
			"the neighbor's window stands unboarded before the column scene installs")
	var setup: Dictionary = data.setup
	setup.column = {"at": [1904, 2312], "direction": "north"}
	var errors := runtime.install(made.world, _day_spec(own_run))
	t.check(errors.is_empty(), "the column scene installs: %s" % [errors])
	t.check(fronts.boardings() >= 1,
			"and the neighbor's window is boarded through the dressing's fronts")
	setup.erase("column")
	_free(stood)

## **One spec for an authored scene**: the walk the run flow started — the one its clock and HUD run
## on (`DayDirector.start()`, a day's or the escape boot's section) — is the very object the scene's
## events are started under (`EventManager.start_recipe()`), handed through `install()`, with no
## second spec built beside it: for an escape section's spec and for a day's with `--day-length 77`.
func _test_the_scene_runs_under_the_spec_it_is_handed(t: TestRunner, built: Dictionary,
		data: Dictionary, own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var escape := DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
	var errors := runtime.install(made.world, escape)
	t.check(errors.is_empty() and made.events.recipe_spec() == escape,
			"an escape scene's events are started under the spec it is handed: %s" % [errors])
	var configured := RunConfig.parse(PackedStringArray(["--day-length", "77"]), "", true)
	var day := DaySpec.for_day(own_run.header().day(),
			configured.day_length_for(own_run.header().day()))
	errors = runtime.install(made.world, day)
	t.check(errors.is_empty() and made.events.recipe_spec() == day,
			"and a day's, configured with its own length, is the one its events are started under: %s"
			% [errors])
	_free(stood)

## **The scene's ground is handed to the walk**: `start_recipe()` is handed one, made on the map
## as the install held it, and it offers a row none of the home's street, which a ground with no
## rule would. (The install holds the home's streets for every spec, so the ground cannot show
## the walk spec's own home-street rule, which is `tests/test_walk_siting_spec.gd`'s.)
func _test_the_walk_is_handed_the_scenes_ground(t: TestRunner, built: Dictionary,
		data: Dictionary, own_run: RunState) -> void:
	var def := EventCatalogue.shipped().by_id("burning_building")
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var errors := runtime.install(made.world, _day_spec(own_run))
	var ground := made.events.recipe_ground()
	t.check(errors.is_empty() and ground != null,
			"the walk is handed the scene's ground: %s" % [errors])
	if ground != null:
		var home := ClosurePlanner.home_street(made.map).tile_rect()
		var unruled := EventScheduler.row_ground(built.map, Corridor.of(made.streets.route_tree()), false)
		var home_offered := 0
		for tile in unruled.tiles_for(def):
			home_offered += int(home.has_point(tile))
		t.check(home_offered > 0, "fixture: a ground with no rule offers the home's street (%d tiles)"
				% home_offered)
		var kept_off := true
		for tile in ground.tiles_for(def):
			kept_off = kept_off and not home.has_point(tile)
		t.check(kept_off, "and the ground it is handed, made on the map as the install held it, "
				+ "offers none of it")
	_free(stood)

## **The scene's route tree and locations are handed to the walk**: `start_recipe()` is handed
## the tree the day's streets hold (the one the rows' corridor is made of) and the locations
## laid out over that corridor, so a siting made as she walks grows and lays out neither again;
## a scene with no route tree is handed neither.
func _test_the_walk_is_handed_the_scenes_tree_and_locations(t: TestRunner, built: Dictionary,
		data: Dictionary, own_run: RunState) -> void:
	var stood := _stand(built, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var errors := runtime.install(made.world, _day_spec(own_run))
	t.check(errors.is_empty() and made.streets.route_tree() != null
			and made.events.recipe_tree() == made.streets.route_tree(),
			"the walk is handed the route tree the day's streets hold: %s" % [errors])
	var handed := made.events.recipe_locations()
	var over_its_corridor := DayLocations.lay_out(made.map,
			Corridor.of(made.streets.route_tree()))
	var with_no_corridor := DayLocations.lay_out(made.map, Corridor.of(null))
	var views_handed := _views_of(handed)
	var views_over_corridor := _views_of(over_its_corridor)
	t.check(views_over_corridor != _views_of(with_no_corridor),
			"fixture: on this scene a layout with no corridor tells the views differently")
	t.check(not views_handed.is_empty() and views_handed == views_over_corridor,
			"and the locations are the ones laid out over its corridor, with its views (%d)"
			% views_handed.size())
	_free(stood)
	# A scene with no route tree lays its locations out under a corridor that answers none, so
	# the walk is handed neither.
	var treeless := _stand(built, data, own_run)
	var bare: SceneWorld = treeless[0]
	bare.streets.begin_day(null, null, [] as Array[RoadClosure])
	var bare_runtime: SceneRecipeRuntime = treeless[1]
	var bare_errors := bare_runtime.install(bare.world, _day_spec(own_run))
	t.check(bare_errors.is_empty() and bare.events.recipe_tree() == null
			and bare.events.recipe_locations() == null,
			"a scene with no route tree hands the walk neither: %s" % [bare_errors])
	_free(treeless)

## The view each of `locations`' locations has of the routes, in the order they are laid out:
## what a layout over a corridor tells that one with no corridor does not. Empty for none.
func _views_of(locations: DayLocations) -> Array[int]:
	var views: Array[int] = []
	if locations == null:
		return views
	for location in locations.all():
		views.append(location.view())
	return views

## **An oversized city-wide uniform population is refused, not truncated**: the crowd placed fewer
## walkers than the recipe's area and multiplier asked for (8,444 of the 8,540 asked, read off the
## real crowd for this recipe once), and the install says so.
func _test_an_oversized_uniform_population_is_refused(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var oversized: Dictionary = recipe.duplicate(true)
	oversized.setup = {"day": 1, "background": {"crowd": true, "crowd_scope": "city",
			"uniform_walkers": true, "walker_multiplier": 4}}
	var built := RecipeCityBuilder.build(EventCatalogue.shipped(), oversized)
	var build_errors: Array = built.errors
	t.check(build_errors.is_empty(), "the recipe builds: %s" % [build_errors])
	if not build_errors.is_empty():
		return
	built.data = oversized
	var own_run := _run_on(1)
	var stood := _stand(built, oversized, own_run)
	var made: SceneWorld = stood[0]
	made.crowd.count_is(8444)
	var runtime: SceneRecipeRuntime = stood[1]
	var errors := runtime.install(made.world, _day_spec(own_run))
	t.check("\n".join(errors).contains("too few eligible sidewalk positions"),
			"oversized city-wide uniform population rejects instead of silently truncating")
	_free(stood)

## **An authored mast is accepted by the checks `DawnMasts` makes of a site**: a day with masts,
## ground a mast site would be offered that is not closed, held or the home block, and clear of the
## day's doors. Each site is installed as a recipe installs it (`install()`), with her at the alley
## mouth, and read off what the install says: a refused site is an install error naming the mast.
func _test_an_authored_mast_stands_only_where_the_days_masts_may(t: TestRunner) -> void:
	var context := RecipeCityBuilder.build(EventCatalogue.shipped(), {"version": 1, "name": "task", "seed": RECIPE_SEED,
			"extent": {"scope": "full"}, "city": {"context_seed": CONTEXT}})
	var context_errors: Array = context.errors
	t.check(context_errors.is_empty(), "the context city builds: %s" % [context_errors])
	if not context_errors.is_empty():
		return
	var day := 11
	var standing := _mast_install_errors(t, context, day, MAST_AT)
	t.check(standing.is_empty(),
			"a mast stands on an eligible sidewalk of a day with masts: %s" % [standing])
	# A site within the reach of a door a street could stand at (`MastSites`, the ground a mast is
	# offered) is refused: found as a tile that only that reach rules out, so the install's refusal
	# is the door's.
	var beside_a_door := _a_site_only_a_door_rules_out(context.map)
	t.check(beside_a_door != Vector2.INF and not _mast_installs(t, context, day, beside_a_door),
			"but not with its field on the ground a door could stand beside")
	t.check(not _mast_installs(t, context, day, MAST_AT, "closed"), "nor on a closed tile")
	t.check(not _mast_installs(t, context, day, MAST_AT, "held"), "nor on a held street")
	t.check(not _mast_installs(t, context, Tuning.MAST_FIRST_DAY - 1, MAST_AT),
			"nor on a day before the masts")

## A sidewalk or square point of `map` that a mast site is refused only for lying within the
## reach of a point a street door could stand at: ground that is open, unheld, off the home
## block, and that `MastSites.is_eligible()` accepts when no door is handed in, or `Vector2.INF`
## when there is none.
func _a_site_only_a_door_rules_out(map: CityMap) -> Vector2:
	var reach := Tuning.CHECKPOINT_EVENT_GAP + EventCatalogue.shipped().mast().field_reach()
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
				if MastSites.is_eligible(EventCatalogue.shipped(), at, map, nowhere) and not MastSites.is_eligible(EventCatalogue.shipped(), at, map):
					return at
	return Vector2.INF

## Whether the install takes a recipe's loudspeaker at `at` on `day`: false only when its errors
## name the mast (`_mast_install_errors()`), so an install that fails for another reason counts as
## taking it, and the case that a mast stands asserts no error at all.
func _mast_installs(t: TestRunner, context: Dictionary, day: int, at: Vector2, shut := "") -> bool:
	return not "\n".join(_mast_install_errors(t, context, day, at, shut)).contains("event mast fails")

## What the runtime's own `install()` says of a recipe's loudspeaker at `at` on `day` over a copy of
## `context`'s map, with her at the alley mouth. `shut` is "closed" to shut the street the site is
## on first, "held" to hold it, "" for neither.
func _mast_install_errors(t: TestRunner, context: Dictionary, day: int, at: Vector2,
		shut := "") -> Array[String]:
	var own_run := _run_on(day)
	var her := (context.map as CityMap).tile_to_world(MOUTH)
	var data := {"setup": {"day": day, "player": {"at": [her.x, her.y]},
			"events": [{"name": "mast", "row": "loudspeaker", "at": [at.x, at.y], "mast_id": "m"}]}}
	var stood := _stand(context, data, own_run)
	var made: SceneWorld = stood[0]
	var runtime: SceneRecipeRuntime = stood[1]
	var tile := made.map.world_to_tile(at)
	var street := made.map.street_network().segment_containing(tile)
	if shut == "closed":
		var closed: Array[RoadClosure] = made.streets.closures().duplicate()
		closed.append(RoadClosure.new(RoadClosure.Kind.ROADWORKS, street))
		made.map.close_streets(closed)
		t.check(made.map.is_closed(tile), "fixture: the street's closure shuts the tile")
	elif shut == "held":
		made.map.hold_segment(street.key(), HeldStreets.Why.SEAL)
	var errors := runtime.install(made.world, _day_spec(own_run))
	_free(stood)
	return errors
