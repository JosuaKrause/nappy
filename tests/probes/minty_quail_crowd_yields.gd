extends RefCounted
## **Where the crowd and the event figures meet**: how often a walker's or a crowd car's body overlaps
## an event figure's, how long crowd cars stand for one, whether a junction stalls, and the crowd's
## own numbers (horns, bumps, strikes, speed), with the events and the crowd both live. Written for
## minty-quail shared-components C2b (the crowd yields to event figures, inbox #884 in
## plaid-raven) and run in each revision's checkout; not a suite, it prints rather than asserts:
##
##     tools/test.sh probes/minty_quail_crowd_yields.gd > out.txt
##     grep '^CROWD_YIELDS_JSON ' out.txt
##
## Per seed, a real city through the real day order (`CityState.begin_day()`, `City.start_day()`,
## `EventManager.start_day()`, the director), the day's crowd started round her, stepped at the 30Hz
## physics tick in the game's order: the events' movers first (`City` adds the event manager before
## the crowd), then the crowd's whole tick (`Crowd._physics_process()`). The runs:
##
## - **rows**, on day 3: a charger (`charging_dog`), a pursuer on foot (`policeman_giving_chase`) and
##   the patrol car at its top heat, which lets officers out (`police_patrol`), each made `OFFSET`
##   px from her at each of `SPOTS` sidewalk spots, she walking away from it, `TICKS` ticks;
## - **day 12's cordon** from the swing's touch, she at the swing, `CORDON_TICKS` ticks;
## - **day 13's column** sent down the main road toward her at the doorstep, `TICKS * 2` ticks.
##
## **An event figure** is a move on the map's list (`WorldMap.moves`) that does not give way
## (`MoveProposal.yields` false) and has a body (`radius` above zero), by the rules the crowd gives
## way by (`SeparationPass`): **for a walker**, one under way (moved in the last
## `SeparationPass.UNDER_WAY_TICKS` ticks) or standing with `stood_round`; **for a car**, one that
## has moved since the probe first saw it, as long as it stands. A step longer than
## `SeparationPass.PLACEMENT_STEP` is a placement and not a move. Every event the probe makes is
## taken out through the game's own paths (`EventInstance.take_out()`), so no finished event stays
## on the list as a figure. A walker overlaps one when their centres are nearer than the two radii
## less half a pixel, a crowd car when the figure's circle reaches into the car's capsule (`GroundShape`'s
## spine and radius along its heading). `most_figures` is the most figures at once (those a walker
## or a car gives way to, together); `walker_overlap_*` count walkers inside the figures a walker
## gives way to, `car_overlap_*` cars inside the figures a car gives way to. Counted per run: overlap entries (a pair coming into
## overlap) and overlap ticks, apart for walkers and cars; the seconds crowd cars stand (speed under
## 1px/s) with a figure ahead in their lane within `AHEAD`px, and the longest such stand; the
## longest a car stood still inside a junction box and how many such stands passed `STALL` seconds;
## horns, bumps and strikes; the mean car speed; the crowd tick's mean cost in microseconds; and a
## SHA-256 chain of every event instance's and cordon officer's pose on every tick, which is the
## same on both revisions when the events keep their courses.
##
## `PROBE_SEEDS` (comma-separated) runs other seeds.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SWEEP := preload("res://tests/test_park_cordon_seeds.gd")
const SEEDS: Array[int] = [4242, 1]
const ROWS: Array[String] = ["charging_dog", "policeman_giving_chase", "police_patrol"]
const SPOTS := 3
const OFFSET := 150.0
const STEP := 1.0 / 30.0
const TICKS := 600
const CORDON_TICKS := 1800
## How far ahead of a crowd car's centre a figure in its lane counts as what it stands for.
const AHEAD := 120.0
## A stand in a junction box longer than this many seconds is counted as a stall.
const STALL := 5.0

var _horns := 0
var _bumps := 0
var _strikes := 0
var _lines := 0

