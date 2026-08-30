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

	_assign_street_kinds(map)
	_lay_streets(map)
	var purposes := _assign_purposes(map, rng)
	var block_rects := _build_blocks(map, purposes, rng)
	_place_home(map, block_rects)
	_plan_arcs(map, purposes, rng)

	for rects in block_rects.values():
		map.building_rects.append_array(rects)
	# The map starts on day 1, which is every block at step 0 of its arc.
	var state := CityState.new()
	map.repaint(state)
	return map

# ------------------------------------------------------------------ streets ---

## Decides where the main road and the precincts are, before a tile is laid.
##
## Seeded from the map seed with an RNG of its own rather than drawn from the generator's, the
## same trick `CrowdLanes.busyness` uses: the hierarchy is a property of the city, and taking it
## out of the shared stream means adding it moves nothing else that a seed already decided.
##
## The spine is the corridor `CrowdLanes.arterial_index` already called the arterial, so the
## busiest street and the main road are the same street rather than two overlapping claims about
## which one matters — and it is **only** the north-south one. *(Playtest 12, finding 2.)*
static func _assign_street_kinds(map: CityMap) -> void:
	map.main_road = CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("street:%d" % map.seed_used)
	_place_precincts(map, rng)

## The two precincts, three blocks each. *(Playtest 12, findings 1 and 7: "a stretch of three
## blocks at the shore, like a coney island beach walk, and three blocks in the city somewhere —
## no more.")*
##
## One is always the **shore**: the southern boundary street, which is the one corridor in the
## city with buildings on a single side, so a promenade there has a front and a back the way a
## sea front does. The other is inland and may be on either axis.
##
## They are stretches rather than corridors because that is what makes a precinct a *place*. A
## whole corridor of it is a kind of street, and a kind of street you meet every third block is
## simply what a street is — which is the version this replaced.
static func _place_precincts(map: CityMap, rng: RandomNumberGenerator) -> void:
	map.precinct_spans.clear()
	var length := Tuning.PRECINCT_BLOCKS

	var shore := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y) - 1
	var along := rng.randi_range(0, Tuning.CITY_BLOCKS.x - length)
	map.precinct_spans.append(Vector4i(0, shore, along, along + length - 1))

	# Inland: never the spine, never beside it — a car diverted off the main road needs the
	# street next to it to be a street — and never the boundary, which is either the shore itself
	# or the far side of the city from it.
	for _attempt in 24:
		var vertical := rng.randf() < 0.5
		var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
		var across: int = Tuning.CITY_BLOCKS.y if vertical else Tuning.CITY_BLOCKS.x
		var corridor := rng.randi_range(1, CrowdLanes.corridor_count(blocks) - 2)
		if vertical and absi(corridor - map.main_road) <= 1:
			continue
		var start := rng.randi_range(0, across - length)
		map.precinct_spans.append(
				Vector4i(1 if vertical else 0, corridor, start, start + length - 1))
		return

static func _lay_streets(map: CityMap) -> void:
	# The offsets are a modulo and the kinds are a short scan of the precinct list, so both are
	# hoisted per row and per column rather than asked once per tile of a lattice this size.
	var x_offsets := PackedInt32Array()
	x_offsets.resize(map.size.x)
	for x in map.size.x:
		x_offsets[x] = CityMap.corridor_offset(x)
	for y in map.size.y:
		var y_offset := CityMap.corridor_offset(y)
		# The kind of each corridor *at this row*: a precinct is three blocks of a street, so a
		# vertical corridor's kind changes as the row moves down it.
		var x_kinds := PackedByteArray()
		x_kinds.resize(map.size.x)
		for x in map.size.x:
			x_kinds[x] = map.street_kind_at(true, Vector2i(x, y))
		for x in map.size.x:
			var x_offset := x_offsets[x]
			if x_offset < 0 and y_offset < 0:
				map.set_tile(Vector2i(x, y), GameEnums.TileType.BUILDING)
			else:
				map.set_tile(Vector2i(x, y), _street_tile(x_offset,
						x_kinds[x] as GameEnums.StreetKind, y_offset,
						map.street_kind_at(false, Vector2i(x, y))))

