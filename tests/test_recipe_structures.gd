extends RefCounted
## Real runtime installation rejects incomplete structures and refreshes a felled tree's source.

func run(t) -> void:
	var prior_seed := GameState.run_seed
	var prior_day := GameState.day
	GameState.run_seed = 11
	GameState.day = 13
	var loaded := SceneRecipe.load_file("res://scene-recipes/trailer-trucks.json")
	var data: Dictionary = loaded.data.duplicate(true)
	data.setup = {"day": 13, "player": {"at": [16, 16]}}
	var built := RecipeCityBuilder.build(data)
	built.data = data
	var packed: PackedScene = load("res://scenes/world/city.tscn")
	var city: City = packed.instantiate()
	t.add_child(city)
	city.build(built.map)
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 13)
	city.start_recipe_day(state, 13, GameState.day_rng())
	var player_scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = player_scene.instantiate()
	t.add_child(player)
	var baby: Baby = player.get_node("Baby")
	var runtime := SceneRecipeRuntime.new()
	runtime.configure(built, false)
	var selected := Vector3i(-1, -1, -1)
	var home := ClosurePlanner.home_street(city.map)
	for key: Vector3i in StreetTrees.segment_keys_with_trees(city.map):
		var segment := StreetNetwork.by_key(key)
		if city.map.has_street(key) and not city.route_tree().is_on_the_tree(key) \
				and (not home or key != home.key()) and not SealPlanner._is_the_main_road(city.map, segment):
			selected = key
			break
	t.check(selected.x >= 0, "tree regression has a real eligible off-route street")
	if selected.x >= 0:
		data.setup.seals = [{"segment": [selected.x, selected.y, selected.z], "candidate": "fallen_tree_seal"}]
		var errors := runtime.install(city, player, baby)
		t.check(errors.is_empty(), "authored fallen tree installs through production siting: %s" % [errors])
		t.check(city.map._seal_tree_pits.size() == 1, "authored fallen tree empties exactly one source pit")
		for tile: Vector2i in city.map._seal_tree_pits:
			t.check(city._street_tree_pits.has(tile) and not (city._street_tree_pits[tile] as Prop).visible,
					"runtime hides the standing source tree after installing its fallen seal")
		data.setup.erase("seals")
		errors = runtime.install(city, player, baby)
		t.check(errors.is_empty() and city.map._seal_tree_pits.is_empty(), "reinstallation clears unselected fallen-tree state")
		for tree: Prop in city._street_trees:
			t.check(tree.visible, "standing source trees return when no authored fallen tree selects them")
	city.map.recipe_bounds = Rect2i(0, 0, 14, 14)
	for collection in ["gates", "barriers", "seals"]:
		var entry := {"segment": [7, 6, 0]} if collection == "gates" else {"segment": [3, 5, 0]}
		if collection == "barriers":
			entry.end = "b"
		elif collection == "seals":
			entry.candidate = "cafe_pair"
		data.setup[collection] = [entry]
		var errors := runtime.install(city, player, baby)
		t.check("\n".join(errors).contains("leaves the authored extent"),
				"%s outside a bounded scene rejects instead of silently dropping bodies" % collection)
		data.setup.erase(collection)
	runtime.free()
	player.free()
	city.free()
	GameState.run_seed = prior_seed
	GameState.day = prior_day
