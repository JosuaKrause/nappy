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
## **Atoms.** A calm area's access segments, a commercial square's own frontage, the home street,
## and a precinct span's own corridor are each unioned into one atom before growth, so no boundary
## segment ever borders calm ground or a square, is the home street, or cuts a precinct — by
## construction, the same way `SealPlanner` and `ClosurePlanner` already keep that ground whole
## rather than checking for a violation afterwards. A square is atomised for the same reason a calm
## area is and by the same mechanism (`_union_touch_points`): open, non-street ground that can
## border more than one street is exactly the shape of bypass the wall's mouth placement cannot
## see, whether or not the ground itself is calm.
##
## **An alley is not an atom; it is a second kind of crossing.** Unioning an alley's two bordering
## streets does not scale: an alley touches all four corners of its own block, so a city's worth of
## them chains into one atom spanning much of the lattice, which can degenerate the partition to a
## single region holding every calm area on an unlucky seed. See `ground_region_of` for what a
## crossing alley is instead.
##
## **Growth.** `Tuning.REGION_COUNT` seed junctions, spread by farthest-point sampling over the
## real-segment graph (`absent_segments` — both the zone-absorbed and the built-over kind — is
## never traversed, so a region can never grow across ground that is not there to cross), then a
## round-robin breadth-first flood: one step per region in turn, claiming a junction **and its
## whole atom** on every claim. The round-robin is what keeps the regions comparable in size
## rather than the first seed eating the map before the others start.
##
## **The wall stands at a boundary crossing's mouth, one tile deep, never its midpoint.** A segment
## has two mouths and the wall stands at one of them (`CityMap.boundary_wall_at_a`, decided at
## generation); an alley has two mouths and, when it is a crossing, both are walled. A midpoint
## band reaches roughly two tiles either way at the checkpoint row's own radius, wide enough to
## cover a nearby alley's mouth outright — the mouth is one tile deep and never bleeds sideways.
##
## **The wall is the day's, not `absent_segments`.** From `Tuning.REGION_WALL_FIRST_DAY`, every
## boundary crossing — a segment or a crossing alley — the day's tree uses is a **door**; every
## other one is **wall**. That is the whole rule: the tree wins. A region with no calm area
## therefore gets no doors on every day its own boundary is off the tree, which is every day unless
## the tree genuinely has to cross it to reach calm ground the milestone's own decree says a region
## edge may never affect — in which case the crossing is a door and the decree is why.
##
## **The main road is ordinary ground to the partition.** Nothing here excludes it: a boundary may
## cut it, and the checkpoint that results is the one place the milestone's gate over the roadway
## means anything.

## The catalogue row the wall's bodies are hard seals of: `roadblock`, the barrier that closes a
## street outright — renamed from `checkpoint` once the milestone's own door structure took that
## word for the passable one. **Whoever renames the row again updates this string in the same
## commit**, or the wall silently starts sealing nothing.
const _WALL_DEF_ID := "roadblock"

## The shared state of one checkpoint gate: its own ground point and whether the boom is up right
## now. Built once per street door in `_add_door_bodies`, held by the `checkpoint_gate` instance
## through `EventScheduler.Planned.gate_state` (which is what it draws raised or lowered from) and
## by `Crowd` through `RegionPlan.gates` (which is what actually raises and lowers it — see
## `Crowd._stop_for_gates()`). A `RefCounted` rather than two separate copies, so the two systems
## can never disagree about whether a boom is up.
class GateState extends RefCounted:
	## The gate's own ground point, in world space — the same position its `checkpoint_gate`
	## instance stands at, and what `Crowd` measures a car's distance from.
	var position := Vector2.ZERO
	## Whether the boom is up. `Crowd._stop_for_gates()` is the only writer; the instance only
	## reads it, once a frame, to choose which of the four boom textures to draw.
	var raised := false
	## Seconds the car at the front of this gate's queue has been held at the stop line —
	## `Crowd`'s own clock for `Tuning.GATE_STOP_SECONDS`, reset the moment nobody is held here.
	var stopped_for := 0.0