func run(t) -> void:
	var saved_completed := GameState.resistance.completed_steps.duplicate()
	var saved_progress := GameState.resistance.progress
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	var saved_scars := GameState.attempt_spend.scars.duplicate(true)
	var saved_day := GameState.header.day
	var saved_state := GameState.attempt_spend.city_state
	EventBus.car_near_miss.connect(func(_at: Vector2) -> void: _horns += 1)
	EventBus.crowd_bumped.connect(func(_at: Vector2) -> void: _bumps += 1)
	EventBus.hard_fail_triggered.connect(func(cause: String) -> void:
		if cause == "car_strike":
			_strikes += 1)
	for seed_value in _listed("PROBE_SEEDS", SEEDS):
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.crowd_view = ScreenCrowdView.new(t)
		city.build(CityGenerator.generate(seed_value))
		for day: int in [3, 12, 13]:
			_a_day(t, city, seed_value, day)
		city.crowd._player = null
		city.free()
	GameState.resistance.completed_steps = saved_completed
	GameState.resistance.progress = saved_progress
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	GameState.attempt_spend.scars = saved_scars
	GameState.header.day = saved_day
	GameState.attempt_spend.city_state = saved_state
	t.check(_lines > 0, "there were runs to print (%d)" % _lines)

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
	player.set_process(false)
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
	var label := {"seed": seed_value, "day": day}
	if day == 3:
		var spots := _spots(city)
		for id in ROWS:
			var def := EventCatalogue.by_id(id)
			if id == "police_patrol":
				def = EventCatalogue.heated(def, EventCatalogue.heat_levels() - 1)
			for i in spots.size():
				_a_row(city, player, def, spots[i], label.merged({"run": "%s spot %d" % [id, i]}))
	var offered := director.current_step()
	if offered and offered.is_pickup:
		director._on_contact_completed(offered.index)
	var task := director.current_step()
	if day == 12 and task and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		_the_cordon(city, director, player, task, label.merged({"run": "cordon"}))
	if day == ResistanceHappenings.COLUMN_DAY:
		_the_column(city, director, player, label.merged({"run": "column"}))
	director.free()
	player.free()

## One row made `OFFSET` px from her at `spot`, she walking away from it, stepped `TICKS` ticks.
func _a_row(city: City, player: Stroller, def: EventDef, spot: Vector2, label: Dictionary) -> void:
	var her := spot
	_stand(city, player, her)
	var at := her + Vector2(OFFSET, 0.0)
	if not city.map.is_walkable(city.map.world_to_tile(at)):
		at = her + Vector2(0.0, OFFSET)
	var before := city.events.instances().duplicate()
	var meeting := Meeting.new(self, city, label)
	meeting.start_the_crowd(player)
	var made := city.events.spawn_extra(def, at)
	if made == null:
		_take_out(city, before)
		return
	var away := (her - at).normalized()
	for tick in TICKS:
		var next := her + away * Tuning.WALK_SPEED * STEP
		if city.map.is_walkable(city.map.world_to_tile(next)):
			her = next
			_stand(city, player, her)
			player.velocity = away * Tuning.WALK_SPEED
		else:
			player.velocity = Vector2.ZERO
		_tick_events(city)
		meeting.tick_the_crowd()
		meeting.observe(before, [])
	_print(meeting.report())
	_take_out(city, before)

## Day 12's cordon from the swing's touch, she at the swing.
func _the_cordon(city: City, director: ResistanceDirector, player: Stroller,
		task: ResistanceSteps.Step, label: Dictionary) -> void:
	var swing := director.contact_position()
	director._on_contact_completed(task.index)
	var happenings: ResistanceHappenings = director._happenings
	var her := [swing]
	var shows: Callable = SWEEP.new().call("_camera_on", her)
	_stand(city, player, swing)
	happenings.tick(STEP, swing, Vector2.ZERO, shows)
	var park := happenings.cordon.park
	happenings.cordon.clear()
	var before := city.events.instances().duplicate()
	var meeting := Meeting.new(self, city, label)
	meeting.start_the_crowd(player)
	var cordon := ParkCordon.new(city.map, city.navigator, city, park, director._reach_blocked)
	for tick in CORDON_TICKS:
		_tick_events(city)
		cordon.tick(STEP, swing, shows)
		meeting.tick_the_crowd()
		meeting.observe(before, cordon.officers)
	_print(meeting.report())
	cordon.clear()
	_take_out(city, before)

