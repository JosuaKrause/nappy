class_name InteriorMap
extends RefCounted
## Builds the escape scene's one building-wide map, from the player's four sketches
## (`docs/reference/escape-{floor-hallway,stairwell,lobby,basement}-sketch-01.jpg`) — a small,
## hand-shaped plan of `InteriorTile.Kind` cells, independent of `CityMap`'s own lattice, generator
## and guarantees: a building with one way through it has no route-redundancy invariant to keep.
## See `docs/TODO.md`, "M112 — The escape scene, walkable" for the brief this lays out.
##
## **Seven parts, one shared grid, joined only by doors.** Each part — three hallways, two
## stairwells, the lobby, the basement — is laid out at its own `_ORIGIN`, `_SLOT_STRIDE` (64
## tiles) apart from its neighbours in the slot order below. `Stroller`'s `Camera2D` at zoom 2 sees
## 640×360, 20×11.25 tiles — so a 64-tile stride leaves at least 50 tiles of nothing between any
## two parts' own footprints on every side, far more than a screen could ever span, which is what
## makes "no part is in view from another" true by construction rather than by measurement.
## `tests/test_interior.gd` still checks it, by flood fill.
##
## Three hallways share one layout: a 14-tile east-west hallway, two rows deep, with a stair door
## at each end — opposite ends, not the two the sketch drew both at the right, a player decision
## (playtest 55: "that way having a fire on the stairs forces you to enter a floor hallway and walk
## to the other end"). Two independent stairwells, each a tall plain switchback — one flight down
## and one flight back per floor, alternating direction — with no map load mid-shaft, since there
## is only the one map. The lobby is the hallway's own width with the barricaded entrance and doors
## to both stairwells and the basement. The basement is the winding corridor with its own short
## entry flight and the exit at the top.

const _SLOT_STRIDE := 64
const _HALLWAY_THIRD_ORIGIN := Vector2i(0 * _SLOT_STRIDE, 0)
const _STAIRWELL_LEFT_ORIGIN := Vector2i(1 * _SLOT_STRIDE, 0)
const _STAIRWELL_RIGHT_ORIGIN := Vector2i(2 * _SLOT_STRIDE, 0)
const _HALLWAY_SECOND_ORIGIN := Vector2i(3 * _SLOT_STRIDE, 0)
const _HALLWAY_FIRST_ORIGIN := Vector2i(4 * _SLOT_STRIDE, 0)
const _LOBBY_ORIGIN := Vector2i(5 * _SLOT_STRIDE, 0)
const _BASEMENT_ORIGIN := Vector2i(6 * _SLOT_STRIDE, 0)

## `--start-escape <part>`'s own recognised words, and the `tests/test_interior.gd` per-part flood
## seed — the same list, since both questions are "where does this part begin".
const PARTS: Array[String] = [
	"hallway_third", "hallway_second", "hallway_first",
	"stairwell_left", "stairwell_right", "lobby", "basement",
]

static func build() -> InteriorMapPlan:
	var f := InteriorMapPlan.new()
	_build_hallway(f, "hallway_third", _HALLWAY_THIRD_ORIGIN, true)
	_build_hallway(f, "hallway_second", _HALLWAY_SECOND_ORIGIN, false)
	_build_hallway(f, "hallway_first", _HALLWAY_FIRST_ORIGIN, false)
	_build_stairwell(f, "left", _STAIRWELL_LEFT_ORIGIN)
	_build_stairwell(f, "right", _STAIRWELL_RIGHT_ORIGIN)
	_build_lobby(f, _LOBBY_ORIGIN)
	_build_basement(f, _BASEMENT_ORIGIN)
	f.start_tile = f.waypoints["hallway_third"]
	_mark_diagonal_clearances(f)
	return f

## The two cells flanking every diagonal step between two walkable tiles touch each other only at
## a single corner point — a circular body of any real radius cannot cross a pinch with a full-tile
## blocker on both flanks, which is what made a diagonal flight unwalkable in practice the first
## time this was played rather than only stepped by a headless test. Freeing both flanks of every
## diagonal adjacency, once, over the whole finished plan, fixes every flight and the basement's own
## entry flight alike without threading the concept through each place a diagonal tile is laid.
static func _mark_diagonal_clearances(f: InteriorMapPlan) -> void:
	var diagonals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for t: Vector2i in f.tiles.keys():
		for d in diagonals:
			if f.tiles.has(t + d):
				f.collision_clearance[Vector2i(t.x + d.x, t.y)] = true
				f.collision_clearance[Vector2i(t.x, t.y + d.y)] = true

# -------------------------------------------------------------------------------- hallway ---

