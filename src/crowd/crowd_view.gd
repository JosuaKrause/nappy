class_name CrowdView
extends RefCounted
## What the crowd is handed of the screen: the one place an agent learns where the camera looks and
## which world the viewport shows, so the agent itself reaches for neither the viewport nor a static.
##
## **Owned by `Crowd` and handed to every agent it makes**, the way it hands them `field` and
## `traffic`. An agent built by hand has none, and then keeps the rules a rig without a screen
## wants: no camera to be out of view of (the day's `Tuning.OUT_OF_SIGHT` radius answers) and no
## screen to be off (it is always drawn).
##
## **The viewport is the anchor's**, read at each ask rather than held, so a view made before the
## anchor is in the tree still answers once it is. Nothing is cached here beyond `DrawnView`'s own
## once-a-process-frame box, which is the value it has always been.

## The node whose viewport is the screen — the `Crowd` that owns this view.
var _anchor: Node

func _init(anchor: Node) -> void:
	_anchor = anchor

## The world the current camera shows, grown by `DrawnView.MARGIN`: everything an agent's drawing
## could be inside. See `DrawnView`.
func drawn_box() -> Rect2:
	return DrawnView.box_of(_anchor.get_viewport())

## Whether no part of a body standing at `at` (`room` either side) is inside a square centred where
## the camera looks, as wide and as tall as the larger side of the design box at the camera's zoom
## (640x640 world pixels at zoom 2). That is stricter than the real view: both presentations show
## the same 640x360 world, a portrait touch screen turning it a quarter
## (`ScreenOrientation.apply_to_camera()`), so the square holds a margin above and below it. With no
## camera — a rig that steps agents by hand — the played day's radius answers, from `otherwise`,
## the point the camera would have been looking at.
func beyond_every_view(at: Vector2, room: float, otherwise: Vector2) -> bool:
	var camera := _anchor.get_viewport().get_camera_2d()
	if not camera:
		return at.distance_to(otherwise) > Tuning.OUT_OF_SIGHT
	var size := Vector2(maxf(ScreenOrientation.DESIGN_SIZE.x, ScreenOrientation.ROTATED_SIZE.x),
			maxf(ScreenOrientation.DESIGN_SIZE.y, ScreenOrientation.ROTATED_SIZE.y)) / camera.zoom
	var offset := (at - camera.get_screen_center_position()).abs()
	return offset.x > size.x * 0.5 + room or offset.y > size.y * 0.5 + room
