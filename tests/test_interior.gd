extends RefCounted
## `InteriorMap` and `InteriorMapPlan` — the escape scene's one building-wide map, walkability, the
## diagonal switchback stairwells and the doors that teleport between its seven parts, all headless:
## nothing here needs a scene tree except the two suites that build `InteriorScene` itself.

func run(t) -> void:
	_test_the_map_builds(t)
	_test_the_stairwell_grammar_is_exact_in_both_shafts(t)
	_test_stair_symbols_define_walkability_and_art(t)
	_test_every_door_has_the_counterpart_it_claims(t)
	_test_the_exit_and_the_entrance_are_what_they_claim(t)
	_test_the_ground_between_parts_is_not_walkable(t)
	_test_every_walkable_tile_is_reachable_from_her_door_through_the_doors(t)
	_test_no_two_parts_are_reachable_by_walking_alone(t)
	_test_the_tileset_carries_every_walkable_ground_kind(t)
	_test_the_scene_paints_the_whole_map(t)
	_test_collision_blocks_exactly_the_non_walkable_ground(t)
	_test_stair_roles_are_live_tiles_and_old_overlays_are_unbound(t)
	_test_a_sideways_press_on_a_flight_walks_its_slope(t)
	_test_a_real_stroller_physically_crosses_both_flight_directions(t)
	_test_every_diagonal_step_has_both_its_pinch_corners_cleared(t)
	_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)
	_test_a_door_release_latch_keeps_a_door_from_retaking_her(t)
	_test_the_fire_closes_one_stairwell_and_leaves_the_other(t)
	_test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t)
	_test_an_explosion_flashes_every_hallway_window(t)

func _test_the_map_builds(t: Node) -> void:
	var f := InteriorMap.build()
	t.check(f != null and not f.tiles.is_empty(), "the map builds a non-empty tile grid")
	for part in InteriorMap.PARTS:
		t.check(f.waypoints.has(part), "the map carries a waypoint for '%s'" % part)

## The first 22 rows are the player's literal corrected diagram. The last four finish the same
## alternation only through the fourth door's two-cell level approach. This checks the authored
## rows and the parsed cells in both shafts, so a correct-looking constant that is not what the map
## paints cannot pass.
func _test_the_stairwell_grammar_is_exact_in_both_shafts(t: Node) -> void:
	var expected: Array[String] = [
		"..........",
		".D........",
		".Ft.......",
		".Fmt......",
		".bcmt.....",
		"...cmt....",
		"....cmt...",
		".....cmtD.",
		"......cmF.",
		".......cF.",
		".......TF.",
		"......TMF.",
		".....TMCb.",
		"....TMC...",
		"...TMC....",
		".DTMC.....",
		".FMC......",
		".FC.......",
		".Ft.......",
		".Fmt......",
		".bcmt.....",
		"...cmt....",
		"....cmt...",
		".....cmtD.",
		"......cmF.",
		".......cF.",
	]
	t.check(InteriorMap.STAIRWELL_ROWS == expected,
			"the runtime grammar is the literal 22-row diagram plus one completed lobby approach")
	var f := InteriorMap.build()
	for side in ["left", "right"]:
		var part := "stairwell_%s" % side
		var origin: Vector2i = f.waypoints[part] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for y in expected.size():
			for x in expected[y].length():
				var symbol := expected[y].substr(x, 1)
				var at := origin + Vector2i(x, y)
				if symbol == ".":
					t.check(not f.tiles.has(at), "%s row %d column %d stays background" % [part, y, x])
				elif symbol == "D":
					t.check(f.tiles.get(at) == InteriorTile.Kind.DOOR,
							"%s row %d column %d is its corridor door" % [part, y, x])
				else:
					t.check(f.tiles.get(at) == InteriorMap.stair_kind_for_symbol(symbol),
							"%s row %d column %d paints '%s'" % [part, y, x, symbol])

