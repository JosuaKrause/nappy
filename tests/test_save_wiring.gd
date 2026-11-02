extends RefCounted
## What `main` does with the save: the focus loss that writes nothing, the dawn a resumed boot writes,
## the title and the resume gate that lead to the day brief or the ending, the day engaged writing the
## run as under way, the day-14 hand-over that carries the save symbol over a reload, and the two
## orderings read off `main.gd`'s source, plus the three checks of what `main._save_now()` adds to a
## write. Split from `tests/test_save.gd` (the save file, its flush and its symbol, all through
## `GameSave` and `SaveIndicator`'s public calls) because every check here builds a script-only `main`
## and reaches its members. What stops them being converted is cost, not a missing seam: they are
## converted the way `tests/test_main.gd` is, by booting a real `main` (`main.configure()` with a
## windowed `RunConfig`, then `add_child`), pressing the title and the continue button with real input
## and letting real frames pass, with `Main.use_reload()` for the day-14 reload. The save symbol a
## booted `main` raises is found as its child. That work is in `tests-public-seams.md`'s remaining
## list, with this file's name on it.
##
## `GameSave` is pointed at a scratch file and handed the configuration of a windowed release run, so
## its ordinary `write()`, `try_resume()` and `clear()` reach it; `run()` puts both back.

const _SCRATCH_PATH := "user://test_save_wiring_scratch.json"

func run(t) -> void:
	t.gives_back_observers()
	var baseline := GameState.save_snapshot()
	GameSave.set_path_override(_SCRATCH_PATH)
	GameSave.configure(RunConfig.parse(PackedStringArray(), "", false, false, {}, false))
	GameSave.clear_when_a_run_ends()
	GameSave.clear()

	_test_focus_loss_never_charges_a_nerve(t)
	_test_focus_loss_and_window_close_write_nothing(t)
	_test_fresh_boot_writes_nothing_until_the_title_is_dismissed(t)
	_test_a_restart_writes_nothing_until_the_next_titles_dismissed(t)
	_test_a_game_closed_between_days_writes_nothing_at_opening(t)
	_test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t)
	_test_dismissing_a_fresh_titles_start_writes_the_save_under_way(t)
	_test_title_leads_to_the_day_brief_with_nothing_charged(t)
	_test_title_leads_to_the_day_brief_with_a_charged_nerve(t)
	_test_title_leads_to_the_ending_on_the_last_nerve(t)
	_test_main_builds_the_symbol_before_the_charge_that_can_end_the_run(t)
	_test_the_held_restart_deletes_the_save_before_the_run_log_closes(t)
	_test_the_hand_over_to_the_escape_carries_a_pending_save_over(t)
	_test_main_draws_nothing_for_a_refused_run(t)
	_test_main_shows_a_desktop_save_confirmed_at_once(t)
	_test_main_adds_nothing_to_what_the_bus_carried_to_the_symbol(t)

	GameSave.clear()
	GameSave.set_path_override("")
	GameSave.configure(null)
	GameState.restore_snapshot(baseline)
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.calendar.hard_mode = false
	GameState.calendar.checkpoint = {}

## `GameState` written to the scratch file the way a game writes it. Whether the write was kept.
func _saved(day_under_way: bool) -> bool:
	return GameSave.write(GameState, day_under_way) == GameSave.Result.CONFIRMED

var _operation := 5000

func _next_operation() -> int:
	_operation += 1
	return _operation

## The scratch file is put away around `callable`, so a test starts and leaves with no save.
func _with_a_scratch_save(callable: Callable) -> void:
	GameSave.clear()
	callable.call()
	GameSave.clear()

const _MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const _PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const _SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const _TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")

