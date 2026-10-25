extends RefCounted
## A car's frame is proposed, checked and then committed (`CarDriving`): what the frame decides on
## the pose it would end on — parking at the end of its route, leaving off the end of it — holds
## only once that pose is the one it keeps. A step the check takes back takes back what was decided
## on it (likely-bugs.md, the car's taken-back frame).
##
## The fire engine is the rig, stepped a frame at a time and told where she and her pram are the
## way `EventManager` tells it, as `tests/test_fire_truck_body.gd` does.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_last_step_taken_back_does_not_park_it_short(t)
	_test_a_car_comes_back_standing(t)

func _engine(t, route: PackedVector2Array) -> EventInstance:
	var def := EventCatalogue.by_id("fire_truck")
	var engine := EventInstance.new()
	engine.setup(def, route[0], route, (route[1] - route[0]).normalized(), null)
	engine.resume(def.telegraph_time, 0.0)
	t.add_child(engine)
	engine.set_process(false)
	return engine

func _step(engine: EventInstance, her: Vector2, facing: Vector2) -> void:
	engine.player_at = her
	engine.pram_at = her + facing * Tuning.PLAYER_BODY_RADIUS
	engine._process(STEP)

## **She stands just past its kerb, so the step that would end its route is the one taken back.**
## Parked there, it would be parked short of its kerb, for good: a parked engine never drives on.
## Taken back with its step, it stands for her, and once she has gone it drives the rest of the way
## and parks at its kerb.
func _test_a_last_step_taken_back_does_not_park_it_short(t) -> void:
	var route := PackedVector2Array([Vector2(-300.0, 0.0), Vector2.ZERO])
	var length := route[0].distance_to(route[1])
	var refused_at_the_end := 0
	var parked_short := 0
	var past := 42.0
	while past <= 44.0:
		var engine := _engine(t, route)
		var her := Vector2(past, 0.0)
		for i in int(3.0 / STEP):
			_step(engine, her, Vector2.RIGHT)
			if engine.is_parked or (engine.car.is_standing() and engine.path_travelled() > length - 4.0):
				break
		if engine.car.is_standing() or engine.is_parked and engine.path_travelled() < length - 0.001:
			refused_at_the_end += 1
		if engine.is_parked and engine.path_travelled() < length - 0.001:
			parked_short += 1
		# She walks away; it drives the rest of the way, if it has any left, and parks.
		for i in int(2.0 / STEP):
			_step(engine, Vector2(600.0, 600.0), Vector2.RIGHT)
		t.check(engine.is_parked and engine.global_position.distance_to(route[1]) < 0.01,
				"%.1fpx past its kerb, once she has gone it is parked at its kerb (%.2fpx off it, "
				% [past, engine.global_position.distance_to(route[1])]
				+ "%.1f of %.1fpx driven)" % [engine.path_travelled(), length])
		engine.free()
		past += 0.1
	t.check(refused_at_the_end > 0,
			"the rig reaches a step taken back at the end of its route (%d placements)"
			% refused_at_the_end)
	t.check(parked_short == 0, "no step taken back at its kerb parks it short (%d did)" % parked_short)

## **A car carries nothing across a stream-out** (`EventCarDriving.save()`): whether it stands is
## decided again every frame, and a car streamed back in stands as one first made does, driving off
## only once she is out of its way.
func _test_a_car_comes_back_standing(t) -> void:
	var route := PackedVector2Array([Vector2(-300.0, 0.0), Vector2.ZERO])
	var engine := _engine(t, route)
	for i in int(0.5 / STEP):
		_step(engine, Vector2(600.0, 600.0), Vector2.RIGHT)
	t.check(not engine.car.is_standing() and engine.car.is_driving(), "the engine is driving its route")
	var state := engine.save_behaviours()
	t.check(not state.has(&"EventCarDriving"), "and its driving saves nothing")
	var back := _engine(t, route)
	back.resume(engine.age, engine.path_travelled(), engine.noticed_at())
	back.restore_behaviours(state)
	t.check(back.car.is_standing() and back.global_position.is_equal_approx(engine.global_position),
			"streamed back in, it stands where it had got to")
	engine.free()
	back.free()
