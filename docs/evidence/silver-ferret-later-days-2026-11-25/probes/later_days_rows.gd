extends RefCounted
## Evidence copy (silver-ferret, the later days judged on their events' difficulty and count):
## `tests/probes/placement_rows.gd` as it stands on the measured tree, its `RD`, `RV` and `RK`
## lines unchanged, with two kinds of line added: `RM day row count`, the moments the dawn owes
## her counted under their row (`placement_rows.gd` counts them only as a total), and
## `FLAGS id ends_the_day pursues waits hunts_for_her` for every catalogue row (the evidence copy
## `row_flags.gd` of the minty-quail end remeasure, N8). Copied into `tests/probes/` of the
## worktree uncommitted to run, removed after; not part of the repository's probes.

const SEEDS := 18

func run(t: TestRunner) -> void:
	for def: EventDef in CatalogueRows.every():
		print("FLAGS %s %d %d %d %d" % [def.id(), int(def.ends_the_day()), int(def.pursues()),
				int(def.waits_for_her()), int(def.hunts_for_her())])
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var by_moment := {}
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
					by_moment[plan.row_id()] = int(by_moment.get(plan.row_id(), 0)) + 1
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
		for key: String in by_moment:
			print("RM %d %s %d" % [day, key, by_moment[key]])
	t.check(true, "later days probe ran")

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
