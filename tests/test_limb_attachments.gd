extends RefCounted
## Render-space contracts for directional limb attachment transforms.


func run(t) -> void:
	_test_slanted_axis_endpoints(t)
	_test_axes_must_be_complete_and_crop_local(t)
	_test_walker_painted_bounds_and_static_attachments(t)
	_test_walker_motion_stays_connected_and_reachable(t)


func _test_slanted_axis_endpoints(t) -> void:
	var manifest := DirectionalParts.new_manifest()
	var texture: Texture2D = preload("res://assets/illustrated/walkers/legs-denim-sneakers-v1.png")
	var rects: Array[Rect2] = []
	var pivots: Array[Vector2] = []
	var starts: Array[Vector2] = []
	var ends: Array[Vector2] = []
	var z_orders: Array[int] = []
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		rects.append(Rect2(0.0, 0.0, 24.0, 24.0))
		pivots.append(Vector2(7.0 + direction * 0.1, 6.0))
		starts.append(Vector2(2.0, 3.0))
		ends.append(Vector2(11.0, 15.0))
		z_orders.append(direction)
	t.check(manifest.register_part("slanted", texture, rects, Vector2.ZERO, pivots,
		z_orders, "default", starts, ends), "a complete slanted segment registration is accepted")
	var sprite: Sprite2D = manifest.make_sprite("slanted", DirectionalParts.Direction.NE)
	var target_start := Vector2(-4.0, 8.0)
	var target_end := Vector2(17.0, -2.0)
	t.check(manifest.apply_segment(sprite, "slanted", DirectionalParts.Direction.NE,
		target_start, target_end, 0.25), "a non-axis-aligned limb transform is applied")
	var registration: DirectionalParts.PartRegistration = manifest.require_part("slanted")
	var rendered_start: Vector2 = sprite.transform * (
		registration.axis_start_for(DirectionalParts.Direction.NE) + sprite.offset)
	var rendered_end: Vector2 = Vector2.ZERO
	rendered_end = sprite.transform * (
		registration.axis_end_for(DirectionalParts.Direction.NE) + sprite.offset)
	t.check(rendered_start.is_equal_approx(target_start),
		"the rendered source start meets the requested proximal joint")
	t.check(rendered_end.is_equal_approx(target_end),
		"the rendered source end meets the requested distal joint")
	var source_axis: Vector2 = registration.axis_end_for(DirectionalParts.Direction.NE) \
		- registration.axis_start_for(DirectionalParts.Direction.NE)
	var source_normal := Vector2(-source_axis.y, source_axis.x).normalized()
	var source_width_point: Vector2 = registration.axis_start_for(DirectionalParts.Direction.NE) \
		+ source_normal * 4.0
	var rendered_width_point: Vector2 = sprite.transform * (source_width_point + sprite.offset)
	t.close_to(rendered_width_point.distance_to(rendered_start), 1.0,
		"transverse scale is applied once and independently of segment length")
	sprite.free()


func _test_axes_must_be_complete_and_crop_local(t) -> void:
	var manifest := DirectionalParts.new_manifest()
	var texture: Texture2D = preload("res://assets/illustrated/walkers/legs-denim-sneakers-v1.png")
	var rects: Array[Rect2] = []
	var points: Array[Vector2] = []
	var z_orders: Array[int] = []
	for _direction: int in DirectionalParts.DIRECTION_NAMES.size():
		rects.append(Rect2(0.0, 0.0, 16.0, 16.0))
		points.append(Vector2(4.0, 4.0))
		z_orders.append(0)
	t.check(not manifest.register_part("one_end", texture, rects, Vector2.ZERO,
		Vector2.ZERO, z_orders, "default", points),
		"one segment endpoint cannot invent a downward axis")
	var outside: Array[Vector2] = points.duplicate()
	outside[DirectionalParts.Direction.W] = Vector2(17.0, 4.0)
	var valid_ends: Array[Vector2] = []
	for _direction: int in DirectionalParts.DIRECTION_NAMES.size():
		valid_ends.append(Vector2(4.0, 12.0))
	t.check(not manifest.register_part("outside", texture, rects, Vector2.ZERO,
		Vector2.ZERO, z_orders, "default", outside, valid_ends),
		"whole-sheet coordinates cannot pass as crop-local segment endpoints")


