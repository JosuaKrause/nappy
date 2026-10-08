extends "res://tests/events_shared_city.gd"
## The scheduler's own determinism and safety rules -- the same seed replans identically, placement
## and per-day caps are respected, a one-shot fires once per run, an alley robbery and the alley
## mouse stay on the alley's own ground, a calm area a day has not used is left alone -- plus the
## day's own content guarantees: the successors of a resolved event resolve, the fire truck is
## never itself scheduled, the fire engine is warned long enough from the worst position on its
## street, and every along-street path a row can walk stays in bounds.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again"; further split from
## a combined `test_events_scheduler.gd` (which also held "what a street costs", M19) once the
## combined file measured close to the two-minute budget on its own -- `test_events_costs.gd` keeps
## the cost side, which shares nothing but the inherited `_map()`/`_planned()` with this half.

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
	_test_the_fire_engine_is_warned_long_enough_from_the_worst_position_on_the_street(t)
	_test_along_street_paths_stay_in_bounds(t)


func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

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

## **The engine's own contract, on the game's own siting, from every position the sighting allows.**
## Seeing the fire only bounds her distance from it to the half diagonal of the view
## (`ResistanceDirector.NOTICE_RADIUS`'s own reasoning), so she may be anywhere from the kerb the
## engine stops at to that far up its street. From each such point, standing still, the engine's
## warning is walked the way `EventManager` runs it: its place is the one
## `PendingWarning.on_its_route()` gives (what `EventManager._summon_the_sighted_row()` hands the
## warning), and the engine is created there with its telegraph spent, as `spawn_warned()` does.
## What holds: the place is up the road from the kerb and wholly out of sight when it is created, its
## badge alone was at most `Tuning.WARNING_ALONE_MAX`, and **from the badge to the earliest its field
## reaches her is at least the row's own minimum** (`EventDef.minimum_telegraph()`).
##
## Its forward reach (548px) is deeper than the view is from her, so on its street she is inside its
## field from its first frame, and the warning before it exists is the whole of what she is owed.
func _test_the_fire_engine_is_warned_long_enough_from_the_worst_position_on_the_street(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	var kerb := Vector2(2000.0, 4000.0)
	# It comes down the street from the north to the kerb, so up its road is up the screen.
	var travel := Vector2.DOWN
	var worst_sight := Tuning.VIEW_HALF_EXTENT.length()
	var checked := 0
	var wrong: Array[String] = []
	var up := 0.0
	while up <= worst_sight:
		var her := kerb - travel * up
		up += Tuning.TILE_SIZE
		checked += 1
		var created: Array[EventInstance] = []
		var where := func(at: Vector2) -> Vector2:
			return PendingWarning.on_its_route(truck, at, kerb, travel, 4000.0)
		var arrive := func(place: Vector2, _at: Vector2) -> bool:
			var instance := EventInstance.new()
			instance.setup(truck, place, PackedVector2Array([place, kerb]))
			instance.resume(truck.telegraph_time, 0.0)
			created.append(instance)
			return true
		var warning := PendingWarning.new(truck, where, arrive)
		if not warning.put_up(her):
			wrong.append("no place for its warning with her %.0fpx up from the kerb"
					% her.distance_to(kerb))
			continue
		while created.is_empty() and warning.shown < Tuning.WARNING_ALONE_MAX + 5.0:
			warning.tick(STEP, her)
		if created.is_empty():
			wrong.append("never created with her %.0fpx up from the kerb" % her.distance_to(kerb))
			continue
		var engine := created[0]
		var place := engine.global_position
		if warning.shown > Tuning.WARNING_ALONE_MAX + STEP + 0.001:
			wrong.append("its badge was up alone %.2fs" % warning.shown)
		elif (place - kerb).dot(travel) >= 0.0:
			wrong.append("created at the kerb or past it at %v" % place)
		elif not PendingWarning.is_out_of_sight(VisibleView.around(her), truck, her, place):
			wrong.append("created in sight at %v with her at %v" % [place, her])
		var to_reach := 0.0
		while engine.contribution_at(her) <= 0.0 and to_reach < 10.0:
			engine.player_at = her
			engine._process(STEP)
			to_reach += STEP
		var badge_to_reach := warning.shown + to_reach
		if badge_to_reach + 0.001 < truck.minimum_telegraph():
			wrong.append("its field reaches her %.2fs after the badge with her %.0fpx up from the "
					% [badge_to_reach, her.distance_to(kerb)]
					+ "kerb, under the %.2fs minimum" % truck.minimum_telegraph())
		engine.free()
	t.check(checked > 0 and wrong.is_empty(),
			("from all %d positions up to %.0fpx up its street, the engine is created up its road "
			% [checked, worst_sight]) + "out of sight and reaches her no sooner than its minimum "
			+ "after the badge%s" % ("" if wrong.is_empty() else ": " + wrong[0]))

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
