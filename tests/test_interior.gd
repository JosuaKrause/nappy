extends RefCounted
## `InteriorMap` and `InteriorMapPlan` — the escape scene's one building-wide map, walkability, the
## alternating stairwells of the ten-column grammar, and the doors that teleport between its seven
## parts, all headless: nothing here needs a scene tree except the suites that build
## `InteriorScene` itself.

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
	_test_the_grammar_tiles_are_the_whole_staircase(t)
	_test_a_sideways_press_on_a_flight_walks_its_slope(t)
	_test_a_real_stroller_physically_crosses_both_flight_directions(t)
	_test_every_diagonal_step_has_both_its_pinch_corners_cleared(t)
	_test_the_basement_entry_is_a_straight_level_stair(t)
	_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)
	_test_a_door_release_latch_keeps_a_door_from_retaking_her(t)
	_test_the_rubble_shuts_the_top_floor_off_its_right_stairwell(t)
	_test_the_fire_closes_one_stairwell_and_leaves_the_other(t)
	_test_the_masked_man_runs_the_stairs_rather_than_crossing_them(t)
	_test_a_door_is_always_within_his_own_notice_from_his_line(t)
	_test_another_masked_man_comes_up_the_same_shaft(t)
	_test_the_service_exit_is_reachable_past_the_rubble_the_fire_and_his_line(t)
	_test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t)
	_test_the_vents_blow_on_their_own_clocks_and_give_notice_first(t)
	_test_a_vent_never_closes_around_her(t)
	_test_no_pocket_between_two_vents_outlasts_the_noise(t)
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

## **The reviewed grammar tiles are the whole of a staircase**, and this asks it as a closed list
## rather than as a list of absentees. The deck, rail and landing sources a shaft used to be
## assembled from live in `docs/evidence/archive/rejected-graphics/` now, and the archive is behind
## a `.gdignore`, so a test naming them by path would fail to *load* rather than fail its check —
## which is the wrong answer to "is it bound", and would have to be rewritten every time one more
## picture left the tree.
##
## So: every stair source the TileSet carries is one of the kit, the kit is all of them, and
## nothing standing in the scene draws a stair picture at all. All three halves are needed. The
## first two alone would let a `Sprite2D` overlay rebuild the old assembly over the top; the last
## alone would let a source nothing paints sit in the atlas unnoticed.
func _test_the_grammar_tiles_are_the_whole_staircase(t: Node) -> void:
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

	# Every shaft picture the whole TileSet carries, by the file it was built from. `stairwell_
	# floor.svg` is the level `F` ground and the tread under each `D`; the basement's own
	# front-facing stair and the retained diagonal treads and landing are the rest of the stair
	# vocabulary. Anything else showing up here is an assembly source coming back.
	var kit := {
		"m158_stair_side_upper_e.svg": true, "m158_stair_side_lower_e.svg": true,
		"m158_stair_side_upper_w.svg": true, "m158_stair_side_lower_w.svg": true,
		"m158_stair_side_continue_e.svg": true, "m158_stair_side_continue_w.svg": true,
		"m158_stair_side_block.svg": true, "stair_down.svg": true,
		"stair_flight_e.svg": true, "stair_flight_w.svg": true, "stair_landing.svg": true,
		"stairwell_floor.svg": true,
	}
	var stair_sources := {}
	for kind: InteriorTile.Kind in InteriorTile.Kind.values():
		var id := InteriorTileSet.source_id_for(kind)
		if id < 0:
			continue
		var atlas := tile_set.get_source(id) as TileSetAtlasSource
		var file: String = atlas.texture.resource_path.get_file()
		if not file.begins_with("stair") and not file.begins_with("m158_stair"):
			continue
		stair_sources[file] = true
		t.check(kit.has(file), "the TileSet's stair source '%s' is one of the kit" % file)
	t.check(stair_sources.size() == kit.size(),
			"and the kit is all of them (%d sources against %d named)"
			% [stair_sources.size(), kit.size()])

	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var drawn_stairs := 0
	for child in scene.get_node("Entities").get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var file: String = sprite.texture.resource_path.get_file()
		if file.begins_with("stair") and file != "stairwell_door.svg":
			drawn_stairs += 1
	t.check(drawn_stairs == 0,
			"nothing standing in the scene draws a stair: the ground cells are the staircase (%d)"
			% drawn_stairs)
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

