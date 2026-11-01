extends RefCounted
## **When every pursuer catches her or gives up, and when every departure ends, tick by tick**, so a
## change to how a mover's step is proposed, checked and committed (minty-quail shared-components
## C2a) can be shown to change none of it. Not a suite: it prints rather than asserts. Run by name in
## each revision's checkout and compare the `PURSUIT_TIMING` lines:
##
##     tools/test.sh probes/minty_quail_pursuit_timing.gd > before.txt
##     grep '^PURSUIT_TIMING ' before.txt > before.pt     (the same for after; `cmp` the two)
##
## Per seed and day, a real city through the real day order (`CityState.begin_day()`,
## `City.start_day()`, `EventManager.start_day()`, then the director), with a rig player handed to
## the events and the director, stepped at the 30Hz physics tick the way the event manager's tick
## runs its movers (`_tell_them_where_she_is()`, `_step_them()`, `let_the_officers_out()`,
## `retire_finished()`):
##
## - **rows**, on `ROW_DAYS`: a charger (`charging_dog`), the alley robber (`alley_robbery`), a
##   pursuer on foot (`policeman_giving_chase`) and the patrol car at its top heat, which lets police
##   officers out (`police_patrol`), each made `OFFSET` px from her at each of `SPOTS` spread
##   sidewalk spots, with her standing still, walking away from it and running away from it (every
##   instance told she runs, so a chase can be shaken off);
## - **the day's own trap** from day 6 on, sent the way the game sends it the moment the task is done
##   (on day 13 the task guard, already in the world, set on her; every pursuer standing in the
##   world is followed in that run);
## - **day 12's cordon**, a busker standing in the park, with her standing at the swing: every
##   officer's position and phase each tick, when the busker's departure ends and when the last gap
##   closes;
## - **day 13's column** sent down the main road toward her: the trucks' poses, parks and ends.
##
## For each run, one line: every instance that came into the world during it, by id, with the tick
## it first could end her day where she stood (`is_lethal_at()`), the tick it gave up, the tick it
## began leaving and the tick it finished, and a SHA-256 chain of every tracked mover's exact pose on
## every tick. `PROBE_SEEDS` and `PROBE_DAYS` (comma-separated) run other seeds or days;
## `PROBE_NO_ROWS` set skips the rows.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 1]
const DAYS: Array[int] = [3, 6, 7, 8, 11, 12, 13]
## The days the rows are made on.
const ROW_DAYS: Array[int] = [3, 12]
const ROWS: Array[String] = ["charging_dog", "alley_robbery", "policeman_giving_chase",
		"police_patrol"]
const SPOTS := 3
const OFFSET := 150.0
const STEP := 1.0 / 30.0
const TICKS := 600
const CORDON_TICKS := 3600

var _lines := 0
var _trace: Array[String] = []
## Whether she is running in the run under way: every instance is told so each tick.
var _running := false

func run(t) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	var saved_scars := GameState.attempt_spend.scars.duplicate(true)
	var saved_day := GameState.header.day
	var saved_state := GameState.attempt_spend.city_state
	for seed_value in _listed("PROBE_SEEDS", SEEDS):
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in _listed("PROBE_DAYS", DAYS):
			_a_day(t, city, seed_value, day)
		city.free()
	GameState.resistance.completed_steps = saved_completed
	GameState.resistance.progress = saved_progress
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	GameState.attempt_spend.scars = saved_scars
	GameState.header.day = saved_day
	GameState.attempt_spend.city_state = saved_state
	print("PURSUIT_TIMING_TOTAL %d lines" % _lines)
	t.check(_lines > 0, "there were runs to print (%d)" % _lines)

## `fallback`, or the comma-separated numbers the environment variable `name` lists.
func _listed(name: String, fallback: Array[int]) -> Array[int]:
	if OS.get_environment(name) == "":
		return fallback
	var listed: Array[int] = []
	for part in OS.get_environment(name).split(","):
		listed.append(int(part))
	return listed

func _a_day(t, city: City, seed_value: int, day: int) -> void:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.index <= 2 * (day - 6):
			done.append(step.index)
	GameState.resistance.completed_steps = done
	GameState.resistance.progress = 0
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
	director.setup(city, city.map)
	director.use_player(player)
	director.set_sight(city.events.sees)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var label := "seed %d day %d" % [seed_value, day]
	_trace.clear()
	director.trace = RunTrace.recording(_trace)
	var spots: Array[Vector2] = []
	if OS.get_environment("PROBE_NO_ROWS") == "" and ROW_DAYS.has(day):
		spots = _spots(city)
	for id in ROWS:
		var def := EventCatalogue.by_id(id)
		if id == "police_patrol":
			def = EventCatalogue.heated(def, EventCatalogue.heat_levels() - 1)
		for i in spots.size():
			for mode: String in ["stands", "walks away", "runs away"]:
				_a_row(city, player, def, spots[i], mode, "%s row %s spot %d %s" % [label, id, i,
						mode])
	var offered := director.current_step()
	if offered and offered.is_pickup:
		director._on_contact_completed(offered.index)
	var task := director.current_step()
	if task and day == ResistanceSteps.swing_day() \
			and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		_the_cordon(city, director, player, task, label)
	elif task and not task.is_pickup and day >= 6:
		_the_trap(city, director, player, task, day, label)
	if day == ResistanceHappenings.COLUMN_DAY:
		_the_column(city, director, player, label)
	director.free()
	player.free()