## Walkability and drawing are properties of the symbol roles, not of a second sparse flight map.
## The walkable roles have TileSet sources because they are the surface; the three side roles also
## have sources but remain solid.
func _test_stair_symbols_define_walkability_and_art(t: Node) -> void:
	for symbol in ["F", "t", "m", "T", "M"]:
		var kind: InteriorTile.Kind = InteriorMap.stair_kind_for_symbol(symbol)
		t.check(InteriorTile.is_walkable(kind), "'%s' is walkable" % symbol)
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "'%s' has a live tile source" % symbol)
	t.check(InteriorTile.is_walkable(InteriorTile.Kind.DOOR), "'D' is a walkable transition")
	for symbol in ["b", "c", "C"]:
		var kind: InteriorTile.Kind = InteriorMap.stair_kind_for_symbol(symbol)
		t.check(not InteriorTile.is_walkable(kind), "'%s' is not walkable" % symbol)
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "'%s' is still painted" % symbol)
	t.check(not InteriorTile.is_walkable(InteriorTile.Kind.NONE), "'.' is not walkable")

func _test_every_door_has_the_counterpart_it_claims(t: Node) -> void:
	var f := InteriorMap.build()
	var expected_pairs: Array[Array] = [
		["hallway_third:left", "stairwell_left:landing_third"],
		["hallway_third:right", "stairwell_right:landing_third"],
		["hallway_second:left", "stairwell_left:landing_second"],
		["hallway_second:right", "stairwell_right:landing_second"],
		["hallway_first:left", "stairwell_left:landing_first"],
		["hallway_first:right", "stairwell_right:landing_first"],
		["lobby:left", "stairwell_left:landing_lobby"],
		["lobby:right", "stairwell_right:landing_lobby"],
		["lobby:basement", "basement:entry"],
	]
	t.check(f.doors.size() == expected_pairs.size() * 2,
			"the building keeps exactly the nine external door pairs")
	for pair: Array in expected_pairs:
		var a: InteriorMapPlan.Door = f.door(pair[0])
		var b: InteriorMapPlan.Door = f.door(pair[1])
		t.check(a != null and b != null, "door pair '%s' / '%s' exists" % pair)
		if a == null or b == null:
			continue
		t.check(a.target_door == b.id and b.target_door == a.id,
				"'%s' and '%s' remain exact counterparts" % pair)
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
		if f.is_walkable(tile):
			t.check(not blocked.has(tile), "walkable tile %s is unblocked" % tile)
		else:
			t.check(blocked.has(tile), "painted non-walkable tile %s is blocked" % tile)
	t.check(blocked.has(Vector2i(30, 0)), "a gap tile between two parts is blocked")
	for side in ["left", "right"]:
		var part := "stairwell_%s" % side
		var origin: Vector2i = f.waypoints[part] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for y in InteriorMap.STAIRWELL_ROWS.size():
			var row: String = InteriorMap.STAIRWELL_ROWS[y]
			for x in row.length():
				var symbol := row.substr(x, 1)
				var at := origin + Vector2i(x, y)
				var should_block := symbol in [".", "b", "c", "C"]
				t.check(blocked.has(at) == should_block,
						"%s '%s' collision matches its grammar role at row %d column %d"
						% [part, symbol, y, x])
	# The two-row diagonal is wider at its narrowest cross-section than the player's circular body,
	# and each diagonal same-role step has the other role in one orthogonal corner. One outside
	# blocker therefore cannot recreate the two-blocker pinch the old one-row flight needed repaired.
	t.check(Tuning.PLAYER_BODY_RADIUS * 2.0 < InteriorScene.TILE * sqrt(2.0),
			"the player fits inside the two-row diagonal surface")
	var paired_steps := 0
	for tile: Vector2i in f.tiles:
		var kind: InteriorTile.Kind = f.tiles[tile]
		var direction := InteriorTile.flight_direction(kind)
		if direction == 0:
			continue
		var next := tile + Vector2i(direction, 1)
		if f.tiles.get(next) != kind:
			continue
		paired_steps += 1
		var corner_a := Vector2i(next.x, tile.y)
		var corner_b := Vector2i(tile.x, next.y)
		t.check(f.is_walkable(corner_a) or f.is_walkable(corner_b),
				"the diagonal surface from %s to %s has a walkable orthogonal corner" % [tile, next])
	t.check(paired_steps > 0, "both-row diagonal continuity has real steps to check")
	scene.free()

