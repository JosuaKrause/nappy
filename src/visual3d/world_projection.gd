class_name WorldProjection
extends RefCounted
## Maps the logical 2D ground into the orthographic 3D presentation.
##
## The logical camera remains authoritative. This adapter reads its canvas transform, removes the
## portrait presentation rotation into design space, and configures a Camera3D to show that same
## ground target and zoom. It owns no movement, collision, event timing, or gameplay state.

const TILE_SIZE_PX := 32.0
const PITCH_DEGREES := 65.0
const PITCH_RADIANS := deg_to_rad(PITCH_DEGREES)
const GROUND_Z_SCALE := 1.0 / sin(PITCH_RADIANS)
const CAMERA_DISTANCE := 32.0

## Converts a logical pixel position into the ground plane's model-unit position.
static func logical_to_world(logical_position_px: Vector2) -> Vector3:
	return Vector3(
		logical_position_px.x / TILE_SIZE_PX,
		0.0,
		logical_position_px.y / (TILE_SIZE_PX * sin(PITCH_RADIANS)))

## Converts a model-unit ground position back into logical pixels. Elevation is ignored because
## logical positions describe gameplay ground, not the height of a roof or actor.
static func world_to_logical(world_position: Vector3) -> Vector2:
	return Vector2(world_position.x * TILE_SIZE_PX,
		world_position.z * TILE_SIZE_PX * sin(PITCH_RADIANS))

## Converts a logical world pixel position into fixed design-viewport coordinates using the live
## canvas transform. `canvas_transform` may be in the rotated presented box.
static func logical_to_design(logical_position_px: Vector2, canvas_transform: Transform2D,
		rotated: bool, design_size_px: Vector2) -> Vector2:
	return _canvas_in_design_space(canvas_transform, rotated, design_size_px) * logical_position_px

## Converts a design-viewport coordinate, such as a touch picked after unrotation, back into the
## logical world pixels represented by the live canvas transform.
static func design_to_logical(design_position_px: Vector2, canvas_transform: Transform2D,
		rotated: bool, design_size_px: Vector2) -> Vector2:
	var design_canvas := _canvas_in_design_space(canvas_transform, rotated, design_size_px)
	return design_canvas.affine_inverse() * design_position_px

## Aligns an orthographic camera to the logical camera represented by `canvas_transform`.
## `design_size_px` is the fixed design viewport, not the physical window size.
static func sync_camera(camera: Camera3D, canvas_transform: Transform2D, rotated: bool,
		design_size_px: Vector2) -> void:
	var design_canvas := _canvas_in_design_space(canvas_transform, rotated, design_size_px)
	var design_center_px := design_size_px * 0.5
	var logical_center_px := design_canvas.affine_inverse() * design_center_px
	var ground_target := logical_to_world(logical_center_px)
	var zoom := _uniform_zoom(design_canvas)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = design_size_px.y / (zoom * TILE_SIZE_PX)
	var camera_offset := Vector3(0.0, sin(PITCH_RADIANS), cos(PITCH_RADIANS)) * CAMERA_DISTANCE
	camera.position = ground_target + camera_offset
	camera.look_at(ground_target, Vector3.UP)

## Removes the fixed +90-degree presentation transform used by ScreenOrientation. Keeping this
## local to the adapter lets tests and future subviewports use a different design-size box safely.
static func _canvas_in_design_space(canvas_transform: Transform2D, rotated: bool,
		design_size_px: Vector2) -> Transform2D:
	if not rotated:
		return canvas_transform
	var presented_size_px := Vector2(design_size_px.y, design_size_px.x)
	var presentation_rotation := Transform2D().rotated(deg_to_rad(90.0))
	presentation_rotation.origin = presented_size_px * 0.5 - presentation_rotation.basis_xform(design_size_px * 0.5)
	return presentation_rotation.affine_inverse() * canvas_transform

static func _uniform_zoom(design_canvas: Transform2D) -> float:
	return (design_canvas.basis_xform(Vector2.RIGHT).length()
		+ design_canvas.basis_xform(Vector2.DOWN).length()) * 0.5
