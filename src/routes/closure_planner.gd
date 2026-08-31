class_name ClosurePlanner
extends RefCounted
## Chooses which streets are closed today, and refuses to close so many that the day stops
## being a choice.
##
## Playtest 01, finding 12: *prune the road network per day with blockers, so the route is a
## real decision — avoidable, but clearly "not that way"*. The clarification that came out of
## planning it is the part that matters here: **a pruned network is not a corridor.** A
## single forced path is not a decision, and it would make a fixed city pointless because
## there would be nothing worth learning. So the day-level invariant is a floor, not a
## ceiling:
##
##     at least two distinct calm areas can still be walked to.
##
## It is checked before a closure is accepted rather than repaired afterwards — so the set that
## comes out of here always satisfies it, and there is no order-dependent unwinding to reason
## about.
##
## **It read "two distinct routes to two distinct calm areas" from M16 to 2026-08-31**, and the
## player's clarification is what changed it: *"the two routes guarantee is not a hard rule."*
## Edge-disjointness was standing in for winnability rather than being it — see
## `Tuning.MIN_CALM_AREAS_REACHABLE` — and under M50 a wall is placed off the day's tree, so what
## keeps the calm reachable is where a closure goes rather than how many ways round it there are.
##
## Everything here is deterministic from the day's RNG. A run is learnable or it is nothing.

## Somewhere today can be won, and the streets it is entered from.
##
## The access streets are what make the "two routes" question answerable for hidden calm as
## well as open calm. A park is entered from any of the four streets around it; a courtyard
## is entered through one archway onto one street. Arriving at *either end* of an access
## street counts, so a courtyard can still have two routes to it — the two routes differ
## everywhere except the doorway, which is the same exemption the home has always had.
class CalmArea extends RefCounted:
	var block: Vector2i
	var access: Array[StreetNetwork.Segment] = []

## Plans a day's closures. `map` must already be repainted for the day, because which blocks
## are calm is the thing the invariant is stated over and a requisitioned park is not one.
static func plan_day(map: CityMap, day: int, rng: RandomNumberGenerator) -> Array[RoadClosure]:
	var chosen: Array[RoadClosure] = []
	var wanted := Tuning.closures_for_day(day)
	if wanted <= 0:
		return chosen

	var home := home_street(map)
	var areas := calm_areas(map)
	# Nothing to protect, or nowhere to protect it from: close nothing rather than guess.
	if not home or areas.size() < Tuning.MIN_CALM_AREAS_REACHABLE:
		return chosen

	# The streets a four-block calm zone absorbed start out "closed" and stay that way. They are
	# not there to be shut and they are not there to be routed down either, and folding them in
	# here is the whole of what M21's holes cost the planner.
	var closed := map.blocked_segments()
	var kinds := RoadClosure.kinds_on(day)
	for segment in _shuffled_candidates(map, home, areas, rng):
		if chosen.size() >= wanted:
			break
		closed[segment.key()] = true
		if _invariant_holds(home, areas, closed):
			chosen.append(RoadClosure.new(_pick_kind(kinds, rng) as RoadClosure.Kind, segment))
		else:
			# Tried and rejected: this street is one of the ones holding the day up.
			closed.erase(segment.key())
	return chosen

## The street the front door opens onto. Never closable — the home is a notch in a block with
## one exit, so sealing it seals the player in. docs/CITY.md has carried that exemption since
## M3; this is where it is enforced.
static func home_street(map: CityMap) -> StreetNetwork.Segment:
	return StreetNetwork.segment_containing(
			map.world_to_tile(map.doorstep_world_position()))

## Today's calm ground, as areas with ways in.
static func calm_areas(map: CityMap) -> Array[CalmArea]:
	var found: Array[CalmArea] = []
	for block in map.calm_blocks:
		var area := CalmArea.new()
		area.block = block
		area.access = _access_streets(map, block)
		if not area.access.is_empty():
			found.append(area)
	return found

## The streets a calm area can be entered from. A block of open calm opens onto all four sides
## of its lot; a four-block zone onto eight streets, two to a side; a courtyard onto exactly
## one, through its archway.
static func _access_streets(map: CityMap, block: Vector2i) -> Array[StreetNetwork.Segment]:
	var found: Array[StreetNetwork.Segment] = []
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.passage):
		var side := _passage_side(CityMap.block_rect(block), layout.passage)
		var segment := StreetNetwork.beside_block(block, side)
		if segment:
			found.append(segment)
		return found
	return StreetNetwork.around_blocks(map.lot_blocks(block))

