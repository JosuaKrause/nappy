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
## **Why these checks build a city.** The suite's checks still build the shared city and are not
## converted to stand-ins yet: only as far as a pull request's change reaches is a suite converted
## (inbox #1159 in gray-dolphin). One check builds a city for a reason of its own: the closed-streets
## day (`_test_a_scar_cutting_the_clean_calm_area_off_is_not_stood`) is the integration check of
## day 12's route to a clean calm area other than the swing's, on a real day planned through
## `build_day()`, with the day's calm areas made the way `DayPlanner` makes them (`CalmAreas.of()`
## from the day and its target, which is where the swing's park is set aside).

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_alley_robbery_never_lands_on_a_required_alley(t)
	_test_the_mouse_crosses_the_alleys_own_short_axis(t)
	_test_the_mouse_waits_until_she_is_near(t)
	_test_one_park_stays_usable(t)
	_test_the_fixed_parts_hold_their_locations(t)
	_test_a_scripted_row_takes_a_location_of_its_own(t)
	_test_a_scar_cutting_the_clean_calm_area_off_is_not_stood(t)
	_test_calm_she_has_not_used_is_left_alone(t)
	_test_successors_resolve(t)
	_test_sighted_successors_resolve(t)
	_test_fire_truck_is_never_scheduled(t)
	_test_the_fire_engine_is_warned_long_enough_from_the_worst_position_on_the_street(t)
	_test_along_street_paths_stay_in_bounds(t)
	_test_the_gatehouse_day_keeps_a_share_of_the_fills_walls(t)
	_test_every_ground_weight_names_a_row_and_a_kind(t)
	_test_nothing_beside_the_routes_stands_on_the_main_road(t)
	_test_day_13s_roadblocks_stand_beside_the_routes(t)
	_test_a_roadblock_leaves_no_section_within_its_spacing_offered(t)


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
			# A one-shot is exempt: it is a group of one, `max_per_day` is a cap on instances and
			# the group is one instance by construction; the count that would break it is asserted
			# in `tests/test_event_manager.gd`, where an instance actually exists.
			if def.kind == GameEnums.EventKind.AMBIENT \
					or def.kind == GameEnums.EventKind.ONE_SHOT:
				continue
			t.check(counts[id] <= def.max_per_day,
					"day %d: '%s' respects max_per_day" % [day, id])

## **A one-shot is planned on at most one day of a run, as a group of one.** The day half is asserted
## here, over the plan; that exactly one of it happens is asserted where an instance exists:
## `tests/test_event_manager.gd`, against a real `EventManager` with the plans streamed in.
##
## **Two seeds, both runs whole.** Fourteen days is the unit and cannot shrink — "planned on one
## day of a *run*" is a statement about carrying `consumed` across the whole calendar, and a
## sampled day cannot say it. What it asserts is true of every run rather than of the average, so a
## second city is there to keep it from being a fact about one layout and a third would add nothing.
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

## **Every weight `EventScheduler.GROUND_WEIGHTS` holds is one the draw can find**: keyed by a row the
## catalogue has and by a `Location.Kind`, so a misspelt row or a renamed kind fails here rather than
## quietly weighing one and moving the fitted mix.
func _test_every_ground_weight_names_a_row_and_a_kind(t) -> void:
	var stray: Array[String] = []
	for id: String in EventScheduler.GROUND_WEIGHTS:
		if EventCatalogue.by_id(id) == null:
			stray.append(id)
			continue
		for kind: Variant in (EventScheduler.GROUND_WEIGHTS[id] as Dictionary):
			if typeof(kind) != TYPE_INT or not Location.Kind.values().has(kind):
				stray.append("%s: %s" % [id, kind])
	t.check(not EventScheduler.GROUND_WEIGHTS.is_empty() and stray.is_empty(),
			"every ground weight names a catalogue row and a kind of location (%s)" % [stray])

## How far the share of its walls a day keeps from the gatehouse day on may sit from
## `DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE`, over the days the test below plans: the bags' wall
## marbles are scaled by the share, and the walls a location would have drawn go mostly to its empty
## marbles, a few to the rows its ground still accepts, so the count lands near the share rather than
## on it. Wide enough for that, narrow enough that a share not honoured at all, every wall kept, lands
## outside it.
const _WALL_SHARE_TOLERANCE := 0.2

