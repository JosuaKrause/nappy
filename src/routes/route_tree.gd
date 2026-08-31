class_name RouteTree
extends RefCounted
## The day's corridor: one branch from the doorstep to every calm area still worth reaching.
##
## *(M50. The design is docs/CITY.md, "Diversions — the design" and "How the corridor is built";
## the construction below is the player's own algorithm.)*
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
##   second is the shortest way left once the first one's streets are spent.
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
## **A step is a segment on the junction graph, not a tile.** A corridor is a set of segment keys
## everywhere else in this design, and a tile-walked path would produce something no other part
## of it could consume.
##
## Nothing here draws, emits or decides anything the player can feel yet — placement by role is
## the milestone's step 2. This is the structure those decisions are made against, and the
## picture in `TelemetryMap` is what says whether it points anywhere.


## One calm area's way home: the branch that reaches it, as one or two routes.
##
## A route is an ordered `Array` of segment keys running **from the area to the doorstep**, which
## is the direction it was grown in and the direction the shared stretch is at the end of. The
## inner arrays are deliberately untyped `Array`s of `Vector3i` rather than `Array[Vector3i]`:
## passing an untyped array into an `Array[T]` parameter retains its arguments and leaks at
## shutdown, so the element type is declared at the call sites that need one instead.
class Branch extends RefCounted:
	## The block that anchors the calm area, matching `CityMap.calm_blocks`.
	var area: Vector2i
	## One or two routes. The first is the random walk, the second — where the map allowed one —
	## the shortest way that shares none of its streets.
	var routes: Array[Array] = []

	## Every street on either route, as a set of keys.
	func on_it() -> Dictionary:
		var found := {}
		for route in routes:
			for key: Vector3i in route:
				found[key] = true
		return found

	func has_a_choice() -> bool:
		return routes.size() >= 2


## The branches, in the order they were grown. A branch's index is its **colour**, which is what
## the sharing is recorded in.
var branches: Array[Branch] = []

## Segment key -> the set of colours carried by that street.
var _colours := {}
## Junction node -> `[the next node toward the doorstep, the street between them]`.
##
## Set the first time a junction enters the tree and never overwritten, which is what keeps this
## a tree rather than a mesh: a later probe that passes through an existing junction without
## merging leaves the way home it already had.
var _parent := {}
## Junction node -> the colours carried by the chain of parents from it to the doorstep. This is
## the whole of the same-colour rule: a probe may merge at a junction whose tail does not already
## carry its colour, and may not at one that does. See `_resettle_the_tails`.
var _tail := {}
## Junction node -> the junctions whose way home runs through it. The inverse of `_parent`, kept
## rather than searched because a colour reaches a junction's whole subtree.
var _children := {}
## The two junctions of the home street, which is where every branch ends. The home street itself
## is not on the tree — a door is not a route, the same exemption both ends of the journey have
## had since M16.
var _home := {}
## Junction node -> `[[neighbour node, segment key], ...]`, closed and absent streets already
## dropped. Built once per tree: a `Dictionary` keyed by `Vector3i` hashes a Variant on every
## lookup, and a random walk asks thousands of times.
var _links: Array = []

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

# ---------------------------------------------------------------- construction ---

## The tree for one day, from the map and what is shut on it.
##
## **Deterministic from the city's seed and the day number, and from nothing else** — not from
## where the player walked, not from an RNG threaded through the rest of the day. Two callers ask
## for the day's tree for different reasons: the scheduler, which places against it, and
## `TelemetryMap`, which draws it. They have to get the same tree or the picture is of a plan
## nobody used, and telemetry may not touch a gameplay stream to get one. A pure function of
## `(seed, day, closed)` is the cheapest way for both to be true at once.
static func for_day(map: CityMap, day: int, closures: Array[RoadClosure] = []) -> RouteTree:
	var closed := {}
	for closure in closures:
		closed[closure.segment.key()] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("routes:%d:%d" % [map.seed_used, day])
	return grow(ClosurePlanner.home_street(map), ClosurePlanner.calm_areas(map),
			map.blocked_segments(closed), rng)

