extends RefCounted
## EventManager against a real generated City.
##
## Everything else in the event tests runs on plain data. This one builds an actual city
## and runs a day through it, because the bugs that live here are wiring bugs: an instance
## that is freed but left in the list, a successor that is spawned but never tracked. Both
## of those are invisible to a data-level test and both happened.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_build_city(t)
	_test_day_populates_the_manager(t)
	_test_finished_instances_are_dropped(t)
	_test_successor_replaces_its_parent(t)
	_test_excitement_sums_over_instances(t)
	_test_an_event_waits_until_she_is_near_it(t)
	_test_an_event_that_has_run_does_not_run_again(t)
	_test_a_running_event_comes_back_where_it_got_to(t)
	_test_a_set_piece_happens_at_exactly_one_of_its_sites(t)
	_test_a_day_started_through_the_manager_alone_still_carries_seals(t)
	_test_a_streamed_pursuer_resumes_the_chase(t)
	_test_the_fire_is_sited_on_the_way_she_is_walking(t)
	_test_the_fire_burns_where_her_walk_put_it(t)
	_test_the_fire_she_did_not_choose_leaves_her_a_way_out(t)
	_test_a_fire_that_was_never_lit_was_not_spent(t)
	_test_a_won_day_with_the_fire_unmet_still_burns(t)
	_teardown()

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	# There is no player in this rig, so nothing would ever come within streaming reach. This
	# suite is about the manager's wiring over a whole day's event set — retirement, successors,
	# the sum — and those are the same questions whether or not the day is streamed. The
	# streaming itself is checked in `_test_an_event_waits_until_she_is_near_it`.
	_city.events.stream_radius = INF

## The page's own lifetime, and that every look a row can carry has pictures on it, are
## `tests/test_atlas_events.gd`: with one baked page for the whole catalogue there is no
## per-family group left for a rig like this one to watch come and go, and the questions that
## replace it — the manager's reference count across days and teardown, and every picture a look
## can draw resolving on the `events` page — are about `AtlasLibrary` rather than about this
## suite's city.

## **A day 3 she wins with the fire never in the world still burns.** *"I agree with the fire fix"*
## (PLAYTEST-121). The row's only day is day 3 and it is spent where it enters the world, so a day
## she wins while every siting waited would leave the run with no fire, no scar and no shell — and
## the shell is what the city remembering day 3 is made of. It is lit at the end of the day instead,
## off her path, by the same acceptance rules.
##
## Nothing walks here, which is the case: a day nobody walked far enough into for a siting to be due
## is the cheapest way to produce exactly the state this is for.
func _test_a_won_day_with_the_fire_unmet_still_burns(t) -> void:
	var scars_before := GameState.scars.duplicate()
	var day := Tuning.RUN_TAUGHT_DAY
	_start(day)
	var plan := _fire_plan()
	t.check(plan != null and not plan.is_placed() and not plan.was_live,
			"the day ends with the fire owed, planned and never in the world")
	if not plan:
		return
	var doorstep := _city.map.doorstep_world_position()
	t.check(_city.events.light_what_she_never_met(doorstep),
			"the end of a won day lights it")
	t.check(plan.is_placed() and plan.was_live,
			"and it has been in the world, which is what records what a fire does to a run")
	t.check(plan.position.distance_to(doorstep)
			>= EventScheduler.WalkSiting.DUSK_CLEAR_OF_HER,
			("it is lit %.0fpx from where she finished, past the %.0fpx streaming band, so it is "
			% [plan.position.distance_to(doorstep),
			EventScheduler.WalkSiting.DUSK_CLEAR_OF_HER]) + "nowhere she could have seen it happen")
	var scar_here := false
	for scar in GameState.scars:
		scar_here = scar_here or (String(scar["id"]) == "burnt_shell"
				and Vector2(scar["position"]).distance_to(plan.position) < 1.0)
	t.check(scar_here, "and the shell the run keeps is standing where it burned")
	var still_alight := false
	for instance in _city.events.instances():
		still_alight = still_alight or instance.def.id == "burning_building"
	t.check(not still_alight,
			"and nothing is left burning in a day that is over")

	# A second call on the same day has nothing left to light: the one-shot is spent.
	t.check(not _city.events.light_what_she_never_met(doorstep),
			"a run gets exactly one fire, however many times the day ends")
	GameState.scars = scars_before

func _teardown() -> void:
	_city.free()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

func _start(day: int) -> void:
	var consumed: Array[String] = []
	_city.events.start_day(day, _rng(day), consumed)

func _test_day_populates_the_manager(t) -> void:
	_start(1)
	t.check(_city.events.active_count() > 0, "starting a day puts events in the world")
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "every tracked instance is a live node")
		t.check(instance.def != null, "every tracked instance has a def")

func _test_finished_instances_are_dropped(t) -> void:
	_start(1)
	var before := _city.events.active_count()
	var victim: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.spawns_on_finish == "":
			victim = instance
			break
	t.check(victim != null, "there is an event that leaves nothing behind")

	victim._finish()
	_city.events._physics_process(0.016)
	t.check(_city.events.active_count() == before - 1, "a finished event is dropped")
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance),
				"no freed node is left in the list after a retirement")

