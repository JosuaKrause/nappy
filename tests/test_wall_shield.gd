extends RefCounted
## Excitement does not go through a wall — `CityMap.wall_between()`, the line every source's
## `contribution_at()` asks — *(plaid-wombat, inbox #554: "Excitement should not go through any
## wall but it's not straightforward. If the player is partially in a wall they should not be
## protected so the blocking should happen in the middle of the wall (or one tile deep)"; inbox
## #568: "half a tile was only supposed to be done if the wall is only one tile wide otherwise it
## should be one tile")*: the geometry's own edge cases on hand-built maps, a sweep against a
## sampled depth on a real city, and the three readers (the meter's sum, the halo's pick and the
## caret's projection) agreeing.

const _SIZE := float(Tuning.TILE_SIZE)

## Lines whose two directions answered differently, checked once every hand-built case has run.
var _asymmetric := 0

func run(t) -> void:
	_test_the_depth_sits_between_her_body_and_a_tile(t)
	_test_a_wall_one_tile_thick_blocks_at_its_middle(t)
	_test_a_thicker_building_blocks_a_tile_deep(t)
	_test_a_one_tile_wall_blocks_at_its_corner_too(t)
	_test_grazing_a_corner_shields_nothing(t)
	_test_a_line_deep_across_a_corner_is_blocked(t)
	_test_her_body_in_a_wall_is_not_shielded(t)
	_test_a_corner_open_only_diagonally_is_shallow_round_its_point(t)
	_test_exact_geometry_agrees_with_a_sampled_depth(t)
	_test_an_event_is_silent_behind_a_wall(t)
	_test_a_crowd_body_is_silent_behind_a_wall(t)
	_test_the_caret_asks_the_wall_where_the_bodies_will_be(t)
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
## ground on both sides, and every line across it, square or slanted, passes that middle.
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

## A wall two tiles thick, x 4 to 5 (128 to 192px): its middle, x = 160, is a whole tile from open
## ground, and every line across it passes there; a line that reaches only part of the way in is not
## blocked, however far past half a tile it gets.
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
