class_name BodyPiece
extends RefCounted
## **One solid piece of a row's body**: where it sits along the scene's own spread axis, and the
## `GroundShape` it collides and casts its shadow as there. A value: nothing changes it once it
## exists, so every row and copy that holds it shares it.
##
## **Almost every row is one piece at the origin**, which is what `BodySpec.pieces()` answers for a
## row that declares none. The list exists for the one scene whose picture leaves real ground open
## inside its own span: a crash is two cars with debris between them and an onlooker on each
## sidewalk, and a body spanning the whole street would be a wall where the picture shows a way
## through.
##
## **The pieces are a subset of the body's shape.** `EventDef.validate()` refuses a piece reaching
## past the shape's own reach, so `BodySpec.obstructs_within()` stays an upper bound on every body
## the row puts down, and every planner can read that one disc without knowing pieces exist.
##
## **Two offsets, because a wide scene has two authored pictures.**
## `EventPictures.wide_scene_texture` picks a composition per street axis rather than rotating one,
## so where the cars sit is a fact about the picture in use. `along` is read off the north-south
## asset and `along_vertical` off its `_vertical` sibling, both at the scale
## `SpreadLook._draw_wide_scene` fits the picture to the street.

## Offset along the spread axis, in px from the scene's own centre, on a north-south street.
var _along := 0.0
## The same, off the `_vertical` picture, on an east-west street.
var _along_vertical := 0.0
var _shape: GroundShape = null

## A piece `along` px from the scene's centre on a north-south street and `along_vertical` on an
## east-west one, colliding and casting its shadow as `shape`. **A piece is made with its shape**,
## so a piece with no shape cannot be written; a null one is refused here.
static func at(along: float, along_vertical: float, shape: GroundShape) -> BodyPiece:
	if shape == null:
		push_error("a body piece is made with a shape to collide and cast its shadow as")
	var made := BodyPiece.new()
	made._along = along
	made._along_vertical = along_vertical
	made._shape = shape
	return made

## The offset the instance places this piece at, given whether its body lies down the screen
## (`EventBody.runs_vertically()`).
func offset_for(vertical: bool) -> float:
	return _along_vertical if vertical else _along

## The furthest this piece reaches from the scene's own centre, on the worse of the two axes: what
## `BodySpec.solid_reach()` maximises and what `EventDef.validate()` holds inside the body's own
## reach.
func reach() -> float:
	return maxf(absf(_along), absf(_along_vertical)) + _shape.reach()

## The `GroundShape` this piece collides and casts its shadow as.
func ground_shape() -> GroundShape:
	return _shape
