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
## scene away (`use_reload()`, `use_quit()`), and real frames pass until its boot has finished. After that
## everything is what a player or the engine could do: a real touch pushed through the viewport onto
## the title's button and the summary's continue button, the engine's focus notifications on the
## `ReturnWindow`, the pause screen's restart signal, and the day's own end signal. Nodes are found by
## the names and classes the scene gives them (`tests/booted_main.gd`, which also waits for the boot
## itself, `until_booted()`), and the save symbol a booted `main` raises is its child. A save a boot
## resumes from is a run of the test's own written through `_save.write()` before the boot, the way
## a game closed earlier left it; what is on disk afterwards is read back into a run of the test's
## own too (`_on_disk()`), so reading it never touches the run the booted game plays.
##
## **Each test plays a run of its own.** Where a check reads the run the booted game plays, the
## boot is handed a home with a sitting parked in it that holds a fresh `RunState` of the test's
## (`Boot.home_playing()`), so the game takes that sitting and plays that run; the held restart's
## test lets the boot build its own sitting instead, since parking it is what that test checks.
##
## Where a check follows something across a reload, the boots are handed one node of the test's
## own in place of the tree's root (`main.use_sitting_home()`): the reload a boot asks for parks its
## `Sitting` there, as a real one parks it at the root, and the boot standing for the reload takes
## it from there. Where a check reads the symbol's internal count (`Showing.pending`, `begun`), a
## symbol built with a timeline of the test's own is parked under a sitting in such a home, which
## is what an earlier `main` leaves for the next boot (`SaveIndicator.outlive_the_scene()`), and the
## booted `main` adopts it (`SaveIndicator.carried()`) as it adopts the one a reload carries over.
##
## The suite's `GameSave` is built at a scratch file, handed to every boot (`main.use_save()`) and the
## configuration of a windowed release run (a booted `main` hands it its own, which is that), so its
## ordinary `write()`, `try_resume()` and `clear()` reach it.

const Boot := preload("res://tests/booted_main.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

const _SCRATCH_PATH := "user://test_save_wiring_scratch.json"
const _SEED := 4242

## The save under test, at a scratch path, handed to every boot.
var _save := GameSave.new(_SCRATCH_PATH)

func run(t) -> void:
	_save.clear_when_a_run_ends()
	_begin()

	await _test_focus_loss_never_charges_a_nerve_and_writes_nothing(t)
	await _test_a_fresh_boot_writes_nothing_until_the_title_is_dismissed(t)
	await _test_a_restart_clears_the_save_in_the_log_it_abandons(t)
	await _test_the_save_outlives_a_reload_under_the_sitting(t)
	await _test_a_game_closed_between_days_writes_nothing_at_opening(t)
	await _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t)
	await _test_title_leads_to_the_day_brief_with_nothing_charged(t)
	await _test_title_leads_to_the_day_brief_with_a_charged_nerve(t)
	await _test_title_leads_to_the_ending_on_the_last_nerve(t)
	await _test_the_hand_over_to_the_escape_carries_a_pending_save_over(t)
	await _test_main_draws_nothing_for_a_refused_run(t)
	await _test_a_desktop_save_is_shown_at_once_and_begun_once(t)

	_save.clear()
	_save.free()

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
	_save.configure(_windowed())
	_save.clear()

## `run` written to the scratch file the way a game writes it. Whether the write was kept.
func _saved(run: RunState, day_under_way: bool) -> bool:
	return _save.write(run, day_under_way) == GameSave.Result.CONFIRMED

## What the scratch file resumes into: `_save.try_resume()`'s own answer, read into a run of the
## test's own so the run the booted game plays is never touched, with that run's nerves after it
## under `"nerves"` (`{}` when there is nothing to resume).
func _on_disk() -> Dictionary:
	var reader := RunState.new()
	var resumed := _save.try_resume(reader)
	if not resumed.is_empty():
		resumed["nerves"] = reader.header.nerves
	return resumed

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