## Rows 0 (north, walled) and 1 (south, the apartment-door edge) — a hallway is always these two.
const HALLWAY_LENGTH := 14
const LIFT_COLUMN := 6
const WINDOW_COLUMNS: Array[int] = [2, 4, 9, 11]
## Beside each stair door, lighting the way to it — kept clear of the lift and window columns.
const LAMP_COLUMNS: Array[int] = [0, HALLWAY_LENGTH - 1]
const LEFT_DOOR_COLUMN := 0
const RIGHT_DOOR_COLUMN := HALLWAY_LENGTH - 1
## Her own apartment door, third floor only — implied on the south edge below the view, the same
## as every other apartment door on every floor.
const HALLWAY_START_COLUMN := HALLWAY_LENGTH / 2

## `id` is "hallway_third"/"hallway_second"/"hallway_first" — the part name every door and
## waypoint on this hallway is prefixed with, and the name `_build_stairwell()` reads back to wire
## up the counterpart on each landing door.
static func _build_hallway(f: InteriorMapPlan, id: String, origin: Vector2i, is_start: bool) -> void:
	for x in HALLWAY_LENGTH:
		f.tiles[origin + Vector2i(x, 0)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N
		f.tiles[origin + Vector2i(x, 1)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S
		f.walls[origin + Vector2i(x, 0)] = InteriorTile.Kind.WALL
	f.walls[origin + Vector2i(LIFT_COLUMN, 0)] = InteriorTile.Kind.LIFT_DOOR
	for c in WINDOW_COLUMNS:
		f.walls[origin + Vector2i(c, 0)] = InteriorTile.Kind.WINDOW
	for c in LAMP_COLUMNS:
		f.walls[origin + Vector2i(c, 0)] = InteriorTile.Kind.WALL_LAMP

	# The two open notches — one at each end, opposite the sketch's both-at-the-right (playtest 55).
	_add_door(f, "%s:left" % id, origin + Vector2i(LEFT_DOOR_COLUMN, 1), "stairwell_left:landing_%s" % id.trim_prefix("hallway_"))
	_add_door(f, "%s:right" % id, origin + Vector2i(RIGHT_DOOR_COLUMN, 1), "stairwell_right:landing_%s" % id.trim_prefix("hallway_"))

	var start := origin + Vector2i(HALLWAY_START_COLUMN, 1)
	f.waypoints[id] = start
	if is_start:
		f.start_tile = start

# ------------------------------------------------------------------------------ stairwell ---

## Rows between one landing and the next: a landing (1) + a 3-tile flight down + a 1-tile
## half-landing at the turn + a 3-tile flight back = 8, which returns to the same column, so
## landings stack in one vertical line down the shaft.
const STAIRWELL_LANDING_GAP := 8
const STAIRWELL_FLIGHT_LEN := 3
## The column every landing sits at (local to the shaft's own origin); the switchback swings
## `STAIRWELL_FLIGHT_LEN + 1` tiles either side of it, so this is comfortably clear of both the
## shaft's own left edge and the next part's slot.
const STAIRWELL_X0 := 4
## One step off a landing, to the side rather than on the vertical line the flights travel —
## arbitrary, and the same side for every landing on every shaft.
const STAIRWELL_DOOR_OFFSET := Vector2i(-1, 0)

## Top to bottom. The last has no flights of its own — it is the shaft's own floor, and its door
## leads to the lobby rather than to a hallway.
const _STAIRWELL_LANDINGS: Array[String] = ["landing_third", "landing_second", "landing_first", "landing_lobby"]
const _STAIRWELL_HALLWAYS: Array[String] = ["hallway_third", "hallway_second", "hallway_first"]

static func _build_stairwell(f: InteriorMapPlan, side: String, origin: Vector2i) -> void:
	var part_id := "stairwell_%s" % side
	for i in _STAIRWELL_LANDINGS.size():
		var landing_id: String = _STAIRWELL_LANDINGS[i]
		var y0 := i * STAIRWELL_LANDING_GAP
		var at := origin + Vector2i(STAIRWELL_X0, y0)
		f.tiles[at] = InteriorTile.Kind.LANDING
		f.waypoints["%s:%s" % [part_id, landing_id]] = at
		if i == 0:
			f.waypoints[part_id] = at
		var door_tile := at + STAIRWELL_DOOR_OFFSET
		var counterpart := "%s:%s" % [_STAIRWELL_HALLWAYS[i], side] if i < _STAIRWELL_HALLWAYS.size() \
				else "lobby:%s" % side
		_add_door(f, "%s:%s" % [part_id, landing_id], door_tile, counterpart)
		if i == _STAIRWELL_LANDINGS.size() - 1:
			continue   # The lobby landing has nothing further down.
		# Alternates so the shaft zigzags floor by floor rather than always swinging the same way.
		var dir := 1 if i % 2 == 0 else -1
		_lay_flight(f, at, dir)

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

static func _build_lobby(f: InteriorMapPlan, origin: Vector2i) -> void:
	for x in HALLWAY_LENGTH:
		f.tiles[origin + Vector2i(x, 0)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N
		f.tiles[origin + Vector2i(x, 1)] = InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S
		f.walls[origin + Vector2i(x, 0)] = InteriorTile.Kind.WALL
	f.walls[origin + Vector2i(LOBBY_ENTRANCE_COLUMN, 0)] = InteriorTile.Kind.ENTRANCE_DOOR
	f.entrance_tiles.append(origin + Vector2i(LOBBY_ENTRANCE_COLUMN, 0))
	f.walls[origin + Vector2i(LOBBY_LIFT_COLUMN, 0)] = InteriorTile.Kind.LIFT_DOOR
	for c in LOBBY_LAMP_COLUMNS:
		f.walls[origin + Vector2i(c, 0)] = InteriorTile.Kind.WALL_LAMP

	_add_door(f, "lobby:left", origin + Vector2i(LOBBY_LEFT_DOOR_COLUMN, 1), "stairwell_left:landing_lobby")
	_add_door(f, "lobby:right", origin + Vector2i(LOBBY_RIGHT_DOOR_COLUMN, 1), "stairwell_right:landing_lobby")
	_add_door(f, "lobby:basement", origin + Vector2i(LOBBY_BASEMENT_COLUMN, 1), "basement:entry")

	f.waypoints["lobby"] = origin + Vector2i(LOBBY_ENTRANCE_COLUMN, 1)

# -------------------------------------------------------------------------------- basement ---

## Three short east-west stretches, each two rows deep like a hallway with its own brick wall
## along its north edge, stacked and jogged so the corridor "runs north, jogs, runs north again"
## the way the sketch draws it (`escape-basement-sketch-01.jpg`) — entry at the bottom, exit at the
## top. Connected by narrow one-tile jogs rather than by widening a single band, which is where the
## sketch's debris, rat and puddles sit.
static func _build_basement(f: InteriorMapPlan, origin: Vector2i) -> void:
	# Band A, nearest the entry.
	_lay_basement_band(f, origin, 0, 10, 4)
	# The jog right, into band B.
	for y in [8, 9]:
		f.tiles[origin + Vector2i(4, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# Band B, shifted two east of band A — the sketch's rightward jog.
	_lay_basement_band(f, origin, 2, 6, 6)
	# The jog left, into band C.
	for y in [2, 3, 4, 5]:
		f.tiles[origin + Vector2i(2, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# Band C, back under band A's own columns — the sketch's leftward jog, and the exit's band.
	_lay_basement_band(f, origin, 0, 0, 4)

	# The entry: a short diagonal flight up from the lobby's own door into band A's floor.
	_add_door(f, "basement:entry", origin + Vector2i(2, 13), "lobby:basement")
	f.tiles[origin + Vector2i(1, 12)] = InteriorTile.Kind.STAIR_FLIGHT_E
	f.tiles[origin + Vector2i(0, 11)] = InteriorTile.Kind.STAIR_FLIGHT_E

	f.exit_tile = origin + Vector2i(1, 0)
	f.tiles[f.exit_tile] = InteriorTile.Kind.EMERGENCY_EXIT

	f.decals[origin + Vector2i(3, 11)] = InteriorTile.Kind.PUDDLE
	f.decals[origin + Vector2i(5, 7)] = InteriorTile.Kind.DEBRIS
	f.decals[origin + Vector2i(2, 3)] = InteriorTile.Kind.RAT

	f.waypoints["basement"] = f.doors["basement:entry"].tile

## One two-row band of basement floor, brick-walled along its own north edge (`wall_row`), from
## `x_min` to `x_max` inclusive, all local to `origin`.
static func _lay_basement_band(f: InteriorMapPlan, origin: Vector2i, x_min: int, wall_row: int, x_max: int) -> void:
	for x in range(x_min, x_max + 1):
		f.tiles[origin + Vector2i(x, wall_row)] = InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N
		f.tiles[origin + Vector2i(x, wall_row + 1)] = InteriorTile.Kind.BASEMENT_FLOOR_EDGE_S
		f.walls[origin + Vector2i(x, wall_row)] = InteriorTile.Kind.BRICK_WALL

# ---------------------------------------------------------------------------------- doors ---

static func _add_door(f: InteriorMapPlan, id: String, tile: Vector2i, target_door: String) -> void:
	var d := InteriorMapPlan.Door.new()
	d.id = id
	d.tile = tile
	d.target_door = target_door
	f.tiles[tile] = InteriorTile.Kind.DOOR
	f.doors[id] = d
