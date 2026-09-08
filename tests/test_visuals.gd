extends RefCounted
## Focused headless contract tests for the standalone modular compositor and grounded gait.

func run(t) -> void:
	_test_manifest_rejects_invalid_registration(t)
	_test_registered_regions_and_order(t)
	_test_no_motion_is_stable(t)
	_test_displacement_plants_and_lifts(t)
	_test_stop_reverse_turn_and_reset(t)
	_test_direction_hysteresis(t)
	_test_visual_state_does_not_own_body(t)
	_test_live_owner_coordinate_binding(t)
	_test_short_walk_stop_turn_sequence(t)
	_test_walker_manifest_and_variants(t)
	_test_walker_consumes_actual_displacement(t)

func _test_manifest_rejects_invalid_registration(t) -> void:
	var manifest := DirectionalParts.new_manifest()
	var texture: Texture2D = preload("res://assets/illustrated/modular/mother-parts-v3.png")
	var rects: Array[Rect2] = []
	var z_orders: Array[int] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		rects.append(Rect2(0.0, 0.0, 16.0, 16.0))
		z_orders.append(0)
	t.check(manifest.register_part("valid", texture, rects, Vector2.ZERO, Vector2.ZERO, z_orders),
		"a bounded registration with one shared pivot is accepted")
	var outside: Array[Rect2] = rects.duplicate()
	outside[DirectionalParts.Direction.N] = Rect2(1272.0, 0.0, 16.0, 16.0)
	t.check(not manifest.register_part("outside", texture, outside, Vector2.ZERO, Vector2.ZERO, z_orders),
		"a crop extending past the PNG is rejected")
	var wrong_pivots: Array[Vector2] = [Vector2.ZERO]
	t.check(not manifest.register_part("pivot_count", texture, rects, Vector2.ZERO, wrong_pivots, z_orders),
		"a partial direction pivot list is rejected instead of silently falling back")
	t.check(not manifest.register_part("blank_variant", texture, rects, Vector2.ZERO, Vector2.ZERO, z_orders, ""),
		"an empty variant key is rejected")

func _rig(t) -> ModularPerson:
	var rig := ModularPerson.new()
	t.add_child(rig)
	rig.reset_at(Vector2(10.0, 20.0), Vector2.DOWN)
	return rig

func _test_registered_regions_and_order(t) -> void:
	var rig := _rig(t)
	t.check(rig.registration_valid(), "the measured mother and pram manifests register cleanly")
	for part_id: String in rig.registered_mother_part_ids():
		var registration := rig.mother_manifest.require_part(part_id)
		t.check(registration.rects.size() == 8, "%s has eight mother regions" % part_id)
		for index: int in 8:
			var rect: Rect2 = registration.rect_for(index)
			t.check(rect.size.x > 0.0 and rect.size.y > 0.0,
				"%s direction %d has a measured non-empty crop" % [part_id, index])
		t.check(rig.mother_sprites[part_id].z_index == 0,
			"%s remains inside the actor's y-sort layer" % part_id)
	for part_id: String in rig.registered_pram_part_ids():
		var registration := rig.pram_manifest.require_part(part_id)
		t.check(registration.rects.size() == 8, "%s has eight pram regions" % part_id)
		for index: int in 8:
			t.check(registration.rect_for(index).size.x > 0.0 \
					and registration.rect_for(index).size.y > 0.0,
				"%s direction %d has a measured non-empty crop" % [part_id, index])
		t.check(rig.pram_sprites[part_id].z_index == 0,
			"%s remains inside the actor's y-sort layer" % part_id)
	t.check(rig.pram_sprites["chassis"].position != Vector2.ZERO,
		"pram is composed beside the mother")
	rig.free()

func _test_no_motion_is_stable(t) -> void:
	var rig := _rig(t)
	var left := rig.gait.foot_world(PlantedGait.LEFT_FOOT)
	var right := rig.gait.foot_world(PlantedGait.RIGHT_FOOT)
	rig.stop_pose()
	t.check(rig.last_displacement == Vector2.ZERO, "stopping supplies zero displacement")
	t.check(rig.gait.foot_world(0) == left and rig.gait.foot_world(1) == right,
		"stopped pose does not drift either foot")
	rig.free()

