class_name MenLetOut
extends RefCounted
## The men an investigating vehicle has let out, read off the world: the instances standing in the
## manager's list that lay a trail from a door of the vehicle (the first point of a man's trail is
## the door he was put down at, `EventOfficer.let_out_of()`, and the trail is carried in his saved
## state), in the order the list holds them. A suite asks it of the manager the way the game's own
## classes find them, rather than of the vehicle, which answers only how many men it still owes.

## Every man `vehicle` let out who is still in the world.
static func of(events: EventManager, vehicle: EventInstance) -> Array[EventInstance]:
	var men: Array[EventInstance] = []
	if not is_instance_valid(vehicle):
		return men
	for instance in events.instances():
		if instance != vehicle and instance.pursues() and _was_put_down_at_a_door_of(instance, vehicle):
			men.append(instance)
	return men

## The first of them, or null.
static func first_of(events: EventManager, vehicle: EventInstance) -> EventInstance:
	var men := of(events, vehicle)
	return men[0] if not men.is_empty() else null

## Whether the first point of `man`'s trail lies at a door of `vehicle`: within the reach
## `EventInstance.door_for_its_officer()` stands a man out from its middle, and the spacing along
## its flank two men are put down apart.
static func _was_put_down_at_a_door_of(man: EventInstance, vehicle: EventInstance) -> bool:
	var trail: PackedVector2Array = man.save().state_of("EventOfficer").get("trail",
			PackedVector2Array())
	if trail.is_empty() or vehicle.ground_shape() == null or man.ground_shape() == null:
		return false
	var out := vehicle.ground_shape().rounding_radius() + man.ground_shape().reach() + 1.0
	return trail[0].distance_to(vehicle.global_position) <= out + EventsAhead.OFFICER_SPACING
