class_name GoatCounterOutbox
extends RefCounted
## What `VisitCounter` hands its events to: the gate that decides whether an event may be sent,
## the queue that holds events asked for before the page's `count.js` has loaded, and the one line
## of script that counts an event. The counter decides *what* is counted and when; this decides
## *whether and how* it reaches the page, so the gate and the queue are checked on their own, with
## a script evaluator handed in instead of a web page.

## Evaluates a line of script on the page. The counter hands in `JavaScriptBridge.eval`; a test
## hands in a recorder.
var _evaluate: Callable

## Events asked for while `count.js` had not yet finished loading, in the order they were asked
## for — flushed the cheap way, from `send()` itself the next time anything is asked for, rather
## than a timer or a per-frame poll: nothing here may cost anything while the game is otherwise
## between events. A cold, first-ever visit is the case this exists for — `count.js` is a real
## network fetch, and the earliest events of a run (`run_begun`, day 1's `day_started`) can race
## ahead of it; a later visit, with the script already cached, never queues anything at all.
var _pending: Array[String] = []

func _init(evaluate: Callable) -> void:
	_evaluate = evaluate

## The three of the gate's four inputs (on the web, not a debug build, not `?debug=1` —
## `RunConfig.readout_requested`, the same flag that keeps `count.js` itself off the page, see
## `export_presets.cfg`'s `html/head_include`) that can never change their answer for the rest of this
## page's life once asked — the build is not going to stop being a debug build, and `?debug=1`
## does not disappear from a page nobody reloads. `goatcounter_present` is the one input that
## legitimately answers differently a moment later, because `count.js` loads asynchronously
## (`export_presets.cfg`'s own `counter.async = true`) — so the counter asks this once, up front,
## to decide *whether an event is ever worth queuing at all* before it asks the time-varying half.
## **A reason that cannot change never populates the queue**: a debug build or a page carrying
## `?debug=1` holds nothing here and costs nothing beyond the one boolean check.
static func may_ever_send(on_web: bool, is_debug_build: bool, debug_requested: bool) -> bool:
	return on_web and not is_debug_build and not debug_requested

## Counts `name` when `present` holds, after whatever was queued before it, in the order it was
## asked for; queues it otherwise. `present` is a parameter rather than a read taken in here, the
## same split `may_ever_send()` makes for the inputs that never change, so a test drives both outcomes without
## a page to ask.
func send(name: String, present: bool) -> void:
	if present:
		var queued := _pending
		_pending = []
		for queued_name in queued:
			_evaluate.call(_count_call(queued_name))
		_evaluate.call(_count_call(name))
	else:
		_pending.append(name)

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

## The one line of script `send()` evaluates for `name`: `count()` with `_count_options()`,
## wrapped in the page's own `try`/`catch` as well as the caller's own presence check, so a
## third-party script's own internals throwing never becomes an engine error on this side — "a
## missing or failing window.goatcounter must never raise or print an engine error".
static func _count_call(name: String) -> String:
	return ("try { window.goatcounter.count(%s); } catch (e) {}"
			% JSON.stringify(_count_options(name)))
