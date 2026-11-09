@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends "res://tests/resistance_rig.gd"
## M188: a relocated mark is never placed in an alley she cannot reach, and day 11 puts up a mast near the mark when none is near.

const ResistanceReads := preload("res://tests/resistance_reads.gd")

func run(t) -> void:
	_test_day_eleven_puts_up_a_mast_near_the_mark_when_none_is_near(t)
	_test_a_relocated_mark_is_never_placed_in_an_alley_she_cannot_reach(t)
	_free_city()

## feathery-marmot, day 11 — *"Now just add a new mast close by"* (the player, 2026-10-03, quiet-yak, inbox #486, on a
## mark with no live mast near it). On three cities, day 11 is planned the way a played day is and
## its mark read standing on it: where no planned mast stands where her paths reach in the circle,
## the task goes to a mast the scheduler has just generated near her (`EventManager.queue_a_mast()`)
## — a `loudspeaker` plan under `EventScheduler.added_mast_id()`, on the edge of the circle and out
## of her view — or, where the scheduler's acceptance refused all of it, the nearest live mast.
## Reaching it silences it and records its scar; day 14's sabotage (`silence_all_masts()`) puts
## that very plan out when it is lit again; and the next day's and the last night's masts, planned
## from the scars, stand it again at its own foot, silenced. Before, the task went to the nearest of
## the city's six masts, 1,377px and 3,948px away on two of these cities.
func _test_day_eleven_puts_up_a_mast_near_the_mark_when_none_is_near(t) -> void:
	var added := [0]
	var room_days := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		# A city and a run of its own for every seed: the scar the task leaves is this run's.
		_build_city_in_a_new_run(t, seed_value)
		var read := _read_the_mark_on(t, 11, seed_value)
		var director: ResistanceDirector = read[0]
		var mark: Vector2 = read[1]
		var player: Stroller = read[2]
		var circle := _edge_of_her_circle(director, mark)
		var site_near := false
		var reach := ResistanceReads.day_reachability(_city)
		# The task's mast, by the public link: the contact stands on its foot.
		var added_plan: EventScheduler.Planned = null
		for plan in _city.events.plans():
			if plan.def.id == "loudspeaker" and plan.mast_id.begins_with("added-") \
					and _city.events.mast_foot(plan.mast_id).distance_to(
					director.contact_position()) < 0.5:
				added_plan = plan
		for plan in _city.events.plans():
			if plan.def.id != "loudspeaker" or plan.mast_id.begins_with("added-") or plan.silenced:
				continue
			var foot_tile := _city.map.world_to_tile(plan.position)
			# The tile she touches it from: the first beside the foot she can stand on, the
			# order `_place_at_a_mast()` asks them in.
			for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := foot_tile + side
				if not SpawnSiting.is_legal_ground(_city.map, next,
						_walled_alleys()) or _city.map.is_obstructed(next) \
						or not ResistanceReads.reaches_home(reach, next):
					continue
				if circle[0].has(next) or circle[1].has(next):
					site_near = true
				break
		if not site_near and added_plan != null:
			added[0] += 1
			var mast_id := added_plan.mast_id
			var foot := _city.events.mast_foot(mast_id)
			t.check(foot != Vector2.INF and circle[0].has(_city.map.world_to_tile(foot)),
					"seed %d: the mast put up for the task stands where her path reaches the circle's edge"
					% seed_value)
			t.check(not _would_show(ResistanceDirector.TASK_BOX, foot),
					"seed %d: and out of her view" % seed_value)
			# Her touch on the task's contact, which silences the mast it stands at.
			director.contact().complete_now()
			var scarred := false
			for scar: Dictionary in _city.run.attempt_spend.scars:
				if String(scar["id"]) == EventScheduler.SILENCED_MAST \
						and (scar["position"] as Vector2).distance_to(foot) < 1.0:
					scarred = true
			t.check(scarred and added_plan.silenced,
					"seed %d: reaching it silences it and records its scar" % seed_value)
			# Day 14's sabotage: lit again, the added mast is put out by `silence_all_masts()`
			# with the others — it is that one mast's plan this asks about.
			t.check(_city.events.plans().has(added_plan),
					"seed %d: the task went to the mast put up for it, one of the day's plans"
					% seed_value)
			added_plan.silenced = false
			_city.events.silence_all_masts()
			t.check(added_plan.silenced,
					"seed %d: day 14's sabotage puts out the queued mast too" % seed_value)
			# The same night as the game plans it: the mast is there unless that night's
			# closures, holds or district doors leave it no room, and then it is absent.
			_plan_the_day(14, seed_value)
			var on_day_14 := false
			for plan in _city.events.plans():
				if plan.mast_id == mast_id and plan.silenced:
					on_day_14 = true
			var no_room := _the_day_leaves_no_room_for(foot)
			if not no_room:
				room_days[0] += 1
			t.check(on_day_14 == not no_room,
					"seed %d: and on the real last night it stands exactly where the night leaves room (%s)"
					% [seed_value, "room" if not no_room else "no room"])
			_plan_the_day(12, seed_value)
			var stands_again := false
			for plan in _city.events.plans():
				if plan.mast_id == mast_id and plan.silenced \
						and plan.position.distance_to(foot) < 1.0:
					stands_again = true
			t.check(stands_again, "seed %d: and the next day stands it again, silenced"
					% seed_value)
		elif not site_near:
			# The scheduler may refuse every tile it was offered — its acceptance, not the
			# director's — and then the nearest live mast is the task's, which the director says.
			var generated := 0
			for plan in _city.events.plans():
				if plan.def.id == "loudspeaker" and plan.mast_id.begins_with("added-"):
					generated += 1
			var stands_on := ResistanceReads.mast_at(director, _city.events)
			t.check(generated == 0 and stands_on != "" and not stands_on.begins_with("added-"),
					"seed %d: no mast near the mark, none generated (%d), and the nearest stands in"
					% [seed_value, generated])
		player.free()
		director.free()
	_free_city()
	t.check(added[0] > 0, "some city had no mast near its day-11 mark, so one was put up (%d)"
			% added[0])
	t.check(room_days[0] > 0, "some seed's last night left the mast room, so it was planned (%d)"
			% room_days[0])

