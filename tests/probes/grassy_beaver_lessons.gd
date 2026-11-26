extends RefCounted
## Measurement probe for grassy-beaver's lessons on the route (a day one that teaches): over the
## city suites' seeds and seeds 1 to 120, day 1 planned as `DayPlanner` plans it (the home's
## streets held, the seals standing, the tree grown with the tutorial route), and for each lesson
## whether its row stands on the route's units (`DawnTutorial`). It also counts what the dawn
## draw left on the route's units past the first block, which should be nothing but the lessons,
## and how near the yeller's beat comes to lesson (5)'s junction, the box she crosses at with cars
## before his street, in tiles from the box's edge (YELLER lines).
##
## Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/grassy_beaver_lessons.gd   (prints LESSONS lines)

static func _seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(4400 + i * 31)
	for i in 12:
		found.append(5150 + i * 13)
	for i in 6:
		found.append(71717 + i * 91)
	for i in range(1, 121):
		found.append(i)
	return found

## The lesson rows the route has a street for, as a set.
static func _lessons(route: TutorialRoute) -> Dictionary:
	var found := {}
	if route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE):
		found[DawnTutorial.NOISE_PASSED_WIDE] = true
	if route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_NO_CARS):
		found[DawnTutorial.SHUTS_HER_SIDEWALK] = true
	if route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER):
		found[DawnTutorial.PACES_HER_SIDEWALK] = true
	return found

## Whole tiles between the nearest end of `beat`, the yeller's route, and the box of the junction
## she comes onto his street at (lesson (5)'s): 0 for an end on the box or beside it.
static func _beat_gap(map: CityMap, route: TutorialRoute, beat: PackedVector2Array) -> int:
	var junction := route.arrives_at(route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER))
	var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	var nearest := 1 << 30
	for point in beat:
		var tile := map.world_to_tile(point)
		var gap := maxi(maxi(box.position.x - 1 - tile.x, tile.x - box.end.x),
				maxi(box.position.y - 1 - tile.y, tile.y - box.end.y))
		nearest = mini(nearest, maxi(gap, 0))
	return nearest

func run(t: TestRunner) -> void:
	var stood := {}
	var routes := 0
	var strays := 0
	var missing: Array[String] = []
	var beat_gaps := {}
	for seed_value in _seeds():
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), 1)
		map.repaint(state)
		var route := TutorialRoute.for_city(Shipped.rows(), map)
		if not route:
			missing.append("%d: no route" % seed_value)
			continue
		routes += 1
		var spec := DaySpec.for_day(1)
		map.clear_day_holds()
		for segment in map.street_network().around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			map.hold_segment(segment.key(), HeldStreets.Why.HOME)
		var tree := RouteTree.for_day(map, 1, route)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var seals := SealPlanner.plan_day(Shipped.rows(), map, spec, tree, rng, {},
				map.held_streets(), route, null)
		var dawn := GameDawn.of(spec, rng, map).on(tree).standing(seals).tutorial(route).planned()
		var units := {}
		for unit in route.units_past_the_first_block():
			units[unit] = true
		var on_units := {}
		for plan in dawn.events().placements():
			if not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.placed_at())
			var location := dawn.locations().holding(tile, map.tile_at(tile))
			if location and units.has(location.part_of()):
				on_units[plan.row_id()] = int(on_units.get(plan.row_id(), 0)) + 1
				if plan.row_id() == DawnTutorial.PACES_HER_SIDEWALK:
					var gap := _beat_gap(map, route, plan.walks())
					beat_gaps[gap] = int(beat_gaps.get(gap, 0)) + 1
		var lessons := _lessons(route)
		for row_id: String in lessons:
			if on_units.has(row_id):
				stood[row_id] = int(stood.get(row_id, 0)) + 1
			else:
				missing.append("%d: %s" % [seed_value, row_id])
		for row_id: String in on_units:
			if not lessons.has(row_id):
				strays += 1
				missing.append("%d: stray %s" % [seed_value, row_id])
	print("LESSONS routes=%d stood=%s strays=%d" % [routes, stood, strays])
	print("YELLER beats by tiles between the nearest end and lesson (5)'s box: %s" % beat_gaps)
	for line in missing:
		print("LESSONS missing ", line)
	t.check(true, "a probe asserts nothing")
