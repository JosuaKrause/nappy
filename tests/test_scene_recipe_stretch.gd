extends RefCounted
## A task scene's stretch (`docs/SCENE_RECIPES.md`, "The task scenes"): the recipe's tiles are the
## only ground, the void beyond is no ground and a wall, authored edits survive save/load and daily
## repainting independently of generation, the crowd enters and leaves at the stretch's ends, and the
## director draws her route's events from the bag the recipe rigs. The scenes' own walks are
## `tools/scene-recipes.sh`'s.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SCENE := "res://scene-recipes/task-07-package.json"
const PARTIAL_COURTYARD_SCENE := "res://scene-recipes/task-14-last-night.json"

func run(t) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var built := RecipeCityBuilder.build(data)
	t.check(built.errors.is_empty(), "day 7's stretch loads explicit context: %s" % [built.errors])
	if not built.errors.is_empty():
		return
	var map: CityMap = built.map
	var witness: CityMap = RecipeCityBuilder.build(SceneRecipeDraft.base_of(data)).map
	_test_the_stretch_is_the_only_ground(t, map, witness)
	_test_the_arrow_stays_on_the_stretch(t, map)
	_test_saved_layout_is_independent(t, data)
	_test_authored_building_values_drive_live_joins(t, data)
	_test_authored_partial_courtyard_controls_live_tint(t)
	_test_the_schema(t, data)
	_test_the_crowd_enters_at_the_ends(t, map)
	_test_the_draft_takes_whole_streets(t, witness)
	_test_the_route_bag(t, map, data)
	_test_the_city_draws_the_stretch_alone(t, map)
	_test_appeared_requires_sight(t)

func _test_appeared_requires_sight(t) -> void:
	var ordinary := _visibility_rig(t, 1.0)
	var runtime: SceneRecipeRuntime = ordinary.runtime
	var camera: Camera2D = ordinary.camera
	var recipe := {"playback": {"duration": 1, "observations": [
			{"tick": 20, "subject": "event", "condition": "appeared"}]}}
	runtime.configure({"data": recipe, "manifest": {}, "anchors": {}}, true)
	var event := Node2D.new()
	runtime.add_child(event)
	runtime.named["event"] = event
	event.position = Vector2(10000, 10000)
	runtime._observe()
	t.check(not runtime._appeared.has("event"),
			"an existing event that never enters the camera does not satisfy appeared")
	event.position = Vector2.ZERO
	runtime._observe()
	t.check(runtime._appeared.has("event") and runtime._she_can_see(event),
			"at the default camera zoom, the same event counts once it enters view")
	(ordinary.viewport as SubViewport).free()
	# At zoom 4, this 32px body sits wholly beyond the real 160px half-width although it remains
	# inside `Tuning.VIEW_HALF_EXTENT.x` (320px), the stale constant this regression replaces.
	var close := _visibility_rig(t, 4.0)
	runtime = close.runtime
	camera = close.camera
	event = Node2D.new()
	runtime.add_child(event)
	event.position = camera.get_screen_center_position() + Vector2(250.0, 0.0)
	var half_view := runtime.get_viewport().get_visible_rect().size / camera.zoom / 2.0
	t.check(event.position.x - 16.0 > camera.get_screen_center_position().x + half_view.x
			and not runtime._she_can_see(event),
			("at zoom 4, an actor wholly outside the actual %.0fpx camera half-width does not count "
			+ "(world view %s)") % [half_view.x, runtime._camera_world_rect()])
	(close.viewport as SubViewport).free()
	var wide := _visibility_rig(t, 0.5)
	runtime = wide.runtime
	camera = wide.camera
	event = Node2D.new()
	runtime.add_child(event)
	event.position = camera.get_screen_center_position() + Vector2(250.0, 0.0)
	half_view = runtime.get_viewport().get_visible_rect().size / camera.zoom / 2.0
	t.check(event.position.x + 16.0 < camera.get_screen_center_position().x + half_view.x
			and runtime._she_can_see(event),
			"zoomed out, that same actor counts when the actual camera includes its body")
	(wide.viewport as SubViewport).free()

