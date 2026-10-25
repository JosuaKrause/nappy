extends RefCounted
## Real runtime installation rejects incomplete structures and refreshes a felled tree's source, and
## runs the scene's events under the one spec the run flow hands it.

const MAIN := preload("res://src/main.gd")

func run(t) -> void:
	var prior_seed := GameState.header.run_seed
	var prior_day := GameState.header.day
	GameState.header.run_seed = 11
	GameState.header.day = 13
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
	runtime.configure(built, RunConfig.parse(PackedStringArray(["--recipe", "test.json"]), "", true))
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
		var errors := runtime.install(city, player, baby, DaySpec.for_day(GameState.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check(errors.is_empty(), "authored fallen tree installs through production siting: %s" % [errors])
		t.check(city.map._seal_tree_pits.size() == 1, "authored fallen tree empties exactly one source pit")
		for tile: Vector2i in city.map._seal_tree_pits:
			t.check(city._street_tree_pits.has(tile) and not (city._street_tree_pits[tile] as Prop).visible,
					"runtime hides the standing source tree after installing its fallen seal")
		data.setup.erase("seals")
		errors = runtime.install(city, player, baby, DaySpec.for_day(GameState.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check(errors.is_empty() and city.map._seal_tree_pits.is_empty(), "reinstallation clears unselected fallen-tree state")
		for tree: Prop in city._street_trees:
			t.check(tree.visible, "standing source trees return when no authored fallen tree selects them")
	var authored_bounds := city.map.recipe_bounds
	city.map.recipe_bounds = Rect2i(0, 0, 14, 14)
	for collection in ["gates", "barriers", "seals"]:
		var entry := {"segment": [7, 6, 0]} if collection == "gates" else {"segment": [3, 5, 0]}
		if collection == "barriers":
			entry.end = "b"
		elif collection == "seals":
			entry.candidate = "cafe_pair"
		data.setup[collection] = [entry]
		var errors := runtime.install(city, player, baby, DaySpec.for_day(GameState.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check("\n".join(errors).contains("leaves the authored extent"),
				"%s outside a bounded scene rejects instead of silently dropping bodies" % collection)
		data.setup.erase(collection)
	city.map.recipe_bounds = authored_bounds
	_test_the_scene_runs_under_the_spec_it_is_handed(t, runtime, city, player, baby)
	runtime.free()
	player.free()
	city.free()
	GameState.header.run_seed = prior_seed
	GameState.header.day = prior_day

## **One spec for an authored scene**: the walk the run flow started — the one its clock and HUD run
## on (`main._start_recipe_day()`, or the escape boot's section) — is the spec the scene's events run
## under, handed through `install()`, with no second spec built beside it. An escape scene's events
## owe no return and a torn poster sends nobody there; a day scene's walk is the day as configured,
## `--day-length` included (`main.day_spec()`), and its events run with a day's settings, a torn
## poster sending its pursuer.
func _test_the_scene_runs_under_the_spec_it_is_handed(t, runtime: SceneRecipeRuntime, city: City,
		player: Stroller, baby: Baby) -> void:
	player.global_position = city.map.tile_to_world(Vector2i(16, 16))
	city.events._player = player
	var escape := MAIN.escape_section_spec(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
	var errors := runtime.install(city, player, baby, escape)
	t.check(errors.is_empty() and runtime.walk_spec == escape,
			"an escape scene is installed into the spec it is handed: %s" % [errors])
	t.check(not city.events._owes_a_return and not city.events._sends_poster_pursuits,
			"and its events owe no return and send no poster pursuer")
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().is_empty(), "so a torn poster there sends nobody")

	var day := MAIN.day_spec(RunConfig.parse(PackedStringArray(["--day-length", "77"]), "", true),
			GameState.header.day)
	t.check(is_equal_approx(day.length, 77.0),
			"a day scene's walk is the configured day's length (%.1fs)" % day.length)
	errors = runtime.install(city, player, baby, day)
	t.check(errors.is_empty() and runtime.walk_spec == day
			and city.events._owes_a_return and city.events._sends_poster_pursuits,
			"and the same spec, with a day's settings, is the one its events run under: %s" % [errors])
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().size() == 1,
			"so a torn poster on a day scene sends its pursuer (%d warnings)"
			% city.events.pending_warnings().size())
	city.events._pending.clear()
