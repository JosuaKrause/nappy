class_name EventAbduction
extends EventBehaviour
## **The unmarked van takes somebody first**, on the terms its row's `AbductionSpec` sets: the first
## time she comes close enough to see it, a bystander is walked to the van and taken. Drawing and
## telemetry only — nothing here reaches into the crowd, and nothing here changes the van's field.

## The event's age the take began at, or `INF` before it has and after a hunting van abandons one
## mid-walk.
var _taken_at := INF
## Whether the one run-log line for this take has been written.
var _logged := false

## Whether the walk is running right now.
func is_taking() -> bool:
	return _taken_at != INF and (event.age - _taken_at) < event.def.abduction.taken_over

## How far into the walk it is, in seconds, while it runs.
func walked_for() -> float:
	return event.age - _taken_at

## Starts the walk now, for a rig that drives the scene by hand.
func take_now() -> void:
	_taken_at = event.age

## Stops the walk, for a rig that drives the scene by hand.
func stop() -> void:
	_taken_at = INF

## **Begins the first time she can see it happen**, within the van's `outer_radius`: a van she
## never came near never runs it. **Never starts without enough of the van's life left to finish
## in**: a take cut short by the van disappearing mid-walk would read as a bug. **A hunting van has
## other business**: the instant it stops waiting it is letting its men out after her, so a take in
## progress is abandoned — no victim is drawn again and nothing is logged.
func step(_delta: float) -> void:
	var def: EventDef = event.def
	if (def.pursuit != null or def.investigates) and not event.is_waiting():
		_taken_at = INF
		return
	if _taken_at == INF:
		if event.player_at == Vector2.INF \
				or event.global_position.distance_to(event.player_at) > def.outer_radius \
				or _time_left() < def.abduction.taken_over:
			return
		_taken_at = event.age
		return
	if _logged or event.age - _taken_at < def.abduction.taken_over:
		return
	_logged = true
	event.trace.note("taken", "'%s' takes a bystander" % def.id)

## How long the van has before it is simply gone, or `INF` where the question does not yet apply:
## a row still waiting has no expiry of its own.
func _time_left() -> float:
	if event.is_waiting() or event.def.duration <= 0.0:
		return INF
	return (event.notice_time() + event.def.duration) - event.chase_age()

## The take's start as seconds before the event's age (`INF` for none), and whether it was logged.
func save() -> Dictionary:
	return {"taken_ago": event.age - _taken_at if _taken_at != INF else INF, "logged": _logged}

func restore(state: Dictionary) -> void:
	var ago := float(state.get("taken_ago", INF))
	_taken_at = event.age - ago if ago != INF else INF
	_logged = bool(state.get("logged", false))
