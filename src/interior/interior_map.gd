class_name InteriorMap
extends RefCounted
## Builds the seven maps of the escape scene's building, from the player's four sketches
## (`docs/reference/escape-{floor-hallway,stairwell,lobby,basement}-sketch-01.jpg`) — each a small,
## hand-shaped plan of `InteriorTile.Kind` cells, independent of `CityMap`'s own lattice, generator
## and guarantees: a building with one way through it has no route-redundancy invariant to keep.
## See `docs/TODO.md`, "M112 — The escape scene, walkable" for the brief this lays out.
##
## The seven maps are never one coordinate space. Each is its own small grid with its own origin,
## and the only thing that joins two of them is a matched pair of `InteriorMapPlan.Door` — one
## door on each side naming the other map and the other door's own id. `tests/test_interior.gd`
## asserts every door has exactly the counterpart it claims.
##
## Three hallways (`HALLWAY_THIRD`/`SECOND`/`FIRST`) share one layout: a 14-tile east-west hallway,
## two rows deep, with a stair door at each end — opposite ends, not the two the sketch drew both
## at the right, a player decision (playtest 55: "that way having a fire on the stairs forces you
## to enter a floor hallway and walk to the other end"). Two independent stairwells
## (`STAIRWELL_LEFT`/`RIGHT`), each its own tall map the camera follows down with no map load
## mid-shaft: a plain switchback, one flight down and one flight back per floor, alternating
## direction. `LOBBY` is the hallway's own width with the barricaded entrance and doors to both
## stairwells and the basement. `BASEMENT` is the winding corridor with its own short entry flight
## and the exit at the top.

## Which of the seven maps `build()` was asked for, and which door on it leads where. Every other
## file reads this as `int` — see `InteriorMapPlan.Door.target_map`'s own doc.
enum MapKind { HALLWAY_THIRD, HALLWAY_SECOND, HALLWAY_FIRST, STAIRWELL_LEFT, STAIRWELL_RIGHT, LOBBY, BASEMENT }

const _HALLWAY_KINDS: Array[int] = [MapKind.HALLWAY_THIRD, MapKind.HALLWAY_SECOND, MapKind.HALLWAY_FIRST]
## The landing door id each hallway's stair door leads to, in stacking order (top to bottom) —
## the same order `_STAIRWELL_LANDING_IDS` walks when laying out a shaft.
const _HALLWAY_LANDING_ID := {
	MapKind.HALLWAY_THIRD: "landing_third",
	MapKind.HALLWAY_SECOND: "landing_second",
	MapKind.HALLWAY_FIRST: "landing_first",
}

static func build(kind: int) -> InteriorMapPlan:
	match kind:
		MapKind.HALLWAY_THIRD, MapKind.HALLWAY_SECOND, MapKind.HALLWAY_FIRST:
			return _build_hallway(kind)
		MapKind.STAIRWELL_LEFT:
			return _build_stairwell("left")
		MapKind.STAIRWELL_RIGHT:
			return _build_stairwell("right")
		MapKind.LOBBY:
			return _build_lobby()
		MapKind.BASEMENT:
			return _build_basement()
		_:
			push_error("InteriorMap.build: unknown MapKind %d" % kind)
			return InteriorMapPlan.new()

# -------------------------------------------------------------------------------- hallway ---

const HALLWAY_LENGTH := 14
const HALLWAY_ROWS := 2   ## Rows 0 (north, walled) and 1 (south, the apartment-door edge).
const LIFT_COLUMN := 6
const WINDOW_COLUMNS: Array[int] = [2, 4, 9, 11]
## Beside each stair door, lighting the way to it — kept clear of the lift and window columns.
const LAMP_COLUMNS: Array[int] = [0, HALLWAY_LENGTH - 1]
const LEFT_DOOR_COLUMN := 0
const RIGHT_DOOR_COLUMN := HALLWAY_LENGTH - 1
## Her own apartment door, third floor only — implied on the south edge below the view, the same
## as every other apartment door on every floor.
const HALLWAY_START_COLUMN := HALLWAY_LENGTH / 2