## **From the gatehouse day on, the day draws a share of its walls** — `EventScheduler.view_weight()`
## scales the weight in the bags of every wall-role row by `DaySpec.wall_row_share` (azure-puffin
## point 4: "fewer of all three"). The same city, seed and day is planned twice, once as the game plans it
## (`DaySpec.for_day()`) and once with `wall_row_share` at `1.0`, every wall weighed in full, so the
## check is a relationship between the two days rather than the rule read back to itself: the share
## of walls the day keeps is `DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE` within `_WALL_SHARE_TOLERANCE`, a
## wall the full day stands at its cap stands at most its cap times the share, rounded up (its cap is
## scaled as well as its weight), and a day before `Tuning.REGION_WALL_FIRST_DAY` is the same day
## either way.
func _test_the_gatehouse_day_keeps_a_share_of_the_fills_walls(t) -> void:
	var map := _map()
	var walls := 0
	var kept := 0
	var capped_rows := 0
	for day: int in [Tuning.REGION_WALL_FIRST_DAY - 1, Tuning.REGION_WALL_FIRST_DAY, 11, 13]:
		var every_wall := DaySpec.for_day(day)
		every_wall.wall_row_share = 1.0
		var consumed: Array[String] = []
		var full_plans := EventScheduler.build_day(every_wall, _rng(day), map, CalmAreas.of(map),
				consumed).placements()
		var full := _walls_of(full_plans)
		var game := _walls_of(_planned(day))
		if day >= Tuning.REGION_WALL_FIRST_DAY:
			# A wall whose cap the full day reaches is thinned too: the share scales its cap.
			var full_by_row := _walls_by_row(full_plans)
			var game_by_row := _walls_by_row(_planned(day))
			for id: String in full_by_row:
				var most: int = full_by_row[id][1]
				if int(full_by_row[id][0]) < most:
					continue
				capped_rows += 1
				var bound := ceili(most * DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE)
				t.check(int(game_by_row.get(id, [0, 0])[0]) <= bound,
						"day %d: '%s', at its cap of %d with every wall kept, stands at most %d (%d)"
						% [day, id, most, bound, int(game_by_row.get(id, [0, 0])[0])])
		if day < Tuning.REGION_WALL_FIRST_DAY:
			t.check(full == game and full > 0,
					"day %d, before the gatehouse day, places the same %d walls either way (%d)"
					% [day, full, game])
			continue
		walls += full
		kept += game
	t.check(walls > 0, "the days from the gatehouse day had walls to weigh (%d)" % walls)
	t.check(capped_rows > 0, "and walls at their cap to thin (%d)" % capped_rows)
	var share := float(kept) / maxf(1.0, float(walls))
	t.check(absf(share - DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE) <= _WALL_SHARE_TOLERANCE,
			"from the gatehouse day the day keeps %.2f of its walls (%d of %d); the share asked "
			% [share, kept, walls] + "for is %.2f" % DaySpec.GATEHOUSE_DAY_WALL_ROW_SHARE)

## The placed recurring wall-role rows of `plans` by row: `id -> [how many, the row's cap]`.
static func _walls_by_row(plans: Array[EventScheduler.Planned]) -> Dictionary:
	var found := {}
	for plan in plans:
		if plan.role == GameEnums.BlockerRole.WALL and plan.is_placed() \
				and plan.def.kind == GameEnums.EventKind.RECURRING:
			var was: Array = found.get(plan.def.id, [0, plan.def.most_in_a_day()])
			found[plan.def.id] = [int(was[0]) + 1, was[1]]
	return found

## How many of `plans` are placed recurring wall-role rows, the rows the bags weigh by the share.
static func _walls_of(plans: Array[EventScheduler.Planned]) -> int:
	var count := 0
	for plan in plans:
		if plan.role == GameEnums.BlockerRole.WALL and plan.is_placed() \
				and plan.def.kind == GameEnums.EventKind.RECURRING:
			count += 1
	return count

