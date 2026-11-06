extends RefCounted
## What the observers record of a scripted run, end to end through the real `main.tscn`: the names
## the page's counter sends (`VisitCounter`, GoatCounter) and the lines the run log writes.
##
## **Both are pinned, not merely checked for shape.** The names are what the page counts by, so a
## name that changes starts a new series and ends the old one's history (docs/TELEMETRY.md, "The page
## counts visits"); the run log is read back across builds, so a line that moves or changes wording
## is a log a reader cannot compare with last week's. The expected names are literals here, and the
## expected log is `BASELINE`, the lines this same script produces — recorded before the run log,
## the counter and the UI became observers of domain events, and its escape half again when the
## escape's sections became days — so a refactor of who calls whom shows up here as a difference,
## line by line, and not as a count that quietly drifted.
##
## Driven through the real boot (`tests/booted_main.gd`) with the tree held paused between the calls
## below, so no physics tick of the day runs and every line is stamped at the clock it was written
## at: a day lost to a car, to her crying, to a catalogue row and to dusk, each tried again, then won
## and the next day begun; then the escape handed over from day 14, lost once, walked out of and
## left by the tunnel — each of its sections a day of its own, ended through the day's own finish
## path. The summary's continue is pressed through the viewport; the title's answers are the signal
## the title raises (a rig's boot skips the title, and the city runs on behind an open one).
## Everything is found by the names `main` gives it, and each run is a `RunState` of the test's own.

const Boot := preload("res://tests/booted_main.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_observers_scratch.json"
## The run log the script below wrote on the build this was recorded on, one line per line; the
## two scenarios are separated by a line of their own (`SCENARIO_BREAK`).
const BASELINE := "res://tests/fixtures/observed_run_log.txt"
const SCENARIO_BREAK := "=== the escape"
const SEED := 4242
## `VisitCounter` with `_send_event()` recording the name rather than reaching for a page — the same
## stand-in `tests/test_visit_counter.gd` uses — so what each event would send can be read back.
class RecordingCounter extends VisitCounter:
	var sent: Array[String] = []

	## Counts `run` and listens to the game's bus, as `main` hands the real counter the run it plays
	## and the bus.
	func _init(run: RunState) -> void:
		configure(null, run)
		listen(EventBus)

	func _send_event(name: String) -> void:
		sent.append(name)

func run(t) -> void:
	var day_lines: Array[String] = await _test_a_day_lost_to_each_cause_won_and_the_next_begun(t)
	var escape_lines: Array[String] = await _test_the_escape_handed_over_lost_and_left(t)
	_test_the_run_log_is_the_baseline(t, day_lines, escape_lines)
	_test_endings_and_checkpoints(t)
	_test_a_fresh_run_a_resume_and_a_reload(t)

# ------------------------------------------------------------------- a day ---

## Day 1 of `SEED`: the controls answered twice (a joystick, then a key), lost to a car, to her
## crying, to a catalogue row and to dusk, each retried, then won, and day 2 begun.
func _test_a_day_lost_to_each_cause_won_and_the_next_begun(t) -> Array[String]:
	var saved_paused: bool = t.get_tree().paused
	var run := RunState.new()
	var counter := RecordingCounter.new(run)
	t.add_child(counter)
	t.get_tree().paused = true
	# A run log of the test's own, open before the boot and handed to it: `--no-telemetry` keeps the
	# boot from opening one, and it writes into the one it is handed.
	var run_log := Telemetry.new("")
	run_log.begin_run(SEED)

	# The tree stays paused throughout: the day's clock counts physics ticks, and none passes
	# between the presses below, so every line is stamped at the clock it was written at. **The
	# title is skipped** (`--no-title`, as a rig skips it): the city keeps running behind an open
	# title, the neighbor walking on, so the distance a loss line reports to her would depend on how
	# many frames the title was up.
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE,
			Boot.config(["--seed", str(SEED), "--no-title"]),
			func(m: Node) -> void:
				m.use_sitting_home(home)
				m.use_run_log(run_log))
	var main := booted.main
	t.check(Boot.day(main) != null and Boot.day(main).is_running(), "the boot reached day 1")
	_check_the_observer_runs_after(t, main, [Boot.city(main), Boot.resistance(main), _edge_of(main),
			Boot.day(main)], "a day")

	# The controls answered twice, by the signal the title raises for a joystick button and for a
	# key (`space` begins a run in tap mode), which `main` answers as it answers a press: a title
	# that is not up cannot be pressed, and a second answer has no title to come from.
	var title := Boot.title(main)
	title.start_requested.emit(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.LEFT)
	t.get_tree().paused = true
	title.start_requested.emit(ControlsMode.Mode.TAP, true, ControlsMode.Side.LEFT)
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	await _continue_while_paused(t, main)
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	await _continue_while_paused(t, main)
	EventBus.hard_fail_triggered.emit("homeless_yeller")
	await _continue_while_paused(t, main)
	# Dusk: the day's own clock run out, through the one tick that notices it.
	var day := Boot.day(main)
	day.time_remaining = 0.0
	day.tick(0.0)
	await _continue_while_paused(t, main)
	day = Boot.day(main)
	day.day_finished.emit(GameEnums.DayResult.WON)
	await _continue_while_paused(t, main)

	var lines := _lines_kept(run_log.current_log().lines)
	t.check(counter.sent == [
			"nappy-run-fresh", "nappy-day-1-began",
			"nappy-controls-joystick", "nappy-mode-normal",
			"nappy-controls-keys", "nappy-mode-normal",
			"nappy-day-1-lost-hard-fail-car", "nappy-day-1-began",
			"nappy-day-1-lost-crying-self", "nappy-day-1-began",
			"nappy-day-1-lost-hard-fail-homeless-yeller", "nappy-day-1-began",
			"nappy-day-1-lost-timeout", "nappy-day-1-began",
			"nappy-day-1-won", "nappy-day-2-began"],
			"a day lost to each kind of cause, won and the next begun sends exactly these (%s)"
					% [counter.sent])

	booted.free_all()
	run_log.free()
	home.free()
	counter.free()
	t.get_tree().paused = saved_paused
	return lines

