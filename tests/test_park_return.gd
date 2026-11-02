extends RefCounted
## Day 12's walk home after the park is taken, played through the real transitions: the swing
## touched on a booted `Main`, the cordon closing round the park, the baby asleep, the day won or
## lost, the day's summary, and the next morning. *(azure-koala, finding 9: "day 12 after closing
## the park and walking back with sleeping baby softlocks the game".)*
##
## `tools/run.sh --route mark,task,calm,home` stops at the win, so it never shows the summary or the
## next dawn; this suite carries on through `Main._on_day_finished()` and
## `Main._on_summary_continued()` and asks what a softlock would be: the day that cannot end, the
## summary that cannot be left, or a morning that does not start (no running clock, a baby that is
## not awake, a cordon left from yesterday). Three cases, on a sweep of seeds:
## she asleep inside the park and leaving through the last gap with the baby asleep, the baby put to
## sleep elsewhere with the park taped behind her, and shut in with the baby asleep.
##
## `run()` snapshots the whole save first and puts it back last, and points `GameSave` at a scratch
## file, so nothing here leaks into the next suite or reaches the player's save.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEEDS: Array[int] = [4242, 11, 13]
const STEP := 1.0 / 60.0
## How long a check lets the cordon work before calling it stuck, in seconds of day.
const PATIENCE := 40.0
## How long after the swing she sets off, in the walking cases: time to see the officers.
const REACTION := 2.0
const _SCRATCH_PATH := "user://test_park_return_scratch.json"

func run(t) -> void:
	var baseline := GameSave.file_data(GameState, false)
	GameSave.set_path_override(_SCRATCH_PATH)
	for seed_value in SEEDS:
		_test_asleep_in_the_park_and_out_through_the_gap(t, seed_value)
		_test_asleep_elsewhere_with_the_park_taped_behind_her(t, seed_value)
		_test_shut_in_with_the_baby_asleep(t, seed_value)
	GameSave._clear_now()
	GameSave.set_path_override("")
	GameState.run_parts.restore_run_data(baseline)
	GameState.calendar.hard_mode = bool(baseline["hard_mode"])
	GameState.calendar.checkpoint = baseline["checkpoint"]

# ------------------------------------------------------------------ fixture ---

## A booted `Main` standing at day 12's dawn on `seed_value`, a normal run, with the mark read and
## the swing offered.
func _day_twelve(t, seed_value: int) -> Node2D:
	# `Main` rolls its own seed unless a command line or a save gives one: a save of this seed's run,
	# standing at day 12's dawn, is the way a test gives it, and is read back through the scratch
	# file this suite points `GameSave` at.
	GameState.start_run(seed_value)
	GameState.header.day = ResistanceSteps.swing_day()
	GameSave._write_now(GameState, true)
	var main: Node2D = MAIN_SCENE.instantiate()
	# A run with no flag at all, whatever this process's own command line says.
	main.configure(RunConfig.parse(PackedStringArray(), "", true, false, {}, false))
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	main._on_title_start(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.RIGHT)
	t.check(main._city.map.seed_used == seed_value, "seed %d is the city under test (%d)"
			% [seed_value, main._city.map.seed_used])
	t.check(GameState.header.day == ResistanceSteps.swing_day(), "booted at day %d (day %d)"
			% [ResistanceSteps.swing_day(), GameState.header.day])
	# A resumed run opens on the day's brief; leaving it is what puts her on the street.
	if main._flow.mode == RunFlow.Mode.BRIEF:
		main._on_summary_continued(main._flow.mode)
	t.check(main._day.is_running() and not main._summary.is_showing(),
			"seed %d: day %d is under way" % [seed_value, GameState.header.day])
	var director: ResistanceDirector = main._resistance
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	return main

func _touch_the_swing(main: Node2D) -> Vector2:
	var director: ResistanceDirector = main._resistance
	var task := director.current_step()
	var swing := director.contact_position()
	main._player.global_position = swing
	director._on_contact_completed(task.index if task else -1)
	return swing

