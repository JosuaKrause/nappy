class_name FakeCrowdFocus
extends CrowdFocus
## A stand-in for the crowd's focus source (`CrowdFocus`) that answers a point a check sets, handed to
## `Crowd.use_focus()` so a rig that ticks the crowd with `step()` (which has no player in it)
## moves the patch of simulated streets where the check wants it. A helper, not a suite: the runner
## loads only `test_*.gd`.

var _at: Vector2

func _init(at := Vector2.ZERO) -> void:
	_at = at

## Sets where the patch stands from the next ask on.
func move_to(at: Vector2) -> void:
	_at = at

## Overrides CrowdFocus.where.
func where() -> Vector2:
	return _at
