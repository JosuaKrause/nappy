extends RefCounted
## `ThroughRoads`: the stretches of carriageway between two junction boxes a car can drive into and
## go on from without turning round, the 2-core of the boxes and the stretches that are a car's.
##
## On a hand-drawn lattice of three by three junction boxes, laid as every city's streets are
## (`StreetLayout.lay()`): a map is data, built as it is, and the one interaction asked is which
## stretches the survey keeps.

## Three boxes along each axis: two periods of the lattice and a street's width.
const SIZE := 2 * Tuning.BLOCK_SIZE + 3 * Tuning.STREET_WIDTH

func run(t: TestRunner) -> void:
	_test_a_whole_lattice_is_all_through_roads(t)
	_test_a_box_paved_whole_takes_its_four_stretches(t)
	_test_a_closed_stretch_is_none_and_a_stub_it_leaves_is_dropped(t)
	_test_a_body_on_one_lane_takes_the_stretch(t)
	_test_a_single_street_has_none(t)

## The three by three lattice, its streets laid with no main road and no precinct.
static func _lattice() -> CityMap:
	var map := CityMap.new(Vector2i(SIZE, SIZE))
	map.index_posts()
	StreetLayout.lay(map)
	return map

## Every stretch of the lattice, `[box, toward]`, each once.
static func _stretches() -> Array[Array]:
	var all: Array[Array] = []
	for y in 3:
		for x in 3:
			if x < 2:
				all.append([Vector2i(x, y), Vector2i.RIGHT])
			if y < 2:
				all.append([Vector2i(x, y), Vector2i.DOWN])
	return all

## The stretches of `roads` that go on, as `"(x, y)->(dx, dy)"` names.
static func _through(roads: ThroughRoads) -> Array[String]:
	var named: Array[String] = []
	for stretch: Array in _stretches():
		var box: Vector2i = stretch[0]
		var toward: Vector2i = stretch[1]
		if roads.goes_on(box, toward):
			named.append("%s->%s" % [box, toward])
	return named

## All nine boxes joined: every one of the twelve stretches is a through road, asked from either
## box.
func _test_a_whole_lattice_is_all_through_roads(t: TestRunner) -> void:
	var roads := ThroughRoads.over(_lattice(), Mover.vehicle())
	t.check(_through(roads).size() == 12, "every stretch of a whole lattice goes on (%d of 12)"
			% _through(roads).size())
	t.check(roads.goes_on(Vector2i(1, 1), Vector2i.LEFT) and roads.goes_on(Vector2i(0, 1),
			Vector2i.RIGHT), "and a stretch is the same asked from either of its boxes")

## A precinct over the middle box (on the north-south street through it, blocks 0 and 1, so the
## middle box is inside its span and paved whole): its four stretches are not through roads, and the
## ring round it is, each of its boxes keeping two.
func _test_a_box_paved_whole_takes_its_four_stretches(t: TestRunner) -> void:
	var map := _lattice()
	map.add_precinct(Vector4i(1, 1, 0, 1))
	StreetLayout.lay(map)
	var roads := ThroughRoads.over(map, Mover.vehicle())
	var into_the_box := 0
	for toward: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if roads.goes_on(Vector2i(1, 1), toward):
			into_the_box += 1
	t.check(into_the_box == 0, "no stretch into a box paved whole goes on (%d)" % into_the_box)
	t.check(_through(roads).size() == 8, "and the eight of the ring round it do (%s)"
			% ", ".join(_through(roads)))

## The stretch from the north-west box south closed (`CityMap.closed_tiles`, which stops a car): it
## is not a through road, and the north-west box is left one stretch, east, so that stub is dropped
## too, though every tile of it is a car's; the box east of it keeps two and stays. Fails with the
## dropping loop removed: the stub answers true.
func _test_a_closed_stretch_is_none_and_a_stub_it_leaves_is_dropped(t: TestRunner) -> void:
	var map := _lattice()
	var closed := {}
	var period := CityMap.period()
	for lane: int in CrowdLanes.ROAD_OFFSETS:
		closed[Vector2i(lane, period - 3)] = true
	map.close_streets([FakeClosure.over_set(closed)] as Array[RoadClosure])
	var roads := ThroughRoads.over(map, Mover.vehicle())
	t.check(not roads.goes_on(Vector2i(0, 0), Vector2i.DOWN), "a closed stretch does not go on")
	t.check(not roads.goes_on(Vector2i(0, 0), Vector2i.RIGHT),
			"nor the stub it leaves at the corner, with nowhere to go on to but back")
	t.check(roads.goes_on(Vector2i(1, 0), Vector2i.RIGHT) and roads.goes_on(Vector2i(0, 1),
			Vector2i.DOWN), "and the rest does (%d of 12)" % _through(roads).size())

## A body standing on one lane of the middle box's east stretch (`CityMap.obstruct_tiles()`, which
## stops a car): that stretch is not a through road.
func _test_a_body_on_one_lane_takes_the_stretch(t: TestRunner) -> void:
	var map := _lattice()
	var period := CityMap.period()
	var tiles: Array[Vector2i] = [Vector2i(period + Tuning.STREET_WIDTH + 2,
			period + CrowdLanes.ROAD_OFFSETS[1])]
	map.obstruct_tiles(1, tiles)
	var roads := ThroughRoads.over(map, Mover.vehicle())
	t.check(not roads.goes_on(Vector2i(1, 1), Vector2i.RIGHT),
			"a stretch with a body on one lane does not go on")
	t.check(roads.goes_on(Vector2i(1, 1), Vector2i.LEFT), "and the stretch the other way does")

## A lattice that is one street, the boxes of one row joined and nothing else: every box keeps two
## at the most and the ends one, so the whole street is dropped.
func _test_a_single_street_has_none(t: TestRunner) -> void:
	var map := _lattice()
	var period := CityMap.period()
	for row: int in [1, 2]:
		map.fill_rect(Rect2i(0, row * period, SIZE, Tuning.STREET_WIDTH),
				GameEnums.TileType.BUILDING)
	var roads := ThroughRoads.over(map, Mover.vehicle())
	t.check(_through(roads).is_empty(), "a lattice that is a single street has no through road (%s)"
			% ", ".join(_through(roads)))
