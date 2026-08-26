class_name EventDef
extends Resource
## Authored data for one kind of event. See docs/EVENTS.md.
##
## Defs are constructed in code by `EventCatalogue` rather than saved as .tres files: they
## are reviewable in a diff, they can be validated on load, and the fairness contract can be
## asserted over the whole catalogue in a test. Nothing here needs an editor to tune.

## How the instance is drawn. Data rather than a script per event, since most events differ
## only in their numbers.
enum Look {
	NONE,     ## Invisible — something else already draws it (a park's playground frame).
	ANIMAL,
	PERSON,
	VEHICLE,
	OBJECT,
}

## Where AMBIENT instances come from. Ambient events are features of the map, not rolls.
enum AmbientSource {
	NONE,
	PLAYGROUND,  ## One per playground.
	MAIN_ROAD,   ## Spread along arterial roads.
}

@export var id := ""
@export var display_name := ""
@export var kind := GameEnums.EventKind.RECURRING
@export var look := Look.OBJECT
@export var ambient_source := AmbientSource.NONE

## Day gating, 1-based and inclusive. `last_day = 0` means it never expires.
@export var first_day := 1
@export var last_day := 0
## For SCRIPTED events: the exact day it fires.
@export var scripted_day := 0

## Relative likelihood when filling the recurring budget, and what one costs of it.
@export var weight := 1.0
@export var cost := 1
@export var max_per_day := 1

## Tile types an instance may be placed on.
@export var placement: Array[int] = []

## Peak excitement per second at the centre.
@export var intensity := 6.0
@export var inner_radius := 40.0
@export var outer_radius := 150.0

## Seconds at full strength. 0 means it lasts the whole day.
@export var duration := 0.0
## Seconds of visible warning before full intensity, during which it emits only
## TELEGRAPH_INTENSITY_FRACTION of `intensity`.
@export var telegraph_time := 2.5
## Seconds per intensity cycle, for events that pulse rather than hold. 0 is constant.
@export var pulse_period := 0.0

## Moves along a path at `speed` px/s. The scheduler builds the path.
@export var mobile := false
@export var speed := 0.0

## Entering the inner radius ends the day immediately.
@export var hard_fail := false

## Narrative act, for palette and audio in M7.
@export var act_tag := 1

func available_on(day: int) -> bool:
	if kind == GameEnums.EventKind.SCRIPTED:
		return scripted_day == day
	if day < first_day:
		return false
	return last_day == 0 or day <= last_day

## Checks the telegraph fairness contract from docs/EVENTS.md.
##
## AMBIENT events are exempt, and have to be: they are permanent features of a fixed map,
## so there is no moment they appear and nothing to warn about. The player learns where the
## playgrounds are on day 1 and that knowledge holds for the rest of the run — which is the
## whole point of a city that does not change.
func validate() -> bool:
	if kind == GameEnums.EventKind.AMBIENT:
		return true
	return Tuning.validate_event(id, telegraph_time, inner_radius, outer_radius, hard_fail)

## Shortest telegraph this geometry may fairly have.
func minimum_telegraph() -> float:
	return Tuning.required_telegraph_time(inner_radius, outer_radius, hard_fail)
