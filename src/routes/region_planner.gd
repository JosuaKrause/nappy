class_name RegionPlanner
extends RefCounted
## Partitions the lattice's junctions into `Tuning.REGION_COUNT` regions, once per run, and turns
## that partition plus a day's `RouteTree` into which boundary segments are wall and which are
## door. See `docs/TODO.md`, M62, "The draft answer to what a region is" and "The concrete form
## the build takes" — this class is that design made exact.
##
## **A region is a set of junctions, and a segment follows its two ends.** Every junction belongs
## to exactly one region (`assign`, called once at generation and stored on `CityMap`). A segment
## whose two ends share a region is that region's interior; one whose ends differ is a **boundary
## segment**, and a route crosses from one region to another if and only if it walks one. That is
## `is_on_the_tree()` and `region_of_junction` disagreeing at a segment's two ends — one lookup,
## not a search.
##
## **Regions are orthogonal to path planning, by decree.** `RouteTree` is grown with no knowledge
## of regions and the partition is decided before any day's tree exists, so there is no ordering
## problem and no case where the wall makes a route worse — see the milestone's own "a region edge
## can never affect a path". `plan_day` only ever reads a finished tree; it never feeds back into
## growing one.
##
## **Atoms.** A calm area's access segments, a through-alley's two segments, the home street, and
## a precinct span's own corridor are each unioned into one atom before growth, so no boundary
## segment ever borders calm ground, crosses an alley, is the home street, or cuts a precinct — by
## construction, the same way `SealPlanner` and `ClosurePlanner` already keep those four kinds of
## ground whole rather than checking for a violation afterwards.
##
## **Growth.** `Tuning.REGION_COUNT` seed junctions, spread by farthest-point sampling over the
## real-segment graph (`absent_segments` — both the zone-absorbed and the built-over kind — is
## never traversed, so a region can never grow across ground that is not there to cross), then a
## round-robin breadth-first flood: one step per region in turn, claiming a junction **and its
## whole atom** on every claim. The round-robin is what keeps the regions comparable in size
## rather than the first seed eating the map before the others start.
##
## **The wall is the day's, not `absent_segments`.** From `Tuning.REGION_WALL_FIRST_DAY` a boundary
## segment the day's tree uses is a door; every other boundary segment is wall — refined by two
## rules stated in the class doc of `plan_day`.
##
## **The main road is ordinary ground to the partition.** Nothing here excludes it: a boundary may
## cut it, and the checkpoint that results is the one place the milestone's gate over the roadway
## means anything.

## How many regions the lattice's junctions are partitioned into. Four, the milestone's own
## recommendation: two is a single dividing line and eight or nine — one per calm area — puts most
## of the lattice's 264 segments behind a wall and never lets "a region with no calm area gets no
## doors" fire, since almost every region would have exactly one.
const _WALL_DEF_ID := "checkpoint"

## One region growth's result: which region a segment's boundary status resolves to, and the
## day's wall/door split built from it.
class RegionPlan extends RefCounted:
	## Boundary segments that are wall today — the whole day if before `Tuning.REGION_WALL_
	## FIRST_DAY`, since nothing is drawn before then.
	var walls: Array[StreetNetwork.Segment] = []
	## Boundary segments the day's tree crosses — an open segment, structure-free in this half of
	## the build. The second agent places the hut, the gate and the guards here.
	var doors: Array[StreetNetwork.Segment] = []
	## The wall's own bodies, as `EventScheduler.Planned` — hard seals of the `checkpoint` row,
	## edge to edge across each wall segment's midpoint. Kept as its own list, appended to
	## `EventManager._plans` by the caller, rather than merged anywhere: a caller that only wants
	## to know where the wall runs never has to filter it back out of the day's whole plan.
	var wall_bodies: Array[EventScheduler.Planned] = []

# ------------------------------------------------------------------- generation ---

## Assigns every junction to a region and stores the result on `map` — `region_of_junction`,
## `region_has_calm`. Called once, at generation, after hard blockers have taken their streets
## (`CityGenerator._assign_regions`): a region may not grow across ground a dead end or a big
## building just built over, and `absent_segments` only carries that once the blockers are placed.
##
## `rng` seeds only the farthest-point sample's starting junction — everything after that is
## deterministic BFS — and it is the caller's own stream, seeded from the map's seed rather than
## the shared generation RNG, the same trick `CityGenerator._assign_street_kinds` uses so that
## adding regions moves nothing else a seed already decided.
static func assign(map: CityMap, rng: RandomNumberGenerator) -> void:
	var total := StreetNetwork.node_total()
	var dsu := _DSU.new(total)
	_union_atoms(map, dsu)
	var adjacency := _growth_graph(map)
	var real: Array[int] = []
	for node in total:
		if not (adjacency[node] as Array).is_empty():
			real.append(node)
	var seeds := _pick_seeds(adjacency, real, dsu, rng)
	map.region_of_junction = _grow_regions(total, adjacency, dsu, seeds)
	map.region_has_calm = _compute_region_has_calm(map, map.region_of_junction)

