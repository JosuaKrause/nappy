extends RefCounted
## `TutorialRoute`'s questions about a route laid by hand on a map of nothing but streets
## (`StreetMap`): which side streets open onto it past its first block, which ground the day's
## other branches may not use, and on a longer one the lessons' streets and the line she walks. How `for_city()` chooses a route on a generated city, and what the
## seals make of it, is `tests/test_seals.gd`'s, on day 1's whole plan.

## The route: the doorstep's street runs west from junction (2, 2), the first lesson street south
## to (2, 3), the second east to (3, 3); the park is the block south-east of the far junction.
const FIRST := Vector2i(2, 2)
const TURN := Vector2i(2, 3)
const FAR := Vector2i(3, 3)

## The park's ground: the block south-east of the far junction.
static func _park() -> Rect2i:
	return Rect2i(FAR * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH,
			Vector2i.ONE * (CityMap.period() - Tuning.STREET_WIDTH))

func run(t: TestRunner) -> void:
	var map := StreetMap.full()
	var route := _route(map)
	_test_the_side_streets_past_the_first_block(t, map, route)
	_test_the_kept_ground(t, map, route)
	_test_the_park_among_the_blocks_she_settled_in(t, route)
	_test_a_zone_block_of_the_park(t)
	_test_the_lessons_count_back_from_the_parks_street(t, map)
	_test_the_line_crosses_lesson_fours_street_and_keeps_the_park_side(t, map)
	_test_a_route_of_six_lesson_streets_leaves_its_first_empty(t, map)

func _arm(map: CityMap, junction: Vector2i, toward: Vector2i) -> StreetNetwork.Segment:
	for segment in map.street_network().at_junction(junction):
		if segment.other_end(junction) == toward:
			return segment
	return null

func _route(map: CityMap) -> TutorialRoute:
	var streets: Array[StreetNetwork.Segment] = [_arm(map, FIRST, TURN), _arm(map, TURN, FAR)]
	var junctions: Array[Vector2i] = [FIRST, TURN, FAR]
	return TutorialRoute.new(map, _arm(map, FIRST, FIRST + Vector2i.LEFT), streets, junctions,
			FAR, _park())

## Every street meeting the route at a junction past the first that is not a lesson street, once per
## end on the route, with the end that opens onto it; none at the first junction, where she may
## turn off.
func _test_the_side_streets_past_the_first_block(t: TestRunner, map: CityMap,
		route: TutorialRoute) -> void:
	var wanted := {
		_arm(map, TURN, TURN + Vector2i.LEFT).key(): TURN,
		_arm(map, TURN, TURN + Vector2i.DOWN).key(): TURN,
		_arm(map, FAR, FAR + Vector2i.UP).key(): FAR,
		_arm(map, FAR, FAR + Vector2i.RIGHT).key(): FAR,
		_arm(map, FAR, FAR + Vector2i.DOWN).key(): FAR,
	}
	var found := {}
	for mouth in route.side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		var at_a: bool = mouth[1]
		found[segment.key()] = segment.a if at_a else segment.b
	t.check(found == wanted,
			"the side streets past the first block are %s, each at its end on the route (got %s)"
			% [wanted, found])

## The other branches keep off the lesson streets, every junction box past the first, the half of
## each side street nearest the route and the park; the first junction box and a side street's far
## half stay theirs.
func _test_the_kept_ground(t: TestRunner, map: CityMap, route: TutorialRoute) -> void:
	var kept := route.kept_ground()
	for segment: StreetNetwork.Segment in [_arm(map, FIRST, TURN), _arm(map, TURN, FAR)]:
		t.check(_all_in(map, segment.tile_rect(), kept),
				"a lesson street %s is kept" % segment.key())
	t.check(_all_in(map, _box(FAR), kept) and _all_in(map, _box(TURN), kept),
			"the junction boxes past the first are kept")
	t.check(_none_in(map, _box(FIRST), kept), "the first junction box is not kept")
	t.check(route.walked_ground().has(_box(FIRST).position),
			"the route walks the first junction box all the same")
	t.check(_all_in(map, _park(), kept), "the park is kept")
	for mouth in route.side_street_mouths():
		var segment: StreetNetwork.Segment = mouth[0]
		var at_a: bool = mouth[1]
		t.check(_all_in(map, segment.mouth_rect(at_a), kept),
				"side street %s is kept at its mouth on the route" % segment.key())
		t.check(_none_in(map, segment.mouth_rect(not at_a), kept),
				"side street %s is not kept at its far end" % segment.key())

func _box(junction: Vector2i) -> Rect2i:
	return Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)

func _all_in(map: CityMap, rect: Rect2i, tiles: Dictionary) -> bool:
	for tile in map.rect_tiles(rect):
		if not tiles.has(tile):
			return false
	return true

func _none_in(map: CityMap, rect: Rect2i, tiles: Dictionary) -> bool:
	for tile in map.rect_tiles(rect):
		if tiles.has(tile):
			return false
	return true

## The park she settled in is found among the blocks she settled in, by any block of it; blocks
## elsewhere are not the park.
func _test_the_park_among_the_blocks_she_settled_in(t: TestRunner, route: TutorialRoute) -> void:
	var with_the_park: Array[Vector2i] = [TURN, FAR]
	t.check(route.has_its_park_among(with_the_park), "a settled block in the park is the park")
	var elsewhere: Array[Vector2i] = [FIRST, TURN]
	t.check(not route.has_its_park_among(elsewhere), "settled blocks elsewhere are not the park")
	var nowhere: Array[Vector2i] = []
	t.check(not route.has_its_park_among(nowhere), "and no settled block is not the park")

