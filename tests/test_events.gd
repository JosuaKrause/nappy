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
	_test_hard_fail_only_when_active(t)
	_test_scheduler_is_deterministic(t)
	_test_scheduler_respects_placement_and_caps(t)
	_test_one_shots_fire_once_per_run(t)
	_test_one_park_stays_usable(t)
	_test_successors_resolve(t)
	_test_burning_building_is_never_scheduled(t)
	_test_fire_truck_is_a_day_three_one_shot(t)
	_test_along_street_paths_stay_in_bounds(t)

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
	var def := EventCatalogue.by_id("cat_dash")
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
			if plan.def.placement.is_empty():
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
func _test_one_park_stays_usable(t) -> void:
	var map := _map()
	for day in range(1, 15):
		var consumed: Array[String] = []
		var planned := EventScheduler.build_day(day, _rng(day), map, consumed)
		var clean := 0
		for block in map.calm_blocks:
			var lot := map.tile_rect_to_world(CityMap.block_rect(block))
			var spoiled := false
			for plan in planned:
				if plan.def.kind == GameEnums.EventKind.AMBIENT:
					continue
				if lot.grow(plan.def.outer_radius).has_point(plan.position):
					spoiled = true
					break
			if not spoiled:
				clean += 1
		t.check(clean >= 1, "day %d leaves at least one park unspoiled" % day)

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
