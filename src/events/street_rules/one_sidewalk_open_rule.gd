class_name OneSidewalkOpenRule
extends StreetRule
## **No street has both its sidewalks closed by bodies a draw put on them** (inbox #1465: "if one
## sidewalk is blocked then the other sidewalk cannot draw a block again"): a candidate that blocks
## the way (`EventPlan.obstructs()`, at `EventPlan.blocking_radius()`) is refused where, for a
## street its body reaches, neither sidewalk can be walked junction to junction with it standing
## (`RouteSidewalkRule.closes_a_walked_sidewalk_band()`, asked of both of the street's bands against
## the bodies standing round it), and one could without it.
##
## - **Both ways round**: the street's own second body is refused, and so is a neighbour's body
##   reaching into the street's last open sidewalk, whichever draws first. A street draws all its
##   locations at once and its touching units draw before it or after it with what it drew in view,
##   so a street drawing after its neighbours keeps one sidewalk open, given what they drew.
## - **A street already closed is left alone**: one a seal, a closure or the region wall closes
##   has no open sidewalk to keep, and nothing is refused there.
## - **A roadblock is asked too** (*inbox #747 in woolly-penguin: "roadblocks currently are
##   impossible to get past. one sidewalk must be open if they're en-route."*). It spans the street
##   by design (`EventDef.spans_the_street()`), and its band takes the sidewalk on its own side of
##   the road and leaves the far one, so it is refused where a body already closes that far
##   sidewalk, and a body drawn after it is refused across from it the same way.
##
## It asks a body, never a cost: a row whose field alone covers both sidewalks is the line rules'
## question, and on a street off the routes it may stand (the leaf blower, the man shouting). Which
## streets it covers is one setting (`COVERS`). Model: no node.

## Which streets the rule keeps a sidewalk open on.
enum Streets {
	## The streets of her routes and the streets touching them (`Corridor.view_of()`: on the route
	## and route-adjacent). Further off, nothing is refused.
	NEAR_THE_ROUTES,
	## Every street of the day.
	EVERY_STREET,
}

## **The streets the day's rule covers.** The player's words say every street (inbox #1465); the
## streets off the routes are also where the player asked for blocking events all over, so she
## stays out of them (PLAYTEST-17, "areas that outside the paths should have blocking events all
## over"). Until the board's question open-sidewalk-reach settles which holds off the routes, the
## rule keeps a sidewalk open near the routes, where she walks, and leaves the walls further off
## as they are drawn.
const COVERS := Streets.NEAR_THE_ROUTES

var _map: CityMap
var _corridor: Corridor
var _streets: Streets

## The rule on `map` for the routes `corridor` runs (null for a walk with no route tree: nothing is
## near a route then), covering `streets`.
func _init(map: CityMap, corridor: Corridor, streets := COVERS) -> void:
	_map = map
	_corridor = corridor
	_streets = streets

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], around: Array[EventPlan]) -> bool:
	if not candidate.obstructs():
		return true
	for street in _streets_reached_by(candidate):
		if _covers(street) and _closes_its_last_sidewalk(street, candidate, around):
			return false
	return true

## The streets a body's disc reaches a tile of, with her own radius on it: a body stops her
## `blocking_radius() + PLAYER_BODY_RADIUS` from where it stands. The streets this city has only.
func _streets_reached_by(plan: EventPlan) -> Array[StreetNetwork.Segment]:
	var reach := plan.blocking_radius() + Tuning.PLAYER_BODY_RADIUS
	var from := _map.world_to_tile(plan.placed_at() - Vector2.ONE * reach)
	var to := _map.world_to_tile(plan.placed_at() + Vector2.ONE * reach)
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

## Whether the setting covers `street`.
func _covers(street: StreetNetwork.Segment) -> bool:
	if _streets == Streets.EVERY_STREET:
		return true
	if _corridor == null:
		return false
	var view := _corridor.view_of(street)
	return view == PlacementView.View.ON_THE_ROUTE or view == PlacementView.View.ROUTE_ADJACENT

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
		if world.grow(radius + Tuning.PLAYER_BODY_RADIUS).has_point(plan.placed_at()):
			bodies.append(Vector3(plan.placed_at().x, plan.placed_at().y, radius))
	var bands := Corridor.sidewalk_bands(rect, street.horizontal)
	if not _one_is_open(bands, street.horizontal, bodies):
		return false
	bodies.append(Vector3(candidate.placed_at().x, candidate.placed_at().y,
			candidate.blocking_radius()))
	return not _one_is_open(bands, street.horizontal, bodies)

## Whether one of `bands` can be walked junction to junction past `bodies`.
func _one_is_open(bands: Array[Rect2i], horizontal: bool, bodies: Array) -> bool:
	for band in bands:
		if not RouteSidewalkRule.closes_a_walked_sidewalk_band(_map, band, horizontal, bodies):
			return true
	return false
