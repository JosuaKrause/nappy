class_name PlantedGait extends RefCounted
## Distance-driven two-foot gait state for a feet-anchored sprite assembly.
##
## A stance foot stores a world-space anchor and does not move while the body passes
## over it. Lengths, offsets and lift are world pixels, so the visual pose stays legible
## at the compositor's gameplay scale. A swing begins only after actual body displacement
## reaches the step trigger; elapsed time alone cannot advance it. The helper never changes
## the logical body.

const LEFT_FOOT: int = 0
const RIGHT_FOOT: int = 1

var hip_offsets: Array[Vector2] = [Vector2(-6.0, -34.0), Vector2(6.0, -34.0)]
var foot_offsets: Array[Vector2] = [Vector2(-15.0, 0.0), Vector2(15.0, 0.0)]
var upper_leg_length: float = 17.0
var lower_leg_length: float = 17.0
var step_trigger: float = 14.0
var step_span: float = 24.0
var swing_height: float = 8.0
var ankle_height: float = 4.0
var reach_scale: float = 1.2
var rest_length_scales: Array[float] = [1.0, 1.0]

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
var _continuous: bool = false


func configure(hips: Array[Vector2], upper_length: float, lower_length: float,
		trigger: float = 14.0, swing_span: float = 24.0, lift: float = 8.0,
		feet: Array[Vector2] = [Vector2(-15.0, 0.0), Vector2(15.0, 0.0)],
		shoe_ankle_height: float = 4.0, allowed_reach_scale: float = 1.2) -> void:
	if hips.size() != 2:
		push_error("PlantedGait needs exactly two hip offsets")
		return
	hip_offsets = hips.duplicate()
	upper_leg_length = maxf(0.001, upper_length)
	lower_leg_length = maxf(0.001, lower_length)
	swing_height = maxf(0.0, lift)
	ankle_height = maxf(0.001, shoe_ankle_height)
	reach_scale = maxf(1.0, allowed_reach_scale)
	if feet.size() == 2:
		foot_offsets = feet.duplicate()
	var nominal_length: float = upper_leg_length + lower_leg_length
	for foot: int in [LEFT_FOOT, RIGHT_FOOT]:
		var rest_ankle: Vector2 = foot_offsets[foot] + Vector2(0.0, -ankle_height)
		rest_length_scales[foot] = clampf(
			hip_offsets[foot].distance_to(rest_ankle) / nominal_length, 0.001, reach_scale)
	var available_reach: float = _available_reach()
	step_trigger = minf(maxf(0.001, trigger), available_reach * 0.4)
	# One foot remains planted through the other foot's complete swing. Keeping one and a
	# half spans inside the controlled reach prevents cadence from leaving it behind. The
	# first swing also includes its trigger distance, so both limits apply.
	step_span = minf(maxf(0.001, swing_span), minf(
		maxf(0.001, available_reach / 1.5),
		maxf(0.001, available_reach - step_trigger)))
	_initialized = false


