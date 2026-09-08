extends RefCounted
## Render-space contracts for directional limb attachment transforms.


func run(t) -> void:
	_test_slanted_axis_endpoints(t)
	_test_axes_must_be_complete_and_crop_local(t)


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
