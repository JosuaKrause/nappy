class_name LethalSpec
extends RefCounted
## **Whether a row's catch ends the day, and the distance it is measured from**, as one value. A row
## holds one (`EventDef.lethal()`); nothing changes it once it exists (a factory makes each, and a
## row's copies share it by reference).
##
## Two kinds:
##
## - **A catch that is nothing** (`none()`): contact costs points and no more; a pursuer whose catch is a
##   stop (`PursuitSpec.stopping_her_for()`) holds it.
## - **A place that ends the day** (`at_its_core()`, `within()`): walking into its reach is the end of
##   her day. `at_its_core()` catches where its field's core ends; `within()` at a reach of its own,
##   which is a man's arms rather than a barrier's core (the roadblock's guard, the masked man).
##
## **One value holds the catch, so a catch reach on a row and another on its pursuit cannot be
## written at once**: the row's `lethal_reach()` is this reach where it sets one, its field's core
## otherwise. A car's strike is its driving's (`EventCarDriving`), never this.

## Whether walking into its reach ends her day.
var _ends_the_day := false

## How close she has to come to be caught, in px, or 0 for the row's field's own core.
var _reach := 0.0

## A catch that is nothing: the row cannot end her day, and its catch is measured from its core.
static func none() -> LethalSpec:
	return LethalSpec.new()

## A place that ends her day at the core of its own field.
static func at_its_core() -> LethalSpec:
	var spec := LethalSpec.new()
	spec._ends_the_day = true
	return spec

## A place that ends her day within `reach`, in px, where that is not its field's own core.
static func within(reach: float) -> LethalSpec:
	assert(reach > 0.0, "a catch that has a reach of its own has a distance")
	var spec := LethalSpec.at_its_core()
	spec._reach = reach
	return spec

## Whether walking into its reach ends her day.
func ends_the_day() -> bool:
	return _ends_the_day

## The distance its catch is measured from, given the `core` of the field it stands in: its own
## reach where it sets one, the core otherwise.
func reach_from(core: float) -> float:
	return _reach if _reach > 0.0 else core
