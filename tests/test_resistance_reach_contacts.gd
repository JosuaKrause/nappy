extends "res://tests/resistance_rig.gd"
## M188: every mark and contact stands on ground she can reach, and a queued mast is never generated inside a lethal field.

func run(t) -> void:
	_test_a_queued_mast_is_never_generated_inside_a_lethal_field(t)
	# This one reads the city standing, the third of the seeds the day-11 mast test builds.
	_build_city(t, 1234567)
	_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground(t)
	_test_pick_reachable_only_replaces_the_candidate_the_new_check_rejects(t)
	if _city != null:
		_city.free()

## feathery-marmot, day 11's queued mast — *"if there is a mast queued up that will be the next
## event to be generated"* (quiet-yak, inbox #503). On the test city's day 11, a stationary `reversing_lorry`
## (hard_fail, 175px field) is planned on a sidewalk, and the mast is queued with only the sidewalk
## inside that field to stand on: the scheduler's acceptance refuses every tile, so no mast is
## generated, as `_room_around()` refuses any row inside a lethal field ("Nothing else happens
## inside a lethal event's field"). Offered sidewalk well clear of it, the mast is generated, joins
## the day's plan under an added id, and has room by the same rule. A mast put down where the
## director pointed, as before, fails the first half.
func _test_a_queued_mast_is_never_generated_inside_a_lethal_field(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
	_with_clean_run(func() -> void:
		var read := _read_the_mark_on(t, 11, SEED)
		var director: ResistanceDirector = read[0]
		var player: Stroller = read[2]
		var map := _city.map
		var lorry_def := EventCatalogue.by_id("reversing_lorry")
		var walled := _walled_alleys()
		var lorry_tile := Vector2i(-1, -1)
		for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
			if SpawnSiting.is_legal_ground(map, tile, walled) and not map.is_obstructed(tile) \
					and map.tile_to_world(tile).distance_to(map.doorstep_world_position()) > 600.0:
				lorry_tile = tile
				break
		var lorry := EventScheduler.Planned.new(lorry_def, map.tile_to_world(lorry_tile))
		lorry.role = GameEnums.BlockerRole.FRICTION
		_city.events.streaming._plans.append(lorry)
		var inside: Array[Vector2i] = []
		var clear: Array[Vector2i] = []
		for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
			if not SpawnSiting.is_legal_ground(map, tile, walled) or map.is_obstructed(tile):
				continue
			var gap := map.tile_to_world(tile).distance_to(lorry.position)
			if gap > EventScheduler.EVENT_SPACING_ANY and gap < lorry_def.field_reach() - Tuning.TILE_SIZE:
				inside.append(tile)
			elif gap > lorry_def.field_reach() + 600.0 and gap < lorry_def.field_reach() + 900.0:
				clear.append(tile)
		t.check(not inside.is_empty() and not clear.is_empty(),
				"there is sidewalk inside the lorry's field and well clear of it (%d, %d)"
				% [inside.size(), clear.size()])
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var refused := _city.events.queue_a_mast(inside, rng)
		t.check(refused == null, "offered only ground inside a lethal field, no mast is generated")
		var placed := _city.events.queue_a_mast(clear, rng)
		t.check(placed != null and placed.mast_id.begins_with("added-")
				and placed in _city.events.plans(),
				"offered ground clear of it, a mast is generated into the day's plan")
		if placed:
			var others := _city.events.plans().filter(
					func(plan: EventScheduler.Planned) -> bool: return plan != placed)
			t.check(EventScheduler._room_around(placed, others) != -INF,
					"and it has room by the scheduler's own spacing")
		player.free()
		director.free())
	GameState.attempt_spend.city_state = saved_state

const REACHABILITY_SWEEP_SEEDS: Array[int] = [4242, 90210, 1234567]

## Every mark and every contact a task activates stands on walkable, unobstructed ground — day 8's,
## which stands on the burnt building's door, is touched from the ground in front of it — swept
## over days 6-13 and the seeds the route rig timed, through the real day order (`City.start_day()`,
## then `EventManager.start_day()`, then `ResistanceDirector.start_day()`, then one `_process()`
## tick with her standing at the doorstep) so `CityMap.obstructed_tiles` is the day's real record
## rather than an empty one, and a mark that only moves once she is actually in the world is
## checked where she would actually find it.
##
## **The one `_process()` tick is load-bearing, not a nicety.** A `--day 9 --seed 4242 --route
## mark,task,calm,home --no-title` boot of the real game showed this directly: day 9's mark rolled
## legal ground at dawn (108,67), but she starts at the doorstep, more than `NOTICE_RADIUS` from
## it, so `_track_sight_and_reposition()` relocates it on the very first frame — before this sweep
## ever existed, straight onto an obstructed tile, (79,90), that `_pick_reachable()`'s own dawn
## check never had a chance to refuse because the draw itself was never the problem. A sweep that
## only asked `start_day()` was asking a question the real game never actually asks: `main.gd`'s
## own order (`_resistance.start_day()`, then `_player.reset_at(start_at)`, then the tree's first
## `_process()`) means a played mark is always checked here at frame 0, standing wherever the
## relocation left it, not wherever the dawn roll did. Skipping it also drew the day's RNG stream
## one guard-placement short of a real day: `_move_the_mark()` re-rolls the guard through the same
## `_rng` the day's later placements share, so a sweep that never relocated the mark answered
## every placement *after* it — the task's own included — from a stream a
## real boot never sees, which is why an earlier sweep's own "moved" list did not match the route
## rig's real cases at all.
##
## **Each day is asked fresh**, the same "no history, just this day" state `--day N`
## (`DevFlags.day_override()`) boots into — `GameState.start_run()` runs before `GameState.header.day` is
## set, so a rig timing day 9 alone never played days 6-8 first — matching every other single-day
## placement test in this file (`_test_the_door_task_sits_at_a_region_door` and others call
## `director.start_day()` for one chosen day with no days before it either).
##
## Days 10 and 11 offer no mark (`ResistanceSteps._build()`'s own comment on the later slice they
## wait on) and are swept anyway rather than skipped, so the loop's own day range reads as "days
## 6-13" without a silent gap; `current_step() == null` there is expected and checked nothing.
##
## Named cases this sweep carries (`docs/TODO.md`, M188): day 9 seed 4242 (a mark relocated onto
## obstructed ground, and then — once that was fixed — onto ground the day's own obstruction sealed
## off from home), days 7 and 8 seed 90210 (a contact's offset landing inside a building), and day 7
## seed 1234567 (a mark on good ground the day's whole obstruction seals off from home, item 3) are
## all within this sweep's own days and seeds, so the general loop below checks them along with
## everything else rather than as a separate case.
func _test_every_mark_and_contact_stands_on_walkable_unobstructed_ground(t) -> void:
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		var saved_scars := GameState.attempt_spend.scars.duplicate()
		var checked := 0
		for seed_value in REACHABILITY_SWEEP_SEEDS:
			var city: City = RunCity.of_the_run(CITY_SCENE)
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day in REACHABILITY_SWEEP_DAYS:
				GameState.resistance.completed_steps = []
				GameState.resistance.failed_steps = []
				GameState.facts.completed_resistance_alley_tiles.clear()
				# No history, like `--day N`: day 8 with no recorded scar records one for its
				# task, and a scar from another seed's city must not stand in this one's.
				GameState.attempt_spend.scars = []
				var closure_state := CityState.new()
				closure_state.begin_day(city.map.block_plans, day)
				city.start_day(closure_state, day, _production_rng(seed_value, day, "closures"))
				city.events.start_day(DaySpec.for_day(day), _production_rng(seed_value, day, "events"), [],
						city.map.doorstep_world_position())

				var director := ResistanceDirector.new()
				t.add_child(director)
				director.set_process(false)
				director.setup(city, city.map)
				director.start_day(day, _production_rng(seed_value, day, "resistance"),
						Tuning.day_length(day))
				# `main.gd`'s own order: the player is placed at the doorstep only after
				# `_resistance.start_day()` returns, and the tree's first `_process()` runs after
				# that — so a mark checked before this tick is checked somewhere she never sees.
				var player := _rig_player(t, city.map.doorstep_world_position())
				director.use_player(player)
				director.tick(STEP)

				var region_plan: RegionPlanner.RegionPlan = city.region_plan()
				var walled_alleys: Array[Rect2i] = region_plan.alley_walls if region_plan else []
				var reachability := _day_reachability(city)
				var grid: ReachabilityGrid = reachability[0]
				var blocked: Dictionary = reachability[1]
				var reached: Dictionary = reachability[2]
				var mark_step := director.current_step()
				if mark_step != null:
					checked += 1
					var mark_tile := city.map.world_to_tile(director.contact_position())
					t.check(_stands_on_legal_ground(city.map, mark_tile, walled_alleys, false,
							grid, blocked, reached),
							("seed %d day %d: step %d's mark stands on walkable, unobstructed, " +
							"reachable ground at %s") % [seed_value, day, mark_step.index, mark_tile])

					director._on_contact_completed(mark_step.index)
					var task_step := director.current_step()
					if task_step != null:
						checked += 1
						var task_tile := city.map.world_to_tile(director.contact_position())
						# Every contact stands on its item — a door on a wall, a van or a mast on its
						# own body's tile — so what is asked is that she can touch it from ground
						# she can stand on. Day 9's is crossed instead: its gatehouse stands on the
						# door's own held pavement, which is asked as before.
						if task_step.target_kind == ResistanceSteps.TargetKind.DOOR:
							t.check(_stands_on_legal_ground(city.map, task_tile, walled_alleys,
									true, grid, blocked, reached),
									("seed %d day %d: step %d's gatehouse stands on walkable, " +
									"reachable ground at %s") % [seed_value, day, task_step.index,
									task_tile])
						else:
							t.check(_touched_from_standable_ground(director,
									director.contact_position(), city.map),
									("seed %d day %d: step %d's contact at %s is touched from " +
									"walkable, unobstructed, reachable ground") % [seed_value, day,
									task_step.index, task_tile])
				player.free()
				director.free()
			city.free()
		GameState.facts.completed_resistance_alley_tiles = saved_tiles
		GameState.attempt_spend.scars = saved_scars
		t.check(checked > 0, "the sweep actually checked something (%d)" % checked))

