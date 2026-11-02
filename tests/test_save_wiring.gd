extends RefCounted
## What `main` does with the save: the focus loss that writes nothing, the dawn a resumed boot writes,
## the title and the resume gate that lead to the day brief or the ending, the day engaged writing the
## run as under way, the held restart's deletion, the day-14 hand-over that carries the save symbol
## over a reload, and what a refused or an ordinary write leaves of the symbol. Split from
## `tests/test_save.gd` (the save file, its flush and its symbol, all through `GameSave` and
## `SaveIndicator`'s public calls) because every check here needs a `main`.
##
## **`main` is booted for real**, the way `tests/test_main.gd` boots it: the real `scenes/main.tscn`
## is handed a `RunConfig` (`configure()`), the reload and the quit that would take the runner's own
## scene away (`use_reload()`, `use_quit()`), and two real frames let its `_ready()` finish. After that
## everything is what a player or the engine could do: a real touch pushed through the viewport onto
## the title's button and the summary's continue button, the engine's focus notifications on the
## `ReturnWindow`, the pause screen's restart signal, and the day's own end signal. Nodes are found by
## the names and classes the scene gives them, and the save symbol a booted `main` raises is its child.
## A save a boot resumes from is laid down through `GameSave.write()` before the boot, the way a game
## closed earlier left it.
##
## Where a check reads the symbol's internal count (`Showing.pending`, `begun`), a symbol built with a
## timeline of the test's own is parked at the tree's home, which is what an earlier `main` leaves
## for the next boot (`SaveIndicator.outlive_the_scene()`), and the booted `main` adopts it
## (`SaveIndicator.carried()`) as it adopts the one a reload carries over.
##
## `GameSave` is pointed at a scratch file and handed the configuration of a windowed release run (a
## booted `main` hands it its own, which is that) so its ordinary `write()`, `try_resume()` and
## `clear()` reach it; `run()` puts both back.

const UI := preload("res://tests/ui_screens.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const DaySummaryScript := preload("res://src/ui/day_summary.gd")

const _SCRATCH_PATH := "user://test_save_wiring_scratch.json"
const _SEED := 4242

func run(t) -> void:
	t.gives_back_observers()
	var baseline := GameState.save_snapshot()
	GameSave.set_path_override(_SCRATCH_PATH)
	GameSave.clear_when_a_run_ends()
	_begin()

	await _test_focus_loss_never_charges_a_nerve_and_writes_nothing(t)
	await _test_a_fresh_boot_writes_nothing_until_the_title_is_dismissed(t)
	await _test_a_restart_clears_the_save_in_the_log_it_abandons(t)
	await _test_a_game_closed_between_days_writes_nothing_at_opening(t)
	await _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t)
	await _test_title_leads_to_the_day_brief_with_nothing_charged(t)
	await _test_title_leads_to_the_day_brief_with_a_charged_nerve(t)
	await _test_title_leads_to_the_ending_on_the_last_nerve(t)
	await _test_the_hand_over_to_the_escape_carries_a_pending_save_over(t)
	await _test_main_draws_nothing_for_a_refused_run(t)
	await _test_a_desktop_save_is_shown_at_once_and_begun_once(t)

	GameSave.clear()
	GameSave.set_path_override("")
	GameSave.configure(null)
	GameState.restore_snapshot(baseline)
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.calendar.hard_mode = false
	GameState.calendar.checkpoint = {}
	ControlsMode.forget()
	# The restart wiring the suite drove stamped the title's guard; give it back.
	TitleScreen._restarted_at_msec = -INF
	GameState.start_run(_SEED)

# ------------------------------------------------------------------ finding and booting ---

## The configuration of a windowed release run: it saves, the dev flags do not exist, and only the
## player-facing opt-out of the run log is given, so no run log is written.
func _windowed() -> RunConfig:
	return RunConfig.parse(PackedStringArray(["--no-telemetry"]), "", false, false, {}, false)

## The configuration of the test runner's own run: no window, so no save.
func _headless() -> RunConfig:
	return RunConfig.parse(PackedStringArray(["--no-telemetry"]), "", false)

## Each test starts with `GameSave` as a windowed release run holds it and no save on disk.
func _begin() -> void:
	GameSave.configure(_windowed())
	GameSave.clear()

## `GameState` written to the scratch file the way a game writes it. Whether the write was kept.
func _saved(day_under_way: bool) -> bool:
	return GameSave.write(GameState, day_under_way) == GameSave.Result.CONFIRMED

