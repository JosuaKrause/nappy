extends RefCounted
## The charging dog past the teaching day — M96, "the teaching day, and the dog after it".
##
## Day 3 (`Tuning.RUN_TAUGHT_DAY`) sites it on her exact heading, unavoidable, because the run
## lesson depends on it. Every day after, the same row recurs but is no longer the lesson — *"the
## tutorial dog may appear later but not as tutorial."* `EventDef.spawn_mode_on(day)` is what
## switches: `AHEAD_OF_PLAYER` through the teaching day, `MAP` after it, so the row is placed on a
## tile and met by routing into it, the way `alley_robbery` is, rather than sited by the director on
## her heading or off it. See `EventScheduler._place_one()` and `EventDirector.start_day()`.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_spawn_mode_switches_after_the_teaching_day(t)
	_test_day_3_is_still_sited_on_her_heading(t)
	_test_day_4_is_a_map_placement(t)
	_test_day_4_is_never_owed_to_the_director(t)

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

## And the other half, confirmed at the director: past the teaching day the row is never in the
## owed list at all, so it can never be sited on her heading, or anywhere else the director reaches
## for. Swept over several rng streams, since a single trial passing would not rule out "usually,
## not always".
func _test_day_4_is_never_owed_to_the_director(t) -> void:
	var map := _map()
	var def := EventCatalogue.by_id("charging_dog")
	for seed in [3, 17, 29, 41, 53]:
		var director := EventDirector.new(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
		director.start_day(Tuning.RUN_TAUGHT_DAY + 1, plans, rng)
		t.check(director.owed() == 0,
				"seed %d: past the teaching day the dog is never handed to the director" % seed)
