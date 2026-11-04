extends "res://tests/resistance_rig.gd"
## The red arrow: what it points at, how it chooses and switches, and where every arrow ends.
##
## Every test builds its city in a run of its own (`_build_city_in_a_new_run()`) and plays the day it
## asks about on it, so none leans on a step, a scar or a man shouting an earlier one left. What the
## arrow has chosen is read from `ResistanceDirector`'s public queries (`red_arrow_target()`,
## `arrow_targets()`, `arrow_nearest_at()`, `arrow_lead_at()`, `arrow_sweeping()`, `mast_in_play()`,
## `rider()`, `contact()`); its choosing and sweeping are driven by `retarget_the_arrow()` and
## `tick()`, the step `main` runs on every physics tick (`_settle_the_arrow()` below); and her touch
## is a real physics frame (`_step_a_frame()`).

func run(t) -> void:
	t.gives_back_observers()
	await _test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t)
	_test_an_arrow_exists_on_every_task_day(t)
	_test_the_arrow_chooses_by_walking_distance_not_straight_line(t)
	_test_the_arrow_switches_as_another_target_becomes_closer(t)
	_test_the_arrow_moves_at_four_tiles_closer(t)
	_test_the_arrow_does_not_move_at_three_tiles_closer(t)
	_test_the_arrow_leaves_a_freed_instance_at_once(t)
	_test_a_single_target_arrow_stays_on_its_contact(t)
	await _test_day_eleven_answers_at_any_live_mast(t)
	_test_every_arrow_ends_on_its_item_and_its_touch_can_be_made(t)
	_test_the_swings_touch_is_the_ellipse_at_its_base(t)
	_free_city()

## Runs the arrow to rest the way the game does: it chooses (`retarget_the_arrow()`), then the
## physics ticks `main` runs (`ResistanceDirector.tick()`) sweep the walking fields a slice at a time,
## choosing again as each finishes, until none is under way. Bounded: a sweep that never ends fails
## the test's next check rather than hanging it.
func _settle_the_arrow(director: ResistanceDirector) -> void:
	director.retarget_the_arrow()
	var ticks := 0
	while director.arrow_sweeping() and ticks < 1200:
		director.tick(STEP)
		ticks += 1

## Every built perform step earns the red arrow, the "any instance" ones (the man shouting, a
## roadblock) included. A mark never earns one, whichever task it unlocks. Each case plays its day
## on a city of its own.
func _test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t) -> void:
	_build_city_in_a_new_run(t)
	var mark_only := _director(t)
	mark_only.start_day(6, _rng(6, "resistance"), 300.0)
	t.check(mark_only.red_arrow_target() == Vector2.INF, "a mark never earns the red arrow")
	mark_only.free()

	_build_city_in_a_new_run(t)
	var yeller := _director_on_the_yeller_perform(t)
	t.check(yeller.red_arrow_target() != Vector2.INF and yeller.rider() != null
			and yeller.red_arrow_target() == yeller.rider().global_position,
			"the yeller is any instance and earns the arrow too, on the man shouting")
	yeller.free()

	# Day 7: reading the mark unlocks the package task, whose contact stands on the van.
	var read := _read_the_mark_on(t, 7, SEED)
	var van: ResistanceDirector = read[0]
	var player: Stroller = read[2]
	# M222, "the red arrow for the van does not end on the van", and feathery-marmot, "Never
	# besides the item!": the contact stands on the van and the arrow's tip is the van itself.
	t.check(van.rider() != null, "the package's van is a rider, not a bare point")
	t.check(van.rider() != null and van.red_arrow_target() != Vector2.INF
			and van.red_arrow_target() == van.rider().global_position
			and van.red_arrow_target() == van.contact_position(),
			"the package's van is one place, so it earns the arrow, exactly on the van's body")
	var task := van.current_step()
	player.teleport_to(van.contact_position())
	await _step_a_frame(t)
	t.check(task != null and van.contact().is_done and van.red_arrow_target() == Vector2.INF,
			"and it goes out once she has reached it")
	player.free()
	van.free()
	_free_city()