## The summary's continue pressed through the viewport, and the tree held still again at once: the
## continue that starts a day unpauses the tree in the same frame the test resumes in, before any
## physics tick of it has run, so every line the next call writes is stamped at the same clock.
func _continue_while_paused(t, main: Node) -> void:
	await Boot.press_continue(t, main)
	t.get_tree().paused = true

## The screen-edge badge the boot built, on the layer `main` names it.
static func _edge_of(main: Node) -> Node:
	return main.get_node_or_null("DangerEdge/Edge")

## The observer stamps its lines with the clock and reads the resistance and the badges, so it has
## to process after them each frame, as it did when `main` added it straight after the day's
## clock: tree order is process order, and the session that holds it is `main`'s first child.
func _check_the_observer_runs_after(t, main: Node, world: Array, boot: String) -> void:
	var found := main.find_children("*", "TelemetryObserver", true, false)
	var observer: TelemetryObserver = found[0] if not found.is_empty() else null
	t.check(observer != null, "%s's boot builds the observer with a log open" % boot)
	if not observer:
		return
	for node: Node in world:
		t.check(node != null and observer.is_greater_than(node),
				"in %s the observer processes after %s" % [boot, node.name if node else "null"])

# --------------------------------------------------------------- the escape ---

## A won day 14 handing over: the building's brief, the section lost to the masked man — the day's
## outcome screen — and begun again, the walk out of the service door into the city, and out by the
## tunnel. Each section is counted as a day of its own (`DaySpec.BUILDING_DAY`,
## `DaySpec.CITY_DAY`) beside the escape's own names.
func _test_the_escape_handed_over_lost_and_left(t) -> Array[String]:
	var saved_paused: bool = t.get_tree().paused
	var run := RunState.new()
	run.start_run(SEED)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.facts.escape_section = DaySpec.Section.BUILDING
	var counter := RecordingCounter.new(run)
	t.add_child(counter)
	t.get_tree().paused = true
	var run_log := Telemetry.new("")
	run_log.begin_run(SEED)

	# No `--no-telemetry`: the escape's boot keeps a log already open, so the memory log above, which
	# it is handed, is the one it writes into, its own section header included.
	var home := Boot.home_playing(t, run)
	var config := RunConfig.parse(PackedStringArray(["--no-save"]), "", true)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, config,
			func(m: Node) -> void:
				m.use_sitting_home(home)
				m.use_run_log(run_log))
	var main := booted.main
	var summary := Boot.summary(main)
	t.check(Boot.day(main).spec.section == DaySpec.Section.BUILDING and summary.is_showing(),
			"the escape opened on its brief")
	var brief := _words_on(summary)

	await _continue_while_paused(t, main)
	_check_the_observer_runs_after(t, main, [Boot.day(main), _edge_of(main), Boot.interior(main),
			main.get_node_or_null("BuildingEvents")], "the escape")
	EventBus.hard_fail_triggered.emit("masked_pursuer")
	t.check(summary.is_showing() and _words_on(summary).contains("He caught you on the stairs"),
			"a lost section comes up on the day's outcome screen, with the reason it was lost")
	await _continue_while_paused(t, main)
	t.check(summary.is_showing() and _words_on(summary) == brief,
			"and its continue on the section's brief")
	await _continue_while_paused(t, main)
	Boot.interior(main).exit_requested.emit()
	t.check(Boot.day(main).spec.section == DaySpec.Section.CITY and summary.is_showing(),
			"through the service door, the city opens on its brief")
	await _continue_while_paused(t, main)
	Boot.player(main).global_position = Boot.day(main).spec.exits[CityEdge.Kind.TUNNEL]
	Boot.day(main).tick(0.0)

	var lines := _lines_kept(run_log.current_log().lines)
	var building := "nappy-day-%d-" % DaySpec.BUILDING_DAY
	var city := "nappy-day-%d-" % DaySpec.CITY_DAY
	t.check(counter.sent == [
			"nappy-run-fresh", "nappy-escape-begun", building + "began",
			building + "lost-hard-fail-masked-pursuer", "nappy-escape-lost", building + "began",
			building + "won", "nappy-escape-city", city + "began", city + "blackout", city + "won",
			"nappy-escape-out", "nappy-ending-neutral"],
			"the escape handed over, lost once and left sends exactly these (%s)" % [counter.sent])

	booted.free_all()
	run_log.free()
	home.free()
	counter.free()
	t.get_tree().paused = saved_paused
	return lines