var _operation := 5000

func _next_operation() -> int:
	_operation += 1
	return _operation

## What a boot is handed to count a reload or a quit that would otherwise take the runner's scene
## away: `reloads` and `quits` gain an entry each time `main` asks for one.
class Calls:
	var reloads: Array[int] = []
	var quits: Array[int] = []

	func reload() -> void:
		reloads.append(1)

	func quit() -> void:
		quits.append(1)

## A symbol with a timeline of the test's own, parked at a plain node standing for the tree's root
## where an earlier `main` leaves one, for the next booted `main` to adopt.
class Parked:
	var home := Node.new()
	var timeline := SaveIndicator.Showing.new()
	var indicator: SaveIndicator

	func _init(t) -> void:
		t.add_child(home)
		SaveIndicator.use_home(home)
		indicator = SaveIndicator.new(timeline)
		home.add_child(indicator)

	func free_all() -> void:
		SaveIndicator.use_home(null)
		home.free()

## Every node under `root` that is a `type_name`: a script class by its `class_name` (the scene
## root of a screen is one), anything else by the engine's class.
func _all(root: Node, type_name: String) -> Array[Node]:
	var found: Array[Node] = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node != root and _is_a(node, type_name):
			found.append(node)
	return found

func _is_a(node: Node, type_name: String) -> bool:
	var script: Script = node.get_script()
	while script:
		if script.get_global_name() == type_name \
				or script.resource_path.get_file().get_basename().to_pascal_case() == type_name:
			return true
		script = script.get_base_script()
	return node.is_class(type_name)

## The one node of `type_name` under `root`, or null.
func _one(root: Node, type_name: String) -> Node:
	var found := _all(root, type_name)
	return found[0] if found.size() == 1 else null

## The real `main.tscn` handed `config` and `calls`, put in the tree, with the two frames its
## `_ready()` awaits let pass: the run, the day and the title are built.
func _boot(t, config: RunConfig, calls: Calls) -> Node2D:
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(config)
	main.use_reload(calls.reload)
	main.use_quit(calls.quit)
	t.add_child(main)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	return main

func _shut(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main.free()

## A press on the title's button `button_name` ("Left", "Right", "Tap"), pushed through the viewport
## where the layout really draws it, and the frames the tap's acknowledgement takes.
func _press_on_the_title(t, main: Node2D, button_name: String) -> void:
	var title := _one(main, "TitleScreen")
	await UI.frames(t)
	UI.push(title, UI.touch_at(UI.centre(UI.button(title, button_name)), true))
	await UI.frames(t)

## A press on the summary's continue button, the way the title's is pressed.
func _press_continue(t, main: Node2D) -> void:
	var summary := _one(main, "DaySummary")
	await UI.frames(t)
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t)

func _summary_of(main: Node2D) -> DaySummaryScript:
	return _one(main, "DaySummary") as DaySummaryScript

## Whether the summary's note line is up, and what it says.
func _note_of(main: Node2D) -> Label:
	return _summary_of(main).get_node("Root/Center/Lines/Note") as Label

# ---------------------------------------------------------------------------- the checks ---

## Losing focus opens the pause and, under a real run, may write a save — but never through
## `GameState.calendar.finish_day()`. Only *opening a saved game* ever spends a nerve; continuing after a
## focus loss in the same session is free, which this asserts by the coarsest available proof: the
## numbers `finish_day()` would have touched do not move.
##
## **Neither focus loss nor a window close writes the save.** Losing focus still opens the pause and
## a window close still ends the telemetry log, but neither touches the save any more — only a day
## starting, or its own brief or end-of-day message coming up, changes what a save holds
## (docs/MECHANICS.md, "Saving and resuming"). The save the day's start wrote is taken away first,
## so a stray write here would come back as a file; a windowed run saves, so the check can fail.
## `main._quit()` makes the same change on its one remaining line, but it also quits the tree; the
## quit is handed to a counter here, and the pause screen's quit button is the other half.
func _test_focus_loss_never_charges_a_nerve_and_writes_nothing(t) -> void:
	_begin()
	var calls := Calls.new()
	var main := await _boot(t, _windowed(), calls)
	await _press_on_the_title(t, main, "Tap")
	var pause := _one(main, "PauseScreen") as PauseScreen
	var window := main.get_node("ReturnWindow") as ReturnWindow
	var day := GameState.header.day
	var nerves := GameState.header.nerves
	t.get_tree().paused = false

	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "focus loss still opens the pause, exactly as before this milestone")
	t.check(GameState.header.day == day and GameState.header.nerves == nerves,
			"and neither the day nor the nerve count moved — a focus loss alone never spends one")
	pause.close()

	GameSave.clear()
	t.get_tree().paused = false
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "focus loss still opens the pause")
	t.check(not GameSave.has_save(), "but writes nothing")
	pause.close()

	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	t.check(not GameSave.has_save(), "and neither does the window-close notification")

	_shut(t, main)
	GameSave.clear()