## One region growth's result: which crossings are wall today and which are doors, plus the
## bodies the wall and the doors stand as.
class RegionPlan extends RefCounted:
	## Boundary segments that are wall today — the whole day if before `Tuning.REGION_WALL_
	## FIRST_DAY`, since nothing is drawn before then.
	var walls: Array[StreetNetwork.Segment] = []
	## Boundary segments the day's tree crosses — a hut on each pavement and a gate over the road,
	## from `Tuning.REGION_WALL_FIRST_DAY`. See `door_bodies`.
	var doors: Array[StreetNetwork.Segment] = []
	## Through-alley rects that are **crossings** (`ground_region_of` differs at their two mouths)
	## and wall today — both mouths walled, the alley equivalent of `walls`.
	var alley_walls: Array[Rect2i] = []
	## Crossing alley rects the day's tree uses — a single guard at each of its two mouths, from
	## `Tuning.REGION_WALL_FIRST_DAY`. See `door_bodies`.
	var alley_doors: Array[Rect2i] = []
	## The wall's own bodies, as `EventScheduler.Planned` — hard seals of the roadblock row, one
	## tile deep at a boundary segment's mouth or an alley's two mouths. Kept as its own list,
	## appended to `EventManager._plans` by the caller, rather than merged anywhere: a caller that
	## only wants to know where the wall runs never has to filter it back out of the day's whole
	## plan.
	var wall_bodies: Array[EventScheduler.Planned] = []
	## The door structure's own bodies: two `checkpoint_hut`s and a `checkpoint_gate` at every
	## street door's mouth, one `checkpoint_post` at each mouth of every alley door. Kept apart
	## from `wall_bodies` for the same reason that list is kept apart from everything else — a
	## caller that wants the wall alone never has to filter the doors back out, and vice versa.
	var door_bodies: Array[EventScheduler.Planned] = []
	## One `GateState` per street door, in the same order as `doors` — `Crowd` reads this to know
	## where today's gates are and to raise and lower them; the `checkpoint_gate` `Planned` at the
	## same crossing carries the identical object. Empty for an alley door, which has no gate.
	var gates: Array[GateState] = []

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
	map.boundary_wall_at_a = _assign_wall_ends(map)

## Unions every atom's junctions together before growth, so a claim can never split one across a
## boundary. See the class doc, "Atoms".
##
## **An alley is not unioned into anything here.** Unioning all four corners of its own block, so
## its two bordering streets could never end up in different regions, would make every alley bridge
## whichever two calm areas its own block happens to sit between — a city's worth of alleys chains
## into one atom spanning most of the lattice, which can put every calm area in a single region on
## an unlucky seed. An alley is a second kind of **crossing** instead — see `ground_region_of` and
## `plan_day` — so it needs no atom of its own; a route through one is a boundary crossing like any
## other, decided the same way a segment's is.
static func _union_atoms(map: CityMap, dsu: _DSU) -> void:
	for area in ClosurePlanner.calm_areas(map):
		_union_touch_points(map, area.rect, dsu)
	# A commercial square is the same shape of problem a calm area is — open, non-street ground
	# that can border more than one street — and is not itself calm, so `ClosurePlanner.calm_areas`
	# never offers it. A square touching two streets the growth put in different regions is exactly
	# as unguarded a bypass as an unatomised calm area would be, since nothing about the wall's
	# mouth placement (see `ground_region_of`) stops a walk that never sets foot on the segment the
	# wall actually stands on.
	for rect in map.square_rects:
		_union_touch_points(map, rect, dsu)
	var home := ClosurePlanner.home_street(map)
	if home:
		dsu.union(StreetNetwork.node_of(home.a), StreetNetwork.node_of(home.b))
	for span: Vector4i in map.precinct_spans:
		var junctions := _precinct_span_junctions(span)
		for i in range(1, junctions.size()):
			dsu.union(StreetNetwork.node_of(junctions[0]), StreetNetwork.node_of(junctions[i]))

## Unions every junction `_area_touch_points(map, rect)` finds into one atom — a calm area's or a
## commercial square's own rect.
static func _union_touch_points(map: CityMap, rect: Rect2i, dsu: _DSU) -> void:
	var first := -1
	for pair in _area_touch_points(map, rect):
		for junction in pair:
			var node := StreetNetwork.node_of(junction)
			if first < 0:
				first = node
			else:
				dsu.union(first, node)

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
## `boundary_segments()` can even see.
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

