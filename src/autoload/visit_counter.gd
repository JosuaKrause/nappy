extends Node
## Sends anonymous GoatCounter events for how far a run gets — see docs/TELEMETRY.md, "The page
## counts visits", and PLAYTEST-132 ("let's get info about how far people get ... anything with
## debug doesn't get tracked").
##
## **A different thing from `Telemetry`, the run log.** This never writes a file and never reads
## one back — it only calls the page's own `window.goatcounter.count()`, which the page's `<head>`
## loads `count.js` for (`export_presets.cfg`'s `html/head_include`) with the game's own site,
## `nappy.goatcounter.com`, as its endpoint. That site keeps sessions for the page visit, which
## `count.js` counts on load, and every event here opts out of them with `no_session`, so it
## counts every time it is sent — a day lost three times in an evening is three `lost-*` — while
## the visit stays one visitor ("okay, I can turn session back on and you opt out for everything
## except /nappy.josuakrause.com/"). Off the web, on a debug build, or behind `?debug=1`, it is a
## silent no-op — see
## `_may_ever_send()`. `count.js` loading asynchronously is not one of those: an event asked for
## before it has finished loading is queued and sent the moment it appears — see `_pending` — and
## only a `count.js` genuinely never loading (missing or blocked) leaves that queue unsent.
##
## **It only listens**, the same discipline `TelemetryObserver` keeps for the run log: everything
## here answers an `EventBus` signal, reads nothing gameplay decides by, and writes nothing back
## into anything gameplay reads. The telemetry skill's own invariant — the game plays identically
## with this off — holds for this counter exactly as it holds for the run log, and it is why every
## signal it listens to already exists for another reason (or was added purely to be listened to,
## with no behaviour of its own — see `EventBus`'s own doc on each one).
##
## Every event name starts with `nappy-`, the prefix `tools/goatcounter.sh` reads events back by,
## and every name is short, lowercase and hyphenated —
## `nappy-day-6-lost-crying`, PLAYTEST-132's own shape for it. Counts only: no seed, no position,
## no time and nothing that could tell one visitor from another or from their own next visit.
##
## The events, at least:
## - `nappy-run-fresh` / `nappy-run-resumed-day-N` — a run begun fresh, or resumed from the save.
## - `nappy-mode-hard` / `nappy-mode-normal` — a fresh run's mode, once, as its title is dismissed.
## - `nappy-day-N-began` — each day begun (a retry begins it again, for the day it repeats), and
##   `nappy-day-N-began-hard` beside it for a hard run's, so a normal run's count is the difference.
## - `nappy-checkpoint-N-from-day-M` — a normal run out of nerves on day M, back at checkpoint N.
## - `nappy-day-N-won` / `nappy-day-N-lost-timeout` — a day's end that names nothing further: a win
##   needs no cause and a timeout's own name already says everything about a clock that ran out.
## - `nappy-day-N-lost-crying-<source>` / `nappy-day-N-lost-hard-fail-<what>` — a lost day's own
##   name, one event rather than a `lost-*` beside a second one, folding in what actually did it:
##   `car` for the one hard fail that is not an event row, otherwise the row id (hyphenated,
##   `charging-dog`); a crying loss names `crowd`, `traffic`, `self`, or the row id, whichever
##   landed the most on her over the crying window — the `cause` `EventBus.day_ended` carries, see
##   its own doc and `_loss_event_suffix()` below. A `LOST_CRYING`/`LOST_HARD_FAIL` day ended with
##   no cause still sends the bare `lost-crying` / `lost-hard-fail` rather than nothing.
## - `nappy-day-3-seen-fire` / `nappy-day-3-fire-unmet` — the burning building sighted, and lit off
##   her path at dusk on a day she won without meeting it.
## - `nappy-day-14-blackout` — the city goes dark, whether or not a mast was silenced.
## - `nappy-escape-city` — the building is behind her and the city section begins.
## - `nappy-day-N-dog-chased` / `nappy-day-N-dog-shaken` / `nappy-day-N-dog-outlasted` —
##   `charging_dog` starts chasing, and how the chase ended without catching her. A caught chase is
##   `nappy-day-N-lost-hard-fail-charging-dog` instead, off the pair above.
## - `nappy-day-N-seen-<event>` / `nappy-day-N-influenced-<event>` /
##   `nappy-day-N-influenced-unseen-<event>` — one encounter with an event instance properly on
##   screen, meaningful, or meaningful without ever being seen, each at most once per encounter
##   (`EncounterWatch`). `<event>` is the row's id hyphenated, or `pelican`.
## - `nappy-day-N-ran` — a bout of her running begun (`EncounterWatch`).
## - `nappy-day-N-pelican-spawned` / `nappy-day-N-pelican-seen` / `nappy-day-N-pelican-excited` /
##   `nappy-day-N-pelican-hit` — the one cyclist in about four hundred drawn as a pelican: created,
##   first on screen, its field's first share of her meter, and its lethal reach covering her, each
##   once per pelican. A day it ends is `nappy-day-N-lost-hard-fail-pelican` (or `lost-crying-pelican`
##   when it landed the most), never `cyclist`.
## - `nappy-day-N-mark-seen` / `nappy-day-N-mark-read` / `nappy-day-N-mark-missed` — a chalk mark
##   noticed, touched, or untouched when the day it belongs to ends.
## - `nappy-day-N-task-done` / `nappy-day-N-task-skipped` — each perform step done, and each a day
##   ended without: a mark never gives one of these any more, see `mark-*` above.
## - `nappy-day-N-poster-torn` / `nappy-day-N-chat` / `nappy-day-N-checkpoint` — every poster torn,
##   every mother who stops her to chat and every checkpoint hold.
## - `nappy-day-N-poster-pursuit` — a tear that sends a pursuer on foot after her, beside its
##   `poster-torn`.
## - `nappy-ending-bad` / `nappy-ending-neutral` / `nappy-ending-good` — the ending reached (`bad`
##   is a hard run's alone).
## - `nappy-escape-begun` / `nappy-escape-lost` / `nappy-escape-out` — the escape: begun (the fresh
##   handover only), lost (either section, any attempt), or got out. Beside them, each of the
##   escape's two sections is counted as a day of its own under its own number, after the last day
##   (`DaySpec.BUILDING_DAY` for the building, `DaySpec.CITY_DAY` for the city): its `began`, its
##   `won` or `lost-*` with what did it, and everything counted while it is walked.
## - `nappy-controls-joystick` / `nappy-controls-tap` / `nappy-controls-keys` — the "etc.": which
##   button began the run on the title screen, or that a key did, cheap to answer and part of "how
##   far people get" in its own way.

