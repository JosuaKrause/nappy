extends RefCounted
## **What day 13's two blocking beats could replace**: the blocking bodies the day's plan placed,
## sorted by where they stand against the day's routes, so the swap a beat makes during the walk
## can be designed from what a day actually holds. Not a suite: it prints rather than asserts.
##
##     tools/test.sh probes/minty_quail_swap_candidates.gd > out.txt
##     grep '^SC' out.txt
##
## Per seed, day 13, started the way `DayDirector.start()` starts one. A body blocks when
## `EventPlan.obstructs()` says so; the region wall's and the doors' bodies are never candidates.
## **Off the routes** is a body whose tile no route runs along (`Corridor.carries_a_route()`);
## **route-adjacent** is one standing on a street segment no route runs along, one of whose two
## junction boxes a route crosses; **deep** is every other body off the routes.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024]
const DAY := 13
const SPOTS := 10
const REACHES: Array[float] = [900.0, 1300.0, 1700.0]

func run(t: TestRunner) -> void:
	var asked := 0
	for seed_value in SEEDS:
		var city := _start(t, seed_value)
		var map := city.map
		var corridor := Corridor.of(city.streets().route_tree())
		var region := city.streets().region_plan()
		var fixed := {}
		if region:
			for body in region.wall_bodies:
				fixed[body] = true
			for body in region.door_bodies:
				fixed[body] = true
		var counts := {"on": 0, "adjacent": 0, "deep": 0, "spine": 0}
		var adjacent: Array[EventPlan] = []
		var ids := {}
		for plan in city.events.plans():
			if fixed.has(plan) or not plan.obstructs():
				continue
			var kind := _where(map, corridor, plan)
			counts[kind] += 1
			if kind == "adjacent":
				adjacent.append(plan)
				var key := "%s r%.0f" % [plan.def.id, plan.blocking_radius()]
				ids[key] = int(ids.get(key, 0)) + 1
				var segment := map.network.segment_containing(map.world_to_tile(plan.position))
				if segment and not segment.horizontal and segment.a.x == map.main_road:
					counts["spine"] += 1
		print("SC seed %d | on the routes %d | route-adjacent %d (on the main road %d) | deep %d"
				% [seed_value, counts["on"], counts["adjacent"], counts["spine"], counts["deep"]])
		print("SC_ROWS seed %d | %s" % [seed_value, ids])
		var route := _route_tiles(map, corridor)
		for id: String in ["barricade", "roadblock"]:
			var beat := EventCatalogue.by_id(id)
			var width := EventPlan.new(beat, Vector2.ZERO).blocking_radius()
			var fits: Array[EventPlan] = []
			var spine := 0
			for plan in adjacent:
				var tile := map.world_to_tile(plan.position)
				if plan.blocking_radius() < width or not beat.placement.has(map.tile_at(tile)):
					continue
				fits.append(plan)
				var segment := map.network.segment_containing(tile)
				if segment and not segment.horizontal and segment.a.x == map.main_road:
					spine += 1
			var kinds := {}
			for plan in fits:
				kinds[plan.def.id] = int(kinds.get(plan.def.id, 0)) + 1
			print("SC_FITS seed %d %s | %d route-adjacent bodies at least as wide on its ground "
					% [seed_value, id, fits.size()] + "(%d on the main road) | %s" % [spine, kinds])
			for spot in SPOTS:
				var her := map.tile_to_world(route[(route.size() * spot) / SPOTS])
				var within: Array[int] = []
				for reach in REACHES:
					var n := 0
					for plan in fits:
						var d := plan.position.distance_to(her)
						if d <= reach and d > Tuning.OUT_OF_SIGHT:
							n += 1
					within.append(n)
				print("SC_NEAR seed %d %s spot %d | out of sight and within %s: %s"
						% [seed_value, id, spot, REACHES, within])
				asked += 1
		_bodies(city, seed_value)
		_scar_discs(city, seed_value)
		city.free()
	for id: String in ["barricade", "roadblock"]:
		var def := EventCatalogue.by_id(id)
		var plan := EventPlan.new(def, Vector2.ZERO)
		print("SC_BEAT %s | blocking radius %.1f | obstructs %.1f | hard fail %s"
				% [id, plan.blocking_radius(), def.obstructs_radius, def.hard_fail])
	t.check(asked > 0, "there were places to ask from (%d)" % asked)

func _where(map: CityMap, corridor: Corridor, plan: EventPlan) -> String:
	var tile := map.world_to_tile(plan.position)
	if corridor.carries_a_route(tile):
		return "on"
	var segment := map.network.segment_containing(tile)
	if not segment:
		return "deep"
	for tile_on in map.rect_tiles(segment.tile_rect()):
		if corridor.carries_a_route(tile_on):
			return "on"
	for junction: Vector2i in [segment.a, segment.b]:
		var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		for tile_in in map.rect_tiles(box):
			if corridor.carries_a_route(tile_in):
				return "adjacent"
	return "deep"

