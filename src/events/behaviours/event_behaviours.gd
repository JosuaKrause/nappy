class_name EventBehaviours
extends RefCounted
## **Which behaviours a catalogue row's event is composed of, read off the row's data**, and the
## order they tick in. One place, so a row's behaviour is its data and no event type has a class.

## The behaviours an event of `row` is made of, in the order `step()` runs them each tick. Each is
## handed what never changes under it as it is made: the figure it moves (`figure`, the event's
## `EventInstance.Figure`), its settings (the row, or its part's settings class), where she is as
## `event` hears it (`where`), the map, the navigator, what the event walks as (`mover`), where the
## event writes its account for the run log (`trace`) and the behaviours beside it it works with,
## where it needs them. The pursuit, the man on foot, the
## barrier post, the investigation and the car are attached to `event` instead
## (`EventBehaviour.attach()`). `event`'s typed fields (`hold`, `flock`, ...) are set to the same
## objects, so the event can answer for each.
##
## **The order is load-bearing**: a flock's birds move before its flush can put them up, a
## pursuer's chase runs before its man's stop is looked for, and a row that runs nothing else walks
## its route. A vehicle that investigates is never also a pursuer (`EventDef.validate()`).
static func compose(event: EventInstance, row: EventDef, where: WhereSheIs,
		figure: EventInstance.Figure, map: WorldMap, navigator: Navigator,
		mover: Mover, trace: RunTrace) -> Array[EventBehaviour]:
	# The siblings another behaviour is handed are made first; each ticks in its own place below.
	var on_foot: EventOfficer = null
	if row.pursuit != null:
		on_foot = EventOfficer.new()
	var barrier_post: EventBarrierPost = null
	if row.leaves_its_body():
		barrier_post = EventBarrierPost.new()
	var route: EventRouteWalk = null
	if row.mobile:
		route = EventRouteWalk.new(figure, row, navigator, mover)
		event.route = route
	var out: Array[EventBehaviour] = []
	event.departure = EventDeparture.new(figure, where, row, map, navigator, mover, barrier_post,
			on_foot)
	out.append(event.departure)
	if row.vehicle:
		event.car = EventCarDriving.new()
		_attach(out, event, where, event.car)
	if row.flock_size > 0:
		event.flock = EventFlock.new(figure, row)
		out.append(event.flock)
	if row.investigates():
		event.investigation = EventInvestigation.new()
		_attach(out, event, where, event.investigation)
	if row.pursuit != null:
		event.pursuit = EventPursuit.new()
		_attach(out, event, where, event.pursuit)
		event.on_foot = on_foot
		_attach(out, event, where, on_foot)
	if barrier_post != null:
		event.barrier_post = barrier_post
		_attach(out, event, where, barrier_post)
	if row.notice != null and row.pursuit == null and not row.investigates():
		event.notice_run = EventNoticeRun.new(figure, where, row, row.notice, route)
		out.append(event.notice_run)
	if row.mobile and not row.investigates() and row.pursuit == null and row.notice == null:
		out.append(route)
	if row.detain_seconds > 0.0:
		event.hold = EventHold.new(figure, row)
		out.append(event.hold)
	if row.comes_down_her_line() and not row.telegraphs:
		event.unreachable = EventUnreachable.new(figure, where)
		out.append(event.unreachable)
	if row.abduction != null:
		event.abduction = EventAbduction.new(figure, where, row, row.abduction, trace)
		out.append(event.abduction)
	return out

## Attaches a behaviour that still holds its event to `event`, and adds it to the tick's order.
static func _attach(out: Array[EventBehaviour], event: EventInstance, where: WhereSheIs,
		behaviour: EventBehaviour) -> void:
	behaviour.attach(event, where)
	out.append(behaviour)
