extends RefCounted
## Residency is presentation only: coverage, hysteresis, reconstruction, stable identity and RNG.

const CITY := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	for seed_value in [4242, 3265820891]:
		_test_city(t, seed_value)

func _view(at: Vector2) -> Rect2:
	return Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2)

func _test_city(t, seed_value: int) -> void:
	GameState.start_run(seed_value)
	var city: City = CITY.instantiate()
	t.add_child(city)
	var map := CityGenerator.generate(seed_value)
	city.build(map)
	var home := _view(map.doorstep_world_position())
	var initial := city._ground.get_used_cells().size()
	t.check(initial > 0 and initial < map.size.x * map.size.y / 8,
			"boot prepares a nonempty neighborhood, not the entire map")
	_check_coverage(t, city, home)
	var unloaded := 0
	for building in city.buildings():
		if not building.scenery_resident:
			unloaded += 1
			t.check(not building.is_processing(), "unprepared roofs run no animation callbacks")
			t.check(building._roof_layers.is_empty() and building._windows.is_empty(),
					"a distant building has no window/roof preparation")
			t.check(building._collision.shape != null and building.shape != null,
					"a distant building keeps its complete collision")
	t.check(unloaded > city.buildings().size() / 2, "most buildings are unprepared at home")
	var building := city.buildings()[0]
	var identity := building.get_instance_id()
	var collision := building._collision.shape
	var target := _view(building.scenery_bounds().get_center())
	city.scenery.update(target, true)
	var windows := building._windows.duplicate()
	var roof := building._roof_furniture.duplicate(true)
	var layers := building._roof_layers.duplicate()
	var cells := city._ground.get_used_cells()
	var chunk_ids := {}
	for key: Vector2i in city._ground.chunks:
		chunk_ids[key] = city._ground.chunks[key].get_instance_id()
	# Moving the boundary repeatedly by a tile never crosses the wider eviction boundary.
	city.scenery.update(Rect2(target.position + Vector2(32, 0), target.size), true)
	var prepared := city._ground.prepared
	var evicted := city._ground.evicted
	for i in 12:
		city.scenery.update(Rect2(target.position + Vector2(32 if i % 2 else 0, 0), target.size), true)
	t.check(city._ground.prepared == prepared and city._ground.evicted == evicted,
			"repeated load-boundary reversals inside retention cause no allocation or eviction")
	for key: Vector2i in chunk_ids:
		t.check(city._ground.chunks[key].get_instance_id() == chunk_ids[key],
				"retained chunks preserve their actual allocation")
	var far := _view(map.world_size() - Vector2(100, 100))
	city.scenery.update(far, true)
	t.check(not building.scenery_resident, "leaving the retention boundary evicts the building")
	for layer in layers:
		t.check(not is_instance_valid(layer), "eviction frees roof nodes and their texture references")
	t.check(city._ground.evicted > evicted, "leaving retention frees actual ground chunks")
	for tile in cells:
		if not far.grow(SceneryResidency.RETAIN_MARGIN).intersects(
				SceneryGround.bounds(SceneryGround.key_for(tile))):
			t.check(city._ground.get_cell_source_id(tile) == -1, "distant cells have no resident owner")
	building.day = 12
	building.condition = Building.Condition.BOARDED
	building.powered = false
	building.neighbor_window_col = 2
	building.posters = {1: {"kind": 1, "tear": 0, "under": -1, "under_tear": 0, "side": 1}}
	var changed: Array[Vector2i] = [map.world_to_tile(target.get_center())]
	city.close_ground(changed)
	seed(91234)
	var expected_rng := randi()
	seed(91234)
	city.scenery.update(target, true)
	t.check(randi() == expected_rng, "scenery reconstruction consumes no global gameplay RNG")
	t.check(building.get_instance_id() == identity and building._collision.shape == collision,
			"residency preserves building identity and its collision resource")
	t.check(building._windows == windows and building._roof_furniture == roof,
			"returning artwork reconstructs the same seeded window and furniture layout")
	t.check(building.day == 12 and building.condition == Building.Condition.BOARDED \
			and not building.powered and building.neighbor_window_col == 2 \
			and building.posters.has(1), "changes while unloaded survive reconstruction")
	_check_coverage(t, city, target)
	var state := CityState.new()
	state.begin_day(map.block_plans, 8)
	city.start_day(state, 8, GameState.day_rng(8, "closures"))
	city.scenery.update(far, true)
	_check_coverage(t, city, far)
	city.scenery.update(home, true)
	_check_coverage(t, city, home)
	t.check(building.get_instance_id() == identity and building._collision.shape == collision,
			"dawn and relocation do not replace persistent building collision")
	# Clock belongs to the city, so a newly entered shoreline resumes its neighbors' phase.
	city._ground._process(3.75)
	var shore := _view(Vector2(map.world_size().x * 0.5, map.world_size().y + 100))
	city.scenery.update(shore, true)
	var water_count := 0
	for chunk: TileMapLayer in city._ground.chunks.values():
		for child in chunk.get_children():
			if child is SceneryWater:
				water_count += 1
				t.check(child.elapsed == city._ground.elapsed and not child.is_processing(),
						"new water chunks share one pausable city phase")
	t.check(water_count > 1, "the phase check covers multiple water chunks")
	city.free()

func _check_coverage(t, city: City, view: Rect2) -> void:
	var lo := Vector2i((view.position / Tuning.TILE_SIZE).floor())
	var hi := Vector2i((view.end / Tuning.TILE_SIZE).ceil())
	var wrong := 0
	var checked := 0
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			var tile := Vector2i(x, y)
			var source := city.scenery_ground_source(tile)
			if source == GroundTiles.WATER:
				wrong += int(not city._ground.has_water(tile))
			elif source >= 0:
				wrong += int(city._ground.get_cell_source_id(tile) != source)
				checked += 1
	t.check(checked > 0 and wrong == 0, "visible ground has its current source without gaps")
	for building in city.buildings():
		if building.scenery_bounds().intersects(view):
			t.check(building.scenery_resident, "every intersecting building is prepared")