func _ready() -> void:
	EventBus.run_begun.connect(_on_run_begun)
	EventBus.day_started.connect(_on_day_started)
	EventBus.day_ended.connect(_on_day_ended)
	EventBus.run_restarted.connect(_on_run_restarted)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.resistance_contact_available.connect(_on_task_offered)
	EventBus.resistance_step_completed.connect(_on_task_completed)
	EventBus.resistance_step_failed.connect(_on_task_failed)
	EventBus.resistance_mark_seen.connect(_on_mark_seen)
	EventBus.event_sighted.connect(_on_event_sighted)
	EventBus.event_lit_unmet.connect(_on_event_lit_unmet)
	EventBus.city_gone_dark.connect(_on_city_gone_dark)
	EventBus.pursuit_began.connect(_on_pursuit_began)
	EventBus.pursuit_warned.connect(_on_pursuit_warned)
	EventBus.pursuit_caught.connect(_on_pursuit_caught)
	EventBus.pursuit_cut_short.connect(_on_pursuit_cut_short)
	EventBus.pursuit_ended.connect(_on_pursuit_ended)
	EventBus.encounter_seen.connect(_on_encounter_seen)
	EventBus.encounter_influenced.connect(_on_encounter_influenced)
	EventBus.run_bout_began.connect(_on_run_bout_began)
	EventBus.pelican_spawned.connect(_on_pelican_spawned)
	EventBus.pelican_sighted.connect(_on_pelican_sighted)
	EventBus.pelican_excited_her.connect(_on_pelican_excited_her)
	EventBus.pelican_struck_her.connect(_on_pelican_struck_her)
	EventBus.poster_torn.connect(_on_poster_torn)
	EventBus.poster_pursuit_sent.connect(_on_poster_pursuit_sent)
	EventBus.player_detained.connect(_on_player_detained)
	EventBus.escape_begun.connect(_on_escape_begun)
	EventBus.escape_city_entered.connect(_on_escape_city_entered)
	EventBus.escape_lost.connect(_on_escape_lost)
	EventBus.escape_out.connect(_on_escape_out)
	EventBus.controls_chosen.connect(_on_controls_chosen)
	EventBus.run_mode_chosen.connect(_on_run_mode_chosen)
	EventBus.went_back_to_a_checkpoint.connect(_on_went_back_to_a_checkpoint)

