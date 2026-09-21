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
	_test_a_fire_that_was_never_lit_was_not_spent(t)
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
## Every cardinal, and one diagonal because a press sets an arbitrary unit vector and most real
## headings are not square to the lattice.
const WALKS := {
	"east": Vector2.RIGHT,
	"west": Vector2.LEFT,
	"north": Vector2.UP,
	"south": Vector2.DOWN,
	"north-east": Vector2(0.7071, -0.7071),
}
## Long enough that a siting at the far end of the band (`EventDirector.ON_HER_WAY_SIGHT`) is met
## with the outbound leg of a 180s day still in hand.
const WALK_SECONDS := 70.0

## A player the manager can find, out of the physics loop and moved by hand at `Tuning.WALK_SPEED`.
##
## **It walks through the lattice rather than round it, and that is the rig being honest about what
## it tests.** What is under test is where the day sites a place against the direction she is
## *travelling*; a rig that turned at every frontage would be testing the collision shape, and one
## that only ever walked legal ground could not hold a heading long enough to ask the question.
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

## Steps the manager for `seconds` of walking in `heading`, stopping the frame `until` answers true.
## Returns the heading she was travelling on the last frame, which is `heading` unless the map's
## edge turned her round.
##
## **She turns round at the border rather than walking off it**, because a straight line long enough
## to meet a fire sited up to `EventDirector.ON_HER_WAY_SIGHT` seconds of walking ahead is longer
## than the city on most headings. That is not a workaround: a player who reaches the boundary turns
## round too, and it is exactly the case the re-siting exists for.
func _walk(rig: Stroller, heading: Vector2, seconds: float, until := Callable()) -> Vector2:
	var walked := 0.0
	while walked < seconds:
		var margin := heading * Tuning.TILE_SIZE * 4.0
		if not _city.map.in_bounds(_city.map.world_to_tile(rig.global_position + margin)):
			heading = -heading
		rig.velocity = heading * Tuning.WALK_SPEED
		rig.global_position += heading * Tuning.WALK_SPEED * WALK_STEP
		_city.events._physics_process(WALK_STEP)
		walked += WALK_STEP
		_walk_clock += WALK_STEP
		if until.is_valid() and until.call():
			return heading
	return heading

func _fire_plan() -> EventScheduler.Planned:
	for plan in _city.events.plans():
		if plan.def.id == "burning_building":
			return plan
	return null

## **The fire is on the way she is taking, whichever way that is.** The day plans it with no
## position at all; walking any of the five headings below from the doorstep has it sited ahead of
## her, off screen, and brought into view by continuing to walk.
##
## The two numbers checked on the siting itself are the ones the design is stated in: it is *ahead*
## (inside `EventDirector.ON_HER_WAY_CONE` of the heading she was travelling) and it is *off screen*
## (outside the streaming band, so nothing about it is visible and nothing about it is real yet).
func _test_the_fire_is_sited_on_the_way_she_is_walking(t) -> void:
	var scars_before := GameState.scars.duplicate()
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	for heading_name: String in WALKS:
		var heading: Vector2 = WALKS[heading_name]
		_start(Tuning.RUN_TAUGHT_DAY)
		var plan := _fire_plan()
		t.check(plan != null and not plan.is_placed(),
				"walking %s: day 3 budgets a fire and leaves it for her walk to site" % heading_name)
		if not plan:
			continue
		var rig := _walker(t, _city.map.home_world_position())
		var sited_from := Vector2.ZERO
		var sited_at := -1.0
		var seen_at := -1.0
		_walk_clock = 0.0
		while _walk_clock < WALK_SECONDS and seen_at < 0.0:
			var before := plan.is_placed()
			var here := rig.global_position
			heading = _walk(rig, heading, WALK_STEP)
			if not before and plan.is_placed():
				sited_at = _walk_clock
				sited_from = here
				t.check(plan.position.distance_to(here) > Tuning.EVENT_STREAM_RADIUS,
						("walking %s: the fire is sited %.0fpx out, past the %.0fpx streaming band, "
						% [heading_name, plan.position.distance_to(here), Tuning.EVENT_STREAM_RADIUS])
						+ "so it is neither visible nor real when it is placed")
				var toward := plan.position - here
				var across := Vector2(-heading.y, heading.x)
				t.check(toward.dot(heading) > 0.0
						and absf(toward.dot(across)) <= EventDirector.ON_HER_WAY_DRIFT,
						("walking %s: and it is on the line she is walking — %.0fpx along it and "
						% [heading_name, toward.dot(heading)])
						+ "%.0fpx off it, inside the %.0fpx that keeps it in view when she reaches it"
						% [absf(toward.dot(across)), EventDirector.ON_HER_WAY_DRIFT])
			if plan.is_placed() and _city.events._is_on_screen(plan.position):
				seen_at = _walk_clock
		t.check(sited_at >= 0.0, "walking %s: the fire is sited at all" % heading_name)
		t.check(seen_at >= 0.0,
				"walking %s: and continuing to walk brings it into view (%.1fs in)"
				% [heading_name, seen_at])
		if seen_at >= 0.0:
			print("      fire %s: sited %.1fs in, %.0fpx ahead, first seen %.1fs later"
					% [heading_name, sited_at, plan.position.distance_to(sited_from),
					seen_at - sited_at])
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
	var rig := _walker(t, _city.map.home_world_position())
	_walk_clock = 0.0
	var heading := _walk(rig, Vector2.RIGHT, WALK_SECONDS,
			func() -> bool: return plan.is_placed())
	t.check(plan.is_placed(), "walking sites it")
	if not plan.is_placed():
		rig.free()
		_city.events.stream_radius = INF
		return

	heading = _walk(rig, heading, WALK_SECONDS, func() -> bool: return plan.was_live)
	t.check(plan.was_live, "and walking on puts it in the world")
	if plan.was_live:
		var burning_at := plan.position
		var scar_here := false
		for scar in GameState.scars:
			scar_here = scar_here or (String(scar["id"]) == "burnt_shell"
					and Vector2(scar["position"]).distance_to(burning_at) < 1.0)
		t.check(scar_here, "and the scar the run keeps is where it actually burned")
		_walk(rig, -heading, 20.0)
		t.check(plan.position == burning_at,
				"and turning round after it is real leaves it exactly where it burned")
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
	var rig := _walker(t, _city.map.home_world_position())
	_walk_clock = 0.0
	var heading := _walk(rig, Vector2.RIGHT, WALK_SECONDS, func() -> bool: return plan.is_placed())
	_walk(rig, heading, WALK_SECONDS, func() -> bool: return plan.was_live)
	t.check(plan.was_live and "burning_building" in consumed,
			"walking into it is what spends it")
	_city.events.start_day(day, _rng(day), consumed)
	t.check(_fire_plan() == null, "and no later day plans a second one")
	rig.free()
	_city.events.stream_radius = INF
	GameState.scars = scars_before

