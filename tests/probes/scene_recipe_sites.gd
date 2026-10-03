extends RefCounted
## Prints production-accepted sites on one explicit construction context for recipe authoring.
## It varies no city seed; use the resulting coordinates as reviewed pins in saved recipes.

func run(_t) -> void:
	var data := {"version": 1, "name": "sites", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501}}
	var built := RecipeCityBuilder.build(data)
	var map: CityMap = built.map
	print("HOME ", map.doorstep_world_position())
	for day: int in [1, 13]:
		GameState.start_run(11)
		GameState.day = day
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var regions := RegionPlanner.plan_day(map, day, tree)
		var corridor := Corridor.of(tree)
		var doors := PackedVector2Array()
		for body in regions.door_bodies:
			doors.append(body.position)
			if body.def.id == "checkpoint_hut":
				print("GATE ", body.position)
		var def := EventCatalogue.by_id("leaf_blower" if day == 1 else "military_convoy")
		var ground := {}
		var tiles := EventScheduler._ground_for(def, map, ground, corridor,
				EventScheduler._role_for(def, day))
		tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.distance_squared_to(Vector2i(65, 60)) < b.distance_squared_to(Vector2i(65, 60)))
		var accepted := 0
		for tile in tiles:
			var prior: Array[EventScheduler.Planned] = []
			var at := map.tile_to_world(tile)
			var plan := EventScheduler.recipe_placement(def, day, map, at, 1, prior, corridor, doors)
			if not plan:
				continue
			print("SITE ", def.id, " tile=", tile, " world=", at, " path=", plan.path)
			accepted += 1
			if accepted >= 5:
				break
	GameState.day = 14
	var state := CityState.new()
	state.begin_day(map.block_plans, 14)
	map.repaint(state)
	var finale := FinalePlanner.plan(map, GameState.day_rng(14, "finale"))
	var guards := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)
	print("ESCAPE_EXIT ", FinalePlanner.service_exit_world_position(map))
	var found := 0
	for segment in finale.open_streets:
		var ground := EventScheduler._finale_ground(map, segment, guards,
				StreetTrees.footprint_tiles(map), FinalePlanner.service_exit_world_position(map))
		if ground.is_empty():
			continue
		print("ESCAPE_GUARD ", map.tile_to_world(ground[ground.size() / 2]), " street=", segment.key())
		found += 1
		if found >= 12:
			break
	var dog := EventCatalogue.by_id("charging_dog")
	print("DOG_LEAD ", Tuning.offscreen_lead(Vector2.RIGHT,
			dog.pursue_speed + Tuning.WALK_SPEED, dog.offscreen_notice))