## The bug this exists for: one event finishing and spawning one successor leaves the list
## the same LENGTH, so a size comparison concluded nothing had changed — and left a freed
## node in the array while never tracking the successor at all.
##
## `military_convoy`/`barricade` rather than the fire engine: `fire_truck` no longer sets
## `spawns_on_finish` — the day the fire is found before the engine reversed that link, so it is
## `burning_building` that now names something, in the opposite direction
## (`EventDef.spawns_on_sight`, checked in `tests/test_events.gd`, not here). The convoy is the
## row `spawns_on_finish` still governs, and the wiring this test exists for is the same either
## way.
func _test_successor_replaces_its_parent(t) -> void:
	_start(12)
	var convoy: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.id == "military_convoy":
			convoy = instance
			break
	if not convoy:
		# The convoy is a recurring row rather than a one-shot; this seed may not have rolled
		# one on this day. Spawn one directly rather than skip the check.
		convoy = _city.events._spawn_unplanned(
				EventCatalogue.by_id("military_convoy"), Vector2(500, 500))

	var before := _city.events.active_count()
	var where := convoy.global_position
	convoy._finish()
	_city.events._physics_process(0.016)

	t.check(_city.events.active_count() == before,
			"a one-for-one replacement keeps the count the same")
	var barricade: EventInstance = null
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "no freed node survives a successor swap")
		if instance.def.id == "barricade":
			barricade = instance
	t.check(barricade != null, "the convoy leaves a barricade behind it")
	if barricade:
		t.close_to(barricade.global_position.distance_to(where), 0.0,
				"the barricade starts where the convoy stopped", 1.0)

func _test_excitement_sums_over_instances(t) -> void:
	_start(5)
	var instances := _city.events.instances()
	t.check(instances.size() > 1, "day 5 has several events to sum")

	var at: Vector2 = instances[0].global_position
	var expected := 0.0
	for instance in instances:
		expected += instance.contribution_at(at)
	t.close_to(_city.events.total_excitement_at(at), expected,
			"the manager's total is the sum of the instances' contributions")

	var far := Vector2(-10000.0, -10000.0)
	t.close_to(_city.events.total_excitement_at(far), 0.0,
			"nothing reaches a point outside every radius")

# ---------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"don't load everything upfront."* The day is still planned across the whole
# city, so every invariant stated over a day survives; what changed is when a plan becomes a
# node. These are the two properties that make that legal.

## An event is in the world exactly when the player is near it. The distances matter: the
## streaming radius has to be wider than the widest field in the catalogue, or an event would
## appear *already inside* its own outer radius and the fairness contract would be a lie.
func _test_an_event_waits_until_she_is_near_it(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)

	var plan: EventScheduler.Planned = null
	for candidate in _city.events.plans():
		# Not city-wide, which has no "near", and not mobile: a route means the reach is
		# measured to the nearest point of it, which is a different check.
		if candidate.is_placed() and not candidate.def.city_wide and candidate.path.is_empty():
			plan = candidate
			break
	t.check(plan != null, "day 1 has a stationary event somewhere in the city")
	if not plan:
		return

	var at := plan.position
	var away := at + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0)
	_city.events.stream_around(away)
	t.check(plan.live == null, "an event across the city is not in the world")

	_city.events.stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS - 40.0, 0.0))
	t.check(plan.live != null, "walking into reach of it puts it there")
	var arrived := plan.live
	t.check(arrived.age <= 0.0 or arrived.is_telegraphing(),
			"and it starts its telegraph on arrival, so the warning is not spent off-screen")

	# The hysteresis: a player pacing on the boundary must not rebuild it every other frame,
	# because a rebuilt instance telegraphs again and would crouch at her forever.
	_city.events.stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS + 40.0, 0.0))
	t.check(plan.live == arrived, "stepping just past the edge does not take it away again")
	_city.events.stream_around(away)
	t.check(plan.live == null, "walking properly away does")

	t.check(Tuning.EVENT_STREAM_RADIUS > _widest_field(),
			"an event streams in from further out (%.0f) than its own reach (%.0f), so it is "
			% [Tuning.EVENT_STREAM_RADIUS, _widest_field()]
			+ "never already on top of her when it appears")

func _widest_field() -> float:
	var widest := 0.0
	for def in EventCatalogue.all():
		if not def.city_wide:
			widest = maxf(widest, def.outer_radius)
	return widest

