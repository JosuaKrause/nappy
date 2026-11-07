extends RefCounted
## What a resistance contact draws (snowy-kestrel, the player: "red arrow tasks show a chalk mark at
## their destination"): the chalk mark and its touched picture belong to the pickup alone, and a
## task's destination — a rider, or a bare point (day 9's district door, day 11's mast foot, day
## 12's swing, the last night's station door) — draws no chalk picture, untouched or done, while the
## red arrow still ends on it. A headless draw pass leaves no picture to read, so this asks
## `ContactPoint.draws_a_mark()`, the one question `_draw()` asks before it draws the chalk.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_test_every_task_days_destination_draws_no_mark(t)
	if _city != null:
		_city.free()
		_city = null

## Through the real day order on every task day, each in a run of its own (the city holds it): the
## mark on offer draws, the task its touch activates draws nothing at its destination while the red
## arrow ends there, and the read mark keeps its touched picture where she read it.
func _test_every_task_days_destination_draws_no_mark(t) -> void:
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
			t.check(offered != null and offered.is_pickup and director.contact().draws_a_mark(),
					"day %d: the mark on offer draws its chalk" % day)
			# Her touch, the way `ContactPoint._physics_process()` answers it: done, then the
			# director activates the task.
			if offered != null and offered.is_pickup:
				director.contact().complete_now()
			t.check(director.read_mark() != null and director.read_mark().is_done
					and director.read_mark().draws_a_mark(),
					"day %d: the read mark keeps its touched picture" % day)
		var task := director.current_step()
		t.check(task != null and not task.is_pickup, "day %d: the task is on offer" % day)
		if task != null and not task.is_pickup:
			var contact := director.contact()
			var bare := director.rider() == null
			t.check(not contact.draws_a_mark(), "day %d: the task's destination (%s) draws no chalk"
					% [day, "a bare point" if bare else "a rider"])
			t.check(director.red_arrow_target() != Vector2.INF,
					"day %d: the red arrow still points at the destination" % day)
			if bare:
				t.check(director.red_arrow_target().is_equal_approx(director.contact_position()),
						"day %d: the arrow ends on the bare point's own item" % day)
			contact.is_done = true
			t.check(not contact.draws_a_mark(), "day %d: a done task draws no touched chalk" % day)
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
