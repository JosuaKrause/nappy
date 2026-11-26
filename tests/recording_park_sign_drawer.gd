extends ParkSignDrawer
## A park sign drawer that records what a sign tells it to draw instead of drawing it, handed to a
## sign through `ParkSign.mount()` the way the city hands the real one. A check reads which picture
## a sign was drawn as off this, without reading what the sign holds.

## Every picture drawn, in order.
var pictures: Array[StringName] = []

func _init() -> void:
	super(null)

## Overrides ParkSignDrawer.draw_sign.
func draw_sign(_canvas: CanvasItem, picture: StringName) -> void:
	pictures.append(picture)

## The picture drawn last, or an empty name before the first draw.
func shown() -> StringName:
	return pictures.back() if not pictures.is_empty() else &""
