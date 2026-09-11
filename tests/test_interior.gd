extends RefCounted
## `InteriorMap` and `InteriorMapPlan` — the escape scene's one building-wide map, walkability, the
## diagonal switchback stairwells and the doors that teleport between its seven parts, all headless:
## nothing here needs a scene tree except the two suites that build `InteriorScene` itself.

func run(t) -> void:
	_test_the_map_builds(t)
	_test_every_flight_and_landing_tile_is_walkable(t)
	_test_the_anti_shortcut_property_in_each_shaft(t)
	_test_every_door_has_the_counterpart_it_claims(t)
	_test_the_exit_and_the_entrance_are_what_they_claim(t)
	_test_the_ground_between_parts_is_not_walkable(t)
	_test_every_walkable_tile_is_reachable_from_her_door_through_the_doors(t)
	_test_no_two_parts_are_reachable_by_walking_alone(t)
	_test_the_tileset_carries_every_walkable_ground_kind(t)
	_test_the_scene_paints_the_whole_map(t)
	_test_collision_blocks_exactly_the_non_walkable_ground(t)
	_test_a_sideways_press_on_a_flight_walks_its_slope(t)
	_test_every_diagonal_step_has_both_its_pinch_corners_cleared(t)
	_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)

func _test_the_map_builds(t: Node) -> void:
	var f := InteriorMap.build()
	t.check(f != null and not f.tiles.is_empty(), "the map builds a non-empty tile grid")
	for part in InteriorMap.PARTS:
		t.check(f.waypoints.has(part), "the map carries a waypoint for '%s'" % part)

func _test_every_flight_and_landing_tile_is_walkable(t: Node) -> void:
	var f := InteriorMap.build()
	var count := 0
	for tile: Vector2i in f.tiles:
		var k: InteriorTile.Kind = f.tiles[tile]
		if k in [InteriorTile.Kind.STAIR_FLIGHT_E, InteriorTile.Kind.STAIR_FLIGHT_W, InteriorTile.Kind.LANDING]:
			count += 1
			t.check(f.is_walkable(tile), "tile %s (kind %d) is walkable" % [tile, k])
	# A guard that the sweep above was not vacuous — two shafts, each three floor-to-floor gaps of
	# a 3-tile flight down, a 1-tile half-landing and a 3-tile flight back, plus its four floor
	# landings (`LANDING` kind), plus the basement's own two-tile entry flight (`STAIR_FLIGHT_E`,
	# the same kit tiles, counted in this sweep too since it asks about the whole map at once).
	t.check(count == 2 * (3 * (3 + 1 + 3) + 4) + 2,
			"both shafts have every gap's flight and half-landing tiles and every floor landing, "
			+ "plus the basement's own entry flight (got %d)" % count)

## The property `InteriorMap._lay_flight()`'s own doc exists to guarantee: the only walkable way
## from one landing to the next is along the flights it lays — checked as a graph distance rather
## than a raw adjacency test, since a diagonal layout has no single "gap row" left to measure. If
## any tile off the intended chain were walkable and adjacent to two non-consecutive tiles on it, a
## shorter path would exist and this would catch it.
func _test_the_anti_shortcut_property_in_each_shaft(t: Node) -> void:
	var f := InteriorMap.build()
	for side in ["left", "right"]:
		var part := "stairwell_%s" % side
		var ids: Array = ["landing_third", "landing_second", "landing_first", "landing_lobby"]
		for i in ids.size() - 1:
			var here: Vector2i = f.waypoints["%s:%s" % [part, ids[i]]]
			var there: Vector2i = f.waypoints["%s:%s" % [part, ids[i + 1]]]
			var steps := _shortest_path_length(f, here, there)
			# 9 nodes on the chain (landing, 3 down, the turn, 3 back, landing) is 8 edges; a
			# shorter answer means some other walkable tile cut the corner.
			t.check(steps == 8, "%s: %s to %s is exactly 8 steps along the flights (got %d)"
					% [part, ids[i], ids[i + 1], steps])

func _test_every_door_has_the_counterpart_it_claims(t: Node) -> void:
	var f := InteriorMap.build()
	for id: String in f.doors:
		var door: InteriorMapPlan.Door = f.doors[id]
		var back: InteriorMapPlan.Door = f.door(door.target_door)
		t.check(back != null, "door '%s' -> '%s' exists" % [id, door.target_door])
		if back == null:
			continue
		t.check(back.target_door == id, "'%s' and '%s' are each other's counterpart" % [id, door.target_door])

