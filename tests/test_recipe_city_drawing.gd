extends RefCounted
## **The real `City` draws the maps a recipe builds**: the power station recipes' bounded
## context and their two examples are built by `RecipeCityBuilder`
## (`tests/test_scene_recipe.gd`'s) and handed to a real `City`, which gives the exterior the
## plain ground, extends the hall roof over its adjoining wall and streams fallback ground
## beyond the original map. A suite that builds a real `City` and combines two modules for a
## guarantee that spans them: the builder's map is one the city can draw, which neither module's
## own suite can see (the builder has no city to hand it to, and the city's suites are handed
## maps the generator made). The same holds for a task scene's stretch (day 7's, and day 14's
## partial courtyard): what the city does with a map that has a stretch (keeps the ground an
## author edited through the day's preparation, builds a join from the authored heights, draws
## only the recipe's buildings and walls the void) is a guarantee between the recipe's map and
## the city, which the builder's suite (no city) and the city's (generated maps) cannot see.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const FrontReads := preload("res://tests/front_reads.gd")
const UI := preload("res://tests/ui_screens.gd")
const PARTIAL_COURTYARD_SCENE := "res://scene-recipes/task-14-last-night.json"

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
	await _test_a_stretchs_city(t)

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

## **What the city draws of a task scene's stretch** (day 7's, and day 14's for its partial
## courtyard): the day's preparation keeps what an author edited, an authored building value is
## what a live join is built from, a partial courtyard's tint is its first visible member's, and
## the ground, the buildings and the wall are the recipe's alone.
func _test_a_stretchs_city(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(
			"res://scene-recipes/task-07-package.json").data
	var built := RecipeCityBuilder.build(data)
	t.check(_errors(built).is_empty(),
			"day 7's stretch loads explicit context: %s" % [built.errors])
	if not _errors(built).is_empty():
		return
	var map: CityMap = built.map
	_test_the_days_preparation_keeps_the_manual_ground(t, data)
	await _test_authored_building_values_drive_live_joins(t, data)
	await _test_authored_partial_courtyard_controls_live_tint(t)
	_test_the_city_draws_the_stretch_alone(t, map)

## **The day's and the finale's preparation keep the ground an author edited**: one road run and
## one alley run of day 7's stretch are listed as sidewalk, and the real `City` begins the day
## over that map (it repaints the map for the day's state, as the finale's preparation does) and
## both tiles are still the sidewalk the author wrote. The alley is block ground, which a
## repaint without the saved dawn ground would paint back; a street tile is not.
func _test_the_days_preparation_keeps_the_manual_ground(t: TestRunner,
		data: Dictionary) -> void:
	var drifted := data.duplicate(true)
	var runs: Dictionary = drifted.stretch.tiles
	var road: Array = runs.road
	var moved: Array = road.pop_back()
	(runs.sidewalk as Array).append(moved)
	var alley: Array = runs.alley
	var cleared: Array = alley.pop_back()
	(runs.sidewalk as Array).append(cleared)
	var edited := RecipeCityBuilder.build(drifted)
	t.check(_errors(edited).is_empty(), "manual tile edit loads: %s" % [edited.errors])
	if not _errors(edited).is_empty():
		return
	var map: CityMap = edited.map
	var tile := Vector2i(int(moved[1]), int(moved[0]))
	var alley_tile := Vector2i(int(cleared[1]), int(cleared[0]))
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 7)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, map)
	city.start_day(state, 7, RandomNumberGenerator.new(),
			DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	t.check(map.tile_at(tile) == GameEnums.TileType.SIDEWALK
			and map.tile_at(alley_tile) == GameEnums.TileType.SIDEWALK,
			"the real finale/day preparation keeps the manual ground")
	city.free()

## Authored values are construction inputs, not a visual override applied after construction.
## The day-7 rear lot touches the two-column front lot: making its wall four rows high makes the
## live front roof extend four rows to meet it.
func _test_authored_building_values_drive_live_joins(t: TestRunner,
		day_seven: Dictionary) -> void:
	var edited := day_seven.duplicate(true)
	var back_lot := Rect2i(90, 56, 2, 6)
	var front_lot := Rect2i(90, 62, 2, 8)
	for spec: Dictionary in edited.stretch.buildings:
		if SceneRecipe.rect(spec.lot) == back_lot:
			spec.height = 4
	var built := RecipeCityBuilder.build(edited)
	t.check(_errors(built).is_empty(), "the adjacent-height edit builds: %s" % [built.errors])
	if _errors(built).is_empty():
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, built.map)
		var back: Building = null
		var front: Building = null
		for building: Building in city.buildings():
			if building.lot_rect() == back_lot:
				back = building
			elif building.lot_rect() == front_lot:
				front = building
		t.check(back != null and front != null,
				"both pieces of the edited day-7 join stand in the live City")
		if back != null and front != null:
			FrontReads.watch(front, city.atlas)
			await UI.frames(t, 2)
			var drawn_extension := FrontReads.look(front).roof_extension()
			var expected_extension: Array[int] = [4, 4]
			t.check(back.wall_tiles() == 4 and drawn_extension == expected_extension,
					"the front roof reaches the edited rear wall: %s" % [drawn_extension])
		city.free()

