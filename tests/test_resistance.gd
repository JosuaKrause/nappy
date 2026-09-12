extends RefCounted
## The resistance subquest: the step table, touch-completion, a perform contact riding on an
## `EventInstance`, the seeded guard, the expiring step, and the sabotage silencing the city.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_step_table(t)
	_test_step_selection(t)
	_test_the_finale_needs_the_legwork(t)
	_test_completing_a_pickup_sets_the_day_briefs_words(t)
	_test_touching_completes_a_pickup(t)
	_test_walking_away_leaves_it_untouched(t)
	_test_a_perform_contact_rides_on_its_instance(t)
	_test_a_perform_contact_sees_its_rider_finish(t)
	_test_placement_is_deterministic(t)
	_test_the_guard_is_seeded(t)
	_test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t)
	_test_a_mark_within_notice_radius_does_not_move(t)
	_test_a_seen_mark_never_moves_again(t)
	_test_the_guard_moves_with_the_mark_and_faces_away_from_her(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	_test_a_perform_contact_is_never_relocated(t)
	_test_a_perform_step_expires_when_its_rider_is_gone(t)
	_test_a_timed_step_expires(t)
	_test_completing_the_package_makes_the_pram_heavier(t)
	_test_starting_a_day_resets_the_package_flag(t)
	_test_the_sabotage_silences_the_city(t)

# ---------------------------------------------------------------- step table ---

func _test_step_table(t) -> void:
	var steps := ResistanceSteps.all()
	# Not `size() == 11`: `ResistanceSteps._build()` is a literal array, so a count of it is that
	# array restated and adding a task would mean editing both in lockstep. The guard here is only
	# that there is something to check, which is what stops the sweep below passing vacuously.
	t.check(not steps.is_empty(), "there is a step table to check")

	var previous_day := 0
	var previous_index := 0
	var performs := 0
	for step in steps:
		t.check(step.index == previous_index + 1, "step indices run consecutively from 1")
		t.check(step.first_day >= previous_day, "steps unlock in calendar order")
		t.check(step.placement.size() > 0 or step.district >= 0,
				"step %d knows where it goes" % step.index)
		if step.is_pickup:
			t.check(not step.grants_progress, "a pickup does not grant progress")
			t.check(step.task_event_id == "", "a pickup sits on a tile, not a rider")
		elif not step.needs_goal:
			t.check(step.task_event_id != "", "a perform step names what it rides on")
			performs += 1
		previous_index = step.index
		previous_day = step.first_day

	t.check(performs > Tuning.RESISTANCE_GOAL,
			"there are more perform steps than the goal needs, so one task can be missed")
	t.check(steps[steps.size() - 1].needs_goal, "the finale is the last step")
	t.check(steps[steps.size() - 1].first_day == Tuning.RUN_LENGTH_DAYS,
			"and it is on the last day")

func _test_step_selection(t) -> void:
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(1, none, none, false) == null,
			"nothing is on offer before the resistance exists")

	var first := ResistanceSteps.for_day(4, none, none, false)
	t.check(first != null and first.index == 1 and first.is_pickup,
			"day 4 offers the first chalk mark")

	var done: Array[int] = [1]
	t.check(ResistanceSteps.for_day(4, done, none, false) == null,
			"the mark done and the perform not yet open leaves nothing on offer")
	var second := ResistanceSteps.for_day(5, done, none, false)
	t.check(second != null and second.index == 2 and not second.is_pickup,
			"day 5 moves on to the perform half")

	# A step lost to its deadline is gone for the rest of the run.
	var failed: Array[int] = [2]
	var after_failure := ResistanceSteps.for_day(5, done, failed, false)
	t.check(after_failure == null, "a failed step is never offered again")
	var later := ResistanceSteps.for_day(6, done, failed, false)
	t.check(later != null and later.index == 3, "but the run carries on to the next task's mark")

