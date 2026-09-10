extends RefCounted
## Direction quantisation for the player rig, including its boundary hold.

func run(t) -> void:
	_test_all_eight_facings(t)
	_test_live_draw_selection(t)
	_test_boundary_hysteresis(t)
	_test_reset_settles_direction(t)
	_test_wrap_boundary_holds(t)

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
