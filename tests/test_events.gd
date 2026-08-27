extends RefCounted
## The event system: the fairness contract, the emission model, and the scheduler's
## determinism and safety rules.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_catalogue_is_fair(t)
	_test_telegraph_damps_emission(t)
	_test_pulse_envelope(t)
	_test_duration_and_finish(t)
	_test_mobile_follows_its_path(t)
	_test_a_crouching_event_holds_still_until_it_bolts(t)
	_test_the_director_puts_it_in_front_of_her(t)
	_test_hard_fail_only_when_active(t)
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_one_park_stays_usable(t)
	_test_successors_resolve(t)
	_test_burning_building_is_never_scheduled(t)
	_test_fire_truck_is_a_day_three_one_shot(t)
	_test_along_street_paths_stay_in_bounds(t)
	_test_nothing_is_cheaper_to_walk_through_than_around(t)
	_test_the_pavement_can_be_blocked_from_day_one(t)
	_test_a_day_has_enough_in_it_to_meet(t)
	_test_the_caps_can_spend_the_budget(t)
	_test_the_named_decisions_arrive(t)
	_test_two_of_a_kind_are_not_the_same_incident(t)
	_test_nothing_happens_inside_a_lethal_field(t)

# ------------------------------------------------------------------ fairness ---

## The contract from docs/EVENTS.md: a player who starts walking away the instant an event
## becomes visible clears its outer radius before it reaches full strength. A violation is
## a bug, not a difficulty setting, so the whole catalogue is checked.
func _test_catalogue_is_fair(t) -> void:
	var defs := EventCatalogue.all()
	t.check(not defs.is_empty(), "the catalogue is not empty")
	for def in defs:
		t.check(def.id != "", "every event has an id")
		t.check(def.validate(), "event '%s' gives the player time to walk clear" % def.id)
		if def.kind != GameEnums.EventKind.AMBIENT:
			t.check(def.telegraph_time >= def.minimum_telegraph(),
					"event '%s' telegraph %.2fs >= minimum %.2fs"
					% [def.id, def.telegraph_time, def.minimum_telegraph()])
		t.check(def.outer_radius > def.inner_radius,
				"event '%s' has a falloff band to fade across" % def.id)

	# Ambient events are exempt because they never "appear"; assert that is deliberate.
	var playground := EventCatalogue.by_id("playground")
	t.check(playground.kind == GameEnums.EventKind.AMBIENT,
			"the playground is ambient, so its zero telegraph is intended")

# ------------------------------------------------------------------ emission ---

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

func _test_telegraph_damps_emission(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := _instance(t, def)

	t.check(instance.is_telegraphing(), "an event starts in its telegraph phase")
	t.close_to(instance.current_intensity(), def.intensity * Tuning.TELEGRAPH_INTENSITY_FRACTION,
			"a telegraphing event emits only a fraction of its intensity")
	t.close_to(instance.contribution_at(Vector2(1000.0, 0.0)), 0.0,
			"an event contributes nothing beyond its outer radius")

	_advance(instance, def.telegraph_time + 0.05)
	t.check(not instance.is_telegraphing(), "the telegraph phase ends after telegraph_time")
	t.close_to(instance.current_intensity(), def.intensity,
			"an active event emits its full intensity", 0.05)
	t.close_to(instance.contribution_at(Vector2(def.inner_radius * 0.5, 0.0)), def.intensity,
			"inside the inner radius the full intensity applies", 0.05)
	instance.free()

func _test_pulse_envelope(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def.pulse_period > 0.0, "the yeller pulses rather than holding")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + 0.05)

	var lowest := INF
	var highest := -INF
	for i in int(def.pulse_period / STEP):
		instance._process(STEP)
		lowest = minf(lowest, instance.current_intensity())
		highest = maxf(highest, instance.current_intensity())

	t.check(highest > lowest * 2.0, "the pulse envelope has a real swing between beats")
	t.check(lowest > 0.0, "a pulsing event never goes completely silent")
	t.check(highest <= def.intensity + 0.001, "the pulse never exceeds the stated intensity")
	instance.free()

