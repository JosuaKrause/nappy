class_name DoorClearanceRule
extends StreetRule
## **Nothing's field or beat comes within `Tuning.CHECKPOINT_EVENT_GAP` of a region door**, on either
## side, so the ground she is let out onto is ground she can read before anything charges her
## (`clear_of_the_doors()`). The doors are planned before anything is drawn.

var _doors: PackedVector2Array

func _init(doors: PackedVector2Array) -> void:
	_doors = doors

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> bool:
	return clear_of_the_doors(candidate.placed_at(), candidate.walks(), _doors,
			candidate.row().field_reach())

## Whether a placement keeps `Tuning.CHECKPOINT_EVENT_GAP` of clear ground around every one of
## today's region-door bodies — *"there should be a gap for events immediately surrounding the
## gates"*. `true` when there are no doors, which is every day before
## `Tuning.REGION_WALL_FIRST_DAY`.
##
## **The whole route, not the spot it starts at.** `path` is a mover's beat or its run, and a
## patrol that only *passes* a door through the gap is exactly what finished two of the attempts
## this rule comes from — so the distance is measured to the nearest point of the route, the same
## way `EventScheduler.Planned.distance_from()` does, and a stationary row is that route's single point.
##
## **The field, not the body.** `reach` is the candidate's own `EventDef.field_reach()`, so what is
## refused is a field arriving inside the gap rather than only a body standing in it: an event
## outside the gap whose radius reached across it would charge the ground she is let out onto
## without ever having stood in it.
##
## Shared with `EventDirector.due()`, which asks the same question of a path it is about to site in
## front of her, with the scheduler's masts and with the scene recipes. Public for that reason.
static func clear_of_the_doors(at: Vector2, path: PackedVector2Array,
		doors: PackedVector2Array, reach: float) -> bool:
	if doors.is_empty():
		return true
	var limit := Tuning.CHECKPOINT_EVENT_GAP + reach
	for door in doors:
		if _distance_to_route(door, at, path) < limit:
			return false
	return true

## Distance from `door` to the nearest part of a placement — its one position, or the nearest point
## of the route it travels. `EventScheduler.Planned.distance_from()`'s own arithmetic, stated over the two raw
## fields so the director can ask it about a path that has no `EventScheduler.Planned` yet.
static func _distance_to_route(door: Vector2, at: Vector2, path: PackedVector2Array) -> float:
	if path.size() < 2:
		return door.distance_to(at)
	var best := INF
	for i in range(1, path.size()):
		best = minf(best, door.distance_to(
				Geometry2D.get_closest_point_to_segment(door, path[i - 1], path[i])))
	return best
