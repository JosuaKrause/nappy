@warning_ignore_start("untyped_declaration", "unsafe_method_access")
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
## over the seeds. Each day is planned as the game plans it: its closures, holds, region wall and
## seals first, the seals and the wall's bodies handed in as standing.

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
			# The run's mast sites, worked out once on the city as built, as the game does.
			var sites := MastSites.compute(map)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var spec := DaySpec.for_day(day)
			# The day's own closures, holds, region wall and seals, planned as the game plans them
			# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
			# stand as the day's standing and hold their locations.
			var region_plan := RegionPlanner.plan_day(map, spec, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
			var closures := ClosurePlanner.plan_day(map, spec, closure_rng, tree, region_plan)
			map.close_streets(closures)
			map.clear_day_holds()
			for closure: RoadClosure in closures:
				map.hold_segment(closure.segment.key(), HeldStreets.Why.CLOSURE)
			for segment: StreetNetwork.Segment in region_plan.walls:
				map.hold_segment(segment.key(), HeldStreets.Why.WALL)
			for segment: StreetNetwork.Segment in region_plan.doors:
				map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
			for segment: StreetNetwork.Segment in map.network.around_blocks(
					Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key(), HeldStreets.Why.HOME)
			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
			var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary, map.held_streets())
			for seal in seals:
				seal.stand_as_a_seal()
			var doors := PackedVector2Array()
			for body in region_plan.door_bodies:
				doors.append(body.position)
			var standing: Array[EventScheduler.Planned] = []
			standing.append_array(seals)
			standing.append_array(region_plan.wall_bodies)
			for body in region_plan.wall_bodies:
				body.stand_in_the_wall()
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
			var guarded := ResistanceSteps.guarded_row_on(day)
			var consumed: Array[String] = []
			for plan in EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), sites,
					consumed, [], tree, 0, doors, standing, null,
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
