class_name EventBehaviours
extends RefCounted
## **Which behaviours a catalogue row's event is composed of, read off the row's data**, and the
## order they tick in. One place, so a row's behaviour is its data and no event type has a class.

## The behaviours an event of `row` is made of, attached to `event`, in the order `step()` runs
## them each tick. `event`'s typed fields (`hold`, `flock`, ...) are set to the same objects, so
## the event can answer for each.
static func compose(event: EventInstance, row: EventDef) -> Array[EventBehaviour]:
	var out: Array[EventBehaviour] = []
	if row.flock_size > 0:
		event.flock = EventFlock.new()
		_add(out, event, event.flock)
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