## plush-moose: an arrow exists on every task day, the any-instance days (6 and 13) and day 11's
## masts included, from the moment the mark is read, and the last night's from dawn.
func _test_an_arrow_exists_on_every_task_day(t) -> void:
	var run := _build_city_in_a_new_run(t)
	for day: int in range(6, Tuning.RUN_LENGTH_DAYS + 1):
		run.attempt_spend.scars = []
		run.resistance.progress = Tuning.RESISTANCE_GOAL if day == Tuning.RUN_LENGTH_DAYS else 0
		run.resistance.sabotage_done = false
		var read := _read_the_mark_on(t, day, SEED) if day != Tuning.RUN_LENGTH_DAYS \
				else _start_the_finale(t, SEED)
		var director: ResistanceDirector = read[0]
		var step := director.current_step()
		t.check(step != null and not step.is_pickup,
				"day %d: the task is on offer" % day)
		t.check(director.red_arrow_target() != Vector2.INF,
				"day %d: and it has the red arrow" % day)
		(read[2] as Stroller).free()
		director.free()
	_free_city()

## A tile with a straight run of walkable tiles that nothing blocks today — no closure, no soft
## seal, no body standing — `before` tiles to its left and `after` to its right, for building a
## constructed case, or (-1, -1).
func _open_run_for(before: int, after: int) -> Vector2i:
	var map := _city.map
	for y in range(8, map.size.y - 8):
		for x in range(before + 1, map.size.x - after - 1):
			var open := true
			for dx in range(-before, after + 1):
				var tile := Vector2i(x + dx, y)
				if not map.is_walkable(tile) or map.is_closed(tile) or map.is_obstructed(tile) \
						or map.is_soft_sealed(tile):
					open = false
					break
			if open:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

## Day 6 on a city of its own with the men shouting `offsets` tiles to the right of the open run's
## centre (a negative one to its left) and every other put out of the day, and her standing at the
## centre: `[director, her rig, the centre tile, the men]`. She is stood on the first man and the
## director ticked once, which is how the task comes to ride him (`tick()` retargets the contact onto
## the look-alike she is within reach of); then the day's own man, who rode the contact before, is
## retired along with the rest.
func _yeller_arrow_case(t, before: int, after: int, offsets: Array) -> Array:
	_build_city_in_a_new_run(t)
	var director := _director_on_the_yeller_perform(t)
	var tile := _open_run_for(before, after)
	var player := _rig_player(t, _city.map.tile_to_world(tile))
	director.use_player(player)
	var men: Array[EventInstance] = []
	if tile.x < 0:
		return [director, player, tile, men]
	for offset: int in offsets:
		men.append(_put_a_yeller(tile + Vector2i(offset, 0)))
	player.global_position = men[0].global_position
	director.tick(STEP)
	for instance in _city.events.instances():
		if instance.def.id == "homeless_yeller" and instance not in men:
			_city.events.retire(instance)
	player.global_position = _city.map.tile_to_world(tile)
	return [director, player, tile, men]

func _put_a_yeller(tile: Vector2i) -> EventInstance:
	return _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"),
			_city.map.tile_to_world(tile))

## plush-moose, "closest here always means path closeness not crow closeness": a wall of standing
## bodies between her and the man who is nearer as the crow flies sends the arrow to the farther
## one she can walk to sooner. The wall goes up after the arrow has chosen, in the live record of
## bodies (`CityMap.obstruct_tiles()`), so this is also the arrow reading what blocks her now.
func _test_the_arrow_chooses_by_walking_distance_not_straight_line(t) -> void:
	var made := _yeller_arrow_case(t, 15, 8, [6, -14])
	var director: ResistanceDirector = made[0]
	var player: Stroller = made[1]
	var here: Vector2i = made[2]
	t.check(here.x >= 0, "the test city has an open run to build the case on")
	if here.x >= 0:
		var near_by_crow: EventInstance = made[3][0]
		var near_by_path: EventInstance = made[3][1]
		t.check(player.global_position.distance_to(near_by_crow.global_position)
				< player.global_position.distance_to(near_by_path.global_position),
				"the one beyond the wall is the nearer as the crow flies")
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) < 1.0,
				"with nothing between them the arrow points at the nearer one")
		# A wall of bodies three tiles beyond her, far longer than the hold.
		var wall: Array[Vector2i] = []
		for dy in range(-30, 31):
			wall.append(here + Vector2i(3, dy))
		var owner := get_instance_id()
		_city.map.obstruct_tiles(owner, wall)
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(near_by_path.global_position) < 1.0,
				"behind a wall the arrow points at the one she can walk to sooner")
		t.check(director.pointable_objective() == director.red_arrow_target(),
				"and the protest cue points at the same chosen objective as the arrow")
		t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) > 100.0,
				"and not at the nearer as the crow flies")
		_city.map.release_obstruction(owner)
	player.free()
	director.free()
	_free_city()

