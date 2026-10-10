extends RefCounted
## Excitement does not go through a wall — `CityMap.wall_between()`, the line every source's
## `contribution_at()` asks — *(plaid-wombat, inbox #554: "Excitement should not go through any
## wall but it's not straightforward. If the player is partially in a wall they should not be
## protected so the blocking should happen in the middle of the wall (or one tile deep)"; inbox
## #568: "half a tile was only supposed to be done if the wall is only one tile wide otherwise it
## should be one tile")*: the geometry's own edge cases on hand-built maps, a sweep against a
## sampled depth on a real city, the three readers (the meter's sum, the halo's pick and the
## caret's projection) agreeing, the escape's building stopping it at its own walls, and the debug
## view's fields layer cut where the meter receives nothing.

const _SIZE := float(Tuning.TILE_SIZE)

## Lines whose two directions answered differently, checked once every hand-built case has run.
var _asymmetric := 0

func run(t) -> void:
	_test_the_depth_sits_between_her_body_and_a_tile(t)
	_test_a_wall_one_tile_thick_blocks_at_its_middle(t)
	_test_a_thicker_building_blocks_a_tile_deep(t)
	_test_an_open_end_is_shallower(t)
	_test_a_one_tile_wall_blocks_at_its_corner_too(t)
	_test_grazing_a_corner_shields_nothing(t)
	_test_a_line_deep_across_a_corner_is_blocked(t)
	_test_her_body_in_a_wall_is_not_shielded(t)
	_test_a_corner_open_only_diagonally_is_shallow_round_its_point(t)
	_test_exact_geometry_agrees_with_a_sampled_depth(t)
	_test_an_event_is_silent_behind_a_wall(t)
	_test_a_crowd_body_is_silent_behind_a_wall(t)
	_test_the_caret_asks_the_wall_where_the_bodies_will_be(t)
	_test_the_building_inside_stops_it_at_its_own_walls(t)
	_test_the_fields_layer_is_cut_where_a_wall_stops_the_field(t)
	_test_the_fields_layer_skips_only_where_no_wall_can_block(t)
	_test_the_fields_layer_follows_the_wall_along_the_whole_outline(t)
	_test_the_fields_layer_cuts_a_moved_source_again(t)
	_test_the_fields_layer_never_culls_an_outline_on_screen(t)
	t.check(_asymmetric == 0, "every hand-built line answers the same both ways (%d did not)"
			% _asymmetric)

## A `width`×`height` map of sidewalk with the given tiles built on.
func _map_with(buildings: Array[Vector2i], width := 12, height := 12) -> CityMap:
	var map := CityMap.new(Vector2i(width, height))
	map.fill_rect(Rect2i(0, 0, width, height), GameEnums.TileType.SIDEWALK)
	for tile in buildings:
		map.set_tile(tile, GameEnums.TileType.BUILDING)
	return map