## **The review finding this test exists for.** The day's start used to write its own dawn
## unconditionally, so merely opening the game — before the title was ever dismissed — created a
## save for a fresh day 1 nobody had touched, with the symbol flashing behind the title on every
## launch and the *next* launch showing a day brief for a day nobody played. A fresh run has nothing
## to resume, so the boot's dawn write does nothing at all: the booted game is on its title with no
## file on disk.
##
## **The regression this whole commit exists for.** A day engaged with no write beside it would
## leave the save on disk saying `day_under_way: false` — correctly written at dawn, for a day
## nobody had touched yet — for the entire time between the title closing and the next moment
## something else happened to write. A crash, a force-kill, or a backgrounded mobile tab whose page
## is simply discarded never sends a notification at all any more, so a day playtested start to
## finish and killed right after would have resumed for free were the engaged day not the one place
## the title's start (with no resume) reaches to write immediately. Asserted directly: dismissing a
## fresh day 1's title, with nothing else run at all, already leaves the save on disk saying the
## day is under way.
func _test_a_fresh_boot_writes_nothing_until_the_title_is_dismissed(t) -> void:
	_begin()
	var main := await _boot(t, _windowed(), Calls.new())
	t.check((_one(main, "TitleScreen") as TitleScreen).is_open()
			and not _summary_of(main).is_showing(), "a fresh run's own default — nothing to resume")
	t.check(not GameSave.has_save(), "a fresh boot writes nothing at all")

	await _press_on_the_title(t, main, "Tap")
	t.check(not _summary_of(main).is_showing()
			and not t.get_tree().paused,
			"no day brief for a fresh run — she is playing already, the tree running")
	var saved := GameSave.try_resume(GameState)
	t.check(saved.get("day_under_way") == true,
			"and the save on disk already says so, with nothing else run at all")

	_shut(t, main)
	GameSave.clear()

## The held restart reaches the same case as a fresh boot: its `GameSave.clear()` leaves
## `GameSave.try_resume()` nothing to find on the reload that follows, so the reloaded boot's own
## resume is empty and its dawn write does nothing either. Driven by the pause screen's own restart
## signal on a booted game that has a save under way, then a second boot, the reloaded one.
##
## **The restart deletes the save before the run log closes**, so the "deleted the save" line is
## written into the run being abandoned: a log held in memory stands in for the run's, and is the
## `Telemetry` log the restart closes.
func _test_a_restart_clears_the_save_in_the_log_it_abandons(t) -> void:
	_begin()
	# The restart hands the symbol showing its deletion to the tree's root, here a plain node.
	var home := Node.new()
	t.add_child(home)
	SaveIndicator.use_home(home)
	var calls := Calls.new()
	var main := await _boot(t, _windowed(), calls)
	await _press_on_the_title(t, main, "Tap")
	t.check(GameSave.has_save(), "a save exists before the restart")
	Telemetry.begin_memory_log()
	var log: TelemetryLog = Telemetry.current_log()

	(_one(main, "PauseScreen") as PauseScreen).restart_requested.emit()
	t.check(not GameSave.has_save(), "the held restart clears it")
	t.check(calls.reloads.size() == 1, "and reloads the scene")
	t.check(log.lines.any(func(line: String) -> bool: return "deleted the save" in line),
			"the restart's deletion is logged")
	t.check(Telemetry.current_log() == null, "and the log is closed after it, not before")
	_shut(t, main)

	var resume := GameSave.try_resume(GameState)
	t.check(resume.is_empty(), "the reloaded boot's own try_resume() finds nothing to resume")
	var reloaded := await _boot(t, _windowed(), calls)
	t.check(not GameSave.has_save(), "and its own dawn write does nothing either")
	t.check((_one(reloaded, "TitleScreen") as TitleScreen).is_open(), "it opens on the title")
	_shut(t, reloaded)
	Telemetry.end_run()
	SaveIndicator.use_home(null)
	home.free()

