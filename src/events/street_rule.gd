class_name StreetRule
extends RefCounted
## **One of the day's placement rules, as the invalidation the design asks for** (inbox #1185 in gentle-owl:
## "which events make which others invalid on the same street -- this is what your current rules
## accomplish. the same applies still"): whether a candidate may stand where it was built, given
## what the walk has placed and what stands round it. A rule that refuses never bends, so a
## refused candidate is not one a location draws. `StreetInvalidation` composes the rules a walk
## asks; each implementation is handed what it reads in its constructor. Model: no node.

## The four steps to a tile's neighbours, which the rules that walk ground tile by tile share.
const NEIGHBOUR_STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## Whether `candidate`, built at `tile`, may stand: `placed` is what the walk has placed so far, and
## `around` that with what stands for the day besides (the seals, the region wall's own bodies),
## which a rule about reaching across ground asks as well. True here: a rule that refuses says so.
func allows(_candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	return true
