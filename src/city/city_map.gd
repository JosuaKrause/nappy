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
## Keyed by the block that **anchors a lot**, which is not always one block: a four-block calm zone
## is a single entry whose ground covers all four of its blocks and the streets that used to run
## between them. The other three appear in `zone_anchor` and nowhere else, so everything stated over
## `block_plans` — how many calm areas there are, which one is least spoiled, which one she settled
## in yesterday — counts a zone once, which is what it is.
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
## **`StreetNetwork` assumes a full grid and still enumerates one.** This is the set that is not
## really there, so the graph half — route counting, the invariant, the doorway exemptions — needs
## no special case and simply gets a bigger `closed` set. See `blocked_segments()`.
var absent_segments := {}
## The streets a **hard blocker** built over, as segment key -> the tile rect that is now solid.
## A subset of `absent_segments`, kept apart because the two are absent for opposite reasons and
## anything reasoning about *why* a street is not there has to tell them apart.
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
## The landmarks, each as the **pair of blocks** it joins. A big building builds over the one street
## between two neighbouring blocks and leaves every other street around them alone; a type that
## closes all four is a different type and does not exist yet. See
## `CityGenerator._place_big_buildings`.
var big_buildings: Array[Rect2i] = []

## Whether a street is missing because something was built over it rather than because a calm zone
## painted a park across it. The question every rule about *zones* actually wants to ask, now that
## `absent_segments` has two kinds of thing in it.
func is_hard_blocker(key: Vector3i) -> bool:
	return built_over.has(key)

## Which of `Tuning.REGION_COUNT` regions each junction belongs to, indexed by `StreetNetwork.
## node_of()`. `-1` before generation and for a junction no real segment ever touches. Set once by
## `RegionPlanner.assign()`, called from `CityGenerator._assign_regions` after the hard blockers
## have taken their streets — fixed for the run, the way the lattice itself is. See
## `docs/CITY.md`, "Regions and the wall".
var region_of_junction := PackedInt32Array()
## Which regions held a calm area on the morning generation decided the partition — one byte per
## region, `1` or `0`. A generation-time fact and not a per-day one: which region a calm *area* is
## in never changes, only whether today's tree can still reach it. See `RegionPlanner.
## regions_with_calm()`, and its own doc for why this no longer decides which boundary segments get
## doors — the day's tree does, unconditionally.
var region_has_calm := PackedByteArray()

## Which end of a boundary segment the wall stands at, keyed by `StreetNetwork.Segment.key()`:
## `true` for the `a` end, `false` for `b`. Decided once at generation
## (`RegionPlanner._assign_wall_ends`) so that as few through-alleys as possible end up as
## **crossings** — see `RegionPlanner.ground_region_of()`, which reads this to say which region a
## boundary segment's whole ground belongs to. Absent for an interior segment, which has no wall
## and therefore no end to choose.
var boundary_wall_at_a := {}

## The corridor index of the one main road, which runs north to south. `-1` before generation.
##
## One of it, and only on this axis. A spine that crosses itself is two spines; what makes a main
## road the main road is that there is nowhere else it could be.
var main_road := -1

## The precincts, as stretches rather than corridors: `(axis, corridor, first block, last block)`
## with axis 1 for north-south. Three blocks long and two of them, so a precinct is a place you
## can be told how to find rather than a kind of street. See `CityGenerator._place_precincts`.
##
## A span covers its blocks' frontages and the junctions **between** them, and its paving reaches
## the road edge of the crossroads at either end: the box's own carriageway still crosses a real
## street, so a car reaching the precinct has an ordinary T to turn at, but the box's precinct-side
## sidewalk band is paving too, which is what keeps the crossing street from painting a zebra over
## a road that stops a pavement's width later. That is where the bollards stand.
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

## Street segments a catalogue row may never be offered as ground today, keyed by
## `StreetNetwork.Segment.key()`. Filled by `EventManager.start_day`, before `EventScheduler.
## build_day` runs, from four sources: today's closures, every hard-sealed segment (`SealPlanner.
## plan_day`'s own `held` out-param — a soft seal is deliberately not covered, since its
## carriageway is still walkable and a café on it is the price of that route), every region wall
## and door segment (`RegionPlanner.plan_day`'s `walls` and `doors`), and every segment bordering
## the home block. See `docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street" and "Nothing
## on the home block".
##
## **Two readers, and the docstring is for both.** `EventScheduler._open_ground_for` refuses any
## candidate tile on a held segment, the fix this exists for. `CrowdAgent._cannot_go_on()` (M110,
## "The crowd goes round a seal") wants the identical fact for the same reason a car should not
## queue across a seal it cannot see through — read it with `is_held`/`is_held_at` rather than
## reaching into this dictionary directly.
var held_segments := {}

