extends RefCounted
## Synchronous headless preparation and geometric coverage experiment. No rendered-frame claims.
## Run with tools/test.sh probes/lazy_scenery_measure.gd; external timeout belongs to the caller.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const TIMED_CITY := preload("res://tests/probes/lazy_scenery_city.gd")
const SEEDS := [4242, 3265820891]
const HALF_VIEW := Vector2(320, 180)

func run(t) -> void:
	print("LAZY_META " + JSON.stringify({"engine": Engine.get_version_info(),
		"os": OS.get_name(), "processor": OS.get_processor_name(),
		"mode": "headless synchronous; no engine frame between stages"}))
	# Warm shared pages once, matching process residency rather than timing cold disk loads.
	var groups: Array[StringName] = [ &"buildings", &"street_kit", &"ground", &"decoration", &"events", &"crowd" ]
	for group in groups:
		AtlasLibrary.acquire(group)
		var size := AtlasLibrary.page_size(group)
		print("LAZY_ATLAS " + JSON.stringify({"group": group, "size": str(size),
			"rgba8_base_bytes": size.x * size.y * 4}))
	for trial in 3:
		for seed_value: int in SEEDS:
			_measure(t, seed_value, trial)
	for group in groups:
		AtlasLibrary.release(group)
	_actual_boot(t)

func _measure(t, seed_value: int, trial: int) -> void:
	GameState.start_run(seed_value)
	var started := Time.get_ticks_usec()
	var map := CityGenerator.generate(seed_value)
	var generation_ms := (Time.get_ticks_usec() - started) / 1000.0
	var city: City = CITY_SCENE.instantiate()
	city.set_script(TIMED_CITY)
	t.add_child(city)
	var memory_before := OS.get_static_memory_usage()
	started = Time.get_ticks_usec()
	city.build(map)
	var row: Dictionary = city.get("spans").duplicate()
	row.merge({"seed": seed_value, "trial": trial, "stage": "build",
		"generation_ms": generation_ms, "total_ms": (Time.get_ticks_usec() - started) / 1000.0,
		"static_memory_delta": OS.get_static_memory_usage() - memory_before,
		"nodes": _nodes(city), "buildings": city.buildings().size()})
	print("LAZY_STAGE " + JSON.stringify(row))
	if trial == 0:
		_coverage(city)
		_counterfactual(city, t)
	var state := CityState.new()
	for day: int in [1, 8, 14]:
		GameState.day = day
		state.begin_day(map.block_plans, day)
		city.set("spans", {})
		started = Time.get_ticks_usec()
		city.start_day(state, day, GameState.day_rng())
		row = city.get("spans").duplicate()
		row.merge({"seed": seed_value, "trial": trial, "stage": "day", "day": day,
			"total_ms": (Time.get_ticks_usec() - started) / 1000.0,
			"nodes_including_pending_free": _nodes(city), "props": city.props().size()})
		print("LAZY_STAGE " + JSON.stringify(row))
		# Flush only the old daily nodes, not a simulated/rendered frame.
		for child in city.find_children("*", "", true, false):
			if is_instance_valid(child) and child.is_queued_for_deletion():
				child.free()
	city.free()

func _nodes(node: Node) -> int:
	var result := 1
	for child in node.get_children():
		result += _nodes(child)
	return result

func _coverage(city: City) -> void:
	var map := city.map
	var home := map.doorstep_world_position()
	var view := Rect2(home - HALF_VIEW, HALF_VIEW * 2)
	var home_rect := map.tile_rect_to_world(CityMap.block_rect(map.home_block))
	var ground: TileMapLayer = city.get_node("Ground")
	var cells := ground.get_used_cells()
	var boot_inside := 0
	var boot_outside := 0
	for tile in cells:
		var rect := Rect2(Vector2(tile) * 32.0, Vector2(32, 32))
		if view.intersects(rect):
			if home_rect.intersects(rect):
				boot_inside += 1
			else:
				boot_outside += 1
	var building_nodes := 0
	var max_roof_north_overhang := 0.0
	var roof_layers := 0
	for building in city.buildings():
		building_nodes += _nodes(building)
		for col in building.columns():
			max_roof_north_overhang = maxf(max_roof_north_overhang,
				building._extension_rows(col) * 32.0)
		for layer: SceneryLayer in building._roof_layers:
			roof_layers += 1
			for rect: Rect2 in layer._rects:
				max_roof_north_overhang = maxf(max_roof_north_overhang,
					-rect.position.y - building.footprint.y)
	print("LAZY_BOOT " + JSON.stringify({"seed": map.seed_used,
		"viewport_world": str(view), "home_block_world": str(home_rect),
		"ground_prepared": cells.size(), "visible_ground_inside_home": boot_inside,
		"visible_ground_outside_home": boot_outside, "building_nodes": building_nodes,
		"roof_layers": roof_layers, "max_roof_north_overhang_px": max_roof_north_overhang,
		"buildings_visible_by_lot": _building_count(city, view),
		"shadow_chunks": city.get_node("BuildingShadows").get_child_count()}))
	# BFS on walkable map tiles, without daily closures, bodies, clock or danger.
	var origin := map.world_to_tile(home)
	var parents: Dictionary = {origin: origin}
	var queue: Array[Vector2i] = [origin]
	var near := origin
	var far := origin
	var index := 0
	while index < queue.size():
		var at := queue[index]
		index += 1
		if Tile.is_calm(map.tile_at(at)):
			if near == origin:
				near = at
			far = at
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + offset
			if not parents.has(next) and map.is_walkable(next):
				parents[next] = at
				queue.append(next)
	for goal: Vector2i in [near, far]:
		var path: Array[Vector2i] = []
		var tile := goal
		while tile != origin:
			path.append(tile)
			tile = parents[tile]
		path.append(origin)
		var seen_cells: Dictionary = {}
		var seen_buildings: Dictionary = {}
		for at in path:
			var camera := map.tile_to_world(at)
			var rect := Rect2(camera - HALF_VIEW, HALF_VIEW * 2)
			var lo := Vector2i((rect.position / 32).floor())
			var hi := Vector2i((rect.end / 32).ceil())
			for y in range(lo.y, hi.y):
				for x in range(lo.x, hi.x):
					var cell := Vector2i(x, y)
					if ground.get_cell_source_id(cell) >= 0:
						seen_cells[cell] = true
			for building in city.buildings():
				if rect.intersects(map.tile_rect_to_world(building.lot)):
					seen_buildings[building.lot] = true
		print("LAZY_COVERAGE " + JSON.stringify({"seed": map.seed_used,
			"route": "nearest_calm_return" if goal == near else "farthest_bfs_calm_return",
			"round_trip_px": (path.size() - 1) * 64,
			"unique_ground_cells": seen_cells.size(), "prepared_ground_cells": cells.size(),
			"unique_building_lots": seen_buildings.size(), "prepared_buildings": city.buildings().size()}))

