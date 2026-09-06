class_name ModularPerson extends Node2D
## Standalone compositor for the registered mother and pram part sheets.
##
## The caller owns the logical body, collision and random state. This node receives the
## displacement that caller actually applied and turns the solved foot pose into sprites.

const MOTHER_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/mother-parts-v3.png")
const PRAM_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/pram-parts-v2.png")
const MOTHER_MANIFEST_PATH := "res://assets/illustrated/modular/mother-parts-v3.manifest.json"
const PRAM_MANIFEST_PATH := "res://assets/illustrated/modular/pram-parts-v2.manifest.json"
const MOTHER_SCALE := 0.14
const PRAM_SCALE := 0.28
const PRAM_SIDE_OFFSET := 34.0
var mother_order: Array[String] = []
var pram_order: Array[String] = []
const LEFT_HIPS: Array[Vector2] = [Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116)]
const RIGHT_HIPS: Array[Vector2] = [Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116)]
const LEFT_KNEES: Array[Vector2] = [Vector2(68, 150), Vector2(66, 148), Vector2(64, 146), Vector2(62, 144), Vector2(68, 150), Vector2(72, 148), Vector2(74, 146), Vector2(72, 148)]
const RIGHT_KNEES: Array[Vector2] = [Vector2(92, 150), Vector2(94, 148), Vector2(96, 146), Vector2(98, 144), Vector2(92, 150), Vector2(88, 148), Vector2(86, 146), Vector2(88, 148)]
const LEFT_SOLES: Array[Vector2] = [Vector2(50, 184), Vector2(48, 184), Vector2(46, 184), Vector2(44, 184), Vector2(50, 184), Vector2(54, 184), Vector2(56, 184), Vector2(54, 184)]
const RIGHT_SOLES: Array[Vector2] = [Vector2(110, 184), Vector2(112, 184), Vector2(114, 184), Vector2(116, 184), Vector2(110, 184), Vector2(106, 184), Vector2(104, 184), Vector2(106, 184)]

var direction: int = DirectionalParts.Direction.S
var heading: Vector2 = Vector2.DOWN
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
var _has_pose := false

func _init() -> void:
	mother_asset = _read_manifest(MOTHER_MANIFEST_PATH, MOTHER_TEXTURE)
	pram_asset = _read_manifest(PRAM_MANIFEST_PATH, PRAM_TEXTURE)
	mother_order = _string_array(mother_asset.get("draw_order", []))
	pram_order = _string_array(pram_asset.get("draw_order", []))
	# These world-pixel lengths keep a normal Stroller walk visible at gameplay scale.
	gait.configure( [Vector2(-6.0, -34.0), Vector2(6.0, -34.0)], 17.0, 17.0, 14.0, 24.0, 8.0, [Vector2(-15.0, 0.0), Vector2(15.0, 0.0)])
	_register_parts()
	_create_sprites()

func _ready() -> void:
	if not _has_pose:
		reset_at(Vector2.ZERO, Vector2.DOWN)

func apply_displacement(actual_displacement: Vector2, actual_body_position: Vector2, delta: float, facing: Vector2 = Vector2.ZERO) -> Dictionary:
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
	if new_facing.length_squared() <= 0.000001:
		return
	heading = new_facing.normalized()
	direction = DirectionalParts.select_direction(Vector2.ZERO, heading, direction)
	last_displacement = Vector2.ZERO
	last_pose = gait.advance(visual_world_position, Vector2.ZERO, 0.0, heading)
	_update_sprites()

func stop_pose() -> Dictionary:
	last_displacement = Vector2.ZERO
	last_pose = gait.advance(visual_world_position, Vector2.ZERO, 0.0, heading)
	_update_sprites()
	return last_pose

func registered_mother_part_ids() -> Array[String]:
	return mother_order.duplicate()

func registered_pram_part_ids() -> Array[String]:
	return pram_order.duplicate()

