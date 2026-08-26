extends RefCounted
## The resistance subquest: the step table, the hold, and the two things that make it cost
## something — the alley roulette and the step that expires.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_step_table(t)
	_test_step_selection(t)
	_test_the_finale_needs_the_legwork(t)
	_test_holding_completes_a_contact(t)
	_test_letting_go_unwinds(t)
	_test_a_patrol_resets_the_hold(t)
	_test_placement_is_deterministic(t)
	_test_the_alley_roulette_is_seeded(t)
	_test_a_timed_step_expires(t)

# ---------------------------------------------------------------- step table ---

func _test_step_table(t) -> void:
	var steps := ResistanceSteps.all()
	t.check(steps.size() == 6, "there are six steps")

	var previous_day := 0
	var previous_index := 0
	for step in steps:
		t.check(step.index == previous_index + 1, "step indices run 1..6 in order")
		t.check(step.first_day >= previous_day, "steps unlock in calendar order")
		t.check(step.hold_seconds > 0.0, "every step asks you to stand still for a while")
		t.check(step.placement.size() > 0 or step.district >= 0,
				"step %d knows where it goes" % step.index)
		previous_index = step.index
		previous_day = step.first_day

	# Reaching the goal must be possible while missing one of the first five.
	var before_finale := 0
	for step in steps:
		if not step.needs_goal:
			before_finale += 1
	t.check(before_finale > Tuning.RESISTANCE_GOAL,
			"there are more ordinary steps than the goal needs, so one can be missed")
	t.check(steps[steps.size() - 1].needs_goal, "the finale is the last step")
	t.check(steps[steps.size() - 1].first_day == Tuning.RUN_LENGTH_DAYS,
			"and it is on the last day")

func _test_step_selection(t) -> void:
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(1, none, none, false) == null,
			"nothing is on offer before the resistance exists")

	var first := ResistanceSteps.for_day(5, none, none, false)
	t.check(first != null and first.index == 1, "day 5 offers the chalk mark")

	var done: Array[int] = [1]
	t.check(ResistanceSteps.for_day(5, done, none, false) == null,
			"a completed step is not offered again, and the next one is not open yet")
	var second := ResistanceSteps.for_day(7, done, none, false)
	t.check(second != null and second.index == 2, "day 7 moves on to the contact")

	# A step lost to its deadline is gone for the rest of the run.
	var failed: Array[int] = [2]
	var after_failure := ResistanceSteps.for_day(7, done, failed, false)
	t.check(after_failure == null, "a failed step is never offered again")
	var later := ResistanceSteps.for_day(9, done, failed, false)
	t.check(later != null and later.index == 3, "but the run carries on to the next one")

func _test_the_finale_needs_the_legwork(t) -> void:
	var done: Array[int] = [1, 2, 3, 4, 5]
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, false) == null,
			"the finale is not offered to a player who has not earned it")
	var finale := ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, true)
	t.check(finale != null and finale.needs_goal, "and is offered to one who has")

# ---------------------------------------------------------------------- hold ---

var _player: Stroller
var _contact: ContactPoint

func _build_contact(t, step_index: int) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)
	_player.global_position = Vector2.ZERO

	_contact = ContactPoint.new()
	_contact.setup(ResistanceSteps.by_index(step_index), Vector2.ZERO, null)
	t.add_child(_contact)
	_contact.set_physics_process(false)

func _teardown_contact() -> void:
	Input.action_release("interact")
	_contact.free()
	_player.free()

func _hold_for(seconds: float) -> void:
	Input.action_press("interact")
	for i in int(round(seconds / STEP)):
		_contact._physics_process(STEP)

func _wait(seconds: float) -> void:
	Input.action_release("interact")
	for i in int(round(seconds / STEP)):
		_contact._physics_process(STEP)

func _test_holding_completes_a_contact(t) -> void:
	_build_contact(t, 1)
	var completed: Array[int] = []
	_contact.completed.connect(func(index: int) -> void: completed.append(index))

	_hold_for(_contact.step.hold_seconds * 0.5)
	t.check(not _contact.is_done, "half the hold is not enough")
	t.check(_contact.progress > 0.4 and _contact.progress < 0.6,
			"and progress tracks the time held")

	_hold_for(_contact.step.hold_seconds * 0.6)
	t.check(_contact.is_done, "holding it out completes the step")
	t.check(completed == [1], "and reports which step it was, once")
	_teardown_contact()

func _test_letting_go_unwinds(t) -> void:
	_build_contact(t, 2)
	_hold_for(_contact.step.hold_seconds * 0.5)
	var peak := _contact.progress
	_wait(1.0)
	t.check(_contact.progress < peak, "letting go unwinds the hold")
	t.check(not _contact.is_done, "and does not complete it")

	# Walking away is the same as letting go.
	_player.global_position = Vector2(500.0, 0.0)
	_hold_for(_contact.step.hold_seconds * 2.0)
	t.check(not _contact.is_done, "holding the button from across the city does nothing")
	_teardown_contact()

