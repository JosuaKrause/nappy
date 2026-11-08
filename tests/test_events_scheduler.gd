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
##
## **Why these checks build a city.** The suite's other checks still build the shared city and
## are not converted to stand-ins yet: only as far as a pull request's change reaches is a suite
## converted (inbox #1159 in gray-dolphin). One check builds a city for a reason of its own: the closed-streets day
## (`_test_the_repair_keeps_a_route_to_the_clean_calm_ground_not_the_spoiled`) is the
## integration check of the day's planning choosing the clean area on a real day. It makes the
## day's calm areas through the call `DayPlanner` makes, `CalmAreas.of()` from the day and its
## target, which is where the swing's park is set aside; its target is the swing's candidate
## tiles (`ResistanceSteps.target_candidates()`), where `DayPlanner` passes those of them
## `ResistanceDirector.target_ground()` finds legal. It then plans the day through `build_day()`,
## which runs the repair. Each part has its own check with stand-ins (`tests/test_calm_areas.gd`,
## `tests/test_day_repairs.gd`); this one holds that they choose together.

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
	_test_the_gatehouse_day_keeps_a_share_of_the_fills_walls(t)
	_test_the_repair_keeps_a_route_to_the_clean_calm_ground_not_the_spoiled(t)
	_test_nothing_beside_the_routes_stands_on_the_main_road(t)
	_test_day_13s_roadblocks_stand_beside_the_routes(t)


func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## The calm block she would find and settle in: the one the fewest of the day's rows spoil, as
## the day itself answers it (`DayEvents.spoilers_of()`).
func _quietest_calm_block(events: DayEvents, calm: CalmAreas) -> Vector2i:
	var best := Vector2i(-1, -1)
	var fewest := 1 << 30
	for block in calm.blocks():
		var spoilers := events.spoilers_of(block).size()
		if spoilers < fewest:
			fewest = spoilers
			best = block
	return best

func _test_scheduler_is_deterministic(t) -> void:
	var map := _map()
	for day in [1, 5, 14]:
		var consumed_a: Array[String] = []
		var consumed_b: Array[String] = []
		var first := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map,
				CalmAreas.of(map), consumed_a).placements()
		var second := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map,
				CalmAreas.of(map), consumed_b).placements()
		t.check(_signature(first) == _signature(second),
				"day %d replans identically from the same seed" % day)

	var consumed: Array[String] = []
	var day_one := EventScheduler.build_day(DaySpec.for_day(1), _rng(1), map, CalmAreas.of(map),
			consumed).placements()
	consumed.clear()
	var day_two := EventScheduler.build_day(DaySpec.for_day(2), _rng(2), map, CalmAreas.of(map),
			consumed).placements()
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
			for plan in EventScheduler.build_day(DaySpec.for_day(day), rng_for.call(day), map,
					CalmAreas.of(map), consumed).placements():
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
			for plan in EventScheduler.build_day(DaySpec.for_day(day), rng, map,
					CalmAreas.of(map), consumed, [], tree).placements():
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
## checks is the alley dash's own reason for existing (`EventInstance.path` of the mouse): that the
## two-point dash it builds runs across whichever side of the alley is narrower, never along it. Read straight
## off `CityMap.alley_rects` rather than off a scheduled placement, so it holds for every alley a
## seed generates rather than only the ones a roll happens to use that day.
func _test_the_mouse_crosses_the_alleys_own_short_axis(t) -> void:
	var checked := 0
	var solid := 0
	for run_seed in [4242, 2102613802, 90210]:
		var map := CityGenerator.generate(run_seed)
		for rect: Rect2i in map.alley_rects:
			# An alley the generator has made solid stays in `alley_rects` (see `SealPlanner`'s
			# note on `_make_the_pair_solid`) and has no ground to stand on, so a mouse is never
			# placed in it and the dash it is given there is cut to nothing.
			if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
				solid += 1
				continue
			checked += 1
			var vertical := rect.size.y > rect.size.x
			var at := map.tile_to_world(rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2))
			var path := _dash_of_the_mouse_at(map, at)
			t.check(path.size() == 2,
					"seed %d alley %s: the crossing path has exactly two points" % [run_seed, rect])
			if path.size() < 2:
				continue
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
	t.check(checked > 10 * solid,
			"and the alleys passed over as solid are a few (%d of %d)" % [solid, checked + solid])