func _rect_tiles(rect: Rect2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			found.append(Vector2i(x, y))
	return found

## Both directions, since a source and her are the same two points whichever end asks.
func _blocked(map: CityMap, a: Vector2, b: Vector2) -> bool:
	var forward := map.wall_between(a, b)
	if forward != map.wall_between(b, a):
		_asymmetric += 1
	return forward

## Over her body, so her own overlap with a wall's edge cannot shield her; a thin wall's depth no
## more than its middle, or it could never block; and neither deeper than a tile, the depth the tile
## neighbourhood can answer.
func _test_the_depth_sits_between_her_body_and_a_tile(t) -> void:
	t.check(Tuning.THIN_WALL_SHIELD_DEPTH > Tuning.PLAYER_BODY_RADIUS,
			"a thin wall shields only past her own body's reach into it (%.1f > %.1f)"
			% [Tuning.THIN_WALL_SHIELD_DEPTH, Tuning.PLAYER_BODY_RADIUS])
	t.check(Tuning.THIN_WALL_SHIELD_DEPTH <= _SIZE * 0.5,
			"a thin wall's depth is no deeper than its own middle")
	t.check(Tuning.THIN_WALL_SHIELD_DEPTH <= Tuning.WALL_SHIELD_DEPTH,
			"and no deeper than a thick building's")
	t.check(Tuning.WALL_SHIELD_DEPTH <= _SIZE,
			"which is no deeper than a tile, which a tile's neighbours can answer")

## A wall one tile thick, the column x = 4 (128 to 160px): its middle is half a tile from open
## ground on both sides, and every line across it, square or slanted, passes that middle. The
## column runs off both edges of the map, which counts as building, so it has no open end here.
func _test_a_wall_one_tile_thick_blocks_at_its_middle(t) -> void:
	var map := _map_with(_rect_tiles(Rect2i(4, 0, 1, 12)))
	t.check(_blocked(map, Vector2(112.0, 80.0), Vector2(176.0, 80.0)),
			"a line straight across a one-tile wall is blocked")
	t.check(_blocked(map, Vector2(100.0, 40.0), Vector2(190.0, 150.0)),
			"and a diagonal across it too")
	t.check(not _blocked(map, Vector2(112.0, 80.0), Vector2(143.0, 80.0)),
			"a line stopping a pixel short of the wall's middle is not")
	t.check(not _blocked(map, Vector2(112.0, 20.0), Vector2(112.0, 360.0)),
			"and a line along the wall's face, in the open, never is")

## A wall two tiles thick, x 4 to 5 (128 to 192px), with no open end: its middle, x = 160, is a whole
## tile from open ground, and every line across it passes there; a line that reaches only part of the
## way in is not blocked, however far past half a tile it gets.
func _test_a_thicker_building_blocks_a_tile_deep(t) -> void:
	var map := _map_with(_rect_tiles(Rect2i(4, 0, 2, 12)))
	t.check(_blocked(map, Vector2(112.0, 80.0), Vector2(208.0, 80.0)),
			"a line straight across a two-tile wall is blocked")
	t.check(_blocked(map, Vector2(100.0, 40.0), Vector2(220.0, 190.0)),
			"and a diagonal across it too")
	t.check(not _blocked(map, Vector2(112.0, 80.0), Vector2(150.0, 80.0)),
			"a line 22px into it, past half a tile, is not")
	t.check(not _blocked(map, Vector2(112.0, 80.0), Vector2(159.0, 80.0)),
			"nor one stopping a pixel short of its middle")
	var deep := _map_with(_rect_tiles(Rect2i(4, 0, 4, 12)))
	t.check(_blocked(deep, Vector2(112.0, 80.0), Vector2(162.0, 80.0)),
			"in a building four tiles thick a line a tile and a little in is blocked")
	t.check(not _blocked(deep, Vector2(112.0, 80.0), Vector2(158.0, 80.0)),
			"and one 30px in is not")

## Near an open end, where the middle is shallower: a building two tiles thick and eight long, x 4 to
## 5 and y 2 to 9 (y from 64px), blocks a line straight across it only once it is a tile from the end,
## and a one-tile wall of the same length only once it is half a tile from it. The player's own answer
## for the end *(bouncy-kestrel, inbox #568: "Near the end of the building the same spacing is used
## so a 2x8 building has a 6 unit long line through its middle")*.
func _test_an_open_end_is_shallower(t) -> void:
	var thick := _map_with(_rect_tiles(Rect2i(4, 2, 2, 8)))
	t.check(not _blocked(thick, Vector2(112.0, 95.0), Vector2(208.0, 95.0)),
			"a line through a two-tile building 31px from its end passes")
	t.check(_blocked(thick, Vector2(112.0, 97.0), Vector2(208.0, 97.0)),
			"and 33px from its end is blocked")
	var thin := _map_with(_rect_tiles(Rect2i(4, 2, 1, 8)))
	t.check(not _blocked(thin, Vector2(112.0, 79.0), Vector2(176.0, 79.0)),
			"a line through a one-tile wall 15px from its end passes")
	t.check(_blocked(thin, Vector2(112.0, 81.0), Vector2(176.0, 81.0)),
			"and 17px from its end is blocked")

## An L of one-tile walls, the column x = 4 down to y = 5 and the row y = 5 east from it: the corner
## tile (4, 5) holds no point a tile from open ground, so it is thin and a line across the bend is
## blocked at its middle — the bend of a thin wall is still a thin wall.
func _test_a_one_tile_wall_blocks_at_its_corner_too(t) -> void:
	var tiles := _rect_tiles(Rect2i(4, 0, 1, 6))
	tiles.append_array(_rect_tiles(Rect2i(5, 5, 7, 1)))
	var map := _map_with(tiles)
	t.check(_blocked(map, Vector2(110.0, 210.0), Vector2(180.0, 140.0)),
			"a diagonal across the bend of an L of one-tile walls is blocked")
	t.check(not _blocked(map, Vector2(110.0, 210.0), Vector2(139.0, 181.0)),
			"and one stopping short of the bend's middle is not")

## A building of three by four tiles, x 4 to 6 and y 3 to 6 (128 to 224, 96 to 224px), open on all
## sides: a line that cuts its north-west corner short of a tile deep on either face is a graze.
func _test_grazing_a_corner_shields_nothing(t) -> void:
	var map := _map_with(_rect_tiles(Rect2i(4, 3, 3, 4)))
	t.check(not _blocked(map, Vector2(112.0, 112.0), Vector2(150.0, 88.0)),
			"a line clipping the corner about four pixels deep is not blocked")
	t.check(not _blocked(map, Vector2(104.0, 120.0), Vector2(152.0, 72.0)),
			"nor one passing exactly through the corner point")
	t.check(not _blocked(map, Vector2(80.0, 140.0), Vector2(168.0, 84.0)),
			"nor one cutting the corner short of half a tile on either face")
	t.check(not _blocked(map, Vector2(100.0, 164.0), Vector2(196.0, 68.0)),
			"nor one cutting it 20px deep on both faces, past half a tile and short of a whole one")

## The same building, a diagonal through (164, 132): 36px in from both open faces.
func _test_a_line_deep_across_a_corner_is_blocked(t) -> void:
	var map := _map_with(_rect_tiles(Rect2i(4, 3, 3, 4)))
	t.check(_blocked(map, Vector2(100.0, 196.0), Vector2(232.0, 64.0)),
			"a diagonal cutting the corner past a tile on both faces is blocked")
	t.check(_blocked(map, Vector2(112.0, 160.0), Vector2(240.0, 160.0)),
			"a line straight through the building is blocked")

## Her centre inside the wall's skin, as far as her own body could ever reach into it: nothing she
## hears is shielded by that, whether the source is beside her along the face or across the open
## street from her. A source past the wall's middle, or past a thick building, still is.
func _test_her_body_in_a_wall_is_not_shielded(t) -> void:
	var thin := _map_with(_rect_tiles(Rect2i(4, 0, 1, 12)))
	var inside := 128.0 + Tuning.PLAYER_BODY_RADIUS
	t.check(not _blocked(thin, Vector2(inside, 80.0), Vector2(60.0, 80.0)),
			"her body in a one-tile wall's edge does not shield her from the street she stands on")
	t.check(not _blocked(thin, Vector2(inside, 80.0), Vector2(inside, 300.0)),
			"nor from a source along the same face, the line running inside the skin")
	t.check(_blocked(thin, Vector2(inside, 80.0), Vector2(200.0, 80.0)),
			"a source beyond the wall's middle is still shut out")
	var thick := _map_with(_rect_tiles(Rect2i(4, 0, 3, 12)))
	t.check(not _blocked(thick, Vector2(inside, 20.0), Vector2(inside, 340.0)),
			"along a thick wall's face, her body's depth in shields nothing")
	t.check(not _blocked(thick, Vector2(inside, 80.0), Vector2(60.0, 80.0)),
			"nor from the street she stands on")
	t.check(_blocked(thick, Vector2(inside, 80.0), Vector2(240.0, 80.0)),
			"a source beyond the thick wall is still shut out")

## A courtyard of one open tile, (4, 4), inside a building filling x 3 to 6, y 3 to 6. Tile (5, 5)
## is open only diagonally, at its corner point (160, 160), and is part of the thick building: the
## shallow ground there is a disc of a whole tile round that point, not the tile's whole edge.
func _test_a_corner_open_only_diagonally_is_shallow_round_its_point(t) -> void:
	var tiles := _rect_tiles(Rect2i(3, 3, 4, 4))
	tiles.erase(Vector2i(4, 4))
	var map := _map_with(tiles)
	t.check(not _blocked(map, Vector2(150.0, 150.0), Vector2(180.0, 180.0)),
			"a line ending 28px from the open corner is in its shallow disc")
	t.check(_blocked(map, Vector2(150.0, 150.0), Vector2(185.0, 185.0)),
			"and one ending 35px from it reaches a tile deep")

## The depth of a point inside a building: its distance to the nearest open tile among the 5×5
## around it, or `INF` where none is, which is deeper than any depth this suite asks about.
func _depth(map: CityMap, at: Vector2) -> float:
	var tile := map.world_to_tile(at)
	if map.is_walkable(tile):
		return 0.0
	var nearest := INF
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var other := tile + Vector2i(dx, dy)
			if not map.is_walkable(other):
				continue
			var rect := Rect2(Vector2(other) * _SIZE, Vector2(_SIZE, _SIZE))
			nearest = minf(nearest, at.clamp(rect.position, rect.end).distance_to(at))
	return nearest

## Whether a building tile holds a point a whole tile from open ground — asked of its four corners,
## the only places in a tile that can be. Stated over the sampled depth rather than over the tile
## pattern `CityMap` reads, so the two are independent.
func _is_thick(map: CityMap, tile: Vector2i) -> bool:
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var at := Vector2(tile + corner) * _SIZE
		# A point on a tile edge belongs to every tile it touches; the nudge reads it from inside.
		var inside := at + (Vector2(0.5, 0.5) - Vector2(corner)) * 0.001
		if _depth(map, inside) >= _SIZE - 0.01:
			return true
	return false

## The depth a point has to reach to block: the least over every building tile whose closed square
## holds it — a tile's own depth, a whole tile where the tile is thick and half one where it is
## part of a wall one tile thick.
func _needed_at(map: CityMap, at: Vector2, thick: Dictionary) -> float:
	var needed := INF
	var base := map.world_to_tile(at)
	for dy in range(-1, 1):
		for dx in range(-1, 1):
			var tile := base + Vector2i(dx, dy)
			if map.is_walkable(tile) \
					or not Rect2(Vector2(tile) * _SIZE, Vector2(_SIZE, _SIZE)).grow(0.001).has_point(at):
				continue
			if not thick.has(tile):
				thick[tile] = _is_thick(map, tile)
			needed = minf(needed, Tuning.WALL_SHIELD_DEPTH if thick[tile]
					else Tuning.THIN_WALL_SHIELD_DEPTH)
	return needed

## **The exact walk against a sampled one, on a real city.** Seeded segments from open ground near
## buildings, in every direction and up to the widest field's reach, each sampled every pixel for
## how far its deepest point inside a building gets past the depth that point's own tile asks. The
## depth moves at most a pixel per pixel, so inside one tile the true margin is within half a pixel
## above the sampled one: a sample at or past its depth must be blocked, one more than half a pixel
## short must not, and the sliver between is set aside. The guards count both answers, so a sweep
## that only met open ground or only walls cannot pass.
func _test_exact_geometry_agrees_with_a_sampled_depth(t) -> void:
	var map := CityGenerator.generate(4242)
	var rng := RandomNumberGenerator.new()
	rng.seed = 554
	var buildings := map.tiles_of_type(GameEnums.TileType.BUILDING)
	var thick := {}
	var asked := 0
	var blocked := 0
	var clear_through_buildings := 0
	var disagreed := 0
	while asked < 300:
		var near: Vector2i = buildings[rng.randi_range(0, buildings.size() - 1)]
		var from := map.tile_to_world(near) + Vector2(rng.randf_range(-80.0, 80.0),
				rng.randf_range(-80.0, 80.0))
		if not map.is_walkable(map.world_to_tile(from)):
			continue
		var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 200.0)
		var samples := int(ceil(from.distance_to(to)))
		var deepest := 0.0
		var margin := -INF
		for i in samples + 1:
			var at := from.lerp(to, float(i) / float(samples))
			var depth := _depth(map, at)
			deepest = maxf(deepest, depth)
			if depth > 0.0:
				margin = maxf(margin, depth - _needed_at(map, at, thick))
		if margin < 0.0 and margin + 0.5 >= 0.0:
			continue
		asked += 1
		var exact := map.wall_between(from, to)
		if exact:
			blocked += 1
		elif deepest > 0.0:
			clear_through_buildings += 1
		if exact != (margin >= 0.0):
			disagreed += 1
	t.check(blocked > 30, "the sweep crossed walls (%d of %d)" % [blocked, asked])
	t.check(clear_through_buildings > 10,
			"and grazed buildings without reaching their middle (%d)" % clear_through_buildings)
	t.check(disagreed == 0, "the exact walk and the sampled depth agree (%d did not)" % disagreed)

