extends RefCounted
## Measurement probe for calm-pelican's day-13 roadblock (the-arrow-and-the-day-13-guard): with the
## task's own roadblock placed the way the day places one, near where she read the mark
## (`ResistanceDirector._place_the_roadblock_near()`), how often that placement finds a site under
## the day's rules rather than falling back to the spawn on the circle's edge, how far the task's
## roadblock stands from the mark, and how often the red arrow — the closest live roadblock on foot
## (plush-moose) — points at the task's own roadblock rather than another. Not a suite: it prints
## counts rather than asserting them, so it lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/calm_pelican_day13_roadblock.gd      (prints DAY13_ROADBLOCK lines)
##
## **The rig.** Per seed, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), her standing on the mark with
## the camera's unrotated view round her answering what is on screen, and the mark read, so the task
## is placed as a played day places it. The arrow is then settled from where she stands
## (`_settle_the_arrow()`), and again from each of `WALK_STOPS` points on her straight line toward
## the task's roadblock, to see whether the arrow stays on it as she walks there.
##
## **Before and after in one file.** `FallbackDirector` refuses every placement under the day's
## rules, which is the spawn on the circle's edge every other task near its mark takes — the
## placement before this change — so both are measured on the same cities and the same seeds.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY := 13
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024, 555, 8080, 99, 123456,
		271828, 314159]
## Points on her straight line from the mark to the task's roadblock, as fractions of the way.
const WALK_STOPS: Array[float] = [0.25, 0.5, 0.75]

## A director whose placement under the day's rules always comes back empty: the edge spawn.
class FallbackDirector extends ResistanceDirector:
	func _place_the_roadblock_near(_mark: Vector2) -> EventInstance:
		return null

func run(t) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	for fallback in [true, false]:
		_measure(t, fallback)
	GameState.completed_resistance_steps.assign(saved_completed)
	GameState.failed_resistance_steps.assign(saved_failed)
	GameState.resistance_progress = saved_progress
	GameState.scars.assign(saved_scars)
	GameState.city_state = saved_state

func _measure(t, fallback: bool) -> void:
	var label := "before (edge spawn)" if fallback else "after (placed under the day's rules)"
	var placed_by_rules := 0
	var tasks := 0
	var own_from_mark := 0
	var own_on_the_way := 0
	var stops := 0
	var distances: Array[float] = []
	var live_counts: Array[int] = []
	var reading: Array[float] = []
	for seed_value in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		GameState.scars = []
		var director: ResistanceDirector = FallbackDirector.new() if fallback \
				else ResistanceDirector.new()
		var player := _start_the_day(t, city, director, seed_value)
		var mark := director.current_step()
		if mark == null or not mark.is_pickup:
			print("DAY13_ROADBLOCK seed %d: no mark" % seed_value)
			_tear_down(player, director, city)
			continue
		var mark_at := director.contact_position()
		player.global_position = mark_at
		var view_round := func(at: Vector2) -> bool:
			var off := (at - player.global_position).abs()
			return off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y
		director.set_sight(view_round, view_round)
		var plans_before := city.events.plans().size()
		var started := Time.get_ticks_usec()
		director._on_contact_completed(mark.index)
		reading.append((Time.get_ticks_usec() - started) / 1000.0)
		var step := director.current_step()
		var own: EventInstance = director._rider
		if step == null or own == null:
			print("DAY13_ROADBLOCK seed %d: no task" % seed_value)
			_tear_down(player, director, city)
			continue
		tasks += 1
		var newest: EventScheduler.Planned = city.events.plans().back()
		var by_rules: bool = city.events.plans().size() > plans_before and newest.live == own
		if by_rules:
			placed_by_rules += 1
		var distance := own.body_position().distance_to(mark_at)
		distances.append(distance)
		director._settle_the_arrow()
		var found := director._arrow_candidates(step)
		live_counts.append(found.size())
		var own_key := own.get_instance_id()
		var first_own := ResistanceDirector._same_key(director._arrow_key, own_key)
		if first_own:
			own_from_mark += 1
		var stayed := 0
		for along in WALK_STOPS:
			var at := mark_at.lerp(own.body_position(), along)
			var tile := city.map.world_to_tile(at)
			if not city.map.is_walkable(tile):
				continue
			player.global_position = at
			director._settle_the_arrow()
			stops += 1
			if ResistanceDirector._same_key(director._arrow_key, own_key):
				own_on_the_way += 1
				stayed += 1
		print("DAY13_ROADBLOCK %s seed %d: %s, %.0fpx from the mark, %d live roadblocks, arrow on it from the mark: %s, on the way %d" % [
				label, seed_value, "under the rules" if by_rules else "edge spawn", distance,
				found.size(), first_own, stayed])
		_tear_down(player, director, city)
	distances.sort()
	print("DAY13_ROADBLOCK %s: %d tasks, %d placed under the day's rules | from the mark the arrow points at the task's own roadblock %d of %d | on the way to it %d of %d stops | distance from the mark min %.0f median %.0f max %.0f px | live roadblocks %s | reading the mark took mean %.0f worst %.0f ms"
			% [label, tasks, placed_by_rules, own_from_mark, tasks, own_on_the_way, stops,
			distances[0] if not distances.is_empty() else 0.0,
			distances[distances.size() / 2] if not distances.is_empty() else 0.0,
			distances.back() if not distances.is_empty() else 0.0, live_counts,
			_mean(reading), _worst(reading)])

func _start_the_day(t, city: City, director: ResistanceDirector, seed_value: int) -> Stroller:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.completed_resistance_steps.assign(done)
	GameState.failed_resistance_steps.assign([])
	GameState.resistance_progress = 0
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	city.events.start_day(DAY, _rng(seed_value, "events"), [], city.map.doorstep_world_position())
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = city.map.doorstep_world_position()
	return player

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, DAY, stream])
	return rng

func _tear_down(player: Stroller, director: ResistanceDirector, city: City) -> void:
	player.free()
	director.free()
	city.free()

func _mean(values: Array[float]) -> float:
	var total := 0.0
	for v in values:
		total += v
	return total / values.size() if not values.is_empty() else 0.0

func _worst(values: Array[float]) -> float:
	var worst := 0.0
	for v in values:
		worst = maxf(worst, v)
	return worst