## The reviewed sources are the TileSet pictures selected by the grammar. No structural overlay —
## including the rejected vertical landing — or broad deck/rail is allowed to recreate the old
## sparse map on top of them.
func _test_stair_roles_are_live_tiles_and_old_overlays_are_unbound(t: Node) -> void:
	var expected_sources := {
		InteriorTile.Kind.STAIR_TOP_E: load("res://assets/interior/m158_stair_side_upper_e.svg"),
		InteriorTile.Kind.STAIR_MIDDLE_E: load("res://assets/interior/m158_stair_side_lower_e.svg"),
		InteriorTile.Kind.STAIR_CORNER_E: load("res://assets/interior/m158_stair_side_continue_e.svg"),
		InteriorTile.Kind.STAIR_TOP_W: load("res://assets/interior/m158_stair_side_upper_w.svg"),
		InteriorTile.Kind.STAIR_MIDDLE_W: load("res://assets/interior/m158_stair_side_lower_w.svg"),
		InteriorTile.Kind.STAIR_CORNER_W: load("res://assets/interior/m158_stair_side_continue_w.svg"),
		InteriorTile.Kind.STAIR_BLOCK: load("res://assets/interior/m158_stair_side_block.svg"),
	}
	var tile_set := InteriorTileSet.build()
	for kind: InteriorTile.Kind in expected_sources:
		var source_id := InteriorTileSet.source_id_for(kind)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		t.check(source != null and source.texture == expected_sources[kind],
				"stair role %d binds its reviewed tile source" % kind)
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var removed_textures: Array[Texture2D] = [
		load("res://assets/interior/stair_landing_vertical.svg"),
		load("res://assets/interior/stair_flight_run_e.svg"),
		load("res://assets/interior/stair_flight_run_w.svg"),
		load("res://assets/interior/stair_landing_floor.svg"),
		load("res://assets/interior/stair_landing_turn.svg"),
		load("res://assets/interior/stair_rail_run_e.svg"),
		load("res://assets/interior/stair_rail_run_w.svg"),
		load("res://assets/interior/stair_rail_run_e_rear.svg"),
		load("res://assets/interior/stair_rail_run_w_rear.svg"),
		load("res://assets/interior/stair_rail_short_e.svg"),
		load("res://assets/interior/stair_rail_short_e_rear.svg"),
	]
	var removed_bound := 0
	for layer_name in ["StairStructure", "Entities"]:
		for child in scene.get_node(layer_name).get_children():
			var sprite := child as Sprite2D
			if sprite != null and removed_textures.has(sprite.texture):
				removed_bound += 1
	t.check(removed_bound == 0,
			"no vertical landing, broad deck, platform, foreground rail or rear rail is bound")
	t.check(scene.get_node("StairStructure").get_child_count() == 0,
			"the corrected grammar needs no presentation-only stair structure")
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
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var player := Stroller.new()
	player.add_child(camera)
	t.add_child(player)
	player.slope_dir_at = scene.slope_dir_at
	var roles: Array[InteriorTile.Kind] = [
		InteriorTile.Kind.STAIR_TOP_E,
		InteriorTile.Kind.STAIR_MIDDLE_E,
		InteriorTile.Kind.STAIR_TOP_W,
		InteriorTile.Kind.STAIR_MIDDLE_W,
	]
	for kind: InteriorTile.Kind in roles:
		var role_tile := Vector2i(-1, -1)
		for tile: Vector2i in f.tiles:
			if f.tiles[tile] == kind:
				role_tile = tile
				break
		t.check(role_tile.x >= 0, "flight role %d exists in the shaft" % kind)
		if role_tile.x < 0:
			continue
		player.global_position = scene.tile_to_world(role_tile)
		var right := player._redirect_along_a_flight(Vector2(1, 0))
		var left := player._redirect_along_a_flight(Vector2(-1, 0))
		var descends_east := InteriorTile.flight_direction(kind) > 0
		if descends_east:
			t.check(right.x > 0 and right.y > 0,
					"east role %d: right moves equally right and down" % kind)
			t.check(left.x < 0 and left.y < 0,
					"east role %d: left moves equally left and up" % kind)
		else:
			t.check(left.x < 0 and left.y > 0,
					"west role %d: left moves equally left and down" % kind)
			t.check(right.x > 0 and right.y < 0,
					"west role %d: right moves equally right and up" % kind)
		for redirected in [right, left]:
			t.check(is_equal_approx(absf(redirected.x), absf(redirected.y)),
					"flight role %d gives equal horizontal and vertical components" % kind)
			t.check(is_equal_approx(redirected.length(), 1.0),
					"flight role %d normalizes the diagonal to ordinary movement speed" % kind)
		var vertical := player._redirect_along_a_flight(Vector2(0, -1))
		t.check(vertical == Vector2.ZERO, "flight role %d ignores pure vertical input" % kind)

	var landing_tile: Vector2i = f.waypoints["stairwell_left:landing_third"]
	player.global_position = scene.tile_to_world(landing_tile)
	var off_flight := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(off_flight == Vector2(1, 0), "off a flight, a sideways press is unchanged")

	player.free()
	scene.free()

