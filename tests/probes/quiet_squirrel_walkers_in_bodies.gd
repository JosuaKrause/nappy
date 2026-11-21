extends RefCounted
## Walkers standing inside a body's tile on seed 67, days 2 and 7, at the precinct column x=24
## (quiet-squirrel). Printed, not asserted; not a suite, run by name:
##
##     tools/test.sh probes/quiet_squirrel_walkers_in_bodies.gd
##
## Boots each day the way `main.gd` does (as `m219_precinct_pile.gd` does), puts the crowd's focus
## on (24,156), and for forty seconds counts walker-frames whose tile is in
## `CityMap.obstructed_tiles`. For each time a walker enters such a tile it prints the frame, the
## walker, the tile, where it stood the frame before and whether that tile was already obstructed,
## so a walker that walked in, one placed or recycled into a body, and one a body appeared under
## can be told apart. At dawn the bodies there are a `burst_water_main` across all six precinct
## lanes (x=24, y=154..159) on day 2, and a `car_accident` in lanes 2-3 ((24,156), (24,157)) on
## day 7.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0

func run(t) -> void:
	for day: int in [2, 7]:
		var seed_value := 67
		var map := CityGenerator.generate(seed_value)
		var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
		city.run.header.day = day
		t.add_child(city)
		city.build(map)
		city.run.attempt_spend.city_state.begin_day(map.block_plans, day)
		city.start_day(city.run.attempt_spend.city_state, day, city.run.calendar.day_rng(day, "closures"))
		var doorstep := map.doorstep_world_position()
		city.events.start_day(DaySpec.for_day(day), city.run.calendar.day_rng(), city.run.attempt_spend.consumed_one_shots, doorstep)
		var at := map.tile_to_world(Vector2i(24, 156))
		city.events.stream_around(at)
		city.crowd.start_day(day, city.run.calendar.day_rng(day, "crowd"), at)
		city.crowd.set_gates(city.streets().region_plan().gates)
		var prev := {}
		var inside_frames := 0
		var entries := []
		for frame in int(40.0 / STEP):
			city.crowd.set_focus(at)
			city.crowd.step(STEP)
			var now := {}
			for agent in city.crowd.agents():
				if agent.kind != CrowdAgent.Kind.WALKER:
					continue
				var tile := map.world_to_tile(agent.position)
				var id := agent.get_instance_id()
				var inside := map.is_obstructed(tile)
				now[id] = [agent.position, inside]
				if inside:
					inside_frames += 1
					var was = prev.get(id)
					if was == null or not was[1]:
						var from := Vector2.INF if was == null else (was[0] as Vector2)
						var from_tile := Vector2i(-99, -99) if was == null else map.world_to_tile(from)
						entries.append("f%d id%d tile %s pos %s from %s (%s) obstructed-before=%s dir=%s vert=%s lane=%s detour=%.1f"
								% [frame, id, tile, agent.position, from, from_tile,
								map.is_obstructed(from_tile), agent._direction, agent._vertical,
								agent._lane_centre, agent._detour])
			prev = now
		print("day %d: inside walker-frames %d, entries %d" % [day, inside_frames, entries.size()])
		for line in entries.slice(0, 40):
			print("  ", line)
		city.free()
	t.check(true, "ran")
