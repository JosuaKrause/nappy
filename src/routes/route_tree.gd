class_name RouteTree
extends RefCounted
## The day's corridor: one branch from the doorstep to every calm area still worth reaching.
##
## The design is docs/CITY.md, "Diversions — the design" and "How the corridor is built", and
## docs/TODO.md, M69, "The day's route tree moves onto the grid too".
##
## **The city permits routes to calm and protects them from becoming impossible. It never
## suggests one.** This is the structure that lets it suggest one: a *wall* is a street just
## outside a branch, *friction* is a street on one, and a *set piece* is sited so that every
## branch touches one of its candidates. None of those three words means anything until there
## is a tree to be inside or outside of.
##
## **It is a tree on purpose, and not a bundle of shortest paths.** *"Don't take the strictly
## shortest path. Aim for paths that share prefixes. The paths to some calm zones might not be
## optimal or short but that is okay."* Independent shortest paths to five calm areas are a
## **star** — five rays out of the doorstep sharing almost nothing — and a star has no bundles,
## no chokepoints and a fan-out equal to the number of destinations. Everything placement
## depends on comes from the sharing, so the sharing is what the construction is for rather
## than something it is allowed to lose.
##
## The growth runs **backwards**, from every destination toward the doorstep, and the trunk is
## what is left where the branches have come together:
##
## - **Two probes at each calm area.** The first is a loop-erased random walk toward home; the
##   second is the shortest way left once the first one's ground is spent.
## - **A path carries the colour of its area**, and both probes from one area carry the same one.
## - **Same colours may not merge**, so where a second route exists at all the area is reached two
##   genuinely distinct ways.
## - **Different colours merge, and the colours add up.** A probe that touches a differently
##   coloured path joins it and the joined stretch carries both. Which is the elegant half: once
##   the `A`+`B` stretch exists, `A`'s other probe is locked out of it by the rule above, so the
##   distinctness maintains itself as the tree grows and nothing has to police it.
##
## **"Touch" means *merge*, never *be near*.** Two branches may run down adjacent streets — *"the
## player can walk the beginning of path A and then switch to path B without noticing"*, and that
## is fine, because both go to the same place. The constraint is on the graph and never on
## spacing; anything here that enforced a distance between branches would have misread it.
##
## **A second route is an offer, not a promise.** *"Having two distinct paths is really a niceness
## to the user. If we cannot construct a path B at all, let's not try."* An area with one way in
## is a legitimate area. What must still hold absolutely is only that *some* calm is reachable,
## which is `EventScheduler._ensure_the_city_is_still_walkable`'s job and not this class's.
##
## **A step is a `ReachabilityGrid` node, one per 4-connected component of a cell — not a street
## and not a tile.** M69 moved the growth here from the junction graph: a tree of whole streets
## puts every park crossing and every alley off the tree, which would make *"closed everywhere off
## the path"* (M64) seal the shortcuts the city is built around. Growing on the grid instead lets a
## branch cut through a park corner or take an alley exactly where the ground allows it, and the
## picture in `TelemetryMap` draws cells rather than a line down the middle of every street on the
## tree.
##
## **What still asks about a street asks in segment keys, translated from the cells.** A closure is
## still a whole `StreetNetwork.Segment` — see `StreetNetwork`'s own docstring on why — so
## `streets()`, `rim()`, `gaps()` and `is_on_the_tree()` all answer in `Vector3i` segment keys, each
## one derived from which cells are on the tree rather than tracked directly. `cells()` is the new
## one, for the picture and for `Corridor`'s tile-level questions.
##
## **The trunk.** *(2026-09-03, playtest 22: "the starting area was sealed off completely and the
## only way out was alongside the main road, which basically ends the day".)* `_home` is a rect of
## nodes and every branch's probe reaches *some* node bordering it, but which one is whatever the
## random walk happened to find first — on a day where every ordinary street near home lost the
## coin flip to the main road, the main road can end up the *only* street the join is protected on.
## `_grow_the_trunk()` runs once after every branch has grown: a plain BFS from the home nodes
## outward to the nearest cell already on the tree, tried first without the main road and only with
## it if no other way out exists at all (`trunk_used_the_spine`). Adopted through the same
## `_adopt()` every branch uses, under one of the merge point's own existing colours rather than a
## new one, so `is_on_the_tree()` — the fact `SealPlanner` and `ClosurePlanner` both build their
## guarantee on — is true of the join without either of them having to know the trunk exists.