## A script-only `main`, the same shape `tests/test_main.gd`'s own focus-loss rig builds, with its
## `ReturnWindow`, whose departures open the pause — a bare `DayController` stands in for a live one.
func _build_bare_main(t) -> Node2D:
	var main: Node2D = _MAIN_SCRIPT.new()
	main._summary = _SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._pause = _PAUSE_SCENE.instantiate()
	main._pause.use_run(main._run)
	t.add_child(main._pause)
	main._title = _TITLE_SCENE.instantiate()
	main._title.use_run(main._run)
	t.add_child(main._title)
	main._no_focus_pause = false
	main._add_the_return_window(t.get_viewport())
	main._day = DayController.new()
	main._day.phase = GameEnums.DayPhase.WALKING
	return main

func _free_bare_main(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main._summary.queue_free()
	main._pause.queue_free()
	main._title.queue_free()
	main._day.free()
	main.free()

## Losing focus opens the pause and, under a real run, may write a save — but never through
## `GameState.calendar.finish_day()`. Only *opening a saved game* ever spends a nerve; continuing after a
## focus loss in the same session is free, which this asserts by the coarsest available proof: the
## numbers `finish_day()` would have touched do not move.
func _test_focus_loss_never_charges_a_nerve(t) -> void:
	var main := _build_bare_main(t)
	var day := GameState.header.day
	var nerves := GameState.header.nerves
	t.get_tree().paused = false

	main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open(), "focus loss still opens the pause, exactly as before this milestone")
	t.check(GameState.header.day == day and GameState.header.nerves == nerves,
			"and neither the day nor the nerve count moved — a focus loss alone never spends one")
	main._pause.close()

	_free_bare_main(t, main)

## **Neither focus loss nor a window close calls `_save_now()`.** Losing focus
## still opens the pause (asserted above) and a window close still ends the telemetry log, but
## neither touches the save any more — only a day starting, or its own brief or end-of-day message
## coming up, changes what a save holds (docs/MECHANICS.md, "Saving and resuming"). Forced through
## `_with_a_scratch_save()` so a stray write here would actually land and be caught; without it
## `uses_save()` already answers `false` under the headless runner regardless of what `main` calls,
## and the assertion would pass whether or not the write survived. `main._quit()` makes the same
## change on its one remaining line, but it also calls `get_tree().quit()`, which would end this
## test run rather than this test — there is no way to call it from here at all, so that half is
## read off the diff rather than asserted.
func _test_focus_loss_and_window_close_write_nothing(t) -> void:
	_with_a_scratch_save(func() -> void:
		var main := _build_bare_main(t)
		t.get_tree().paused = false

		main._return_window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		t.check(main._pause.is_open(), "focus loss still opens the pause")
		t.check(not GameSave.has_save(), "but writes nothing")
		main._pause.close()

		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		t.check(not GameSave.has_save(), "and neither does the window-close notification")

		_free_bare_main(t, main)
	)

## The fuller rig `_on_title_start()`/`_show_the_resume_gate()`/`_on_summary_continued()` need to
## run for real: the same touch/camera/city/hud/edge/status scaffolding
## `_test_dismissing_a_fresh_titles_start_writes_the_save_under_way()` needs to drive
## `_engage_the_day()`, plus a real `DaySummary` scene instance so `show_summary()`'s own labels
## have something to populate into.
func _bare_gate_main(t) -> Node2D:
	var main: Node2D = _MAIN_SCRIPT.new()
	main._add_touch_controls()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	main._player = stroller
	main._city = City.new()
	main._hud = CanvasLayer.new()
	main._edge_layer = CanvasLayer.new()
	main._status = Label.new()
	main._title = TitleScreen.new()
	main._summary = _SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	return main

func _free_gate_main(t, main: Node2D) -> void:
	t.get_tree().paused = false
	var stroller: Node = main._player
	main._status.free()
	main._title.free()
	main._edge_layer.free()
	main._hud.free()
	main._city.free()
	main._summary.queue_free()
	main.free()
	stroller.free()

