extends RefCounted
## **Every placement entry point of the resistance and the events' director half, printed one line
## each**, so a change to the rules they ask can be shown to pick exactly what they picked before:
## the pick (row, tile, world point, heading where there is one) and the state of the stream the
## pick drew from. Not a suite: it prints rather than asserts. Run by name, before and after a
## change, and compare:
##
##     tools/test.sh probes/director_placement_fingerprint.gd > before.txt
##     grep '^DP ' before.txt > before.dp     (and the same for after; `diff` the two)
##
## With `trap_arrival_fingerprint.gd` (the pursuers the director sends) and
## `placement_fingerprint.gd` (the day's own plan) this covers everything placement does. Per seed
## and day 1 to 14, a real city through the real day order, and:
##
## - **the director's contact placements**: the day's mark and its guard, the task's contact and
##   its guard (a door, a swing, a mast, a roadblock, the neighbor), each placed again from a
##   fresh stream (`_place()`, so `_pick_reachable()` and `_pick_near()`), and the guard spots
##   asked directly from a few places she may stand (`_guard_position()`,
##   `_roadblock_guard_spot()`), with and without her screen counted;
## - **the relocation and the extras**: `_nearest_alley_within()`, `_nearest_to_the_mark()`,
##   `_door_can_be_touched()`, the neighbor's start (`_send_the_neighbor_home()`), the mast added
##   near the mark (`_add_a_mast_near()`) and day 13's roadblock placed near it
##   (`_place_the_roadblock_near()`);
## - **the happenings**: day 10's raid, refused with her view on a van and let through off it, and
##   day 13's column sent at her from a few places along the main road;
## - **the events' director half**: where a row comes down her line (`down_her_line()`, the
##   cyclist and the loose dog), along her heading (`along_her_heading()`, the charging dog), on
##   its route (`on_its_route()`, the fire engine to the kerb `where_the_summoned_row_stops()`
##   gives), in its lane (`in_its_lane()`, the column), and where the men a hunting van owes get out
##   (`let_the_officers_out()`).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 77, 90210]
const DAYS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
## How many spread tiles the sweeps stand her on, per seed and day.
const SPOTS := 4
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
	print("DP_TOTAL %d lines" % printed)
	t.check(printed > 0, "there were placements to print (%d)" % printed)

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
	director.set_sight(city.events.sees)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var label := "seed %d day %d" % [seed_value, day]
	var printed := 0
	var doorstep := city.map.doorstep_world_position()
	_stand(city, player, doorstep)
	# The events' director half and the happenings, on the day's own morning.
	printed += _the_events_ahead(city, player, label)
	if day == 10:
		printed += _the_raid(city, director, player, label)
	if day == 13:
		printed += _the_column(city, director, player, label)
	_stand(city, player, doorstep)
	# The mark and its guard.
	var offered := director.current_step()
	_print("%s mark %s guard %s" % [label, _point(director.contact_position()),
			_guard_at(director._guard)])
	printed += 1
	var mark := director.contact_position()
	if offered and offered.is_pickup and mark != Vector2.INF:
		printed += _the_guard_spots(city, director, label, mark, true, doorstep)
		printed += _the_relocation(city, director, player, label, mark)
		director._on_contact_completed(offered.index)
	var task := director.current_step()
	if task == null or task.is_pickup:
		_print("%s no task" % label)
		director.free()
		player.free()
		return printed + 1
	var contact := director.contact_position()
	_print("%s task %s contact %s guard %s mast %s arrow %s" % [label, task.index, _point(contact),
			_guard_at(director._task_guard), director._mast_id,
			_point(director.red_arrow_target())])
	printed += 1
	# The task placed again from a fresh stream, as the day's order draws it.
	var again := _rng(seed_value, day, "placed-again")
	var placed := director._place(task, again, mark)
	_print("%s task %s placed again %s rng %d fell back %s" % [label, task.index,
			_point(placed), again.state, director._fell_back])
	printed += 1
	if contact != Vector2.INF:
		printed += _the_guard_spots(city, director, label, contact, false, doorstep)
		printed += _the_extras(city, director, player, label, task, contact, mark, seed_value, day)
	director.free()
	player.free()
	return printed

