class_name ClosurePlanner
extends RefCounted
## Chooses which streets are closed today, and refuses to close so many that the day stops
## being a choice.
##
## The network is pruned per day so that the route is a real decision — avoidable, but clearly
## *not that way*. **A pruned network is not a corridor**, and that is the part to keep hold of: a
## single forced path is not a decision, and it would make a fixed city pointless because there
## would be nothing worth learning. So the day-level invariant is a floor, not a ceiling:
##
##     at least two distinct calm areas can still be walked to.
##
## It is checked before a closure is accepted rather than repaired afterwards — so the set that
## comes out of here always satisfies it, and there is no order-dependent unwinding to reason
## about.
##
## **Not "two distinct routes to two distinct calm areas".** Edge-disjointness stands in for
## winnability rather than being it — see `Tuning.MIN_CALM_AREAS_REACHABLE` — and a wall is placed
## off the day's tree anyway, so what keeps the calm reachable is where a closure goes rather than
## how many ways round it there are.
##
## **A closure is a `wall`, in the sense `docs/CITY.md` gives that word**, and the practical
## difference is which streets it may land on: it is placed **off** the day's corridor,
## preferentially on a turning off it, so that a road block is guidance rather than a hindrance.
## See `_shuffled_candidates`, which is where that lives, and note what it does to the invariant
## above — a wall off the tree cannot cut the tree, so the check below is the second opinion on
## winnability rather than the thing that keeps it.
##
## Everything here is deterministic from the day's RNG. A run is learnable or it is nothing.

## Somewhere today can be won: its own ground, and the streets it is entered from.
##
## **`rect` is what "reachable" is asked about now** — the tile rect of the area's own calm
## ground, the lot for open calm and the court alone for a courtyard — because the grid answers a
## question about tiles rather than about streets. `access` survives for the one thing still asked
## of the graph rather than the grid: `CityGenerator._the_calm_survives` and `validate()` test a
## *hard* blocker before its wall is built, when the street is absent from the lattice but its
## tiles are not yet a wall — a fact the grid, built from tiles, cannot see and the segment graph
## can.
class CalmArea extends RefCounted:
	var block: Vector2i
	var rect: Rect2i
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

	var kinds := RoadClosure.kinds_on(day)
	var corridor := tree if tree else RouteTree.for_day(map, day)
	# Built once and asked many times: the grid is the day's tiles, which do not move while
	# candidates are tried — only the barrier tiles a candidate would add do.
	var grid := ReachabilityGrid.build(map)
	var today_closed := {}
	for segment in _shuffled_candidates(map, home, areas, corridor, rng):
		if chosen.size() >= wanted:
			break
		today_closed[segment.key()] = true
		if _invariant_holds(map, grid, areas, today_closed):
			chosen.append(RoadClosure.new(_pick_kind(kinds, rng) as RoadClosure.Kind, segment))
		else:
			# **A wall off the tree should never fail this**, so a failure is not a near miss to be
			# skipped quietly — it means the corridor and the wall disagree about where she is
			# going, which is the one bug this milestone can have that nothing else would show.
			# `tests/test_routes.gd` asserts it never happens over a run's worth of days; the note
			# is what would say so in a real run.
			today_closed.erase(segment.key())
			Telemetry.note("plan", "day %d: closing %s off the corridor would have cut the calm"
					% [day, TelemetryLog.tile(segment.a)])
	return chosen

## The street the front door opens onto. Never closable — the home is a notch in a block with
## one exit, so sealing it seals the player in. docs/CITY.md states that exemption; this is where
## it is enforced.
static func home_street(map: CityMap) -> StreetNetwork.Segment:
	return StreetNetwork.segment_containing(
			map.world_to_tile(map.doorstep_world_position()))

## Today's calm ground, as areas with their own ground and ways in.
static func calm_areas(map: CityMap) -> Array[CalmArea]:
	var found: Array[CalmArea] = []
	for block in map.calm_blocks:
		var area := CalmArea.new()
		area.block = block
		area.rect = calm_area_rect(map, block)
		area.access = _access_segments(map, area.rect)
		if not area.access.is_empty():
			found.append(area)
	return found

