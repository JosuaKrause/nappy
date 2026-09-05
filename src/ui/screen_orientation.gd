class_name ScreenOrientation
extends RefCounted
## Whether and how the game presents itself rotated when the real window is portrait, so a
## player whose phone auto-rotate is off still sees a full-size landscape game rather than a
## thin letterboxed strip of one.
##
## Nothing here asks the device to rotate — no orientation lock, no manifest hint, no fullscreen
## request. `project.godot`'s `window/stretch/mode="canvas_items"` already maps every touch and
## every Control/CanvasLayer coordinate into one fixed logical box, `Window.content_scale_size`
## (1280x720 by default), regardless of the real window's own pixel size. Swapping
## `content_scale_size` to the ROTATED box when the window is portrait asks Godot to do that same
## free mapping against the rotated shape instead, so a real touch already arrives in 720x1280
## space, and `rotation_transform()` is the fixed step back into the 1280x720 space every screen
## is still authored in.
##
## **One rotation, carried by every `CanvasLayer` of screen furniture.** `main._apply_orientation()`
## sets `layer.transform` to `rotation_transform()` (or `Transform2D.IDENTITY`) on every layer —
## `apply_to_layer()` is that one line, so it is written once. A layer's own children still have to
## be laid out against the fixed 1280x720 box rather than against whatever `content_scale_size`
## currently is — a `Control` anchored full-rect under a rotated layer would otherwise size itself
## to the swapped 720x1280 box and rotate that, landing a 1280x720 footprint in the wrong place —
## which is what `pin_to_design_box()` is for: a single root `Control` per layer, pinned to
## `DESIGN_SIZE` with fixed top-left anchors so its rect never depends on the viewport's own shape.
##
## `TouchControls` is the one place in `src/ui/` whose *input* needs the same correction the other
## direction: a real touch still arrives in the swapped 720x1280 box regardless of any layer
## transform, so `to_design_space()` is what remaps it back before comparing it to `STICK_CENTRE`
## and friends. `DangerEdge` and `HomeArrow` need the same remap on the way *out* — both compute a
## screen position fresh every frame from a world position and
## `get_viewport().get_canvas_transform()`, which lands in that same swapped box, and now that
## their own `Control` is pinned to the fixed design box by `pin_to_design_box()` too, that raw
## position has to go through `to_design_space()` before it is usable as a local coordinate on it.

## The box every screen in this game is authored against, matching `project.godot`'s own
## `window/size/viewport_width` and `window/size/viewport_height`.
const DESIGN_SIZE := Vector2(1280.0, 720.0)
## The same box, axes swapped — what `content_scale_size` becomes while rotated.
const ROTATED_SIZE := Vector2(720.0, 1280.0)

## Only a touch device in a portrait window rotates. A narrow desktop window is portrait too, and
## is deliberately left alone — the same reasoning the retired CSS rotate overlay in
## `export_presets.cfg` used to gate its own message on `(hover: none) and (pointer: coarse)`
## together with `(orientation: portrait)`, so a desktop window merely taller than it is wide was
## never told to rotate. `touch_available` is passed in rather than read here (`TouchInput
## .available()` is the one real place that asks the platform), so a test can ask this question
## without a touchscreen — the same split `TouchControls._touch` already makes between the
## platform fact and the policy built on it.
static func wants_rotation(window_size: Vector2, touch_available: bool) -> bool:
	return touch_available and window_size.y > window_size.x

## The `Window.content_scale_size` to present at, given whether rotation is wanted.
static func content_scale_size(rotate: bool) -> Vector2i:
	return Vector2i(ROTATED_SIZE) if rotate else Vector2i(DESIGN_SIZE)

## The fixed transform from the 1280x720 box every screen is authored in onto the 720x1280 box
## `content_scale_size` reports while rotated — a rotation and a recentre between two constant
## boxes, independent of the real window's own pixel size, because `content_scale_size` is what
## already fits either box to whatever the real window turns out to be.
static func rotation_transform() -> Transform2D:
	var t := Transform2D().rotated(deg_to_rad(90.0))
	t.origin = ROTATED_SIZE * 0.5 - t.basis_xform(DESIGN_SIZE * 0.5)
	return t

## A point already in the rotated 720x1280 box — where a real touch arrives once
## `content_scale_size` is swapped — back into the 1280x720 box `TouchControls`' own constants
## are authored against. Identity while not rotating, so a call site does not have to ask twice.
static func to_design_space(position: Vector2, rotate: bool) -> Vector2:
	if not rotate:
		return position
	return rotation_transform().affine_inverse() * position

## The other direction: a point authored in the 1280x720 box, to where it actually belongs once
## rotated. Identity while not rotating.
static func to_presented_space(position: Vector2, rotate: bool) -> Vector2:
	if not rotate:
		return position
	return rotation_transform() * position

## Pins `control`'s rect to the fixed 1280x720 box every screen is authored against — top-left
## anchors and literal offsets, so its size depends on nothing but this call, not on whatever
## `content_scale_size` currently reports. The single definition of "laid out against the design
## box" every rotating `CanvasLayer`'s root uses, instead of the same four offsets written out at
## every call site: `hud.tscn`'s inserted `Root`, `pause_screen.tscn`'s, `day_summary.tscn`'s and
## `title_screen.tscn`'s own, and the two single-node layers built in code, `DangerEdge` and
## `TouchControls`.
static func pin_to_design_box(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = DESIGN_SIZE.x
	control.offset_bottom = DESIGN_SIZE.y

## Sets `layer`'s own transform to the rotation while rotated, identity while not — the single
## definition every screen-furniture `CanvasLayer` applies, so `main._apply_orientation()` reads
## as one line per layer rather than an `if rotate: ... else: IDENTITY` repeated at each one.
static func apply_to_layer(layer: CanvasLayer, rotate: bool) -> void:
	layer.transform = rotation_transform() if rotate else Transform2D.IDENTITY
