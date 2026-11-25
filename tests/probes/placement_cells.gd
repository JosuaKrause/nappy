extends RefCounted
## Measurement probe for the declared table (`docs/EVENTS.md`, "The density, and why it is a
## declared table"; `PlacementDensity`): **what the units place, by view, kind of ground and day,
## over the draw locations they had to place it on**, the measure every cell of the table is stated
## in. Not a suite: it prints rather than asserting, so it lives here under `tests/probes/`, where
## the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/placement_cells.gd
##
## Each day is planned as `walk_rows.gd` plans it (its closures, holds, region wall and seals
## first, the seals and the wall's bodies handed in as standing), on `SEEDS` cities from `BASE` in
## steps of `STEP` and the same streams, its units left undrawn (`GameDawn.undrawn()`); each unit's
## room is counted in small marbles (`UnitRoom`: a street's open sidewalk locations, a junction box,
## an alley's thirds, a lot's cells, the draw locations of the table), and then every unit is drawn
## (the same whatever the order, `UnitDraw`). Prints, summed over the seeds:
##
## - `CL day view ground units room`: the units of that view and ground and their draw locations;
## - `CE day view ground row count`: the rows the units drew there, a row handed to her walk among
##   them;
## - `CP day ground row tiles count`: the pacing rows drawn on that ground (`RouteSpec.pacing()`:
##   the man shouting and the chatting mother), by the length of their beat in whole tiles, which a
##   junction box cuts short (`Location.run()`).
##
## The view and the ground are the unit's (`PlacementUnit.view()`, `kind()`): 0 on the route, 1
## route-adjacent, 2 off the route; `street`, `junction`, `alley`, `open`. The evidence folder
## `docs/evidence/polite-tapir-declared-table-2026-11-16/` holds the scripts that read the lines
## beside the table's seed.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const GROUNDS := ["street", "junction", "alley", "open"]

func run(t: TestRunner) -> void:
	for day in range(1, 15):
		var room_by := {}
		var units_by := {}
		var events_by := {}
		var beats_by := {}
		for i in SEEDS:
			var map := CityGenerator.generate(BASE + i * STEP)
			# The run's mast sites, worked out once on the city as built, as the game does.
			var sites := MastSites.compute(map)
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
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
				map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
			for segment: StreetNetwork.Segment in region_plan.wall_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.WALL)
			for segment: StreetNetwork.Segment in region_plan.door_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
			for segment: StreetNetwork.Segment in map.street_network().around_blocks(
					Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
				map.hold_segment(segment.key(), HeldStreets.Why.HOME)
			var boundary := {}
			for segment in region_plan.wall_segments():
				boundary[segment.key()] = true
			for segment in region_plan.door_segments():
				boundary[segment.key()] = true
			for rect in region_plan.walled_alleys():
				boundary[rect.position] = true
			for rect in region_plan.door_alleys():
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
			var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary,
					map.held_streets())
			for seal in seals:
				seal.stand_as_a_seal()
			var doors := PackedVector2Array()
			for body in region_plan.door_plans():
				doors.append(body.placed_at())
			var standing: Array[EventPlan] = []
			standing.append_array(seals)
			standing.append_array(region_plan.wall_plans())
			for body in region_plan.wall_plans():
				body.stand_in_the_wall()
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
			var guarded := ResistanceSteps.guarded_row_on(day)
			var consumed: Array[String] = []
			var dawn: DawnContext = GameDawn.of(spec, rng, map).masts(sites).spent(consumed) \
					.on(tree).doors(doors).standing(standing) \
					.roadblock(EventCatalogue.by_id(guarded) if guarded != "" else null) \
					.undrawn().planned()
			var draw := dawn.unit_draw()
			var units := draw.units().undrawn_within(Vector2.ZERO, INF)
			for unit in units:
				var key := "%d %s" % [unit.view(), GROUNDS[unit.kind()]]
				var room := UnitRoom.of(unit)
				var count := 0
				while room.is_open():
					room.take(EventDef.StreetShare.A_LOCATION)
					count += 1
				room_by[key] = int(room_by.get(key, 0)) + count
				units_by[key] = int(units_by.get(key, 0)) + 1
			for unit in units:
				draw.draw(unit)
			for unit in units:
				var key := "%d %s" % [unit.view(), GROUNDS[unit.kind()]]
				for plan in unit.drawn():
					var ek := "%s %s" % [key, plan.row_id()]
					events_by[ek] = int(events_by.get(ek, 0)) + 1
					if plan.row().paces_a_beat() and plan.is_placed():
						var bk := "%s %s %d" % [GROUNDS[unit.kind()], plan.row_id(),
								_beat_in_tiles(plan.walks())]
						beats_by[bk] = int(beats_by.get(bk, 0)) + 1
		for key: String in room_by:
			print("CL %d %s %d %d" % [day, key, units_by[key], room_by[key]])
		for key: String in events_by:
			print("CE %d %s %d" % [day, key, events_by[key]])
		for key: String in beats_by:
			print("CP %d %s %d" % [day, key, beats_by[key]])
	t.check(true, "placement_cells probe ran")

## How long a pacing row's beat is, in whole tiles: the length of its path end to end.
static func _beat_in_tiles(path: PackedVector2Array) -> int:
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i].distance_to(path[i - 1])
	return roundi(length / Tuning.TILE_SIZE)