## **The review finding this test exists for.** `_start_day()` used to write its own dawn
## unconditionally, so merely opening the game — before the title was ever dismissed — created a
## save for a fresh day 1 nobody had touched, with the symbol flashing behind the title on every
## launch and the *next* launch showing a day brief for a day nobody played. `_resume` is empty for
## a fresh run, so `_write_dawn_for_a_resumed_run()`'s own guard means the call does nothing at
## all — asserted directly, against the function itself, rather than the whole world `_start_day()`
## needs to run for real.
func _test_fresh_boot_writes_nothing_until_the_title_is_dismissed(t) -> void:
	GameState.start_run(345)
	_with_a_scratch_save(func() -> void:
		var main: Node2D = _MAIN_SCRIPT.new()
		t.check(main._resume.is_empty(), "a fresh run's own default — nothing to resume")

		main._write_dawn_for_a_resumed_run()
		t.check(not GameSave.has_save(), "a fresh boot writes nothing at all")

		main.free()
	)

## The held restart reaches the same case as a fresh boot: `main._restart_run()`'s own
## `GameSave.clear()` leaves `GameSave.try_resume()` nothing to find on the reload that follows, so
## the reloaded boot's own `_resume` is empty and its dawn write does nothing either — asserted by
## driving `try_resume()` for real against a save that was just cleared, the same shape the reload
## itself reaches.
func _test_a_restart_writes_nothing_until_the_next_titles_dismissed(t) -> void:
	GameState.start_run(346)
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "a save exists before the restart")
		GameSave.clear()
		t.check(not GameSave.has_save(), "the held restart clears it")

		var resume := GameSave.try_resume(GameState)
		t.check(resume.is_empty(), "the reloaded boot's own try_resume() finds nothing to resume")

		var main: Node2D = _MAIN_SCRIPT.new()
		main._resume = resume
		main._write_dawn_for_a_resumed_run()
		t.check(not GameSave.has_save(), "and its own dawn write does nothing either")

		main.free()
	)

## *"either it saves with one less nerve and a cleared "during active game" flag. or you defer
## saving to the actual day start"* — a game closed between days charged nothing when it was
## reopened, its file already says `day_under_way: false`, and opening it writes nothing: no file
## is rewritten and no symbol is drawn. A game closed with its day under way is the case the next
## test covers, which does write.
func _test_a_game_closed_between_days_writes_nothing_at_opening(t) -> void:
	GameState.start_run(348)
	GameState.header.day = 4
	GameState.calendar.begin_day()
	_with_a_scratch_save(func() -> void:
		t.check(_saved(false), "the save the end-of-day message wrote")
		var resume := GameSave.try_resume(GameState)
		t.check(resume.get("day_under_way") == false, "the load finds the day not under way")
		# Taken away, so a rewrite shows as a file coming back rather than as a same-looking file.
		GameSave.clear()
		# Built after the save and its removal, which each raise the symbol: what is checked below is
		# that opening the save raises nothing more.
		var indicator := SaveIndicator.new()
		t.add_child(indicator)

		var main: Node2D = _MAIN_SCRIPT.new()
		main._resume = resume
		main._save_indicator = indicator
		main._write_dawn_for_a_resumed_run()
		t.check(not GameSave.has_save(), "opening it writes nothing")
		t.check(not indicator.is_showing(), "and the symbol stays dark")

		main.free()
		indicator.free()
	)

## A resumed boot with a charged nerve: `main._ready()` calls `GameState.calendar.finish_day()` (driven here
## directly, the same as `_test_day_under_way_load_costs_one_nerve()` above) before `_start_day()`
## and this write ever run, so the reduced nerve count is already the live `GameState`'s own by the
## time this lands — and it is what the write carries to disk, with `day_under_way: false`, before
## the title or the day brief behind it is ever shown.
func _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t) -> void:
	GameState.start_run(347)
	GameState.header.day = 4
	GameState.header.nerves = 5
	GameState.calendar.begin_day()
	t.check(_saved(true), "the original mid-day save")

	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way") == true, "the load finds a day under way")
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.header.nerves == 4, "main._ready() charges its one nerve before _start_day() runs")

	_with_a_scratch_save(func() -> void:
		var main: Node2D = _MAIN_SCRIPT.new()
		main._resume = resume
		main._write_dawn_for_a_resumed_run()

		var after := GameSave.try_resume(GameState)
		t.check(after.get("day_under_way") == false,
				"the boot write says nothing has been played in the retry yet")
		t.check(GameState.header.nerves == 4,
				"and the reduced nerve count the load already charged is what landed on disk")

		main.free()
	)