## Grows the tree. `closed` is the merged set `CityMap.blocked_segments()` returns — the streets
## a calm zone absorbed as well as the ones shut this morning, because neither is there to be
## walked down.
static func grow(home: StreetNetwork.Segment, areas: Array[ClosurePlanner.CalmArea],
		closed: Dictionary, rng: RandomNumberGenerator) -> RouteTree:
	var tree := RouteTree.new()
	if not home or areas.is_empty():
		return tree
	tree._build_links(closed)
	for junction in [home.a, home.b]:
		tree._home[StreetNetwork.node_of(junction)] = true
	# The order decides which area's probe gets home first and therefore which one the trunk
	# belongs to, so it is rolled rather than left as `calm_blocks`' generation order — otherwise
	# the same area anchors the tree on every day of the run.
	for area in tree._in_a_rolled_order(areas, rng):
		tree._grow_a_branch(area, rng)
	return tree

## The junction graph with today's shut and absent streets already gone.
func _build_links(closed: Dictionary) -> void:
	_links.resize(StreetNetwork.node_total())
	for node in StreetNetwork.node_total():
		_links[node] = []
	for segment in StreetNetwork.segments():
		if closed.has(segment.key()):
			continue
		var u := StreetNetwork.node_of(segment.a)
		var v := StreetNetwork.node_of(segment.b)
		(_links[u] as Array).append([v, segment.key()])
		(_links[v] as Array).append([u, segment.key()])

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
func _grow_a_branch(area: ClosurePlanner.CalmArea, rng: RandomNumberGenerator) -> void:
	var sources := _access_junctions(area)
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
## walking a street, so its route is empty. That is not a corridor — there is nothing to place a
## wall outside of or a set piece on — and an empty route in the covering set would be a route
## nothing can ever hit, which quietly makes the whole day's fan-out unanswerable. Not a branch.
func _is_no_route(path: Array[int]) -> bool:
	return path.is_empty() or (path.size() == 1 and _home.has(path[0]))

## The junctions that count as having arrived at a calm area: both ends of every street it opens
## onto. A street that is shut is not a way in today, which is the same reading `route_count`
## takes — and it is what makes a courtyard whose one archway is closed drop off the tree.
func _access_junctions(area: ClosurePlanner.CalmArea) -> Array[int]:
	var found: Array[int] = []
	var seen := {}
	for segment in area.access:
		if not _is_a_real_street(segment):
			continue
		for junction in [segment.a, segment.b]:
			var node := StreetNetwork.node_of(junction)
			if seen.has(node):
				continue
			seen[node] = true
			found.append(node)
	return found

## Whether a street is still in the lattice today, asked of the links rather than of the map: a
## segment that was closed or absorbed has no link on either of its junctions.
func _is_a_real_street(segment: StreetNetwork.Segment) -> bool:
	for link: Array in _links[StreetNetwork.node_of(segment.a)]:
		if (link[1] as Vector3i) == segment.key():
			return true
	return false

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
		var ways: Array = _links[at]
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

## The second probe: the shortest way home that uses none of this colour's streets.
##
## It stops where the first one does — at the doorstep or at a merge — and the mergeable set is
## what makes the two routes distinct all the way rather than only up to the trunk: a junction
## whose tail already carries this colour is not a merge, it is the first route.
func _shortest_home(sources: Array[int], colour: int) -> Array[int]:
	var previous := {}
	var queue: Array[int] = []
	for node in sources:
		if previous.has(node):
			continue
		previous[node] = -1
		queue.append(node)
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if _is_the_end_of_a_probe(node, colour):
			return _unwind(previous, node)
		for link: Array in _links[node]:
			var next: int = link[0]
			if previous.has(next) or _carries(link[1] as Vector3i, colour):
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

func _carries(key: Vector3i, colour: int) -> bool:
	return _colours.has(key) and (_colours[key] as Dictionary).has(colour)

# --------------------------------------------------------------------- adoption ---

## Puts a probe's path into the tree and returns the whole route it stands for.
##
## The path itself is only the new stretch. Where it ended in a merge, the route continues down
## the parent chain to the doorstep, and **this colour is added to every street of that chain**:
## that is "the colours add up", and it is also what locks this area's other probe out of the
## shared stretch, since a junction whose tail now carries the colour is no longer a merge.
func _adopt(path: Array[int], colour: int) -> Array:
	for i in range(path.size() - 1):
		if not _parent.has(path[i]):
			_parent[path[i]] = [path[i + 1], _street_between(path[i], path[i + 1])]
			var below: Array[int] = _children.get(path[i + 1], [] as Array[int])
			below.append(path[i])
			_children[path[i + 1]] = below

	var nodes: Array[int] = path.duplicate()
	var at: int = nodes[nodes.size() - 1]
	# Bounded rather than trusted. The chain cannot cycle — a junction's parent is set once, when
	# it joins, and always points at something already on the way home — but a hang here would be
	# a suite that prints nothing, so the one impossible case is the one worth bounding.
	while not _home.has(at) and _parent.has(at) and nodes.size() <= StreetNetwork.node_total():
		at = (_parent[at] as Array)[0]
		nodes.append(at)

	var route: Array = []
	for i in range(nodes.size() - 1):
		var key := _street_between(nodes[i], nodes[i + 1])
		route.append(key)
		var carried: Dictionary = _colours.get(key, {})
		carried[colour] = true
		_colours[key] = carried
	_resettle_the_tails()
	return route