func _test_displacement_plants_and_lifts(t) -> void:
	var rig := _rig(t)
	var anchors_before: Array[Vector2] = [rig.gait.stance_anchor(PlantedGait.LEFT_FOOT),
		rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT)]
	var travel: float = rig.gait.step_trigger + rig.gait.step_span * 0.5
	rig.apply_displacement(Vector2(travel, 0.0), Vector2(10.0 + travel, 20.0),
		1.0, Vector2.RIGHT)
	t.check(rig.gait.is_stepping(), "actual travel starts a swing step")
	var swing: int = rig.gait.step_foot()
	var stance: int = PlantedGait.RIGHT_FOOT \
		if swing == PlantedGait.LEFT_FOOT else PlantedGait.LEFT_FOOT
	t.check(rig.gait.stance_anchor(stance) == anchors_before[stance],
		"stance foot keeps its world anchor while the body travels")
	t.check(rig.last_pose["%s_foot_height" % ("left" if swing == 0 else "right")] > 0.0,
		"only the swing foot receives lift")
	t.check(rig.last_pose["left_foot_height"] == 0.0 or rig.last_pose["right_foot_height"] == 0.0,
		"stance foot remains on the ground")
	var swing_name: String = "left" if swing == PlantedGait.LEFT_FOOT else "right"
	var stance_name: String = "right" if swing == PlantedGait.LEFT_FOOT else "left"
	var stance_registration := rig.mother_manifest.require_part(stance_name + "_shoe")
	var swing_registration := rig.mother_manifest.require_part(swing_name + "_shoe")
	t.check(rig.source_point_in_actor(stance_name + "_shoe",
		stance_registration.axis_end_for(rig.direction)).is_equal_approx(
			rig.last_pose[stance_name + "_sole"]),
		"stance shoe's painted sole consumes its planted pose")
	t.check(rig.source_point_in_actor(swing_name + "_shoe",
		swing_registration.axis_end_for(rig.direction)).y \
			< rig.last_pose[swing_name + "_foot"].y,
		"swing shoe visibly lifts above the ground plane")
	t.check(rig.last_pose[swing_name + "_foot_height"] > rig.gait.swing_height * 0.5,
		"swing lift is meaningful at gameplay pixel scale")
	var lower_registration := rig.mother_manifest.require_part(swing_name + "_lower_leg")
	t.check(rig.source_point_in_actor(swing_name + "_lower_leg",
		lower_registration.axis_start_for(rig.direction)).is_equal_approx(
			rig.last_pose[swing_name + "_knee"]),
		"swing shin's painted proximal joint meets the solved knee")
	t.check(rig.source_point_in_actor(swing_name + "_lower_leg",
		lower_registration.axis_end_for(rig.direction)).is_equal_approx(
			rig.last_pose[swing_name + "_ankle"]),
		"swing shin's painted distal joint meets the raised ankle")
	rig.free()

func _test_stop_reverse_turn_and_reset(t) -> void:
	var rig := _rig(t)
	var stop_travel: float = rig.gait.step_trigger + rig.gait.step_span * 0.5
	rig.apply_displacement(Vector2(stop_travel, 0.0), Vector2(10.0 + stop_travel, 20.0),
		1.0, Vector2.RIGHT)
	var pose_before_stop: Dictionary = rig.last_pose.duplicate()
	rig.stop_pose()
	t.check(rig.last_displacement == Vector2.ZERO, "stop supplies no gait travel")
	t.check(rig.last_pose["left_sole"] == pose_before_stop["left_sole"] \
			and rig.last_pose["right_sole"] == pose_before_stop["right_sole"] \
			and rig.last_pose["step_progress"] == pose_before_stop["step_progress"],
		"stop freezes both rendered soles and swing progress")
	rig.stop_pose()
	t.check(rig.last_pose["left_sole"] == pose_before_stop["left_sole"] \
			and rig.last_pose["right_sole"] == pose_before_stop["right_sole"],
		"repeated stop keeps the frozen pose stable")
	rig.turn_to(Vector2.LEFT)
	t.check(rig.direction == DirectionalParts.Direction.W, "turn selects the reverse authored view")
	var reversed_body := Vector2(10.0 + stop_travel - 16.0, 20.0)
	rig.apply_displacement(Vector2(-16.0, 0.0), reversed_body, 1.0, Vector2.LEFT)
	t.check(rig.direction == DirectionalParts.Direction.W, "reverse displacement follows the new heading")
	rig.teleport_to(Vector2(100.0, 40.0), Vector2.UP)
	t.check(rig.visual_world_position == Vector2(100.0, 40.0), "teleport resets visual position")
	t.check(rig.gait.foot_world(0) == rig.gait.stance_anchor(0), "teleport resets left planted anchor")
	t.check(rig.gait.foot_world(1) == rig.gait.stance_anchor(1), "teleport resets right planted anchor")
	rig.free()