## **A calm zone's other block is the park too**: she may settle in a block of a two-block park that
## is not its anchor, and `has_its_park_among()` names the park by the block's anchor
## (`CityMap.anchor_of()`). The zone is recorded on its own map the way the generator records one
## (`CityMap.record_zone_member()`); on a map with no zone, the same block is not the park.
func _test_a_zone_block_of_the_park(t: TestRunner) -> void:
	var beside := FAR + Vector2i.RIGHT
	var settled: Array[Vector2i] = [beside]
	t.check(not _route(StreetMap.full()).has_its_park_among(settled),
			"with no zone, the block beside the park is not the park")
	var zoned := StreetMap.full()
	zoned.record_zone_member(FAR, FAR)
	zoned.record_zone_member(beside, FAR)
	t.check(_route(zoned).has_its_park_among(settled),
			"in a two-block park, a settled block that is not its anchor is the park")

# ------------------------------------------------------------------- lessons ---

## A route of five lesson streets: south from (2, 2), east twice, south, east, the park south of
## the last street; `first` puts one more lesson street before them, south from (2, 1).
static func _lesson_route(map: CityMap, first := false) -> TutorialRoute:
	var junctions: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3),
			Vector2i(4, 3), Vector2i(4, 4), Vector2i(5, 4)]
	if first:
		junctions.push_front(Vector2i(2, 1))
	var streets: Array[StreetNetwork.Segment] = []
	for i in range(1, junctions.size()):
		streets.append(_arm_of(map, junctions[i - 1], junctions[i]))
	var park := Rect2i(Vector2i(4, 4) * CityMap.period() + Vector2i(0, Tuning.STREET_WIDTH),
			Vector2i(CityMap.period(), CityMap.period() - Tuning.STREET_WIDTH))
	return TutorialRoute.new(map, _arm_of(map, junctions[0], junctions[0] + Vector2i.LEFT),
			streets, junctions, Vector2i(4, 4), park)

static func _arm_of(map: CityMap, junction: Vector2i, toward: Vector2i) -> StreetNetwork.Segment:
	for segment in map.street_network().at_junction(junction):
		if segment.other_end(junction) == toward:
			return segment
	return null

## Which side of `segment`'s rect `band` is: 0 for its first, 1 for its second.
static func _side(segment: StreetNetwork.Segment, band: Rect2i) -> int:
	return 0 if band.position == segment.tile_rect().position else 1

## **The lessons count back from the park's street**, which carries none: the yeller the street
## before it, the crossing with no cars at the start of the street before his, the dog walker's and
## the stall's before that; the crossing with cars at the far end of the crossing's street.
func _test_the_lessons_count_back_from_the_parks_street(t: TestRunner, map: CityMap) -> void:
	var route := _lesson_route(map)
	var streets := route.lesson_streets()
	t.check(route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE) == streets[0]
			and route.lesson_street(TutorialRoute.Lesson.NOISE_WITH_LESS_ROOM) == streets[1]
			and route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_NO_CARS) == streets[2]
			and route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER) == streets[3],
			"the lessons stand on the four streets before the park's, in order")
	t.check(route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_CARS) == null,
			"the crossing with cars is a junction, not a street")
	t.check(route.crossing_with_no_cars() == Vector2i(3, 3),
			"lesson (4) is crossed at the start of its street (%s)" % route.crossing_with_no_cars())
	t.check(route.crossing_with_cars() == Vector2i(4, 3),
			"lesson (5) is crossed at the far end of lesson (4)'s street (%s)"
			% route.crossing_with_cars())
	t.check(route.is_on_lesson(TutorialRoute.Lesson.NOISE_WITH_LESS_ROOM,
			streets[1].tile_rect().get_center())
			and not route.is_on_lesson(TutorialRoute.Lesson.NOISE_WITH_LESS_ROOM,
			streets[0].tile_rect().get_center()),
			"she is on lesson (3)'s street on its tiles alone")
	t.check(_route(map).lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE) == null
			and _route(map).crossing_with_no_cars() == TutorialRoute.NO_JUNCTION,
			"a route too short for the first lessons has none of them")

## **The line changes side across lesson (4)'s street at its start**, so the sidewalk she arrives
## toward is the far one, which the van shuts, **and keeps to the park's side on the last street**,
## where the tree's branch reaches the park; the line's ground holds the line's sidewalks and not
## the far ones.
func _test_the_line_crosses_lesson_fours_street_and_keeps_the_park_side(t: TestRunner,
		map: CityMap) -> void:
	var route := _lesson_route(map)
	var streets := route.lesson_streets()
	t.check(_side(streets[2], route.far_sidewalk(streets[2]))
			== _side(streets[1], route.line_sidewalk(streets[1])),
			"lesson (4)'s far sidewalk is on the side she arrives on from lesson (3)'s street")
	t.check(_side(streets[4], route.line_sidewalk(streets[4])) == 1,
			"the line keeps to the park's side of the last street")
	var ground := route.line_ground()
	var line_held := true
	var far_left := true
	for segment in streets:
		for tile in map.rect_tiles(route.line_sidewalk(segment)):
			line_held = line_held and ground.has(tile)
		for tile in map.rect_tiles(route.far_sidewalk(segment)):
			far_left = far_left and not ground.has(tile)
	t.check(line_held and far_left, "the line's ground is the line's sidewalks, not the far ones")

## **A route of six lesson streets leaves its first one empty**: the lessons still count back from
## the park's street.
func _test_a_route_of_six_lesson_streets_leaves_its_first_empty(t: TestRunner,
		map: CityMap) -> void:
	var route := _lesson_route(map, true)
	t.check(route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE) == route.lesson_streets()[1],
			"the stall stands on the second lesson street of six")
