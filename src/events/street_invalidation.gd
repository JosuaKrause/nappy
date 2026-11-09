class_name StreetInvalidation
extends RefCounted
## **The day's placement rules a walk asks of a candidate** (`StreetRule`, one class per rule): the
## invalidation the design's draw leaves a refused row out by (inbox #1185 in gentle-owl, `docs/EVENTS.md`, "The
## three views and the placement order"), and the judge every other placement asks too, so the rules
## are stated once. A walk composes them from its spec: every walk's route rules (its junctions, its
## walked sidewalk, a beat's opening, and at dawn no body cutting a route off from home), the calm
## she has not used and the doors' clear ground; the escape's on top, one notice at a time
## (`DaySpec.one_notice_at_a_time`) and its walk kept open (`DaySpec.keeps_the_walk_open`).
##
## `room()` answers what a placement weighs a candidate by: `-INF` where a rule refuses it, else the
## room round it among what the walk has placed (`room_around()`, `INF` where it
## clears every spacing). Model: no node.

var _map: CityMap
var _corridor: Corridor
var _rules: Array[StreetRule] = []

## The rules for a walk on `map` routed by `corridor` (null for a walk with no route tree, which
## asks none of the route rules): `ground` the day's ground cache, `leave_alone` the calm ground she
## has not used, `doors` where the region doors' bodies stand, `one_notice` whether the spec keeps
## one waiting guard's notice at a time, `walk` the walk's ground where the spec keeps the walk
## open, else null, and `reach` the dawn's `RouteReachRule`, handed in so the reach it keeps in step
## is worked out once for every judge of the day. A walk's siting hands none: the reach is a dawn
## rule, asked of every body the day plans and not of what the walk sites ahead of her. The walk is
## asked last, since it is the expensive question.
func _init(map: CityMap, corridor: Corridor, ground: Dictionary, leave_alone: Array[Rect2],
		doors: PackedVector2Array, one_notice: bool, walk: WalkGround = null,
		reach: RouteReachRule = null) -> void:
	_map = map
	_corridor = corridor
	_rules.append(UnusedCalmRule.new(leave_alone))
	_rules.append(DoorClearanceRule.new(doors))
	_rules.append(RouteJunctionsRule.new(map, corridor, ground))
	_rules.append(RouteSidewalkRule.new(map, corridor))
	_rules.append(PacingOpeningRule.new(map, corridor))
	if reach:
		_rules.append(reach)
	if one_notice:
		_rules.append(OneNoticeRule.new(map))
	if walk:
		_rules.append(WalkOpenRule.new(walk))

