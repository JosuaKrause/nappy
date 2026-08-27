extends RefCounted
## The day loop: the two phases, the four ways a day ends, and the run-level bookkeeping
## that decides which ending you get.

const SEED := 4242

var _map: CityMap
var _player: Node2D
var _day: DayController
var _results: Array[GameEnums.DayResult] = []

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_start_sets_the_clock(t)
	_test_running_out_of_daylight_loses(t)
	_test_sleeping_starts_the_return_phase(t)
	_test_home_only_wins_during_the_return(t)
	_test_falling_asleep_at_home_wins_immediately(t)
	_test_being_woken_resumes_walking(t)
	_test_crying_loses(t)
	_test_hard_fail_loses_with_a_reason(t)
	_test_a_day_ends_only_once(t)
	_test_nerves_and_endings(t)
	_test_the_city_learns_where_she_settled(t)

# --------------------------------------------------------------------- rig ---

func _build(t) -> void:
	_results = []
	_player = Node2D.new()
	t.add_child(_player)
	_away_from_home()
	_day = DayController.new()
	t.add_child(_day)
	_day.set_process(false)
	_day.setup(_map, _player)
	_day.day_finished.connect(func(result: GameEnums.DayResult) -> void: _results.append(result))

func _teardown() -> void:
	# Freeing the controller drops its EventBus connections, so sub-tests do not leak
	# into each other.
	_day.free()
	_player.free()

func _tick(seconds: float) -> void:
	_day._process(seconds)

func _at_home() -> void:
	_player.global_position = _map.home_world_position()

func _away_from_home() -> void:
	_player.global_position = _map.tile_to_world(
		Vector2i(map_edge_tile(), map_edge_tile()))

func map_edge_tile() -> int:
	return Tuning.STREET_WIDTH / 2

# ------------------------------------------------------------------- phases ---

func _test_start_sets_the_clock(t) -> void:
	_build(t)
	_day.start(300.0)
	t.check(_day.phase == GameEnums.DayPhase.WALKING, "a day starts in the walking phase")
	t.close_to(_day.time_remaining, 300.0, "the clock starts full")
	t.close_to(_day.fraction_remaining(), 1.0, "the light starts at midday")
	_tick(150.0)
	t.close_to(_day.fraction_remaining(), 0.5, "the light tracks the clock")
	_teardown()

func _test_running_out_of_daylight_loses(t) -> void:
	_build(t)
	_day.start(10.0)
	_tick(9.0)
	t.check(_results.is_empty(), "the day is still running before dusk")
	_tick(2.0)
	t.check(_results == [GameEnums.DayResult.LOST_TIMEOUT], "dusk loses the day")
	t.check(_day.failure_reason != "", "a timeout explains itself")
	_teardown()

func _test_sleeping_starts_the_return_phase(t) -> void:
	_build(t)
	_day.start(300.0)
	EventBus.return_phase_started.emit()
	t.check(_day.phase == GameEnums.DayPhase.RETURNING,
			"a sleeping baby starts the walk home")
	t.check(_results.is_empty(), "falling asleep does not by itself win the day")
	_teardown()

func _test_home_only_wins_during_the_return(t) -> void:
	_build(t)
	_day.start(300.0)
	_at_home()
	_tick(1.0)
	t.check(_results.is_empty(), "reaching home with a wide-awake baby wins nothing")

	EventBus.return_phase_started.emit()
	_tick(1.0)
	t.check(_results == [GameEnums.DayResult.WON], "getting a sleeping baby home wins the day")
	_teardown()

func _test_falling_asleep_at_home_wins_immediately(t) -> void:
	_build(t)
	_day.start(300.0)
	_at_home()
	EventBus.return_phase_started.emit()
	t.check(_results == [GameEnums.DayResult.WON],
			"falling asleep on the doorstep does not need a lap of the block")
	_teardown()

