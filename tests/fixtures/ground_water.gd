class_name GroundWater
extends RefCounted
## Whether the scenery ground has water on a tile: read off the water surfaces a resident chunk
## stands (`SceneryWater`, which draws its cells), since the game never asks this of the ground, only
## draws it. A chunk that is not resident has none.

static func at(ground: SceneryGround, tile: Vector2i) -> bool:
	var layer: TileMapLayer = ground.chunks().get(SceneryGround.key_for(tile))
	if layer == null:
		return false
	for child in layer.get_children():
		if child is SceneryWater and (child as SceneryWater).cells.has(tile):
			return true
	return false
