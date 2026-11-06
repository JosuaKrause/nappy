extends RefCounted
## What a `SceneryGround` has laid in its tile layers, read the way the engine reads any tile layer.
##
## The ground keeps one `TileMapLayer` per resident region (`SceneryGround.chunks`), and what it
## lays there as she walks is the whole of what it shows: a cell no resident region holds has no
## owner and answers nothing. So a suite asking which source or atlas cell a tile got, or which
## cells are laid at all, asks the layer that owns the tile with the engine's own calls, which are
## not members of the ground.

## The resident layer that owns `tile`, or null when its region is not resident.
static func layer_of(ground: SceneryGround, tile: Vector2i) -> TileMapLayer:
	return ground.chunks.get(SceneryGround.key_for(tile))

## The source id laid at `tile`, or -1 where no resident region holds it or it is empty.
static func source_id(ground: SceneryGround, tile: Vector2i) -> int:
	var layer := layer_of(ground, tile)
	return layer.get_cell_source_id(tile) if layer != null else -1

## The atlas cell laid at `tile`, or (-1, -1) where no resident region holds it or it is empty.
static func atlas_coords(ground: SceneryGround, tile: Vector2i) -> Vector2i:
	var layer := layer_of(ground, tile)
	return layer.get_cell_atlas_coords(tile) if layer != null else Vector2i(-1, -1)

## Every cell laid in a resident region, none of an unfinished one.
static func used_cells(ground: SceneryGround) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for layer: TileMapLayer in ground.chunks.values():
		cells.append_array(layer.get_used_cells())
	return cells
