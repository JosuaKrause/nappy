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

static func has(rect: Rect2i) -> bool:
	return rect.size.x > 0 and rect.size.y > 0
