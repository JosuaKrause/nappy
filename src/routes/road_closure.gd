class_name RoadClosure
extends RefCounted
## One street closed for one day, and what closed it.
##
## A closure is the only thing in the game that changes *where the player may walk* from one
## morning to the next. Block purposes may change what a place is worth walking to and never
## move a walkable tile (docs/CITY.md); a closure is the deliberate exception, and it is kept
## deliberate by being per-day, sealed at both ends, and validated against the route
## invariant before it is accepted.
##
## **A closure is silent.** It changes the shape of the route and contributes nothing to the
## excitement meter — the noise of a street is the crowd on it, and the danger of a street is
## the events on it. A roadworks that emits is already in the catalogue (`construction`);
## this is the structural half, and keeping the two apart is what stops `City` from growing a
## third thing to sum.

## What has closed the street. The kinds differ in what they look like and when they start
## happening; none of them differ mechanically, because a street you cannot walk down is a
## street you cannot walk down.
enum Kind { ROADWORKS, FALLEN_TREE, CRASH, CORDON, RUBBLE }

## Name, the first day it can happen, and how likely it is against the others available.
##
## The escalation is the point of the table: act I closes streets by accident, act II closes
## them by order, and act IV closes them by bringing the building down.
const KINDS := {
	Kind.ROADWORKS: {"name": "Roadworks", "first_day": 1, "weight": 1.0},
	Kind.FALLEN_TREE: {"name": "Fallen tree", "first_day": 1, "weight": 0.6},
	Kind.CRASH: {"name": "Accident", "first_day": 1, "weight": 0.8},
	Kind.CORDON: {"name": "Cordoned off", "first_day": 4, "weight": 1.4},
	Kind.RUBBLE: {"name": "Collapsed", "first_day": 12, "weight": 1.6},
}

var kind := Kind.ROADWORKS
var segment: StreetNetwork.Segment

func _init(closure_kind: Kind, closed_street: StreetNetwork.Segment) -> void:
	kind = closure_kind
	segment = closed_street

static func display_name(closure_kind: Kind) -> String:
	return String(KINDS[closure_kind]["name"])

## The kinds that can happen on a given day. `Array[int]` rather than `Array[Kind]` because
## an enum is not a legal array element type — the values are `Kind` all the same.
static func kinds_on(day: int) -> Array[int]:
	var found: Array[int] = []
	for closure_kind: int in KINDS:
		if day >= int(KINDS[closure_kind]["first_day"]):
			found.append(closure_kind)
	return found

# ------------------------------------------------------------------ geometry ---

## Every tile the closure takes out of the network — the whole street, not just the two
## ends. The barriers only stand at the mouths, but the ground between them is not somewhere
## anyone can get to, so nothing should be placed there and nobody should be routed through
## it.
func tiles(map: CityMap) -> Array[Vector2i]:
	return map.rect_tiles(segment.tile_rect())

## Where the two barriers stand: the middle of each mouth, on the ground plane.
func mouth_centres(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for at_a in [true, false]:
		found.append(map.tile_rect_to_world(segment.mouth_rect(at_a)).get_center())
	return found

## The middle of the closed street, where whatever caused it is lying.
func cause_centre(map: CityMap) -> Vector2:
	return map.tile_rect_to_world(segment.tile_rect()).get_center()

## True when the barrier line runs left-to-right across the screen, which it does for a
## north-south street. It decides which of the two fence sprites is used.
func barrier_runs_across() -> bool:
	return not segment.horizontal