## One row made `OFFSET` px from her at `spot`, she standing, walking away from it or running away
## from it (`mode`), stepped `TICKS` ticks; then everything that came into the world is taken out
## of it.
func _a_row(city: City, player: Stroller, def: EventDef, spot: Vector2, mode: String,
		label: String) -> void:
	var her := spot
	_stand(city, player, her)
	var at := her + Vector2(OFFSET, 0.0)
	if not city.map.is_walkable(city.map.world_to_tile(at)):
		at = her + Vector2(0.0, OFFSET)
	var before := city.events.instances().duplicate()
	var made := city.events.spawn_extra(def, at)
	if made == null:
		_print("%s not made" % label)
		return
	var away := (her - at).normalized()
	var speed := 0.0 if mode == "stands" else Tuning.WALK_SPEED if mode == "walks away" \
			else Tuning.RUN_SPEED
	_running = mode == "runs away"
	var run := Run.new(before)
	for tick in TICKS:
		if speed > 0.0:
			var next := her + away * speed * STEP
			if city.map.is_walkable(city.map.world_to_tile(next)):
				her = next
				_stand(city, player, her)
		_tick(city)
		run.observe(city, her, tick)
	_running = false
	_print("%s %s" % [label, run.report()])
	_take_out(city, before)

## The day's own trap, sent the way the game sends it the moment the task is done, her standing at
## the task, stepped until the warning has run and `TICKS` ticks after.
func _the_trap(city: City, director: ResistanceDirector, player: Stroller,
		task: ResistanceSteps.Step, day: int, label: String) -> void:
	var her := director.contact_position()
	if her == Vector2.INF:
		_print("%s trap no contact" % label)
		return
	if not city.map.is_walkable(city.map.world_to_tile(her)):
		her += Vector2(0.0, Tuning.TILE_SIZE)
	_stand(city, player, her)
	var before := city.events.instances().duplicate()
	if day == 13:
		director._set_the_task_guard_on_her()
	elif ResistanceDirector.sets_a_trap_on_her(task):
		director._set_the_trap_on_her(task)
	else:
		_print("%s trap none" % label)
		return
	var sent := city.events.pending_warnings().size()
	# Day 13's task guard is in the world already when he is set on her: followed with what comes.
	var known: Array = []
	for instance in before:
		if is_instance_valid(instance) and instance.def.pursuit == null:
			known.append(instance)
	var run := Run.new(known)
	for tick in TICKS + 300:
		city.events.warnings.run(STEP, her)
		_tick(city)
		run.observe(city, her, tick)
	_print("%s trap warnings %d %s | %s" % [label, sent, run.report(), " / ".join(_trace)])
	_take_out(city, before)

