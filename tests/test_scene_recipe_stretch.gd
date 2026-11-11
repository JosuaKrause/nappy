@warning_ignore_start("unsafe_method_access")
extends RefCounted
## A task scene's stretch (`docs/SCENE_RECIPES.md`, "The task scenes"): the recipe's tiles are the
## only ground, the void beyond is no ground and a wall, authored edits survive save/load and daily
## repainting independently of generation, the crowd enters and leaves at the stretch's ends, and the
## director draws her route's events from the bag the recipe rigs. The scenes' own walks are
## `tools/scene-recipes.sh`'s.
##
## **Builds a real `City` where a check is about what the city does with a stretch** (its ground is the only
## ground, its crowd enters at the ends, its drawing leaves the void alone) and the real `Crowd` and `DayDirector`
## beside it: a stretch is a guarantee between the recipe's map and those modules, which none of their suites
## is handed. The checks that read only the built map (`RecipeCityBuilder`) need no city.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const SCENE := "res://scene-recipes/task-07-package.json"
const PARTIAL_COURTYARD_SCENE := "res://scene-recipes/task-14-last-night.json"
const RecipeErrors := preload("res://tests/recipe_runtime_errors.gd")

## Where each recipe is written and loaded, and what loading it answers.
var _errors := RecipeErrors.new()

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var built := RecipeCityBuilder.build(data)
	t.check(built.errors.is_empty(), "day 7's stretch loads explicit context: %s" % [built.errors])
	if not built.errors.is_empty():
		return
	var map: CityMap = built.map
	_test_the_stretch_is_the_only_ground(t, map, data)
	_test_the_arrow_stays_on_the_stretch(t, map)
	_test_saved_layout_is_independent(t, data)
	_test_authored_building_values_drive_live_joins(t, data)
	_test_authored_partial_courtyard_controls_live_tint(t)
	_test_the_schema(t, data)
	_test_the_crowd_enters_at_the_ends(t, map)
	_test_the_draft_takes_whole_streets(t, data)
	_test_the_route_bag(t, map, data)
	_test_the_city_draws_the_stretch_alone(t, map)
	_test_a_door_a_recipe_stands_is_a_point_a_mast_keeps_clear_of(t)
	await _test_appeared_requires_sight(t)

## `appeared` asks that a subject has been in the picture the camera draws, by the tick the
## observation names: the camera's real view at its zoom, not a constant half-extent. A scripted
## recipe installed on a city in a viewport of its own, an actor named by its `setup.actors`, begun
## and left to its own physics ticks, ends the game (what `configure()` was handed, as `main` hands its
## own) with status 0 when the observation holds and 1 when it does not. An actor wholly outside the view
## fails whether it is far off or only just outside the real half-width at a close zoom (the stale
## `Tuning.VIEW_HALF_EXTENT` constant, 320px, would have counted it); one inside it passes at the
## default zoom and zoomed out.
func _test_appeared_requires_sight(t: TestRunner) -> void:
	var seen := await _sight(t, 1.0, 2)
	t.check(seen == [0], "at the default camera zoom, an actor in view counts once it enters view: %s" % [seen])
	var far := await _sight(t, 1.0, 36)
	t.check(far == [1], "an existing actor that never enters the camera does not satisfy appeared: %s" % [far])
	# At zoom 4 the real half-width is 160px of a 1280px window; an actor 7 tiles (224px) out has its
	# body (32px) wholly outside it although inside `Tuning.VIEW_HALF_EXTENT.x` (320px), the stale
	# constant this regression replaces.
	var close := await _sight(t, 4.0, 7)
	t.check(close == [1], "at zoom 4, an actor wholly outside the actual camera half-width does not count: %s"
			% [close])
	# At zoom 0.5 the half-width is 1280px; 36 tiles (1152px) out the body is wholly inside it.
	var wide := await _sight(t, 0.5, 36)
	t.check(wide == [0], "zoomed out, an actor the actual camera includes counts: %s" % [wide])

