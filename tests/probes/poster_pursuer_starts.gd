extends RefCounted
## **Where a torn poster's pursuer on foot starts, one line a tear**, so a change to how his start
## is sited can be counted: the tears whose start moves and the tears that now send nobody. Not a
## suite: it prints rather than asserts. Run by name before and after a change and compare the
## `PP ` lines:
##
##     tools/test.sh probes/poster_pursuer_starts.gd > before.txt
##     grep '^PP ' before.txt > before.pp     (and the same for after; `diff` the two)
##
## Per seed and every day posters are up (`PosterWalls.FIRST_DAY` to the last), a real city through
## the real day order with its walls pasted, a rig player handed to the events, and up to
## `TEARS_A_DAY` pasted sheets spread over the walls in tile order: she stands on the sheet's front
## tile, the day's view about her, and the pursuit marble is drawn
## (`EventManager.send_a_pursuer()`); the badge is run to its end with her standing there, and where
## he was created is printed, or that nobody was sent. The run's tear count is set to the sheet's
## index, so which way he is tried from first (a hash of the run and the count) varies across the
## tears.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := 40
const TEARS_A_DAY := 5
const STEP := 1.0 / 60.0

func run(t) -> void:
	var saved_day := GameState.header.day
	var saved_state := GameState.attempt_spend.city_state
	var saved_tears := GameState.posters.tears
	var printed := 0
	var nobody := 0
	for seed_value in range(1, SEEDS + 1):
		GameState.start_run(seed_value)
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in range(PosterWalls.FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			GameState.header.day = day
			var state := CityState.new()
			GameState.attempt_spend.city_state = state
			state.begin_day(city.map.block_plans, day)
			city.start_day(state, day, _rng(seed_value, day, "closures"))
			city.events.start_day(DaySpec.for_day(day), _rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())
			var player := Stroller.new()
			var camera := Camera2D.new()
			camera.name = "Camera2D"
			camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
			player.add_child(camera)
			t.add_child(player)
			player.set_physics_process(false)
			player.add_to_group("player")
			city.events.use_player(player)
			var sheets: Array = GameState.posters.cells.keys()
			sheets.sort()
			var picked: Array[Vector2i] = []
			for i in mini(TEARS_A_DAY, sheets.size()):
				picked.append(sheets[(i * sheets.size()) / TEARS_A_DAY])
			var tears := 0
			for tile: Vector2i in picked:
				tears += 1
				GameState.posters.tears = tears
				var her := city.map.tile_to_world(tile)
				player.global_position = her
				city.events.visible_view().look(Rect2(her - Tuning.VIEW_HALF_EXTENT,
						Tuning.VIEW_HALF_EXTENT * 2.0), null)
				city.events.ahead.clear()
				city.events.send_a_pursuer()
				var shown := 0.0
				while not city.events.pending_warnings().is_empty() and shown < 5.0:
					city.events.warnings.run(STEP, her)
					shown += STEP
				var sent := city.events.ahead.sent_pursuer()
				var made := "nobody"
				if sent:
					made = "%s at (%s, %s)" % [sent.def.id, var_to_str(sent.global_position.x),
							var_to_str(sent.global_position.y)]
					city.events.retire(sent)
				else:
					nobody += 1
				print("PP seed %d day %d tear %d at %s -> %s" % [seed_value, day, tears,
						RunTrace.tile(tile), made])
				printed += 1
			city.events.ahead.clear()
			player.free()
		city.free()
	GameState.header.day = saved_day
	GameState.attempt_spend.city_state = saved_state
	GameState.posters.tears = saved_tears
	print("PP_TOTAL %d tears, %d sent nobody" % [printed, nobody])
	t.check(printed > 0, "there were tears to print (%d)" % printed)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