## Clears today's held segments. Called once per day, before anything is added — see
## `held_segments`.
func clear_day_holds() -> void:
	held_segments.clear()

## Marks one segment as held for today. See `held_segments`.
func hold_segment(key: Vector3i) -> void:
	held_segments[key] = true

## Whether `segment` is held today. Null answers false, so a caller need not check for a real
## street first.
func is_held(segment: StreetNetwork.Segment) -> bool:
	return segment != null and held_segments.has(segment.key())

## Whether the street segment a tile stands on is held today. False for a tile inside a junction
## or a block interior, where `StreetNetwork.segment_containing` names no segment at all.
func is_held_at(tile: Vector2i) -> bool:
	return is_held(StreetNetwork.segment_containing(tile))

## Whether a tile is inside the home block's own lot — the ground `_place_home` carves the notch
## out of. Distinct from `is_held_at`, which is about the streets *around* the block: a catalogue
## row or a resistance mark placed inside the block itself (its building interior, or an alley if
## one were ever carved there) is the other half of "nothing on the home block", `docs/DECISIONS.md`, M100's
## own words for playtest 11's reopened finding.
func is_on_home_block(tile: Vector2i) -> bool:
	return lot_rect(home_block).has_point(tile)

## Whether `tile` lies inside one of `walled_alleys` — today's crossing alleys where the region
## wall stands rather than a door (`RegionPlanner.RegionPlan.alley_walls`). **A fourth refusal
## beside `is_closed()`, `is_held_at()` and `is_on_home_block()`, and the one none of those three
## can ever stand in for**: an alley is carved into a block interior, never a `StreetNetwork`
## segment, so `is_held_at()`'s `StreetNetwork.segment_containing()` answers null for every tile of
## it and the alley is invisible to it regardless of what stands at its mouths; and a region wall
## is not a `RoadClosure`, so `is_closed()` never sees it either.
##
## Whole-rect rather than a flood from the doorstep: `RegionPlanner`'s own doc says a crossing
## alley off today's tree is walled at **both** mouths at once ("an alley has two mouths and, when
## it is a crossing, both are walled"), one tile deep and spanning the alley's full width the same
## way a street door's three bodies span a carriageway (`SealPlanner.positions_across`) — so there
## is no third opening and no tile of the rect is reachable from either street it borders. That
## makes membership in the rect itself the exact answer a reachability flood would give, without
## paying for one. See `docs/DECISIONS.md`, M100, "A blocked-off alley has no chalk mark".
func is_in_walled_alley(tile: Vector2i, walled_alleys: Array[Rect2i]) -> bool:
	for rect in walled_alleys:
		if rect.has_point(tile):
			return true
	return false

## Tiles a soft seal's own body stands on, shut to walkers only for today — the carriageway
## underneath a soft seal is untouched, so a car still drives straight through it. Deliberately
## apart from `held_segments`: that record is about which whole *segment* no catalogue row may be
## offered, and a soft seal's own carriageway is still walkable and still open to a catalogue row,
## so it was never held there — folding this into it would shut the carriageway too. Keyed on the
## tile rather than the segment for the same reason: a soft seal takes one pavement or the other,
## never the whole street, and the thinning pass may drop one body of a pair and leave that
## pavement's tiles out of this set entirely. Filled by `SealPlanner.plan_day`, which clears and
## refills it fresh on every call, the same as `held_segments` is cleared and refilled once a day.
var soft_sealed_tiles := {}

## Clears today's soft seals. See `soft_sealed_tiles`.
func clear_day_soft_seals() -> void:
	soft_sealed_tiles.clear()

## Marks one tile as soft-sealed to walkers for today. See `soft_sealed_tiles`.
func seal_soft_tile(tile: Vector2i) -> void:
	soft_sealed_tiles[tile] = true

## Whether a tile is shut to walkers by today's soft seals. False for anything a soft seal never
## stood on, cars included — a soft seal never asks this on their behalf.
func is_soft_sealed(tile: Vector2i) -> bool:
	return soft_sealed_tiles.has(tile)

