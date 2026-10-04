extends Node
## Bounded quadrant/row/atomic comparison and real-process-frame residency coverage.
## Run its scene with --no-save --no-telemetry; GROUND_FRAMES_OUTPUT is a fresh JSON path.
## Coverage runs in the ground mode --ground-mode names (2 when absent): mode 2 fails on any frame
## that prepares a second region outside the guard, and mode 3 on stepping that never spans frames.

const CITY: PackedScene = preload("res://scenes/world/city.tscn")
var _city: City
var _failures: Array[String] = []
var _started := 0
var _rendered := false
var _forced_draws := 0

func _ready() -> void:
	_started = Time.get_ticks_msec()
	_rendered = DisplayServer.get_name() != "headless"
	if not "--no-save" in OS.get_cmdline_user_args() \
			or OS.get_environment("GROUND_FRAMES_OUTPUT").is_empty():
		push_error("ground_frames requires --no-save and GROUND_FRAMES_OUTPUT")
		get_tree().quit(1)
		return
	if _rendered:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	call_deferred("_run")

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _started > 120000:
		push_error("ground_frames exceeded its two-minute deadline")
		get_tree().quit(1)

func _run() -> void:
	GameState.start_run(4242)
	_city = CITY.instantiate()
	add_child(_city)
	_city.build(CityGenerator.generate(4242))
	_city.scenery.set_process(false)
	_city.hide()
	var trials: Array[Dictionary] = []
	var facing_only := OS.get_environment("GROUND_FRAMES_FACING_ONLY") == "1"
	var modes: Array[String] = ["atomic", "rows", "quadrants"]
	if facing_only:
		modes.clear()
	# Warm each strategy once, then retain every trial in this fixed interleaved order.
	for mode in modes:
		await _comparison(mode, true)
	for trial in 3:
		for mode in modes:
			var result := await _comparison(mode, false)
			result.trial = trial
			trials.append(result)
	if _rendered and not trials.is_empty():
		for trial in trials:
			if trial.pixel_sha256 != trials[0].pixel_sha256:
				_failures.append("completed pixels differ between preparation strategies")
	_city.show()
	var coverage: Array[Dictionary] = []
	if facing_only:
		coverage.append(await _coverage(60, Vector2.RIGHT, true))
	else:
		for rate in [15, 30, 60]:
			for direction: Vector2 in [Vector2.DOWN, Vector2.RIGHT, Vector2.ONE.normalized()]:
				coverage.append(await _coverage(rate, direction))
	var result := {"engine": Engine.get_version_info(), "processor": OS.get_processor_name(),
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_driver_name(),
		"viewport_size": str(get_viewport().get_visible_rect().size), "forced_draws": _forced_draws,
		"trials": trials, "coverage": coverage, "failures": _failures,
		"source_sha256": _hashes(), "elapsed_ms": Time.get_ticks_msec() - _started}
	var output := FileAccess.open(OS.get_environment("GROUND_FRAMES_OUTPUT"), FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "  ") + "\n")
	output.close()
	_city.free()
	print("GROUND_FRAMES " + JSON.stringify(result))
	get_tree().quit(int(not _failures.is_empty()))

