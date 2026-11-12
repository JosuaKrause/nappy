extends Node2D
## Bounded runtime fixture: production drawing nodes, enlarged for review, with real draw counters.

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")

var _started := 0
var _frames: Array = []
var _counts := {}
var _capturing := false
var _finishing := true
var _recording := false
var _fixtures: Node2D
var _building: Building
## What the fixture's roof was told to stand: the drawer is handed to the building as the city hands
## its own, and stands each unit for real.
var _roof := RecordingRoofDrawer.new()
var _water: SceneryWater
var _events: Array[EventInstance] = []
var _output := OS.get_environment("SCENERY_CAPTURE_OUTPUT")
## The library the fixture's events draw from, holding their page as a manager would.
var _atlas := AtlasLibrary.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(not _output.is_empty() and "--no-save" in OS.get_cmdline_user_args())
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	_atlas.acquire(&"events")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	_fixtures = Node2D.new()
	_fixtures.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_fixtures)
	_roof.real = RoofDrawer.new(_atlas)
	_building = Building.new()
	_building.equip(_atlas, _roof, FrontDrawer.new(_atlas))
	_building.footprint = Vector2(192, 192)
	_building.height = 64
	_building.district = GameEnums.BlockPurpose.INDUSTRIAL
	_building.position = Vector2(205, 438)
	_building.scale = Vector2.ONE * 1.7
	_fixtures.add_child(_building)
	# Equipped as the city equips it, the building waits for the residency, which stands a building
	# in view up.
	_building.residence().set_resident(true)
	for variant in 200:
		if not _rotors().is_empty():
			break
		_building.variant = variant + 1
	assert(not _rotors().is_empty())
	_watch(_building, "building_static")
	for entry in _roof.standing():
		_watch(entry.object, "roof_static")
	for layer in _rotors():
		_watch(layer, "roof_rotor")
	_event("burst_water_main", false, Vector2(670, 235), 2.0)
	_event("car_accident", false, Vector2(670, 410), 2.0)
	_event("burst_water_main", true, Vector2(1000, 380), 1.6)
	_event("car_accident", true, Vector2(1160, 380), 1.6)
	_watch_the_events()
	_water = SceneryWater.new()
	_water.position = Vector2(40, 495)
	_water.scale = Vector2.ONE * 1.3
	_fixtures.add_child(_water)
	var cells: Array[Vector2i] = []
	for y in 4:
		for x in 8:
			cells.append(Vector2i(x, y))
	_water.configure(cells)
	_watch(_water, "water_surface")
	if DisplayServer.get_name() == "headless":
		print("Fixture construction passed; drawing requires a display")
		get_tree().quit()
		return
	_started = Time.get_ticks_usec()
	_finishing = false

func _exit_tree() -> void:
	if _fixtures != null:
		_atlas.release(&"events")

## The turning rotor of every vent the building was told to stand.
func _rotors() -> Array[SceneryLayer]:
	var rotors: Array[SceneryLayer] = []
	for entry in _roof.standing():
		var object: Building.RoofObject = entry.object
		if object.rotor != null:
			rotors.append(object.rotor)
	return rotors

func _event(id: String, vertical: bool, at: Vector2, factor: float) -> void:
	var event := EventInstance.new()
	event.atlas = _atlas
	event.setup(EventCatalogue.by_id(id), at, PackedVector2Array(), Vector2.RIGHT,
			EastWestStreet.new() if vertical else WorldMap.open_ground())
	event.scale = Vector2.ONE * factor
	_fixtures.add_child(event)
	_events.append(event)
	_watch(event, id + "_owner")

## Watches every scenery layer of the events, by kind: the scene is drawn in slices beside each
## event, each with its part's scenery, and the slices go into the world on the idle frame after the
## event is made, so this waits a frame and a drawn frame for them before it looks.
func _watch_the_events() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for event in _events:
		var id := event.row_id()
		for slice in (event.look as SpreadLook).slices():
			for scenery in slice.get_children():
				if not scenery is EventScenery:
					continue
				var split: Array = await _split_by_animation(event, scenery as EventScenery)
				for layer: SceneryLayer in split[1]:
					_watch(layer, id + "_static")
				for layer: SceneryLayer in split[0]:
					_watch(layer, id + "_motion")

