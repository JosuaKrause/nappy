class_name StreetTrees
extends RefCounted
## Where street trees stand: a handful of **tree-lined runs**, each a straight stretch of three to
## five consecutive blocks along one street line, with pits on both kerbs — chosen from the city's
## own seed at generation and fixed for the run, the same "fixed for the run" contract a building
## keeps, and for the same reason: the geometry she learns has to stay true.
##
## **A pure function of `CityMap`, not a scene.** `City._spawn_street_trees()` draws exactly the
## positions this returns, `ClosurePlanner` reads `has_trees()` to decide where a `fallen_tree`
## closure may happen at all, and `EventScheduler` reads `footprint_tiles()` to refuse that ground
## to the day's events — one source of truth for all three, so the drawing, the planting and the
## planning can never disagree about which street has trees on it.
##
## **Most streets are bare, and that is the design.** *(2026-09-12, the player: "trees read like
## obstacles (they add noise) so it makes detecting actual obstacles harder … trees must be quite
## rare to be able to still place vans restaurants etc. also, trees make it harder to spot events
## like yeller, dog walker, etc.")* A tree and an event never share ground, so every pit is a tile
## the day may not put a van, a café, a market stall, a yeller or a seal on. The four numbers that
## keep that bill small are `Tuning.STREET_TREE_RUNS`, the two run-length bounds, and
## `Tuning.STREET_TREE_PIT_SPACING`; `Tuning.STREET_TREE_MAX_LINED_FRACTION` is the ceiling they
## are chosen under.
##
## **The mouth margin is what keeps a pit off a crossing and off a checkpoint.** A boundary
## segment's wall or door structure always stands at one of its two one-tile-deep mouths
## (`RegionPlanner.boundary_segments`'s own doc: "the wall stands at a boundary crossing's mouth,
## one tile deep, never its midpoint" — fixed at generation, independent of which day makes it a
## wall or a door), and a zebra crossing is painted at the same junction-adjacent tiles. A generic
## one-tile buffer from both ends of *every* segment therefore already clears both without a
## special case for which segments are boundaries, and it holds inside a run exactly as it held
## when every qualifying street was planted.

## Streets fronted by one of these purposes (`CityMap.starting_purpose`, fixed for the run — a
## requisitioned park does not change what a street outside it was built as) may carry trees.
const _DISTRICTS := {
	GameEnums.BlockPurpose.RESIDENTIAL: true,
	GameEnums.BlockPurpose.COMMERCIAL: true,
}

## Tiles kept clear at each end of a segment — see the class doc for why one tile already covers
## both "never on a crossing" and "never within a tile of a checkpoint".
const _MOUTH_MARGIN_TILES := 1

## The pavement offset nearest the carriageway on each of a corridor's two footways
## (`CrowdLanes.SIDEWALK_OFFSETS` is `[0, 1, 4, 5]`) — a street tree stands at the kerb, which
## also keeps the building-frontage lane (offset 0 or 5) clear for anybody browsing a shopfront.
const _CURB_OFFSETS := [1, 4]

## How many placements `runs()` may try before it gives up on reaching `Tuning.STREET_TREE_RUNS`.
## A run needs three to five consecutive ordinary streets fronting housing or shops and not
## already taken by another run, which most of the lattice satisfies and some of it cannot — a
## bound rather than a `while true`, so a hostile seed ends with fewer runs instead of hanging.
const _RUN_TRIES := 240

## The fraction of a tree sprite's own width its ground shape reaches, out of
## `Prop._compute_shape()` — the point the shadow is drawn from and the footprint an event is kept
## out of. Mirrored here rather than read off a `Prop`, because every caller of `footprint_tiles()`
## is a headless planner with no scene to build one in; `tests/test_blocks.gd` compares this
## against a real street tree's own `shape.reach()` so the two cannot drift apart unnoticed.
const _FOOTPRINT_FRACTION := 0.28

