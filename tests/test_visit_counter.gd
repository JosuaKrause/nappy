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

## `VisitCounter` with `_send_event()` recording the name instead of reaching for a page, so a test
## can read what each signal would send. Everything else is the real counter's own code.
class RecordingCounter extends "res://src/autoload/visit_counter.gd":
	var sent: Array[String] = []

	func _send_event(name: String) -> void:
		sent.append(name)

func run(t) -> void:
	_test_should_send_truth_table(t)
	_test_day_event_name(t)
	_test_loss_cause_names_every_day_result(t)
	_test_loss_event_suffix_folds_a_cause_only_for_the_two_results_that_ever_have_one(t)
	_test_run_begun_name(t)
	_test_mode_event_name(t)
	_test_day_began_names(t)
	_test_checkpoint_event_name(t)
	_test_a_hard_run_counts_its_days_twice_and_a_normal_run_once(t)
	_test_controls_event_name(t)
	_test_detention_suffix(t)
	_test_is_pickup_step(t)
	_test_listening_touches_no_gameplay_state(t)
	_test_task_skipped_only_for_a_step_still_open_on_its_own_day(t)
	_test_mark_and_task_sends_are_split_by_the_resistance_own_data(t)
	_test_every_tear_and_every_hold_is_sent(t)
	_test_a_lost_day_folds_its_cause_into_one_event_not_two(t)
	_test_a_hard_fail_day_folds_its_cause_too(t)
	_test_a_lost_day_with_no_recorded_cause_still_sends_the_bare_loss_name(t)
	_test_won_and_timeout_never_carry_a_pending_cause(t)
	_test_resumed_for_report_truth_table(t)
	_test_a_second_run_begun_on_the_same_page_is_never_reported_as_resumed(t)
	_test_pending_events_queue_until_present_and_flush_in_order(t)
	_test_send_event_never_queues_when_it_may_never_send(t)
	_test_a_chase_is_reported_once_however_the_pursuer_arrived(t)
	_test_a_waiting_dog_is_counted_warned_then_chased(t)
	_test_every_charger_has_its_own_counter(t)
	_test_a_charge_ends_in_exactly_one_of_three(t)
	_test_the_lesson_dog_has_its_own_set(t)
	_test_a_raised_hand_is_counted_warned_and_the_charge_chased(t)
	_test_the_masked_man_has_his_counter(t)
	_test_a_charge_cut_short_by_the_day_is_counted_ended(t)
	_test_the_pelican_is_its_own_entry(t)
	_test_a_day_lost_to_the_pelican_names_the_pelican(t)
	_test_encounters_and_runs_are_named_by_their_day_and_row(t)
	_test_an_escape_section_is_counted_as_a_day_of_its_own(t)
	_test_every_event_opts_out_of_sessions(t)

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
		"?debug=1 (RunConfig.readout_requested) sends nothing even on a release web build")
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

## `_loss_event_suffix()` is what `_on_day_ended()` actually sends: `_loss_cause(result)` with
## `EventBus.day_ended`'s own raw cause folded on, for the two results that ever have one — a win
## or a timeout keeps its bare name even if it is (wrongly) handed a cause, since the game names
## none for either.
func _test_loss_event_suffix_folds_a_cause_only_for_the_two_results_that_ever_have_one(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._loss_event_suffix(GameEnums.DayResult.LOST_CRYING, "traffic")
			== "lost-crying-traffic", "a crying loss folds its cause on")
	t.check(VISIT_COUNTER_SCRIPT._loss_event_suffix(GameEnums.DayResult.LOST_HARD_FAIL, "car")
			== "lost-hard-fail-car", "a hard fail folds its cause on the same way")
	t.check(VISIT_COUNTER_SCRIPT._loss_event_suffix(GameEnums.DayResult.LOST_CRYING, "")
			== "lost-crying", "no recorded cause sends the bare loss name rather than nothing")
	t.check(VISIT_COUNTER_SCRIPT._loss_event_suffix(GameEnums.DayResult.WON, "traffic") == "won",
		"a win never carries a cause, whatever is pending")
	t.check(VISIT_COUNTER_SCRIPT._loss_event_suffix(GameEnums.DayResult.LOST_TIMEOUT, "traffic")
			== "lost-timeout", "a timeout never carries a cause either")

func _test_run_begun_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._run_begun_name(1, false) == "nappy-run-fresh",
		"a fresh run always starts day 1, not worth repeating in the name")
	t.check(VISIT_COUNTER_SCRIPT._run_begun_name(9, true) == "nappy-run-resumed-day-9",
		"a resumed run names the day it resumed on")

func _test_mode_event_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._mode_event_name(true) == "nappy-mode-hard", "a hard run")
	t.check(VISIT_COUNTER_SCRIPT._mode_event_name(false) == "nappy-mode-normal", "a normal run")

## Every run keeps the plain `began`, so its series runs on unbroken; a hard run adds its copy.
func _test_day_began_names(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._day_began_names(5, false) == ["nappy-day-5-began"],
		"a normal run's day sends the plain name alone")
	t.check(VISIT_COUNTER_SCRIPT._day_began_names(5, true)
			== ["nappy-day-5-began", "nappy-day-5-began-hard"],
		"a hard run's day sends the plain name and its hard-only copy")

