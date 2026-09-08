class_name ModularPerson extends Node2D
## Measured PNG assembly for the mother and pram.
##
## The logical owner supplies applied travel and the ground origin. Every painted joint is
## projected from a crop-local registration; this presentation never moves the logical body.

const MOTHER_TEXTURE: Texture2D = preload(
	"res://assets/illustrated/modular/mother-parts-v3.png")
const PRAM_TEXTURE: Texture2D = preload(
	"res://assets/illustrated/modular/pram-layered-v3-draft-transparent.png")
const MOTHER_MANIFEST_PATH := \
	"res://assets/illustrated/modular/mother-parts-v3.manifest.json"
const PRAM_MANIFEST_PATH := \
	"res://assets/illustrated/modular/pram-layered-v3.manifest.json"
const COMPARISON_OFFSET := 96.0
const MOTHER_PARTS: Array[String] = [
	"head_hair", "torso_clothing", "left_arm", "right_arm",
	"left_upper_leg", "left_lower_leg", "right_upper_leg", "right_lower_leg",
	"left_shoe", "right_shoe",
]
const MOTHER_SEGMENTS: Array[String] = [
	"torso_clothing", "left_arm", "right_arm", "left_upper_leg", "left_lower_leg",
	"right_upper_leg", "right_lower_leg", "left_shoe", "right_shoe",
]
const PRAM_PARTS: Array[String] = ["chassis", "seat", "canopy", "baby"]

var direction: int = DirectionalParts.Direction.S
var heading := Vector2.DOWN
var visual_world_position := Vector2.ZERO
var last_displacement := Vector2.ZERO
var last_pose: Dictionary = {}
var gait := PlantedGait.new()
var mother_manifest := DirectionalParts.new_manifest()
var pram_manifest := DirectionalParts.new_manifest()
var mother_sprites: Dictionary = {}
var pram_sprites: Dictionary = {}
var mother_asset: Dictionary = {}
var pram_asset: Dictionary = {}
var mother_order: Array[String] = []
var pram_order: Array[String] = []
var _mother_scale := 1.0
var _registration_valid := false
var _has_pose := false
var _torso_polygon: Polygon2D
var _torso_transform: Sprite2D


func _init() -> void:
	mother_asset = _read_manifest(MOTHER_MANIFEST_PATH, MOTHER_TEXTURE, MOTHER_PARTS)
	pram_asset = _read_manifest(PRAM_MANIFEST_PATH, PRAM_TEXTURE, PRAM_PARTS)
	if mother_asset.is_empty() or pram_asset.is_empty():
		return
	if not _validate_assembly_metadata():
		mother_asset = {}
		pram_asset = {}
		return
	mother_order = _string_array(mother_asset["draw_order"])
	pram_order = _string_array(pram_asset["draw_order"])
	_mother_scale = float(mother_asset["base_scale"])
	var skeleton: Dictionary = mother_asset["skeleton"]
	var hips: Array[Vector2] = [
		_point(skeleton["left_hip_offset"]), _point(skeleton["right_hip_offset"])]
	var soles: Array[Vector2] = [
		_point(skeleton["left_sole_offset"]), _point(skeleton["right_sole_offset"])]
	gait.configure(hips, float(skeleton["upper_leg_length"]),
		float(skeleton["lower_leg_length"]), 8.0, 14.0, 3.5, soles,
		float(skeleton["shoe_ankle_height"]))
	_registration_valid = _register_asset(
		mother_manifest, mother_asset, MOTHER_TEXTURE, mother_order)
	_registration_valid = _register_asset(
		pram_manifest, pram_asset, PRAM_TEXTURE, pram_order) and _registration_valid
	if _registration_valid:
		_create_sprites()


func _ready() -> void:
	if _registration_valid and not _has_pose:
		reset_at(Vector2.ZERO, Vector2.DOWN)


func registration_valid() -> bool:
	return _registration_valid


func apply_displacement(actual_displacement: Vector2, actual_body_position: Vector2,
		delta: float, facing: Vector2 = Vector2.ZERO) -> Dictionary:
	if not _registration_valid:
		return {}
	visual_world_position = actual_body_position
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
	if not _registration_valid:
		return
	visual_world_position = body_position
	heading = facing.normalized() if facing.length_squared() > 0.000001 else Vector2.DOWN
	direction = DirectionalParts.direction_from_heading(heading)
	last_displacement = Vector2.ZERO
	gait.reset(body_position, heading)
	last_pose = gait.pose(body_position)
	_update_sprites()
	_has_pose = true