## The tile rect of a calm block's own calm ground — the open rect for open calm, falling back to
## the whole lot. Also what `EventScheduler._calm_rect` protects from spoiling; the two ask the
## same question and this is the one place it is answered.
static func calm_area_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

## The streets a calm area can be entered from, found by walking out from its own tiles rather
## than by reasoning about the lot's geometry.
##
## **This is what replaced the lot-geometry version, and the bug it had is why.** The old
## `_access_streets` read the archway's side off the *lot rect*, which agrees with the *block* rect
## for a one-block courtyard and disagrees on three sides out of four for a four-block apartment
## complex — so the street it named was sometimes one of the complex's own absorbed streets, not in
## the lattice at all, which read as *this calm area cannot be reached from the home*. Walking the
## actual tiles has no geometry to get wrong: an open block's every bordering street is one step
## away and found immediately; a courtyard's archway is a corridor of non-street tiles the walk
## simply continues through until it reaches a real one, whatever shape the lot is.
static func _access_segments(map: CityMap, rect: Rect2i) -> Array[StreetNetwork.Segment]:
	var found := {}
	var visited := {}
	for tile in map.rect_tiles(rect):
		visited[tile] = true
	var queue: Array[Vector2i] = []
	for tile in map.rect_tiles(rect):
		_queue_walkable_neighbours(map, tile, visited, queue)
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		var segment := StreetNetwork.segment_containing(tile)
		# A **real** street is where this direction's search stops: what lies beyond it is not
		# "entered from" this area, it is somewhere the street itself leads on to. `segment_
		# containing` answers from tile geometry alone, so it still names a segment where a
		# four-block apartment complex's own absorbed street used to run, even though nothing
		# there is a street any more — an archway that happens to cross that footprint on its way
		# out must keep walking through it rather than stopping, or the "street" it names is one
		# `map.has_street` already says is not in the lattice at all.
		if segment and map.has_street(segment.key()):
			found[segment.key()] = segment
			continue
		_queue_walkable_neighbours(map, tile, visited, queue)
	var result: Array[StreetNetwork.Segment] = []
	for key in found:
		result.append(found[key])
	return result

const _NEIGHBOUR_OFFSETS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

static func _queue_walkable_neighbours(map: CityMap, tile: Vector2i, visited: Dictionary,
		queue: Array[Vector2i]) -> void:
	for offset in _NEIGHBOUR_OFFSETS:
		var neighbour := tile + offset
		if visited.has(neighbour) or not map.is_walkable(neighbour):
			continue
		visited[neighbour] = true
		queue.append(neighbour)

# ---------------------------------------------------------------- invariant ---

## The day-level guarantee, in one place: enough calm areas can still be walked to.
##
## **It asks the grid rather than the junction graph now**, because the graph cannot see a park or
## an alley at all — it only knows a street is an edge, never that the ground beside it is calm
## ground somebody can step onto from a direction no barrier stands across. `grid` is the day's
## tiles, built once per `plan_day` call; `today_closed` is the segments a candidate would add on
## top of it, which is where the barrier tiles asked of the grid actually come from — see
## `_barrier_tiles`.
##
## **It asked for two distinct routes to each of them until 2026-08-31**, and the player's own
## clarification is why it does not: *"the two routes guarantee is not a hard rule."* See
## `Tuning.MIN_CALM_AREAS_REACHABLE` for what that leaves standing and what it deliberately does
## not weaken.
static func _invariant_holds(map: CityMap, grid: ReachabilityGrid, areas: Array[CalmArea],
		today_closed: Dictionary) -> bool:
	var blocked := _barrier_tiles(map, today_closed)
	var reached := grid.flood([_home_tile(map)], blocked)
	var reachable := 0
	for area in areas:
		if _area_is_reached(map, grid, reached, blocked, area):
			reachable += 1
			if reachable >= Tuning.MIN_CALM_AREAS_REACHABLE:
				return true
	return false

static func _home_tile(map: CityMap) -> Vector2i:
	return map.world_to_tile(map.doorstep_world_position())

## Whether some tile of `area`'s own calm ground is reached, under a `reached` set `grid.flood()`
## produced for this same `blocked` dictionary.
static func _area_is_reached(map: CityMap, grid: ReachabilityGrid, reached: Dictionary,
		blocked: Dictionary, area: CalmArea) -> bool:
	for tile in map.rect_tiles(area.rect):
		if Tile.is_calm(map.tile_at(tile)) and grid.reaches(tile, blocked, reached):
			return true
	return false

