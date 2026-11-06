extends EventDrawer
## An event drawer that records what a look tells it to draw instead of painting it, handed to an
## instance through `EventInstance.drawer` the way its manager's spawner hands the real one. A check
## reads the pictures an event was drawn with off this, without reading what the look holds; which
## picture an event shows where is the look's to decide, and how a picture looks on a canvas is the
## real drawer's.
##
## The scenery of a crash's or a burst main's slices is built for real, since the look stands it
## behind its slice as a node: a drawer recording scenery is handed the atlas the scenery is cut
## from, and one handed none records no scenery and must not be asked to. The scenery lays its
## pictures through the real drawer's own, or through `scenery_drawer` when a test hands one.

## Every picture the look asked for, in order: `{"canvas", "kind", "picture", "foot", "size",
## "rect", "mirrored", "colour", "band", "pass", "frame"}`. `kind` is `&"stand"`, `&"paint"`, `&"caret"` (a danger caret: `foot` is its tip, `size` its width twice over, `colour` its colour),
## `&"band"` or `&"scenery"`; `rect` is where the picture lands in `canvas`'s own space: a standing
## picture's box, its bottom edge centred on `foot` at `size` (its own size when it was asked for at
## zero), a painted one's rectangle, and a band's or a scenery's whole picture; `band` is the part a
## band or a scenery is cut to (no area for the whole); `pass` counts the times `canvas` was drawn
## before this one, and `frame` is the process frame it was drawn in. A scenery's `canvas` is the
## scenery node itself, which the look stands behind its slice.
var draws: Array[Dictionary] = []

## How many times each canvas the look has drawn on was drawn again after the first, by instance id:
## its `draw` signal, emitted before every `_draw()` but the one it was first seen in, counts them.
var _passes := {}

## What the scenery this builds lays its pictures through, handed on to it through
## `EventScenery.drawer` in place of the one the real drawer hands; null to keep that one.
var scenery_drawer: SceneryDrawer = null

func _init(atlas: AtlasLibrary = null) -> void:
	super(atlas)

func stand(canvas: CanvasItem, picture: String, foot: Vector2, size := Vector2.ZERO,
		mirrored := false, colour := Color.WHITE) -> void:
	var extent := size if size != Vector2.ZERO else EventPictures.native_size(picture)
	_record(canvas, &"stand", picture, Rect2(foot - Vector2(extent.x * 0.5, extent.y), extent),
			foot, extent, mirrored, colour)

func paint(canvas: CanvasItem, picture: String, rect: Rect2, colour := Color.WHITE) -> void:
	_record(canvas, &"paint", picture, rect, rect.position, rect.size, false, colour)

func paint_band(canvas: CanvasItem, picture: String, whole: Rect2, band: Rect2) -> void:
	_record(canvas, &"band", picture, whole, whole.position, whole.size, false, Color.WHITE, band)

func caret(canvas: CanvasItem, at: Vector2, width: float, colour: Color) -> void:
	_record(canvas, &"caret", "", Rect2(at - Vector2(width, width * 0.8), Vector2(width * 2.0, width * 1.3)),
			at, Vector2(width, width), false, colour)

func scenery(picture: String, extent: Vector2, anchor: Vector2, shadow: String,
		band: Rect2) -> EventScenery:
	var built := super(picture, extent, anchor, shadow, band)
	if scenery_drawer != null:
		built.drawer = scenery_drawer
	draws.append({"canvas": built, "kind": &"scenery", "picture": picture, "foot": anchor,
		"size": extent, "rect": Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent),
		"mirrored": false, "colour": Color.WHITE, "band": band, "pass": 0,
		"frame": Engine.get_process_frames()})
	return built

func _record(canvas: CanvasItem, kind: StringName, picture: String, rect: Rect2, foot: Vector2,
		size: Vector2, mirrored: bool, colour: Color, band := Rect2()) -> void:
	draws.append({"canvas": canvas, "kind": kind, "picture": picture, "foot": foot, "size": size,
		"rect": rect, "mirrored": mirrored, "colour": colour, "band": band,
		"pass": _pass_of(canvas), "frame": Engine.get_process_frames()})

## Which time `canvas` is being drawn now, 0 for the first, counting from its `draw` signal.
func _pass_of(canvas: CanvasItem) -> int:
	var id := canvas.get_instance_id()
	if not _passes.has(id):
		_passes[id] = 0
		canvas.draw.connect(func() -> void: _passes[id] += 1)
	return _passes[id]

## What `canvas` shows now: the draws of the time it was last drawn, in order, since a retained
## `_draw()` paints the whole of its part again each time it runs. Keyed on the canvas's own count
## of draws (`_pass_of()`), so a canvas drawn again with nothing on it shows nothing, rather than
## what an earlier draw left. Empty before its first draw.
func shown_on(canvas: CanvasItem) -> Array[Dictionary]:
	var last: Array[Dictionary] = []
	var id := canvas.get_instance_id()
	if not _passes.has(id):
		return last
	var current: int = _passes[id]
	for entry in draws:
		if entry.canvas == canvas and entry.pass == current:
			last.append(entry)
	return last

## Every canvas the look has drawn on, in the order each was first drawn.
func canvases() -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	for entry in draws:
		if entry.canvas != null and not found.has(entry.canvas):
			found.append(entry.canvas)
	return found

## What every canvas shows now (`shown_on()`), the canvases in the order `canvases()` gives.
func shown() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for canvas in canvases():
		all.append_array(shown_on(canvas))
	return all

## `entry`'s rectangle in `instance`'s own space: where the picture lands about the event's origin,
## whichever canvas it was drawn on (the instance, one of its slices, its band).
static func rect_about(entry: Dictionary, instance: EventInstance) -> Rect2:
	var rect: Rect2 = entry.rect
	var canvas := entry.canvas as Node2D
	if canvas != null and canvas != instance:
		rect.position += canvas.global_position - instance.global_position
	return rect

## `entry`'s foot in `instance`'s own space (`rect_about()`).
static func foot_about(entry: Dictionary, instance: EventInstance) -> Vector2:
	var foot: Vector2 = entry.foot
	var canvas := entry.canvas as Node2D
	if canvas != null and canvas != instance:
		foot += canvas.global_position - instance.global_position
	return foot
