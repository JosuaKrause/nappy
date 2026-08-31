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
##
## Keyed by the block that **anchors a lot**, which since M21 is not always one block: a
## four-block calm zone is a single entry whose ground covers all four of its blocks and the
## streets that used to run between them. The other three appear in `zone_anchor` and nowhere
## else, so everything stated over `block_plans` — how many calm areas there are, which one is
## least spoiled, which one she settled in yesterday — counts a zone once, which is what it is.
var block_plans := {}
## Block coordinate -> BlockLayout. The carves, also fixed at generation. Anchors only, for the
## same reason as `block_plans`: an absorbed block has no ground of its own.
var block_layouts := {}
## Anchor block -> the rect of *blocks* its lot spans. Only multi-block lots appear here; a
## plain block's lot is itself and is not worth a dictionary entry. See `lot_blocks()`.
var zone_rects := {}
## Every block of a multi-block lot -> that lot's anchor, the anchor included. The inverse of
## `zone_rects`, kept rather than searched because `block_at()` asks it per event.
var zone_anchor := {}
## Segment keys this city does not have at all: the streets a four-block calm zone was painted
## straight over. Fixed for the run, unlike `closed_tiles`, and a fact about the **lattice**
## rather than about a day — the tiles are park, and the player walks on them quite happily.
##
## This is what M21 does to `StreetNetwork`, which was written assuming a full grid: the
## enumeration is still the full grid and this is the set that is not really there, so the graph
## half — route counting, the invariant, the doorway exemptions — survives untouched and simply
## gets a bigger `closed` set. See `blocked_segments()`.
var absent_segments := {}
## The streets a **hard blocker** built over, as segment key -> the tile rect that is now solid.
## A subset of `absent_segments`, kept apart because the two are absent for opposite reasons and
## anything reasoning about *why* a street is not there has to tell them apart. *(M50 step 1.)*
##
## A calm zone's absorbed corridor is **ground you walk over** — the tiles are park and the lattice
## losing the street is the whole point of a shortcut. A hard blocker is the reverse: the lattice
## loses the street *and the ground stops*, because one that could be walked through would not be
## one.
##
## Anything asking "can a route go this way" wants `blocked_segments()`, which is both and does not
## care. This is for the things that do: the telemetry map's legend, and any test whose sentence is
## about zones.
var built_over := {}
## Which of `built_over` are **dead ends** — a street with one end walled — as a set of keys. The
## rest belong to a big building, which took its street whole.
var dead_ends := {}
## The landmarks, each as the **pair of blocks** it joins. *(M50 step 1.)* A big building builds
## over the one street between two neighbouring blocks and leaves every other street around them
## alone; a type that closes all four is a different type and does not exist yet. See
## `CityGenerator._place_big_buildings`.
var big_buildings: Array[Rect2i] = []

## Whether a street is missing because something was built over it rather than because a calm zone
## painted a park across it. The question every rule about *zones* actually wants to ask, now that
## `absent_segments` has two kinds of thing in it.
func is_hard_blocker(key: Vector3i) -> bool:
	return built_over.has(key)
## The corridor index of the one main road, which runs north to south. `-1` before generation.
##
## One of it, and only on this axis. *(Playtest 12, finding 2: "there should be one north to south
## main road, I had multiple, and there should be no east to west ones at all.")* A spine that
## crosses itself is two spines; what makes a main road the main road is that there is nowhere
## else it could be.
var main_road := -1

## The precincts, as stretches rather than corridors: `(axis, corridor, first block, last block)`
## with axis 1 for north-south. Three blocks long and two of them, so a precinct is a place you
## can be told how to find rather than a kind of street. See `CityGenerator._place_precincts`.
##
## A span covers its blocks' frontages and the junctions **between** them, and stops short of the
## crossroads at either end. That is where the bollards are: the road runs up to the junction and
## the paving begins after it, so a car reaching a precinct has an ordinary junction to turn at
## rather than having to turn round on brick.
var precinct_spans: Array[Vector4i] = []
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
## The streets closed today, as a set of tiles. The only per-day thing on this class, and
## deliberately so: everything else here is fixed for the run or derived from a block's
## purpose, and neither of those may move a walkable tile. A closure is the one thing that
## changes where the player may walk, which is why it is a set that is cleared every morning
## rather than an edit to `tiles`. See `RoadClosure` and docs/CITY.md, "Road closures".
var closed_tiles := {}

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