func _test_a_patrol_resets_the_hold(t) -> void:
	_build_contact(t, 1)
	var seen: Array[bool] = []
	var handler := func() -> void: seen.append(true)
	EventBus.resistance_seen.connect(handler)

	# A patrol parked right on top of the contact, past its telegraph.
	var patrol := EventInstance.new()
	patrol.setup(EventCatalogue.by_id("police_patrol"), Vector2.ZERO)
	t.add_child(patrol)
	patrol.set_process(false)
	for i in int(round((patrol.def.telegraph_time + 0.2) / STEP)):
		patrol._process(STEP)

	_hold_for(_contact.step.hold_seconds * 0.4)
	var without_patrol := _contact.progress
	t.check(without_patrol > 0.0, "the hold builds while nobody is looking")

	var fake := _FakeEvents.new([patrol])
	_contact._events = fake
	_hold_for(0.5)
	t.check(_contact.progress == 0.0, "a patrol coming past resets the hold")
	t.check(seen.size() > 0, "and says so")
	t.check(not _contact.is_done, "you cannot finish a handover while being watched")

	EventBus.resistance_seen.disconnect(handler)
	# EventManager is a Node, so the stand-in is not refcounted and has to be freed by hand.
	fake.free()
	patrol.free()
	_teardown_contact()

## Stands in for EventManager, which needs a whole City to build.
class _FakeEvents extends EventManager:
	var _fake: Array[EventInstance] = []

	func _init(list: Array[EventInstance]) -> void:
		_fake = list

	func instances() -> Array[EventInstance]:
		return _fake

# ------------------------------------------------------------------ director ---

var _city: City

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

func _with_clean_run(action: Callable) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	action.call()
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress

## The whole design rests on the run being learnable: the alley that was safe on day 9 has
## to be safe on day 9 every time you replay that run.
func _test_placement_is_deterministic(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var first := _director(t)
		first.start_day(5, _rng(5, "resistance"), 300.0)
		var where := first.contact_position()
		t.check(where != Vector2.INF, "day 5 puts a contact somewhere")
		t.check(_city.map.tile_type_at_world(where) == GameEnums.TileType.ALLEY,
				"and the chalk mark is in an alley")

		var second := _director(t)
		second.start_day(5, _rng(5, "resistance"), 300.0)
		t.close_to(second.contact_position().distance_to(where), 0.0,
				"and it is in the same alley every time", 0.01)

		var other := _director(t)
		other.start_day(7, _rng(7, "resistance"), 300.0)
		t.check(other.contact_position() != where, "a different day is a different alley")

		first.free()
		second.free()
		other.free())

func _test_the_alley_roulette_is_seeded(t) -> void:
	_with_clean_run(func() -> void:
		# Before act III an alley contact is never a trap.
		var early := _director(t)
		early.start_day(7, _rng(7, "resistance"), 300.0)
		t.check(not _has_robbery_at(early.contact_position()),
				"alleys are not yet lethal in act II")
		early.free()

		# From act III the same day always rolls the same way.
		var trapped_days := 0
		for day in range(8, Tuning.RUN_LENGTH_DAYS + 1):
			GameState.completed_resistance_steps = []
			GameState.failed_resistance_steps = []
			var a := _director(t)
			a.start_day(day, _rng(day, "resistance"), 300.0)
			var at := a.contact_position()
			var trapped := _has_robbery_at(at)
			a.free()

			var b := _director(t)
			b.start_day(day, _rng(day, "resistance"), 300.0)
			t.check(_has_robbery_at(b.contact_position()) == trapped,
					"day %d rolls the trap the same way every replay" % day)
			b.free()
			if trapped:
				trapped_days += 1
		t.check(trapped_days < Tuning.RUN_LENGTH_DAYS - 7,
				"not every alley is a trap, or there would be no gamble"))

func _has_robbery_at(where: Vector2) -> bool:
	if where == Vector2.INF:
		return false
	for instance in _city.events.instances():
		if instance.def.id != "alley_robbery":
			continue
		if instance.global_position.distance_to(where) < 1.0:
			return true
	return false

## A warning delivered late is not a warning.
func _test_a_timed_step_expires(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = [1, 2, 3]
		var timed := ResistanceSteps.by_index(4)
		t.check(timed.deadline_fraction > 0.0, "step 4 is the timed one")

		var director := _director(t)
		director.start_day(11, _rng(11, "resistance"), 100.0)
		t.check(director.current_step() != null, "the warning is on offer at the start")

		director._process(100.0 * timed.deadline_fraction * 0.5)
		t.check(director.current_step() != null, "and still on offer before the deadline")
		t.check(4 not in GameState.failed_resistance_steps, "nothing has failed yet")

		director._process(100.0 * timed.deadline_fraction)
		t.check(director.current_step() == null, "past the deadline it is gone")
		t.check(4 in GameState.failed_resistance_steps, "and recorded as failed for the run")
		director.free())
	_city.free()
