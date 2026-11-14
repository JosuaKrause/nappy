extends RefCounted
## `InteriorMap` and `InteriorMapPlan` — the escape scene's one building-wide map, walkability, the
## alternating stairwells of the ten-column grammar, and the doors that teleport between its seven
## parts, all headless: nothing here needs a scene tree except the suites that build
## `InteriorScene` itself.

const BuildingEvents := preload("res://tests/building_events.gd")
const InteriorRig := preload("res://tests/interior_rig.gd")
const GivenPlanner := preload("res://tests/given_planner.gd")
const BakedRegions := preload("res://tests/baked_regions.gd")
## The building's seven parts, each of which starts where its waypoint stands.
const PARTS: Array[String] = [
	"hallway_third", "hallway_second", "hallway_first",
	"stairwell_left", "stairwell_right", "lobby", "basement",
]

## How many times real time a door's fade runs at when a test lets it (`_let_the_fade_run()`).
const FADE_SCALE := 6.0

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
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
	_test_the_escape_building_is_dark_by_part(t)
	_test_collision_blocks_exactly_the_non_walkable_ground(t)
	_test_the_grammar_tiles_are_the_whole_staircase(t)
	await _test_a_sideways_press_on_a_flight_walks_its_slope(t)
	await _test_every_tile_of_a_stairwell_steers_every_press_along_its_flight(t)
	_test_every_diagonal_step_has_both_its_pinch_corners_cleared(t)
	_test_every_door_is_drawn_under_her(t)
	_test_the_basement_entry_is_a_straight_level_stair(t)
	await _test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t)
	await _test_a_door_release_latch_keeps_a_door_from_retaking_her(t)
	_test_the_rubble_shuts_the_top_floor_off_its_right_stairwell(t)
	_test_the_fire_closes_one_stairwell_and_leaves_the_other(t)
	_test_the_fire_stands_on_the_second_floor_and_the_walk_is_left_right_left(t)
	_test_the_masked_man_runs_the_stairs_rather_than_crossing_them(t)
	await _test_his_catch_ends_the_section_with_what_struck_her(t)
	_test_his_run_stops_at_the_building_walls(t)
	_test_the_service_exit_is_reachable_past_the_rubble_the_fire_and_his_line(t)
	_test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t)
	await _test_the_vents_blow_on_their_own_clocks_and_give_notice_first(t)
	await _test_a_vent_never_closes_around_her(t)
	_test_no_pocket_between_two_vents_outlasts_the_noise(t)
	_test_one_blow_of_steam_costs_forty_to_fifty_points(t)
	_test_the_meter_does_not_fall_in_the_basement(t)
	await _test_every_vent_has_its_grate_blowing_or_not(t)
	_test_the_floor_decals_are_drawn_under_her(t)
	await _test_an_explosion_flashes_every_hallway_window(t)
	await _test_the_far_windows_flash_between_the_bangs_and_cost_nothing(t)
	await _test_the_building_shows_what_the_city_shows(t)

func _test_the_map_builds(t: TestRunner) -> void:
	var f := InteriorMap.build()
	t.check(f != null and not f.floor_tiles().is_empty(), "the map builds a non-empty tile grid")
	for part in PARTS:
		t.check(f.has_waypoint(part) and InteriorMap.part_at(f.waypoint(part)) == part,
				"the map carries a waypoint for '%s', in that part" % part)

## The first 22 rows are the player's literal corrected diagram. The last four finish the same
## alternation only through the fourth door's two-cell level approach. This checks the authored
## rows and the parsed cells in both shafts, so a correct-looking constant that is not what the map
## paints cannot pass.
func _test_the_stairwell_grammar_is_exact_in_both_shafts(t: TestRunner) -> void:
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
	for side: String in ["left", "right"]:
		var part := "stairwell_%s" % side
		var origin: Vector2i = f.waypoint(part) - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for y in expected.size():
			for x in expected[y].length():
				var symbol := expected[y].substr(x, 1)
				var at := origin + Vector2i(x, y)
				if symbol == ".":
					t.check(not f.has_floor_at(at), "%s row %d column %d stays background" % [part, y, x])
				elif symbol == "D":
					t.check(f.floor_kind_at(at) == InteriorTile.Kind.DOOR,
							"%s row %d column %d is its corridor door" % [part, y, x])
				else:
					t.check(f.has_floor_at(at),
							"%s row %d column %d paints '%s'" % [part, y, x, symbol])

## Walkability and drawing are properties of the symbol roles, not of a second sparse flight map.
## The walkable roles have TileSet sources because they are the surface; the three side roles also
## have sources but remain solid.
func _test_stair_symbols_define_walkability_and_art(t: TestRunner) -> void:
	for symbol: String in ["F", "t", "m", "T", "M"]:
		var kind := _kind_painted_for(symbol)
		t.check(InteriorTile.is_walkable(kind), "'%s' is walkable" % symbol)
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "'%s' has a live tile source" % symbol)
	t.check(InteriorTile.is_walkable(InteriorTile.Kind.DOOR), "'D' is a walkable transition")
	for symbol: String in ["b", "c", "C"]:
		var kind := _kind_painted_for(symbol)
		t.check(not InteriorTile.is_walkable(kind), "'%s' is not walkable" % symbol)
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "'%s' is still painted" % symbol)
	t.check(not InteriorTile.is_walkable(InteriorTile.Kind.NONE), "'.' is not walkable")

## The kind the map painted for a stair symbol: the cell the left shaft's grammar puts that symbol on,
## read off the built map (`InteriorMap.build()`), the one place the symbol means anything.
func _kind_painted_for(symbol: String) -> InteriorTile.Kind:
	var f := InteriorMap.build()
	var origin: Vector2i = f.waypoint("stairwell_left") - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	for y in InteriorMap.STAIRWELL_ROWS.size():
		var x: int = InteriorMap.STAIRWELL_ROWS[y].find(symbol)
		if x >= 0:
			return f.floor_kind_at(origin + Vector2i(x, y))
	return InteriorTile.Kind.NONE

func _test_every_door_has_the_counterpart_it_claims(t: TestRunner) -> void:
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
	t.check(f.door_ids().size() == expected_pairs.size() * 2,
			"the building keeps exactly the nine external door pairs")
	for pair: Array in expected_pairs:
		var a: InteriorMapPlan.Door = f.door(pair[0])
		var b: InteriorMapPlan.Door = f.door(pair[1])
		t.check(a != null and b != null, "door pair '%s' / '%s' exists" % pair)
		if a == null or b == null:
			continue
		t.check(a.target_door == b.id and b.target_door == a.id,
				"'%s' and '%s' remain exact counterparts" % pair)
	for id: String in f.door_ids():
		var door: InteriorMapPlan.Door = f.door(id)
		var back: InteriorMapPlan.Door = f.door(door.target_door)
		t.check(back != null, "door '%s' -> '%s' exists" % [id, door.target_door])
		if back == null:
			continue
		t.check(back.target_door == id, "'%s' and '%s' are each other's counterpart" % [id, door.target_door])

func _test_the_exit_and_the_entrance_are_what_they_claim(t: TestRunner) -> void:
	var f := InteriorMap.build()
	t.check(f.exit_position().x >= 0, "the map records an exit tile")
	t.check(f.floor_kind_at(f.exit_position()) == InteriorTile.Kind.EMERGENCY_EXIT,
			"the basement's own exit tile is the emergency exit kind")
	t.check(f.is_walkable(f.exit_position()), "the emergency exit is walkable")

	t.check(not f.entrance_positions().is_empty(), "the map records a barricaded entrance")
	if f.entrance_positions().is_empty():
		return
	var entrance: Vector2i = f.entrance_positions()[0]
	t.check(f.wall_kind_at(entrance) == InteriorTile.Kind.ENTRANCE_DOOR,
			"the lobby's own entrance is the entrance door kind")

## A few representative points between parts — the gap `InteriorMap._SLOT_STRIDE` leaves, since
## nothing is ever placed there.
func _test_the_ground_between_parts_is_not_walkable(t: TestRunner) -> void:
	var f := InteriorMap.build()
	for x: int in [30, 94, 158, 222, 286, 350]:
		var tile := Vector2i(x, 0)
		t.check(not f.is_walkable(tile), "the gap tile %s between two parts is not walkable" % tile)