func _route_tiles(map: CityMap, corridor: Corridor) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if corridor.carries_a_route(tile) and map.passable(tile, Mover.lattice()):
				found.append(tile)
	return found

func _start(t: TestRunner, seed_value: int) -> City:
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

## Where each beat's own body stands on the street it is put on: the tiles its footprint records
## (`EventSpawner.obstructed_footprint()`) at its sites, and whether a sidewalk tile is left open on
## each side of the street across from it. The barricade on the main road's lanes, the roadblock on
## its own ground, a few hundred sites each.
func _bodies(city: City, seed_value: int) -> void:
	var map := city.map
	for id: String in ["barricade", "roadblock"]:
		var def := EventCatalogue.by_id(id)
		var sites := 0
		var shut := 0
		var types := {}
		var tiles := []
		if id == "barricade":
			if map.main_road < 0:
				continue
			for going: float in [1.0, -1.0]:
				var lane_x := CrowdLanes.lane_centre(map.main_road, CrowdLanes.road_lane(true, going))
				for y in range(0, map.size.y, 3):
					var tile := map.world_to_tile(Vector2(lane_x, map.tile_to_world(Vector2i(0, y)).y))
					if map.network.segment_containing(tile) == null or not map.is_driveable_at(true, tile):
						continue
					tiles.append([Vector2(lane_x, map.tile_to_world(tile).y), Vector2(0, going)])
		else:
			var ground := EventScheduler.open_ground_for(def, map, {})
			for i in range(0, ground.size(), 7):
				tiles.append([map.tile_to_world(ground[i]), Vector2.RIGHT])
		for site: Array in tiles:
			var at: Vector2 = site[0]
			var foot := EventSpawner.obstructed_footprint(map, def, at, site[1])
			var segment := map.network.segment_containing(map.world_to_tile(at))
			if not segment:
				continue
			sites += 1
			var on := {}
			for tile in foot:
				on[tile] = true
				var name: String = GameEnums.TileType.keys()[map.tile_at(tile)]
				types[name] = int(types.get(name, 0)) + 1
			var centre := map.world_to_tile(at)
			var rect := segment.tile_rect()
			var open_sides := 0
			for side in 2:
				var open := false
				for k in Tuning.STREET_WIDTH:
					var tile := Vector2i(rect.position.x + k, centre.y) if not segment.horizontal \
							else Vector2i(centre.x, rect.position.y + k)
					var near_side := k < Tuning.STREET_WIDTH / 2
					if near_side != (side == 0):
						continue
					if map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not on.has(tile):
						open = true
				if open:
					open_sides += 1
			if open_sides < 2:
				shut += 1
		print("SC_BODY seed %d %s | %d sites | %d leave a sidewalk shut across from it | tiles %s"
				% [seed_value, id, sites, shut, types])

## **Whether a barricade standing as a scar closes the main road in the dawn reading**: at every
## third lane point mid-street on the main road (where the column stops), the barricade's own disc
## (`EventPlan.blocking_radius()`, as `EventScheduler.blocked_by()` paints it) laid over today's
## closures, and the street alone flooded on the reachability grid from a sidewalk tile a block-end
## short of it to one a block-end past it. Counted: the stops whose disc leaves the street through.
func _scar_discs(city: City, seed_value: int) -> void:
	var map := city.map
	if map.main_road < 0:
		return
	var grid := ReachabilityGrid.build(map)
	var def := EventCatalogue.by_id("barricade")
	var sites := 0
	var through := 0
	for going: float in [1.0, -1.0]:
		var lane_x := CrowdLanes.lane_centre(map.main_road, CrowdLanes.road_lane(true, going))
		for y in range(0, map.size.y, 3):
			var tile := map.world_to_tile(Vector2(lane_x, map.tile_to_world(Vector2i(0, y)).y))
			var segment := map.network.segment_containing(tile)
			if segment == null or segment.horizontal or not map.is_driveable_at(true, tile):
				continue
			var rect := segment.tile_rect()
			var scar := EventPlan.new(def, Vector2(lane_x, map.tile_to_world(tile).y))
			var blocked := EventScheduler.blocked_by(map, [scar] as Array[EventPlan])
			# Only the street itself counts: everything off its rect is shut.
			for yy in range(rect.position.y - 1, rect.end.y + 1):
				for xx in range(rect.position.x - 2, rect.end.x + 2):
					var t := Vector2i(xx, yy)
					if map.in_bounds(t) and not rect.has_point(t):
						blocked[t] = true
			var start := Vector2i(rect.position.x, rect.position.y)
			var end := Vector2i(rect.position.x, rect.end.y - 1)
			if blocked.has(start) or blocked.has(end):
				continue
			sites += 1
			var reached := grid.flood([start], blocked)
			if grid.reaches(end, blocked, reached):
				through += 1
	print("SC_SCAR seed %d | %d stops on the main road | %d leave the street through" % [
		seed_value, sites, through])