## The words the summary shows, heading and body together: what tells a day's brief from the
## outcome screen of the day it follows.
static func _words_on(summary: Node) -> String:
	var words := ""
	for label_name in ["Heading", "Title", "Note", "Body", "Brief"]:
		var label := summary.find_child(label_name, true, false) as Label
		if label and label.visible:
			words += "%s: %s\n" % [label_name, label.text]
	return words

# ------------------------------------------------------------------ the log ---

## Every line both scenarios wrote, against the lines the same script wrote before the observers were
## rebuilt. The first differing line is named, since a count alone says nothing about which entry
## moved.
func _test_the_run_log_is_the_baseline(t, day_lines: Array[String],
		escape_lines: Array[String]) -> void:
	var got: Array[String] = []
	got.append_array(day_lines)
	got.append(SCENARIO_BREAK)
	got.append_array(escape_lines)
	var file := FileAccess.open(BASELINE, FileAccess.READ)
	t.check(file != null, "the baseline log is there to compare against")
	if not file:
		# What a baseline would hold, each line marked, for re-recording one on purpose.
		for line in got:
			print("observed| " + line)
		return
	var wanted: Array[String] = []
	for line in file.get_as_text().split("\n"):
		wanted.append(line)
	file.close()
	if not wanted.is_empty() and wanted.back() == "":
		wanted.pop_back()
	var first_difference := -1
	for i in maxi(got.size(), wanted.size()):
		var a: String = got[i] if i < got.size() else "<no line>"
		var b: String = wanted[i] if i < wanted.size() else "<no line>"
		if a != b:
			first_difference = i
			t.check(false, "run log line %d is '%s', the baseline's is '%s'" % [i + 1, a, b])
			break
	t.check(first_difference == -1 and got.size() == wanted.size(),
			"the run log is the baseline's, line for line (%d lines, baseline %d)"
					% [got.size(), wanted.size()])

## The lines a run writes that are about the machine rather than the run: a page loaded in so many
## milliseconds, the ground composed in so many. Everything else is a function of the seed and the
## calls above.
static func _lines_kept(lines: Array[String]) -> Array[String]:
	var kept: Array[String] = []
	for line in lines:
		if line.substr(8, 9) == "texture  ":
			continue
		kept.append(line)
	return kept

# ---------------------------------------------------------- the run's own end ---

## A normal run out of nerves goes back to its checkpoint; a hard one ends badly; a final day won
## with the resistance done ends well, and without it neutrally.
func _test_endings_and_checkpoints(t) -> void:
	var run := RunState.new()
	var counter := RecordingCounter.new(run)
	t.add_child(counter)

	run.start_run(SEED)
	run.header.day = 6
	run.header.nerves = 1
	run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)

	run.start_run(SEED)
	run.calendar.choose_mode(true)
	run.header.day = 3
	run.header.nerves = 1
	run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	run.start_run(SEED)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.resistance.progress = Tuning.RESISTANCE_GOAL
	run.resistance.sabotage_done = true
	run.calendar.finish_day(GameEnums.DayResult.WON)

	run.start_run(SEED)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.calendar.finish_day(GameEnums.DayResult.WON)

	t.check(counter.sent == ["nappy-checkpoint-1-from-day-6", "nappy-ending-bad",
			"nappy-ending-good", "nappy-ending-neutral"],
			"a checkpoint and each ending send exactly these (%s)" % [counter.sent])
	counter.free()

## A run begun fresh, one picked back up from the save, and the same run coming back on a reload
## the page itself made, which sends nothing.
func _test_a_fresh_run_a_resume_and_a_reload(t) -> void:
	var run := RunState.new()
	var counter := RecordingCounter.new(run)
	t.add_child(counter)
	EventBus.run_begun.emit(9, true)
	EventBus.run_begun.emit(9, true)
	t.check(counter.sent == ["nappy-run-resumed-day-9"],
			"a resume is counted once, and the page's own reload onto it not again (%s)"
					% [counter.sent])
	counter.free()

	var fresh := RecordingCounter.new(run)
	t.add_child(fresh)
	EventBus.run_begun.emit(1, false)
	EventBus.run_begun.emit(1, false)
	t.check(fresh.sent == ["nappy-run-fresh", "nappy-run-fresh"],
			"a fresh run is counted every time one begins (%s)" % [fresh.sent])
	fresh.free()
