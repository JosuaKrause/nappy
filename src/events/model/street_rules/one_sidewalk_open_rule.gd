class_name OneSidewalkOpenRule
extends StreetRule
## **No street of her routes has both its sidewalks closed by bodies a draw put on them**: a
## candidate that blocks the way (`EventPlan.obstructs()`, at `blocking_radius()`) is refused
## where, for a street of her routes its body reaches, neither sidewalk can be walked
## junction to junction with it standing (`RouteSidewalkRule.closes_a_walked_sidewalk_band()`,
## asked of both of the street's bands against the bodies standing round it), and one could
## without it.
##
## **Each body is read where it stands** (`BodyStance.of_plan()`'s centre), not where it was
## placed: a sidewalk body stands on the middle of its pavement band, half a tile across from the
## lane tile the draw chose, and the half tile decides whether the sidewalk beside a second body
## stays walkable. Read at the lane tile, a café's tables on one sidewalk and a leaf blower on the
## other passed the rule and shut the street where the game stood them.
##
## **Only her routes' own streets** (`Corridor.view_of()` on the route). *(Inbox #1465 in
## spry-plover, the player's answer on the board: "what I said was *if* a street needs to have one
## sidewalk walkable *then* the placement of the drawn events needs to make sure of that".)* No
## street is newly required to keep a sidewalk; a route's street already is, and the draw makes
## sure of it. The streets beside the routes and off them keep their blocking events all over (PLAYTEST-17:
## "areas that outside the paths should have blocking events all over"), and the escape's walk
## keeps its own rule.
##
## **And day 1's walk left open on day 2** (`kept`, the tutorial route's lesson streets,
## `DayStreets.tutorial_walk_left_open()`): those streets are off the day's tree, yet the walk is
## the path she is meant to walk again to the park she used *(minty-dolphin #834, the player:
## "there should be a path that touches the first day's park so the player learns this lesson
## (since they are free to go to it again)")*, so each is a street that needs one sidewalk
## walkable, and the draw keeps one there as on a route's street. Without it, rows that take a
## whole sidewalk each (a café's tables, a van) stand on both sides of a lesson street now and then
## and shut the walk.
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
## - **Both roadblocks are asked too** (*inbox #747 in woolly-penguin: "roadblocks currently are
##   impossible to get past. one sidewalk must be open if they're en-route."*). Each spans the
##   street by design (`EventDef.spans_the_street()`), and is read at its band at every heat, since
##   its guard's catch lies inside the band (`EventDef.catch_shuts_within()`). The open roadblock's
##   band stands on the kerb beside its lane (`EventPlan.body_at()`) and takes the sidewalk on its
##   own side of the road and the road, leaving the far sidewalk whole, so it is refused where a
##   body already closes that far sidewalk, and a body drawn after it is refused across from it the
##   same way. The closing roadblock's band stands on the street's middle
##   (`EventDef.stands_mid_street()`) and takes both sidewalks, so this rule refuses it alone on any
##   street of her routes; it stands only beside and off them, and the route's bags hold no marble
##   of it (`EventDef.stands_off_the_route()`, which follows this rule).
##
## It asks a body, never a cost: a row whose field alone covers both sidewalks is the line rules'
## question. Model: no node.

var _map: CityMap
var _corridor: Corridor
## The keys of the streets kept beside her routes' own (`kept`), as a set.
var _kept := {}

## The rule on `map` for the routes `corridor` runs (null for a walk with no route tree: no street
## is on a route then), and for `kept`, the streets off them that keep a sidewalk too: day 1's walk
## left open, or none.
func _init(map: CityMap, corridor: Corridor,
		kept: Array[StreetNetwork.Segment] = []) -> void:
	_map = map
	_corridor = corridor
	for street in kept:
		_kept[street.key()] = true

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], around: Array[EventPlan]) -> bool:
	if not candidate.obstructs():
		return true
	for street in _streets_reached_by(candidate):
		if _keeps_a_sidewalk(street) and _closes_its_last_sidewalk(street, candidate, around):
			return false
	return true

## The streets a body's disc reaches a tile of, with her own radius on it: a body stops her
## `blocking_radius() + PLAYER_BODY_RADIUS` from where it stands. The streets this city has only.
func _streets_reached_by(plan: EventPlan) -> Array[StreetNetwork.Segment]:
	var reach := plan.blocking_radius() + Tuning.PLAYER_BODY_RADIUS
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

## Whether `street` keeps a sidewalk: a route of the day runs along it, or it is one of the
## streets kept beside them.
func _keeps_a_sidewalk(street: StreetNetwork.Segment) -> bool:
	if _kept.has(street.key()):
		return true
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
		var radius := plan.blocking_radius()
		var at := BodyStance.of_plan(_map, plan).center()
		if world.grow(radius + Tuning.PLAYER_BODY_RADIUS).has_point(at):
			bodies.append(Vector3(at.x, at.y, radius))
	var bands := Corridor.sidewalk_bands(rect, street.horizontal)
	if not _one_is_open(bands, street.horizontal, bodies):
		return false
	var stands := BodyStance.of_plan(_map, candidate).center()
	bodies.append(Vector3(stands.x, stands.y, candidate.blocking_radius()))
	return not _one_is_open(bands, street.horizontal, bodies)

## Whether one of `bands` can be walked junction to junction past `bodies`.
func _one_is_open(bands: Array[Rect2i], horizontal: bool, bodies: Array) -> bool:
	for band in bands:
		if not RouteSidewalkRule.closes_a_walked_sidewalk_band(_map, band, horizontal, bodies):
			return true
	return false
