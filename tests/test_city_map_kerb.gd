extends RefCounted
## `CityMap.kerb_beside()`: where the kerb runs beside the carriageway lane a point stands in, the
## place a row that spans the street stands its body (`EventDef.stands_at_its_kerb()`, the
## roadblock). It is the lattice's geometry, so it is asked of points on a north-south street at
## tiles x 0..5, an east-west one at y 0..5, and the junction box where they meet, with no map;
## `kerb_across_from()` is asked of a generated one.

## A coordinate inside a block, three tiles past a corridor: ground off the streets.
const OFF_THE_CORRIDOR := Tuning.STREET_WIDTH + 3
const TILE := float(Tuning.TILE_SIZE)

func run(t: TestRunner) -> void:
	_test_the_road_across_from_each_sidewalk_tile(t)
	_test_a_lane_point_goes_to_its_own_kerb(t)
	_test_a_point_on_a_kerb_stays(t)
	_test_no_kerb_outside_one_corridors_carriageway(t)

## `CityMap.kerb_across_from()` on a generated map: from each of the two sidewalk tiles beside a
## kerb, on either side of a corridor and along either axis, it is the road tile against that kerb,
## the same tile from both, with the point's own place along the street kept. The first sidewalk
## tile found at each offset of the sidewalk bands is asked, so each of the eight answers is its own
## check; the generated map is the one that has corridors, junctions and blocks round them.
func _test_the_road_across_from_each_sidewalk_tile(t: TestRunner) -> void:
	var map := CityGenerator.generate(4242)
	var near_road := Tuning.SIDEWALK_WIDTH
	var far_road := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1
	var sidewalk_offsets: Array[int] = []
	for offset in Tuning.SIDEWALK_WIDTH:
		sidewalk_offsets.append(offset)
		sidewalk_offsets.append(Tuning.STREET_WIDTH - 1 - offset)
	var asked := {}
	var size := map.size_in_tiles()
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			var inward := map.pavement_inward(tile)
			if inward == Vector2i.ZERO:
				continue
			var along_x := inward.x != 0
			var offset := CityMap.corridor_offset(x if along_x else y)
			var key := "%s:%d" % ["x" if along_x else "y", offset]
			if asked.has(key) or not sidewalk_offsets.has(offset):
				continue
			asked[key] = true
			var base := (x if along_x else y) - offset
			var road := base + (near_road if offset < Tuning.SIDEWALK_WIDTH else far_road)
			var at := map.tile_to_world(tile)
			var answer := map.kerb_across_from(at)
			var answered := map.world_to_tile(answer)
			var road_tile := Vector2i(road, y) if along_x else Vector2i(x, road)
			t.check(answered == road_tile and Tile.is_road(map.tile_type_at_world(answer)),
					"from the sidewalk tile at offset %d of an %s-axis corridor the road tile "
					% [offset, key.left(1)] + "against its kerb is at %s (it answers %s)"
					% [road_tile, answered])
			var along := y if along_x else x
			t.check(answer.y == at.y if along_x else answer.x == at.x,
					"%s keeps its place along the street (%d)" % [key, along])
	t.check(asked.size() == 8, "all eight sidewalk offsets were found and asked (%d)" % asked.size())
	var road := map.tile_to_world(_a_road_tile(map))
	t.check(map.kerb_across_from(road) == Vector2.INF, "a point on the carriageway has no kerb across")

## The first carriageway tile found by scanning from the map's corner.
func _a_road_tile(map: CityMap) -> Vector2i:
	var size := map.size_in_tiles()
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			if Tile.is_road(map.tile_type_at_world(map.tile_to_world(tile))):
				return tile
	return Vector2i.ZERO

## A point in either carriageway lane goes across its street to the kerb on its own side, 64px or
## 128px from the corridor's edge, and stays where it was along the street.
func _test_a_lane_point_goes_to_its_own_kerb(t: TestRunner) -> void:
	var near_kerb := Tuning.SIDEWALK_WIDTH * TILE
	var far_kerb := (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * TILE
	for lane: int in [Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1]:
		var kerb := near_kerb if lane * 2 < Tuning.STREET_WIDTH else far_kerb
		var north_south := _centre(Vector2i(lane, OFF_THE_CORRIDOR)) + Vector2(3.0, 5.0)
		t.check(CityMap.kerb_beside(north_south).is_equal_approx(Vector2(kerb, north_south.y)),
				"a point in the lane at %.0fpx across a north-south street goes to the kerb at %.0fpx"
				% [north_south.x, kerb])
		var east_west := _centre(Vector2i(OFF_THE_CORRIDOR, lane)) + Vector2(-4.0, 2.0)
		t.check(CityMap.kerb_beside(east_west).is_equal_approx(Vector2(east_west.x, kerb)),
				"a point in the lane at %.0fpx across an east-west street goes to the kerb at %.0fpx"
				% [east_west.y, kerb])

## A point already on either kerb line is where asking again puts it, so a body moved there and
## stood again (`EventInstance.move_to()`) stays.
func _test_a_point_on_a_kerb_stays(t: TestRunner) -> void:
	var along := _centre(Vector2i(0, OFF_THE_CORRIDOR)).y
	for kerb: float in [Tuning.SIDEWALK_WIDTH * TILE,
			(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * TILE]:
		var on_it := Vector2(kerb, along)
		t.check(CityMap.kerb_beside(on_it) == on_it, "a point on the kerb at %.0fpx stays" % kerb)
		var once := CityMap.kerb_beside(on_it + Vector2(-9.0, 0.0))
		t.check(CityMap.kerb_beside(once) == once,
				"a point 9px short of the kerb at %.0fpx, stood twice, stays where once put it" % kerb)

## No kerb is beside a sidewalk, a junction box (in both corridors at once, with no one kerb) or
## ground off the streets: the point is kept.
func _test_no_kerb_outside_one_corridors_carriageway(t: TestRunner) -> void:
	var sidewalk := _centre(Vector2i(1, OFF_THE_CORRIDOR))
	t.check(CityMap.kerb_beside(sidewalk) == sidewalk, "a sidewalk point stays")
	var box_middle := _centre(Vector2i(Tuning.SIDEWALK_WIDTH, Tuning.SIDEWALK_WIDTH))
	t.check(CityMap.kerb_beside(box_middle) == box_middle, "a point in a junction box's middle stays")
	var zebra := _centre(Vector2i(Tuning.SIDEWALK_WIDTH, 0))
	t.check(CityMap.kerb_beside(zebra) == zebra, "a point on a junction box's zebra stays")
	var block := _centre(Vector2i(OFF_THE_CORRIDOR, OFF_THE_CORRIDOR))
	t.check(CityMap.kerb_beside(block) == block, "a point off the streets stays")

## The centre of `tile` in world space: tiles are `Tuning.TILE_SIZE` square from the origin.
func _centre(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