## Tiles a **stationary solid body** stands on today — a café's tables, a construction band, a
## kerbed van, a stall, a skip, a burnt-out car — as tile -> how many bodies are standing there.
## *("yes every solid body should do that -- not necessarily force a turn around but at least avoid
## the solid".)* Filled by `EventManager.start_day` from the day's whole plan and by
## `EventManager._create` for anything placed later, and read by `CrowdAgent` so the crowd goes
## round a body instead of through it.
##
## **Three kinds of body are deliberately not in here**, each because something else already
## answers for it and two answers to one question is one too many. A **mobile** row is exempt by
## the catalogue's own *solid things are solid* rule and moves out of the way by walking. A body
## standing on a segment `held_segments` already holds — a hard seal, a region wall — has shut the
## whole segment to everybody, so recording its tiles again would change nothing and would make
## the two records disagree the moment one of them moved. And a **door** body (`detain_seconds >
## 0`: a hut, the boom, an alley guard) is a crossing the day means to keep open, held by
## `WalkerDoorHold` for a walker and by `Crowd._stop_for_gates()` for a car.
##
## **Counted rather than flagged**, because two bodies can overlap a tile — a café beside a stall
## on the same pavement — and the first of them to finish must not open ground the second is still
## standing on. See `release_obstruction()`.
##
## Keyed on the tile the way `soft_sealed_tiles` is and for the same reason: a body takes one lane
## of a pavement or one lane of a carriageway, never a whole segment, and which lane is the whole
## of what the crowd does about it.
var obstructed_tiles := {}
## Which tiles each body put there, by the owner id it was recorded under. Kept so a body can give
## its own tiles back without a sweep of the whole record.
var _obstruction_owners := {}

## Clears today's solid bodies. Called once a day, beside `clear_day_holds()` — see
## `obstructed_tiles`.
func clear_day_obstructions() -> void:
	obstructed_tiles.clear()
	_obstruction_owners.clear()

## Records one body's footprint under `owner`, an `Object.get_instance_id()` the caller can hand
## back later. Re-recording the same owner replaces its old footprint, so a body that moved or a
## plan re-recorded on a second day cannot leave tiles behind.
func obstruct_tiles(owner: int, tiles_covered: Array[Vector2i]) -> void:
	release_obstruction(owner)
	if tiles_covered.is_empty():
		return
	for tile in tiles_covered:
		obstructed_tiles[tile] = int(obstructed_tiles.get(tile, 0)) + 1
	_obstruction_owners[owner] = tiles_covered

## Gives one body's footprint back — its instance finishing, or the day ending. Unknown owners are
## a no-op, so every way a body can stop existing may call this without checking first.
func release_obstruction(owner: int) -> void:
	if not _obstruction_owners.has(owner):
		return
	var tiles_covered: Array[Vector2i] = _obstruction_owners[owner]
	for tile in tiles_covered:
		var left := int(obstructed_tiles.get(tile, 0)) - 1
		if left > 0:
			obstructed_tiles[tile] = left
		else:
			obstructed_tiles.erase(tile)
	_obstruction_owners.erase(owner)

## Whether a stationary solid body is standing on a tile today.
func is_obstructed(tile: Vector2i) -> bool:
	return obstructed_tiles.has(tile)

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
		# Widened by SIDEWALK_WIDTH at each end so the range reaches the crossroads' own road
		# edge rather than the block's: the box's precinct-side sidewalk band is precinct ground
		# too, which is what removes the zebra a crossing street would otherwise paint over a
		# road that stops a pavement's width later (see docs/CITY.md and PLAYTEST-37.md).
		if along_tile >= span.z * period() + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH \
				and along_tile < (span.w + 1) * period() + Tuning.SIDEWALK_WIDTH:
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

## The same for a world tile, checked against **both** corridors that meet there. A junction box
## belongs to two corridors at once, and a precinct on either one paves the whole box — so a car
## travelling an ordinary street that happens to cross a precinct is told the truth about the tile
## it is on rather than only about the street it is following.
func is_driveable_at(vertical: bool, tile: Vector2i) -> bool:
	return street_kind_at(vertical, tile) != GameEnums.StreetKind.PEDESTRIAN \
			and street_kind_at(not vertical, tile) != GameEnums.StreetKind.PEDESTRIAN

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
## this, because a corridor may simply not be there — a four-block calm zone is painted over the
## streets between its blocks, and those tiles are park somebody walks on rather than street anybody
## drives down. A crowd agent that only checked `is_walkable` would drive across the grass.
func is_street(tile: Vector2i) -> bool:
	var type := tile_at(tile)
	return type == GameEnums.TileType.SIDEWALK or type == GameEnums.TileType.ROAD \
			or type == GameEnums.TileType.CROSSING