## Recomputes every junction's tail, from the doorstep outwards.
##
## **A tail is not the stretch that was just walked, it is everything hanging off it**, and this
## is the one piece of bookkeeping in the class that has to be transitive: adding a colour to a
## stretch adds it to the tail of every junction that reaches home *through* that stretch,
## including whole branches adopted earlier that merged into it further up, and including
## branches that will hang off it later.
##
## Marking only the junctions the probe walked was the first version and it was silently wrong in
## both directions at once — an area's second probe was allowed to merge at a junction whose way
## home ran straight back into the streets its first probe had spent, so the two routes shared
## ground while every explicit check in the construction said they could not. That is the failure
## the colour rule exists to make impossible, arriving through the one place nothing was looking.
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
			for colour: int in (_colours[(_parent[child] as Array)[1] as Vector3i] as Dictionary):
				tail[colour] = true
			_tail[child] = tail
			stack.append(child)

func _street_between(from: int, to: int) -> Vector3i:
	for link: Array in _links[from]:
		if (link[0] as int) == to:
			return link[1] as Vector3i
	return Vector3i.ZERO   # unreachable: every step of a path came from a link

# ---------------------------------------------------------------------- asking ---

## Every street on the tree, in the order it was grown.
func streets() -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	for key: Vector3i in _colours:
		found.append(key)
	return found

func is_on_the_tree(key: Vector3i) -> bool:
	return _colours.has(key)

## How many branches run down a street. One is a branch; two or more is a bundle.
func colours_on(key: Vector3i) -> int:
	return (_colours[key] as Dictionary).size() if _colours.has(key) else 0

## The streets carried by two or more branches — the trunk, and any stretch several ways out of
## the city share before they separate.
##
## A bundle is what makes placement cheap: it narrows *how many places* a thing has to be in to
## be met. It never narrows it to one, and anything written as "the street she must cross" is
## wrong — see `covering_sites`.
func bundles() -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	for key: Vector3i in _colours:
		if (_colours[key] as Dictionary).size() >= 2:
			found.append(key)
	return found

func branch_for(area: Vector2i) -> Branch:
	for branch in branches:
		if branch.area == area:
			return branch
	return null

## The fan-out: the smallest set of streets such that **every route touches at least one of
## them**. This is what a set piece needs.
##
## *"We can have multiple candidate places and make sure all routes touch at least one of them."*
## The guarantee is structural rather than predictive — it holds whichever way she goes, so
## nothing has to know which route she chose, and the fire engine stops being a silhouette and a
## fairness contract spent on a street she never walked.
##
## **It covers routes and not branches, and the difference is the whole of the design's warning.**
## A first version of this counted a branch as covered when *either* of its routes was, which is
## the natural reading of "every corridor passes at least one" — and measured over 32 planned
## days it produced a **single** street on nine of them. That street is on route one of every
## area and on route two of none, so a set piece placed there is met by a player who takes the
## first way out of every area and missed entirely by one who takes the second. It is
## "the street she must cross" arriving through the back door, which the design names as the
## first draft's mistake and rules out in arithmetic: *"anything that must be encountered has to
## exist in at least two places."* Covering routes gets that for nothing — the two routes of one
## area share no street by construction, so no single site can ever cover both.
##
## It is a minimum hitting set, which is only expensive in general: there are a handful of routes
## and a distinct street is only interesting for *which* of them it carries, so the search is over
## the distinct route sets and its depth is bounded by the number of routes. An empty answer means
## no such set exists — which happens when a route has no streets at all, because its calm area
## opens straight onto the doorstep.
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
## same routes are interchangeable here, so only one of them is worth searching over.
func _sites_by_route_set() -> Dictionary:
	var masks := {}
	var index := 0
	for branch in branches:
		for route: Array in branch.routes:
			for key: Vector3i in route:
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