## A street musician with a building between them: nothing on the meter's sum and no rim, while
## the same musician on open ground reaches her.
func _test_an_event_is_silent_behind_a_wall(t) -> void:
	var def := EventCatalogue.by_id("busker")
	var her := Vector2(240.0, 176.0)
	var at := Vector2(112.0, 176.0)
	var walled := _map_with(_rect_tiles(Rect2i(5, 0, 2, 12)))
	var open := _map_with([])
	var behind := _musician(def, at, walled)
	var beside := _musician(def, at, open)
	t.check(beside.contribution_at(her) > 0.0,
			"on open ground the musician's field reaches her (%.2f/s)" % beside.contribution_at(her))
	t.check(behind.contribution_at(her) == 0.0,
			"with a building between them it does not")
	t.check(behind._field_at(her, -1.0, Vector2.INF) == beside.contribution_at(her),
			"the field itself is unchanged; only what reaches her is")
	var picked := ExcitementHalo.select_sources([behind, beside], her)
	t.check(picked.size() == 1 and picked[0] == beside,
			"the halo picks the one that reaches her and not the one behind the wall")
	behind.free()
	beside.free()

## A row's instance standing at `at` past its telegraph, asking `map` about the ground — set after
## `setup()` so both copies stand exactly where they were put.
func _musician(def: EventDef, at: Vector2, map: CityMap) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at)
	instance._map = map
	instance.age = def.telegraph_time + 1.0
	return instance

