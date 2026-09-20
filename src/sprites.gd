class_name Sprites
extends RefCounted
## Drawing helpers for the feet-anchored sprite art.
##
## Everything in this game stands on the ground plane: a node's position is where its feet
## are, and its art rises from there. That is what keeps y-sorting honest — see
## docs/CITY.md, "Rendering". These helpers exist so that rule is written once instead of
## being re-derived, slightly differently, in every `_draw()`.

## The canvas transform whoever is drawing has already put on the canvas around the
## `draw_standing()` calls it is about to make — the offset a ring of re-drawn bodies is at, the
## lift a bobbing entity rides — so the mirror below can **compose** with it instead of replacing
## it. `Transform2D.IDENTITY` for the ordinary case, where nobody has set one.
##
## **`draw_set_transform` replaces, and nothing can read back what it replaced.** Godot exposes no
## way to ask a `CanvasItem` for its current custom transform, so a helper that has to mirror about
## a point can only set an absolute matrix — and an absolute matrix is wrong the moment somebody
## outside it had already put one there. `EntityHalo` is what pays for that: it traces its owner's
## own body twelve times at a ring of offsets, one `draw_set_transform` apiece, and every **mirrored**
## view threw that offset away. The three west-facing sectors of every eight-view family — a car, a
## crowd walker, the mother, a dog walker — stacked twelve copies on top of the body and drew no rim
## at all, which is a cue silently missing for half the headings in the game.
##
## Static, and set through `set_base_transform()` below rather than passed as an argument, because
## it is a property of the drawing **pass** and not of any one sprite: threading it through
## `draw_standing()`'s own parameter list would put it on every one of the dozens of call sites that
## never need it, and a rule every caller has to remember is not a rule.
static var _base_transform := Transform2D.IDENTITY

## Tells `draw_standing()` what transform the canvas is currently under. **Always paired with the
## caller's own `draw_set_transform*` call on the canvas, and always cleared back to
## `Transform2D.IDENTITY` when the pass ends** — the two say the same thing to two different places,
## and a caller that sets one without the other leaves a later mirrored sprite drawing through an
## offset nobody asked for. `EntityHalo._on_draw()` and `EventInstance._draw()` are the two callers.
static func set_base_transform(base: Transform2D) -> void:
	_base_transform = base

## Where a mirrored `draw_standing()` actually puts its texture: the mirror about `at` composed
## **under** whatever the caller had already set, rather than the mirror alone.
##
## A function of its own rather than an expression inside the branch below, because headless runs
## never call `_draw()` — so this is the only shape of it a test can hold. See
## `tests/test_halo.gd`, "the rim's mirrored copies land on the ring".
static func mirrored_transform(at: Vector2) -> Transform2D:
	return _base_transform * Transform2D(0.0, at).scaled_local(Vector2(-1.0, 1.0))

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
	canvas.draw_set_transform_matrix(mirrored_transform(at))
	canvas.draw_texture_rect(texture,
			Rect2(-extent.x * 0.5, -extent.y, extent.x, extent.y), false, modulate)
	# Back to what the caller had, never to identity: a second layer drawn after this one — a
	# walker's trim over its body, a car's trim over its paint — is in the same pass and wants the
	# same offset. See `_base_transform`.
	canvas.draw_set_transform_matrix(_base_transform)

## The caret from the danger vocabulary — a downward chevron over an entity that is dangerous
## *right now and changingly so*. See docs/EVENTS.md, "The visual vocabulary".
##
## Deliberately not an exclamation mark: that shape is spoken for, it means *this is about you*,
## and it lives over the player's head and nowhere else.
##
## Lives here rather than on `EventInstance`, because a car needs one and a car is not an event.
## Two hand-drawn chevrons that slowly stop being the same chevron is exactly how a short
## vocabulary turns into a long one.
static func draw_caret(canvas: CanvasItem, at: Vector2, width: float, colour: Color) -> void:
	var points := PackedVector2Array([
		at + Vector2(-width, -width * 0.8),
		at + Vector2(width, -width * 0.8),
		at + Vector2(0.0, width * 0.5),
	])
	canvas.draw_colored_polygon(points, colour)
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), Palette.OUTLINE, 2.0)

## The contact shadow every standing **point** thing draws first — the mother, the pram, a walker,
## a tree, a per-part shadow inside an event, anything whose shape is a single point rather than a
## spread. The point shortcut over `GroundShape.point(radius).draw_shadow()`: something whose
## shape is not a point reads `GroundShape` directly instead of coming through here.
static func draw_shadow(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	GroundShape.point(radius).draw_shadow(canvas, at)
