extends SceneryDrawer
## A scenery drawer that records what a layer tells it to lay instead of laying it, handed to the
## owner of the layers the way the game hands the real one: to the city's decals through
## `CityDecals.drawer`, to a vent's rotor through the roof drawer's constructor (`RoofDrawer`), and
## to an event's scenery in `EventScenery.draw_through()`, which the recording event drawer hands
## its own to (`tests/recording_event_drawer.gd`). A check reads the textures a layer stood off
## this, without reading what the layer holds; which texture stands where, and which of a picture's
## two frames shows, is the layer's to decide, and how a texture is laid on a canvas is the real
## drawer's.

## Every picture a layer asked for, in order: `{"canvas", "texture", "rect", "source", "pass"}`, with
## `rect` and `source` as `draw()` was given them and `pass` the times `canvas` was drawn before
## this one. `texture` is held weakly (a `WeakRef`), so recording a picture does not keep an atlas
## region alive after its page is released; `shown_on()` and `shown()` hand it back resolved.
var draws: Array[Dictionary] = []

## How many times each canvas was drawn again after the first, by instance id: its `draw` signal,
## emitted before every `_draw()` but the one it was first seen in, counts them.
var _passes := {}

## Overrides SceneryDrawer.draw.
func draw(canvas: CanvasItem, texture: Texture2D, rect: Rect2, source: Rect2) -> void:
	draws.append({"canvas": canvas, "texture": weakref(texture), "rect": rect, "source": source,
		"pass": _pass_of(canvas)})

## Which time `canvas` is being drawn now, 0 for the first, counting from its `draw` signal.
func _pass_of(canvas: CanvasItem) -> int:
	var id := canvas.get_instance_id()
	if not _passes.has(id):
		_passes[id] = 0
		canvas.draw.connect(func() -> void: _passes[id] += 1)
	return _passes[id]

## How many times `canvas` has been drawn through this drawer: 0 before its first draw.
func passes_of(canvas: CanvasItem) -> int:
	var id := canvas.get_instance_id()
	return _passes[id] + 1 if _passes.has(id) else 0

## What `canvas` shows now: the pictures of the time it was last drawn, in order, since a retained
## `_draw()` lays every picture again each time it runs, each with its `texture` resolved (null for
## one since freed). Empty before its first draw.
func shown_on(canvas: CanvasItem) -> Array[Dictionary]:
	var last: Array[Dictionary] = []
	var id := canvas.get_instance_id()
	if not _passes.has(id):
		return last
	var current: int = _passes[id]
	for entry in draws:
		if entry.pass == current and is_instance_valid(entry.canvas) and entry.canvas == canvas:
			var resolved := entry.duplicate()
			resolved.texture = (entry.texture as WeakRef).get_ref()
			last.append(resolved)
	return last

## What every canvas still standing shows now (`shown_on()`), the canvases in the order each was
## first drawn: a canvas its owner freed shows nothing.
func shown() -> Array[Dictionary]:
	var found: Array[CanvasItem] = []
	for entry in draws:
		if is_instance_valid(entry.canvas) and not found.has(entry.canvas):
			found.append(entry.canvas)
	var all: Array[Dictionary] = []
	for canvas in found:
		all.append_array(shown_on(canvas))
	return all
