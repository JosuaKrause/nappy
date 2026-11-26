class_name OpeningShot
extends Node
## Day 1's opening shot, an experiment the player tries before it is kept (`docs/MECHANICS.md`,
## "The opening shot"): the camera cuts to the tutorial park, rests there, follows the tutorial route
## back at a steady pace to her door and hands the view back to hers; a tap or a key skips it.
## `finished` says when play may begin. Flow layer: it moves a camera and stands a focus for the
## crowd, and knows nothing of who runs it.
##
## **Her own camera is not moved.** The shot's camera is a plain `Camera2D` of its own, made current
## over hers (hers sits on her, dormant), and freed at the end, which hands the view back to hers,
## the way `LossHold` does. It copies hers for the zoom, the turn and the limits, so the phone's
## rotated presentation reads the same through it.
##
## **The crowd's box goes with the camera** (`focus()`, a `CameraFocus`): for the shot's length the
## crowd simulates the streets in the picture, so with the cars held the ones left near her door are
## outside the box, where they park, and none comes back in behind the camera. A car that happens to
## drive inside the box all the way is still there, since nothing vanishes in view.
##
## Lives under `Main` and keeps running while the tree is paused, as the title does. The day's clock
## does not run during it: she is handed to the day only when it ends.

signal finished

## Seconds the camera rests on the park before it starts back.
const REST_SECONDS := 1.0
## Seconds the camera takes along the whole way back, at one pace, whatever the route's length.
const TRAVEL_SECONDS := 5.0

var _camera: Camera2D = null
var _focus: CameraFocus = null
var _line: Array[Vector2] = []
## The distance along `_line` at each of its points, the first 0.
var _reached: Array[float] = []
var _elapsed := 0.0
var _running := false

func _ready() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)

## The shot's route for `route`, in world pixels: the park, the junctions the route passes from its
## far end back to the one it leaves the doorstep's street at, and `doorstep`. A straight line
## between two points, so it runs down the middle of each street.
static func line_for(route: TutorialRoute, doorstep: Vector2) -> Array[Vector2]:
	var junctions: Array[Vector2i] = [route.turning_junction()]
	for street in route.lesson_streets():
		junctions.append(street.other_end(junctions[junctions.size() - 1]))
	var park := Rect2(CityMap.block_rect(route.park_block()))
	var line: Array[Vector2] = [park.get_center() * Tuning.TILE_SIZE]
	for i in range(junctions.size() - 1, -1, -1):
		line.append(_junction_centre(junctions[i]))
	line.append(doorstep)
	return line

## The middle of the junction's box, in world pixels.
static func _junction_centre(junction: Vector2i) -> Vector2:
	var middle := Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)
	return middle * Tuning.TILE_SIZE

## Cuts the view from `drawing`, the camera showing her now, to the first point of `line` and
## starts the shot.
func begin(drawing: Camera2D, line: Array[Vector2]) -> void:
	_line = line
	_reached = [0.0]
	for i in range(1, _line.size()):
		_reached.append(_reached[i - 1] + _line[i - 1].distance_to(_line[i]))
	_camera = Camera2D.new()
	_camera.name = "ShotCamera"
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.ignore_rotation = drawing.ignore_rotation
	_camera.rotation = drawing.global_rotation
	_camera.limit_left = drawing.limit_left
	_camera.limit_right = drawing.limit_right
	_camera.limit_top = drawing.limit_top
	_camera.limit_bottom = drawing.limit_bottom
	_camera.zoom = drawing.zoom
	_camera.position = _line[0]
	add_child(_camera)
	_camera.make_current()
	_camera.reset_physics_interpolation()
	_focus = CameraFocus.new(_camera)
	_elapsed = 0.0
	_running = true
	set_physics_process(true)
	set_process_unhandled_input(true)

## Where the crowd's box stands for the shot's length: the camera's own view.
func focus() -> CameraFocus:
	return _focus

## Whether the shot is running: begun and neither run out nor skipped. While it is, the window
## losing focus opens no pause over it (`Main._pause_on_focus_lost()`).
func is_running() -> bool:
	return _running

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var along := clampf((_elapsed - REST_SECONDS) / TRAVEL_SECONDS, 0.0, 1.0)
	_camera.global_position = _point_at(along * _reached[_reached.size() - 1])
	if _elapsed >= REST_SECONDS + TRAVEL_SECONDS:
		_finish()

## The point `distance` px along the line, the last point past its end.
func _point_at(distance: float) -> Vector2:
	for i in range(1, _line.size()):
		if distance <= _reached[i]:
			var length := _reached[i] - _reached[i - 1]
			if length <= 0.0:
				return _line[i]
			return _line[i - 1].lerp(_line[i], (distance - _reached[i - 1]) / length)
	return _line[_line.size() - 1]

## A tap or a key skips the shot at once and is not passed on to what is under it. The press that
## dismissed the title is not its skip: the title starts the run two frames after the press and a
## key's own press is held (an echo) or handled by then.
func _unhandled_input(event: InputEvent) -> void:
	if not _running or event.is_echo() or not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch \
			or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		_finish()

func _finish() -> void:
	if not _running:
		return
	_running = false
	set_physics_process(false)
	set_process_unhandled_input(false)
	# The focus reads the camera once more, so it keeps where the view ended, and freeing the current
	# camera hands the view back to hers.
	_focus.where()
	_camera.free()
	_camera = null
	finished.emit()
