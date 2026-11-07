extends RefCounted
## Measurement probe for a main-road door two tiles in from its junction (inbox #1186, the
## player's answer on where it stands: in from the corner, so crossing the main road there never
## takes her in): how much of the junction box its gatehouses' take-in reaches, whether a gatehouse
## overlaps any other solid body of the day, and whether an alley opening beside a gatehouse is
## still reached through that mouth. Not a suite: it prints numbers rather than asserting
## relationships, so it lives under `tests/probes/`, where the runner never discovers it, and runs
## only by name:
##
##     tools/test.sh probes/main_road_door_row.gd
##
## **Forty seeds, days `Tuning.REGION_WALL_FIRST_DAY` to the end**: the ten the region-plan suites
## use (`tests/test_regions.gd`'s six and `tests/test_checkpoints.gd`'s four) and thirty more at
## `5000 + i * 7919`, the review's own sample, which holds the three seeds a gatehouse overlapped a
## crossing alley's wall on (261054, 171299, 187137) and the three a gatehouse overlapped an alley's
## soft seal on (771605, 5000, 195056). Each day is planned whole, as `DayDirector.start_day()`
## plans it: the city's streets, then the seals and the events.
##
## For each main-road door (its three points, `RegionPlanner.door_positions()`):
##
## - **`box`**: of the 16 sidewalk tiles of the junction boxes at both ends of its street, how many
##   have their centre within `EventDef.detain_distance()` (80px) of a gatehouse, the take-in
##   measured by distance alone as `CheckpointController.hold_that_would_begin()` does;
## - **`overlap`**: whether a gatehouse's solid circle overlaps any other solid body the day stands:
##   the region wall's (a crossing alley's mouth walls included), another door's, a seal's, an
##   event's.
##
## And for each through-alley mouth beside a main-road door (one whose body
## `SealPlanner.alley_mouth_body_rect()` stands a tile deeper): what stands in it (the region wall,
## an alley door's post, a seal, or nothing), and **`reached`**, whether a flood from the sidewalks
## at both ends of the street it opens on (`ReachabilityGrid`, every solid body of the day blocked
## as a circle, the alley's other mouth shut) reaches the alley's end row there.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

static func _seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(260917 + i * 137)
	for i in 4:
		found.append(771103 + i * 251)
	for i in 30:
		found.append(5000 + i * 7919)
	return found

func run(t) -> void:
	var totals := {"doors": 0, "box": 0, "huts": 0, "overlaps": 0, "overlap_seeds": {},
			"mouths": 0, "reached": 0, "kinds": {}}
	var seed_days := 0
	for seed_value in _seeds():
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			seed_days += 1
			_day(t, seed_value, day, totals)
	print("TOTAL %d seed-days over %d seeds" % [seed_days, _seeds().size()])
	print(("TOTAL main-road doors %d | junction-box sidewalk tiles in a take-in %d | gatehouses %d, " +
			"overlapping another body %d (seeds %s)")
			% [totals.doors, totals.box, totals.huts, totals.overlaps, totals.overlap_seeds.keys()])
	print("TOTAL alley mouths beside a main-road door %d, stood a tile deeper by %s | end row reached %d"
			% [totals.mouths, totals.kinds, totals.reached])
	t.check(true, "probe finished")

## The 16 sidewalk tiles of the junction box at `junction`.
static func _box_sidewalk(junction: Vector2i) -> Array[Vector2i]:
	var origin := junction * CityMap.period()
	var found: Array[Vector2i] = []
	for y in Tuning.STREET_WIDTH:
		for x in Tuning.STREET_WIDTH:
			if (x < 2 or x >= Tuning.STREET_WIDTH - 2) and (y < 2 or y >= Tuning.STREET_WIDTH - 2):
				found.append(origin + Vector2i(x, y))
	return found