## A runtime and current camera in their own 1280x720 viewport, with `zoom` fixed before the camera
## enters the tree. Camera2D applies a changed zoom on its next process step; separate synchronous
## rigs let the headless unit test inspect each real canvas transform without advancing the tree.
func _visibility_rig(t, zoom: float) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	t.add_child(viewport)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.zoom = Vector2.ONE * zoom
	player.add_child(camera)
	player._camera = camera
	viewport.add_child(player)
	player.set_physics_process(false)
	camera.make_current()
	camera.force_update_scroll()
	var runtime := SceneRecipeRuntime.new()
	viewport.add_child(runtime)
	runtime.set_physics_process(false)
	runtime._player = player
	return {"viewport": viewport, "player": player, "camera": camera, "runtime": runtime}

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

func _test_the_arrow_stays_on_the_stretch(t, _map: CityMap) -> void:
	# A U-shaped authored street: from the left tip, target A is five tiles along the visible
	# ground. Target B is twelve tiles along it, but only four through the hidden context between
	# the two tips. A raw-context sweep therefore picks B; the scene's real walk must pick A.
	var map := CityMap.new(Vector2i(5, 5))
	map.tiles.fill(GameEnums.TileType.SIDEWALK)
	map.stretch.resize(map.tiles.size())
	map.stretch.fill(0)
	for y in map.size.y:
		for x in map.size.x:
			if x == 0 or x == map.size.x - 1 or y == map.size.y - 1:
				map.stretch[y * map.size.x + x] = 1
	map.stretch_active = true
	var targets: Array[Dictionary] = [
		{"key":"near_on_stretch", "at":map.tile_to_world(Vector2i(1, 4)),
				"reach":0.0, "beat":PackedVector2Array()},
		{"key":"near_through_void", "at":map.tile_to_world(Vector2i(4, 0)),
				"reach":0.0, "beat":PackedVector2Array()}
	]
	var raw_ground := PackedInt32Array()
	raw_ground.resize(map.tiles.size())
	raw_ground.fill(ArrowField.UNREACHED)
	var raw := ArrowField.start(map, targets, Vector2i.ZERO)
	while not raw.done:
		raw.advance(map, raw_ground, map.tiles.size())
	var director := ResistanceDirector.new()
	director._map = map
	var ground := director._ground_for_the_arrow()
	var authored := ArrowField.start(map, targets, Vector2i.ZERO)
	while not authored.done:
		authored.advance(map, ground, map.tiles.size())
	var start := Vector2i(0, 0)
	t.check(raw.nearest_at(start) == "near_through_void",
			"the counterexample's raw context chooses the target across its hidden shortcut")
	t.check(authored.nearest_at(start) == "near_on_stretch",
			"the task arrow chooses the target actually nearer along the authored U-shaped street")
	director.free()

func _test_saved_layout_is_independent(t, data: Dictionary) -> void:
	var original := RecipeCityBuilder.build(data)
	var changed_seed := data.duplicate(true)
	changed_seed.city.context_seed = 1
	changed_seed.city.layouts = []
	var independent := RecipeCityBuilder.build(changed_seed)
	t.check(independent.errors.is_empty() and independent.map.tiles == original.map.tiles,
			"changing drafting inputs cannot regenerate or reject a saved layout")
	var malformed := data.duplicate(true)
	malformed.context.tiles[0] = [["sidewalk", -1]]
	t.check(not RecipeCityBuilder.build(malformed).errors.is_empty(),
			"a malformed context fails before restoring its tile array")
	var drifted := data.duplicate(true)
	var runs: Dictionary = drifted.stretch.tiles
	var road: Array = runs.road
	var moved: Array = road.pop_back()
	(runs.sidewalk as Array).append(moved)
	# Round-trip through the same JSON representation an author saves, then build a real City.
	var parser := JSON.new()
	t.check(parser.parse(SceneRecipeDraft.to_json(drifted)) == OK, "manual edit serializes")
	var edited := RecipeCityBuilder.build(parser.data)
	t.check(edited.errors.is_empty(), "manual tile edit loads: %s" % [edited.errors])
	if edited.errors.is_empty():
		var map: CityMap = edited.map
		var tile := Vector2i(int(moved[1]), int(moved[0]))
		var state := CityState.new()
		state.begin_day(map.block_plans, 7)
		map.repaint(state)
		t.check(map.tile_at(tile) == GameEnums.TileType.SIDEWALK,
				"authored ground survives dawn repaint")
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		city.start_finale(state, 7)
		t.check(map.tile_at(tile) == GameEnums.TileType.SIDEWALK,
				"the real finale/day preparation also keeps the manual ground")
		city.free()
	var building := data.duplicate(true)
	var first: Dictionary = building.stretch.buildings[0]
	first.lot[1] = int(first.lot[1]) + 1
	first.lot[3] = int(first.lot[3]) - 1
	first.height = int(first.height) + 1
	var rebuilt := RecipeCityBuilder.build(building)
	t.check(rebuilt.errors.is_empty() and rebuilt.map.building_rects.has(SceneRecipe.rect(first.lot)),
			"a resized lot becomes the live building footprint without matching a generator: %s" % [rebuilt.errors])
	var tree := data.duplicate(true)
	var run: Array = tree.stretch.tiles.sidewalk[0]
	var planted := Vector2i(int(run[1]), int(run[0]))
	while not StreetNetwork.segment_containing(planted) and planted.x < int(run[2]):
		planted.x += 1
	tree.stretch.trees = [[planted.x, planted.y]]
	var treed := RecipeCityBuilder.build(tree)
	t.check(treed.errors.is_empty(), "manually planted tree loads: %s" % [treed.errors])
	if treed.errors.is_empty():
		var shown := StreetTrees.planted(treed.map).filter(func(item: StreetTrees.Planted) -> bool:
			return treed.map.in_stretch(item.tile))
		t.check(shown.size() == 1 and shown[0].tile == planted,
				"the authored tree list supplies the same placement used by drawing and clearance")
	var twice := data.duplicate(true)
	(twice.stretch.tiles.road as Array).append((twice.stretch.tiles.road as Array)[0])
	t.check("\n".join(RecipeCityBuilder.build(twice).errors).contains("listed twice"),
			"a tile listed twice is refused")

