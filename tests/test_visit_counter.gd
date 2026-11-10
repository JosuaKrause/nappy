@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
extends RefCounted
## `VisitCounter`'s own pure halves — the gate's truth table and the event-name builders — plus a
## check that answering every signal it connects to touches nothing the run it counts owns, the same
## invariant `tests/test_telemetry.gd` pins for the run log.
##
## Every counter is a fresh instance of the test's own, handed a `RunState` made fresh for it
## (`configure()`, as `main` hands the one under the sitting the run it plays), the bus it
## listens to and a run flow whose walks it counts (`listen_to_the_flow()`); nothing here reads a
## global run.

## A bus of the game's own kind with nobody listening to it: a counter handed one hears what a test
## emits on it and nothing the live singletons answer to.
const EVENT_BUS_SCRIPT = preload("res://src/autoload/event_bus.gd")

## `VisitCounter` with `_send_event()` recording the name instead of reaching for a page, so a test
## can read what each signal would send. Everything else is the real counter's own code.
class RecordingCounter extends VisitCounter:
	var sent: Array[String] = []

	## The bus of its own this counter listens to.
	var bus: Node = EVENT_BUS_SCRIPT.new()
	## The run flow of its own whose walks it counts, as `main` hands it each boot's.
	var flow := RunFlow.new()

	## The run it counts, made fresh for it (day 1 of a normal run). A test reaches it as
	## `counter.run`.
	var run := RunState.new()

	## Counts a run of its own, as `main` hands the real counter the run it plays.
	func _init() -> void:
		run.start_run(1)
		configure(null, run)
		listen(bus)
		listen_to_the_flow(flow)

	## Begins the walk of day `day` on its flow, as the run flow announces one.
	func begin(day: int) -> void:
		flow.day_started.emit(spec_of(day))

	## The spec of day `day` as the run flow carries it: a section of the escape under its own
	## number (`DaySpec.BUILDING_DAY`, `CITY_DAY`), or an ordinary day.
	static func spec_of(day: int) -> DaySpec:
		if day == DaySpec.BUILDING_DAY:
			return DaySpec.for_section(DaySpec.Section.BUILDING, 180.0)
		if day == DaySpec.CITY_DAY:
			return DaySpec.for_section(DaySpec.Section.CITY, 180.0)
		return DaySpec.for_day(day, 210.0)

	## Overrides VisitCounter._send_event.
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

## The gate's truth table: `may_ever_send()` is the three inputs that never change (on the web, a
## release build, `?debug=1` unasked); the fourth, `window.goatcounter.count` being present, is
## `send()`'s `present`, which counts at once when true and queues when false. All four are
## required; missing any one of them sends nothing.
func _test_should_send_truth_table(t) -> void:
	var scripts: Array[String] = []
	var outbox := GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script))
	t.check(GoatCounterOutbox.may_ever_send(true, false, false),
		"web, a release build and no ?debug=1 may send")
	outbox.send("probe", true)
	t.check(scripts.size() == 1, "and with goatcounter present it counts (%s)" % [scripts])
	t.check(not GoatCounterOutbox.may_ever_send(false, false, false),
		"off the web, nothing is sent no matter what else is true")
	t.check(not GoatCounterOutbox.may_ever_send(true, true, false),
		"a debug build sends nothing, on the web or off it")
	t.check(not GoatCounterOutbox.may_ever_send(true, false, true),
		"?debug=1 (RunConfig.readout_requested) sends nothing even on a release web build")
	scripts.clear()
	outbox.send("early", false)
	t.check(scripts.is_empty(), "a missing or blocked window.goatcounter sends nothing")
	t.check(not GoatCounterOutbox.may_ever_send(false, true, true),
		"every reason to refuse at once still refuses")
	# The composition `VisitCounter._send_event()` makes, over all sixteen inputs: counted only
	# when the three fixed inputs allow it and the page has goatcounter.
	for bits in 16:
		var web := bits & 1 != 0
		var debug_build := bits & 2 != 0
		var debug_requested := bits & 4 != 0
		var present := bits & 8 != 0
		scripts.clear()
		var fresh := GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script))
		if GoatCounterOutbox.may_ever_send(web, debug_build, debug_requested):
			fresh.send("composed", present)
		t.check((scripts.size() == 1) == (web and not debug_build and not debug_requested and present),
			"web %s, debug build %s, ?debug=1 %s, present %s counts only when all four allow it"
			% [web, debug_build, debug_requested, present])

