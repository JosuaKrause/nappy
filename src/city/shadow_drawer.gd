class_name ShadowDrawer
extends RefCounted
## What the buildings' shadows (`BuildingShadows`) are drawn through: one `draw()` call per shadow
## chunk each time the chunk is drawn, told which canvas and which tiles it shades. The city builds
## one and hands it to its shadows (`BuildingShadows.drawer`) before it builds.
##
## The shadows decide which tiles are shaded, from the union of the buildings' footprints, and
## which chunk draws each; this decides what a shaded tile looks like on the canvas, a whole tile or
## its corner triangle in the shadow's flat dark. Kept apart so each is tested apart: a test hands
## the shadows a drawer that records the tiles each chunk is told to draw instead of drawing them,
## and checks them against the footprints, without reading what the shadows hold.

## Draws `tiles` on `canvas`, in world coordinates (every chunk sits at the origin): each full tile
## whole, and each corner triangle as the half of its tile on the building's side of the cut from
## its north-east corner to its south-west corner.
func draw(canvas: CanvasItem, tiles: BuildingShadows.Tiles) -> void:
	var tile_size := BuildingShadows.TILE
	var colour := Color(Palette.SHADOW.r, Palette.SHADOW.g, Palette.SHADOW.b,
			BuildingShadows.BUILDING_SHADOW_ALPHA)
	for tile in tiles.full:
		canvas.draw_rect(Rect2(Vector2(tile) * tile_size, Vector2.ONE * tile_size), colour)
	for tile in tiles.triangles:
		var origin := Vector2(tile) * tile_size
		# North-west, north-east, south-west: the half of the tile on the building's own side of
		# the north-east-to-south-west cut, which is why the whole top edge — the edge shared with
		# the building to the north — is one side of this triangle rather than split by it.
		canvas.draw_colored_polygon(PackedVector2Array([
			origin,
			origin + Vector2(tile_size, 0.0),
			origin + Vector2(0.0, tile_size),
		]), colour)
