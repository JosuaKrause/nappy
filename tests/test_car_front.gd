extends RefCounted
## A crowd car kills only what is in front of it while it drives.
##
## The player's words *(2026-10-03, minty-hedgehog, statement 4: "cars should only be lethal in front
## of them while they're driving" and "when I walk behind a standing car right now and it starts
## moving I die -- that is not correct the car is driving away from me")*. The strike box runs from
## the car's centre forward (`Crowd._strike()`, `CrowdAgent.will_be_lethal()`), so the rear half is
## harmless, and a car that sets off from a stand has nobody behind it to strike.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City

func run(t) -> void:
	_city = RunCity.of_the_run(CITY_SCENE)
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_city.crowd.start_day(1, _rng())
	var car: CrowdAgent = null
	for agent: CrowdAgent in _city.crowd.agents():
		if agent.kind == CrowdAgent.Kind.CAR:
			car = agent
			break
	t.check(car != null, "there is a car on the street")
	if car:
		_test_the_rear_half_is_safe_and_the_front_half_is_not(t, car)
		_test_a_car_pulling_away_from_a_stand_does_not_end_the_day(t, car)
		_test_a_car_driving_at_her_still_does(t, car)
		_test_a_fast_car_is_foreseen(t, car)
	_city.free()

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("car-front:%d" % SEED)
	return rng

func _strike(car: CrowdAgent, at: Vector2) -> bool:
	_city.crowd._struck = false
	return _city.crowd._strike(car, at)

func _test_the_rear_half_is_safe_and_the_front_half_is_not(t, car: CrowdAgent) -> void:
	car._speed = 60.0
	var forward := car.heading()
	var side := Vector2(-forward.y, forward.x)
	var at := car.global_position
	var half := Tuning.CAR_STRIKE_HALF_LENGTH
	var wide := Tuning.CAR_STRIKE_HALF_WIDTH
	t.check(_strike(car, at + forward * (half - 2.0)), "just inside its bumper is a strike")
	t.check(_strike(car, at + forward * (half * 0.5) + side * (wide - 2.0)),
			"the sides of the front half are a strike")
	t.check(_strike(car, at), "its centre is a strike")
	t.check(not _strike(car, at - forward * 2.0), "just behind its centre is not")
	t.check(not _strike(car, at - forward * (half - 2.0)), "its rear half is not")
	t.check(not _strike(car, at - forward * (half * 0.5) + side * (wide - 2.0)),
			"nor the sides of its rear half")
	t.check(not _strike(car, at + forward * (half + 4.0)), "beyond its bumper is not")
	t.check(not car.will_be_lethal(at - forward * (half - 2.0)),
			"the danger prediction agrees: no red caret behind it")
	t.check(car.will_be_lethal(at + forward * (half + 40.0)),
			"and has one for somebody it is driving at")

func _test_a_car_pulling_away_from_a_stand_does_not_end_the_day(t, car: CrowdAgent) -> void:
	var forward := car.heading()
	var behind := car.global_position - forward * (Tuning.CAR_STRIKE_HALF_LENGTH - 4.0)
	car._speed = 0.0
	t.check(not _strike(car, behind), "standing, it strikes nobody behind it")
	car._speed = Tuning.CAR_STRIKE_MIN_SPEED
	var struck := false
	for i in 120:
		car.global_position += forward * (Tuning.CAR_STRIKE_MIN_SPEED + 40.0) * STEP
		car._speed = Tuning.CAR_STRIKE_MIN_SPEED + 40.0
		struck = struck or _strike(car, behind)
	t.check(not struck, "a car that sets off away from her standing just behind it never strikes her")

func _test_a_car_driving_at_her_still_does(t, car: CrowdAgent) -> void:
	var forward := car.heading()
	var her := car.global_position + forward * 120.0
	car._speed = 90.0
	var struck := false
	for i in 120:
		car.global_position += forward * 90.0 * STEP
		struck = struck or _strike(car, her)
	t.check(struck, "a car driving at her still ends the day")

func _test_a_fast_car_is_foreseen(t, car: CrowdAgent) -> void:
	# At the top speed the car covers 46px per 0.25s sample, more than the 26px strike box, so a
	# sampled prediction can step over her; the closed form cannot.
	var forward := car.heading()
	var top := Tuning.CAR_SPEED.y
	car._speed = top
	var ahead := 100.0 + Tuning.CAR_STRIKE_HALF_LENGTH
	t.check(car.will_be_lethal(car.global_position + forward * ahead),
			"a car at top speed is foreseen to strike her 126px ahead, between two samples")
	var beyond := top * Tuning.EXPECTED_IMPACT_HORIZON + Tuning.CAR_STRIKE_HALF_LENGTH + 40.0
	t.check(not car.will_be_lethal(car.global_position + forward * beyond),
			"and not one beyond the horizon")