func _building_count(city: City, rect: Rect2) -> int:
	var result := 0
	for building in city.buildings():
		result += int(rect.intersects(city.map.tile_rect_to_world(building.lot)))
	return result

func _counterfactual(city: City, t) -> void:
	var source: TileMapLayer = city.get_node("Ground")
	var expected_count := source.get_used_cells().size()
	var home := city.map.doorstep_world_position()
	var nearby := Rect2(home - HALF_VIEW, HALF_VIEW * 2).grow(128)
	var sheet := (source.tile_set.get_source(source.tile_set.get_source_id(0)) as TileSetAtlasSource).texture
	for mode: String in ["full", "nearby", "nearby", "full"]:
		var baseline := OS.get_static_memory_usage()
		var layer := TileMapLayer.new()
		layer.tile_set = source.tile_set
		# Deliberately outside the tree: no renderer/physics/quadrant processing in this experiment.
		var lo := Vector2i(-City.OUTSIDE_DEPTH_TILES, -City.OUTSIDE_DEPTH_TILES)
		var hi := city.map.size + Vector2i.ONE * City.OUTSIDE_DEPTH_TILES
		if mode == "nearby":
			lo = Vector2i((nearby.position / 32).floor())
			hi = Vector2i((nearby.end / 32).ceil())
		var started := Time.get_ticks_usec()
		var count := 0
		for y in range(lo.y, hi.y):
			for x in range(lo.x, hi.x):
				var tile := Vector2i(x, y)
				var inside := x >= 0 and y >= 0 and x < city.map.size.x and y < city.map.size.y
				var source_id := GroundTiles.source_for(city.map, tile, 1) if inside \
					else city._border_source(x, y, City.OUTSIDE_DEPTH_TILES)
				if source_id >= 0 and source_id != GroundTiles.WATER:
					layer.set_cell(tile, source_id, GroundLayers.atlas_coords_for(
						source_id, city.map.seed_used, tile, source.tile_set))
					count += 1
		var insert_ms := (Time.get_ticks_usec() - started) / 1000.0
		var allocated := OS.get_static_memory_usage() - baseline
		var mismatches := 0
		for y in range(lo.y, hi.y):
			for x in range(lo.x, hi.x):
				var tile := Vector2i(x, y)
				mismatches += int(layer.get_cell_source_id(tile) != source.get_cell_source_id(tile)
					or layer.get_cell_atlas_coords(tile) != source.get_cell_atlas_coords(tile))
		started = Time.get_ticks_usec()
		layer.clear()
		var clear_ms := (Time.get_ticks_usec() - started) / 1000.0
		var after_clear := OS.get_static_memory_usage() - baseline
		layer.free()
		var after_free := OS.get_static_memory_usage() - baseline
		t.check(count > 0 and mismatches == 0,
			"counterfactual paints nonempty cells identical to the actual boot ground")
		if mode == "full":
			t.check(count == expected_count, "full counterfactual covers boot ground")
		print("LAZY_SUBSET " + JSON.stringify({"seed": city.map.seed_used, "mode": mode,
			"cells": count, "insert_ms": insert_ms, "clear_ms": clear_ms,
			"static_memory_delta": allocated, "static_memory_after_clear_delta": after_clear,
			"static_memory_after_free_delta": after_free,
			"shared_sheet_size": str(sheet.get_size()),
			"shared_sheet_rgba8_bytes": sheet.get_width() * sheet.get_height() * 4}))

## Observe the real first suspended boot frame, then complete its two warmup awaits as the
## camera regression suite does. This validates geometry, not a rendered image or boot timing.
func _actual_boot(t) -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	t.add_child(main)
	var camera := main.get_viewport().get_camera_2d()
	var size := main.get_viewport_rect().size / camera.zoom
	print("LAZY_REAL_BOOT " + JSON.stringify({"viewport_px": str(main.get_viewport_rect().size),
		"zoom": str(camera.zoom), "world_size": str(size),
		"camera_center": str(camera.get_screen_center_position()),
		"doorstep": str(main._city.map.doorstep_world_position()),
		"player_absent": main._player == null}))
	t.check(size.is_equal_approx(HALF_VIEW * 2), "real boot matches coverage viewport")
	t.check(camera.get_screen_center_position().distance_to(
		main._city.map.doorstep_world_position()) < 1, "real boot camera centers on doorstep")
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
