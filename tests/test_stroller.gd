extends RefCounted
## Focused contracts for the live Stroller owner and its modular presentation child.

func run(t) -> void:
	_test_default_facing_has_live_compositor(t)
	_test_reset_selects_requested_visual_heading(t)

func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

func _test_default_facing_has_live_compositor(t) -> void:
	var rig := _rig(t)
	rig.reset_at(Vector2(80.0, 120.0))
	var compositor: ModularPerson = rig.get_node("ModularPerson")
	t.check(rig.facing == Vector2.DOWN, "reset keeps the default south-facing owner heading")
	t.check(compositor.direction == DirectionalParts.Direction.S,
		"default reset selects the matching south modular view")
	t.check(compositor.global_position == rig.global_position,
		"reset places the live compositor on the owner")
	rig.free()

func _test_reset_selects_requested_visual_heading(t) -> void:
	var rig := _rig(t)
	var headings: Array[Vector2] = [
		Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT,
		Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0), Vector2(-1.0, -1.0),
	]
	var expected: Array[int] = [
		DirectionalParts.Direction.N, DirectionalParts.Direction.E,
		DirectionalParts.Direction.S, DirectionalParts.Direction.W,
		DirectionalParts.Direction.NE, DirectionalParts.Direction.SE,
		DirectionalParts.Direction.SW, DirectionalParts.Direction.NW,
	]
	for index: int in headings.size():
		rig.reset_at(Vector2(30.0 + index * 11.0, 60.0), headings[index])
		var compositor: ModularPerson = rig.get_node("ModularPerson")
		t.check(compositor.direction == expected[index],
			"reset selects the requested eight-direction modular view (%s)" % DirectionalParts.direction_name(expected[index]))
		t.check(compositor.global_position == rig.global_position,
			"reset keeps the compositor aligned for heading %d" % index)
	rig.free()