## A car on the far side of a building, and a walker startled there: silent through the wall,
## heard in the open, in the crowd's own sum.
func _test_a_crowd_body_is_silent_behind_a_wall(t) -> void:
	var walled := _map_with(_rect_tiles(Rect2i(0, 4, 12, 2)))
	var her := Vector2(176.0, 208.0)
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.position = Vector2(176.0, 112.0)
	car._map = walled
	t.check(car.contribution_at(her, false) > 0.0, "the car's field reaches her distance (%.2f/s)"
			% car.contribution_at(her, false))
	t.check(car.contribution_at(her) == 0.0, "but not through the building between them")
	car.startle(18.0, 0.9, 45.0, Tuning.CAR_HORN_OUTER_RADIUS)
	t.check(car.contribution_at(her) == 0.0, "nor does its horn")
	car._map = _map_with([])
	t.check(car.contribution_at(her) > 0.0, "and on open ground the same car is heard")
	car.free()

## The caret projects both bodies forward. The wall is asked where they will be, not at the
## translated point: her walking down a street with a long building between her and a musician
## expects nothing from him, and the same walk in the open does; a car driving down the far side
## of the building expects nothing from her standing still, and in the open it does. And a car
## about to come out past the building's end expects what it will land once it is out — which the
## line from where the car stands now to her translated place, still across the building, would
## answer as nothing.
func _test_the_caret_asks_the_wall_where_the_bodies_will_be(t) -> void:
	var def := EventCatalogue.by_id("busker")
	var walled := _map_with(_rect_tiles(Rect2i(0, 4, 24, 2)), 24, 12)
	var open := _map_with([], 24, 12)
	var ending := _map_with(_rect_tiles(Rect2i(0, 4, 10, 2)), 24, 12)
	var coming_out := CrowdAgent.new()
	coming_out.kind = CrowdAgent.Kind.CAR
	coming_out.position = Vector2(80.0, 112.0)
	coming_out._speed = 140.0
	coming_out._direction = 1.0
	coming_out._map = ending
	coming_out.set_player_at(Vector2(400.0, 200.0))
	t.check(coming_out.contribution_at(Vector2(400.0, 200.0)) == 0.0
			and coming_out.expected_gross_at(Vector2(400.0, 200.0)) > 0.0,
			"a car about to clear the building's end expects what it lands once out (%.2f)"
			% coming_out.expected_gross_at(Vector2(400.0, 200.0)))
	coming_out.free()
	var at := Vector2(400.0, 80.0)
	var her := Vector2(240.0, 208.0)
	var walk := Vector2(Tuning.WALK_SPEED, 0.0)
	for map: CityMap in [walled, open]:
		var musician := _musician(def, at, map)
		musician.set_player_at(her, walk)
		var expected := musician.expected_gross_at(her)
		if map == walled:
			t.check(expected == 0.0, "walking past behind a building expects nothing (%.2f)"
					% expected)
		else:
			t.check(expected > 0.0, "the same walk in the open expects something (%.2f)"
					% expected)
		musician.free()
	for map: CityMap in [walled, open]:
		var car := CrowdAgent.new()
		car.kind = CrowdAgent.Kind.CAR
		car.position = Vector2(80.0, 112.0)
		car._speed = 140.0
		car._direction = 1.0
		car._map = map
		car.set_player_at(Vector2(400.0, 200.0))
		var expected := car.expected_gross_at(Vector2(400.0, 200.0))
		if map == walled:
			t.check(expected == 0.0, "a car on the far side of a building expects nothing (%.2f)"
					% expected)
		else:
			t.check(expected > 0.0, "the same car with nothing between expects something (%.2f)"
					% expected)
		car.free()

