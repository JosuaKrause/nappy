class_name CityGenerator
extends RefCounted
## Builds a CityMap deterministically from a run seed. See docs/CITY.md.
##
## Pure data, no nodes, so a test can hammer it across hundreds of seeds headlessly.
##
## The street lattice is never cut — alleys, plazas and the home are carved *inside*
## blocks. That is what guarantees the "at least two distinct routes to every park"
## property from docs/CITY.md by construction rather than by search: a full lattice cannot
## be disconnected by removing any single corridor.

## How many seeds to try before accepting a map that fails the soft guarantees.
const MAX_ATTEMPTS := 64

const _DISTRICT_TARGETS := {
	GameEnums.District.CIVIC: 2,
	GameEnums.District.COMMERCIAL: 8,
	GameEnums.District.INDUSTRIAL: 6,
}

## Generates a city, retrying with adjacent seeds until the guarantees hold.
static func generate(seed_value: int) -> CityMap:
	var last: CityMap = null
	for attempt in MAX_ATTEMPTS:
		var map := _attempt(seed_value + attempt)
		last = map
		if validate(map) == "":
			return map
	push_warning("CityGenerator: no seed near %d satisfied every guarantee (%s)"
			% [seed_value, validate(last)])
	return last

static func _attempt(seed_value: int) -> CityMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var map := CityMap.new()
	map.seed_used = seed_value

	_lay_streets(map)
	var districts := _assign_districts(map, rng)
	var block_rects := _build_blocks(map, districts, rng)
	_place_home(map, districts, block_rects, rng)

	for rects in block_rects.values():
		map.building_rects.append_array(rects)
	return map

# ------------------------------------------------------------------ streets ---

static func _lay_streets(map: CityMap) -> void:
	for y in map.size.y:
		var y_offset := CityMap.corridor_offset(y)
		for x in map.size.x:
			var x_offset := CityMap.corridor_offset(x)
			if x_offset < 0 and y_offset < 0:
				map.set_tile(Vector2i(x, y), GameEnums.TileType.BUILDING)
			else:
				map.set_tile(Vector2i(x, y), _street_tile(x_offset, y_offset))

## Sidewalk | road | sidewalk across a corridor. Where a road crosses the *other*
## corridor's sidewalk band you get a pedestrian crossing, which is exactly where a
## crossing belongs.
static func _street_tile(x_offset: int, y_offset: int) -> GameEnums.TileType:
	var x_road := x_offset >= 0 and _is_road_offset(x_offset)
	var y_road := y_offset >= 0 and _is_road_offset(y_offset)

	if x_offset >= 0 and y_offset >= 0:
		if x_road and y_road:
			return GameEnums.TileType.ROAD
		if x_road or y_road:
			return GameEnums.TileType.CROSSING
		return GameEnums.TileType.SIDEWALK

	return GameEnums.TileType.ROAD if (x_road or y_road) else GameEnums.TileType.SIDEWALK

static func _is_road_offset(offset: int) -> bool:
	return offset >= Tuning.SIDEWALK_WIDTH and offset < Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH

# ---------------------------------------------------------------- districts ---

static func _assign_districts(map: CityMap, rng: RandomNumberGenerator) -> Dictionary:
	var blocks: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			blocks.append(Vector2i(x, y))

	var shuffled := blocks.duplicate()
	_shuffle(shuffled, rng)

	var districts := {}
	# Parks first, and never side by side, so the calm is spread across the map.
	var park_target := rng.randi_range(Tuning.MIN_PARK_DISTRICTS, Tuning.MAX_PARK_DISTRICTS)
	for block in shuffled:
		if districts.size() >= park_target:
			break
		if _has_park_neighbour(districts, block):
			continue
		districts[block] = GameEnums.District.PARK
		map.park_blocks.append(block)

	var remaining: Array[Vector2i] = []
	for block in shuffled:
		if not districts.has(block):
			remaining.append(block)

	var index := 0
	for district in _DISTRICT_TARGETS:
		for i in _DISTRICT_TARGETS[district]:
			if index >= remaining.size():
				break
			districts[remaining[index]] = district
			index += 1
	while index < remaining.size():
		districts[remaining[index]] = GameEnums.District.RESIDENTIAL
		index += 1

	map.districts = districts
	return districts

static func _has_park_neighbour(districts: Dictionary, block: Vector2i) -> bool:
	for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if districts.get(block + step, -1) == GameEnums.District.PARK:
			return true
	return false

static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = array[i]
		array[i] = array[j]
		array[j] = swap

# ------------------------------------------------------------------- blocks ---