## The first `RandomNumberGenerator.seed` whose first `randi_range(0, pool_size - 1)` answers
## `wanted_index` — found by trying seeds in order rather than inverted by hand, since nothing here
## needs a *particular* seed, only one that reproduces a chosen draw so the next test can control
## which pool entry a fresh RNG picks.
func _seed_that_draws(pool_size: int, wanted_index: int) -> int:
	for seed_value in range(1, 100000):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if rng.randi_range(0, pool_size - 1) == wanted_index:
			return seed_value
	return -1

## **A placement that is valid today stays exactly where it is; only a candidate the new check
## rejects is replaced.** `_pick_reachable()` draws one index over the whole pool exactly as it did
## before `is_obstructed()` was ever checked, and only asks the question of the tile the draw
## actually landed on — so a pool with nothing obstructed in it, or a draw that lands on a tile
## that never was, answers exactly what a bare `pool[rng.randi_range(...)]` would.
##
## Proven directly rather than inferred from a sweep's own before/after numbers: two real, legal
## alley tiles as the whole pool, one seed engineered to draw each index first
## (`_seed_that_draws()`). Neither candidate obstructed draws candidate_a exactly; candidate_a
## obstructed replaces it with candidate_b, the pool's only other legal tile, never a third,
## nonexistent one; and the seed that would have drawn candidate_b anyway still draws it,
## unmoved by an obstruction on a *different* candidate it was never going to answer with.
func _test_pick_reachable_only_replaces_the_candidate_the_new_check_rejects(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		# Neither candidate this test picks may already be "used" (M177) — an unrelated leftover
		# would shrink the pool below the two entries every check below assumes.
		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		GameState.facts.completed_resistance_alley_tiles.clear()

		var legal: Array[Vector2i] = []
		for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
			if _city.map.is_walkable(tile) and not _city.map.is_closed(tile) \
					and not _city.map.is_held_at(tile) and not _city.map.is_on_home_block(tile):
				legal.append(tile)
			if legal.size() >= 2:
				break
		t.check(legal.size() >= 2, "the test city has at least two legal alley candidates")
		if legal.size() < 2:
			GameState.facts.completed_resistance_alley_tiles = saved_tiles
			return

		var candidate_a: Vector2i = legal[0]
		var candidate_b: Vector2i = legal[1]
		var candidates: Array[Vector2i] = [candidate_a, candidate_b]
		var seed_for_a := _seed_that_draws(candidates.size(), 0)
		var seed_for_b := _seed_that_draws(candidates.size(), 1)

		var director := _director(t)
		var rng_a := RandomNumberGenerator.new()
		rng_a.seed = seed_for_a
		t.check(director._pick_reachable(candidates, rng_a) == _city.map.tile_to_world(candidate_a),
				"neither candidate obstructed: the draw lands exactly where it always would")

		var obstruction: Array[Vector2i] = [candidate_a]
		_city.map.obstruct_tiles(self.get_instance_id(), obstruction)
		var rng_a2 := RandomNumberGenerator.new()
		rng_a2.seed = seed_for_a
		t.check(director._pick_reachable(candidates, rng_a2) == _city.map.tile_to_world(candidate_b),
				"candidate_a obstructed: the same draw is replaced by the pool's only other " +
				"legal candidate")

		var rng_b := RandomNumberGenerator.new()
		rng_b.seed = seed_for_b
		t.check(director._pick_reachable(candidates, rng_b) == _city.map.tile_to_world(candidate_b),
				"a draw whose own candidate was never obstructed still lands exactly there, " +
				"unmoved by an obstruction on the other one")

		_city.map.release_obstruction(self.get_instance_id())
		GameState.facts.completed_resistance_alley_tiles = saved_tiles
		director.free())
