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
## - `nappy-day-N-began` — each day begun (a retry begins it again, for the day it repeats).
## - `nappy-day-N-won` / `nappy-day-N-lost-timeout` — a day's end that names nothing further: a win
##   needs no cause and a timeout's own name already says everything about a clock that ran out.
## - `nappy-day-N-lost-crying-<source>` / `nappy-day-N-lost-hard-fail-<what>` — a lost day's own
##   name, one event rather than a `lost-*` beside a second one, folding in what actually did it:
##   `car` for the one hard fail that is not a catalogue row, otherwise a catalogue id (hyphenated,
##   `charging-dog`); a crying loss names `crowd`, `traffic`, `self`, or a catalogue id, whichever
##   landed the most on her over the crying window. See `EventBus.day_lost_to`'s own doc and
##   `_loss_event_suffix()` below. A `LOST_CRYING`/`LOST_HARD_FAIL` day this counter never got a
##   cause for — reachable only where something drives `day_ended` without first driving
##   `day_lost_to` for the same day, which nothing in `main.gd`'s own wiring does — still sends the
##   bare `lost-crying` / `lost-hard-fail` rather than nothing.
## - `nappy-day-3-seen-fire` / `nappy-day-3-fire-unmet` — the burning building sighted, and lit off
##   her path at dusk on a day she won without meeting it.
## - `nappy-day-14-blackout` — the city goes dark, whether or not a mast was silenced.
## - `nappy-escape-city` — the building is behind her and the city section begins.
## - `nappy-day-N-dog-chased` / `nappy-day-N-dog-shaken` / `nappy-day-N-dog-outlasted` —
##   `charging_dog` starts chasing, and how the chase ended without catching her. A caught chase is
##   `nappy-day-N-lost-hard-fail-charging-dog` instead, off the pair above.
## - `nappy-day-N-mark-seen` / `nappy-day-N-mark-read` / `nappy-day-N-mark-missed` — a chalk mark
##   noticed, touched, or untouched when the day it belongs to ends.
## - `nappy-day-N-task-done` / `nappy-day-N-task-skipped` — each perform step done, and each a day
##   ended without: a mark never gives one of these any more, see `mark-*` above.
## - `nappy-day-N-poster-torn` / `nappy-day-N-chat` / `nappy-day-N-checkpoint` — every poster torn,
##   every mother who stops her to chat and every checkpoint hold.
## - `nappy-day-N-poster-pursuit` — a tear that sends a patrol after her, beside its `poster-torn`.
## - `nappy-ending-bad` / `nappy-ending-neutral` / `nappy-ending-good` — the ending reached.
## - `nappy-escape-begun` / `nappy-escape-lost` / `nappy-escape-out` — the escape: begun (the fresh
##   handover only), lost (either section, any attempt), or got out.
## - `nappy-controls-joystick` / `nappy-controls-tap` / `nappy-controls-keys` — the "etc.": which
##   button began the run on the title screen, or that a key did, cheap to answer and part of "how
##   far people get" in its own way.

func _ready() -> void:
	EventBus.run_begun.connect(_on_run_begun)
	EventBus.day_started.connect(_on_day_started)
	EventBus.day_lost_to.connect(_on_day_lost_to)
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
	EventBus.pursuit_ended.connect(_on_pursuit_ended)
	EventBus.poster_torn.connect(_on_poster_torn)
	EventBus.poster_pursuit_sent.connect(_on_poster_pursuit_sent)
	EventBus.player_detained.connect(_on_player_detained)
	EventBus.escape_begun.connect(_on_escape_begun)
	EventBus.escape_city_entered.connect(_on_escape_city_entered)
	EventBus.escape_lost.connect(_on_escape_lost)
	EventBus.escape_out.connect(_on_escape_out)
	EventBus.controls_chosen.connect(_on_controls_chosen)

# ------------------------------------------------------------------- the gate ---

## Whether an event may be sent at all, right now. `_should_send()` below is the pure truth table;
## this is the one place its four live inputs are actually read, the same split
## `DevFlags.live_debug_requested()`/`_live_debug_requested()` already uses.
static func should_send() -> bool:
	return _should_send(OS.get_name() == "Web", OS.is_debug_build(), DevFlags.readout_requested(),
			_goatcounter_present())

## The gate, as a pure function of its four inputs: on the web, not a debug build, not
## `?debug=1` (`DevFlags.readout_requested()`, the same flag that keeps `count.js` itself off the
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
## without ever asking `JavaScriptBridge`, the same guard `DevFlags._web_query()` makes before its
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
	if not _may_ever_send(OS.get_name() == "Web", OS.is_debug_build(), DevFlags.readout_requested()):
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

## The full name a day's own end sends, `_loss_cause(result)` with `cause` — `EventBus.day_lost_to`'s
## raw, unprefixed source — folded on for the two results it is ever set for. `cause` is only ever
## non-empty for `LOST_CRYING`/`LOST_HARD_FAIL` in real play, since `main._on_day_finished()` never
## fires `day_lost_to` for `WON` or `LOST_TIMEOUT`; this still guards on `result` rather than trusting
## an empty `cause` alone, so a stale cause left over from an earlier day can never attach itself to
## either of those two. An empty `cause` reaching here for `LOST_CRYING`/`LOST_HARD_FAIL` — nothing
## in `main.gd`'s own wiring does this, only a caller driving `_on_day_ended()` without first driving
## `_on_day_lost_to()` for the same day — sends the bare loss name rather than nothing.
static func _loss_event_suffix(result: GameEnums.DayResult, cause: String) -> String:
	var base := _loss_cause(result)
	if cause.is_empty():
		return base
	if result != GameEnums.DayResult.LOST_CRYING and result != GameEnums.DayResult.LOST_HARD_FAIL:
		return base
	return "%s-%s" % [base, cause]

