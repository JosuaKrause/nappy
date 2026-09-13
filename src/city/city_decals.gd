class_name CityDecals
extends Node2D
## Loose litter and street-tree beds, drawn flat: no body, no field, no y-sort. Placed between
## `Ground` and `Buildings` in `city.tscn`, so a decal always lies under a building or an entity
## and never sorts against either the way a `Prop` does. The beds remain on this layer even though
## their standing trees belong to the y-sorted `Entities` layer.
##
## `City._place_litter()` rebuilds `_placed` once a day, the same as `_dress_blocks()` rebuilds
## `_props`, and calls `queue_redraw()`; nothing here rolls its own placement.

var _placed: Array[Litter.Placed] = []
var _street_tree_pits: Array[StreetTrees.Planted] = []
var _map: CityMap = null

const TREE_PIT := preload("res://assets/props/tree_pit.svg")

func set_placed(placed: Array[Litter.Placed]) -> void:
	_placed = placed
	queue_redraw()

## Street-tree beds are flat ground marks, so they belong to this layer rather than to the
## y-sorted `Entities` layer that owns the standing tree. The planted positions remain fixed for
## the run; `CityMap` supplies which pits today's fallen-tree closures have emptied.
func set_street_tree_pits(placed: Array[StreetTrees.Planted], city_map: CityMap) -> void:
	_street_tree_pits = placed
	_map = city_map
	queue_redraw()

## Repaint after closures or seals choose an emptied pit for the day.
func refresh_street_tree_pits() -> void:
	queue_redraw()

func _draw() -> void:
	for entry in _placed:
		var texture := TextureResolver.resolve(Litter.TEXTURES[entry.texture_index])
		draw_texture(texture, entry.position - texture.get_size() * 0.5)
	var pit := TextureResolver.resolve(TREE_PIT)
	for entry in _street_tree_pits:
		if _map and _map.is_tree_pit_emptied(entry.tile):
			continue
		draw_texture(pit, entry.position - pit.get_size() * 0.5)