func _test_the_finale_needs_the_legwork(t) -> void:
	var done: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, false) == null,
			"the finale is not offered to a player who has not earned it")
	var finale := ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, true)
	t.check(finale != null and finale.needs_goal, "and is offered to one who has")

## The day brief is the mechanism now, not a courtesy: miss the mark and there is nothing to
## read, because nothing else in the game ever says what a task wants.
func _test_completing_a_pickup_sets_the_day_briefs_words(t) -> void:
	_with_clean_run(func() -> void:
		var mark := ResistanceSteps.by_index(1)
		t.check(mark.is_pickup and mark.brief != "", "the first mark has words to give")

		GameState.complete_resistance_step(1, mark.grants_progress)
		t.check(GameState.pending_resistance_brief == mark.brief,
				"completing the pickup queues its words for the next day brief")

		GameState.pending_resistance_brief = ""
		var perform := ResistanceSteps.by_index(2)
		t.check(not perform.is_pickup and perform.brief == "",
				"a perform step has nothing further to say")
		GameState.complete_resistance_step(2, perform.grants_progress)
		t.check(GameState.pending_resistance_brief == "",
				"completing a perform does not queue anything"))

# --------------------------------------------------------------------- touch ---

var _player: Stroller
var _contact: ContactPoint

func _build_pickup(t, step_index: int) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)
	_player.global_position = Vector2.ZERO

	_contact = ContactPoint.new()
	_contact.setup(ResistanceSteps.by_index(step_index), Vector2.ZERO)
	t.add_child(_contact)
	_contact.set_physics_process(false)

func _teardown_contact() -> void:
	_contact.free()
	_player.free()

func _test_touching_completes_a_pickup(t) -> void:
	_build_pickup(t, 1)
	var completed: Array[int] = []
	_contact.completed.connect(func(index: int) -> void: completed.append(index))

	t.check(not _contact.is_done, "not done before she arrives")
	_contact._physics_process(STEP)
	t.check(_contact.is_done, "touching it completes it, instantly — there is no hold")
	t.check(completed == [1], "and reports which step it was, once")
	_teardown_contact()

func _test_walking_away_leaves_it_untouched(t) -> void:
	_build_pickup(t, 1)
	_player.global_position = Vector2(500.0, 0.0)
	_contact._physics_process(STEP)
	t.check(not _contact.is_done, "out of reach, nothing happens")
	_teardown_contact()

## The shared plumbing every task needs: a contact that rides on an `EventInstance` rather
## than sitting on a bare tile, and follows it if it moves.
func _test_a_perform_contact_rides_on_its_instance(t) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)

	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2(300.0, 0.0))
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(2), instance, Vector2.ZERO)
	t.add_child(contact)
	contact.set_physics_process(false)

	_player.global_position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(not contact.is_done, "out of reach of where the rider is now")

	# The rider moves; the contact follows it rather than staying where it started.
	instance.position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(contact.is_done, "and completes once she reaches wherever the rider has gone")

	contact.free()
	instance.free()
	_player.free()

