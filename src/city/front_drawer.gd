class_name FrontDrawer
extends RefCounted
## What a building paints its front through: one call per picture on its front, told which canvas,
## which picture and where. `paint()` lays a picture of the front's grid (a wall cell, a window, a
## wall or roof edge, a ground-floor shop, a roof cell, the power station's cladding and clerestory
## band) with its top-left corner at a spot; `stand()` stands an overlay (a door, the civic portico,
## a fire-escape balcony, the power station's door) on its foot. The city builds one over its atlas
## and hands it to every building it builds (`City._spawn_buildings()`); a building nobody handed
## one (a suite's, a developer's preview rig) makes its own over its own atlas when it first enters
## the tree.
##
## The building decides which picture its front shows where (a burnt parapet, a lit clerestory, a
## shuttered shop); this decides what a picture looks like on the canvas. Kept apart so each is
## tested apart: a test hands a building a drawer that records what it is told to paint instead of
## painting it, and checks the pictures the front was drawn with, without reading what the
## building holds. The posters pasted on a front are not drawn through this: their picture is
## `PosterArt`'s, which the posters suite tests.

var _atlas: AtlasLibrary

func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Paints `picture`, a region of the `buildings` atlas group, on `canvas` with its top-left corner
## at `at`, in `canvas`'s own space, tinted by `colour` (white for a picture drawn in its own
## colours).
func paint(canvas: CanvasItem, picture: StringName, at: Vector2, colour := Color.WHITE) -> void:
	canvas.draw_texture(_atlas.region(picture), at, colour)

## Stands `picture` on `canvas` with the middle of its bottom edge at `foot`, in `canvas`'s own
## space (`Sprites.draw_standing()`).
func stand(canvas: CanvasItem, picture: StringName, foot: Vector2) -> void:
	Sprites.draw_standing(canvas, _atlas.region(picture), foot)