## Fills every block and returns the building rects it left behind, keyed by block, so the
## home can be carved out of its block afterwards without re-deriving anything.
static func _build_blocks(map: CityMap, districts: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var block_rects := {}
	# Iterate in a fixed order; `districts` is keyed by an unordered shuffle.
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			block_rects[block] = _build_block(map, block, districts[block], rng)
	return block_rects

static func _build_block(map: CityMap, block: Vector2i, district: GameEnums.District,
		rng: RandomNumberGenerator) -> Array[Rect2i]:
	var lot := CityMap.block_rect(block)

	if district == GameEnums.District.PARK:
		map.fill_rect(lot, GameEnums.TileType.PARK)
		var playground := _inset_rect(lot, 3, rng)
		map.fill_rect(playground, GameEnums.TileType.PLAYGROUND)
		map.playgrounds.append(playground)
		return []

	map.fill_rect(lot, GameEnums.TileType.BUILDING)
	var rects: Array[Rect2i] = [lot]

	if district == GameEnums.District.COMMERCIAL:
		var square := _corner_rect(lot, Tuning.SQUARE_SIZE_TILES, rng)
		map.fill_rect(square, GameEnums.TileType.SQUARE)
		map.square_rects.append(square)
		rects = _subtract_all(rects, square)

	if rng.randf() < float(Tuning.ALLEY_CHANCE[district]):
		var alley := _alley_rect(lot, rng)
		map.fill_rect(alley, GameEnums.TileType.ALLEY)
		map.alley_rects.append(alley)
		rects = _subtract_all(rects, alley)

	return _keep_nonempty(rects)

## A rect of `size` tiles somewhere inside `lot`, never touching its edge.
static func _inset_rect(lot: Rect2i, size: int, rng: RandomNumberGenerator) -> Rect2i:
	var span := lot.size.x - size - 2
	var offset := Vector2i(rng.randi_range(1, maxi(1, span)), rng.randi_range(1, maxi(1, span)))
	return Rect2i(lot.position + offset, Vector2i.ONE * size)

## A rect of `size` tiles pinned to one of the lot's four corners, so it opens onto the
## streets on two sides.
static func _corner_rect(lot: Rect2i, size: int, rng: RandomNumberGenerator) -> Rect2i:
	var right := rng.randf() < 0.5
	var bottom := rng.randf() < 0.5
	var position := lot.position
	if right:
		position.x = lot.end.x - size
	if bottom:
		position.y = lot.end.y - size
	return Rect2i(position, Vector2i.ONE * size)

## A through-alley spanning the lot, leaving at least two tiles of building either side.
static func _alley_rect(lot: Rect2i, rng: RandomNumberGenerator) -> Rect2i:
	var width := Tuning.ALLEY_WIDTH_TILES
	var offset := rng.randi_range(2, maxi(2, lot.size.x - width - 2))
	if rng.randf() < 0.5:
		return Rect2i(Vector2i(lot.position.x + offset, lot.position.y),
				Vector2i(width, lot.size.y))
	return Rect2i(Vector2i(lot.position.x, lot.position.y + offset),
			Vector2i(lot.size.x, width))

## Every non-degenerate piece is kept, including one-tile slivers left beside a hole.
## Dropping them instead would leave BUILDING tiles with no Building node over them — an
## invisible wall the player walks straight through. A sliver renders as a low wall, which
## is what a 32px-wide building should look like anyway.
static func _keep_nonempty(rects: Array[Rect2i]) -> Array[Rect2i]:
	var kept: Array[Rect2i] = []
	for rect in rects:
		if rect.size.x > 0 and rect.size.y > 0:
			kept.append(rect)
	return kept

# ---------------------------------------------------------- rect subtraction ---

static func _subtract_all(rects: Array[Rect2i], hole: Rect2i) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for rect in rects:
		result.append_array(_subtract(rect, hole))
	return result

## `outer` minus `hole`, as up to four rects: a band above, a band below, then the left and
## right slivers of the row the hole occupies.
static func _subtract(outer: Rect2i, hole: Rect2i) -> Array[Rect2i]:
	if not outer.intersects(hole):
		return [outer]
	var overlap := outer.intersection(hole)
	var pieces: Array[Rect2i] = []

	if overlap.position.y > outer.position.y:
		pieces.append(Rect2i(outer.position,
				Vector2i(outer.size.x, overlap.position.y - outer.position.y)))
	if overlap.end.y < outer.end.y:
		pieces.append(Rect2i(Vector2i(outer.position.x, overlap.end.y),
				Vector2i(outer.size.x, outer.end.y - overlap.end.y)))
	if overlap.position.x > outer.position.x:
		pieces.append(Rect2i(Vector2i(outer.position.x, overlap.position.y),
				Vector2i(overlap.position.x - outer.position.x, overlap.size.y)))
	if overlap.end.x < outer.end.x:
		pieces.append(Rect2i(Vector2i(overlap.end.x, overlap.position.y),
				Vector2i(outer.end.x - overlap.end.x, overlap.size.y)))
	return pieces

# --------------------------------------------------------------------- home ---

## Picks the most central residential block that is still a long walk from any park, then
## notches the home into its south edge.
##
## The distance test runs on a single multi-source sweep out from every park tile, taken
## before the home exists — so no candidate has to be carved and un-carved to be measured.
static func _place_home(map: CityMap, districts: Dictionary, block_rects: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var from_parks := map.walk_distances_from(map.park_tiles())
	var centre := Vector2(Tuning.CITY_BLOCKS - Vector2i.ONE) * 0.5

	var candidates: Array[Vector2i] = []
	for block in block_rects:
		if districts[block] == GameEnums.District.RESIDENTIAL:
			candidates.append(block)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a).distance_squared_to(centre) < Vector2(b).distance_squared_to(centre))

	var fallback := Vector2i.ZERO
	var fallback_distance := -1
	for block in candidates:
		var home := _home_rect(map, block)
		var distance := _distance_to_parks(map, from_parks, home)
		if distance >= Tuning.MIN_HOME_TO_PARK_TILES:
			_carve_home(map, block_rects, block, home)
			return
		if distance > fallback_distance:
			fallback_distance = distance
			fallback = block

	# No block was far enough; take the furthest one and let validate() report it.
	_carve_home(map, block_rects, fallback, _home_rect(map, fallback))

