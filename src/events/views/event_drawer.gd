class_name EventDrawer
extends RefCounted
## What an event's look paints its pictures through: one call per picture of the `events` atlas
## group, told which canvas, which picture and where. `stand()` stands a picture on its foot (a
## figure, a vehicle, a segment or an end post of a spread, a café table, a flame);
## `paint()` lays one into a rectangle (a wide scene's contact shadow, a checkpoint's gate and hut);
## `paint_band()` lays the part of a wide scene that falls in one slice's band; and `scenery()`
## builds the scenery that stands behind one slice of a crash or a burst main. The event's manager
## builds one over its atlas (`EventManager.atlas`) and every instance it makes is handed it
## (`EventSpawner.create()`, `EventInstance.drawer`); an instance nobody handed one (a suite's, a
## developer's rig) draws through one of its own over its own atlas.
##
## The look decides which picture the event shows where (a café sitter turned to her table, an end
## post inset to the barrier's end, a protest pointing at its objective); this decides what a
## picture looks like on the canvas. Kept apart so each is tested apart: a test hands an instance a
## drawer that records what it is told to paint instead of painting it, and checks the pictures the
## event was drawn with, without reading what the look holds. What is not an atlas picture is drawn
## by the look itself, as before: a ground shadow, a dog's lead, a muzzle flash, the caret.

var _atlas: AtlasLibrary

func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Stands `picture` on `canvas` with the middle of its bottom edge at `foot`, in `canvas`'s own
## space, at `size` (its own size for zero), mirrored left to right when `mirrored`, tinted by
## `colour` (`Sprites.draw_standing()`).
func stand(canvas: CanvasItem, picture: String, foot: Vector2, size := Vector2.ZERO,
		mirrored := false, colour := Color.WHITE) -> void:
	Sprites.draw_standing(canvas, EventPictures.drawn(_atlas, picture), foot, size, mirrored, colour)

## Lays `picture` on `canvas` into `rect`, in `canvas`'s own space, tinted by `colour`.
func paint(canvas: CanvasItem, picture: String, rect: Rect2, colour := Color.WHITE) -> void:
	canvas.draw_texture_rect(EventPictures.drawn(_atlas, picture), rect, false, colour)

## Lays on `canvas` the part of `picture` that falls inside `band` when the whole picture fills
## `whole`, both in `canvas`'s own space: one slice's share of a wide scene.
func paint_band(canvas: CanvasItem, picture: String, whole: Rect2, band: Rect2) -> void:
	var texture := EventPictures.drawn(_atlas, picture)
	var texels := texture.get_size() / whole.size
	canvas.draw_texture_rect_region(texture, band,
			Rect2((band.position - whole.position) * texels, band.size * texels))

## The scenery of one slice of a crash or a burst main (`EventScenery`): the part of every span of
## `picture` inside `band` when the whole picture is `extent` standing on `anchor`, and `shadow`, the
## contact shadow, whole (`""` for none). Not yet in the tree; the look puts it behind its slice.
func scenery(picture: String, extent: Vector2, anchor: Vector2, shadow: String,
		band: Rect2) -> EventScenery:
	var built := EventScenery.new()
	built.atlas = _atlas
	built.configure(picture, extent, anchor, shadow, band)
	return built
