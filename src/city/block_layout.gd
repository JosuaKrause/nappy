class_name BlockLayout
extends RefCounted
## The fixed geometry of one block: which rects were carved out of it at generation.
##
## Separating this from `BlockPurpose` is what lets a block change what it *is* without
## changing what it *looks like the shape of*. The layout is decided once, from the run
## seed; the purpose decides only which ground goes in the open rect. Repainting a block on
## a later day therefore re-rolls nothing — the same court is a court on day 1 and churned
## mud on day 12, in the same place, the same size.
##
## Empty rects mean "this block has none of that".

## The block's open ground: the whole lot for a park, a forest or a quiet square; the court
## for a courtyard block; empty for a plain built one. This is the rect whose tile type
## follows the purpose.
var open_rect := Rect2i()
## The playground inside a park. Only a park has one, and it goes with the park: a
## requisitioned park has no swings in it.
var playground := Rect2i()
## The market plaza carved out of a commercial block. Stays whatever happens to the block —
## paving does not care who is in charge.
var square := Rect2i()
## The through-alley, if this block has one.
var alley := Rect2i()
## The archway from a courtyard out to the street. A court with no way in is a hole in the
## map, which is exactly what the first version of this was — the connectivity check caught
## it on every seed. It is paved as an alley on purpose: reaching hidden calm costs a few
## seconds of somewhere you would rather not be.
var passage := Rect2i()

## The same carves as a layout of its own (`CityMap.copy()`).
func copy() -> BlockLayout:
	var twin := BlockLayout.new()
	twin.open_rect = open_rect
	twin.playground = playground
	twin.square = square
	twin.alley = alley
	twin.passage = passage
	return twin

## The block's open ground (`open_rect`), empty for a plain built block.
func open_ground() -> Rect2i:
	return open_rect

## Whether the block has open ground.
func has_open_ground() -> bool:
	return has(open_rect)

## Carves the block's open ground out of it at generation.
func carve_open_ground(rect: Rect2i) -> void:
	open_rect = rect

## The playground inside a park (`playground`), empty on any other block.
func playground_rect() -> Rect2i:
	return playground

## Whether the block has a playground.
func has_playground() -> bool:
	return has(playground)

## Carves the playground out of the park at generation.
func carve_playground(rect: Rect2i) -> void:
	playground = rect

## The market plaza of a commercial block (`square`), empty on any other block.
func square_rect() -> Rect2i:
	return square

## Whether the block has a plaza.
func has_square() -> bool:
	return has(square)

## Carves the plaza out of the block at generation.
func carve_square(rect: Rect2i) -> void:
	square = rect

## The through-alley (`alley`), empty on a block with none.
func alley_rect() -> Rect2i:
	return alley

## Whether the block has a through-alley.
func has_alley() -> bool:
	return has(alley)

## Carves the through-alley out of the block at generation.
func carve_alley(rect: Rect2i) -> void:
	alley = rect

## The archway from a courtyard to the street (`passage`), empty on a block with none.
func passage_rect() -> Rect2i:
	return passage

## Whether the block has an archway.
func has_passage() -> bool:
	return has(passage)

## Carves the archway out of the block at generation.
func carve_passage(rect: Rect2i) -> void:
	passage = rect

static func has(rect: Rect2i) -> bool:
	return rect.size.x > 0 and rect.size.y > 0