## A real carrying rig starts on the level `F` approach and holds the same horizontal action the
## running game reads. The synchronous runner cannot advance `move_and_slide()`'s engine-owned
## delta, so each call to the real `_physics_process()` supplies its redirected, accelerated
## velocity and this test applies that frame's displacement through `move_and_collide()` against
## the scene's registered full-cell blockers, sliding the collision remainder along the reported
## normal. Reaching the next `F` approach therefore proves the 14px circle crossed every blocker
## corner in a complete flight; a graph path, assigned position or bare `Stroller.new()` cannot
## make this pass.
func _test_a_real_stroller_physically_crosses_both_flight_directions(t: Node) -> void:
	var f := InteriorMap.build()
	var origin: Vector2i = f.waypoints["stairwell_left"] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	_test_physical_flight(t, origin + Vector2i(1, 2), origin + Vector2i(8, 8), "move_right", "east")
	_test_physical_flight(t, origin + Vector2i(8, 10), origin + Vector2i(1, 16), "move_left", "west")

func _test_physical_flight(
		t: Node, start: Vector2i, target: Vector2i, action: StringName, label: String) -> void:
	const STEP := 1.0 / 60.0
	const MAX_STEPS := 360
	var f := InteriorMap.build()
	t.check(f.tiles.get(start) == InteriorTile.Kind.STAIRWELL_FLOOR,
			"the %s physical traversal starts on its level F approach" % label)
	t.check(f.tiles.get(target) == InteriorTile.Kind.STAIRWELL_FLOOR,
			"the %s physical traversal targets the next level F approach" % label)
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.slope_dir_at = scene.slope_dir_at
	scene.add_entity(player)
	player.set_physics_process(false)
	var body_collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var body_circle := body_collision.shape as CircleShape2D
	t.check(not body_collision.disabled and body_circle != null
			and is_equal_approx(body_circle.radius, Tuning.PLAYER_BODY_RADIUS),
			"the %s traversal uses the enabled real 14px player circle" % label)
	var pram_collision := player.get_node("PramCollisionShape2D") as CollisionShape2D
	t.check(pram_collision.disabled,
			"the %s escape traversal disables the pram body while she carries the baby" % label)
	player.global_position = scene.tile_to_world(start)
	player.velocity = Vector2.ZERO

	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_press(action)
	var steps := 0
	var collision_contacts := 0
	while steps < MAX_STEPS and scene.world_to_tile(player.global_position) != target:
		player._physics_process(STEP)
		collision_contacts += _move_real_body_one_step(player, player.velocity * STEP)
		steps += 1
	Input.action_release(action)
	var displacement := player.global_position - scene.tile_to_world(start)
	var expected_sign := 1.0 if label == "east" else -1.0
	t.check(scene.world_to_tile(player.global_position) == target,
			("the real %s-moving circle reaches the next F approach after %d physics steps; "
			+ "ended at %s, displacement %s")
			% [label, steps, player.global_position, displacement])
	t.check(signf(displacement.x) == expected_sign and displacement.y > 0.0,
			"the real %s flight makes forward and downward progress (%s)" % [label, displacement])
	t.check(absf(displacement.x) > InteriorScene.TILE * 6.0
			and displacement.y > InteriorScene.TILE * 5.0,
			"the real %s traversal crosses the complete flight (%s)" % [label, displacement])
	t.check(collision_contacts > 0,
			"the real %s circle contacts the flight's full-cell blockers while still crossing" % label)
	print("M158 physical %s flight: %d steps, displacement %s, %d blocker contacts" \
			% [label, steps, displacement, collision_contacts])
	scene.free()

