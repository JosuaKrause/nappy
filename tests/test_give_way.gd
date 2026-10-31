extends RefCounted
## `GiveWay`, the street rules a crowd car and an event car both give way by: the box ahead, the red
## light, the zebra she waits at and the exemption for the main road. The two drivers' own tests
## (`test_police_car.gd`, `test_crowd.gd`, `test_turns.gd`) hold what each does with the answer; this
## holds the answers themselves, asked of a real map in plain values.

const TILE := float(Tuning.TILE_SIZE)

func run(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	_test_the_box_ahead(t, map)
	_test_the_stop_line_is_a_setback_short(t)
	_test_a_light_is_red_only_where_it_is_signalled_and_not_green(t, map)
	_test_the_main_road_does_not_give_way(t, map)
	_test_the_zebra_she_waits_at(t, map)
	_test_a_zebra_past_the_box(t, map)

func _test_the_box_ahead(t, map: CityMap) -> void:
	var period := CityMap.period()
	var low := float(2 * period) * TILE
	# In the block band before box 2, going up the axis: that box. Going down: the one behind.
	var before := low - 3.0 * TILE
	t.check(GiveWay.box_index(before, 1.0) == 2, "up the axis, the block band's box is the next")
	t.check(GiveWay.box_index(before, -1.0) == 1, "down the axis, it is the one behind")
	t.check(GiveWay.box_near_edge(2, 1.0) == low, "its near edge going up is its low edge")
	t.check(GiveWay.box_near_edge(2, -1.0) == low + float(Tuning.STREET_WIDTH) * TILE,
			"and going down its high edge")
	t.check(is_equal_approx(GiveWay.distance_to_box(before, 1.0, 10.0), 3.0 * TILE - 10.0),
			"the distance is from the nose, not the centre")
	t.check(GiveWay.distance_to_box(low + TILE, 1.0, 10.0) < 0.0, "negative once inside")
	t.check(GiveWay.junction_at(2, 5, true) == Vector2i(5, 2) and GiveWay.junction_at(2, 5, false)
			== Vector2i(2, 5), "a junction is keyed (column, row) whichever way it is driven")

func _test_the_stop_line_is_a_setback_short(t) -> void:
	t.check(GiveWay.stop_line(100.0) == 100.0 - Tuning.CAR_STOP_LINE_SETBACK,
			"the line is the setback short of what it stops for")
	t.check(GiveWay.stop_line(1.0) < 0.0, "one inside the setback is a negative room")

func _test_a_light_is_red_only_where_it_is_signalled_and_not_green(t, map: CityMap) -> void:
	t.check(not GiveWay.is_red(null, Vector2i.ZERO, true), "no signals, no red")
	var signals := TrafficSignals.new(map)
	var junction := Vector2i(map.main_road, 1)
	signals.elapsed = 0.0
	while signals.phase_of(junction) != TrafficSignals.Phase.MAIN_GREEN:
		signals.elapsed += 0.25
	t.check(signals.is_signalled(junction), "the main road's junctions are signalled")
	var vertical_green := signals.green_for(junction, true)
	t.check(GiveWay.is_red(signals, junction, not vertical_green) \
			and not GiveWay.is_red(signals, junction, vertical_green),
			"red is the arm that is not green")

func _test_the_main_road_does_not_give_way(t, map: CityMap) -> void:
	var ordinary := _a_zebra(map)
	t.check(ordinary != Vector2.INF, "found a zebra off the main road")
	if ordinary == Vector2.INF:
		return
	t.check(GiveWay.owes_her_way(map, false, ordinary - Vector2(100.0, 0.0), ordinary),
			"an ordinary street gives way to her at its zebra")
	t.check(not GiveWay.owes_her_way(map, false, ordinary, Vector2.INF),
			"to nobody, nothing")
	t.check(not GiveWay.owes_her_way(map, false, ordinary,
			ordinary + Vector2(0.0, float(Tuning.STREET_WIDTH) * TILE)),
			"and not to somebody in the next street over")
	# The spine runs north-south: a car driving along it is on the main road.
	var at := map.tile_to_world(Vector2i(map.main_road * CityMap.period() + 3, 20))
	t.check(map.street_kind_at(true, map.world_to_tile(at)) == GameEnums.StreetKind.MAIN,
			"a column of the main road is the main road")
	t.check(not GiveWay.owes_her_way(map, true, at, at), "the main road does not give way")

func _test_the_zebra_she_waits_at(t, map: CityMap) -> void:
	var zebra := _a_zebra(map)
	if zebra == Vector2.INF:
		return
	var paint := floorf(zebra.x / TILE) * TILE
	var from_the_west := zebra - Vector2(160.0, 0.0)
	var edge := GiveWay.zebra_edge_ahead(map, from_the_west, false, 1.0, zebra)
	t.check(edge <= paint and edge > paint - 2.0 * TILE and fmod(edge, TILE) == 0.0,
			"going east, the line is the near edge of the run of paint (%.0f, tile at %.0f)"
			% [edge, paint])
	t.check(GiveWay.zebra_edge_ahead(map, zebra + Vector2(160.0, 0.0), false, 1.0, zebra) == INF,
			"past it, there is none ahead")
	t.check(GiveWay.zebra_edge_ahead(map, from_the_west, false, 1.0,
			zebra + Vector2(0.0, 0.0) + Vector2(Tuning.CAR_ZEBRA_WAIT_RADIUS + TILE * 4.0, 0.0)) == INF,
			"nor where she waits further along than the paint's wait radius")
	t.check(GiveWay.zebra_edge_ahead(map, zebra + Vector2(160.0, 0.0), false, -1.0, zebra) > edge,
			"going west the near edge is the run's far side, further along than going east's")

func _test_a_zebra_past_the_box(t, map: CityMap) -> void:
	t.check(GiveWay.lies_past_the_box(300.0, 100.0, 1.0) and not GiveWay.lies_past_the_box(100.4, 100.0, 1.0),
			"further than half a pixel past the box's near edge")
	t.check(GiveWay.lies_past_the_box(100.0, 300.0, -1.0), "and the same going down the axis")
	var lane_y := _lane_to_the_main_road(map)
	if lane_y < 0:
		return
	var period := CityMap.period()
	var cross := (float(lane_y) + 0.5) * TILE
	var c := -1
	for candidate in range(1, map.main_road + 1):
		if map.is_crossing(Vector2i(candidate * period + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, lane_y)):
			c = candidate
			break
	t.check(c >= 0, "found a box with paint on the far side of it, going up the axis")
	if c < 0:
		return
	var first := c * period + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	var her := Vector2((float(first) + 0.5) * TILE, cross)
	t.check(GiveWay.waits_past_the_box(map, c, 1.0, cross, false, her),
			"waiting on the paint past the box is past it")
	t.check(not GiveWay.waits_past_the_box(map, c, 1.0, cross, false, her - Vector2(5.0 * TILE, 0.0)),
			"and not from the near side of the box")

func _lane_to_the_main_road(map: CityMap) -> int:
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) == Tuning.SIDEWALK_WIDTH \
				and map.tile_at(Vector2i(map.main_road * CityMap.period() - 4, y)) \
						== GameEnums.TileType.ROAD:
			return y
	return -1

## The centre of the first `CROSSING` tile on an east-west carriageway lane at a junction off the
## main road, or `INF`.
func _a_zebra(map: CityMap) -> Vector2:
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) < 0 or not CityMap.is_road_offset(CityMap.corridor_offset(y)):
			continue
		for x in range(12, map.size.x - 16):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.CROSSING:
				continue
			if map.tile_at(tile - Vector2i(5, 0)) != GameEnums.TileType.ROAD:
				continue
			if map.is_main_road(true, CityMap.junction_index(x + 2)):
				continue
			return map.tile_to_world(tile)
	return Vector2.INF