## Day 13's column sent down the main road toward her at the doorstep.
func _the_column(city: City, director: ResistanceDirector, player: Stroller,
		label: Dictionary) -> void:
	var her := city.map.doorstep_world_position()
	_stand(city, player, her)
	var before := city.events.instances().duplicate()
	var meeting := Meeting.new(self, city, label)
	meeting.start_the_crowd(player)
	var happenings: ResistanceHappenings = director._happenings
	if happenings.send_the_column(her) == null:
		_take_out(city, before)
		return
	for tick in TICKS * 2:
		city.events.warnings.run(STEP, her)
		_tick_events(city)
		meeting.tick_the_crowd()
		meeting.observe(before, [])
	_print(meeting.report())
	_take_out(city, before)

## The movers' half of the event manager's tick, without the streaming and the siting, so only what
## the probe made moves.
func _tick_events(city: City) -> void:
	var events := city.events
	events._tell_them_where_she_is()
	events._step_them(STEP)
	events.ahead.let_the_officers_out()
	events.streaming.retire_finished()

func _take_out(city: City, before: Array) -> void:
	for instance in city.events.instances().duplicate():
		if not before.has(instance) and is_instance_valid(instance):
			city.events.retire(instance)
	city.events.streaming.retire_finished()

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

func _print(line: Dictionary) -> void:
	_lines += 1
	print("CROWD_YIELDS_JSON " + JSON.stringify(line))

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## One run: the crowd started round her, its tick, and what is counted on every tick. Also what
## `minty_quail_crowd_cadence.gd` counts the figures with when it runs the day's events, handed no
## probe, so it reports the figures' counts alone.
class Meeting extends RefCounted:
	var _probe
	var _city: City
	var _label: Dictionary
	## Every figure seen, by move: its last pose and how many ticks in a row it has stood still.
	var _seen := {}
	var _overlapping := {}
	var _walker_entries := 0
	var _walker_ticks := 0
	var _car_entries := 0
	var _car_ticks := 0
	var _figure_stand_ticks := 0
	var _figure_stand_run := {}
	var _longest_figure_stand := 0
	var _standing_ticks := 0
	var _box_run := {}
	var _longest_box_stand := 0
	var _stalls := 0
	var _speeds := 0.0
	var _speed_samples := 0
	var _ticks := 0
	var _crowd_usec := 0
	var _most_figures := 0
	var _chain := HashingContext.new()
	var _horns := 0
	var _bumps := 0
	var _strikes := 0

	func _init(probe, city: City, label: Dictionary) -> void:
		_probe = probe
		_city = city
		_label = label
		_chain.start(HashingContext.HASH_SHA256)
		if probe != null:
			_horns = probe._horns
			_bumps = probe._bumps
			_strikes = probe._strikes

	## Starts the day's crowd round her, from a seed of the run's own label.
	func start_the_crowd(player: Stroller) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("crowd-yields:%s" % JSON.stringify(_label))
		_city.crowd.start_day(int(_label.day), rng, player.global_position)
		_city.crowd.set_gates(_city.region_plan().gates)
		_city.crowd._player = player

	func tick_the_crowd() -> void:
		var started := Time.get_ticks_usec()
		_city.crowd._physics_process(STEP)
		_crowd_usec += Time.get_ticks_usec() - started

	## Counts this tick: `before` is the instances standing before the run began, `officers` the
	## cordon's.
	func observe(before: Array, officers: Array) -> void:
		_ticks += 1
		var line := "%d" % _ticks
		for instance in _city.events.instances():
			if before.has(instance) or not is_instance_valid(instance):
				continue
			line += "|%s:%s,%s,%d" % [instance.def.id, var_to_str(instance.position.x),
					var_to_str(instance.position.y), instance.phase]
		for officer in officers:
			line += "|o:%s,%s,%d" % [var_to_str(officer.at.x), var_to_str(officer.at.y),
					officer.phase]
		_chain.update(line.to_utf8_buffer())
		# The two lists of figures `SeparationPass` keeps (`SeparationPass.gather()`), by the same
		# rules: walkers give way to one under way or standing round, cars to one that has moved.
		var for_walkers: Array[MoveProposal] = []
		var for_cars: Array[MoveProposal] = []
		for move in _city.map.moves.keeping_their_course():
			if move.radius <= 0.0:
				continue
			var seen: Array = _seen.get(move, [move.to, SeparationPass.NEVER_MOVED])
			var still: int = seen[1]
			var step: float = move.to.distance_to(seen[0])
			if step > SeparationPass.PLACEMENT_STEP:
				step = 0.0
			if step > 0.0:
				still = 0
			elif still < SeparationPass.NEVER_MOVED:
				still += 1
			_seen[move] = [move.to, still]
			if still <= SeparationPass.UNDER_WAY_TICKS or move.stood_round:
				for_walkers.append(move)
			if still != SeparationPass.NEVER_MOVED:
				for_cars.append(move)
		var figures := for_walkers.duplicate()
		for move in for_cars:
			if not figures.has(move):
				figures.append(move)
		_most_figures = maxi(_most_figures, figures.size())
		var now := {}
		for agent in _city.crowd.agents():
			var is_car := agent.kind == CrowdAgent.Kind.CAR
			var here := agent.global_position
			var forward := agent.heading()
			var side := Vector2(-forward.y, forward.x)
			var standing := is_car and agent.speed() < 1.0
			var for_a_figure := false
			for figure in (for_cars if is_car else for_walkers):
				var offset := figure.to - here
				if offset.length() > 200.0:
					continue
				var overlaps := false
				if is_car:
					var spine := clampf(offset.dot(forward), -agent.shape.half_length,
							agent.shape.half_length)
					overlaps = (offset - forward * spine).length() \
							< agent.shape.radius + figure.radius - 0.5
					var along := offset.dot(forward)
					if standing and along > 0.0 and along < AHEAD \
							and absf(offset.dot(side)) < agent.shape.radius + figure.radius + 4.0:
						for_a_figure = true
				else:
					overlaps = offset.length() < agent.shape.reach() + figure.radius - 0.5
				if not overlaps:
					continue
				var key := [agent, figure]
				now[key] = true
				if is_car:
					_car_ticks += 1
				else:
					_walker_ticks += 1
				if not _overlapping.has(key):
					if is_car:
						_car_entries += 1
					else:
						_walker_entries += 1
			if not is_car:
				continue
			_speeds += agent.speed()
			_speed_samples += 1
			if standing:
				_standing_ticks += 1
			if for_a_figure:
				_figure_stand_ticks += 1
				_figure_stand_run[agent] = int(_figure_stand_run.get(agent, 0)) + 1
				_longest_figure_stand = maxi(_longest_figure_stand, _figure_stand_run[agent])
			else:
				_figure_stand_run.erase(agent)
			if standing and agent.junction_occupied() != Vector2i(-1, -1):
				var run := int(_box_run.get(agent, 0)) + 1
				_box_run[agent] = run
				_longest_box_stand = maxi(_longest_box_stand, run)
				if run == int(STALL / STEP):
					_stalls += 1
			else:
				_box_run.erase(agent)
		_overlapping = now

	func report() -> Dictionary:
		var minutes := float(_ticks) * STEP / 60.0
		var counts := {}
		if _probe != null:
			counts = {"horns": _probe._horns - _horns, "bumps": _probe._bumps - _bumps,
				"strikes": _probe._strikes - _strikes,
				"mean_car_speed": _speeds / maxf(1.0, float(_speed_samples)),
				"crowd_tick_usec": float(_crowd_usec) / maxf(1.0, float(_ticks))}
		return _label.merged(counts).merged({"ticks": _ticks, "most_figures": _most_figures,
			"walker_overlap_entries": _walker_entries,
			"walker_overlap_per_minute": float(_walker_entries) / minutes,
			"walker_overlap_seconds": float(_walker_ticks) * STEP,
			"car_overlap_entries": _car_entries,
			"car_overlap_per_minute": float(_car_entries) / minutes,
			"car_overlap_seconds": float(_car_ticks) * STEP,
			"car_seconds_standing_for_figures": float(_figure_stand_ticks) * STEP,
			"longest_stand_for_a_figure": float(_longest_figure_stand) * STEP,
			"car_seconds_standing": float(_standing_ticks) * STEP,
			"longest_box_stand": float(_longest_box_stand) * STEP,
			"box_stalls": _stalls,
			"events_chain": _chain.finish().hex_encode()})
