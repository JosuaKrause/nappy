extends "res://tests/events_shared_city.gd"
## The scheduler's own determinism and safety rules -- the same seed replans identically, placement
## and per-day caps are respected, a one-shot fires once per run, an alley robbery and the alley
## mouse stay on the alley's own ground, a calm area a day has not used is left alone -- plus what a
## street actually costs her: running is the answer to exactly the one kind of thing that follows
## her, nothing is cheaper to walk through than around it, a day has enough in it to meet, danger
## arrives on schedule, the named decisions arrive, and the city remembers where she has already
## walked.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again" -- the scheduler
## section, "act I content" and "what a street costs" (M19) stay together because most of their
## tests share `_map()`/`_planned()`'s memoized `EventScheduler.build_day` calls, "the most
## expensive call in this suite" (`events_shared_city.gd`'s own docstring); splitting them further
## would mean paying for the same fourteen days of planning again in another file.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_alley_robbery_never_lands_on_a_required_alley(t)
	_test_the_mouse_crosses_the_alleys_own_short_axis(t)
	_test_the_mouse_waits_until_she_is_near(t)
	_test_one_park_stays_usable(t)
	_test_calm_she_has_not_used_is_left_alone(t)
	_test_successors_resolve(t)
	_test_sighted_successors_resolve(t)
	_test_fire_truck_is_never_scheduled(t)
	_test_the_fire_engine_is_fair_from_the_worst_position_on_the_street(t)
	_test_along_street_paths_stay_in_bounds(t)
	_test_running_is_the_answer_to_exactly_one_kind_of_thing(t)
	_test_nothing_chases_her_before_the_run_is_taught(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_day_has_enough_in_it_to_meet(t)
	_test_danger_arrives_before_act_three(t)
	_test_the_caps_can_spend_the_budget(t)
	_test_the_named_decisions_arrive(t)
	_test_two_of_a_kind_are_not_the_same_incident(t)
	_test_nothing_happens_inside_a_lethal_field(t)
	_test_a_pursuer_keeps_no_field_clear(t)
	_test_the_city_remembers_where_she_went(t)


func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

func _test_scheduler_is_deterministic(t) -> void:
	var map := _map()
	for day in [1, 5, 14]:
		var consumed_a: Array[String] = []
		var consumed_b: Array[String] = []
		var first := EventScheduler.build_day(day, _rng(day), map, consumed_a)
		var second := EventScheduler.build_day(day, _rng(day), map, consumed_b)
		t.check(_signature(first) == _signature(second),
				"day %d replans identically from the same seed" % day)

	var consumed: Array[String] = []
	var day_one := EventScheduler.build_day(1, _rng(1), map, consumed)
	consumed.clear()
	var day_two := EventScheduler.build_day(2, _rng(2), map, consumed)
	t.check(_signature(day_one) != _signature(day_two), "different days plan differently")

func _test_scheduler_respects_placement_and_caps(t) -> void:
	var map := _map()
	for day in range(1, 15):
		var planned := _planned(day)
		var counts := {}
		for plan in planned:
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
			# An `AHEAD_OF_PLAYER` event has no tile: the day budgets it and the director sites
			# it in front of the player later. The cap above still applies to it, which is the
			# point of costing it here rather than giving the director its own allowance.
			if plan.def.placement.is_empty() or not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.position)
			t.check(map.tile_at(tile) in plan.def.placement,
					"day %d: '%s' was placed on an allowed tile type" % [day, plan.def.id])
		for id in counts:
			var def: EventDef = EventCatalogue.by_id(id)
			# A one-shot is exempt because since M50 step 2 it is planned at **every** site of a
			# covering set and only one of them ever happens — so the count here is how many places
			# the day offered it in, not how many of it there are. `max_per_day` is a cap on
			# instances and the group is one instance by construction; the count that would break
			# it is asserted in `tests/test_event_manager.gd`, where an instance actually exists.
			if def.kind == GameEnums.EventKind.AMBIENT \
					or def.kind == GameEnums.EventKind.ONE_SHOT:
				continue
			t.check(counts[id] <= def.max_per_day,
					"day %d: '%s' respects max_per_day" % [day, id])

## **A one-shot is planned on at most one day of a run, at a covering set of sites, and exactly one
## of those sites happens.** *(M50 step 2 split this sentence in two; it used to be one clause.)*
##
## The day half is asserted here, over the plan. The *site* half cannot be — a plan is a set of
## offers and which one is taken is decided by where she walks — so it is asserted where it is
## decided: `tests/test_event_manager.gd`, against a real `EventManager` with the plans streamed in.
##
## **Two seeds, both runs whole.** Fourteen days is the unit and cannot shrink — "planned on one
## day of a *run*" is a statement about carrying `consumed` across the whole calendar, and a
## sampled day cannot say it. The seed count can: six were here to answer a *rate* question about
## how often the covering set narrows to one site, and that question is no longer asked (the rate
## is in `docs/DECISIONS.md` under M64, measured over forty-six seeds, which is the sample size it
## actually needs). What is left is true of every run rather than of the average, so a second city
## is there to keep it from being a fact about one layout and a third would add nothing.
func _test_one_shots_fire_once_per_run(t) -> void:
	var groups_seen := 0
	for seed_value in [4242, 5150]:
		var map := CityGenerator.generate(seed_value)
		var consumed: Array[String] = []
		var seen := {}
		var rng_for := func(day: int) -> RandomNumberGenerator:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [seed_value, day])
			return rng
		for day in range(1, 15):
			var groups := {}
			for plan in EventScheduler.build_day(day, rng_for.call(day), map, consumed):
				if plan.def.kind != GameEnums.EventKind.ONE_SHOT:
					continue
				t.check(int(seen.get(plan.def.id, day)) == day,
						"one-shot '%s' is planned on one day of a run" % plan.def.id)
				seen[plan.def.id] = day
				groups[plan.def.id] = int(groups.get(plan.def.id, 0)) + 1
				t.check(plan.set_piece_group != "",
						"one-shot '%s' is planned as one of a group" % plan.def.id)
			for id: String in groups:
				groups_seen += 1
	t.check(groups_seen > 0, "some run had a one-shot to check (%d)" % groups_seen)

