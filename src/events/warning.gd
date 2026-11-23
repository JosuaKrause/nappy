class_name Warning
extends RefCounted
## **One warning: a clock that starts, may be held, and ends by being called off or by running
## out.** Every warning in the game is this clock, read against the caller's own: an event's notice
## (a charger's warning inside its one radius, a pursuer's approach, a man standing with his hand
## raised, the masked man's wait), a crossing of a district door's line (`CheckpointController`),
## and the screen-edge badge up alone before a thing exists (`PendingWarning`).
##
## **The caller owns the clock it is read against** — an event's age, the badge's own time up —
## so a warning carried across a stream-out is its start on that clock (`started_at()`), and a
## warning never drifts from the clock beside it. What calls it off and what it runs out into
## are the caller's: a test the caller asks each tick (`call_off_when()`), and an action
## (`run_when_it_runs_out()`) that `tick()` runs once, the frame it has run.

## What `tick()` found.
enum Outcome { NOT_RUNNING, RUNNING, CALLED_OFF, RAN_OUT }

## Seconds it runs for, on the caller's clock, once started; `INF` for one that only ends by being
## called off or stopped by hand.
var _length := INF
## Asked each `tick()` while it runs; true calls it off. Optional (`call_off_when()`).
var _cancel_if := Callable()
## Run once by `tick()`, the frame it has run. Optional (`run_when_it_runs_out()`).
var _on_expired := Callable()

var _started := INF
var _held := 0.0

## Starts it at `clock`, for `seconds`. A warning already running starts again from here.
func start(clock: float, seconds := INF) -> void:
	_started = clock
	_held = 0.0
	_length = seconds

## Seconds it runs for once started, `INF` for one with no length.
func lasts_for() -> float:
	return _length

## What each `tick()` asks while it runs: when `test` answers true it is called off.
func call_off_when(test: Callable) -> void:
	_cancel_if = test

## What `tick()` runs, once, the frame it has run out.
func run_when_it_runs_out(action: Callable) -> void:
	_on_expired = action

## Stops it, called off or no longer wanted, so it is not running.
func stop() -> void:
	_started = INF
	_held = 0.0

func is_running() -> bool:
	return _started != INF

## How long it has run at `clock`, less what it was held for; 0 while it is not running.
func elapsed(clock: float) -> float:
	if _started == INF:
		return 0.0
	return clock - _started - _held

## How long it has still to run at `clock`; `INF` for one with no length, 0 once it has run.
func left(clock: float) -> float:
	if _length == INF:
		return INF
	return maxf(_length - elapsed(clock), 0.0)

## Whether it is running and has run its length at `clock`.
func has_run(clock: float) -> bool:
	return _started != INF and elapsed(clock) >= _length

## Holds it for `seconds` of the caller's clock: that much of its clock does not count.
func hold(seconds: float) -> void:
	_held += seconds

## Where on the caller's clock it would have started had it never been held, or `INF` while it is
## not running: what a stream-out carries, so the warning comes back exactly as far run.
func started_at() -> float:
	return _started + _held if _started != INF else INF

## One frame at `clock`: called off when its test says so, run out (and its action run) the
## frame it has run its length, stopped either way. Answers which.
func tick(clock: float) -> Outcome:
	if _started == INF:
		return Outcome.NOT_RUNNING
	if _cancel_if.is_valid() and bool(_cancel_if.call()):
		stop()
		return Outcome.CALLED_OFF
	if not has_run(clock):
		return Outcome.RUNNING
	stop()
	if _on_expired.is_valid():
		_on_expired.call()
	return Outcome.RAN_OUT
