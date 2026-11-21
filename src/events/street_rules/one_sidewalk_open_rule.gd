class_name OneSidewalkOpenRule
extends StreetRule
## **No street of her routes has both its sidewalks closed by bodies a draw put on them**: a
## candidate that blocks the way (`EventPlan.obstructs()`, at `_closing_radius()`) is
## refused where, for a street of her routes its body reaches, neither sidewalk can be walked
## junction to junction with it standing (`RouteSidewalkRule.closes_a_walked_sidewalk_band()`,
## asked of both of the street's bands against the bodies standing round it), and one could
## without it.
##
## **Only her routes' own streets** (`Corridor.view_of()` on the route). *(Inbox #1465 in
## spry-plover, the player's answer on the board: "what I said was *if* a street needs to have one
## sidewalk walkable *then* the placement of the drawn events needs to make sure of that".)* No
## street is newly required to keep a sidewalk; a route's street already is, and the draw makes
## sure of it. The streets beside the routes and off them keep their blocking events all over (PLAYTEST-17:
## "areas that outside the paths should have blocking events all over"), and the escape's walk
## keeps its own rule.
##
## **Why the line rules do not already hold it there**: they ask only a row that counts against
## the line (`EventPlan.counts_against_the_line()`), and a pursuer (the alley robbery, the charging
## dog) does not, since it follows her rather than holding a tile, yet it stands as a body. So a
## pursuer on one sidewalk and a roadblock, or another pursuer, on the other close the street with
## every line rule satisfied, and this rule is the one that sees the pair.
##
## - **Both ways round**: the street's own second body is refused, and so is a neighbour's body
##   reaching into the street's last open sidewalk, whichever draws first. A street draws all its
##   locations at once and its touching units draw before it or after it with what it drew in view,
##   so a street drawing after its neighbours keeps one sidewalk open, given what they drew.
## - **A street already closed is left alone**: one a seal, a closure or the region wall closes
##   has no open sidewalk to keep, and nothing is refused there.
## - **A roadblock is asked too** (*inbox #747 in woolly-penguin: "roadblocks currently are
##   impossible to get past. one sidewalk must be open if they're en-route."*). It spans the street
##   by design (`EventDef.spans_the_street()`), and its band, at every heat (`_closing_radius()`),
##   stands on the kerb beside its lane (`EventPlan.body_at()`) and takes the sidewalk on its own
##   side of the road and the road, leaving the far sidewalk whole, so it is refused where a body
##   already closes that far sidewalk, and a body drawn after it is refused across from it the same
##   way.
##
## It asks a body, never a cost: a row whose field alone covers both sidewalks is the line rules'
## question. Model: no node.

var _map: CityMap
var _corridor: Corridor

## The rule on `map` for the routes `corridor` runs (null for a walk with no route tree: no street
## is on a route then).
func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], around: Array[EventPlan]) -> bool:
	if not candidate.obstructs():
		return true
	for street in _streets_reached_by(candidate):
		if _is_on_her_routes(street) and _closes_its_last_sidewalk(street, candidate, around):
			return false
	return true

## The streets a body's disc reaches a tile of, with her own radius on it: a body stops her
## `_closing_radius() + PLAYER_BODY_RADIUS` from where it stands. The streets this city has only.
func _streets_reached_by(plan: EventPlan) -> Array[StreetNetwork.Segment]:
	var reach := _closing_radius(plan) + Tuning.PLAYER_BODY_RADIUS
	var at := plan.body_at()
	var from := _map.world_to_tile(at - Vector2.ONE * reach)
	var to := _map.world_to_tile(at + Vector2.ONE * reach)
	var found: Array[StreetNetwork.Segment] = []
	var seen := {}
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			var street := _map.street_network().segment_containing(Vector2i(x, y))
			if street == null or seen.has(street.key()) or not _map.has_street(street.key()):
				continue
			seen[street.key()] = true
			found.append(street)
	return found

## Whether a route of the day runs along `street`.
func _is_on_her_routes(street: StreetNetwork.Segment) -> bool:
	return _corridor != null \
			and _corridor.view_of(street) == PlacementView.View.ON_THE_ROUTE

## Whether `candidate` closes the last sidewalk of `street` that the bodies of `around` leave
## walkable from one junction to the other.
func _closes_its_last_sidewalk(street: StreetNetwork.Segment, candidate: EventPlan,
		around: Array[EventPlan]) -> bool:
	var rect := street.tile_rect()
	var world := _map.tile_rect_to_world(rect)
	var bodies: Array = []
	for plan in around:
		if plan == candidate or not plan.obstructs():
			continue
		var radius := _closing_radius(plan)
		var at := plan.body_at()
		if world.grow(radius + Tuning.PLAYER_BODY_RADIUS).has_point(at):
			bodies.append(Vector3(at.x, at.y, radius))
	var bands := Corridor.sidewalk_bands(rect, street.horizontal)
	if not _one_is_open(bands, street.horizontal, bodies):
		return false
	var stands := candidate.body_at()
	bodies.append(Vector3(stands.x, stands.y, _closing_radius(candidate)))
	return not _one_is_open(bands, street.horizontal, bodies)

## **The disc a body closes a sidewalk with, here: one place, so it is one change.** A body is read
## at `EventPlan.blocking_radius()`, its body or a row's lethal inner disc, whichever is wider; **a
## row that spans the street (`EventDef.spans_the_street()`, the roadblock) is read at its band,
## its own body, at every heat**. From heat 4 the roadblock's copy hunts and its lethal inner
## radius would take both sidewalks from either road row, so it would be refused on every route
## street by itself. The other pursuers (the alley robbery, the charging dog) have no body and stay
## read at their lethal disc, which takes one sidewalk; the roadblock is the one exception, read at
## its band as the escape reads the same hunting roadblock (`WalkGround`). *Read as (the
## orchestrator's, open to the player's correction):* the band is the roadblock's body at every heat.
static func _closing_radius(plan: EventPlan) -> float:
	if plan.spans_the_street():
		return plan.obstructs_within()
	return plan.blocking_radius()

## Whether one of `bands` can be walked junction to junction past `bodies`.
func _one_is_open(bands: Array[Rect2i], horizontal: bool, bodies: Array) -> bool:
	for band in bands:
		if not RouteSidewalkRule.closes_a_walked_sidewalk_band(_map, band, horizontal, bodies):
			return true
	return false