## The exit statuses a scripted scene ends its game with: a free-standing walker (`setup.actors`) `tiles`
## tiles east of her on a sidewalk, a camera at `zoom` on her in a 1280x720 viewport, and the observation
## that the walker `appeared` by the fifth tick, left to its own ticks past the scene's half second.
func _sight(t: TestRunner, zoom: float, tiles: int) -> Array[int]:
	var own_run := RunState.new()
	own_run.start_run(4242)
	own_run.header.day = 3
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	t.add_child(viewport)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	city.run = own_run
	viewport.add_child(city)
	city.build(CityGenerator.generate(4242))
	var state := CityState.new()
	own_run.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, 3)
	city.start_recipe_day(state, 3, own_run.calendar.day_rng(3, "closures"))
	var from := Vector2i.ZERO
	var found := false
	for tile in city.map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		var along := tile + Vector2i(tiles, 0)
		if city.map.tile_at(along) == GameEnums.TileType.SIDEWALK and city.map.is_open(tile) \
				and city.map.is_open(along) and CityMap.corridor_offset(along.y) in CrowdLanes.SIDEWALK_OFFSETS:
			from = tile
			found = true
			break
	t.check(found, "a sidewalk tile with a sidewalk %d tiles east of it" % tiles)
	var her := city.map.tile_to_world(from)
	var there := city.map.tile_to_world(from + Vector2i(tiles, 0))
	# A walker pinned on a sidewalk stands exactly on its lane (`SceneRecipeRuntime` never snaps it).
	there.y = CrowdLanes.walker_lane_centre(CrowdLanes.corridor_at(there.y),
			CityMap.corridor_offset(from.y), CrowdLanes.SIDEWALK_OFFSETS)
	var player: Stroller = load("res://scenes/player/stroller.tscn").instantiate()
	# The zoom is fixed before her camera enters the tree: a Camera2D applies a zoom it is changed to
	# on its next process step, and `appeared` is asked of every tick from the first.
	(player.get_node("Camera2D") as Camera2D).zoom = Vector2.ONE * zoom
	viewport.add_child(player)
	(player.get_node("Camera2D") as Camera2D).make_current()
	var ended: Array[int] = []
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"name": "sight", "setup": {"day": 3, "player": {"at": [her.x, her.y]},
			"actors": [{"name": "actor", "kind": "walker", "at": [there.x, there.y],
			"direction": "east"}]},
			"playback": {"duration": 0.5, "settled_camera": true,
			"observations": [{"tick": 5, "subject": "actor", "condition": "appeared"}]}},
			"manifest": {}, "anchors": {}, "map": city.map},
			RunConfig.parse(PackedStringArray(["--recipe", "sight.json", "--recipe-mode", "scripted"]),
					"", true),
			own_run, func(code: int) -> void: ended.append(code))
	viewport.add_child(runtime)
	var errors := runtime.install(city, player, player.get_node("Baby"),
			DaySpec.for_day(3, Tuning.DAY_LENGTH_SECONDS))
	t.check(errors.is_empty(), "the sight scene is installed: %s" % [errors])
	if errors.is_empty():
		runtime.begin()
		await PhysicsTicks.pass_ticks(t, 20)
	viewport.free()
	return ended