## *"Basement stairs are just not stairs."* What replaced the two diagonal treads is a stair seen
## from the front, and the three things that makes it: the cell between the entry door and the
## corridor is the one-tile `STAIR_DOWN` picture, the walk out of the door is a straight column
## with no diagonal step in it, and the cell is level — `flight_direction()` answers zero, so a
## sideways press on it is a sideways step rather than a slide along a slope.
func _test_the_basement_entry_is_a_straight_level_stair(t: Node) -> void:
	var f := InteriorMap.build()
	var entry := f.door("basement:entry")
	t.check(entry != null, "the basement keeps its entry door")
	if entry == null:
		return
	var stair := entry.tile + Vector2i.UP
	t.check(f.tiles.get(stair) == InteriorTile.Kind.STAIR_DOWN,
			"the cell north of the door is the one-tile front-facing stair")
	t.check(InteriorTile.is_walkable(InteriorTile.Kind.STAIR_DOWN)
			and InteriorTile.flight_direction(InteriorTile.Kind.STAIR_DOWN) == 0,
			"which is walkable and level, so nothing redirects a press along it")
	t.check(InteriorTileSet.source_id_for(InteriorTile.Kind.STAIR_DOWN) >= 0,
			"and it is painted")
	t.check(f.is_walkable(stair + Vector2i.UP),
			"and the corridor is the next cell straight on")
	# And the consequence for the whole building: with the entry straight, no diagonal step
	# anywhere is pinched between two absent corners, so the clearance pass has nothing left to
	# free. `_test_every_diagonal_step_has_both_its_pinch_corners_cleared` is the other half — it
	# checks that a pinch which did appear would be freed; this checks that none does.
	t.check(f.collision_clearance.is_empty(),
			"no cell in the building needs its collision cleared to be crossable (%d do)"
			% f.collision_clearance.size())

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

## *"The top floor right side should be completely blocked off with rubble."*
##
## Three separate claims, and the third is the one the milestone is about. The heap stands on
## painted hallway floor, so what closes those cells is the collapse rather than a hole in the
## map; it fills the corridor's whole depth, so there is no lane past it; and **from her own door,
## walking alone, the right stair door cannot be reached while the left one can** — which is what
## makes the first flight she takes the one the fire is on.
##
## The second and third floors are asked the opposite question in the same breath, because the
## answer to the fire is crossing a hallway to the other shaft: a collapse that closed those too
## would close the section.
func _test_the_rubble_shuts_the_top_floor_off_its_right_stairwell(t: Node) -> void:
	var f := InteriorMap.build()
	t.check(f.rubble.size.x > 0 and f.rubble.size.y > 0,
			"the top floor carries a collapse (%s)" % f.rubble)
	t.check(f.rubble.size.y == 2,
			"it fills both rows of a two-row corridor, so nothing walks round it (%d)"
			% f.rubble.size.y)
	var cells := 0
	for y in range(f.rubble.position.y, f.rubble.end.y):
		for x in range(f.rubble.position.x, f.rubble.end.x):
			var tile := Vector2i(x, y)
			cells += 1
			t.check(f.tiles.has(tile), "the heap at %s stands on painted hallway floor" % tile)
			t.check(not f.is_walkable(tile), "and %s cannot be stood on" % tile)
	t.check(cells == f.rubble.size.x * f.rubble.size.y,
			"every cell of the heap was asked about (%d)" % cells)

	var reached := _flood_fill(f, f.start_tile)
	var right_door: Vector2i = f.door("hallway_third:right").tile
	var left_door: Vector2i = f.door("hallway_third:left").tile
	t.check(not reached.has(right_door),
			"from her own door the right stairwell cannot be entered on the top floor at all")
	t.check(reached.has(left_door),
			"and the left one still can, so the way down starts on the fire's own side")
	for id in ["hallway_second", "hallway_first"]:
		var seen := _flood_fill(f, f.waypoints[id])
		t.check(seen.has(f.door("%s:right" % id).tile) and seen.has(f.door("%s:left" % id).tile),
				"%s still walks between both of its stair doors, so crossing over is possible" % id)

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
		# **The fire and the rubble may never take the same shaft.** The collapse shuts one
		# stairwell off the top floor outright, so a fire on that same side would leave her
		# nothing to walk down from her own door. Asked as the two together rather than as the
		# word "left": the side she can still walk to is the side that burns.
		var f := InteriorMap.build()
		var reached := _flood_fill(f, f.start_tile)
		t.check(reached.has(f.door("hallway_third:%s" % burning).tile),
				"the shaft the fire is in (%s) is the one her own door can still walk to" % burning)
		t.check(not reached.has(f.door("hallway_third:%s" % other).tile),
				"and the shaft the rubble shut (%s) is the one it is not in" % other)
		t.check(scene.inner_floor_approaches("stairwell_%s" % burning).has(
				scene.world_to_tile(fire.global_position)),
				"the fire stands on the inner cell of a level approach in the %s shaft" % burning)
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