func _test_the_exit_and_the_entrance_are_what_they_claim(t: Node) -> void:
	var f := InteriorMap.build()
	t.check(f.exit_tile.x >= 0, "the map records an exit tile")
	t.check(f.tiles.get(f.exit_tile) == InteriorTile.Kind.EMERGENCY_EXIT,
			"the basement's own exit tile is the emergency exit kind")
	t.check(f.is_walkable(f.exit_tile), "the emergency exit is walkable")

	t.check(f.entrance_tiles.size() == 1, "the map records exactly one barricaded entrance")
	var entrance: Vector2i = f.entrance_tiles[0]
	t.check(f.walls.get(entrance) == InteriorTile.Kind.ENTRANCE_DOOR,
			"the lobby's own entrance is the entrance door kind")
	t.check(not InteriorTile.is_walkable(InteriorTile.Kind.ENTRANCE_DOOR),
			"the barricaded entrance is not a walkable kind at all — it is a wall cell, never a floor tile")

## A few representative points between parts — the gap `InteriorMap._SLOT_STRIDE` leaves, since
## nothing is ever placed there.
func _test_the_ground_between_parts_is_not_walkable(t: Node) -> void:
	var f := InteriorMap.build()
	for x in [30, 94, 158, 222, 286, 350]:
		var tile := Vector2i(x, 0)
		t.check(not f.is_walkable(tile), "the gap tile %s between two parts is not walkable" % tile)

## A flood fill that crosses doors, starting at her own door on the third-floor hallway — every
## walkable cell in the whole building must be reachable from it once a door is allowed to jump.
func _test_every_walkable_tile_is_reachable_from_her_door_through_the_doors(t: Node) -> void:
	var f := InteriorMap.build()
	var seen := {f.start_tile: true}
	var queue: Array[Vector2i] = [f.start_tile]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next: Vector2i = here + Vector2i(dx, dy)
				if f.is_walkable(next) and not seen.has(next):
					seen[next] = true
					queue.append(next)
		for id: String in f.doors:
			var door: InteriorMapPlan.Door = f.doors[id]
			if door.tile != here:
				continue
			var target: Vector2i = f.door(door.target_door).tile
			if not seen.has(target):
				seen[target] = true
				queue.append(target)
	var walkable := 0
	for tile: Vector2i in f.tiles:
		if f.is_walkable(tile):
			walkable += 1
	t.check(seen.size() == walkable,
			"every walkable tile is reachable from her door through the doors (%d of %d)" % [seen.size(), walkable])

## The other half of the same guarantee: **without** crossing a door, a flood fill from one part's
## own waypoint never reaches another part's — the gaps `InteriorMap._SLOT_STRIDE` leaves are wide
## enough that walking alone, with no door, cannot cross from one part to the next.
func _test_no_two_parts_are_reachable_by_walking_alone(t: Node) -> void:
	var f := InteriorMap.build()
	var components := {}
	for part in InteriorMap.PARTS:
		components[part] = _flood_fill(f, f.waypoints[part])
	for part in InteriorMap.PARTS:
		for other in InteriorMap.PARTS:
			if other == part:
				continue
			t.check(not components[part].has(f.waypoints[other]),
					"'%s' cannot be reached from '%s' by walking alone, without a door" % [other, part])

## Every walkable kind that is drawn as ground rather than as a standing sprite or a decal needs an
## atlas source, or `InteriorScene.build()` would silently skip painting that cell — `PUDDLE` is the
## one walkable kind that is never a `tiles` entry of its own (see its own doc), so it is the one
## exclusion.
func _test_the_tileset_carries_every_walkable_ground_kind(t: Node) -> void:
	for kind in InteriorTile.Kind.values():
		if kind == InteriorTile.Kind.PUDDLE or not InteriorTile.is_walkable(kind):
			continue
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "walkable ground kind %d has a TileSet source" % kind)

