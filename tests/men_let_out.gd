class_name MenLetOut
extends RefCounted
## The men an investigating vehicle has let out, read off the world: the instances standing in the
## manager's list whose officer behaviour names the vehicle (`EventOfficer.vehicle`, set when the
## manager puts a man down at its door), in the order the list holds them. A suite asks it of the
## manager the way the game's own classes find them, rather than of the vehicle, which keeps no
## public list of its men that anything but a test would read.

## Every man `vehicle` let out who is still in the world.
static func of(events: EventManager, vehicle: EventInstance) -> Array[EventInstance]:
	var men: Array[EventInstance] = []
	for instance in events.instances():
		if instance.on_foot != null and instance.on_foot.vehicle == vehicle:
			men.append(instance)
	return men

## The first of them, or null.
static func first_of(events: EventManager, vehicle: EventInstance) -> EventInstance:
	var men := of(events, vehicle)
	return men[0] if not men.is_empty() else null
