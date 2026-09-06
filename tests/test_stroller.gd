extends RefCounted
## Focused contracts for the live Stroller owner. Illustrated presentation opt-in is tested by
## `test_presentation_mode.gd`; this suite keeps the baseline rig legacy-shaped.

func run(t) -> void:
	_test_default_facing_has_no_illustrated_compositor(t)

func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

func _test_default_facing_has_no_illustrated_compositor(t) -> void:
	var rig := _rig(t)
	rig.reset_at(Vector2(80.0, 120.0))
	t.check(rig.facing == Vector2.DOWN, "reset keeps the default south-facing owner heading")
	t.check(rig.get_node_or_null("ModularPerson") == null,
		"baseline reset leaves the illustrated compositor opt-in")
	rig.free()