## The layers `scenery` holds as `[moving, still]`: the moving ones are the layers its
## `set_frame()` draws again when it turns them, counted off each layer's `draw` signal; the still
## ones the rest. `event`'s own process frame, which shows its clock's frame, is held meanwhile, and
## its next one puts its frame back.
func _split_by_animation(event: EventInstance, scenery: EventScenery) -> Array:
	var layers: Array[SceneryLayer] = []
	for child in scenery.get_children():
		if child is SceneryLayer:
			layers.append(child)
	event.set_process(false)
	scenery.set_frame(true)
	await get_tree().process_frame
	var drawn := {}
	var counters := {}
	for layer in layers:
		drawn[layer] = 0
		counters[layer] = func() -> void: drawn[layer] += 1
		layer.draw.connect(counters[layer])
	scenery.set_frame(false)
	await get_tree().process_frame
	for layer in layers:
		layer.draw.disconnect(counters[layer])
	event.set_process(true)
	var moving: Array[SceneryLayer] = []
	moving.assign(layers.filter(func(l: SceneryLayer) -> bool: return drawn[l] > 0))
	var still: Array[SceneryLayer] = []
	still.assign(layers.filter(func(l: SceneryLayer) -> bool: return not moving.has(l)))
	return [moving, still]

func _watch(item: CanvasItem, key: String) -> void:
	_counts[key] = 0
	item.draw.connect(func() -> void:
		if _recording:
			_counts[key] += 1)

func _process(_delta: float) -> void:
	if _finishing:
		return
	var elapsed := float(Time.get_ticks_usec() - _started) / 1000000.0
	if elapsed > 12.0:
		push_error("runtime capture exceeded its deadline")
		get_tree().quit(1)
		return
	if elapsed < 2.0 or _capturing:
		return
	_recording = true
	if _frames.size() >= 36:
		_finishing = true
		_finish(elapsed - 2.0)
	elif elapsed - 2.0 >= float(_frames.size()) / 12.0:
		_capture()

func _capture() -> void:
	_capturing = true
	await DrawnFrame.wait(get_tree())
	var elapsed := float(Time.get_ticks_usec() - _started) / 1000000.0 - 2.0
	var filename := "frame-%03d.png" % _frames.size()
	assert(get_viewport().get_texture().get_image().save_png(_output.path_join(filename)) == OK)
	_frames.append({"file": filename, "elapsed_seconds": elapsed})
	_capturing = false

func _finish(duration: float) -> void:
	_recording = false
	var before := [_building._vent_timer, _ripple_clock(), _events[0].clock()]
	get_tree().paused = true
	await get_tree().create_timer(0.25, true).timeout
	var paused := [_building._vent_timer, _ripple_clock(), _events[0].clock()]
	get_tree().paused = false
	await get_tree().create_timer(0.15, true).timeout
	var resumed := [_building._vent_timer, _ripple_clock(), _events[0].clock()]
	var static_held := true
	for key: String in _counts:
		if key.ends_with("static") or key.ends_with("owner") or key == "water_surface":
			static_held = static_held and _counts[key] == 0
	var animated: bool = _counts.roof_rotor > 0 and _counts.burst_water_main_motion > 0 \
			and _counts.car_accident_motion > 0
	var metadata := {"schema_version": 1, "frames": _frames, "duration_seconds": duration,
		"target_fps": 12, "status": "complete", "reason": "frame_cap",
		"context": "Synthetic layout of production nodes; roof 1.7x, horizontal scenes 2x, vertical 1.6x, water 1.3x",
		"draw_counts": _counts, "static_held": static_held, "animated": animated,
		"paused_clocks_held": before == paused, "resumed_clocks": resumed,
		"engine": Engine.get_version_info(), "arguments": Array(OS.get_cmdline_args())}
	var file := FileAccess.open(_output.path_join("burst.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "  ") + "\n")
	file.close()
	print("SCENERY_RUNTIME " + JSON.stringify(metadata.duplicate().merged({"frames": _frames.size()}, true)))
	get_tree().quit(0 if static_held and animated and before == paused and resumed != paused else 1)

## Where the water's ripples are in their animation: the clock its shader is drawing with.
func _ripple_clock() -> float:
	return float((_water.material as ShaderMaterial).get_shader_parameter("elapsed"))

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("292f35"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(30, 35), "SCENERY ANIMATION — production-node fixture (enlarged)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25)
	for label: Array in [[Vector2(40, 80), "Roof vent · 1.7x"],
			[Vector2(475, 110), "Broken pipe · 2x"], [Vector2(475, 305), "Crash smoke · 2x"],
			[Vector2(935, 150), "Both vertical views · 1.6x"],
			[Vector2(40, 478), "Approved shoreline ripple · 1.3x"],
			[Vector2(475, 610), "Only small details change their drawing."],
			[Vector2(475, 642), "Source artwork, timing and body geometry retained."]]:
		draw_string(font, label[0], label[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 19)
