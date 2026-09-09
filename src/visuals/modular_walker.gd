class_name ModularWalker extends Node2D
## PNG presentation for a live crowd walker; it consumes movement without owning movement.

const MUSTARD_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/upper-mustard-bob-v1.png")
const RUST_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/upper-rust-curls-v1.png")
const LEGS_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/legs-denim-sneakers-v1.png")
const MANIFEST_PATH := "res://assets/illustrated/walkers/MANIFEST.json"
## The exact per-view scale is derived from the painted top-to-hem distance. This value
## remains the nominal transverse scale for tools that inspect the compositor before reset.
const VISUAL_SCALE := 0.04
const COMPARISON_OFFSET := 96.0

var direction: int = DirectionalParts.Direction.S
var heading := Vector2.DOWN
var last_displacement := Vector2.ZERO
var last_pose: Dictionary = {}
var gait := PlantedGait.new()
var manifest := DirectionalParts.new_manifest()
var sprites: Dictionary = {}
var variant := "mustard_bob"
var asset_manifest: Dictionary = {}
var registration_valid: bool = false
var _has_pose: bool = false

func _init() -> void:
	asset_manifest = _read_manifest()
	if asset_manifest.is_empty():
		return
	var hip_height: float = float(asset_manifest["hip_height"])
	gait.configure([Vector2(-2.0, -hip_height), Vector2(2.0, -hip_height)],
		10.0, 10.0, 4.0, 6.0, 3.0,
		[Vector2(-3.0, 0.0), Vector2(3.0, 0.0)], 4.0, 1.2)
	registration_valid = _register_parts() and _create_sprites()

func _ready() -> void:
	if registration_valid and not _has_pose:
		reset_at(Vector2.ZERO, Vector2.DOWN)

func apply_displacement(actual_displacement: Vector2, actual_body_position: Vector2, delta: float,
		facing: Vector2 = Vector2.ZERO) -> Dictionary:
	if not registration_valid:
		return {}
	last_displacement = actual_displacement
	if facing.length_squared() > 0.000001:
		heading = facing.normalized()
	elif actual_displacement.length_squared() > 0.000001:
		heading = actual_displacement.normalized()
	direction = DirectionalParts.select_direction(actual_displacement, heading, direction)
	last_pose = gait.advance(actual_body_position, actual_displacement, delta, heading)
	_update_sprites()
	return last_pose

