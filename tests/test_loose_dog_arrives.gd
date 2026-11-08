extends RefCounted
## **A loose dog sent from behind her arrives and runs past, or is retired out of sight.**
## *(sunny-hedgehog, 2026-09-27: "a loose dog that spawns behind me never arrives it stays offscreen
## indefinitely".)* The director sends the dog ahead of her; she may then turn round, or run. Run over
## a generated map through `EventsAhead._send_down_her_line()`, the dog sent from behind her while she
## stands, while she walks away at `Tuning.WALK_SPEED` (it closes on her at 40px/s) and while she
## runs away at `Tuning.RUN_SPEED` (it cannot). The first two must reach her and be gone; the third,
## sent from the furthest the director sites it, must be retired once it is out of sight and not
## closing, rather than run its whole route there — which is what a check on `main` fails.
##
## **The subject is the event manager and what it sends**, so it is built over a copy of the generated
## city's map and no city (`tests/fixtures/street_events.gd`): the dog's line, and the solid across it on
## seed 4242, are the streets' and the siting's own, and nothing else of a city is read.

const MapCache := preload("res://tests/city_map_cache.gd")
## The run's seed: on run seed 4242 a solid stands across the far dog's line, so it leaves its route
## there and is finished by leaving; on seed 2 the line is clear.
const RUN_SEED := 2
## The engine's clock for the walks: each physics tick carries `1 / Engine.physics_ticks_per_second
## * Engine.time_scale` seconds, so the stretch is sped up and put back after it.
const FAST_SCALE := 3.0
## How near it comes to count as having reached her, px: her body and its own.
const REACHED := 40.0
## Seconds between two forced dogs: short, so the first is sent within the walk toward it.
const FORCED_INTERVAL := 1.0
## Game seconds the walk toward the dog may take before it is sent, and the ones after the turn.
const SEND_WITHIN := 20.0
const AFTER_THE_TURN := 25.0
## Game seconds the far dog is watched for: the check is that it is retired within 7.
const RUN_AWAY_FOR := 10.0

var _events: EventManager
var _map: CityMap
var _run: RunState
var _rig: Stroller

func run(t) -> void:
	await PhysicsTicks.settle(t)
	_run = RunState.new()
	_run.start_run(RUN_SEED)
	_map = MapCache.of(4242)
	_events = StreetEvents.over(t, _map, _run)
	_rig = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	_rig.add_child(camera)
	t.add_child(_rig)
	_rig.set_physics_process(false)
	_events.use_player(_rig)
	for speed: float in [0.0, Tuning.WALK_SPEED]:
		_start_the_day(true)
		var seen := await _meet_and_turn(t, speed)
		t.check(seen["sent"],
				"the director sent a loose dog down her line, she going away at %.0fpx/s" % speed)
		if not seen["sent"]:
			continue
		t.check(seen["finished"], "a dog sent from behind her, she going away at %.0fpx/s, is over" % speed)
		t.check(seen["closest"] < REACHED, "and it reached her (%.0fpx at its nearest)" % seen["closest"])
	_start_the_day(false)
	var far := _send_from_behind_far()
	var far_run := await _run_away(t, far, Tuning.RUN_SPEED)
	t.check(not far_run["left"],
			"the dog was retired where it stood, not walked off by leaving its route first")
	t.check(far_run["over_at"] < 7.0,
			"a dog she runs away from, sent from behind the furthest out, is retired within 7s (%.1fs)"
			% far_run["over_at"])
	t.check(far_run["gap_when_over"] > Tuning.OUT_OF_SIGHT,
			"and out of sight, not on the screen (%.0fpx from her)" % far_run["gap_when_over"])
	t.check(far_run["distance_to_route_end"] > Tuning.TILE_SIZE,
			"before it ran its route out")
	_rig.free()
	_events.free()