## Day 12's cordon from the swing's touch, a busker standing in the park (the cordon suite's own
## spot), her at the swing: the officers' poses and phases, and the busker's, every tick.
func _the_cordon(city: City, director: ResistanceDirector, player: Stroller,
		task: ResistanceSteps.Step, label: String) -> void:
	var swing := director.contact_position()
	director._on_contact_completed(task.index)
	var happenings: ResistanceHappenings = director._happenings
	var her := [swing]
	var camera := Rect2(swing - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	_stand(city, player, swing)
	city.events.visible_view().look(camera, null)
	happenings.tick(STEP, swing, Vector2.ZERO)
	var park := happenings.cordon.park
	happenings.cordon.clear()
	var area := city.map.tile_rect_to_world(ClosurePlanner.calm_area_rect(city.map, park))
	var before := city.events.instances().duplicate()
	var busker := city.events.spawn_extra(EventCatalogue.by_id("busker"),
			area.position + area.size * Vector2(0.25, 0.3))
	var cordon := ParkCordon.new(city.map, city.navigator, city, park, city.spawn_siting,
			director._reach_blocked)
	var run := Run.new(before)
	var chain := HashingContext.new()
	chain.start(HashingContext.HASH_SHA256)
	for tick in CORDON_TICKS:
		_tick(city)
		city.events.visible_view().look(camera, null)
		cordon.tick(STEP, swing)
		run.observe(city, swing, tick)
		var line := "%d" % tick
		for officer in cordon.officers:
			line += "|%s,%s,%d" % [var_to_str(officer.at.x), var_to_str(officer.at.y),
					officer.phase]
		chain.update(line.to_utf8_buffer())
		if cordon.is_closed() and (busker == null or not is_instance_valid(busker)
				or busker.is_finished):
			break
	_print("%s cordon busker %s closed %s officers %d relaid %d straight %d chain %s %s" % [label,
			"placed" if busker else "none", var_to_str(cordon.closed_at), cordon.officers.size(),
			cordon.relaid, cordon.walked_straight, chain.finish().hex_encode(), run.report()])
	cordon.clear()
	_take_out(city, before)

## Day 13's column sent down the main road toward her at the doorstep.
func _the_column(city: City, director: ResistanceDirector, player: Stroller,
		label: String) -> void:
	var her := city.map.doorstep_world_position()
	_stand(city, player, her)
	var before := city.events.instances().duplicate()
	var happenings: ResistanceHappenings = director._happenings
	if happenings.send_the_column(her) == null:
		_print("%s column none" % label)
		return
	var run := Run.new(before)
	for tick in TICKS * 2:
		city.events.warnings.run(STEP, her)
		_tick(city)
		run.observe(city, her, tick)
	_print("%s column trucks %d %s" % [label, happenings.column.size(), run.report()])
	_take_out(city, before)

## The movers' half of the event manager's tick (`EventManager._tick_the_events()`), without the
## streaming and the siting, so only what the probe made moves.
func _tick(city: City) -> void:
	var events := city.events
	events._tell_them_where_she_is()
	if _running:
		for instance in events.instances():
			instance.player_running = true
	events._step_them(STEP)
	events.ahead.let_the_officers_out()
	events.streaming.retire_finished()

func _take_out(city: City, before: Array) -> void:
	for instance in city.events.instances().duplicate():
		if not before.has(instance) and is_instance_valid(instance):
			city.events.retire(instance)
	city.events.streaming.retire_finished()

## Stands her at `at`, the day's view looked through about her as the camera would.
func _stand(city: City, player: Stroller, at: Vector2) -> void:
	player.global_position = at
	city.events.visible_view().look(Rect2(at - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), null)

## `SPOTS` walkable sidewalk tiles spread evenly over the map's tile order, off the home block.
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

func _print(line: String) -> void:
	_lines += 1
	print("PURSUIT_TIMING " + line)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## One run's record: every instance that came into the world after `before`, in the order first
## seen, with its moments, and the chain of every pose.
class Run extends RefCounted:
	var _before: Array
	var _seen: Array[EventInstance] = []
	var _ids: Array[String] = []
	var _moments: Array[Dictionary] = []
	var _chain := HashingContext.new()

	func _init(before: Array) -> void:
		_before = before
		_chain.start(HashingContext.HASH_SHA256)

	func observe(city: City, her: Vector2, tick: int) -> void:
		for instance in city.events.instances():
			if _before.has(instance) or _seen.has(instance):
				continue
			_seen.append(instance)
			_ids.append(instance.def.id)
			_moments.append({"made": tick, "lethal": -1, "gave_up": -1, "leaving": -1,
					"finished": -1})
		var line := "%d" % tick
		for i in _seen.size():
			var instance := _seen[i]
			var moments := _moments[i]
			if not is_instance_valid(instance) or instance.is_queued_for_deletion():
				if moments.finished < 0:
					moments.finished = tick
				continue
			if moments.lethal < 0 and instance.is_lethal_at(her):
				moments.lethal = tick
			if moments.gave_up < 0 and instance.gave_up:
				moments.gave_up = tick
			if moments.leaving < 0 and instance.is_leaving:
				moments.leaving = tick
			if moments.finished < 0 and instance.is_finished:
				moments.finished = tick
			line += "|%d:%s,%s,%s,%s,%s,%d,%d" % [i, var_to_str(instance.position.x),
					var_to_str(instance.position.y), var_to_str(instance._heading.x),
					var_to_str(instance._heading.y), var_to_str(instance._path_travelled),
					instance.phase, 1 if instance.is_parked else 0]
		_chain.update(line.to_utf8_buffer())

	func report() -> String:
		var parts: Array[String] = []
		for i in _seen.size():
			var m := _moments[i]
			parts.append("%s[made %d lethal %d gave_up %d leaving %d finished %d]" % [_ids[i],
					m.made, m.lethal, m.gave_up, m.leaving, m.finished])
		return "movers %s chain %s" % [" ".join(parts), _chain.finish().hex_encode()]