## Sidewalk | road | sidewalk across a corridor. Where a road crosses the *other*
## corridor's sidewalk band you get a pedestrian crossing, which is exactly where a
## crossing belongs.
##
## Two kinds change what that produces, and both changes are the kind saying what the street is
## rather than a new rule about geometry:
##
## - **A pedestrianised corridor has no carriageway**, so its own band is paving all the way
##   across and a driveable street crossing it does so over a zebra six tiles deep.
## - **A main road's zebra is signalled rather than negotiated.** The paint is the same paint and
##   it stays: what changes is who honours it. Traffic on a main road does not give way to
##   somebody standing at the kerb — it obeys the light — so the crossing becomes a *timing*
##   problem where an ordinary one is a gap-hunting problem. See `CrowdAgent._give_way` and
##   `TrafficSignals`. Painting it away instead was tried and is worse: a walker crossing a side
##   street would then be standing on open carriageway, and the one thing a zebra is for is
##   saying where a person on a road is meant to be.
static func _street_tile(x_offset: int, x_kind: GameEnums.StreetKind,
		y_offset: int, y_kind: GameEnums.StreetKind) -> GameEnums.TileType:
	var x_road := x_offset >= 0 and x_kind != GameEnums.StreetKind.PEDESTRIAN \
			and CityMap.is_road_offset(x_offset)
	var y_road := y_offset >= 0 and y_kind != GameEnums.StreetKind.PEDESTRIAN \
			and CityMap.is_road_offset(y_offset)

	if x_offset >= 0 and y_offset >= 0:
		if x_road and y_road:
			return GameEnums.TileType.ROAD
		if x_road or y_road:
			return GameEnums.TileType.CROSSING
		return GameEnums.TileType.SIDEWALK

	return GameEnums.TileType.ROAD if (x_road or y_road) else GameEnums.TileType.SIDEWALK

# ----------------------------------------------------------------- purposes ---

## Decides what each block starts as. **Four-block calm zones first**, because they are the
## only thing here that needs a shape rather than a slot and every later choice can work round
## one; then single calm blocks, never side by side with anything calm, so the calm is spread
## across the map; then the built kinds; then courtyards, cut into residential blocks that are
## not already next to open calm.
##
## The dictionary that comes back is keyed by **lot anchors**, not by blocks: the three blocks a
## zone absorbed are removed at the end and live in `map.zone_anchor` instead. They carry the
## zone's purpose while this function runs, though, because that is what makes the "never side
## by side" rule see a zone as calm ground without a special case for it.
static func _assign_purposes(map: CityMap, rng: RandomNumberGenerator) -> Dictionary:
	var blocks: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			blocks.append(Vector2i(x, y))

	var shuffled := blocks.duplicate()
	_shuffle(shuffled, rng)

	var purposes := {}
	var zones := {}
	# **The middle block is claimed for the home before anything else is decided.** Claiming it
	# rather than preferring it is what makes the home central *mandatorily*: a claimed block cannot
	# be swallowed by a calm zone (`_zone_fits` requires a wholly unclaimed footprint), cannot be
	# rolled as calm below, and is not in `remaining`, so no courtyard is cut into it either.
	purposes[home_block()] = GameEnums.BlockPurpose.RESIDENTIAL

	var areas := _place_calm_zones(purposes, zones, shuffled, rng)

	var calm_target := rng.randi_range(Tuning.MIN_CALM_BLOCKS, Tuning.MAX_CALM_BLOCKS)
	for block in shuffled:
		if areas >= calm_target:
			break
		if purposes.has(block) or _has_open_calm_neighbour(purposes, Rect2i(block, Vector2i.ONE)):
			continue
		if _too_near_the_home(Rect2i(block, Vector2i.ONE)):
			continue
		purposes[block] = _OPEN_CALM[rng.randi_range(0, _OPEN_CALM.size() - 1)]
		areas += 1

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
	_record_zones(map, purposes, zones)
	return purposes