## The guard spots asked directly, her standing nowhere, at the doorstep and on the contact, with
## her screen counted and not.
func _the_guard_spots(city: City, director: ResistanceDirector, label: String, at: Vector2,
		for_mark: bool, doorstep: Vector2) -> int:
	var printed := 0
	var hers: Array[Vector2] = [Vector2.INF, doorstep, at]
	for her in hers:
		for on_screen in [false, true]:
			var rng := _rng(0, 0, "guard-spot")
			if on_screen and her != Vector2.INF:
				city.events.visible_view().look(Rect2(her - Tuning.VIEW_HALF_EXTENT,
						Tuning.VIEW_HALF_EXTENT * 2.0), null)
			var spot := director._guard_position(rng, at, for_mark, her, on_screen)
			_print("%s %s guard spot her %s screen %s -> %s rng %d" % [label,
					"mark" if for_mark else "roadblock", _point(her), on_screen, _point(spot),
					rng.state])
			printed += 1
	if not for_mark:
		for her in hers:
			var rng := _rng(0, 0, "roadblock-spot")
			var moved := director._roadblock_guard_spot(rng, at, ContactPoint.REACH, her, false,
					false)
			_print("%s roadblock spot no-any her %s -> %s rng %d" % [label, _point(her),
					_point(moved), rng.state])
			printed += 1
	return printed

## The relocation search from a few places she may stand, her view on her.
func _the_relocation(city: City, director: ResistanceDirector, player: Stroller, label: String,
		mark: Vector2) -> int:
	var printed := 0
	var spots := _spots(city)
	for spot in spots:
		_stand(city, player, spot)
		var found := director._nearest_alley_within(spot)
		_print("%s relocation from %s -> %s" % [label, _point(spot), _point(found)])
		printed += 1
	_stand(city, player, mark)
	return printed

## The extras: the nearest-to-the-mark fallback, the door's touch, the neighbor, the mast added
## and the roadblock placed near the mark. Last, since the last two join the day's plan.
func _the_extras(city: City, director: ResistanceDirector, player: Stroller, label: String,
		task: ResistanceSteps.Step, contact: Vector2, mark: Vector2, seed_value: int,
		day: int) -> int:
	var printed := 0
	var sidewalk := city.map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	_stand(city, player, mark if mark != Vector2.INF else contact)
	_print("%s nearest to the mark %s" % [label, _point(director._nearest_to_the_mark(sidewalk,
			contact))])
	printed += 1
	_print("%s door touched %s" % [label, director._door_can_be_touched(contact)])
	printed += 1
	if day >= 6:
		var neighbor := director._send_the_neighbor_home()
		if neighbor != null:
			_print("%s neighbor starts at %s rng %d" % [label,
					_point(neighbor.global_position), director._rng.state])
			city.events.retire(neighbor)
		else:
			_print("%s neighbor starts nowhere rng %d" % [label, director._rng.state])
		printed += 1
		var mast_rng := _rng(seed_value, day, "mast-near")
		director._follow_the_paths_to_the_edge(director._where_she_read_it(contact))
		var added := director._add_a_mast_near(contact, mast_rng)
		_print("%s mast near %s rng %d" % [label, added, mast_rng.state])
		printed += 1
		var roadblock := director._place_the_roadblock_near(contact)
		_print("%s roadblock near %s rng %d" % [label, _point(roadblock.global_position)
				if roadblock else "none", director._rng.state])
		printed += 1
	return printed

## Day 10's raid: her far from her door, her view on the first van (refused) and then elsewhere
## (let through).
func _the_raid(city: City, director: ResistanceDirector, player: Stroller, label: String) -> int:
	var happenings := director._happenings
	var vans := happenings._raid_vans
	var beat := happenings._raid_beat
	_print("%s raid plans vans %s beat %s" % [label, vans, beat])
	var far := city.map.tile_to_world(Vector2i(city.map.size.x - 4, 3))
	var printed := 1
	# Her far from her door, her screen on what the raid would put down.
	for focus: Vector2 in [vans[0] if not vans.is_empty() else far,
			vans[vans.size() - 1] if not vans.is_empty() else far,
			beat[0] if not beat.is_empty() else far,
			beat[beat.size() - 1] if not beat.is_empty() else far]:
		_stand(city, player, far)
		city.events.visible_view().look(Rect2(focus - Tuning.VIEW_HALF_EXTENT * 0.5,
				Tuning.VIEW_HALF_EXTENT), null)
		happenings.tick(STEP, far, Vector2.ZERO)
		_print("%s raid with her screen on %s: %d" % [label, _point(focus),
				happenings.raid.size()])
		printed += 1
	_stand(city, player, far)
	happenings.tick(STEP, far, Vector2.ZERO)
	var at: Array[String] = []
	for body in happenings.raid:
		at.append(_point(body.global_position))
	_print("%s raid from %s: %d at %s" % [label, _point(far), happenings.raid.size(), at])
	return printed + 1

