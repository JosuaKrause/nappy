class_name Warning
extends RefCounted
## **One warning: a clock that starts, may be held, and ends by being called off or by running
## out.** Every warning in the game is this clock, read against the caller's own: an event's notice
## (a charger's warning inside its one radius, a pursuer's approach, a man standing with his hand
## raised), a crossing of a district door's line (`CheckpointController`), and the screen-edge badge
## up alone before a thing exists (`PendingWarning`).
##
## **The caller owns the clock it is read against** — an event's age, the badge's own time up —
## so a warning carried across a stream-out is its start on that clock (`started_at()`), and a
## warning never drifts from the clock beside it. What calls it off and what it runs out into
## are the caller's, which asks it each tick whether it has run (`has_run()`) and stops it.

## Seconds it runs for, on the caller's clock, once started; `INF` for one that only ends by being
## called off or stopped by hand.
var _length := INF

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
