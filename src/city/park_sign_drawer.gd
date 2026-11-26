class_name ParkSignDrawer
extends RefCounted
## What a park sign draws itself through: `draw_sign()` stands the sign's picture with its shadow
## under it. The city builds one over its atlas and hands it to every sign it stands
## (`City._spawn_park_signs()`); a sign nobody handed one (a suite's) makes its own.
##
## The sign decides which picture it shows, from the way it points; this decides how a picture is
## stood. Kept apart so each is tested apart: a test hands a sign a drawer that records what it is
## told to draw instead of drawing it, and checks which picture the sign showed.

var _atlas: AtlasLibrary

func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Stands `picture` (`ParkSign.UP`, `DOWN`, `LEFT` or `RIGHT`) on `canvas` with its foot at the
## canvas's origin and its shadow under it.
func draw_sign(canvas: CanvasItem, picture: StringName) -> void:
	# The post's own shape, a point, as a signal head's is: a `GroundShape` buys nothing here.
	Sprites.draw_shadow(canvas, Vector2.ZERO, 5.0)
	Sprites.draw_standing(canvas, _atlas.region(picture), Vector2.ZERO, Vector2.ZERO, false)