## *"either it saves with one less nerve and a cleared "during active game" flag. or you defer
## saving to the actual day start"* — a game closed between days charged nothing when it was
## reopened, its file already says `day_under_way: false`, and opening it writes nothing: no file
## is rewritten and no symbol is drawn. A game closed with its day under way is the case the next
## test covers, which does write. A write announces itself on the bus, so what the boot makes of
## the file is what the bus carries.
func _test_a_game_closed_between_days_writes_nothing_at_opening(t) -> void:
	_begin()
	GameState.start_run(348)
	GameState.header.day = 4
	GameState.calendar.begin_day()
	t.check(_saved(false), "the save the end-of-day message wrote")
	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way") == false, "the load finds the day not under way")
	var before := FileAccess.get_file_as_string(_SCRATCH_PATH)
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	EventBus.save_deleted.connect(listen)
	# Built after the save, which raised the symbol of no boot: what is checked below is that
	# opening the save raises nothing more.
	var main := await _boot(t, _windowed(), Calls.new())
	EventBus.save_written.disconnect(listen)
	EventBus.save_deleted.disconnect(listen)
	t.check(heard.is_empty() and FileAccess.get_file_as_string(_SCRATCH_PATH) == before,
			"opening it writes nothing")
	var indicator := _one(main, "SaveIndicator") as SaveIndicator
	t.check(indicator != null and not indicator.is_showing(), "and the symbol stays dark")

	_shut(t, main)
	GameSave.clear()

## A resumed boot with a charged nerve: `main._ready()` charges the load's day under way one nerve
## (`GameState.calendar.finish_day()`) before the day's start and this write ever run, so the reduced
## nerve count is already the live `GameState`'s own by the time this lands — and it is what the
## write carries to disk, with `day_under_way: false`, before the title or the day brief behind it
## is ever shown.
func _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t) -> void:
	_begin()
	GameState.start_run(347)
	GameState.header.day = 4
	GameState.header.nerves = 5
	GameState.calendar.begin_day()
	t.check(_saved(true), "the original mid-day save")
	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way") == true, "the load finds a day under way")

	var main := await _boot(t, _windowed(), Calls.new())
	t.check(GameState.header.nerves == 4, "the boot charges its one nerve")
	var after := GameSave.try_resume(GameState)
	t.check(after.get("day_under_way") == false,
			"the boot write says nothing has been played in the retry yet")
	t.check(GameState.header.nerves == 4,
			"and the reduced nerve count the load already charged is what landed on disk")

	_shut(t, main)
	GameSave.clear()

## The title→day-brief path with nothing charged: the save was written at a day's own summary or at
## an earlier day brief (`day_under_way: false`), so pressing start on the title shows the day brief
## with no lost-day note, and continuing from it is the moment the save actually says the day is under
## way. Also the "second open of a nothing-played-yet save costs nothing" case: nothing here writes
## between the title closing and the day brief's own continue, so a kill anywhere in between finds
## exactly what the screen is already showing.
func _test_title_leads_to_the_day_brief_with_nothing_charged(t) -> void:
	_begin()
	GameState.start_run(234)
	GameState.header.day = 7
	GameState.header.nerves = 5
	_saved(false)
	var main := await _boot(t, _windowed(), Calls.new())

	await _press_on_the_title(t, main, "Tap")
	var summary := _summary_of(main)
	t.check(summary.is_showing(), "the day brief shows instead of starting the day outright")
	t.check(not _note_of(main).visible, "no lost-day note — the load cost nothing")
	t.check(GameSave.try_resume(GameState).get("day_under_way") == false,
			"and the day brief's own continue still has to engage the day, which the save says;"
			+ " showing the brief writes nothing new — the dawn write already said this")

	t.check(t.get_tree().paused, "the day brief holds the tree, so the day is not walked yet")
	await _press_continue(t, main)
	t.check(not summary.is_showing(), "continuing dismisses the brief")
	t.check(not t.get_tree().paused, "and the gate is spent, the day walked with the tree running")
	t.check(GameSave.try_resume(GameState).get("day_under_way") == true,
			"the day is engaged, which the save now says")

	_shut(t, main)
	GameSave.clear()