## A symbol with a timeline of the test's own, under a sitting parked in a home of the test's own
## where an earlier `main` leaves one, for the next booted `main` handed that home to take. The
## sitting holds a fresh run of its own, which the booted game plays.
class Parked:
	var home := Node.new()
	var sitting := Sitting.new()
	var timeline := SaveIndicator.Showing.new()
	var indicator: SaveIndicator

	func _init(t) -> void:
		t.add_child(home)
		sitting.name = Sitting.NODE_NAME
		sitting.run = RunState.new()
		home.add_child(sitting)
		indicator = SaveIndicator.new(timeline)
		sitting.add_child(indicator)

	func free_all() -> void:
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

## The real `main.tscn` handed `config`, `calls` and, when given, the `home` its sitting is parked
## in and taken from and the `run_log` it writes (`main.use_run_log()`), put in the tree, with real frames let pass until its boot has finished
## (`Boot.until_booted()`): the run, the day, her and the title are built.
func _boot(t, config: RunConfig, calls: Calls, home: Node = null, hand_the_save := true,
		run_log: Telemetry = null) -> Node2D:
	var main: Node2D = MAIN_SCENE.instantiate()
	if hand_the_save:
		main.use_save(_save)
	main.configure(config)
	main.use_reload(calls.reload)
	main.use_quit(calls.quit)
	if home:
		main.use_sitting_home(home)
	if run_log:
		main.use_run_log(run_log)
	t.add_child(main)
	await Boot.until_booted(t, main)
	return main

func _shut(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main.free()

## Whether the summary's note line is up, and what it says.
func _note_of(main: Node2D) -> Label:
	return Boot.summary(main).get_node("Root/Center/Lines/Note") as Label

# ---------------------------------------------------------------------------- the checks ---

## Losing focus opens the pause and, under a real run, may write a save — but never through
## `RunCalendar.finish_day()`. Only *opening a saved game* ever spends a nerve; continuing after a
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
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var main := await _boot(t, _windowed(), calls, home)
	await Boot.press_title(t, main, "Tap")
	var pause := Boot.pause(main)
	var window := main.get_node("ReturnWindow") as ReturnWindow
	var day := run.header.day
	var nerves := run.header.nerves
	t.get_tree().paused = false

	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "focus loss still opens the pause, exactly as before this milestone")
	t.check(run.header.day == day and run.header.nerves == nerves,
			"and neither the day nor the nerve count moved — a focus loss alone never spends one")
	pause.close()

	_save.clear()
	t.get_tree().paused = false
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "focus loss still opens the pause")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "but writes nothing")
	pause.close()

	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and neither does the window-close notification")

	_shut(t, main)
	home.free()
	_save.clear()

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
	t.check(Boot.title(main).is_open()
			and not Boot.summary(main).is_showing(), "a fresh run's own default — nothing to resume")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "a fresh boot writes nothing at all")

	await Boot.press_title(t, main, "Tap")
	t.check(not Boot.summary(main).is_showing()
			and not t.get_tree().paused,
			"no day brief for a fresh run — she is playing already, the tree running")
	t.check(_on_disk().get("day_under_way") == true,
			"and the save on disk already says so, with nothing else run at all")

	_shut(t, main)
	_save.clear()

