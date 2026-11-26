class_name LossHold
extends Node
## The beat a lost day holds before its summary, so the player sees what caused it without a word
## (show, not tell). The world stops on the frame of the loss; when one thing caused it (the car
## that struck her, the event that struck her, the event that charged the baby most), the camera
## eases to frame her and that thing together and holds there; when no one thing did (the crowd,
## the traffic as a whole, her own running), it holds where it stands, on her. A tap or a key
## skips it. `finished` says when the summary may come up.
##
## **Nothing is drawn for the cause**: the framing is the whole mark, and the frozen frame stands
## exactly as it was, so neither a halo nor a caret is added or taken away. Its camera is a plain
## `Camera2D` of its own, made current over hers (hers is paused with the world), and freed at the
## end, which hands the view back to hers.
##
## Lives under `Main`, so it keeps running while the tree is paused.

signal finished

## Seconds the camera takes to ease from her view to the framing.
const EASE_SECONDS := 0.7
## Seconds the framing holds after the ease, before the summary.
const HOLD_SECONDS := 1.5
## The room, in screen px, kept between her or the cause and the screen's edge.
const MARGIN := 90.0
## How far the framing may zoom out to fit a far cause, as a share of her own zoom; a cause farther
## than that is framed as far as it goes with her still in view.
const FARTHEST_ZOOM := 0.5

var _camera: Camera2D = null
var _from_centre := Vector2.ZERO
var _to_centre := Vector2.ZERO
var _from_zoom := 1.0
var _to_zoom := 1.0
var _elapsed := 0.0
var _running := false

func _ready() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)

## The zoom that frames her and the cause together on a screen of `view_size` px, her own being
## `zoom`, with the camera turned by `turned` radians (0 while the view is not rotated): her own
## when both fit already, zoomed out to fit them with `MARGIN` to spare otherwise, never beyond
## `FARTHEST_ZOOM` of hers.
static func _zoom_for(her: Vector2, cause: Vector2, view_size: Vector2, zoom: float,
		turned: float) -> float:
	var apart := (cause - her).rotated(-turned).abs()
	var fit := minf(view_size.x / (apart.x + 2.0 * MARGIN), view_size.y / (apart.y + 2.0 * MARGIN))
	return clampf(fit, zoom * FARTHEST_ZOOM, zoom)

## The world point the camera centres on at `zoom`: halfway between her and the cause, moved
## toward her only as far as it takes to keep her inside the screen's margin when the cause is too
## far to frame.
static func _centre_for(her: Vector2, cause: Vector2, view_size: Vector2, zoom: float,
		turned: float) -> Vector2:
	var apart := (cause - her).rotated(-turned)
	var reach := (view_size / (2.0 * zoom) - Vector2(MARGIN, MARGIN)).max(Vector2.ZERO)
	var centre := Vector2(clampf(apart.x * 0.5, -reach.x, reach.x),
			clampf(apart.y * 0.5, -reach.y, reach.y))
	return her + centre.rotated(turned)

## Stops the world and eases the view from `drawing`, the camera showing her now, to the framing of
## her at `her` and the cause at `cause`, on a screen of `view_size` px.
func begin(drawing: Camera2D, her: Vector2, cause: Vector2, view_size: Vector2) -> void:
	var turned := 0.0 if drawing.ignore_rotation else drawing.global_rotation
	_from_centre = drawing.get_screen_center_position()
	_from_zoom = drawing.zoom.x
	_to_zoom = _zoom_for(her, cause, view_size, _from_zoom, turned)
	_to_centre = _centre_for(her, cause, view_size, _to_zoom, turned)
	_camera = Camera2D.new()
	_camera.name = "LossCamera"
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.ignore_rotation = drawing.ignore_rotation
	_camera.rotation = drawing.global_rotation
	_camera.limit_left = drawing.limit_left
	_camera.limit_right = drawing.limit_right
	_camera.limit_top = drawing.limit_top
	_camera.limit_bottom = drawing.limit_bottom
	_camera.zoom = Vector2(_from_zoom, _from_zoom)
	_camera.position = _from_centre
	add_child(_camera)
	_camera.make_current()
	_camera.reset_physics_interpolation()
	_start()

## Whether the beat is running: begun and neither run out nor skipped. While it is, the window losing
## focus opens no pause over it (`Main._pause_on_focus_lost()`).
func is_running() -> bool:
	return _running

## Stops the world and holds the view where it is, for a loss no one thing caused.
func hold_on_her() -> void:
	_start()

func _start() -> void:
	_elapsed = 0.0
	_running = true
	if is_inside_tree():
		get_tree().paused = true
	set_physics_process(true)
	set_process_unhandled_input(true)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _camera:
		var ease_share := smoothstep(0.0, 1.0, clampf(_elapsed / EASE_SECONDS, 0.0, 1.0))
		_camera.global_position = _from_centre.lerp(_to_centre, ease_share)
		var zoom := lerpf(_from_zoom, _to_zoom, ease_share)
		_camera.zoom = Vector2(zoom, zoom)
	if _elapsed >= EASE_SECONDS + HOLD_SECONDS:
		_finish()

## A tap or a key ends the beat at once, and is not passed on to what is under it.
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
	if _camera:
		# Freeing the current camera hands the view back to hers.
		_camera.free()
		_camera = null
	finished.emit()
