extends RefCounted
## Measurement probe for M181, "the station's front door, day 9's door and day 12's swing are
## reachable by construction": for each seed and each of the three days, how many of the day's target
## candidates are legal ground, how many of those are also unobstructed and reachable from home
## under the day's whole obstruction, and where the director actually puts the contact. Not a suite
## — it prints numbers rather than asserting relationships — so it lives under `tests/probes/`,
## where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m181_resistance_targets.gd
##
## **The real day order**, as `main.gd`'s `_start_day()` runs it: `City.start_day()` (the tree, the
## region plan and the closures), then `EventManager.start_day()` (the seals, the catalogue, the
## wall and door bodies), then the director. Each day is asked fresh, with no history, the way
## `--day N` boots.
##
## **Reachable** is the director's own question (`ResistanceDirector._reachable_from_home()`):
## every placed plan that obstructs or is hard-fail, a region door's own bodies excepted, painted as
## `EventScheduler.blocked_by()` discs over today's closures, flooded from the home. Built here
## independently rather than asked of the director.

const SEEDS: Array[int] = [4242, 90210, 1234567, 2295276695, 291862120, 314159, 555555, 271828,
		8675309, 1000003, 777, 31337]
## How many more cities, past the named ones, a wide run plans — seeded `BASE_SEED + i * 7919`.
const EXTRA_SEEDS := 28
const BASE_SEED := 181_000
const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	var saved_progress := GameState.resistance_progress
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	print("\n== M181: the day's resistance target, reachable from home ==")
	print("%-12s %4s %-8s %6s %6s %6s  %s" % ["seed", "day", "target", "legal", "open", "reach",
			"placed at (reachable?)"])
	var failures := 0
	var cases := 0
	var seeds: Array[int] = SEEDS.duplicate()
	for i in EXTRA_SEEDS:
		seeds.append(BASE_SEED + i * 7919)
	for seed_value in seeds:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day: int in [9, 12, 14]:
			var state := CityState.new()
			state.begin_day(city.map.block_plans, day)
			city.start_day(state, day, _rng(seed_value, day, "closures"))
			city.events.start_day(day, _rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())
			var director := ResistanceDirector.new()
			t.add_child(director)
			director.set_process(false)
			director.setup(city, city.map)
			var step: ResistanceSteps.Step = _step_for(day)
			var candidates := _candidates(city, day)
			var region_plan := city.region_plan()
			var walled: Array[Rect2i] = region_plan.alley_walls if region_plan else []
			var door_bodies: Array[EventScheduler.Planned] = \
					region_plan.door_bodies if region_plan else []
			var blockers: Array[EventScheduler.Planned] = []
			for plan in city.events.plans():
				if not plan.is_placed() or plan in door_bodies:
					continue
				if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
					blockers.append(plan)
			var grid := ReachabilityGrid.build(city.map)
			var blocked := EventScheduler.blocked_by(city.map, blockers)
			var reached := grid.flood([city.map.home_rect.position], blocked)
			var legal := 0
			var open := 0
			var reach := 0
			var allow_held := ResistanceSteps.stands_on_held_ground(step)
			for tile in candidates:
				var map := city.map
				if not map.is_walkable(tile) or map.is_closed(tile) \
						or (not allow_held and map.is_held_at(tile)) or map.is_on_home_block(tile) \
						or map.is_in_walled_alley(tile, walled):
					continue
				legal += 1
				if map.is_obstructed(tile):
					continue
				open += 1
				if grid.reaches(tile, blocked, reached):
					reach += 1
			var director_rng := _rng(seed_value, day, "resistance")
			var at := director._place(step, director_rng)
			var placed := "nowhere"
			if at != Vector2.INF:
				var tile := city.map.world_to_tile(at)
				var ok := grid.reaches(tile, blocked, reached) and not city.map.is_obstructed(tile)
				placed = "%s (%s)" % [tile, "yes" if ok else "NO"]
				if not ok:
					failures += 1
			else:
				failures += 1
			cases += 1
			print("%-12d %4d %-8s %6d %6d %6d  %s" % [seed_value, day, _name(step), legal, open,
					reach, placed])
			director.free()
		city.free()
	print("%d of %d placements unreachable or nowhere" % [failures, cases])
	GameState.resistance_progress = saved_progress

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## The narrow-target step for the day: the perform half of day 9 and day 12, the finale on day 14.
func _step_for(day: int) -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.day != day or step.is_pickup:
			continue
		return step
	return null

func _name(step: ResistanceSteps.Step) -> String:
	match step.target_kind:
		ResistanceSteps.TargetKind.DOOR:
			return "door"
		ResistanceSteps.TargetKind.PARK_SWING:
			return "swing"
		ResistanceSteps.TargetKind.STATION_DOOR:
			return "station"
	return "other"

## The director's own candidate pool, asked of the one function planning and the director share.
func _candidates(city: City, day: int) -> Array[Vector2i]:
	return ResistanceSteps.target_candidates(ResistanceSteps.narrow_target_on(day), city.map,
			city.region_plan())
