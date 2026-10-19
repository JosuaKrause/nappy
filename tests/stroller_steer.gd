extends RefCounted
## Runs a rig's own `_physics_process` for the velocity it computes and leaves her body where it
## stood, for the suites that make the displacement themselves (`move_and_collide()`, or the
## velocity added by hand).
##
## `_physics_process` ends in `move_and_slide()`, which moves her itself; the caller's own
## displacement is then the only one. Putting the body back after the whole step also drops the
## crowd's shove (`move_and_collide(_shove * delta)` at the end of `Stroller._physics_process`)
## if a suite steps a crowd.

static func velocity_step(player: CharacterBody2D, tick: float) -> void:
	var before := player.global_position
	player._physics_process(tick)
	player.global_position = before
