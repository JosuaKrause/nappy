extends RefCounted
## A crowd car kills only what is in front of it while it drives.
##
## The player's words *(2026-10-03, minty-hedgehog, statement 4: "cars should only be lethal in front
## of them while they're driving" and "when I walk behind a standing car right now and it starts
## moving I die -- that is not correct the car is driving away from me")*. The strike box runs from
## the car's centre forward (`CarStrike.hits()`, which `Crowd._strike()` asks every tick, and
## `CrowdExcitement.will_be_lethal()`), so the rear half is harmless, and a car that sets off from a
## stand has nobody behind it to strike.
##
## The box is asked as the crowd asks it, from a car's centre, heading and speed; and the day's end
## is asked of a real crowd: a stroller on the carriageway, the crowd's own physics frames passing,
## and `EventBus.hard_fail_triggered` as the signal the game listens to.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

var _rig = RIG.new()
var _fails: Array[String] = []

func run(t) -> void:
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(map)
	var street: Vector2i = _rig._a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(street.x >= 0, "this city has a straight stretch of ordinary street for a car")
	if street.x >= 0:
		EventBus.hard_fail_triggered.connect(_on_hard_fail)
		var lane: int = CrowdLanes.road_lane(true, 1.0)
		_test_the_rear_half_is_safe_and_the_front_half_is_not(t, city, map, street, lane)
		_test_a_car_pulling_away_from_a_stand_does_not_end_the_day(t)
		await _test_a_car_driving_at_her_still_does(t, city, map, street, lane)
		await _test_a_car_driving_away_from_her_does_not(t, city, map, street, lane)
		_test_a_fast_car_is_foreseen(t, city, map, street, lane)
		EventBus.hard_fail_triggered.disconnect(_on_hard_fail)
	city.free()

func _on_hard_fail(reason: String) -> void:
	_fails.append(reason)

## A car of the run's own on the carriageway of `street`, going down it at `speed`, in a crowd of
## nobody else (a day started and emptied, as the rig's other suites do).
func _a_car(city: City, map: CityMap, street: Vector2i, lane: int, speed: float) -> CrowdAgent:
	city.crowd.start_day(1, _rng(), Vector2.ZERO)
	city.crowd.clear()
	return _rig._agent_on(city, map, CrowdAgent.Kind.CAR, street.x, lane,
			float(street.y + 2) * Tuning.TILE_SIZE, 1.0, true, CrowdLanes.SIDEWALK_OFFSETS, speed)

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("car-front:%d" % SEED)
	return rng

func _test_the_rear_half_is_safe_and_the_front_half_is_not(t, city: City, map: CityMap,
		street: Vector2i, lane: int) -> void:
	var car := _a_car(city, map, street, lane, Tuning.CAR_SPEED.x)
	var forward := car.heading()
	var side := Vector2(-forward.y, forward.x)
	var at := car.global_position
	var half := Tuning.CAR_STRIKE_HALF_LENGTH
	var wide := Tuning.CAR_STRIKE_HALF_WIDTH
	var speed := car.speed()
	t.check(CarStrike.hits(at, forward, speed, at + forward * (half - 2.0)),
			"just inside its bumper is a strike")
	t.check(CarStrike.hits(at, forward, speed, at + forward * (half * 0.5) + side * (wide - 2.0)),
			"the sides of the front half are a strike")
	t.check(CarStrike.hits(at, forward, speed, at), "its centre is a strike")
	t.check(not CarStrike.hits(at, forward, speed, at - forward * 2.0),
			"just behind its centre is not")
	t.check(not CarStrike.hits(at, forward, speed, at - forward * (half - 2.0)),
			"its rear half is not")
	t.check(not CarStrike.hits(at, forward, speed, at - forward * (half * 0.5) + side * (wide - 2.0)),
			"nor the sides of its rear half")
	t.check(not CarStrike.hits(at, forward, speed, at + forward * (half + 4.0)),
			"beyond its bumper is not")
	t.check(not car.excitement.will_be_lethal(at - forward * (half - 2.0)),
			"the danger prediction agrees: no red caret behind it")
	t.check(car.excitement.will_be_lethal(at + forward * (half + 40.0)),
			"and has one for somebody it is driving at")
	t.check(CarStrike.hits(at, forward, speed, at) and not CarStrike.hits(at, forward, 0.0, at),
			"a car that has stopped cannot run anybody over")

func _test_a_car_pulling_away_from_a_stand_does_not_end_the_day(t) -> void:
	var forward := Vector2.DOWN
	var centre := Vector2(400.0, 400.0)
	var behind := centre - forward * (Tuning.CAR_STRIKE_HALF_LENGTH - 4.0)
	t.check(not CarStrike.hits(centre, forward, 0.0, behind),
			"standing, it strikes nobody behind it")
	var speed := Tuning.CAR_STRIKE_MIN_SPEED + 40.0
	var struck := false
	for i in 120:
		centre += forward * speed * STEP
		struck = struck or CarStrike.hits(centre, forward, speed, behind)
	t.check(not struck, "a car that sets off away from her standing just behind it never strikes her")

## A stroller on the carriageway `gap` px ahead of `car`, the crowd's own physics frames passing for
## `seconds`, reports whether the day ended in that time.
func _the_day_ends_with_her_ahead(city: City, car: CrowdAgent, gap: float, seconds: float) -> bool:
	var her := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	her.add_child(camera)
	city.add_child(her)
	her.set_physics_process(false)
	her.global_position = car.global_position + car.heading() * gap
	city.crowd.use_player(her)
	_fails.clear()
	for frame in int(round(seconds / STEP)):
		city.crowd.set_focus(car.global_position)
		await city.get_tree().physics_frame
	city.crowd.use_player(null)
	her.free()
	return _fails.has("car_strike")

func _test_a_car_driving_at_her_still_does(t, city: City, map: CityMap, street: Vector2i,
		lane: int) -> void:
	var car := _a_car(city, map, street, lane, Tuning.CAR_SPEED.x)
	var ended: bool = await _the_day_ends_with_her_ahead(city, car, 120.0, 2.0)
	t.check(ended, "a car driving at her still ends the day")

func _test_a_car_driving_away_from_her_does_not(t, city: City, map: CityMap, street: Vector2i,
		lane: int) -> void:
	var car := _a_car(city, map, street, lane, Tuning.CAR_SPEED.x)
	var ended: bool = await _the_day_ends_with_her_ahead(city, car, -(Tuning.CAR_STRIKE_HALF_LENGTH - 4.0), 2.0)
	t.check(not ended, "a car driving away from her, who stands just behind it, never ends the day")

func _test_a_fast_car_is_foreseen(t, city: City, map: CityMap, street: Vector2i,
		lane: int) -> void:
	# At the top speed the car covers 46px per 0.25s sample, more than the 26px strike box, so a
	# sampled prediction can step over her; the closed form cannot.
	var top := Tuning.CAR_SPEED.y
	var car := _a_car(city, map, street, lane, top)
	var forward := car.heading()
	var ahead := 100.0 + Tuning.CAR_STRIKE_HALF_LENGTH
	t.check(car.excitement.will_be_lethal(car.global_position + forward * ahead),
			"a car at top speed is foreseen to strike her 126px ahead, between two samples")
	var beyond := top * Tuning.EXPECTED_IMPACT_HORIZON + Tuning.CAR_STRIKE_HALF_LENGTH + 40.0
	t.check(not car.excitement.will_be_lethal(car.global_position + forward * beyond),
			"and not one beyond the horizon")
