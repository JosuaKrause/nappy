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
	_test_resumed_for_report_truth_table(t)
	_test_a_second_run_begun_on_the_same_page_is_never_reported_as_resumed(t)
	_test_pending_events_queue_until_present_and_flush_in_order(t)
	_test_send_event_never_queues_when_it_may_never_send(t)

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

## Review finding: a genuinely fresh visit that hands over to the escape at day 14 re-enters
## `main._ready()` through `reload_current_scene()`, and `GameSave.try_resume()` there finds the
## save that same reload just wrote — `resumed` (from `EventBus.run_begun`) reads `true`, but the
## page never actually left. `_resumed_for_report()` is the fix: a save is only a resume if this
## page has not already reported a run beginning once before.
func _test_resumed_for_report_truth_table(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._is_the_same_run_reloaded(true, true),
			"a save found by a second run_begun on one page is the same run reloaded: nothing sent")
	t.check(not VISIT_COUNTER_SCRIPT._is_the_same_run_reloaded(false, true),
			"no save on a second run_begun is a new run after a held restart: counted fresh")
	t.check(not VISIT_COUNTER_SCRIPT._is_the_same_run_reloaded(true, false),
			"the page's first run_begun that finds a save is a real resume: counted")
	t.check(VISIT_COUNTER_SCRIPT._resumed_for_report(true, false),
		"a genuine resume, the first time this page has ever reported, stays a resume")
	t.check(not VISIT_COUNTER_SCRIPT._resumed_for_report(true, true),
		"a save found after this page already reported once is this page's own write, not a resume")
	t.check(not VISIT_COUNTER_SCRIPT._resumed_for_report(false, false),
		"no save at all is never a resume")
	t.check(not VISIT_COUNTER_SCRIPT._resumed_for_report(false, true),
		"no save and already reported stays not-a-resume")

## The stateful half: `_reported_run_begun` starts false, flips true on the first `run_begun`, and
## a second one on the same instance — the day-14 handover's own `reload_current_scene()`, or any
## other reload within one page's life — is downgraded to fresh even though `main.gd` still passed
## `resumed = true`, because the save it found is this page's own.
func _test_a_second_run_begun_on_the_same_page_is_never_reported_as_resumed(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	t.check(not counter._reported_run_begun, "a fresh instance has not reported anything yet")
	counter._on_run_begun(1, true)
	t.check(counter._reported_run_begun, "the first call marks the page as having reported")
	# Same instance, a later boot within this page's own life (a day-14 handover, say) — main.gd
	# still passes `resumed = true` because a save now genuinely exists, and the fix is that this
	# object, not main.gd, is what downgrades it.
	t.check(not VISIT_COUNTER_SCRIPT._resumed_for_report(true, counter._reported_run_begun),
		"once this page has reported, a second 'resumed' argument is not trusted as a new resume")
	counter.free()

## Review finding: `count.js` loads asynchronously, so an event asked for before it has finished
## loading — the earliest events of a cold, first-ever visit, above all — must not be dropped
## silently the way a debug build's events are. `_flush_pending()` takes `present` as a parameter
## rather than asking `_goatcounter_present()` itself (which is hard-wired false off the web), so
## the queueing logic is testable here without a real page.
func _test_pending_events_queue_until_present_and_flush_in_order(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	var seeded: Array[String] = ["nappy-run-fresh", "nappy-day-1-began"]
	counter._pending = seeded
	counter._flush_pending(false)
	t.check(counter._pending == seeded,
		"count.js not yet present leaves the queue exactly as it was")
	counter._flush_pending(true)
	t.check(counter._pending.is_empty(),
		"count.js present drains the whole queue, in the order the events were asked for")
	# Flushing an empty queue, present or not, costs nothing and breaks nothing.
	counter._flush_pending(true)
	t.check(counter._pending.is_empty(), "flushing an already-empty queue is a no-op")
	counter.free()

## The other half of the fix: a reason that can never change — off the web, a debug build, or
## `?debug=1` — must never populate the queue at all, the same "still send nothing under debug"
## the gate itself already promised. This process is never on the web, so `_send_event()` refuses
## before `_pending` is ever touched.
func _test_send_event_never_queues_when_it_may_never_send(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	counter._send_event("nappy-run-fresh")
	t.check(counter._pending.is_empty(),
		"off the web, an event is refused outright rather than queued forever unsent")
	counter.free()
