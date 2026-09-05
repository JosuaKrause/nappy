class_name TapControls
extends Node
## The tap-to-walk reader: a tap decides a straight line and a double tap runs it, standing in
## for the on-screen stick in the other of the two control schemes `ControlsMode` chooses between.
##
## **Nothing here re-aims.** The heading is worked out once, at the tap, and pressed the way
## `TouchControls._set_axis()` presses the stick's own deflection — the components of a fixed unit
## vector, not a direction recomputed every frame — so a shove that knocks her off the line does
## not silently correct itself. Walking into a wall and stopping is the player's mistake to make
## here exactly as it is with the stick: nothing routes around what is in the way, and nothing
## times out either. She presses until she arrives or until the next tap.
##
## **Arrival is the plane through the target, not a distance.** `has_arrived()` is
## `(target - position).dot(direction) <= 0` — the plane at right angles to the heading fixed at
## the tap. That terminates cleanly even when a shove pushes her sideways off the line, where a
## distance test would have her pressing forever past a target she was knocked around.
##
## A double tap is two windows: `DOUBLE_TAP_SECONDS` decides *soon enough*, and `DOUBLE_TAP_DISTANCE`
## decides *close enough* to the first tap to read as the same destination doubled rather than a
## new one — without the second window, a tap somewhere else a moment later would make her run to
## the wrong place. Both are plain constants here, the way `TouchControls.RUN_CATCH_RADIUS` (how
## near the RUN button a thumb must land) is a plain constant there rather than a balance number in
## `Tuning`.

## How soon a second tap has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second tap has to land to the first, in screen px, to read as the same
## destination rather than a new one. Generous like `TouchControls.RUN_CATCH_RADIUS`, because a
## thumb tapping twice does not land on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0

## The rig, found the same way `HUD._rig` is: a state of the player rather than something a
## signal carries.
var _rig: Node2D

## Fixed at the tap that started the current leg; never touched again until the next tap or
## arrival releases them.
var _direction := Vector2.ZERO
var _target := Vector2.ZERO
var _walking := false

## The previous tap's own moment and screen position, for the double-tap windows. `-INF` reads as
## "no earlier tap this run", which can never fall inside either window.
var _last_tap_at := -INF
var _last_tap_screen_position := Vector2.ZERO

func _ready() -> void:
	# Has to keep reading a tap through the arrival pause it can itself raise, the same reason
	# `TouchControls` stays ALWAYS rather than the inherited PAUSABLE.
	process_mode = Node.PROCESS_MODE_ALWAYS

## Every real tap: `InputEventScreenTouch` is what a finger sends. A mouse click stands in for one
## too, in the dev build only -- that is its own later entry, not this one.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_tap((event as InputEventScreenTouch).position, Time.get_ticks_msec() / 1000.0)

## A tap arrived at `screen_position` -- the same canvas-space coordinate the event itself carries,
## whatever the window's own rotation -- at moment `now`.
##
## `get_viewport().get_canvas_transform().affine_inverse()` maps it to a world position: the exact
## reverse of what `DangerEdge` and `HomeArrow` already do every frame to place a screen cue from a
## world one, so this tracks the camera, the zoom and the rotated presentation with nothing of its
## own to keep in step -- no separate remap through `ScreenOrientation` the way `TouchControls` has
## to for its own fixed screen constants, because a tap has no fixed constant to compare against.
##
## `now` is a parameter rather than read from `Time` in here, so a test can hold the double-tap
## window still instead of racing the engine clock -- `_input()` is the one real caller and is what
## supplies it from `Time.get_ticks_msec()`.
func _on_tap(screen_position: Vector2, now: float) -> void:
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var double := is_double_tap(now - _last_tap_at,
			screen_position.distance_to(_last_tap_screen_position))
	_last_tap_at = now
	_last_tap_screen_position = screen_position
	walk_to(world, double)

func _process(_delta: float) -> void:
	if not _walking:
		return
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
		if not _rig:
			return
	if has_arrived(_target, _rig.global_position, _direction):
		_walking = false
		_release()

## Starts a leg toward `target`, computed once here and never again. `run` holds the same `run`
## action the button and Shift do, until she arrives or the next tap lets go of it.
##
## A tap that lands on her own position has no line to walk and is a no-op — there is nothing for
## `_process()` to test an arrival against.
func walk_to(target: Vector2, run: bool) -> void:
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	if not _rig:
		return
	var direction := heading_to(target, _rig.global_position)
	if direction == Vector2.ZERO:
		return
	_target = target
	_direction = direction
	_walking = true
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

func _release() -> void:
	TouchControls._release_movement()

## Whether a straight walk toward `target`, heading `direction`, has reached the plane through the
## target at right angles to that heading — see the class doc for why this is a plane and not a
## radius.
static func has_arrived(target: Vector2, position: Vector2, direction: Vector2) -> bool:
	return (target - position).dot(direction) <= 0.0

## The unit vector from `from` to `target`, or `Vector2.ZERO` for a tap with nowhere to go.
static func heading_to(target: Vector2, from: Vector2) -> Vector2:
	var offset := target - from
	return offset.normalized() if offset.length() > 0.001 else Vector2.ZERO

## Whether a second tap `distance` px from the first, `elapsed` seconds after it, reads as the
## same destination doubled rather than a new one.
static func is_double_tap(elapsed: float, distance: float) -> bool:
	return elapsed <= DOUBLE_TAP_SECONDS and distance <= DOUBLE_TAP_DISTANCE