func reset(world_position: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	_body_world = world_position
	_facing = _safe_direction(facing, Vector2.DOWN)
	_feet_world = [world_position + foot_offsets[LEFT_FOOT], world_position + foot_offsets[RIGHT_FOOT]]
	_stance_world = _feet_world.duplicate()
	_swing_start = Vector2.ZERO
	_swing_target = Vector2.ZERO
	_swing_distance = 0.0
	_travel_since_step = 0.0
	_swing_foot = LEFT_FOOT
	_stepping = false
	_continuous = false
	_initialized = true


func advance(world_position: Vector2, body_displacement: Vector2, _delta: float,
		facing: Vector2 = Vector2.ZERO) -> Dictionary:
	if not _initialized:
		reset(world_position, facing if facing.length_squared() > 0.000001 else body_displacement)
	if facing.length_squared() > 0.000001:
		_facing = facing.normalized()
	elif body_displacement.length_squared() > 0.000001:
		_facing = body_displacement.normalized()
	var travel: float = body_displacement.length()
	if travel <= 0.000001:
		_body_world = world_position
		return pose(world_position)
	var movement_direction: Vector2 = body_displacement / travel
	var movement_start: Vector2 = world_position - body_displacement
	var consumed: float = 0.0
	while consumed < travel - 0.000001:
		var body_at_cursor: Vector2 = movement_start + movement_direction * consumed
		if not _stepping:
			if _continuous:
				_swing_foot = _most_extended_foot(body_at_cursor, movement_direction)
				_begin_step(body_at_cursor, movement_direction)
			else:
				var until_step: float = step_trigger - _travel_since_step
				var wait_distance: float = minf(travel - consumed, until_step)
				_travel_since_step += wait_distance
				consumed += wait_distance
				if _travel_since_step + 0.000001 < step_trigger:
					break
				body_at_cursor = movement_start + movement_direction * consumed
				_swing_foot = _most_extended_foot(body_at_cursor, movement_direction)
				_begin_step(body_at_cursor, movement_direction)
		var swing_remaining: float = step_span - _swing_distance
		var swing_travel: float = minf(travel - consumed, swing_remaining)
		_swing_distance += swing_travel
		consumed += swing_travel
		var progress: float = clampf(_swing_distance / step_span, 0.0, 1.0)
		_feet_world[_swing_foot] = _swing_start.lerp(_swing_target, progress)
		if progress >= 1.0 - 0.000001:
			_finish_step()
	_body_world = world_position
	return pose(world_position)


func pose(world_position: Vector2 = Vector2.INF) -> Dictionary:
	var at: Vector2 = _body_world if world_position == Vector2.INF else world_position
	var left_foot: Vector2 = _feet_world[LEFT_FOOT]
	var right_foot: Vector2 = _feet_world[RIGHT_FOOT]
	var left_height: float = _foot_height(LEFT_FOOT)
	var right_height: float = _foot_height(RIGHT_FOOT)
	var left_ankle: Vector2 = left_foot + Vector2(0.0, -ankle_height - left_height)
	var right_ankle: Vector2 = right_foot + Vector2(0.0, -ankle_height - right_height)
	var left_hip: Vector2 = at + hip_offsets[LEFT_FOOT]
	var right_hip: Vector2 = at + hip_offsets[RIGHT_FOOT]
	var left_knee: Vector2 = _solve_reachable_knee(
		left_hip, left_ankle, LEFT_FOOT, 1.0)
	var right_knee: Vector2 = _solve_reachable_knee(
		right_hip, right_ankle, RIGHT_FOOT, -1.0)
	return {
		"left_foot_world": left_foot,
		"right_foot_world": right_foot,
		"left_foot": left_foot - at,
		"right_foot": right_foot - at,
		"left_sole": left_foot - at + Vector2(0.0, -left_height),
		"right_sole": right_foot - at + Vector2(0.0, -right_height),
		"left_ankle": left_ankle - at,
		"right_ankle": right_ankle - at,
		"left_hip": left_hip - at,
		"right_hip": right_hip - at,
		"left_knee": left_knee - at,
		"right_knee": right_knee - at,
		"left_foot_height": left_height,
		"right_foot_height": right_height,
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


func max_reach() -> float:
	return (upper_leg_length + lower_leg_length) * reach_scale


func _begin_step(world_position: Vector2, travel_direction: Vector2) -> void:
	var forward: Vector2 = _safe_direction(travel_direction, _facing)
	_swing_start = _feet_world[_swing_foot]
	var predicted_body: Vector2 = world_position + forward * step_span
	var desired_sole: Vector2 = world_position + forward * step_span * 0.5 \
		+ foot_offsets[_swing_foot]
	_swing_target = _clamp_sole_to_reach(desired_sole, predicted_body, _swing_foot)
	_swing_distance = 0.0
	_travel_since_step = 0.0
	_stepping = true
	_continuous = true


func _finish_step() -> void:
	_feet_world[_swing_foot] = _swing_target
	_stance_world[_swing_foot] = _swing_target
	_stepping = false
	_swing_distance = 0.0
	_swing_foot = RIGHT_FOOT if _swing_foot == LEFT_FOOT else LEFT_FOOT


func _foot_height(index: int) -> float:
	if not _stepping or index != _swing_foot:
		return 0.0
	var progress: float = clampf(_swing_distance / step_span, 0.0, 1.0)
	return sin(progress * PI) * swing_height


func _solve_reachable_knee(hip: Vector2, ankle: Vector2, foot: int,
		bend_side: float) -> Vector2:
	var needed_scale: float = ankle.distance_to(hip) / (upper_leg_length + lower_leg_length)
	var extension: float = clampf(needed_scale, rest_length_scales[foot], reach_scale)
	return solve_knee(hip, ankle, upper_leg_length * extension,
		lower_leg_length * extension, bend_side)


func _clamp_sole_to_reach(sole: Vector2, body_position: Vector2, foot: int) -> Vector2:
	var hip: Vector2 = body_position + hip_offsets[foot]
	var ankle: Vector2 = sole + Vector2(0.0, -ankle_height)
	var hip_to_ankle: Vector2 = ankle - hip
	if hip_to_ankle.length() <= max_reach():
		return sole
	return hip + hip_to_ankle.normalized() * max_reach() + Vector2(0.0, ankle_height)


func _available_reach() -> float:
	var rest_reach: float = 0.0
	for foot: int in [LEFT_FOOT, RIGHT_FOOT]:
		var ankle_offset: Vector2 = foot_offsets[foot] + Vector2(0.0, -ankle_height)
		rest_reach = maxf(rest_reach, hip_offsets[foot].distance_to(ankle_offset))
	return maxf(0.001, max_reach() - rest_reach)


func _most_extended_foot(body_position: Vector2, movement_direction: Vector2) -> int:
	var predicted_body: Vector2 = body_position + movement_direction * step_span
	var left_hip: Vector2 = predicted_body + hip_offsets[LEFT_FOOT]
	var right_hip: Vector2 = predicted_body + hip_offsets[RIGHT_FOOT]
	var left_ankle: Vector2 = _feet_world[LEFT_FOOT] + Vector2(0.0, -ankle_height)
	var right_ankle: Vector2 = _feet_world[RIGHT_FOOT] + Vector2(0.0, -ankle_height)
	var left_reach: float = left_hip.distance_squared_to(left_ankle)
	var right_reach: float = right_hip.distance_squared_to(right_ankle)
	if is_equal_approx(left_reach, right_reach):
		return _swing_foot
	return LEFT_FOOT if left_reach > right_reach else RIGHT_FOOT


func _safe_direction(value: Vector2, fallback: Vector2) -> Vector2:
	return value.normalized() if value.length_squared() > 0.000001 else fallback.normalized()
