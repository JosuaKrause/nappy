extends FrontDrawer
## A front drawer that records what a building tells it to paint instead of painting it, handed to a
## building through `Building.equip()` the way the city hands the real one. A check reads the
## pictures a front was drawn with off this, without reading what the building holds; which picture
## a front shows where is the building's to decide, and how a picture looks on a canvas is the real
## drawer's.

## Every picture the building asked for, in order: `{"canvas", "picture", "at", "colour",
## "standing", "mirrored", "frame"}`. `at` is the top-left corner of a `paint()` and the foot of a
## `stand()`, in `canvas`'s own space; `standing` says which of the two it was, and `mirrored`
## whether a `stand()` was mirrored; `frame` is the process frame the building drew it in.
var draws: Array[Dictionary] = []

func _init() -> void:
	super(null)

## Overrides FrontDrawer.paint.
func paint(canvas: CanvasItem, picture: StringName, at: Vector2, colour := Color.WHITE) -> void:
	draws.append({"canvas": canvas, "picture": picture, "at": at, "colour": colour,
		"standing": false, "mirrored": false, "frame": Engine.get_process_frames()})

## Overrides FrontDrawer.stand.
func stand(canvas: CanvasItem, picture: StringName, foot: Vector2, mirrored := false) -> void:
	draws.append({"canvas": canvas, "picture": picture, "at": foot, "colour": Color.WHITE,
		"standing": true, "mirrored": mirrored, "frame": Engine.get_process_frames()})

## What the front shows now: on each canvas it was drawn on (its own, and the power station's yard
## layer), the draws of the last frame that canvas was drawn in, since a retained `_draw()` paints
## the whole canvas again each time it runs and a canvas is drawn at most once a frame. Empty before
## the first draw.
func shown() -> Array[Dictionary]:
	var last_frame := {}
	for entry in draws:
		last_frame[entry.canvas] = entry.frame
	var last: Array[Dictionary] = []
	for entry in draws:
		if entry.frame == last_frame[entry.canvas]:
			last.append(entry)
	return last

## The pictures the front shows now, in the order they were drawn.
func pictures() -> Array[StringName]:
	var names: Array[StringName] = []
	for entry in shown():
		names.append(entry.picture)
	return names