## The explicit-displacement half `move_and_slide()` normally derives from the physics delta that
## the synchronous test runner cannot advance. The real body's sweep supplies every collision
## normal and remainder; up to `max_slides` applies the same bounded sliding shape as the runtime.
func _move_real_body_one_step(player: CharacterBody2D, motion: Vector2) -> int:
	var collision := player.move_and_collide(motion)
	var slides := 0
	var contacts := 0
	while collision != null and slides < player.max_slides:
		contacts += 1
		motion = collision.get_remainder().slide(collision.get_normal())
		if motion.is_zero_approx():
			return contacts
		collision = player.move_and_collide(motion)
		slides += 1
	return contacts

## Drives a rig from her own door on the top hallway through a stair door, down the whole shaft by
## the left flights and again by the right, into the lobby, down to the basement and out — the walk
## the TODO item asks for, on both stairwells.
##
## **The structural half of the regression a capture session found.** A diagonal flight tile
## touches its own diagonal neighbour at a single corner point; two full-cell blockers on both
## flanks pinch the passage to nothing. The physical test above owns the resulting body motion;
## this one proves the map only clears an absent two-blocker pinch and never turns a painted side
## role into walkable space.
## `InteriorMap._mark_diagonal_clearances()` frees both corners only when neither is already
## walkable. That keeps the basement entry open without clearing the corrected shaft's explicit
## `.` background or its painted side cells.
func _test_every_diagonal_step_has_both_its_pinch_corners_cleared(t: Node) -> void:
	var f := InteriorMap.build()
	var diagonals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var checked := 0
	for t1: Vector2i in f.tiles:
		if not f.is_walkable(t1):
			continue
		for d in diagonals:
			var t2 := t1 + d
			if not f.is_walkable(t2):
				continue
			checked += 1
			var corner_a := Vector2i(t1.x + d.x, t1.y)
			var corner_b := Vector2i(t1.x, t1.y + d.y)
			if f.is_walkable(corner_a) or f.is_walkable(corner_b):
				continue
			t.check(not f.tiles.has(corner_a) and not f.tiles.has(corner_b),
					"a required pinch clearance never overrides a painted stair-side cell")
			t.check(f.collision_clearance.has(corner_a),
					"the absent corner %s pinching %s to %s is cleared" % [corner_a, t1, t2])
			t.check(f.collision_clearance.has(corner_b),
					"the absent corner %s pinching %s to %s is cleared" % [corner_b, t1, t2])
	# A guard that the sweep found real diagonal adjacencies to check — every flight in both
	# shafts plus the basement's own entry flight.
	t.check(checked > 0, "the map has at least one diagonal adjacency to check (got %d)" % checked)

