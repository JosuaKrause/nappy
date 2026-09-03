extends RefCounted
## The resistance subquest: the step table, touch-completion, a perform contact riding on an
## `EventInstance`, the seeded guard, the expiring step, and the sabotage silencing the city.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_step_table(t)
	_test_step_selection(t)
	_test_the_finale_needs_the_legwork(t)
	_test_completing_a_pickup_sets_the_day_briefs_words(t)
	_test_touching_completes_a_pickup(t)
	_test_walking_away_leaves_it_untouched(t)
	_test_a_perform_contact_rides_on_its_instance(t)
	_test_a_perform_contact_sees_its_rider_finish(t)
	_test_placement_is_deterministic(t)
	_test_the_guard_is_seeded(t)
	_test_a_perform_step_expires_when_its_rider_is_gone(t)
	_test_a_timed_step_expires(t)
	_test_completing_the_package_makes_the_pram_heavier(t)
	_test_starting_a_day_resets_the_package_flag(t)
	_test_the_sabotage_silences_the_city(t)

# ---------------------------------------------------------------- step table ---

func _test_step_table(t) -> void:
	var steps := ResistanceSteps.all()
	# Not `size() == 11`: `ResistanceSteps._build()` is a literal array, so a count of it is that
	# array restated and adding a task would mean editing both in lockstep. The guard here is only
	# that there is something to check, which is what stops the sweep below passing vacuously.
	t.check(not steps.is_empty(), "there is a step table to check")

	var previous_day := 0
	var previous_index := 0
	var performs := 0
	for step in steps:
		t.check(step.index == previous_index + 1, "step indices run consecutively from 1")
		t.check(step.first_day >= previous_day, "steps unlock in calendar order")
		t.check(step.placement.size() > 0 or step.district >= 0,
				"step %d knows where it goes" % step.index)
		if step.is_pickup:
			t.check(not step.grants_progress, "a pickup does not grant progress")
			t.check(step.task_event_id == "", "a pickup sits on a tile, not a rider")
		elif not step.needs_goal:
			t.check(step.task_event_id != "", "a perform step names what it rides on")
			performs += 1
		previous_index = step.index
		previous_day = step.first_day

	t.check(performs > Tuning.RESISTANCE_GOAL,
			"there are more perform steps than the goal needs, so one task can be missed")
	t.check(steps[steps.size() - 1].needs_goal, "the finale is the last step")
	t.check(steps[steps.size() - 1].first_day == Tuning.RUN_LENGTH_DAYS,
			"and it is on the last day")

func _test_step_selection(t) -> void:
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(1, none, none, false) == null,
			"nothing is on offer before the resistance exists")

	var first := ResistanceSteps.for_day(4, none, none, false)
	t.check(first != null and first.index == 1 and first.is_pickup,
			"day 4 offers the first chalk mark")

	var done: Array[int] = [1]
	t.check(ResistanceSteps.for_day(4, done, none, false) == null,
			"the mark done and the perform not yet open leaves nothing on offer")
	var second := ResistanceSteps.for_day(5, done, none, false)
	t.check(second != null and second.index == 2 and not second.is_pickup,
			"day 5 moves on to the perform half")

	# A step lost to its deadline is gone for the rest of the run.
	var failed: Array[int] = [2]
	var after_failure := ResistanceSteps.for_day(5, done, failed, false)
	t.check(after_failure == null, "a failed step is never offered again")
	var later := ResistanceSteps.for_day(6, done, failed, false)
	t.check(later != null and later.index == 3, "but the run carries on to the next task's mark")

func _test_the_finale_needs_the_legwork(t) -> void:
	var done: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, false) == null,
			"the finale is not offered to a player who has not earned it")
	var finale := ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, true)
	t.check(finale != null and finale.needs_goal, "and is offered to one who has")

## The day brief is the mechanism now, not a courtesy: miss the mark and there is nothing to
## read, because nothing else in the game ever says what a task wants.
func _test_completing_a_pickup_sets_the_day_briefs_words(t) -> void:
	_with_clean_run(func() -> void:
		var mark := ResistanceSteps.by_index(1)
		t.check(mark.is_pickup and mark.brief != "", "the first mark has words to give")

		GameState.complete_resistance_step(1, mark.grants_progress)
		t.check(GameState.pending_resistance_brief == mark.brief,
				"completing the pickup queues its words for the next day brief")

		GameState.pending_resistance_brief = ""
		var perform := ResistanceSteps.by_index(2)
		t.check(not perform.is_pickup and perform.brief == "",
				"a perform step has nothing further to say")
		GameState.complete_resistance_step(2, perform.grants_progress)
		t.check(GameState.pending_resistance_brief == "",
				"completing a perform does not queue anything"))

# --------------------------------------------------------------------- touch ---

var _player: Stroller
var _contact: ContactPoint

