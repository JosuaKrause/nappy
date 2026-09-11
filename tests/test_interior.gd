extends RefCounted
## `InteriorMap` and `InteriorMapPlan` — the escape scene's seven maps, walkability, the diagonal
## switchback stairwells and the doors that join every map to the next, all headless: nothing here
## needs a scene tree except the two suites that build `InteriorScene` itself.

const _ALL_KINDS: Array[int] = [
	InteriorMap.MapKind.HALLWAY_THIRD, InteriorMap.MapKind.HALLWAY_SECOND,
	InteriorMap.MapKind.HALLWAY_FIRST, InteriorMap.MapKind.STAIRWELL_LEFT,
	InteriorMap.MapKind.STAIRWELL_RIGHT, InteriorMap.MapKind.LOBBY, InteriorMap.MapKind.BASEMENT,
]

func run(t) -> void:
	_test_every_map_builds(t)
	_test_every_flight_and_landing_tile_is_walkable(t)
	_test_the_anti_shortcut_property_in_each_shaft(t)
	_test_every_door_has_the_counterpart_it_claims(t)
	_test_the_exit_and_the_entrance_are_what_they_claim(t)
	_test_every_walkable_tile_of_every_map_is_reachable_from_her_door(t)
	_test_the_tileset_carries_every_walkable_ground_kind(t)
	_test_the_scene_paints_every_map(t)
	_test_collision_blocks_exactly_the_non_walkable_ground(t)
	_test_a_sideways_press_on_a_flight_walks_its_slope(t)
	_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)

func _test_every_map_builds(t: Node) -> void:
	for kind in _ALL_KINDS:
		var f := InteriorMap.build(kind)
		t.check(f != null and not f.tiles.is_empty(), "map %d builds a non-empty tile grid" % kind)

func _test_every_flight_and_landing_tile_is_walkable(t: Node) -> void:
	for kind in [InteriorMap.MapKind.STAIRWELL_LEFT, InteriorMap.MapKind.STAIRWELL_RIGHT]:
		var f := InteriorMap.build(kind)
		var count := 0
		for tile: Vector2i in f.tiles:
			var k: InteriorTile.Kind = f.tiles[tile]
			if k in [InteriorTile.Kind.STAIR_FLIGHT_E, InteriorTile.Kind.STAIR_FLIGHT_W, InteriorTile.Kind.LANDING]:
				count += 1
				t.check(f.is_walkable(tile), "map %d tile %s (kind %d) is walkable" % [kind, tile, k])
		# A guard that the sweep above was not vacuous — three floor-to-floor gaps, each a 3-tile
		# flight down, a 1-tile half-landing and a 3-tile flight back, plus the four floor landings
		# themselves (`LANDING` kind, one per entry in `InteriorMap._STAIRWELL_LANDINGS`).
		t.check(count == 3 * (3 + 1 + 3) + 4,
				"map %d has every gap's flight and half-landing tiles, and every floor landing (got %d)"
				% [kind, count])
	# The basement's own short entry flight, reused from the same kit.
	var basement := InteriorMap.build(InteriorMap.MapKind.BASEMENT)
	var basement_flights := 0
	for tile: Vector2i in basement.tiles:
		if basement.tiles[tile] in [InteriorTile.Kind.STAIR_FLIGHT_E, InteriorTile.Kind.STAIR_FLIGHT_W]:
			basement_flights += 1
			t.check(basement.is_walkable(tile), "basement flight tile %s is walkable" % tile)
	t.check(basement_flights == 2, "the basement's entry flight has its two tiles (got %d)" % basement_flights)

