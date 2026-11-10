class_name EventOfficer
extends EventBehaviour
## **A man on foot who may stop her and walk back**: every pursuer is composed of one. The man an
## investigating vehicle lets out lays a trail from its door while he chases and walks back along
## it to get in (`let_out_of()`); a man whose catch is a stop (`PursuitSpec.stop_excitement`) stands with
## her through it instead of ending the day. Neither applies to a pursuer nothing let out and whose
## catch ends the day; for him this does nothing.

## How far apart the points of a man's trail are, in px: a third of a tile, so a corner he went
## round is a corner on the way back.
const TRAIL_STEP := 10.0

## The vehicle that let this man out, or null for everything else — a torn poster's man included.
## **Not carried across a stream-out**: it is an instance of its own.
var vehicle: EventInstance = null
## The way he came, laid down every `TRAIL_STEP` px while he is out, from the door: walked back in
## reverse, it is ground he has already walked, so no building stands between him and his vehicle.
var trail := PackedVector2Array()
## The event's age at which he reached her and stopped her, or `INF`.
var _stopped_her_at := INF
## Its row: how near he has to come to catch her.
var _row: EventDef
## How he comes after her (`PursuitSpec`): whether his catch is a stop.
var _pursuit: PursuitSpec
## The ground he walks back over, and how he moves over it, as what he walks as.
var _navigator: Navigator
var _mover: Mover
## The departure his walk back is part of (`EventDeparture`), which puts him where each walk ends,
## held by a weak reference: the departure holds him to walk him back, so a strong one each way
## would be a reference cycle that is never freed. Handed once the departure is made
## (`take_its_departure()`).
var _departure: WeakRef = null

## Handed, as its event is set up, the figure he moves, where she is, his row, how he comes after
## her, and the ground and how he moves over it.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, pursuit: PursuitSpec,
		navigator: Navigator, mover: Mover) -> void:
	_figure = figure
	_where = where
	_row = row
	_pursuit = pursuit
	_navigator = navigator
	_mover = mover

## Handed the departure his walk back is part of, as his event is set up: it is made after him,
## since it is handed him too (`EventBehaviours.compose()`).
func take_its_departure(departure: EventDeparture) -> void:
	_departure = weakref(departure)

## Let out of `by` at the door he stands at, which is where he walks back to.
func let_out_of(by: EventInstance) -> void:
	vehicle = by
	trail = PackedVector2Array([_figure.place()])

## Whether he has reached her and stopped her.
func has_stopped_her() -> bool:
	return _stopped_her_at != INF

## How long ago he stopped her, in seconds of the event's age.
func stopped_for() -> float:
	return _figure.age() - _stopped_her_at

## While he is with her through his stop he stands, and walks back once it has run
## (`Tuning.OFFICER_STOP_SECONDS`).
func stand_with_her() -> void:
	if stopped_for() >= Tuning.OFFICER_STOP_SECONDS:
		_figure.be_done()

## After his chase's step (`EventPursuit`): **his catch, made a stop** — chasing, within his
## catch's own reach of her and along a clear line (`clear_line_to()`, the sight, which differs from a catch's strict line only for a body of his own, and his row has none) —
## and the next point of his trail; once he has stopped her, standing with her instead. **A man
## who would stop her waits outside a door's hold** (`WhereSheIs.is_held_at_a_door()`): a stop is a
## cost on the meter, and inside a hold nothing but the door's toll reaches her, so he keeps after
## her and stops her once she is let out. *Chosen while building, open to overturn.*
##
## Overrides EventBehaviour.step.
func step(_delta: float) -> void:
	if has_stopped_her():
		stand_with_her()
		return
	_stop_her_if_he_has_reached_her()
	_lay_the_trail()

func _stop_her_if_he_has_reached_her() -> void:
	var her: Vector2 = _where.at()
	if _pursuit.stop_excitement <= 0.0 or has_stopped_her() or her == Vector2.INF \
			or _where.is_held_at_a_door():
		return
	if _figure.is_gone() or _figure.is_on_its_way_out() or _figure.is_waiting() \
			or _figure.is_telegraphing():
		return
	if _figure.place().distance_to(her) > _row.lethal_reach() or not _figure.clear_line_to(her):
		return
	_stopped_her_at = _figure.age()
	_figure.stopped_her(vehicle if is_instance_valid(vehicle) else null)
	_figure.turn_to((her - _figure.place()).normalized())

func _lay_the_trail() -> void:
	if trail.is_empty():
		return
	if _figure.place().distance_to(trail[trail.size() - 1]) >= TRAIL_STEP:
		trail.append(_figure.place())

## Whether he has a trail to walk back along.
func walks_back() -> bool:
	return not trail.is_empty()

## **He walks back the way he came, and gets in**: toward the last point of his trail, dropping each
## point as he reaches it, and gone once he is at the door. Back along his own trail rather than
## straight at the vehicle, since a chase can take him round a corner the straight line would cut
## through a building; where something solid now stands across it, round it to the next point of
## the trail (`Navigator.path()`), and where nothing goes round, he gets in from there. True while he
## is still walking back.
func walk_back(step: float) -> bool:
	if not trail.is_empty():
		var back := trail.duplicate()
		back.reverse()
		var walked: Navigator.Walked = _navigator.walk(_figure.place(), back, step, _mover)
		var departure: EventDeparture = _departure.get_ref()
		departure.take_the_walk(walked)
		trail = walked.points
		trail.reverse()
		if walked.stopped:
			var round: PackedVector2Array = _navigator.path(_figure.place(),
					trail[trail.size() - 1], _mover)
			if round.is_empty():
				trail.clear()
			# The way round ends at the trail point itself; the rest goes on the trail's end,
			# nearest last, since the trail is walked from its end.
			for i in range(round.size() - 2, -1, -1):
				trail.append(round[i])
		if not trail.is_empty():
			return true
	_figure.begin(EventInstance.Phase.DONE)
	return false

## His trail and his stop (its start as seconds before the event's age), not his vehicle.
##
## Overrides EventBehaviour.save.
func save() -> Dictionary:
	return {"trail": trail,
			"stopped_ago": _figure.age() - _stopped_her_at if _stopped_her_at != INF else INF}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	trail = state.get("trail", PackedVector2Array())
	var ago := float(state.get("stopped_ago", INF))
	_stopped_her_at = _figure.age() - ago if ago != INF else INF
