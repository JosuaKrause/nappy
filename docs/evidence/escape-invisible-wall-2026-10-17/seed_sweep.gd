extends RefCounted
## Inbox #777, how often: on each seed, whether each of the escape's two exits can still be reached
## from the service exit once the escape building's collision cells stand in the city. Prints counts
## rather than asserting them (`EIW_SWEEP` lines).
##
## **Kept here as text** (`docs/` has a `.gdignore`, so Godot never loads it from this folder). To
## run it, copy it to `tests/probes/eiw_sweep.gd` in a checkout and name it:
##
##     EIW_PICTURE=/tmp/players-city.png tools/test.sh probes/eiw_sweep.gd
##
## `EIW_PICTURE` is optional; without it no picture is drawn.
##
## **The model.** The building's blockers are seed-independent (`InteriorScene.build()` takes no
## seed), so they are built once and read as a set of city tiles. Per seed, a real city and a real
## escape plan for day 14, the day a run hands over on (`FinalePlanner.plan()` with
## `GameState.day_rng(14, "finale")`, the same stream `main._plan_the_finale_city()` reads), and a
## breadth-first walk over the walkable tiles of the plan's open cells — everything off them is
## sealed by `SealPlanner.plan_finale()` — from the service exit to each exit tile, once as the plan
## is and once with the building's tiles removed. Tile-level, so it ignores the escape's own event
## bodies on both passes alike: the question is what the building's cells alone take away.

const SEEDS := 100
const DAY := 14

func run(t) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var walls := {}
	for body in scene._collision.get_children():
		walls[scene.world_to_tile((body as Node2D).position)] = true
	var lowest := -1000
	for tile: Vector2i in walls:
		lowest = maxi(lowest, tile.y)
	print("EIW_SWEEP the building's blockers: %d cells, footprint %s, the lowest row %d"
			% [walls.size(), scene._footprint(), lowest])
	scene.free()
	var saved_seed := GameState.run_seed
	_draw_the_players_city(walls)
	var both_before := 0
	var tunnel_cut := 0
	var bridge_cut := 0
	var both_cut := 0
	var start_inside := 0
	var counted := 0
	for i in SEEDS:
		var seed_value := 1000 + i * 7919
		GameState.run_seed = seed_value
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.block_plans, DAY)
		map.repaint(state)
		var plan := FinalePlanner.plan(map, GameState.day_rng(DAY, "finale"), false)
		var start := FinalePlanner.service_exit_tile(map)
		var tunnel := FinalePlanner.exit_tile(map, CityEdge.Kind.TUNNEL)
		var bridge := FinalePlanner.exit_tile(map, CityEdge.Kind.BRIDGE)
		var open := _open_tiles(map, plan)
		var t0 := _reaches(open, {}, start, tunnel)
		var b0 := _reaches(open, {}, start, bridge)
		var t1 := _reaches(open, walls, start, tunnel)
		var b1 := _reaches(open, walls, start, bridge)
		counted += 1
		if t0 and b0:
			both_before += 1
		if t0 and not t1:
			tunnel_cut += 1
		if b0 and not b1:
			bridge_cut += 1
		if (t0 and not t1) and (b0 and not b1):
			both_cut += 1
		if walls.has(start):
			start_inside += 1
		print("EIW_SWEEP seed %d: map %s, service exit %s, tunnel %s %s -> %s, bridge %s %s -> %s"
				% [seed_value, map.size, start, tunnel, t0, t1, bridge, b0, b1])
	GameState.run_seed = saved_seed
	print("EIW_SWEEP %d seeds: both exits reachable on the plan alone %d; with the building's cells, tunnel cut off %d, bridge cut off %d, both %d; service exit on a building cell %d"
			% [counted, both_before, tunnel_cut, bridge_cut, both_cut, start_inside])

## Every walkable tile of the plan's open cells.
static func _open_tiles(map: CityMap, plan: FinalePlanner.Plan) -> Dictionary:
	var open := {}
	for cell: Vector2i in plan.open_cells:
		for dy in ReachabilityGrid.CELL:
			for dx in ReachabilityGrid.CELL:
				var tile := cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
				if map.is_walkable(tile):
					open[tile] = true
	return open

## Whether `to` is reached from `from` over `open` less `walls`, four-connected.
static func _reaches(open: Dictionary, walls: Dictionary, from: Vector2i, to: Vector2i) -> bool:
	if walls.has(from) or walls.has(to):
		return false
	var seen := {from: true}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var here: Vector2i = frontier.pop_back()
		if here == to:
			return true
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := here + step
			if seen.has(next) or walls.has(next) or not (open.has(next) or next == to):
				continue
			seen[next] = true
			frontier.append(next)
	return false

## Where the picture goes: `EIW_PICTURE=<path>` in the environment, or nothing is drawn.
const PICTURE_ENV := "EIW_PICTURE"
const PLAYERS_SEED := 4216201080
const PLAYERS_DAY := 1
const WHERE_SHE_STOOD := Vector2i(74, 27)
const SCALE := 4

## The player's city (seed 4216201080, day 1, her `--start-escape` boot), one tile to a 4px square:
## buildings and other ground she cannot stand on dark, open ground grey, the tunnel chain's open
## tiles amber and the bridge chain's blue, the building's collision cells red over whatever they
## cover, the service exit green, the two exits white and the tile she stood on magenta.
func _draw_the_players_city(walls: Dictionary) -> void:
	var path := OS.get_environment(PICTURE_ENV)
	if path == "":
		return
	GameState.run_seed = PLAYERS_SEED
	var map := CityGenerator.generate(PLAYERS_SEED)
	var state := CityState.new()
	state.begin_day(map.block_plans, PLAYERS_DAY)
	map.repaint(state)
	var plan := FinalePlanner.plan(map, GameState.day_rng(PLAYERS_DAY, "finale"), false)
	print("EIW_SWEEP the player's plan: %s" % plan.summary())
	var image := Image.create(map.size.x * SCALE, map.size.y * SCALE, false, Image.FORMAT_RGB8)
	var chain_of := {}
	for chain in plan.chains:
		for cell: Vector2i in chain.cells:
			chain_of[cell] = chain.exit_kind
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			var colour := Color(0.16, 0.16, 0.2)
			if map.is_walkable(tile):
				colour = Color(0.55, 0.55, 0.58)
				var cell := tile / ReachabilityGrid.CELL
				if chain_of.has(cell):
					colour = Color(0.95, 0.7, 0.15) if chain_of[cell] == CityEdge.Kind.TUNNEL \
							else Color(0.3, 0.55, 0.95)
			if walls.has(tile):
				colour = colour.lerp(Color(0.9, 0.1, 0.1), 0.75)
			_square(image, tile, colour)
	_square(image, FinalePlanner.service_exit_tile(map), Color(0.1, 0.9, 0.2), 2)
	_square(image, FinalePlanner.exit_tile(map, CityEdge.Kind.TUNNEL), Color.WHITE, 2)
	_square(image, FinalePlanner.exit_tile(map, CityEdge.Kind.BRIDGE), Color.WHITE, 2)
	_square(image, WHERE_SHE_STOOD, Color(1.0, 0.2, 1.0), 2)
	image.save_png(path)
	print("EIW_SWEEP wrote %s" % path)

static func _square(image: Image, tile: Vector2i, colour: Color, grow := 0) -> void:
	for dy in range(-grow, SCALE + grow):
		for dx in range(-grow, SCALE + grow):
			var px := tile.x * SCALE + dx
			var py := tile.y * SCALE + dy
			if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
				image.set_pixel(px, py, colour)