func reset_at(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	if not registration_valid:
		return
	heading = facing.normalized() if facing.length_squared() > 0.000001 else Vector2.DOWN
	direction = DirectionalParts.direction_from_heading(heading)
	last_displacement = Vector2.ZERO
	gait.reset(body_position, heading)
	last_pose = gait.pose(body_position)
	_has_pose = true
	_update_sprites()

func recycle_at(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	reset_at(body_position, facing)

func set_variant(next_variant: String) -> void:
	if not registration_valid:
		return
	if manifest.has_part("upper_body", next_variant):
		variant = next_variant
		if not last_pose.is_empty():
			_update_sprites()

func registered_part_ids() -> Array[String]:
	return ["upper_body", "left_upper_leg", "right_upper_leg", "left_lower_leg", "right_lower_leg", "left_shoe", "right_shoe"]

func _register_parts() -> bool:
	var valid: bool = manifest.register_variant("upper_body", "mustard_bob", MUSTARD_TEXTURE,
		_upper_rects("mustard_bob"), Vector2.ZERO, _upper_hems("mustard_bob"), _z_orders(0))
	valid = manifest.register_variant("upper_body", "rust_curls", RUST_TEXTURE,
		_upper_rects("rust_curls"), Vector2.ZERO, _upper_hems("rust_curls"), _z_orders(0)) and valid
	for side: String in ["left", "right"]:
		for part: String in ["upper", "lower", "shoe"]:
			var part_id: String = side + "_" + (part + "_leg" if part != "shoe" else "shoe")
			var starts: Array[Vector2] = _limb_points(side, part, "start")
			valid = manifest.register_part(part_id, LEGS_TEXTURE, _limb_rects(side, part),
				Vector2.ZERO, starts, _limb_z_orders(side), "default", starts,
				_limb_points(side, part, "end")) and valid
	return valid


func _upper_rects(upper_variant: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var view: Dictionary = _upper_view(upper_variant, direction_name)
		result.append(_rect(view.get("crop", [])))
	return result


func _upper_hems(upper_variant: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var view: Dictionary = _upper_view(upper_variant, direction_name)
		result.append(_point(view.get("hem", [])))
	return result


func _limb_rects(side: String, part: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var record: Dictionary = _limb_record(direction_name, side, part)
		result.append(_rect(record.get("crop", [])))
	return result


func _limb_points(side: String, part: String, field: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var record: Dictionary = _limb_record(direction_name, side, part)
		result.append(_point(record.get(field, [])))
	return result


func _limb_z_orders(side: String) -> Array[int]:
	var result: Array[int] = []
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var limbs: Dictionary = asset_manifest.get("limbs", {})
		var direction_record: Dictionary = limbs.get(direction_name, {})
		var side_record: Dictionary = direction_record.get(side, {})
		result.append(int(side_record.get("z", 0)))
	return result


func _upper_view(upper_variant: String, direction_name: String) -> Dictionary:
	var upper_bodies: Dictionary = asset_manifest.get("upper_body", {})
	var variant_record: Dictionary = upper_bodies.get(upper_variant, {})
	var views: Dictionary = variant_record.get("views", {})
	return views.get(direction_name, {})


func _limb_record(direction_name: String, side: String, part: String) -> Dictionary:
	var limbs: Dictionary = asset_manifest.get("limbs", {})
	var direction_record: Dictionary = limbs.get(direction_name, {})
	var side_record: Dictionary = direction_record.get(side, {})
	return side_record.get(part, {})


func _rect(value: Variant) -> Rect2:
	var numbers: Array = value if value is Array else []
	if numbers.size() != 4:
		return Rect2()
	return Rect2(float(numbers[0]), float(numbers[1]), float(numbers[2]), float(numbers[3]))


func _point(value: Variant) -> Vector2:
	var numbers: Array = value if value is Array else []
	if numbers.size() != 2:
		return Vector2.INF
	return Vector2(float(numbers[0]), float(numbers[1]))


func visual_scale() -> float:
	var hem: Vector2 = _point(_upper_view(variant,
		DirectionalParts.direction_name(direction)).get("hem", []))
	var target_height: float = float(asset_manifest.get("target_height", 38.0))
	var hip_height: float = float(asset_manifest.get("hip_height", 18.0))
	return (target_height - hip_height) / maxf(hem.y, 0.001)

func _z_orders(value: int) -> Array[int]:
	var result: Array[int] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		result.append(value)
	return result

func _read_manifest() -> Dictionary:
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("cannot open walker manifest: %s" % MANIFEST_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("walker manifest is not a JSON object: %s" % MANIFEST_PATH)
		return {}
	var manifest: Dictionary = parsed
	if not _manifest_is_valid(manifest):
		return {}
	return manifest


func _manifest_is_valid(value: Dictionary) -> bool:
	var directions: Array = value.get("direction_order", [])
	if directions.size() != DirectionalParts.DIRECTION_NAMES.size():
		return _manifest_error("direction_order must contain exactly eight views")
	for index: int in DirectionalParts.DIRECTION_NAMES.size():
		if directions[index] != DirectionalParts.DIRECTION_NAMES[index]:
			return _manifest_error("direction_order must use N, NE, E, SE, S, SW, W, NW")
	if not _positive_number(value.get("target_height")) \
			or not _positive_number(value.get("hip_height")):
		return _manifest_error("target_height and hip_height must be positive numbers")
	var upper_bodies: Dictionary = value.get("upper_body", {})
	for upper_variant: String in ["mustard_bob", "rust_curls"]:
		var variant_record: Dictionary = upper_bodies.get(upper_variant, {})
		var views: Dictionary = variant_record.get("views", {})
		for direction_name: String in DirectionalParts.DIRECTION_NAMES:
			var view: Dictionary = views.get(direction_name, {})
			if not _valid_crop_and_point(view.get("crop"), view.get("hem")):
				return _manifest_error("%s %s needs a crop-local hem" % [
					upper_variant, direction_name])
	var limbs: Dictionary = value.get("limbs", {})
	for direction_name: String in DirectionalParts.DIRECTION_NAMES:
		var direction_record: Dictionary = limbs.get(direction_name, {})
		var side_order: Array = direction_record.get("side_order", [])
		if side_order.size() != 2 or not side_order.has("left") or not side_order.has("right"):
			return _manifest_error("%s needs an explicit left/right side_order" % direction_name)
		for side: String in ["left", "right"]:
			var side_record: Dictionary = direction_record.get(side, {})
			if not side_record.has("z"):
				return _manifest_error("%s %s needs an actor-local z value" % [direction_name, side])
			for part: String in ["upper", "lower", "shoe"]:
				var record: Dictionary = side_record.get(part, {})
				if not _valid_crop_and_segment(record):
					return _manifest_error("%s %s %s needs crop-local segment endpoints" % [
						direction_name, side, part])
	return true


func _valid_crop_and_point(crop_value: Variant, point_value: Variant) -> bool:
	if not _number_array(crop_value, 4) or not _number_array(point_value, 2):
		return false
	var crop: Rect2 = _rect(crop_value)
	var point: Vector2 = _point(point_value)
	return crop.size.x > 0.0 and crop.size.y > 0.0 and point.is_finite() \
		and point.x >= 0.0 and point.y >= 0.0 \
		and point.x <= crop.size.x and point.y <= crop.size.y


func _valid_crop_and_segment(record: Dictionary) -> bool:
	if not _valid_crop_and_point(record.get("crop"), record.get("start")):
		return false
	if not _valid_crop_and_point(record.get("crop"), record.get("end")):
		return false
	return _point(record["start"]).distance_squared_to(_point(record["end"])) > 0.000001


func _number_array(value: Variant, expected_size: int) -> bool:
	if not value is Array or value.size() != expected_size:
		return false
	for item: Variant in value:
		if not item is int and not item is float:
			return false
		if not is_finite(float(item)):
			return false
	return true


func _positive_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) > 0.0


func _manifest_error(message: String) -> bool:
	push_error("invalid walker manifest: %s" % message)
	return false


func _create_sprites() -> bool:
	var upper: Sprite2D = manifest.make_sprite("upper_body", direction, variant)
	if upper == null:
		return false
	upper.name = "WalkerUpperBody"
	upper.scale = Vector2.ONE * VISUAL_SCALE
	add_child(upper)
	sprites["upper_body"] = upper
	for part_id: String in ["left_upper_leg", "right_upper_leg", "left_lower_leg", "right_lower_leg", "left_shoe", "right_shoe"]:
		var leg: Sprite2D = manifest.make_sprite(part_id, direction)
		if leg == null:
			return false
		leg.name = "Walker_" + part_id
		leg.scale = Vector2.ONE * VISUAL_SCALE
		add_child(leg)
		sprites[part_id] = leg
	return true

func _update_sprites() -> void:
	if not registration_valid:
		return
	var upper: Sprite2D = sprites["upper_body"]
	manifest.update_sprite(upper, "upper_body", direction, variant)
	var hip_center: Vector2 = (last_pose["left_hip"] + last_pose["right_hip"]) * 0.5
	upper.position = hip_center
	var source_scale: float = visual_scale()
	upper.scale = Vector2.ONE * source_scale
	for side: String in ["left", "right"]:
		var hip: Vector2 = last_pose[side + "_hip"]
		var knee: Vector2 = last_pose[side + "_knee"]
		var ankle: Vector2 = last_pose[side + "_ankle"]
		var sole: Vector2 = last_pose[side + "_sole"]
		var upper_leg: Sprite2D = sprites[side + "_upper_leg"]
		var lower_leg: Sprite2D = sprites[side + "_lower_leg"]
		var shoe: Sprite2D = sprites[side + "_shoe"]
		manifest.apply_segment(upper_leg, side + "_upper_leg", direction,
			hip, knee, source_scale)
		manifest.apply_segment(lower_leg, side + "_lower_leg", direction,
			knee, ankle, source_scale)
		manifest.apply_segment(shoe, side + "_shoe", direction,
			ankle, sole, source_scale)
	_order_siblings()


func _order_siblings() -> void:
	var direction_record: Dictionary = asset_manifest["limbs"][
		DirectionalParts.direction_name(direction)]
	var order: Array = direction_record["side_order"]
	var child_index: int = 0
	for side: String in order:
		for suffix: String in ["upper_leg", "lower_leg", "shoe"]:
			move_child(sprites[side + "_" + suffix], child_index)
			child_index += 1
	move_child(sprites["upper_body"], child_index)
