extends "res://tests/resistance_rig.gd"
## The red arrow: what it points at, how it chooses and switches, and where every arrow ends.

func run(t) -> void:
	_test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t)
	_test_an_arrow_exists_on_every_task_day(t)
	_test_the_arrow_chooses_by_walking_distance_not_straight_line(t)
	_test_the_arrow_switches_as_another_target_becomes_closer(t)
	_test_the_arrow_moves_at_four_tiles_closer_and_not_at_three(t)
	_test_the_arrow_leaves_a_freed_instance_at_once(t)
	_test_a_single_target_arrow_stays_on_its_contact(t)
	_test_day_eleven_answers_at_any_live_mast(t)
	_test_every_arrow_ends_on_its_item_and_its_touch_can_be_made(t)
	_test_the_swings_touch_is_the_ellipse_at_its_base(t)
	if _city != null:
		_city.free()

## Every built perform step earns the red arrow, the "any instance" ones (the man shouting, a
## roadblock) included. A mark never earns one, whichever task it unlocks.
func _test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var mark_only := _director(t)
		mark_only.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(mark_only.red_arrow_target() == Vector2.INF, "a mark never earns the red arrow")
		mark_only.free()

		var yeller := _director_on_the_yeller_perform(t)
		t.check(yeller.red_arrow_target() != Vector2.INF
				and yeller.red_arrow_target() == yeller._rider.global_position,
				"the yeller is any instance and earns the arrow too, on the man shouting")
		yeller.free()

		GameState.resistance.completed_steps = _completed_through(2)
		var van := _director(t)
		van.start_day(7, _rng(7, "resistance"), 300.0)
		van._on_contact_completed(3)
		# M222, "the red arrow for the van does not end on the van", and feathery-marmot, "Never
		# besides the item!": the contact stands on the van and the arrow's tip is the van itself.
		t.check(van._rider != null, "the package's van is a rider, not a bare point")
		t.check(van.red_arrow_target() != Vector2.INF
				and van.red_arrow_target() == van._rider.global_position
				and van.red_arrow_target() == van.contact_position(),
				"the package's van is one place, so it earns the arrow, exactly on the van's body")
		var task := van.current_step()
		van._contact._complete()
		t.check(task != null and van.red_arrow_target() == Vector2.INF,
				"and it goes out once she has reached it")
		van.free())

## plush-moose: an arrow exists on every task day, the any-instance days (6 and 13) and day 11's
## masts included, from the moment the mark is read, and the last night's from dawn.
func _test_an_arrow_exists_on_every_task_day(t) -> void:
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var saved_progress := GameState.resistance.progress
	var saved_sabotage := GameState.resistance.sabotage_done
	_build_city(t)
	_with_clean_run(func() -> void:
		for day: int in range(6, Tuning.RUN_LENGTH_DAYS + 1):
			GameState.attempt_spend.scars = []
			GameState.resistance.progress = Tuning.RESISTANCE_GOAL \
					if day == Tuning.RUN_LENGTH_DAYS else 0
			GameState.resistance.sabotage_done = false
			var read := _read_the_mark_on(t, day, SEED) if day != Tuning.RUN_LENGTH_DAYS \
					else _start_the_finale(t, SEED)
			var director: ResistanceDirector = read[0]
			var step := director.current_step()
			t.check(step != null and not step.is_pickup,
					"day %d: the task is on offer" % day)
			t.check(director.red_arrow_target() != Vector2.INF,
					"day %d: and it has the red arrow" % day)
			(read[2] as Stroller).free()
			director.free())
	GameState.attempt_spend.scars = saved_scars
	GameState.attempt_spend.city_state = saved_state
	GameState.resistance.progress = saved_progress
	GameState.resistance.sabotage_done = saved_sabotage

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

## Day 6 on the test city with every man shouting retired, so the ones a test puts in are the only
## ones, and a rig of her on an open run: `[director, her rig, tile]`, the tile the run is centred
## on.
func _yeller_arrow_case(t, before: int, after: int) -> Array:
	var director := _director_on_the_yeller_perform(t)
	for instance in _city.events.instances():
		if instance.def.id == "homeless_yeller":
			_city.events.retire(instance)
	director._rider = null
	var tile := _open_run_for(before, after)
	var player := _rig_player(t, _city.map.tile_to_world(tile))
	director.use_player(player)
	return [director, player, tile]

func _put_a_yeller(tile: Vector2i) -> EventInstance:
	return _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"),
			_city.map.tile_to_world(tile))

