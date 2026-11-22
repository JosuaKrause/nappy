class_name AbductionSpec
extends RefCounted
## **The unmarked van takes somebody first** (`EventDef.takes_a_victim_by()`, `EventAbduction`):
## the first time she comes close enough to see it, a bystander is walked to the van and taken.
## Drawing and telemetry only — nothing here reaches into the crowd, and nothing here changes
## the van's field. The hunting copies carry the same take (`EventDef.at_heat()` keeps it),
## which stops the moment the van notices her.
##
## A value: built once by `standard()`, never changed, shared by a row and its copies.

## How long the walk to the van takes once it starts, in seconds.
var _taken_over := 2.5
## How far to the side of the van the bystander stands before the walk begins, in px.
var _standing_offset := 32.0

## The take the unmarked van carries: a two-and-a-half-second walk from 32px to the van's side.
static func standard() -> AbductionSpec:
	return AbductionSpec.new()

## How long the walk to the van takes once it starts, in seconds.
func taken_over() -> float:
	return _taken_over

## How far to the side of the van the bystander stands before the walk begins, in px.
func standing_offset() -> float:
	return _standing_offset