func _comparison(mode: String, warmup: bool) -> Dictionary:
	var owner := Node2D.new()
	add_child(owner)
	var layers: Array[TileMapLayer] = []
	var preparation: Array[int] = []
	var submission: Array[int] = []
	var frames: Array[int] = []
	var draws: Array[int] = []
	var draw_calls: Array[int] = []
	var cells := 0
	var water_surfaces := 0
	var before := OS.get_static_memory_usage()
	# Four ordinary chunks and four shoreline chunks, all selected from current map state.
	var shore_y := ceili(float(_city.map.size.y) / SceneryGround.CHUNK_TILES)
	var keys: Array[Vector2i] = []
	for x in 4:
		keys.append(Vector2i(x + 1, 2))
		keys.append(Vector2i(x + 1, shore_y))
	# Prepare off screen. A hidden owner would skip the engine rendering work being measured.
	get_viewport().canvas_transform = Transform2D(0, Vector2(10000, 10000))
	for key in keys:
		var layer := TileMapLayer.new()
		layer.tile_set = _city._ground.tile_set
		layer.rendering_quadrant_size = 4 if mode == "quadrants" else 16
		owner.add_child(layer)
		layers.append(layer)
		var steps := 4 if mode == "quadrants" else (8 if mode == "rows" else 1)
		for step in steps:
			await get_tree().process_frame
			var started := Time.get_ticks_usec()
			var origin := key * 8
			var size := Vector2i(8, 8)
			if mode == "quadrants":
				origin += Vector2i(step % 2, step / 2) * 4
				size = Vector2i(4, 4)
			elif mode == "rows":
				origin.y += step
				size.y = 1
			var water: Array[Vector2i] = []
			for y in range(origin.y, origin.y + size.y):
				for x in range(origin.x, origin.x + size.x):
					var tile := Vector2i(x, y)
					var source := _city.scenery_ground_source(tile)
					if source == GroundTiles.WATER:
						water.append(tile)
					elif source >= 0:
						layer.set_cell(tile, source, GroundLayers.atlas_coords_for(source,
								_city.map.seed_used, tile, layer.tile_set))
					cells += int(source >= 0)
			if not water.is_empty():
				var surface := SceneryWater.new()
				layer.add_child(surface)
				surface.configure(water)
				surface.set_process(false)
				water_surfaces += 1
			var submitted := Time.get_ticks_usec()
			layer.update_internals()
			submission.append(Time.get_ticks_usec() - submitted)
			preparation.append(Time.get_ticks_usec() - started)
			await _draw_frame()
			frames.append(Time.get_ticks_usec() - started)
	var allocated := OS.get_static_memory_usage() - before
	var pixel_hashes: Array[String] = []
	# Completed ground and water in view: fixed clock, identical viewport, compare final pixels.
	for key in [keys[0], keys[1]]:
		get_viewport().canvas_transform = Transform2D(0, -Vector2(key * 8 * Tuning.TILE_SIZE))
		await _draw_frame()
		if _rendered and not warmup:
			var context := HashingContext.new()
			context.start(HashingContext.HASH_SHA256)
			context.update(get_viewport().get_texture().get_image().get_data())
			pixel_hashes.append(context.finish().hex_encode())
		for frame in 20:
			await get_tree().process_frame
			var started := Time.get_ticks_usec()
			await _draw_frame()
			draws.append(Time.get_ticks_usec() - started)
			draw_calls.append(RenderingServer.get_rendering_info(
					RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	var result := {"mode": mode, "cells": cells, "water_surfaces": water_surfaces,
		"prepare_usec": _distribution(preparation), "renderer_submit_usec": _distribution(submission),
		"step_through_draw_usec": _distribution(frames), "steady_through_draw_usec": _distribution(draws),
		"tracked_allocation_bytes": allocated, "steady_draw_calls": _distribution(draw_calls),
		"pixel_sha256": pixel_hashes}
	owner.free()
	await get_tree().process_frame
	return result

func _coverage(rate: int, direction: Vector2, reverse_look_ahead := false) -> Dictionary:
	var ground := _city._ground
	var at := _city.map.doorstep_world_position()
	var initial := at
	var extent := Tuning.VIEW_HALF_EXTENT * 2
	ground.clear()
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# This fixture moves the camera directly in process frames; interpolation would render
	# an older physics transform rather than the bounds whose coverage it is asserting.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.zoom = get_viewport().get_visible_rect().size / extent
	add_child(camera)
	camera.position = at
	camera.force_update_scroll()
	_city.scenery.update(Rect2(at - extent / 2, extent), true)
	ground.worst_step_usec = 0
	var started := ground.prepared
	var catchups := _city.scenery.ordinary_guard_preparations
	var misses := 0
	var pending_frames := 0
	var updates: Array[int] = []
	var frames: Array[int] = []
	var pending_owners := {}
	var completed_across_frames := 0
	var most_ordinary_in_a_frame := 0
	var ordinary_beside_guard := 0
	# Two running-speed legs with a facing reversal. This is a camera stress itinerary, not
	# a playable/survival route. Engine frames really advance, unlike synchronous test models.
	var total_frames := rate * 30
	for frame in total_frames:
		await get_tree().process_frame
		at += direction * (168.0 / rate) * (1 if frame < total_frames / 2 else -1)
		var view := Rect2(at - extent / 2, extent)
		if reverse_look_ahead and frame >= total_frames / 2:
			view.position -= direction * 92
		# Taken outside the timed span, like the classification after the draw below.
		var resident_before := ground.chunks.duplicate()
		var relocating := _city.scenery.view.get_center().distance_to(view.get_center()) \
				> SceneryResidency.GUARD_MARGIN
		var tick := Time.get_ticks_usec()
		camera.position = view.get_center()
		camera.force_update_scroll()
		var actual := _city.scenery.camera_view()
		if not actual.is_equal_approx(view):
			_failures.append("rendered viewport and checked camera view differ")
			break
		if _city.scenery._pending or view.size != _city.scenery.view.size \
				or view.get_center().distance_to(_city.scenery.view.get_center()) >= 16:
			_city.scenery.update(view)
		updates.append(Time.get_ticks_usec() - tick)
		for key: Vector2i in ground.pending:
			if not pending_owners.has(key):
				pending_owners[key] = frame
			pending_frames += 1
		for key: Vector2i in pending_owners.keys():
			if ground.chunks.has(key):
				completed_across_frames += int(frame > pending_owners[key])
				pending_owners.erase(key)
		for key in ground.keys_in(view):
			misses += int(not ground.chunks.has(key))
		await _draw_frame()
		frames.append(Time.get_ticks_usec() - tick)
		# The guard's own regions are the new ones its rectangle reaches; the guard counter
		# also counts buildings and decals, so it cannot tell ground apart. A relocation
		# prepares its whole destination at once in every mode, so it is not counted.
		var guarded := 0
		var ordinary := 0
		var guard := _city.scenery.view.grow(SceneryResidency.GUARD_MARGIN)
		for key: Vector2i in ground.chunks:
			if not relocating and not resident_before.has(key):
				if guard.intersects(SceneryGround.bounds(key)):
					guarded += 1
				else:
					ordinary += 1
		most_ordinary_in_a_frame = maxi(most_ordinary_in_a_frame, ordinary)
		ordinary_beside_guard += int(guarded > 0 and ordinary > 0)
	if misses:
		_failures.append("coverage gaps")
	if ground.mode == SceneryGround.Mode.STEPPED and completed_across_frames == 0:
		_failures.append("no real-frame stepped completions")
	if ground.mode == SceneryGround.Mode.ONE \
			and (most_ordinary_in_a_frame > 1 or ordinary_beside_guard > 0):
		_failures.append("mode 2 prepared a second region in one frame outside the guard")
	camera.free()
	return {"ground_mode": ground.mode, "modeled_hz": rate, "direction": str(direction),
		"look_ahead_reversal_px": 92 if reverse_look_ahead else 0,
		"frames": frames.size(), "missing_regions": misses,
		"pending_frame_observations": pending_frames, "completed_across_frames": completed_across_frames,
		"prepared_regions": ground.prepared - started,
		"guard_catchups": _city.scenery.ordinary_guard_preparations - catchups,
		"most_ordinary_regions_in_a_frame": most_ordinary_in_a_frame,
		"frames_with_ordinary_beside_guard": ordinary_beside_guard,
		"end_distance_from_start": at.distance_to(initial),
		"update_usec": _distribution(updates), "through_draw_usec": _distribution(frames),
		"worst_ground_step_usec": ground.worst_step_usec}

func _draw_frame() -> void:
	if _rendered:
		_forced_draws += int(await AutoScreenshot.drawn_frame(get_tree()))
	else:
		await get_tree().process_frame

func _distribution(values: Array[int]) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	values.sort()
	var sum := 0
	for value in values:
		sum += value
	return {"count": values.size(), "sum": sum, "median": values[values.size() / 2],
		"p95": values[mini(values.size() - 1, ceili(values.size() * 0.95) - 1)],
		"max": values[-1]}

func _hashes() -> Dictionary:
	var hashes := {}
	for path in ["src/city/scenery_ground.gd", "src/city/scenery_residency.gd",
			"src/city/city.gd", "src/city/scenery_water.gd", "tests/probes/ground_frames.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	return hashes
