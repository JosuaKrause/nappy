extends RefCounted
## `TapControls`' own geometry and its wiring to a rig — the parts a screenshot cannot check: that
## the pressed direction matches the tap's own unit vector, that arrival is the plane and not a
## radius, and that a double tap needs both its windows before it reads as a modifier rather than
## a new destination.

func run(t) -> void:
	_test_has_arrived_is_the_plane_not_a_radius(t)
	_test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t)
	_test_is_double_tap_needs_both_windows(t)
	_test_walk_to_presses_the_components_of_the_heading(t)
	_test_a_tap_on_herself_presses_nothing(t)
	_test_arriving_releases_every_action_it_held(t)
	_test_a_shove_past_the_plane_still_arrives(t)
	_release_actions()

func _rig_at(position: Vector2) -> Node2D:
	var rig := Node2D.new()
	rig.global_position = position
	rig.add_to_group("player")
	return rig

func _test_has_arrived_is_the_plane_not_a_radius(t) -> void:
	var direction := Vector2.RIGHT
	t.check(not TapControls.has_arrived(Vector2(100.0, 0.0), Vector2(50.0, 0.0), direction),
			"short of the target has not arrived")
	t.check(TapControls.has_arrived(Vector2(100.0, 0.0), Vector2(100.0, 0.0), direction),
			"exactly on the plane through the target has arrived")
	t.check(TapControls.has_arrived(Vector2(100.0, 0.0), Vector2(140.0, 0.0), direction),
			"past the target, on the far side of the plane, has still arrived")
	t.check(not TapControls.has_arrived(Vector2(100.0, 0.0), Vector2(60.0, 500.0), direction),
			"level with the plane but nowhere near the line has not crossed it either")

func _test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t) -> void:
	var direction := TapControls.heading_to(Vector2(0.0, 100.0), Vector2.ZERO)
	t.close_to(direction.length(), 1.0, "the heading is a unit vector")
	t.check(direction.is_equal_approx(Vector2.DOWN), "pointing straight at the target")
	t.check(TapControls.heading_to(Vector2(10.0, 10.0), Vector2(10.0, 10.0)) == Vector2.ZERO,
			"a tap on her own position has no line to walk")

func _test_is_double_tap_needs_both_windows(t) -> void:
	t.check(TapControls.is_double_tap(0.1, 10.0), "soon and close reads as a double tap")
	t.check(not TapControls.is_double_tap(1.0, 10.0), "close but late is a new single tap")
	t.check(not TapControls.is_double_tap(0.1, 400.0),
			"soon but far away is a new destination, not a modifier on the old one")

func _test_walk_to_presses_the_components_of_the_heading(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(100.0, -100.0), false)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up"),
			"a diagonal tap presses both components of its own unit vector")
	t.check(not Input.is_action_pressed("run"), "a single tap does not hold run")

	tap.walk_to(Vector2(-100.0, -100.0), true)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a new tap the other way releases the axis it no longer wants")
	t.check(Input.is_action_pressed("run"), "a double tap holds run")

	tap.free()
	rig.free()

func _test_a_tap_on_herself_presses_nothing(t) -> void:
	# Leftover state from the previous test's own double tap, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(Vector2(50.0, 50.0))
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(50.0, 50.0), false)
	t.check(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"nowhere to walk presses nothing")

	tap.free()
	rig.free()

func _test_arriving_releases_every_action_it_held(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds the direction and, on a double tap, run")

	rig.global_position = Vector2(100.0, 0.0)
	tap._process(0.016)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"arriving lets go of the direction and the run key together")

	tap.free()
	rig.free()

func _test_a_shove_past_the_plane_still_arrives(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(100.0, 0.0), false)
	# A shove sideways and past the target's own plane -- not the line she was aimed along at all.
	rig.global_position = Vector2(140.0, 60.0)
	tap._process(0.016)
	t.check(not Input.is_action_pressed("move_right"),
			"knocked past the plane by a shove still reads as arrived, not stuck pressing forever")

	tap.free()
	rig.free()

func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
