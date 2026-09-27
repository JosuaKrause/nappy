extends Stroller
## A test double for the one thing a headless suite cannot otherwise see: whether a real
## `NOTIFICATION_RESET_PHYSICS_INTERPOLATION` reached this node while it was hidden or while it
## was visible. Godot delivers the notification either way, but only honours the reset itself —
## collapsing the interpolated pair the renderer blends between — when the node is visible at the
## time; a reset made while hidden is delivered and silently does nothing. That difference has no
## other hook a script can read, so `tests/test_checkpoints.gd` swaps this script onto a real
## `Stroller` (`set_script()`, after the scene's own has built its children) to read it back.
##
## `Stroller.teleport_to()` calls `reset_physics_interpolation()` while she is still hidden
## (`_release_finished_door_detentions()` calls it before `show_after_inspection()`); that call
## reaches here as `reset_seen_while_hidden`, never as the one that actually clears the stale pair
## a hold leaves behind — see `Stroller.show_after_inspection()`'s own doc for what that pair is
## and why it survives a hidden reset.
var reset_seen_while_visible := false
var reset_seen_while_hidden := false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
		if visible:
			reset_seen_while_visible = true
		else:
			reset_seen_while_hidden = true