# ------------------------------------------------------------------- the gate ---

## The run's configuration, handed in by `main` at boot (`configure()`), or `null` before then —
## and nothing is sent before then, since the gate cannot yet say whether the page asked
## `?debug=1`.
var _config: RunConfig

## The run this page is counting, handed in by `main` at boot (`configure()`): its mode, read as a
## day begins, and its day, which names what is counted before any `day_started` has been heard.
var _run: RunState

## Hands the counter the run's configuration and the run; a `null` configuration puts it back to
## none, which sends nothing.
func configure(config: RunConfig, run: RunState) -> void:
	_config = config
	_run = run

## Whether an event may be sent at all, right now. `_should_send()` below is the pure truth table;
## this is the one place its four live inputs are actually read.
func should_send() -> bool:
	return _config != null and _should_send(OS.get_name() == "Web", _config.debug_build,
			_config.readout_requested, _goatcounter_present())

## The gate, as a pure function of its four inputs: on the web, not a debug build, not
## `?debug=1` (`RunConfig.readout_requested`, the same flag that keeps `count.js` itself off the
## page — see `export_presets.cfg`'s `html/head_include`), and `window.goatcounter.count` actually
## present, since the script can fail to load or be blocked by the visitor's own browser.
static func _should_send(on_web: bool, is_debug_build: bool, debug_requested: bool,
		goatcounter_present: bool) -> bool:
	return _may_ever_send(on_web, is_debug_build, debug_requested) and goatcounter_present

## The three of the gate's four inputs that can never change their answer for the rest of this
## page's life once asked — the build is not going to stop being a debug build, and `?debug=1`
## does not disappear from a page nobody reloads. `_goatcounter_present()` is the one input that
## legitimately answers differently a moment later, because `count.js` loads asynchronously
## (`export_presets.cfg`'s own `counter.async = true`) — so `_send_event()` below asks this once,
## up front, to decide *whether an event is ever worth queuing at all* before it asks the
## time-varying half.
static func _may_ever_send(on_web: bool, is_debug_build: bool, debug_requested: bool) -> bool:
	return on_web and not is_debug_build and not debug_requested

## Whether the page actually has a callable `window.goatcounter.count` — `false` off the web
## without ever asking `JavaScriptBridge`, the same guard `DevFlags.page_query()` makes before its
## own `JavaScriptBridge.eval()`. **`bool(...)`, never `present is bool`**: a JS boolean crosses
## `JavaScriptBridge.eval()` as a GDScript `int` (`1`/`0`), not a `bool` — confirmed against a real
## export, where `present is bool` silently refused every event, gate closed, no error anywhere to
## say why. `bool()` reads true off that `int` the same as it would a native bool.
static func _goatcounter_present() -> bool:
	if OS.get_name() != "Web":
		return false
	var present: Variant = JavaScriptBridge.eval(
			"(typeof window.goatcounter !== 'undefined' " +
			"&& typeof window.goatcounter.count === 'function')")
	return bool(present)

## Events asked for while `count.js` had not yet finished loading — see `_may_ever_send()`'s own
## doc for why that is the one live input worth waiting on. Flushed the cheap way, from
## `_send_event()` itself the next time anything is asked for, rather than a timer or a per-frame
## poll: nothing here may cost anything while the game is otherwise between events. A cold,
## first-ever visit is the case this exists for — `count.js` is a real network fetch, and the
## earliest events of a run (`run_begun`, day 1's `day_started`) can race ahead of it; a later
## visit, with the script already cached, never queues anything at all.
##
## **Never populated for a reason that cannot change.** `_send_event()` checks `_may_ever_send()`
## before this queue is ever touched, so a debug build or a page carrying `?debug=1` holds nothing
## here and costs nothing beyond the one boolean check every other refusal already costs.
var _pending: Array[String] = []

func _send_event(name: String) -> void:
	if _config == null \
			or not _may_ever_send(OS.get_name() == "Web", _config.debug_build, _config.readout_requested):
		return
	var present := _goatcounter_present()
	_flush_pending(present)
	if present:
		_dispatch(name)
	else:
		_pending.append(name)

