class_name StandingPiece
extends RefCounted
## **One solid piece of a body where it stands on the map**: its middle in world space, its ground
## shape (a disc, a capsule or a rectangle) and the axis its spine lies along. What
## `BodyStance.pieces_at()` and `BodyStance.pieces_laid_out()` answer, so the walk's ground, the
## map's record of standing bodies, the route rig and a live body's footprint all read one layout of
## a body's pieces. Pure data, holding nothing it was not built with.

var _center := Vector2.ZERO
var _shape: GroundShape
var _axis := Vector2.RIGHT

func _init(at: Vector2, piece_shape: GroundShape, along: Vector2) -> void:
	_center = at
	_shape = piece_shape
	_axis = along

## Where the piece's middle stands, in world space.
func center() -> Vector2:
	return _center

## The piece's shape: a disc, a capsule or a rectangle.
func ground_shape() -> GroundShape:
	return _shape

## The way the piece's spine lies on the ground (`BodyStance.solid_axis_of()`'s answer, a unit vector).
func axis() -> Vector2:
	return _axis

## The tiles whose middle the piece covers (`GroundShape.tiles_under()`, which says why the middle
## is the rule), the tile its own middle stands on first.
func tiles() -> Array[Vector2i]:
	return _shape.tiles_under(_center, _axis)