func _test_a_perform_contact_sees_its_rider_finish(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("roadblock"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(6), instance, Vector2(90.0, 0.0))
	t.add_child(contact)
	contact.set_physics_process(false)

	t.check(contact.rider_alive(), "the rider starts alive")
	instance._finish()
	t.check(not contact.rider_alive(), "and rider_alive() sees it end")

	contact.free()
	instance.free()

# ------------------------------------------------------------------ director ---

var _city: City

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

func _with_clean_run(action: Callable) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_package := GameState.resistance_carrying_package
	var saved_brief := GameState.pending_resistance_brief
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false
	GameState.pending_resistance_brief = ""
	action.call()
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.resistance_carrying_package = saved_package
	GameState.pending_resistance_brief = saved_brief

func _completed_through(last_index: int) -> Array[int]:
	var done: Array[int] = []
	done.assign(range(1, last_index + 1))
	return done

## The whole design rests on the run being learnable: the alley that was safe on day 9 has
## to be safe on day 9 every time you replay that run — and the same is true of a perform
## step's own placement.
func _test_placement_is_deterministic(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var first := _director(t)
		first.start_day(4, _rng(4, "resistance"), 300.0)
		var where := first.contact_position()
		t.check(where != Vector2.INF, "day 4 puts a mark somewhere")
		t.check(_city.map.tile_type_at_world(where) == GameEnums.TileType.ALLEY,
				"and the chalk mark is in an alley")

		var second := _director(t)
		second.start_day(4, _rng(4, "resistance"), 300.0)
		t.close_to(second.contact_position().distance_to(where), 0.0,
				"and it is in the same alley every time", 0.01)

		GameState.completed_resistance_steps = _completed_through(1)
		var perform := _director(t)
		perform.start_day(5, _rng(5, "resistance"), 300.0)
		t.check(perform.current_step() != null and perform.current_step().index == 2,
				"day 5 offers the perform half")
		t.check(perform.contact_position() != Vector2.INF,
				"and it rides on a live instance rather than a bare tile")

		first.free()
		second.free()
		perform.free())

## *Always guarded* has to mean a survivable band, not a guaranteed lost day: a robber sits
## somewhere between 66px (30 + `ContactPoint.REACH`) and 176px (140 + `ContactPoint.REACH`)
## of every mark, seeded so the distance is the same every time this day is replayed.
func _test_the_guard_is_seeded(t) -> void:
	_seen_guard_distances = []
	_with_clean_run(func() -> void:
		var before := _director(t)
		before.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(before.current_step() == null, "nothing is offered before day 4")
		before.free()

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH
		var search := max_distance + 40.0

		for day in [4, 5, 6, 7]:
			GameState.completed_resistance_steps = _completed_through(day - 4)
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var at := director.contact_position()
			var guard := _find_robbery_near(at, search)
			t.check(guard != null, "day %d's mark is guarded" % day)
			var distance := guard.global_position.distance_to(at) if guard else -1.0
			if guard:
				t.check(distance >= min_distance - 0.5 and distance <= max_distance + 0.5,
						"day %d's guard sits in the 66-176px band" % day)
				_seen_guard_distances.append(distance)
			director.free()

			var replay := _director(t)
			replay.start_day(day, _rng(day, "resistance"), 300.0)
			var replay_guard := _find_robbery_near(replay.contact_position(), search)
			if guard and replay_guard:
				t.close_to(replay_guard.global_position.distance_to(replay.contact_position()),
						distance, "day %d's guard distance replays the same way" % day, 0.5)
			replay.free())

	var all_equal := true
	for distance in _seen_guard_distances:
		if not is_equal_approx(distance, _seen_guard_distances[0]):
			all_equal = false
	t.check(_seen_guard_distances.size() >= 2 and not all_equal,
			"the guard distance is not the same every day")

var _seen_guard_distances: Array[float] = []

func _find_robbery_near(at: Vector2, within: float) -> EventInstance:
	if at == Vector2.INF:
		return null
	for instance in _city.events.instances():
		if instance.def.id != "alley_robbery":
			continue
		if instance.global_position.distance_to(at) <= within:
			return instance
	return null

# ------------------------------------------------------------- re-placement ---
# Playtest 19 finding 6, in the player's own words: "if it was placed but never on screen it
# should count as not placed and be placed on the next alley the player comes close to."

## Same shape `_build_pickup` uses for a bare `ContactPoint` — a real `Stroller`, physics off,
## dropped straight into `player` group by its own `_ready()` so `ResistanceDirector` finds it
## the same way it would in the running game.
func _rig_player(t, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	return player

## The world position of an `ALLEY` tile more than `min_distance` from `at`, or `Vector2.INF`
## if the test city has none. Used to put her far enough from the mark that the re-placement
## rule has to fire.
func _alley_farther_than(min_distance: float, at: Vector2) -> Vector2:
	for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
		var world := _city.map.tile_to_world(tile)
		if world.distance_to(at) > min_distance:
			return world
	return Vector2.INF

func _test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(4, _rng(4, "resistance"), 300.0)
		var mark_at := director.contact_position()
		t.check(mark_at != Vector2.INF, "day 4 places the mark")

		# She stands exactly on a distant alley — the nearest reachable one to her is itself,
		# at distance 0, which is what makes the assertion below exact rather than approximate.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)

		Telemetry.begin_memory_log()
		director._process(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"an unseen mark moves to the alley she has just come near")

		var moved := false
		for line in Telemetry.current_log().lines:
			if line.contains("contact") and line.contains("moved to") \
					and line.contains("never seen"):
				moved = true
		t.check(moved, "and a contact telemetry line records the move")
		Telemetry.end_run()

		player.free()
		director.free())

func _test_a_mark_within_notice_radius_does_not_move(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(4, _rng(4, "resistance"), 300.0)
		var mark_at := director.contact_position()
		var mark_tile := _city.map.world_to_tile(mark_at)
		var player_at := mark_at + Vector2(60.0, 0.0)
		var player := _rig_player(t, player_at)

		# Not a vacuous check: there really is a nearer alley on offer, and the rule still
		# leaves the mark alone because she has not left its own radius yet.
		var nearer_distance := player_at.distance_to(mark_at)
		var found_nearer := false
		for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
			if tile == mark_tile:
				continue
			if player_at.distance_to(_city.map.tile_to_world(tile)) < nearer_distance:
				found_nearer = true
				break
		t.check(found_nearer, "the test city has a nearer alley to tempt the rule")

		director._process(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"within NOTICE_RADIUS of her own mark, nothing moves — not even to a nearer alley")

		player.free()
		director.free())

func _test_a_seen_mark_never_moves_again(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(4, _rng(4, "resistance"), 300.0)
		var mark_at := director.contact_position()
		director.set_sight(func(_p: Vector2) -> bool: return true)

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"seen on the very first frame, so it does not move even though she is far from it")
		director._process(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"and it stays put on every later frame too, however far she walks")

		player.free()
		director.free())