# ------------------------------------------------------- four-block calm zones ---

## Picks the 2x2 calm zones and marks all four blocks of each. Returns how many calm areas it
## made, which is what the single-block pass counts on from.
##
## Two constraints beyond "does it fit", and both are about what the zone would take away:
##
## - **Never the arterial.** A zone absorbs the corridor between its own columns and the one
##   between its own rows, and the main road is one street the city cannot afford to lose a
##   stretch of — it is the noise floor, the thing that has to be crossed, and the street a
##   player learns first. `CrowdLanes.arterial_index` says which it is.
## - **Never beside other calm.** The same rule single blocks obey, applied to the whole
##   footprint: a four-block park with a quiet square across the road from it is one calm area
##   with an awkward middle, and the point of several is that they are somewhere else.
static func _place_calm_zones(purposes: Dictionary, zones: Dictionary,
		shuffled: Array[Vector2i], rng: RandomNumberGenerator) -> int:
	var wanted := rng.randi_range(Tuning.MIN_CALM_ZONES, Tuning.MAX_CALM_ZONES)
	var made := 0
	var span := Vector2i.ONE * Tuning.CALM_ZONE_BLOCKS
	for anchor in shuffled:
		if made >= wanted:
			break
		var footprint := Rect2i(anchor, span)
		if not _zone_fits(purposes, footprint):
			continue
		var purpose := _OPEN_CALM[rng.randi_range(0, _OPEN_CALM.size() - 1)]
		for block in _blocks_in(footprint):
			purposes[block] = purpose
		zones[anchor] = footprint
		made += 1
	return made

## The middle of the lattice, which is the home's block. Odd on both axes by constraint, so there
## is exactly one — see `Tuning.CITY_BLOCKS`.
static func home_block() -> Vector2i:
	return (Tuning.CITY_BLOCKS - Vector2i.ONE) / 2

## Whether a footprint is close enough to the home that putting calm ground in it would undo the
## thing the walk out is for.
##
## The two rules about the home compete — it is central, and it is `MIN_HOME_TO_PARK_TILES` of
## walking from calm ground — and with the home pinned to the middle this is the only remaining
## place to settle that.
##
## Stated in blocks because the lattice is what it constrains, and **derived from the tile guarantee
## rather than authored beside it**, or the two drift apart the first time either moves. A block `d`
## away starts `d * period()` tiles from the home block's own origin, of which `BLOCK_SIZE` is the
## home's lot — so the shortest walk to it is about `d * period() - BLOCK_SIZE`, and the clearance is
## the smallest `d` that clears the guarantee.
##
## It is a floor rather than the guarantee itself: walking distance is not straight-line, and the
## home sits in the *south* edge of its block, so real distances come out longer. `validate()` still
## checks the tile guarantee, which is what catches the case this approximation is wrong about.
static func _too_near_the_home(footprint: Rect2i) -> bool:
	var home := home_block()
	var clearance := ceili(float(Tuning.MIN_HOME_TO_PARK_TILES + Tuning.BLOCK_SIZE)
			/ float(CityMap.period()))
	for block in _blocks_in(footprint):
		var away: Vector2i = (block - home).abs()
		if maxi(away.x, away.y) < clearance:
			return true
	return false

## Whether a 2x2 footprint is inside the map, wholly unclaimed, clear of other calm, clear of the
## home, and does not swallow a stretch of either arterial.
static func _zone_fits(purposes: Dictionary, footprint: Rect2i) -> bool:
	if footprint.end.x > Tuning.CITY_BLOCKS.x or footprint.end.y > Tuning.CITY_BLOCKS.y:
		return false
	if _too_near_the_home(footprint):
		return false
	# The corridors this would absorb are the ones between its own columns and rows.
	for index in range(footprint.position.x + 1, footprint.end.x):
		if index == CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.x):
			return false
	for index in range(footprint.position.y + 1, footprint.end.y):
		if index == CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.y):
			return false
	for block in _blocks_in(footprint):
		if purposes.has(block):
			return false
	return not _has_open_calm_neighbour(purposes, footprint)

