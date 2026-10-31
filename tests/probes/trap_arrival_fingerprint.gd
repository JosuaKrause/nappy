extends RefCounted
## **Every start the resistance director picks for a pursuer it sends at her, printed one line
## each**, so a change to how a start is sited can be shown to pick exactly what it picked before:
## the row, where the badge pointed when it went up, where he was created (exact world point and
## tile), the run log's line for him, and the state of the director's own stream after the draw.
## Not a suite: it prints rather than asserts. Run by name, before and after a change, and compare:
##
##     tools/test.sh probes/trap_arrival_fingerprint.gd > before.txt
##     grep '^TA ' before.txt > before.ta     (and the same for after; `diff` the two)
##
## Per seed and day 6 to 14, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director, handed her view as `main`
## hands it), with a rig player handed to the events and the director:
##
## - **the day's mark and the arrow**: where the mark stands, then, once it is read, the task's
##   contact and where the red arrow points;
## - **the day's own trap**, sent the way the game sends it the moment the task is done
##   (`_set_the_trap_on_her()`, or on day 13 the task guard set on her out of her view,
##   `_set_the_task_guard_on_her()`), her standing at the task, the badge run to its end;
## - **a sweep of starts**: from `SPOTS` walkable tiles spread over the city, a robber sent at her
##   (`_send_at_her()`) as an ordinary task's and as a front door's, the badge run to its end with
##   her stepping `DRIFT` px partway through, so the badge's bearing is asked again from another
##   place.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 77, 90210, 1, 555]
const DAYS: Array[int] = [6, 7, 8, 9, 10, 11, 12, 13, 14]
## How many spread tiles the sweep sends a robber at her from, per seed and day.
const SPOTS := 10
## How far she steps while a sweep's badge is up, in px, and which way.
const DRIFT := Vector2(30.0, 18.0)
const STEP := 1.0 / 60.0

var _lines: Array[String] = []

func run(t) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	var saved_scars := GameState.attempt_spend.scars.duplicate(true)
	var saved_day := GameState.header.day
	var saved_state := GameState.attempt_spend.city_state
	var printed := 0
	for seed_value in SEEDS:
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in DAYS:
			printed += _a_day(t, city, seed_value, day)
		city.free()
	GameState.resistance.completed_steps = saved_completed
	GameState.resistance.progress = saved_progress
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	GameState.attempt_spend.scars = saved_scars
	GameState.header.day = saved_day
	GameState.attempt_spend.city_state = saved_state
	print("TA_TOTAL %d lines" % printed)
	t.check(printed > 0, "there were starts to print (%d)" % printed)

func _a_day(t, city: City, seed_value: int, day: int) -> int:
	var finale := day == Tuning.RUN_LENGTH_DAYS
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if (finale and not step.needs_goal) or (not finale and step.index <= 2 * (day - 6)):
			done.append(step.index)
	GameState.resistance.completed_steps = done
	GameState.resistance.progress = Tuning.RESISTANCE_GOAL if finale else 0
	GameState.facts.completed_resistance_alley_tiles = []
	GameState.attempt_spend.scars.clear()
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
	player.global_position = city.map.doorstep_world_position()
	city.events.use_player(player)
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	_lines.clear()
	director.trace = RunTrace.recording(_lines)
	director.setup(city, city.map)
	director.use_player(player)
	director.set_sight(city.events.sees, city.events.on_screen)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var label := "seed %d day %d" % [seed_value, day]
	var printed := 0
	var offered := director.current_step()
	_print("%s mark %s" % [label, _point(director.contact_position())])
	printed += 1
	if offered and offered.is_pickup:
		director._on_contact_completed(offered.index)
	var task := director.current_step()
	if task == null or task.is_pickup:
		_print("%s no task" % label)
		director.free()
		player.free()
		return printed + 1
	_print("%s task %s contact %s arrow %s" % [label, task.index,
			_point(director.contact_position()), _point(director.red_arrow_target())])
	printed += 1
	var her := director.contact_position()
	if her != Vector2.INF and not city.map.is_walkable(city.map.world_to_tile(her)):
		her += Vector2(0.0, Tuning.TILE_SIZE)
	if her != Vector2.INF:
		_stand(city, player, her)
		_lines.clear()
		if day == 13:
			director._set_the_task_guard_on_her()
		elif ResistanceDirector.sets_a_trap_on_her(task):
			director._set_the_trap_on_her(task)
		printed += _run_out(city, director, player, "%s own trap" % label, Vector2.ZERO)
	var robber := EventCatalogue.by_id("robber_giving_chase")
	for spot in _spots(city):
		for front_door: bool in [false, true]:
			_stand(city, player, spot)
			_lines.clear()
			director._send_at_her(robber, front_door)
			var where := RunTrace.tile(city.map.world_to_tile(spot))
			printed += _run_out(city, director, player, "%s sweep %s%s" % [label, where,
					" front door" if front_door else ""], DRIFT)
	director.free()
	player.free()
	return printed

