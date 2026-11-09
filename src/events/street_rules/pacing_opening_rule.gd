class_name PacingOpeningRule
extends StreetRule
## **The opening a pacing man's beat leaves is ground in its own right**: the rows reaching one route
## street are asked together whether a walk along it survives, so nothing stands in the one end the
## man shouting is away from (`_leaves_a_pacing_beats_opening()`).

var _map: CityMap
var _corridor: Corridor

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	return _leaves_a_pacing_beats_opening(candidate, _map, _corridor, around)

## **A pacing row leaves the line open for part of its beat.** *"Time pass — don't route around
## them"* (PLAYTEST-71): a man walking two hundred and fifty pixels of footway and back is a timing
## problem rather than a routing one, so the ground he denies is the ground his beat **never** leaves
## free, and a line that is clear at some phase of the loop can simply wait for him.
##
## That reading is what makes the beat's opening worth protecting, and it is the whole of what the
## probe finds broken: not a beat that closes a street by itself — the intersection over a walk is
## far smaller than the disc — but a beat whose one open end has something else standing in it.
## *"No other row's reach covers that open end."*
##
## So on a route street carrying a pacing row, the rows reaching it are asked **together** whether a
## walk from one junction to the other survives. Both directions of the collision are the same
## question and this is asked in both: a pacing row is refused ground where the rows already there
## would close its opening, and a standing row is refused the opening a pacing row already leaves.
##
## **It is scoped to the streets a pacing row actually stands on**, which is what keeps it from
## being a second, wider copy of the width rule. Two standing rows closing a street between them is
## a different shape with a different answer, and the milestone does not write a rule for it.
static func _leaves_a_pacing_beats_opening(candidate: EventScheduler.Planned, map: CityMap, corridor: Corridor,
		already: Array[EventScheduler.Planned]) -> bool:
	if not corridor or not candidate.counts_against_the_line():
		return true
	var reach := candidate.def.line_reach()
	var streets := {}
	var here := map.segment_containing(map.world_to_tile(candidate.position))
	if candidate.def.paces and here and corridor.depth(here.tile_rect().position) == 0:
		streets[here.key()] = here
	for plan in already:
		if plan == candidate or not plan.def.paces or not plan.counts_against_the_line():
			continue
		var theirs := map.segment_containing(map.world_to_tile(plan.position))
		if not theirs or corridor.depth(theirs.tile_rect().position) != 0:
			continue
		if candidate.reach_touches(map.tile_rect_to_world(theirs.tile_rect()), reach):
			streets[theirs.key()] = theirs

	for key: Vector3i in streets:
		var segment: StreetNetwork.Segment = streets[key]
		var rect := map.tile_rect_to_world(segment.tile_rect())
		var standing: Array[EventScheduler.Planned] = [candidate]
		for plan in already:
			if plan == candidate or not plan.counts_against_the_line():
				continue
			if plan.reach_touches(rect, plan.def.line_reach()):
				standing.append(plan)
		if _closes_the_street(map, segment, standing):
			return false
	return true

## Whether these rows between them leave no walk from one end of a street to the other.
##
## Stated over the street's own ground — both pavements, the carriageway between the kerbs left out
## because a line may not cross there anyway (*"in-block crossings are possible in game but
## shouldn't be counted on by the routing algorithm"*) — and over a four-connected walk, so a
## barrier laid diagonally counts as closing a street exactly as a straight band does. This is
## `tests/probes/m129_zero_cost_line.gd`'s own question, asked at placement time instead of after
## the fact, which is what makes the probe's number the measurement of the rule rather than a
## second opinion about it.
static func _closes_the_street(map: CityMap, segment: StreetNetwork.Segment,
		rows: Array[EventScheduler.Planned]) -> bool:
	return RouteSidewalkRule.closes_the_run(map, segment.tile_rect(), segment.horizontal, rows)
