extends RefCounted
## Measurement probe for the bags per view (`docs/EVENTS.md`, "The three views and the placement
## order"): **what today's placement puts in each view, per day.** Not a suite: it prints rather
## than asserting, so it lives here under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/placement_view_mix.gd
##
## Each day is planned as the scheduler plans it (`EventScheduler.build_day()` on a repainted city
## and its route tree), and every placed plan standing on a street is counted under its street's view
## (`Corridor.view_of()`), by row; plans off the streets (squares, parks, alleys, junction boxes) are
## counted apart, since no view's locations hold them yet. Read with the number of sidewalk locations
## each view has (`StreetLocations`: six a street), it gives each view's share of drawn events against
## empty ones, which is what the empty marble's weight in each view's bag is set from (fork 5(a) of
## the placement proposal, *read as* the orchestrator's: set from today's measured count).

const SEEDS := 6
const SAMPLE_DAYS := [1, 4, 7, 10, 13, 14]
const NAMES := ["on the route", "route-adjacent", "off the route"]

func run(t) -> void:
	for day in SAMPLE_DAYS:
		_mix_on(day)
	t.check(true, "placement_view_mix probe ran")

func _mix_on(day: int) -> void:
	var streets := [0, 0, 0]
	var counts := [{}, {}, {}]
	var totals := [0, 0, 0]
	var off_the_streets := 0
	for i in SEEDS:
		var map := CityGenerator.generate(90210 + i * 31)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		for segment in map.network.segments():
			if map.has_street(segment.key()):
				streets[corridor.view_of(segment)] += 1
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("placement_view_mix:%d:%d" % [map.seed_used, day])
		var guarded := ResistanceSteps.guarded_row_on(day)
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(DaySpec.for_day(day), rng, map, CalmAreas.of(map),
				consumed, [], tree, 0, PackedVector2Array(), [] as Array[Vector2i],
				[] as Array[EventScheduler.Planned], null, null,
				EventCatalogue.by_id(guarded) if guarded != "" else null).placements():
			if not plan.is_placed():
				continue
			var segment := map.network.segment_containing(map.world_to_tile(plan.placed_at()))
			if segment == null:
				off_the_streets += 1
				continue
			var view := corridor.view_of(segment)
			var row: Dictionary = counts[view]
			row[plan.row_id()] = int(row.get(plan.row_id(), 0)) + 1
			totals[view] += 1
	var seeds := float(SEEDS)
	print("\n== day %d, %d seeds: placed events per day by view ==" % [day, SEEDS])
	for view in NAMES.size():
		var locations: float = streets[view] * 6.0 / seeds
		var events: float = totals[view] / seeds
		print("  %s: %.1f streets, %.0f sidewalk locations, %.1f events (%.1f%% of locations)"
				% [NAMES[view], streets[view] / seeds, locations, events,
				100.0 * events / maxf(1.0, locations)])
		var rows: Dictionary = counts[view]
		var ids := rows.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return int(rows[a]) > int(rows[b]))
		var parts: Array[String] = []
		for id: String in ids:
			parts.append("%s %.1f" % [id, int(rows[id]) / seeds])
		print("    " + ", ".join(parts))
	print("  off the streets: %.1f events" % (off_the_streets / seeds))
