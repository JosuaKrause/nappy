extends RefCounted
## `VisitCounter`'s own pure halves — the gate's truth table and the event-name builders — plus a
## check that answering every signal it connects to touches nothing `GameState` owns, the same
## invariant `tests/test_telemetry.gd` pins for the run log.
##
## `VisitCounter` is an autoload, and "autoload names cannot also be `class_name` types"
## (`game_enums.gd`'s own doc), so it is reached here the same way `test_player_presentation.gd`
## reaches `GameState`'s own script: a `preload()` of the file rather than the bare autoload name,
## which is what lets a fresh instance be built for the state test below without touching the
## live singleton every other suite's own signals also reach.

const VISIT_COUNTER_SCRIPT = preload("res://src/autoload/visit_counter.gd")

func run(t) -> void:
	_test_should_send_truth_table(t)
	_test_day_event_name(t)
	_test_loss_cause_names_every_day_result(t)
	_test_run_begun_name(t)
	_test_controls_event_name(t)
	_test_listening_touches_no_gameplay_state(t)
	_test_task_skipped_only_for_a_step_still_open_on_its_own_day(t)

## `_should_send()` — on the web, released, unasked-for and with a live
## `window.goatcounter.count` are all four required; missing any one of them refuses.
func _test_should_send_truth_table(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._should_send(true, false, false, true),
		"web, a release build, no ?debug=1, and goatcounter present sends")
	t.check(not VISIT_COUNTER_SCRIPT._should_send(false, false, false, true),
		"off the web, nothing is sent no matter what else is true")
	t.check(not VISIT_COUNTER_SCRIPT._should_send(true, true, false, true),
		"a debug build sends nothing, on the web or off it")
	t.check(not VISIT_COUNTER_SCRIPT._should_send(true, false, true, true),
		"?debug=1 (DevFlags.readout_requested()) sends nothing even on a release web build")
	t.check(not VISIT_COUNTER_SCRIPT._should_send(true, false, false, false),
		"a missing or blocked window.goatcounter sends nothing")
	t.check(not VISIT_COUNTER_SCRIPT._should_send(false, true, true, false),
		"every reason to refuse at once still refuses")

func _test_day_event_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._day_event_name(6, "lost-crying") == "nappy-day-6-lost-crying",
		"day and suffix join the way PLAYTEST-132's own example does")
	t.check(VISIT_COUNTER_SCRIPT._day_event_name(1, "began") == "nappy-day-1-began",
		"a plain day-scoped name")
	t.check(VISIT_COUNTER_SCRIPT._day_event_name(14, "task-skipped") == "nappy-day-14-task-skipped",
		"a two-word suffix stays hyphenated, not a second underscore")

## `GameEnums.DayResult`'s own keys are the loss causes — nothing here invents a second name for
## one, it only lowercases and hyphenates the key already in the game.
func _test_loss_cause_names_every_day_result(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._loss_cause(GameEnums.DayResult.WON) == "won",
		"a win names itself, no 'lost-' prefix")
	t.check(VISIT_COUNTER_SCRIPT._loss_cause(GameEnums.DayResult.LOST_CRYING) == "lost-crying",
		"an enum key's underscore becomes the name's own hyphen")
	t.check(VISIT_COUNTER_SCRIPT._loss_cause(GameEnums.DayResult.LOST_TIMEOUT) == "lost-timeout",
		"the timeout loss")
	t.check(VISIT_COUNTER_SCRIPT._loss_cause(GameEnums.DayResult.LOST_HARD_FAIL) == "lost-hard-fail",
		"a two-word cause stays entirely hyphenated")

func _test_run_begun_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._run_begun_name(1, false) == "nappy-run-fresh",
		"a fresh run always starts day 1, not worth repeating in the name")
	t.check(VISIT_COUNTER_SCRIPT._run_begun_name(9, true) == "nappy-run-resumed-day-9",
		"a resumed run names the day it resumed on")

func _test_controls_event_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._controls_event_name(ControlsMode.Mode.JOYSTICK)
			== "nappy-controls-joystick", "the joystick scheme")
	t.check(VISIT_COUNTER_SCRIPT._controls_event_name(ControlsMode.Mode.TAP)
			== "nappy-controls-tap", "the tap scheme")

## Drives every signal handler the counter connects to and checks that none of it moved anything
## `GameState` owns. This process is never on the web (`OS.get_name() != "Web"`), so
## `should_send()` refuses every one of these and `_send_event()` never reaches
## `JavaScriptBridge` at all — the point of the check is that the *listening* itself is inert, the
## same "telemetry must not touch gameplay" invariant `tests/test_telemetry.gd` pins for the run
## log, adapted for a listener with no per-frame watch of its own.
func _test_listening_touches_no_gameplay_state(t) -> void:
	t.check(not VISIT_COUNTER_SCRIPT.should_send(),
		"a headless test process is never the web, so nothing below can reach a real page")
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	var before := _gamestate_snapshot()
	counter._on_run_begun(1, false)
	counter._on_day_started(1)
	counter._on_task_offered(0)
	counter._on_task_completed(0)
	counter._on_task_offered(1)
	counter._on_task_failed(1)
	counter._on_day_ended(1, GameEnums.DayResult.WON)
	counter._on_run_restarted(1)
	counter._on_run_ended(GameEnums.Ending.NEUTRAL)
	counter._on_escape_begun()
	counter._on_escape_lost()
	counter._on_escape_out()
	counter._on_controls_chosen(ControlsMode.Mode.TAP)
	var after := _gamestate_snapshot()
	t.check(before == after,
		"answering every signal the counter connects to leaves GameState untouched")
	counter.free()

func _gamestate_snapshot() -> Dictionary:
	return {
		"day": GameState.day,
		"nerves": GameState.nerves,
		"resistance_progress": GameState.resistance_progress,
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
		"ending": GameState.ending,
	}

## The bookkeeping behind "each task done, and each task skipped (a task day that ended without
## it), by day" — a step offered and then completed never reaches `_on_day_ended()`'s own sweep; a
## step offered and never touched, or offered on an earlier day and still open, does. Checked
## through `_open_tasks` directly, the one piece of state private to the counter, since the
## `_send_event` calls themselves are silent in this process (see the test above).
func _test_task_skipped_only_for_a_step_still_open_on_its_own_day(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	counter._on_task_offered(5)
	counter._on_task_completed(5)
	t.check(not counter._open_tasks.has(5), "a completed step is no longer open")
	counter._on_task_offered(6)
	t.check(counter._open_tasks.has(6), "an offered, untouched step stays open")
	counter._on_day_ended(GameState.day, GameEnums.DayResult.LOST_TIMEOUT)
	t.check(not counter._open_tasks.has(6),
		"the day it belonged to ending, won or lost, closes it out as skipped")
	counter.free()
