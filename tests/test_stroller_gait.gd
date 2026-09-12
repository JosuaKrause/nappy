extends RefCounted
## The carrying rig's full contact/passing loop and its distance-driven progression.

const QUARTER_CYCLE_DISTANCE := (TAU / 4.0) / 0.09

func run(t) -> void:
	_test_carrying_visits_contact_passing_contact_passing(t)
	_test_displacement_crosses_a_passing_boundary(t)
	_test_idle_holds_the_passing_pose(t)
	_test_pushing_keeps_its_two_frame_stride(t)
	_test_every_carrying_view_resolves_the_passing_texture(t)

func _rig() -> Stroller:
	var rig := Stroller.new()
	rig.carrying = true
	return rig

func _test_carrying_visits_contact_passing_contact_passing(t) -> void:
	var rig := _rig()
	var frames: Array[int] = []
	for _quarter in range(4):
		frames.append(rig._mother_gait_frame(1.0))
		rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE)
	t.check(frames == [0, 1, 2, 1], "one carrying cycle is A, C, B, C")
	t.check(is_zero_approx(rig._walk_phase), "the four displacement quarters wrap at one TAU")
	rig.free()

func _test_displacement_crosses_a_passing_boundary(t) -> void:
	var rig := _rig()
	rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE * 0.5)
	t.check(rig._mother_gait_frame(1.0) == 0,
			"half the first contact's travel still holds contact one")
	rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE * 0.5)
	t.check(rig._mother_gait_frame(1.0) == 1,
			"the second half of that traveled distance reaches the passing pose")
	rig.free()

func _test_idle_holds_the_passing_pose(t) -> void:
	var rig := _rig()
	for phase in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
		rig._walk_phase = phase
		t.check(rig._mother_gait_frame(0.0) == 1,
				"stopping from phase %.2f settles into the feet-together passing pose" % phase)
	rig.free()

func _test_pushing_keeps_its_two_frame_stride(t) -> void:
	var rig := _rig()
	rig.carrying = false
	rig._walk_phase = PI / 4.0
	t.check(rig._mother_gait_frame(1.0) == 1, "pushing still reaches its second frame")
	rig._walk_phase = 3.0 * PI / 4.0
	t.check(rig._mother_gait_frame(1.0) == 0, "pushing still returns to its first frame")
	rig.free()

func _test_every_carrying_view_resolves_the_passing_texture(t) -> void:
	var rig := _rig()
	var passing: Array[Texture2D] = [
		Stroller.MOTHER_CARRYING_SIDE[1],
		Stroller.MOTHER_CARRYING_FRONT_DIAGONAL[1],
		Stroller.MOTHER_CARRYING_FRONT[1],
		Stroller.MOTHER_CARRYING_FRONT_DIAGONAL[1],
		Stroller.MOTHER_CARRYING_SIDE[1],
		Stroller.MOTHER_CARRYING_BACK_DIAGONAL[1],
		Stroller.MOTHER_CARRYING_BACK[1],
		Stroller.MOTHER_CARRYING_BACK_DIAGONAL[1],
	]
	for direction in range(8):
		rig._view_direction = direction
		t.check(rig._mother_texture(1) == passing[direction],
				"direction %d resolves its carrying passing pose" % direction)
	rig.free()
