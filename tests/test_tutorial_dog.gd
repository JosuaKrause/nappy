extends RefCounted
## The charging dog past the teaching day — M96, "the teaching day, and the dog after it".
##
## Day 3 (`Tuning.RUN_TAUGHT_DAY`) sites it on her exact heading, unavoidable, because the run
## lesson depends on it. Every day after, the same row recurs but is no longer the lesson — *"the
## tutorial dog may appear later but not as tutorial."* `EventDef.spawn_mode_on(day)` is what
## switches: `AHEAD_OF_PLAYER` through the teaching day, `MAP` after it, so the row is placed on a
## tile and met by routing into it, the way `alley_robbery` is, rather than sited by the director on
## her heading or off it. See `EventScheduler._place_one()` and `EventDirector.start_day()`.
##
## Two things past the switch, both below. **The map-placed dog waits** inside its own field for
## her rather than announcing itself the moment it streams in — `EventDef.pursues_within_on(day)`,
## the same day-keyed switch answered a different way, and `EventScheduler._for_day()` is where a
## placement past it gets a copy carrying that answer. **And the day-3 shape does not retire** —
## *(2026-09-13, PLAYTEST-68: "we can sprinkle the day 3 charging dog in every now and then,
## too")* — `EventDirector._owe_the_sprinkled_dog()` now and then sends the same unmodified def
## off her heading again, unguaranteed and without the tip.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_spawn_mode_switches_after_the_teaching_day(t)
	_test_day_3_is_still_sited_on_her_heading(t)
	_test_day_4_is_a_map_placement(t)
	_test_day_4_is_never_owed_to_the_director(t)
	_test_pursues_within_switches_after_the_teaching_day(t)
	_test_day_4_dog_waits_until_she_is_in_its_field(t)
	_test_day_3_dog_still_charges_the_moment_it_streams_in(t)
	_test_the_sprinkle_offers_day_3s_own_shape_on_a_later_day(t)
	_test_the_sprinkle_never_runs_on_the_teaching_day(t)

func _map() -> CityMap:
	return CityGenerator.generate(4242)

