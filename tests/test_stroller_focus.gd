extends RefCounted
## The game's focus source for the crowd (`StrollerFocus`): it answers where she stands, and a crowd
## handed it centres its patch of simulated streets on her. The crowd is a real one on a real
## generated map with no city around it (`tests/crowd_street_rig.gd`), since what is checked is the
## wiring between the source and the crowd's tick: that the patch follows her as she moves.

const Rig := preload("res://tests/crowd_street_rig.gd")
## The seed of the map the crowd is built on.
const MAP_SEED := 1917501

var _rig := Rig.new()

func run(t: TestRunner) -> void:
	var map := CityGenerator.generate(MAP_SEED)
	var her := Stroller.new()
	# The name matters: Stroller's @onready looks the camera up by path.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	t.add_child(her)
	her.set_physics_process(false)
	var focus := StrollerFocus.new(her)
	her.global_position = map.doorstep_world_position()
	t.check(focus.where() == her.global_position, "the source answers where she stands")
	her.global_position = map.world_size() * 0.25
	t.check(focus.where() == her.global_position, "and where she stands after she has walked on")

	var crowd := _rig.a_crowd(t, map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	crowd.start_day(1, rng, map.doorstep_world_position())
	crowd.use_focus(focus)
	var reach := CrowdField.new(map, her.global_position).half_extent() \
			+ CrowdAgent.ENTRY_SPREAD + Tuning.TILE_SIZE
	for frame in 3:
		crowd.step(1.0 / 30.0)
	var all_round := not crowd.agents().is_empty()
	for agent in crowd.agents():
		var gap := agent.global_position - her.global_position
		all_round = all_round and maxf(absf(gap.x), absf(gap.y)) <= reach
	t.check(all_round, "a crowd handed it is simulated around her, wherever the day was started")
	_rig.free_crowd(crowd)
	her.free()