## The held restart reaches the same case as a fresh boot: its `_save.clear()` leaves
## `_save.try_resume()` nothing to find on the reload that follows, so the reloaded boot's own
## resume is empty and its dawn write does nothing either. Driven by the pause screen's own restart
## signal on a booted game that has a save under way, then a second boot, the reloaded one.
##
## **The restart deletes the save before the run log closes**, so the "deleted the save" line is
## written into the run being abandoned: a log held in memory stands in for the run's, and is the
## `Telemetry` log the restart closes. **And it stamps the sitting** the reloaded boot's title
## measures its restart guard against (`Sitting.restarted_at_msec`), since that title is a fresh one.
func _test_a_restart_clears_the_save_in_the_log_it_abandons(t) -> void:
	_begin()
	# The restart parks the sitting, with the symbol showing its deletion under it, in its home.
	var home := Node.new()
	t.add_child(home)
	var calls := Calls.new()
	var run_log := Telemetry.new("")
	var main := await _boot(t, _windowed(), calls, home, true, run_log)
	await Boot.press_title(t, main, "Tap")
	t.check(FileAccess.file_exists(_SCRATCH_PATH), "a save exists before the restart")
	run_log.begin_run(0, false)
	var log: TelemetryLog = run_log.current_log()

	Boot.pause(main).restart_requested.emit()
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "the held restart clears it")
	t.check(calls.reloads.size() == 1, "and reloads the scene")
	t.check(log.lines.any(func(line: String) -> bool: return "deleted the save" in line),
			"the restart's deletion is logged")
	t.check(run_log.current_log() == null, "and the log is closed after it, not before")
	var sitting := home.get_node_or_null(NodePath(Sitting.NODE_NAME)) as Sitting
	t.check(sitting != null, "the restart parks the sitting in its home before the reload")
	t.check(sitting != null and sitting.restarted_at_msec > -INF,
			"stamped with the restart")
	var carried := SaveIndicator.carried(sitting)
	t.check(carried != null, "and with the symbol showing the deletion under it")
	_shut(t, main)

	t.check(_on_disk().is_empty(), "the reloaded boot's own try_resume() finds nothing to resume")
	var reloaded := await _boot(t, _windowed(), calls, home, true, run_log)
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and its own dawn write does nothing either")
	t.check(Boot.title(reloaded).is_open(), "it opens on the title")
	t.check(_one(reloaded, "SaveIndicator") == null and home.get_child_count() == 1
			and SaveIndicator.carried(sitting) == carried,
			"and takes the parked sitting, adopting the symbol under it rather than building its own")
	_shut(t, reloaded)
	run_log.free()
	home.free()

## **The game's own path to its save**, which every other test here skips by handing `main` a save
## (`main.use_save()`): a boot handed only the sitting's home finds the save under the sitting in it,
## and a reload leaves that same node there, so the next boot finds the same instance and its
## operation ids keep growing. A boot that built a fresh save each time would free the one with the
## reload (dropping a pending web flush) and restart the ids at 1, so a carried symbol's newest id
## would outrank the next boot's write. The home holds a sitting with a save at a scratch path, as an
## earlier boot leaves it, so the boot never reaches the player's file.
func _test_the_save_outlives_a_reload_under_the_sitting(t) -> void:
	_begin()
	var home := Node.new()
	t.add_child(home)
	var run := RunState.new()
	var sitting := Sitting.new()
	sitting.name = Sitting.NODE_NAME
	sitting.run = run
	home.add_child(sitting)
	var parked := GameSave.new(_SCRATCH_PATH)
	parked.name = GameSave.NODE_NAME
	sitting.add_child(parked)
	var ids: Array[int] = []
	var hear := func(operation: int, _result: int) -> void: ids.append(operation)
	EventBus.save_written.connect(hear)
	var calls := Calls.new()

	var first := await _boot(t, _windowed(), calls, home, false)
	# Only the lookup under test keeps this boot off the player's own save file: if it broke, `main`
	# would make a save at the default path, wherever it parked it. So stop before anything can
	# write unless `parked` is the one `GameSave` anywhere in the tree.
	var saves: Array[Node] = []
	var pending: Array[Node] = [t.get_tree().root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node is GameSave:
			saves.append(node)
	var took_it := saves == [parked]
	t.check(took_it, "the first boot took the save under the sitting and made none of its own")
	if not took_it:
		_shut(t, first)
		EventBus.save_written.disconnect(hear)
		home.free()
		return
	await Boot.press_title(t, first, "Tap")
	t.check(ids.size() >= 1, "the first boot's save, found under the sitting, wrote (%s)" % [ids])
	var before := ids.size()
	Boot.pause(first).restart_requested.emit()
	t.check(calls.reloads.size() == 1 and is_instance_valid(parked)
			and parked.get_parent() == sitting and sitting.get_parent() == home,
			"the restart reloads and the save is still parked under the sitting in its home")
	_shut(t, first)
	t.check(is_instance_valid(parked), "freeing the first boot leaves the save alive")

	var second := await _boot(t, _windowed(), calls, home, false)
	t.check(home.get_node_or_null(NodePath("%s/%s" % [Sitting.NODE_NAME, GameSave.NODE_NAME])) == parked
			and home.get_child_count() == 1 and _all(sitting, "GameSave").size() == 1,
			"the next boot finds the same save node, and makes no second one")
	await Boot.press_title(t, second, "Tap")
	t.check(ids.size() > before, "the next boot wrote through it (%s)" % [ids])
	var growing := true
	for i in range(1, ids.size()):
		growing = growing and ids[i] > ids[i - 1]
	t.check(growing, "and the operation ids across the reload only grow (%s)" % [ids])
	_shut(t, second)
	EventBus.save_written.disconnect(hear)
	parked.clear()
	home.free()

## *"either it saves with one less nerve and a cleared "during active game" flag. or you defer
## saving to the actual day start"* — a game closed between days charged nothing when it was
## reopened, its file already says `day_under_way: false`, and opening it writes nothing: no file
## is rewritten and no symbol is drawn. A game closed with its day under way is the case the next
## test covers, which does write. A write announces itself on the bus, so what the boot makes of
## the file is what the bus carries.
func _test_a_game_closed_between_days_writes_nothing_at_opening(t) -> void:
	_begin()
	var closed := RunState.new()
	closed.start_run(348)
	closed.header.day = 4
	closed.calendar.begin_day()
	t.check(_saved(closed, false), "the save the end-of-day message wrote")
	t.check(_on_disk().get("day_under_way") == false, "the load finds the day not under way")
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
	_save.clear()

## A resumed boot with a charged nerve: `main._ready()` charges the load's day under way one nerve
## (`RunCalendar.finish_day()`) before the day's start and this write ever run, so the reduced
## nerve count is already the run's own by the time this lands — and it is what the
## write carries to disk, with `day_under_way: false`, before the title or the day brief behind it
## is ever shown.
func _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t) -> void:
	_begin()
	var run := RunState.new()
	run.start_run(347)
	run.header.day = 4
	run.header.nerves = 5
	run.calendar.begin_day()
	t.check(_saved(run, true), "the original mid-day save")
	t.check(_on_disk().get("day_under_way") == true, "the load finds a day under way")

	# A fresh run handed to the boot, which the resume reads the save into.
	var played := RunState.new()
	var home := Boot.home_playing(t, played)
	var main := await _boot(t, _windowed(), Calls.new(), home)
	t.check(played.header.nerves == 4, "the boot charges its one nerve")
	var after := _on_disk()
	t.check(after.get("day_under_way") == false,
			"the boot write says nothing has been played in the retry yet")
	t.check(after.get("nerves") == 4,
			"and the reduced nerve count the load already charged is what landed on disk")

	_shut(t, main)
	home.free()
	_save.clear()