## *"The masked man is floating in the stairwell."* His path is the shaft's own walk, so what this
## asks is the two properties that make it one: every step joins two cells she could stand on, and
## a diagonal step has a walkable orthogonal corner — the same pinch rule
## `InteriorMap._mark_diagonal_clearances()` keeps for her, so his line is ground and not the
## background and the solid `c`/`C`/`b` sides between the flights.
##
## **Asked as the tile steps it is made of rather than by sampling the line.** A diagonal step's
## segment passes through the single corner point four cells meet at, where a floored sample is a
## coin toss between two of them — so a sampling test would answer a question about floating-point
## rounding instead of about the staircase. A step between two walkable 8-adjacent cells covers no
## other ground than those two.
##
## And the counterplay the brief gives him — *"going into a corridor and letting them pass"* — is
## measured rather than assumed: every door in his shaft has to sit further from every point of his
## line than `inner_radius`, the radius that takes the baby, or stepping onto a door is not an
## answer to him at all.
func _test_the_masked_man_runs_the_stairs_rather_than_crossing_them(t: Node) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)

	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "masked_pursuer":
			man = instance
	t.check(man != null, "a masked man is on the stairs")
	if man:
		var side := "right" if events.burning_side() == "left" else "left"
		var part := "stairwell_%s" % side
		var steps := man.path
		t.check(steps.size() > 8,
				"his line is the whole shaft rather than two points (%d)" % steps.size())
		t.check(scene.world_to_tile(steps[0]) == f.waypoints["%s:landing_lobby" % part]
				and scene.world_to_tile(steps[steps.size() - 1]) == f.waypoints[part],
				"and it runs landing to landing")
		var off_the_ground := 0
		var pinched := 0
		var not_adjacent := 0
		for i in range(1, steps.size()):
			var here := scene.world_to_tile(steps[i - 1])
			var next := scene.world_to_tile(steps[i])
			if not f.is_walkable(here) or not f.is_walkable(next):
				off_the_ground += 1
				continue
			var step := next - here
			if absi(step.x) > 1 or absi(step.y) > 1 or step == Vector2i.ZERO:
				not_adjacent += 1
				continue
			if step.x != 0 and step.y != 0 \
					and not f.is_walkable(Vector2i(next.x, here.y)) \
					and not f.is_walkable(Vector2i(here.x, next.y)):
				pinched += 1
		t.check(off_the_ground == 0,
				"every cell on his line is walkable (%d were not)" % off_the_ground)
		t.check(not_adjacent == 0,
				"and every step is one cell (%d crossed more)" % not_adjacent)
		t.check(pinched == 0,
				"and every diagonal step has a walkable orthogonal corner (%d did not)" % pinched)

		var nearest_door := INF
		var doors := 0
		for id: String in f.doors:
			if not id.begins_with("%s:" % part):
				continue
			doors += 1
			var at := scene.tile_to_world(f.doors[id].tile)
			for point in steps:
				nearest_door = minf(nearest_door, at.distance_to(point))
		t.check(doors == 4, "the shaft has its four doors to ask about (%d)" % doors)
		t.check(nearest_door > man.def.inner_radius,
				"and the nearest is %.0fpx off his line, clear of the %.0fpx that takes the baby"
				% [nearest_door, man.def.inner_radius])
		print("The masked man's line: %d cells, nearest door %.0fpx off it against a %.0fpx reach"
				% [steps.size(), nearest_door, man.def.inner_radius])
	events.free()
	scene.free()