static func _run_begun_name(day: int, resumed: bool) -> String:
	return "nappy-run-resumed-day-%d" % day if resumed else "nappy-run-fresh"

## `keys` when a key began the run, whatever mode that gave it — the title begins a key's run in
## `Mode.TAP`, and a key player is not a tap player — otherwise the button pressed.
static func _controls_event_name(mode: int, by_key: bool) -> String:
	if by_key:
		return "nappy-controls-keys"
	return "nappy-controls-joystick" if mode == ControlsMode.Mode.JOYSTICK else "nappy-controls-tap"

## `EventBus.player_detained`'s own `id` (`nearest.def.id` in `EventManager._check_detentions()`),
## named the way the day brief already tells the two kinds of stop apart: `chatting_mother` is a
## `chat`, and every other id that can reach here (`checkpoint_hut`, `checkpoint_post` —
## `checkpoint_gate`'s own boom never detains, see `EventCatalogue`) is a `checkpoint`.
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

func _on_day_started(day: int) -> void:
	_send_event(_day_event_name(day, "began"))

## The cause `day_lost_to` supplied for whichever day is currently ending, read once by
## `_on_day_ended()` immediately after and reset the moment it is read. `main._on_day_finished()`
## fires the two signals back to back for the same day (`day_lost_to` then `day_ended`, with
## nothing else in between), so nothing here needs a day key — and the reset means a stale cause
## from one day can never survive to attach itself to a later one.
var _pending_loss_cause := ""

func _on_day_lost_to(_day: int, cause: String) -> void:
	_pending_loss_cause = cause

## Which day offered a step is on offer, kept only long enough to say whether the day it belongs
## to ended with the step done or without it — `step index -> day`. A retry re-offers the same
## index for the same day (`GameState._give_the_resistance_back()` restores the step lists a lost
## attempt spent), which simply overwrites the entry with the day it already named.
var _open_tasks := {}

func _on_task_offered(step: int) -> void:
	_open_tasks[step] = GameState.day

func _on_task_completed(step: int) -> void:
	var day: int = _open_tasks.get(step, GameState.day)
	_open_tasks.erase(step)
	_send_event(_day_event_name(day, "mark-read" if _is_pickup_step(step) else "task-done"))

## A timed step's own deadline passed — `ResistanceDirector`'s one expiry path. Counted the same
## as a step a day simply ended without touching (`_on_day_ended()` below): both are "a task day
## that ended without it", just found at two different moments.
func _on_task_failed(step: int) -> void:
	var day: int = _open_tasks.get(step, GameState.day)
	_open_tasks.erase(step)
	_send_event(_day_event_name(day, "mark-missed" if _is_pickup_step(step) else "task-skipped"))

func _on_mark_seen(step: int) -> void:
	var day: int = _open_tasks.get(step, GameState.day)
	_send_event(_day_event_name(day, "mark-seen"))

func _on_event_sighted(id: String) -> void:
	if id != "burning_building":
		return
	_send_event(_day_event_name(GameState.day, "seen-fire"))

func _on_event_lit_unmet(id: String) -> void:
	if id != "burning_building":
		return
	_send_event(_day_event_name(GameState.day, "fire-unmet"))

func _on_city_gone_dark() -> void:
	_send_event(_day_event_name(GameState.day, "blackout"))

func _on_pursuit_began(id: String) -> void:
	if id != "charging_dog":
		return
	_send_event(_day_event_name(GameState.day, "dog-chased"))

func _on_pursuit_ended(id: String, shaken_off: bool) -> void:
	if id != "charging_dog":
		return
	_send_event(_day_event_name(GameState.day, "dog-shaken" if shaken_off else "dog-outlasted"))

## Every tear, not the first of an attempt: every event opts out of the site's sessions so that
## each one is counted (PLAYTEST-143: "we need a telemetry item for ripping posters").
func _on_poster_torn() -> void:
	_send_event(_day_event_name(GameState.day, "poster-torn"))

## A tear whose marble sends a patrol, beside that tear's own `poster-torn` (PLAYTEST-143: "we
## need a telemetry item for ripping posters and pursuit triggered by poster ripping").
func _on_poster_pursuit_sent() -> void:
	_send_event(_day_event_name(GameState.day, "poster-pursuit"))

## Every hold: `EventManager._check_detentions()` emits once per catch, a mother only ever chats
## once, and a checkpoint that holds her again is a second stop she paid for.
func _on_player_detained(id: String) -> void:
	_send_event(_day_event_name(GameState.day, _detention_suffix(id)))

func _on_run_restarted(day: int) -> void:
	_send_event(_day_event_name(day, "restarted"))

func _on_run_ended(ending: GameEnums.Ending) -> void:
	_send_event("nappy-ending-%s" % String(GameEnums.Ending.keys()[ending]).to_lower())

func _on_day_ended(day: int, result: GameEnums.DayResult) -> void:
	var cause := _pending_loss_cause
	_pending_loss_cause = ""
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

func _on_escape_lost() -> void:
	_send_event("nappy-escape-lost")

func _on_escape_out() -> void:
	_send_event("nappy-escape-out")

func _on_controls_chosen(mode: int, by_key: bool) -> void:
	_send_event(_controls_event_name(mode, by_key))