## The property `InteriorMap._lay_flight()`'s own doc exists to guarantee: the only walkable way
## from one landing to the next is along the flights it lays — checked as a graph distance rather
## than a raw adjacency test, since a diagonal layout has no single "gap row" left to measure. If
## any tile off the intended chain were walkable and adjacent to two non-consecutive tiles on it, a
## shorter path would exist and this would catch it; the original design's equivalent check is
## `docs/DECISIONS.md`'s own record of the single-shaft door/landing gap this supersedes.
func _test_the_anti_shortcut_property_in_each_shaft(t: Node) -> void:
	for kind in [InteriorMap.MapKind.STAIRWELL_LEFT, InteriorMap.MapKind.STAIRWELL_RIGHT]:
		var f := InteriorMap.build(kind)
		var ids: Array = ["landing_third", "landing_second", "landing_first", "landing_lobby"]
		for i in ids.size() - 1:
			var here: Vector2i = f.waypoints[ids[i]]
			var there: Vector2i = f.waypoints[ids[i + 1]]
			var steps := _shortest_path_length(f, here, there)
			# 9 nodes on the chain (landing, 3 down, the turn, 3 back, landing) is 8 edges; a
			# shorter answer means some other walkable tile cut the corner.
			t.check(steps == 8, "map %d: %s to %s is exactly 8 steps along the flights (got %d)"
					% [kind, ids[i], ids[i + 1], steps])

func _test_every_door_has_the_counterpart_it_claims(t: Node) -> void:
	var plans := {}
	for kind in _ALL_KINDS:
		plans[kind] = InteriorMap.build(kind)
	for kind in _ALL_KINDS:
		var f: InteriorMapPlan = plans[kind]
		for id: String in f.doors:
			var door: InteriorMapPlan.Door = f.doors[id]
			t.check(plans.has(door.target_map), "map %d door '%s' names a real target map" % [kind, id])
			if not plans.has(door.target_map):
				continue
			var target: InteriorMapPlan = plans[door.target_map]
			var back: InteriorMapPlan.Door = target.door(door.target_door)
			t.check(back != null, "map %d door '%s' -> map %d has a door '%s' there"
					% [kind, id, door.target_map, door.target_door])
			if back == null:
				continue
			t.check(back.target_map == kind and back.target_door == id,
					"map %d door '%s' and map %d door '%s' are each other's counterpart"
					% [kind, id, door.target_map, door.target_door])

func _test_the_exit_and_the_entrance_are_what_they_claim(t: Node) -> void:
	var basement := InteriorMap.build(InteriorMap.MapKind.BASEMENT)
	t.check(basement.exit_tile.x >= 0, "the basement records an exit tile")
	t.check(basement.tiles.get(basement.exit_tile) == InteriorTile.Kind.EMERGENCY_EXIT,
			"the basement's own exit tile is the emergency exit kind")
	t.check(basement.is_walkable(basement.exit_tile), "the emergency exit is walkable")

	var lobby := InteriorMap.build(InteriorMap.MapKind.LOBBY)
	t.check(lobby.entrance_column >= 0, "the lobby records an entrance column")
	t.check(lobby.walls.get(Vector2i(lobby.entrance_column, 0)) == InteriorTile.Kind.ENTRANCE_DOOR,
			"the lobby's own entrance column is the entrance door kind")
	t.check(not InteriorTile.is_walkable(InteriorTile.Kind.ENTRANCE_DOOR),
			"the barricaded entrance is not a walkable kind at all — it is a wall cell, never a floor tile")