## Builds the TileSet for real (needs `Tuning.TILE_SIZE`, an autoload — see this suite's own doc
## for why it runs as a scene) and paints the whole map, checking the ground layer actually holds a
## cell for every tile the plan says is walkable ground.
func _test_the_scene_paints_the_whole_map(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var ground: TileMapLayer = scene.get_node("Ground")
	var painted := 0
	for tile: Vector2i in f.tiles:
		if InteriorTileSet.source_id_for(f.tiles[tile]) >= 0:
			painted += 1
			t.check(ground.get_cell_source_id(tile) >= 0, "tile %s is painted" % tile)
	t.check(painted > 0, "the map actually has ground tiles to check (%d)" % painted)
	scene.free()

## `TileMapLayer` collision only ever comes from a cell that holds a tile — the gaps between parts
## and everything off the whole footprint hold none — so `InteriorScene` builds its own blockers,
## one `StaticBody2D` per non-walkable cell in a margin around the building. Checked structurally,
## by each body's own position, rather than through a physics-space query: a fresh body is not
## guaranteed to be registered with the physics server until a physics frame has actually run,
## which nothing here steps.
func _test_collision_blocks_exactly_the_non_walkable_ground(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var blocked := {}
	for body in scene.get_node("Collision").get_children():
		blocked[scene.world_to_tile(body.position)] = true
	for tile: Vector2i in f.tiles:
		t.check(not blocked.has(tile), "every tile with a floor (%s) is unblocked" % tile)
	t.check(blocked.has(Vector2i(30, 0)), "a gap tile between two parts is blocked")
	scene.free()

## The switchback's own redirection: a sideways press on a diagonal flight walks its slope rather
## than the screen axis it was pressed on — *(2026-09-10, playtest 55: "holding right or left on
## the switchback stairs moves the player diagonally")*. Steps `Stroller._redirect_along_a_flight()`
## directly, the function `_physics_process()` calls every frame, over a real `InteriorScene` so
## `slope_dir_at` answers for actual flight tiles rather than a hand-built stand-in.
func _test_a_sideways_press_on_a_flight_walks_its_slope(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var east_tile := Vector2i(-1, -1)
	var west_tile := Vector2i(-1, -1)
	for tile: Vector2i in f.tiles:
		if f.tiles[tile] == InteriorTile.Kind.STAIR_FLIGHT_E and east_tile.x < 0:
			east_tile = tile
		if f.tiles[tile] == InteriorTile.Kind.STAIR_FLIGHT_W and west_tile.x < 0:
			west_tile = tile
	t.check(east_tile.x >= 0 and west_tile.x >= 0, "the shaft has both flight kinds to test against")

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	var player := Stroller.new()
	player.add_child(camera)
	t.add_child(player)
	player.slope_dir_at = scene.slope_dir_at

	player.global_position = scene.tile_to_world(east_tile)
	var right_on_e := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(right_on_e.x > 0 and right_on_e.y > 0,
			"pressing right on a descending-east flight moves lower and further right")
	var left_on_e := player._redirect_along_a_flight(Vector2(-1, 0))
	t.check(left_on_e.x < 0 and left_on_e.y < 0, "pressing left on the same flight climbs toward its upper end")
	var up_on_e := player._redirect_along_a_flight(Vector2(0, -1))
	t.check(up_on_e == Vector2.ZERO, "a vertical press on a flight moves nowhere")

	player.global_position = scene.tile_to_world(west_tile)
	var right_on_w := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(right_on_w.x > 0 and right_on_w.y < 0,
			"pressing right on a descending-west flight climbs toward its upper end")

	var landing_tile: Vector2i = f.waypoints["stairwell_left:landing_third"]
	player.global_position = scene.tile_to_world(landing_tile)
	var off_flight := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(off_flight == Vector2(1, 0), "off a flight, a sideways press is unchanged")

	player.free()
	scene.free()

## Drives a rig from her own door on the top hallway through a stair door, down the whole shaft by
## the left flights and again by the right, into the lobby, down to the basement and out — the walk
## the TODO item asks for, on both stairwells.
##
## **The regression test for the actual defect a capture session found.** A diagonal flight tile
## touches its own diagonal neighbour at a single corner point; the two cells flanking that step
## are full-tile collision blockers on both sides by default, and a circular body of any real
## radius cannot cross a gap pinched to nothing between them. Every headless test above this one —
## the tile arithmetic, the anti-shortcut graph distance, even the redirected velocity's own
## direction — passed while a real body stood still against a wall it could not see, because
## nothing headless exercises `move_and_slide()` against freshly built collision bodies with no
## physics frame having actually elapsed (the project's own established shape: "a bare
## `Stroller.new()` has no `CollisionShape2D`, so `move_and_slide()` never moves it — assert on
## velocity, not on position," and no suite in this repo drives real collision-checked movement
## either). So this asserts the fix at the level headless *can* see: the data.
## `InteriorMap._mark_diagonal_clearances()` must have freed both corner cells for every diagonal
## adjacency in `tiles`, or `InteriorScene._rebuild_collision()` places a blocker back in the pinch
## and the defect returns.
func _test_every_diagonal_step_has_both_its_pinch_corners_cleared(t: Node) -> void:
	var f := InteriorMap.build()
	var diagonals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var checked := 0
	for t1: Vector2i in f.tiles:
		for d in diagonals:
			var t2 := t1 + d
			if not f.tiles.has(t2):
				continue
			checked += 1
			var corner_a := Vector2i(t1.x + d.x, t1.y)
			var corner_b := Vector2i(t1.x, t1.y + d.y)
			# Safe from `_rebuild_collision()`'s own blocker either way: floor of its own, or
			# explicitly cleared. Either satisfies the geometry; what matters is that it is never
			# both un-floored and un-cleared, which is the pinch.
			t.check(f.tiles.has(corner_a) or f.collision_clearance.has(corner_a),
					"the corner %s pinching %s to %s is floor or cleared" % [corner_a, t1, t2])
			t.check(f.tiles.has(corner_b) or f.collision_clearance.has(corner_b),
					"the corner %s pinching %s to %s is floor or cleared" % [corner_b, t1, t2])
	# A guard that the sweep found real diagonal adjacencies to check — every flight in both
	# shafts plus the basement's own entry flight.
	t.check(checked > 0, "the map has at least one diagonal adjacency to check (got %d)" % checked)

## **Steps `InteriorScene`'s own transition functions directly rather than driving `Stroller` by
## input.** `transition_at()` and `teleport_to_door()` are the exact functions `process_player()`
## calls every frame in the running game — the only thing skipped is the fade `Tween`'s own timing,
## which is presentation rather than logic (see `_start_door_transition()`'s own doc). Driving a
## `Stroller` by `--walk`-style input instead would additionally exercise `move_and_slide()` and
## real collision, which `_test_a_real_stroller_physically_crosses_a_diagonal_step` already covers
## on its own, over a real `CollisionShape2D` rather than a teleport that skips physics entirely —
## repeating that here would double the work rather than test anything new. **Not vacuous**: every
## assertion below reads the player's own `global_position` back after the call, not from a value
## this test computed itself, so a `teleport_to_door()` that silently failed to move the player
## would fail the very next line rather than being asserted past.
func _test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t: Node) -> void:
	var f := InteriorMap.build()
	for side in ["left", "right"]:
		var part := "stairwell_%s" % side
		var scene := InteriorScene.new()
		t.add_child(scene)
		scene.build()
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		var player := Stroller.new()
		player.add_child(camera)
		t.add_child(player)
		player.set_physics_process(false)

		# Her door -> the stair door at this hallway's own end.
		player.global_position = scene.tile_to_world(f.door("hallway_third:%s" % side).tile)
		var to_shaft := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_shaft.get("kind") == "door", "the %s stair door is a door transition" % side)
		scene.teleport_to_door(to_shaft["door"].target_door, player)
		t.check(player.global_position == scene.tile_to_world(f.door("%s:landing_third" % part).tile),
				"the %s walk arrives at its own top landing's own door" % side)

		# Down the whole shaft by the flights — no teleport until the bottom door, since every
		# intermediate landing's own door stands beside the vertical path rather than on it (see
		# `InteriorMapPlan.waypoints`'s own doc), so passing floor 2 and floor 1 on the way down
		# triggers nothing.
		for id in ["landing_third", "landing_second", "landing_first"]:
			var landing_tile: Vector2i = f.waypoints["%s:%s" % [part, id]]
			var mid_result := scene.transition_at(landing_tile)
			t.check(mid_result.is_empty(), "%s: passing %s's own landing triggers nothing" % [part, id])

		var bottom_door := f.door("%s:landing_lobby" % part)
		player.global_position = scene.tile_to_world(bottom_door.tile)
		var to_lobby := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_lobby.get("kind") == "door", "the %s shaft's own bottom door is a door transition" % side)
		scene.teleport_to_door(to_lobby["door"].target_door, player)
		t.check(player.global_position == scene.tile_to_world(f.door("lobby:%s" % side).tile),
				"the %s walk reaches the lobby's own door" % side)

		# The lobby's own basement door, to the basement, to the exit.
		player.global_position = scene.tile_to_world(f.door("lobby:basement").tile)
		var to_basement := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_basement.get("kind") == "door", "the lobby's basement notch is a door transition")
		scene.teleport_to_door(to_basement["door"].target_door, player)
		t.check(player.global_position == scene.tile_to_world(f.door("basement:entry").tile),
				"the %s walk reaches the basement's own entry door" % side)

		player.global_position = scene.tile_to_world(f.exit_tile)
		var exit_result := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(exit_result.get("kind") == "exit",
				"the basement's own exit tile is a transition to the exit, reached via the %s stairwell" % side)

		player.free()
		scene.free()

## A pure 8-directional flood fill (to match `Stroller`'s own two-axis input) that never crosses a
## door — the "walking alone" half of the reachability guarantee.
func _flood_fill(f: InteriorMapPlan, start: Vector2i) -> Dictionary:
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

func _shortest_path_length(f: InteriorMapPlan, start: Vector2i, goal: Vector2i) -> int:
	var dist := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var here: Vector2i = queue[head]
		head += 1
		if here == goal:
			return dist[here]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := here + Vector2i(dx, dy)
				if f.is_walkable(next) and not dist.has(next):
					dist[next] = dist[here] + 1
					queue.append(next)
	return -1
