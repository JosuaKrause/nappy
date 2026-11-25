class_name HoldSpec
extends RefCounted
## **Whether a row holds her when she comes to it, and how**, as one value: how many seconds it takes
## her controls, how far past its own solid edge she has to come, and whether it takes her again.
## A row holds one (`EventDef.hold()`); nothing changes it once it exists (a refinement returns a
## new value). `none()` is a row that holds nobody.
##
## **The one mechanic in the catalogue that takes the controls away rather than costing a meter**:
## `chatting_mother`'s conversation and a door's hut or post. Everything else that stops her is a
## choice, which is why `EventDef.validate()` refuses a hold on a row that ends the day or pursues:
## the hold spans parts, so the check stays on the row.

## Seconds her movement input is locked for, on first contact. 0 holds nobody.
var _seconds := 0.0

## How close she has to come **to the row's own solid edge** before a hold starts, in px. Stated
## over the body rather than over her: a radius from the middle has to be bigger than whatever she
## pushes in front of her, so it silently switches the mechanic off the day that changes.
var _past_its_edge := 0.0

## Whether an instance is armed again once she has been released and has moved outside its reach,
## rather than spent for good after its first conversation. A toll she can pass again, with the
## same cost each time, is the one that wants it.
var _again := false

## A row that holds nobody.
static func none() -> HoldSpec:
	return HoldSpec.new()

## A hold of `seconds`, from no distance past the row's edge yet (`from()` sets it).
static func for_seconds(seconds: float) -> HoldSpec:
	assert(seconds > 0.0, "a hold lasts; a row that holds nobody is none()")
	var spec := HoldSpec.new()
	spec._seconds = seconds
	return spec

## The same hold, starting when she is within `past_its_edge` px of the row's solid edge.
func from(past_its_edge: float) -> HoldSpec:
	var spec := _copy()
	spec._past_its_edge = past_its_edge
	return spec

## The same hold, armed again once she has been let out and has walked away.
func again() -> HoldSpec:
	var spec := _copy()
	spec._again = true
	return spec

## Whether it holds her at all.
func detains_her() -> bool:
	return _seconds > 0.0

## How long a hold lasts, in seconds, or 0 for a row that holds nobody.
func detains_for() -> float:
	return _seconds

## How far past the row's solid edge she has to come for a hold to start, in px.
func past_its_edge() -> float:
	return _past_its_edge

## Whether it is armed again once she has been let out and has walked away.
func detains_again() -> bool:
	return _again

func _copy() -> HoldSpec:
	var spec := HoldSpec.new()
	spec._seconds = _seconds
	spec._past_its_edge = _past_its_edge
	spec._again = _again
	return spec