func is_closed(tile: Vector2i) -> bool:
	return closed_tiles.has(tile)

## Which way is *away from the carriageway* from a pavement tile, as a unit tile step. Zero
## where the question has no single answer.
##
## A corridor is sidewalk | road | sidewalk across its own axis, so a pavement tile has a kerb on
## one side and a frontage on the other, and which is which follows from the offset. Two cases
## deliberately answer zero rather than guessing:
##
## - **A junction**, where the tile is in both corridors at once and has a kerb on two sides. A
##   van parked in one is wrong whichever way it faces.
## - **Anything that is not pavement** — the carriageway itself, a park a calm zone painted over
##   the street, a closed tile. `is_street()` is not enough here: a corridor may not be there at
##   all, and a tile at a pavement offset can be grass.
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
## park, which overstates the redundancy — and route redundancy is not true by construction in a
## lattice with holes in it, so an overstatement is the whole of how it goes wrong.
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

## The rect of *blocks* one lot covers — one block for almost everything, and a `CALM_ZONE_SHAPES`
## footprint for a zone. `block` may be any member of the lot; the answer is the same for all of
## them.
func lot_blocks(block: Vector2i) -> Rect2i:
	var anchor := anchor_of(block)
	return zone_rects.get(anchor, Rect2i(anchor, Vector2i.ONE))

## How many blocks' worth of **calm ground** this lot has, which is what the sleepiness curve is a
## function of.
##
## It is the lot for open calm and **one** for a courtyard, however big the lot is, because what a
## courtyard offers is its court: a four-block apartment complex is twenty-two tiles of building
## with ten tiles of ground in the middle of it, and paying it the rate of a four-block park would
## make the smallest calm area in the city the slowest one in it.
##
## The answer is unchanged for every lot that existed before apartment complexes did — a
## single-block courtyard's lot is one block either way — so this generalises the old question
## rather than repricing anything. That is the same move `sleepiness_multiplier` itself was: the new
## question has to contain the old answer.
func calm_lot_blocks(block: Vector2i) -> int:
	if starting_purpose(anchor_of(block)) == GameEnums.BlockPurpose.COURTYARD:
		return 1
	var lot := lot_blocks(block)
	return lot.size.x * lot.size.y

## The tile rect one lot covers, streets between its blocks included.
func lot_rect(block: Vector2i) -> Rect2i:
	return blocks_tile_rect(lot_blocks(block))

## The block that stands for the lot this one belongs to. Identity for the 45 lots that are one
## block, and the anchor for the members of a zone.
func anchor_of(block: Vector2i) -> Vector2i:
	return zone_anchor.get(block, block)

## Takes today's closed streets out of the network — the tiles genuinely cut off by the barriers,
## not the whole street on the assumption that they are. The barriers stand at the two mouths, and
## a street with an alley mouth or a courtyard archway opening onto its middle is still reachable
## from that side, whichever end the barriers seal; a street with no such opening is unreachable
## end to end exactly as it always was. `ReachabilityGrid` is what tells the two apart: flood the
## day's tiles from the doorstep with every barrier tile added on top, and whatever a closed
## street's own ground the flood never reaches is what goes in `closed_tiles`.
##
## Built once for every closure of the day together, not one at a time: whether a bypass survives
## can depend on ground a *different* closure also touches, so the barrier tiles of the whole set
## have to be down before any of them is judged.
func close_streets(closures: Array[RoadClosure]) -> void:
	closed_tiles.clear()
	if closures.is_empty():
		return
	var barrier_tiles := {}
	for closure in closures:
		for at_a in [true, false]:
			for tile in rect_tiles(closure.segment.mouth_rect(at_a)):
				barrier_tiles[tile] = true
	var grid := ReachabilityGrid.build(self)
	var reached := grid.flood([world_to_tile(doorstep_world_position())], barrier_tiles)
	for closure in closures:
		for tile in closure.tiles(self):
			if not grid.reaches(tile, barrier_tiles, reached):
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
## containment — and it is nearest *lot* centre, so a fire on the edge of a four-block park is
## attributed to the park rather than to one quarter of it that has no arc of its own.
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
## **The one thing about a `CityMap` that is not fixed for the run.** The street lattice, the block
## boundaries, the carves and the building footprints all are — this only ever swaps the *ground*
## inside a block's open rect, so no repaint can disconnect the city or make a wall appear where a
## route used to be. What changes is what a place is worth walking to.
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

## Every calm tile in the city right now. It is the only ground a day can be won on, so it is what
## "how hard is today" actually means.
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