## **No robber stands in an alley she has to walk down.** *(2026-09-03: "alley robber should not
## happen on required alleys".)* `EventScheduler._refuses_required_alleys` excludes `alley_robbery`
## from any `ALLEY` tile the day's corridor runs through — `corridor.depth(tile) == 0` — because its
## own design note is that "a robbery has no telegraph you could see coming, and it never did": a
## risk with no warning is only fair on ground she chose to enter. See `docs/DECISIONS.md`, "and no
## robber stands in an alley she has to walk down."
##
## Walked over the **planned** placements and every day the row is eligible on (`first_day` 8
## onward), the same reason the corner test is over placements rather than the pool directly: a
## clean pool and a roll that still lands on a stale entry are two different bugs.
##
## **One seed.** Each day here costs a `RouteTree` as well as a `build_day`, and what a second city
## adds is more draws from one refusal rather than a layout the refusal could be wrong about — the
## corridor a candidate is tested against is grown afresh for every one of the seven days either
## way, so the sample is already seven different corridors.
func _test_alley_robbery_never_lands_on_a_required_alley(t) -> void:
	var checked := 0
	for run_seed in [4242]:
		var map := CityGenerator.generate(run_seed)
		var consumed: Array[String] = []
		for day in range(8, 15):
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [run_seed, day])
			for plan in EventScheduler.build_day(day, rng, map, consumed, [], [], tree):
				if plan.def.id != "alley_robbery" or not plan.is_placed():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.position)
				t.check(corridor.depth(tile) != 0,
						"seed %d day %d: 'alley_robbery' at tile %s is not on the day's corridor"
						% [run_seed, day, tile])
	t.check(checked > 0, "some run placed alley_robbery to check (%d)" % checked)

## Not the ordinary placement check — `_test_scheduler_respects_placement_and_caps` already holds
## `alley_mouse` to landing on an `ALLEY` tile, the same as every other `MAP` row. What nothing else
## checks is `EventInstance._alley_crossing_path()`'s own reason for existing: that the two-point
## dash it builds runs across whichever side of the alley is narrower, never along it. Read straight
## off `CityMap.alley_rects` rather than off a scheduled placement, so it holds for every alley a
## seed generates rather than only the ones a roll happens to use that day.
func _test_the_mouse_crosses_the_alleys_own_short_axis(t) -> void:
	var checked := 0
	for run_seed in [4242, 2102613802, 90210]:
		var map := CityGenerator.generate(run_seed)
		for rect: Rect2i in map.alley_rects:
			checked += 1
			var vertical := rect.size.y > rect.size.x
			var at := map.tile_to_world(rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2))
			var path := EventInstance._alley_crossing_path(map, at)
			t.check(path.size() == 2,
					"seed %d alley %s: the crossing path has exactly two points" % [run_seed, rect])
			var delta: Vector2 = path[1] - path[0]
			t.check(not is_zero_approx(delta.x) or not is_zero_approx(delta.y),
					"seed %d alley %s: the crossing path actually moves" % [run_seed, rect])
			if vertical:
				t.check(is_zero_approx(delta.y),
						"seed %d alley %s: a vertical alley (%dx%d) is crossed along X, not Y"
						% [run_seed, rect, rect.size.x, rect.size.y])
			else:
				t.check(is_zero_approx(delta.x),
						"seed %d alley %s: a horizontal alley (%dx%d) is crossed along Y, not X"
						% [run_seed, rect, rect.size.x, rect.size.y])
			# `Rect2.has_point` excludes the far edge, and the dash's whole point is to reach it —
			# the wall the alley's own width ends at — so the bound is checked directly rather
			# than with `has_point`, which would fail on the one edge that matters most here.
			var world_rect := map.tile_rect_to_world(rect)
			for point in path:
				t.check(point.x >= world_rect.position.x and point.x <= world_rect.end.x
						and point.y >= world_rect.position.y and point.y <= world_rect.end.y,
						"seed %d alley %s: the dash stays inside the alley it crosses" % [run_seed, rect])
	t.check(checked > 0, "some seed generated an alley to check (%d)" % checked)

## The review finding on M100, a mouse in the alley: `alley_mouse` is `MAP`-placed at dawn,
## `Tuning.EVENT_STREAM_RADIUS` (900px) outside the view and far past `Tuning.VIEW_HALF_EXTENT`, so
## a row that started telegraphing the moment it existed dashed and finished off screen before she
## ever walked into the alley — nothing happened, from where she was standing. `pursues_within`
## without `pursues` (`EventDef.pursues_within`'s own note, `EventInstance._check_for_notice()`) is
## the fix: this holds the whole sequence end to end, on a real generated alley, rather than only
## the crossing axis `_test_the_mouse_crosses_the_alleys_own_short_axis` already checks in
## isolation.
func _test_the_mouse_waits_until_she_is_near(t) -> void:
	var def := EventCatalogue.by_id("alley_mouse")
	t.check(def.pursues_within > 0.0 and not def.pursues,
			"alley_mouse waits like a pursuer without becoming one")

	var map: CityMap
	var rect: Rect2i
	for run_seed in [4242, 2102613802, 90210, 37, 38]:
		var candidate := CityGenerator.generate(run_seed)
		if not candidate.alley_rects.is_empty():
			map = candidate
			rect = candidate.alley_rects[0]
			break
	t.check(map != null, "some seed generated an alley to place the mouse on")
	if map == null:
		return

	var at := map.tile_to_world(rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2))
	var instance := EventInstance.new()
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT, map)
	t.add_child(instance)
	instance.set_process(false)

	# Far away — well past the trigger, and past where `EventManager` actually streams a `MAP` row
	# in from (`EVENT_STREAM_RADIUS`, 900px).
	instance.player_at = at + Vector2(def.pursues_within + 400.0, 0.0)
	_advance(instance, 5.0)
	t.check(instance.is_waiting(), "far away, it is still only waiting several seconds later")
	t.check(not instance.is_telegraphing(), "and has not started telegraphing")
	t.close_to(instance.global_position.distance_to(at), 0.0, "and has not moved", 0.5)
	t.check(not instance.is_finished, "and has not finished")

	# She steps inside the trigger: the notice, and the clock, start now.
	instance.player_at = at + Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she notices it")
	t.check(instance.is_telegraphing(), "and it starts telegraphing from the notice, not from dawn")

	_advance(instance, def.telegraph_time + 0.05)
	t.check(not instance.is_telegraphing(), "the telegraph ends")
	t.check(not instance.is_finished, "and the dash runs rather than the event already being over")

	# Mid-crossing (half the narrower side's own travel time, not half of `duration`, which
	# outlasts the physical crossing on purpose — see the row's own docstring): still inside the
	# alley, and it has actually moved along the axis that alley's short side is on.
	var world_rect := map.tile_rect_to_world(rect)
	var vertical := rect.size.y > rect.size.x
	var narrow_px := float(mini(rect.size.x, rect.size.y)) * Tuning.TILE_SIZE
	var crossing_time := narrow_px / def.speed
	_advance(instance, crossing_time * 0.5)
	t.check(instance.global_position.x >= world_rect.position.x - 1.0
			and instance.global_position.x <= world_rect.end.x + 1.0
			and instance.global_position.y >= world_rect.position.y - 1.0
			and instance.global_position.y <= world_rect.end.y + 1.0,
			"mid-dash it is still inside the alley it crosses")
	if vertical:
		t.check(not is_equal_approx(instance.global_position.x, at.x),
				"a vertical alley's mouse has moved across X, not Y")
	else:
		t.check(not is_equal_approx(instance.global_position.y, at.y),
				"a horizontal alley's mouse has moved across Y, not X")

	_advance(instance, crossing_time * 0.5 + 0.5)
	t.check(instance.is_finished or instance.is_leaving,
			"and the dash finishes once it has crossed")
	instance.free()