## The same path with a nerve charged: the day brief carries `Texts.RESUMED_DAY_LOST`.
func _test_title_leads_to_the_day_brief_with_a_charged_nerve(t) -> void:
	_begin()
	GameState.start_run(235)
	_saved(true)
	var main := await _boot(t, _windowed(), Calls.new())

	await _press_on_the_title(t, main, "Tap")
	t.check(_note_of(main).visible and _note_of(main).text == Texts.RESUMED_DAY_LOST,
			"the day brief carries the lost-day line the load itself charged")

	_shut(t, main)
	GameSave.clear()

## The last-nerve case: a hard run whose save was closed with its day under way. The load's own
## `GameState.calendar.finish_day()` call in `_ready()` spends the run's last nerve, so pressing start
## on the title shows the ending directly — the same screen and the same continue any other
## run-ending reaches — rather than the day brief. The run has ended by the time the title is up, so
## `GameSave.write()`'s own refusal (see its doc) means nothing here writes at all, and the run's end
## deleted the file.
##
## **The symbol exists before the charge**, because the charge can end the run and the run's end
## deletes the save, a change the symbol shows: the booted game's own symbol is showing after the
## boot only if it was raised before the charge, since one raised after hears nothing of it.
func _test_title_leads_to_the_ending_on_the_last_nerve(t) -> void:
	_begin()
	GameState.start_run(236)
	GameState.calendar.choose_mode(true)
	GameState.header.day = 5
	GameState.header.nerves = 1
	GameState.calendar.begin_day()
	t.check(_saved(true), "the hard run's save, closed with its day under way, is on disk")
	var main := await _boot(t, _windowed(), Calls.new())

	var own := _one(main, "SaveIndicator") as SaveIndicator
	t.check(own != null and own.is_showing(),
			"the symbol is raised before the resumed run's charge, so the deletion it makes is announced")
	t.check(GameState.header.ending != GameEnums.Ending.NONE and not GameSave.has_save(),
			"the charge spent the last nerve, ended the run and deleted the save")
	await _press_on_the_title(t, main, "Tap")
	var summary := _summary_of(main)
	t.check(summary.is_showing()
			and (summary.get_node("Root/Center/Lines/Title") as Label).text
			== SummaryModel.ending(GameState, GameState.header.ending).title,
			"the ending is shown rather than the day brief, so there is no day brief for a later"
			+ " continue to engage")
	t.check(not GameSave.has_save(), "a run that has ended writes nothing, on this path either")

	_shut(t, main)

