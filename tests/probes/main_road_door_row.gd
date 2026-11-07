extends RefCounted
## Measurement probe for where on its street a main-road door can stand (inbox #1186, the review of
## #1188): for each candidate row, how much of the junction box a gatehouse's take-in reaches,
## whether she can be taken in walking along the main road's sidewalk at the gatehouse from the
## junction side, and whether a gatehouse overlaps another solid body of the day. Not a suite: it
## prints numbers rather than asserting relationships, so it lives under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/main_road_door_row.gd
##
## **Forty seeds, days `Tuning.REGION_WALL_FIRST_DAY` to the end**: the ten the region-plan suites
## use (`tests/test_regions.gd`'s six and `tests/test_checkpoints.gd`'s four) and thirty more at
## `5000 + i * 7919`, the review's own sample, which holds the three seeds a gatehouse two tiles in
## overlapped a crossing alley's wall on.
##
## **The rows** are tiles in from the junction at the door's own end (`CityMap.boundary_wall_at_a`):
## 0 is the mouth row every other door stands on, 2 is `RegionPlanner.MAIN_ROAD_DOOR_INSET`. A row's
## three points are worked out here as `RegionPlanner.door_positions()` would at that inset; the day
## itself is planned once, as the game plans it, and its other bodies are read off it.
##
## For each main-road door and row:
##
## - **`box`**: of the 16 sidewalk tiles of the junction box at the door's end, how many have their
##   centre within `EventDef.detain_distance()` (80px) of a gatehouse, the take-in measured by
##   distance alone as `CheckpointController.hold_that_would_begin()` does today;
## - **`from the junction`**: for each gatehouse, where her centre stops walking straight at it
##   along its sidewalk from the junction side, the gatehouse's solid edge plus her reach ahead
##   (her body's centre to the pram's far edge: `Tuning.PLAYER_BODY_RADIUS` +
##   `Stroller.PRAM_BODY_RADIUS`), and whether that point is on the door's own street
##   (`Segment.tile_rect()`) rather than in the box. A take-in confined to the street can take her in
##   from the junction side only where it is;
## - **`overlap`**: whether a gatehouse's solid circle overlaps any other solid body the day stands:
##   the region wall's (a crossing alley's mouth walls included), another door's, a seal's, an
##   event's.
##
## And for each door off the main road, at its own mouth row, the `box` and `from the junction`
## readings, which say what confining its take-in to its own street would change.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const ROWS: Array[int] = [0, 1, 2]

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
	var totals := {}
	for row in ROWS:
		totals[row] = {"doors": 0, "box": 0, "box_doors": 0, "huts": 0, "inside": 0,
				"overlaps": 0, "overlap_seeds": {}, "overlap_days": 0}
	var off := {"doors": 0, "box": 0, "box_doors": 0, "huts": 0, "inside": 0}
	var seed_days := 0
	for seed_value in _seeds():
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			seed_days += 1
			_day(t, seed_value, day, totals, off)
	print("TOTAL %d seed-days over %d seeds" % [seed_days, _seeds().size()])
	for row in ROWS:
		var r: Dictionary = totals[row]
		print(("TOTAL row %d | main-road doors %d | box tiles in reach %d (doors with any %d) | " +
				"gatehouses %d, taken in from the junction side possible at %d | overlapping " +
				"gatehouses %d on %d seed-days, %d seeds %s")
				% [row, r.doors, r.box, r.box_doors, r.huts, r.inside, r.overlaps, r.overlap_days,
				r.overlap_seeds.size(), r.overlap_seeds.keys()])
	print(("TOTAL off the main road, mouth row | doors %d | box tiles in reach %d (doors with any " +
			"%d) | gatehouses %d, stop point from the junction side on the street %d")
			% [off.doors, off.box, off.box_doors, off.huts, off.inside])
	t.check(true, "probe finished")