## The title→day-brief path with nothing charged: the save was written at a day's own summary or at
## an earlier day brief (`day_under_way: false`), so pressing start on the title shows the day brief
## with no lost-day note, and continuing from it is the moment the save actually says the day is under
## way. Also the "second open of a nothing-played-yet save costs nothing" case: nothing here writes
## between the title closing and the day brief's own continue, so a kill anywhere in between finds
## exactly what the screen is already showing.
func _test_title_leads_to_the_day_brief_with_nothing_charged(t) -> void:
	_begin()
	var run := RunState.new()
	run.start_run(234)
	run.header.day = 7
	run.header.nerves = 5
	_saved(run, false)
	var main := await _boot(t, _windowed(), Calls.new())

	await Boot.press_title(t, main, "Tap")
	var summary := Boot.summary(main)
	t.check(summary.is_showing(), "the day brief shows instead of starting the day outright")
	t.check(not _note_of(main).visible, "no lost-day note — the load cost nothing")
	t.check(_on_disk().get("day_under_way") == false,
			"and the day brief's own continue still has to engage the day, which the save says;"
			+ " showing the brief writes nothing new — the dawn write already said this")

	t.check(t.get_tree().paused, "the tree stays paused while the day brief is up, so the day is not walked yet")
	await Boot.press_continue(t, main)
	t.check(not summary.is_showing(), "continuing dismisses the brief")
	t.check(not t.get_tree().paused, "and the gate is spent, the day walked with the tree running")
	t.check(_on_disk().get("day_under_way") == true,
			"the day is engaged, which the save now says")

	_shut(t, main)
	_save.clear()

