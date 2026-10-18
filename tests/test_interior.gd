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
	_test_every_tile_of_a_stairwell_steers_every_press_along_its_flight(t)
	_test_her_body_walks_every_flight_at_45_degrees(t)
	_test_every_diagonal_step_has_both_its_pinch_corners_cleared(t)
	_test_the_basement_entry_is_a_straight_level_stair(t)
	_test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)
	_test_a_door_release_latch_keeps_a_door_from_retaking_her(t)
	_test_the_rubble_shuts_the_top_floor_off_its_right_stairwell(t)
	_test_the_fire_closes_one_stairwell_and_leaves_the_other(t)
	_test_the_fire_stands_on_the_second_floor_and_the_walk_is_left_right_left(t)
	_test_the_masked_man_runs_the_stairs_rather_than_crossing_them(t)
	_test_she_has_to_run_to_the_first_floor_door(t)
	_test_another_masked_man_comes_up_the_same_shaft(t)
	_test_the_service_exit_is_reachable_past_the_rubble_the_fire_and_his_line(t)
	_test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t)
	_test_the_vents_blow_on_their_own_clocks_and_give_notice_first(t)
	_test_a_vent_never_closes_around_her(t)
	_test_no_pocket_between_two_vents_outlasts_the_noise(t)
	_test_one_blow_of_steam_costs_forty_to_fifty_points(t)
	_test_the_meter_does_not_fall_in_the_basement(t)
	_test_every_vent_has_its_grate_blowing_or_not(t)
	_test_an_explosion_flashes_every_hallway_window(t)
	_test_the_far_windows_flash_between_the_bangs_and_cost_nothing(t)
	_test_the_building_shows_what_the_city_shows(t)

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
	# A flight's two straight edges (`InteriorScene._blocker_outline()`) are further apart across the
	# slope than her circular body is wide, and each diagonal same-role step has the other role in
	# one orthogonal corner, so no blocker pinches a flight shut.
	t.check(Tuning.PLAYER_BODY_RADIUS * 2.0
			< InteriorScene.FLIGHT_HALF_WIDTH * 2.0 * InteriorScene.TILE / sqrt(2.0),
			"the player fits between a flight's two edges")
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
## Region names, and every `TileSetAtlasSource` sharing the one `interior` page object rather
## than a texture of its own — see `InteriorTileSet`'s own doc for why one tile per source makes
## that safe, proved against this engine version with a throwaway script before it was written
## this way. `InteriorTileSet.region_name_for()` is the lookup; a drawn sprite's own `AtlasTexture`
## (`.atlas`/`.region`) is what a test reads directly now, since it is a live region rather than a
## cropped copy with no `resource_path` of its own.
func _test_the_grammar_tiles_are_the_whole_staircase(t: Node) -> void:
	var expected_names := {
		InteriorTile.Kind.STAIR_TOP_E: &"interior/m158_stair_side_upper_e",
		InteriorTile.Kind.STAIR_MIDDLE_E: &"interior/m158_stair_side_lower_e",
		InteriorTile.Kind.STAIR_CORNER_E: &"interior/m158_stair_side_continue_e",
		InteriorTile.Kind.STAIR_TOP_W: &"interior/m158_stair_side_upper_w",
		InteriorTile.Kind.STAIR_MIDDLE_W: &"interior/m158_stair_side_lower_w",
		InteriorTile.Kind.STAIR_CORNER_W: &"interior/m158_stair_side_continue_w",
		InteriorTile.Kind.STAIR_BLOCK: &"interior/m158_stair_side_block",
	}
	# `InteriorTileSet.build()` reads the group's own live page, so the group has to be acquired
	# for as long as this test keeps the `TileSet` it returns — released at the very end, after
	# the scene built below (which holds its own reference) is freed.
	AtlasLibrary.acquire(&"interior")
	var tile_set := InteriorTileSet.build()
	var page := AtlasLibrary.region(&"interior/stairwell_floor").atlas
	for kind: InteriorTile.Kind in expected_names:
		var name: StringName = expected_names[kind]
		t.check(InteriorTileSet.region_name_for(kind) == name,
				"stair role %d binds its reviewed tile region" % kind)
		var source_id := InteriorTileSet.source_id_for(kind)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		t.check(source != null and source.texture == page,
				"stair role %d's source shares the interior page, not a texture of its own" % kind)
		var rect := AtlasLibrary.region_rect(name)
		t.check(source != null and source.get_tile_texture_region(Vector2i.ZERO) == rect,
				"stair role %d's tile addresses exactly its own region on the shared page" % kind)

	# Every shaft picture the whole TileSet carries, by its own region name. `interior/stairwell_
	# floor` is the level `F` ground and the tread under each `D`; the basement's own
	# front-facing stair and the retained diagonal treads and landing are the rest of the stair
	# vocabulary. Anything else showing up here is an assembly source coming back.
	var kit := {
		&"interior/m158_stair_side_upper_e": true, &"interior/m158_stair_side_lower_e": true,
		&"interior/m158_stair_side_upper_w": true, &"interior/m158_stair_side_lower_w": true,
		&"interior/m158_stair_side_continue_e": true, &"interior/m158_stair_side_continue_w": true,
		&"interior/m158_stair_side_block": true, &"interior/stair_down": true,
		&"interior/stair_flight_e": true, &"interior/stair_flight_w": true,
		&"interior/stair_landing": true, &"interior/stairwell_floor": true,
	}
	var stair_sources := {}
	for kind: InteriorTile.Kind in InteriorTile.Kind.values():
		var id := InteriorTileSet.source_id_for(kind)
		if id < 0:
			continue
		var name := InteriorTileSet.region_name_for(kind)
		var short := String(name).trim_prefix("interior/")
		if not short.begins_with("stair") and not short.begins_with("m158_stair"):
			continue
		stair_sources[name] = true
		t.check(kit.has(name), "the TileSet's stair source '%s' is one of the kit" % name)
	t.check(stair_sources.size() == kit.size(),
			"and the kit is all of them (%d sources against %d named)"
			% [stair_sources.size(), kit.size()])

	# Every region name on the `interior` page that could pass for a stair, other than the
	# stairwell door itself — asked as textures rather than names, since a drawn `Sprite2D`
	# no longer carries a name of its own to compare against, only the `AtlasTexture` region
	# `AtlasLibrary.region()` handed out and cached.
	var forbidden := {}
	for name in AtlasLibrary.region_names():
		if AtlasLibrary.group_of(name) != &"interior" or name == InteriorScene.DOOR_TEXTURE:
			continue
		var short := String(name).trim_prefix("interior/")
		if short.begins_with("stair") or short.begins_with("m158_stair"):
			forbidden[AtlasLibrary.region(name)] = true

	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var drawn_stairs := 0
	for child in scene.get_node("Entities").get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		if forbidden.has(sprite.texture):
			drawn_stairs += 1
	t.check(drawn_stairs == 0,
			"nothing standing in the scene draws a stair: the ground cells are the staircase (%d)"
			% drawn_stairs)
	scene.free()
	AtlasLibrary.release(&"interior")

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

	var hall_tile: Vector2i = f.waypoints["hallway_third"]
	player.global_position = scene.tile_to_world(hall_tile)
	var off_flight := player._redirect_along_a_flight(Vector2(1, 0))
	t.check(off_flight == Vector2(1, 0), "off the stairs, a sideways press is unchanged")

	player.free()
	scene.free()

