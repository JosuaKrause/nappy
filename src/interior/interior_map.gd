class_name InteriorMap
extends RefCounted
## Builds the five floors of the escape scene's building — each a small, hand-shaped plan of
## `InteriorTile.Kind` cells, independent of `CityMap`'s own lattice, generator and guarantees:
## a building with one way through it has no route-redundancy invariant to keep. See
## `docs/TODO.md`, "M112 — The escape scene, walkable" for the brief this lays out.
##
## Coordinate system: `x` runs east along the hallway (`0 .. HALLWAY_LENGTH - 1`), `y` runs south.
## Rows 0 and 1 are the hallway itself — row 0 against the north wall, row 1 its south edge, where
## the apartment doors are implied below the view. A stairwell opens off column 0 (the left/west
## end) or column `HALLWAY_LENGTH - 1` (the right/east end) by carving three further rows south of
## the hallway. See `_carve_stairwell()` for the switchback layout.

## `FloorKind`, kept here rather than on `InteriorFloor`, since this is the file that knows the
## order they stack in. Every other file reads it as `int` — see `InteriorFloor.kind`'s own doc.
enum FloorKind { THIRD, SECOND, FIRST, GROUND, BASEMENT }

const HALLWAY_LENGTH := 14
## Rows 0 and 1 are the hallway; a stairwell's own rows start at row `HALLWAY_ROWS`.
const HALLWAY_ROWS := 2
const LEFT_DOOR_COLUMN := 0
const RIGHT_DOOR_COLUMN := HALLWAY_LENGTH - 1
## Kept clear of both door columns and of each other, so nothing in the wall ever shares a column
## with two different features.
const LIFT_COLUMN := 3
const WINDOW_COLUMNS: Array[int] = [1, 5, 9, 11]
## Ground floor only, in addition to the lift every floor has.
const ENTRANCE_COLUMN := 7
## Basement only, at the hallway's own west end — an arbitrary side; either stairwell reaches it
## by the same short walk once she is on the basement's hallway floor.
const EXIT_COLUMN := 1

## Building order, top to bottom. `floor_below()` reads this rather than each floor answering
## "what comes after me" on its own, since the order is a fact about the building, not about any
## one storey.
const ORDER: Array[int] = [
	FloorKind.THIRD, FloorKind.SECOND, FloorKind.FIRST, FloorKind.GROUND, FloorKind.BASEMENT,
]

## The floor one storey down, or `kind` unchanged at the basement — there is nothing further down
## to go, and `InteriorFloor.Stairwell.has_flights()` is what actually keeps the basement's own
## stairwells from ever asking this.
static func floor_below(kind: int) -> int:
	var index := ORDER.find(kind)
	return ORDER[index + 1] if index != -1 and index + 1 < ORDER.size() else kind