## Starts the day over on day `RUN_TAUGHT_DAY + 2` with the director forced to owe the loose dog
## every `FORCED_INTERVAL` seconds, or with nothing forced.
func _start_the_day(forced: bool) -> void:
	_events.force("loose_dog" if forced else "", FORCED_INTERVAL if forced else 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var consumed: Array[String] = []
	_events.start_day(DaySpec.for_day(Tuning.RUN_TAUGHT_DAY + 2), rng, consumed)
	_rig.global_position = CrowdLanes.arterial_pavement(_map)
	_rig.velocity = Vector2.ZERO

## A dog placed as far out behind her (`Vector2.DOWN`, she heads up) as the director ever sites one,
## 700px, rather than just out of sight.
func _send_from_behind_far() -> EventInstance:
	var def := EventCatalogue.by_id("loose_dog")
	var her := _rig.global_position
	var place := her + Vector2.DOWN * 700.0
	var path := PendingWarning.route_down_her_line(null, place, her, Vector2.DOWN)
	var made := _events.spawner.spawn(def, path[0], path)
	made.resume(EventSpawner.age_when_warned(def), 0.0)
	return made

## Lets real physics ticks pass, one a frame, with her walking down the street by hand (the rig's
## own physics is off) until the director sends a loose dog down her line, ahead of her; then she
## turns round and goes up at `speed`. The manager sends and steps the dog on its own ticks. Answers
## the dog and how near it came to her.
func _meet_and_turn(t, speed: float) -> Dictionary:
	var step := 1.0 / Engine.physics_ticks_per_second * FAST_SCALE
	var seen := {"dog": null, "sent": false, "closest": INF, "finished": false}
	var before := _events.instances().duplicate()
	var each := func(_n: int) -> void:
		if not seen["sent"]:
			_rig.velocity = Vector2.DOWN * Tuning.WALK_SPEED
			_rig.global_position += _rig.velocity * step
			for instance in _events.instances():
				if instance.def.id == "loose_dog" and not before.has(instance):
					seen["dog"] = instance
					seen["sent"] = true
			return
		_rig.velocity = Vector2.UP * speed
		_rig.global_position += _rig.velocity * step
		if seen["finished"]:
			return
		var dog: EventInstance = seen["dog"]
		if not is_instance_valid(dog) or dog.is_finished:
			seen["finished"] = true
			return
		seen["closest"] = minf(seen["closest"], dog.global_position.distance_to(_rig.global_position))
	var second := PhysicsTicks.ticks_for(1.0, FAST_SCALE)
	var waited := 0
	while not seen["sent"] and waited < int(SEND_WITHIN):
		await PhysicsTicks.pass_ticks(t, second, each, FAST_SCALE)
		waited += 1
	waited = 0
	while seen["sent"] and not seen["finished"] and waited < int(AFTER_THE_TURN):
		await PhysicsTicks.pass_ticks(t, second, each, FAST_SCALE)
		waited += 1
	return seen

## Lets real physics ticks pass with her running up at `speed`; when `dog` is over, when and how far
## from her. The manager steps the dog in its own ticks.
func _run_away(t, dog: EventInstance, speed: float) -> Dictionary:
	var route_end := dog.path[dog.path.size() - 1]
	var step := 1.0 / Engine.physics_ticks_per_second * FAST_SCALE
	var seen := {"over_at": INF, "gap": INF, "from_end": INF, "dog": dog, "left": false}
	var each := func(n: int) -> void:
		if seen["over_at"] != INF:
			return
		_rig.velocity = Vector2.UP * speed
		_rig.global_position += _rig.velocity * step
		var the_dog: EventInstance = seen["dog"]
		if is_instance_valid(the_dog) and the_dog.is_leaving:
			seen["left"] = true
		if not is_instance_valid(the_dog) or the_dog.is_finished:
			seen["over_at"] = (n - 1) * step
			return
		seen["gap"] = the_dog.global_position.distance_to(_rig.global_position)
		seen["from_end"] = the_dog.global_position.distance_to(route_end)
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(RUN_AWAY_FOR, FAST_SCALE), each, FAST_SCALE)
	return {"over_at": seen["over_at"], "gap_when_over": seen["gap"],
			"distance_to_route_end": seen["from_end"], "left": seen["left"]}
