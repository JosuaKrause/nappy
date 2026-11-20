extends RefCounted
## `WayOn`: the next leg of a route worked out as it goes. A row of the road drives from junction box
## to junction box, straight on where the street beyond the next box is a through road and otherwise
## round the corner in that box, away from her first; a row on foot walks straight on; and one check
## says whether a car may drive a stretch (`drives_clear()`).
##
## On a hand-drawn lattice of three by three junction boxes, laid as every city's streets are
## (`StreetLayout.lay()`), with a real `ThroughRoads` and the map's own navigator: both are pure
## functions of the map the legs are asked against, and a fake of either would only restate the
## lattice the test draws. The day's rule is a function the test hands in.

## Three boxes along each axis: two periods of the lattice and a street's width.
const SIZE := 2 * Tuning.BLOCK_SIZE + 3 * Tuning.STREET_WIDTH
const TILE := Tuning.TILE_SIZE

var _patrol := EventCatalogue.by_id("police_patrol").as_sent_ahead()
var _walker := EventCatalogue.by_id("dog_walker").as_sent_ahead()

func run(t: TestRunner) -> void:
	_test_straight_on_to_the_far_edge_of_the_next_box(t)
	_test_a_turn_in_the_next_box_away_from_her(t)
	_test_a_closed_street_has_no_leg_and_a_stub_goes_on(t)
	_test_a_body_straight_on_takes_the_turn(t)
	_test_the_days_rule_asks_a_live_leg_and_not_a_leaving_one(t)
	_test_what_a_car_may_drive(t)
	_test_a_row_on_foot_walks_straight_on(t)

## The three by three lattice, its streets laid with no main road and no precinct.
static func _lattice() -> CityMap:
	var map := CityMap.new(Vector2i(SIZE, SIZE))
	map.index_posts()
	StreetLayout.lay(map)
	return map

## The way on over `map` as it stands now.
static func _way_on(map: CityMap) -> WayOn:
	return WayOn.new(map, Navigator.new(map), ThroughRoads.over(map, Mover.vehicle()))

## The centre of the lane of corridor `index` that drives `direction` (a unit along one axis).
static func _lane(index: int, direction: Vector2i) -> float:
	var vertical := direction.y != 0
	return CrowdLanes.lane_centre(index, CrowdLanes.road_lane(vertical,
			float(direction.y if vertical else direction.x)))

## Closes both lanes of the stretch leaving `box` `toward`, a tile into it.
static func _close(map: CityMap, box: Vector2i, toward: Vector2i) -> void:
	var period := CityMap.period()
	var closed := map.closed_tiles.duplicate()
	for lane: int in CrowdLanes.ROAD_OFFSETS:
		if toward.y != 0:
			closed[Vector2i(box.x * period + lane, box.y * period + Tuning.STREET_WIDTH + 2)] = true
		else:
			closed[Vector2i(box.x * period + Tuning.STREET_WIDTH + 2, box.y * period + lane)] = true
	map.closed_tiles = closed

## Whether every point of `leg`, every half tile, stands on carriageway.
static func _on_carriageway(map: CityMap, leg: PackedVector2Array) -> bool:
	for i in range(1, leg.size()):
		for k in 9:
			if not map.is_carriageway(map.world_to_tile(leg[i - 1].lerp(leg[i], k / 8.0))):
				return false
	return true

## Southbound down the middle street, before the middle box and from inside the box above it, and
## northbound from inside the bottom box: the leg runs straight through the next box to its far edge,
## in its own lane.
func _test_straight_on_to_the_far_edge_of_the_next_box(t: TestRunner) -> void:
	var way_on := _way_on(_lattice())
	var south := _lane(1, Vector2i.DOWN)
	for at: Vector2 in [Vector2(south, 9.5 * TILE), Vector2(south, 3.5 * TILE)]:
		var leg := way_on.next_leg(_patrol, at, Vector2.DOWN, Vector2.INF)
		t.check(leg.size() == 2 and leg[0] == at
				and leg[1].is_equal_approx(Vector2(south, 20.0 * TILE)),
				"southbound from %s, straight on to the middle box's far edge: %s" % [at, leg])
	var north := _lane(1, Vector2i.UP)
	var from := Vector2(north, 30.5 * TILE)
	var up := way_on.next_leg(_patrol, from, Vector2.UP, Vector2.INF)
	t.check(up.size() == 2 and up[1].is_equal_approx(Vector2(north, 14.0 * TILE)),
			"northbound from inside the bottom box, straight on to the middle box's far edge: %s" % up)