## *(2026-10-18, inbox #783; inbox #782, the player: on a stair she goes diagonally up or down
## depending on which stair, outside of a stair she goes into the direction.)* Every walkable tile
## of both shafts, each of the eight directions and an analog diagonal, as an exact steering. **On a
## flight tile** any press with a sideways part walks the flight's 45 degrees toward the side
## pressed, down if that is the side the flight descends to and up otherwise, and a pure up or down
## press moves nowhere. **On a level `F` tile**, a landing, every press is left as it was pressed.
## The eight directions a key or a tap gives, as unit presses, and one analog diagonal.
const _PRESSES := {
	"right": Vector2(1, 0), "left": Vector2(-1, 0), "up": Vector2(0, -1), "down": Vector2(0, 1),
	"up-right": Vector2(1, -1), "down-right": Vector2(1, 1), "up-left": Vector2(-1, -1),
	"down-left": Vector2(-1, 1), "analog right-up": Vector2(0.9, -0.3),
}

func _press(name: String) -> Vector2:
	var press: Vector2 = _PRESSES[name]
	return press if name.begins_with("analog") else press.normalized()

func _test_every_tile_of_a_stairwell_steers_every_press_along_its_flight(t: Node) -> void:
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
	var landing_tiles := 0
	for side in ["left", "right"]:
		var origin: Vector2i = f.waypoints["stairwell_%s" % side] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for tile: Vector2i in scene.stairwell_tiles("stairwell_%s" % side):
			var kind: InteriorTile.Kind = f.tiles[tile]
			if not InteriorTile.is_walkable(kind) or kind == InteriorTile.Kind.DOOR:
				continue
			player.global_position = scene.tile_to_world(tile)
			var slope := InteriorTile.flight_direction(kind)
			if slope == 0:
				landing_tiles += 1
			for name: String in _PRESSES:
				var press := _press(name)
				var expected := press
				if slope != 0:
					var toward := signf(press.x)
					expected = Vector2.ZERO if toward == 0.0 \
							else Vector2(toward, slope * toward).normalized() * press.length()
				var got := player._redirect_along_a_flight(press)
				t.check(got.is_equal_approx(expected), "%s shaft %s, %s press: steers %s (got %s)"
						% [side, tile - origin, name, expected, got])
	# Twelve level tiles in each shaft's grammar: two at the top, four on each of the two middle
	# landings, two at the foot.
	t.check(landing_tiles == 24, "every level tile of both shafts was asked (%d)" % landing_tiles)
	player.free()
	scene.free()