## The two streets a through-alley's rect borders, as `[segment_a, segment_b, vertical]`, or an
## empty array when the alley is built over or either side falls outside the lattice entirely.
## **Either or both may be absent** — a hard blocker can take either side independently of the
## alley — so a caller that needs a real street on both sides (`_assign_wall_ends`'s own nudge)
## checks `map.has_street()` itself; a caller asking what ground a mouth touches wants
## `alley_mouth_ground_region` instead, which already knows what to do with an absent one.
static func _alley_border_segments(map: CityMap, rect: Rect2i) -> Array:
	if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
		return []
	var vertical := rect.size.x < rect.size.y
	var block := map.block_at(map.tile_rect_to_world(rect).get_center())
	var side_a: int = StreetNetwork.Side.NORTH if vertical else StreetNetwork.Side.WEST
	var side_b: int = StreetNetwork.Side.SOUTH if vertical else StreetNetwork.Side.EAST
	var segment_a := StreetNetwork.beside_block(block, side_a)
	var segment_b := StreetNetwork.beside_block(block, side_b)
	if not segment_a or not segment_b:
		return []
	return [segment_a, segment_b, vertical]

## The region the ground at one of an alley's mouths belongs to — `ground_region_of` for a real
## bordering street, and a dead end's or a big building's own surviving stub read directly for an
## absent one. **Without the second half, a dead-end-adjacent alley is invisible to the crossing
## machinery and can bridge two regions the wall never learns to guard**: `beside_block` still
## names the absent segment and `_alley_border_segments` still returns it, but a caller that only
## asks `ground_region_of` never learns what region its own still-walkable ground belongs to.
## `-1` when neither end is unambiguously the open one (a big building leaves
## no stub at all; the two are told apart by which single end, if either, is still walkable) — an
## alley that cannot be read this way is left to the ordinary M64 sealing pass, exactly as one with
## fewer than two bordering streets already was.
static func alley_mouth_ground_region(map: CityMap, segment: StreetNetwork.Segment) -> int:
	if map.has_street(segment.key()):
		return ground_region_of(map, segment)
	return _dead_end_ground_region(map, segment)

## Which region a dead end's (or a big building's) own street reaches, read off the one end that
## is still walkable — the near tile of each end says which, since a dead end builds over only the
## *far* one and a big building takes both, leaving neither walkable at all.
static func _dead_end_ground_region(map: CityMap, segment: StreetNetwork.Segment) -> int:
	var rect := segment.tile_rect()
	var near_a: Vector2i
	var near_b: Vector2i
	if segment.horizontal:
		var mid_y := rect.position.y + rect.size.y / 2
		near_a = Vector2i(rect.position.x, mid_y)
		near_b = Vector2i(rect.end.x - 1, mid_y)
	else:
		var mid_x := rect.position.x + rect.size.x / 2
		near_a = Vector2i(mid_x, rect.position.y)
		near_b = Vector2i(mid_x, rect.end.y - 1)
	var a_open := map.is_walkable(near_a)
	var b_open := map.is_walkable(near_b)
	if a_open and not b_open:
		return region_of_junction(map, segment.a)
	if b_open and not a_open:
		return region_of_junction(map, segment.b)
	return -1

## Which end of every boundary segment carries the wall, keyed by segment key: `true` for `a`.
## Default is deterministic and arbitrary — the lower region id's end — then a greedy pass over
## alleys nudges it so that as few through-alleys as possible end up as crossings, per the
## milestone's own words. See `ground_region_of` for how this is read back.
##
## **The pass is greedy and never repairs a conflict.** An alley demanding a ground a previous
## alley already set differently for the same segment leaves that segment at its default rather
## than fighting over it — `_demand` records the conflict once and every later demand for that
## segment is then ignored, so the order alleys are visited in never has to be undone.
static func _assign_wall_ends(map: CityMap) -> Dictionary:
	var wall_at_a := {}
	for segment in boundary_segments(map):
		var ra := region_of_junction(map, segment.a)
		var rb := region_of_junction(map, segment.b)
		wall_at_a[segment.key()] = ra < rb
	var demanded := {}
	for rect in map.alley_rects:
		var info := _alley_border_segments(map, rect)
		if info.is_empty():
			continue
		var segment_a: StreetNetwork.Segment = info[0]
		var segment_b: StreetNetwork.Segment = info[1]
		if not map.has_street(segment_a.key()) or not map.has_street(segment_b.key()):
			continue   # nothing to nudge without a real street on both sides to compare
		var a_region := region_of_segment(map, segment_a)
		var b_region := region_of_segment(map, segment_b)
		if a_region >= 0 and b_region >= 0:
			continue   # both interior; nothing to nudge, and no crossing either
		if a_region >= 0 and b_region < 0:
			_demand_ground(demanded, segment_b, a_region)
		elif b_region >= 0 and a_region < 0:
			_demand_ground(demanded, segment_a, b_region)
		else:
			# Both boundary segments: if their four ends share one region, that region is the
			# alley's own side and both segments' ground is set to it, so the alley opens onto the
			# same ground from either bordering street and is never a crossing.
			var a_ends := [region_of_junction(map, segment_a.a), region_of_junction(map, segment_a.b)]
			var b_ends := [region_of_junction(map, segment_b.a), region_of_junction(map, segment_b.b)]
			var shared := -1
			for r in a_ends:
				if b_ends.has(r):
					shared = r
					break
			if shared < 0:
				continue
			_demand_ground(demanded, segment_a, shared)
			_demand_ground(demanded, segment_b, shared)
	for key: Vector3i in demanded:
		var wanted: int = demanded[key]
		if wanted < 0:
			continue   # a conflict was recorded; keep the default
		var segment := StreetNetwork.by_key(key)
		var ra := region_of_junction(map, segment.a)
		var rb := region_of_junction(map, segment.b)
		if ra == wanted:
			wall_at_a[key] = false   # wall at b, ground (the far end) is a
		elif rb == wanted:
			wall_at_a[key] = true    # wall at a, ground (the far end) is b
	return wall_at_a

