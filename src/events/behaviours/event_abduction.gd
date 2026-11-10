class_name EventAbduction
extends EventBehaviour
## **The unmarked van takes somebody first**, on the terms its row's `AbductionSpec` sets: the first
## time she comes close enough to see it, a bystander is walked to the van and taken. Drawing and
## telemetry only — nothing here reaches into the crowd, and nothing here changes the van's field.

## Its row: whether its van hunts, how long it lasts, what the run log calls it.
var _row: EventDef
## The take's own settings: how long the walk to the van takes.
var _spec: AbductionSpec
## Where its event writes its own account for the run log (`EventInstance.trace`).
var _trace: RunTrace

## The event's age the take began at, or `INF` before it has and after a hunting van abandons one
## mid-walk.
var _taken_at := INF
## Whether the one run-log line for this take has been written.
var _logged := false

## Handed, as its event is set up, the figure it moves, where she is, its row, its take's settings
## and where its one run-log line goes.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef,
		spec: AbductionSpec, trace: RunTrace) -> void:
	_figure = figure
	_where = where
	_row = row
	_spec = spec
	_trace = trace

## Whether the walk is running right now.
func is_taking() -> bool:
	return _taken_at != INF and (_figure.age() - _taken_at) < _spec.taken_over

## How far into the walk it is, in seconds, while it runs.
func walked_for() -> float:
	return _figure.age() - _taken_at

## Stops the walk, for a rig that drives the scene by hand.
func stop() -> void:
	_taken_at = INF

## **Begins the first time she can see it happen**, where the van's field reaches her
## (`EventInstance.Figure.field_reaches()`, within its `outer_radius`): a van she never came near
## never runs it. **Never starts without enough of the van's life left to finish in**: a take cut
## short by the van disappearing mid-walk would read as a bug. **A hunting van has other
## business**: the instant it stops waiting it is letting its men out after her, so a take in
## progress is abandoned — no victim is drawn again and nothing is logged.
##
## Overrides EventBehaviour.step.
func step(_delta: float) -> void:
	if (_row.pursuit != null or _row.investigates()) and not _figure.is_waiting():
		_taken_at = INF
		return
	if _taken_at == INF:
		if _where.at() == Vector2.INF or not _figure.field_reaches(_where.at()) \
				or _time_left() < _spec.taken_over:
			return
		_taken_at = _figure.age()
		return
	if _logged or _figure.age() - _taken_at < _spec.taken_over:
		return
	_logged = true
	_trace.note("taken", "'%s' takes a bystander" % _row.id)

## How long the van has before it is simply gone, or `INF` where the question does not yet apply:
## a row still waiting has no expiry of its own.
func _time_left() -> float:
	if _figure.is_waiting() or _row.duration <= 0.0:
		return INF
	return (_figure.notice_time() + _row.duration) - _figure.chase_age()

## The take's start as seconds before the event's age (`INF` for none), and whether it was logged.
##
## Overrides EventBehaviour.save.
func save() -> Dictionary:
	return {"taken_ago": _figure.age() - _taken_at if _taken_at != INF else INF,
			"logged": _logged}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	var ago := float(state.get("taken_ago", INF))
	_taken_at = _figure.age() - ago if ago != INF else INF
	_logged = bool(state.get("logged", false))