## plush-moose, "might switch if another closest one comes close": as she walks the arrow moves to
## whichever target has become closer on foot, with a hold of `ARROW_HOLD_TILES` so two about-as-
## near ones do not make it flicker, and the tick moves it by itself.
func _test_the_arrow_switches_as_another_target_becomes_closer(t) -> void:
	var made := _yeller_arrow_case(t, 15, 15, [-6, 14])
	var director: ResistanceDirector = made[0]
	var player: Stroller = made[1]
	var here: Vector2i = made[2]
	t.check(here.x >= 0, "the test city has an open run to build the case on")
	if here.x >= 0:
		var west: EventInstance = made[3][0]
		var east: EventInstance = made[3][1]
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
				"standing at the start the arrow points at the closer one")
		# Walking east: the other becomes closer by more than the hold, and the tick moves it.
		player.global_position = _city.map.tile_to_world(here + Vector2i(8, 0))
		director.tick(ResistanceDirector.ARROW_RETARGET_SECONDS)
		t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
				"walking toward the other one, the arrow switches to it")
		# Back to a spot about as near to both: it stays where it is.
		player.global_position = _city.map.tile_to_world(here + Vector2i(4, 0))
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
				"about as near to both, it does not flicker back")
		# Ignoring the task and walking on west: it goes back to the first.
		player.global_position = _city.map.tile_to_world(here + Vector2i(-4, 0))
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
				"walking away from the task the arrow jumps to the closest on the other side")
	player.free()
	director.free()
	_free_city()

## The hold's margin, as the docs state it: another target exactly `ARROW_HOLD_TILES` (four) tiles
## closer on foot takes the arrow, and one three tiles closer does not. Each case puts the arrow on
## the east man first, then stands her where the walking lengths differ by that much, measured from
## the arrow's own queries so a case the city's ground does not give is a failure, not a pass.
func _test_the_arrow_moves_at_four_tiles_closer(t) -> void:
	_the_arrow_with_the_west_man_closer_by(t, 14, ResistanceDirector.ARROW_HOLD_TILES, true)

func _test_the_arrow_does_not_move_at_three_tiles_closer(t) -> void:
	_the_arrow_with_the_west_man_closer_by(t, 13, ResistanceDirector.ARROW_HOLD_TILES - 1, false)

## One case of the hold: the east man `east_at` tiles from the open run's centre, the west man six
## to its left, her stood where the west man is `lead` tiles closer on foot; whether the arrow then
## moves to him is `moves`.
func _the_arrow_with_the_west_man_closer_by(t, east_at: int, lead: int, moves: bool) -> void:
	var made := _yeller_arrow_case(t, 10, 18, [east_at, -6])
	var director: ResistanceDirector = made[0]
	var player: Stroller = made[1]
	var here: Vector2i = made[2]
	t.check(here.x >= 0, "the test city has an open run to build the case on")
	if here.x >= 0:
		var east: EventInstance = made[3][0]
		var west: EventInstance = made[3][1]
		player.global_position = _city.map.tile_to_world(here + Vector2i(east_at - 1, 0))
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
				"beside the east man the arrow is on him")
		player.global_position = _city.map.tile_to_world(here + Vector2i(2, 0))
		var tile := _city.map.world_to_tile(player.global_position)
		t.check(director.arrow_nearest_at(tile) == west.get_instance_id()
				and director.arrow_lead_at(tile) == lead,
				"the west man is %d tiles closer on foot (the lead is %d)"
				% [lead, director.arrow_lead_at(tile)])
		director.retarget_the_arrow()
		var moved := director.red_arrow_target().distance_to(west.global_position) < 1.0
		t.check(moved == moves, "%d tiles closer %s the arrow"
				% [lead, "moves" if moves else "does not move"])
	player.free()
	director.free()
	_free_city()

