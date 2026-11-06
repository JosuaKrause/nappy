extends "res://tests/test_day13_guard.gd"
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
## where she touched, or with her walking away from it), built with `tests/test_day13_guard.gd`'s
## helpers, which this file extends, and per 60 Hz tick his position, his heading and the tile the
## red arrow points at (`ResistanceDirector.red_arrow_target()`). The arrow: on each of `ARROW_DAYS`
## that a task several places answer is on offer, on each of `ARROW_SEEDS`, with her handed to the
## director, the tile the arrow points at with her at each of `POSITIONS` spread over the city, after
## every sweep has finished, how many tiles closer on foot the closest target is than that one
## (`_arrow_lead_at()`), and the tile of the closest (`_arrow_nearest_at()`). Every city stands in a
## run of its own.

const PROBE := preload("res://tests/probes/velvet_stork_guard_path_cost.gd")
const GUARD_SEEDS: Array[int] = [4242, 90210, 555]
const ARROW_SEEDS: Array[int] = [4242, 90210]
const ARROW_DAYS: Array[int] = [6, 11, 13]
const POSITIONS := 12
const FRAME := 1.0 / 60.0
const CHASE_SECONDS := 31.8

func run(t) -> void:
	t.gives_back_observers()
	for seed_value in GUARD_SEEDS:
		for walks in [false, true]:
			_the_guard(t, seed_value, walks)
	for day in ARROW_DAYS:
		for seed_value in ARROW_SEEDS:
			_the_arrow(t, day, seed_value)

func _the_guard(t, seed_value: int, walks: bool) -> void:
	var city := _build_city(t, seed_value)
	var director := _start_the_day(t, city, seed_value)
	var player := _rig_player(t, director, director.contact_position())
	var label := "D2_PARITY guard seed %d %s" % [seed_value, "walking" if walks else "standing"]
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var step := director.current_step()
	var guard := _task_guard()
	var touched: EventInstance = null
	if step and guard:
		var held := guard.global_position
		_view = Rect2(held - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
		_settle_the_arrow(director)
		touched = _her_way_to_another_roadblock(director, player, director.rider())
	if touched == null:
		print("%s: no other live roadblock to touch" % label)
		_finish(player, director, city)
		return
	_choose_again(director)
	var map := city.map
	var at := _beside(map, touched.body_position(), ContactPoint.body_reach(touched))
	player.global_position = at
	director.contact().complete_now()
	var route := PROBE.walk_away_from(map, at) if walks else PackedVector2Array()
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
				guard.facing_now().y, _arrow_tile(director, map)])
		tick += 1
		if guard.is_lethal_at(her) or guard.global_position.distance_to(her) <= standoff + 1.0:
			break
	print("%s: %d ticks" % [label, tick])
	_finish(player, director, city)

func _finish(player: Stroller, director: ResistanceDirector, city: City) -> void:
	_tear_down(player, director, city)
	_view = Rect2()

## The tile the red arrow points at, or (-1, -1) while it points at nothing.
static func _arrow_tile(director: ResistanceDirector, map: CityMap) -> Vector2i:
	var at := director.red_arrow_target()
	return Vector2i(-1, -1) if at == Vector2.INF else map.world_to_tile(at)

func _the_arrow(t, day: int, seed_value: int) -> void:
	var city := _build_city(t, seed_value)
	var director := _read_the_mark(t, city, day, seed_value)
	var player := _rig_player(t, director, director.contact_position())
	var label := "D2_PARITY arrow day %d seed %d" % [day, seed_value]
	var step := director.current_step()
	if step == null or step.is_pickup:
		print("%s: no task on offer" % label)
	else:
		var found := _arrow_targets(director)
		print("%s: %d targets" % [label, found.size()])
		var index := 0
		for at in _positions(city, director):
			player.global_position = at
			_settle_the_arrow(director)
			print("%s position %d (%.1f, %.1f): arrow tile %s, lead %d, nearest tile %s" % [label,
					index, at.x, at.y, _arrow_tile(director, city.map),
					_arrow_lead_at(director, city.map.world_to_tile(at)),
					_nearest_tile(director, city.map, found, at)])
			index += 1
	_tear_down(player, director, city)

## The tile of the target the field of every target says is closest to `at`, from `found`.
static func _nearest_tile(director: ResistanceDirector, map: CityMap, found: Array[Dictionary],
		at: Vector2) -> Vector2i:
	var key: Variant = _arrow_nearest_at(director, map.world_to_tile(at))
	for target in found:
		if key != null and _same_key(target["key"], key):
			return map.world_to_tile(target["at"])
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
	var run: RunState = city.run
	run.resistance.completed_steps = done
	var state := CityState.new()
	run.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _day_rng(seed_value, day, "closures"))
	city.events.start_day(DaySpec.for_day(day), _day_rng(seed_value, day, "events"), [],
			city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(day, _day_rng(seed_value, day, "resistance"), 300.0)
	var mark := director.current_step()
	if mark != null and mark.is_pickup:
		director.contact().complete_now()
	return director

## The stream of `day` on `seed_value`, named as the probes name them (no suite prefix).
func _day_rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## `ResistanceDirector`'s places that answer today's task, as the arrow chooses among them
## (`_arrow_candidates()`): empty with no step on offer or one a single place answers. The probe
## reads the director's private state, which the director offers no query of.
static func _arrow_targets(director: ResistanceDirector) -> Array[Dictionary]:
	var step := director.current_step()
	if step == null or not ResistanceSteps.answers_at_several_places(step):
		var none: Array[Dictionary] = []
		return none
	return director._arrow_candidates(step)

## The key of the target closest on foot from `tile` in the director's finished sweep of every
## target, or null (`ResistanceDirector._arrow_nearest`, which the director offers no query of).
static func _arrow_nearest_at(director: ResistanceDirector, tile: Vector2i) -> Variant:
	return director._arrow_nearest.nearest_at(tile) if director._arrow_nearest else null

## How many tiles closer on foot from `tile` the closest target is than the one the arrow points
## at, or -1 while either sweep is unfinished (`ResistanceDirector._arrow_nearest`, `_arrow_own`).
static func _arrow_lead_at(director: ResistanceDirector, tile: Vector2i) -> int:
	if not director._arrow_nearest or not director._arrow_own:
		return -1
	var to_nearest: int = director._arrow_nearest.length_at(tile)
	var to_own: int = director._arrow_own.length_at(tile)
	return to_own - to_nearest if to_nearest >= 0 and to_own >= 0 else -1
