extends RefCounted
## `DawnTutorial`, day 1's lessons stood on the tutorial route at dawn: the slot of each lesson's
## row, read off a fake route whose answers the test sets (`FakeRoute`, on a map of nothing but
## streets); and day 1 planned whole as the game plans it (`GameDawn`, the tree grown with the
## route, the seals standing), on generated cities. **It builds real cities for that second part,
## and says why**: the guarantee is the dawn's as a whole, the lessons judged by every rule of the
## day among the seals, then every unit drawn round them, which only the real planning reaches.

## A route on a map of nothing but streets whose lesson streets are the ones handed, each in order,
## its line on the first sidewalk of each and the far sidewalk the second.
class FakeRoute extends TutorialRoute:
	var _lessons: Array[StreetNetwork.Segment] = []

	func _init(streets: Array[StreetNetwork.Segment]) -> void:
		super(null, null, streets, [] as Array[Vector2i], Vector2i(-1, -1), Rect2i())
		_lessons = streets

	## Overrides TutorialRoute.lesson_street.
	func lesson_street(lesson: TutorialRoute.Lesson) -> StreetNetwork.Segment:
		match lesson:
			TutorialRoute.Lesson.NOISE_PASSED_WIDE:
				return _lessons[0]
			TutorialRoute.Lesson.CROSSING_WITH_NO_CARS:
				return _lessons[1]
			TutorialRoute.Lesson.TIMING_THE_YELLER:
				return _lessons[2]
		return null

	## Overrides TutorialRoute.line_sidewalk.
	func line_sidewalk(segment: StreetNetwork.Segment) -> Rect2i:
		return Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)[0]

	## Overrides TutorialRoute.far_sidewalk.
	func far_sidewalk(segment: StreetNetwork.Segment) -> Rect2i:
		return Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)[1]

	## Overrides TutorialRoute.crossing_with_no_cars.
	func crossing_with_no_cars() -> Vector2i:
		return _lessons[1].a

	## Overrides TutorialRoute.arrives_at.
	func arrives_at(segment: StreetNetwork.Segment) -> Vector2i:
		return segment.b

## Seeds on which every lesson's slot has a tile the day's rules allow.
const SEEDS: Array[int] = [4431, 5150]

func run(t: TestRunner) -> void:
	_test_each_row_is_offered_its_slot_in_order(t)
	for seed_value in SEEDS:
		_test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t, seed_value)

## Three streets of the map running east from (1, 1), (1, 3) and (1, 5).
static func _streets(map: CityMap) -> Array[StreetNetwork.Segment]:
	var found: Array[StreetNetwork.Segment] = []
	for junction: Vector2i in [Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 5)]:
		for segment in map.street_network().at_junction(junction):
			if segment.other_end(junction) == junction + Vector2i.RIGHT:
				found.append(segment)
	return found

static func _box_centre(junction: Vector2i) -> Vector2:
	return Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)

## **Each row is offered its slot, nearest its anchor first**: the stall the far sidewalk of (2)'s
## street from its middle, the van the far sidewalk of (4)'s street from the box she crosses at, the
## yeller the line's sidewalk of (6)'s street from the end she arrives at.
func _test_each_row_is_offered_its_slot_in_order(t: TestRunner) -> void:
	var map := StreetMap.full()
	var streets := _streets(map)
	var route := FakeRoute.new(streets)
	var slots := DawnTutorial.lesson_slots(route)
	var wanted := {
		DawnTutorial.NOISE_PASSED_WIDE: [route.far_sidewalk(streets[0]),
				Vector2(route.far_sidewalk(streets[0]).get_center())],
		DawnTutorial.SHUTS_HER_SIDEWALK: [route.far_sidewalk(streets[1]),
				_box_centre(streets[1].a)],
		DawnTutorial.PACES_HER_SIDEWALK: [route.line_sidewalk(streets[2]),
				_box_centre(streets[2].b)],
	}
	for row_id: String in wanted:
		var band: Rect2i = wanted[row_id][0]
		var anchor: Vector2 = wanted[row_id][1]
		var tiles: Array[Vector2i] = slots.get(row_id, [] as Array[Vector2i])
		var inside := not tiles.is_empty() and tiles.size() == band.get_area()
		var nearer_first := true
		for i in tiles.size():
			inside = inside and band.has_point(tiles[i])
			if i > 0:
				nearer_first = nearer_first and (Vector2(tiles[i - 1]) - anchor).length() \
						<= (Vector2(tiles[i]) - anchor).length() + 0.001
		t.check(inside, "%s is offered every tile of its slot and no other" % row_id)
		t.check(nearer_first, "%s is offered its slot nearest its anchor first" % row_id)

## **Day 1 planned whole stands each lesson's row on its slot and nothing else on the route's units
## past the first block**, and a second planning of the same day stands them on the same tiles.
func _test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t: TestRunner,
		seed_value: int) -> void:
	var first := _planned_day_one(seed_value)
	var second := _planned_day_one(seed_value)
	var slots := DawnTutorial.lesson_slots(first[1] as TutorialRoute)
	var stood: Dictionary = first[0]
	for row_id: String in slots:
		var tiles: Array[Vector2i] = slots[row_id]
		t.check(stood.has(row_id) and tiles.has(stood[row_id]),
				"seed %d: %s stands on its slot (%s)" % [seed_value, row_id, stood.get(row_id)])
	t.check(stood.size() == slots.size(),
			"seed %d: nothing but the lessons stands on the route's units (%s)"
			% [seed_value, stood.keys()])
	t.check(stood == second[0], "seed %d: a retried day 1 stands the same lessons" % seed_value)

## Day 1 of `seed_value` planned as the game plans it, every unit drawn: `[row id -> the tile it
## stands on, for each plan on the route's units past the first block; the route]`.
static func _planned_day_one(seed_value: int) -> Array:
	var map := CityGenerator.generate(seed_value)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 1)
	map.repaint(state)
	var route := TutorialRoute.for_city(map)
	var spec := DaySpec.for_day(1)
	map.clear_day_holds()
	for segment in map.street_network().around_blocks(
			Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
		map.hold_segment(segment.key(), HeldStreets.Why.HOME)
	var tree := RouteTree.for_day(map, 1, route)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var seals := SealPlanner.plan_day(map, spec, tree, rng, {}, map.held_streets(), route, null)
	var dawn := GameDawn.of(spec, rng, map).on(tree).standing(seals).tutorial(route).planned()
	var units := DawnTutorial.route_units(route)
	var stood := {}
	for plan in dawn.events().placements():
		if not plan.is_placed():
			continue
		var tile := map.world_to_tile(plan.placed_at())
		var location := dawn.locations().holding(tile, map.tile_at(tile))
		if location and units.has(location.part_of()):
			stood[plan.row_id()] = tile
	return [stood, route]
