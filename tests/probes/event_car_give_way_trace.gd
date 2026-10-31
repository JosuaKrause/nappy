extends RefCounted
## Whether two revisions of the code drive an event car identically where it gives way: every
## tick's pose, heading, distance travelled, speed and whether it stands, over seeds, heat levels
## (the days' rows: a patrol car cold and at each heat, the fire truck) and four rigs — a zebra she
## waits at and then leaves, a red light that turns green, the far zebra behind a junction box at
## an ordinary junction and at the main road — each driven both ways along its lane.
##
## Run in each revision's checkout and compare the `EVENT_CAR_TRACE_JSON` lines run for run:
## `tools/test.sh probes/event_car_give_way_trace.gd`. Reads only what both revisions have
## (`EventInstance.step()`, `car.is_standing()`, `signals`, `player_at`, `pram_at`).
const STEP := 1.0 / 60.0
const SEEDS: Array[int] = [4242, 478156010]
const TICKS := 600
const LEAVES_AT := 300

func run(t) -> void:
	var defs: Array[EventDef] = []
	for def in EventCatalogue.all():
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(def, level)
			if hot.vehicle != null and hot.mobile and not defs.has(hot):
				defs.append(hot)
	var cases := 0
	for city_seed in SEEDS:
		var map: CityMap = CityGenerator.generate(city_seed)
		for def in defs:
			for rig in _rigs(map):
				var report := _drive(t, map, def, rig)
				report["seed"] = city_seed
				report["def"] = def.id
				report["speed"] = def.speed
				report["rig"] = rig["name"]
				print("EVENT_CAR_TRACE_JSON " + JSON.stringify(report))
				cases += 1
	t.check(cases > 0, "ran %d cases" % cases)

## Each rig: a name, the route, where she waits, how the lights stand and when she leaves.
func _rigs(map: CityMap) -> Array:
	var rigs: Array = []
	var tile := float(Tuning.TILE_SIZE)
	var zebra := _a_zebra(map)
	if zebra != Vector2.INF:
		for direction in [1.0, -1.0]:
			var start: Vector2 = zebra - Vector2(160.0 * direction, 0.0)
			rigs.append({"name": "zebra_%d" % int(direction), "route": PackedVector2Array(
					[start, start + Vector2(560.0 * direction, 0.0)]), "her": zebra, "red": false})
	var lane_y := _lane_to_the_main_road(map)
	if lane_y < 0:
		return rigs
	var lane := float(lane_y) * tile + tile * 0.5
	var box_x := float(map.main_road * CityMap.period()) * tile
	for direction in [1.0, -1.0]:
		var near: float = box_x if direction > 0.0 else box_x + float(Tuning.STREET_WIDTH) * tile
		var start := Vector2(near - direction * 260.0, lane)
		rigs.append({"name": "red_%d" % int(direction), "route": PackedVector2Array(
				[start, start + Vector2(direction * 660.0, 0.0)]), "her": Vector2.INF,
				"red": true, "junction": Vector2i(map.main_road, CityMap.junction_index(lane_y))})
	var period := CityMap.period()
	var ordinary := -1
	for c in range(1, map.main_road):
		if _zebras_either_side(map, lane_y, c):
			ordinary = c
			break
	for c in [ordinary, map.main_road]:
		if c < 0 or not _zebras_either_side(map, lane_y, c):
			continue
		for direction in [1.0, -1.0]:
			var low: float = float(c * period) * tile
			var near: float = low if direction > 0.0 else low + float(Tuning.STREET_WIDTH) * tile
			var first: int = c * period + (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
					if direction > 0.0 else 0)
			var start := Vector2(near - direction * 220.0, lane)
			for k in Tuning.SIDEWALK_WIDTH:
				for out in [0.0, 64.0]:
					rigs.append({"name": "far_%d_%d_%d_%d" % [c, int(direction), k, int(out)],
							"route": PackedVector2Array([start, start + Vector2(direction * 820.0, 0.0)]),
							"her": Vector2((float(first + k) + 0.5) * tile, lane - out),
							"red": false, "junction": Vector2i(map.main_road, CityMap.junction_index(lane_y)),
							"green": true})
	return rigs

