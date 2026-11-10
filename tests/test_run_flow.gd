@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The run's flow through its screens (`RunFlow`): what each screen's continue leads to, and that a
## continue with no screen up leads nowhere.
##
## **Combined by composition, for this reason:** what `RunFlow` guarantees is where each screen's
## continue *leads*, and that is only visible in the real `main`, which owns the screens, the day and
## the escape that the continue hands over to; a stand-in for those would answer for itself what the
## suite asks of them. Each boot is on a cached generated city (`tests/city_map_cache.gd`).

const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const UI := preload("res://tests/ui_screens.gd")
const RecordingLog := preload("res://tests/recording_log.gd")
const SEED := 4242
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_run_flow_scratch.json"
## Whether the tree was paused before a boot, put back once it is shut down.
var _saved_paused := false
## The run the boot plays and the node standing for the tree's root it is parked in (`Boot.home_playing()`):
## made fresh for each boot, so no check reads or sets a run it shares with another.
var _run: RunState
var _home: Node
## The run log each boot is handed, open before the boot, whose headers say which walks it began.
var _run_log: RecordingLog

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
	flow.spec = spec
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
## is the scene's own, and the control lessons are skipped when the scene has learned them. The
## game's own run generates its map and teaches.
func _test_an_authored_scene_configures_the_rest_of_the_run(t) -> void:
	var own := RunFlow.new()
	t.check(not own.authored and own.authored_map() == null and not own.lessons_learned(),
			"the game's own run is configured by no scene")
	var scene := _LearnedScene.new()
	scene.map = CityMap.new(Vector2i(2, 2))
	var flow := RunFlow.new()
	flow.author(scene)
	t.check(flow.authored and flow.scene == scene, "authoring the flow configures it with the scene")
	t.check(flow.authored_map() == scene.map, "the city is built on the scene's own map")
	t.check(flow.lessons_learned(), "and the lessons the scene has learned are not taught")
	scene.free()

## An authored scene that brings its own map and has learned the control lessons.
class _LearnedScene extends AuthoredScene:
	var map: CityMap

	## Overrides AuthoredScene.city_map.
	func city_map() -> CityMap:
		return map

	## Overrides AuthoredScene.lessons_learned.
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

## The spec begun is the one the observers hear, at the moments the day director tells the flow of:
## begun, its world as it stands with whether it is a retry, and planned with that world once the
## director has started it. An authored scene's walk is never announced planned, and what its setup
## could not stand is handed back.
func _test_the_observers_hear_the_spec_begun_and_planned(t) -> void:
	var run := RunState.new()
	var scene := AuthoredScene.new()
	for authored: bool in [false, true]:
		var flow := RunFlow.new(scene if authored else null)
		var heard: Array = []
		flow.day_started.connect(func(spec: DaySpec) -> void: heard.append(["started", spec]))
		flow.world_stood.connect(func(spec: DaySpec, world: DayWorld, restarted: bool) -> void:
			heard.append(["stood", spec, world, restarted]))
		flow.day_planned.connect(func(spec: DaySpec, world: DayWorld) -> void:
			heard.append(["planned", spec, world]))
		var director := _HeardDirector.new(run, heard)
		var spec := DaySpec.for_section(DaySpec.Section.CITY, 60.0) if authored \
				else DaySpec.for_day(5, 210.0)
		var errors := flow.start(director, spec, authored)
		var world := director.world
		if authored:
			t.check(flow.spec == spec and heard == [["started", spec], ["stood", spec, world, true],
					["director", spec]] and errors == director.problems, "an authored walk is "
					+ "begun and stood, never planned, and hands back what did not stand (%s)"
					% [heard])
		else:
			t.check(flow.spec == spec and heard == [["started", spec], ["stood", spec, world, false],
					["director", spec], ["planned", spec, world]], "a day is announced begun, stood "
					+ "and planned with its spec and its world (%s)" % [heard])
	scene.free()