func _test_being_woken_resumes_walking(t) -> void:
	_build(t)
	_day.start(300.0)
	EventBus.return_phase_started.emit()
	EventBus.baby_state_changed.emit(GameEnums.BabyState.AWAKE)
	t.check(_day.phase == GameEnums.DayPhase.WALKING,
			"being woken on the way home puts you back to walking her down")

	_at_home()
	_tick(1.0)
	t.check(_results.is_empty(), "and reaching home with her awake wins nothing")
	_teardown()

# -------------------------------------------------------------------- losses ---

func _test_crying_loses(t) -> void:
	_build(t)
	_day.start(300.0)
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	t.check(_results == [GameEnums.DayResult.LOST_CRYING], "crying loses the day")
	t.check(_day.failure_reason != "", "crying explains itself")
	_teardown()

func _test_hard_fail_loses_with_a_reason(t) -> void:
	_build(t)
	_day.start(300.0)
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(_results == [GameEnums.DayResult.LOST_HARD_FAIL], "a hard fail loses the day")
	t.check(_day.failure_reason.contains("van"),
			"a hard fail explains itself in the event's own words")

	_teardown()
	_build(t)
	_day.start(300.0)
	EventBus.hard_fail_triggered.emit("something_unwritten")
	t.check(_day.failure_reason != "", "an unwritten hard fail still says something")
	_teardown()

## Every outcome runs through _end(), and a day that has already ended must stay ended —
## otherwise a cry during the dusk frame would spend two nerves.
func _test_a_day_ends_only_once(t) -> void:
	_build(t)
	_day.start(300.0)
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	EventBus.hard_fail_triggered.emit("abduction")
	EventBus.return_phase_started.emit()
	_at_home()
	_tick(400.0)
	t.check(_results.size() == 1, "a day finishes exactly once, whatever else arrives")
	_teardown()

# ------------------------------------------------------------ run bookkeeping ---

