class_name ActorMotion extends Node3D
## Advances an actor's visual pose from distance travelled.
##
## The configured actor is a visual Node3D, not a gameplay body. `advance()` never
## changes its position or a gameplay root; it rotates the visual heading, poses
## articulated children, and rolls named wheels. If no caller invokes `advance`,
## time does not move and the pose is paused.

const WALK_STRIDE: float = 1.45
const RUN_STRIDE: float = 2.45

var _actor: Node3D
var _kind: String = "person"
var _walk_distance: float = 0.0
var _idle_time: float = 0.0
var _wheel_distance: float = 0.0
var _steer_angle: float = 0.0
var _last_heading: float = 0.0
var _has_heading: bool = false
var _rest_y: float = 0.0
var _rest_torso_y: float = 0.0
var _rest_hip_rotation: float = 0.0
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _torso: Node3D
var _wheel_spins: Array[Node3D] = []
var _wheel_radii: Array[float] = []
var _front_wheels: Array[Node3D] = []


func configure(actor: Node3D, kind: String) -> void:
	_actor = actor
	_kind = kind
	_walk_distance = 0.0
	_idle_time = 0.0
	_wheel_distance = 0.0
	_steer_angle = 0.0
	_has_heading = false
	_rest_y = actor.position.y
	_left_leg = _find_node(actor, "LeftLegPivot")
	_right_leg = _find_node(actor, "RightLegPivot")
	_left_arm = _find_node(actor, "LeftArmPivot")
	_right_arm = _find_node(actor, "RightArmPivot")
	_torso = _find_node(actor, "Torso")
	if _torso != null:
		_rest_torso_y = _torso.position.y
	_rest_hip_rotation = actor.rotation.z
	_wheel_spins.clear()
	_wheel_radii.clear()
	_front_wheels.clear()
	for node: Node in actor.find_children("Wheel*", "Node3D", true, false):
		var wheel: Node3D = node as Node3D
		if wheel == null:
			continue
		if not (wheel.name.ends_with("Left") or wheel.name.ends_with("Right")):
			continue
		var spin: Node3D = _find_node(wheel, "WheelSpin")
		if spin != null:
			_wheel_spins.append(spin)
			var radius_value: Variant = wheel.get_meta("wheel_radius", 0.125)
			_wheel_radii.append(float(radius_value))
		if wheel.name.begins_with("WheelFront"):
			_front_wheels.append(wheel)


func advance(delta: float, speed: float, heading: float) -> void:
	if _actor == null:
		return
	if delta <= 0.0:
		return
	if not _has_heading:
		_last_heading = heading
		_has_heading = true
	_actor.rotation.y = heading
	var moving: bool = absf(speed) > 0.01
	if moving:
		_walk_distance += absf(speed) * delta
		_idle_time += delta
		_apply_walk(speed, delta)
	else:
		_idle_time += delta
		_apply_idle(delta)
	if _kind == "pram" or _kind == "car" or _kind == "van" or _kind == "truck" or _kind == "armored":
		_roll_wheels(speed, delta, heading)
	_last_heading = heading