## plush-moose, "closest here always means path closeness not crow closeness": a wall of standing
## bodies between her and the man who is nearer as the crow flies sends the arrow to the farther
## one she can walk to sooner. The wall goes up after the arrow has chosen, in the live record of
## bodies (`CityMap.obstruct_tiles()`), so this is also the arrow reading what blocks her now.
func _test_the_arrow_chooses_by_walking_distance_not_straight_line(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 8)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var near_by_crow := _put_a_yeller(here + Vector2i(6, 0))
			var near_by_path := _put_a_yeller(here + Vector2i(-14, 0))
			t.check(player.global_position.distance_to(near_by_crow.global_position)
					< player.global_position.distance_to(near_by_path.global_position),
					"the one beyond the wall is the nearer as the crow flies")
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) < 1.0,
					"with nothing between them the arrow points at the nearer one")
			# A wall of bodies three tiles beyond her, far longer than the hold.
			var wall: Array[Vector2i] = []
			for dy in range(-30, 31):
				wall.append(here + Vector2i(3, dy))
			var owner := get_instance_id()
			_city.map.obstruct_tiles(owner, wall)
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near_by_path.global_position) < 1.0,
					"behind a wall the arrow points at the one she can walk to sooner")
			t.check(director.pointable_objective() == director.red_arrow_target(),
					"and the protest cue points at the same chosen objective as the arrow")
			t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) > 100.0,
					"and not at the nearer as the crow flies")
			_city.map.release_obstruction(owner)
		player.free()
		director.free())

## plush-moose, "might switch if another closest one comes close": as she walks the arrow moves to
## whichever target has become closer on foot, with a hold of `ARROW_HOLD_TILES` so two about-as-
## near ones do not make it flicker, and the tick moves it by itself.
func _test_the_arrow_switches_as_another_target_becomes_closer(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 15)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var west := _put_a_yeller(here + Vector2i(-6, 0))
			var east := _put_a_yeller(here + Vector2i(14, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
					"standing at the start the arrow points at the closer one")
			# Walking east: the other becomes closer by more than the hold, and the tick moves it.
			player.global_position = _city.map.tile_to_world(here + Vector2i(8, 0))
			director.tick(ResistanceDirector.ARROW_RETARGET_SECONDS)
			t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
					"walking toward the other one, the arrow switches to it")
			# Back to a spot about as near to both: it stays where it is.
			player.global_position = _city.map.tile_to_world(here + Vector2i(4, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
					"about as near to both, it does not flicker back")
			# Ignoring the task and walking on west: it goes back to the first.
			player.global_position = _city.map.tile_to_world(here + Vector2i(-4, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
					"walking away from the task the arrow jumps to the closest on the other side")
		player.free()
		director.free())

## The hold's margin, as the docs state it: another target exactly `ARROW_HOLD_TILES` (four) tiles
## closer on foot takes the arrow, and one three tiles closer does not. Each case puts the arrow on
## the east man first, then stands her where the walking lengths differ by that much, measured from
## the fields themselves so a case the city's ground does not give is a failure, not a pass.
func _test_the_arrow_moves_at_four_tiles_closer_and_not_at_three(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 10, 18)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			for case: Array in [[14, ResistanceDirector.ARROW_HOLD_TILES, true],
					[13, ResistanceDirector.ARROW_HOLD_TILES - 1, false]]:
				var east_at: int = case[0]
				var west := _put_a_yeller(here + Vector2i(-6, 0))
				var east := _put_a_yeller(here + Vector2i(east_at, 0))
				player.global_position = _city.map.tile_to_world(here + Vector2i(east_at - 1, 0))
				director._settle_the_arrow()
				t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
						"beside the east man the arrow is on him")
				player.global_position = _city.map.tile_to_world(here + Vector2i(2, 0))
				var tile := _city.map.world_to_tile(player.global_position)
				var to_west := director._arrow_nearest.length_at(tile)
				var to_east := director._arrow_own.length_at(tile)
				t.check(director._arrow_nearest.nearest_at(tile) == west.get_instance_id()
						and to_east - to_west == case[1],
						"the west man is %d tiles closer on foot (%d against %d)"
						% [case[1], to_west, to_east])
				director.retarget_the_arrow()
				var moved := director.red_arrow_target().distance_to(west.global_position) < 1.0
				t.check(moved == case[2], "%d tiles closer %s the arrow"
						% [case[1], "moves" if case[2] else "does not move"])
				_city.events.retire(west)
				_city.events.retire(east)
		player.free()
		director.free())

