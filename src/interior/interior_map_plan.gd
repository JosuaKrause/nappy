class_name InteriorMapPlan
extends WorldMap
## The escape scene's whole building as **one** map: a sparse grid of `InteriorTile.Kind` cells
## holding all seven parts — three hallways, two stairwells, the lobby and the basement — laid out
## with wide unwalkable gaps between them, joined only by doors that teleport rather than by a
## shared floor. *(2026-09-10, playtest 55: "instead of multiple maps have all parts of the house
## on the same map with enough space inbetween and on transition fade to black, teleport, then
## fade in again".)* Built once by `InteriorMap.build()`; nothing here mutates it afterwards.
##
## **There is no "current part".** A door does not load or free anything — it moves her, the same
## map open the whole time — so the only state a transition touches is her own position and the
## camera that follows it.
##
## **The building's `WorldMap`**: the ground is walkable where `is_walkable()` says she may stand and
## closed everywhere else — the solid between two flights, a stair side, the rubble, the gaps between
## parts — so a field indoors is stopped at exactly the depths a field outdoors is
## (`WorldMap.wall_between()`), and a figure walks round the same walls she does
## (`WorldMap.passable()`). It has no streets, so every street question answers "no street". And
## the building's pure geometry is here — its flights' bands, the walks down its stairwells and its
## basement, where its events are sited, what a door leads to — so the scene that draws it
## (`InteriorScene`) and the events placed in it read one map.

## A threshold that teleports to another door's own tile — or, for the basement's
## `EMERGENCY_EXIT`, to the title screen instead, which is not a `Door` at all; see
## `InteriorScene._start_exit()`.
class Door:
	var id := ""              ## Globally unique — "hallway_third:left", "stairwell_left:landing_third".
	var tile := Vector2i.ZERO ## Where this door's threshold stands.
	var target_door := ""     ## The id of the door this one teleports to.

## Tile position -> `InteriorTile.Kind`, for every painted interior cell any part actually has
## (door thresholds included). Most are walkable ground; the stair grammar also paints `c`, `C`
## and `b` as non-walkable stair sides. A position absent from this dictionary has no floor at all
## and is therefore not walkable — see `is_walkable()`. The gaps between parts are exactly the
## positions absent here.
var tiles: Dictionary = {}
## A wall-anchor position -> `InteriorTile.Kind`, elevation drawn at that cell's own north edge.
## Not part of `tiles`: nothing ever stands *on* a wall cell, so a wall needs a position to be
## drawn at rather than a floor-grid position.
var walls: Dictionary = {}
## Where a fresh run starts — the third floor's own door, mid-hallway on its south edge.
var start_tile := Vector2i.ZERO
## `id -> Door`, every door in the building.
var doors: Dictionary = {}
## Apartment recesses that look locked but do not change the hallway's floor or routing. They are
## kept apart from `doors`: an apartment is scenery, while a `Door` is a playable transition.
var locked_thresholds: Array[Vector2i] = []
## `Vector2i(-1, -1)` unless the basement's own exit has been placed.
var exit_tile := Vector2i(-1, -1)
## Every barricaded entrance position — read by the renderer to place the barricade and by tests
## that assert what stands in the wall there. Only the lobby has one, but keyed by position rather
## than held as a single field, the same reasoning `walls` already follows now that everything
## shares one coordinate space.
var entrance_tiles: Array[Vector2i] = []
## Ground decals — `PUDDLE`, `DEBRIS` or `RAT` — that change nothing about what is walkable
## beneath them. `tile -> InteriorTile.Kind`.
var decals: Dictionary = {}
## Cells that are not floor (absent from `tiles`) but must not get a collision blocker either.
## Only a diagonal step with no walkable orthogonal neighbor needs the two flanks cleared: the
## basement's one-cell entry can otherwise pinch a circular body between two blockers. The main
## stair grammar has two walkable rows, so its `.` background remains blocked and its `c`, `C`
## and `b` cells remain explicit blockers.
var collision_clearance: Dictionary = {}
## A named position that is not a door — a stairwell's own landing platform, a hallway's mid-point,
## the lobby's own floor — used both as `--start-escape <part>`'s teleport target and, in
## `tests/test_interior.gd`, as the seed a per-part flood fill starts from. `id -> Vector2i`.
var waypoints: Dictionary = {}
## Where the basement corridor is one tile wide on the way to the exit, in the order she meets them
## walking up from the entry — see `InteriorMap.BASEMENT_NARROWS` for which they are and why the
## entry stair is not among them. A gate stands on each; the layout says where a gate *can* stand
## and the building's placements decide what stands there (`BuildingPlan`).
var corridor_narrows: Array[Vector2i] = []
## The cells the fallen ceiling fills, as one tile rect — floor that is painted and drawn over but
## cannot be stood on. Its own field rather than a tile kind, because what is underneath a heap is
## still this hallway's floor and is still drawn as one; a `RUBBLE` kind would have to repaint the
## ground as well as close it, and the ground is not what changed. `Rect2i()` — zero size, so
## `has_point()` is false everywhere — for a building with no collapse in it.
var rubble := Rect2i()