## **Her body walks the flight's 45 degrees, not only her steering** *(inbox #783)*. A real carrying
## rig holds one sideways action from a landing tile's centre until she stands on the next landing,
## on every flight of both shafts, down and up. The synchronous runner cannot advance
## `move_and_slide()`'s engine-owned delta, so each call to the real `_physics_process()` supplies
## its redirected, accelerated velocity and this test applies that frame's displacement through
## `move_and_collide()` against the scene's registered blockers, sliding the collision remainder
## along the reported normal.
##
## Sampled every tenth of a second, her displacement while she is on flight tiles heads within
## `_STAIR_HEADING_TOLERANCE` of the flight's own 45 degrees. A landing leaves her press as it is,
## so her first step is level until she stands on the flight. From a landing tile level with the
## flight's end tread that step puts her on the flight's line, and she never touches a wall on it.
## From the row below the flight's end tread (`second_row`) she is a tile under the flight's line,
## and slides along the stair side onto it, so there the samples are pinned once she is two tiles
## along. With full-cell blockers beside the flight the same walks zigzag between flat and 80
## degrees, since the blockers' corners are closer together across the slope than her body is wide.
const _STAIR_HEADING_TOLERANCE := 2.0
const _STAIR_WALKS := [
	# [local start, the next landing's column, action, second_row]
	[Vector2i(1, 2), 8, "move_right", false], [Vector2i(1, 3), 8, "move_right", true],
	[Vector2i(8, 8), 1, "move_left", false],
	[Vector2i(8, 10), 1, "move_left", false], [Vector2i(8, 11), 1, "move_left", true],
	[Vector2i(1, 16), 8, "move_right", false],
	[Vector2i(1, 18), 8, "move_right", false], [Vector2i(1, 19), 8, "move_right", true],
	[Vector2i(8, 24), 1, "move_left", false], [Vector2i(8, 25), 1, "move_left", true],
]

func _test_her_body_walks_every_flight_at_45_degrees(t: Node) -> void:
	const STEP := 1.0 / 60.0
	const MAX_STEPS := 360
	var f := InteriorMap.build()
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
			"the walks use the enabled real 14px player circle")
	t.check((player.get_node("PramCollisionShape2D") as CollisionShape2D).disabled,
			"and the pram body is off while she carries the baby")
	for side in ["left", "right"]:
		var origin: Vector2i = f.waypoints["stairwell_%s" % side] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for walk: Array in _STAIR_WALKS:
			var start: Vector2i = origin + (walk[0] as Vector2i)
			var column: int = origin.x + int(walk[1])
			var action: String = walk[2]
			var second_row: bool = walk[3]
			var label := "%s shaft from %s, %s" % [side, walk[0], action]
			t.check(f.tiles.get(start) == InteriorTile.Kind.STAIRWELL_FLOOR,
					"%s: starts on a landing tile" % label)
			for a in ["move_left", "move_right", "move_up", "move_down"]:
				Input.action_release(a)
			Input.action_press(action)
			player.global_position = scene.tile_to_world(start)
			player.velocity = Vector2.ZERO
			var steps := 0
			var sampled := 0
			var worst := 0.0
			var flight_contacts := 0
			var last := player.global_position
			while steps < MAX_STEPS and not (scene.world_to_tile(player.global_position).x == column
					and scene.slope_dir_at(player.global_position) == 0):
				player._physics_process(STEP)
				var on_flight := scene.slope_dir_at(player.global_position) != 0
				var contacts := _move_real_body_one_step(player, player.velocity * STEP)
				if on_flight:
					flight_contacts += contacts
				steps += 1
				if steps % 6 != 0:
					continue
				var moved := player.global_position - last
				var along := absf(last.x - scene.tile_to_world(start).x)
				if scene.slope_dir_at(last) != 0 and scene.slope_dir_at(player.global_position) != 0 \
						and moved.length() > 1.0 and (not second_row or along >= InteriorScene.TILE * 2.0):
					sampled += 1
					# 45 degrees off the vertical, whichever of the four diagonals.
					var off_vertical := absf(absf(rad_to_deg(moved.angle())) - 90.0)
					worst = maxf(worst, absf(off_vertical - 45.0))
				last = player.global_position
			Input.action_release(action)
			t.check(scene.world_to_tile(player.global_position).x == column,
					"%s: she reaches the next landing (%d steps, ended on %s)"
					% [label, steps, scene.world_to_tile(player.global_position) - origin])
			t.check(sampled >= 10, "%s: the walk had samples on the flight to read (%d)" % [label, sampled])
			t.check(worst <= _STAIR_HEADING_TOLERANCE,
					"%s: her body heads within %.0f degrees of 45 on the flight (worst %.1f)"
					% [label, _STAIR_HEADING_TOLERANCE, worst])
			if not second_row:
				t.check(flight_contacts == 0,
						"%s: and touches no wall on it (%d contacts)" % [label, flight_contacts])
	player.free()
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
## flights by `_test_her_body_walks_every_flight_at_45_degrees()`; repeating those
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

