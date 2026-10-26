extends RefCounted
## The run's flow through its screens (`RunFlow`): what each screen's continue leads to, and that a
## continue with no screen up leads nowhere.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEED := 4242
## How many frames a boot may take to reach its first day before the test gives up on it.
const BOOT_FRAMES := 30

func run(t) -> void:
	_test_each_screen_continues_to_its_step(t)
	_test_a_day_end_raises_the_screen_its_end_asks_for(t)
	_test_a_lost_section_raises_its_outcome_or_ends_the_run(t)
	_test_an_authored_scene_plays_again_from_every_screen(t)
	_test_only_a_run_stands_behind_its_own_escape(t)
	_test_the_escape_screens_hold_esc_back_only_in_a_section(t)
	_test_the_observers_hear_the_spec_begun_and_planned(t)
	await _test_a_tap_then_a_key_continue_once(t)

# ------------------------------------------------------------ the transitions ---

## Every mode's continue: the step `main` carries out, and the mode that step leaves the run in. A
## mode with no screen up answers nothing and stays where it is.
func _test_each_screen_continues_to_its_step(t) -> void:
	var M := RunFlow.Mode
	var S := RunFlow.Step
	var cases := [
		[M.BRIEF, S.ENGAGE, M.WALKING],
		[M.DAY_OVER, S.NEXT_DAY, M.WALKING],
		[M.BACK_TO_CHECKPOINT, S.CARRY_TO_CHECKPOINT, M.RELOADING],
		[M.INTO_ESCAPE, S.RELOAD_SCENE, M.RELOADING],
		[M.SECTION_LOST, S.RETRY_SECTION, M.BRIEF],
		[M.RUN_OVER, S.SHOW_ENDING, M.ENDING],
		[M.ENDING, S.RESTART_RUN, M.RELOADING],
		[M.EPILOGUE, S.RESTART_RUN, M.RELOADING],
		[M.BOOTING, S.NONE, M.BOOTING],
		[M.TITLE, S.NONE, M.TITLE],
		[M.WALKING, S.NONE, M.WALKING],
		[M.RELOADING, S.NONE, M.RELOADING],
	]
	t.check(cases.size() == M.size(), "every mode is asked (%d of %d)" % [cases.size(), M.size()])
	for case: Array in cases:
		var flow := RunFlow.new()
		flow.mode = case[0]
		var step := flow.continued()
		t.check(step == case[1] and flow.mode == case[2],
				"%s continues to %s and leaves %s (got %s, %s)" % [M.keys()[case[0]],
				S.keys()[case[1]], M.keys()[case[2]], S.keys()[step], M.keys()[flow.mode]])

## What `DayDirector.finish_day()` settled picks the screen: handed over before gone back before
## run over, since one end can carry only one of them, and an ordinary end otherwise.
func _test_a_day_end_raises_the_screen_its_end_asks_for(t) -> void:
	var M := RunFlow.Mode
	var ordinary := DayEnd.new()
	var handed := DayEnd.new()
	handed.hands_over_to_the_escape = true
	var back := DayEnd.new()
	back.goes_back = true
	var over := DayEnd.new()
	over.run_over = true
	for case: Array in [[ordinary, M.DAY_OVER], [handed, M.INTO_ESCAPE],
			[back, M.BACK_TO_CHECKPOINT], [over, M.RUN_OVER]]:
		var flow := RunFlow.new()
		flow.mode = M.WALKING
		flow.day_ended(case[0])
		t.check(flow.mode == case[1], "a day's end raises %s (got %s)"
				% [M.keys()[case[1]], M.keys()[flow.mode]])

## A lost section's outcome screen retries it; the one that ended the run leads to the ending.
func _test_a_lost_section_raises_its_outcome_or_ends_the_run(t) -> void:
	var flow := RunFlow.new()
	t.check(flow.section_lost(false) == RunFlow.Step.SHOW_OUTCOME
			and flow.mode == RunFlow.Mode.SECTION_LOST, "a lost section raises its outcome screen")
	t.check(flow.section_lost(true) == RunFlow.Step.SHOW_OUTCOME
			and flow.mode == RunFlow.Mode.RUN_OVER, "one that spent the last nerve ends the run")
	flow.escape_won()
	t.check(flow.mode == RunFlow.Mode.EPILOGUE, "and out of the city the epilogue is up")