## **Indoors too.** *(plaid-wombat, inbox #554: "Excitement should not go through **any** wall".)*
## The escape's building has no `CityMap`, so `InteriorEvents` hands every source its own walls
## (`InteriorScene.wall_grid()`, the plan's walkability as a grid `CityMap.wall_between()` answers)
## and they stop a field at the depths a city's buildings do. The masked man is stood on every tile
## of his own shaft's walk and asked at every walkable point of it within his reach: nothing where
## the grid walls the line, the field itself everywhere else; the guard counts the points a field
## reached and a wall stopped, which is what the solid between two flights does to him. The
## explosion is the exception: it stands for a bang outside that has already come through the walls,
## so a wall between where its instance stands and her keeps none of it from her.
func _test_the_building_inside_stops_it_at_its_own_walls(t) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	events.setup(scene, rng)
	var grid := scene.wall_grid()
	var disagreed := 0
	for y in range(-2, grid.size.y + 2):
		for x in range(-2, grid.size.x + 2):
			if grid.is_walkable(Vector2i(x, y)) != scene.is_walkable(Vector2i(x, y)):
				disagreed += 1
	t.check(disagreed == 0, "the wall grid is open exactly where she may stand (%d tiles were not)"
			% disagreed)

	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "masked_pursuer":
			man = instance
	t.check(man != null, "the masked man is on the stairs")
	if man:
		man.resume(man.def.telegraph_time, 0.0, INF)
		var shaft: Array[Vector2] = []
		for tile in scene.stairwell_tiles("stairwell_right"):
			if not scene.is_walkable(tile):
				continue
			for sy in 4:
				for sx in 4:
					shaft.append(Vector2(tile) * _SIZE + Vector2(4.0 + 8.0 * sx, 4.0 + 8.0 * sy))
		var reached := 0
		var stopped := 0
		var wrong := 0
		for tile in scene.stairwell_walk("stairwell_right"):
			man.global_position = scene.tile_to_world(tile)
			for her in shaft:
				var field := man._field_at(her, -1.0, Vector2.INF)
				if field <= 0.0:
					continue
				# Uncached: the man is moved under a fixed `age`, which `contribution_at()`'s
				# own cache is keyed on, so the public call would answer for where he last stood.
				var landed := man._contribution_at_uncached(her, -1.0, Vector2.INF)
				var walled := grid.wall_between(man.global_position, her)
				if walled:
					stopped += 1
				else:
					reached += 1
				if landed != (0.0 if walled else field):
					wrong += 1
		t.check(stopped > 0, "a wall in his shaft stands between him and her (%d points)" % stopped)
		t.check(reached > stopped, "while most of his reach is open stairs (%d points)" % reached)
		t.check(wrong == 0, "and his field reaches her exactly where no wall stops it (%d did not)"
				% wrong)

	# Somewhere on the stairs with open stair behind a wall from it, well inside the bang's reach.
	var stands := Vector2.INF
	var behind := Vector2.INF
	for from in scene.stairwell_walk("stairwell_right"):
		for tile in scene.stairwell_tiles("stairwell_right"):
			var at := scene.tile_to_world(tile)
			if scene.is_walkable(tile) and at.distance_to(scene.tile_to_world(from)) < 200.0 \
					and grid.wall_between(scene.tile_to_world(from), at):
				stands = scene.tile_to_world(from)
				behind = at
				break
		if behind != Vector2.INF:
			break
	t.check(behind != Vector2.INF, "there is open stair behind a wall from a step of the shaft")
	var player := Node2D.new()
	player.add_to_group("player")
	t.add_child(player)
	player.global_position = stands
	events._explode_every_so_often(Tuning.FINALE_EXPLOSION_INTERVAL)
	var burst: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "finale_explosion":
			burst = instance
	t.check(burst != null and burst.global_position == stands,
			"an explosion goes off where she stands")
	if burst and behind != Vector2.INF:
		t.check(burst.contribution_at(behind) > 0.0,
				"and the bang reaches her behind the wall: it came through the walls from outside"
				+ " (%.1f)" % burst.contribution_at(behind))
	player.free()
	events.free()
	scene.free()