## The dash `alley_mouse` is given when it is set up at `at` (`EventInstance.path`, which the
## event's own stepping walks): built from the alley it stands in and cut to the ground it fits on.
func _dash_of_the_mouse_at(map: CityMap, at: Vector2) -> PackedVector2Array:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("alley_mouse"), at, PackedVector2Array(), Vector2.RIGHT, map)
	var path := instance.path
	instance.free()
	return path

## The review finding on M100, a mouse in the alley: `alley_mouse` is `MAP`-placed at dawn,
## `Tuning.EVENT_STREAM_RADIUS` (900px) outside the view and far past `Tuning.VIEW_HALF_EXTENT`, so
## a row that started telegraphing the moment it existed dashed and finished off screen before she
## ever walked into the alley — nothing happened, from where she was standing. `EventDef.notice`
## without `EventDef.pursuit` (`EventDef.notice`'s own note, `EventNoticeRun`) is
## the fix: this holds the whole sequence end to end, on a real generated alley, rather than only
## the crossing axis `_test_the_mouse_crosses_the_alleys_own_short_axis` already checks in
## isolation.
func _test_the_mouse_waits_until_she_is_near(t) -> void:
	var def := EventCatalogue.by_id("alley_mouse")
	t.check(def.notice_within() > 0.0 and def.pursuit == null,
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
	instance.player_at = at + Vector2(def.notice_within() + 400.0, 0.0)
	_advance(instance, 5.0)
	t.check(instance.is_waiting(), "far away, it is still only waiting several seconds later")
	t.check(not instance.is_telegraphing(), "and has not started telegraphing")
	t.close_to(instance.global_position.distance_to(at), 0.0, "and has not moved", 0.5)
	t.check(not instance.is_finished, "and has not finished")

	# She steps inside the trigger: the notice, and the clock, start now.
	instance.player_at = at + Vector2(def.notice_within() - 10.0, 0.0)
	instance.step(STEP)
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
## street outside spoils the lot and not the court. The guarantee: somewhere in the city there
## is calm ground with nothing emitting into it, read off the day as the scheduler answers it
## (`DayEvents.is_spoiled()`, whose own logic `tests/test_day_events.gd` checks).
func _test_one_park_stays_usable(t) -> void:
	var calm := CalmAreas.of(_map())
	for day in range(1, 15):
		var events := _day_events(day)
		var clean := 0
		for block in calm.blocks():
			if not events.is_spoiled(block):
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
			var calm := CalmAreas.of(map, used_this_act)
			var events := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map, calm,
					consumed, [])
			for block in calm.unused():
				var near: Array[String] = []
				for plan in events.spoilers_of(block):
					near.append(plan.def.id)
				t.check(near.is_empty(),
						"seed %d day %d: nothing is near the unused calm at %s (%s)"
						% [run_seed, day, block, ", ".join(near)])
			used_this_act.append(_quietest_calm_block(events, calm))

func _test_successors_resolve(t) -> void:
	for def in EventCatalogue.all():
		if def.aftermath.on_finish == "":
			continue
		t.check(EventCatalogue.by_id(def.aftermath.on_finish) != null,
				"'%s' spawns '%s', which exists in the catalogue"
				% [def.id, def.aftermath.on_finish])

