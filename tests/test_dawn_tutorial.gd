extends RefCounted
## `DawnTutorial`, day 1's lessons stood on the tutorial route at dawn: day 1 planned whole as the
## game plans it (`GameDawn`, the tree grown with the route, the seals standing), on generated
## cities, and each lesson's row read off where it stands against the route's own answers
## (`TutorialRoute`). **It builds real cities, and says why**: the guarantee is the dawn's as a
## whole, the lessons judged by every rule of the day among the seals, then every unit drawn round
## them, which only the real planning reaches.

## The city suites' seeds of the 5150 family and 4431, planned whole; a lesson whose slot has no
## tile the day's rules allow on a seed stands nowhere there (the record grassy-beaver-golden-puffin
## counts how often, `tests/probes/grassy_beaver_lessons.gd`).
static func _seeds() -> Array[int]:
	var found: Array[int] = [4431]
	for i in 12:
		found.append(5150 + i * 13)
	return found

## How many of the seeds are planned a second time, for the replay.
const REPLAYED := 2

func run(t: TestRunner) -> void:
	var stood_on := {}
	var seeds := _seeds()
	for i in seeds.size():
		_test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t, seeds[i], i < REPLAYED,
				stood_on)
	for row_id: String in [DawnTutorial.NOISE_PASSED_WIDE, DawnTutorial.SHUTS_HER_SIDEWALK,
			DawnTutorial.PACES_HER_SIDEWALK]:
		t.check(int(stood_on.get(row_id, 0)) > 0,
				"%s stands on its slot on some seed (%d of %d)"
				% [row_id, int(stood_on.get(row_id, 0)), seeds.size()])

static func _box_centre(junction: Vector2i) -> Vector2:
	return Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)

## Where each lesson's row is to stand on `route`: `[row id, its band, its anchor, how far from
## the anchor it may be]`. The stall on the far sidewalk of (2)'s street, offered from its middle
## out, so within the middle half; the van on the far sidewalk of (4)'s street, offered from the
## box she crosses at, so in the half by that box; the yeller on the line's sidewalk of (6)'s
## street, offered from its middle on along the half away from the end she arrives at, so within
## half the street of its middle. The box's centre lies off the band's end, and the band's centre
## off its edge, so each reach adds that much.
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
		wanted.append([DawnTutorial.PACES_HER_SIDEWALK, band,
				Vector2(band.position) + Vector2(band.size) * 0.5,
				_length(band) * 0.5 + mini(band.size.x, band.size.y)])
	return wanted

## The length of `band`, a sidewalk, along its street, in tiles.
static func _length(band: Rect2i) -> float:
	return float(maxi(band.size.x, band.size.y))

## **Day 1 planned whole stands each lesson's row that stands at all on its slot, and nothing else on
## the route's units past the first block**, the yeller's beat on the half of his street away from
## lesson (5)'s junction, and, `replayed`, a second planning of the same day stands them on the
## same tiles. Counts each row that stood into `stood_on`.
func _test_day_one_stands_the_lessons_and_nothing_else_on_the_route(t: TestRunner,
		seed_value: int, replayed: bool, stood_on: Dictionary) -> void:
	var first := _planned_day_one(seed_value)
	var wanted := _wanted(first[1] as TutorialRoute)
	var stood: Dictionary = first[0]
	t.check(wanted.size() == 3, "seed %d: the route lays all three rows' lessons" % seed_value)
	var lessons := {}
	for row: Array in wanted:
		var row_id: String = row[0]
		var band: Rect2i = row[1]
		var anchor: Vector2 = row[2]
		var reach: float = row[3]
		lessons[row_id] = true
		if not stood.has(row_id):
			continue
		stood_on[row_id] = int(stood_on.get(row_id, 0)) + 1
		var at: Vector2i = stood[row_id]
		t.check(band.has_point(at),
				"seed %d: %s stands on its sidewalk (%s)" % [seed_value, row_id, at])
		t.check((Vector2(at) - anchor).length() <= reach,
				"seed %d: %s stands within %.0f tiles of where its slot starts (%s)"
				% [seed_value, row_id, reach, at])
	var beat: PackedVector2Array = (first[2] as Dictionary).get(DawnTutorial.PACES_HER_SIDEWALK,
			PackedVector2Array())
	if not beat.is_empty():
		_check_the_beat_keeps_off_lesson_five(t, seed_value, first[1] as TutorialRoute, beat)
	for row_id: String in stood:
		t.check(lessons.has(row_id),
				"seed %d: nothing but the lessons stands on the route's units (%s)"
				% [seed_value, row_id])
	if replayed:
		t.check(stood == _planned_day_one(seed_value)[0],
				"seed %d: a retried day 1 stands the same lessons" % seed_value)

## **The yeller's beat, `beat`, never comes onto the half of his street by lesson (5)'s junction**,
## the crossing with cars, which is a lesson of its own before his *(gentle-owl #1253)*: every end of
## it lies further from that junction's box than the box's half width and half the street, in tiles.
func _check_the_beat_keeps_off_lesson_five(t: TestRunner, seed_value: int, route: TutorialRoute,
		beat: PackedVector2Array) -> void:
	var paced := route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER)
	var box := _box_centre(route.arrives_at(paced))
	var off := Tuning.STREET_WIDTH * 0.5 + _length(route.line_sidewalk(paced)) * 0.5
	var nearest := INF
	for point in beat:
		var tile := Vector2(point / float(Tuning.TILE_SIZE)).floor() + Vector2(0.5, 0.5)
		var gap := (tile - box).abs()
		nearest = minf(nearest, maxf(gap.x, gap.y))
	t.check(nearest >= off,
			"seed %d: the yeller's beat keeps to the half of his street away from lesson (5)'s junction (%.1f tiles from its box's centre, at least %.1f)"
			% [seed_value, nearest, off])

## Day 1 of `seed_value` planned as the game plans it, every unit drawn: `[row id -> the tile it
## stands on, for each plan on the route's units past the first block; the route; row id -> the
## ends of its route, for each of those plans that moves]`.
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
	var units := {}
	for unit in route.units_past_the_first_block():
		units[unit] = true
	var stood := {}
	var walks := {}
	for plan in dawn.events().placements():
		if not plan.is_placed():
			continue
		var tile := map.world_to_tile(plan.placed_at())
		var location := dawn.locations().holding(tile, map.tile_at(tile))
		if location and units.has(location.part_of()):
			stood[plan.row_id()] = tile
			if plan.walks().size() >= 2:
				walks[plan.row_id()] = plan.walks()
	return [stood, route, walks]