## One seed-day, planned as `DayDirector.start_day()` plans it.
func _day(t, seed_value: int, day: int, totals: Dictionary) -> void:
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	city.run.header.day = day
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var map := city.map
	city.run.attempt_spend.city_state.begin_day(map.block_plans, day)
	city.start_day(city.run.attempt_spend.city_state, day,
			city.run.calendar.day_rng(day, "closures"), spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, city.run.calendar.day_rng(day), consumed,
			map.doorstep_world_position())
	var plan := city.streets().region_plan()
	var hut_def := EventCatalogue.by_id("checkpoint_hut")
	var solids: Array[EventScheduler.Planned] = []
	var seen := {}
	var everything: Array[EventScheduler.Planned] = []
	everything.append_array(plan.wall_bodies)
	everything.append_array(plan.door_bodies)
	everything.append_array(city.events.plans())
	for body in everything:
		if seen.has(body) or not body.is_placed() or body.def.obstructs_radius <= 0.0:
			continue
		seen[body] = true
		solids.append(body)
	var main_road_doors: Array[EventScheduler.Planned] = []
	for i in plan.doors.size():
		var segment := plan.doors[i]
		if not map.is_main_road_segment(segment):
			continue
		var own := RegionPlanner.door_positions(map, segment)
		var huts: Array[Vector2] = [own[0], own[own.size() - 1]]
		totals.doors += 1
		for junction in [segment.a, segment.b]:
			for tile in _box_sidewalk(junction):
				for hut in huts:
					if map.tile_to_world(tile).distance_to(hut) <= hut_def.detain_distance():
						totals.box += 1
						break
		for body in solids:
			if _is_one_of(body.position, own):
				main_road_doors.append(body)
		for hut in huts:
			totals.huts += 1
			for body in solids:
				if _is_one_of(body.position, own):
					continue
				var apart := hut.distance_to(body.position)
				if apart < hut_def.obstructs_radius + body.def.obstructs_radius:
					totals.overlaps += 1
					totals.overlap_seeds[seed_value] = true
					print("OVERLAP seed %d day %d | door %s | gatehouse %s | %s at %s, %.0fpx apart"
							% [seed_value, day, segment.key(), hut, body.def.id, body.position,
							apart])
	if not main_road_doors.is_empty():
		_alleys_beside(map, main_road_doors, solids, totals)
	city.free()

## The through-alley mouths beside `doors`, a main-road door's bodies: what stands in each, and
## whether its end row is reached from the street it opens on.
static func _alleys_beside(map: CityMap, doors: Array[EventScheduler.Planned],
		solids: Array[EventScheduler.Planned], totals: Dictionary) -> void:
	var grid: ReachabilityGrid = null
	for rect in map.alley_rects:
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		var vertical := rect.size.x < rect.size.y
		for at_start in [true, false]:
			var end_row := SealPlanner.alley_mouth_rect(rect, vertical, at_start)
			var stood := SealPlanner.alley_mouth_body_rect(map, rect, vertical, at_start, doors)
			if stood == end_row:
				continue
			totals.mouths += 1
			var kind := "nothing"
			var deeper := map.tile_rect_to_world(stood)
			for body in solids:
				if deeper.grow(1.0).has_point(body.position):
					kind = body.def.id
			totals.kinds[kind] = totals.kinds.get(kind, 0) + 1
			if not grid:
				grid = ReachabilityGrid.build(map)
			var blocked := {}
			for body in solids:
				_add_circle(map, blocked, body.position, body.def.obstructs_radius)
			for tile in map.rect_tiles(SealPlanner.alley_mouth_rect(rect, vertical, not at_start)):
				blocked[tile] = true
			var outward := (Vector2i.UP if vertical else Vector2i.LEFT) if at_start \
					else (Vector2i.DOWN if vertical else Vector2i.RIGHT)
			var street := map.network.segment_containing(end_row.position + outward)
			if not street:
				print("ALLEY %s mouth %s opens on no street" % [rect, end_row])
				continue
			var sources: Array = []
			for tile in map.rect_tiles(street.mouth_rect(true)) + map.rect_tiles(street.mouth_rect(false)):
				if not blocked.has(tile):
					sources.append(tile)
			var reached := grid.flood(sources, blocked)
			var reached_it := false
			for tile in map.rect_tiles(end_row):
				reached_it = reached_it or grid.reaches(tile, blocked, reached)
			totals.reached += 1 if reached_it else 0
			print("ALLEY seed %d | %s mouth %s | stood a tile deeper by %s | end row reached %s"
					% [map.seed_used, rect, end_row.position, kind, reached_it])

static func _add_circle(map: CityMap, blocked: Dictionary, at: Vector2, radius: float) -> void:
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true

static func _is_one_of(at: Vector2, points: Array[Vector2]) -> bool:
	for point in points:
		if at.is_equal_approx(point):
			return true
	return false