## The opposite direction: `aftermath.on_sight` names what arrives once a row has been seen,
## `aftermath.on_finish`'s own check above, mirrored. `burning_building` is the only row that
## carries one today.
func _test_sighted_successors_resolve(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.aftermath.on_sight == "":
			continue
		checked += 1
		t.check(EventCatalogue.by_id(def.aftermath.on_sight) != null,
				"'%s' summons '%s' on sight, which exists in the catalogue"
				% [def.id, def.aftermath.on_sight])
	t.check(checked > 0, "there is at least one row with an aftermath.on_sight ('burning_building')")

## It has no scheduled day at all, so nothing but `EventSpawner._summon_the_sighted_row()` can
## put one in the world — see `EventDef.aftermath.on_sight` on `burning_building`.
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
## `PendingWarning.on_its_route()` gives (what `EventSpawner._summon_the_sighted_row()` hands the
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
		elif not SpawnSiting.is_out_of_sight(VisibleView.around(her, null),
				EventFootprints.footprint_of(truck), her, place):
			wrong.append("created in sight at %v with her at %v" % [place, her])
		var to_reach := 0.0
		while engine.excitement.contribution_at(her) <= 0.0 and to_reach < 10.0:
			engine.player_at = her
			engine.step(STEP)
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

## How far the share of its walls a day keeps from the gatehouse day on may sit from
## `EventScheduler.GATEHOUSE_DAY_WALL_ROW_SHARE`, over the days the test below plans: a couple of hundred
## rolls, so a share honoured by the roll lands well
## inside it (about five standard deviations) and one not honoured at all, every wall kept or none,
## lands far outside it.
const _WALL_SHARE_TOLERANCE := 0.15

## **From the gatehouse day on, the fill keeps a share of its walls, and nothing else about the day
## moves** — `EventScheduler.build_day()` thins the fill by `DaySpec.wall_row_share` (azure-puffin
## point 4: "fewer of all three"). The same city, seed and day is planned twice, once as the game
## plans it (`DaySpec.for_day()`) and once with `wall_row_share` at `1.0`, every wall kept, so the
## check is a relationship between the two days rather than the rule read back to itself: the
## thinned day is the full day's plans in the same order with only `WALL`-role placements taken out,
## the share kept is `DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE` within `_WALL_SHARE_TOLERANCE`, and a day
## before `Tuning.REGION_WALL_FIRST_DAY` loses nothing.
func _test_the_gatehouse_day_keeps_a_share_of_the_fills_walls(t) -> void:
	var map := _map()
	var walls := 0
	var kept := 0
	for day: int in [Tuning.REGION_WALL_FIRST_DAY - 1, Tuning.REGION_WALL_FIRST_DAY, 11, 13]:
		var every_wall := DaySpec.for_day(day)
		every_wall.wall_row_share = 1.0
		var consumed: Array[String] = []
		var before := EventScheduler.build_day(every_wall, _rng(day), map, CalmAreas.of(map),
				consumed).placements()
		var after := _planned(day)
		# `after` has to be `before` with entries taken out and nothing else: walked in step, every
		# plan of `after` is met in `before` in the same order.
		var removed: Array[EventScheduler.Planned] = []
		var matched := 0
		for plan in before:
			if matched < after.size() and _same_plan(after[matched], plan):
				matched += 1
			else:
				removed.append(plan)
		t.check(matched == after.size(),
				"day %d: the thinned day is the full day with plans taken out, in order, "
				% day + "nothing added and nothing moved (%d of %d met)" % [matched, after.size()])
		var day_walls := 0
		for plan in before:
			if plan.role == GameEnums.BlockerRole.WALL and plan.is_placed():
				day_walls += 1
		# The fill's own rows are the recurring ones: the ambient rows, the scars, the masts, the
		# scripted rows and the one-shots are placed before it, and none of them is `RECURRING`. A
		# used park's spoilers are drawn from the recurring pool, so this cannot tell them from the
		# fill; no park is used in this day, so no spoiler stands in it.
		var not_a_fill_wall: Array[String] = []
		for plan in removed:
			if plan.role != GameEnums.BlockerRole.WALL or not plan.is_placed() \
					or plan.def.kind != GameEnums.EventKind.RECURRING:
				not_a_fill_wall.append(plan.def.id)
		t.check(not_a_fill_wall.is_empty(),
				"day %d: only the fill's own recurring walls are taken out (%s)" % [day, not_a_fill_wall])
		if day < Tuning.REGION_WALL_FIRST_DAY:
			t.check(removed.is_empty() and day_walls > 0,
					"day %d, before the gatehouse day, keeps all %d of its walls (%d taken out)"
					% [day, day_walls, removed.size()])
			continue
		t.check(not removed.is_empty(), "day %d: the thinning takes some of the %d walls out"
				% [day, day_walls])
		walls += day_walls
		kept += day_walls - removed.size()
	t.check(walls > 0, "the days from the gatehouse day had walls to thin (%d)" % walls)
	var share := float(kept) / maxf(1.0, float(walls))
	t.check(absf(share - DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE) <= _WALL_SHARE_TOLERANCE,
			"from the gatehouse day the day keeps %.2f of its walls (%d of %d); the share asked "
			% [share, kept, walls] + "for is %.2f" % DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE)

## Whether two plans are the same placement: the same row at the same place.
func _same_plan(a: EventScheduler.Planned, b: EventScheduler.Planned) -> bool:
	return a.def.id == b.def.id and a.position == b.position

## The city, and the seed of the day's draw, where the walkability repair has to choose between
## two calm areas (see the test below). Found by building this day for cities 1000 + 31k and
## draw seeds `hash("zz:<city>:<area>:<try>")`, once with `DayEvents.is_spoiled()` as the game
## has it and once answering "not spoiled" (a temporary edit), until the two kept different
## bodies; the first hit is pinned. If the guard in the test trips because the catalogue, the
## planner or the tuning moved, search again the same way for a city and a draw where the plans
## differ, and pin those.
const _CHOICE_CITY_SEED := 1000
const _CHOICE_DRAW_SEED := 3855935560

## **The repair keeps a route to a clean calm area, not to a spoiled one.** On day 12, with the
## swing park as the target, `EventScheduler` keeps a route to the calm ground *besides* the
## swing's that no event's field reaches (`DayRepairs.ensure_the_city_is_still_walkable()`);
## when the bodies placed cut that clean area off, it drops them, widest first, until it is
## reached. Counting the spoiled area as well would stop at the first drop that left *it*
## reachable.
##
## The route tree keeps calm ground reachable, so no day the game plans on its own puts a body on the
## one street to a clean area. The day here is built so it does: every street but the three the home,
## the swing and the two other calm areas need is closed (`CityMap.close_streets()`, the game's own
## writer), the area the day spoils is the one she used, and the clean one is reached by those
## streets alone, with bodies standing on them.
func _test_the_repair_keeps_a_route_to_the_clean_calm_ground_not_the_spoiled(t) -> void:
	var map := CityGenerator.generate(_CHOICE_CITY_SEED)
	var day := ResistanceSteps.swing_day()
	var target := ResistanceSteps.target_candidates(ResistanceSteps.narrow_target_on(day), map, null)
	var park := CityGenerator.swing_park(map)
	var others: Array[Vector2i] = []
	for block in map.calm_blocks:
		if block != park:
			others.append(block)
	t.check(not target.is_empty() and others.size() >= 2,
			"the choice city has a swing target and two calm areas besides the swing's")
	if target.is_empty() or others.size() < 2:
		return
	var clean_block := others[0]
	var spoiled_block := others[1]
	var used: Array[Vector2i] = [spoiled_block]
	var calm := CalmAreas.of(map, used, day, target)
	t.check(calm.besides() == park, "the swing day sets the swing's park aside")
	var calm_tile := func(block: Vector2i) -> Vector2i:
		var tiles := calm.calm_tiles_of(block)
		return tiles[0] if not tiles.is_empty() else Vector2i(-1, -1)
	var walks := {}   # which place -> the street segments its walk from home uses
	var keep := {}
	for place: String in ["target", "clean", "spoiled"]:
		var to: Vector2i = target[0]
		if place == "clean":
			to = calm_tile.call(clean_block)
		elif place == "spoiled":
			to = calm_tile.call(spoiled_block)
		walks[place] = {}
		t.check(_keep_streets_to(map, to, walks[place]), "home reaches the %s on open streets" % place)
		keep.merge(walks[place])
	var shut: Array[RoadClosure] = []
	for segment in map.network.segments():
		if not keep.has(segment.key()):
			shut.append(RoadClosure.new(RoadClosure.Kind.ROADWORKS, segment))
	map.close_streets(shut)
	var rng := RandomNumberGenerator.new()
	rng.seed = _CHOICE_DRAW_SEED
	var consumed: Array[String] = []
	var events := EventScheduler.build_day(DaySpec.for_day(day), rng, map, calm, consumed, [],
			null, 0, PackedVector2Array(), target, [])
	t.check(not events.is_spoiled(clean_block),
			"the area she has not used is clean after the repair")
	t.check(events.is_spoiled(spoiled_block),
			"the area she used is spoiled after the repair")
	var blockers := events.obstructions()
	var blocked := EventScheduler.blocked_by(map, blockers)
	var grid := ReachabilityGrid.build(map)
	var reached := grid.flood([map.home_rect.position], blocked)
	t.check(grid.reaches(calm_tile.call(clean_block), blocked, reached),
			"with every body the day kept standing, the clean calm area is still reached from home")
	# **The case is live**: the clean area has one way in, the streets only its walk uses, and a
	# body the day kept stands on them. Were it opened another way, or no body to stand there,
	# the check above would pass whatever `DayEvents.is_spoiled()` answered.
	var access := {}   # the tiles of the streets only the clean area's walk uses
	for key: Vector3i in walks["clean"]:
		if not walks["target"].has(key) and not walks["spoiled"].has(key):
			for tile in map.rect_tiles(walks["clean"][key].tile_rect()):
				access[tile] = true
	t.check(not access.is_empty(), "the clean area has streets of its own to reach it by")
	var shut_off := grid.flood([map.home_rect.position], access)
	t.check(not grid.reaches(calm_tile.call(clean_block), access, shut_off),
			"the clean area has one way in: without its own streets home does not reach it")
	var stands_on_access := false
	for body in blockers:
		for tile: Vector2i in EventScheduler.blocked_by(map, [body] as Array[EventScheduler.Planned]):
			stands_on_access = stands_on_access or access.has(tile)
	t.check(stands_on_access, "a body the day kept stands on the clean area's one way in")
	map.close_streets([])

## Marks in `keep` (by key) every street segment on the shortest walk from the doorstep to `to`.
## False when no walk exists.
func _keep_streets_to(map: CityMap, to: Vector2i, keep: Dictionary) -> bool:
	var start := map.world_to_tile(map.doorstep_world_position())
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size() and not came.has(to):
		var at := queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if not came.has(next) and map.is_walkable(next):
				came[next] = at
				queue.append(next)
	if not came.has(to):
		return false
	var tile := to
	while tile != start:
		var segment := map.network.segment_containing(tile)
		if segment:
			keep[segment.key()] = segment
		tile = came[tile]
	return true

## **Beside the routes, and never the main road** (inbox #1185, inbox #1186): where day 13's dawn
## stands its roadblocks and what the task's swap may replace (`stands_beside_the_routes()`), on a
## corridor whose route is set by hand (`tests/fake_route_tree.gd`): east along the streets from
## junction (2, 2) to (4, 2), with the main road the north-south corridor through junction column 3.
func _test_nothing_beside_the_routes_stands_on_the_main_road(t) -> void:
	var map := CityMap.new()
	map.main_road = 3
	var corridor := Corridor.of(FakeRouteTree.new(map).set_routes(
			[Vector3i(2, 2, 0), Vector3i(3, 2, 0)] as Array[Vector3i],
			[Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)] as Array[Vector2i]))
	var middle := func(key: Vector3i) -> Vector2i:
		return StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0).tile_rect().get_center()
	t.check(EventScheduler.stands_beside_the_routes(map, corridor, middle.call(Vector3i(2, 2, 1))),
			"a side street south from a junction the route crosses stands beside the routes")
	t.check(not EventScheduler.stands_beside_the_routes(map, corridor,
			middle.call(Vector3i(3, 2, 1))),
			"the main road south from the same kind of junction does not, though it touches the route")
	t.check(not EventScheduler.stands_beside_the_routes(map, corridor,
			middle.call(Vector3i(2, 2, 0))), "and a street the route runs along does not")

