extends RefCounted
## Uncommitted: per-kind cost of the agents' own frames, day 1 and 14, seed 4242, street walk.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0

func run(t) -> void:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.set_process(false)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	for day in [1, 14]:
		var state := CityState.new()
		state.begin_day(city.map.block_plans, day)
		var closures := RandomNumberGenerator.new()
		closures.seed = hash("crowd-tick-cost-closures:%d:%d" % [4242, day])
		city.start_day(state, day, closures)
		var crowd := city.crowd
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("crowd-tick-cost:%d:%d" % [4242, day])
		var here := city.map.doorstep_world_position()
		crowd.start_day(day, rng, here)
		crowd.set_gates(city.region_plan().gates)
		crowd._player = rig
		var walkers_us := 0
		var cars_us := 0
		var vel_us := 0
		var nw := 0
		var nc := 0
		for tick in 750:
			var going := Vector2.DOWN if tick < 90 else (Vector2.RIGHT if (tick - 90) / 60 % 2 == 0 else Vector2.LEFT)
			rig.global_position = here
			rig.velocity = going * Tuning.WALK_SPEED
			here += going * Tuning.WALK_SPEED * STEP
			for agent in crowd.agents():
				var a := Time.get_ticks_usec()
				agent._process(STEP)
				var b := Time.get_ticks_usec()
				if tick >= 150:
					if agent.kind == CrowdAgent.Kind.CAR:
						cars_us += b - a
						nc += 1
					else:
						walkers_us += b - a
						nw += 1
			var v0 := Time.get_ticks_usec()
			for agent in crowd.agents():
				agent.velocity()
				agent.heading()
			if tick >= 150:
				vel_us += Time.get_ticks_usec() - v0
			crowd._physics_process(STEP)
		print("KIND_PROFILE day %d walker %.2f us/frame car %.2f us/frame velocity+heading %.2f us/agent" % [
			day, float(walkers_us) / maxi(nw, 1), float(cars_us) / maxi(nc, 1),
			float(vel_us) / (600.0 * crowd.agents().size())])
	city.crowd._player = null
	city.free()
	rig.free()
	t.check(true, "ran")
