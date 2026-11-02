extends "res://tests/resistance_rig.gd"
## M188: the narrow targets are reachable on their day, and a task is placed near its mark.

func run(t) -> void:
	_test_a_task_is_placed_near_its_mark(t)
	_test_the_narrow_targets_are_reachable_on_their_day(t)
	if _city != null:
		_city.free()

## The same three seeds `tests/probes/m184_route_timing.gd` times days 6-13 against.
## feathery-marmot, "a task's target is near its mark" — *"the van should spawn close to the mark
## not across the city"* · *"this applies to almost all tasks"* (minty-hedgehog, statement 3). On
## three cities, each day whose task is placed rather than fixed — day 6's man shouting, day 7's
## van, day 8's burnt building on a run with no day-3 fire, day 11's mast, day 13's roadblock — is
## planned the way a played day is and its mark read standing on it, the screen her view around
## her: the task lands where one of her paths first reaches the edge of a
## `ResistanceDirector.NEAR_THE_MARK` (576px) circle round her — worked out here by its own walk
## over the day's obstruction (`_edge_of_her_circle()`) — or the director says nothing on the edge
## qualified; day 11's mast is one her paths reach inside or on that circle; and a task put in the
## world is put outside her view. *("create a circle around the current player position with the
## radius of the desired distance -- then follow the path until it reaches the edge of the
## circle".)* Before, it was drawn anywhere within 576px as the crow flies.
func _test_a_task_is_placed_near_its_mark(t) -> void:
	var saved_scars := GameState.attempt_spend.scars.duplicate()
	var saved_state := GameState.attempt_spend.city_state
	var checked := [0]
	var fell_back := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		_build_city(t, seed_value)
		_with_clean_run(func() -> void:
			for day: int in [6, 7, 8, 11, 13]:
				GameState.attempt_spend.scars = []
				var read := _read_the_mark_on(t, day, seed_value)
				var director: ResistanceDirector = read[0]
				var mark: Vector2 = read[1]
				var player: Stroller = read[2]
				var step := director.current_step()
				t.check(step != null and not step.is_pickup,
						"seed %d day %d: reading the mark puts its task on offer" % [seed_value, day])
				if step != null and not step.is_pickup:
					checked[0] += 1
					var mast := step.target_kind == ResistanceSteps.TargetKind.MAST
					var target := director.contact_position() if mast or director._rider == null \
							else director._rider.global_position
					var circle := _edge_of_her_circle(director, mark)
					# Day 13's roadblock is offered the ground her paths reach out to each of
					# `ROADBLOCK_WIDER_REACH` in turn where the day's rules refuse the whole edge
					# (`_place_the_roadblock_near()`), and that is not a fallback.
					var wider := director._paths_reach_between(mark, ResistanceDirector.NEAR_THE_MARK,
							ResistanceDirector.ROADBLOCK_WIDER_REACH.back()) if day == 13 else {}
					var on_it := false
					var centre := _city.map.world_to_tile(target)
					for step_to: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT,
							Vector2i.UP, Vector2i.DOWN]:
						var tile := centre + step_to
						if circle[0].has(tile) or (mast and circle[1].has(tile)) or wider.has(tile):
							on_it = true
					t.check(on_it or director._fell_back,
							("seed %d day %d: the task stands where her path reaches the circle's " +
							"edge (day 13: or the wider reach its roadblock is offered next), or " +
							"nothing there qualified") % [seed_value, day])
					if director._fell_back:
						fell_back[0] += 1
					if not mast:
						t.check(not _would_show(ResistanceDirector.TASK_BOX, target),
								"seed %d day %d: and was put in the world outside her view"
								% [seed_value, day])
				player.free()
				director.free())
	GameState.attempt_spend.scars = saved_scars
	GameState.attempt_spend.city_state = saved_state
	t.check(checked[0] > 0 and fell_back[0] * 3 < checked[0],
			"tasks were placed (%d), most on the edge rather than by the fallback (%d)"
			% [checked[0], fell_back[0]])

## Cities whose narrow targets the day's own seals and bodies could ring, found by
## `tests/probes/m181_resistance_targets.gd`'s wide run: each had a last-night destination cut off
## from home before the day kept a route to it. Chosen for what they would catch rather than for
## luck: the guarantee is a rule about every day, and these are days the rule has work to do on.
const NARROW_TARGET_SEEDS: Array[int] = [196838, 355218, 323542, 252271]