func _register_parts() -> void:
	var mother_rows: Array = mother_asset.get("rows_by_layer", [])
	var mother_cell: Vector2 = _point(mother_asset.get("cell_px", []))
	var body_pivots: Dictionary = {
		"head_hair": _point(mother_asset.get("pivots", {}).get("head", [])),
		"torso_clothing": _point(mother_asset.get("pivots", {}).get("torso", [])),
		"arms_hands": _point(mother_asset.get("pivots", {}).get("left_shoulder", [])),
	}
	for part_id: String in ["head_hair", "torso_clothing", "arms_hands"]:
		_register_full_row(mother_manifest, part_id, MOTHER_TEXTURE, mother_rows.find(part_id), mother_cell,
			body_pivots[part_id], (mother_order.find(part_id) + 1) * 10)
	for part_id: String in ["left_upper_leg", "left_lower_leg", "right_upper_leg", "right_lower_leg"]:
		_register_full_row(mother_manifest, part_id, MOTHER_TEXTURE, mother_rows.find(part_id), mother_cell,
			_leg_pivots(part_id), (mother_order.find(part_id) + 1) * 10)
	for shoe_id: String in ["left_shoe", "right_shoe"]:
		var rects: Array[Rect2] = []
		var pivots: Array[Vector2] = []
		var sole_points: Array[Vector2] = LEFT_SOLES if shoe_id == "left_shoe" else RIGHT_SOLES
		var shoe_data: Dictionary = mother_asset.get("shoe_layers", {}).get("rects_by_direction", {})
		for index: int in DirectionalParts.DIRECTION_NAMES.size():
			var direction_name: String = DirectionalParts.DIRECTION_NAMES[index]
			var source_column: int = _source_column(mother_asset, direction_name)
			var local_rect: Rect2 = _rect(shoe_data.get(direction_name, {}).get(shoe_id, []))
			rects.append(Rect2(Vector2(source_column * mother_cell.x, 7.0 * mother_cell.y) + local_rect.position, local_rect.size))
			pivots.append(sole_points[index] - local_rect.position)
		mother_manifest.register_part(shoe_id, MOTHER_TEXTURE, rects, Vector2.ZERO, pivots, _z_orders((mother_order.find(shoe_id) + 1) * 10))
	var pram_rows: Array = pram_asset.get("rows_by_layer", [])
	var pram_cell: Vector2 = _point(pram_asset.get("cell_px", []))
	var pram_pivots: Dictionary = pram_asset.get("pivots", {})
	for part_id: String in ["pram_body_basket", "canopy_baby", "wheels_frame"]:
		var pivot_key: String = "body" if part_id == "pram_body_basket" else part_id
		_register_full_row(pram_manifest, part_id, PRAM_TEXTURE, pram_rows.find(part_id), pram_cell,
			_point(pram_pivots.get(pivot_key, [])), (pram_order.find(part_id) + 1) * 10)

func _register_full_row(manifest: DirectionalParts.SpriteManifest, part_id: String, texture: Texture2D, row: int, cell: Vector2, pivots: Variant, z_order: int) -> void:
	var rects: Array[Rect2] = []
	for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
		var source_column: int = _source_column(mother_asset if texture == MOTHER_TEXTURE else pram_asset,
			DirectionalParts.DIRECTION_NAMES[direction_index])
		rects.append(Rect2(Vector2(source_column * cell.x, row * cell.y), cell))
	manifest.register_part(part_id, texture, rects, Vector2.ZERO, pivots, _z_orders(z_order))

func _z_orders(value: int) -> Array[int]:
	var result: Array[int] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		result.append(value)
	return result

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(String(item))
	return result

func _source_column(asset: Dictionary, direction_name: String) -> int:
	var columns: Array[String] = _string_array(asset.get("source_columns", []))
	var source_column: int = columns.find(direction_name)
	return source_column if source_column >= 0 else DirectionalParts.DIRECTION_NAMES.find(direction_name)

