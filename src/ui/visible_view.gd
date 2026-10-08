class_name VisibleView
extends RefCounted
## How much of a thing in the world the player can actually see: the share of a world rectangle
## inside the camera's view, less whatever the on-screen controls cover. *(misty-newt, inbox #581,
## the player: "when counting the 80% visibility for seen remove the area at the bottom left and
## right up to the top of the joystick circle and horizontal extent of the speed button -- use that
## everywhere where visibility is concerned -- for the other mode those rectangles *do* count".)*
##
## The covered corners exist only in joystick mode. Each focus carries either a steering ring
## or an equally sized Run disc, so swapping sides does not change the covered footprint.
## Each rectangle runs from its screen edge to the disc's far edge, and from its top downward.
## The corners are worked out from `TouchControls`' own constants in the 1280x720 design box and
## scaled onto the view, so moving a ring or a button moves what it covers. The view is the world
## the camera shows, whose corners are the design box's own whether or not a portrait window
## presents the game rotated, since the rotation turns the world and the controls together.
##
## Two ways to ask. `visible_share()` is the one-off question. A caller asking about many things in
## one frame keeps an instance, sets it once a frame with `look()` — which lays the two corners onto
## the view there and then — and asks `share_of()` for each thing, so the corners are worked out
## once a frame rather than once a thing.
##
## The page's counter is the one reader today (`EncounterWatch`'s encounters, the pelican's
## `pelican-seen`). Nothing gameplay decides by — a sighting, a notice, an edge badge — asks this
## yet. The player wants them to ("yes, everything should follow this (and treat it depending on the
## input mode)"); moving them changes play, and goes in the batch with M226 rather than here.

## The world the camera shows, as `look()` was last told.
var view := Rect2()
## Whether the joystick scheme's controls cover the view's bottom corners, as `look()` was last told.
var joystick := false
## The two covered corners laid onto `view`, while `joystick` holds.
var _left := Rect2()
var _right := Rect2()

## Sets the view and the scheme for this frame, and lays the covered corners onto it.
func look(at_view: Rect2, joystick_in_force: bool) -> void:
	view = at_view
	joystick = joystick_in_force
	if joystick:
		var scale := view.size / ScreenOrientation.DESIGN_SIZE
		_left = _onto(covered_left(), view, scale)
		_right = _onto(covered_right(), view, scale)

## `visible_share()` for `rect` against what `look()` was last told.
func share_of(rect: Rect2) -> float:
	return _share(rect, view, joystick, _left, _right)

## The left covered corner includes the painted ring or Run disc, never its invisible catch.
static func covered_left() -> Rect2:
	var top := TouchControls.FOCUS_LEFT.y - TouchControls.RUN_RADIUS
	var right := TouchControls.FOCUS_LEFT.x + TouchControls.RUN_RADIUS
	return Rect2(0.0, top, right, ScreenOrientation.DESIGN_SIZE.y - top)

## The right covered corner mirrors the same disc footprint.
static func covered_right() -> Rect2:
	var top := TouchControls.FOCUS_RIGHT.y - TouchControls.RUN_RADIUS
	var left := TouchControls.FOCUS_RIGHT.x - TouchControls.RUN_RADIUS
	return Rect2(left, top, ScreenOrientation.DESIGN_SIZE.x - left, ScreenOrientation.DESIGN_SIZE.y - top)
## The share, 0 to 1, of `rect` (world space) the player can see in `view` (the world the camera
## shows), leaving out the covered corners when `joystick` is the scheme in force. 0 for a rectangle
## with no area. The two corners never overlap each other, so what they cover of `rect` is a plain
## sum. Allocates nothing, so a caller may ask it for every live thing every frame.
static func visible_share(rect: Rect2, in_view: Rect2, joystick_in_force: bool) -> float:
	if not joystick_in_force:
		return _share(rect, in_view, false, Rect2(), Rect2())
	var scale := in_view.size / ScreenOrientation.DESIGN_SIZE
	return _share(rect, in_view, true, _onto(covered_left(), in_view, scale),
			_onto(covered_right(), in_view, scale))

static func _share(rect: Rect2, in_view: Rect2, covered: bool, left: Rect2, right: Rect2) -> float:
	var area := rect.get_area()
	if area <= 0.0:
		return 0.0
	var inside := rect.intersection(in_view).get_area()
	if covered and inside > 0.0:
		inside -= rect.intersection(left).get_area()
		inside -= rect.intersection(right).get_area()
	return maxf(0.0, inside) / area

## A design-box rectangle laid onto `view`, `scale` being the view's size over the design box's.
static func _onto(design: Rect2, onto: Rect2, scale: Vector2) -> Rect2:
	return Rect2(onto.position + design.position * scale, design.size * scale)