## Sends whatever is queued, in the order it was asked for, when `present` holds; leaves the
## queue exactly as it was otherwise. `present` is a parameter rather than a fresh
## `_goatcounter_present()` read taken in here, the same split `_should_send()` already makes for
## its own live half, so a test can drive both outcomes directly without a page to ask.
func _flush_pending(present: bool) -> void:
	if not present or _pending.is_empty():
		return
	var queued := _pending
	_pending = []
	for queued_name in queued:
		_dispatch(queued_name)

## Sends `name` through the page's own `count.js` — see `_count_call()` for the call.
func _dispatch(name: String) -> void:
	JavaScriptBridge.eval(_count_call(name))

## What `window.goatcounter.count()` is given for `name` — see
## https://www.goatcounter.com/help/events and /help/js. `path` is the event's own name, which
## also keeps the page's path function (the head's `goatcounter.path`, for the visit alone) off
## it, since `count.js` reads that only when a call names no path. **`no_session` on every
## event**: the site keeps sessions for the page visit, and a path hit again inside one session
## is not counted again, so without it a day lost three times would read as one `lost-*`.
## `count.js` sends it as the hit's `ns` parameter, and GoatCounter counts a hit carrying it as a
## visit of its own.
static func _count_options(name: String) -> Dictionary:
	return {"path": name, "title": name, "event": true, "no_session": true}

## The one line of script `_dispatch()` evaluates for `name`: `count()` with `_count_options()`,
## wrapped in the page's own `try`/`catch` as well as the caller's own `_goatcounter_present()`
## check, so a third-party script's own internals throwing never becomes an engine error on this
## side — "a missing or failing window.goatcounter must never raise or print an engine error".
static func _count_call(name: String) -> String:
	return ("try { window.goatcounter.count(%s); } catch (e) {}"
			% JSON.stringify(_count_options(name)))

# --------------------------------------------------------------- event names ---
# Pure functions, each testable without a web page, a save or a run behind it.

static func _day_event_name(day: int, suffix: String) -> String:
	return "nappy-day-%d-%s" % [day, suffix]

## `GameEnums.DayResult`'s own key, lowercased and hyphenated — `LOST_CRYING` -> `lost-crying`,
## `WON` -> `won` — so a day's end is always named straight off the game's own loss causes rather
## than a second copy of them invented here.
static func _loss_cause(result: GameEnums.DayResult) -> String:
	return String(GameEnums.DayResult.keys()[result]).to_lower().replace("_", "-")

## The full name a day's own end sends: `_loss_cause(result)` with `cause` — `EventBus.day_ended`'s
## own, unprefixed — folded on for the two results that ever have one. The game names no cause for
## `WON` or `LOST_TIMEOUT`; this still guards on `result` rather than trusting an empty `cause`
## alone, so neither name can ever carry one. An empty `cause` for `LOST_CRYING`/`LOST_HARD_FAIL`
## sends the bare loss name rather than nothing.
static func _loss_event_suffix(result: GameEnums.DayResult, cause: String) -> String:
	var base := _loss_cause(result)
	if cause.is_empty():
		return base
	if result != GameEnums.DayResult.LOST_CRYING and result != GameEnums.DayResult.LOST_HARD_FAIL:
		return base
	return "%s-%s" % [base, cause]

static func _run_begun_name(day: int, resumed: bool) -> String:
	return "nappy-run-resumed-day-%d" % day if resumed else "nappy-run-fresh"

## A fresh run's mode. *(gentle-osprey, the player: "needs telemetry whether someone chooses hard
## mode".)*
static func _mode_event_name(hard: bool) -> String:
	return "nappy-mode-hard" if hard else "nappy-mode-normal"

## What a day begun sends: `began` for every run, and its hard-only copy beside it for a hard run.
## *(gentle-osprey, the player: "we should also count regular day starts with mode. so we know how
## far people get in each mode", answered "Add a hard-only copy".)* The plain name stays every
## run's, so its series runs on unbroken and a normal run's count is the total less the hard one.
## Nothing else splits by mode: *"hard mode doesn't affect gameplay -- only restart pacing"*.
static func _day_began_names(day: int, hard: bool) -> Array[String]:
	var names: Array[String] = [_day_event_name(day, "began")]
	if hard:
		names.append(_day_event_name(day, "began-hard"))
	return names