func _test_the_guard_moves_with_the_mark_and_faces_away_from_her(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(4, _rng(4, "resistance"), 300.0)
		var old_at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH
		var guards: Array[EventInstance] = []
		for instance in _city.events.instances():
			if instance.def.id == "alley_robbery" and not instance.is_finished:
				guards.append(instance)
		t.check(guards.size() == 1, "exactly one live guard exists once the mark has moved (%d)"
				% guards.size())

		var guard: EventInstance = guards[0]
		var distance := guard.global_position.distance_to(new_at)
		t.check(distance >= min_distance - 0.5 and distance <= max_distance + 0.5,
				"the new guard sits in the same 66-176px band as any other")

		var facing_away := (new_at - player.global_position).normalized()
		var to_guard := (guard.global_position - new_at).normalized()
		t.check(facing_away.dot(to_guard) >= -0.01,
				"and his bearing from the mark is on the half facing away from her")

		player.free()
		director.free())

## `docs/DECISIONS.md`, M100, "The guard robber is placed inside a building, where he is stuck for ever":
## `ResistanceDirector._draw_guard_position` redraws a bearing until the point is walkable, never
## on a held segment or the home block, rejecting rather than repairing — checked directly, over
## many seeds and many marks, rather than through a live guard instance: the geometry is the same
## draw whichever mark it is asked from, and this reaches far more of it than the seeded-run tests
## above sample. No `_city` is needed for the draw itself, so the director here is never added to
## the scene tree and is freed by hand.
func _test_the_guard_never_lands_inside_a_building(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	var unguarded := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-sweep:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			for _attempt in 3:
				checked += 1
				var guard_at := director._draw_guard_position(rng, mark, Vector2.INF,
						min_distance, max_distance)
				if guard_at == Vector2.INF:
					unguarded += 1
					continue
				var guard_tile := map.world_to_tile(guard_at)
				t.check(map.is_walkable(guard_tile),
						"seed %d: the guard for the mark at %s stands on walkable ground"
						% [seed_value, tile])
				t.check(not map.is_held_at(guard_tile) and not map.is_on_home_block(guard_tile),
						"seed %d: the guard for the mark at %s is not on held or home-block ground"
						% [seed_value, tile])
				var inside_a_building := false
				for rect in map.building_rects:
					if rect.has_point(guard_tile):
						inside_a_building = true
						break
				t.check(not inside_a_building,
						"seed %d: the guard for the mark at %s never stands inside a footprint"
						% [seed_value, tile])
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws, %d found no ground)"
			% [checked, unguarded])

