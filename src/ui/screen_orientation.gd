class_name ScreenOrientation
extends RefCounted
## Whether and how the game presents itself rotated when the real window is portrait, so a
## player whose phone auto-rotate is off still sees a full-size landscape game rather than a
## thin letterboxed strip of one.
##
## Nothing here asks the device to rotate — no orientation lock, no manifest hint, no fullscreen
## request. `project.godot`'s `window/stretch/mode="canvas_items"` already maps every touch and
## every Control/CanvasLayer coordinate into one fixed logical box, `Window.content_scale_size`
## (1280x720 by default), regardless of the real window's own pixel size — that is why
## `TouchControls`' own `STICK_CENTRE` and friends are plain constants that already work at any
## window size. Swapping `content_scale_size` to the ROTATED box when the window is portrait asks
## Godot to do that same free mapping against the rotated shape instead, so a real touch already
## arrives in 720x1280 space; `rotation_transform()` is the one further, fixed step back into the
## 1280x720 space every screen is still authored in, needed only where a screen reads a raw
## screen-space position rather than letting a `Control`'s own anchors or `Camera2D` adapt to
## whatever `content_scale_size` currently is. `TouchControls` is the one place in `src/ui/` that
## does — `DangerEdge` and `HomeArrow` both compute their own screen position fresh every frame
## from `size` and `get_viewport().get_canvas_transform()`, so they already track a rotated,
## swapped viewport with no change of their own.

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