## With the street past the middle box closed, a car coming to it turns in it, away from her: west
## with her east of the box, east with her west of it, into the lane that drives that way, to the
## box's edge, by an arc that stays on carriageway. The same eastbound, with the street east of the
## middle box closed: south with her north, north with her south.
func _test_a_turn_in_the_next_box_away_from_her(t: TestRunner) -> void:
	var south_closed := _lattice()
	_close(south_closed, Vector2i(1, 1), Vector2i.DOWN)
	var east_closed := _lattice()
	_close(east_closed, Vector2i(1, 1), Vector2i.RIGHT)
	var centre := Vector2(17.0, 17.0) * TILE
	var southbound := Vector2(_lane(1, Vector2i.DOWN), 9.5 * TILE)
	var eastbound := Vector2(9.5 * TILE, _lane(1, Vector2i.RIGHT))
	var cases: Array[Array] = [
		[southbound, Vector2.DOWN, Vector2.RIGHT, Vector2(14.0 * TILE, _lane(1, Vector2i.LEFT))],
		[southbound, Vector2.DOWN, Vector2.LEFT, Vector2(20.0 * TILE, _lane(1, Vector2i.RIGHT))],
		[eastbound, Vector2.RIGHT, Vector2.UP, Vector2(_lane(1, Vector2i.DOWN), 20.0 * TILE)],
		[eastbound, Vector2.RIGHT, Vector2.DOWN, Vector2(_lane(1, Vector2i.UP), 14.0 * TILE)]]
	for case: Array in cases:
		var at: Vector2 = case[0]
		var heading: Vector2 = case[1]
		var her: Vector2 = centre + (case[2] as Vector2) * 8.0 * TILE
		var ends: Vector2 = case[3]
		var map := south_closed if heading == Vector2.DOWN else east_closed
		var way_on := _way_on(map)
		var leg := way_on.next_leg(_patrol, at, heading, her)
		t.check(leg.size() > 3 and leg[leg.size() - 1].is_equal_approx(ends),
				"driving %s with her %s of the box, it turns away from her to %s: %s"
				% [heading, case[2], ends, leg])
		t.check(_on_carriageway(map, leg) and way_on.drives_clear(_patrol, leg),
				"and the turn stays on carriageway")

## On the closed stretch itself, short of the closure, a car cannot drive to the next box and has no
## leg. On a stub that drives into the through roads (the north-west box's street south closed, so
## its street east is left a stub the survey drops, though every tile of it is a car's), a car driving
## east goes on straight through the next box, since nothing is asked of the stretch it is on but
## that it drives it clear.
func _test_a_closed_street_has_no_leg_and_a_stub_goes_on(t: TestRunner) -> void:
	var map := _lattice()
	_close(map, Vector2i(1, 1), Vector2i.DOWN)
	var leg := _way_on(map).next_leg(_patrol, Vector2(_lane(1, Vector2i.DOWN), 21.5 * TILE),
			Vector2.DOWN, Vector2.INF)
	t.check(leg.is_empty(), "on a closed street short of the closure there is no leg: %s" % leg)
	var stubbed := _lattice()
	_close(stubbed, Vector2i(0, 0), Vector2i.DOWN)
	var east := _lane(0, Vector2i.RIGHT)
	var on := _way_on(stubbed).next_leg(_patrol, Vector2(9.5 * TILE, east), Vector2.RIGHT,
			Vector2.INF)
	t.check(on.size() == 2 and on[1].is_equal_approx(Vector2(20.0 * TILE, east)),
			"on a stub into the through roads it goes on into them: %s" % on)

## A body put down after the walk's through roads were worked out, on the car's lane in the far half
## of the next box: straight on is refused, as `drives_clear()` asks each leg of the ground, and it
## turns away from her instead.
func _test_a_body_straight_on_takes_the_turn(t: TestRunner) -> void:
	var map := _lattice()
	var way_on := _way_on(map)
	var at := Vector2(_lane(1, Vector2i.DOWN), 9.5 * TILE)
	var her := Vector2(25.0, 9.0) * TILE
	var clear := way_on.next_leg(_patrol, at, Vector2.DOWN, her)
	var body: Array[Vector2i] = [map.world_to_tile(Vector2(at.x, 18.5 * TILE))]
	map.obstruct_tiles(1, body)
	var round := way_on.next_leg(_patrol, at, Vector2.DOWN, her)
	t.check(clear.size() == 2 and round.size() > 3
			and round[round.size() - 1].is_equal_approx(Vector2(14.0 * TILE,
			_lane(1, Vector2i.LEFT))),
			"straight on with the box clear (%s), round the corner away from her with a body on its "
			% clear + "lane (%s)" % round)

