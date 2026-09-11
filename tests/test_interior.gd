extends RefCounted
## `InteriorMap` and `InteriorFloor` — the escape scene's floor plans, walkability, and the
## switchback stairwell layout, all headless: nothing here needs a scene tree.

func run(t) -> void:
	_test_every_floor_builds(t)
	_test_every_flight_and_landing_is_walkable(t)
	_test_the_gap_between_door_and_lower_landing_is_not_adjacent(t)
	_test_both_stairwells_lead_down_on_the_same_side(t)
	_test_the_basement_has_no_further_down_flights(t)
	_test_the_exit_and_the_entrance_are_what_they_claim(t)
	_test_nothing_walkable_is_unreachable_from_the_start(t)
	_test_the_tileset_carries_every_walkable_ground_kind(t)
	_test_the_scene_paints_every_floor(t)

func _test_every_floor_builds(t: Node) -> void:
	for kind in InteriorMap.ORDER:
		var f := InteriorMap.build(kind)
		t.check(f != null and not f.tiles.is_empty(),
				"floor %d builds a non-empty tile grid" % kind)
		t.check(f.stairwells.size() == 2, "floor %d carves exactly two stairwells" % kind)

func _test_every_flight_and_landing_is_walkable(t: Node) -> void:
	for kind in InteriorMap.ORDER:
		var f := InteriorMap.build(kind)
		var flight_or_landing_count := 0
		for tile: Vector2i in f.tiles:
			var k: InteriorTile.Kind = f.tiles[tile]
			if k in [InteriorTile.Kind.STAIR_FLIGHT_E, InteriorTile.Kind.STAIR_FLIGHT_W,
					InteriorTile.Kind.LANDING]:
				flight_or_landing_count += 1
				t.check(f.is_walkable(tile),
						"floor %d tile %s (kind %d) is walkable" % [kind, tile, k])
		# A guard that the sweep above was not vacuous — every non-basement floor carves two full
		# switchbacks, each with 6 flight tiles (three down, three back) and 4 landing tiles (the
		# turn's own three rows, plus the lower landing that triggers the transition).
		if kind != InteriorMap.FloorKind.BASEMENT:
			t.check(flight_or_landing_count == 2 * (6 + 4),
					"floor %d has both stairwells' full flight and landing tiles (got %d)"
					% [kind, flight_or_landing_count])

## The property `InteriorMap._carve_stairwell()`'s own doc exists to guarantee: the door and the
## lower landing (the transition trigger) are never within one step of each other, orthogonally
## or diagonally, so she cannot cross from one to the other without walking the flights between
## them — even though `Stroller` reads both input axes at once and diagonal movement is live.
func _test_the_gap_between_door_and_lower_landing_is_not_adjacent(t: Node) -> void:
	for kind in InteriorMap.ORDER:
		var f := InteriorMap.build(kind)
		for sw in f.stairwells:
			if not sw.has_flights():
				continue
			var gap := sw.door_tile - sw.lower_landing_tile
			t.check(maxi(absi(gap.x), absi(gap.y)) >= 2,
					"floor %d %s stairwell: door %s and lower landing %s are not adjacent"
					% [kind, sw.side, sw.door_tile, sw.lower_landing_tile])

func _test_both_stairwells_lead_down_on_the_same_side(t: Node) -> void:
	for kind in InteriorMap.ORDER:
		if kind == InteriorMap.FloorKind.BASEMENT:
			continue
		var f := InteriorMap.build(kind)
		var below := InteriorMap.build(InteriorMap.floor_below(kind))
		for side in ["left", "right"]:
			var here := f.stairwell(side)
			var there := below.stairwell(side)
			t.check(here.has_flights(), "floor %d's %s stairwell has flights down" % [kind, side])
			t.check(here.door_tile.x == there.door_tile.x,
					"floor %d's %s stairwell lands on the same side one floor down (%d vs %d)"
					% [kind, side, here.door_tile.x, there.door_tile.x])