## A flood fill that crosses doors, starting at her own door on the third-floor hallway — the
## brief's own "nothing walkable is unreachable from her door" reworked for seven maps that no
## longer share one coordinate space. Each map keeps its own 8-directional (to match `Stroller`'s
## two-axis input) reachable set; stepping onto a door tile also enqueues the counterpart door's
## tile on its target map.
func _test_every_walkable_tile_of_every_map_is_reachable_from_her_door(t: Node) -> void:
	var plans := {}
	for kind in _ALL_KINDS:
		plans[kind] = InteriorMap.build(kind)
	var start_kind := InteriorMap.MapKind.HALLWAY_THIRD
	var start_tile: Vector2i = plans[start_kind].start_tile
	var seen := {}   # kind -> {tile: true}
	for kind in _ALL_KINDS:
		seen[kind] = {}
	var queue: Array = [[start_kind, start_tile]]
	seen[start_kind][start_tile] = true
	while not queue.is_empty():
		var here: Array = queue.pop_back()
		var kind: int = here[0]
		var tile: Vector2i = here[1]
		var plan: InteriorMapPlan = plans[kind]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next: Vector2i = tile + Vector2i(dx, dy)
				if plan.is_walkable(next) and not seen[kind].has(next):
					seen[kind][next] = true
					queue.append([kind, next])
		for id: String in plan.doors:
			var door: InteriorMapPlan.Door = plan.doors[id]
			if door.tile != tile:
				continue
			var target_plan: InteriorMapPlan = plans[door.target_map]
			var target_tile: Vector2i = target_plan.door(door.target_door).tile
			if not seen[door.target_map].has(target_tile):
				seen[door.target_map][target_tile] = true
				queue.append([door.target_map, target_tile])
	for kind in _ALL_KINDS:
		var plan: InteriorMapPlan = plans[kind]
		var walkable := 0
		for tile: Vector2i in plan.tiles:
			if plan.is_walkable(tile):
				walkable += 1
		t.check(seen[kind].size() == walkable,
				"map %d: every walkable tile is reachable from her door through the doors (%d of %d)"
				% [kind, seen[kind].size(), walkable])

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
## for why it runs as a scene) and paints every map, checking the ground layer actually holds a
## cell for every tile the plan says is walkable ground.
func _test_the_scene_paints_every_map(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	for kind in _ALL_KINDS:
		scene.build(kind)
		var f := InteriorMap.build(kind)
		var ground: TileMapLayer = scene.get_node("Ground")
		var painted := 0
		for tile: Vector2i in f.tiles:
			if InteriorTileSet.source_id_for(f.tiles[tile]) >= 0:
				painted += 1
				t.check(ground.get_cell_source_id(tile) >= 0, "map %d tile %s is painted" % [kind, tile])
		t.check(painted > 0, "map %d actually has ground tiles to check (%d)" % [kind, painted])
	scene.free()

## `TileMapLayer` collision only ever comes from a cell that holds a tile — the space off a map's
## own footprint holds none — so `InteriorScene` builds its own blockers, one `StaticBody2D` per
## non-walkable cell in a margin around the map. Checked structurally, by each body's own position,
## rather than through a physics-space query: a fresh body is not guaranteed to be registered with
## the physics server until a physics frame has actually run, which nothing here steps.
func _test_collision_blocks_exactly_the_non_walkable_ground(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build(InteriorMap.MapKind.HALLWAY_THIRD)
	var f := InteriorMap.build(InteriorMap.MapKind.HALLWAY_THIRD)
	var blocked := {}
	for body in scene.get_node("Collision").get_children():
		blocked[scene.world_to_tile(body.position)] = true
	for tile: Vector2i in f.tiles:
		t.check(not blocked.has(tile), "every tile with a floor (%s) is unblocked" % tile)
	# One tile north of the hallway's own wall row is genuinely outside the floor plan.
	var above_the_wall := Vector2i(f.start_tile.x, -1)
	t.check(blocked.has(above_the_wall), "the cell above the hallway's own wall row is blocked")
	scene.free()

## The switchback's own redirection: a sideways press on a diagonal flight walks its slope rather
## than the screen axis it was pressed on — *(2026-09-10, playtest 55: "holding right or left on
## the switchback stairs moves the player diagonally")*. Steps `Stroller._redirect_along_a_flight()`
## directly, the function `_physics_process()` calls every frame, over a real `InteriorScene` so
## `slope_dir_at` answers for actual flight tiles rather than a hand-built stand-in.
func _test_a_sideways_press_on_a_flight_walks_its_slope(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build(InteriorMap.MapKind.STAIRWELL_LEFT)
	var f := InteriorMap.build(InteriorMap.MapKind.STAIRWELL_LEFT)
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

	var landing_tile: Vector2i = f.door("landing_third").tile
	player.global_position = scene.tile_to_world(landing_tile)
	var off_flight := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(off_flight == Vector2(1, 0), "off a flight, a sideways press is unchanged")

	player.free()
	scene.free()

## Drives a rig from her own door on the top hallway through a stair door, down the whole shaft by
## the left flights and again by the right, into the lobby, down to the basement and out — the walk
## the TODO item asks for, on both stairwells.
##
## **Steps `InteriorScene`'s own transition functions directly rather than driving `Stroller` by
## input.** `transition_at()` and `go_to_map()` are the exact functions `process_player()` calls
## every frame in the running game — the only thing skipped is the fade `Tween`'s own timing, which
## is presentation rather than logic (see `_start_door_transition()`'s own doc). Driving a
## `Stroller` by `--walk`-style input instead would additionally exercise `move_and_slide()` and the
## collision blockers `_rebuild_collision()` builds, which `_test_collision_blocks_exactly_the_
## non_walkable_ground` already covers on its own — repeating that here would double the work
## rather than test anything new. **Not vacuous**: every assertion below reads `scene.map_kind` and
## the player's own `global_position` back from the *scene*, not from a value this test computed
## itself, so a `go_to_map()` that silently failed to rebuild or to move the player would fail the
## very next line rather than being asserted past.
func _test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t: Node) -> void:
	for side in ["left", "right"]:
		var stairwell_kind := InteriorMap.MapKind.STAIRWELL_LEFT if side == "left" else InteriorMap.MapKind.STAIRWELL_RIGHT
		var scene := InteriorScene.new()
		t.add_child(scene)
		scene.build(InteriorMap.MapKind.HALLWAY_THIRD)
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		var player := Stroller.new()
		player.add_child(camera)
		t.add_child(player)
		player.set_physics_process(false)

		var visited: Array[int] = [scene.map_kind]

		# Her door -> the stair door at this hallway's own end.
		var hallway := InteriorMap.build(InteriorMap.MapKind.HALLWAY_THIRD)
		player.global_position = scene.tile_to_world(hallway.door(side).tile)
		var to_shaft := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_shaft.get("kind") == "door", "the %s stair door is a door transition" % side)
		scene.go_to_map(stairwell_kind, to_shaft["door"].target_door, player)
		visited.append(scene.map_kind)
		t.check(scene.map_kind == stairwell_kind, "the %s walk reaches its own stairwell" % side)

		# Down the whole shaft by the flights — no map load until the bottom door, since every
		# intermediate landing's own door stands beside the vertical path rather than on it (see
		# `InteriorMapPlan.waypoints`'s own doc), so passing floor 2 and floor 1 on the way down
		# triggers nothing.
		var shaft := InteriorMap.build(stairwell_kind)
		for id in ["landing_third", "landing_second", "landing_first"]:
			var landing_tile: Vector2i = shaft.waypoints[id]
			var mid_result := scene.transition_at(landing_tile)
			t.check(mid_result.is_empty(), "%s shaft: passing %s's own landing triggers nothing" % [side, id])

		var bottom_door := shaft.door("landing_lobby")
		player.global_position = scene.tile_to_world(bottom_door.tile)
		var to_lobby := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_lobby.get("kind") == "door", "the %s shaft's own bottom door is a door transition" % side)
		scene.go_to_map(to_lobby["door"].target_map, to_lobby["door"].target_door, player)
		visited.append(scene.map_kind)
		t.check(scene.map_kind == InteriorMap.MapKind.LOBBY, "the %s walk reaches the lobby" % side)

		# The lobby's own basement door, to the basement, to the exit.
		var lobby := InteriorMap.build(InteriorMap.MapKind.LOBBY)
		player.global_position = scene.tile_to_world(lobby.door("basement").tile)
		var to_basement := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(to_basement.get("kind") == "door", "the lobby's basement notch is a door transition")
		scene.go_to_map(InteriorMap.MapKind.BASEMENT, to_basement["door"].target_door, player)
		visited.append(scene.map_kind)
		t.check(scene.map_kind == InteriorMap.MapKind.BASEMENT, "the %s walk reaches the basement" % side)

		var basement := InteriorMap.build(InteriorMap.MapKind.BASEMENT)
		player.global_position = scene.tile_to_world(basement.exit_tile)
		var exit_result := scene.transition_at(scene.world_to_tile(player.global_position))
		t.check(exit_result.get("kind") == "exit",
				"the basement's own exit tile is a transition to the exit, reached via the %s stairwell" % side)

		t.check(visited == [InteriorMap.MapKind.HALLWAY_THIRD, stairwell_kind, InteriorMap.MapKind.LOBBY,
				InteriorMap.MapKind.BASEMENT],
				"the %s walk visits hallway, its own stairwell, the lobby and the basement in order: %s"
				% [side, visited])

		player.free()
		scene.free()

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
