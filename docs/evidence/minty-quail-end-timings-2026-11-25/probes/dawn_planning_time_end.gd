extends RefCounted
## COPY of tests/probes/placement_rows.gd at fc29914e60afd85bb216bd5e9307b00a3b66218a (today's main) with SEEDS = 14
## and timers around the dawn's planning, made the way dawn_planning_time_after_4b.gd was made from the after-4b
## tree's probe. It plans through placement_probe_day_timed.gd (a copy of the helper, whose header says where the
## two timers stand) and prints DAWN_PLANNING build_day_sec, draw_every_unit_sec and whole_probe_sec once. Since
## minty-quail-tiny-magpie the probe plans each day's closures, region wall and seals as DayPlanner does and builds
## a city node (RunCity) per city; that work is outside both timers and inside whole_probe_sec, so the whole-probe
## figure here holds more than the after-4b copy's. The RD / RV / RK lines are the probe's own, with SEEDS = 14.
## Measurement probe for the day's mix (`docs/EVENTS.md`, "The density, and why it is a declared
## table"): **what each day places, row by row, by view and by kind of ground.** Not a suite: it
## prints rather than asserting, so it lives here under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/placement_rows.gd
##
## It asks what the game's own dawn asks (`EventScheduler.build_day()`, `Corridor.view_of()`,
## the tile under each plan), row by row beside the declared table's cells
## (`tests/probes/placement_cells.gd`): each day planned as the scheduler plans it, on `SEEDS`
## cities from `PlacementProbeDay.BASE` in steps of `PlacementProbeDay.STEP` and the streams
## `placement_view_mix.gd` uses, and every placed plan counted under its row, its view (its
## street's, or the depth of its tile off the streets) and its kind of ground (a junction box,
## an alley, a park or square, a carriageway, a sidewalk). The moments she is owed are counted
## apart. Prints `RD day seeds placed moments`, `RV day row view count` and `RK day row kind
## count`, each summed over the seeds. Each day is planned as the game plans it: its closures,
## holds, region wall and seals first, the seals and the wall's bodies handed in as standing,
## the guarded-band roadblock row handed through `EventCatalogue.heated()` as `DayPlanner` does,
## at heat 0 like every baseline reading, and the street trees refreshed after the dawn
## (`PlacementProbeDay`, which both placement probes plan through).

const SEEDS := 14
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]

func run(t: TestRunner) -> void:
	var whole_began := Time.get_ticks_usec()
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		var moments := 0
		for i in SEEDS:
			var the_day := PlacementProbeDayTimed.prepared(day, i, "placement_rows", t)
			var map := the_day.map
			var corridor := the_day.corridor
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
				var view := 0
				if segment:
					view = corridor.view_of(segment)
				else:
					var d := corridor.depth(tile)
					view = 0 if d == 0 else (1 if d == 1 else 2)
				var kind := _kind_of(map, tile)
				var id := plan.row_id()
				var kv := "%s %d" % [id, view]
				by_view[kv] = int(by_view.get(kv, 0)) + 1
				var kk := "%s %s" % [id, kind]
				by_kind[kk] = int(by_kind.get(kk, 0)) + 1
			the_day.city.free()
		print("RD %d %d %d %d" % [day, SEEDS, placed, moments])
		for key: String in by_view:
			print("RV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("RK %d %s %d" % [day, key, by_kind[key]])
	print("DAWN_PLANNING build_day_sec %.3f draw_every_unit_sec %.3f whole_probe_sec %.3f cities %d days 14" % [
			PlacementProbeDayTimed.build_usec / 1e6, PlacementProbeDayTimed.draw_usec / 1e6,
			(Time.get_ticks_usec() - whole_began) / 1e6, SEEDS])
	t.check(true, "dawn planning probe ran")

static func _kind_of(map: CityMap, tile: Vector2i) -> String:
	if CityMap.junction_at(tile) != Vector2i(-1, -1):
		return "junction"
	match map.tile_at(tile):
		GameEnums.TileType.ALLEY:
			return "alley"
		GameEnums.TileType.PARK, GameEnums.TileType.SQUARE:
			return "open"
		GameEnums.TileType.ROAD:
			return "carriageway"
		GameEnums.TileType.SIDEWALK:
			return "sidewalk"
	return "other"
