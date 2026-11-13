class_name RouteJunctionsRule
extends StreetRule
## **A route's junction box keeps a walk between the route streets meeting there**, against the line
## reach of every row that counts against it (`_leaves_the_route_junctions_open()`).
## It reads what stands round the box, seals and the region wall included, so what another street
## holds within its reach invalidates here too (fork 3 of the placement proposal, the orchestrator's
## reading: today's rules reach across a junction).

var _map: CityMap
var _corridor: Corridor
## The routes' junctions with the geometry the rule asks about (`_route_junctions()`), worked out
## when the rule is first asked and kept for its life.
var _junctions: Array = []
var _junctions_are_known := false

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], around: Array[EventPlan]) -> bool:
	return _leaves_the_route_junctions_open(candidate, around)

## **A route's junctions stay clear**, checked before a row is accepted and never repaired after.
##
## A junction is the only place a line may change pavement, so a crossing the day's rows have
## closed between them is a cut nothing on either side can answer — the shape
## `tests/probes/m129_zero_cost_line.gd` measured breaking more routes than every other shape put
## together. The refusal is *this ground*, not *this row*: the placement asks
## the row's next tile or location, and the row lands somewhere it leaves the crossing open.
##
## **It is stated over the candidate together with what is already down**, which is what makes it
## the rule the measurement asked for rather than a weaker one: the crossing the probe names most
## often is covered by a pair (`cafe_tables` and `homeless_yeller` at one junction), and a rule that
## only ever asked *does this row alone take the box* would accept both of them. Stating it
## cumulatively is still *checked before accepted*: each row in turn is asked whether the day it is
## joining still has a line through every crossing, so a closed one never exists even briefly.
func _leaves_the_route_junctions_open(candidate: EventPlan, already: Array[EventPlan]) -> bool:
	if not _corridor or not candidate.counts_against_the_line():
		return true
	var reach := candidate.row().line_reach()
	for entry: Array in _route_junctions():
		var centre: Vector2 = entry[1]
		var box_reach: float = entry[2]
		if candidate.distance_from(centre) > reach + box_reach:
			continue
		if not _a_crossing_stays_open(_map, _corridor, entry, candidate, already):
			return false
	return true

## The routes' junctions with the geometry the rule asks about, worked out once a rule: each entry
## is `[junction, the box's world centre, the box's own reach from that centre]`. They are the
## rule's own facts about the routes, a few dozen boxes, so the rule keeps them itself.
func _route_junctions() -> Array:
	if not _junctions_are_known:
		for junction in _corridor.route_junctions():
			var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
			var world := _map.tile_rect_to_world(box)
			_junctions.append([junction, world.get_center(), world.size.length() * 0.5])
		_junctions_are_known = true
	return _junctions

## Whether one junction box still carries a walk between every route street that meets it, with the
## candidate standing and everything already down standing too.
##
## **The arms are the on-corridor streets and nothing else.** A junction where three route streets
## meet has to connect all three, because a line may arrive down any of them; a turning off the
## corridor is not ground the guarantee is about. Where the tree crosses a junction without using a
## street at either side — a park cut, an alley mouth — there are no arms and the box only has to
## have somewhere free left in it.
static func _a_crossing_stays_open(map: CityMap, corridor: Corridor, entry: Array,
		candidate: EventPlan, already: Array[EventPlan]) -> bool:
	var junction: Vector2i = entry[0]
	var centre: Vector2 = entry[1]
	var box_reach: float = entry[2]
	var standing: Array[EventPlan] = [candidate]
	for plan in already:
		if plan == candidate or not plan.counts_against_the_line():
			continue
		if plan.distance_from(centre) <= plan.row().line_reach() + box_reach:
			standing.append(plan)

	var origin := junction * CityMap.period()
	var free := {}
	for y in Tuning.STREET_WIDTH:
		for x in Tuning.STREET_WIDTH:
			var tile := origin + Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for plan in standing:
				if plan.denies(at, plan.row().line_reach()):
					taken = true
					break
			if not taken:
				free[tile] = true
	if free.is_empty():
		return false

	var arms: Array = []
	for segment in map.street_network().at_junction(junction):
		if corridor.depth(segment.tile_rect().position) != 0:
			continue
		var open_here: Array[Vector2i] = []
		for tile in _arm_tiles(origin, junction, segment):
			if free.has(tile):
				open_here.append(tile)
		if open_here.is_empty():
			return false
		arms.append(open_here)
	if arms.size() < 2:
		return true

	var reached := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in arms[0]:
		reached[tile] = true
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in StreetRule.NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	for i in range(1, arms.size()):
		var joined := false
		for tile: Vector2i in arms[i]:
			if reached.has(tile):
				joined = true
				break
		if not joined:
			return false
	return true

## The one-tile strip of a junction box that a street opens onto — where a line enters the box from
## that street and where it leaves it for that street.
static func _arm_tiles(origin: Vector2i, junction: Vector2i,
		segment: StreetNetwork.Segment) -> Array[Vector2i]:
	var step := segment.other_end(junction) - junction
	var found: Array[Vector2i] = []
	for i in Tuning.STREET_WIDTH:
		if step.x > 0:
			found.append(origin + Vector2i(Tuning.STREET_WIDTH - 1, i))
		elif step.x < 0:
			found.append(origin + Vector2i(0, i))
		elif step.y > 0:
			found.append(origin + Vector2i(i, Tuning.STREET_WIDTH - 1))
		else:
			found.append(origin + Vector2i(i, 0))
	return found