## The stated fallback, exercised directly: a mark with nowhere walkable in its whole band draws
## `TRAP_DRAW_LIMIT` times and gives up rather than settling for a building — "no trap is better
## than a trap in a wall". Built from a real map's own tile grid, with every tile in the band
## forced to `BUILDING` first, so the draw genuinely has nowhere to land rather than merely being
## unlucky.
func _test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t) -> void:
	var map := CityGenerator.generate(13)
	var director := ResistanceDirector.new()
	director.setup(null, map)
	var mark_tile := Vector2i(20, 20)
	var mark := map.tile_to_world(mark_tile)
	# 8 tiles (256px) comfortably clears the 176px band's own far edge on every side.
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			map.set_tile(mark_tile + Vector2i(dx, dy), GameEnums.TileType.BUILDING)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var guard_at := director._draw_guard_position(rng, mark, Vector2.INF, 60.0, 176.0)
	t.check(guard_at == Vector2.INF,
			"a band with no walkable ground anywhere in it draws no guard at all")
	director.free()

## Item 4: the spawn kill named at the top of M100's queue has no fix of its own — items 1
## through 3 are supposed to make it impossible by construction, and this is what proves it.
## Nothing named `alley_robbery` — the catalogue's own placement, from `first_day` 8, or the
## resistance's guard trap, from `TRAP_FIRST_DAY` (4) — ever stands within lethal reach of the
## doorstep, over several seeds and every day either kind can appear.
##
## `reach` is computed from the row's own `inner_radius` (30px, the always-lethal zone around
## whichever one of them it is) and the trap's own `min_distance` (66px, how close a guard is
## ever placed to its mark) rather than a literal — the two named constants this bug was always
## about, added together as a generous rather than exact bound.
func _test_no_alley_robbery_stands_near_the_doorstep(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var reach: float = robbery.inner_radius + min_distance
	var checked := 0
	for seed_value in [4242, 90210, 2295276695, 291862120, 314159, 555555]:
		var map := CityGenerator.generate(seed_value)
		var doorstep := map.doorstep_world_position()
		var consumed: Array[String] = []
		for day in range(4, 15):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var events_rng := RandomNumberGenerator.new()
			events_rng.seed = hash("%d:events:%d" % [seed_value, day])
			for plan in EventScheduler.build_day(day, events_rng, map, consumed, [], [], tree):
				if plan.def.id != "alley_robbery" or not plan.is_placed():
					continue
				checked += 1
				t.check(plan.position.distance_to(doorstep) > reach,
						("seed %d day %d: no scheduled alley_robbery stands within lethal reach " +
						"of the doorstep") % [seed_value, day])

			var director := ResistanceDirector.new()
			director.setup(null, map)
			var mark_rng := RandomNumberGenerator.new()
			mark_rng.seed = hash("%d:mark:%d" % [seed_value, day])
			var mark_at := director._place(ResistanceSteps.by_index(1), mark_rng)
			if mark_at != Vector2.INF:
				checked += 1
				t.check(mark_at.distance_to(doorstep) > reach,
						"seed %d day %d: the chalk mark is not within lethal reach of the doorstep"
						% [seed_value, day])
				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d" % [seed_value, day])
				var guard_at := director._draw_guard_position(guard_rng, mark_at, Vector2.INF,
						min_distance, max_distance)
				if guard_at != Vector2.INF:
					checked += 1
					t.check(guard_at.distance_to(doorstep) > reach,
							"seed %d day %d: the guard trap is not within lethal reach of the doorstep"
							% [seed_value, day])
			director.free()
	t.check(checked > 0, "some (seed, day) actually placed something to check (%d)" % checked)

## The reported run, replayed exactly: seed 291862120, day 7. The chalk mark was offered far from
## the doorstep, the M78 "never-seen mark follows her" rule (`_track_sight_and_reposition`)
## relocated it on the very first frame because she starts the day standing at the doorstep, and
## the guard redrawn for the new mark left five separate attempts dead in under a second. Built
## through the real pipeline — `City.start_day`, then `EventManager.start_day`, then
## `ResistanceDirector.start_day` — rather than the data-level sweep above, so the M78 relocation
## actually runs the way it does in a played day.
func _test_playtest_55_seed_has_no_spawn_kill(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 291862120
		var day := 7
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = INF

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)

		var doorstep := city.map.doorstep_world_position()
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("%d:events:%d" % [seed_value, day])
		var consumed: Array[String] = []
		city.events.start_day(day, events_rng, consumed, doorstep)

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)
		var resistance_rng := RandomNumberGenerator.new()
		resistance_rng.seed = hash("%d:resistance:%d" % [seed_value, day])
		# No steps completed yet, which is what actually offers step 1's chalk mark on day 7 — a
		# player who has not yet been near it, exactly the reported run.
		director.start_day(day, resistance_rng, 300.0)
		t.check(director.current_step() != null and director.current_step().index == 1,
				"seed %d day %d: step 1's chalk mark is still on offer, as in the reported run"
				% [seed_value, day])

		var player := _rig_player(t, doorstep)
		director._process(STEP)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var reach: float = robbery.inner_radius + min_distance

		var mark_at := director.contact_position()
		if mark_at != Vector2.INF:
			t.check(mark_at.distance_to(doorstep) > reach,
					("seed %d day %d: the (possibly relocated) chalk mark is not within lethal " +
					"reach of the doorstep") % [seed_value, day])

		var robbers_checked := 0
		for instance in city.events.instances():
			if instance.def.id != "alley_robbery":
				continue
			robbers_checked += 1
			t.check(instance.global_position.distance_to(doorstep) > reach,
					("seed %d day %d: no alley_robbery instance (guard or scheduled) stands " +
					"within lethal reach of the doorstep") % [seed_value, day])
		t.check(robbers_checked > 0,
				"seed %d day %d: the reported run's guard exists to check (%d found)"
				% [seed_value, day, robbers_checked])

		player.free()
		director.free()
		city.free())