## *"The fire in the house moved one floor down from what it was before breaking the escape
## sequence left right left."* (inbox #741) **The fire stands on the second floor's approach in
## the left shaft whatever the seed**, because it is not rolled. The flights are asked one by one
## over the plan with the fire's blocking reach taken out of the floor. What the fire forces: left
## from the third floor to the second is open, left from the second to the first is shut, right
## from the second to the first is open, so she crosses over at the second. What it leaves open,
## and the map does not forbid: the left shaft from the first floor to the lobby (where the masked
## man coming up the right shaft pushes her) and the right shaft from the first floor to the lobby
## (the way she can also take). A fire on the first floor's approach would leave the second flight
## open and shut the last, which is the walk that lost the crossing.
func _test_the_fire_stands_on_the_second_floor_and_the_walk_is_left_right_left(t: Node) -> void:
	for run_seed in [1, 2, 7, 99, 4242, 12345, 777, 31337, 5, 8675309]:
		var scene := InteriorScene.new()
		t.add_child(scene)
		var events := InteriorEvents.new()
		t.add_child(events)
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed
		events.setup(scene, rng)
		var fire: EventInstance = null
		for instance in events.instances():
			if instance.def.id == "burning_building":
				fire = instance
		t.check(fire != null, "seed %d: the escape puts a fire in the building" % run_seed)
		if fire == null:
			events.free()
			scene.free()
			continue
		var second := scene.waypoint("stairwell_left:landing_second") + Vector2i.DOWN
		t.check(scene.world_to_tile(fire.global_position) == second,
				"seed %d: the fire stands on the second floor's approach %s, at %s"
				% [run_seed, second, scene.world_to_tile(fire.global_position)])
		var f := InteriorMap.build()
		var reach := fire.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS
		var shut := {}
		for tile in f.tiles:
			if scene.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut[tile] = true
		# Each flight is walked between the shaft's own doors, which is where a flight begins and ends
		# and where a door arrival lands clear of the fire.
		var landing := {}
		for side in ["left", "right"]:
			for floor_id in ["third", "second", "first", "lobby"]:
				landing["%s:%s" % [side, floor_id]] = f.door("stairwell_%s:landing_%s" % [side, floor_id]).tile
		t.check(_walks_between(f, shut, landing["left:third"], landing["left:second"]),
				"seed %d: left, from the third floor to the second, is open" % run_seed)
		t.check(not _walks_between(f, shut, landing["left:second"], landing["left:first"]),
				"seed %d: the fire shuts the left flight from the second floor to the first" % run_seed)
		t.check(_walks_between(f, shut, landing["right:second"], landing["right:first"]),
				"seed %d: right, from the second floor to the first, is open" % run_seed)
		t.check(_walks_between(f, shut, landing["left:first"], landing["left:lobby"]),
				"seed %d: left, from the first floor to the lobby, is open" % run_seed)
		t.check(_walks_between(f, shut, landing["right:first"], landing["right:lobby"]),
				"seed %d: the right shaft from the first floor to the lobby is open too" % run_seed)
		events.free()
		scene.free()

## Whether `to` can be walked to from `from` over the plan's ground with `shut` taken out of it,
## never crossing a door.
func _walks_between(f: InteriorMapPlan, shut: Dictionary, from: Vector2i, to: Vector2i) -> bool:
	if shut.has(from) or shut.has(to):
		return false
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		if here == to:
			return true
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var next := here + Vector2i(dx, dy)
				if (dx == 0 and dy == 0) or seen.has(next) or shut.has(next) or not f.is_walkable(next):
					continue
				seen[next] = true
				queue.append(next)
	return false

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

## **She has to run to the door** *(inbox #764, the player: "player should have to run to the
## door"; inbox #782, the player: the radius bigger, not him moved)*. He warns while she is in the
## stairwell and runs his line once she is within `masked_pursuer.charges_within` of him
## (`EventInstance._warn_on_its_line()`). Driven as the running game drives them: her real carrying
## body with the real stair steering and collision, `InteriorEvents._physics_process()` telling him
## where she is, and his own `_process()`. She comes in at his shaft's second-floor door and down
## the landing, and takes the second flight from each of the three rows a player turns onto it from:
## the row level with its head tread, the row below, and the landing tile between the two flights,
## down-left. Once he runs she makes for the first floor's door, on along the flight and up the
## landing into it. **A walker is caught on every one; a runner gets through on every one**, whether
## she was running all along or starts running the moment he does.
func _test_she_has_to_run_to_the_first_floor_door(t: Node) -> void:
	for walk: Array in _SECOND_FLIGHT_TURNS:
		for pace: String in ["walk", "run", "walk-run"]:
			var met := _meet_the_masked_man(t, walk, pace)
			var expected := "caught" if pace == "walk" else "through"
			t.check(met["ran"], "turning onto the flight from row %d at a %s: he runs" % [walk[0], pace])
			t.check(met["outcome"] == expected,
					"turning onto the flight from row %d at a %s: %s (%s, %.0fpx from him at the closest)"
					% [walk[0], pace, expected, met["outcome"], met["closest"]])

## The rows of his shaft's second-floor landing she turns onto the second flight from, local to
## the grammar, and what she holds there.
const _SECOND_FLIGHT_TURNS := [
	[10, ["move_left"]],
	[11, ["move_left"]],
	[9, ["move_left", "move_down"]],
]

## One meeting with the right shaft's masked man: her real body from the shaft's second-floor door
## down the landing to `walk`'s row, then holding its keys, walking (`pace` "walk"), running all the
## way ("run") or walking until he runs and running from then on ("walk-run"); once he runs she
## makes for the first floor's door. Answers whether he ran, the outcome ("through", "caught" or
## "neither") and how near he came.
func _meet_the_masked_man(t: Node, walk: Array, pace: String) -> Dictionary:
	const STEP := 1.0 / 60.0
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
	var origin: Vector2i = f.waypoints["stairwell_right"] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var door: Vector2i = (f.doors["stairwell_right:landing_first"] as InteriorMapPlan.Door).tile
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.slope_dir_at = scene.slope_dir_at
	scene.add_entity(player)
	player.set_physics_process(false)
	player.global_position = scene.tile_to_world(
			(f.doors["stairwell_right:landing_second"] as InteriorMapPlan.Door).tile)
	player.velocity = Vector2.ZERO
	var running := pace == "run"
	_hold_keys(["move_down"], running)
	var met := {"ran": false, "outcome": "neither", "closest": INF}
	var turned := false
	var elapsed := 0.0
	while man != null and elapsed < 20.0:
		player._physics_process(STEP)
		_move_real_body_one_step(player, player.velocity * STEP)
		var her := player.global_position
		var tile := scene.world_to_tile(her)
		events._physics_process(STEP)
		man.player_running = running
		man._process(STEP)
		elapsed += STEP
		if not turned and tile.y - origin.y >= int(walk[0]) and her.y >= scene.tile_to_world(tile).y:
			turned = true
			_hold_keys(walk[1], running)
		if not met["ran"] and not man.is_waiting() and not man.is_telegraphing():
			met["ran"] = true
			if pace == "walk-run":
				running = true
				_hold_keys(walk[1], true)
		if met["ran"]:
			met["closest"] = minf(met["closest"], man.global_position.distance_to(her))
		if man.is_lethal_at(her):
			met["outcome"] = "caught"
			break
		if tile == door:
			met["outcome"] = "through"
			break
		# On the first floor's landing, up into its door.
		if met["ran"] and tile.x == origin.x + 1 and tile.y - origin.y >= 16:
			_hold_keys(["move_up"], running)
	_hold_keys([], false)
	player.free()
	events.free()
	scene.free()
	return met

