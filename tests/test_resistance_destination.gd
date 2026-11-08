extends RefCounted
## Where a resistance task's destination is, once its pickup is read: on every task day, through the
## real day order, the task is on offer after the mark is touched and the red arrow still ends on its
## destination (the rider's body, or on a bare point the contact's own position). Whether a contact
## draws chalk is `tests/test_destination_drawing.gd`'s, on `ContactPoint` alone.
##
## **A combined suite, for a stated reason**: the guarantee spans modules. The director picks the
## task from the step table and the run's progress, places its contact on the day's events and map,
## and answers the arrow from them, so the real city (from the cached maps of
## `tests/city_map_cache.gd`), the day's events and the director are built.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_test_every_task_days_destination_holds_the_arrow(t)
	if _city != null:
		_city.free()
		_city = null

## Through the real day order on every task day, each in a run of its own (the city holds it): the
## pickup is on offer and read, the task its touch activates is on offer, and the red arrow ends on
## that task's destination. What each contact point draws is `test_destination_drawing`'s.
func _test_every_task_days_destination_holds_the_arrow(t) -> void:
	var finale_day := Tuning.RUN_LENGTH_DAYS
	var days: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day not in days:
			days.append(step.day)
	for day in days:
		_build_city(t)
		var run := _city.run
		var finale := day == finale_day
		run.header.day = day
		run.resistance.completed_steps = _all_but_the_finale() if finale \
				else _completed_before(day)
		run.resistance.progress = Tuning.RESISTANCE_GOAL if finale else 0
		var state := CityState.new()
		run.attempt_spend.city_state = state
		state.begin_day(_city.map.block_plans, day)
		_city.start_day(state, day, _rng(day, "closures"))
		_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city, null,
				_city.spawn_siting)
		director.start_day(day, _rng(day, "resistance"), 300.0)
		var offered := director.current_step()
		if not finale:
			t.check(offered != null and offered.is_pickup,
					"day %d: the pickup is on offer" % day)
			# Her touch, the way `ContactPoint._physics_process()` answers it: done, then the
			# director activates the task.
			if offered != null and offered.is_pickup:
				director.contact().complete_now()
			t.check(director.read_mark() != null and director.read_mark().is_done,
					"day %d: the pickup is read" % day)
		var task := director.current_step()
		t.check(task != null and not task.is_pickup, "day %d: the task is on offer" % day)
		if task != null and not task.is_pickup:
			var contact := director.contact()
			var bare := director.rider() == null
			t.check(director.red_arrow_target() != Vector2.INF,
					"day %d: the red arrow still points at the destination" % day)
			if bare:
				t.check(director.red_arrow_target().is_equal_approx(director.contact_position()),
						"day %d: the arrow ends on the bare point's own item" % day)
		director.free()

func _build_city(t) -> void:
	if _city != null:
		_city.free()
	_city = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(_city)
	_city.build(MapCache.of(SEED))

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

## Every step of the days before `day`, done — the run a player reaching `day` with the whole
## subquest behind her carries.
func _completed_before(day: int) -> Array[int]:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < day:
			done.append(step.index)
	return done

func _all_but_the_finale() -> Array[int]:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if not step.needs_goal:
			done.append(step.index)
	return done
