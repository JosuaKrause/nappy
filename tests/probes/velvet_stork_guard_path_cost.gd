extends RefCounted
## Measurement probe for velvet-stork, "day 13's guard reaches her from across the city": what the
## guard's walk round buildings (`EventInstance._chase_way`) costs a frame of his chase, and
## whether he reaches her. Not a suite: it prints times rather than asserting them, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/velvet_stork_guard_path_cost.gd       (prints VELVET_STORK lines)
##     PROBE_SEEDS=4242,90210 tools/test.sh probes/velvet_stork_guard_path_cost.gd
##
## **The rig** is `tests/test_day13_guard.gd`'s parked guard: a real city through the real day order
## on day 13, the mark read, the guard held at the task's own roadblock by her view on him while she
## walks to another live roadblock and touches it, which sets him on her
## (`ResistanceDirector._set_the_task_guard_on_her()`). Each seed runs twice from the same start:
##
## - **standing**: she stays where she touched the roadblock;
## - **walking away**: she walks at `Tuning.WALK_SPEED` along the shortest walk to the walkable
##   tile farthest on foot from where she touched it, and stands once she is there.
##
## Each runs at 60 steps a second of game time until he is within his stand-off of her, catches
## her, or `CHASE_SECONDS` have passed (his notice plus the 30s `Tuning.PURSUIT_TIME` cap).
##
## **What is timed**, in milliseconds of wall clock in the debug build the test runner uses: each
## step's `EventInstance.step()` — his whole tick, the chase and the sweep's slice with it.
## Printed: the mean, the 99th percentile and the worst frame; the share of frames on which a sweep
## was under way (`ChaseWay.sweep_under_way()`); how many sweeps were begun; and the outcome — the nearest he
## came and when he reached her stand-off, if he did.

const SUITE := preload("res://tests/test_day13_guard.gd")
const DEFAULT_SEEDS: Array[int] = [4242, 90210, 555]
const FRAME := 1.0 / 60.0
const CHASE_SECONDS := 31.8

func run(t) -> void:
	var seeds := DEFAULT_SEEDS.duplicate()
	if OS.get_environment("PROBE_SEEDS") != "":
		seeds.clear()
		for part in OS.get_environment("PROBE_SEEDS").split(","):
			seeds.append(int(part))
	for seed_value: int in seeds:
		for walks in [false, true]:
			_measure(t, seed_value, walks)

func _measure(t, seed_value: int, walks: bool) -> void:
	var suite = SUITE.new()
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_failed := GameState.resistance.failed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var saved_alleys := GameState.facts.completed_resistance_alley_tiles.duplicate()
	var city: City = RunCity.of_the_run(SUITE.CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.scars = []
	var director: ResistanceDirector = suite._start_the_day(t, city, seed_value)
	var player: Stroller = suite._rig_player(t, director, director.contact_position())
	var label := "VELVET_STORK seed %d %s:" % [seed_value, "walking away" if walks else "standing"]
	var mark := director.current_step()
	if mark:
		director._on_contact_completed(mark.index)
	var step := director.current_step()
	var guard: EventInstance = director._task_guard
	var touched: EventInstance = null
	if step and guard:
		director._settle_the_arrow()
		var held := guard.global_position
		suite._view = Rect2(held - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
		touched = suite._her_way_to_another_roadblock(director, player, step)
	if touched == null:
		print("%s no other live roadblock to touch" % label)
		_finish(suite, player, director, city, saved_completed, saved_failed, saved_progress,
				saved_scars, saved_state, saved_alleys)
		return
	director._move_the_task_guard_to_her_target()
	var map := city.map
	var at: Vector2 = SUITE._beside(map, touched.body_position(), ContactPoint.body_reach(touched))
	player.global_position = at
	director._on_contact_completed(step.index)
	var route := _walk_away_from(map, at) if walks else PackedVector2Array()
	var standoff := Tuning.pursuit_standoff(guard.def.chase_speed(), guard.def.standoff_reach())
	var start := guard.global_position.distance_to(at)
	var times := PackedFloat64Array()
	var sweeping := 0
	var begun := 0
	var nearest := start
	var reached_at := -1.0
	var caught := false
	var her := at
	var next := 0
	var clock := 0.0
	while clock < CHASE_SECONDS and not guard.is_finished:
		if next < route.size():
			her = her.move_toward(route[next], Tuning.WALK_SPEED * FRAME)
			if her.distance_to(route[next]) < 0.01:
				next += 1
		guard.player_at = her
		var before: WalkField = guard._chase_way.sweep_under_way() if guard._chase_way else null
		var t0 := Time.get_ticks_usec()
		guard.step(FRAME)
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
		var after: WalkField = guard._chase_way.sweep_under_way() if guard._chase_way else null
		if before != null or after != null:
			sweeping += 1
		if after != null and after != before:
			begun += 1
		clock += FRAME
		var gap := guard.global_position.distance_to(her)
		nearest = minf(nearest, gap)
		if guard.is_lethal_at(her):
			caught = true
		if gap <= standoff + 1.0 or caught:
			reached_at = clock
			break
	var sorted := times.duplicate()
	sorted.sort()
	var total := 0.0
	for ms in times:
		total += ms
	print(("%s from %.0fpx, %d frames: mean %.3fms, p99 %.3fms, worst %.3fms; a sweep under way " +
			"on %.0f%% of frames, %d sweeps begun; nearest %.0fpx (stand-off %.0fpx), %s")
			% [label, start, times.size(), total / maxi(times.size(), 1),
			sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))], sorted[sorted.size() - 1],
			100.0 * sweeping / maxi(times.size(), 1), begun, nearest, standoff,
			("reached her stand-off at %.1fs" % reached_at) if reached_at >= 0.0
			else "not reached in %.1fs" % clock])
	_finish(suite, player, director, city, saved_completed, saved_failed, saved_progress,
			saved_scars, saved_state, saved_alleys)

## The shortest walk from `from` to the walkable tile farthest from it on foot, as tile centres.
static func _walk_away_from(map: CityMap, from: Vector2) -> PackedVector2Array:
	var origin := map.world_to_tile(from)
	var out := map.walk_field(origin)
	var far := origin
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.distance_at(out, tile) > map.distance_at(out, far):
				far = tile
	var back := map.walk_field(far)
	var route := PackedVector2Array()
	var tile := origin
	while tile != far:
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

func _finish(suite, player: Stroller, director: ResistanceDirector, city: City, completed: Array,
		failed: Array, progress: int, scars: Array, state: CityState, alleys: Array) -> void:
	suite._tear_down(player, director, city)
	suite._restore(completed, failed, progress, scars, state)
	GameState.facts.completed_resistance_alley_tiles.assign(alleys)