func _build_pickup(t, step_index: int) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)
	_player.global_position = Vector2.ZERO

	_contact = ContactPoint.new()
	_contact.setup(ResistanceSteps.by_index(step_index), Vector2.ZERO)
	t.add_child(_contact)
	_contact.set_physics_process(false)

func _teardown_contact() -> void:
	_contact.free()
	_player.free()

func _test_touching_completes_a_pickup(t) -> void:
	_build_pickup(t, 1)
	var completed: Array[int] = []
	_contact.completed.connect(func(index: int) -> void: completed.append(index))

	t.check(not _contact.is_done, "not done before she arrives")
	_contact._physics_process(STEP)
	t.check(_contact.is_done, "touching it completes it, instantly — there is no hold")
	t.check(completed == [1], "and reports which step it was, once")
	_teardown_contact()

func _test_walking_away_leaves_it_untouched(t) -> void:
	_build_pickup(t, 1)
	_player.global_position = Vector2(500.0, 0.0)
	_contact._physics_process(STEP)
	t.check(not _contact.is_done, "out of reach, nothing happens")
	_teardown_contact()

## The shared plumbing every task needs: a contact that rides on an `EventInstance` rather
## than sitting on a bare tile, and follows it if it moves.
func _test_a_perform_contact_rides_on_its_instance(t) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)

	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2(300.0, 0.0))
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(2), instance, Vector2.ZERO)
	t.add_child(contact)
	contact.set_physics_process(false)

	_player.global_position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(not contact.is_done, "out of reach of where the rider is now")

	# The rider moves; the contact follows it rather than staying where it started.
	instance.position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(contact.is_done, "and completes once she reaches wherever the rider has gone")

	contact.free()
	instance.free()
	_player.free()

func _test_a_perform_contact_sees_its_rider_finish(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("checkpoint"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(6), instance, Vector2(90.0, 0.0))
	t.add_child(contact)
	contact.set_physics_process(false)

	t.check(contact.rider_alive(), "the rider starts alive")
	instance._finish()
	t.check(not contact.rider_alive(), "and rider_alive() sees it end")

	contact.free()
	instance.free()

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
	var saved_package := GameState.resistance_carrying_package
	var saved_brief := GameState.pending_resistance_brief
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false
	GameState.pending_resistance_brief = ""
	action.call()
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.resistance_carrying_package = saved_package
	GameState.pending_resistance_brief = saved_brief

func _completed_through(last_index: int) -> Array[int]:
	var done: Array[int] = []
	done.assign(range(1, last_index + 1))
	return done

## The whole design rests on the run being learnable: the alley that was safe on day 9 has
## to be safe on day 9 every time you replay that run — and the same is true of a perform
## step's own placement.
func _test_placement_is_deterministic(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var first := _director(t)
		first.start_day(4, _rng(4, "resistance"), 300.0)
		var where := first.contact_position()
		t.check(where != Vector2.INF, "day 4 puts a mark somewhere")
		t.check(_city.map.tile_type_at_world(where) == GameEnums.TileType.ALLEY,
				"and the chalk mark is in an alley")

		var second := _director(t)
		second.start_day(4, _rng(4, "resistance"), 300.0)
		t.close_to(second.contact_position().distance_to(where), 0.0,
				"and it is in the same alley every time", 0.01)

		GameState.completed_resistance_steps = _completed_through(1)
		var perform := _director(t)
		perform.start_day(5, _rng(5, "resistance"), 300.0)
		t.check(perform.current_step() != null and perform.current_step().index == 2,
				"day 5 offers the perform half")
		t.check(perform.contact_position() != Vector2.INF,
				"and it rides on a live instance rather than a bare tile")

		first.free()
		second.free()
		perform.free())

## *Always guarded* has to mean a survivable band, not a guaranteed lost day: a robber sits
## somewhere between 66px (30 + `ContactPoint.REACH`) and 176px (140 + `ContactPoint.REACH`)
## of every mark, seeded so the distance is the same every time this day is replayed.
func _test_the_guard_is_seeded(t) -> void:
	_seen_guard_distances = []
	_with_clean_run(func() -> void:
		var before := _director(t)
		before.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(before.current_step() == null, "nothing is offered before day 4")
		before.free()

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH
		var search := max_distance + 40.0

		for day in [4, 5, 6, 7]:
			GameState.completed_resistance_steps = _completed_through(day - 4)
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var at := director.contact_position()
			var guard := _find_robbery_near(at, search)
			t.check(guard != null, "day %d's mark is guarded" % day)
			var distance := guard.global_position.distance_to(at) if guard else -1.0
			if guard:
				t.check(distance >= min_distance - 0.5 and distance <= max_distance + 0.5,
						"day %d's guard sits in the 66-176px band" % day)
				_seen_guard_distances.append(distance)
			director.free()

			var replay := _director(t)
			replay.start_day(day, _rng(day, "resistance"), 300.0)
			var replay_guard := _find_robbery_near(replay.contact_position(), search)
			if guard and replay_guard:
				t.close_to(replay_guard.global_position.distance_to(replay.contact_position()),
						distance, "day %d's guard distance replays the same way" % day, 0.5)
			replay.free())

	var all_equal := true
	for distance in _seen_guard_distances:
		if not is_equal_approx(distance, _seen_guard_distances[0]):
			all_equal = false
	t.check(_seen_guard_distances.size() >= 2 and not all_equal,
			"the guard distance is not the same every day")

var _seen_guard_distances: Array[float] = []

func _find_robbery_near(at: Vector2, within: float) -> EventInstance:
	if at == Vector2.INF:
		return null
	for instance in _city.events.instances():
		if instance.def.id != "alley_robbery":
			continue
		if instance.global_position.distance_to(at) <= within:
			return instance
	return null

func _test_a_perform_step_expires_when_its_rider_is_gone(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(1)
		var director := _director(t)
		director.start_day(5, _rng(5, "resistance"), 300.0)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"day 5 offers the yeller perform step")
		var rider: EventInstance = director._rider
		t.check(rider != null, "the perform step rides on a live instance")

		rider._finish()
		director._process(0.1)
		t.check(director.current_step() == null, "and it is gone once the rider is")
		t.check(2 in GameState.failed_resistance_steps, "recorded as failed for the run")
		director.free())

