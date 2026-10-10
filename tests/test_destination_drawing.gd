extends RefCounted
## What a resistance contact draws (snowy-kestrel, the player: "red arrow tasks show a chalk mark at
## their destination"): the chalk mark and its touched picture belong to the pickup alone, and a
## task's destination — a rider, or a bare point (day 9's district door, day 11's mast foot, day
## 12's swing, the last night's station door) — draws no chalk picture, untouched or done, while the
## red arrow still ends on it. Headless runs never call `_draw()`, so this asks
## `ContactPoint.draws_a_mark()`, the one question `_draw()` asks before it draws the chalk.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_test_every_task_days_destination_draws_no_mark(t)
	if _city != null:
		_city.free()
		_city = null

## Through the real day order on every task day: the mark on offer draws, the task its touch
## activates draws nothing at its destination while the red arrow ends there, and the read mark
## keeps its touched picture where she read it.
func _test_every_task_days_destination_draws_no_mark(t) -> void:
	var finale_day := Tuning.RUN_LENGTH_DAYS
	var days: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day not in days:
			days.append(step.day)
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	var saved_state := GameState.city_state
	var saved_sabotage := GameState.sabotage_done
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_package := GameState.resistance_carrying_package
	for day in days:
		_build_city(t)
		var finale := day == finale_day
		GameState.scars.clear()
		GameState.day = day
		GameState.failed_resistance_steps = []
		GameState.completed_resistance_steps = _all_but_the_finale() if finale \
				else _completed_before(day)
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL if finale else 0
		GameState.resistance_carrying_package = false
		GameState.sabotage_done = false
		var state := CityState.new()
		GameState.city_state = state
		state.begin_day(_city.map.block_plans, day)
		_city.start_day(state, day, _rng(day, "closures"))
		_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(_city, _city.map)
		director.start_day(day, _rng(day, "resistance"), 300.0)
		var offered := director.current_step()
		if not finale:
			t.check(offered != null and offered.is_pickup and director._contact.draws_a_mark(),
					"day %d: the mark on offer draws its chalk" % day)
			# Her touch, the way `ContactPoint._physics_process()` answers it: done, then the
			# director activates the task.
			if offered != null and offered.is_pickup:
				director._contact._complete()
			t.check(director._read_mark != null and director._read_mark.is_done
					and director._read_mark.draws_a_mark(),
					"day %d: the read mark keeps its touched picture" % day)
		var task := director.current_step()
		t.check(task != null and not task.is_pickup, "day %d: the task is on offer" % day)
		if task != null and not task.is_pickup:
			var contact := director._contact
			var bare := contact._rider == null
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
	GameState.scars = saved_scars
	GameState.day = saved_day
	GameState.city_state = saved_state
	GameState.sabotage_done = saved_sabotage
	GameState.completed_resistance_alley_tiles = saved_tiles
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.resistance_carrying_package = saved_package

func _build_city(t) -> void:
	if _city != null:
		_city.free()
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

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