## A normal run back at checkpoint `checkpoint_day` (1, 4, 8 or 12) after losing its last nerve on
## `lost_day`. *(gentle-osprey, the player: "whether they are restarting from a checkpoint after
## losing all nerves".)*
static func _checkpoint_event_name(checkpoint_day: int, lost_day: int) -> String:
	return "nappy-checkpoint-%d-from-day-%d" % [checkpoint_day, lost_day]

## `keys` when a key began the run, whatever scheme that gave it — the title begins a key's run in
## the tap scheme, and a key player is not a tap player — otherwise the button pressed.
static func _controls_event_name(joystick: bool, by_key: bool) -> String:
	if by_key:
		return "nappy-controls-keys"
	return "nappy-controls-joystick" if joystick else "nappy-controls-tap"

## `EventBus.player_detained`'s own `id` (`nearest.def.id` in
## `CheckpointController.check_detentions()`), named the way the day brief already tells the two
## kinds of stop apart: `chatting_mother` is a `chat`, and every other id that can reach here
## (`checkpoint_hut`, `checkpoint_post` — `checkpoint_gate`'s own boom never detains, see
## `EventCatalogue`) is a `checkpoint`.
static func _detention_suffix(id: String) -> String:
	return "chat" if id == "chatting_mother" else "checkpoint"

## Whether `step` is a chalk-mark pickup or the perform half it unlocks — read straight off the
## resistance's own data (`ResistanceSteps.Step.is_pickup`) rather than a parity rule invented
## here, so a step's own kind can never disagree with what the resistance itself built it as.
## `false` for an index `ResistanceSteps` does not know (the finale's own step, or a stale index),
## which reads as a task rather than a mark — the safer default, since a `task-done`/`task-skipped`
## miscount is the smaller error next to a `mark-*` sent for a step that was never a mark at all.
static func _is_pickup_step(step: int) -> bool:
	var data := ResistanceSteps.by_index(step)
	return data != null and data.is_pickup

# ------------------------------------------------------------------- signals ---

## Whether this autoload — which, like every autoload, survives `get_tree().reload_current_scene()`
## and so lives for as long as this browser tab keeps its WASM instance, across a held restart or
## a day-14 handover into the escape alike — has already answered `run_begun` once. `main.gd`'s own
## `resumed` argument only asks "did a save exist when `GameSave.try_resume()` ran"; it cannot also
## know whether *this page* already ran once before asking, because that is not something
## `GameState` or a save file could ever record — a save a `reload_current_scene()` wrote a moment
## ago and a save a real previous visit left both answer `GameSave.try_resume()` the same way.
## "A resume means a save that existed when the page loaded, never one this page session wrote" is
## answered here instead, the one place a flag can live for exactly a page's own lifetime.
var _reported_run_begun := false

## The decision behind `_on_run_begun()`'s own gate, pulled out to a pure function of its two
## inputs so a test can drive the truth table directly, the same split every other live check in
## this file makes for its own pure half.
static func _resumed_for_report(resumed: bool, already_reported_this_page: bool) -> bool:
	return resumed and not already_reported_this_page

## Whether a `run_begun` is the same run coming back after a reload this page made — the day-14
## handover into the escape reloads the scene onto the save it has just written — rather than a run
## begun: a second `run_begun` on one page that finds a save. That sends nothing, since the run was
## already counted; a held restart clears the save before its reload, so it finds none and counts
## as the new, fresh run it is.
static func _is_the_same_run_reloaded(resumed: bool, already_reported_this_page: bool) -> bool:
	return resumed and already_reported_this_page

func _on_run_begun(day: int, resumed: bool) -> void:
	if _is_the_same_run_reloaded(resumed, _reported_run_begun):
		return
	var actually_resumed := _resumed_for_report(resumed, _reported_run_begun)
	_reported_run_begun = true
	_send_event(_run_begun_name(day, actually_resumed))

## The day the last `day_started` announced — one of the fourteen, or one of the escape's two
## sections under their own numbers (`DaySpec.number`) — which everything counted while it is walked
## is named by: a charge, an encounter, a poster, a hold. `0` until one is heard on this page.
var _day := 0

## The day what happens now is counted under: the one `day_started` announced, or, before any has
## been heard on this page — a suite driving the counter by hand — the run's own day.
func _counted_day() -> int:
	return _day if _day > 0 else _run.header.day

