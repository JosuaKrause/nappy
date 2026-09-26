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
##
## `region_plan` is likewise the caller's own, or grown fresh the same way — `RegionPlanner.
## plan_day` is a pure function of the map, the day and the tree. Its walls and doors are refused
## as closure candidates: a closure on a region boundary would be two things standing in the same
## spot, one placed by this pass and one by the region's own wall or door.
##
## **`CityMap.fenced_park`'s fence comes back with the streets** (one `ParkClosure` per fenced run
## of its edge), after them and outside the day's quota: it is what `City` stands barriers at, the
## same way it stands them at a closed street's two mouths. Every other used area in `CityMap.
## shut_calm` gets no fence at all — it is off the route tree but not off the ground, so nothing
## here draws anything for it. The fenced ground itself was decided at the repaint and is already
## closed on the map, so every candidate below is judged with it closed.
static func plan_day(map: CityMap, day: int, rng: RandomNumberGenerator,
		tree: RouteTree = null, region_plan: RegionPlanner.RegionPlan = null) -> Array[RoadClosure]:
	var chosen := _close_streets(map, day, rng, tree, region_plan)
	if map.fenced_park.x >= 0:
		for fence in ParkClosure.fence(map, map.fenced_park):
			chosen.append(fence)
	return chosen

static func _close_streets(map: CityMap, day: int, rng: RandomNumberGenerator,
		tree: RouteTree, region_plan: RegionPlanner.RegionPlan) -> Array[RoadClosure]:
	var chosen: Array[RoadClosure] = []
	# Whatever this day does or does not close, it owns the answer to which pits are empty — so a
	# day that closes nothing says so, rather than leaving yesterday's fallen tree missing from the
	# row. See `CityMap.set_closure_tree_pits`.
	map.set_closure_tree_pits([] as Array[Vector2i])
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
	var regions := region_plan if region_plan else RegionPlanner.plan_day(map, day, corridor)
	# Built once and asked many times: the grid is the day's tiles, which do not move while
	# candidates are tried — only the barrier tiles a candidate would add do.
	var grid := ReachabilityGrid.build(map)
	# Which segment has a standing street tree, asked once rather than once per candidate — see
	# `StreetTrees` for why the same set also decides what `City` draws.
	var tree_segments := StreetTrees.segment_keys_with_trees(map)
	# The pits today's fallen trees take, collected as they are chosen and handed to the map whole
	# below.
	var emptied: Array[Vector2i] = []
	var today_closed := {}
	var places := places_to_reach_today(map, day, regions)
	for segment in _shuffled_candidates(map, home, areas, corridor, regions, rng):
		if chosen.size() >= wanted:
			break
		today_closed[segment.key()] = true
		if _invariant_holds(map, grid, areas, today_closed, places):
			var kind := _pick_kind(kinds, rng, tree_segments.has(segment.key())) as RoadClosure.Kind
			chosen.append(RoadClosure.new(kind, segment))
			if kind == RoadClosure.Kind.FALLEN_TREE:
				# The tree that fell is the one that is missing. Which pit is this planner's, and
				# the answer is the one nearest the middle of the street it closed — a gap at the
				# far end of the street from the wreck would read as two different trees.
				var centre := map.tile_rect_to_world(segment.tile_rect()).get_center()
				var pit := StreetTrees.pit_nearest(map, segment.key(), centre)
				if pit:
					emptied.append(pit.tile)
		else:
			# **A wall off the tree should never fail this**, so a failure is not a near miss to be
			# skipped quietly — it means the corridor and the wall disagree about where she is
			# going, which is the one bug this milestone can have that nothing else would show.
			# `tests/test_routes.gd` asserts it never happens over a run's worth of days; the note
			# is what would say so in a real run.
			today_closed.erase(segment.key())
			Telemetry.note("plan", "day %d: closing %s off the corridor would have cut the calm"
					% [day, TelemetryLog.tile(segment.a)])
	map.set_closure_tree_pits(emptied)
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

# ------------------------------------------------------------ spent calm ---