## **The regression this whole commit exists for.** A day engaged with no write beside it would
## leave the save on disk saying `day_under_way: false` — correctly written at dawn, for a day
## nobody had touched yet — for the entire time between the title closing and the next moment
## something else happened to write. A crash, a force-kill, or a backgrounded mobile tab whose page
## is simply discarded never sends a notification at all any more (see the two writes above), so a
## day playtested start to finish and killed right after would have resumed for free were
## `_engage_the_day()` not the one place `_on_title_start()` (with no resume) reaches to write
## immediately. Asserted directly: dismissing a fresh day 1's title, with nothing else run at all,
## already leaves the save on disk saying the day is under way.
func _test_dismissing_a_fresh_titles_start_writes_the_save_under_way(t) -> void:
	# A fresh run, since an earlier test in this suite may have left `GameState.header.ending` set —
	# `GameSave.write()` refuses once an ending is set, on purpose, and `start_run()` is the
	# same reset an ordinary day 1 boot itself performs before ever reaching the title.
	GameState.start_run(123)
	_with_a_scratch_save(func() -> void:
		var main := _bare_gate_main(t)
		t.check(main._resume.is_empty(), "a fresh run carries no resume")

		t.check(not GameSave.has_save(), "nothing on disk before the title is dismissed")
		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._flow.mode == RunFlow.Mode.WALKING,
				"no day brief for a fresh run — she is playing already")
		var saved := GameSave.try_resume(GameState)
		t.check(saved.get("day_under_way") == true,
				"and the save on disk already says so, with nothing else run at all")

		_free_gate_main(t, main)
	)

## The title→day-brief path with nothing charged: `_resume` says the save was written at a day's
## own summary or at an earlier day brief (`day_under_way: false`), so pressing start on the title
## shows the day brief with no lost-day note, and continuing from it — `_on_summary_continued()` on
## a brief (`RunFlow.Mode.BRIEF`) — is the moment the save actually says the day is under way.
## Also the "second open of a nothing-played-yet save costs nothing" case: nothing here writes
## between the title closing and the day brief's own continue, so a kill anywhere in between finds
## exactly what the screen is already showing — see `_show_the_resume_gate()`'s own doc for why.
func _test_title_leads_to_the_day_brief_with_nothing_charged(t) -> void:
	GameState.start_run(234)
	GameState.header.day = 7
	GameState.header.nerves = 5
	_with_a_scratch_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": false}
		_saved(false)

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._summary.is_showing(), "the day brief shows instead of starting the day outright")
		t.check(not main._summary._note.visible, "no lost-day note — the load cost nothing")
		t.check(main._flow.mode == RunFlow.Mode.BRIEF,
				"and the day brief's own continue still has to engage the day")
		t.check(GameSave.try_resume(GameState).get("day_under_way") == false,
				"showing the day brief writes nothing new — the dawn write already said this")

		main._on_summary_continued(main._flow.mode)
		t.check(not main._summary.is_showing(), "continuing dismisses the brief")
		t.check(main._flow.mode == RunFlow.Mode.WALKING, "and the gate is spent")
		t.check(GameSave.try_resume(GameState).get("day_under_way") == true,
				"the day is engaged, which the save now says")

		_free_gate_main(t, main)
	)

## The same path with a nerve charged: the day brief carries `Texts.RESUMED_DAY_LOST`.
func _test_title_leads_to_the_day_brief_with_a_charged_nerve(t) -> void:
	GameState.start_run(235)
	_with_a_scratch_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": true}

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._summary._note.visible
				and main._summary._note.text == Texts.RESUMED_DAY_LOST,
				"the day brief carries the lost-day line the load itself charged")

		_free_gate_main(t, main)
	)

