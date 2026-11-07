extends RefCounted
## **What the siting after dawn reads as cut off, and which sites it accepts**, on the days the
## region doors stand (9 to 14), so a change to what blocks her way can be shown before and after.
## Not a suite: it prints rather than asserts. Run by name on each tree and compare the totals:
##
##     tools/test.sh probes/minty_quail_door_bodies.gd > out.txt
##     grep '^DB' out.txt
##
## Each day is started the way `DayDirector.start_day()` starts one, through a real `City` and its
## `EventManager`, and asked of the siting the walk's events hand out
## (`EventScheduler.WalkSiting`, built as `EventsAhead` builds it):
##
## - **`DB_CUT`**: of the tiles the day's routes run along, how many the siting reads as cut off
##   from home or from every calm area she has not used, under what it counts as already standing
##   in her way;
## - **`DB_SITE`**: on day 13, the barricade the column leaves and the task's roadblock, offered on
##   their ground within `NEAR` of her at a few places along her routes: whether the siting
##   accepts the site (`leaves_her_a_way()`), and whether it really cuts her off, read with the
##   doors' bodies standing open, as the crossing they are.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024]
const DAYS: Array[int] = [9, 10, 11, 12, 13, 14]
const SITE_DAY := 13
const NEAR := 900.0
## How many places along her routes day 13's sites are offered from, per seed.
const SPOTS := 10
## Every how many tiles, along each axis, a site is offered.
const SITE_STEP := 3

func run(t) -> void:
	var tiles := 0
	var cut := 0
	var sites := 0
	var really := 0
	var accepted_really := 0
	var accepted := 0
	var by_body := 0
	for seed_value in SEEDS:
		for day in DAYS:
			var city := _start(t, seed_value, day)
			var siting := _siting(city, day)
			var plans := city.events.plans()
			var route := _route_tiles(city)
			var blocked := EventScheduler.blocked_by(city.map, siting._what_already_blocks(plans))
			var day_cut := 0
			for tile in route:
				if not siting._she_can_still_get_away(tile, blocked):
					day_cut += 1
			print("DB_CUT seed %d day %d | %d route tiles | %d read as cut off"
					% [seed_value, day, route.size(), day_cut])
			tiles += route.size()
			cut += day_cut
			if day == SITE_DAY:
				var counts := _sites(city, siting, plans, route, seed_value)
				sites += counts[0]
				really += counts[1]
				accepted_really += counts[2]
				accepted += counts[3]
				by_body += counts[4]
			city.free()
	_ahead(t)
	print("DB_TOTAL_CUT %d of %d route tiles read as cut off" % [cut, tiles])
	print("DB_TOTAL_SITES %d sites | %d really cut her off | %d of those accepted | %d accepted"
			% [sites, really, accepted_really, accepted])
	print("DB_TOTAL_BODY %d sites whose body alone, as the dawn disc, cuts her off" % by_body)
	t.check(tiles > 0 and sites > 0, "there were tiles and sites to ask (%d, %d)" % [tiles, sites])

func _start(t, seed_value: int, day: int) -> City:
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	city.run.header.day = day
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	city.run.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(city.run.attempt_spend.city_state, day, city.run.calendar.day_rng(day, "closures"),
			spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, city.run.calendar.day_rng(day), consumed,
			city.map.doorstep_world_position())
	return city

## The siting the walk's events would build for a task row on `day` (`EventsAhead._task_siting()`).
func _siting(city: City, day: int) -> EventScheduler.WalkSiting:
	return EventScheduler.WalkSiting.new(day, city.map, city.route_tree(),
			city.events.walk_events(), EventScheduler.Verdicts.new())

## Every passable tile the day's routes run along.
func _route_tiles(city: City) -> Array[Vector2i]:
	var corridor := Corridor.of(city.route_tree())
	var found: Array[Vector2i] = []
	for y in city.map.size.y:
		for x in city.map.size.x:
			var tile := Vector2i(x, y)
			if corridor.carries_a_route(tile) and city.map.passable(tile, Mover.lattice()):
				found.append(tile)
	return found