static func _build_hallway(kind: int) -> InteriorMapPlan:
	var f := InteriorMapPlan.new()
	f.kind = kind
	for x in HALLWAY_LENGTH:
		f.tiles[Vector2i(x, 0)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N
		f.tiles[Vector2i(x, 1)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S
		f.walls[Vector2i(x, 0)] = InteriorTile.Kind.WALL
	f.walls[Vector2i(LIFT_COLUMN, 0)] = InteriorTile.Kind.LIFT_DOOR
	for c in WINDOW_COLUMNS:
		f.walls[Vector2i(c, 0)] = InteriorTile.Kind.WINDOW
	for c in LAMP_COLUMNS:
		f.walls[Vector2i(c, 0)] = InteriorTile.Kind.WALL_LAMP

	# The two open notches — one at each end, opposite the sketch's both-at-the-right (playtest 55).
	_add_door(f, "left", Vector2i(LEFT_DOOR_COLUMN, 1), MapKind.STAIRWELL_LEFT, _HALLWAY_LANDING_ID[kind])
	_add_door(f, "right", Vector2i(RIGHT_DOOR_COLUMN, 1), MapKind.STAIRWELL_RIGHT, _HALLWAY_LANDING_ID[kind])

	f.start_tile = Vector2i(HALLWAY_START_COLUMN, 1)
	return f

# ------------------------------------------------------------------------------ stairwell ---

## Rows between one landing and the next: a landing (1) + a 3-tile flight down + a 1-tile
## half-landing at the turn + a 3-tile flight back = 8, which returns to the same column, so
## landings stack in one vertical line down the shaft.
const STAIRWELL_LANDING_GAP := 8
const STAIRWELL_FLIGHT_LEN := 3
## The column every landing sits at; the switchback swings `STAIRWELL_FLIGHT_LEN + 1` tiles either
## side of it, so this is comfortably clear of both map edges.
const STAIRWELL_X0 := 4

## Top to bottom. The last has no flights of its own — it is the shaft's own floor, and its door
## leads to the lobby rather than to a hallway.
const _STAIRWELL_LANDINGS: Array[String] = ["landing_third", "landing_second", "landing_first", "landing_lobby"]

## One step off a landing, to the side rather than on the vertical line the flights travel —
## arbitrary, and the same side for every landing on every shaft.
const STAIRWELL_DOOR_OFFSET := Vector2i(-1, 0)

static func _build_stairwell(side: String) -> InteriorMapPlan:
	var f := InteriorMapPlan.new()
	f.kind = MapKind.STAIRWELL_LEFT if side == "left" else MapKind.STAIRWELL_RIGHT
	for i in _STAIRWELL_LANDINGS.size():
		var landing_id: String = _STAIRWELL_LANDINGS[i]
		var y0 := i * STAIRWELL_LANDING_GAP
		var at := Vector2i(STAIRWELL_X0, y0)
		f.tiles[at] = InteriorTile.Kind.LANDING
		f.waypoints[landing_id] = at
		var door_tile := at + STAIRWELL_DOOR_OFFSET
		if i == 0:
			f.start_tile = door_tile
		if i < _HALLWAY_KINDS.size():
			_add_door(f, landing_id, door_tile, _HALLWAY_KINDS[i], side)
		else:
			_add_door(f, landing_id, door_tile, MapKind.LOBBY, side)
		if i == _STAIRWELL_LANDINGS.size() - 1:
			continue   # The lobby landing has nothing further down.
		# Alternates so the shaft zigzags floor by floor rather than always swinging the same way.
		var dir := 1 if i % 2 == 0 else -1
		_lay_flight(f, at, dir)
	return f

## One floor's worth of switchback: a flight of `STAIRWELL_FLIGHT_LEN` diagonal tiles down from
## `top` in `dir` (east for `1`, west for `-1`), a one-tile half-landing at the turn, and a second
## flight back the other way to `top + Vector2i(0, STAIRWELL_LANDING_GAP)` — the next floor's own
## landing, laid by the next loop iteration in `_build_stairwell()`. Every step is diagonal — see
## `InteriorTile.Kind.STAIR_FLIGHT_E`'s own doc — so no walkable tile ever stands beside the run
## without also being part of it, which is the anti-shortcut property `tests/test_interior.gd`
## checks: the only way from one landing to the next is along these flights.
static func _lay_flight(f: InteriorMapPlan, top: Vector2i, dir: int) -> void:
	var down_kind := InteriorTile.Kind.STAIR_FLIGHT_E if dir > 0 else InteriorTile.Kind.STAIR_FLIGHT_W
	var back_kind := InteriorTile.Kind.STAIR_FLIGHT_W if dir > 0 else InteriorTile.Kind.STAIR_FLIGHT_E
	for i in range(1, STAIRWELL_FLIGHT_LEN + 1):
		f.tiles[top + Vector2i(dir * i, i)] = down_kind
	var turn := top + Vector2i(dir * (STAIRWELL_FLIGHT_LEN + 1), STAIRWELL_FLIGHT_LEN + 1)
	f.tiles[turn] = InteriorTile.Kind.LANDING
	for i in range(1, STAIRWELL_FLIGHT_LEN + 1):
		f.tiles[turn + Vector2i(-dir * i, i)] = back_kind

# ---------------------------------------------------------------------------------- lobby ---

const LOBBY_ENTRANCE_COLUMN := 6
const LOBBY_LIFT_COLUMN := LOBBY_ENTRANCE_COLUMN + 3
const LOBBY_LAMP_COLUMNS: Array[int] = [4, 8]
const LOBBY_LEFT_DOOR_COLUMN := 0
const LOBBY_RIGHT_DOOR_COLUMN := HALLWAY_LENGTH - 1
const LOBBY_BASEMENT_COLUMN := LOBBY_ENTRANCE_COLUMN

static func _build_lobby() -> InteriorMapPlan:
	var f := InteriorMapPlan.new()
	f.kind = MapKind.LOBBY
	for x in HALLWAY_LENGTH:
		f.tiles[Vector2i(x, 0)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N
		f.tiles[Vector2i(x, 1)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S
		f.walls[Vector2i(x, 0)] = InteriorTile.Kind.WALL
	f.walls[Vector2i(LOBBY_ENTRANCE_COLUMN, 0)] = InteriorTile.Kind.ENTRANCE_DOOR
	f.entrance_column = LOBBY_ENTRANCE_COLUMN
	f.walls[Vector2i(LOBBY_LIFT_COLUMN, 0)] = InteriorTile.Kind.LIFT_DOOR
	for c in LOBBY_LAMP_COLUMNS:
		f.walls[Vector2i(c, 0)] = InteriorTile.Kind.WALL_LAMP

	_add_door(f, "left", Vector2i(LOBBY_LEFT_DOOR_COLUMN, 1), MapKind.STAIRWELL_LEFT, "landing_lobby")
	_add_door(f, "right", Vector2i(LOBBY_RIGHT_DOOR_COLUMN, 1), MapKind.STAIRWELL_RIGHT, "landing_lobby")
	_add_door(f, "basement", Vector2i(LOBBY_BASEMENT_COLUMN, 1), MapKind.BASEMENT, "entry")

	f.start_tile = Vector2i(LOBBY_ENTRANCE_COLUMN, 1)
	return f

# -------------------------------------------------------------------------------- basement ---

## Three short east-west stretches, each two rows deep like a hallway with its own brick wall
## along its north edge, stacked and jogged so the corridor "runs north, jogs, runs north again"
## the way the sketch draws it (`escape-basement-sketch-01.jpg`) — entry at the bottom, exit at the
## top. Connected by narrow one-tile jogs rather than by widening a single band, which is where the
## sketch's debris, rat and puddles sit.
static func _build_basement() -> InteriorMapPlan:
	var f := InteriorMapPlan.new()
	f.kind = MapKind.BASEMENT

	# Band A, nearest the entry.
	_lay_basement_band(f, 0, 10, 4)
	# The jog right, into band B.
	for y in [8, 9]:
		f.tiles[Vector2i(4, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# Band B, shifted two east of band A — the sketch's rightward jog.
	_lay_basement_band(f, 2, 6, 6)
	# The jog left, into band C.
	for y in [2, 3, 4, 5]:
		f.tiles[Vector2i(2, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# Band C, back under band A's own columns — the sketch's leftward jog, and the exit's band.
	_lay_basement_band(f, 0, 0, 4)

	# The entry: a short diagonal flight up from the lobby's own door into band A's floor.
	_add_door(f, "entry", Vector2i(2, 13), MapKind.LOBBY, "basement")
	f.tiles[Vector2i(1, 12)] = InteriorTile.Kind.STAIR_FLIGHT_E
	f.tiles[Vector2i(0, 11)] = InteriorTile.Kind.STAIR_FLIGHT_E

	f.exit_tile = Vector2i(1, 0)
	f.tiles[f.exit_tile] = InteriorTile.Kind.EMERGENCY_EXIT

	f.decals[Vector2i(3, 11)] = InteriorTile.Kind.PUDDLE
	f.decals[Vector2i(5, 7)] = InteriorTile.Kind.DEBRIS
	f.decals[Vector2i(2, 3)] = InteriorTile.Kind.RAT

	f.start_tile = f.doors["entry"].tile
	return f

## One two-row band of basement floor, brick-walled along its own north edge (`wall_row`), from
## `x_min` to `x_max` inclusive.
static func _lay_basement_band(f: InteriorMapPlan, x_min: int, wall_row: int, x_max: int) -> void:
	for x in range(x_min, x_max + 1):
		f.tiles[Vector2i(x, wall_row)] = InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N
		f.tiles[Vector2i(x, wall_row + 1)] = InteriorTile.Kind.BASEMENT_FLOOR_EDGE_S
		f.walls[Vector2i(x, wall_row)] = InteriorTile.Kind.BRICK_WALL

# ---------------------------------------------------------------------------------- doors ---

static func _add_door(f: InteriorMapPlan, id: String, tile: Vector2i, target_map: int, target_door: String) -> void:
	var d := InteriorMapPlan.Door.new()
	d.id = id
	d.tile = tile
	d.target_map = target_map
	d.target_door = target_door
	f.tiles[tile] = InteriorTile.Kind.DOOR
	f.doors[id] = d
