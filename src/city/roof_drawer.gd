class_name RoofDrawer
extends RefCounted
## What a building draws its roof units through: one `draw()` call per unit its roof layout places
## (`Building.roof_layout()`), told which layer, which cell, which picture, where its foot stands,
## and how a duct section joins. The city builds one over its atlas and hands it to every building
## it builds (`City._spawn_buildings()`); a building nobody handed one (a developer's preview rig)
## makes its own over its own atlas when it first enters the tree.
##
## The building decides what stands on its roof and where; this decides what a unit looks like in
## the world. Kept apart so each is tested apart: a test hands a building a drawer that records what
## it is told to draw instead of drawing it, and checks that every unit the layout places was drawn
## at its foot, without reading what the building holds.

var _atlas: AtlasLibrary

func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Stands one roof unit's picture in `layer` with its foot at `at`, in `layer`'s own space, and
## returns it; the building keeps it and frees it when its roof is rebuilt, evicted or leaves the
## tree. `duct_links` is the unit's west, east, south and north duct neighbours as bits 0 to 3, or
## -1 for a unit that draws its whole picture. The vent housing gets its turning rotor
## (`RoofObject.rotor`), shown at `rotor_frame_b`, since the building owns the rotor's phase and
## timing and a rebuild must not reset it. The object is named after `cell`, and added before
## the next is drawn, so units at one depth keep the order the building draws them in.
func draw(layer: Node2D, cell: Vector2i, texture_key: StringName, at: Vector2, duct_links: int,
		rotor_frame_b: bool) -> Building.RoofObject:
	var object := Building.RoofObject.new()
	object.atlas = _atlas
	object.name = "RoofObject_%d_%d" % [cell.x, cell.y]
	object.texture_key = texture_key
	object.duct_links = duct_links
	object.position = at
	layer.add_child(object)
	if texture_key == Building.VENT_HOUSING:
		object.add_rotor(rotor_frame_b)
	return object