## A window that closes when the poster crew's own instance is gone rather than by the day's
## clock — but the crew here never naturally finishes, so this exercises the fallback that
## does watch the clock: `deadline_fraction`, kept exactly as step 4 used it.
func _test_a_timed_step_expires(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(7)
		var timed := ResistanceSteps.by_index(8)
		t.check(timed.deadline_fraction > 0.0, "the wall is the timed perform step")

		var director := _director(t)
		director.start_day(11, _rng(11, "resistance"), 100.0)
		t.check(director.current_step() != null and director.current_step().index == 8,
				"the wall is on offer at the start")

		director._process(100.0 * timed.deadline_fraction * 0.5)
		t.check(director.current_step() != null, "and still on offer before the deadline")
		t.check(8 not in GameState.failed_resistance_steps, "nothing has failed yet")

		director._process(100.0 * timed.deadline_fraction)
		t.check(director.current_step() == null, "past the deadline it is gone")
		t.check(8 in GameState.failed_resistance_steps, "and recorded as failed for the run")
		director.free())

## E's cost is deferred and total rather than local: picking the package up does not cost the
## street it happened on, it makes every street after it dearer for the rest of the day.
func _test_completing_the_package_makes_the_pram_heavier(t) -> void:
	_with_clean_run(func() -> void:
		var somewhere := _city.map.tile_to_world(Vector2i(10, 10))
		var before := _city.decay_multiplier(somewhere)

		var director := _director(t)
		director._on_contact_completed(4)
		t.check(GameState.resistance_carrying_package, "picking up the package sets the flag")

		var after := _city.decay_multiplier(somewhere)
		t.close_to(after, before * Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER,
				"and every street after it decays slower for the rest of the day", 0.001)
		director.free())

func _test_starting_a_day_resets_the_package_flag(t) -> void:
	_with_clean_run(func() -> void:
		GameState.resistance_carrying_package = true
		var director := _director(t)
		director.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(not GameState.resistance_carrying_package,
				"a fresh attempt at a day has not picked it up yet")
		director.free())

## The whole subquest pays out in quiet. On the last walk home the masts stop, and the
## floor they have been holding under the meter since day 5 goes with them.
func _test_the_sabotage_silences_the_city(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(10)
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		GameState.sabotage_done = false
		t.check(GameState.sabotage_available(), "the finale is on offer")

		# A live mast, the way day 5 onwards leaves one.
		var mast := _city.events.spawn_extra(EventCatalogue.by_id("loudspeaker"),
				Vector2(400.0, 400.0))
		for i in int(round((mast.def.telegraph_time + 0.2) / STEP)):
			mast._process(STEP)
		var somewhere := Vector2(9000.0, 9000.0)
		t.check(mast.contribution_at(somewhere) > 0.0,
				"the mast reaches the far side of the city while it is on")

		var quiet: Array[bool] = []
		var handler := func() -> void: quiet.append(true)
		EventBus.city_went_quiet.connect(handler)

		var director := _director(t)
		director.start_day(Tuning.RUN_LENGTH_DAYS,
				_rng(Tuning.RUN_LENGTH_DAYS, "resistance"), 300.0)
		t.check(director.current_step() != null, "the last night has a contact")
		director._on_contact_completed(11)

		t.check(GameState.sabotage_done, "completing it does the sabotage")
		t.check(quiet.size() == 1, "and the city goes quiet, once")
		t.close_to(mast.contribution_at(somewhere), 0.0,
				"the mast contributes nothing afterwards")
		t.close_to(_city.events.total_excitement_at(somewhere), 0.0,
				"and there is no floor left anywhere")

		EventBus.city_went_quiet.disconnect(handler)
		director.free())
	_city.free()
