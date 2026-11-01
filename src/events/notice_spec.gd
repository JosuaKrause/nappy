class_name NoticeSpec
extends Resource
## **How a row that waits for her notices her**: a place until she comes within `within` of it
## along a clear line, then a moment. Its wait emits at full strength, is not lethal and does not
## move; once it notices her, its telegraph, its duration and, for a pursuer, its warning and
## charge are all measured from the notice rather than from the row's birth.
##
## Carried by every row that waits — the alley robber, the alley mouse, the pigeon flock, the
## masked man, the hunting and investigating copies `EventDef.at_heat()` makes, and `charging_dog`
## once it is placed on the map (`EventDef.from_day_after`). A row with no `NoticeSpec` has no wait:
## its clock starts when it exists.
##
## For a pursuer `within` is its **one radius** (inbox #788 in minty-lemur): inside it the pursuer
## warns for its `PursuitSpec.warns_for`, and charges if she is still inside once that has run.

## How close she has to come, in px, before it notices her.
@export var within := 0.0

## Whether the wait and the notice emit `EventInstance.TELEGRAPH_INTENSITY_FRACTION` of the row's
## intensity, as an ordinary telegraph does: birds pecking on a pavement are nearly nothing until
## they go up (`pigeon_flock`). Off for a row whose waiting state is itself the threat.
@export var quiet := false

## **How close she has to come before a row that runs its own line starts its run**, in px, or 0
## for a row whose notice ends on its clock: the masked man on the escape's stairs, who warns while
## she is inside `within` with no clock and runs the moment she comes within this (inbox #788 in
## minty-lemur). One that notices her already inside it warns for `Tuning.WARNING_ALONE_MAX` first.
@export var runs_within := 0.0

## A notice at `radius`, the shape most rows carry.
static func at(radius: float) -> NoticeSpec:
	var spec := NoticeSpec.new()
	spec.within = radius
	return spec