## When the instance the arrow points at goes — freed as it streams out, the way
## `EventStreaming.stream_out()` frees it — asking for the arrow is still a read that answers a
## real place (the contact's own, never a freed one's and never (0, 0)), and the next frame points
## the arrow at a target that is still there.
func _test_the_arrow_leaves_a_freed_instance_at_once(t) -> void:
	# The contact rides the far man, as it rides a live man shouting all day.
	var made := _yeller_arrow_case(t, 15, 15, [12, -4])
	var director: ResistanceDirector = made[0]
	var player: Stroller = made[1]
	var here: Vector2i = made[2]
	t.check(here.x >= 0, "the test city has an open run to build the case on")
	if here.x >= 0:
		var far: EventInstance = made[3][0]
		var near: EventInstance = made[3][1]
		t.check(director.rider() == far, "the task rides the far man")
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(near.global_position) < 1.0,
				"the arrow is on the nearer man")
		_city.events.world.instances.erase(near)
		near.free()
		var asked := director.red_arrow_target()
		t.check(asked == director.contact_position() and asked != Vector2.ZERO,
				"asked after he is freed, it answers the contact's own place (%s)" % asked)
		t.check(not director.arrow_sweeping(),
				"and asking started no sweep: it is a read")
		director.tick(STEP)
		t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
				"the next frame the arrow is on a man still there")
		t.check(director.arrow_sweeping(),
				"and that frame chose again at once, the walk to the men still there under way")
		_settle_the_arrow(director)
		t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
				"and stays there once the sweep without the freed one is done")
	player.free()
	director.free()
	_free_city()

## The cell centres of the day's longest route, from the doorstep end out: the walk she takes, as
## `tests/test_route_bag.gd` walks it. A route names `ReachabilityGrid` cells, two tiles square, so
## a cell's centre is half a tile past its first tile's centre on both axes.
func _longest_route_points() -> Array[Vector2]:
	var longest: Array = []
	for branch in _city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(_city.map.tile_to_world(longest[i] * ReachabilityGrid.CELL)
				+ Vector2.ONE * (Tuning.TILE_SIZE * 0.5))
	return points

## How many seconds the last `_walk_until_the_route_mast()` walked before the mast was put down.
var _seconds_walked_to_the_route_mast := 0.0

## Walks her down the day's longest route, the events siting what her walk sites and placing what
## is owed ahead of her as they do in play, until the mast reading day 11's mark rigged onto her
## route is put down — a mast that is not in `at_the_mark`, the ids the day had when she read it:
## its mast id, or "" if the walk ends first.
func _walk_until_the_route_mast(at_the_mark: Dictionary, player: Stroller) -> String:
	_seconds_walked_to_the_route_mast = 0.0
	var path := _longest_route_points()
	_city.events.use_player(player)
	if path.size() < 2:
		return ""
	var index := 0
	var direction := 1
	player.global_position = path[0]
	var walked := 0.0
	var step := 0.1
	while walked < 600.0:
		for plan in _city.events.plans():
			if plan.def.role == EventDef.Role.MAST and plan.mast_id != "" \
					and not at_the_mark.has(plan.mast_id):
				_seconds_walked_to_the_route_mast = walked
				return plan.mast_id
		var next: Vector2 = path[index + direction] if index + direction >= 0 \
				and index + direction < path.size() else Vector2.INF
		if next == Vector2.INF:
			direction = -direction
			continue
		var toward := next - player.global_position
		if toward.length() < Tuning.WALK_SPEED * step:
			player.global_position = next
			index += direction
			continue
		player.velocity = toward.normalized() * Tuning.WALK_SPEED
		_city.events.ahead.site_what_is_on_her_way(step)
		_city.events.ahead.place_what_is_owed_ahead(step)
		player.global_position += player.velocity * step
		walked += step
	return ""

## A tile beside `foot` she can stand on to touch the mast there, as `_place_at_a_mast()` asks it.
func _beside_the_mast(director: ResistanceDirector, foot: Vector2) -> Vector2:
	var foot_tile := _city.map.world_to_tile(foot)
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var tile := foot_tile + side
		if SpawnSiting.is_legal_ground(_city.map, tile, _walled_alleys()) \
				and not _city.map.is_obstructed(tile):
			return _city.map.tile_to_world(tile)
	return Vector2.INF

