class_name CrowdView
extends RefCounted
## What the crowd is handed of the screen: the one place an agent learns where the camera looks and
## which world the viewport shows, so neither the agent nor the crowd reaches for the viewport or
## names a view-layer class. **The crowd's own idea of "the screen"**, two reads and the rule built
## on them; the answers come from whoever implements it (`ScreenCrowdView`, `src/ui/`, which reads
## the viewport's camera and `DrawnView`), handed to `City` by `main._new_city()`.
##
## **Handed to every agent the crowd makes**, the way it hands them `field` and `traffic`. An agent
## built by hand has none, and then keeps the rules a rig without a screen wants: no camera to be
## out of view of (the day's `Tuning.OUT_OF_SIGHT` radius answers) and no screen to be off (it is
## always drawn).
##
## **Asked, not pushed.** The camera moves inside the frame, at its own place in the tree's
## process order, and the box an agent redraws against is the one the camera shows when that agent
## is processed; a value written once a frame at some other point would be a frame behind for the
## agents on one side of the camera. So the implementation answers at the moment of the ask
## (`DrawnView` keeps its own once-a-process-frame box): the first agent processed in a frame sees
## the camera as it stands then.
## This base answers nothing: no area at all, which `beyond_every_view()` takes for "no camera".

## The world the current camera shows, grown by `DrawnView.MARGIN`: everything an agent's drawing
## could be inside. A view with no screen answers an empty rectangle.
func drawn_box() -> Rect2:
	return Rect2()

## The square centred where the camera looks, as wide and as tall as the larger side of the design
## box at the camera's zoom (640x640 world pixels at zoom 2). That is stricter than the real view:
## both presentations show the same 640x360 world, a portrait touch screen turning it a quarter, so
## the square holds a margin above and below it. No area when there is no camera.
func camera_square() -> Rect2:
	return Rect2()

## Whether no part of a body standing at `at` (`room` either side) is inside `camera_square()`. With
## no camera — a rig that steps agents by hand — the played day's radius answers, from `otherwise`,
## the point the camera would have been looking at.
func beyond_every_view(at: Vector2, room: float, otherwise: Vector2) -> bool:
	var square := camera_square()
	if not square.has_area():
		return at.distance_to(otherwise) > Tuning.OUT_OF_SIGHT
	var half := square.size * 0.5
	var offset := (at - (square.position + half)).abs()
	return offset.x > half.x + room or offset.y > half.y + room