## The debug view's fields layer draws an outline only where the meter would read it: a musician
## beside a building two tiles thick has the part of his outline past the building's middle cut
## away, every point left on it is one his field reaches by his own wall answer, every open corner of
## the outline is still drawn, each cut ends within a pixel of where that answer turns, and on open
## ground the same outline is the whole closed loop.
func _test_the_fields_layer_is_cut_where_a_wall_stops_the_field(t) -> void:
	var def := EventCatalogue.by_id("busker")
	# A map wide enough that the outline stays on it: ground off the map counts as building.
	var at := Vector2(304.0, 384.0)
	var behind := _musician(def, at, _map_with(_rect_tiles(Rect2i(11, 0, 2, 24)), 24, 24))
	var beside := _musician(def, at, _map_with([], 24, 24))
	var outline := GroundShape.field_outline_at(at, Vector2.ZERO, def.outer_radius)
	var whole := DebugLayers.open_runs(outline, at, beside.wall_grid())
	t.check(whole.size() == 1 and whole[0].size() == outline.size() + 1
			and whole[0][0] == whole[0][whole[0].size() - 1],
			"on open ground the outline is drawn whole, closed")
	var runs := DebugLayers.open_runs(outline, at, behind.wall_grid())
	var kept := 0
	for point in outline:
		if not behind._walled_off(at, point):
			kept += 1
	t.check(kept > 0 and kept < outline.size(),
			"the musician's outline runs both sides of the building (%d of %d points open)"
			% [kept, outline.size()])
	var corners := 0
	for run in runs:
		for point in run:
			if outline.has(point):
				corners += 1
	var through := 0
	var loose := 0
	for run in runs:
		for i in run.size() - 1:
			for step in 5:
				if behind._walled_off(at, run[i].lerp(run[i + 1], float(step) / 4.0)):
					through += 1
		var past_end := run[run.size() - 1] \
				+ (run[run.size() - 1] - run[run.size() - 2]).normalized()
		var past_start := run[0] + (run[0] - run[1]).normalized()
		if not behind._walled_off(at, past_end) or not behind._walled_off(at, past_start):
			loose += 1
	t.check(runs.size() == 1, "behind one building it is one open stretch (%d)" % runs.size())
	t.check(corners == kept, "carrying every open corner of the outline (%d of %d)" % [corners, kept])
	t.check(through == 0, "nothing drawn is behind the wall (%d samples were)" % through)
	t.check(loose == 0, "and each cut stops within a pixel of the wall's answer turning")
	behind.free()
	beside.free()

