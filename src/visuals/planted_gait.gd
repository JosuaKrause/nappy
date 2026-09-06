class_name PlantedGait extends RefCounted
## Distance-driven two-foot gait state for a feet-anchored sprite assembly.
##
## A stance foot stores a world-space anchor and does not move while the body passes
## over it. A swing begins only after actual body displacement reaches the step trigger;
## elapsed time alone cannot advance it. The helper never changes the logical body.

const LEFT_FOOT: int = 0
const RIGHT_FOOT: int = 1

var hip_offsets: Array[Vector2] = [Vector2(-0.12, 0.0), Vector2(0.12, 0.0)]
var upper_leg_length: float = 0.25
var lower_leg_length: float = 0.25
var step_trigger: float = 0.18
var step_span: float = 0.34

var _initialized: bool = false
var _body_world: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.DOWN
var _feet_world: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _stance_world: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _swing_start: Vector2 = Vector2.ZERO
var _swing_target: Vector2 = Vector2.ZERO
var _swing_distance: float = 0.0
var _travel_since_step: float = 0.0
var _swing_foot: int = LEFT_FOOT
var _stepping: bool = false


func configure(hips: Array[Vector2], upper_length: float, lower_length: float,
		trigger: float = 0.18, swing_span: float = 0.34) -> void:
	if hips.size() != 2:
		push_error("PlantedGait needs exactly two hip offsets")
		return
	hip_offsets = hips.duplicate()
	upper_leg_length = maxf(0.001, upper_length)
	lower_leg_length = maxf(0.001, lower_length)
	step_trigger = maxf(0.001, trigger)
	step_span = maxf(0.001, swing_span)
	_initialized = false


func reset(world_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	_body_world = world_position
	_facing = _safe_direction(facing, Vector2.DOWN)
	_feet_world = [world_position + hip_offsets[LEFT_FOOT], world_position + hip_offsets[RIGHT_FOOT]]
	_stance_world = _feet_world.duplicate()
	_swing_start = Vector2.ZERO
	_swing_target = Vector2.ZERO
	_swing_distance = 0.0
	_travel_since_step = 0.0
	_swing_foot = LEFT_FOOT
	_stepping = false
	_initialized = true


func advance(world_position: Vector2, body_displacement: Vector2, delta: float,
		facing: Vector2 = Vector2.ZERO) -> Dictionary:
	if not _initialized:
		reset(world_position, facing if facing.length_squared() > 0.000001 else body_displacement)
	if delta <= 0.0:
		_body_world = world_position
		return pose(world_position)
	if facing.length_squared() > 0.000001:
		_facing = facing.normalized()
	elif body_displacement.length_squared() > 0.000001:
		_facing = body_displacement.normalized()
	_body_world = world_position
	var travel: float = body_displacement.length()
	if travel <= 0.000001:
		return pose(world_position)
	if _stepping:
		_swing_distance += travel
		var progress: float = clampf(_swing_distance / step_span, 0.0, 1.0)
		_feet_world[_swing_foot] = _swing_start.lerp(_swing_target, progress)
		if progress >= 1.0:
			_feet_world[_swing_foot] = _swing_target
			_stance_world[_swing_foot] = _swing_target
			_stepping = false
			_travel_since_step = 0.0
			_swing_distance = 0.0
			_swing_foot = RIGHT_FOOT if _swing_foot == LEFT_FOOT else LEFT_FOOT
	else:
		_travel_since_step += travel
		_feet_world[LEFT_FOOT] = _stance_world[LEFT_FOOT]
		_feet_world[RIGHT_FOOT] = _stance_world[RIGHT_FOOT]
		if _travel_since_step >= step_trigger:
			_begin_step(world_position)
	return pose(world_position)


func pose(world_position: Vector2 = Vector2.INF) -> Dictionary:
	var at: Vector2 = _body_world if world_position == Vector2.INF else world_position
	var left_foot: Vector2 = _feet_world[LEFT_FOOT]
	var right_foot: Vector2 = _feet_world[RIGHT_FOOT]
	var left_hip: Vector2 = at + hip_offsets[LEFT_FOOT]
	var right_hip: Vector2 = at + hip_offsets[RIGHT_FOOT]
	var left_knee: Vector2 = solve_knee(left_hip, left_foot, upper_leg_length, lower_leg_length, -1.0)
	var right_knee: Vector2 = solve_knee(right_hip, right_foot, upper_leg_length, lower_leg_length, 1.0)
	return {
		"left_foot_world": left_foot,
		"right_foot_world": right_foot,
		"left_foot": left_foot - at,
		"right_foot": right_foot - at,
		"left_hip": left_hip - at,
		"right_hip": right_hip - at,
		"left_knee": left_knee - at,
		"right_knee": right_knee - at,
		"left_foot_height": _foot_height(LEFT_FOOT),
		"right_foot_height": _foot_height(RIGHT_FOOT),
		"swing_foot": _swing_foot if _stepping else -1,
		"step_progress": clampf(_swing_distance / step_span, 0.0, 1.0) if _stepping else 0.0,
	}


func foot_world(index: int) -> Vector2:
	if index < LEFT_FOOT or index > RIGHT_FOOT:
		push_error("PlantedGait foot index must be 0 or 1")
		return Vector2.ZERO
	return _feet_world[index]


func stance_anchor(index: int) -> Vector2:
	if index < LEFT_FOOT or index > RIGHT_FOOT:
		push_error("PlantedGait stance index must be 0 or 1")
		return Vector2.ZERO
	return _stance_world[index]


func is_stepping() -> bool:
	return _stepping


func step_foot() -> int:
	return _swing_foot if _stepping else -1


static func solve_knee(hip: Vector2, foot: Vector2, upper: float, lower: float,
		bend_side: float) -> Vector2:
	var to_foot: Vector2 = foot - hip
	var distance: float = clampf(to_foot.length(), 0.001, upper + lower - 0.001)
	var direction: Vector2 = to_foot.normalized()
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height_squared: float = maxf(0.0, upper * upper - along * along)
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x) * sqrt(height_squared) * bend_side
	return hip + direction * along + perpendicular


func _begin_step(world_position: Vector2) -> void:
	var forward: Vector2 = _facing
	var side: Vector2 = Vector2(-forward.y, forward.x)
	var left_or_right: float = -1.0 if _swing_foot == LEFT_FOOT else 1.0
	_swing_start = _feet_world[_swing_foot]
	_swing_target = world_position + forward * 0.26 + side * (0.12 * left_or_right)
	_swing_distance = 0.0
	_stepping = true


func _foot_height(index: int) -> float:
	if not _stepping or index != _swing_foot:
		return 0.0
	var progress: float = clampf(_swing_distance / step_span, 0.0, 1.0)
	return sin(progress * PI) * 0.07


func _safe_direction(value: Vector2, fallback: Vector2) -> Vector2:
	return value.normalized() if value.length_squared() > 0.000001 else fallback.normalized()