## Tile rect spanned by a rect of blocks, **including the streets between them**.
##
## For one block that is `block_rect`. For a 2x2 zone it is 22 tiles square, because the two
## block interiors and the corridor between them are contiguous — which is the whole reason a
## four-block calm zone can be one rect of grass rather than four with roads through it.
static func blocks_tile_rect(blocks: Rect2i) -> Rect2i:
	var first := block_rect(blocks.position)
	var last := block_rect(blocks.end - Vector2i.ONE)
	return Rect2i(first.position, last.end - first.position)

## Position within the current period, or -1 when the coordinate is inside a block.
static func corridor_offset(coordinate: int) -> int:
	var offset := posmod(coordinate, period())
	return offset if offset < Tuning.STREET_WIDTH else -1

# ------------------------------------------------------------ street kinds ---

## What kind of street a stretch of corridor is: the axis, the corridor index, and how far along
## it in tiles. `ORDINARY` for anything outside the lattice, which is what every caller means by
## "not a street I know about".
##
## It takes the **along** coordinate as well as the corridor because a precinct is three blocks of
## a street rather than the whole of it. Callers that genuinely have no along coordinate — a car
## choosing which corridor to drive down — want `is_driveable_street` instead.
func street_kind(vertical: bool, index: int, along_tile: int) -> GameEnums.StreetKind:
	if vertical and index == main_road:
		return GameEnums.StreetKind.MAIN
	for span in precinct_spans:
		if (span.x == 1) != vertical or span.y != index:
			continue
		if along_tile >= span.z * period() + Tuning.STREET_WIDTH \
				and along_tile < (span.w + 1) * period():
			return GameEnums.StreetKind.PEDESTRIAN
	return GameEnums.StreetKind.ORDINARY

## The kind of street at a tile, asked about one of the two corridors it may belong to. The along
## coordinate is the *other* axis, which is what a stretch is measured along.
func street_kind_at(vertical: bool, tile: Vector2i) -> GameEnums.StreetKind:
	var across: int = tile.x if vertical else tile.y
	if corridor_offset(across) < 0:
		return GameEnums.StreetKind.ORDINARY
	return street_kind(vertical, junction_index(across), tile.y if vertical else tile.x)

## Whether there is a carriageway here. The one question a car asks about a street that a walker
## never does: a precinct is paved from frontage to frontage, so it is perfectly walkable ground
## with nowhere on it a car is allowed to be.
##
## Stated over a **point** rather than over a corridor, because a precinct is three blocks of a
## street and the eight either side of it are an ordinary road that ought to have traffic on it.
## A car meeting the end of the precinct diverts, which is what a driver meeting a bollarded
## street does.
func is_driveable(vertical: bool, index: int, along_tile: int) -> bool:
	return street_kind(vertical, index, along_tile) != GameEnums.StreetKind.PEDESTRIAN

## The same for a world tile, asked about whichever corridor it is travelling along.
func is_driveable_at(vertical: bool, tile: Vector2i) -> bool:
	return street_kind_at(vertical, tile) != GameEnums.StreetKind.PEDESTRIAN

## The junction a tile stands in — the pair of corridor indices whose bands cross there — or
## `(-1, -1)` where it is not inside one.
##
## A junction is the one piece of street that belongs to two corridors at once, which is why it
## needs a name of its own: a lane is a queue and a junction is a **box**, and two cars on
## crossing arms can each have a clear lane ahead while both are about to be in the same box.
static func junction_at(tile: Vector2i) -> Vector2i:
	if corridor_offset(tile.x) < 0 or corridor_offset(tile.y) < 0:
		return Vector2i(-1, -1)
	return Vector2i(junction_index(tile.x), junction_index(tile.y))

