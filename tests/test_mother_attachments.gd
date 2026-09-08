extends RefCounted
## Source and render-space contracts for the measured mother and pram assembly.

const BODY_PARTS: Array[String] = [
	"head_hair", "left_upper_leg", "left_lower_leg", "right_upper_leg",
	"right_lower_leg", "left_shoe", "right_shoe",
]


func run(t) -> void:
	var rig := ModularPerson.new()
	t.add_child(rig)
	t.check(rig.registration_valid(), "the complete measured mother and pram manifests register")
	if not rig.registration_valid():
		rig.free()
		return
	_check_source_landmarks(t, rig)
	_check_all_facings(t, rig)
	_check_walk_stop_reverse_reset(t, rig)
	_check_incomplete_order_stops_safely(t, rig)
	rig.free()


func _check_source_landmarks(t, rig: ModularPerson) -> void:
	var mother_image := rig.MOTHER_TEXTURE.get_image()
	for part_id: String in rig.registered_mother_part_ids():
		var registration: DirectionalParts.PartRegistration = \
			rig.mother_manifest.require_part(part_id)
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := registration.rect_for(direction)
			if registration.has_axis(direction):
				for point: Vector2 in [
						registration.axis_start_for(direction),
						registration.axis_end_for(direction)]:
					t.check(_alpha_near(mother_image, crop.position + point),
						"%s %s joint is supported by named source artwork" % [
							part_id, DirectionalParts.DIRECTION_NAMES[direction]])
	var head := rig.mother_manifest.require_part("head_hair")
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		t.check(_alpha_near(mother_image,
			head.rect_for(direction).position + head.pivot_for(direction), 8),
			"%s head neck pivot reaches painted source pixels" %
				DirectionalParts.DIRECTION_NAMES[direction])
	var pram_image := rig.PRAM_TEXTURE.get_image()
	var chassis: Dictionary = rig.pram_asset["parts"]["chassis"]
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		var crop := rig._rect(chassis["crops"][direction])
		for key: String in ["seat_contacts", "left_hand_contacts", "right_hand_contacts"]:
			var contacts: Array = chassis[key]
			t.check(_alpha_near(pram_image,
				crop.position + rig._point(contacts[direction])),
				"%s %s lands on painted chassis artwork" % [
					DirectionalParts.DIRECTION_NAMES[direction], key])
	var seat: Dictionary = rig.pram_asset["parts"]["seat"]
	for key: String in ["canopy_contacts", "baby_contacts"]:
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := rig._rect(seat["crops"][direction])
			t.check(_alpha_near(pram_image,
				crop.position + rig._point(seat[key][direction])),
				"%s %s lands on painted seat artwork" % [
					DirectionalParts.DIRECTION_NAMES[direction], key])
	for part_id: String in ["seat", "canopy", "baby"]:
		var part: Dictionary = rig.pram_asset["parts"][part_id]
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := rig._rect(part["crops"][direction])
			t.check(_alpha_near(pram_image,
				crop.position + rig._point(part["pivots"][direction])),
				"%s %s pivot is supported by painted source artwork" % [
					DirectionalParts.DIRECTION_NAMES[direction], part_id])


func _check_all_facings(t, rig: ModularPerson) -> void:
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		var facing: Vector2 = DirectionalParts.DIRECTION_VECTORS[direction]
		rig.reset_at(Vector2(40.0, 50.0), facing)
		_check_rendered_attachments(t, rig)
		var bounds := _painted_body_bounds(rig)
		t.check(bounds.size.y >= 44.0 and bounds.size.y <= 49.0,
			"%s painted body retains the 46px legacy stature" %
				DirectionalParts.DIRECTION_NAMES[direction])
		t.check(absf(bounds.end.y) <= 1.25,
			"%s painted shoes finish at the actor ground" %
				DirectionalParts.DIRECTION_NAMES[direction])
		var chassis_bounds := _painted_sprite_bounds(rig.pram_sprites["chassis"])
		t.close_to(chassis_bounds.size.y, 30.0,
			"%s chassis retains the 30px painted height" %
				DirectionalParts.DIRECTION_NAMES[direction], 0.4)
		_check_sibling_order(t, rig, facing)


