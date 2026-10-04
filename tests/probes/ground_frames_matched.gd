extends Node
## Common rendered-city collector for the three ground modes of one clean runtime checkout; the
## mode is the launch's own --ground-mode. Timing starts at process_frame and ends at
## frame_post_draw, before observation work. Run through tools/measure-ground-frames.sh; this
## excludes Main, crowds and events.

signal sampled(row: Dictionary)
const CITY: PackedScene = preload("res://scenes/world/city.tscn")
const EXTENT := Vector2(640, 360)
var _city: City
var _camera: Camera2D
var _request: Dictionary = {}
var _begin := 0
var _queue_usec := 0
var _executed := false
var _started := 0
var _forced := 0
var _failures: Array[String] = []
var _before: Dictionary = {}
var _stepped := false
var _city_mode := 0

func _ready() -> void:
	_started = Time.get_ticks_msec()
	process_priority = 10000
	if not "--no-save" in OS.get_cmdline_user_args() \
			or OS.get_environment("GROUND_MATCH_OUTPUT").is_empty():
		push_error("matched collector requires --no-save and GROUND_MATCH_OUTPUT")
		get_tree().quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("matched rendered timing requires a display server")
		get_tree().quit(1)
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	get_tree().process_frame.connect(_start_frame)
	RenderingServer.frame_post_draw.connect(_finish_frame)
	call_deferred("_run")

func _start_frame() -> void:
	if _request.is_empty() or _executed:
		return
	_begin = Time.get_ticks_usec()
	_city._ground._process(float(_request.delta))
	# Roof animation shares the modeled clock too; actual uncapped FPS must not change
	# frame selection or redraw cadence between strategies. Keep its work inside the span.
	for item in _city.scenery._items:
		if item is Building:
			item.set_process(false)
			if item.scenery_resident and item._has_vent:
				item._process(float(_request.delta))

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _started > 120000:
		push_error("matched collector exceeded two-minute deadline")
		get_tree().quit(1)
	if _request.is_empty() or _executed or _begin == 0:
		return
	var view: Rect2 = _request.view
	_camera.position = view.get_center()
	_camera.force_update_scroll()
	var tick := Time.get_ticks_usec()
	if _request.queue and (_city.scenery._pending or view.size != _city.scenery.view.size \
			or view.get_center().distance_to(_city.scenery.view.get_center()) >= 16):
		_city.scenery.update(view)
	_queue_usec = Time.get_ticks_usec() - tick
	_executed = true
	call_deferred("_draw_if_occluded")

func _draw_if_occluded() -> void:
	# Deferred TileMap notifications precede this fallback; never finish before _process.
	if _executed and not DisplayServer.window_can_draw():
		_forced += 1
		RenderingServer.force_draw(false)

func _finish_frame() -> void:
	if not _executed:
		return
	var ended := Time.get_ticks_usec()
	var ground := _city._ground
	var gaps := 0
	if not _city.scenery.camera_view().is_equal_approx(_request.view):
		_failures.append("camera geometry differs from coverage geometry")
	for key in ground.keys_in(_request.view):
		gaps += int(not ground.chunks.has(key))
	var after := _snapshot()
	var sections := 0
	var canceled := 0
	for key: Vector2i in after.pending:
		sections += int(after.pending[key]) - int(_before.pending.get(key, 0))
	var guard := _city.scenery.view.grow(SceneryResidency.GUARD_MARGIN)
	var ordinary := 0
	var guarded := 0
	for key: Vector2i in after.chunks:
		if after.chunks[key] != _before.chunks.get(key, 0):
			sections += (4 if _stepped else 1) - int(_before.pending.get(key, 0))
			if guard.intersects(SceneryGround.bounds(key)):
				guarded += 1
			else:
				ordinary += 1
	# Mode 2's promise, checked on every real frame: one ordinary region at most, none beside
	# the guard. The traversal moves under the relocation distance, so no frame relocates.
	if _city_mode == SceneryGround.Mode.ONE and (ordinary > 1 or (ordinary > 0 and guarded > 0)):
		_failures.append("mode 2 prepared a second region in one frame outside the guard")
	for key: Vector2i in _before.pending:
		canceled += int(not after.pending.has(key) and not after.chunks.has(key))
	var row := {"span_usec": ended - _begin, "queue_usec": _queue_usec,
		"regions": ground.prepared - int(_before.prepared),
		"guards": _city.scenery.ordinary_guard_preparations - int(_before.guards),
		"evictions": ground.evicted - int(_before.evicted), "gaps": gaps,
		"observed_sections": sections, "canceled_pending": canceled,
		"pending": after.pending.size(), "resident": after.chunks.size(),
		"draw_calls": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)}
	_before = after
	row.observer_usec = Time.get_ticks_usec() - ended
	_request = {}
	_executed = false
	_begin = 0
	sampled.emit(row)

