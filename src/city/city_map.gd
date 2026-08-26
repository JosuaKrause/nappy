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
## Block coordinate -> GameEnums.District.
var districts := {}
var building_rects: Array[Rect2i] = []
var park_blocks: Array[Vector2i] = []
## Tile rect of each playground, one per park block.
var playgrounds: Array[Rect2i] = []
var alley_rects: Array[Rect2i] = []
var square_rects: Array[Rect2i] = []
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

## Every tile belonging to any park block.
func park_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for block in park_blocks:
		result.append_array(rect_tiles(block_rect(block)))
	return result

## Shortest walking distance from the home to any park tile, or -1 if unreachable.
func home_to_nearest_park() -> int:
	var distances := walk_distances_from(park_tiles())
	var best := -1
	for tile in rect_tiles(home_rect):
		if distances.has(tile):
			var distance: int = distances[tile]
			if best == -1 or distance < best:
				best = distance
	return best

func rect_tiles(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			result.append(Vector2i(x, y))
	return result
