extends RefCounted
## The seals that stand on a pedestrian street (a precinct), and what each leaves open across it.
## Printed, not asserted; not a suite, run by name:
##
##     tools/test.sh probes/crisp_beaver_precinct_seals.gd     (prints PRECINCT_SEAL lines)
##
## A day's seals are `SealPlanner.plan_day()`'s, on `RouteTree.for_day()`'s tree and the rng
## `tests/test_seals.gd` seeds them with, the tutorial route handed in on the day she walks it.
## For each seal on a precinct it prints its rows, its strength and two openings across the
## street, taken over the stretch three tiles either side of the seal:
##
## - **lanes**: the walker lanes (the street's six tiles across) that no body's footprint
##   (`EventSpawner.footprint_of()`, what the crowd steers round) and no soft-sealed tile
##   (`CityMap.soft_sealed_tiles()`) touches in that stretch, so a walker walks straight through;
## - **her**: the widest band across the street, in px, where her centre passes the whole stretch
##   with no solid piece holding it off (`WalkGround.Solid.stops_her_at()`), so she walks straight
##   through it too. 0 is closed to her.
##
## Then one PRECINCT_SEALS line per seed: the seals on precincts, the soft ones among them, and
## those leaving a lane or a band open.

const SEEDS: Array[int] = [67, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
		20, 24757, 71717]
## How far either side of a seal's own tile the openings are asked over, in tiles.
const STRETCH := 3
## The step her centre is sampled at, in px.
const STEP := 2.0

func run(t: TestRunner) -> void:
	var strength_of := {}
	for candidate in SealPlanner.candidates():
		for id in candidate.def_ids:
			strength_of[id] = "hard" if candidate.strength == SealPlanner.Strength.HARD else "soft"
	var total_seals := 0
	var total_soft := 0
	var total_open := 0
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var tutorial := TutorialRoute.for_city(Shipped.rows(), map)
		var seals := 0
		var soft := 0
		var open := 0
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var spec := DaySpec.for_day(day)
			var route: TutorialRoute = tutorial if spec.walks_the_tutorial() else null
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("seals:%d:%d" % [map.city_seed(), day])
			var plans := SealPlanner.plan_day(Shipped.rows(), map, spec,
					RouteTree.for_day(map, day, route), rng, {}, null, route)
			var footprint := {}
			for plan in plans:
				for tile in EventSpawner.footprint_of(BodyStance.of_plan(map, plan)):
					footprint[tile] = true
			var soft_tiles := map.soft_sealed_tiles()
			var ground := WalkGround.new(map, plans)
			for group: Array in _seals_on_precincts(map, plans):
				var segment: StreetNetwork.Segment = group[0]
				var bodies: Array[EventPlan] = []
				bodies.assign(group[1])
				var ids := {}
				var is_soft := false
				for body in bodies:
					ids[body.row_id()] = true
					is_soft = is_soft or strength_of.get(body.row_id(), "") == "soft"
				var along := _along_of(map, segment, bodies[0])
				var lanes := _open_lanes(segment, along, footprint, soft_tiles)
				var her := _her_widest_band(map, segment, along, ground, bodies)
				seals += 1
				soft += 1 if is_soft else 0
				open += 1 if lanes.size() > 0 or her > 0.0 else 0
				print("PRECINCT_SEAL seed %d day %d street %s %s %s lanes open %s, her band %.0fpx"
						% [seed_value, day, segment.key(), "soft" if is_soft else "hard",
						",".join(ids.keys()), lanes, her])
		print("PRECINCT_SEALS seed %d: %d seals on precincts, %d soft, %d leave a way through"
				% [seed_value, seals, soft, open])
		total_seals += seals
		total_soft += soft
		total_open += open
	print("PRECINCT_SEALS all %d seeds: %d seals on precincts, %d soft, %d leave a way through"
			% [SEEDS.size(), total_seals, total_soft, total_open])
	t.check(true, "crisp_beaver_precinct_seals probe ran")

## The day's seal bodies standing on a precinct, grouped by street and by the tile they stand at
## along it: each entry is [segment, bodies].
func _seals_on_precincts(map: CityMap, plans: Array[EventPlan]) -> Array[Array]:
	var groups := {}
	var found: Array[Array] = []
	for plan in plans:
		var segment := map.street_network().segment_containing(map.world_to_tile(plan.placed_at()))
		if segment == null or not TutorialRoute.is_a_precinct(map, segment):
			continue
		var along := _along_of(map, segment, plan)
		var key := "%s:%d" % [segment.key(), along]
		if not groups.has(key):
			var entry: Array = [segment, [] as Array[EventPlan]]
			groups[key] = entry
			found.append(entry)
		var group: Array = groups[key]
		var bodies: Array[EventPlan] = group[1]
		bodies.append(plan)
	return found

func _along_of(map: CityMap, segment: StreetNetwork.Segment, plan: EventPlan) -> int:
	var tile := map.world_to_tile(plan.placed_at())
	return tile.x if segment.horizontal else tile.y

## The lanes across `segment` that nothing touches within `STRETCH` tiles of `along`.
func _open_lanes(segment: StreetNetwork.Segment, along: int, footprint: Dictionary,
		soft_tiles: Dictionary) -> Array[int]:
	var rect := segment.tile_rect()
	var open: Array[int] = []
	for lane in Tuning.STREET_WIDTH:
		var clear := true
		for step in range(-STRETCH, STRETCH + 1):
			var tile := Vector2i(along + step, rect.position.y + lane) if segment.horizontal \
					else Vector2i(rect.position.x + lane, along + step)
			if not rect.has_point(tile):
				continue
			if footprint.has(tile) or soft_tiles.has(tile):
				clear = false
				break
		if clear:
			open.append(lane)
	return open

## The widest band across `segment`, in px, where her centre passes `STRETCH` tiles either side
## of `along` with none of `bodies`' solid pieces holding it off.
func _her_widest_band(map: CityMap, segment: StreetNetwork.Segment, along: int,
		ground: WalkGround, bodies: Array[EventPlan]) -> float:
	var solids: Array[WalkGround.Solid] = []
	for body in bodies:
		solids.append_array(ground.solids_of(body))
	var world := map.tile_rect_to_world(segment.tile_rect())
	var width: float = world.size.y if segment.horizontal else world.size.x
	var centre := (float(along) + 0.5) * Tuning.TILE_SIZE
	var reach := float(STRETCH) * Tuning.TILE_SIZE
	var widest := 0.0
	var run := 0.0
	var across := Tuning.PLAYER_BODY_RADIUS
	while across <= width - Tuning.PLAYER_BODY_RADIUS:
		var clear := true
		var on := centre - reach
		while on <= centre + reach and clear:
			var at := Vector2(on, world.position.y + across) if segment.horizontal \
					else Vector2(world.position.x + across, on)
			for solid in solids:
				if solid.stops_her_at(at):
					clear = false
					break
			on += STEP
		run = run + STEP if clear else 0.0
		widest = maxf(widest, run)
		across += STEP
	return widest
