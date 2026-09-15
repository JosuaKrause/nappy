class_name CityDecals
extends Node2D
## Loose litter and street-tree beds, drawn flat: no body, no field, no y-sort. Placed between
## `Ground` and `Buildings` in `city.tscn`, so a decal always lies under a building or an entity
## and never sorts against either the way a `Prop` does. The beds remain on this layer even though
## their standing trees belong to the y-sorted `Entities` layer.
##
## `City` calls `set_placed(Litter.placed(map, day))` once a day, the same as `_dress_blocks()`
## rebuilds `_props`; nothing here rolls its own placement.

var _placed: Array[Litter.Placed] = []
var _street_tree_pits: Array[StreetTrees.Planted] = []
var _map: CityMap = null

const TREE_PIT := preload("res://assets/props/tree_pit.svg")

## The one `TextureAtlas` group the street's decoration is drawn from — the five litter decals and
## the tree bed here, and the trees, the bollard, the swing frame, the garbage sack and its pile
## that `Prop` draws. One group rather than two, because they are placed and dressed together
## (`City.build()` asks for it, `City._exit_tree()` hands it back) and a street shows them
## together: a sack on the kerb beside a tree over a bed of litter is exactly the run of sprites
## the composite was asked to stop breaking between.
const DECORATION_ATLAS := "decoration"

## Every picture in that group, keyed by the source texture itself — what both `_draw()` here and
## `Prop._draw()` have in hand when they ask for the region standing in for it.
static func decoration_sources() -> Dictionary:
	var sources: Dictionary = {}
	for texture: Texture2D in Litter.TEXTURES:
		sources[texture] = texture
	for texture: Texture2D in Prop.TREES:
		sources[texture] = texture
	var rest: Array[Texture2D] = [
		TREE_PIT, Prop.SWING_FRAME, Prop.BOLLARD, Prop.SACK, Prop.SACK_PILE,
	]
	for texture in rest:
		sources[texture] = texture
	return sources

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
		var source: Texture2D = Litter.TEXTURES[entry.texture_index]
		var texture := TextureAtlas.texture_for(DECORATION_ATLAS, source, source)
		draw_texture(texture, entry.position - texture.get_size() * 0.5)
	var pit := TextureAtlas.texture_for(DECORATION_ATLAS, TREE_PIT, TREE_PIT)
	for entry in _street_tree_pits:
		if _map and _map.is_tree_pit_emptied(entry.tile):
			continue
		draw_texture(pit, entry.position - pit.get_size() * 0.5)
