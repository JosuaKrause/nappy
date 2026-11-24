extends RefCounted
## What `RecipeCityBuilder` builds from a recipe: the tree a recipe relocates across the road is
## the planting's own (a pit moves, a road or an unrelated sidewalk is refused), the title scene's
## capture stays in its park, and a task scene's stretch is built as its recipe lists it (day 7's:
## its tiles the only ground, the saved layout read as saved, the author's edits what shows). The
## builder builds a map and nothing else, so no city, crowd or event is made here: what the city
## draws of the map is `tests/test_recipe_city_drawing.gd`'s and what the crowd does on it is
## `tests/test_crowd_coverage.gd`'s.

## The diagnostics a builder's answer carries.
func _errors(result: Dictionary) -> Array[String]:
	return result.errors

func run(t: TestRunner) -> void:
	_test_a_tree_moves_across_the_road_and_nothing_else(t)
	_test_the_titles_capture_stays_in_its_park(t)
	_test_a_stretch_is_built_as_its_recipe_lists_it(t)

func _test_a_tree_moves_across_the_road_and_nothing_else(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(recipe)
	t.check(_errors(built).is_empty(), "opposite-curb tree recipe constructs: %s" % [built.errors])
	if not _errors(built).is_empty():
		return
	var source := Vector2i(50, 74)
	var destination := Vector2i(50, 71)
	var pits := {}
	for tree in StreetTrees.planted(built.map):
		pits[tree.tile] = tree
	t.check(not pits.has(source) and pits.has(destination),
			"planning moves the original tree pit across the road")
	for target: Array in [[50, 73], [51, 71]]:
		var invalid: Dictionary = recipe.duplicate(true)
		invalid.city.tree_moves[0].to = target
		t.check(not _errors(RecipeCityBuilder.build(invalid)).is_empty(),
				"tree relocation refuses road or unrelated sidewalk")

func _test_the_titles_capture_stays_in_its_park(t: TestRunner) -> void:
	var title: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-title.json").data
	var park := RecipeCityBuilder.build(title)
	var park_map: CityMap = park.map
	var anchors: Dictionary = park.anchors
	var at: Vector2 = anchors.start
	t.check(park_map.tile_at(park_map.world_to_tile(at)) == GameEnums.TileType.PARK,
			"title begins inside the existing park")
	var capture := at + Vector2.DOWN * Tuning.WALK_SPEED * float(title.playback.capture_at)
	t.check(park_map.tile_at(park_map.world_to_tile(capture)) == GameEnums.TileType.PARK,
			"title's moving capture remains inside the park")

## **A task scene's stretch is built as its recipe lists it** (day 7's): the stretch is the only
## ground, the saved layout is independent of the drafting inputs, and the author's own edits are
## what the map shows. No city is made: what the city draws of the map is
## `tests/test_recipe_city_drawing.gd`'s.
func _test_a_stretch_is_built_as_its_recipe_lists_it(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file("res://scene-recipes/task-07-package.json").data
	var built := RecipeCityBuilder.build(data)
	t.check(_errors(built).is_empty(), "day 7's stretch loads explicit context: %s" % [built.errors])
	if not _errors(built).is_empty():
		return
	var map: CityMap = built.map
	_test_the_stretch_is_the_only_ground(t, map, data)
	_test_the_saved_layout_ignores_the_drafting_inputs(t, data)
	_test_a_hand_edited_tile_survives_the_dawns_repaint(t, data)
	_test_a_resized_lot_and_a_planted_tree_are_the_authors(t, data)
	t.check("\n".join(_errors(RecipeCityBuilder.build(_with_a_tile_listed_twice(data)))).contains(
			"listed twice"), "a tile listed twice is refused")

## The live map against the recipe's own lists, never against a generated city *(mossy-marmot,
## inbox #618, the player's choice: "Finish fully handcrafted layouts now")*: each stretch tile
## is the type `stretch.tiles` lists for it, every other tile is void, and the void the stretch
## cut off is ground in its saved `context`. Asked of the saved scene and of a copy with one road
## run hand-edited to sidewalk, which the saved context still has as road: an edit an author makes
## is what the scene shows, and holds here as it holds in play.
func _test_the_stretch_is_the_only_ground(t: TestRunner, map: CityMap, data: Dictionary) -> void:
	t.check(map.has_stretch() and map.is_void(Vector2i.ZERO), "the scene's map shows its stretch")
	var context := RecipeCityContext.restore(data.context)
	_check_the_ground(t, map, data, context, "the saved scene")
	var edited := data.duplicate(true)
	var road: Array = edited.stretch.tiles.road
	var moved: Array = road.pop_back()
	(edited.stretch.tiles.sidewalk as Array).append(moved)
	var tile := Vector2i(int(moved[1]), int(moved[0]))
	var rebuilt := RecipeCityBuilder.build(edited)
	t.check(_errors(rebuilt).is_empty() and context.tile_at(tile) == GameEnums.TileType.ROAD,
			"the hand-edited copy builds, its edit at %s differing from the saved context: %s"
			% [tile, rebuilt.errors])
	if _errors(rebuilt).is_empty():
		_check_the_ground(t, rebuilt.map, edited, context, "the hand-edited copy")
	var edges := map.witness_only()
	var outside := Vector2i(0, 0)
	t.check(not map.in_stretch(outside) and map.tile_at(outside) == context.tile_at(outside),
			"a whole-city rule reads the saved context while the edges are off")
	map.restore_edges(edges)
	t.check(map.is_void(outside) and map.tile_at(outside) == GameEnums.TileType.BUILDING,
			"and the void is back once it is done")

func _check_the_ground(t: TestRunner, map: CityMap, data: Dictionary, context: CityMap, label: String) -> void:
	var listed := {}
	for type_name: String in data.stretch.tiles:
		for run: Array in data.stretch.tiles[type_name]:
			for x in range(int(run[1]), int(run[2]) + 1):
				listed[Vector2i(x, int(run[0]))] = GameEnums.TileType[type_name.to_upper()]
	var as_listed := true
	var void_elsewhere := true
	var cut_off := 0
	var cut_off_was_ground := true
	for y in map.size_in_tiles().y:
		for x in map.size_in_tiles().x:
			var tile := Vector2i(x, y)
			if map.in_stretch(tile) != listed.has(tile):
				as_listed = false
			elif listed.has(tile):
				as_listed = as_listed and map.tile_at(tile) == listed[tile]
			elif map.tile_at(tile) != GameEnums.TileType.BUILDING or map.is_walkable(tile) \
					or map.is_street(tile):
				void_elsewhere = false
			if map.is_cut_off(tile):
				cut_off += 1
				# A precinct's post stands on ground whose type is walkable and that nobody can stand on.
				cut_off_was_ground = cut_off_was_ground and context.walkable_lut()[context.tile_at(tile)] == 1
	t.check(not listed.is_empty() and as_listed,
			"%s: its %d tiles are the stretch and read as `stretch.tiles` lists them"
			% [label, listed.size()])
	t.check(void_elsewhere, "%s: every other tile is void, no ground" % label)
	t.check(cut_off > 0 and cut_off_was_ground,
			"%s: some of the void is ground the stretch cut off from its saved context (%d tiles)"
			% [label, cut_off])

## **Changing what a draft is made from changes nothing of a saved layout**: another context seed
## and no layouts build the same tiles as the scene's own (a saved layout is read, never
## regenerated or rejected), and a context whose tile array is malformed fails before it is
## restored.
func _test_the_saved_layout_ignores_the_drafting_inputs(t: TestRunner, data: Dictionary) -> void:
	var original := RecipeCityBuilder.build(data)
	var changed_seed := data.duplicate(true)
	changed_seed.city.context_seed = 1
	changed_seed.city.layouts = []
	var independent := RecipeCityBuilder.build(changed_seed)
	var independent_map: CityMap = independent.map
	var original_map: CityMap = original.map
	t.check(_errors(independent).is_empty()
			and independent_map.tiles_snapshot() == original_map.tiles_snapshot(),
			"changing drafting inputs cannot regenerate or reject a saved layout")
	var malformed := data.duplicate(true)
	malformed.context.tiles[0] = [["sidewalk", -1]]
	t.check(not _errors(RecipeCityBuilder.build(malformed)).is_empty(),
			"a malformed context fails before restoring its tile array")

## **A hand edit of the stretch's ground survives the dawn's repaint**: one road run and one alley
## run listed as sidewalk, saved and read back as an author's file is, builds, and the map's repaint
## for the day (`CityMap.repaint()`) leaves both edited tiles the sidewalk the author wrote. The
## alley is block ground, which a repaint without the saved dawn ground would paint back; a street
## tile is not, so the road alone would not show it. The city's own preparation of the day is
## `tests/test_recipe_city_drawing.gd`'s.
func _test_a_hand_edited_tile_survives_the_dawns_repaint(t: TestRunner, data: Dictionary) -> void:
	var drifted := data.duplicate(true)
	var runs: Dictionary = drifted.stretch.tiles
	var road: Array = runs.road
	var moved: Array = road.pop_back()
	(runs.sidewalk as Array).append(moved)
	var alley: Array = runs.alley
	var cleared: Array = alley.pop_back()
	(runs.sidewalk as Array).append(cleared)
	# Round-trip through the JSON an author saves.
	var parser := JSON.new()
	t.check(parser.parse(JSON.stringify(drifted)) == OK, "manual edit serializes")
	var edited := RecipeCityBuilder.build(parser.data)
	t.check(_errors(edited).is_empty(), "manual tile edit loads: %s" % [edited.errors])
	if _errors(edited).is_empty():
		var map: CityMap = edited.map
		var tile := Vector2i(int(moved[1]), int(moved[0]))
		var alley_tile := Vector2i(int(cleared[1]), int(cleared[0]))
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), 7)
		map.repaint(state)
		t.check(map.tile_at(tile) == GameEnums.TileType.SIDEWALK
				and map.tile_at(alley_tile) == GameEnums.TileType.SIDEWALK,
				"authored ground survives dawn repaint")