func _test_checkpoint_event_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._checkpoint_event_name(8, 10) == "nappy-checkpoint-8-from-day-10",
		"the checkpoint gone back to, and the day the last nerve was lost on")
	t.check(VISIT_COUNTER_SCRIPT._checkpoint_event_name(1, 2) == "nappy-checkpoint-1-from-day-2",
		"checkpoint zero is day 1")

## The day a fresh run's title stands in front of has already begun as a normal run's by the time
## the title says the run is hard, so the counter sends that day's hard copy with the mode; every
## later day of a hard run sends it from `day_started` itself.
func _test_a_hard_run_counts_its_days_twice_and_a_normal_run_once(t) -> void:
	var saved := GameState.hard_mode
	var counter := RecordingCounter.new()
	GameState.hard_mode = false
	counter._on_day_started(1)
	counter._on_run_mode_chosen(true, 1)
	GameState.hard_mode = true
	counter._on_day_started(2)
	t.check(counter.sent == ["nappy-day-1-began", "nappy-mode-hard", "nappy-day-1-began-hard",
			"nappy-day-2-began", "nappy-day-2-began-hard"],
			"a hard run's first day is counted hard once its mode is known (%s)" % [counter.sent])
	counter.sent.clear()
	GameState.hard_mode = false
	counter._on_day_started(1)
	counter._on_run_mode_chosen(false, 1)
	counter._on_went_back_to_a_checkpoint(4, 7)
	t.check(counter.sent == ["nappy-day-1-began", "nappy-mode-normal",
			"nappy-checkpoint-4-from-day-7"],
			"a normal run's days are counted once, and its checkpoint restart named (%s)"
					% [counter.sent])
	GameState.hard_mode = saved
	counter.free()

## A key begins the run in the tap scheme, and is still reported as keys: the name comes from the
## input that began the run, not the scheme it fell back to.
func _test_controls_event_name(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._controls_event_name(true, false)
			== "nappy-controls-joystick", "the joystick button")
	t.check(VISIT_COUNTER_SCRIPT._controls_event_name(false, false)
			== "nappy-controls-tap", "the tap button")
	t.check(VISIT_COUNTER_SCRIPT._controls_event_name(false, true)
			== "nappy-controls-keys", "a key, whose run begins in tap mode, is reported as keys")

## `chatting_mother` is a `chat`; every other id that can reach `EventBus.player_detained` — the
## catalogue's only other two rows with a `detain_seconds` above zero — is a `checkpoint`.
func _test_detention_suffix(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._detention_suffix("chatting_mother") == "chat",
		"the mother who stops her for a conversation")
	t.check(VISIT_COUNTER_SCRIPT._detention_suffix("checkpoint_hut") == "checkpoint",
		"a checkpoint's hut")
	t.check(VISIT_COUNTER_SCRIPT._detention_suffix("checkpoint_post") == "checkpoint",
		"a checkpoint's post")

## The mark/task split comes from `ResistanceSteps` itself — index 1 is day 6's chalk mark and
## index 2 is the perform step it unlocks (`ResistanceSteps._build()`), so this is real catalogue
## data rather than an index chosen to make the parity come out right.
func _test_is_pickup_step(t) -> void:
	t.check(VISIT_COUNTER_SCRIPT._is_pickup_step(1), "index 1 is day 6's chalk mark")
	t.check(not VISIT_COUNTER_SCRIPT._is_pickup_step(2),
		"index 2 is the perform step the mark unlocks")
	t.check(not VISIT_COUNTER_SCRIPT._is_pickup_step(17),
		"the finale's own step is not a pickup either")
	t.check(not VISIT_COUNTER_SCRIPT._is_pickup_step(999),
		"an index the resistance does not know reads as a task, the safer default")

