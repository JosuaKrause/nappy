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
##
## `PARK` is the one kind that closes no street: it is the fence of a calm area she has already
## used, shut today (`ParkClosure`). Like `CORDON` it leaves nothing lying anywhere, so the barriers
## are the whole of it, and it is never rolled for a street (`kinds_on()`).
enum Kind { ROADWORKS, FALLEN_TREE, CRASH, CORDON, RUBBLE, PARK }

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
	Kind.PARK: {"name": "Park closed", "first_day": 1, "weight": 0.0},
}

var _kind := Kind.ROADWORKS
## The street closed. Every reader under `src/` outside this file asks the methods below but one,
## the day's holds (`DayPlanner`), which hold its key and wait for the events' interface to ask
## `street_key()`; the suites' and the probes' reads of it go with that read.
var segment: StreetNetwork.Segment

func _init(closure_kind: Kind, closed_street: StreetNetwork.Segment) -> void:
	_kind = closure_kind
	segment = closed_street

## What closed the street: what its barriers carry and what lies in the road (`ClosureMarker`), and
## the name the run log gives it (`display_name()`).
func kind() -> Kind:
	return _kind

static func display_name(closure_kind: Kind) -> String:
	return String(KINDS[closure_kind]["name"])

## The kinds that can close a **street** on a given day. `Array[int]` rather than `Array[Kind]`
## because an enum is not a legal array element type — the values are `Kind` all the same. `PARK`
## is never one: it is what a shut calm area's fence is, and nothing rolls it.
static func kinds_on(day: int) -> Array[int]:
	var found: Array[int] = []
	for closure_kind: int in KINDS:
		if closure_kind == Kind.PARK:
			continue
		if day >= int(KINDS[closure_kind]["first_day"]):
			found.append(closure_kind)
	return found

## What this closure is and where, in the run log's words: its kind, which way the street runs and
## the tile it starts at, such as `roadworks v(8,6)`.
func summary_words() -> String:
	return "%s %s" % [RoadClosure.display_name(_kind).to_lower(), street_words()]

## Where this closure is, in the run log's words: which way its street runs and the tile it starts
## at, such as `v(8,6)`.
func street_words() -> String:
	return "%s%s" % ["h" if segment.horizontal else "v", RunTrace.tile(segment.a)]

## The lattice key of the street this closure closes (`StreetNetwork.Segment.key()`), which tells it
## apart from the day's other closures. A park's fence answers a key no street has
## (`ParkClosure.Edge.key()`).
func street_key() -> Vector3i:
	return segment.key()

# ------------------------------------------------------------------ geometry ---

## Every tile of the street this closure's segment covers — the geometry, not the verdict.
##
## **This is not the same set as what ends up in `CityMap.closed_tiles`.** The barriers stand at
## the two mouths, and ground between them that opens onto an alley or a courtyard archway mid-
## segment is still somewhere a pedestrian can get to from that side, whatever the two ends of the
## street say. Which of these tiles are genuinely unreachable is a question about the whole day's
## walkable ground, not about one closure in isolation, so `CityMap.close_streets` is what answers
## it — with `ReachabilityGrid`, once, for every closure of the day together.
func tiles(map: CityMap) -> Array[Vector2i]:
	return map.rect_tiles(segment.tile_rect())

## Whether `tile` lies on the ground this closure's segment covers: a street's tiles, or a park
## fence's strip of edge (`ParkClosure.Edge`). The geometry, not the verdict, as `tiles()`.
func covers_tile(tile: Vector2i) -> bool:
	return segment.tile_rect().has_point(tile)

## Whether the whole street this closure's segment covers lies inside `window` (a tile rectangle).
func fits_within(window: Rect2i) -> bool:
	return window.encloses(segment.tile_rect())

## The two mouths the barriers stand across, the `a` end first, each a tile rectangle one tile thick
## across the street (`StreetNetwork.Segment.mouth_rect()`). A `ParkClosure`'s are its run's strip,
## twice.
func mouth_rects() -> Array[Rect2i]:
	var found: Array[Rect2i] = []
	for at_a: bool in [true, false]:
		found.append(segment.mouth_rect(at_a))
	return found

## Where the two barriers stand: the middle of each mouth, on the ground plane.
func mouth_centres(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for mouth in mouth_rects():
		found.append(map.tile_rect_to_world(mouth).get_center())
	return found

## The middle of the closed street, where whatever caused it is lying.
func cause_centre(map: CityMap) -> Vector2:
	return map.tile_rect_to_world(segment.tile_rect()).get_center()

## True when the barrier line runs left-to-right across the screen, which it does for a
## north-south street. It decides which of the two fence sprites is used.
func barrier_runs_across() -> bool:
	return not segment.horizontal

## How wide a line of barrier is, in pixels — a street's own width, since its mouth is exactly
## that wide by construction. `City._spawn_barrier()` reads this rather than `Tuning.STREET_WIDTH`
## directly, so a closure whose line is not a street's width (`ParkClosure`, one line the length of
## a whole edge) can say so without this class knowing anything drew it that way.
func barrier_width() -> float:
	return Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)

## How far up the screen an end-on line's panels are drawn above the ground they cover. None for a
## street, whose line meets no other. The park's renderer positions its two rails separately
## at their authored elevations rather than shifting this street panel.
func end_on_rise() -> float:
	return 0.0

## Where a post stands on its own, at the end of a line of barrier or at the corner two lines turn
## on (`ClosureMarker.Piece.POST`). None for a street: its line runs wall to wall across the mouth,
## so it has no end in the open to finish. `ParkClosure` answers the corners and ends of its runs.
func posts(_map: CityMap) -> Array[Vector2]:
	var none: Array[Vector2] = []
	return none
