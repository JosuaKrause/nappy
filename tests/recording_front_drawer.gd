extends FrontDrawer
## A front drawer that records what a building tells it to paint instead of painting it, handed to a
## building through `Building.front_drawer` the way the city hands the real one. A check reads the
## pictures a front was drawn with off this, without reading what the building holds; which picture
## a front shows where is the building's to decide, and how a picture looks on a canvas is the real
## drawer's.

## Every picture the building asked for, in order: `{"canvas", "picture", "at", "colour",
## "standing", "frame"}`. `at` is the top-left corner of a `paint()` and the foot of a `stand()`,
## in `canvas`'s own space; `standing` says which of the two it was; `frame` is the process frame
## the building drew it in.
var draws: Array[Dictionary] = []

func _init() -> void:
	super(null)

func paint(canvas: CanvasItem, picture: StringName, at: Vector2, colour := Color.WHITE) -> void:
	draws.append({"canvas": canvas, "picture": picture, "at": at, "colour": colour,
		"standing": false, "frame": Engine.get_process_frames()})

func stand(canvas: CanvasItem, picture: StringName, foot: Vector2) -> void:
	draws.append({"canvas": canvas, "picture": picture, "at": foot, "colour": Color.WHITE,
		"standing": true, "frame": Engine.get_process_frames()})

## What the front shows now: the draws of the last frame it was drawn in, since a retained
## `_draw()` paints the whole front again each time it runs and a canvas is drawn at most once a
## frame. Empty before the first draw.
func shown() -> Array[Dictionary]:
	var last: Array[Dictionary] = []
	if draws.is_empty():
		return last
	var frame: int = draws.back().frame
	for entry in draws:
		if entry.frame == frame:
			last.append(entry)
	return last

## The pictures the front shows now, in the order they were drawn.
func pictures() -> Array[StringName]:
	var names: Array[StringName] = []
	for entry in shown():
		names.append(entry.picture)
	return names