## Which corridor a coordinate's period belongs to. Floored rather than integer-divided so a
## coordinate just outside the map answers -1 instead of sharing corridor 0.
static func junction_index(coordinate: int) -> int:
	return floori(float(coordinate) / float(period()))

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

## Street ground: pavement, carriageway or crossing. Anything that travels the lattice asks
## this, because since M21 a corridor may simply not be there — a four-block calm zone is
## painted over the streets between its blocks, and those tiles are park somebody walks on
## rather than street anybody drives down. A crowd agent that only checked `is_walkable` would
## drive across the grass.
func is_street(tile: Vector2i) -> bool:
	var type := tile_at(tile)
	return type == GameEnums.TileType.SIDEWALK or type == GameEnums.TileType.ROAD \
			or type == GameEnums.TileType.CROSSING

func is_closed(tile: Vector2i) -> bool:
	return closed_tiles.has(tile)

## Which way is *away from the carriageway* from a pavement tile, as a unit tile step. Zero
## where the question has no single answer. *(M34, playtest 07 findings 7 and 15.)*
##
## A corridor is sidewalk | road | sidewalk across its own axis, so a pavement tile has a kerb on
## one side and a frontage on the other, and which is which follows from the offset. Two cases
## deliberately answer zero rather than guessing:
##
## - **A junction**, where the tile is in both corridors at once and has a kerb on two sides. A
##   van parked in one is wrong whichever way it faces.
## - **Anything that is not pavement** — the carriageway itself, a park a calm zone painted over
##   the street, a closed tile. `is_street()` is not enough here: since M21 a corridor may not be
##   there at all, and a tile at a pavement offset can be grass.
func pavement_inward(tile: Vector2i) -> Vector2i:
	if tile_at(tile) != GameEnums.TileType.SIDEWALK:
		return Vector2i.ZERO
	var x_offset := corridor_offset(tile.x)
	var y_offset := corridor_offset(tile.y)
	if x_offset >= 0 and y_offset >= 0:
		return Vector2i.ZERO
	var offset := x_offset if x_offset >= 0 else y_offset
	var axis := Vector2i.RIGHT if x_offset >= 0 else Vector2i.DOWN
	if offset < Tuning.SIDEWALK_WIDTH:
		return -axis
	if offset >= Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH:
		return axis
	return Vector2i.ZERO

## Walkable *and* open: what the player can actually use today. Anything choosing a place to
## put something — an event, a crowd agent, a resistance contact — wants this rather than
## `is_walkable`, or it will put it somewhere nobody can reach.
func is_open(tile: Vector2i) -> bool:
	return not closed_tiles.has(tile) and Tile.is_walkable(tile_at(tile))

## The lattice as a route search must see it: the streets this city never had, plus whatever
## today has shut on top of them.
##
## Every `StreetNetwork` call that takes a `closed` set wants this rather than the day's
## closures alone. Passing the closures by themselves lets a route run down the middle of a
## park, which overstates the redundancy — and route redundancy is the one guarantee that used
## to be true by construction and is not any more, so overstating it is exactly the failure M21
## has to avoid.
func blocked_segments(closed_today: Dictionary = {}) -> Dictionary:
	if closed_today.is_empty():
		return absent_segments.duplicate()
	var blocked := absent_segments.duplicate()
	for key: Vector3i in closed_today:
		blocked[key] = true
	return blocked

## Whether the lattice really has this street. False for the ones a calm zone absorbed.
func has_street(key: Vector3i) -> bool:
	return not absent_segments.has(key)

# ---------------------------------------------------------------------- lots ---

## The rect of *blocks* one lot covers — one block for almost everything, 2x2 for a four-block
## calm zone. `block` may be any member of the lot; the answer is the same for all of them.
func lot_blocks(block: Vector2i) -> Rect2i:
	var anchor := anchor_of(block)
	return zone_rects.get(anchor, Rect2i(anchor, Vector2i.ONE))