## Each tile's walkability as one byte (`walk_tiles()`), row by row over `size`; built by `finish()`.
var _grid := PackedByteArray()
## Every solid cell beside a flight whose blocker is cut to the flight's band
## (`blocker_outline()`), as the part of it that stays solid, in world space: what a line through the
## cell meets (`_ground_stops()`). Built by `finish()`.
var _cut_cells := {}

## Whether a walker may stand here. **The rubble is asked first**, since its cells carry ordinary
## walkable floor and are closed by the collapse rather than by the kind painted under it.
func is_walkable(tile: Vector2i) -> bool:
	if rubble.has_point(tile):
		return false
	return InteriorTile.is_walkable(tiles.get(tile, InteriorTile.Kind.NONE))

func door(id: String) -> Door:
	return doors.get(id)

## Sizes the map to the building's footprint and lays its walkability out as a grid, once every part
## is laid (`InteriorMap.build()`). The building starts at tile (0, 0) — the slots run east from it
## and every part's rows south — and a tile off the grid is closed, as it is off the city's.
func finish() -> void:
	var box := footprint()
	if box.position.x < 0 or box.position.y < 0:
		push_error("the building reaches tile %s, west or north of its map's origin" % box.position)
	size = box.end
	_grid = PackedByteArray()
	_grid.resize(size.x * size.y)
	for tile: Vector2i in tiles:
		if in_bounds(tile) and is_walkable(tile):
			_grid[tile.y * size.x + tile.x] = 1
	_cut_cells.clear()
	var bands := flight_bands()
	for band: Dictionary in bands:
		for tile: Vector2i in band["cells"]:
			if _cut_cells.has(tile):
				continue
			var outline := blocker_outline(tile, bands)
			if outline.is_empty():
				continue
			var placed := PackedVector2Array()
			for point in outline:
				placed.append(tile_to_world(tile) + point)
			_cut_cells[tile] = placed

# ------------------------------------------------------------------- WorldMap ---

func has_ground() -> bool:
	return true

## The ground as built: walkable floor for anything the floor stops, and no street ground at all.
func _ground_lets(tile: Vector2i, layers: int) -> bool:
	if layers & Mover.STREETS != 0:
		return false
	return layers & Mover.GROUND == 0 or is_walkable(tile)

## **A step or a line beside a flight meets what her body meets**: a solid cell beside a flight is cut
## to the flight's band (`blocker_outline()`, the blocker she collides with), so a line through the
## cut part of it passes and only one that meets the part left standing is stopped. A figure walking
## a flight's own cells corner to corner — the masked man running the shaft — goes where she can.
## Every other closed tile stops it whole.
func _ground_stops(tile: Vector2i, layers: int, from: Vector2, to: Vector2) -> bool:
	if layers & Mover.STREETS != 0 or not _cut_cells.has(tile):
		return true
	var solid: PackedVector2Array = _cut_cells[tile]
	if Geometry2D.is_point_in_polygon(from, solid) or Geometry2D.is_point_in_polygon(to, solid):
		return true
	for i in solid.size():
		if Geometry2D.segment_intersects_segment(from, to, solid[i],
				solid[(i + 1) % solid.size()]) != null:
			return true
	return false

func _open(x: int, y: int) -> bool:
	return is_walkable(Vector2i(x, y))

func walk_tiles() -> PackedByteArray:
	return _grid

func walkable_lut() -> PackedByteArray:
	return PackedByteArray([0, 1])

## No carriageway indoors.
func is_carriageway(_tile: Vector2i) -> bool:
	return false