## **The candidate's room, or `-INF` where a rule refuses it**, having given it its role: `role`,
## or a wall's where a pacing beat walls its sidewalk. What makes a man walking a beat passable is
## where the beat runs, not what he emits: one whose beat reaches no junction and no side route
## cannot be left once she is on his sidewalk, so he is a wall and takes a wall's one rule with him,
## never on ground a route runs along (`_a_pacing_beat_walls_a_sidewalk()`). `placed`
## is what the walk has placed, `around` that with what stands for the day besides.
func room(candidate: EventScheduler.Planned, role: GameEnums.BlockerRole, tile: Vector2i,
		placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> float:
	candidate.give_role(role)
	if _a_pacing_beat_walls_a_sidewalk(candidate, _map):
		candidate.give_role(GameEnums.BlockerRole.WALL)
		if _corridor and _corridor.carries_a_route(tile):
			return -INF
	for rule in _rules:
		if not rule.allows(candidate, tile, placed, around):
			return -INF
	return room_around(candidate, placed)

## **Whether *this* pacing placement is a wall**: its field leaves no line along a sidewalk, and its
## beat reaches nowhere she can leave that sidewalk.
##
## The arithmetic of the first half is the plain clause above — a beat runs *along* a sidewalk and
## moves the row nowhere across it, so the width of the line past a yeller is the same at every
## phase of his loop and waiting does not widen a sidewalk. What the second half adds is the way out
## that is not a wider sidewalk: **somewhere his beat passes that she can leave by**, of which there
## are two kinds and the player named both. *"If they stay on the segment for the whole time with no
## side route then there is no way to avoid them."*
##
## - **A crossing.** A beat that reaches a junction box is one she can step off at the zebra there
##   while he is at the other end of it. **A junction box is where every crosswalk in the city is**,
##   so *his beat crosses a crosswalk* and *his beat reaches a junction* are one question —
##   `StreetLayout._street_tile` paints `CROSSING` only where both corridor offsets are inside a
##   street and exactly one of them is a carriageway offset, which is a junction box by definition.
##   It is also the crossing this whole milestone counts on: a mid-block crossing exists in play and
##   is not planned around.
## - **A side route**, which is the other half and asks nothing of the carriageway: ground off the
##   street opening off the sidewalk on its **own** side — an alley mouth, a park or square edge, a
##   courtyard or a precinct opening. She leaves by it without crossing anything.
##
## A beat with neither leaves her the choice of walking through him or turning round, and that
## placement is the wall.
static func _a_pacing_beat_walls_a_sidewalk(plan: EventScheduler.Planned, map: CityMap) -> bool:
	if not plan.row().paces or not EventScheduler.leaves_no_line_along_a_sidewalk(plan.row()):
		return false
	return not _a_beat_reaches_a_way_out(plan, map)

## Whether a beat's own run passes a junction box or a side route. Two waypoints and a straight run
## between them (`EventScheduler._along_street_path`), so the tiles are a step along one axis; a row with no beat
## laid at all answers no, which is the conservative side of a rule that only ever refuses ground.
static func _a_beat_reaches_a_way_out(plan: EventScheduler.Planned, map: CityMap) -> bool:
	if plan.walks().size() < 2:
		return false
	var from := map.world_to_tile(plan.walks()[0])
	var to := map.world_to_tile(plan.walks()[plan.walks().size() - 1])
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	# **Bounded by the run's own length rather than by reaching its end**: a run along one axis
	# reaches `to` in exactly this many steps, and one that did not lie along an axis would step
	# past `to` without ever landing on it.
	var at := from
	for _step in maxi(absi(to.x - from.x), absi(to.y - from.y)) + 1:
		if CityMap.junction_at(at) != Vector2i(-1, -1) or _a_side_route_opens_off(map, at):
			return true
		at += step
	return false

## Whether ground off the street opens off this sidewalk tile, on the sidewalk's own side.
##
## **It is a question about tiles and costs a handful of them**, which is the whole reason it is
## stated this way: a flood fill per candidate would answer *does this lead anywhere* exactly and
## would run inside the placement loop, hundreds of times a day. The tile reading that is honest
## without it is **depth**: step across the sidewalk band to its frontage edge — `pavement_inward`
## is which way that is, and it answers zero inside a junction box, which the caller has already
## covered — and ask whether the first two tiles past the band are walkable ground that is not
## street. Two rather than one, because one tile of walkable ground against a frontage is a doorway
## notch rather than a way out, and everything that really leads somewhere — an alley, a park, a
## square, a courtyard — is a lot's worth of ground deep.
static func _a_side_route_opens_off(map: CityMap, tile: Vector2i) -> bool:
	var inward := map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return false
	var at := tile
	for _across in Tuning.SIDEWALK_WIDTH:
		at += inward
		if map.tile_at(at) != GameEnums.TileType.SIDEWALK:
			break
	return _is_ground_off_the_street(map, at) and _is_ground_off_the_street(map, at + inward)

## Walkable today and not part of a street: a park, a square, an alley, a courtyard, a precinct's
## own ground. A carriageway is walkable and is not a way off a street, which is why this asks
## `is_street` rather than only `is_open`.
static func _is_ground_off_the_street(map: CityMap, tile: Vector2i) -> bool:
	return map.is_open(tile) and not map.is_street(tile)

## How much room a candidate has. `INF` means it satisfies every rule and can be taken at once;
## `-INF` means it is illegal at any price; anything between is how far it got towards
## `EventScheduler.EVENT_SPACING_SAME`, which is the only rule that bends.
##
## "Room" is measured against the whole of an event rather than the tile it starts on: a dog
## walker's route is thirty tiles long, and a start point with room around it can still walk the
## length of somebody else's field.
##
## **Two of the rules are absolute and one is a preference**, and the split is what each one is
## protecting:
##
## - `EventScheduler.EVENT_SPACING_ANY` — nothing is ever drawn inside anything else. Two tiles, thousands of
##   candidates, so refusing costs a re-roll and nothing else.
## - **Nothing else happens inside a lethal event's field.** `Tuning.validate_event()` states the
##   telegraph contract *per event* and the player experiences the sum, so at one event per block
##   "walk out of this radius" can quietly mean "walk into the next one". For a row that only costs
##   points that is what the density is *for*; for one that ends the day it is a death arriving out
##   of a field she was already reading. A `hard_fail` event that cannot find room is not placed.
## - `EventScheduler.EVENT_SPACING_SAME` — a second dog walker a few pixels from the first reads as a
##   duplicated sprite rather than a second incident. This one bends, because on a full map the
##   honest answer is the roomiest spot left rather than no event.
static func room_around(candidate: EventScheduler.Planned, already: Array[EventScheduler.Planned]) -> float:
	var room_same := INF
	for plan in already:
		if not plan.is_placed():
			continue
		var gap := candidate.gap_to(plan)
		if gap < EventScheduler.EVENT_SPACING_ANY:
			return -INF
		if plan.keeps_its_field_clear() and gap < plan.row().field_reach():
			return -INF
		if plan.row().id == candidate.row().id:
			room_same = minf(room_same, gap)
		if candidate.keeps_its_field_clear() and gap < candidate.row().field_reach():
			return -INF
	return INF if room_same >= EventScheduler.EVENT_SPACING_SAME else room_same
