extends RefCounted
## Throwaway seed probe for placement step 3 (the declared table), written against main as it
## stood on 2026-11-09 (38ce038): every location drawn once at dawn from its view's bag, with the
## caps. Plans each day exactly as this tree's `placement_rows.gd` does (same cities, same
## streams), then reads the day's locations after the draw. Prints, summed over the seeds:
##   RD day seeds placed moments            (as placement_rows.gd, a cross-check)
##   SL day view ground available open      (the draw's small locations: a street's sidewalk
##                                           locations, a junction box, an alley's thirds, a
##                                           lot's cells; open = not held by a dawn phase)
##   SE day view ground row count           (the rows the draw placed there)
## view is the unit's: a street's, a box's, or the most permissive of an alley's or a lot's.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const GROUNDS := ["street", "junction", "alley", "open"]

func run(t) -> void:
	for day in range(1, 15):
		var denom := {}
		var events_by := {}
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
			var day_events := EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), sites,
					consumed, [], tree, 0, doors, standing, null,
					EventCatalogue.by_id(guarded) if guarded != "" else null)
			for plan in day_events.placements():
				var mode := plan.def.spawn_mode_on(day)
				if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
					moments += 1
					continue
				if plan.is_placed():
					placed += 1
			var locations: DayLocations = day_events.locations()
			var all: Array[Location] = locations.drawing_order(RandomNumberGenerator.new())
			# The lot of every alley, park and square tile, so an alley's thirds and a lot's cells
			# share the most permissive of their views, as a unit does.
			var lot_of := {}
			_flood(map, [GameEnums.TileType.ALLEY], lot_of, 0)
			_flood(map, [GameEnums.TileType.PARK, GameEnums.TileType.SQUARE], lot_of, 1000000)
			var lot_view := {}
			var lot_at := {}
			var section_at := {}
			for location in all:
				var kind := location.kind()
				if kind == Location.Kind.SECTION:
					section_at["%s:%d" % [location.segment().key(), location.section()]] = location
				if kind == Location.Kind.ALLEY or kind == Location.Kind.OPEN:
					var lot := _lot_in(location.tiles(), lot_of)
					lot_at[location] = lot
					lot_view[lot] = mini(int(lot_view.get(lot, 2)), location.view())
			for location in all:
				var kind := location.kind()
				var ground := 0
				var view := location.view()
				if kind == Location.Kind.JUNCTION:
					ground = 1
				elif kind == Location.Kind.ALLEY:
					ground = 2
					view = int(lot_view[lot_at[location]])
				elif kind == Location.Kind.OPEN:
					ground = 3
					view = int(lot_view[lot_at[location]])
				var key := "%d %s" % [view, GROUNDS[ground]]
				var plan: EventScheduler.Planned = location._plan
				if location.is_drawn() and plan != null:
					var ek := "%s %s" % [key, plan.row_id()]
					events_by[ek] = int(events_by.get(ek, 0)) + 1
				if kind == Location.Kind.SECTION:
					continue
				var counts: Array = denom.get(key, [0, 0])
				if location.is_available():
					counts[0] += 1
					var by_phase := location.is_taken() and not location.is_drawn()
					if by_phase and kind == Location.Kind.SIDEWALK:
						var section: Location = section_at["%s:%d" % [location.segment().key(),
								location.section()]]
						if section.is_drawn() and section.is_taken():
							by_phase = false
					if not by_phase:
						counts[1] += 1
				denom[key] = counts
		print("RD %d %d %d %d" % [day, SEEDS, placed, moments])
		for key: String in denom:
			print("SL %d %s %d %d" % [day, key, denom[key][0], denom[key][1]])
		for key: String in events_by:
			print("SE %d %s %d" % [day, key, events_by[key]])
	t.check(true, "seed probe ran")

static func _flood(map: CityMap, types: Array, lot_of: Dictionary, base: int) -> void:
	var next_id := base
	for type: int in types:
		for start in map.tiles_of_type(type as GameEnums.TileType):
			if lot_of.has(start):
				continue
			next_id += 1
			var queue: Array[Vector2i] = [start]
			lot_of[start] = next_id
			while not queue.is_empty():
				var at: Vector2i = queue.pop_back()
				for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next := at + step
					if not lot_of.has(next) and map.in_bounds(next) \
							and types.has(int(map.tile_at(next))):
						lot_of[next] = next_id
						queue.append(next)

static func _lot_in(rect: Rect2i, lot_of: Dictionary) -> int:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if lot_of.has(Vector2i(x, y)):
				return int(lot_of[Vector2i(x, y)])
	return -1
