class_name RouteLines
extends Node2D
## The day's planned routes, drawn as one purple polyline per route from the doorstep to its calm
## area — the fifth debug layer, key `5` and `--layers 5`/`?layers=5`. See docs/TELEMETRY.md, "The
## debug view", and `RouteTree`'s own class doc for what a route is.
##
## **A sibling of `DebugLayers`, not a fourth case inside it.** `main._add_debug_layers()` gates
## that class on `_debug` and this one is gated the same way by its own `main._add_route_lines()` —
## the two answer independent questions (the live geometry state a frame is actually drawing, in
## `DebugLayers`' case, against the day's own fixed plan here), so nothing beyond the on/off
## pattern is shared.
##
## **Takes a `CityMap` and a `RouteTree` rather than a whole `City`.** `DebugLayers` needs the
## live `City` because it queries entities that move every frame; this class only ever needs the
## two things `Corridor` and `TelemetryMap` already ask for, so it depends on those and nothing
## else — which is also what lets a test build one without a running city's worth of nodes.
##
## **Redrawn only when the day's tree changes, never every frame.** There is no `_process()` here:
## `main._start_day()` calls `refresh(_city.route_tree())` once `City.start_day()` has grown
## today's tree, and that is the only time the picture can have changed — a route tree is fixed
## for the whole day and nothing about it depends on where she is standing or what the crowd is
## doing.
##
## **What "the centre of a route's tile" means against a tree grown on two-tile cells.**
## `RouteTree.Branch.routes` is `Array[Array]` of `Vector2i` **cell** coordinates, not tile
## coordinates — see docs/DECISIONS.md, M69: a step on the tree is a `ReachabilityGrid` node, one
## per 4-connected component of a two-tile cell, and the grid keeps no public record of which
## specific tile of a multi-tile cell a route actually crossed (only `any_tile_of()`, one
## representative tile per node, kept for street lookups that do not care which tile answers).
## So every interior point of a drawn route here is a **cell** centre
## (`ReachabilityGrid.CELL` = 2 tiles), honouring the day's plan at the grain it is actually stored
## in rather than inventing a tile-level path the tree never committed to.
##
## **The two ends are real tiles, because each is a single, unambiguous one.** The first point is
## the doorstep tile every day actually starts and ends on (`CityMap.doorstep_world_position()`).
## The last is a calm tile immediately across the border from the route's own last cell:
## `RouteTree` stores a route only as far as the *access* cell just outside the calm area — "a
## door is not a route" holds at both ends, see `RouteTree`'s own class doc on the home side, and
## `RouteTree._access_nodes()` builds the calm side the same way — so the one calm tile actually
## inside the area is found here rather than read out of the tree.
##
## **The doorstep connector is not one step, and nothing here pretends it is.** `RouteTree`'s own
## "the trunk" doc: a branch's probe reaches *some* node bordering the home street, "whichever the
## random walk happened to find first" — a route can rejoin the home frontage anywhere along it,
## not necessarily beside the one tile the day actually starts on. Measured over 6 seeds x 4 days
## (301 routes), the cell a route actually meets home at is never closer than 2 reachability cells
## from the doorstep's own cell. Drawing from the fixed doorstep tile regardless is what matches
## what the player actually sees repeated every day — one fixed point every route fans out from —
## rather than a different point on the kerb for every route. **The connector is drawn as two
## axis-aligned legs, never one straight hop**: a straight line from the doorstep to a join cell
## further along the frontage cut diagonally across the carriageway, and read as a route crossing
## mid-block where no route cell was — *(2026-09-14, the player, of exactly that picture: "how is
## this path possible? the rule is to only allow crossing at crossings never across the street")*.
## The corner is whichever of the two axis-aligned candidates lies nearer the doorstep, which is the
## point on the frontage in front of the door; from there the second leg runs along the street to
## the join. The calm-side connector has no such gap: it is always the route's own last cell's
## direct neighbour, because it is built from that cell rather than from a second fixed point.

## The same purple `TelemetryMap` already draws the day's corridor in on the dusk map, so the live
## overlay and the dusk picture agree on what "the corridor" looks like rather than inventing a
## second colour for the same fact.
const ROUTE_COLOUR := TelemetryMap.CORRIDOR_MARK
## `DebugLayers.LINE_WIDTH`'s own weight, so a purple route line reads at the same weight as the
## other four geometry layers when several are on together.
const LINE_WIDTH := 1.5

var _map: CityMap
var _routes: Array[PackedVector2Array] = []

func setup(map: CityMap) -> void:
	_map = map

## Sets whether the layer starts on — `5 in indices`, from `DevFlags.layers_override()`. See
## `DebugLayers.apply_initial_state()` for the same split against `1`-`3`.
func apply_initial_state(indices: Array[int]) -> void:
	visible = 5 in indices

## Rebuilds every route's own polyline from `tree` and redraws. `tree` is `null` for the whole
## escape sequence — `City.route_tree()`'s own contract, since the finale plants no tree at all —
## which this answers with an empty picture rather than an error.
func refresh(tree: RouteTree) -> void:
	_routes = _build_routes(tree)
	queue_redraw()

## Every route built by the last `refresh()`, for a test to inspect directly rather than
## re-deriving the same picture a second way.
func routes() -> Array[PackedVector2Array]:
	return _routes