## Unions every atom's junctions together before growth, so a claim can never split one across a
## boundary. See the class doc, "Atoms".
static func _union_atoms(map: CityMap, dsu: _DSU) -> void:
	for area in ClosurePlanner.calm_areas(map):
		var first := -1
		for pair in _area_touch_points(map, area.rect):
			for junction in pair:
				var node := StreetNetwork.node_of(junction)
				if first < 0:
					first = node
				else:
					dsu.union(first, node)
	var home := ClosurePlanner.home_street(map)
	if home:
		dsu.union(StreetNetwork.node_of(home.a), StreetNetwork.node_of(home.b))
	for rect in map.alley_rects:
		# A through-alley can be built over by a later generation pass, which does not retract it
		# from `alley_rects` — the same check `SealPlanner._seal_alley_mouths` makes for the same
		# reason: the ground is checked rather than trusted.
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		# `_area_touch_points`, not a direct `beside_block` at each of the alley's two sides: a hard
		# blocker can take either of them independently of the alley itself, and its still-walkable
		# stub then needs the same treatment a calm area's own stub-adjacency does — see that
		# function's doc. An alley is two tiles wide and one block long, so this walk from its own
		# rect finds exactly its two bordering streets when both are real, the ordinary case.
		var first := -1
		for pair in _area_touch_points(map, rect):
			for junction in pair:
				var node := StreetNetwork.node_of(junction)
				if first < 0:
					first = node
				else:
					dsu.union(first, node)
	for span: Vector4i in map.precinct_spans:
		var junctions := _precinct_span_junctions(span)
		for i in range(1, junctions.size()):
			dsu.union(StreetNetwork.node_of(junctions[0]), StreetNetwork.node_of(junctions[i]))

## Every segment `area`'s own walkable buffer touches, real or not, as `[junction, junction]`
## pairs to union — `ClosurePlanner.calm_areas().access` is not enough on its own.
##
## **A calm area can be tile-adjacent to a dead end's still-open stub.** `ClosurePlanner.
## _access_segments` walks past an absent segment without recording it, because for *closure*
## planning a street that is not there is simply not a way in. But a dead end only builds over
## the *far* end of its street (`docs/CITY.md`, "Hard blockers": "one street, gone from the
## lattice, with one end built over") — the near stub stays ordinary, walkable sidewalk, so a
## courtyard beside it is tile-connected to that stub's own surviving junction exactly the way it
## is connected to a real access street. Two dead ends either side of the same calm ground would
## otherwise each keep their own near junction out of the atom, and if growth ever put those two
## junctions in different regions, the calm ground between their stubs becomes a walkable bypass no
## boundary segment was ever placed to guard, because neither dead end is a real segment
## `boundary_segments()` can even see. Found by the flood-over-cells test in `tests/test_regions.gd`
## rather than reasoned out in advance — the exact class of bug that check exists to catch.
##
## Same walk `_access_segments` uses — flood the area's own tiles outward through non-street
## ground — except every segment the walk meets is recorded (its own two junctions, to union
## together) and only a **real** one stops the walk in that direction; an absent one is walked
## through, the same as `_access_segments` does, so a stub two dead ends deep is still covered.
static func _area_touch_points(map: CityMap, rect: Rect2i) -> Array:
	var found: Array = []
	var seen_keys := {}
	var visited := {}
	for tile in map.rect_tiles(rect):
		visited[tile] = true
	var queue: Array[Vector2i] = []
	for tile in map.rect_tiles(rect):
		ClosurePlanner._queue_walkable_neighbours(map, tile, visited, queue)
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		var segment := StreetNetwork.segment_containing(tile)
		if segment:
			if not seen_keys.has(segment.key()):
				seen_keys[segment.key()] = true
				found.append([segment.a, segment.b])
			if map.has_street(segment.key()):
				continue
		ClosurePlanner._queue_walkable_neighbours(map, tile, visited, queue)
	return found

