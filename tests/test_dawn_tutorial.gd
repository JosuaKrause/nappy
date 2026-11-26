extends RefCounted
## `DawnTutorial`, day 1's lessons stood on the tutorial route at dawn: day 1 planned whole as the
## game plans it (`GameDawn`, the tree grown with the route, the seals standing), on generated
## cities, and each lesson's row read off where it stands against the route's own answers
## (`TutorialRoute`). **It builds real cities, and says why**: the guarantee is the dawn's as a
## whole, the lessons judged by every rule of the day among the seals, then every unit drawn round
## them, which only the real planning reaches.

## Seeds on which every lesson's slot has a tile the day's rules allow.
const SEEDS: Array[int] = [4431, 5150]

func run(t: TestRunner) -> void:
	for seed_value in SEEDS:
		_test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t, seed_value)

## The tiles of the route's units past the first block, as `Location.part_of()` names them, as a
## set: each lesson street's rect and the junction box at each of its ends.
static func _route_units(route: TutorialRoute) -> Dictionary:
	var units := {}
	for segment in route.lesson_streets():
		units[segment.tile_rect()] = true
		for junction: Vector2i in [segment.a, segment.b]:
			units[Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)] = true
	return units

static func _box_centre(junction: Vector2i) -> Vector2:
	return Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)

## Where each lesson's row is to stand on `route`: `[row id, its band, its anchor, how far from
## the anchor it may be]`. The stall on the far sidewalk of (2)'s street, offered from its middle
## out, so within the middle half; the van on the far sidewalk of (4)'s street, offered from the
## box she crosses at, so in the half by that box; the yeller on the line's sidewalk of (6)'s
## street, offered from the end she arrives at, so in the half at that end. The box's centre lies
## off the band's end, and the band's centre off its edge, so each reach adds that much.
static func _wanted(route: TutorialRoute) -> Array[Array]:
	var wanted: Array[Array] = []
	var wide := route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE)
	if wide:
		var band := route.far_sidewalk(wide)
		wanted.append([DawnTutorial.NOISE_PASSED_WIDE, band, Vector2(band.get_center()),
				_length(band) * 0.25 + mini(band.size.x, band.size.y)])
	var shut := route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_NO_CARS)
	if shut:
		var band := route.far_sidewalk(shut)
		wanted.append([DawnTutorial.SHUTS_HER_SIDEWALK, band,
				_box_centre(route.crossing_with_no_cars()), _length(band) * 0.5 + Tuning.STREET_WIDTH])
	var paced := route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER)
	if paced:
		var band := route.line_sidewalk(paced)
		wanted.append([DawnTutorial.PACES_HER_SIDEWALK, band, _box_centre(route.arrives_at(paced)),
				_length(band) * 0.5 + Tuning.STREET_WIDTH])
	return wanted

## The length of `band`, a sidewalk, along its street, in tiles.
static func _length(band: Rect2i) -> float:
	return float(maxi(band.size.x, band.size.y))

## **Day 1 planned whole stands each lesson's row on its slot and nothing else on the route's units
## past the first block**, and a second planning of the same day stands them on the same tiles.
func _test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t: TestRunner,
		seed_value: int) -> void:
	var first := _planned_day_one(seed_value)
	var second := _planned_day_one(seed_value)
	var wanted := _wanted(first[1] as TutorialRoute)
	var stood: Dictionary = first[0]
	t.check(wanted.size() == 3, "seed %d: the route lays all three rows' lessons" % seed_value)
	for row: Array in wanted:
		var row_id: String = row[0]
		var band: Rect2i = row[1]
		var anchor: Vector2 = row[2]
		var reach: float = row[3]
		var at: Vector2i = stood.get(row_id, Vector2i(-1, -1))
		t.check(stood.has(row_id) and band.has_point(at),
				"seed %d: %s stands on its sidewalk (%s)" % [seed_value, row_id, stood.get(row_id)])
		t.check(stood.has(row_id) and (Vector2(at) - anchor).length() <= reach,
				"seed %d: %s stands within %.0f tiles of where its slot starts (%s)"
				% [seed_value, row_id, reach, stood.get(row_id)])
	t.check(stood.size() == wanted.size(),
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
	var units := _route_units(route)
	var stood := {}
	for plan in dawn.events().placements():
		if not plan.is_placed():
			continue
		var tile := map.world_to_tile(plan.placed_at())
		var location := dawn.locations().holding(tile, map.tile_at(tile))
		if location and units.has(location.part_of()):
			stood[plan.row_id()] = tile
	return [stood, route]
