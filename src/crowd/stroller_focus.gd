class_name StrollerFocus
extends CrowdFocus
## The game's focus source for the crowd (`CrowdFocus`): the patch of simulated streets stands where
## she does, so the crowd is simulated around the pram she pushes and recycles what falls out of
## its box behind her.

var _player: Stroller

func _init(player: Stroller) -> void:
	_player = player

## Overrides CrowdFocus.where.
func where() -> Vector2:
	return _player.global_position