## A day's rule that refuses the leg straight on (a field kept clear over the street past the box,
## handed in as the director hands its own): a live row turns, and a row that is leaving, which the
## day does not ask, goes straight on.
func _test_the_days_rule_asks_a_live_leg_and_not_a_leaving_one(t: TestRunner) -> void:
	var way_on := _way_on(_lattice())
	var asked: Array[int] = [0]
	way_on.use_the_days_rule(func(leg: PackedVector2Array, _row: EventDef) -> bool:
		asked[0] += 1
		return leg[leg.size() - 1].y < 19.0 * TILE)
	var at := Vector2(_lane(1, Vector2i.DOWN), 9.5 * TILE)
	var live := way_on.next_leg(_patrol, at, Vector2.DOWN, Vector2.INF)
	var asked_live := asked[0]
	var leaving := way_on.leg_to_leave_by(_patrol, at, Vector2.DOWN, Vector2.INF)
	t.check(live.size() > 3 and asked_live > 1, "a live row is refused straight on and turns (%s)"
			% live)
	t.check(leaving.size() == 2 and asked[0] == asked_live,
			"and a leaving one goes straight on, the day not asked (%s)" % leaving)

## A car may drive a stretch of plain carriageway, and not over a precinct's paving, over a street a
## calm zone absorbed (park ground, which the convoy's mover, a figure's, would cross, so only
## `is_carriageway()` refuses it), into a closure, off the map or past a body.
func _test_what_a_car_may_drive(t: TestRunner) -> void:
	var south := _lane(0, Vector2i.DOWN)
	var leg := PackedVector2Array([Vector2(south, 7.5 * TILE), Vector2(south, 12.5 * TILE)])
	t.check(_way_on(_lattice()).drives_clear(_patrol, leg), "plain carriageway is a car's")
	var paved := _lattice()
	paved.add_precinct(Vector4i(1, 0, 0, 0))
	StreetLayout.lay(paved)
	t.check(not _way_on(paved).drives_clear(_patrol, leg), "a precinct's paving is not")
	var park := _lattice()
	park.fill_rect(Rect2i(Vector2i(int(south / TILE), 10), Vector2i.ONE), GameEnums.TileType.PARK)
	var convoy := EventCatalogue.by_id("military_convoy").as_sent_ahead()
	t.check(_way_on(_lattice()).drives_clear(convoy, leg)
			and not _way_on(park).drives_clear(convoy, leg), "nor a street a park took")
	var closed := _lattice()
	closed.closed_tiles = {Vector2i(int(south / TILE), 10): true}
	t.check(not _way_on(closed).drives_clear(_patrol, leg), "nor a closed street")
	var off := PackedVector2Array([Vector2(south, 30.5 * TILE), Vector2(south, 36.5 * TILE)])
	t.check(not _way_on(_lattice()).drives_clear(_patrol, off), "nor off the map")
	var bodied := _lattice()
	var way_on := _way_on(bodied)
	var body: Array[Vector2i] = [Vector2i(int(south / TILE), 10)]
	bodied.obstruct_tiles(1, body)
	t.check(not way_on.drives_clear(_patrol, leg), "nor past a body put down since")

## A row on foot walks straight on down its sidewalk, a street and a box (fourteen tiles), through the
## box it comes to; stopped short of a body; with no leg where a building or the map's edge is under
## two tiles on; and the same leg asked twice.
func _test_a_row_on_foot_walks_straight_on(t: TestRunner) -> void:
	var map := _lattice()
	var way_on := _way_on(map)
	var at := Vector2(15.5, 7.5) * TILE
	var leg := way_on.next_leg(_walker, at, Vector2.DOWN, Vector2.INF)
	t.check(leg.size() == 2 and is_equal_approx(leg[1].y - at.y, 14.0 * TILE),
			"fourteen tiles straight on: %s" % leg)
	t.check(way_on.next_leg(_walker, at, Vector2.DOWN, Vector2.INF) == leg,
			"and the same leg asked again")
	t.check(way_on.next_leg(_walker, at, Vector2.LEFT, Vector2.INF).is_empty(),
			"a building a tile on leaves no leg")
	t.check(way_on.next_leg(_walker, Vector2(15.5, 32.5) * TILE, Vector2.DOWN,
			Vector2.INF).is_empty(), "nor the map's edge a tile on")
	var body: Array[Vector2i] = [Vector2i(15, 12)]
	map.obstruct_tiles(1, body)
	var short := way_on.next_leg(_walker, at, Vector2.DOWN, Vector2.INF)
	t.check(short.size() == 2 and short[1].y < 12.0 * TILE and short[1].y - at.y >= 2.0 * TILE,
			"a body on its way stops it short: %s" % short)