## Drives every signal handler the counter connects to and checks that none of it moved anything
## `GameState` owns. This process is never on the web (`OS.get_name() != "Web"`), so
## `should_send()` refuses every one of these and `_send_event()` never reaches
## `JavaScriptBridge` at all — the point of the check is that the *listening* itself is inert, the
## same "telemetry must not touch gameplay" invariant `tests/test_telemetry.gd` pins for the run
## log, adapted for a listener with no per-frame watch of its own.
func _test_listening_touches_no_gameplay_state(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	t.check(not counter.should_send(),
		"a counter handed no configuration sends nothing")
	counter.configure(RunConfig.parse(PackedStringArray(), "", false))
	t.check(not counter.should_send(),
		"a headless test process is never the web, so nothing below can reach a real page")
	var before := _gamestate_snapshot()
	counter._on_run_begun(1, false)
	counter._on_day_started(1)
	counter._on_task_offered(0)
	counter._on_task_completed(0)
	counter._on_task_offered(1)
	counter._on_task_failed(1)
	counter._on_mark_seen(1)
	counter._on_event_sighted("burning_building")
	counter._on_event_lit_unmet("burning_building")
	counter._on_city_gone_dark()
	counter._on_pursuit_warned("charging_dog")
	counter._on_pursuit_began("charging_dog")
	counter._on_pursuit_caught("alley_robbery")
	counter._on_pursuit_cut_short("alley_robbery")
	counter._on_pursuit_ended("charging_dog", true)
	counter._on_encounter_seen(1, "homeless_yeller")
	counter._on_encounter_influenced(1, "homeless_yeller", true)
	counter._on_encounter_influenced(1, "pelican", false)
	counter._on_run_bout_began(1)
	counter._on_pelican_spawned(null)
	counter._on_pelican_sighted(null)
	counter._on_pelican_excited_her(null)
	counter._on_pelican_struck_her(null)
	counter._on_poster_torn()
	counter._on_poster_pursuit_sent()
	counter._on_player_detained("chatting_mother")
	counter._on_day_ended(1, GameEnums.DayResult.WON, "", 0.0)
	counter._on_run_restarted(1)
	counter._on_run_ended(GameEnums.Ending.NEUTRAL)
	counter._on_escape_begun()
	counter._on_escape_city_entered()
	counter._on_escape_lost(DaySpec.Section.BUILDING, GameEnums.DayResult.LOST_CRYING)
	counter._on_escape_out(CityEdge.Kind.TUNNEL)
	counter._on_controls_chosen(false, true)
	counter._on_run_mode_chosen(true, 1)
	counter._on_went_back_to_a_checkpoint(4, 6)
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
	counter._on_day_ended(GameState.day, GameEnums.DayResult.LOST_TIMEOUT, "", 0.0)
	t.check(not counter._open_tasks.has(6),
		"the day it belonged to ending, won or lost, closes it out as skipped")
	counter.free()

## `_on_task_completed()`/`_on_task_failed()`/`_on_day_ended()`'s own sweep all ask
## `_is_pickup_step()` rather than a parity rule of their own — checked here through `_open_tasks`
## directly, since `_send_event` itself is silent in this process (see the test above this one).
## Index 1 (day 6's mark) and index 2 (the perform step it unlocks) are real `ResistanceSteps` data,
## not indices chosen to make a parity come out right.
func _test_mark_and_task_sends_are_split_by_the_resistance_own_data(t) -> void:
	var counter: Node = VISIT_COUNTER_SCRIPT.new()
	counter._on_task_offered(1)
	counter._on_task_offered(2)
	counter._on_task_completed(1)
	counter._on_task_completed(2)
	t.check(not counter._open_tasks.has(1) and not counter._open_tasks.has(2),
		"a completed mark and a completed task both close out, whatever they are sent as")
	counter._on_task_offered(1)
	counter._on_task_offered(2)
	counter._on_day_ended(GameState.day, GameEnums.DayResult.LOST_TIMEOUT, "", 0.0)
	t.check(not counter._open_tasks.has(1) and not counter._open_tasks.has(2),
		"the day ending closes out an untouched mark and an untouched task alike")
	counter.free()

## `poster-torn`, `chat` and `checkpoint` are sent every time, within one attempt and across a
## retry alike: every event opts out of the site's sessions so that a count is every time a thing
## happened
## (PLAYTEST-143: "no, even current run wouldn't work if the player dies multiple times on the same
## day"). Read off `RecordingCounter`, which keeps what `_send_event()` was asked for, since the
## real one is silent in this process.
func _test_every_tear_and_every_hold_is_sent(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_day_started(day)
	counter._on_poster_torn()
	counter._on_poster_torn()
	counter._on_player_detained("checkpoint_hut")
	counter._on_player_detained("checkpoint_hut")
	counter._on_day_started(day)
	counter._on_poster_torn()
	var torn := "nappy-day-%d-poster-torn" % day
	var held := "nappy-day-%d-checkpoint" % day
	t.check(counter.sent.count(torn) == 3,
		"two tears in one attempt and one in the retry are three poster-torn events")
	t.check(counter.sent.count(held) == 2, "a checkpoint that holds her twice is two events")
	counter._on_poster_pursuit_sent()
	t.check(counter.sent.back() == "nappy-day-%d-poster-pursuit" % day,
		"a tear that sends a pursuer on foot sends its own poster-pursuit")
	counter.free()

## The fold this counter makes: the day's end's own cause becomes part of the one event a lost day
## sends, never a `lost-crying` beside a second `noise-traffic` of its own — the double counting the
## player asked to see gone ("lost-crying still doesn't tell me anything about how they died").
func _test_a_lost_day_folds_its_cause_into_one_event_not_two(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_day_ended(day, GameEnums.DayResult.LOST_CRYING, "traffic", 0.0)
	t.check(counter.sent == ["nappy-day-%d-lost-crying-traffic" % day],
		"the cause and the loss kind fold into one event, not a lost-crying beside a noise-traffic")
	counter.free()

## A hard-fail day folds the same way, off `_hard_fail_cause_suffix()`'s own raw name, as the day's
## end carries it.
func _test_a_hard_fail_day_folds_its_cause_too(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_day_ended(day, GameEnums.DayResult.LOST_HARD_FAIL, "alley-robbery", 0.0)
	t.check(counter.sent == ["nappy-day-%d-lost-hard-fail-alley-robbery" % day],
		"a hard fail folds its cause the same way a crying loss does")
	counter.free()

## A lost day ended with no cause still sends the bare loss name rather than nothing.
func _test_a_lost_day_with_no_recorded_cause_still_sends_the_bare_loss_name(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_day_ended(day, GameEnums.DayResult.LOST_CRYING, "", 0.0)
	t.check(counter.sent.has("nappy-day-%d-lost-crying" % day),
		"an unknown cause sends the bare loss name instead of silently dropping the day's own end")
	counter.free()

## A cause never attaches to a result that has none. The game names a cause only for
## `LOST_CRYING`/`LOST_HARD_FAIL`, so a `WON` or `LOST_TIMEOUT` handed one can only happen by driving
## the handler directly, the way this test does — and even then, the bare name is what is sent.
func _test_won_and_timeout_never_carry_a_pending_cause(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_day_ended(day, GameEnums.DayResult.WON, "traffic", 0.0)
	t.check(counter.sent == ["nappy-day-%d-won" % day], "a win never carries a leftover cause")
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

## `EventBus.pursuit_began` (the counter's `dog-chased`) fires once per chase, and **a pursuer
## created where its warning pointed reports the chase it starts**. `EventManager.spawn_warned()`
## creates such a row through `EventInstance.resume()` to spend the telegraph the warning already
## ran, and a resume otherwise stands for an instance streamed back in, whose chase — for a row
## like `charging_dog` that never waits (`pursues_within` 0.0) — began before it streamed out and
## was already reported. Three arrivals of the one row: placed at once and telegraphing, created
## warned the way `spawn_warned()` does it (`came_under_a_warning` set, then `resume()`), and
## streamed back in mid-chase, which reports nothing a second time.
func _test_a_chase_is_reported_once_however_the_pursuer_arrived(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	t.check(def.pursues and def.pursues_within <= 0.0,
		"'charging_dog' is a pursuer that never waits, the case a resume could misread")
	var began: Array[String] = []
	var on_began := func(id: String) -> void: began.append(id)
	EventBus.pursuit_began.connect(on_began)
	var step := 1.0 / 60.0
	var her := Vector2(200.0, 0.0)

	var placed := EventInstance.new()
	placed.setup(def, Vector2.ZERO)
	t.add_child(placed)
	placed.set_process(false)
	for i in int(ceil((def.telegraph_time + 0.5) / step)):
		placed.player_at = her
		placed._process(step)
	t.check(began.size() == 1, "placed at once, its chase is reported once after its telegraph "
		+ "(%d reports)" % began.size())
	var age := placed.age
	var travelled := placed.path_travelled()
	placed.free()

	began.clear()
	var streamed := EventInstance.new()
	streamed.setup(def, Vector2.ZERO)
	t.add_child(streamed)
	streamed.set_process(false)
	streamed.resume(age, travelled)
	for i in 10:
		streamed.player_at = her
		streamed._process(step)
	t.check(began.is_empty(), "streamed back in mid-chase, the same chase is not reported again")
	streamed.free()

	var warned := EventInstance.new()
	warned.setup(def, Vector2.ZERO)
	t.add_child(warned)
	warned.set_process(false)
	warned.came_under_a_warning = true
	warned.resume(def.telegraph_time, 0.0)
	for i in 10:
		warned.player_at = her
		warned._process(step)
	t.check(began.size() == 1 and began[0] == "charging_dog",
		"created where its warning pointed, its chase is reported once (%s)" % [began])
	warned.free()
	EventBus.pursuit_began.disconnect(on_began)

## **A waiting dog's warning is its own level below its charge** *(inbox #764 in minty-lemur, the player: dog-chased
## implies the charge; a warning level of its own)*. Walked with the real `EventInstance` and the
## real signals, read off `RecordingCounter`: the dog that waits past `Tuning.RUN_TAUGHT_DAY` sends
## `dog-warned` once when it starts warning her, nothing for a warning she walks out of or a second
## warning, and `dog-chased` only at its charge; the alley robber's warning sends his own
## `alley-robbery-warned`.
func _test_a_waiting_dog_is_counted_warned_then_chased(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var def := EventScheduler._for_day(EventCatalogue.by_id("charging_dog"), Tuning.RUN_TAUGHT_DAY + 1)
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
	var dog := _charger(t, def)
	_walk(dog, Vector2(def.pursues_within - 10.0, 0.0), 1.0)
	t.check(counter.sent == ["nappy-day-%d-dog-warned" % day],
		"warning her, the dog is counted warned and not chased (%s)" % [counter.sent])
	_walk(dog, Vector2(def.pursues_within + 10.0, 0.0), 0.5)
	_walk(dog, Vector2(def.pursues_within - 10.0, 0.0), 0.5)
	t.check(counter.sent.size() == 1, "walked out of and back into, it is not counted again (%s)"
		% [counter.sent])
	_walk(dog, Vector2(standoff - 2.0, 0.0), def.warns_for + 0.2)
	t.check(counter.sent == ["nappy-day-%d-dog-warned" % day, "nappy-day-%d-dog-chased" % day],
		"its charge, once its warning has run with her still inside, is counted chased (%s)"
		% [counter.sent])
	dog.free()
	counter.sent.clear()
	var robber := _charger(t, EventCatalogue.by_id("alley_robbery"))
	_walk(robber, Vector2(170.0, 0.0), 1.0 / 60.0)
	t.check(counter.sent == ["nappy-day-%d-alley-robbery-warned" % day],
		"the robber's warning is counted under his own name (%s)" % [counter.sent])
	robber.free()
	_unlisten(listening)
	counter.free()

## **Every charger has a counter of its own, named by its row** *(inbox #764 in minty-lemur, the player: "Ending a
## day and a charging counter are not the same thing")*, the dog keeping its `dog-*` names and the
## day-3 lesson's dog its own `dog-tutorial-*`.
func _test_every_charger_has_its_own_counter(t) -> void:
	var names := {"charging_dog": "dog", "charging_dog_tutorial": "dog-tutorial",
			"alley_robbery": "alley-robbery", "roadblock": "roadblock", "door_guard": "door-guard",
			"robber_giving_chase": "robber-giving-chase",
			"van_guard_giving_chase": "van-guard-giving-chase",
			"policeman_giving_chase": "policeman-giving-chase",
			"guardsman_giving_chase": "guardsman-giving-chase"}
	for id: String in names.keys():
		t.check(VISIT_COUNTER_SCRIPT.charger_counter_name(id) == names[id],
			"'%s' is counted as '%s'" % [id, VISIT_COUNTER_SCRIPT.charger_counter_name(id)])
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_pursuit_began("door_guard")
	counter._on_pursuit_caught("door_guard")
	counter._on_pursuit_began("policeman_giving_chase")
	counter._on_pursuit_ended("policeman_giving_chase", true)
	t.check(counter.sent == ["nappy-day-%d-door-guard-chased" % day,
			"nappy-day-%d-door-guard-caught" % day,
			"nappy-day-%d-policeman-giving-chase-chased" % day,
			"nappy-day-%d-policeman-giving-chase-shaken" % day],
		"each charger's charge and its end go under its own name (%s)" % [counter.sent])
	counter.free()

## **A charge ends in exactly one of caught, shaken off and outlasted, whatever the day does**
## *(inbox #764 in minty-lemur, the player: "Charging is independent of an ended day")*. The real instance and
## signals, for a sent robber, who charges from his first frame: caught (`report_the_catch()`, what
## `EventManager._check_hard_fails()` and a patrol car's man stopping her call) and then finished
## anyway, as a day that goes on under `--invincible` would; run off; and walked away from until his
## clock runs out. Each sends `-chased` and then one end, and a catch said twice is counted once.
func _test_a_charge_ends_in_exactly_one_of_three(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var def := EventCatalogue.by_id("robber_giving_chase")
	var name := "nappy-day-%d-robber-giving-chase-" % day

	var caught := _charger(t, def)
	_walk(caught, Vector2(300.0, 0.0), 0.2)
	caught.report_the_catch()
	caught.report_the_catch()
	caught._be_done()
	t.check(counter.sent == [name + "chased", name + "caught"],
		"caught, it is counted caught once and never also outlasted (%s)" % [counter.sent])
	caught.free()

	counter.sent.clear()
	var shaken := _charger(t, def)
	var step := 1.0 / 60.0
	var her := Vector2(300.0, 0.0)
	for i in int(round(3.0 / step)):
		her.x += Tuning.RUN_SPEED * step
		shaken.player_at = her
		shaken.player_running = true
		shaken._process(step)
		if shaken.is_leaving:
			break
	t.check(counter.sent == [name + "chased", name + "shaken"],
		"run off, it is counted shaken (%s)" % [counter.sent])
	shaken.free()

	counter.sent.clear()
	var outlasted := _charger(t, def)
	for i in int(round((def.telegraph_time + def.duration + 1.0) / step)):
		outlasted.player_at = outlasted.global_position + Vector2(400.0, 0.0)
		outlasted._process(step)
		if outlasted.is_leaving:
			break
	t.check(counter.sent == [name + "chased", name + "outlasted"],
		"its clock run out, it is counted outlasted (%s)" % [counter.sent])
	outlasted.free()
	_unlisten(listening)
	counter.free()

## **The day-3 lesson's dog has its own set and not the dog's** *(PLAYTEST-141: "we need to record
## like dog tutorial")*: `EventInstance.is_the_lesson`, which `EventManager._create()` sets on the
## first dog it makes on `Tuning.RUN_TAUGHT_DAY`, names its charge `dog-tutorial-*`; a second dog
## that day is an ordinary `dog`.
func _test_the_lesson_dog_has_its_own_set(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var def := EventCatalogue.by_id("charging_dog")
	var lesson := _charger(t, def)
	lesson.is_the_lesson = true
	t.check(lesson.charger_name() == "charging_dog_tutorial", "the lesson's dog is named apart")
	_walk(lesson, Vector2(400.0, 0.0), def.telegraph_time + 0.5)
	lesson.report_the_catch()
	t.check(counter.sent == ["nappy-day-%d-dog-tutorial-chased" % day,
			"nappy-day-%d-dog-tutorial-caught" % day],
		"it sends its own set, and none of the dog's (%s)" % [counter.sent])
	lesson.free()
	counter.sent.clear()
	var later := _charger(t, def)
	_walk(later, Vector2(400.0, 0.0), def.telegraph_time + 0.5)
	t.check(counter.sent == ["nappy-day-%d-dog-chased" % day],
		"a dog that is not the lesson's is an ordinary dog (%s)" % [counter.sent])
	later.free()
	_unlisten(listening)
	counter.free()

## **A raised hand is a warning, and the charge comes after it** *(inbox #764 in minty-lemur, the player: "Dog-chased
## implies charge")*. The man a vehicle lets out stands with his hand raised for a second: the
## counter sends his `-warned` as the hand goes up, nothing more for that second, and `-chased` only
## when he charges. Day 13's guard set on her in her view counts the same way, as `task-guard`.
func _test_a_raised_hand_is_counted_warned_and_the_charge_chased(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var def := EventCatalogue.out_of_the_car(EventCatalogue.guardsmen_from_day())
	var man := _charger(t, def)
	man.global_position = Vector2(150.0, 0.0)
	_walk(man, Vector2.ZERO, 1.0 / 60.0)
	var name := "nappy-day-%d-guardsman-giving-chase-" % day
	t.check(counter.sent == [name + "warned"],
		"his raised hand is counted warned at once (%s)" % [counter.sent])
	_walk(man, Vector2.ZERO, def.telegraph_time - 0.1)
	t.check(counter.sent == [name + "warned"],
		"and nothing more while it is up (%s)" % [counter.sent])
	_walk(man, Vector2.ZERO, 0.2)
	t.check(counter.sent == [name + "warned", name + "chased"],
		"his charge is counted chased (%s)" % [counter.sent])
	man.free()
	counter.sent.clear()
	var guard := _charger(t, EventCatalogue.by_id("alley_robbery"))
	guard.counted_as = "task_guard"
	guard.notice_her_at(Vector2(300.0, 0.0), Tuning.WARNING_ALONE_MAX, true)
	_walk(guard, Vector2(300.0, 0.0), 0.5)
	t.check(counter.sent == ["nappy-day-%d-task-guard-warned" % day],
		"day 13's guard warning in her view is counted warned, as the task's guard (%s)" % [counter.sent])
	_walk(guard, Vector2(300.0, 0.0), 0.7)
	t.check(counter.sent == ["nappy-day-%d-task-guard-warned" % day,
			"nappy-day-%d-task-guard-chased" % day],
		"and his charge after his second chased (%s)" % [counter.sent])
	guard.free()
	_unlisten(listening)
	counter.free()

## **The masked man in the escape's stairwell has his counter** like every charger: `-warned` as his
## hand goes up, `-chased` when he starts his run, and then `-caught` (`InteriorEvents` reports his
## catch) or `-outlasted` when his run is over without one.
func _test_the_masked_man_has_his_counter(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var def := EventCatalogue.by_id("masked_pursuer")
	var name := "nappy-day-%d-masked-pursuer-" % day
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -400.0)])
	var man := EventInstance.new()
	man.setup(def, Vector2.ZERO, path)
	t.add_child(man)
	man.set_process(false)
	_walk(man, Vector2(0.0, -(def.charges_within + 100.0)), 0.5)
	t.check(counter.sent == [name + "warned"], "warning her, he is counted warned (%s)" % [counter.sent])
	_walk(man, Vector2(0.0, -(def.charges_within - 10.0)), 1.0 / 60.0)
	t.check(counter.sent == [name + "warned", name + "chased"],
		"his run is counted chased (%s)" % [counter.sent])
	for i in int(round(6.0 / (1.0 / 60.0))):
		man.player_at = Vector2(200.0, 0.0)
		man._process(1.0 / 60.0)
		if man.is_leaving:
			break
	t.check(counter.sent == [name + "warned", name + "chased", name + "outlasted"],
		"and his run over without a catch is counted outlasted (%s)" % [counter.sent])
	man.free()
	counter.sent.clear()
	var caught := EventInstance.new()
	caught.setup(def, Vector2.ZERO, path)
	t.add_child(caught)
	caught.set_process(false)
	_walk(caught, Vector2(0.0, -(def.charges_within - 10.0)), Tuning.WARNING_ALONE_MAX + 0.1)
	caught.report_the_catch()
	t.check(counter.sent == [name + "warned", name + "chased", name + "caught"],
		"a run that catches her is counted caught (%s)" % [counter.sent])
	caught.free()
	_unlisten(listening)
	counter.free()

## **A charge the day ends under is counted ended**, so every charge still ends in exactly one way
## *(inbox #764 in minty-lemur, the player: "Charging is independent of an ended day")*: the day's end asks every
## charge still running (`EventManager.end_the_charges_still_running()`), and one that ends this way
## is not also counted shaken or outlasted when it is finished after.
func _test_a_charge_cut_short_by_the_day_is_counted_ended(t) -> void:
	var counter := RecordingCounter.new()
	var listening := _listen(counter)
	var day := GameState.day
	var name := "nappy-day-%d-robber-giving-chase-" % day
	var robber := _charger(t, EventCatalogue.by_id("robber_giving_chase"))
	_walk(robber, Vector2(300.0, 0.0), 0.2)
	robber.report_the_charge_cut_short()
	robber.report_the_charge_cut_short()
	robber._be_done()
	t.check(counter.sent == [name + "chased", name + "ended"],
		"cut short by the day, it is counted ended once and nothing else (%s)" % [counter.sent])
	robber.free()
	counter.sent.clear()
	var waiting := _charger(t, EventCatalogue.by_id("alley_robbery"))
	_walk(waiting, Vector2(500.0, 0.0), 0.2)
	waiting.report_the_charge_cut_short()
	t.check(counter.sent.is_empty(), "a charger that never charged has nothing to end (%s)" % [counter.sent])
	waiting.free()
	_unlisten(listening)
	counter.free()

## Connects `counter` to the charging signals, as the real counter is; answers what
## `_unlisten()` takes.
func _listen(counter: Node) -> Array[Callable]:
	var calls: Array[Callable] = [
		func(id: String) -> void: counter._on_pursuit_warned(id),
		func(id: String) -> void: counter._on_pursuit_began(id),
		func(id: String) -> void: counter._on_pursuit_caught(id),
		func(id: String, shaken_off: bool) -> void: counter._on_pursuit_ended(id, shaken_off),
		func(id: String) -> void: counter._on_pursuit_cut_short(id)]
	EventBus.pursuit_warned.connect(calls[0])
	EventBus.pursuit_began.connect(calls[1])
	EventBus.pursuit_caught.connect(calls[2])
	EventBus.pursuit_ended.connect(calls[3])
	EventBus.pursuit_cut_short.connect(calls[4])
	return calls

func _unlisten(calls: Array[Callable]) -> void:
	EventBus.pursuit_warned.disconnect(calls[0])
	EventBus.pursuit_began.disconnect(calls[1])
	EventBus.pursuit_caught.disconnect(calls[2])
	EventBus.pursuit_ended.disconnect(calls[3])
	EventBus.pursuit_cut_short.disconnect(calls[4])

## A charger at the origin, in the tree, stepped by hand.
func _charger(t: Node, def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	return instance

## Steps `instance` for `seconds` with her held at `her`.
func _walk(instance: EventInstance, her: Vector2, seconds: float) -> void:
	var step := 1.0 / 60.0
	for i in maxi(1, int(round(seconds / step))):
		instance.player_at = her
		instance._process(step)

## The pelican's own four moments, each its own day-numbered event *(inbox #527 in azure-tapir, the player: "when
## the pelican spawns, when it's on screen, and when it's hitting the player. it must appear as its
## own entry")* — one send per signal, in the order the signals came. That each signal fires once
## per pelican, at its moment, is `tests/test_pelican.gd`'s.
func _test_the_pelican_is_its_own_entry(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_pelican_spawned(null)
	counter._on_pelican_sighted(null)
	counter._on_pelican_excited_her(null)
	counter._on_pelican_struck_her(null)
	var expected: Array[String] = []
	for moment in ["spawned", "seen", "excited", "hit"]:
		expected.append("nappy-day-%d-pelican-%s" % [day, moment])
	t.check(counter.sent == expected,
			"the pelican's four moments are four events of its own (%s)" % [counter.sent])
	counter.free()

## A day the pelican ends folds `pelican` into its loss, never its row's `cyclist` — the cause
## `main._hard_fail_cause_suffix()` names it by (`tests/test_day_lost_to.gd`), carried through.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	var counter := RecordingCounter.new()
	var day := GameState.day
	counter._on_pelican_struck_her(null)
	counter._on_day_ended(day, GameEnums.DayResult.LOST_HARD_FAIL, "pelican", 0.0)
	t.check(counter.sent == ["nappy-day-%d-pelican-hit" % day,
			"nappy-day-%d-lost-hard-fail-pelican" % day],
			"the hit, then the day lost to the pelican (%s)" % [counter.sent])
	counter.free()

## An encounter's three names and a bout of running *(misty-newt)*: the day the signal carries,
## not `GameState`'s, since an influence that waited can go out after the next day began; the row
## hyphenated as every id in a name is; and an influence never seen named apart, so influenced ÷
## seen counts only what she could see. When each is sent is `tests/test_encounters.gd`'s.
func _test_encounters_and_runs_are_named_by_their_day_and_row(t) -> void:
	var counter := RecordingCounter.new()
	counter._on_encounter_seen(4, "charging_dog")
	counter._on_encounter_influenced(4, "charging_dog", true)
	counter._on_encounter_influenced(7, "pelican", false)
	counter._on_run_bout_began(9)
	t.check(counter.sent == ["nappy-day-4-seen-charging-dog", "nappy-day-4-influenced-charging-dog",
			"nappy-day-7-influenced-unseen-pelican", "nappy-day-9-ran"],
			"seen, influenced, influenced-unseen and ran, each under its own day (%s)"
			% [counter.sent])
	counter.free()

## Every event the counter sends carries `no_session: true`, the one thing that keeps it counted
## every time on a site whose sessions stay on for the page visit ("okay, I can turn session back
## on and you opt out for everything except /nappy.josuakrause.com/"). Every handler is driven
## through `RecordingCounter`, and each name it sent is checked in the options `_dispatch()` hands
## `count()` and in the script line itself, parsed back rather than searched as text.
func _test_every_event_opts_out_of_sessions(t) -> void:
	var counter := RecordingCounter.new()
	counter._on_run_begun(1, false)
	counter._on_day_started(1)
	counter._on_task_offered(1)
	counter._on_mark_seen(1)
	counter._on_task_completed(1)
	counter._on_task_offered(2)
	counter._on_task_failed(2)
	counter._on_task_offered(3)
	counter._on_event_sighted("burning_building")
	counter._on_event_lit_unmet("burning_building")
	counter._on_city_gone_dark()
	counter._on_pursuit_began("charging_dog")
	counter._on_pursuit_ended("charging_dog", false)
	counter._on_encounter_seen(2, "charging_dog")
	counter._on_encounter_influenced(2, "charging_dog", true)
	counter._on_encounter_influenced(2, "charging_dog", false)
	counter._on_run_bout_began(2)
	counter._on_pelican_spawned(null)
	counter._on_pelican_sighted(null)
	counter._on_pelican_excited_her(null)
	counter._on_pelican_struck_her(null)
	counter._on_poster_torn()
	counter._on_poster_pursuit_sent()
	counter._on_player_detained("chatting_mother")
	counter._on_player_detained("checkpoint_hut")
	counter._on_day_ended(GameState.day, GameEnums.DayResult.LOST_CRYING, "car", 0.0)
	counter._on_run_restarted(1)
	counter._on_run_ended(GameEnums.Ending.GOOD)
	counter._on_escape_begun()
	counter._on_escape_city_entered()
	counter._on_escape_lost(DaySpec.Section.CITY, GameEnums.DayResult.LOST_TIMEOUT)
	counter._on_escape_out(CityEdge.Kind.BRIDGE)
	counter._on_controls_chosen(true, false)
	t.check(counter.sent.size() >= 20,
		"there were events to check (%d)" % counter.sent.size())
	var prefix := "try { window.goatcounter.count("
	var suffix := "); } catch (e) {}"
	for name: String in counter.sent:
		var options: Dictionary = VISIT_COUNTER_SCRIPT._count_options(name)
		var call: String = VISIT_COUNTER_SCRIPT._count_call(name)
		var parsed: Variant = null
		if call.begins_with(prefix) and call.ends_with(suffix):
			parsed = JSON.parse_string(call.substr(prefix.length(),
					call.length() - prefix.length() - suffix.length()))
		t.check(options.get("no_session") == true and options.get("event") == true
				and options.get("path") == name,
			"%s is an event under its own path that opts out of sessions" % name)
		t.check(parsed is Dictionary and parsed == options,
			"%s: the script line hands count() exactly those options" % name)
	counter.free()

## **Each of the escape's sections is counted as a day of its own, under its own number** *(minty-
## lemur #785: "telemetry should work the same also in escape both apartment and city")*: what is
## counted while it is walked is named by the day `day_started` announced — the building's
## `DaySpec.BUILDING_DAY`, the city's `DaySpec.CITY_DAY` — never by the calendar, which stays on
## the last day for the whole escape. The escape's own names go out beside the day's, as before.
func _test_an_escape_section_is_counted_as_a_day_of_its_own(t) -> void:
	var saved_day := GameState.day
	GameState.day = Tuning.RUN_LENGTH_DAYS
	var counter := RecordingCounter.new()
	var building := DaySpec.BUILDING_DAY
	counter._on_day_started(building)
	counter._on_pursuit_warned("masked_pursuer")
	counter._on_pursuit_began("masked_pursuer")
	counter._on_pursuit_caught("masked_pursuer")
	counter._on_day_ended(building, GameEnums.DayResult.LOST_HARD_FAIL, "masked-pursuer", 12.0)
	counter._on_escape_lost(DaySpec.Section.BUILDING, GameEnums.DayResult.LOST_HARD_FAIL)
	counter._on_day_started(building)
	counter._on_day_ended(building, GameEnums.DayResult.WON, "", 40.0)
	counter._on_escape_city_entered()
	var city := DaySpec.CITY_DAY
	counter._on_day_started(city)
	counter._on_city_gone_dark()
	counter._on_player_detained("checkpoint_post")
	counter._on_day_ended(city, GameEnums.DayResult.WON, "", 90.0)
	counter._on_escape_out(CityEdge.Kind.BRIDGE)
	var b := "nappy-day-%d-" % building
	var c := "nappy-day-%d-" % city
	t.check(counter.sent == [b + "began", b + "masked-pursuer-warned", b + "masked-pursuer-chased",
			b + "masked-pursuer-caught", b + "lost-hard-fail-masked-pursuer", "nappy-escape-lost",
			b + "began", b + "won", "nappy-escape-city", c + "began", c + "blackout",
			c + "checkpoint", c + "won", "nappy-escape-out"],
			"the building and the city are counted as days %d and %d (%s)"
			% [building, city, counter.sent])
	counter.free()
	GameState.day = saved_day