func _camera_on(main: Node2D) -> Callable:
	return func(row: EventDef, feet: Vector2) -> bool:
		var centre: Vector2 = main._player.global_position
		var view := Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		var box := EventFootprints.footprint_of(row)
		if not box.has_area():
			return view.has_point(feet)
		return view.intersects(Rect2(feet + box.position, box.size))

## The city's own view looked through about her, as the game's camera does, or about nothing: what
## the cordon's officers are placed out of sight of (`SpawnSiting`'s).
func _look(main: Node2D, camera: bool) -> void:
	var at: Vector2 = main._player.global_position
	main._city.events.visible_view().look(
			Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0) if camera
			else Rect2(), null)

## One frame of the day: the happenings and the day's own clock and win check.
func _frame(main: Node2D, shows: Callable) -> void:
	var happenings: ResistanceHappenings = main._resistance._happenings
	_look(main, shows.is_valid())
	happenings.tick(STEP, main._player.global_position, Vector2.ZERO)
	main._day.tick(STEP)

## Walks her toward `to` at the walking speed for `seconds`, a frame at a time.
func _walk(main: Node2D, to: Vector2, seconds: float, shows: Callable) -> void:
	var frames := int(seconds / STEP)
	for i in frames:
		if not main._day.is_running():
			return
		var here: Vector2 = main._player.global_position
		main._player.global_position = here.move_toward(to, Tuning.WALK_SPEED * STEP)
		_frame(main, shows)

## Waits out the cordon with her where she stands, until it closes or `PATIENCE` runs out.
func _wait_for_the_close(main: Node2D, shows: Callable) -> void:
	var happenings: ResistanceHappenings = main._resistance._happenings
	var waited := 0.0
	while happenings.is_closing() and main._day.is_running() and waited < PATIENCE:
		_frame(main, shows)
		waited += STEP

## Out through the last gap, `REACTION` after the touch, and on a tile's width past the tape.
func _walk_out_through_the_gap(main: Node2D, swing: Vector2, shows: Callable) -> void:
	var happenings: ResistanceHappenings = main._resistance._happenings
	_walk(main, swing, REACTION, shows)
	var exit := happenings.cordon.last_gap
	var out := exit + (exit - swing).normalized() \
			* (Tuning.CLOSURE_BARRIER_DEPTH + Tuning.TILE_SIZE)
	_walk(main, out, 20.0, shows)

## The day's end seen from the summary: it comes up, is left with one press, and the next morning
## is a running day 13 with everything of the cordon gone.
func _check_the_next_morning(t, main: Node2D, label: String) -> void:
	t.check(main._summary.is_showing(), "%s: the won day's summary is up" % label)
	var map: CityMap = main._city.map
	main._on_summary_continued(main._flow.mode)
	t.check(GameState.header.day == ResistanceSteps.swing_day() + 1,
			"%s: leaving the summary starts day %d (day %d)"
			% [label, ResistanceSteps.swing_day() + 1, GameState.header.day])
	t.check(not main._summary.is_showing() and not t.get_tree().paused,
			"%s: with the summary gone and the tree running" % label)
	t.check(main._day.is_running() and main._day.phase == GameEnums.DayPhase.WALKING,
			"%s: the new day is running and she is walking" % label)
	t.check(main._baby.state == GameEnums.BabyState.AWAKE,
			"%s: the baby wakes with the day" % label)
	t.check(main._resistance._happenings.cordon == null,
			"%s: no cordon stands in the new day" % label)
	var here: Vector2 = main._player.global_position
	t.check(here.distance_to(map.doorstep_world_position()) < Tuning.TILE_SIZE * 3.0,
			"%s: she stands at her own door (%s)" % [label, here])
	# And the day moves: a second of it ticks the clock down.
	var before: float = main._day.time_remaining
	main._day.tick(1.0)
	t.check(main._day.time_remaining < before, "%s: the clock runs" % label)

func _finish(t, main: Node2D) -> void:
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()

# -------------------------------------------------------------------- cases ---

