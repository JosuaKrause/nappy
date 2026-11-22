class_name ScreenCrowdView
extends CrowdView
## The crowd's view of the screen as the game shows it: the box of the `DrawnView` it is handed,
## and the square the viewport's current camera looks at, sized from
## `ScreenOrientation`'s design box and its rotated one (a portrait touch window presents the game
## turned a quarter, `ScreenOrientation.apply_to_camera()`).
##
## **Owned by `Main`**, which owns the window and so the viewport and its camera, and handed to the
## simulation's builder (`SimulationBuilder.use_the_crowds_screen()`) that hands it to every city's
## crowd; the crowd itself names none of this.
##
## **The viewport is the anchor's**, read at each ask rather than held, so a view made before the
## anchor is in the tree still answers once it is. The box is the one `DrawnView` derives, handed
## in rather than made here, so the events' looks and the crowd are asked against one object.

## The node whose viewport is the screen.
var _anchor: Node

## The box every drawing gate is asked against.
var _drawn: DrawnView

func _init(anchor: Node, drawn: DrawnView) -> void:
	_anchor = anchor
	_drawn = drawn

## Overrides CrowdView.drawn_box.
func drawn_box() -> Rect2:
	return _drawn.box()

## Overrides CrowdView.camera_square.
func camera_square() -> Rect2:
	var camera := _anchor.get_viewport().get_camera_2d()
	if not camera:
		return Rect2()
	var size := Vector2(maxf(ScreenOrientation.DESIGN_SIZE.x, ScreenOrientation.ROTATED_SIZE.x),
			maxf(ScreenOrientation.DESIGN_SIZE.y, ScreenOrientation.ROTATED_SIZE.y)) / camera.zoom
	return Rect2(camera.get_screen_center_position() - size * 0.5, size)
