extends RefCounted
## THROWAWAY exploration probe for the trailer shot list. Not committed.
## Env: PROBE_SEED, PROBE_DAY, PROBE_R (radius in tiles)

const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	if OS.get_environment("PROBE_SEARCH") != "":
		_search(t)
		return
	var seed_value := int(OS.get_environment("PROBE_SEED"))
	var day := int(OS.get_environment("PROBE_DAY"))
	var r := int(OS.get_environment("PROBE_R")) if OS.get_environment("PROBE_R") != "" else 14
	var center_env := OS.get_environment("PROBE_AT")
	GameState.start_run(seed_value)
	GameState.day = day
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(GameState.run_seed))
	city.events.stream_radius = INF
	GameState.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.city_state, day, GameState.day_rng(day, "closures"))
	var doorstep := city.map.doorstep_world_position()
	city.events.start_day(day, GameState.day_rng(), GameState.consumed_one_shots, doorstep)
	var home := city.map.world_to_tile(doorstep)
	var at := home
	if center_env != "":
		var parts := center_env.split(",")
		at = Vector2i(int(parts[0]), int(parts[1]))
	print("seed %d day %d male %s doorstep tile %s main_road col %d map %s" % [seed_value, day,
			GameState.player_is_male, home, city.map.main_road, city.map.size])
	var marks := {}
	for plan in city.events.plans():
		if not plan.is_placed():
			continue
		var tile := city.map.world_to_tile(plan.position)
		if absi(tile.x - at.x) <= r and absi(tile.y - at.y) <= r:
			marks[tile] = plan.def.id
			print("  event %-18s tile %s kind %d mobile %s" % [plan.def.id, tile, plan.def.kind,
					plan.def.mobile])
	for closure in city.closures():
		var ctiles := closure.tiles(city.map)
		print("  closure kind %d cause %s tiles %s..%s" % [closure.kind,
				city.map.world_to_tile(closure.cause_centre(city.map)), ctiles[0], ctiles[-1]])
		for ct in ctiles:
			marks[ct] = "closure"
	var plan := city.region_plan()
	if plan:
		for body in plan.door_bodies:
			var tile := city.map.world_to_tile(body.position)
			if absi(tile.x - at.x) <= r * 3 and absi(tile.y - at.y) <= r * 3:
				print("  door body %s tile %s" % [body.def.id, tile])
	var glyph := {
		GameEnums.TileType.BUILDING: "B", GameEnums.TileType.SIDEWALK: ".",
		GameEnums.TileType.ROAD: "=", GameEnums.TileType.CROSSING: "#",
		GameEnums.TileType.PARK: "P", GameEnums.TileType.SQUARE: "S",
		GameEnums.TileType.ALLEY: "a", GameEnums.TileType.PLAYGROUND: "p",
		GameEnums.TileType.HOME: "H", GameEnums.TileType.FOREST: "F",
		GameEnums.TileType.QUIET_SQUARE: "q", GameEnums.TileType.COURTYARD: "c",
		GameEnums.TileType.SPOILED: "x",
	}
	var header := "      "
	for x in range(at.x - r, at.x + r + 1):
		header += str(absi(x) % 10)
	print(header)
	for y in range(at.y - r, at.y + r + 1):
		var line := "%5d " % y
		for x in range(at.x - r, at.x + r + 1):
			var tile := Vector2i(x, y)
			if tile == home:
				line += "@"
			elif marks.has(tile):
				line += "X" if marks[tile] == "closure" else "*"
			elif x < 0 or y < 0 or x >= city.map.size.x or y >= city.map.size.y:
				line += " "
			else:
				line += glyph.get(city.map.tile_at(tile), "?")
		print(line)
	city.free()
	t.check(true, "probe ran")

func _search(t) -> void:
	var from := int(OS.get_environment("PROBE_SEARCH"))
	var count := int(OS.get_environment("PROBE_COUNT"))
	var days := OS.get_environment("PROBE_DAYS").split(",")
	for seed_value in range(from, from + count):
		for day_word in days:
			var day := int(day_word)
			GameState.start_run(seed_value)
			GameState.day = day
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(GameState.run_seed))
			GameState.city_state.begin_day(city.map.block_plans, day)
			city.start_day(GameState.city_state, day, GameState.day_rng(day, "closures"))
			var home := city.map.world_to_tile(city.map.doorstep_world_position())
			for closure in city.closures():
				var cause := city.map.world_to_tile(closure.cause_centre(city.map))
				var d := absi(cause.x - home.x) + absi(cause.y - home.y)
				if d <= 22:
					print("SEARCH seed %d day %d male %s home %s closure kind %d cause %s dist %d" % [
							seed_value, day, GameState.player_is_male, home, closure.kind, cause, d])
			city.free()
	t.check(true, "search ran")
