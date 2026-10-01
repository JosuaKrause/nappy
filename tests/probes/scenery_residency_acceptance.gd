extends RefCounted
## Bounded native acceptance on production daily route positions. This advances the camera
## model, not physics or rendered frames; the separate walking capture supplies that evidence.

func run(t) -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	var started := Time.get_ticks_usec()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	var boot_usec := Time.get_ticks_usec() - started
	var city: City = main._city
	var ground := city._ground
	var tree := city.route_tree()
	var home_cells := ground.get_used_cells().size()
	var home_chunks := ground.chunks.size()
	var home_buildings := 0
	for building in city.buildings():
		home_buildings += int(building.scenery_resident)
	var route: Array = []
	var branch_index := 0
	for index in tree.branches.size():
		for option: Array in tree.branches[index].routes:
			if option.size() > route.size():
				route = option
				branch_index = index
	var positions: Array[Vector2] = []
	for cell: Vector2i in route:
		var candidates: Array[Vector2] = []
		for y in ReachabilityGrid.CELL:
			for x in ReachabilityGrid.CELL:
				var tile := cell * ReachabilityGrid.CELL + Vector2i(x, y)
				var node := tree.grid.node_at(tile)
				if city.map.is_open(tile) and tree._colours.get(node, []).has(branch_index):
					candidates.append(city.map.tile_to_world(tile))
		if not candidates.is_empty():
			positions.append(candidates[0])
	t.check(positions.size() > 8, "a production route supplies a nontrivial camera itinerary")
	positions.reverse()
	var forward := positions.duplicate()
	positions.append_array(forward.slice(0, forward.size() - 1).duplicate())
	# The second leg retraces the same offered option, not the union of all choices.
	for i in range(forward.size(), positions.size()):
		positions[i] = forward[forward.size() - 2 - (i - forward.size())]
	var at := positions[0]
	city.scenery.update(_view(at), true)
	var samples: Array[int] = []
	var misses := 0
	var max_chunks := ground.chunks.size()
	var travelled := 0.0
	var catchups_before := city.scenery.ordinary_guard_preparations
	var memory_start := OS.get_static_memory_usage()
	var max_memory := memory_start
	for destination in positions:
		while at.distance_to(destination) > 0.01:
			var next := at.move_toward(destination, 168.0 / 60.0)
			travelled += at.distance_to(next)
			at = next
			started = Time.get_ticks_usec()
			city.scenery.update(_view(at))
			samples.append(Time.get_ticks_usec() - started)
			misses += _missing(city, _view(at))
			max_chunks = maxi(max_chunks, ground.chunks.size())
			max_memory = maxi(max_memory, OS.get_static_memory_usage())
	var held: Array = ground.chunks.values()
	var memory_before_release := OS.get_static_memory_usage()
	city.scenery.update(Rect2(Vector2(-10000, -10000), Vector2(640, 360)), true)
	var memory_after_release := OS.get_static_memory_usage()
	var freed := 0
	for node in held:
		freed += int(not is_instance_valid(node))
	t.check(misses == 0, "every modeled running-speed viewport is fully prepared")
	t.check(freed == held.size() and ground.chunks.is_empty(), "eviction actually frees every ground node")
	t.check(city.scenery.ordinary_guard_preparations == catchups_before,
			"ordinary approach never reaches the synchronous safety guard unprepared")
	samples.sort()
	print("SCENERY_ACCEPTANCE " + JSON.stringify({"seed": city.map.seed_used,
		"day": GameState.day, "engine": Engine.get_version_info().string,
		"processor": OS.get_processor_name(), "mode": "synchronous modeled camera, no frames",
		"boot_main_usec": boot_usec, "home_cells": home_cells, "home_chunks": home_chunks,
		"home_buildings": home_buildings, "total_buildings": city.buildings().size(),
		"route_cells": route.size(), "route_positions": forward.size(), "distance_px": travelled,
		"samples": samples.size(), "median_usec": _percentile(samples, 0.5),
		"p95_usec": _percentile(samples, 0.95), "p99_usec": _percentile(samples, 0.99),
		"max_usec": samples[-1], "worst_ground_chunk_usec": ground.worst_prepare_usec,
		"max_resident_chunks": max_chunks, "prepared": ground.prepared, "evicted": ground.evicted,
		"guard_catchups": city.scenery.ordinary_guard_preparations - catchups_before,
		"missing": misses, "peak_tracked_delta_bytes": max_memory - memory_start,
		"release_tracked_delta_bytes": memory_before_release - memory_after_release,
		"freed_ground_nodes": freed}))
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()

func _view(at: Vector2) -> Rect2:
	# Covers maximum facing look-ahead in every direction, including a sudden reversal.
	return Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2).grow(
			Stroller.CAMERA_LOOK_AHEAD)

func _percentile(values: Array[int], fraction: float) -> int:
	return values[mini(values.size() - 1, floori(values.size() * fraction))]

func _missing(city: City, view: Rect2) -> int:
	var misses := 0
	for key in city._ground.keys_in(view):
		misses += int(not city._ground.chunks.has(key))
	for building in city.buildings():
		if view.intersects(building.scenery_bounds()) and not building.scenery_resident:
			misses += 1
	return misses
