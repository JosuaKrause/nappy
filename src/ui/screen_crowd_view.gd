class_name ScreenCrowdView
extends CrowdView
## The crowd's view of the screen as the game shows it: the box `DrawnView` keeps for the viewport
## the anchor is in, and the square the viewport's current camera looks at, sized from
## `ScreenOrientation`'s design box and its rotated one (a portrait touch window presents the game
## turned a quarter, `ScreenOrientation.apply_to_camera()`).
##
## **Owned by `Main`**, which owns the window and so the viewport and its camera, and handed to the
## city (`City.crowd_view`) that hands it to its crowd; the crowd itself names none of this.
##
## **The viewport is the anchor's**, read at each ask rather than held, so a view made before the
## anchor is in the tree still answers once it is.

## The node whose viewport is the screen.
var _anchor: Node

func _init(anchor: Node) -> void:
	_anchor = anchor

func drawn_box() -> Rect2:
	return DrawnView.box_of(_anchor.get_viewport())

func camera_square() -> Rect2:
	var camera := _anchor.get_viewport().get_camera_2d()
	if not camera:
		return Rect2()
	var size := Vector2(maxf(ScreenOrientation.DESIGN_SIZE.x, ScreenOrientation.ROTATED_SIZE.x),
			maxf(ScreenOrientation.DESIGN_SIZE.y, ScreenOrientation.ROTATED_SIZE.y)) / camera.zoom
	return Rect2(camera.get_screen_center_position() - size * 0.5, size)
