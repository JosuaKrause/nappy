extends RefCounted
## A spine whose lights are out still carries its traffic: right before left and "nothing enters a box
## it cannot leave" hold a five-times-busier street together without a light.
##
## **Why this builds a real `City`, and a crowd in it**: the promise is a measurement between the
## signals and the crowd's own junction rule, over the cars the crowd simulates on the spine, and it
## has to come from a city the generator can produce (writing-tests, "Which map a test uses"): the
## street network the lanes run on exists only there. So the crowd and the signals are real and the
## city is the generated one of seed 4242, from the cache (`tests/city_map_cache.gd`). The lights
## are put out by the one flag the blackout sets (`TrafficSignals.powered`); that the blackout does
## so is `tests/test_blackout.gd`'s. This case belongs in the crowd's suites once their conversion
## reaches them; `tests/crowd_rig.gd`, which they run from, is not this change's.
##
## Stated against the lit spine on the same day rather than as a speed, since what is being asked is
## that the dark one is no car park by comparison. The day starts no events: a protest the day's
## draw stands on the spine's crossings stops its cars lit or dark, which is the density's question,
## not the lights'.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City
## How many car samples the last `_spine_traffic()` took.
var _sampled_cars := 0

func run(t: TestRunner) -> void:
	await _test_the_dark_spine_keeps_moving(t)

func _rng(label: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dark spine:%d:%s" % [SEED, label])
	return rng

func _test_the_dark_spine_keeps_moving(t: TestRunner) -> void:
	_city = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(_city)
	_city.build(MapCache.of(SEED))
	# Day 14's city as the game starts it, then the crowd on its streets: a quiet day, with no
	# events started, so no row the day's draw puts on the spine's crossings can jam it. What is
	# measured is the lights, not the day's density.
	var day := Tuning.RUN_LENGTH_DAYS
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng("closures"))
	var lit: Vector2 = await _spine_traffic(t)
	var lit_samples := _sampled_cars
	_city.signals.powered = false
	var dark: Vector2 = await _spine_traffic(t)
	_sampled_cars = mini(_sampled_cars, lit_samples)
	print("[test_dark_spine] spine traffic over 40s, lit: mean %.0f px/s, %.0f%% stopped; "
			% [lit.x, lit.y * 100.0] + "dark: mean %.0f px/s, %.0f%% stopped"
			% [dark.x, dark.y * 100.0])
	t.check(_sampled_cars > 0, "there were cars on the spine to sample (%d samples)" % _sampled_cars)
	t.check(dark.x >= lit.x * 0.8,
			"the dark spine carries its traffic about as fast as the lit one (%.0f vs %.0f px/s)"
			% [dark.x, lit.x])
	t.check(dark.y < 0.5, "and most of it is moving at any instant (%.0f%% stopped)"
			% (dark.y * 100.0))
	_city.free()
	_city = null

## Mean speed and stopped share of the cars on the spine, sampled every half second over forty
## seconds of the crowd's own physics ticks, with a stroller standing on the sidewalk beside the
## spine for the crowd to make way for, so the field is over the spine and the cars there are the
## ones being simulated. The spine is lit or dark as the city has it.
func _spine_traffic(t: TestRunner) -> Vector2:
	_city.crowd.start_day(Tuning.RUN_LENGTH_DAYS, _rng("traffic"))
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	_city.add_child(her)
	her.set_physics_process(false)
	her.global_position = _sidewalk_beside_the_spine()
	_city.crowd.use_player(her)
	var totals := {"speed": 0.0, "stopped": 0, "samples": 0}
	var sample := func(ticks: int) -> bool:
		if ticks % 30 != 0:
			return false
		for agent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR or not agent.travelling_vertically() \
					or not _city.map.is_main_road(true, CrowdLanes.corridor_at(agent.position.x)):
				continue
			totals.samples += 1
			totals.speed += agent.speed()
			if agent.speed() < Tuning.CAR_STOPPED_SPEED:
				totals.stopped += 1
		return false
	await PhysicsTicks.pass_ticks_faster(t, PhysicsTicks.ticks_for(40.0, 1.0), PhysicsTicks.FASTER, sample)
	_city.crowd.use_player(null)
	her.free()
	_sampled_cars = totals.samples
	return Vector2(totals.speed / maxf(1.0, totals.samples),
			float(totals.stopped) / maxf(1.0, totals.samples))

## A sidewalk tile beside the spine at the map's middle height, where a body stands off the
## carriageway the cars drive on.
func _sidewalk_beside_the_spine() -> Vector2:
	var row := _city.map.size.y / 2
	for x in range(_city.map.main_road * CityMap.period(),
			_city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH + 1):
		var tile := Vector2i(x, row)
		if _city.map.tile_at(tile) == GameEnums.TileType.SIDEWALK:
			return _city.map.tile_to_world(tile)
	return _city.map.tile_to_world(Vector2i(_city.map.main_road * CityMap.period(), row))