## A scene recipe is one authored day: whatever screen it ends on, its continue plays the scene
## again, a lost section is its runtime's to retry, and its won last day hands over to nothing.
func _test_an_authored_scene_plays_again_from_every_screen(t) -> void:
	var M := RunFlow.Mode
	for mode: int in [M.BRIEF, M.DAY_OVER, M.BACK_TO_CHECKPOINT, M.INTO_ESCAPE, M.SECTION_LOST,
			M.RUN_OVER, M.ENDING, M.EPILOGUE]:
		var flow := RunFlow.new(true)
		flow.mode = mode
		t.check(flow.continued() == RunFlow.Step.RELOAD_SCENE and flow.mode == M.RELOADING,
				"an authored scene's %s plays the scene again" % M.keys()[mode])
	var authored := RunFlow.new(true)
	authored.mode = M.WALKING
	t.check(authored.continued() == RunFlow.Step.NONE, "but a continue with no screen up does not")
	t.check(authored.section_lost(false) == RunFlow.Step.RETRY_AUTHORED
			and authored.mode == M.WALKING, "a lost section is the scene's own to retry")
	t.check(not authored.escape_follows() and RunFlow.new().escape_follows(),
			"and only the game's own run hands a won last day over to the escape")

func _test_only_a_run_stands_behind_its_own_escape(t) -> void:
	var O := RunFlow.Opening
	for case: Array in [[O.FRESH, false], [O.RESUMED, false], [O.CARRIED_FROM_CHECKPOINT, false],
			[O.ESCAPE_HANDED_OVER, true], [O.ESCAPE_RESUMED, true], [O.ESCAPE_BY_FLAG, false]]:
		var flow := RunFlow.new()
		flow.opening = case[0]
		t.check(flow.escape_from_a_run() == case[1], "%s %s a run behind its escape"
				% [O.keys()[case[0]], "has" if case[1] else "has no"])

## Esc does not open over a section's brief or the epilogue, and does over a day's brief.
func _test_the_escape_screens_hold_esc_back_only_in_a_section(t) -> void:
	var M := RunFlow.Mode
	var section := DaySpec.for_section(DaySpec.Section.BUILDING, 180.0, "Escape the building")
	for case: Array in [[section, M.BRIEF, true], [section, M.EPILOGUE, true],
			[section, M.SECTION_LOST, false], [section, M.WALKING, false],
			[DaySpec.for_day(3, 210.0), M.BRIEF, false]]:
		var flow := RunFlow.new()
		flow.spec = case[0]
		flow.mode = case[1]
		t.check(flow.escape_screen_waits() == case[2], "%s in %s %s Esc back" % [
				"a section" if case[0] == section else "a day", M.keys()[case[1]],
				"holds" if case[2] else "does not hold"])

## The spec begun is the one the observers hear, before and after it is planned.
func _test_the_observers_hear_the_spec_begun_and_planned(t) -> void:
	var flow := RunFlow.new()
	var heard: Array = []
	flow.day_started.connect(func(spec: DaySpec) -> void: heard.append(["started", spec]))
	flow.day_planned.connect(func(spec: DaySpec) -> void: heard.append(["planned", spec]))
	var spec := DaySpec.for_day(5, 210.0)
	flow.begin(spec)
	t.check(flow.spec == spec and heard == [["started", spec]], "a day begun is announced with its spec")
	flow.planned()
	t.check(heard == [["started", spec], ["planned", spec]], "and planned with the same spec")

# ------------------------------------------------------------- the real boot ---

## A tap on the day's summary holds the continue button's pressed look for two frames before it
## continues (`DaySummary._acknowledge_and_continue()`), and a key continues at once, so a key
## pressed inside those two frames continues first and the tap's own continue arrives after the
## summary is gone. Only the first may start a day: the second reaches a run that is already walking.
func _test_a_tap_then_a_key_continue_once(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	t.get_tree().paused = true
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--seed", str(SEED), "--no-telemetry",
			"--no-title", "--no-save"]), "", true))
	t.add_child(main)
	var frames := 0
	while frames < BOOT_FRAMES and not (main._day and main._day.is_running()):
		await t.get_tree().process_frame
		frames += 1
	t.check(main._day != null and main._day.is_running(), "the boot reached day 1")
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(main._summary.is_showing(), "the lost day's summary is up")

	var started: Array[int] = []
	var count := func(day: int) -> void: started.append(day)
	EventBus.day_started.connect(count)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = _off_the_restart_button(main._summary)
	main._summary._unhandled_input(tap)
	var key := InputEventAction.new()
	key.action = &"ui_accept"
	key.pressed = true
	main._summary._unhandled_input(key)
	for _frame in 4:
		await t.get_tree().process_frame
	EventBus.day_started.disconnect(count)
	t.check(started == [1], "a tap and a key inside the tap's two frames start the day once (%s)"
			% [started])
	t.check(main._readout._spec == main._flow.spec,
			"the readout heard the day begun from the flow")

	t.remove_child(main)
	main.free()
	t.get_tree().paused = saved_paused

## A point on the screen whose tap is a continue, not the start of the held restart.
func _off_the_restart_button(summary: CanvasLayer) -> Vector2:
	var size: Vector2 = summary.get_viewport().get_visible_rect().size
	for x in range(1, 8):
		for y in range(1, 8):
			var at := Vector2(size.x * x / 8.0, size.y * y / 8.0)
			var design := ScreenOrientation.to_design_space(at, summary._wants_rotation())
			if not summary._restart_button.contains_design_point(design):
				return at
	return Vector2.ZERO