## Day 11, through the real rig: reading the mark rigs a mast onto her route, and walking the
## day's route puts it down. Then **any live mast answers the task** *(the player: "why limit
## artificially to two arbitrary masts")* — the one near the mark, the routed one and a third one
## besides — and touching the third, which is neither, completes the task, silences that mast and
## scars its foot, and leaves the other two lit. Asking for the arrow along the way is a read.
##
## **The routed mast has a place on her route in every one of `DAY_ELEVEN_SEEDS`.** Every mast is
## exempt from the three rules that keep a line along her routes
## (`Planned.counts_against_the_line()`; inbox #684 in coral-lark), so the walk down the longest route puts it
## down in every city. The suite's own city is walked in full; the others are asked the one question
## the walk asks, `WalkSiting.ahead_of()` from points along the longest route, without walking, which
## keeps six cities as cheap as one. A city that fails fails here rather than being skipped.
func _test_day_eleven_answers_at_any_live_mast(t) -> void:
	var routed_on := [-1]
	var missed: Array[int] = []
	for seed_value: int in DAY_ELEVEN_SEEDS:
		_build_city_in_a_new_run(t, seed_value)
		if seed_value == DAY_ELEVEN_SEEDS[0]:
			await _answer_day_eleven_at_any_live_mast(t, seed_value, routed_on)
			if routed_on[0] < 0:
				missed.append(seed_value)
			continue
		var read := _read_the_mark_on(t, 11, seed_value)
		if not _a_mast_can_be_sited_along_her_route():
			missed.append(seed_value)
		(read[2] as Stroller).free()
		(read[0] as ResistanceDirector).free()
	t.check(missed.is_empty(), "the rigged mast has a place on her route in every city of %s (not in %s)"
			% [DAY_ELEVEN_SEEDS, missed])
	_free_city()

## Whether `WalkSiting.ahead_of()` finds the routed mast a place from some point along the day's
## longest route, heading along it: the question `_walk_until_the_route_mast()` answers by walking.
func _a_mast_can_be_sited_along_her_route() -> bool:
	var siting: EventScheduler.WalkSiting = _city.events.ahead._siting
	var def: EventDef = _city.events.ahead.director().route_row(EventCatalogue.mast().id)
	var band: Vector2 = _city.events.ahead.director()._siting_band()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var path := _longest_route_points()
	for i in range(0, path.size() - 1, 4):
		var heading := (path[i + 1] - path[i]).normalized()
		if heading != Vector2.ZERO and siting.ahead_of(def, rng, _city.events.plans(), path[i],
				heading, band.x, band.y) != null:
			return true
	return false

## The cities `_test_day_eleven_answers_at_any_live_mast` covers: the suite's own (walked), 90210 and
## 1234567, which `_test_a_task_is_placed_near_its_mark` also reads day 11 on, and 314159, 555555 and
## 8675309, cities whose route tree has few tiles a mast may take.
const DAY_ELEVEN_SEEDS: Array[int] = [SEED, 90210, 1234567, 314159, 555555, 8675309]

## One city's half of `_test_day_eleven_answers_at_any_live_mast`; sets `routed_on[0]` to the seed
## once its walk has put the routed mast down, and checks the rest only then.
func _answer_day_eleven_at_any_live_mast(t, seed_value: int, routed_on: Array) -> void:
	var read := _read_the_mark_on(t, 11, seed_value)
	var director: ResistanceDirector = read[0]
	var player: Stroller = read[2]
	var step := director.current_step()
	var near := director.mast_in_play()
	t.check(step != null and near != "", "day 11's task is on offer at the mast near the mark")
	var before := [director.arrow_key(), director.red_arrow_target(), director.mast_in_play(),
			director.contact_position()]
	var asked := director.red_arrow_target()
	t.check(asked == director.contact_position() and not director.arrow_sweeping()
			and [director.arrow_key(), director.red_arrow_target(), director.mast_in_play(),
			director.contact_position()] == before,
			"asking for the arrow chooses nothing, sweeps nothing and moves no contact")
	var at_the_mark := {}
	for plan in _city.events.plans():
		if plan.mast_id != "":
			at_the_mark[plan.mast_id] = true
	var routed := _walk_until_the_route_mast(at_the_mark, player)
	if routed == "" or step == null:
		player.free()
		director.free()
		return
	routed_on[0] = seed_value
	var keys: Array = []
	for target in director.arrow_targets():
		keys.append(target["key"])
	var third := ""
	for key: String in keys:
		if key != near and key != routed \
				and _beside_the_mast(director, _city.events.mast_foot(key)) != Vector2.INF:
			third = key
	t.check(near in keys and routed in keys and third != "",
			"the near mast, the routed one and a third all answer (%s)" % [keys])
	if third == "":
		player.free()
		director.free()
		return
	var third_foot := _city.events.mast_foot(third)
	var near_foot := _city.events.mast_foot(near)
	player.global_position = _beside_the_mast(director, third_foot)
	t.check(director.red_arrow_target().distance_to(near_foot) < 1.0
			and director.mast_in_play() == near,
			"before the next choice the arrow and task still point at the near mast")
	director.tick(STEP)
	t.check(director.red_arrow_target().distance_to(third_foot) < 1.0
			and director.mast_in_play() == third,
			"following her between masts moves the task to the one she actually touches")
	await _step_a_frame(t)
	t.check(step.index in _city.run.resistance.completed_steps,
			"touching the third mast completes the task")
	var silenced := {}
	for plan in _city.events.plans():
		if plan.mast_id in [near, routed, third]:
			silenced[plan.mast_id] = plan.silenced
	t.check(silenced.get(third, false) and not silenced.get(near, true)
			and not silenced.get(routed, true),
			"and silences the mast she touched, not the near or the routed one (%s)" % silenced)
	var scarred := []
	for scar: Dictionary in _city.run.attempt_spend.scars:
		if String(scar["id"]) == EventScheduler.SILENCED_MAST:
			scarred.append(scar["position"])
	t.check(scarred.size() == 1 and (scarred[0] as Vector2).distance_to(third_foot) < 1.0,
			"and the one scar is that mast's foot")
	player.free()
	director.free()