## Authored values are construction inputs, not a visual override applied after construction. The
## day-7 rear lot touches the two-column front lot: making its wall four rows high makes the live
## front roof extend four rows to meet it.
func _test_authored_building_values_drive_live_joins(t, day_seven: Dictionary) -> void:
	var edited := day_seven.duplicate(true)
	var back_lot := Rect2i(90, 56, 2, 6)
	var front_lot := Rect2i(90, 62, 2, 8)
	for spec: Dictionary in edited.stretch.buildings:
		if SceneRecipe.rect(spec.lot) == back_lot:
			spec.height = 4
	var built := RecipeCityBuilder.build(edited)
	t.check(built.errors.is_empty(), "the adjacent-height edit builds: %s" % [built.errors])
	if built.errors.is_empty():
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(built.map)
		var back: Building = null
		var front: Building = null
		for building: Building in city.buildings():
			if building.lot == back_lot:
				back = building
			elif building.lot == front_lot:
				front = building
		t.check(back != null and front != null,
				"both pieces of the edited day-7 join stand in the live City")
		if back != null and front != null:
			var expected_extension: Array[int] = [4, 4]
			t.check(back.wall_tiles() == 4 and front.roof_extension_rows == expected_extension,
					"the front roof reaches the edited four-row rear wall: %s"
					% [front.roof_extension_rows])
		city.free()

## A stretch keeps the complete courtyard as hidden context but draws only its authored members.
## The first visible task-14 member therefore supplies their shared tint; the hidden context's
## earlier member cannot override it, and the second visible member retains its own authored roll.
func _test_authored_partial_courtyard_controls_live_tint(t) -> void:
	var edited: Dictionary = SceneRecipe.load_file(PARTIAL_COURTYARD_SCENE).data.duplicate(true)
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
	t.check(built.errors.is_empty(), "the partial-courtyard edit builds: %s" % [built.errors])
	if built.errors.is_empty():
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(built.map)
		var tint_source: Building = null
		var visible_sibling: Building = null
		for building: Building in city.buildings():
			if building.lot == tint_source_lot:
				tint_source = building
			elif building.lot == visible_sibling_lot:
				visible_sibling = building
		t.check(tint_source != null and visible_sibling != null,
				"both authored pieces of task 14's partial courtyard stand in the live City")
		if tint_source != null and visible_sibling != null:
			t.check(tint_source.variant == authored_variant
					and visible_sibling.variant == sibling_variant,
					"each visible piece keeps its own authored variant")
			t.check(tint_source.tint_variant == authored_variant
					and visible_sibling.tint_variant == authored_variant,
					("the first visible piece controls the partial courtyard's live tint: %s, %s")
					% [tint_source.tint_variant, visible_sibling.tint_variant])
		city.free()

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
			"a street tree is listed under trees, the shared placement source")
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