## Records that `segment`'s ground should be `region`, or marks it a conflict (`-1`) if an earlier
## demand for the same segment wanted a different one — see `_assign_wall_ends`'s own doc.
static func _demand_ground(demanded: Dictionary, segment: StreetNetwork.Segment,
		region: int) -> void:
	var key := segment.key()
	if not demanded.has(key):
		demanded[key] = region
	elif demanded[key] != region:
		demanded[key] = -1

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

## The region a segment's whole **ground** belongs to — the question the wall's mouth placement
## makes meaningful where `region_of_segment` cannot answer at all. An interior segment's ground is
## simply its own region, the same answer either function gives. A boundary segment's wall stands
## one tile deep at one mouth (`CityMap.boundary_wall_at_a`), so the rest of its length — right up
## to that one-tile band — is walkable from the **far** end and unreachable from the near one; this
## returns the far end's region. `-1` for an absent segment, same as `region_of_segment`.
##
## This is also what a through-alley's two mouths are compared against to decide whether it is a
## **crossing**: `plan_day` calls this on the real street at each end, and the alley is a crossing
## exactly when the two answers differ.
static func ground_region_of(map: CityMap, segment: StreetNetwork.Segment) -> int:
	if not segment or not map.has_street(segment.key()):
		return -1
	var ra := region_of_junction(map, segment.a)
	var rb := region_of_junction(map, segment.b)
	if ra == rb:
		return ra
	var wall_at_a: bool = map.boundary_wall_at_a.get(segment.key(), ra < rb)
	return rb if wall_at_a else ra

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
## **From it on, a boundary crossing — a segment or a crossing alley — is a door if the day's tree
## uses it and wall otherwise. The tree wins, unconditionally, over anything the partition alone
## would say.** Forcing a wall onto a calm-less region's own boundary regardless of the tree, on the
## reasoning that there is no reason to ever enter a region with nothing in it, breaks the
## milestone's own decree that a region edge may never affect a path — a segment the tree is
## actually using would turn into a wall it did not expect. **A region with no calm area still gets
## no doors on every day its own boundary happens to be off the tree** — which is every day unless
## the tree has a genuine reason to cross it, and on that day the reason wins, because the decree
## that a region edge never affects a path is the stronger rule and this is what obeying it looks
## like.
##
## No exemption for the home region is needed here either, for the same reason: home's own boundary
## was never a case the tree-wins rule could get wrong, since the tree door/wall answer only depends
## on the tree, never on which regions are calm-less. `tests/test_regions.gd` restates "the home
## region has a door, or every calm area the tree reaches is in the home region" as the
## unconditional sentence it always was rather than working around a rule that no longer exists.
static func plan_day(map: CityMap, day: int, tree: RouteTree) -> RegionPlan:
	var plan := RegionPlan.new()
	if day < Tuning.REGION_WALL_FIRST_DAY or not tree:
		return plan
	for segment in boundary_segments(map):
		if tree.is_on_the_tree(segment.key()):
			plan.doors.append(segment)
		else:
			plan.walls.append(segment)
	for rect in map.alley_rects:
		var info := _alley_border_segments(map, rect)
		if info.is_empty():
			continue
		var ground_a := alley_mouth_ground_region(map, info[0])
		var ground_b := alley_mouth_ground_region(map, info[1])
		if ground_a < 0 or ground_b < 0 or ground_a == ground_b:
			continue   # not a (detectable) crossing; the ordinary M64 sealing pass handles it
		var on_tree := false
		for tile in map.rect_tiles(rect):
			if not tree.branches_on(tile).is_empty():
				on_tree = true
				break
		if on_tree:
			plan.alley_doors.append(rect)
		else:
			plan.alley_walls.append(rect)
	for segment in plan.walls:
		var default_at_a := region_of_junction(map, segment.a) < region_of_junction(map, segment.b)
		var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
		plan.wall_bodies.append_array(SealPlanner.place_hard_on(map, segment, _WALL_DEF_ID, at_a))
	for rect in plan.alley_walls:
		var info := _alley_border_segments(map, rect)
		if info.is_empty():
			continue
		var vertical: bool = info[2]
		plan.wall_bodies.append(SealPlanner.alley_mouth_wall(map, rect, vertical, true, _WALL_DEF_ID))
		plan.wall_bodies.append(SealPlanner.alley_mouth_wall(map, rect, vertical, false, _WALL_DEF_ID))
	for segment in plan.doors:
		_add_door_bodies(map, segment, plan)
	for rect in plan.alley_doors:
		_add_alley_door_bodies(map, rect, plan)
	return plan

