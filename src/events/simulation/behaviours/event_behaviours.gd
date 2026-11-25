class_name EventBehaviours
extends RefCounted
## **Which behaviours a catalogue row's event is composed of, read off the row's data**, and the
## order they tick in. One place, so a row's behaviour is its data and no event type has a class.
## `compose()` makes the value; the event that asked for it is handed it whole and asks it for
## the behaviour it answers for, so nothing writes a field of the event.

## Every behaviour of the event, in the order it ticks.
var _ticking: Array[EventBehaviour] = []
var _abduction: EventAbduction = null
var _barrier_post: EventBarrierPost = null
var _car: EventCarDriving = null
var _departure: EventDeparture = null
var _flock: EventFlock = null
var _hold: EventHold = null
var _investigation: EventInvestigation = null
var _notice_run: EventNoticeRun = null
var _on_foot: EventOfficer = null
var _pursuit: EventPursuit = null
var _route: EventRouteWalk = null

## The unmarked van's take of a bystander, null for a row that takes none.
func abduction() -> EventAbduction:
	return _abduction

## A barrier its guards stand at and walk out of, null for a row with no post.
func barrier_post() -> EventBarrierPost:
	return _barrier_post

## A car's driving, null for anything that does not drive.
func car() -> EventCarDriving:
	return _car

## Going away once it is over; every event has one.
func departure() -> EventDeparture:
	return _departure

## A flock's birds, null for a row that is not a flock.
func flock() -> EventFlock:
	return _flock

## A conversation or a door's hold, null for a row that detains no one.
func hold() -> EventHold:
	return _hold

## A vehicle that stops for her and lets men out, null for a row that does not.
func investigation() -> EventInvestigation:
	return _investigation

## The man on foot a pursuer sends, null for a row that does not pursue.
func on_foot() -> EventOfficer:
	return _on_foot

## Coming after her, null for a row that does not pursue.
func pursuit() -> EventPursuit:
	return _pursuit

## Following its route or pacing its beat, null for a row that does not move.
func route() -> EventRouteWalk:
	return _route

## The behaviours in the order `step()` runs them each tick.
func in_tick_order() -> Array[EventBehaviour]:
	return _ticking

## The behaviours an event of `row` is made of, in the order `step()` runs them each tick. Each is
## handed what never changes under it as it is made: the figure it moves (`figure`, the event's
## `EventInstance.Figure`), its settings (the row, or its part's settings class), where she is as
## the event hears it (`where`), the map, the navigator, what the event walks as (`mover`), where the
## event writes its account for the run log (`trace`), the lights a car of it stops at (`lights`,
## null where there are none), the event's move (`move`, which a car's
## driving checks) and the behaviours beside it it works with, where it needs them. The value it
## returns holds those behaviours, each answered by its own method (null for one the row is not
## composed of), and the whole list in tick order.
##
## **The order is load-bearing**: a flock's birds move before its flush can put them up, a
## pursuer's chase runs before its man's stop is looked for, a row a place set off runs its line,
## and a row that runs nothing else walks its route. A vehicle that investigates is never also a pursuer (`EventDef.validate()`).
static func compose(row: EventDef, where: WhereSheIs, figure: EventInstance.Figure,
		map: WorldMap, navigator: Navigator, mover: Mover, trace: RunTrace, lights: TrafficSignals,
		move: MoveProposal) -> EventBehaviours:
	var made := EventBehaviours.new()
	# The siblings another behaviour is handed are made first; each ticks in its own place below.
	var on_foot: EventOfficer = null
	if row.pursues():
		on_foot = EventOfficer.new(figure, where, row, row.pursuit(), navigator, mover)
	var barrier_post: EventBarrierPost = null
	if row.leaves_its_body():
		barrier_post = EventBarrierPost.new(figure, where, row, row.look(), map, navigator, mover)
	var route: EventRouteWalk = null
	if row.moves():
		route = EventRouteWalk.new(figure, where, row, row.route(), navigator, mover)
		made._route = route
	var investigation: EventInvestigation = null
	if row.investigates():
		investigation = EventInvestigation.new(figure, where, row, row.route(), map, route)
	var car: EventCarDriving = null
	if row.drives():
		car = EventCarDriving.new(figure, where, row, row.route(), map, route, investigation,
				move, lights)
	# The investigation stands its car for her once its men are back: made after it, since the car
	# is handed the investigation, the car is handed to it once it is made.
	if investigation != null and car != null:
		investigation.take_its_car(car)
	var out: Array[EventBehaviour] = []
	made._departure = EventDeparture.new(figure, where, row, row.route(), map, navigator, mover,
			barrier_post, on_foot)
	out.append(made._departure)
	# The man on foot walks back, and the barrier post's guard walks off, by the departure that is
	# handed them: made after them, it is handed to them once it is made.
	if on_foot != null:
		on_foot.take_its_departure(made._departure)
	if barrier_post != null:
		barrier_post.take_its_departure(made._departure)
	if car != null:
		made._car = car
		out.append(car)
	if row.is_a_flock():
		made._flock = EventFlock.new(figure, row.flock(), row.field())
		out.append(made._flock)
	if investigation != null:
		made._investigation = investigation
		out.append(investigation)
	if row.pursues():
		made._pursuit = EventPursuit.new(figure, where, row, row.pursuit(), navigator, mover, route,
				on_foot, barrier_post)
		out.append(made._pursuit)
		made._on_foot = on_foot
		out.append(on_foot)
	if barrier_post != null:
		made._barrier_post = barrier_post
		out.append(barrier_post)
	if row.waits_for_her() and not row.pursues() and not row.investigates():
		made._notice_run = EventNoticeRun.new(
				figure, where, row.route(), row.flock(), row.notice(), route)
		out.append(made._notice_run)
	# A row a place set off that runs a line (the masked man) runs it from its first tick; one that
	# stands where it went off (the escape city's explosion) only happens there.
	if row.is_set_off_by_a_place() and row.moves():
		out.append(EventSetOffRun.new(figure, route))
	elif row.moves() and not row.investigates() and not row.pursues() and not row.waits_for_her():
		out.append(route)
	if row.detains_her():
		made._hold = EventHold.new(figure, row.hold())
		out.append(made._hold)
	if row.comes_down_her_line() and not row.telegraphs_its_coming():
		out.append(EventUnreachable.new(figure, where))
	if row.takes_a_victim_by() != null:
		made._abduction = EventAbduction.new(figure, where, row, row.takes_a_victim_by(), trace)
		out.append(made._abduction)
	made._ticking = out
	return made
