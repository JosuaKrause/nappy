extends RefCounted
## The water a city paints off its map's southern edge, and which ground surface owns it: the shore
## the ground keeps resident is water on every cell outside the map and clear of the bridge's
## columns, each cell owned by one animated surface and none by the static tile layer, and a repaint
## (the escape's route tint) keeps the shoreline and the bridge gap.
##
## **This is a direct test of the city's painting** (`City.scenery_ground_source()` decides each
## cell, the ground lays what it says): the real city is built, from a cached map
## (`tests/city_map_cache.gd`). What one water surface does with its cells is
## `tests/test_scenery_animation.gd`'s.

const MapCache := preload("res://tests/city_map_cache.gd")
const GroundCells := preload("res://tests/ground_cells.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const WATER_SEED := 4242

func run(t: TestRunner) -> void:
	_test_water_ownership(t)

func _test_water_ownership(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, WATER_SEED)
	t.add_child(city)
	city.build(MapCache.of(WATER_SEED))
	var shore_reach := float(CityMap.OUTSIDE_DEPTH_TILES * Tuning.TILE_SIZE)
	# Inspect the complete shore explicitly, corners under the forest bands included; an ordinary
	# home boot retains none of this water.
	city.scenery.update(Rect2(Vector2(-shore_reach, city.map.world_size().y),
			Vector2(city.map.world_size().x + 2.0 * shore_reach,
					CityMap.OUTSIDE_DEPTH_TILES * Tuning.TILE_SIZE)), true)
	# Out of view, the city keeps the residency it was given: its own process frame would otherwise
	# follow the camera home and release the shore this inspects.
	city.visible = false
	var surfaces: Array[SceneryWater] = []
	for chunk: TileMapLayer in city.scenery_ground.chunks().values():
		for child in chunk.get_children():
			if child is SceneryWater:
				surfaces.append(child)
	t.check(not surfaces.is_empty(), "the resident shoreline supplies water surfaces")
	var water := surfaces[0]
	t.check(not city.scenery_ground.tile_set.has_source(GroundTiles.WATER),
			"the static ground sheet contains no unused water source")
	t.check(not water.cells.is_empty(), "the actual city supplies water cells")
	var expected: Dictionary[Vector2i, bool] = {}
	var bridge_left := city.map.main_road * CityMap.period() + Tuning.SIDEWALK_WIDTH
	var bridge_right := bridge_left + Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH
	# Residency prepares whole chunks, including water beyond the requested shore. The bridge
	# carries its road on for as far as any view asks, so its columns are never water.
	for key: Vector2i in city.scenery_ground.chunks():
		var start := key * SceneryGround.CHUNK_TILES
		for y in range(maxi(start.y, city.map.size.y + 1), start.y + SceneryGround.CHUNK_TILES):
			for x in range(start.x, start.x + SceneryGround.CHUNK_TILES):
				if x < bridge_left or x >= bridge_right:
					expected[Vector2i(x, y)] = true
	var actual: Dictionary[Vector2i, bool] = {}
	var count := 0
	for surface in surfaces:
		for tile in surface.cells:
			actual[tile] = true
			count += 1
			t.check(GroundCells.source_id(city.scenery_ground, tile) == -1,
					"animated water has no duplicate pixel owner in the static TileMap")
	t.check(actual == expected and actual.size() == count,
			"resident water has one owner per cell and excludes the bridge columns at every depth")
	for y in range(city.map.size.y + 1, city.map.size.y + CityMap.OUTSIDE_DEPTH_TILES):
		for x in range(-CityMap.OUTSIDE_DEPTH_TILES, city.map.size.x + CityMap.OUTSIDE_DEPTH_TILES):
			if x < bridge_left or x >= bridge_right:
				t.check(actual.has(Vector2i(x, y)),
						"water fills the complete requested shore, south-west and south-east corners included")
	# The escape's route tint repaints every resident chunk, shore included, as the game does.
	city.tint_the_route(null)
	t.check(not is_instance_valid(water), "repaint releases the prior water and material")
	for tile: Vector2i in expected:
		t.check(GroundWater.at(city.scenery_ground, tile), "repaint preserves the shoreline and bridge gap")
	city.free()