func _on_day_started(day: int) -> void:
	_day = day
	for name in _day_began_names(day, _run.calendar.hard_mode):
		_send_event(name)

## A fresh run's mode, from its title. **The day behind that title has already begun** — the first
## morning is built and its `day_started` sent before the title is dismissed, while the run still
## reads as normal — so a hard run sends that day's hard copy here, once its mode is known.
func _on_run_mode_chosen(hard: bool, day: int) -> void:
	_send_event(_mode_event_name(hard))
	if hard:
		_send_event(_day_event_name(day, "began-hard"))

func _on_went_back_to_a_checkpoint(checkpoint_day: int, lost_day: int) -> void:
	_send_event(_checkpoint_event_name(checkpoint_day, lost_day))

## Which day offered a step is on offer, kept only long enough to say whether the day it belongs
## to ended with the step done or without it — `step index -> day`. A retry re-offers the same
## index for the same day (`GameState._give_the_attempt_back()` restores the step lists a lost
## attempt spent), which simply overwrites the entry with the day it already named.
var _open_tasks := {}

func _on_task_offered(step: int) -> void:
	_open_tasks[step] = _counted_day()

func _on_task_completed(step: int) -> void:
	var day: int = _open_tasks.get(step, _counted_day())
	_open_tasks.erase(step)
	_send_event(_day_event_name(day, "mark-read" if _is_pickup_step(step) else "task-done"))

## A timed step's own deadline passed — `ResistanceDirector`'s one expiry path. Counted the same
## as a step a day simply ended without touching (`_on_day_ended()` below): both are "a task day
## that ended without it", just found at two different moments.
func _on_task_failed(step: int) -> void:
	var day: int = _open_tasks.get(step, _counted_day())
	_open_tasks.erase(step)
	_send_event(_day_event_name(day, "mark-missed" if _is_pickup_step(step) else "task-skipped"))

func _on_mark_seen(step: int) -> void:
	var day: int = _open_tasks.get(step, _counted_day())
	_send_event(_day_event_name(day, "mark-seen"))

func _on_event_sighted(id: String) -> void:
	if id != "burning_building":
		return
	_send_event(_day_event_name(_counted_day(), "seen-fire"))

func _on_event_lit_unmet(id: String) -> void:
	if id != "burning_building":
		return
	_send_event(_day_event_name(_counted_day(), "fire-unmet"))

func _on_city_gone_dark() -> void:
	_send_event(_day_event_name(_counted_day(), "blackout"))

## **Every charger's own charging counter** *(inbox #764 in minty-lemur, the player: "Ending a day and a charging
## counter are not the same thing"; "Charging is independent of an ended day")*: `<charger>-warned`
## when it starts warning her, `-chased` at its charge, and its charge's end in exactly one of
## `-caught`, `-shaken`, `-outlasted` and `-ended` (the day ended some other way under it), whatever
## the day does — a catch that ends the day sends `lost-hard-fail-<row>` as well. `<charger>` is
## `charger_counter_name()`.
func _on_pursuit_warned(id: String) -> void:
	_send_event(_day_event_name(_counted_day(), "%s-warned" % charger_counter_name(id)))

func _on_pursuit_began(id: String) -> void:
	_send_event(_day_event_name(_counted_day(), "%s-chased" % charger_counter_name(id)))

func _on_pursuit_caught(id: String) -> void:
	_send_event(_day_event_name(_counted_day(), "%s-caught" % charger_counter_name(id)))

func _on_pursuit_cut_short(id: String) -> void:
	_send_event(_day_event_name(_counted_day(), "%s-ended" % charger_counter_name(id)))

func _on_pursuit_ended(id: String, shaken_off: bool) -> void:
	_send_event(_day_event_name(_counted_day(), "%s-%s" % [charger_counter_name(id),
			"shaken" if shaken_off else "outlasted"]))

## A charger's name in its counter: `dog` for `charging_dog`, so its `dog-chased`, `dog-shaken` and
## `dog-outlasted` keep the names their history has; `dog-tutorial` for the day-3 lesson's dog
## (`EventInstance.charger_name()`'s `charging_dog_tutorial`), which sends its own set and not the
## dog's *(PLAYTEST-141: "we need to record like dog tutorial")*; every other row its id hyphenated,
## as the encounter events are (`alley_robbery` -> `alley-robbery`), and `task-guard` for day 13's
## task guard, his row `task_guard`, whose sent copy counts as him (`EventDef.counts_charges_as`).
static func charger_counter_name(id: String) -> String:
	match id:
		"charging_dog":
			return "dog"
		"charging_dog_tutorial":
			return "dog-tutorial"
	return id.replace("_", "-")