## When the instance the arrow points at goes — freed as it streams out, the way
## `EventStreaming.stream_out()` frees it — asking for the arrow is still a read that answers a
## real place (the contact's own, never a freed one's and never (0, 0)), and the next frame points
## the arrow at a target that is still there.
func _test_the_arrow_leaves_a_freed_instance_at_once(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 15)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var near := _put_a_yeller(here + Vector2i(-4, 0))
			var far := _put_a_yeller(here + Vector2i(12, 0))
			# The contact rides the far one, as it rides a live man shouting all day.
			director._rider = far
			director._contact.ride(director._step, far, Vector2.ZERO)
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near.global_position) < 1.0,
					"the arrow is on the nearer man")
			_city.events.world.instances.erase(near)
			near.free()
			var asked := director.red_arrow_target()
			t.check(asked == director.contact_position() and asked != Vector2.ZERO,
					"asked after he is freed, it answers the contact's own place (%s)" % asked)
			t.check(director._arrow_nearest_next == null,
					"and asking started no sweep: it is a read")
			director.tick(STEP)
			t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
					"the next frame the arrow is on a man still there")
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
					"and stays there once the sweep without the freed one is done")
		player.free()
		director.free())

## The cell centres of the day's longest route, from the doorstep end out: the walk she takes, as
## `tests/test_route_bag.gd` walks it.
func _longest_route_points() -> Array[Vector2]:
	var longest: Array = []
	for branch in _city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(EventScheduler.WalkSiting._cell_centre(_city.map, longest[i]))
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
## (`EventScheduler._counts_against_the_line`; inbox #684 in coral-lark), so the walk down the longest route puts it
## down in every city. The suite's own city is walked in full; the others are asked the one question
## the walk asks, `WalkSiting.ahead_of()` from points along the longest route, without walking, which
## keeps six cities as cheap as one. A city that fails fails here rather than being skipped.
func _test_day_eleven_answers_at_any_live_mast(t) -> void:
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var routed_on := [-1]
	var missed: Array[int] = []
	for seed_value: int in DAY_ELEVEN_SEEDS:
		_build_city(t, seed_value)
		if seed_value == DAY_ELEVEN_SEEDS[0]:
			_with_clean_run(func() -> void: _answer_day_eleven_at_any_live_mast(t, seed_value, routed_on))
			if routed_on[0] < 0:
				missed.append(seed_value)
			continue
		_with_clean_run(func() -> void:
			GameState.attempt_spend.scars = []
			var read := _read_the_mark_on(t, 11, seed_value)
			if not _a_mast_can_be_sited_along_her_route():
				missed.append(seed_value)
			(read[2] as Stroller).free()
			(read[0] as ResistanceDirector).free())
	t.check(missed.is_empty(), "the rigged mast has a place on her route in every city of %s (not in %s)"
			% [DAY_ELEVEN_SEEDS, missed])
	GameState.attempt_spend.scars = saved_scars
	GameState.attempt_spend.city_state = saved_state

## Whether `WalkSiting.ahead_of()` finds the routed mast a place from some point along the day's
## longest route, heading along it: the question `_walk_until_the_route_mast()` answers by walking.
func _a_mast_can_be_sited_along_her_route() -> bool:
	var siting: EventScheduler.WalkSiting = _city.events.ahead._siting
	var def: EventDef = _city.events.ahead._director.route_row(EventCatalogue.mast().id)
	var band: Vector2 = _city.events.ahead._director._siting_band()
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
	GameState.attempt_spend.scars = []
	var read := _read_the_mark_on(t, 11, seed_value)
	var director: ResistanceDirector = read[0]
	var player: Stroller = read[2]
	var step := director.current_step()
	var near := director._mast_id
	t.check(step != null and near != "", "day 11's task is on offer at the mast near the mark")
	var before := [director._arrow_key, director._mast_id, director.contact_position()]
	var asked := director.red_arrow_target()
	t.check(asked == director.contact_position() and director._arrow_nearest_next == null
			and [director._arrow_key, director._mast_id, director.contact_position()] == before,
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
	for target in director._arrow_candidates(step):
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
			and director._mast_id == near,
			"before the next choice the arrow and task still point at the near mast")
	director.tick(STEP)
	t.check(director.red_arrow_target().distance_to(third_foot) < 1.0
			and director._mast_id == third,
			"following her between masts moves the task to the one she actually touches")
	director._contact._physics_process(STEP)
	t.check(step.index in GameState.resistance.completed_steps,
			"touching the third mast completes the task")
	var silenced := {}
	for plan in _city.events.plans():
		if plan.mast_id in [near, routed, third]:
			silenced[plan.mast_id] = plan.silenced
	t.check(silenced.get(third, false) and not silenced.get(near, true)
			and not silenced.get(routed, true),
			"and silences the mast she touched, not the near or the routed one (%s)" % silenced)
	var scarred := []
	for scar: Dictionary in GameState.attempt_spend.scars:
		if String(scar["id"]) == EventScheduler.SILENCED_MAST:
			scarred.append(scar["position"])
	t.check(scarred.size() == 1 and (scarred[0] as Vector2).distance_to(third_foot) < 1.0,
			"and the one scar is that mast's foot")
	player.free()
	director.free()

