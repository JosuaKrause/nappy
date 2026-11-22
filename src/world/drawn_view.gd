class_name DrawnView
extends RefCounted
## **The one box every off-screen drawing gate asks**: the world the current camera shows, grown by
## `MARGIN`, derived once a process frame by this object and handed to everything that asks.
## *(velvet-marten, #700, the player: "Skipping redraws for of screen elements. Also we don't
## really change things with animation if it's of screen. If we have a bounding box that extends
## a little bit into of screen then it won't be noticable.")*
##
## **Drawing only.** A thing outside this box still does everything it does — where it is, what it
## costs her, its timing — and only its picture is left as it was last drawn. A retained canvas item
## keeps its last draw list and moving its node still moves it, so a thing that comes back into the
## box redraws once from its current state on that frame, before the margin has let any of it onto
## the screen. Three callers ask it: an event's look (`EventLook._in_the_drawn_view()`), the
## roadblock's look for the band left at the post (`RoadblockLook._shows_its_nodes()`), and the
## crowd's view of the screen (`ScreenCrowdView.drawn_box()`), which hands the box to its agents.
## `Main` makes the one (`DrawnView.on()`) and hands that object two ways: to the simulation's
## builder, which puts it in every live event's surroundings, and to `ScreenCrowdView`, so the
## events and the crowd see the same box because they hold the same object. A view made with
## `DrawnView.new()` has no screen and shows everything, which is what a rig with nothing to be
## off screen from is handed; a suite's stand-in extends this class and overrides `has_screen()`
## and `box()`.
##
## **Not `VisibleView`, and the two are not to be merged.** That one answers "has she seen it", with
## the controls' covered corners taken out; this one answers "can any of it be on the screen", and a
## corner under a joystick is still drawn. It is read off the viewport's own canvas transform rather
## than off `Tuning.VIEW_HALF_EXTENT`, so a rig's own camera, a zoom and the portrait presentation's
## quarter turn are all the screen they are, with nothing to keep in step.
##
## Worked out once a process frame: the camera moves in the physics step
## (`process_callback` physics, under interpolation), which runs before every `_process()` that asks.

## How far past the screen's edge the box reaches, in world px: two tiles, over a third of a second
## of her running, and far more than the camera moves between the physics step that places it and
## the frame drawn from it, so nothing visibly starts or stops at the edge.
const MARGIN := 64.0

## What the view keeps its box under: the process frame it was worked out in and the box itself.
var _frame := -1
var _box := Rect2()

## The node whose viewport is the screen, or null for a view with no screen. Read at each ask rather
## than held as a viewport, so a view made before its anchor is in the tree answers once it is.
var _anchor: Node = null

## The screen the viewport of `anchor` shows. An anchor that is not in a tree is no screen.
static func on(anchor: Node) -> DrawnView:
	var view := DrawnView.new()
	view._anchor = anchor
	return view

## Whether there is a screen to be off: false for a view made with `DrawnView.new()` and for one
## whose anchor is not in a tree.
func has_screen() -> bool:
	return _anchor != null and is_instance_valid(_anchor) and _anchor.is_inside_tree()

## The box for this process frame: the world the viewport's canvas shows grown by `MARGIN`, or an
## empty rectangle where there is no screen. Worked out on the first ask of a process frame.
func box() -> Rect2:
	if not has_screen():
		return Rect2()
	var frame := Engine.get_process_frames()
	if frame == _frame:
		return _box
	var viewport := _anchor.get_viewport()
	var shown := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	_box = shown.grow(MARGIN)
	_frame = frame
	return _box

## Whether any of `reach` — a rectangle relative to `item`'s own position, everything its drawing
## can cover — is inside the box. True where there is no screen, and for an item that is not in a
## tree: a hand-built rig has no screen to be off.
func shows(item: Node2D, reach: Rect2) -> bool:
	if not has_screen() or not item.is_inside_tree():
		return true
	var at := item.global_position
	return box().intersects(Rect2(at + reach.position, reach.size))
