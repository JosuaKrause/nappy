extends RefCounted
## Focused headless contract tests for the standalone modular compositor and grounded gait.

func run(t) -> void:
	_test_registered_regions_and_order(t)
	_test_no_motion_is_stable(t)
	_test_displacement_plants_and_lifts(t)
	_test_stop_reverse_turn_and_reset(t)
	_test_direction_hysteresis(t)
	_test_visual_state_does_not_own_body(t)
	_test_short_walk_stop_turn_sequence(t)

func _rig(t) -> ModularPerson:
	var rig := ModularPerson.new()
	t.add_child(rig)
	rig.reset_at(Vector2(10.0, 20.0), Vector2.DOWN)
	return rig

func _test_registered_regions_and_order(t) -> void:
	var rig := _rig(t)
	t.check(rig.mother_manifest.part_count() == 9, "all body, leg and shoe parts are registered")
	t.check(rig.pram_manifest.part_count() == 3, "all three pram rows are registered")
	for part_id: String in rig.registered_mother_part_ids():
		var registration := rig.mother_manifest.require_part(part_id)
		t.check(registration.rects.size() == 8, "%s has eight mother regions" % part_id)
		for index: int in 8:
			var rect: Rect2 = registration.rect_for(index)
			t.check(rect.position.x >= 0.0 and rect.end.x <= 1280.0 and rect.position.y >= 0.0 and rect.end.y <= 1536.0,
				"%s direction %d stays within the v3 sheet" % [part_id, index])
			t.check(registration.pivot_for(index) != Vector2.ZERO,
				"%s direction %d has a registered pivot" % [part_id, index])
	for part_id: String in rig.registered_pram_part_ids():
		var registration := rig.pram_manifest.require_part(part_id)
		t.check(registration.rects.size() == 8, "%s has eight pram regions" % part_id)
		for index: int in 8:
			t.check(registration.rect_for(index) == Rect2(index * 160, rig.PRAM_ROWS[part_id] * 128, 160, 128),
				"%s direction %d uses its documented cell" % [part_id, index])
	t.check(rig.mother_manifest.require_part("head_hair").pivot == Vector2(80, 28),
		"head uses the documented attachment pivot")
	t.check(rig.mother_manifest.require_part("left_upper_leg").pivot_for(0) == Vector2(68, 116),
		"left upper leg uses the documented north hip pivot")
	t.check(rig.mother_manifest.require_part("right_lower_leg").pivot_for(2) == Vector2(96, 146),
		"right lower leg uses the documented east knee pivot")
	t.check(rig.mother_manifest.require_part("left_shoe").rect_for(0) == Rect2(27, 7 * 192 + 19, 46, 63),
		"left shoe uses its numeric v3 cutout")
	t.check(rig.pram_manifest.require_part("wheels_frame").pivot == Vector2(80, 112),
		"wheels use the documented wheel pivot")
	t.check(rig.mother_sprites["right_lower_leg"].z_index < rig.mother_sprites["left_shoe"].z_index,
		"mother shoes draw over legs")
	t.check(rig.pram_sprites["wheels_frame"].z_index < rig.pram_sprites["canopy_baby"].z_index,
		"pram canopy draws over wheels")
	t.check(rig.pram_sprites["wheels_frame"].position != Vector2.ZERO,
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
	var planted := rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT)
	rig.apply_displacement(Vector2(16.0, 0.0), Vector2(26.0, 20.0), 1.0, Vector2.RIGHT)
	t.check(rig.gait.is_stepping(), "actual travel starts a swing step")
	t.check(rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT) == planted,
		"stance foot keeps its world anchor while the body travels")
	rig.apply_displacement(Vector2(6.0, 0.0), Vector2(32.0, 20.0), 1.0, Vector2.RIGHT)
	var swing := rig.gait.step_foot()
	t.check(rig.last_pose["%s_foot_height" % ("left" if swing == 0 else "right")] > 0.0,
		"only the swing foot receives lift")
	t.check(rig.last_pose["left_foot_height"] == 0.0 or rig.last_pose["right_foot_height"] == 0.0,
		"stance foot remains on the ground")
	var swing_name: String = "left" if swing == PlantedGait.LEFT_FOOT else "right"
	var stance_name: String = "right" if swing == PlantedGait.LEFT_FOOT else "left"
	var swing_shoe: Sprite2D = rig.mother_sprites[swing_name + "_shoe"]
	var stance_shoe: Sprite2D = rig.mother_sprites[stance_name + "_shoe"]
	var swing_lower: Sprite2D = rig.mother_sprites[swing_name + "_lower_leg"]
	t.check(stance_shoe.position.is_equal_approx(rig.last_pose[stance_name + "_foot"]),
		"stance shoe consumes its planted world pose")
	t.check(swing_shoe.position.y < rig.last_pose[swing_name + "_foot"].y,
		"swing shoe visibly lifts above the ground plane")
	t.check(rig.last_pose[swing_name + "_foot_height"] >= 4.0,
		"swing lift is meaningful at gameplay pixel scale")
	t.check(swing_lower.position.is_equal_approx(rig.last_pose[swing_name + "_knee"]),
		"swing lower leg is attached at the solved knee")
	t.check(absf(swing_lower.rotation) > 0.001,
		"swing lower leg rotates through the solved knee")
	rig.free()

func _test_stop_reverse_turn_and_reset(t) -> void:
	var rig := _rig(t)
	rig.apply_displacement(Vector2(16.0, 0.0), Vector2(26.0, 20.0), 1.0, Vector2.RIGHT)
	var left_before_stop: Vector2 = rig.gait.stance_anchor(PlantedGait.LEFT_FOOT)
	var right_before_stop: Vector2 = rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT)
	rig.stop_pose()
	t.check(rig.last_displacement == Vector2.ZERO, "stop cancels further gait travel")
	t.check(rig.last_pose["left_foot_height"] == 0.0 and rig.last_pose["right_foot_height"] == 0.0,
		"stop settles both feet onto the ground plane")
	t.check(rig.gait.stance_anchor(PlantedGait.LEFT_FOOT) == left_before_stop and
		rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT) == right_before_stop,
		"stop preserves both existing foot anchors")
	rig.stop_pose()
	t.check(rig.gait.stance_anchor(PlantedGait.LEFT_FOOT) == left_before_stop and
		rig.gait.stance_anchor(PlantedGait.RIGHT_FOOT) == right_before_stop,
		"repeated stop keeps settled anchors stable")
	rig.turn_to(Vector2.LEFT)
	t.check(rig.direction == DirectionalParts.Direction.W, "turn selects the reverse authored view")
	rig.apply_displacement(Vector2(-16.0, 0.0), Vector2(10.0, 20.0), 1.0, Vector2.LEFT)
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

func _test_short_walk_stop_turn_sequence(t) -> void:
	var rig := _rig(t)
	rig.apply_displacement(Vector2(16.0, 0.0), Vector2(26.0, 20.0), 1.0, Vector2.RIGHT)
	var walk := rig.apply_displacement(Vector2(6.0, 0.0), Vector2(32.0, 20.0), 1.0, Vector2.RIGHT)
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
