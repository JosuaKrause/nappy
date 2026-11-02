extends "res://tests/resistance_rig.gd"
## M188: a mark is never placed in an alley she cannot reach.

func run(t) -> void:
	_test_a_mark_is_never_placed_in_an_alley_she_cannot_reach(t)
	if _city != null:
		_city.free()

## downy-otter, "a mark should never be placed in an alley that is not reachable (ie sealed off)"
## (olive-koala, statement 9). The claim above already holds — `_pick_reachable()` redraws
## against `_reachable_from_home()`, closures and hard seals alike, with a nearest-legal fallback
## — but `_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground` only ever asked it
## of the three seeds `tests/probes/m184_route_timing.gd` times, tied to that probe on purpose
## (its own doc). This asks the mark half alone, over four more seeds — deliberately not
## overlapping that test's own three, which is the item's own "a test over many seeds states it"
## — reusing `_day_reachability()`/`_stands_on_legal_ground()` rather than a second implementation
## of either. A full-city-generation sweep is the expensive kind (M125's own finding, cut from six
## seeds to three for the same reason), so this stays at four rather than growing further.
const MARK_REACHABILITY_SWEEP_SEEDS: Array[int] = [2295276695, 291862120, 314159, 555555]

func _test_a_mark_is_never_placed_in_an_alley_she_cannot_reach(t) -> void:
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		var checked := 0
		for seed_value in MARK_REACHABILITY_SWEEP_SEEDS:
			var city: City = RunCity.of_the_run(CITY_SCENE)
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day in REACHABILITY_SWEEP_DAYS:
				GameState.resistance.completed_steps = []
				GameState.resistance.failed_steps = []
				GameState.facts.completed_resistance_alley_tiles.clear()
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
				# `main.gd`'s own order: she is placed and ticks once before this checks anything —
				# see `_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground`'s own
				# doc for why the tick is load-bearing.
				var player := _rig_player(t, city.map.doorstep_world_position())
				director.use_player(player)
				director.tick(STEP)

				var mark_step := director.current_step()
				if mark_step != null and mark_step.is_pickup:
					checked += 1
					var region_plan: RegionPlanner.RegionPlan = city.region_plan()
					var walled_alleys: Array[Rect2i] = \
							region_plan.alley_walls if region_plan else []
					var reachability := _day_reachability(city)
					var grid: ReachabilityGrid = reachability[0]
					var blocked: Dictionary = reachability[1]
					var reached: Dictionary = reachability[2]
					var mark_tile := city.map.world_to_tile(director.contact_position())
					t.check(_stands_on_legal_ground(city.map, mark_tile, walled_alleys, false,
							grid, blocked, reached),
							("seed %d day %d: the mark stands on walkable, unobstructed, " +
							"reachable ground at %s, never a sealed or closed alley")
							% [seed_value, day, mark_tile])
				player.free()
				director.free()
			city.free()
		GameState.facts.completed_resistance_alley_tiles = saved_tiles
		t.check(checked > 0, "the sweep actually checked something (%d)" % checked))
