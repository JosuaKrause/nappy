extends RefCounted
## Measurement probe for grassy-goose (inbox #556), "a touched target sends the robber from off
## screen": where the trap's start falls on each target's own ground — the burnt building's door on
## its facade (day 8), the district door in a region wall (day 9), a mast's foot (day 11), the swing
## in its park (day 12) and the station's door on its facade (the last night) — and whether walking
## away from him escapes. Not a suite: it prints rates rather than asserting them, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/grassy_goose_target_traps.gd
##
## **The rig.** Per seed and day, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), the mark read so the task is
## placed, and her standing where the trap is sent from:
##
## - on its contact for a mast's foot and the swing;
## - for a door on a facade, on the sidewalk tile straight below it, inside its reach;
## - for day 9's district door, where an inspection lets her out: the gatehouse the arrow names,
##   `obstructs_radius + PLAYER_BODY_RADIUS + CHECKPOINT_RELEASE_MARGIN` (54px) past the door's line
##   along the street, once on each side (`EventManager._release_finished_door_detentions()`), so
##   day 9 counts two cases a city.
##
## From there `ResistanceDirector._draw_arrival_position()` — the same call `_set_the_trap_on_her()`
## makes, told whether the target is a front door — is asked with the director's own `_rng` and a
## `_sight` answering the unrotated 640x360 screen round her. Counted per case: a start from across
## the street, above or below her with a clear run, beside her along her street with one, a legal
## start with no clear run at all, and no legal start; and, independently of the director, whether
## his straight run at her passes through a district door's line
## (`EventManager.where_she_crossed()` over each door body).
##
## **Walking away.** From each start a `robber_giving_chase` is walked against her for his whole
## notice and chase (`EventInstance._process()` at 60 frames a second): once with her standing still,
## and once walking at `Tuning.WALK_SPEED` in each of the four street directions, sliding along
## walls the way a body does. "A walk escapes" counts the cases where at least one of the four walks
## outlasts him — the trap a player beats without running. Each such case is printed with the
## headings that escape and his start relative to her.
##
## Written to run against the code before the front-door start too, for a before-and-after: it
## passes the front-door flag only when `_draw_arrival_position()` takes one.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS_TO_SWEEP := 30
const DAYS: Array[int] = [8, 9, 11, 12, 14]
const STEP := 1.0 / 60.0
const HEADINGS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

## Columns of the start table, in print order.
const ACROSS := 0
const ABOVE_BELOW := 1
const BESIDE := 2
const NO_CLEAR_RUN := 3
const NO_START := 4
const NO_TASK := 5
## Columns of the escape table.
const CASES := 0
const THROUGH_THE_DOOR := 1
const STOOD_CAUGHT := 2
const A_WALK_ESCAPES := 3

func run(t) -> void:
	var def := EventCatalogue.by_id("robber_giving_chase")
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	var saved_state := GameState.city_state
	var starts := {}
	var walks := {}
	for day in DAYS:
		starts[day] = [0, 0, 0, 0, 0, 0]
		walks[day] = [0, 0, 0, 0]
	for seed_value in range(1, SEEDS_TO_SWEEP + 1):
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in DAYS:
			var tally: Array = starts[day]
			var walked: Array = walks[day]
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
				tally[NO_TASK] += 1
				director.free()
				continue
			var front_door := task.target_kind == ResistanceSteps.TargetKind.STATION_DOOR \
					or task.task_event_id == "burnt_shell"
			for her: Vector2 in _where_she_stands(city, director, day):
				var at := _draw(director, her, def, front_door)
				var result: Array = at[1]
				var start: Vector2 = result[0]
				if start == Vector2.INF:
					tally[NO_START] += 1
					continue
				if result.size() > 3 and result[3]:
					tally[ACROSS] += 1
				elif result[2]:
					tally[BESIDE] += 1
				elif result[1]:
					tally[ABOVE_BELOW] += 1
				else:
					tally[NO_CLEAR_RUN] += 1
					print("[grassy-goose] seed %d day %d: no clear run to her at %s"
							% [seed_value, day, city.map.world_to_tile(her)])
				walked[CASES] += 1
				if _runs_through_a_door(city, start, her):
					walked[THROUGH_THE_DOOR] += 1
				if _chase(t, city, def, start, her, Vector2.ZERO):
					walked[STOOD_CAUGHT] += 1
				var escaped: Array[String] = []
				for heading in HEADINGS:
					if not _chase(t, city, def, start, her, heading):
						escaped.append("%s" % heading)
				if not escaped.is_empty():
					walked[A_WALK_ESCAPES] += 1
					print("[grassy-goose] seed %d day %d: walking %s escapes him from %s off her"
							% [seed_value, day, ", ".join(escaped), start - her])
			director.free()
		city.free()
	GameState.completed_resistance_steps = saved_completed
	GameState.resistance_progress = saved_progress
	GameState.completed_resistance_alley_tiles = saved_tiles
	GameState.scars = saved_scars
	GameState.day = saved_day
	GameState.city_state = saved_state
	print("\n== grassy-goose: where a touched target's robber starts, %d seeds ==" % SEEDS_TO_SWEEP)
	print("| day | across the street | above/below, clear run | beside, clear run | no clear run at all | no legal start | no task |")
	print("|---|---|---|---|---|---|---|")
	for day in DAYS:
		var tally: Array = starts[day]
		print("| %d | %d | %d | %d | %d | %d | %d |" % [day, tally[ACROSS], tally[ABOVE_BELOW],
				tally[BESIDE], tally[NO_CLEAR_RUN], tally[NO_START], tally[NO_TASK]])
	print("\n== grassy-goose: walking away from him ==")
	print("| day | cases with a start | run through a district door | standing still is caught | a walk escapes |")
	print("|---|---|---|---|---|")
	for day in DAYS:
		var walked: Array = walks[day]
		print("| %d | %d | %d | %d | %d |" % [day, walked[CASES], walked[THROUGH_THE_DOOR],
				walked[STOOD_CAUGHT], walked[A_WALK_ESCAPES]])
	t.check(true, "probe ran")