## One tree-lined run: a straight stretch of `length` consecutive blocks along one street line.
## `index` is the corridor the line runs down (the junction row for a horizontal run, the junction
## column for a vertical one) and `first` is the block it starts at.
class Run extends RefCounted:
	var horizontal := true
	var index := 0
	var first := 0
	var length := 0

	## The keys of the streets this run covers, in order along the line — the same
	## `StreetNetwork.Segment.key()` shape, built from the run's own geometry rather than searched
	## for.
	func segment_keys() -> Array[Vector3i]:
		var found: Array[Vector3i] = []
		for i in length:
			found.append(Vector3i(first + i, index, 0) if horizontal \
					else Vector3i(index, first + i, 1))
		return found

	## The streets this run covers, as the lattice's own `Segment` objects. Null for a key the
	## lattice does not enumerate, which `_run_is_plantable` refuses the run for.
	func segments() -> Array[StreetNetwork.Segment]:
		var found: Array[StreetNetwork.Segment] = []
		for key in segment_keys():
			var segment := StreetNetwork.by_key(key)
			if segment:
				found.append(segment)
		return found

## One standing street tree: where it is, which tile it stands on, and which segment it belongs
## to — the fact `has_trees()` groups by.
class Planted extends RefCounted:
	var position: Vector2
	var tile: Vector2i
	var segment_key: Vector3i

## The city's tree-lined runs, fixed for the run from `map.seed_used`.
##
## **Placed at random across the map in both directions** *(2026-09-11, the player: "continuous
## segments of 3/4/5 blocks randomly placed on the map in both directions")*, and rejected whole
## rather than trimmed: a run whose every street is not an ordinary street fronting housing or
## shops is not a shorter run, it is a different one, so the roll is taken again. Runs never
## overlap, which is what makes `Tuning.STREET_TREE_RUNS` a count of *places* rather than a count
## of rolls.
static func runs(map: CityMap) -> Array[Run]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("street_tree_runs:%d" % map.seed_used)
	var found: Array[Run] = []
	var taken := {}
	for _try in _RUN_TRIES:
		if found.size() >= Tuning.STREET_TREE_RUNS:
			break
		var run := Run.new()
		run.horizontal = rng.randi_range(0, 1) == 0
		run.length = rng.randi_range(Tuning.STREET_TREE_RUN_MIN_BLOCKS,
				Tuning.STREET_TREE_RUN_MAX_BLOCKS)
		var along_blocks: int = Tuning.CITY_BLOCKS.x if run.horizontal else Tuning.CITY_BLOCKS.y
		var lines: int = Tuning.CITY_BLOCKS.y if run.horizontal else Tuning.CITY_BLOCKS.x
		if run.length > along_blocks:
			continue
		run.index = rng.randi_range(0, lines)
		run.first = rng.randi_range(0, along_blocks - run.length)
		if not _run_is_plantable(map, run, taken):
			continue
		for key in run.segment_keys():
			taken[key] = true
		found.append(run)
	return found

## Every standing street tree in the city, fixed for the run.
##
## Planted along the **whole run** rather than street by street, which is what makes
## `Tuning.STREET_TREE_PIT_SPACING` mean "one pit every other lot-length" instead of one per
## street: the spacing accumulator crosses the junction between two blocks of the same run.
static func planted(map: CityMap) -> Array[Planted]:
	var found: Array[Planted] = []
	var door_tile := _door_tile(map)
	for run in runs(map):
		for offset in _CURB_OFFSETS:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("street_tree:%d:%d:%d:%d:%d" % [map.seed_used,
					0 if run.horizontal else 1, run.index, run.first, offset])
			found.append_array(_plant_side(run, offset, rng, door_tile))
	return found