## Stands her at `at`, the day's view looked through about her as the camera would.
func _stand(city: City, player: Stroller, at: Vector2) -> void:
	player.global_position = at
	city.events.visible_view().look(Rect2(at - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), false)

## Runs every warning up to its end, her stepping `drift` halfway through its time, and prints what
## came of the one the director put up: where it pointed, where he was created, the run log's lines
## and the director's stream. The pursuer is then taken out of the world.
func _run_out(city: City, director: ResistanceDirector, player: Stroller, label: String,
		drift: Vector2) -> int:
	var warnings := city.events.pending_warnings().duplicate()
	if warnings.is_empty():
		_print("%s nothing sent | %s | rng %d" % [label, " / ".join(_lines), director._rng.state])
		return 1
	var warning: PendingWarning = warnings[0]
	var pointed := warning.place
	var her := player.global_position
	var half := warning.left * 0.5
	var shown := 0.0
	var drifted := false
	while not city.events.pending_warnings().is_empty() and shown < 5.0:
		if not drifted and shown >= half and drift != Vector2.ZERO:
			drifted = true
			var stepped := her + drift
			if city.map.is_walkable(city.map.world_to_tile(stepped)):
				her = stepped
				_stand(city, player, her)
		city.events.warnings.run(STEP, her)
		shown += STEP
	var sent: EventInstance = director._trap
	var made := "nobody (withdrawn)" if warning.withdrawn else "nobody"
	if sent != null and is_instance_valid(sent):
		made = "%s at %s %s" % [sent.def.id, _point(sent.global_position),
				RunTrace.tile(city.map.world_to_tile(sent.global_position))]
	_print("%s %s badge %s -> %s | %s | rng %d" % [label, warning.def.id, _point(pointed), made,
			" / ".join(_lines), director._rng.state])
	if sent != null and is_instance_valid(sent):
		city.events.retire(sent)
	director._trap = null
	return 1

## `SPOTS` walkable sidewalk tiles spread evenly over the map's tile order.
func _spots(city: City) -> Array[Vector2]:
	var sidewalk: Array[Vector2i] = []
	for y in city.map.size.y:
		for x in city.map.size.x:
			var tile := Vector2i(x, y)
			if city.map.tile_at(tile) == GameEnums.TileType.SIDEWALK \
					and city.map.is_walkable(tile) and not city.map.is_on_home_block(tile):
				sidewalk.append(tile)
	var spots: Array[Vector2] = []
	if sidewalk.is_empty():
		return spots
	for i in SPOTS:
		spots.append(city.map.tile_to_world(sidewalk[(i * sidewalk.size()) / SPOTS
				+ sidewalk.size() / (SPOTS * 2)]))
	return spots

func _point(at: Vector2) -> String:
	if at == Vector2.INF:
		return "none"
	return "(%s, %s)" % [var_to_str(at.x), var_to_str(at.y)]

func _print(line: String) -> void:
	print("TA " + line)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
