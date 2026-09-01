class_name StreetNetwork
extends RefCounted
## The street lattice as a graph: junctions, and the segments of street between them.
##
## The tile grid answers "may I stand here". This answers "can I get there, and is there more than
## one way" — the question a day's closures are validated against. It is a couple of hundred
## junctions and segments rather than ten thousand tiles, so validating a whole day costs less than
## a single tile-level flood fill.
##
## Nothing here knows what is closed or what is calm. The lattice is fixed for the run; what
## today has done to it arrives as a set of segment keys.

## One street, from one junction to the next: the frontage of the blocks either side of it.
##
## A segment is the unit a closure works in. Closing half a street would be a closure the
## player cannot see the shape of, and closing a whole corridor would remove a route rather
## than narrow the choice.
class Segment extends RefCounted:
	## The lower-numbered of the two junctions it joins.
	var a: Vector2i
	var b: Vector2i
	var horizontal: bool

	func _init(from: Vector2i, runs_horizontal: bool) -> void:
		a = from
		horizontal = runs_horizontal
		b = from + (Vector2i.RIGHT if runs_horizontal else Vector2i.DOWN)

	## Hashable identity, for the "closed today" set.
	func key() -> Vector3i:
		return Vector3i(a.x, a.y, 0 if horizontal else 1)

	## The tiles between the two junctions: one block long, one corridor wide.
	func tile_rect() -> Rect2i:
		var origin := a * CityMap.period()
		if horizontal:
			return Rect2i(origin + Vector2i(Tuning.STREET_WIDTH, 0),
					Vector2i(Tuning.BLOCK_SIZE, Tuning.STREET_WIDTH))
		return Rect2i(origin + Vector2i(0, Tuning.STREET_WIDTH),
				Vector2i(Tuning.STREET_WIDTH, Tuning.BLOCK_SIZE))

	## The one-tile strip where the street meets the junction at one of its ends. A closure
	## is sealed here rather than in the middle of the street, so that it is visible from
	## the junction — which is the last moment the player can still choose another way.
	func mouth_rect(at_a: bool) -> Rect2i:
		var rect := tile_rect()
		if horizontal:
			var x: int = rect.position.x if at_a else rect.end.x - 1
			return Rect2i(Vector2i(x, rect.position.y), Vector2i(1, rect.size.y))
		var y: int = rect.position.y if at_a else rect.end.y - 1
		return Rect2i(Vector2i(rect.position.x, y), Vector2i(rect.size.x, 1))

	func other_end(junction: Vector2i) -> Vector2i:
		return b if junction == a else a

## Which side of a block a segment runs along.
enum Side { NORTH, SOUTH, WEST, EAST }

# ------------------------------------------------------------------ lattice ---

## Junctions per axis: one at each end of every block, so one more than there are blocks.
static func junction_count() -> Vector2i:
	return Tuning.CITY_BLOCKS + Vector2i.ONE

static func in_bounds(junction: Vector2i) -> bool:
	var count := junction_count()
	return junction.x >= 0 and junction.y >= 0 and junction.x < count.x and junction.y < count.y

## Every street in the city. Built once — the lattice never changes.
static func segments() -> Array[Segment]:
	if _segments.is_empty():
		var count := junction_count()
		for y in count.y:
			for x in count.x:
				var junction := Vector2i(x, y)
				if x < count.x - 1:
					_add(Segment.new(junction, true))
				if y < count.y - 1:
					_add(Segment.new(junction, false))
	return _segments

## The segment with this key, or null.
static func by_key(key: Vector3i) -> Segment:
	segments()
	return _by_key.get(key)

## The four streets that meet at a junction — three at an edge, two at a corner.
static func at_junction(junction: Vector2i) -> Array[Segment]:
	segments()
	var found: Array[Segment] = []
	for candidate in [
			Vector3i(junction.x, junction.y, 0), Vector3i(junction.x - 1, junction.y, 0),
			Vector3i(junction.x, junction.y, 1), Vector3i(junction.x, junction.y - 1, 1)]:
		var segment: Segment = _by_key.get(candidate)
		if segment:
			found.append(segment)
	return found