## Day 13's column sent at her from three places along the main road and one off it.
func _the_column(city: City, director: ResistanceDirector, player: Stroller, label: String) -> int:
	var happenings := director._happenings
	var map := city.map
	var spine := (float(map.main_road * CityMap.period()) + Tuning.STREET_WIDTH * 0.5) \
			* Tuning.TILE_SIZE
	var printed := 0
	var hers: Array[Vector2] = [Vector2(spine, 600.0), Vector2(spine + 90.0, 40.0),
			Vector2(spine - 130.0, map.size.y * Tuning.TILE_SIZE - 50.0),
			Vector2(300.0, 900.0)]
	for her in hers:
		_stand(city, player, her)
		var before := happenings._rng.state
		var warning := happenings.send_the_column(her)
		if warning == null:
			_print("%s column from %s: none (rng %d -> %d)" % [label, _point(her), before,
					happenings._rng.state])
			printed += 1
			continue
		var pointed := warning.place
		var shown := 0.0
		while not city.events.pending_warnings().is_empty() and shown < 5.0:
			city.events.warnings.run(STEP, her)
			shown += STEP
		var trucks: Array[String] = []
		for truck in happenings.column:
			if is_instance_valid(truck):
				trucks.append(_point(truck.global_position))
				city.events.retire(truck)
		happenings.column.clear()
		_print("%s column from %s: badge %s withdrawn %s trucks %s (rng %d -> %d)" % [label,
				_point(her), _point(pointed), warning.withdrawn, trucks, before,
				happenings._rng.state])
		printed += 1
	return printed

## Where the events' director half puts a row, from a few places she may stand.
func _the_events_ahead(city: City, player: Stroller, label: String) -> int:
	var printed := 0
	var view := city.events.visible_view()
	var map := city.map
	var cyclist := EventCatalogue.by_id("cyclist")
	var dog := EventCatalogue.by_id("loose_dog")
	var charger := EventCatalogue.by_id("charging_dog")
	var engine := EventCatalogue.by_id("fire_truck")
	var column := EventCatalogue.by_id("military_convoy")
	var headings: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for her in _spots(city):
		_stand(city, player, her)
		var tile := RunTrace.tile(map.world_to_tile(her))
		for heading in headings:
			var line: Array[String] = []
			for row in [cyclist, dog]:
				line.append(_point(PendingWarning.down_her_line(map, row, her, heading, view)))
			line.append(_point(PendingWarning.along_her_heading(map, charger, her, heading, view)))
			_print("%s ahead at %s heading %s: cyclist/dog down her line, charger along %s" % [
					label, tile, heading, line])
			printed += 1
		var kerb := EventSpawner.where_the_summoned_row_stops(map, her)
		if kerb != Vector2.INF:
			for travel in headings:
				_print("%s ahead at %s engine to %s travel %s -> %s" % [label, tile, _point(kerb),
						travel, _point(PendingWarning.on_its_route(engine, her, kerb, travel,
								4000.0, view))])
				printed += 1
		for going in [1.0, -1.0]:
			_print("%s ahead at %s column going %s -> %s" % [label, tile, going,
					_point(PendingWarning.in_its_lane(column, her, her.x - 40.0, going, 16.0,
							map.size.y * Tuning.TILE_SIZE - 16.0, view))])
			printed += 1
		# The men a hunting van owes get out beside it.
		var hot := EventCatalogue.heated(EventCatalogue.by_id("abduction"),
				Tuning.RESISTANCE_GOAL)
		var van := city.events.spawn_extra(hot, her + Vector2(hot.notice_within() - 10.0, 0.0))
		van.player_at = her
		van.step(STEP)
		var owed := van.officers_owed()
		city.events.ahead.let_the_officers_out()
		var men: Array[String] = []
		for man in van.its_officers():
			men.append(_point(man.global_position))
			city.events.retire(man)
		city.events.retire(van)
		_print("%s ahead at %s van owes %d, men at %s" % [label, tile, owed, men])
		printed += 1
	return printed

func _guard_at(guard: EventInstance) -> String:
	if guard == null or not is_instance_valid(guard):
		return "none"
	return _point(guard.global_position)

## Stands her at `at`, the day's view looked through about her as the camera would.
func _stand(city: City, player: Stroller, at: Vector2) -> void:
	player.global_position = at
	city.events.visible_view().look(Rect2(at - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), null)

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
	print("DP " + line)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
