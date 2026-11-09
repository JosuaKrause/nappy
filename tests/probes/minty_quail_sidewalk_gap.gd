@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **How much sidewalk a body leaves open across the street from it**, for the rule that a body
## blocks her way unless it leaves a gap a whole sidewalk wide (`Tuning.SIDEWALK_WIDTH` tiles).
## Not a suite: it prints rather than asserts.
##
##     tools/test.sh probes/minty_quail_sidewalk_gap.gd > out.txt
##     grep '^SG' out.txt
##
## Per seed, day 13, started the way `DayDirector.start_day()` starts one. A body's tiles are what
## the map records for it (`EventSpawner.obstructed_footprint()`). For every line across the street
## its footprint covers, each side's sidewalk tiles left open are counted, and the body is read by
## its worst line: `near/far` is the side with fewer open, then the other. Asked of:
##
## - **the barricade** day 13's column leaves, at every third point mid-street down both lanes of
##   the main road, where the column stops;
## - **the roadblock**, at every seventh tile of its own ground;
## - **every body the day's plan obstructs with** (`Planned.obstructs()`), by row. A region door's
##   bodies are not in the record at all, so they are counted apart.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024]
const DAY := 13

func run(t) -> void:
	var beats := {"barricade": {}, "roadblock": {}}
	var rows := {}
	var asked := 0
	for seed_value in SEEDS:
		var city := _start(t, seed_value)
		var map := city.map
		var barricade := EventCatalogue.by_id("barricade")
		for going: float in [1.0, -1.0]:
			if map.main_road < 0:
				break
			var lane_x := CrowdLanes.lane_centre(map.main_road, CrowdLanes.road_lane(true, going))
			for y in range(0, map.size.y, 3):
				var tile := map.world_to_tile(Vector2(lane_x, map.tile_to_world(Vector2i(0, y)).y))
				if map.network.segment_containing(tile) == null or not map.is_driveable_at(true, tile):
					continue
				var at := Vector2(lane_x, map.tile_to_world(tile).y)
				_count(beats["barricade"], _gap(map, barricade, at, Vector2(0, going)))
				asked += 1
		var roadblock := EventCatalogue.by_id("roadblock")
		var ground := EventScheduler.open_ground_for(roadblock, map, {})
		for i in range(0, ground.size(), 7):
			_count(beats["roadblock"],
					_gap(map, roadblock, map.tile_to_world(ground[i]), Vector2.RIGHT))
			asked += 1
		for plan in city.events.plans():
			if not plan.is_placed():
				continue
			var key := plan.def.id
			if plan.is_door():
				key = "door body " + key
			elif not plan.obstructs():
				continue
			if not rows.has(key):
				rows[key] = {}
			_count(rows[key], _gap(map, plan.def, plan.position, plan.facing))
		city.free()
	for id: String in beats:
		print("SG_BEAT %s | %s" % [id, _line(beats[id])])
	var keys := rows.keys()
	keys.sort()
	for key: String in keys:
		print("SG_ROW %s | %s" % [key, _line(rows[key])])
	t.check(asked > 0, "there were sites to ask (%d)" % asked)

## `near/far` for `def` standing at `at` looking `facing`, or what keeps it from being read: "off a
## street" for a body on no street segment, "no record" for one the map records no tiles for.
func _gap(map: CityMap, def: EventDef, at: Vector2, facing: Vector2) -> String:
	var foot := EventSpawner.obstructed_footprint(map, def, at, facing)
	if foot.is_empty():
		return "no record"
	var segment := map.network.segment_containing(map.world_to_tile(at))
	if not segment:
		return "off a street"
	var rect := segment.tile_rect()
	var on := {}
	var lines := {}
	for tile in foot:
		on[tile] = true
		lines[tile.y if not segment.horizontal else tile.x] = true
	var worst := [Tuning.SIDEWALK_WIDTH, Tuning.SIDEWALK_WIDTH]
	for line: int in lines:
		var open := [0, 0]
		for k in Tuning.STREET_WIDTH:
			var tile := Vector2i(rect.position.x + k, line) if not segment.horizontal \
					else Vector2i(line, rect.position.y + k)
			if not rect.has_point(tile) or map.tile_at(tile) != GameEnums.TileType.SIDEWALK \
					or on.has(tile):
				continue
			open[0 if k < Tuning.STREET_WIDTH / 2 else 1] += 1
		worst[0] = mini(worst[0], open[0])
		worst[1] = mini(worst[1], open[1])
	return "%d/%d" % [mini(worst[0], worst[1]), maxi(worst[0], worst[1])]

func _count(tally: Dictionary, key: String) -> void:
	tally[key] = int(tally.get(key, 0)) + 1

func _line(tally: Dictionary) -> String:
	var keys := tally.keys()
	keys.sort()
	var parts: Array[String] = []
	var total := 0
	for key: String in keys:
		parts.append("%s: %d" % [key, tally[key]])
		total += int(tally[key])
	return "%d bodies | %s" % [total, ", ".join(parts)]

func _start(t, seed_value: int) -> City:
	var spec := DaySpec.for_day(DAY)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	city.run.header.day = DAY
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	city.run.attempt_spend.city_state.begin_day(city.map.block_plans, DAY)
	city.start_day(city.run.attempt_spend.city_state, DAY, city.run.calendar.day_rng(DAY, "closures"),
			spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, city.run.calendar.day_rng(DAY), consumed,
			city.map.doorstep_world_position())
	return city
