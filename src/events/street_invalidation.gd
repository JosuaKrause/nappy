class_name StreetInvalidation
extends RefCounted
## **The day's placement rules a walk asks of a candidate** (`StreetRule`, one class per rule): the
## invalidation the design's draw leaves a refused row out by (inbox #1185, `docs/EVENTS.md`, "The
## three views and the placement order"), and the judge every other placement asks too, so the rules
## are stated once. A walk composes them from its spec: every walk's route rules (its junctions, its
## walked sidewalk, a beat's opening, and no body cutting a route off from home), the calm she has
## not used and the doors' clear ground; the escape's on top, one notice at a time
## (`DaySpec.one_notice_at_a_time`) and its walk kept open (`DaySpec.keeps_the_walk_open`).
##
## `room()` answers what a placement weighs a candidate by: `-INF` where a rule refuses it, else the
## room round it among what the walk has placed (`EventScheduler._room_around()`, `INF` where it
## clears every spacing). Model: no node.

var _map: CityMap
var _corridor: Corridor
var _rules: Array[StreetRule] = []

## The rules for a walk on `map` routed by `corridor` (null for a walk with no route tree, which
## asks none of the route rules): `ground` the day's ground cache, `leave_alone` the calm ground she
## has not used, `doors` where the region doors' bodies stand, `one_notice` whether the spec keeps
## one waiting guard's notice at a time, and `walk` the walk's ground where the spec keeps the walk
## open, else null. The walk is asked last, since it is the expensive question.
func _init(map: CityMap, corridor: Corridor, ground: Dictionary, leave_alone: Array[Rect2],
		doors: PackedVector2Array, one_notice: bool, walk: WalkGround = null) -> void:
	_map = map
	_corridor = corridor
	_rules.append(UnusedCalmRule.new(leave_alone))
	_rules.append(DoorClearanceRule.new(doors))
	_rules.append(RouteJunctionsRule.new(map, corridor, ground))
	_rules.append(RouteSidewalkRule.new(map, corridor))
	_rules.append(PacingOpeningRule.new(map, corridor))
	_rules.append(RouteReachRule.new(map, corridor))
	if one_notice:
		_rules.append(OneNoticeRule.new(map))
	if walk:
		_rules.append(WalkOpenRule.new(walk))

## **The candidate's room, or `-INF` where a rule refuses it**, having given it its role: `role`,
## or a wall's where a pacing beat walls its sidewalk. What makes a man walking a beat passable is
## where the beat runs, not what he emits: one whose beat reaches no junction and no side route
## cannot be left once she is on his sidewalk, so he is a wall and takes a wall's one rule with him,
## never on ground a route runs along (`EventScheduler._a_pacing_beat_walls_a_sidewalk()`). `placed`
## is what the walk has placed, `around` that with what stands for the day besides.
func room(candidate: EventScheduler.Planned, role: GameEnums.BlockerRole, tile: Vector2i,
		placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> float:
	candidate.role = role
	if EventScheduler._a_pacing_beat_walls_a_sidewalk(candidate, _map):
		candidate.role = GameEnums.BlockerRole.WALL
		if _corridor and _corridor.carries_a_route(tile):
			return -INF
	for rule in _rules:
		if not rule.allows(candidate, tile, placed, around):
			return -INF
	return EventScheduler._room_around(candidate, placed)