## The street running along one side of a block.
##
## `side` is an `int` and not a `Side`: an enum declared in one script and named from another
## does not compare equal to itself as a parameter type ("argument should be Side but is
## StreetNetwork.Side"), so a cross-script enum parameter has to be widened by hand.
static func beside_block(block: Vector2i, side: int) -> Segment:
	match side:
		Side.NORTH:
			return by_key(Vector3i(block.x, block.y, 0))
		Side.SOUTH:
			return by_key(Vector3i(block.x, block.y + 1, 0))
		Side.WEST:
			return by_key(Vector3i(block.x, block.y, 1))
		_:
			return by_key(Vector3i(block.x + 1, block.y, 1))

## Every street running along the outside of a rect of blocks, in a fixed order.
##
## One block has four and this is `beside_block` four times over. A four-block calm zone has
## **eight**, two to a side, because the streets between its own blocks were absorbed and are
## not there to be one of them — which is the whole reason this exists: "the ways into this calm
## area" stopped being derivable from a block coordinate the moment a calm area could be more
## than a block.
static func around_blocks(blocks: Rect2i) -> Array[Segment]:
	var found: Array[Segment] = []
	for x in range(blocks.position.x, blocks.end.x):
		_append_if_real(found, by_key(Vector3i(x, blocks.position.y, 0)))
		_append_if_real(found, by_key(Vector3i(x, blocks.end.y, 0)))
	for y in range(blocks.position.y, blocks.end.y):
		_append_if_real(found, by_key(Vector3i(blocks.position.x, y, 1)))
		_append_if_real(found, by_key(Vector3i(blocks.end.x, y, 1)))
	return found

static func _append_if_real(found: Array[Segment], segment: Segment) -> void:
	if segment:
		found.append(segment)

## The street a tile is on, or null when the tile is inside a junction or inside a block.
## A junction belongs to no street on purpose: it is where the choice is made.
static func segment_containing(tile: Vector2i) -> Segment:
	var period := CityMap.period()
	var across_x := CityMap.corridor_offset(tile.x) >= 0
	var across_y := CityMap.corridor_offset(tile.y) >= 0
	if across_x == across_y:
		return null   # a junction (both) or a block interior (neither)
	return by_key(Vector3i(floori(float(tile.x) / period), floori(float(tile.y) / period),
			1 if across_x else 0))

static var _segments: Array[Segment] = []
static var _by_key := {}

static func _add(segment: Segment) -> void:
	_segments.append(segment)
	_by_key[segment.key()] = segment

# -------------------------------------------------------------------- graph ---

## The graph node a junction is, for the traversals below.
static func node_of(junction: Vector2i) -> int:
	return junction.y * junction_count().x + junction.x

static func node_total() -> int:
	var count := junction_count()
	return count.x * count.y

## Junctions within reach of `sources`, as node -> distance in streets. `closed` is a set of
## segment keys, which is what a day does to the lattice.
static func junction_distances(sources: Array[Vector2i], closed: Dictionary) -> Dictionary:
	var links := _links()
	var distances := {}
	var queue: Array[int] = []
	for junction in sources:
		var node := node_of(junction)
		if distances.has(node):
			continue
		distances[node] = 0
		queue.append(node)
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		for link: Array in links[node]:
			if closed.has(link[1] as Vector3i) or distances.has(link[0] as int):
				continue
			distances[link[0]] = int(distances[node]) + 1
			queue.append(link[0])
	return distances

