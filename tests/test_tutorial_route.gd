extends RefCounted
## `TutorialRoute`'s questions about a route laid by hand on a map of nothing but streets
## (`StreetMap`): which side streets open onto it past its first block, and which ground the day's
## other branches may not use. How `for_city()` chooses a route on a generated city, and what the
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