func _hold_keys(actions: Array, running: bool) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(a)
	for a: String in actions:
		Input.action_press(a)
	if running:
		Input.action_press("run")

## *"Then the pursuing guy should respawn forcing to switch the side again."*
##
## Driven through `InteriorEvents._physics_process()` and each instance's own `_process()`, the two
## calls the running game makes every frame, with her standing on the lobby's door at the shaft's
## foot for the whole run — off his line, clear of his reach, and inside
## `masked_pursuer.charges_within` of where each man appears, so every man that appears notices her,
## warns her and runs rather than waiting at the bottom for ever.
##
## Three contracts, and the second is what keeps the first fair:
##
## - **More than one of him over a section**, or "switch the side again" has nothing behind it.
## - **Every one of them warns her standing still before he runs.** Appearing with her already
##   inside his charge distance, he warns for `Tuning.WARNING_ALONE_MAX` first
##   (`EventInstance._warn_on_its_line()`); a respawned pursuer that inherited an old instance's
##   state would arrive at speed, which is the exact thing `still_while_telegraphing` exists to
##   prevent, and no screenshot could ever catch it.
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
	var plan := InteriorMap.build()
	var her := scene.tile_to_world((plan.doors["%s:landing_lobby" % part] as InteriorMapPlan.Door).tile)

	var appeared: Array[float] = []
	var left: Array[float] = []
	var known := {}
	var moved_while_telegraphing := 0
	var first_step_age: Array[float] = []
	# The age each man stopped waiting at: his warning's own start, since his notice clock is held.
	var warned_at: Array[float] = []
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
				warned_at.append(INF)
			var before := instance.global_position
			var was_leaving := instance.is_leaving
			instance._process(STEP)
			var which: int = known[id]
			if warned_at[which] == INF and not instance.is_waiting():
				warned_at[which] = instance.age
			if not before.is_equal_approx(instance.global_position):
				if instance.is_telegraphing():
					moved_while_telegraphing += 1
				if first_step_age[which] < 0.0:
					first_step_age[which] = instance.age - warned_at[which]
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
		t.check(first_step_age[i] >= Tuning.WARNING_ALONE_MAX - STEP,
				"man %d took his first step %.2fs into his warning, after the second it owes"
				% [i, first_step_age[i]])
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
## no body — so what he owes is the run to the first floor's door
## `_test_she_has_to_run_to_the_first_floor_door` measures, and it is named here rather than
## repeated.
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

## *"The steam should have a stronger impact."* / *"steam should be 40 to 50."* (inbox #741, #747)
## **One blow, stood in, costs her 40 to 50 points of a hundred awake** (22 to 28 asleep), measured
## on the row itself: an instance of the blow is run from its first frame to its last with her
## standing `STAND_AT` out from the vent, and every frame's `contribution_at()` is summed. 30px is
## where a vent holds her centre (`STEAM_VENT_BODY` + her own body), which is where she waits at
## the gate and the nearest she can be to a blow, so the dearest a blow costs her.
func _test_one_blow_of_steam_costs_forty_to_fifty_points(t: Node) -> void:
	const STEP := 1.0 / 60.0
	const STAND_AT := 30.0
	var steam := EventCatalogue.by_id("basement_steam")
	var blow := EventInstance.new()
	# Set up before it joins the tree, the order `InteriorEvents._spawn()` uses: `_ready()` reads
	# the def.
	blow.setup(steam, Vector2.ZERO)
	t.add_child(blow)
	var cost := 0.0
	var elapsed := 0.0
	while not blow.is_finished and elapsed < 20.0:
		blow.player_at = Vector2(STAND_AT, 0.0)
		blow._process(STEP)
		cost += blow.contribution_at(Vector2(STAND_AT, 0.0)) * STEP
		elapsed += STEP
	print("One blow of steam, stood %.0fpx from the vent for %.2fs: %.1f points awake, %.1f asleep"
			% [STAND_AT, elapsed, cost, cost * Tuning.SLEEPING_SENSITIVITY])
	t.check(cost >= 40.0 and cost <= 50.0,
			"one blow costs 40 to 50 points awake at %.0fpx (%.1f)" % [STAND_AT, cost])
	blow.free()

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

