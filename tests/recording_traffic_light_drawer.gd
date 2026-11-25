extends TrafficLightDrawer
## A signal head drawer that records what a head tells it to draw instead of drawing it, handed to
## a head through `TrafficLight.drawer` the way the city hands the real one. A check reads which
## view a head was drawn in and which lamp it showed off this, without reading what the head holds.

## Every head drawn, in order: `{"canvas", "picture", "mirrored", "lamps", "frame"}`, where
## `lamps` is each `{"lamp", "edge_on", "mirrored"}` painted on that head after it was stood, and
## `frame` is the process frame it was drawn in.
var heads: Array[Dictionary] = []

func _init() -> void:
	super(null)

## Overrides TrafficLightDrawer.draw_head.
func draw_head(canvas: CanvasItem, picture: StringName, mirrored: bool) -> void:
	heads.append({"canvas": canvas, "picture": picture, "mirrored": mirrored, "lamps": [],
		"frame": Engine.get_process_frames()})

## Overrides TrafficLightDrawer.draw_lamp.
func draw_lamp(canvas: CanvasItem, lamp: int, edge_on: bool, mirrored: bool) -> void:
	# A lamp painted with no head under it is recorded as a head of its own with no picture, so a
	# check that every lamp stands on a head sees it.
	if heads.is_empty() or heads.back()["frame"] != Engine.get_process_frames():
		heads.append({"canvas": canvas, "picture": &"", "mirrored": false, "lamps": [],
			"frame": Engine.get_process_frames()})
	var head: Dictionary = heads.back()
	var lamps: Array = head["lamps"]
	lamps.append({"lamp": lamp, "edge_on": edge_on, "mirrored": mirrored})

## The head as it is drawn now, the last one drawn, or an empty dictionary before the first draw.
func shown() -> Dictionary:
	return heads.back() if not heads.is_empty() else {}
