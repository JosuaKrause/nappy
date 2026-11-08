class_name DoorClearanceRule
extends StreetRule
## **Nothing's field or beat comes within `Tuning.CHECKPOINT_EVENT_GAP` of a region door**, on either
## side, so the ground she is let out onto is ground she can read before anything charges her
## (`EventScheduler._clear_of_the_doors()`). The doors are planned before anything is drawn.

var _doors: PackedVector2Array

func _init(doors: PackedVector2Array) -> void:
	_doors = doors

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> bool:
	return EventScheduler._clear_of_the_doors(candidate.position, candidate.path, _doors,
			candidate.def.field_reach())
