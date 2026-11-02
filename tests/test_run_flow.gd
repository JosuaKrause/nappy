extends RefCounted
## The run's flow through its screens (`RunFlow`): what each screen's continue leads to, and that a
## continue with no screen up leads nowhere.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEED := 4242
## How many frames a boot may take to reach its first day before the test gives up on it.
const BOOT_FRAMES := 30
## Whether the tree was paused before a boot, put back once it is shut down.
var _saved_paused := false

func run(t) -> void:
	_test_raising_a_brief_announces_it(t)
	_test_each_screen_continues_to_its_step(t)
	_test_a_continue_from_a_screen_the_run_has_left_leads_nowhere(t)
	_test_a_day_end_raises_the_screen_its_end_asks_for(t)
	_test_a_lost_section_raises_its_outcome_or_ends_the_run(t)
	_test_an_authored_scene_plays_again_from_every_screen(t)
	_test_an_authored_scene_configures_the_rest_of_the_run(t)
	_test_only_a_run_stands_behind_its_own_escape(t)
	_test_the_escape_screens_hold_esc_back_only_in_a_section(t)
	_test_the_observers_hear_the_spec_begun_and_planned(t)
	await _test_a_tap_then_a_key_continue_once(t)
	await _test_a_tap_then_a_key_on_the_run_over_screen_show_the_ending(t)
	await _test_a_tap_then_a_key_on_a_lost_section_show_the_retry_brief(t)

# ------------------------------------------------------------ the transitions ---

## A brief raised tells whoever listens which day or section it leads into, so a dev rig can answer it.
func _test_raising_a_brief_announces_it(t) -> void:
	var flow := RunFlow.new()
	var heard: Array[DaySpec] = []
	flow.brief_opened.connect(func(spec: DaySpec) -> void: heard.append(spec))
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 60.0)
	flow.begin(spec)
	flow.open_brief()
	t.check(heard.size() == 1 and heard[0] == spec and flow.mode == RunFlow.Mode.BRIEF,
			"raising a brief announces it with the spec it leads into")

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
		var step := flow.continued(case[0])
		t.check(step == case[1] and flow.mode == case[2],
				"%s continues to %s and leaves %s (got %s, %s)" % [M.keys()[case[0]],
				S.keys()[case[1]], M.keys()[case[2]], S.keys()[step], M.keys()[flow.mode]])

## The screen's continue carries the mode it was raised in, and the flow answers by it: a continue
## from a screen the run has already left — a day's summary once the next day is being walked, a
## run-over screen once the ending is up — leads nowhere and moves nothing.
func _test_a_continue_from_a_screen_the_run_has_left_leads_nowhere(t) -> void:
	var M := RunFlow.Mode
	for case: Array in [[M.DAY_OVER, M.WALKING], [M.RUN_OVER, M.ENDING], [M.SECTION_LOST, M.BRIEF],
			[M.BRIEF, M.WALKING]]:
		var flow := RunFlow.new()
		flow.mode = case[1]
		t.check(flow.continued(case[0]) == RunFlow.Step.NONE and flow.mode == case[1],
				"a continue raised in %s, with the run in %s, leads nowhere" % [M.keys()[case[0]],
				M.keys()[case[1]]])

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
	var scene := AuthoredScene.new()
	for mode: int in [M.BRIEF, M.DAY_OVER, M.BACK_TO_CHECKPOINT, M.INTO_ESCAPE, M.SECTION_LOST,
			M.RUN_OVER, M.ENDING, M.EPILOGUE]:
		var flow := RunFlow.new(scene)
		flow.mode = mode
		t.check(flow.continued(mode) == RunFlow.Step.RELOAD_SCENE and flow.mode == M.RELOADING,
				"an authored scene's %s plays the scene again" % M.keys()[mode])
	var authored := RunFlow.new(scene)
	authored.mode = M.WALKING
	t.check(authored.continued(M.WALKING) == RunFlow.Step.NONE,
			"but a continue with no screen up does not")
	t.check(authored.section_lost(false) == RunFlow.Step.RETRY_AUTHORED
			and authored.mode == M.WALKING, "a lost section is the scene's own to retry")
	t.check(not authored.escape_follows() and RunFlow.new().escape_follows(),
			"and only the game's own run hands a won last day over to the escape")
	scene.free()

## The rest of what an authored scene changes is asked of the flow it configures: the city's map
## is the scene's own, the escape's city plans no finale of its own, and the control lessons are
## skipped when the scene has learned them. The game's own run generates its map, plans its finale
## and teaches.
func _test_an_authored_scene_configures_the_rest_of_the_run(t) -> void:
	var own := RunFlow.new()
	t.check(not own.authored and own.authored_map() == null and own.plans_the_finale()
			and not own.lessons_learned(), "the game's own run is configured by no scene")
	var scene := _LearnedScene.new()
	scene.map = CityMap.new(Vector2i(2, 2))
	var flow := RunFlow.new()
	flow.author(scene)
	t.check(flow.authored and flow.scene == scene, "authoring the flow configures it with the scene")
	t.check(flow.authored_map() == scene.map, "the city is built on the scene's own map")
	t.check(not flow.plans_the_finale(), "the escape's city plans no finale of its own")
	t.check(flow.lessons_learned(), "and the lessons the scene has learned are not taught")
	scene.free()