## The same path with a nerve charged: the day brief carries `Texts.RESUMED_DAY_LOST`.
func _test_title_leads_to_the_day_brief_with_a_charged_nerve(t) -> void:
	_begin()
	var run := RunState.new()
	run.start_run(235)
	_saved(run, true)
	var main := await _boot(t, _windowed(), Calls.new())

	await Boot.press_title(t, main, "Tap")
	t.check(_note_of(main).visible and _note_of(main).text == Texts.RESUMED_DAY_LOST,
			"the day brief carries the lost-day line the load itself charged")

	_shut(t, main)
	_save.clear()

## The last-nerve case: a hard run whose save was closed with its day under way. The load's own
## `RunCalendar.finish_day()` call in `_ready()` spends the run's last nerve, so pressing start
## on the title shows the ending directly — the same screen and the same continue any other
## run-ending reaches — rather than the day brief. The run has ended by the time the title is up, so
## `_save.write()`'s own refusal (see its doc) means nothing here writes at all, and the run's end
## deleted the file.
##
## **The symbol exists before the charge**, because the charge can end the run and the run's end
## deletes the save, a change the symbol shows: the booted game's own symbol is showing after the
## boot only if it was raised before the charge, since one raised after hears nothing of it.
func _test_title_leads_to_the_ending_on_the_last_nerve(t) -> void:
	_begin()
	var closed := RunState.new()
	closed.start_run(236)
	closed.calendar.choose_mode(true)
	closed.header.day = 5
	closed.header.nerves = 1
	closed.calendar.begin_day()
	t.check(_saved(closed, true), "the hard run's save, closed with its day under way, is on disk")
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var main := await _boot(t, _windowed(), Calls.new(), home)

	var own := _one(main, "SaveIndicator") as SaveIndicator
	t.check(own != null and own.is_showing(),
			"the symbol is raised before the resumed run's charge, so the deletion it makes is announced")
	t.check(run.header.ending != GameEnums.Ending.NONE and not FileAccess.file_exists(_SCRATCH_PATH),
			"the charge spent the last nerve, ended the run and deleted the save")
	await Boot.press_title(t, main, "Tap")
	var summary := Boot.summary(main)
	t.check(summary.is_showing()
			and (summary.get_node("Root/Center/Lines/Title") as Label).text
			== SummaryModel.ending(run, run.header.ending).title,
			"the ending is shown rather than the day brief, so there is no day brief for a later"
			+ " continue to engage")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "a run that has ended writes nothing, on this path either")

	_shut(t, main)
	home.free()

