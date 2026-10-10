extends RefCounted
## Measurement probe for plush-moose, "every task has a red arrow to the closest by walking
## distance": what choosing the arrow's target costs per tick on the three days several places
## answer a task (day 6's man shouting, day 11's live masts, day 13's roadblock), and how often a
## tick finds no walking length to any target. Not a suite: it prints times rather than asserting
## them, so it lives under `tests/probes/`, where the runner never discovers it, and runs only by
## name:
##
##     tools/test.sh probes/plush_moose_arrow_cost.gd      (prints PLUSH_MOOSE lines)
##
## **The rig.** Per seed and day, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), the mark read so the task is
## placed and her route rigged, and the day's longest route walked through
## `EventManager._site_what_is_on_her_way()` and `_place_what_is_owed_ahead()` until the rigged bag
## is spent, so day 11 has its second mast on her route and day 6 its second man shouting, the way a
## played day has them.
##
## **The positions.** The mark, then `POSITIONS - 1` sidewalk tiles reachable from home, taken at an
## even stride through every such tile in scan order, so they spread over the whole city rather than
## round the mark.
##
## **What is timed**, in milliseconds of wall clock in the debug build the test runner uses:
##
## - **tick**: `retarget_the_arrow()` with her at each position — what `_process()` runs twice a
##   second. On the per-target fields (`ArrowField`) it is a lookup, plus starting the sweep of the
##   one it now points at when it moved the arrow; on the walk it replaced, the whole walk.
## - **sweep slice**: one frame's `_sweep_the_arrow_fields(ARROW_SWEEP_TILES_PER_FRAME)` while a
##   sweep is under way, over the first sweep from nothing and every sweep a tick started; and how
##   many frames the longest of them took to finish.
## - **whole sweep at once**: the same field swept in one go, for scale — what one frame would cost
##   if the sweep were not spread.
##
## "no length from her" counts positions where her tile has no walking length to any target. Both
## versions of the director are measured by the same file: it asks for the fields' functions by
## name, so at a commit with the walk instead it times the walk.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567]
const DAYS: Array[int] = [6, 11, 13]
const POSITIONS := 10
const STEP := 0.1

func run(t) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var fields := ClassDB.class_exists("ArrowField") or ResourceLoader.exists(
			"res://src/resistance/arrow_field.gd")
	for day in DAYS:
		var ticks: Array[int] = []
		var slices: Array[int] = []
		var frames: Array[int] = []
		var whole: Array[int] = []
		var unreached := 0
		var targets := 0
		for seed_value in SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			GameState.scars = []
			var director := _read_the_mark(t, city, day, seed_value)
			var player := _rig_player(t, director.contact_position())
			_walk_the_rigged_bag(city, player)
			var step := director.current_step()
			if step == null or step.is_pickup:
				print("PLUSH_MOOSE seed %d day %d: no task on offer" % [seed_value, day])
				player.free()
				director.free()
				city.free()
				continue
			var found := director._arrow_candidates(step)
			targets = maxi(targets, found.size())
			print("PLUSH_MOOSE seed %d day %d: %d targets" % [seed_value, day, found.size()])
			var spots := _positions(city, director)
			if fields:
				# The first sweep from nothing, a frame's slice at a time, as `_process()` runs it.
				player.global_position = spots[0]
				director.retarget_the_arrow()
				frames.append(_sweep_to_the_end(director, slices))
				# And the same sweep at once, for scale.
				var started := Time.get_ticks_usec()
				var at_once: RefCounted = load("res://src/resistance/arrow_field.gd").call("start",
						city.map, found,
						Vector2i(city.map.day_record_version, city.map.obstruction_version))
				var ground: PackedInt32Array = director.call("_ground_for_the_arrow")
				at_once.call("advance", city.map, ground, 1 << 30)
				at_once.call("advance", city.map, ground, 1 << 30)
				whole.append(Time.get_ticks_usec() - started)
				director.call("_settle_the_arrow")
			for at in spots:
				player.global_position = at
				var started := Time.get_ticks_usec()
				director.retarget_the_arrow()
				ticks.append(Time.get_ticks_usec() - started)
				if fields:
					# A tick that moved the arrow starts the sweep of the one it now points at.
					frames.append(_sweep_to_the_end(director, slices))
				if _no_length_from(director, step, at):
					unreached += 1
			player.free()
			director.free()
			city.free()
		var line := "PLUSH_MOOSE day %d: %d positions, up to %d targets | tick mean %.3f ms worst %.3f ms" \
				% [day, ticks.size(), targets, _mean(ticks), _worst(ticks)]
		if fields:
			line += " | sweep slice mean %.3f ms worst %.3f ms over %d slices" \
					% [_mean(slices), _worst(slices), slices.size()]
			line += " | frames to finish a sweep worst %d" % _worst_count(frames)
			line += " | whole sweep at once mean %.2f ms worst %.2f ms" % [_mean(whole), _worst(whole)]
		print(line + " | no length from her %d" % unreached)
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.scars = saved_scars
	GameState.city_state = saved_state