func teleport_to(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	reset_at(body_position, facing)


func turn_to(new_facing: Vector2) -> void:
	if not _registration_valid or new_facing.length_squared() <= 0.000001:
		return
	heading = new_facing.normalized()
	direction = DirectionalParts.select_direction(Vector2.ZERO, heading, direction)
	last_displacement = Vector2.ZERO
	last_pose = gait.advance(visual_world_position, Vector2.ZERO, 0.0, heading)
	_update_sprites()


func stop_pose() -> Dictionary:
	if not _registration_valid:
		return {}
	last_displacement = Vector2.ZERO
	last_pose = gait.advance(visual_world_position, Vector2.ZERO, 0.0, heading)
	_update_sprites()
	return last_pose


func registered_mother_part_ids() -> Array[String]:
	return mother_order.duplicate()


func registered_pram_part_ids() -> Array[String]:
	return pram_order.duplicate()


## Returns a registered crop point after the live Sprite2D transform.
func source_point_in_actor(part_id: String, source_point: Vector2) -> Vector2:
	var sprite: Sprite2D = mother_sprites.get(part_id) as Sprite2D
	if sprite == null:
		return Vector2.INF
	return sprite.transform * (source_point + sprite.offset)


func _register_asset(manifest: DirectionalParts.SpriteManifest, asset: Dictionary,
		texture: Texture2D, order: Array[String]) -> bool:
	var parts: Dictionary = asset["parts"]
	var valid := true
	for part_id: String in order:
		var part: Dictionary = parts[part_id]
		var rects: Array[Rect2] = _rect_array(part["crops"])
		var pivots: Array[Vector2] = _point_array(part["pivots"])
		var z_orders: Array[int] = _z_orders(asset, part_id)
		var starts: Variant = null
		var ends: Variant = null
		if part.has("axis_start"):
			starts = _point_array(part["axis_start"])
			ends = _point_array(part["axis_end"])
		valid = manifest.register_part(part_id, texture, rects, Vector2.ZERO,
			pivots, z_orders, "default", starts, ends) and valid
	return valid


func _create_sprites() -> void:
	for part_id: String in mother_order:
		var sprite: Sprite2D = mother_manifest.make_sprite(part_id, direction)
		if sprite == null:
			_registration_valid = false
			return
		sprite.name = "Mother_" + part_id
		if part_id == "torso_clothing":
			sprite.visible = false
			_torso_transform = sprite
			add_child(sprite)
			_torso_polygon = Polygon2D.new()
			_torso_polygon.name = "Mother_torso_clothing"
			_torso_polygon.texture = MOTHER_TEXTURE
			add_child(_torso_polygon)
		else:
			add_child(sprite)
		mother_sprites[part_id] = sprite
	for part_id: String in pram_order:
		var sprite: Sprite2D = pram_manifest.make_sprite(part_id, direction)
		if sprite == null:
			_registration_valid = false
			return
		sprite.name = "Pram_" + part_id
		add_child(sprite)
		pram_sprites[part_id] = sprite


func _update_sprites() -> void:
	var hip_center: Vector2 = (last_pose["left_hip"] + last_pose["right_hip"]) * 0.5
	var skeleton: Dictionary = mother_asset["skeleton"]
	var neck := Vector2(hip_center.x, -float(skeleton["neck_height"]))
	_update_torso(neck, hip_center)
	_update_rigid("head_hair", neck)
	for side: String in ["left", "right"]:
		_update_leg(side)
		_update_shoe(side)
	_update_pram()
	_update_arms()
	_apply_directional_order()


func _update_torso(neck: Vector2, hip_center: Vector2) -> void:
	if not mother_manifest.apply_segment(_torso_transform, "torso_clothing", direction,
			neck, hip_center, _mother_scale):
		return
	var part: Dictionary = mother_asset["parts"]["torso_clothing"]
	var polygons: Array = part["core_polygons"]
	var source_polygon: Array = polygons[direction]
	var registration: DirectionalParts.PartRegistration = \
		mother_manifest.require_part("torso_clothing")
	var pivot: Vector2 = registration.pivot_for(direction)
	var crop: Rect2 = registration.rect_for(direction)
	var vertices := PackedVector2Array()
	var ultraviolet := PackedVector2Array()
	for value: Variant in source_polygon:
		var point: Vector2 = _point(value)
		vertices.append(point - pivot)
		ultraviolet.append(crop.position + point)
	_torso_polygon.polygon = vertices
	_torso_polygon.uv = ultraviolet
	_torso_polygon.transform = _torso_transform.transform


func _update_rigid(part_id: String, target: Vector2) -> void:
	var sprite: Sprite2D = mother_sprites[part_id]
	if not mother_manifest.update_sprite(sprite, part_id, direction):
		return
	sprite.position = target
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE * _mother_scale


func _update_leg(side: String) -> void:
	mother_manifest.apply_segment(mother_sprites[side + "_upper_leg"],
		side + "_upper_leg", direction, last_pose[side + "_hip"],
		last_pose[side + "_knee"], _mother_scale)
	mother_manifest.apply_segment(mother_sprites[side + "_lower_leg"],
		side + "_lower_leg", direction, last_pose[side + "_knee"],
		last_pose[side + "_ankle"], _mother_scale)


func _update_shoe(side: String) -> void:
	mother_manifest.apply_segment(mother_sprites[side + "_shoe"], side + "_shoe",
		direction, last_pose[side + "_ankle"], last_pose[side + "_sole"], _mother_scale)


func _update_pram() -> void:
	var pram_anchor := Vector2(
		heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.PRAM_DISTANCE
	var scales: Array = pram_asset["scale_by_direction"]
	var scale := float(scales[direction])
	for part_id: String in pram_order:
		var sprite: Sprite2D = pram_sprites[part_id]
		pram_manifest.update_sprite(sprite, part_id, direction)
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * scale
	var chassis: Sprite2D = pram_sprites["chassis"]
	var chassis_part: Dictionary = pram_asset["parts"]["chassis"]
	chassis.position = pram_anchor + _point(chassis_part["assembly_targets"][direction])
	var seat: Sprite2D = pram_sprites["seat"]
	seat.position = _pram_source_point(chassis, chassis_part["seat_contacts"])
	var seat_part: Dictionary = pram_asset["parts"]["seat"]
	pram_sprites["canopy"].position = _pram_source_point(
		seat, seat_part["canopy_contacts"])
	pram_sprites["baby"].position = _pram_source_point(
		seat, seat_part["baby_contacts"])


func _pram_source_point(sprite: Sprite2D, points: Array) -> Vector2:
	return sprite.transform * (_point(points[direction]) + sprite.offset)


func _update_arms() -> void:
	var shoulders_by_direction: Array = mother_asset["skeleton"]["shoulders_by_direction"]
	var shoulders: Array = shoulders_by_direction[direction]
	var chassis: Sprite2D = pram_sprites["chassis"]
	var chassis_part: Dictionary = pram_asset["parts"]["chassis"]
	for side_index: int in 2:
		var side := "left" if side_index == 0 else "right"
		var contacts: Array = chassis_part[side + "_hand_contacts"]
		var hand_target: Vector2 = chassis.transform * (
			_point(contacts[direction]) + chassis.offset)
		mother_manifest.apply_segment(mother_sprites[side + "_arm"], side + "_arm",
			direction, _point(shoulders[side_index]), hand_target, _mother_scale)


func _apply_directional_order() -> void:
	var direction_name := String(DirectionalParts.DIRECTION_NAMES[direction])
	var mother_layers: Array = mother_asset["per_direction_order"][direction_name]
	var pram_layers: Array = pram_asset["per_direction_order"][direction_name]
	var actor_layers: Array = []
	if heading.y < -0.001:
		actor_layers.append_array(pram_layers)
		actor_layers.append_array(mother_layers)
	else:
		actor_layers.append_array(mother_layers)
		actor_layers.append_array(pram_layers)
	for part_id: String in actor_layers:
		var child: CanvasItem
		if part_id == "torso_clothing":
			child = _torso_polygon
		elif mother_sprites.has(part_id):
			child = mother_sprites[part_id]
		else:
			child = pram_sprites[part_id]
		child.z_index = 0
		move_child(child, get_child_count() - 1)


func _read_manifest(path: String, texture: Texture2D,
		required_parts: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _manifest_error(path, "file is missing")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _manifest_error(path, "root is not a JSON object")
	var asset: Dictionary = parsed
	for key: String in ["texture", "sheet_px", "directions", "source_columns",
			"draw_order", "parts", "per_direction_order"]:
		if not asset.has(key):
			return _manifest_error(path, "missing '%s'" % key)
	if texture.get_size() != _point(asset["sheet_px"]):
		return _manifest_error(path, "PNG dimensions do not match sheet_px")
	var directions: Array[String] = _string_array(asset["directions"])
	var source_columns: Array[String] = _string_array(asset["source_columns"])
	if directions.size() != DirectionalParts.DIRECTION_NAMES.size():
		return _manifest_error(path, "directions are not canonical N clockwise")
	for index: int in DirectionalParts.DIRECTION_NAMES.size():
		if directions[index] != DirectionalParts.DIRECTION_NAMES[index]:
			return _manifest_error(path, "directions are not canonical N clockwise")
	if source_columns.size() != directions.size():
		return _manifest_error(path, "source_columns does not map eight drawings")
	for direction_name: String in directions:
		if source_columns.count(direction_name) != 1:
			return _manifest_error(path, "source direction '%s' is missing or duplicated" %
				direction_name)
	var parts: Dictionary = asset["parts"]
	var order: Array[String] = _string_array(asset["draw_order"])
	if order.size() != required_parts.size():
		return _manifest_error(path, "draw_order must contain exactly the registered parts")
	for part_id: String in order:
		if not parts.has(part_id) or order.count(part_id) != 1:
			return _manifest_error(path, "draw_order contains missing or duplicate part '%s'" % part_id)
	for part_id: String in required_parts:
		if not parts.has(part_id) or order.count(part_id) != 1:
			return _manifest_error(path, "required part '%s' is missing or unordered" % part_id)
		var part: Dictionary = parts[part_id]
		for key: String in ["crops", "pivots"]:
			var values: Array = part.get(key, [])
			if values.size() != directions.size():
				return _manifest_error(path, "part '%s' needs eight %s" % [part_id, key])
		var has_start := part.has("axis_start")
		if has_start != part.has("axis_end"):
			return _manifest_error(path, "part '%s' has a partial segment axis" % part_id)
		if MOTHER_SEGMENTS.has(part_id) and not has_start:
			return _manifest_error(path,
				"mother segment '%s' needs measured endpoints" % part_id)
		if has_start and (part["axis_start"].size() != directions.size() \
				or part["axis_end"].size() != directions.size()):
			return _manifest_error(path, "part '%s' needs eight complete axes" % part_id)
	var per_direction: Dictionary = asset["per_direction_order"]
	for direction_name: String in directions:
		if not per_direction.has(direction_name):
			return _manifest_error(path, "missing layer order for '%s'" % direction_name)
		var layers: Array[String] = _string_array(per_direction[direction_name])
		if layers.size() != order.size():
			return _manifest_error(path, "layer order '%s' has the wrong part count" % direction_name)
		for part_id: String in order:
			if layers.count(part_id) != 1:
				return _manifest_error(path,
					"layer order '%s' must contain '%s' once" % [direction_name, part_id])
	return asset


func _manifest_error(path: String, message: String) -> Dictionary:
	push_error("illustrated manifest '%s': %s" % [path, message])
	return {}


func _validate_assembly_metadata() -> bool:
	for key: String in ["base_scale", "skeleton"]:
		if not mother_asset.has(key):
			_manifest_error(MOTHER_MANIFEST_PATH, "missing '%s'" % key)
			return false
	var skeleton: Dictionary = mother_asset["skeleton"]
	for key: String in ["neck_height", "upper_leg_length", "lower_leg_length",
			"shoe_ankle_height", "left_hip_offset", "right_hip_offset",
			"left_sole_offset", "right_sole_offset", "shoulders_by_direction"]:
		if not skeleton.has(key):
			_manifest_error(MOTHER_MANIFEST_PATH, "skeleton is missing '%s'" % key)
			return false
	var shoulders: Array = skeleton["shoulders_by_direction"]
	if shoulders.size() != DirectionalParts.DIRECTION_NAMES.size():
		_manifest_error(MOTHER_MANIFEST_PATH, "skeleton needs eight shoulder pairs")
		return false
	for pair: Variant in shoulders:
		if not pair is Array or pair.size() != 2:
			_manifest_error(MOTHER_MANIFEST_PATH, "each direction needs two shoulders")
			return false
	var torso: Dictionary = mother_asset["parts"]["torso_clothing"]
	if not torso.has("core_polygons") \
			or torso["core_polygons"].size() != DirectionalParts.DIRECTION_NAMES.size():
		_manifest_error(MOTHER_MANIFEST_PATH, "torso needs eight sleeve-free core polygons")
		return false
	var mother_image := MOTHER_TEXTURE.get_image()
	for part_id: String in MOTHER_SEGMENTS:
		var part: Dictionary = mother_asset["parts"][part_id]
		if not part.has("axis_start") or not part.has("axis_end"):
			_manifest_error(MOTHER_MANIFEST_PATH,
				"mother segment '%s' needs measured endpoints" % part_id)
			return false
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := _rect(part["crops"][direction])
			for field: String in ["axis_start", "axis_end"]:
				if not _source_has_alpha(mother_image,
						crop.position + _point(part[field][direction])):
					_manifest_error(MOTHER_MANIFEST_PATH,
						"%s %s %s is not on painted source art" % [
							part_id, DirectionalParts.DIRECTION_NAMES[direction], field])
					return false
	if not pram_asset.has("scale_by_direction") \
			or pram_asset["scale_by_direction"].size() != DirectionalParts.DIRECTION_NAMES.size():
		_manifest_error(PRAM_MANIFEST_PATH, "pram needs eight measured scales")
		return false
	for scale: Variant in pram_asset["scale_by_direction"]:
		if float(scale) <= 0.0:
			_manifest_error(PRAM_MANIFEST_PATH, "pram scales must be positive")
			return false
	var chassis: Dictionary = pram_asset["parts"]["chassis"]
	var chassis_crops: Array = chassis["crops"]
	var pram_image := PRAM_TEXTURE.get_image()
	for key: String in [
			"assembly_targets", "seat_contacts", "left_hand_contacts", "right_hand_contacts"]:
		if not chassis.has(key) \
				or chassis[key].size() != DirectionalParts.DIRECTION_NAMES.size():
			_manifest_error(PRAM_MANIFEST_PATH,
				"chassis needs eight %s" % key)
			return false
		if key == "assembly_targets":
			continue
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := _rect(chassis_crops[direction])
			if not _source_has_alpha(pram_image,
					crop.position + _point(chassis[key][direction])):
				_manifest_error(PRAM_MANIFEST_PATH,
					"%s %s is not on painted chassis art" % [
						DirectionalParts.DIRECTION_NAMES[direction], key])
				return false
	var seat: Dictionary = pram_asset["parts"]["seat"]
	var seat_crops: Array = seat["crops"]
	for key: String in ["canopy_contacts", "baby_contacts"]:
		if not seat.has(key) \
				or seat[key].size() != DirectionalParts.DIRECTION_NAMES.size():
			_manifest_error(PRAM_MANIFEST_PATH, "seat needs eight %s" % key)
			return false
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := _rect(seat_crops[direction])
			if not _source_has_alpha(pram_image,
					crop.position + _point(seat[key][direction])):
				_manifest_error(PRAM_MANIFEST_PATH,
					"%s %s is not on painted seat art" % [
						DirectionalParts.DIRECTION_NAMES[direction], key])
				return false
	for part_id: String in ["seat", "canopy", "baby"]:
		var part: Dictionary = pram_asset["parts"][part_id]
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			var crop := _rect(part["crops"][direction])
			if not _source_has_alpha(pram_image,
					crop.position + _point(part["pivots"][direction])):
				_manifest_error(PRAM_MANIFEST_PATH,
					"%s %s pivot is not on painted source art" % [
						DirectionalParts.DIRECTION_NAMES[direction], part_id])
				return false
	return true


func _source_has_alpha(image: Image, point: Vector2, radius: int = 4) -> bool:
	var center := Vector2i(roundi(point.x), roundi(point.y))
	for y: int in range(maxi(0, center.y - radius),
			mini(image.get_height(), center.y + radius + 1)):
		for x: int in range(maxi(0, center.x - radius),
				mini(image.get_width(), center.x + radius + 1)):
			if image.get_pixel(x, y).a > 0.1:
				return true
	return false


func _z_orders(_asset: Dictionary, _part_id: String) -> Array[int]:
	var result: Array[int] = []
	for _direction_name: String in DirectionalParts.DIRECTION_NAMES:
		result.append(0)
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(String(item))
	return result


func _point_array(value: Variant) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if value is Array:
		for item: Variant in value:
			result.append(_point(item))
	return result


func _rect_array(value: Variant) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if value is Array:
		for item: Variant in value:
			result.append(_rect(item))
	return result


func _point(value: Variant) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.INF


func _rect(value: Variant) -> Rect2:
	if value is Array and value.size() == 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Rect2()