func _draw() -> void:
	for route in _routes:
		if route.size() >= 2:
			draw_polyline(route, ROUTE_COLOUR, LINE_WIDTH, true)

## One polyline per route, doorstep first. `RouteTree.Branch.routes` runs calm-to-doorstep (see its
## own class doc), so each is reversed before the doorstep tile is prepended and the calm tile
## appended — see the class doc above for what each of those two extra points is and why neither
## comes from the tree itself.
func _build_routes(tree: RouteTree) -> Array[PackedVector2Array]:
	var found: Array[PackedVector2Array] = []
	if not tree or not _map:
		return found
	var doorstep := _map.tile_to_world(_map.world_to_tile(_map.doorstep_world_position()))
	var areas := ClosurePlanner.calm_areas(_map)
	var area_by_block := {}
	for area in areas:
		area_by_block[area.block] = area
	for branch in tree.branches:
		var area: ClosurePlanner.CalmArea = area_by_block.get(branch.area)
		for route: Array in branch.routes:
			if route.is_empty():
				continue
			var points := PackedVector2Array()
			points.append(doorstep)
			var ordered := route.duplicate()
			ordered.reverse()
			points.append(_doorstep_corner(doorstep, _cell_centre_world(ordered[0])))
			for cell: Vector2i in ordered:
				points.append(_cell_centre_world(cell))
			if area:
				points.append(_map.tile_to_world(
						_calm_endpoint_tile(ordered[ordered.size() - 1], area)))
			found.append(points)
	return found

## The corner of the doorstep connector's two legs — see the class doc. Of the two axis-aligned
## candidates between `doorstep` and `join`, the one nearer the doorstep; when the join is already
## in line with the door the corner coincides with one end and the second leg has no length, which
## draws nothing and keeps the polyline's shape fixed (doorstep, corner, cells, calm) for the test.
func _doorstep_corner(doorstep: Vector2, join: Vector2) -> Vector2:
	var a := Vector2(doorstep.x, join.y)
	var b := Vector2(join.x, doorstep.y)
	return a if doorstep.distance_to(a) <= doorstep.distance_to(b) else b

## The world position of a two-tile reachability cell's own centre — the point equidistant from
## all four of its tiles' centres, at `(cell * CELL + (1, 1)) * TILE_SIZE` rather than any one
## tile's own `(0.5, 0.5)` offset. See the class doc for why the interior of a route is drawn at
## this grain instead of a tile's.
func _cell_centre_world(cell: Vector2i) -> Vector2:
	var half := float(ReachabilityGrid.CELL) * 0.5
	return (Vector2(cell * ReachabilityGrid.CELL) + Vector2(half, half)) * Tuning.TILE_SIZE

## A calm tile actually inside `area`'s own rect, immediately across the border from
## `access_cell` — the route's own last cell, which `RouteTree._access_nodes()` guarantees was
## found by walking outward from a calm tile of this same area. This mirrors that method exactly,
## the other way round: every tile of `access_cell`, every one of *its* four neighbours, first
## neighbour in a **different** cell that is both inside the rect and calm ground.
##
## **The neighbour must leave the cell, and checking that is not optional.** `area.rect` is the
## calm area's own *open* rect (`ClosurePlanner.calm_area_rect()`), which answers a design question
## about which ground is calm and is never adjusted to land on a `ReachabilityGrid` cell boundary —
## only a whole *block* is guaranteed cell-aligned (docs/DECISIONS.md, M69). So a corner tile of
## `access_cell` itself can sit inside `area.rect` and read as calm ground while a sibling corner of
## the very same cell is the real access tile outside it; without the cross-cell check this method
## found that corner and answered a point 0.71 tiles from the cell's own centre — still on
## `access_cell`, not across the border it was supposed to cross.
##
## Measured over 6 seeds x 4 days (301 routes), this always finds one on the first neighbour cell
## it tries; the rect-clamp below is an unreached fallback kept rather than trusted, the same
## reasoning `RouteTree._adopt()`'s own bounded walk gives for a case its author also expects never
## to fire.
func _calm_endpoint_tile(access_cell: Vector2i, area: ClosurePlanner.CalmArea) -> Vector2i:
	var offsets: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var origin := access_cell * ReachabilityGrid.CELL
	var cell_tiles: Array[Vector2i] = [
		origin, origin + Vector2i(1, 0), origin + Vector2i(0, 1), origin + Vector2i(1, 1),
	]
	for tile in cell_tiles:
		for offset in offsets:
			var neighbour := tile + offset
			if _cell_of(neighbour) == access_cell:
				continue
			if area.rect.has_point(neighbour) and Tile.is_calm(_map.tile_at(neighbour)):
				return neighbour
	var centre := origin + Vector2i(1, 1)
	return area.rect.position + Vector2i(
			clampi(centre.x - area.rect.position.x, 0, maxi(area.rect.size.x - 1, 0)),
			clampi(centre.y - area.rect.position.y, 0, maxi(area.rect.size.y - 1, 0)))

## The reachability cell a tile belongs to — the same floor division `ReachabilityGrid` itself
## builds cells from, restated here rather than exposed from it, since nothing else in this class
## needs a grid instance at all.
func _cell_of(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / ReachabilityGrid.CELL),
			floori(float(tile.y) / ReachabilityGrid.CELL))
