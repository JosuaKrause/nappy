extends RefCounted
## Measurement probe for the day's mix (`docs/EVENTS.md`, "The density, and why it is caps and
## bags"): **what each day places, row by row, by view and by kind of ground.** Not a suite: it
## prints rather than asserting, so it lives here under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/placement_rows.gd
##
## It asks only what every tree has (`EventScheduler.build_day()`, `Corridor.view_of()`, the tile
## under each plan), so the same file measures main and a branch alike, which is how
## `EventScheduler.GROUND_WEIGHTS` and `VIEW_SHARE_SCALES` are fitted: each day planned as the
## scheduler plans it, on `SEEDS` cities from `BASE` in steps of `STEP` and the streams
## `placement_view_mix.gd` uses, and every placed plan counted under its row, its view (its street's,
## or the depth of its tile off the streets) and its kind of ground (a junction box, an alley, a
## park or square, a carriageway, a sidewalk). The moments she is owed are counted apart. Prints
## `RD day seeds placed moments`, `RV day row view count` and `RK day row kind count`, each summed
## over the seeds.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]

func run(t) -> void:
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		var moments := 0
		for i in SEEDS:
			var map := CityGenerator.generate(BASE + i * STEP)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
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
