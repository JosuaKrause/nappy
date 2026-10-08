extends Node2D
## Controlled diagonal routes through production EventInstance movement and drawing.
## Each carrier follows its rider to keep the small animation visible at normal 2x camera scale.

var _riders: Array[EventInstance] = []
var _carriers: Array[Node2D] = []
var _frames: Array[Dictionary] = []
var _started := 0
var _capturing := false
var _finished := false
var _output := OS.get_environment("PELICAN_CAPTURE_OUTPUT")

func _ready() -> void:
	assert("--no-save" in OS.get_cmdline_user_args())
	assert(not _output.is_empty())
	assert(DirAccess.make_dir_recursive_absolute(_output) == OK)
	if not AutoScreenshot.can_photograph(DisplayServer.get_name()):
		push_error("Pelican runtime fixture requires a display")
		get_tree().quit(1)
		return
	get_window().size = Vector2i(940, 240)
	get_window().content_scale_size = Vector2i(940, 240)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	AtlasLibrary.acquire(&"events")
	var headings: Array[Vector2] = [Vector2(1, -1), Vector2(1, 1), Vector2.RIGHT, Vector2(-1, -1), Vector2(-1, 1), Vector2.LEFT]
	for heading: Vector2 in headings:
		var carrier := Node2D.new()
		carrier.scale = Vector2.ONE * 2.0
		add_child(carrier)
		var rider := EventInstance.new()
		var route := PackedVector2Array([Vector2.ZERO, heading.normalized() * 3000.0])
		rider.setup(EventCatalogue.by_id("cyclist"), Vector2.ZERO, route, heading.normalized())
		rider.is_pelican = true
		carrier.add_child(rider)
		_riders.append(rider)
		_carriers.append(carrier)
	_started = Time.get_ticks_usec()

func _process(_delta: float) -> void:
	if _finished:
		return
	for index: int in range(_riders.size()):
		_carriers[index].position = Vector2(90 + index * 150, 175) - _riders[index].position * 2.0
	var elapsed := float(Time.get_ticks_usec() - _started) / 1000000.0
	if elapsed > 12.0:
		push_error("Pelican runtime fixture exceeded its deadline")
		get_tree().quit(1)
	elif elapsed >= 2.0 and not _capturing:
		if _frames.size() >= 36:
			_finish(elapsed - 2.0)
		elif elapsed - 2.0 >= float(_frames.size()) / 12.0:
			_capture()

func _capture() -> void:
	_capturing = true
	await AutoScreenshot.drawn_frame(get_tree())
	var elapsed := float(Time.get_ticks_usec() - _started) / 1000000.0 - 2.0
	var filename := "frame-%03d.png" % _frames.size()
	assert(get_viewport().get_texture().get_image().save_png(_output.path_join(filename)) == OK)
	var phases: Array[bool] = []
	for rider: EventInstance in _riders:
		phases.append(rider._gait_stepping())
	_frames.append({"file": filename, "elapsed_seconds": elapsed, "pedal_b": phases})
	_capturing = false

func _finish(duration: float) -> void:
	_finished = true
	var metadata := {"schema_version": 1, "frames": _frames, "duration_seconds": duration,
		"target_fps": 12, "status": "complete", "reason": "frame_cap",
		"context": "Controlled routes; real EventInstance process and drawing; 2x normal camera scale; carriers follow riders. NE, SE, E, NW, SW, W.",
		"engine": Engine.get_version_info(), "arguments": Array(OS.get_cmdline_args())}
	var file := FileAccess.open(_output.path_join("burst.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "  ") + "\n")
	file.close()
	print("PELICAN_RUNTIME frames=", _frames.size(), " duration=", duration)
	get_tree().quit()

func _exit_tree() -> void:
	AtlasLibrary.release(&"events")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 940, 240), Color("96928a"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(18, 25), "Pelican legs: production rider fixture, normal 2x camera scale", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("221f28"))
	var labels: Array[String] = ["NE", "SE", "E", "NW", "SW", "W"]
	for index: int in range(labels.size()):
		draw_string(font, Vector2(78 + index * 150, 205), labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("221f28"))