## A day-scoped name is `nappy-day-<day>-<suffix>`, joined the way PLAYTEST-132's own example does.
func _test_day_event_name(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.day_ended.emit(6, GameEnums.DayResult.LOST_CRYING, "", 0.0)
	t.check(counter.sent.back() == "nappy-day-6-lost-crying",
		"day and suffix join the way PLAYTEST-132's own example does (%s)" % [counter.sent])
	counter.begin(1)
	t.check(counter.sent.back() == "nappy-day-1-began", "a plain day-scoped name (%s)" % [counter.sent])
	counter.bus.resistance_contact_available.emit(2)
	counter.bus.day_ended.emit(14, GameEnums.DayResult.WON, "", 0.0)
	t.check(counter.sent.size() == 3,
		"a step offered on another day is not skipped by day 14's end (%s)" % [counter.sent])
	counter.bus.day_ended.emit(1, GameEnums.DayResult.WON, "", 0.0)
	t.check(counter.sent.back() == "nappy-day-1-task-skipped",
		"a two-word suffix stays hyphenated, not a second underscore (%s)" % [counter.sent])
	_done(counter)

## `GameEnums.DayResult`'s own keys are the loss causes — nothing here invents a second name for
## one, it only lowercases and hyphenates the key already in the game. A day's end sends the key.
func _test_loss_cause_names_every_day_result(t) -> void:
	var counter := RecordingCounter.new()
	var named := [
		[GameEnums.DayResult.WON, "won", "a win names itself, no 'lost-' prefix"],
		[GameEnums.DayResult.LOST_CRYING, "lost-crying",
				"an enum key's underscore becomes the name's own hyphen"],
		[GameEnums.DayResult.LOST_TIMEOUT, "lost-timeout", "the timeout loss"],
		[GameEnums.DayResult.LOST_HARD_FAIL, "lost-hard-fail",
				"a two-word cause stays entirely hyphenated"]]
	for row in named:
		counter.sent.clear()
		counter.bus.day_ended.emit(3, row[0], "", 0.0)
		t.check(counter.sent == ["nappy-day-3-" + row[1]], row[2])
	_done(counter)

## What a day's end sends is the loss kind with `EventBus.day_ended`'s own raw cause folded on, for
## the two results that ever have one — a win or a timeout keeps its bare name even if it is
## (wrongly) handed a cause, since the game names none for either.
func _test_loss_event_suffix_folds_a_cause_only_for_the_two_results_that_ever_have_one(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.day_ended.emit(2, GameEnums.DayResult.LOST_CRYING, "traffic", 0.0)
	t.check(counter.sent.back() == "nappy-day-2-lost-crying-traffic", "a crying loss folds its cause on")
	counter.bus.day_ended.emit(2, GameEnums.DayResult.LOST_HARD_FAIL, "car", 0.0)
	t.check(counter.sent.back() == "nappy-day-2-lost-hard-fail-car",
		"a hard fail folds its cause on the same way")
	counter.bus.day_ended.emit(2, GameEnums.DayResult.LOST_CRYING, "", 0.0)
	t.check(counter.sent.back() == "nappy-day-2-lost-crying",
		"no recorded cause sends the bare loss name rather than nothing")
	counter.bus.day_ended.emit(2, GameEnums.DayResult.WON, "traffic", 0.0)
	t.check(counter.sent.back() == "nappy-day-2-won", "a win never carries a cause, whatever is pending")
	counter.bus.day_ended.emit(2, GameEnums.DayResult.LOST_TIMEOUT, "traffic", 0.0)
	t.check(counter.sent.back() == "nappy-day-2-lost-timeout", "a timeout never carries a cause either")
	_done(counter)

func _test_run_begun_name(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.run_begun.emit(1, false)
	t.check(counter.sent == ["nappy-run-fresh"],
		"a fresh run always starts day 1, not worth repeating in the name")
	_done(counter)
	counter = RecordingCounter.new()
	counter.bus.run_begun.emit(9, true)
	t.check(counter.sent == ["nappy-run-resumed-day-9"], "a resumed run names the day it resumed on")
	_done(counter)

func _test_mode_event_name(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.run_mode_chosen.emit(true, 1)
	t.check(counter.sent.front() == "nappy-mode-hard", "a hard run")
	counter.sent.clear()
	counter.bus.run_mode_chosen.emit(false, 1)
	t.check(counter.sent.front() == "nappy-mode-normal", "a normal run")
	_done(counter)

## Every run keeps the plain `began`, so its series runs on unbroken; a hard run adds its copy.
func _test_day_began_names(t) -> void:
	var counter := RecordingCounter.new()
	counter.run.calendar.hard_mode = false
	counter.begin(5)
	t.check(counter.sent == ["nappy-day-5-began"], "a normal run's day sends the plain name alone")
	counter.sent.clear()
	counter.run.calendar.hard_mode = true
	counter.begin(5)
	t.check(counter.sent == ["nappy-day-5-began", "nappy-day-5-began-hard"],
		"a hard run's day sends the plain name and its hard-only copy")
	_done(counter)

func _test_checkpoint_event_name(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.went_back_to_a_checkpoint.emit(8, 10)
	t.check(counter.sent.back() == "nappy-checkpoint-8-from-day-10",
		"the checkpoint gone back to, and the day the last nerve was lost on")
	counter.bus.went_back_to_a_checkpoint.emit(1, 2)
	t.check(counter.sent.back() == "nappy-checkpoint-1-from-day-2", "checkpoint zero is day 1")
	_done(counter)

## The day a fresh run's title stands in front of has already begun as a normal run's by the time
## the title says the run is hard, so the counter sends that day's hard copy with the mode; every
## later day of a hard run sends it as the day begins.
func _test_a_hard_run_counts_its_days_twice_and_a_normal_run_once(t) -> void:
	var counter := RecordingCounter.new()
	counter.run.calendar.hard_mode = false
	counter.begin(1)
	counter.bus.run_mode_chosen.emit(true, 1)
	counter.run.calendar.hard_mode = true
	counter.begin(2)
	t.check(counter.sent == ["nappy-day-1-began", "nappy-mode-hard", "nappy-day-1-began-hard",
			"nappy-day-2-began", "nappy-day-2-began-hard"],
			"a hard run's first day is counted hard once its mode is known (%s)" % [counter.sent])
	counter.sent.clear()
	counter.run.calendar.hard_mode = false
	counter.begin(1)
	counter.bus.run_mode_chosen.emit(false, 1)
	counter.bus.went_back_to_a_checkpoint.emit(4, 7)
	t.check(counter.sent == ["nappy-day-1-began", "nappy-mode-normal",
			"nappy-checkpoint-4-from-day-7"],
			"a normal run's days are counted once, and its checkpoint restart named (%s)"
					% [counter.sent])
	_done(counter)

## A key begins the run in the tap scheme, and is still reported as keys: the name comes from the
## input that began the run, not the scheme it fell back to.
func _test_controls_event_name(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.controls_chosen.emit(true, false)
	t.check(counter.sent.back() == "nappy-controls-joystick", "the joystick button")
	counter.bus.controls_chosen.emit(false, false)
	t.check(counter.sent.back() == "nappy-controls-tap", "the tap button")
	counter.bus.controls_chosen.emit(false, true)
	t.check(counter.sent.back() == "nappy-controls-keys",
		"a key, whose run begins in tap mode, is reported as keys")
	_done(counter)

## `chatting_mother` is a `chat`; every other id that can reach `EventBus.player_detained` — the
## catalogue's only other two rows with a `detain_seconds` above zero — is a `checkpoint`.
func _test_detention_suffix(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.begin(day)
	counter.sent.clear()
	counter.bus.player_detained.emit("chatting_mother")
	t.check(counter.sent == ["nappy-day-%d-chat" % day], "the mother who stops her for a conversation")
	counter.sent.clear()
	counter.bus.player_detained.emit("checkpoint_hut")
	t.check(counter.sent == ["nappy-day-%d-checkpoint" % day], "a checkpoint's hut")
	counter.sent.clear()
	counter.bus.player_detained.emit("checkpoint_post")
	t.check(counter.sent == ["nappy-day-%d-checkpoint" % day], "a checkpoint's post")
	_done(counter)

## The mark/task split comes from `ResistanceSteps` itself — index 1 is day 6's chalk mark and
## index 2 is the perform step it unlocks (`ResistanceSteps._build()`), so this is real catalogue
## data rather than an index chosen to make the parity come out right. A completed step is sent as
## `mark-read` or `task-done` accordingly.
func _test_is_pickup_step(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.begin(day)
	var cases := [
		[1, "mark-read", "index 1 is day 6's chalk mark"],
		[2, "task-done", "index 2 is the perform step the mark unlocks"],
		[17, "task-done", "the finale's own step is not a pickup either"],
		[999, "task-done", "an index the resistance does not know reads as a task, the safer default"]]
	for row in cases:
		counter.sent.clear()
		counter.bus.resistance_step_completed.emit(row[0])
		t.check(counter.sent == ["nappy-day-%d-%s" % [day, row[1]]], row[2])
	_done(counter)

## Drives every signal handler the counter connects to and checks that none of it moved anything
## the run it counts owns. This process is never on the web (`OS.get_name() != "Web"`), so
## `_send_event()` refuses every one of these and never reaches
## `JavaScriptBridge` at all — the point of the check is that the *listening* itself is inert, the
## same "telemetry must not touch gameplay" invariant `tests/test_telemetry.gd` pins for the run
## log, adapted for a listener with no per-frame watch of its own.
func _test_listening_touches_no_gameplay_state(t) -> void:
	var counter := VisitCounter.new()
	var bus: Node = EVENT_BUS_SCRIPT.new()
	var flow := RunFlow.new()
	var run := RunState.new()
	run.start_run(1)
	var scripts: Array[String] = []
	counter.send_through(GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script)))
	counter.listen(bus)
	counter.listen_to_the_flow(flow)
	flow.day_started.emit(RecordingCounter.spec_of(1))
	t.check(scripts.is_empty(),
		"a counter handed no configuration sends nothing")
	counter.configure(RunConfig.parse(PackedStringArray(), "", false), run)
	var before := _run_snapshot(run)
	bus.run_begun.emit(1, false)
	flow.day_started.emit(RecordingCounter.spec_of(1))
	bus.resistance_contact_available.emit(0)
	bus.resistance_step_completed.emit(0)
	bus.resistance_contact_available.emit(1)
	bus.resistance_step_failed.emit(1)
	bus.resistance_mark_seen.emit(1)
	bus.event_sighted.emit("burning_building")
	bus.event_lit_unmet.emit("burning_building")
	bus.city_gone_dark.emit()
	bus.pursuit_warned.emit("charging_dog")
	bus.pursuit_began.emit("charging_dog")
	bus.pursuit_caught.emit("alley_robbery")
	bus.pursuit_cut_short.emit("alley_robbery")
	bus.pursuit_ended.emit("charging_dog", true)
	bus.encounter_seen.emit(1, "homeless_yeller")
	bus.encounter_influenced.emit(1, "homeless_yeller", true)
	bus.encounter_influenced.emit(1, "pelican", false)
	bus.run_bout_began.emit(1)
	bus.pelican_spawned.emit(null)
	bus.pelican_sighted.emit(null)
	bus.pelican_excited_her.emit(null)
	bus.pelican_struck_her.emit(null)
	bus.poster_torn.emit()
	bus.poster_pursuit_sent.emit()
	bus.player_detained.emit("chatting_mother")
	bus.day_ended.emit(1, GameEnums.DayResult.WON, "", 0.0)
	bus.run_restarted.emit(1)
	bus.run_ended.emit(GameEnums.Ending.NEUTRAL)
	bus.escape_begun.emit()
	bus.escape_city_entered.emit()
	bus.escape_lost.emit(DaySpec.Section.BUILDING, GameEnums.DayResult.LOST_CRYING)
	bus.escape_out.emit(CityEdge.Kind.TUNNEL)
	bus.controls_chosen.emit(false, true)
	bus.run_mode_chosen.emit(true, 1)
	bus.went_back_to_a_checkpoint.emit(4, 6)
	var after := _run_snapshot(run)
	t.check(before == after,
		"answering every signal the counter connects to leaves the run it counts untouched")
	t.check(scripts.is_empty(),
		"a headless test process is never the web, so nothing above reached a real page")
	bus.free()
	counter.free()

## Frees the counter, which lets go of every bus it listened to, and the bus of its own.
func _done(counter: RecordingCounter) -> void:
	counter.bus.free()
	counter.free()

func _run_snapshot(run: RunState) -> Dictionary:
	return {
		"day": run.header.day,
		"nerves": run.header.nerves,
		"resistance_progress": run.resistance.progress,
		"completed": run.resistance.completed_steps.duplicate(),
		"failed": run.resistance.failed_steps.duplicate(),
		"ending": run.header.ending,
	}

## The bookkeeping behind "each task done, and each task skipped (a task day that ended without
## it), by day" — a step offered and then completed never reaches `_on_day_ended()`'s own sweep; a
## step offered and never touched, or offered on an earlier day and still open, does. Read off what
## the counter sends when the day ends: a skipped step is a `task-skipped` of the day it was offered.
func _test_task_skipped_only_for_a_step_still_open_on_its_own_day(t) -> void:
	var counter := RecordingCounter.new()
	counter.begin(5)
	counter.bus.resistance_contact_available.emit(5)
	counter.bus.resistance_step_completed.emit(5)
	counter.bus.resistance_contact_available.emit(6)
	counter.sent.clear()
	counter.bus.day_ended.emit(5, GameEnums.DayResult.LOST_TIMEOUT, "", 0.0)
	t.check(counter.sent == ["nappy-day-5-lost-timeout", "nappy-day-5-task-skipped"],
		"the day ending skips the offered, untouched step once and not the completed one (%s)"
		% [counter.sent])
	counter.sent.clear()
	counter.bus.day_ended.emit(5, GameEnums.DayResult.LOST_TIMEOUT, "", 0.0)
	t.check(counter.sent == ["nappy-day-5-lost-timeout"],
		"the day it belonged to ending closed the step out: a second end skips nothing (%s)"
		% [counter.sent])
	counter.bus.resistance_contact_available.emit(8)
	counter.bus.resistance_step_failed.emit(8)
	counter.begin(6)
	counter.bus.resistance_contact_available.emit(7)
	counter.sent.clear()
	counter.bus.day_ended.emit(5, GameEnums.DayResult.WON, "", 0.0)
	t.check(counter.sent == ["nappy-day-5-won"],
		"a step offered on day 6 stays open when day 5's end comes (%s)" % [counter.sent])
	_done(counter)

## `_on_task_completed()`/`_on_task_failed()`/`_on_day_ended()`'s own sweep all ask whether a step is
## a pickup rather than apply a parity rule of their own — checked here through what each sends.
## Index 1 (day 6's mark) and index 2 (the perform step it unlocks) are real `ResistanceSteps` data,
## not indices chosen to make a parity come out right.
func _test_mark_and_task_sends_are_split_by_the_resistance_own_data(t) -> void:
	var counter := RecordingCounter.new()
	counter.begin(6)
	counter.bus.resistance_contact_available.emit(1)
	counter.bus.resistance_contact_available.emit(2)
	counter.bus.resistance_step_completed.emit(1)
	counter.bus.resistance_step_completed.emit(2)
	counter.bus.day_ended.emit(6, GameEnums.DayResult.WON, "", 0.0)
	t.check(counter.sent.slice(1) == ["nappy-day-6-mark-read", "nappy-day-6-task-done", "nappy-day-6-won"],
		"a completed mark and a completed task both close out, and are sent as what they are (%s)"
		% [counter.sent])
	counter.sent.clear()
	counter.bus.resistance_contact_available.emit(1)
	counter.bus.resistance_contact_available.emit(2)
	counter.bus.day_ended.emit(6, GameEnums.DayResult.LOST_TIMEOUT, "", 0.0)
	t.check(counter.sent.slice(1) == ["nappy-day-6-mark-missed", "nappy-day-6-task-skipped"],
		"the day ending closes out an untouched mark and an untouched task alike (%s)" % [counter.sent])
	_done(counter)

## `poster-torn`, `chat` and `checkpoint` are sent every time, within one attempt and across a
## retry alike: every event opts out of the site's sessions so that a count is every time a thing
## happened
## (PLAYTEST-143: "no, even current run wouldn't work if the player dies multiple times on the same
## day"). Read off `RecordingCounter`, which keeps what `_send_event()` was asked for, since the
## real one is silent in this process.
func _test_every_tear_and_every_hold_is_sent(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.begin(day)
	counter.bus.poster_torn.emit()
	counter.bus.poster_torn.emit()
	counter.bus.player_detained.emit("checkpoint_hut")
	counter.bus.player_detained.emit("checkpoint_hut")
	counter.begin(day)
	counter.bus.poster_torn.emit()
	var torn := "nappy-day-%d-poster-torn" % day
	var held := "nappy-day-%d-checkpoint" % day
	t.check(counter.sent.count(torn) == 3,
		"two tears in one attempt and one in the retry are three poster-torn events")
	t.check(counter.sent.count(held) == 2, "a checkpoint that holds her twice is two events")
	counter.bus.poster_pursuit_sent.emit()
	t.check(counter.sent.back() == "nappy-day-%d-poster-pursuit" % day,
		"a tear that sends a pursuer on foot sends its own poster-pursuit")
	_done(counter)

## The fold this counter makes: the day's end's own cause becomes part of the one event a lost day
## sends, never a `lost-crying` beside a second `noise-traffic` of its own — the double counting the
## player asked to see gone ("lost-crying still doesn't tell me anything about how they died").
func _test_a_lost_day_folds_its_cause_into_one_event_not_two(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.day_ended.emit(day, GameEnums.DayResult.LOST_CRYING, "traffic", 0.0)
	t.check(counter.sent == ["nappy-day-%d-lost-crying-traffic" % day],
		"the cause and the loss kind fold into one event, not a lost-crying beside a noise-traffic")
	_done(counter)

## A hard-fail day folds the same way, off `LossCause.of()`'s own raw name for it, as the day's
## end carries it.
func _test_a_hard_fail_day_folds_its_cause_too(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.day_ended.emit(day, GameEnums.DayResult.LOST_HARD_FAIL, "alley-robbery", 0.0)
	t.check(counter.sent == ["nappy-day-%d-lost-hard-fail-alley-robbery" % day],
		"a hard fail folds its cause the same way a crying loss does")
	_done(counter)

## A lost day ended with no cause still sends the bare loss name rather than nothing.
func _test_a_lost_day_with_no_recorded_cause_still_sends_the_bare_loss_name(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.day_ended.emit(day, GameEnums.DayResult.LOST_CRYING, "", 0.0)
	t.check(counter.sent.has("nappy-day-%d-lost-crying" % day),
		"an unknown cause sends the bare loss name instead of silently dropping the day's own end")
	_done(counter)

## A cause never attaches to a result that has none. The game names a cause only for
## `LOST_CRYING`/`LOST_HARD_FAIL`, so a `WON` or `LOST_TIMEOUT` handed one can only happen by driving
## the handler directly, the way this test does — and even then, the bare name is what is sent.
func _test_won_and_timeout_never_carry_a_pending_cause(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.day_ended.emit(day, GameEnums.DayResult.WON, "traffic", 0.0)
	t.check(counter.sent == ["nappy-day-%d-won" % day], "a win never carries a leftover cause")
	_done(counter)

## Review finding: a genuinely fresh visit that hands over to the escape at day 14 re-enters
## `main._ready()` through `reload_current_scene()`, and `GameSave.try_resume()` there finds the
## save that same reload just wrote — `resumed` (from `EventBus.run_begun`) reads `true`, but the
## page never actually left. A save is only a resume if this page has not already reported a run
## beginning once before. The four cases of (resumed, already reported), read off what is sent.
func _test_resumed_for_report_truth_table(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.run_begun.emit(4, true)
	counter.bus.run_begun.emit(4, true)
	t.check(counter.sent == ["nappy-run-resumed-day-4"],
		"a save found by a second run_begun on one page is the same run reloaded: nothing sent (%s)"
		% [counter.sent])
	counter.sent.clear()
	counter.bus.run_begun.emit(1, false)
	t.check(counter.sent == ["nappy-run-fresh"],
		"no save on a second run_begun is a new run after a held restart: counted fresh")
	_done(counter)
	counter = RecordingCounter.new()
	counter.bus.run_begun.emit(4, true)
	t.check(counter.sent == ["nappy-run-resumed-day-4"],
		"the page's first run_begun that finds a save is a real resume: counted")
	_done(counter)
	counter = RecordingCounter.new()
	counter.bus.run_begun.emit(1, false)
	t.check(counter.sent == ["nappy-run-fresh"], "no save at all is never a resume")
	counter.bus.run_begun.emit(1, false)
	t.check(counter.sent == ["nappy-run-fresh", "nappy-run-fresh"],
		"no save and already reported stays not-a-resume")
	_done(counter)

## The stateful half: the page has reported nothing at first, the first `run_begun` marks it, and
## a second one on the same instance — the day-14 handover's own `reload_current_scene()`, or any
## other reload within one page's life — is never reported as resumed even though `main.gd` still
## passed `resumed = true`, because the save it found is this page's own.
func _test_a_second_run_begun_on_the_same_page_is_never_reported_as_resumed(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.run_begun.emit(14, true)
	t.check(counter.sent == ["nappy-run-resumed-day-14"],
		"a fresh instance has not reported anything yet: a save found is a resume")
	counter.bus.run_begun.emit(1, false)
	t.check(counter.sent.back() == "nappy-run-fresh" and counter.sent.size() == 2,
		"the first call marked the page as having reported, and a run with no save is fresh")
	# Same instance, a later boot within this page's own life (a day-14 handover, say) — main.gd
	# still passes `resumed = true` because a save now genuinely exists, and the fix is that this
	# object, not main.gd, is what refuses it.
	counter.bus.run_begun.emit(14, true)
	t.check(counter.sent.size() == 2,
		"once this page has reported, a second 'resumed' argument is not trusted as a new resume")
	_done(counter)

## Review finding: `count.js` loads asynchronously, so an event asked for before it has finished
## loading — the earliest events of a cold, first-ever visit, above all — must not be dropped
## silently the way a debug build's events are. `GoatCounterOutbox.send()` takes `present` as a
## parameter rather than asking the page (which is hard-wired absent off the web), so the queueing
## logic is testable here without a real page: the outbox evaluates what it is handed a recorder
## for.
func _test_pending_events_queue_until_present_and_flush_in_order(t) -> void:
	var scripts: Array[String] = []
	var outbox := GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script))
	outbox.send("nappy-run-fresh", false)
	outbox.send("nappy-day-1-began", false)
	t.check(scripts.is_empty(), "count.js not yet present evaluates nothing: the events are held")
	outbox.send("nappy-day-1-task-done", true)
	t.check(scripts.size() == 3 and scripts[0].contains("\"path\":\"nappy-run-fresh\"")
			and scripts[1].contains("\"path\":\"nappy-day-1-began\"")
			and scripts[2].contains("\"path\":\"nappy-day-1-task-done\""),
		"count.js present drains the whole queue, in the order the events were asked for, then the "
		+ "one asked for now (%s)" % [scripts])
	outbox.send("nappy-day-1-blackout", true)
	t.check(scripts.size() == 4 and scripts[3].contains("nappy-day-1-blackout"),
		"with nothing held, an event is counted at once and the drained queue is not sent twice")
	t.check(scripts[3].begins_with("try { window.goatcounter.count(") and scripts[3].ends_with("catch (e) {}")
			and scripts[3].contains("\"no_session\":true") and scripts[3].contains("\"event\":true"),
		"every event is one count() call inside the page's own try/catch, opted out of sessions")

## The other half of the fix: a reason that can never change — off the web, a debug build, or
## `?debug=1` — must never populate the queue at all, the same "still send nothing under debug"
## the gate itself already promised. This process is never on the web, so the real counter, handed
## a bus, a release build's configuration and an outbox with a recorder (as `main` hands it the
## page's), refuses every event before its outbox is touched. Nothing it was handed is queued: the
## outbox's next counted event, a probe sent with `count.js` present, flushes whatever the outbox
## holds ahead of itself, and the recorder sees the probe alone.
func _test_send_event_never_queues_when_it_may_never_send(t) -> void:
	var counter := VisitCounter.new()
	var bus: Node = EVENT_BUS_SCRIPT.new()
	var scripts: Array[String] = []
	var outbox := GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script))
	var run := RunState.new()
	run.start_run(1)
	counter.configure(RunConfig.parse(PackedStringArray(), "", false), run)
	counter.send_through(outbox)
	counter.listen(bus)
	var flow := RunFlow.new()
	counter.listen_to_the_flow(flow)
	t.check(bus.controls_chosen.get_connections().size() == 1
			and flow.day_started.get_connections().size() == 1,
		"the counter answers the bus and the flow it is handed, so there are events to refuse")
	bus.run_begun.emit(1, false)
	flow.day_started.emit(RecordingCounter.spec_of(1))
	bus.controls_chosen.emit(true, false)
	bus.day_ended.emit(1, GameEnums.DayResult.WON, "", 0.0)
	t.check(scripts.is_empty(), "off the web, nothing reaches a page (%s)" % [scripts])
	outbox.send("probe", true)
	t.check(scripts.size() == 1 and scripts[0].contains("\"path\":\"probe\""),
		"off the web, an event is refused outright rather than queued forever unsent (%s)"
		% [scripts])
	t.check(not GoatCounterOutbox.may_ever_send(true, true, false)
			and not GoatCounterOutbox.may_ever_send(true, false, true)
			and GoatCounterOutbox.may_ever_send(true, false, false),
		"a debug build and ?debug=1 are refused for good, a release web page is not")
	bus.free()
	counter.free()

## `EventBus.pursuit_began` (the counter's `dog-chased`) fires once per chase, and **a pursuer
## created where its warning pointed reports the chase it starts**. `EventManager.spawn_warned()`
## creates such a row through `EventInstance.resume()` to spend the telegraph the warning already
## ran, and a resume otherwise stands for an instance streamed back in, whose chase — for a row
## like `charging_dog` that never waits (`EventDef.notice` 0.0) — began before it streamed out and
## was already reported. Three arrivals of the one row: placed at once and telegraphing, created
## warned the way `spawn_warned()` does it (`came_under_a_warning` set, then `resume()`), and
## streamed back in mid-chase, which reports nothing a second time.
func _test_a_chase_is_reported_once_however_the_pursuer_arrived(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	t.check(def.pursuit != null and def.notice_within() <= 0.0,
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
		placed.step(step)
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
		streamed.step(step)
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
		warned.step(step)
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
	counter.listen(EventBus)
	var day := counter.run.header.day
	var def := EventCatalogue.by_id("charging_dog").for_day(Tuning.RUN_TAUGHT_DAY + 1)
	var standoff := PursuitSpec.standoff(def.chase_speed(), def.standoff_reach())
	var dog := _charger(t, def)
	_walk(dog, Vector2(def.notice_within() - 10.0, 0.0), 1.0)
	t.check(counter.sent == ["nappy-day-%d-dog-warned" % day],
		"warning her, the dog is counted warned and not chased (%s)" % [counter.sent])
	_walk(dog, Vector2(def.notice_within() + 10.0, 0.0), 0.5)
	_walk(dog, Vector2(def.notice_within() - 10.0, 0.0), 0.5)
	t.check(counter.sent.size() == 1, "walked out of and back into, it is not counted again (%s)"
		% [counter.sent])
	_walk(dog, Vector2(standoff - 2.0, 0.0), def.pursuit.warns_for + 0.2)
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
	_done(counter)

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
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	for id: String in names.keys():
		counter.sent.clear()
		counter.bus.pursuit_began.emit(id)
		t.check(counter.sent == ["nappy-day-%d-%s-chased" % [day, names[id]]],
			"'%s' is counted as '%s' (%s)" % [id, names[id], counter.sent])
	counter.sent.clear()
	counter.bus.pursuit_began.emit("door_guard")
	counter.bus.pursuit_caught.emit("door_guard")
	counter.bus.pursuit_began.emit("policeman_giving_chase")
	counter.bus.pursuit_ended.emit("policeman_giving_chase", true)
	t.check(counter.sent == ["nappy-day-%d-door-guard-chased" % day,
			"nappy-day-%d-door-guard-caught" % day,
			"nappy-day-%d-policeman-giving-chase-chased" % day,
			"nappy-day-%d-policeman-giving-chase-shaken" % day],
		"each charger's charge and its end go under its own name (%s)" % [counter.sent])
	_done(counter)

## **A charge ends in exactly one of caught, shaken off and outlasted, whatever the day does**
## *(inbox #764 in minty-lemur, the player: "Charging is independent of an ended day")*. The real instance and
## signals, for a sent robber, who charges from his first frame: caught (`report_the_catch()`, what
## `EventManager.check_hard_fails()` and a patrol car's man stopping her call) and then finished
## anyway, as a day that goes on under `--invincible` would; run off; and walked away from until his
## clock runs out. Each sends `-chased` and then one end, and a catch said twice is counted once.
func _test_a_charge_ends_in_exactly_one_of_three(t) -> void:
	var counter := RecordingCounter.new()
	counter.listen(EventBus)
	var day := counter.run.header.day
	var def := EventCatalogue.by_id("robber_giving_chase")
	var name := "nappy-day-%d-robber-giving-chase-" % day

	var caught := _charger(t, def)
	_walk(caught, Vector2(300.0, 0.0), 0.2)
	caught.report_the_catch()
	caught.report_the_catch()
	t.check(_finish_by_its_own_frames(caught), "the caught robber is finished anyway, by his own clock")
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
		shaken.step(step)
		if shaken.is_leaving:
			break
	t.check(counter.sent == [name + "chased", name + "shaken"],
		"run off, it is counted shaken (%s)" % [counter.sent])
	shaken.free()

	counter.sent.clear()
	var outlasted := _charger(t, def)
	for i in int(round((def.telegraph_time + def.duration + 1.0) / step)):
		outlasted.player_at = outlasted.global_position + Vector2(400.0, 0.0)
		outlasted.step(step)
		if outlasted.is_leaving:
			break
	t.check(counter.sent == [name + "chased", name + "outlasted"],
		"its clock run out, it is counted outlasted (%s)" % [counter.sent])
	outlasted.free()
	_done(counter)

## **The day-3 lesson's dog has its own set and not the dog's** *(PLAYTEST-141: "we need to record
## like dog tutorial")*: its own row, `charging_dog_tutorial`, which `EventDirector` hands out in
## place of the first dog it sends on `Tuning.RUN_TAUGHT_DAY`, names its charge `dog-tutorial-*`;
## the charging dog's own row is an ordinary `dog`.
func _test_the_lesson_dog_has_its_own_set(t) -> void:
	var counter := RecordingCounter.new()
	counter.listen(EventBus)
	var day := counter.run.header.day
	var def := EventCatalogue.lesson_of(EventCatalogue.by_id("charging_dog"))
	var lesson := _charger(t, def)
	_walk(lesson, Vector2(400.0, 0.0), def.telegraph_time + 0.5)
	lesson.report_the_catch()
	t.check(counter.sent == ["nappy-day-%d-dog-tutorial-chased" % day,
			"nappy-day-%d-dog-tutorial-caught" % day],
		"it sends its own set, and none of the dog's (%s)" % [counter.sent])
	lesson.free()
	counter.sent.clear()
	var dog := EventCatalogue.by_id("charging_dog")
	var later := _charger(t, dog)
	_walk(later, Vector2(400.0, 0.0), dog.telegraph_time + 0.5)
	t.check(counter.sent == ["nappy-day-%d-dog-chased" % day],
		"a dog that is not the lesson's is an ordinary dog (%s)" % [counter.sent])
	later.free()
	_done(counter)

## **A raised hand is a warning, and the charge comes after it** *(inbox #764 in minty-lemur, the player: "Dog-chased
## implies charge")*. The man a vehicle lets out stands with his hand raised for a second: the
## counter sends his `-warned` as the hand goes up, nothing more for that second, and `-chased` only
## when he charges. Day 13's guard set on her in her view counts the same way, as `task-guard`.
func _test_a_raised_hand_is_counted_warned_and_the_charge_chased(t) -> void:
	var counter := RecordingCounter.new()
	counter.listen(EventBus)
	var day := counter.run.header.day
	var def := EventCatalogue.out_of_the_car(DaySpec.for_day(Tuning.REGION_WALL_FIRST_DAY))
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
	var guard := _charger(t, EventCatalogue.task_guard())
	guard.notice_her_at(Vector2(300.0, 0.0), Tuning.WARNING_ALONE_MAX, true)
	_walk(guard, Vector2(300.0, 0.0), 0.5)
	t.check(counter.sent == ["nappy-day-%d-task-guard-warned" % day],
		"day 13's guard warning in her view is counted warned, as the task's guard (%s)" % [counter.sent])
	_walk(guard, Vector2(300.0, 0.0), 0.7)
	t.check(counter.sent == ["nappy-day-%d-task-guard-warned" % day,
			"nappy-day-%d-task-guard-chased" % day],
		"and his charge after his second chased (%s)" % [counter.sent])
	guard.free()
	_done(counter)

## **The masked man in the escape's stairwell has his counter** like every charger: `-warned` as his
## hand goes up, `-chased` when he starts his run, and then `-caught` (the building's `EventManager`
## reports his catch, as a day's does) or `-outlasted` when his run is over without one.
func _test_the_masked_man_has_his_counter(t) -> void:
	var counter := RecordingCounter.new()
	counter.listen(EventBus)
	var day := counter.run.header.day
	var def := EventCatalogue.by_id("masked_pursuer")
	var name := "nappy-day-%d-masked-pursuer-" % day
	var path := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -400.0)])
	var man := EventInstance.new()
	man.setup(def, Vector2.ZERO, path)
	t.add_child(man)
	man.set_process(false)
	_walk(man, Vector2(0.0, -(def.notice.runs_within + 100.0)), 0.5)
	t.check(counter.sent == [name + "warned"], "warning her, he is counted warned (%s)" % [counter.sent])
	_walk(man, Vector2(0.0, -(def.notice.runs_within - 10.0)), 1.0 / 60.0)
	t.check(counter.sent == [name + "warned", name + "chased"],
		"his run is counted chased (%s)" % [counter.sent])
	for i in int(round(6.0 / (1.0 / 60.0))):
		man.player_at = Vector2(200.0, 0.0)
		man.step(1.0 / 60.0)
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
	_walk(caught, Vector2(0.0, -(def.notice.runs_within - 10.0)), Tuning.WARNING_ALONE_MAX + 0.1)
	caught.report_the_catch()
	t.check(counter.sent == [name + "warned", name + "chased", name + "caught"],
		"a run that catches her is counted caught (%s)" % [counter.sent])
	caught.free()
	_done(counter)

## **A charge the day ends under is counted ended**, so every charge still ends in exactly one way
## *(inbox #764 in minty-lemur, the player: "Charging is independent of an ended day")*: the day's end asks every
## charge still running (`EventManager.end_the_charges_still_running()`), and one that ends this way
## is not also counted shaken or outlasted when it is finished after.
func _test_a_charge_cut_short_by_the_day_is_counted_ended(t) -> void:
	var counter := RecordingCounter.new()
	counter.listen(EventBus)
	var day := counter.run.header.day
	var name := "nappy-day-%d-robber-giving-chase-" % day
	var robber := _charger(t, EventCatalogue.by_id("robber_giving_chase"))
	_walk(robber, Vector2(300.0, 0.0), 0.2)
	robber.report_the_charge_cut_short()
	robber.report_the_charge_cut_short()
	t.check(_finish_by_its_own_frames(robber), "the cut-short robber is finished after, by his own clock")
	t.check(counter.sent == [name + "chased", name + "ended"],
		"cut short by the day, it is counted ended once and nothing else (%s)" % [counter.sent])
	robber.free()
	counter.sent.clear()
	var waiting := _charger(t, EventCatalogue.by_id("alley_robbery"))
	_walk(waiting, Vector2(500.0, 0.0), 0.2)
	waiting.report_the_charge_cut_short()
	t.check(counter.sent.is_empty(), "a charger that never charged has nothing to end (%s)" % [counter.sent])
	waiting.free()
	_done(counter)

## A charger at the origin, in the tree, stepped by hand.
func _charger(t: Node, def: EventDef) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	return instance

## Steps `instance` with her held well away until it leaves or is finished the way the game
## finishes it, its own clock run out (or her shaken off), and says whether it did.
func _finish_by_its_own_frames(instance: EventInstance) -> bool:
	var step := 1.0 / 60.0
	for i in int(round((instance.def.telegraph_time + instance.def.duration + 1.0) / step)):
		instance.player_at = instance.global_position + Vector2(400.0, 0.0)
		instance.step(step)
		if instance.is_leaving or instance.is_finished:
			return true
	return false

## Steps `instance` for `seconds` with her held at `her`.
func _walk(instance: EventInstance, her: Vector2, seconds: float) -> void:
	var step := 1.0 / 60.0
	for i in maxi(1, int(round(seconds / step))):
		instance.player_at = her
		instance.step(step)

## The pelican's own four moments, each its own day-numbered event *(inbox #527 in azure-tapir, the player: "when
## the pelican spawns, when it's on screen, and when it's hitting the player. it must appear as its
## own entry")* — one send per signal, in the order the signals came. That each signal fires once
## per pelican, at its moment, is `tests/test_pelican.gd`'s.
func _test_the_pelican_is_its_own_entry(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.pelican_spawned.emit(null)
	counter.bus.pelican_sighted.emit(null)
	counter.bus.pelican_excited_her.emit(null)
	counter.bus.pelican_struck_her.emit(null)
	var expected: Array[String] = []
	for moment in ["spawned", "seen", "excited", "hit"]:
		expected.append("nappy-day-%d-pelican-%s" % [day, moment])
	t.check(counter.sent == expected,
			"the pelican's four moments are four events of its own (%s)" % [counter.sent])
	_done(counter)

## A day the pelican ends folds `pelican` into its loss, never its row's `cyclist` — the cause
## `LossCause.of()` names it by (`tests/test_loss_cause.gd`), carried through.
func _test_a_day_lost_to_the_pelican_names_the_pelican(t) -> void:
	var counter := RecordingCounter.new()
	var day := counter.run.header.day
	counter.bus.pelican_struck_her.emit(null)
	counter.bus.day_ended.emit(day, GameEnums.DayResult.LOST_HARD_FAIL, "pelican", 0.0)
	t.check(counter.sent == ["nappy-day-%d-pelican-hit" % day,
			"nappy-day-%d-lost-hard-fail-pelican" % day],
			"the hit, then the day lost to the pelican (%s)" % [counter.sent])
	_done(counter)

## An encounter's three names and a bout of running *(misty-newt)*: the day the signal carries,
## not the run's, since an influence that waited can go out after the next day began; the row
## hyphenated as every id in a name is; and an influence never seen named apart, so influenced ÷
## seen counts only what she could see. When each is sent is `tests/test_encounters.gd`'s.
func _test_encounters_and_runs_are_named_by_their_day_and_row(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.encounter_seen.emit(4, "charging_dog")
	counter.bus.encounter_influenced.emit(4, "charging_dog", true)
	counter.bus.encounter_influenced.emit(7, "pelican", false)
	counter.bus.run_bout_began.emit(9)
	t.check(counter.sent == ["nappy-day-4-seen-charging-dog", "nappy-day-4-influenced-charging-dog",
			"nappy-day-7-influenced-unseen-pelican", "nappy-day-9-ran"],
			"seen, influenced, influenced-unseen and ran, each under its own day (%s)"
			% [counter.sent])
	_done(counter)

## Every event the counter sends carries `no_session: true`, the one thing that keeps it counted
## every time on a site whose sessions stay on for the page visit ("okay, I can turn session back
## on and you opt out for everything except /nappy.josuakrause.com/"). Every handler is driven
## through `RecordingCounter`, and each name it sent is checked in the options
## `GoatCounterOutbox.send()` hands `count()` and in the script line itself, parsed back rather than searched as text.
func _test_every_event_opts_out_of_sessions(t) -> void:
	var counter := RecordingCounter.new()
	counter.bus.run_begun.emit(1, false)
	counter.begin(1)
	counter.bus.resistance_contact_available.emit(1)
	counter.bus.resistance_mark_seen.emit(1)
	counter.bus.resistance_step_completed.emit(1)
	counter.bus.resistance_contact_available.emit(2)
	counter.bus.resistance_step_failed.emit(2)
	counter.bus.resistance_contact_available.emit(3)
	counter.bus.event_sighted.emit("burning_building")
	counter.bus.event_lit_unmet.emit("burning_building")
	counter.bus.city_gone_dark.emit()
	counter.bus.pursuit_began.emit("charging_dog")
	counter.bus.pursuit_ended.emit("charging_dog", false)
	counter.bus.encounter_seen.emit(2, "charging_dog")
	counter.bus.encounter_influenced.emit(2, "charging_dog", true)
	counter.bus.encounter_influenced.emit(2, "charging_dog", false)
	counter.bus.run_bout_began.emit(2)
	counter.bus.pelican_spawned.emit(null)
	counter.bus.pelican_sighted.emit(null)
	counter.bus.pelican_excited_her.emit(null)
	counter.bus.pelican_struck_her.emit(null)
	counter.bus.poster_torn.emit()
	counter.bus.poster_pursuit_sent.emit()
	counter.bus.player_detained.emit("chatting_mother")
	counter.bus.player_detained.emit("checkpoint_hut")
	counter.bus.day_ended.emit(counter.run.header.day, GameEnums.DayResult.LOST_CRYING, "car", 0.0)
	counter.bus.run_restarted.emit(1)
	counter.bus.run_ended.emit(GameEnums.Ending.GOOD)
	counter.bus.escape_begun.emit()
	counter.bus.escape_city_entered.emit()
	counter.bus.escape_lost.emit(DaySpec.Section.CITY, GameEnums.DayResult.LOST_TIMEOUT)
	counter.bus.escape_out.emit(CityEdge.Kind.BRIDGE)
	counter.bus.controls_chosen.emit(true, false)
	t.check(counter.sent.size() >= 20,
		"there were events to check (%d)" % counter.sent.size())
	var prefix := "try { window.goatcounter.count("
	var suffix := "); } catch (e) {}"
	var scripts: Array[String] = []
	var outbox := GoatCounterOutbox.new(func(script: String) -> void: scripts.append(script))
	for name: String in counter.sent:
		outbox.send(name, true)
	t.check(scripts.size() == counter.sent.size(), "each event is one script line")
	for i in counter.sent.size():
		var name := counter.sent[i]
		var call := scripts[i]
		var options: Variant = null
		if call.begins_with(prefix) and call.ends_with(suffix):
			options = JSON.parse_string(call.substr(prefix.length(),
					call.length() - prefix.length() - suffix.length()))
		t.check(options is Dictionary and options.get("no_session") == true
				and options.get("event") == true and options.get("path") == name,
			"%s is an event under its own path that opts out of sessions" % name)
		t.check(options is Dictionary and options.get("title") == name and options.size() == 4,
			"%s: the script line hands count() exactly those options" % name)
	_done(counter)

## **Each of the escape's sections is counted as a day of its own, under its own number** *(minty-
## lemur #785: "telemetry should work the same also in escape both apartment and city")*: what is
## counted while it is walked is named by the day of the walk last begun — the building's
## `DaySpec.BUILDING_DAY`, the city's `DaySpec.CITY_DAY` — never by the calendar, which stays on
## the last day for the whole escape. The escape's own names go out beside the day's, as before.
func _test_an_escape_section_is_counted_as_a_day_of_its_own(t) -> void:
	var counter := RecordingCounter.new()
	counter.run.header.day = Tuning.RUN_LENGTH_DAYS
	var building := DaySpec.BUILDING_DAY
	counter.begin(building)
	counter.bus.pursuit_warned.emit("masked_pursuer")
	counter.bus.pursuit_began.emit("masked_pursuer")
	counter.bus.pursuit_caught.emit("masked_pursuer")
	counter.bus.day_ended.emit(building, GameEnums.DayResult.LOST_HARD_FAIL, "masked-pursuer", 12.0)
	counter.bus.escape_lost.emit(DaySpec.Section.BUILDING, GameEnums.DayResult.LOST_HARD_FAIL)
	counter.begin(building)
	counter.bus.day_ended.emit(building, GameEnums.DayResult.WON, "", 40.0)
	counter.bus.escape_city_entered.emit()
	var city := DaySpec.CITY_DAY
	counter.begin(city)
	counter.bus.city_gone_dark.emit()
	counter.bus.player_detained.emit("checkpoint_post")
	counter.bus.day_ended.emit(city, GameEnums.DayResult.WON, "", 90.0)
	counter.bus.escape_out.emit(CityEdge.Kind.BRIDGE)
	var b := "nappy-day-%d-" % building
	var c := "nappy-day-%d-" % city
	t.check(counter.sent == [b + "began", b + "masked-pursuer-warned", b + "masked-pursuer-chased",
			b + "masked-pursuer-caught", b + "lost-hard-fail-masked-pursuer", "nappy-escape-lost",
			b + "began", b + "won", "nappy-escape-city", c + "began", c + "blackout",
			c + "checkpoint", c + "won", "nappy-escape-out"],
			"the building and the city are counted as days %d and %d (%s)"
			% [building, city, counter.sent])
	_done(counter)