## The counterplay he is built around, asked from **every** cell of his line rather than from the
## one that happens to be nearest a door.
##
## *"Going into a corridor and letting them pass"* is only an answer if she can reach a corridor in
## the notice he gives her, and he now comes again and again — so a stretch of shaft where the
## nearest door is four seconds' walk away would be a stretch where the answer is not available at
## all, however long the gap between his runs is. The margin is stated as his own
## `telegraph_time` against `Tuning.WALK_SPEED`: he stands still for the whole of it
## (`still_while_telegraphing`), so that is exactly the time she has before he moves at all, and he
## then takes longer still to arrive.
##
## Distances are eight-connected walking distances with a diagonal step costing what a diagonal
## step costs, because the flights are runs of diagonal cells and counting them as unit steps would
## flatter the answer by 40%.
func _test_a_door_is_always_within_his_own_notice_from_his_line(t: Node) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "masked_pursuer":
			man = instance
	t.check(man != null, "a masked man is on the stairs")
	if man:
		var part := "stairwell_%s" % ("right" if events.burning_side() == "left" else "left")
		var doors: Array[Vector2i] = []
		for id: String in f.doors:
			if id.begins_with("%s:" % part):
				doors.append((f.doors[id] as InteriorMapPlan.Door).tile)
		t.check(doors.size() == 4, "the shaft has its four doors to step through (%d)" % doors.size())
		var to_a_door := _walk_distance_to_nearest(f, doors)
		var worst := 0.0
		var worst_at := Vector2i.ZERO
		var asked := 0
		for point in man.path:
			var here := scene.world_to_tile(point)
			if not to_a_door.has(here):
				t.check(false, "no door is walkable from %s on his line" % here)
				continue
			asked += 1
			var reach: float = to_a_door[here]
			if reach > worst:
				worst = reach
				worst_at = here
		t.check(asked == man.path.size(), "every cell of his line was asked (%d)" % asked)
		var seconds := worst / Tuning.WALK_SPEED
		t.check(seconds <= man.def.telegraph_time,
				("the furthest cell of his line, %s, is %.0fpx from a door — %.2fs at %.0fpx/s "
				% [worst_at, worst, seconds, Tuning.WALK_SPEED])
				+ "against the %.2fs he stands still for" % man.def.telegraph_time)
		print("The masked man's notice: worst cell on his line is %.0fpx from a door (%.2fs of %.2fs)"
				% [worst, seconds, man.def.telegraph_time])
	events.free()
	scene.free()

## *"Then the pursuing guy should respawn forcing to switch the side again."*
##
## Driven through `InteriorEvents._physics_process()` and each instance's own `_process()`, the two
## calls the running game makes every frame, with her standing on the shaft's top landing for the
## whole run — inside `masked_pursuer.pursues_within` of its foot, so every man that appears
## notices her and runs rather than waiting at the bottom for ever.
##
## Three contracts, and the second is what keeps the first fair:
##
## - **More than one of him over a section**, or "switch the side again" has nothing behind it.
## - **Every one of them spends his whole notice standing still.** A respawned pursuer that
##   inherited an old instance's clock would arrive at speed, which is the exact thing
##   `still_while_telegraphing` exists to prevent, and no screenshot could ever catch it.
## - **The gap is the stated one**, measured from him leaving the top of the shaft to the next one
##   appearing at the foot, rather than read off the constant.
func _test_another_masked_man_comes_up_the_same_shaft(t: Node) -> void:
	const STEP := 1.0 / 60.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var part := "stairwell_%s" % ("right" if events.burning_side() == "left" else "left")
	var her := scene.tile_to_world(scene.waypoint(part))

	var appeared: Array[float] = []
	var left: Array[float] = []
	var known := {}
	var moved_while_telegraphing := 0
	var first_step_age: Array[float] = []
	var at := 0.0
	while at < Tuning.FINALE_LENGTH_SECONDS:
		events._physics_process(STEP)
		for instance in events.instances():
			instance.player_at = her
			instance.baby_awake = true
			if instance.def.id != "masked_pursuer":
				continue
			var id := instance.get_instance_id()
			if not known.has(id):
				known[id] = appeared.size()
				appeared.append(at)
				first_step_age.append(-1.0)
			var before := instance.global_position
			var was_leaving := instance.is_leaving
			instance._process(STEP)
			var which: int = known[id]
			if not before.is_equal_approx(instance.global_position):
				if instance.is_telegraphing():
					moved_while_telegraphing += 1
				if first_step_age[which] < 0.0:
					first_step_age[which] = instance.chase_age()
			if instance.is_leaving and not was_leaving:
				left.append(at)
		at += STEP

	t.check(appeared.size() >= 3,
			"more than one masked man comes up the shaft over a section (%d)" % appeared.size())
	t.check(moved_while_telegraphing == 0,
			"and none of them moves while he is giving notice (%d frames)" % moved_while_telegraphing)
	var notices := 0
	for i in first_step_age.size():
		if first_step_age[i] < 0.0:
			continue
		notices += 1
		t.check(first_step_age[i] >= EventCatalogue.by_id("masked_pursuer").telegraph_time - STEP,
				"man %d took his first step %.2fs in, after his whole notice" % [i, first_step_age[i]])
	t.check(notices >= 2, "at least two of them actually ran (%d)" % notices)
	var gaps := 0
	for i in range(1, appeared.size()):
		if i - 1 >= left.size():
			break
		gaps += 1
		var gap: float = appeared[i] - left[i - 1]
		t.check(absf(gap - Tuning.FINALE_PURSUER_RESPAWN_SECONDS) <= STEP * 3.0,
				"the next man comes %.2fs after the last one ran out of the top, against %.2fs"
				% [gap, Tuning.FINALE_PURSUER_RESPAWN_SECONDS])
	t.check(gaps > 0, "there were gaps between his runs to measure (%d)" % gaps)
	print("The masked man came %d times in %.0fs; gaps measured: %d"
			% [appeared.size(), Tuning.FINALE_LENGTH_SECONDS, gaps])
	events.free()
	scene.free()

