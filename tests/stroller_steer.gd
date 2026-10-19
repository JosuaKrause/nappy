extends RefCounted
## Runs a rig's own `_physics_process` for the velocity it computes and leaves her body where it
## stood, for the suites that make the displacement themselves (`move_and_collide()`, or the
## velocity added by hand).
##
## `_physics_process` ends in `move_and_slide()`, which moves her by the engine's physics delta:
## 1/30 s once a physics frame has run, which the runner lets pass before the first suite, so the
## call would move her once and the suite's own displacement a second time.

static func velocity_step(player: CharacterBody2D, tick: float) -> void:
	var before := player.global_position
	player._physics_process(tick)
	player.global_position = before
