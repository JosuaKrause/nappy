extends RefCounted
## Printing rig for "every solid body diverts the crowd, as far as avoiding it": how much of a real
## day's ground the solid bodies take, how much of the crowd is stepping round one, how often anybody
## ends up standing inside one, and — the number worth watching — what the record costs the traffic.
## Not a suite: it prints and asserts nothing, so it lives under `tests/probes/`, where the runner
## never discovers it, and runs only by name:
##
##     tools/test.sh probes/m110_bodies.gd
##
## Each day is walked twice, once with `CityMap.obstructed_tiles` as the day filled it and once with
## the record emptied, so the **stopped-car share** is read as a difference rather than as a level. A
## body in a car's lane turns it at the last junction, and a turn that never fits is a car that parks
## itself and takes the street behind it with it — that is the failure this number is watching for.
## `tests/test_crowd_bodies.gd` holds the occupancy as an assertion; this is where the numbers behind
## `Tuning.WALKER_BODY_SIDESTEP_TILES` are taken again.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0
const SEEDS := [4242, 24757, 91117]
const DAYS := [1, 5, 9]
const SECONDS := 30.0

func run(t) -> void:
	for city_seed: int in SEEDS:
		var map := CityGenerator.generate(city_seed)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for day: int in DAYS:
			_one_day(city, map, city_seed, day)
		city.free()
	t.check(true, "probe finished")

func _one_day(city: City, map: CityMap, city_seed: int, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	var closures := RandomNumberGenerator.new()
	closures.seed = hash("m110-closures:%d:%d" % [city_seed, day])
	city.start_day(state, day, closures)
	var events := RandomNumberGenerator.new()
	events.seed = hash("m110-events:%d:%d" % [city_seed, day])
	var consumed: Array[String] = []
	city.events.start_day(day, events, consumed)

	var tiles := map.obstructed_tiles.size()
	var kept := map.obstructed_tiles.duplicate()
	var with_bodies := _walk(city, map, city_seed, day)
	# The same day with nothing recorded, for the traffic's own baseline. The bodies are still drawn
	# and still solid to the player; only the crowd's copy of where they are goes away.
	map.obstructed_tiles.clear()
	var without := _walk(city, map, city_seed, day)
	map.obstructed_tiles.clear()
	map.obstructed_tiles.merge(kept)

	print("seed %d day %d: %d tiles under a body | inside: %d walker-frames, %d car-frames | "
			% [city_seed, day, tiles, with_bodies["inside_walkers"], with_bodies["inside_cars"]]
			+ "sidestepping %.1f%% of walker-frames | stopped cars %.1f%% against %.1f%% with "
			% [with_bodies["sidestepping"], with_bodies["stopped"], without["stopped"]]
			+ "nothing recorded")

## Thirty seconds of the day's own crowd around the doorstep, as percentages of the frames each
## kind was alive for.
func _walk(city: City, map: CityMap, city_seed: int, day: int) -> Dictionary:
	var at := map.doorstep_world_position()
	var crowd_rng := RandomNumberGenerator.new()
	crowd_rng.seed = hash("m110-crowd:%d:%d" % [city_seed, day])
	city.crowd.start_day(day, crowd_rng, at)
	city.crowd.set_gates(city.region_plan().gates)

	var inside_walkers := 0
	var inside_cars := 0
	var sidestepping := 0
	var walker_frames := 0
	var car_frames := 0
	var stopped := 0
	for frame in int(round(SECONDS / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent in city.crowd.agents():
			var caught := map.is_obstructed(map.world_to_tile(agent.position))
			if agent.kind == CrowdAgent.Kind.WALKER:
				walker_frames += 1
				inside_walkers += 1 if caught else 0
				sidestepping += 1 if agent._body_detour_held else 0
			else:
				car_frames += 1
				inside_cars += 1 if caught else 0
				stopped += 1 if agent.speed() < Tuning.CAR_STOPPED_SPEED else 0
	return {
		"inside_walkers": inside_walkers,
		"inside_cars": inside_cars,
		"sidestepping": 100.0 * float(sidestepping) / float(maxi(1, walker_frames)),
		"stopped": 100.0 * float(stopped) / float(maxi(1, car_frames)),
	}