## **The three of them together still leave a way out.** The rubble shuts the top floor's right
## half, the fire shuts a flight of the left shaft, and the masked man runs the right one — and a
## section where any pair of those closed the last route would be unplayable rather than hard.
##
## Asked as a flood from her own door across the whole building, doors included, with **both of the
## things that actually close ground taken out of the walkable set**: the collapse, and every cell
## within the fire's own blocking reach. The masked man closes nothing — he is mobile and carries
## no body — so what he owes is the door margin
## `_test_a_door_is_always_within_his_own_notice_from_his_line` measures, and it is named here
## rather than repeated.
##
## Non-vacuous on purpose: both closures are counted, so a build where the fire stood somewhere
## harmless or the rubble was never laid would fail the guard rather than pass the flood.
func _test_the_service_exit_is_reachable_past_the_rubble_the_fire_and_his_line(t: Node) -> void:
	var f := InteriorMap.build()
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
	t.check(fire != null, "the fire is in the building")
	var shut := {}
	var reach := 0.0
	if fire:
		reach = fire.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS
		for tile: Vector2i in f.tiles:
			if f.is_walkable(tile) and scene.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut[tile] = true
	t.check(shut.size() > 0, "the fire actually closes ground (%d cells)" % shut.size())
	var buried := 0
	for y in range(f.rubble.position.y, f.rubble.end.y):
		for x in range(f.rubble.position.x, f.rubble.end.x):
			if f.tiles.has(Vector2i(x, y)):
				buried += 1
	t.check(buried > 0, "and the rubble actually closes ground (%d cells)" % buried)

	var seen := {f.start_tile: true}
	var queue: Array[Vector2i] = [f.start_tile]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next: Vector2i = here + Vector2i(dx, dy)
				if seen.has(next) or shut.has(next) or not f.is_walkable(next):
					continue
				seen[next] = true
				queue.append(next)
		for id: String in f.doors:
			var door: InteriorMapPlan.Door = f.doors[id]
			if door.tile != here:
				continue
			var target: Vector2i = f.door(door.target_door).tile
			if not seen.has(target) and not shut.has(target):
				seen[target] = true
				queue.append(target)
	t.check(seen.has(f.exit_tile),
			"the service exit is reachable from her own door past a %.0fpx fire and the collapse"
			% reach)
	events.free()
	scene.free()

## Walking distance in px from every walkable cell to the nearest of `targets`, eight-connected,
## with a diagonal step costing `TILE * sqrt(2)` rather than one step — the flights are runs of
## diagonal cells, so counting them as unit steps understates the walk by forty percent.
func _walk_distance_to_nearest(f: InteriorMapPlan, targets: Array[Vector2i]) -> Dictionary:
	var best := {}
	var queue: Array[Vector2i] = []
	for tile in targets:
		best[tile] = 0.0
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var here: Vector2i = queue[head]
		head += 1
		var cost: float = best[here]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := here + Vector2i(dx, dy)
				if not f.is_walkable(next):
					continue
				var step := InteriorScene.TILE * (sqrt(2.0) if dx != 0 and dy != 0 else 1.0)
				if best.has(next) and float(best[next]) <= cost + step:
					continue
				best[next] = cost + step
				queue.append(next)
	return best

