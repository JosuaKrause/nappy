class_name GateState
extends RefCounted
## The shared state of one checkpoint gate: its own ground point and whether the boom is up right
## now. Built once per street door by `RegionPlanner.stand_door()`, held by the `checkpoint_gate`
## instance through `EventPlan.gate()` (which is what it draws raised or lowered from) and by
## `Crowd` through `RegionPlan.gate_states()` (which is what actually raises and lowers it, see
## `Crowd._stop_for_gates()`). One object rather than two copies, so the two systems can never
## disagree about whether a boom is up.

## The gate's own ground point, in world space: the position its `checkpoint_gate` instance
## stands at. Given to `_init()` and asked through `ground_point()`.
var _position := Vector2.ZERO
## Whether the boom is up. Asked through `is_boom_up()` and set through `set_boom_up()`.
var _raised := false
## Seconds the car at the front of this gate's queue has been held at the stop line, `Crowd`'s own
## clock for `Crowd.GATE_STOP_SECONDS`, reset the moment nobody is held here.
var _stopped_for := 0.0

func _init(at := Vector2.ZERO) -> void:
	_position = at

## Where the gate stands, in world space: what `Crowd` measures a car's and her distance from.
func ground_point() -> Vector2:
	return _position

## Whether the boom's arm is up right now.
func is_boom_up() -> bool:
	return _raised

## Raises or lowers the boom. `Crowd._stop_for_gates()` is the only caller; the instance only asks
## `is_boom_up()`, once a frame, to choose which of the four boom textures to draw.
func set_boom_up(up: bool) -> void:
	_raised = up

## How long the car at the front of this gate's queue has been held at the stop line, in seconds.
func held_for() -> float:
	return _stopped_for

## Counts `seconds` more of the car at the front being held at the stop line.
func hold_for(seconds: float) -> void:
	_stopped_for += seconds

## Forgets the hold: nobody is held at this gate's stop line.
func release_hold() -> void:
	_stopped_for = 0.0
