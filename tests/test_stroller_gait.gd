extends RefCounted
## The pushing and carrying rigs share a distance-driven contact/passing gait.

## The library her pages are acquired on, handed to every rig through `Stroller.use_atlas()`.
var _library := AtlasLibrary.new()

func run(t: TestRunner) -> void:
	for carrying: bool in [false, true]:
		var rig := _rig(t, carrying)
		var samples := await _walk(t, rig, 80)
		_test_the_cycle_visits_contact_passing_contact_passing(t, carrying, samples)
		_test_the_gait_follows_distance_and_changes_frame_on_quarter_boundaries(t, carrying, samples)
		_test_idle_holds_the_passing_pose_from_every_phase(t, carrying, samples)
		rig.free()
	_test_each_state_has_three_distinct_poses_per_view(t)
	await _test_every_view_resolves_every_pose_in_both_states(t)

## A rig in the tree, so her own `_enter_tree()` acquires her page (on a library of her own, since
## nobody hands her one) and her own `_physics_process()` runs.
func _rig(t: TestRunner, carrying: bool) -> Stroller:
	var rig := Stroller.new()
	rig.use_atlas(_library)
	rig.carrying = carrying
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	return rig

func _state_name(carrying: bool) -> String:
	return "carrying" if carrying else "pushing"

## One sample per real physics frame of her walking east with the move key held: the pose she is
## drawn in, how far the frame carried her, and the gait phase before it.
func _walk(t: TestRunner, rig: Stroller, frames: int) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	Input.action_press("move_right")
	for _i in frames:
		var before := rig.global_position
		var phase_before: float = rig.pose(1.0).walk_phase
		await t.get_tree().physics_frame
		samples.append({
			"pose": rig.pose(1.0),
			"idle_pose": rig.pose(0.0),
			"phase_before": phase_before,
			"moved": rig.global_position.distance_to(before),
		})
	Input.action_release("move_right")
	return samples

func _test_the_cycle_visits_contact_passing_contact_passing(t: TestRunner, carrying: bool, samples: Array[Dictionary]) -> void:
	var frames: Array[int] = []
	for sample in samples:
		var frame: int = sample.pose.gait_frame
		if frames.is_empty() or frames[-1] != frame:
			frames.append(frame)
	t.check(frames.size() >= 8 and frames.slice(0, 8) == [0, 1, 2, 1, 0, 1, 2, 1],
			"two %s cycles are A, C, B, C, A, C, B, C (%s)" % [_state_name(carrying), frames])

func _test_the_gait_follows_distance_and_changes_frame_on_quarter_boundaries(t: TestRunner, carrying: bool, samples: Array[Dictionary]) -> void:
	var wrapped := true
	var by_distance := true
	var by_quarter := true
	for sample in samples:
		var phase: float = sample.pose.walk_phase
		wrapped = wrapped and phase >= 0.0 and phase < TAU
		# Each step advances the phase by the distance it covered, whatever the speed.
		var advanced := fposmod(phase - float(sample.phase_before), TAU)
		by_distance = by_distance and is_equal_approx(advanced,
				fposmod(float(sample.moved) * WalkerLook.GAIT_RATE, TAU))
		by_quarter = by_quarter and sample.pose.gait_frame \
				== Stroller.MOTHER_GAIT_LOOP[int(floor(phase / (TAU / 4.0))) % 4]
	t.check(wrapped, "the %s gait phase wraps at one TAU" % _state_name(carrying))
	t.check(by_distance, "the %s gait advances by distance covered" % _state_name(carrying))
	t.check(by_quarter, "the %s frame changes exactly on a quarter boundary of the phase"
			% _state_name(carrying))

func _test_idle_holds_the_passing_pose_from_every_phase(t: TestRunner, carrying: bool, samples: Array[Dictionary]) -> void:
	var quarters := {}
	var held := true
	for sample in samples:
		quarters[int(floor(float(sample.pose.walk_phase) / (TAU / 4.0)))] = true
		held = held and sample.idle_pose.gait_frame == 1
	t.check(quarters.size() == 4, "the %s walk visits all four quarters of the phase"
			% _state_name(carrying))
	t.check(held, "idle %s settles on C from every phase" % _state_name(carrying))

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

func _test_each_state_has_three_distinct_poses_per_view(t: TestRunner) -> void:
	for carrying: bool in [false, true]:
		for family in _pose_families(carrying):
			t.check(family.size() == 3,
					"each %s view exposes A, C, and B" % _state_name(carrying))
			t.check(family[0] != family[1] and family[1] != family[2]
					and family[0] != family[2],
					"each %s view resolves three distinct texture resources" % _state_name(carrying))

func _direction_textures(carrying: bool, frame: int) -> Array[String]:
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

func _test_every_view_resolves_every_pose_in_both_states(t: TestRunner) -> void:
	for carrying: bool in [false, true]:
		var rig := _rig(t, carrying)
		for direction in range(8):
			rig.reset_at(Vector2.ZERO, Vector2.from_angle(direction * PI / 4.0))
			var pose := rig.pose(1.0)
			t.check(pose.view == direction, "facing %d settles view %d" % [direction * 45, direction])
			for frame in range(3):
				var expected := _direction_textures(carrying, frame)
				t.check(pose.mother_sources[frame] == expected[direction]
						and _library.region(StringName(pose.mother_sources[frame]))
						== _library.region(StringName(expected[direction])),
						"direction %d resolves %s pose %d"
						% [direction, _state_name(carrying), frame])
		rig.free()
