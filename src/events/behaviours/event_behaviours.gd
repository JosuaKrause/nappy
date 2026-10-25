class_name EventBehaviours
extends RefCounted
## **Which behaviours a catalogue row's event is composed of, read off the row's data**, and the
## order they tick in. One place, so a row's behaviour is its data and no event type has a class.

## The behaviours an event of `row` is made of, attached to `event`, in the order `step()` runs
## them each tick. `event`'s typed fields (`hold`, `flock`, ...) are set to the same objects, so
## the event can answer for each.
##
## **The order is load-bearing**: a flock's birds move before its flush can put them up, a
## pursuer's chase runs before its man's stop is looked for, and a row that runs nothing else walks
## its route. A vehicle that investigates is never also a pursuer (`EventDef.validate()`).
static func compose(event: EventInstance, row: EventDef) -> Array[EventBehaviour]:
	var out: Array[EventBehaviour] = []
	event.departure = EventDeparture.new()
	_add(out, event, event.departure)
	if row.mobile:
		event.route = EventRouteWalk.new()
		event.route.attach(event)
	if row.vehicle:
		event.car = EventCarDriving.new()
		_add(out, event, event.car)
	if row.flock_size > 0:
		event.flock = EventFlock.new()
		_add(out, event, event.flock)
	if row.investigates:
		event.investigation = EventInvestigation.new()
		_add(out, event, event.investigation)
	if row.pursuit != null:
		event.pursuit = EventPursuit.new()
		_add(out, event, event.pursuit)
		event.on_foot = EventOfficer.new()
		_add(out, event, event.on_foot)
	if row.notice != null and row.pursuit == null and not row.investigates:
		event.notice_run = EventNoticeRun.new()
		_add(out, event, event.notice_run)
	if row.mobile and not row.investigates and row.pursuit == null and row.notice == null:
		_add(out, event, event.route)
	if row.detain_seconds > 0.0:
		event.hold = EventHold.new()
		_add(out, event, event.hold)
	if row.comes_down_her_line() and not row.telegraphs:
		event.unreachable = EventUnreachable.new()
		_add(out, event, event.unreachable)
	if row.look == EventDef.Look.UNMARKED_VAN:
		event.abduction = EventAbduction.new()
		_add(out, event, event.abduction)
	return out

static func _add(out: Array[EventBehaviour], event: EventInstance, behaviour: EventBehaviour) -> void:
	behaviour.attach(event)
	out.append(behaviour)