func _test_duration_and_finish(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := _instance(t, def)
	_advance(instance, def.telegraph_time + def.duration + 0.1)
	t.check(instance.is_finished, "an event with a duration finishes")
	t.close_to(instance.contribution_at(Vector2.ZERO), 0.0,
			"a finished event contributes nothing")
	instance.free()

func _test_mobile_follows_its_path(t) -> void:
	var def := EventCatalogue.by_id("fire_truck")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(300.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)
	t.check(instance.position == Vector2.ZERO, "a mobile event starts at its first waypoint")

	_advance(instance, 0.5)
	t.close_to(instance.position.x, def.speed * 0.5, "a mobile event travels at its speed", 5.0)
	t.close_to(instance.position.y, 0.0, "a mobile event stays on its path")

	# Off the end of the route is over, whatever the nominal duration says.
	_advance(instance, 3.0)
	t.check(instance.is_finished, "a mobile event finishes at the end of its path")
	instance.free()

## The other kind of mobile event, and the reason the field exists. A telegraph that is an
## *approach* has to travel — a fire engine warns you by being audible three streets away. A
## telegraph that is a *posture* must not: the cat crouches, then bolts.
##
## Playtest 04 found the cat doing nothing, and this is half of why. Its route is one street
## wide, so at 240px/s it finished the whole crossing inside its own 1.6s telegraph — it never
## reached full intensity, and the running sprite never drew once in six milestones.
func _test_a_crouching_event_holds_still_until_it_bolts(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	t.check(def.still_while_telegraphing, "the cat crouches rather than creeping")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(400.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	_advance(instance, def.telegraph_time - 0.1)
	t.check(instance.position == Vector2.ZERO, "it has not moved while telegraphing")
	t.check(instance.is_telegraphing(), "and it is still telegraphing")

	_advance(instance, 0.5)
	t.check(not instance.is_telegraphing(), "then the telegraph ends")
	t.close_to(instance.position.x, def.speed * 0.4,
			"and it bolts at its full speed from where it was crouched", 20.0)

	# The duration has to outlast the crossing, or it expires in the middle of the road.
	var crossing := float(EventDirector.CROSSING_REACH_TILES * Tuning.TILE_SIZE) * 2.0
	t.check(def.duration >= crossing / def.speed,
			"it lives long enough (%.2fs) to cross the whole street (%.2fs)"
			% [def.duration, crossing / def.speed])
	instance.free()

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
	director.start_day(plans, rng)
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
	var crossing := (path[0] + path[1]) * 0.5
	t.close_to(crossing.distance_to(at), Tuning.AHEAD_LEAD_DISTANCE,
			"it crosses where she is about to be, not where she is", 1.0)
	t.check((crossing - at).normalized().dot(north.normalized()) > 0.99,
			"and that is in front of her rather than beside or behind her")
	t.close_to((path[1] - path[0]).normalized().dot(north.normalized()), 0.0,
			"the run is square across her line", 0.01)

	# The fairness half. It starts at one end of that run, and both ends are further from her
	# than the field it will emit — so she is outside it the whole time it is telegraphing, and
	# the reaction window is real rather than nominal.
	var def := due[0] as EventDef
	for end in [path[0], path[1]]:
		t.check(at.distance_to(end) > def.outer_radius,
				"she is outside its reach (%.0fpx) when it appears (%.0fpx away)"
				% [def.outer_radius, at.distance_to(end)])
	t.check(Tuning.AHEAD_LEAD_DISTANCE / Tuning.WALK_SPEED >= 1.5,
			"and the lead is %.1fs of walking, which is time to do something about it"
			% (Tuning.AHEAD_LEAD_DISTANCE / Tuning.WALK_SPEED))
	t.check(director.owed() == 1, "and the day is one cat poorer")

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

# ----------------------------------------------------------------- scheduler ---

func _map() -> CityMap:
	return CityGenerator.generate(4242)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [4242, day])
	return rng

func _signature(planned: Array) -> String:
	var parts: Array[String] = []
	for plan in planned:
		parts.append("%s@%.1f,%.1f" % [plan.def.id, plan.position.x, plan.position.y])
	return "|".join(parts)

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
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
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
			if def.kind != GameEnums.EventKind.AMBIENT:
				t.check(counts[id] <= def.max_per_day,
						"day %d: '%s' respects max_per_day" % [day, id])

func _test_one_shots_fire_once_per_run(t) -> void:
	var map := _map()
	var consumed: Array[String] = []
	var seen := {}
	for day in range(1, 15):
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
			if plan.def.kind != GameEnums.EventKind.ONE_SHOT:
				continue
			t.check(not seen.has(plan.def.id),
					"one-shot '%s' fires at most once in a run" % plan.def.id)
			seen[plan.def.id] = day

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
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
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

## The calm ground of a calm block — mirrors `EventScheduler._calm_rect`, which is the
## definition the guarantee is actually written over.
func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

# -------------------------------------------------------------- act I content ---

func _test_successors_resolve(t) -> void:
	for def in EventCatalogue.all():
		if def.spawns_on_finish == "":
			continue
		t.check(EventCatalogue.by_id(def.spawns_on_finish) != null,
				"'%s' spawns '%s', which exists in the catalogue"
				% [def.id, def.spawns_on_finish])

## It has no scheduled day at all, so nothing but the fire engine can put one in the world.
func _test_burning_building_is_never_scheduled(t) -> void:
	var fire := EventCatalogue.by_id("burning_building")
	t.check(fire != null, "the burning building exists")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(not fire.available_on(day),
				"the burning building is not schedulable on day %d" % day)

func _test_fire_truck_is_a_day_three_one_shot(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(truck.kind == GameEnums.EventKind.ONE_SHOT, "the fire engine is a one-shot")
	t.check(not truck.available_on(2), "the fire engine cannot come on day 2")
	t.check(truck.available_on(3), "the fire engine can come on day 3")
	t.check(not truck.available_on(4), "the fire engine never comes again")

	# It outruns a walk, so the fairness rule must demand the full radius of clearance.
	t.check(truck.speed > Tuning.WALK_SPEED, "the fire engine is faster than walking")
	t.close_to(truck.minimum_telegraph(), truck.outer_radius / Tuning.WALK_SPEED,
			"a fast mover must be clearable across its whole radius, not just its band")
	t.check(truck.telegraph_time >= truck.minimum_telegraph(),
			"the fire engine gives that much warning")

	# A dog walker is slower than walking, so the ordinary band rule applies to it.
	var dog := EventCatalogue.by_id("dog_walker")
	t.check(dog.speed < Tuning.WALK_SPEED, "the dog walker is slower than walking")
	t.close_to(dog.minimum_telegraph(), (dog.outer_radius - dog.inner_radius) / Tuning.WALK_SPEED,
			"a slow mover can simply be walked away from")

func _test_along_street_paths_stay_in_bounds(t) -> void:
	var map := _map()
	var extent := map.world_size()
	for day in range(1, 15):
		var consumed: Array[String] = []
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
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

# ------------------------------------------------------- what a street costs (M19) ---

## Events that are deliberately scenery: they are there so the street *looks* different, not
## so it costs something. Everything else has to cost something to walk through — an obstacle
## that is cheaper to walk into than to walk around is a bribe, and the player learns to take
## it. Naming the three explicitly is the point: a fourth one has to be a decision.
const _SCENERY := ["poster_crew", "barricade", "burnt_shell"]

## Net excitement from walking straight through the centre of an event at walking pace, in
## points of a hundred-point meter: the falloff integrated along the line, minus the walking
## decay over the same time. This is what produced the table in docs/EVENTS.md, and the
## measurement behind playtest 02's finding 7.
func _cost_to_walk_through(def: EventDef) -> float:
	var span := def.outer_radius * 2.0
	var seconds := span / Tuning.WALK_SPEED
	var steps := 2000
	var total := 0.0
	for i in steps:
		var d := absf(-def.outer_radius + span * (i + 0.5) / steps)
		total += Tuning.falloff(d, def.intensity, def.inner_radius, def.outer_radius)
	return (total / steps - Tuning.EXCITEMENT_DECAY_WALKING) * seconds

## The measured failure playtest 02 found and M19 fixes: at intensity 7 the dog walker cost
## −0.1 points to walk straight through, so the correct play was to plough into it.
func _test_nothing_is_cheaper_to_walk_through_than_around(t) -> void:
	for def in EventCatalogue.all():
		if def.city_wide or def.intensity <= 0.0 or def.id in _SCENERY:
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
	var map := _map()
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	for day in [1, 3, 7, 14]:
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
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
func _test_the_named_decisions_arrive(t) -> void:
	var map := _map()
	var counts := {}
	for city_seed in [4242, 77, 1301]:
		var seeded := CityGenerator.generate(city_seed)
		var consumed: Array[String] = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:1" % city_seed)
		for plan in EventScheduler.build_day(1, rng, seeded, consumed):
			counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
		t.check(int(counts.get("dog_walker", 0)) > 0, "seed %d: day 1 has dog walkers" % city_seed)
	t.check(counts.get("dog_walker", 0) >= 3 * 8,
			"day 1 carries enough dog walkers to meet two on a route (%s over three seeds)"
			% counts.get("dog_walker", 0))
	t.check(counts.get("cafe_tables", 0) >= 3 * 6,
			"day 1 carries enough cafés to find one (%s over three seeds)"
			% counts.get("cafe_tables", 0))
	t.check(map.calm_blocks.size() > 0, "and the map still has calm ground on it")

## What `max_per_day` was quietly doing before M28, now doing it on purpose. The fallback in
## `_roomiest_of_several` can still put two of a kind closer than `EVENT_SPACING_SAME` on a
## full map, so this is stated as "almost never" plus a hard floor that nothing may cross.
func _test_two_of_a_kind_are_not_the_same_incident(t) -> void:
	var map := _map()
	for day in [1, 8, 14]:
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
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
## into another. Survivable for everything that only costs points, and a death for the three
## rows that end the day — so a lethal field has nothing else in it. Unlike the other spacing
## rules this one has no fallback, which is why it is asserted absolutely.
func _test_nothing_happens_inside_a_lethal_field(t) -> void:
	var map := _map()
	var lethal_days := 0
	for day in range(1, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		for plan in planned:
			if not plan.def.hard_fail or not plan.is_placed():
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
	t.check(lethal_days > 0, "and a run actually contains lethal events to check")
