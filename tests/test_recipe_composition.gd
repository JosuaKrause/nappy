extends RefCounted
## Authored scenery shares the production tree source, and pedestrian overrides end with a day.
const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(recipe)
	t.check(built.errors.is_empty(), "opposite-curb tree recipe constructs: %s" % [built.errors])
	if not built.errors.is_empty():
		return
	var source := Vector2i(50, 74)
	var destination := Vector2i(50, 71)
	var pits := {}
	for tree in StreetTrees.planted(built.map):
		pits[tree.tile] = tree
	t.check(not pits.has(source) and pits.has(destination), "planning moves the original tree pit across the road")
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(built.map)
	t.check(not city._street_tree_pits.has(source) and city._street_tree_pits.has(destination),
			"real tree props and pit rendering use the relocated planning source")
	var tree: Prop = city._street_tree_pits[destination]
	t.check(tree.position == city.map.tile_to_world(destination) and tree.kind == Prop.Kind.STREET_TREE,
			"relocation retains a real existing street-tree component")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	city.crowd.start_day(1, rng, Vector2(1952, 1936), true, false, true, 2)
	var counts := {}
	var before := {}
	var cars := 0
	for agent in city.crowd.agents():
		if agent.kind == CrowdAgent.Kind.CAR:
			cars += 1
			continue
		var key := "%s%d" % ["v" if agent.travelling_vertically() else "h", agent.get("_corridor")]
		counts[key] = int(counts.get(key, 0)) + 1
		before[agent] = agent.position
	t.check(cars == Tuning.crowd_cars(1) and before.size() == Tuning.crowd_pedestrians(1) * 2,
			"recipe increases only walkers while retaining ordinary car population")
	var main_count := int(counts.get("v%d" % city.map.main_road, 0))
	var ordinary_max := 0
	for key: String in counts:
		if key != "v%d" % city.map.main_road:
			ordinary_max = maxi(ordinary_max, counts[key])
	t.check(main_count > 0 and ordinary_max > 0 and main_count < ordinary_max * 2,
			"uniform pedestrian selection does not concentrate the field on the main road")
	for frame in 30:
		city.crowd.step(1.0 / 30.0)
	var moving := 0
	for agent: CrowdAgent in before:
		var distance := agent.position.distance_to(before[agent])
		moving += int(distance > 1 and distance < Tuning.PEDESTRIAN_SPEED.y * 1.5)
	t.check(moving > before.size() / 2, "authored density retains physically moving production walkers")
	city.crowd.start_day(1, rng)
	t.check(not city.crowd.field().uniform_walkers
			and city.crowd.agent_count() == Tuning.crowd_pedestrians(1) + Tuning.crowd_cars(1),
			"ordinary day restores its density and street hierarchy")
	city.free()
	for target in [[50, 73], [51, 71]]:
		var invalid: Dictionary = recipe.duplicate(true)
		invalid.city.tree_moves[0].to = target
		t.check(not RecipeCityBuilder.build(invalid).errors.is_empty(), "tree relocation refuses road or unrelated sidewalk")
	var title: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-title.json").data
	var park := RecipeCityBuilder.build(title)
	var at: Vector2 = park.anchors.start
	t.check(park.map.tile_at(park.map.world_to_tile(at)) == GameEnums.TileType.PARK,
			"title begins inside the existing park")
	var capture := at + Vector2.DOWN * Tuning.WALK_SPEED * float(title.playback.capture_at)
	t.check(park.map.tile_at(park.map.world_to_tile(capture)) == GameEnums.TileType.PARK,
			"title's moving capture remains inside the park")