## Where she stands when the day's trap is sent — see the class doc. Day 9 is two places, one on
## each side of the door's line; every other day one.
func _where_she_stands(city: City, director: ResistanceDirector, day: int) -> Array[Vector2]:
	var her := director.contact_position()
	if day != 9:
		if not city.map.is_walkable(city.map.world_to_tile(her)):
			her += Vector2(0.0, Tuning.TILE_SIZE)
		return [her]
	var hut: EventScheduler.Planned = null
	for body in city.region_plan().door_bodies:
		if body.def.redetains and body.position.distance_to(her) < 0.5:
			hut = body
	if hut == null:
		return [her]
	var out := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ Tuning.CHECKPOINT_RELEASE_MARGIN
	return [hut.position + hut.facing * out, hut.position - hut.facing * out]

## `_draw_arrival_position()` asked with `_sight` set to the screen round `her`; returns
## `[her, result]`.
func _draw(director: ResistanceDirector, her: Vector2, def: EventDef, front_door: bool) -> Array:
	var screen := func(p: Vector2) -> bool:
		return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
				and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y
	director.set_sight(screen, screen)
	var args: Array = [director._rng, her, def]
	if director.get_method_argument_count("_draw_arrival_position") >= 4:
		args.append(front_door)
	var result: Array = director.callv("_draw_arrival_position", args)
	return [her, result]

## Whether the straight run from `start` to `her` crosses the line of any of today's district-door
## bodies, the question `EventManager._watch_the_door_lines()` asks of her own steps.
func _runs_through_a_door(city: City, start: Vector2, her: Vector2) -> bool:
	var plan := city.region_plan()
	if not plan:
		return false
	for body in plan.door_bodies:
		if EventManager.where_she_crossed(body.position, body.facing, body.def.obstructs_radius,
				start, her) != Vector2.INF:
			return true
	return false

## A `robber_giving_chase` started at `start` against her at `her`, walking `heading` at
## `Tuning.WALK_SPEED` (standing still for `Vector2.ZERO`), for his whole notice and chase. Whether
## he catches her.
func _chase(t, city: City, def: EventDef, start: Vector2, her_at: Vector2, heading: Vector2) -> bool:
	var chaser := EventInstance.new()
	chaser.setup(def, start, PackedVector2Array(), Vector2.RIGHT, city.map)
	t.add_child(chaser)
	chaser.set_process(false)
	var her := her_at
	var caught := false
	var elapsed := 0.0
	var limit := def.telegraph_time + def.duration + 1.0
	while elapsed < limit and not chaser.is_finished and not chaser.is_leaving:
		her += _her_step(city.map, her, heading * Tuning.WALK_SPEED * STEP)
		chaser.player_at = her
		chaser.player_running = false
		chaser._process(STEP)
		elapsed += STEP
		if chaser.is_lethal_at(her):
			caught = true
			break
	chaser.free()
	return caught

## Her own step, sliding along a wall on whichever axis is still open — the probe's stand-in for
## her body's `move_and_slide()`.
func _her_step(map: CityMap, from: Vector2, delta: Vector2) -> Vector2:
	if delta.is_zero_approx() or map.is_walkable(map.world_to_tile(from + delta)):
		return delta
	for along: Vector2 in [Vector2(delta.x, 0.0), Vector2(0.0, delta.y)]:
		if not along.is_zero_approx() and map.is_walkable(map.world_to_tile(from + along)):
			return along
	return Vector2.ZERO

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