## **The day keeps a route to its narrow resistance target** (`docs/CITY.md`, "Guarantees"): day
## 9's door, day 12's swing and the power station's front door, planned through the real day
## order —
## `City.start_day()`, `EventManager.start_day()`, then the director's own `_place()` of the day's
## step — and asked of an independent flood (`_day_reachability()`). Two things per day: some tile
## of the pool is legal, unobstructed and reachable from home, and the tile the director actually
## picks is one of them.
##
## The finale's day plans at full heat, since the finale is only offered once the goal is met and
## the heat is what the scheduler reads; days 9 and 12 plan cold, each asked fresh as `--day N`
## boots it.
##
## **Day 12 owes a second park as well**: some calm area other than the swing's, clean — no field
## the day planned reaching its ground — and reachable from home under the same flood, which is
## where she settles the baby once the swing's park is taken.
func _test_the_narrow_targets_are_reachable_on_their_day(t) -> void:
	_with_clean_run(func() -> void:
		var checked := 0
		for seed_value in NARROW_TARGET_SEEDS:
			var city: City = RunCity.of_the_run(CITY_SCENE)
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day: int in [9, 12, Tuning.RUN_LENGTH_DAYS]:
				var step := ResistanceSteps.narrow_target_on(day)
				t.check(step != null, "day %d has a narrow resistance target" % day)
				if not step:
					continue
				GameState.resistance.progress = Tuning.RESISTANCE_GOAL if step.needs_goal else 0
				var state := CityState.new()
				state.begin_day(city.map.block_plans, day)
				city.start_day(state, day, _production_rng(seed_value, day, "closures"))
				city.events.start_day(DaySpec.for_day(day), _production_rng(seed_value, day, "events"), [],
						city.map.doorstep_world_position())
				var region_plan: RegionPlanner.RegionPlan = city.region_plan()
				var pool := ResistanceSteps.target_candidates(step, city.map, region_plan)
				var walled: Array[Rect2i] = region_plan.alley_walls if region_plan else []
				var allow_held := ResistanceSteps.stands_on_held_ground(step)
				var reachability := _day_reachability(city)
				var grid: ReachabilityGrid = reachability[0]
				var blocked: Dictionary = reachability[1]
				var reached: Dictionary = reachability[2]
				var reachable := 0
				for tile in pool:
					if _stands_on_legal_ground(city.map, tile, walled, allow_held, grid, blocked,
							reached):
						reachable += 1
				checked += 1
				t.check(reachable > 0,
						("seed %d day %d: some tile of step %d's target is legal, unobstructed " +
						"and reachable from home (%d of %d)")
						% [seed_value, day, step.index, reachable, pool.size()])
				if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
					t.check(_a_second_clean_park_is_reached(city, grid, blocked, reached),
							"seed %d day 12: a clean calm area besides the swing's is reachable"
							% seed_value)

				var director := ResistanceDirector.new()
				t.add_child(director)
				director.set_process(false)
				director.setup(city, city.map)
				var at := director._place(step, _production_rng(seed_value, day, "resistance"))
				var at_tile := city.map.world_to_tile(at) if at != Vector2.INF else Vector2i(-1, -1)
				# The station's contact stands on its door, on the facade, and is touched from the
				# pavement straight below it, which is the ground asked about.
				if step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR and at != Vector2.INF:
					at_tile = city.map.world_to_tile(at + Vector2.DOWN * Tuning.TILE_SIZE)
				t.check(at != Vector2.INF and _stands_on_legal_ground(city.map, at_tile, walled,
						allow_held, grid, blocked, reached),
						"seed %d day %d: step %d's contact stands on reachable ground at %s"
						% [seed_value, day, step.index, at_tile])
				director.free()
			city.free()
		t.check(checked > 0, "the sweep actually checked some day (%d)" % checked))

## Whether some calm area other than the day's swing park has calm ground reached under
## `_day_reachability()`'s flood and no field of the day's catalogue on it — the rows the day rolled
## (every one of them given a role) and the masts, which is what `_ensure_one_usable_park()` counts
## as spoiling; the seals and the region wall are the street's, and it does not.
func _a_second_clean_park_is_reached(city: City, grid: ReachabilityGrid, blocked: Dictionary,
		reached: Dictionary) -> bool:
	var swing := CityGenerator.swing_park(city.map)
	var catalogue: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if plan.role != GameEnums.BlockerRole.NONE or plan.mast_id != "":
			catalogue.append(plan)
	for block in city.map.calm_blocks:
		if block == swing:
			continue
		var rect := ClosurePlanner.calm_area_rect(city.map, block)
		if EventScheduler._is_spoiled(city.map, catalogue, rect):
			continue
		for tile in city.map.rect_tiles(rect):
			if Tile.is_calm(city.map.tile_at(tile)) and grid.reaches(tile, blocked, reached):
				return true
	return false
