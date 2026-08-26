class_name Sprites
extends RefCounted
## Drawing helpers for the feet-anchored sprite art.
##
## Everything in this game stands on the ground plane: a node's position is where its feet
## are, and its art rises from there. That is what keeps y-sorting honest — see
## docs/CITY.md, "Rendering". These helpers exist so that rule is written once instead of
## being re-derived, slightly differently, in every `_draw()`.

const SHADOW := preload("res://assets/props/shadow.svg")

## Draws `texture` standing on `at`, in the canvas's own coordinates: bottom-centre on the
## ground plane, art rising from it.
##
## `size` overrides the texture's own, which is how a fire scales its flames with what it
## is emitting and a tree scales with its variant.
static func draw_standing(canvas: CanvasItem, texture: Texture2D, at: Vector2,
		size := Vector2.ZERO, flip_h := false, modulate := Color.WHITE) -> void:
	var extent := size if size != Vector2.ZERO else texture.get_size()
	if not flip_h:
		canvas.draw_texture_rect(texture,
				Rect2(at - Vector2(extent.x * 0.5, extent.y), extent), false, modulate)
		return
	# Mirroring about `at` rather than passing a negative width: a negative-width Rect2 is
	# normalised on the way through, which slides the sprite a full width sideways off its
	# own shadow instead of flipping it.
	canvas.draw_set_transform(at, 0.0, Vector2(-1.0, 1.0))
	canvas.draw_texture_rect(texture,
			Rect2(-extent.x * 0.5, -extent.y, extent.x, extent.y), false, modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The contact shadow every standing thing draws first. Squashed on Y by the same amount
## the rest of the oblique view is, so it reads as lying on the pavement.
static func draw_shadow(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	var extent := Vector2(radius * 2.0, radius * 0.8)
	canvas.draw_texture_rect(SHADOW,
			Rect2(at - extent * 0.5, extent), false, Palette.SHADOW)
