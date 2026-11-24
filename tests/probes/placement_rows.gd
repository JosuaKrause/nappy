extends RefCounted
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

const SEEDS := 18
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]

func run(t: TestRunner) -> void:
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		var moments := 0
		for i in SEEDS:
			var the_day := PlacementProbeDay.prepared(day, i, "placement_rows", t)
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
	t.check(true, "rows probe ran")

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
