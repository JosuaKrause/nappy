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
## to the other end"). **The top floor's right half is shut by a fallen ceiling** — see
## `TOP_FLOOR_RUBBLE` — so the first flight out of her own door is always the left one.
## Two independent stairwells each alternate one lateral flight per floor, with
## corridor doors beside the level approaches at opposite flight ends and no map load mid-shaft,
## since there is only the one map. The lobby is the hallway's own width with the barricaded
## entrance and doors to both stairwells and the basement. Each stairwell is the corrected
## ten-column symbol grammar:
## its reviewed stair-side pictures are the walkable `t/m/T/M` cells themselves, while `c/C/b`
## and background stay solid. The basement is the winding corridor with its own one-tile entry
## stair and the exit at the top.

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

## The part each slot holds, in slot order — the same order as the `_ORIGIN`s above.
const _SLOT_PARTS: Array[String] = [
	"hallway_third", "stairwell_left", "stairwell_right", "hallway_second", "hallway_first",
	"lobby", "basement",
]

## Which part `tile` belongs to, or `""` for a tile in no slot. By slot rather than by looking the
## tile up, so a wall cell or a threshold just outside a part's floor answers the same as the floor
## beside it: every part starts at its own origin and is far narrower than the stride, and the gap
## either side of it is dozens of tiles of nothing, so the nearest origin is the part.
static func part_at(tile: Vector2i) -> String:
	var slot := floori((float(tile.x) + _SLOT_STRIDE * 0.25) / float(_SLOT_STRIDE))
	if slot < 0 or slot >= _SLOT_PARTS.size():
		return ""
	return _SLOT_PARTS[slot]

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

## A diagonal step pinches only when neither orthogonal neighbor is walkable, and **nothing in the
## building has that shape today**: the main shafts' `t/m` and `T/M` pairs make a two-row surface
## whose every diagonal step has the other role in one corner, and the basement's entry is a
## straight column from its door. The pass stays because the shape is one tile away — a flight
## narrowed to one row, or a jog cut to a corner — and a 14px body cannot cross a corner point
## between two full-cell blockers at all, which is a map that looks connected and is not. It only
## ever *frees* an absent corner: every `.` background cell and every painted `c/C/b` side stays
## blocked exactly as the grammar says.
static func _mark_diagonal_clearances(f: InteriorMapPlan) -> void:
	var diagonals: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for t: Vector2i in f.tiles.keys():
		if not f.is_walkable(t):
			continue
		for d in diagonals:
			if not f.is_walkable(t + d):
				continue
			var corner_a := Vector2i(t.x + d.x, t.y)
			var corner_b := Vector2i(t.x, t.y + d.y)
			if f.is_walkable(corner_a) or f.is_walkable(corner_b):
				continue
			if not f.tiles.has(corner_a):
				f.collision_clearance[corner_a] = true
			if not f.tiles.has(corner_b):
				f.collision_clearance[corner_b] = true

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
## The sparse south-edge apartment recesses read as individual apartments instead of a repeated
## floor trim. The starting recess is included so her home has the same visual language.
const LOCKED_APARTMENT_COLUMNS: Array[int] = [2, 5, HALLWAY_START_COLUMN, 10]

## The ceiling down across the top floor, local to that hallway's own origin: two columns, **both
## rows**, between her own door at column 7 and the right stair door at column 13.
##
## **Both rows, or it is not a wall.** A hallway is two tiles deep and a heap on one row is
## something to walk round; this closes the corridor outright, so from her own door the right
## stairwell cannot be entered on the top floor at all and the first flight she takes is the left
## one — the side the fire is on. Two columns rather than one because 32px of debris across a
## 64px-deep corridor reads as a strip of decoration; 64px reads as a collapse.
##
## **Columns 8 and 9 rather than any other pair.** Anywhere strictly between the two doors closes
## the same ground, and these are the pair that sits under a window (column 9) and clear of every
## apartment recess (`LOCKED_APARTMENT_COLUMNS`), so nothing it covers is a threshold somebody
## could mistake for a way through.
const TOP_FLOOR_RUBBLE := Rect2i(8, 0, 2, 2)

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
	for column in LOCKED_APARTMENT_COLUMNS:
		f.locked_thresholds.append(origin + Vector2i(column, 1))

	var start := origin + Vector2i(HALLWAY_START_COLUMN, 1)
	f.waypoints[id] = start
	if is_start:
		f.start_tile = start
		# The collapse is laid down here, with the floor, rather than checked for afterwards: the
		# top floor is built with the right half already shut, so nothing ever places anything on
		# ground the rubble then has to be reconciled with.
		f.rubble = Rect2i(origin + TOP_FLOOR_RUBBLE.position, TOP_FLOOR_RUBBLE.size)

# ------------------------------------------------------------------------------ stairwell ---