## **The building's alleys are its passages one tile wide**: the run of such cells `tile` lies in,
## walled on both sides across it, or an empty rect where the floor is wider. What an alley is
## asked for is the same here — the short way across is across her path, and a spread laid in one
## closes it — so the basement's mouse darts across the passage it stands in, wall to wall, as an
## alley's mouse darts across its alley (`EventInstance._alley_crossing_path()`).
func alley_at(tile: Vector2i) -> Rect2i:
	if not is_walkable(tile):
		return Rect2i()
	for across: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
		if not _one_wide(tile, across):
			continue
		var along := Vector2i(across.y, across.x)
		var first := tile
		while _one_wide(first - along, across):
			first -= along
		var last := tile
		while _one_wide(last + along, across):
			last += along
		return Rect2i(first, last - first + Vector2i.ONE)
	return Rect2i()

## Whether `tile` is floor with closed ground on both sides of it along `across`.
func _one_wide(tile: Vector2i, across: Vector2i) -> bool:
	return is_walkable(tile) and not is_walkable(tile + across) and not is_walkable(tile - across)

## `+1`/`-1` if `world_position`'s tile is a diagonal flight tile, `0` otherwise — the one question
## `Stroller._physics_process()` asks every frame to redirect a sideways press along a flight's own
## slope (`InteriorTile.flight_direction()`). Off a flight, a landing tile included, she walks the
## way she presses (inbox #782 in minty-lemur).
func slope_dir_at(world_position: Vector2) -> int:
	return InteriorTile.flight_direction(tiles.get(world_to_tile(world_position),
			InteriorTile.Kind.NONE))

# ------------------------------------------------------------------ the footprint ---

## The bounding box of every painted cell in the whole building — every part and every gap between
## them, since the collision pass and the camera limits both cover the gaps too (she must not walk,
## or be framed, off the building's own combined edge).
func footprint() -> Rect2i:
	var min_t := Vector2i(999999, 999999)
	var max_t := Vector2i(-999999, -999999)
	for tile: Vector2i in tiles:
		min_t = min_t.min(tile)
		max_t = max_t.max(tile)
	return Rect2i(min_t, max_t - min_t + Vector2i.ONE)

# ------------------------------------------------------------------- the flights ---

## **A flight's two edges are straight lines along its slope, not the stair sides' square corners.**
## A flight's walkable `t/m` band is two cells wide on every row, but the solid cells either side of
## it meet it at convex corners that lie on two lines only 22.6px apart across the slope, and her
## body is 28px across (`Tuning.PLAYER_BODY_RADIUS`, 14px): with full-cell blockers she can only
## pass each pair of corners moving nearly flat or nearly straight down, and a held sideways press
## walks a zigzag of flat steps and steep drops however the press is steered (inbox #783 in
## minty-lemur). So each solid cell beside a flight has the part of it inside the flight's band cut
## off, and the band's two edges are straight, `FLIGHT_HALF_WIDTH` either side of the flight's centre
## line (the line half-way between the centres of its `t` and its `m` cells).
##
## **1.125, so a landing's line is inside the band.** The landing tile level with a flight's first
## or last tread has its centre half a unit off the flight's centre line, and her centre stays
## `FLIGHT_HALF_WIDTH` less her radius (0.62 units) from it at most: at 1.125 a press from that
## tile's centre walks onto the flight and down the whole of it at 45 degrees without touching an
## edge, where at 1.0 she would touch the lower edge on the first tread and slide flat for a
## moment. Her centre has 11.5px of play either side of the centre line, so one that arrives off
## the line, from the landing's next row down, is slid onto it by the cut faces, and her centre is
## always over the drawn treads. Along a row, the lower edge lies 4px beyond the drawn side face
## (the hypotenuse of the `c`/`C` triangle) and the upper one 12px beyond the treads' tips.
##
## **Only solid cells are cut; the walkable flight cells keep no blocker of their own.** The corners
## of a `t` or `m` cell outside the band are pockets too small to hold her (the circle they hold
## is under 4px in radius), and a blocker in them would face the landing beside the flight's first
## and last row with a wall she could not step past.
##
## In tile units, measured along `(slope, -1)`: a descending-east flight's `t` cells are at one
## value of `x - y` and its `m` cells one lower, so the centre line is half-way between; a
## descending-west flight is the mirror, `-x - y`. One unit is 22.6px across the slope.
const FLIGHT_HALF_WIDTH := 1.125