func _check_rendered_attachments(t, rig: ModularPerson) -> void:
	var pose: Dictionary = rig.last_pose
	var hip_center: Vector2 = (pose["left_hip"] + pose["right_hip"]) * 0.5
	var neck := Vector2(hip_center.x, -float(rig.mother_asset["skeleton"]["neck_height"]))
	_check_axis(t, rig, "torso_clothing", neck, hip_center)
	var head: DirectionalParts.PartRegistration = \
		rig.mother_manifest.require_part("head_hair")
	t.check(rig.source_point_in_actor("head_hair", head.pivot_for(rig.direction)
		).distance_to(neck) <= 0.02, "the painted head neck pivot meets the skeleton neck")
	for side: String in ["left", "right"]:
		_check_axis(t, rig, side + "_upper_leg", pose[side + "_hip"], pose[side + "_knee"])
		_check_axis(t, rig, side + "_lower_leg", pose[side + "_knee"], pose[side + "_ankle"])
		_check_axis(t, rig, side + "_shoe", pose[side + "_ankle"], pose[side + "_sole"])
		var shoulder := _shoulder(rig, side)
		_check_axis(t, rig, side + "_arm", shoulder, _handle_contact(rig, side))
		t.check(_point_meets_torso(rig, shoulder),
			"the %s painted arm starts at the rendered torso edge" % side)
	var pram_anchor := Vector2(
		rig.heading.x, rig.heading.y * Stroller.OBLIQUE_Y) * Stroller.PRAM_DISTANCE
	var chassis: Sprite2D = rig.pram_sprites["chassis"]
	t.check(chassis.position.distance_to(pram_anchor) <= 0.02,
		"the chassis wheel baseline meets the logical pram ground")
	var seat: Sprite2D = rig.pram_sprites["seat"]
	t.check(seat.position.distance_to(_pram_contact(rig, chassis, "chassis",
		"seat_contacts")) <= 0.02, "the seat pivot meets the rendered chassis mount")
	var canopy: Sprite2D = rig.pram_sprites["canopy"]
	t.check(canopy.position.distance_to(_pram_contact(rig, seat, "seat",
		"canopy_contacts")) <= 0.02, "the canopy hinge meets the rendered seat hinge")
	var baby: Sprite2D = rig.pram_sprites["baby"]
	t.check(baby.position.distance_to(_pram_contact(rig, seat, "seat",
		"baby_contacts")) <= 0.02, "the baby contact meets the rendered seat")


func _check_axis(t, rig: ModularPerson, part_id: String,
		target_start: Vector2, target_end: Vector2) -> void:
	var sprite: Sprite2D = rig.mother_sprites[part_id]
	var registration: DirectionalParts.PartRegistration = \
		rig.mother_manifest.require_part(part_id)
	var rendered_start: Vector2 = sprite.transform * (
		registration.axis_start_for(rig.direction) + sprite.offset)
	var rendered_end: Vector2 = sprite.transform * (
		registration.axis_end_for(rig.direction) + sprite.offset)
	t.check(rendered_start.distance_to(target_start) <= 0.02,
		"%s painted proximal endpoint meets its live joint" % part_id)
	t.check(rendered_end.distance_to(target_end) <= 0.02,
		"%s painted distal endpoint meets its live joint" % part_id)


func _check_walk_stop_reverse_reset(t, rig: ModularPerson) -> void:
	var body := Vector2(90.0, 70.0)
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		var travel: Vector2 = DirectionalParts.DIRECTION_VECTORS[direction].normalized()
		rig.reset_at(body, travel)
		var greatest_lift := 0.0
		for _step: int in 20:
			var displacement := travel * 2.0
			body += displacement
			var pose := rig.apply_displacement(displacement, body, 1.0 / 60.0, travel)
			greatest_lift = maxf(greatest_lift,
				maxf(float(pose["left_foot_height"]), float(pose["right_foot_height"])))
			_check_rendered_attachments(t, rig)
		t.check(greatest_lift > 0.0,
			"%s sustained travel produces a painted swing" %
				DirectionalParts.DIRECTION_NAMES[direction])
		var stopped := rig.stop_pose()
		var stopped_again := rig.stop_pose()
		t.check(stopped["left_sole"].is_equal_approx(stopped_again["left_sole"])
			and stopped["right_sole"].is_equal_approx(stopped_again["right_sole"])
			and is_equal_approx(float(stopped["step_progress"]),
				float(stopped_again["step_progress"])),
			"repeated zero travel freezes the rendered soles and swing progress")
		_check_rendered_attachments(t, rig)
		var reverse := -travel
		rig.turn_to(reverse)
		t.check(rig.direction == DirectionalParts.direction_from_heading(reverse),
			"a zero-travel turn selects the authored reverse facing")
		_check_rendered_attachments(t, rig)
		var reverse_displacement := reverse * 48.0
		body += reverse_displacement
		var reversed := rig.apply_displacement(
			reverse_displacement, body, 1.0 / 30.0, reverse)
		for side: String in ["left", "right"]:
			t.check(reversed[side + "_hip"].distance_to(reversed[side + "_ankle"])
				<= rig.gait.max_reach() + 0.02,
				"a large reversed move keeps the %s painted leg within calibrated reach" % side)
		_check_rendered_attachments(t, rig)
	var reset_position := Vector2(-35.0, 112.0)
	rig.teleport_to(reset_position, Vector2.DOWN)
	t.check(rig.visual_world_position == reset_position,
		"teleport reset records the new logical ground origin")
	_check_rendered_attachments(t, rig)