## A stretch keeps the complete courtyard as hidden context but draws only its authored members.
## The first visible task-14 member therefore supplies their shared tint; the hidden context's
## earlier member cannot override it, and the second visible member retains its own authored
## roll.
func _test_authored_partial_courtyard_controls_live_tint(t: TestRunner) -> void:
	var courtyard_data: Dictionary = SceneRecipe.load_file(PARTIAL_COURTYARD_SCENE).data
	var edited := courtyard_data.duplicate(true)
	var tint_source_lot := Rect2i(118, 34, 13, 4)
	var visible_sibling_lot := Rect2i(132, 34, 8, 4)
	var authored_variant := 123456789
	var sibling_variant := -1
	for spec: Dictionary in edited.stretch.buildings:
		var lot := SceneRecipe.rect(spec.lot)
		if lot == tint_source_lot:
			spec.variant = authored_variant
		elif lot == visible_sibling_lot:
			sibling_variant = int(spec.variant)
	var built := RecipeCityBuilder.build(edited)
	t.check(_errors(built).is_empty(), "the partial-courtyard edit builds: %s" % [built.errors])
	if _errors(built).is_empty():
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, built.map)
		var tint_source: Building = null
		var visible_sibling: Building = null
		for building: Building in city.buildings():
			if building.lot_rect() == tint_source_lot:
				tint_source = building
			elif building.lot_rect() == visible_sibling_lot:
				visible_sibling = building
		t.check(tint_source != null and visible_sibling != null,
				"both authored pieces of task 14's partial courtyard stand in the live City")
		if tint_source != null and visible_sibling != null:
			t.check(tint_source.look_variant() == authored_variant
					and visible_sibling.look_variant() == sibling_variant,
					"each visible piece keeps its own authored variant")
			FrontReads.watch(tint_source, city.atlas)
			FrontReads.watch(visible_sibling, city.atlas)
			await UI.frames(t, 2)
			var source_wall := FrontReads.look(tint_source).colour_of(Building.WALL)
			var sibling_wall := FrontReads.look(visible_sibling).colour_of(Building.WALL)
			var authored_wall := Palette.building_wall(authored_variant)
			t.check(source_wall == authored_wall and sibling_wall == authored_wall,
					"the first visible piece controls the courtyard's live tint: %s, %s"
					% [source_wall, sibling_wall])
		city.free()

## **The city draws the stretch alone**: only the recipe's buildings stand, the void round the
## stretch is walled off, the recipe's cracks are what the ground draws, and no ground is drawn
## in the void.
func _test_the_city_draws_the_stretch_alone(t: TestRunner, map: CityMap) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, map)
	t.check(city.buildings().size() == map.stretch_building_lots().size(),
			"only the recipe's buildings stand (%d)" % city.buildings().size())
	var edge := city.get_node_or_null("VoidEdge")
	t.check(edge != null and edge.get_child_count() > 0,
			"and the void round the stretch is walled off")
	var cracked := 0
	for tile: Vector2i in map.rect_tiles(Rect2i(Vector2i.ZERO, map.size_in_tiles())):
		if map.stretch_crack_at(tile) == null:
			continue
		var drawn := city.scenery_ground_source(tile)
		cracked += int(drawn != GroundTiles.SIDEWALK and drawn != GroundTiles.ROAD
				and drawn != GroundTiles.ALLEY)
	t.check(cracked > 0, "the recipe's cracks are what the ground draws")
	t.check(city.scenery_ground_source(Vector2i.ZERO) == -1, "no ground is drawn in the void")
	var beyond := map.size_in_tiles()
	for tile: Vector2i in [Vector2i(-3, -3), Vector2i(beyond.x, 5), Vector2i(5, beyond.y)]:
		t.check(city.scenery_ground_source(tile) == -1,
				"and none beyond the map's edge, at %s" % [tile])
	city.free()