func _test_the_basement_has_no_further_down_flights(t: Node) -> void:
	var basement := InteriorMap.build(InteriorMap.FloorKind.BASEMENT)
	for side in ["left", "right"]:
		var sw := basement.stairwell(side)
		t.check(not sw.has_flights(), "the basement's %s stairwell has nothing further down" % side)
	t.check(InteriorMap.floor_below(InteriorMap.FloorKind.BASEMENT) == InteriorMap.FloorKind.BASEMENT,
			"asking what is below the basement answers the basement itself, not a sixth floor")

func _test_the_exit_and_the_entrance_are_what_they_claim(t: Node) -> void:
	var basement := InteriorMap.build(InteriorMap.FloorKind.BASEMENT)
	t.check(basement.exit_tile.x >= 0, "the basement records an exit tile")
	t.check(basement.tiles.get(basement.exit_tile) == InteriorTile.Kind.EMERGENCY_EXIT,
			"the basement's own exit tile is the emergency exit kind")
	t.check(basement.is_walkable(basement.exit_tile), "the emergency exit is walkable")

	var ground := InteriorMap.build(InteriorMap.FloorKind.GROUND)
	t.check(ground.entrance_column >= 0, "the ground floor records an entrance column")
	t.check(ground.north_wall.get(ground.entrance_column) == InteriorTile.Kind.ENTRANCE_DOOR,
			"the ground floor's own entrance column is the entrance door kind")
	t.check(not InteriorTile.is_walkable(InteriorTile.Kind.ENTRANCE_DOOR),
			"the barricaded entrance is not a walkable kind at all — it is a wall column, "
			+ "never a floor tile")

## A flood fill over each floor's own walkable set from its `start_tile`, 8-directional to match
## `Stroller`'s own two-axis input. A cell absent from `tiles` is not walkable and is never a
## flood-fill neighbour, so this also re-proves the adjacency test above from the opposite
## direction: if it had failed, this sweep would have reached every flight and landing tile in
## one component instead of the door alone.
func _test_nothing_walkable_is_unreachable_from_the_start(t: Node) -> void:
	for kind in InteriorMap.ORDER:
		var f := InteriorMap.build(kind)
		var walkable: Array[Vector2i] = []
		for tile: Vector2i in f.tiles:
			if f.is_walkable(tile):
				walkable.append(tile)
		var reached := _flood_fill(f, f.start_tile)
		t.check(reached.size() == walkable.size(),
				"floor %d: every walkable tile is reachable from the start (%d of %d)"
				% [kind, reached.size(), walkable.size()])

## Every walkable kind that is drawn as ground rather than as a standing sprite needs an atlas
## source, or `InteriorScene.build()` would silently skip painting that cell — `PUDDLE` is the one
## walkable kind that is not ground of its own (it decorates the basement floor beneath it, and is
## never a `tiles` entry — see `InteriorTile.Kind.PUDDLE`'s own doc), so it is the one exclusion.
func _test_the_tileset_carries_every_walkable_ground_kind(t: Node) -> void:
	for kind in InteriorTile.Kind.values():
		if kind == InteriorTile.Kind.PUDDLE or not InteriorTile.is_walkable(kind):
			continue
		t.check(InteriorTileSet.source_id_for(kind) >= 0,
				"walkable ground kind %d has a TileSet source" % kind)

## Builds the TileSet for real (needs `Tuning.TILE_SIZE`, an autoload — see this suite's own doc
## for why it runs as a scene) and paints every floor, checking the ground layer actually holds
## a cell for every tile the floor plan says is walkable ground.
func _test_the_scene_paints_every_floor(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	for kind in InteriorMap.ORDER:
		scene.build(kind)
		var f: InteriorFloor = InteriorMap.build(kind)
		var ground: TileMapLayer = scene.get_node("Ground")
		var painted := 0
		for tile: Vector2i in f.tiles:
			if InteriorTileSet.source_id_for(f.tiles[tile]) >= 0:
				painted += 1
				t.check(ground.get_cell_source_id(tile) >= 0,
						"floor %d tile %s is painted" % [kind, tile])
		t.check(painted > 0, "floor %d actually has ground tiles to check (%d)" % [kind, painted])
	scene.free()

func _flood_fill(f: InteriorFloor, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := here + Vector2i(dx, dy)
				if seen.has(next) or not f.is_walkable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen
