extends RefCounted
## A task scene's stretch (`docs/SCENE_RECIPES.md`, "The task scenes"): the recipe's tiles are the
## only ground, the void beyond is no ground and a wall, the construction witness has to agree with
## the recipe or the scene is refused, the crowd enters and leaves at the stretch's ends, and the
## director draws her route's events from the bag the recipe rigs. The scenes' own walks are
## `tools/scene-recipes.sh`'s.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SCENE := "res://scene-recipes/task-07-package.json"

func run(t) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var built := RecipeCityBuilder.build(data)
	t.check(built.errors.is_empty(), "day 7's stretch builds on its witness: %s" % [built.errors])
	if not built.errors.is_empty():
		return
	var map: CityMap = built.map
	var witness: CityMap = RecipeCityBuilder.build(SceneRecipeDraft.base_of(data)).map
	_test_the_stretch_is_the_only_ground(t, map, witness)
	_test_a_witness_that_disagrees_is_refused(t, data)
	_test_the_schema(t, data)
	_test_the_crowd_enters_at_the_ends(t, map)
	_test_the_draft_takes_whole_streets(t, witness)
	_test_the_route_bag(t, map, data)
	_test_the_city_draws_the_stretch_alone(t, map)

func _test_the_stretch_is_the_only_ground(t, map: CityMap, witness: CityMap) -> void:
	t.check(map.has_stretch() and map.stretch_active, "the scene's map shows its stretch")
	var inside := 0
	var agrees := true
	var cut_off := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.in_stretch(tile):
				inside += 1
				agrees = agrees and map.tile_at(tile) == witness.tile_at(tile)
			elif map.tile_at(tile) != GameEnums.TileType.BUILDING or map.is_walkable(tile) \
					or map.is_street(tile):
				agrees = false
			if map.is_cut_off(tile):
				cut_off += 1
				agrees = agrees and witness.is_walkable(tile)
	t.check(inside > 0 and agrees,
			"its %d tiles read as the witness has them and every other tile as void, no ground" % inside)
	t.check(cut_off > 0, "and some of the void is street the stretch cut off (%d tiles)" % cut_off)
	var edges := map.witness_only()
	var outside := Vector2i(0, 0)
	t.check(not map.in_stretch(outside) and map.tile_at(outside) == witness.tile_at(outside),
			"a whole-city rule reads the witness while the edges are off")
	map.restore_edges(edges)
	t.check(map.stretch_active and map.tile_at(outside) == GameEnums.TileType.BUILDING,
			"and the void is back once it is done")

func _test_a_witness_that_disagrees_is_refused(t, data: Dictionary) -> void:
	var drifted := data.duplicate(true)
	var runs: Dictionary = drifted.stretch.tiles
	var road: Array = runs.road
	var moved: Array = road.pop_back()
	(runs.sidewalk as Array).append(moved)
	var refused := RecipeCityBuilder.build(drifted)
	t.check("\n".join(refused.errors).contains("stretch.witness"),
			"a tile the witness has as another type is refused, not drawn over: %s" % [refused.errors])
	var no_lot := data.duplicate(true)
	(no_lot.stretch.buildings as Array).append({"lot": [0, 0, 3, 3], "district": "residential",
			"variant": 1, "height": 1, "condition": "lived_in"})
	t.check("\n".join(RecipeCityBuilder.build(no_lot).errors).contains("the witness builds no lot"),
			"a building the witness does not build is refused")
	var tree := data.duplicate(true)
	(tree.stretch.trees as Array).append([(tree.stretch.tiles.road as Array)[0][1],
			(tree.stretch.tiles.road as Array)[0][0]])
	t.check("\n".join(RecipeCityBuilder.build(tree).errors).contains("stretch.trees"),
			"a street tree the witness does not plant is refused")
	var twice := data.duplicate(true)
	(twice.stretch.tiles.road as Array).append((twice.stretch.tiles.road as Array)[0])
	t.check("\n".join(RecipeCityBuilder.build(twice).errors).contains("listed twice"),
			"a tile listed twice is refused")

