extends ShadowDrawer
## A shadow drawer that records the tiles each shadow chunk is told to draw instead of drawing them,
## handed to the shadows through `BuildingShadows.drawer` the way the city hands the real one. A
## check reads which tiles a chunk shades off this, without reading what the shadows hold; which
## tiles are shaded, and which chunk draws each, is the shadows' to decide, and what a shaded tile
## looks like is the real drawer's.

## Every chunk drawn, in order: `{"canvas", "full", "triangles"}`, the canvas being the chunk's own
## and the two lists copies of the tiles it was told to draw.
var draws: Array[Dictionary] = []

func draw(canvas: CanvasItem, tiles: BuildingShadows.Tiles) -> void:
	draws.append({"canvas": canvas, "full": tiles.full.duplicate(),
		"triangles": tiles.triangles.duplicate()})

## What every chunk still standing shades now: the last draw of each canvas its owner has not
## freed, in the order each was first drawn. A chunk is drawn through one call per pass, so its
## last call is what it shows.
func shown() -> Array[Dictionary]:
	var last := {}
	var order: Array[CanvasItem] = []
	for entry in draws:
		if not is_instance_valid(entry.canvas):
			continue
		if not last.has(entry.canvas):
			order.append(entry.canvas)
		last[entry.canvas] = entry
	var all: Array[Dictionary] = []
	for canvas in order:
		all.append(last[canvas])
	return all