## The home notch: `HOME_SIZE_TILES` in the south edge of the lot, slid sideways if that
## would land it in an alley.
static func _home_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var lot := CityMap.block_rect(block)
	var size := Tuning.HOME_SIZE_TILES
	var top_left := Vector2i(lot.position.x + (lot.size.x - size.x) / 2, lot.end.y - size.y)
	for shift in range(0, lot.size.x - size.x):
		# Alternate right and left of centre until the notch clears any alley.
		var offset: int = (shift + 1) / 2 * (1 if shift % 2 == 0 else -1)
		var candidate := Rect2i(top_left + Vector2i(offset, 0), size)
		if not lot.encloses(candidate):
			continue
		if _is_all_building(map, candidate):
			return candidate
	return Rect2i(top_left, size)

static func _is_all_building(map: CityMap, rect: Rect2i) -> bool:
	for tile in map.rect_tiles(rect):
		if map.tile_at(tile) != GameEnums.TileType.BUILDING:
			return false
	return true

static func _distance_to_parks(map: CityMap, from_parks: Dictionary, home: Rect2i) -> int:
	# The home opens onto the sidewalk directly south of it.
	var doorstep := Vector2i(home.position.x, home.end.y)
	if not from_parks.has(doorstep):
		return -1
	return int(from_parks[doorstep]) + 1

static func _carve_home(map: CityMap, block_rects: Dictionary, block: Vector2i,
		home: Rect2i) -> void:
	map.fill_rect(home, GameEnums.TileType.HOME)
	map.home_rect = home
	block_rects[block] = _keep_nonempty(_subtract_all(block_rects[block], home))

# --------------------------------------------------------------- validation ---

## Returns "" when the map satisfies every guarantee in docs/CITY.md, else why it does not.
static func validate(map: CityMap) -> String:
	if map.home_rect.size == Vector2i.ZERO:
		return "no home was placed"

	var reachable := map.walk_distances(map.home_rect.position)
	if reachable.size() != map.count_walkable():
		return "%d of %d walkable tiles are cut off from the home" % [
			map.count_walkable() - reachable.size(), map.count_walkable()]

	if map.park_blocks.size() < Tuning.MIN_PARK_DISTRICTS:
		return "only %d park districts, need %d" % [
			map.park_blocks.size(), Tuning.MIN_PARK_DISTRICTS]

	for block in map.park_blocks:
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			if block + step in map.park_blocks:
				return "park districts %s and %s are adjacent" % [block, block + step]

	var park_distance := map.home_to_nearest_park()
	if park_distance < Tuning.MIN_HOME_TO_PARK_TILES:
		return "home is only %d tiles from a park, need %d" % [
			park_distance, Tuning.MIN_HOME_TO_PARK_TILES]

	return ""