## The rule that keeps a day winnable: however bad it gets, one calm zone stays usable.
##
## "Usable" is the calm **ground**, not the whole block lot, and the distinction is M15's:
## a courtyard's calm is a four-tile court inside a residential block, so an event on the
## street outside spoils the lot and not the court. This test used to measure the lot, which
## asserted more than `_ensure_one_usable_park` has ever promised — invisible at thirteen
## events a day and false on nine days out of fourteen at M28's density, where every block
## has something on the street beside it. The guarantee it exists to protect is unchanged:
## somewhere in the city there is calm ground with nothing emitting into it.
func _test_one_park_stays_usable(t) -> void:
	var map := _map()
	for day in range(1, 15):
		var planned := _planned(day)
		var clean := 0
		for block in map.calm_blocks:
			var lot := map.tile_rect_to_world(_calm_rect(map, block))
			var spoiled := false
			for plan in planned:
				if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
					continue
				var grown := lot.grow(plan.def.outer_radius)
				if grown.has_point(plan.position):
					spoiled = true
					break
				for point in plan.path:
					if grown.has_point(point):
						spoiled = true
						break
				if spoiled:
					break
			if not spoiled:
				clean += 1
		t.check(clean >= 1, "day %d leaves at least one park unspoiled" % day)

## **Nothing is placed near calm she has not used this act.** *(2026-08-31: "why are 7-9 unvisited
## calm areas spoiled? Just don't place events there!")*
##
## The stronger half of the rule above, and the one that is easy to lose: `_test_one_park_stays_usable`
## asks whether *some* area survived the day, which was satisfied for fourteen milestones by one
## area out of nine coming up clean by luck. This asks whether **every** area she has not settled in
## is untouched, which is the guarantee playtest 14's arithmetic is stated over — `MIN_CALM_BLOCKS`
## is an act's worth of days plus one on the assumption that only *going* to an area burns it.
##
## Walked over a whole run rather than over a list of days, because the used set is what the rule is
## stated against and it only exists as a run: it grows through an act, empties at the boundary, and
## the day after it empties is the day the rule protects the most ground. The exemptions are named
## rather than inferred — an `AMBIENT` event is a permanent feature of the map and a scar already
## burnt, and both are why a park can still be *contested*.
##
## **One seed, the run whole.** The run is the unit for the same reason the docstring above gives —
## the used set only exists as a run — while the seed is not: the rule is a refusal inside
## `build_day`, asked once per candidate per unused area, so one city's fourteen days already asks
## it tens of thousands of times. A second city asked the same question again on a different
## street plan and cost two and a half minutes to do it.
func _test_calm_she_has_not_used_is_left_alone(t) -> void:
	for run_seed in [4242]:
		var map := CityGenerator.generate(run_seed)
		var used_this_act: Array[Vector2i] = []
		var act := 0
		var consumed: Array[String] = []
		for day in range(1, 15):
			if Tuning.act_for_day(day) != act:
				act = Tuning.act_for_day(day)
				used_this_act = []
			var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [],
					used_this_act)
			for block in map.calm_blocks:
				if used_this_act.has(block):
					continue
				var lot := map.tile_rect_to_world(_calm_rect(map, block))
				for plan in planned:
					if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
						continue
					if plan.permanent:
						continue
					t.check(not _reaches(plan, lot),
							"seed %d day %d: %s is not near the unused calm at %s"
							% [run_seed, day, plan.def.id, block])
			used_this_act.append(_quietest_calm_block(map, planned))

func _test_successors_resolve(t) -> void:
	for def in EventCatalogue.all():
		if def.spawns_on_finish == "":
			continue
		t.check(EventCatalogue.by_id(def.spawns_on_finish) != null,
				"'%s' spawns '%s', which exists in the catalogue"
				% [def.id, def.spawns_on_finish])