func _apply_walk(speed: float, delta: float) -> void:
	var stride: float = RUN_STRIDE if absf(speed) > 3.6 else WALK_STRIDE
	var phase: float = _walk_distance * TAU / stride
	var amplitude: float = 0.43 if absf(speed) < 1.5 else 0.62
	var swing: float = sin(phase) * amplitude
	_actor.position.y = lerpf(_actor.position.y, _rest_y + sin(phase * 0.5) * 0.003, minf(1.0, delta * 8.0))
	if _is_vehicle():
		_actor.rotation.z = _rest_hip_rotation
		return
	if _torso != null:
		_torso.position.y = lerpf(_torso.position.y, _rest_torso_y, minf(1.0, delta * 8.0))
	if _left_leg != null:
		_left_leg.rotation.x = lerp_angle(_left_leg.rotation.x, swing, minf(1.0, delta * 10.0))
	if _right_leg != null:
		_right_leg.rotation.x = lerp_angle(_right_leg.rotation.x, -swing, minf(1.0, delta * 10.0))
	if _left_arm != null:
		_left_arm.rotation.x = lerp_angle(_left_arm.rotation.x, -swing * 0.72, minf(1.0, delta * 10.0))
	if _right_arm != null:
		_right_arm.rotation.x = lerp_angle(_right_arm.rotation.x, swing * 0.72, minf(1.0, delta * 10.0))
	if _kind == "mother" or _kind == "person":
		# A mother keeps both hands close to the forward handle while her
		# weight still shifts through the legs.
		if _kind == "mother":
			if _left_arm != null:
				_left_arm.rotation.x = lerp_angle(_left_arm.rotation.x, -0.12 + sin(phase) * 0.06, minf(1.0, delta * 10.0))
				if _right_arm != null:
					_right_arm.rotation.x = lerp_angle(_right_arm.rotation.x, -0.12 - sin(phase) * 0.06, minf(1.0, delta * 10.0))
	_actor.rotation.z = lerpf(_actor.rotation.z, _rest_hip_rotation + sin(phase * 0.5) * 0.025, minf(1.0, delta * 8.0))


func _apply_idle(delta: float) -> void:
	var breath: float = sin(_idle_time * TAU * 0.72) * 0.012
	if _torso != null:
		_torso.position.y = lerpf(_torso.position.y, _rest_torso_y + breath, minf(1.0, delta * 6.0))
	if _left_leg != null:
		_left_leg.rotation.x = lerp_angle(_left_leg.rotation.x, sin(_idle_time * TAU * 0.37) * 0.025, minf(1.0, delta * 6.0))
	if _right_leg != null:
		_right_leg.rotation.x = lerp_angle(_right_leg.rotation.x, -sin(_idle_time * TAU * 0.37) * 0.025, minf(1.0, delta * 6.0))
	if _left_arm != null:
		_left_arm.rotation.x = lerp_angle(_left_arm.rotation.x, -0.035 if _kind == "mother" else sin(_idle_time * TAU * 0.42) * 0.025, minf(1.0, delta * 6.0))
	if _right_arm != null:
		_right_arm.rotation.x = lerp_angle(_right_arm.rotation.x, -0.035 if _kind == "mother" else -sin(_idle_time * TAU * 0.42) * 0.025, minf(1.0, delta * 6.0))
	_actor.rotation.z = lerpf(_actor.rotation.z, _rest_hip_rotation + sin(_idle_time * TAU * 0.37) * 0.012, minf(1.0, delta * 6.0))
	_actor.position.y = lerpf(_actor.position.y, _rest_y + sin(_idle_time * TAU * 0.72) * 0.004, minf(1.0, delta * 6.0))


func _roll_wheels(speed: float, delta: float, heading: float) -> void:
	_wheel_distance += speed * delta
	for index: int in range(_wheel_spins.size()):
		var radius: float = _wheel_radii[index]
		_wheel_spins[index].rotation.y = _wheel_distance / radius
	var heading_delta: float = angle_difference(_last_heading, heading)
	var steering_target: float = clampf(heading_delta / maxf(delta, 0.001) * 0.08, -0.35, 0.35)
	_steer_angle = lerpf(_steer_angle, steering_target, minf(1.0, delta * 7.0))
	for wheel: Node3D in _front_wheels:
		wheel.rotation.y = _steer_angle
	if _actor != null:
		_actor.position.y = lerpf(_actor.position.y, _rest_y + sin(_wheel_distance * 0.4) * 0.003, minf(1.0, delta * 8.0))


func _is_vehicle() -> bool:
	return _kind == "pram" or _kind == "car" or _kind == "van" or _kind == "truck" or _kind == "armored"


func _find_node(root: Node, node_name: String) -> Node3D:
	var found: Node = root.find_child(node_name, true, false)
	if found == null:
		return null
	return found as Node3D
