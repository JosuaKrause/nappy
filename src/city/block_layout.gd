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
var _open_rect := Rect2i()
## The playground inside a park. Only a park has one, and it goes with the park: a
## requisitioned park has no swings in it.
var playground := Rect2i()
## The market plaza carved out of a commercial block. Stays whatever happens to the block —
## paving does not care who is in charge.
var _square := Rect2i()
## The through-alley, if this block has one.
var _alley := Rect2i()
## The archway from a courtyard out to the street. A court with no way in is a hole in the
## map, which is exactly what the first version of this was — the connectivity check caught
## it on every seed. It is paved as an alley on purpose: reaching hidden calm costs a few
## seconds of somewhere you would rather not be.
var _passage := Rect2i()

## The same carves as a layout of its own (`CityMap.copy()`).
func copy() -> BlockLayout:
	var twin := BlockLayout.new()
	twin._open_rect = _open_rect
	twin.playground = playground
	twin._square = _square
	twin._alley = _alley
	twin._passage = _passage
	return twin

## The block's open ground (`_open_rect`), empty for a plain built block.
func open_ground() -> Rect2i:
	return _open_rect

## Whether the block has open ground.
func has_open_ground() -> bool:
	return has(_open_rect)

## Carves the block's open ground out of it at generation.
func carve_open_ground(rect: Rect2i) -> void:
	_open_rect = rect

## The playground inside a park (`playground`), empty on any other block.
func playground_rect() -> Rect2i:
	return playground

## Whether the block has a playground.
func has_playground() -> bool:
	return has(playground)

## Carves the playground out of the park at generation.
func carve_playground(rect: Rect2i) -> void:
	playground = rect

## The market plaza of a commercial block (`_square`), empty on any other block.
func square_rect() -> Rect2i:
	return _square

## Whether the block has a plaza.
func has_square() -> bool:
	return has(_square)

## Carves the plaza out of the block at generation.
func carve_square(rect: Rect2i) -> void:
	_square = rect

## The through-alley (`_alley`), empty on a block with none.
func alley_rect() -> Rect2i:
	return _alley

## Whether the block has a through-alley.
func has_alley() -> bool:
	return has(_alley)

## Carves the through-alley out of the block at generation.
func carve_alley(rect: Rect2i) -> void:
	_alley = rect

## The archway from a courtyard to the street (`_passage`), empty on a block with none.
func passage_rect() -> Rect2i:
	return _passage

## Whether the block has an archway.
func has_passage() -> bool:
	return has(_passage)

## Carves the archway out of the block at generation.
func carve_passage(rect: Rect2i) -> void:
	_passage = rect

## The carves by name, each a tile rect, empty where the block has none: `open_rect`, `playground`,
## `square`, `alley` and `passage`. What an authored scene saves of the block (`CityMap.capture()`)
## and `restored()` makes the same layout from.
func capture() -> Dictionary:
	return {"open_rect": _open_rect, "playground": playground, "square": _square, "alley": _alley,
			"passage": _passage}

## The layout `carves` describes, as `capture()` names them.
static func restored(carves: Dictionary) -> BlockLayout:
	var layout := BlockLayout.new()
	layout._open_rect = carves["open_rect"]
	layout.playground = carves["playground"]
	layout._square = carves["square"]
	layout._alley = carves["alley"]
	layout._passage = carves["passage"]
	return layout

static func has(rect: Rect2i) -> bool:
	return rect.size.x > 0 and rect.size.y > 0
