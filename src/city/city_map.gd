class_name CityMap
extends RefCounted
## The generated city as data: a tile grid plus the derived features the renderer, the
## event scheduler and the tests all need. No nodes, no drawing — so it can be generated
## and validated headlessly across hundreds of seeds.
##
## Tile layout, per axis:
##
##     |<- street ->|<--- block --->|<- street ->|<--- block --->| ...
##      0         5   6          13   14      19   20         27
##
## so a coordinate's position within its period tells you which it is.

var size: Vector2i
var tiles: PackedByteArray
## Block coordinate -> BlockPlan. The arc each block may travel, fixed at generation.
var block_plans := {}
## Block coordinate -> BlockLayout. The carves, also fixed at generation.
var block_layouts := {}
var building_rects: Array[Rect2i] = []
## Blocks that are calm ground *right now*. Recomputed by `repaint()`, because which ground
## is calm is the thing that changes over a run.
var calm_blocks: Array[Vector2i] = []
## Tile rect of each playground currently in the city. A requisitioned park has none.
var playgrounds: Array[Rect2i] = []
var home_block := Vector2i.ZERO
var alley_rects: Array[Rect2i] = []
var square_rects: Array[Rect2i] = []
var courtyard_rects: Array[Rect2i] = []
var home_rect := Rect2i()
var seed_used := 0

# ------------------------------------------------------------------ layout ---

## Tiles between the start of one street corridor and the start of the next.
static func period() -> int:
	return Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH

## Full map size in tiles: a street corridor on every side of every block.
static func map_tiles() -> Vector2i:
	return Vector2i.ONE * Tuning.STREET_WIDTH + Tuning.CITY_BLOCKS * period()

## Tile rect of a block's interior (not counting the streets around it).
static func block_rect(block: Vector2i) -> Rect2i:
	return Rect2i(Vector2i.ONE * Tuning.STREET_WIDTH + block * period(),
			Vector2i.ONE * Tuning.BLOCK_SIZE)

## Position within the current period, or -1 when the coordinate is inside a block.
static func corridor_offset(coordinate: int) -> int:
	var offset := posmod(coordinate, period())
	return offset if offset < Tuning.STREET_WIDTH else -1

## Whether a corridor offset lands on the carriageway rather than the pavement.
## Layout across a corridor is sidewalk | road | sidewalk.
static func is_road_offset(offset: int) -> bool:
	return offset >= Tuning.SIDEWALK_WIDTH \
			and offset < Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH

# ------------------------------------------------------------------- tiles ---

func _init(map_size: Vector2i = map_tiles()) -> void:
	size = map_size
	tiles = PackedByteArray()
	tiles.resize(size.x * size.y)

func in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < size.x and tile.y < size.y

func tile_at(tile: Vector2i) -> GameEnums.TileType:
	if not in_bounds(tile):
		return GameEnums.TileType.BUILDING
	return tiles[tile.y * size.x + tile.x] as GameEnums.TileType

func set_tile(tile: Vector2i, type: GameEnums.TileType) -> void:
	if in_bounds(tile):
		tiles[tile.y * size.x + tile.x] = type

func fill_rect(rect: Rect2i, type: GameEnums.TileType) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			set_tile(Vector2i(x, y), type)

func is_walkable(tile: Vector2i) -> bool:
	return Tile.is_walkable(tile_at(tile))

# --------------------------------------------------------------- conversion ---

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / Tuning.TILE_SIZE),
			floori(world_position.y / Tuning.TILE_SIZE))