## A single-target task keeps its arrow on its contact exactly, retargeting or not.
func _test_a_single_target_arrow_stays_on_its_contact(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		GameState.resistance.completed_steps = _completed_through(2)
		var van := _director(t)
		van.start_day(7, _rng(7, "resistance"), 300.0)
		van._on_contact_completed(3)
		van.retarget_the_arrow()
		t.check(van.red_arrow_target() == van.contact_position()
				and van.red_arrow_target() != Vector2.INF,
				"the van has the one arrow, on its contact")
		van.free())

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
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var saved_progress := GameState.resistance.progress
	var saved_sabotage := GameState.resistance.sabotage_done
	var checked := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		_build_city(t, seed_value)
		_with_clean_run(func() -> void:
			for day: int in [7, 9, 11, 12, Tuning.RUN_LENGTH_DAYS]:
				GameState.attempt_spend.scars = []
				GameState.resistance.progress = Tuning.RESISTANCE_GOAL \
						if day == Tuning.RUN_LENGTH_DAYS else 0
				GameState.resistance.sabotage_done = false
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
				director.free())
	GameState.attempt_spend.scars = saved_scars
	GameState.attempt_spend.city_state = saved_state
	GameState.resistance.progress = saved_progress
	GameState.resistance.sabotage_done = saved_sabotage
	t.check(checked[0] > 0, "some task was put on offer (%d)" % checked[0])

## The finale on the test city in the real day order, the goal met: `[director, Vector2.INF, her
## rig]`, the shape `_read_the_mark_on()` answers, the finale having no mark.
func _start_the_finale(t, seed_value: int) -> Array:
	var day := Tuning.RUN_LENGTH_DAYS
	GameState.resistance.completed_steps = _all_but_the_finale()
	GameState.facts.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
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
			return director._rider.global_position if director._rider else Vector2.INF
		ResistanceSteps.TargetKind.DOOR:
			var nearest := Vector2.INF
			for body in _city.region_plan().door_bodies:
				if body.def.redetains and (nearest == Vector2.INF or body.position.distance_to(
						director.contact_position()) < nearest.distance_to(director.contact_position())):
					nearest = body.position
			return nearest
		ResistanceSteps.TargetKind.MAST:
			return _city.events.mast_foot(director._mast_id)
		ResistanceSteps.TargetKind.PARK_SWING:
			var layout: BlockLayout = _city.map.block_layouts.get(CityGenerator.swing_park(_city.map))
			return _city.map.swing_position(layout.playground) if layout else Vector2.INF
		ResistanceSteps.TargetKind.STATION_DOOR:
			var door := _city.map.power_station_door_position()
			return Vector2(door.x, door.y - Tuning.TILE_SIZE)
	return Vector2.INF

## feathery-marmot, day 12 — *"Not the drawn swing. Place an ellipse at its base. That's the area to
## touch"*. The swing's contact is touched by her body overlapping `ResistanceDirector.swing_base()`
## round the swing's base, the extent of the shadow the frame casts there
## (`Prop._playground_frame_shape()`): from eight bearings, standing with her edge a pixel inside the ellipse's
## outline completes it, at each side and each corner, and standing two pixels clear of it does not.
## Before, a 36px circle round the swing's tile centre counted.
func _test_the_swings_touch_is_the_ellipse_at_its_base(t) -> void:
	var contact := ContactPoint.new()
	contact.setup(_perform_on(12), Vector2(500.0, 500.0))
	contact.touch_ellipse = ResistanceDirector.swing_base()
	t.add_child(contact)
	contact.set_physics_process(false)
	var semi := ResistanceDirector.swing_base()
	var shadow := Prop._playground_frame_shape()
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