## An authored scene that brings its own map and has learned the control lessons.
class _LearnedScene extends AuthoredScene:
	var map: CityMap

	func city_map() -> CityMap:
		return map

	func lessons_learned() -> bool:
		return true

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
## pressed inside those two frames continues first and the tap's own continue comes due after the
## screen it was meant for is gone. Only the first may move the run on: the tap's is dropped.
func _test_a_tap_then_a_key_continue_once(t) -> void:
	var main: Node2D = await _boot(t, ["--no-title"])
	t.check(main._day != null and main._day.is_running(), "the boot reached day 1")
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(main._summary.is_showing(), "the lost day's summary is up")

	var started: Array[int] = []
	var count := func(day: int) -> void: started.append(day)
	EventBus.day_started.connect(count)
	await _tap_then_key(t, main)
	EventBus.day_started.disconnect(count)
	t.check(started == [1], "a tap and a key inside the tap's two frames start the day once (%s)"
			% [started])
	t.check(main._readout._spec == main._flow.spec,
			"the readout heard the day begun from the flow")
	# Every reload goes through one function, which an authored scene failing its own retry calls
	# straight from the walk: the flow says RELOADING whichever way it came.
	main.use_reload(func() -> void: pass)
	main._reload_the_scene()
	t.check(main._flow.mode == RunFlow.Mode.RELOADING, "a reload from the walk leaves RELOADING (%s)"
			% RunFlow.Mode.keys()[main._flow.mode])
	_shut_down(t, main)

## A hard run's last nerve: the run-over screen's continue raises the ending, and the tap's own
## continue must not then reach the ending and restart the run before it has been seen.
func _test_a_tap_then_a_key_on_the_run_over_screen_show_the_ending(t) -> void:
	var main: Node2D = await _boot(t, ["--no-title"])
	var reloads: Array[int] = []
	main.use_reload(func() -> void: reloads.append(1))
	GameState.calendar.choose_mode(true)
	GameState.header.nerves = 1
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(main._flow.mode == RunFlow.Mode.RUN_OVER and main._summary.is_showing(),
			"the run-over screen is up")
	await _tap_then_key(t, main)
	t.check(main._flow.mode == RunFlow.Mode.ENDING and main._summary.is_showing()
			and reloads.is_empty(), "the ending is up and the run not restarted (%s, %d reloads)"
			% [RunFlow.Mode.keys()[main._flow.mode], reloads.size()])
	_shut_down(t, main)
	GameState.header.ending = GameEnums.Ending.NONE
	GameState.calendar.choose_mode(false)

## A lost section's retry comes up behind its brief (PLAYTEST-94 10), and the tap's own continue
## must not then reach that brief and start the retry before it has been read.
func _test_a_tap_then_a_key_on_a_lost_section_show_the_retry_brief(t) -> void:
	var main: Node2D = await _boot(t, ["--start-escape", "city"])
	t.check(main._flow.mode == RunFlow.Mode.BRIEF and main._summary.is_showing(),
			"the boot stands on the city section's brief")
	main._on_summary_continued(main._flow.mode)
	t.check(main._flow.mode == RunFlow.Mode.WALKING and main._day.is_running(),
			"and its continue walks the section")
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(main._flow.mode == RunFlow.Mode.SECTION_LOST and main._summary.is_showing(),
			"the lost section's screen is up")
	await _tap_then_key(t, main)
	t.check(main._flow.mode == RunFlow.Mode.BRIEF and main._summary.is_showing(),
			"the retry's brief is up rather than the retry walked past it (%s)"
			% RunFlow.Mode.keys()[main._flow.mode])
	_shut_down(t, main)
	GameState.facts.escape_section = DaySpec.Section.NONE

## The real `main.tscn` on `SEED` with `args`, unsaved and uncounted, once its first day or section
## is built (running, or behind its brief), with the tree paused as a screen leaves it.
func _boot(t, args: Array) -> Node2D:
	_saved_paused = t.get_tree().paused
	t.get_tree().paused = true
	var given := PackedStringArray(["--seed", str(SEED), "--no-telemetry", "--no-save"])
	given.append_array(PackedStringArray(args))
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(given, "", true))
	t.add_child(main)
	var frames := 0
	while frames < BOOT_FRAMES and not (main._day and main._day.is_running()) \
			and main._flow.mode != RunFlow.Mode.BRIEF:
		await t.get_tree().process_frame
		frames += 1
	t.get_tree().paused = true
	return main

## A tap off the held restart, then a key inside the two frames the tap's acknowledgement holds
## open, then long enough for the tap's own continue to come due.
func _tap_then_key(t, main: Node2D) -> void:
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

func _shut_down(t, main: Node2D) -> void:
	t.remove_child(main)
	main.free()
	t.get_tree().paused = _saved_paused

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