## Every junction along a precinct span's own corridor, first block to last block inclusive —
## `length + 1` of them for a `length`-block span. `span` is `(axis, corridor, first block, last
## block)`; `axis == 1` runs the span along y at a fixed x (`corridor`), `axis == 0` along x at a
## fixed y. See `CityMap.precinct_spans`.
static func _precinct_span_junctions(span: Vector4i) -> Array[Vector2i]:
	var junctions: Array[Vector2i] = []
	var corridor := span.y
	if span.x == 1:
		for y in range(span.z, span.w + 2):
			junctions.append(Vector2i(corridor, y))
	else:
		for x in range(span.z, span.w + 2):
			junctions.append(Vector2i(x, corridor))
	return junctions

## Junction adjacency over real segments only — `absent_segments` is never traversed, so a region
## can never grow across ground that is not there to cross. Built fresh per call: this only ever
## runs once per city, at generation, so caching it the way `StreetNetwork._links()` caches the
## full lattice would save nothing.
static func _growth_graph(map: CityMap) -> Array:
	var total := StreetNetwork.node_total()
	var adjacency: Array = []
	adjacency.resize(total)
	for i in total:
		adjacency[i] = []
	for segment in StreetNetwork.segments():
		if not map.has_street(segment.key()):
			continue
		var u := StreetNetwork.node_of(segment.a)
		var v := StreetNetwork.node_of(segment.b)
		(adjacency[u] as Array).append(v)
		(adjacency[v] as Array).append(u)
	return adjacency

static func _bfs_distances(adjacency: Array, source: int) -> PackedInt32Array:
	var total := adjacency.size()
	var dist := PackedInt32Array()
	dist.resize(total)
	dist.fill(-1)
	dist[source] = 0
	var queue: Array[int] = [source]
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		for neighbour: int in adjacency[node]:
			if dist[neighbour] < 0:
				dist[neighbour] = dist[node] + 1
				queue.append(neighbour)
	return dist

## `Tuning.REGION_COUNT` seed junctions spread out by farthest-point sampling over graph distance:
## the first is rolled from `rng`, and every one after it is whichever real junction is furthest
## (by BFS hops) from every seed chosen so far. `rng` decides only the first choice; the rest is
## deterministic given it, which is what "seeded from an RNG of its own" buys — the growth itself
## has nothing left to roll.
##
## **Never two seeds in the same atom.** Sampling only knows graph distance, not atoms, and a
## large atom (a four-block calm zone's access streets, say) can span enough of the lattice that
## two farthest-apart junctions still land in it together. A region whose own seed's atom was
## already claimed by an earlier seed never gets to start growing at all — `dsu` is threaded
## through here so a candidate already sharing a chosen seed's atom is passed over.
static func _pick_seeds(adjacency: Array, real: Array[int], dsu: _DSU,
		rng: RandomNumberGenerator) -> Array[int]:
	var seeds: Array[int] = []
	if real.is_empty():
		return seeds
	var used_roots := {}
	var first: int = real[rng.randi_range(0, real.size() - 1)]
	seeds.append(first)
	used_roots[dsu.find(first)] = true
	var min_dist := _bfs_distances(adjacency, first)
	while seeds.size() < Tuning.REGION_COUNT and seeds.size() < real.size():
		var best := -1
		var best_dist := -1
		for node in real:
			if used_roots.has(dsu.find(node)):
				continue
			var d: int = min_dist[node]
			if d > best_dist:
				best_dist = d
				best = node
		if best < 0:
			break
		seeds.append(best)
		used_roots[dsu.find(best)] = true
		var next_dist := _bfs_distances(adjacency, best)
		for node in real:
			if next_dist[node] >= 0 and (min_dist[node] < 0 or next_dist[node] < min_dist[node]):
				min_dist[node] = next_dist[node]
	return seeds