## **Steps `InteriorScene`'s own transition functions directly rather than driving `Stroller` by
## input.** `transition_at()` and `teleport_to_door()` are the exact functions `process_player()`
## calls every frame in the running game — the only thing skipped is the fade `Tween`'s own timing,
## which is presentation rather than logic (see `_start_door_transition()`'s own doc). The real
## input, slope redirection and collision sweep are separately covered on complete east and west
## flights by `_test_a_real_stroller_physically_crosses_both_flight_directions()`; repeating those
## here would double the work rather than test anything new. **Not vacuous**: every
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
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

		# The level `F` approach at each floor remains on the stair route while its `D` is one cell
		# beside it. Walking past a floor therefore does not trigger its corridor transition.
		var landing_ids: Array[String] = [
			"landing_third", "landing_second", "landing_first", "landing_lobby",
		]
		for index in landing_ids.size() - 1:
			var from: Vector2i = f.waypoints["%s:%s" % [part, landing_ids[index]]]
			var to: Vector2i = f.waypoints["%s:%s" % [part, landing_ids[index + 1]]]
			t.check(_shortest_path_length(f, from, to) > 0,
					"%s has a continuous walk from %s to %s"
					% [part, landing_ids[index], landing_ids[index + 1]])
		for id in ["landing_third", "landing_second", "landing_first"]:
			var landing_tile: Vector2i = f.waypoints["%s:%s" % [part, id]]
			var mid_result := scene.transition_at(landing_tile)
			t.check(mid_result.is_empty(), "%s: passing %s's `F` approach triggers nothing" % [part, id])

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

## `InteriorScene` arms a `ReleaseLatch` (`src/world/release_latch.gd`) on every arrival through a
## door rather than tracking an edge-detected "last tile", so the arrival tile and the trigger tile
## can be the same tile — see the class's own doc. `ReleaseLatch` itself, armed and updated with no
## door around it, is proven in `tests/test_checkpoints.gd`'s `_test_the_release_latch`; this checks
## only that `InteriorScene` wires it the way the milestone asks: armed on arrival with the stated
## radius, holding while she stays close, and clearing once she has actually left.
##
## Drives `teleport_to_door()` and `process_player()` directly, the same functions the running game
## calls every frame — see `_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit`'s own doc
## for why the fade tween's own timing is skipped. `player` is a plain `Node2D` rather than a
## `Stroller`: `teleport_to_door()` falls back to a bare `global_position` assignment for anything
## that is not a `Stroller`, and nothing here touches physics or the camera.
func _test_a_door_release_latch_keeps_a_door_from_retaking_her(t: Node) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var player := Node2D.new()
	t.add_child(player)

	var door_id := "hallway_third:left"
	var centre := scene.tile_to_world(f.door(door_id).tile)

	scene.teleport_to_door(door_id, player)
	t.check(scene._door_release_latch.holds(), "arriving through a door arms its release latch")
	scene.process_player(player, 0.0)
	t.check(not scene._transitioning,
			"standing where she arrived does not start a second transition")

	# Stepping one tile off the door and straight back on, while still inside the radius the latch
	# was armed with, fires nothing — an edge-detected "last tile" flag would refire here, since the
	# tile she stepped onto in between differs from the one she arrived on.
	player.global_position = centre + Vector2(InteriorScene.TILE, 0.0)
	scene.process_player(player, 0.0)
	player.global_position = centre
	scene.process_player(player, 0.0)
	t.check(not scene._transitioning, "stepping one tile off the door and straight back fires nothing")

	# The latch is armed with the stated radius: one tile and a half, 48px, past the door's own
	# tile centre.
	player.global_position = centre + Vector2(47.0, 0.0)
	scene.process_player(player, 0.0)
	t.check(scene._door_release_latch.holds(), "47px out, inside the tile-and-a-half radius, still holds")
	player.global_position = centre + Vector2(49.0, 0.0)
	scene.process_player(player, 0.0)
	t.check(not scene._door_release_latch.holds(), "49px out clears the latch")

	# Leaving the radius and returning fires the door again.
	player.global_position = centre
	scene.process_player(player, 0.0)
	t.check(scene._transitioning, "returning to the door after leaving the latch's radius fires it again")

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