## PLAYTEST-57, "a chalk mark behind a barrier": `144s-attempt1-asked-1.png` shows the
## resistance's mark on an alley's paving behind a roadblock band across its mouth. Reproduced on
## the reported run's own seed, 2199579682, day 7 — `Tuning.REGION_WALL_FIRST_DAY`, the first day a
## wall can stand at all: `RegionPlanner.plan_day` walls several crossing alleys that day, off
## today's tree, and **every one of their tiles passed all three checks `_pick_reachable()` had
## before this fix** — `is_closed()` (about a `RoadClosure`, which this is not), `is_held_at()`
## (about a `StreetNetwork` segment, which an alley is never on) and `is_on_home_block()`. None of
## the three ever looks at a region wall, which is the whole of the escape. `CityMap.
## is_in_walled_alley()` is the fourth check that closes it.
func _test_a_walled_alley_escapes_no_other_check(t) -> void:
	var seed_value := 2199579682
	var day := 7
	var map := CityGenerator.generate(seed_value)
	var tree := RouteTree.for_day(map, day)
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	t.check(not region_plan.alley_walls.is_empty(),
			"seed %d day %d walls at least one crossing alley, or this test checks nothing"
			% [seed_value, day])

	var checked := 0
	for rect in region_plan.alley_walls:
		for tile in map.rect_tiles(rect):
			checked += 1
			t.check(not map.is_closed(tile) and not map.is_held_at(tile) \
					and not map.is_on_home_block(tile),
					("seed %d day %d: %s is inside a walled alley, and none of is_closed(), " +
					"is_held_at() or is_on_home_block() catches it — that gap is the reported bug")
					% [seed_value, day, tile])
			t.check(map.is_in_walled_alley(tile, region_plan.alley_walls),
					"seed %d day %d: %s is refused by the check that closes the gap"
					% [seed_value, day, tile])
	t.check(checked > 0, "some walled-alley tile was actually checked (%d)" % checked)

