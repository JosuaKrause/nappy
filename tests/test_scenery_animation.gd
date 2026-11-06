extends RefCounted
## Scenery phases update their own retained layers without changing static layout or bodies.

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const GroundCells := preload("res://tests/ground_cells.gd")
const RecordingSceneryDrawer := preload("res://tests/recording_scenery_drawer.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const WATER_SEED := 4242

func run(t) -> void:
	await _test_roof_rotors(t)
	_test_both_rotor_phases_share_one_registration(t)
	await _test_event_parts(t)
	await _test_water_ownership(t)

## A roof that is told what to stand through a recording drawer (`tests/recording_roof_drawer.gd`,
## standing each unit for real so a vent has its rotor), and whose own process frames run in the
## tree. Its rotors are read off the units it was told to stand (`RoofObject.rotor`), never off what
## the building holds, and the picture each rotor stands off the scenery drawer the real roof drawer
## hands every rotor (`tests/recording_scenery_drawer.gd`), as the city hands its own. Time is the engine's `time_scale`, which scales the delta the building's
## process frame is given: a frame at a hundredth of its length cannot reach the interval, and one at
## a hundred thousand times its length always crosses it, so no check depends on how long a frame
## takes.
func _test_roof_rotors(t) -> void:
	var pages := PageLog.new()
	var atlas := AtlasLibrary.new()
	var drawer := RecordingRoofDrawer.new()
	var scenery := RecordingSceneryDrawer.new()
	drawer.real = RoofDrawer.new(atlas, scenery)
	var building := Building.new()
	building.atlas = atlas
	building.roof_drawer = drawer
	building.footprint = Vector2(256, 256)
	building.height = 64
	building.district = GameEnums.BlockPurpose.INDUSTRIAL
	t.add_child(building)
	for variant in 200:
		if not _rotors(drawer).is_empty():
			break
		building.variant = variant + 1
	t.check(not _rotors(drawer).is_empty(), "the roof fixture actually has moving vents")
	var shape := building.shape
	var drawn := drawer.draws.size()
	var objects: Array[Building.RoofObject] = []
	for entry in drawer.standing():
		objects.append(entry.object)
	var rotors := _rotors(drawer)
	var first_phase: bool = rotors[0].frame_b
	t.check(building.is_processing(), "a roof with a vent takes its process frames")
	var clock := Engine.time_scale
	Engine.time_scale = 0.01
	for frame in 3:
		await t.get_tree().process_frame
		for rotor in _rotors(drawer):
			t.check(rotor.frame_b == first_phase,
					"rotor holds its first phase until the existing interval")
	for rotor in rotors:
		t.check(_picture_on(scenery, rotor) == _rotor_picture(atlas, first_phase),
				"a rotor stands the picture of its first phase")
	Engine.time_scale = clock
	# The frame after this one is given a delta a hundred thousand times its length, so it crosses
	# the interval once; the scale is back before the frame after that.
	Engine.time_scale = 100000.0
	await t.get_tree().process_frame
	Engine.time_scale = clock
	await t.get_tree().process_frame
	var turned := _rotors(drawer)
	t.check(turned[0].frame_b != first_phase,
			"the building's own process frames turn its rotors once the interval has passed")
	var phase: bool = turned[0].frame_b
	for rotor in turned:
		t.check(rotor.frame_b == phase, "the small rotors advance together")
		# One of the two phases is the alternate frame, so between this and the first phase's check
		# every rotor has stood both its pictures.
		t.check(_picture_on(scenery, rotor) == _rotor_picture(atlas, phase),
				"the turned rotor stands the picture of its new phase, drawn again on the turn")
	for object in objects:
		if object.texture_key != Building.VENT_HOUSING:
			t.check(object.get_child_count() == 0,
					"stationary roof objects own no independently redrawn child")
	t.check(drawer.draws.size() == drawn, "animation does not redraw or reroll the roof's furniture")
	t.check(building.shape == shape, "animation does not rebuild collision")
	# A rebuild from the property the city's own height and footprint changes assign.
	building.footprint = building.footprint
	for object in objects:
		t.check(not is_instance_valid(object), "rebuild releases every superseded roof object")
	t.check(drawer.standing().size() == objects.size()
			and drawer.draws.size() == drawn + objects.size(),
			"rebuild draws the roof again, once")
	for rotor in _rotors(drawer):
		t.check(rotor.frame_b == phase, "rebuilding the roof preserves the current phase")
	for entry in drawer.standing():
		if entry.texture == Building.VENT_HOUSING:
			t.check(entry.rotor_frame_b == phase, "the rebuilt roof is told the current phase")
	var old_rotor: WeakRef = weakref(atlas.region(Building.VENT_ROTOR))
	t.remove_child(building)
	t.check(drawer.standing().is_empty(),
			"tree exit releases every roof object and moving child")
	if not pages.held(&"buildings"):
		t.check(old_rotor.get_ref() == null, "the last building retains no atlas texture after exit")
	t.add_child(building)
	var reentered := _rotors(drawer)
	t.check(not reentered.is_empty() and reentered[0].frame_b == phase,
			"reentry acquires fresh regions and preserves the animation phase")
	building.footprint = Vector2(32, 32)
	t.check(_rotors(drawer).is_empty() and not building.is_processing(),
			"a roof without vents releases them and stops its animation callback")
	building.free()
	pages.stop()

## The turning rotor of every vent the drawer was told to stand and the building has not released.
func _rotors(drawer: RecordingRoofDrawer) -> Array[SceneryLayer]:
	var rotors: Array[SceneryLayer] = []
	for entry in drawer.standing():
		var object: Building.RoofObject = entry.object
		if object.rotor != null:
			rotors.append(object.rotor)
	return rotors

## The one picture `layer` stood the last time it was drawn through `scenery`, or null for none or
## more than one.
func _picture_on(scenery: RecordingSceneryDrawer, layer: SceneryLayer) -> Texture2D:
	var shown := scenery.shown_on(layer)
	return shown[0].texture if shown.size() == 1 else null

## The rotor's picture at `frame_b`: the alternate frame when it is set.
func _rotor_picture(atlas: AtlasLibrary, frame_b: bool) -> Texture2D:
	return atlas.region(Building.VENT_ROTOR_B if frame_b else Building.VENT_ROTOR)

## Both rotor frames are cropped out of the housing canvas from their editable vector sources, whose
## viewBoxes must agree, or the second frame would jump when the rotor turns.
func _test_both_rotor_phases_share_one_registration(t) -> void:
	var authored: Array[Rect2] = []
	for path in ["res://art/props/industrial_vent_rotor.svg",
			"res://art/props/industrial_vent_rotor_b.svg"]:
		var source := FileAccess.get_file_as_string(path)
		var regex := RegEx.new()
		t.check(regex.compile('viewBox="([0-9.]+) ([0-9.]+) ([0-9.]+) ([0-9.]+)"') == OK,
				"the rotor crop viewBox pattern compiles")
		var found := regex.search(source)
		t.check(found != null, "%s carries a registered viewBox" % path.get_file())
		if found != null:
			authored.append(Rect2(float(found.get_string(1)), float(found.get_string(2)),
					float(found.get_string(3)), float(found.get_string(4))))
	t.check(authored.size() == 2 and authored[0] == authored[1],
			"both rotor phases share one registration in the housing canvas")

## A crash and a burst main are drawn in slices, each holding its part's scenery
## (`SpreadLook.Slice`, `EventScenery`), so what is asked here is asked of every slice's. The
## axis it spreads on is the street it stands on (`EastWestStreet` is one running east-west), the
## way the game hands `setup()` a map. What each layer of the scenery stands is read off a recording
## scenery drawer, handed to the scenery by the event's drawer (`EventInstance.drawer`, as its
## manager's spawner hands the real one) the way the real one hands its own.
func _test_event_parts(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	for id: String in ["car_accident", "burst_water_main"]:
		for vertical: bool in [false, true]:
			var instance := EventInstance.new()
			instance.atlas = atlas
			var laid := RecordingSceneryDrawer.new()
			var pictures := RecordingEventDrawer.new(atlas)
			pictures.scenery_drawer = laid
			instance.drawer = pictures
			instance.setup(EventCatalogue.by_id(id), Vector2.ZERO, PackedVector2Array(),
					Vector2.RIGHT, EastWestStreet.new() if vertical else WorldMap.open_ground())
			t.add_child(instance)
			t.check(instance.runs_vertically() == vertical, "%s stands on the axis asked for" % id)
			# The slices go into the world on the idle frame after the instance is made.
			await t.get_tree().process_frame
			instance.step(instance.def.telegraph_time + 0.01)
			var sceneries := _sceneries_of(instance)
			var moving: Array[SceneryLayer] = []
			var still: Array[SceneryLayer] = []
			for scenery: EventScenery in sceneries:
				var split := _split_by_animation(scenery)
				moving.append_array(split[0])
				still.append_array(split[1])
			t.check(sceneries.size() > 1 and not moving.is_empty(),
					"%s/%s has independently moving detail across its slices" % [id, vertical])
			var body := _body_of(instance)
			var centers := instance.solid_part_centres()
			t.check(body != null and instance.is_solid(), "%s/%s stands a solid body" % [id, vertical])
			t.check(instance.look.redraw_if_the_picture_changed(),
					"the event's first drawn frame asks for its draw, so the gate is live for the check below")
			var initial: bool = moving[0].frame_b
			var period := EventPictures.CAR_ACCIDENT_SMOKE_PERIOD if id == "car_accident" \
					else EventPictures.BURST_MAIN_SPLASH_PERIOD
			# The layers are drawn on the frame after they are made.
			await t.get_tree().process_frame
			var before := {}
			for layer: SceneryLayer in moving + still:
				before[layer] = _pictures_on(laid, layer)
			instance.step(period * 0.5)
			# The look shows the step on the next drawn frame.
			var asked := instance.look.redraw_if_the_picture_changed()
			await t.get_tree().process_frame
			for layer in moving:
				t.check(layer.frame_b != initial, "the existing event clock advances each detail")
				var turned := _pictures_on(laid, layer)
				t.check(not turned.is_empty() and turned.size() == before[layer].size()
						and _all_differ(turned, before[layer]),
						"every moving detail stands its alternate picture once its frame flips")
			# Nothing flips a stationary layer's frame; flipped here through the member its scenery
			# flips a moving one's by, it is drawn again with the same pictures.
			var passes := {}
			for layer in still:
				passes[layer] = laid.passes_of(layer)
				layer.frame_b = not layer.frame_b
			await t.get_tree().process_frame
			for layer in still:
				t.check(laid.passes_of(layer) > passes[layer]
						and not before[layer].is_empty()
						and _pictures_on(laid, layer) == before[layer],
						"stationary surroundings have no alternate picture")
				layer.frame_b = not layer.frame_b
			t.check(not asked, "animation leaves the static event key alone")
			t.check(_body_of(instance) == body and instance.solid_part_centres() == centers,
					"animation preserves both collision resource and placement")
			# The instance's own process frame hides what a finished event leaves.
			instance.transition(EventInstance.Phase.DONE)
			await t.get_tree().process_frame
			await t.get_tree().process_frame
			t.check(sceneries.all(func(scenery: EventScenery) -> bool: return not scenery.visible),
					"a finished event hides every scenery layer")
			# Detached, it takes its slices and their scenery with it; back in the tree, it builds
			# them again once it has settled.
			t.remove_child(instance)
			await t.get_tree().process_frame
			t.check(sceneries.all(func(scenery: Variant) -> bool:
					return not is_instance_valid(scenery)),
					"detaching the event releases its scenery and its retained atlas regions")
			t.add_child(instance)
			await t.get_tree().process_frame
			var rebound := false
			for scenery in _sceneries_of(instance):
				rebound = rebound or not _split_by_animation(scenery)[0].is_empty()
			t.check(rebound, "reentry rebinds event scenery regions")
			var again := _sceneries_of(instance)
			instance.free()
			await t.get_tree().process_frame
			t.check(again.all(func(scenery: Variant) -> bool:
					return not is_instance_valid(scenery)),
					"removing an event releases its scenery")
	atlas.release(&"events")

## The pictures `layer` stood the last time it was drawn through `scenery`, in order.
func _pictures_on(scenery: RecordingSceneryDrawer, layer: SceneryLayer) -> Array[Texture2D]:
	var pictures: Array[Texture2D] = []
	for entry in scenery.shown_on(layer):
		pictures.append(entry.texture)
	return pictures

## Whether every picture of `a` differs from the one at its place in `b`, the two the same length.
func _all_differ(a: Array[Texture2D], b: Array[Texture2D]) -> bool:
	for i in a.size():
		if a[i] == b[i]:
			return false
	return true

## The scenery behind each of `instance`'s slices, in the slices' order.
## The layers `scenery` holds as `[moving, still]`: the moving ones are the layers its `set_frame()`
## turns to their alternate frame, the still ones the rest (its contact shadow and its static spans).
## The frame it had is put back.
func _split_by_animation(scenery: EventScenery) -> Array:
	var layers: Array[SceneryLayer] = []
	for child in scenery.get_children():
		if child is SceneryLayer:
			layers.append(child)
	var had := {}
	for layer in layers:
		had[layer] = layer.frame_b
	scenery.set_frame(true)
	var turned_on: Array[SceneryLayer] = []
	turned_on.assign(layers.filter(func(l: SceneryLayer) -> bool: return l.frame_b))
	scenery.set_frame(false)
	var moving: Array[SceneryLayer] = []
	moving.assign(turned_on.filter(func(l: SceneryLayer) -> bool: return not l.frame_b))
	var still: Array[SceneryLayer] = []
	still.assign(layers.filter(func(l: SceneryLayer) -> bool: return not moving.has(l)))
	scenery.set_frame(not moving.is_empty() and had[moving[0]])
	return [moving, still]

func _sceneries_of(instance: EventInstance) -> Array[EventScenery]:
	var found: Array[EventScenery] = []
	for slice in (instance.look as SpreadLook).slices():
		for child in slice.get_children():
			if child is EventScenery:
				found.append(child)
	return found

## The one solid body the instance stands, or null.
func _body_of(instance: EventInstance) -> StaticBody2D:
	for child in instance.get_children():
		if child is StaticBody2D:
			return child
	return null

func _test_water_ownership(t) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, WATER_SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(WATER_SEED))
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
	for chunk: TileMapLayer in city.scenery_ground.chunks.values():
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
	for key: Vector2i in city.scenery_ground.chunks:
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
	var cells := water.cells.duplicate()
	var ripples := water.material as ShaderMaterial
	var before := water.elapsed
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	t.check(water.elapsed > before and water.cells == cells,
			"ripple time advances without repainting any ground cell")
	t.check(float(ripples.get_shader_parameter("elapsed")) == water.elapsed,
			"the shader's clock is the surface's")
	water.configure(cells)
	t.check(water.material != ripples
			and (water.material as ShaderMaterial).shader == SceneryWater.RIPPLE_SHADER,
			"repeated configure keeps the shared shader while refreshing instance uniforms")
	# A surface of its own, handed no library, makes one when it enters the tree.
	# Watched from here, so the only lines about the `ground` page are the ones its own library writes.
	var pages := PageLog.new()
	var other := SceneryWater.new()
	city.scenery_ground.add_child(other)
	other.configure(cells.slice(0, 1))
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	t.check(other.material != water.material
			and (other.material as ShaderMaterial).shader
			== (water.material as ShaderMaterial).shader,
			"two water surfaces share the shader but keep independent materials")
	t.check(other.elapsed > 0.0 and other.elapsed < water.elapsed
			and float((other.material as ShaderMaterial).get_shader_parameter("elapsed"))
			== other.elapsed,
			"two water surfaces keep independent animation clocks")
	t.check(pages.held(&"ground"), "a surface holds the ground page while it stands")
	var owner := other.get_parent()
	owner.remove_child(other)
	t.check(other.material == null and not pages.held(&"ground"),
			"detaching water releases its atlas region and shader material")
	var kept := other.elapsed
	owner.add_child(other)
	t.check(pages.held(&"ground") and other.elapsed >= kept
			and (other.material as ShaderMaterial).shader == SceneryWater.RIPPLE_SHADER,
			"reentry rebinds the region and shared shader without resetting its clock")
	other.free()
	pages.stop()
	owner = water.get_parent()
	owner.remove_child(water)
	t.check(water.material == null, "detaching a city's water releases its shader material")
	owner.add_child(water)
	t.check(water.elapsed > 0.0 and (water.material as ShaderMaterial).shader == SceneryWater.RIPPLE_SHADER,
			"reentry rebinds the shared shader without resetting its clock")
	# The escape's route tint repaints every resident chunk, shore included, as the game does.
	city.tint_the_route(null)
	t.check(not is_instance_valid(water), "repaint releases the prior water and material")
	for tile: Vector2i in expected:
		t.check(GroundWater.at(city.scenery_ground, tile), "repaint preserves the shoreline and bridge gap")
	city.free()
