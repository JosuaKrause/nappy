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

## How many of the non-calm blocks get each built purpose. Whatever is left over is
## residential, which is what most of a city is.
const _BUILT_TARGETS := {
	GameEnums.BlockPurpose.CIVIC: 2,
	GameEnums.BlockPurpose.COMMERCIAL: 8,
	GameEnums.BlockPurpose.INDUSTRIAL: 6,
}

## The calm kinds a whole block can be. A courtyard is not here: it is a residential block
## with a court cut into it, which is what makes it *hidden* calm — you have to know it is
## there, and that is exactly the knowledge a fixed city is supposed to reward.
const _OPEN_CALM: Array[GameEnums.BlockPurpose] = [
	GameEnums.BlockPurpose.PARK,
	GameEnums.BlockPurpose.FOREST,
	GameEnums.BlockPurpose.QUIET_SQUARE,
]

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
	var purposes := _assign_purposes(map, rng)
	var block_rects := _build_blocks(map, purposes, rng)
	_place_home(map, purposes, block_rects, rng)
	_plan_arcs(map, purposes, rng)

	for rects in block_rects.values():
		map.building_rects.append_array(rects)
	# The map starts on day 1, which is every block at step 0 of its arc.
	var state := CityState.new()
	map.repaint(state)
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
	var x_road := x_offset >= 0 and CityMap.is_road_offset(x_offset)
	var y_road := y_offset >= 0 and CityMap.is_road_offset(y_offset)

	if x_offset >= 0 and y_offset >= 0:
		if x_road and y_road:
			return GameEnums.TileType.ROAD
		if x_road or y_road:
			return GameEnums.TileType.CROSSING
		return GameEnums.TileType.SIDEWALK

	return GameEnums.TileType.ROAD if (x_road or y_road) else GameEnums.TileType.SIDEWALK

# ----------------------------------------------------------------- purposes ---

## Decides what each block starts as. Open calm first and never side by side, so the calm is
## spread across the map and no two quiet blocks are one street apart; then the built kinds;
## then courtyards, cut into residential blocks that are not already next to open calm.
static func _assign_purposes(map: CityMap, rng: RandomNumberGenerator) -> Dictionary:
	var blocks: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			blocks.append(Vector2i(x, y))

	var shuffled := blocks.duplicate()
	_shuffle(shuffled, rng)

	var purposes := {}
	var calm_target := rng.randi_range(Tuning.MIN_CALM_BLOCKS, Tuning.MAX_CALM_BLOCKS)
	for block in shuffled:
		if purposes.size() >= calm_target:
			break
		if _has_open_calm_neighbour(purposes, block):
			continue
		purposes[block] = _OPEN_CALM[rng.randi_range(0, _OPEN_CALM.size() - 1)]

	var remaining: Array[Vector2i] = []
	for block in shuffled:
		if not purposes.has(block):
			remaining.append(block)

	var index := 0
	for purpose: GameEnums.BlockPurpose in _BUILT_TARGETS:
		for i in _BUILT_TARGETS[purpose]:
			if index >= remaining.size():
				break
			purposes[remaining[index]] = purpose
			index += 1
	while index < remaining.size():
		purposes[remaining[index]] = GameEnums.BlockPurpose.RESIDENTIAL
		index += 1

	_cut_courtyards(purposes, remaining, rng)
	return purposes

## Turns some residential blocks into courtyard blocks. Never one that touches open calm:
## a hidden court is worth finding, and a court across the street from a park is not.
static func _cut_courtyards(purposes: Dictionary, remaining: Array[Vector2i],
		rng: RandomNumberGenerator) -> void:
	var cut := 0
	for block in remaining:
		if cut >= Tuning.MAX_COURTYARD_BLOCKS:
			return
		if purposes[block] != GameEnums.BlockPurpose.RESIDENTIAL:
			continue
		if _has_open_calm_neighbour(purposes, block):
			continue
		if rng.randf() >= Tuning.COURTYARD_CHANCE:
			continue
		purposes[block] = GameEnums.BlockPurpose.COURTYARD
		cut += 1

static func _has_open_calm_neighbour(purposes: Dictionary, block: Vector2i) -> bool:
	for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _OPEN_CALM.has(purposes.get(block + step, -1)):
			return true
	return false

# --------------------------------------------------------------------- arcs ---