## The layer skips the wall questions for an outline when nothing within its bounds is deep enough in
## a building to wall a line (`DebugLayers._deep_ground_meets()`), which is only right if every line
## a wall does block crosses such ground. Asked of seeded lines from open ground, up to the widest
## field's reach, on a real city and on hand-built maps of scattered buildings, where one-tile walls,
## bends and corners open only diagonally are common: every blocked line has deep ground in its
## bounds, and the guards count both that some were blocked and that the skip is taken for others.
func _test_the_fields_layer_skips_only_where_no_wall_can_block(t) -> void:
	var maps: Array[CityMap] = [CityGenerator.generate(4242)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1004
	for i in 6:
		var scattered: Array[Vector2i] = []
		for tile in _rect_tiles(Rect2i(0, 0, 16, 16)):
			if rng.randf() < 0.45:
				scattered.append(tile)
		maps.append(_map_with(scattered, 16, 16))
	for map in maps:
		var open: Array[Vector2i] = []
		for tile in _rect_tiles(Rect2i(Vector2i.ZERO, map.size)):
			if map.is_walkable(tile):
				open.append(tile)
		var reach := 260.0 if map.size.x > 16 else 120.0
		var blocked := 0
		var skipped := 0
		var missed := 0
		for i in 1500:
			var from := map.tile_to_world(open[rng.randi_range(0, open.size() - 1)]) \
					+ Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-15.0, 15.0))
			var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, reach)
			var deep := DebugLayers._deep_ground_meets(map, Rect2(from, Vector2.ZERO).expand(to))
			if map.wall_between(from, to):
				blocked += 1
				if not deep:
					missed += 1
			elif not deep:
				skipped += 1
		t.check(blocked > 50 and skipped > 20 and missed == 0,
				"on a %dx%d map the skip is taken (%d lines) and never for one a wall blocks (%d of %d)"
				% [map.size.x, map.size.y, skipped, missed, blocked])

## **The whole outline, not only its corners.** A wall can fall between two corners of an outline —
## the widest rows' outlines have edges of a hundred pixels and more — so on a real city, at the
## radii of the busiest and the widest fields, every outline is walked a pixel at a time and each
## point is asked against `wall_between()` from the source. What the layer draws through a wall, and
## what it leaves out where the field reaches, are each never longer than `_MISDRAWN_AT_MOST`, a
## third of a tile — stated here rather than read off the layer's own piece length, so a layer that
## asked in longer pieces fails it. The guard counts outlines a wall actually cut, so a sweep that met
## no buildings cannot pass.
const _MISDRAWN_AT_MOST := 10.0

func _test_the_fields_layer_follows_the_wall_along_the_whole_outline(t) -> void:
	var map := CityGenerator.generate(4242)
	var walkable := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 642
	var allowed := _MISDRAWN_AT_MOST
	for radius in [120.0, 260.0, 340.0]:
		var cut := 0
		var worst_through := 0.0
		var worst_missing := 0.0
		for n in 60:
			var source := map.tile_to_world(walkable[rng.randi_range(0, walkable.size() - 1)])
			var outline := GroundShape.field_outline_at(source, Vector2.ZERO, radius)
			var runs := DebugLayers.open_runs(outline, source, map)
			var buckets := _run_buckets(runs)
			var through := 0.0
			var missing := 0.0
			var walled_any := false
			for i in outline.size():
				var from := outline[i]
				var to := outline[(i + 1) % outline.size()]
				var steps := ceili(from.distance_to(to))
				var step := from.distance_to(to) / float(steps)
				for k in steps:
					var at := from.lerp(to, float(k) / float(steps))
					var walled := map.wall_between(source, at)
					var drawn := _on_a_run(buckets, at)
					walled_any = walled_any or walled
					through = through + step if walled and drawn else 0.0
					missing = missing + step if not walled and not drawn else 0.0
					worst_through = maxf(worst_through, through)
					worst_missing = maxf(worst_missing, missing)
			if walled_any:
				cut += 1
		t.check(cut > 5, "at %.0fpx walls cut some of the outlines (%d of 60)" % [radius, cut])
		t.check(worst_through <= allowed,
				"and nothing drawn runs through a wall further than a third of a tile (%.1fpx at most)"
				% worst_through)
		t.check(worst_missing <= allowed,
				"nor is an open stretch left out for longer (%.1fpx at most)" % worst_missing)