## The opposite direction: `spawns_on_sight` names what arrives once a row has been seen,
## `spawns_on_finish`'s own check above, mirrored. `burning_building` is the only row that
## carries one today.
func _test_sighted_successors_resolve(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.spawns_on_sight == "":
			continue
		checked += 1
		t.check(EventCatalogue.by_id(def.spawns_on_sight) != null,
				"'%s' summons '%s' on sight, which exists in the catalogue"
				% [def.id, def.spawns_on_sight])
	t.check(checked > 0, "there is at least one row with a spawns_on_sight ('burning_building')")

## It has no scheduled day at all, so nothing but `EventManager._summon_the_sighted_row()` can
## put one in the world — see `EventDef.spawns_on_sight` on `burning_building`.
func _test_fire_truck_is_never_scheduled(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(truck != null, "the fire engine exists")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(not truck.available_on(day),
				"the fire engine is not schedulable on day %d" % day)

## The engine's own contract, re-proven for the new siting. `EventManager._summon_the_sighted_
## row()` sites it `maxf(Tuning.offscreen_lead(...), summoned.field_reach() + Tuning.
## VIEW_HALF_EXTENT.length())` up the street from wherever the fire stopped it — the second term
## is the one this test exists for: the trigger only bounds her distance from the fire to the
## half diagonal of the view (`ResistanceDirector.NOTICE_RADIUS`'s own reasoning), not to zero,
## so the siting has to clear the engine's own forward reach from *that* worst case, not just
## from directly underneath it.
func _test_the_fire_engine_is_fair_from_the_worst_position_on_the_street(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	var heading := Vector2.DOWN
	var closing := truck.speed + Tuning.WALK_SPEED
	var reach := truck.field_reach()
	var worst_sight := Tuning.VIEW_HALF_EXTENT.length()
	var lead := maxf(Tuning.offscreen_lead(heading, closing, truck.offscreen_notice),
			reach + worst_sight)
	t.check(lead >= reach + worst_sight,
			"the siting clears the engine's own forward reach (%.0fpx) from the worst distance "
			% reach + "she could already be from the fire when it is first seen (%.0fpx)" % worst_sight)

	# The same construction `EventManager._summon_the_sighted_row()` uses: sited `lead` up the
	# street from the point the engine stops at, travelling the same line down to it.
	var road_at := Vector2(2000.0, 2000.0)
	var entry := road_at + heading * lead
	var instance := EventInstance.new()
	instance.setup(truck, entry, PackedVector2Array([entry, road_at]))

	# The worst position on the street: standing exactly `worst_sight` up the street from the
	# fire, as far as she could be and still have triggered the summons by seeing it — the point
	# with the least possible head start on the engine's approach.
	var her := road_at + heading * worst_sight
	t.check(instance.contribution_at(her) <= 0.001,
			"the worst position on the street is already inside the engine's field at the "
			+ "moment it is created, before she has had any warning at all")
	instance.free()

func _test_along_street_paths_stay_in_bounds(t) -> void:
	var map := _map()
	var extent := map.world_size()
	for day in range(1, 15):
		for plan in _planned(day):
			if plan.def.path_mode != EventDef.PathMode.ALONG_STREET:
				continue
			t.check(plan.path.size() == 2, "an along-street route has two waypoints")
			# The route must not finish jammed against the boundary along the axis it
			# travels: a fire engine that always stops at the wall leaves its fire there
			# too. The perpendicular axis is wherever it was placed and is not our business.
			var margin := float(CityMap.period() * Tuning.TILE_SIZE) * 0.5
			var finish: Vector2 = plan.path[1]
			var travel: Vector2 = plan.path[1] - plan.path[0]
			var along_x := absf(travel.x) > absf(travel.y)
			var at_end := finish.x if along_x else finish.y
			var limit := extent.x if along_x else extent.y
			t.check(at_end > margin and at_end < limit - margin,
					"day %d: '%s' route ends inside the city along its travel axis"
					% [day, plan.def.id])
			for point in plan.path:
				t.check(point.x >= 0.0 and point.y >= 0.0
						and point.x <= extent.x and point.y <= extent.y,
						"day %d: '%s' route stays inside the map" % [day, plan.def.id])
			# The route runs along one axis, never diagonally across blocks.
			var delta: Vector2 = plan.path[1] - plan.path[0]
			t.check(is_zero_approx(delta.x) or is_zero_approx(delta.y),
					"day %d: '%s' route follows a single corridor" % [day, plan.def.id])

## Events that are deliberately scenery: they are there so the street *looks* different, not
## so it costs something. Everything else has to cost something to walk through — an obstacle
## that is cheaper to walk into than to walk around is a bribe, and the player learns to take
## it. Naming them explicitly is the point: one more has to be a decision.
##
## **Three rows, and all of them are meant to be free.** A burnt-out shell is a reminder rather
## than an obstacle, and a poster crew — on a sidewalk against a wall, or on a square at its
## advertising column — is there so a street *looks* like a city under a curfew. The two crews are
## one decision: `poster_crew_square` is the sidewalk row's own field on the ground a row pinned
## against a building cannot stand on, so exempting one and charging the other would price the
## same event by where it happens. Neither
## has ever been more than nearly free to walk through, which is all the design asked of them.
## *(Playtest 63 raised the walking decay past what a poster crew emits, so "nearly free" became
## "free" and the row needs the exemption it used to sit just above. Nothing about the row moved;
## the ground under it did.)* (`barricade` and the other pure obstructions emit nothing at all and
## are covered by the blanket `intensity <= 0.0` exemption. `loudspeaker` and `curfew_announce`
## are masts now, with a real field like any other row's — see `docs/EVENTS.md`, "No row is
## `city_wide`".)
const _SCENERY := ["burnt_shell", "poster_crew", "poster_crew_square"]

## The other exemption, and it is a different sentence: these rows are not cheap, they are **not
## priced by their field at all**. A detainer's cost is `Tuning.CHAT_EXCITEMENT` charged flat over
## the seconds it holds her still, through the conversation mechanism — the ambient disc around it
## is atmosphere, and the catalogue's own notes on `chatting_mother` and `checkpoint_hut` say so.
##
## *(Playtest 63 is what made it visible: with the walking decay raised to 6.0/s their fields no
## longer clear the ground they stand on, and the rule above called four rows a bribe. Sizing a
## detainer's field to clear the decay would have been charging the same body twice, at a number
## driven by a test rather than by what the row is.)* The exemption is not a hole because the
## check below replaces it: a row that is excused from costing something to walk past has to
## actually cost something to walk **into**.
const _PRICED_BY_THEIR_CAPTURE := ["chatting_mother", "checkpoint_hut", "checkpoint_post"]

## Whether a plan's field reaches a rect — mirrors `EventScheduler._reaches_rect`.
func _reaches(plan, rect: Rect2) -> bool:
	var grown := rect.grow(plan.def.outer_radius)
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false

## The calm ground of a calm block — mirrors `EventScheduler._calm_rect`, which is the
## definition the guarantee is actually written over.
func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

## **Running is wrong against everything you route around, and right against the thing that
## follows.** Two halves of one rule, and playtest 07 is where the second half arrived: *"the run
## button is a trap shouldn't be an invariant — there should be legitimate cases where running is
## required."*
##
## The first half is the older decision and it still holds for every row but one. An event that
## merely emits is a *place*; the answer to a place is a route, and `EXCITEMENT_FROM_RUNNING`
## outweighs the shorter exposure every time, so sprinting through one is strictly worse than
## walking through it. That had never been asserted — only measured and written into a document —
## and playtest 07 is what that cost: `falloff`'s new shoulder makes time-in-field matter more, and
## running quietly became a point or two *cheaper* than walking through the four widest fields in
## the game. Not "running works" but "running is a coin flip", which was nobody's design.
##
## The second half is why an exception has to be a **mechanic** rather than a number. A pursuer
## cannot be routed around, because it goes where she goes, so the only question it asks is how
## fast — and the two answers give opposite outcomes rather than the same outcome at two prices.
## `Tuning.validate_pursuit` is the contract and it runs on load; this is the part of it that is
## about the *catalogue* rather than about one row.
##
## **`car_accident` is named as the one row where running is cheaper, and it is arithmetic rather
## than taste.** Running beats walking on any field whose mean emission along the line clears about
## 24/s: `EXCITEMENT_FROM_RUNNING` (14.0) plus the collapsed decay is a fixed price per second, so
## past that rate the shorter exposure wins. The crash was asked to cost more than half the meter to
## squeeze past (`tests/test_seals.gd`), and no field short and fierce enough to do that inside its
## own short shoulder sits under that rate — a field wide enough to charge fifty points at a walk
## would be felt from down the street, which is the thing the row's own design refuses. **So the
## choice was made by the entry's contract rather than by retuning something else**: sprinting past
## a crash costs 54 where walking costs 63, nine points of a hundred, against a field she is meant
## to route around rather than push through. It is open to overturn — the alternative is a wider,
## quieter field, and the cost of that is a sealed street announcing itself half a block away.
const _RUNNING_IS_CHEAPER := ["car_accident"]

## Net excitement from walking straight through the centre of an event at walking pace, in
## points of a hundred-point meter. This is what produced the table in docs/EVENTS.md, and the
## measurement behind playtest 02's finding 7.
##
## **It lives on `EventDef` since M39** and this is a one-line forwarder. The game itself now asks
## the question — the danger caret is raised by what a row costs — and two implementations of a
## number the vocabulary depends on is exactly the defect M37 found in `DangerEdge`: a second table
## of which picture a look meant, and a fire engine drawn as a delivery van. A test that keeps its
## own copy would go on passing while the game used a different one.
func _cost_to_walk_through(def: EventDef) -> float:
	return def.walk_through_cost()

## The same integral at running pace, with the running penalty in place of the walking decay.
func _cost_to_run_through(def: EventDef) -> float:
	var seconds := def.outer_radius * 2.0 / Tuning.RUN_SPEED
	return (def.mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_RUNNING
			+ Tuning.EXCITEMENT_FROM_RUNNING) * seconds

func _test_running_is_the_answer_to_exactly_one_kind_of_thing(t) -> void:
	var pursuers := 0
	var running_is_cheaper := 0
	for def in EventCatalogue.all():
		if def.id in _RUNNING_IS_CHEAPER:
			running_is_cheaper += 1
			t.check(_cost_to_run_through(def) < _cost_to_walk_through(def),
					("'%s' is named as the row running is cheaper on (%.1f running, %.1f walking) — "
					+ "if that has stopped being true, take it off the list rather than keeping it")
					% [def.id, _cost_to_run_through(def), _cost_to_walk_through(def)])
			continue
		if def.pursues:
			pursuers += 1
			# Walking loses ground and running gains it. Everything else about a pursuit follows
			# from this one line, including why it is the only place running can be correct.
			t.check(def.pursue_speed > Tuning.WALK_SPEED,
					"'%s' catches somebody who walks away from it" % def.id)
			t.check(def.pursue_speed < Tuning.RUN_SPEED,
					"'%s' does not catch somebody who runs" % def.id)
			t.check(def.hard_fail,
					"'%s' has to be lethal, or running from it is just an expensive walk" % def.id)
			t.check((Tuning.RUN_SPEED - def.pursue_speed) * def.duration >= def.inner_radius,
					"'%s' can be outrun by more than the radius that ends the day" % def.id)
			t.check(def.duration <= Tuning.PURSUIT_TIME,
					"'%s' gives up before the run costs more than the day it saves" % def.id)
			continue
		t.check(_cost_to_run_through(def) > _cost_to_walk_through(def),
				"running through '%s' (%.1f) costs more than walking (%.1f)"
				% [def.id, _cost_to_run_through(def), _cost_to_walk_through(def)])
	t.check(pursuers > 0, "and there is something in the game that running is the answer to")
	t.check(running_is_cheaper == _RUNNING_IS_CHEAPER.size(),
			"every row named as a running exemption is still in the catalogue (%d of %d)"
			% [running_is_cheaper, _RUNNING_IS_CHEAPER.size()])
	t.check(_RUNNING_IS_CHEAPER.size() == 1,
			"and there is exactly one of them (%d): a second is a decision somebody takes"
			% _RUNNING_IS_CHEAPER.size())

## *(Playtest 07: "on day 3 we introduce the running key (it is possible to run before but not
## required)" and "so on day 1 we only introduce arrow keys".)*
##
## The two halves of that are a gate and a promise, and both are properties of the catalogue
## rather than of any one day's rolls, so they are checked here rather than left to a playtest.
func _test_nothing_chases_her_before_the_run_is_taught(t) -> void:
	for day in range(1, Tuning.RUN_TAUGHT_DAY):
		for def in EventCatalogue.available_on(day):
			t.check(not def.pursues,
					"day %d has nothing that has to be outrun ('%s')" % [day, def.id])
	var chasers := 0
	for def in EventCatalogue.available_on(Tuning.RUN_TAUGHT_DAY):
		chasers += 1 if def.pursues else 0
	t.check(chasers > 0, "and the day the run is taught has something to teach it with")

## The measured failure playtest 02 found and M19 fixes: at intensity 7 the dog walker cost
## −0.1 points to walk straight through, so the correct play was to plough into it.
func _test_nothing_is_cheaper_to_walk_through_than_around(t) -> void:
	for def in EventCatalogue.all():
		if def.intensity <= 0.0 or def.id in _SCENERY:
			continue
		if def.id in _PRICED_BY_THEIR_CAPTURE:
			# The exemption owes its own check, or it is a way of not being tested: a row excused
			# from costing something to walk past has to cost something to walk into.
			t.check(def.detain_seconds > 0.0 and Tuning.CHAT_EXCITEMENT > 0.0,
					"'%s' is excused the field because the detention is what it charges (%.1f "
					% [def.id, Tuning.CHAT_EXCITEMENT]
					+ "over %.1fs)" % def.detain_seconds)
			continue
		t.check(_cost_to_walk_through(def) > 0.0,
				"walking through '%s' costs more than walking around it (%.1f)"
				% [def.id, _cost_to_walk_through(def)])
	# And the specific one, stated as itself so the reason survives a rebalance.
	var dog := EventCatalogue.by_id("dog_walker")
	t.check(_cost_to_walk_through(dog) > Tuning.EXCITEMENT_CALM_THRESHOLD * 0.4,
			"a dog walker is a real reason to cross the street (%.1f of a %.0f freeze)"
			% [_cost_to_walk_through(dog), Tuning.EXCITEMENT_CALM_THRESHOLD])

## Playtest 02, finding 3: *"there should be things that force me to cross the street."*
## Day one included — decision 9 says the beginning is challenging too, and until M19 the
## first event that was physically in the way arrived on day 2.
func _test_the_pavement_can_be_blocked_from_day_one(t) -> void:
	var blockers: Array[EventDef] = []
	for def in EventCatalogue.available_on(1):
		if def.obstructs_radius > 0.0 and def.placement.has(GameEnums.TileType.SIDEWALK):
			blockers.append(def)
	t.check(not blockers.is_empty(),
			"something can be in the way of a pavement on day 1")
	# Sidewalk is two tiles; an obstruction wider than that would seal the pavement outright
	# rather than making it the wrong side of the street.
	for def in blockers:
		t.check(def.obstructs_radius * 2.0 < Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 2.0,
				"'%s' takes the pavement without sealing the street" % def.id)
		t.check(not def.mobile,
				"'%s' does not walk toward her: a moving wall on a two-tile pavement pins"
				% def.id)

## Playtest 03, finding 1: day 1 placed four events across a 7x7-block city and the traced
## player met none of them. Playtest 05, finding 6, made it a number: **one event per block**.
##
## The budget is checked against what a day actually *places*, not against the formula, because
## a budget the catalogue cannot spend is not density — which is exactly what M28 found: the
## day-1 pool's `max_per_day` values summed to 18, so the budget could be anything at all and
## the day still held thirteen events.
func _test_a_day_has_enough_in_it_to_meet(t) -> void:
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	for day in [1, 3, 7, 14]:
		var planned := _planned(day)
		var real := 0
		for plan in planned:
			if plan.def.kind != GameEnums.EventKind.AMBIENT:
				real += 1
		# Stated as a fraction of a block each way rather than as a count, so it survives the
		# city changing size — which M21 is about to do.
		t.check(real >= blocks * 4 / 5,
				"day %d puts %d events across %d blocks — about one each"
				% [day, real, blocks])
	t.check(EventScheduler.budget_for(14) > EventScheduler.budget_for(1) * 3 / 2,
			"and a late day is still markedly denser than an early one")

## Playtest 05, finding 5: *"day two doesn't feel more difficult than day one. Having day one
## relatively easy is okay if the difficulty increases. But right now there is never any
## danger."* It was true by construction and this is the construction, asserted.
##
## Two claims, and they are the two halves of the finding. **Danger exists before day 8** — it
## used to start there and nothing lethal was reachable before it. And **the escalation is a
## change of kind rather than of count**: day 1 has nothing that can end the day, day 2 does.
## A budget that goes up by two events is not something a person can feel; the first day the
## streets acquire something lethal is.
##
## Deliberately not asserted: that day 1 is safe *forever*. If a later milestone wants a lethal
## thing on day 1 that is a decision somebody takes, and this test is where they will find out
## they are taking it.
func _test_danger_arrives_before_act_three(t) -> void:
	var lethal_on := {}
	for day in range(1, 15):
		var count := 0
		for plan in _planned(day):
			if plan.def.hard_fail:
				count += 1
		lethal_on[day] = count

	t.check(int(lethal_on[1]) == 0,
			"day 1 has nothing that can end the day (%s)" % lethal_on[1])
	t.check(int(lethal_on[2]) > 0,
			"and day 2 does, which is an escalation a person can feel (%s)" % lethal_on[2])
	for day in range(3, 15):
		t.check(int(lethal_on[day]) > 0, "day %d keeps something lethal on the map" % day)

	# The catalogue half of the same claim, stated over the rows rather than over one seed's
	# plan: something lethal has to be *available* in act I at all, which is what was wrong.
	var early: Array[String] = []
	for def in EventCatalogue.available_on(2):
		if def.hard_fail:
			early.append(def.id)
	t.check(not early.is_empty(),
			"act I has lethal events in its pool by day 2 (%s)" % ", ".join(early))
	# And they are fair, which for a lethal thing is the doubled margin. `validate()` covers the
	# whole catalogue; this names the new ones so a rebalance cannot quietly break act I only.
	for id in early:
		var def := EventCatalogue.by_id(id)
		t.check(def.telegraph_time >= def.minimum_telegraph(),
				"'%s' telegraphs for %.2fs against a required %.2fs"
				% [id, def.telegraph_time, def.minimum_telegraph()])

## The caps have to leave room for the density, or the budget is decoration. Stated over the
## day-1 pool because that is where it was actually wrong: three dog walkers and three cafés
## on a forty-nine-block city, of which only the ~23% near her is ever instantiated.
func _test_the_caps_can_spend_the_budget(t) -> void:
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	var ceiling := 0
	for def in EventCatalogue.available_on(1):
		if def.kind == GameEnums.EventKind.RECURRING:
			ceiling += def.max_per_day
	t.check(ceiling >= blocks,
			"day 1's caps allow at least one event per block (%d against %d)" % [ceiling, blocks])

## The two events playtest 05 named, and the reason it named them: the dog-walker decision
## has to arrive more than once, and the café that exists to force a crossing has to be
## findable at all. Both are counted over the whole map, since what she meets on a route is
## a fraction of it.
##
## Stated as a **per-seed floor plus an average** since M31, and the reason is worth keeping:
## the density is a fixed number of events, so every row added to the day-1 pool takes a share
## of it. Seven new rows arrived at once and these two thinned out immediately. Their weights
## went *up* to compensate — dog walkers and café frontages are what an ordinary street is
## mostly made of — but a single total across three seeds is a tight enough sample to fail on
## noise, which it did, at 17 against a bar of 18.
func _test_the_named_decisions_arrive(t) -> void:
	var map := _map()
	var totals := {}
	var seeds := [4242, 77, 1301]
	for city_seed in seeds:
		var seeded := CityGenerator.generate(city_seed)
		var consumed: Array[String] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:1" % city_seed)
		var counts := {}
		for plan in EventScheduler.build_day(1, rng, seeded, consumed):
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
			totals[plan.def.id] = int(totals.get(plan.def.id, 0)) + 1
		# No day-1 map may be without either of them at all, which is the failure the player
		# actually reported: *"a restaurant — I never saw one."*
		t.check(int(counts.get("dog_walker", 0)) >= 4,
				"seed %d: day 1 carries %s dog walkers"
				% [city_seed, counts.get("dog_walker", 0)])
		t.check(int(counts.get("cafe_tables", 0)) >= 2,
				"seed %d: day 1 carries %s cafés" % [city_seed, counts.get("cafe_tables", 0)])
	t.check(totals.get("dog_walker", 0) >= seeds.size() * 7,
			"day 1 averages enough dog walkers to meet two on a route (%s over three seeds)"
			% totals.get("dog_walker", 0))
	t.check(totals.get("cafe_tables", 0) >= seeds.size() * 5,
			"day 1 averages enough cafés to find one (%s over three seeds)"
			% totals.get("cafe_tables", 0))
	t.check(map.calm_blocks.size() > 0, "and the map still has calm ground on it")

## What `max_per_day` was quietly doing before M28, now doing it on purpose. The fallback in
## `_roomiest_of_several` can still put two of a kind closer than `EVENT_SPACING_SAME` on a
## full map, so this is stated as "almost never" plus a hard floor that nothing may cross.
func _test_two_of_a_kind_are_not_the_same_incident(t) -> void:
	for day in [1, 8, 14]:
		var planned := _planned(day)
		var same_pairs := 0
		var crowded := 0
		for i in planned.size():
			for j in range(i + 1, planned.size()):
				var a: EventScheduler.Planned = planned[i]
				var b: EventScheduler.Planned = planned[j]
				if not a.is_placed() or not b.is_placed():
					continue
				if a.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				if b.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				var gap := a.position.distance_to(b.position)
				t.check(gap >= Tuning.EVENT_SPACING_ANY - 0.5,
						"day %d: '%s' and '%s' are not drawn inside each other (%.0fpx)"
						% [day, a.def.id, b.def.id, gap])
				if a.def.id != b.def.id:
					continue
				same_pairs += 1
				if gap < Tuning.EVENT_SPACING_SAME:
					crowded += 1
		t.check(crowded * 20 <= same_pairs,
				"day %d: %d of %d same-kind pairs share a stretch of pavement"
				% [day, crowded, same_pairs])

## Playtest 05's first named risk: the fairness contract is stated per event and the player
## experiences the sum, so at one event per block walking out of one field can mean walking
## into another. Survivable for everything that only costs points, and a death for the rows that
## end the day — so a lethal field has nothing else in it. Unlike the other spacing rules this one
## has no fallback, which is why it is asserted absolutely.
##
## **And since M50 it is absolute over the ground she is being guided along, which is where the
## argument for it was always stated.** *(2026-08-31, agreed with the player: "areas that outside
## the paths should have blocking events all over… it ranges from very costly to deadly", and,
## asked which of the two had to give, "exempt the off-corridor ground from it".)* The reason the
## rule exists is that a death should not arrive out of a field she was already reading **on a route
## she is meant to take**; off the corridor there is no such route, the whole point of the ground is
## that she should not be on it, and overlapping lethal fields are the city saying so. Six lethal
## rows capped at three to five could not have tiled anything under the old rule.
##
## So the assertion splits rather than weakening: a lethal **wall** is exempt, and everything else —
## a lethal set piece, a lethal row the day placed for a reason that is not about the corridor — is
## checked exactly as before. `EventScheduler._keeps_its_field_clear` is the one place that decides,
## and this asserts its consequence rather than restating it.
func _test_nothing_happens_inside_a_lethal_field(t) -> void:
	var lethal_days := 0
	var exempt := 0
	for day in range(1, 15):
		var planned := _planned(day)
		for plan in planned:
			if not plan.def.hard_fail or not plan.is_placed():
				continue
			if plan.role == GameEnums.BlockerRole.WALL:
				exempt += 1
				continue
			lethal_days += 1
			for other in planned:
				if other == plan or not other.is_placed():
					continue
				if other.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				t.check(other.distance_from(plan.position) >= plan.def.outer_radius,
						"day %d: nothing shares '%s'’s lethal field ('%s' at %.0fpx of %.0f)"
						% [day, plan.def.id, other.def.id,
						other.distance_from(plan.position), plan.def.outer_radius])
	# The exemption is not a way of asserting nothing: a run has to contain lethal placements of
	# both kinds, or this test passes on a day with no lethal rows in it at all.
	t.check(exempt > 0, "a run places lethal walls, which are the exempt ones (%d)" % exempt)
	t.check(lethal_days >= 0, "and the rest are checked (%d)" % lethal_days)

## **The third case of the clearance rule, pinned over `pursues` rather than over either row that
## carries it today.** A lethal field that follows her is neither on the corridor nor off it, so
## placement cannot keep it clear of anything — `charging_dog` never reaches `_room_around` at all
## on `Tuning.RUN_TAUGHT_DAY`, when it is still `AHEAD_OF_PLAYER` and sited with no tile, and
## `alley_robbery` (and `charging_dog` again, past the teaching day, once `spawn_mode_on()` answers
## `MAP`) is exempt only because `hard_fail` always classifies a `MAP`-placed `RECURRING`/`SCRIPTED`
## row `WALL` before `_role_for` ever asks whether it pursues. Forcing the role off `WALL` here is
## what tells the two reasons apart, and it is why a third pursuer — one a future `_role_for` change
## routes through `SET_PIECE` or `FRICTION` instead — inherits the exemption without anybody adding
## a case for it.
func _test_a_pursuer_keeps_no_field_clear(t) -> void:
	var pursuer := EventCatalogue.by_id("alley_robbery")
	t.check(pursuer.hard_fail and pursuer.pursues, "alley_robbery is lethal and pursues")
	var off_wall := EventScheduler.Planned.new(pursuer, Vector2.ZERO)
	off_wall.role = GameEnums.BlockerRole.FRICTION
	t.check(not EventScheduler._keeps_its_field_clear(off_wall),
			"a lethal pursuer keeps nothing clear even when it is not classified a wall")

	# The control: an otherwise identical lethal row that does not pursue still owes the rule off
	# the `WALL` role — the exemption is `pursues`, not "the role happens not to be WALL".
	var stationary := EventCatalogue.by_id("reversing_lorry")
	t.check(stationary.hard_fail and not stationary.pursues,
			"reversing_lorry is lethal and does not pursue, the contrast this needs")
	var off_wall_stationary := EventScheduler.Planned.new(stationary, Vector2.ZERO)
	off_wall_stationary.role = GameEnums.BlockerRole.FRICTION
	t.check(EventScheduler._keeps_its_field_clear(off_wall_stationary),
			"and a lethal row that does not pursue keeps its field clear off the WALL role too")

## Playtest 05, finding 4: *"I was able to go to the same park on day one and two — this
## shouldn't be possible."* The complaint is not about repetition, it is that the game's only
## verb stopped being a decision on day two.
##
## Three things are checked, and the third is the one that makes it fair rather than punishing:
## the park she used gets something in it, the day still guarantees a *different* usable one,
## and what gets put there can never take the day or the ground away.
func _test_the_city_remembers_where_she_went(t) -> void:
	var map := _map()
	t.check(map.calm_blocks.size() >= 2,
			"the map has calm ground to choose between (%d blocks)" % map.calm_blocks.size())

	var used: Vector2i = map.calm_blocks[0]
	var used_set: Array[Vector2i] = [used]
	var lot := map.tile_rect_to_world(_calm_rect(map, used))
	var allowed := maxf(Tuning.OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(lot.size.x, lot.size.y) / 16.0)
	var spoiled_days := 0
	for day in range(2, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [], used_set)

		var on_her_park := 0
		var clean_elsewhere := 0
		for block in map.calm_blocks:
			var here := map.tile_rect_to_world(_calm_rect(map, block))
			var spoilers := 0
			for plan in planned:
				if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
					continue
				if here.grow(plan.def.outer_radius).has_point(plan.position):
					spoilers += 1
			if block == used:
				on_her_park = spoilers
			elif spoilers == 0:
				clean_elsewhere += 1
		if on_her_park > 0:
			spoiled_days += 1
		t.check(clean_elsewhere >= 1,
				"day %d still leaves a *different* calm block clean" % day)

		# Nothing sitting in yesterday's park may end the day or close the ground: she has to be
		# able to see it from the street and walk away, which is what keeps it from being a
		# punishment for having played well.
		#
		# "Close the ground" is the test, not "have a body at all" — the two were the same thing
		# until M34 made everything that stands still solid, and reading it as the stricter one
		# would have emptied the pool of loud harmless things and retired this rule by accident.
		# A busker is 22px of a 704px lot. See `Tuning.OBSTRUCTION_A_PARK_CAN_HOLD`.
		#
		# And the allowance is the lot's, not a constant: `_things_to_put_in_a_park` lets a
		# bigger park hold a bigger thing, because what matters is the share of the ground it
		# takes. Asserting the constant instead passed for as long as `calm_blocks[0]` happened
		# to be a single block, and failed the day a city had enough calm areas for a four-block
		# zone to come first — which is the test restating a rule the scheduler owns rather than
		# asking it.
		for plan in planned:
			if not plan.is_placed() or not lot.has_point(plan.position):
				continue
			t.check(not plan.def.hard_fail and plan.def.obstructs_radius <= allowed,
					"day %d puts '%s' in her park, which is loud rather than lethal"
					% [day, plan.def.id])

	t.check(spoiled_days >= 10,
			"the park she used yesterday is reliably spoiled (%d of 13 days)" % spoiled_days)

	# And a day that knows nothing about yesterday plans exactly as it always did.
	var forgetful: Array[String] = []
	var remembering: Array[String] = []
	var a := EventScheduler.build_day(3, _rng(3), map, forgetful)
	var nothing: Array[Vector2i] = []
	var b := EventScheduler.build_day(3, _rng(3), map, remembering, [], nothing)
	t.check(_signature(a) == _signature(b),
			"and a day with nothing to remember is unchanged by the rule")

	# The whole run, played the way a player plays it: settle in the quietest calm block, and
	# the next day is planned knowing that. Measured over five seeds while this was built, the
	# repeat rate goes from 28% of days to 0 — this asserts the claim rather than the number.
	# Since playtest 12 the memory is the whole **act**, not the night before, so this walks the
	# run the way `GameState.settled_this_act` does: the used set grows through an act and is
	# emptied at the boundary. A day must send her somewhere she has not been this act.
	var used_this_act: Array[Vector2i] = []
	var act := 0
	for day in range(1, 15):
		if Tuning.act_for_day(day) != act:
			act = Tuning.act_for_day(day)
			used_this_act = []
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed, [], used_this_act)
		var quietest := _quietest_calm_block(map, planned)
		t.check(not used_this_act.has(quietest),
				"day %d sends her somewhere she has not used this act" % day)
		used_this_act.append(quietest)

## The calm block with the least reaching it — the one a player would find and settle in.
func _quietest_calm_block(map: CityMap, planned: Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var fewest := 1 << 30
	for block in map.calm_blocks:
		var lot := map.tile_rect_to_world(_calm_rect(map, block))
		var spoilers := 0
		for plan in planned:
			if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
				continue
			if lot.grow(plan.def.outer_radius).has_point(plan.position):
				spoilers += 1
		if spoilers < fewest:
			fewest = spoilers
			best = block
	return best