## Every flight in the building as `{normal, centre, cells}`: `normal` is `(slope, -1)`, `centre`
## the mean of `normal · cell centre` over the flight's cells, and `cells` the solid cells beside it
## (its eight-neighbours that are not walkable), which are the ones `blocker_outline()` cuts. A
## flight is one eight-connected run of flight cells of one slope.
func flight_bands() -> Array[Dictionary]:
	var bands: Array[Dictionary] = []
	var seen := {}
	for start: Vector2i in tiles:
		var slope := InteriorTile.flight_direction(tiles[start])
		if slope == 0 or seen.has(start):
			continue
		var normal := Vector2(slope, -1)
		var total := 0.0
		var count := 0
		var beside := {}
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			total += normal.dot(Vector2(cell) + Vector2(0.5, 0.5))
			count += 1
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var next := cell + Vector2i(dx, dy)
					if next == cell:
						continue
					if InteriorTile.flight_direction(tiles.get(next, InteriorTile.Kind.NONE)) == slope:
						if not seen.has(next):
							seen[next] = true
							queue.append(next)
					elif not is_walkable(next):
						beside[next] = true
		bands.append({"normal": normal, "centre": total / count, "cells": beside})
	return bands

## The blocker for a solid `tile` as a convex outline in pixels about the tile's centre, or empty
## for the plain full cell. Each flight it stands beside cuts away the part of it inside that
## flight's band, keeping the side of the band its own centre is on.
func blocker_outline(tile: Vector2i, bands: Array[Dictionary]) -> PackedVector2Array:
	var corners := PackedVector2Array([Vector2(tile), Vector2(tile) + Vector2(1, 0),
			Vector2(tile) + Vector2(1, 1), Vector2(tile) + Vector2(0, 1)])
	var outline := corners
	var cut := false
	for band: Dictionary in bands:
		if not (band["cells"] as Dictionary).has(tile):
			continue
		var normal: Vector2 = band["normal"]
		var centre: float = band["centre"]
		var side := signf(normal.dot(Vector2(tile) + Vector2(0.5, 0.5)) - centre)
		# Kept: `side * (normal · p) >= side * centre + FLIGHT_HALF_WIDTH`.
		outline = clip_to_half_plane(outline, normal * side, side * centre + FLIGHT_HALF_WIDTH)
		cut = true
	if not cut or outline == corners:
		return PackedVector2Array()
	var local := PackedVector2Array()
	for point in outline:
		local.append((point - Vector2(tile) - Vector2(0.5, 0.5)) * Tuning.TILE_SIZE)
	return local

## The part of convex `polygon` where `normal · p >= limit` (Sutherland–Hodgman against one line).
static func clip_to_half_plane(polygon: PackedVector2Array, normal: Vector2, limit: float
		) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var da := normal.dot(a) - limit
		var db := normal.dot(b) - limit
		if da >= 0.0:
			kept.append(a)
		if (da >= 0.0) != (db >= 0.0):
			kept.append(a.lerp(b, da / (da - db)))
	return kept

# ------------------------------------------------------------ places and walks ---

## What `waypoint()` answers for a name the plan does not have. Off every part's own footprint by
## several map widths, so a caller that forgets to check it puts something nowhere at all rather
## than on the ground beside her.
const NOWHERE := Vector2i(-999999, -999999)

## A waypoint by name — a stairwell's landing, a hallway's midpoint, the lobby floor — or
## `NOWHERE`. The escape's events are sited against these rather than against tile arithmetic of
## their own, so a change to the building's layout moves them with it.
func waypoint(id: String) -> Vector2i:
	return waypoints.get(id, NOWHERE)

## Where a fresh run starts — the third floor's own door, mid-hallway on its south edge.
func start_world_position() -> Vector2:
	return tile_to_world(start_tile)

## `InteriorMap.PARTS`' own waypoint, in world space — what `--start-escape <part>` teleports to.
## Her own start for a name this does not recognise, the same "unknown means the default" shape
## `DevFlags.start_escape_at()` already leaves to its caller.
func part_world_position(part: String) -> Vector2:
	if waypoints.has(part):
		return tile_to_world(waypoints[part])
	return start_world_position()

