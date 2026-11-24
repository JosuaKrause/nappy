extends RefCounted
## **The real `City` draws the maps a recipe builds**: the power station recipes' bounded context and
## their two examples are built by `RecipeCityBuilder` (`tests/test_scene_recipe.gd`'s) and handed to
## a real `City`, which gives the exterior the plain ground, extends the hall roof over its adjoining
## wall and streams fallback ground beyond the original map. A suite that builds a real `City` and
## combines two modules for a guarantee that spans them: the builder's map is one the city can draw,
## which neither module's own suite can see (the builder has no city to hand it to, and the city's
## suites are handed maps the generator made).
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const FrontReads := preload("res://tests/front_reads.gd")
const UI := preload("res://tests/ui_screens.gd")

## The diagnostics a builder's answer carries.
func _errors(result: Dictionary) -> Array[String]:
	return result.errors

func _recipe() -> Dictionary:
	return {"version": 1, "name": "construction check", "seed": 7,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501},
			"anchors": {"door": "power_station_door"}, "setup": {}, "playback": {}}

func run(t: TestRunner) -> void:
	await _test_the_bounded_context(t)
	_test_the_examples(t)
	_test_the_props_stand_a_relocated_tree(t)
	_test_a_street_tree_with_an_emptied_pit_is_hidden(t)

## **The city's props stand a tree the recipe relocates** across the road, where the builder's
## planting has its pit now: the street tree the city draws stands at the destination pit's tile
## and not at the source's, and is the real street-tree prop.
func _test_the_props_stand_a_relocated_tree(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(recipe)
	if not _errors(built).is_empty():
		t.check(false, "opposite-curb tree recipe constructs: %s" % [built.errors])
		return
	var source := Vector2i(50, 74)
	var destination := Vector2i(50, 71)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, built.map)
	var trees := {}
	for node in city.props():
		var prop := node as Prop
		if prop != null and prop.kind() == Prop.Kind.STREET_TREE:
			trees[city.map.world_to_tile(prop.position)] = prop
	t.check(not trees.has(source) and trees.has(destination),
			"real tree props use the relocated planning source")
	var tree: Prop = trees.get(destination)
	t.check(tree != null and tree.position == city.map.tile_to_world(destination),
			"relocation retains a real existing street-tree component")
	city.free()

## **The city hides the street tree whose pit the day emptied** when it refreshes its trees, and
## shows every tree again once no pit is emptied: a fallen tree stands where the street tree stood.
func _test_a_street_tree_with_an_emptied_pit_is_hidden(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(recipe)
	if not _errors(built).is_empty():
		t.check(false, "street-tree recipe constructs: %s" % [built.errors])
		return
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, built.map)
	var trees := {}
	for node in city.props():
		var prop := node as Prop
		if prop != null and prop.kind() == Prop.Kind.STREET_TREE:
			trees[city.map.world_to_tile(prop.position)] = prop
	t.check(trees.size() >= 2, "the city draws several street trees (%d)" % trees.size())
	var emptied: Vector2i = trees.keys()[0]
	var pits: Array[Vector2i] = [emptied]
	city.map.set_seal_tree_pits(pits)
	city.refresh_street_trees()
	var others_shown := true
	for tile: Vector2i in trees:
		var prop: Prop = trees[tile]
		if tile != emptied and not prop.visible:
			others_shown = false
	t.check(not (trees[emptied] as Prop).visible,
			"the street tree whose pit is emptied is hidden after the refresh")
	t.check(others_shown, "every other street tree stays shown")
	var none: Array[Vector2i] = []
	city.map.set_seal_tree_pits(none)
	city.refresh_street_trees()
	var all_shown := true
	for tile: Vector2i in trees:
		if not (trees[tile] as Prop).visible:
			all_shown = false
	t.check(all_shown, "every street tree is shown again once no pit is emptied")
	city.free()

func _test_the_bounded_context(t: TestRunner) -> void:
	var input := _recipe()
	input.extent = {"scope": "bounded", "bounds": [112, 0, 34, 56]}
	var bounded := RecipeCityBuilder.build(input)
	t.check(_errors(bounded).is_empty(), "bounded context retains whole footprints: %s" % [bounded.errors])
	if not _errors(bounded).is_empty():
		return
	var local: CityMap = bounded.map
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, local)
	t.check(city.scenery_ground_source(Vector2i(-100, -100)) == GroundTiles.ALLEY,
			"exterior uses the plain documented ground texture")
	var station: Building = null
	for building in city.buildings():
		if building.is_power_station():
			station = building
	t.check(station != null, "bounded rendering includes the real power station")
	if station:
		FrontReads.watch(station, city.atlas)
		await UI.frames(t, 2)
		var extended := 0
		for rows: int in FrontReads.look(station).roof_extension():
			extended += rows
		t.check(extended > 0, "actual City construction extends the hall roof over its adjoining wall")
	city.free()

func _test_the_examples(t: TestRunner) -> void:
	for side: String in ["hall", "yard"]:
		var loaded := SceneRecipe.load_file("res://scene-recipes/power-station-%s.json" % side)
		var built := RecipeCityBuilder.build(loaded.data)
		if not _errors(built).is_empty():
			t.check(false, "%s example builds: %s" % [side, built.errors])
			continue
		var map: CityMap = built.map
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		city.schedule_scenery(SceneryGround.Mode.ONE, true)
		t.add_child(city)
		RunCity.build(city, map)
		var wall_tile := Vector2i(118 if side == "hall" else 132, 14)
		var found := false
		for building in city.buildings():
			if building.lot_rect().position != wall_tile:
				continue
			found = true
			t.check(not building.covered_ground_cols().is_empty(), "%s renders adjoining facade columns" % side)
			for covered: bool in building.covered_ground_cols():
				t.check(covered == (side == "hall"), "%s adjoining column has a roof or keeps its facade" % side)
		t.check(found, "%s uses the generator's real adjoining dead-end building" % side)
		var exterior := Rect2(-20000, -20000, 640, 480)
		city.scenery.update(exterior)
		t.check(not city.scenery_ground.chunks().is_empty(), "fallback ground streams beyond the original map")
		t.check(city.scenery_ground.pending().is_empty(), "scripted scenery drains preparation independent of wall-clock budget")
		city.free()
