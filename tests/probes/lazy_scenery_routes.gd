extends RefCounted
## Coverage of the actual daily offered route graph, after Main plans closures and events.
## This inspects generated options; it does not run a player or choose a new route.

const HALF_VIEW := Vector2(320, 180)

var _city: City
var _ground: TileMapLayer

func run(t) -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	_city = main._city
	_ground = _city.get_node("Ground")
	var tree := _city.route_tree()
	t.check(tree != null and not tree.branches.is_empty(), "real daily boot supplies route options")
	var home_tiles := _tiles_for_nodes(tree, tree._home)
	home_tiles[_city.map.world_to_tile(_city.map.doorstep_world_position())] = true
	var network_tiles := _tiles_for_nodes(tree, tree._colours)
	var network_closed := _closed_count(network_tiles)
	var offered := network_tiles.duplicate()
	offered.merge(home_tiles)
	var row := {"seed": _city.map.seed_used, "day": GameState.day,
		"branches": tree.branches.size(), "generated_nodes": tree._colours.size(),
		"generated_candidate_tiles": network_tiles.size(),
		"closed_generated_tiles": network_closed, "home_candidate_tiles": home_tiles.size(),
		"closures": _city.closures().size(), "closed_map_tiles": _city.map.closed_tiles.size(),
		"events_planned": _city.events.planned_count(),
		"ground_prepared": _ground.get_used_cells().size(),
		"buildings_prepared": _city.buildings().size(),
		"network": _coverage(network_tiles, 0), "network_and_home": _coverage(offered, 0),
		"network_and_home_lookahead_envelope": _coverage(offered, Stroller.CAMERA_LOOK_AHEAD),
		"routes": []}
	var lines := RouteLines.new()
	lines._map = _city.map
	var areas := ClosurePlanner.calm_areas(_city.map)
	var area_by_block := {}
	for area in areas:
		area_by_block[area.block] = area
	var all_options := home_tiles.duplicate()
	for index in tree.branches.size():
		var branch := tree.branches[index]
		for option in branch.routes.size():
			var cells: Array = branch.routes[option]
			var nodes := {}
			for node: int in tree._colours:
				if tree._colours[node].has(index) and cells.has(tree.grid.cell_of(node)):
					nodes[node] = true
			var tiles := _tiles_for_nodes(tree, nodes)
			var closed := _closed_count(tiles)
			var area: ClosurePlanner.CalmArea = area_by_block.get(branch.area)
			if area and not cells.is_empty():
				tiles[lines._calm_endpoint_tile(cells[0], area)] = true
			tiles.merge(home_tiles)
			all_options.merge(tiles)
			row.routes.append({"area": str(branch.area), "option": option,
				"generated_cells": cells.size(), "closed_generated_tiles": closed,
				"coverage_with_home_and_calm_entry": _coverage(tiles, 0)})
	lines.free()
	row["all_options_and_home_and_calm_entries"] = _coverage(all_options, 0)
	t.check(row.routes.size() >= tree.branches.size(), "every branch supplies a measured option")
	t.check(network_closed == 0, "daily closures leave sampled generated network tiles open")
	t.check(row.network_and_home.ground_cells > 0, "generated-route coverage is nonempty")
	print("LAZY_ROUTES " + JSON.stringify(row))
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()

## Keep the actual connected-component node identity rather than treating each 2x2 cell as
## wholly walkable. The tree is generated before closures; openness is checked at coverage time.
func _tiles_for_nodes(tree: RouteTree, nodes: Dictionary) -> Dictionary:
	var tiles := {}
	for node: int in nodes:
		var origin := tree.grid.cell_of(node) * ReachabilityGrid.CELL
		for y in ReachabilityGrid.CELL:
			for x in ReachabilityGrid.CELL:
				var tile := origin + Vector2i(x, y)
				if tree.grid.node_at(tile) == node:
					tiles[tile] = true
	return tiles

func _closed_count(tiles: Dictionary) -> int:
	var result := 0
	for tile: Vector2i in tiles:
		result += int(not _city.map.is_open(tile))
	return result

## View unions over offered open tile centers. A square 46px expansion is a conservative
## envelope for all possible look-ahead directions, not a simulated camera trajectory.
func _coverage(tiles: Dictionary, margin: float) -> Dictionary:
	var ground_seen := {}
	var buildings_seen := {}
	var centers := 0
	for tile: Vector2i in tiles:
		if not _city.map.is_open(tile):
			continue
		centers += 1
		var at := _city.map.tile_to_world(tile)
		var view := Rect2(at - HALF_VIEW, HALF_VIEW * 2).grow(margin)
		var lo := Vector2i((view.position / 32).floor())
		var hi := Vector2i((view.end / 32).ceil())
		for y in range(lo.y, hi.y):
			for x in range(lo.x, hi.x):
				var cell := Vector2i(x, y)
				if _ground.get_cell_source_id(cell) >= 0:
					ground_seen[cell] = true
		for building in _city.buildings():
			if view.intersects(_city.map.tile_rect_to_world(building.lot)):
				buildings_seen[building.lot] = true
	return {"open_camera_centers": centers, "ground_cells": ground_seen.size(),
		"building_lots": buildings_seen.size()}