## Plans every block's arc, up front, for the whole run.
##
## The one hard rule: at least `MIN_CALM_BLOCKS_AT_END` blocks must still be calm on the
## last day. A day can only be won on calm ground (M14), so an arc set that requisitions
## everything is not a hard run, it is an unwinnable one — and because arcs are planned here
## rather than rolled day by day, that is a property this function can simply guarantee
## instead of a property the scheduler has to keep rescuing.
static func _plan_arcs(map: CityMap, purposes: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var calm: Array[Vector2i] = []
	for block: Vector2i in purposes:
		if BlockPlan.is_calm(purposes[block]):
			calm.append(block)
	calm.sort()
	_shuffle(calm, rng)
	var may_be_taken := maxi(0, calm.size() - Tuning.MIN_CALM_BLOCKS_AT_END)

	var taken := 0
	for block: Vector2i in purposes:
		var purpose: GameEnums.BlockPurpose = purposes[block]
		var plan := BlockPlan.of(purpose)
		if BlockPlan.is_calm(purpose):
			var index := calm.find(block)
			if index >= 0 and index < may_be_taken and rng.randf() < Tuning.REQUISITION_CHANCE:
				plan.then(GameEnums.BlockPurpose.REQUISITIONED,
						rng.randi_range(Tuning.REQUISITION_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1),
						GameEnums.BlockCause.SCHEDULED)
				taken += 1
		else:
			_plan_built_arc(plan, purpose, rng)
		map.block_plans[block] = plan

## A built block goes dark before it burns, and only a commercial one goes dark at all.
## The fire step is event-caused: it waits for something to actually burn there, so a block
## whose arc ends in ashes may finish the run untouched.
static func _plan_built_arc(plan: BlockPlan, purpose: GameEnums.BlockPurpose,
		rng: RandomNumberGenerator) -> void:
	if purpose == GameEnums.BlockPurpose.COMMERCIAL and rng.randf() < Tuning.BOARDING_CHANCE:
		plan.then(GameEnums.BlockPurpose.BOARDED_UP,
				rng.randi_range(Tuning.BOARDING_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1),
				GameEnums.BlockCause.SCHEDULED)
	if rng.randf() < Tuning.BURN_CHANCE:
		plan.then(GameEnums.BlockPurpose.BURNT_OUT, Tuning.BURN_FIRST_DAY,
				GameEnums.BlockCause.FIRE)

static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = array[i]
		array[i] = array[j]
		array[j] = swap

# ------------------------------------------------------------------- blocks ---

## Carves every block and returns the building rects it left behind, keyed by block, so the
## home can be carved out of its block afterwards without re-deriving anything.
##
## The carves are recorded in a `BlockLayout` as well as painted, because the painting is
## redone every day from the block's current purpose and must not re-roll anything. The
## tiles this lays down are day 1's; `CityMap.repaint()` owns every day after that.
static func _build_blocks(map: CityMap, purposes: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var block_rects := {}
	# Iterate in a fixed order; `purposes` is keyed by an unordered shuffle.
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			block_rects[block] = _build_block(map, block, purposes[block], rng)
	return block_rects

static func _build_block(map: CityMap, block: Vector2i, purpose: GameEnums.BlockPurpose,
		rng: RandomNumberGenerator) -> Array[Rect2i]:
	var lot := CityMap.block_rect(block)
	var layout := BlockLayout.new()
	map.block_layouts[block] = layout

	if _OPEN_CALM.has(purpose):
		layout.open_rect = lot
		map.fill_rect(lot, CityMap.open_tile_for(purpose))
		# Only a park has a playground: a forest with a swing frame in it is a park, and a
		# quiet square with one is not quiet.
		if purpose == GameEnums.BlockPurpose.PARK:
			layout.playground = _inset_rect(lot, 3, rng)
			map.fill_rect(layout.playground, GameEnums.TileType.PLAYGROUND)
		return []

	map.fill_rect(lot, GameEnums.TileType.BUILDING)
	var rects: Array[Rect2i] = [lot]

	if purpose == GameEnums.BlockPurpose.COURTYARD:
		layout.open_rect = _inset_rect(lot, Tuning.COURTYARD_SIZE_TILES, rng)
		layout.passage = _passage_rect(lot, layout.open_rect, rng)
		map.fill_rect(layout.open_rect, GameEnums.TileType.COURTYARD)
		map.fill_rect(layout.passage, GameEnums.TileType.ALLEY)
		map.courtyard_rects.append(layout.open_rect)
		rects = _subtract_all(rects, layout.open_rect)
		rects = _subtract_all(rects, layout.passage)

	if purpose == GameEnums.BlockPurpose.COMMERCIAL:
		layout.square = _corner_rect(lot, Tuning.SQUARE_SIZE_TILES, rng)
		map.fill_rect(layout.square, GameEnums.TileType.SQUARE)
		map.square_rects.append(layout.square)
		rects = _subtract_all(rects, layout.square)

	if rng.randf() < float(Tuning.ALLEY_CHANCE[purpose]):
		layout.alley = _alley_rect(lot, rng)
		map.fill_rect(layout.alley, GameEnums.TileType.ALLEY)
		map.alley_rects.append(layout.alley)
		rects = _subtract_all(rects, layout.alley)

	return _keep_nonempty(rects)

## A rect of `size` tiles somewhere inside `lot`, never touching its edge.
static func _inset_rect(lot: Rect2i, size: int, rng: RandomNumberGenerator) -> Rect2i:
	var span := lot.size.x - size - 2
	var offset := Vector2i(rng.randi_range(1, maxi(1, span)), rng.randi_range(1, maxi(1, span)))
	return Rect2i(lot.position + offset, Vector2i.ONE * size)

## The archway out of a courtyard: one tile wide, from the court to the nearest point on one
## of the lot's four edges. Without it the court is a sealed hole in the map — which is how
## the first version of courtyards failed, on every seed, at the connectivity check.
static func _passage_rect(lot: Rect2i, court: Rect2i, rng: RandomNumberGenerator) -> Rect2i:
	var side := rng.randi_range(0, 3)
	var middle := court.position + court.size / 2
	match side:
		0:  # north
			return Rect2i(Vector2i(middle.x, lot.position.y),
					Vector2i(1, court.position.y - lot.position.y))
		1:  # south
			return Rect2i(Vector2i(middle.x, court.end.y),
					Vector2i(1, lot.end.y - court.end.y))
		2:  # west
			return Rect2i(Vector2i(lot.position.x, middle.y),
					Vector2i(court.position.x - lot.position.x, 1))
		_:  # east
			return Rect2i(Vector2i(court.end.x, middle.y),
					Vector2i(lot.end.x - court.end.x, 1))

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
static func _place_home(map: CityMap, purposes: Dictionary, block_rects: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var from_calm := map.walk_distances_from(map.calm_tiles())
	var centre := Vector2(Tuning.CITY_BLOCKS - Vector2i.ONE) * 0.5

	var candidates: Array[Vector2i] = []
	for block in block_rects:
		if purposes[block] == GameEnums.BlockPurpose.RESIDENTIAL:
			candidates.append(block)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a).distance_squared_to(centre) < Vector2(b).distance_squared_to(centre))

	var fallback := Vector2i.ZERO
	var fallback_distance := -1
	for block in candidates:
		var home := _home_rect(map, block)
		var distance := _distance_to_calm(map, from_calm, home)
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

static func _distance_to_calm(map: CityMap, from_calm: Dictionary, home: Rect2i) -> int:
	# The home opens onto the sidewalk directly south of it.
	var doorstep := Vector2i(home.position.x, home.end.y)
	if not from_calm.has(doorstep):
		return -1
	return int(from_calm[doorstep]) + 1

static func _carve_home(map: CityMap, block_rects: Dictionary, block: Vector2i,
		home: Rect2i) -> void:
	map.fill_rect(home, GameEnums.TileType.HOME)
	map.home_rect = home
	map.home_block = block
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

	if map.calm_blocks.size() < Tuning.MIN_CALM_BLOCKS:
		return "only %d calm blocks, need %d" % [
			map.calm_blocks.size(), Tuning.MIN_CALM_BLOCKS]

	var open_calm: Array[Vector2i] = []
	for block in map.calm_blocks:
		if _OPEN_CALM.has(map.starting_purpose(block)):
			open_calm.append(block)
	for block in open_calm:
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			if block + step in open_calm:
				return "calm blocks %s and %s are adjacent" % [block, block + step]

	var calm_distance := map.home_to_nearest_calm()
	if calm_distance < Tuning.MIN_HOME_TO_PARK_TILES:
		return "home is only %d tiles from calm ground, need %d" % [
			calm_distance, Tuning.MIN_HOME_TO_PARK_TILES]

	# The arcs are planned for the whole run, so the end of it can be checked here rather
	# than hoped for. A run that requisitions its way to nothing is unwinnable, not hard.
	var lasting := 0
	for block: Vector2i in map.block_plans:
		if (map.block_plans[block] as BlockPlan).stays_calm():
			lasting += 1
	if lasting < Tuning.MIN_CALM_BLOCKS_AT_END:
		return "only %d blocks stay calm for the whole run, need %d" % [
			lasting, Tuning.MIN_CALM_BLOCKS_AT_END]

	return ""