## The other half, and the one a naive implementation gets wrong: an event that has already
## happened must not happen again because she walked back past it. Streaming is allowed to take
## an event away and give it back while it is *running*; it is not allowed to rewind it.
func _test_an_event_that_has_run_does_not_run_again(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	var plan: EventScheduler.Planned = null
	for candidate in _city.events.plans():
		if candidate.is_placed() and not candidate.def.city_wide \
				and candidate.def.spawns_on_finish == "":
			plan = candidate
			break
	if not plan:
		return

	_city.events.stream_around(plan.position)
	t.check(plan.live != null, "she walks up to it and it is there")
	plan.live._finish()
	_city.events._physics_process(0.016)
	t.check(plan.spent and plan.live == null, "it runs its course and the plan is spent")

	_city.events.stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	_city.events.stream_around(plan.position)
	t.check(plan.live == null, "and coming back does not start it over")
	_city.events.stream_radius = INF

## The third case, and the one that was actually wrong. *(M31.)* An event that is still
## **running** may be taken away and given back — but it has to come back where it got to, not
## where the day put it at dawn.
##
## Reported as *"dog walkers are not moving?"*, which they were: at 32px/s a dog walker covers a
## tile a second, and every time the player left its radius and came back it was rebuilt from
## `plan.position` and teleported to the top of its street. At a third of her walking speed that
## is most times, so from outside it was an event that never went anywhere.
func _test_a_running_event_comes_back_where_it_got_to(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	var plan: EventScheduler.Planned = null
	for candidate in _city.events.plans():
		if candidate.is_placed() and candidate.def.mobile and candidate.path.size() > 1 \
				and not candidate.def.still_while_telegraphing:
			plan = candidate
			break
	t.check(plan != null, "day 1 has something walking down a street")
	if not plan:
		_city.events.stream_radius = INF
		return

	_city.events.stream_around(plan.position)
	t.check(plan.live != null, "she comes near it and it is there")
	var started := plan.live.global_position
	for i in 120:
		plan.live._process(1.0 / 60.0)
	var walked := plan.live.global_position
	t.check(started.distance_to(walked) > 1.0,
			"it covers ground while she is watching (%.0fpx in 2s)"
			% started.distance_to(walked))
	var aged := plan.live.age

	_city.events.stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	t.check(plan.live == null, "she walks away and it leaves the world")
	_city.events.stream_around(walked)
	t.check(plan.live != null, "she comes back and it is there again")
	if plan.live:
		t.check(plan.live.global_position.distance_to(walked) < 1.0,
				"and it is where it had got to, not back at the top of its street (%.0fpx off)"
				% plan.live.global_position.distance_to(walked))
		# The age comes back with it, so an event cannot be made immortal by being visited
		# twice — its telegraph, its pulse and its duration all carry on rather than restart.
		t.check(absf(plan.live.age - aged) < 0.01,
				"and it is as old as it was, so revisiting cannot restart its clock")
	_city.events.stream_radius = INF

## **A set piece happens in exactly one place, and there are two ways of guaranteeing that.** A
## one-shot planned at every site of a covering set happens at the one she reaches — the first to
## enter the world spends the rest. A one-shot carrying `EventDef.sited_on_her_way` is one plan with
## no position at all, which cannot be in two places because there is only ever one of it, and which
## nothing in this rig can put anywhere: there is no player here, so no walk for it to be sited from.
##
## `tests/test_events.gd` can only see the plan, so *which* site is taken has to be checked here,
## where an instance exists. `stream_radius` is `INF` and there is nobody walking, so every sited
## offer is reachable at once: the first one the manager streams in must spend the rest, which is
## the strongest form of the property.
##
## It is the same shape as `_test_an_event_that_has_run_does_not_run_again` one level up. There a
## plan may not run twice; here a *group* may not.
func _test_a_set_piece_happens_at_exactly_one_of_its_sites(t) -> void:
	var offered := 0
	var owed_to_her_walk := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		_start(day)
		var groups := {}
		for plan in _city.events.plans():
			if plan.set_piece_group == "":
				continue
			var seen: Array = groups.get(plan.set_piece_group, [] as Array)
			seen.append(plan)
			groups[plan.set_piece_group] = seen
		for group: String in groups:
			var plans: Array = groups[group]
			var placed := 0
			var live := 0
			var spent := 0
			for plan: EventScheduler.Planned in plans:
				placed += 1 if plan.is_placed() else 0
				live += 1 if plan.was_live else 0
				spent += 1 if plan.spent else 0
			if placed == 0:
				# Nothing has been sited, so this is a set piece the day owes her walk. With no
				# player in the rig it must still be waiting — and waiting is one plan, not several.
				owed_to_her_walk += 1
				t.check(plans.size() == 1 and live == 0 and spent == 0,
						"day %d: '%s' is one unsited plan waiting for a walk that never happens here"
						% [day, group])
				continue
			offered += 1
			t.check(live == 1, "day %d: '%s' happened in exactly one place (%d)"
					% [day, group, live])
			t.check(spent == plans.size() - 1,
					"day %d: and the other %d offers are spent (%d were)"
					% [day, plans.size() - 1, spent])
	t.check(offered + owed_to_her_walk > 0,
			"a run has a set piece to check at all (%d sited, %d owed to her walk, over fourteen days)"
			% [offered, owed_to_her_walk])

## M100: "a rig driving `EventManager` before `City.start_day` seals nothing." `EventManager.
## start_day` used to read the day's tree as `_city.route_tree()` whenever `_city` existed at
## all — even before `_city.start_day()` had ever grown one, which is exactly what every rig in
## this suite does, this one included — so `SealPlanner.plan_day` and `RegionPlanner.plan_day`
## were handed a null tree and came back with nothing, while `EventScheduler.build_day` grew a
## tree of its own for the catalogue's own placements: two trees for one day, and no seals or
## walls at all.
##
## Comparing "the manager alone" against "the manager after the city's own `start_day`" is the
## check, rather than counting seals directly: `RouteTree.for_day(map, day)` is deterministic and
## `SealPlanner`'s own RNG stream (`GameState.day_rng(day, "seals")`) does not depend on `_city`
## either, so every segment the fallback holds has to be held the real way too — a rig that skips
## `City.start_day` must not come out with less of it. **Not exact equality**: `_city.closures()`
## only ever has something to read once `City.start_day()` has run (see the comment in
## `EventManager.start_day` above `_map.clear_day_holds()`), so the "after" run legitimately holds
## a little more, one closure's own segment. See `tests/test_checkpoints.gd`'s
## `_test_the_manager_actually_places_the_door_structure()` for the same `City.start_day` calling
## convention, written against this exact gap before it had a fix.
func _test_a_day_started_through_the_manager_alone_still_carries_seals(t) -> void:
	var day := Tuning.REGION_WALL_FIRST_DAY  # so a region wall or door is in play, not only seals.
	_start(day)
	var alone: Dictionary = _city.map.held_segments.duplicate()
	t.check(alone.size() > 0,
			"a day started through the manager alone still holds some ground (%d segments)"
			% alone.size())

	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("m100-seals:closures:%d" % day)
	_city.start_day(state, day, closures_rng)
	_start(day)
	var after_city: Dictionary = _city.map.held_segments.duplicate()

	for key in alone:
		t.check(after_city.has(key),
				"everything the manager's own fallback tree holds, City.start_day holds too")

	# **This test's own `City.start_day()` call must not outlive it.** `_city` is shared across
	# every function in this suite, and everywhere else drives `EventManager` alone, the way M100's
	# gap describes above — but `City.start_day()` writes `_tree`, `_closures`, `_region_plan` and
	# `map.closed_tiles` onto `_city` itself, and nothing before this fix ever cleared them back
	# off. `_city.route_tree()` and `_city.closures()` have no fallback at all once non-null
	# (`EventManager.start_day`'s own doc, above the holds it builds), so once this test called
	# `City.start_day()` for `day`, every later test's "manager alone" day kept reading *this*
	# day's corridor and closures — of whatever day `Tuning.REGION_WALL_FIRST_DAY` names — rather
	# than growing its own, which is what "alone" is supposed to mean. That only ever changed which
	# candidates a later day's own siting had to route around, so it stayed silent until a branch's
	# own decision (M181, moving the day the region wall starts standing) chose a value whose
	# leftover corridor and closures this seed's fire tests could not route around — see
	# `docs/DECISIONS.md`, M181. `close_streets([])` is `CityMap`'s own way to clear `closed_tiles`;
	# `_tree`, `_closures` and `_region_plan` have no such method, since nothing outside a test ever
	# needs to un-start a day, so they are reset by hand.
	_city.map.close_streets([])
	_city._tree = null
	_city._closures = []
	_city._region_plan = null

## M100, small, real, and nobody's: the wiring half of "a pursuer streamed out mid-chase comes
## back having forgotten it." `tests/test_heat.gd` already drives `EventInstance.resume()` directly
## and pins that its `from_noticed_at` argument restores `_noticed_at`; the gap that shipped anyway
## was one level up — `EventScheduler.Planned` had no field to hold the notice, so
## `EventManager._stream_in()` always called `resume()` with the default `INF` and a `pursues_within`
## row streamed out mid-chase came back `is_waiting()`, standing where the day planted it. This
## drives the same encounter through `EventManager._stream_in()`/`_stream_out()` themselves, the
## only place that bug could actually live — the same kind of wiring question the rest of this
## suite exists for (see the class doc above).
##
## `alley_robbery` rather than a scheduled plan: it carries `pursues_within` cold, with no heat
## level or a particular day's roll needed to reach it, and a `Planned` built by hand is
## deterministic where waiting for the scheduler to place one on some day would not be.
func _test_a_streamed_pursuer_resumes_the_chase(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var plan := EventScheduler.Planned.new(def, Vector2(500.0, 500.0))

	_city.events._stream_in(plan)
	t.check(plan.live != null, "the hand-built plan streams in like any other")
	if not plan.live:
		return

	var her := plan.position + Vector2(def.pursues_within - 10.0, 0.0)
	plan.live.player_at = her
	plan.live._process(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "she is inside the trigger, so it notices her")
	for i in 60:
		plan.live.player_at = her
		plan.live._process(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "and a second later it is still chasing, not patrolling")
	var chase_age_before := plan.live.chase_age()

	_city.events._stream_out(plan)
	t.check(plan.live == null, "streaming out through the manager clears the live instance")
	t.check(plan.noticed_at != INF,
			"and the plan itself remembers when it noticed her, not just the freed instance")

	_city.events._stream_in(plan)
	t.check(plan.live != null, "streaming back in rebuilds it")
	if plan.live:
		t.check(not plan.live.is_waiting(),
				"streamed back in through EventManager it is still chasing, not waiting")
		t.close_to(plan.live.chase_age(), chase_age_before,
				"and the chase clock continued from the notice rather than restarting at it", 0.05)

# ------------------------------------------- the fire is on her way (M179) ---
# *"the fire should come first and be on your way guaranteed (a dynamic event dependent on the
# route you chose that day)"* (PLAYTEST-117). Day 3's fire carries `EventDef.sited_on_her_way`, so
# the day budgets it with no position and `EventDirector.site_what_is_on_her_way()` puts it on a
# building face ahead of her once her heading for the day is clear.
#
# **These have to be here rather than in `tests/test_events.gd`.** Everything about the siting is a
# function of where she actually walked, so it needs a real city, a real manager and something in
# the `player` group that moves — the same reason this suite exists at all.

const WALK_STEP := 1.0 / 30.0
## Long enough for a whole route out to a calm area and back again at walking pace, which is what
## the outbound and return legs of a 180s day are.
const WALK_SECONDS := 240.0

## A player the manager can find, out of the physics loop and moved by hand at `Tuning.WALK_SPEED`.
##
## **It walks the day's own routes**, because that is what the siting is stated over: a site is a
## building face on the branch of the day's `RouteTree` she is walking, so a rig holding a compass
## heading through the lattice spends its walk off the tree, where there is no branch to be ahead on
## and the only correct answer is to wait. `_a_route_out()` turns a route into the line it walks.
func _walker(t, at: Vector2) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	# Set here rather than left to the engine: a camera built in code under physics interpolation is
	# overridden to the physics callback with a warning, and a warning in a test run is a failure.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.global_position = at
	return rig

## Seconds of walking since the last `_start`, advanced by `_walk` so a test can say *when*
## something happened without threading a clock through the walking itself.
var _walk_clock := 0.0

## Steps the manager along `route` — a chain of world points — until it runs out, `WALK_SECONDS` of
## walking have gone by, or `until` answers true. Returns the direction she was travelling on the
## last frame, which is what a caller asking "and then she turned round" needs.
##
## A point is walked to rather than through: the rig is moved at `Tuning.WALK_SPEED` straight at the
## next cell centre of the route and `velocity` is set to match, since the director's clock only
## runs while she is actually going somewhere and its heading is read off `velocity`.
func _walk(rig: Stroller, route: PackedVector2Array, until := Callable()) -> Vector2:
	var heading := Vector2.RIGHT
	# From where she already is, so a second call carries on down the same route rather than
	# walking her back to its first point — which is what a test that stops at the siting and then
	# keeps going needs.
	for i in range(_nearest_on(route, rig.global_position), route.size()):
		var toward := route[i] - rig.global_position
		while toward.length() > Tuning.WALK_SPEED * WALK_STEP and _walk_clock < WALK_SECONDS:
			heading = toward.normalized()
			rig.velocity = heading * Tuning.WALK_SPEED
			rig.global_position += heading * Tuning.WALK_SPEED * WALK_STEP
			_city.events._physics_process(WALK_STEP)
			_walk_clock += WALK_STEP
			if until.is_valid() and until.call():
				return heading
			toward = route[i] - rig.global_position
		if _walk_clock >= WALK_SECONDS:
			return heading
	return heading

## Paints one disc of ground into a `blocked` set, the way the day's own reachability questions do.
func _block(blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := _city.map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if _city.map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true

## The nearest walkable tile to `from` that is not inside anything `blocked` — where she steps back
## to when she comes round the corner into a field. `Vector2i(-1, -1)` if there is none within the
## fire's own field, which would be a fire she cannot get out of at all.
func _retreat_from(from: Vector2i, blocked: Dictionary) -> Vector2i:
	var reach := ceili(EventCatalogue.by_id("burning_building").outer_radius / Tuning.TILE_SIZE)
	for ring in range(0, reach + 1):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var tile := from + Vector2i(dx, dy)
				if not blocked.has(tile) and _city.map.is_walkable(tile):
					return tile
	return Vector2i(-1, -1)

## The calm tiles of every area she has not settled in this act — what the siting's own acceptance
## check requires to stay reachable, worked out here from the map rather than asked of the check.
func _calm_she_has_not_used() -> Array[Vector2i]:
	var used := GameState.settled_this_act()
	var tiles: Array[Vector2i] = []
	for block in _city.map.calm_blocks:
		if used.has(block):
			continue
		for tile in _city.map.rect_tiles(ClosurePlanner.calm_area_rect(_city.map, block)):
			if Tile.is_calm(_city.map.tile_at(tile)):
				tiles.append(tile)
	return tiles if not tiles.is_empty() else _city.map.calm_tiles()

## The index of the route point she is standing nearest to. A route is a chain of cell centres and
## she walks between them, so this is where a resumed walk picks up.
func _nearest_on(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in route.size():
		var distance := route[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

## The tree the manager planned this day against, chosen the way `EventManager.start_day` chooses
## it: the city's own if a `City.start_day` has ever grown one, and a fresh `RouteTree.for_day`
## otherwise. **Asking for a fresh one unconditionally is the trap**, because this suite drives the
## manager without the city on most of its days and with it on one — so after that one the city
## holds a tree grown for a different day, and a rig walking a route out of a tree the fire was
## never sited against measures nothing.
func _days_tree(day: int) -> RouteTree:
	var tree := _city.route_tree()
	return tree if tree else RouteTree.for_day(_city.map, day)

## The longest route of the day's own tree as the line she walks: out from the doorstep to the calm
## area it reaches when `outward`, back down the same ground when not.
##
## A route runs from the area to the doorstep, which is why the walk out is the array reversed.
func _a_route_out(day: int, outward := true) -> PackedVector2Array:
	var tree := _days_tree(day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for i in best.size():
		var cell: Vector2i = best[best.size() - 1 - i] if outward else best[i]
		points.append(EventScheduler.WalkSiting._cell_centre(_city.map, cell))
	return points

## Which cells of the day's routes carry `position`, as the branch colours `RouteTree` records —
## empty for a point off the tree. What "on the path" means, asked of a placement.
func _branches_on(day: int, position: Vector2) -> Array[int]:
	return _days_tree(day).branches_on(_city.map.world_to_tile(position))

func _fire_plan() -> EventScheduler.Planned:
	for plan in _city.events.plans():
		if plan.def.id == "burning_building":
			return plan
	return null

## **The fire is on the path she is walking, and nowhere else.** *(PLAYTEST-119: "the fire needs to
## spawn on the current path the player is on — moving it around works but valid spawn locations are
## only on the path".)* The day plans it with no position at all; walking the day's own route out of
## the doorstep has it sited on that route ahead of her, off screen, and brought into view by
## continuing to walk. Walking the same route home again is the same rule, which is the whole of
## PLAYTEST-120: a fire she has dodged is still ahead of her on the way back.
##
## The three properties checked on the siting itself are the ones the design is stated in. It is
## **on the tree** — the day's own `RouteTree` carries the tile it stands on. It is **ahead on the
## branch she is walking**, which is `WalkSiting.still_ahead_of()`'s own question asked from where
## she was standing. And it is **off screen**: outside the streaming band, so nothing about it is
## visible and nothing about it is real yet.
func _test_the_fire_is_sited_on_the_way_she_is_walking(t) -> void:
	var scars_before := GameState.scars.duplicate()
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var day := Tuning.RUN_TAUGHT_DAY
	for leg: String in ["out", "home again"]:
		_start(day)
		var plan := _fire_plan()
		t.check(plan != null and not plan.is_placed(),
				"walking %s: day 3 budgets a fire and leaves it for her walk to site" % leg)
		if not plan:
			continue
		var route := _a_route_out(day)
		var rig := _walker(t, route[0])
		_walk_clock = 0.0
		if leg == "home again":
			# Stood at the calm area with nothing sited, which is the state a walk out that dodged
			# the fire ends in: the director's clock only runs while she is walking, so putting her
			# at the far end of the route is a walk out during which no siting was ever due. What
			# is then measured is entirely the return leg's.
			rig.global_position = route[route.size() - 1]
			route = _a_route_out(day, false)
		# `_walk` stops on the frame the fire is sited, so where she is standing when it returns is
		# where she was standing when it happened, to within one step. A lambda cannot carry that
		# out of the walk instead: GDScript captures a local by value, so a closure assigning to one
		# writes to its own copy and the caller reads the value it started with.
		var heading := _walk(rig, route, func() -> bool: return plan.is_placed())
		t.check(plan.is_placed(), "walking %s: the fire is sited at all" % leg)
		if not plan.is_placed():
			rig.free()
			continue
		var sited_from := rig.global_position
		var sited_at := _walk_clock
		t.check(not _branches_on(day, plan.position).is_empty(),
				"walking %s: and it stands on the day's own route tree, never off it" % leg)
		t.check(plan.position.distance_to(sited_from) > Tuning.EVENT_STREAM_RADIUS,
				("walking %s: %.0fpx out, past the %.0fpx streaming band, so it is neither visible "
				% [leg, plan.position.distance_to(sited_from), Tuning.EVENT_STREAM_RADIUS])
				+ "nor real when it is placed")
		var siting := _city.events.walk_siting()
		t.check(siting != null and siting.still_ahead_of(sited_from, heading, plan.position),
				"walking %s: and it is ahead of her along the branch she is walking" % leg)
		var seen_at := -1.0
		_walk(rig, route, func() -> bool: return _city.events._is_on_screen(plan.position))
		if _city.events._is_on_screen(plan.position):
			seen_at = _walk_clock
		t.check(seen_at >= 0.0,
				"walking %s: and continuing along the route brings it into view (%.1fs in)"
				% [leg, seen_at])
		if seen_at >= 0.0:
			print("      fire %s: sited %.1fs in, %.0fpx ahead, first seen %.1fs later"
					% [leg, sited_at, plan.position.distance_to(sited_from), seen_at - sited_at])
			# The engine is what the sight of it summons, and it is summoned on that same frame.
			var engine := false
			for instance in _city.events.instances():
				engine = engine or instance.def.id == "fire_truck"
			t.check(engine, "walking %s: and seeing it calls the engine in" % leg)
		rig.free()
	_city.events.stream_radius = INF
	GameState.scars = scars_before

## **The scar the run keeps is where it actually burned.** The whole point of siting the fire from
## her walk is that where it stands is not known at dawn, and a scar is the city's memory of a day —
## so this is the one property that would go wrong silently: a burnt-out shell standing for the rest
## of the run somewhere no fire ever was.
##
## The rule that keeps it true is that a plan stops being movable the moment it is *real*, which is
## the first time it streams in — `EventManager._stream_in` records the scar there. The rule itself
## is checked in `tests/test_events.gd`, against a director with the geometry written rather than
## walked; what is checked here is the wiring, against a real streaming manager and a real walk.
func _test_the_fire_burns_where_her_walk_put_it(t) -> void:
	var scars_before := GameState.scars.duplicate()
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(Tuning.RUN_TAUGHT_DAY)
	var plan := _fire_plan()
	t.check(plan != null, "day 3 has a fire to walk into")
	if not plan:
		_city.events.stream_radius = INF
		return
	var route := _a_route_out(Tuning.RUN_TAUGHT_DAY)
	var rig := _walker(t, route[0])
	_walk_clock = 0.0
	_walk(rig, route, func() -> bool: return plan.is_placed())
	t.check(plan.is_placed(), "walking the day's route sites it")
	if not plan.is_placed():
		rig.free()
		_city.events.stream_radius = INF
		return

	_walk(rig, route, func() -> bool: return plan.was_live)
	t.check(plan.was_live, "and walking on puts it in the world")
	if plan.was_live:
		var burning_at := plan.position
		var scar_here := false
		for scar in GameState.scars:
			scar_here = scar_here or (String(scar["id"]) == "burnt_shell"
					and Vector2(scar["position"]).distance_to(burning_at) < 1.0)
		t.check(scar_here, "and the scar the run keeps is where it actually burned")
		# Back down the route she came up, which is the walk home: it is real now, so nothing about
		# turning round may move it.
		_walk(rig, _a_route_out(Tuning.RUN_TAUGHT_DAY, false))
		t.check(plan.position == burning_at,
				"and turning round after it is real leaves it exactly where it burned")
	rig.free()
	_city.events.stream_radius = INF
	GameState.scars = scars_before

## **A siting she did not choose owes her a way out of it.** She walks up to this fire because the
## day put it in front of her rather than because she picked the street, so the fire's own body,
## its field and the engine's must never be what closes the last way off the street she is on.
##
## Asked as reachability rather than as a radius: from the tile she is standing on when she first
## sees the fire, with every solid body the day has placed counted as blocked, she can still reach
## calm ground. `EventScheduler.WalkSiting` refuses a candidate that would break the same property
## measured from the home, and this is the other end of it — the property stated over *her*, at the
## one moment the milestone is about.
func _test_the_fire_she_did_not_choose_leaves_her_a_way_out(t) -> void:
	var scars_before := GameState.scars.duplicate()
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(Tuning.RUN_TAUGHT_DAY)
	var plan := _fire_plan()
	if not plan:
		t.check(false, "day 3 has a fire to walk up to")
		_city.events.stream_radius = INF
		return
	var route := _a_route_out(Tuning.RUN_TAUGHT_DAY)
	var rig := _walker(t, route[0])
	_walk_clock = 0.0
	_walk(rig, route,
			func() -> bool: return plan.is_placed() and _city.events._is_on_screen(plan.position))
	t.check(plan.is_placed() and _city.events._is_on_screen(plan.position),
			"she walks out and finds the fire")
	if not plan.is_placed():
		rig.free()
		_city.events.stream_radius = INF
		return

	var fire: EventInstance = plan.live
	t.check(fire != null, "the fire is in the world by the time it is on screen")
	if fire:
		# **What the first sight owes is the walk out of it, not a clear screen.** The fire is on the
		# route she is walking, so it can come into view from any direction — and the view is
		# `Tuning.VIEW_HALF_EXTENT` (320 x 180), narrower on its short axis than the fire's own
		# 260px outer radius, so an approach up or down the screen puts it in sight with the outer
		# edge of the field already on her. That is the telegraph contract's own worst case rather
		# than a hole in it: what it promises is that a player who turns round the instant she sees
		# a thing gets clear before it is at full strength, which is exactly this measurement.
		var range_to_it := rig.global_position.distance_to(fire.global_position)
		t.check(range_to_it > plan.def.inner_radius,
				("she first sees it %.0fpx off, outside the %.0fpx where its field is at full "
				% [range_to_it, plan.def.inner_radius]) + "strength")
		t.check((plan.def.outer_radius - range_to_it) / Tuning.WALK_SPEED
				<= plan.def.telegraph_time,
				("and walking away from it clears the field in %.2fs, inside the %.2fs its "
				% [maxf(plan.def.outer_radius - range_to_it, 0.0) / Tuning.WALK_SPEED,
				plan.def.telegraph_time]) + "telegraph buys her")
	var engines := 0
	for instance in _city.events.instances():
		if instance.def.id != "fire_truck":
			continue
		engines += 1
		t.close_to(instance.contribution_at(rig.global_position), 0.0,
				"and the engine it calls in is outside its own forward reach of her when it is "
				+ "created, from the worst position the sighting allows", 0.001)
		# **It is aimed at where the fire actually is**, which is the half a runtime siting could
		# break: the route is built from the live instance's position when it is first seen, and a
		# plan stops being movable at its first stream-in, so the two can never be a fire that moved
		# after the engine was sent to where it used to be. The end of the route is the near kerb
		# across from the frontage it is burning against — `EventManager._summon_the_sighted_row()`.
		t.check(instance.path.size() == 2, "and it is given a route down the fire's own street")
		if instance.path.size() == 2:
			var inward := _city.map.pavement_inward(_city.map.world_to_tile(plan.position))
			var kerb: Vector2 = plan.position - Vector2(inward) \
					* (Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
			t.close_to(instance.path[1].distance_to(kerb), 0.0,
					"ending at the near kerb across from where the fire is actually burning", 1.0)
	t.check(engines == 1, "seeing the fire calls in exactly one engine (%d)" % engines)

	# **The whole of what the pair owes, measured where she is standing when she meets it.** Both
	# fields are closed ground here, not only the bodies: the fire is 260px of field on a 30px body
	# and the parked engine is 340px on no body at all, and what she is asked to do is go another
	# way rather than walk through either. Rebuilt from the map rather than read off `WalkSiting`,
	# so a check that agreed with the siting only because it shared its arithmetic would not pass.
	var blocked := _city.map.closed_tiles.duplicate()
	for other in _city.events.plans():
		if not other.is_placed():
			continue
		var radius := maxf(other.def.obstructs_radius,
				other.def.inner_radius if other.def.hard_fail else 0.0)
		_block(blocked, other.position, radius)
	_block(blocked, plan.position, plan.def.outer_radius)
	var engine_def := EventCatalogue.by_id(plan.def.spawns_on_sight)
	var parked := EventManager.where_the_summoned_row_stops(_city.map, plan.position)
	if engine_def and parked != Vector2.INF:
		_block(blocked, parked, engine_def.outer_radius)
	var grid := ReachabilityGrid.build(_city.map)
	# **From where she can retreat to, not from where she is standing.** She sees the fire the
	# moment it enters the view, which is 180px deep against a 260px field — so on an approach up or
	# down the screen she is already inside the field when she first sees it, and a flood started on
	# a blocked tile answers nothing. What the pair owes is that stepping back out of both fields is
	# possible and leaves her somewhere to go, so the retreat is the first thing measured.
	var her := _retreat_from(_city.map.world_to_tile(rig.global_position), blocked)
	t.check(her != Vector2i(-1, -1),
			"she can step back out of both fields from where she first sees the fire")
	if her == Vector2i(-1, -1):
		rig.free()
		_city.events.stream_radius = INF
		GameState.scars = scars_before
		return
	var reached := grid.flood([her], blocked)
	t.check(grid.reaches(_city.map.home_rect.position, blocked, reached),
			"and from where she is standing when she first sees it the way home is still open "
			+ "without entering either field")
	var unused := _calm_she_has_not_used()
	var out := false
	for tile in unused:
		out = out or grid.reaches(tile, blocked, reached)
	t.check(out and not unused.is_empty(),
			("and so is a calm area she has not used (%d tiles of them)" % unused.size())
			+ " — the day still works around the pair")
	rig.free()
	_city.events.stream_radius = INF
	GameState.scars = scars_before

## **A fire that was never lit was not spent.** *"What the run has spent stays spent ... a fire that
## burnt a block down did happen"* (`GameState.finish_day`) — so a set piece the day owed her walk is
## consumed where it becomes real rather than where it is planned, and a day 3 lost before she ever
## got near it is offered it again. A day on which it burned is not: the city remembers that one, and
## the shell is standing in it.
func _test_a_fire_that_was_never_lit_was_not_spent(t) -> void:
	var scars_before := GameState.scars.duplicate()
	var consumed: Array[String] = []
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var day := Tuning.RUN_TAUGHT_DAY
	_city.events.start_day(day, _rng(day), consumed)
	t.check(not "burning_building" in consumed and _fire_plan() != null,
			"day 3 budgets the fire without spending it, because a plan with no position promises "
			+ "nothing yet")

	# Lost without her ever walking out to it. The same day, again, still owes her one.
	_city.events.start_day(day, _rng(day), consumed)
	t.check(_fire_plan() != null, "a day 3 lost before she reached it is offered it again")

	# Now she walks into it. That is the fire the run remembers, and there is not a second one.
	var plan := _fire_plan()
	var route := _a_route_out(day)
	var rig := _walker(t, route[0])
	_walk_clock = 0.0
	_walk(rig, route, func() -> bool: return plan.was_live)
	t.check(plan.was_live and "burning_building" in consumed,
			"walking into it is what spends it")
	_city.events.start_day(day, _rng(day), consumed)
	t.check(_fire_plan() == null, "and no later day plans a second one")
	rig.free()
	_city.events.stream_radius = INF
	GameState.scars = scars_before