## The same reported seed and day, through the real pipeline `_test_playtest_55_seed_has_no_spawn_
## kill` uses — `City.start_day`, then `ResistanceDirector.start_day` — swept over many RNG draws
## per step rather than trusting the one draw the reported run happened to make: neither the mark
## nor its guard, from `TRAP_FIRST_DAY`, may ever land inside a walled-off crossing alley, on any
## draw.
func _test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 2199579682
		var day := 7
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)
		var walled_alleys := city.region_plan().alley_walls
		t.check(not walled_alleys.is_empty(),
				"seed %d day %d walls at least one crossing alley, or this test checks nothing"
				% [seed_value, day])

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH

		var attempts := 0
		for step in ResistanceSteps.all():
			if step.district >= 0:
				continue   # the finale sits in a district, never an alley
			for trial in 20:
				attempts += 1
				var mark_rng := RandomNumberGenerator.new()
				mark_rng.seed = hash("%d:mark:%d:%d:%d" % [seed_value, day, step.index, trial])
				var at := director._place(step, mark_rng)
				if at == Vector2.INF:
					continue
				var tile := city.map.world_to_tile(at)
				t.check(not city.map.is_in_walled_alley(tile, walled_alleys),
						"seed %d day %d step %d trial %d: the mark is not inside a walled alley"
						% [seed_value, day, step.index, trial])

				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d:%d:%d" % [seed_value, day, step.index, trial])
				var guard_at := director._draw_guard_position(guard_rng, at, Vector2.INF,
						min_distance, max_distance, walled_alleys)
				if guard_at == Vector2.INF:
					continue
				var guard_tile := city.map.world_to_tile(guard_at)
				t.check(not city.map.is_in_walled_alley(guard_tile, walled_alleys),
						"seed %d day %d step %d trial %d: the guard is not inside a walled alley either"
						% [seed_value, day, step.index, trial])
		t.check(attempts > 0, "some (step, trial) actually placed something to check (%d)" % attempts)

		director.free()
		city.free())

func _test_a_perform_contact_is_never_relocated(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(1)
		var director := _director(t)
		director.start_day(5, _rng(5, "resistance"), 300.0)
		t.check(director.current_step() != null and not director.current_step().is_pickup,
				"day 5 is a perform step, riding on the yeller rather than sitting on a mark")
		var at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		t.check(director.contact_position().distance_to(at) < 0.5,
				"a perform contact is never subject to the re-placement rule")

		player.free()
		director.free())

func _test_a_perform_step_expires_when_its_rider_is_gone(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(1)
		var director := _director(t)
		director.start_day(5, _rng(5, "resistance"), 300.0)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"day 5 offers the yeller perform step")
		var rider: EventInstance = director._rider
		t.check(rider != null, "the perform step rides on a live instance")

		rider._finish()
		director._process(0.1)
		t.check(director.current_step() == null, "and it is gone once the rider is")
		t.check(2 in GameState.failed_resistance_steps, "recorded as failed for the run")
		director.free())

