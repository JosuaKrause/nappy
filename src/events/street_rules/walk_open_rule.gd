class_name WalkOpenRule
extends StreetRule
## **Each street of the escape's walk keeps a sidewalk open, and the walk stays joined from where she
## starts to each exit**, past every body standing on it (`WalkGround`, inbox #747): the escape's rule
## (`DaySpec.keeps_the_walk_open`). The walk's ground learns what the walk has placed before it is
## asked (`WalkGround.catch_up()`), so a candidate is asked against everything already down.

var _walk: WalkGround

func _init(walk: WalkGround) -> void:
	_walk = walk

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	_walk.catch_up(placed)
	return _walk.accepts(candidate)