## *"Let's not replenish the meter in the basement it's a tense situation."* (inbox #765) The
## scene answers the baby's `decay_multiplier()` with `Tuning.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER`
## (nothing) at every tile of the basement's corridor and with an ordinary 1.0 in every other part
## of the building, so a blow's points stay on the meter until she is out.
func _test_the_meter_does_not_fall_in_the_basement(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var walk := scene.basement_walk()
	t.check(not walk.is_empty(), "the basement has a corridor to walk")
	var worst := 0.0
	for tile in walk:
		worst = maxf(worst, scene.decay_multiplier(scene.tile_to_world(tile)))
	t.check(worst == 0.0 and Tuning.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER == 0.0,
			"no tile of the basement corridor gives any decay back (%.2f)" % worst)
	for part in InteriorMap.PARTS:
		if part == "basement":
			continue
		var at := scene.tile_to_world(scene.waypoint(part))
		t.check(scene.decay_multiplier(at) == 1.0,
				"%s is ordinary ground for the meter" % part)
	var f := InteriorMap.build()
	t.check(scene.decay_multiplier(scene.tile_to_world(f.door("lobby:basement").tile)) == 1.0,
			"the lobby's basement door is still ordinary ground")
	t.check(scene.decay_multiplier(scene.tile_to_world(f.door("basement:entry").tile)) == 0.0,
			"the basement's entry tile gives nothing back")
	scene.free()

## **A vent that is there all the time, blowing or not, is what a player can plan around.** Each
## vent's floor grate lies on its site from the moment the section is placed, before the first blow
## and between every two after it, and a blow's cloud rises out of that grate rather than somewhere
## of its own:
##
## - the grate is centred on the vent's own point, which is where every blow stands, so the cloud
##   frames' bottom-centre anchor is the grate's middle;
## - the grate is ground: drawn over the floor tiles and under the layer she and every blow stand
##   in, so she walks over it and each blow's cloud is drawn over it, never the other way round;
## - a restart lays each vent's grate once, not a second time over the first.
func _test_every_vent_has_its_grate_blowing_or_not(t: Node) -> void:
	const STEP := 1.0 / 60.0
	const WINDOW := 12.0
	var grate_size := AtlasLibrary.native_size(StringName(EventInstance.STEAM_GRATE))
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var ground := scene.get_node_or_null("Ground") as CanvasItem
	t.check(ground != null, "the building has its floor tiles to lie on")
	# She joins the same layer every blow does (`InteriorScene.add_entity()`), so a stand-in there
	# answers where she is drawn without building the whole stroller.
	var her := Node2D.new()
	scene.add_entity(her)
	t.check(events.vents().size() == Tuning.FINALE_STEAM_PERIODS.size(),
			"the basement has its vents (%d)" % events.vents().size())
	for vent: InteriorEvents.Vent in events.vents():
		var grate := vent.grate
		t.check(is_instance_valid(grate) and grate.is_inside_tree(),
				"the vent at %s has a grate lying in the building" % vent.at)
		if not is_instance_valid(grate):
			continue
		t.check(grate.position == vent.at and grate.centered,
				"the grate is centred on its vent's own point (%s, %s)" % [grate.position, vent.at])
		t.check(grate.texture != null and Vector2i(grate.texture.get_size()) == grate_size,
				"the grate is drawn with its own picture")
		t.check(_drawn_z(grate) < _drawn_z(her),
				"the grate is drawn under her, not sorted against her (z %d against %d)"
				% [_drawn_z(grate), _drawn_z(her)])
		if ground:
			t.check(_drawn_z(grate) == _drawn_z(ground) and grate.get_parent() == ground.get_parent()
					and grate.get_index() > ground.get_index(),
					"and lies on the floor tiles rather than under them")

	var far := Vector2(-10000.0, -10000.0)
	var blowing_frames := {}
	var quiet_frames := {}
	var grates_missing := 0
	var under_its_grate := 0
	var seen := {}
	var live := 0.0
	while live < WINDOW:
		events._physics_process(STEP)
		var blowing := {}
		for instance in events.instances():
			if instance.def.id != "basement_steam":
				continue
			instance.player_at = far
			blowing[instance.global_position] = instance
			instance._process(STEP)
		for vent: InteriorEvents.Vent in events.vents():
			if not is_instance_valid(vent.grate) or not vent.grate.is_inside_tree():
				grates_missing += 1
				continue
			var blow: EventInstance = blowing.get(vent.at)
			var tally: Dictionary = blowing_frames if blow else quiet_frames
			tally[vent.at] = int(tally.get(vent.at, 0)) + 1
			if not blow or seen.has(blow.get_instance_id()):
				continue
			seen[blow.get_instance_id()] = true
			if _drawn_z(blow) <= _drawn_z(vent.grate):
				under_its_grate += 1
		live += STEP
	t.check(seen.size() > events.vents().size(),
			"the vents blew over %.0fs (%d blows)" % [WINDOW, seen.size()])
	for vent: InteriorEvents.Vent in events.vents():
		t.check(int(blowing_frames.get(vent.at, 0)) > 0 and int(quiet_frames.get(vent.at, 0)) > 0,
				"the vent at %s was seen both blowing (%d frames) and between blows (%d)"
				% [vent.at, int(blowing_frames.get(vent.at, 0)), int(quiet_frames.get(vent.at, 0))])
	t.check(grates_missing == 0,
			"no vent was ever without its grate (%d frames were)" % grates_missing)
	t.check(under_its_grate == 0,
			"every blow's cloud is drawn over its grate (%d were not)" % under_its_grate)

	var old_grates: Array[Sprite2D] = []
	for vent: InteriorEvents.Vent in events.vents():
		old_grates.append(vent.grate)
	events.restart()
	var lying := 0
	for vent: InteriorEvents.Vent in events.vents():
		if is_instance_valid(vent.grate) and not vent.grate.is_queued_for_deletion():
			lying += 1
	t.check(lying == events.vents().size(),
			"a restart lays every vent's grate again (%d of %d)" % [lying, events.vents().size()])
	var left_over := 0
	for grate in old_grates:
		if is_instance_valid(grate) and not grate.is_queued_for_deletion():
			left_over += 1
	t.check(left_over == 0, "and takes the old ones up rather than laying two (%d stayed)"
			% left_over)
	events.free()
	scene.free()

## The `z_index` a canvas item is drawn at: its own, plus every parent's for as long as each is
## relative to the one above it. Godot keeps this sum to itself, and it is what decides whether a
## thing on the floor can be drawn over somebody standing on it.
func _drawn_z(item: CanvasItem) -> int:
	var z := 0
	var node: Node = item
	while node is CanvasItem:
		var canvas_item := node as CanvasItem
		z += canvas_item.z_index
		if not canvas_item.z_as_relative:
			break
		node = node.get_parent()
	return z

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
	t.check(scene.windows_are_flashing(), "an explosion lights the hallway windows")
	# *"All windows always need to flash together. A single window cannot flash by itself."*
	t.check(scene.windows_lit() == scene.window_count(),
			"every one of the %d, together (%d lit)" % [scene.window_count(), scene.windows_lit()])
	scene._process(Tuning.FINALE_WINDOW_FLASH_SECONDS + 0.01)
	t.check(not scene.windows_are_flashing(), "and they go dark again a frame or two later")
	t.check(scene.windows_lit() == 0, "all of them, with none left lit (%d)" % scene.windows_lit())
	events.free()
	scene.free()

## *"The flashing lights in the window are too rare"*, and *"do a biased random distribution
## between 100ms and 5s between flashes where the mean is 1.3s and the rest of the curve is
## smooth."*
##
## Four things, and each is a separate way the answer could be wrong.
##
## - **The draw itself.** A few thousand values off the real function: all inside the stated
##   bounds, a mean on the stated mean, and a median under it — which is what "biased" means and
##   is the one property a symmetric mistake would still pass the mean check with.
## - **The rate on screen.** Over a minute of the section, far more flashes than the explosions
##   alone ever gave, which is what the player actually asked for. Stated against
##   `Tuning.FINALE_EXPLOSION_INTERVAL` rather than as a count written here.
## - **All of them or none of them.** *(2026-09-19: "all windows always need to flash together. a
##   single window cannot flash by itself.")* Checked on every frame of the minute, so an overlap
##   between two flashes 0.1s apart cannot leave one lit or blink the corridor dark for a frame.
## - **The cost, which is none.** Excitement in this building is a pure query over
##   `InteriorEvents.instances()` — nothing writes at the baby — so "adds nothing to the meter" is
##   exactly "creates no instance", and that is asked directly rather than through an integral
##   that a stray source elsewhere in the building could muddy.
##
## And the same seed twice, since the waits come off the section's own seeded stream.
func _test_the_far_windows_flash_between_the_bangs_and_cost_nothing(t: Node) -> void:
	const STEP := 1.0 / 60.0
	const SPAN := 60.0
	const DRAWS := 4000
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	t.check(scene.window_count() > 0, "the building has hallway windows (%d)" % scene.window_count())

	# The distribution, asked of the function the running game draws from.
	var waits: Array[float] = []
	var outside := 0
	var total := 0.0
	for _draw in DRAWS:
		var wait := events._wait_for_the_next_distant_flash()
		if wait < Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS \
				or wait > Tuning.FINALE_DISTANT_FLASH_MAX_SECONDS:
			outside += 1
		waits.append(wait)
		total += wait
	waits.sort()
	var mean := total / float(DRAWS)
	var median: float = waits[DRAWS / 2]
	t.check(outside == 0,
			"every wait is inside [%.1fs, %.1fs] (%d of %d were not)"
			% [Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS, Tuning.FINALE_DISTANT_FLASH_MAX_SECONDS,
			outside, DRAWS])
	t.check(absf(mean - Tuning.FINALE_DISTANT_FLASH_MEAN_SECONDS) <= 0.05,
			"the mean wait is %.3fs against the %.2fs the shape constant is solved for"
			% [mean, Tuning.FINALE_DISTANT_FLASH_MEAN_SECONDS])
	t.check(median < mean,
			"and the median (%.3fs) is under it, which is the bias toward short gaps" % median)
	print("Distant flash waits over %d draws: mean %.3fs, median %.3fs, longest %.2fs"
			% [DRAWS, mean, median, waits[DRAWS - 1]])
	events.restart()

	var flashes := 0
	var when: Array[float] = []
	var was := false
	var half_lit := 0
	var lit_while_dark := 0
	var at := 0.0
	while at < SPAN:
		events._physics_process(STEP)
		var now := scene.windows_are_flashing()
		if now and not was:
			when.append(at)
			flashes += 1
		was = now
		if now and scene.windows_lit() != scene.window_count():
			half_lit += 1
		if not now and scene.windows_lit() != 0:
			lit_while_dark += 1
		scene._process(STEP)
		at += STEP
	var bangs := int(SPAN / Tuning.FINALE_EXPLOSION_INTERVAL)
	t.check(flashes > bangs * 5,
			"far more flashes than the bangs alone gave (%d in %.0fs against %d explosions)"
			% [flashes, SPAN, bangs])
	t.check(half_lit == 0,
			"every window lights on every flash, none on its own (%d frames with some dark)"
			% half_lit)
	t.check(lit_while_dark == 0,
			"and none is left lit once a flash is over (%d frames)" % lit_while_dark)
	print("Window flashes over %.0fs: %d, against %d explosions" % [SPAN, flashes, bangs])

	var instances := events.instances().size()
	events._light_the_far_windows(Tuning.FINALE_DISTANT_FLASH_MAX_SECONDS + 0.01)
	t.check(events.instances().size() == instances,
			"a distant flash creates nothing, so it can charge nothing (%d instances either side)"
			% instances)
	t.check(scene.windows_lit() == scene.window_count(),
			"and lights the whole corridor, exactly as a bang does (%d of %d)"
			% [scene.windows_lit(), scene.window_count()])

	# The same seed, the same night: a second building flashes at the same instants.
	var twin_scene := InteriorScene.new()
	t.add_child(twin_scene)
	var twin := InteriorEvents.new()
	t.add_child(twin)
	var twin_rng := RandomNumberGenerator.new()
	twin_rng.seed = 4242
	twin.setup(twin_scene, twin_rng)
	# `restart()` reseeds the flash stream from the run seed, which is what makes this a comparison
	# of two nights rather than of two points in one stream — the loop above is run after its own
	# `restart()` for the same reason, since the draws taken for the distribution came first.
	twin.restart()
	var twin_when: Array[float] = []
	var twin_was := false
	at = 0.0
	while at < SPAN:
		twin._physics_process(STEP)
		var now := twin_scene.windows_are_flashing()
		if now and not twin_was:
			twin_when.append(at)
		twin_was = now
		twin_scene._process(STEP)
		at += STEP
	t.check(twin_when == when,
			"the same seed flashes at the same instants (%d against %d)"
			% [twin_when.size(), when.size()])

	twin.free()
	twin_scene.free()
	events.free()
	scene.free()

## *"The escape shouldn't behave any different than the rest of the game."* The screen-edge badge,
## the excitement halo and the debug view read the building's `InteriorEvents` the way they read a
## day's `EventManager` — the one question each asks being `instances()` — and none of them needs
## a crowd. Each is driven here against the real building rather than a stand-in, so what is
## checked is that the masked man coming up a stairwell raises a badge, the fire she is standing
## beside wears a rim, and the building's walls are bodies the bounding-box layer traces.
func _test_the_building_shows_what_the_city_shows(t: Node) -> void:
	const STEP := 1.0 / 60.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var fire: EventInstance = null
	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "burning_building":
			fire = instance
		elif instance.def.id == "masked_pursuer":
			man = instance
	t.check(fire != null and man != null, "the building has its fire and its masked man")
	if not fire or not man:
		events.free()
		scene.free()
		return

	# **The halo**, with no crowd at all: a source that has landed points on her reads a rim.
	var player := Node2D.new()
	t.add_child(player)
	var baby := Baby.new()
	var halo := ExcitementHalo.new()
	t.add_child(halo)
	halo.setup(events, null, player, baby)
	player.global_position = fire.global_position + Vector2(fire.def.inner_radius * 0.5, 0.0)
	# Past its notice, the way `InteriorEvents` hands an explosion over: a fire still telegraphing
	# emits nothing, and a rim on it would be the cue marking a thing that costs her nothing.
	fire.resume(fire.def.telegraph_time, 0.0, INF)
	t.check(fire.contribution_at(player.global_position) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"standing beside the fire, it reaches her")
	fire.accumulate_landed(20.0)
	halo._process(STEP)
	t.check(fire.holds_a_halo() and fire._halo._target_alpha > 0.0,
			"the fire she is standing beside wears a rim, read from InteriorEvents with no crowd")
	t.check(not man.holds_a_halo(),
			"and the masked man on the other shaft, charging her nothing, holds no rim at all")

	# **The badge.** Placed far off any screen and walked in towards her, so the only thing that
	# can raise it is his own approach — the same test a fire engine coming down a street meets.
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.size = ScreenOrientation.DESIGN_SIZE
	edge.setup(events, player)
	var far := Vector2(-40000.0, -40000.0)
	player.global_position = far
	man.global_position = far + Vector2(man.def.outer_radius + 400.0, 0.0)
	edge._measure(0.1)
	man.global_position -= Vector2(30.0, 0.0)
	edge._measure(0.1)
	var announced: Array[String] = []
	for badge in edge.announcing():
		announced.append(badge["id"])
	t.check(announced.has("masked_pursuer"),
			"the masked man closing on her from off screen raises a badge (%s)" % str(announced))

	# **The debug view.** The world is the building, so the bounding-box layer walks its walls and
	# the fire's body; no crowd, no props, and nothing about either is a crash.
	var stroller := Stroller.new()
	var layers := DebugLayers.new()
	t.add_child(layers)
	layers.setup(events, null, scene, stroller)
	var bodies := DebugLayers.collision_nodes_under(scene).size()
	t.check(bodies > 0, "the building's own bodies are found (%d)" % bodies)
	t.check(layers.body_outline_count() == bodies + DebugLayers.collision_nodes_under(stroller).size(),
			"and the layer outlines every one of them, with no crowd to add a strike box")
	t.check(layers._live().size() == events.instances().size(),
			"its fields and shadows read the same instances InteriorEvents holds")

	layers.free()
	stroller.free()
	edge.free()
	halo.free()
	baby.free()
	player.free()
	events.free()
	scene.free()