## A day director that tells the flow a walk has begun and its world stands, as the real one does,
## notes being asked to start it, and starts nothing.
class _HeardDirector extends DayDirector:
	var _heard: Array
	var problems: Array[String] = ["a problem"]
	## The world it says stands.
	var world := DayWorld.new()

	func _init(run: RunState, heard: Array) -> void:
		super(run.calendar, run.facts, run.attempt_spend, RunConfig.parse(PackedStringArray(), "", true))
		_heard = heard

	## Overrides DayDirector.start.
	func start(the_spec: DaySpec, started := Callable(), stood := Callable()) -> Array[String]:
		started.call()
		stood.call(world)
		_heard.append(["director", the_spec])
		return problems

# ------------------------------------------------------------- the real boot ---

## A tap on the day's summary holds the continue button's pressed look for two frames before it
## continues (`DaySummary._acknowledge_and_continue()`), and a key continues at once, so a key
## pressed inside those two frames continues first and the tap's own continue comes due after the
## screen it was meant for is gone. Only the first may move the run on: the tap's is dropped.
##
## **Booted and driven as a player drives it** (`tests/booted_main.gd`): the screens are read off
## what they show (the summary up, its continue shown or not, the day's clock running) and pressed
## through the viewport, the tap on the continue button and the key as an action event.
func _test_a_tap_then_a_key_continue_once(t) -> void:
	var booted: Boot.Booted = await _boot(t, ["--no-title"])
	var main := booted.main
	var day := Boot.day(main)
	t.check(day != null and day.is_running(), "the boot reached day 1")
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(Boot.summary(main).is_showing(), "the lost day's summary is up")

	var before := _walks_begun()
	await _tap_then_key(t, main)
	var started := _walks_begun().slice(before.size())
	t.check(started.size() == 1 and started[0].begins_with("begin_day 1 "),
			"a tap and a key inside the tap's two frames start the day once (%s)" % [started])

	# Every reload goes through one function, which the held restart calls straight from the walk
	# (the pause screen's restart) as an authored scene failing its own retry does: the flow says
	# RELOADING whichever way it came, and the walk's tick, which counts only while the flow says
	# WALKING (`main._physics_process()`), stops with the reload asked for. The reload is the hand-in
	# `main` takes in place of reloading the runner's scene, and the tree it unpauses keeps running.
	var reloads: Array[int] = []
	main.use_reload(func() -> void: reloads.append(1))
	t.get_tree().paused = false
	var ticks := _run.header.play_ticks
	await _physics_frames(t, 4)
	t.check(_run.header.play_ticks > ticks, "the walk's tick counts while she walks (%d to %d)"
			% [ticks, _run.header.play_ticks])
	Boot.pause(main).restart_requested.emit()
	t.check(reloads.size() == 1, "a restart from the walk asks for one reload (%d)" % reloads.size())
	ticks = _run.header.play_ticks
	await _physics_frames(t, 4)
	t.check(_run.header.play_ticks == ticks and not t.get_tree().paused,
			"and leaves the flow RELOADING: the walk's tick no longer counts, with the tree running"
			+ " (%d to %d)" % [ticks, _run.header.play_ticks])
	_shut_down(t, booted)

## A hard run's last nerve: the run-over screen's continue raises the ending, and the tap's own
## continue must not then reach the ending and restart the run before it has been seen. The ending
## is the summary with no continue on it (`DaySummary.show_summary()` hides it on an ending).
func _test_a_tap_then_a_key_on_the_run_over_screen_show_the_ending(t) -> void:
	var booted: Boot.Booted = await _boot(t, ["--no-title"])
	var main := booted.main
	var reloads: Array[int] = []
	main.use_reload(func() -> void: reloads.append(1))
	_run.calendar.choose_mode(true)
	_run.header.nerves = 1
	EventBus.hard_fail_triggered.emit("car_strike")
	var summary := Boot.summary(main)
	t.check(summary.is_showing() and _continue_shown(main) and _run.header.nerves == 0,
			"the run-over screen is up")
	await _tap_then_key(t, main)
	t.check(summary.is_showing() and not _continue_shown(main) and reloads.is_empty(),
			"the ending is up and the run not restarted (continue shown %s, %d reloads)"
			% [_continue_shown(main), reloads.size()])
	_shut_down(t, booted)