func _test_walker_painted_bounds_and_static_attachments(t) -> void:
	var walker := ModularWalker.new()
	t.add_child(walker)
	t.check(walker.registration_valid, "the complete measured walker manifest registers cleanly")
	var missing_shoe: Dictionary = walker.asset_manifest.duplicate(true)
	var missing_left: Dictionary = missing_shoe["limbs"]["N"]["left"]
	missing_left.erase("shoe")
	t.check(not walker._manifest_is_valid(missing_shoe),
		"a walker manifest with a missing directional part is rejected")
	var upper_images: Dictionary = {
		"mustard_bob": preload("res://assets/illustrated/walkers/upper-mustard-bob-v1.png").get_image(),
		"rust_curls": preload("res://assets/illustrated/walkers/upper-rust-curls-v1.png").get_image(),
	}
	var legs_image: Image = preload(
		"res://assets/illustrated/walkers/legs-denim-sneakers-v1.png").get_image()
	for upper_variant: String in ["mustard_bob", "rust_curls"]:
		walker.set_variant(upper_variant)
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var facing: Vector2 = DirectionalParts.DIRECTION_VECTORS[direction]
			walker.reset_at(Vector2.ZERO, facing)
			_assert_actor_local_order(t, walker,
				"%s %s" % [upper_variant, DirectionalParts.direction_name(direction)])
			var upper_registration: DirectionalParts.PartRegistration = \
				walker.manifest.require_part("upper_body", upper_variant)
			var upper_rect: Rect2 = upper_registration.rect_for(direction)
			var painted: Rect2i = _painted_bounds(upper_images[upper_variant], upper_rect)
			t.check(painted == Rect2i(Vector2i.ZERO, Vector2i(upper_rect.size)),
				"%s %s crop is the measured painted silhouette, including its real width" % [
					upper_variant, DirectionalParts.direction_name(direction)])
			var hem: Vector2 = upper_registration.pivot_for(direction)
			t.check(_alpha_near(upper_images[upper_variant], upper_rect.position + hem, 12),
				"%s %s hem attachment is supported by painted pixels" % [
					upper_variant, DirectionalParts.direction_name(direction)])
			var upper: Sprite2D = walker.sprites["upper_body"]
			var painted_top: Vector2 = upper.transform * (Vector2(hem.x, 0.0) + upper.offset)
			var ground_y: float = maxf(walker.last_pose["left_sole"].y,
				walker.last_pose["right_sole"].y)
			t.close_to(ground_y - painted_top.y,
				float(walker.asset_manifest["target_height"]),
				"%s %s assembled walker matches the legacy painted height" % [
					upper_variant, DirectionalParts.direction_name(direction)])
			_assert_walker_attachments(t, walker, legs_image,
				"%s %s idle" % [upper_variant, DirectionalParts.direction_name(direction)])
	walker.free()


func _assert_actor_local_order(t, walker: ModularWalker, context: String) -> void:
	var direction_record: Dictionary = walker.asset_manifest["limbs"][
		DirectionalParts.direction_name(walker.direction)]
	var side_order: Array = direction_record["side_order"]
	var previous_index: int = -1
	for side: String in side_order:
		for part: String in ["upper_leg", "lower_leg", "shoe"]:
			var sprite: Sprite2D = walker.sprites[side + "_" + part]
			t.check(sprite.z_index == 0 and sprite.region_filter_clip_enabled,
				"%s %s stays inside the actor's y-sort layer and clips its atlas crop" % [
					context, sprite.name])
			t.check(sprite.get_index() > previous_index,
				"%s keeps each directional leg together in sibling order" % context)
			previous_index = sprite.get_index()
	var upper: Sprite2D = walker.sprites["upper_body"]
	t.check(upper.z_index == 0 and upper.get_index() > previous_index,
		"%s upper body remains in the actor-local sibling group" % context)


func _test_walker_motion_stays_connected_and_reachable(t) -> void:
	var walker := ModularWalker.new()
	t.add_child(walker)
	var legs_image: Image = preload(
		"res://assets/illustrated/walkers/legs-denim-sneakers-v1.png").get_image()
	for direction: int in DirectionalParts.DIRECTION_NAMES.size():
		var facing: Vector2 = DirectionalParts.DIRECTION_VECTORS[direction]
		var body := Vector2.ZERO
		walker.reset_at(body, facing)
		for frame: int in 32:
			var swing_before: int = walker.gait.step_foot()
			var stance_before: int = PlantedGait.RIGHT_FOOT \
				if swing_before == PlantedGait.LEFT_FOOT else PlantedGait.LEFT_FOOT
			var planted_before: Vector2 = _rendered_sole_world(walker, stance_before, body)
			var distance: float = 1.5 if frame % 3 else 3.0
			var displacement: Vector2 = facing * distance
			body += displacement
			walker.apply_displacement(displacement, body, 1.0 / 60.0, facing)
			if swing_before >= 0 and walker.gait.step_foot() == swing_before:
				t.check(_rendered_sole_world(walker, stance_before, body).is_equal_approx(
					planted_before), "%s stance shoe sole stays planted in world space" %
						DirectionalParts.direction_name(direction))
			_assert_walker_attachments(t, walker, legs_image,
				"%s continuous frame %d" % [DirectionalParts.direction_name(direction), frame])
			_assert_pose_reach(t, walker, "%s continuous frame %d" % [
				DirectionalParts.direction_name(direction), frame])
		var before_stop: Array[Vector2] = [walker.gait.foot_world(0), walker.gait.foot_world(1)]
		for _pause: int in 3:
			walker.apply_displacement(Vector2.ZERO, body, 0.25, facing)
		t.check(walker.gait.foot_world(0) == before_stop[0] \
			and walker.gait.foot_world(1) == before_stop[1],
			"%s zero travel cannot advance or drift either foot" %
				DirectionalParts.direction_name(direction))
		for _stutter: int in 40:
			var displacement: Vector2 = facing * 0.8
			body += displacement
			walker.apply_displacement(displacement, body, 1.0 / 60.0, facing)
			walker.apply_displacement(Vector2.ZERO, body, 0.2, facing)
			_assert_pose_reach(t, walker, "%s stop-start" %
				DirectionalParts.direction_name(direction))
		var reverse: Vector2 = -facing
		var large_displacement: Vector2 = reverse * 41.0
		body += large_displacement
		walker.apply_displacement(large_displacement, body, 0.5, reverse)
		_assert_walker_attachments(t, walker, legs_image,
			"%s reverse large-delta" % DirectionalParts.direction_name(direction))
		_assert_pose_reach(t, walker,
			"%s reverse large-delta" % DirectionalParts.direction_name(direction))
		var turn: Vector2 = Vector2(-facing.y, facing.x)
		var turn_displacement: Vector2 = turn * 17.0
		body += turn_displacement
		walker.apply_displacement(turn_displacement, body, 0.3, turn)
		_assert_walker_attachments(t, walker, legs_image,
			"%s severe turn" % DirectionalParts.direction_name(direction))
		_assert_pose_reach(t, walker, "%s severe turn" %
			DirectionalParts.direction_name(direction))
		walker.recycle_at(Vector2(60.0, -25.0), facing)
		_assert_walker_attachments(t, walker, legs_image,
			"%s recycle" % DirectionalParts.direction_name(direction))
	walker.free()