## The baby falls asleep inside the park, the cordon still closing; she walks out through the last
## gap with her asleep, and home.
func _test_asleep_in_the_park_and_out_through_the_gap(t, seed_value: int) -> void:
	var label := "seed %d, asleep in the park" % seed_value
	var main := _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	var swing := _touch_the_swing(main)
	var happenings: ResistanceHappenings = main._resistance._happenings
	t.check(happenings.cordon != null, "%s: reaching the swing starts the cordon" % label)
	_frame(main, shows)
	main._baby.force_sleep()
	t.check(main._day.phase == GameEnums.DayPhase.RETURNING,
			"%s: asleep, the day is the walk home" % label)
	var results: Array = []
	main._day.day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	_walk_out_through_the_gap(main, swing, shows)
	_wait_for_the_close(main, shows)
	t.check(happenings.cordon.is_closed() and not happenings.cordon.trapped,
			"%s: the gap closes behind her, with her outside" % label)
	t.check(main._day.is_running() and results.is_empty(),
			"%s: the day is still on, the baby asleep (%s)" % [label, results])
	t.check(main._baby.state == GameEnums.BabyState.ASLEEP, "%s: and still asleep" % label)
	main._player.global_position = main._city.map.home_world_position()
	_frame(main, shows)
	t.check(results == [GameEnums.DayResult.WON], "%s: home with her asleep wins (%s)"
			% [label, results])
	_check_the_next_morning(t, main, label)
	_finish(t, main)

## Out first, settled elsewhere with the park taped behind her, then home: the rig's own route, on
## to the summary and the next morning.
func _test_asleep_elsewhere_with_the_park_taped_behind_her(t, seed_value: int) -> void:
	var label := "seed %d, settled outside" % seed_value
	var main := _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	var swing := _touch_the_swing(main)
	var happenings: ResistanceHappenings = main._resistance._happenings
	_walk_out_through_the_gap(main, swing, shows)
	_wait_for_the_close(main, shows)
	t.check(happenings.cordon.is_closed() and not happenings.cordon.trapped,
			"%s: the park is taped with her outside" % label)
	var results: Array = []
	main._day.day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	main._baby.force_sleep()
	main._player.global_position = main._city.map.home_world_position()
	_frame(main, shows)
	t.check(results == [GameEnums.DayResult.WON], "%s: home asleep wins (%s)" % [label, results])
	_check_the_next_morning(t, main, label)
	_finish(t, main)

## Standing in the park with the baby asleep as the last gap is taped: the day is lost to the
## cordon, the summary is left, and the day is played again from its dawn, with a cordon to come.
func _test_shut_in_with_the_baby_asleep(t, seed_value: int) -> void:
	var label := "seed %d, shut in asleep" % seed_value
	var main := _day_twelve(t, seed_value)
	var shows := _camera_on(main)
	_touch_the_swing(main)
	var happenings: ResistanceHappenings = main._resistance._happenings
	main._baby.force_sleep()
	var results: Array = []
	main._day.day_finished.connect(func(r: GameEnums.DayResult) -> void: results.append(r))
	_wait_for_the_close(main, shows)
	t.check(results == [GameEnums.DayResult.LOST_HARD_FAIL]
			and main._day.hard_fail_reason == ParkCordon.TRAPPED,
			"%s: shut in, the day is lost to the cordon (%s)" % [label, results])
	t.check(main._summary.is_showing(), "%s: the lost day's summary is up" % label)
	var day := GameState.header.day
	main._on_summary_continued(main._flow.mode)
	t.check(GameState.header.day == day and not main._summary.is_showing()
			and not t.get_tree().paused,
			"%s: leaving it plays day %d again (day %d)" % [label, day, GameState.header.day])
	t.check(main._day.is_running() and main._day.phase == GameEnums.DayPhase.WALKING
			and main._baby.state == GameEnums.BabyState.AWAKE,
			"%s: the retry runs with the baby awake" % label)
	t.check(happenings.cordon == null, "%s: no cordon stands at the retry's dawn" % label)
	_finish(t, main)
