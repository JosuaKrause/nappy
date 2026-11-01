extends RefCounted
## Parity probe for minty-quail's shared-components D2 (the walk field on the world layer, the chase
## way from the `Navigator`): prints, deterministically and with no timing in it, what the move of
## the red arrow's sweep to `WalkField` and of day 13's task guard's way to `ChaseWay` must leave
## byte-identical. Not a suite: it asserts nothing, so it lives under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/minty_quail_walk_field_parity.gd | grep '^D2_PARITY' > out.txt
##
## **Two parts.** The guard: on day 13 on each of `GUARD_SEEDS`, the rig of
## `tests/probes/velvet_stork_guard_path_cost.gd` (the guard set on her by the done task, standing
## where she touched, or with her walking away from it), and per 60 Hz tick his position, his
## heading and the red arrow's target tile. The arrow: on each of `ARROW_DAYS` that a task several
## places answer is on offer, on each of `ARROW_SEEDS`, the tile of the target the arrow points at
## with her at each of `POSITIONS` spread over the city, after every sweep has finished.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SUITE := preload("res://tests/test_day13_guard.gd")
const PROBE := preload("res://tests/probes/velvet_stork_guard_path_cost.gd")
const GUARD_SEEDS: Array[int] = [4242, 90210, 555]
const ARROW_SEEDS: Array[int] = [4242, 90210]
const ARROW_DAYS: Array[int] = [6, 11, 13]
const POSITIONS := 12
const FRAME := 1.0 / 60.0
const CHASE_SECONDS := 31.8

func run(t) -> void:
	for seed_value in GUARD_SEEDS:
		for walks in [false, true]:
			_the_guard(t, seed_value, walks)
	for day in ARROW_DAYS:
		for seed_value in ARROW_SEEDS:
			_the_arrow(t, day, seed_value)

func _the_guard(t, seed_value: int, walks: bool) -> void:
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
	var label := "D2_PARITY guard seed %d %s" % [seed_value, "walking" if walks else "standing"]
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
		print("%s: no other live roadblock to touch" % label)
		_finish(suite, player, director, city, saved_completed, saved_failed, saved_progress,
				saved_scars, saved_state, saved_alleys)
		return
	director._move_the_task_guard_to_her_target()
	var map := city.map
	var at: Vector2 = SUITE._beside(map, touched.body_position(), ContactPoint.body_reach(touched))
	player.global_position = at
	director._on_contact_completed(step.index)
	var route := PROBE._walk_away_from(map, at) if walks else PackedVector2Array()
	var standoff := PursuitSpec.standoff(guard.def.chase_speed(), guard.def.standoff_reach())
	var her := at
	var next := 0
	var clock := 0.0
	var tick := 0
	while clock < CHASE_SECONDS and not guard.is_finished:
		if next < route.size():
			her = her.move_toward(route[next], Tuning.WALK_SPEED * FRAME)
			if her.distance_to(route[next]) < 0.01:
				next += 1
		guard.player_at = her
		guard.step(FRAME)
		clock += FRAME
		print("%s tick %d: at (%.3f, %.3f) heading (%.5f, %.5f) arrow tile %s" % [label, tick,
				guard.global_position.x, guard.global_position.y, guard.facing_now().x,
				guard.facing_now().y, _arrow_tile(director)])
		tick += 1
		if guard.is_lethal_at(her) or guard.global_position.distance_to(her) <= standoff + 1.0:
			break
	print("%s: %d ticks" % [label, tick])
	_finish(suite, player, director, city, saved_completed, saved_failed, saved_progress,
			saved_scars, saved_state, saved_alleys)

func _finish(suite, player: Stroller, director: ResistanceDirector, city: City, completed: Array,
		failed: Array, progress: int, scars: Array, state: CityState, alleys: Array) -> void:
	suite._tear_down(player, director, city)
	suite._restore(completed, failed, progress, scars, state)
	GameState.facts.completed_resistance_alley_tiles.assign(alleys)

func _arrow_tile(director: ResistanceDirector) -> Vector2i:
	var at := director._arrow_position()
	return Vector2i(-1, -1) if at == Vector2.INF else director._map.world_to_tile(at)

func _the_arrow(t, day: int, seed_value: int) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_failed := GameState.resistance.failed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.scars = []
	var director := _read_the_mark(t, city, day, seed_value)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = director.contact_position()
	var label := "D2_PARITY arrow day %d seed %d" % [day, seed_value]
	var step := director.current_step()
	if step == null or step.is_pickup:
		print("%s: no task on offer" % label)
	else:
		var found := director._arrow_candidates(step)
		print("%s: %d targets" % [label, found.size()])
		var index := 0
		for at in _positions(city, director):
			player.global_position = at
			director._settle_the_arrow()
			print("%s position %d (%.1f, %.1f): arrow tile %s, length %d, nearest tile %s" % [label,
					index, at.x, at.y, _arrow_tile(director), _length_at(director, at),
					_nearest_tile(director, found, at)])
			index += 1
	player.free()
	director.free()
	city.free()
	GameState.resistance.completed_steps = saved_completed
	GameState.resistance.failed_steps = saved_failed
	GameState.resistance.progress = saved_progress
	GameState.attempt_spend.scars = saved_scars
	GameState.attempt_spend.city_state = saved_state

func _length_at(director: ResistanceDirector, at: Vector2) -> int:
	var nearest = director._arrow_nearest
	return -2 if nearest == null else nearest.length_at(director._map.world_to_tile(at))

## The tile of the target the field of every target says is closest to `at`, from `found`.
func _nearest_tile(director: ResistanceDirector, found: Array[Dictionary], at: Vector2) -> Vector2i:
	var nearest = director._arrow_nearest
	if nearest == null:
		return Vector2i(-1, -1)
	var key = nearest.nearest_at(director._map.world_to_tile(at))
	for target in found:
		if key != null and ResistanceDirector._same_key(target["key"], key):
			return director._map.world_to_tile(target["at"])
	return Vector2i(-1, -1)

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
	var stride := maxi(1, sidewalk.size() / POSITIONS)
	for i in range(stride / 2, sidewalk.size(), stride):
		if spots.size() >= POSITIONS:
			break
		spots.append(map.tile_to_world(sidewalk[i]))
	return spots

func _read_the_mark(t, city: City, day: int, seed_value: int) -> ResistanceDirector:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < day:
			done.append(step.index)
	GameState.resistance.completed_steps = done
	GameState.resistance.failed_steps = []
	GameState.resistance.progress = 0
	GameState.facts.completed_resistance_alley_tiles.assign([])
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(seed_value, day, "closures"))
	city.events.start_day(DaySpec.for_day(day), _rng(seed_value, day, "events"), [],
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

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