## The live map against the recipe's own lists, never against a generated city *(mossy-marmot,
## inbox #618, the player's choice: "Finish fully handcrafted layouts now")*: each stretch tile
## is the type `stretch.tiles` lists for it, every other tile is void, and the void the stretch
## cut off is ground in its saved `context`. Asked of the saved scene and of a copy with one road
## run hand-edited to sidewalk, which the saved context still has as road: an edit an author makes
## is what the scene shows, and holds here as it holds in play.
func _test_the_stretch_is_the_only_ground(t: TestRunner, map: CityMap, data: Dictionary) -> void:
	t.check(map.has_stretch() and map.stretch_active, "the scene's map shows its stretch")
	var context := RecipeCityContext.restore(data.context)
	_check_the_ground(t, map, data, context, "the saved scene")
	var edited := data.duplicate(true)
	var road: Array = edited.stretch.tiles.road
	var moved: Array = road.pop_back()
	(edited.stretch.tiles.sidewalk as Array).append(moved)
	var tile := Vector2i(int(moved[1]), int(moved[0]))
	var rebuilt := RecipeCityBuilder.build(edited)
	t.check(rebuilt.errors.is_empty() and context.tile_at(tile) == GameEnums.TileType.ROAD,
			"the hand-edited copy builds, its edit at %s differing from the saved context: %s"
			% [tile, rebuilt.errors])
	if rebuilt.errors.is_empty():
		_check_the_ground(t, rebuilt.map, edited, context, "the hand-edited copy")
	var edges := map.witness_only()
	var outside := Vector2i(0, 0)
	t.check(not map.in_stretch(outside) and map.tile_at(outside) == context.tile_at(outside),
			"a whole-city rule reads the saved context while the edges are off")
	map.restore_edges(edges)
	t.check(map.stretch_active and map.tile_at(outside) == GameEnums.TileType.BUILDING,
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
	for y in map.size.y:
		for x in map.size.x:
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

## The ground every sweep of the red arrow starts from (`WalkField.ground_for()`, which the
## director's `_ground_for_the_arrow()` lays out once for each state of what blocks her and the
## day-13 guard's walk reads too) is the authored street's, not the hidden context's. On the
## scene's own map: the streets the stretch was cut from go on under the void, as walkable ground
## in its saved context. A target standing on that hidden ground, nearer to her than one on the
## stretch by the context's walk, is the counterexample: a sweep of the raw context picks it, and the
## scene's real walk must pick the one on the street she can walk to.
func _test_the_arrow_stays_on_the_stretch(t: TestRunner, map: CityMap) -> void:
	var raw_ground := PackedInt32Array()
	raw_ground.resize(map.tiles.size())
	raw_ground.fill(WalkField.UNREACHED)
	var start := Vector2i.ZERO
	for y in map.size.y:
		for x in map.size.x:
			if start == Vector2i.ZERO and map.in_stretch(Vector2i(x, y)) \
					and map.is_walkable(Vector2i(x, y)):
				start = Vector2i(x, y)
	var from_her: Array[Dictionary] = [{"key": "her", "at": map.tile_to_world(start),
			"reach": 0.0, "beat": PackedVector2Array()}]
	var raw := _swept(map, from_her, raw_ground)
	var authored := _swept(map, from_her, WalkField.ground_for(map))
	# The hidden ground nearest her by the context's walk, a tile clear of the stretch's own (a
	# target seeds the tiles within a tile of it, which would reach the stretch from the edge).
	var through_void := Vector2i(-1, -1)
	var nearest_hidden := INF
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not map.is_cut_off(tile) or raw.length_at(tile) < 0 \
					or raw.length_at(tile) >= nearest_hidden:
				continue
			var clear := true
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				clear = clear and not map.in_stretch(tile + step)
			if clear:
				through_void = tile
				nearest_hidden = raw.length_at(tile)
	t.check(through_void.x >= 0, "the scene's stretch has hidden ground the context walks to")
	if through_void.x < 0:
		return
	# The stretch's tile farthest from her by the authored walk, which the context's walk puts
	# farther than the hidden ground too.
	var on_stretch := start
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.in_stretch(tile) and authored.length_at(tile) > authored.length_at(on_stretch):
				on_stretch = tile
	t.check(raw.length_at(on_stretch) > raw.length_at(through_void),
			"and it is nearer her through the context than the far end of the street is")
	var targets: Array[Dictionary] = [
		{"key": "near_on_stretch", "at": map.tile_to_world(on_stretch),
				"reach": 0.0, "beat": PackedVector2Array()},
		{"key": "near_through_void", "at": map.tile_to_world(through_void),
				"reach": 0.0, "beat": PackedVector2Array()}
	]
	t.check(_swept(map, targets, raw_ground).nearest_at(start) == "near_through_void",
			"the scene's raw context chooses the target on the hidden ground")
	t.check(_swept(map, targets, WalkField.ground_for(map)).nearest_at(start) == "near_on_stretch",
			"the task arrow chooses the target on the authored street she can walk to")

## A finished sweep from `targets` over `ground`.
func _swept(map: CityMap, targets: Array[Dictionary], ground: PackedInt32Array) -> WalkField:
	var field := WalkField.start(map, targets, Vector2i.ZERO)
	while not field.done:
		field.advance(map, ground, map.tiles.size())
	return field

func _test_saved_layout_is_independent(t: TestRunner, data: Dictionary) -> void:
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
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		city.build(map)
		city.start_day(state, 7, RandomNumberGenerator.new(),
				DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
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
	var lattice := StreetNetwork.new()
	while not lattice.segment_containing(planted) and planted.x < int(run[2]):
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
func _test_authored_building_values_drive_live_joins(t: TestRunner, day_seven: Dictionary) -> void:
	var edited := day_seven.duplicate(true)
	var back_lot := Rect2i(90, 56, 2, 6)
	var front_lot := Rect2i(90, 62, 2, 8)
	for spec: Dictionary in edited.stretch.buildings:
		if SceneRecipe.rect(spec.lot) == back_lot:
			spec.height = 4
	var built := RecipeCityBuilder.build(edited)
	t.check(built.errors.is_empty(), "the adjacent-height edit builds: %s" % [built.errors])
	if built.errors.is_empty():
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
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
func _test_authored_partial_courtyard_controls_live_tint(t: TestRunner) -> void:
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
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
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

func _test_the_schema(t: TestRunner, data: Dictionary) -> void:
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
	t.check("\n".join(_errors.errors_of(t, crowd)).contains("authored actors"),
			"a stretch's crowd is its listed starting population, never a rolled one")

func _test_the_crowd_enters_at_the_ends(t: TestRunner, map: CityMap) -> void:
	var field := CrowdField.new(map, Vector2.ZERO)
	field.use_stretch()
	var ends := field.ends_of_the_stretch()
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
	var looking := Vector2(123, 456)
	field.centre = looking
	t.check(field.has_stretch() and field.looking_at() == looking and field.centre != looking,
			"the field stays over the whole stretch while the camera moves")

## Drafting is the one place a stretch meets generation: the draft walks the whole city its
## drafting inputs make (`SceneRecipeDraft.base_of()`). Asked as a draft run asks it: a city of the
## witness, the tiles she walked recorded (`SceneRecipeDraft.record()`), the stretch composed
## (`SceneRecipeDraft.compose()`), and `stretch.tiles` read back.
func _test_the_draft_takes_whole_streets(t: TestRunner, data: Dictionary) -> void:
	var witness: CityMap = RecipeCityBuilder.build(SceneRecipeDraft.base_of(data)).map
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	city.build(witness)
	var segment := witness.network.by_key(Vector3i(5, 5, 1))
	var drafted := _drafted(t, city, data, [Vector2i(segment.tile_rect().get_center())], [])
	var ground := _listed(drafted)
	var whole := true
	for tile in witness.rect_tiles(segment.tile_rect()):
		whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	for end: Vector2i in [segment.a, segment.b]:
		var box := Rect2i(end * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		for tile in witness.rect_tiles(box):
			whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	t.check(whole and not ground.is_empty(),
			"a step on a street takes the whole street and the junction at each end")
	# A mark she reads from beside it, pinned by the task: its own corner and not the alley behind
	# it, which only walking the alley takes in (`SceneRecipeDraft.compose()` adds a pin as unwalked).
	var mouth := Vector2i(92, 69)
	var behind := mouth + Vector2i.UP * 4
	var home := witness.world_to_tile(witness.doorstep_world_position())
	var pinned := _listed(_drafted(t, city, data, [home], [witness.tile_to_world(mouth)]))
	t.check(pinned.has(mouth) and not pinned.has(behind),
			"a pinned mark brings its own corner, not the alley behind it")
	var walked := _listed(_drafted(t, city, data, [home, mouth], []))
	t.check(walked.has(behind), "walking in at the same mouth takes the whole alley behind it")
	city.free()

## The stretch a draft that walked `walked` (tiles, in order) and was pinned `pinned` (world points)
## composes for `data`'s recipe in `city`, in a run of its own on day 7.
func _drafted(t: TestRunner, city: City, data: Dictionary, walked: Array[Vector2i],
		pinned: Array[Vector2]) -> Dictionary:
	var draft := SceneRecipeDraft.new()
	var walker := Node2D.new()
	for tile in walked:
		walker.position = city.map.tile_to_world(tile)
		draft.record(walker, city, null)
	walker.free()
	var own_run := RunState.new()
	own_run.start_run(7)
	own_run.header.day = 7
	var problems: Array[String] = []
	var drafted := draft.compose(data, own_run, city, city.map.tile_to_world(walked[0]), pinned,
			problems)
	return drafted

## The tiles a drafted recipe's `stretch.tiles` lists, as a set.
func _listed(drafted: Dictionary) -> Dictionary:
	var listed := {}
	for type_name: String in drafted.stretch.tiles:
		for run: Array in drafted.stretch.tiles[type_name]:
			for x in range(int(run[1]), int(run[2]) + 1):
				listed[Vector2i(x, int(run[0]))] = true
	return listed

## The street door a recipe's `setup.gates` stands is the one the day's own plan stands
## (`RegionPlanner.stand_door()`), at the points `MastSites` keeps a mast's field clear of: so a mast
## `SceneRecipeRuntime` places is already clear of every door it stands, by `MastSites.is_eligible()`
## alone. Asked of every street door a day plans (`RegionPlanner.plan_day()`) on the context city,
## from the first day with checkpoints and on the last.
func _test_a_door_a_recipe_stands_is_a_point_a_mast_keeps_clear_of(t: TestRunner) -> void:
	var map: CityMap = RecipeCityBuilder.build({"version": 1, "name": "doors", "seed": 11,
			"extent": {"scope": "full"}, "city": {"context_seed": 1917501}}).map
	var points := MastSites.possible_door_points(map)
	var bodies := 0
	var off_a_point := 0
	for day: int in [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1]:
		var plan := RegionPlanner.plan_day(map, DaySpec.for_day(day), RouteTree.for_day(map, day))
		var stood := RegionPlanner.RegionPlan.new()
		for door in plan.doors:
			RegionPlanner.stand_door(map, door, stood)
		for body in stood.door_bodies:
			bodies += 1
			var nearest := INF
			for point in points:
				nearest = minf(nearest, point.distance_to(body.position))
			off_a_point += int(nearest > 0.01)
	t.check(bodies > 0 and off_a_point == 0,
			"every one of the %d bodies of a day's street doors stands on a point a mast keeps clear of (%d do not)"
			% [bodies, off_a_point])

func _test_the_route_bag(t: TestRunner, map: CityMap, data: Dictionary) -> void:
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
	t.check("\n".join(_errors.errors_of(t, place)).contains("not a row the director sites"),
			"a marble names a row the director sites that day")
	var asked := data.duplicate(true)
	(asked.playback.observations as Array).append(
			{"tick": 1, "subject": "mark", "condition": "crowd", "walkers": 1})
	t.check("\n".join(_errors.errors_of(t, asked)).contains("round the player"),
			"a crowd observation asks about the picture round her")

func _test_the_city_draws_the_stretch_alone(t: TestRunner, map: CityMap) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
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