# ------------------------------------------------------------ the escape's own events ---
# `InteriorEvents` is the escape's first section: a mouse, a masked man on one stairwell, a fire on
# the other, steam in the basement and the explosions outside. What these check is the placement's
# own promises — the ones the brief makes and a screenshot cannot see.

## *"There might be a fire on one staircase forcing us to use the other staircase (all buildings
## have two egresses)."* Both halves of that sentence: the fire really does close the shaft it is
## in, and it reaches nothing at all in the other one.
##
## Stated over the fire's own blocking reach — `obstructs_radius` plus her own body, which is where
## her centre is stopped — rather than over a number of tiles, so it survives the fire's body being
## retuned.
func _test_the_fire_closes_one_stairwell_and_leaves_the_other(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)

	var fire: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "burning_building":
			fire = instance
	t.check(fire != null, "the escape puts a fire in the building")
	if fire:
		var burning := events.burning_side()
		var other := "right" if burning == "left" else "left"
		t.check(scene.turn_landings("stairwell_%s" % burning).has(
				scene.world_to_tile(fire.global_position)),
				"the fire stands on an interior level approach of the %s shaft" % burning)
		var reach := fire.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS
		t.check(reach > 0.0, "and it is solid at all (%.0fpx)" % reach)
		var shut := 0
		for tile in _shaft_tiles(scene, "stairwell_%s" % burning):
			if scene.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut += 1
		t.check(shut > 0, "it closes ground in its own shaft (%d tiles)" % shut)
		var elsewhere := 0
		for tile in _shaft_tiles(scene, "stairwell_%s" % other):
			if scene.tile_to_world(tile).distance_to(fire.global_position) < reach:
				elsewhere += 1
		t.check(elsewhere == 0, "and reaches nothing in the %s shaft, which stays walkable" % other)
		# The other egress is where the masked man is, which is the whole reason the fire is worth
		# having: the way past a fire is the other stairwell, and somebody is coming up it.
		var man: EventInstance = null
		for instance in events.instances():
			if instance.def.id == "masked_pursuer":
				man = instance
		t.check(man != null, "a masked man is on the stairs")
		if man:
			t.check(_shaft_tiles(scene, "stairwell_%s" % other).has(
					scene.world_to_tile(man.global_position)),
					"on the shaft the fire left open")
	events.free()
	scene.free()

## Every painted grammar cell in one stairwell, including its non-walkable sides.
func _shaft_tiles(scene: InteriorScene, part_id: String) -> Array[Vector2i]:
	return scene.stairwell_tiles(part_id)

## *"Maybe some mice. ... Maybe some steam in the basement etc."* Both stand on the basement's own
## corridor, which has no branches — so they are things she walks past rather than things she may
## happen not to find.
func _test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var walk := scene.basement_walk()
	t.check(walk.size() > 8, "the basement is a walk from its entry to its exit (%d tiles)"
			% walk.size())
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	for id in ["alley_mouse", "basement_steam"]:
		var found: EventInstance = null
		for instance in events.instances():
			if instance.def.id == id:
				found = instance
		t.check(found != null, "'%s' is in the building" % id)
		if found:
			t.check(walk.has(scene.world_to_tile(found.global_position)),
					"'%s' stands on the basement's own corridor" % id)
	events.free()
	scene.free()

## *"The hallway windows that flash when an explosion goes off."* There is no burst on the street
## to see and no arc drawn for the noise, so the flash is the whole of the cue — driven here
## through the same per-frame call the running game makes, rather than by reaching for the swap.
func _test_an_explosion_flashes_every_hallway_window(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	t.check(not scene.windows_are_flashing(), "the windows are dark to begin with")
	events._physics_process(Tuning.FINALE_EXPLOSION_INTERVAL)
	t.check(scene.windows_are_flashing(), "an explosion lights every hallway window")
	scene._process(Tuning.FINALE_WINDOW_FLASH_SECONDS + 0.01)
	t.check(not scene.windows_are_flashing(), "and they go dark again a frame or two later")
	events.free()
	scene.free()
