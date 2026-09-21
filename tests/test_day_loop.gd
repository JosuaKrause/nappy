extends RefCounted
## The day loop: the two phases, the four ways a day ends, and the run-level bookkeeping
## that decides which ending you get.

const SEED := 4242
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY_SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

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
	_test_day_finished_shows_the_summary_with_no_observer_in_the_tree(t)
	_test_the_day_brief_shows_the_days_own_line(t)
	_test_the_summary_shows_when_the_day_ended(t)
	_test_a_lost_day_gives_the_resistance_back(t)
	_test_the_retry_meets_the_same_mark_in_the_same_alley(t)

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

## **A day ending with no `TelemetryObserver` in the tree must still reach the summary.**
## *(Reproduced on the deployed build and read out of a real Web export's console: "excitement
## pinned at 100 and I'm completely invincible", also swallowing the cyclist and the timeout.)*
##
## `main._on_day_finished()` built its trail for `Telemetry.write_map()` from
## `_observer.trail() if _observer else []` assigned straight into a declared `Array[Vector3]` — a
## bare `[]` on the `else` side is an **untyped** `Array`, which is not the declared type, and
## Godot only throws on the mismatch when the line actually runs rather than at parse time.
## `_observer` is null on every build with telemetry off (`--no-telemetry`, and always on a Web
## export, since `Telemetry` disables itself there), which is the ordinary shape nothing that ever
## exercised this line ran under. The function aborted at that line, before `_summary.show_day()`
## a few lines below it ever ran — and `DayController._end()` had already moved the day's own phase
## to `OVER`, so from there the day simply stopped telling anything downstream: no summary, no
## paused tree, the meter frozen wherever it stood and the player still walking a day already over.
##
## Exercises `main._on_day_finished()` directly rather than through `DayController`'s own signal,
## the same way `tests/test_main.gd` reaches past `main._ready()` for the rest of its logic — a
## script-only instance, its handful of world dependencies wired up by hand, with `_observer` left
## null exactly the way a telemetry-off run leaves it.
func _test_day_finished_shows_the_summary_with_no_observer_in_the_tree(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_day := GameState.day
	var saved_nerves := GameState.nerves
	var saved_progress := GameState.resistance_progress
	var saved_sabotage := GameState.sabotage_done
	var saved_paused: bool = t.get_tree().paused
	GameState.start_run(SEED)

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var player := Node2D.new()
	t.add_child(player)
	var day := DayController.new()
	t.add_child(day)
	day.set_process(false)
	day.setup(city.map, player)
	day.start(300.0)
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	t.check(day.failure_reason != "",
			"the rig actually lost the day before asking the summary for anything")

	var summary: CanvasLayer = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(summary)

	var main: Node2D = MAIN_SCRIPT.new()
	main._city = city
	main._day = day
	main._summary = summary
	main._observer = null

	main._on_day_finished(GameEnums.DayResult.LOST_CRYING)

	t.check(summary.is_showing(),
			"the summary actually comes up with no telemetry observer in the tree")

	main.free()
	summary.free()
	day.free()
	player.free()
	city.free()
	# **Unpause, or this test silently disarms three of `tests/test_hud.gd`'s.** A summary coming up
	# sets `get_tree().paused = true` (`DaySummary.show_day()`, so the city keeps its state behind
	# it) and `.free()` on the node does not put it back — the whole suite shares one tree, so the
	# flag outlives this function. `HUD._teach_the_pause()` treats a paused tree as being *held*
	# rather than having stopped and resets its stand timer every frame, so the pause lesson simply
	# never fires again and the checks that assert its wording fail in a full run while passing on
	# their own. Restored rather than set to `false` for the same reason `main._close_the_pause()`
	# puts back the state it found: nothing here may decide the tree's paused state for a suite that
	# had its own reason to set one.
	t.get_tree().paused = saved_paused
	GameState.run_seed = saved_seed
	GameState.day = saved_day
	GameState.nerves = saved_nerves
	GameState.resistance_progress = saved_progress
	GameState.sabotage_done = saved_sabotage

## The brief is drawn to be noticed, and it is a static fact about the calendar day rather than a
## queue that empties once read — `docs/TODO.md`, M181, the resistance has a reason, and a task
## is one day: the day brief carries no task and no mark's words, only the morning's own line from
## `DaySummary._DAY_BRIEF`. `show_day()` reads it off `GameState.day` directly, whichever
## `DayResult` this is, so a lost day's own line reads exactly as it did this morning and a second
## call shows the same words again rather than nothing.
func _test_the_day_brief_shows_the_days_own_line(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	var saved_day := GameState.day
	GameState.day = 6

	var summary: CanvasLayer = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(summary)

	var expected: String = summary._DAY_BRIEF[6]
	summary.show_day(6, GameEnums.DayResult.LOST_CRYING, "She would not settle.", 2)
	t.check(summary._brief.text == expected,
			"the morning's own line for the calendar day, whichever DayResult this is")
	t.check(summary._brief.visible, "and the label showing it is actually on screen")

	summary.show_day(6, GameEnums.DayResult.WON, "", 3)
	t.check(summary._brief.text == expected, "and it reads exactly the same the second time")

	summary.free()
	# See the same restoration in `_test_day_finished_shows_the_summary_with_no_observer_in_the_
	# tree`, above: `show_day()` pauses the tree and freeing the node does not undo that.
	t.get_tree().paused = saved_paused
	GameState.day = saved_day

## M154: the summary carries the day's own clock at the instant it ended, phrased per outcome —
## `docs/TODO.md`'s M154 item, quoting the player: *"fell asleep after xx:xx or something like
## that"*. `elapsed_seconds` is a known value here (84.0, `1:24`) rather than anything a rig walks
## to, since what is under test is the phrasing `show_day()` builds from it, not the capture in
## `main._on_day_finished()`.
func _test_the_summary_shows_when_the_day_ended(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	var summary: CanvasLayer = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(summary)

	summary.show_day(4, GameEnums.DayResult.WON, "", 3, 84.0)
	t.check("She fell asleep after 1:24." in summary._body.text,
			"a won day names the clock it ended on ('%s')" % summary._body.text)

	summary.show_day(4, GameEnums.DayResult.LOST_CRYING,
			"She started crying. There is no settling her now.", 2, 84.0)
	t.check("She started crying after 1:24. There is no settling her now." in summary._body.text,
			"a crying loss reads the clock into its own first sentence ('%s')"
					% summary._body.text)

	summary.show_day(4, GameEnums.DayResult.LOST_HARD_FAIL,
			"It never slowed down. You were in the road.", 1, 84.0)
	t.check("It never slowed down. You were in the road. After 1:24." in summary._body.text,
			"a hard fail keeps its own sentence whole, with the clock following it ('%s')"
					% summary._body.text)

	summary.show_day(4, GameEnums.DayResult.LOST_TIMEOUT, "Dusk. You are still out.", 3, 180.0)
	t.check("Dusk. You are still out." in summary._body.text,
			"a timeout still shows its own reason ('%s')" % summary._body.text)
	t.check(not "3:00" in summary._body.text,
			"and the day's own length is not printed back at it, since dusk already is the whole "
			+ "day ('%s')" % summary._body.text)

	summary.free()
	t.get_tree().paused = saved_paused

# ------------------------------------------------------- the resistance's own day ---

## Everything the resistance did on an attempt that failed is given back, and a win commits it.
## *"a lost day shouldn't retain the touch mark -- a task is only complete if it is done on the day
## that won. but also it should reset if lost so the player can try again"* — so the day-6 mark is
## not both kept and unrepeatable, which is what it was while `completed_resistance_steps` survived
## the nerve and `ResistanceSteps.for_day()` never offers a completed step twice. A task is one day
## now, so both halves — the mark and the task it unlocks — are touched (or not) on the same day.
##
## Drives `GameState` directly rather than through a director: the five fields are what the director
## reads to decide what today offers, and the sub-test below holds that it actually does.
func _test_a_lost_day_gives_the_resistance_back(t) -> void:
	var saved := _save_run()

	# The mark she found on the day she lost. Touching it granted no progress — it never does.
	GameState.start_run(SEED)
	GameState.day = 6
	GameState.begin_day()
	GameState.complete_resistance_step(1, false)
	t.check(GameState.completed_resistance_steps.has(1), "the rig actually touched the mark")
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(not GameState.completed_resistance_steps.has(1),
			"a mark touched on a lost day is untouched again")
	t.check(GameState.day == 6, "and the retry is the same day")
	var offered := ResistanceSteps.for_day(GameState.day, GameState.completed_resistance_steps,
			GameState.failed_resistance_steps, GameState.sabotage_available())
	t.check(offered != null and offered.index == 1,
			"so the day's own table offers the same mark again")

	# Both the mark and the task it unlocks, done on a day that is won, stand — and then a task
	# done on a day that is lost does not.
	GameState.start_run(SEED)
	GameState.day = 6
	GameState.begin_day()
	GameState.complete_resistance_step(1, false)
	GameState.complete_resistance_step(2, true)
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.day == 7 and GameState.completed_resistance_steps.has(1)
			and GameState.completed_resistance_steps.has(2),
			"a mark and its task, both done on a day that was won, stand, and the calendar moves")

	GameState.begin_day()
	GameState.complete_resistance_step(3, false)
	GameState.resistance_carrying_package = true
	GameState.fail_resistance_step(999)
	t.check(GameState.resistance_progress == 1, "yesterday's task counted; today's own mark has not")
	GameState.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	t.check(not GameState.completed_resistance_steps.has(3),
			"today's own mark, touched on the lost day, is on offer again")
	t.check(GameState.completed_resistance_steps.has(1) and GameState.completed_resistance_steps.has(2),
			"and yesterday's won mark and task still stand")
	t.check(not GameState.failed_resistance_steps.has(999),
			"a contact lost to its deadline is given back with the day")
	t.check(not GameState.resistance_carrying_package, "and the package is put down")
	t.check(GameState.day == 7, "on the same day, which is the one being retried")

	# The last night is no exception: the sabotage is an act on a day like any other.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.begin_day()
	GameState.sabotage_done = true
	GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(not GameState.sabotage_done,
			"the last night's sabotage is undone by losing the last night")

	# A win commits, so the next day's loss gives back what that win left rather than nothing.
	GameState.start_run(SEED)
	GameState.day = 6
	GameState.begin_day()
	GameState.complete_resistance_step(1, false)
	GameState.complete_resistance_step(2, true)
	GameState.finish_day(GameEnums.DayResult.WON)
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(GameState.completed_resistance_steps.has(2) and GameState.resistance_progress == 1,
			"a won day's own work is committed and survives the next day's loss")

	_restore_run(saved)

## The half a `GameState`-only test cannot see: that the *director* re-offers what the restored
## state says is untouched, in the place the day first put it. Its placement is drawn from
## `GameState.day_rng(day, "resistance")`, so a retry of the same day with the same run seed and an
## untouched step is the same alley — the mark is not merely on offer again, it is where she
## already knows to look.
func _test_the_retry_meets_the_same_mark_in_the_same_alley(t) -> void:
	var saved := _save_run()
	GameState.start_run(SEED)
	GameState.day = 6

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	GameState.begin_day()
	var first := _resistance_director(t, city)
	first.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"), 300.0)
	var step := first.current_step()
	t.check(step != null and step.is_pickup, "day 6 puts the first chalk mark on offer")
	var where := first.contact_position()
	t.check(where != Vector2.INF, "and the rig knows where it is")
	GameState.complete_resistance_step(step.index, step.grants_progress)
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)

	GameState.begin_day()
	var retry := _resistance_director(t, city)
	retry.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"), 300.0)
	t.check(retry.current_step() != null and retry.current_step().index == step.index,
			"the retry is offered the same step the lost attempt was")
	t.close_to(retry.contact_position().distance_to(where), 0.0,
			"in the same alley, from the same seed", 0.01)

	first.free()
	retry.free()
	city.free()
	_restore_run(saved)

func _resistance_director(t, city: City) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	return director

## `GameState` is an autoload and the whole suite shares one, so anything that starts a run puts
## back what it found. The same shape `tests/test_resistance.gd` uses, over the run-level fields
## these tests write rather than the resistance's alone.
func _save_run() -> Dictionary:
	return {
		"seed": GameState.run_seed,
		"day": GameState.day,
		"nerves": GameState.nerves,
		"ending": GameState.ending,
		"progress": GameState.resistance_progress,
		"sabotage": GameState.sabotage_done,
		"package": GameState.resistance_carrying_package,
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
	}

func _restore_run(saved: Dictionary) -> void:
	GameState.run_seed = saved["seed"]
	GameState.day = saved["day"]
	GameState.nerves = saved["nerves"]
	GameState.ending = saved["ending"]
	GameState.resistance_progress = saved["progress"]
	GameState.sabotage_done = saved["sabotage"]
	GameState.resistance_carrying_package = saved["package"]
	GameState.completed_resistance_steps = saved["completed"]
	GameState.failed_resistance_steps = saved["failed"]