## A window that closes when the poster crew's own instance is gone rather than by the day's
## clock — but the crew here never naturally finishes, so this exercises the fallback that
## does watch the clock: `deadline_fraction`, kept exactly as step 4 used it.
func _test_a_timed_step_expires(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(7)
		var timed := ResistanceSteps.by_index(8)
		t.check(timed.deadline_fraction > 0.0, "the wall is the timed perform step")

		var director := _director(t)
		director.start_day(11, _rng(11, "resistance"), 100.0)
		t.check(director.current_step() != null and director.current_step().index == 8,
				"the wall is on offer at the start")

		director._process(100.0 * timed.deadline_fraction * 0.5)
		t.check(director.current_step() != null, "and still on offer before the deadline")
		t.check(8 not in GameState.failed_resistance_steps, "nothing has failed yet")

		director._process(100.0 * timed.deadline_fraction)
		t.check(director.current_step() == null, "past the deadline it is gone")
		t.check(8 in GameState.failed_resistance_steps, "and recorded as failed for the run")
		director.free())

## E's cost is deferred and total rather than local: picking the package up does not cost the
## street it happened on, it makes every street after it dearer for the rest of the day.
func _test_completing_the_package_makes_the_pram_heavier(t) -> void:
	_with_clean_run(func() -> void:
		var somewhere := _city.map.tile_to_world(Vector2i(10, 10))
		var before := _city.decay_multiplier(somewhere)

		var director := _director(t)
		director._on_contact_completed(4)
		t.check(GameState.resistance_carrying_package, "picking up the package sets the flag")

		var after := _city.decay_multiplier(somewhere)
		t.close_to(after, before * Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER,
				"and every street after it decays slower for the rest of the day", 0.001)
		director.free())

func _test_starting_a_day_resets_the_package_flag(t) -> void:
	_with_clean_run(func() -> void:
		GameState.resistance_carrying_package = true
		var director := _director(t)
		director.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(not GameState.resistance_carrying_package,
				"a fresh attempt at a day has not picked it up yet")
		director.free())

## The whole subquest pays out in quiet. On the last walk home the masts stop, and the
## floor they have been holding under the meter since day 5 goes with them.
func _test_the_sabotage_silences_the_city(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(10)
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		GameState.sabotage_done = false
		t.check(GameState.sabotage_available(), "the finale is on offer")

		# A live mast, the way day 5 onwards leaves one.
		var mast := _city.events.spawn_extra(EventCatalogue.by_id("loudspeaker"),
				Vector2(400.0, 400.0))
		for i in int(round((mast.def.telegraph_time + 0.2) / STEP)):
			mast._process(STEP)
		var somewhere := Vector2(9000.0, 9000.0)
		t.check(mast.contribution_at(somewhere) > 0.0,
				"the mast reaches the far side of the city while it is on")

		var quiet: Array[bool] = []
		var handler := func() -> void: quiet.append(true)
		EventBus.city_went_quiet.connect(handler)

		var director := _director(t)
		director.start_day(Tuning.RUN_LENGTH_DAYS,
				_rng(Tuning.RUN_LENGTH_DAYS, "resistance"), 300.0)
		t.check(director.current_step() != null, "the last night has a contact")
		director._on_contact_completed(11)

		t.check(GameState.sabotage_done, "completing it does the sabotage")
		t.check(quiet.size() == 1, "and the city goes quiet, once")
		t.close_to(mast.contribution_at(somewhere), 0.0,
				"the mast contributes nothing afterwards")
		t.close_to(_city.events.total_excitement_at(somewhere), 0.0,
				"and there is no floor left anywhere")

		EventBus.city_went_quiet.disconnect(handler)
		director.free())
	_city.free()
