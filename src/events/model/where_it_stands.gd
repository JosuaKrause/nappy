class_name WhereItStands
extends RefCounted
## **Where a plan's live event stands now, as the plan can ask it**: whether it is in the world,
## where it is, which way it faces and whether it is over. The plan answers those questions for its
## live event without naming it (`EventPlan.is_in_the_world()`, `where_it_stands_now()`,
## `faces_now()`, `its_event_is_gone()`), and the manager hands the live event itself only to a
## caller that commands it (`EventManager.event_of()`). The base's own answers are nowhere's, the
## plan's before its event enters the world and after it has left; the live event's own
## implementation answers for it (`EventInstance.standing()`).

## The handle of a plan whose event is not in the world: it stands nowhere.
static func nowhere() -> WhereItStands:
	return WhereItStands.new()

## Whether there is a live event to ask: false for nowhere, and once the event has been freed.
func is_there() -> bool:
	return false

## Where the live event stands, `Vector2.INF` for nowhere.
func at() -> Vector2:
	return Vector2.INF

## Which way the live event faces now, `Vector2.ZERO` for nowhere.
func facing() -> Vector2:
	return Vector2.ZERO

## Whether the live event is over and gone, false for nowhere.
func is_gone() -> bool:
	return false

## Whether the live event's field reaches `point`, false for nowhere, where no field stands.
func field_reaches(_point: Vector2) -> bool:
	return false
