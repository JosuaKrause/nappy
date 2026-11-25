class_name SceneryWater
extends Node2D
## The unreachable south water, kept off the static ground TileMap and drawn behind its chunk's
## tiles, so a tile that stands in the water (the bulkhead's sea wall,
## `GroundTiles.stands_in_water()`) shows it through the transparent part of its picture. Each
## cell is drawn from the south water's one live tile (`SouthWaterTile`), from the place in the
## tile the cell covers in the world, so the surfaces the ground streams in chunk by chunk meet
## without a seam and move as one. The tile carries the motion and its clock, so a surface draws its cells once and is never
## drawn again for the water to move.

var cells: Array[Vector2i] = []
## The tile the cells are drawn from, handed in by `use_tile()` (the ground does, before the
## surface is added). A surface handed none draws nothing.
var _tile: SouthWaterTile = null

func _init() -> void:
	# Behind the chunk's own TileMap, which is this surface's parent: the water under a sea-wall
	# cell is drawn first and the stone over it.
	show_behind_parent = true
	# Repeat, so a texel sampled at the tile's edge blends with the other edge's, its neighbour in
	# the world; linear, as the tile is drawn a texel a world pixel and magnified on screen.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

## Hands in the tile the cells are drawn from.
func use_tile(tile: SouthWaterTile) -> void:
	_tile = tile
	queue_redraw()

func configure(water_cells: Array[Vector2i]) -> void:
	if cells != water_cells:
		cells.assign(water_cells)
	queue_redraw()

func _draw() -> void:
	if _tile == null:
		return
	var picture := _tile.get_texture()
	var extent := Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	for tile in cells:
		# Unclipped, so the filter reads across the region's edge into the texels beside it.
		draw_texture_rect_region(picture, Rect2(Vector2(tile) * extent, extent),
				_tile.region_for(tile), Color.WHITE, false, false)
