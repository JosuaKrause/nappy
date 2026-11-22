class_name FlockSpec
extends Resource
## **How many creatures a row is and how far they spread**, as one value: a row that is several
## bodies rather than one thing drawn several times. A row holds one (`EventDef.flock()`); nothing
## changes it once it exists (a refinement returns a new value). `none()` is a row that is one body.
##
## **A flock is not one sprite drawn seven times at fixed offsets**: offsets derived from the
## instance's position are right for a *static* picture and wrong for a moving one, where the birds
## could only move together. With a flock, `EventInstance` gives every bird its own position,
## heading, speed, height and wingbeat, and steps them one at a time (`EventFlock`).

## How many individual creatures it is. 0 for everything that is one body.
var _count := 0

## How far from the middle a flock spreads, in px. The row's `heard_within()` is the field it emits
## over; this is the ground it stands on and the air it wheels in, much smaller, so a flock she can
## see the shape of is a flock she can walk round.
var _spread := 0.0

## A row that is one body.
static func none() -> FlockSpec:
	return FlockSpec.new()

## `count` creatures wheeling inside `spread` px of the row's middle.
static func of(count: int, spread: float) -> FlockSpec:
	assert(count > 0 and spread > 0.0, "a flock is bodies and a spread; one body is none()")
	var spec := FlockSpec.new()
	spec._count = count
	spec._spread = spread
	return spec

## Whether it is a flock of bodies wheeling over one place.
func is_a_flock() -> bool:
	return _count > 0

## How many creatures it is, or 0 for a row that is one body.
func count() -> int:
	return _count

## How far from the middle the creatures spread, in px.
func spread() -> float:
	return _spread