func _test_direction_hysteresis(t) -> void:
	var rig := _rig(t)
	rig.turn_to(Vector2.RIGHT)
	var settled := rig.direction
	for degrees in [20.0, 24.0, 28.0, 32.0]:
		var angle := deg_to_rad(degrees)
		rig.apply_displacement(Vector2.ZERO, rig.visual_world_position, 0.0,
			Vector2(cos(angle), sin(angle)))
		t.check(rig.direction == settled, "heading wobble stays in the hysteresis band")
	rig.turn_to(Vector2.DOWN)
	t.check(rig.direction == DirectionalParts.Direction.S, "turn exits the band to south")
	rig.free()

func _test_visual_state_does_not_own_body(t) -> void:
	var rig := _rig(t)
	var logical := Vector2(33.0, 44.0)
	rig.apply_displacement(Vector2(2.0, 0.0), logical, 1.0, Vector2.RIGHT)
	t.check(logical == Vector2(33.0, 44.0), "caller logical body value is unchanged")
	t.check(rig.position == Vector2.ZERO, "compositor does not move its Node2D origin")
	rig.free()

func _test_live_owner_coordinate_binding(t) -> void:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.reset_at(Vector2(137.0, 241.0), Vector2.RIGHT)
	var compositor := stroller.get_node_or_null("ModularPerson") as ModularPerson
	if not DevFlags.illustrated_requested():
		t.check(compositor == null, "legacy presentation does not create the opt-in compositor")
		stroller.free()
		return
	t.check(compositor != null, "illustrated presentation creates the live compositor")
	if compositor == null:
		stroller.free()
		return
	t.check(compositor.position == Vector2.ZERO, "live compositor stays at the owner's local origin")
	t.check(compositor.global_position == stroller.global_position,
		"live compositor origin is aligned with the owner's world position")
	stroller.global_position = Vector2(181.0, 209.0)
	t.check(compositor.global_position == stroller.global_position,
		"child compositor follows owner movement without an independent offset")
	stroller.free()

func _test_short_walk_stop_turn_sequence(t) -> void:
	var rig := _rig(t)
	var travel: float = rig.gait.step_trigger + rig.gait.step_span * 0.5
	var walk := rig.apply_displacement(Vector2(travel, 0.0),
		Vector2(10.0 + travel, 20.0), 1.0, Vector2.RIGHT)
	var swing := rig.gait.step_foot()
	var swing_sprite: Sprite2D = rig.mother_sprites["left_shoe" if swing == 0 else "right_shoe"]
	print("[visual-sequence] walk direction=%s swing=%d shoe_pos=%s knee=%s leg_rot=%.3f lift=(%.3f, %.3f)" % [
		DirectionalParts.direction_name(rig.direction), swing, str(swing_sprite.position),
		str(rig.mother_sprites["left_lower_leg" if swing == 0 else "right_lower_leg"].position),
		swing_sprite.rotation, walk["left_foot_height"], walk["right_foot_height"]])
	var stopped := rig.stop_pose()
	print("[visual-sequence] stop direction=%s lift=(%.3f, %.3f)" % [
		DirectionalParts.direction_name(rig.direction), stopped["left_foot_height"],
		stopped["right_foot_height"]])
	rig.turn_to(Vector2.LEFT)
	print("[visual-sequence] turn direction=%s anchors=(%s, %s)" % [
		DirectionalParts.direction_name(rig.direction), str(rig.gait.foot_world(0)),
		str(rig.gait.foot_world(1))])
	t.check(rig.direction == DirectionalParts.Direction.W, "short sequence turns to west")
	rig.free()