func _test_the_schema(t, data: Dictionary) -> void:
	var bare := data.duplicate(true)
	bare.erase("stretch")
	t.check("\n".join(SceneRecipe.validate(bare)).contains("come together"),
			"a stretch scope needs its stretch")
	var walled := data.duplicate(true)
	walled.stretch.tiles["building"] = [[0, 0, 0]]
	t.check("\n".join(SceneRecipe.validate(walled)).contains("not a walkable tile type"),
			"a stretch lists ground, never a building tile")
	var prop := data.duplicate(true)
	(prop.stretch.props as Array).append({"kind": "street_tree", "at": [0, 0]})
	t.check("\n".join(SceneRecipe.validate(prop)).contains("stretch.props"),
			"a street tree is listed under trees, where the witness is asked about it")
	var crowd := data.duplicate(true)
	crowd.setup["background"] = {"crowd": true}
	t.check("\n".join(SceneRecipeRuntime.validate_runtime(crowd)).contains("authored actors"),
			"a stretch's crowd is its listed starting population, never a rolled one")

func _test_the_crowd_enters_at_the_ends(t, map: CityMap) -> void:
	var ends := CrowdField.stretch_ends_of(map)
	t.check(not ends.is_empty(), "the stretch has ends where its streets run into the void")
	var sound := true
	for end in ends:
		var step := Vector2i.DOWN if end.vertical else Vector2i.RIGHT
		var inward := step * int(end.direction)
		var lane_end := false
		for offset in Tuning.STREET_WIDTH:
			var cross := int(end.corridor) * CityMap.period() + offset
			var at := Vector2i(cross, int(end.along)) if end.vertical else Vector2i(int(end.along), cross)
			var run := 0
			while map.in_stretch(at + inward * run):
				run += 1
			lane_end = lane_end or (map.is_cut_off(at - inward) and run > Tuning.STREET_WIDTH)
		sound = sound and lane_end
	t.check(sound, "each end is a lane end with void beyond it and more than a junction behind it")
	var crowd_map := map
	var field := CrowdField.new(crowd_map, Vector2.ZERO)
	field.use_stretch()
	var looking := Vector2(123, 456)
	field.centre = looking
	t.check(field.has_stretch() and field.looking_at() == looking and field.centre != looking,
			"the field stays over the whole stretch while the camera moves")

func _test_the_draft_takes_whole_streets(t, witness: CityMap) -> void:
	var segment := StreetNetwork.by_key(Vector3i(5, 5, 1))
	var ground := {}
	SceneRecipeDraft._add_the_ground_of(witness, segment.tile_rect().get_center(), ground)
	var whole := true
	for tile in witness.rect_tiles(segment.tile_rect()):
		whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	var box := Rect2i(segment.a * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	for tile in witness.rect_tiles(box):
		whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	t.check(whole, "a step on a street takes the whole street and the junction at each end")
	var mouth := Vector2i(92, 69)
	var pinned := {}
	SceneRecipeDraft._add_the_ground_of(witness, mouth, pinned, false)
	t.check(not pinned.has(mouth + Vector2i.UP * 4),
			"a pinned mark brings its own corner, not the alley behind it")

func _test_the_route_bag(t, map: CityMap, data: Dictionary) -> void:
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var none: Array[EventScheduler.Planned] = []
	director.start_day(7, none, rng)
	director.start_recipe_route(["cyclist", "cyclist"], ["cat_dash"], 3, 2.0, 0)
	t.check(director.owed() == 3, "the route is owed what the recipe says")
	t.check(director.route_bag().peek() == "cat_dash", "and the pre-bag is drawn first")
	var place := data.duplicate(true)
	place.setup.route_bag = {"marbles": ["burning_building"]}
	t.check("\n".join(SceneRecipeRuntime.validate_runtime(place)).contains("not a row the director sites"),
			"a marble names a row the director sites that day")
	var asked := data.duplicate(true)
	(asked.playback.observations as Array).append(
			{"tick": 1, "subject": "mark", "condition": "crowd", "walkers": 1})
	t.check("\n".join(SceneRecipeRuntime.validate_runtime(asked)).contains("round the player"),
			"a crowd observation asks about the picture round her")

func _test_the_city_draws_the_stretch_alone(t, map: CityMap) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	t.check(city.buildings().size() == map.stretch_buildings.size(),
			"only the recipe's buildings stand (%d)" % city.buildings().size())
	var edge := city.get_node_or_null("VoidEdge")
	t.check(edge != null and edge.get_child_count() > 0, "and the void round the stretch is walled off")
	var cracked := 0
	for tile: Vector2i in map.stretch_cracks:
		var plain := GroundTiles.source_for(map, tile, 7)
		cracked += int(plain != GroundTiles.SIDEWALK and plain != GroundTiles.ROAD
				and plain != GroundTiles.ALLEY)
	t.check(cracked > 0, "the recipe's cracks are what the ground draws")
	var outside := Vector2i.ZERO
	t.check(city.scenery_ground_source(outside) == -1, "and no ground is drawn in the void")
	city.free()