## One calm area's way home: the branch that reaches it, as one or two routes.
##
## A route is an ordered `Array` of cell coordinates running **from the area to the doorstep**,
## which is the direction it was grown in and the direction the shared stretch is at the end of.
## The inner arrays are deliberately untyped `Array`s of `Vector2i` rather than `Array[Vector2i]`:
## passing an untyped array into an `Array[T]` parameter retains its arguments and leaks at
## shutdown, so the element type is declared at the call sites that need one instead.
class Branch extends RefCounted:
	## The block that anchors the calm area, matching `CityMap.calm_blocks`.
	var area: Vector2i
	## One or two routes. The first is the random walk, the second — where the map allowed one —
	## the shortest way that shares none of its ground.
	var routes: Array[Array] = []

	## Every cell on either route, as a set.
	func on_it() -> Dictionary:
		var found := {}
		for route in routes:
			for cell: Vector2i in route:
				found[cell] = true
		return found

	func has_a_choice() -> bool:
		return routes.size() >= 2


## The branches, in the order they were grown. A branch's index is its **colour**, which is what
## the sharing is recorded in.
var branches: Array[Branch] = []

## The grid the tree was grown on. Kept rather than rebuilt, because `Corridor` and the telemetry
## map both need to translate a cell or a tile against the same one the tree used.
var grid: ReachabilityGrid

## The city the tree is grown against. Kept for the one fact about the lattice growth itself needs
## beyond plain walkability: which cells are the main road, so `_grow_the_trunk()` can prefer a way
## out that never walks along it. See `_runs_along_the_spine` and the class doc, "The trunk".
var _map: CityMap

## Whether `_grow_the_trunk()` had to allow the main road to connect the doorstep to the rest of
## the tree at all, because every other way out of the home street was unreachable without it. See
## the class doc, "The trunk". Kept as a field rather than only a local so a caller can measure it
## directly instead of re-deriving it.
var trunk_used_the_spine := false

## Node id -> the set of colours carried by that cell.
var _colours := {}
## Node id -> the next node toward the doorstep.
##
## Set the first time a node enters the tree and never overwritten, which is what keeps this a
## tree rather than a mesh: a later probe that passes through an existing node without merging
## leaves the way home it already had.
var _parent := {}
## Node id -> the colours carried by the chain of parents from it to the doorstep. This is the
## whole of the same-colour rule: a probe may merge at a node whose tail does not already carry
## its colour, and may not at one that does. See `_resettle_the_tails`.
var _tail := {}
## Node id -> the nodes whose way home runs through it. The inverse of `_parent`, kept rather than
## searched because a colour reaches a node's whole subtree.
var _children := {}
## Every node of the home street's own tile rect, which is where every branch ends. The home
## street itself is not on the tree — a door is not a route, which is the same exemption both ends
## of the journey have.
var _home := {}
## The segments this tree's own lattice does not have — `map.blocked_segments()`, i.e. absent
## segments only, since the tree is grown before today's closures are chosen. Kept for the one
## question still asked in segment terms without a cell to derive it from: whether a candidate
## street for `gaps()` is a real street at all.
var _absent := {}

## Segment key -> `true`, lazily derived from `_colours` the first time anything asks a
## segment-level question. A `ReachabilityGrid` node is a handful of tiles and a tree touches many
## of them, so this is worth computing once rather than once per candidate `_shuffled_candidates`
## or `CityGenerator` asks about.
var _street_keys := {}
var _street_keys_built := false

## When a random walk has taken this many steps without arriving, it is replaced by the shortest
## way home from where it started.
##
## A walk on a connected graph arrives with probability one, so this is not a correctness
## measure — it is insurance against the one failure mode this project cannot see: a runtime
## hang inside a suite prints nothing at all and looks exactly like a slow test.
const _WALK_STEP_LIMIT := 20000

## Above this many routes the covering set is found greedily rather than exactly. A day plans
## about fifteen; the bound is here so that a city three times the size degrades into a worse
## answer rather than into a search nobody is waiting for.
const _EXACT_COVER_ROUTES := 32

const _NEIGHBOUR_OFFSETS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

# ---------------------------------------------------------------- construction ---

## The tree for one day, from the map and what is shut on it.
##
## **Deterministic from the city's seed and the day number, and from nothing else** — not from
## where the player walked, not from an RNG threaded through the rest of the day. Two callers ask
## for the day's tree for different reasons: the scheduler, which places against it, and
## `TelemetryMap`, which draws it. They have to get the same tree or the picture is of a plan
## nobody used, and telemetry may not touch a gameplay stream to get one. A pure function of
## `(seed, day, closed)` is the cheapest way for both to be true at once.
## The day number the **reference** tree is grown under. Not a day anybody plays: it is the one
## sample of the construction that generation takes, to place hard blockers against something
## rather than before anything. Zero, so it can never collide with a real day.
const REFERENCE_DAY := 0

