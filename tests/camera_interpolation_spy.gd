extends Camera2D
## A test double for the camera-side half of the same bug `tests/stroller_interpolation_spy.gd`
## catches on the body: whether a real `NOTIFICATION_RESET_PHYSICS_INTERPOLATION` reached this
## `Camera2D` while it was visible *in the tree* — not while its own `visible` read `true`, which
## it does throughout a checkpoint's hold and says nothing about the question. The camera rides
## under `Stroller`, and `is_visible_in_tree()` walks the real parent chain regardless of
## `top_level`, which only decouples the camera's *transform* from hers — so a hidden `Stroller`
## makes this node exactly as hidden-in-tree as she is. See `Stroller._force_reset_camera_
## interpolation()`'s own doc for the mechanism this exists to prove.
##
## `tests/test_checkpoints.gd` swaps this script onto the real `Camera2D` child of a real
## `Stroller` scene (`set_script()`, before the scene ever enters the tree, the same reason
## `stroller_interpolation_spy.gd` swaps before `add_child()`), since `scenes/player/stroller.tscn`
## carries no script of its own on that node to lose.
var reset_seen_while_visible_in_tree := false
var reset_seen_while_hidden_in_tree := false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
		if is_visible_in_tree():
			reset_seen_while_visible_in_tree = true
		else:
			reset_seen_while_hidden_in_tree = true