## **Never across the main road** (inbox #1186): a section on the main road takes no roadblock,
## neither one the roadblock phase places nor one day 13's task puts across it
## (`EventScheduler.across_the_section()`, which the phase's offers share), on the suite's own city: the
## middle section of a street of the main road, and of the first street that is not, the one with
## its carriageway and the other without the main road under it.
func _test_nothing_beside_the_routes_stands_on_the_main_road(t) -> void:
	var map := _map()
	var def := EventCatalogue.by_id("roadblock").for_day(13)
	var main: Location = null
	var side: Location = null
	for segment in map.street_segments():
		var section := StreetLocations.of(map, segment, PlacementView.View.ROUTE_ADJACENT).sections()[1]
		var on_it := map.is_main_road(not segment.horizontal, segment.a.x)
		if on_it and main == null:
			main = section
		elif not on_it and side == null and _has_a_carriageway(map, section):
			side = section
	t.check(main != null and side != null, "the city has a street of the main road and one that is not")
	if main == null or side == null:
		return
	var across := EventScheduler.across_the_section(def, map, side, _rng(13))
	t.check(across != null and side.tiles().has_point(map.world_to_tile(across.placed_at())),
			"a side street's section takes a roadblock across it, inside the section")
	t.check(_has_a_carriageway(map, main)
			and EventScheduler.across_the_section(def, map, main, _rng(13)) == null,
			"a section of the main road takes none")

## Whether any tile of `section` is carriageway (`ROAD`): a precinct, paved frontage to frontage,
## has none.
static func _has_a_carriageway(map: CityMap, section: Location) -> bool:
	var tiles := section.tiles()
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			if map.tile_at(Vector2i(x, y)) == GameEnums.TileType.ROAD:
				return true
	return false

