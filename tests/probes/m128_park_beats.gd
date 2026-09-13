extends RefCounted
## What `playground` and `busker` actually cost on real, generated parks, printed rather than
## asserted. Not a suite: it lives under `tests/probes/`, where the runner never discovers it,
## and runs only by name:
##
##     tools/test.sh probes/m128_park_beats.gd
##
## M128 asked for two things the cost table alone cannot answer: whether a one-block park with a
## playground in it has anywhere to settle, and how far a busker's field actually reaches onto
## the street beside its lot. Both are geometric questions about a real city rather than about
## `Tuning` in isolation, so this builds real maps with `CityGenerator` and real days rather than
## reasoning about the numbers on paper.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 90210, 1337]

func run(t) -> void:
	_playground_settles(t)
	t.check(true, "m128 park-beats probe ran")

# -------------------------------------------------------------------------- the playground ---

## Every playground this city has, standing exactly at its own centre — where `_place_ambient`
## puts the ambient source, and so the worst point in the park for it. `_walk_until_asleep` is
## `tests/test_balance.gd`'s own rig, duplicated here rather than shared because a probe under
## `tests/probes/` is not discovered by anything that could import it as a dependency.
func _playground_settles(t) -> void:
	print("\n== a one-block park with a playground in it: can she settle at its own centre? ==")
	var step := 1.0 / 60.0
	for city_seed in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		var consumed: Array[String] = []
		city.events.start_day(1, _rng(city_seed), consumed)
		for rect in city.map.playgrounds:
			var at: Vector2 = city.map.tile_rect_to_world(rect).get_center()
			city.events.stream_around(at)
			city.crowd.start_day(1, _rng(city_seed), at)
			var stroller := Stroller.new()
			var camera := Camera2D.new()
			camera.name = "Camera2D"
			stroller.add_child(camera)
			t.add_child(stroller)
			stroller.set_physics_process(false)
			stroller.global_position = at
			stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
			var baby := Baby.new()
			stroller.add_child(baby)
			baby.set_physics_process(false)

			var settled := -1.0
			var duration := Tuning.day_length(1)
			for i in int(round(duration / step)):
				city.crowd.step(step)
				for instance in city.events.instances():
					if not instance.is_finished:
						instance._process(step)
				baby._physics_process(step)
				if baby.state == GameEnums.BabyState.ASLEEP:
					settled = i * step
					break
			print("  seed %-8d settled: %s" % [city_seed,
					("%.0fs" % settled) if settled > 0.0 else "never"])
			stroller.free()
		city.free()

func _rng(city_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m128:%d" % city_seed)
	return rng