## The last-nerve case: the load's own `GameState.calendar.finish_day()` call in `_ready()` (not driven here
## — this rig starts past it, with the run's ending already set the way that call would have left it)
## spent the run's last nerve, so pressing start on the title shows the ending directly — the same
## screen and the same `_on_summary_continued()` path any other run-ending reaches — rather than
## the day brief. `GameState.header.ending` is already set by the time this is reached, so
## `GameSave.write()`'s own refusal (see its doc) means nothing here writes at all, gate or no
## gate.
func _test_title_leads_to_the_ending_on_the_last_nerve(t) -> void:
	_with_a_scratch_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": true}
		var ending := GameState.header.ending
		GameState.header.ending = GameEnums.Ending.BAD

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._flow.mode == RunFlow.Mode.ENDING,
				"the ending is shown rather than the day brief, so there is no day brief for a later"
				+ " continue to engage")
		t.check(not GameSave.has_save(), "a run that has ended writes nothing, on this path either")

		GameState.header.ending = ending
		_free_gate_main(t, main)
	)

## `main._ready()` charges a resumed run before the HUD and the screens exist, so the symbol has to
## exist before the charge or the deletion it makes is announced to nobody. Read from the source,
## since a booted `main` is not something this suite builds: `_raise_save_indicator()` comes before
## the `finish_day` call that charges the run.
func _test_main_builds_the_symbol_before_the_charge_that_can_end_the_run(t) -> void:
	var text := FileAccess.get_file_as_string("res://src/main.gd")
	var raised := text.find("\t_raise_save_indicator()\n\tif _resume.get(\"day_under_way\"")
	var charged := text.find("_run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)")
	t.check(raised != -1 and charged != -1 and raised < charged,
			"the symbol is raised right before the resumed run's charge")

## `main._restart_run()` deletes the save before the run session closes the run log, so the
## "deleted the save" line is written into the run being abandoned. Read from the source, since a
## booted `main` is not something this suite builds.
func _test_the_held_restart_deletes_the_save_before_the_run_log_closes(t) -> void:
	var text := FileAccess.get_file_as_string("res://src/main.gd")
	var start := text.find("func _restart_run() -> void:")
	var cleared := text.find("\tGameSave.clear()\n", start)
	var closed := text.find("\t\t_session.close()\n", start)
	t.check(start != -1 and cleared != -1 and closed != -1 and cleared < closed,
			"the restart's deletion is logged before the log is closed")