## A single-target task keeps its arrow on its contact exactly, retargeting or not.
func _test_a_single_target_arrow_stays_on_its_contact(t) -> void:
	_build_city_in_a_new_run(t)
	var read := _read_the_mark_on(t, 7, SEED)
	var van: ResistanceDirector = read[0]
	van.retarget_the_arrow()
	t.check(van.red_arrow_target() == van.contact_position()
			and van.red_arrow_target() != Vector2.INF,
			"the van has the one arrow, on its contact")
	(read[2] as Stroller).free()
	van.free()
	_free_city()

## feathery-marmot, "the arrow ends on the item" — *"the red arrows should point to the actual item
## -- however, the radius of acceptance should be big enough to be possible to do"* · *"No! Never
## besides the item!"*. On three cities, each one-place task with a bare point or a body is
## planned in the real day order and put on offer: day 7's van, day 9's district door, day 11's
## mast, day 12's swing and the last night's station door. Its arrow ends on the item itself — the
## van's centre, one of the door's two gatehouses, the mast's foot, the swing's base
## (`CityMap.swing_position()`), the station door's point on its facade — and the task is completed
## from some standable, reachable tile near it (day 9 is crossed instead, and its own test is
## below). Before, the arrow ended beside the mast (32px), on the swing's tile centre, on a pavement
## tile in front of the station door and on the middle of the district door's street.
func _test_every_arrow_ends_on_its_item_and_its_touch_can_be_made(t) -> void:
	var checked := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		var run := _build_city_in_a_new_run(t, seed_value)
		for day: int in [7, 9, 11, 12, Tuning.RUN_LENGTH_DAYS]:
			run.attempt_spend.scars = []
			run.resistance.progress = Tuning.RESISTANCE_GOAL \
					if day == Tuning.RUN_LENGTH_DAYS else 0
			run.resistance.sabotage_done = false
			var read := _read_the_mark_on(t, day, seed_value) if day != Tuning.RUN_LENGTH_DAYS \
					else _start_the_finale(t, seed_value)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var step := director.current_step()
			var arrow := director.red_arrow_target()
			if step == null or step.is_pickup or arrow == Vector2.INF:
				t.check(false, "seed %d day %d: the task is on offer with its arrow"
						% [seed_value, day])
			else:
				checked[0] += 1
				var item := _the_item_of(director, step)
				t.check(item != Vector2.INF and arrow.distance_to(item) < 0.5,
						"seed %d day %d: the arrow ends on the item itself (%s, item %s)"
						% [seed_value, day, arrow, item])
				if step.target_kind != ResistanceSteps.TargetKind.DOOR:
					t.check(_touched_from_standable_ground(director, item),
							"seed %d day %d: and the task is touched from ground she can stand on"
							% [seed_value, day])
			player.free()
			director.free()
	_free_city()
	t.check(checked[0] > 0, "some task was put on offer (%d)" % checked[0])

