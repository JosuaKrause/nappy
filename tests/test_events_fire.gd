extends "res://tests/events_shared_city.gd"
## Day 3's fire: budgeted at dawn with no position and sited by `EventDirector` from the walk she
## turns out to take -- *"the fire should come first and be on your way guaranteed (a dynamic event
## dependent on the route you chose that day)"* (PLAYTEST-117).
##
## These drive the director directly, with her position and velocity written rather than walked, so
## the geometry is the test's own: what a city's borders happen to leave room for is the integration
## question and it is asked in `tests/test_event_manager.gd`, against a real manager and a real
## player. What is asked here is the rule.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again". Extends
## `events_shared_city.gd` since every helper below sites against the one shared generated city.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_director_puts_it_in_front_of_her(t)
	_test_the_fire_follows_her_walk_until_it_is_real(t)
	_test_a_corner_is_not_a_change_of_mind(t)
	_test_the_engine_parks_at_the_fire(t)
	_test_a_site_that_shuts_her_out_is_refused(t)
	_test_the_fire_is_the_days_only_unsited_place(t)
	_test_the_crews_on_her_way_move_no_other_row(t)
	_test_a_rig_meets_the_three_things_that_arrive(t)
	_test_hard_fail_only_when_active(t)


## Walks a synthetic player down `route` from `at`, stepping the director every frame, and returns
## where she finished. She moves at `Tuning.WALK_SPEED` because the director's own clock only runs
## while she is actually going somewhere, and the heading it reads is the direction of the next
## point of the route — so the walk is a walk of the day's own corridor rather than a line through
## the lattice, which is what the siting is stated over.
##
## `_last_heading` carries the direction of the last step out, for a caller that needs to ask what
## she was travelling on the frame something happened.
var _last_heading := Vector2.RIGHT

func _walk_the_director(director: EventDirector, plans: Array[EventScheduler.Planned],
		at: Vector2, route: PackedVector2Array, seconds: float, until := Callable()) -> Vector2:
	var left := seconds
	for i in range(_nearest_on(route, at), route.size()):
		var toward := route[i] - at
		while toward.length() > Tuning.WALK_SPEED * STEP and left > 0.0:
			_last_heading = toward.normalized()
			var velocity := _last_heading * Tuning.WALK_SPEED
			at += velocity * STEP
			left -= STEP
			director.site_what_is_on_her_way(STEP, at, velocity, plans)
			if until.is_valid() and until.call():
				return at
			toward = route[i] - at
		if left <= 0.0:
			return at
	return at

