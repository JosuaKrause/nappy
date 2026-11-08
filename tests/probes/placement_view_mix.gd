extends RefCounted
## Measurement probe for the bags per view (`docs/EVENTS.md`, "The three views and the placement
## order"): **what the day's placement puts in each view, per day.** Not a suite: it prints rather
## than asserting, so it lives here under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/placement_view_mix.gd
##
## Each day is planned as the scheduler plans it (`EventScheduler.build_day()` on a repainted city
## and its route tree), and every placed plan is counted under the view of the ground it stands on
## (`Corridor.view_of()` for a street, `Corridor.view_of_ground()` for an alley, a lot or a junction
## box), by row, against the number of locations each view has (`DayLocations.drawing_order()`).
## The rows the director sites in front of her, which the day owes her but places nowhere, are
## counted apart (`MOMENTS`). `PV_VIEW` lines give each view's events per location, which each
## view's empty weight is set from (fork 5(a) of the placement proposal, the orchestrator's reading:
## set from today's measured count), and `PV_DAY` the day's whole count.

const SEEDS := 6
const SAMPLE_DAYS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
const NAMES := ["on the route", "route-adjacent", "off the route"]

func run(t) -> void:
	for day in SAMPLE_DAYS:
		_mix_on(day)
	t.check(true, "placement_view_mix probe ran")

func _mix_on(day: int) -> void:
	var locations_in := [0, 0, 0]
	var counts := [{}, {}, {}]
	var totals := [0, 0, 0]
	var moments := 0
	var placed := 0
	for i in SEEDS:
		var map := CityGenerator.generate(90210 + i * 31)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var corridor := Corridor.of(tree)
		for location in DayLocations.lay_out(map, corridor).drawing_order(_rng(i, day)):
			if location.is_available():
				locations_in[location.view()] += 1
		var rng := _rng(i, day)
		var guarded := ResistanceSteps.guarded_row_on(day)
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(DaySpec.for_day(day), rng, map, CalmAreas.of(map),
				consumed, [], tree, 0, PackedVector2Array(), [] as Array[Vector2i],
				[] as Array[EventScheduler.Planned], null, null,
				EventCatalogue.by_id(guarded) if guarded != "" else null).placements():
			var mode := plan.def.spawn_mode_on(day)
			if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
				moments += 1
				continue
			if not plan.is_placed():
				continue
			placed += 1
			var tile := map.world_to_tile(plan.placed_at())
			var segment := map.network.segment_containing(tile)
			var view := corridor.view_of(segment) if segment else \
					corridor.view_of_ground(Rect2i(tile, Vector2i.ONE))
			var row: Dictionary = counts[view]
			row[plan.row_id()] = int(row.get(plan.row_id(), 0)) + 1
			totals[view] += 1
	var seeds := float(SEEDS)
	print("PV_DAY %d | %.1f placed, %.1f moments owed, per day over %d seeds"
			% [day, placed / seeds, moments / seeds, SEEDS])
	for view in NAMES.size():
		var locations: float = locations_in[view] / seeds
		var events: float = totals[view] / seeds
		print("PV_VIEW %d %s | %.0f locations, %.1f events, %.2f%% of locations"
				% [day, NAMES[view], locations, events, 100.0 * events / maxf(1.0, locations)])
		var rows: Dictionary = counts[view]
		var ids := rows.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return int(rows[a]) > int(rows[b]))
		var parts: Array[String] = []
		for id: String in ids:
			parts.append("%s %.1f" % [id, int(rows[id]) / seeds])
		print("PV_ROWS %d %s | %s" % [day, NAMES[view], ", ".join(parts)])

static func _rng(i: int, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
	return rng
