class_name ModularPerson extends Node2D
## Standalone compositor for the registered mother and pram part sheets.
##
## The caller owns the logical body, collision and random state. This node receives the
## displacement that caller actually applied and turns the solved foot pose into sprites.

const MOTHER_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/mother-parts-v3.png")
const PRAM_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/pram-parts-v2.png")
const CELL := Vector2(160.0, 192.0)
const PRAM_CELL := Vector2(160.0, 128.0)
const MOTHER_SCALE := 0.14
const PRAM_SCALE := 0.28
const PRAM_SIDE_OFFSET := 34.0
const PRAM_GROUND_Y := 118.0
const PRAM_WHEEL_PIVOT_Y := 112.0
const PRAM_GROUND_LIFT := (PRAM_WHEEL_PIVOT_Y - PRAM_GROUND_Y) * PRAM_SCALE
const BODY_ROWS: Dictionary = {"head_hair": 0, "torso_clothing": 1, "arms_hands": 2}
const LEG_ROWS: Dictionary = {"left_upper_leg": 3, "left_lower_leg": 4, "right_upper_leg": 5, "right_lower_leg": 6}
const PRAM_ROWS: Dictionary = {"pram_body_basket": 0, "canopy_baby": 1, "wheels_frame": 2}
const MOTHER_ORDER: Array[String] = ["left_upper_leg", "left_lower_leg", "right_upper_leg", "right_lower_leg", "torso_clothing", "head_hair", "arms_hands", "left_shoe", "right_shoe"]
const PRAM_ORDER: Array[String] = ["wheels_frame", "pram_body_basket", "canopy_baby"]
const BODY_PIVOTS: Dictionary = {"head_hair": Vector2(80, 28), "torso_clothing": Vector2(80, 66), "arms_hands": Vector2(80, 77)}
const PRAM_PIVOTS: Dictionary = {"pram_body_basket": Vector2(80, 74), "canopy_baby": Vector2(80, 34), "wheels_frame": Vector2(80, 112)}
const LEFT_HIPS: Array[Vector2] = [Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116), Vector2(68, 116)]
const RIGHT_HIPS: Array[Vector2] = [Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116), Vector2(92, 116)]
const LEFT_KNEES: Array[Vector2] = [Vector2(68, 150), Vector2(66, 148), Vector2(64, 146), Vector2(62, 144), Vector2(68, 150), Vector2(72, 148), Vector2(74, 146), Vector2(72, 148)]
const RIGHT_KNEES: Array[Vector2] = [Vector2(92, 150), Vector2(94, 148), Vector2(96, 146), Vector2(98, 144), Vector2(92, 150), Vector2(88, 148), Vector2(86, 146), Vector2(88, 148)]
const LEFT_SOLES: Array[Vector2] = [Vector2(50, 184), Vector2(48, 184), Vector2(46, 184), Vector2(44, 184), Vector2(50, 184), Vector2(54, 184), Vector2(56, 184), Vector2(54, 184)]
const RIGHT_SOLES: Array[Vector2] = [Vector2(110, 184), Vector2(112, 184), Vector2(114, 184), Vector2(116, 184), Vector2(110, 184), Vector2(106, 184), Vector2(104, 184), Vector2(106, 184)]
const SHOE_RECTS: Dictionary = {
	"left_shoe": [Rect2(27, 19, 46, 63), Rect2(38, 18, 49, 61), Rect2(45, 33, 56, 52), Rect2(46, 20, 56, 79), Rect2(24, 19, 51, 48), Rect2(19, 48, 55, 48), Rect2(0, 21, 58, 78), Rect2(0, 37, 84, 56)],
	"right_shoe": [Rect2(86, 19, 44, 63), Rect2(102, 34, 54, 56), Rect2(102, 49, 58, 49), Rect2(102, 34, 56, 65), Rect2(85, 54, 44, 48), Rect2(75, 19, 51, 49), Rect2(52, 34, 60, 65), Rect2(85, 11, 45, 52)],
}

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
var _has_pose := false

