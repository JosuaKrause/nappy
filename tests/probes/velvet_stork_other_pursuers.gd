extends RefCounted
## Measurement probe for velvet-stork: whether the pursuers on foot other than day 13's task guard,
## which keep the straight chase (`EventInstance.walkable_step_on()`, straight at her, sliding along
## walls), are stuck behind buildings the way he was. The entry left that a question for the player
## "if a probe shows them stuck the same way". Not a suite: it prints counts rather than asserting
## them, so it lives under `tests/probes/`, and runs only by name:
##
##     tools/test.sh probes/velvet_stork_other_pursuers.gd        (prints VELVET_STORK lines)
##     PROBE_SEEDS=4242,90210 tools/test.sh probes/velvet_stork_other_pursuers.gd
##
## **Clear-line starts.** Per seed, `CLEAR_TRIALS` random starts 360px from her with a clear line
## to her — a pursuer that noticed her, or one sent with a clear run at her — while she walks the
## shortest walk to a tile 15 to 30 tiles away at `Tuning.WALK_SPEED`, then stands. Counts the
## chases at 130px/s that come within the alley robber's stand-off of her within 20s. This measures
## clear-line starts only.
##
## **The sent robber's own starts.** Per seed, on day 13 through the real day order (the
## `tests/test_day13_guard.gd` rig), the director draws where `robber_giving_chase` would start
## (`ResistanceDirector._draw_arrival_position()`) with her standing at `POSITIONS` open tiles spread
## through the city in scan order, and each drawn start is chased from, straight at her standing
## still, for the row's 30s `Tuning.PURSUIT_TIME`. Counted by what the draw found: a clear run at
## her, a walk at her from across the street, or none — `docs/EVENTS.md`'s "where no start has one
## at all, the first legal start stands in and he may never reach her". For a start that never comes
## within his stand-off, whether she can be walked to from it at all (`CityMap.walk_field()`) says
## whether a walk round buildings could reach her.

const SUITE := preload("res://tests/test_day13_guard.gd")
const DEFAULT_SEEDS: Array[int] = [4242, 90210, 555]
const CLEAR_TRIALS := 60
const POSITIONS := 150
const STEP := 0.05

func run(t) -> void:
	var seeds := DEFAULT_SEEDS.duplicate()
	if OS.get_environment("PROBE_SEEDS") != "":
		seeds.clear()
		for part in OS.get_environment("PROBE_SEEDS").split(","):
			seeds.append(int(part))
	for seed_value: int in seeds:
		_clear_line_starts(seed_value)
		_the_sent_robbers_starts(t, seed_value)

func _clear_line_starts(seed_value: int) -> void:
	var map := CityGenerator.generate(seed_value)
	var robbery := EventCatalogue.by_id("alley_robbery")
	var standoff := Tuning.pursuit_standoff(robbery.pursue_speed, robbery.standoff_reach())
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var trials := 0
	var reached := 0
	var tries := 0
	while trials < CLEAR_TRIALS and tries < 5000:
		tries += 1
		var her_tile := Vector2i(rng.randi_range(0, map.size.x - 1),
				rng.randi_range(0, map.size.y - 1))
		if not map.is_walkable(her_tile):
			continue
		var her := map.tile_to_world(her_tile)
		var start := her + Vector2.from_angle(rng.randf() * TAU) * 360.0
		if not map.is_walkable(map.world_to_tile(start)) or not map.clear_line(start, her):
			continue
		var route := _route_from(map, her_tile, rng)
		if route.is_empty():
			continue
		trials += 1
		var him := start
		var at := her
		var next := 0
		var clock := 0.0
		while clock < 20.0:
			clock += STEP
			if next < route.size():
				at = at.move_toward(route[next], Tuning.WALK_SPEED * STEP)
				if at.distance_to(route[next]) < 0.01:
					next += 1
			var toward := at - him
			if toward.length() <= standoff:
				reached += 1
				break
			him += EventInstance.walkable_step_on(map, him,
					toward.normalized() * minf(robbery.pursue_speed * STEP, toward.length()))
	print("VELVET_STORK seed %d clear-line starts 360px off, her walking: %d trials, a straight chase reached her stand-off within 20s in %d"
			% [seed_value, trials, reached])

## The shortest walk from `from` to a tile 15 to 30 tiles away on foot, as tile centres, or empty.
static func _route_from(map: CityMap, from: Vector2i,
		rng: RandomNumberGenerator) -> PackedVector2Array:
	var out := map.walk_field(from)
	var goal := Vector2i(-1, -1)
	for k in 200:
		var tile := from + Vector2i(rng.randi_range(-30, 30), rng.randi_range(-30, 30))
		var d := map.distance_at(out, tile)
		if d >= 15 and d <= 30:
			goal = tile
			break
	var route := PackedVector2Array()
	if goal == Vector2i(-1, -1):
		return route
	var back := map.walk_field(goal)
	var tile := from
	while tile != goal:
		var best := tile
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var d := map.distance_at(back, tile + offset)
			if d >= 0 and d < map.distance_at(back, best):
				best = tile + offset
		if best == tile:
			break
		tile = best
		route.append(map.tile_to_world(tile))
	return route

func _the_sent_robbers_starts(t, seed_value: int) -> void:
	var suite = SUITE.new()
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var saved_alleys := GameState.completed_resistance_alley_tiles.duplicate()
	var city: City = SUITE.CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.scars = []
	var director: ResistanceDirector = suite._start_the_day(t, city, seed_value)
	var player: Stroller = suite._rig_player(t, director.contact_position())
	var map := city.map
	var def := EventCatalogue.by_id("robber_giving_chase")
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
	var open: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.is_walkable(tile) and not map.is_closed(tile) and not map.is_obstructed(tile) \
					and not map.soft_sealed_tiles.has(tile):
				open.append(tile)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# kind -> [drawn, reached, of the rest: she can be walked to from the start]
	var counts := {"a clear run": [0, 0, 0], "across the street": [0, 0, 0], "no clear run": [0, 0, 0]}
	var unsent := 0
	var stride := maxi(1, open.size() / POSITIONS)
	for i in range(0, open.size(), stride):
		var her := map.tile_to_world(open[i])
		player.global_position = her
		var drawn: Array = director._draw_arrival_position(rng, her, def)
		var start: Vector2 = drawn[0]
		if start == Vector2.INF:
			unsent += 1
			continue
		var kind := "across the street" if drawn[3] else ("a clear run" if drawn[1] else "no clear run")
		var row: Array = counts[kind]
		row[0] += 1
		var him := start
		var got := false
		for k in int(Tuning.PURSUIT_TIME / STEP):
			var toward := her - him
			if toward.length() <= standoff:
				got = true
				break
			him += EventInstance.walkable_step_on(map, him,
					toward.normalized() * minf(def.pursue_speed * STEP, toward.length()))
		if got:
			row[1] += 1
		elif map.reaches(map.walk_field(map.world_to_tile(start)), open[i]):
			row[2] += 1
	for kind: String in counts:
		var row: Array = counts[kind]
		print("VELVET_STORK seed %d day 13 sent robber, %s: %d drawn, a straight chase reached her standing within 30s in %d; of the %d that did not, she could be walked to from %d"
				% [seed_value, kind, row[0], row[1], row[0] - row[1], row[2]])
	print("VELVET_STORK seed %d day 13 sent robber: nobody sent from %d positions" % [seed_value, unsent])
	suite._tear_down(player, director, city)
	suite._restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
	GameState.completed_resistance_alley_tiles.assign(saved_alleys)
