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
## Driven through the real boot with the tree paused, so no frame of the day runs between the calls
## below and every line is stamped at the clock it was written at: a day lost to a car, to her
## crying, to a catalogue row and to dusk, each tried again, then won and the next day begun; then
## the escape handed over from day 14, lost once, walked out of and left by the tunnel — each of its
## sections a day of its own, ended through the day's own finish path.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
## The run log the script below wrote on the build this was recorded on, one line per line; the
## two scenarios are separated by a line of their own (`SCENARIO_BREAK`).
const BASELINE := "res://tests/fixtures/observed_run_log.txt"
const SCENARIO_BREAK := "=== the escape"
const SEED := 4242
## How many frames a boot may take to reach its first day or its first brief before the test gives
## up on it rather than waiting for ever: the boot awaits the canvas-shader warm-up's two frames.
const BOOT_FRAMES := 30

## `VisitCounter` with `_send_event()` recording the name rather than reaching for a page — the same
## stand-in `tests/test_visit_counter.gd` uses — so what each event would send can be read back.
class RecordingCounter extends "res://src/autoload/visit_counter.gd":
	var sent: Array[String] = []

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
	var counter := RecordingCounter.new()
	t.add_child(counter)
	t.get_tree().paused = true
	Telemetry.begin_memory_log()

	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--seed", str(SEED), "--no-telemetry",
			"--no-title", "--no-save"]), "", true))
	t.add_child(main)
	var frames := 0
	while frames < BOOT_FRAMES and not (main._day and main._day.is_running()):
		await t.get_tree().process_frame
		frames += 1
	t.check(main._day != null and main._day.is_running(), "the boot reached day 1")
	_check_the_observer_runs_after(t, main, [main._city, main._resistance, main._edge, main._day],
			"a day")

	main._on_title_start(ControlsMode.Mode.JOYSTICK, false)
	main._on_title_start(ControlsMode.Mode.TAP, true)
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("car_strike")
	main._on_summary_continued()
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	main._on_summary_continued()
	EventBus.hard_fail_triggered.emit("homeless_yeller")
	main._on_summary_continued()
	# Dusk: the day's own clock run out, through the one frame that notices it.
	main._day.time_remaining = 0.0
	main._day._process(0.0)
	main._on_summary_continued()
	main._on_day_finished(GameEnums.DayResult.WON)
	main._on_summary_continued()

	var lines := _lines_kept(Telemetry.current_log().lines)
	Telemetry.end_run()
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

	t.remove_child(main)
	main.free()
	counter.free()
	t.get_tree().paused = saved_paused
	return lines

## The observer stamps its lines with the clock and reads the resistance and the badges, so it has
## to process after them each frame, as it did when `main` added it straight after the day's
## clock: tree order is process order, and the session that holds it is `main`'s first child.
func _check_the_observer_runs_after(t, main: Node, world: Array, boot: String) -> void:
	var observer: TelemetryObserver = main._session.observer()
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
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.escape_section = DaySpec.Section.BUILDING
	var counter := RecordingCounter.new()
	t.add_child(counter)
	t.get_tree().paused = true
	Telemetry.begin_memory_log()

	var main: Node2D = MAIN_SCENE.instantiate()
	# No `--no-telemetry`: the escape's boot keeps a log already open, so the memory log above is the
	# one it writes into, its own section header included.
	main.configure(RunConfig.parse(PackedStringArray(["--no-save"]), "", true))
	t.add_child(main)
	var frames := 0
	while frames < BOOT_FRAMES and not (main._spec.section != DaySpec.Section.NONE
			and main._summary.is_showing()):
		await t.get_tree().process_frame
		frames += 1
	t.check(main._spec.section == DaySpec.Section.BUILDING and main._summary.is_showing(),
			"the escape opened on its brief")

	main._on_summary_continued()
	_check_the_observer_runs_after(t, main, [main._day, main._edge, main._interior,
			main._interior_events], "the escape")
	t.get_tree().paused = true
	EventBus.hard_fail_triggered.emit("masked_pursuer")
	t.check(main._summary.is_showing() and not main._resume_gate_open,
			"a lost section comes up on the day's outcome screen")
	main._on_summary_continued()
	t.check(main._summary.is_showing() and main._resume_gate_open,
			"and its continue on the section's brief")
	main._on_summary_continued()
	t.get_tree().paused = true
	main._interior.exit_requested.emit()
	t.check(main._spec.section == DaySpec.Section.CITY and main._summary.is_showing(),
			"through the service door, the city opens on its brief")
	main._on_summary_continued()
	t.get_tree().paused = true
	main._player.global_position = main._spec.exits[CityEdge.Kind.TUNNEL]
	main._day._process(0.0)

	var lines := _lines_kept(Telemetry.current_log().lines)
	Telemetry.end_run()
	var building := "nappy-day-%d-" % DaySpec.BUILDING_DAY
	var city := "nappy-day-%d-" % DaySpec.CITY_DAY
	t.check(counter.sent == [
			"nappy-run-fresh", "nappy-escape-begun", building + "began",
			building + "lost-hard-fail-masked-pursuer", "nappy-escape-lost", building + "began",
			building + "won", "nappy-escape-city", city + "began", city + "blackout", city + "won",
			"nappy-escape-out", "nappy-ending-neutral"],
			"the escape handed over, lost once and left sends exactly these (%s)" % [counter.sent])

	t.remove_child(main)
	main.free()
	counter.free()
	GameState.escape_section = DaySpec.Section.NONE
	t.get_tree().paused = saved_paused
	return lines

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
	var counter := RecordingCounter.new()
	t.add_child(counter)

	GameState.start_run(SEED)
	GameState.day = 6
	GameState.nerves = 1
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)

	GameState.start_run(SEED)
	GameState.choose_mode(true)
	GameState.day = 3
	GameState.nerves = 1
	GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.sabotage_done = true
	GameState.finish_day(GameEnums.DayResult.WON)

	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.finish_day(GameEnums.DayResult.WON)

	t.check(counter.sent == ["nappy-checkpoint-1-from-day-6", "nappy-ending-bad",
			"nappy-ending-good", "nappy-ending-neutral"],
			"a checkpoint and each ending send exactly these (%s)" % [counter.sent])
	counter.free()
	GameState.start_run(SEED)

## A run begun fresh, one picked back up from the save, and the same run coming back on a reload
## the page itself made, which sends nothing.
func _test_a_fresh_run_a_resume_and_a_reload(t) -> void:
	var counter := RecordingCounter.new()
	t.add_child(counter)
	EventBus.run_begun.emit(9, true)
	EventBus.run_begun.emit(9, true)
	t.check(counter.sent == ["nappy-run-resumed-day-9"],
			"a resume is counted once, and the page's own reload onto it not again (%s)"
					% [counter.sent])
	counter.free()

	var fresh := RecordingCounter.new()
	t.add_child(fresh)
	EventBus.run_begun.emit(1, false)
	EventBus.run_begun.emit(1, false)
	t.check(fresh.sent == ["nappy-run-fresh", "nappy-run-fresh"],
			"a fresh run is counted every time one begins (%s)" % [fresh.sent])
	fresh.free()
