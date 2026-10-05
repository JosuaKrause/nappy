class_name VisibleView
extends RefCounted
## How much of a thing in the world the player can actually see: the share of a world rectangle
## inside the camera's view, less whatever the on-screen controls cover. *(misty-newt, inbox #581,
## the player: "when counting the 80% visibility for seen remove the area at the bottom left and
## right up to the top of the joystick circle and horizontal extent of the speed button -- use that
## everywhere where visibility is concerned -- for the other mode those rectangles *do* count".)*
##
## **The covered corners exist only in `ControlsMode.Mode.JOYSTICK`**, the scheme that draws the
## two focal rings and their run buttons (`TouchControls._draw()`). Each bottom corner holds one ring
## with its button inward of it, so each corner's rectangle runs from the screen's own side to the
## far edge of its run button, and from the top of its ring (`TouchControls.STOP_RADIUS` above the
## focus) to the bottom of the screen. In `TAP` nothing is drawn there and the whole view counts.
##
## The corners are worked out from `TouchControls`' own constants in the 1280x720 design box and
## scaled onto the view, so moving a ring or a button moves what it covers. The view is the world
## the camera shows, whose corners are the design box's own whether or not a portrait window
## presents the game rotated, since the rotation turns the world and the controls together.
##
## The page's counter is the one reader today (`EncounterWatch`'s seen test). Nothing gameplay
## decides by — a sighting, a notice, an edge badge — asks this yet.

## The left covered corner, in the design box: from its side to the outer edge of the left run
## button, from the top of the left ring down.
static func covered_left() -> Rect2:
	var top := TouchControls.FOCUS_LEFT.y - TouchControls.STOP_RADIUS
	var right := TouchControls.RUN_CENTRE_LEFT.x + TouchControls.RUN_RADIUS
	return Rect2(0.0, top, right, ScreenOrientation.DESIGN_SIZE.y - top)

## The right covered corner, in the design box: the mirror of `covered_left()` about the right ring
## and button.
static func covered_right() -> Rect2:
	var top := TouchControls.FOCUS_RIGHT.y - TouchControls.STOP_RADIUS
	var left := TouchControls.RUN_CENTRE_RIGHT.x - TouchControls.RUN_RADIUS
	return Rect2(left, top, ScreenOrientation.DESIGN_SIZE.x - left, ScreenOrientation.DESIGN_SIZE.y - top)

## The share, 0 to 1, of `rect` (world space) the player can see in `view` (the world the camera
## shows), leaving out the covered corners when `joystick` is the scheme in force. 0 for a rectangle
## with no area. The two corners never overlap each other, so what they cover of `rect` is a plain
## sum. Allocates nothing, so a caller may ask it for every live thing every frame.
static func visible_share(rect: Rect2, view: Rect2, joystick: bool) -> float:
	var area := rect.get_area()
	if area <= 0.0:
		return 0.0
	var inside := rect.intersection(view).get_area()
	if joystick and inside > 0.0:
		var scale := view.size / ScreenOrientation.DESIGN_SIZE
		inside -= rect.intersection(_onto(covered_left(), view, scale)).get_area()
		inside -= rect.intersection(_onto(covered_right(), view, scale)).get_area()
	return maxf(0.0, inside) / area

## A design-box rectangle laid onto `view`, `scale` being the view's size over the design box's.
static func _onto(design: Rect2, view: Rect2, scale: Vector2) -> Rect2:
	return Rect2(view.position + design.position * scale, design.size * scale)
