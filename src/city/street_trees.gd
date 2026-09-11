class_name StreetTrees
extends RefCounted
## Where street trees stand: pits on the pavement along `RESIDENTIAL` and `COMMERCIAL` frontage,
## fixed for the run from the city's own seed — the same "fixed for the run" contract a building
## keeps, and for the same reason: the geometry she learns has to stay true.
##
## **A pure function of `CityMap`, not a scene.** `City._spawn_street_trees()` draws exactly the
## positions this returns, and `ClosurePlanner` reads `has_trees()` to prefer `fallen_tree` on a
## street that already has standing trees — one source of truth for both, so the drawing and the
## planning can never disagree about which street has trees on it.
##
## **The mouth margin is what keeps a pit off a crossing and off a checkpoint.** A boundary
## segment's wall or door structure always stands at one of its two one-tile-deep mouths
## (`RegionPlanner.boundary_segments`'s own doc: "the wall stands at a boundary crossing's mouth,
## one tile deep, never its midpoint" — fixed at generation, independent of which day makes it a
## wall or a door), and a zebra crossing is painted at the same junction-adjacent tiles. A generic
## one-tile buffer from both ends of *every* segment therefore already clears both without a
## special case for which segments are boundaries.

## Streets fronted by one of these purposes (`CityMap.starting_purpose`, fixed for the run — a
## requisitioned park does not change what a street outside it was built as) may carry trees.
const _DISTRICTS := {
	GameEnums.BlockPurpose.RESIDENTIAL: true,
	GameEnums.BlockPurpose.COMMERCIAL: true,
}

## Tiles kept clear at each end of a segment — see the class doc for why one tile already covers
## both "never on a crossing" and "never within a tile of a checkpoint".
const _MOUTH_MARGIN_TILES := 1

## Minimum centre-to-centre spacing along one pavement, in px — wide enough that consecutive pits
## read as a planted row rather than a hedge (`City.MIN_TREE_SPACING`, 50px, is a park canopy's
## own width; a street tree stands alone against a much longer sightline).
const MIN_SPACING := 96.0

## Chance a qualifying tile gets a pit at all, rolled once per candidate in scan order — what
## turns "every qualifying street" into "some of them", the way `Building.LIT_WINDOW_CHANCE` does
## for windows.
const PLANT_CHANCE := 0.55

## The pavement offset nearest the carriageway on each of a corridor's two footways
## (`CrowdLanes.SIDEWALK_OFFSETS` is `[0, 1, 4, 5]`) — a street tree stands at the kerb, which
## also keeps the building-frontage lane (offset 0 or 5) clear for anybody browsing a shopfront.
const _CURB_OFFSETS := [1, 4]

## One standing street tree: where it is, and which segment it belongs to — the fact
## `has_trees()` groups by.
class Planted extends RefCounted:
	var position: Vector2
	var segment_key: Vector3i

## Every standing street tree in the city, fixed for the run.
static func planted(map: CityMap) -> Array[Planted]:
	var found: Array[Planted] = []
	var door_tile := _door_tile(map)
	for segment in StreetNetwork.segments():
		if not map.has_street(segment.key()):
			continue
		if _street_kind_of(map, segment) != GameEnums.StreetKind.ORDINARY:
			continue
		if not _fronts_a_qualifying_block(map, segment):
			continue
		for offset in _CURB_OFFSETS:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("street_tree:%d:%d:%d:%d:%d" % [map.seed_used, segment.a.x,
					segment.a.y, 0 if segment.horizontal else 1, offset])
			found.append_array(_plant_side(map, segment, offset, rng, door_tile))
	return found

## Whether `segment` carries a standing street tree — what `ClosurePlanner._pick_kind` reads to
## prefer `fallen_tree` there, so a felled tree reads as one of *those* trees.
static func has_trees(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	return segment_keys_with_trees(map).has(segment.key())

## `planted()`'s own segments, as a set — built once per call rather than once per candidate
## closure, since `ClosurePlanner.plan_day` asks this at most once per day.
static func segment_keys_with_trees(map: CityMap) -> Dictionary:
	var keys := {}
	for tree in planted(map):
		keys[tree.segment_key] = true
	return keys

# ------------------------------------------------------------------ district ---

static func _street_kind_of(map: CityMap, segment: StreetNetwork.Segment) -> GameEnums.StreetKind:
	var vertical := not segment.horizontal
	var index := segment.a.x if vertical else segment.a.y
	var mid := segment.a.y if vertical else segment.a.x
	var along := mid * CityMap.period() + Tuning.STREET_WIDTH + Tuning.BLOCK_SIZE / 2
	return map.street_kind(vertical, index, along)

## The one or two blocks a segment runs beside, by the same NORTH/SOUTH/WEST/EAST geometry
## `StreetNetwork.beside_block` reads — inverted here rather than searched for, since a segment's
## own `a` already names which block sides it is.
static func _bordering_blocks(segment: StreetNetwork.Segment) -> Array[Vector2i]:
	if segment.horizontal:
		return [segment.a, segment.a + Vector2i.UP]
	return [segment.a, segment.a + Vector2i.LEFT]

static func _fronts_a_qualifying_block(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	for block in _bordering_blocks(segment):
		if not map.block_plans.has(block):
			continue   # off the lattice — the boundary street outside the map's edge block
		if _DISTRICTS.has(map.starting_purpose(block)):
			return true
	return false

# ------------------------------------------------------------------ planting ---

## The home's own front door tile, kept clear the same one-tile margin as a crossing or a
## checkpoint — the single literal "door" in the game, `door.svg`, standing at the home's notch.
static func _door_tile(map: CityMap) -> Vector2i:
	return Vector2i(map.home_rect.position.x, map.home_rect.end.y)

static func _plant_side(map: CityMap, segment: StreetNetwork.Segment, offset: int,
		rng: RandomNumberGenerator, door_tile: Vector2i) -> Array[Planted]:
	var vertical := not segment.horizontal
	var rect := segment.tile_rect()
	var along_base := rect.position.x if segment.horizontal else rect.position.y
	var along_count := rect.size.x if segment.horizontal else rect.size.y
	var index := segment.a.x if vertical else segment.a.y
	var cross := CrowdLanes.lane_centre(index, offset)
	var cross_tile := index * CityMap.period() + offset
	var found: Array[Planted] = []
	var last_along := -INF
	for k in range(_MOUTH_MARGIN_TILES, along_count - _MOUTH_MARGIN_TILES):
		var along_tile := along_base + k
		var tile := Vector2i(along_tile, cross_tile) if segment.horizontal \
				else Vector2i(cross_tile, along_tile)
		if _chebyshev(tile, door_tile) <= 1:
			continue
		if rng.randf() >= PLANT_CHANCE:
			continue
		var along_world := (along_tile + 0.5) * float(Tuning.TILE_SIZE)
		if last_along > -INF and absf(along_world - last_along) < MIN_SPACING:
			continue
		var position := Vector2(along_world, cross) if segment.horizontal \
				else Vector2(cross, along_world)
		var tree := Planted.new()
		tree.position = position
		tree.segment_key = segment.key()
		found.append(tree)
		last_along = along_world
	return found

static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
