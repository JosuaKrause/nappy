extends RefCounted
## Measurement probe for downy-otter, "a mark is never placed in an alley she cannot reach"
## (olive-koala, statement 9: *"also a mark should never be placed in an alley that is not reachable
## (ie sealed off)"*; statement 8, the line before it: *"the go through a door task is silly when you
## have to go through a door to even reach the mark."*). Prints numbers, asserts nothing, so it
## lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/downy_otter_sealed_alley.gd
##
## Six cities, days 6 to 13, the real day order. Every dawn mark, and every relocation target from
## her standing on every tenth sidewalk tile, is asked three ways, each flooded from home:
##
## - **the director's own** (`_reachable_from_home()`): the day's closures and every obstructing or
##   lethal plan's disc, region doors open;
## - **doors shut**: the same, with the region doors' own bodies counted as blocks — a mark only
##   reachable through a district door;
## - **by tiles**: a plain walk over walkable ground minus `closed_tiles`, `soft_sealed_tiles` and
##   `obstructed_tiles`, the per-tile record of where a body stands, not the discs.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 2295276695, 314159, 271828, 555555]

func run(t) -> void:
	var saved_steps := GameState.completed_resistance_steps.duplicate()
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	var totals := {"dawn": [0, 0, 0], "moved": [0, 0, 0]}
	for seed_value in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in range(6, 14):
			GameState.completed_resistance_alley_tiles = []
			var done: Array[int] = []
			done.assign(range(1, 2 * (day - 6) + 1))
			GameState.completed_resistance_steps = done
			var state := CityState.new()
			GameState.city_state = state
			state.begin_day(city.map.block_plans, day)
			city.start_day(state, day, _rng(seed_value, day, "closures"))
			city.events.start_day(day, _rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())
			var director := ResistanceDirector.new()
			t.add_child(director)
			director.set_process(false)
			director.setup(city, city.map)
			director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
			var step := director.current_step()
			if step == null or not step.is_pickup:
				director.free()
				continue
			var shut := _doors_shut(city)
			var by_tiles := _by_tiles(city)
			_count(totals["dawn"], city, director, director.contact_position(), shut, by_tiles,
					"seed %d day %d dawn" % [seed_value, day])
			var sidewalks := city.map.tiles_of_type(GameEnums.TileType.SIDEWALK)
			for i in range(0, sidewalks.size(), 10):
				var target := director._nearest_alley_within(city.map.tile_to_world(sidewalks[i]))
				if target == Vector2.INF:
					continue
				_count(totals["moved"], city, director, target, shut, by_tiles, "")
			director.free()
		city.free()
	GameState.completed_resistance_steps = saved_steps
	GameState.completed_resistance_alley_tiles = saved_tiles
	for kind in ["dawn", "moved"]:
		print("[downy] %-5s marks %d: only through a district door %d, unreachable by tiles %d"
				% [kind, totals[kind][0], totals[kind][1], totals[kind][2]])
	t.check(true, "probe ran")

func _count(total: Array, city: City, director: ResistanceDirector, at: Vector2, shut: Array,
		by_tiles: PackedInt32Array, label: String) -> void:
	var tile := city.map.world_to_tile(at)
	total[0] += 1
	var grid: ReachabilityGrid = shut[0]
	if not grid.reaches(tile, shut[1], shut[2]):
		total[1] += 1
		if label != "":
			print("[downy] %s: the mark at %s is reachable only through a district door"
					% [label, tile])
	if city.map.distance_at(by_tiles, tile) < 0:
		total[2] += 1
		if label != "":
			print("[downy] %s: the mark at %s is unreachable by tiles" % [label, tile])
	var _unused := director

func _doors_shut(city: City) -> Array:
	var blockers: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if plan.is_placed() and (plan.def.obstructs_radius > 0.0 or plan.def.hard_fail):
			blockers.append(plan)
	var grid := ReachabilityGrid.build(city.map)
	var blocked := EventScheduler.blocked_by(city.map, blockers)
	return [grid, blocked, grid.flood([city.map.home_rect.position], blocked)]

func _by_tiles(city: City) -> PackedInt32Array:
	var blocked := {}
	for tile in city.map.closed_tiles:
		blocked[tile] = true
	for tile in city.map.soft_sealed_tiles:
		blocked[tile] = true
	for tile in city.map.obstructed_tiles:
		blocked[tile] = true
	return city.map.walk_field(city.map.world_to_tile(city.map.doorstep_world_position()), blocked)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