## Centre of a tile in world space.
func tile_to_world(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * Tuning.TILE_SIZE

func tile_rect_to_world(rect: Rect2i) -> Rect2:
	return Rect2(Vector2(rect.position) * Tuning.TILE_SIZE,
			Vector2(rect.size) * Tuning.TILE_SIZE)

func world_size() -> Vector2:
	return Vector2(size) * Tuning.TILE_SIZE

func tile_type_at_world(world_position: Vector2) -> GameEnums.TileType:
	return tile_at(world_to_tile(world_position))

func home_world_position() -> Vector2:
	return tile_rect_to_world(home_rect).get_center()

## Where a day starts and ends: the pavement outside the front door, not the doorway
## itself. Spawning in the doorway drew her standing on top of the door.
func doorstep_world_position() -> Vector2:
	var tile := Vector2i(home_rect.position.x, home_rect.end.y)
	var beside := tile + Vector2i.RIGHT
	if is_walkable(beside):
		return (tile_to_world(tile) + tile_to_world(beside)) * 0.5
	return tile_to_world(tile)

# ------------------------------------------------------------ block purpose ---

## What a block was generated as. Fixed for the run — building heights, alley chances and
## the resistance's placements all key off this rather than off today's purpose.
func starting_purpose(block: Vector2i) -> GameEnums.BlockPurpose:
	var plan: BlockPlan = block_plans.get(block)
	return plan.starting_purpose() if plan else GameEnums.BlockPurpose.RESIDENTIAL

## The block nearest a world position. Events happen on streets, between blocks, so "which
## block did this happen to" is nearest-centre rather than containment.
func block_at(world_position: Vector2) -> Vector2i:
	var best := Vector2i.ZERO
	var closest := INF
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			var centre := tile_rect_to_world(block_rect(block)).get_center()
			var distance := centre.distance_squared_to(world_position)
			if distance < closest:
				closest = distance
				best = block
	return best

## Repaints every block interior for the purposes `state` currently holds, and re-derives
## the things that follow from them.
##
## This is the change M15 makes to the old "the CityMap is immutable for the run" rule. The
## street lattice, the block boundaries, the carves and the building footprints are all
## still fixed — this only ever swaps the *ground* inside a block's open rect, so no repaint
## can disconnect the city or make a wall appear where a route used to be. What changes is
## what a place is worth walking to.
func repaint(state: CityState) -> void:
	for block: Vector2i in block_plans:
		_repaint_block(block, state.purpose_of(block_plans, block))
	# The home notch is carved out of a block interior, so it has to go back on top.
	if home_rect.size != Vector2i.ZERO:
		fill_rect(home_rect, GameEnums.TileType.HOME)
	_tiles_by_type.clear()
	_recompute_calm(state)

func _repaint_block(block: Vector2i, purpose: GameEnums.BlockPurpose) -> void:
	var layout: BlockLayout = block_layouts.get(block)
	if not layout:
		return
	fill_rect(block_rect(block), GameEnums.TileType.BUILDING)
	if BlockLayout.has(layout.open_rect):
		fill_rect(layout.open_rect, open_tile_for(purpose))
	if purpose == GameEnums.BlockPurpose.PARK and BlockLayout.has(layout.playground):
		fill_rect(layout.playground, GameEnums.TileType.PLAYGROUND)
	if BlockLayout.has(layout.square):
		fill_rect(layout.square, GameEnums.TileType.SQUARE)
	if BlockLayout.has(layout.alley):
		fill_rect(layout.alley, GameEnums.TileType.ALLEY)
	if BlockLayout.has(layout.passage):
		fill_rect(layout.passage, GameEnums.TileType.ALLEY)

## The ground a purpose puts in its open rect. Everything degraded lands on `SPOILED`,
## which is the whole idea: the same ground, no longer worth walking to.
static func open_tile_for(purpose: GameEnums.BlockPurpose) -> GameEnums.TileType:
	match purpose:
		GameEnums.BlockPurpose.PARK:
			return GameEnums.TileType.PARK
		GameEnums.BlockPurpose.FOREST:
			return GameEnums.TileType.FOREST
		GameEnums.BlockPurpose.QUIET_SQUARE:
			return GameEnums.TileType.QUIET_SQUARE
		GameEnums.BlockPurpose.COURTYARD:
			return GameEnums.TileType.COURTYARD
		_:
			return GameEnums.TileType.SPOILED

func _recompute_calm(state: CityState) -> void:
	calm_blocks = state.calm_blocks(block_plans)
	playgrounds.clear()
	for block in calm_blocks:
		if state.purpose_of(block_plans, block) != GameEnums.BlockPurpose.PARK:
			continue
		var layout: BlockLayout = block_layouts.get(block)
		if layout and BlockLayout.has(layout.playground):
			playgrounds.append(layout.playground)

# --------------------------------------------------------------- traversal ---

const _NEIGHBOURS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## Walking distance in tiles from `from` to every reachable walkable tile.
## Unreachable tiles are absent from the result.
func walk_distances(from: Vector2i, blocked: Dictionary = {}) -> Dictionary:
	return walk_distances_from([from], blocked)

## Multi-source version: distance to the nearest of `sources`. One sweep answers
## "how far is the nearest park from anywhere", which is how the home is placed.
func walk_distances_from(sources: Array, blocked: Dictionary = {}) -> Dictionary:
	var distances := {}
	var queue: Array[Vector2i] = []
	for source in sources:
		var tile: Vector2i = source
		if not is_walkable(tile) or blocked.has(tile) or distances.has(tile):
			continue
		distances[tile] = 0
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var next_distance: int = distances[current] + 1
		for step in _NEIGHBOURS:
			var neighbour: Vector2i = current + step
			if distances.has(neighbour) or blocked.has(neighbour):
				continue
			if not is_walkable(neighbour):
				continue
			distances[neighbour] = next_distance
			queue.append(neighbour)
	return distances

func count_walkable() -> int:
	var total := 0
	for index in tiles.size():
		if Tile.is_walkable(tiles[index] as GameEnums.TileType):
			total += 1
	return total

## Every calm tile in the city right now. Since M14 this is the only ground a day can be
## won on, so it is what "how hard is today" actually means.
func calm_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			if Tile.is_calm(tile_at(tile)):
				result.append(tile)
	return result

## Shortest walking distance from the home to any calm tile, or -1 if unreachable.
func home_to_nearest_calm() -> int:
	var distances := walk_distances_from(calm_tiles())
	var best := -1
	for tile in rect_tiles(home_rect):
		if distances.has(tile):
			var distance: int = distances[tile]
			if best == -1 or distance < best:
				best = distance
	return best

## Walkable tiles immediately outside a block — its pavement, effectively. Used to place
## things "at" a district when the district itself is solid building.
func perimeter_tiles(block: Vector2i) -> Array[Vector2i]:
	var lot := block_rect(block)
	var found: Array[Vector2i] = []
	for x in range(lot.position.x - 1, lot.end.x + 1):
		for y in [lot.position.y - 1, lot.end.y]:
			var tile := Vector2i(x, y)
			if is_walkable(tile):
				found.append(tile)
	for y in range(lot.position.y, lot.end.y):
		for x in [lot.position.x - 1, lot.end.x]:
			var tile := Vector2i(x, y)
			if is_walkable(tile):
				found.append(tile)
	return found

## Every walkable tile in or around the blocks that *started* as this purpose. Generation-
## time identity, not today's: the resistance's "a civic block" means the one that was built
## as a ministry, whatever has since happened to it.
func purpose_tiles(purpose: GameEnums.BlockPurpose) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for block: Vector2i in block_plans:
		if starting_purpose(block) != purpose:
			continue
		for tile in rect_tiles(block_rect(block)):
			if is_walkable(tile):
				found.append(tile)
		found.append_array(perimeter_tiles(block))
	return found

## Every tile of a given type. Cached, since the scheduler samples these every day.
func tiles_of_type(type: GameEnums.TileType) -> Array[Vector2i]:
	if _tiles_by_type.has(type):
		return _tiles_by_type[type]
	var found: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if tile_at(Vector2i(x, y)) == type:
				found.append(Vector2i(x, y))
	_tiles_by_type[type] = found
	return found

var _tiles_by_type := {}

func rect_tiles(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			result.append(Vector2i(x, y))
	return result