func _read_manifest(path: String, texture: Texture2D) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("illustrated manifest is missing: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("illustrated manifest is not a JSON object: %s" % path)
		return {}
	var manifest: Dictionary = parsed
	for required_key: String in ["texture", "sheet_px", "cell_px", "columns", "directions", "source_columns", "rows_by_layer"]:
		if not manifest.has(required_key):
			push_error("illustrated manifest '%s' is missing '%s'" % [path, required_key])
	var directions: Array = manifest.get("directions", [])
	if directions.size() != DirectionalParts.DIRECTION_NAMES.size():
		push_error("illustrated manifest '%s' must declare all 8 directions" % path)
	else:
		for index: int in DirectionalParts.DIRECTION_NAMES.size():
			if String(directions[index]) != DirectionalParts.DIRECTION_NAMES[index]:
				push_error("illustrated manifest '%s' has direction %d out of order" % [path, index])
	var source_columns: Array = manifest.get("source_columns", [])
	if _string_array(source_columns).size() != DirectionalParts.DIRECTION_NAMES.size():
		push_error("illustrated manifest '%s' must map all 8 source columns" % path)
	var sheet_size: Vector2 = _point(manifest.get("sheet_px", []))
	var cell_size: Vector2 = _point(manifest.get("cell_px", []))
	var columns: int = int(manifest.get("columns", 0))
	var rows: Array = manifest.get("rows_by_layer", [])
	if texture.get_size() != sheet_size or sheet_size != cell_size * Vector2(columns, rows.size()):
		push_error("illustrated manifest '%s' does not match its PNG dimensions" % path)
	return manifest

func _point(value: Variant) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _rect(value: Variant) -> Rect2:
	if value is Array and value.size() == 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Rect2()

func _pram_ground_lift() -> float:
	var pivots: Dictionary = pram_asset.get("pivots", {})
	var wheel_pivot: Vector2 = _point(pivots.get("wheels_frame", []))
	var ground_y: float = float(pram_asset.get("ground_y", 0.0))
	return (wheel_pivot.y - ground_y) * PRAM_SCALE

func _leg_pivots(part_id: String) -> Array[Vector2]:
	if part_id == "left_upper_leg" or part_id == "right_upper_leg":
		return LEFT_HIPS if part_id == "left_upper_leg" else RIGHT_HIPS
	return LEFT_KNEES if part_id == "left_lower_leg" else RIGHT_KNEES

func _create_sprites() -> void:
	for part_id: String in mother_order:
		var sprite: Sprite2D = mother_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * MOTHER_SCALE
		sprite.name = "Mother_" + part_id
		add_child(sprite)
		mother_sprites[part_id] = sprite
	for part_id: String in pram_order:
		var sprite: Sprite2D = pram_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * PRAM_SCALE
		sprite.name = "Pram_" + part_id
		add_child(sprite)
		pram_sprites[part_id] = sprite

func _update_sprites() -> void:
	var side := Vector2(-heading.y, heading.x)
	var pram_anchor := side * PRAM_SIDE_OFFSET + Vector2(0.0, _pram_ground_lift())
	var hip_center: Vector2 = (last_pose["left_hip"] + last_pose["right_hip"]) * 0.5
	var source_hip_center: Vector2 = Vector2(80.0, 116.0)
	for part_id: String in ["head_hair", "torso_clothing", "arms_hands"]:
		var sprite: Sprite2D = mother_sprites[part_id]
		mother_manifest.update_sprite(sprite, part_id, direction)
		var source_pivot: Vector2 = mother_manifest.require_part(part_id).pivot_for(direction)
		var body_position: Vector2 = hip_center + (Vector2(80.0, 66.0) - source_hip_center) * MOTHER_SCALE
		if part_id == "head_hair":
			body_position += Vector2(0.0, -24.0)
		elif part_id == "arms_hands":
			body_position += Vector2(0.0, 2.0)
		sprite.position = body_position + (source_pivot - Vector2(80.0, 66.0)) * MOTHER_SCALE
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * MOTHER_SCALE
	_update_leg("left", last_pose)
	_update_leg("right", last_pose)
	_update_shoe("left", last_pose)
	_update_shoe("right", last_pose)
	for part_id: String in pram_order:
		var sprite: Sprite2D = pram_sprites[part_id]
		pram_manifest.update_sprite(sprite, part_id, direction)
		sprite.position = pram_anchor
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * PRAM_SCALE

func _update_leg(side_name: String, pose: Dictionary) -> void:
	var hip: Vector2 = pose[side_name + "_hip"]
	var knee: Vector2 = pose[side_name + "_knee"]
	var foot: Vector2 = pose[side_name + "_foot"]
	var upper: Sprite2D = mother_sprites[side_name + "_upper_leg"]
	var lower: Sprite2D = mother_sprites[side_name + "_lower_leg"]
	mother_manifest.update_sprite(upper, side_name + "_upper_leg", direction)
	mother_manifest.update_sprite(lower, side_name + "_lower_leg", direction)
	upper.position = hip
	lower.position = knee
	upper.rotation = _segment_rotation(hip, knee)
	lower.rotation = _segment_rotation(knee, foot)
	upper.scale = Vector2.ONE * MOTHER_SCALE
	lower.scale = Vector2.ONE * MOTHER_SCALE

func _update_shoe(side_name: String, pose: Dictionary) -> void:
	var sprite: Sprite2D = mother_sprites[side_name + "_shoe"]
	var foot: Vector2 = pose[side_name + "_foot"]
	var height: float = pose[side_name + "_foot_height"]
	mother_manifest.update_sprite(sprite, side_name + "_shoe", direction)
	sprite.position = foot + Vector2(0.0, -height)
	sprite.rotation = _segment_rotation(pose[side_name + "_knee"], foot) if height > 0.0 else 0.0
	sprite.scale = Vector2.ONE * MOTHER_SCALE

func _segment_rotation(start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	if segment.length_squared() <= 0.000001:
		return 0.0
	return segment.angle() - Vector2.DOWN.angle()