## The tile rect one lot covers, streets between its blocks included.
func lot_rect(block: Vector2i) -> Rect2i:
	return blocks_tile_rect(lot_blocks(block))

## The block that stands for the lot this one belongs to. Identity for the 45 lots that are one
## block, and the anchor for the members of a zone.
func anchor_of(block: Vector2i) -> Vector2i:
	return zone_anchor.get(block, block)

## Takes today's closed streets out of the network. The whole street goes in the set, not
## just the two barriers: the ground between them is not somewhere anyone can get to, so
## nothing should be placed there and nobody should be routed through it.
func close_streets(closures: Array[RoadClosure]) -> void:
	closed_tiles.clear()
	for closure in closures:
		for tile in closure.tiles(self):
			closed_tiles[tile] = true

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

## The lot nearest a world position, named by its anchor block. Events happen on streets,
## between blocks, so "which block did this happen to" is nearest-centre rather than
## containment — and since M21 it is nearest *lot* centre, so a fire on the edge of a
## four-block park is attributed to the park rather than to one quarter of it that has no arc
## of its own.
func block_at(world_position: Vector2) -> Vector2i:
	var best := Vector2i.ZERO
	var closest := INF
	for block: Vector2i in block_plans:
		var centre := tile_rect_to_world(lot_rect(block)).get_center()
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
	# Two passes, and the split is what makes a four-block calm zone possible: one lot's ground
	# now covers blocks that are not its own, so a single pass that cleared each lot immediately
	# before painting it would have whichever block came later in the dictionary punch a
	# building-shaped hole in the park next door. Clear everything, then paint everything.
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			fill_rect(block_rect(Vector2i(x, y)), GameEnums.TileType.BUILDING)
	for block: Vector2i in block_plans:
		_repaint_block(block, state.purpose_of(block_plans, block))
	# The home notch is carved out of a block interior, so it has to go back on top.
	if home_rect.size != Vector2i.ZERO:
		fill_rect(home_rect, GameEnums.TileType.HOME)
	_tiles_by_type.clear()
	# Yesterday's closures are gone before today's are planned; the planner needs to see the
	# whole lattice to decide what it can afford to take out of it.
	closed_tiles.clear()
	_recompute_calm(state)

func _repaint_block(block: Vector2i, purpose: GameEnums.BlockPurpose) -> void:
	var layout: BlockLayout = block_layouts.get(block)
	if not layout:
		return
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

## A tile the sweep never got to, and one it was told to treat as a wall. Both read as
## unreachable to `reaches()`; they are two values only so that `blocked` can be painted into
## the grid before the sweep starts instead of being asked about per neighbour.
const UNREACHED := -1
const BLOCKED := -2

## `TileType -> 1` where the ground can be walked on, so the sweep below can ask by index
## rather than by call. `Tile.is_walkable` stays the one place that decides it.
static var _WALKABLE: PackedByteArray = _lut(Tile.is_walkable)
static var _CALM: PackedByteArray = _lut(Tile.is_calm)

## Sized by the largest value rather than by the count of them, so an enum that later gains an
## explicit value cannot quietly index past the end or read a gap as "no".
static func _lut(predicate: Callable) -> PackedByteArray:
	var highest := 0
	for value: int in GameEnums.TileType.values():
		highest = maxi(highest, value)
	var lut := PackedByteArray()
	lut.resize(highest + 1)
	for value: int in GameEnums.TileType.values():
		lut[value] = 1 if predicate.call(value as GameEnums.TileType) else 0
	return lut

## Walking distance in tiles from `from` to every reachable walkable tile, as a flat grid
## indexed `y * size.x + x`. Negative where the tile cannot be reached. Read it with
## `reaches()` and `distance_at()` rather than indexing it by hand.
##
## Flat rather than a `Vector2i -> int` dictionary because this is the most-run piece of
## arithmetic in the project: `CityGenerator.validate` sweeps it twice per generation attempt
## and `EventScheduler` once more for every day it plans. A dictionary hashes a Variant about
## fifty thousand times to answer a question the tile grid answers by index, and the four
## neighbour steps are written out rather than looped for the same reason — the loop's own
## bounds test costs more than the arithmetic it guards.
func walk_field(from: Vector2i, blocked: Dictionary = {}) -> PackedInt32Array:
	return walk_field_from([from], blocked)

