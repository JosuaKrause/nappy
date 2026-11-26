class_name JunctionBoxes
extends RefCounted
## **Where the junction boxes lie along a street**, in world px. The lattice puts a street corridor
## every `CityMap.period()` tiles, `Tuning.STREET_WIDTH` tiles wide, so along any street box
## `index` runs from `low(index)` to `high(index)`, and a coordinate inside it is in it
## (`holding()`, the corridor `CrowdLanes.corridor_at()` reads off the same lattice). It is the one
## place that arithmetic is written for a car sent from box to box: the convoy the director sites
## (`EventDirector`) and the way a sent car goes on (`WayOn`) both ask it.
##
## Pure arithmetic over the lattice's constants, like `CityMap.period()`: it holds no state, so
## nothing is handed to it and a test asks it as the game does.

## Where box `index` starts along a street, in px.
static func _low(index: int) -> float:
	return float(index * CityMap.period() * Tuning.TILE_SIZE)

## Where box `index` ends along a street, in px: the first coordinate past it.
static func _high(index: int) -> float:
	return _low(index) + float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)

## The middle of box `index` along a street, in px.
static func centre(index: int) -> float:
	return (_low(index) + _high(index)) * 0.5

## The box `along` (a coordinate along a street) lies in, or -1 between two boxes.
static func holding(along: float) -> int:
	return CrowdLanes.corridor_at(along)

## The box `along` lies in, or the first one past it driving or walking toward the high end where
## `forward` and toward the low end where not.
static func ahead(along: float, forward: bool) -> int:
	var inside := holding(along)
	if inside >= 0:
		return inside
	return _below(along) + (1 if forward else 0)

## The first box wholly past `along` that way: the next one after the box it lies in, or
## `ahead()` between two boxes.
static func past(along: float, forward: bool) -> int:
	var inside := holding(along)
	if inside >= 0:
		return inside + (1 if forward else -1)
	return ahead(along, forward)

## The box `along` lies in, or the last one it has left that way: the box a car driving there
## leaves straight out of, or last left.
static func behind(along: float, forward: bool) -> int:
	var inside := holding(along)
	if inside >= 0:
		return inside
	return _below(along) + (0 if forward else 1)

## Where a car driving toward the high end where `forward` comes into box `index`.
static func entry(index: int, forward: bool) -> float:
	return _low(index) if forward else _high(index)

## Where it leaves box `index`.
static func exit(index: int, forward: bool) -> float:
	return _high(index) if forward else _low(index)

## A pixel short of where it comes into box `index`: the last coordinate before it, from which
## the box it comes to (`ahead()`, `behind()` and on) is `index` itself.
static func short_of(index: int, forward: bool) -> float:
	return entry(index, forward) + (-1.0 if forward else 1.0)

## The box at or below `along` (the one it lies in, or the last one toward the low end).
static func _below(along: float) -> int:
	return floori(along / float(CityMap.period() * Tuning.TILE_SIZE))
