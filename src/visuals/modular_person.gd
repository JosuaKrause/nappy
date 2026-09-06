class_name ModularPerson extends Node2D
## Standalone visual compositor for the registered mother and pram part sheets.
##
## The caller owns the logical body, collision and random state. This node receives the
## displacement that caller actually applied and keeps only a visual pose and child sprites.

const MOTHER_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/mother-parts-v2.png")
const PRAM_TEXTURE: Texture2D = preload("res://assets/illustrated/modular/pram-parts-v2.png")
const CELL := Vector2(160.0, 192.0)
const PRAM_CELL := Vector2(160.0, 128.0)
const VISUAL_SCALE := 0.5
const PRAM_SIDE_OFFSET := 72.0
const PRAM_GROUND_LIFT := 33.0

const MOTHER_ROWS: Dictionary = {
	"head_hair": 0, "torso_clothing": 1, "arms_hands": 2, "legs": 3, "shoes": 4,
}
const PRAM_ROWS: Dictionary = {"pram_body_basket": 0, "canopy_baby": 1, "wheels_frame": 2}
const MOTHER_ORDER: Array[String] = ["legs", "torso_clothing", "head_hair", "arms_hands", "shoes"]
const PRAM_ORDER: Array[String] = ["wheels_frame", "pram_body_basket", "canopy_baby"]
const MOTHER_PIVOTS: Dictionary = {
	"head_hair": Vector2(80.0, 28.0), "torso_clothing": Vector2(80.0, 66.0),
	"arms_hands": Vector2(80.0, 77.0), "legs": Vector2(80.0, 116.0),
	"shoes": Vector2(80.0, 184.0),
}
const PRAM_PIVOTS: Dictionary = {
	"pram_body_basket": Vector2(80.0, 74.0), "canopy_baby": Vector2(80.0, 34.0),
	"wheels_frame": Vector2(80.0, 112.0),
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

func _ready() -> void:
	if not _has_pose:
		reset_at(Vector2.ZERO, Vector2.DOWN)

## Creates or updates the persistent registered sprites without binding to gameplay nodes.
func _init() -> void:
	_register_parts()
	_create_sprites()

## Applies one measured world displacement. The supplied body position is a visual anchor only;
## callers keep ownership of their logical position and pass it back after collision resolution.
func apply_displacement(actual_displacement: Vector2, actual_body_position: Vector2, delta: float,
		facing: Vector2 = Vector2.ZERO) -> Dictionary:
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

## Settles every visual anchor for a teleport or a newly spawned actor.
func reset_at(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	visual_world_position = body_position
	heading = facing.normalized() if facing.length_squared() > 0.000001 else Vector2.DOWN
	direction = DirectionalParts.direction_from_heading(heading)
	last_displacement = Vector2.ZERO
	gait.reset(body_position, heading)
	last_pose = gait.pose(body_position)
	_update_sprites()

## Teleport is explicit so a caller cannot accidentally leave old planted anchors behind.
func teleport_to(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	reset_at(body_position, facing)

## Keeps the last stance feet planted while changing the authored facing.
func turn_to(new_facing: Vector2) -> void:
	if new_facing.length_squared() <= 0.000001:
		return
	heading = new_facing.normalized()
	direction = DirectionalParts.select_direction(Vector2.ZERO, heading, direction)
	last_displacement = Vector2.ZERO
	last_pose = gait.advance(visual_world_position, Vector2.ZERO, 0.0, heading)
	_update_sprites()

## Stopped pose has no hidden treadmill advance or foot drift.
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
	for part_id: String in MOTHER_ROWS:
		var row: int = MOTHER_ROWS[part_id]
		var rects: Array[Rect2] = []
		var z_orders: Array[int] = []
		for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
			rects.append(Rect2(Vector2(direction_index * CELL.x, row * CELL.y), CELL))
			z_orders.append((MOTHER_ORDER.find(part_id) + 1) * 10)
		mother_manifest.register_part(part_id, MOTHER_TEXTURE, rects, Vector2.ZERO,
			MOTHER_PIVOTS[part_id], z_orders)
	for part_id: String in PRAM_ROWS:
		var row: int = PRAM_ROWS[part_id]
		var rects: Array[Rect2] = []
		var z_orders: Array[int] = []
		for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
			rects.append(Rect2(Vector2(direction_index * PRAM_CELL.x, row * PRAM_CELL.y), PRAM_CELL))
			z_orders.append((PRAM_ORDER.find(part_id) + 1) * 10)
		pram_manifest.register_part(part_id, PRAM_TEXTURE, rects, Vector2.ZERO,
			PRAM_PIVOTS[part_id], z_orders)

func _create_sprites() -> void:
	for part_id: String in MOTHER_ORDER:
		var sprite: Sprite2D = mother_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * VISUAL_SCALE
		sprite.name = "Mother_" + part_id
		add_child(sprite)
		mother_sprites[part_id] = sprite
	for part_id: String in PRAM_ORDER:
		var sprite: Sprite2D = pram_manifest.make_sprite(part_id, direction)
		sprite.scale = Vector2.ONE * VISUAL_SCALE
		sprite.name = "Pram_" + part_id
		add_child(sprite)
		pram_sprites[part_id] = sprite

func _update_sprites() -> void:
	var side := Vector2(-heading.y, heading.x)
	var pram_anchor := side * PRAM_SIDE_OFFSET + Vector2(0.0, PRAM_GROUND_LIFT)
	for part_id: String in MOTHER_ORDER:
		var sprite: Sprite2D = mother_sprites[part_id]
		mother_manifest.update_sprite(sprite, part_id, direction)
		sprite.position = Vector2.ZERO
		sprite.scale = Vector2.ONE * VISUAL_SCALE
	for part_id: String in PRAM_ORDER:
		var sprite: Sprite2D = pram_sprites[part_id]
		pram_manifest.update_sprite(sprite, part_id, direction)
		sprite.position = pram_anchor
		sprite.scale = Vector2.ONE * VISUAL_SCALE
