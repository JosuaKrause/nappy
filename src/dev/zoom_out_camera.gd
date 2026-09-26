class_name ZoomOutCamera
extends Node
## `--zoom-out <seconds> [delay]`: the trailer's last shot, *"a zoom out from her doorstep to show
## the full buzzling city (to give a hint of the scale)"* (PLAYTEST-139). Holds on her own camera
## for `delay`, then pulls a camera of its own back over `seconds` from exactly where hers was
## looking to the framing `--overview` uses — the whole of `City.camera_bounds()` in the window —
## and holds there.
##
## **The one camera move in the trailer, and a dev rig's rather than the game's.** Her own camera
## (`scenes/player/stroller.tscn`) is untouched: this builds a second `Camera2D` under `main`, the
## way `DevRig`'s `--follow` and `--overview` cameras are built, and makes it current at the moment
## the move starts, from her camera's own screen centre and zoom, so the cut into it is invisible.
##
## **The zoom is interpolated on a log scale and the position on the view's size.** A linear zoom
## from 2 to about 0.1 spends almost all of its time at the wide end and rushes the close one; equal
## steps of `log(zoom)` read as a constant pull back. The centre then moves in step with how much
## wider the view has become, so while the view is still street-sized she stays in the middle of
## it and the centre only travels once the city is what fills it. The clock is the frame's own
## `delta`, which `--fixed-fps` makes the same on every render.

var _seconds := 1.0
var _delay := 0.0
var _elapsed := 0.0
## The camera the move starts from — hers — read at the moment it starts.
var _from: Camera2D
var _end_position := Vector2.ZERO
var _end_zoom := 1.0
var _start_position := Vector2.ZERO
var _start_zoom := 1.0
var _camera: Camera2D

## `from` is her camera, `bounds` the city's own camera bounds and `viewport_size` the window's,
## the same two numbers `DevRig.make_overview_camera()` frames the city from.
func setup(from: Camera2D, bounds: Rect2, viewport_size: Vector2, seconds: float,
		delay: float) -> void:
	_from = from
	_seconds = maxf(seconds, 0.01)
	_delay = maxf(delay, 0.0)
	_end_position = bounds.get_center()
	_end_zoom = overview_zoom(bounds, viewport_size)

## The zoom that fits all of `bounds` in `viewport_size` — `DevRig.make_overview_camera()`'s own.
static func overview_zoom(bounds: Rect2, viewport_size: Vector2) -> float:
	return minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _delay:
		return
	if not _camera:
		_start()
	var t := clampf((_elapsed - _delay) / _seconds, 0.0, 1.0)
	var pose := pose_at(smoothstep(0.0, 1.0, t), _start_position, _start_zoom, _end_position,
			_end_zoom)
	_camera.position = Vector2(pose.x, pose.y)
	_camera.zoom = Vector2.ONE * pose.z

func _start() -> void:
	_start_zoom = _from.zoom.x if _from else 2.0
	_start_position = _from.get_screen_center_position() if _from else _end_position
	_camera = Camera2D.new()
	_camera.name = "ZoomOutCamera"
	# Moved every `_process` frame by this node rather than on the physics tick, so physics
	# interpolation would draw it a tick behind — the same reason `DevRig`'s follow camera is off.
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_camera.position = _start_position
	_camera.zoom = Vector2.ONE * _start_zoom
	add_child(_camera)
	_camera.make_current()

## Where the camera is and how far it is zoomed, `weight` (0 to 1, already eased) of the way from the
## start to the end: `x` and `y` the centre, `z` the zoom. Pure, so a test can hold the shape of the
## move without a camera: the zoom is geometric between the two, and the centre has travelled the
## same fraction of the way that the view's own width has grown.
static func pose_at(weight: float, start_position: Vector2, start_zoom: float,
		end_position: Vector2, end_zoom: float) -> Vector3:
	var zoom := exp(lerpf(log(start_zoom), log(end_zoom), weight))
	var widened := inverse_lerp(1.0 / start_zoom, 1.0 / end_zoom, 1.0 / zoom) \
			if not is_equal_approx(start_zoom, end_zoom) else weight
	var centre := start_position.lerp(end_position, clampf(widened, 0.0, 1.0))
	return Vector3(centre.x, centre.y, zoom)
