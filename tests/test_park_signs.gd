extends RefCounted
## `ParkSigns`: where the run's park signs stand and which way each points, on a map of nothing but
## streets (`StreetMap`) with a tutorial route laid by hand, the home block recorded and the calm
## blocks planned, so each case is the one interaction it names. How `TutorialRoute.for_city()`
## chooses a route on a generated city is `tests/test_seals.gd`'s; how a sign is drawn is
## `tests/test_park_sign.gd`'s.

## The route: the doorstep's street runs west from junction (2, 2) to (1, 2), with the home block
## south of it; the first lesson street runs south to (2, 3), the second east to (3, 3); the park is
## the block south-east of the far junction.
const TURN := Vector2i(2, 2)
const FAR_END := Vector2i(1, 2)
const SOUTH := Vector2i(2, 3)
const FAR := Vector2i(3, 3)
const HOME := Vector2i(1, 2)
const PARK := Vector2i(3, 3)

func run(t: TestRunner) -> void:
	_test_the_first_sign_points_down_the_first_lesson_street(t)
	_test_the_next_corner_is_used_where_the_best_has_no_sidewalk(t)
	_test_a_first_sign_pointing_straight_on_stands_on_the_home_side(t)
	_test_a_second_sign_points_back_where_the_park_is_nearest_that_way(t)
	_test_no_second_sign_where_another_calm_area_is_nearer(t)
	_test_no_sign_where_the_park_does_not_stay_calm(t)
	_test_no_sign_without_a_route(t)

## The streets with `calm` planned as `purpose` blocks (the park first), the home recorded and day
## 1's calm read off the plans.
func _map(calm: Array[Vector2i], arc: BlockPlan = null) -> CityMap:
	var map := StreetMap.full()
	map.record_home_block(HOME)
	for block in calm:
		map.plan_block(block, BlockPlan.of(GameEnums.BlockPurpose.PARK))
	if arc:
		map.plan_block(calm[0], arc)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 1)
	map.recompute_calm(state)
	return map

func _arm(map: CityMap, junction: Vector2i, toward: Vector2i) -> StreetNetwork.Segment:
	for segment in map.street_network().at_junction(junction):
		if segment.other_end(junction) == toward:
			return segment
	return null

func _route(map: CityMap) -> TutorialRoute:
	var streets: Array[StreetNetwork.Segment] = [_arm(map, TURN, SOUTH), _arm(map, SOUTH, FAR)]
	var junctions: Array[Vector2i] = [TURN, SOUTH, FAR]
	return TutorialRoute.new(map, _arm(map, TURN, FAR_END), streets, junctions, PARK,
			CityMap.block_rect(PARK))

## The tile at corner `corner` (each axis -1 or 1) of `junction`'s box.
func _corner(junction: Vector2i, corner: Vector2i) -> Vector2i:
	var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	return Vector2i(box.position.x if corner.x < 0 else box.end.x - 1,
			box.position.y if corner.y < 0 else box.end.y - 1)

## She comes east along the doorstep's street and turns south: the sign stands at that junction,
## points south, on the sidewalk corner between the arm she comes along and the one she turns down.
func _test_the_first_sign_points_down_the_first_lesson_street(t: TestRunner) -> void:
	var map := _map([PARK])
	var signs := ParkSigns.for_route(map, _route(map)).signs()
	t.check(not signs.is_empty(), "the route's first junction has a sign")
	if signs.is_empty():
		return
	var first := signs[0]
	t.check(first.junction() == TURN and first.points() == Vector2i.DOWN,
			"it stands where the route leaves the doorstep's street and points down the first "
			+ "lesson street (%s, %s)" % [first.junction(), first.points()])
	t.check(first.tile() == _corner(TURN, Vector2i(-1, 1))
			and map.tile_at(first.tile()) == GameEnums.TileType.SIDEWALK,
			"it stands on the sidewalk corner between the doorstep's street and the turn (%s)"
			% [first.tile()])