func _assert_walker_attachments(t, walker: ModularWalker, legs_image: Image,
		context: String) -> void:
	for side: String in ["left", "right"]:
		var targets: Dictionary = {
			"upper_leg": [walker.last_pose[side + "_hip"], walker.last_pose[side + "_knee"]],
			"lower_leg": [walker.last_pose[side + "_knee"], walker.last_pose[side + "_ankle"]],
			"shoe": [walker.last_pose[side + "_ankle"], walker.last_pose[side + "_sole"]],
		}
		for part: String in targets:
			var part_id: String = side + "_" + part
			var registration: DirectionalParts.PartRegistration = walker.manifest.require_part(part_id)
			var sprite: Sprite2D = walker.sprites[part_id]
			var source_start: Vector2 = registration.axis_start_for(walker.direction)
			var source_end: Vector2 = registration.axis_end_for(walker.direction)
			var rendered_start: Vector2 = sprite.transform * (source_start + sprite.offset)
			var rendered_end: Vector2 = sprite.transform * (source_end + sprite.offset)
			var expected: Array = targets[part]
			t.check(rendered_start.is_equal_approx(expected[0]),
				"%s %s painted proximal joint stays connected" % [context, part_id])
			t.check(rendered_end.is_equal_approx(expected[1]),
				"%s %s painted distal joint stays connected" % [context, part_id])
			var crop: Rect2 = registration.rect_for(walker.direction)
			t.check(_alpha_near(legs_image, crop.position + source_start, 12),
				"%s %s proximal measurement is supported by painted pixels" % [context, part_id])
			t.check(_alpha_near(legs_image, crop.position + source_end, 12),
				"%s %s distal measurement is supported by painted pixels" % [context, part_id])


func _assert_pose_reach(t, walker: ModularWalker, context: String) -> void:
	for side: String in ["left", "right"]:
		var hip: Vector2 = walker.last_pose[side + "_hip"]
		var ankle: Vector2 = walker.last_pose[side + "_ankle"]
		var reach: float = hip.distance_to(ankle)
		t.check(reach <= walker.gait.max_reach() + 0.02,
			"%s %s rendered hip-to-ankle reach stays bounded" % [context, side])


func _rendered_sole_world(walker: ModularWalker, foot: int, body: Vector2) -> Vector2:
	var side: String = "left" if foot == PlantedGait.LEFT_FOOT else "right"
	var part_id: String = side + "_shoe"
	var registration: DirectionalParts.PartRegistration = walker.manifest.require_part(part_id)
	var sprite: Sprite2D = walker.sprites[part_id]
	return body + sprite.transform * (registration.axis_end_for(walker.direction) + sprite.offset)


func _painted_bounds(image: Image, crop: Rect2) -> Rect2i:
	var minimum := Vector2i(int(crop.size.x), int(crop.size.y))
	var maximum := Vector2i(-1, -1)
	for y: int in int(crop.size.y):
		for x: int in int(crop.size.x):
			if image.get_pixel(int(crop.position.x) + x, int(crop.position.y) + y).a >= 0.5:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _alpha_near(image: Image, point: Vector2, radius: int) -> bool:
	var center := Vector2i(point)
	for y: int in range(maxi(0, center.y - radius), mini(image.get_height(), center.y + radius + 1)):
		for x: int in range(maxi(0, center.x - radius), mini(image.get_width(), center.x + radius + 1)):
			if image.get_pixel(x, y).a >= 0.5:
				return true
	return false