## The three points a street door on `segment` stands at `row` tiles in from its end's junction:
## `RegionPlanner.door_positions()`'s arithmetic with the inset as a parameter.
static func _points_at(map: CityMap, segment: StreetNetwork.Segment, row: int) -> Array[Vector2]:
	var mouth := segment.mouth_rect(_at_a(map, segment))
	var inward := Vector2i.RIGHT if segment.horizontal else Vector2i.DOWN
	mouth.position += inward * (row if _at_a(map, segment) else -row)
	return SealPlanner.positions_across(map.tile_rect_to_world(mouth), segment.horizontal,
			Tuning.TILE_SIZE)

static func _at_a(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
			< RegionPlanner.region_of_junction(map, segment.b)
	return map.boundary_wall_at_a.get(segment.key(), default_at_a)

## The 16 sidewalk tiles of the junction box at `junction`.
static func _box_sidewalk(junction: Vector2i) -> Array[Vector2i]:
	var origin := junction * CityMap.period()
	var found: Array[Vector2i] = []
	for y in Tuning.STREET_WIDTH:
		for x in Tuning.STREET_WIDTH:
			if (x < 2 or x >= Tuning.STREET_WIDTH - 2) and (y < 2 or y >= Tuning.STREET_WIDTH - 2):
				found.append(origin + Vector2i(x, y))
	return found

## `box` and `from the junction` for one door's two gatehouses at `huts`, added to `into`.
static func _take_in(map: CityMap, segment: StreetNetwork.Segment, huts: Array[Vector2],
		hut_def: EventDef, into: Dictionary) -> void:
	var at_a := _at_a(map, segment)
	var junction := segment.a if at_a else segment.b
	var covered := 0
	for tile in _box_sidewalk(junction):
		for hut in huts:
			if map.tile_to_world(tile).distance_to(hut) <= hut_def.detain_distance():
				covered += 1
				break
	into.doors += 1
	into.box += covered
	into.box_doors += 1 if covered > 0 else 0
	var street := map.tile_rect_to_world(segment.tile_rect())
	var along := Vector2.RIGHT if segment.horizontal else Vector2.DOWN
	var toward_the_junction := -along if at_a else along
	var stops := hut_def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS + Stroller.PRAM_BODY_RADIUS
	for hut in huts:
		into.huts += 1
		if street.has_point(hut + toward_the_junction * stops):
			into.inside += 1

## One seed-day, planned as `DayDirector.start_day()` plans it.
func _day(t, seed_value: int, day: int, totals: Dictionary, off: Dictionary) -> void:
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
	for i in plan.doors.size():
		var segment := plan.doors[i]
		var own := RegionPlanner.door_positions(map, segment)
		if not map.is_main_road_segment(segment):
			var mouth_huts: Array[Vector2] = [own[0], own[own.size() - 1]]
			_take_in(map, segment, mouth_huts, hut_def, off)
			continue
		for row in ROWS:
			var r: Dictionary = totals[row]
			var points := _points_at(map, segment, row)
			var huts: Array[Vector2] = [points[0], points[points.size() - 1]]
			_take_in(map, segment, huts, hut_def, r)
			var overlapping := 0
			for hut in huts:
				for body in solids:
					if _is_one_of(body.position, own):
						continue
					var apart := hut.distance_to(body.position)
					if apart < hut_def.obstructs_radius + body.def.obstructs_radius:
						overlapping += 1
						print("OVERLAP seed %d day %d row %d | door %s | gatehouse %s | %s at %s, %.0fpx apart"
								% [seed_value, day, row, segment.key(), hut, body.def.id,
								body.position, apart])
			r.overlaps += overlapping
			if overlapping > 0:
				r.overlap_days += 1
				r.overlap_seeds[seed_value] = true
	city.free()

static func _is_one_of(at: Vector2, points: Array[Vector2]) -> bool:
	for point in points:
		if at.is_equal_approx(point):
			return true
	return false