## One example of a way to everywhere calm, on the finished lattice and with nothing shut.
##
## *"First construct an example tree from the initial map, then place the hard blockers — that way
## we can't block off regions entirely. Then when a day starts we construct a tree for real."*
##
## What it is **for** is the thing to keep straight: it is not the corridor and no day uses it. It
## is a witness. A hard blocker placed off it cannot cut it, and the tree reaches every calm area
## the run will ever use, so *every one of them is still reachable* — which is the property the
## gate would otherwise have to search for on every candidate.
##
## Named against `for_day` rather than `reference`, which is a method on `RefCounted` and would
## have been an override that the engine never calls.
static func for_the_run(map: CityMap) -> RouteTree:
	return for_day(map, REFERENCE_DAY)

## **It is grown on the permanent lattice, and today's closures are not in it.**
## That reads backwards until the order the day is planned in is in view: the corridor comes
## **first**, and the closures are then placed off it — so a tree grown against today's barriers
## would be a tree grown against decisions that were taken by consulting it. What makes it sound
## rather than merely circular is the guarantee on the other side: `ClosurePlanner` excludes every
## street on the tree, so a corridor grown this morning is still walkable this evening.
##
## It took a parameter for the day's closures until step 2 and nothing may pass one now. A tree
## that included them would differ from the one the day was planned against — the random walk sees
## a different graph, not merely a shorter one — and the picture would then be of a plan nobody
## used.
static func for_day(map: CityMap, day: int) -> RouteTree:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("routes:%d:%d" % [map.seed_used, day])
	var grid := ReachabilityGrid.build(map)
	return grow(map, ClosurePlanner.home_street(map), ClosurePlanner.calm_areas(map),
			map.blocked_segments(), grid, rng)

## Grows the tree. `closed` is the merged set `CityMap.blocked_segments()` returns — the streets a
## calm zone absorbed. Their ground is already reflected in `grid` as walkable calm tiles, so it
## costs the growth nothing extra; it is kept here only for `gaps()`'s "is this candidate a real
## street" question, which a segment key alone cannot answer.
static func grow(map: CityMap, home: StreetNetwork.Segment, areas: Array[ClosurePlanner.CalmArea],
		closed: Dictionary, grid: ReachabilityGrid, rng: RandomNumberGenerator) -> RouteTree:
	var tree := RouteTree.new()
	if not home or areas.is_empty():
		return tree
	tree.grid = grid
	tree._map = map
	tree._absent = closed
	for tile in _rect_tiles(home.tile_rect()):
		var node := grid.node_at(tile)
		if node >= 0:
			tree._home[node] = true
	# The order decides which area's probe gets home first and therefore which one the trunk
	# belongs to, so it is rolled rather than left as `calm_blocks`' generation order — otherwise
	# the same area anchors the tree on every day of the run.
	for area in tree._in_a_rolled_order(areas, rng):
		tree._grow_a_branch(map, area, rng)
	tree._grow_the_trunk()
	return tree