## The along-street axis a door's own bodies share: `RIGHT` for a segment/alley that runs
## east-west (`horizontal`), `DOWN` for one that runs north-south. Carried on every door body's own
## `Planned.facing`, which is what lets a stationary instance answer "which side of the crossing is
## she on" without a second lookup — see `EventManager`'s detention teleport.
static func _along_axis(horizontal: bool) -> Vector2:
	return Vector2.RIGHT if horizontal else Vector2.DOWN

## The three bodies a street door stands at its mouth: a `checkpoint_hut` on each pavement lane and
## a `checkpoint_gate` on the road between them — the same three positions `place_hard_on` would
## give the wall, `SealPlanner.positions_across` at `Tuning.TILE_SIZE`, which comes out at three
## across the street's own `STREET_WIDTH` (sidewalk, road, sidewalk, each exactly two tiles).
##
## `sealed_variant(..., true)` is what keeps `EventInstance.setup()`'s pavement auto-centring from
## re-deriving a position these three already sit exactly on — see that function's own doc on why a
## continuous, non-tile-aligned position disagrees with what the recentring assumes.
static func _add_door_bodies(map: CityMap, segment: StreetNetwork.Segment, plan: RegionPlan) -> void:
	var default_at_a := region_of_junction(map, segment.a) < region_of_junction(map, segment.b)
	var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
	var world := map.tile_rect_to_world(segment.mouth_rect(at_a))
	var positions := SealPlanner.positions_across(world, segment.horizontal, Tuning.TILE_SIZE)
	if positions.is_empty():
		return
	var axis := _along_axis(segment.horizontal)
	var road_index := positions.size() / 2
	var gate := GateState.new()
	gate.position = positions[road_index]
	plan.gates.append(gate)
	for i in positions.size():
		var def_id := "checkpoint_gate" if i == road_index else "checkpoint_hut"
		var def := SealPlanner.sealed_variant(EventCatalogue.by_id(def_id), true)
		var body := EventScheduler.Planned.new(def, positions[i])
		body.facing = axis
		if i == road_index:
			body.gate_state = gate
		plan.door_bodies.append(body)

## The two bodies an alley door stands, one `checkpoint_post` at each of its two mouths — the same
## mouths `_seal_alley_mouths` would wall, read through the same `SealPlanner.alley_mouth_rect` a
## wall's own crossing-alley bodies use.
static func _add_alley_door_bodies(map: CityMap, rect: Rect2i, plan: RegionPlan) -> void:
	var vertical := rect.size.x < rect.size.y
	var axis := _along_axis(not vertical)
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("checkpoint_post"), true)
	for at_start in [true, false]:
		var mouth := SealPlanner.alley_mouth_rect(rect, vertical, at_start)
		var body := EventScheduler.Planned.new(def, map.tile_rect_to_world(mouth).get_center())
		body.facing = axis
		plan.door_bodies.append(body)

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
