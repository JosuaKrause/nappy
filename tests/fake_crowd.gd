class_name FakeCrowd
extends Crowd
## A stand-in for the crowd, handed to what is handed a `Crowd` (the day director, an authored
## scene) in place of the real one, so the check builds no city and places nobody. It records what
## it is asked and answers what a suite sets: `start_day()`'s arguments, `set_gates()`,
## `use_stretch()`; `agent_count()` what it is set to; `add_recipe_actor()` an agent at the point
## asked, or the error it is set to answer; `agents()` the actors it made; `recipe_coverage()` an
## empty count. A helper, not a suite: the runner loads only `test_*.gd`.
##
## **Read off a real crowd once** (writing-tests): `add_recipe_actor()` answers the shape the real
## one does, `{"actor": <the agent>, "error": ""}` or `{"error": <why>}`; the count a scene's
## uniform population is checked against is read off the real crowd for that recipe by the suite
## that sets it. The real crowd's own logic is `tests/test_crowd_*.gd`'s.
##
## A node: the suite frees it, and with it every actor it made.

var _fake_asked: Array[String]
var _fake_count := 0
var _fake_failure := ""
var _fake_made: Array[CrowdAgent] = []
var _fake_started: Array[Dictionary] = []
var _fake_gates: Array[GateState] = []
var _fake_stretches := 0
var _fake_car_free_start: CarFreeStart = null

## A crowd that notes its asks as lines of `asked`, the list a suite shares among its stand-ins.
func _init(asked: Array[String] = []) -> void:
	_fake_asked = asked

## Sets what `agent_count()` answers.
func count_is(count: int) -> FakeCrowd:
	_fake_count = count
	return self

## Sets the error `add_recipe_actor()` answers, "" for none.
func refuse_actors_with(error: String) -> FakeCrowd:
	_fake_failure = error
	return self

## What each `start_day()` was handed, in order: `day`, `focus`, `populate`, `city_view`,
## `uniform_walkers`, `walker_multiplier` and `car_multiplier`.
func days_started() -> Array[Dictionary]:
	return _fake_started

## The gates `set_gates()` was last handed.
func gates() -> Array[GateState]:
	return _fake_gates

## How many times `use_stretch()` was asked.
func stretches_used() -> int:
	return _fake_stretches

## Overrides Crowd.start_day.
func start_day(day: int, _rng: RandomNumberGenerator, focus := Vector2.INF,
		populate := true, city_view := false, uniform_walkers := false,
		walker_multiplier := 1.0, car_multiplier := 1.0) -> void:
	_fake_started.append({"day": day, "focus": focus, "populate": populate, "city_view": city_view,
			"uniform_walkers": uniform_walkers, "walker_multiplier": walker_multiplier,
			"car_multiplier": car_multiplier})
	_fake_asked.append("crowd start_day")

## Overrides Crowd.hold_new_cars.
func hold_new_cars() -> void:
	_fake_asked.append("crowd hold_new_cars")

## Overrides Crowd.let_cars_in.
func let_cars_in() -> void:
	_fake_asked.append("crowd let_cars_in")

## Overrides Crowd.use_car_free_start.
func use_car_free_start(start: CarFreeStart) -> void:
	_fake_car_free_start = start
	_fake_asked.append("crowd use_car_free_start %s" % ("set" if start else "none"))

## What `use_car_free_start()` was last handed.
func car_free_start() -> CarFreeStart:
	return _fake_car_free_start

## Overrides Crowd.clear.
func clear() -> void:
	_fake_asked.append("crowd clear")

## Overrides Crowd.set_gates.
func set_gates(gates: Array[GateState]) -> void:
	_fake_gates = gates
	_fake_asked.append("crowd set_gates")

## Overrides Crowd.use_stretch.
func use_stretch() -> void:
	_fake_stretches += 1
	_fake_asked.append("crowd use_stretch")

## Overrides Crowd.agent_count.
func agent_count() -> int:
	return _fake_count

## Overrides Crowd.add_recipe_actor.
func add_recipe_actor(actor_name: String, kind: int, at: Vector2, _heading: Vector2,
		_speed: float, _seed_value: int) -> Dictionary:
	_fake_asked.append("crowd add_recipe_actor %s" % actor_name)
	if _fake_failure != "":
		return {"error": _fake_failure}
	var actor := CrowdAgent.new(kind as CrowdAgent.Kind)
	actor.name = actor_name
	actor.position = at
	_fake_made.append(actor)
	return {"actor": actor, "error": ""}

## Overrides Crowd.agents.
func agents() -> Array[CrowdAgent]:
	return _fake_made

## Overrides Crowd.recipe_coverage.
func recipe_coverage() -> Dictionary:
	return {}

## Frees what `add_recipe_actor()` made, beside the crowd's own letting go of its parts.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for actor in _fake_made:
			if is_instance_valid(actor):
				actor.free()
		_fake_made.clear()