## Whether the day just planned on the test city refuses a mast at `foot`: its tile closed, held or
## on the home block, or a district door's checkpoint within the gap and a mast's field of it
## (`DoorClearanceRule.clear_of_the_doors()`, the check the planning makes of every mast).
func _the_day_leaves_no_room_for(foot: Vector2) -> bool:
	var tile := _city.map.world_to_tile(foot)
	if _city.map.is_closed(tile) or _city.map.is_held_at(tile) or _city.map.is_on_home_block(tile):
		return true
	var doors := PackedVector2Array()
	var region_plan: RegionPlanner.RegionPlan = _city.streets().region_plan()
	if region_plan:
		for body in region_plan.door_bodies:
			doors.append(body.position)
	return not DoorClearanceRule.clear_of_the_doors(foot, PackedVector2Array(), doors,
			EventCatalogue.mast().field_reach())

## Plans `day` on the test city in the real day order (closures, then events), from the run's own
## scars: what the game does at that day's dawn.
func _plan_the_day(day: int, seed_value: int) -> void:
	var state := CityState.new()
	_city.run.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures", seed_value))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events", seed_value), [],
			_city.map.doorstep_world_position())

## downy-otter, "a mark is never placed in an alley she cannot reach" (*"also a mark should never
## be placed in an alley that is not reachable (ie sealed off)"*, olive-koala statement 9), on the
## relocation path: the relocation asks `_reachable_from_home()` over the day's reach
## (`DayReach`), worked out once as the walk starts. Asked here from every tenth
## sidewalk tile of two cities, over every mark day, the way a mark relocating mid-walk is placed —
## her stroller set down there and one tick (`_relocate_round()`), the mark read off the street —
## and every answer is checked two ways: against `_day_reachability()`, the same rule the director
## keeps (every obstructing or lethal plan's disc and the day's closures), built afresh; and against
## a plain walk from the doorstep over walkable ground minus `CityMap.closed_tiles`,
## `soft_sealed_tiles` and `obstructed_tiles` — the per-tile record of where a body stands, a
## second source the director's discs do not read. Two seeds and a tenth of the sidewalks keep the
## cost down: a relocation is linear in the alley count per tick.
##
## **A region door counts as a way through**, for the director and for the tile walk alike, so a
## mark reachable only by crossing a district door passes here. That is the player's own rule
## (crisp-moose, statement 2: *"the alley must be next to a path. if there is no path to it it
## shouldn't appear"*): a door always lets her through after its hold, so it is a path.
func _test_a_relocated_mark_is_never_placed_in_an_alley_she_cannot_reach(t) -> void:
	var seeds: Array[int] = [4242, 2295276695]
	var checked := 0
	for seed_value in seeds:
		_build_city_in_a_new_run(t, seed_value)
		var city := _city
		for day in REACHABILITY_SWEEP_DAYS:
			var closure_state := CityState.new()
			closure_state.begin_day(city.map.block_plans, day)
			city.start_day(closure_state, day, _production_rng(seed_value, day, "closures"))
			city.events.start_day(DaySpec.for_day(day), _production_rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())

			var director := _director(t)
			director.start_day(day, _production_rng(seed_value, day, "resistance"),
					Tuning.day_length(day))
			var mark_step := director.current_step()
			if mark_step == null or not mark_step.is_pickup:
				director.free()
				continue

			var region_plan: RegionPlanner.RegionPlan = city.streets().region_plan()
			var walled_alleys: Array[Rect2i] = region_plan.alley_walls if region_plan else []
			var reachability := _day_reachability(city)
			var grid: ReachabilityGrid = reachability[0]
			var blocked: Dictionary = reachability[1]
			var reached: Dictionary = reachability[2]

			var by_tiles := {}
			for tiles: Dictionary in [city.map.closed_tiles, city.map.soft_sealed_tiles,
					city.map.obstructed_tiles]:
				for tile: Vector2i in tiles:
					by_tiles[tile] = true
			var walk := city.map.walk_field(
					city.map.world_to_tile(city.map.doorstep_world_position()), by_tiles)

			var player := _rig_player(t, director.contact_position())
			director.use_player(player)
			var away: Array[Vector2] = []
			for tile in _mark_tiles():
				away.append(city.map.tile_to_world(tile))
			var sidewalks := city.map.tiles_of_type(GameEnums.TileType.SIDEWALK)
			for i in sidewalks.size():
				if i % 10 != 0:
					continue
				var here := city.map.tile_to_world(sidewalks[i])
				var nearest := _relocate_round(director, player, here, away)
				if nearest == Vector2.INF:
					continue
				checked += 1
				var nearest_tile := city.map.world_to_tile(nearest)
				t.check(_stands_on_legal_ground(city.map, nearest_tile, walled_alleys, false,
						grid, blocked, reached),
						("seed %d day %d: the alley a relocation from %s answers with is " +
						"walkable, unobstructed and reachable from home, never sealed off")
						% [seed_value, day, sidewalks[i]])
				t.check(city.map.distance_at(walk, nearest_tile) >= 0,
						("seed %d day %d: and a walk from the doorstep around every closure, seal " +
						"and body reaches it (%s, from %s)")
						% [seed_value, day, nearest_tile, sidewalks[i]])
			player.free()
			director.free()
	_free_city()
	t.check(checked > 0, "some relocation target was actually checked (%d)" % checked)