## *"Maybe some mice. ... Maybe some steam in the basement etc."* The mouse and every vent stand on
## the basement's own corridor, which has no branches — so they are things she walks past rather
## than things she may happen not to find.
##
## A vent stands on a cell where the corridor is **one tile wide**, and that is what makes it a
## gate: her centre is held `obstructs_radius + PLAYER_BODY_RADIUS` from the middle of the
## passage, and a one-tile passage leaves it only half a tile of play either side of that middle,
## so there is no line past a vent that is blowing. Stated as those two reaches rather than as the
## numbers they come out at today — and asked of each vent's own four neighbours, so a layout that
## widened one of the three would fail here rather than in a playtest.
##
## **And each gate is one she cannot go round**, checked by taking that one cell out of the
## walkable set and asking whether the exit is still reachable from the entry. A gate on a cell
## with a way past it is scenery.
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
	var mouse: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "alley_mouse":
			mouse = instance
	t.check(mouse != null, "the mouse is in the building")
	if mouse:
		t.check(walk.has(scene.world_to_tile(mouse.global_position)),
				"and stands on the basement's own corridor")

	var steam := EventCatalogue.by_id("basement_steam")
	var vents := events.vents()
	t.check(vents.size() == Tuning.FINALE_STEAM_PERIODS.size(),
			"the corridor has one vent per period in `Tuning` (%d)" % vents.size())
	t.check(steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS > InteriorScene.TILE * 0.5,
			"a blowing vent holds her centre %.0fpx out against the %.0fpx half-width of a one-tile "
			% [steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS, InteriorScene.TILE * 0.5]
			+ "passage, so there is no line past one")
	var periods := {}
	var spacing := INF
	for i in vents.size():
		var vent: InteriorEvents.Vent = vents[i]
		periods[vent.period] = true
		var tile := scene.world_to_tile(vent.at)
		t.check(walk.has(tile), "vent %d stands on the walk she has to take (%s)" % [i, tile])
		t.check(vent.at.is_equal_approx(scene.tile_to_world(tile)),
				"vent %d stands on its cell's own centre, where a one-tile passage is symmetric" % i)
		var sideways := scene.is_walkable(tile + Vector2i.LEFT) \
				or scene.is_walkable(tile + Vector2i.RIGHT)
		var lengthways := scene.is_walkable(tile + Vector2i.UP) \
				or scene.is_walkable(tile + Vector2i.DOWN)
		t.check(not (sideways and lengthways),
				"vent %d stands where the corridor is one tile wide, not on a two-row band" % i)
		t.check(not _basement_reaches_the_exit_without(tile),
				"vent %d stands on a cell the walk to the exit cannot go round" % i)
		if i > 0:
			spacing = minf(spacing, vent.at.distance_to((vents[i - 1] as InteriorEvents.Vent).at))
	t.check(periods.size() == vents.size(),
			"and no two vents share a period, so their gaps do not line up by themselves")
	t.check(spacing > (steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS) * 2.0,
			"consecutive vents leave a pocket she fits in (%.0fpx apart)" % spacing)
	# The gap a vent leaves has to be long enough to cross its own reach with time over — the floor
	# `Tuning.FINALE_STEAM_PERIODS`' own doc derives, asked of the numbers rather than restated.
	var crossing := (steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS) * 2.0 / Tuning.WALK_SPEED
	for period: float in Tuning.FINALE_STEAM_PERIODS:
		t.check(period - Tuning.FINALE_STEAM_BLOWS_FOR >= crossing + 1.0,
				("a %.1fs vent leaves %.2fs of open corridor against the %.2fs it takes to walk "
				% [period, period - Tuning.FINALE_STEAM_BLOWS_FOR, crossing])
				+ "through its reach, a margin of %.2fs"
				% (period - Tuning.FINALE_STEAM_BLOWS_FOR - crossing))
	print("Basement vents: %d, %.0fpx apart at the closest, periods %s; a crossing costs %.2fs"
			% [vents.size(), spacing, Tuning.FINALE_STEAM_PERIODS, crossing])
	events.free()
	scene.free()

## Whether the basement's exit is still reachable from its entry with `without` taken out of the
## walkable set — the question that separates a gate from scenery.
func _basement_reaches_the_exit_without(without: Vector2i) -> bool:
	var f := InteriorMap.build()
	var entry: InteriorMapPlan.Door = f.door("basement:entry")
	var seen := {entry.tile: true}
	var queue: Array[Vector2i] = [entry.tile]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := here + Vector2i(dx, dy)
				if next == without or seen.has(next) or not f.is_walkable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen.has(f.exit_tile)

