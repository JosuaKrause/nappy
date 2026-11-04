class_name Footprint
extends RefCounted
## **One solid's ground contact**, the one datum both of its answers to "is this ground taken" come
## from: the physics body that stops her (`body()`) and the tiles a map's blocked record holds for
## everything else that moves (`tiles()`, written into `BlockedLayer.obstruct()`). A solid with only
## one of the two is solid to one side and see-through to the other; built from one footprint, the
## body and the record cannot disagree.
##
## **A footprint is pieces**: each a `GroundShape` (a disc, a capsule or a rectangle) at an offset
## from the solid's own origin, its spine lying along an axis. Almost every solid is one piece at its
## origin; a crash is a car per piece, with the debris between them open ground. A long solid — a
## band, a spread, a fence — is one piece whose length lies along its axis, which is what a drawing
## that slices it at the feet reads (`Piece.span()`, `DrawLayer.run_of()`).

class Piece:
	extends RefCounted
	var shape: GroundShape
	## Where the piece stands, from the solid's own origin.
	var offset := Vector2.ZERO
	## The way the piece's spine lies on the ground (`GroundShape.tiles_under()`).
	var axis := Vector2.RIGHT

	## How far the piece reaches from its middle along its length: a disc's or a capsule's reach
	## along its axis, a rectangle's longer half side.
	func half_length() -> float:
		if shape.kind == GroundShape.Kind.RECT:
			return maxf(shape.half_extents.x, shape.half_extents.y)
		return shape.reach()

	## The two ends of the piece along its length on the ground with the solid's origin at `at`,
	## the end up or left of the screen first: the run a drawing that slices it at the feet covers
	## (`DrawLayer.run_of()`). A rectangle lies its own frame along `axis`, as its body does
	## (`Footprint.body()`), so its length is along `axis` or across it, whichever side is longer.
	func span(at: Vector2) -> PackedVector2Array:
		var along := axis.normalized()
		if shape.kind == GroundShape.Kind.RECT and shape.half_extents.y > shape.half_extents.x:
			along = along.orthogonal()
		if along.y < 0.0 or (is_zero_approx(along.y) and along.x < 0.0):
			along = -along
		var middle := at + offset
		var half := half_length()
		return PackedVector2Array([middle - along * half, middle + along * half])

var pieces: Array[Piece] = []

## A footprint of one piece at the origin.
static func of(shape: GroundShape, axis := Vector2.RIGHT) -> Footprint:
	return Footprint.new().add(shape, Vector2.ZERO, axis)

## Adds a piece and answers this footprint, so pieces chain.
func add(shape: GroundShape, offset: Vector2, axis := Vector2.RIGHT) -> Footprint:
	var piece := Piece.new()
	piece.shape = shape
	piece.offset = offset
	piece.axis = axis
	pieces.append(piece)
	return self

## Every tile this footprint stands on with its origin at `at`, each once: a tile is in when a
## piece covers its middle (`GroundShape.tiles_under()`, which says why the middle is the rule).
func tiles(at: Vector2) -> Array[Vector2i]:
	var covered: Array[Vector2i] = []
	for piece in pieces:
		for tile in piece.shape.tiles_under(at + piece.offset, piece.axis):
			# Two pieces may overhang one tile, and the record counts bodies, not pieces: a body that
			# recorded one tile twice would need two releases to give it back.
			if not covered.has(tile):
				covered.append(tile)
	return covered

## The physics body of this footprint, its origin at the body's own: one `StaticBody2D` with one
## `CollisionShape2D` per piece, each the piece's own collision resource
## (`GroundShape.collision_shape()`) at its offset and turned so its spine lies along its axis. A
## capsule stands along local Y by default, so a segment turns by its axis less a quarter turn; a
## rectangle is laid out in its own frame, so it turns by its axis.
func body() -> StaticBody2D:
	var solid := StaticBody2D.new()
	for piece in pieces:
		var collision := CollisionShape2D.new()
		collision.shape = piece.shape.collision_shape()
		collision.position = piece.offset
		match piece.shape.kind:
			GroundShape.Kind.SEGMENT:
				collision.rotation = piece.axis.angle() - PI * 0.5
			GroundShape.Kind.RECT:
				if piece.axis != Vector2.RIGHT:
					collision.rotation = piece.axis.angle()
		solid.add_child(collision)
	return solid
