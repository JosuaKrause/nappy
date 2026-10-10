extends RefCounted
## Measurement probe for calm-pelican, "walls inside the building stop excitement too": what the debug
## view's fields layer costs now that it cuts each outline where a wall stops the field
## (`DebugLayers.field_runs()`). Prints numbers, asserts nothing, so it lives under `tests/probes/`
## and runs only by name:
##
##     tools/test.sh probes/calm_pelican_fields_layer_cost.gd
##
## Two seeds, day 1, the events the day streams in at its start and the crowd started round her
## doorstep and stepped two seconds; `--all-events` as a user argument streams every event of the
## day in instead (`stream_radius = INF`), far more than a real frame has. Timed: the outlines the layer built
## before it cut anything (every emitter, everywhere, closed); `field_runs()` over the whole map,
## cold and again; one screen (640x360, the camera at zoom 2) round her doorstep, cold and again; and
## one screen round each live event, cold. "Again" is a second call with nothing moved, so a standing
## source's cut is reused. Headless, so drawing itself is not in any figure.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SCREEN := Vector2(640.0, 360.0)

func run(t) -> void:
	for city_seed in [4242, 5551212]:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		var day := 1
		var state := CityState.new()
		state.begin_day(city.map.block_plans, day)
		var closures_rng := RandomNumberGenerator.new()
		closures_rng.seed = 1
		city.start_day(state, day, closures_rng)
		if "--all-events" in OS.get_cmdline_user_args():
			city.events.stream_radius = INF
		var consumed: Array[String] = []
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = 2
		city.events.start_day(day, events_rng, consumed)
		var home := city.map.doorstep_world_position()
		var crowd_rng := RandomNumberGenerator.new()
		crowd_rng.seed = 3
		city.crowd.start_day(day, crowd_rng, home)
		for i in 120:
			city.crowd.step(1.0 / 60.0)
		var scene: PackedScene = load("res://scenes/player/stroller.tscn")
		var stroller: Stroller = scene.instantiate()
		t.add_child(stroller)
		stroller.set_physics_process(false)
		var layers := DebugLayers.new()
		layers.setup(city.events, city.crowd, city, stroller)
		print("FIELDS seed %d: %d events live, %d crowd" % [city_seed,
				city.events.instances().size(), city.crowd.agents().size()])

		var started := Time.get_ticks_usec()
		var built := 0
		for instance in city.events.instances():
			for level: float in [instance.def.inner_radius, instance.def.outer_radius]:
				var points := GroundShape.field_outline_at(instance.global_position,
						instance.travel_velocity(), level)
				var closed := points.duplicate()
				closed.append(points[0])
				built += 1
		for agent in city.crowd.agents():
			for level: float in [Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS]:
				var points := GroundShape.field_outline_at(agent.global_position, agent.velocity(),
						level)
				var closed := points.duplicate()
				closed.append(points[0])
				built += 1
		_report("uncut outlines everywhere, as the layer built them before", built, started)

		var everywhere := Rect2(-1e6, -1e6, 2e6, 2e6)
		var at_home := Rect2(home - SCREEN * 0.5, SCREEN)
		for view: Rect2 in [everywhere, at_home]:
			var label := "whole map" if view == everywhere else "one screen at her doorstep"
			layers._cuts = {}
			started = Time.get_ticks_usec()
			_report(label + ", cold", layers.field_runs(view).size(), started)
			started = Time.get_ticks_usec()
			_report(label + ", again", layers.field_runs(view).size(), started)

		var total := 0
		var worst := 0
		for instance in city.events.instances():
			layers._cuts = {}
			started = Time.get_ticks_usec()
			layers.field_runs(Rect2(instance.global_position - SCREEN * 0.5, SCREEN))
			var spent := Time.get_ticks_usec() - started
			total += spent
			worst = maxi(worst, spent)
		var views := maxi(city.events.instances().size(), 1)
		print("FIELDS   one screen round each of %d events, cold: mean %.1f ms, worst %.1f ms"
				% [views, float(total) / views / 1000.0, float(worst) / 1000.0])
		layers.free()
		stroller.free()
		city.free()

func _report(label: String, outlines: int, started: int) -> void:
	print("FIELDS   %s: %d outlines, %.1f ms" % [label, outlines,
			float(Time.get_ticks_usec() - started) / 1000.0])