func _check_incomplete_order_stops_safely(t, rig: ModularPerson) -> void:
	var malformed: Dictionary = rig.mother_asset.duplicate(true)
	var orders: Dictionary = malformed["per_direction_order"]
	var north: Array = orders["N"]
	north.pop_back()
	var path := "/tmp/nappy-invalid-mother-layer-order.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	t.check(file != null, "the malformed manifest fixture can be written")
	if file == null:
		return
	file.store_string(JSON.stringify(malformed))
	file.close()
	var result := rig._read_manifest(path, rig.MOTHER_TEXTURE, rig.MOTHER_PARTS)
	t.check(result.is_empty(),
		"an incomplete directional layer order stops registration before sprite construction")
	malformed = rig.mother_asset.duplicate(true)
	var left_arm: Dictionary = malformed["parts"]["left_arm"]
	left_arm.erase("axis_start")
	left_arm.erase("axis_end")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	result = rig._read_manifest(path, rig.MOTHER_TEXTURE, rig.MOTHER_PARTS)
	t.check(result.is_empty(),
		"a mother segment without measured axes stops registration before sprite construction")
	DirAccess.remove_absolute(path)


func _shoulder(rig: ModularPerson, side: String) -> Vector2:
	var shoulders: Array = rig.mother_asset["skeleton"]["shoulders_by_direction"][rig.direction]
	return rig._point(shoulders[0 if side == "left" else 1])


func _handle_contact(rig: ModularPerson, side: String) -> Vector2:
	var chassis: Sprite2D = rig.pram_sprites["chassis"]
	var contacts: Array = rig.pram_asset["parts"]["chassis"][side + "_hand_contacts"]
	return chassis.transform * (rig._point(contacts[rig.direction]) + chassis.offset)


func _pram_contact(rig: ModularPerson, sprite: Sprite2D,
		part_id: String, key: String) -> Vector2:
	var points: Array = rig.pram_asset["parts"][part_id][key]
	return sprite.transform * (rig._point(points[rig.direction]) + sprite.offset)


func _painted_body_bounds(rig: ModularPerson) -> Rect2:
	var bounds := Rect2()
	var initialized := false
	for part_id: String in BODY_PARTS:
		var part_bounds := _painted_sprite_bounds(rig.mother_sprites[part_id])
		if not initialized:
			bounds = part_bounds
			initialized = true
		else:
			bounds = bounds.merge(part_bounds)
	return bounds.merge(_polygon_bounds(rig._torso_polygon))


func _painted_sprite_bounds(sprite: Sprite2D) -> Rect2:
	var image := sprite.texture.get_image()
	var crop := sprite.region_rect
	var minimum := Vector2.INF
	var maximum := -Vector2.INF
	for y: int in int(crop.size.y):
		for x: int in int(crop.size.x):
			if image.get_pixelv(Vector2i(crop.position) + Vector2i(x, y)).a <= 0.1:
				continue
			var rendered: Vector2 = sprite.transform * (Vector2(x, y) + sprite.offset)
			minimum = minimum.min(rendered)
			maximum = maximum.max(rendered)
	return Rect2(minimum, maximum - minimum)


func _polygon_bounds(polygon: Polygon2D) -> Rect2:
	var minimum := Vector2.INF
	var maximum := -Vector2.INF
	for point: Vector2 in polygon.polygon:
		var rendered := polygon.transform * point
		minimum = minimum.min(rendered)
		maximum = maximum.max(rendered)
	return Rect2(minimum, maximum - minimum)


func _point_meets_torso(rig: ModularPerson, point: Vector2) -> bool:
	var rendered := PackedVector2Array()
	for vertex: Vector2 in rig._torso_polygon.polygon:
		rendered.append(rig._torso_polygon.transform * vertex)
	if Geometry2D.is_point_in_polygon(point, rendered):
		return true
	for index: int in rendered.size():
		var closest := Geometry2D.get_closest_point_to_segment(
			point, rendered[index], rendered[(index + 1) % rendered.size()])
		if closest.distance_to(point) <= 2.0:
			return true
	return false


func _alpha_near(image: Image, point: Vector2, radius: int = 4) -> bool:
	var center := Vector2i(roundi(point.x), roundi(point.y))
	for y: int in range(maxi(0, center.y - radius), mini(image.get_height(), center.y + radius + 1)):
		for x: int in range(maxi(0, center.x - radius), mini(image.get_width(), center.x + radius + 1)):
			if image.get_pixel(x, y).a > 0.1:
				return true
	return false


func _check_sibling_order(t, rig: ModularPerson, facing: Vector2) -> void:
	var mother_indices: Array[int] = []
	for part_id: String in rig.registered_mother_part_ids():
		var item: CanvasItem = rig._torso_polygon if part_id == "torso_clothing" \
			else rig.mother_sprites[part_id]
		t.check(item.z_index == 0, "mother parts share one actor-level z plane")
		mother_indices.append(item.get_index())
	var pram_indices: Array[int] = []
	for part_id: String in rig.registered_pram_part_ids():
		var item: CanvasItem = rig.pram_sprites[part_id]
		t.check(item.z_index == 0, "pram parts share one actor-level z plane")
		pram_indices.append(item.get_index())
	if facing.y < -0.001:
		t.check(pram_indices.max() < mother_indices.min(),
			"north-facing pram siblings draw behind the mother as one actor")
	else:
		t.check(mother_indices.max() < pram_indices.min(),
			"forward pram siblings draw above the mother as one actor")
