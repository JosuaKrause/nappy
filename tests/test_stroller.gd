extends RefCounted
## Direction quantisation for the player rig, including its boundary hold.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_all_eight_facings(t)
	_test_live_draw_selection(t)
	_test_pram_scale_preserves_integer_canvas_sizes(t)
	_test_boundary_hysteresis(t)
	_test_reset_settles_direction(t)
	_test_wrap_boundary_holds(t)
	_test_pram_offset_stays_continuous_through_side_facings(t)
	_test_the_pram_has_its_own_trailing_body(t)

func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

func _face(rig: Stroller, degrees: float) -> void:
	rig.facing = Vector2.from_angle(deg_to_rad(degrees))
	rig._update_view()

func _test_all_eight_facings(t) -> void:
	var rig := _rig(t)
	for direction in range(8):
		_face(rig, direction * 45.0)
		t.check(rig._view_direction == direction, "facing %d degrees selects direction %d" % [direction * 45, direction])
	rig.free()

func _test_live_draw_selection(t) -> void:
	var rig := _rig(t)
	var mother_first_frames: Array[Texture2D] = [
		Stroller.MOTHER_SIDE[0], Stroller.MOTHER_FRONT_DIAGONAL[0], Stroller.MOTHER_FRONT[0],
		Stroller.MOTHER_FRONT_DIAGONAL[0], Stroller.MOTHER_SIDE[0],
		Stroller.MOTHER_BACK_DIAGONAL[0], Stroller.MOTHER_BACK[0],
		Stroller.MOTHER_BACK_DIAGONAL[0],
	]
	var mother_second_frames: Array[Texture2D] = [
		Stroller.MOTHER_SIDE[1], Stroller.MOTHER_FRONT_DIAGONAL[1], Stroller.MOTHER_FRONT[1],
		Stroller.MOTHER_FRONT_DIAGONAL[1], Stroller.MOTHER_SIDE[1],
		Stroller.MOTHER_BACK_DIAGONAL[1], Stroller.MOTHER_BACK[1],
		Stroller.MOTHER_BACK_DIAGONAL[1],
	]
	var pram_textures: Array[Texture2D] = [
		Stroller.PRAM_SIDE, Stroller.PRAM_FRONT_DIAGONAL, Stroller.PRAM_FRONT,
		Stroller.PRAM_FRONT_DIAGONAL, Stroller.PRAM_SIDE, Stroller.PRAM_BACK_DIAGONAL,
		Stroller.PRAM_BACK, Stroller.PRAM_BACK_DIAGONAL,
	]
	var mirrored: Array[bool] = [false, false, false, true, true, true, false, false]
	for direction in range(8):
		rig._view_direction = direction
		t.check(rig._mother_texture(0) == mother_first_frames[direction],
				"mother draw selects the authored texture for direction %d" % direction)
		t.check(rig._mother_texture(1) == mother_second_frames[direction],
				"mother draw selects gait frame B for direction %d" % direction)
		t.check(rig._pram_texture() == pram_textures[direction],
				"pram draw selects the authored texture for direction %d" % direction)
		t.check(rig._mother_is_mirrored() == mirrored[direction],
				"mother mirror matches direction %d" % direction)
		t.check(rig._pram_is_mirrored() == mirrored[direction],
				"pram mirror matches direction %d" % direction)
	rig.free()

func _test_pram_scale_preserves_integer_canvas_sizes(t) -> void:
	var rig := _rig(t)
	for direction in range(8):
		rig._view_direction = direction
		var native_size := rig._pram_texture().get_size()
		var draw_size := rig._pram_draw_size()
		t.check(is_equal_approx(draw_size.x * native_size.y, draw_size.y * native_size.x),
				"direction %d preserves the authored pram aspect ratio" % direction)
		t.check(draw_size.x == roundf(draw_size.x) and draw_size.y == roundf(draw_size.y),
				"direction %d keeps the scaled pram on an integer-pixel canvas" % direction)
	rig.free()

func _test_boundary_hysteresis(t) -> void:
	var rig := _rig(t)
	_face(rig, 0.0)
	_face(rig, 26.0)
	t.check(rig._view_direction == 0, "five degree hold keeps east just past the 22.5 degree boundary")
	_face(rig, 28.0)
	t.check(rig._view_direction == 1, "east changes to southeast after the hysteresis margin")
	_face(rig, 24.0)
	t.check(rig._view_direction == 1, "southeast holds while turning back inside the margin")
	_face(rig, 16.0)
	t.check(rig._view_direction == 0, "southeast returns to east below the margin")
	rig.free()