## The player-supplied grammar's first 22 rows are literal. The final four finish the same
## east-descending landing far enough to place the fourth (`lobby`) door and its two-cell level
## approach; no unused next flight is appended below it.
const STAIRWELL_ROWS: Array[String] = [
	"..........",
	".D........",
	".Ft.......",
	".Fmt......",
	".bcmt.....",
	"...cmt....",
	"....cmt...",
	".....cmtD.",
	"......cmF.",
	".......cF.",
	".......TF.",
	"......TMF.",
	".....TMCb.",
	"....TMC...",
	"...TMC....",
	".DTMC.....",
	".FMC......",
	".FC.......",
	".Ft.......",
	".Fmt......",
	".bcmt.....",
	"...cmt....",
	"....cmt...",
	".....cmtD.",
	"......cmF.",
	".......cF.",
]
const STAIRWELL_SIZE := Vector2i(10, 26)
## Every named landing waypoint is the first level `F` below its door, local to the grammar.
const STAIRWELL_TOP_LANDING_LOCAL := Vector2i(1, 2)

## Top to bottom. The last has no flights of its own — it is the shaft's own floor, and its door
## leads to the lobby rather than to a hallway.
const _STAIRWELL_LANDINGS: Array[String] = ["landing_third", "landing_second", "landing_first", "landing_lobby"]
const _STAIRWELL_HALLWAYS: Array[String] = ["hallway_third", "hallway_second", "hallway_first"]

static func _build_stairwell(f: InteriorMapPlan, side: String, origin: Vector2i) -> void:
	var part_id := "stairwell_%s" % side
	var door_index := 0
	for y in STAIRWELL_ROWS.size():
		var row: String = STAIRWELL_ROWS[y]
		for x in row.length():
			var symbol := row.substr(x, 1)
			if symbol == ".":
				continue
			var at := origin + Vector2i(x, y)
			if symbol == "D":
				var landing_id: String = _STAIRWELL_LANDINGS[door_index]
				var counterpart := "%s:%s" % [_STAIRWELL_HALLWAYS[door_index], side] \
						if door_index < _STAIRWELL_HALLWAYS.size() else "lobby:%s" % side
				_add_door(f, "%s:%s" % [part_id, landing_id], at, counterpart)
				var landing := at + Vector2i.DOWN
				f.waypoints["%s:%s" % [part_id, landing_id]] = landing
				if door_index == 0:
					f.waypoints[part_id] = landing
				door_index += 1
				continue
			f.tiles[at] = stair_kind_for_symbol(symbol)
	if door_index != _STAIRWELL_LANDINGS.size():
		push_error("Stairwell grammar placed %d doors, expected %d" \
				% [door_index, _STAIRWELL_LANDINGS.size()])

## The tile kind one non-background stair symbol paints. Kept public so the focused suite can ask
## the same parser the runtime uses instead of maintaining a second symbol-to-kind table.
static func stair_kind_for_symbol(symbol: String) -> InteriorTile.Kind:
	match symbol:
		"F":
			return InteriorTile.Kind.STAIRWELL_FLOOR
		"t":
			return InteriorTile.Kind.STAIR_TOP_E
		"m":
			return InteriorTile.Kind.STAIR_MIDDLE_E
		"T":
			return InteriorTile.Kind.STAIR_TOP_W
		"M":
			return InteriorTile.Kind.STAIR_MIDDLE_W
		"c":
			return InteriorTile.Kind.STAIR_CORNER_E
		"C":
			return InteriorTile.Kind.STAIR_CORNER_W
		"b":
			return InteriorTile.Kind.STAIR_BLOCK
		_:
			push_error("Unknown stairwell grammar symbol '%s'" % symbol)
			return InteriorTile.Kind.NONE

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

	# **A part's waypoint is never a door's own tile.** `--start-escape <part>` puts her down at
	# this position with nothing armed, and `InteriorScene.process_player()` fires a transition on
	# the frame she is standing on a door — so a waypoint that *is* the basement notch sends her
	# straight down to the basement instead of showing her the lobby. One column east of the
	# entrance, which is still in front of the barricade and is nobody's threshold.
	f.waypoints["lobby"] = origin + Vector2i(LOBBY_ENTRANCE_COLUMN + 1, 1)

# -------------------------------------------------------------------------------- basement ---

## Where the corridor is one tile wide on the way to the exit, local to the basement's own origin
## and **in the order she meets them walking up from the entry**: the jog between bands A and B,
## the narrowing laid across band B, and the jog between bands B and C. A steam vent stands on each
## (`InteriorEvents._vent_sites()`).
##
## **One cloud is the whole width here, which is what the vents are for.** *(2026-09-19: "there are
## only two steams and they are not blocking in any way they should go in the narrow hallways.")*
## A vent in a two-row band leaves a lane whichever row it stands on; in a one-tile passage her
## centre has 16px of play either side of the middle and the blow holds it 30px out, so there is no
## line past a vent that is blowing and the answer is waiting rather than aiming.
##
## Two of the three are the jogs the sketch already drew; `BASEMENT_PINCH` is the third and is laid
## rather than found, since the sketch gives band B no narrow stretch of its own.
##
## The entry stair is one tile wide too and is deliberately not one of these: it is the cell a door
## puts her down on, and a gate on a threshold is a gate she arrives inside.
const BASEMENT_NARROWS: Array[Vector2i] = [Vector2i(4, 9), Vector2i(3, 6), Vector2i(2, 3)]

