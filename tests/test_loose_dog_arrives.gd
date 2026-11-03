extends RefCounted
## **A loose dog sent from behind her arrives and runs past, or is retired out of sight.**
## *(sunny-hedgehog, 2026-09-27: "a loose dog that spawns behind me never arrives it stays offscreen
## indefinitely".)* The director sends the dog ahead of her; she may then turn round, or run. Run on
## a real city through `EventsAhead._send_down_her_line()`, the dog sent from behind her while she
## stands, while she walks away at `Tuning.WALK_SPEED` (it closes on her at 40px/s) and while she
## runs away at `Tuning.RUN_SPEED` (it cannot). The first two must reach her and be gone; the third,
## sent from the furthest the director sites it, must be retired once it is out of sight and not
## closing, rather than run its whole route there — which is what a check on `main` fails.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The engine's clock for the walks: each physics frame carries `1 / Engine.physics_ticks_per_second
## * Engine.time_scale` seconds, so the stretch is sped up and put back after it.
const FAST_SCALE := 3.0
## How near it comes to count as having reached her, px: her body and its own.
const REACHED := 40.0

var _city: City
var _rig: Stroller

func run(t) -> void:
	_city = RunCity.of_the_run(CITY_SCENE)
	t.add_child(_city)
	_city.build(CityGenerator.generate(4242))
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var consumed: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_city.events.start_day(DaySpec.for_day(Tuning.RUN_TAUGHT_DAY + 2), rng, consumed)
	_rig = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	_rig.add_child(camera)
	t.add_child(_rig)
	_rig.set_physics_process(false)
	_city.events.use_player(_rig)
	for speed: float in [0.0, Tuning.WALK_SPEED]:
		var dog := _send_from_behind(false)
		var seen := await _run(dog, speed, 25.0)
		t.check(dog.is_finished, "a dog sent from behind her, she going away at %.0fpx/s, is over" % speed)
		t.check(seen["closest"] < REACHED, "and it reached her (%.0fpx at its nearest)" % seen["closest"])
	var far := _send_from_behind(true)
	var route_end := far.path[far.path.size() - 1]
	var far_run := await _run(far, Tuning.RUN_SPEED, 25.0)
	t.check(far.is_finished and far_run["over_at"] < 7.0,
			"a dog she runs away from, sent from behind the furthest out, is retired within 7s (%.1fs)"
			% far_run["over_at"])
	t.check(far_run["gap_when_over"] > Tuning.OUT_OF_SIGHT,
			"and out of sight, not on the screen (%.0fpx from her)" % far_run["gap_when_over"])
	t.check(far.global_position.distance_to(route_end) > Tuning.TILE_SIZE,
			"before it ran its route out")
	_rig.free()
	_city.free()

## The dog sent down her line from behind (`Vector2.DOWN`, she heads up); `far` places it as far out
## as the director ever sites one, 700px, rather than just out of sight.
func _send_from_behind(far: bool) -> EventInstance:
	var def := EventCatalogue.by_id("loose_dog")
	var her := CrowdLanes.arterial_pavement(_city.map)
	_rig.global_position = her
	_rig.velocity = Vector2.ZERO
	var before := _city.events.instances().duplicate()
	if far:
		var place := her + Vector2.DOWN * 700.0
		var path := PendingWarning.route_down_her_line(null, place, her, Vector2.DOWN)
		var made := _city.events.spawner.spawn(def, path[0], path)
		made.resume(EventSpawner.age_when_warned(def), 0.0)
		return made
	_city.events.ahead._send_down_her_line(def, her, Vector2.DOWN)
	for instance in _city.events.instances():
		if instance.def.id == "loose_dog" and not before.has(instance):
			return instance
	return null

## Lets real physics frames pass for `seconds` of the game's clock with her walking up at `speed`;
## when the dog is over, when and how far from her, and how near it came. The manager steps the dog
## in its own physics frames, and her walk is carried by hand since the rig's own physics is off.
func _run(dog: EventInstance, speed: float, seconds: float) -> Dictionary:
	var closest := INF
	var over_at := INF
	var gap := INF
	var step := 1.0 / Engine.physics_ticks_per_second * FAST_SCALE
	var clock := Engine.time_scale
	Engine.time_scale = FAST_SCALE
	for i in int(seconds / step):
		_rig.velocity = Vector2.UP * speed
		_rig.global_position += _rig.velocity * step
		await _rig.get_tree().physics_frame
		if dog.is_finished:
			over_at = i * step
			break
		gap = dog.global_position.distance_to(_rig.global_position)
		closest = minf(closest, gap)
	Engine.time_scale = clock
	return {"closest": closest, "over_at": over_at, "gap_when_over": gap}