static func _rect_tiles(rect: Rect2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			found.append(Vector2i(x, y))
	return found

func _in_a_rolled_order(areas: Array[ClosurePlanner.CalmArea],
		rng: RandomNumberGenerator) -> Array[ClosurePlanner.CalmArea]:
	var order: Array[ClosurePlanner.CalmArea] = areas.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := order[i]
		order[i] = order[j]
		order[j] = held
	return order

## One area's branch: a probe, and then the offer of a second one.
##
## The colour is the branch's index, taken **before** the branch is appended so the two agree. If
## the first probe finds no way home at all the area is simply not on the tree today — an area
## that cannot be reached is not a destination, and the walkability guarantee is stated over
## *some* calm rather than over this one.
func _grow_a_branch(map: CityMap, area: ClosurePlanner.CalmArea, rng: RandomNumberGenerator) -> void:
	var sources := _access_nodes(map, area)
	if sources.is_empty():
		return
	var colour := branches.size()
	var first := _walk_home(sources, colour, rng)
	if _is_no_route(first):
		return
	var branch := Branch.new()
	branch.area = area.block
	branches.append(branch)
	branch.routes.append(_adopt(first, colour))
	# Probe two, and it is **the shortest way left** rather than a second wander. A shorter B puts
	# less of the map in play: *"the shortest path also reduces the overall number of available
	# blocks, which makes the area more approachable — the player feels less lost."* The same
	# search that answers *is there a second route* is the second route, so there is no second walk.
	var second := _shortest_home(sources, colour)
	if not _is_no_route(second):
		branch.routes.append(_adopt(second, colour))

## A probe that found nothing, or found that the area's way in **is** the doorstep.
##
## The second is the case worth naming: a calm area next door to the home is arrived at without
## walking any ground, so its route is empty. That is not a corridor — there is nothing to place a
## wall outside of or a set piece on — and an empty route in the covering set would be a route
## nothing can ever hit, which quietly makes the whole day's fan-out unanswerable. Not a branch.
func _is_no_route(path: Array[int]) -> bool:
	return path.is_empty() or (path.size() == 1 and _home.has(path[0]))

## The nodes that count as having arrived at a calm area: every node that borders the area's own
## calm ground from outside it. Found by walking the area's own tiles rather than by reasoning
## about the lot — a park's every frontage tile is a way in and a courtyard's is the one tile its
## archway lands on, and neither needs a special case here because the tiles already say so.
func _access_nodes(map: CityMap, area: ClosurePlanner.CalmArea) -> Array[int]:
	var found := {}
	for tile in _rect_tiles(area.rect):
		if not Tile.is_calm(map.tile_at(tile)):
			continue
		for offset in _NEIGHBOUR_OFFSETS:
			var neighbour := tile + offset
			if area.rect.has_point(neighbour):
				continue
			var node := grid.node_at(neighbour)
			if node >= 0:
				found[node] = true
	var result: Array[int] = []
	for node in found:
		result.append(node)
	return result

# --------------------------------------------------------------------- probes ---

## The first probe: a loop-erased random walk from one of the area's ways in, until it reaches
## the doorstep or merges into another colour's path.
##
## **Wilson's algorithm rather than a drift toward home.** Walk at random and delete each loop as
## it closes — the standard tool for growing a tree with variety in it, and the reason a route to
## a calm area is not the same route two days running. A walk that drifts homeward is a shortest
## path with jitter on it, which is the star this class exists to avoid.
func _walk_home(sources: Array[int], colour: int, rng: RandomNumberGenerator) -> Array[int]:
	var start: int = sources[rng.randi_range(0, sources.size() - 1)]
	var path: Array[int] = [start]
	var index := {start: 0}
	var at := start
	var steps := 0
	while not _is_the_end_of_a_probe(at, colour):
		var ways: Array = grid.neighbours(at)
		if ways.is_empty():
			return []
		steps += 1
		if steps > _WALK_STEP_LIMIT:
			var only: Array[int] = [start]
			return _shortest_home(only, colour)
		at = (ways[rng.randi_range(0, ways.size() - 1)] as Array)[0]
		if index.has(at):
			var keep: int = index[at]
			for i in range(keep + 1, path.size()):
				index.erase(path[i])
			path.resize(keep + 1)
		else:
			index[at] = path.size()
			path.append(at)
	return path

## The second probe: the shortest way home that uses none of this colour's ground.
##
## It stops where the first one does — at the doorstep or at a merge — and the mergeable set is
## what makes the two routes distinct all the way rather than only up to the trunk: a node whose
## tail already carries this colour is not a merge, it is the first route.
##
## **A source the first probe's own route already stands on is excluded from starting the second
## one, and this is not the same fact as the tail check above.** A cell is now the coloured unit —
## the first probe's start node is *itself* part of route one, since a door is not a route but an
## access cell is real ground — so seeding every access node as a free root here the way the
## junction-graph version safely could would let probe two start again from that same cell and
## share it with probe one. A junction was never part of a route in the old model and had nothing
## to protect; a cell is, and does.
func _shortest_home(sources: Array[int], colour: int) -> Array[int]:
	var previous := {}
	var queue: Array[int] = []
	for node in sources:
		if previous.has(node) or _carries(node, colour):
			continue
		previous[node] = -1
		queue.append(node)
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if _is_the_end_of_a_probe(node, colour):
			return _unwind(previous, node)
		for edge: Array in grid.neighbours(node):
			var next: int = edge[0]
			if previous.has(next) or _carries(next, colour):
				continue
			previous[next] = node
			queue.append(next)
	return []

func _unwind(previous: Dictionary, node: int) -> Array[int]:
	var path: Array[int] = []
	var at := node
	while at != -1:
		path.append(at)
		at = previous[at]
	path.reverse()
	return path

## A probe is finished when it is home, or when it has found somewhere to merge.
func _is_the_end_of_a_probe(node: int, colour: int) -> bool:
	if _home.has(node):
		return true
	if not _parent.has(node):
		return false
	return not (_tail[node] as Dictionary).has(colour)

func _carries(node: int, colour: int) -> bool:
	return _colours.has(node) and (_colours[node] as Dictionary).has(colour)

# ------------------------------------------------------------------ the main road ---

## `grid.neighbours(node)` with every edge that would walk along the main road removed. Used by
## `_grow_the_trunk()`'s own search; see its own doc for why the trunk in particular needs this.
func _ways(node: int) -> Array:
	var edges := grid.neighbours(node)
	if not _map or _map.main_road < 0:
		return edges
	var found: Array = []
	for edge: Array in edges:
		if _runs_along_the_spine(edge[1], edge[2]):
			continue
		found.append(edge)
	return found

## Whether stepping from tile `a` to tile `b` walks along the main road rather than across it.
##
## A grid edge is either an x-step or a y-step (`ReachabilityGrid._build_edges` only ever connects
## a cell to its immediate horizontal or vertical neighbour), and the main road is a north-south
## band — `CityMap.street_kind_at(true, tile)` depends only on the tile's `x`. So a **y-step within
## the band** (`a.x == b.x`, both on the spine) is walking along it; an **x-step through the band**
## is crossing it, one cell at a time, and is never refused here however many of them a route takes
## in a row.
func _runs_along_the_spine(a: Vector2i, b: Vector2i) -> bool:
	return a.x == b.x and _map.street_kind_at(true, a) == GameEnums.StreetKind.MAIN

# --------------------------------------------------------------------- adoption ---

## Puts a probe's path into the tree and returns the whole route it stands for, as a chain of
## cells.
##
## The path itself is only the new stretch. Where it ended in a merge, the route continues down
## the parent chain to the doorstep, and **this colour is added to every node of that chain**:
## that is "the colours add up", and it is also what locks this area's other probe out of the
## shared stretch, since a node whose tail now carries the colour is no longer a merge. The home
## nodes themselves are never coloured and never appear in the returned route — a door is not a
## route.
func _adopt(path: Array[int], colour: int) -> Array:
	for i in range(path.size() - 1):
		if not _parent.has(path[i]):
			_parent[path[i]] = path[i + 1]
			var below: Array[int] = _children.get(path[i + 1], [] as Array[int])
			below.append(path[i])
			_children[path[i + 1]] = below

	var nodes: Array[int] = path.duplicate()
	var at: int = nodes[nodes.size() - 1]
	# Bounded rather than trusted. The chain cannot cycle — a node's parent is set once, when it
	# joins, and always points at something already on the way home — but a hang here would be a
	# suite that prints nothing, so the one impossible case is the one worth bounding.
	while not _home.has(at) and _parent.has(at) and nodes.size() <= grid.node_count():
		at = _parent[at] as int
		nodes.append(at)

	var route: Array[Vector2i] = []
	for node in nodes:
		if _home.has(node):
			continue
		var carried: Dictionary = _colours.get(node, {})
		carried[colour] = true
		_colours[node] = carried
		route.append(grid.cell_of(node))
	_resettle_the_tails()
	return route

## Recomputes every node's tail, from the doorstep outwards.
##
## **A tail is not the stretch that was just walked, it is everything hanging off it**, and this
## is the one piece of bookkeeping in the class that has to be transitive: adding a colour to a
## node adds it to the tail of every node that reaches home *through* it, including whole branches
## adopted earlier that merged into it further up, and including branches that will hang off it
## later.
##
## Recomputing the lot is O(the tree) a dozen times a day, which is nothing, and it is the version
## whose correctness can be read off the definition instead of argued about subtree by subtree.
func _resettle_the_tails() -> void:
	_tail.clear()
	var stack: Array[int] = []
	for node: int in _home:
		_tail[node] = {}
		stack.append(node)
	while not stack.is_empty():
		var node: int = stack.pop_back()
		for child: int in _children.get(node, [] as Array[int]):
			var tail: Dictionary = (_tail[node] as Dictionary).duplicate()
			for colour: int in (_colours.get(child, {}) as Dictionary):
				tail[colour] = true
			_tail[child] = tail
			stack.append(child)

# ------------------------------------------------------------------------ the trunk ---

## Guarantees the join between the doorstep and the rest of the tree, regardless of which street a
## branch's own random walk happened to reach home through. See the class doc, "The trunk", and
## `docs/TODO.md`, M64: "grow the day's tree from the doorstep and exempt the trunk with it, so
## home-to-corridor is tree ground like any other."
##
## A no-op when nothing grew at all — there is no tree to join home to, and that day's walkability
## is somebody else's question (`EventScheduler._ensure_the_city_is_still_walkable`, `Tuning.
## MIN_CALM_AREAS_REACHABLE`), not this one's.
func _grow_the_trunk() -> void:
	if _colours.is_empty():
		return
	var path := _trunk_path(true)
	if path.is_empty():
		path = _trunk_path(false)
		if path.is_empty():
			return
		trunk_used_the_spine = true
	# `path` runs merge point first, home last (see `_trunk_path`) — the merge point is the end
	# that already carries a colour; the home end never does.
	_adopt(path, _any_colour_of(path[0]))

## The shortest way from any home node to the nearest cell already on the tree, oriented the way
## `_adopt()` expects — far end first, home last — exactly like a branch's own probe. `avoid_spine`
## true is tried first; see `_grow_the_trunk`.
func _trunk_path(avoid_spine: bool) -> Array[int]:
	var previous := {}
	var queue: Array[int] = []
	for node: int in _home:
		previous[node] = -1
		queue.append(node)
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if _colours.has(node):
			var path := _unwind(previous, node)
			path.reverse()
			return path
		var edges := _ways(node) if avoid_spine else grid.neighbours(node)
		for edge: Array in edges:
			var next: int = edge[0]
			if previous.has(next):
				continue
			previous[next] = node
			queue.append(next)
	return []

## Any one colour already carried at `node` — deterministic (the lowest), so the trunk's own
## colour does not depend on dictionary iteration order.
func _any_colour_of(node: int) -> int:
	var best := -1
	for colour: int in (_colours.get(node, {}) as Dictionary):
		if best == -1 or colour < best:
			best = colour
	return best

# ---------------------------------------------------------------------- asking ---

## Every cell on the tree, in no particular order — what the dusk map draws.
func cells() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for node: int in _colours:
		found.append(grid.cell_of(node))
	return found

## Builds `_street_keys` the first time anything asks a segment-level question. A node's cell
## resolves to a segment exactly when the cell is wholly street — `StreetNetwork.segment_
## containing` already tells a street tile from a junction or a block-interior one, and a cell
## never straddles that distinction (docs/TODO.md, "The cell is two tiles square").
func _ensure_street_keys() -> void:
	if _street_keys_built:
		return
	for node: int in _colours:
		var segment := StreetNetwork.segment_containing(grid.any_tile_of(node))
		if segment:
			_street_keys[segment.key()] = true
	_street_keys_built = true

## Every street the tree touches, as segment keys — the streets `ClosurePlanner` may not close and
## `CityGenerator` may not take for a hard blocker. A tree that cuts through a park or an alley
## simply contributes no key for that stretch, which is correct: there is no street there to
## protect, only ground.
func streets() -> Array[Vector3i]:
	_ensure_street_keys()
	var found: Array[Vector3i] = []
	for key: Vector3i in _street_keys:
		found.append(key)
	return found

func is_on_the_tree(key: Vector3i) -> bool:
	_ensure_street_keys()
	return _street_keys.has(key)

## The streets just outside the corridor: not on the tree, and meeting one that is at a junction.
##
## **Kept junction-based rather than moved to grid depth, on purpose, and this is the one place
## the milestone's own "everything moves to cells" does not reach.** `gaps()` stays a street-level
## question stated over junctions — "a street of the tree crosses each of its two ends" — and its
## own docstring promises every gap is on the rim by construction. A grid-depth rim would break
## that promise the moment the tree can shortcut through calm ground: a gap street's own junction
## might sit two or three grid hops from the nearest on-tree cell if the shorter way there runs
## through a park, while still being exactly the street two tree strands cross at both ends. The
## rim a wall is placed against is a fact about **streets meeting at a junction**, which is what
## `_shuffled_candidates` and `CityGenerator`'s hard-blocker gate both actually ask about, so this
## answers at that grain rather than the cell's.
func rim() -> Array[Vector3i]:
	_ensure_street_keys()
	var found := {}
	for key: Vector3i in _street_keys:
		var segment := StreetNetwork.by_key(key)
		if not segment:
			continue
		for junction in [segment.a, segment.b]:
			for candidate in StreetNetwork.at_junction(junction):
				var beside := candidate.key()
				if _street_keys.has(beside) or _absent.has(beside):
					continue
				found[beside] = true
	var result: Array[Vector3i] = []
	for key in found:
		result.append(key)
	return result

## How far off the corridor every reachable node is, counted in grid steps. Zero is on the tree;
## `Corridor` is what turns this into the byte-a-tile answer placement actually asks.
func node_depths() -> Dictionary:
	var found := {}
	var frontier: Array[int] = []
	for node: int in _colours:
		found[node] = 0
		frontier.append(node)
	var hop := 0
	while not frontier.is_empty():
		hop += 1
		var next: Array[int] = []
		for node in frontier:
			for edge: Array in grid.neighbours(node):
				var neighbour: int = edge[0]
				if found.has(neighbour):
					continue
				found[neighbour] = hop
				next.append(neighbour)
		frontier = next
	return found

## How far off the corridor every reachable **street** is, counted in turnings — the junction-graph
## question `node_depths()` answered before M69, kept for street ground specifically rather than
## replaced by the grid everywhere.
##
## **A street tile still answers at the grain of its whole street, not its own cell.** A route is
## a thin chain of cells now, but a street is walkable frontage to frontage — three cells wide —
## and a player on it can be anywhere across that width, on the side the tree's path happened to
## take or the other one. Answering street tiles from `node_depths()` instead would price two
## thirds of every on-tree street's own pavement as one turning further out than it is, which
## `Corridor.depth()` found by measurement: the share of costly rows landing on the corridor nearly
## halved the day this used the grid for streets too. Cells still answer the question they exist to
## answer — a park cut or an alley the tree actually takes reads as depth zero, which no street
## question could ever have told it.
func segment_depths() -> Dictionary:
	_ensure_street_keys()
	var found := {}
	var frontier: Array[Vector3i] = []
	for key: Vector3i in _street_keys:
		found[key] = 0
		frontier.append(key)
	var hop := 0
	while not frontier.is_empty():
		hop += 1
		var next: Array[Vector3i] = []
		for key in frontier:
			var segment := StreetNetwork.by_key(key)
			if not segment:
				continue
			for junction in [segment.a, segment.b]:
				for candidate in StreetNetwork.at_junction(junction):
					var beside := candidate.key()
					if found.has(beside):
						continue
					found[beside] = hop
					next.append(beside)
		frontier = next
	return found

## Whether a street is still in the lattice today, asked of the run-fixed absent set rather than
## of the grid: a segment a calm zone absorbed resolves to perfectly walkable (calm) ground, so the
## grid alone cannot tell it apart from a real street.
func _is_a_real_street(segment: StreetNetwork.Segment) -> bool:
	return not _absent.has(segment.key())

## The streets that sit **between two adjacent strands of the corridor**: one street of the tree
## crossing each end, and nothing of the tree on the street itself.
##
## What it is for: two strands of corridor running parallel with one free street between them are
## one wide route rather than two, so something goes in that street.
##
## **Directly adjacent means one street, and that is the whole definition.** Two strands two
## turnings apart have off-corridor ground between them, which is lethal or very costly on its own
## — so they are separated by the map and nothing has to be placed. Asking this question of
## anything wider invents a rule nobody asked for.
##
## **A strand is a stretch of corridor and not a branch**, so a single branch that runs out along
## one street and home along the next one down answers yes here. `branches_on()` is what tells two
## routes apart, and it is the telemetry's question rather than this one.
func gaps() -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if is_on_the_tree(key) or not _is_a_real_street(segment):
			continue
		if _crossed_by_the_tree(segment.a, key.z) and _crossed_by_the_tree(segment.b, key.z):
			found.append(key)
	return found

## Whether a street of the tree runs across this junction at right angles to `along`.
##
## At right angles is what makes the two strands **parallel**. A tree street collinear with the
## connector is the corridor carrying straight on through the junction, which is one strand rather
## than two, and counting it would call every dead end off a route a gap.
func _crossed_by_the_tree(junction: Vector2i, along: int) -> bool:
	for segment in StreetNetwork.at_junction(junction):
		if segment.key().z != along and is_on_the_tree(segment.key()):
			return true
	return false

## Which branches carry `tile`, sorted. Empty for a tile off the tree, which is what makes it
## meaningful to the telemetry — *she left one path and entered another* is only sayable because a
## count could not tell it apart from *she left the corridor*.
func branches_on(tile: Vector2i) -> Array[int]:
	var found: Array[int] = []
	var node := grid.node_at(tile)
	if node >= 0 and _colours.has(node):
		for colour: int in (_colours[node] as Dictionary):
			found.append(colour)
	found.sort()
	return found

## The cells carried by two or more branches — the trunk, and any stretch several ways out of the
## city share before they separate.
##
## A bundle is what makes placement cheap: it narrows *how many places* a thing has to be in
## order to be met. It never narrows it to one, and anything written as "the tile she must cross"
## is wrong — see `covering_sites`.
func bundles() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for node: int in _colours:
		if (_colours[node] as Dictionary).size() >= 2:
			found.append(grid.cell_of(node))
	return found

func branch_for(area: Vector2i) -> Branch:
	for branch in branches:
		if branch.area == area:
			return branch
	return null

## The streets a set piece is placed on: the smallest set of **real streets** such that every
## route touches at least one of them.
##
## *"We can have multiple candidate places and make sure all routes touch at least one of them."*
## Stated over streets rather than cells because a set piece needs somewhere she is walked *past*
## rather than a single two-tile step — `EventScheduler._ground_for` bounds a set piece's candidate
## ground to the whole named street. A route's cells that resolve to no street (a park cut, an
## alley) simply do not offer a site; the guarantee is unaffected, because it never promised a
## site on every cell, only that every route meets one somewhere.
##
## **It covers routes and not branches, and the difference is the whole of the design's warning.**
## A first version of this counted a branch as covered when *either* of its routes was — see
## `docs/DECISIONS.md` for the measurement that ruled it out — which is "the street she must
## cross" arriving through the back door. Covering routes gets the right guarantee for nothing: the
## two routes of one area share no ground by construction, so no single site can ever cover both.
##
## It is a minimum hitting set, which is only expensive in general: there are a handful of routes
## and a distinct street is only interesting for *which* of them it carries, so the search is over
## the distinct route sets and its depth is bounded by the number of routes. An empty answer means
## no such set exists — which happens when a route has no real street on it at all, because its
## calm area opens straight onto the doorstep or reaches home entirely through park and alley.
func covering_sites() -> Array[Vector3i]:
	var routes := _route_count()
	if routes == 0:
		return []
	if routes > _EXACT_COVER_ROUTES:
		return _greedy_cover()
	var sites := _sites_by_route_set()
	var masks: Array[int] = []
	for mask: int in sites:
		masks.append(mask)
	var everything := (1 << routes) - 1
	# Deepening rather than a single search, so the first answer found is a smallest one.
	for budget in range(1, routes + 1):
		var found := _cover(everything, masks, sites, budget)
		if not found.is_empty():
			return found
	return []

func _route_count() -> int:
	var total := 0
	for branch in branches:
		total += branch.routes.size()
	return total

## One street per distinct set of routes, as `route mask -> segment key`. Two streets carrying the
## same routes are interchangeable here, so only one of them is worth searching over. A route's
## cells that resolve to no real street contribute nothing to any mask.
func _sites_by_route_set() -> Dictionary:
	var masks := {}
	var index := 0
	for branch in branches:
		for route: Array in branch.routes:
			for cell: Vector2i in route:
				var segment := StreetNetwork.segment_containing(cell * ReachabilityGrid.CELL)
				if segment:
					var key := segment.key()
					masks[key] = int(masks.get(key, 0)) | (1 << index)
			index += 1
	var sites := {}
	for key: Vector3i in masks:
		var mask: int = masks[key]
		if mask != 0 and not sites.has(mask):
			sites[mask] = key
	return sites

## A cover of `uncovered` using at most `budget` streets, or empty if there is none.
##
## Every cover has to hit the lowest uncovered route, so the only candidates worth trying are the
## streets that carry it — which is what keeps the search small.
func _cover(uncovered: int, masks: Array[int], sites: Dictionary, budget: int) -> Array[Vector3i]:
	if budget <= 0:
		return []
	var route := 0
	while (uncovered & (1 << route)) == 0:
		route += 1
	for mask in masks:
		if (mask & (1 << route)) == 0:
			continue
		var rest := uncovered & ~mask
		if rest == 0:
			var one: Array[Vector3i] = []
			one.append(sites[mask] as Vector3i)
			return one
		var deeper := _cover(rest, masks, sites, budget - 1)
		if not deeper.is_empty():
			deeper.push_front(sites[mask] as Vector3i)
			return deeper
	return []

## The fallback for a city with more routes than the exact search is meant for: take the street
## covering the most routes still uncovered, and repeat.
func _greedy_cover() -> Array[Vector3i]:
	var sites := _sites_by_route_set()
	var uncovered := (1 << _route_count()) - 1
	var chosen: Array[Vector3i] = []
	while uncovered != 0:
		var best := 0
		var best_mask := 0
		for mask: int in sites:
			var hits := _bits(mask & uncovered)
			if hits > best:
				best = hits
				best_mask = mask
		if best == 0:
			return []
		chosen.append(sites[best_mask] as Vector3i)
		uncovered &= ~best_mask
	return chosen

static func _bits(mask: int) -> int:
	var count := 0
	var rest := mask
	while rest != 0:
		count += rest & 1
		rest >>= 1
	return count