func _nearest_on(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in route.size():
		var distance := route[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

## A way out of the doorstep that does not carry `unlike` — the other side of a fork, for the check
## that an unseen fire follows the branch she actually took.
func _another_branch(day: int, unlike: Vector2) -> PackedVector2Array:
	var tree := RouteTree.for_day(_map(), day)
	var carries := tree.branches_on(_map().world_to_tile(unlike))
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() < 8:
				continue
			var shares := false
			for colour in carries:
				shares = shares or branch.routes.size() > 0 and colour == tree.branches.find(branch)
			if shares:
				continue
			var points := PackedVector2Array()
			for i in route.size():
				points.append(EventScheduler.WalkSiting._cell_centre(_map(),
						route[route.size() - 1 - i]))
			return points
	return PackedVector2Array()

## The day's longest route as the line she walks — out from the doorstep to the calm area when
## `outward`, home again when not. A route is grown from the area to the doorstep, so the walk out
## is the array reversed.
func _fire_route(day: int, outward := true) -> PackedVector2Array:
	var tree := RouteTree.for_day(_map(), day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for i in best.size():
		var cell: Vector2i = best[best.size() - 1 - i] if outward else best[i]
		points.append(EventScheduler.WalkSiting._cell_centre(_map(), cell))
	return points

## Day 3's plan, built fresh rather than taken from `_planned()`. These tests site the fire, which
## writes a position into the plan — and the memoized copy is shared with every other check in this
## suite on the understanding that nothing writes to it.
func _fire_day_plans() -> Array[EventScheduler.Planned]:
	var consumed: Array[String] = []
	return EventScheduler.build_day(Tuning.RUN_TAUGHT_DAY, _rng(Tuning.RUN_TAUGHT_DAY), _map(),
			consumed)

## The placement context the director above is started on, built the way `EventManager.start_day`
## builds one. Kept as its own function so a check can ask it the same questions the director does —
## `still_ahead_of()`, which is what "on the branch she is walking" means.
var _shared_fire_siting: EventScheduler.WalkSiting = null

## The day-3 fire, and the whole rig it needs: the day's own plan, a placement context built the way
## `EventManager.start_day` builds one, and a director started on both.
func _fire_director(day: int, plans: Array[EventScheduler.Planned]) -> EventDirector:
	var director := EventDirector.new(_map())
	director.start_day(day, plans, _rng(day), _fire_siting(day))
	return director

func _fire_siting(day: int) -> EventScheduler.WalkSiting:
	if not _shared_fire_siting:
		_shared_fire_siting = EventScheduler.WalkSiting.new(day, _map(),
				RouteTree.for_day(_map(), day), [] as Array[Vector2i], PackedVector2Array())
	return _shared_fire_siting

func _fire_in(plans: Array[EventScheduler.Planned]) -> EventScheduler.Planned:
	for plan in plans:
		if plan.def.id == "burning_building":
			return plan
	return null

func _instance(t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

## Playtest 04: *"the cat is ineffective since it happens when it spawns — the cat should get
## spawned in in front of the player while they walk, so it happens directly in front of them
## every time."*
##
## The three properties that make an interruption legal, in the order they matter. It has to be
## *in front of her*, or it is not the thing that was asked for. It has to start *outside its
## own outer radius*, or an event with no telegraph phase is being dropped on top of her. And
## the clock has to run on walking, not on wall time, or a player who stops in a park to let the
## meter recover comes back to the pavement owing four cats.
func _test_the_director_puts_it_in_front_of_her(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var plans: Array[EventScheduler.Planned] = [
		EventScheduler.Planned.new(EventCatalogue.by_id("cat_dash"), Vector2.INF),
		EventScheduler.Planned.new(EventCatalogue.by_id("cat_dash"), Vector2.INF),
	]
	director.start_day(1, plans, rng)
	t.check(director.owed() == 2, "the day's budget is what the director gets to spend")

	# Somewhere on a street, walking north. `arterial_pavement` is a pavement lane by
	# construction, so the lead lands on walkable ground.
	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var north := Vector2(0.0, -Tuning.WALK_SPEED)

	# Standing still owes nothing, however long she stands there.
	var fired := false
	for i in int(round(60.0 / STEP)):
		fired = fired or not director.due(STEP, at, Vector2.ZERO).is_empty()
	t.check(not fired, "nothing crosses in front of somebody who is not going anywhere")
	t.check(director.owed() == 2, "so a minute of standing still spends none of the day")

	# Walking does.
	var due: Array = []
	for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
		due = director.due(STEP, at, north)
		if not due.is_empty():
			break
	t.check(not due.is_empty(), "walking for the length of the interval brings one out")
	if due.is_empty():
		return

	var path := due[1] as PackedVector2Array
	t.check(path.size() == 2, "it is given a route across her line")
	var def := due[0] as EventDef
	# The cat is `still_while_telegraphing`, so its lead is `EventDef.ahead_of_player_lead()` —
	# longer than the flat `AHEAD_LEAD_DISTANCE` by exactly the ground she covers while it holds
	# its crouch — rather than the constant every other crossing row is sited at.
	var lead := def.ahead_of_player_lead()
	t.check(lead > Tuning.AHEAD_LEAD_DISTANCE,
			"the cat's own lead (%.0fpx) accounts for its held crouch, not just a flat reaction "
			% lead + "window (%.0fpx)" % Tuning.AHEAD_LEAD_DISTANCE)
	var crossing := (path[0] + path[1]) * 0.5
	t.close_to(crossing.distance_to(at), lead,
			"it crosses where she is about to be, not where she is", 1.0)
	t.check((crossing - at).normalized().dot(north.normalized()) > 0.99,
			"and that is in front of her rather than beside or behind her")
	t.close_to((path[1] - path[0]).normalized().dot(north.normalized()), 0.0,
			"the run is square across her line", 0.01)

	# The fairness half. It starts at one end of that run, and both ends are further from her
	# than the field it will emit — so she is outside it the whole time it is telegraphing, and
	# the reaction window is real rather than nominal.
	for end in [path[0], path[1]]:
		t.check(at.distance_to(end) > def.outer_radius,
				"she is outside its reach (%.0fpx) when it appears (%.0fpx away)"
				% [def.outer_radius, at.distance_to(end)])
	t.check(lead / Tuning.WALK_SPEED >= 1.5,
			"and the lead is %.1fs of walking, which is time to do something about it"
			% (lead / Tuning.WALK_SPEED))
	t.check(director.owed() == 1, "and the day is one cat poorer")

## **It is sited from her walk, it may be moved while it is nobody's memory yet, and it is fixed the
## moment it is real.**
##
## The third of those is the one with teeth. `EventManager._stream_in` records the scar and moves the
## block along its arc the first time a plan enters the world, so the city already remembers this
## fire burning *there* — and a rule that moved it afterwards would be repairing a fact rather than
## checking one before accepting it. `Planned.was_live` is where the line is drawn, and it is drawn
## at the streaming radius rather than at the screen edge, which is six seconds of walking earlier.
func _test_the_fire_follows_her_walk_until_it_is_real(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var plans := _fire_day_plans()
	var fire := _fire_in(plans)
	t.check(fire != null and not fire.is_placed(),
			"day 3 budgets the fire and leaves it with no position at all")
	if not fire:
		return
	var director := _fire_director(day, plans)
	var siting := _fire_siting(day)

	var out := _fire_route(day)
	var at := _walk_the_director(director, plans, out[0], out, 120.0,
			func() -> bool: return fire.is_placed())
	t.check(fire.is_placed(), "walking the day's own route out of the doorstep sites it")
	if not fire.is_placed():
		return
	var first := fire.position
	t.check(not RouteTree.for_day(map, day).branches_on(map.world_to_tile(first)).is_empty(),
			"on the path she is on: the day's route tree carries the tile it stands on")
	t.check(siting.still_ahead_of(at, _last_heading, first),
			"and ahead of her along the branch she is walking, rather than merely ahead of her")
	t.check(first.distance_to(at) > Tuning.EVENT_STREAM_RADIUS,
			"and outside the streaming band (%.0fpx), so it is neither seen nor real yet"
			% first.distance_to(at))

	# Home and out again the other way. It was never in the world, so it follows her onto the branch
	# she actually took — which is the whole of what a fork owes, and the one case a rule stated only
	# over "is it behind her" cannot answer: the way out she abandoned stays a few degrees off
	# square from the way she took, for the rest of the day.
	at = _walk_the_director(director, plans, at, _fire_route(day, false), 200.0)
	var other := _another_branch(day, first)
	t.check(not other.is_empty(), "the day offers a second way out to change her mind to")
	at = _walk_the_director(director, plans, at, other, 200.0,
			func() -> bool: return fire.position != first)
	t.check(fire.position != first, "taking a different way out before it is ever seen moves it")
	t.check(siting.still_ahead_of(at, _last_heading, fire.position),
			"and it lands ahead of her on the branch she took instead")

	# Real. From here it is where the city remembers it burning, and nothing moves it.
	var burning_at := fire.position
	fire.was_live = true
	_walk_the_director(director, plans, at, _fire_route(day), 30.0)
	t.check(fire.position == burning_at,
			"once it has been in the world, walking away from it for half a minute leaves it "
			+ "exactly where it burned")

## **A corner is not a change of mind.** A route turns every block or two, and each turning leaves
## the fire a little behind square — a rule that moved it there would move it at every junction,
## which is a day spent chasing something that is always the same distance ahead.
## `EventDirector.ON_HER_WAY_BEHIND` is the coarse half of what makes the two cases different and
## `WalkSiting.still_ahead_of()` the fine one, and this is the half of it that would otherwise never
## be noticed: the *absence* of a move.
##
## **The walk has to actually turn**, or the check passes by walking in a straight line and proves
## nothing; the corner it took is measured and asserted alongside.
func _test_a_corner_is_not_a_change_of_mind(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	var plans := _fire_day_plans()
	var fire := _fire_in(plans)
	if not fire:
		t.check(false, "day 3 budgets a fire to turn a corner past")
		return
	var director := _fire_director(day, plans)
	var out := _fire_route(day)
	var at := _walk_the_director(director, plans, out[0], out, 120.0,
			func() -> bool: return fire.is_placed())
	if not fire.is_placed():
		t.check(false, "walking the day's route sites the fire")
		return
	var sited := fire.position

	# On down the same branch for twice the patience the rule has, which is several turnings.
	var before := _last_heading
	var sharpest := 1.0
	var patience := EventDirector.ON_HER_WAY_TURNED_AWAY * 2.0
	for i in int(round(patience / STEP)):
		at = _walk_the_director(director, plans, at, out, STEP)
		sharpest = minf(sharpest, before.dot(_last_heading))
	t.check(fire.position == sited,
			"carrying on down the same branch for %.0fs leaves the fire where it is" % patience)
	t.check(sharpest < 0.7,
			"and the walk really did turn a corner in that time (%.0f degrees off where it started)"
			% rad_to_deg(acos(clampf(sharpest, -1.0, 1.0))))

## **The engine parks at the fire and stays there for the rest of the day.** *(2026-09-20, the
## player, asked whether it parks, waits twenty seconds or passes through: "option A -- a fire engine
## has a high cost"; "you're not supposed to go past it".)* Driven here rather than in a city,
## because what is under test is what an instance does when its route runs out — which needs a route
## and a clock and nothing else.
##
## Four things are checked and every one of them was wrong before the flag existed. It **stops**
## where the route ended rather than driving on out of sight. It is **not over**: it still emits,
## which is the entire cost the player asked for, where `is_leaving` would have silenced it. It
## **answers zero for its travel**, which is what the screen-edge badge reads as a closing speed.
## And the distance it has covered **stops growing**, because the gait is driven by distance and a
## parked engine would otherwise bob at the kerb for ever.
func _test_the_engine_parks_at_the_fire(t) -> void:
	var def := EventCatalogue.by_id("fire_truck")
	t.check(def != null and def.stops_where_it_arrives,
			"the fire engine is the row that stops where it arrives")
	if not def:
		return
	var kerb := Vector2(def.speed * 2.0, 0.0)
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, kerb]))
	# Past the end of a two-second route by a good margin, and then a while longer.
	_advance(instance, 4.0)
	t.check(instance.is_parked, "it parks when its route runs out")
	t.check(not instance.is_leaving and not instance.is_finished,
			"and parking is not an ending: it has neither left nor finished")
	t.close_to(instance.global_position.distance_to(kerb), 0.0,
			"it is standing at the end of its route, the near kerb across from the fire", 1.0)
	t.close_to(instance.travel_velocity().length(), 0.0,
			"and it answers zero for how fast it is travelling, so nothing reads it as closing",
			0.001)
	t.check(instance.contribution_at(kerb + Vector2(def.inner_radius * 0.5, 0.0)) > 0.0,
			"it is still emitting where it stands, which is the cost the pair is made of")
	var travelled := instance.path_travelled()
	_advance(instance, 6.0)
	t.close_to(instance.path_travelled(), travelled,
			"and ten seconds later it has covered no more ground, so the gait it is drawn with "
			+ "has stopped too", 0.001)
	t.check(instance.is_parked and not instance.is_finished,
			"and it is still standing there, for the rest of the day")
	instance.free()

## **A site is accepted only where the day still works around it.** The fire and the engine parked
## across from it are meant to close the street she is on, so the thing that has to be checked is the
## other direction: from where she is, with both fields taken as closed ground, the home and a calm
## area she has not used are still reachable. Checked before accepting; a refusal is a second of
## walking and another attempt.
##
## Both directions are asked, because a check that refused everything would pass the interesting half
## of this on its own. The refusal case is a fire sited on the doorstep itself, whose field swallows
## the one way out of the home — the shape the check exists for, and the one no amount of walking
## could answer.
func _test_a_site_that_shuts_her_out_is_refused(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY
	var def := EventCatalogue.by_id("burning_building")
	var siting := EventScheduler.WalkSiting.new(day, map, RouteTree.for_day(map, day),
			[] as Array[Vector2i], PackedVector2Array())
	var nothing_else: Array[EventScheduler.Planned] = []
	var route := _fire_route(day)
	t.check(route.size() > 8, "the day has a route out of the doorstep to stand on")
	if route.size() <= 8:
		return
	var at: Vector2 = route[route.size() / 2]

	var far_off := EventScheduler.Planned.new(def, route[route.size() - 2])
	t.check(siting._still_leaves_a_park_reachable(nothing_else, far_off, at),
			"a fire at the far end of the branch she is walking leaves the day working around it")

	var on_the_doorstep := EventScheduler.Planned.new(def, map.doorstep_world_position())
	t.check(not siting._still_leaves_a_park_reachable(nothing_else, on_the_doorstep, at),
			"and a fire whose field swallows the doorstep is refused, because the way home is what "
			+ "she would have no way round")

## **One set piece, the day's crews, and the day is otherwise exactly the day it was.** A set piece
## the day owes her walk is budgeted like any other one-shot — one plan, tagged as its own group.
## The only other rows left for the walk to site are the poster crews, rolled at dawn like any
## recurring row and handed over with no position (`EventScheduler._hand_to_her_walk`), so no other
## row changes shape because of either.
func _test_the_fire_is_the_days_only_unsited_place(t) -> void:
	var owed := 0
	var crews := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if not plan.def.sited_on_her_way:
				continue
			t.check(not plan.is_placed(), "day %d: '%s' is planned with no position"
					% [day, plan.def.id])
			t.check(plan.def.spawn_mode == EventDef.SpawnMode.MAP and not plan.def.mobile,
					"day %d: and it is a place that stands still, not a director's moment" % day)
			if plan.def.kind != GameEnums.EventKind.ONE_SHOT:
				crews += 1
				t.check(plan.def.id == "poster_crew" and plan.def.pastes_a_front,
						"day %d: the only recurring row left for her walk is the poster crew, not '%s'"
						% [day, plan.def.id])
				continue
			owed += 1
			t.check(day == Tuning.RUN_TAUGHT_DAY and plan.def.id == "burning_building",
					"day %d: the only set piece the day leaves for her walk is day 3's fire, not '%s'"
					% [day, plan.def.id])
			t.check(plan.set_piece_group != "", "day %d: and it is tagged as a set piece" % day)
	t.check(owed == 1, "exactly one set piece in a fourteen-day run is owed to her walk (%d)" % owed)
	t.check(crews > 0, "and there are poster crews for her walk to site (%d)" % crews)

## **Handing the crews to her walk moves no other row.** The dawn roll still places every crew by
## its own `pavement_side` and only then drops the position, so the day planned with the crews
## handed over and the day planned with the flag off are the same day, row for row and place for
## place, and differ only in where the crews stand.
func _test_the_crews_on_her_way_move_no_other_row(t) -> void:
	var map := CityGenerator.generate(4242)
	var crew := EventCatalogue.by_id("poster_crew")
	for day in [4, 8, 12]:
		var tree := RouteTree.for_day(map, day)
		var handed := EventScheduler.build_day(day, _rng(day), map, [], [], [], tree)
		crew.sited_on_her_way = false
		var kept := EventScheduler.build_day(day, _rng(day), map, [], [], [], tree)
		crew.sited_on_her_way = true
		var same := handed.size() == kept.size()
		var crews := 0
		for i in mini(handed.size(), kept.size()):
			same = same and handed[i].def.id == kept[i].def.id
			if handed[i].def.id == "poster_crew":
				crews += 1
				same = same and not handed[i].is_placed() and kept[i].is_placed()
			else:
				same = same and handed[i].position == kept[i].position
		t.check(crews > 0, "day %d: the day rolled crews (%d)" % [day, crews])
		t.check(same, "day %d: every other row stands where the roll put it, crews or no crews" % day)

## **The three rows that never had an impact, meeting the rig they were designed for.** The bike,
## the loose dog and the cat were each sited in a way that meant she could walk the whole day
## without ever crossing paths with one — `cyclist` and `loose_dog` on a street the day chose at
## dawn, `cat_dash` aimed at where she was rather than where she would be. This is the point of
## fixing all three: not that the siting geometry is fair on paper, but that a rig walking a real
## street actually **meets** each of them — comes within its own `outer_radius`, the same measure
## the fairness contract and the cost table are both stated over.
##
## Driven through `EventDirector` exactly as `EventManager` drives it in play, on a real generated
## map, walking continuously the way `due()` requires before it will ever site anything.
func _test_a_rig_meets_the_three_things_that_arrive(t) -> void:
	for id in ["cat_dash", "cyclist", "loose_dog"]:
		var def := EventCatalogue.by_id(id)
		var map := _map()
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
		director.start_day(def.first_day, plans, rng)

		# Somewhere on a street, walking north — the same rig `_test_the_director_puts_it_in_front_
		# of_her` walks, so a real street is guaranteed long enough for this.
		var at := CrowdLanes.arterial_pavement(map)
		at.y = map.world_size().y * 0.5
		var north := Vector2(0.0, -Tuning.WALK_SPEED)

		var due: Array = []
		for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
			due = director.due(STEP, at, north)
			at += north * STEP
			if not due.is_empty():
				break
		t.check(not due.is_empty(), "'%s' is sited while she walks a real street" % id)
		if due.is_empty():
			continue

		var path := due[1] as PackedVector2Array
		# A row that comes down her line is warned of first: she walks on through its warning, and
		# it is created where the warning then points, its telegraph spent — `EventManager`'s
		# `_warn_down_her_line()` and `spawn_warned()`.
		if def.warns_before_it_exists():
			var direction := (path[0] - path[1]).normalized()
			for i in int(ceil(def.telegraph_time / STEP)):
				at += north * STEP
			path = PendingWarning.route_down_her_line(map,
					PendingWarning.down_her_line(map, def, at, direction), at, direction)
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		if def.warns_before_it_exists():
			instance.resume(def.telegraph_time, 0.0)
		t.add_child(instance)
		instance.set_process(false)

		var closest := INF
		for i in int(round(15.0 / STEP)):
			at += north * STEP
			instance.player_at = at
			instance._process(STEP)
			closest = minf(closest, instance.global_position.distance_to(at))
			if instance.is_finished:
				break
		t.check(closest <= def.outer_radius,
				"'%s' actually meets the rig (closest %.0fpx of a %.0fpx reach)"
				% [id, closest, def.outer_radius])
		instance.free()

func _test_hard_fail_only_when_active(t) -> void:
	var def := EventDef.new()
	def.id = "test_hard_fail"
	def.intensity = 20.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.hard_fail = true
	def.telegraph_time = def.minimum_telegraph()
	t.check(def.validate(), "a hard-fail event with the doubled margin is fair")

	var instance := _instance(t, def)
	t.check(not instance.is_lethal_at(Vector2.ZERO),
			"a telegraphing hard-fail event is not yet lethal - that is the warning")
	_advance(instance, def.telegraph_time + 0.05)
	t.check(instance.is_lethal_at(Vector2(10.0, 0.0)),
			"an active hard-fail event is lethal inside its inner radius")
	t.check(not instance.is_lethal_at(Vector2(100.0, 0.0)),
			"a hard-fail event is not lethal outside its inner radius")
	instance.free()

	var safe := EventCatalogue.by_id("cat_dash")
	var harmless := _instance(t, safe)
	_advance(harmless, safe.telegraph_time + 0.05)
	t.check(not harmless.is_lethal_at(Vector2.ZERO), "an ordinary event is never lethal")
	harmless.free()