## An encounter's `name` (`EventInstance.logged_name()`) as a name's last part: hyphenated the way
## every other id in a name is, `charging_dog` -> `charging-dog`.
static func _encounter_suffix(kind: String, name: String) -> String:
	return "%s-%s" % [kind, name.replace("_", "-")]

func _on_encounter_seen(day: int, name: String) -> void:
	_send_event(_day_event_name(day, _encounter_suffix("seen", name)))

## `influenced-unseen` for an encounter that was never seen, so influenced ÷ seen counts only the
## encounters she could see.
func _on_encounter_influenced(day: int, name: String, seen: bool) -> void:
	var kind := "influenced" if seen else "influenced-unseen"
	_send_event(_day_event_name(day, _encounter_suffix(kind, name)))

func _on_run_bout_began(day: int) -> void:
	_send_event(_day_event_name(day, "ran"))

## The pelican's own four moments *(inbox #527 in azure-tapir, the player: "when the pelican spawns, when it's on
## screen, and when it's hitting the player. it must appear as its own entry")*. Each signal fires
## once per pelican where it is emitted (`EventBus`'s own doc on each), so each sends once; the
## instance it carries is not read.
func _on_pelican_spawned(_instance: Variant) -> void:
	_send_event(_day_event_name(_counted_day(), "pelican-spawned"))

func _on_pelican_sighted(_instance: Variant) -> void:
	_send_event(_day_event_name(_counted_day(), "pelican-seen"))

func _on_pelican_excited_her(_instance: Variant) -> void:
	_send_event(_day_event_name(_counted_day(), "pelican-excited"))

func _on_pelican_struck_her(_instance: Variant) -> void:
	_send_event(_day_event_name(_counted_day(), "pelican-hit"))

## Every tear, not the first of an attempt: every event opts out of the site's sessions so that
## each one is counted (PLAYTEST-143: "we need a telemetry item for ripping posters").
func _on_poster_torn() -> void:
	_send_event(_day_event_name(_counted_day(), "poster-torn"))

## A tear whose marble sends a pursuer on foot after her, beside that tear's own `poster-torn`
## (PLAYTEST-143: "we need a telemetry item for ripping posters and pursuit triggered by poster
## ripping").
func _on_poster_pursuit_sent() -> void:
	_send_event(_day_event_name(_counted_day(), "poster-pursuit"))

## Every hold: `CheckpointController.check_detentions()` emits once per catch, a mother only
## ever chats once, and a checkpoint that holds her again is a second stop she paid for.
func _on_player_detained(id: String) -> void:
	_send_event(_day_event_name(_counted_day(), _detention_suffix(id)))

func _on_run_restarted(day: int) -> void:
	_send_event(_day_event_name(day, "restarted"))

func _on_run_ended(ending: GameEnums.Ending) -> void:
	_send_event("nappy-ending-%s" % String(GameEnums.Ending.keys()[ending]).to_lower())

func _on_day_ended(day: int, result: GameEnums.DayResult, cause: String, _elapsed: float) -> void:
	_send_event(_day_event_name(day, _loss_event_suffix(result, cause)))
	# Whatever today's step still stands open — never reached, or reached but not finished — is
	# skipped the moment the day it belonged to ends, whether the day was won or lost.
	for step: int in _open_tasks.keys().duplicate():
		if int(_open_tasks[step]) != day:
			continue
		_open_tasks.erase(step)
		_send_event(_day_event_name(day, "mark-missed" if _is_pickup_step(step) else "task-skipped"))

func _on_escape_begun() -> void:
	_send_event("nappy-escape-begun")

func _on_escape_city_entered() -> void:
	_send_event("nappy-escape-city")

func _on_escape_lost(_section: int, _result: int) -> void:
	_send_event("nappy-escape-lost")

func _on_escape_out(_exit_kind: int) -> void:
	_send_event("nappy-escape-out")

func _on_controls_chosen(joystick: bool, by_key: bool) -> void:
	_send_event(_controls_event_name(joystick, by_key))
