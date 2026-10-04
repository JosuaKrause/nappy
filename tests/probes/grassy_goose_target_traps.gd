extends RefCounted
## Measurement probe for grassy-goose (inbox #556), "a touched target sends the robber from off
## screen": how the trap's start falls on each target's own ground — the burnt building's door on
## its facade (day 8), the district door in a region wall (day 9), a mast's foot (day 11), the swing
## in its park (day 12) and the station's door on its facade (the last night). Not a suite: it
## prints rates rather than asserting them, so it lives under `tests/probes/`, where the runner
## never discovers it, and runs only by name:
##
##     tools/test.sh probes/grassy_goose_target_traps.gd
##
## **The rig.** Per seed and day, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), the mark read so the task is
## placed, and her standing where the task is touched from: on its contact, or, for a door on a
## facade, on the sidewalk tile straight below it, inside its reach. From there
## `ResistanceDirector._draw_arrival_position()` — the same call `_set_the_trap_on_her()` makes —
## is asked with the director's own `_rng` and a `_sight` answering the unrotated 640x360 screen
## round her, the same predicate `tests/test_resistance.gd` gives it. Counted: a start above or below
## her with a clear run, a start beside her along her street with one, a legal start with no clear
## run at all, and no legal start.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS_TO_SWEEP := 30
const DAYS: Array[int] = [8, 9, 11, 12, 14]

func run(t) -> void:
	var def := EventCatalogue.by_id("robber_giving_chase")
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	var saved_state := GameState.city_state
	var counts := {}
	for day in DAYS:
		counts[day] = [0, 0, 0, 0, 0]
	for seed_value in range(1, SEEDS_TO_SWEEP + 1):
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in DAYS:
			var tally: Array = counts[day]
			var finale := day == Tuning.RUN_LENGTH_DAYS
			var done: Array[int] = []
			for step in ResistanceSteps.all():
				if (finale and not step.needs_goal) or (not finale and step.index <= 2 * (day - 6)):
					done.append(step.index)
			GameState.completed_resistance_steps = done
			GameState.resistance_progress = Tuning.RESISTANCE_GOAL if finale else 0
			GameState.completed_resistance_alley_tiles = []
			GameState.scars.clear()
			GameState.day = day
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
			var offered := director.current_step()
			if offered and offered.is_pickup:
				director._on_contact_completed(offered.index)
			var task := director.current_step()
			if task == null or task.is_pickup:
				tally[4] += 1
				director.free()
				continue
			var her := director.contact_position()
			if not city.map.is_walkable(city.map.world_to_tile(her)):
				her += Vector2(0.0, Tuning.TILE_SIZE)
			director.set_sight(func(p: Vector2) -> bool:
				return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
						and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y)
			var result: Array = director._draw_arrival_position(director._rng, her, def)
			var at: Vector2 = result[0]
			if at == Vector2.INF:
				tally[3] += 1
			elif result[2]:
				tally[1] += 1
			elif result[1]:
				tally[0] += 1
			else:
				tally[2] += 1
				print("[grassy-goose] seed %d day %d: no clear run to her at %s"
						% [seed_value, day, city.map.world_to_tile(her)])
			director.free()
		city.free()
	GameState.completed_resistance_steps = saved_completed
	GameState.resistance_progress = saved_progress
	GameState.completed_resistance_alley_tiles = saved_tiles
	GameState.scars = saved_scars
	GameState.day = saved_day
	GameState.city_state = saved_state
	print("\n== grassy-goose: where a touched target's robber starts, %d seeds ==" % SEEDS_TO_SWEEP)
	print("| day | above/below, clear run | beside, clear run | no clear run at all | no legal start | no task |")
	print("|---|---|---|---|---|---|")
	for day in DAYS:
		var tally: Array = counts[day]
		print("| %d | %d | %d | %d | %d | %d |" % [day, tally[0], tally[1], tally[2], tally[3],
				tally[4]])
	t.check(true, "probe ran")

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
