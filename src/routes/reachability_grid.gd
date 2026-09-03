class_name ReachabilityGrid
extends RefCounted
## The tile graph, contracted into two-tile-square cells: the reachability answer everything in
## this file used to ask by hand — a park's frontage, a courtyard's one archway, an alley's width
## as a connection count — falls out of the tiles instead.
##
## See docs/TODO.md, M69, "The cell is two tiles square, not three" and "A cell is not one node —
## its contents decide which of its sides connect". Two tiles because two divides `BLOCK_SIZE` (8),
## `STREET_WIDTH` (6) and their period (14) exactly, so every cell is wholly street or wholly block;
## three divides none of them.
##
## **A cell contributes one node per 4-connected component of its own walkable tiles.** A cell
## holds four tiles, so a sliver building with open ground either side of it touches two sides and
## not four, and a whole-cell node would walk straight through a real wall. Sixteen masks, and only
## the two diagonal ones (`NW+SE`, `NE+SW`) split into two components that do not connect to each
## other.
##
## **This is the tile graph contracted, not a coarser approximation of it.** `flood()` with no
## `blocked` tiles agrees with `CityMap.walk_field` exactly, over every seed
## `tests/test_reachability_grid.gd` sweeps — that agreement is the whole of what "contracted" is
## allowed to mean.
##
## **A query may hand in extra blocked tiles** — a candidate closure's barrier, an event's
## obstruction circle — that the grid was not built with. Rebuilding the whole grid per query would
## throw away the point of contracting it, so a query instead treats only the cells the blocked
## tiles actually touch at **tile** granularity, falling back to the same tile-by-tile adjacency
## `CityMap.walk_field` uses there, and everything else at the cheaper cell granularity. That is
## what keeps a diagonal split correct even when nothing at build time could have predicted it: a
## blocked tile can turn a cell that started as one component into two, and a query only has to get
## that right for the handful of cells the blocking actually reaches.

## Local tile slots within a cell.
const _NW := 0
const _NE := 1
const _SW := 2
const _SE := 3
## Which pairs of local slots are 4-adjacent. `NW`-`SE` and `NE`-`SW` are the two diagonals and are
## deliberately absent: they are the two masks that split into two components.
const _ADJACENT_LOCAL := [[_NW, _NE], [_NW, _SW], [_NE, _SE], [_SW, _SE]]

## Every tile's offset from its cell's origin, in slot order.
const _SLOT_OFFSET: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

const CELL := 2

## Keys above this are a specific tile inside a cell a query has marked dirty, rather than a node
## id. Comfortably above any node id or flat tile index this project's map sizes produce.
const _TILE_KEY_OFFSET := 1 << 24
const NONE := -1

var _map_size := Vector2i.ZERO
var _cells := Vector2i.ZERO
## tile flat index -> node id, or -1 where the tile is not walkable.
var _node_of_tile: PackedInt32Array
## node id -> cell coordinate it belongs to.
var _cell_of_node: Array[Vector2i] = []
## node id -> Array of `[neighbour node id, tile in this node, tile in the neighbour]`. Both
## directions of a boundary are stored whenever both exist, deliberately not deduplicated to one
## per node pair — a query that finds one of the two tiles blocked still has the other.
var _edges: Array = []

## The sixteen-entry lookup from a cell's walkable mask to its components, each a list of local
## slots. Built once, lazily, and shared by every grid — it depends on nothing but the geometry of
## a 2x2 square.
static var _mask_components: Array = []

static func _components_of_mask(mask: int) -> Array:
	if _mask_components.is_empty():
		_mask_components.resize(16)
		for candidate in 16:
			_mask_components[candidate] = _compute_components(candidate)
	return _mask_components[mask]

static func _compute_components(mask: int) -> Array:
	var present: Array[int] = []
	for slot in 4:
		if mask & (1 << slot) != 0:
			present.append(slot)
	var assigned := {}
	var components: Array = []
	for start in present:
		if assigned.has(start):
			continue
		var component: Array[int] = []
		var stack: Array[int] = [start]
		assigned[start] = true
		while not stack.is_empty():
			var slot: int = stack.pop_back()
			component.append(slot)
			for pair in _ADJACENT_LOCAL:
				var other := -1
				if pair[0] == slot:
					other = pair[1]
				elif pair[1] == slot:
					other = pair[0]
				if other >= 0 and present.has(other) and not assigned.has(other):
					assigned[other] = true
					stack.append(other)
		components.append(component)
	return components

## Builds the grid from a day's tiles. Cheap enough to do once a day: every cell is a handful of
## `is_walkable` lookups and the edges are found once, not searched per query.
static func build(map: CityMap) -> ReachabilityGrid:
	var grid := ReachabilityGrid.new()
	grid._map_size = map.size
	grid._cells = map.size / CELL
	var tile_count := map.size.x * map.size.y
	grid._node_of_tile = PackedInt32Array()
	grid._node_of_tile.resize(tile_count)
	grid._node_of_tile.fill(NONE)

	for cy in grid._cells.y:
		for cx in grid._cells.x:
			var cell := Vector2i(cx, cy)
			var origin := cell * CELL
			var mask := 0
			var tiles: Array[Vector2i] = []
			for slot in 4:
				var tile := origin + _SLOT_OFFSET[slot]
				tiles.append(tile)
				if map.is_walkable(tile):
					mask |= 1 << slot
			for component in _components_of_mask(mask):
				var node := grid._edges.size()
				grid._edges.append([])
				grid._cell_of_node.append(cell)
				for slot in component:
					var tile: Vector2i = tiles[slot]
					grid._node_of_tile[tile.y * map.size.x + tile.x] = node
	grid._build_edges()
	return grid

