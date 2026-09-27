extends RefCounted
## Scenery phases update their own retained layers without changing static layout or bodies.

func run(t) -> void:
	_test_roof_rotors(t)
	_test_event_parts(t)
	_test_water_ownership(t)

func _test_roof_rotors(t) -> void:
	var building := Building.new()
	building.footprint = Vector2(256, 256)
	building.height = 64
	building.district = GameEnums.BlockPurpose.INDUSTRIAL
	t.add_child(building)
	t.check(not building._rotor_layers.is_empty(), "the roof fixture actually has moving vents")
	var furniture := building._roof_furniture.duplicate(true)
	var collision: Shape2D = building._collision.shape
	var layers := building._roof_layers.duplicate()
	building._process(Building.VENT_FRAME_INTERVAL - 0.01)
	for rotor in building._rotor_layers:
		t.check(not rotor.frame_b, "rotor holds its first phase until the existing interval")
	building._process(0.02)
	for layer: SceneryLayer in layers:
		if building._rotor_layers.has(layer):
			t.check(layer.frame_b, "the small rotor advances independently")
			t.check(layer._rects[0].size == Vector2(6, 6), "only the cropped rotor is animated")
		else:
			t.check(not layer.frame_b, "a stationary furniture batch keeps its frame")
	t.check(building._roof_furniture == furniture, "animation does not reroll furniture")
	t.check(building._collision.shape == collision, "animation does not rebuild collision")
	building._rebuild()
	for layer in layers:
		t.check(not is_instance_valid(layer), "rebuild releases every superseded roof layer")
	for rotor in building._rotor_layers:
		t.check(rotor.frame_b, "rebuilding the roof preserves the current phase")
	var old_rotor: WeakRef = weakref(building._rotor_layers[0]._textures[0])
	t.remove_child(building)
	t.check(building._roof_layers.is_empty(), "tree exit releases every cached roof region")
	if not AtlasLibrary.is_acquired(&"buildings"):
		t.check(old_rotor.get_ref() == null, "the last building retains no atlas texture after exit")
	t.add_child(building)
	t.check(not building._rotor_layers.is_empty() and building._rotor_layers[0].frame_b,
			"reentry acquires fresh regions and preserves the animation phase")
	building.footprint = Vector2(32, 32)
	t.check(building._rotor_layers.is_empty() and not building.is_processing(),
			"a roof without vents releases them and stops its animation callback")
	building.free()

func _test_event_parts(t) -> void:
	AtlasLibrary.acquire(&"events")
	for id: String in ["car_accident", "burst_water_main"]:
		for vertical: bool in [false, true]:
			var instance := EventInstance.new()
			instance.setup(EventCatalogue.by_id(id), Vector2.ZERO)
			instance._spread_vertical = vertical
			t.add_child(instance)
			instance._process(instance.def.telegraph_time + 0.01)
			var scenery := instance._scenery
			t.check(scenery != null and not scenery.moving_layers.is_empty(),
					"%s/%s has independently moving detail" % [id, vertical])
			var body := instance._obstruction
			var centers := instance.solid_part_centres()
			var key := instance._picture_key()
			var initial: bool = scenery.moving_layers[0].frame_b
			var period := EventInstance.CAR_ACCIDENT_SMOKE_PERIOD if id == "car_accident" \
					else EventInstance.BURST_MAIN_SPLASH_PERIOD
			instance._process(period * 0.5)
			for layer in scenery.moving_layers:
				t.check(layer.frame_b != initial, "the existing event clock advances each detail")
			for layer in scenery.static_layers:
				t.check(not layer.frame_b, "stationary surroundings retain their phase")
			t.check(instance._picture_key() == key, "animation leaves the static event key alone")
			t.check(instance._obstruction == body and instance.solid_part_centres() == centers,
					"animation preserves both collision resource and placement")
			instance._finish()
			t.check(not scenery.visible, "a finished event hides every scenery layer")
			t.remove_child(instance)
			t.check(scenery.moving_layers.is_empty() and scenery.static_layers.is_empty(),
					"detaching the event releases retained atlas regions")
			t.add_child(instance)
			t.check(not scenery.moving_layers.is_empty(), "reentry rebinds event scenery regions")
			instance.free()
			t.check(not is_instance_valid(scenery), "removing an event releases its scenery")
	AtlasLibrary.release(&"events")

func _test_water_ownership(t) -> void:
	var packed: PackedScene = load("res://scenes/world/city.tscn")
	var city: City = packed.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	var water := city._south_water
	t.check(not city._ground.tile_set.has_source(GroundTiles.WATER),
			"the static ground sheet contains no unused water source")
	t.check(not water.cells.is_empty(), "the actual city supplies water cells")
	var expected: Dictionary[Vector2i, bool] = {}
	var bridge_left := city.map.main_road * CityMap.period() + Tuning.SIDEWALK_WIDTH
	var bridge_right := bridge_left + Tuning.STREET_WIDTH - 2 * Tuning.SIDEWALK_WIDTH
	for y in range(city.map.size.y + 1, city.map.size.y + City.OUTSIDE_DEPTH_TILES):
		for x in range(-City.OUTSIDE_DEPTH_TILES, city.map.size.x + City.OUTSIDE_DEPTH_TILES):
			if x < bridge_left or x >= bridge_right:
				expected[Vector2i(x, y)] = true
	var actual: Dictionary[Vector2i, bool] = {}
	for tile in water.cells:
		actual[tile] = true
		t.check(city._ground.get_cell_source_id(tile) == -1,
				"animated water has no duplicate pixel owner in the static TileMap")
	t.check(actual == expected and actual.size() == water.cells.size(),
			"water fills the complete south band beyond the bulkhead, excluding the bridge")
	var cells := water.cells.duplicate()
	water._process(0.25)
	t.check(water.elapsed > 0.0 and water.cells == cells,
			"ripple time advances without repainting any ground cell")
	city._ground.remove_child(water)
	t.check(water._texture == null and water.material == null,
			"detaching water releases its atlas region and shader material")
	city._ground.add_child(water)
	t.check(water._texture != null and water.elapsed > 0.0,
			"reentry rebinds the water region without resetting its clock")
	city._paint_ground()
	t.check(not is_instance_valid(water), "repaint releases the prior water and material")
	t.check(city._south_water.cells == cells, "repaint preserves the shoreline and bridge gap")
	city.free()