## Day 13's two rows offered round `SPOTS` places along her routes. Answers `[sites, really cut
## her off, of those accepted, accepted]`.
func _sites(city: City, siting: EventScheduler.WalkSiting, plans: Array[EventScheduler.Planned],
		route: Array[Vector2i], seed_value: int) -> Array[int]:
	var map := city.map
	var open: Array[EventScheduler.Planned] = []
	for plan in plans:
		if plan.obstructs() and not plan.is_door():
			open.append(plan)
	var counts: Array[int] = [0, 0, 0, 0, 0]
	var grid := ReachabilityGrid.build(map)
	var calm := siting._calm_she_has_not_used()
	for spot in SPOTS:
		var her_tile := route[(route.size() * spot) / SPOTS]
		var her := map.tile_to_world(her_tile)
		var baseline := EventScheduler.blocked_by(map, open)
		if not _gets_away(map, grid, her_tile, baseline, calm):
			continue
		for id: String in ["barricade", "roadblock"]:
			var def := EventCatalogue.by_id(id)
			for tile in _ground(map, def, her):
				var candidate := EventScheduler.Planned.new(def, map.tile_to_world(tile))
				var with_it := baseline.duplicate()
				EventScheduler.block_a_disc(map, with_it, candidate.position, def.outer_radius)
				var cuts := not _gets_away(map, grid, her_tile, with_it, calm)
				var body := baseline.duplicate()
				EventScheduler.block_a_disc(map, body, candidate.position, candidate.blocking_radius())
				if not _gets_away(map, grid, her_tile, body, calm):
					counts[4] += 1
					print("DB_BODY seed %d | %s at %s | her %s | its body alone cuts her off"
							% [seed_value, id, RunTrace.tile(tile), RunTrace.tile(her_tile)])
				var takes := siting.leaves_her_a_way(candidate, her)
				counts[0] += 1
				if cuts:
					counts[1] += 1
					if takes:
						counts[2] += 1
					print("DB_SITE seed %d | %s at %s | her %s | really cuts her off | accepted %s"
							% [seed_value, id, RunTrace.tile(tile), RunTrace.tile(her_tile), takes])
				if takes:
					counts[3] += 1
	return counts

## The tiles within `NEAR` of `her` the row may stand on, every `SITE_STEP` along each axis.
func _ground(map: CityMap, def: EventDef, her: Vector2) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for tile in EventScheduler.open_ground_for(def, map, {}):
		if tile.x % SITE_STEP != 0 or tile.y % SITE_STEP != 0:
			continue
		if map.tile_to_world(tile).distance_to(her) <= NEAR:
			found.append(tile)
	return found

## Whether a flood from `her` over `blocked` reaches the home and some tile of `calm`, the calm
## she has not used as the siting reads it.
func _gets_away(map: CityMap, grid: ReachabilityGrid, her: Vector2i, blocked: Dictionary,
		calm: Array[Vector2i]) -> bool:
	var reached := grid.flood([her], blocked)
	if not grid.reaches(map.home_rect.position, blocked, reached):
		return false
	for tile in calm:
		if grid.reaches(tile, blocked, reached):
			return true
	return false

## **What the walk's own sitings accept**: day 3's fire and the poster crews of days 4, 9 and 13,
## offered ahead of her (`WalkSiting.ahead_of()`, the band the director sites in) from `SPOTS`
## places along the day's longest route, heading along it, with a stream of their own per ask.
## `DB_AHEAD` counts the asks and the sites accepted, per seed and day.
func _ahead(t) -> void:
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var far := near + Tuning.WALK_SPEED * EventDirector.ON_HER_WAY_SIGHT
	var asked := 0
	var sited := 0
	for seed_value in SEEDS:
		for day: int in [3, 4, 9, 13]:
			var city := _start(t, seed_value, day)
			var siting := _siting(city, day)
			if city.poster_walls():
				siting.fronts = city.poster_walls().fronts()
			var def := EventCatalogue.by_id("burning_building" if day == 3 else "poster_crew")
			def = def.for_day(day)
			var route := _longest(city, siting)
			var day_asked := 0
			var day_sited := 0
			for spot in SPOTS:
				var i := 1 + ((route.size() - 2) * spot) / SPOTS
				if i >= route.size():
					continue
				var heading := (route[i] - route[i - 1]).normalized()
				var rng := RandomNumberGenerator.new()
				rng.seed = hash("door-bodies:%d:%d:%d" % [seed_value, day, spot])
				day_asked += 1
				if siting.ahead_of(def, rng, null, route[i - 1], heading, near, far):
					day_sited += 1
			print("DB_AHEAD seed %d day %d %s | %d asked | %d sited"
					% [seed_value, day, def.id, day_asked, day_sited])
			asked += day_asked
			sited += day_sited
			city.free()
	print("DB_TOTAL_AHEAD %d asked | %d sited" % [asked, sited])

## The cell centres of the day's longest route, from the doorstep end out.
func _longest(city: City, siting: EventScheduler.WalkSiting) -> PackedVector2Array:
	var best: Array = []
	for branch in city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for i in range(best.size() - 1, -1, -1):
		points.append(siting.cell_centre(best[i]))
	return points
