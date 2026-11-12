extends RefCounted
## A city overview retains ordinary crowd density and real traffic in every quadrant,
## while the normal player-following field keeps its population and movement behavior.
##
## A crowd on a real generated map with **no city around it**: `Crowd.setup()` is handed a bare world, the map
## and its lights, as a task scene's rig hands it (`tests/crowd_street_rig.gd`'s `a_crowd()`), so this suite
## tests the crowd.

const Rig := preload("res://tests/crowd_street_rig.gd")
## The seed of the map the crowd is built on.
const MAP_SEED := 1917501

var _rig := Rig.new()

func run(t: TestRunner) -> void:
	var map := CityGenerator.generate(MAP_SEED)
	var crowd := _rig.a_crowd(t, map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var focus := map.doorstep_world_position()
	crowd.start_day(1, rng, focus, true, true)
	var field := crowd.field()
	var middle := map.world_size() * 0.5
	var bounds_x := field.along_bounds(false)
	var bounds_y := field.along_bounds(true)
	crowd.set_focus(Vector2.ZERO)
	field.centre = map.world_size()
	t.check(field.centre == middle and field.along_bounds(false) == bounds_x
			and field.along_bounds(true) == bounds_y, "city crowd bounds stay fixed as the player moves")
	t.check(bounds_x == Vector2(0, map.world_size().x)
			and bounds_y == Vector2(0, map.world_size().y), "city crowd field covers the entire map")
	var area_scale := map.world_size().x * map.world_size().y \
			/ pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0)
	var initial := crowd.recipe_coverage()
	t.check(initial.walkers == roundi(Tuning.crowd_pedestrians(1) * area_scale)
			and initial.cars == roundi(Tuning.crowd_cars(1) * area_scale),
			"city crowd preserves the existing population per covered field area")
	var positions := {}
	for agent in crowd.agents():
		positions[agent] = agent.global_position
	for frame in 90:
		crowd.step(1.0 / 30.0)
	var measured := {"nw": {"moving": 0, "moving_cars": 0}, "ne": {"moving": 0, "moving_cars": 0},
			"sw": {"moving": 0, "moving_cars": 0}, "se": {"moving": 0, "moving_cars": 0}}
	for agent in crowd.agents():
		var at := agent.global_position
		var moved: float = at.distance_to(positions[agent])
		# Recycling is not evidence of motion. Only a plausible physical displacement
		# during the three-second window contributes to the measured coverage.
		if moved <= 1.0 or moved > Tuning.CAR_SPEED.y * 3.0:
			continue
		var quadrant := ("n" if at.y < middle.y else "s") + ("w" if at.x < middle.x else "e")
		measured[quadrant].moving += 1
		if agent.kind == CrowdAgent.Kind.CAR:
			measured[quadrant].moving_cars += 1
	var coverage := crowd.recipe_coverage()
	for quadrant: String in coverage.quadrants:
		var counts: Dictionary = coverage.quadrants[quadrant]
		t.check(counts.walkers > 0 and counts.cars > 0,
				"%s contains both pedestrians and cars across the city view" % quadrant)
		t.check(counts.moving > 0 and counts.moving_cars > 0,
				"%s reports effective movement including traffic" % quadrant)
		t.check(measured[quadrant].moving > 0 and measured[quadrant].moving_cars > 0,
				"%s actors and cars physically move under production signals and queue updates" % quadrant)
	print("RECIPE_CROWD_COVERAGE ", JSON.stringify(coverage), " displacement ", JSON.stringify(measured))
	crowd.start_day(1, rng, focus)
	t.check(not field.city_view and field.centre == focus,
			"a normal day restores the moving field after a city-view recipe")
	t.check(crowd.agent_count() == Tuning.crowd_pedestrians(1) + Tuning.crowd_cars(1),
			"normal population is unchanged by the optional city view")
	crowd.set_focus(middle)
	t.check(field.centre == middle, "normal field follows focus again")
	crowd.start_day(1, rng, focus, false, true)
	t.check(crowd.agent_count() == 0, "city-view extent does not enable unrequested population")
	_rig.free_crowd(crowd)