## **Day 13's roadblock phase stands its roadblocks beside her routes and says how many route tiles
## it leaves without one** (inbox #1185, inbox #1186): the day planned with the task's row
## (`build_day()`'s `beside_the_routes`, `RoadblockPhase`) on the suite's own city, where the run log
## names each one it stood. The phase's own draw, its bias and its stop are checked with stand-ins
## in `tests/test_roadblock_phase.gd`; this holds the phase and the day's real ground together. Each is on a street beside the routes (`Corridor.is_beside_the_routes()`), off every
## tile a route runs along and off the main road, nothing else stands within `EVENT_SPACING_ANY` of
## it, and the count of route tiles left with none close by is written once the day is planned.
func _test_day_13s_roadblocks_stand_beside_the_routes(t) -> void:
	var map := _map()
	var day := 13
	var tree := RouteTree.for_day(map, day)
	var corridor := Corridor.of(tree)
	var told: Array[String] = []
	var events := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map, CalmAreas.of(map),
			[] as Array[String], [] as Array[Dictionary], tree, 0, PackedVector2Array(),
			[] as Array[Vector2i], [] as Array[EventScheduler.Planned], RunTrace.recording(told),
			null, EventCatalogue.by_id("roadblock"))
	var stood: Array[Vector2i] = []
	var counted := ""
	var tile_pattern := RegEx.create_from_string("\\((-?\\d+),(-?\\d+)\\)")
	for line in told:
		if line.contains("placed beside the day's routes"):
			for found in tile_pattern.search_all(line.get_slice(";", 0)):
				stood.append(Vector2i(int(found.get_string(1)), int(found.get_string(2))))
		if line.contains("route tiles have no roadblock"):
			counted = line
	t.check(stood.size() > 1, "dawn stood roadblocks beside the routes (%d)" % stood.size())
	var by_tile := {}
	for plan in events.placements():
		if plan.row_id() == "roadblock" and plan.is_placed():
			by_tile[map.world_to_tile(plan.placed_at())] = plan
	for tile in stood:
		var plan: EventScheduler.Planned = by_tile.get(tile)
		var segment := map.network.segment_containing(tile)
		t.check(plan != null and segment != null and corridor.is_beside_the_routes(tile)
				and not corridor.carries_a_route(tile)
				and not map.is_main_road(not segment.horizontal, segment.a.x),
				"the roadblock at %s stands on a street beside the routes, off them and off the main road"
				% tile)
		if plan == null:
			continue
		var nearest := INF
		for other in events.placements():
			if other != plan and other.is_placed():
				nearest = minf(nearest, plan.gap_to(other))
		t.check(nearest >= EventScheduler.EVENT_SPACING_ANY,
				"and nothing else the day placed stands within %.0fpx of it (%.0fpx)"
				% [EventScheduler.EVENT_SPACING_ANY, nearest])
	var left := RegEx.create_from_string("^plan (\\d+) of (\\d+) route tiles").search(counted)
	t.check(left != null and int(left.get_string(1)) < int(left.get_string(2)),
			"the run log counts the route tiles left with no roadblock close by (%s)" % counted)
