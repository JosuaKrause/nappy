class_name UnusedCalmRule
extends StreetRule
## **No field reaches the calm ground she has not used yet** (`CalmAreas.unused_ground()`, handed in
## as the rects to leave alone; `_reaches_any()`), so an area she has not settled in
## is still one she can settle in. About the ground, never about what is on it, so it never bends.

var _leave_alone: Array[Rect2]

func _init(leave_alone: Array[Rect2]) -> void:
	_leave_alone = leave_alone

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	return not _reaches_any(candidate, _leave_alone)

## Whether a candidate's field would reach any of them.
static func _reaches_any(candidate: EventPlan, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if candidate.reaches(rect):
			return true
	return false
