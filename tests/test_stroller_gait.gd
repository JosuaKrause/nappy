extends RefCounted
## The pushing and carrying rigs share a distance-driven contact/passing gait.

const QUARTER_CYCLE_DISTANCE := (TAU / 4.0) / 0.09

func run(t) -> void:
	_test_both_states_visit_contact_passing_contact_passing(t)
	_test_displacement_crosses_a_passing_boundary_in_both_states(t)
	_test_idle_holds_the_passing_pose_from_every_phase(t)
	_test_each_state_has_three_distinct_poses_per_view(t)
	_test_every_view_resolves_every_pose_in_both_states(t)

func _rig(carrying: bool) -> Stroller:
	var rig := Stroller.new()
	rig.carrying = carrying
	return rig

func _state_name(carrying: bool) -> String:
	return "carrying" if carrying else "pushing"

func _test_both_states_visit_contact_passing_contact_passing(t) -> void:
	for carrying in [false, true]:
		var rig := _rig(carrying)
		var frames: Array[int] = []
		for _quarter in range(4):
			frames.append(rig._mother_gait_frame(1.0))
			rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE)
		t.check(frames == [0, 1, 2, 1],
				"one %s cycle is A, C, B, C" % _state_name(carrying))
		t.check(is_zero_approx(rig._walk_phase),
				"the four %s displacement quarters wrap at one TAU" % _state_name(carrying))
		rig.free()

func _test_displacement_crosses_a_passing_boundary_in_both_states(t) -> void:
	for carrying in [false, true]:
		var rig := _rig(carrying)
		rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE * 0.5)
		t.check(rig._mother_gait_frame(1.0) == 0,
				"half the first %s contact's travel still holds A" % _state_name(carrying))
		rig._advance_walk_phase(QUARTER_CYCLE_DISTANCE * 0.5)
		t.check(rig._mother_gait_frame(1.0) == 1,
				"the completed %s quarter reaches passing C" % _state_name(carrying))
		rig.free()

func _test_idle_holds_the_passing_pose_from_every_phase(t) -> void:
	for carrying in [false, true]:
		var rig := _rig(carrying)
		for phase in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
			rig._walk_phase = phase
			t.check(rig._mother_gait_frame(0.0) == 1,
					"idle %s settles on C from phase %.2f" % [_state_name(carrying), phase])
		rig.free()

func _pose_families(carrying: bool) -> Array[Array]:
	if carrying:
		return [
			Stroller.MOTHER_CARRYING_SIDE,
			Stroller.MOTHER_CARRYING_FRONT_DIAGONAL,
			Stroller.MOTHER_CARRYING_FRONT,
			Stroller.MOTHER_CARRYING_BACK_DIAGONAL,
			Stroller.MOTHER_CARRYING_BACK,
		]
	return [
		Stroller.MOTHER_SIDE,
		Stroller.MOTHER_FRONT_DIAGONAL,
		Stroller.MOTHER_FRONT,
		Stroller.MOTHER_BACK_DIAGONAL,
		Stroller.MOTHER_BACK,
	]

func _test_each_state_has_three_distinct_poses_per_view(t) -> void:
	for carrying in [false, true]:
		for family in _pose_families(carrying):
			t.check(family.size() == 3,
					"each %s view exposes A, C, and B" % _state_name(carrying))
			t.check(family[0] != family[1] and family[1] != family[2]
					and family[0] != family[2],
					"each %s view resolves three distinct texture resources" % _state_name(carrying))

func _direction_textures(carrying: bool, frame: int) -> Array[Texture2D]:
	var families := _pose_families(carrying)
	var side: Array = families[0]
	var front_diagonal: Array = families[1]
	var front: Array = families[2]
	var back_diagonal: Array = families[3]
	var back: Array = families[4]
	return [
		side[frame],
		front_diagonal[frame],
		front[frame],
		front_diagonal[frame],
		side[frame],
		back_diagonal[frame],
		back[frame],
		back_diagonal[frame],
	]

func _test_every_view_resolves_every_pose_in_both_states(t) -> void:
	for carrying in [false, true]:
		var rig := _rig(carrying)
		for frame in range(3):
			var expected := _direction_textures(carrying, frame)
			for direction in range(8):
				rig._view_direction = direction
				t.check(rig._mother_texture(frame) == expected[direction],
						"direction %d resolves %s pose %d"
						% [direction, _state_name(carrying), frame])
		rig.free()