## How many distinct routes lead from the doorstep street to a calm area today, counted up
## to `cap` — asking for more than the invariant needs is wasted work.
##
## **Distinct means sharing no street.** Two routes may cross at a junction; if they run
## down the same street they are one route with a detour in it. Counting them that way is a
## unit-capacity max flow, and by Menger's theorem the answer is also *how many streets it
## would take to cut the area off*, which is the honest statement of the invariant: two
## routes means today's closures have left the player somewhere to go if one of them turns
## out to be a bad idea.
##
## Neither end of the journey is charged for its own doorstep. The source is the street the
## home opens onto — a notch with one exit, which docs/CITY.md has always exempted — and an
## area is reached by arriving at *either end* of a street it opens onto, so a courtyard
## with a single archway can still have two routes to it. The exemption is the same at both
## ends and for the same reason: a door is not a route.
static func route_count(from: Segment, access: Array[Segment], closed: Dictionary,
		cap: int = 2) -> int:
	if not from or access.is_empty():
		return 0
	var total := node_total() + 2
	var source := total - 2
	var sink := total - 1

	# Residual capacities, keyed by from * total + to. A street is one unit in each
	# direction, which is the standard reduction for edge-disjoint paths in an undirected
	# graph: a flow that used both directions of one street cancels to a flow that uses
	# neither, so the value counts streets and not lanes.
	var capacity := {}
	var links: Array = _links().duplicate()
	for segment in segments():
		if closed.has(segment.key()):
			continue
		var u := node_of(segment.a)
		var v := node_of(segment.b)
		capacity[u * total + v] = 1
		capacity[v * total + u] = 1
	links.resize(total)
	var out_of_source: Array[int] = []
	for junction in [from.a, from.b]:
		var node := node_of(junction)
		capacity[source * total + node] = 1
		out_of_source.append(node)
	links[source] = _plain_links(out_of_source)
	links[sink] = []
	for segment in access:
		if closed.has(segment.key()):
			continue
		for junction in [segment.a, segment.b]:
			var node := node_of(junction)
			if int(capacity.get(node * total + sink, 0)) > 0:
				continue
			capacity[node * total + sink] = 1
			var extended: Array = (links[node] as Array).duplicate()
			extended.append([sink, _NO_STREET])
			links[node] = extended

	var found := 0
	while found < cap and _augment(capacity, links, total, source, sink):
		found += 1
	return found

## One more unit of flow, or false when there is no way through left.
static func _augment(capacity: Dictionary, links: Array, total: int, source: int,
		sink: int) -> bool:
	var previous := {}
	previous[source] = -1
	var queue: Array[int] = [source]
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if node == sink:
			break
		for link: Array in links[node]:
			var next: int = link[0]
			if previous.has(next) or int(capacity.get(node * total + next, 0)) <= 0:
				continue
			previous[next] = node
			queue.append(next)
	if not previous.has(sink):
		return false
	var at := sink
	while at != source:
		var before: int = previous[at]
		capacity[before * total + at] = int(capacity[before * total + at]) - 1
		var back: int = at * total + before
		capacity[back] = int(capacity.get(back, 0)) + 1
		at = before
	return true

## The key on a link that stands for no street at all: the two ways out of the doorstep,
## and the last step onto calm ground. Neither can be closed, so neither is charged for.
const _NO_STREET := Vector3i(-1, -1, -1)

## Junction adjacency, as node -> [[neighbour node, segment key], ...]. Built once; the
## per-day work is all in the capacities, which is why this is worth caching.
static var _adjacency: Array = []

static func _links() -> Array:
	if _adjacency.is_empty():
		_adjacency.resize(node_total())
		for i in node_total():
			_adjacency[i] = []
		for segment in segments():
			var u := node_of(segment.a)
			var v := node_of(segment.b)
			(_adjacency[u] as Array).append([v, segment.key()])
			(_adjacency[v] as Array).append([u, segment.key()])
	return _adjacency

## Links with no street behind them, for the source's two ways out of the doorstep.
static func _plain_links(nodes: Array[int]) -> Array:
	var links: Array = []
	for node in nodes:
		links.append([node, _NO_STREET])
	return links