static func _blocks_in(footprint: Rect2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(footprint.position.y, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			found.append(Vector2i(x, y))
	return found

## Writes the zones onto the map and takes the absorbed blocks out of `purposes`, so that from
## here on a lot is one entry however many blocks of ground it owns.
static func _record_zones(map: CityMap, purposes: Dictionary, zones: Dictionary) -> void:
	for anchor: Vector2i in zones:
		var footprint: Rect2i = zones[anchor]
		map.zone_rects[anchor] = footprint
		for block in _blocks_in(footprint):
			map.zone_anchor[block] = anchor
			if block != anchor:
				purposes.erase(block)
		_absorb_streets(map, footprint)

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
		if _has_open_calm_neighbour(purposes, Rect2i(block, Vector2i.ONE)):
			continue
		if rng.randf() >= Tuning.COURTYARD_CHANCE:
			continue
		purposes[block] = GameEnums.BlockPurpose.COURTYARD
		cut += 1

## Whether anything open-calm sits directly across a street from this footprint. Stated over a
## rect of blocks rather than one block so that a single block and a four-block zone are the
## same question asked twice, rather than one rule and one special case.
static func _has_open_calm_neighbour(purposes: Dictionary, footprint: Rect2i) -> bool:
	for x in range(footprint.position.x, footprint.end.x):
		for y in [footprint.position.y - 1, footprint.end.y]:
			if _OPEN_CALM.has(purposes.get(Vector2i(x, y), -1)):
				return true
	for y in range(footprint.position.y, footprint.end.y):
		for x in [footprint.position.x - 1, footprint.end.x]:
			if _OPEN_CALM.has(purposes.get(Vector2i(x, y), -1)):
				return true
	return false

## Takes the streets inside a zone out of the lattice: the two horizontal segments between its
## rows and the two vertical ones between its columns.
##
## That is the whole of it, and the graph half of `StreetNetwork` needs no other change —
## `map.absent_segments` is added to the closed set of every route search, the four junctions
## around the removed cross become T-junctions for free, and the one in the middle of the zone
## is left with nothing reaching it at all.
##
## Then the **stub**. Each of the four surviving junctions on the zone's edge is a T now, and
## the quarter of it on the zone's side is a two-tile spur of carriageway and zebra that leads
## out of the junction and stops in the grass. Nothing drives there — a car diverting turns on
## the junction's own road band, a whole tile before it — and nothing has to be crossed there
## either, so it becomes pavement and the road visibly ends at the junction rather than poking
## into the park.
##
## `grow(SIDEWALK_WIDTH)` is exactly that spur and nothing else: the band it adds is one
## pavement deep, which alongside a block is pavement already and inside a junction is precisely
## the quarter beyond the crossroads. Getting the turn wrong makes this repaint *look* wrong —
## the first build turned late, so cars drove down the spur and stood on the new pavement, which
## reads as a bug in the paint rather than as a bug in the turn.
static func _absorb_streets(map: CityMap, footprint: Rect2i) -> void:
	for y in range(footprint.position.y + 1, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			map.absent_segments[Vector3i(x, y, 0)] = true
	for x in range(footprint.position.x + 1, footprint.end.x):
		for y in range(footprint.position.y, footprint.end.y):
			map.absent_segments[Vector3i(x, y, 1)] = true

	var zone := CityMap.blocks_tile_rect(footprint)
	for tile in map.rect_tiles(zone.grow(Tuning.SIDEWALK_WIDTH)):
		if zone.has_point(tile):
			continue
		if map.tile_at(tile) == GameEnums.TileType.CROSSING:
			map.set_tile(tile, GameEnums.TileType.SIDEWALK)

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
	# Iterate in a fixed order; `purposes` is keyed by an unordered shuffle. Blocks a calm zone
	# absorbed are not in it at all — their ground belongs to the anchor and is built with it.
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			if purposes.has(block):
				block_rects[block] = _build_block(map, block, purposes[block], rng)
	return block_rects

static func _build_block(map: CityMap, block: Vector2i, purpose: GameEnums.BlockPurpose,
		rng: RandomNumberGenerator) -> Array[Rect2i]:
	# The whole lot, which for a four-block calm zone is 22 tiles square and takes in the
	# corridors between its own blocks. Everything below is written against the lot rather than
	# the block, so a zone is a big park and not a special case.
	var lot := map.lot_rect(block)
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

## Notches the home into the south edge of the middle block.
##
## **The middle, not the most central block that happens to work.** The home used to be chosen by
## sorting residential blocks by distance to the centre and taking the first that was
## `MIN_HOME_TO_PARK_TILES` from calm ground — two rules competing for the same thing, which the
## walk out settled by walking the home outward until it was far enough. Measured over ten seeds at
## 7x7 it landed about two blocks off centre and was central in four, which puts the doorstep near
## the boundary: *"I spawn too often at the edge, leaving only a few ways into the rest of the
## city."* Half the directions out of a corner block are a wall, and a city you can only leave two
## ways is a smaller city than the one that was generated.
##
## The competition is settled in `_assign_purposes` instead, by keeping calm ground away from the
## middle (`_too_near_the_home`) — so the distance guarantee holds where the home *is* rather than
## deciding where it goes. `validate()` still checks it, because a clearance stated in blocks is an
## approximation of a guarantee stated in tiles.
static func _place_home(map: CityMap, block_rects: Dictionary) -> void:
	var block := home_block()
	_carve_home(map, block_rects, block, _home_rect(map, block))

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

	if map.calm_blocks.size() < Tuning.MIN_CALM_BLOCKS:
		return "only %d calm blocks, need %d" % [
			map.calm_blocks.size(), Tuning.MIN_CALM_BLOCKS]

	# Stated over every block of every open-calm lot, not over the anchors: two four-block zones
	# whose anchors are three apart can still have their footprints touching.
	var owner := {}
	for block in map.calm_blocks:
		if not _OPEN_CALM.has(map.starting_purpose(block)):
			continue
		for member in _blocks_in(map.lot_blocks(block)):
			owner[member] = block
	for member: Vector2i in owner:
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbour: Vector2i = member + step
			if owner.has(neighbour) and owner[neighbour] != owner[member]:
				return "calm areas %s and %s are across the street from each other" % [
					owner[member], owner[neighbour]]

	if map.zone_rects.size() < Tuning.MIN_CALM_ZONES:
		return "only %d four-block calm zones, need %d" % [
			map.zone_rects.size(), Tuning.MIN_CALM_ZONES]

	# The arcs are planned for the whole run, so the end of it can be checked here rather
	# than hoped for. A run that requisitions its way to nothing is unwinnable, not hard.
	var lasting := 0
	for block: Vector2i in map.block_plans:
		if (map.block_plans[block] as BlockPlan).stays_calm():
			lasting += 1
	if lasting < Tuning.MIN_CALM_BLOCKS_AT_END:
		return "only %d blocks stay calm for the whole run, need %d" % [
			lasting, Tuning.MIN_CALM_BLOCKS_AT_END]

	# The two sweeps of the map come last, and the order is the whole reason this is affordable:
	# `generate` calls it on every attempt and about a third of them fail, so a rejection that
	# can be seen by counting calm blocks must not first walk eleven thousand tiles twice.
	# Which reason comes back when several are true changes; whether a map is accepted does not.
	var reached := map.reach_count(map.walk_field(map.home_rect.position))
	if reached != map.count_walkable():
		return "%d of %d walkable tiles are cut off from the home" % [
			map.count_walkable() - reached, map.count_walkable()]

	var calm_distance := map.home_to_nearest_calm()
	if calm_distance < Tuning.MIN_HOME_TO_PARK_TILES:
		return "home is only %d tiles from calm ground, need %d" % [
			calm_distance, Tuning.MIN_HOME_TO_PARK_TILES]

	return ""