func _sample(view: Rect2, delta: float, queue := true) -> Dictionary:
	_request = {"view": view, "delta": delta, "queue": queue}
	return await sampled

func _snapshot() -> Dictionary:
	var pending := {}
	if _stepped:
		var jobs: Dictionary = _city._ground.get("pending")
		for key: Vector2i in jobs:
			pending[key] = jobs[key].step
	var chunks := {}
	for key: Vector2i in _city._ground.chunks:
		chunks[key] = _city._ground.chunks[key].get_instance_id()
	return {"pending": pending, "chunks": chunks, "prepared": _city._ground.prepared,
		"guards": _city.scenery.ordinary_guard_preparations, "evicted": _city._ground.evicted}

func _run() -> void:
	var cases: Array[Dictionary] = []
	for spec: Array in [["south60", 60, Vector2.DOWN], ["south15", 15, Vector2.DOWN],
			["diagonal15", 15, Vector2.ONE.normalized()]]:
		GameState.start_run(4242)
		_city = CITY.instantiate()
		add_child(_city)
		_city.build(CityGenerator.generate(4242))
		_city.scenery.set_process(false)
		_city._ground.set_process(false)
		_city._ground.elapsed = 0
		_city_mode = _city._ground.mode
		_stepped = _city._ground.mode == SceneryGround.Mode.STEPPED
		_camera = Camera2D.new()
		_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		_camera.zoom = get_viewport().get_visible_rect().size / EXTENT
		add_child(_camera)
		var at := _city.map.doorstep_world_position()
		var initial := at
		_camera.position = at
		_camera.force_update_scroll()
		_city.scenery.update(Rect2(at - EXTENT / 2, EXTENT), true)
		_before = _snapshot()
		for frame in 120:
			await _sample(Rect2(at - EXTENT / 2, EXTENT), 0)
		var rows: Array[Dictionary] = []
		var rate: int = spec[1]
		var direction: Vector2 = spec[2]
		for frame in rate * 30:
			at += direction * (168.0 / rate) * (1 if frame < rate * 15 else -1)
			rows.append(await _sample(Rect2(at - EXTENT / 2, EXTENT), 1.0 / rate))
		var result := _summarize(rows)
		result.name = spec[0]
		result.modeled_hz = rate
		result.start = str(initial)
		result.world_size = str(_city.map.world_size())
		result.end_distance = at.distance_to(initial)
		_write_rows(str(spec[0]), rows)
		# All strategies settle the same shoreline view for water/quad overhead comparison.
		at = Vector2(_city.map.world_size().x / 2, _city.map.world_size().y)
		_city._ground.clear()
		_city._ground.elapsed = 0
		_camera.position = at
		_camera.force_update_scroll()
		var steady_view := Rect2(at - EXTENT / 2, EXTENT)
		_city.scenery.update(steady_view, true)
		_before = _snapshot()
		for frame in 120:
			await _sample(steady_view, 0)
		rows.clear()
		for frame in 240:
			rows.append(await _sample(steady_view, 0, false))
		result.steady = _summarize(rows)
		result.steady_workload = _workload()
		_write_rows(str(spec[0]) + "-steady", rows)
		# Image readback and hashing are outside every timed sample.
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(get_viewport().get_texture().get_image().get_data())
		result.steady_pixel_sha256 = context.finish().hex_encode()
		rows.clear()
		var allocated := OS.get_static_memory_usage()
		_city._ground.clear()
		await get_tree().process_frame
		await get_tree().process_frame
		result.ground_release_static_bytes = allocated - OS.get_static_memory_usage()
		cases.append(result)
		_camera.free()
		_city.free()
		await get_tree().process_frame
	var result := {"cases": cases, "failures": _failures, "forced_draws": _forced,
		"engine": Engine.get_version_info(), "processor": OS.get_processor_name(),
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_driver_name(),
		"viewport": str(get_viewport().get_visible_rect().size), "extent": str(EXTENT),
		"ground_mode": _city_mode, "seed": 4242, "warmup_frames": 120, "traversal_seconds": 30,
		"steady_frames": 240, "vsync_disabled": true, "elapsed_ms": Time.get_ticks_msec() - _started,
		"collector_sha256": FileAccess.get_sha256("res://tests/probes/ground_frames_matched.gd")}
	for key in ["STRATEGY", "TRIAL", "RUN_ORDER", "SOURCE_REVISION", "COLLECTOR_REVISION", "RUNTIME_DIGEST"]:
		result[key.to_lower()] = OS.get_environment("GROUND_MATCH_" + key)
	var output := FileAccess.open(OS.get_environment("GROUND_MATCH_OUTPUT"), FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "  ") + "\n")
	output.close()
	print("GROUND_MATCH complete " + OS.get_environment("GROUND_MATCH_STRATEGY"))
	get_tree().quit(int(not _failures.is_empty()))