func _test_reset_settles_direction(t) -> void:
	var rig := _rig(t)
	_face(rig, 0.0)
	rig.reset_at(Vector2.ZERO)
	t.check(rig._view_direction == 2, "default reset look settles south")
	rig.reset_at(Vector2.ZERO, Vector2.LEFT)
	t.check(rig._view_direction == 4, "explicit reset look settles west")
	rig.reset_at(Vector2.ZERO, Vector2.from_angle(deg_to_rad(66.0)))
	t.check(rig._view_direction == 1, "reset at 66 degrees chooses southeast without prior-view hold")
	rig.reset_at(Vector2.ZERO, Vector2.from_angle(deg_to_rad(114.0)))
	t.check(rig._view_direction == 3, "reset at 114 degrees chooses southwest without prior-view hold")
	rig.free()

func _test_wrap_boundary_holds(t) -> void:
	var rig := _rig(t)
	_face(rig, 330.0)
	_face(rig, 340.0)
	t.check(rig._view_direction == 7, "north-east holds through the zero degree wrap")
	_face(rig, 345.0)
	t.check(rig._view_direction == 0, "east wins after crossing the wrapped boundary")
	rig.free()

func _test_pram_offset_stays_continuous_through_side_facings(t) -> void:
	var rig := _rig(t)
	var epsilon := 0.001
	var largest_axis_distance: float = maxf(
			Stroller.PRAM_HORIZONTAL_DISTANCE,
			maxf(Stroller.PRAM_NORTH_DISTANCE, Stroller.PRAM_SOUTH_DISTANCE))
	for side: float in [0.0, PI]:
		rig.facing = Vector2.from_angle(side - epsilon)
		var before := rig.pram_draw_offset()
		rig.facing = Vector2.from_angle(side)
		var at_side := rig.pram_draw_offset()
		rig.facing = Vector2.from_angle(side + epsilon)
		var after := rig.pram_draw_offset()
		# A one-sided distance choice is safe only because its directional term has reached zero
		# here. Bound the movement by the turn itself, so this checks for a jump without pinning the
		# presentation distances selected by visual review.
		t.check(before.distance_to(at_side) <= largest_axis_distance * epsilon,
				"the pram reaches side facing continuously from one turn direction")
		t.check(after.distance_to(at_side) <= largest_axis_distance * epsilon,
				"the pram leaves side facing continuously in the other turn direction")
	rig.free()

## The pram's physical body and visible position are separate contracts. The body stays on the
## circumference of her own circle, unsquashed in the ground plane, while its art, shadow, cue and
## field follow the authored presentation offset. Checked at the wiring level because no physics
## frame elapses during this suite's synchronous `run()`, so `move_and_slide()` cannot demonstrate a
## wall collision here.
func _test_the_pram_has_its_own_trailing_body(t) -> void:
	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var rig: Stroller = scene.instantiate()
	t.add_child(rig)
	rig.set_physics_process(false)

	var pram_collision := rig.get_node_or_null("PramCollisionShape2D") as CollisionShape2D
	t.check(pram_collision != null,
			"the real stroller scene carries a second collision shape for the pram")
	var circle := pram_collision.shape as CircleShape2D
	t.check(circle != null and is_equal_approx(circle.radius, Stroller.PRAM_BODY_RADIUS),
			("sized to PRAM_BODY_RADIUS, smaller than the 12px pram_shape still draws the shadow "
			+ "with (%.1f in the scene, %.1f pinned)")
			% [circle.radius if circle else -1.0, Stroller.PRAM_BODY_RADIUS])
	t.check(not pram_collision.disabled, "and enabled while she is pushing the pram")

	# On the circumference of her own circle, whichever way she is facing, never at the pram's own
	# drawn distance. No input is pressed, so `_turn_toward()` never runs and `facing` stays exactly
	# what this sets before each step.
	for facing: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT,
			Vector2(1.0, 1.0).normalized()]:
		rig.facing = facing
		rig._physics_process(STEP)
		var visible_offset: Vector2 = rig.pram_draw_offset()
		t.check(rig._pram_offset.is_equal_approx(visible_offset),
				"the drawn pram, shadow and cue share one live offset on facing %s" % facing)
		var expected: Vector2 = facing * Tuning.PLAYER_BODY_RADIUS
		t.check(pram_collision.position.is_equal_approx(expected),
				"the pram's own body sits PLAYER_BODY_RADIUS out along facing %s (%s, want %s)"
				% [facing, pram_collision.position, expected])
		t.close_to(pram_collision.position.length(), Tuning.PLAYER_BODY_RADIUS,
				"which is 14px from her own centre on every facing, not only the axes", 0.01)
		t.check(not pram_collision.position.is_equal_approx(visible_offset),
				"and changing the visible hand-to-handle placement does not move that body")
	rig.free()

	# Carrying her in arms rather than pushing the pram: there is no pram to collide with either.
	var carrying_rig: Stroller = scene.instantiate()
	carrying_rig.carrying = true
	t.add_child(carrying_rig)
	var carrying_collision := carrying_rig.get_node("PramCollisionShape2D") as CollisionShape2D
	t.check(carrying_collision.disabled, "and disabled for the carrying rig, which has no pram")
	carrying_rig.free()
