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
## **Since M50 step 2 a closure is a `wall`, in the sense `docs/CITY.md` gives that word**, and the
## practical difference is which streets it may land on: a closure is placed **off** the day's
## corridor, preferentially on a turning off it. *"A road block becomes guidance and is not a
## hindrance. It flips its role."* See `_shuffled_candidates`, which is where the flip lives, and
## note what it does to the invariant above — a wall off the tree cannot cut the tree, so the check
## below stopped being the thing that keeps a day winnable and became the second opinion on it.
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
##
## `tree` is the day's corridor, and every closure is placed **off** it. The caller passes the one
## it is going to plan the rest of the day against; when there is none to hand this grows the same
## one, because `RouteTree.for_day` is a pure function of the city's seed and the day number.
static func plan_day(map: CityMap, day: int, rng: RandomNumberGenerator,
		tree: RouteTree = null) -> Array[RoadClosure]:
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
	var corridor := tree if tree else RouteTree.for_day(map, day)
	for segment in _shuffled_candidates(map, home, corridor, rng):
		if chosen.size() >= wanted:
			break
		closed[segment.key()] = true
		if _invariant_holds(home, areas, closed):
			chosen.append(RoadClosure.new(_pick_kind(kinds, rng) as RoadClosure.Kind, segment))
		else:
			# **A wall off the tree should never fail this**, so a failure is not a near miss to be
			# skipped quietly — it means the corridor and the wall disagree about where she is
			# going, which is the one bug this milestone can have that nothing else would show.
			# `tests/test_routes.gd` asserts it never happens over a run's worth of days; the note
			# is what would say so in a real run.
			closed.erase(segment.key())
			Telemetry.note("plan", "day %d: closing %s off the corridor would have cut the calm"
					% [day, TelemetryLog.tile(segment.a)])
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

## Every street the day may shut, in the order it will try them.
##
## **This is the inversion, and it is the whole of M50 step 2 on this side.** *"A road block becomes
## guidance and is not a hindrance. It flips its role."* Until now a closure was biased *onto* the
## streets the player would have used — `CLOSURE_ROUTE_BIAS`, five to one — because a closure was
## an obstacle and an obstacle nobody meets is scenery. Under the diversion design a closure is a
## **wall**: it prunes the ways that lead nowhere she should go, so that the ways that remain are
## obvious. Placing one across her route is now the defect rather than the point.
##
## So the tree is not weighted against, it is **excluded**. A wall that cuts the corridor is not a
## worse wall, it is the opposite of one, and the guarantee that it cannot happen is what lets the
## rest of the day be planned against a tree that is still walkable when the barriers go up.
##
## What is left splits in two, and the preference between them is `CLOSURE_WALL_BIAS`:
##
## - **The rim** — a turning off a street the routes run down. This is what a closure is *for*: it
##   is read from the junction, where the wrong way is still a choice, which is the same reason
##   `RoadClosure` seals both mouths rather than putting one sign half way down.
## - **Everywhere else** — legal, and it is the far corner of the map that the old bias existed to
##   avoid. Kept in the pool rather than refused, because a day that cannot find its quota of
##   rim streets should still shut something.
static func _shuffled_candidates(map: CityMap, home: StreetNetwork.Segment,
		tree: RouteTree, rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
	var rim := {}
	for key in tree.rim():
		rim[key] = true
	var pool: Array[StreetNetwork.Segment] = []
	var weights: Array[float] = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if key == home.key() or not map.has_street(key) or tree.is_on_the_tree(key):
			continue
		pool.append(segment)
		weights.append(Tuning.CLOSURE_WALL_BIAS if rim.has(key) else 1.0)

	var order: Array[StreetNetwork.Segment] = []
	while not pool.is_empty():
		var index := _pick_weighted(weights, rng)
		order.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	return order

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