## Which of the calm areas she has used this act (`spent`, most recent first) are taken off today's
## route tree: the tree neither grows a branch to one nor runs a route through it, though the
## ground stays calm and walkable — she is stopped by what `EventScheduler.
## _spoil_the_parks_she_used` places there, not by the ground itself. *(PLAYTEST-140, statement 8:
## "a used park is shut by the events placed in it, as before... and no route of the day goes
## through it".)* Called by `CityMap.repaint()`, before anything grows the day's tree, so the tree,
## the region plan and the street closures are all planned around what this excludes.
##
## **Checked before it is accepted, one area at a time, the way a street closure is** — never
## exclude everything and then reinclude until the day is legal. An area is refused for the day, and
## stays fully on the tree's table, when excluding it would:
##
## - **leave fewer than `Tuning.MIN_CALM_AREAS_REACHABLE` calm areas open** — the count every
##   closure is held to, and what leaves `EventScheduler._ensure_one_usable_park` a park to keep
##   clean;
## - **cut anything off** — any tile the doorstep reaches with nothing excluded that it no longer
##   reaches with this area and every area already accepted, both simulated as if their ground were
##   impassable. That is stronger than the calm count, and it is the one question that covers every
##   guarantee at once: the other calm areas, day 9's door and the power station's door, and every
##   street a route could need, since a park that is the only way between two parts of the city is a
##   park a route still has to be allowed through.
##
## `protected` is never excluded: day 12's park, whose swing is the day's task. An area that is not
## calm today (requisitioned since, or never calm) is not in `map.calm_blocks` and is passed over.
## A refused area is still one she has used, so `EventScheduler._spoil_the_parks_she_used` spoils it
## — which every accepted area not chosen as `CityMap.fenced_park` also gets, since exclusion from
## the tree is the only thing accepting an area here actually does.
static func calm_to_shut(map: CityMap, spent: Array[Vector2i],
		protected: Array[Vector2i] = []) -> Array[Vector2i]:
	var shut: Array[Vector2i] = []
	var candidates: Array[Vector2i] = []
	for block in spent:
		if block in map.calm_blocks and not block in protected and not block in candidates:
			candidates.append(block)
	if candidates.is_empty():
		return shut
	var home := _home_tile(map)
	var before := map.walk_field(home)
	var blocked := {}
	for block in candidates:
		if map.calm_blocks.size() - shut.size() - 1 < Tuning.MIN_CALM_AREAS_REACHABLE:
			Telemetry.note("plan", "the calm area she used at %s stays open: shutting it would "
					% TelemetryLog.tile(block) + "leave fewer than %d open"
					% Tuning.MIN_CALM_AREAS_REACHABLE)
			continue
		var trial := blocked.duplicate()
		for tile in map.rect_tiles(calm_area_rect(map, block)):
			if map.is_walkable(tile):
				trial[tile] = true
		var after := map.walk_field(home, trial)
		var cut := _tiles_cut_off(map, before, after, trial)
		if cut > 0:
			Telemetry.note("plan", "the calm area she used at %s stays open: shutting it would cut "
					% TelemetryLog.tile(block) + "%d tiles off from the doorstep" % cut)
			continue
		if _open_calm_reached(map, after, shut, block) < Tuning.MIN_CALM_AREAS_REACHABLE:
			Telemetry.note("plan", "the calm area she used at %s stays open: shutting it would "
					% TelemetryLog.tile(block) + "leave fewer than %d reachable"
					% Tuning.MIN_CALM_AREAS_REACHABLE)
			continue
		shut.append(block)
		blocked = trial
		Telemetry.note("plan", "the calm area she used at %s is shut today"
				% TelemetryLog.tile(block))
	return shut

## How many tiles `before` reached that `after` does not, leaving out the shut ground itself
## (`shut`). Both are `CityMap.walk_field()` sweeps from the doorstep, flat and indexed alike.
static func _tiles_cut_off(map: CityMap, before: PackedInt32Array, after: PackedInt32Array,
		shut: Dictionary) -> int:
	var cut := 0
	var width := map.size.x
	for index in before.size():
		if before[index] < 0 or after[index] >= 0:
			continue
		if shut.has(Vector2i(index % width, index / width)):
			continue
		cut += 1
	return cut