## A calm zone took the sidewalk of the best corner: the sign stands on the next one.
func _test_the_next_corner_is_used_where_the_best_has_no_sidewalk(t: TestRunner) -> void:
	var map := _map([PARK])
	map.set_tile(_corner(TURN, Vector2i(-1, 1)), GameEnums.TileType.BUILDING)
	var signs := ParkSigns.for_route(map, _route(map)).signs()
	t.check(not signs.is_empty() and signs[0].tile() == _corner(TURN, Vector2i(1, 1)),
			"the sign stands on the next corner's sidewalk (%s)"
			% [signs[0].tile() if not signs.is_empty() else null])

## The first lesson street continues straight on from the doorstep's street, east to (3, 2) and
## then south to the park: the sign points straight on and stands on the home block's side of the
## arm ahead, the south-east corner of the junction box.
func _test_a_first_sign_pointing_straight_on_stands_on_the_home_side(t: TestRunner) -> void:
	var map := _map([PARK])
	var ahead := Vector2i(3, 2)
	var streets: Array[StreetNetwork.Segment] = [_arm(map, TURN, ahead), _arm(map, ahead, FAR)]
	var junctions: Array[Vector2i] = [TURN, ahead, FAR]
	var route := TutorialRoute.new(map, _arm(map, TURN, FAR_END), streets, junctions, PARK,
			CityMap.block_rect(PARK))
	var signs := ParkSigns.for_route(map, route).signs()
	t.check(not signs.is_empty(), "a route straight on from the doorstep's street has a sign")
	if signs.is_empty():
		return
	t.check(signs[0].junction() == TURN and signs[0].points() == Vector2i.RIGHT
			and signs[0].tile() == _corner(TURN, Vector2i(1, 1)),
			"it points straight on from the home block's side of the arm ahead (%s, %s, %s)"
			% [signs[0].junction(), signs[0].points(), signs[0].tile()])

## From the doorstep street's other end the tutorial park is the only calm area, and a shortest way
## to it runs back past the first sign: a second sign there points back along the doorstep's street,
## on its home side.
func _test_a_second_sign_points_back_where_the_park_is_nearest_that_way(t: TestRunner) -> void:
	var map := _map([PARK])
	var signs := ParkSigns.for_route(map, _route(map)).signs()
	t.check(signs.size() == 2, "the doorstep street's other end has a sign too (%d)" % signs.size())
	if signs.size() < 2:
		return
	var back := signs[1]
	t.check(back.junction() == FAR_END and back.points() == Vector2i.RIGHT
			and back.tile() == _corner(FAR_END, Vector2i(1, 1)),
			"it points back along the doorstep's street from its home-side corner (%s, %s, %s)"
			% [back.junction(), back.points(), back.tile()])

## A park at the doorstep street's other end is nearer from there than the tutorial park: a sign
## there pointing back past her door would point past it, so none stands.
func _test_no_second_sign_where_another_calm_area_is_nearer(t: TestRunner) -> void:
	var calm: Array[Vector2i] = [PARK, Vector2i(0, 2)]
	var map := _map(calm)
	var signs := ParkSigns.for_route(map, _route(map)).signs()
	t.check(signs.size() == 1 and signs[0].junction() == TURN,
			"only the first junction has a sign where another park is nearer the far end (%d)"
			% signs.size())

## A park its arc may requisition would turn the sign false on the day it is, so the run has none.
func _test_no_sign_where_the_park_does_not_stay_calm(t: TestRunner) -> void:
	var arc := BlockPlan.of(GameEnums.BlockPurpose.PARK).then(
			GameEnums.BlockPurpose.REQUISITIONED, 9, GameEnums.BlockCause.SCHEDULED)
	var calm: Array[Vector2i] = [PARK]
	var map := _map(calm, arc)
	t.check(ParkSigns.for_route(map, _route(map)).signs().is_empty(),
			"no sign stands where the tutorial park may be requisitioned")

func _test_no_sign_without_a_route(t: TestRunner) -> void:
	t.check(ParkSigns.for_route(_map([PARK]), null).signs().is_empty(),
			"a city handed no tutorial route stands no sign")