## Every segment of every run, by the 16px cell each of its points every 4px falls in, so a point
## can ask only the segments near it whether it is on one.
func _run_buckets(runs: Array[PackedVector2Array]) -> Dictionary:
	var buckets := {}
	for run in runs:
		for i in run.size() - 1:
			var segment := [run[i], run[i + 1]]
			var steps := maxi(1, ceili(run[i].distance_to(run[i + 1]) / 4.0))
			for k in steps + 1:
				var cell := Vector2i((run[i].lerp(run[i + 1], float(k) / float(steps)) / 16.0).floor())
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var key := cell + Vector2i(dx, dy)
						if not buckets.has(key):
							buckets[key] = []
						buckets[key].append(segment)
	return buckets

func _on_a_run(buckets: Dictionary, at: Vector2) -> bool:
	for segment: Array in buckets.get(Vector2i((at / 16.0).floor()), []):
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < 0.3:
			return true
	return false

## Event source for the layer's own loop: the instances it is handed, under the name it reads.
class _Source extends Node:
	var live: Array[EventInstance] = []
	func instances() -> Array[EventInstance]:
		return live

## **A source that moves is cut again where it now stands.** The layer keeps last frame's cut while
## an outline is unchanged; a musician moved a tile closer to the building between two frames has an
## outline the building cuts differently, and the second frame draws that cut, not the first.
func _test_the_fields_layer_cuts_a_moved_source_again(t) -> void:
	var def := EventCatalogue.by_id("busker")
	var map := _map_with(_rect_tiles(Rect2i(11, 0, 2, 24)), 24, 24)
	var musician := _musician(def, Vector2(272.0, 384.0), map)
	var source := _Source.new()
	source.live.append(musician)
	var layers := DebugLayers.new()
	layers.setup(source, null, null, null)
	var everywhere := Rect2(-1e5, -1e5, 2e5, 2e5)
	var first: Array = layers.field_runs(everywhere)
	var again: Array = layers.field_runs(everywhere)
	t.check(first.size() == 2 and str(again) == str(first),
			"standing still, the musician's two outlines are cut the same way twice")
	musician.position = Vector2(320.0, 384.0)
	var moved: Array = layers.field_runs(everywhere)
	var expected: Array = []
	for level: float in [def.inner_radius, def.outer_radius]:
		expected.append(DebugLayers.open_runs(def.shape.field_outline(musician.position,
				musician.solid_axis(), Vector2.ZERO, level) if def.shape != null
				else GroundShape.field_outline_at(musician.position, Vector2.ZERO, level),
				musician.position, map))
	t.check(moved.size() == 2 and str(moved[1][0]) != str(first[1][0]),
			"moved a tile and a half nearer the building, its outer outline is cut anew")
	t.check(moved.size() == 2 and str(moved[0][0]) == str(expected[0])
			and str(moved[1][0]) == str(expected[1]),
			"exactly as a fresh cut where it now stands")
	layers.free()
	source.free()
	musician.free()

## **No outline that reaches the screen is culled.** The layer decides from the emitter's own point
## and the level, before it builds the outline (`DebugLayers._may_be_seen()`); over seeded fields —
## standing points and stadiums, and moving ones at every speed up to past the eccentricity cap —
## and a screen-sized view placed round each, every outline whose bounds meet the view is kept. The
## guards count both kinds, so the sweep is not vacuous.
func _test_the_fields_layer_never_culls_an_outline_on_screen(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6420
	var seen := 0
	var unseen := 0
	var culled_on_screen := 0
	for i in 4000:
		var level := rng.randf_range(10.0, 520.0)
		var spine := rng.randf_range(0.0, 60.0) if rng.randf() < 0.5 else 0.0
		var shape := GroundShape.segment(spine, 6.0) if spine > 0.0 else GroundShape.point(6.0)
		var axis := Vector2.from_angle(rng.randf() * TAU)
		var velocity := Vector2.ZERO if rng.randf() < 0.4 \
				else Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 600.0)
		var at := Vector2(rng.randf_range(-1500.0, 1500.0), rng.randf_range(-1500.0, 1500.0))
		var outline := shape.field_outline(at, axis, velocity, level)
		var view := Rect2(Vector2(-320.0, -180.0), Vector2(640.0, 360.0))
		var bounds := DebugLayers._bounds_of(outline)
		var shown := DebugLayers._may_be_seen(view, at, level, spine)
		if view.intersects(bounds):
			seen += 1
			if not shown:
				culled_on_screen += 1
		elif not shown:
			unseen += 1
	t.check(seen > 200 and unseen > 200,
			"the sweep met outlines on screen (%d) and culled ones off it (%d)" % [seen, unseen])
	t.check(culled_on_screen == 0, "and culled none that reach the screen (%d were)"
			% culled_on_screen)