## The round-robin flood: one step per region in turn, claiming a junction and its whole atom on
## every claim. A junction with no real segment at all is never reached — its adjacency list is
## empty, so it never enters any region's frontier — and is left at `-1`, region-less; nothing
## downstream ever asks a segment-free junction a region question, since a boundary segment always
## has a real segment on both its ends.
##
## **The claim is written inline in both places it happens, rather than factored into a shared
## function that takes `region_of` as a parameter.** `PackedInt32Array` copies on write: passing
## one into a function and writing through the parameter there diverges a private copy inside the
## call, leaving the caller's own array silently unmodified. Keeping every write to `region_of`
## inside this one function's local scope is what avoids the trap rather than merely happening not
## to trigger it — see `.claude/skills/godot/SKILL.md`, "Types".
static func _grow_regions(total: int, adjacency: Array, dsu: _DSU, seeds: Array[int]) -> PackedInt32Array:
	var region_of := PackedInt32Array()
	region_of.resize(total)
	region_of.fill(-1)
	var members := {}
	for node in total:
		var root := dsu.find(node)
		if not members.has(root):
			members[root] = []
		(members[root] as Array).append(node)

	var frontiers: Array = []
	for i in seeds.size():
		frontiers.append([])

	# Every seed's whole atom is claimed before the round-robin starts, so an atom that happens to
	# contain two seeds — possible only on a small or oddly shaped lattice — is settled by seed
	# order rather than by which region's turn happens to come first below.
	for r in seeds.size():
		var seed_node: int = seeds[r]
		if region_of[seed_node] >= 0:
			continue
		var root := dsu.find(seed_node)
		for member: int in members.get(root, [seed_node]):
			if region_of[member] < 0:
				region_of[member] = r
				(frontiers[r] as Array).append(member)

	var active := true
	while active:
		active = false
		for r in seeds.size():
			var queue: Array = frontiers[r]
			if queue.is_empty():
				continue
			active = true
			var node: int = queue.pop_front()
			for neighbour: int in adjacency[node]:
				if region_of[neighbour] >= 0:
					continue
				var root := dsu.find(neighbour)
				for member: int in members.get(root, [neighbour]):
					if region_of[member] < 0:
						region_of[member] = r
						queue.append(member)
	return region_of

## Which regions hold a calm area, decided once at generation from that morning's calm ground
## (`ClosurePlanner.calm_areas`, read at the same point in `_attempt` that placed it) — see the
## class doc on why this is a generation-time fact and not a per-day one.
static func _compute_region_has_calm(map: CityMap, region_of: PackedInt32Array) -> PackedByteArray:
	var flags := PackedByteArray()
	flags.resize(Tuning.REGION_COUNT)
	for area in ClosurePlanner.calm_areas(map):
		if area.access.is_empty():
			continue
		var node := StreetNetwork.node_of(area.access[0].a)
		if node < 0 or node >= region_of.size():
			continue
		var region: int = region_of[node]
		if region >= 0 and region < flags.size():
			flags[region] = 1
	return flags

# ------------------------------------------------------------------------ queries ---

## The region a junction belongs to, or `-1` for one out of bounds or never claimed (no real
## segment touches it at all).
static func region_of_junction(map: CityMap, junction: Vector2i) -> int:
	if not StreetNetwork.in_bounds(junction):
		return -1
	var node := StreetNetwork.node_of(junction)
	if node < 0 or node >= map.region_of_junction.size():
		return -1
	return map.region_of_junction[node]

## The region a segment belongs to when both its ends agree, or `-1` when it is absent from the
## lattice or is itself a boundary segment. Never confuse the two `-1`s without checking
## `map.has_street()` first — `boundary_segments()` already only ever offers real ones.
static func region_of_segment(map: CityMap, segment: StreetNetwork.Segment) -> int:
	if not segment or not map.has_street(segment.key()):
		return -1
	var ra := region_of_junction(map, segment.a)
	var rb := region_of_junction(map, segment.b)
	return ra if ra == rb else -1

## Every real segment whose two ends disagree about their region — the wall, permanent for the
## run and independent of any day's tree.
static func boundary_segments(map: CityMap) -> Array[StreetNetwork.Segment]:
	var found: Array[StreetNetwork.Segment] = []
	for segment in StreetNetwork.segments():
		if not map.has_street(segment.key()):
			continue
		if region_of_junction(map, segment.a) != region_of_junction(map, segment.b):
			found.append(segment)
	return found

## Which regions hold a calm area — the generation-time fact `assign()` stored on `map`, wrapped
## here so a caller never reaches into the map's field directly.
static func regions_with_calm(map: CityMap) -> PackedByteArray:
	return map.region_has_calm

## The region the home street's own two junctions belong to. Never `-1` in practice: the home
## street's atom unions its two junctions before growth, so they always resolve to one region
## together, the same way any other atom does.
static func home_region(map: CityMap) -> int:
	var home := ClosurePlanner.home_street(map)
	if not home:
		return -1
	return region_of_segment(map, home)

# --------------------------------------------------------------------------- the day ---