## A lost section's retry comes up behind its brief (PLAYTEST-94 10), and the tap's own continue
## must not then reach that brief and start the retry before it has been read.
func _test_a_tap_then_a_key_on_a_lost_section_show_the_retry_brief(t) -> void:
	var booted: Boot.Booted = await _boot(t, ["--start-escape", "city"])
	var main := booted.main
	var summary := Boot.summary(main)
	var day := Boot.day(main)
	t.check(summary.is_showing() and _title_of(main) == _city_words(),
			"the boot stands on the city section's brief")
	# The readout is told the section begun by the flow, and names it in its day line (an ordinary
	# day's line carries no title). It rebuilds its text a few times a second, so frames pass first.
	var readout := Boot.readout_label(main)
	for _frame in Boot.BOOT_FRAMES:
		if "seed" in readout.text:
			break
		await t.get_tree().process_frame
	t.check(("   " + Texts.ESCAPE_CITY.to_lower()) in readout.text,
			"the readout names the section the flow began (%s)" % readout.text.get_slice("\n", 1))
	await Boot.press_continue(t, main)
	t.check(not summary.is_showing() and day.is_running(),
			"and its continue walks the section")
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	t.check(summary.is_showing() and not day.is_running(), "the lost section's screen is up")
	var before := _walks_begun()
	await _tap_then_key(t, main)
	var started := _walks_begun().slice(before.size())
	t.check(summary.is_showing() and _title_of(main) == _city_words() and started.size() == 1,
			"the retry's brief is up rather than the retry walked past it (%d started, '%s')"
			% [started.size(), _title_of(main)])
	_shut_down(t, booted)

## The real `main.tscn` on `SEED` with `args`, unsaved and uncounted, once its boot has finished
## (its first day running, or behind its brief), with the tree paused as a screen leaves it.
func _boot(t, args: Array) -> Boot.Booted:
	_saved_paused = t.get_tree().paused
	t.get_tree().paused = true
	var words := ["--seed", str(SEED)]
	words.append_array(args)
	_run = RunState.new()
	_home = Boot.home_playing(t, _run)
	_run_log = RecordingLog.new()
	_run_log.begin_run(SEED)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config(words),
			func(main: Node) -> void:
				main.use_sitting_home(_home)
				main.use_run_log(_run_log),
			false, MapCache.source())
	t.get_tree().paused = true
	return booted

## A tap on the continue button, then a key inside the two frames the tap's acknowledgement holds
## open, both pushed through the viewport, then long enough for the tap's own continue to come due.
## The screen is let lay itself out first, so the button stands where it is drawn.
func _tap_then_key(t, main: Node2D) -> void:
	var summary := Boot.summary(main)
	await UI.frames(t)
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	var key := InputEventAction.new()
	key.action = &"ui_accept"
	key.pressed = true
	UI.push(summary, key)
	for _frame in 4:
		await t.get_tree().process_frame

## What the summary's title says: a section's brief is titled with the section's own words, its
## outcome screen with what ended it.
func _title_of(main: Node2D) -> String:
	return (Boot.summary(main).get_node("Root/Center/Lines/Title") as Label).text

## The escape city section's own words, which its brief is titled with.
func _city_words() -> String:
	return Texts.ESCAPE_CITY

## Whether the summary shows its continue button: every screen but the ending does.
func _continue_shown(main: Node2D) -> bool:
	return UI.button(Boot.summary(main), "Continue").is_visible_in_tree()

## `count` physics ticks, waited on.
func _physics_frames(t, count: int) -> void:
	for _tick in count:
		await t.get_tree().physics_frame

## The walks the boot has begun so far, each the header the run log opened it with (`begin_day N`,
## or `begin_section N ...` for a section of the escape), in order.
func _walks_begun() -> Array[String]:
	var begun: Array[String] = []
	for line in _run_log.lines:
		if line.begins_with("begin_"):
			begun.append(line)
	return begun

func _shut_down(t, booted: Boot.Booted) -> void:
	booted.free_all()
	_run_log.free()
	_home.free()
	t.get_tree().paused = _saved_paused
