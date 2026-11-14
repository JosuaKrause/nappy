class_name EventRouteLines
extends Node2D
## Every live event's own route, drawn as a polyline from where it starts to where it ends, in a
## colour of its own — the seventh debug layer, key `7` and `--layers 7`/`?layers=7`. See
## docs/TELEMETRY.md, "The debug view".
##
## **A different question from layer 5.** `RouteLines` draws *her* day's planned routes, the same on
## every build; this draws the route each event walks or drives on the frame it is drawn (a dog
## walker's block, a police patrol's street, a convoy's way through the junction boxes), so a change
## to where a row's route is cut shows up as a different picture. It is not a field and not a body,
## so it is not a case inside `DebugLayers`; it is a sibling the way `RouteLines` is.
##
## **Read through the event's own method, never its fields.** `EventInstance.walks()` answers the
## route in world space, empty or one point for an event that stands, so an event with no route
## draws nothing, and one that is gone (`is_gone()`) is skipped. A row that paces a beat shows the
## beat, the one stretch it folds back and forth over.
##
## **Redrawn every frame while it is shown, and not at all while it is off.** An event appears, walks
## and leaves, so the picture is asked again each frame it is visible. While it is hidden
## `_process()` still runs but asks for no redraw, and a hidden `CanvasItem` is not drawn.

## Hot pink: the debug view's other colours are amber and deep red (fields), cyan (shadows), green
## (bodies) and the purple of her own routes, and none of them is this, so a line is told at once
## from the other layers when several are on.
const ROUTE_COLOUR := Color(1.0, 0.35, 0.75, 0.95)
## `DebugLayers.LINE_WIDTH`'s own weight, so the route reads at the weight of the other layers.
const LINE_WIDTH := 1.5
## The half-size of the start's dot and the end's square, in pixels.
const MARK_SIZE := 4.0

## The world's events, asked only for `instances()`. Null before the world is handed over.
var _events: EventManager

## **Called again when the escape walks out of the service door**, with the city's events in place of
## the building's.
func setup(events: EventManager) -> void:
	_events = events

## Sets whether the layer starts on — `7 in indices`, from `DevFlags.layers_override()`.
func apply_initial_state(indices: Array[int]) -> void:
	visible = 7 in indices

## Every route a live event has, one polyline each, start first. What `_draw()` draws, pulled out so
## a test can ask it without a viewport to draw into.
func routes() -> Array[PackedVector2Array]:
	var found: Array[PackedVector2Array] = []
	if not _events:
		return found
	for instance in _events.instances():
		if instance.is_gone():
			continue
		var route := instance.walks()
		if route.size() >= 2:
			found.append(route)
	return found

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	for route in routes():
		draw_polyline(route, ROUTE_COLOUR, LINE_WIDTH, true)
		draw_circle(route[0], MARK_SIZE, ROUTE_COLOUR)
		var end := route[route.size() - 1]
		draw_rect(Rect2(end - Vector2(MARK_SIZE, MARK_SIZE), Vector2(MARK_SIZE, MARK_SIZE) * 2.0),
				ROUTE_COLOUR)
