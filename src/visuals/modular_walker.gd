class_name ModularWalker extends Node2D
## PNG presentation for a live crowd walker; it consumes movement without owning movement.

const MUSTARD_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/upper-mustard-bob-v1.png")
const RUST_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/upper-rust-curls-v1.png")
const LEGS_TEXTURE: Texture2D = preload("res://assets/illustrated/walkers/legs-denim-sneakers-v1.png")
const MANIFEST_PATH := "res://assets/illustrated/walkers/MANIFEST.json"
const UPPER_SIZE := Vector2(2172.0, 724.0)
const LEGS_SIZE := Vector2(2172.0, 724.0)
const VISUAL_SCALE := 0.065
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

func _init() -> void:
	asset_manifest = _read_manifest()
	# These anchors are shared by every authored view; the PNGs retain their own transparent padding.
	gait.configure([Vector2(-5.0, -29.0), Vector2(5.0, -29.0)], 14.0, 14.0, 12.0, 20.0, 6.0,
		[Vector2(-11.0, 0.0), Vector2(11.0, 0.0)])
	_register_parts()
	_create_sprites()

func _ready() -> void:
	reset_at(Vector2.ZERO, Vector2.DOWN)

func apply_displacement(actual_displacement: Vector2, actual_body_position: Vector2, delta: float,
		facing: Vector2 = Vector2.ZERO) -> Dictionary:
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
	heading = facing.normalized() if facing.length_squared() > 0.000001 else Vector2.DOWN
	direction = DirectionalParts.direction_from_heading(heading)
	last_displacement = Vector2.ZERO
	gait.reset(body_position, heading)
	last_pose = gait.pose(body_position)
	_update_sprites()

func recycle_at(body_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	reset_at(body_position, facing)

func set_variant(next_variant: String) -> void:
	if next_variant == "rust_curls" and manifest.has_part("upper_body", next_variant):
		variant = next_variant
		if not last_pose.is_empty():
			_update_sprites()

func registered_part_ids() -> Array[String]:
	return ["upper_body", "left_upper_leg", "right_upper_leg", "left_lower_leg", "right_lower_leg", "left_shoe", "right_shoe"]

func _register_parts() -> void:
	manifest.register_variant("upper_body", "mustard_bob", MUSTARD_TEXTURE, _regions(UPPER_SIZE),
		Vector2.ZERO, _pivots(UPPER_SIZE, 0.94), _z_orders(40))
	manifest.register_variant("upper_body", "rust_curls", RUST_TEXTURE, _regions(UPPER_SIZE),
		Vector2.ZERO, _pivots(UPPER_SIZE, 0.94), _z_orders(40))
	for side: String in ["left", "right"]:
		manifest.register_part(side + "_upper_leg", LEGS_TEXTURE, _leg_regions(0.0, 240.0, side),
			Vector2.ZERO, _leg_pivots(18.0), _z_orders(10))
		manifest.register_part(side + "_lower_leg", LEGS_TEXTURE, _leg_regions(240.0, 500.0, side),
			Vector2.ZERO, _leg_pivots(12.0), _z_orders(20))
		manifest.register_part(side + "_shoe", LEGS_TEXTURE, _leg_regions(500.0, 724.0, side),
			Vector2.ZERO, _leg_pivots(214.0), _z_orders(30))

func _regions(size: Vector2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
		var source_column: int = _source_column(DirectionalParts.DIRECTION_NAMES[direction_index])
		var left := floorf(size.x * float(source_column) / 8.0)
		var right := floorf(size.x * float(source_column + 1) / 8.0)
		result.append(Rect2(left, 0.0, right - left, size.y))
	return result

func _leg_regions(top: float, bottom: float, side: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for direction_index: int in DirectionalParts.DIRECTION_NAMES.size():
		var source_column: int = _source_column(DirectionalParts.DIRECTION_NAMES[direction_index])
		var left := floorf(LEGS_SIZE.x * float(source_column) / 8.0)
		var right := floorf(LEGS_SIZE.x * float(source_column + 1) / 8.0)
		var half := (right - left) * 0.5
		result.append(Rect2(left if side == "left" else left + half, top, half, bottom - top))
	return result

func _leg_pivots(y: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		# Each leg region is one half-cell, so its pivot is local to that half-cell.
		result.append(Vector2(67.0, y))
	return result

func _pivots(size: Vector2, y_fraction: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		result.append(Vector2(size.x / 8.0 * 0.5, size.y * y_fraction))
	return result

func _z_orders(value: int) -> Array[int]:
	var result: Array[int] = []
	for _direction in DirectionalParts.DIRECTION_NAMES.size():
		result.append(value)
	return result

func _read_manifest() -> Dictionary:
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("walker manifest is not a JSON object: %s" % MANIFEST_PATH)
		return {}
	var manifest: Dictionary = parsed
	var columns: Array = manifest.get("source_columns", [])
	if columns.size() != DirectionalParts.DIRECTION_NAMES.size():
		push_error("walker manifest must map all 8 source columns")
	return manifest

func _source_column(direction_name: String) -> int:
	var columns: Array = asset_manifest.get("source_columns", [])
	var source_column: int = columns.find(direction_name)
	return source_column if source_column >= 0 else DirectionalParts.DIRECTION_NAMES.find(direction_name)

func _create_sprites() -> void:
	var upper: Sprite2D = manifest.make_sprite("upper_body", direction, variant)
	upper.name = "WalkerUpperBody"
	upper.scale = Vector2.ONE * VISUAL_SCALE
	add_child(upper)
	sprites["upper_body"] = upper
	for part_id: String in ["left_upper_leg", "right_upper_leg", "left_lower_leg", "right_lower_leg", "left_shoe", "right_shoe"]:
		var leg: Sprite2D = manifest.make_sprite(part_id, direction)
		leg.name = "Walker_" + part_id
		leg.scale = Vector2.ONE * VISUAL_SCALE
		add_child(leg)
		sprites[part_id] = leg

func _update_sprites() -> void:
	var upper: Sprite2D = sprites["upper_body"]
	manifest.update_sprite(upper, "upper_body", direction, variant)
	var hip_center: Vector2 = (last_pose["left_hip"] + last_pose["right_hip"]) * 0.5
	upper.position = hip_center
	upper.scale = Vector2.ONE * VISUAL_SCALE
	for side: String in ["left", "right"]:
		var hip: Vector2 = last_pose[side + "_hip"]
		var knee: Vector2 = last_pose[side + "_knee"]
		var foot: Vector2 = last_pose[side + "_foot"]
		var upper_leg: Sprite2D = sprites[side + "_upper_leg"]
		var lower_leg: Sprite2D = sprites[side + "_lower_leg"]
		var shoe: Sprite2D = sprites[side + "_shoe"]
		manifest.update_sprite(upper_leg, side + "_upper_leg", direction)
		manifest.update_sprite(lower_leg, side + "_lower_leg", direction)
		manifest.update_sprite(shoe, side + "_shoe", direction)
		upper_leg.position = hip
		lower_leg.position = knee
		shoe.position = foot + Vector2(0.0, -last_pose[side + "_foot_height"])
		upper_leg.rotation = _segment_rotation(hip, knee)
		lower_leg.rotation = _segment_rotation(knee, foot)
		shoe.rotation = _segment_rotation(knee, foot) if last_pose[side + "_foot_height"] > 0.0 else 0.0

func _segment_rotation(start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	return segment.angle() - Vector2.DOWN.angle() \
		if segment.length_squared() > 0.000001 else 0.0
