class_name DrawnView
extends RefCounted
## **The one box every off-screen drawing gate asks**: the world the current camera shows, grown by
## `MARGIN`. *(velvet-marten, #700, the player: "Skipping redraws for of screen elements. Also we
## don't really change things with animation if it's of screen. If we have a bounding box that
## extends a little bit into of screen then it won't be noticable.")*
##
## **Drawing only.** A thing outside this box still does everything it does — where it is, what it
## costs her, its timing — and only its picture is left as it was last drawn. A retained canvas item
## keeps its last draw list and moving its node still moves it, so a thing that comes back into the
## box redraws once from its current state on that frame, before the margin has let any of it onto
## the screen. `CrowdAgent` and `EventInstance` are the two callers.
##
## **Not `VisibleView`, and the two are not to be merged.** That one answers "has she seen it", with
## the controls' covered corners taken out; this one answers "can any of it be on the screen", and a
## corner under a joystick is still drawn. It is read off the viewport's own canvas transform rather
## than off `Tuning.VIEW_HALF_EXTENT`, so a rig's own camera, a zoom and the portrait presentation's
## quarter turn are all the screen they are, with nothing to keep in step.
##
## Worked out once a process frame per viewport: the camera moves in the physics step
## (`process_callback` physics, under interpolation), which runs before every `_process()` that asks.

## How far past the screen's edge the box reaches, in world px: two tiles, over a third of a second
## of her running, and far more than the camera moves between the physics step that places it and
## the frame drawn from it, so nothing visibly starts or stops at the edge.
const MARGIN := 64.0

static var _frame := -1
static var _viewport_id := 0
static var _box := Rect2()

## Whether any of `reach` — a rectangle relative to `item`'s own position, everything its drawing
## can cover — is inside the box. True for an item that is not in a tree: a hand-built rig has no
## screen to be off, and keeps the gates' old behaviour.
static func shows(item: Node2D, reach: Rect2) -> bool:
	if not item.is_inside_tree():
		return true
	var at := item.global_position
	return box_of(item.get_viewport()).intersects(Rect2(at + reach.position, reach.size))

## The box for `viewport` this process frame.
static func box_of(viewport: Viewport) -> Rect2:
	var frame := Engine.get_process_frames()
	var id := viewport.get_instance_id()
	if frame != _frame or id != _viewport_id:
		_frame = frame
		_viewport_id = id
		var shown := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
		_box = shown.grow(MARGIN)
	return _box

## Drops this frame's box, for a test that moves the view between two asks in one frame.
static func forget() -> void:
	_frame = -1