static func build(kind: int) -> InteriorFloor:
	var f := InteriorFloor.new()
	f.kind = kind
	var basement := kind == FloorKind.BASEMENT
	var wall_kind := InteriorTile.Kind.BRICK_WALL if basement else InteriorTile.Kind.WALL
	var edge_n := InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N if basement \
			else InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N
	var edge_s := InteriorTile.Kind.BASEMENT_FLOOR_EDGE_S if basement \
			else InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S
	var edge_w := InteriorTile.Kind.BASEMENT_FLOOR_EDGE_W if basement \
			else InteriorTile.Kind.HALLWAY_FLOOR_EDGE_W
	var edge_e := InteriorTile.Kind.BASEMENT_FLOOR_EDGE_E if basement \
			else InteriorTile.Kind.HALLWAY_FLOOR_EDGE_E

	# The hallway: two rows deep, so both rows are edges rather than plain floor — see
	# InteriorTile.Kind.HALLWAY_FLOOR's own doc for why the bare kind goes unused here.
	for x in HALLWAY_LENGTH:
		f.tiles[Vector2i(x, 0)] = edge_n
		f.tiles[Vector2i(x, 1)] = edge_s
		f.north_wall[x] = wall_kind
	f.tiles[Vector2i(0, 1)] = edge_w
	f.tiles[Vector2i(HALLWAY_LENGTH - 1, 1)] = edge_e

	if basement:
		f.tiles[Vector2i(EXIT_COLUMN, 0)] = InteriorTile.Kind.EMERGENCY_EXIT
		f.exit_tile = Vector2i(EXIT_COLUMN, 0)
		f.puddle_tiles = [Vector2i(6, 1), Vector2i(9, 0)]
	else:
		f.north_wall[LIFT_COLUMN] = InteriorTile.Kind.LIFT_DOOR
		for c in WINDOW_COLUMNS:
			f.north_wall[c] = InteriorTile.Kind.WINDOW
		if kind == FloorKind.GROUND:
			f.north_wall[ENTRANCE_COLUMN] = InteriorTile.Kind.ENTRANCE_DOOR
			f.entrance_column = ENTRANCE_COLUMN

	# Every floor gets both stairwells; only the basement's have nothing further down.
	f.stairwells.append(_carve_stairwell(f, "left", LEFT_DOOR_COLUMN, 1, not basement))
	f.stairwells.append(_carve_stairwell(f, "right", RIGHT_DOOR_COLUMN, -1, not basement))

	f.start_tile = Vector2i(HALLWAY_LENGTH / 2, 1) if kind == FloorKind.THIRD \
			else f.stairwell("left").door_tile
	return f

## One stairwell: a door at `door_col`, a three-tile flight `dir` columns per step east (`dir=1`)
## or west (`dir=-1`) to a landing, then — only when `has_flights` — a second three-tile flight
## back the other way, two rows further south, to the lower landing that triggers the transition
## to the floor below.
##
## **The gap row between the two flights is deliberately left with nothing walkable except the
## landing's own turn column.** The door and the lower landing sit in the same column two rows
## apart — a Chebyshev distance of 2, so they are never orthogonally *or* diagonally adjacent —
## and the row between them is otherwise entirely absent from `tiles`. Diagonal movement is live
## (`Stroller._physics_process()` reads `Input.get_vector()` on both axes), so anything less than
## that gap would let her step from the door straight to the transition tile without ever standing
## on a flight tile, which is the one thing this layout exists to prevent.
static func _carve_stairwell(f: InteriorFloor, side: String, door_col: int, dir: int,
		has_flights: bool) -> InteriorFloor.Stairwell:
	var s := InteriorFloor.Stairwell.new()
	s.side = side
	var row_door := HALLWAY_ROWS
	s.door_tile = Vector2i(door_col, row_door)
	f.tiles[s.door_tile] = InteriorTile.Kind.STAIRWELL_DOOR
	if not has_flights:
		return s

	var flight_down := InteriorTile.Kind.STAIR_FLIGHT_E if dir > 0 else InteriorTile.Kind.STAIR_FLIGHT_W
	var flight_back := InteriorTile.Kind.STAIR_FLIGHT_W if dir > 0 else InteriorTile.Kind.STAIR_FLIGHT_E
	for i in range(1, 4):
		f.tiles[Vector2i(door_col + dir * i, row_door)] = flight_down
	var turn_col := door_col + dir * 4
	var row_gap := row_door + 1
	var row_lower := row_door + 2
	f.tiles[Vector2i(turn_col, row_door)] = InteriorTile.Kind.LANDING
	f.tiles[Vector2i(turn_col, row_gap)] = InteriorTile.Kind.LANDING
	f.tiles[Vector2i(turn_col, row_lower)] = InteriorTile.Kind.LANDING
	for i in range(1, 4):
		f.tiles[Vector2i(turn_col - dir * i, row_lower)] = flight_back
	s.lower_landing_tile = Vector2i(door_col, row_lower)
	f.tiles[s.lower_landing_tile] = InteriorTile.Kind.LANDING
	return s