## How many calm areas neither shut already (`shut`) nor about to be (`besides`) still have a calm
## tile `field` reaches.
static func _open_calm_reached(map: CityMap, field: PackedInt32Array, shut: Array[Vector2i],
		besides: Vector2i) -> int:
	var reached := 0
	for block in map.calm_blocks:
		if block == besides or block in shut:
			continue
		for tile in map.rect_tiles(calm_area_rect(map, block)):
			if Tile.is_calm(map.tile_at(tile)) and map.reaches(field, tile):
				reached += 1
				break
	return reached

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
##
## **It also asks for each of the day's own destinations** (`places`, from
## `places_to_reach_today()`, empty on most days): the resistance's door, swing or the power
## station's front door on theirs. Each is a set of tiles, and one tile of each
## has to stay reached — a closure that would cut every one of them off is refused the same way one
## that would cut the calm off is, before it is accepted. The day's tree reaches every one of them
## (`RouteTree.for_day`) and every closure is placed off the tree, so like the calm half this is the
## second opinion rather than the thing that keeps it.
##
## **With today's fenced park closed as well** (`CityMap.fenced_park`, in `map.closed_tiles` from
## the repaint on): a street closure that leaves two areas reachable only through the one park that
## is actually fenced has left them unreachable. A merely-`shut_calm` area is not in `closed_tiles`
## — its ground stays open, so a street closure may still rely on a route through it.
static func _invariant_holds(map: CityMap, grid: ReachabilityGrid, areas: Array[CalmArea],
		today_closed: Dictionary, places: Array[Array] = []) -> bool:
	var blocked := _barrier_tiles(map, today_closed)
	blocked.merge(map.closed_tiles)
	var reached := grid.flood([_home_tile(map)], blocked)
	for place: Array in places:
		var place_reached := false
		for tile: Vector2i in place:
			if grid.reaches(tile, blocked, reached):
				place_reached = true
				break
		if not place_reached:
			return false
	var reachable := 0
	for area in areas:
		if _area_is_reached(map, grid, reached, blocked, area):
			reachable += 1
			if reachable >= Tuning.MIN_CALM_AREAS_REACHABLE:
				return true
	return false

## What `_invariant_holds` must still reach besides the calm: one set of tiles per destination the
## day sends her to, of which one tile has to stay reached — the candidate tiles of the day's
## narrow resistance target (`ResistanceSteps.narrow_target_on`) on days 9, 12 and the last night,
## whose target is the pavement in front of the power station's front door. The same pool
## `ResistanceDirector` draws the contact from (`ResistanceSteps.target_candidates`). Empty on
## every other day, and a pool with no tiles in it is left out rather than failing every closure:
## a day with nothing to send her to asks nothing of the closures about it.
static func places_to_reach_today(map: CityMap, day: int,
		region_plan: RegionPlanner.RegionPlan) -> Array[Array]:
	var places: Array[Array] = []
	var target := ResistanceSteps.target_candidates(ResistanceSteps.narrow_target_on(day), map,
			region_plan)
	if not target.is_empty():
		places.append(target)
	return places

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
##
## **A region's boundary is refused outright too, wall and door alike.** A closure on a wall segment
## is two things in one place; a closure on a door would close a crossing the region plan is
## supposed to keep open (or hold shut, on its own terms) regardless of what `ClosurePlanner` rolls.
static func _shuffled_candidates(map: CityMap, home: StreetNetwork.Segment, areas: Array[CalmArea],
		tree: RouteTree, region_plan: RegionPlanner.RegionPlan,
		rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
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
	var boundary := {}
	for segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment in region_plan.doors:
		boundary[segment.key()] = true
	var pool: Array[StreetNetwork.Segment] = []
	var weights: Array[float] = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if key == home.key() or not map.has_street(key) or tree.is_on_the_tree(key) \
				or access.has(key) or boundary.has(key):
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

## Weight `fallen_tree` is multiplied by on a street `StreetTrees` planted, on top of the gate
## below rather than instead of it. **The gate is what the player asked for and the weight is what
## keeps the kind visible**: tree-lined streets are a small fraction of the city, and a day closes
## between one and four streets, so a fallen tree offered at its plain 0.6 against roadworks and an
## accident would be a picture almost nobody ever meets. On a street that has trees, it is the
## likeliest thing to have happened.
const _FALLEN_TREE_STREET_BIAS := 6.0

## What closed this street. Weighted from the kinds the day has reached, so act I closes a
## street by accident and act IV closes it by bringing the building down.
##
## **`FALLEN_TREE` is offered only where a tree stood** — *(2026-09-11, the player: "fallen trees
## should only be possible on streets with trees and one spot should be empty (the fallen tree's
## spot)")*. A street with no trees on it drops the kind from the roll entirely rather than
## weighting it down, which is what makes the empty pit beside the wreck a promise rather than a
## coincidence. `RoadClosure.KINDS` always leaves `ROADWORKS` and `CRASH` available from day 1, so
## dropping this one can never leave a street with nothing to have happened to it.
static func _pick_kind(kinds: Array[int], rng: RandomNumberGenerator, street_has_trees: bool) -> int:
	var offered: Array[int] = []
	var weights: Array[float] = []
	for kind in kinds:
		if kind == RoadClosure.Kind.FALLEN_TREE and not street_has_trees:
			continue
		var weight := float(RoadClosure.KINDS[kind]["weight"])
		if kind == RoadClosure.Kind.FALLEN_TREE:
			weight *= _FALLEN_TREE_STREET_BIAS
		offered.append(kind)
		weights.append(weight)
	return offered[_pick_weighted(weights, rng)]
