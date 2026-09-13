class_name FinalePlanner
extends RefCounted
## The escape's route through the city: **two ordered chains, not a tree.**
##
## *(The player, on the finale's shape: "the finale route is *not* a tree any more. it's a single
## path going to the first park, then the second, then the third, then the exit. no overlapping
## routes"; and, on how many: "two paths it is.")*
##
## A day grows several strands to several calm areas and counts two distinct routes to each as a
## max flow, because a day has to stay winnable whichever way she goes. The escape has one way out
## and asks the opposite question: **which single walk does she take, and what does it cost.** So
## `RouteTree.for_day` and its redundancy guarantee are exactly what this must not run — and the
## rule they both keep still holds, because it is the rule that made two chains possible at all:
## **a route out of the city is never a route to a calm area**, which is what `CityEdge` and
## `tests/test_blocks.gd` already say about the tunnel and the bridge.
##
## **Each chain is service exit → calm → calm → calm → edge.** One street-walk between consecutive
## stops and nothing else open: the legs are shortest paths on the `ReachabilityGrid`, the same
## two-tile cells a day's routes are grown on, so every geometric fact about a park's frontage, an
## alley's width or a courtyard's one archway falls out of the tiles the way it does everywhere
## else. The tunnel chain goes north, the bridge chain goes south, and the second is grown with
## every cell of the first forbidden — so they part at the exit, or as near it as the lattice
## allows, and share no cell afterwards.
##
## **The calm on the way is what the parks are for**, in the brief's own words — *"the player can
## use them to calm down or get the baby back to sleep if it wakes up"* — so a stop is any
## connected component of `Tile.is_calm` ground, which is a park lot, a four-block zone, a forest,
## a quiet square or a courtyard without this file having to know which. Distinctness is then
## automatic: two stops are different components or they are the same stop.
##
## What this hands back is a `Plan`: the two chains, the union of their cells, and every
## `EventScheduler.Planned` the escape puts in the city — `SealPlanner.plan_finale()`'s walls off
## the chains and `EventScheduler.build_finale()`'s trucks, vans, masked men and bursts on them.

## One calm area on the way: a connected component of calm ground, its tiles and the grid nodes
## that cover them.
class CalmArea extends RefCounted:
	var centre := Vector2i.ZERO
	var tiles: Array[Vector2i] = []
	var nodes: Array[int] = []

## One way out, from the door to an edge.
class Chain extends RefCounted:
	## `CityEdge.Kind.TUNNEL` or `CityEdge.Kind.BRIDGE`.
	var exit_kind := CityEdge.Kind.TUNNEL
	## The three calm areas it runs through, in the order it meets them.
	var stops: Array[CalmArea] = []
	## Every `ReachabilityGrid` node the walk covers, in order, and the cells they sit in.
	var nodes: Array[int] = []
	var cells: Dictionary = {}
	## False when a leg could not be walked at all — a city whose lattice leaves a stop or an edge
	## unreachable from the door. Never seen on a generated city; the flag exists so the caller
	## gets a plan rather than a crash if one ever is.
	var complete := true

class Plan extends RefCounted:
	var chains: Array[Chain] = []
	## The union of both chains' cells: what stays open, and what `SealPlanner.plan_finale()` is
	## asked to spare.
	var open_cells: Dictionary = {}
	## Every street either chain runs through — where the finale's own events stand.
	var open_streets: Array[StreetNetwork.Segment] = []
	var placements: Array[EventScheduler.Planned] = []

	## One line for the run log: which way each chain goes and how much of the city is left open.
	func summary() -> String:
		var parts: Array[String] = []
		for chain in chains:
			parts.append("%s via %d calm, %d cells%s" % [
				"tunnel" if chain.exit_kind == CityEdge.Kind.TUNNEL else "bridge",
				chain.stops.size(), chain.cells.size(), "" if chain.complete else " (incomplete)"])
		parts.append("%d open streets, %d placements" % [open_streets.size(), placements.size()])
		return " | ".join(parts)

# ------------------------------------------------------------------ the plan ---

