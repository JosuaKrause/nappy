class_name ScreenCover
extends RefCounted
## The parts of the screen the on-screen controls cover, as plain rectangles in the box the
## controls are authored in, handed to `VisibleView` so the world layer needs no class or group from
## the UI to know what she cannot see *(feathery-lynx, inbox #581)*.
##
## **Made and kept by the UI that owns the controls** (`TouchControls.covering`), which puts it in
## or out of force when the scheme changes (`put_in_force()`); handed to whoever asks "can she see
## it" (`main` hands it to each `EventManager`, `EventManager.use_controls()`). `VisibleView` lays
## `left_corner()` and `right_corner()` onto the world view by the ratio of the view's size to
## `design_box()`.

## The box the corners are in: the 1280x720 design box, whichever way a portrait touch window
## presents the game (the controls and the world turn together).
var design_size := Vector2.ONE
## The two covered corners, each from its screen edge to its disc's far edge and from its top down.
var _left := Rect2()
var _right := Rect2()
## Whether the scheme that draws the discs in those corners is the one in force. In the other, the
## whole view counts.
var _in_force := false

func _init(design: Vector2 = Vector2.ONE, left_corner := Rect2(), right_corner := Rect2()) -> void:
	design_size = design
	_left = left_corner
	_right = right_corner

## Whether the scheme that draws the discs in the corners is the one in force now.
func is_in_force() -> bool:
	return _in_force

## Puts the scheme in or out of force: out, the whole view counts.
func put_in_force(now: bool) -> void:
	_in_force = now

## The size of the design box the corners are measured in.
func design_box() -> Vector2:
	return design_size

## The left covered corner, in the design box.
func left_corner() -> Rect2:
	return _left

## The right covered corner, in the design box.
func right_corner() -> Rect2:
	return _right