func _drive(t, map: CityMap, def: EventDef, rig: Dictionary) -> Dictionary:
	var route: PackedVector2Array = rig["route"]
	var car := EventInstance.new()
	car.setup(def, route[0], route, (route[1] - route[0]).normalized(), map)
	t.add_child(car)
	car.set_process(false)
	var signals := TrafficSignals.new(map)
	if rig.has("junction"):
		signals.elapsed = 0.0
		var junction: Vector2i = rig["junction"]
		if rig["red"]:
			while signals.phase_of(junction) != TrafficSignals.Phase.MAIN_GREEN:
				signals.elapsed += 0.25
		else:
			while not signals.green_for(junction, false):
				signals.elapsed += 0.25
		car.signals = signals
	var her: Vector2 = rig["her"]
	var chain := PackedByteArray()
	chain.resize(32)
	var held := 0
	var flips := 0
	var was_standing := true
	for tick in TICKS:
		if her != Vector2.INF:
			var at := her if tick < LEAVES_AT else her + Vector2(0.0, -160.0)
			car.player_at = at
			car.pram_at = at + Vector2.UP * Tuning.PLAYER_BODY_RADIUS
		if rig["red"] and tick == LEAVES_AT:
			var junction: Vector2i = rig["junction"]
			while not signals.green_for(junction, false):
				signals.elapsed += 0.25
		car.step(STEP)
		var standing: bool = car.car.is_standing()
		held += 1 if standing else 0
		flips += 1 if standing != was_standing else 0
		was_standing = standing
		var state := PackedFloat32Array([car.position.x, car.position.y, car._heading.x,
				car._heading.y, car._path_travelled, 1.0 if standing else 0.0,
				1.0 if car.is_parked else 0.0, 1.0 if car.is_leaving else 0.0,
				1.0 if car.is_finished else 0.0, car.car.room_to_its_line(car.position, car._heading)])
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(chain)
		context.update(state.to_byte_array())
		chain = context.finish()
	var report := {"chain": chain.hex_encode(), "held": held, "flips": flips,
			"x": snappedf(car.position.x, 0.001), "y": snappedf(car.position.y, 0.001)}
	car.free()
	return report

func _lane_to_the_main_road(map: CityMap) -> int:
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) == Tuning.SIDEWALK_WIDTH \
				and map.tile_at(Vector2i(map.main_road * CityMap.period() - 4, y)) \
						== GameEnums.TileType.ROAD:
			return y
	return -1

func _zebras_either_side(map: CityMap, lane_y: int, c: int) -> bool:
	var period := CityMap.period()
	for x in [c * period, c * period + 1, c * period + Tuning.STREET_WIDTH - 2,
			c * period + Tuning.STREET_WIDTH - 1]:
		if map.tile_at(Vector2i(x, lane_y)) != GameEnums.TileType.CROSSING:
			return false
	return map.tile_at(Vector2i(c * period - 4, lane_y)) == GameEnums.TileType.ROAD \
			and map.tile_at(Vector2i(c * period + Tuning.STREET_WIDTH + 4, lane_y)) \
					== GameEnums.TileType.ROAD

func _a_zebra(map: CityMap) -> Vector2:
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) < 0 or not CityMap.is_road_offset(CityMap.corridor_offset(y)):
			continue
		for x in range(12, map.size.x - 16):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.CROSSING:
				continue
			if map.tile_at(tile - Vector2i(5, 0)) != GameEnums.TileType.ROAD:
				continue
			if map.is_main_road(true, CityMap.junction_index(x + 2)):
				continue
			return map.tile_to_world(tile)
	return Vector2.INF