static func plan(map: CityMap, rng: RandomNumberGenerator) -> Plan:
	var grid := ReachabilityGrid.build(map)
	var start := service_exit_tile(map)
	var areas := calm_areas(map, grid)
	var result := Plan.new()
	# Sorted north to south, so the tunnel chain takes the calm nearest the top of the map and the
	# bridge chain the calm nearest the bottom. The home lot sits between the two ends of the
	# spine, so neither exit is trivially nearer and neither chain is the short one.
	areas.sort_custom(func(a: CalmArea, b: CalmArea) -> bool: return a.centre.y < b.centre.y)
	var per_chain := mini(Tuning.FINALE_PARKS_PER_CHAIN, areas.size() / 2)
	# **Each chain's own stops are ordered so the walk only ever goes one way.** The three northern
	# areas are met southmost first, since she starts between the two exits and the tunnel is at
	# the top; the three southern ones are already in the order she meets them on the way down. A
	# chain ordered the other way would double back past the door between its first and second
	# park, which is a route with no decision in it.
	var northern := areas.slice(0, per_chain)
	northern.reverse()
	var southern := areas.slice(areas.size() - per_chain)

	var tunnel := _grow(grid, start, northern, exit_tile(map, CityEdge.Kind.TUNNEL),
			CityEdge.Kind.TUNNEL, {})
	# The tunnel chain's own cells are forbidden to the bridge chain, except the cell she starts
	# in: *"they part at the service exit, or as near it as the lattice allows"*, and the door
	# itself is one cell that both walks have to leave from.
	var taken := tunnel.cells.duplicate()
	taken.erase(_cell_of(start))
	var bridge := _grow(grid, start, southern, exit_tile(map, CityEdge.Kind.BRIDGE),
			CityEdge.Kind.BRIDGE, taken)

	result.chains = [tunnel, bridge]
	for chain in result.chains:
		for cell: Vector2i in chain.cells:
			result.open_cells[cell] = true
	result.open_streets = _streets_covering(map, result.open_cells)
	result.placements.append_array(SealPlanner.plan_finale(map, result.open_cells, rng))
	result.placements.append_array(EventScheduler.build_finale(map, rng, result.open_streets))
	return result

## One chain: the door, each stop in turn, then the edge. Each leg is a shortest walk on the grid
## with `forbidden` cells treated as wall, and every leg's cells join the chain — so a chain that
## has to double back out of a courtyard carries that ground once.
static func _grow(grid: ReachabilityGrid, start: Vector2i, stops: Array,
		exit: Vector2i, exit_kind: int, forbidden: Dictionary) -> Chain:
	var chain := Chain.new()
	chain.exit_kind = exit_kind
	var here := grid.node_at(start)
	if here < 0:
		chain.complete = false
		return chain
	chain.nodes.append(here)
	chain.cells[grid.cell_of(here)] = true
	for stop: CalmArea in stops:
		chain.stops.append(stop)
		here = _walk(grid, chain, here, stop.nodes, forbidden)
		if here < 0:
			chain.complete = false
			return chain
	var exit_node := grid.node_at(exit)
	if exit_node < 0 or _walk(grid, chain, here, [exit_node], forbidden) < 0:
		chain.complete = false
	return chain

## Walks from `from` to the nearest of `targets`, appending every node on the way to `chain` and
## returning where it ended — or `ReachabilityGrid.NONE` when no walk exists. **A chain's own cells
## stop being forbidden to itself**: `blocked` is the other chain's ground, never this one's, or a
## leg could not leave the stop the previous leg arrived at.
static func _walk(grid: ReachabilityGrid, chain: Chain, from: int, targets: Array,
		blocked: Dictionary) -> int:
	var wanted := {}
	for node: int in targets:
		wanted[node] = true
	if wanted.has(from):
		return from
	var previous := {from: -1}
	var queue: Array[int] = [from]
	var head := 0
	var found := ReachabilityGrid.NONE
	while head < queue.size() and found == ReachabilityGrid.NONE:
		var node: int = queue[head]
		head += 1
		for edge: Array in grid.neighbours(node):
			var next: int = edge[0]
			if previous.has(next) or blocked.has(grid.cell_of(next)):
				continue
			previous[next] = node
			if wanted.has(next):
				found = next
				break
			queue.append(next)
	if found == ReachabilityGrid.NONE:
		return ReachabilityGrid.NONE
	var path: Array[int] = []
	var at := found
	while at != -1:
		path.append(at)
		at = previous[at]
	path.reverse()
	for node in path:
		chain.nodes.append(node)
		chain.cells[grid.cell_of(node)] = true
	return found

static func _cell_of(tile: Vector2i) -> Vector2i:
	return tile / ReachabilityGrid.CELL

# ------------------------------------------------------- where the walk starts and ends ---