## The def itself, asked the direct question: the smallest possible check of the field that makes
## everything else in this file true.
func _test_spawn_mode_switches_after_the_teaching_day(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	t.check(def != null, "charging_dog is in the catalogue")
	if not def:
		return
	t.check(def.spawn_mode_on(Tuning.RUN_TAUGHT_DAY) == EventDef.SpawnMode.AHEAD_OF_PLAYER,
			"on the teaching day itself the dog is still director-sited")
	t.check(def.spawn_mode_on(Tuning.RUN_TAUGHT_DAY + 1) == EventDef.SpawnMode.MAP,
			"the day after, it is a map placement")
	t.check(def.spawn_mode_on(Tuning.RUN_TAUGHT_DAY + 11) == EventDef.SpawnMode.MAP,
			"and it stays one for every day after that")

## Walks a director until it hands out `charging_dog`, or returns two `Vector2.INF`s if a real
## street's worth of walking never gets one. `due()` sites relative to wherever she has walked to
## by the time it fires — `Tuning.AHEAD_INTERVAL` is up to 26s of walking, hundreds of pixels past
## the start — so the second return is her position *at the moment of siting*, which is what a
## heading has to be measured from, not the start of the walk.
func _site_the_dog(director: EventDirector, at: Vector2, heading: Vector2) -> Array:
	var due: Array = []
	var walked := at
	for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
		due = director.due(STEP, walked, heading * Tuning.WALK_SPEED)
		walked += heading * Tuning.WALK_SPEED * STEP
		if not due.is_empty():
			break
	if due.is_empty():
		return [Vector2.INF, Vector2.INF]
	var path := due[1] as PackedVector2Array
	if path.size() != 1:
		return [Vector2.INF, Vector2.INF]
	return [path[0], walked]

## Day 3: unavoidable, on her exact line — `_teach_the_run()` puts it at the head of the queue and
## nothing about its siting has changed.
func _test_day_3_is_still_sited_on_her_heading(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var def := EventCatalogue.by_id("charging_dog")
	var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
	director.start_day(Tuning.RUN_TAUGHT_DAY, plans, rng)

	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var north := Vector2(0.0, -1.0)
	var result := _site_the_dog(director, at, north)
	var site: Vector2 = result[0]
	var sited_from: Vector2 = result[1]
	t.check(site != Vector2.INF, "day 3 sites the dog while she walks a real street")
	if site == Vector2.INF:
		return
	var direction := (site - sited_from).normalized()
	t.check(direction.dot(north) > 0.99,
			"and it is on her exact heading — the lesson has to be unavoidable")

## Day 4 and every day after: the row is placed on the map at dawn, the way `alley_robbery` is,
## rather than left for the director to site. Walked over the planned placements of several seeds
## and every day the row is eligible on past the teaching day, the same reason `alley_robbery`'s own
## required-alley test is over placements rather than the pool directly: a def whose field answers
## `MAP` and a scheduler that still refuses to place it are two different bugs.
func _test_day_4_is_a_map_placement(t) -> void:
	var checked := 0
	for run_seed in [4242, 2102613802, 90210]:
		var map := CityGenerator.generate(run_seed)
		var consumed: Array[String] = []
		for day in range(Tuning.RUN_TAUGHT_DAY + 1, 15):
			var tree := RouteTree.for_day(map, day)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [run_seed, day])
			for plan in EventScheduler.build_day(day, rng, map, consumed, [], [], tree):
				if plan.def.id != "charging_dog":
					continue
				checked += 1
				t.check(plan.is_placed(),
						"seed %d day %d: 'charging_dog' has a position, not a director siting"
						% [run_seed, day])
	t.check(checked > 0, "some run placed charging_dog past the teaching day to check (%d)" % checked)

## And the other half, confirmed at the director: a `MAP`-mode plan is never turned into an owed
## encounter by `start_day()`'s own per-plan loop, so it can never be sited on her heading, or
## anywhere else the director reaches for, *by that mechanism*. Compared against an identical rng
## stream with no plan at all rather than against a flat `owed() == 0`, because past M96's own
## sprinkle (`_test_the_sprinkle_offers_day_3s_own_shape_on_a_later_day`, below)
## `EventDirector` can legitimately owe the row anyway — the two calls share a seed so the
## sprinkle's own roll, which reads nothing from `plans`, comes out identically either way, and
## the only thing left to differ is what the plan itself contributed.
func _test_day_4_is_never_owed_to_the_director(t) -> void:
	var map := _map()
	var def := EventCatalogue.by_id("charging_dog")
	for seed in [3, 17, 29, 41, 53]:
		var with_plan := EventDirector.new(map)
		var rng_a := RandomNumberGenerator.new()
		rng_a.seed = seed
		var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
		with_plan.start_day(Tuning.RUN_TAUGHT_DAY + 1, plans, rng_a)

		var without_plan := EventDirector.new(map)
		var rng_b := RandomNumberGenerator.new()
		rng_b.seed = seed
		without_plan.start_day(Tuning.RUN_TAUGHT_DAY + 1, [], rng_b)

		t.check(with_plan.owed() == without_plan.owed(),
				("seed %d: a MAP-mode plan changes nothing about what is owed — only the sprinkle, " +
						"rolled identically with or without it, may put the dog in the queue") % seed)

## The def itself, the same direct question `_test_spawn_mode_switches_after_the_teaching_day` asks
## of `spawn_mode_on()` — `pursues_within_on()` is the same day-keyed switch, read for the trigger
## rather than the siting.
func _test_pursues_within_switches_after_the_teaching_day(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	t.check(def != null, "charging_dog is in the catalogue")
	if not def:
		return
	t.check(def.pursues_within_on(Tuning.RUN_TAUGHT_DAY) <= 0.0,
			"on the teaching day itself it still charges the moment it streams in")
	var waiting := def.pursues_within_on(Tuning.RUN_TAUGHT_DAY + 1)
	t.check(waiting > 0.0, "the day after, it waits for her to come within its own field")
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
	t.check(waiting < def.outer_radius and waiting > standoff,
			"inside its own outer radius, an 'on sight' band before the trigger — alley_robbery's " +
					"shape — and past the stand-off, or the notice would be spent standing still")
	t.check(is_equal_approx(def.pursues_within_on(Tuning.RUN_TAUGHT_DAY + 11), waiting),
			"and it stays the waiting shape for every day after that")

## The waiting itself, on the copy `EventScheduler._for_day()` hands a `MAP` placement past the
## switch. `EventInstance` never asks a day of anybody — this is where the day answer actually has
## to arrive: a different `EventDef`, `pursues_within` already set, never a mutation of the one
## day 3's own dog reads.
func _test_day_4_dog_waits_until_she_is_in_its_field(t) -> void:
	var cold := EventCatalogue.by_id("charging_dog")
	if not cold:
		return
	var day := Tuning.RUN_TAUGHT_DAY + 1
	var hot := EventScheduler._for_day(cold, day)
	t.check(hot.pursues_within > 0.0, "the day-4 copy carries a real trigger")

	var dog := EventInstance.new()
	dog.setup(hot, Vector2.ZERO)
	# Inside the field (`outer_radius`) but outside the trigger (`pursues_within`) — the "on sight"
	# band alley_robbery's own shape leaves room for.
	dog.set_player_at(Vector2((hot.outer_radius + hot.pursues_within) * 0.5, 0.0))
	dog._process(STEP)
	t.check(dog.is_waiting() and not dog.is_telegraphing(),
			"inside its own field but outside the trigger, a day-4 dog has not noticed her yet")

	dog.set_player_at(Vector2(hot.pursues_within - 10.0, 0.0))
	dog._process(STEP)
	t.check(not dog.is_waiting() and dog.is_telegraphing(),
			"inside the trigger, it notices her and starts its telegraph")
	dog.free()

## Day 3's own dog, unchanged: the raw catalogue def, `pursues_within` still 0.0, so it is already
## telegraphing its charge from the first frame, wherever she happens to be standing. The same fact
## `tests/test_danger.gd` checks from the caret's side; this is the trigger's own.
func _test_day_3_dog_still_charges_the_moment_it_streams_in(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	if not def:
		return
	t.check(def.pursues_within <= 0.0, "day 3's own def is untouched by the switch")
	var dog := EventInstance.new()
	dog.setup(def, Vector2.ZERO)
	dog.set_player_at(Vector2(1000.0, 1000.0))
	dog._process(STEP)
	t.check(not dog.is_waiting() and dog.is_telegraphing(),
			"a day-3 dog is already telegraphing its charge however far away she is standing")
	dog.free()

## The sprinkle: past the teaching day, `EventDirector` now and then adds the row back to its own
## queue in day 3's own shape — the same `EventDef`, unmodified, so it still charges the moment it
## streams in rather than waiting the way a `MAP` placement on the same day would. Swept over many
## seeds because "now and then" is a probability, not a certainty on any one day: both outcomes
## have to actually occur somewhere in the sweep, or the roll is dead code.
func _test_the_sprinkle_offers_day_3s_own_shape_on_a_later_day(t) -> void:
	var map := _map()
	var day := Tuning.RUN_TAUGHT_DAY + 1
	var offered := 0
	var not_offered := 0
	for seed in range(200):
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		director.start_day(day, [], rng)
		if director.owed() > 0:
			offered += 1
			for queued: EventDef in director._owed:
				t.check(queued.id == "charging_dog" and queued.pursues_within <= 0.0,
						("seed %d: the sprinkle is charging_dog itself, pursues_within untouched " +
								"at 0.0 — day 3's own shape, not the waiting one a MAP placement " +
								"past the switch would carry") % seed)
		else:
			not_offered += 1
	t.check(offered > 0, "the sprinkle happens on some days past the teaching day")
	t.check(not_offered > 0, "and not on every one of them — 'now and then', not guaranteed")

## And it never doubles the teaching day itself: `_teach_the_run()` already guarantees day 3 its
## one dog with the tip and the delay, and a second roll stacked on top would be two lessons where
## the entry asks for one guarantee and, separately, an unguaranteed sprinkle confined to later days.
func _test_the_sprinkle_never_runs_on_the_teaching_day(t) -> void:
	var map := _map()
	var def := EventCatalogue.by_id("charging_dog")
	for seed in range(50):
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
		director.start_day(Tuning.RUN_TAUGHT_DAY, plans, rng)
		t.check(director.owed() == 1,
				("seed %d: the teaching day owes exactly its one guaranteed dog, never a second " +
						"from the sprinkle") % seed)