## The day's wall and doors, built from the permanent partition and today's `RouteTree`.
##
## **Before `Tuning.REGION_WALL_FIRST_DAY`, nothing is drawn.** The regions exist from generation,
## but the milestone's own words are "checkpoints in the later acts" — returns an empty plan.
##
## **From it on, every boundary segment is a door if the day's tree crosses it and wall
## otherwise** — refined by one rule, applied per segment from each of its two sides:
##
## - **A region with no calm area gets no doors at all**, except the region the home street is
##   in, which always keeps its doors whatever the tree does. A segment touching a no-calm,
##   non-home region on one side is forced to wall regardless of the other side, overriding what
##   the tree would otherwise have made it — the tree is not expected to ever reach such a region
##   (there is nothing there for it to grow toward), so this rarely has anything to override; see
##   the milestone report for whether it ever did across the sweep it was measured on.
##
## **A segment that touches the home region on either side is never forced**, whatever the other
## side is — that is the whole of what "the region she starts in always has doors" buys, read
## literally rather than only as "home is not itself treated as a no-calm region". On a seed where
## almost every calm area happens to land in the home region's own atom, every other region can be
## genuinely calm-less at once, and if home's own exits were still subject to the rule on the far
## side, she could be sealed into her own region with no door out of it at all — a wall standing
## with nothing behind it to open. Exempting the home side of every one of its own boundary
## segments is what keeps that from happening: those segments fall through to the ordinary
## tree rule, door if the tree crosses them and wall otherwise, the same as any other segment
## touching a region that does hold calm.
##
## The home region's own "always keeps its doors" is not enforced by adding one — that would be
## exactly the repair pass `CLAUDE.md` warns against, resting a guarantee on code nothing checks.
## It holds because the tree always reaches *some* calm area and the home region's own boundary is
## never force-walled, so if that area lies outside the home region the branch reaching it has to
## cross one of the home region's own boundary segments, which is then a door by the ordinary
## rule. `tests/test_regions.gd` checks the sentence rather than assuming the mechanism — and
## states the premise the argument above actually rests on: *if some other region holds calm at
## all.* Where every calm area a city will ever have landed in the home region's own atom (found on
## the sweep this suite runs, once), the tree has nothing outside home to grow toward, and a
## boundary can stand with no door in it without contradicting anything above — the argument's own
## premise never held. This is a property of a specific seed's atoms rather than a repair the
## code could make; see the milestone report for how often it was seen.
static func plan_day(map: CityMap, day: int, tree: RouteTree) -> RegionPlan:
	var plan := RegionPlan.new()
	if day < Tuning.REGION_WALL_FIRST_DAY or not tree:
		return plan
	var calm := regions_with_calm(map)
	var home := home_region(map)
	for segment in boundary_segments(map):
		var ra := region_of_junction(map, segment.a)
		var rb := region_of_junction(map, segment.b)
		var touches_home := ra == home or rb == home
		if not touches_home and (_forces_wall(ra, calm) or _forces_wall(rb, calm)):
			plan.walls.append(segment)
		elif tree.is_on_the_tree(segment.key()):
			plan.doors.append(segment)
		else:
			plan.walls.append(segment)
	for segment in plan.walls:
		plan.wall_bodies.append_array(SealPlanner.place_hard_on(map, segment, _WALL_DEF_ID))
	return plan

## Whether `region` is a genuine reason to force a wall — real and holding no calm area. The
## caller decides the home exemption itself (`plan_day`'s own `touches_home` guard), because that
## exemption is about the *segment*, not the region: a segment touching home is never forced even
## when its far side is a calm-less region, so home cannot be checked here in isolation.
static func _forces_wall(region: int, calm: PackedByteArray) -> bool:
	if region < 0:
		return false
	return region >= calm.size() or calm[region] == 0

# --------------------------------------------------------------------------------- dsu ---

## Union-find over junction node ids, for grouping atoms before growth. A plain `RefCounted`
## rather than free functions over a passed-in `PackedInt32Array`, so mutation through `find`'s
## path compression is never in question — a `PackedInt32Array` argument can copy on write across
## a call boundary, and a DSU that silently stopped compressing its caller's array would still
## look correct while doing needless work forever.
class _DSU extends RefCounted:
	var parent: PackedInt32Array

	func _init(count: int) -> void:
		parent = PackedInt32Array()
		parent.resize(count)
		for i in count:
			parent[i] = i

	func find(x: int) -> int:
		var root := x
		while parent[root] != root:
			root = parent[root]
		var at := x
		while parent[at] != root:
			var next: int = parent[at]
			parent[at] = root
			at = next
		return root

	func union(a: int, b: int) -> void:
		var ra := find(a)
		var rb := find(b)
		if ra != rb:
			parent[ra] = rb
