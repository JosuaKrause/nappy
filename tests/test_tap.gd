extends RefCounted
## `TapControls`' own geometry and its wiring to a rig — the parts a screenshot cannot check: that
## the pressed direction matches the tap's own unit vector, that arrival is the plane and not a
## radius, and that a double tap needs both its windows before it reads as a modifier rather than
## a new destination.

func run(t) -> void:
	# Several tests below toggle the tree's own pause, the same guard `test_touch.gd` takes for
	# the same reason: whatever this suite runs under must not be left paused for the next one.
	var was_paused: bool = t.get_tree().paused
	_test_has_arrived_is_the_plane_not_a_radius(t)
	_test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t)
	_test_is_double_tap_needs_both_windows(t)
	_test_walk_to_presses_the_components_of_the_heading(t)
	_test_a_tap_on_herself_presses_nothing(t)
	_test_arriving_releases_every_action_it_held(t)
	_test_a_shove_past_the_plane_still_arrives(t)
	_test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t)
	_test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t)
	_test_arriving_starts_a_clock_that_opens_tap_modes_own_pause(t)
	_test_a_tap_during_tap_modes_own_pause_still_sets_the_next_destination(t)
	_test_a_tap_during_an_unrelated_pause_does_nothing(t)
	_test_an_unrelated_pause_force_releases_a_held_direction(t)
	t.get_tree().paused = was_paused
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

## **The test a screenshot cannot be**: `_on_tap()`'s own reverse of the transform `DangerEdge` and
## `HomeArrow` already read forwards. Constructed from the viewport's own real
## `get_canvas_transform()` rather than an assumed identity, so this would still catch a camera
## offset or a rotation the way a hard-coded expectation would not.
func _test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	var world_target := Vector2(120.0, -40.0)
	var screen_position: Vector2 = tap.get_viewport().get_canvas_transform() * world_target
	tap._on_tap(screen_position, 0.0)
	t.check(tap._target.is_equal_approx(world_target),
			"a tap's own screen position maps back to the world position it was drawn from")

	tap.free()
	rig.free()

## The double-tap windows again, now through the real entry point rather than the pure function
## directly -- a close tap soon after runs, and either window failing on its own falls back to a
## fresh single tap.
func _test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	var transform: Transform2D = tap.get_viewport().get_canvas_transform()

	tap._on_tap(transform * Vector2(100.0, 0.0), 10.0)
	t.check(not Input.is_action_pressed("run"), "the first tap of a run only walks")

	tap._on_tap(transform * Vector2(100.0, 0.0), 10.2)
	t.check(Input.is_action_pressed("run"), "soon and on the same spot reads as a double tap")

	tap._on_tap(transform * Vector2(500.0, 500.0), 10.4)
	t.check(not Input.is_action_pressed("run"),
			"soon but far away is a new destination, not a double tap on the old one")

	tap._on_tap(transform * Vector2(500.0, 500.0), 12.0)
	t.check(not Input.is_action_pressed("run"), "close but late is also a new single tap")

	tap.free()
	rig.free()

## **Arriving starts the stand, not the pause** -- pausing on arrival itself would stutter the
## ordinary loop of arriving and tapping on. Only standing the whole of `ARRIVAL_PAUSE_AFTER` out
## raises tap mode's own pause.
func _test_arriving_starts_a_clock_that_opens_tap_modes_own_pause(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(10.0, 0.0), false)
	rig.global_position = Vector2(10.0, 0.0)
	tap._process(0.016)
	t.check(not tap._walking and not tap._own_pause,
			"arriving starts the stand, and the pause has not fired yet")

	tap._process(TapControls.ARRIVAL_PAUSE_AFTER)
	t.check(tap._own_pause, "standing the clock out the whole way opens tap mode's own pause")

	tap.free()
	rig.free()

## **A tap while tap mode's own pause is up both unpauses and sets the next destination** -- a tap
## is the only input this mode has, so the same tap that dismisses the pause is the one that says
## where to go next. Unpausing itself is `PauseScreen._unhandled_input()`'s own job, off the same
## raw touch event once it propagates past here unhandled -- not asserted in this suite, which has
## no `PauseScreen` to check it against.
func _test_a_tap_during_tap_modes_own_pause_still_sets_the_next_destination(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	tap._own_pause = true
	t.get_tree().paused = true

	tap._on_tap(tap.get_viewport().get_canvas_transform() * Vector2(50.0, 0.0), 0.0)
	t.check(Input.is_action_pressed("move_right"),
			"a tap during tap mode's own pause still sets a new destination")

	tap.free()
	rig.free()

## Paused for any other reason -- Esc, the day ending, the title -- a tap does nothing, the same as
## every one of those screens already leaving the stick's own controls drawing nothing.
func _test_a_tap_during_an_unrelated_pause_does_nothing(t) -> void:
	# Leftover state from the previous test's own tap, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	t.get_tree().paused = true

	tap._on_tap(tap.get_viewport().get_canvas_transform() * Vector2(50.0, 0.0), 0.0)
	t.check(not Input.is_action_pressed("move_right") and not tap._walking,
			"a tap during a pause tap mode did not raise itself does nothing at all")

	tap.free()
	rig.free()

## A direction left pressed into whatever comes next is the same leak
## `TouchControls._release_all()` already guards its own controls against on every kind of hiding.
func _test_an_unrelated_pause_force_releases_a_held_direction(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.walk_to(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds a direction and, on a double tap, run")

	t.get_tree().paused = true
	tap._process(0.016)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"Esc or any other pause force-releases whatever tap mode was holding")
	t.check(not tap._walking, "and abandons the leg rather than merely pausing mid-stride")

	tap.free()
	rig.free()

func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