## The column of band B whose **south** row is never laid, so the band pinches to its wall row
## there. Band B runs east-west between the two jogs, so a walk from one to the other has to pass
## this column whichever row it is on. The south row rather than the north, because the north row
## carries the band's brick wall and the passage then hugs something she can see.
const BASEMENT_PINCH := 3

## Three short east-west stretches, each two rows deep like a hallway with its own brick wall
## along its north edge, stacked and jogged so the corridor "runs north, jogs, runs north again"
## the way the sketch draws it (`escape-basement-sketch-01.jpg`) — entry at the bottom, exit at the
## top. Connected by narrow one-tile jogs rather than by widening a single band, which is where the
## sketch's debris, rat and puddles sit, and pinched once across band B so that the corridor offers
## three one-tile gates rather than two — see `BASEMENT_NARROWS`.
static func _build_basement(f: InteriorMapPlan, origin: Vector2i) -> void:
	# Band A, nearest the entry.
	_lay_basement_band(f, origin, 0, 10, 4)
	# The jog right, into band B.
	for y in [8, 9]:
		f.tiles[origin + Vector2i(4, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# This is an open mouth between the two bands, not a brick wall across a walkable passage.
	f.walls.erase(origin + Vector2i(4, 10))
	# Band B, shifted two east of band A — the sketch's rightward jog — pinched to its wall row at
	# one column. **Laid with the gap rather than laid and then cut**: a band that was built whole
	# and had a cell taken out of it afterwards is the shape this repository refuses everywhere
	# else, and the narrowing is part of what the basement *is*.
	_lay_basement_band(f, origin, 2, 6, 6, BASEMENT_PINCH)
	# The jog left, into band C.
	for y in [2, 3, 4, 5]:
		f.tiles[origin + Vector2i(2, y)] = InteriorTile.Kind.BASEMENT_FLOOR
	# The second jog enters band B through another open mouth.
	f.walls.erase(origin + Vector2i(2, 6))
	# Band C, back under band A's own columns — the sketch's leftward jog, and the exit's band.
	_lay_basement_band(f, origin, 0, 0, 4)
	for narrow in BASEMENT_NARROWS:
		f.corridor_narrows.append(origin + narrow)

	# The entry: the lobby's own door, the stair she came down, and band A's floor — one straight
	# column, north from the door, seen from the front. *(Playtest 55, sketching the basement:
	# "basement starts at the bottom (horizontal lines indicate a small stair leading down)".)*
	# One cell rather than a run of them, because `stair_down.svg` draws a complete flight inside
	# its own tile — widest tread at the near edge, narrowest at the far one — so two of them
	# stacked read as two stairs rather than as one longer flight.
	_add_door(f, "basement:entry", origin + Vector2i(2, 13), "lobby:basement")
	f.tiles[origin + Vector2i(2, 12)] = InteriorTile.Kind.STAIR_DOWN

	f.exit_tile = origin + Vector2i(1, 0)
	f.tiles[f.exit_tile] = InteriorTile.Kind.EMERGENCY_EXIT

	f.decals[origin + Vector2i(3, 11)] = InteriorTile.Kind.PUDDLE
	f.decals[origin + Vector2i(5, 7)] = InteriorTile.Kind.DEBRIS
	# One cell further up its jog than the other two decals sit in theirs, so the rat is not drawn
	# under the steam vent that stands on this jog's own gate (`BASEMENT_NARROWS`).
	f.decals[origin + Vector2i(2, 2)] = InteriorTile.Kind.RAT

	# The corridor cell the entry stair arrives at, for the same reason the lobby's is not its own
	# notch: the entry door's tile would teleport her back up to the lobby on the first frame.
	f.waypoints["basement"] = origin + Vector2i(2, 11)

## One two-row band of basement floor, brick-walled along its own north edge (`wall_row`), from
## `x_min` to `x_max` inclusive, all local to `origin`. `pinch_column` is a column whose south row
## is never laid at all, so the band is one tile wide there — see `BASEMENT_NARROWS`; `-1`, the
## default, lays the band whole.
static func _lay_basement_band(f: InteriorMapPlan, origin: Vector2i, x_min: int, wall_row: int,
		x_max: int, pinch_column := -1) -> void:
	for x in range(x_min, x_max + 1):
		f.tiles[origin + Vector2i(x, wall_row)] = InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N
		if x != pinch_column:
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
