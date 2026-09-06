class_name AnimalMotion extends Node3D
## Poses an animal model from its caller-provided state.
##
## This component never advances an event, changes a gameplay position, or decides
## when a telegraph ends. `advance()` only updates visual child transforms, and no
## pose changes when the caller stops invoking it.

const WALK_STRIDE: float = 0.72
const RUN_STRIDE: float = 1.18

var _actor: Node3D
var _kind: String = "dog"
var _state: String = "idle"
var _distance: float = 0.0
var _time: float = 0.0
var _rest_actor_y: float = 0.0
var _rest_body_position: Vector3 = Vector3.ZERO
var _rest_body_scale: Vector3 = Vector3.ONE
var _rest_head_rotation: Vector3 = Vector3.ZERO
var _body: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _left_wing: Node3D
var _right_wing: Node3D


func configure(actor: Node3D, kind: String) -> void:
	_actor = actor
	_kind = "charging_dog" if kind == "charging" or kind == "charging_dog" else kind
	_state = "idle"
	_distance = 0.0
	_time = 0.0
	_rest_actor_y = actor.position.y
	_body = _find_node(actor, "Body")
	_head = _find_node(actor, "Head")
	_tail = _find_node(actor, "TailSegment0")
	if _body != null:
		_rest_body_position = _body.position
		_rest_body_scale = _body.scale
	if _head != null:
		_rest_head_rotation = _head.rotation
	_legs.clear()
	for leg_name: String in ["LeftFrontLegPivot", "RightFrontLegPivot", "LeftBackLegPivot", "RightBackLegPivot"]:
		var leg: Node3D = _find_node(actor, leg_name)
		if leg != null:
			_legs.append(leg)
	_left_wing = _find_node(actor, "LeftWingPivot")
	_right_wing = _find_node(actor, "RightWingPivot")


func advance(delta: float, speed: float, heading: float, state: String = "idle") -> void:
	if _actor == null or delta <= 0.0:
		return
	_state = state
	_time += delta
	_actor.rotation.y = heading
	var moving: bool = absf(speed) > 0.01
	if moving:
		_distance += absf(speed) * delta
	if _kind == "bird":
		_apply_bird(delta, speed, moving)
	else:
		_apply_quadruped(delta, speed, moving)


func _apply_quadruped(delta: float, speed: float, moving: bool) -> void:
	var is_cat: bool = _kind == "cat"
	var telegraphing: bool = _state == "telegraph"
	var running: bool = _state == "running" or _state == "leaving"
	var stride: float = RUN_STRIDE if running else WALK_STRIDE
	var phase: float = _distance * TAU / stride
	var smooth: float = minf(1.0, delta * 9.0)

	if _body != null:
		var posture_scale: Vector3 = _rest_body_scale
		if is_cat and telegraphing:
			posture_scale = _rest_body_scale * Vector3(1.10, 0.72, 0.82)
		elif is_cat and running:
			posture_scale = _rest_body_scale * Vector3(0.88, 0.92, 1.22)
		elif not is_cat and telegraphing and _kind == "charging_dog":
			posture_scale = _rest_body_scale * Vector3(1.05, 0.84, 1.08)
		_body.scale = _body.scale.lerp(posture_scale, smooth)
		var breathing: float = sin(_time * TAU * 0.72) * 0.008
		_body.position.y = lerpf(_body.position.y, _rest_body_position.y + breathing, smooth)

	if _head != null:
		var head_target: Vector3 = _rest_head_rotation
		if telegraphing:
			head_target.x = -0.18 if is_cat else -0.10
		elif running:
			head_target.x = 0.08 if is_cat else 0.04
		_head.rotation = _head.rotation.lerp(head_target, smooth)

	if moving and not telegraphing:
		var amplitude: float = 0.30 if running else 0.20
		for index: int in _legs.size():
			var leg_phase: float = phase + (0.0 if index % 2 == 0 else PI)
			if index >= 2:
				leg_phase += PI
			var target: float = sin(leg_phase) * amplitude
			_legs[index].rotation.x = lerp_angle(_legs[index].rotation.x, target, smooth)
	else:
		for leg: Node3D in _legs:
			var settle: float = sin(_time * TAU * 0.36) * 0.025
			leg.rotation.x = lerp_angle(leg.rotation.x, settle, minf(1.0, delta * 5.0))

	if _tail != null:
		var tail_target: float = 0.10 + sin(_time * TAU * (2.0 if moving else 0.7)) * (0.14 if moving else 0.04)
		if _kind == "charging_dog":
			tail_target = -0.03 if running else -0.16
		_tail.rotation.z = lerpf(_tail.rotation.z, tail_target, smooth)

	_actor.rotation.z = lerpf(_actor.rotation.z, sin(_time * TAU * 0.34) * 0.012, smooth)


func _apply_bird(delta: float, speed: float, moving: bool) -> void:
	var flying: bool = _state == "flying" or _state == "leaving"
	var smooth: float = minf(1.0, delta * 10.0)
	if flying:
		var beat: float = sin(_distance * 7.0 + _time * 2.0)
		var left_target: float = -0.58 - beat * 0.42
		var right_target: float = 0.58 + beat * 0.42
		if _left_wing != null:
			_left_wing.rotation.z = lerpf(_left_wing.rotation.z, left_target, smooth)
		if _right_wing != null:
			_right_wing.rotation.z = lerpf(_right_wing.rotation.z, right_target, smooth)
		_actor.position.y = lerpf(_actor.position.y, _rest_actor_y + 0.05 + absf(beat) * 0.05, smooth)
	else:
		var peck: float = sin(_time * TAU * 0.8) * 0.16
		if _head != null:
			_head.rotation.x = lerpf(_head.rotation.x, _rest_head_rotation.x + peck, smooth)
		if _left_wing != null:
			_left_wing.rotation.z = lerpf(_left_wing.rotation.z, -0.20, smooth)
		if _right_wing != null:
			_right_wing.rotation.z = lerpf(_right_wing.rotation.z, 0.20, smooth)
		_actor.position.y = lerpf(_actor.position.y, _rest_actor_y, smooth)
	if not moving and not flying:
		_actor.rotation.z = lerpf(_actor.rotation.z, sin(_time * TAU * 0.45) * 0.015, smooth)


func _find_node(root: Node, node_name: String) -> Node3D:
	var found: Node = root.find_child(node_name, true, false)
	if found == null:
		return null
	return found as Node3D