## A flood fill that crosses doors, starting at her own door on the third-floor hallway — every
## walkable cell in the whole building must be reachable from it once a door is allowed to jump.
func _test_every_walkable_tile_is_reachable_from_her_door_through_the_doors(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var seen := {f.start_position(): true}
	var queue: Array[Vector2i] = [f.start_position()]
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
		for id: String in f.door_ids():
			var door: InteriorMapPlan.Door = f.door(id)
			if door.tile != here:
				continue
			var target: Vector2i = f.door(door.target_door).tile
			if not seen.has(target):
				seen[target] = true
				queue.append(target)
	var walkable := 0
	for tile: Vector2i in f.floor_tiles():
		if f.is_walkable(tile):
			walkable += 1
	t.check(seen.size() == walkable,
			"every walkable tile is reachable from her door through the doors (%d of %d)" % [seen.size(), walkable])

## The other half of the same guarantee: **without** crossing a door, a flood fill from one part's
## own waypoint never reaches another part's — the gaps `InteriorMap._SLOT_STRIDE` leaves are wide
## enough that walking alone, with no door, cannot cross from one part to the next.
func _test_no_two_parts_are_reachable_by_walking_alone(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var components: Dictionary[String, Dictionary] = {}
	for part in PARTS:
		components[part] = _flood_fill(f, f.waypoint(part))
	for part in PARTS:
		for other in PARTS:
			if other == part:
				continue
			t.check(not components[part].has(f.waypoint(other)),
					"'%s' cannot be reached from '%s' by walking alone, without a door" % [other, part])

## Every walkable kind that is drawn as ground rather than as a standing sprite or a decal needs an
## atlas source, or `InteriorScene.build()` would silently skip painting that cell — `PUDDLE` is the
## one walkable kind that is never a `tiles` entry of its own (see its own doc), so it is the one
## exclusion.
func _test_the_tileset_carries_every_walkable_ground_kind(t: TestRunner) -> void:
	for kind: InteriorTile.Kind in InteriorTile.Kind.values():
		if kind == InteriorTile.Kind.PUDDLE or not InteriorTile.is_walkable(kind):
			continue
		t.check(InteriorTileSet.source_id_for(kind) >= 0, "walkable ground kind %d has a TileSet source" % kind)

## Builds the TileSet for real (needs `Tuning.TILE_SIZE`, an autoload — see this suite's own doc
## for why it runs as a scene) and paints the whole map, checking the ground layer actually holds a
## cell for every tile the plan says is walkable ground.
func _test_the_scene_paints_the_whole_map(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var ground: TileMapLayer = scene.get_node("Ground")
	var painted := 0
	for tile: Vector2i in f.floor_tiles():
		if InteriorTileSet.source_id_for(f.floor_kind_at(tile)) >= 0:
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
func _test_collision_blocks_exactly_the_non_walkable_ground(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var blocked := {}
	for body: Node2D in scene.get_node("Collision").get_children():
		blocked[scene.map.world_to_tile(body.position)] = true
	for tile: Vector2i in f.floor_tiles():
		if f.is_walkable(tile):
			t.check(not blocked.has(tile), "walkable tile %s is unblocked" % tile)
		else:
			t.check(blocked.has(tile), "painted non-walkable tile %s is blocked" % tile)
	t.check(blocked.has(Vector2i(30, 0)), "a gap tile between two parts is blocked")
	for side: String in ["left", "right"]:
		var part := "stairwell_%s" % side
		var origin: Vector2i = f.waypoint(part) - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
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
			< InteriorMapPlan.FLIGHT_HALF_WIDTH * 2.0 * InteriorScene.TILE / sqrt(2.0),
			"the player fits between a flight's two edges")
	var paired_steps := 0
	for tile: Vector2i in f.floor_tiles():
		var kind: InteriorTile.Kind = f.floor_kind_at(tile)
		var direction := InteriorTile.flight_direction(kind)
		if direction == 0:
			continue
		var next := tile + Vector2i(direction, 1)
		if f.floor_kind_at(next) != kind:
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
## this way. A source's own tile region on the page (`get_tile_texture_region()`) is what says which
## region it draws, as a drawn sprite's own `AtlasTexture` (`.atlas`/`.region`) does, since either is
## a live region rather than a cropped copy with no `resource_path` of its own.
func _test_the_grammar_tiles_are_the_whole_staircase(t: TestRunner) -> void:
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
	# the scene built below (which holds its own reference, on the same library) is freed.
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"interior")
	var tile_set := InteriorTileSet.build(atlas)
	var page := atlas.region(&"interior/stairwell_floor").atlas
	for kind: InteriorTile.Kind in expected_names:
		var name: StringName = expected_names[kind]
		var source_id := InteriorTileSet.source_id_for(kind)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		t.check(source != null and source.texture == page,
				"stair role %d's source shares the interior page, not a texture of its own" % kind)
		var rect := AtlasTable.baked().region_rect(name)
		t.check(source != null and source.get_tile_texture_region(Vector2i.ZERO) == rect,
				"stair role %d binds its reviewed tile, exactly its own region on the shared page"
				% kind)

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
	var interior_names := BakedRegions.on(&"interior")
	var name_at: Dictionary = {}
	for name in interior_names:
		name_at[AtlasTable.baked().region_rect(name)] = name
	var stair_sources := {}
	for kind: InteriorTile.Kind in InteriorTile.Kind.values():
		var id := InteriorTileSet.source_id_for(kind)
		if id < 0 or not tile_set.has_source(id):
			continue
		var tile_source := tile_set.get_source(id) as TileSetAtlasSource
		var name: StringName = name_at.get(tile_source.get_tile_texture_region(Vector2i.ZERO), &"")
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
	# the library's `region()` handed out and cached — the scene is handed the same library.
	var forbidden := {}
	for name in interior_names:
		if name == InteriorScene.DOOR_TEXTURE:
			continue
		var short := String(name).trim_prefix("interior/")
		if short.begins_with("stair") or short.begins_with("m158_stair"):
			forbidden[atlas.region(name)] = true

	var scene := InteriorScene.new()
	scene.atlas = atlas
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
	atlas.release(&"interior")

## The switchback's own redirection: a sideways press on a diagonal flight walks its slope rather
## than the screen axis it was pressed on — *(2026-09-10, playtest 55: "holding right or left on
## the switchback stairs moves the player diagonally")*. A real carrying `Stroller` stands on a flight
## tile of a real `InteriorScene` (so `slope_dir_at` answers for actual flight tiles rather than a
## hand-built stand-in), a key is held, one physics tick passes, and the heading she is steering by
## (`Stroller.steering_direction()`, what `PosterWalls` asks of her) is the walk's.
func _test_a_sideways_press_on_a_flight_walks_its_slope(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var roles: Array[InteriorTile.Kind] = [
		InteriorTile.Kind.STAIR_TOP_E,
		InteriorTile.Kind.STAIR_MIDDLE_E,
		InteriorTile.Kind.STAIR_TOP_W,
		InteriorTile.Kind.STAIR_MIDDLE_W,
	]
	var tiles: Array[Vector2i] = []
	for kind: InteriorTile.Kind in roles:
		var role_tile := Vector2i(-1, -1)
		for tile: Vector2i in f.floor_tiles():
			if f.floor_kind_at(tile) == kind:
				role_tile = tile
				break
		t.check(role_tile.x >= 0, "flight role %d exists in the shaft" % kind)
		tiles.append(role_tile)
	tiles.append(f.waypoint("hallway_third"))
	var walkers := _strollers_on(scene, tiles)
	var steering := {}
	for press: String in ["right", "left", "up"]:
		steering[press] = (await _steer(t, scene, walkers, tiles, press))["headings"]
	for index in roles.size():
		var kind := roles[index]
		var right: Vector2 = steering["right"][index]
		var left: Vector2 = steering["left"][index]
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
		for redirected: Vector2 in [right, left]:
			t.check(is_equal_approx(absf(redirected.x), absf(redirected.y)),
					"flight role %d gives equal horizontal and vertical components" % kind)
			t.check(is_equal_approx(redirected.length(), 1.0),
					"flight role %d normalizes the diagonal to ordinary movement speed" % kind)
		var vertical: Vector2 = steering["up"][index]
		t.check(vertical == Vector2.ZERO, "flight role %d ignores pure vertical input" % kind)
	var off_flight: Vector2 = steering["right"][roles.size()]
	t.check(off_flight == Vector2(1, 0), "off the stairs, a sideways press is unchanged")

	for walker in walkers:
		walker.free()
	scene.free()

## The eight directions a key or a tap gives, as the held actions and how far each is held, and one
## analog diagonal: the joystick's, held part of the way.
const _PRESSES := {
	"right": {"move_right": 1.0}, "left": {"move_left": 1.0},
	"up": {"move_up": 1.0}, "down": {"move_down": 1.0},
	"up-right": {"move_up": 1.0, "move_right": 1.0}, "down-right": {"move_down": 1.0, "move_right": 1.0},
	"up-left": {"move_up": 1.0, "move_left": 1.0}, "down-left": {"move_down": 1.0, "move_left": 1.0},
	"analog right-up": {"move_right": 0.9, "move_up": 0.3},
}

## What a key or a tap gives, as a heading: a unit vector in its direction. The analog press is
## whatever the engine makes of its strengths, which is asked of her (`input_she_moves_by()`).
const _UNIT_PRESSES := {
	"right": Vector2(1, 0), "left": Vector2(-1, 0), "up": Vector2(0, -1), "down": Vector2(0, 1),
	"up-right": Vector2(1, -1), "down-right": Vector2(1, 1), "up-left": Vector2(-1, -1),
	"down-left": Vector2(-1, 1),
}

## A real carrying `Stroller` on each of `tiles` of `scene`, drawn in its entities layer as she is.
## She is out of the way of her neighbours' collisions: only the steering is read of them.
func _strollers_on(scene: InteriorScene, tiles: Array[Vector2i]) -> Array[Stroller]:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var walkers: Array[Stroller] = []
	for tile in tiles:
		var walker: Stroller = packed.instantiate()
		walker.carrying = true
		walker.set_map(scene.map)
		scene.add_entity(walker)
		walker.collision_layer = 0
		walker.collision_mask = 0
		walkers.append(walker)
	return walkers

## Puts each of `walkers` on its tile of `tiles`, holds the keys of the press `name` (`_PRESSES`),
## lets one physics tick pass and returns `{"press", "headings"}`: the press the held keys make as
## she moves by it (`input_she_moves_by()`) and the heading each is steering by, in order, with the
## keys let go again. Every walker starts the tick where she was put, so what she steers by is what
## her own `_physics_process()` read of the held keys and the ground under her.
func _steer(t: TestRunner, scene: InteriorScene, walkers: Array[Stroller], tiles: Array[Vector2i],
		name: String) -> Dictionary:
	for index in walkers.size():
		walkers[index].reset_at(scene.map.tile_to_world(tiles[index]))
	var held: Dictionary = _PRESSES[name]
	for action: String in held:
		Input.action_press(action, held[action])
	await PhysicsTicks.pass_ticks(t, 1)
	var headings: Array[Vector2] = []
	for walker in walkers:
		headings.append(walker.steering_direction())
	var press := walkers[0].input_she_moves_by()
	for action: String in held:
		Input.action_release(action)
	return {"press": press, "headings": headings}

## *(2026-10-18, inbox #783 in minty-lemur; inbox #782 in minty-lemur, the player: on a stair she goes diagonally up or down
## depending on which stair, outside of a stair she goes into the direction.)* Every walkable tile
## of both shafts, each of the eight directions and an analog diagonal, as an exact steering. **On a
## flight tile** any press with a sideways part walks the flight's 45 degrees toward the side
## pressed, down if that is the side the flight descends to and up otherwise, and a pure up or down
## press moves nowhere. **On a level `F` tile**, a landing, every press is left as it was pressed. Each press is held on real input and read of a real `Stroller` on every tile at once
## after one physics tick (`Stroller.steering_direction()`).
func _test_every_tile_of_a_stairwell_steers_every_press_along_its_flight(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var tiles: Array[Vector2i] = []
	var origins: Array[Vector2i] = []
	var sides: Array[String] = []
	for side: String in ["left", "right"]:
		var origin: Vector2i = f.waypoint("stairwell_%s" % side) - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for tile: Vector2i in scene.map.stairwell_tiles("stairwell_%s" % side):
			var kind: InteriorTile.Kind = f.floor_kind_at(tile)
			if not InteriorTile.is_walkable(kind) or kind == InteriorTile.Kind.DOOR:
				continue
			tiles.append(tile)
			origins.append(origin)
			sides.append(side)
	var walkers := _strollers_on(scene, tiles)
	var landing_tiles := 0
	for tile in tiles:
		if InteriorTile.flight_direction(f.floor_kind_at(tile)) == 0:
			landing_tiles += 1
	for name: String in _PRESSES:
		var steered := await _steer(t, scene, walkers, tiles, name)
		var headings: Array[Vector2] = steered["headings"]
		var press: Vector2 = steered["press"]
		if _UNIT_PRESSES.has(name):
			t.check(press.is_equal_approx((_UNIT_PRESSES[name] as Vector2).normalized()),
					"the %s press is held as its direction (%s)" % [name, press])
		for index in tiles.size():
			var slope := InteriorTile.flight_direction(f.floor_kind_at(tiles[index]))
			var expected := press
			if slope != 0:
				var toward := signf(press.x)
				expected = Vector2.ZERO if toward == 0.0 \
						else Vector2(toward, slope * toward).normalized() * press.length()
			var got := headings[index]
			t.check(got.is_equal_approx(expected), "%s shaft %s, %s press: steers %s (got %s)"
					% [sides[index], tiles[index] - origins[index], name, expected, got])
	# Twelve level tiles in each shaft's grammar: two at the top, four on each of the two middle
	# landings, two at the foot.
	t.check(landing_tiles == 24, "every level tile of both shafts was asked (%d)" % landing_tiles)
	for walker in walkers:
		walker.free()
	scene.free()

## **Every door in the building is drawn under her** *(the player, 2026-10-18: the escape's door
## graphics should always be under her)*: the stairwell doors, the open and the apartments'
## thresholds, the emergency exit, the lift door and the entrance. Asked of the canvas the way the
## engine orders it, by her absolute z against each door picture's, and for one in her own z and
## y-sorted with her, by its foot against hers, with her standing on every walkable tile within a
## tile of each door, at the tile's centre and at its four edges as near as her body lets her.
func _test_every_door_is_drawn_under_her(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	scene.add_entity(player)
	var door_textures := [InteriorScene.DOOR_TEXTURE, InteriorScene.OPEN_THRESHOLD_TEXTURE,
			InteriorScene.APARTMENT_THRESHOLD_TEXTURE, InteriorScene.EMERGENCY_EXIT_TEXTURE,
			InteriorScene.LIFT_DOOR_TEXTURE, InteriorScene.ENTRANCE_DOOR_TEXTURE]
	var pictures := {}
	for name: StringName in door_textures:
		pictures[scene.atlas.region(name)] = name
	var doors: Array[Sprite2D] = []
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Sprite2D and pictures.has((node as Sprite2D).texture):
			doors.append(node)
	var expected := f.door_ids().size() + f.locked_threshold_positions().size() + (1 if f.exit_position().x >= 0 else 0)
	for at: Vector2i in f.wall_tiles():
		if f.wall_kind_at(at) in [InteriorTile.Kind.LIFT_DOOR, InteriorTile.Kind.ENTRANCE_DOOR]:
			expected += 1
	t.check(doors.size() == expected, "every door picture is found (%d of %d)" % [doors.size(), expected])
	var reach := Tuning.PLAYER_BODY_RADIUS
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(0, -0.5 * InteriorScene.TILE + reach),
			Vector2(0, 0.5 * InteriorScene.TILE - reach), Vector2(-0.5 * InteriorScene.TILE + reach, 0),
			Vector2(0.5 * InteriorScene.TILE - reach, 0)]
	var asked := 0
	var over := 0
	for door: Sprite2D in doors:
		var foot := scene.map.world_to_tile(door.global_position - Vector2(0, 1))
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var tile := foot + Vector2i(dx, dy)
				if not f.is_walkable(tile):
					continue
				for offset: Vector2 in offsets:
					player.global_position = scene.map.tile_to_world(tile) + offset
					asked += 1
					if not _drawn_over(player, door):
						over += 1
						t.check(false, "%s at %s is drawn over her at %s"
								% [pictures[door.texture], door.global_position, player.global_position])
	t.check(over == 0 and asked > doors.size(),
			"every door is under her wherever she stands beside one (%d positions asked)" % asked)
	player.free()
	scene.free()

## Whether `top` draws over `under`: a higher absolute z, or the same z in the same y-sorted parent
## with its foot no higher.
static func _drawn_over(top: CanvasItem, under: CanvasItem) -> bool:
	var a := _absolute_z(top)
	var b := _absolute_z(under)
	if a != b:
		return a > b
	var parent := top.get_parent() as Node2D
	if parent and parent == under.get_parent() and parent.y_sort_enabled:
		return (top as Node2D).global_position.y >= (under as Node2D).global_position.y
	return false

static func _absolute_z(item: CanvasItem) -> int:
	var z := 0
	var node: Node = item
	while node is CanvasItem:
		z += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:
			break
		node = node.get_parent()
	return z

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
func _test_every_diagonal_step_has_both_its_pinch_corners_cleared(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var diagonals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var checked := 0
	for t1: Vector2i in f.floor_tiles():
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
			t.check(not f.has_floor_at(corner_a) and not f.has_floor_at(corner_b),
					"a required pinch clearance never overrides a painted stair-side cell")
			t.check(f.has_collision_clearance_at(corner_a),
					"the absent corner %s pinching %s to %s is cleared" % [corner_a, t1, t2])
			t.check(f.has_collision_clearance_at(corner_b),
					"the absent corner %s pinching %s to %s is cleared" % [corner_b, t1, t2])
	# A guard that the sweep found real diagonal adjacencies to check — every flight in both
	# shafts plus the basement's own entry flight.
	t.check(checked > 0, "the map has at least one diagonal adjacency to check (got %d)" % checked)

## *"Basement stairs are just not stairs."* What replaced the two diagonal treads is a stair seen
## from the front, and the three things that makes it: the cell between the entry door and the
## corridor is the one-tile `STAIR_DOWN` picture, the walk out of the door is a straight column
## with no diagonal step in it, and the cell is level — `flight_direction()` answers zero, so a
## sideways press on it is a sideways step rather than a slide along a slope.
func _test_the_basement_entry_is_a_straight_level_stair(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var entry := f.door("basement:entry")
	t.check(entry != null, "the basement keeps its entry door")
	if entry == null:
		return
	var stair := entry.tile + Vector2i.UP
	t.check(f.floor_kind_at(stair) == InteriorTile.Kind.STAIR_DOWN,
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
	var cleared := 0
	for y in f.size_in_tiles().y:
		for x in f.size_in_tiles().x:
			cleared += 1 if f.has_collision_clearance_at(Vector2i(x, y)) else 0
	t.check(cleared == 0,
			"no cell in the building needs its collision cleared to be crossable (%d do)" % cleared)

## **Stands her on each door in turn and lets the building do what it does under her**: `transition_at()`
## names what is under her and `process_player()` (the call the run flow makes every frame) starts the
## fade to black, puts her at the counterpart door under it and lifts the fade again, all on real frames
## (`_let_the_fade_run()`). The real input, slope redirection and collision sweep are separately covered
## on complete east and west flights by `_test_her_body_walks_every_flight_at_45_degrees()`; repeating
## those here would double the work rather than test anything new. **Not vacuous**: every assertion
## below reads the player's own `global_position` back after the fade, not a value this test computed
## itself, so a door that silently failed to move her would fail the very next line.
func _test_a_rig_walks_both_stairwells_from_her_door_to_the_exit(t: TestRunner) -> void:
	var f := InteriorMap.build()
	for side: String in ["left", "right"]:
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
		player.global_position = scene.map.tile_to_world(f.door("hallway_third:%s" % side).tile)
		var to_shaft := scene.map.transition_at(scene.map.world_to_tile(player.global_position))
		t.check(to_shaft.get("kind") == "door", "the %s stair door is a door transition" % side)
		scene.map.process_player(player, 0.0)
		await _let_the_fade_run(t)
		t.check(player.global_position == scene.map.tile_to_world(f.door("%s:landing_third" % part).tile),
				"the %s walk arrives at its own top landing's own door" % side)

		# The level `F` approach at each floor remains on the stair route while its `D` is one cell
		# beside it. Walking past a floor therefore does not trigger its corridor transition.
		var landing_ids: Array[String] = [
			"landing_third", "landing_second", "landing_first", "landing_lobby",
		]
		for index in landing_ids.size() - 1:
			var from: Vector2i = f.waypoint("%s:%s" % [part, landing_ids[index]])
			var to: Vector2i = f.waypoint("%s:%s" % [part, landing_ids[index + 1]])
			t.check(_shortest_path_length(f, from, to) > 0,
					"%s has a continuous walk from %s to %s"
					% [part, landing_ids[index], landing_ids[index + 1]])
		for id: String in ["landing_third", "landing_second", "landing_first"]:
			var landing_tile: Vector2i = f.waypoint("%s:%s" % [part, id])
			var mid_result := scene.map.transition_at(landing_tile)
			t.check(mid_result.is_empty(), "%s: passing %s's `F` approach triggers nothing" % [part, id])

		var bottom_door := f.door("%s:landing_lobby" % part)
		player.global_position = scene.map.tile_to_world(bottom_door.tile)
		var to_lobby := scene.map.transition_at(scene.map.world_to_tile(player.global_position))
		t.check(to_lobby.get("kind") == "door", "the %s shaft's own bottom door is a door transition" % side)
		scene.map.process_player(player, 0.0)
		await _let_the_fade_run(t)
		t.check(player.global_position == scene.map.tile_to_world(f.door("lobby:%s" % side).tile),
				"the %s walk reaches the lobby's own door" % side)

		# The lobby's own basement door, to the basement, to the exit.
		player.global_position = scene.map.tile_to_world(f.door("lobby:basement").tile)
		var to_basement := scene.map.transition_at(scene.map.world_to_tile(player.global_position))
		t.check(to_basement.get("kind") == "door", "the lobby's basement notch is a door transition")
		scene.map.process_player(player, 0.0)
		await _let_the_fade_run(t)
		t.check(player.global_position == scene.map.tile_to_world(f.door("basement:entry").tile),
				"the %s walk reaches the basement's own entry door" % side)

		player.global_position = scene.map.tile_to_world(f.exit_position())
		var exit_result := scene.map.transition_at(scene.map.world_to_tile(player.global_position))
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
## Asked through what the latch does to the door, which is all the building lets be seen: a door
## that fires starts the fade to black (`FadeLayer/Fade`, which `_start_door_transition()` raises
## on the frames after), and one the latch holds starts nothing. Drives
## the map's `process_player()` (`WorldMap.process_player()`), the call the running game makes, and
## lets real frames pass after each so the fade has the frames it needs to show. She arrives by
## walking onto the counterpart door and letting the fade run, as in the game. `player` is a plain
## `Node2D` rather than a `Stroller`: a door puts anything that is not a `Stroller` at the door by a
## bare `global_position` assignment, and nothing here touches physics or the camera.
func _test_a_door_release_latch_keeps_a_door_from_retaking_her(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var player := Node2D.new()
	t.add_child(player)

	var door_id := "hallway_third:left"
	var centre := scene.map.tile_to_world(f.door(door_id).tile)

	player.global_position = scene.map.tile_to_world(scene.map.door(scene.map.door(door_id).target_door).tile)
	scene.map.process_player(player, 0.0)
	await _let_the_fade_run(t)
	scene.map.process_player(player, 0.0)
	t.check(not await _fires_a_transition(t, scene),
			"arriving through a door arms its release latch: standing where she arrived does not start a second transition")

	# Stepping one tile off the door and straight back on, while still inside the radius the latch
	# was armed with, fires nothing — an edge-detected "last tile" flag would refire here, since the
	# tile she stepped onto in between differs from the one she arrived on.
	player.global_position = centre + Vector2(InteriorScene.TILE, 0.0)
	scene.map.process_player(player, 0.0)
	player.global_position = centre
	scene.map.process_player(player, 0.0)
	t.check(not await _fires_a_transition(t, scene), "stepping one tile off the door and straight back fires nothing")

	# The latch is armed with the stated radius: one tile and a half, 48px, past the door's own
	# tile centre.
	player.global_position = centre + Vector2(47.0, 0.0)
	scene.map.process_player(player, 0.0)
	player.global_position = centre
	scene.map.process_player(player, 0.0)
	t.check(not await _fires_a_transition(t, scene),
			"47px out, inside the tile-and-a-half radius, still holds: back on the door fires nothing")
	player.global_position = centre + Vector2(49.0, 0.0)
	scene.map.process_player(player, 0.0)

	# Leaving the radius and returning fires the door again.
	player.global_position = centre
	scene.map.process_player(player, 0.0)
	t.check(await _fires_a_transition(t, scene),
			"49px out clears the latch: returning to the door after leaving the latch's radius fires it again")

	player.free()
	scene.free()

## Lets `count` drawn frames pass: a view that works on a frame (the halo, the screen edge) has
## taken them when this returns, each being a frame the engine runs every node's `_process()` in.
func _frames(t: Node, count: int) -> void:
	for _frame in count:
		await t.get_tree().process_frame

## Lets a door's whole fade run on real frames: to black, the move to the counterpart door under it,
## and back, at `FADE_SCALE` times real time (`PhysicsTicks.pass_ticks()`), with a margin.
func _let_the_fade_run(t: TestRunner) -> void:
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(InteriorScene.FADE_SECONDS * 2.0 + 0.2,
			FADE_SCALE), Callable(), FADE_SCALE)

## Whether the fade to black of `scene` has begun after real frames have passed: a door fired, or
## the service exit did, since both raise it.
func _fires_a_transition(t: Node, scene: InteriorScene) -> bool:
	for _frame in 3:
		await t.get_tree().process_frame
	return (scene.get_node("FadeLayer/Fade") as ColorRect).modulate.a > 0.0

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
func _test_the_rubble_shuts_the_top_floor_off_its_right_stairwell(t: TestRunner) -> void:
	var f := InteriorMap.build()
	t.check(f.rubble_area().size.x > 0 and f.rubble_area().size.y > 0,
			"the top floor carries a collapse (%s)" % f.rubble_area())
	t.check(f.rubble_area().size.y == 2,
			"it fills both rows of a two-row corridor, so nothing walks round it (%d)"
			% f.rubble_area().size.y)
	var cells := 0
	for y in range(f.rubble_area().position.y, f.rubble_area().end.y):
		for x in range(f.rubble_area().position.x, f.rubble_area().end.x):
			var tile := Vector2i(x, y)
			cells += 1
			t.check(f.has_floor_at(tile), "the heap at %s stands on painted hallway floor" % tile)
			t.check(not f.is_walkable(tile), "and %s cannot be stood on" % tile)
	t.check(cells == f.rubble_area().size.x * f.rubble_area().size.y,
			"every cell of the heap was asked about (%d)" % cells)

	var reached := _flood_fill(f, f.start_position())
	var right_door: Vector2i = f.door("hallway_third:right").tile
	var left_door: Vector2i = f.door("hallway_third:left").tile
	t.check(not reached.has(right_door),
			"from her own door the right stairwell cannot be entered on the top floor at all")
	t.check(reached.has(left_door),
			"and the left one still can, so the way down starts on the fire's own side")
	for id: String in ["hallway_second", "hallway_first"]:
		var seen := _flood_fill(f, f.waypoint(id))
		t.check(seen.has(f.door("%s:right" % id).tile) and seen.has(f.door("%s:left" % id).tile),
				"%s still walks between both of its stair doors, so crossing over is possible" % id)

# ------------------------------------------------------------ the escape's own events ---
# The escape's first section's events (`BuildingPlan`, run by the day's `EventManager` on the
# building's map): a mouse, a masked man on one stairwell, a fire on the other, steam in the basement
# and the explosions outside. What these check is the placement's
# own promises — the ones the brief makes and a screenshot cannot see.

## *"There might be a fire on one staircase forcing us to use the other staircase (all buildings
## have two egresses)."* Both halves of that sentence: the fire really does close the shaft it is
## in, and it reaches nothing at all in the other one.
##
## Stated over the fire's own blocking reach — `obstructs_radius` plus her own body, which is where
## her centre is stopped — rather than over a number of tiles, so it survives the fire's body being
## retuned.
func _test_the_fire_closes_one_stairwell_and_leaves_the_other(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())

	var fire: EventInstance = null
	for instance in events.instances():
		if instance.row_id() == "burning_building":
			fire = instance
	t.check(fire != null, "the escape puts a fire in the building")
	if fire:
		var burning := BuildingPlan.BURNING_SIDE
		var other := "right" if burning == "left" else "left"
		# **The fire and the rubble may never take the same shaft.** The collapse shuts one
		# stairwell off the top floor outright, so a fire on that same side would leave her
		# nothing to walk down from her own door. Asked as the two together rather than as the
		# word "left": the side she can still walk to is the side that burns.
		var f := InteriorMap.build()
		var reached := _flood_fill(f, f.start_position())
		t.check(reached.has(f.door("hallway_third:%s" % burning).tile),
				"the shaft the fire is in (%s) is the one her own door can still walk to" % burning)
		t.check(not reached.has(f.door("hallway_third:%s" % other).tile),
				"and the shaft the rubble shut (%s) is the one it is not in" % other)
		# The inner cell of a level approach in the burning shaft: the cell below the second or the
		# first floor's landing, one cell further in than its door.
		var approaches: Array[Vector2i] = []
		for landing_id: String in ["landing_second", "landing_first"]:
			var landing: Vector2i = scene.map.waypoint("stairwell_%s:%s" % [burning, landing_id])
			if scene.map.is_walkable(landing + Vector2i.DOWN):
				approaches.append(landing + Vector2i.DOWN)
		t.check(approaches.has(scene.map.world_to_tile(fire.global_position)),
				"the fire stands on the inner cell of a level approach in the %s shaft" % burning)
		var reach := fire.row().obstructs_within() + Tuning.PLAYER_BODY_RADIUS
		t.check(reach > 0.0, "and it is solid at all (%.0fpx)" % reach)
		var shut := 0
		for tile in _shaft_tiles(scene, "stairwell_%s" % burning):
			if scene.map.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut += 1
		t.check(shut > 0, "it closes ground in its own shaft (%d tiles)" % shut)
		var elsewhere := 0
		for tile in _shaft_tiles(scene, "stairwell_%s" % other):
			if scene.map.tile_to_world(tile).distance_to(fire.global_position) < reach:
				elsewhere += 1
		t.check(elsewhere == 0, "and reaches nothing in the %s shaft, which stays walkable" % other)
		# The other egress is where the masked man is, which is the whole reason the fire is worth
		# having: the way past a fire is the other stairwell, and somebody is coming up it.
		var man: EventInstance = null
		for instance in events.instances():
			if instance.row_id() == "masked_pursuer":
				man = instance
		t.check(man != null, "a masked man is on the stairs")
		if man:
			t.check(_shaft_tiles(scene, "stairwell_%s" % other).has(
					scene.map.world_to_tile(man.global_position)),
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
func _test_the_fire_stands_on_the_second_floor_and_the_walk_is_left_right_left(t: TestRunner) -> void:
	for run_seed: int in [1, 2, 7, 99, 4242, 12345, 777, 31337, 5, 8675309]:
		var scene := InteriorScene.new()
		t.add_child(scene)
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed
		var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
		var fire: EventInstance = null
		for instance in events.instances():
			if instance.row_id() == "burning_building":
				fire = instance
		t.check(fire != null, "seed %d: the escape puts a fire in the building" % run_seed)
		if fire == null:
			events.free()
			scene.free()
			continue
		var second := scene.map.waypoint("stairwell_left:landing_second") + Vector2i.DOWN
		t.check(scene.map.world_to_tile(fire.global_position) == second,
				"seed %d: the fire stands on the second floor's approach %s, at %s"
				% [run_seed, second, scene.map.world_to_tile(fire.global_position)])
		var f := InteriorMap.build()
		var reach := fire.row().obstructs_within() + Tuning.PLAYER_BODY_RADIUS
		var shut := {}
		for tile: Vector2i in f.floor_tiles():
			if scene.map.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut[tile] = true
		# Each flight is walked between the shaft's own doors, which is where a flight begins and ends
		# and where a door arrival lands clear of the fire.
		var landing := {}
		for side: String in ["left", "right"]:
			for floor_id: String in ["third", "second", "first", "lobby"]:
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
	return scene.map.stairwell_tiles(part_id)

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
func _test_the_masked_man_runs_the_stairs_rather_than_crossing_them(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())

	var man: EventInstance = null
	for instance in events.instances():
		if instance.row_id() == "masked_pursuer":
			man = instance
	t.check(man != null, "a masked man is on the stairs")
	if man:
		var side := "right" if BuildingPlan.BURNING_SIDE == "left" else "left"
		var part := "stairwell_%s" % side
		var steps := man.walks()
		t.check(steps.size() > 8,
				"his line is the whole shaft rather than two points (%d)" % steps.size())
		t.check(scene.map.world_to_tile(steps[0]) == f.waypoint("%s:landing_lobby" % part)
				and scene.map.world_to_tile(steps[steps.size() - 1]) == f.waypoint(part),
				"and it runs landing to landing")
		var off_the_ground := 0
		var pinched := 0
		var not_adjacent := 0
		for i in range(1, steps.size()):
			var here := scene.map.world_to_tile(steps[i - 1])
			var next := scene.map.world_to_tile(steps[i])
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
		for id: String in f.door_ids():
			if not id.begins_with("%s:" % part):
				continue
			doors += 1
			var at := scene.map.tile_to_world(f.door(id).tile)
			for point in steps:
				nearest_door = minf(nearest_door, at.distance_to(point))
		t.check(doors == 4, "the shaft has its four doors to ask about (%d)" % doors)
		t.check(nearest_door > man.row().core_within(),
				"and the nearest is %.0fpx off his line, clear of the %.0fpx that takes the baby"
				% [nearest_door, man.row().core_within()])
		print("The masked man's line: %d cells, nearest door %.0fpx off it against a %.0fpx reach"
				% [steps.size(), nearest_door, man.row().core_within()])
	events.free()
	scene.free()

## **A catch in the building is a day's catch** *(minty-lemur #785: "losing an escape should still
## state the reason like the rest of the game")*: the building's events are the day's own
## `EventManager`, so standing on the masked man's line ends the section through the same
## `EventBus.hard_fail_triggered` a day's catch sends, and the manager names what struck her
## (`EventManager.what_struck_her()`), which the loss's cause reads.
func _test_his_catch_ends_the_section_with_what_struck_her(t: TestRunner) -> void:
	# Twice real time: a tick is 1/15 of a second, so a step of his is a few pixels against his
	# catch radius, and he cannot step across her between two ticks.
	const SCALE := 2.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var man := BuildingEvents.live(events, "masked_pursuer")
	t.check(man != null, "a masked man is on the stairs")
	if not man:
		events.free()
		scene.free()
		return
	var player := Node2D.new()
	player.add_to_group("player")
	events.use_player(player)
	t.add_child(player)
	player.global_position = man.walks()[4]
	var fired: Array[String] = []
	var heard := func(reason: String) -> void:
		fired.append(reason)
		# The walk ends with the catch: nothing is stepped after it.
		events.set_physics_process(false)
	EventBus.hard_fail_triggered.connect(heard)
	var passed := 0
	while fired.is_empty() and passed < PhysicsTicks.ticks_for(20.0, SCALE):
		await PhysicsTicks.pass_ticks(t, 10, Callable(), SCALE)
		passed += 10
	EventBus.hard_fail_triggered.disconnect(heard)
	t.check(fired.size() == 1 and fired[0] == "masked_pursuer",
			"standing on his line, his catch ends the section as a day's catch does (%s)" % str(fired))
	t.check(events.what_struck_her() == "masked_pursuer",
			"and the building's events name what struck her (%s)" % events.what_struck_her())
	player.free()
	events.free()
	scene.free()

## **He walks where she can, and out of sight round the walls**: once he has run off the top of the
## shaft he leaves the way every figure leaves, through the building's map, so he never goes on
## through the wall past the top landing; every step he takes after his run is on ground she could
## stand on.
func _test_his_run_stops_at_the_building_walls(t: TestRunner) -> void:
	const STEP := 1.0 / 60.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var man := BuildingEvents.live(events, "masked_pursuer")
	t.check(man != null, "a masked man is on the stairs")
	if not man:
		events.free()
		scene.free()
		return
	var off_the_ground := 0
	var leaving_frames := 0
	var at := 0.0
	while at < 15.0 and not man.is_gone():
		events.world.where_she_is().tell(man.global_position + Vector2(40.0, -40.0))
		man.step(STEP)
		if man.is_on_its_way_out():
			leaving_frames += 1
		if not scene.map.is_walkable(scene.map.world_to_tile(man.global_position)):
			off_the_ground += 1
		at += STEP
	t.check(leaving_frames > 0, "he ran his line and is leaving (%d frames)" % leaving_frames)
	t.check(off_the_ground == 0,
			"and never stood off the building's ground, running or leaving (%d frames did)"
			% off_the_ground)
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
func _test_the_service_exit_is_reachable_past_the_rubble_the_fire_and_his_line(t: TestRunner) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var fire: EventInstance = null
	for instance in events.instances():
		if instance.row_id() == "burning_building":
			fire = instance
	t.check(fire != null, "the fire is in the building")
	var shut := {}
	var reach := 0.0
	if fire:
		reach = fire.row().obstructs_within() + Tuning.PLAYER_BODY_RADIUS
		for tile: Vector2i in f.floor_tiles():
			if f.is_walkable(tile) and scene.map.tile_to_world(tile).distance_to(fire.global_position) < reach:
				shut[tile] = true
	t.check(shut.size() > 0, "the fire actually closes ground (%d cells)" % shut.size())
	var buried := 0
	for y in range(f.rubble_area().position.y, f.rubble_area().end.y):
		for x in range(f.rubble_area().position.x, f.rubble_area().end.x):
			if f.has_floor_at(Vector2i(x, y)):
				buried += 1
	t.check(buried > 0, "and the rubble actually closes ground (%d cells)" % buried)

	var seen := {f.start_position(): true}
	var queue: Array[Vector2i] = [f.start_position()]
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
		for id: String in f.door_ids():
			var door: InteriorMapPlan.Door = f.door(id)
			if door.tile != here:
				continue
			var target: Vector2i = f.door(door.target_door).tile
			if not seen.has(target) and not shut.has(target):
				seen[target] = true
				queue.append(target)
	t.check(seen.has(f.exit_position()),
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
func _test_the_basement_events_stand_on_the_corridor_she_has_to_walk(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var walk := scene.map.basement_walk()
	t.check(walk.size() > 8, "the basement is a walk from its entry to its exit (%d tiles)"
			% walk.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var mouse: EventInstance = null
	for instance in events.instances():
		if instance.row_id() == "alley_mouse":
			mouse = instance
	t.check(mouse != null, "the mouse is in the building")
	if mouse:
		t.check(walk.has(scene.map.world_to_tile(mouse.global_position)),
				"and stands on the basement's own corridor")
		# Its dash crosses the passage it stands in, wall to wall, and never leaves the floor: the
		# building's map stops it at the walls as an alley's stop the city's mouse.
		var dash := mouse.walks()
		var on_the_floor := dash.size() >= 2
		for point in dash:
			on_the_floor = on_the_floor and scene.map.is_walkable(scene.map.world_to_tile(point))
		t.check(on_the_floor and dash[0].distance_to(dash[dash.size() - 1]) > 16.0,
				"and darts across its passage on the floor, wall to wall (%s)" % dash)

	var steam := EventCatalogue.by_id("basement_steam")
	var vents := BuildingEvents.vents(events)
	t.check(vents.size() == BuildingPlan.FINALE_STEAM_PERIODS.size(),
			"the corridor has one vent per period in `Tuning` (%d)" % vents.size())
	t.check(steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS > InteriorScene.TILE * 0.5,
			"a blowing vent holds her centre %.0fpx out against the %.0fpx half-width of a one-tile "
			% [steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS, InteriorScene.TILE * 0.5]
			+ "passage, so there is no line past one")
	var periods := {}
	var spacing := INF
	for i in vents.size():
		var vent: EventPlan = vents[i]
		periods[vent.repeat_every] = true
		var tile := scene.map.world_to_tile(vent.placed_at())
		t.check(walk.has(tile), "vent %d stands on the walk she has to take (%s)" % [i, tile])
		t.check(vent.placed_at().is_equal_approx(scene.map.tile_to_world(tile)),
				"vent %d stands on its cell's own centre, where a one-tile passage is symmetric" % i)
		var sideways := scene.map.is_walkable(tile + Vector2i.LEFT) \
				or scene.map.is_walkable(tile + Vector2i.RIGHT)
		var lengthways := scene.map.is_walkable(tile + Vector2i.UP) \
				or scene.map.is_walkable(tile + Vector2i.DOWN)
		t.check(not (sideways and lengthways),
				"vent %d stands where the corridor is one tile wide, not on a two-row band" % i)
		t.check(not _basement_reaches_the_exit_without(tile),
				"vent %d stands on a cell the walk to the exit cannot go round" % i)
		if i > 0:
			spacing = minf(spacing, vent.placed_at().distance_to((vents[i - 1] as EventPlan).placed_at()))
	t.check(periods.size() == vents.size(),
			"and no two vents share a period, so their gaps do not line up by themselves")
	t.check(spacing > (steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS) * 2.0,
			"consecutive vents leave a pocket she fits in (%.0fpx apart)" % spacing)
	# The gap a vent leaves has to be long enough to cross its own reach with time over — the floor
	# `BuildingPlan.FINALE_STEAM_PERIODS`' own doc derives, asked of the numbers rather than restated.
	var crossing := (steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS) * 2.0 / Tuning.WALK_SPEED
	for period: float in BuildingPlan.FINALE_STEAM_PERIODS:
		t.check(period - EventCatalogue.FINALE_STEAM_BLOWS_FOR >= crossing + 1.0,
				("a %.1fs vent leaves %.2fs of open corridor against the %.2fs it takes to walk "
				% [period, period - EventCatalogue.FINALE_STEAM_BLOWS_FOR, crossing])
				+ "through its reach, a margin of %.2fs"
				% (period - EventCatalogue.FINALE_STEAM_BLOWS_FOR - crossing))
	print("Basement vents: %d, %.0fpx apart at the closest, periods %s; a crossing costs %.2fs"
			% [vents.size(), spacing, BuildingPlan.FINALE_STEAM_PERIODS, crossing])
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
	return seen.has(f.exit_position())

## The corridor as a timing puzzle: *"have them turn off an on in different intervals"*. Driven
## through the building's `EventManager._physics_process()` and each instance's own `_process()`, the two calls
## the running game makes every frame, since a suite advances no clock of its own.
##
## Three contracts, and none of them is a number this test chose:
##
## - **A blow gives its notice before it closes anything.** `SolidWhen.ONCE_IT_STARTS` means the body
##   goes down at the end of the telegraph, and the telegraph has to be longer than walking out
##   from under the body takes.
## - **A vent's own gaps are its own period.** Measured between successive blows rather than read
##   off `Tuning`, so a stagger or a retire that quietly dropped a beat would show.
## - **A vent that is off is not there at all** — no instance, so no body and nothing charged.
func _test_the_vents_blow_on_their_own_clocks_and_give_notice_first(t: TestRunner) -> void:
	# Three times real time: a tick is a tenth of a second, which a vent's period (4 to 5.5s) and its
	# notice are several times over.
	const SCALE := 3.0
	const WINDOW := 24.0
	var tick_seconds := SCALE / Engine.physics_ticks_per_second
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var steam := EventCatalogue.by_id("basement_steam")
	t.check(steam.telegraphs_for()
			>= (steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS) / Tuning.WALK_SPEED,
			"the notice (%.2fs) covers walking out from under the body (%.2fs)"
			% [steam.telegraphs_for(),
			(steam.obstructs_within() + Tuning.PLAYER_BODY_RADIUS) / Tuning.WALK_SPEED])

	# Far enough away that nothing is ever withheld for her sake — that half is the next test.
	var her := Node2D.new()
	t.add_child(her)
	her.global_position = Vector2(-10000.0, -10000.0)
	events.use_player(her)
	var blows := {}
	var solid := {"before_the_notice": 0}
	var seen := {}
	var watch := func(tick: int) -> void:
		var live := tick * tick_seconds
		for instance in events.instances():
			if instance.row_id() != "basement_steam":
				continue
			var id := instance.get_instance_id()
			if not seen.has(id):
				seen[id] = true
				if not blows.has(instance.global_position):
					blows[instance.global_position] = [] as Array[float]
				(blows[instance.global_position] as Array[float]).append(live)
				if instance.is_solid():
					solid["before_the_notice"] += 1
			if instance.is_solid() and instance.age < steam.telegraphs_for():
				solid["before_the_notice"] += 1
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(WINDOW, SCALE), watch, SCALE)
	t.check(solid["before_the_notice"] == 0,
			"no blow was ever solid before its notice was over (%d were)" % solid["before_the_notice"])
	t.check(blows.size() == BuildingEvents.vents(events).size(),
			"every vent blew inside %.0fs and nothing blew anywhere else (%d places)"
			% [WINDOW, blows.size()])
	var off_period := 0
	var beats := 0
	for vent: EventPlan in BuildingEvents.vents(events):
		var times: Array = blows.get(vent.placed_at(), [])
		t.check(times.size() >= 2, "vent at %s blew more than once (%d)" % [vent.placed_at(), times.size()])
		for i in range(1, times.size()):
			beats += 1
			# A blow is first seen on the tick it began in, so its time is off by less than one tick
			# and a gap between two of them by less than one tick either way.
			if absf((times[i] - times[i - 1]) - vent.repeat_every) > tick_seconds + 0.0001:
				off_period += 1
	t.check(beats > 0, "there were gaps between blows to measure (%d)" % beats)
	t.check(off_period == 0, "and every one of them is that vent's own period (%d were not)"
			% off_period)
	her.free()
	events.free()
	scene.free()

## *"A vent never turns on with her inside its body."* The one thing a notice, however long, cannot
## be an answer to is walking **into** the thing that is about to close: a body built around her is
## a wall she is inside, and the only ways out of one are teleporting her or deleting it again.
##
## So the body is withheld for as long as she stands in the footprint and goes down the moment she
## is clear — a precondition rather than a repair, and the steam charges her the whole time, so
## standing in a vent is the most expensive way through it rather than a way past it.
func _test_a_vent_never_closes_around_her(t: TestRunner) -> void:
	# Three times real time, as the vents' clocks are walked in `_test_the_vents_blow_on_their_own_clocks_and_give_notice_first`.
	const SCALE := 3.0
	var tick_seconds := SCALE / Engine.physics_ticks_per_second
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var steam := EventCatalogue.by_id("basement_steam")
	var vents := BuildingEvents.vents(events)
	t.check(not vents.is_empty(), "there are vents to stand in")
	if vents.is_empty():
		events.free()
		scene.free()
		return
	var inside: Vector2 = (vents[0] as EventPlan).placed_at()
	# She stands where the first vent's footprint is; the manager tells every blow where she is.
	var her := Node2D.new()
	t.add_child(her)
	her.global_position = inside
	events.use_player(her)

	# Driven only as far as the first blow at that vent getting past its own notice, which is the
	# frame the contract is about: any longer and the instance under test would be a later cycle
	# still telegraphing, and "not solid" would pass for the wrong reason.
	var watched := {"blow": null, "charged": 0.0, "solid": 0, "blowing": false}
	var watch := func(_tick: int) -> void:
		if watched["blowing"]:
			return
		for instance in events.instances():
			if instance.row_id() != "basement_steam" or instance.global_position != inside:
				continue
			watched["blow"] = instance
			if instance.is_solid():
				watched["solid"] += 1
			watched["charged"] += instance.source().contribution_at(inside) * tick_seconds
			watched["blowing"] = instance.age > steam.telegraphs_for() and not instance.is_gone()
		if watched["blowing"]:
			# Stopped at the frame the contract is about.
			events.set_physics_process(false)
	var passed := 0
	while not watched["blowing"] and passed < PhysicsTicks.ticks_for(RunConfig.FINALE_LENGTH_SECONDS, SCALE):
		await PhysicsTicks.pass_ticks(t, 10, watch, SCALE)
		passed += 10
	var blow: EventInstance = watched["blow"]
	t.check(blow != null and watched["blowing"], "the vent she is standing in blew, and is past its notice")
	t.check(watched["solid"] == 0,
			"and never became solid while she was inside it (%d ticks)" % watched["solid"])
	t.check(watched["charged"] > 0.0,
			"while charging her for standing there (%.0f points of meter)" % watched["charged"])
	if blow and watched["blowing"]:
		# One tick with her clear of the footprint is all it takes.
		her.global_position = inside + Vector2(1000.0, 0.0)
		events.set_physics_process(true)
		await PhysicsTicks.pass_ticks(t, 1, Callable(), SCALE)
		t.check(blow.is_solid(), "and it closes the corridor the moment she steps out of it")
	her.free()
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
func _test_no_pocket_between_two_vents_outlasts_the_noise(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var steam := EventCatalogue.by_id("basement_steam")
	var vents := BuildingEvents.vents(events)
	var pairs := 0
	for i in range(1, vents.size()):
		var a: EventPlan = vents[i - 1]
		var b: EventPlan = vents[i]
		pairs += 1
		var shut := _longest_both_shut(a, b, steam)
		var half := a.placed_at().distance_to(b.placed_at()) * 0.5
		var rate := 2.0 * Field.falloff(half, steam.peak(), steam.core_within(),
				steam.heard_within(), steam.falloff_power)
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
func _test_one_blow_of_steam_costs_forty_to_fifty_points(t: TestRunner) -> void:
	const STEP := 1.0 / 60.0
	const STAND_AT := 30.0
	var steam := EventCatalogue.by_id("basement_steam")
	var blow_where := WhereSheIs.nowhere()
	var blow := EventInstance.new()
	# Set up before it joins the tree, the order `EventSpawner.create()` uses: `_ready()` reads the
	# def.
	blow.setup(steam, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT, null, null, blow_where)
	t.add_child(blow)
	var cost := 0.0
	var elapsed := 0.0
	while not blow.is_gone() and elapsed < 20.0:
		blow_where.tell(Vector2(STAND_AT, 0.0))
		blow.step(STEP)
		cost += blow.source().contribution_at(Vector2(STAND_AT, 0.0)) * STEP
		elapsed += STEP
	print("One blow of steam, stood %.0fpx from the vent for %.2fs: %.1f points awake, %.1f asleep"
			% [STAND_AT, elapsed, cost, cost * Baby.SLEEPING_SENSITIVITY])
	t.check(cost >= 40.0 and cost <= 50.0,
			"one blow costs 40 to 50 points awake at %.0fpx (%.1f)" % [STAND_AT, cost])
	blow.free()

## The longest run of seconds during which both vents are solid at once, over the whole sequence's
## own clock. Sampled rather than solved: the two windows are periodic with different periods and
## the overlap pattern does not repeat inside the clock, so the honest answer is to walk it.
func _longest_both_shut(a: EventPlan, b: EventPlan, steam: EventDef) -> float:
	const STEP := 1.0 / 60.0
	var longest := 0.0
	var run := 0.0
	var at := 0.0
	while at < RunConfig.FINALE_LENGTH_SECONDS:
		if _is_shut(a, at, steam) and _is_shut(b, at, steam):
			run += STEP
			longest = maxf(longest, run)
		else:
			run = 0.0
		at += STEP
	return longest

## Whether one vent's body is down at `at` seconds into the section. A vent's cycle is its notice,
## then `EventCatalogue.FINALE_STEAM_BLOWS_FOR` of blowing, then nothing until its own period comes round;
## `until_the_next_blow` is how far into the first cycle it starts.
func _is_shut(vent: EventPlan, at: float, steam: EventDef) -> bool:
	var since := at - (vent.comes_in - vent.repeat_every)
	if since < 0.0:
		return false
	var phase := fmod(since, vent.repeat_every)
	return phase >= steam.telegraphs_for() \
			and phase < steam.telegraphs_for() + EventCatalogue.FINALE_STEAM_BLOWS_FOR

## *"Let's not replenish the meter in the basement it's a tense situation."* (inbox #765 in minty-lemur) The
## scene answers the baby's `decay_multiplier()` with `InteriorScene.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER`
## (nothing) at every tile of the basement's corridor and with an ordinary 1.0 in every other part
## of the building, so a blow's points stay on the meter until she is out.
func _test_the_meter_does_not_fall_in_the_basement(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var walk := scene.map.basement_walk()
	t.check(not walk.is_empty(), "the basement has a corridor to walk")
	var worst := 0.0
	for tile in walk:
		worst = maxf(worst, scene.decay_multiplier(scene.map.tile_to_world(tile)))
	t.check(worst == 0.0 and InteriorScene.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER == 0.0,
			"no tile of the basement corridor gives any decay back (%.2f)" % worst)
	for part in PARTS:
		if part == "basement":
			continue
		var at := scene.map.tile_to_world(scene.map.waypoint(part))
		t.check(scene.decay_multiplier(at) == 1.0,
				"%s is ordinary ground for the meter" % part)
	var f := InteriorMap.build()
	t.check(scene.decay_multiplier(scene.map.tile_to_world(f.door("lobby:basement").tile)) == 1.0,
			"the lobby's basement door is still ordinary ground")
	t.check(scene.decay_multiplier(scene.map.tile_to_world(f.door("basement:entry").tile)) == 0.0,
			"the basement's entry tile gives nothing back")
	scene.free()

## The basement's puddle, debris and rat lie flat on the floor, so each is drawn under her wherever
## she stands on it: at the ground layer (the vent grate's own), not in the y-sorted layer she joins,
## where she would be drawn under it on its northern half. A stand-in for her is added the way she
## is, through `add_entity()`.
func _test_the_floor_decals_are_drawn_under_her(t: Node) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var her := Node2D.new()
	scene.add_entity(her)
	t.check(scene.map.decals.size() >= 3, "the building has its floor decals (%d)" % scene.map.decals.size())
	var kinds := {}
	for tile: Vector2i in scene.map.decals:
		kinds[scene.map.decals[tile]] = true
		var at := scene.map.tile_to_world(tile)
		var decal: Sprite2D = null
		for node in scene.find_children("*", "Sprite2D", true, false):
			var sprite := node as Sprite2D
			if sprite.position == at and sprite.get_parent() != her.get_parent():
				decal = sprite
		t.check(decal != null, "the decal at %s lies outside the sorted layer she stands in" % tile)
		if decal == null:
			continue
		t.check(_drawn_z(decal) < _drawn_z(her),
				"the decal at %s is drawn under her (z %d against %d)" % [tile, _drawn_z(decal), _drawn_z(her)])
	t.check(kinds.size() == 3, "the puddle, the debris and the rat are all there (%d kinds)" % kinds.size())
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
## - a restart leaves each vent's grate lying, and lays none over it.
func _test_every_vent_has_its_grate_blowing_or_not(t: TestRunner) -> void:
	# Three times real time, as the vents' clocks are walked in the test of their clocks.
	const SCALE := 3.0
	const WINDOW := 12.0
	var grate_size := AtlasTable.baked().native_size(StringName(EventPictures.STEAM_GRATE))
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var grates := SteamGrates.lay(BuildingPlan.grates(scene.map), scene.map, events.atlas)
	var ground := scene.get_node_or_null("Ground") as CanvasItem
	t.check(ground != null, "the building has its floor tiles to lie on")
	# She joins the same layer every blow does (`InteriorScene.add_entity()`), so a stand-in there
	# answers where she is drawn without building the whole stroller.
	var her := Node2D.new()
	scene.add_entity(her)
	# Far enough away that nothing is withheld for her sake.
	her.global_position = Vector2(-10000.0, -10000.0)
	events.use_player(her)
	t.check(BuildingEvents.vents(events).size() == BuildingPlan.FINALE_STEAM_PERIODS.size(),
			"the basement has its vents (%d)" % BuildingEvents.vents(events).size())
	for vent: EventPlan in BuildingEvents.vents(events):
		var grate := _grate_at(grates, vent.placed_at())
		t.check(is_instance_valid(grate) and grate.is_inside_tree(),
				"the vent at %s has a grate lying in the building" % vent.placed_at())
		if not is_instance_valid(grate):
			continue
		t.check(grate.position == vent.placed_at() and grate.centered,
				"the grate is centred on its vent's own point (%s, %s)" % [grate.position, vent.placed_at()])
		t.check(grate.texture != null and Vector2i(grate.texture.get_size()) == grate_size,
				"the grate is drawn with its own picture")
		t.check(_drawn_z(grate) < _drawn_z(her),
				"the grate is drawn under her, not sorted against her (z %d against %d)"
				% [_drawn_z(grate), _drawn_z(her)])
		if ground:
			# On the building's ground layer, whose node stands after the floor tiles.
			var layer := grate.get_parent()
			t.check(_drawn_z(grate) == _drawn_z(ground) and layer.get_parent() == ground.get_parent()
					and layer.get_index() > ground.get_index(),
					"and lies on the floor tiles rather than under them")

	var blowing_frames := {}
	var quiet_frames := {}
	var drawn := {"grates_missing": 0, "under_its_grate": 0}
	var seen := {}
	var watch := func(_tick: int) -> void:
		var blowing := {}
		for instance in events.instances():
			if instance.row_id() != "basement_steam":
				continue
			blowing[instance.global_position] = instance
		for vent: EventPlan in BuildingEvents.vents(events):
			var grate := _grate_at(grates, vent.placed_at())
			if not is_instance_valid(grate) or not grate.is_inside_tree():
				drawn["grates_missing"] += 1
				continue
			var blow: EventInstance = blowing.get(vent.placed_at())
			var tally: Dictionary = blowing_frames if blow else quiet_frames
			tally[vent.placed_at()] = int(tally.get(vent.placed_at(), 0)) + 1
			if not blow or seen.has(blow.get_instance_id()):
				continue
			seen[blow.get_instance_id()] = true
			if _drawn_z(blow) <= _drawn_z(grate):
				drawn["under_its_grate"] += 1
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(WINDOW, SCALE), watch, SCALE)
	t.check(seen.size() > BuildingEvents.vents(events).size(),
			"the vents blew over %.0fs (%d blows)" % [WINDOW, seen.size()])
	for vent: EventPlan in BuildingEvents.vents(events):
		t.check(int(blowing_frames.get(vent.placed_at(), 0)) > 0 and int(quiet_frames.get(vent.placed_at(), 0)) > 0,
				"the vent at %s was seen both blowing (%d frames) and between blows (%d)"
				% [vent.placed_at(), int(blowing_frames.get(vent.placed_at(), 0)), int(quiet_frames.get(vent.placed_at(), 0))])
	t.check(drawn["grates_missing"] == 0,
			"no vent was ever without its grate (%d ticks were)" % drawn["grates_missing"])
	t.check(drawn["under_its_grate"] == 0,
			"every blow's cloud is drawn over its grate (%d were not)" % drawn["under_its_grate"])

	# The grates are the building's floor for the whole escape, laid once: a restart of the section
	# starts its plans again and leaves the floor as it is.
	var lying_before := _grates_lying(scene)
	BuildingEvents.restart(events, scene)
	var lying := 0
	for grate in grates:
		if is_instance_valid(grate) and not grate.is_queued_for_deletion():
			lying += 1
	t.check(lying == grates.size(),
			"a restart leaves every vent's grate lying (%d of %d)" % [lying, grates.size()])
	t.check(_grates_lying(scene) == lying_before,
			"and lays none over them (%d grates, %d before)" % [_grates_lying(scene), lying_before])
	events.free()
	scene.free()

## The grate lying at `at`, or null.
func _grate_at(grates: Array[Sprite2D], at: Vector2) -> Sprite2D:
	for grate in grates:
		if grate.position == at:
			return grate
	return null

## How many grates lie in the building, on any layer.
func _grates_lying(scene: InteriorScene) -> int:
	var count := 0
	for node in scene.find_children("SteamGrate*", "Sprite2D", true, false):
		if not node.is_queued_for_deletion():
			count += 1
	return count

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

## How fast the window suites run the night: six times real time (`PhysicsTicks`), so a tick is
## `FLASH_SCALE / physics_ticks_per_second` seconds of game time. **No less than 3.6**: a lit window
## darkens on the first frame whose time has used up `InteriorScene.FINALE_WINDOW_FLASH_SECONDS`
## (0.12s), and a frame's time is one tick's, so a scale under 0.12 times the tick rate would leave a
## window lit across two ticks and the checks that call a tick dark could not tell.
const FLASH_SCALE := 6.0

## Where each test makes a fresh run of its own.
var _rig := InteriorRig.new()

## The hallway windows as drawn: every sprite in the building showing the picture of a window,
## dark or lit, read off the scene's tree.
func _windows(scene: InteriorScene) -> Array[Sprite2D]:
	var dark := scene.atlas.region(InteriorScene.HALLWAY_WINDOW)
	var lit := scene.atlas.region(InteriorScene.HALLWAY_WINDOW_FLASH)
	var found: Array[Sprite2D] = []
	for node in scene.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == dark or sprite.texture == lit:
			found.append(sprite)
	return found

## How many of `windows` show the lit picture.
func _lit(scene: InteriorScene, windows: Array[Sprite2D]) -> int:
	var lit := scene.atlas.region(InteriorScene.HALLWAY_WINDOW_FLASH)
	var count := 0
	for sprite in windows:
		if sprite.texture == lit:
			count += 1
	return count

## *"The hallway windows that flash when an explosion goes off."* There is no burst on the street
## to see and no arc drawn for the noise, so the flash is the whole of the cue — asked of the
## windows' own pictures as the building's events bring a bang on real physics ticks, with the
## night of far flashes stopped (`stop_the_night()`, as the exit does) so that nothing but the bang
## can light them.
func _test_an_explosion_flashes_every_hallway_window(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	scene.stop_the_night()
	var windows := _windows(scene)
	t.check(not windows.is_empty(), "the building has hallway windows (%d)" % windows.size())
	t.check(_lit(scene, windows) == 0, "the windows are dark to begin with")
	var lit_ticks: Array[int] = []
	# The watch runs at `process_frame`: after the tick's physics lit the windows and before that
	# frame's `_process()` darkens them (the engine's fixed order), so a flash is seen on its tick.
	var odd := {"neither": 0}
	var watch := func(tick: int) -> void:
		var lit := _lit(scene, windows)
		if lit > 0:
			lit_ticks.append(tick)
		# *"All windows always need to flash together. A single window cannot flash by itself."*
		if lit != 0 and lit != windows.size():
			odd["neither"] += 1
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(EventCatalogue.FINALE_EXPLOSION_INTERVAL + 2.0,
			FLASH_SCALE), watch, FLASH_SCALE)
	t.check(not lit_ticks.is_empty(), "an explosion lights the hallway windows")
	t.check(odd["neither"] == 0, "every one of the %d, together (%d ticks with some lit and some dark)"
			% [windows.size(), odd["neither"]])
	# A flash is over by the frame after it: it holds for 0.12s and a tick is longer.
	t.check(lit_ticks.size() == 1,
			"and they go dark again a frame or two later (lit on ticks %s)" % str(lit_ticks))
	t.check(_lit(scene, windows) == 0, "all of them, with none left lit (%d)" % _lit(scene, windows))
	# Every coming of a row from outside lights them, not only a repeat: a plan that comes once, in
	# the world from its first frame, lights them as it is put there.
	var once := EventPlan.new(EventCatalogue.explosion_outside(),
			scene.start_world_position())
	once.come_again_every(0.0)
	GivenPlanner.hand_in(events, [once] as Array[EventPlan])
	var none: Array[String] = []
	events.start_day(BuildingEvents.spec(), RandomNumberGenerator.new(), none,
			scene.start_world_position())
	t.check(once.is_in_the_world() and _lit(scene, windows) == windows.size(),
			"a bang from outside that comes once lights every window as it comes")
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
##   `EventCatalogue.FINALE_EXPLOSION_INTERVAL` rather than as a count written here.
## - **All of them or none of them.** *(2026-09-19: "all windows always need to flash together. a
##   single window cannot flash by itself.")* Checked on every frame of the minute, so an overlap
##   between two flashes 0.1s apart cannot leave one lit or blink the corridor dark for a frame.
## - **The cost, which is none.** Excitement in this building is a pure query over
##   the building's events' `instances()` — nothing writes at the baby — so "adds nothing to the meter" is
##   exactly "creates no instance", and that is asked directly rather than through an integral
##   that a stray source elsewhere in the building could muddy.
##
## And the same seed twice, since the waits come off the section's own seeded stream.
func _test_the_far_windows_flash_between_the_bangs_and_cost_nothing(t: TestRunner) -> void:
	const SPAN := 60.0
	const DRAWS := 4000
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := _rig.fresh_run()
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var windows := _windows(scene)
	t.check(not windows.is_empty(), "the building has hallway windows (%d)" % windows.size())

	# The distribution, asked of the curve the running game draws its waits from.
	var draws := RandomNumberGenerator.new()
	draws.seed = 4242
	var waits: Array[float] = []
	var outside := 0
	var total := 0.0
	for _draw in DRAWS:
		var wait := InteriorScene.distant_flash_wait(draws.randf())
		if wait < InteriorScene.FINALE_DISTANT_FLASH_MIN_SECONDS \
				or wait > InteriorScene.FINALE_DISTANT_FLASH_MAX_SECONDS:
			outside += 1
		waits.append(wait)
		total += wait
	waits.sort()
	var mean := total / float(DRAWS)
	var median: float = waits[DRAWS / 2]
	t.check(outside == 0,
			"every wait is inside [%.1fs, %.1fs] (%d of %d were not)"
			% [InteriorScene.FINALE_DISTANT_FLASH_MIN_SECONDS, InteriorScene.FINALE_DISTANT_FLASH_MAX_SECONDS,
			outside, DRAWS])
	t.check(absf(mean - Tuning.FINALE_DISTANT_FLASH_MEAN_SECONDS) <= 0.05,
			"the mean wait is %.3fs against the %.2fs the shape constant is solved for"
			% [mean, Tuning.FINALE_DISTANT_FLASH_MEAN_SECONDS])
	t.check(median < mean,
			"and the median (%.3fs) is under it, which is the bias toward short gaps" % median)
	# The documented curve's 95th percentile is 2.37s (the shape constant's doc).
	var p95: float = waits[int(DRAWS * 0.95)]
	t.check(absf(p95 - 2.37) <= 0.1, "and the 95th percentile (%.2fs) is the curve's 2.37s" % p95)
	print("Distant flash waits over %d draws: mean %.3fs, median %.3fs, longest %.2fs"
			% [DRAWS, mean, median, waits[DRAWS - 1]])

	# The same seed twice: a second building, started in the same ticks, from the same seed.
	var twin_scene := InteriorScene.new()
	t.add_child(twin_scene)
	var twin_rng := RandomNumberGenerator.new()
	twin_rng.seed = 4242
	var twin_run := _rig.fresh_run()
	var twin := BuildingEvents.events_in(t, twin_scene, twin_rng, twin_run)
	var twin_windows := _windows(twin_scene)

	# The night on real ticks, every one of them watched: which tick each building's windows were
	# lit on, and whether it was all of them or none.
	var when: Array[int] = []
	var twin_when: Array[int] = []
	var wrong := {"half_lit": 0, "began": 0, "ended": 0, "was_lit": false}
	# The watch runs when `process_frame` is emitted: after the tick's physics, which lit the windows,
	# and before that frame's `_process()` darkens them. The engine's order, the same on every frame.
	var watch := func(tick: int) -> void:
		var lit := _lit(scene, windows)
		if lit > 0:
			when.append(tick)
		if _lit(twin_scene, twin_windows) > 0:
			twin_when.append(tick)
		# All of them or none, on every tick: a flash that is over leaves none lit, and one that is on
		# has every window lit.
		if lit != 0 and lit != windows.size():
			wrong["half_lit"] += 1
		if lit > 0 and not wrong["was_lit"]:
			wrong["began"] += 1
		if lit == 0 and wrong["was_lit"]:
			wrong["ended"] += 1
		wrong["was_lit"] = lit > 0
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(SPAN, FLASH_SCALE), watch, FLASH_SCALE)
	var bangs := int(SPAN / EventCatalogue.FINALE_EXPLOSION_INTERVAL)
	t.check(when.size() > bangs * 5,
			"far more flashes than the bangs alone gave (%d in %.0fs against %d explosions)"
			% [when.size(), SPAN, bangs])
	t.check(wrong["half_lit"] == 0,
			"every window lights on every flash and goes dark with it, none on its own (%d ticks with some lit and some dark)"
			% wrong["half_lit"])
	t.check(wrong["ended"] > 0 and wrong["ended"] >= wrong["began"] - 1,
			"and none is left lit once a flash is over (%d began, %d ended)"
			% [wrong["began"], wrong["ended"]])
	print("Window flashes over %.0fs: %d ticks lit, against %d explosions" % [SPAN, when.size(), bangs])

	# **What this holds**: the stream's seeding (the `building_seed` meta that `tests/building_events.gd`
	# hands to `start_the_night()`) and the tick alignment of the flashes. Not the curve's shape, which
	# is pinned above by the bounds, the mean, the median and the 95th percentile.
	# Where the flashes fall: the night's waits are drawn from a stream of its own seeded from the
	# building's seed, so the first of them fall on the ticks that stream's waits make. A flash is
	# lit on the tick the wait runs out, and the next wait counts from that tick.
	var night := RandomNumberGenerator.new()
	night.seed = events.get_meta(&"building_seed")
	var tick_seconds := FLASH_SCALE / Engine.physics_ticks_per_second
	var predicted: Array[int] = []
	var left := InteriorScene.distant_flash_wait(night.randf())
	var tick := 0
	while tick * tick_seconds < EventCatalogue.FINALE_EXPLOSION_INTERVAL * 0.75:
		tick += 1
		left -= tick_seconds
		if left <= 0.0:
			predicted.append(tick)
			left = InteriorScene.distant_flash_wait(night.randf())
	var seen_early: Array[int] = []
	for lit_tick in when:
		if lit_tick <= tick:
			seen_early.append(lit_tick)
	t.check(not predicted.is_empty() and seen_early == predicted,
			"the flashes fall on the ticks the section's seeded stream makes (%s against %s)"
			% [str(seen_early), str(predicted)])
	t.check(twin_when == when,
			"the same seed flashes at the same instants (%d against %d)"
			% [twin_when.size(), when.size()])

	# A distant flash is a picture and nothing else: with the manager stopped, so that nothing it
	# does can be mistaken for a flash's doing, the next one lights the corridor and adds no instance.
	events.set_physics_process(false)
	var instances := events.instances().size()
	var whole := [] as Array[int]
	var count_lit := func(tick: int) -> void:
		if _lit(scene, windows) == windows.size():
			whole.append(tick)
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(
			InteriorScene.FINALE_DISTANT_FLASH_MAX_SECONDS + 0.01, FLASH_SCALE), count_lit, FLASH_SCALE)
	t.check(events.instances().size() == instances,
			"a distant flash creates nothing, so it can charge nothing (%d instances either side)"
			% instances)
	t.check(not whole.is_empty(),
			"and lights the whole corridor, exactly as a bang does (%d ticks with all %d lit)"
			% [whole.size(), windows.size()])

	twin.free()
	twin_scene.free()
	events.free()
	scene.free()

## *"The escape shouldn't behave any different than the rest of the game."* The screen-edge badge,
## the excitement halo and the debug view read the building's events the way they read a day's —
## the building's are the day's own `EventManager` — and none of them needs
## a crowd. Each is driven here against the real building rather than a stand-in, so what is
## checked is that the masked man coming up a stairwell raises a badge, the fire she is standing
## beside wears a rim, and the building's walls are bodies the bounding-box layer traces.
func _test_the_building_shows_what_the_city_shows(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	# Standing still: the instances stay where the checks put them, and the frames below are the
	# views' own.
	events.set_physics_process(false)
	var fire: EventInstance = null
	var man: EventInstance = null
	for instance in events.instances():
		if instance.row_id() == "burning_building":
			fire = instance
		elif instance.row_id() == "masked_pursuer":
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
	var sets: Array[ExcitementSources] = [events.sources]
	halo.setup(sets, player, baby)
	player.global_position = fire.global_position + Vector2(fire.row().core_within() * 0.5, 0.0)
	# Past its notice, the way the explosion outside comes: a fire still telegraphing
	# emits nothing, and a rim on it would be the cue marking a thing that costs her nothing.
	fire.resume(fire.telegraphs_for(), 0.0, INF)
	t.check(fire.source().contribution_at(player.global_position) > ExcitementHalo.CONTRIBUTION_FLOOR,
			"standing beside the fire, it reaches her")
	fire.source().accumulate_landed(20.0)
	# A drawn frame of the halo, as the game runs it.
	await _frames(t, 3)
	t.check(fire.source().rim().is_held() and not fire.rim().is_faded_out(),
			"the fire she is standing beside wears a rim, read from the building's events, no crowd")
	t.check(not man.source().rim().is_held(),
			"and the masked man on the other shaft, charging her nothing, holds no rim at all")

	# **The badge.** Placed far off any screen and walked in towards her, so the only thing that
	# can raise it is his own approach — the same test a fire engine coming down a street meets.
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.size = ScreenOrientation.DESIGN_SIZE
	# The pictures a badge is drawn with, from the atlas `main` hands it.
	edge.atlas = events.atlas
	edge.setup(events, player)
	var far := Vector2(-40000.0, -40000.0)
	player.global_position = far
	man.global_position = far + Vector2(man.row().heard_within() + 400.0, 0.0)
	await _frames(t, 3)
	man.global_position -= Vector2(30.0, 0.0)
	await _frames(t, 3)
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
	# Its fields read the building's instances: with nothing else on the map, every one that is not
	# finished is outlined at its inner and its outer radius (a flock at each bird's).
	var unfinished := 0
	for instance in events.instances():
		if not instance.is_gone():
			var birds := instance.flock_offsets().size()
			unfinished += 2 * maxi(birds, 1)
	var outlined := layers.field_runs(Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6)).size()
	t.check(outlined == unfinished,
			"its fields outline each of the building's unfinished instances at both radii (%d of %d)"
			% [outlined, unfinished])

	layers.free()
	stroller.free()
	edge.free()
	halo.free()
	baby.free()
	player.free()
	events.free()
	scene.free()

## The building she escapes through is the same night: the hallways and the lobby in the gloom, the
## basement darker, the stairwells on the red emergency lighting, and a hallway lit by a blast while
## its windows flash. Every door is asked which part it is in, since a door's id names its part and
## the light is chosen by the part.
func _test_the_escape_building_is_dark_by_part(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var plan := InteriorMap.build()
	var misplaced := 0
	for id: String in plan.door_ids():
		var door: InteriorMapPlan.Door = plan.door(id)
		if InteriorMap.part_at(door.tile) != id.split(":")[0]:
			misplaced += 1
	t.check(plan.door_ids().size() > 0 and misplaced == 0,
			"every door is in the part its id names (%d of %d misplaced)"
			% [misplaced, plan.door_ids().size()])
	var player := Node2D.new()
	t.add_child(player)
	var hallway := _lighting_at(scene, player, plan.waypoint("hallway_second"))
	var lobby := _lighting_at(scene, player, plan.waypoint("lobby"))
	var basement := _lighting_at(scene, player, plan.waypoint("basement"))
	var stairs := _lighting_at(scene, player, plan.waypoint("stairwell_left"))
	t.check(hallway == Palette.ESCAPE_GLOOM and lobby == Palette.ESCAPE_GLOOM,
			"the hallways and the lobby are in the gloom")
	t.check(basement.get_luminance() < hallway.get_luminance(),
			"and the basement is darker than they are")
	t.check(stairs == Palette.ESCAPE_EMERGENCY_RED,
			"the stairwells are on the red emergency lighting")
	t.check(_lighting_at(scene, player, plan.waypoint("stairwell_right")) == stairs,
			"both of them")
	# An explosion outside, the call the day's events make (`WorldContext.bang_outside()`).
	scene.bang_outside()
	t.check(_lighting_at(scene, player, plan.waypoint("hallway_second")).get_luminance()
			> hallway.get_luminance(), "a hallway is lit up while its windows flash")
	t.check(_lighting_at(scene, player, plan.waypoint("stairwell_left")) == stairs,
			"a stairwell, with no windows, is not")
	player.free()
	scene.free()

## The light she stands in at `tile`: the scene's own modulate after the building has been asked what
## its ground does to somebody standing there (`process_player()`, which the run flow asks every frame).
func _lighting_at(scene: InteriorScene, player: Node2D, tile: Vector2i) -> Color:
	player.global_position = scene.map.tile_to_world(tile)
	scene.map.process_player(player, 0.0)
	return scene.modulate
