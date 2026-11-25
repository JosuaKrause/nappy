extends RefCounted
## `WalkField`'s ground for the red arrow's sweep on an authored scene's map
## (`docs/SCENE_RECIPES.md`, "The task scenes"): the ground every sweep starts from
## (`WalkField.ground_for()`, which the director's `_ground_for_the_arrow()` lays out once for
## each state of what blocks her and the day-13 guard's walk reads too) is the authored
## street's, not the hidden context's.
##
## The map is the one data a recipe builds (`RecipeCityBuilder.build()`, task 7's stretch): a
## map with a stretch is model data, so no city, crowd or director is made here, and the sweeps
## are `WalkField`'s own, advanced by hand over that ground.

const SCENE := "res://scene-recipes/task-07-package.json"

## The diagnostics a builder's answer carries.
func _diagnostics(result: Dictionary) -> Array[String]:
	return result.errors

func run(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var built := RecipeCityBuilder.build(data)
	t.check(_diagnostics(built).is_empty(),
			"day 7's stretch loads explicit context: %s" % [built.errors])
	if not _diagnostics(built).is_empty():
		return
	var map: CityMap = built.map
	_test_the_arrow_stays_on_the_stretch(t, map)

## The ground every sweep of the red arrow starts from (`WalkField.ground_for()`, which the
## director's `_ground_for_the_arrow()` lays out once for each state of what blocks her and the
## day-13 guard's walk reads too) is the authored street's, not the hidden context's. On the
## scene's own map: the streets the stretch was cut from go on under the void, as walkable
## ground in its saved context. A target standing on that hidden ground, nearer to her than one
## on the stretch by the context's walk, is the counterexample: a sweep of the raw context picks
## it, and the scene's real walk must pick the one on the street she can walk to.
func _test_the_arrow_stays_on_the_stretch(t: TestRunner, map: CityMap) -> void:
	var raw_ground := PackedInt32Array()
	raw_ground.resize(map.size_in_tiles().x * map.size_in_tiles().y)
	raw_ground.fill(WalkField.UNREACHED)
	var start := Vector2i.ZERO
	for y in map.size_in_tiles().y:
		for x in map.size_in_tiles().x:
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
	for y in map.size_in_tiles().y:
		for x in map.size_in_tiles().x:
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
	for y in map.size_in_tiles().y:
		for x in map.size_in_tiles().x:
			var tile := Vector2i(x, y)
			if map.in_stretch(tile) \
					and authored.length_at(tile) > authored.length_at(on_stretch):
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
	t.check(_swept(map, targets,
			WalkField.ground_for(map)).nearest_at(start) == "near_on_stretch",
			"the task arrow chooses the target on the authored street she can walk to")

## A finished sweep from `targets` over `ground`.
func _swept(map: CityMap, targets: Array[Dictionary], ground: PackedInt32Array) -> WalkField:
	var field := WalkField.start(map, targets, Vector2i.ZERO)
	while not field.is_done():
		field.advance(map, ground, map.size_in_tiles().x * map.size_in_tiles().y)
	return field