## **Day 13's roadblock phase stands its roadblocks beside her routes and says how many route tiles
## it leaves without one** (inbox #1185, inbox #1186): the day planned with the task's row
## (`build_day()`'s `beside_the_routes`, `RoadblockPhase`) on the suite's own city, where the run log
## names each one it stood. Each is on a route-adjacent street (`Corridor.view_of()`),
## off every tile a route runs along and off the main road, nothing else stands within
## `EVENT_SPACING_ANY` of it, no two of them stand within `EVENT_SPACING_SAME` of each other (the
## judged ground offers no section that close to one already placed), and the count of route tiles
## left with none close by is written once the day is planned. The phase's own draw, its bias and its
## stop are checked with stand-ins in `tests/test_roadblock_phase.gd`; this holds the phase and the
## day's real ground together.
func _test_day_13s_roadblocks_stand_beside_the_routes(t) -> void:
	var map := _map()
	var day := 13
	var tree := RouteTree.for_day(map, day)
	var corridor := Corridor.of(tree)
	var told: Array[String] = []
	var events := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map, CalmAreas.of(map),
			[] as Array[String], [] as Array[Dictionary], tree, 0, PackedVector2Array(), [] as Array[EventScheduler.Planned], RunTrace.recording(told),
			EventCatalogue.by_id("roadblock"))
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
		t.check(plan != null and segment != null
				and corridor.view_of(segment) == PlacementView.View.ROUTE_ADJACENT
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
	var nearest_pair := INF
	for i in stood.size():
		for j in range(i + 1, stood.size()):
			nearest_pair = minf(nearest_pair,
					map.tile_to_world(stood[i]).distance_to(map.tile_to_world(stood[j])))
	t.check(nearest_pair >= EventScheduler.EVENT_SPACING_SAME,
			("no two of the phase's roadblocks stand within %.0fpx of each other: the spacing " +
			"between two of a row invalidates (nearest %.0fpx)")
			% [EventScheduler.EVENT_SPACING_SAME, nearest_pair])
	var left := RegEx.create_from_string("^plan (\\d+) of (\\d+) route tiles").search(counted)
	t.check(left != null and int(left.get_string(1)) < int(left.get_string(2)),
			"the run log counts the route tiles left with no roadblock close by (%s)" % counted)

## **Once a roadblock stands, the day's ground offers no section a roadblock within
## `EVENT_SPACING_SAME` of it** (the spacing between two of a row as an invalidation, the
## orchestrator's reading of inbox #1185, open to correction): on the suite's own city on day 13,
## the judged ground the roadblock phase asks (`EventScheduler.RuledRoadblockGround`) is asked of
## every route-adjacent section before and after one roadblock stands. Sections it offered one
## within that spacing before are offered none, or one standing clear of it, after.
func _test_a_roadblock_leaves_no_section_within_its_spacing_offered(t) -> void:
	var map := _map()
	var day := 13
	var corridor := Corridor.of(RouteTree.for_day(map, day))
	var def := EventCatalogue.by_id("roadblock").for_day(day)
	var events := DayEvents.over(CalmAreas.of(map))
	var judged := EventScheduler.RuledRoadblockGround.new(def, day, map, events, {}, corridor,
			StreetInvalidation.new(map, corridor, {}, [] as Array[Rect2], PackedVector2Array(), false),
			true)
	var sections := DayLocations.lay_out(map, corridor).sections_in(
			PlacementView.View.ROUTE_ADJACENT)
	var first: EventScheduler.Planned = null
	var before := {}
	for section in sections:
		var offered := judged.offer(section)
		if offered == null:
			continue
		if first == null:
			first = offered
		before[section] = offered
	t.check(first != null, "the city's route-adjacent sections are offered roadblocks (%d)"
			% before.size())
	if first == null:
		return
	var near_before := 0
	for section: Location in before:
		var offered: EventScheduler.Planned = before[section]
		if offered != first and offered.gap_to(first) < EventScheduler.EVENT_SPACING_SAME:
			near_before += 1
	judged.stand(first)
	var near_after := 0
	for section in sections:
		var offered := judged.offer(section)
		if offered != null and offered.gap_to(first) < EventScheduler.EVENT_SPACING_SAME:
			near_after += 1
	t.check(near_before > 0, "before it stands, sections within %.0fpx of it are offered one (%d)"
			% [EventScheduler.EVENT_SPACING_SAME, near_before])
	t.check(near_after == 0, "once it stands, none within %.0fpx of it is (%d)"
			% [EventScheduler.EVENT_SPACING_SAME, near_after])

## The city, and the seed of the day's draw, for the test below. The case is live by construction:
## the body that cuts the clean area off is stood there by hand (`_CUTTING_BODY`), so the city and the
## draw only have to give the area she used a row that spoils it, which the test's guard checks. If it
## trips because the catalogue, the planner or the tuning moved, pin another draw seed that passes.
const _CHOICE_CITY_SEED := 1000
const _CHOICE_DRAW_SEED := 3855935566
## The body stood on the clean area's one way in: a burst water main, whose body reaches 96px each
## way from the middle of the street, across its 192px. Stood through the run's scars, the one way a
## day stands a catalogue body on a spot of the caller's choosing (`build_day()`'s `scars`).
const _CUTTING_BODY := "burst_water_main"

## **On the swing day, a scar that would cut the clean calm area off is not stood.** Day 12's route
## to calm ground besides the swing's that no event's field reaches (`docs/CITY.md`, "Guarantees")
## is kept by construction: the day's routes run to it, and a scar is asked `RouteReachRule` before
## it stands (`EventScheduler._place_scars()`), so a body that would leave the clean area's route
## tiles unreached from home is refused where it would stand.
##
## The route tree keeps calm ground reachable, so no day the game plans on its own puts a body on the
## one street to a clean area. The day here is built so it does: every street but the three the home,
## the swing and the two other calm areas need is closed (`CityMap.close_streets()`, the game's own
## writer), the area the day spoils is the one she used, the clean one is reached by those streets
## alone, and a scar stands across the middle of a street only the clean area's walk uses
## (`_CUTTING_BODY`). The guards say the case is live: that body alone cuts the clean area off and
## leaves the spoiled one reached, so the check fails when the scar is stood regardless.
func _test_a_scar_cutting_the_clean_calm_area_off_is_not_stood(t) -> void:
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
		for tile in map.rect_tiles(calm.rect_of(block)):
			if map.is_walkable(tile):
				return tile
		return Vector2i(-1, -1)
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
	var grid := ReachabilityGrid.build(map)
	# The body, across the middle of the first street only the clean area's walk uses.
	var cutting: EventScheduler.Planned = null
	for key: Vector3i in walks["clean"]:
		if cutting == null and not walks["target"].has(key) and not walks["spoiled"].has(key):
			var street: StreetNetwork.Segment = walks["clean"][key]
			cutting = EventScheduler.Planned.new(EventCatalogue.by_id(_CUTTING_BODY),
					map.tile_rect_to_world(street.tile_rect()).get_center())
	t.check(cutting != null, "the clean area has a street of its own to reach it by")
	if cutting == null:
		map.close_streets([])
		return
	var alone := EventScheduler.blocked_by(map, [cutting] as Array[EventScheduler.Planned])
	var reached_alone := grid.flood([map.home_rect.position], alone)
	t.check(not grid.reaches(calm_tile.call(clean_block), alone, reached_alone)
			and grid.reaches(calm_tile.call(spoiled_block), alone, reached_alone),
			"the case is live: that body alone cuts the clean area off and leaves the spoiled one reached")
	var scars: Array[Dictionary] = [{"id": _CUTTING_BODY, "position": cutting.position,
			"since_day": day - 1}]
	var rng := RandomNumberGenerator.new()
	rng.seed = _CHOICE_DRAW_SEED
	var consumed: Array[String] = []
	var events := EventScheduler.build_day(DaySpec.for_day(day), rng, map, calm, consumed, scars)
	t.check(events.is_spoiled(spoiled_block),
			"the area she used is spoiled, so the day has a spoiled area besides the clean one")
	t.check(not events.is_spoiled(clean_block), "the area she has not used is clean")
	var blockers: Array[EventScheduler.Planned] = []
	var stood_the_cut := false
	var everything := events.placements()
	everything.append_array(events.standing())
	for body in everything:
		if body.obstructs():
			blockers.append(body)
		stood_the_cut = stood_the_cut or (body.def.id == _CUTTING_BODY and body.position == cutting.position)
	t.check(not stood_the_cut, "the scar across the clean area's one way in is not stood")
	var blocked := EventScheduler.blocked_by(map, blockers)
	var reached := grid.flood([map.home_rect.position], blocked)
	t.check(grid.reaches(calm_tile.call(clean_block), blocked, reached),
			"with every body the day stands, the clean calm area is still reached from home")
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


## **The fixed parts hold their locations** (the design's fixed parts' phases: a mast's location
## holds its mast on a day with one, and nothing is drawn where a fixed part stands): on every day
## of the shared city, each mast and each playground the day stands takes the location holding it,
## and no other placed row stands inside that location. Before the masts' first day, a mast's
## location holds nothing and is drawn like any other, so the days asked span it.
func _test_the_fixed_parts_hold_their_locations(t) -> void:
	var asked := 0
	for day in [3, 5, 8, 11, 14]:
		var events := _day_events(day)
		var locations := events.locations()
		var map := _map()
		for part in events.placements():
			if part.row().role != EventDef.Role.MAST and part.row().kind != GameEnums.EventKind.AMBIENT:
				continue
			var tile := map.world_to_tile(part.placed_at())
			var location := locations.holding(tile, map.tile_at(tile))
			if location == null:
				continue
			asked += 1
			t.check(location.is_taken(), "day %d: the location under %s at %s is taken"
					% [day, part.row_id(), RunTrace.tile(tile)])
			for other in events.placements():
				if other == part or not other.is_placed() or other.is_a_fixed_part():
					continue
				t.check(not location.tiles().has_point(map.world_to_tile(other.placed_at())),
						"day %d: nothing drawn stands in the location of %s at %s (found %s)"
						% [day, part.row_id(), RunTrace.tile(tile), other.row_id()])
	t.check(asked > 0, "the days asked stood fixed parts on locations (%d)" % asked)

## **A scripted row takes a location of its own at dawn** (`ScriptedPhase`): on the days a scripted
## row is placed (day 10's night raid, day 13's firefight), it stands inside a location that is
## taken for the day, on ground the location takes, and no row the draw placed stands in that
## location beside it.
func _test_a_scripted_row_takes_a_location_of_its_own(t) -> void:
	var asked := 0
	for day in [10, 13]:
		var events := _day_events(day)
		var map := _map()
		for plan in events.placements():
			if plan.row().kind != GameEnums.EventKind.SCRIPTED or plan.row().role == EventDef.Role.MAST \
					or not plan.is_placed() or plan.is_a_fixed_part():
				continue
			asked += 1
			var tile := map.world_to_tile(plan.placed_at())
			var location := events.locations().holding(tile, map.tile_at(tile))
			t.check(location != null and location.is_taken(),
					"day %d: %s stands in a location taken for the day" % [day, plan.row_id()])
			if location == null:
				continue
			for other in events.placements():
				if other == plan or not other.is_placed() or other.is_a_fixed_part():
					continue
				t.check(not location.tiles().has_point(map.world_to_tile(other.placed_at())),
						"day %d: nothing else stands in %s's location (found %s)"
						% [day, plan.row_id(), other.row_id()])
	t.check(asked > 0, "the scripted days placed their rows (%d)" % asked)