## **The day-14 hand-over's reload to the escape, through `main._on_summary_continued()` itself.**
## Day 14's own save (A) is written as its summary appears and may still be waiting for the browser
## when the player continues. The hand-over must carry the symbol to the tree's root like the held
## restart does, so it outlives the reload, keeps showing A, and the escape's boot adopts it. There
## the escape's first save (B) begins, and A's answer, arriving late, must settle A and never B: B's
## failure afterwards still strikes the symbol. The reload itself goes to what `use_reload()` was handed, since a
## real one would throw away the test runner's own scene.
func _test_the_hand_over_to_the_escape_carries_a_pending_save_over(t) -> void:
	var tree: SceneTree = t.get_tree()
	var home := Node.new()
	t.add_child(home)
	SaveIndicator.use_home(home)
	var section := GameState.facts.escape_section
	GameState.facts.escape_section = DaySpec.Section.BUILDING
	var old_main_scene := Node.new()
	t.add_child(old_main_scene)
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	old_main_scene.add_child(indicator)
	var main: Node2D = _MAIN_SCRIPT.new()
	main._save_indicator = indicator
	main._summary = _SUMMARY_SCENE.instantiate()
	old_main_scene.add_child(main._summary)
	# Day 14's summary after the hand-over (`DayEnd.hands_over_to_the_escape`).
	main._flow.mode = RunFlow.Mode.INTO_ESCAPE
	var reloads: Array[int] = []
	main.use_reload(func() -> void: reloads.append(1))

	var day_fourteen := _next_operation()
	EventBus.save_written.emit(day_fourteen, int(GameSave.Result.PENDING))
	main._on_summary_continued(main._flow.mode)
	t.check(reloads.size() == 1, "continuing past day 14's summary reloads into the escape")
	t.check(indicator.get_parent() == home,
			"and hands the symbol showing day 14's pending save to the tree's root first")
	main.free()
	old_main_scene.free()
	t.check(is_instance_valid(indicator) and SaveIndicator.carried(tree) == indicator,
			"so the reload does not free it, and the escape's boot adopts it")
	if not is_instance_valid(indicator):
		GameState.facts.escape_section = section
		SaveIndicator.use_home(null)
		home.free()
		return
	t.check(timeline.pending == 1 and timeline.alpha() == 1.0,
			"still fully shown for day 14's save")

	var escape := _next_operation()
	EventBus.save_written.emit(escape, int(GameSave.Result.PENDING))
	EventBus.save_write_settled.emit(day_fourteen, true)
	t.check(timeline.pending == 1,
			"day 14's late answer settles day 14's save, not the escape's")
	EventBus.save_write_settled.emit(escape, false)
	t.check(indicator.shows_struck() and timeline.pending == 0,
			"so the escape's failure afterwards still strikes the symbol")
	timeline.advance(SaveIndicator.MIN_STRUCK_SECONDS - 0.1)
	t.check(timeline.alpha() == 1.0, "fully, for its ten seconds")

	indicator.free()
	GameState.facts.escape_section = section
	t.get_tree().paused = false
	SaveIndicator.use_home(null)
	home.free()

## The whole path through `main._save_now()`: a run `GameSave.uses_save()` refuses — here the
## headless runner — leaves the symbol dark rather than struck. The same write straight through
## `GameSave.write()` is `tests/test_save.gd`'s `_test_a_refused_save_leaves_the_symbol_dark()`.
func _test_main_draws_nothing_for_a_refused_run(t) -> void:
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	t.add_child(indicator)
	var main: Node2D = _MAIN_SCRIPT.new()
	main._save_indicator = indicator
	GameSave.configure(RunConfig.parse(PackedStringArray(), "", false))
	main._save_now(true)
	GameSave.configure(RunConfig.parse(PackedStringArray(), "", false, false, {}, false))
	t.check(timeline.is_idle() and not timeline.struck, "a refused save leaves the symbol dark")
	main.free()
	indicator.free()

func _test_main_shows_a_desktop_save_confirmed_at_once(t) -> void:
	_with_a_scratch_save(func() -> void:
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		var main: Node2D = _MAIN_SCRIPT.new()
		main._save_indicator = indicator
		main._save_now(true)
		t.check(timeline.pending == 0 and not timeline.is_idle(),
				"a desktop save is answered at once and the symbol is already showing")
		t.check(not timeline.struck and not indicator.shows_struck(), "showing the plain picture")
		main.free()
		indicator.free()
	)

## A write tells `EventBus` what it came to, so the symbol hears it without `main` relaying it, and
## begins exactly once for one save: `main._save_now()` adds nothing to what the bus carried. The
## `GameSave.write()` half, with its refused cases, is `tests/test_save.gd`'s
## `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once()`.
func _test_main_adds_nothing_to_what_the_bus_carried_to_the_symbol(t) -> void:
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	_with_a_scratch_save(func() -> void:
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		var main: Node2D = _MAIN_SCRIPT.new()
		main._save_indicator = indicator
		main._save_now(true)
		t.check(heard == [int(GameSave.Result.CONFIRMED)], "a write announces what it came to")
		t.check(timeline.begun == 1, "and the symbol began once for it, not a second time by main")
		t.check(indicator.is_showing() and timeline.pending == 0,
				"and that one change is already answered")
		main.free()
		indicator.free()
	)
	EventBus.save_written.disconnect(listen)