## Whether no target had a walking length from `at`: on the fields, her tile read in the field of
## every target; on the walk, every length it returned.
func _no_length_from(director: ResistanceDirector, step: ResistanceSteps.Step, at: Vector2) -> bool:
	if director.has_method("_settle_the_arrow"):
		var nearest: RefCounted = director.get("_arrow_nearest")
		return nearest == null or int(nearest.call("length_at", director._map.world_to_tile(at))) < 0
	var lengths: Array[int] = director.call("_walking_lengths", at,
			director._arrow_candidates(step))
	for length in lengths:
		if length >= 0:
			return false
	return true

## Runs the sweeps under way a frame's slice at a time, timing each slice into `slices`, and
## answers how many frames they took.
func _sweep_to_the_end(director: ResistanceDirector, slices: Array[int]) -> int:
	var count := 0
	while (director.get("_arrow_nearest_next") != null or director.get("_arrow_own_next") != null) \
			and count < 1000:
		var started := Time.get_ticks_usec()
		director.call("_sweep_the_arrow_fields", director.get_script().get_script_constant_map()
				.get("ARROW_SWEEP_TILES_PER_FRAME", 1500))
		slices.append(Time.get_ticks_usec() - started)
		count += 1
	return count

func _worst_count(values: Array[int]) -> int:
	var worst := 0
	for v in values:
		worst = maxi(worst, v)
	return worst

func _read_the_mark(t, city: City, day: int, seed_value: int) -> ResistanceDirector:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < day:
			done.append(step.index)
	GameState.completed_resistance_steps = done
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
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
	var mark := director.current_step()
	if mark != null and mark.is_pickup:
		director._on_contact_completed(mark.index)
	return director

## Walks the day's longest route until the bag the mark rigged is spent, the way
## `tests/test_route_bag.gd` does, so what the rig puts on her route is in the day's plans.
func _walk_the_rigged_bag(city: City, player: Stroller) -> void:
	var path := _the_longest_route(city)
	if path.size() < 2:
		return
	var index := 0
	var direction := 1
	player.global_position = path[0]
	var walked := 0.0
	city.events._find_player()
	var bag := city.events._director.route_bag()
	while walked < 600.0 and bag and not bag.bag_in_front().is_empty():
		var next: Vector2 = path[index + direction] if index + direction >= 0 \
				and index + direction < path.size() else Vector2.INF
		if next == Vector2.INF:
			direction = -direction
			continue
		var toward := next - player.global_position
		if toward.length() < Tuning.WALK_SPEED * STEP:
			player.global_position = next
			index += direction
			continue
		player.velocity = toward.normalized() * Tuning.WALK_SPEED
		city.events._site_what_is_on_her_way(STEP)
		city.events._place_what_is_owed_ahead(STEP)
		player.global_position += player.velocity * STEP
		walked += STEP

func _the_longest_route(city: City) -> Array[Vector2]:
	var longest: Array = []
	for branch in city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(EventScheduler.WalkSiting._cell_centre(city.map, longest[i]))
	return points

func _positions(city: City, director: ResistanceDirector) -> Array[Vector2]:
	var map := city.map
	var sidewalk: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not map.is_obstructed(tile) \
					and director._reachable_from_home(tile):
				sidewalk.append(tile)
	var spots: Array[Vector2] = [director.contact_position()]
	if director._read_mark:
		spots[0] = director._read_mark.global_position
	var stride := maxi(1, sidewalk.size() / POSITIONS)
	for i in range(stride / 2, sidewalk.size(), stride):
		if spots.size() >= POSITIONS:
			break
		spots.append(map.tile_to_world(sidewalk[i]))
	return spots

func _rig_player(t, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	return player

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

func _mean(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0
	for v in values:
		total += v
	return total / 1000.0 / values.size()

func _worst(values: Array[int]) -> float:
	var worst := 0
	for v in values:
		worst = maxi(worst, v)
	return worst / 1000.0