## Every tile a barrier would stand on for the segments in `closed` — the two mouths of each, which
## is where `RoadClosure` actually places one. **Never the whole street**: the ground between the
## two mouths is not blocked by a barrier standing at either end of it, which is the fact
## `RoadClosure.tiles()` gets right and `_invariant_holds` needs too, or a candidate would be
## judged against a street that is not the one the closure actually builds.
static func _barrier_tiles(map: CityMap, closed: Dictionary) -> Dictionary:
	var tiles := {}
	for key: Vector3i in closed:
		if map.absent_segments.has(key):
			continue   # ground a calm zone painted over, not a street with a barrier on it
		var segment := StreetNetwork.by_key(key)
		if not segment:
			continue
		for at_a in [true, false]:
			for tile in map.rect_tiles(segment.mouth_rect(at_a)):
				tiles[tile] = true
	return tiles

# ---------------------------------------------------------------- placement ---

## Every street the day may shut, in the order it will try them.
##
## **A closure is guidance rather than a hindrance, and this is where that is decided.** Biasing one
## *onto* the streets the player would have used treats it as an obstacle, on the argument that an
## obstacle nobody meets is scenery. It is a **wall** instead: it prunes the ways that lead nowhere
## she should go, so that the ways that remain are obvious. Placing one across her route is the
## defect, not the point.
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
##
## **And one part of the rim is worth more than the rest of it.** A **gap** is the single street two
## adjacent strands of today's corridor are joined by — see `RouteTree.gaps()` — and shutting some
## of them is what stops two parallel routes from being one wide one. A closure is the *impassable*
## half of that, where a wall event is the costly half. `CLOSURE_GAP_BIAS` is the preference, and
## the day's quota is what keeps it a *sometimes*: one street shut in act I and four in act IV
## cannot close fifteen gaps however hard it aims at them.
##
## The invariant below is unmoved and still does the deciding. A gap is off the tree like every
## other candidate, so nothing here can cut the corridor; what the check catches is the same thing
## it always did.
##
## **A calm area's own access streets are refused outright, never merely weighted down.** This is
## the payoff the grid exists for, and it is one rule for two asymmetric reasons:
##
## - **A park is walked through**, so a barrier on any of its access streets — every street round
##   its lot, since `_access_segments` finds all of them — closes nothing. It is read as broken by
##   anybody standing at it looking at the open ground beside it.
## - **A courtyard is a pocket with one door**, so a barrier beside it is a real closure — but not
##   on the one street its archway opens onto, which is a courtyard's *own* access street and
##   nothing else. A barrier there does not lengthen the walk to the courtyard, it ends it.
##
## Refusing every area's access streets happens to cover both without asking which kind of calm
## area it is: an open block's access is every side of it, so refusing all of it is refusing
## "beside the park"; a courtyard's access is the one street its archway is on, so refusing it is
## refusing exactly that street and nothing beside it.
##
## **Stated over the cells the barrier touches, not over the map.** M45 measured the global version
## — *does this closure lengthen the best route to any calm area* — and it does not work: 350
## closures across ten seeds changed the best route to the nearest calm area exactly once, because a
## Manhattan lattice with several calm areas almost always has another way round. The local version
## asked here needs no route search at all: it is a fact about which street an archway sits on.
static func _shuffled_candidates(map: CityMap, home: StreetNetwork.Segment, areas: Array[CalmArea],
		tree: RouteTree, rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
	var rim := {}
	for key in tree.rim():
		rim[key] = true
	var gaps := {}
	for key in tree.gaps():
		gaps[key] = true
	var access := {}
	for area in areas:
		for segment in area.access:
			access[segment.key()] = true
	var pool: Array[StreetNetwork.Segment] = []
	var weights: Array[float] = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if key == home.key() or not map.has_street(key) or tree.is_on_the_tree(key) \
				or access.has(key):
			continue
		pool.append(segment)
		var weight := Tuning.CLOSURE_WALL_BIAS if rim.has(key) else 1.0
		weights.append(weight * Tuning.CLOSURE_GAP_BIAS if gaps.has(key) else weight)

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