## The corridor as a timing puzzle: *"have them turn off an on in different intervals"*. Driven
## through `InteriorEvents._physics_process()` and each instance's own `_process()`, the two calls
## the running game makes every frame, since a synchronous suite advances no clock of its own.
##
## Three contracts, and none of them is a number this test chose:
##
## - **A blow gives its notice before it closes anything.** `solid_once_it_starts` means the body
##   goes down at the end of the telegraph, and the telegraph has to be longer than walking out
##   from under the body takes.
## - **A vent's own gaps are its own period.** Measured between successive blows rather than read
##   off `Tuning`, so a stagger or a retire that quietly dropped a beat would show.
## - **A vent that is off is not there at all** — no instance, so no body and nothing charged.
func _test_the_vents_blow_on_their_own_clocks_and_give_notice_first(t: Node) -> void:
	const STEP := 1.0 / 60.0
	const WINDOW := 24.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var steam := EventCatalogue.by_id("basement_steam")
	t.check(steam.telegraph_time
			>= (steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS) / Tuning.WALK_SPEED,
			"the notice (%.2fs) covers walking out from under the body (%.2fs)"
			% [steam.telegraph_time,
			(steam.obstructs_radius + Tuning.PLAYER_BODY_RADIUS) / Tuning.WALK_SPEED])

	# Far enough away that nothing is ever withheld for her sake — that half is the next test.
	var far := Vector2(-10000.0, -10000.0)
	var blows := {}
	var solid_before_the_notice := 0
	var seen := {}
	var live := 0.0
	while live < WINDOW:
		events._physics_process(STEP)
		for instance in events.instances():
			if instance.def.id != "basement_steam":
				continue
			instance.player_at = far
			var id := instance.get_instance_id()
			if not seen.has(id):
				seen[id] = true
				if not blows.has(instance.global_position):
					blows[instance.global_position] = [] as Array[float]
				(blows[instance.global_position] as Array[float]).append(live)
				if instance.is_solid():
					solid_before_the_notice += 1
			if instance.is_solid() and instance.age < steam.telegraph_time:
				solid_before_the_notice += 1
			instance._process(STEP)
		live += STEP
	t.check(solid_before_the_notice == 0,
			"no blow was ever solid before its notice was over (%d were)" % solid_before_the_notice)
	t.check(blows.size() == events.vents().size(),
			"every vent blew inside %.0fs and nothing blew anywhere else (%d places)"
			% [WINDOW, blows.size()])
	var off_period := 0
	var beats := 0
	for vent: InteriorEvents.Vent in events.vents():
		var times: Array = blows.get(vent.at, [])
		t.check(times.size() >= 2, "vent at %s blew more than once (%d)" % [vent.at, times.size()])
		for i in range(1, times.size()):
			beats += 1
			if absf((times[i] - times[i - 1]) - vent.period) > STEP * 2.0:
				off_period += 1
	t.check(beats > 0, "there were gaps between blows to measure (%d)" % beats)
	t.check(off_period == 0, "and every one of them is that vent's own period (%d were not)"
			% off_period)
	events.free()
	scene.free()

## *"A vent never turns on with her inside its body."* The one thing a notice, however long, cannot
## be an answer to is walking **into** the thing that is about to close: a body built around her is
## a wall she is inside, and the only ways out of one are teleporting her or deleting it again.
##
## So the body is withheld for as long as she stands in the footprint and goes down the moment she
## is clear — a precondition rather than a repair, and the steam charges her the whole time, so
## standing in a vent is the most expensive way through it rather than a way past it.
func _test_a_vent_never_closes_around_her(t: Node) -> void:
	const STEP := 1.0 / 60.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var steam := EventCatalogue.by_id("basement_steam")
	var vents := events.vents()
	t.check(not vents.is_empty(), "there are vents to stand in")
	if vents.is_empty():
		events.free()
		scene.free()
		return
	var inside: Vector2 = (vents[0] as InteriorEvents.Vent).at

	# Driven only as far as the first blow at that vent getting past its own notice, which is the
	# frame the contract is about: any longer and the instance under test would be a later cycle
	# still telegraphing, and "not solid" would pass for the wrong reason.
	var blow: EventInstance = null
	var live := 0.0
	var charged := 0.0
	var solid_while_she_was_in_it := 0
	var blowing := false
	while live < Tuning.FINALE_LENGTH_SECONDS and not blowing:
		events._physics_process(STEP)
		for instance in events.instances():
			if instance.def.id != "basement_steam" or instance.global_position != inside:
				continue
			blow = instance
			instance.player_at = inside
			instance._process(STEP)
			if instance.is_solid():
				solid_while_she_was_in_it += 1
			charged += instance.contribution_at(inside) * STEP
			blowing = instance.age > steam.telegraph_time and not instance.is_finished
		live += STEP
	t.check(blow != null and blowing, "the vent she is standing in blew, and is past its notice")
	t.check(solid_while_she_was_in_it == 0,
			"and never became solid while she was inside it (%d frames)" % solid_while_she_was_in_it)
	t.check(charged > 0.0,
			"while charging her for standing there (%.0f points of meter)" % charged)
	if blow and blowing:
		# One frame with her clear of the footprint is all it takes.
		blow.player_at = inside + Vector2(1000.0, 0.0)
		blow._process(STEP)
		t.check(blow.is_solid(), "and it closes the corridor the moment she steps out of it")
	events.free()
	scene.free()