## Where she comes out of the building: the pavement beside the home block, on the side away from
## the main road.
##
## **The side is decided rather than rolled**, because the brief says where the door is —
## *"emerging from the service exit on the side of the main building"* — and a service door on the
## arterial frontage is the one side of a building that never has one. The main road runs
## north-south, so "the side" is east or west: the far side from the spine when the spine is one of
## the lot's own two streets, and the west side otherwise, which is arbitrary and stated rather
## than derived. If that tile is not walkable — a lot whose frontage is built over — the nearest
## walkable tile on the block's own perimeter is taken instead, so this always answers with ground
## she can stand on.
static func service_exit_tile(map: CityMap) -> Vector2i:
	var lot := map.lot_blocks(map.home_block)
	var tiles := CityMap.blocks_tile_rect(lot)
	var row := tiles.position.y + tiles.size.y / 2
	var west := Vector2i(tiles.position.x - 1, row)
	var east := Vector2i(tiles.end.x, row)
	var wanted := east if map.main_road == lot.position.x else west
	if map.is_walkable(wanted):
		return wanted
	var fallback := west if wanted == east else east
	if map.is_walkable(fallback):
		return fallback
	for tile in map.perimeter_tiles(map.home_block):
		if map.is_walkable(tile):
			return tile
	return map.world_to_tile(map.doorstep_world_position())

static func service_exit_world_position(map: CityMap) -> Vector2:
	return map.tile_to_world(service_exit_tile(map))

## The last walkable tile of the spine at one end of the map — the carriageway under the tunnel's
## portal, or the one running out onto the bridge deck. `City.tunnel_world_position()` draws the
## picture at the same place; this is the tile the chain has to reach to be standing in it.
static func exit_tile(map: CityMap, exit_kind: int) -> Vector2i:
	var column := map.main_road * CityMap.period() + Tuning.SIDEWALK_WIDTH
	var row := 0 if exit_kind == CityEdge.Kind.TUNNEL else map.size.y - 1
	var step := 1 if exit_kind == CityEdge.Kind.TUNNEL else -1
	# The outermost rows are painted as the border band rather than as city, so the first walkable
	# tile inward is the one the walk can actually end on.
	for i in Tuning.STREET_WIDTH:
		var tile := Vector2i(column, row + i * step)
		if map.is_walkable(tile):
			return tile
	return Vector2i(column, row)

# ----------------------------------------------------------------- the calm ---

## Every connected component of calm ground in the city, as somewhere a chain can stop.
##
## **A component rather than a block**, because what the brief asks for is *"three parks"* and what
## the map holds is calm *ground*: a four-block zone is one place to rest and not four, a courtyard
## cut into a residential block is calm she can settle in like any other, and a playground is part
## of the park around it. Flooding the tiles answers all three at once, and makes "three distinct
## calm areas" a property nothing has to state — two stops are different components or they are the
## same stop.
##
## **Slivers are dropped**, with `_SMALLEST_CALM_AREA` stated against the ground rather than
## against taste: a calm area has to be big enough to have a route through it, because progress
## requires motion and standing still drains sleepiness (`docs/CITY.md`, "multi-block calm zones").
## A courtyard is 16 tiles and is the smallest thing in a generated city that counts; anything
## under that is a corner of one, not a place.
const _SMALLEST_CALM_AREA := 16

static func calm_areas(map: CityMap, grid: ReachabilityGrid) -> Array[CalmArea]:
	var seen := {}
	var found: Array[CalmArea] = []
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if seen.has(tile) or not Tile.is_calm(map.tile_at(tile)):
				continue
			var area := _flood_calm(map, grid, tile, seen)
			if area.tiles.size() >= _SMALLEST_CALM_AREA and not area.nodes.is_empty():
				found.append(area)
	return found

static func _flood_calm(map: CityMap, grid: ReachabilityGrid, from: Vector2i,
		seen: Dictionary) -> CalmArea:
	var area := CalmArea.new()
	var nodes := {}
	var sum := Vector2i.ZERO
	var stack: Array[Vector2i] = [from]
	seen[from] = true
	while not stack.is_empty():
		var tile: Vector2i = stack.pop_back()
		area.tiles.append(tile)
		sum += tile
		var node := grid.node_at(tile)
		if node >= 0:
			nodes[node] = true
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if seen.has(next) or not map.in_bounds(next) or not Tile.is_calm(map.tile_at(next)):
				continue
			seen[next] = true
			stack.append(next)
	area.centre = sum / maxi(1, area.tiles.size())
	for node: int in nodes:
		area.nodes.append(node)
	return area

# -------------------------------------------------------------- the streets ---

## Every street either chain actually walks, which is where the finale's own events stand.
##
## The same question `SealPlanner.plan_finale()` asks about which streets to spare, asked through
## the same function — a street the chain merely turns at is sealed, so putting an army truck on it
## would put one behind a wall.
static func _streets_covering(map: CityMap, open_cells: Dictionary) -> Array[StreetNetwork.Segment]:
	var found: Array[StreetNetwork.Segment] = []
	for segment in StreetNetwork.segments():
		if map.has_street(segment.key()) and SealPlanner.runs_through(segment, open_cells):
			found.append(segment)
	return found
