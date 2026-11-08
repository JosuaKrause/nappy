class_name UnusedCalmRule
extends StreetRule
## **No field reaches the calm ground she has not used yet** (`CalmAreas.unused_ground()`, handed in
## as the rects to leave alone; `EventScheduler._reaches_any()`), so an area she has not settled in
## is still one she can settle in. About the ground, never about what is on it, so it never bends.

var _leave_alone: Array[Rect2]

func _init(leave_alone: Array[Rect2]) -> void:
	_leave_alone = leave_alone

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> bool:
	return not EventScheduler._reaches_any(candidate, _leave_alone)