## *"No pair of adjacent vents can hold her in a pocket whose both ends are shut for longer than
## she can stand the noise."*
##
## Both halves are asked of the things they are made of rather than of a number written here. The
## pocket's length is the worst overlap of two adjacent vents' solid windows, simulated over the
## whole sequence's own clock; what she can stand is the meter — `Tuning.METER_MAX` — against the
## rate the two fields charge her at the quietest point she can reach, which is the middle of the
## pocket, standing still, where the ground gives nothing back (`EXCITEMENT_DECAY_IDLE` is zero
## recovery). If the vents are far enough apart that the middle is outside both fields, the pocket
## costs nothing and can hold her all day, which is why the rate is measured rather than assumed.
func _test_no_pocket_between_two_vents_outlasts_the_noise(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var steam := EventCatalogue.by_id("basement_steam")
	var vents := events.vents()
	var pairs := 0
	for i in range(1, vents.size()):
		var a: InteriorEvents.Vent = vents[i - 1]
		var b: InteriorEvents.Vent = vents[i]
		pairs += 1
		var shut := _longest_both_shut(a, b, steam)
		var half := a.at.distance_to(b.at) * 0.5
		var rate := 2.0 * Tuning.falloff(half, steam.intensity, steam.inner_radius,
				steam.outer_radius, steam.falloff_power)
		t.check(shut * rate < Tuning.METER_MAX,
				("a pocket %.0fpx wide is shut at both ends for at most %.2fs at %.1f/s, "
				% [half * 2.0, shut, rate])
				+ "which is %.0f of the %.0f the meter holds"
				% [shut * rate, Tuning.METER_MAX])
		print("Steam pocket %d: %.0fpx wide, shut at both ends for %.2fs at %.1f/s (%.0f of %.0f)"
				% [pairs, half * 2.0, shut, rate, shut * rate, Tuning.METER_MAX])
	t.check(pairs > 0, "there were adjacent vents to make a pocket (%d pairs)" % pairs)
	events.free()
	scene.free()

## The longest run of seconds during which both vents are solid at once, over the whole sequence's
## own clock. Sampled rather than solved: the two windows are periodic with different periods and
## the overlap pattern does not repeat inside the clock, so the honest answer is to walk it.
func _longest_both_shut(a: InteriorEvents.Vent, b: InteriorEvents.Vent, steam: EventDef) -> float:
	const STEP := 1.0 / 60.0
	var longest := 0.0
	var run := 0.0
	var at := 0.0
	while at < Tuning.FINALE_LENGTH_SECONDS:
		if _is_shut(a, at, steam) and _is_shut(b, at, steam):
			run += STEP
			longest = maxf(longest, run)
		else:
			run = 0.0
		at += STEP
	return longest

## Whether one vent's body is down at `at` seconds into the section. A vent's cycle is its notice,
## then `Tuning.FINALE_STEAM_BLOWS_FOR` of blowing, then nothing until its own period comes round;
## `until_the_next_blow` is how far into the first cycle it starts.
func _is_shut(vent: InteriorEvents.Vent, at: float, steam: EventDef) -> bool:
	var since := at - (vent.until_the_next_blow - vent.period)
	if since < 0.0:
		return false
	var phase := fmod(since, vent.period)
	return phase >= steam.telegraph_time \
			and phase < steam.telegraph_time + Tuning.FINALE_STEAM_BLOWS_FOR

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
