extends RefCounted
## Measurement probe for the bags per view (`docs/EVENTS.md`, "The three views and the placement
## order"): **what the day's placement puts in each view, per day.** Not a suite: it prints rather
## than asserting, so it lives here under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/placement_view_mix.gd
##
## Each day is planned as the game plans it (`DayPlanner._plan_a_day()`): its closures, holds,
## region wall and seals first, the seals and the wall's bodies handed in as standing, then
## `EventScheduler.build_day()` on the repainted city and its route tree at heat 0, like every
## baseline reading, the guarded-band roadblock row handed through
## `EventCatalogue.heated()` as the day does (`PlacementProbeDay`), the street trees
## refreshed after. Every placed plan is counted under the view of the ground it stands on
## (`Corridor.view_of()` for a street, `Corridor.view_of_ground()` for an alley, a lot or a
## junction box), by row, against the number of locations each view has (`DayLocations.all()`).
## The rows the director sites in front of her, which the day owes her but places nowhere, are
## counted apart (`MOMENTS`). `PV_VIEW` lines give each view's events per location and `PV_DAY`
## the day's whole count; the declared table's own cells, by view, kind of ground and act, are
## `tests/probes/placement_cells.gd`'s.

const SEEDS := 18
const SAMPLE_DAYS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
const NAMES := ["on the route", "route-adjacent", "off the route"]

## Where each day's city stands while it is asked.
var _parent: Node

func run(t: TestRunner) -> void:
	_parent = t
	for day: int in SAMPLE_DAYS:
		_mix_on(day)
	t.check(true, "placement_view_mix probe ran")

func _mix_on(day: int) -> void:
	var locations_in := [0, 0, 0]
	var counts := [{}, {}, {}]
	var totals := [0, 0, 0]
	var moments := 0
	var placed := 0
	for i in SEEDS:
		var the_day := PlacementProbeDay.prepared(day, i, "placement_view_mix", _parent)
		var map := the_day.map
		var corridor := the_day.corridor
		for location in DayLocations.lay_out(map, corridor).all():
			if location.is_available():
				locations_in[location.view()] += 1
		for plan in the_day.placements():
			var mode := plan.spawn_mode_on(day)
			# A row the director sends ahead of her is a moment where the dawn left it unplaced.
			if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER \
					or (plan.is_sent_ahead() and not plan.is_placed()):
				moments += 1
				continue
			if not plan.is_placed():
				continue
			placed += 1
			var tile := map.world_to_tile(plan.placed_at())
			var segment := map.street_network().segment_containing(tile)
			var view := corridor.view_of(segment) if segment else \
					corridor.view_of_ground(Rect2i(tile, Vector2i.ONE))
			var row: Dictionary = counts[view]
			row[plan.row_id()] = int(row.get(plan.row_id(), 0)) + 1
			totals[view] += 1
		the_day.city.free()
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