func _workload() -> Dictionary:
	var records: Array[String] = []
	var water_surfaces := 0
	var water_cells := 0
	for layer: TileMapLayer in _city._ground.chunks.values():
		for cell in layer.get_used_cells():
			records.append("%s:%s:%s" % [cell, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell)])
		for child in layer.get_children():
			if child is SceneryWater:
				water_surfaces += 1
				for cell: Vector2i in child.cells:
					water_cells += 1
					records.append("water:%s" % cell)
	records.sort()
	return {"regions": _city._ground.chunks.size(), "cells": records.size(),
		"water_cells": water_cells, "water_surfaces": water_surfaces,
		"cell_sha256": "\n".join(records).sha256_text()}

func _summarize(rows: Array[Dictionary]) -> Dictionary:
	var result := {}
	for key in rows[0]:
		var values: Array[int] = []
		for row in rows:
			values.append(int(row[key]))
		values.sort()
		var sum := 0
		var over16 := 0
		var over33 := 0
		var over66 := 0
		for value in values:
			sum += value
			over16 += int(value > 16667)
			over33 += int(value > 33333)
			over66 += int(value > 66667)
		result[key] = {"count": values.size(), "sum": sum, "median": values[values.size() / 2],
			"p95": values[ceili(values.size() * 0.95) - 1],
			"p99": values[ceili(values.size() * 0.99) - 1], "max": values[-1]}
		if key.ends_with("usec"):
			result[key].over_16667 = over16
			result[key].over_33333 = over33
			result[key].over_66667 = over66
	if result.gaps.sum > 0 or (result.regions.sum == 0 and rows.size() != 240):
		_failures.append("coverage gap or traversal without preparation")
	return result

func _write_rows(label: String, rows: Array[Dictionary]) -> void:
	var output := FileAccess.open(OS.get_environment("GROUND_MATCH_OUTPUT") + "." + label + ".csv", FileAccess.WRITE)
	var keys := rows[0].keys()
	output.store_csv_line(PackedStringArray(keys))
	for row in rows:
		var values := PackedStringArray()
		for key in keys:
			values.append(str(row[key]))
		output.store_csv_line(values)
	output.close()