## **A lot the author resized and a tree the author planted are what the map holds**: a lot one
## tile narrower on a taller building is the live footprint without matching any generator's, and a
## tree listed under `trees` is the planting's own, the one placement the drawing and the clearance
## read.
func _test_a_resized_lot_and_a_planted_tree_are_the_authors(t: TestRunner, data: Dictionary) -> void:
	var building := data.duplicate(true)
	var first: Dictionary = building.stretch.buildings[0]
	first.lot[1] = int(first.lot[1]) + 1
	first.lot[3] = int(first.lot[3]) - 1
	first.height = int(first.height) + 1
	var rebuilt := RecipeCityBuilder.build(building)
	var rebuilt_map: CityMap = rebuilt.map
	t.check(_errors(rebuilt).is_empty() and rebuilt_map.building_lots().has(SceneRecipe.rect(first.lot)),
			"a resized lot becomes the live building footprint without matching a generator: %s"
			% [rebuilt.errors])
	var tree := data.duplicate(true)
	var run: Array = tree.stretch.tiles.sidewalk[0]
	var planted := Vector2i(int(run[1]), int(run[0]))
	var lattice := StreetNetwork.new()
	while not lattice.segment_containing(planted) and planted.x < int(run[2]):
		planted.x += 1
	tree.stretch.trees = [[planted.x, planted.y]]
	var treed := RecipeCityBuilder.build(tree)
	t.check(_errors(treed).is_empty(), "manually planted tree loads: %s" % [treed.errors])
	if _errors(treed).is_empty():
		var treed_map: CityMap = treed.map
		var shown := StreetTrees.planted(treed_map).filter(func(item: StreetTrees.Planted) -> bool:
			return treed_map.in_stretch(item.tile))
		t.check(shown.size() == 1 and shown[0].tile == planted,
				"the authored tree list supplies the same placement used by drawing and clearance")

## `data` with its first road run listed a second time.
func _with_a_tile_listed_twice(data: Dictionary) -> Dictionary:
	var twice := data.duplicate(true)
	(twice.stretch.tiles.road as Array).append((twice.stretch.tiles.road as Array)[0])
	return twice