## **The day-14 hand-over's reload to the escape, through the summary's own continue.** Day 14's own
## save (A) is written as its summary appears and may still be waiting for the browser when the player
## continues. The hand-over must carry the symbol to the tree's root like the held restart does, so
## it outlives the reload, keeps showing A, and the escape's boot adopts it. There the escape's first
## save (B) begins, and A's answer, arriving late, must settle A and never B: B's failure afterwards
## still strikes the symbol. The reload itself goes to what `use_reload()` was handed, since a real
## one would throw away the test runner's own scene; the tree's root is a plain node here
## (`SaveIndicator.use_home()`), which a suite running while the root is busy cannot use.
##
## Two halves. The booted game's own symbol is handed to the root by the continue and survives the
## game being freed. A symbol of the test's own timeline, parked where that one is, is then adopted by
## a second booted game, and the escape's two saves are played on it with its counts read.
func _test_the_hand_over_to_the_escape_carries_a_pending_save_over(t) -> void:
	_begin()
	var tree: SceneTree = t.get_tree()
	var home := Node.new()
	t.add_child(home)
	SaveIndicator.use_home(home)
	var calls := Calls.new()
	var main := await _boot(t, _windowed(), calls)
	await _press_on_the_title(t, main, "Tap")
	var indicator := _one(main, "SaveIndicator") as SaveIndicator
	t.check(indicator != null and indicator.get_parent() == main,
			"a boot with nothing carried builds the symbol as its own child")

	# Day 14 after the hand-over (`DayEnd.hands_over_to_the_escape`): every task done, a win.
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.start_run(_SEED)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance.progress = Tuning.RESISTANCE_GOAL
	GameState.resistance.sabotage_done = true
	(_one(main, "DayController") as DayController).day_finished.emit(GameEnums.DayResult.WON)
	t.check(_summary_of(main).is_showing()
			and GameState.facts.escape_section == DaySpec.Section.BUILDING,
			"a won day 14 puts day 14's summary up with the run in the building")
	var day_fourteen := _next_operation()
	EventBus.save_written.emit(day_fourteen, int(GameSave.Result.PENDING))
	t.check(indicator.is_showing(), "and the symbol shows day 14's pending save")
	await _press_continue(t, main)
	t.check(calls.reloads.size() == 1, "continuing past day 14's summary reloads into the escape")
	t.check(indicator.get_parent() == home,
			"and hands the symbol showing day 14's pending save to the tree's root first")
	_shut(t, main)
	t.check(is_instance_valid(indicator) and SaveIndicator.carried(tree) == indicator,
			"so the reload does not free it, and the escape's boot adopts it")
	t.check(is_instance_valid(indicator) and indicator.is_showing() and not indicator.shows_struck(),
			"still fully shown for day 14's save after the reload")
	if is_instance_valid(indicator):
		indicator.free()

	# The adoption, on a symbol whose counts the test can read.
	GameState.facts.escape_section = DaySpec.Section.NONE
	var parked := Parked.new(t)
	var escape_boot := await _boot(t, _windowed(), calls)
	t.check(_one(escape_boot, "SaveIndicator") == null
			and SaveIndicator.carried(tree) == parked.indicator,
			"the next boot adopts the carried symbol and builds none of its own")
	var timeline := parked.timeline
	var begun := timeline.begun
	EventBus.save_written.emit(day_fourteen, int(GameSave.Result.PENDING))
	t.check(timeline.begun == begun + 1 and timeline.pending == 1 and timeline.alpha() == 1.0,
			"still fully shown for day 14's save")
	var escape := _next_operation()
	EventBus.save_written.emit(escape, int(GameSave.Result.PENDING))
	EventBus.save_write_settled.emit(day_fourteen, true)
	t.check(timeline.pending == 1,
			"day 14's late answer settles day 14's save, not the escape's")
	EventBus.save_write_settled.emit(escape, false)
	t.check(parked.indicator.shows_struck() and timeline.pending == 0,
			"so the escape's failure afterwards still strikes the symbol")
	timeline.advance(SaveIndicator.MIN_STRUCK_SECONDS - 0.1)
	t.check(timeline.alpha() == 1.0, "fully, for its ten seconds")

	_shut(t, escape_boot)
	parked.free_all()
	home.free()
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameSave.clear()

## The whole path through `main`'s write: a run `GameSave.uses_save()` refuses — here the headless
## runner — leaves the symbol dark rather than struck. The same write straight through
## `GameSave.write()` is `tests/test_save.gd`'s `_test_a_refused_save_leaves_the_symbol_dark()`.
func _test_main_draws_nothing_for_a_refused_run(t) -> void:
	_begin()
	var parked := Parked.new(t)
	var main := await _boot(t, _headless(), Calls.new())
	await _press_on_the_title(t, main, "Tap")
	t.check(not t.get_tree().paused, "the day engaged, which is where the game writes its save")
	t.check(parked.timeline.is_idle() and not parked.timeline.struck,
			"a refused save leaves the symbol dark")
	t.check(not GameSave.has_save(), "and writes nothing")

	_shut(t, main)
	parked.free_all()

## The whole path through `main`'s write on a run that saves: a desktop save is answered at once and
## the symbol is already showing the plain picture. A write tells `EventBus` what it came to, so the
## symbol hears it without `main` relaying it, and begins exactly once for one save: `main` adds
## nothing to what the bus carried. The `GameSave.write()` half, with its refused cases, is
## `tests/test_save.gd`'s `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once()`.
func _test_a_desktop_save_is_shown_at_once_and_begun_once(t) -> void:
	_begin()
	var parked := Parked.new(t)
	var main := await _boot(t, _windowed(), Calls.new())
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	await _press_on_the_title(t, main, "Tap")
	EventBus.save_written.disconnect(listen)
	var timeline := parked.timeline
	t.check(timeline.pending == 0 and not timeline.is_idle(),
			"a desktop save is answered at once and the symbol is already showing")
	t.check(not timeline.struck and not parked.indicator.shows_struck(), "showing the plain picture")
	t.check(heard == [int(GameSave.Result.CONFIRMED)], "a write announces what it came to")
	t.check(timeline.begun == 1, "and the symbol began once for it, not a second time by main")
	t.check(parked.indicator.is_showing() and timeline.pending == 0,
			"and that one change is already answered")

	_shut(t, main)
	parked.free_all()
	GameSave.clear()