func _test_nerves_and_endings(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_day := GameState.day
	var saved_nerves := GameState.nerves
	var saved_progress := GameState.resistance_progress
	var saved_sabotage := GameState.sabotage_done

	GameState.start_run(SEED)
	t.check(GameState.nerves == Tuning.STARTING_NERVES, "a run starts with full nerves")
	t.check(GameState.finish_day(GameEnums.DayResult.WON), "winning day 1 continues the run")
	t.check(GameState.day == 2, "winning advances the calendar")
	t.check(GameState.nerves == Tuning.STARTING_NERVES, "winning costs no nerves")

	# Playtest 06, finding 4: *"we shouldn't advance the day, that's for sure."* A nerve buys
	# another attempt at the same day rather than a day off the calendar.
	GameState.remember_where_she_settled(Vector2i(4, 4))
	t.check(GameState.finish_day(GameEnums.DayResult.LOST_CRYING), "losing a day continues")
	t.check(GameState.day == 2, "and the calendar stays where it is, so the day is retried")
	t.check(GameState.nerves == Tuning.STARTING_NERVES - 1, "losing costs a nerve")
	# Where she settled belongs to the attempt, not to the run: left behind, tomorrow would
	# spoil a park the winning attempt never went to, and the record is written once a day.
	t.check(GameState.settled_in.get(2, Vector2i(-1, -1)) == Vector2i(-1, -1),
			"and a lost attempt's calm block is forgotten with it")

	# Burn the rest.
	for i in Tuning.STARTING_NERVES - 1:
		GameState.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	t.check(GameState.nerves <= 0, "nerves run out")
	t.check(GameState.ending == GameEnums.Ending.BAD, "running out of nerves is the bad ending")
	t.check(GameState.day == 2, "having spent all three on the same day, which is now allowed")

	# The run length is a promise rather than a budget: with nerves left, the final day is
	# played until it is won, and the only way to lose a run is to run out of nerves.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	t.check(GameState.finish_day(GameEnums.DayResult.LOST_TIMEOUT),
			"losing the last day with nerves left does not end the run")
	t.check(GameState.day == Tuning.RUN_LENGTH_DAYS and GameState.ending == GameEnums.Ending.NONE,
			"it is still day %d, with the run undecided" % Tuning.RUN_LENGTH_DAYS)

	# Surviving to the end without the resistance is the neutral ending.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	t.check(not GameState.finish_day(GameEnums.DayResult.WON), "the final day ends the run")
	t.check(GameState.ending == GameEnums.Ending.NEUTRAL,
			"finishing without the resistance is the neutral ending")

	# Doing the legwork and then skipping the last night is still the neutral ending:
	# reaching the goal earns the CHANCE at the good one, the sabotage is the act.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	for step in Tuning.RESISTANCE_GOAL:
		GameState.complete_resistance_step(step + 1)
	t.check(GameState.resistance_progress >= Tuning.RESISTANCE_GOAL, "the goal is reached")
	t.check(GameState.sabotage_available(), "which puts the sabotage on offer")
	t.check(not GameState.earned_good_ending(), "but the goal alone does not earn the ending")
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NEUTRAL,
			"reaching the goal without doing the sabotage is still the neutral ending")

	# Both, and it is the good one.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	for step in Tuning.RESISTANCE_GOAL:
		GameState.complete_resistance_step(step + 1)
	GameState.sabotage_done = true
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.GOOD,
			"the goal plus the sabotage is the good ending")

	# And the sabotage without the legwork is not enough either.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.sabotage_done = true
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NEUTRAL,
			"the sabotage without the progress is not the good ending")

	# A completed step never counts twice.
	GameState.start_run(SEED)
	GameState.complete_resistance_step(1)
	GameState.complete_resistance_step(1)
	t.check(GameState.resistance_progress == 1, "a resistance step counts once")
	GameState.penalise_resistance()
	GameState.penalise_resistance()
	t.check(GameState.resistance_progress == 0, "resistance progress never goes negative")

	GameState.run_seed = saved_seed
	GameState.day = saved_day
	GameState.nerves = saved_nerves
	GameState.resistance_progress = saved_progress
	GameState.sabotage_done = saved_sabotage

## The recording half of M24. The scheduler's half is tested in `test_events.gd`; this is the
## half that decides *what* it gets told, and it is easy to get subtly wrong in two ways —
## recording a pavement she happened to fall asleep on, or recording nothing because the rule
## was put somewhere that does not know where she is standing.
##
## It lives in `DayController` rather than in `Baby` because of the invariant: the baby's whole
## interface to the world is three questions and none of them is about blocks.
func _test_the_city_learns_where_she_settled(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_day := GameState.day
	var saved_settled := GameState.settled_in.duplicate()

	GameState.start_run(SEED)
	_build(t)
	_day.start(300.0)

	# Asleep on an ordinary pavement is not a park and does not spend one.
	_away_from_home()
	EventBus.return_phase_started.emit()
	t.check(GameState.settled_yesterday() == Vector2i(-1, -1),
			"nothing is remembered yet on day 1")
	t.check(not GameState.settled_in.has(1),
			"falling asleep on a pavement does not spend a park")
	_teardown()

	# Asleep on calm ground records the block she is standing in.
	_build(t)
	_day.start(300.0)
	var calm: Vector2i = _map.calm_blocks[0]
	_player.global_position = _map.tile_rect_to_world(CityMap.block_rect(calm)).get_center()
	EventBus.return_phase_started.emit()
	t.check(GameState.settled_in.get(1, Vector2i(-1, -1)) == calm,
			"the calm block she settled in is remembered")

	GameState.day = 2
	t.check(GameState.settled_yesterday() == calm,
			"and tomorrow is the day that reads it")
	_teardown()

	GameState.settled_in = saved_settled
	GameState.run_seed = saved_seed
	GameState.day = saved_day