## Whether `segment` carries a standing street tree — what `ClosurePlanner._pick_kind` and
## `SealPlanner` read to decide whether a fallen tree may happen on this street at all. **A run
## segment with no pit on it answers false**, and that is the point: a fallen tree has to take a
## pit, so a street with none is not a street a tree can fall on.
static func has_trees(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	return segment_keys_with_trees(map).has(segment.key())

## `planted()`'s own segments, as a set — built once per call rather than once per candidate
## closure, since `ClosurePlanner.plan_day` asks this at most once per day.
static func segment_keys_with_trees(map: CityMap) -> Dictionary:
	var keys := {}
	for tree in planted(map):
		keys[tree.segment_key] = true
	return keys

## How far a street tree's own ground shape reaches from its trunk, in px — `Prop`'s street tree
## is a `GroundShape.point` of exactly this, and the widest of the sprites it may be drawn as is
## what a planner has to keep clear, since which variant a pit gets is decided where the prop is
## built rather than here.
static func footprint_radius() -> float:
	var widest := 0.0
	for texture: Texture2D in Prop.TREES:
		widest = maxf(widest, texture.get_size().x * _FOOTPRINT_FRACTION)
	return widest

## Every tile a standing street tree stands on or reaches over, as a set — the ground
## `EventScheduler._open_ground_for` refuses a candidate row, the same way it refuses a closed
## street, and the ground `SealPlanner` steps its own bodies aside from.
##
## **Every pit, including one today's fallen tree empties.** An emptied pit is on a street that is
## closed or hard-sealed for the day, so it is already refused by the segment it is on; keeping
## this answer a fact about the *city* rather than about the day is what lets it be asked before
## the day's plan exists.
static func footprint_tiles(map: CityMap) -> Dictionary:
	var tiles := {}
	var radius := footprint_radius()
	for tree in planted(map):
		var low := ((tree.position - Vector2.ONE * radius) / float(Tuning.TILE_SIZE)).floor()
		var high := ((tree.position + Vector2.ONE * radius) / float(Tuning.TILE_SIZE)).floor()
		for y in range(int(low.y), int(high.y) + 1):
			for x in range(int(low.x), int(high.x) + 1):
				tiles[Vector2i(x, y)] = true
	return tiles

## The pit on `segment_key` nearest `to`, or null when that street has none — how a planner picks
## which tree fell. Stated as "nearest the thing that felled it" rather than "the first one" so
## that the gap in the row is where the picture is, which is the whole of what the player asked
## for: *"one spot should be empty (the fallen tree's spot)"*.
static func pit_nearest(map: CityMap, segment_key: Vector3i, to: Vector2) -> Planted:
	var best: Planted = null
	var best_distance := INF
	for tree in planted(map):
		if tree.segment_key != segment_key:
			continue
		var distance := tree.position.distance_to(to)
		if distance < best_distance:
			best_distance = distance
			best = tree
	return best

# ------------------------------------------------------------------ district ---

## Whether every street of `run` is one trees may line, and none of them is already in another
## run. An ordinary street — the main road is crossed rather than walked and a precinct's paving
## is the shops' own — fronting housing or shops, and actually in this city's lattice.
static func _run_is_plantable(map: CityMap, run: Run, taken: Dictionary) -> bool:
	for key in run.segment_keys():
		if taken.has(key) or not map.has_street(key):
			return false
		var segment := StreetNetwork.by_key(key)
		if not segment:
			return false
		if _street_kind_of(map, segment) != GameEnums.StreetKind.ORDINARY:
			return false
		if not _fronts_a_qualifying_block(map, segment):
			return false
	return true

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

## One kerb of one run, planted end to end. The `along` coordinate walks each block's own street
## tiles inside the mouth margin and simply skips the junctions between them, so the spacing is
## measured over the run and a junction never carries a pit.
static func _plant_side(run: Run, offset: int, rng: RandomNumberGenerator,
		door_tile: Vector2i) -> Array[Planted]:
	var cross_tile := run.index * CityMap.period() + offset
	var cross := CrowdLanes.lane_centre(run.index, offset)
	var found: Array[Planted] = []
	var last_along := -INF
	for i in run.length:
		var block := run.first + i
		var segment_key := Vector3i(block, run.index, 0) if run.horizontal \
				else Vector3i(run.index, block, 1)
		var base := block * CityMap.period() + Tuning.STREET_WIDTH
		for k in range(_MOUTH_MARGIN_TILES, Tuning.BLOCK_SIZE - _MOUTH_MARGIN_TILES):
			var along_tile := base + k
			var tile := Vector2i(along_tile, cross_tile) if run.horizontal \
					else Vector2i(cross_tile, along_tile)
			if _chebyshev(tile, door_tile) <= 1:
				continue
			if rng.randf() >= Tuning.STREET_TREE_PLANT_CHANCE:
				continue
			var along_world := (along_tile + 0.5) * float(Tuning.TILE_SIZE)
			if last_along > -INF and absf(along_world - last_along) < Tuning.STREET_TREE_PIT_SPACING:
				continue
			var tree := Planted.new()
			tree.position = Vector2(along_world, cross) if run.horizontal \
					else Vector2(cross, along_world)
			tree.tile = tile
			tree.segment_key = segment_key
			found.append(tree)
			last_along = along_world
	return found

static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