func _test_walker_manifest_and_variants(t) -> void:
	var walker := ModularWalker.new()
	t.add_child(walker)
	t.check(walker.registration_valid, "walker registers every measured directional part")
	for variant: String in ["mustard_bob", "rust_curls"]:
		var registration := walker.manifest.require_part("upper_body", variant)
		t.check(registration.rects.size() == 8, "%s upper body has eight authored views" % variant)
		for index: int in 8:
			t.check(registration.rect_for(index).size.x > 0.0 \
					and registration.rect_for(index).size.y > 0.0,
				"%s direction %d has a measured non-empty silhouette" % [variant, index])
	for part_id: String in ["left_upper_leg", "right_upper_leg", "left_lower_leg", "right_lower_leg", "left_shoe", "right_shoe"]:
		var lower := walker.manifest.require_part(part_id)
		t.check(lower.rects.size() == 8,
			"%s has eight explicit directional source regions" % part_id)
		t.check(walker.sprites[part_id].z_index == 0 \
				and walker.sprites[part_id].region_filter_clip_enabled,
			"%s stays actor-local and clips atlas filtering to its crop" % part_id)
	t.check(walker.sprites["upper_body"].position.is_equal_approx(
		(walker.last_pose["left_hip"] + walker.last_pose["right_hip"]) * 0.5),
		"walker upper body is registered from the gait hip anchor")
	var upper_leg_registration := walker.manifest.require_part("left_upper_leg")
	var lower_leg_registration := walker.manifest.require_part("left_lower_leg")
	t.check(upper_leg_registration.axis_end_for(0).y > upper_leg_registration.axis_start_for(0).y,
		"upper leg records a measured rest axis")
	t.check(lower_leg_registration.axis_end_for(0).y > lower_leg_registration.axis_start_for(0).y,
		"lower leg records a measured rest axis")
	walker.set_variant("rust_curls")
	t.check(walker.variant == "rust_curls", "walker can switch interchangeable upper variation")
	walker.free()

func _test_walker_consumes_actual_displacement(t) -> void:
	var walker := ModularWalker.new()
	t.add_child(walker)
	walker.reset_at(Vector2(20.0, 40.0), Vector2.RIGHT)
	walker.apply_displacement(Vector2.ZERO, Vector2(20.0, 40.0), 1.0, Vector2.RIGHT)
	t.check(walker.last_displacement == Vector2.ZERO, "stopped walker receives zero applied displacement")
	var travel: float = walker.gait.step_trigger + walker.gait.step_span * 0.5
	var displacement := Vector2(travel, 0.0)
	walker.apply_displacement(displacement, Vector2(20.0 + travel, 40.0), 0.1, Vector2.RIGHT)
	t.check(walker.last_displacement == displacement and walker.gait.is_stepping(),
			"walker gait is driven by actual applied displacement")
	t.check(walker.position == Vector2.ZERO, "walker presentation never moves its owner origin")
	var swing := walker.gait.step_foot()
	var swing_name: String = "left" if swing == PlantedGait.LEFT_FOOT else "right"
	var stance_name: String = "right" if swing == PlantedGait.LEFT_FOOT else "left"
	var swing_registration := walker.manifest.require_part(swing_name + "_shoe")
	var stance_registration := walker.manifest.require_part(stance_name + "_shoe")
	var swing_sole: Vector2 = walker.sprites[swing_name + "_shoe"].transform * (
		swing_registration.axis_end_for(walker.direction) \
			+ walker.sprites[swing_name + "_shoe"].offset)
	var stance_sole: Vector2 = walker.sprites[stance_name + "_shoe"].transform * (
		stance_registration.axis_end_for(walker.direction) \
			+ walker.sprites[stance_name + "_shoe"].offset)
	t.check(swing_sole.y < walker.last_pose[swing_name + "_foot"].y,
		"swing shoe consumes solved lift")
	t.check(stance_sole.is_equal_approx(walker.last_pose[stance_name + "_sole"]),
		"stance shoe's painted sole remains on its solved ground anchor")
	walker.recycle_at(Vector2(100.0, 40.0), Vector2.UP)
	t.check(walker.last_displacement == Vector2.ZERO and walker.direction == DirectionalParts.Direction.N,
			"recycle resets applied displacement and heading")
	walker.free()