## Multi-source version: distance to the nearest of `sources`. One sweep answers
## "how far is the nearest park from anywhere", which is how the home is placed.
func walk_field_from(sources: Array, blocked: Dictionary = {}) -> PackedInt32Array:
	var width := size.x
	var cells := width * size.y
	var field := PackedInt32Array()
	field.resize(cells)
	field.fill(UNREACHED)
	for tile: Vector2i in blocked:
		if in_bounds(tile):
			field[tile.y * width + tile.x] = BLOCKED

	var queue := PackedInt32Array()
	queue.resize(cells)
	var tail := 0
	for source in sources:
		var tile: Vector2i = source
		if not in_bounds(tile) or _WALKABLE[tiles[tile.y * width + tile.x]] == 0:
			continue
		var index := tile.y * width + tile.x
		if field[index] != UNREACHED:
			continue
		field[index] = 0
		queue[tail] = index
		tail += 1

	var head := 0
	while head < tail:
		var index := queue[head]
		head += 1
		var next_distance: int = field[index] + 1
		# The row's own ends for left and right — the grid is one array, so a step off the left
		# edge lands on the right end of the row above and would walk through the boundary wall.
		var x := index % width
		if x > 0 and field[index - 1] == UNREACHED and _WALKABLE[tiles[index - 1]] == 1:
			field[index - 1] = next_distance
			queue[tail] = index - 1
			tail += 1
		if x < width - 1 and field[index + 1] == UNREACHED and _WALKABLE[tiles[index + 1]] == 1:
			field[index + 1] = next_distance
			queue[tail] = index + 1
			tail += 1
		if index >= width and field[index - width] == UNREACHED \
				and _WALKABLE[tiles[index - width]] == 1:
			field[index - width] = next_distance
			queue[tail] = index - width
			tail += 1
		if index + width < cells and field[index + width] == UNREACHED \
				and _WALKABLE[tiles[index + width]] == 1:
			field[index + width] = next_distance
			queue[tail] = index + width
			tail += 1
	return field

## Whether a sweep reached a tile. Out of bounds is not reached rather than an error, which is
## what every caller means by it.
func reaches(field: PackedInt32Array, tile: Vector2i) -> bool:
	return in_bounds(tile) and field[tile.y * size.x + tile.x] >= 0

## How far a sweep had to walk to a tile, or -1 if it never got there.
func distance_at(field: PackedInt32Array, tile: Vector2i) -> int:
	if not in_bounds(tile):
		return -1
	return maxi(-1, field[tile.y * size.x + tile.x])

## How many tiles a sweep reached.
func reach_count(field: PackedInt32Array) -> int:
	var total := 0
	for distance in field:
		if distance >= 0:
			total += 1
	return total

func count_walkable() -> int:
	var total := 0
	for type in tiles:
		total += _WALKABLE[type]
	return total

## Every calm tile in the city right now. Since M14 this is the only ground a day can be
## won on, so it is what "how hard is today" actually means.
func calm_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var width := size.x
	for index in tiles.size():
		if _CALM[tiles[index]] == 1:
			result.append(Vector2i(index % width, index / width))
	return result

## Shortest walking distance from the home to any calm tile, or -1 if unreachable.
func home_to_nearest_calm() -> int:
	var field := walk_field_from(calm_tiles())
	var best := -1
	for tile in rect_tiles(home_rect):
		var distance := distance_at(field, tile)
		if distance >= 0 and (best == -1 or distance < best):
			best = distance
	return best

## Walkable tiles immediately outside a lot — its pavement, effectively. Used to place
## things "at" a district when the district itself is solid building.
func perimeter_tiles(block: Vector2i) -> Array[Vector2i]:
	var lot := lot_rect(block)
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
		for tile in rect_tiles(lot_rect(block)):
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