## The finale on the test city in the real day order, the goal met: `[director, Vector2.INF, her
## rig]`, the shape `_read_the_mark_on()` answers, the finale having no mark.
func _start_the_finale(t, seed_value: int) -> Array:
	var day := Tuning.RUN_LENGTH_DAYS
	_city.run.resistance.completed_steps = _all_but_the_finale()
	_city.run.facts.completed_resistance_alley_tiles = []
	var state := CityState.new()
	_city.run.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures", seed_value))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events", seed_value), [],
			_city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance", seed_value), 300.0)
	var player := _rig_player(t, _city.map.doorstep_world_position())
	director.use_player(player)
	return [director, Vector2.INF, player]

## Where the item a one-place task is about stands, found from the day itself rather than from the
## contact: the van's own instance, a gatehouse of today's district doors (the one nearest the
## contact, so the test asks that the contact is on one of them), the foot of the mast the task
## named, the swing frame's base, the station's door point on its facade.
func _the_item_of(director: ResistanceDirector, step: ResistanceSteps.Step) -> Vector2:
	match step.target_kind:
		ResistanceSteps.TargetKind.EVENT:
			return director.rider().global_position if director.rider() else Vector2.INF
		ResistanceSteps.TargetKind.DOOR:
			var nearest := Vector2.INF
			for body in _city.region_plan().door_bodies:
				if body.def.redetains and (nearest == Vector2.INF or body.position.distance_to(
						director.contact_position()) < nearest.distance_to(director.contact_position())):
					nearest = body.position
			return nearest
		ResistanceSteps.TargetKind.MAST:
			return _city.events.mast_foot(director.mast_in_play())
		ResistanceSteps.TargetKind.PARK_SWING:
			var layout: BlockLayout = _city.map.block_layouts.get(CityGenerator.swing_park(_city.map))
			return _city.map.swing_position(layout.playground) if layout else Vector2.INF
		ResistanceSteps.TargetKind.STATION_DOOR:
			var door := _city.map.power_station_door_position()
			return Vector2(door.x, door.y - Tuning.TILE_SIZE)
	return Vector2.INF

## feathery-marmot, day 12 — *"Not the drawn swing. Place an ellipse at its base. That's the area to
## touch"*. The swing's contact is touched by her body overlapping `ResistanceDirector.swing_base()`
## round the swing's base, the extent of the shadow the frame casts there (the ground shape a swing
## frame `Prop` takes as it enters the tree, `Prop.shape`): from eight bearings, standing with her edge a pixel inside the ellipse's
## outline completes it, at each side and each corner, and standing two pixels clear of it does not.
## Before, a 36px circle round the swing's tile centre counted.
func _test_the_swings_touch_is_the_ellipse_at_its_base(t) -> void:
	var contact := ContactPoint.new()
	contact.setup(_perform_on(12), Vector2(500.0, 500.0))
	contact.touch_ellipse = ResistanceDirector.swing_base()
	t.add_child(contact)
	contact.set_physics_process(false)
	var semi := ResistanceDirector.swing_base()
	var frame := Prop.new()
	frame.kind = Prop.Kind.PLAYGROUND_FRAME
	t.add_child(frame)
	var shadow := frame.shape
	frame.free()
	t.check(is_equal_approx(semi.x, shadow.reach()) and is_equal_approx(semi.y, shadow.across()),
			"the ellipse spans the shadow the frame casts at its base (%s)" % semi)
	var touching := 0
	var clear := 0
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var edge := Vector2(cos(angle) * semi.x, sin(angle) * semi.y)
		var outward := Vector2(cos(angle) / semi.x, sin(angle) / semi.y).normalized()
		var inside := contact.global_position + edge + outward * (Tuning.PLAYER_BODY_RADIUS - 1.0)
		var outside := contact.global_position + edge + outward * (Tuning.PLAYER_BODY_RADIUS + 2.0)
		if contact.would_complete_at(inside):
			touching += 1
		if not contact.would_complete_at(outside):
			clear += 1
	t.check(touching == 8, "her body overlapping the swing's base ellipse completes it on every side and corner (%d of 8)" % touching)
	t.check(clear == 8, "and two pixels clear of it, on every side and corner, does not (%d of 8)" % clear)
	t.check(semi.x > semi.y and semi.y > 0.0, "the base is wider than it is deep, as the frame stands side-on")
	contact.free()