func _build_edges() -> void:
	for cy in _cells.y:
		for cx in _cells.x:
			var origin := Vector2i(cx, cy) * CELL
			if cx + 1 < _cells.x:
				_maybe_edge(origin + Vector2i(1, 0), origin + Vector2i(2, 0))
				_maybe_edge(origin + Vector2i(1, 1), origin + Vector2i(2, 1))
			if cy + 1 < _cells.y:
				_maybe_edge(origin + Vector2i(0, 1), origin + Vector2i(0, 2))
				_maybe_edge(origin + Vector2i(1, 1), origin + Vector2i(1, 2))

## Records both directions of one boundary tile-pair, whenever both tiles are walkable. Not
## deduplicated against the cell's other boundary tile-pair, if it has one — see the class doc on
## why a query needs both kept separately.
func _maybe_edge(a: Vector2i, b: Vector2i) -> void:
	var na := node_at(a)
	var nb := node_at(b)
	if na < 0 or nb < 0:
		return
	_edges[na].append([nb, a, b])
	_edges[nb].append([na, b, a])

# ------------------------------------------------------------------------ base ---

func node_count() -> int:
	return _edges.size()

## The node a tile belongs to, or `NONE` when the tile is not walkable or out of bounds.
func node_at(tile: Vector2i) -> int:
	if tile.x < 0 or tile.y < 0 or tile.x >= _map_size.x or tile.y >= _map_size.y:
		return NONE
	return _node_of_tile[tile.y * _map_size.x + tile.x]

## The cell a node belongs to. Any tile of it resolves the same cell, since a cell is never split
## across a segment or a block boundary — see docs/TODO.md, "The cell is two tiles square".
func cell_of(node: int) -> Vector2i:
	return _cell_of_node[node]

## A tile belonging to a node, for translating a route back to the streets it touches. Any tile
## does, since `StreetNetwork.segment_containing` answers the same way for every tile of one cell.
func any_tile_of(node: int) -> Vector2i:
	return cell_of(node) * CELL

## The base neighbours of a node: `[neighbour node id, tile in this node, tile in the neighbour]`
## for every boundary tile pair. Used by `RouteTree`'s own walk, which grows on the grid as it is —
## today's closures are never in it, because the tree is grown before they are chosen.
func neighbours(node: int) -> Array:
	return _edges[node]

# ---------------------------------------------------------------------- queries ---

func _cell_of_tile(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / CELL), floori(float(tile.y) / CELL))

func _dirty_cells(blocked: Dictionary) -> Dictionary:
	var dirty := {}
	for tile: Vector2i in blocked:
		dirty[_cell_of_tile(tile)] = true
	return dirty

## The key a tile answers to for this query: its base node id where the query leaves its cell
## alone, or a key naming the tile itself where the cell is dirty — a cell touched by at least one
## blocked tile of this query, and therefore not safe to answer for at the cached, unblocked
## resolution.
func _key_of(tile: Vector2i, blocked: Dictionary, dirty: Dictionary) -> int:
	if blocked.has(tile):
		return NONE
	var node := node_at(tile)
	if node < 0:
		return NONE
	if dirty.has(_cell_of_tile(tile)):
		return _TILE_KEY_OFFSET + tile.y * _map_size.x + tile.x
	return node

func _neighbours_of_key(key: int, blocked: Dictionary, dirty: Dictionary) -> Array[int]:
	var found: Array[int] = []
	if key >= _TILE_KEY_OFFSET:
		var flat := key - _TILE_KEY_OFFSET
		var tile := Vector2i(flat % _map_size.x, flat / _map_size.x)
		for offset in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var neighbour := _key_of(tile + offset, blocked, dirty)
			if neighbour != NONE:
				found.append(neighbour)
		return found
	for edge: Array in _edges[key]:
		var tile_there: Vector2i = edge[2]
		if dirty.has(_cell_of_tile(tile_there)):
			var neighbour := _key_of(tile_there, blocked, dirty)
			if neighbour != NONE:
				found.append(neighbour)
		else:
			found.append(edge[0] as int)
	return found

## Every tile reached from `sources`, as the set of query keys a caller hands to `reaches()`.
## `blocked` is on top of the day's own walkable tiles, never instead of them — a closure's
## barrier, an event's obstruction circle, whatever the caller is asking "what if this were gone"
## about.
func flood(sources: Array, blocked: Dictionary = {}) -> Dictionary:
	var dirty := _dirty_cells(blocked)
	var reached := {}
	var queue: Array[int] = []
	for source in sources:
		var key := _key_of(source, blocked, dirty)
		if key != NONE and not reached.has(key):
			reached[key] = true
			queue.append(key)
	var head := 0
	while head < queue.size():
		var key: int = queue[head]
		head += 1
		for neighbour in _neighbours_of_key(key, blocked, dirty):
			if not reached.has(neighbour):
				reached[neighbour] = true
				queue.append(neighbour)
	return reached

## Whether `tile` is in a `reached` set `flood()` returned for the **same** `blocked` dictionary.
func reaches(tile: Vector2i, blocked: Dictionary, reached: Dictionary) -> bool:
	var dirty := _dirty_cells(blocked)
	var key := _key_of(tile, blocked, dirty)
	return key != NONE and reached.has(key)