## **The day-14 hand-over's reload to the escape, through the summary's own continue.** Day 14's own
## save (A) is written as its summary appears and may still be waiting for the browser when the player
## continues. The hand-over must carry the symbol to the sitting like the held restart does, so
## it outlives the reload, keeps showing A, and the escape's boot adopts it. There the escape's first
## save (B) begins, and A's answer, arriving late, must settle A and never B: B's failure afterwards
## still strikes the symbol. The reload itself goes to what `use_reload()` was handed, since a real
## one would throw away the test runner's own scene; the sitting the symbol is carried under is
## parked in a home of the test's own (`main.use_sitting_home()`), standing for the tree's root.
##
## Two halves. The booted game's own symbol is handed to the sitting by the continue and survives
## the game being freed. A symbol of the test's own timeline, parked where that one is, is then
## adopted by a second booted game, and the escape's two saves are played on it with its counts read.
## The first boot plays a run of the test's own, from a sitting parked in the home before it boots
## (`Boot.home_playing()`); that the reload parks a sitting the boot built itself is the held
## restart's test above, through the same `main._reload_the_scene()`.
func _test_the_hand_over_to_the_escape_carries_a_pending_save_over(t) -> void:
	_begin()
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var calls := Calls.new()
	var main := await _boot(t, _windowed(), calls, home)
	await Boot.press_title(t, main, "Tap")
	var indicator := _one(main, "SaveIndicator") as SaveIndicator
	t.check(indicator != null and indicator.get_parent() == main,
			"a boot with nothing carried builds the symbol as its own child")

	# Day 14 after the hand-over (`DayEnd.hands_over_to_the_escape`): every task done, a win.
	run.start_run(_SEED)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.resistance.progress = Tuning.RESISTANCE_GOAL
	run.resistance.sabotage_done = true
	Boot.day(main).day_finished.emit(GameEnums.DayResult.WON)
	t.check(Boot.summary(main).is_showing()
			and run.facts.escape_section == DaySpec.Section.BUILDING,
			"a won day 14 puts day 14's summary up with the run in the building")
	var day_fourteen := _next_operation()
	EventBus.save_written.emit(day_fourteen, int(GameSave.Result.PENDING))
	t.check(indicator.is_showing(), "and the symbol shows day 14's pending save")
	await Boot.press_continue(t, main)
	t.check(calls.reloads.size() == 1, "continuing past day 14's summary reloads into the escape")
	var sitting := home.get_node_or_null(NodePath(Sitting.NODE_NAME)) as Sitting
	t.check(sitting != null and indicator.get_parent() == sitting,
			"and hands the symbol showing day 14's pending save to the sitting in its home")
	_shut(t, main)
	t.check(is_instance_valid(indicator) and SaveIndicator.carried(sitting) == indicator,
			"so the reload does not free it, and the escape's boot adopts it")
	t.check(is_instance_valid(indicator) and indicator.is_showing() and Boot.save_symbol_plain(indicator),
			"still shown, not struck, for day 14's save after the reload")
	if is_instance_valid(indicator):
		indicator.free()

	# The adoption, on a symbol whose counts the test can read.
	var parked := Parked.new(t)
	var escape_boot := await _boot(t, _windowed(), calls, parked.home)
	t.check(_one(escape_boot, "SaveIndicator") == null
			and SaveIndicator.carried(parked.sitting) == parked.indicator,
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
	t.check(Boot.save_symbol_struck(parked.indicator) and timeline.pending == 0,
			"so the escape's failure afterwards still strikes the symbol")
	timeline.advance(SaveIndicator.MIN_STRUCK_SECONDS - 0.1)
	t.check(timeline.alpha() == 1.0, "fully, for its ten seconds")

	_shut(t, escape_boot)
	parked.free_all()
	home.free()
	_save.clear()

## The whole path through `main`'s write: a run the save refuses — here the headless
## runner — leaves the symbol dark rather than struck. The same write straight through
## `_save.write()` is `tests/test_save.gd`'s `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once()`.
func _test_main_draws_nothing_for_a_refused_run(t) -> void:
	_begin()
	var parked := Parked.new(t)
	var main := await _boot(t, _headless(), Calls.new(), parked.home)
	await Boot.press_title(t, main, "Tap")
	t.check(not t.get_tree().paused, "the day engaged, which is where the game writes its save")
	t.check(parked.timeline.is_idle() and not parked.timeline.struck,
			"a refused save leaves the symbol dark")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and writes nothing")

	_shut(t, main)
	parked.free_all()

## The whole path through `main`'s write on a run that saves: a desktop save is answered at once and
## the symbol is already showing the plain picture. A write tells `EventBus` what it came to, so the
## symbol hears it without `main` relaying it, and begins exactly once for one save: `main` adds
## nothing to what the bus carried. The `_save.write()` half, with its refused cases, is
## `tests/test_save.gd`'s `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once()`.
func _test_a_desktop_save_is_shown_at_once_and_begun_once(t) -> void:
	_begin()
	var parked := Parked.new(t)
	var main := await _boot(t, _windowed(), Calls.new(), parked.home)
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	await Boot.press_title(t, main, "Tap")
	EventBus.save_written.disconnect(listen)
	var timeline := parked.timeline
	t.check(timeline.pending == 0 and not timeline.is_idle(),
			"a desktop save is answered at once and the symbol is already showing")
	t.check(not timeline.struck and Boot.save_symbol_plain(parked.indicator), "showing the plain picture")
	t.check(heard == [int(GameSave.Result.CONFIRMED)], "a write announces what it came to")
	t.check(timeline.begun == 1, "and the symbol began once for it, not a second time by main")

	_shut(t, main)
	parked.free_all()
	_save.clear()