## Which edge of the lot an archway comes out on. The passage is generated as a one-tile
## channel from the court to one lot edge, so the edge it touches is the answer.
static func _passage_side(lot: Rect2i, passage: Rect2i) -> int:
	if passage.size.x == 1:
		return StreetNetwork.Side.NORTH if passage.position.y == lot.position.y \
				else StreetNetwork.Side.SOUTH
	return StreetNetwork.Side.WEST if passage.position.x == lot.position.x \
			else StreetNetwork.Side.EAST

# ---------------------------------------------------------------- invariant ---

## The day-level guarantee, in one place: enough calm areas can still be walked to.
##
## **It asked for two distinct routes to each of them until 2026-08-31**, and the player's own
## clarification is why it does not: *"the two routes guarantee is not a hard rule."* See
## `Tuning.MIN_CALM_AREAS_REACHABLE` for what that leaves standing and what it deliberately does
## not weaken.
static func _invariant_holds(home: StreetNetwork.Segment, areas: Array[CalmArea],
		closed: Dictionary) -> bool:
	var reachable := 0
	for area in areas:
		if StreetNetwork.route_count(home, area.access, closed, 1) >= 1:
			reachable += 1
			if reachable >= Tuning.MIN_CALM_AREAS_REACHABLE:
				return true
	return false

# ---------------------------------------------------------------- placement ---

## Every closable street, in the order the day will try them — weighted so that the streets
## the player would actually have used come up first.
##
## A closure in the far corner of a map is not a decision, it is scenery. The bias is what
## makes the mechanic do its job: a street is *useful* if it lies on a shortest way from the
## door to some calm ground, give or take a block, and a useful street is several times
## likelier to be the one that is shut. The invariant is what stops that from being cruel.
static func _shuffled_candidates(map: CityMap, home: StreetNetwork.Segment,
		areas: Array[CalmArea], rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
	var useful := _streets_on_a_route(map, home, areas)
	var pool: Array[StreetNetwork.Segment] = []
	var weights: Array[float] = []
	for segment in StreetNetwork.segments():
		if segment.key() == home.key() or not map.has_street(segment.key()):
			continue
		pool.append(segment)
		weights.append(Tuning.CLOSURE_ROUTE_BIAS if useful.has(segment.key()) else 1.0)

	var order: Array[StreetNetwork.Segment] = []
	while not pool.is_empty():
		var index := _pick_weighted(weights, rng)
		order.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	return order

## The streets on a near-shortest way from the door to some calm ground, as a set of keys.
##
## `from_home[u] + 1 + to_calm[v]` is the length of the best route that goes through this
## street; comparing it against the best route overall says whether the street is on the way
## or a detour. The slack is what keeps it from being a single line of tiles: at slack 1
## every street that costs one extra block still counts, which is roughly "the ways a player
## would actually consider".
static func _streets_on_a_route(map: CityMap, home: StreetNetwork.Segment,
		areas: Array[CalmArea]) -> Dictionary:
	var useful := {}
	var absent := map.blocked_segments()
	var from_home := StreetNetwork.junction_distances([home.a, home.b], absent)
	for area in areas:
		var doorsteps: Array[Vector2i] = []
		for segment in area.access:
			doorsteps.append(segment.a)
			doorsteps.append(segment.b)
		var to_calm := StreetNetwork.junction_distances(doorsteps, absent)
		var best := INF
		for junction in doorsteps:
			var node := StreetNetwork.node_of(junction)
			if from_home.has(node):
				best = minf(best, float(from_home[node]))
		if best == INF:
			continue
		for segment in StreetNetwork.segments():
			if absent.has(segment.key()):
				continue
			var u := StreetNetwork.node_of(segment.a)
			var v := StreetNetwork.node_of(segment.b)
			var through := minf(_through(from_home, to_calm, u, v),
					_through(from_home, to_calm, v, u))
			if through <= best + Tuning.CLOSURE_ROUTE_SLACK:
				useful[segment.key()] = true
	return useful

static func _through(from_home: Dictionary, to_calm: Dictionary, u: int, v: int) -> float:
	if not from_home.has(u) or not to_calm.has(v):
		return INF
	return float(from_home[u]) + 1.0 + float(to_calm[v])

static func _pick_weighted(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := rng.randf() * total
	for index in weights.size():
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return weights.size() - 1

## What closed this street. Weighted from the kinds the day has reached, so act I closes a
## street by accident and act IV closes it by bringing the building down.
static func _pick_kind(kinds: Array[int], rng: RandomNumberGenerator) -> int:
	var weights: Array[float] = []
	for kind in kinds:
		weights.append(float(RoadClosure.KINDS[kind]["weight"]))
	return kinds[_pick_weighted(weights, rng)]
