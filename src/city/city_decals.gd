class_name CityDecals
extends Node2D
## Loose litter, drawn flat: no body, no field, no y-sort. Placed between `Ground` and
## `Buildings` in `city.tscn`, both at the scene's default `z_index` of 0, so a decal always lies
## under a building or an entity and never sorts against either the way a `Prop` does — the
## milestone's own words are "they lie under everything".
##
## `City._place_litter()` rebuilds `_placed` once a day, the same as `_dress_blocks()` rebuilds
## `_props`, and calls `queue_redraw()`; nothing here rolls its own placement.

var _placed: Array[Litter.Placed] = []

func set_placed(placed: Array[Litter.Placed]) -> void:
	_placed = placed
	queue_redraw()

func _draw() -> void:
	for entry in _placed:
		var texture := TextureResolver.resolve(Litter.TEXTURES[entry.texture_index])
		draw_texture(texture, entry.position - texture.get_size() * 0.5)