## The inner cell of each intermediate floor's level approach, in one shaft — the second of the two
## level `F` cells below a `D`, two tiles from the door. Named for what it is: **the grammar has no
## half-landing between floors and no cell of kind `LANDING` in a shaft at all**, so anything
## sited here is on a floor's own approach, one cell further in than the door.
##
## Which is exactly what the fire wants: two tiles from the door, its body closes the flight the
## approach leads onto without covering the corridor transition itself, so the way past it is
## through that floor's door rather than back up the stairs. The top and lobby approaches are
## excluded, since neither has a flight above it to close.
func inner_floor_approaches(part_id: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for landing_id in ["landing_second", "landing_first"]:
		var first: Vector2i = waypoint("%s:%s" % [part_id, landing_id])
		if first == NOWHERE:
			continue
		var inner := first + Vector2i.DOWN
		if is_walkable(inner):
			found.append(inner)
	return found

## Every painted cell inside one grammar rectangle, including the non-walkable stair-side roles.
## The events' placement and focused tests use the same bounds rather than inferring a shaft from
## the changing positions of its alternating doors.
func stairwell_tiles(part_id: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var top: Vector2i = waypoint(part_id)
	if top == NOWHERE:
		return found
	var origin := top - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var bounds := Rect2i(origin, InteriorMap.STAIRWELL_SIZE)
	for tile: Vector2i in tiles:
		if bounds.has_point(tile):
			found.append(tile)
	return found

## One shaft's own walk, its lobby landing to its top landing, tile by tile. A shaft is a corridor
## with no branches too — the level `F` columns and the `t/m` and `T/M` diagonals are the only
## ground in the grammar — so its shortest walk *is* the staircase, and anything that has to travel
## the shaft travels it over cells she could stand on rather than across the solid `c`/`C`/`b`
## sides and the background between the flights.
##
## The doors are dead ends off it: each `D` cell's only walkable neighbours are the level approach
## below it, so a shortest walk never stands on one.
func stairwell_walk(part_id: String) -> Array[Vector2i]:
	var bottom := waypoint("%s:landing_lobby" % part_id)
	var top := waypoint(part_id)
	if bottom == NOWHERE or top == NOWHERE:
		return []
	return shortest_walk(bottom, top)

## Where the basement corridor is one tile wide on the way out, in the order she meets them —
## `corridor_narrows`, what the layout laid rather than whatever the geometry happens to offer.
func basement_narrows() -> Array[Vector2i]:
	return corridor_narrows

## **Where the basement's vents stand**: each of the corridor's one-tile-wide cells
## (`basement_narrows()`), at its centre, in the order she meets them. A vent closes the corridor
## because of where it stands, not because of how wide it is (`EventCatalogue.STEAM_VENT_BODY`): the
## one place a 32px cloud is the whole width is a passage one tile across, where her centre has 16px
## of play either side of the middle and a blow holds it 30px out (2026-09-19: "they should go in the
## narrow hallways"). The cells are the layout's, so the gates are in the same places every attempt
## — *"multiple fixed locations"* — and each is checked against the corridor's own walk, because a
## gate she can go round is not a gate and nothing else would notice the layout and the walk
## disagreeing. Empty, with the error said, where one is not on the walk.
func vent_sites() -> Array[Vector2]:
	var found: Array[Vector2] = []
	var on_the_walk := {}
	for tile in basement_walk():
		on_the_walk[tile] = true
	for tile in basement_narrows():
		if not on_the_walk.has(tile):
			push_error("the steam vent at %s is not on the basement's own walk" % tile)
			return []
		found.append(tile_to_world(tile))
	return found

## The basement's corridor, entry to exit, tile by tile. The corridor has no branches, so its
## shortest walk *is* the corridor, and anything sited a fraction of the way along it stands
## somewhere she has to pass rather than somewhere she might.
func basement_walk() -> Array[Vector2i]:
	var entry := door("basement:entry")
	if not entry or exit_tile.x < 0:
		return []
	return shortest_walk(entry.tile, exit_tile)

## Breadth-first over walkable tiles, unwound into the path itself — `from` first, `to` last, or
## empty when there is no walk between them.
##
## **Eight-connected, not four.** A shaft's flights are runs of diagonal steps — the reviewed
## `t/m` and `T/M` roles drop one tile height over one tile width — so a four-connected walk finds
## no way down a staircase at all. She walks those corners, so a walk that could not is not the
## walk she takes.
func shortest_walk(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var previous := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if tile == to:
			break
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := tile + Vector2i(dx, dy)
				if previous.has(next) or not is_walkable(next):
					continue
				previous[next] = tile
				queue.append(next)
	if not previous.has(to):
		return []
	var path: Array[Vector2i] = []
	var at := to
	while at != from:
		path.append(at)
		at = previous[at]
	path.append(from)
	path.reverse()
	return path

## Whether `tile` is a transition trigger, and what it leads to: `{"kind": "door", "door": Door}`,
## `{"kind": "exit"}`, or empty. The exact question the scene asks every frame she walks
## (`InteriorScene.process_player()`), answerable without waiting on the fade it owns.
func transition_at(tile: Vector2i) -> Dictionary:
	for id: String in doors:
		var found: Door = doors[id]
		if found.tile == tile:
			return {"kind": "door", "door": found}
	if exit_tile.x >= 0 and tile == exit_tile:
		return {"kind": "exit"}
	return {}
