class_name NoticeSpec
extends RefCounted
## **How a row that waits for her notices her**: a place until she comes within `within` of it
## along a clear line, then a moment. Its wait emits at full strength, is not lethal and does not
## move; once it notices her, its telegraph, its duration and, for a pursuer, its warning and
## charge are all measured from the notice rather than from the row's birth.
##
## Carried by every row that waits — the alley robber, the alley mouse, the pigeon flock, the
## hunting and investigating copies `EventDef.at_heat()` makes, and `charging_dog`
## once it is placed on the map (`EventDef.spawn_mode_on()`). A row with no `NoticeSpec` has no
## wait: its clock starts when it exists.
##
## For a pursuer `within` is its **one radius** (inbox #788 in minty-lemur): inside it the pursuer
## warns for its `PursuitSpec.warns_for()`, and charges if she is still inside once that has run.

## How close she has to come, in px, before it notices her.
var _within := 0.0

## Whether the wait and the notice emit `EventInstance.TELEGRAPH_INTENSITY_FRACTION` of the row's
## intensity, as an ordinary telegraph does: birds pecking on a pavement are nearly nothing until
## they go up (`pigeon_flock`). Off for a row whose waiting state is itself the threat.
var _quiet := false

## A notice at `radius`, the shape most rows carry.
static func at(radius: float) -> NoticeSpec:
	var spec := NoticeSpec.new()
	spec._within = radius
	return spec

## The same notice whose wait and notice emit only a telegraph's share of the row's intensity.
func quietly() -> NoticeSpec:
	var spec := _copy()
	spec._quiet = true
	return spec

## How close she has to come, in px, before it notices her.
func within() -> float:
	return _within

## Whether its wait and its notice emit only a telegraph's share of the row's intensity.
func is_quiet() -> bool:
	return _quiet

func _copy() -> NoticeSpec:
	var spec := NoticeSpec.new()
	spec._within = _within
	spec._quiet = _quiet
	return spec