func _init() -> void:
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
	return MOTHER_ORDER.duplicate()

func registered_pram_part_ids() -> Array[String]:
	return PRAM_ORDER.duplicate()

func _register_parts() -> void:
	for part_id: String in BODY_ROWS:
		_register_full_row(mother_manifest, part_id, MOTHER_TEXTURE, BODY_ROWS[part_id], CELL, BODY_PIVOTS[part_id], (MOTHER_ORDER.find(part_id) + 1) * 10)
	for part_id: String in LEG_ROWS:
		_register_full_row(mother_manifest, part_id, MOTHER_TEXTURE, LEG_ROWS[part_id], CELL, _leg_pivots(part_id), (MOTHER_ORDER.find(part_id) + 1) * 10)
	for shoe_id: String in ["left_shoe", "right_shoe"]:
		var rects: Array[Rect2] = []
		var pivots: Array[Vector2] = []
		var sole_points: Array[Vector2] = LEFT_SOLES if shoe_id == "left_shoe" else RIGHT_SOLES
		for index: int in DirectionalParts.DIRECTION_NAMES.size():
			var local_rect: Rect2 = SHOE_RECTS[shoe_id][index]
			rects.append(Rect2(Vector2(index * CELL.x, 7.0 * CELL.y) + local_rect.position, local_rect.size))
			pivots.append(sole_points[index] - local_rect.position)
		mother_manifest.register_part(shoe_id, MOTHER_TEXTURE, rects, Vector2.ZERO, pivots, _z_orders((MOTHER_ORDER.find(shoe_id) + 1) * 10))
	for part_id: String in PRAM_ROWS:
		_register_full_row(pram_manifest, part_id, PRAM_TEXTURE, PRAM_ROWS[part_id], PRAM_CELL, PRAM_PIVOTS[part_id], (PRAM_ORDER.find(part_id) + 1) * 10)

func _register_full_row(manifest: DirectionalParts.SpriteManifest, part_id: String, texture: Texture2D, row: int, cell: Vector2, pivots: Variant, z_order: int) -> void:
	var rects: Array[Rect2] = []
	for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
		rects.append(Rect2(Vector2(direction_index * cell.x, row * cell.y), cell))
	manifest.register_part(part_id, texture, rects, Vector2.ZERO, pivots, _z_orders(z_order))

func _z_orders(value: int) -> Array[int]:
	var result: Array[int] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		result.append(value)
	return result

func _leg_pivots(part_id: String) -> Array[Vector2]:
	if part_id == "left_upper_leg" or part_id == "right_upper_leg":
		return LEFT_HIPS if part_id == "left_upper_leg" else RIGHT_HIPS
	return LEFT_KNEES if part_id == "left_lower_leg" else RIGHT_KNEES

func _create_sprites() -> void:
	for part_id: String in MOTHER_ORDER:
		var sprite: Sprite2D = mother_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * MOTHER_SCALE
		sprite.name = "Mother_" + part_id
		add_child(sprite)
		mother_sprites[part_id] = sprite
	for part_id: String in PRAM_ORDER:
		var sprite: Sprite2D = pram_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * PRAM_SCALE
		sprite.name = "Pram_" + part_id
		add_child(sprite)
		pram_sprites[part_id] = sprite

func _update_sprites() -> void:
	var side := Vector2(-heading.y, heading.x)
	var pram_anchor := side * PRAM_SIDE_OFFSET + Vector2(0.0, PRAM_GROUND_LIFT)
	for part_id: String in ["head_hair", "torso_clothing", "arms_hands"]:
		var sprite: Sprite2D = mother_sprites[part_id]
		mother_manifest.update_sprite(sprite, part_id, direction)
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * MOTHER_SCALE
	_update_leg("left", last_pose)
	_update_leg("right", last_pose)
	_update_shoe("left", last_pose)
	_update_shoe("right", last_pose)
	for part_id: String in PRAM_ORDER:
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
	return segment.angle() - DirectionalParts.DIRECTION_VECTORS[direction].angle()
